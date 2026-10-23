;;;; Bridge WAL/CSN: sensore C4, seriali prima dei worker indipendenti.
;;;; Preregistrazione: docs/implementazione/wal-csn-metodo.md. Nessun I/O dati reale.
;;;; Uso dal worktree congelato: --self-test|--bench [--output-dir spikes/out/UNIQUE/].
;;; REQ: REQ-WAL-002 REQ-WAL-005 REQ-MVC-008 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002 REQ-VAL-001
;;; OWNER: main possiede rapporti/API; ogni worker possiede la propria fixture.
;;; SHARED: solo barriere del sensore; registri/log/slot pubblicati indipendenti.
(require :asdf)
(require :sb-posix)
(require :sb-md5)
(defpackage #:arcdocdb.wal-csn.bench (:use #:cl))
(in-package #:arcdocdb.wal-csn.bench)
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
(defconstant +positive-bytes+ 1048576)
;; Oggetto alto creato una volta; mai combinare i limb CSN in un u64 nel ciclo.
(defconstant +file-id+ #xffffffffffffffff)

(defstruct (api (:copier nil))
  "Tabella immutabile risolta dal main dopo il caricamento rigoroso del prodotto."
  (registry #'identity :type function :read-only t)
  (frontiers #'identity :type function :read-only t)
  (lotto #'identity :type function :read-only t)
  (add-record #'identity :type function :read-only t)
  (seal #'identity :type function :read-only t)
  (read-token #'identity :type function :read-only t)
  (token-state #'identity :type function :read-only t)
  (resolve #'identity :type function :read-only t)
  (reuse-lotto #'identity :type function :read-only t)
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
  (u32 #'identity :type function :read-only t)
  (reason #'identity :type function :read-only t)
  (resource-error nil :type symbol :read-only t)
  (stamp-offset 0 :type fixnum :read-only t)
  (seal-total 0 :type fixnum :read-only t)
  (record-total 0 :type fixnum :read-only t))

(defun product-function (package name &optional (visibility :external))
  "Pre: nomi interni al driver. Post: API attesa; manca => fallimento C4."
  (multiple-value-bind (symbol actual) (find-symbol name package)
    (unless (and symbol (eq visibility actual) (fboundp symbol))
      (error "tools/wal-csn-bench.lisp COD-61: API assente ~A:~A." package name))
    (symbol-function symbol)))

(defun product-constant (package name)
  "Legge gli offset del formato senza duplicarne i valori nel sensore."
  (let ((symbol (find-symbol name package)))
    (unless (and symbol (boundp symbol) (typep (symbol-value symbol) 'fixnum))
      (error "tools/wal-csn-bench.lisp COD-61: costante assente ~A:~A." package name))
    (symbol-value symbol)))

(defun load-product ()
  "Compilazione fuori dal clock; warning e style-warning impediscono la campagna."
  (setf asdf:*compile-file-failure-behaviour* :error
        asdf:*compile-file-warnings-behaviour* :error)
  (let ((*standard-output* *error-output*))
    (handler-bind ((warning (lambda (condition)
                             (unless (typep condition 'sb-kernel:redefinition-warning)
                               (error condition)))))
      (asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
      (asdf:load-system "arcdocdb" :force t)))
  (flet ((wal (name) (product-function "ARCDOCDB.WAL" name))
         (io (name) (product-function "ARCDOCDB.IO" name)))
    (let* ((header (product-constant "ARCDOCDB.RECORD" "+HEADER-BYTES+"))
           (seal (+ header (product-constant "ARCDOCDB.RECORD" "+SEAL-BYTES+"))))
      (make-api
       :registry (product-function "ARCDOCDB.CSN" "CREA-REGISTRO-CSN")
       :frontiers (product-function "ARCDOCDB.CSN" "LEGGI-FRONTIERE-CSN")
       :lotto (wal "CREA-LOTTO") :add-record (wal "AGGIUNGI-RECORD")
       :seal (wal "SIGILLA-LOTTO-CON-CSN") :read-token (wal "LEGGI-CSN-LOTTO")
       :token-state (wal "STATO-CSN-LOTTO") :resolve (wal "RISOLVI-LOTTO-PUBBLICATO")
       :reuse-lotto (wal "RIUSA-LOTTO") :lotto-state (wal "STATO-LOTTO")
       :length (wal "LUNGHEZZA-LOTTO")
       :buffer (product-function "ARCDOCDB.WAL" "LOTTO-BUFFER" :internal)
       :log (wal "CREA-LOG-IO") :log-state (wal "STATO-LOG")
       :group (wal "CREA-GRUPPO") :add-lotto (wal "AGGIUNGI-LOTTO")
       :close-group (wal "CHIUDI-GRUPPO") :execute (wal "ESEGUI-GRUPPO")
       :reuse-group (wal "RIUSA-GRUPPO") :group-state (wal "STATO-GRUPPO")
       :covered (wal "COPERTO-P") :backend (io "MAKE-BACKEND")
       :file (io "CREA-TEMPORANEO") :close-file (io "CHIUDI")
       :written (io "POSIZIONE-SCRITTA") :durable (io "POSIZIONE-DUREVOLE")
       :u32 (product-function "ARCDOCDB.BINARY" "LEGGI-U32")
       :reason (product-function "ARCDOCDB.CONDITIONS" "ERROR-REASON")
       :resource-error (find-symbol "RESOURCE-EXHAUSTED" "ARCDOCDB.CONDITIONS")
       :stamp-offset (product-constant "ARCDOCDB.RECORD" "+STAMP-OFFSET+")
       :seal-total seal :record-total (+ header 16 64 seal)))))

(defstruct (fixture (:copier nil))
  "Oggetti preallocati di un unico proprietario; published usa CAS sul riferimento."
  (api nil :type (or null api) :read-only t)
  (registry nil :type t) (lotto nil :type t) (file nil :type t)
  (log nil :type t) (group nil :type t) (buffer nil :type t)
  (key (make-array 16 :element-type '(unsigned-byte 8) :initial-element 17)
       :type (simple-array (unsigned-byte 8) (16)) :read-only t)
  (value (make-array 64 :element-type '(unsigned-byte 8) :initial-element 42)
         :type (simple-array (unsigned-byte 8) (64)) :read-only t)
  ;; Registro, slot, high, low, end: evento atteso, non ricostruito al callback.
  (descriptor (make-array 5 :initial-element nil) :type simple-vector :read-only t)
  (published nil :type t)
  (high 0 :type (unsigned-byte 32)) (low 0 :type (unsigned-byte 32))
  (cycles 0 :type fixnum) (writes 0 :type fixnum) (flushes 0 :type fixnum)
  (bytes 0 :type fixnum) (publications 0 :type fixnum))

(defun close-fixture (fixture)
  "Pre: worker terminato. Post: backend simulato chiuso; nessun token annullato."
  (when (fixture-file fixture)
    (funcall (api-close-file (fixture-api fixture)) (fixture-file fixture))))

(defun new-fixture (api high low)
  "Costruisce backend e buffer fuori dal clock; nessun descrittore nativo aperto."
  (let* ((fixture (make-fixture :api api :high high :low low))
         (backend
           (funcall (api-backend api)
                    (lambda (name mode) (declare (ignore name mode)) 7)
                    (lambda (&rest args) (error "Read simulata inattesa: ~S." args))
                    (lambda (fd buffer start count)
                      (declare (ignore fd))
                      (unless (and (eq buffer (fixture-buffer fixture)) (zerop start)
                                   (= count (api-record-total api)))
                        (error "Write simulata incoerente."))
                      (incf (fixture-writes fixture)) (incf (fixture-bytes fixture) count) count)
                    (lambda (fd) (declare (ignore fd)) (incf (fixture-flushes fixture)) 0)
                    (lambda (&rest args) (error "Flush directory inatteso: ~S." args))
                    (lambda (fd) (declare (ignore fd)) 0))))
    (setf (fixture-registry fixture)
          (funcall (api-registry api) :capacity +capacity+ :initial-high high :initial-low low)
          (fixture-lotto fixture)
          (funcall (api-lotto api) :segment +file-id+ :capacity 512 :max-records 1)
          (fixture-buffer fixture) (funcall (api-buffer api) (fixture-lotto fixture))
          (fixture-file fixture)
          (funcall (api-file api) "wal-csn-bench.tmp" :backend backend
                   :max-transfer 512 :max-file-bytes most-positive-fixnum))
    (handler-case
        (setf (fixture-log fixture) (funcall (api-log api) (fixture-file fixture) :segment +file-id+)
              (fixture-group fixture) (funcall (api-group api) (fixture-log fixture) :max-lots 1
                                              :max-bytes 512))
      (error (condition) (close-fixture fixture) (error condition)))
    fixture))

(declaim (inline next-pair))
(defun next-pair (high low)
  "Successore indipendente a due u32, limitato al dominio della campagna."
  (declare (type (unsigned-byte 32) high low))
  (if (= low #xffffffff) (values (1+ high) 0) (values high (1+ low))))

(defun check-stamp (fixture position high low)
  "Controlla entrambi i limb nei byte senza materializzare un intero u64."
  (let* ((api (fixture-api fixture)) (buffer (fixture-buffer fixture))
         (offset (+ position (api-stamp-offset api))))
    (unless (and (= (funcall (api-u32 api) buffer offset) low)
                 (= (funcall (api-u32 api) buffer (+ offset 4)) high))
      (error "tools/wal-csn-bench.lisp COD-61: stamp record/SEAL errato."))))

(defun seal-cycle (fixture)
  "Aggiunge un PUT e cattura il token atteso dell'evento nel descrittore preallocato."
  (let* ((api (fixture-api fixture)) (lotto (fixture-lotto fixture))
         (file (fixture-file fixture)) (registry (fixture-registry fixture))
         (descriptor (fixture-descriptor fixture)))
    (unless (eq (funcall (api-token-state api) lotto) :libero)
      (error "Token non libero all'inizio del ciclo."))
    (multiple-value-bind (next-high next-low) (next-pair (fixture-high fixture) (fixture-low fixture))
      (setf (fixture-high fixture) next-high (fixture-low fixture) next-low))
    (unless (= (funcall (api-add-record api) lotto 1 (fixture-key fixture) (fixture-value fixture))
               (- (api-record-total api) (api-seal-total api)))
      (error "Lunghezza PUT inattesa."))
    (multiple-value-bind (used high low)
        (funcall (api-seal api) lotto registry (fixture-log fixture)
                 (funcall (api-written api) file) (funcall (api-durable api) file))
      (unless (and (= used (api-record-total api)) (= high (fixture-high fixture))
                   (= low (fixture-low fixture))
                   (eq (funcall (api-token-state api) lotto) :pendente))
        (error "Assegnazione CSN o stato pendente errato."))
      (multiple-value-bind (slot actual-high actual-low) (funcall (api-read-token api) lotto)
        (unless (and (typep slot 'fixnum) (<= 0 slot) (< slot +capacity+)
                     (= actual-high high) (= actual-low low))
          (error "Token o riuso dello slot CSN incoerente."))
        (setf (svref descriptor 0) registry (svref descriptor 1) slot
              (svref descriptor 2) high (svref descriptor 3) low
              (svref descriptor 4) (+ (funcall (api-written api) file) used)))
      (check-stamp fixture 0 high low)
      (check-stamp fixture (- used (api-seal-total api)) high low))))

(defun publish-and-resolve (fixture)
  "Pre: write/flush simulati finiti. Post: pubblicazione CAS prima del callback atteso."
  (let* ((api (fixture-api fixture)) (lotto (fixture-lotto fixture))
         (descriptor (fixture-descriptor fixture)))
    (unless (and (eq (funcall (api-lotto-state api) lotto) :durable)
                 (funcall (api-covered api) lotto :group))
      (error "Copertura durevole incoerente prima della pubblicazione."))
    (let ((previous (sb-ext:compare-and-swap (fixture-published fixture) nil descriptor)))
      (unless (null previous) (error "Pubblicazione esterna già presente.")))
    (incf (fixture-publications fixture))
    (unless (eq (fixture-published fixture) descriptor)
      (error "Pubblicazione assente prima del callback."))
    (multiple-value-bind (hh hl)
        (funcall (api-resolve api) lotto (svref descriptor 0) (svref descriptor 1)
                 (svref descriptor 2) (svref descriptor 3) :group)
      (unless (and (= hh (fixture-high fixture)) (= hl (fixture-low fixture))
                   (eq (funcall (api-token-state api) lotto) :risolto))
        (error "H o risoluzione del lotto incoerente.")))
    (let ((previous (sb-ext:compare-and-swap (fixture-published fixture) descriptor nil)))
      (unless (eq descriptor previous) (error "Il riferimento pubblicato non è stato ritirato.")))))

(defun integrated-cycle (fixture)
  "Un ciclo senza retry: add, seal, write/flush, pubblicazione, risoluzione, riuso."
  (let ((api (fixture-api fixture)) (lotto (fixture-lotto fixture)) (group (fixture-group fixture)))
    (seal-cycle fixture)
    (unless (= (funcall (api-add-lotto api) group lotto) 1) (error "Conteggio gruppo errato."))
    (funcall (api-close-group api) group)
    (unless (= (funcall (api-execute api) group) (svref (fixture-descriptor fixture) 4))
      (error "Frontiera write/flush errata."))
    (publish-and-resolve fixture)
    (funcall (api-reuse-group api) group)
    (funcall (api-reuse-lotto api) lotto)
    (unless (and (eq (funcall (api-token-state api) lotto) :libero)
                 (eq (funcall (api-lotto-state api) lotto) :open)
                 (zerop (funcall (api-length api) lotto))
                 (eq (funcall (api-group-state api) group) :building))
      (error "Riuso integrato incompleto."))
    (incf (fixture-cycles fixture)) 1))

(defun fixture-observation (fixture)
  "Snapshot compatto fuori dal clock, conservato anche quando un ciclo fallisce."
  (let ((api (fixture-api fixture)))
    (multiple-value-bind (lh ll hh hl) (funcall (api-frontiers api) (fixture-registry fixture))
      (list :last-high lh :last-low ll :horizon-high hh :horizon-low hl
            :expected-high (fixture-high fixture) :expected-low (fixture-low fixture)
            :cycles (fixture-cycles fixture) :writes (fixture-writes fixture)
            :flushes (fixture-flushes fixture) :bytes (fixture-bytes fixture)
            :publications (fixture-publications fixture)
            :written (funcall (api-written api) (fixture-file fixture))
            :durable (funcall (api-durable api) (fixture-file fixture))
            :log-state (funcall (api-log-state api) (fixture-log fixture))
            :lotto-state (funcall (api-lotto-state api) (fixture-lotto fixture))
            :token-state (funcall (api-token-state api) (fixture-lotto fixture))
            :group-state (funcall (api-group-state api) (fixture-group fixture))
            :published-reference (not (null (fixture-published fixture)))))))

(defun validate-fixture (observation iterations bytes)
  "Esige conteggi esatti, frontiere convergenti e nessun riferimento pubblicato vivo."
  (unless (and (= (getf observation :cycles) iterations)
               (= (getf observation :writes) iterations) (= (getf observation :flushes) iterations)
               (= (getf observation :publications) iterations)
               (= (getf observation :bytes) (* iterations bytes))
               (= (getf observation :written) (getf observation :bytes))
               (= (getf observation :durable) (getf observation :bytes))
               (= (getf observation :last-high) (getf observation :expected-high))
               (= (getf observation :last-low) (getf observation :expected-low))
               (= (getf observation :horizon-high) (getf observation :last-high))
               (= (getf observation :horizon-low) (getf observation :last-low))
               (eq (getf observation :log-state) :open)
               (eq (getf observation :lotto-state) :open)
               (eq (getf observation :token-state) :libero)
               (eq (getf observation :group-state) :building)
               (null (getf observation :published-reference)))
    (error "tools/wal-csn-bench.lisp COD-61: oracolo finale incoerente: ~S." observation)))

(defun warmup (api high low)
  "Fixture separata: non consuma il carry della finestra misurata."
  (let ((fixture (new-fixture api high low)))
    (unwind-protect
         (progn (dotimes (i +warmup+) (integrated-cycle fixture))
                (validate-fixture (fixture-observation fixture) +warmup+ (api-record-total api)))
      (close-fixture fixture))))

(defstruct (raw-window (:copier nil))
  "Solo valori grezzi preallocati; rapporti e diagnostica sono formati dopo le finestre."
  (status :ready :type keyword) (failure nil :type (or null condition))
  (start nil :type (or null integer)) (end nil :type (or null integer))
  (before nil :type (or null integer)) (after nil :type (or null integer))
  (completed 0 :type fixnum) (sink 0 :type fixnum))

(defun measure-raw (function iterations raw &optional deadline)
  "Nessun report nel clock; un errore ferma la finestra e conserva contatori/progresso."
  (unless (typep iterations '(integer 1 320000)) (error "Iterazioni fuori budget."))
  (setf (raw-window-status raw) :running (raw-window-start raw) (get-internal-real-time)
        (raw-window-before raw) (sb-ext:get-bytes-consed))
  (handler-case
      (dotimes (i iterations)
        (when (and deadline (zerop (logand i 255)) (>= (get-internal-real-time) deadline))
          (error "Deadline del worker WAL/CSN esaurita."))
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
        :start-ticks nil :end-ticks nil :time-quality :pending :sink nil
        :expected-sink (+ (* iterations token) (truncate (* iterations (1- iterations)) 2))
        :bytes-per-cycle bytes :cycles-per-second nil :bytes-per-second nil
        :allocation-scope scope :busy-failures 0 :full-failures 0 :retries 0
        :final nil :diagnostic nil))

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
        (error "tools/wal-csn-bench.lisp COD-61: metrica mancante ~S." key)))))

(defun validate-window (record &key (zero-heap nil) (valid-time nil) (rates nil))
  "Gate del sensore; nessuna soglia di prestazione del prodotto."
  (require-fields record '(:schema-version :status :iterations :completed-iterations :heap-bytes
                          :raw-ticks :seconds :sink :expected-sink :cycles-per-second :bytes-per-second))
  (unless (and (= (getf record :schema-version) 1) (eq (getf record :status) :ok)
               (integerp (getf record :heap-bytes)) (>= (getf record :heap-bytes) 0)
               (integerp (getf record :raw-ticks)) (>= (getf record :raw-ticks) 0)
               (realp (getf record :seconds)) (>= (getf record :seconds) 0)
               (= (getf record :sink) (getf record :expected-sink))
               (= (getf record :completed-iterations) (getf record :iterations)))
    (error "tools/wal-csn-bench.lisp COD-61: finestra incompleta/invalida: ~S." record))
  (when (and zero-heap (not (zerop (getf record :heap-bytes))))
    (error "tools/wal-csn-bench.lisp COD-30: successo seriale alloca ~D byte."
           (getf record :heap-bytes)))
  (when (and valid-time (< (getf record :raw-ticks) +minimum-ticks+))
    (error "tools/wal-csn-bench.lisp COD-61: finestra inferiore a ~D tick." +minimum-ticks+))
  (when (and rates (not (and (realp (getf record :cycles-per-second))
                            (plusp (getf record :cycles-per-second))
                            (realp (getf record :bytes-per-second))
                            (plusp (getf record :bytes-per-second)))))
    (error "tools/wal-csn-bench.lisp COD-61: throughput assente o invalido."))
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
        (error "tools/wal-csn-bench.lisp COD-61: plist persistita malformata: ~A." path))
      record)))

(defun require-rejection (function)
  "Confine C4 dell'autoverifica negativa; esige un errore dal gate."
  (let ((rejected nil))
    (handler-case (funcall function) (error () (setf rejected t)))
    (unless rejected (error "tools/wal-csn-bench.lisp COD-60: regressione non rilevata."))
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
      (error "tools/wal-csn-bench.lisp COD-60: aggiornamento getf perde la testa condivisa."))
    (save-plist shared path :error)
    (let ((stored (read-plist path)))
      (require-fields stored '(:heap-bytes :raw-ticks :seconds :cycles-per-second :bytes-per-second))
      (unless (and (equal stored shared) (= (getf stored :cycles-per-second) 17d0)
                   (= (getf stored :bytes-per-second) 19d0))
        (error "tools/wal-csn-bench.lisp COD-60: metriche persistite perse.")))
    (list :status :ok :path (namestring path) :shared-head-preserved t
          :cycles-per-second 17d0 :bytes-per-second 19d0)))

(defun sensor-self-test (report out)
  "Finestra vuota zero, 16 MiB vivi e regressioni dei gate; nessuna API prodotto."
  (let* ((empty (window-record +initial-iterations+ 0 0 :whole-process-serial))
         (positive (window-record 16 +positive-bytes+ 0 :whole-process-serial))
         (empty-raw (make-raw-window)) (positive-raw (make-raw-window))
         (probes (make-array 16 :initial-element nil)) (cursor 0)
         (test (list :status :running :empty-window empty :allocation-control positive
                     :invalid-time-rejected nil :heap-regression-rejected nil
                     :missing-metric-rejected nil :persisted-metric-fields nil)))
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
      (error "tools/wal-csn-bench.lisp COD-60: sensore non rileva 16 MiB deliberati."))
    (setf (getf test :heap-regression-rejected)
          (require-rejection (lambda () (validate-window positive :zero-heap t))))
    (let ((invalid (copy-list empty)) (missing (copy-list empty)))
      (setf (getf invalid :raw-ticks) 0)
      (remf missing :bytes-per-second)
      (setf (getf test :invalid-time-rejected)
            (require-rejection (lambda () (validate-window invalid :valid-time t)))
            (getf test :missing-metric-rejected)
            (require-rejection (lambda () (validate-window missing)))))
    (setf (getf test :persisted-metric-fields) (metric-persistence-self-test out)
          (getf test :status) :ok)))

(defun classify-failure (api record raw)
  "Conta il primo rifiuto busy/full; retry effettivi restano zero."
  (let ((condition (raw-window-failure raw)))
    (when (and condition (typep condition (api-resource-error api)))
      (case (funcall (api-reason api) condition)
        (:csn-busy (setf (getf record :busy-failures) 1))
        (:csn-full (setf (getf record :full-failures) 1))
        (otherwise nil)))))

(defun serial-attempt (api high low count record)
  "Warmup separato e fixture nuova; osservazioni conservate prima del gate zero heap."
  (warmup api high low)
  (let* ((fixture (new-fixture api high low)) (raw (make-raw-window))
         (cycle (lambda () (integrated-cycle fixture))))
    (setf (getf record :warmup-iterations) +warmup+)
    (unwind-protect
         (progn
           (sb-ext:gc :full t)
           (fill-window record (measure-raw cycle count raw))
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
               (setf (getf record :status) :failed (getf record :diagnostic) (princ-to-string condition))
               (error condition)))
           (when (>= (getf record :raw-ticks) +minimum-ticks+)
             (validate-window record :zero-heap t :valid-time t :rates t)
             (setf (getf sample :measurement) record (getf sample :status) :ok)
             (return-from serial-sample sample))
           (setf (getf record :status) :below-resolution)
        finally (error "tools/wal-csn-bench.lisp COD-61: risoluzione insufficiente a ~D cicli."
                       +maximum-iterations+)))

(defun serial-campaigns (api report)
  "Dieci repliche consecutive prima di creare qualunque worker parallelo."
  (dolist (base '((0 0) (#x80000000 #xfffffff0)))
    (destructuring-bind (high low) base
      (let ((campaign (list :status :running :scenario :integrated-wal-csn
                            :capacity +capacity+ :initial-high high :initial-low low
                            :file-id +file-id+ :records-per-cycle 1 :value-bytes 64 :key-bytes 16
                            :publication :preallocated-descriptor-cas :level :group :samples nil)))
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

(defun worker-main (worker count ready start)
  "Un errore ferma il worker: nessun retry, nessun annullamento sano del token."
  (let ((raw (worker-raw worker)))
    (handler-case
        (progn
          (sb-thread:signal-semaphore ready)
          (unless (sb-thread:wait-on-semaphore start :timeout +deadline-seconds+)
            (error "Start del worker oltre deadline."))
          (measure-raw (worker-cycle worker) count raw
                       (+ (get-internal-real-time)
                          (* +deadline-seconds+ internal-time-units-per-second))))
      (error (condition)
        (setf (raw-window-status raw) :failed (raw-window-failure raw) condition))))
  nil)

(defun start-workers (workers threads count ready start)
  "Crea solo i thread di questa replica; lambda e fixture precedono lo start gate."
  (dotimes (i (length workers))
    (let ((worker (svref workers i)))
      (setf (svref threads i)
            (sb-thread:make-thread (lambda () (worker-main worker count ready start))
                                   :name (format nil "wal-csn-bench-~D" i))))))

(defun remaining-seconds (deadline)
  "Tutte le attese condividono un limite assoluto, non un timeout per tentativo."
  (/ (max 0 (- deadline (get-internal-real-time)))
     (float internal-time-units-per-second 1d0)))

(defun await-ready (ready count deadline)
  "Pre: thread avviati. Post: tutti al gate entro la deadline della replica."
  (dotimes (i count)
    (unless (sb-thread:wait-on-semaphore ready :timeout (remaining-seconds deadline))
      (error "Worker WAL/CSN non pronto entro deadline."))))

(defun join-workers (threads deadline)
  "Attese seriali con deadline comune; nessuna attesa oltre 30 secondi."
  (dotimes (i (length threads))
    (let ((thread (svref threads i)))
      (sb-thread:join-thread thread :timeout (remaining-seconds deadline) :default :timeout)
      (when (sb-thread:thread-alive-p thread) (error "Join WAL/CSN oltre deadline.")))))

(defun cleanup-threads (threads start)
  "Fail-stop delle fixture interrotte; terminate non afferma rollback dopo assegnazione."
  (sb-thread:signal-semaphore start (length threads))
  (dotimes (i (length threads))
    (let ((thread (svref threads i)))
      (when (and thread (sb-thread:thread-alive-p thread)) (sb-thread:terminate-thread thread))))
  (dotimes (i (length threads))
    (let ((thread (svref threads i)))
      (when thread (sb-thread:join-thread thread :timeout 2 :default :cleanup-timeout)))))

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
                    (setf (getf record :status) :failed
                          (getf record :diagnostic) (princ-to-string condition)))))
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
                    (window-record iterations 1 (api-record-total api)
                                   :process-global-overlapping-worker-window-not-summable))
          :process-start-ticks nil :process-end-ticks nil :process-raw-ticks nil
          :process-heap-before nil :process-heap-after nil :process-heap-bytes nil
          :process-window-status :pending :diagnostic nil)))

(defun parallel-attempt (api count iterations attempt)
  "Una replica indipendente; tutti i join precedono rapporti, oracoli finali e cleanup file."
  (let* ((workers (make-array count :initial-element nil))
         (threads (make-array count :initial-element nil))
         (ready (sb-thread:make-semaphore)) (start (sb-thread:make-semaphore))
         (deadline (+ (get-internal-real-time)
                      (* +deadline-seconds+ internal-time-units-per-second))))
    (unwind-protect
         (progn
           (dotimes (i count)
             (warmup api #x80000000 #xfffffff0)
             (let ((fixture (new-fixture api #x80000000 #xfffffff0)))
               (setf (svref workers i)
                     (make-worker :fixture fixture :cycle (lambda () (integrated-cycle fixture))))))
           (start-workers workers threads iterations ready start)
           (await-ready ready count deadline)
           (sb-ext:gc :full t)
           (setf (getf attempt :process-start-ticks) (get-internal-real-time)
                 (getf attempt :process-heap-before) (sb-ext:get-bytes-consed))
           (sb-thread:signal-semaphore start count)
           (join-workers threads deadline)
           (setf (getf attempt :process-heap-after) (sb-ext:get-bytes-consed)
                 (getf attempt :process-end-ticks) (get-internal-real-time)
                 (getf attempt :process-window-status) :complete))
      (cleanup-threads threads start)
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
               (setf (getf attempt :status) :failed (getf attempt :diagnostic) (princ-to-string condition))
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
        finally (error "tools/wal-csn-bench.lisp COD-61: parallelo sotto risoluzione al budget.")))

(defun parallel-campaigns (api report)
  "Nove repliche: 1/2/4 worker per tre volte, senza sovrapposizione tra repliche."
  (dolist (count '(1 2 4))
    (dotimes (replica +parallel-replicas+)
      (let ((campaign (list :schema-version 1 :status :running :mode :registry-and-log-per-worker
                            :worker-count count :replica (1+ replica) :capacity-per-registry +capacity+
                            :initial-high #x80000000 :initial-low #xfffffff0 :file-id +file-id+
                            :attempts nil :measurement nil)))
        (setf (getf report :parallel) (append (getf report :parallel) (list campaign)))
        (parallel-sample api count campaign)))))

(defun fingerprints ()
  "Stabilità del prodotto, ASD, driver e metodo; non una prova di autenticità."
  (loop for file in (append '(#p"arcdocdb.asd" #p"tools/wal-csn-bench.lisp"
                             #p"docs/implementazione/wal-csn-metodo.md")
                           (sort (directory "src/**/*.lisp") #'string< :key #'namestring))
        collect (list :file (enough-namestring file)
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file file) 'list)))))

(defun create-output-directory (requested)
  "mkdir esclusivo; directory configurabile figlia diretta del vero spikes/out/."
  (ensure-directories-exist "spikes/out/")
  (let ((root (truename "spikes/out/")))
    (when requested
      (let* ((path (merge-pathnames (uiop:ensure-directory-pathname requested) (truename "./")))
             (parent (truename (uiop:pathname-parent-directory-pathname path))))
        (unless (and (equal parent root) (not (probe-file path)))
          (error "tools/wal-csn-bench.lisp COD-61: --output-dir deve essere nuova e figlia di ~A." root))
        (sb-posix:mkdir path #o700)
        (return-from create-output-directory (truename path))))
    (loop for attempt below 1000
          for path = (merge-pathnames (format nil "~D-wal-csn-~D-~D/"
                                             (get-universal-time) (sb-posix:getpid) attempt) root)
          do (handler-case
                 (progn (sb-posix:mkdir path #o700) (return-from create-output-directory (truename path)))
               (sb-posix:syscall-error (condition)
                 (unless (= (sb-posix:syscall-errno condition) sb-posix:eexist) (error condition)))))
    (error "tools/wal-csn-bench.lisp COD-61: nomi esclusivi esauriti.")))

(defun parse-arguments (args)
  "Forma finita: mode e, facoltativamente, --output-dir PATH."
  (unless (and (member (first args) '("--self-test" "--bench") :test #'equal)
               (or (= (length args) 1)
                   (and (= (length args) 3) (equal (second args) "--output-dir"))))
    (error "tools/wal-csn-bench.lisp COD-61: --self-test|--bench [--output-dir spikes/out/UNIQUE/]."))
  (values (first args) (third args)))

(defun new-report ()
  "Predeclara anche fingerprint, diagnostica e campi finali per gli alias condivisi."
  (list :schema-version 1 :kind :wal-csn-benchmark :status :running :mode nil
        :recorded-at (get-universal-time) :finished-at nil :output-directory nil
        :sbcl (lisp-implementation-version) :machine (machine-type) :cpu (machine-version)
        :os (software-type) :os-version (software-version) :safety 3
        :counter-scope :whole-process :serial-zero-heap-gate t :parallel-heap-gate :observational
        :timer-units-per-second internal-time-units-per-second :minimum-window-ticks +minimum-ticks+
        :initial-iterations +initial-iterations+ :maximum-iterations +maximum-iterations+
        :maximum-attempts +maximum-attempts+ :warmup-iterations +warmup+
        :serial-samples +samples+ :parallel-replicas +parallel-replicas+
        :worker-deadline-seconds +deadline-seconds+ :capacity +capacity+
        :source-fingerprints-before nil :source-fingerprints-after nil :source-consistency :pending
        :self-test nil :serial nil :parallel nil :persistence-status :pending :diagnostic nil
        :limits '(:simulated-write-and-flush :simulated-external-index-publication
                  :no-nvme-or-real-durability-claim :no-client-latency-or-database-throughput-claim
                  :no-snapshot-or-recovery-qualification :external-load-uncontrolled
                  :campaigns-run-sequentially :oracle-in-measured-loop :no-throughput-threshold
                  :serial-success-zero-heap-required :parallel-heap-observational
                  :counter-scope-whole-process :worker-heap-windows-overlap-and-are-not-summable
                  :parallel-process-window-includes-start-and-joins :no-retry
                  :unexpected-interruption-after-assignment-requires-fail-stop
                  :sensor-not-absolute-nonallocation-proof)))

(defun validate-success-report (report)
  "Verifica finale anche sulla plist riletta: campi obbligatori e cardinalità delle campagne."
  (require-fields report '(:schema-version :status :mode :self-test :serial :parallel :source-consistency))
  (unless (and (= (getf report :schema-version) 1) (eq (getf report :status) :ok)
               (eq (getf report :source-consistency) :stable))
    (error "tools/wal-csn-bench.lisp COD-61: rapporto finale invalido."))
  (let ((test (getf report :self-test)))
    (require-fields test '(:status :empty-window :allocation-control :persisted-metric-fields
                          :invalid-time-rejected :heap-regression-rejected :missing-metric-rejected))
    (unless (and (eq (getf test :status) :ok) (getf test :invalid-time-rejected)
                 (getf test :heap-regression-rejected) (getf test :missing-metric-rejected)
                 (eq (getf (getf test :persisted-metric-fields) :status) :ok))
      (error "tools/wal-csn-bench.lisp COD-60: autoverifica incompleta."))
    (validate-window (getf test :empty-window) :zero-heap t)
    (validate-window (getf test :allocation-control)))
  (when (equal (getf report :mode) "--bench")
    (unless (and (= (length (getf report :serial)) 2) (= (length (getf report :parallel)) 9))
      (error "tools/wal-csn-bench.lisp COD-61: campagne mancanti."))
    (dolist (campaign (getf report :serial))
      (unless (and (eq (getf campaign :status) :ok) (= (length (getf campaign :samples)) +samples+))
        (error "tools/wal-csn-bench.lisp COD-61: repliche seriali mancanti."))
      (dolist (sample (getf campaign :samples))
        (validate-window (getf sample :measurement) :zero-heap t :valid-time t :rates t)))
    (dolist (campaign (getf report :parallel))
      (let ((attempt (getf campaign :measurement)))
        (unless (and (eq (getf campaign :status) :ok) (eq (getf attempt :status) :ok)
                     (= (length (getf attempt :workers)) (getf campaign :worker-count)))
          (error "tools/wal-csn-bench.lisp COD-61: worker o metriche parallele mancanti."))
        (validate-window (getf attempt :measurement) :valid-time t :rates t)
        (dolist (record (getf attempt :workers)) (validate-window record :valid-time t :rates t)))))
  report)

(defun finish-fingerprints (report)
  "Un sorgente cambiato durante il run impedisce il successo, conservando i campioni."
  (handler-case
      (let ((after (fingerprints)))
        (setf (getf report :source-fingerprints-after) after
              (getf report :source-consistency)
              (if (equal (getf report :source-fingerprints-before) after) :stable :changed))
        (when (and (eq (getf report :status) :ok) (eq (getf report :source-consistency) :changed))
          (setf (getf report :status) :source-changed)))
    (error (condition)
      (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition)))))

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
        (setf (getf report :status) :failed (getf report :persistence-status) :failed
              (getf report :diagnostic)
              (format nil "tools/wal-csn-bench.lisp COD-61: ~A; report ~A." condition path))
        (save-plist report path)))))

(defun main ()
  "Confine C4: nessun run implicito; invocazione esplicita e rapporti anche al fallimento."
  (let ((report (new-report)) (out nil))
    (handler-case
        (multiple-value-bind (mode requested) (parse-arguments (rest sb-ext:*posix-argv*))
          (unless (>= most-positive-fixnum #xffffffff)
            (error "tools/wal-csn-bench.lisp COD-61: richiesto SBCL con limb u32 fixnum."))
          (setf out (create-output-directory requested)
                (getf report :mode) mode (getf report :output-directory) (namestring out)
                (getf report :source-fingerprints-before) (fingerprints))
          (save-plist report (merge-pathnames "report.lisp" out) :error)
          (sensor-self-test report out)
          (when (equal mode "--bench")
            (let ((api (load-product))) (serial-campaigns api report) (parallel-campaigns api report)))
          (setf (getf report :status) :ok))
      (error (condition)
        (setf (getf report :status) :failed (getf report :diagnostic)
              (format nil "tools/wal-csn-bench.lisp COD-61: ~A" condition))))
    (finish-fingerprints report)
    (setf (getf report :finished-at) (get-universal-time))
    (when out
      (handler-case (persist-final report out)
        (error (condition)
          (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition)))))
    (let ((*print-readably* t) (*print-length* nil) (*print-level* nil))
      (write report :pretty t) (terpri))
    (unless (eq (getf report :status) :ok) (sb-ext:exit :code 1))))

(uiop:with-current-directory
    ((merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*)))
  (main))
