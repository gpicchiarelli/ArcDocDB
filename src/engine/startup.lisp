;;; OWNER: ciclo completo del motore nell'attore I/O, dall'esclusione fisica alla sola admission finale.
;;; SHARED: gate e runtime canonici esistenti; nessun bootstrap o replay richiesto al chiamante.
(in-package #:arcdocdb.engine)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-MVC-006 REQ-IDX-001 REQ-AFF-008
(declaim (ftype (function (motore) null) avvia-recovery-motore))
(defun avvia-recovery-motore (engine)
  "Pre: directory lock esclusivo, file canonici presenti e admission chiusa. Post: motore READY completo.
Gate prima degli effetti, checkpoint e nomi prima di indice/runtime/radice; errori al confine startup."
  (setf (motore-state engine) :recovering)
  (osserva-motore engine :before-recovery)
  (let* ((archive (dar:crea-archivio-recovery (motore-scope engine) (motore-archive-id engine)))
         (decisions (leggi-decisioni-motore engine archive))
         (set (ac:crea-insieme-serie-recovery archive (motore-view engine) (vector (motore-view engine))
                                            :max-series 1 :budget-riferimenti 8)))
    (multiple-value-bind (control sources active closed previous)
        (recupera-fonti-motore engine decisions set)
      (verifica-ordine-fonti-motore engine control sources decisions closed)
      (let ((id (verifica-inventario-motore engine control)))
        (osserva-motore engine :recovered)
        (rs:stabilizza-nomi-serie-recuperata (motore-directory engine) sources active closed
                                          :max-segmenti (motore-max-segments engine))
        (let ((prepared (checkpoint-motore engine active id)))
          (multiple-value-bind (current current-sources current-active current-closed plan)
            (recupera-fonti-motore engine decisions set)
          (unless (equal (multiple-value-list (ac:massimo-csn-archivio previous))
                         (multiple-value-list (ac:massimo-csn-archivio plan)))
            (error 'invariant-violation :reason :engine-recovery-csn-changed))
          (rs:stabilizza-nomi-serie-recuperata (motore-directory engine) current-sources current-active current-closed
                                            :max-segmenti (motore-max-segments engine))
            (adotta-runtime-motore engine archive current current-closed plan prepared))))))
  nil)

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function ((or string pathname) octets octets
                          &key (:create boolean) (:version (member 1 2)) (:clock t) (:observer t) (:record-validator t)
                               (:max-file-bytes index) (:max-record-bytes index) (:max-records u32)
                               (:max-segments index) (:index-capacity index) (:key-arena-bytes index)
                               (:hash-seed-high u32) (:hash-seed-low u32)) motore) apri-motore))
(defun apri-motore (directory archive-id series-id
                   &key (create nil) (version 2) clock observer record-validator (max-file-bytes 16777216)
                        (max-record-bytes 65536) (max-records 65536) (max-segments 64)
                        (index-capacity 4096) (key-arena-bytes 1048576) (hash-seed-high #x243f6a88)
                        (hash-seed-low #x85a308d3))
  "Pre: directory esistente privata, UUID espliciti, clock monotono iniettabile, nessuna cancellazione thread.
Post: unico writer fisico e motore READY; init esplicito o recovery automatico senza harness.
Punti durevoli nei preparatori/publisher esistenti; nessuna admission prima di indice e fonti completi.
Errori tipizzati, risorse tutte tentate; causa primaria e cleanup conservati, nessun retry/rollback."
  (unless (typep record-validator '(or null function))
    (error 'invalid-argument :reason :engine-record-validator))
  (verifica-configurazione-motore archive-id series-id version clock observer
                                 max-file-bytes max-records max-segments max-record-bytes)
  (let ((engine (%make-motore :archive-id (copy-seq archive-id) :series-id (copy-seq series-id)
                   :clock clock :observer observer :record-validator record-validator
                   :version version :max-file-bytes max-file-bytes
                   :max-record-bytes max-record-bytes :max-records max-records :max-segments max-segments
                   :scratch (make-array max-file-bytes :element-type '(unsigned-byte 8) :initial-element 0)
                   :empty (make-array 0 :element-type '(unsigned-byte 8)))) (complete nil) (cause nil))
    (handler-case
        (unwind-protect
             (handler-case (progn
               (prepara-ispezione-motore engine index-capacity key-arena-bytes hash-seed-high hash-seed-low)
               (setf (motore-directory engine) (possiedi-file-motore engine (io:apri-directory directory)))
               (io:esigi-esclusiva-directory (motore-directory engine))
               (osserva-motore engine :starting)
               (when create (inizializza-storage-motore engine))
               (avvia-recovery-motore engine)
               (setf complete t)
               engine)
               (error (primary) (setf cause primary) (error primary)))
          (unless complete
            (tenta-cleanup-motore engine (lambda () (guasta-motore engine cause)))
            (libera-risorse-motore engine)))
      (error (primary)
        (setf (motore-failure engine) primary)
        (when (motore-cleanup-failures engine)
          (error 'errore-cleanup-motore :reason :engine-startup-cleanup :primary primary
                 :errors (reverse (motore-cleanup-failures engine))))
        (error primary)))))
