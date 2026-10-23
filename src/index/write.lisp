;;; OWNER: ogni chiamata ha il gettone writer della Serie; nessuna mutazione concorrente.
;;; SHARED: solo seqlock e campi dello slot; interruzione composta => salute terminale.
(in-package #:arcdocdb.index.slots)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-AFF-004
(declaim (inline sequenza-slot-writer))
(declaim (ftype (function (banco-slot fixnum) u64) sequenza-slot-writer))
(defun sequenza-slot-writer (bank base)
  "Pre: writer esclusivo, base valida. Post: contenuto coerente e sequenza pari senza wrap.
Corruzione => FAULTED; non consuma o richiede credito seqlock per una semplice verifica."
  (let* ((words (banco-slot-words bank)) (sequence (aref words (+ base +slot-sequence+))))
    (declare (type u64 sequence))
    (when (or (oddp sequence) (>= sequence +slot-sequence-limit+))
      (guasto-slot bank :index-slot-writer-sequence))
    (verifica-campi-slot bank (aref words (+ base +slot-csn+)) (aref words (+ base +slot-location+))
                         (aref words (+ base +slot-key+)) (aref words (+ base +slot-length+))
                         (if (banco-slot-retained bank) (aref words (+ base +slot-end+)) 0))
    sequence))

;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-AFF-008
(declaim (ftype (function (banco-slot integer) fixnum) credito-scrittura-slot))
(defun credito-scrittura-slot (bank slot)
  "Pre: writer esclusivo; preflight prima del commit, inclusi tutti gli aggiornamenti già in volo.
Post: numero di incrementi doppi ancora ammessi; zero richiede rebuild prima del commit.
Non prenota crediti: il writer contabilizza quelli necessari ai lotti pendenti della stessa Serie."
  (esigi-banco-writer bank)
  (let ((sequence (sequenza-slot-writer bank (base-slot bank slot))))
    (declare (type u64 sequence))
    (esigi-banco-sano bank)
    (values (floor (- +slot-sequence-limit+ 2 sequence) 2))))

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-LIM-001 REQ-AFF-004
(declaim (ftype (function (banco-slot fixnum (or null contenuto-slot)) null) cambia-slot))
(defun cambia-slot (bank base source)
  "Pre: writer, contenuto SOURCE già validato e privato, oppure NIL per rimozione.
Post: tutti i campi pubblicati prima della nuova sequenza pari; nessuna durability attestata.
Ogni interruzione dopo l'avvio della mutazione rende FAULTED, senza rollback del seqlock."
  (let* ((words (banco-slot-words bank)) (sequence (sequenza-slot-writer bank base)) (complete nil))
    (declare (type u64 sequence))
    (when (>= sequence (- +slot-sequence-limit+ 2))
      (error 'resource-exhausted :reason :index-slot-seqlock-rebuild))
    (unwind-protect
         (progn
           (esigi-banco-sano bank)
           (setf (aref words (+ base +slot-sequence+)) (1+ sequence))
           (sb-thread:barrier (:write))
           (setf (aref words (+ base +slot-csn+)) (if source (aref source 0) 0)
                 (aref words (+ base +slot-location+)) (if source (aref source 1) 0)
                 (aref words (+ base +slot-key+)) (if source (aref source 2) 0)
                 (aref words (+ base +slot-length+)) (if source (aref source 3) 0))
           (when (banco-slot-retained bank)
             (setf (aref words (+ base +slot-end+)) (if source (aref source 4) 0)))
           (sb-thread:barrier (:write))
           (setf (aref words (+ base +slot-sequence+)) (+ sequence 2))
           (esigi-banco-sano bank)
           (setf complete t))
      (unless complete (invalida-banco-slot bank))))
  nil)

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-LIM-001 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (banco-slot integer contenuto-slot) null) pubblica-slot-v2))
(defun pubblica-slot-v2 (bank slot source)
  "Pre: gettone writer, SOURCE privata; chiave/arena, retention, conflitti e budget prevalidati.
Post: payload pubblicato sotto seqlock; nessuna conferma di commit o byte di controllo scritto.
Input/range/frozen rifiutati prima della mutazione; ricostruire se manca credito seqlock."
  (esigi-banco-writer bank)
  (let ((base (base-slot bank slot)))
    (esigi-contenuto-slot bank source)
    (cambia-slot bank base source))
  nil)

;;; REQ: REQ-IDX-003 REQ-IDX-006 REQ-AFF-004
(declaim (ftype (function (banco-slot integer) null) rimuovi-slot-v2))
(defun rimuovi-slot-v2 (bank slot)
  "Pre: writer esclusivo, retention e tombstone dello storage già gestiti dal chiamante.
Post: payload zero sotto seqlock, nessun tombstone in memoria; il controllo diventa DELETED dopo.
Non cambia chiavi dell'arena; slot vuoto già rimosso è idempotente senza consumare sequenza."
  (esigi-banco-writer bank)
  (let* ((base (base-slot bank slot)) (words (banco-slot-words bank)))
    (sequenza-slot-writer bank base)
    (unless (zerop (aref words (+ base +slot-csn+))) (cambia-slot bank base nil)))
  (esigi-banco-sano bank)
  nil)
