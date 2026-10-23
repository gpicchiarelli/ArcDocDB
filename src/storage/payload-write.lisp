;;;; Encoder di payload da sezioni già possedute dal chiamante; preflight prima della copia.
;;; OWNER: buffer esclusivo; sezioni input stabili per l'intera chiamata.
;;; SHARED: nessuna struttura mutabile condivisa tra Serie.
(in-package #:arcdocdb.storage.format)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-FOR-003 REQ-AFF-008
(declaim (ftype (function (octets index u64 boolean octets u32 octets u32 u32 u32 index)
                         (values index u32 &optional)) preflight-edit))
(defun preflight-edit (buffer start next-id completo chiusi numero-chiusi rimossi
                      max-chiusi max-rimossi max-esiti max-bytes)
  "Pre: input tipizzati, sezioni senza alias con BUFFER. Post: tutte le sezioni e budget validi.
Restituisce fine output/count rimossi; errori tipizzati senza modificare BUFFER."
  (when (or (eq buffer chiusi) (eq buffer rimossi))
    (error 'invalid-argument :reason :input-alias :offset start))
  (unless (or completo (zerop next-id))
    (error 'invalid-argument :reason :edit-next-id :offset start))
  (unless (zerop (mod (length rimossi) +removed-id-bytes+))
    (error 'invalid-argument :reason :removed-id-length :offset start))
  (let ((size (+ +edit-min-bytes+ (length chiusi) (length rimossi)))
        (removed-count (floor (length rimossi) +removed-id-bytes+)))
    (unless (<= max-bytes +metadata-max-bytes+)
      (error 'invalid-argument :reason :metadata-byte-budget :offset start))
    (esigi-budget size max-bytes start)
    (esigi-budget removed-count max-rimossi start)
    (unless (= (length chiusi)
               (scandisci-chiusi chiusi 0 (length chiusi) numero-chiusi max-chiusi max-esiti))
      (error 'invalid-argument :reason :closed-trailing-data :offset start))
    (check-range buffer start (+ start size))
    (values (+ start size) removed-count)))

;;; REQ: REQ-FOR-003 REQ-AFF-008
(declaim (ftype (function (octets index u64 u64 octets u32 octets
                                &key (:completo boolean) (:max-chiusi u32)
                                (:max-rimossi u32) (:max-esiti u32) (:max-bytes index))
                         (values index &optional)) scrivi-valore-edit))
(defun scrivi-valore-edit (buffer start next-id open-id chiusi numero-chiusi rimossi
                         &key completo (max-chiusi +default-list-budget+)
                              (max-rimossi +default-list-budget+) (max-esiti +default-list-budget+)
                              (max-bytes +metadata-max-bytes+))
  "Pre: BUFFER esclusivo; CHIUSI entry codificate senza count, RIMOSSI ID u64 concatenati.
Post: payload EDIT canonico; restituisce fine. Nessun rifiuto di preflight modifica BUFFER.
Propaga errori tipizzati; completa la preparazione dei byte, senza punto di commit."
  (multiple-value-bind (end removed-count)
      (preflight-edit buffer start next-id completo chiusi numero-chiusi rimossi
                      max-chiusi max-rimossi max-esiti max-bytes)
    (let* ((closed-start (+ start +edit-closed-start+))
           (removed-count-start (+ closed-start (length chiusi)))
           (removed-start (+ removed-count-start +count-bytes+)))
      (scrivi-u64 buffer (+ start +edit-next-id-offset+) next-id)
      (scrivi-u64 buffer (+ start +edit-open-offset+) open-id)
      (scrivi-u32 buffer (+ start +edit-closed-count-offset+) numero-chiusi)
      (replace buffer chiusi :start1 closed-start :end1 removed-count-start)
      (scrivi-u32 buffer removed-count-start removed-count)
      (replace buffer rimossi :start1 removed-start :end1 end)
      end)))

;;; REQ: REQ-FOR-003 REQ-TXM-001 REQ-AFF-008
(declaim (ftype (function (octets index u64 octets
                                &key (:max-partecipanti u16) (:max-bytes index))
                         (values index &optional)) scrivi-valore-decision))
(defun scrivi-valore-decision (buffer start csn partecipanti
                             &key (max-partecipanti +max-participants+)
                                  (max-bytes +metadata-max-bytes+))
  "Pre: BUFFER esclusivo; PARTECIPANTI ID16 concatenati senza alias, almeno due.
Post: payload DECISION canonico, fine restituita; fuori range invariato.
INVALID-ARGUMENT per sezioni, RESOURCE-EXHAUSTED per budget; preflight non mutante."
  (when (eq buffer partecipanti)
    (error 'invalid-argument :reason :input-alias :offset start))
  (unless (zerop (mod (length partecipanti) +participant-id-bytes+))
    (error 'invalid-argument :reason :participant-id-length :offset start))
  (let* ((count (floor (length partecipanti) +participant-id-bytes+))
         (size (+ +decision-parts-offset+ (length partecipanti))) (end (+ start size)))
    (when (< count +min-participants+)
      (error 'invalid-argument :reason :decision-participants :offset start))
    (unless (<= max-bytes +metadata-max-bytes+)
      (error 'invalid-argument :reason :metadata-byte-budget :offset start))
    (esigi-budget count max-partecipanti start)
    (esigi-budget size max-bytes start)
    (check-range buffer start end)
    (scrivi-u64 buffer (+ start +decision-csn-offset+) csn)
    (scrivi-u16 buffer (+ start +decision-count-offset+) count)
    (replace buffer partecipanti :start1 (+ start +decision-parts-offset+) :end1 end)
    end))
