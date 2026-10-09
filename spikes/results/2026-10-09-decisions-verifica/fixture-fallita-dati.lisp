(:SCHEMA-VERSION 1 :KIND :FAILED-FIXTURE :SCOPE :DECISIONS :PROCESS-ARTIFACT
 "mutazione-baseline-fallita.lisp" :CAUSE
 :SHORT-FRAME-CLASSIFIED-BY-SCANNER-BEFORE-SEMANTIC-PAYLOAD :SOURCE
 ";;;; Seconda lettura C1: ordine fisico dei conflitti dopo il raggruppamento per TXID.
(in-package #:arcdocdb.recovery.tests)

;;; REQ: REQ-TXM-001 REQ-TXM-005 REQ-AFF-009 REQ-AFF-017
(deftest test-REQ-TXM-005-first-physical-decision-conflict-across-txid-groups
  (let* ((maximum (1- (ash 1 64)))
         (file-offset (ash 1 63))
         (a (participant-id 0))
         (b (participant-id maximum #x80))
         (c (participant-id 1 #xff))
         (d (participant-id 2 #xff)))
    (dolist (version '(1 2))
      (dolist (txids (list (list maximum 0) (list 0 maximum)))
        (destructuring-bind (first-txid second-txid) txids
          (let ((specs (list (decision-spec first-txid 0 (list a b c))
                             (decision-spec second-txid 0 (list c a b))
                             (decision-spec first-txid 0 (list b c a))
                             (decision-spec first-txid maximum (list c b a))
                             (decision-spec second-txid 0 (list b a c))
                             (decision-spec second-txid 0 (list a b d)))))
            (dolist (split '(nil t))
              (let ((batches (if split
                                 (list (subseq specs 0 2) (subseq specs 2 4)
                                       (subseq specs 4 6))
                                 (list specs))))
                (multiple-value-bind (buffer start end layouts)
                    (decision-log-fixture batches :version version :file-offset file-offset)
                  (let* ((before (copy-seq buffer))
                         (record-starts (mapcan (lambda (layout)
                                                 (copy-list (getf layout :records)))
                                               layouts))
                         (expected (+ file-offset (fourth record-starts))))
                    ;; La prima discordanza fisica è nel quarto record, anche se
                    ;; il gruppo TXID numericamente minore viene visitato per primo.
                    (loop repeat 2 do
                      (let ((condition
                              (signals corruption-detected
                                (arcdocdb.recovery.decisions:ricostruisci-decisioni
                                  buffer start end :version version :file-offset file-offset
                                  :file-size (+ file-offset end) :max-decisions 6
                                  :max-participants 18 :max-participants-per-decision 3)
                                :decision-conflict)))
                        (is (= expected (error-offset condition)))
                        (is (equalp before buffer))))))))))))))

;;; REQ: REQ-TXM-001 REQ-TXM-005 REQ-AFF-017
(deftest test-REQ-TXM-001-participant-every-byte-and-every-bit
  (let* ((base (make-array 16 :element-type '(unsigned-byte 8) :initial-element #x80))
         (ids (cons base
                    (loop for byte below 16 append
                      (loop for value in '(#x7f #xff) collect
                        (let ((id (copy-seq base))) (setf (aref id byte) value) id)))))
         (spec (decision-spec 31 0 (permute-decisions ids 193))))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end) (decision-log-fixture (list (list spec))
                                                                  :version version)
        (multiple-value-bind (table prefix status)
            (decision-fixture-read buffer start end :version version)
          (is (= end prefix)) (is (eq :complete status))
          (assert-decision-table table (list spec))
          ;; Tutti i 128 bit cambiano l'identità, anche nei byte centrali
          ;; non rappresentati dal prefisso/numero di PARTICIPANT-ID.
          (dotimes (byte 16)
            (dotimes (bit 8)
              (let ((query (copy-seq base)))
                (setf (aref query byte) (logxor (aref query byte) (ash 1 bit)))
                (is (not (member query ids :test #'equalp)))
                (is (not (arcdocdb.recovery.decisions:partecipante-decisione-p
                           table 31 query 0 16))))))
          (fill buffer 0)
          (assert-decision-table table (list spec)))))))

;;; REQ: REQ-FOR-003 REQ-TXM-005 REQ-AFF-017
(deftest test-REQ-FOR-003-sealed-short-or-trailing-decision-payload
  (dolist (version '(1 2))
    (dolist (size '(0 1 7 8 9 43))
      (let* ((body (make-array size :element-type '(unsigned-byte 8) :initial-element 0))
             (short (< size 10)))
        ;; 43 = CSN(8) + count(2) + due ID16(32) + un byte residuo.
        (unless short (reference-le body 8 2 2))
        (multiple-value-bind (buffer start end)
            (decision-record-log-fixture
             (list (list (reference-record 6 0 (bytes) body :version version)))
             :version version)
          (let* ((before (copy-seq buffer))
                 (condition (signals corruption-detected
                              (decision-fixture-read buffer start end :version version)
                              (if short :decision-truncated :decision-trailing-data))))
            (is (not (typep condition 'log-corruption)))
            (is (= (+ start (if short 24 34)) (error-offset condition)))
            (is (equalp before buffer))))))))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-009 REQ-AFF-017
(deftest test-REQ-TXM-005-unsealed-semantic-errors-and-covering-witness
  (dolist (version '(1 2))
    (dolist (bad-parts (list nil (list (participant-id 8) (participant-id 8))))
      (let* ((good (decision-spec 0 0 (list (participant-id 1) (participant-id 2))))
             (bad (decision-spec 0 1 bad-parts))
             (later (decision-spec 17 1 (list (participant-id 3) (participant-id 4)))))
        (multiple-value-bind (buffer start end layouts)
            (decision-log-fixture (list (list good) (list bad) (list later)) :version version)
          (let* ((failed (second layouts)) (p (getf failed :start))
                 (cut (getf failed :seal)) (before (copy-seq buffer)))
            ;; Una DECISION completa ma non sigillata non sostituisce quella
            ;; del prefisso e non consuma i suoi budget semantici.
            (multiple-value-bind (table prefix status)
                (decision-fixture-read buffer start cut :version version
                   :max-decisions 1 :max-participants 2 :max-participants-per-decision 2)
              (is (= p prefix)) (is (eq :tail status))
              (assert-decision-table table (list good) '(17)))
            (is (equalp before buffer))
            (setf (aref buffer cut) (logxor 1 (aref buffer cut)))
            (set-durable buffer (third layouts) (+ 64 p 1))
            (setf before (copy-seq buffer))
            (let ((condition (signals log-corruption
                               (decision-fixture-read buffer start end :version version
                                                      :max-decisions 0)
                               :log-durable-corruption)))
              (is (= p (corruption-prefix-end condition)))
              (is (= (+ 64 p) (error-offset condition)))
              (is (= (+ 64 (getf (third layouts) :seal))
                     (corruption-witness-offset condition)))
              (is (= (+ 64 p 1) (corruption-durable-offset condition)))
              (is (eq :header-crc (corruption-first-reason condition)))
              (is (equalp before buffer)))))))))

;;; REQ: REQ-AFF-008 REQ-TXM-005 REQ-TXM-001
(deftest test-REQ-AFF-008-decision-budget-offsets-before-coalescence
  (let* ((file-offset (ash 1 63))
         (spec (decision-spec 0 0 (list (participant-id 1) (participant-id 2)))))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end layouts)
          (decision-log-fixture (list (list spec) (list spec spec))
                                :version version :file-offset file-offset)
        (let ((before (copy-seq buffer)))
          (let ((condition (signals resource-exhausted
                             (decision-fixture-read buffer start end :version version
                                :file-offset file-offset :max-decisions 2)
                             :decision-count-budget)))
            (is (= (+ file-offset start) (error-offset condition))))
          (let ((condition (signals resource-exhausted
                             (decision-fixture-read buffer start end :version version
                                :file-offset file-offset :max-participants 5)
                             :decision-participant-budget)))
            (is (= (+ file-offset (second (getf (second layouts) :records)))
                   (error-offset condition))))
          (let ((condition (signals resource-exhausted
                             (decision-fixture-read buffer start end :version version
                                :file-offset file-offset :max-participants-per-decision 1)
                             :metadata-budget)))
            ;; Gli errori del codec conservano offset relativi al buffer.
            (is (= (+ start 24) (error-offset condition))))
          (is (equalp before buffer)))))))
"
 :BASELINE-OUTPUT
 "decision-test-start TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
ok    TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
decision-test-start TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
ok    TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
decision-test-start TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
ok    TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
decision-test-start TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
ok    TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
ok    TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
decision-test-start TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
ok    TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
decision-test-start TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
ok    TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
decision-test-start TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
ok    TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
decision-test-start TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
ok    TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
decision-test-start TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
ok    TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
decision-test-start TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
ok    TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
decision-test-start TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
ok    TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
decision-test-start TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
ok    TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
decision-test-start TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
ok    TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
decision-test-start TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
ok    TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
decision-test-start TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
ok    TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
decision-test-start TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
ok    TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
decision-test-start TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
ok    TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
ok    TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
decision-test-start TEST-REQ-FOR-003-SEALED-SHORT-OR-TRAILING-DECISION-PAYLOAD
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {8005970393}>:
  Asserzione recovery fallita: (TYPEP CONDITION 'CORRUPTION-DETECTED)

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005970393}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {800842CF53}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {800842CF53}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {800842CF53}>)
3: (ERROR \"Asserzione recovery fallita: ~S\" (TYPEP CONDITION (QUOTE CORRUPTION-DETECTED)))
4: (TEST-REQ-FOR-003-SEALED-SHORT-OR-TRAILING-DECISION-PAYLOAD)
5: (\"top level form\") [toplevel]
6: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
7: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
8: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
9: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
10: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
11: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4 NIL)
12: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4)
13: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 4)
14: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {108ED0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
15: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-final-nh56qkmz/spikes/out/decisions-mutants-final/baseline/tools/decisions-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
16: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-final-nh56qkmz/spikes/out/decisions-mutants-final/baseline/tools/decisions-isolated-build.lisp\" {80052B0043}> NIL)
17: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {108ED09EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-final-nh56qkmz/spikes/out/decisions-mutants-final/baseline/tools/decisions-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-final-nh56qkmz/spikes/out/decisions-mutants-final/baseline/tools/decisions-isolated-build.lisp\" {80052B0043}>)
18: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-final-nh56qkmz/spikes/out/decisions-mutants-final/baseline/tools/decisions-isolated-build.lisp\" {80052B0043}> NIL)
19: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-final-nh56qkmz/spikes/out/decisions-mutants-final/baseline/tools/decisions-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
20: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-final-nh56qkmz/spikes/out/decisions-mutants-final/baseline/tools/decisions-isolated-build.lisp\" {80052B0043}>)
21: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
22: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
23: (SB-IMPL::PROCESS-SCRIPT \"tools/decisions-isolated-build.lisp\")
24: (SB-IMPL::TOPLEVEL-INIT)
25: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
26: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
27: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
