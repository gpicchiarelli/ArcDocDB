;;; OWNER: coordinatore esclusivo del bootstrap; vettori, namespace e FD congelati.
;;; SHARED: sole letture di binding e capacità; nessuna pubblicazione o modifica CSN.
(in-package #:arcdocdb.runtime)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (t t t t) arcdocdb.binary:index) verifica-budget-closed-runtime))
(defun verifica-budget-closed-runtime (closed maps maximum budget)
  "Pre: ingressi stabili del coordinatore. Post: forma, cardinalità e budget prima di scansioni/array.
INVALID-ARGUMENT per forma/configurazione/count; RESOURCE-EXHAUSTED per capacità/payload.
Picco array nuovi: 20*N byte su SBCL 64 bit; esclude wrapper, hash del gate, array condivisi e GC."
  (unless (and (typep closed 'simple-vector) (typep maps 'simple-vector))
    (error 'invalid-argument :reason :runtime-closed-vectors))
  (unless (and (typep maximum 'arcdocdb.binary:index) (<= 1 maximum 65536)
               (typep budget 'arcdocdb.binary:index))
    (error 'invalid-argument :reason :runtime-closed-configuration))
  (let ((count (length closed)))
    (unless (= count (length maps)) (error 'invalid-argument :reason :runtime-closed-count))
    (when (> count maximum)
      (error 'arcdocdb.conditions:resource-exhausted :reason :runtime-closed-segment-budget))
    (when (> (* 20 count) budget)
      (error 'arcdocdb.conditions:resource-exhausted :reason :runtime-closed-payload-budget))
    count))

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-MVC-007 REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (archivio-recovery arcdocdb.get:vista-get-serie
                          arcdocdb.control:control-recuperato) arcdocdb.get:vista-get-serie)
                verifica-autorita-closed-runtime))
(defun verifica-autorita-closed-runtime (archive view control)
  "Pre: Archivio canonico e CONTROL autorevole della Serie, bootstrap esclusivo senza reader.
Post: vecchia vista dello scope Archivio, nuova vista dello scope runtime canonico, stesso UUID.
INVALID-ARGUMENT per runtime assente/scope/identità; binding corrotto propaga INVARIANT-VIOLATION.
Non certifica il catalogo, ricostruisce il primary o copia cache/pin dal bootstrap."
  (let ((runtime (trova-runtime-archivio archive))
        (old (arcdocdb.control::control-recuperato-view control)))
    (unless runtime (error 'invalid-argument :reason :runtime-closed-unbound))
    (unless (eq (arcdocdb.get::vista-get-serie-scope old)
                (arcdocdb.recovery.archive::archivio-recovery-scope archive))
      (error 'invalid-argument :reason :runtime-closed-bootstrap-scope))
    (unless (eq (arcdocdb.get::vista-get-serie-scope view) (ambito-runtime-archivio runtime))
      (error 'invalid-argument :reason :runtime-closed-target-scope))
    (unless (equalp (arcdocdb.get::vista-get-serie-identity old)
                    (arcdocdb.get::vista-get-serie-identity view))
      (error 'invalid-argument :reason :runtime-closed-serie-identity))
    old))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-FOR-004 REQ-IDX-001 REQ-AFF-008
(declaim (ftype (function (arcdocdb.get:vista-get-serie t t u32) u32) verifica-mappa-closed-runtime))
(defun verifica-mappa-closed-runtime (old recovered map previous)
  "Pre: insieme CLOSED completo già verificato, vettori paralleli stabili; PREVIOUS è l'ID precedente.
Post: mappa canonica della vista bootstrap, stesso FD EQ, ID, P, versione e origine del risultato.
INVALID-ARGUMENT per tipi, ordine, lifetime o disaccordo; nessun I/O o troncamento ID storage u64."
  (unless (typep recovered 'arcdocdb.recovery.closed:closed-recuperato)
    (error 'invalid-argument :reason :runtime-closed-result))
  (let* ((id (arcdocdb.get.directory::verifica-mappa-directory-get old map previous))
         (entry (the arcdocdb.get.resolver:mappa-segmento-get map))
         (segment (arcdocdb.get.resolver::mappa-segmento-get-segment entry)))
    (unless (eq (arcdocdb.get::segmento-get-file segment)
                (arcdocdb.recovery.closed::closed-recuperato-input recovered))
      (error 'invalid-argument :reason :runtime-closed-file))
    (unless (and (= id (arcdocdb.recovery.closed::closed-recuperato-id recovered))
                 (= (arcdocdb.get.resolver::mappa-segmento-get-end entry)
                    (arcdocdb.recovery.closed::closed-recuperato-prefix recovered))
                 (= (arcdocdb.get::segmento-get-version segment)
                    (arcdocdb.recovery.closed::closed-recuperato-version recovered))
                 (= (arcdocdb.get::segmento-get-origin segment)
                    (arcdocdb.recovery.closed::closed-recuperato-origin recovered)))
      (error 'invalid-argument :reason :runtime-closed-source))
    id))
