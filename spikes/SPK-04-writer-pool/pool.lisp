;;;; SPK-04: code limitate per Serie e tratti del writer su worker condivisi.
;;;; Esperimento C4; non implementa il motore, lo scheduler adattivo o l'I/O.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-003 REQ-CON-004 REQ-CON-005
;;; REQ: REQ-AFF-008 REQ-BEN-001 REQ-BEN-002 REQ-OBS-001
(defpackage #:arcdocdb.spk04.pool
  (:use #:cl)
  (:export #:check #:benchmark))
(in-package #:arcdocdb.spk04.pool)
(declaim (optimize (safety 3) (speed 2) (debug 1)))

(defconstant +max-operazioni+ 50000)
(defconstant +max-serie+ 64)
(defconstant +max-worker+ 16)
(defconstant +tentativi-mutex+ 100000)
(defconstant +timeout-join+ 10)

(define-condition pool-error (error)
  ((contesto :initarg :contesto :reader errore-contesto)
   (dettaglio :initarg :dettaglio :reader errore-dettaglio))
  (:report (lambda (condizione stream)
             (format stream "SPK-04 ~S: ~S."
                     (errore-contesto condizione) (errore-dettaglio condizione)))))

(defun esigi (condizione contesto dettaglio)
  "Un oracle fallito segnala un errore esplicito, mai un risultato parziale riuscito."
  (unless condizione
    (error 'pool-error :contesto contesto :dettaglio dettaglio)))

(defun prendi-mutex (mutex)
  "Acquisizione non bloccante: tetto di tentativi, esaurimento dichiarato."
  (loop for tentativo from 1 to +tentativi-mutex+
        when (sb-thread:grab-mutex mutex :waitp nil) do (return-from prendi-mutex tentativo)
        do (sb-thread:thread-yield))
  (error 'pool-error :contesto :mutex :dettaglio :attempt-limit))

;;; La macro serve durante compile-file; il FASL contiene soltanto le espansioni.
(eval-when (:compile-toplevel :execute)
(defmacro con-mutex-limitato ((mutex &optional contatore) &body corpo)
  "Elimina la sola ripetizione acquisizione/rilascio; nessuna attesa del tratto."
  (let ((oggetto (gensym "MUTEX")))
    `(let ((,oggetto ,mutex))
       ,(if contatore `(incf ,contatore (prendi-mutex ,oggetto))
            `(prendi-mutex ,oggetto))
       (unwind-protect (progn ,@corpo) (sb-thread:release-mutex ,oggetto))))))

;;; OWNER: produttori sotto mutex locale; un unico writer possiede lo stato elaborato.
;;; Nessuno slot della Serie è aggiornato mentre il mutex della lista pronta è tenuto.
(defstruct serie
  (indice 0 :type fixnum :read-only t)
  (mutex (sb-thread:make-mutex :name "SPK04 Serie") :type sb-thread:mutex :read-only t)
  (richieste (make-array 0 :element-type 'fixnum) :type (simple-array fixnum (*)) :read-only t)
  (sequenze (make-array 0 :element-type 'fixnum) :type (simple-array fixnum (*)) :read-only t)
  (viste (make-array 0 :element-type '(unsigned-byte 8))
         :type (simple-array (unsigned-byte 8) (*)) :read-only t)
  (testa 0 :type fixnum)
  (conteggio 0 :type fixnum)
  (accodate 0 :type fixnum)
  (elaborate 0 :type fixnum)
  (writer-attivo nil :type boolean)
  (proprietario -1 :type fixnum)
  (checksum 0 :type fixnum)
  (latenza-somma 0 :type integer)
  (latenza-massima 0 :type fixnum))

;;; OWNER: ogni worker modifica soltanto i propri contatori e il proprio errore.
(defstruct worker
  (indice 0 :type fixnum :read-only t)
  (thread nil :type (or null sb-thread:thread))
  (tratti 0 :type fixnum)
  (operazioni 0 :type fixnum)
  (tentativi-lock 0 :type fixnum)
  (errore nil :type (or null condition))
  (inietta-errore nil :type boolean :read-only t))

;;; OWNER: lista pronta sotto il proprio mutex, toccata ai confini dei tratti.
;;; SHARED: Lista delle Serie pronte; pop e requeue nella stessa sezione critica.
;;; STOP: controllo del solo harness, scritto soltanto su arresto o errore worker.
;;; Il carico viene sigillato prima dello start: nessun produttore durante il drain.
(defstruct pool
  (serie #() :type simple-vector :read-only t)
  (pronte (make-array 0 :element-type 'fixnum) :type (simple-array fixnum (*)) :read-only t)
  (mutex (sb-thread:make-mutex :name "SPK04 pronte") :type sb-thread:mutex :read-only t)
  (testa 0 :type fixnum)
  (conteggio 0 :type fixnum)
  (batch 1 :type fixnum :read-only t)
  (lavoro 0 :type fixnum :read-only t)
  (tratti 0 :type fixnum)
  (accessi-pronte 0 :type fixnum)
  (log-serie (make-array 0 :element-type 'fixnum) :type (simple-array fixnum (*)) :read-only t)
  (log-worker (make-array 0 :element-type 'fixnum) :type (simple-array fixnum (*)) :read-only t)
  (log-lunghezze (make-array 0 :element-type 'fixnum)
                 :type (simple-array fixnum (*)) :read-only t)
  (workers #() :type simple-vector)
  (stop nil :type boolean)
  (inizio 0 :type fixnum)
  (cronometro nil :type (or null function) :read-only t))

(defun nuova-serie (indice operazioni &optional (capacita operazioni))
  "Prealloca ring e bitmap di verifica: nessuna crescita durante il drain."
  (esigi (<= 1 capacita operazioni +max-operazioni+) :parametri :capacita)
  (make-serie :indice indice
              :richieste (make-array capacita :element-type 'fixnum :initial-element -1)
              :sequenze (make-array capacita :element-type 'fixnum :initial-element -1)
              :viste (make-array operazioni :element-type '(unsigned-byte 8) :initial-element 0)))

(defun accoda (serie richiesta)
  "Linearizza MPSC sotto il mutex della sola Serie. Saturazione senza mutare il ring."
  (esigi (and (typep richiesta 'fixnum) (<= 0 richiesta)
              (< richiesta (length (serie-viste serie)))) :accoda :richiesta)
  (con-mutex-limitato ((serie-mutex serie))
    (let ((capacita (length (serie-richieste serie))))
      (if (= (serie-conteggio serie) capacita)
          :resource-exhausted
          (let ((coda (mod (+ (serie-testa serie) (serie-conteggio serie)) capacita)))
            (setf (aref (serie-richieste serie) coda) richiesta
                  (aref (serie-sequenze serie) coda) (serie-accodate serie))
            (incf (serie-conteggio serie))
            (incf (serie-accodate serie))
            :accepted)))))

(defun estrai (serie worker)
  "Estrae in FIFO con contatore di tentativi locale al worker, senza lock globale."
  (con-mutex-limitato ((serie-mutex serie) (worker-tentativi-lock worker))
    (esigi (plusp (serie-conteggio serie)) :estrai :coda-vuota)
    (let* ((testa (serie-testa serie))
           (richiesta (aref (serie-richieste serie) testa))
           (sequenza (aref (serie-sequenze serie) testa)))
      (setf (aref (serie-richieste serie) testa) -1
            (aref (serie-sequenze serie) testa) -1
            (serie-testa serie) (mod (1+ testa) (length (serie-richieste serie))))
      (decf (serie-conteggio serie))
      (values richiesta sequenza))))

(defun nuovo-pool (conteggi batch lavoro &optional misura)
  "Alloca tutte le code e i log; una voce pronta iniziale per ogni Serie."
  (esigi (<= 1 (length conteggi) +max-serie+) :parametri :serie)
  (esigi (<= 1 batch +max-operazioni+) :parametri :batch)
  (esigi (<= 0 lavoro 10000) :parametri :lavoro)
  (let* ((n (length conteggi))
         (serie (make-array n :initial-element nil))
         (limite (loop for count across conteggi sum (ceiling count batch)))
         (pronte (make-array n :element-type 'fixnum :initial-element 0)))
    (dotimes (i n)
      (setf (aref serie i) (nuova-serie i (aref conteggi i)) (aref pronte i) i))
    (make-pool :serie serie :pronte pronte :conteggio n :batch batch :lavoro lavoro
               :log-serie (make-array limite :element-type 'fixnum :initial-element -1)
               :log-worker (make-array limite :element-type 'fixnum :initial-element -1)
               :log-lunghezze (make-array limite :element-type 'fixnum :initial-element 0)
               :cronometro (when misura #'get-internal-real-time))))

(defun preaccoda (pool)
  "Le richieste sono pronte prima dei worker; la misura esclude il generatore."
  (loop for serie across (pool-serie pool)
        do (dotimes (richiesta (length (serie-viste serie)))
             (esigi (eq :accepted (accoda serie richiesta)) :preaccoda :saturazione))))

(defun inserisci-pronta (pool indice)
  "Il chiamante possiede il mutex scheduler; non consulta né cambia dati di Serie."
  (let ((capacita (length (pool-pronte pool))))
    (esigi (< (pool-conteggio pool) capacita) :pronte :saturazione)
    (setf (aref (pool-pronte pool)
                (mod (+ (pool-testa pool) (pool-conteggio pool)) capacita)) indice)
    (incf (pool-conteggio pool))))

(defun prossimo-tratto (pool worker precedente pendente &optional soltanto-pubblica)
  "Un accesso scheduler per confine: riaccoda il tratto concluso e prende il prossimo."
  (con-mutex-limitato ((pool-mutex pool) (worker-tentativi-lock worker))
    (incf (pool-accessi-pronte pool))
    (when (and precedente pendente) (inserisci-pronta pool precedente))
    (when (and (not soltanto-pubblica) (plusp (pool-conteggio pool)))
      (let ((indice (aref (pool-pronte pool) (pool-testa pool)))
            (ordinal (pool-tratti pool)))
        (esigi (< ordinal (length (pool-log-serie pool))) :pronte :limite-tratti)
        (setf (pool-testa pool) (mod (1+ (pool-testa pool)) (length (pool-pronte pool))))
        (decf (pool-conteggio pool))
        (incf (pool-tratti pool))
        (setf (aref (pool-log-serie pool) ordinal) indice
              (aref (pool-log-worker pool) ordinal) (worker-indice worker))
        (values indice ordinal)))))

(defun acquisisci-gettone (serie worker)
  "Oracle di esclusività: due worker non possono possedere la stessa Serie."
  (con-mutex-limitato ((serie-mutex serie) (worker-tentativi-lock worker))
    (esigi (not (serie-writer-attivo serie)) :gettone :writer-concorrenti)
    (setf (serie-writer-attivo serie) t (serie-proprietario serie) (worker-indice worker))))

(defun rilascia-gettone (serie worker)
  "Rilascia il gettone locale dopo il completamento o l'errore del tratto."
  (con-mutex-limitato ((serie-mutex serie) (worker-tentativi-lock worker))
    (esigi (= (serie-proprietario serie) (worker-indice worker)) :gettone :proprietario)
    (setf (serie-writer-attivo serie) nil (serie-proprietario serie) -1)))

(defun lavoro-sintetico (valore iterazioni)
  "Costo controllato da un numero finito di iterazioni, con risultato osservato."
  (declare (type fixnum valore iterazioni))
  (dotimes (i iterazioni valore)
    (setf valore (logand #x3fffffff (logxor (+ valore 17 i) (ash valore -3))))))

(defun elabora-richiesta (pool serie worker)
  "FIFO e exactly-once verificati prima della mutazione dello stato del writer."
  (multiple-value-bind (richiesta sequenza) (estrai serie worker)
    (esigi (= sequenza (serie-elaborate serie)) :writer :fifo)
    (esigi (zerop (aref (serie-viste serie) richiesta)) :writer :richiesta-duplicata)
    (esigi (and (serie-writer-attivo serie)
                (= (serie-proprietario serie) (worker-indice worker))) :writer :gettone)
    (setf (serie-checksum serie)
          (logxor (serie-checksum serie) (lavoro-sintetico richiesta (pool-lavoro pool)))
          (aref (serie-viste serie) richiesta) 1)
    (incf (serie-elaborate serie))
    (incf (worker-operazioni worker))
    (when (pool-cronometro pool)
      (let ((latenza (- (funcall (pool-cronometro pool)) (pool-inizio pool))))
        (incf (serie-latenza-somma serie) latenza)
        (setf (serie-latenza-massima serie) (max latenza (serie-latenza-massima serie)))))))

(defun esegui-tratto (pool worker indice ordinal)
  "Nessuna sospensione: al più batch operazioni locali, nessuna scrittura globale."
  (let ((serie (aref (pool-serie pool) indice)))
    (acquisisci-gettone serie worker)
    (unwind-protect
         (let ((n (min (pool-batch pool) (serie-conteggio serie))))
           (esigi (plusp n) :tratto :vuoto)
           (dotimes (i n) (elabora-richiesta pool serie worker))
           ;; Slot del log assegnato una volta al worker, soltanto per tratto.
           (setf (aref (pool-log-lunghezze pool) ordinal) n)
           (incf (worker-tratti worker))
           (plusp (serie-conteggio serie)))
      (rilascia-gettone serie worker))))

(defun stop-richiesto-p (pool)
  (sb-thread:barrier (:read))
  (pool-stop pool))

(defun chiedi-stop (pool)
  "Solo controllo dell'harness, fuori dal percorso delle singole operazioni."
  (setf (pool-stop pool) t)
  (sb-thread:barrier (:write)))

(defun corpo-worker (pool worker limite limitato)
  "Ogni giro completa un tratto; un worker senza Serie pronta termina.
Il carico statico rende sicuro il ritiro: ogni Serie in corso resta al suo worker."
  (handler-case
      (let ((precedente nil) (pendente nil) (ritirato nil))
        ;; Iniezione prima della selezione: rilevata anche se altri worker hanno
        ;; già svuotato il carico quando questo thread viene schedulato.
        (when (worker-inietta-errore worker)
          (error 'pool-error :contesto :worker :dettaglio :injected))
        (dotimes (i limite)
          (when (stop-richiesto-p pool) (setf ritirato t) (return))
          (multiple-value-bind (indice ordinal)
              (prossimo-tratto pool worker precedente pendente)
            (setf precedente nil pendente nil)
            (unless indice (setf ritirato t) (return))
            (setf pendente (esegui-tratto pool worker indice ordinal) precedente indice)))
        (when (and precedente pendente (not (stop-richiesto-p pool)))
          (prossimo-tratto pool worker precedente t t))
        (esigi (or ritirato limitato) :worker :limite-tratti)
        :completed)
    (error (condizione)
      ;; Confine worker: errore conservato, arresto cooperativo e propagazione dopo join.
      (setf (worker-errore worker) condizione)
      (chiedi-stop pool)
      :failed)))

(defun join-limitato (thread)
  "Join del solo controller, con timeout diagnostico; nessun tempo prova correttezza."
  (multiple-value-bind (valore stato)
      (sb-thread:join-thread thread :timeout +timeout-join+ :default :join-failed)
    (esigi (not (eq valore :join-failed)) :join :timeout-or-abort)
    (esigi (not (sb-thread:thread-alive-p thread)) :join :timeout)
    (esigi (not (eq stato :abort)) :join (list :abort valore))
    valore))

(defun unisci-worker (pool)
  "Tenta tutti i join; un solo retry sui thread vivi dopo stop, senza occultare il timeout."
  (let ((errore nil))
    (loop for worker across (pool-workers pool)
          when (worker-thread worker)
            do (handler-case (join-limitato (worker-thread worker))
                 (error (condizione)
                   (unless errore (setf errore condizione))
                   (chiedi-stop pool))))
    (when errore
      (loop for worker across (pool-workers pool)
            when (and (worker-thread worker)
                      (sb-thread:thread-alive-p (worker-thread worker)))
              do (handler-case (join-limitato (worker-thread worker))
                   (error (condizione)
                     ;; Il primo errore resta osservabile anche se il retry riesce.
                     (when (sb-thread:thread-alive-p (worker-thread worker))
                       (error 'pool-error :contesto :join
                              :dettaglio (list :cleanup-incomplete
                                               (worker-indice worker) condizione errore)))))))
    (when errore (error errore))))

(defun avvia-pool (pool n &key (base 0) massimo-tratti inietta-errore)
  "Worker finiti; cleanup della creazione parziale, join e propagazione degli errori."
  (esigi (<= 1 n +max-worker+) :parametri :workers)
  (let* ((workers (make-array n :initial-element nil))
         (limite (or massimo-tratti (1+ (length (pool-log-serie pool))))))
    (dotimes (i n)
      (setf (aref workers i) (make-worker :indice (+ base i)
                             :inietta-errore (and inietta-errore (zerop i)))))
    (setf (pool-workers pool) workers)
    (unwind-protect
         (dotimes (i n)
           (let ((worker (aref workers i)))
             (setf (worker-thread worker)
                   (sb-thread:make-thread
                    (lambda () (corpo-worker pool worker limite (not (null massimo-tratti))))
                    :name "SPK04 worker"))))
      (unisci-worker pool))
    (let ((errore (loop for worker across workers thereis (worker-errore worker))))
      (when errore (error errore)))
    workers))

(defun verifica-pool (pool)
  "Oracle finale indipendente dall'ordine dei thread: tutte e sole le richieste una volta."
  (esigi (zerop (pool-conteggio pool)) :verifica :lista-non-vuota)
  (loop for serie across (pool-serie pool)
        do (esigi (= (serie-elaborate serie) (length (serie-viste serie))) :verifica :totale)
           (esigi (= (serie-accodate serie) (serie-elaborate serie)) :verifica :persa)
           (esigi (zerop (serie-conteggio serie)) :verifica :coda-non-vuota)
           (esigi (not (serie-writer-attivo serie)) :verifica :gettone-perso)
           (esigi (every (lambda (n) (= n 1)) (serie-viste serie)) :verifica :exactly-once))
  (esigi (every (lambda (worker) (not (sb-thread:thread-alive-p (worker-thread worker))))
                (pool-workers pool)) :verifica :thread-residuo)
  (dotimes (i (pool-tratti pool))
    (esigi (<= 1 (aref (pool-log-lunghezze pool) i) (pool-batch pool)) :verifica :tratto))
  :ok)

;;; REQ: REQ-AFF-008 REQ-CON-001
(defun test-req-aff-008-ring ()
  "Saturazione prima della mutazione, wrap-around e FIFO con ring di due slot."
  (let* ((serie (nuova-serie 0 4 2)) (worker (make-worker))
         (snapshot nil) (sequenze nil))
    (esigi (eq :accepted (accoda serie 0)) :test :prima)
    (esigi (eq :accepted (accoda serie 1)) :test :seconda)
    (setf snapshot (copy-seq (serie-richieste serie)) sequenze (copy-seq (serie-sequenze serie)))
    (esigi (eq :resource-exhausted (accoda serie 2)) :test :saturazione)
    (esigi (and (equalp snapshot (serie-richieste serie))
                (equalp sequenze (serie-sequenze serie))
                (= 2 (serie-conteggio serie) (serie-accodate serie))
                (zerop (serie-testa serie))) :test :mutazione-saturazione)
    (multiple-value-bind (richiesta sequenza) (estrai serie worker)
      (esigi (= 0 richiesta sequenza) :test :fifo-prima))
    (esigi (eq :accepted (accoda serie 2)) :test :wrap)
    (dolist (attesa '(1 2))
      (multiple-value-bind (richiesta sequenza) (estrai serie worker)
        (esigi (= attesa richiesta sequenza) :test :fifo-wrap)))
    (list :status :ok :capacity 2 :rejected 1 :wrapped t)))

(defun preaccoda-mpsc (pool)
  "Due produttori reali per Serie; intervalli di richieste disgiunti prima del drain."
  (let* ((n (* 2 (length (pool-serie pool))))
         (threads (make-array n :initial-element nil))
         (errori (make-array n :initial-element nil)))
    (unwind-protect
         (dotimes (i n)
           (let* ((indice i) (serie (aref (pool-serie pool) (floor i 2)))
                  (inizio (* (mod i 2) 32)))
             (setf (aref threads i)
                   (sb-thread:make-thread
                    (lambda ()
                      (handler-case
                          (dotimes (j 32)
                            (esigi (eq :accepted (accoda serie (+ inizio j))) :mpsc :saturazione))
                        (error (condizione) (setf (aref errori indice) condizione))))
                    :name "SPK04 produttore"))))
      (let ((join-error nil))
        (loop for thread across threads when thread
              do (handler-case (join-limitato thread)
                   (error (condizione) (unless join-error (setf join-error condizione)))))
        (when join-error (error join-error))))
    (let ((errore (find-if #'identity errori))) (when errore (error errore)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(defun test-req-con-001-mpsc ()
  "FIFO sull'ordine di accettazione locale e bitmap exactly-once con thread reali."
  (let ((pool (nuovo-pool (make-array 4 :element-type 'fixnum :initial-element 64) 7 32)))
    (preaccoda-mpsc pool)
    (avvia-pool pool 4)
    (verifica-pool pool)
    (esigi (= (+ (pool-tratti pool) 4) (pool-accessi-pronte pool)) :test :accessi-per-tratto)
    (list :status :ok :series 4 :producers 8 :workers 4 :operations 256
          :traits (pool-tratti pool) :ready-list-accesses (pool-accessi-pronte pool))))

;;; REQ: REQ-CON-001 REQ-CON-002
(defun test-req-con-002-ricambio ()
  "Staffetta deterministica: quattro tratti di una Serie su thread alternativamente nuovi."
  (let ((pool (nuovo-pool (make-array 1 :element-type 'fixnum :initial-element 4) 1 0)))
    (preaccoda pool)
    (dolist (indice '(0 1 0 1)) (avvia-pool pool 1 :base indice :massimo-tratti 1))
    (verifica-pool pool)
    (esigi (equalp #(0 1 0 1) (pool-log-worker pool)) :test :ricambio)
    (list :status :ok :worker-sequence '(0 1 0 1) :operations 4 :joined-thread-count 4)))

;;; REQ: REQ-CON-003 REQ-CON-004 REQ-CON-005
(defun test-req-con-003-burst ()
  "Un solo worker rende riproducibile la prova di equità strutturale, senza cronometro."
  (let ((pool (nuovo-pool (make-array 4 :element-type 'fixnum :initial-contents '(64 4 4 4)) 4 0)))
    (preaccoda pool)
    (avvia-pool pool 1)
    (verifica-pool pool)
    (esigi (equalp #(0 1 2 3) (subseq (pool-log-serie pool) 0 4)) :test :burst)
    (esigi (= 4 (aref (pool-log-lunghezze pool) 0)) :test :limite-hot)
    (list :status :ok :hot-operations 64 :cold-operations '(4 4 4)
          :first-traits '(0 1 2 3) :cold-complete-by-trait 4
          :bound :round-robin-traits :wall-time-guarantee nil)))

;;; REQ: REQ-CON-004 REQ-AFF-008
(defun test-req-con-004-errori ()
  "Errore worker osservato dal controller soltanto dopo i join di tutto il gruppo."
  (let ((pool (nuovo-pool (make-array 4 :element-type 'fixnum :initial-element 32) 4 0))
        (osservato nil))
    (preaccoda pool)
    (handler-case (avvia-pool pool 4 :inietta-errore t)
      (pool-error (condizione)
        (setf osservato (and (eq :worker (errore-contesto condizione))
                            (eq :injected (errore-dettaglio condizione))))))
    (esigi osservato :test :errore-perso)
    (esigi (every (lambda (worker) (not (sb-thread:thread-alive-p (worker-thread worker))))
                  (pool-workers pool)) :test :join-errori)
    (list :status :ok :propagated :injected :joined-thread-count 4)))

(declaim (ftype (function () list) check))
(defun check ()
  "Oracle deterministici, thread reali e nessuna durata usata come garanzia."
  (list :spike :spk-04 :module :writer-pool :status :ok
        :ring (test-req-aff-008-ring) :mpsc (test-req-con-001-mpsc)
        :worker-replacement (test-req-con-002-ricambio)
        :burst (test-req-con-003-burst) :worker-errors (test-req-con-004-errori)))

(defun conteggi-carico (numero totale scenario)
  "Carico finito: skewed assegna circa 3/4 del totale alla prima Serie."
  (esigi (<= numero totale +max-operazioni+) :parametri :operations)
  (let* ((conteggi (make-array numero :element-type 'fixnum :initial-element 1))
         (prima (ecase scenario
                  (:uniform 0)
                  (:skewed (if (= numero 1) 0
                               (min (- totale numero) (max 0 (1- (floor (* 3 totale) 4))))))))
         (inizio (if (and (eq scenario :skewed) (> numero 1)) 1 0))
         (destinatarie (- numero inizio))
         (restanti (- totale numero prima)))
    (incf (aref conteggi 0) prima)
    (dotimes (i destinatarie)
      (incf (aref conteggi (+ inizio i))
            (+ (floor restanti destinatarie) (if (< i (mod restanti destinatarie)) 1 0))))
    conteggi))

(defun secondi (ticks)
  (/ (coerce ticks 'double-float) (coerce internal-time-units-per-second 'double-float)))

(defun throughput (operazioni durata)
  "Nil se il cronometro non ha risoluzione sufficiente; nessun throughput inventato."
  (when (plusp durata) (/ operazioni durata)))

(defun report-serie (serie durata)
  (list :series (serie-indice serie) :operations (serie-elaborate serie)
        :operations-per-second (throughput (serie-elaborate serie) durata)
        :mean-completion-from-drain-start-seconds
        (secondi (/ (serie-latenza-somma serie) (serie-elaborate serie)))
        :max-completion-from-drain-start-seconds (secondi (serie-latenza-massima serie))
        :checksum (serie-checksum serie)))

(defun benchmark-caso (workers numero batch operazioni lavoro scenario)
  "Wall include start/join e oracle per richiesta; esclude preallocazione/generatore."
  (let* ((conteggi (conteggi-carico numero operazioni scenario))
         (pool (nuovo-pool conteggi batch lavoro t)))
    (preaccoda pool)
    (let ((bytes-inizio (sb-ext:get-bytes-consed)))
      (setf (pool-inizio pool) (funcall (pool-cronometro pool)))
      (avvia-pool pool workers)
      (let* ((ticks (- (funcall (pool-cronometro pool)) (pool-inizio pool)))
             (bytes (- (sb-ext:get-bytes-consed) bytes-inizio))
             (durata (secondi ticks)))
      (verifica-pool pool)
      (list :status :ok :scenario scenario :workers workers :series numero :batch batch
            :work-iterations lavoro :operations operazioni :wall-seconds durata
            :allocated-bytes bytes :allocation-scope :process-including-harness-and-concurrent-threads
            :operations-per-second (throughput operazioni durata) :traits (pool-tratti pool)
            :ready-list-accesses (pool-accessi-pronte pool)
            :ready-list-access-accounting :traits-plus-worker-retirements
            :lock-attempts (loop for worker across (pool-workers pool) sum (worker-tentativi-lock worker))
            :batch-one-role (when (= batch 1) :diagnostic-single-operation-traits)
            :per-series (map 'list (lambda (serie) (report-serie serie durata)) (pool-serie pool))
            :clock-resolution-seconds (secondi 1))))))

(declaim (ftype (function (&key (:workers list) (:series list) (:batches list)
                              (:operations integer) (:work integer) (:scenarios list)) list)
                benchmark))
(defun benchmark (&key (workers '(1 2 4)) (series '(1 4 16)) (batches '(1 8 64))
                      (operations 4096) (work 32) (scenarios '(:uniform :skewed)))
  "Campagna diagnostica locale e finita, con parametri riportati in ogni caso."
  (esigi (and (<= 1 (length workers) 16) (every (lambda (n) (<= 1 n +max-worker+)) workers))
          :parametri :workers)
  (esigi (and (<= 1 (length series) 64) (every (lambda (n) (<= 1 n +max-serie+)) series))
          :parametri :series)
  (esigi (and (<= 1 (length batches) 16) (every (lambda (n) (<= 1 n +max-operazioni+)) batches))
          :parametri :batches)
  (esigi (and (<= 1 (length scenarios) 2)
              (every (lambda (s) (member s '(:uniform :skewed))) scenarios)) :parametri :scenarios)
  (esigi (<= 1 operations +max-operazioni+) :parametri :operations)
  (esigi (<= 0 work 10000) :parametri :work)
  (let ((casi nil))
    (dolist (scenario scenarios)
      (dolist (numero series)
        (dolist (n workers)
          (dolist (batch batches)
            (push (benchmark-caso n numero batch operations work scenario) casi)))))
    (list :spike :spk-04 :module :writer-pool :status :ok
          :method :prequeued-bounded-drain :cases (nreverse casi)
          :limits (list :operations-per-case +max-operazioni+ :series +max-serie+
                        :workers +max-worker+ :mutex-attempts +tentativi-mutex+
                        :join-timeout-seconds +timeout-join+)
          :claims-scalability nil :claims-zero-allocation nil
          :excluded '(:adaptive-scheduler :live-producers :io :cbor :durability
                      :csn :horizon :epoch :snapshot-registry :client-parking)
          :completion-clock-origin :common-prequeued-drain-start
          :measurement-overhead '(:worker-start :join :fifo-oracle :exactly-once-oracle
                                  :per-operation-clock :try-lock-counter))))
