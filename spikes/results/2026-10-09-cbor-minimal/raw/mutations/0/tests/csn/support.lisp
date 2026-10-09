;;;; Oracolo CSN indipendente: interi matematici e lista dei soli token in volo.
(defpackage #:arcdocdb.csn.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted #:invariant-violation
                #:error-reason)
  (:import-from #:arcdocdb.csn #:registro-csn #:crea-registro-csn #:prendi-csn
                #:risolvi-csn #:leggi-frontiere-csn)
  (:export #:run))
(in-package #:arcdocdb.csn.tests)

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))

(defun run ()
  (dolist (test (reverse *tests*))
    (funcall test)
    (format t "ok    ~A~%" test))
  (format t "~D test del registro CSN superati.~%" (length *tests*))
  t)

(defconstant +csn-word-base+ 4294967296)
(defconstant +csn-test-maximum+ 18446744073709551615)

(defun csn-number (high low)
  "Solo harness: aritmetica anche bignum, mai helper aritmetici del prodotto."
  (+ (* high +csn-word-base+) low))

(defun csn-words (number)
  (floor number +csn-word-base+))

(defun csn-token-number (token)
  (csn-number (second token) (third token)))

;;; L'identita osservabile e (slot high low), legata dal chiamante al registro.
;;; Due registri con la stessa base possono emettere gli stessi tre numeri:
;;; il contratto non include un cookie di proprieta e non puo distinguerli.
;;; Gli oracoli delle API non leggono vettori o contatori del prodotto.
;;; Le sole fixture FI accedono ai privati per preparare e conservare un guasto.
(defstruct (csn-model (:constructor %make-csn-model (capacity last horizon)))
  capacity last horizon (live nil))

(defun csn-fixture (&key (capacity 3) (base 0))
  (multiple-value-bind (high low) (csn-words base)
    (values (crea-registro-csn :capacity capacity :initial-high high :initial-low low)
            (%make-csn-model capacity base base))))

(defun csn-frontiers (registry)
  (let ((result (multiple-value-list (leggi-frontiere-csn registry))))
    (is (= 4 (length result)))
    (is (every (lambda (word) (typep word '(unsigned-byte 32))) result))
    result))

(defun csn-check-model (registry model)
  "H = minimo dei pendenti meno uno, oppure ultimo; monotonia controllata ai passi."
  (let* ((actual (csn-frontiers registry))
         (last (csn-number (first actual) (second actual)))
         (horizon (csn-number (third actual) (fourth actual)))
         (live (csn-model-live model))
         (expected (if live (1- (reduce #'min live :key #'csn-token-number))
                       (csn-model-last model))))
    (is (= last (csn-model-last model)))
    (is (= horizon expected (csn-model-horizon model)))
    (is (<= 0 horizon last +csn-test-maximum+))
    (is (<= (length live) (csn-model-capacity model)))
    (is (= (length live) (length (remove-duplicates live :key #'first))))
    (is (= (length live) (length (remove-duplicates live :key #'csn-token-number))))
    (dolist (token live)
      (is (< horizon (csn-token-number token) (1+ last))))
    actual))

(defun csn-take (registry model)
  "Un rifiuto conserva frontiere e lista; ogni successo registra prima di esporre H."
  (cond
    ((= (length (csn-model-live model)) (csn-model-capacity model))
     (let ((before (csn-check-model registry model)))
       (signals resource-exhausted (prendi-csn registry) :csn-full)
       (is (equal before (csn-check-model registry model))))
     nil)
    ((= +csn-test-maximum+ (csn-model-last model))
     (let ((before (csn-check-model registry model)))
       (signals resource-exhausted (prendi-csn registry) :csn-exhausted)
       (is (equal before (csn-check-model registry model))))
     nil)
    (t
     (let ((token (multiple-value-list (prendi-csn registry))))
       (is (= 3 (length token)))
       (is (and (typep (first token) 'fixnum)
                (<= 0 (first token) (1- (csn-model-capacity model)))))
       (is (every (lambda (word) (typep word '(unsigned-byte 32))) (rest token)))
       (is (= (csn-token-number token) (1+ (csn-model-last model))))
       (is (not (assoc (first token) (csn-model-live model))))
       (incf (csn-model-last model))
       (push token (csn-model-live model))
       (csn-check-model registry model)
       token))))

(defun csn-resolve (registry model token)
  "La fixture ha pubblicato o validamente annullato gli effetti prima di chiamare."
  (is (member token (csn-model-live model) :test #'equal))
  (let ((before (csn-model-horizon model))
        (result (multiple-value-list
                 (risolvi-csn registry (first token) (second token) (third token)))))
    (is (= 2 (length result)))
    (is (every (lambda (word) (typep word '(unsigned-byte 32))) result))
    (setf (csn-model-live model) (remove token (csn-model-live model) :test #'equal :count 1))
    (let ((live (csn-model-live model)))
      (setf (csn-model-horizon model)
            (if live (1- (reduce #'min live :key #'csn-token-number))
                (csn-model-last model))))
    (is (<= before (csn-model-horizon model)))
    (is (= (csn-model-horizon model) (csn-number (first result) (second result))))
    (csn-check-model registry model)
    result))

(defun csn-reject-token (registry token)
  (let ((before (csn-frontiers registry)))
    (signals invalid-argument
      (risolvi-csn registry (first token) (second token) (third token)) :csn-token)
    (is (equal before (csn-frontiers registry))))
  t)

(defun csn-drain (registry model)
  (dolist (token (copy-list (csn-model-live model)))
    (csn-resolve registry model token))
  (is (null (csn-model-live model)))
  (is (= (csn-model-last model) (csn-model-horizon model)))
  t)

(defun csn-private-image (registry)
  "Solo FI: immagine dei campi per provare il rifiuto prima di ogni modifica.
Non calcola frontiere attese e non e usata come oracolo delle API sane."
  (list (arcdocdb.csn::registro-csn-used registry)
        (arcdocdb.csn::registro-csn-cursor registry)
        (arcdocdb.csn::registro-csn-last-high registry)
        (arcdocdb.csn::registro-csn-last-low registry)
        (arcdocdb.csn::registro-csn-horizon-high registry)
        (arcdocdb.csn::registro-csn-horizon-low registry)
        (copy-seq (arcdocdb.csn::registro-csn-highs registry))
        (copy-seq (arcdocdb.csn::registro-csn-lows registry))))

(defun csn-invariant-refusal (registry thunk reason)
  (let ((before (csn-private-image registry)))
    (signals invariant-violation (funcall thunk) reason)
    (is (equalp before (csn-private-image registry)))
    (is (null (sb-thread:mutex-owner (arcdocdb.csn::registro-csn-mutex registry)))))
  t)

(defun csn-replay (capacity actions)
  "Replay su un registro nuovo: niente rollback o clonazione della rappresentazione."
  (multiple-value-bind (registry model) (csn-fixture :capacity capacity)
    (csn-check-model registry model)
    (dolist (action actions)
      (if (eq action :take)
          (is (csn-take registry model))
          (let ((token (find action (csn-model-live model) :key #'csn-token-number)))
            (is token)
            (csn-resolve registry model token))))
    ;; Anche nei prefissi saturi un tentativo fallito non crea buchi nel CSN.
    (when (= capacity (length (csn-model-live model)))
      (is (null (csn-take registry model))))
    (csn-check-model registry model)
    t))

(defun csn-explore (capacity commits)
  "Tutti i prefissi di assegnazione/risoluzione, senza deduplicare storie diverse.
Le scelte derivano da interi/lista; la selezione degli slot e lasciata al prodotto."
  (let ((prefixes 0) (complete 0) (maximum-depth 0))
    (labels ((visit (last live reversed-actions)
               (incf prefixes)
               (setf maximum-depth (max maximum-depth (length reversed-actions)))
               (csn-replay capacity (reverse reversed-actions))
               (when (and (= commits last) (null live)) (incf complete))
               (when (and (< last commits) (< (length live) capacity))
                 (visit (1+ last) (cons (1+ last) live) (cons :take reversed-actions)))
               (dolist (pending live)
                 (visit last (remove pending live) (cons pending reversed-actions)))))
      (visit 0 nil nil))
    (is (plusp complete))
    (is (= (* 2 commits) maximum-depth))
    (format t "  CSN: K=~D, ~D commit, ~D prefissi, ~D storie complete.~%"
            capacity commits prefixes complete)
    (values prefixes complete)))

(defun csn-deadline (&optional (seconds 20))
  (+ (get-internal-real-time) (* seconds internal-time-units-per-second)))

(defun csn-seconds-left (deadline)
  (let ((remaining (- deadline (get-internal-real-time))))
    (unless (plusp remaining) (error "Budget temporale della fixture CSN esaurito."))
    (/ remaining (float internal-time-units-per-second 1d0))))

(defun csn-wait (semaphore deadline)
  (unless (sb-thread:wait-on-semaphore semaphore :timeout (csn-seconds-left deadline))
    (error "Semaforo della fixture CSN oltre il limite."))
  t)

(defun csn-worker (name thunk)
  "Il worker restituisce l'errore al join, che lo rilancia nel thread del runner."
  (sb-thread:make-thread
   (lambda () (handler-case (funcall thunk) (error (condition) condition))) :name name))

(defun csn-join (thread deadline)
  (let ((result (sb-thread:join-thread thread :timeout (csn-seconds-left deadline)
                                           :default :csn-timeout)))
    (when (typep result 'error) (error result))
    (is (eq result :ok))
    result))

(defun csn-stop-workers (threads)
  "Cleanup limitato anche dopo errori: solo worker creati dalla fixture."
  (dolist (thread threads)
    (when (sb-thread:thread-alive-p thread) (sb-thread:terminate-thread thread))
    (sb-thread:join-thread thread :timeout 1 :default :csn-terminated)
    (is (not (sb-thread:thread-alive-p thread))))
  nil)

(defun csn-retry (thunk deadline reasons &optional refused)
  "Retry solo dell'harness; il prodotto deve effettuare un singolo try-lock."
  (loop
    (csn-seconds-left deadline)
    (handler-case (return (funcall thunk))
      (resource-exhausted (condition)
        (is (member (error-reason condition) reasons))
        (when refused (funcall refused (error-reason condition)))))
    (sb-thread:thread-yield)))

(defun call-with-csn-held-guard (registry thunk)
  "FI: un worker trattiene il mutex; un altro deve concludere prima del rilascio.
Join e semafori hanno lo stesso limite: un mutante bloccante non ferma il runner."
  (let ((held (sb-thread:make-semaphore)) (release (sb-thread:make-semaphore))
        (deadline (csn-deadline 5)) (threads nil))
    (unwind-protect
         (progn
           (push (csn-worker
                  "CSN guard holder"
                  (lambda ()
                    ;; L'unico accessor privato serve a forzare la contesa.
                    (sb-thread:with-mutex ((arcdocdb.csn::registro-csn-mutex registry))
                      (sb-thread:signal-semaphore held)
                      (csn-wait release deadline))
                    :ok)) threads)
           (csn-wait held deadline)
           (push (csn-worker "CSN nonblocking probe"
                             (lambda () (funcall thunk) :ok)) threads)
           (csn-join (first threads) deadline)
           (sb-thread:signal-semaphore release)
           (csn-join (second threads) deadline))
      (sb-thread:signal-semaphore release)
      (csn-stop-workers threads)))
  t)
