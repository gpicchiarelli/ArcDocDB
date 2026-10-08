;;; REQ: REQ-SIM-001 REQ-SIM-002 REQ-OBS-001 REQ-BEN-001 REQ-BEN-002
;;; REQ: REQ-AFF-003 REQ-AFF-008 REQ-AFF-016
(defpackage #:arcdocdb.spk02
  (:use #:cl)
  (:export #:check #:benchmark))
(in-package #:arcdocdb.spk02)
(declaim (optimize (safety 3) (speed 2) (debug 1)))

(defconstant +mib+ 1048576)
(defconstant +fragment-bytes+ 262144)
(defconstant +allocation-bytes+ 65536)
(defconstant +transient-limit+ (* 32 1048576))
(defconstant +worker-batch-limit+ 10000000)

(defstruct (campioni (:constructor nuovi-campioni (dati)))
  (dati (make-array 0 :element-type 'fixnum)
         :type (simple-array fixnum (*)) :read-only t)
  (count 0 :type fixnum)
  (scartati 0 :type fixnum)
  (massimo nil :type (or null fixnum)))

(defun prealloca-campioni (capacita)
  "Prealloca il buffer; non cresce durante la misura."
  (nuovi-campioni (make-array capacita :element-type 'fixnum :initial-element 0)))

(defun registra (campioni tick)
  "Conserva il prefisso; conta esplicitamente l'overflow."
  (check-type tick (and fixnum unsigned-byte))
  (setf (campioni-massimo campioni) (max tick (or (campioni-massimo campioni) 0)))
  (let ((n (campioni-count campioni)))
    (if (< n (length (campioni-dati campioni)))
        (progn (setf (aref (campioni-dati campioni) n) tick)
               (incf (campioni-count campioni)))
        (incf (campioni-scartati campioni))))
  tick)

(defun quantile-rank (ordinati n numeratore denominatore)
  "Nearest rank, posizione ceil(p*n), numerazione da uno; nil per n=0."
  (when (plusp n)
    (aref ordinati (1- (ceiling (* n numeratore) denominatore)))))

(defun millisecondi (tick)
  (when tick (* 1000d0 (/ tick internal-time-units-per-second))))

(defun riepilogo (campioni)
  "Ordina una copia solo dopo la misura; quantili in millisecondi."
  (let* ((n (campioni-count campioni))
         (dati (sort (subseq (campioni-dati campioni) 0 n) #'<)))
    (list :unit :milliseconds :count n
          :observed-count (+ n (campioni-scartati campioni))
          :dropped-count (campioni-scartati campioni) :quantile :nearest-rank
          :p50 (millisecondi (quantile-rank dati n 50 100))
          :p99 (millisecondi (quantile-rank dati n 99 100))
          :max (millisecondi (campioni-massimo campioni))
          :quantile-sample-scope :retained-prefix
          :max-scope :all-observations)))

(defstruct zona
  (layout :heap-large :type keyword :read-only t)
  (bytes 0 :type fixnum :read-only t)
  (frammenti #() :type simple-vector)
  (foreign nil :type t))

(defun nuovo-array (bytes)
  "Inizializza il payload e tocca ogni passo da 4096 byte e l'ultimo byte."
  (let ((dati (make-array bytes :element-type '(unsigned-byte 8)
                                :initial-element 0)))
    (loop for i from 0 below bytes by 4096 do (setf (aref dati i) 37))
    (setf (aref dati (1- bytes)) 37)
    dati))

(defun prepara-heap (zona)
  (let* ((bytes (zona-bytes zona))
         (pezzo (if (eq (zona-layout zona) :heap-large) bytes +fragment-bytes+))
         (frammenti (make-array (ceiling bytes pezzo) :initial-element nil)))
    (setf (zona-frammenti zona) frammenti)
    (dotimes (i (length frammenti))
      (setf (aref frammenti i) (nuovo-array (min pezzo (- bytes (* i pezzo))))))))

(defun tocca-foreign (puntatore bytes)
  (declare (type (sb-alien:alien (* sb-alien:unsigned-char)) puntatore))
  (loop for i from 0 below bytes by 4096
        do (setf (sb-alien:deref puntatore i) 37))
  (setf (sb-alien:deref puntatore (1- bytes)) 37))

(defun chiama-con-zona (layout bytes funzione)
  "Il controller possiede il payload; free-alien anche su uscita anomala."
  (let ((zona (make-zona :layout layout :bytes bytes)))
    (unwind-protect
         (progn
           (if (eq layout :foreign)
               (let ((puntatore (sb-alien:make-alien sb-alien:unsigned-char bytes)))
                 (setf (zona-foreign zona) puntatore)
                 (when (sb-alien:null-alien puntatore)
                   (error "make-alien ha restituito un puntatore nullo."))
                 (tocca-foreign puntatore bytes))
               (prepara-heap zona))
           (funcall funzione zona))
      (when (zona-foreign zona)
        (sb-alien:free-alien (zona-foreign zona))
        (setf (zona-foreign zona) nil))
      (setf (zona-frammenti zona) #()))))

(defun sink-zona (zona)
  "Consuma riferimenti e dati dopo le collection: mantiene il payload vivo."
  (if (eq (zona-layout zona) :foreign)
      (let ((p (zona-foreign zona)))
        (declare (type (sb-alien:alien (* sb-alien:unsigned-char)) p))
        (+ (sb-alien:deref p 0) (sb-alien:deref p (1- (zona-bytes zona)))))
      (loop for frammento across (zona-frammenti zona)
            sum (+ (aref frammento 0) (aref frammento (1- (length frammento)))))))

(defun sostituisci-frammento (zona indice)
  "Rimpiazzo seriale del controller; il vecchio array è ritirato dal GC."
  (let* ((frammenti (zona-frammenti zona))
         (i (mod indice (length frammenti)))
         (bytes (length (aref frammenti i))))
    (setf (aref frammenti i) (nuovo-array bytes))
    bytes))

;;; OWNER: controller per stop/errore/stati, sotto mutex; worker per campioni
;;; e buffer propri, letti dal controller soltanto dopo il join.
;;; SHARED: harness sintetico C4. Il mutex serializza controllo e polling stop,
;;; non rappresenta un percorso di operazione fra Serie nel prodotto.
(defstruct worker
  (indice 0 :type fixnum :read-only t)
  (thread nil :type (or null sb-thread:thread))
  (stato :creato :type keyword)
  (errore nil :type (or null error))
  (buffer (make-array 32 :element-type '(unsigned-byte 32) :initial-element 1)
          :type (simple-array (unsigned-byte 32) (*)) :read-only t)
  (latenze (prealloca-campioni 256) :type campioni :read-only t)
  (ritardi (prealloca-campioni 256) :type campioni :read-only t)
  (batch 0 :type fixnum)
  (sink 0 :type fixnum))

(defstruct gruppo
  (mutex (sb-thread:make-mutex :name "SPK02 controllo")
         :type sb-thread:mutex :read-only t)
  (ready (sb-thread:make-semaphore) :type sb-thread:semaphore :read-only t)
  (start (sb-thread:make-semaphore) :type sb-thread:semaphore :read-only t)
  (running (sb-thread:make-semaphore) :type sb-thread:semaphore :read-only t)
  (wake (sb-thread:make-semaphore) :type sb-thread:semaphore :read-only t)
  (worker #() :type simple-vector :read-only t)
  (stop nil :type boolean)
  (modo :work :type keyword :read-only t)
  (inietta-errore nil :type boolean :read-only t))

(defun stop-richiesto-p (gruppo)
  (sb-thread:with-mutex ((gruppo-mutex gruppo)) (gruppo-stop gruppo)))

(defun cambia-stato (gruppo worker stato)
  (sb-thread:with-mutex ((gruppo-mutex gruppo)) (setf (worker-stato worker) stato)))

(defun batch-numerico (worker)
  "Lavoro osservabile sul buffer privato, risultato consumato dal controller."
  (let ((buffer (worker-buffer worker)) (sink (worker-sink worker)))
    (declare (type fixnum sink))
    (dotimes (i 256)
      (let* ((slot (logand i 31))
             (v (logand #xffffffff (+ (aref buffer slot) 17))))
        (setf (aref buffer slot) v
              sink (logand #x3fffffff (+ sink v slot)))))
    (setf (worker-sink worker) sink)))

(defun lavora-worker (gruppo worker)
  (let ((precedente (get-internal-real-time)))
    (loop repeat +worker-batch-limit+
          until (stop-richiesto-p gruppo)
          do (let ((inizio (get-internal-real-time)))
               (registra (worker-ritardi worker) (- inizio precedente))
               (batch-numerico worker)
               (setf precedente (get-internal-real-time))
               (registra (worker-latenze worker) (- precedente inizio))
               (incf (worker-batch worker)))
          finally (unless (stop-richiesto-p gruppo)
                    (error "Limite dei batch worker raggiunto.")))))

(defun attendi-worker (gruppo)
  "Il timeout periodico e wake rendono l'arresto cooperativo osservabile."
  (loop repeat +worker-batch-limit+
        until (stop-richiesto-p gruppo)
        do (sb-thread:wait-on-semaphore (gruppo-wake gruppo) :timeout 0.05d0)
        finally (unless (stop-richiesto-p gruppo)
                  (error "Limite delle attese worker raggiunto."))))

(defun corpo-worker (gruppo worker)
  "Confine del worker: registra l'errore e chiede stop; non lo perde."
  (unwind-protect
       (handler-case
           (progn
             (dotimes (i 4) (batch-numerico worker))
             (cambia-stato gruppo worker :ready)
             (sb-thread:signal-semaphore (gruppo-ready gruppo))
             (unless (sb-thread:wait-on-semaphore (gruppo-start gruppo) :timeout 5)
               (error "Timeout della barriera start."))
             (if (stop-richiesto-p gruppo)
                 (sb-thread:signal-semaphore (gruppo-running gruppo))
                 (progn
               (when (and (gruppo-inietta-errore gruppo)
                          (zerop (worker-indice worker)))
                 (error "SPK02 errore worker iniettato."))
               (cambia-stato gruppo worker
                             (if (eq (gruppo-modo gruppo) :work) :running :attesa))
               (sb-thread:signal-semaphore (gruppo-running gruppo))
               (ecase (gruppo-modo gruppo)
                 (:work (lavora-worker gruppo worker))
                 (:semaphore (attendi-worker gruppo))))))
         (error (condizione)
           (sb-thread:with-mutex ((gruppo-mutex gruppo))
             (setf (worker-errore worker) condizione (gruppo-stop gruppo) t))
           ;; Consente al controller di osservare il fallimento della barriera.
           (sb-thread:signal-semaphore (gruppo-running gruppo))))
    (cambia-stato gruppo worker :terminato)))

(defun errore-worker (gruppo)
  (sb-thread:with-mutex ((gruppo-mutex gruppo))
    (loop for worker across (gruppo-worker gruppo)
          thereis (worker-errore worker))))

(defun barriera-semaforo (semaforo n)
  (dotimes (i n)
    (unless (sb-thread:wait-on-semaphore semaforo :timeout 5)
      (error "Timeout della barriera di ~D worker." n))))

(defun avvia-gruppo (gruppo)
  "Gli oggetti sono preallocati; cleanup del chiamante copre creazione parziale."
  (loop for worker across (gruppo-worker gruppo)
        do (let ((corrente worker))
             (setf (worker-thread corrente)
                   (sb-thread:make-thread (lambda () (corpo-worker gruppo corrente))
                                         :name "SPK02 worker"))))
  (let ((n (length (gruppo-worker gruppo))))
    (barriera-semaforo (gruppo-ready gruppo) n)
    (sb-thread:signal-semaphore (gruppo-start gruppo) n)
    (barriera-semaforo (gruppo-running gruppo) n)
    (when (errore-worker gruppo) (error (errore-worker gruppo)))
    (sb-thread:barrier (:memory))))

(defun ferma-e-join (gruppo)
  "Stop sotto mutex; risveglia anche thread ancora alla barriera e join di tutti."
  (let ((n (length (gruppo-worker gruppo))))
    (sb-thread:with-mutex ((gruppo-mutex gruppo)) (setf (gruppo-stop gruppo) t))
    (sb-thread:signal-semaphore (gruppo-start gruppo) n)
    (sb-thread:signal-semaphore (gruppo-wake gruppo) n)
    (loop for worker across (gruppo-worker gruppo)
          when (worker-thread worker)
            do (multiple-value-bind (valore stato)
                   (sb-thread:join-thread (worker-thread worker) :default :aborted)
                 (when (eq stato :abort)
                   (setf (worker-errore worker)
                         (make-condition 'simple-error :format-control
                                         "Worker abortito (~S)." :format-arguments
                                         (list valore)))))))
  ;; Join senza timeout: stop è sempre controllato fra batch limitati; attesa
  ;; semaforo <=50 ms. Nessun lock può essere tenuto durante il join.
  (when (errore-worker gruppo) (error (errore-worker gruppo))))

(defun nuovo-gruppo (n modo &optional inietta-errore)
  (make-gruppo :worker (map 'vector (lambda (i) (make-worker :indice i))
                           (loop for i below n collect i))
               :modo modo :inietta-errore inietta-errore))

(defun chiama-con-gruppo (gruppo funzione)
  (unwind-protect
       (progn (avvia-gruppo gruppo) (funcall funzione gruppo))
    (ferma-e-join gruppo)))

(defun riassumi-worker (gruppo)
  "Legge solo dopo join; i tempi sono richieste sintetiche, non pause GC."
  (let* ((worker (gruppo-worker gruppo))
         (capacita (* (length worker) 256))
         (latenze (prealloca-campioni capacita))
         (ritardi (prealloca-campioni capacita)))
    (dolist (coppia (list (cons latenze #'worker-latenze)
                          (cons ritardi #'worker-ritardi)))
      (loop for w across worker do
        (let ((origine (funcall (cdr coppia) w)))
          (dotimes (i (campioni-count origine))
            (registra (car coppia) (aref (campioni-dati origine) i)))
          (incf (campioni-scartati (car coppia)) (campioni-scartati origine))
          (when (campioni-massimo origine)
            (setf (campioni-massimo (car coppia))
                  (max (or (campioni-massimo (car coppia)) 0)
                       (campioni-massimo origine)))))))
    (list :joined (every (lambda (w) (not (sb-thread:thread-alive-p
                                          (worker-thread w)))) worker)
          :batches (loop for w across worker sum (worker-batch w))
          :sink (loop for w across worker sum (worker-sink w))
          :request-wall (riepilogo latenze) :scheduling-gap-wall (riepilogo ritardi))))

(defun simbolo-epoca ()
  "Capacità interna SBCL: identità, non contatore di collection."
  (let ((simbolo (find-symbol "*GC-EPOCH*" "SB-KERNEL")))
    (unless (and simbolo (boundp simbolo))
      (error "SBCL senza SB-KERNEL::*GC-EPOCH*: osservazione non supportata."))
    simbolo))

(defun istantanea-gc (epoca)
  "Lettura coerente: un GC fra contatore ed epoca provoca un tentativo nuovo."
  (loop repeat 32
        for prima = (symbol-value epoca)
        for tempo = (sb-thread:barrier (:read) sb-ext:*gc-real-time*)
        for dopo = (sb-thread:barrier (:read) (symbol-value epoca))
        when (eq prima dopo) return (values tempo dopo)
        finally (error "Impossibile acquisire un'istantanea GC coerente in 32 tentativi.")))

(defun osserva-delta (campioni prima dopo epoca-prima epoca-dopo)
  "Un campione aggrega una o più collection; anche delta zero è conservato."
  (when (< dopo prima) (error "Contatore GC reale non monotono."))
  (unless (eq epoca-prima epoca-dopo) (registra campioni (- dopo prima))))

(defun misura-overhead (epoca)
  "Baseline isolata del controller: osservazione+registrazione, byte misurati."
  (let ((dati (prealloca-campioni 256)) (destinazione (prealloca-campioni 272))
        (sink 0))
    (dotimes (i 16)
      (multiple-value-bind (tempo epoch) (istantanea-gc epoca)
        (setf sink tempo)
        (when epoch (registra destinazione 0))))
    (let ((byte-prima (sb-ext:get-bytes-consed))
          (inizio-totale (get-internal-real-time)))
      (dotimes (i 256)
        (let ((inizio (get-internal-real-time)))
          (multiple-value-bind (tempo epoch) (istantanea-gc epoca)
            (setf sink tempo)
            (when epoch (registra destinazione 0)))
          (registra dati (- (get-internal-real-time) inizio))))
      (let ((wall (- (get-internal-real-time) inizio-totale))
            (byte (- (sb-ext:get-bytes-consed) byte-prima)))
        (list :observation-and-recording-wall (riepilogo dati)
              :batch-wall-ms (millisecondi wall) :process-bytes-consed byte
              :sink sink :subtracted-from-gc-samples nil)))))

(defun misura-forzata (epoca tipo n deadline)
  "Delta runtime e durata wall distinta; nessuna attribuzione a stop-world."
  (let ((runtime (prealloca-campioni n)) (wall (prealloca-campioni n))
        (chiamate 0))
    (loop repeat n while (< (get-internal-real-time) deadline) do
      (multiple-value-bind (prima epoch-prima) (istantanea-gc epoca)
        (let ((inizio (get-internal-real-time)))
          (ecase tipo (:generation0 (sb-ext:gc :gen 0)) (:full (sb-ext:gc :full t)))
          (let ((fine (get-internal-real-time)))
            (multiple-value-bind (dopo epoch-dopo) (istantanea-gc epoca)
              (osserva-delta runtime prima dopo epoch-prima epoch-dopo)
              (registra wall (- fine inizio))
              (incf chiamate))))))
    (list :measurement-kind :forced-gc :requested tipo
          :call-count chiamate :call-wall (riepilogo wall)
          :runtime-collection-time (riepilogo runtime)
          :scope :cumulative-delta-per-observation-window
          :exact-stop-world-time nil :individual-collection-count nil)))

(defstruct carico
  (runtime (prealloca-campioni 4096) :type campioni :read-only t)
  (richieste (prealloca-campioni 4096) :type campioni :read-only t)
  (anello (make-array 16 :initial-element nil) :type simple-vector :read-only t)
  (passi 0 :type fixnum)
  (payload 0 :type fixnum)
  (rimpiazzi 0 :type fixnum)
  (bytes-rimpiazzati 0 :type fixnum))

(defun passo-carico (carico zona bytes-obiettivo)
  "Un chunk per passo; nessun backlog recuperato con un burst illimitato."
  (when (and (plusp bytes-obiettivo) (< (carico-payload carico) +transient-limit+)
             (< (carico-payload carico) bytes-obiettivo))
    (setf (aref (carico-anello carico) (mod (carico-passi carico) 16))
          (nuovo-array +allocation-bytes+))
    (incf (carico-payload carico) +allocation-bytes+))
  (when (and (eq (zona-layout zona) :heap-replacement)
             (< (carico-rimpiazzi carico) 32))
    (incf (carico-bytes-rimpiazzati carico)
          (sostituisci-frammento zona (carico-rimpiazzi carico)))
    (incf (carico-rimpiazzi carico)))
  (incf (carico-passi carico)))

(defun finestra-automatica (epoca zona gruppo tasso durata deadline)
  (let* ((carico (make-carico)) (inizio (get-internal-real-time))
         (fine-richiesta (+ inizio (ceiling (* durata internal-time-units-per-second))))
         (fine (min deadline fine-richiesta))
         (byte-prima (sb-ext:get-bytes-consed)) (gc-prima 0)
         (tempo-precedente 0) (epoch-precedente nil))
    (multiple-value-setq (gc-prima epoch-precedente) (istantanea-gc epoca))
    (setf tempo-precedente gc-prima)
    (loop repeat 100000 until (>= (get-internal-real-time) fine) do
      (when (errore-worker gruppo) (error (errore-worker gruppo)))
      (let* ((tempo (get-internal-real-time))
             (bytes-obiettivo (floor (* tasso (- tempo inizio))
                                     internal-time-units-per-second)))
        (passo-carico carico zona bytes-obiettivo)
        (registra (carico-richieste carico) (- (get-internal-real-time) tempo)))
      (multiple-value-bind (gc epoch) (istantanea-gc epoca)
        (osserva-delta (carico-runtime carico) tempo-precedente gc
                       epoch-precedente epoch)
        (setf tempo-precedente gc epoch-precedente epoch))
      ;; Limita la CPU del controller; l'attesa contribuisce al tasso osservato.
      (sleep 0.00025d0))
    (multiple-value-bind (gc epoch) (istantanea-gc epoca)
      (osserva-delta (carico-runtime carico) tempo-precedente gc epoch-precedente epoch)
      (let* ((wall (- (get-internal-real-time) inizio))
             (byte (- (sb-ext:get-bytes-consed) byte-prima))
             (secondi (/ wall internal-time-units-per-second))
             (finestre (+ (campioni-count (carico-runtime carico))
                           (campioni-scartati (carico-runtime carico)))))
        (list :measurement-kind :automatic-gc
              :duration-complete (>= (+ inizio wall) fine-richiesta)
              :requested-allocation-bytes-per-second tasso
              :wall-ms (millisecondi wall) :process-bytes-consed byte
              :process-allocation-bytes-per-second (when (plusp secondi) (/ byte secondi))
              :payload-allocated-bytes (carico-payload carico)
              :payload-bytes-per-second (when (plusp secondi)
                                         (/ (carico-payload carico) secondi))
              :replacement-count (carico-rimpiazzi carico)
              :replacement-bytes (carico-bytes-rimpiazzati carico)
              :controller-steps (carico-passi carico)
              :runtime-collection-time (riepilogo (carico-runtime carico))
              :total-runtime-collection-ms (millisecondi (- gc gc-prima))
              :collection-window-frequency-lower-bound-hz
              (when (plusp secondi) (/ finestre secondi))
              :controller-request-wall (riepilogo (carico-richieste carico))
              :scope :cumulative-delta-per-observation-window
              :individual-collection-count nil :exact-stop-world-time nil)))))

(defun misura-caso (zona epoca n modo tasso durata forzati deadline)
  (let ((gruppo (nuovo-gruppo n modo)) (risultato nil)
        (gen0 nil) (full nil) (automatico nil) (thread-processo 0))
    (chiama-con-gruppo gruppo
      (lambda (g)
        (setf thread-processo (length (sb-thread:list-all-threads))
              gen0 (misura-forzata epoca :generation0 forzati deadline)
              full (misura-forzata epoca :full forzati deadline)
              automatico (finestra-automatica epoca zona g tasso durata deadline)
              risultato
              (list :layout (zona-layout zona) :live-payload-bytes (zona-bytes zona)
                    :live-managed-payload-bytes
                    (if (eq (zona-layout zona) :foreign) 0 (zona-bytes zona))
                    :live-foreign-payload-bytes
                    (if (eq (zona-layout zona) :foreign) (zona-bytes zona) 0)
                    :worker-count n :worker-mode modo
                    :process-thread-count-at-ready thread-processo
                    :case-complete (and (= forzati (getf gen0 :call-count))
                                        (= forzati (getf full :call-count))
                                        (getf automatico :duration-complete))
                    :forced-gc (list :generation0 gen0 :full full)
                    :automatic-gc automatico
                    :live-sink (sink-zona zona)))))
    (append risultato (list :workers (riassumi-worker gruppo)))))

(defun valida-parametri (live-bytes thread-counts layouts rates modes
                         budget-seconds case-seconds forced-samples nursery-bytes)
  (unless (typep live-bytes '(integer 1 536870912))
    (error "live-bytes deve essere fra 1 e 512 MiB."))
  (unless (and thread-counts (<= (length thread-counts) 4)
               (every (lambda (n) (member n '(1 16 64 256))) thread-counts)
               (= (length thread-counts) (length (remove-duplicates thread-counts))))
    (error "thread-counts: sottoinsieme distinto di (1 16 64 256)."))
  (unless (and layouts (<= (length layouts) 4)
               (every (lambda (x) (member x '(:heap-large :heap-fragments
                                             :heap-replacement :foreign))) layouts))
    (error "Layout non supportato."))
  (unless (and rates (<= (length rates) 3)
               (every (lambda (x) (typep x '(integer 0 268435456))) rates))
    (error "Da uno a tre tassi, fra 0 e 256 MiB/s."))
  (unless (and modes (<= (length modes) 2)
               (every (lambda (x) (member x '(:work :semaphore))) modes))
    (error "Modo worker non supportato."))
  (unless (and (realp budget-seconds) (< 0 budget-seconds 16)
               (realp case-seconds) (< 0 case-seconds 2)
               (typep forced-samples '(integer 1 64))
               (typep nursery-bytes '(integer 1048576 67108864)))
    (error "Budget <=15s, finestra <2s, campioni 1..64, nursery 1..64 MiB."))
  t)

(defun profili (thread-counts rates modes)
  (loop for n in thread-counts append
    (loop for modo in modes append
      (loop for tasso in (if (eq modo :semaphore) '(0) rates)
            collect (list n modo tasso)))))

(defun ambiente (epoca)
  (list :lisp (lisp-implementation-type) :version (lisp-implementation-version)
        :os (software-type) :os-version (software-version)
        :machine (machine-type) :machine-version (machine-version)
        :collector-features (intersection '(:gencgc :mark-region-gc :sb-safepoint
                                           :sb-thread :64-bit) *features*)
        :internal-time-units-per-second internal-time-units-per-second
        :dynamic-space-bytes (sb-ext:dynamic-space-size)
        :bytes-consed-between-gcs (sb-ext:bytes-consed-between-gcs)
        :gc-real-time-source "SB-EXT:*GC-REAL-TIME*"
        :epoch-source (format nil "~A::~A" (package-name (symbol-package epoca))
                              (symbol-name epoca))
        :reference-hardware-conclusion nil))

;;; REQ: REQ-BEN-001 REQ-BEN-002 REQ-SIM-001 REQ-OBS-001
(defun benchmark (&key (live-bytes (* 128 +mib+)) (thread-counts '(1 16 64))
                    (layouts '(:heap-large :heap-fragments :heap-replacement :foreign))
                    (allocation-rates (list 0 (* 4 +mib+) (* 128 +mib+)))
                    (worker-modes '(:work :semaphore))
                    (budget-seconds 12) (case-seconds 0.08d0)
                    (forced-samples 3) (nursery-bytes (* 4 +mib+)))
  "Campagna limitata; plist di misure reali, nessuna certificazione di pause STW."
  (valida-parametri live-bytes thread-counts layouts allocation-rates worker-modes
                    budget-seconds case-seconds forced-samples nursery-bytes)
  (let* ((epoca (simbolo-epoca)) (vecchia-nursery (sb-ext:bytes-consed-between-gcs))
         (inizio (get-internal-real-time))
         (deadline (+ inizio (ceiling (* budget-seconds internal-time-units-per-second))))
         (profili (profili thread-counts allocation-rates worker-modes))
         (risultati nil) (overhead nil) (ambiente nil))
    (unwind-protect
         (progn
           (setf (sb-ext:bytes-consed-between-gcs) nursery-bytes)
           (setf ambiente (ambiente epoca) overhead (misura-overhead epoca))
           (loop for layout in layouts while (< (get-internal-real-time) deadline) do
             (chiama-con-zona layout live-bytes
               (lambda (zona)
                 ;; Riscaldamento/promozione: esplicitamente fuori dai campioni.
                 (sb-ext:gc :full t)
                 (sink-zona zona)
                 (loop for (n modo tasso) in profili
                       while (< (get-internal-real-time) deadline)
                       do (push (misura-caso zona epoca n modo tasso case-seconds
                                             forced-samples deadline) risultati))))))
      (setf (sb-ext:bytes-consed-between-gcs) vecchia-nursery))
    (let ((richiesti (* (length layouts) (length profili))))
      (list :status :ok :spike :spk02 :environment ambiente
            :live-payload-bytes live-bytes :fragment-bytes +fragment-bytes+
            :transient-payload-limit-per-case +transient-limit+
            :replacement-limit-per-case 32 :retained-transient-chunks 16
            :warmup (list :full-collections-per-layout 1 :worker-batches 4
                          :observation-iterations 16)
            :budget-seconds budget-seconds :deadline-policy :cooperative
            :actual-wall-ms (millisecondi (- (get-internal-real-time) inizio))
            :case-seconds case-seconds :forced-samples-requested forced-samples
            :requested-profiles profili :requested-layouts layouts
            :cases-requested richiesti :cases-run (length risultati)
            :cases-skipped (- richiesti (length risultati))
            :cases-truncated (count-if-not (lambda (r) (getf r :case-complete)) risultati)
            :complete (and (= richiesti (length risultati))
                           (every (lambda (r) (getf r :case-complete)) risultati))
            :benchmark-overhead overhead :measurements (nreverse risultati)))))

(define-condition fixture-error (error) ())

;;; REQ: REQ-BEN-001 REQ-BEN-002
(defun verifica-req-ben-001-quantili ()
  (let ((campioni (prealloca-campioni 4)))
    (assert (null (getf (riepilogo campioni) :p99)))
    (dolist (v '(4 1 3 2 999)) (registra campioni v))
    (let ((r (riepilogo campioni)))
      (assert (= 4 (getf r :count)))
      (assert (= 1 (getf r :dropped-count)))
      (assert (= (millisecondi 2) (getf r :p50)))
      (assert (= (millisecondi 4) (getf r :p99)))
      (assert (= (millisecondi 999) (getf r :max)))))
  t)

;;; REQ: REQ-SIM-001 REQ-AFF-016
(defun verifica-req-sim-001-memoria ()
  (dolist (layout '(:heap-large :heap-fragments :heap-replacement :foreign))
    (chiama-con-zona layout (+ +fragment-bytes+ 13)
      (lambda (zona)
        (let ((atteso (if (member layout '(:heap-fragments :heap-replacement)) 148 74)))
          (assert (= atteso (sink-zona zona)))
          (when (eq layout :heap-replacement)
            (assert (= 13 (sostituisci-frammento zona 1))))
          (sb-ext:gc :gen 0)
          (sb-ext:gc :full t)
          (assert (= atteso (sink-zona zona)))))))
  (let ((zona-uscita nil) (rilevato nil))
    (handler-case
        (chiama-con-zona :foreign 4097
          (lambda (zona) (setf zona-uscita zona) (error 'fixture-error)))
      (fixture-error () (setf rilevato t)))
    (assert rilevato)
    (assert (null (zona-foreign zona-uscita))))
  t)

;;; REQ: REQ-AFF-008 REQ-BEN-001
(defun verifica-req-aff-008-worker ()
  (dolist (modo '(:work :semaphore))
    (let ((gruppo (nuovo-gruppo 2 modo)))
      (chiama-con-gruppo gruppo
        (lambda (g)
          (sb-thread:with-mutex ((gruppo-mutex g))
            (assert (every (lambda (w) (eq (worker-stato w)
                                         (if (eq modo :work) :running :attesa)))
                           (gruppo-worker g))))))
      (assert (getf (riassumi-worker gruppo) :joined))))
  (let ((gruppo (nuovo-gruppo 2 :work t)) (rilevato nil))
    (handler-case (chiama-con-gruppo gruppo (lambda (g) (gruppo-stop g)))
      (error (c)
        (assert (search "errore worker iniettato" (princ-to-string c)))
        (setf rilevato t)))
    (assert rilevato)
    (assert (getf (riassumi-worker gruppo) :joined)))
  t)

;;; REQ: REQ-OBS-001 REQ-BEN-002
(defun verifica-req-obs-001-strumentazione ()
  (let ((epoca (simbolo-epoca)) (campioni (prealloca-campioni 3)))
    (let ((identita (list 1)))
      (osserva-delta campioni 7 7 identita identita)
      (assert (zerop (campioni-count campioni)))
      (osserva-delta campioni 7 7 identita (list 2))
      (osserva-delta campioni 7 10 identita (list 3))
      (assert (= 2 (campioni-count campioni)))
      (assert (zerop (aref (campioni-dati campioni) 0)))
      (assert (= 3 (aref (campioni-dati campioni) 1))))
    (let ((deadline (+ (get-internal-real-time) (* 5 internal-time-units-per-second))))
      (dolist (tipo '(:generation0 :full))
        (let ((r (misura-forzata epoca tipo 1 deadline)))
          (assert (= 1 (getf r :call-count)))
          (assert (= 1 (getf (getf r :runtime-collection-time) :count)))
          (assert (= 1 (getf (getf r :call-wall) :count)))))))
  t)

;;; REQ: REQ-AFF-003 REQ-AFF-008 REQ-BEN-001 REQ-SIM-001 REQ-OBS-001
(defun check ()
  "Fixture deterministiche; nessuna soglia prestazionale e nessuna campagna."
  (verifica-req-ben-001-quantili)
  (verifica-req-sim-001-memoria)
  (verifica-req-aff-008-worker)
  (verifica-req-obs-001-strumentazione)
  (list :status :ok :spike :spk02
        :checks '(:req-ben-001-quantili :req-sim-001-memoria
                  :req-aff-008-worker :req-obs-001-strumentazione)
        :performance-claims nil :maximum-fixture-live-payload-bytes
        (+ +fragment-bytes+ 13)))
