;;;; Prove locali della rinomina: backend e preflight, senza filesystem reale.
;;;; Non attestano decisione EDIT, validità dei file o checkpoint completo.
(in-package #:arcdocdb.io.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; OWNER: ciascun test possiede fixture, capacità e registro delle chiamate.
;;; SHARED: nessuno stato tra fixture; registrazione solo tramite DEFTEST del supporto.
(defstruct (rename-test-context (:constructor %make-rename-test-context)
                               (:conc-name rename-test-) (:copier nil))
  "Fixture senza risorse native: FD simulato e chiamate in ordine inverso."
  (file nil :type (or null arcdocdb.io:file-io))
  (events nil :type list))

(defun rename-test-fixture (callback &key (mode :directory) (include-rename t) (fd 41))
  "Apre una capacità simulata; ogni operazione del backend lascia un evento.
Le frontiere non nulle sono sentinelle iniettate soltanto dall'harness.
Nessun WITH-FILE: una chiusura automatica nasconderebbe close/rollback indebiti."
  (let ((context (%make-rename-test-context)))
    (flet ((record-call (operation &rest args)
             (push (cons operation args) (rename-test-events context))))
      (let* ((operations
               (list (lambda (name actual-mode)
                       (record-call :open name actual-mode) fd)
                     (lambda (&rest args) (apply #'record-call :read args) 0)
                     (lambda (&rest args) (apply #'record-call :write args) 0)
                     (lambda (descriptor) (record-call :flush descriptor) 0)
                     (lambda (descriptor) (record-call :directory-flush descriptor) 0)
                     (lambda (descriptor) (record-call :close descriptor) 0)
                     :identity (lambda (descriptor)
                                 (record-call :identity descriptor) (values 3 9))))
             (backend
               (if include-rename
                   (apply #'make-backend
                          (append operations
                                  (list :rename
                                        (when callback
                                          (lambda (descriptor source destination)
                                            (record-call :rename descriptor source destination)
                                            ;; Fallisce subito anche davanti a un retry senza limite.
                                            (is (= 1 (count :rename (rename-test-events context)
                                                             :key #'car)))
                                            (funcall callback descriptor source destination))))))
                   (apply #'make-backend operations)))
             (file (ecase mode
                     (:directory (apri-directory "rename-test-directory" :backend backend))
                     (:input (apri-lettura "rename-test.input" :backend backend))
                     (:append (crea-temporaneo "rename-test.tmp" :backend backend)))))
        (setf (rename-test-file context) file
              (arcdocdb.io::file-written file) 23
              (arcdocdb.io::file-durable file) 7)))
    context))

(defun rename-test-zero (fd source destination)
  "Callback POSIX simulato riuscito."
  (declare (ignore fd source destination))
  0)

(defun rename-test-call (context source destination)
  (arcdocdb.io:rinomina-nella-directory (rename-test-file context) source destination))

(defun rename-test-check-file (context state &key (fd 41) (mode :directory))
  "Controlla stato atteso, FD, modo ed entrambe le frontiere sentinella."
  (let ((file (rename-test-file context)))
    (is (eq state (stato-file file)))
    (is (= fd (arcdocdb.io::file-fd file)))
    (is (eq mode (arcdocdb.io:mode-file file)))
    (is (= 23 (posizione-scritta file)))
    (is (= 7 (posizione-durevole file)))))

(defun rename-test-check-events (context expected)
  "Anche close, flush, accessi al contenuto e rinomina inversa sono osservabili."
  (is (equal expected (mapcar #'car (reverse (rename-test-events context))))))

(defun rename-test-success (source destination &key (fd 41))
  (let ((context (rename-test-fixture #'rename-test-zero :fd fd))
        (expected-source (copy-seq source)) (expected-destination (copy-seq destination)))
    (is (equal '(nil) (multiple-value-list (rename-test-call context source destination))))
    (rename-test-check-file context :open :fd fd)
    (rename-test-check-events context '(:open :rename))
    (let ((event (first (rename-test-events context))))
      (is (= fd (second event)))
      (is (typep (third event) 'simple-base-string))
      (is (typep (fourth event) 'simple-base-string))
      (is (string= expected-source (third event)))
      (is (string= expected-destination (fourth event)))
      (is (not (eq source (third event))))
      (is (not (eq destination (fourth event))))
      (is (not (eq (third event) (fourth event)))))
    (is (string= expected-source source))
    (is (string= expected-destination destination))))

(defun rename-test-invalid-name (name)
  "Isola un nome invalido alla volta, prima source e poi destination."
  (dolist (source-p '(t nil))
    (let ((context (rename-test-fixture #'rename-test-zero))
          (source (if source-p name "source.tmp"))
          (destination (if source-p "destination.seg" name)))
      (if (stringp name)
          (signals invalid-argument (rename-test-call context source destination) :io-rename-name)
          (signals type-error (rename-test-call context source destination)))
      (rename-test-check-file context :open)
      (rename-test-check-events context '(:open))
      ;; Il rifiuto non consuma la capacità: una chiamata valida resta possibile.
      (is (null (rename-test-call context "source.tmp" "destination.seg")))
      (rename-test-check-file context :open)
      (rename-test-check-events context '(:open :rename)))))

(defun rename-test-check-faulted (context)
  "Un guasto impedisce ogni rinomina successiva e il flush, senza close o retry."
  (rename-test-check-file context :faulted)
  (rename-test-check-events context '(:open :rename))
  (signals io-fault (rename-test-call context "source.tmp" "destination.seg") :io-unavailable)
  (signals io-fault (durable-flush (rename-test-file context)) :io-unavailable)
  (rename-test-check-file context :faulted)
  (rename-test-check-events context '(:open :rename)))

(defun rename-test-check-closed-after-callback (context)
  "Una chiusura deliberata nel callback resta definitiva, anche dopo il guasto."
  (rename-test-check-file context :closed)
  (rename-test-check-events context '(:open :rename :close))
  (is (equal '(:close 41) (first (rename-test-events context))))
  (is (= 1 (count :close (rename-test-events context) :key #'car)))
  (dotimes (attempt 2)
    (is (null (chiudi (rename-test-file context)))))
  (signals io-fault (rename-test-call context "source.tmp" "destination.seg") :io-unavailable)
  (signals io-fault (durable-flush (rename-test-file context)) :io-unavailable)
  (is (= 1 (count :close (rename-test-events context) :key #'car)))
  (rename-test-check-file context :closed)
  (rename-test-check-events context '(:open :rename :close)))

(defun rename-test-io-failure (context reason errno &key (state :faulted))
  "Osserva FAULTED o CLOSED al segnale IO-FAULT; controlla metadati, retry e close."
  (let ((caught nil) (observed nil) (state-at-signal nil))
    (handler-case
        (handler-bind ((io-fault (lambda (condition)
                                  (setf observed condition
                                        state-at-signal (stato-file (rename-test-file context))))))
          (rename-test-call context "source.tmp" "destination.seg"))
      (io-fault (condition) (setf caught condition)))
    (is (typep caught 'io-fault))
    (is (eq caught observed))
    (is (eq state state-at-signal))
    (is (eq reason (error-reason caught)))
    (is (eq :rename (error-operation caught)))
    (is (eql errno (error-errno caught)))
    (is (= 0 (error-transferred caught)))
    (is (null (arcdocdb.conditions:error-cleanup-errno caught)))
    (ecase state
      (:faulted (rename-test-check-faulted context))
      (:closed (rename-test-check-closed-after-callback context)))))

(defun rename-test-errno (errno)
  (let ((context (rename-test-fixture (raises-errno errno))))
    (rename-test-io-failure context :io-syscall errno)))

(defun rename-test-result (result)
  (let ((context (rename-test-fixture
                  (lambda (fd source destination)
                    (declare (ignore fd source destination)) result))))
    (rename-test-io-failure context :io-rename-result nil)))

(defun rename-test-close-callback-failure (callback reason errno)
  "Inietta una violazione del protocollo fidato: close precede il fallimento del callback."
  (let ((context nil))
    (setf context
          (rename-test-fixture
           (lambda (fd source destination)
             (is (null (chiudi (rename-test-file context))))
             (funcall callback fd source destination))))
    (rename-test-io-failure context reason errno :state :closed)))

(defun rename-test-original-condition (original)
  "Una condizione del callback conserva identità e tipo dopo il cleanup fail-stop."
  (let ((context (rename-test-fixture
                  (lambda (fd source destination)
                    (declare (ignore fd source destination)) (error original)))))
    ;; Confine dell'harness: cattura anche condizioni estranee alla gerarchia del prodotto.
    (is (eq original
            (handler-case (rename-test-call context "source.tmp" "destination.seg")
              (error (condition) condition))))
    (rename-test-check-faulted context)))

(defun rename-test-post-call (context verify-after)
  "Chiama consapevolmente il core interno con fixture validata e nomi privati semplici."
  (let ((file (rename-test-file context))
        (source (map 'simple-base-string #'identity "source.tmp"))
        (destination (map 'simple-base-string #'identity "destination.seg")))
    (rename-test-check-file context :open)
    (is (typep source 'simple-base-string))
    (is (typep destination 'simple-base-string))
    (is (functionp verify-after))
    (is (functionp (arcdocdb.io::backend-rename (arcdocdb.io::file-backend file))))
    (arcdocdb.io::esigi-aperto file :directory)
    (arcdocdb.io::verifica-nome-rinomina source)
    (arcdocdb.io::verifica-nome-rinomina destination)
    (is (not (string= source destination)))
    (arcdocdb.io::rinomina-con-nomi-privati file source destination verify-after)))

(defun rename-test-post-entry (context)
  "La postcondizione entra dopo esattamente una rename, a capacità ancora aperta."
  (rename-test-check-file context :open)
  (rename-test-check-events context '(:open :rename))
  (let ((event (first (rename-test-events context))))
    (is (= 41 (second event)))
    (is (typep (third event) 'simple-base-string))
    (is (typep (fourth event) 'simple-base-string))
    (is (string= "source.tmp" (third event)))
    (is (string= "destination.seg" (fourth event)))))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest TEST-REQ-REC-001-IO-RENAME-MINIMUM-SOURCE-NAME
  (rename-test-success "s" "destination.seg"))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest TEST-REQ-REC-001-IO-RENAME-MINIMUM-DESTINATION-NAME
  (rename-test-success "source.tmp" "d"))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest TEST-REQ-REC-001-IO-RENAME-MAXIMUM-SOURCE-NAME
  (rename-test-success (make-string 255 :initial-element #\s) "destination.seg"))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest TEST-REQ-REC-001-IO-RENAME-MAXIMUM-DESTINATION-NAME
  (rename-test-success "source.tmp" (make-string 255 :initial-element #\d)))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest TEST-REQ-REC-001-IO-RENAME-BOTH-NAME-BOUNDARIES
  (rename-test-success "s" "d")
  (rename-test-success (make-string 255 :initial-element #\s)
                       (make-string 255 :initial-element #\d)))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest TEST-REQ-REC-001-IO-RENAME-ALL-PERMITTED-ASCII
  ;; 126 caratteri: l'intero ASCII non NUL, escluso slash; inclusi controlli e DEL.
  (let ((alphabet (coerce (loop for code from 1 to 127
                                unless (= code 47) collect (code-char code)) 'string)))
    (rename-test-success (concatenate 'string "s" alphabet)
                         (concatenate 'string "d" alphabet))))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest TEST-REQ-REC-001-IO-RENAME-NAMES-WITH-DOTS-AND-BACKSLASH
  (rename-test-success ".source.tmp" "destination..seg")
  (rename-test-success "..." (format nil "d~Cseg" (code-char 92))))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest TEST-REQ-REC-001-IO-RENAME-CASE-SENSITIVE-NAMES
  (rename-test-success "SOURCE" "source"))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest TEST-REQ-REC-001-IO-RENAME-STRING-FILL-POINTER
  (let ((source (make-array 256 :element-type 'character :initial-element #\Null
                                :adjustable t :fill-pointer 1))
        (destination (make-array 256 :element-type 'character :initial-element #\/
                                     :adjustable t :fill-pointer 255)))
    ;; Solo i caratteri nella lunghezza logica appartengono al nome.
    (fill source #\s)
    (fill destination #\d)
    (rename-test-success source destination)))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest TEST-REQ-REC-001-IO-RENAME-ADJUSTABLE-STRINGS-NORMALIZED
  (dolist (length '(1 255))
    (let ((source (make-array length :element-type 'character :initial-element #\s
                                    :adjustable t))
          (destination (make-array length :element-type 'character :initial-element #\d
                                         :adjustable t)))
      (is (stringp source))
      (is (stringp destination))
      (is (not (typep source 'simple-base-string)))
      (is (not (typep destination 'simple-base-string)))
      (rename-test-success source destination))))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest TEST-REQ-REC-001-IO-RENAME-DISPLACED-STRINGS-NORMALIZED
  (dolist (length '(1 255))
    (let* ((source-storage (make-array (+ length 2) :element-type 'character
                                                  :initial-element #\Null))
           (destination-storage (make-array (+ length 2) :element-type 'character
                                                       :initial-element #\/))
           (source (make-array length :element-type 'character :displaced-to source-storage
                                      :displaced-index-offset 1))
           (destination (make-array length :element-type 'character
                                           :displaced-to destination-storage
                                           :displaced-index-offset 1)))
      ;; NUL/slash negli antenati dello storage non appartengono alle due viste.
      (fill source #\s)
      (fill destination #\d)
      (is (eq source-storage (array-displacement source)))
      (is (eq destination-storage (array-displacement destination)))
      (rename-test-success source destination)
      (is (char= #\Null (char source-storage 0)))
      (is (char= #\/ (char destination-storage 0))))))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest TEST-REQ-REC-001-IO-RENAME-DISPLACED-ADJUSTABLE-FILL-POINTER-NORMALIZED
  (let* ((source-storage (make-array 257 :element-type 'character :initial-element #\Null))
         (destination-storage (make-array 257 :element-type 'character :initial-element #\/))
         (source (make-array 256 :element-type 'character :adjustable t :fill-pointer 255
                                :displaced-to source-storage :displaced-index-offset 1))
         (destination (make-array 256 :element-type 'character :adjustable t :fill-pointer 1
                                     :displaced-to destination-storage :displaced-index-offset 1)))
    (fill source #\s)
    (fill destination #\d)
    (rename-test-success source destination)))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest TEST-REQ-REC-001-IO-RENAME-PRIVATE-COPIES-BEFORE-CALLBACK-EFFECT
  (let* ((storage (make-array 8 :element-type 'base-char :initial-contents "src.dest"))
         (source (make-array 3 :element-type 'base-char :displaced-to storage))
         (destination (make-array 4 :element-type 'base-char :displaced-to storage
                                    :displaced-index-offset 4))
         (context (rename-test-fixture
                   (lambda (fd actual-source actual-destination)
                     (is (= 41 fd))
                     (is (typep actual-source 'simple-base-string))
                     (is (typep actual-destination 'simple-base-string))
                     (is (not (eq source actual-source)))
                     (is (not (eq destination actual-destination)))
                     (is (not (eq actual-source actual-destination)))
                     ;; Violazione deliberata: il chiamante altera lo storage durante il callback.
                     (setf (char storage 0) #\x (char storage 4) #\y)
                     (is (string= "src" actual-source))
                     (is (string= "dest" actual-destination))
                     0))))
    (is (null (rename-test-call context source destination)))
    (is (string= "xrc" source))
    (is (string= "yest" destination))
    (rename-test-check-file context :open)
    (rename-test-check-events context '(:open :rename))))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-AFF-004-IO-RENAME-NON-STRING-NAMES
  (dolist (name (list nil 17 #\a :source '(#\a) (vector #\a)
                     (bytes 65) (make-pathname :name "source" :type "tmp")))
    (rename-test-invalid-name name)))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-REC-001-IO-RENAME-EMPTY-NAME
  (rename-test-invalid-name ""))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-REC-001-IO-RENAME-NAME-OVER-MAXIMUM
  (rename-test-invalid-name (make-string 256 :initial-element #\a)))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-REC-001-IO-RENAME-NUL-NAME
  (dolist (name (list (string #\Null) (format nil "~Ca" #\Null)
                     (format nil "a~Cb" #\Null) (format nil "a~C" #\Null)))
    (rename-test-invalid-name name)))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-REC-001-IO-RENAME-SLASH-NAME
  (dolist (name '("/" "/source" "source/" "source/destination"))
    (rename-test-invalid-name name)))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-REC-001-IO-RENAME-DOT-NAME
  (rename-test-invalid-name "."))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-REC-001-IO-RENAME-DOTDOT-NAME
  (rename-test-invalid-name ".."))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-REC-001-IO-RENAME-NON-ASCII-NAME
  (dolist (code '(128 233 8364))
    (let ((character (code-char code)))
      (dolist (name (list (string character) (format nil "~Ca" character)
                         (format nil "a~Cb" character) (format nil "a~C" character)))
        (rename-test-invalid-name name)))))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-REC-001-IO-RENAME-FORBIDDEN-LAST-CHARACTER-AT-MAXIMUM-LENGTH
  (dolist (code '(0 47 128))
    (let ((name (make-string 255 :initial-element #\a)))
      (setf (char name 254) (code-char code))
      (rename-test-invalid-name name))))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-REC-001-IO-RENAME-SAME-NAME-SAME-STRING
  (let ((context (rename-test-fixture #'rename-test-zero)) (name (copy-seq "source.tmp")))
    (signals invalid-argument (rename-test-call context name name) :io-rename-same-name)
    (rename-test-check-file context :open)
    (rename-test-check-events context '(:open))
    (is (null (rename-test-call context name "destination.seg")))
    (rename-test-check-file context :open)
    (rename-test-check-events context '(:open :rename))))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-REC-001-IO-RENAME-SAME-NAME-DISTINCT-STRINGS
  (let ((context (rename-test-fixture #'rename-test-zero))
        (source (copy-seq "source.tmp")) (destination (copy-seq "source.tmp")))
    (is (not (eq source destination)))
    (signals invalid-argument (rename-test-call context source destination) :io-rename-same-name)
    (rename-test-check-file context :open)
    (rename-test-check-events context '(:open))))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-AFF-004-IO-RENAME-INPUT-CAPABILITY
  (let ((context (rename-test-fixture #'rename-test-zero :mode :input)))
    (signals invalid-argument (rename-test-call context "source.tmp" "destination.seg") :io-mode)
    (rename-test-check-file context :open :mode :input)
    (rename-test-check-events context '(:open))))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-AFF-004-IO-RENAME-APPEND-CAPABILITY
  (let ((context (rename-test-fixture #'rename-test-zero :mode :append)))
    (signals invalid-argument (rename-test-call context "source.tmp" "destination.seg") :io-mode)
    (rename-test-check-file context :open :mode :append)
    (rename-test-check-events context '(:open))))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-AFF-004-IO-RENAME-CLOSED-DIRECTORY
  (let ((context (rename-test-fixture #'rename-test-zero)))
    (is (null (chiudi (rename-test-file context))))
    (signals io-fault (rename-test-call context "source.tmp" "destination.seg") :io-unavailable)
    (rename-test-check-file context :closed)
    (rename-test-check-events context '(:open :close))))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-AFF-004-IO-RENAME-FAULTED-DIRECTORY
  (let ((context (rename-test-fixture #'rename-test-zero)))
    ;; Iniezione isolata dello stato precedente, senza un primo errore di rinomina.
    (setf (arcdocdb.io::file-state (rename-test-file context)) :faulted)
    (signals io-fault (rename-test-call context "source.tmp" "destination.seg") :io-unavailable)
    (rename-test-check-file context :faulted)
    (rename-test-check-events context '(:open))))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-AFF-004-IO-RENAME-INVALID-PRIVATE-DESCRIPTOR
  (let ((context (rename-test-fixture #'rename-test-zero)))
    (setf (arcdocdb.io::file-fd (rename-test-file context)) -1)
    (signals invariant-violation (rename-test-call context "source.tmp" "destination.seg")
      :io-descriptor)
    (rename-test-check-file context :open :fd -1)
    (rename-test-check-events context '(:open))))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-AFF-004-IO-RENAME-BACKEND-KEYWORD-OMITTED
  (let ((context (rename-test-fixture nil :include-rename nil)))
    (dotimes (attempt 2)
      (signals arcdocdb.conditions:unsupported-format
        (rename-test-call context "source.tmp" "destination.seg") :io-rename-unavailable)
      (rename-test-check-file context :open)
      (rename-test-check-events context '(:open)))))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest TEST-REQ-AFF-004-IO-RENAME-BACKEND-CALLBACK-NIL
  (let ((context (rename-test-fixture nil)))
    (signals arcdocdb.conditions:unsupported-format
      (rename-test-call context "source.tmp" "destination.seg") :io-rename-unavailable)
    (rename-test-check-file context :open)
    (rename-test-check-events context '(:open))))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest TEST-REQ-REC-001-IO-RENAME-BACKEND-CALLBACK-PRESENT-SINGLE-CALL
  (rename-test-success "unverified.payload" "unverified.destination"))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest TEST-REQ-REC-001-IO-RENAME-DIRECTORY-DESCRIPTOR-BOUNDARIES
  (rename-test-success "source.tmp" "destination.seg" :fd 0)
  (rename-test-success "source.tmp" "destination.seg" :fd 2147483647))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest TEST-REQ-AFF-001-IO-RENAME-FLUSH-IS-SEPARATE
  (let ((context (rename-test-fixture #'rename-test-zero)))
    (is (null (rename-test-call context "source.tmp" "destination.seg")))
    (rename-test-check-file context :open)
    (rename-test-check-events context '(:open :rename))
    (is (= 23 (durable-flush (rename-test-file context))))
    (is (eq :open (stato-file (rename-test-file context))))
    (is (= 23 (posizione-scritta (rename-test-file context))))
    (is (= 23 (posizione-durevole (rename-test-file context))))
    (rename-test-check-events context '(:open :rename :directory-flush))
    (is (equal '(:directory-flush 41) (first (rename-test-events context))))))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-ENOENT-NO-RETRY-OR-CLOSE
  (rename-test-errno sb-posix:enoent))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-EIO-NO-RETRY-OR-CLOSE
  (rename-test-errno sb-posix:eio))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-EINTR-NO-RETRY-OR-CLOSE
  (rename-test-errno sb-posix:eintr))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-NIL-RESULT-FAULTS
  (rename-test-result nil))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-POSITIVE-RESULT-FAULTS
  (rename-test-result 1))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-NEGATIVE-RESULT-FAULTS
  (rename-test-result -1))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-NON-INTEGER-ZERO-RESULT-FAULTS
  (rename-test-result 0.0d0))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-CALLBACK-CLOSE-THEN-RETURN-ONE-KEEPS-CLOSED
  (rename-test-close-callback-failure
   (lambda (fd source destination)
     (declare (ignore fd source destination)) 1)
   :io-rename-result nil))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-CALLBACK-CLOSE-THEN-EIO-KEEPS-CLOSED
  (rename-test-close-callback-failure (raises-errno sb-posix:eio) :io-syscall sb-posix:eio))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-CALLBACK-CLOSE-THEN-ZERO-KEEPS-CLOSED
  (let ((context nil))
    ;; Callback fidati non fanno close; qui si forza il rifiuto del controllo dopo l'effetto.
    (setf context
          (rename-test-fixture
           (lambda (fd source destination)
             (declare (ignore fd source destination))
             (is (null (chiudi (rename-test-file context))))
             0)))
    (signals io-fault (rename-test-call context "source.tmp" "destination.seg") :io-unavailable)
    (rename-test-check-closed-after-callback context)))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-004-IO-RENAME-ORIGINAL-TYPED-CONDITION-PRESERVED
  (rename-test-original-condition
   (make-condition 'resource-exhausted :reason :rename-test-callback-fault)))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-004-IO-RENAME-ORIGINAL-FOREIGN-CONDITION-PRESERVED
  (rename-test-original-condition
   (make-condition 'simple-error :format-control "Guasto del callback rinomina iniettato.")))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-CONDITION-DURING-CALLBACK-RETURN
  (let* ((original (make-condition 'invariant-violation :reason :rename-test-return-fault))
         (cleanups 0)
         (context (rename-test-fixture
                   (lambda (fd source destination)
                     (declare (ignore fd source destination))
                     ;; Il risultato zero è già valutato, ma il callback non completa il ritorno.
                     (unwind-protect 0 (incf cleanups) (error original))))))
    (is (eq original
            (handler-case (rename-test-call context "source.tmp" "destination.seg")
              (invariant-violation (condition) condition))))
    (is (= 1 cleanups))
    (rename-test-check-faulted context)))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-SYSCALL-ERROR-DURING-CALLBACK-RETURN
  (let ((context (rename-test-fixture
                  (lambda (fd source destination)
                    (declare (ignore fd source destination))
                    (unwind-protect 0
                      (error 'sb-posix:syscall-error :errno sb-posix:eio :name 'rename-return))))))
    (rename-test-io-failure context :io-syscall sb-posix:eio)))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-NONLOCAL-EXIT-CLEANUP-FAULTS-BEFORE-CALLER-CLEANUP
  (let ((context nil) (marker (list :rename-test-escape)) (state-at-caller-cleanup nil))
    (is (eq marker
            (block escaped
              (setf context
                    (rename-test-fixture
                     (lambda (fd source destination)
                       (declare (ignore fd source destination)) (return-from escaped marker))))
              (unwind-protect
                   (progn (rename-test-call context "source.tmp" "destination.seg") :fell-through)
                (setf state-at-caller-cleanup (stato-file (rename-test-file context)))))))
    (is (eq :faulted state-at-caller-cleanup))
    (rename-test-check-faulted context)))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-HANDLER-NONLOCAL-EXIT-CLEANUP-FAULTS
  (let ((original (make-condition 'resource-exhausted :reason :rename-test-handler-fault))
        (context nil) (observed nil) (marker (list :rename-test-handler-escape)))
    (is (eq marker
            (block escaped
              (setf context
                    (rename-test-fixture
                     (lambda (fd source destination)
                       (declare (ignore fd source destination)) (error original))))
              (handler-bind ((resource-exhausted
                               (lambda (condition)
                                 (setf observed condition) (return-from escaped marker))))
                (rename-test-call context "source.tmp" "destination.seg"))
              :fell-through)))
    (is (eq original observed))
    (rename-test-check-faulted context)))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-LOCAL-INTERRUPT-PROBE-CLEANUP-BOUNDARIES
  ;; Probe sincrona e bounded: tre osservazioni, nessun timer/thread/hook globale.
  ;; Verifica callback/handler non mascherati e cleanup completato prima dell'uscita.
  ;; Non inietta un interrupt asincrono nel singolo store interno del prodotto.
  (is sb-sys:*interrupts-enabled*)
  (let ((sb-sys:*interrupts-enabled* sb-sys:*interrupts-enabled*)
        (sb-sys:*allow-with-interrupts* sb-sys:*allow-with-interrupts*)
        (original (make-condition 'resource-exhausted :reason :rename-test-interrupt-probe))
        (context nil) (marker (list :rename-test-probe-exit)) (observations nil))
    (flet ((observe (phase)
             (push (list phase sb-sys:*interrupts-enabled*
                         (stato-file (rename-test-file context))) observations)))
      (is (eq marker
              (block interrupted
                (setf context
                      (rename-test-fixture
                       (lambda (fd source destination)
                         (declare (ignore fd source destination))
                         (observe :callback)
                         (error original))))
                (unwind-protect
                     (handler-bind ((resource-exhausted
                                      (lambda (condition)
                                        (is (eq original condition))
                                        (observe :handler)
                                        (return-from interrupted marker))))
                       (rename-test-call context "source.tmp" "destination.seg"))
                  (observe :caller-cleanup)))))
      (is (equal '((:callback t :open) (:handler t :open) (:caller-cleanup t :faulted))
                 (reverse observations)))
      (is sb-sys:*interrupts-enabled*)
      (rename-test-check-faulted context))))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-LOCAL-INTERRUPT-PROBE-FAILURE-SIGNAL
  ;; Due casi deterministici: nonzero e syscall-error, con probe ai soli confini pubblici.
  (is sb-sys:*interrupts-enabled*)
  (dolist (errno (list nil sb-posix:eio))
    (let ((sb-sys:*interrupts-enabled* sb-sys:*interrupts-enabled*)
          (callback-enabled nil) (handler-enabled nil) (state-at-signal nil)
          (caught nil) (context nil))
      (setf context
            (rename-test-fixture
             (lambda (fd source destination)
               (declare (ignore fd source destination))
               (setf callback-enabled sb-sys:*interrupts-enabled*)
               (if errno
                   (error 'sb-posix:syscall-error :errno errno :name 'rename-probe)
                   1))))
      (handler-case
          (handler-bind ((io-fault
                           (lambda (condition)
                             (setf caught condition
                                   handler-enabled sb-sys:*interrupts-enabled*
                                   state-at-signal (stato-file (rename-test-file context))))))
            (rename-test-call context "source.tmp" "destination.seg"))
        (io-fault (condition) (is (eq caught condition))))
      (is (typep caught 'io-fault))
      (is callback-enabled)
      (is handler-enabled)
      (is (eq :faulted state-at-signal))
      (is (eq :rename (error-operation caught)))
      (is (eq (if errno :io-syscall :io-rename-result) (error-reason caught)))
      (is (eql errno (error-errno caught)))
      (is sb-sys:*interrupts-enabled*)
      (rename-test-check-faulted context))))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-004-IO-RENAME-RESULT-HANDLER-CONDITION-PRESERVED
  (let ((context (rename-test-fixture
                  (lambda (fd source destination)
                    (declare (ignore fd source destination)) nil)))
        (original (make-condition 'resource-exhausted :reason :rename-test-result-handler))
        (observed nil) (state-at-signal nil))
    (is (eq original
            (handler-case
                (handler-bind ((io-fault
                                 (lambda (condition)
                                   (setf observed condition
                                         state-at-signal (stato-file (rename-test-file context)))
                                   (error original))))
                  (rename-test-call context "source.tmp" "destination.seg"))
              (resource-exhausted (condition) condition))))
    (is (typep observed 'io-fault))
    (is (eq :io-rename-result (error-reason observed)))
    (is (eq :faulted state-at-signal))
    (rename-test-check-faulted context)))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-REC-001-IO-RENAME-POSTCHECKER-NIL-SUCCESS
  (let ((context (rename-test-fixture #'rename-test-zero)) (checks 0))
    (is (equal '(nil)
               (multiple-value-list
                (rename-test-post-call
                 context (lambda ()
                           (incf checks)
                           (is (= 1 checks))
                           (rename-test-post-entry context)
                           nil)))))
    (is (= 1 checks))
    (rename-test-check-file context :open)
    (rename-test-check-events context '(:open :rename))))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-POSTCHECKER-NON-NIL-RESULT-FAULTS
  ;; Anche zero è non NIL: il postchecker ha un contratto distinto dal callback POSIX.
  (dolist (result '(t 0 1 :unexpected))
    (let ((context (rename-test-fixture #'rename-test-zero)) (checks 0)
          (caught nil) (observed nil) (state-at-signal nil))
      (handler-case
          (handler-bind ((io-fault
                           (lambda (condition)
                             (setf observed condition
                                   state-at-signal (stato-file (rename-test-file context))))))
            (rename-test-post-call
             context (lambda ()
                       (incf checks)
                       (is (= 1 checks))
                       (rename-test-post-entry context)
                       result)))
        (io-fault (condition) (setf caught condition)))
      (is (= 1 checks))
      (is (typep caught 'io-fault))
      (is (eq caught observed))
      (is (eq :faulted state-at-signal))
      (is (eq :io-rename-post-result (error-reason caught)))
      (is (eq :rename (error-operation caught)))
      (is (null (error-errno caught)))
      (is (= 0 (error-transferred caught)))
      (is (null (arcdocdb.conditions:error-cleanup-errno caught)))
      (rename-test-check-faulted context))))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest TEST-REQ-AFF-001-IO-RENAME-POSTCHECKER-INCOMPLETE-EXIT-FAULTS
  ;; Due fixture isolate: condizione originale e uscita nonlocale dopo l'effetto riuscito.
  (dolist (exit '(:condition :nonlocal))
    (let ((context (rename-test-fixture #'rename-test-zero)) (checks 0)
          (original (make-condition 'resource-exhausted :reason :rename-test-postchecker-fault))
          (marker (list :rename-test-postchecker-exit)) (state-at-caller-cleanup nil))
      (let ((result
              (handler-case
                  (block post-exit
                    (unwind-protect
                         (progn
                           (rename-test-post-call
                            context (lambda ()
                                      (incf checks)
                                      (is (= 1 checks))
                                      (rename-test-post-entry context)
                                      (ecase exit
                                        (:condition (error original))
                                        (:nonlocal (return-from post-exit marker)))))
                           :fell-through)
                      (setf state-at-caller-cleanup (stato-file (rename-test-file context)))))
                (resource-exhausted (condition) condition))))
        (is (eq (ecase exit (:condition original) (:nonlocal marker)) result)))
      (is (= 1 checks))
      (is (eq :faulted state-at-caller-cleanup))
      (rename-test-check-faulted context))))
