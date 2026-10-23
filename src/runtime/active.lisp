;;; OWNER: controller esclusivo adotta il nuovo ACTIVE preparato, prima delle lease e del traffico.
;;; SHARED: binding del solo log; registro CSN dell'Archivio passato senza accessi o modifiche.
(in-package #:arcdocdb.runtime)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-CON-002 REQ-FOR-001 REQ-MVC-008 REQ-AFF-008
(declaim (ftype (function (runtime-archivio arcdocdb.active:segmento-attivo-preparato)
                         arcdocdb.wal:log-io) verifica-adozione-active))
(defun verifica-adozione-active (runtime prepared)
  "Pre: ACTIVE preparato e capacità congelate, namespace posseduto; nessuna lease o traffico.
Post: ambito runtime esatto, identità writer coerente e due capacità associate aperte a frontiera 64.
INVALID-ARGUMENT scope/start; IO-FAULT capacità; INVARIANT-VIOLATION identità, prima del binding.
Nessun I/O, CSN, root o attestazione della decisione durevole del catalogo."
  (let* ((segment (arcdocdb.active::segmento-attivo-preparato-segment prepared))
         (view (arcdocdb.get::segmento-get-owner segment))
         (log (arcdocdb.active:log-segmento-attivo-preparato prepared))
         (append (arcdocdb.wal::log-io-file log)))
    (unless (eq (arcdocdb.get::vista-get-serie-scope view) (ambito-runtime-archivio runtime))
      (error 'invalid-argument :reason :runtime-active-scope))
    (arcdocdb.wal:verifica-log-segmento log)
    (unless (and (= (arcdocdb.wal::log-io-file-id log)
                    (logior (ash (arcdocdb.get::segmento-get-high segment) 32)
                            (arcdocdb.get::segmento-get-low segment)))
                 (= (arcdocdb.wal::log-io-version log) (arcdocdb.get::segmento-get-version segment))
                 (= (arcdocdb.get::segmento-get-origin segment) arcdocdb.storage.format::+writer-origin+))
      (error 'invariant-violation :reason :runtime-active-identity))
    (arcdocdb.io:verifica-associazione-file
     (arcdocdb.active::segmento-attivo-preparato-association prepared)
     (arcdocdb.get::segmento-get-file segment) append)
    (unless (and (= (arcdocdb.io:posizione-scritta append) arcdocdb.storage.format:+segment-header-bytes+)
                 (= (arcdocdb.io:posizione-durevole append) arcdocdb.storage.format:+segment-header-bytes+))
      (error 'invalid-argument :reason :runtime-active-started))
    log))

;;; REQ: REQ-REC-001 REQ-CON-002 REQ-CON-005 REQ-MVC-008 REQ-AFF-008
(declaim (ftype (function (runtime-archivio arcdocdb.active:segmento-attivo-preparato
                          &key (:capacity t)) arcdocdb.series:controllore-serie) adotta-controllore-active))
(defun adotta-controllore-active (runtime prepared &key (capacity 64))
  "Pre: nuovo ACTIVE completo nel medesimo ambito runtime, un solo log canonico per file.
Il caller completa la decisione del catalogo prima di pubblicare le fonti e ammettere richieste.
Post: unico controller del log, CSN runtime, ring vuoto, root NIL e next-offset 64; nessuna lease.
Propaga rifiuti del preflight/factory; :SERIE-LOG-BOUND per seconda adozione, nessun reset.
Il binding è volatile e non decide il catalogo. Dopo interruzione, TROVA-CONTROLLORE-SERIE ritrova il risultato."
  (let ((log (verifica-adozione-active runtime prepared)))
    (arcdocdb.series:crea-controllore-serie
     (csn-runtime-archivio runtime) log :capacity capacity :root nil
     :next-offset arcdocdb.storage.format:+segment-header-bytes+)))
