;;;; Controller Serie: sensore C4; metodo preregistrato prima dell'esecuzione.
;;;; --self-test|--bench [--output-dir spikes/out/UNIQUE/] SOLO a sorgenti congelati.
;;; REQ: REQ-WAL-002 REQ-WAL-005 REQ-MVC-008 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002 REQ-VAL-001
;;; OWNER: main possiede API/rapporti; ciascun worker possiede un Archivio simulato.
;;; SHARED: solo i gate del sensore; nessun registro/log/controller condiviso tra worker.
(require :asdf)
(require :sb-posix)
(defpackage #:arcdocdb.series-controller.bench (:use #:cl))
(in-package #:arcdocdb.series-controller.bench)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defconstant +initial-iterations+ 20000)
(defconstant +maximum-iterations+ 320000)
(defconstant +maximum-attempts+ 5)
(defconstant +minimum-ticks+ 20)
(defconstant +warmup+ 1024)
(defconstant +samples+ 5)
(defconstant +parallel-replicas+ 3)
(defconstant +deadline-seconds+ 30)
(defconstant +capacity+ 256)
(defconstant +event-capacity+ 64)
(defconstant +positive-bytes+ 1048576)
;; U64 preboxed una volta; i CSN nel clock rimangono due limb fixnum.
(defconstant +file-id+ #xffffffffffffffff)
(defconstant +root-a+ :series-bench-root-a)
(defconstant +root-b+ :series-bench-root-b)
(declaim (ftype (function (list list) t) require-fields))

(defstruct (api (:copier nil))
  "Tabella immutabile risolta solo dopo il build rigoroso del checkout congelato."
  (registry #'identity :type function :read-only t)
  (frontiers #'identity :type function :read-only t)
  (lotto #'identity :type function :read-only t)
  (add-record #'identity :type function :read-only t)
  (seal #'identity :type function :read-only t)
  (read-token #'identity :type function :read-only t)
  (token-state #'identity :type function :read-only t)
  (lotto-state #'identity :type function :read-only t)
  (length #'identity :type function :read-only t)
  (buffer #'identity :type function :read-only t)
  (log #'identity :type function :read-only t)
  (log-state #'identity :type function :read-only t)
  (group #'identity :type function :read-only t)
  (add-lotto #'identity :type function :read-only t)
  (close-group #'identity :type function :read-only t)
  (execute #'identity :type function :read-only t)
  (reuse-group #'identity :type function :read-only t)
  (group-state #'identity :type function :read-only t)
  (covered #'identity :type function :read-only t)
  (backend #'identity :type function :read-only t)
  (file #'identity :type function :read-only t)
  (close-file #'identity :type function :read-only t)
  (written #'identity :type function :read-only t)
  (durable #'identity :type function :read-only t)
  (controller #'identity :type function :read-only t)
  (acquire #'identity :type function :read-only t)
  (release #'identity :type function :read-only t)
  (adopt #'identity :type function :read-only t)
  (start-io #'identity :type function :read-only t)
  (complete-io #'identity :type function :read-only t)
  (publish #'identity :type function :read-only t)
  (reuse-event #'identity :type function :read-only t)
  (root #'identity :type function :read-only t)
  (health #'identity :type function :read-only t)
  (fault-scope #'identity :type function :read-only t)
  (event-state #'identity :type function :read-only t)
  (event-token #'identity :type function :read-only t)
  (counts #'identity :type function :read-only t)
  (u32 #'identity :type function :read-only t)
  (reason #'identity :type function :read-only t)
  (product-error nil :type symbol :read-only t)
  (resource-error nil :type symbol :read-only t)
  (stamp-offset 0 :type fixnum :read-only t)
  (seal-total 0 :type fixnum :read-only t)
  (record-total 0 :type fixnum :read-only t))

(define-condition pending-publication (error) ()
  (:report (lambda (condition stream)
             (declare (ignore condition))
             (write-string "tools/series-controller-bench.lisp COD-61: pubblicazione :pendente; zero retry." stream))))

(define-condition sensor-rejection (error)
  ((reason :initarg :reason :reader sensor-reason :type keyword)
   (detail :initarg :detail :initform nil :reader sensor-detail :type t))
  (:report (lambda (condition stream)
             (format stream "tools/series-controller-bench.lisp ~A: ~S ~S."
                     (if (eq (sensor-reason condition) :heap-nonzero) "COD-30" "COD-61")
                     (sensor-reason condition) (sensor-detail condition)))))

(defun product-function (package name &optional (visibility :external))
  "API assente o non esportata: fallimento C4 prima del clock."
  (multiple-value-bind (symbol actual) (find-symbol name package)
    (unless (and symbol (eq visibility actual) (fboundp symbol))
      (error "tools/series-controller-bench.lisp COD-61: API assente ~A:~A." package name))
    (symbol-function symbol)))

(defun product-constant (package name)
  "Legge le costanti del formato senza duplicarne i valori nel sensore."
  (let ((symbol (find-symbol name package)))
    (unless (and symbol (boundp symbol) (typep (symbol-value symbol) 'fixnum))
      (error "tools/series-controller-bench.lisp COD-61: costante assente ~A:~A." package name))
    (symbol-value symbol)))

(defun isolate-fasl (out)
  "Pre: ASD caricato. Post: ogni sorgente ricorsivo tradotto nella cache esclusiva."
  (let* ((root (truename "./")) (destination (merge-pathnames "fasl/" out))
         (product (sort (directory "src/**/*.lisp") #'string< :key #'namestring)))
    (unless product (error "tools/series-controller-bench.lisp COD-61: sorgenti assenti."))
    (ensure-directories-exist (merge-pathnames "placeholder" destination))
    (asdf:initialize-output-translations
     `(:output-translations
       (,(merge-pathnames "**/*.*" root) ,(merge-pathnames "**/*.*" destination))
       :ignore-inherited-configuration))
    (loop for source in (cons (truename "tools/series-controller-bench.lisp") product)
          for translated = (asdf:apply-output-translations (make-pathname :type "fasl" :defaults source))
          do (unless (uiop:subpathp translated destination)
               (error "tools/series-controller-bench.lisp COD-61: FASL non isolato ~A." source))
          collect (list :source (enough-namestring source) :fasl (namestring translated)))))

(defun compile-driver (out)
  "Compila anche C4 dopo ASD/prodotto; non carica il FASL e non esegue main."
  (let ((destination
          (asdf:apply-output-translations
           (merge-pathnames "tools/series-controller-bench.fasl" (truename "./")))))
    (unless (uiop:subpathp destination (merge-pathnames "fasl/" out))
      (error "tools/series-controller-bench.lisp COD-61: FASL driver non isolato."))
    (ensure-directories-exist destination)
    (multiple-value-bind (fasl warnings failed)
        (compile-file "tools/series-controller-bench.lisp" :output-file destination)
      (unless (and fasl (not warnings) (not failed))
        (error "tools/series-controller-bench.lisp COD-01: compilazione C4 non rigorosa."))
      (namestring (truename fasl)))))

(defun resolve-api ()
  "Nessun find-symbol o caricamento di codice nel percorso misurato."
  (flet ((wal (name) (product-function "ARCDOCDB.WAL" name))
         (io (name) (product-function "ARCDOCDB.IO" name))
         (serie (name) (product-function "ARCDOCDB.SERIES" name)))
    (let* ((header (product-constant "ARCDOCDB.RECORD" "+HEADER-BYTES+"))
           (seal (+ header (product-constant "ARCDOCDB.RECORD" "+SEAL-BYTES+"))))
      (make-api
       :registry (product-function "ARCDOCDB.CSN" "CREA-REGISTRO-CSN")
       :frontiers (product-function "ARCDOCDB.CSN" "LEGGI-FRONTIERE-CSN")
       :lotto (wal "CREA-LOTTO") :add-record (wal "AGGIUNGI-RECORD")
       :seal (wal "SIGILLA-LOTTO-CON-CSN") :read-token (wal "LEGGI-CSN-LOTTO")
       :token-state (wal "STATO-CSN-LOTTO") :lotto-state (wal "STATO-LOTTO")
       :length (wal "LUNGHEZZA-LOTTO") :buffer (product-function "ARCDOCDB.WAL" "LOTTO-BUFFER" :internal)
       :log (wal "CREA-LOG-IO") :log-state (wal "STATO-LOG")
       :group (wal "CREA-GRUPPO") :add-lotto (wal "AGGIUNGI-LOTTO")
       :close-group (wal "CHIUDI-GRUPPO") :execute (wal "ESEGUI-GRUPPO")
       :reuse-group (wal "RIUSA-GRUPPO") :group-state (wal "STATO-GRUPPO")
       :covered (wal "COPERTO-P") :backend (io "MAKE-BACKEND")
       :file (io "CREA-TEMPORANEO") :close-file (io "CHIUDI")
       :written (io "POSIZIONE-SCRITTA") :durable (io "POSIZIONE-DUREVOLE")
       :controller (serie "CREA-CONTROLLORE-SERIE") :acquire (serie "ACQUISISCI-CONTROLLORE-SERIE")
       :release (serie "RILASCIA-CONTROLLORE-SERIE") :adopt (serie "REGISTRA-COMMIT-SERIE")
       :start-io (serie "INIZIA-IO-COMMIT-SERIE") :complete-io (serie "COMPLETA-IO-COMMIT-SERIE")
       :publish (serie "PUBBLICA-COMMIT-SERIE") :reuse-event (serie "RIUSA-COMMIT-SERIE")
       :root (serie "LEGGI-RADICE-SERIE") :health (serie "STATO-CONTROLLORE-SERIE")
       :fault-scope (serie "AMBITO-FAULT-SERIE") :event-state (serie "STATO-COMMIT-SERIE")
       :event-token (serie "LEGGI-CSN-COMMIT-SERIE") :counts (serie "CONTA-COMMIT-SERIE")
       :u32 (product-function "ARCDOCDB.BINARY" "LEGGI-U32")
       :reason (product-function "ARCDOCDB.CONDITIONS" "ERROR-REASON")
       :product-error (find-symbol "ARCDOCDB-ERROR" "ARCDOCDB.CONDITIONS")
       :resource-error (find-symbol "RESOURCE-EXHAUSTED" "ARCDOCDB.CONDITIONS")
       :stamp-offset (product-constant "ARCDOCDB.RECORD" "+STAMP-OFFSET+")
       :seal-total seal :record-total (+ header 16 64 seal)))))

(defun load-product (out report)
  "ASD, cache ricorsiva, build senza warning, poi tabella API; log sempre conservato."
  (setf asdf:*compile-file-failure-behaviour* :error
        asdf:*compile-file-warnings-behaviour* :error)
  (let ((build (getf report :build)))
    (setf (getf build :status) :running (getf build :phase) :load-asd)
    (with-open-file (stream (merge-pathnames "build.log" out) :direction :output
                           :if-exists :error :if-does-not-exist :create :external-format :utf-8)
      (let ((*standard-output* stream) (*error-output* stream))
        (handler-bind ((warning (lambda (condition) (error condition))))
          (asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
          (setf (getf build :phase) :output-translations)
          (setf (getf build :fasl-mapping) (isolate-fasl out))
          (setf (getf build :phase) :compile-product)
          (asdf:load-system "arcdocdb" :force t)
          (setf (getf build :phase) :compile-driver
                (getf build :driver-fasl) (compile-driver out))
          (setf (getf build :status) :compiled (getf build :phase) :resolve-api)
          (let ((api (resolve-api)))
            (unless (and (api-product-error api) (api-resource-error api))
              (error "tools/series-controller-bench.lisp COD-61: condizioni API assenti."))
            (setf (getf build :api-status) :resolved (getf build :status) :ok (getf build :phase) :complete)
            api))))))

(defstruct (fixture (:copier nil))
  "Oggetti preallocati di un Archivio; lease solo nel thread che esegue il tratto."
  (api nil :type (or null api) :read-only t)
  (registry nil :type t) (lotto nil :type t) (file nil :type t)
  (log nil :type t) (group nil :type t) (buffer nil :type t) (controller nil :type t)
  (key (make-array 16 :element-type '(unsigned-byte 8) :initial-element 17)
       :type (simple-array (unsigned-byte 8) (16)) :read-only t)
  (value (make-array 64 :element-type '(unsigned-byte 8) :initial-element 42)
         :type (simple-array (unsigned-byte 8) (64)) :read-only t)
  ;; Token WAL catturato prima dell'adozione: registry, slot, high, low, end.
  (descriptor (make-array 5 :initial-element nil) :type simple-vector :read-only t)
  (events (make-array +event-capacity+ :initial-element nil) :type simple-vector :read-only t)
  (generations (make-array +event-capacity+ :element-type 'fixnum :initial-element 0)
               :type (simple-array fixnum (64)) :read-only t)
  (seen 0 :type fixnum) (event nil :type t) (generation 0 :type fixnum)
  (lease 0 :type fixnum) (run-lease 0 :type fixnum) (root +root-a+ :type symbol)
  (count 0 :type fixnum) (unresolved 0 :type fixnum) (active-io 0 :type fixnum)
  (high 0 :type (unsigned-byte 32)) (low 0 :type (unsigned-byte 32))
  (cycles 0 :type fixnum) (writes 0 :type fixnum) (flushes 0 :type fixnum)
  (bytes 0 :type fixnum) (adoptions 0 :type fixnum) (publications 0 :type fixnum)
  (retirements 0 :type fixnum)
  (publication-status :not-attempted :type keyword)
  (returned-high 0 :type (unsigned-byte 32)) (returned-low 0 :type (unsigned-byte 32)))

(defun close-fixture (fixture)
  "Pre: worker terminato. Post: file simulato chiuso, nessun rollback del token."
  (when (fixture-file fixture)
    (unless (null (funcall (api-close-file (fixture-api fixture)) (fixture-file fixture)))
      (error "tools/series-controller-bench.lisp COD-61: chiusura file incoerente."))))

(defun new-fixture (api high low)
  "Preallocazione fuori dal clock; nessun descrittore nativo dati aperto."
  (let* ((fixture (make-fixture :api api :high high :low low))
         (backend
           (funcall (api-backend api)
                    (lambda (name mode) (declare (ignore name mode)) 7)
                    (lambda (&rest args) (error "Read simulata inattesa: ~S." args))
                    (lambda (fd buffer start count)
                      (declare (ignore fd))
                      (unless (and (eq buffer (fixture-buffer fixture)) (zerop start)
                                   (= count (api-record-total api)))
                        (error "tools/series-controller-bench.lisp COD-61: write incoerente."))
                      (incf (fixture-writes fixture)) (incf (fixture-bytes fixture) count) count)
                    (lambda (fd) (declare (ignore fd)) (incf (fixture-flushes fixture)) 0)
                    (lambda (&rest args) (error "Flush directory inatteso: ~S." args))
                    (lambda (fd) (declare (ignore fd)) 0))))
    (setf (fixture-registry fixture)
          (funcall (api-registry api) :capacity +capacity+ :initial-high high :initial-low low)
          (fixture-lotto fixture) (funcall (api-lotto api) :segment +file-id+ :capacity 512 :max-records 1)
          (fixture-buffer fixture) (funcall (api-buffer api) (fixture-lotto fixture))
          (fixture-file fixture) (funcall (api-file api) "series-controller-bench.tmp" :backend backend
                                          :max-transfer 512 :max-file-bytes most-positive-fixnum))
    (handler-case
        (setf (fixture-log fixture) (funcall (api-log api) (fixture-file fixture) :segment +file-id+)
              (fixture-group fixture) (funcall (api-group api) (fixture-log fixture) :max-lots 1 :max-bytes 512)
              (fixture-controller fixture)
              (funcall (api-controller api) (fixture-registry fixture) (fixture-log fixture)
                       :root +root-a+ :next-offset 0))
      (error (condition) (close-fixture fixture) (error condition)))
    fixture))

(defun acquire-fixture (fixture)
  "Pre: thread proprietario, nessuna lease. Post: lease positiva per tutto il tratto."
  (unless (zerop (fixture-lease fixture)) (error "Lease fixture già acquisita."))
  (let ((lease (funcall (api-acquire (fixture-api fixture)) (fixture-controller fixture))))
    (unless (and (typep lease 'fixnum) (plusp lease)) (error "Lease controller invalida."))
    (setf (fixture-lease fixture) lease (fixture-run-lease fixture) lease))
  nil)

(defun release-fixture (fixture)
  "Pre: stesso thread del tratto concluso. Post: lease rilasciata fuori dal clock."
  (when (plusp (fixture-lease fixture))
    (unless (null (funcall (api-release (fixture-api fixture))
                          (fixture-controller fixture) (fixture-lease fixture)))
      (error "Rilascio lease controller incoerente."))
    (setf (fixture-lease fixture) 0))
  nil)

(declaim (inline next-pair))
(defun next-pair (high low)
  "Successore indipendente su due u32, entro il dominio preregistrato."
  (declare (type (unsigned-byte 32) high low))
  (if (= low #xffffffff) (values (1+ high) 0) (values high (1+ low))))

(defun check-counts (fixture count unresolved active)
  "Oracolo sotto lease nel clock; conserva l'ultimo triplo osservato anche su errore."
  (multiple-value-bind (actual pending io)
      (funcall (api-counts (fixture-api fixture)) (fixture-controller fixture) (fixture-lease fixture))
    (setf (fixture-count fixture) actual (fixture-unresolved fixture) pending (fixture-active-io fixture) io)
    (unless (and (= actual count) (= pending unresolved) (= io active))
      (error "tools/series-controller-bench.lisp COD-61: conteggi controller incoerenti."))))

(defun check-stamp (fixture position high low)
  "Legge entrambi i limb nel buffer; nessun u64 CSN ricostruito."
  (let* ((api (fixture-api fixture)) (buffer (fixture-buffer fixture))
         (offset (+ position (api-stamp-offset api))))
    (unless (and (= (funcall (api-u32 api) buffer offset) low)
                 (= (funcall (api-u32 api) buffer (+ offset 4)) high))
      (error "tools/series-controller-bench.lisp COD-61: stamp record/SEAL errato."))))

(defun seal-cycle (fixture)
  "PUT e SEAL; token WAL catturato in un descrittore già allocato."
  (let* ((api (fixture-api fixture)) (lotto (fixture-lotto fixture))
         (file (fixture-file fixture)) (registry (fixture-registry fixture))
         (descriptor (fixture-descriptor fixture)))
    (unless (eq (funcall (api-token-state api) lotto) :libero) (error "Token non libero."))
    (multiple-value-bind (high low) (next-pair (fixture-high fixture) (fixture-low fixture))
      (setf (fixture-high fixture) high (fixture-low fixture) low))
    (unless (= (funcall (api-add-record api) lotto 1 (fixture-key fixture) (fixture-value fixture))
               (- (api-record-total api) (api-seal-total api)))
      (error "Lunghezza PUT inattesa."))
    (multiple-value-bind (used high low)
        (funcall (api-seal api) lotto registry (fixture-log fixture)
                 (funcall (api-written api) file) (funcall (api-durable api) file))
      (unless (and (= used (api-record-total api)) (= high (fixture-high fixture))
                   (= low (fixture-low fixture)) (eq (funcall (api-lotto-state api) lotto) :sealed)
                   (eq (funcall (api-token-state api) lotto) :pendente))
        (error "CSN o lotto sealed incoerente."))
      (multiple-value-bind (slot token-high token-low) (funcall (api-read-token api) lotto)
        (unless (and (typep slot 'fixnum) (<= 0 slot) (< slot +capacity+)
                     (= token-high high) (= token-low low)) (error "Token WAL incoerente."))
        (setf (svref descriptor 0) registry (svref descriptor 1) slot
              (svref descriptor 2) high (svref descriptor 3) low
              (svref descriptor 4) (+ (funcall (api-written api) file) used)))
      (check-stamp fixture 0 high low)
      (check-stamp fixture (- used (api-seal-total api)) high low))))

(defun remember-event (fixture event generation)
  "Identità preallocate, ricerca <=64; ogni riuso richiede una generazione superiore."
  (unless (and event (typep generation 'fixnum) (plusp generation))
    (error "Evento/generazione controller invalido."))
  (unless (= generation (1+ (fixture-generation fixture)))
    (error "Generazione globale evento diversa dal successore atteso."))
  (let ((index (position event (fixture-events fixture) :end (fixture-seen fixture) :test #'eq)))
    (unless index
      (when (= (fixture-seen fixture) +event-capacity+) (error "Evento fuori dal ring bounded."))
      (setf index (fixture-seen fixture) (svref (fixture-events fixture) index) event)
      (incf (fixture-seen fixture)))
    (unless (> generation (aref (fixture-generations fixture) index))
      (error "Generazione evento riusato senza avanzamento."))
    (setf (aref (fixture-generations fixture) index) generation
          (fixture-event fixture) event (fixture-generation fixture) generation)))

(defun check-event-token (fixture)
  "Confronta token evento corrente con quello WAL catturato prima dell'adozione."
  (let ((api (fixture-api fixture)) (descriptor (fixture-descriptor fixture)))
    (multiple-value-bind (slot high low)
        (funcall (api-event-token api) (fixture-controller fixture)
                 (fixture-event fixture) (fixture-generation fixture))
      (unless (and (= slot (svref descriptor 1)) (= high (svref descriptor 2))
                   (= low (svref descriptor 3))) (error "Token evento diverso dal token catturato.")))))

(defun check-event-state (fixture state)
  "Stato dell'identità evento con la generazione catturata, entro il clock."
  (unless (eq (funcall (api-event-state (fixture-api fixture)) (fixture-controller fixture)
                      (fixture-event fixture) (fixture-generation fixture)) state)
    (error "tools/series-controller-bench.lisp COD-61: stato evento incoerente.")))

(defun adopt-cycle (fixture expected-root next-root)
  "Il controller riceve un lotto sealed prima di qualunque dispatch I/O."
  (let ((api (fixture-api fixture)) (controller (fixture-controller fixture)))
    (unless (eq (funcall (api-root api) controller) expected-root)
      (error "Radice prima dell'adozione incoerente."))
    (multiple-value-bind (event generation)
        (funcall (api-adopt api) controller (fixture-lease fixture) (fixture-lotto fixture)
                 expected-root next-root :group)
      (remember-event fixture event generation))
    (incf (fixture-adoptions fixture))
    (check-event-state fixture :preparato)
    (check-event-token fixture)
    (check-counts fixture 1 1 0)))

(defun io-cycle (fixture)
  "Dispatch simulato sincrono: end del compito/barriera prima di active->retired."
  (let ((api (fixture-api fixture)) (group (fixture-group fixture))
        (controller (fixture-controller fixture)) (lease (fixture-lease fixture))
        (event (fixture-event fixture)) (generation (fixture-generation fixture)))
    (unless (= (funcall (api-add-lotto api) group (fixture-lotto fixture)) 1) (error "Conteggio gruppo errato."))
    (unless (null (funcall (api-close-group api) group)) (error "Chiusura gruppo incoerente."))
    (unless (null (funcall (api-start-io api) controller lease event generation)) (error "Start I/O incoerente."))
    (check-counts fixture 1 1 1)
    (check-event-state fixture :preparato)
    (unless (eq (funcall (api-root api) controller) (fixture-root fixture)) (error "Radice mutata dal dispatch."))
    (unless (= (funcall (api-execute api) group) (svref (fixture-descriptor fixture) 4))
      (error "Frontiera I/O incoerente."))
    (sb-thread:barrier (:memory))
    (unless (and (eq (funcall (api-lotto-state api) (fixture-lotto fixture)) :durable)
                 (eq (funcall (api-group-state api) group) :durable)
                 (= (fixture-bytes fixture) (svref (fixture-descriptor fixture) 4))
                 (= (fixture-bytes fixture) (funcall (api-written api) (fixture-file fixture)))
                 (= (fixture-bytes fixture) (funcall (api-durable api) (fixture-file fixture)))
                 (= (fixture-writes fixture) (1+ (fixture-cycles fixture)))
                 (= (fixture-flushes fixture) (1+ (fixture-cycles fixture))))
      (error "Fine write/flush incoerente."))
    (unless (null (funcall (api-complete-io api) controller lease event generation))
      (error "Completamento I/O incoerente."))
    (check-counts fixture 1 1 0)
    (check-event-state fixture :preparato)
    (unless (and (eq (funcall (api-root api) controller) (fixture-root fixture))
                 (eq (funcall (api-token-state api) (fixture-lotto fixture)) :pendente))
      (error "Fine I/O ha alterato radice/token di pubblicazione."))))

(defun publish-cycle (fixture next-root)
  "Una sola pubblicazione: un :pendente è un'anomalia conservata, senza retry."
  (let ((api (fixture-api fixture)) (controller (fixture-controller fixture)))
    (unless (and (funcall (api-covered api) (fixture-lotto fixture) :group)
                 (eq (funcall (api-log-state api) (fixture-log fixture)) :open))
      (error "Copertura/log prima della pubblicazione incoerente."))
    (multiple-value-bind (status high low)
        (funcall (api-publish api) controller (fixture-lease fixture)
                 (fixture-event fixture) (fixture-generation fixture))
      (setf (fixture-publication-status fixture) status
            (fixture-returned-high fixture) high (fixture-returned-low fixture) low)
      (when (eq status :pendente)
        (unless (and (zerop high) (zerop low)) (error "H nonzero su :pendente normalizzato."))
        (error 'pending-publication))
      (unless (and (eq status :risolto) (= high (fixture-high fixture)) (= low (fixture-low fixture)))
        (error "Risoluzione controller/H incoerente.")))
    (unless (and (eq (funcall (api-root api) controller) next-root)
                 (eq (funcall (api-token-state api) (fixture-lotto fixture)) :risolto)
                 (eq (funcall (api-health api) controller) :healthy)
                 (eq (funcall (api-fault-scope api) controller) :none))
      (error "Radice/token/salute dopo pubblicazione incoerente."))
    (multiple-value-bind (lh ll hh hl) (funcall (api-frontiers api) (fixture-registry fixture))
      (unless (and (= lh (fixture-high fixture)) (= ll (fixture-low fixture)) (= lh hh) (= ll hl))
        (error "Frontiere CSN dopo pubblicazione incoerenti.")))
    (setf (fixture-root fixture) next-root)
    (incf (fixture-publications fixture))
    (check-event-state fixture :risolto)
    (check-event-token fixture)
    (check-counts fixture 1 0 0)))

(defun retire-cycle (fixture)
  "Prima rilascio del gruppo; poi riuso del controller, che riusa il lotto."
  (let ((api (fixture-api fixture)) (lotto (fixture-lotto fixture)))
    (unless (null (funcall (api-reuse-group api) (fixture-group fixture))) (error "Rilascio gruppo incoerente."))
    (unless (null (funcall (api-reuse-event api) (fixture-controller fixture) (fixture-lease fixture)
                          (fixture-event fixture) (fixture-generation fixture))) (error "Ritiro evento incoerente."))
    (check-event-state fixture :libero)
    (check-counts fixture 0 0 0)
    (unless (and (eq (funcall (api-token-state api) lotto) :libero)
                 (eq (funcall (api-lotto-state api) lotto) :open) (zerop (funcall (api-length api) lotto))
                 (eq (funcall (api-group-state api) (fixture-group fixture)) :building)
                 (eq (funcall (api-root api) (fixture-controller fixture)) (fixture-root fixture)))
      (error "Riuso integrato controller/lotto incompleto."))
    (incf (fixture-retirements fixture))))

(defun integrated-cycle (fixture)
  "Ciclo bounded senza retry, costruzione di report o allocazioni deliberate."
  (let* ((expected-root (funcall (api-root (fixture-api fixture)) (fixture-controller fixture)))
         (next-root (if (eq expected-root +root-a+) +root-b+ +root-a+)))
    (unless (eq expected-root (fixture-root fixture)) (error "Radice attesa a inizio ciclo incoerente."))
    (seal-cycle fixture)
    (adopt-cycle fixture expected-root next-root)
    (io-cycle fixture)
    (publish-cycle fixture next-root)
    (retire-cycle fixture)
    (incf (fixture-cycles fixture)))
  1)

(defun fixture-observation (fixture)
  "Fuori dal clock, solo dopo join; count è l'ultimo oracolo eseguito sotto lease."
  (let* ((api (fixture-api fixture)) (controller (fixture-controller fixture))
         (health (funcall (api-health api) controller))
         (log-state (funcall (api-log-state api) (fixture-log fixture)))
         (root-readable (and (eq health :healthy) (eq log-state :open))))
    (multiple-value-bind (lh ll hh hl) (funcall (api-frontiers api) (fixture-registry fixture))
      (list :last-high lh :last-low ll :horizon-high hh :horizon-low hl
            :expected-high (fixture-high fixture) :expected-low (fixture-low fixture)
            :cycles (fixture-cycles fixture) :writes (fixture-writes fixture) :flushes (fixture-flushes fixture)
            :bytes (fixture-bytes fixture) :adoptions (fixture-adoptions fixture)
            :publications (fixture-publications fixture) :retirements (fixture-retirements fixture)
            :written (funcall (api-written api) (fixture-file fixture))
            :durable (funcall (api-durable api) (fixture-file fixture))
            :log-state log-state
            :lotto-state (funcall (api-lotto-state api) (fixture-lotto fixture))
            :token-state (funcall (api-token-state api) (fixture-lotto fixture))
            :group-state (funcall (api-group-state api) (fixture-group fixture))
            :controller-state health :fault-scope (funcall (api-fault-scope api) controller)
            :root (when root-readable (funcall (api-root api) controller)) :root-readable root-readable
            :expected-root (fixture-root fixture) :last-generation (fixture-generation fixture)
            :publication-status (fixture-publication-status fixture)
            :returned-high (fixture-returned-high fixture) :returned-low (fixture-returned-low fixture)
            :last-event-state (when (fixture-event fixture)
                                (funcall (api-event-state api) controller
                                         (fixture-event fixture) (fixture-generation fixture)))
            :captured-slot (svref (fixture-descriptor fixture) 1)
            :captured-high (svref (fixture-descriptor fixture) 2)
            :captured-low (svref (fixture-descriptor fixture) 3)
            :captured-end (svref (fixture-descriptor fixture) 4)
            :event-identities (fixture-seen fixture) :count (fixture-count fixture)
            :unresolved (fixture-unresolved fixture) :active-io (fixture-active-io fixture)
            :count-observation :last-in-clock-under-lease :run-lease (fixture-run-lease fixture)
            :lease-released (zerop (fixture-lease fixture))))))

(defun validate-fixture (observation iterations bytes)
  "Oracoli finali fuori dal clock; richiesti anche sul rapporto persistito."
  (require-fields observation '(:cycles :writes :flushes :adoptions :publications :retirements
                               :count :unresolved :active-io :root :expected-root :last-generation))
  (unless (and (= (getf observation :cycles) iterations) (= (getf observation :writes) iterations)
               (= (getf observation :flushes) iterations) (= (getf observation :adoptions) iterations)
               (= (getf observation :publications) iterations) (= (getf observation :retirements) iterations)
               (= (getf observation :bytes) (* iterations bytes))
               (= (getf observation :written) (getf observation :bytes))
               (= (getf observation :durable) (getf observation :bytes))
               (= (getf observation :last-high) (getf observation :expected-high))
               (= (getf observation :last-low) (getf observation :expected-low))
               (= (getf observation :horizon-high) (getf observation :last-high))
               (= (getf observation :horizon-low) (getf observation :last-low))
               (eq (getf observation :log-state) :open) (eq (getf observation :lotto-state) :open)
               (eq (getf observation :token-state) :libero) (eq (getf observation :group-state) :building)
               (eq (getf observation :controller-state) :healthy) (eq (getf observation :fault-scope) :none)
               (getf observation :root-readable) (eq (getf observation :publication-status) :risolto)
               (= (getf observation :returned-high) (getf observation :expected-high))
               (= (getf observation :returned-low) (getf observation :expected-low))
               (eq (getf observation :root) (if (evenp iterations) +root-a+ +root-b+))
               (eq (getf observation :root) (getf observation :expected-root))
               (= (getf observation :last-generation) iterations)
               (= (getf observation :event-identities) (min iterations +event-capacity+))
               (eq (getf observation :last-event-state) :libero)
               (typep (getf observation :captured-slot) 'fixnum)
               (<= 0 (getf observation :captured-slot) (1- +capacity+))
               (= (getf observation :captured-high) (getf observation :expected-high))
               (= (getf observation :captured-low) (getf observation :expected-low))
               (= (getf observation :captured-end) (getf observation :bytes))
               (typep (getf observation :run-lease) 'fixnum) (plusp (getf observation :run-lease))
               (zerop (getf observation :count)) (zerop (getf observation :unresolved))
               (zerop (getf observation :active-io)) (getf observation :lease-released))
    (error "tools/series-controller-bench.lisp COD-61: oracolo finale incoerente: ~S." observation)))

(defun warmup (api high low)
  "Fixture/lease separate: il carry della finestra misurata rimane nel clock."
  (let ((fixture (new-fixture api high low)))
    (unwind-protect
         (progn
           (acquire-fixture fixture)
           (unwind-protect (dotimes (i +warmup+) (integrated-cycle fixture)) (release-fixture fixture))
           (validate-fixture (fixture-observation fixture) +warmup+ (api-record-total api)))
      (close-fixture fixture))))

(defstruct (raw-window (:copier nil))
  "Solo valori grezzi preallocati; rapporti e diagnostica sono formati dopo le finestre."
  (status :ready :type keyword) (failure nil :type (or null condition))
  (start nil :type (or null integer)) (end nil :type (or null integer))
  (before nil :type (or null integer)) (after nil :type (or null integer))
  (completed 0 :type fixnum) (sink 0 :type fixnum))

(defun measure-raw (function iterations raw
                    &optional (deadline (+ (get-internal-real-time)
                                          (* +deadline-seconds+ internal-time-units-per-second))))
  "Nessun report nel clock; un errore ferma la finestra e conserva contatori/progresso."
  (unless (typep iterations '(integer 1 320000)) (error "Iterazioni fuori budget."))
  (setf (raw-window-status raw) :running (raw-window-start raw) (get-internal-real-time)
        (raw-window-before raw) (sb-ext:get-bytes-consed))
  (handler-case
      (dotimes (i iterations)
        (when (and deadline (zerop (logand i 255)) (>= (get-internal-real-time) deadline))
          (error "Deadline del worker controller Serie esaurita."))
        (incf (raw-window-sink raw) (+ i (the fixnum (funcall function))))
        (incf (raw-window-completed raw)))
    (error (condition) (setf (raw-window-failure raw) condition)))
  (setf (raw-window-after raw) (sb-ext:get-bytes-consed)
        (raw-window-end raw) (get-internal-real-time)
        (raw-window-status raw) (if (raw-window-failure raw) :failed :ok))
  raw)

(defun window-record (iterations token bytes scope)
  "Tutte le chiavi sono presenti prima di condividere il record o misurare."
  (list :schema-version 1 :status :running :iterations iterations :warmup-iterations 0
        :completed-iterations 0 :heap-bytes nil :raw-ticks nil :seconds nil
        :start-ticks nil :end-ticks nil :heap-before nil :heap-after nil :time-quality :pending :sink nil
        :expected-sink (+ (* iterations token) (truncate (* iterations (1- iterations)) 2))
        :bytes-per-cycle bytes :cycles-per-second nil :bytes-per-second nil
        :allocation-scope scope :busy-failures 0 :full-failures 0 :retries 0
        :failure-type nil :failure-reason nil :normalized-pending nil :final nil
        :diagnostic nil :additional-diagnostics nil))

(defun fill-window (record raw)
  "Rapporti e stringhe fuori dal clock, e nel parallelo dopo il join di tutti i worker."
  (let* ((ticks (when (and (raw-window-start raw) (raw-window-end raw))
                  (- (raw-window-end raw) (raw-window-start raw))))
         (heap (when (and (raw-window-before raw) (raw-window-after raw))
                 (- (raw-window-after raw) (raw-window-before raw))))
         (seconds (when ticks (/ ticks (float internal-time-units-per-second 1d0)))))
    (setf (getf record :status) (raw-window-status raw)
          (getf record :raw-ticks) ticks (getf record :heap-bytes) heap
          (getf record :seconds) seconds (getf record :sink) (raw-window-sink raw)
          (getf record :completed-iterations) (raw-window-completed raw)
          (getf record :start-ticks) (raw-window-start raw)
          (getf record :end-ticks) (raw-window-end raw)
          (getf record :heap-before) (raw-window-before raw)
          (getf record :heap-after) (raw-window-after raw)
          (getf record :time-quality) (if (and ticks (>= ticks +minimum-ticks+)) :valid :below-resolution)
          (getf record :cycles-per-second)
          (when (and seconds (plusp seconds)) (/ (raw-window-completed raw) seconds))
          (getf record :bytes-per-second)
          (when (and seconds (plusp seconds))
            (/ (* (raw-window-completed raw) (getf record :bytes-per-cycle)) seconds))
          (getf record :diagnostic)
          (when (raw-window-failure raw) (princ-to-string (raw-window-failure raw)))))
  record)

(defun require-fields (record keys)
  "Distingue campi mancanti da campi presenti con valore NIL."
  (dolist (key keys)
    (multiple-value-bind (found value tail) (get-properties record (list key))
      (declare (ignore value))
      (unless (and found tail)
        (error 'sensor-rejection :reason :missing-metric :detail key)))))

(defun note-diagnostic (record condition)
  "Conserva la prima anomalia e tutte quelle successive, fuori dalle finestre."
  (let ((text (format nil "tools/series-controller-bench.lisp COD-61: ~A" condition)))
    (if (getf record :diagnostic)
        (setf (getf record :additional-diagnostics)
              (append (getf record :additional-diagnostics) (list text)))
        (setf (getf record :diagnostic) text)))
  nil)

(defun validate-window (record &key (zero-heap nil) (valid-time nil) (rates nil))
  "Gate del sensore; nessuna soglia di prestazione del prodotto."
  (require-fields record '(:schema-version :status :iterations :completed-iterations :heap-bytes
                          :raw-ticks :seconds :sink :expected-sink :cycles-per-second :bytes-per-second
                          :start-ticks :end-ticks :heap-before :heap-after :time-quality
                          :bytes-per-cycle :busy-failures :full-failures :retries))
  (unless (and (integerp (getf record :raw-ticks)) (>= (getf record :raw-ticks) 0)
               (realp (getf record :seconds)) (>= (getf record :seconds) 0))
    (error 'sensor-rejection :reason :invalid-time))
  (unless (and (= (getf record :schema-version) 1) (eq (getf record :status) :ok)
               (integerp (getf record :heap-bytes)) (>= (getf record :heap-bytes) 0)
               (integerp (getf record :raw-ticks)) (>= (getf record :raw-ticks) 0)
               (realp (getf record :seconds)) (>= (getf record :seconds) 0)
               (integerp (getf record :start-ticks)) (integerp (getf record :end-ticks))
               (= (getf record :raw-ticks) (- (getf record :end-ticks) (getf record :start-ticks)))
               (integerp (getf record :heap-before)) (integerp (getf record :heap-after))
               (= (getf record :heap-bytes) (- (getf record :heap-after) (getf record :heap-before)))
               (= (getf record :seconds)
                  (/ (getf record :raw-ticks) (float internal-time-units-per-second 1d0)))
               (eq (getf record :time-quality)
                   (if (>= (getf record :raw-ticks) +minimum-ticks+) :valid :below-resolution))
               (= (getf record :sink) (getf record :expected-sink))
               (= (getf record :completed-iterations) (getf record :iterations))
               (zerop (getf record :busy-failures)) (zerop (getf record :full-failures))
               (zerop (getf record :retries)))
    (error 'sensor-rejection :reason :invalid-window :detail record))
  (when (and zero-heap (not (zerop (getf record :heap-bytes))))
    (error 'sensor-rejection :reason :heap-nonzero :detail (getf record :heap-bytes)))
  (when (and valid-time (< (getf record :raw-ticks) +minimum-ticks+))
    (error 'sensor-rejection :reason :time-resolution :detail (getf record :raw-ticks)))
  (when (and rates (not (and (realp (getf record :cycles-per-second))
                            (plusp (getf record :cycles-per-second))
                            (realp (getf record :bytes-per-second))
                            (plusp (getf record :bytes-per-second))
                            (= (getf record :cycles-per-second)
                               (/ (getf record :completed-iterations) (getf record :seconds)))
                            (= (getf record :bytes-per-second)
                               (/ (* (getf record :completed-iterations) (getf record :bytes-per-cycle))
                                  (getf record :seconds))))))
    (error 'sensor-rejection :reason :invalid-rates))
  record)

(defun save-plist (record path &optional (if-exists :supersede))
  "Solo file del run esclusivo; rapporto scritto anche dopo un fallimento."
  (with-open-file (stream path :direction :output :if-exists if-exists
                         :if-does-not-exist :create :external-format :utf-8)
    (let ((*print-readably* t) (*print-length* nil) (*print-level* nil))
      (write record :stream stream :pretty t) (terpri stream))))

(defun read-plist (path)
  "Pre: file scritto dal sensore. Post: un solo oggetto, senza read-eval."
  (with-open-file (stream path :external-format :utf-8)
    (let* ((*read-eval* nil) (record (read stream nil :eof)))
      (unless (and (listp record) (not (eq record :eof)) (eq (read stream nil :eof) :eof))
        (error "tools/series-controller-bench.lisp COD-61: plist persistita malformata: ~A." path))
      record)))

(defun require-rejection (function reason)
  "Esige il rifiuto nominato del gate; errori accidentali non fanno passare l'autoverifica."
  (let ((rejected nil))
    (handler-case (funcall function)
      (sensor-rejection (condition)
        (unless (eq (sensor-reason condition) reason) (error condition))
        (setf rejected t)))
    (unless rejected (error "tools/series-controller-bench.lisp COD-60: regressione non rilevata."))
    t))

(defun metric-persistence-self-test (out)
  "Modifica un alias e verifica i throughput dopo salvataggio/rilettura su disco."
  (let* ((record (window-record 1 1 160 :self-test)) (shared record)
         (path (merge-pathnames "self-test-metrics.lisp" out)))
    (setf (getf record :status) :metric-probe (getf record :heap-bytes) 0
          (getf record :raw-ticks) 20 (getf record :seconds) 1d0
          (getf record :completed-iterations) 1 (getf record :sink) 1
          (getf record :cycles-per-second) 17d0 (getf record :bytes-per-second) 19d0)
    (unless (and (eq record shared) (= (getf shared :cycles-per-second) 17d0)
                 (= (getf shared :bytes-per-second) 19d0))
      (error "tools/series-controller-bench.lisp COD-60: aggiornamento getf perde la testa condivisa."))
    (save-plist shared path :error)
    (let ((stored (read-plist path)))
      (require-fields stored '(:heap-bytes :raw-ticks :seconds :cycles-per-second :bytes-per-second))
      (unless (and (equal stored shared) (= (getf stored :cycles-per-second) 17d0)
                   (= (getf stored :bytes-per-second) 19d0))
        (error "tools/series-controller-bench.lisp COD-60: metriche persistite perse.")))
    (list :status :ok :path (namestring path) :shared-head-preserved t
          :cycles-per-second 17d0 :bytes-per-second 19d0)))

(defun sensor-self-test (report out)
  "Finestra vuota zero, 16 MiB vivi e regressioni dei gate; nessuna API prodotto."
  (let* ((empty (window-record +initial-iterations+ 0 0 :whole-process-serial))
         (positive (window-record 16 +positive-bytes+ 0 :whole-process-serial))
         (empty-raw (make-raw-window)) (positive-raw (make-raw-window))
         (probes (make-array 16 :initial-element nil)) (cursor 0)
         (test (list :status :running :empty-window empty :allocation-control positive
                     :invalid-time-rejected nil :negative-time-rejected nil :heap-regression-rejected nil
                     :missing-metric-rejected nil :positive-retained-objects nil
                     :positive-retained-bytes nil :persisted-metric-fields nil)))
    (setf (getf report :self-test) test)
    (sb-ext:gc :full t)
    (fill-window empty (measure-raw (lambda () 0) +initial-iterations+ empty-raw))
    (validate-window empty :zero-heap t)
    (sb-ext:gc :full t)
    (fill-window positive
                 (measure-raw (lambda ()
                                (setf (svref probes cursor)
                                      (make-array +positive-bytes+ :element-type '(unsigned-byte 8)
                                                                  :initial-element 0))
                                (incf cursor) (length (svref probes (1- cursor))))
                              16 positive-raw))
    (validate-window positive)
    (unless (and (= cursor 16) (every (lambda (probe) (= (length probe) +positive-bytes+)) probes)
                 (>= (getf positive :heap-bytes) (* 16 +positive-bytes+)))
      (error "tools/series-controller-bench.lisp COD-60: sensore non rileva 16 MiB deliberati."))
    (setf (getf test :positive-retained-objects) cursor
          (getf test :positive-retained-bytes) (* cursor +positive-bytes+)
          (getf test :heap-regression-rejected)
          (require-rejection (lambda () (validate-window positive :zero-heap t)) :heap-nonzero))
    (let ((invalid (copy-list empty)) (negative (copy-list empty)) (missing (copy-list empty)))
      (setf (getf invalid :raw-ticks) 0 (getf invalid :seconds) 0d0
            (getf invalid :time-quality) :below-resolution
            (getf invalid :end-ticks) (getf invalid :start-ticks)
            (getf negative :raw-ticks) -1 (getf negative :seconds) -1d0)
      (remf missing :bytes-per-second)
      (setf (getf test :invalid-time-rejected)
            (require-rejection (lambda () (validate-window invalid :valid-time t)) :time-resolution)
            (getf test :negative-time-rejected)
            (require-rejection (lambda () (validate-window negative)) :invalid-time)
            (getf test :missing-metric-rejected)
            (require-rejection (lambda () (validate-window missing)) :missing-metric)))
    (setf (getf test :persisted-metric-fields) (metric-persistence-self-test out)
          (getf test :status) :ok)))

(defun classify-failure (api record raw)
  "Conserva reason reale o pending normalizzato; fail-first con zero retry."
  (let ((condition (raw-window-failure raw)))
    (when condition
      (let ((reason (cond ((typep condition 'pending-publication) :csn-busy)
                          ((typep condition (api-product-error api)) (funcall (api-reason api) condition))
                          (t :sensor-or-runtime-error))))
        (setf (getf record :failure-type) (string (type-of condition))
              (getf record :failure-reason) reason
              (getf record :normalized-pending) (typep condition 'pending-publication))
        (when (or (getf record :normalized-pending) (typep condition (api-resource-error api)))
          (case reason
            ((:csn-busy :serie-busy) (setf (getf record :busy-failures) 1))
            ((:csn-full :serie-full) (setf (getf record :full-failures) 1))
            (otherwise nil)))))))

(defun serial-attempt (api high low count record)
  "Warmup separato e fixture nuova; osservazioni conservate prima del gate zero heap."
  (warmup api high low)
  (let* ((fixture (new-fixture api high low)) (raw (make-raw-window))
         (cycle (lambda () (integrated-cycle fixture))))
    (setf (getf record :warmup-iterations) +warmup+)
    (unwind-protect
         (progn
           (acquire-fixture fixture)
           (sb-ext:gc :full t)
           (unwind-protect (measure-raw cycle count raw) (release-fixture fixture))
           (fill-window record raw)
           (classify-failure api record raw)
           (setf (getf record :final) (fixture-observation fixture))
           (validate-window record :zero-heap t)
           (validate-fixture (getf record :final) count (api-record-total api)))
      (close-fixture fixture)))
  record)

(defun serial-sample (api high low sample)
  "Al massimo cinque finestre; ogni tentativo è registrato prima della misura."
  (loop for index below +maximum-attempts+
        for count = +initial-iterations+ then (* 2 count)
        for record = (window-record count 1 (api-record-total api) :whole-process-serial)
        do (setf (getf sample :attempts) (append (getf sample :attempts) (list record)))
           (handler-case (serial-attempt api high low count record)
             (error (condition)
               (setf (getf record :status) :failed)
               (note-diagnostic record condition)
               (error condition)))
           (when (>= (getf record :raw-ticks) +minimum-ticks+)
             (validate-window record :zero-heap t :valid-time t :rates t)
             (setf (getf sample :measurement) record (getf sample :status) :ok)
             (return-from serial-sample sample))
           (setf (getf record :status) :below-resolution)
        finally (error "tools/series-controller-bench.lisp COD-61: risoluzione insufficiente a ~D cicli."
                       +maximum-iterations+)))

(defun serial-campaigns (api report)
  "Dieci repliche consecutive prima di creare qualunque worker parallelo."
  (dolist (base '((0 0) (#x80000000 #xfffffff0)))
    (destructuring-bind (high low) base
      (let ((campaign (list :status :running :scenario :integrated-series-controller
                            :capacity +capacity+ :initial-high high :initial-low low
                            :file-id +file-id+ :records-per-cycle 1 :value-bytes 64 :key-bytes 16
                            :event-capacity +event-capacity+
                            :publication :controller-root-cas :level :group :samples nil)))
        (setf (getf report :serial) (append (getf report :serial) (list campaign)))
        (dotimes (replica +samples+)
          (let ((sample (list :replica (1+ replica) :status :running :attempts nil :measurement nil)))
            (setf (getf campaign :samples) (append (getf campaign :samples) (list sample)))
            (serial-sample api high low sample)))
        (setf (getf campaign :status) :ok)))))

(defstruct (worker (:copier nil))
  "Fixture e finestra private; il main legge solo dopo join o cleanup concluso."
  (fixture nil :type (or null fixture) :read-only t)
  (cycle #'identity :type function :read-only t)
  (raw (make-raw-window) :type raw-window :read-only t))

(defun worker-main (worker count ready start deadline)
  "Un errore ferma il worker: nessun retry, nessun annullamento sano del token."
  (let ((raw (worker-raw worker)))
    (handler-case
        (progn
          (sb-thread:signal-semaphore ready)
          (unless (sb-thread:wait-on-semaphore start :timeout +deadline-seconds+)
            (error "Start del worker oltre deadline."))
          (acquire-fixture (worker-fixture worker))
          (unwind-protect
               (measure-raw (worker-cycle worker) count raw deadline)
            (release-fixture (worker-fixture worker))))
      (error (condition)
        (setf (raw-window-status raw) :failed (raw-window-failure raw) condition))))
  nil)

(defun start-workers (workers threads count ready start deadline)
  "Crea solo i thread di questa replica; lambda e fixture precedono lo start gate."
  (dotimes (i (length workers))
    (let ((worker (svref workers i)))
      (setf (svref threads i)
            (sb-thread:make-thread (lambda () (worker-main worker count ready start deadline))
                                   :name (format nil "series-controller-bench-~D" i))))))

(defun remaining-seconds (deadline)
  "Tutte le attese condividono un limite assoluto, non un timeout per tentativo."
  (/ (max 0 (- deadline (get-internal-real-time)))
     (float internal-time-units-per-second 1d0)))

(defun await-ready (ready count deadline)
  "Pre: thread avviati. Post: tutti al gate entro la deadline della replica."
  (dotimes (i count)
    (unless (sb-thread:wait-on-semaphore ready :timeout (remaining-seconds deadline))
      (error "Worker controller Serie non pronto entro deadline."))))

(defun join-workers (threads deadline)
  "Attese seriali con deadline comune; nessuna attesa oltre 30 secondi."
  (dotimes (i (length threads))
    (let ((thread (svref threads i)))
      (sb-thread:join-thread thread :timeout (remaining-seconds deadline) :default :timeout)
      (when (sb-thread:thread-alive-p thread) (error "Join controller Serie oltre deadline.")))))

(defun cleanup-threads (threads start)
  "Budget comune di 2 s; terminate non afferma rollback o rilascio lease."
  (sb-thread:signal-semaphore start (length threads))
  (dotimes (i (length threads))
    (let ((thread (svref threads i)))
      (when (and thread (sb-thread:thread-alive-p thread)) (sb-thread:terminate-thread thread))))
  (let ((deadline (+ (get-internal-real-time) (* 2 internal-time-units-per-second))))
    (dotimes (i (length threads))
      (let ((thread (svref threads i)))
        (when thread
          (sb-thread:join-thread thread :timeout (remaining-seconds deadline) :default :cleanup-timeout)))))
  (when (loop for thread across threads thereis (and thread (sb-thread:thread-alive-p thread)))
    (error "tools/series-controller-bench.lisp COD-42: thread vivo dopo cleanup.")))

(defun stable-worker-p (thread)
  "Un worker mai avviato o terminato può essere letto dal main."
  (or (null thread) (not (sb-thread:thread-alive-p thread))))

(defun collect-workers (api workers threads attempt)
  "Rapporti fuori dalle finestre; nessun accesso ai campi di un thread ancora vivo."
  (let ((records (getf attempt :workers)))
    (dotimes (i (length workers))
      (let ((worker (svref workers i)) (record (nth i records)))
        (when worker
          (if (stable-worker-p (svref threads i))
              (progn
                (fill-window record (worker-raw worker))
                (classify-failure api record (worker-raw worker))
                (handler-case
                    (setf (getf record :final) (fixture-observation (worker-fixture worker)))
                  (error (condition)
                    (setf (getf record :status) :failed)
                    (note-diagnostic record condition))))
              (setf (getf record :status) :unavailable
                    (getf record :diagnostic) "Thread vivo dopo cleanup; campi non letti.")))))))

(defun aggregate-parallel (attempt)
  "Tempo tra primo start e ultimo end; heap dal contatore globale start gate/join."
  (let* ((records (getf attempt :workers)) (total (getf attempt :measurement))
         (start (loop for record in records minimize (getf record :start-ticks)))
         (end (loop for record in records maximize (getf record :end-ticks)))
         (raw (make-raw-window :status :ok :start start :end end
                               :before (getf attempt :process-heap-before)
                               :after (getf attempt :process-heap-after)
                               :completed (loop for record in records sum (getf record :completed-iterations))
                               :sink (loop for record in records sum (getf record :sink)))))
    (fill-window total raw)
    (setf (getf total :busy-failures) (loop for record in records sum (getf record :busy-failures))
          (getf total :full-failures) (loop for record in records sum (getf record :full-failures))
          (getf attempt :process-raw-ticks)
          (- (getf attempt :process-end-ticks) (getf attempt :process-start-ticks))
          (getf attempt :process-heap-bytes) (getf total :heap-bytes))
    (validate-window total)
    total))

(defun new-parallel-attempt (api count iterations)
  "Ogni chiave modificata e ogni record del worker esiste prima di creare i thread."
  (let ((measurement (window-record (* count iterations) 1 (api-record-total api)
                                    :whole-process-start-gate-and-joins)))
    ;; Il sink aggregato somma N finestre; non è il sink di un'unica finestra lunga.
    (setf (getf measurement :expected-sink) (* count (truncate (* iterations (1+ iterations)) 2)))
    (list :schema-version 1 :status :running :iterations-per-worker iterations
          :worker-count count :retry-policy :fail-first :measurement measurement
          :workers (loop repeat count collect
                    (let ((record (window-record iterations 1 (api-record-total api)
                                                 :process-global-overlapping-worker-window-not-summable)))
                      (setf (getf record :warmup-iterations) +warmup+) record))
          :process-start-ticks nil :process-end-ticks nil :process-raw-ticks nil
          :process-heap-before nil :process-heap-after nil :process-heap-bytes nil
          :process-window-status :pending :cleanup-diagnostic nil
          :diagnostic nil :additional-diagnostics nil)))

(defun parallel-attempt (api count iterations attempt)
  "Una replica indipendente; tutti i join precedono rapporti, oracoli finali e cleanup file."
  (let* ((workers (make-array count :initial-element nil))
         (threads (make-array count :initial-element nil))
         (ready (sb-thread:make-semaphore)) (start (sb-thread:make-semaphore)))
    (unwind-protect
         (progn
           (dotimes (i count)
             (warmup api #x80000000 #xfffffff0)
             (let ((fixture (new-fixture api #x80000000 #xfffffff0)))
               (setf (svref workers i)
                     (make-worker :fixture fixture :cycle (lambda () (integrated-cycle fixture))))))
           (let ((deadline (+ (get-internal-real-time)
                              (* +deadline-seconds+ internal-time-units-per-second))))
             (start-workers workers threads iterations ready start deadline)
             (await-ready ready count deadline)
             (sb-ext:gc :full t)
             (setf (getf attempt :process-start-ticks) (get-internal-real-time)
                   (getf attempt :process-heap-before) (sb-ext:get-bytes-consed))
             (sb-thread:signal-semaphore start count)
             (join-workers threads deadline))
           (setf (getf attempt :process-heap-after) (sb-ext:get-bytes-consed)
                 (getf attempt :process-end-ticks) (get-internal-real-time)
                 (getf attempt :process-window-status) :complete))
      (handler-case (cleanup-threads threads start)
        (error (condition)
          (setf (getf attempt :cleanup-diagnostic) (princ-to-string condition))
          (note-diagnostic attempt condition)))
      (when (and (getf attempt :process-heap-before) (not (getf attempt :process-heap-after))
                 (loop for thread across threads always (stable-worker-p thread)))
        (setf (getf attempt :process-heap-after) (sb-ext:get-bytes-consed)
              (getf attempt :process-end-ticks) (get-internal-real-time)
              (getf attempt :process-window-status) :failed-complete))
      (when (and (getf attempt :process-heap-before) (getf attempt :process-heap-after))
        (setf (getf attempt :process-heap-bytes)
              (- (getf attempt :process-heap-after) (getf attempt :process-heap-before))
              (getf attempt :process-raw-ticks)
              (- (getf attempt :process-end-ticks) (getf attempt :process-start-ticks))))
      (unwind-protect (collect-workers api workers threads attempt)
        (dotimes (i count)
          (when (and (svref workers i) (stable-worker-p (svref threads i)))
            (close-fixture (worker-fixture (svref workers i)))))))
    (when (getf attempt :cleanup-diagnostic)
      (error "tools/series-controller-bench.lisp COD-42: ~A" (getf attempt :cleanup-diagnostic)))
    (dolist (record (getf attempt :workers))
      (validate-window record)
      (validate-fixture (getf record :final) iterations (api-record-total api)))
    (aggregate-parallel attempt))
  attempt)

(defun parallel-sample (api count campaign)
  "Calibrazione limitata; heap parallelo osservazionale, nessuna somma dei worker."
  (loop for index below +maximum-attempts+
        for iterations = +initial-iterations+ then (* 2 iterations)
        for attempt = (new-parallel-attempt api count iterations)
        do (setf (getf campaign :attempts) (append (getf campaign :attempts) (list attempt)))
           (handler-case (parallel-attempt api count iterations attempt)
             (error (condition)
               (setf (getf attempt :status) :failed)
               (note-diagnostic attempt condition)
               (error condition)))
           (when (every (lambda (record) (>= (getf record :raw-ticks) +minimum-ticks+))
                        (getf attempt :workers))
             (dolist (record (getf attempt :workers))
               (validate-window record :valid-time t :rates t))
             (validate-window (getf attempt :measurement) :valid-time t :rates t)
             (setf (getf attempt :status) :ok (getf campaign :status) :ok
                   (getf campaign :measurement) attempt)
             (return-from parallel-sample campaign))
           (setf (getf attempt :status) :below-resolution)
        finally (error "tools/series-controller-bench.lisp COD-61: parallelo sotto risoluzione al budget.")))

(defun parallel-campaigns (api report)
  "Nove repliche: 1/2/4 worker per tre volte, senza sovrapposizione tra repliche."
  (dolist (count '(1 2 4))
    (dotimes (replica +parallel-replicas+)
      (let ((campaign (list :schema-version 1 :status :running :mode :independent-archive-per-worker
                            :worker-count count :replica (1+ replica) :capacity-per-registry +capacity+
                            :event-capacity-per-controller +event-capacity+
                            :initial-high #x80000000 :initial-low #xfffffff0 :file-id +file-id+
                            :attempts nil :measurement nil)))
        (setf (getf report :parallel) (append (getf report :parallel) (list campaign)))
        (parallel-sample api count campaign)))))

(defun command-output (argv)
  "Solo metadata fuori dalle finestre; argv diretto, nessuna shell."
  (multiple-value-bind (stdout stderr code)
      (uiop:run-program argv :output :string :error-output :string :ignore-error-status t)
    (unless (and (integerp code) (zerop code))
      (error "tools/series-controller-bench.lisp COD-61: metadata ~S exit ~S: ~A." argv code stderr))
    (string-trim '(#\Space #\Newline #\Return) stdout)))

(defun fingerprints ()
  "SHA-256 dei file e della lista ricorsiva, prima/dopo; nessun subprocess nel clock."
  (let* ((files (mapcar #'enough-namestring
                       (append '(#p"arcdocdb.asd" #p"tools/series-controller-bench.lisp"
                                 #p"docs/implementazione/controller-serie-metodo.md")
                               (sort (directory "src/**/*.lisp") #'string< :key #'namestring))))
         (output (command-output (append #+darwin '("shasum" "-a" "256" "--")
                                         #-darwin '("sha256sum" "--") files)))
         (lines (remove-if (lambda (line) (zerop (length line)))
                           (uiop:split-string output :separator '(#\Newline)))))
    (unless (= (length files) (length lines)) (error "SHA sorgenti incompleti."))
    (loop for file in files for line in lines
          do (unless (and (>= (length line) 67)
                          (every (lambda (char) (digit-char-p char 16)) (subseq line 0 64))
                          (string= file (subseq line 66)))
               (error "tools/series-controller-bench.lisp COD-61: SHA-256 invalido per ~A." file))
          collect (list :file file :sha256 (string-downcase (subseq line 0 64))))))

(defun environment ()
  "HW, checkout e argv osservati prima di build/misure; carico esterno non controllato."
  (list :argv (copy-list sb-ext:*posix-argv*) :argv-source :sbcl-posix-argv
        :script "tools/series-controller-bench.lisp" :cwd (namestring (truename "./"))
        :hardware
        (list :machine (machine-type)
              :cpu #+darwin (command-output '("sysctl" "-n" "machdep.cpu.brand_string"))
                   #-darwin (machine-version)
              :memory-bytes
              #+darwin (parse-integer (command-output '("sysctl" "-n" "hw.memsize")))
              #-darwin (* (parse-integer (command-output '("getconf" "PAGESIZE")))
                          (parse-integer (command-output '("getconf" "_PHYS_PAGES"))))
              :logical-cpus
              #+darwin (parse-integer (command-output '("sysctl" "-n" "hw.logicalcpu")))
              #-darwin (parse-integer (command-output '("getconf" "_NPROCESSORS_ONLN"))))
        :sbcl (lisp-implementation-version) :os (software-type) :os-version (software-version)
        :commit (command-output '("git" "rev-parse" "HEAD"))
        :working-tree (command-output '("git" "status" "--porcelain"))
        :external-load-status :uncontrolled))

(defun create-output-directory (requested)
  "mkdir esclusivo; directory configurabile figlia diretta del vero spikes/out/."
  (ensure-directories-exist "spikes/out/")
  (let ((root (truename "spikes/out/")))
    (when requested
      (let* ((path (merge-pathnames (uiop:ensure-directory-pathname requested) (truename "./")))
             (parent (truename (uiop:pathname-parent-directory-pathname path))))
        (unless (and (equal parent root) (not (probe-file path)))
          (error "tools/series-controller-bench.lisp COD-61: --output-dir deve essere nuova e figlia di ~A." root))
        (sb-posix:mkdir path #o700)
        (return-from create-output-directory (truename path))))
    (loop for attempt below 1000
          for path = (merge-pathnames (format nil "~D-series-controller-~D-~D/"
                                             (get-universal-time) (sb-posix:getpid) attempt) root)
          do (handler-case
                 (progn (sb-posix:mkdir path #o700) (return-from create-output-directory (truename path)))
               (sb-posix:syscall-error (condition)
                 (unless (= (sb-posix:syscall-errno condition) sb-posix:eexist) (error condition)))))
    (error "tools/series-controller-bench.lisp COD-61: nomi esclusivi esauriti.")))

(defun parse-arguments (args)
  "Forma finita: mode e, facoltativamente, --output-dir PATH."
  (unless (and (member (first args) '("--self-test" "--bench") :test #'equal)
               (or (= (length args) 1)
                   (and (= (length args) 3) (equal (second args) "--output-dir"))))
    (error "tools/series-controller-bench.lisp COD-61: --self-test|--bench [--output-dir spikes/out/UNIQUE/]."))
  (values (first args) (third args)))

(defun new-report ()
  "Predeclara anche fingerprint, diagnostica e campi finali per gli alias condivisi."
  (list :schema-version 1 :kind :series-controller-benchmark :status :running :mode nil
        :recorded-at (get-universal-time) :finished-at nil :output-directory nil
        :sbcl (lisp-implementation-version) :machine (machine-type) :cpu (machine-version)
        :os (software-type) :os-version (software-version) :safety 3
        :counter-scope :whole-process :serial-zero-heap-gate t :parallel-heap-gate :observational
        :timer-units-per-second internal-time-units-per-second :minimum-window-ticks +minimum-ticks+
        :initial-iterations +initial-iterations+ :maximum-iterations +maximum-iterations+
        :maximum-attempts +maximum-attempts+ :warmup-iterations +warmup+
        :serial-samples +samples+ :parallel-replicas +parallel-replicas+
        :worker-deadline-seconds +deadline-seconds+ :capacity +capacity+ :event-capacity +event-capacity+
        :environment nil
        :build (list :status :pending :phase :pending :api-status :pending :fasl-mapping nil
                     :driver-fasl nil
                     :warnings-policy :all-fatal :asd-before-translations t :log "build.log")
        :source-fingerprints-before nil :source-fingerprints-after nil :source-consistency :pending
        :self-test nil :serial nil :parallel nil :persistence-status :pending
        :diagnostic nil :additional-diagnostics nil
        :limits '(:simulated-write-and-flush :opaque-immutable-symbol-roots
                  :synchronous-same-thread-io-handoff :lease-acquisition-outside-clock
                  :no-nvme-or-real-durability-claim :no-client-latency-or-database-throughput-claim
                  :no-snapshot-or-recovery-qualification :external-load-uncontrolled
                  :campaigns-run-sequentially :oracle-in-measured-loop :no-throughput-threshold
                  :serial-success-zero-heap-required :parallel-heap-observational
                  :counter-scope-whole-process :worker-heap-windows-overlap-and-are-not-summable
                  :parallel-process-window-includes-start-and-joins :no-retry
                  :unexpected-interruption-after-assignment-requires-fail-stop
                  :sensor-not-absolute-nonallocation-proof)))

(defun validate-calibrated-window (record serial)
  "Un tentativo sotto risoluzione deve essere completo e privo di anomalie."
  (unless (member (getf record :status) '(:ok :below-resolution))
    (error "tools/series-controller-bench.lisp COD-61: anomalia nella calibrazione."))
  (let ((copy (copy-list record)))
    (setf (getf copy :status) :ok)
    (validate-window copy :zero-heap serial)
    (when (and (eq (getf record :status) :below-resolution)
               (>= (getf record :raw-ticks) +minimum-ticks+))
      (error "Tentativo seriale marcato sotto risoluzione con tempo valido.")))
  (validate-fixture (getf record :final) (getf record :iterations) (getf record :bytes-per-cycle)))

(defun validate-serial-campaign (campaign)
  "Rilegge tutti i tentativi delle cinque repliche, compresi quelli calibrati."
  (unless (and (eq (getf campaign :status) :ok) (= (length (getf campaign :samples)) +samples+))
    (error "tools/series-controller-bench.lisp COD-61: repliche seriali mancanti."))
  (loop for sample in (getf campaign :samples) for replica from 1
        do (unless (and (eq (getf sample :status) :ok) (= (getf sample :replica) replica)
                        (<= 1 (length (getf sample :attempts)) +maximum-attempts+)
                        (equal (getf sample :measurement) (car (last (getf sample :attempts)))))
             (error "tools/series-controller-bench.lisp COD-61: tentativi seriali mancanti."))
           (loop for attempt in (getf sample :attempts)
                 for iterations = +initial-iterations+ then (* 2 iterations)
                 do (unless (= (getf attempt :iterations) iterations) (error "Calibrazione seriale incoerente."))
                    (validate-calibrated-window attempt t))
           (validate-window (getf sample :measurement) :zero-heap t :valid-time t :rates t)))

(defun validate-parallel-campaign (campaign)
  "Tutte le finestre worker e aggregate vengono validate senza sommare heap sovrapposti."
  (unless (and (eq (getf campaign :status) :ok)
               (<= 1 (length (getf campaign :attempts)) +maximum-attempts+)
               (equal (getf campaign :measurement) (car (last (getf campaign :attempts)))))
    (error "tools/series-controller-bench.lisp COD-61: tentativi paralleli mancanti."))
  (loop for attempt in (getf campaign :attempts)
        for iterations = +initial-iterations+ then (* 2 iterations)
        for records = (getf attempt :workers) for total = (getf attempt :measurement)
        do (unless (and (member (getf attempt :status) '(:ok :below-resolution))
                        (= (getf attempt :iterations-per-worker) iterations)
                        (= (length records) (getf campaign :worker-count))
                        (= (getf total :iterations) (* iterations (length records)))
                        (eq (getf attempt :process-window-status) :complete))
             (error "tools/series-controller-bench.lisp COD-61: worker o aggregato mancanti."))
           (dolist (record records)
             (unless (= (getf record :iterations) iterations) (error "Lavoro worker incoerente."))
             (validate-calibrated-window record nil))
           (validate-window total)
           (unless (and (= (getf total :start-ticks) (loop for record in records minimize (getf record :start-ticks)))
                        (= (getf total :end-ticks) (loop for record in records maximize (getf record :end-ticks)))
                        (= (getf total :heap-bytes) (getf attempt :process-heap-bytes)))
             (error "Aggregazione worker incoerente.")))
  (let ((attempt (getf campaign :measurement)))
    (unless (eq (getf attempt :status) :ok) (error "Campione parallelo non accettato."))
    (validate-window (getf attempt :measurement) :valid-time t :rates t)
    (dolist (record (getf attempt :workers)) (validate-window record :valid-time t :rates t))))

(defun validate-success-report (report)
  "Verifica finale anche sulla plist riletta: campi obbligatori e cardinalità delle campagne."
  (require-fields report '(:schema-version :status :mode :self-test :serial :parallel :source-consistency
                          :environment :build :source-fingerprints-before :source-fingerprints-after))
  (unless (and (= (getf report :schema-version) 1) (eq (getf report :status) :ok)
               (eq (getf report :source-consistency) :stable)
               (equal (getf report :source-fingerprints-before) (getf report :source-fingerprints-after))
               (getf report :source-fingerprints-before)
               (eq (getf (getf report :build) :status) :ok)
               (eq (getf (getf report :build) :api-status) :resolved)
               (getf (getf report :build) :driver-fasl)
               (getf (getf report :build) :fasl-mapping))
    (error "tools/series-controller-bench.lisp COD-61: rapporto finale invalido."))
  (let ((test (getf report :self-test)))
    (require-fields test '(:status :empty-window :allocation-control :persisted-metric-fields
                          :invalid-time-rejected :negative-time-rejected
                          :heap-regression-rejected :missing-metric-rejected
                          :positive-retained-objects :positive-retained-bytes))
    (unless (and (eq (getf test :status) :ok) (getf test :invalid-time-rejected)
                 (getf test :negative-time-rejected) (getf test :heap-regression-rejected)
                 (getf test :missing-metric-rejected)
                 (= (getf test :positive-retained-objects) 16)
                 (= (getf test :positive-retained-bytes) (* 16 +positive-bytes+))
                 (>= (getf (getf test :allocation-control) :heap-bytes) (* 16 +positive-bytes+))
                 (eq (getf (getf test :persisted-metric-fields) :status) :ok))
      (error "tools/series-controller-bench.lisp COD-60: autoverifica incompleta."))
    (validate-window (getf test :empty-window) :zero-heap t)
    (validate-window (getf test :allocation-control)))
  (when (equal (getf report :mode) "--bench")
    (unless (and (= (length (getf report :serial)) 2) (= (length (getf report :parallel)) 9))
      (error "tools/series-controller-bench.lisp COD-61: campagne mancanti."))
    (dolist (campaign (getf report :serial)) (validate-serial-campaign campaign))
    (dolist (campaign (getf report :parallel)) (validate-parallel-campaign campaign)))
  report)

(defun finish-fingerprints (report)
  "Un sorgente cambiato durante il run impedisce il successo, conservando i campioni."
  (handler-case
      (let ((after (fingerprints)))
        (setf (getf report :source-fingerprints-after) after
              (getf report :source-consistency)
              (if (equal (getf report :source-fingerprints-before) after) :stable :changed))
        (when (and (eq (getf report :status) :ok) (eq (getf report :source-consistency) :changed))
          (setf (getf report :status) :source-changed)
          (note-diagnostic report "Sorgenti cambiati durante l'invocazione; risultati invalidi.")))
    (error (condition)
      (setf (getf report :status) :failed)
      (note-diagnostic report condition))))

(defun persist-final (report out)
  "Salva osservazioni anche al fallimento; un successo richiede metriche persistite integre."
  (let ((path (merge-pathnames "report.lisp" out)))
    (handler-case
        (progn
          (when (eq (getf report :status) :ok) (validate-success-report report))
          (save-plist report path)
          (let ((stored (read-plist path)))
            (unless (equal stored report) (error "Rapporto persistito diverso dall'osservazione."))
            (when (eq (getf report :status) :ok) (validate-success-report stored)))
          (setf (getf report :persistence-status) :verified)
          (save-plist report path)
          (unless (equal (read-plist path) report) (error "Rapporto finale persistito incoerente.")))
      (error (condition)
        (setf (getf report :status) :failed (getf report :persistence-status) :failed)
        (note-diagnostic report (format nil "~A; report ~A." condition path))
        (save-plist report path)))))

(defun main ()
  "Confine C4: nessun run implicito; invocazione esplicita e rapporti anche al fallimento."
  (let ((report (new-report)) (out nil))
    (handler-case
        (multiple-value-bind (mode requested) (parse-arguments (rest sb-ext:*posix-argv*))
          (unless (>= most-positive-fixnum #xffffffff)
            (error "tools/series-controller-bench.lisp COD-61: richiesto SBCL con limb u32 fixnum."))
          (setf out (create-output-directory requested)
                (getf report :mode) mode (getf report :output-directory) (namestring out))
          (save-plist report (merge-pathnames "report.lisp" out) :error)
          (setf (getf report :environment) (environment)
                (getf report :source-fingerprints-before) (fingerprints))
          (save-plist report (merge-pathnames "report.lisp" out))
          (let ((api (load-product out report)))
            (sensor-self-test report out)
            (when (equal mode "--bench")
              (serial-campaigns api report) (parallel-campaigns api report)))
          (setf (getf report :status) :ok))
      (error (condition)
        (setf (getf report :status) :failed)
        (unless (member (getf (getf report :build) :status) '(:ok :pending))
          (setf (getf (getf report :build) :status) :failed))
        (note-diagnostic report condition)))
    (finish-fingerprints report)
    (setf (getf report :finished-at) (get-universal-time))
    (when out
      (handler-case (persist-final report out)
        (error (condition)
          (setf (getf report :status) :failed)
          (note-diagnostic report condition))))
    (let ((*print-readably* t) (*print-length* nil) (*print-level* nil))
      (write report :pretty t) (terpri))
    (unless (eq (getf report :status) :ok) (sb-ext:exit :code 1))))

(uiop:with-current-directory
    ((merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*)))
  (main))
