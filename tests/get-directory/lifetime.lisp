;;;; GET gia' ammessi e lifetime del FD CLOSED attraverso pubblicazioni ACTIVE reali.
;;; OWNER: writer del runner possiede lease/ticket; un worker possiede il GET bloccato.
;;; SHARED: solo root immutabili, backend fixture e rendezvous bounded; nessun FI di funzioni.
;;; Le gate sono interleaving di verifica, non parcheggio ammesso nel percorso GET reale.
(in-package #:arcdocdb.get.directory.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

(defun directory-lifetime-candidate (fixture context csn id)
  "Pre: worker proprietario del candidato. Post: copia privata confrontata con input/offset letterali."
  (let ((candidate (directory-words 5)))
    (g:copia-candidato-get context candidate)
    (is (= csn (aref candidate 0)))
    (is (= (logior (ash id 32) 64) (aref candidate 1)))
    (is (= 56 (aref candidate 3)))
    (is (= 16 (length (directory-lifetime-fixture-key fixture))))
    (is (= 16 (length (directory-lifetime-fixture-value fixture))))
    candidate))

(defun directory-lifetime-await-reader (gate thread phase)
  "Pre: gate del solo test. Post: rendezvous bounded; un errore anticipato conserva la causa dal join."
  (unless (sb-thread:wait-on-semaphore gate :timeout 5)
    (unless (sb-thread:thread-alive-p thread)
      (directory-join-thread thread 0.05))
    (error 'directory-fixture-timeout :reason phase))
  t)

(defun directory-lifetime-current-read (fixture)
  "Pre: worker uno libero, root ACTIVE pubblicata. Post: fresh CSN2/ACTIVE13 e valore d'input verificati."
  (let* ((series (directory-lifetime-fixture-series fixture))
         (directory (directory-lifetime-fixture-directory fixture))
         (context (directory-series-context series 1)))
    (unwind-protect
         (progn
           (is (eq :candidate
                   (directory-series-begin series (directory-lifetime-fixture-key fixture) 1)))
           (directory-lifetime-candidate fixture context 2 13)
           (is (equal '(:segment :disabled :not-attempted nil nil)
                      (multiple-value-list
                       (d:leggi-record-serie-get context (directory-series-fixture-controller series)))))
           (directory-series-copy-and-finish series (directory-lifetime-fixture-value fixture) 1)
           ;; Checkpoint del prodotto precedente a questo cleanup di sicurezza.
           (is (directory-check-clean directory 1)))
      (g:abbandona-get context))))

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-CMP-007 REQ-CON-004
(deftest test-REQ-CMP-007-series-get-old-candidate-new-active-superset-native-v1-v2
  (dolist (version '(1 2))
    (let* ((fixture (make-directory-lifetime-fixture version))
           (series (directory-lifetime-fixture-series fixture))
           (directory (directory-lifetime-fixture-directory fixture))
           (controller (directory-series-fixture-controller series))
           (context (directory-series-context series))
           (initial (directory-series-fixture-root series)))
      (unwind-protect
           (progn
             (is (zerop (directory-fixture-generation directory)))
             (is (= 0 (nth-value 0 (m:leggi-registro-snapshot (directory-fixture-snapshots directory)))))
             (is (eq :candidate
                     (directory-series-begin series (directory-lifetime-fixture-key fixture))))
             (let ((candidate (directory-lifetime-candidate fixture context 1 #xffffffff)))
               (is (e:epoca-attiva-p (e:contesto-epoca (directory-fixture-epochs directory) 0)))
               ;; Pubblicazione reale di PUT fresco con CSN2: la nuova root conserva CLOSED.
               (let* ((commit (directory-lifetime-publish-superset fixture))
                      (published (arcdocdb.series:leggi-radice-serie controller)))
                 (is (not (eq initial published)))
                 (is (eq published (directory-series-commit-root commit)))
                 (is (= 2 (directory-series-commit-csn commit)))
                 (is (= 1 (d:conta-segmenti-directory-get
                           (d::fonti-get-serie-directory (r:contenuto-radice-get-attiva published)))))
                 (is (zerop (r::radice-get-attiva-count initial))))
               ;; Il resolver acquisisce ora la nuova root, ma il candidato copiato resta CSN1/CLOSED.
               (multiple-value-bind (segment end flags proof)
                   (d:risolvi-candidato-serie-get context controller)
                 (is (eq (directory-lifetime-fixture-file fixture) (g::segmento-get-file segment)))
                 (is (= #xffffffff (g::segmento-get-low segment)))
                 (is (= 120 end)) (is (zerop flags)) (is (null proof)))
               (is (equalp candidate (directory-lifetime-candidate fixture context 1 #xffffffff)))
               (is (null (directory-read-events directory)))
               (is (equal '(:segment :disabled :not-attempted nil nil)
                          (multiple-value-list (d:leggi-record-serie-get context controller))))
               (directory-series-copy-and-finish series (directory-lifetime-fixture-value fixture))
               (is (equal '((4294967295 64 56)) (directory-read-events directory)))
               (is (directory-check-clean directory))
               (is (eq :open (io:stato-file (directory-lifetime-fixture-file fixture))))
               (is (null (directory-close-events directory)))
               (directory-lifetime-current-read fixture)))
        (g:abbandona-get context)
        (close-directory-series-fixture series)))))


(defstruct (directory-lifetime-rendezvous
             (:constructor make-directory-lifetime-rendezvous (fixture mode)))
  "Pre: controller prepara tutte le gate prima dello spawn. Post: fase e handoff del solo test."
  (fixture nil :type directory-lifetime-fixture :read-only t)
  (mode :success :type (member :success :condition :escape) :read-only t)
  (entered (sb-thread:make-semaphore) :type sb-thread:semaphore :read-only t)
  (continue (sb-thread:make-semaphore) :type sb-thread:semaphore :read-only t)
  (verified (sb-thread:make-semaphore) :type sb-thread:semaphore :read-only t)
  (finish (sb-thread:make-semaphore) :type sb-thread:semaphore :read-only t)
  (escape (gensym "DIRECTORY-LIFETIME-ESCAPE") :type symbol :read-only t)
  (escaped-value (list :escaped) :type list :read-only t)
  (injected (make-condition 'arcdocdb.conditions:io-fault
                            :reason :directory-lifetime-native-hook :operation :read)
            :type arcdocdb.conditions:io-fault :read-only t)
  (thread nil :type (or null sb-thread:thread)))

(defun directory-lifetime-install-hook (rendezvous)
  "Pre: prima dello spawn. Post: hook invariato fino al join, limitato al CLOSED del worker zero."
  (let* ((fixture (directory-lifetime-rendezvous-fixture rendezvous))
         (directory (directory-lifetime-fixture-directory fixture))
         (context (directory-series-context (directory-lifetime-fixture-series fixture))))
    (setf (directory-observer-hook (directory-fixture-observer directory))
          (lambda (id offset count)
            (when (= id #xffffffff)
              ;; Questi sono checkpoint del worker proprietario, precedenti al rendezvous.
              (is (= 64 offset)) (is (= 56 count))
              (is (eq :loading (g:stato-contesto-get context)))
              (is (e:epoca-attiva-p (e:contesto-epoca (directory-fixture-epochs directory) 0)))
              (is (directory-output-untouched-p directory))
              (sb-thread:signal-semaphore (directory-lifetime-rendezvous-entered rendezvous))
              (directory-wait-gate (directory-lifetime-rendezvous-continue rendezvous)
                                   :lifetime-native-read)
              (ecase (directory-lifetime-rendezvous-mode rendezvous)
                (:success nil)
                (:condition (error (directory-lifetime-rendezvous-injected rendezvous)))
                (:escape (throw (directory-lifetime-rendezvous-escape rendezvous)
                                (directory-lifetime-rendezvous-escaped-value rendezvous)))))))))

(defun directory-lifetime-worker-success (rendezvous)
  "Pre: worker zero, pread ammessa. Post: copy/conclusione verificati prima del cleanup esterno."
  (let* ((fixture (directory-lifetime-rendezvous-fixture rendezvous))
         (series (directory-lifetime-fixture-series fixture))
         (directory (directory-lifetime-fixture-directory fixture))
         (context (directory-series-context series)))
    (is (equal '(:segment :disabled :not-attempted nil nil)
               (multiple-value-list
                (d:leggi-record-serie-get context (directory-series-fixture-controller series)))))
    (is (eq :verified (g:stato-contesto-get context)))
    (is (e:epoca-attiva-p (e:contesto-epoca (directory-fixture-epochs directory) 0)))
    (is (directory-output-untouched-p directory))
    (sb-thread:signal-semaphore (directory-lifetime-rendezvous-verified rendezvous))
    (directory-wait-gate (directory-lifetime-rendezvous-finish rendezvous) :lifetime-copy)
    (directory-series-copy-and-finish series (directory-lifetime-fixture-value fixture))
    (is (directory-check-clean directory))
    :copied-and-finished))

(defun directory-lifetime-worker-failure (rendezvous)
  "Pre: worker zero. Post: causa o valore THROW originali, pin zero PRIMA di ogni cleanup esterno."
  (let* ((fixture (directory-lifetime-rendezvous-fixture rendezvous))
         (series (directory-lifetime-fixture-series fixture))
         (directory (directory-lifetime-fixture-directory fixture))
         (context (directory-series-context series))
         (controller (directory-series-fixture-controller series))
         (observed
           (ecase (directory-lifetime-rendezvous-mode rendezvous)
             (:condition
              (handler-case
                  (progn (d:leggi-record-serie-get context controller)
                         (error 'directory-fixture-error :reason :condition-not-raised))
                (arcdocdb.conditions:io-fault (condition) condition)))
             (:escape
              (catch (directory-lifetime-rendezvous-escape rendezvous)
                (d:leggi-record-serie-get context controller)
                :unexpected-return)))))
    (is (eq observed
            (ecase (directory-lifetime-rendezvous-mode rendezvous)
              (:condition (directory-lifetime-rendezvous-injected rendezvous))
              (:escape (directory-lifetime-rendezvous-escaped-value rendezvous)))))
    (is (directory-check-clean directory))
    (is (directory-output-untouched-p directory))
    observed))

(defun directory-lifetime-worker (rendezvous)
  "Pre: thread proprietario del contesto zero. Post: checkpoint prodotto prima di ABBANDONA esterno."
  (let* ((fixture (directory-lifetime-rendezvous-fixture rendezvous))
         (series (directory-lifetime-fixture-series fixture))
         (context (directory-series-context series)))
    (unwind-protect
         (progn
           (is (eq :candidate
                   (directory-series-begin series (directory-lifetime-fixture-key fixture))))
           (directory-lifetime-candidate fixture context 1 #xffffffff)
           (if (eq :success (directory-lifetime-rendezvous-mode rendezvous))
               (directory-lifetime-worker-success rendezvous)
               (directory-lifetime-worker-failure rendezvous)))
      (g:abbandona-get context))))

(defun directory-lifetime-check-waiting (fixture)
  "Pre: worker zero in un rendezvous attestato da lui. Post: claim NIL e nessuna chiusura."
  ;; Il controller non legge contesto, scratch o pin privati del worker vivo.
  (is (null (directory-lifetime-claim fixture)))
  (is (eq :open (io:stato-file (directory-lifetime-fixture-file fixture))))
  (is (null (directory-close-events (directory-lifetime-fixture-directory fixture))))
  t)

(defun directory-lifetime-publish-retirement (fixture)
  "Pre: vecchio reader gia' nel native-read. Post: due CAS ordinari, primary ACTIVE, ritiro pubblicato."
  (let* ((series (directory-lifetime-fixture-series fixture))
         (file (directory-lifetime-fixture-file fixture)))
    (directory-lifetime-reserve fixture)
    (let ((ticket (directory-lifetime-fixture-ticket fixture))
          (generation (directory-lifetime-fixture-generation fixture)))
      (is (eq file (e:leggi-risorsa-ritiro ticket generation)))
      (is (eq :reserved (nth-value 0 (e:leggi-ritiro ticket generation)))))
    (directory-lifetime-publish-superset fixture)
    (directory-lifetime-drop-source fixture)
    (let* ((root (arcdocdb.series:leggi-radice-serie (directory-series-fixture-controller series)))
           (sources (r:contenuto-radice-get-attiva root)))
      (is (zerop (d:conta-segmenti-directory-get (d::fonti-get-serie-directory sources))))
      (is (= 2 (r::radice-get-attiva-count root))))
    (is (eq :retired
            (nth-value 0 (e:leggi-ritiro (directory-lifetime-fixture-ticket fixture)
                                       (directory-lifetime-fixture-generation fixture)))))
    (directory-lifetime-check-waiting fixture)
    ;; Un nuovo GET usa ACTIVE mentre il vecchio reader conserva l'autorita' del suo CLOSED.
    (directory-lifetime-current-read fixture)
    (directory-lifetime-check-waiting fixture)))

(defun directory-lifetime-finish-reader (rendezvous)
  "Pre: ritiro pubblicato, vecchio reader fermo nel hook. Post: join e risultato/cause originali."
  (let* ((fixture (directory-lifetime-rendezvous-fixture rendezvous))
         (directory (directory-lifetime-fixture-directory fixture))
         (thread (directory-lifetime-rendezvous-thread rendezvous))
         (mode (directory-lifetime-rendezvous-mode rendezvous)))
    (sb-thread:signal-semaphore (directory-lifetime-rendezvous-continue rendezvous))
    (when (eq mode :success)
      (directory-lifetime-await-reader (directory-lifetime-rendezvous-verified rendezvous)
                                       thread :lifetime-verified)
      ;; Anche dopo pread il pin e' necessario fino a copia e conclusione.
      (directory-lifetime-check-waiting fixture)
      (sb-thread:signal-semaphore (directory-lifetime-rendezvous-finish rendezvous)))
    (let ((result (directory-join-thread thread)))
      (is (eq result
              (ecase mode
                (:success :copied-and-finished)
                (:condition (directory-lifetime-rendezvous-injected rendezvous))
                (:escape (directory-lifetime-rendezvous-escaped-value rendezvous))))))
    (is (directory-check-clean directory))
    (unless (eq mode :success) (is (directory-output-untouched-p directory)))
    (is (eq :open (io:stato-file (directory-lifetime-fixture-file fixture))))
    (is (null (directory-close-events directory)))
    t))

(defun directory-lifetime-check-reclaim (fixture native-fd)
  "Pre: vecchio worker joined e pin zero. Post: claim esclusivo, una close nativa, ticket completo."
  (let* ((directory (directory-lifetime-fixture-directory fixture))
         (file (directory-lifetime-fixture-file fixture))
         (ticket (directory-lifetime-fixture-ticket fixture))
         (generation (directory-lifetime-fixture-generation fixture)))
    (is (directory-lifetime-claim fixture))
    (is (eq :claimed (nth-value 0 (e:leggi-ritiro ticket generation))))
    (is (eq file (e:leggi-risorsa-ritiro ticket generation)))
    (directory-lifetime-reclaim fixture)
    (is (eq :closed (io:stato-file file)))
    (is (equal (list (list #xffffffff native-fd :closed)) (directory-close-events directory)))
    (is (eq :completed (nth-value 0 (e:leggi-ritiro ticket generation))))
    (is (zerop (nth-value 2 (e:leggi-registro-epoche (directory-fixture-epochs directory)))))
    (is (zerop (nth-value 3 (e:leggi-registro-epoche (directory-fixture-epochs directory)))))
    ;; Dopo la chiusura del CLOSED il nuovo GET continua a usare soltanto ACTIVE.
    (directory-lifetime-current-read fixture)
    (is (equal '((4294967295 64 56) (13 64 56) (13 64 56)) (directory-read-events directory)))
    (is (equal (list (list #xffffffff native-fd :closed)) (directory-close-events directory)))
    t))

(defun directory-lifetime-retirement-case (version mode)
  "Due PUT freschi/CAS reali e unlink volatile controllato; non qualifica rotazione o compaction."
  (let* ((fixture (make-directory-lifetime-fixture version))
         (rendezvous (make-directory-lifetime-rendezvous fixture mode))
         (native-fd (io::file-fd (directory-lifetime-fixture-file fixture))))
    (unwind-protect
         (progn
           (is (zerop (directory-fixture-generation (directory-lifetime-fixture-directory fixture))))
           (is (= 0 (nth-value 0
                               (m:leggi-registro-snapshot
                                (directory-fixture-snapshots (directory-lifetime-fixture-directory fixture))))))
           (directory-lifetime-install-hook rendezvous)
           (setf (directory-lifetime-rendezvous-thread rendezvous)
                 (directory-worker-thread 0 (lambda () (directory-lifetime-worker rendezvous))))
           (directory-lifetime-await-reader (directory-lifetime-rendezvous-entered rendezvous)
                                            (directory-lifetime-rendezvous-thread rendezvous)
                                            :lifetime-source-captured)
           (directory-lifetime-publish-retirement fixture)
           (directory-lifetime-finish-reader rendezvous)
           (directory-lifetime-check-reclaim fixture native-fd))
      (sb-thread:signal-semaphore (directory-lifetime-rendezvous-continue rendezvous))
      (sb-thread:signal-semaphore (directory-lifetime-rendezvous-finish rendezvous))
      ;; Un fallimento dello stop/join impedisce la chiusura di risorse ancora usate dal thread.
      (directory-stop-threads (when (directory-lifetime-rendezvous-thread rendezvous)
                                (list (directory-lifetime-rendezvous-thread rendezvous))))
      (close-directory-lifetime-fixture fixture))))

;;; REQ: REQ-CMP-007 REQ-CMP-005 REQ-IDX-001 REQ-WAL-006 REQ-CON-004
(deftest test-REQ-CMP-007-series-get-native-source-pinned-through-copy-and-reclaim
  (dolist (version '(1 2)) (directory-lifetime-retirement-case version :success)))

;;; REQ: REQ-CMP-007 REQ-CON-004 REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-CMP-007-series-get-native-hook-condition-releases-pin-before-reclaim
  (dolist (version '(1 2)) (directory-lifetime-retirement-case version :condition)))

;;; REQ: REQ-CMP-007 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-CMP-007-series-get-native-hook-nonlocal-exit-releases-pin-before-reclaim
  (dolist (version '(1 2)) (directory-lifetime-retirement-case version :escape)))
