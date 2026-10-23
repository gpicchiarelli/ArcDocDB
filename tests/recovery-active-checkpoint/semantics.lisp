;;;; Nominali readonly su FD reali: fatti attesi dichiarati prima del setup.
;;; OWNER: ogni ra-with-case possiede file, scratch e tabella completa della fixture.
;;; SHARED: nessun override, writer concorrente o pubblicazione fra Serie.
(in-package #:arcdocdb.recovery.active.checkpoint.tests)

(defun ra-sem-bytes (&rest values)
  "Ottetti dichiarativi di input, indipendenti dai codec del prodotto."
  (make-array (length values) :element-type '(unsigned-byte 8) :initial-contents values))

(defun ra-sem-le (buffer start width value)
  "Oracolo CLOSED: packing little-endian bytewise senza scrivi-uXX del prodotto."
  (dotimes (i width)
    (setf (aref buffer (+ start i)) (ldb (byte 8 (* 8 i)) value))))

(defun ra-sem-closure-bytes (prefix derived)
  "ID9 e coppie gia ordinate sono fatti della fixture, non letti dal risultato."
  (let ((buffer (make-array (+ 20 (* 16 (length derived)))
                            :element-type '(unsigned-byte 8) :initial-element 0)))
    (ra-sem-le buffer 0 8 9)
    (ra-sem-le buffer 8 8 prefix)
    (ra-sem-le buffer 16 4 (length derived))
    (loop for (txid csn) in derived for position from 20 by 16
          do (ra-sem-le buffer position 8 txid)
             (ra-sem-le buffer (+ position 8) 8 csn))
    buffer))

(defun ra-sem-check-closure (result expected)
  "Confronta byte grezzi e tutte le sentinelle, con offset non nullo."
  (let* ((start 5) (end (+ start (length expected)))
         (output (make-array (+ end 7) :element-type '(unsigned-byte 8)
                             :initial-element #xa7))
         (wanted (copy-seq output)))
    (replace wanted expected :start1 start)
    (is (= (length expected) (ra:lunghezza-chiusura-active result)))
    (is (= end (ra:scrivi-chiusura-active result output start)))
    (is (equalp wanted output))))

(defun ra-sem-check-result (result segment version prefix statistics derived probes expected)
  "Sole API pubbliche: frontiere, classi, capacita opaca, presenza distinta da CSN0."
  (is (typep result 'ra:active-recuperato))
  (is (typep segment 'g:segmento-get))
  (is (eq segment (ra:segmento-active-recuperato result)))
  (is (equal (list prefix prefix :complete version)
             (multiple-value-list (ra:frontiere-active-recuperato result))))
  (is (equal statistics (multiple-value-list (ra:statistiche-active-recuperato result))))
  (dolist (entry derived)
    (destructuring-bind (txid csn) entry
      (is (equal (list t csn) (multiple-value-list (ra:esito-chiusura-active result txid))))))
  (dolist (txid probes)
    (is (equal '(nil 0) (multiple-value-list (ra:esito-chiusura-active result txid)))))
  (ra-sem-check-closure result expected))

(defun ra-sem-case (version batches decisions prefix statistics derived probes)
  "Attesi e bytes CLOSED precedono i file; scratch distrutto soltanto dopo il ritorno."
  (let ((expected (ra-sem-closure-bytes prefix derived)))
    (ra-with-case version batches decisions
      (lambda (case deadline)
        (declare (ignore deadline))
        (is (= 9 (ra-case-id case)))
        (is (= prefix (length (ra-case-bytes case))))
        (let ((before (ra-observations case)))
          (ra-reset-calls case)
          (let* ((result (ra-read case))
                 (segment (ra:segmento-active-recuperato result))
                 (after-read (ra-calls case)))
            (is (every (lambda (byte) (= byte #xcc)) (subseq (ra-case-scratch case) prefix)))
            (ra-sem-check-result result segment version prefix statistics derived probes expected)
            ;; Il caller puo riusare i byte del file letti: nessun alias nel risultato.
            ;; Le sette sentinelle dello scratch restano fuori dal range distrutto.
            (fill (ra-case-scratch case) #x5a :end prefix)
            (is (every (lambda (byte) (= byte #xcc)) (subseq (ra-case-scratch case) prefix)))
            (ra-sem-check-result result segment version prefix statistics derived probes expected)
            (is (equalp after-read (ra-calls case)))
            (is (equalp before (ra-observations case)))
            (ra-no-writes case)
            (ra-check-bytes case)))))))

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-AFF-009
(deftest test-REQ-REC-001-active-recovery-header-only-native-v1-v2
  (dolist (version '(1 2))
    ;; Header64, nessun SEAL o record; DECISION log completo realmente vuoto.
    (ra-sem-case version nil nil 64 '(0 0 0 0 0 0) nil '(0 1 #xffffffffffffffff))))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-TXM-007
(deftest test-REQ-REC-001-active-recovery-ordinary-put-tombstone-native-v1-v2
  (dolist (version '(1 2))
    ;; 64 + PUT(24+1+1) + tombstone(24+1) + SEAL56 =171.
    (let ((batches (list (ra-batch 17
                          (ra-record :put 17 :key (ra-sem-bytes 11) :value (ra-sem-bytes 161))
                          (ra-record :tombstone 17 :key (ra-sem-bytes 22))))))
      (ra-sem-case version batches nil 171 '(1 2 0 0 0 0) nil '(0 17 18)))))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-TXM-007
(deftest test-REQ-TXM-007-active-recovery-local-outcome-native-v1-v2
  (dolist (version '(1 2))
    (dolist (global-present '(nil t))
      ;; Prepared PUT+tombstone nello stesso lotto; OUTCOME in un secondo lotto.
      ;; 64 +(26+25+56) +(32+56) =259; prova locale non duplicata nella CLOSED.
      (let ((batches (list
                      (ra-batch 21
                        (ra-record :prepared-put 37 :key (ra-sem-bytes 11) :value (ra-sem-bytes 161))
                        (ra-record :prepared-tombstone 37 :key (ra-sem-bytes 22)))
                      (ra-batch 43 (ra-record :outcome 37 :csn 43))))
            (decisions (when global-present (list (ra-decision 37 43)))))
        (ra-sem-case version batches decisions 259 '(2 3 1 1 0 0) nil '(0 36 37 38))))))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-TXM-007 REQ-FOR-003
(deftest test-REQ-TXM-005-active-recovery-derived-zero-high-u64-native-v1-v2
  (dolist (version '(1 2))
    ;; Tre prepared in lotti distinti, ordine fisico diverso dall'ordine della CLOSED.
    ;; 64 +3*(26+56) =310; zero e' CSN presente, tutte le word u64 sono significative.
    (let ((batches (list
                    (ra-batch 11 (ra-record :prepared-put #xffffffffffffffff
                                           :key (ra-sem-bytes 11) :value (ra-sem-bytes 161)))
                    (ra-batch 12 (ra-record :prepared-put 7
                                           :key (ra-sem-bytes 22) :value (ra-sem-bytes 178)))
                    (ra-batch 13 (ra-record :prepared-put 0
                                           :key (ra-sem-bytes 33) :value (ra-sem-bytes 195)))))
          (decisions (list (ra-decision 7 #x8000000000000001)
                           (ra-decision #xffffffffffffffff #xffffffffffffffff)
                           (ra-decision 0 0))))
      (ra-sem-case version batches decisions 310 '(3 3 3 0 3 0)
                   '((0 0) (7 #x8000000000000001) (#xffffffffffffffff #xffffffffffffffff))
                   '(1 6 8 #xfffffffffffffffe)))))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-TXM-007
(deftest test-REQ-TXM-005-active-recovery-presumed-abort-native-v1-v2
  (dolist (version '(1 2))
    ;; Tabella completa con decisione estranea: assenza dei TXID17/18 verificata dal modello.
    ;; 64 +(26+56) +(25+56) =227; ne' i prepared abortiti ne' DECISION99 creano esiti.
    (let ((batches (list
                    (ra-batch 11 (ra-record :prepared-put 17
                                           :key (ra-sem-bytes 11) :value (ra-sem-bytes 161)))
                    (ra-batch 12 (ra-record :prepared-tombstone 18 :key (ra-sem-bytes 22)))))
          (decisions (list (ra-decision 99 101))))
      (ra-sem-case version batches decisions 227 '(2 2 2 0 0 2) nil '(0 17 18 99)))))

;;; REQ: REQ-REC-001 REQ-TXM-007
(deftest test-REQ-TXM-007-active-recovery-orphan-outcome-native-v1-v2
  (dolist (version '(1 2))
    ;; 64 +OUTCOME32 +SEAL56 =152; nessun prepared da classificare.
    (let ((batches (list (ra-batch 43 (ra-record :outcome #x100000001 :csn 43)))))
      (ra-sem-case version batches nil 152 '(1 1 0 0 0 0) nil '(0 43 #x100000001)))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-FOR-003
(deftest test-REQ-TXM-007-active-recovery-identical-outcomes-native-v1-v2
  (dolist (version '(1 2))
    ;; Duplicati fisici contano come due record, ma il TXID e' committed locale una volta.
    ;; 64 +(26+56) +(2*32+56) =266; anche il CSN massimo resta identico alla DECISION.
    (let ((batches (list
                    (ra-batch 11 (ra-record :prepared-put 51
                                           :key (ra-sem-bytes 11) :value (ra-sem-bytes 161)))
                    (ra-batch #xffffffffffffffff
                      (ra-record :outcome 51 :csn #xffffffffffffffff)
                      (ra-record :outcome 51 :csn #xffffffffffffffff))))
          (decisions (list (ra-decision 51 #xffffffffffffffff))))
      (ra-sem-case version batches decisions 266 '(2 3 1 1 0 0) nil '(0 50 51 52)))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-AFF-008-active-recovery-serializer-range-and-identity-alias-no-write
  (dolist (version '(1 2))
    (ra-with-case version
        (list (ra-batch 11 (ra-record :prepared-put 17 :key (ra-sem-bytes 11)
                                     :value (ra-sem-bytes 161))))
        (list (ra-decision 17 0))
      (lambda (case deadline)
        (declare (ignore deadline))
        (let* ((result (ra-read case))
               ;; Una entry derivata richiede 36 byte; start3+36 supera length38 di uno.
               (output (make-array 38 :element-type '(unsigned-byte 8) :initial-element #xa7))
               (before (copy-seq output))
               (identity (g::vista-get-serie-identity (ra-case-view case)))
               (identity-before (copy-seq identity)) (calls (ra-calls case)))
          (signals invalid-argument (ra:scrivi-chiusura-active result output 3) :buffer-range)
          (is (equalp before output))
          (signals invalid-argument (ra:scrivi-chiusura-active result identity 0)
                   :active-recovery-closure-alias)
          (is (equalp identity-before identity))
          (is (equalp calls (ra-calls case)))
          (ra-no-writes case)
          (ra-check-bytes case))))))
