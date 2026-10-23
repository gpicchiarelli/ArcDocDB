(in-package #:arcdocdb.fulltext.format.tests)

(deftest REQ-SEC-008-crc-valid-header-errors
  (multiple-value-bind (buffer start end identity) (fixture)
    (dolist (case '((0 0 1 corruption-detected :fulltext-magic)
                    (8 3 2 unsupported-format :fulltext-version)
                    (10 4 2 corruption-detected :fulltext-kind)
                    (12 5 2 corruption-detected :fulltext-header-fields)
                    (14 1 2 corruption-detected :fulltext-header-fields)
                    (16 32 1 corruption-detected :fulltext-source-identity)
                    (32 0 8 corruption-detected :fulltext-source-identity)
                    (40 0 8 corruption-detected :fulltext-file-length)
                    (48 65 8 corruption-detected :fulltext-file-length)
                    (60 1 4 corruption-detected :fulltext-header-fields)))
      (destructuring-bind (offset value width type reason) case
        (let ((changed (copy-seq buffer)))
          (ref-le changed (+ start offset) value width) (repair changed start end)
          (rejection (lambda () (verifica-cornice-indice-full-text
                                  changed start end identity #xffffffffffffffff)) type reason))))))

(deftest REQ-SEC-008-crc-valid-directory-errors
  (multiple-value-bind (buffer start end identity) (fixture)
    (dotimes (section 6)
      (dolist (field '(0 2 4 8 16))
        (let* ((changed (copy-seq buffer)) (offset (+ start 64 (* section 24) field)))
          (if (= field 16) (ref-le changed offset #xffffffffffffffff 8)
              (incf (aref changed offset)))
          (repair changed start end)
          (rejection (lambda () (verifica-cornice-indice-full-text
                                  changed start end identity #xffffffffffffffff))
                     'corruption-detected nil))))
    (let ((changed (copy-seq buffer)))
      (ref-le changed (+ start 64 16) 0 8) (repair changed start end)
      (rejection (lambda () (verifica-cornice-indice-full-text
                              changed start end identity #xffffffffffffffff))
                 'corruption-detected :fulltext-meta-length))
    (dolist (offset '(209 210 211 212 213 214 215 289 290 291 292 293 294 295))
      (let ((changed (copy-seq buffer)))
        (setf (aref changed (+ start offset)) 1) (repair changed start end)
        (rejection (lambda () (verifica-cornice-indice-full-text
                                changed start end identity #xffffffffffffffff))
                   'corruption-detected nil)))))

(deftest REQ-SEC-010-preflight-preserves-destination
  (multiple-value-bind (buffer start end identity section-lengths) (fixture)
    (let ((before (copy-seq buffer)))
      (dolist (case (list (list nil start end identity 1 section-lengths)
                         (list buffer -1 end identity 1 section-lengths)
                         (list buffer start (1+ (length buffer)) identity 1 section-lengths)
                         (list buffer end start identity 1 section-lengths)
                         (list buffer start end (octets '(1)) 1 section-lengths)
                         (list buffer start end identity -1 section-lengths)
                         (list buffer start end identity (expt 2 64) section-lengths)
                         (list buffer start end identity 1 #(1 64 9 48 16 32))
                         (list buffer start end identity 1 (lengths 0 64 9 48 16 32))
                         (list buffer start end identity 1 (lengths 65537 64 9 48 16 32))
                         (list buffer start end identity 1 (lengths 1 63 9 48 16 32))))
        (rejection (lambda () (apply #'scrivi-cornice-indice-full-text case)) 'invalid-argument nil)
        (is (equalp before buffer)))
      (dolist (lengths (list (lengths 1 96 9 48 16 32) (lengths 1 #xffffffffffffffe0 9 48 16 32)))
        (rejection (lambda () (scrivi-cornice-indice-full-text buffer start end identity 1 lengths))
                   'resource-exhausted :fulltext-capacity)
        (is (equalp before buffer)))
      (rejection (lambda () (scrivi-cornice-indice-full-text
                              buffer start end identity 1 section-lengths :max-bytes (1- (- end start))))
                 'resource-exhausted :fulltext-file-budget)
      (is (equalp before buffer)))))

(deftest REQ-SEC-010-reader-input-and-budget
  (multiple-value-bind (buffer start end identity) (fixture)
    (dolist (args (list (list nil start end identity 1) (list buffer start end nil 1)
                       (list buffer start end identity 1 :max-bytes 0)
                       (list buffer start end identity 1 :max-bytes "x")))
      (rejection (lambda () (apply #'verifica-cornice-indice-full-text args)) 'invalid-argument nil))
    (rejection (lambda () (verifica-cornice-indice-full-text
                            buffer start end identity #xffffffffffffffff :max-bytes (1- (- end start))))
               'resource-exhausted :fulltext-file-budget)))
