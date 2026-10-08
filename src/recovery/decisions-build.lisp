;;;; Ricostruzione tutto-o-niente del prefisso sigillato di multiserie.log.
;;; OWNER: una chiamata; workspace e risultato possiedono tutte le copie.
;;; SHARED: nessuna pubblicazione, applicazione o scrittura condivisa tra Serie.
(in-package #:arcdocdb.recovery.decisions)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-TXM-005 REQ-AFF-008
(declaim (ftype (function (integer integer integer) null) check-decision-budgets))
(defun check-decision-budgets (max-decisions max-participants max-per-decision)
  "Pre: budget interi del chiamante. Post: conteggi index e tetto per DECISION u16;
zero ammesso. INVALID-ARGUMENT prima dello scanner per configurazione invalida."
  (unless (and (typep max-decisions 'index) (typep max-participants 'index))
    (error 'invalid-argument :reason :decision-arguments))
  (unless (typep max-per-decision 'u16)
    (error 'invalid-argument :reason :decision-arguments))
  nil)

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (octets index index integer u16)
                         (values index (or null index) index index u16 &optional)) decision-frame))
(defun decision-frame (buffer pos end version max-per-decision)
  "Pre: record nel prefisso sigillato e stabile. Post: cornice verificata; per DECISION
restituisce fine, offset CSN, span ID16 e count; per SEAL offset CSN NIL.
Propaga corruzione del payload e budget, senza riclassificarli come coda."
  (check-range buffer pos end)
  (unless (< pos end)
    (error 'invariant-violation :reason :decision-frame-range :offset pos))
  (multiple-value-bind (next kind flags ks ke vs ve)
      (verifica-cornice buffer pos end :version version)
    (unless (and (< pos next) (<= next end) (= ks ke) (zerop flags))
      (error 'invariant-violation :reason :decision-control-frame :offset pos))
    (cond
      ((= kind +seal+) (values next nil 0 0 0))
      ((= kind +decision+)
       (multiple-value-bind (csn parts-start parts-end count)
           (valida-valore-decision buffer vs ve :max-partecipanti max-per-decision)
         (unless (and (<= vs csn parts-start parts-end ve)
                      (= (- parts-end parts-start) (* count +participant-id-bytes+)))
           (error 'invariant-violation :reason :decision-payload-range :offset pos))
         (values next csn parts-start parts-end count)))
      (t (error 'invariant-violation :reason :decision-record-type :offset pos)))))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-008 REQ-AFF-009
(declaim (ftype (function (octets index index integer index index index u16 u64)
                         (values index &optional)) preflight-decisions))
(defun preflight-decisions (buffer start end version frames decisions max-participants
                            max-per-decision file-offset)
  "Pre: prefisso verificato dallo scanner, contatori di cornici e DECISION autorevoli.
Post: tutti i payload validi e totale partecipanti entro budget, duplicati di record inclusi.
RESOURCE-EXHAUSTED con offset assoluto; errori del codec mantengono offset relativi.
Nessuna entry o copia dei partecipanti allocata durante questo passaggio."
  (check-range buffer start end)
  (unless (<= frames (floor (- end start) +header-bytes+))
    (error 'invariant-violation :reason :decision-frame-count :offset start))
  (let ((pos start) (count 0) (total 0))
    (dotimes (i frames)
      (multiple-value-bind (next csn parts-start parts-end participants)
          (decision-frame buffer pos end version max-per-decision)
        (when csn
          (unless (= (- parts-end parts-start) (* participants +participant-id-bytes+))
            (error 'invariant-violation :reason :decision-participant-size :offset pos))
          (when (> participants (- max-participants total))
            (error 'resource-exhausted :reason :decision-participant-budget
                   :offset (+ file-offset pos)))
          (incf total participants)
          (incf count))
        (setf pos next)))
    (unless (and (= pos end) (= count decisions))
      (error 'invariant-violation :reason :decision-prefix-consumption :offset pos))
    total))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-FOR-003 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (octets index index integer index index index u16 u64)
                         (values simple-vector &optional)) decode-decisions))
(defun decode-decisions (buffer start end version frames count total max-per-decision file-offset)
  "Pre: payload e budget cumulativi già verificati, buffer stabile fino al ritorno.
Post: COUNT entry possedute, partecipanti copiati, ordinati e distinti; nessun alias all'input.
Propaga errori tipizzati; consumo incoerente segnala INVARIANT-VIOLATION."
  (check-range buffer start end)
  (unless (<= count frames (floor (- end start) +header-bytes+))
    (error 'invariant-violation :reason :decision-frame-count :offset start))
  (let ((entries (make-array count :element-type t)) (pos start) (i 0) (participants-read 0))
    (dotimes (frame frames)
      (multiple-value-bind (next csn parts-start parts-end participants)
          (decision-frame buffer pos end version max-per-decision)
        (when csn
          (unless (< i count)
            (error 'invariant-violation :reason :decision-entry-count :offset pos))
          (let ((copy (make-array (- parts-end parts-start) :element-type '(unsigned-byte 8)))
                (offset (+ file-offset pos)))
            (replace copy buffer :start2 parts-start :end2 parts-end)
            (setf (aref entries i)
                  (%make-decision-entry (leggi-u64 buffer (+ pos +stamp-offset+))
                                        (leggi-u64 buffer csn) participants
                                        (sort-participants copy participants offset) offset)))
          (incf i)
          (incf participants-read participants))
        (setf pos next)))
    (unless (and (= pos end) (= i count) (= participants-read total))
      (error 'invariant-violation :reason :decision-prefix-consumption :offset pos))
    entries))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-FOR-003 REQ-VAL-001
(declaim (ftype (function (decision-entry decision-entry) boolean) same-decision-p))
(defun same-decision-p (left right)
  "Pre: entry private con partecipanti canonici. Post: CSN e insieme ID16 coincidono.
INVARIANT-VIOLATION per entry interna malformata; confronto completo e limitato."
  (check-entry-shape left)
  (check-entry-shape right)
  (and (= (%entry-csn left) (%entry-csn right)) (= (%entry-count left) (%entry-count right))
       (let ((a (%entry-participants left)) (b (%entry-participants right)))
         (loop for i below (length a) always (= (aref a i) (aref b i))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (simple-vector) (values index &optional)) unique-decision-count))
(defun unique-decision-count (entries)
  "Pre: entry ordinate stabilmente per TXID. Post: conta TXID unici, duplicati identici ammessi.
CORRUPTION-DETECTED al primo offset assoluto discordante; INVARIANT-VIOLATION per ordine.
Ogni confronto coinvolge solo copie possedute; nessuna tabella parziale restituita."
  (let ((previous nil) (unique 0) (conflict nil))
    (dotimes (i (length entries))
      (let ((entry (the decision-entry (aref entries i))))
        (check-entry-shape entry)
        (when (and previous (< (%entry-txid entry) (%entry-txid previous)))
          (error 'invariant-violation :reason :decision-entry-order))
        (if (and previous (= (%entry-txid entry) (%entry-txid previous)))
            (unless (same-decision-p previous entry)
              (setf conflict (if conflict (min conflict (%entry-source-offset entry))
                                (%entry-source-offset entry))))
            (progn (incf unique) (setf previous entry)))))
    (when conflict
      (error 'corruption-detected :reason :decision-conflict :offset conflict))
    (unless (<= unique (length entries))
      (error 'invariant-violation :reason :decision-entry-count))
    unique))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (simple-vector) (values decision-table &optional)) collapse-decisions))
(defun collapse-decisions (entries)
  "Pre: entry ordinate e possedute. Post: tabella privata completa, un'entry per TXID.
Propaga conflitti tipizzati prima della costruzione del risultato; nessun vettore esportato."
  (let* ((count (unique-decision-count entries))
         (result (make-array count :element-type t)) (previous nil) (next 0))
    (dotimes (i (length entries))
      (let ((entry (the decision-entry (aref entries i))))
        (unless (and previous (= (%entry-txid entry) (%entry-txid previous)))
          (unless (< next count)
            (error 'invariant-violation :reason :decision-entry-count))
          (setf (aref result next) entry previous entry)
          (incf next))))
    (unless (= next count)
      (error 'invariant-violation :reason :decision-entry-count))
    (%make-decision-table result)))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-TXM-002 REQ-TXM-003 REQ-FOR-003
;;; REQ: REQ-AFF-008 REQ-AFF-009 REQ-AFF-017 REQ-VAL-001
(declaim (ftype (function (octets integer integer
                                &key (:version integer) (:file-offset u64) (:file-size t)
                                (:max-bytes integer) (:max-batches integer)
                                (:max-batch-records integer) (:max-batch-bytes integer)
                                (:max-search-bytes integer) (:max-decisions integer)
                                (:max-participants integer) (:max-participants-per-decision integer))
                         (values decision-table index (member :complete :tail) &optional))
                ricostruisci-decisioni))
(defun ricostruisci-decisioni (buffer start end
                              &key (version 0) (file-offset 0) file-size
                                   (max-bytes 67108864) (max-batches 65536)
                                   (max-batch-records 65536) (max-batch-bytes 67108864)
                                   (max-search-bytes 67108864) (max-decisions 65536)
                                   (max-participants 65536) (max-participants-per-decision 65535))
  "Pre: log fino a EOF fisico stabile attestato da FILE-SIZE, versione esplicita;
START dopo header verificato o checkpoint autorevole. Budget finiti, zero ammesso per dati vuoti.
Post: tabella posseduta completa, prefisso nel buffer, COMPLETE/TAIL; nessun I/O, replay,
pubblicazione o mutazione del buffer. Duplicati uguali idempotenti, nessuna tabella parziale.
Propaga errori tipizzati; i payload nel prefisso sigillato non diventano una nuova coda.
Percorso di apertura con allocazioni ammesse; TXID/CSN sono u64 opachi anche zero o massimo."
  (check-decision-budgets max-decisions max-participants max-participants-per-decision)
  (multiple-value-bind (prefix status batches count)
      (scansiona-log buffer start end 0 :version version :log-kind :multiserie
                    :file-offset file-offset :file-size file-size :max-bytes max-bytes
                    :max-batches max-batches :max-batch-records max-batch-records
                    :max-batch-bytes max-batch-bytes :max-search-bytes max-search-bytes)
    (when (> count max-decisions)
      (error 'resource-exhausted :reason :decision-count-budget :offset (+ file-offset start)))
    (let* ((frames (+ batches count))
           (total (preflight-decisions buffer start prefix version frames count max-participants
                                       max-participants-per-decision file-offset))
           (entries (decode-decisions buffer start prefix version frames count total
                                      max-participants-per-decision file-offset)))
      (values (collapse-decisions (sort-entries entries)) prefix status))))
