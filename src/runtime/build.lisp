;;; OWNER: controller conserva l'Archivio canonico fino al binding; candidato ancora privato.
;;; SHARED: un CAS nel bootstrap, nessun accesso al binding per lotto, documento o lettura.
(in-package #:arcdocdb.runtime)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-MVC-006 REQ-MVC-008 REQ-AFF-008
(declaim (ftype (function (runtime-archivio u32 u32 ambito-get) null) verifica-runtime-iniziale))
(defun verifica-runtime-iniziale (runtime high low old-scope)
  "Pre: candidato privato, nessun CSN assegnato o snapshot registrato.
Post: snapshot legato per EQ al registro candidato, ultimo=H=M senza incremento.
INVARIANT-VIOLATION :ARCHIVE-RUNTIME-LINK/BASE prima del CAS; nessuna fonte consultata."
  (unless (and (not (eq old-scope (ambito-runtime-archivio runtime)))
               (eq (arcdocdb.mvcc::registro-snapshot-csns (snapshot-runtime-archivio runtime))
                   (csn-runtime-archivio runtime)))
    (error 'invariant-violation :reason :archive-runtime-link))
  (multiple-value-bind (lh ll hh hl) (leggi-frontiere-csn (csn-runtime-archivio runtime))
    (unless (and (= high lh hh) (= low ll hl))
      (error 'invariant-violation :reason :archive-runtime-base)))
  nil)

;;; REQ: REQ-REC-001 REQ-MVC-006 REQ-MVC-008 REQ-MVC-007 REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (piano-csn-archivio t t
                          &key (:csn-capacity t) (:snapshot-capacity t)
                               (:worker-capacity t) (:retirement-capacity t)) runtime-archivio)
                crea-runtime-archivio))
(defun crea-runtime-archivio (plan lifetime-ticks wait-ticks
                             &key (csn-capacity 256) (snapshot-capacity 256)
                                  (worker-capacity 64) (retirement-capacity 256))
  "Pre: piano completo e congelato, unico oggetto Archivio del catalogo; recovery esclusivo.
Durate esplicite nella stessa unità monotona fornita alle future chiamate snapshot.
Post: una sola famiglia CSN(M)/snapshot/EBR/ambito, pubblicata con CAS senza ammettere traffico.
INVALID-ARGUMENT config o :ARCHIVE-RUNTIME-BOUND; nessun candidato perdente è restituito.
Propaga TYPE-ERROR e INVARIANT-VIOLATION di piano/binding/legami/base: fermare il bootstrap.
Nessun I/O o clock; usa i registri esistenti privati. Errori prima del CAS non pubblicano candidati.
Dopo il CAS nessun rollback: TROVA-RUNTIME-ARCHIVIO recupera la capacità anche dopo interruzione."
  (verifica-configurazione-runtime csn-capacity snapshot-capacity worker-capacity
                                  retirement-capacity lifetime-ticks wait-ticks)
  (verifica-piano-runtime plan)
  (let ((archive (arcdocdb.recovery.archive.csn::piano-csn-archivio-archive plan)))
    (when (trova-runtime-archivio archive)
      (error 'invalid-argument :reason :archive-runtime-bound))
    (multiple-value-bind (high low) (parole-base-csn-archivio plan)
      (let* ((csns (crea-registro-csn :capacity csn-capacity :initial-high high :initial-low low))
             (snapshots (crea-registro-snapshot csns snapshot-capacity lifetime-ticks wait-ticks))
             (epochs (crea-registro-epoche worker-capacity retirement-capacity))
             (runtime (%make-runtime-archivio csns (crea-ambito-get epochs snapshots))))
        (verifica-runtime-iniziale runtime high low (arcdocdb.recovery.archive::archivio-recovery-scope archive))
        (sb-thread:barrier (:write))
        (unless (null (sb-ext:compare-and-swap
                       (arcdocdb.recovery.archive::archivio-recovery-runtime archive) nil runtime))
          (error 'invalid-argument :reason :archive-runtime-bound))
        runtime))))
