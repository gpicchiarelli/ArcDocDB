;;; OWNER: controller fornisce un seme per Serie prima della costruzione dell'indice.
;;; SHARED: due u32 read-only dell'indice; nessuna generazione casuale o cambio seme implicito.
(in-package #:arcdocdb.index.primary)
(declaim (optimize (safety 3) (speed 3) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (indice-primario) (values u32 u32 &optional)) esigi-seme-hash))
(defun esigi-seme-hash (index)
  "Pre: indice canonico. Post: due u32 immutabili della configurazione hash.
Salute e coerenza della coppia verificate; assente => INVALID-ARGUMENT :primary-hash-unconfigured.
Coppia incoerente interna => FAULTED con :primary-hash-seed-corrupt, senza digest normale."
  (esigi-indice-sano index)
  (when (null (indice-primario-seed-high index))
    (unless (null (indice-primario-seed-low index)) (guasto-indice index :primary-hash-seed-corrupt))
    (error 'invalid-argument :reason :primary-hash-unconfigured))
  (when (null (indice-primario-seed-low index)) (guasto-indice index :primary-hash-seed-corrupt))
  (values (indice-primario-seed-high index) (indice-primario-seed-low index)))

;;; REQ: REQ-IDX-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (indice-primario t t t u32 u32) (values u32 u32 &optional)) hash-con-seme-indice))
(defun hash-con-seme-indice (index key start end high low)
  "Pre: indice proprietario sano e seme posseduto. Post: due u32; rifiuti esterni propagati.
INVARIANT-VIOLATION del kernel rende terminale l'indice e rilancia la medesima condizione."
  (handler-case (arcdocdb.hash64:xxh64 key start end high low)
    (invariant-violation (condition) (invalida-indice-primario index) (error condition))))

;;; REQ: REQ-IDX-001 REQ-LIM-003 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (indice-primario t t t) (values u32 u32 &optional)) digest-chiave-indice))
(defun digest-chiave-indice (index key start end)
  "Pre: span immutato del chiamante, seme configurato e indice sano all'ingresso.
Post: due u32 XXH64 calcolati con il seme immutabile della Serie, nessuna scrittura.
Hash di span vuoto ammesso; il writer valida separatamente la lunghezza minima delle chiavi.
Rifiuti del kernel hash e :primary-hash-unconfigured; il digest non e un esito di lookup.
Asserzione interna del kernel: indice FAULTED, condizione originale propagata."
  (multiple-value-bind (high low) (esigi-seme-hash index)
    (hash-con-seme-indice index key start end high low)))
