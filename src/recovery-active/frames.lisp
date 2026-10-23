;;; OWNER: un attraversamento del prefisso interamente verificato, buffer stabile e workspace privato.
;;; SHARED: nessuna pubblicazione; lo scanner a EOF precede ogni interpretazione semantica.
(in-package #:arcdocdb.recovery.active)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-FOR-003 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (octets index index (member 1 2))
                         (values index u8 u8 index &optional)) cornice-active-verificata))
(defun cornice-active-verificata (buffer pos end version)
  "Pre: prefisso già verificato per intero, buffer esclusivo stabile. Post: header e progresso ricontrollati.
Salta il body già coperto dal CRC del primo passaggio; ritorna inizio valore, non prova di commit.
Errori di header/range propagano; INVARIANT-VIOLATION per consumo incoerente, nessuna modifica."
  (check-range buffer pos end)
  (multiple-value-bind (next kind flags key-bytes value-bytes)
      (arcdocdb.record::checked-header buffer pos end version +max-document-bytes+)
    (let ((value-start (+ pos +header-bytes+ key-bytes)))
      (unless (and (< pos next) (<= next end) (= (- next value-start) value-bytes))
        (error 'invariant-violation :reason :active-recovery-frame :offset pos))
      (values next kind flags value-start))))

;;; REQ: REQ-TXM-007 REQ-AFF-008 REQ-REC-001
(declaim (ftype (function (workspace-active u64 index index u32) null) registra-prepared-active))
(defun registra-prepared-active (workspace txid batch pos limit)
  "Pre: PUT/TOMBSTONE prepared in prefisso valido. Post: un solo lotto per TXID e budget di TXID distinti.
CORRUPTION-DETECTED se attraversa lotti o segue un OUTCOME già presente; RESOURCE-EXHAUSTED prima dell'inserimento.
TXID zero e u64 completo sono ammessi; nessun significato dedotto dalla grandezza."
  (multiple-value-bind (csn outcome-present) (gethash txid (workspace-active-outcomes workspace))
    (when outcome-present
      (unless (typep csn 'u64) (error 'invariant-violation :reason :active-recovery-outcome-value))
      (error 'corruption-detected :reason :active-recovery-outcome-before-prepare :offset pos)))
  (multiple-value-bind (previous present) (gethash txid (workspace-active-prepared workspace))
    (when (and present (/= previous batch))
      (error 'corruption-detected :reason :active-recovery-prepared-batches :offset pos))
    (unless present
      (when (>= (hash-table-count (workspace-active-prepared workspace)) limit)
        (error 'resource-exhausted :reason :active-recovery-prepared-budget :offset pos))
      (setf (gethash txid (workspace-active-prepared workspace)) batch)))
  nil)

;;; REQ: REQ-TXM-007 REQ-AFF-008 REQ-REC-001
(declaim (ftype (function (workspace-active u64 u64 index u32) null) registra-outcome-active))
(defun registra-outcome-active (workspace txid csn pos limit)
  "Pre: OUTCOME con body già integro e forma verificata. Post: esito unico oppure duplicato identico.
Budget conta occorrenze fisiche prima dell'inserimento; conflitto segnala CORRUPTION-DETECTED.
Un OUTCOME senza prepared nel segmento non produce da solo un esito di chiusura."
  (when (>= (workspace-active-outcome-records workspace) limit)
    (error 'resource-exhausted :reason :active-recovery-outcome-budget :offset pos))
  (multiple-value-bind (previous present) (gethash txid (workspace-active-outcomes workspace))
    (when (and present (/= previous csn))
      (error 'corruption-detected :reason :active-recovery-outcome-conflict :offset pos))
    (setf (gethash txid (workspace-active-outcomes workspace)) csn))
  (incf (workspace-active-outcome-records workspace))
  (registra-csn-active workspace csn)
  nil)

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-FOR-003 REQ-AFF-008
(declaim (ftype (function (octets index (member 1 2) index index u32 u32) workspace-active)
                attraversa-active))
(defun attraversa-active (buffer prefix version batches records max-prepared max-outcomes)
  "Pre: intero prefisso sigillato e conteggi autorevoli. Post: workspace semantico completo privato.
Rilegge solo header, non CRC dei documenti; ciclo esatto di BATCHES+RECORDS cornici.
Errori tipizzati per prepared/esiti; INVARIANT-VIOLATION se consumo o conteggi divergono."
  (check-range buffer +segment-header-bytes+ prefix)
  (unless (<= (+ batches records) (floor (- prefix +segment-header-bytes+) +header-bytes+))
    (error 'invariant-violation :reason :active-recovery-frame-count))
  (let ((workspace (%make-workspace-active)) (pos +segment-header-bytes+) (batch 0) (count 0))
    (loop repeat (+ batches records)
          do (multiple-value-bind (next kind flags value-start)
                 (cornice-active-verificata buffer pos prefix version)
               (case kind
                 ((#.+put+ #.+tombstone+)
                  (let ((stamp (leggi-u64 buffer (+ pos arcdocdb.record::+stamp-offset+))))
                    (if (logtest flags +prepared+)
                        (registra-prepared-active workspace stamp batch pos max-prepared)
                        (registra-csn-active workspace stamp)))
                  (incf count))
                 (#.+outcome+
                  (registra-outcome-active workspace (leggi-u64 buffer (+ pos arcdocdb.record::+stamp-offset+))
                                          (leggi-u64 buffer value-start) pos max-outcomes)
                  (incf count))
                 (#.+seal+
                  (registra-csn-active workspace (leggi-u64 buffer (+ pos arcdocdb.record::+stamp-offset+)))
                  (incf batch))
                 (otherwise (error 'invariant-violation :reason :active-recovery-kind :offset pos)))
               (setf pos next)))
    (unless (and (= pos prefix) (= batch batches) (= count records))
      (error 'invariant-violation :reason :active-recovery-consumption :offset pos))
    workspace))
