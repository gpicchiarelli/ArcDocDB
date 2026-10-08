;;;; SPK-03: esperimento di Fase 0, soltanto SBCL e contrib.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :sb-posix))

(defpackage #:arcdocdb.spk03
  (:use #:cl)
  (:export #:check #:benchmark))
(in-package #:arcdocdb.spk03)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-016 REQ-WAL-002 REQ-AFF-001
(defconstant +fullfsync+ 51)
;; ENOTSUP = 45 in sys/errno.h Apple; EOPNOTSUPP con UNIX03 può essere 102.
#+darwin (defconstant +enotsup-darwin+ 45)
(defconstant +limite-eintr+ 16)
(defconstant +limite-memoria+ (* 256 1024 1024))
(deftype octet () '(simple-array (unsigned-byte 8) (*)))

;;; OWNER: percorso immutabile dopo il caricamento; nessun contatore globale.
(defparameter *directory-dati*
  (let* ((source (or *load-truename* *compile-file-truename*
                     (error "Percorso dello spike non disponibile.")))
         (directory (make-pathname :name nil :type nil :defaults source)))
    (merge-pathnames
     (if (equal (car (last (pathname-directory directory))) "out")
         "data/" "out/data/")
     directory)))

(define-condition errore-io (error)
  ((operation :initarg :operation :reader operazione-io)
   (errno :initarg :errno :initform nil :reader errno-io))
  (:report (lambda (condizione flusso)
             (format flusso "SPK-03 ~A: errno ~S."
                     (operazione-io condizione) (errno-io condizione)))))
(define-condition flush-non-supportato (errore-io) ())
(define-condition errore-verifica (error)
  ((percorso :initarg :percorso :reader percorso-verifica)
   (regola :initarg :regola :reader regola-verifica)
   (record :initarg :record :initform nil :reader record-verifica)
   (posizione :initarg :posizione :initform nil :reader posizione-verifica))
  (:report (lambda (condizione flusso)
             (format flusso "Verifica ~A fallita in ~A, record ~S, posizione ~S."
                     (regola-verifica condizione) (percorso-verifica condizione)
                     (record-verifica condizione) (posizione-verifica condizione)))))

;;; REQ: REQ-AFF-016 REQ-WAL-002
;; ABI POSIX 64 bits : ssize_t = long, size_t = unsigned long.
(declaim (inline %write))
(sb-alien:define-alien-routine ("write" %write) sb-alien:long
  (fd sb-alien:int) (buffer sb-alien:system-area-pointer)
  (numero sb-alien:unsigned-long))

(defun chiamata-write (fd indirizzo numero)
  "Restituisce progresso ed errno immediatamente dopo la syscall."
  (let ((ritorno (%write fd indirizzo numero)))
    (values ritorno (if (= ritorno -1) (sb-alien:get-errno) 0))))

;;; REQ: REQ-WAL-002 REQ-AFF-001
(defun scrivere-tutto (fd buffer inizio fine &key (chiamata #'chiamata-write))
  "Completa un'append; ripete solo EINTR, nessun puntatore fuori dal pinning."
  (declare (type octet buffer) (type fixnum inizio fine))
  (unless (<= 0 inizio fine (length buffer))
    (error "Limiti write non validi: ~S ~S." inizio fine))
  (let ((position inizio) (interruzioni 0) (chiamate 0))
    (sb-sys:with-pinned-objects (buffer)
      ;; Al massimo FINE-INIZIO progressioni e 16 EINTR per progressione.
      (loop repeat (* (1+ +limite-eintr+) (max 1 (- fine inizio)))
            until (= position fine)
            do (multiple-value-bind (numero errno)
                   (funcall chiamata fd
                            (sb-sys:sap+ (sb-sys:vector-sap buffer) position)
                            (- fine position))
                 (incf chiamate)
                 (cond
                   ((and (= numero -1) (= errno sb-posix:eintr))
                    (incf interruzioni)
                    (when (> interruzioni +limite-eintr+)
                      (error 'errore-io :operation :write-eintr-limit
                                       :errno errno)))
                   ((= numero -1)
                    (error 'errore-io :operation :write :errno errno))
                   ((<= 1 numero (- fine position))
                    (incf position numero)
                    (setf interruzioni 0))
                   (t (error 'errore-io :operation :write-no-progress))))))
    (unless (= position fine)
      (error 'errore-io :operation :write-incomplete))
    chiamate))

(defun primitiva-richiesta ()
  "Primitiva richiesta da ADR-0017; il comportamento hardware resta da verificare."
  #+darwin :fullfsync
  #+linux :fdatasync
  #-(or darwin linux) :unsupported)

(defun primitive-default ()
  (list :fsync (primitiva-richiesta)))

(defun primitiva-disponibile-p (primitive)
  (case primitive
    (:fsync t)
    (:fullfsync #+darwin t #-darwin nil)
    (:fdatasync #+linux t #-linux nil)
    (otherwise nil)))

(defun chiamata-flush (fd primitive)
  "Una sola syscall, senza retry o fallback."
  (case primitive
    (:fsync (sb-posix:fsync fd))
    (:fullfsync #+darwin (sb-posix:fcntl fd +fullfsync+)
                #-darwin (error 'flush-non-supportato :operation primitive))
    (:fdatasync #+linux (sb-posix:fdatasync fd)
                #-linux (error 'flush-non-supportato :operation primitive))
    (otherwise (error 'flush-non-supportato :operation primitive))))

;;; REQ: REQ-WAL-003 REQ-AFF-001
(defun sincronizzare (fd primitive &key (chiamata #'chiamata-flush))
  "Errore esplicito anche su EINTR; nessun tentativo con un'altra primitiva."
  (handler-case
      (let ((ritorno (funcall chiamata fd primitive)))
        (unless (eql ritorno 0)
          (error 'errore-io :operation :flush-invalid-return))
        ritorno)
    (sb-posix:syscall-error (condizione)
      (let ((errno (sb-posix:syscall-errno condizione)))
        (if (and (member primitive '(:fullfsync :fdatasync))
                 (or (member errno (list sb-posix:einval sb-posix:eopnotsupp
                                        sb-posix:enosys))
                     #+darwin (= errno +enotsup-darwin+)))
            (error 'flush-non-supportato :operation primitive :errno errno)
            (error condizione))))))

(defun con-descrittore (fd funzione)
  "Confine di risorsa: chiude una volta e conserva gli errori."
  (let ((risultato nil) (incidente nil) (chiusura nil))
    (unwind-protect
         (handler-case (setf risultato (funcall funzione fd))
           (error (condizione) (setf incidente condizione)))
      (handler-case (sb-posix:close fd)
        (sb-posix:syscall-error (condizione) (setf chiusura condizione))))
    (when chiusura
      (error "Chiusura fallita: ~A; errore precedente: ~A."
             chiusura incidente))
    (when incidente (error incidente))
    risultato))

;;; REQ: REQ-WAL-002
(declaim (inline octet-atteso)
         (ftype (function (fixnum fixnum fixnum) (unsigned-byte 8)) octet-atteso))
(defun octet-atteso (serie record position)
  "Due identificativi u64 LE e un motivo dipendente da file, record e posizione."
  (cond
    ((< position 8) (ldb (byte 8 (* 8 position)) serie))
    ((< position 16) (ldb (byte 8 (* 8 (- position 8))) record))
    (t (logand 255 (logxor (* 17 serie) (* 29 record) (* 37 position)
                           (ash record -8) (ash position -8))))))

(defun preparare-buffer (serie numero-record octet-record)
  "Prepara il caso prima della misura, senza generazione nell'intervallo I/O."
  (declare (type fixnum serie numero-record octet-record))
  (let ((buffer (make-array (* numero-record octet-record)
                            :element-type '(unsigned-byte 8))))
    (dotimes (record numero-record)
      (dotimes (position octet-record)
        (setf (aref buffer (+ (* record octet-record) position))
              (octet-atteso serie record position))))
    buffer))

(defun verificare-file (percorso serie numero-record octet-record)
  "Riapre dopo close; verifica lunghezza, record e tutti gli octet."
  (declare (type fixnum serie numero-record octet-record))
  (with-open-file (flusso percorso :direction :input
                              :element-type '(unsigned-byte 8))
    (let ((atteso (* numero-record octet-record))
          (buffer (make-array octet-record :element-type '(unsigned-byte 8))))
      (unless (= (file-length flusso) atteso)
        (error 'errore-verifica :percorso percorso :regola :length))
      (dotimes (record numero-record)
        (unless (= (read-sequence buffer flusso) octet-record)
          (error 'errore-verifica :percorso percorso :regola :short-record
                                 :record record))
        (dotimes (position octet-record)
          (unless (= (aref buffer position)
                     (octet-atteso serie record position))
            (error 'errore-verifica :percorso percorso :regola :payload
                                   :record record :posizione position))))
      (unless (eq (read-byte flusso nil :fin) :fin)
        (error 'errore-verifica :percorso percorso :regola :extra-bytes))
      atteso)))

;;; REQ: REQ-CON-003 REQ-CON-005 REQ-WAL-001 REQ-WAL-002
;;; OWNER: un worker scrive ogni struttura; il parent legge dopo join.
(defstruct lavoro
  (serie 0 :type fixnum :read-only t)
  (percorso #p"" :type pathname :read-only t)
  (buffer (make-array 0 :element-type '(unsigned-byte 8))
          :type octet :read-only t)
  (tempi-write #() :type vector :read-only t)
  (tempi-flush #() :type vector :read-only t)
  (creato-p nil :type boolean)
  (numero 0 :type fixnum)
  (chiamate 0 :type fixnum)
  (inizio 0 :type integer)
  (fine 0 :type integer)
  (incidente nil :type (or null condition)))

(defun nuova-directory ()
  "mkdtemp crea una directory esclusiva sotto out/data."
  (ensure-directories-exist (merge-pathnames "placeholder" *directory-dati*))
  (sb-ext:parse-native-namestring
   (sb-posix:mkdtemp
    (sb-ext:native-namestring
     (merge-pathnames "spk03-XXXXXX" *directory-dati*)))
   nil *default-pathname-defaults* :as-directory t))

(defun nuovi-lavori (directory file lotto campioni octet-record)
  (loop for serie below file
        collect (make-lavoro
                 :serie serie
                 :percorso (merge-pathnames (format nil "serie-~D.tmp" serie) directory)
                 :buffer (preparare-buffer serie (* lotto (1+ campioni)) octet-record)
                 :tempi-write (make-array campioni :element-type 'integer
                                          :initial-element 0)
                 :tempi-flush (make-array campioni :element-type 'integer
                                          :initial-element 0))))

;;; REQ: REQ-WAL-002 REQ-AFF-001
(defun misurare-append-flush (lavoro fd primitive lotto octet-record
                           campioni scadenza)
  "Append completa poi flush; conta soltanto i flush riusciti dopo il warmup."
  (let ((octet-lotto (* lotto octet-record)))
    (setf (lavoro-inizio lavoro) (get-internal-real-time))
    (dotimes (campione campioni)
      (when (>= (get-internal-real-time) scadenza) (return))
      (let* ((inizio (* (1+ campione) octet-lotto))
             (prima-write (get-internal-real-time))
             (chiamate (scrivere-tutto fd (lavoro-buffer lavoro)
                                    inizio (+ inizio octet-lotto)))
             (prima-flush (get-internal-real-time)))
        (sincronizzare fd primitive)
        (let ((dopo-flush (get-internal-real-time)))
          (setf (aref (lavoro-tempi-write lavoro) campione)
                (- prima-flush prima-write)
                (aref (lavoro-tempi-flush lavoro) campione)
                (- dopo-flush prima-flush))
          (incf (lavoro-chiamate lavoro) chiamate)
          (incf (lavoro-numero lavoro)))))
    (setf (lavoro-fine lavoro) (get-internal-real-time))))

(defun eseguire-worker (lavoro primitive lotto octet-record campioni
                        scadenza pronto partenza)
  "Confine del worker: cattura l'errore, close prima del ritorno, parent informato."
  (let ((segnalato-p nil))
    (unwind-protect
         (handler-case
             (con-descrittore
              (sb-posix:open (lavoro-percorso lavoro)
                             (logior sb-posix:o-wronly sb-posix:o-creat
                                     sb-posix:o-excl sb-posix:o-append) #o600)
              (lambda (fd)
                (setf (lavoro-creato-p lavoro) t)
                ;; Un lotto di warmup non misurato sullo stesso file.
                (scrivere-tutto fd (lavoro-buffer lavoro) 0 (* lotto octet-record))
                (sincronizzare fd primitive)
                (setf segnalato-p t)
                (sb-thread:signal-semaphore pronto)
                (unless (sb-thread:wait-on-semaphore partenza :timeout 30)
                  (error "Tempo massimo di avvio superato."))
                (misurare-append-flush lavoro fd primitive lotto octet-record
                                     campioni scadenza)))
           (error (condizione) (setf (lavoro-incidente lavoro) condizione)))
      (unless segnalato-p (sb-thread:signal-semaphore pronto)))))

(defun avviare-worker (lavori primitive lotto octet-record campioni scadenza)
  "Porta comune una volta per caso; nessun lock per append o flush."
  (let ((pronto (sb-thread:make-semaphore :count 0))
        (partenza (sb-thread:make-semaphore :count 0))
        (threads nil))
    (unwind-protect
         (progn
           (dolist (lavoro lavori)
             (let ((proprietario lavoro))
               (push (sb-thread:make-thread
                      (lambda ()
                        (eseguire-worker proprietario primitive lotto octet-record
                                         campioni scadenza pronto partenza))
                      :name (format nil "spk03-serie-~D" (lavoro-serie lavoro)))
                     threads)))
           (dotimes (i (length threads))
             (unless (sb-thread:wait-on-semaphore pronto :timeout 30)
               (error "Tempo massimo di preparazione dei worker superato."))))
      ;; Anche se l'avvio fallisce, rilasciare e fare join prima della pulizia.
      (sb-thread:signal-semaphore partenza (length threads))
      (dolist (thread threads) (sb-thread:join-thread thread)))))

(defun pulire-file (lavoro)
  "Un lavoro senza creazione esclusiva riuscita non può eliminare il file."
  (when (lavoro-creato-p lavoro)
    (sb-posix:unlink (lavoro-percorso lavoro))))

(defun pulire (lavori directory)
  "Elimina solo i nomi creati con O_EXCL, poi la directory creata."
  (dolist (lavoro lavori)
    (pulire-file lavoro))
  (sb-posix:rmdir directory))

(defun secondi (ticks)
  (/ ticks (float internal-time-units-per-second 1d0)))

(defun distribution (tempi)
  "Percentili per rango superiore; NIL con zero osservazioni."
  (when tempi
    (let* ((ordinati (sort (coerce tempi 'vector) #'<))
           (numero (length ordinati)))
      (flet ((quantile (frazione)
               (secondi (aref ordinati (1- (ceiling (* frazione numero)))))))
        (list :samples numero :min-seconds (secondi (aref ordinati 0))
              :median-seconds (quantile 1/2) :p95-seconds (quantile 95/100)
              :p99-seconds (quantile 99/100)
              :max-seconds (secondi (aref ordinati (1- numero))))))))

(defun risultato-worker (lavoro lotto octet-record)
  (let ((numero (lavoro-numero lavoro)))
    (list :file (lavoro-serie lavoro) :completed-flushes numero
          :warmup-flushes 1 :warmup-records lotto
          :records (* lotto numero) :verified-bytes (* lotto (1+ numero) octet-record)
          :write-syscalls (lavoro-chiamate lavoro)
          :io-seconds (secondi (- (lavoro-fine lavoro) (lavoro-inizio lavoro)))
          :write-seconds (map 'list #'secondi
                              (subseq (lavoro-tempi-write lavoro) 0 numero))
          :flush-seconds (map 'list #'secondi
                              (subseq (lavoro-tempi-flush lavoro) 0 numero)))))

(defun riepilogare (lavori primitive lotto octet-record campioni)
  (let* ((numero (reduce #'+ lavori :key #'lavoro-numero :initial-value 0))
         (records (* lotto numero))
         (octet (* records octet-record))
         (ticks (- (reduce #'max lavori :key #'lavoro-fine)
                   (reduce #'min lavori :key #'lavoro-inizio)))
         (durata (secondi ticks))
         (flush (loop for lavoro in lavori append
                      (coerce (subseq (lavoro-tempi-flush lavoro) 0
                                      (lavoro-numero lavoro)) 'list)))
         (write (loop for lavoro in lavori append
                      (coerce (subseq (lavoro-tempi-write lavoro) 0
                                      (lavoro-numero lavoro)) 'list))))
    (list :status (if (every (lambda (lavoro)
                              (= (lavoro-numero lavoro) campioni)) lavori)
                      :ok :budget-exhausted)
          :flush primitive :required-primitive (primitiva-richiesta)
          :durable-contract-p (eq primitive (primitiva-richiesta))
          :files (length lavori) :batch-records lotto :record-bytes octet-record
          :requested-samples-per-file campioni :completed-flushes numero
          :records records :warmup-flushes (length lavori)
          :warmup-records (* lotto (length lavori))
          :verified-bytes (+ octet (* lotto (length lavori) octet-record))
          :measured-bytes octet :io-wall-seconds durata
          :synced-records-per-second (when (plusp durata) (/ records durata))
          :durable-records-per-second
          (when (and (eq primitive (primitiva-richiesta)) (plusp durata))
            (/ records durata))
          :bytes-per-second (when (plusp durata) (/ octet durata))
          :write-distribution (distribution write)
          :flush-distribution (distribution flush)
          :workers (mapcar (lambda (lavoro)
                             (risultato-worker lavoro lotto octet-record)) lavori))))

(defun eseguire-caso (file lotto campioni octet-record primitive scadenza)
  "Caso isolato: file per worker, verifica dopo join, pulizia finale."
  (unless (primitiva-disponibile-p primitive)
    (return-from eseguire-caso
      (list :status :unsupported :flush primitive :reason :platform
            :files file :batch-records lotto)))
  (let ((directory (nuova-directory)) (lavori nil)
        (inizio-preparazione (get-internal-real-time))
        (inizio-worker 0) (inizio-verifica 0))
    (unwind-protect
         (progn
           (setf lavori (nuovi-lavori directory file lotto
                                          campioni octet-record))
           (setf inizio-worker (get-internal-real-time))
           (avviare-worker lavori primitive lotto octet-record
                           campioni scadenza)
           (setf inizio-verifica (get-internal-real-time))
           (dolist (lavoro lavori)
             (let ((incidente (lavoro-incidente lavoro)))
               (when (and incidente (not (typep incidente 'flush-non-supportato)))
                 (error incidente))))
           (let ((non-supportato (find-if
                                (lambda (lavoro)
                                  (typep (lavoro-incidente lavoro)
                                         'flush-non-supportato)) lavori)))
             (when non-supportato
               (return-from eseguire-caso
                 (list :status :unsupported :flush primitive :reason :syscall
                       :errno (errno-io (lavoro-incidente non-supportato))
                       :files file :batch-records lotto))))
           (dolist (lavoro lavori)
             (verificare-file (lavoro-percorso lavoro) (lavoro-serie lavoro)
                               (* lotto (1+ (lavoro-numero lavoro))) octet-record))
           (append
            (list :preparation-wall-seconds (secondi (- inizio-worker inizio-preparazione))
                  :workers-wall-seconds (secondi (- inizio-verifica inizio-worker))
                  :verification-wall-seconds
                  (secondi (- (get-internal-real-time) inizio-verifica)))
            (riepilogare lavori primitive lotto octet-record campioni)))
      (pulire lavori directory))))

(defun misurare-caso (file lotto campioni octet-record primitive scadenza)
  "Tempo totale comprendente apertura, warmup, verifica, resoconto e pulizia."
  (let* ((inizio (get-internal-real-time))
         (risultato (eseguire-caso file lotto campioni octet-record primitive scadenza)))
    (append (list :case-wall-seconds (secondi (- (get-internal-real-time) inizio)))
            risultato)))

;;; REQ: REQ-AFF-001
(defun check-req-aff-001-write ()
  "Iniezioni deterministiche: EINTR, short write, zero, EIO e limite EINTR."
  (let ((buffer (make-array 11 :element-type '(unsigned-byte 8)
                           :initial-element 73))
        (script (list (cons -1 sb-posix:eintr) (cons 3 0) (cons 8 0)))
        (positions nil))
    (sb-sys:with-pinned-objects (buffer)
      (let ((base (sb-sys:sap-int (sb-sys:vector-sap buffer))))
        (unless (= 3 (scrivere-tutto
                      -1 buffer 0 11
                      :chiamata (lambda (fd indirizzo restante)
                               (declare (ignore fd))
                               (push (list (- (sb-sys:sap-int indirizzo) base) restante)
                                     positions)
                               (let ((passo (pop script)))
                                 (values (car passo) (cdr passo))))))
          (error "Conteggio chiamate short write errato."))))
    (unless (equal (reverse positions) '((0 11) (0 11) (3 8)))
      (error "Progressione del puntatore errata: ~S." positions))
    (dolist (scenario '(:zero :eio :oversize :eintr-limit))
      (let ((chiamate 0) (rilevato nil))
        (handler-case
            (scrivere-tutto -1 buffer 0 11
                         :chiamata (lambda (fd indirizzo restante)
                                  (declare (ignore fd indirizzo))
                                  (incf chiamate)
                                  (case scenario
                                    (:zero (values 0 0))
                                    (:eio (values -1 sb-posix:eio))
                                    (:oversize (values (1+ restante) 0))
                                    (:eintr-limit (values -1 sb-posix:eintr))
                                    (otherwise (error "Scenario sconosciuto.")))))
          (errore-io () (setf rilevato t)))
        (unless (and rilevato (= chiamate (if (eq scenario :eintr-limit) 17 1)))
          (error "Errore write non rilevato o retry indebito: ~S." scenario))))
    (list :status :ok :short-write-offsets :verified
          :zero :detected :eio :detected :oversize :detected
          :eintr-retry :verified :eintr-limit :detected)))

(defun check-req-aff-001-flush ()
  "Un errore di flush produce esattamente una chiamata, senza fallback."
  (dolist (errno (list sb-posix:eio sb-posix:eintr))
    (let ((chiamate 0) (rilevato nil))
      (handler-case
          (sincronizzare -1 :fsync
                        :chiamata (lambda (fd primitive)
                                 (declare (ignore fd primitive))
                                 (incf chiamate)
                                 (error 'errore-io :operation :flush :errno errno)))
        (errore-io (condizione)
          (setf rilevato (= (errno-io condizione) errno))))
      (unless (and rilevato (= chiamate 1))
        (error "Flush ignorato o ripetuto per errno ~D." errno))))
  (let ((chiamate 0) (rilevato nil))
    (handler-case
        (sincronizzare -1 :fullfsync
                      :chiamata (lambda (fd primitive)
                                  (declare (ignore fd primitive))
                                  (incf chiamate)
                                  (error 'sb-posix:syscall-error :name "fcntl"
                                         :errno sb-posix:einval)))
      (flush-non-supportato (condizione)
        (setf rilevato (= (errno-io condizione) sb-posix:einval))))
    (unless (and rilevato (= chiamate 1))
      (error "Primitiva non supportata non dichiarata correttamente.")))
  (list :status :ok :eio :detected :eintr :detected
        :unsupported :explicit :fallback :none))

;;; REQ: REQ-AFF-001
(defun verificare-descrittore-chiuso (fd)
  "Controlla EBADF senza riaprire file, prima che il descrittore sia riutilizzato."
  (handler-case
      (progn (sb-posix:fcntl fd sb-posix:f-getfd)
             (error "Descrittore ~D ancora aperto." fd))
    (sb-posix:syscall-error (condizione)
      (unless (= (sb-posix:syscall-errno condizione) sb-posix:ebadf)
        (error condizione)))))

(defun check-req-aff-001-close (lavoro)
  "Su un file già proprio, un errore write/flush chiude il descrittore."
  (dolist (operazione '(:write :flush))
    (let ((fd (sb-posix:open (lavoro-percorso lavoro) sb-posix:o-wronly))
          (rilevato nil))
      (handler-case
          (con-descrittore
           fd (lambda (descrittore)
                (case operazione
                  (:write
                   (scrivere-tutto
                    descrittore (lavoro-buffer lavoro) 0 1
                    :chiamata (lambda (fd indirizzo numero)
                                (declare (ignore fd indirizzo numero))
                                (values -1 sb-posix:eio))))
                  (:flush
                   (sincronizzare
                    descrittore :fsync
                    :chiamata (lambda (fd primitive)
                                (declare (ignore fd primitive))
                                (error 'errore-io :operation :flush
                                                 :errno sb-posix:eio))))
                  (otherwise (error "Operazione check non valida.")))))
        (errore-io (condizione)
          (setf rilevato (= (errno-io condizione) sb-posix:eio))))
      (unless rilevato (error "Errore ~S non propagato." operazione))
      (verificare-descrittore-chiuso fd)))
  (list :status :ok :write-error :closed :flush-error :closed))

(defun check-req-aff-001-open (lavoro)
  "L'open esclusiva fallita non abilita pulizia di un file preesistente."
  (let ((altro (make-lavoro :serie 99 :percorso (lavoro-percorso lavoro))))
    (eseguire-worker altro :fsync 1 2048 1 0
                     (sb-thread:make-semaphore) (sb-thread:make-semaphore))
    (unless (and (not (lavoro-creato-p altro))
                 (typep (lavoro-incidente altro) 'sb-posix:syscall-error)
                 (= (sb-posix:syscall-errno (lavoro-incidente altro)) sb-posix:eexist))
      (error "Open esclusiva fallita non propagata."))
    (pulire-file altro)
    (verificare-file (lavoro-percorso lavoro) 0 3 2048)
    (list :status :ok :existing-file :preserved :open-error :eexist)))

(defun check-req-wal-002-corruzione (percorso)
  "Il verificatore deve rilevare lunghezza, identità del file e payload errati."
  (dolist (parametri '((0 2 2048) (1 3 2048)))
    (let ((rilevato nil))
      (handler-case (apply #'verificare-file percorso parametri)
        (errore-verifica () (setf rilevato t)))
      (unless rilevato (error "Incoerenza non rilevata: ~S." parametri))))
  (dolist (offset '(8 16 2048))
    (let* ((record (floor offset 2048))
           (posizione (mod offset 2048))
           (atteso (octet-atteso 0 record posizione))
           (rilevato nil))
      (with-open-file (flusso percorso :direction :io :if-exists :overwrite
                                      :if-does-not-exist :error
                                      :element-type '(unsigned-byte 8))
        (unless (file-position flusso offset) (error "Seek check fallita."))
        (write-byte (logxor 1 atteso) flusso))
      (handler-case (verificare-file percorso 0 3 2048)
        (errore-verifica (condizione)
          (setf rilevato (and (= (record-verifica condizione) record)
                             (= (posizione-verifica condizione) posizione)))))
      (unless rilevato (error "Corruzione non rilevata a ~D." offset))
      (with-open-file (flusso percorso :direction :io :if-exists :overwrite
                                      :if-does-not-exist :error
                                      :element-type '(unsigned-byte 8))
        (unless (file-position flusso offset) (error "Seek ripristino fallita."))
        (write-byte atteso flusso))))
  (verificare-file percorso 0 3 2048)
  (list :status :ok :length :detected :file-id :detected
        :record-id :detected :payload :detected :next-record :detected))

(defun check-req-wal-002-rilettura ()
  "Piccolo file reale: write frammentata dopo EINTR simulato, poi fsync."
  (let* ((directory (nuova-directory))
         (lavoro nil)
         (chiamate 0))
    (unwind-protect
         (progn
           (setf lavoro (first (nuovi-lavori directory 1 3 1 2048)))
           (con-descrittore
            (sb-posix:open (lavoro-percorso lavoro)
                           (logior sb-posix:o-wronly sb-posix:o-creat
                                   sb-posix:o-excl sb-posix:o-append) #o600)
            (lambda (fd)
              (setf (lavoro-creato-p lavoro) t)
              (scrivere-tutto fd (lavoro-buffer lavoro) 0 6144
                           :chiamata (lambda (descrittore indirizzo restante)
                                    (incf chiamate)
                                    (if (= chiamate 1)
                                        (values -1 sb-posix:eintr)
                                        (chiamata-write descrittore indirizzo
                                                     (min restante 113)))))
              (sincronizzare fd :fsync)))
           (verificare-file (lavoro-percorso lavoro) 0 3 2048)
           (list :status :ok :records 3 :verified-bytes 6144
                 :write-syscalls chiamate :forced-short-write-bytes 113
                 :close-check (check-req-aff-001-close lavoro)
                 :open-check (check-req-aff-001-open lavoro)
                 :corruption-check
                 (check-req-wal-002-corruzione (lavoro-percorso lavoro))))
      (pulire (when lavoro (list lavoro)) directory))))

(defun ambiente ()
  (list :implementation (lisp-implementation-type)
        :version (lisp-implementation-version) :machine (machine-type)
        :machine-version (machine-version) :os (software-type)
        :os-version (software-version) :safety 3
        :internal-time-units-per-second internal-time-units-per-second
        :required-flush (primitiva-richiesta)
        :data-directory (namestring *directory-dati*)))

;;; REQ: REQ-WAL-002 REQ-AFF-001 REQ-AFF-016
(defun check ()
  "Verifica rapida deterministica e piccoli file reali; nessuna misura pubblicata."
  (let* ((write (check-req-aff-001-write))
         (flush (check-req-aff-001-flush))
         (rilettura (check-req-wal-002-rilettura))
         (caso (misurare-caso 1 3 2 2048 (primitiva-richiesta)
                           (+ (get-internal-real-time)
                              (* 10 internal-time-units-per-second)))))
    (unless (member (getf caso :status) '(:ok :unsupported))
      (error "Check incompleto: ~S." (getf caso :status)))
    (list :status (getf caso :status) :environment (ambiente)
          :REQ-AFF-001-write write :REQ-AFF-001-flush flush
          :REQ-WAL-002-reopen rilettura
          :required-flush
          (if (eq (getf caso :status) :unsupported) caso
              (list :status (getf caso :status) :primitive (getf caso :flush)
                    :completed-flushes (getf caso :completed-flushes)
                    :records (getf caso :records)
                    :verified-bytes (getf caso :verified-bytes)))
          :powercut-proof nil)))

(defun validare-parametri (file lots campioni octet-record
                          primitive secondi-max)
  "Limiti di lavoro e memoria prima di allocare o aprire file."
  (dolist (lista (list file lots primitive))
    (unless (and (listp lista) (<= 1 (length lista) 8))
      (error "Lista di parametri non valida: ~S." lista)))
  (dolist (numero file)
    (unless (typep numero '(integer 1 64)) (error "Numero di file non valido.")))
  (dolist (numero lots)
    (unless (typep numero '(integer 1 4096)) (error "Lotto non valido.")))
  (unless (typep campioni '(integer 1 4096)) (error "Campioni non validi."))
  (unless (typep octet-record '(integer 16 65536)) (error "Dimensione record non valida."))
  (unless (typep secondi-max '(real (0) 60)) (error "Budget non valido."))
  (dolist (primitive primitive)
    (unless (member primitive '(:fsync :fullfsync :fdatasync :unsupported))
      (error "Primitiva sconosciuta: ~S." primitive)))
  (let ((memoria (+ (* (reduce #'max file) (reduce #'max lots)
                       (1+ campioni) octet-record)
                    (* 64 campioni (reduce #'max file)))))
    (when (> memoria +limite-memoria+)
      (error "Memoria esplicita ~D octet > limite ~D." memoria +limite-memoria+))
    memoria))

;;; REQ: REQ-WAL-002 REQ-CON-003 REQ-CON-005 REQ-AFF-012
(defun benchmark (&key (files '(1 4)) (batches '(1 32 128)) (samples 16)
                       (record-bytes 2048) (flush-modes (primitive-default))
                       (max-seconds 15))
  "Misure limitate: casi successivi e file concorrenti; nessuna prova powercut."
  (let* ((memoria (validare-parametri files batches samples record-bytes
                                    flush-modes max-seconds))
         (verifica (check)))
    (unless (eq (getf verifica :status) :ok)
      (return-from benchmark
        (list :spike "SPK-03" :status (getf verifica :status)
              :check verifica :cases nil)))
    (let* ((inizio (get-internal-real-time))
           (scadenza (+ inizio (ceiling (* max-seconds internal-time-units-per-second))))
           (risultati nil) (previsti (* (length files) (length batches)
                                      (length flush-modes))))
      (block matrice
        (dolist (primitive flush-modes)
          (dolist (file files)
            (dolist (lotto batches)
              (when (>= (get-internal-real-time) scadenza) (return-from matrice))
              (push (misurare-caso file lotto samples record-bytes primitive scadenza)
                    risultati)))))
      (list :spike "SPK-03"
            :status (if (or (< (length risultati) previsti)
                            (find :budget-exhausted risultati
                                  :key (lambda (caso) (getf caso :status))))
                        :budget-exhausted
                        (if (find :unsupported risultati
                                  :key (lambda (caso) (getf caso :status)))
                            :unsupported :ok))
            :environment (ambiente) :check verifica
            :parameters (list :files files :batches batches :samples samples
                              :record-bytes record-bytes :flush-modes flush-modes
                              :max-seconds max-seconds)
            :explicit-memory-bound-bytes memoria
            :matrix-wall-seconds (secondi (- (get-internal-real-time) inizio))
            :expected-cases previsti :executed-cases (length risultati)
            :cases (nreverse risultati) :powercut-proof nil))))
