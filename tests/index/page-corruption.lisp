;;; REQ: REQ-IDX-009 REQ-AFF-002
(in-package #:arcdocdb.index.page.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

(defun mutated (offset value width reason &key (kind :bucket) (repair-crc t))
  (let ((body (if (eq kind :bucket) (bucket-body 4096 (list #(7 8))) (directory-body 1 4096))))
    (multiple-value-bind (original start end id)
        (raw-page 4096 kind body (if (eq kind :bucket) 1 2)
                  (if (eq kind :bucket) 32 (+ 1 (* 63 256))))
      (let ((buffer (copy-seq original)))
        (ref-write buffer (+ start offset) value width)
        (when repair-crc (repair buffer start end))
        (let ((copy (copy-seq buffer)))
          (signals corruption-detected (p:verifica-pagina-indice buffer start end id) reason)
          (is (equalp copy buffer)))))))

(deftest req-idx-009-corruzione-ogni-byte-pagina-4k
  (multiple-value-bind (buffer start end id)
      (raw-page 4096 :bucket (bucket-body 4096 (list #(1 2 3))) 1 32)
    (loop for offset from start below end do
      (setf (aref buffer offset) (logxor 1 (aref buffer offset)))
      (signals corruption-detected (p:verifica-pagina-indice buffer start end id))
      (setf (aref buffer offset) (logxor 1 (aref buffer offset))))))

(deftest req-idx-009-header-e-crc-validi-non-bastano
  (dolist (item '((0 0 1 :index-page-magic) (4 0 4 :index-page-magic)
                  (11 16 1 :index-page-header-fields) (12 1 4 :index-page-header-fields)
                  (84 1 4 :index-page-header-fields) (56 4001 4 :index-page-header-domain)
                  (60 65536 4 :index-page-header-domain) (64 1 8 :index-page-reference)
                  (64 1152921504606846976 8 :index-page-header-domain)))
    (apply #'mutated item))
  (mutated 4095 1 1 :index-page-padding)
  (multiple-value-bind (buffer start end id) (raw-page 4096 :chiave #(1) 1 0)
    (ref-write buffer (+ start 8) 2 2) (repair buffer start end)
    (signals unsupported-format (p:verifica-pagina-indice buffer start end id) :index-page-version)
    (ref-write buffer (+ start 8) 1 2) (ref-write buffer (+ start 10) 99 1) (repair buffer start end)
    (signals unsupported-format (p:verifica-pagina-indice buffer start end id) :index-page-kind)))

(deftest req-idx-009-slot-e-chiavi-semanticamente-incoerenti
  ;; Corpo a +96, controlli 32, prima entry +128: gli offset sono indipendenti dal prodotto.
  (dolist (item '((96 254 1 :index-page-control) (96 6 1 :index-page-fingerprint)
                  (136 0 8 :index-page-record) (152 24 4 :index-page-record)
                  (152 16842776 4 :index-page-record) (152 16777243 4 :index-page-record)
                  (144 4294967295 4 :index-page-record)
                  (156 0 2 :index-page-record) (158 2 2 :index-page-key-flags)
                  (156 3 2 :index-page-inline-key)
                  (160 2081 4 :index-page-inline-key) (164 1 4 :index-page-entry-reserved)
                  (168 4096 8 :index-page-inline-key) (184 1 8 :index-page-entry-reserved)
                  (60 0 4 :index-page-bucket-count) (56 2083 4 :index-page-bucket-count)
                  (80 64 4 :index-page-bucket-layout)
                  (192 1 8 :index-page-empty-slot)))
    (apply #'mutated item))
  ;; Home group 16 invece di 0, fingerprint immutato: il miss sul gruppo vuoto lo nasconderebbe.
  (mutated 128 2053 4 :index-page-probe))

(deftest req-idx-009-riferimenti-directory-non-canonici
  (dolist (item '((64 4096 8 :index-page-reference) (72 8 8 :index-page-reference)
                  (96 0 8 :index-page-reference) (104 0 8 :index-page-reference)
                  (96 16777216 8 :index-page-reference) (96 4097 8 :index-page-reference)
                  (96 16781312 8 :index-page-reference)
                  (104 8 8 :index-page-reference) (104 1152921504606846976 8 :index-page-reference-domain)
                  (96 1152921504606846976 8 :index-page-reference-domain)
                  (80 0 4 :index-page-directory-geometry)
                  (80 8 4 :index-page-directory-geometry)
                  (80 65537 4 :index-page-directory-geometry)
                  (80 16130 4 :index-page-directory-geometry)
                  (56 31 4 :index-page-directory-layout)
                  (60 1 4 :index-page-directory-count) (60 3 4 :index-page-directory-layout)))
    (destructuring-bind (offset value width reason) item
      (mutated offset value width reason :kind :directory))))

(deftest req-idx-009-troncamenti-e-guardie
  (dolist (size '(4096 16384 65536))
    (multiple-value-bind (buffer start end id) (raw-page size :chiave #(0 255) 2 0)
      (dolist (length (list 0 1 95 96 4095 (1- size)))
        (signals corruption-detected (p:verifica-pagina-indice buffer start (+ start length) id)
                 :index-page-size))
      (signals invalid-argument (p:verifica-pagina-indice buffer -1 end id) :buffer-range)
      (signals invalid-argument (p:verifica-pagina-indice buffer start (1+ (length buffer)) id)
               :buffer-range)
      (dolist (short '(4096 16384))
        (when (< short size)
          (signals corruption-detected (p:verifica-pagina-indice buffer start (+ start short) id)
                   :index-page-header-fields))))))
