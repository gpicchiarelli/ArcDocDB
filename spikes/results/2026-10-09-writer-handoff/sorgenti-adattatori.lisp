(:SCHEMA-VERSION 1 :KIND :VERIFICATION-ADAPTER-SOURCES :SOURCES
 ((:PATH #A((44) BASE-CHAR . "spikes/out/handoff-strict-tools-initial.lisp")
   :GIT-BLOB "553fad8541ac925889ca4010cd456f1212f8f8fd" :TEXT "(require :asdf)
(let ((directory (merge-pathnames \"spikes/out/handoff-strict-fasl/\" (truename \"./\"))))
  (ensure-directories-exist directory)
  (handler-bind ((warning (lambda (condition)
                           (unless (typep condition 'sb-kernel:redefinition-warning)
                             (error \"COD-01: ~A\" condition)))))
    (dolist (source '(\"tools/writer-handoff-mutation.lisp\" \"tools/writer-handoff-bench.lisp\"))
      (let ((uiop:*command-line-arguments* '(\"--self-test\")))
        (multiple-value-bind (fasl warned failed)
            (compile-file source :output-file (merge-pathnames (file-namestring (compile-file-pathname source)) directory))
          (when (or warned failed (null fasl)) (error \"Compilazione strumento fallita: ~A\" source))
          (load fasl)))))
  (format t \"~&Strict compiler e self-test di entrambi gli strumenti: OK.~%\"))
")
  (:PATH
   #A((49) BASE-CHAR . "spikes/out/handoff-strict-tools-args-initial.lisp")
   :GIT-BLOB "a68a9bbd44577ffa03f09c27da0f9f2529d815ac" :TEXT "(require :asdf)
(require :sb-md5)
(require :sb-posix)
(let ((directory (merge-pathnames \"spikes/out/handoff-strict-fasl/\" (truename \"./\"))))
  (ensure-directories-exist directory)
  (handler-bind ((warning (lambda (condition)
                           (unless (typep condition 'sb-kernel:redefinition-warning)
                             (error \"COD-01: ~A\" condition)))))
    (dolist (source '(\"tools/writer-handoff-mutation.lisp\" \"tools/writer-handoff-bench.lisp\"))
      (let ((uiop:*command-line-arguments* '(\"--self-test\")))
        (multiple-value-bind (fasl warned failed)
            (compile-file source :output-file (merge-pathnames (file-namestring (compile-file-pathname source)) directory))
          (when (or warned failed (null fasl)) (error \"Compilazione strumento fallita: ~A\" source))
          (load fasl)))))
  (format t \"~&Strict compiler e self-test di entrambi gli strumenti: OK.~%\"))
")
  (:PATH #A((36) BASE-CHAR . "spikes/out/handoff-strict-tools.lisp") :GIT-BLOB
   "70f182407a18c2cd6f24d042f710d7a927da26d5" :TEXT "(require :asdf)
(require :sb-md5)
(require :sb-posix)
(let ((directory (merge-pathnames \"spikes/out/handoff-strict-fasl/\" (truename \"./\"))))
  (ensure-directories-exist directory)
  (handler-bind ((warning (lambda (condition)
                           (unless (typep condition 'sb-kernel:redefinition-warning)
                             (error \"COD-01: ~A\" condition)))))
    (dolist (source '(\"tools/writer-handoff-mutation.lisp\" \"tools/writer-handoff-bench.lisp\"))
      (let ((uiop:*command-line-arguments* '(\"--self-test\"))
            (sb-ext:*posix-argv* '(\"sbcl\" \"--self-test\")))
        (multiple-value-bind (fasl warned failed)
            (compile-file source :output-file (merge-pathnames (file-namestring (compile-file-pathname source)) directory))
          (when (or warned failed (null fasl)) (error \"Compilazione strumento fallita: ~A\" source))
          (load fasl)))))
  (format t \"~&Strict compiler e self-test di entrambi gli strumenti: OK.~%\"))
")
  (:PATH #A((47) BASE-CHAR . "spikes/out/handoff-export-coverage-initial.lisp")
   :GIT-BLOB "b7cb888455cac3bb16f1a1dc938f1be86e5a0625" :TEXT "(require :asdf)
(defun coverage-counts (record)
  (let ((events (second record)) (bits (cddr record))
        (expressions 0) (covered 0) (branches 0) (covered-branches 0) (missing nil))
    (unless (and (vectorp events) (typep bits 'bit-vector) (= (length events) (length bits)))
      (error \"COD-60: eventi/bit non corrispondono.\"))
    (dotimes (i (length events))
      (let* ((event (aref events i)) (branch (member (first event) '(:then :else))))
        (if branch
            (progn (incf branches) (incf covered-branches (bit bits i)))
            (progn (incf expressions) (incf covered (bit bits i))))
        (when (zerop (bit bits i))
          (push (list :kind (if branch :branch :expression) :path event) missing))))
    (list :expressions covered :expression-total expressions :branches covered-branches
          :branch-total branches :missing (nreverse missing))))
(let ((fixture (list* \"fixture\" #((0) (:then 1) (:else 1) (2)) #*1100)))
  (let ((r (coverage-counts fixture)))
    (unless (and (= 1 (getf r :expressions)) (= 2 (getf r :expression-total))
                 (= 1 (getf r :branches)) (= 2 (getf r :branch-total))
                 (= 2 (length (getf r :missing))))
      (error \"COD-60: self-test del denominatore fallito.\")))
  (unless (handler-case (progn (coverage-counts (list* \"bad\" #((0)) #*00)) nil)
            (error () t))
    (error \"COD-60: forma incoerente non rifiutata.\")))
(let* ((*read-eval* nil)
       (path \"spikes/out/handoff-coverage/coverage-state.lisp\")
       (native (with-open-file (input path) (read input)))
       (records (remove-if-not (lambda (entry) (search \"/src/execution/\" (first entry))) native))
       (counts (mapcar (lambda (entry) (list :file (file-namestring (first entry))
                                            :counts (coverage-counts entry))) records))
       (report (list :schema-version 1 :kind :raw-coverage-export :scope :execution
                     :self-test :passed :source-format :sb-cover-native
                     :native (list :source-path path :git-blob
                                   (string-trim '(#\\Newline #\\Space)
                                                (uiop:run-program (list \"git\" \"hash-object\" \"--\" path) :output :string))
                                   :text (uiop:read-file-string path))
                     :html-index (uiop:read-file-string \"spikes/out/handoff-coverage/index.html\")
                     :counts counts :limits '(:raw-denominator :no-exclusions :not-mcdc))))
  (unless (= 4 (length records)) (error \"COD-60: scope execution incompleto.\"))
  (with-open-file (output \"spikes/out/handoff-coverage-export.lisp\" :direction :output :if-exists :error)
    (let ((*print-readably* t)) (write report :stream output :pretty t) (terpri output)))
  (dolist (entry counts)
    (let ((r (getf entry :counts)))
      (format t \"~A: ~D/~D espressioni, ~D/~D esiti di ramo.~%\"
              (getf entry :file) (getf r :expressions) (getf r :expression-total)
              (getf r :branches) (getf r :branch-total)))))
")
  (:PATH #A((39) BASE-CHAR . "spikes/out/handoff-export-coverage.lisp")
   :GIT-BLOB "aecefb5352fc6bfafbec27f4b58eafa6c211d35c" :TEXT "(require :asdf)
(defun coverage-counts (record)
  (let ((events (second record)) (bits (cddr record))
        (expressions 0) (covered 0) (branches 0) (covered-branches 0) (missing nil))
    (unless (and (vectorp events) (typep bits 'bit-vector) (= (length events) (length bits)))
      (error \"COD-60: eventi/bit non corrispondono.\"))
    (dotimes (i (length events))
      (let* ((event (aref events i)) (branch (member (first event) '(:then :else))))
        (if branch
            (progn (incf branches) (incf covered-branches (bit bits i)))
            (progn (incf expressions) (incf covered (bit bits i))))
        (when (zerop (bit bits i))
          (push (list :kind (if branch :branch :expression) :path event) missing))))
    (list :expressions covered :expression-total expressions :branches covered-branches
          :branch-total branches :missing (nreverse missing))))
(let ((fixture (list* \"fixture\" #((0) (:then 1) (:else 1) (2)) #*1100)))
  (let ((r (coverage-counts fixture)))
    (unless (and (= 1 (getf r :expressions)) (= 2 (getf r :expression-total))
                 (= 1 (getf r :branches)) (= 2 (getf r :branch-total))
                 (= 2 (length (getf r :missing))))
      (error \"COD-60: self-test del denominatore fallito.\")))
  (unless (handler-case (progn (coverage-counts (list* \"bad\" #((0)) #*00)) nil)
            (error () t))
    (error \"COD-60: forma incoerente non rifiutata.\")))
(let* ((*read-eval* nil)
       (path \"spikes/out/handoff-coverage/coverage-state.lisp\")
       (native (with-open-file (input path) (read input)))
       (records (remove-if-not (lambda (entry) (search \"/src/execution/\" (first entry))) native))
       (counts (mapcar (lambda (entry) (list :file (file-namestring (first entry))
                                            :counts (coverage-counts entry))) records))
       (report (list :schema-version 1 :kind :raw-coverage-export :scope :execution
                     :self-test :passed :source-format :sb-cover-native
                     :native (list :source-path path :git-blob
                                   (string-trim '(#\\Newline #\\Space)
                                                (uiop:run-program (list \"git\" \"hash-object\" \"--\" path) :output :string))
                                   :text (uiop:read-file-string path))
                     :html-index (uiop:read-file-string \"spikes/out/handoff-coverage/cover-index.html\")
                     :counts counts :limits '(:raw-denominator :no-exclusions :not-mcdc))))
  (unless (= 4 (length records)) (error \"COD-60: scope execution incompleto.\"))
  (with-open-file (output \"spikes/out/handoff-coverage-export.lisp\" :direction :output :if-exists :error)
    (let ((*print-readably* t)) (write report :stream output :pretty t) (terpri output)))
  (dolist (entry counts)
    (let ((r (getf entry :counts)))
      (format t \"~A: ~D/~D espressioni, ~D/~D esiti di ramo.~%\"
              (getf entry :file) (getf r :expressions) (getf r :expression-total)
              (getf r :branches) (getf r :branch-total)))))
")
  (:PATH #A((45) BASE-CHAR . "docs/implementazione/writer-handoff-metodo.md")
   :GIT-BLOB "f6eb25d050854b65daa7766d203b3e177dbc8f4a" :TEXT
   "# Metodo della consegna locale dei writer

Registrato il 2026-10-09, prima delle prove. Base `85a4e05`. Componente C1:
`src/execution/handoff.lisp` e helper di accettazione estratto da `queue.lisp`.
Contratto da [ADR-0045, punti 6 e 8](../adr/0045-modello-di-esecuzione.md),
REQ-CON-001/002/004/005 e REQ-AFF-008; invarianti INV-P1/P2/P5/P6, INV-A8, INV-V4.

## Meccanismo e ambito

Un wrapper possiede una coda privata e lo stato `idle/ready/running`. Ring e
stato usano la stessa guard locale già presente; ogni acquisizione tenta un
solo CAS. Nessuna nuova guard, stato globale, allocazione per messaggio,
callback, attesa, I/O o thread. La coda interna non viene esposta e non si
mescolano le API basse con quelle del wrapper.

L'accettazione da idle restituisce `:schedule`; ulteriori messaggi restituiscono
`:queued`. L'avvio acquisisce la lease e passa da ready a running. Il termine
osserva count, rilascia la lease e passa a ready se resta lavoro, a idle se
vuoto, mantenendo la guard per l'intera transizione. La quota è cumulativa
per tratto. Il termine può essere anticipato: i messaggi residui richiedono
comunque un prossimo tratto.

`:schedule` trasferisce al chiamante un obbligo da eseguire una sola volta.
Una notifica fallita richiede di conservare e ritentare quell'obbligo; non
si ripete l'accettazione del payload. Busy al termine conserva la lease:
si ritenta solo il termine. Non viene implementata qui la lista pronta,
il risveglio dei worker o la gestione del loro arresto. La proprietà locale
non garantisce progresso se il chiamante abbandona il compito o la lease.

La coordinazione queue/stato di una mailbox è un pattern consolidato
([Akka Mailbox](https://github.com/akka/akka/blob/main/akka-actor/src/main/scala/akka/dispatch/Mailbox.scala));
questo protocollo è una realizzazione distinta, sotto guard, e richiede prove
proprie. I CAS e il loro ordinamento sono quelli di
[SBCL](https://www.sbcl.org/manual/#Atomic-Operations) e delle
[barriere](https://www.sbcl.org/manual/#Barriers).

## Prove di correttezza

- Compilazione forzata senza warning/style-warning e suite execution precedente.
- Oracolo indipendente con liste FIFO, numero di notifiche e stati logici;
  sequenze finite su capacità/quantum diversi, wrap, NIL, quota cumulativa,
  conclusione anticipata, nuova ondata dopo idle e target intatto fuori span.
- Due ordini della race dopo l'ultimo prelievo: accettazione prima del termine
  produce `:queued` seguito da `:schedule`; termine prima dell'accettazione
  produce `:idle` seguito da `:schedule`. Nessun payload duplicato o perso.
- Full/busy senza mutazione o accettazione; busy al termine conserva lease,
  quota e lavoro. Avvio duplicato, lease vecchia/altro thread, generazione
  esaurita senza wrap e ready conservato. Guardie interne provate con FI privata.
- Thread reali riusati su più ondate; producer aperti durante il consumo,
  passaggio del writer a thread diversi e una Serie che avanza mentre un'altra
  conserva la guard. Semafori e join hanno timeout; errori dei worker rilanciati.
  Questo harness non è il pool adattivo del prodotto né una misura di scalabilità.

## Verifica C1 e strumenti

Due letture, autore e revisore distinto, con i dodici punti dello standard.
Inventario delle decisioni e rami difensivi; raw `sb-cover` di tutti i quattro
file execution, senza sottrarre dichiarazioni o rami non marcati. Si conservano
raw, conteggi, denominatori e limiti; nessuna deroga o MC/DC completa implicita.

Mutation testing su copie isolate, baseline compilata e riuscita; mutanti
semantici relativi a notifica, passaggio di stato, quota e conteggio. Ogni
mutante deve compilare prima di essere rilevato dai test. Compilation failure,
prima-dei-test, sopravvivenza e rilevamento restano esiti distinti. Il set viene
fissato prima dell'esecuzione nel sorgente dello strumento. Self-test del runner
su bersagli mancanti/ambigui e marcatori di risultato.

Allocazioni seriali: input, wrapper e target preallocati, warmup esterno al
contatore, cinque campioni di 4096 cicli per percorso (idle→ready→running→idle,
backlog/quantum/riaccodamento). Sink e notifiche confrontati con l'oracolo.
Contatore con controllo positivo di allocazione; campione zero non è una prova
universale. Nessuna misura throughput/P99 o selezione di algoritmi da questa
campagna. Carico esterno non controllato, piattaforma locale macOS ARM64/SBCL.

Tutte le prove passano tramite il registro strutturato, con sorgenti stabili,
argv/ambiente, stdout/stderr integrali e fallimenti. Evidenze pubblicate in
`spikes/results/2026-10-09-writer-handoff/`; verifica finale `make check`.
I gate del motore e i target integrati restano aperti.
")))
