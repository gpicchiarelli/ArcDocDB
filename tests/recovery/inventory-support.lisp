;;;; Inventario: fixture EDIT bytewise e oracolo dichiarativo a liste.
;;; OWNER: ogni fixture e piano privato appartiene alla singola prova.
;;; SHARED: modelli e piano comune dei worker sono letti soltanto.
(in-package #:arcdocdb.recovery.tests)

(defun inventory-fixture-manifest (specs &key (version 2))
  "Ricostruisce fatti dichiarati da EDIT/SEAL indipendenti; restituisce anche i byte posseduti."
  (multiple-value-bind (buffer start end)
      (manifest-log-fixture (list specs) :version version)
    (let ((before (copy-seq buffer)))
      (multiple-value-bind (manifest prefix status)
          (manifest-fixture-read buffer start end :version version)
        (is (= prefix end)) (is (eq status :complete))
        (is (equalp before buffer))
        (values manifest buffer)))))

(defun inventory-snapshot (active closed removed)
  "Snapshot logico indipendente: CLOSED hanno valid-bytes 64, nessun esito."
  (manifest-spec :completo t :open active
                 :next-id (1+ (reduce #'max (append (list active) closed removed)))
                 :chiusi (mapcar (lambda (id) (list id 64 nil)) closed) :rimossi removed))

(defun inventory-manifest (active closed removed &key (version 2))
  "Fixture semplice; le storie che nominano massimo u64 usano un delta esplicito."
  (inventory-fixture-manifest (list (inventory-snapshot active closed removed))
                              :version version))

(defun inventory-files (specs)
  "Nomi logici (id forma), convertiti soltanto attraverso il costruttore pubblico."
  (map 'simple-vector (lambda (spec)
                        (arcdocdb.recovery.manifest:file-segmento (first spec) (second spec)))
       specs))

(defun inventory-logical-forms (id files)
  "Presenza dichiarata del modello; nessun descrittore o contenitore del prodotto."
  (mapcar #'second (remove-if-not (lambda (file) (= id (first file))) files)))

(defun inventory-oracle-form (id files)
  "Classifica i nomi del modello, che non contiene duplicati esatti."
  (let ((forms (inventory-logical-forms id files)))
    (cond ((null forms) :absent) ((= (length forms) 2) :both) (t (first forms)))))

(defun inventory-oracle-action (state form)
  "Tabella ADR0040§3 dichiarata; non chiama helper o query del planner."
  (cdr (assoc form
              (cdr (assoc state
                          '((:active (:absent . :missing) (:temporary . :rename)
                                     (:final . :use) (:both . :conflict))
                            (:closed (:absent . :missing) (:temporary . :rename)
                                     (:final . :use) (:both . :conflict))
                            (:removed (:temporary . :delete) (:final . :delete)
                                      (:both . :conflict))
                            (:unknown (:temporary . :delete) (:final . :anomaly)
                                      (:both . :conflict))))))))

(defun inventory-oracle (active closed removed files)
  "Union a liste e disponibilità delle sole referenze vive; ordinamento unsigned naturale."
  (let* ((ids (sort (remove-duplicates
                     (append (list active) (copy-list closed) (mapcar #'first files))) #'<))
         (health (cond ((/= 1 (length (inventory-logical-forms active files))) :faulted)
                       ((some (lambda (id) (/= 1 (length (inventory-logical-forms id files))))
                              closed) :degraded)
                       (t :ready))))
    (list :health health :rows
          (mapcar (lambda (id)
                    (let ((state (cond ((= id active) :active) ((member id closed) :closed)
                                       ((member id removed) :removed) (t :unknown)))
                          (form (inventory-oracle-form id files)))
                      (list id form (inventory-oracle-action state form) state))) ids))))

(defun inventory-plan-rows (plan)
  "Solo query pubbliche scalari; confronta anche il numero esatto di valori restituiti."
  (loop for position below (arcdocdb.recovery.manifest:numero-azioni-riconciliazione plan)
        collect (let ((row (multiple-value-list
                            (arcdocdb.recovery.manifest:azione-riconciliazione plan position))))
                  (is (= 4 (length row))) row)))

(defun inventory-assert-plan (plan expected)
  "Confronta disponibilità e tutte le entry canoniche all'oracolo indipendente."
  (is (equal (list (getf expected :health))
             (multiple-value-list (arcdocdb.recovery.manifest:stato-riconciliazione plan))))
  (is (equal (list (length (getf expected :rows)))
             (multiple-value-list (arcdocdb.recovery.manifest:numero-azioni-riconciliazione plan))))
  (is (equal (getf expected :rows) (inventory-plan-rows plan)))
  t)

(defun inventory-check (manifest active closed removed specs &rest options)
  "Prepara nomi privati e verifica nessuna modifica; restituisce piano e vettore riutilizzabile."
  (let* ((files (inventory-files specs)) (before (copy-seq files))
         (plan (apply #'arcdocdb.recovery.manifest:pianifica-riconciliazione
                      manifest files options)))
    (is (every #'eq before files))
    (inventory-assert-plan plan (inventory-oracle active closed removed specs))
    (values plan files)))

(defun inventory-small-files (number)
  "Cinque ID, quattro presenze ciascuno: 4^5 inventari senza duplicati."
  (let ((files nil))
    (dotimes (id 5 (nreverse files))
      (let ((presence (ldb (byte 2 (* 2 id)) number)))
        (when (member presence '(1 3)) (push (list id :temporary) files))
        (when (member presence '(2 3)) (push (list id :final) files))))))

(defun inventory-input-orders (files)
  "Tre ordini riproducibili, anche per inventari vuoti o con un solo nome."
  (list files (reverse files) (if (rest files) (append (rest files) (list (first files))) files)))

(defun inventory-permutations (files)
  "Permutazioni complete di al più sei nomi; ricorsione con profondità massima sei."
  (is (<= (length files) 6))
  (if (null files) (list nil)
      (loop for file in files append
        (mapcar (lambda (suffix) (cons file suffix))
                (inventory-permutations (remove file files :test #'eq :count 1))))))

(defun inventory-indirect-call (function &rest arguments)
  "Invocazione dinamica per provare FTYPE invalidi senza avvisi del compilatore dei test."
  (apply (symbol-function function) arguments))

(defun inventory-parallel-facts (serie)
  "Ogni Serie ha nomi e stati propri; CLOSED zero è riservato alla Serie zero."
  (let ((base (* serie 32)))
    (values (+ base 7) (list base (1+ base)) (list (+ base 2))
            (list (list (+ base 7) :temporary) (list base :final)
                  (list (1+ base) :temporary) (list (+ base 2) :final)
                  (list (+ base 9) :temporary) (list (+ base 10) :final)))))

(defun inventory-parallel-worker (serie gate common common-model)
  "Otto piani privati e letture dello stesso piano comune; ogni attesa è limitata."
  (is (sb-thread:wait-on-semaphore gate :timeout 10))
  (inventory-assert-plan common common-model)
  (multiple-value-bind (active closed removed specs) (inventory-parallel-facts serie)
    (let ((model (inventory-oracle active closed removed specs)))
      (loop for repeat below 8 for version = (if (evenp repeat) 1 2) do
        (multiple-value-bind (manifest buffer)
            (inventory-manifest active closed removed :version version)
          (multiple-value-bind (plan files)
              (inventory-check manifest active closed removed specs)
            (fill files nil) (fill buffer #xff)
            (loop repeat 3 do (inventory-assert-plan plan model)
                              (inventory-assert-plan common common-model)))))))
  t)

(defun inventory-stop-workers (threads)
  "Cleanup delle sole risorse della prova; nessun worker sopravvive al join fallito."
  (dolist (thread threads)
    (when (sb-thread:thread-alive-p thread)
      (sb-thread:terminate-thread thread)
      (sb-thread:join-thread thread :timeout 1 :default :timeout))
    (is (not (sb-thread:thread-alive-p thread)))))
