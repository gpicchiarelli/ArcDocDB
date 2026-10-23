;;; OWNER: test seriale, array di prove privati; nessuna pubblicazione o I/O.
;;; SHARED: nessuno; accesso interno dichiarato per contratti radix e lookup.
(in-package #:arcdocdb.get.resolver.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

(defun resolver-reference-proofs (entries)
  "Tuple indipendenti (TXID CSN OFFSET), codificate come cinque word u32.
Nessuna chiamata a encoding, ordinamento o ricerca del prodotto."
  (let ((words (make-array (* 5 (length entries)) :element-type '(unsigned-byte 32)
                          :initial-element 0)))
    (loop for (txid csn offset) in entries for base from 0 by 5 do
      (setf (aref words base) (ldb (byte 32 0) txid)
            (aref words (+ base 1)) (ldb (byte 32 32) txid)
            (aref words (+ base 2)) (ldb (byte 32 0) csn)
            (aref words (+ base 3)) (ldb (byte 32 32) csn)
            (aref words (+ base 4)) offset))
    words))

;;; REQ: REQ-FOR-004 REQ-AFF-008
(deftest test-REQ-FOR-004-resolver-radix-all-eight-octets
  (let* ((entries '((#xfedcba9876543210 #x100000001 64)
                    (#x0102030405060708 #xffffffffffffffff 96)))
         (proofs (resolver-reference-proofs entries)))
    ;; Attesi espliciti: verifica la selezione della word e di ogni cifra LSD.
    (loop for expected across #(16 50 84 118 152 186 220 254) for digit from 0 do
      (is (= expected (r::cifra-prova-resolver proofs 0 digit))))
    (loop for expected across #(8 7 6 5 4 3 2 1) for digit from 0 do
      (is (= expected (r::cifra-prova-resolver proofs 5 digit))))))

;;; REQ: REQ-FOR-004 REQ-AFF-008
(deftest test-REQ-FOR-004-resolver-radix-zero-and-single-proof
  (dolist (entries '(nil ((#xffffffffffffffff #xffffffff00000001 64))))
    (let* ((proofs (resolver-reference-proofs entries)) (before (copy-seq proofs)))
      (is (eq proofs (r::ordina-prove-resolver proofs)))
      (is (equalp before proofs))
      (multiple-value-bind (found base) (r::trova-prova-resolver proofs #xffffffff #xffffffff)
        (is (eq (not (null entries)) found)) (is (zerop base))))))

;;; REQ: REQ-FOR-004 REQ-AFF-008
(deftest test-REQ-FOR-004-resolver-radix-u64-order-and-stable-duplicates
  (let* ((input (resolver-reference-proofs
                 '((#xffffffffffffffff #x100000002 64) (#x100000001 #x100000002 96)
                   (#xffffffff #x100000002 128) (1 #x100000002 160)
                   (#x100000000 #x100000002 192) (#x100000001 #x100000002 224)
                   (#x8000000000000000 #x100000002 256))))
         (expected (resolver-reference-proofs
                    '((1 #x100000002 160) (#xffffffff #x100000002 128)
                      (#x100000000 #x100000002 192) (#x100000001 #x100000002 96)
                      (#x100000001 #x100000002 224) (#x8000000000000000 #x100000002 256)
                      (#xffffffffffffffff #x100000002 64)))))
    (is (equalp expected (r::ordina-prove-resolver input)))))

;;; REQ: REQ-FOR-004 REQ-AFF-008
(deftest test-REQ-FOR-004-resolver-lookup-first-duplicate-and-u64-borders
  (let ((proofs (resolver-reference-proofs
                 '((1 17 64) (#xffffffff 18 96) (#x100000000 19 128)
                   (#x100000001 20 160) (#x100000001 20 192)
                   (#x8000000000000000 21 224) (#xffffffffffffffff 22 256)))))
    (dolist (query '((0 1 0) (0 #xffffffff 5) (1 0 10) (1 1 15)
                     (#x80000000 0 25) (#xffffffff #xffffffff 30)))
      (multiple-value-bind (found base) (r::trova-prova-resolver proofs (first query) (second query))
        (is found) (is (= (third query) base))))
    ;; Sotto, sopra e fra TXID: high e low diversi devono restare miss.
    (dolist (query '((0 0) (0 2) (1 2) (2 1) (#x80000000 1) (#xffffffff #xfffffffe)))
      (is (equal '(nil 0) (multiple-value-list
                           (r::trova-prova-resolver proofs (first query) (second query))))))))

;;; REQ: REQ-FOR-004 REQ-AFF-008
(deftest test-REQ-FOR-004-resolver-duplicate-csn-each-word-conflicts
  (dolist (conflicting '(#x100000002 #x200000001))
    (let ((proofs (resolver-reference-proofs (list (list #x100000001 #x100000001 64)
                                                 (list #x100000001 conflicting 96)))))
      (signals corruption-detected (r::ordina-prove-resolver proofs) :resolver-conflicting-outcome))))

;;; REQ: REQ-FOR-004 REQ-AFF-008
(deftest test-REQ-FOR-004-resolver-order-high-low-and-physical-offset
  (dolist (entries '(((#x100000000 17 64) (#xffffffff 17 96))
                     ((#x100000002 17 64) (#x100000001 17 96))))
    (signals invariant-violation
      (r::verifica-ordine-prove-resolver (resolver-reference-proofs entries)) :resolver-proof-order))
  (dolist (second-offset '(64 32))
    (signals invariant-violation
      (r::verifica-ordine-prove-resolver
       (resolver-reference-proofs (list (list #xffffffffffffffff 17 64)
                                        (list #xffffffffffffffff 17 second-offset))))
      :resolver-proof-physical-order)))

;;; REQ: REQ-FOR-004 REQ-AFF-008
(deftest test-REQ-FOR-004-resolver-proof-shape-before-sort-or-search
  (let ((bad (make-array 6 :element-type '(unsigned-byte 32) :initial-element 0)))
    (signals invariant-violation (r::ordina-prove-resolver bad) :resolver-proof-shape)
    (signals invariant-violation (r::verifica-ordine-prove-resolver bad) :resolver-proof-shape)
    (signals invariant-violation (r::trova-prova-resolver bad 0 1) :resolver-proof-shape)))

;;; REQ: REQ-FOR-004 REQ-AFF-008
(deftest test-REQ-FOR-004-resolver-radix-preflight-no-partial-effects
  (let* ((source (resolver-reference-proofs '((#x100000001 17 64) (1 18 96))))
         (target (make-array 10 :element-type '(unsigned-byte 32) :initial-element #xa5))
         (histogram (make-array 256 :element-type '(unsigned-byte 32) :initial-element #x5a))
         (source-copy (copy-seq source)) (target-copy (copy-seq target))
         (histogram-copy (copy-seq histogram)))
    (dolist (args (list (list source target histogram 1)
                       (list source source histogram 2)
                       (list source (subseq target 0 5) histogram 2)
                       (list source target (subseq histogram 0 255) 2)))
      (signals invariant-violation
        (r::passata-prove-resolver (first args) (second args) (third args) (fourth args) 0)
        :resolver-radix-shape)
      (is (equalp source-copy source)) (is (equalp target-copy target))
      (is (equalp histogram-copy histogram)))))
