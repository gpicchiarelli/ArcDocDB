;;;; Fixture native del ponte fonti GET/controller; soltanto definizioni, nessuna esecuzione.
;;; OWNER: runner seriale possiede fixture, lease, FD append e hook FI; GET possiede il suo EBR.
;;; SHARED: directory/mappe/root immutabili; nessun thread durante la sostituzione delle funzioni.
;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-CMP-007 REQ-AFF-008
;;; RISCHI STATICI / verifica centralizzata dopo freeze tramite tools/record-command.lisp:
;;; - Compilazione, warning, test e copertura non verificati in questa consegna.
;;; - ASDF deve caricare questo file dopo support/read/threads e prima di series-read.
;;; - FI su SYMBOL-FUNCTION strettamente seriale: non eseguire questi casi in parallelo.
;;; - FD e file temporanei restano vivi fino all'abbandono di tutti i contesti GET.
;;; - Nessuna evidenza prestazionale, di zero heap o di reclaim concorrente dai casi nativi.
;;; - Arity della sonda: :OUTCOME-OFFSET rimosso dal prodotto durante la stesura, correzione solo letta.
;;; - tests/get/active* assenti nel worktree: fixture ACTIVE locale, directory e osservatore riusati.
;;; - FI superset/primary anticipato/geometria non attestano rotation, reclaim o fonti native sintetiche.
;;; - EMPTY-ACTIVE-P assume EDIT gia' durevole a cura del caller; non simula catalogo/recovery.
;;; - IO-EVENTS osserva il backend ACTIVE nativo; CLOSED mantiene il proprio osservatore pread.
(in-package #:arcdocdb.get.directory.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-CMP-007
(defstruct (directory-series-fixture (:constructor %make-directory-series-fixture))
  "Pre: setup esclusivo. Post: directory CLOSED riusata, ACTIVE nativo opzionale e un controller.
La fixture mantiene due FD del medesimo file; cleanup solo dopo l'ultimo accesso GET."
  (directory nil :type (or null directory-fixture))
  (file nil :type t) (readonly nil :type t) (path nil :type t) (backend nil :type t)
  (registry nil :type t) (log nil :type t) (controller nil :type t) (lease nil :type t)
  (source nil :type t) (sources nil :type t) (root nil :type t) (planned nil :type t)
  (io-events nil :type list)
  (active-key nil :type t) (active-value nil :type t)
  (active-id 13 :type (unsigned-byte 32)) (next 64 :type fixnum))

;;; REQ: REQ-WAL-005 REQ-WAL-006
(defstruct (directory-series-commit
             (:constructor make-directory-series-commit
                 (batch event generation root key value start size csn)))
  "Pre: SEALED adottato con token catturato. Post: descrittore fixture immutabile del commit.
I valori attesi derivano dagli input e dal token WAL, mai dal risultato del resolver."
  (batch nil :type t :read-only t) (event nil :type t :read-only t)
  (generation 0 :type fixnum :read-only t) (root nil :type t :read-only t)
  (key nil :type t :read-only t) (value nil :type t :read-only t)
  (start 64 :type fixnum :read-only t) (size 0 :type fixnum :read-only t)
  (csn 0 :type (unsigned-byte 64) :read-only t))

;;; REQ: REQ-CMP-007 REQ-AFF-001
(defun close-directory-series-fixture (fixture)
  "Pre: runner proprietario, nessun worker in volo. Post: GET abbandonati prima dei FD.
Cleanup idempotente; risorse/file appartengono soltanto a questa fixture."
  (unwind-protect
       (when (directory-series-fixture-directory fixture)
         (map nil (lambda (context) (when context (g:abbandona-get context)))
              (directory-fixture-contexts (directory-series-fixture-directory fixture))))
    (unwind-protect
         (when (directory-series-fixture-lease fixture)
           (arcdocdb.series:rilascia-controllore-serie
            (directory-series-fixture-controller fixture) (directory-series-fixture-lease fixture))
           (setf (directory-series-fixture-lease fixture) nil))
      (unwind-protect
           (when (directory-series-fixture-readonly fixture)
             (io:chiudi (directory-series-fixture-readonly fixture)))
        (unwind-protect
             (when (directory-series-fixture-file fixture)
               (io:chiudi (directory-series-fixture-file fixture)))
          (let ((path (directory-series-fixture-path fixture)))
            (when (and path (probe-file path)) (sb-posix:unlink (namestring path))))
          (when (directory-series-fixture-directory fixture)
            (close-directory-fixture (directory-series-fixture-directory fixture)))))))
  nil)

;;; REQ: REQ-WAL-002 REQ-FOR-001
(defun directory-series-observed-io (fixture operation function)
  "Pre: backend della sola fixture seriale. Post: operazione contata prima della syscall nativa.
Nessuna sostituzione prodotto; l'osservatore alloca e non e' un corpo da benchmark."
  (lambda (&rest arguments)
    (push operation (directory-series-fixture-io-events fixture))
    (apply function arguments)))

;;; REQ: REQ-WAL-002 REQ-FOR-001
(defun directory-series-native-log (fixture)
  "Pre: directory nativa posseduta. Post: header writer sincronizzato e log append a offset 64.
Backend nativo senza sostituzione; contatore I/O ACTIVE e osservazione pread della directory."
  (let* ((directory (directory-series-fixture-directory fixture))
         (path (merge-pathnames "series-active.tmp" (directory-fixture-root directory)))
         (header (directory-octets 64))
         (observed (directory-observed-backend (directory-fixture-observer directory)
                                              (directory-series-fixture-active-id fixture)))
         (backend (io:make-backend
                   (directory-series-observed-io fixture :open (io::backend-open observed))
                   (directory-series-observed-io fixture :read (io::backend-reader observed))
                   (directory-series-observed-io fixture :write (io::backend-writer observed))
                   (directory-series-observed-io fixture :flush (io::backend-flush observed))
                   (directory-series-observed-io fixture :directory-flush (io::backend-directory-flush observed))
                   (directory-series-observed-io fixture :close (io::backend-close observed))
                   :identity (directory-series-observed-io fixture :identity #'io::native-identity)))
         (file (io:crea-temporaneo path :backend backend)))
    (setf (directory-series-fixture-path fixture) path (directory-series-fixture-file fixture) file
          (directory-series-fixture-backend fixture) backend)
    (arcdocdb.storage.format:scrivi-header-segmento
     header 0 (g::vista-get-serie-identity (directory-fixture-view directory))
     (directory-series-fixture-active-id fixture) 123456
     :version (directory-fixture-version directory) :origine 1)
    (io:append-esatto file header 0 64)
    (io:durable-flush file)
    (setf (directory-series-fixture-registry fixture)
          (arcdocdb.csn:crea-registro-csn :capacity 8 :initial-low 1)
          (directory-series-fixture-log fixture)
          (arcdocdb.wal:crea-log-io file :segment (directory-series-fixture-active-id fixture)
                                   :version (directory-fixture-version directory)))))

;;; REQ: REQ-IDX-001 REQ-WAL-006
(defun directory-series-native-source (fixture)
  "Pre: controller iniziale NIL e header writer durevole. Post: source del medesimo file readonly.
Header letto realmente dal resolver; nessuna mappa o frontiera sintetica."
  (let* ((directory (directory-series-fixture-directory fixture))
         (file (io:apri-lettura
                (directory-series-fixture-path fixture)
                :backend (directory-series-fixture-backend fixture))))
    (setf (directory-series-fixture-readonly fixture) file
          (directory-series-fixture-source fixture)
          (r:crea-sorgente-get-attiva
           (directory-series-fixture-controller fixture) (directory-series-fixture-lease fixture)
           (g:crea-segmento-get (directory-fixture-view directory) file
                               (directory-series-fixture-active-id fixture) (directory-octets 64))
           :max-pages 4 :max-puts 4 :batch-records 1 :batch-bytes 256 :budget-payload 4096
           :associazione-file (io:associa-file file (directory-series-fixture-file fixture))))))

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-AFF-008
(defun make-directory-series-fixture (&key (count 2) (workers 4) (version 2) (cache-p nil)
                                          (prepared-p nil) (active-p nil) (empty-active-p nil) (active-id 13)
                                          (publish-active-p (and active-p (not empty-active-p)))
                                          (record-bytes 56) content (root nil root-p))
  "Pre: setup seriale. Post: fixture CLOSED esistente, controller nativo e ACTIVE opzionale.
Root CLOSED = fonti; root ACTIVE = delta WAL pubblicato con fonti come content.
EMPTY-ACTIVE-P crea source e pubblica il solo header con fonti CLOSED; nessun lotto/CSN.
EDIT durevole e lifetime EBR sono precondizioni del caller, fuori da questa fixture.
ROOT esplicita e PUBLISH-ACTIVE-P NIL servono soltanto ai test di rifiuto/FI."
  (let ((fixture (%make-directory-series-fixture :active-id active-id)) (complete nil))
    (unwind-protect
         (progn
           (setf (directory-series-fixture-directory fixture)
                 (make-directory-fixture :count count :workers workers :version version
                                         :cache-p cache-p :prepared-p prepared-p :csn 1
                                         :record-bytes record-bytes :observe-io-p t)
                 (directory-series-fixture-active-key fixture) (directory-key 1000)
                 (directory-series-fixture-active-value fixture) (directory-value 1000 16)
                 (directory-series-fixture-sources fixture)
                 (d:crea-fonti-get-serie
                  (directory-fixture-directory (directory-series-fixture-directory fixture)) :content content))
           (directory-series-native-log fixture)
           (let ((initial (if root-p root
                              (unless (or active-p empty-active-p) (directory-series-fixture-sources fixture)))))
             (setf (directory-series-fixture-root fixture) initial
                   (directory-series-fixture-planned fixture) initial
                   (directory-series-fixture-controller fixture)
                   (arcdocdb.series:crea-controllore-serie
                    (directory-series-fixture-registry fixture) (directory-series-fixture-log fixture)
                    :capacity 4 :root initial :next-offset 64)
                   (directory-series-fixture-lease fixture)
                   (arcdocdb.series:acquisisci-controllore-serie (directory-series-fixture-controller fixture))))
           (when (or active-p empty-active-p) (directory-series-native-source fixture))
           (when empty-active-p (directory-series-initialize-empty fixture))
           (when publish-active-p
             (directory-series-publish fixture
                                       (directory-series-stage fixture
                                                               (directory-series-fixture-active-key fixture)
                                                               (directory-series-fixture-active-value fixture))))
           (directory-clear-read-events (directory-series-fixture-directory fixture))
           (setf (directory-series-fixture-io-events fixture) nil)
           (setf complete t)
           fixture)
      (unless complete (close-directory-series-fixture fixture)))))

;;; REQ: REQ-CMP-007 REQ-AFF-001
(defun call-with-directory-series-fixture (thunk &rest options)
  "Pre: runner seriale. Post: chiusura della fixture anche quando il test segnala una condizione."
  (let ((fixture (apply #'make-directory-series-fixture options)))
    (unwind-protect (funcall thunk fixture) (close-directory-series-fixture fixture))))

;;; REQ: REQ-WAL-006 REQ-IDX-001 REQ-AFF-008
(defun directory-series-clear-io-events (fixture)
  "Pre: operazione seriale terminata. Post: setup/I/O precedente esclusi dall'oracolo seguente."
  (setf (directory-series-fixture-io-events fixture) nil)
  (directory-clear-read-events (directory-series-fixture-directory fixture)))

;;; REQ: REQ-WAL-006 REQ-IDX-001 REQ-AFF-008
(defun directory-series-check-empty-root (fixture root &optional (content (directory-series-fixture-sources fixture)))
  "Pre: root restituita dalla factory. Post: forma vuota confrontata con costanti e input fixture."
  (is (typep root 'r:radice-get-attiva))
  (is (eq (directory-series-fixture-source fixture) (r::radice-get-attiva-source root)))
  (is (null (r::radice-get-attiva-directory root)))
  (is (= 0 (r::radice-get-attiva-count root)))
  (is (= 0 (r::radice-get-attiva-puts root)))
  (is (= 0 (r::radice-get-attiva-nodes root)))
  (is (= 64 (r::radice-get-attiva-end root)))
  (is (= 0 (r:payload-radice-get-attiva root)))
  (is (eq content (r:contenuto-radice-get-attiva root)))
  t)

;;; REQ: REQ-WAL-006 REQ-MVC-008 REQ-CON-002 REQ-AFF-001
(defun directory-series-check-initial-state (fixture root &key (written 64) (durable 64)
                                                            (next-offset 64) (readonly-state :open)
                                                            (append-state :open))
  "Pre: nessun lotto sigillato/adottato. Post: root attesa, ring vergine e CSN base=1 intatti.
Frontiere attese esplicite per i rifiuti su file realmente avanzato; nessuna lettura da EOF."
  (let ((controller (directory-series-fixture-controller fixture))
        (registry (directory-series-fixture-registry fixture)))
    (is (eq root (arcdocdb.series:leggi-radice-serie controller)))
    (is (eq root (arcdocdb.series::controllore-serie-planned-root controller)))
    (is (eq sb-thread:*current-thread* (arcdocdb.series::controllore-serie-owner controller)))
    (is (= (directory-series-fixture-lease fixture) (arcdocdb.series::controllore-serie-lease-generation controller)))
    (is (equal '(0 0 0) (multiple-value-list
                         (arcdocdb.series:conta-commit-serie controller (directory-series-fixture-lease fixture)))))
    (is (= 0 (arcdocdb.series::controllore-serie-event-generation controller)))
    (is (= 0 (arcdocdb.series::controllore-serie-head controller)))
    (is (= 0 (arcdocdb.series::controllore-serie-tail controller)))
    (is (= 0 (arcdocdb.series::controllore-serie-publish-head controller)))
    (is (= 0 (arcdocdb.series::controllore-serie-last-high controller)))
    (is (= 0 (arcdocdb.series::controllore-serie-last-low controller)))
    (is (null (arcdocdb.series::controllore-serie-effect-active controller)))
    (map nil (lambda (event)
               (is (eq :libero (arcdocdb.series::commit-serie-phase event)))
               (is (eq :idle (arcdocdb.series::commit-serie-io-state event)))
               (is (= 0 (arcdocdb.series::commit-serie-generation event)))
               (is (= 0 (arcdocdb.series::commit-serie-slot event)))
               (is (= 0 (arcdocdb.series::commit-serie-high event)))
               (is (= 0 (arcdocdb.series::commit-serie-low event)))
               (is (null (arcdocdb.series::commit-serie-lotto event)))
               (is (null (arcdocdb.series::commit-serie-expected-root event)))
               (is (null (arcdocdb.series::commit-serie-root event))))
         (arcdocdb.series::controllore-serie-slots controller))
    (is (= next-offset (arcdocdb.series::controllore-serie-next-offset controller)))
    (is (= written (io:posizione-scritta (directory-series-fixture-file fixture))))
    (is (= durable (io:posizione-durevole (directory-series-fixture-file fixture))))
    (is (eq :append (io:mode-file (directory-series-fixture-file fixture))))
    (is (eq append-state (io:stato-file (directory-series-fixture-file fixture))))
    (when (directory-series-fixture-readonly fixture)
      (is (eq :input (io:mode-file (directory-series-fixture-readonly fixture))))
      (is (eq readonly-state (io:stato-file (directory-series-fixture-readonly fixture)))))
    (is (eq :open (arcdocdb.wal:stato-log (directory-series-fixture-log fixture))))
    (is (null (arcdocdb.wal::log-io-active (directory-series-fixture-log fixture))))
    (is (eq :healthy (arcdocdb.series:stato-controllore-serie controller)))
    (is (eq :none (arcdocdb.series:ambito-fault-serie controller)))
    (is (equal '(0 1 0 1) (multiple-value-list (arcdocdb.csn:leggi-frontiere-csn registry))))
    (is (= 0 (arcdocdb.csn::registro-csn-used registry)))
    (is (= 0 (arcdocdb.csn::registro-csn-cursor registry)))
    (is (every #'zerop (arcdocdb.csn::registro-csn-highs registry)))
    (is (every #'zerop (arcdocdb.csn::registro-csn-lows registry)))
    (is (null (directory-series-fixture-io-events fixture)))
    (is (null (directory-read-events (directory-series-fixture-directory fixture))))
    (is (directory-check-clean (directory-series-fixture-directory fixture))))
  t)

;;; REQ: REQ-WAL-006 REQ-IDX-001 REQ-CMP-007
(defun directory-series-initialize-empty (fixture)
  "Pre: source pronta, EDIT gia' durevole e controller vergine. Post: root vuota pubblicata.
La fixture conserva proprio la root restituita come PREVIOUS del primo lotto."
  (directory-series-clear-io-events fixture)
  (directory-series-check-initial-state fixture nil)
  (let ((root (d:inizializza-fonti-get-attive
               (directory-series-fixture-source fixture) (directory-series-fixture-lease fixture)
               (directory-series-fixture-sources fixture))))
    (setf (directory-series-fixture-root fixture) root (directory-series-fixture-planned fixture) root)
    (directory-series-check-empty-root fixture root)
    (directory-series-check-initial-state fixture root)
    root))

;;; REQ: REQ-WAL-005 REQ-IDX-001
(defun directory-series-seal (fixture key value)
  "Pre: writer con lease, source pronta. Post: OPEN verificato prima di CSN, poi SEALED con token.
Nessun evento adottato o I/O; caller conserva l'obbligo se l'adozione viene rifiutata."
  (let ((batch (arcdocdb.wal:crea-lotto :segment (directory-series-fixture-active-id fixture)
                                      :version (directory-fixture-version
                                                (directory-series-fixture-directory fixture))
                                      :capacity 256 :max-records 1)))
    (arcdocdb.wal:aggiungi-record batch 1 key value)
    (is (= 1 (r:verifica-capienza-get-attiva
              (directory-series-fixture-source fixture) (directory-series-fixture-lease fixture)
              batch (directory-series-fixture-planned fixture))))
    (arcdocdb.wal:sigilla-lotto-con-csn
     batch (directory-series-fixture-registry fixture) (directory-series-fixture-log fixture)
     (directory-series-fixture-next fixture) (io:posizione-durevole (directory-series-fixture-file fixture)))
    batch))

;;; REQ: REQ-WAL-005 REQ-WAL-006
(defun directory-series-stage (fixture key value &key (sources (directory-series-fixture-sources fixture))
                                                     (checked-p t) batch)
  "Pre: lease e root pianificata stabili. Post: evento/CSN/root catturati, nessuna pubblicazione.
CHECKED-P NIL usa il writer generico esistente per FI sul content, mai per il percorso sano."
  (let ((lot (or batch (directory-series-seal fixture key value)))
        (controller (directory-series-fixture-controller fixture)))
    (multiple-value-bind (event generation root)
        (funcall (if checked-p #'d:registra-lotto-fonti-get-attivo #'r:registra-lotto-get-attivo)
                 (directory-series-fixture-source fixture) (directory-series-fixture-lease fixture)
                 lot (directory-series-fixture-planned fixture) sources :strong)
      (is (eq :preparato (arcdocdb.series:stato-commit-serie controller event generation)))
      (multiple-value-bind (slot high low) (arcdocdb.wal:leggi-csn-lotto lot)
        (is (<= 0 slot 7))
        (is (equal (list slot high low)
                   (multiple-value-list (arcdocdb.series:leggi-csn-commit-serie controller event generation))))
        (let ((start (directory-series-fixture-next fixture)))
          (setf (directory-series-fixture-planned fixture) root
                (directory-series-fixture-next fixture) (+ start (arcdocdb.wal:lunghezza-lotto lot)))
          (make-directory-series-commit lot event generation root key value start
                                        (+ 24 (length key) (length value)) (+ (* high #x100000000) low)))))))

;;; REQ: REQ-WAL-002 REQ-WAL-006 REQ-MVC-008
(defun directory-series-publish (fixture commit &key (publish-key-p t))
  "Pre: commit adottato. Post: append+flush nativi, completamento I/O, CAS/risoluzione e ritiro.
La location primary viene pubblicata soltanto DOPO le fonti; nessuna lettura della root dal helper."
  (let* ((controller (directory-series-fixture-controller fixture))
         (lease (directory-series-fixture-lease fixture))
         (event (directory-series-commit-event commit)) (generation (directory-series-commit-generation commit))
         (group (arcdocdb.wal:crea-gruppo (directory-series-fixture-log fixture) :max-lots 1 :max-bytes 256)))
    (arcdocdb.wal:aggiungi-lotto group (directory-series-commit-batch commit))
    (arcdocdb.wal:chiudi-gruppo group)
    (is (null (arcdocdb.series:inizia-io-commit-serie controller lease event generation)))
    (arcdocdb.wal:esegui-gruppo group)
    (is (null (arcdocdb.series:completa-io-commit-serie controller lease event generation)))
    (is (equal (list :risolto (ldb (byte 32 32) (directory-series-commit-csn commit))
                             (ldb (byte 32 0) (directory-series-commit-csn commit)))
               (multiple-value-list (arcdocdb.series:pubblica-commit-serie controller lease event generation))))
    (setf (directory-series-fixture-root fixture) (directory-series-commit-root commit))
    ;; Rilascia l'ownership del gruppo prima del riuso del lotto/evento, come nel protocollo reale.
    (is (null (arcdocdb.wal:riusa-gruppo group)))
    (is (null (arcdocdb.series:riusa-commit-serie controller lease event generation)))
    (when publish-key-p
      (directory-publish-key (directory-series-fixture-directory fixture) (directory-series-commit-key commit)
                             (directory-series-commit-csn commit) (directory-series-fixture-active-id fixture)
                             (directory-series-commit-start commit) (directory-series-commit-size commit)))
    commit))

;;; REQ: REQ-IDX-001 REQ-CMP-007
(defun directory-series-context (fixture &optional (worker 0))
  (aref (directory-fixture-contexts (directory-series-fixture-directory fixture)) worker))

;;; REQ: REQ-IDX-001 REQ-CMP-007
(defun directory-series-begin (fixture key &optional (worker 0))
  (fill (aref (directory-fixture-outputs (directory-series-fixture-directory fixture)) worker) +directory-sentinel+)
  (g:avvia-get (directory-series-context fixture worker)
               (directory-fixture-view (directory-series-fixture-directory fixture)) key nil 0 11))

;;; REQ: REQ-IDX-001 REQ-CCH-002 REQ-WAL-006
(defun directory-series-operation (operation context controller)
  (ecase operation
    (:resolve (d:risolvi-candidato-serie-get context controller))
    (:probe (d:sonda-cache-serie-get context controller))
    (:read (d:leggi-record-serie-get context controller))))

;;; REQ: REQ-CON-004 REQ-CMP-007
(defun directory-series-copy-and-finish (fixture value &optional (worker 0))
  "Pre: VERIFIED. Post: bytes d'input e sentinelle confrontati, FOUND dopo conclusione, pin zero."
  (let* ((directory (directory-series-fixture-directory fixture))
         (output (aref (directory-fixture-outputs directory) worker))
         (context (directory-series-context fixture worker)) (end (+ 3 (length value))))
    (is (= end (g:copia-valore-get context output 3)))
    (is (loop for i below 3 always (= +directory-sentinel+ (aref output i))))
    (is (loop for i below (length value) always (= (aref value i) (aref output (+ 3 i)))))
    (is (loop for i from end below (length output) always (= +directory-sentinel+ (aref output i))))
    (is (equal (list :found (length value)) (multiple-value-list (g:concludi-get context 12))))
    (is (directory-check-clean directory worker))))

;;; REQ: REQ-WAL-006 REQ-CMP-007 REQ-AFF-004
(defun directory-series-function-fi (symbol replacement-maker thunk)
  "Pre: runner seriale esclusivo. Post: funzione ripristinata anche su condizione/uscita non locale.
La sostituzione osserva il confine acquire, senza mutare slot delle root o contesti GET."
  (let ((original (symbol-function symbol)))
    (unwind-protect
         (progn (setf (symbol-function symbol) (funcall replacement-maker original)) (funcall thunk))
      (setf (symbol-function symbol) original))))

;;; REQ: REQ-WAL-006 REQ-CMP-007
(defun directory-series-observe-acquire (fixture thunk &key after-read (expected 1))
  "Pre: candidato del worker zero, esecuzione seriale. Post: numero acquire e pin attivo verificati.
AFTER-READ esegue una sola interleaving dopo la cattura; nessuna attesa o thread aggiuntivo."
  (let ((calls 0) (directory (directory-series-fixture-directory fixture)))
    (directory-series-function-fi
     'arcdocdb.series:leggi-radice-serie
     (lambda (original)
       (lambda (controller)
         (incf calls)
         (is (eq controller (directory-series-fixture-controller fixture)))
         (is (e:epoca-attiva-p (e:contesto-epoca (directory-fixture-epochs directory) 0)))
         (let ((root (funcall original controller)))
           (when (and after-read (= calls 1)) (funcall after-read))
           root)))
     thunk)
    (is (= expected calls))))

;;; REQ: REQ-WAL-005 REQ-WAL-006 REQ-AFF-004
(defun directory-series-check-refused-batch (fixture batch token bytes &key (health :healthy) (fault-scope :none))
  "Pre: rifiuto prima dell'adozione di un primo lotto SEALED. Post: obbligo e buffer al caller.
Ring/root/frontiere native restano iniziali; nessuna pubblicazione o I/O da un rifiuto."
  (let ((controller (directory-series-fixture-controller fixture)))
    (is (eq :sealed (arcdocdb.wal:stato-lotto batch)))
    (is (eq :pendente (arcdocdb.wal:stato-csn-lotto batch)))
    (is (equal token (multiple-value-list (arcdocdb.wal:leggi-csn-lotto batch))))
    (is (equalp bytes (arcdocdb.wal::lotto-buffer batch)))
    (is (equal '(0 0 0) (multiple-value-list
                         (arcdocdb.series:conta-commit-serie controller (directory-series-fixture-lease fixture)))))
    (is (null (arcdocdb.series::controllore-serie-root controller)))
    (is (null (arcdocdb.series::controllore-serie-planned-root controller)))
    (is (= 64 (arcdocdb.series::controllore-serie-next-offset controller)))
    (is (= 64 (io:posizione-scritta (directory-series-fixture-file fixture))))
    (is (= 64 (io:posizione-durevole (directory-series-fixture-file fixture))))
    (is (eq health (arcdocdb.series:stato-controllore-serie controller)))
    (is (eq fault-scope (arcdocdb.series:ambito-fault-serie controller)))
    (is (eq :open (arcdocdb.wal:stato-log (directory-series-fixture-log fixture))))))

;;; REQ: REQ-IDX-001 REQ-AFF-004 REQ-CMP-007
(defun directory-series-fi-root-with-segment (fixture segment)
  "FI tipizzata: clone privato di una root nativa, cambia solo la capacita' della source.
La root viene iniettata al confine acquire, senza dipendere dall'inlining degli accessor DEFSTRUCT."
  (let* ((source (directory-series-fixture-source fixture))
         (root (directory-series-fixture-root fixture))
         (copy (r::%make-sorgente-get-attiva
                (directory-series-fixture-controller fixture) segment
                (r::sorgente-get-attiva-max-pages source) (r::sorgente-get-attiva-max-puts source)
                (r::sorgente-get-attiva-batch-records source) (r::sorgente-get-attiva-batch-bytes source)
                (r::sorgente-get-attiva-budget source))))
    (r::%make-radice-get-attiva copy (r::radice-get-attiva-directory root) (r::radice-get-attiva-count root)
                              (r::radice-get-attiva-puts root) (r::radice-get-attiva-nodes root)
                              (r::radice-get-attiva-end root) (r:contenuto-radice-get-attiva root))))

;;; REQ: REQ-IDX-001 REQ-AFF-008 REQ-AFF-004
(defun directory-series-fi-directory-geometry (fixture mode)
  "FI tipizzata e locale: mismatch maps/ids oppure cardinalita' 65.537 con lunghezze uguali.
Nessun ID 13 ACTIVE in CLOSED; l'errore dipende dalla geometria prima della ricerca binaria.
Capacita' sintetiche condividono i FD della fixture; non sono fonti native autorizzabili."
  (let* ((directory (directory-series-fixture-directory fixture))
         (maps (directory-fixture-maps directory))
         (canonical (directory-fixture-directory directory)))
    (ecase mode
      (:maps (d::%make-directory-get-serie (directory-fixture-view directory)
                                          (copy-seq (d::directory-get-serie-ids canonical)) (vector (svref maps 0))))
      (:oversize
       (d::%make-directory-get-serie
        (directory-fixture-view directory)
        (make-array 65537 :element-type '(unsigned-byte 32) :initial-element 17)
        (make-array 65537 :initial-element (svref maps 0)))))))
