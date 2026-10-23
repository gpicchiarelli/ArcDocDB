;;; OWNER: controller esclusivo; tutte le fault injection precedono la sonda.
;;; SHARED: nessuno; nessun thread o ridefinizione del prodotto nei casi deterministici.
(in-package #:arcdocdb.cache.tests)

(defun cache-guard-slot (cache entry)
  "Trova il tag FI confrontando le quattro parole, senza lookup del prodotto."
  (let ((tags (c::classe-cache-tags (cache-class cache))))
    (or (loop for slot below 8 for base = (* slot 4)
              when (and (= (cache-entry-segment-high entry) (aref tags base))
                        (= (cache-entry-segment-low entry) (aref tags (+ base 1)))
                        (= (cache-entry-offset entry) (aref tags (+ base 2)))
                        (= (length (cache-entry-record entry)) (aref tags (+ base 3))))
                return slot)
        (error "Tag della fixture cache non trovato."))))

;;; REQ: REQ-CCH-002 REQ-CCH-004
(deftest test-REQ-CCH-004-cache-empty-and-published
  (dolist (version '(1 2))
    (dolist (value-bytes '(16 4096))
      (multiple-value-bind (cache entries) (cache-fixture version :value-bytes value-bytes)
        (let ((entry (aref entries 0)) (destination (cache-buffer entries)))
          (is (eq :miss (cache-check-read cache entry destination)))
          (is (equal '(:inserted nil nil) (multiple-value-list (cache-insert cache entry))))
          (is (eq :hit (cache-check-read cache entry destination)))
          (is (equal '(:present nil nil) (multiple-value-list (cache-insert cache entry)))))))))

;;; REQ: REQ-CCH-004 REQ-AFF-002
(deftest test-REQ-CCH-004-cache-odd-sequence-is-unreadable
  (dolist (version '(1 2))
    (multiple-value-bind (cache entries) (cache-fixture version)
      (let ((entry (aref entries 0)) (destination (cache-buffer entries)))
        (is (eq :inserted (cache-insert cache entry)))
        (let* ((slot (cache-guard-slot cache entry))
               (sequences (c::classe-cache-sequences (cache-class cache)))
               (published (aref sequences slot)))
          (is (evenp published))
          (setf (aref sequences slot) (1+ published))
          (is (eq :miss (cache-check-read cache entry destination)))
          ;; Solo FI seriale: il ritorno al pari isola la guardia dalla CRC/tag.
          (setf (aref sequences slot) published)
          (is (eq :hit (cache-check-read cache entry destination))))))))

;;; REQ: REQ-CCH-004 REQ-AFF-008
(deftest test-REQ-CCH-004-cache-sequence-limit-is-unreadable
  (dolist (version '(1 2))
    (multiple-value-bind (cache entries) (cache-fixture version)
      (let ((entry (aref entries 0)) (destination (cache-buffer entries)))
        (is (eq :inserted (cache-insert cache entry)))
        (let ((slot (cache-guard-slot cache entry)) (class (cache-class cache)))
          (dolist (sequence (list c::+cache-sequence-limit+ #xfffffffffffffffe))
            (setf (aref (c::classe-cache-sequences class) slot) sequence)
            (is (eq :miss (cache-check-read cache entry destination)))
            (is (= sequence (aref (c::classe-cache-sequences class) slot)))))))))

;;; REQ: REQ-CCH-004 REQ-AFF-008
(deftest test-REQ-CCH-004-cache-disabled-is-terminal
  (dolist (version '(1 2))
    (multiple-value-bind (cache entries) (cache-fixture version)
      (let ((entry (aref entries 0)) (destination (cache-buffer entries))
            (class (cache-class cache)))
        (is (eq :inserted (cache-insert cache entry)))
        (fill (c::classe-cache-disabled class) 1)
        (let ((before (copy-seq (c::classe-cache-sequences class)))
              (arena (copy-seq (c::classe-cache-arena class))))
          (dotimes (attempt 2)
            (is (eq :miss (cache-check-read cache entry destination)))
            (is (equal '(:unavailable nil nil)
                       (multiple-value-list (cache-insert cache entry))))
            (is (every (lambda (byte) (= 1 byte)) (c::classe-cache-disabled class)))
            (is (equalp before (c::classe-cache-sequences class)))
            (is (equalp arena (c::classe-cache-arena class)))))))))

;;; REQ: REQ-CCH-004 REQ-AFF-008
(deftest test-REQ-CCH-004-cache-last-credit-then-disabled
  (dolist (version '(1 2))
    (multiple-value-bind (cache entries) (cache-fixture version)
      (let* ((class (cache-class cache)) (sequences (c::classe-cache-sequences class))
             (entry (aref entries 0)) (other (aref entries 1)) (destination (cache-buffer entries)))
        (fill (c::classe-cache-disabled class) 1 :start 1)
        (setf (aref sequences 0) (- c::+cache-sequence-limit+ 4))
        (is (equal '(:inserted nil nil) (multiple-value-list (cache-insert cache entry))))
        (is (= (- c::+cache-sequence-limit+ 2) (aref sequences 0)))
        (is (eq :hit (cache-check-read cache entry destination)))
        (is (equal '(:present nil nil) (multiple-value-list (cache-insert cache entry))))
        (is (equal '(:unavailable nil nil) (multiple-value-list (cache-insert cache other))))
        (is (= 1 (aref (c::classe-cache-disabled class) 0)))
        (is (= (- c::+cache-sequence-limit+ 2) (aref sequences 0)))
        (is (eq :miss (cache-check-read cache entry destination)))
        (is (eq :unavailable (cache-insert cache entry)))))))

;;; REQ: REQ-CCH-004 REQ-AFF-008
(deftest test-REQ-CCH-004-cache-odd-slots-are-quarantined
  (dolist (version '(1 2))
    (multiple-value-bind (cache entries) (cache-fixture version)
      (let ((class (cache-class cache)) (entry (aref entries 0)))
        (fill (c::classe-cache-sequences class) 3)
        (is (equal '(:unavailable nil nil) (multiple-value-list (cache-insert cache entry))))
        (is (every (lambda (byte) (= 1 byte)) (c::classe-cache-disabled class)))
        (is (every (lambda (sequence) (= 3 sequence)) (c::classe-cache-sequences class)))
        ;; Anche un pari imposto dalla fixture non riabilita il bit terminale.
        (fill (c::classe-cache-sequences class) 0)
        (is (eq :unavailable (cache-insert cache entry)))
        (is (every #'zerop (c::classe-cache-tags class)))
        (is (every #'zerop (c::classe-cache-sequences class)))
        (is (eq :miss (cache-check-read cache entry (cache-buffer entries))))))))

;;; REQ: REQ-CCH-004 REQ-AFF-002
(deftest test-REQ-CCH-004-cache-corrupt-copy-is-rejected
  (dolist (version '(1 2))
    (multiple-value-bind (cache entries) (cache-fixture version)
      (let ((entry (aref entries 0)) (destination (cache-buffer entries)))
        (is (eq :inserted (cache-insert cache entry)))
        (let* ((class (cache-class cache)) (slot (cache-guard-slot cache entry))
               (position (+ (* slot (c::classe-cache-size class)) 40)))
          (setf (aref (c::classe-cache-arena class) position)
                (logxor 1 (aref (c::classe-cache-arena class) position)))
          (multiple-value-bind (status begin end) (cache-read cache entry destination)
            (is (eq :verify-failed status)) (is (zerop begin)) (is (zerop end))
            (cache-check-sentinels entry destination))
          (is (= 1 (aref (c::classe-cache-rejected class) slot)))
          (is (eq :miss (cache-check-read cache entry destination))))))))

;;; REQ: REQ-CCH-004 REQ-AFF-002
(deftest test-REQ-CCH-004-cache-corrupt-input-precedes-publication
  (dolist (version '(1 2))
    (multiple-value-bind (cache entries) (cache-fixture version :count 2)
      (let* ((valid (aref entries 0)) (invalid (copy-cache-entry (aref entries 1)))
             (class (cache-class cache)))
        (is (eq :inserted (cache-insert cache valid)))
        ;; La copia shallow conserva gli attesi; solo il record input è privato e corrotto.
        (setf (cache-entry-record invalid) (copy-seq (cache-entry-record invalid)))
        (setf (aref (cache-entry-record invalid) 40)
              (logxor 1 (aref (cache-entry-record invalid) 40)))
        (let* ((arrays (list (c::classe-cache-arena class) (c::classe-cache-tags class)
                             (c::classe-cache-sequences class) (c::classe-cache-disabled class)
                             (c::classe-cache-rejected class) (c::classe-cache-hands class)
                             (c::classe-cache-references class) (c::classe-cache-origins class)
                             (c::classe-cache-reread class)))
               (before (mapcar #'copy-seq arrays)))
          (signals arcdocdb.conditions:corruption-detected
            (cache-insert cache invalid) :body-crc)
          ;; Prima di una nuova lettura che potrebbe aggiornare calore/rilettura.
          (loop for saved in before for current in arrays do (is (equalp saved current))))
        (is (eq :hit (cache-check-read cache valid (cache-buffer entries))))))))
