;;; OWNER: compito I/O esclusivo, buffer del piano stabile e scratch privato.
;;; SHARED: nessuna scansione del manifest, allocazione di liste o scrittura tra Serie.
(in-package #:arcdocdb.control)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-REC-001
(declaim (ftype (function (checkpoint-control file-io index) null) scrivi-checkpoint-control))
(defun scrivi-checkpoint-control (plan append chunk-bytes)
  "Pre: preflight conclusa, append a zero, chunk positivo e capacità esclusiva nel pool I/O.
Post: file intero scritto per chunk, non ancora durevole; ogni ritorno controllato.
Guasti I/O propagati senza retry; INVARIANT-VIOLATION per frontiera discordante.
Ciclo limitato a CEILING(size/chunk), senza sospensione o punto di atomicità."
  (unless (plusp chunk-bytes) (error 'invalid-argument :reason :control-checkpoint-chunk))
  (let ((bytes (checkpoint-control-bytes plan)) (size (lunghezza-checkpoint-control plan)))
    (loop repeat (ceiling size chunk-bytes) for start from 0 by chunk-bytes
          for end = (min size (+ start chunk-bytes))
          do (unless (= (append-esatto append bytes start end) end)
               (error 'invariant-violation :reason :control-checkpoint-write :offset start))))
  nil)

;;; REQ: REQ-AFF-002 REQ-AFF-008 REQ-REC-001
(declaim (ftype (function (checkpoint-control file-io octets index) null) rileggi-checkpoint-control))
(defun rileggi-checkpoint-control (plan input scratch chunk-bytes)
  "Pre: file scritto e sincronizzato, preflight conclusa e scratch esclusivo nel pool I/O.
Post: ogni chunk riletto uguale al piano; nessuna ricostruzione/allocazione del manifest.
Guasti I/O/corruzione propagati senza risultato parziale; ritorni controllati.
Ciclo limitato a CEILING(size/chunk); scratch riusato solo dopo confronto completo."
  (unless (plusp chunk-bytes) (error 'invalid-argument :reason :control-checkpoint-chunk))
  (let ((size (lunghezza-checkpoint-control plan)))
    (loop repeat (ceiling size chunk-bytes) for start from 0 by chunk-bytes
          for count = (min chunk-bytes (- size start))
          do (unless (= (leggi-esatto input scratch 0 count start) count)
               (error 'invariant-violation :reason :control-checkpoint-read :offset start))
             (verifica-rilettura-control plan scratch start count)))
  nil)
