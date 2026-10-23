;;; OWNER: startup prepara il runtime privato e rende ammissibile la Serie solo dopo indice/radice completi.
;;; SHARED: binding CSN/snapshot/EBR canonico gia' esistente, nessun secondo allocatore operativo.
(in-package #:arcdocdb.engine)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-IDX-001 REQ-AFF-008
(declaim (ftype (function (motore c:control-recuperato simple-vector) simple-vector) mappe-motore))
(defun mappe-motore (engine control closed)
  "Pre: tutte le fonti gia' verificate, prima di admission. Post: mappe canoniche della vista recovery.
Nessun FD aperto o trasferito; ogni mappa legge lo stesso FD della prova CLOSED."
  (let ((maps (make-array (length closed) :initial-element nil)))
    (dotimes (i (length closed) maps)
      (let* ((token (the rc:closed-recuperato (svref closed i)))
             (file (arcdocdb.recovery.closed::closed-recuperato-input token))
             (id (nth-value 0 (rc:frontiere-closed-recuperato token))))
        (setf (svref maps i)
              (r:crea-mappa-segmento-get (motore-view engine) file (c:manifest-control-recuperato control)
               id (motore-scratch engine) :max-bytes (motore-max-file-bytes engine)
               :max-records (motore-max-records engine) :max-batches (motore-max-records engine)
               :max-batch-records (motore-max-records engine)
               :max-batch-bytes (motore-max-file-bytes engine)))))))

;;; REQ: REQ-REC-001 REQ-MVC-006 REQ-MVC-008 REQ-IDX-001 REQ-AFF-008
(declaim (ftype (function (motore rt:runtime-archivio a:segmento-attivo-preparato) null) adotta-active-motore))
(defun adotta-active-motore (engine runtime prepared)
  "Pre: checkpoint gia' deciso, nuovo ACTIVE solo header e nome completato, ambito runtime corrente.
Post: wrapper runtime dello stesso FD/log/associazione verificati; unico controller e lease dell'owner.
Il rebind rilegge l'header canonico, non riscrive il file o ricostruisce la prova di durability."
  (let* ((old (arcdocdb.active::segmento-attivo-preparato-segment prepared))
         (id (logior (ash (arcdocdb.get::segmento-get-high old) 32) (arcdocdb.get::segmento-get-low old)))
         (segment (g:crea-segmento-get (motore-view engine) (arcdocdb.get::segmento-get-file old)
                                     id (motore-scratch engine)))
         (wrapped (arcdocdb.active::%make-segmento-attivo-preparato
                    (a:log-segmento-attivo-preparato prepared) segment
                    (arcdocdb.active::segmento-attivo-preparato-association prepared)))
         (controller (rt:adotta-controllore-active runtime wrapped :capacity 8)))
    (setf (motore-active engine) wrapped (motore-controller engine) controller
          (motore-append engine) (arcdocdb.wal::log-io-file (a:log-segmento-attivo-preparato wrapped))
          (motore-lease engine) (s:acquisisci-controllore-serie controller)
          (motore-source engine) (a:crea-sorgente-get-preparata controller (motore-lease engine) wrapped
                                  :max-puts (motore-max-records engine)
                                  :batch-records 1 :batch-bytes (+ (motore-max-record-bytes engine) w::+seal-total+))
          (motore-batch engine) (w:crea-lotto :segment id :version (motore-version engine) :max-records 1
                                            :capacity (+ (motore-max-record-bytes engine) w::+seal-total+))
          (motore-group engine) (w:crea-gruppo (a:log-segmento-attivo-preparato wrapped) :max-lots 1))
    (gd:inizializza-fonti-get-attive (motore-source engine) (motore-lease engine) (motore-sources engine)))
  nil)

;;; REQ: REQ-REC-001 REQ-MVC-006 REQ-MVC-008 REQ-IDX-001 REQ-AFF-008
(declaim (ftype (function (motore dar:archivio-recovery c:control-recuperato simple-vector
                          ac:piano-csn-archivio a:segmento-attivo-preparato) null) adotta-runtime-motore))
(defun adotta-runtime-motore (engine archive control closed plan prepared)
  "Pre: checkpoint e nomi completi, gate CSN finale; admission chiusa. Post: runtime/GET/indice completi.
Un solo registro operativo a M, senza incremento; errori prima di READY non restituiscono il motore."
  (let* ((maps (mappe-motore engine control closed)) (runtime (rt:crea-runtime-archivio plan 1000000000 1000000
                                  :csn-capacity 16 :snapshot-capacity 4 :worker-capacity 1 :retirement-capacity 16)))
    (setf (motore-registry engine) (rt:csn-runtime-archivio runtime)
          (motore-scope engine) (rt:ambito-runtime-archivio runtime)
          (motore-view engine) (g:crea-vista-get-serie (motore-scope engine) (motore-index engine)
                                                     nil (motore-series-id engine)))
    (let ((directory (rt:adotta-directory-closed archive (motore-view engine) control closed maps
                      :max-segmenti (motore-max-segments engine)
                      :budget-payload (* 128 (motore-max-segments engine)))))
      (setf (motore-sources engine) (gd:crea-fonti-get-serie directory)))
    (ricostruisci-indice-motore engine closed (limiti-motore engine))
    (adotta-active-motore engine runtime prepared)
    (setf (motore-get-context engine)
          (g:crea-contesto-get (motore-scope engine) 0 :record-bytes (motore-max-record-bytes engine)
                              :budget-payload (+ 1024 (motore-max-record-bytes engine)))))
  (osserva-motore engine :before-admission)
  (setf (motore-state engine) :ready)
  nil)
