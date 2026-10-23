;;; OWNER: coordinatore costruisce una copia dell'elenco canonico prima di aggregare i recovery.
;;; SHARED: legami readonly, nessun vettore esportato o fonte durevole trattenuta nel piano.
(in-package #:arcdocdb.recovery.archive.csn)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-TXM-005 REQ-AFF-008
(defstruct (insieme-serie-recovery
             (:constructor %make-insieme-serie-recovery (archive views)) (:copier nil))
  "Pre: elenco completo autorevole dal catalogo, UUID unici, stesso ambito, Registri inclusa.
Post: vettore posseduto readonly, distinto da quello del chiamante; viste canoniche per EQ.
Non verifica il catalogo su disco né deduce il ruolo Registri dal nome; nessun accessor pubblico."
  (archive nil :type archivio-recovery :read-only t)
  (views #() :type simple-vector :read-only t))

;;; REQ: REQ-REC-001 REQ-MVC-006 REQ-TXM-005 REQ-AFF-008
(defstruct (piano-csn-archivio
             (:constructor %make-piano-csn-archivio (archive series segments present maximum)) (:copier nil))
  "Pre: tutte le Serie dell'insieme e stesso replay decisioni, fonti congelate e verificate.
Post: riepilogo scalare readonly; nessun elenco, tabella decisioni, risultato Serie o FD trattenuto.
Non certifica la salute futura né autorizza il traffico o la creazione di più allocatori."
  (archive nil :type archivio-recovery :read-only t)
  (series 0 :type index :read-only t)
  (segments 0 :type index :read-only t)
  (present nil :type boolean :read-only t)
  (maximum 0 :type u64 :read-only t))
