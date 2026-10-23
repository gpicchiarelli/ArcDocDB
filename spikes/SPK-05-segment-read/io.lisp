;;;; SPK-05: primitive POSIX sperimentali, soltanto SBCL e contrib.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :sb-posix))

(defpackage #:arcdocdb.spk05.io
  (:use #:cl)
  (:export #:apri-lettura #:chiudi #:leggi-esatto #:mappa #:smappa
           #:scrivi-esatto #:crea-esclusivo #:elimina-file #:check #:check-file
           #:errore-io #:regola-io))
(in-package #:arcdocdb.spk05.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defconstant +limite-octet+ (* 256 1024 1024))
(defconstant +limite-offset+ (1- (ash 1 63)))
(defconstant +limite-indirizzo+ (1- (ash 1 64)))
(defconstant +limite-eintr+ 16)

(define-condition errore-io (error)
  ((regola :initarg :regola :reader regola-io)
   (dettaglio :initarg :dettaglio :initform nil :reader dettaglio-io))
  (:report (lambda (condizione flusso)
             (format flusso "SPK-05 I/O: ~S (~S)."
                     (regola-io condizione) (dettaglio-io condizione)))))

;;; REQ: REQ-VAL-001 REQ-AFF-001
;; ABI POSIX 64 bit di SBCL su Darwin/Linux: ssize_t e off_t sono long.
(declaim (inline %pread %write lettura-posizionale scrittura)
         (ftype (function ((integer 0 2147483647) sb-sys:system-area-pointer
                           (integer 0 268435456) (integer 0 9223372036854775807))
                          (signed-byte 64))
                lettura-posizionale)
         (ftype (function ((integer 0 2147483647) sb-sys:system-area-pointer
                           (integer 0 268435456))
                          (signed-byte 64))
                scrittura))
(sb-alien:define-alien-routine ("pread" %pread) sb-alien:long
  (fd sb-alien:int) (buffer sb-alien:system-area-pointer)
  (numero sb-alien:unsigned-long) (offset sb-alien:long))
(sb-alien:define-alien-routine ("write" %write) sb-alien:long
  (fd sb-alien:int) (buffer sb-alien:system-area-pointer)
  (numero sb-alien:unsigned-long))

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun valida-descrittore (fd)
  "Rifiuta un descrittore fuori dal dominio int non negativo prima della syscall."
  (unless (typep fd '(integer 0 2147483647))
    (error 'errore-io :regola :descrittore :dettaglio fd))
  nil)

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun valida-regione (sap octet offset &key (non-vuota nil))
  "Valida aritmetica e limiti; la vita della memoria resta responsabilità del controller."
  (unless (and (typep octet 'integer)
               (<= (if non-vuota 1 0) octet +limite-octet+))
    (error 'errore-io :regola :dimensione :dettaglio octet))
  (unless (and (typep offset 'integer)
               (<= 0 offset +limite-offset+)
               (<= (+ offset octet) +limite-offset+))
    (error 'errore-io :regola :offset :dettaglio offset))
  (unless (typep sap 'sb-sys:system-area-pointer)
    (error 'errore-io :regola :puntatore :dettaglio sap))
  (let ((indirizzo (sb-sys:sap-int sap)))
    (unless (and (or (zerop octet) (plusp indirizzo))
                 (<= (+ indirizzo octet) +limite-indirizzo+))
      (error 'errore-io :regola :regione :dettaglio indirizzo)))
  nil)

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun percorso-nativo (percorso)
  "Accetta pathname o stringa senza NUL; non crea direttori né normalizza il filesystem."
  (let ((nome (sb-ext:native-namestring (pathname percorso))))
    (when (or (zerop (length nome)) (find #\Null nome))
      (error 'errore-io :regola :percorso :dettaglio nome))
    nome))

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun apri-lettura (percorso)
  "Apre il segmento soltanto in lettura; ogni errore POSIX resta esplicito."
  (sb-posix:open (percorso-nativo percorso) sb-posix:o-rdonly))

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun crea-esclusivo (percorso)
  "Crea una fixture nuova con O_EXCL e permessi 0600; mai sovrascrive un file."
  (sb-posix:open (percorso-nativo percorso)
                 (logior sb-posix:o-wronly sb-posix:o-creat sb-posix:o-excl)
                 #o600))

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun chiudi (fd)
  "Chiude una volta; anche EINTR è propagato perché il possesso del fd è ambiguo."
  (valida-descrittore fd)
  (unless (eql 0 (sb-posix:close fd))
    (error 'errore-io :regola :chiusura))
  nil)

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun elimina-file (percorso)
  "Elimina soltanto il percorso posseduto dal controller; assenza ed errori sono dichiarati."
  (unless (eql 0 (sb-posix:unlink (percorso-nativo percorso)))
    (error 'errore-io :regola :eliminazione))
  nil)

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun lettura-posizionale (fd sap octet offset)
  "Una sola pread; cattura errno subito e segnala syscall-error al chiamante."
  (declare (type (integer 0 2147483647) fd)
           (type sb-sys:system-area-pointer sap)
           (type (integer 0 268435456) octet)
           (type (integer 0 9223372036854775807) offset))
  (let ((numero (%pread fd sap octet offset)))
    (when (= numero -1)
      (error 'sb-posix:syscall-error :errno (sb-alien:get-errno) :name 'pread))
    numero))

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun scrittura (fd sap octet)
  "Una sola write; cattura errno subito e segnala syscall-error al chiamante."
  (declare (type (integer 0 2147483647) fd)
           (type sb-sys:system-area-pointer sap)
           (type (integer 0 268435456) octet))
  (let ((numero (%write fd sap octet)))
    (when (= numero -1)
      (error 'sb-posix:syscall-error :errno (sb-alien:get-errno) :name 'write))
    numero))

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun trasferisci-esatto (fd sap octet offset chiamata lettura-p)
  "Avanza soltanto dopo progresso positivo, con massimo 16 EINTR consecutivi."
  (valida-descrittore fd)
  (valida-regione sap octet offset)
  (unless (or (null chiamata) (functionp chiamata))
    (error 'errore-io :regola :chiamata :dettaglio chiamata))
  (let ((descrittore fd) (base sap) (dimensione octet) (inizio offset)
        (callback chiamata) (posizione 0) (interruzioni 0))
    (declare (type (integer 0 2147483647) descrittore)
             (type sb-sys:system-area-pointer base)
             (type (integer 0 268435456) dimensione posizione)
             (type (integer 0 9223372036854775807) inizio)
             (type (or null function) callback)
             (type (integer 0 17) interruzioni))
    ;; Al massimo OCTET progressioni di un byte e 16 EINTR prima di ciascuna.
    (loop repeat (* (1+ +limite-eintr+) (max 1 dimensione))
          until (= posizione dimensione)
          do (multiple-value-bind (numero interrotto-p)
                 (handler-case
                     (let ((residuo (- dimensione posizione)))
                       (declare (type (integer 0 268435456) residuo))
                       (values
                        (if lettura-p
                            (let ((posizione-file (+ inizio posizione)))
                              (declare (type (integer 0 9223372036854775807)
                                             posizione-file))
                              (if callback
                                  (funcall callback descrittore
                                           (sb-sys:sap+ base posizione)
                                           residuo posizione-file)
                                  (lettura-posizionale descrittore
                                                      (sb-sys:sap+ base posizione)
                                                      residuo
                                                      posizione-file)))
                            (if callback
                                (funcall callback descrittore
                                         (sb-sys:sap+ base posizione) residuo)
                                (scrittura descrittore
                                           (sb-sys:sap+ base posizione) residuo)))
                        nil))
                   (sb-posix:syscall-error (condizione)
                     (unless (= (sb-posix:syscall-errno condizione) sb-posix:eintr)
                       (error condizione))
                     (values nil t)))
               (cond
                 (interrotto-p
                  (incf interruzioni)
                  (when (> interruzioni +limite-eintr+)
                    (error 'errore-io :regola :limite-eintr
                                     :dettaglio interruzioni)))
                 ((and (typep numero 'integer)
                       (<= 1 numero (- dimensione posizione)))
                  (incf posizione numero)
                  (setf interruzioni 0))
                 ((eql numero 0)
                  (error 'errore-io :regola (if lettura-p :eof :nessun-progresso)
                                   :dettaglio posizione))
                 (t (error 'errore-io :regola :ritorno-invalido :dettaglio numero)))))
    (unless (= posizione dimensione)
      (error 'errore-io :regola :trasferimento-incompleto :dettaglio posizione)))
  nil)

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun leggi-esatto (fd sap octet offset &key (reader nil))
  "Reader NIL usa pread inline; una funzione iniettata restituisce n o segnala errore."
  (trasferisci-esatto fd sap octet offset reader t))

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun scrivi-esatto (fd sap octet &key (writer nil))
  "Writer NIL usa write inline; completa la fixture senza dichiarare durability."
  (trasferisci-esatto fd sap octet 0 writer nil))

;;; REQ: REQ-VAL-001 REQ-AFF-001 REQ-STO-003
(defun mappa (fd octet)
  "Mappa una regione non vuota dal byte zero, PROT_READ e MAP_PRIVATE, senza fallback."
  (valida-descrittore fd)
  (valida-regione (sb-sys:int-sap 1) octet 0 :non-vuota t)
  (let ((dimensione (sb-posix:stat-size (sb-posix:fstat fd))))
    (unless (<= octet dimensione)
      (error 'errore-io :regola :file-corto :dettaglio dimensione)))
  ;; Il controller garantisce che nessuno tronchi il file mentre la mappa è viva.
  (let ((sap (sb-posix:mmap (sb-sys:int-sap 0) octet sb-posix:prot-read
                          sb-posix:map-private fd 0)))
    (handler-case
        (progn (valida-regione sap octet 0 :non-vuota t) sap)
      (error (incidente)
        ;; Il SAP appartiene già a questo confine di risorsa. Il cleanup non
        ;; richiama SMAPPA, che ripeterebbe la validazione appena fallita.
        (let ((rilascio nil))
          (handler-case
              (unless (eql 0 (sb-posix:munmap sap octet))
                (error 'errore-io :regola :smappatura))
            (error (condizione) (setf rilascio condizione)))
          (when rilascio
            (error 'errore-io :regola :mappa-cleanup
                             :dettaglio (list :primario incidente :cleanup rilascio)))
          (error incidente))))))

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun smappa (sap octet)
  "Rilascia la regione esatta posseduta dal controller; errore di munmap propagato."
  (valida-regione sap octet 0 :non-vuota t)
  (unless (eql 0 (sb-posix:munmap sap octet))
    (error 'errore-io :regola :smappatura))
  nil)

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun attende-regola (regola funzione)
  "Verifica una condizione attesa senza assorbire altri guasti."
  (handler-case
      (progn (funcall funzione)
             (error "Iniezione SPK-05 non rilevata: ~S." regola))
    (errore-io (condizione)
      (unless (eq regola (regola-io condizione))
        (error "Iniezione SPK-05: atteso ~S, ricevuto ~S."
               regola (regola-io condizione)))))
  nil)

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun attende-errno (errno funzione)
  "Verifica un errno esatto; condizioni diverse e successo inatteso restano errori."
  (handler-case
      (progn (funcall funzione)
             (error "Iniezione SPK-05 non rilevata: errno ~S." errno))
    (sb-posix:syscall-error (condizione)
      (unless (= errno (sb-posix:syscall-errno condizione))
        (error "SPK-05: atteso errno ~S, ricevuto ~S."
               errno (sb-posix:syscall-errno condizione)))))
  nil)

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun con-descrittore (fd funzione)
  "Possiede fd fino alla close unica; conserva sia il guasto primario sia quello di cleanup."
  (let ((risultato nil) (incidente nil) (chiusura nil))
    (unwind-protect
         (handler-case (setf risultato (funcall funzione fd))
           (error (condizione) (setf incidente condizione)))
      (handler-case (chiudi fd)
        (error (condizione) (setf chiusura condizione))))
    (when chiusura
      (error 'errore-io :regola :descrittore-cleanup
                       :dettaglio (list :primario incidente :cleanup chiusura)))
    (when incidente (error incidente))
    risultato))

;;; REQ: REQ-VAL-001 REQ-AFF-001 REQ-STO-003
(defun check-file (percorso octet)
  "Verifica guasti POSIX su una fixture immutabile esistente, senza scritture riuscite."
  (unless (and (typep octet 'integer) (<= 1 octet (1- +limite-octet+)))
    (error 'errore-io :regola :dimensione-fixture :dettaglio octet))
  (let ((casi nil)
        (buffer (make-array 1 :element-type '(unsigned-byte 8) :initial-element 197))
        (fd (apri-lettura percorso)))
    (con-descrittore
     fd
     (lambda (descrittore)
       (let ((dimensione (sb-posix:stat-size (sb-posix:fstat descrittore))))
         (unless (= octet dimensione)
           (error 'errore-io :regola :dimensione-fixture :dettaglio dimensione))
         (attende-errno
          sb-posix:eexist
          (lambda ()
            ;; Se la creazione riuscisse, il fd inatteso viene comunque chiuso.
            ;; Non si elimina un percorso che appartiene al controller.
            (con-descrittore
             (crea-esclusivo percorso)
             (lambda (inatteso)
               (declare (ignore inatteso))
               (error "Creazione esclusiva riuscita su una fixture esistente.")))))
         (push (list :case :exclusive-existing :status :ok) casi)
         (sb-sys:with-pinned-objects (buffer)
           (let ((sap (sb-sys:vector-sap buffer)))
             (attende-errno sb-posix:ebadf
                            (lambda () (scrivi-esatto descrittore sap 1)))
             (push (list :case :write-readonly :status :ok) casi)
             (attende-regola :eof
                             (lambda () (leggi-esatto descrittore sap 1 (+ dimensione 17))))
             (push (list :case :pread-beyond-eof :status :ok) casi)))
         (attende-regola :file-corto
                        (lambda () (mappa descrittore (1+ dimensione))))
         (push (list :case :mapping-beyond-eof :status :ok) casi))))
    ;; Nessuna apertura viene eseguita tra la close e F_GETFD.
    (attende-errno sb-posix:ebadf (lambda () (sb-posix:fcntl fd sb-posix:f-getfd)))
    (push (list :case :descriptor-closed :status :ok) casi)
    (let ((ordinati (nreverse casi)))
      (list :status :ok :cases ordinati :case-count (length ordinati)
            :fixture-bytes octet :buffer-after (aref buffer 0)
            :limits '(:immutable-existing-file :no-successful-write
                      :fixture-integrity-verified-by-controller)))))

;;; REQ: REQ-VAL-001 REQ-AFF-001
(defun check ()
  "Iniezioni finite senza filesystem: short I/O, EINTR, EOF, limiti e errno."
  (let ((buffer (make-array 8 :element-type '(unsigned-byte 8) :initial-element 0))
        (casi nil))
    (sb-sys:with-pinned-objects (buffer)
      (let ((sap (sb-sys:vector-sap buffer)))
        (labels ((registra (nome) (push (list :case nome :status :ok) casi))
                 (errore-con-ritorno (regola ritorno)
                   (attende-regola
                    regola (lambda ()
                             (leggi-esatto
                              0 sap 8 41
                              :reader (lambda (fd destinazione numero offset)
                                        (declare (ignore fd destinazione numero offset))
                                        ritorno))))
                   (registra regola)))
          (let ((chiamate 0))
            (leggi-esatto
             0 sap 8 41
             :reader (lambda (fd destinazione numero offset)
                       (declare (ignore fd))
                       (let ((posizione (- offset 41)))
                         (unless (and (<= 0 posizione 7)
                                      (= numero (- 8 posizione))
                                      (= (sb-sys:sap-int destinazione)
                                         (+ (sb-sys:sap-int sap) posizione)))
                           (error "Short pread: puntatore, offset o residuo errato."))
                         (incf chiamate)
                         (let ((copiati (min 3 numero)))
                           (dotimes (i copiati)
                             (setf (sb-sys:sap-ref-8 destinazione i) (+ posizione i 1)))
                           copiati))))
            (unless (and (= chiamate 3) (equalp buffer #(1 2 3 4 5 6 7 8)))
              (error "Short pread: byte o numero di chiamate errato."))
            (registra :short-read))
          (let ((chiamate 0) (copiati 0))
            (scrivi-esatto
             0 sap 8
             :writer (lambda (fd origine numero)
                       (declare (ignore fd))
                       (unless (and (= numero (- 8 copiati))
                                    (= (sb-sys:sap-int origine)
                                       (+ (sb-sys:sap-int sap) copiati)))
                         (error "Short write: puntatore o residuo errato."))
                       (let ((progresso (min numero 2)))
                         (dotimes (i progresso)
                           (unless (= (sb-sys:sap-ref-8 origine i) (+ copiati i 1))
                             (error "Short write: byte errato.")))
                         (incf chiamate)
                         (incf copiati progresso)
                         progresso)))
            (unless (and (= chiamate 4) (= copiati 8))
              (error "Short write: conteggio errato."))
            (registra :short-write))
          (let ((chiamate 0))
            (leggi-esatto
             0 sap 2 41
             :reader (lambda (fd destinazione numero offset)
                       (declare (ignore fd))
                       (let ((progresso (floor chiamate 17)))
                         (unless (and (= offset (+ 41 progresso))
                                      (= numero (- 2 progresso))
                                      (= (sb-sys:sap-int destinazione)
                                         (+ (sb-sys:sap-int sap) progresso)))
                           (error "EINTR deve preservare la regione corrente.")))
                       (incf chiamate)
                       (if (zerop (mod chiamate 17))
                           1
                           (error 'sb-posix:syscall-error :errno sb-posix:eintr
                                                        :name 'pread))))
            (unless (= chiamate 34) (error "EINTR: limite o reset errato."))
            (registra :eintr-reset))
          (let ((chiamate 0))
            (attende-regola
             :limite-eintr
             (lambda ()
               (leggi-esatto
                0 sap 1 0
                :reader (lambda (fd destinazione numero offset)
                          (declare (ignore fd destinazione numero offset))
                          (incf chiamate)
                          (error 'sb-posix:syscall-error :errno sb-posix:eintr
                                                       :name 'pread)))))
            (unless (= chiamate 17) (error "EINTR illimitato o prematuro."))
            (registra :limite-eintr))
          (errore-con-ritorno :eof 0)
          (errore-con-ritorno :ritorno-invalido 9)
          (errore-con-ritorno :ritorno-invalido -1)
          (errore-con-ritorno :ritorno-invalido nil)
          (errore-con-ritorno :ritorno-invalido :interrotto)
          (let ((chiamate 0))
            (handler-case
                (progn
                  (leggi-esatto
                   0 sap 8 41
                   :reader (lambda (fd destinazione numero offset)
                             (declare (ignore fd))
                             (incf chiamate)
                             (if (= chiamate 1)
                                 3
                                 (progn
                                   (unless (and (= offset 44) (= numero 5)
                                                (= (sb-sys:sap-int destinazione)
                                                   (+ (sb-sys:sap-int sap) 3)))
                                     (error "EOF parziale: regione errata."))
                                   0))))
                  (error "EOF parziale non rilevato."))
              (errore-io (condizione)
                (unless (and (eq :eof (regola-io condizione))
                             (= 3 (dettaglio-io condizione)))
                  (error "EOF parziale: condizione errata."))))
            (unless (= chiamate 2) (error "EOF parziale ritentato."))
            (registra :eof-parziale))
          (attende-regola
           :nessun-progresso
           (lambda ()
             (scrivi-esatto 0 sap 8
                            :writer (lambda (fd origine numero)
                                      (declare (ignore fd origine numero))
                                      0))))
          (registra :write-nullo)
          (let ((chiamate 0))
            (handler-case
                (progn
                  (scrivi-esatto
                   0 sap 8
                   :writer (lambda (fd origine numero)
                             (declare (ignore fd origine numero))
                             (incf chiamate)
                             (error 'sb-posix:syscall-error :errno sb-posix:eio
                                                          :name 'write)))
                  (error "Write EIO non propagato."))
              (sb-posix:syscall-error (condizione)
                (unless (= sb-posix:eio (sb-posix:syscall-errno condizione))
                  (error "Write errno alterato."))))
            (unless (= chiamate 1) (error "Write EIO ritentato."))
            (registra :write-errno))
          (let ((chiamate 0))
            (handler-case
                (progn
                  (leggi-esatto
                   0 sap 8 0
                   :reader (lambda (fd destinazione numero offset)
                             (declare (ignore fd destinazione numero offset))
                             (incf chiamate)
                             (error 'sb-posix:syscall-error :errno sb-posix:eio
                                                          :name 'pread)))
                  (error "EIO non propagato."))
              (sb-posix:syscall-error (condizione)
                (unless (= sb-posix:eio (sb-posix:syscall-errno condizione))
                  (error "Errno alterato."))))
            (unless (= chiamate 1) (error "EIO ritentato."))
            (registra :errno))
          (let ((chiamate 0))
            (flet ((non-chiamare (fd destinazione numero offset)
                     (declare (ignore fd destinazione numero offset))
                     (incf chiamate)
                     (error "Syscall chiamata su limiti non validi.")))
              (attende-regola :descrittore
                             (lambda () (leggi-esatto -1 sap 1 0 :reader #'non-chiamare)))
              (attende-regola :dimensione
                             (lambda () (leggi-esatto 0 sap -1 0 :reader #'non-chiamare)))
              (attende-regola :dimensione
                             (lambda () (leggi-esatto 0 sap (1+ +limite-octet+) 0
                                                      :reader #'non-chiamare)))
              (attende-regola :offset
                             (lambda () (leggi-esatto 0 sap 1 +limite-offset+
                                                      :reader #'non-chiamare)))
              (attende-regola :offset
                             (lambda () (leggi-esatto 0 sap 1 -1 :reader #'non-chiamare)))
              (attende-regola :regione
                             (lambda () (leggi-esatto 0 (sb-sys:int-sap +limite-indirizzo+)
                                                      1 0 :reader #'non-chiamare)))
              (attende-regola :regione
                             (lambda () (leggi-esatto 0 (sb-sys:int-sap 0) 1 0
                                                      :reader #'non-chiamare)))
              (attende-regola :puntatore
                             (lambda () (leggi-esatto 0 nil 1 0 :reader #'non-chiamare)))
              (leggi-esatto 0 (sb-sys:int-sap 0) 0 0 :reader #'non-chiamare))
            (unless (zerop chiamate) (error "Validazione tardiva."))
            (registra :limiti-prima-syscall)))))
    (let ((ordinati (nreverse casi)))
      (list :status :ok :cases ordinati :case-count (length ordinati)
            :limits (list :max-bytes +limite-octet+
                          :max-consecutive-eintr +limite-eintr+
                          :memory-lifetime :controller
                          :file-mutation :excluded)))))
