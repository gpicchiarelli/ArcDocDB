;;; OWNER: configurazione privata prima dell'apertura; seed e UUID espliciti, nessun valore dal nome del path.
;;; SHARED: solo il runtime finale pubblichera' il registro CSN canonico a recovery concluso.
(in-package #:arcdocdb.engine)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (octets octets t t t t t t t) null) verifica-configurazione-motore))
(defun verifica-configurazione-motore (archive-id series-id version clock observer bytes records segments frame)
  "Pre: configurazione caller prima dell'I/O. Post: UUID e budget finiti coerenti, clock iniettabile.
INVALID-ARGUMENT prima di risorse/effetti; M1 usa lo stesso formato canonico v1/v2."
  (unless (and (= (length archive-id) 16) (= (length series-id) 16) (member version '(1 2))
               (functionp clock) (typep observer '(or null function)))
    (error 'invalid-argument :reason :engine-configuration))
  (unless (and (typep bytes '(integer 4096 268435456))
               (typep records '(integer 1 65536)) (typep segments '(integer 2 65536))
               (typep frame '(integer 64 16777216)) (<= (+ frame w::+seal-total+ f:+segment-header-bytes+) bytes))
    (error 'invalid-argument :reason :engine-budgets))
  nil)

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-MVC-008 REQ-AFF-008
(declaim (ftype (function (motore index index u32 u32) null) prepara-ispezione-motore))
(defun prepara-ispezione-motore (engine capacity arena seed-high seed-low)
  "Pre: configurazione valida, nessun I/O. Post: indice candidato e vista readonly per recovery, nessun writer.
CSN zero del solo contesto d'ispezione non e' operativo; quello finale deriva dal gate completo.
Errori delle factory prima dell'apertura; nessuna admission o seed derivato da input non verificato."
  (let* ((registry (arcdocdb.csn:crea-registro-csn :capacity 16))
         (snapshots (arcdocdb.mvcc:crea-registro-snapshot registry 4 1000000000 1000000))
         (epochs (arcdocdb.epochs:crea-registro-epoche 1 16))
         (scope (g:crea-ambito-get epochs snapshots)))
    (setf (motore-index engine)
          (p:crea-indice-primario :capacity capacity :arena-bytes arena :max-depth 1
             :directory-budget-bytes 4096 :fragment-budget-bytes (+ 4096 arena (* 256 capacity))
             :hash-seed-high seed-high :hash-seed-low seed-low)
          (motore-index-context engine) (p:crea-contesto-indice)
          (motore-scope engine) scope
          (motore-view engine) (g:crea-vista-get-serie scope (motore-index engine) nil (motore-series-id engine))))
  nil)
