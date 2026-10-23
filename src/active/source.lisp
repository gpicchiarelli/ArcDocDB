;;; OWNER: writer con lease adotta le capacità già preparate, fuori dal pool I/O.
;;; SHARED: nessuna pubblicazione o syscall; obblighi del catalogo restano al controller.
(in-package #:arcdocdb.active)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-MVC-008 REQ-FOR-001
(declaim (ftype (function (controllore-serie segmento-attivo-preparato) null)
                verifica-registro-preparato))
(defun verifica-registro-preparato (controller prepared)
  "Pre: capacità complete, legami immutabili. Post: writer e snapshot usano lo stesso registro CSN.
INVALID-ARGUMENT per altro Archivio; nessuna lettura di frontiere, mutex o modifica del registro."
  (let* ((view (arcdocdb.get::segmento-get-owner (segmento-attivo-preparato-segment prepared)))
         (scope (arcdocdb.get::vista-get-serie-scope view))
         (snapshots (arcdocdb.get::ambito-get-snapshots scope)))
    (unless (eq (arcdocdb.series::controllore-serie-registry controller)
                (arcdocdb.mvcc::registro-snapshot-csns snapshots))
      (error 'invalid-argument :reason :active-initialization-csn)))
  nil)

;;; REQ: REQ-FOR-001 REQ-IDX-001 REQ-WAL-006 REQ-MVC-008 REQ-AFF-008
(declaim (ftype (function (controllore-serie t segmento-attivo-preparato
                         &key (:max-pages integer) (:max-puts integer) (:batch-records integer)
                              (:batch-bytes integer) (:budget-payload integer)) sorgente-get-attiva)
                crea-sorgente-get-preparata))
(defun crea-sorgente-get-preparata (controller lease prepared
                                  &key (max-pages 65536) (max-puts 1048576) (batch-records 65536)
                                       (batch-bytes 67108864) (budget-payload 67108864))
  "Pre: lease, controller unico sul log preparato, stesso registro CSN, root nil e next-offset 64.
Post: sorgente ACTIVE con prova obbligatoria sulle capacità effettive, senza syscall/pubblicazione.
Errori di factory/lease/salute propagati; INVALID-ARGUMENT per altro log o file già avanzato.
Il controller ha già ottenuto la decisione del catalogo prima di ammettere traffico."
  (arcdocdb.series::%check-owner controller lease)
  (arcdocdb.series::%require-healthy controller)
  (unless (eq (arcdocdb.series::controllore-serie-log controller)
              (segmento-attivo-preparato-log prepared))
    (error 'invalid-argument :reason :active-initialization-log))
  (verifica-registro-preparato controller prepared)
  (let ((file (arcdocdb.wal::log-io-file (segmento-attivo-preparato-log prepared))))
    (unless (and (= (posizione-scritta file) +segment-header-bytes+)
                 (= (posizione-durevole file) +segment-header-bytes+))
      (error 'invalid-argument :reason :active-initialization-started)))
  (crea-sorgente-get-attiva controller lease (segmento-attivo-preparato-segment prepared)
                          :max-pages max-pages :max-puts max-puts :batch-records batch-records
                          :batch-bytes batch-bytes :budget-payload budget-payload
                          :associazione-file (segmento-attivo-preparato-association prepared)))
