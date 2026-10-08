;;;; SPK-09: CRC32C e verifica della cornice ADR-0039, senza dipendenze.
;;; REQ: REQ-SIM-002
;;; REQ: REQ-FOR-001
;;; REQ: REQ-FOR-003
;;; REQ: REQ-FOR-004
;;; REQ: REQ-AFF-002
;;; REQ: REQ-AFF-003
;;; REQ: REQ-BEN-001
;;; REQ: REQ-BEN-002

(defpackage #:arcdocdb.spk09
  (:use #:cl)
  (:export #:check #:benchmark #:crc32c-reference
           #:crc32c-byte-safety2 #:crc32c-byte-safety3
           #:crc32c-slicing8-safety2 #:crc32c-slicing8-safety3
           #:verify-record #:verifier-record-safety2 #:verifier-record-safety3
           #:verify-prepared-record
           #:record-invalid #:record-invalid-reason))

(in-package #:arcdocdb.spk09)
(declaim (optimize (speed 2) (safety 3) (debug 1)))

(deftype octets () '(simple-array (unsigned-byte 8) (*)))
(deftype indice () '(integer 0 1073741824))
(deftype u32 () '(unsigned-byte 32))
(deftype u64 () '(unsigned-byte 64))

(defconstant +polinomio+ #x82f63b78)
(defconstant +maschera-crc+ #xffffffff)
(defconstant +header-bytes+ 24)
(defconstant +offset-header-crc+ 0)
(defconstant +offset-body-crc+ 4)
(defconstant +offset-tipo+ 8)
(defconstant +offset-flag+ 9)
(defconstant +offset-key-len+ 10)
(defconstant +offset-riservato+ 11)
(defconstant +offset-value-len+ 12)
(defconstant +offset-stamp+ 16)
(defconstant +tipo-put+ 1)
(defconstant +tipo-outcome+ 4)
(defconstant +outcome-value-bytes+ 8)
(defconstant +outcome-bytes+ 32)
(defconstant +flag-prepared+ 1)
(defconstant +flag-put-ammessi+ 5)
(defconstant +max-record-bytes+ #xffffff)

(define-condition spike-error (error)
  ((messaggio :initarg :messaggio :type string :reader spike-error-messaggio))
  (:report (lambda (condizione stream)
             (write-string (spike-error-messaggio condizione) stream))))

(define-condition record-invalid (spike-error)
  ((reason :initarg :reason :type keyword :reader record-invalid-reason)))

(defun rifiuta-record (motivo)
  "Segnala una cornice non verificata; non restituisce offset del valore."
  (error 'record-invalid :reason motivo
         :messaggio (format nil "Record non valido: ~S" motivo)))

(defun esigi (condizione messaggio)
  "Fa fallire esplicitamente una precondizione o una verifica deterministica."
  (unless condizione (error 'spike-error :messaggio messaggio)))

(declaim (ftype (function (octets integer integer) null) controlla-intervallo))
(defun controlla-intervallo (buffer inizio fine)
  "Controlla l'intervallo completo prima di accedere al buffer CRC."
  (declare (type octets buffer) (type integer inizio fine))
  (esigi (<= 0 inizio fine (length buffer) 1073741824)
         "Intervallo CRC fuori limiti.")
  nil)

;;; REQ: REQ-FOR-001
(declaim (ftype (function (octets integer integer) u32) crc32c-reference))
(defun crc32c-reference (buffer inizio fine)
  "CRC32C bit a bit indipendente dai kernel a tabella, su [INIZIO,FINE)."
  (declare (type octets buffer) (type integer inizio fine)
           (optimize (safety 3)))
  (controlla-intervallo buffer inizio fine)
  (let ((crc +maschera-crc+))
    (declare (type u32 crc))
    (loop for posizione from inizio below fine do
      (setf crc (logxor crc (aref buffer posizione)))
      (dotimes (bit 8)
        (setf crc (if (oddp crc)
                     (logxor (ash crc -1) +polinomio+)
                     (ash crc -1)))))
    (logxor crc +maschera-crc+)))

(defun costruisci-tabelle ()
  "Costruisce otto tabelle CRC di 256 elementi con ricorrenze esplicite."
  (let ((tabelle (make-array '(8 256) :element-type '(unsigned-byte 32))))
    (dotimes (byte 256)
      (let ((crc byte))
        (dotimes (bit 8)
          (setf crc (if (logbitp 0 crc)
                       (logxor +polinomio+ (ash crc -1))
                       (ash crc -1))))
        (setf (aref tabelle 0 byte) crc)))
    (loop for strato from 1 below 8 do
      (dotimes (byte 256)
        (let ((crc (aref tabelle (1- strato) byte)))
          (setf (aref tabelle strato byte)
                (logxor (ash crc -8)
                        (aref tabelle 0 (logand crc 255)))))))
    tabelle))

;;; OWNER: caricamento del package; le tabelle non vengono mutate dopo il load.
(defparameter *tabelle-crc* (costruisci-tabelle))
(declaim (type (simple-array (unsigned-byte 32) (8 256)) *tabelle-crc*))

;; Le macro servono al compilatore e al load sorgente, non si ridefiniscono nel FASL.
(eval-when (:compile-toplevel :execute)
(defmacro definisci-kernel-crc (nome sicurezza slicing)
  "Genera lo stesso kernel per ciascuna policy; nessuna compilazione dinamica."
  `(progn
     (declaim (ftype (function (octets integer integer) u32) ,nome))
     (defun ,nome (buffer inizio fine)
       "CRC32C tipizzato con controlli di tipo e limiti attivi."
       (declare (type octets buffer) (type integer inizio fine)
                (optimize (speed 3) (safety ,sicurezza) (debug 1)))
       (controlla-intervallo buffer inizio fine)
       (let ((crc +maschera-crc+) (posizione (the indice inizio))
             (limite (the indice fine)) (tabelle *tabelle-crc*))
         (declare (type u32 crc) (type indice posizione limite)
                  (type (simple-array (unsigned-byte 32) (8 256)) tabelle))
         ,@(when slicing
             '((loop repeat (floor (- limite posizione) 8) do
                 (let ((parola (logxor crc
                                (aref buffer posizione)
                                (ash (aref buffer (+ posizione 1)) 8)
                                (ash (aref buffer (+ posizione 2)) 16)
                                (ash (aref buffer (+ posizione 3)) 24))))
                   (declare (type u32 parola))
                   (setf crc
                     (logxor (aref tabelle 7 (ldb (byte 8 0) parola))
                             (aref tabelle 6 (ldb (byte 8 8) parola))
                             (aref tabelle 5 (ldb (byte 8 16) parola))
                             (aref tabelle 4 (ldb (byte 8 24) parola))
                             (aref tabelle 3 (aref buffer (+ posizione 4)))
                             (aref tabelle 2 (aref buffer (+ posizione 5)))
                             (aref tabelle 1 (aref buffer (+ posizione 6)))
                             (aref tabelle 0 (aref buffer (+ posizione 7))))))
                 (incf posizione 8))))
         (loop for indice from posizione below limite do
           (setf crc (logxor (ash crc -8)
                            (aref tabelle 0
                              (logand 255 (logxor crc (aref buffer indice)))))))
         (logxor crc +maschera-crc+))))))

(definisci-kernel-crc crc32c-byte-safety2 2 nil)
(definisci-kernel-crc crc32c-byte-safety3 3 nil)
(definisci-kernel-crc crc32c-slicing8-safety2 2 t)
(definisci-kernel-crc crc32c-slicing8-safety3 3 t)

(declaim (inline leggi-u32 leggi-u64))
(declaim (ftype (function (octets indice) u32) leggi-u32)
         (ftype (function (octets indice) u64) leggi-u64))
(defun leggi-u32 (buffer posizione)
  "Legge u32 little-endian; il chiamante ha già verificato i limiti."
  (declare (type octets buffer) (type indice posizione))
  (logior (aref buffer posizione) (ash (aref buffer (+ posizione 1)) 8)
          (ash (aref buffer (+ posizione 2)) 16)
          (ash (aref buffer (+ posizione 3)) 24)))

(defun leggi-u64 (buffer posizione)
  "Legge u64 little-endian senza assumerne la rappresentazione come fixnum."
  (declare (type octets buffer) (type indice posizione))
  (logior (leggi-u32 buffer posizione)
          (ash (leggi-u32 buffer (+ posizione 4)) 32)))

(defun scrivi-intero (buffer posizione valore byte-count)
  "Scrive un intero little-endian su un buffer di costruzione già dimensionato."
  (declare (type octets buffer) (type indice posizione)
           (type (integer 0 *) valore) (type (integer 1 8) byte-count))
  (dotimes (byte byte-count)
    (setf (aref buffer (+ posizione byte)) (ldb (byte 8 (* byte 8)) valore)))
  buffer)

(defun confronta-chiave (buffer inizio lunghezza chiave)
  "Confronta tutti i byte della chiave attesa dopo la verifica dei limiti."
  (declare (type octets buffer chiave) (type indice inizio lunghezza))
  (and (= lunghezza (length chiave))
       (loop for i below lunghezza
             always (= (aref buffer (+ inizio i)) (aref chiave i)))))

;;; REQ: REQ-FOR-003
;;; REQ: REQ-AFF-002
(eval-when (:compile-toplevel :execute)
(defmacro definisci-verificatore (nome sicurezza crc)
  "Genera verificatori identici: header, limiti, semantica, corpo e entry."
  `(defun ,nome (buffer inizio fine chiave csn lunghezza-attesa
                &optional (prepared nil) (massimo +max-record-bytes+))
     "Verifica un PUT ADR-0039; restituisce inizio/fine del valore e stamp."
     (declare (type octets buffer chiave) (type integer inizio fine massimo)
              (type u64 csn) (type integer lunghezza-attesa)
              (type boolean prepared)
              (optimize (speed 3) (safety ,sicurezza) (debug 1)))
     (unless (<= 0 inizio fine (length buffer) 1073741824)
       (rifiuta-record :bounds))
     (unless (<= +header-bytes+ massimo +max-record-bytes+)
       (rifiuta-record :max-parameter))
     (when (< (- fine inizio) +header-bytes+) (rifiuta-record :truncated-header))
     (let* ((base (the indice inizio)) (corpo (+ base +header-bytes+)))
       ;; Nessun campo di lunghezza viene letto prima di questo confronto.
       (unless (= (leggi-u32 buffer (+ base +offset-header-crc+))
                  (,crc buffer (+ base +offset-body-crc+) corpo))
         (rifiuta-record :header-crc))
       (let* ((key-len (aref buffer (+ base +offset-key-len+)))
              (value-len (leggi-u32 buffer (+ base +offset-value-len+)))
              (totale (+ +header-bytes+ key-len value-len))
              (flag (aref buffer (+ base +offset-flag+))))
         (when (> totale massimo) (rifiuta-record :max-record))
         (when (> totale (- fine base)) (rifiuta-record :truncated-body))
         (unless (= totale lunghezza-attesa) (rifiuta-record :entry-length))
         (unless (= (aref buffer (+ base +offset-tipo+)) +tipo-put+)
           (rifiuta-record :not-put))
         (unless (zerop (aref buffer (+ base +offset-riservato+)))
           (rifiuta-record :reserved))
         (unless (zerop (logand flag (logxor +flag-put-ammessi+ 255)))
           (rifiuta-record :flags))
         (when (zerop key-len) (rifiuta-record :empty-key))
         (unless (eq prepared (not (zerop (logand flag +flag-prepared+))))
           (rifiuta-record :prepared-mismatch))
         (let ((termine (the indice (+ base totale)))
               (stamp (leggi-u64 buffer (+ base +offset-stamp+))))
           (unless (= (leggi-u32 buffer (+ base +offset-body-crc+))
                      (,crc buffer corpo termine))
             (rifiuta-record :body-crc))
           (unless (confronta-chiave buffer corpo key-len chiave)
             (rifiuta-record :key-mismatch))
           (unless (or prepared (= stamp csn)) (rifiuta-record :csn-mismatch))
           (values (+ corpo key-len) termine stamp)))))))

(declaim (ftype (function (octets integer integer octets u64 integer
                          &optional boolean integer)
                         (values indice indice u64 &optional))
                verifier-record-safety2 verifier-record-safety3 verify-record))
(definisci-verificatore verifier-record-safety2 2 crc32c-slicing8-safety2)
(definisci-verificatore verifier-record-safety3 3 crc32c-slicing8-safety3)

(defun verify-record (buffer inizio fine chiave csn lunghezza-attesa
                      &optional (prepared nil) (massimo +max-record-bytes+))
  "Cornice con safety 3; un prepared resta parsing, senza prova del suo CSN."
  (verifier-record-safety3 buffer inizio fine chiave csn lunghezza-attesa
                         prepared massimo))

;;; REQ: REQ-FOR-003
;;; REQ: REQ-AFF-002
;;; REQ: REQ-FOR-004
(declaim (ftype (function (octets integer integer u64 u64) u64) verifica-outcome))
(defun verifica-outcome (buffer inizio fine txid-atteso csn-atteso)
  "Verifica la sola cornice OUTCOME ADR-0039 e il legame TXID->CSN atteso."
  (declare (type octets buffer) (type integer inizio fine)
           (type u64 txid-atteso csn-atteso) (optimize (safety 3)))
  (unless (<= 0 inizio fine (length buffer) 1073741824)
    (rifiuta-record :outcome-bounds))
  (when (< (- fine inizio) +header-bytes+)
    (rifiuta-record :outcome-truncated-header))
  (let* ((base (the indice inizio)) (corpo (+ base +header-bytes+)))
    (unless (= (leggi-u32 buffer (+ base +offset-header-crc+))
               (crc32c-slicing8-safety3 buffer (+ base +offset-body-crc+) corpo))
      (rifiuta-record :outcome-header-crc))
    (let* ((key-len (aref buffer (+ base +offset-key-len+)))
           (value-len (leggi-u32 buffer (+ base +offset-value-len+)))
           (totale (+ +header-bytes+ key-len value-len)))
      (when (> totale +max-record-bytes+) (rifiuta-record :outcome-max-record))
      (when (> totale (- fine base)) (rifiuta-record :outcome-truncated-body))
      (unless (and (= totale +outcome-bytes+) (zerop key-len)
                   (= value-len +outcome-value-bytes+))
        (rifiuta-record :outcome-length))
      (unless (= (aref buffer (+ base +offset-tipo+)) +tipo-outcome+)
        (rifiuta-record :not-outcome))
      (unless (and (zerop (aref buffer (+ base +offset-flag+)))
                   (zerop (aref buffer (+ base +offset-riservato+))))
        (rifiuta-record :outcome-flags-reserved))
      (unless (= (leggi-u32 buffer (+ base +offset-body-crc+))
                 (crc32c-slicing8-safety3 buffer corpo (+ base totale)))
        (rifiuta-record :outcome-body-crc))
      (unless (= (leggi-u64 buffer (+ base +offset-stamp+)) txid-atteso)
        (rifiuta-record :outcome-txid-mismatch))
      (let ((csn (leggi-u64 buffer corpo)))
        (unless (= csn csn-atteso) (rifiuta-record :outcome-csn-mismatch))
        csn))))

;;; REQ: REQ-FOR-004
(declaim (ftype (function (octets integer integer octets u64 integer
                          (or null octets) &key (:outcome-start integer)
                          (:outcome-end (or null integer)) (:massimo integer))
                         (values indice indice u64 u64 &optional))
                verify-prepared-record))
(defun verify-prepared-record (buffer inizio fine chiave expected-csn lunghezza-attesa
                              outcome-buffer &key (outcome-start 0) outcome-end
                              (massimo +max-record-bytes+))
  "Verifica prepared e OUTCOME indipendente; restituisce offset, CSN risolto e TXID.
La provenienza e la visibilità della prova restano responsabilità del resolver."
  (declare (type octets buffer chiave) (type integer inizio fine lunghezza-attesa)
           (type u64 expected-csn) (type (or null octets) outcome-buffer)
           (type integer outcome-start massimo) (type (or null integer) outcome-end)
           (optimize (safety 3)))
  (unless outcome-buffer (rifiuta-record :missing-outcome))
  (multiple-value-bind (valore termine txid)
      (verify-record buffer inizio fine chiave expected-csn lunghezza-attesa t massimo)
    (let ((csn (verifica-outcome outcome-buffer outcome-start
                               (or outcome-end (length outcome-buffer))
                               txid expected-csn)))
      (values valore termine csn txid))))

(eval-when (:compile-toplevel :execute)
(defmacro definisci-accumulatore (nome sicurezza)
  "Genera lo stesso lavoro sul valore per le letture di entrambe le policy."
  `(progn
     (declaim (ftype (function (octets indice indice u64) u32) ,nome))
     (defun ,nome (buffer inizio fine stamp)
       "Attraversa ogni byte del valore e incorpora stamp nel risultato."
       (declare (type octets buffer) (type indice inizio fine) (type u64 stamp)
                (optimize (speed 3) (safety ,sicurezza) (debug 1)))
       (let ((somma (logand stamp +maschera-crc+)))
         (declare (type u32 somma))
         (loop for i from inizio below fine do
           (setf somma (logand +maschera-crc+ (+ somma (aref buffer i)))))
         somma)))))

(definisci-accumulatore accumula-valore-safety2 2)
(definisci-accumulatore accumula-valore-safety3 3)

(eval-when (:compile-toplevel :execute)
(defmacro definisci-letture (verificata libera verificatore accumulatore sicurezza)
  "Genera letture con lo stesso accumulatore, su buffer immutabili già pronti."
  `(progn
     (defun ,verificata (buffer inizio fine chiave csn lunghezza)
       "Verifica il record prima di attraversare il valore."
       (declare (type octets buffer chiave) (type indice inizio fine lunghezza)
                (type u64 csn)
                (optimize (speed 3) (safety ,sicurezza) (debug 1)))
       (multiple-value-bind (valore termine stamp)
           (,verificatore buffer inizio fine chiave csn lunghezza)
         (,accumulatore buffer valore termine stamp)))
     (defun ,libera (buffer inizio fine chiave csn lunghezza)
       "Baseline su fixture valide: stessi byte e calcolo, controlli CRC assenti."
       (declare (type octets buffer chiave) (type indice inizio fine lunghezza)
                (type u64 csn) (ignore fine chiave csn lunghezza)
                (optimize (speed 3) (safety ,sicurezza) (debug 1)))
       (let* ((corpo (+ inizio +header-bytes+))
              (valore (+ corpo (aref buffer (+ inizio +offset-key-len+))))
              (termine (+ valore (leggi-u32 buffer (+ inizio +offset-value-len+))))
              (stamp (leggi-u64 buffer (+ inizio +offset-stamp+))))
         (,accumulatore buffer valore termine stamp))))))

(definisci-letture leggi-verificato-safety2 leggi-libero-safety2
                  verifier-record-safety2 accumula-valore-safety2 2)
(definisci-letture leggi-verificato-safety3 leggi-libero-safety3
                  verifier-record-safety3 accumula-valore-safety3 3)

(defun aggiorna-crc-record (buffer inizio fine &optional (corpo t))
  "Ricalcola CRC delle fixture, tramite il riferimento bit a bit."
  (when corpo
    (scrivi-intero buffer (+ inizio +offset-body-crc+)
                  (crc32c-reference buffer (+ inizio +header-bytes+) fine) 4))
  (scrivi-intero buffer (+ inizio +offset-header-crc+)
                (crc32c-reference buffer (+ inizio +offset-body-crc+)
                                  (+ inizio +header-bytes+)) 4)
  buffer)

(defun costruisci-record (chiave valore stamp &key (inizio 0) (flag 0))
  "Costruisce una fixture PUT ADR-0039 con CRC del riferimento."
  (declare (type octets chiave valore) (type u64 stamp)
           (type indice inizio) (type (unsigned-byte 8) flag))
  (esigi (<= 1 (length chiave) 255) "Chiave della fixture fuori limiti.")
  (let* ((totale (+ +header-bytes+ (length chiave) (length valore)))
         (fine (+ inizio totale))
         (buffer (make-array fine :element-type '(unsigned-byte 8)
                                 :initial-element 0)))
    (esigi (<= totale +max-record-bytes+) "Fixture troppo grande.")
    (setf (aref buffer (+ inizio +offset-tipo+)) +tipo-put+
          (aref buffer (+ inizio +offset-flag+)) flag
          (aref buffer (+ inizio +offset-key-len+)) (length chiave))
    (scrivi-intero buffer (+ inizio +offset-value-len+) (length valore) 4)
    (scrivi-intero buffer (+ inizio +offset-stamp+) stamp 8)
    (replace buffer chiave :start1 (+ inizio +header-bytes+))
    (replace buffer valore :start1 (+ inizio +header-bytes+ (length chiave)))
    (aggiorna-crc-record buffer inizio fine)
    (values buffer inizio fine totale)))

(defun costruisci-outcome (txid csn &key (inizio 0))
  "Costruisce una fixture OUTCOME reale, senza chiave e con CSN u64 nel valore."
  (declare (type u64 txid csn) (type indice inizio))
  (let* ((fine (+ inizio +outcome-bytes+))
         (buffer (make-array fine :element-type '(unsigned-byte 8)
                                 :initial-element 0)))
    (setf (aref buffer (+ inizio +offset-tipo+)) +tipo-outcome+)
    (scrivi-intero buffer (+ inizio +offset-value-len+) +outcome-value-bytes+ 4)
    (scrivi-intero buffer (+ inizio +offset-stamp+) txid 8)
    (scrivi-intero buffer (+ inizio +header-bytes+) csn 8)
    (aggiorna-crc-record buffer inizio fine)
    (values buffer inizio fine)))

(defun ottetti-deterministici (lunghezza &optional (seme #x09c0ffee))
  "Genera dati riproducibili con LCG u32; non usa lo stato random del processo."
  (declare (type indice lunghezza) (type u32 seme))
  (let ((buffer (make-array lunghezza :element-type '(unsigned-byte 8))))
    (dotimes (i lunghezza)
      (setf seme (logand +maschera-crc+ (+ (* seme 1664525) 1013904223))
            (aref buffer i) (ldb (byte 8 24) seme)))
    buffer))

(defun descrittori-crc ()
  "Elenca kernel e policy senza lookup dinamico di nomi."
  (list (list :reference 3 #'crc32c-reference)
        (list :byte 2 #'crc32c-byte-safety2)
        (list :byte 3 #'crc32c-byte-safety3)
        (list :slicing-by-8 2 #'crc32c-slicing8-safety2)
        (list :slicing-by-8 3 #'crc32c-slicing8-safety3)))

;;; REQ: REQ-FOR-001
(defun check-req-for-001-crc ()
  "Vettori golden e confronto differenziale su taglie, offset e intervalli."
  (let ((vuoto (make-array 0 :element-type '(unsigned-byte 8)))
        (golden (make-array 9 :element-type '(unsigned-byte 8)
                             :initial-contents '(49 50 51 52 53 54 55 56 57)))
        (buffer (ottetti-deterministici 32784)) (confronti 0) (intervalli 0))
    (labels ((confronta (dati inizio fine atteso)
               (dolist (descrittore (descrittori-crc))
                 (esigi (= atteso (funcall (third descrittore) dati inizio fine))
                        "REQ-FOR-001: discordanza del CRC32C.")
                 (incf confronti))))
      (confronta vuoto 0 0 0)
      (confronta golden 0 9 #xe3069283)
      (loop for lunghezza from 0 to 256 do
        (dotimes (allineamento 16)
          (let ((fine (+ allineamento lunghezza)))
            (confronta buffer allineamento fine
                       (crc32c-reference buffer allineamento fine))
            (incf intervalli))))
      (let ((seme #x739ad013))
        (dotimes (i 512)
          (setf seme (logand +maschera-crc+ (+ (* seme 1664525) 1013904223)))
          (let* ((inizio (mod seme 16000)) (fine (+ inizio (mod (ash seme -16) 257))))
            (confronta buffer inizio fine (crc32c-reference buffer inizio fine))
            (incf intervalli))))
      (dolist (lunghezza '(511 512 513 2048 16384 32768))
        (dotimes (allineamento 8)
          (let ((fine (+ allineamento lunghezza)))
            (confronta buffer allineamento fine
                       (crc32c-reference buffer allineamento fine))
            (incf intervalli)))))
    (list :golden 2 :ranges intervalli :comparisons confronti)))

(defun esigi-rifiuto (funzione motivo)
  "Esige una condizione record-invalid precisa; altri errori non sono catturati."
  (handler-case
      (progn (funcall funzione)
             (error 'spike-error :messaggio "Record alterato accettato."))
    (record-invalid (condizione)
      (esigi (eq (record-invalid-reason condizione) motivo)
             (format nil "Motivo atteso ~S, ricevuto ~S."
                     motivo (record-invalid-reason condizione)))))
  1)

(defun verifica-fixture (verificatore buffer inizio fine chiave csn totale
                       &optional prepared (massimo +max-record-bytes+))
  "Invoca una delle due policy sul medesimo intervallo e sulla medesima entry."
  (funcall verificatore buffer inizio fine chiave csn totale prepared massimo))

;;; REQ: REQ-FOR-003
(defun check-req-for-003-alterazioni (verificatore)
  "Altera ogni bit di ogni byte e tronca ad ogni possibile frontiera."
  (let ((chiave (ottetti-deterministici 13)) (valore (ottetti-deterministici 137))
        (corruzioni-header 0) (corruzioni-corpo 0) (troncamenti 0))
    (multiple-value-bind (buffer inizio fine totale)
        (costruisci-record chiave valore 17 :inizio 7)
      (loop for posizione from inizio below fine do
        (dotimes (bit 8)
          (let ((danneggiato (copy-seq buffer))
                (motivo (if (< posizione (+ inizio +header-bytes+))
                            :header-crc :body-crc)))
            (setf (aref danneggiato posizione)
                  (logxor (aref danneggiato posizione) (ash 1 bit)))
            (esigi-rifiuto
             (lambda () (verifica-fixture verificatore danneggiato inizio fine
                                          chiave 17 totale)) motivo)
            (if (eq motivo :header-crc) (incf corruzioni-header)
                (incf corruzioni-corpo)))))
      (loop for limite from inizio below fine do
        (dolist (fisico '(nil t))
          (let ((tronco (if fisico (subseq buffer 0 limite) buffer)))
            (esigi-rifiuto
             (lambda () (verifica-fixture verificatore tronco inizio limite
                                          chiave 17 totale))
             (if (< (- limite inizio) +header-bytes+)
                 :truncated-header :truncated-body))
            (incf troncamenti)))))
    (list :header-bit-flips corruzioni-header :body-bit-flips corruzioni-corpo
          :truncations troncamenti)))

;;; REQ: REQ-AFF-002
(defun check-req-aff-002-validi (verificatore)
  "PUT validi: offset, chiavi limite, stamp u64 e corpi di diverse taglie."
  (let ((casi 0))
    (dolist (lunghezza '(1 16 255))
      (dolist (taglia '(0 1 7 8 9 128 2048))
        (dolist (stamp '(0 17 1152921504606846976 18446744073709551615))
          (let ((chiave (ottetti-deterministici lunghezza))
                (valore (ottetti-deterministici taglia)))
            (multiple-value-bind (buffer inizio fine totale)
                (costruisci-record chiave valore stamp :inizio (mod taglia 16))
              (multiple-value-bind (valore-inizio termine letto)
                  (verifica-fixture verificatore buffer inizio fine chiave stamp totale)
                (esigi (and (= letto stamp) (= termine fine)
                            (= valore-inizio (+ inizio +header-bytes+ lunghezza))
                            (equalp valore (subseq buffer valore-inizio termine)))
                       "REQ-AFF-002: round-trip incompleto.")
                (incf casi)))))))
    casi))

;;; REQ: REQ-FOR-003
(defun check-req-for-003-malformati (verificatore)
  "Campi falsi con CRC validi; l'ordine header/limiti viene verificato."
  (let ((chiave (ottetti-deterministici 8)) (valore (ottetti-deterministici 32))
        (casi 0))
    (multiple-value-bind (buffer inizio fine totale)
        (costruisci-record chiave valore 17 :inizio 3)
      (labels ((rifiuto (dati motivo &optional (limite fine) (max +max-record-bytes+))
                 (incf casi (esigi-rifiuto
                   (lambda () (verifica-fixture verificatore dati inizio limite
                                                chiave 17 totale nil max)) motivo)))
               (campo (offset numero larghezza motivo)
                 (let ((dati (copy-seq buffer)))
                   (scrivi-intero dati (+ inizio offset) numero larghezza)
                   (aggiorna-crc-record dati inizio fine nil)
                   (rifiuto dati motivo))))
        (let ((dati (copy-seq buffer)))
          (scrivi-intero dati (+ inizio +offset-value-len+) #xffffffff 4)
          (rifiuto dati :header-crc)
          (aggiorna-crc-record dati inizio fine nil)
          (rifiuto dati :max-record))
        (campo +offset-value-len+ 33 4 :truncated-body)
        (campo +offset-value-len+ 31 4 :entry-length)
        (campo +offset-value-len+ (- +max-record-bytes+ +header-bytes+ 8)
               4 :truncated-body)
        (campo +offset-value-len+ (- (1+ +max-record-bytes+) +header-bytes+ 8)
               4 :max-record)
        (campo +offset-key-len+ 0 1 :entry-length)
        (let ((dati (copy-seq buffer)))
          (setf (aref dati (+ inizio +offset-key-len+)) 0)
          (scrivi-intero dati (+ inizio +offset-value-len+) 40 4)
          (aggiorna-crc-record dati inizio fine nil)
          (rifiuto dati :empty-key))
        (dolist (tipo '(0 2 3 4 5 6 255))
          (campo +offset-tipo+ tipo 1 :not-put))
        (campo +offset-riservato+ 1 1 :reserved)
        (dolist (flag '(2 8 16 32 64 128)) (campo +offset-flag+ flag 1 :flags))
        (campo +offset-flag+ 1 1 :prepared-mismatch)
        (rifiuto buffer :max-record fine (1- totale))
        (rifiuto buffer :max-parameter fine 23)
        (rifiuto buffer :max-parameter fine (1+ +max-record-bytes+))
        (rifiuto buffer :bounds (1+ fine))))
    casi))

(defun esigi-type-error (funzione)
  "Verifica che i controlli del runtime segnalino un errore di tipo o array."
  (handler-case
      (progn (funcall funzione)
             (error 'spike-error :messaggio "Controllo del runtime assente."))
    (type-error () 1)))

;;; REQ: REQ-AFF-003
(defun check-req-aff-003-runtime ()
  "Accessi fuori array nella baseline e argomenti non specializzati nei CRC."
  (let ((buffer (make-array +header-bytes+ :element-type '(unsigned-byte 8)
                                         :initial-element 0))
        (chiave (ottetti-deterministici 1)) (casi 0))
    (scrivi-intero buffer +offset-value-len+ 1 4)
    (dolist (lettura (list #'leggi-libero-safety2 #'leggi-libero-safety3))
      (incf casi (esigi-type-error
        (lambda () (funcall lettura buffer 0 +header-bytes+ chiave 0 +header-bytes+)))))
    (dolist (descrittore (descrittori-crc))
      (incf casi (esigi-type-error
        (lambda () (funcall (third descrittore) (vector 1 2 3) 0 3)))))
    casi))

;;; REQ: REQ-AFF-002
(defun check-req-aff-002-entry (verificatore)
  "Rifiuta chiave/CSN/location errati anche con CRC validi, incluso prepared."
  (let ((chiave (ottetti-deterministici 8)) (valore (ottetti-deterministici 32))
        (casi 0))
    (multiple-value-bind (buffer inizio fine totale)
        (costruisci-record chiave valore 17 :inizio 9)
      (labels ((rifiuto (dati key csn len prepared motivo)
                 (incf casi (esigi-rifiuto
                   (lambda () (verifica-fixture verificatore dati inizio fine
                                                key csn len prepared)) motivo))))
        (let ((diversa (copy-seq chiave)))
          (setf (aref diversa 0) (logxor 1 (aref diversa 0)))
          (rifiuto buffer diversa 17 totale nil :key-mismatch))
        (rifiuto buffer (ottetti-deterministici 7) 17 totale nil :key-mismatch)
        (rifiuto buffer chiave 18 totale nil :csn-mismatch)
        (rifiuto buffer chiave 17 (1- totale) nil :entry-length)
        (rifiuto buffer chiave 17 (1+ totale) nil :entry-length)
        (rifiuto buffer chiave 17 totale t :prepared-mismatch)
        (let ((dati (copy-seq buffer)))
          (setf (aref dati (+ inizio +header-bytes+))
                (logxor 1 (aref dati (+ inizio +header-bytes+))))
          (aggiorna-crc-record dati inizio fine)
          (rifiuto dati chiave 17 totale nil :key-mismatch))
        (let ((dati (copy-seq buffer)))
          (scrivi-intero dati (+ inizio +offset-stamp+) 18 8)
          (aggiorna-crc-record dati inizio fine nil)
          (rifiuto dati chiave 17 totale nil :csn-mismatch))))
    (dolist (flag '(1 4 5))
      (multiple-value-bind (buffer inizio fine totale)
          (costruisci-record chiave valore 999 :flag flag)
        (let ((prepared (logbitp 0 flag)))
          (verifica-fixture verificatore buffer inizio fine chiave
                            (if prepared 17 999) totale prepared)
          (incf casi)
          (when prepared
            (incf casi (esigi-rifiuto
              (lambda () (verifica-fixture verificatore buffer inizio fine
                                           chiave 17 totale nil))
              :prepared-mismatch))))))
    casi))

;;; REQ: REQ-AFF-003
(defun check-req-aff-003-limiti ()
  "Rifiuti deterministici per intervalli CRC e accessi fuori array."
  (let ((buffer (ottetti-deterministici 16)) (casi 0))
    (dolist (descrittore (descrittori-crc))
      (dolist (intervallo '((-1 0) (3 2) (0 17) (17 17)))
        (handler-case
            (progn (funcall (third descrittore) buffer
                            (first intervallo) (second intervallo))
                   (error 'simple-error :format-control "Intervallo accettato."))
          (spike-error () (incf casi)))))
    (dolist (verificatore (list #'verifier-record-safety2 #'verifier-record-safety3))
      (dolist (intervallo '((-1 16) (2 1) (0 17)))
        (incf casi (esigi-rifiuto
          (lambda () (verifica-fixture verificatore buffer
                       (first intervallo) (second intervallo) buffer 0 0)) :bounds))))
    casi))

(defun check-calcolo-letture ()
  "Le baseline e le letture verificate producono lo stesso lavoro osservabile."
  (let ((casi 0) (chiave (ottetti-deterministici 16)))
    (dolist (taglia '(20 128 2048 16384))
      (dolist (stamp '(17 18446744073709551615))
        (multiple-value-bind (buffer inizio fine totale)
            (costruisci-record chiave (ottetti-deterministici (- taglia 16)) stamp
                              :inizio 7)
          (let ((atteso (leggi-libero-safety3 buffer inizio fine chiave stamp totale)))
            (dolist (funzione (list #'leggi-libero-safety2 #'leggi-verificato-safety2
                                   #'leggi-verificato-safety3))
              (esigi (= atteso (funcall funzione buffer inizio fine chiave stamp totale))
                     "Letture con risultato diverso.")
              (incf casi))))))
    casi))

;;; REQ: REQ-AFF-002
(defun check-req-aff-002-limite-prepared ()
  "Documenta il limite ADR-0039: la entry non lega un prepared al suo TXID."
  (let ((chiave (ottetti-deterministici 8)) (casi 0))
    (dolist (verificatore (list #'verifier-record-safety2 #'verifier-record-safety3))
      (dolist (txid '(101 202))
        (multiple-value-bind (buffer inizio fine totale)
            (costruisci-record chiave (ottetti-deterministici 32 txid) txid :flag 1)
          (multiple-value-bind (valore termine stamp)
              (verifica-fixture verificatore buffer inizio fine chiave 17 totale t)
            (esigi (and (= stamp txid) (= termine fine) (= valore 32))
                   "Comportamento prepared diverso da ADR-0039.")
            (incf casi)))))
    (list :prepared-location-rebinding :not-detected-by-envelope-only-parsing
          :accepted-fixtures casi :expected-entry-csn 17 :fixture-txids '(101 202))))

;;; REQ: REQ-FOR-004
(defun check-req-for-004-outcome-validi ()
  "Prepared con prove OUTCOME distinte, disallineate e con CSN/TXID a 64 bit."
  (let ((chiave (ottetti-deterministici 8)) (casi 0))
    (dolist (csn '(17 18446744073709551615))
      (dolist (txid '(101 18446744073709551615))
        (multiple-value-bind (buffer inizio fine totale)
            (costruisci-record chiave (ottetti-deterministici 32) txid
                              :inizio 3 :flag 1)
          (multiple-value-bind (prova origine termine)
              (costruisci-outcome txid csn :inizio 7)
            (multiple-value-bind (valore record-fine risolto letto)
                (verify-prepared-record buffer inizio fine chiave csn totale prova
                                        :outcome-start origine :outcome-end termine)
              (esigi (and (= valore (+ inizio 32)) (= record-fine fine)
                          (= risolto csn) (= letto txid))
                     "Risoluzione OUTCOME non corretta.")
              (incf casi))))))
    casi))

;;; REQ: REQ-FOR-003
;;; REQ: REQ-FOR-004
(defun check-req-for-004-outcome-alterazioni ()
  "Altera ogni bit della prova e verifica troncamenti fisici e logici."
  (let ((chiave (ottetti-deterministici 8)) (bit-flips 0) (troncamenti 0))
    (multiple-value-bind (buffer inizio fine totale)
        (costruisci-record chiave (ottetti-deterministici 32) 101 :flag 1)
      (multiple-value-bind (prova origine termine)
          (costruisci-outcome 101 17 :inizio 7)
        (loop for posizione from origine below termine do
          (dotimes (bit 8)
            (let ((dati (copy-seq prova)))
              (setf (aref dati posizione) (logxor (aref dati posizione) (ash 1 bit)))
              (incf bit-flips (esigi-rifiuto
                (lambda () (verify-prepared-record buffer inizio fine chiave 17 totale
                              dati :outcome-start origine :outcome-end termine))
                (if (< posizione (+ origine +header-bytes+))
                    :outcome-header-crc :outcome-body-crc))))))
        (loop for limite from origine below termine do
          (dolist (fisico '(nil t))
            (let ((dati (if fisico (subseq prova 0 limite) prova)))
              (incf troncamenti (esigi-rifiuto
                (lambda () (verify-prepared-record buffer inizio fine chiave 17 totale
                              dati :outcome-start origine :outcome-end limite))
                (if (< (- limite origine) +header-bytes+)
                    :outcome-truncated-header :outcome-truncated-body))))))))
    (list :bit-flips bit-flips :truncations troncamenti)))

;;; REQ: REQ-FOR-004
(defun check-req-for-004-outcome-rifiuti ()
  "Rifiuta prove assenti, campi malformati e risoluzioni di altro TXID o CSN."
  (let ((chiave (ottetti-deterministici 8)) (casi 0))
    (multiple-value-bind (buffer inizio fine totale)
        (costruisci-record chiave (ottetti-deterministici 32) 101 :flag 1)
      (multiple-value-bind (prova origine termine) (costruisci-outcome 101 17)
        (labels ((rifiuto (dati motivo &optional (record buffer) (start origine) (end termine))
                   (incf casi (esigi-rifiuto
                     (lambda () (verify-prepared-record record inizio fine chiave 17 totale
                                   dati :outcome-start start :outcome-end end)) motivo)))
                 (campo (offset numero larghezza motivo)
                   (let ((dati (copy-seq prova)))
                     (scrivi-intero dati offset numero larghezza)
                     (aggiorna-crc-record dati 0 termine)
                     (rifiuto dati motivo))))
          (rifiuto nil :missing-outcome)
          (rifiuto (make-array 0 :element-type '(unsigned-byte 8))
                   :outcome-truncated-header buffer 0 0)
          (rifiuto prova :outcome-bounds buffer -1 termine)
          (rifiuto prova :outcome-bounds buffer 0 (1+ termine))
          (let ((dati (copy-seq prova)))
            (scrivi-intero dati +offset-value-len+ #xffffffff 4)
            (rifiuto dati :outcome-header-crc)
            (aggiorna-crc-record dati 0 termine nil)
            (rifiuto dati :outcome-max-record))
          (campo +offset-value-len+ 7 4 :outcome-length)
          (campo +offset-value-len+ 9 4 :outcome-truncated-body)
          (let ((dati (copy-seq prova)))
            (setf (aref dati +offset-key-len+) 1)
            (scrivi-intero dati +offset-value-len+ 7 4)
            (aggiorna-crc-record dati 0 termine)
            (rifiuto dati :outcome-length))
          (dolist (tipo '(0 1 2 3 5 6 255)) (campo +offset-tipo+ tipo 1 :not-outcome))
          (dolist (flag '(1 2 4 8 16 32 64 128))
            (campo +offset-flag+ flag 1 :outcome-flags-reserved))
          (campo +offset-riservato+ 1 1 :outcome-flags-reserved)
          (campo +offset-stamp+ 102 8 :outcome-txid-mismatch)
          (campo +header-bytes+ 18 8 :outcome-csn-mismatch)
          (multiple-value-bind (diverso d-inizio d-fine d-totale)
              (costruisci-record chiave (ottetti-deterministici 32 202) 202 :flag 1)
            (esigi (and (= d-inizio inizio) (= d-fine fine) (= d-totale totale))
                   "Fixture di location differenti non confrontabili.")
            (rifiuto prova :outcome-txid-mismatch diverso)
            (rifiuto (costruisci-outcome 202 53) :outcome-csn-mismatch diverso)))))
    casi))

(defun check ()
  "Verifica deterministica rapida; restituisce una plist, nessuna misura temporale."
  (let ((crc (check-req-for-001-crc)) (record '()))
    (loop for verificatore in (list #'verifier-record-safety2 #'verifier-record-safety3)
          for sicurezza in '(2 3) do
      (push (list :safety sicurezza
                  :valid (check-req-aff-002-validi verificatore)
                  :corruption (check-req-for-003-alterazioni verificatore)
                  :malformed (check-req-for-003-malformati verificatore)
                  :entry (check-req-aff-002-entry verificatore)) record))
    (list :spike :spk-09 :status :ok :seed #x09c0ffee :crc crc
          :records (nreverse record) :bounds (check-req-aff-003-limiti)
          :runtime-checks (check-req-aff-003-runtime)
          :read-equivalence (check-calcolo-letture)
          :format-limitations (check-req-aff-002-limite-prepared)
          :prepared-proof (list :valid (check-req-for-004-outcome-validi)
                                :corruption (check-req-for-004-outcome-alterazioni)
                                :rejections (check-req-for-004-outcome-rifiuti)))))

;;; REQ: REQ-BEN-001
;;; REQ: REQ-BEN-002
(defun ambiente ()
  "Registra il runtime effettivo senza dedurre il modello hardware da stime."
  (list :lisp (lisp-implementation-type) :version (lisp-implementation-version)
        :machine-type (machine-type) :machine-version (machine-version)
        :software-type (software-type) :software-version (software-version)
        :most-positive-fixnum most-positive-fixnum
        :internal-time-units-per-second internal-time-units-per-second
        :clock :get-internal-real-time :allocation-counter :sb-ext-get-bytes-consed
        :features (intersection '(:sbcl :64-bit :32-bit :arm64 :x86-64 :sb-thread)
                                *features*)))

(defun seconds-tra (inizio fine)
  "Converte i tick del clock monotono del runtime in secondi double-float."
  (/ (coerce (- fine inizio) 'double-float)
     (coerce internal-time-units-per-second 'double-float)))

(defun scalda (funzione iterazioni atteso)
  "Warmup limitato, separato dalla misura, con controllo del risultato."
  (dotimes (i iterazioni)
    (esigi (= (funcall funzione) atteso) "Warmup con risultato inatteso.")))

(defun misura-finestra (funzione secondi bytes-per-op atteso)
  "Misura lotti di 16 chiamate, al più 2 milioni di operazioni per finestra."
  (declare (type function funzione) (type double-float secondi)
           (type (integer 1 65560) bytes-per-op) (type u32 atteso))
  (let ((tick-target (max 1 (ceiling (* secondi internal-time-units-per-second))))
        (inizio (get-internal-real-time))
        (consed-inizio (sb-ext:get-bytes-consed))
        (operazioni 0) (sink 0) (ultimo 0) (fine 0) (consed-fine 0))
    (declare (type u32 sink ultimo) (type fixnum operazioni))
    (loop repeat 125000 do
      (dotimes (i 16)
        (setf ultimo (funcall funzione)
              sink (logand +maschera-crc+ (+ sink ultimo)))
        (incf operazioni))
      (when (>= (- (get-internal-real-time) inizio) tick-target)
        (return)))
    (setf consed-fine (sb-ext:get-bytes-consed)
          fine (get-internal-real-time))
    (esigi (= ultimo atteso) "Risultato del benchmark diverso dalla fixture.")
    (let ((durata (seconds-tra inizio fine))
          (consed (- consed-fine consed-inizio)))
      (list :operations operazioni :seconds durata
            :ns/op (when (plusp durata) (/ (* durata 1d9) operazioni))
            :bytes/s (when (plusp durata) (/ (* operazioni bytes-per-op) durata))
            :bytes-consed consed :bytes-consed/op (/ (coerce consed 'double-float)
                                                   operazioni)
            :clock-resolution-limited (zerop durata)
            :operation-cap-reached (= operazioni 2000000)
            :sink sink :last-result ultimo))))

(defun misura-crc (taglia secondi warmup)
  "Misura ogni kernel sulla stessa fixture, setup e riferimento fuori misura."
  (let* ((buffer (ottetti-deterministici (+ taglia 7)))
         (atteso (crc32c-reference buffer 7 (+ 7 taglia))) (risultati '()))
    (dolist (descrittore (descrittori-crc))
      (destructuring-bind (nome sicurezza kernel) descrittore
        (let ((funzione (lambda () (funcall kernel buffer 7 (+ 7 taglia)))))
          (scalda funzione warmup atteso)
          (push (append (list :kind :crc :kernel nome :safety sicurezza
                              :bytes taglia :alignment 7)
                        (misura-finestra funzione secondi taglia atteso)) risultati))))
    (nreverse risultati)))

(defun descrittori-letture ()
  "Elenca baseline e letture verificate per entrambe le policy."
  (list (list :unchecked 2 #'leggi-libero-safety2)
        (list :verified 2 #'leggi-verificato-safety2)
        (list :unchecked 3 #'leggi-libero-safety3)
        (list :verified 3 #'leggi-verificato-safety3)))

(defun misura-letture (taglia stamp secondi warmup)
  "Misura le medesime letture, con stamp piccolo o potenzialmente bignum."
  (let ((chiave (ottetti-deterministici 16)) (risultati '()))
    (multiple-value-bind (buffer inizio fine totale)
        (costruisci-record chiave (ottetti-deterministici (- taglia 16)) stamp
                          :inizio 7)
      (let ((atteso (leggi-libero-safety3 buffer inizio fine chiave stamp totale)))
        (dolist (descrittore (descrittori-letture))
          (destructuring-bind (nome sicurezza lettura) descrittore
            (let ((funzione (lambda ()
                              (funcall lettura buffer inizio fine chiave stamp totale))))
              (scalda funzione warmup atteso)
              (push (append (list :kind :read :mode nome :safety sicurezza
                                  :body-bytes taglia :record-bytes totale :alignment 7
                                  :stamp stamp :stamp-is-fixnum (typep stamp 'fixnum))
                            (misura-finestra funzione secondi totale atteso))
                    risultati))))))
    (nreverse risultati)))

(defun rapporto-costo (verificato base)
  "Rapporto sul costo temporale medio; NIL se la risoluzione non basta."
  (let ((a (getf verificato :ns/op)) (b (getf base :ns/op)))
    (when (and a b (plusp b)) (- (* 100d0 (/ a b)) 100d0))))

(defun confronti-letture (misure)
  "Calcola l'overhead percentuale solo dalle misure raccolte nella stessa run."
  (let ((risultati '()))
    (dolist (verificato misure)
      (when (eq (getf verificato :mode) :verified)
        (let ((base (find-if
                     (lambda (r)
                       (and (eq (getf r :mode) :unchecked)
                            (= (getf r :safety) (getf verificato :safety))
                            (= (getf r :body-bytes) (getf verificato :body-bytes))
                            (= (getf r :stamp) (getf verificato :stamp)))) misure)))
          (esigi base "Baseline di lettura mancante.")
          (push (list :body-bytes (getf verificato :body-bytes)
                      :stamp (getf verificato :stamp) :safety (getf verificato :safety)
                      :verification-overhead-percent (rapporto-costo verificato base))
                risultati))))
    (nreverse risultati)))

(defun confronti-safety (misure)
  "Confronta safety 3 con safety 2 a parità di kernel, dati e lavoro svolto."
  (let ((risultati '()))
    (dolist (misura misure)
      (when (= (getf misura :safety) 3)
        (let ((base (find-if
                     (lambda (r)
                       (and (= (getf r :safety) 2)
                            (eq (getf r :kind) (getf misura :kind))
                            (eq (getf r :kernel) (getf misura :kernel))
                            (eq (getf r :mode) (getf misura :mode))
                            (eql (getf r :bytes) (getf misura :bytes))
                            (eql (getf r :body-bytes) (getf misura :body-bytes))
                            (eql (getf r :stamp) (getf misura :stamp)))) misure)))
          (when base
            (push (list :kind (getf misura :kind) :kernel (getf misura :kernel)
                        :mode (getf misura :mode)
                        :bytes (or (getf misura :bytes) (getf misura :body-bytes))
                        :stamp (getf misura :stamp)
                        :safety3-over-safety2-percent (rapporto-costo misura base))
                  risultati)))))
    (nreverse risultati)))

(defun parametri-benchmark (secondi taglie warmup)
  "Limita budget, numero di fixture, taglie e warmup prima di allocare."
  (esigi (and (realp secondi) (<= 0.01d0 secondi 10d0))
         "Budget :seconds richiesto tra 0.01 e 10 secondi.")
  (esigi (and (listp taglie) (<= 1 (length taglie) 8)
              (every (lambda (n) (and (integerp n) (<= 20 n 65536))) taglie)
              (= (length taglie) (length (remove-duplicates taglie))))
         "Richieste 1..8 taglie distinte, ciascuna tra 20 e 65536 byte.")
  (esigi (and (integerp warmup) (<= 1 warmup 32))
         "Warmup richiesto tra 1 e 32 iterazioni.")
  t)

(defun benchmark (&key (seconds 6d0) (sizes '(20 128 2048 16384))
                      (warmup-iterations 8))
  "Check, warmup e misure con budget complessivo; risultato plist riproducibile."
  (parametri-benchmark seconds sizes warmup-iterations)
  (let* ((inizio (get-internal-real-time)) (verifica (check))
         (secondi-finestra (/ (coerce seconds 'double-float) (* 13 (length sizes))))
         (crc '()) (letture '()))
    (dolist (taglia sizes)
      (setf crc (nconc crc (misura-crc taglia secondi-finestra warmup-iterations)))
      (dolist (stamp '(17 18446744073709551615))
        (setf letture (nconc letture (misura-letture taglia stamp secondi-finestra
                                                    warmup-iterations)))))
    (list :spike :spk-09 :status :ok :check verifica :environment (ambiente)
          :parameters (list :seconds seconds :sizes sizes :warmup warmup-iterations
                            :seconds-per-window secondi-finestra :batch-operations 16
                            :max-operations-per-window 2000000
                            :table-bytes (* 8 256 4) :seed #x09c0ffee)
          :crc crc :reads letture :comparisons (confronti-letture letture)
          :safety-comparisons (confronti-safety (append crc letture))
          :elapsed-seconds (seconds-tra inizio (get-internal-real-time)))))
