;;; REQ: REQ-IDX-009 REQ-LIM-003
(in-package #:arcdocdb.index.page.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

(deftest req-idx-009-fixture-indipendenti-tre-taglie-e-tipi
  (dolist (size '(4096 16384 65536))
    (roundtrip size :bucket (bucket-body size nil) 0 (capacity size))
    (roundtrip size :bucket (bucket-body size (list #(0) #(0 255) #(255 0 255))) 3 (capacity size))
    (roundtrip size :directory (directory-body 1 size) 2 (+ 1 (* 63 256)))
    (roundtrip size :chiave #(0 255 10) 3 0)))

(deftest req-idx-009-collisioni-overflow-e-saturazione
  (dolist (size '(4096 16384 65536))
    (let* ((limit (* 7 (floor (capacity size) 8)))
           (keys (loop for i below limit collect (vector (mod i 256) (floor i 256)))))
      ;; Stesso digest completo: solo chiavi differenti, sonda fino ai gruppi successivi.
      (roundtrip size :bucket (bucket-body size keys :collision t) limit (capacity size)
                 :next (* size 50) :next-generation 6)
      (multiple-value-bind (buffer start end id)
          (raw-page size :bucket (bucket-body size (append keys (list #(99 99))) :collision t)
                    (1+ limit) (capacity size))
        (signals corruption-detected (p:verifica-pagina-indice buffer start end id)
                 :index-page-bucket-layout)))))

(deftest req-idx-009-directory-radix-e-massimi
  (dolist (size '(4096 16384 65536))
    (let ((bits (ecase size (4096 7) (16384 9) (65536 11))))
      (roundtrip size :directory (directory-body bits size) (expt 2 bits)
                 (+ bits (* (- 64 bits) 256)))
      (roundtrip size :directory (directory-body 1 size :empty t) 0 1))))

(deftest req-idx-009-identita-copiata-e-riferimenti-attesi
  (let* ((uuid (series)) (id (p:crea-identita-pagina uuid 91 (* 4096 4096) 7)))
    (fill uuid 0)
    (multiple-value-bind (buffer start end) (raw-page 4096 :chiave #(7) 1 0)
      (is (eq :chiave (p:verifica-pagina-indice buffer start end id)))
      (dolist (wrong (list (identita-fixture 4096 :image 92) (identita-fixture 4096 :generation 8)
                          (identita-fixture 4096 :page (* 4096 4095))
                          (p:crea-identita-pagina (bytes 16) 91 (* 4096 4096) 7)))
        (signals corruption-detected (p:verifica-pagina-indice buffer start end wrong)
                 :index-page-identity)))))

(deftest req-idx-009-preflight-senza-effetti
  (let* ((id (identita-fixture 4096)) (body (bucket-body 4096 (list #(1 2))))
         (target (bytes 4115 #xcd)) (copy (copy-seq target))
         (plan (p:crea-descrittore-pagina id :bucket 1 32)))
    (signals invalid-argument (p:scrivi-pagina-indice target 7 4103 plan target 7 2089)
             :index-page-alias)
    (signals invalid-argument (p:scrivi-pagina-indice target -1 4095 plan body 0 (length body))
             :buffer-range)
    (signals invalid-argument (p:scrivi-pagina-indice target 7 4102 plan body 0 (length body))
             :index-page-size)
    (signals invalid-argument (p:scrivi-pagina-indice target 7 4103 plan body -1 (length body))
             :buffer-range)
    (signals invalid-argument (p:scrivi-pagina-indice target 7 4103 plan (bytes 0) 0 0)
             :index-page-bucket-layout)
    (setf (aref body 0) 254)
    (signals invalid-argument (p:scrivi-pagina-indice target 7 4103 plan body 0 (length body))
             :index-page-control)
    (is (equalp target copy))))

(deftest req-idx-009-domini-descrittore
  (signals invalid-argument (p:crea-identita-pagina (bytes 15) 1 1 1) :index-page-series)
  (dolist (bad '(0 -1 1/2 1.0 #x1000000000000000))
    (signals invalid-argument (p:crea-identita-pagina (series) bad 4096 1) :index-page-identity)
    (signals invalid-argument (p:crea-identita-pagina (series) 1 bad 1) :index-page-identity)
    (signals invalid-argument (p:crea-identita-pagina (series) 1 4096 bad) :index-page-identity))
  (let ((id (identita-fixture 4096)))
    (signals invalid-argument (p:crea-descrittore-pagina id :ignoto 0 0) :index-page-kind)
    (dolist (args '((:bucket -1 32) (:bucket 65536 32) (:bucket 0 -1) (:bucket 0 4294967296)))
      (signals invalid-argument (apply #'p:crea-descrittore-pagina id args) :index-page-descriptor))
    (signals invalid-argument (p:crea-descrittore-pagina id :bucket 0 32 :next -1)
             :index-page-descriptor)
    (signals invalid-argument (p:crea-descrittore-pagina id :bucket 0 32 :next-generation -1)
             :index-page-descriptor)))

(deftest req-idx-009-interi-grandi-e-geometria-allineata
  (dolist (size '(4096 16384 65536))
    (let ((maximum (1- (expt 2 60))) (page (- (expt 2 60) size)))
      (multiple-value-bind (buffer start end id)
          (raw-page size :chiave #(255) 1 0 :image maximum :generation maximum :page page)
        (is (equal '(:chiave 1 0 1 0 0)
                   (multiple-value-list (p:verifica-pagina-indice buffer start end id))))))))

(deftest req-idx-009-record-ai-limiti-v2
  (let ((body (bucket-body 4096 (list #(7 8)))))
    (dolist (length '(26 16777242))
      (ref-write body (+ 32 24) length 4)
      (roundtrip 4096 :bucket body 1 32)))
  (let ((body (bucket-body 4096 (list (bytes 65535)) :external t)))
    (ref-write body (+ 32 24) 16842775 4)
    (roundtrip 4096 :bucket body 1 32)))
