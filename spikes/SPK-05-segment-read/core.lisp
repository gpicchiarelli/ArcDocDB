;;;; SPK-05: controllo dei file, worker indipendenti e misure delimitate.
;;; REQ: REQ-BEN-001 REQ-BEN-002 REQ-AFF-016 REQ-AFF-002
(defpackage #:arcdocdb.spk05
  (:use #:cl)
  (:import-from #:arcdocdb.spk05.io #:apri-lettura #:crea-esclusivo #:chiudi
                #:leggi-esatto #:scrivi-esatto #:mappa #:smappa #:elimina-file)
  (:import-from #:arcdocdb.spk05.record #:+record-bytes+ #:+value-bytes+
                #:scrivi-fixture #:verifica-record)
  (:export #:check #:benchmark))
(in-package #:arcdocdb.spk05)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(deftype octets () '(simple-array (unsigned-byte 8) (*)))
(deftype piano () '(simple-array (unsigned-byte 32) (*)))
(deftype campioni () '(simple-array (unsigned-byte 64) (*)))
(defconstant +attesa-secondi+ 10)
(defconstant +massimo-record+ 131072)
(defconstant +warmup+ 32)

;;; OWNER: controller crea risorse e piani; worker scrive solo i propri risultati.
;;; SHARED: nessuna mutazione per lettura; porte comuni solo ai confini del caso.
(defstruct lavoro
  "Pre: risorse e piano pronti. Post: esito locale dopo join; nessun trasferimento di SAP."
  (fd -1 :type (integer -1 2147483647))
  (buffer (make-array +record-bytes+ :element-type '(unsigned-byte 8)) :type octets)
  (piano (make-array 0 :element-type '(unsigned-byte 32)) :type piano)
  (campioni (make-array 0 :element-type '(unsigned-byte 64)) :type campioni)
  (inizio 0 :type fixnum) (fine 0 :type fixnum) (completati 0 :type fixnum)
  (valori-verificati 0 :type fixnum) (incidente nil :type (or null error))
  (thread nil :type (or null sb-thread:thread)))

(define-condition worker-incompleto (error)
  ((numero :initarg :numero :reader numero-worker)
   (precedente :initarg :precedente :initform nil :reader errore-precedente))
  (:report (lambda (c s)
             (format s "SPK-05: worker ~D ancora vivo; risorse conservate fino all'uscita.~@[ Errore precedente: ~A.~]"
                     (numero-worker c) (errore-precedente c)))))

(defun secondi (ticks)
  "Converte un intervallo del clock in secondi double-float."
  (/ ticks (coerce internal-time-units-per-second 'double-float)))

(defun nuova-directory (base)
  "Crea una directory esclusiva sotto out/data; nessun file preesistente rimosso."
  (let ((radice (merge-pathnames "out/data/" base)))
    (ensure-directories-exist (merge-pathnames "segnaposto" radice))
    (pathname (concatenate 'string
                           (sb-posix:mkdtemp (namestring (merge-pathnames "letture-XXXXXX" radice)))
                           "/"))))

(defun con-descrittore (fd funzione)
  "Chiude una volta, conservando un eventuale errore precedente e quello di close."
  (let ((esito nil) (incidente nil) (rilascio nil))
    (unwind-protect
         (handler-case (setf esito (funcall funzione fd)) (error (c) (setf incidente c)))
      (handler-case (chiudi fd) (error (c) (setf rilascio c))))
    (when rilascio (error "SPK-05: close fallito: ~A; errore precedente: ~A." rilascio incidente))
    (when incidente (error incidente))
    esito))

(defun verifica-file (path numero)
  "Riapre il file, verifica ogni record e confronta ogni octet con la fixture attesa."
  (let* ((buffer (make-array +record-bytes+ :element-type '(unsigned-byte 8)))
         (atteso (make-array +record-bytes+ :element-type '(unsigned-byte 8)))
         (fd (apri-lettura path)))
    (con-descrittore fd
      (lambda (fd)
           (unless (= (sb-posix:stat-size (sb-posix:fstat fd)) (* numero +record-bytes+))
             (error "SPK-05: dimensione della fixture incoerente."))
           (sb-sys:with-pinned-objects (buffer)
             (dotimes (n numero)
               (leggi-esatto fd (sb-sys:vector-sap buffer) +record-bytes+ (* n +record-bytes+))
               (verifica-record (sb-sys:vector-sap buffer) 0 +record-bytes+ n)
               (scrivi-fixture atteso n)
               (unless (equalp buffer atteso) (error "SPK-05: payload incoerente al record ~D." n)))))))
  (* numero +record-bytes+))

(defun con-fixture (base numero funzione)
  "Confine della fixture: rimuove solo il file proprio, dopo fine dei worker.
Su worker vivo conserva le risorse; gli errori di pulizia restano espliciti."
  (unless (and (typep numero 'fixnum) (<= 1 numero +massimo-record+))
    (error "SPK-05: numero record fuori budget."))
  (let* ((dir (nuova-directory base)) (path (merge-pathnames "segmento.dat.tmp" dir))
         (creato nil) (incidente nil) (pulizia nil) (risultato nil))
    (unwind-protect
         (handler-case
             (progn
               ;; La directory è esclusiva; OPEN fallita non autorizza eliminazione.
               (let* ((buffer (make-array +record-bytes+ :element-type '(unsigned-byte 8)))
                      (fd (crea-esclusivo path)))
                 (setf creato t)
                 (con-descrittore fd
                   (lambda (fd)
                     (sb-sys:with-pinned-objects (buffer)
                        (dotimes (n numero)
                          (scrivi-fixture buffer n)
                          (scrivi-esatto fd (sb-sys:vector-sap buffer) +record-bytes+))))))
               (verifica-file path numero)
               (setf risultato (funcall funzione path numero)))
           (error (c) (setf incidente c)))
      (unless (typep incidente 'worker-incompleto)
        (handler-case
            (progn (when creato (elimina-file path)) (sb-posix:rmdir dir))
          (error (c) (setf pulizia c)))))
    (when pulizia (error "SPK-05: pulizia fallita: ~A; errore precedente: ~A." pulizia incidente))
    (when incidente (error incidente))
    risultato))

(defun prepara-piano (numero worker-id workers accesso)
  "Pre: divisibilità già controllata. Post: intervallo disgiunto o piano LCG32 ripetibile."
  (unless (and (typep numero 'fixnum) (<= 1 numero +massimo-record+) (typep workers '(integer 1 4))
               (typep worker-id 'fixnum) (<= 0 worker-id) (< worker-id workers)
               (zerop (mod numero workers)))
    (error "SPK-05: parametri del piano incoerenti."))
  (let* ((operazioni (/ numero workers))
         (piano (make-array operazioni :element-type '(unsigned-byte 32)))
         (seed (1+ worker-id)))
    (dotimes (i operazioni)
      (setf (aref piano i)
            (case accesso
              (:sequential (+ (* worker-id operazioni) i))
              (:random (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))
                       (mod seed numero))
              (otherwise (error "SPK-05: accesso sconosciuto.")))))
    piano))

(declaim (ftype (function (integer sb-sys:system-area-pointer
                          sb-sys:system-area-pointer fixnum keyword (unsigned-byte 32))
                         (values fixnum &optional)) leggi-verifica))
(defun leggi-verifica (fd buffer mapping bytes-file metodo numero)
  "Pre: SAP stabili, file immutabile. Post: lunghezza del solo corpo verificato, senza copia da mmap."
  (let ((offset (* numero +record-bytes+)))
    (multiple-value-bind (inizio fine)
        (case metodo
          (:pread (leggi-esatto fd buffer +record-bytes+ offset)
                  (verifica-record buffer 0 +record-bytes+ numero))
          (:mmap (verifica-record mapping offset bytes-file numero))
          (otherwise (error "SPK-05: metodo sconosciuto.")))
      (unless (= (- fine inizio) +value-bytes+) (error "SPK-05: range verificato incoerente."))
      (- fine inizio))))

(defun ciclo-worker (lavoro buffer mapping bytes metodo misurare)
  "Esegue un numero finito di letture, senza stato condiviso; campioni locali opzionali."
  (let ((piano (lavoro-piano lavoro)) (campioni (lavoro-campioni lavoro)) (totale 0))
    (declare (type piano piano) (type campioni campioni) (type fixnum totale))
    (dotimes (i (length piano))
      (let ((inizio (if misurare (get-internal-real-time) 0)))
        (incf totale (leggi-verifica (lavoro-fd lavoro) buffer mapping bytes metodo (aref piano i)))
        (when misurare (setf (aref campioni i) (- (get-internal-real-time) inizio)))))
    totale))

(defun esegui-worker (lavoro mapping bytes metodo pronti partenza)
  "Confine worker: ogni errore è registrato; attesa finita e buffer pinned fino al termine."
  (let ((segnalato nil))
    (handler-case
        (let ((buffer (lavoro-buffer lavoro)))
          (sb-sys:with-pinned-objects (buffer)
            (dotimes (i (min +warmup+ (length (lavoro-piano lavoro))))
              (leggi-verifica (lavoro-fd lavoro) (sb-sys:vector-sap buffer) mapping bytes
                             metodo (aref (lavoro-piano lavoro) i)))
            (sb-thread:signal-semaphore pronti)
            (setf segnalato t)
            (unless (sb-thread:wait-on-semaphore partenza :timeout +attesa-secondi+)
              (error "SPK-05: timeout della porta di partenza."))
            (setf (lavoro-inizio lavoro) (get-internal-real-time)
                  (lavoro-valori-verificati lavoro)
                  (ciclo-worker lavoro (sb-sys:vector-sap buffer) mapping bytes metodo t)
                  (lavoro-fine lavoro) (get-internal-real-time)
                  (lavoro-completati lavoro) (length (lavoro-piano lavoro)))))
      (error (c) (setf (lavoro-incidente lavoro) c)))
    (unless segnalato (sb-thread:signal-semaphore pronti)))
  :completato)

(defun attendi-worker (lavori)
  "Join limitati; nessuna risorsa libera mentre un worker è ancora vivo."
  (let ((sentinella (gensym "JOIN")))
    (loop for lavoro in lavori for n from 0
          for thread = (lavoro-thread lavoro)
          when thread
            do (let ((esito (sb-thread:join-thread thread :timeout +attesa-secondi+
                                                  :default sentinella)))
                 (when (eq esito sentinella)
                   (when (sb-thread:thread-alive-p thread)
                     (error 'worker-incompleto :numero n))
                   (error "SPK-05: join senza esito per worker ~D." n))
                 (unless (eq esito :completato) (error "SPK-05: ritorno worker inatteso."))))))

(defun libera-risorse (lavori mapping bytes)
  "Rilascia tutte le risorse tentabili, conservando tutti gli errori di cleanup."
  (let ((errori nil))
    (when mapping
      (handler-case (smappa mapping bytes) (error (c) (push c errori))))
    (dolist (lavoro lavori)
      (when (>= (lavoro-fd lavoro) 0)
        (handler-case (chiudi (lavoro-fd lavoro)) (error (c) (push c errori)))))
    (when errori (error "SPK-05: rilascio risorse fallito: ~{~A~^; ~}." errori))))

(defun percentili (campioni)
  "Rango superiore; l'ordinamento avviene solo dopo join, fuori dall'intervallo misurato."
  (let* ((ordinati (sort (copy-seq campioni) #'<)) (n (length ordinati)))
    (unless (plusp n) (error "SPK-05: campioni vuoti."))
    (loop for (nome . p) in '((:min . 0) (:p50 . 0.50d0) (:p95 . 0.95d0)
                             (:p99 . 0.99d0) (:max . 1))
          append (list nome (secondi (aref ordinati (max 0 (1- (ceiling (* p n))))))))))

(defun risultato-caso (lavori bytes metodo accesso replica allocazioni durata)
  "Aggrega conteggi e intervallo reale comune, senza dedurre un target di prodotto."
  (let* ((inizio (reduce #'min lavori :key #'lavoro-inizio))
         (fine (reduce #'max lavori :key #'lavoro-fine))
         (wall (secondi (- fine inizio)))
         (operazioni (reduce #'+ lavori :key #'lavoro-completati))
         (samples (apply #'concatenate 'campioni (mapcar #'lavoro-campioni lavori))))
    (unless (and (= (* operazioni +record-bytes+) bytes)
                 (= (reduce #'+ lavori :key #'lavoro-valori-verificati) (* operazioni +value-bytes+))
                 (plusp wall))
      (error "SPK-05: conteggi o intervallo incoerenti."))
    (list :status :ok :method metodo :access accesso :workers (length lavori) :replica replica
          :operations operazioni :verified-record-bytes bytes
          :io-and-verification-wall-seconds wall :records-per-second (/ operazioni wall)
          :verified-gib-per-second (/ bytes wall (expt 2 30))
          :latency-seconds (percentili samples) :raw-latency-ticks samples
          :worker-start-ticks (mapcar #'lavoro-inizio lavori)
          :worker-end-ticks (mapcar #'lavoro-fine lavori)
          :process-allocated-bytes-including-controller allocazioni
          :workers-wall-seconds durata)))

(defun avvia-worker (lavori mapping bytes metodo)
  "Porte comuni usate solo una volta; il controller non legge dati del file durante il ciclo."
  (let ((pronti (sb-thread:make-semaphore)) (partenza (sb-thread:make-semaphore))
        (inizio (get-internal-real-time)) (allocazioni (sb-ext:get-bytes-consed)))
    (unwind-protect
         (progn
           (dolist (lavoro lavori)
             (let ((corrente lavoro))
               (setf (lavoro-thread lavoro)
                     (sb-thread:make-thread
                      (lambda () (esegui-worker corrente mapping bytes metodo pronti partenza))
                      :name "SPK-05-lettura"))))
           (dotimes (n (length lavori))
             (unless (sb-thread:wait-on-semaphore pronti :timeout +attesa-secondi+)
               (error "SPK-05: preparazione worker fuori budget."))))
      ;; Anche una creazione parziale libera i worker già creati dalla porta.
      (sb-thread:signal-semaphore partenza (length lavori))
      (attendi-worker lavori))
    (dolist (lavoro lavori)
      (when (lavoro-incidente lavoro) (error (lavoro-incidente lavoro))))
    (values (- (sb-ext:get-bytes-consed) allocazioni)
            (secondi (- (get-internal-real-time) inizio)))))

(defun misura-caso (path numero workers metodo accesso replica &key record-invalido)
  "Alloca prima dei tempi; se un worker resta vivo non esegue munmap né close."
  (let ((lavori nil) (mapping nil) (bytes (* numero +record-bytes+)) (incidente nil)
        (vivo-al-rilascio nil)
        (rilascio nil) (risultato nil) (inizio (get-internal-real-time)))
    (unwind-protect
         (handler-case
             (progn
               (dotimes (n workers)
                 (let ((lavoro (make-lavoro :piano (prepara-piano numero n workers accesso)
                                            :campioni (make-array (/ numero workers)
                                                                 :element-type '(unsigned-byte 64)))))
                   (push lavoro lavori)
                   (setf (lavoro-fd lavoro) (apri-lettura path))))
               (setf lavori (nreverse lavori))
               (when record-invalido
                 (setf (aref (lavoro-piano (first lavori)) 0) numero))
               (when (eq metodo :mmap) (setf mapping (mappa (lavoro-fd (first lavori)) bytes)))
               (multiple-value-bind (allocazioni durata)
                   (avvia-worker lavori (or mapping (sb-sys:int-sap 0)) bytes metodo)
                 (setf risultato (risultato-caso lavori bytes metodo accesso replica allocazioni durata))))
           (error (c) (setf incidente c)))
      (setf vivo-al-rilascio
            (position-if (lambda (lavoro)
                           (let ((thread (lavoro-thread lavoro)))
                             (and thread (sb-thread:thread-alive-p thread)))) lavori))
      (unless vivo-al-rilascio
        (handler-case (libera-risorse lavori mapping bytes) (error (c) (setf rilascio c)))))
    (when vivo-al-rilascio
      (error 'worker-incompleto :numero vivo-al-rilascio :precedente incidente))
    (when rilascio (error "SPK-05: ~A; errore precedente: ~A." rilascio incidente))
    (when incidente (error incidente))
    (append risultato (list :case-wall-seconds (secondi (- (get-internal-real-time) inizio))))))

(defun profilo-allocazioni (path numero metodo)
  "Misura nel solo controller: buffer e piano pronti, nessun campione di tempo per record."
  (let* ((lavoro (make-lavoro :piano (prepara-piano numero 0 1 :random)))
         (buffer (lavoro-buffer lavoro)) (bytes (* numero +record-bytes+))
         (mapping nil) (delta 0) (sink 0) (durata 0d0)
         (incidente nil) (rilascio nil) (risultato nil))
    (unwind-protect
         (handler-case
           (progn
           (setf (lavoro-fd lavoro) (apri-lettura path))
           (when (eq metodo :mmap) (setf mapping (mappa (lavoro-fd lavoro) bytes)))
           (sb-sys:with-pinned-objects (buffer)
             (let ((sap (sb-sys:vector-sap buffer)) (map (or mapping (sb-sys:int-sap 0))))
               (ciclo-worker lavoro sap map bytes metodo nil)
               (let ((prima (sb-ext:get-bytes-consed)) (inizio (get-internal-real-time)))
                 (setf sink (ciclo-worker lavoro sap map bytes metodo nil)
                       delta (- (sb-ext:get-bytes-consed) prima)
                       durata (secondi (- (get-internal-real-time) inizio))))))
           (unless (= sink (* numero +value-bytes+)) (error "SPK-05: oracle delle allocazioni incoerente."))
             (setf risultato
                   (list :status :ok :method metodo :operations numero :observed-process-allocated-bytes delta
                         :seconds durata :sampling :none :allocation-scope :isolated-controller-read-loop)))
           (error (c) (setf incidente c)))
      (handler-case (libera-risorse (list lavoro) mapping bytes) (error (c) (setf rilascio c))))
    (when rilascio (error "SPK-05: ~A; errore precedente: ~A." rilascio incidente))
    (when incidente (error incidente))
    risultato))

(defun check-errori-worker (path numero)
  "Un record fuori file fallisce nel worker; join precede il rilascio delle risorse."
  (dolist (metodo '(:pread :mmap))
    (let ((rilevato nil))
      (handler-case (misura-caso path numero 2 metodo :sequential 0 :record-invalido t)
        (arcdocdb.spk05.io:errore-io (c)
          (unless (and (eq metodo :pread) (eq (arcdocdb.spk05.io:regola-io c) :eof))
            (error c))
          (setf rilevato t))
        (arcdocdb.spk05.record:record-rifiutato (c)
          (unless (and (eq metodo :mmap)
                       (eq (arcdocdb.spk05.record:motivo-rifiuto c) :header-troncato))
            (error c))
          (setf rilevato t)))
      (unless rilevato (error "SPK-05: errore worker non propagato per ~S." metodo))))
  (list :status :ok :worker-errors 2 :propagation :after-join :cleanup :complete))

(defun check (base)
  "Fixture reali, iniezioni e corruzioni limitate; nessuna qualifica del motore."
  (let ((io (arcdocdb.spk05.io:check)) (record (arcdocdb.spk05.record:check)))
    (unless (and (eq (getf io :status) :ok) (eq (getf record :status) :ok))
      (error "SPK-05: esito moduli non valido."))
    (let ((real (con-fixture base 12
                  (lambda (path numero)
                    (let ((filesystem (arcdocdb.spk05.io:check-file path (* numero +record-bytes+)))
                          (errori (check-errori-worker path numero)))
                      (list :filesystem filesystem :worker-errors errori
                            :verified-after-errors (verifica-file path numero)
                            :cases (loop for metodo in '(:pread :mmap)
                                         append (loop for accesso in '(:sequential :random)
                                                      collect (misura-caso path numero 2 metodo accesso 0)))))))))
      (list :status :ok :spike :spk-05 :io io :record record :real-file real
            :file-records 12 :file-bytes (* 12 +record-bytes+) :fixture-cleanup :complete
            :scope :synthetic-immutable-record-read))))

(defun benchmark (base)
  "36 casi in serie, stesso file piccolo, tre repliche; nessuna cache fredda o oltre RAM."
  (let ((inizio (get-internal-real-time)))
    (con-fixture base 8192
      (lambda (path numero)
        (let ((cases nil))
          (dotimes (replica 3)
            (dolist (accesso '(:sequential :random))
              (dolist (workers '(1 2 4))
                (dolist (metodo (if (evenp replica) '(:pread :mmap) '(:mmap :pread)))
                  (push (misura-caso path numero workers metodo accesso replica) cases)))))
          (list :status :ok :spike :spk-05 :file-records numero :file-bytes (* numero +record-bytes+)
                :case-count (length cases) :cases (nreverse cases)
                :allocation-profiles (loop for method in '(:pread :mmap)
                                           collect (profilo-allocazioni path numero method))
                :matrix-wall-seconds-before-cleanup (secondi (- (get-internal-real-time) inizio))
                :parameters (list :workers '(1 2 4) :access '(:sequential :random)
                                  :replicas 3 :warmup-per-worker +warmup+ :record-bytes +record-bytes+)
                :limits '(:small-newly-written-file :uncontrolled-page-cache :synthetic-body-not-cbor
                          :no-index-cache-epoch-or-commit :no-reference-platform-claim)))))))
