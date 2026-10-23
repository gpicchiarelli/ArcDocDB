;;;; Header control/multiserie; nessun I/O, replay o attestazione di durability.
;;; OWNER: chiamante; buffer esclusivo in scrittura e stabile durante la verifica.
;;; SHARED: nessuna mutazione condivisa tra Serie, lock o contatore globale.
(in-package #:arcdocdb.storage.format)
(declaim (optimize (safety 3) (debug 2)))
;;; REQ: REQ-FOR-001 REQ-FOR-002
(declaim (ftype (function (t index) (values u32 &optional)) magic-log))
(defun magic-log (log-kind offset)
  "Pre: tipo dichiarato dal chiamante. Post: magic alto; INVALID-ARGUMENT per altro tipo."
  (case log-kind (:control +control-magic-high+) (:multiserie +multiserie-magic-high+)
    (otherwise (error 'invalid-argument :reason :log-kind :offset offset))))
;;; REQ: REQ-FOR-001 REQ-FOR-002
(declaim (ftype (function (octets index t octets &key (:version integer))
                         (values index &optional)) scrivi-header-log))
(defun scrivi-header-log (buffer start log-kind identity &key (version 2))
  "Pre: BUFFER esclusivo, ID octets 16 byte senza alias, tipo CONTROL/MULTISERIE.
Post: header canonico di 64 byte, CRC e riservati zero; fuori range invariato.
INVALID-ARGUMENT/UNSUPPORTED-FORMAT nel preflight non modificano BUFFER."
  (let ((next (+ start +log-header-bytes+)) (magic (magic-log log-kind start)))
    (when (eq buffer identity) (error 'invalid-argument :reason :input-alias :offset start))
    (check-range buffer start next)
    (unless (= (length identity) +log-identity-bytes+)
      (error 'invalid-argument :reason :log-identity-length :offset start))
    (versione-supportata version start)
    (fill buffer 0 :start start :end next)
    (scrivi-u32 buffer start +log-magic-low+)
    (scrivi-u32 buffer (+ start +log-magic-high-offset+) magic)
    (scrivi-u16 buffer (+ start +log-version-offset+) version)
    (replace buffer identity :start1 (+ start +log-identity-offset+))
    (scrivi-u32 buffer (+ start +log-crc-offset+) (crc32c buffer start (+ start +log-crc-offset+)))
    next))
;;; REQ: REQ-FOR-001 REQ-FOR-002
(declaim (ftype (function (octets index index t octets) (values index u16 &optional))
                verifica-header-log))
(defun verifica-header-log (buffer start end log-kind identity)
  "Pre: range stabile, tipo e ID autorevoli. Post: fine header e versione; input invariati.
INVALID-ARGUMENT per configurazione; CORRUPTION-DETECTED per byte errati;
UNSUPPORTED-FORMAT per versione ignota dopo CRC e magic validi. Nessuna copia."
  (check-range buffer start end)
  (let ((magic (magic-log log-kind start)) (next (+ start +log-header-bytes+)))
    (unless (= (length identity) +log-identity-bytes+)
      (error 'invalid-argument :reason :log-identity-length :offset start))
    (when (< (- end start) +log-header-bytes+)
      (error 'corruption-detected :reason :log-header-truncated :offset start))
    (unless (= (leggi-u32 buffer (+ start +log-crc-offset+))
               (crc32c buffer start (+ start +log-crc-offset+)))
      (error 'corruption-detected :reason :log-header-crc :offset start))
    (unless (and (= (leggi-u32 buffer start) +log-magic-low+)
                 (= (leggi-u32 buffer (+ start +log-magic-high-offset+)) magic))
      (error 'corruption-detected :reason :log-magic :offset start))
    (let ((version (versione-supportata (leggi-u16 buffer (+ start +log-version-offset+)) start)))
      (unless (and (zero-range-p buffer (+ start +log-reserved-a-start+) (+ start +log-reserved-a-end+))
                   (zero-range-p buffer (+ start +log-reserved-b-start+) (+ start +log-crc-offset+))
                   (zero-range-p buffer (+ start +log-reserved-c-start+) next))
        (error 'corruption-detected :reason :log-reserved :offset start))
      (unless (loop for i below +log-identity-bytes+
                    always (= (aref buffer (+ start +log-identity-offset+ i)) (aref identity i)))
        (error 'corruption-detected :reason :log-identity :offset start))
      (values next version))))
