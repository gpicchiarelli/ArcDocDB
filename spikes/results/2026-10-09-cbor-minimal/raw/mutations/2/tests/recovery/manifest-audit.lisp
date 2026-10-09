;;;; Seconda lettura C1: budget fisici, integrità, provenienza e Serie parallele.
(in-package #:arcdocdb.recovery.tests)

;;; REQ: REQ-FOR-003 REQ-AFF-008 REQ-AFF-017
(deftest test-REQ-FOR-003-manifest-direct-api-defaults-and-required-options
  (let* ((specs (manifest-basic-history)) (expected (manifest-oracle specs)))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end)
          (manifest-log-fixture (mapcar #'list specs) :version version :file-offset 0)
        (let ((before (copy-seq buffer)))
          ;; Chiamata diretta: il wrapper non riempie i valori predefiniti.
          (signals unsupported-format
                   (arcdocdb.recovery.manifest:ricostruisci-manifest
                     buffer start end :file-size end)
                   :record-version)
          (signals invalid-argument
                   (arcdocdb.recovery.manifest:ricostruisci-manifest
                     buffer start end :version version)
                   :incomplete-log-buffer)
          (multiple-value-bind (manifest prefix status)
              (arcdocdb.recovery.manifest:ricostruisci-manifest
                buffer start end :version version :file-size end)
            (is (= end prefix)) (is (eq :complete status))
            (is (equalp before buffer))
            (assert-manifest-model manifest expected)
            (fill buffer #xff)
            (assert-manifest-model manifest expected)))))))

;;; REQ: REQ-AFF-018 REQ-FOR-003
(deftest test-REQ-AFF-018-manifest-reserved-old-ids-and-unchanged-active
  (let* ((specs (list (manifest-spec :completo t :next-id 100 :open 10
                                    :chiusi '((0 64 ((0 0)))) :rimossi '(3))
                      (manifest-spec :open 10)
                      (manifest-spec :chiusi '((4 128 nil)))
                      (manifest-spec :rimossi '(0 3 0)))))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end) (manifest-log-fixture (list specs) :version version)
        (multiple-value-bind (manifest prefix status)
            (manifest-fixture-read buffer start end :version version)
          (is (= end prefix)) (is (eq :complete status))
          (assert-manifest-model manifest (manifest-oracle specs) '(1 2 1024)))))))

;;; REQ: REQ-AFF-008 REQ-AFF-018 REQ-FOR-003
(deftest test-REQ-AFF-008-manifest-physical-duplicate-budgets
  (let* ((a '(1 64 ((0 0) (7 17) (0 0))))
         (b '(1 64 ((7 17) (0 0) (7 17))))
         (specs (list (manifest-spec :completo t :next-id 100 :open 10
                                    :chiusi (list a b '(2 512 nil)) :rimossi '(3 3))
                      (manifest-spec :chiusi (list b a) :rimossi '(2 3 2 3)))))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end layouts)
          (manifest-log-fixture (mapcar #'list specs) :version version)
        (let ((before (copy-seq buffer)))
          (multiple-value-bind (manifest prefix status)
              (manifest-fixture-read buffer start end :version version :max-edits 2
                 :max-segmenti 12 :max-esiti 12 :max-chiusi-per-edit 3
                 :max-rimossi-per-edit 4 :max-esiti-per-edit 6 :max-metadata-bytes 196)
            (is (= end prefix)) (is (eq :complete status))
            (assert-manifest-model manifest (manifest-oracle specs)))
          (dolist (case '((:max-edits 1 :manifest-edit-budget 1)
                          (:max-segmenti 5 :manifest-segment-budget 0)
                          (:max-segmenti 11 :manifest-segment-budget 1)
                          (:max-esiti 5 :manifest-outcome-budget 0)
                          (:max-esiti 11 :manifest-outcome-budget 1)))
            (let ((condition (signals resource-exhausted
                               (apply #'manifest-fixture-read buffer start end
                                      :version version (subseq case 0 2))
                               (third case))))
              (is (= (+ 64 (getf (nth (fourth case) layouts) :start))
                     (error-offset condition)))))
          (dolist (option '((:max-edits 0) (:max-segmenti 0) (:max-esiti 0)))
            (signals resource-exhausted
                     (apply #'manifest-fixture-read buffer start end :version version option)))
          (dolist (option '((:max-chiusi-per-edit 2) (:max-rimossi-per-edit 3)
                            (:max-esiti-per-edit 5) (:max-metadata-bytes 195)
                            (:max-metadata-bytes 0)))
            (signals resource-exhausted
                     (apply #'manifest-fixture-read buffer start end :version version option)
                     :metadata-budget))
          (is (equalp before buffer)))))))

;;; REQ: REQ-AFF-008 REQ-FOR-003
(deftest test-REQ-AFF-008-manifest-zero-empty-sections-and-invalid-budgets
  (multiple-value-bind (buffer start end)
      (manifest-log-fixture (list (list (manifest-spec :completo t :next-id 2 :open 1))))
    (let ((manifest (manifest-fixture-read buffer start end :max-edits 1 :max-segmenti 1
                      :max-esiti 0 :max-chiusi-per-edit 0 :max-rimossi-per-edit 0
                      :max-esiti-per-edit 0 :max-metadata-bytes 24)))
      (assert-manifest-model manifest (manifest-oracle
                                       (list (manifest-spec :completo t :next-id 2 :open 1))))))
  (multiple-value-bind (buffer start end) (manifest-log-fixture nil)
    (dolist (key '(:max-edits :max-segmenti :max-esiti :max-chiusi-per-edit
                   :max-rimossi-per-edit :max-esiti-per-edit :max-metadata-bytes))
      (signals invalid-argument (apply #'manifest-fixture-read buffer start end (list key -1))
               :manifest-arguments))
    (dolist (option (list (list :max-edits (1+ most-positive-fixnum))
                          (list :max-segmenti (1+ most-positive-fixnum))
                          (list :max-esiti (1+ most-positive-fixnum))
                          '(:max-chiusi-per-edit 4294967296)
                          '(:max-rimossi-per-edit 4294967296)
                          '(:max-esiti-per-edit 4294967296)
                          '(:max-metadata-bytes 16777217)))
      (signals invalid-argument (apply #'manifest-fixture-read buffer start end option)
               :manifest-arguments))))

;;; REQ: REQ-FOR-003 REQ-AFF-017 REQ-LIM-001
(deftest test-REQ-FOR-003-manifest-semantic-corruption-in-sealed-prefix
  (dolist (version '(1 2))
    (dolist (invalid-length '(0 63 4294967296 18446744073709551615))
      (let ((spec (manifest-spec :completo t :next-id 3 :open 1
                                 :chiusi (list (list 2 invalid-length nil)))))
        (multiple-value-bind (buffer start end) (manifest-log-fixture (list (list spec))
                                                                    :version version)
          (let* ((before (copy-seq buffer))
                 (condition (signals corruption-detected
                              (manifest-fixture-read buffer start end :version version)
                              :closed-valid-bytes)))
            (is (not (typep condition 'log-corruption)))
            (is (= (+ start 52) (error-offset condition)))
            (is (equalp before buffer))))))
    (let* ((valid (manifest-spec :completo t :next-id 2 :open 1))
           (body (concatenate '(vector (unsigned-byte 8)) (reference-manifest-payload valid)
                              (bytes 0))))
      (multiple-value-bind (buffer start end)
          (manifest-record-log-fixture
           (list (list (reference-record 5 17 (bytes) body :version version :flags 8)))
           :version version)
        (signals corruption-detected (manifest-fixture-read buffer start end :version version)
                 :edit-trailing-data)))
    (let ((initial (manifest-spec :completo t :next-id 2 :open 1))
          (bad (manifest-spec :next-id 1)))
      (multiple-value-bind (buffer start end) (manifest-log-fixture (list (list initial bad))
                                                                  :version version)
        (signals corruption-detected (manifest-fixture-read buffer start end :version version)
                 :edit-next-id)))))

;;; REQ: REQ-AFF-009 REQ-AFF-017 REQ-FOR-003
(deftest test-REQ-AFF-009-manifest-witness-precedes-semantic-errors-and-budgets
  (dolist (version '(1 2))
    (let ((initial (manifest-spec :completo t :next-id 3 :open 1 :chiusi '((2 64 nil))))
          (bad (manifest-spec :rimossi '(1))) (last (manifest-spec)))
      (dolist (corrupt-first-p '(nil t))
        (multiple-value-bind (buffer start end layouts)
            (manifest-log-fixture (list (list initial) (list bad) (list last)) :version version)
          (let* ((p (getf (second layouts) :start))
                 (pos (first (getf (second layouts) :records))))
            (when corrupt-first-p
              (reference-le buffer (+ start 52) 8 63)
              (repair-manifest-batch buffer (first layouts)))
            (setf (aref buffer (+ pos 24)) (logxor 1 (aref buffer (+ pos 24))))
            (set-durable buffer (third layouts) (+ 64 p 1))
            (let* ((before (copy-seq buffer))
                   (condition (signals log-corruption
                                (manifest-fixture-read buffer start end :version version
                                                       :max-edits 0 :max-segmenti 0 :max-esiti 0)
                                :log-durable-corruption)))
              (is (= p (corruption-prefix-end condition)))
              (is (= (+ 64 p) (error-offset condition)))
              (is (= (+ 64 (getf (third layouts) :seal))
                     (corruption-witness-offset condition)))
              (is (eq :body-crc (corruption-first-reason condition)))
              (is (equalp before buffer)))))))))

;;; REQ: REQ-AFF-009 REQ-AFF-017 REQ-FOR-003
(deftest test-REQ-AFF-017-manifest-unsealed-invalid-transition-is-excluded
  (let* ((initial (manifest-spec :completo t :next-id 3 :open 1 :chiusi '((2 64 nil))))
         (invalid (manifest-spec :rimossi '(1)))
         (expected (manifest-oracle (list initial))))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end layouts)
          (manifest-log-fixture (list (list initial) (list invalid)) :version version)
        (let ((before (copy-seq buffer)) (seal (getf (second layouts) :seal)))
          (loop for cut from (getf (second layouts) :start) to seal do
            (multiple-value-bind (manifest prefix status)
                (manifest-fixture-read buffer start cut :version version :max-edits 1
                                       :max-segmenti 2 :max-esiti 0)
              (is (= (getf (first layouts) :end) prefix))
              (is (eq (if (= prefix cut) :complete :tail) status))
              (assert-manifest-model manifest expected)))
          (signals corruption-detected (manifest-fixture-read buffer start end :version version)
                   :manifest-remove-active)
          (is (equalp before buffer)))))))

;;; REQ: REQ-AFF-008 REQ-AFF-009 REQ-FOR-003
(deftest test-REQ-AFF-008-manifest-scanner-and-eof-contracts
  (let* ((specs (subseq (manifest-basic-history) 0 2)) (batches (mapcar #'list specs)))
    (multiple-value-bind (buffer start end layouts) (manifest-log-fixture batches)
      (let ((size (loop for layout in layouts maximize (- (getf layout :end)
                                                        (getf layout :start)))))
        (assert-manifest-model
         (manifest-fixture-read buffer start end :max-bytes (- end start)
            :max-batches 2 :max-batch-records 1 :max-batch-bytes size)
         (manifest-oracle specs))
        (signals resource-exhausted
                 (manifest-fixture-read buffer start end :max-bytes (1- (- end start)))
                 :log-byte-budget)
        (signals resource-exhausted (manifest-fixture-read buffer start end :max-batches 1)
                 :log-batch-budget)
        (signals resource-exhausted
                 (manifest-fixture-read buffer start end :max-batch-bytes (1- size))
                 :batch-byte-budget))
      (signals invalid-argument
               (manifest-fixture-read buffer start (1- end) :file-size (+ 64 end))
               :incomplete-log-buffer)
      (dolist (size (list nil -1 (ash 1 64) (1- (+ 64 end)) (1+ (+ 64 end))))
        (signals invalid-argument (manifest-fixture-read buffer start end :file-size size)
                 :incomplete-log-buffer))
      (dolist (version '(0 3 65535))
        (signals unsupported-format (manifest-fixture-read buffer start end :version version)
                 :record-version))
      (let* ((p (getf (second layouts) :start)) (positions (1+ (- end p 56))))
        (setf (aref buffer p) (logxor 1 (aref buffer p)))
        (signals resource-exhausted
                 (manifest-fixture-read buffer start end :max-search-bytes (1- positions))
                 :log-search-budget)))))

;;; REQ: REQ-AFF-018 REQ-AFF-008 REQ-FOR-003
(deftest test-REQ-AFF-018-manifest-high-file-offset-and-error-provenance
  (dolist (file-offset (list (ash 1 32) (ash 1 63) (- #xffffffffffffffff 4096)))
    (dolist (version '(1 2))
      (let* ((initial (manifest-spec :completo t :next-id #xffffffffffffffff :open 1
                                     :chiusi '((2 64 ((0 0))))))
             (bad (manifest-spec :chiusi '((2 65 ((0 0)))))))
        (multiple-value-bind (buffer start end)
            (manifest-log-fixture (list (list initial)) :version version :file-offset file-offset)
          (assert-manifest-model
           (manifest-fixture-read buffer start end :version version :file-offset file-offset)
           (manifest-oracle (list initial))))
        (multiple-value-bind (buffer start end layouts)
            (manifest-log-fixture (list (list initial bad))
                                  :version version :file-offset file-offset)
          (let ((condition (signals corruption-detected
                             (manifest-fixture-read buffer start end :version version
                                                    :file-offset file-offset)
                             :manifest-closed-conflict)))
            (is (= (+ file-offset (second (getf (first layouts) :records)))
                   (error-offset condition)))))))))

(defun manifest-parallel-history (serie)
  "Serie indipendente con identificativi ed esiti propri; nessuno stato globale mutabile."
  (let ((base (* serie 32)))
    (list (manifest-spec :completo t :next-id (+ base 100) :open (+ base 10)
                         :chiusi (list (list (1+ base) 64 (list (list base 0)))))
          (manifest-spec :open (+ base 11)
                         :chiusi (list (list (+ base 10) 256
                                             (list (list (1+ base) #xffffffffffffffff)))))
          (manifest-spec :chiusi (list (list (+ base 12) 128 nil))
                         :rimossi (list (1+ base))))))

(defun manifest-parallel-worker (specs model serie start-gate common common-model)
  "Un worker possiede buffer/manifest privati; COMMON e i modelli sono sole letture."
  (is (sb-thread:wait-on-semaphore start-gate :timeout 10))
  (assert-manifest-model common common-model)
  (loop for repeat below 8 for version = (if (evenp repeat) 1 2) do
    (multiple-value-bind (buffer start end)
        (manifest-log-fixture (mapcar #'list specs) :version version
                              :file-offset (+ 64 (* serie 4096)))
      (let ((before (copy-seq buffer)))
        (multiple-value-bind (manifest prefix status)
            (manifest-fixture-read buffer start end :version version
                                   :file-offset (+ 64 (* serie 4096)))
          (is (= end prefix)) (is (eq :complete status))
          (assert-manifest-model manifest model)
          (is (equalp before buffer))
          (fill buffer #xff)
          (loop repeat 3 do (assert-manifest-model manifest model)
                            (assert-manifest-model common common-model))))))
  t)

;;; REQ: REQ-AFF-017 REQ-AFF-018 REQ-AFF-008
(deftest test-REQ-AFF-017-manifest-four-independent-series-in-parallel
  (let* ((histories (loop for serie below 4 collect (manifest-parallel-history serie)))
         (expected (mapcar #'manifest-oracle histories))
         (common-specs (manifest-basic-history))
         (common-model (manifest-oracle common-specs))
         (threads nil)
         (start-gate (sb-thread:make-semaphore :count 0)))
    (multiple-value-bind (buffer start end) (manifest-log-fixture (list common-specs))
      (multiple-value-bind (common prefix status) (manifest-fixture-read buffer start end)
        (is (= end prefix)) (is (eq :complete status))
        (fill buffer #xff)
        (assert-manifest-model common common-model)
        (unwind-protect
             (progn
               (loop for specs in histories for model in expected for number from 0 do
                 (let ((owned-specs specs) (owned-model model) (serie number))
                   (push (sb-thread:make-thread
                          (lambda () (manifest-parallel-worker owned-specs owned-model serie start-gate
                                                               common common-model))
                          :name (format nil "manifest-serie-~D" serie)) threads)))
               (sb-thread:signal-semaphore start-gate 4)
               (dolist (thread threads)
                 (is (eq t (sb-thread:join-thread thread :timeout 20 :default :timeout)))))
          ;; Sole risorse del test: ogni attesa e vita del worker ha un limite.
          (dolist (thread threads)
            (when (sb-thread:thread-alive-p thread)
              (sb-thread:terminate-thread thread))))))))
