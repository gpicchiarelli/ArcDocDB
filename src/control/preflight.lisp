;;; OWNER: pool I/O possiede capacità e scratch; piano mai modificato.
;;; SHARED: nessun catalogo/indice o stato tra Serie; bridge ai controlli locali I/O.
(in-package #:arcdocdb.control)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-REC-001
(declaim (ftype (function (checkpoint-control file-io file-io file-io octets index) null)
                verifica-preparazione-control))
(defun verifica-preparazione-control (plan input append directory scratch chunk-bytes)
  "Pre: nuovo control.log.tmp O_EXCL, parent autorevole e namespace riservato; capacità esclusive.
Post: buffer, budget, backend e frontiere controllati prima di qualsiasi syscall/mutazione.
INVALID-ARGUMENT/RESOURCE-EXHAUSTED/IO-FAULT dai controlli; ACTIVE ancora solo header."
  (verifica-active-checkpoint (checkpoint-control-active plan))
  (unless (plusp chunk-bytes) (error 'invalid-argument :reason :control-checkpoint-chunk))
  (let* ((active-input (input-active-checkpoint (checkpoint-control-active plan)))
         (view (arcdocdb.get::segmento-get-owner
                (arcdocdb.active::segmento-attivo-preparato-segment (checkpoint-control-active plan))))
         (size (lunghezza-checkpoint-control plan)))
    (when (or (eq scratch (checkpoint-control-bytes plan)) (eq scratch (checkpoint-control-identity plan))
              (eq scratch (arcdocdb.get::vista-get-serie-identity view)))
      (error 'invalid-argument :reason :control-checkpoint-alias))
    (check-range scratch 0 (min size chunk-bytes))
    (verifica-capienza-lettura input (min size chunk-bytes))
    (verifica-capienza-append append size (min size chunk-bytes))
    (arcdocdb.io::esigi-aperto directory :directory)
    (unless (and (eq (arcdocdb.io::file-backend input) (arcdocdb.io::file-backend append))
                 (eq (arcdocdb.io::file-backend input) (arcdocdb.io::file-backend directory))
                 (eq (arcdocdb.io::file-backend input) (arcdocdb.io::file-backend active-input)))
      (error 'invalid-argument :reason :control-checkpoint-backend))
    (unless (and (zerop (posizione-scritta append)) (zerop (posizione-durevole append)))
      (error 'invalid-argument :reason :control-checkpoint-started)))
  nil)

;;; REQ: REQ-AFF-002 REQ-FOR-002 REQ-REC-001
(declaim (ftype (function (checkpoint-control octets index index) null) verifica-rilettura-control))
(defun verifica-rilettura-control (plan scratch start count)
  "Pre: chunk riletto nel range verificato. Post: ogni byte header/EDIT/SEAL uguale al piano.
CORRUPTION-DETECTED al primo disaccordo, offset preciso; nessuna mutazione dei byte.
Ciclo limitato a COUNT, al massimo la lunghezza del piano."
  (let ((expected (checkpoint-control-bytes plan)))
    (check-range scratch 0 count) (check-range expected start (+ start count))
    (dotimes (i count)
      (unless (= (aref scratch i) (aref expected (+ start i)))
        (error 'corruption-detected :reason :control-checkpoint-readback :offset (+ start i)))))
  nil)
