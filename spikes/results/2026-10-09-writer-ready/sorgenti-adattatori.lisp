(:SCHEMA-VERSION 1 :KIND :VERIFICATION-ADAPTER-SOURCES :SOURCES
 ((:PATH "spikes/out/ready-strict-product.lisp" :GIT-BLOB
   "64e53ca5cf2ffef5e60dc5fb0c47f3274dfe9467" :TEXT "(require :asdf)
(push (truename \"./\") asdf:*central-registry*)
(handler-bind ((warning (lambda (condition) (error condition))))
  (asdf:load-system \"arcdocdb\" :force t))
(format t \"STRICT PRODUCT OK~%\")
")
  (:PATH "spikes/out/ready-build-test.lisp" :GIT-BLOB
   "43e16876f064ea85c846eccfe3ff793f48ef2ed7" :TEXT "(require :asdf)
(asdf:initialize-output-translations
 `(:output-translations (,(truename \"./\") ,(merge-pathnames \"spikes/out/ready-build-fasl/\" (truename \"./\")))
                        :ignore-inherited-configuration))
(load \"tools/build.lisp\")
")
  (:PATH "spikes/out/ready-export-coverage.lisp" :GIT-BLOB
   "46c4e6ef60aa87f77d152d1e4b2fd269bf1f43f7" :TEXT "(require :asdf)
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
       (path \"spikes/out/ready-coverage/coverage-state.lisp\")
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
                     :html-index (uiop:read-file-string \"spikes/out/ready-coverage/cover-index.html\")
                     :counts counts :limits '(:raw-denominator :no-exclusions :not-mcdc))))
  (unless (= 6 (length records)) (error \"COD-60: scope execution incompleto.\"))
  (with-open-file (output \"spikes/out/ready-coverage-export.lisp\" :direction :output :if-exists :error)
    (let ((*print-readably* t)) (write report :stream output :pretty t) (terpri output)))
  (dolist (entry counts)
    (let ((r (getf entry :counts)))
      (format t \"~A: ~D/~D espressioni, ~D/~D esiti di ramo.~%\"
              (getf entry :file) (getf r :expressions) (getf r :expression-total)
              (getf r :branches) (getf r :branch-total)))))
")
  (:PATH "spikes/out/writer-ready-tool-self-test.lisp" :GIT-BLOB
   "497b1421554380b6b88d73ab3c8f5cec4a79e0d1" :TEXT
   ";;;; Adapter C4: compila interamente un tool e carica il FASL con --self-test.
;;;; Contrib pre-caricati prima della compilazione rigorosa; argv espliciti per MAIN.
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(let* ((arguments (uiop:command-line-arguments))
       (tool (first arguments))
       (fasl (and tool (merge-pathnames (concatenate 'string (pathname-name tool) \".fasl\")
                                        \"spikes/out/ready-tool-fasl/\"))))
  (unless (and (= 1 (length arguments))
               (member tool '(\"tools/writer-ready-bench.lisp\" \"tools/writer-ready-mutation.lisp\")
                       :test #'string=))
    (error \"COD-61: adapter richiede il path di uno dei due nuovi tool ready.\"))
  (ensure-directories-exist fasl)
  (setf asdf:*compile-file-failure-behaviour* :error
        asdf:*compile-file-warnings-behaviour* :error
        asdf:*user-cache* (merge-pathnames \"spikes/out/ready-tool-product-fasl/\" (truename \"./\")))
  (asdf:initialize-output-translations
   `(:output-translations
     (,(namestring (truename \"./\"))
      ,(namestring (merge-pathnames
                    (concatenate 'string \"spikes/out/ready-tool-product-fasl/\" (pathname-name tool) \"/\")
                    (truename \"./\"))))
     :ignore-inherited-configuration))
  (handler-bind
      ((warning (lambda (condition)
                  (unless (typep condition 'sb-kernel:redefinition-warning)
                    (error \"~A non ammesso (COD-01): ~A\" (type-of condition) condition)))))
    (multiple-value-bind (output warnings failure) (compile-file tool :output-file fasl)
      (unless (and output (not warnings) (not failure))
        (error \"COD-01: compile-file completo non riuscito per ~A.\" tool))
      (setf uiop/image:*command-line-arguments* '(\"--self-test\")
            sb-ext:*posix-argv* '(\"sbcl\" \"--self-test\"))
      (load output)))
  (format t \"~&Tool ready ~A: COMPILE-FILE completo e --self-test FASL superati.~%\" tool))
")
  (:PATH "spikes/out/ready-publish.lisp" :GIT-BLOB
   "73468da7297481e793d9e11abf502562733b06d6" :TEXT "(require :asdf)
(load \"tools/evidence-storage.lisp\")
(defun save-data (data path)
  (with-open-file (stream path :direction :output :if-exists :error :external-format :utf-8)
    (let ((*print-readably* t)) (write data :stream stream :pretty t) (terpri stream))))
(defun source-record (path)
  (list :path path :git-blob
        (string-trim '(#\\Newline #\\Space) (uiop:run-program (list \"git\" \"hash-object\" \"--\" (namestring path)) :output :string))
        :text (uiop:read-file-string path :external-format :utf-8)))
(defun copy-evidence (source target)
  (arcdocdb.evidence:read-evidence source)
  (when (probe-file target) (error \"Destinazione esistente: ~A\" target))
  (uiop:copy-file source target)
  (let* ((*read-eval* nil) (data (with-open-file (stream source) (read stream))))
    (when (eq :compressed-evidence (getf data :kind))
      (uiop:copy-file (merge-pathnames (getf data :payload) (uiop:pathname-directory-pathname source))
                      (merge-pathnames (getf data :payload) (uiop:pathname-directory-pathname target))))))
(let ((out #p\"spikes/results/2026-10-09-writer-ready/\"))
  (ensure-directories-exist out)
  (dolist (entry '((\"4000519941-command-73541-0\" \"prodotto-iniziale\")
                   (\"4000520747-command-93257-0\" \"build-test\")
                   (\"4000520791-command-94821-0\" \"bench-self-test\")
                   (\"4000520791-command-94820-0\" \"mutazioni-self-test\")
                   (\"4000520828-command-97914-0\" \"copertura-processo\")
                   (\"4000520903-command-1709-0\" \"copertura-export-processo\")
                   (\"4000520822-command-96904-0\" \"mutazioni-processo\")
                   (\"4000520933-command-3549-0\" \"allocazioni-processo\")))
    (copy-evidence (format nil \"spikes/out/~A/report.lisp\" (first entry))
                   (merge-pathnames (format nil \"~A.lisp\" (second entry)) out))
    (copy-evidence (format nil \"spikes/out/~A/conservazione.lisp\" (first entry))
                   (merge-pathnames (format nil \"~A-conservazione.lisp\" (second entry)) out)))
  (dolist (entry '((\"spikes/out/ready-coverage-export.lisp\" \"copertura-grezza.lisp\")
                   (\"spikes/out/ready-mutations/report.lisp\" \"mutazioni-dati.lisp\")
                   (\"spikes/out/ready-allocations/report.lisp\" \"allocazioni-dati.lisp\")
                   (\"spikes/out/ready-agent-copy-probes.lisp\" \"probe-copia-agente.lisp\")))
    (copy-evidence (first entry) (merge-pathnames (second entry) out)))
  (let ((report (arcdocdb.evidence:read-evidence \"spikes/out/ready-mutations/report.lisp\")))
    (save-data (list :schema-version 1 :kind :raw-mutation-logs
                     :logs (mapcar #'source-record
                         (cons (getf report :baseline-log)
                               (mapcar (lambda (entry) (getf entry :log)) (getf report :mutants)))))
                (merge-pathnames \"mutazioni-log.lisp\" out)))
  (save-data (list :schema-version 1 :kind :verification-adapter-sources
                  :sources (mapcar #'source-record
                      '(\"spikes/out/ready-strict-product.lisp\" \"spikes/out/ready-build-test.lisp\"
                        \"spikes/out/ready-export-coverage.lisp\" \"spikes/out/writer-ready-tool-self-test.lisp\"
                        \"spikes/out/ready-publish.lisp\" \"docs/implementazione/writer-ready-metodo.md\")))
             (merge-pathnames \"sorgenti-adattatori.lisp\" out)))
(format t \"Evidenze mirate preservate.~%\")
")
  (:PATH "docs/implementazione/writer-ready-metodo.md" :GIT-BLOB
   "9ba796d2196e0f9c43754544b1aad9f25658247f" :TEXT
   "# Metodo della lista dei writer pronti

Registrato il 2026-10-09 prima delle campagne, base `92d8b0e`.
Componente C1: lista pronta preallocata a partizioni indipendenti, da
[ADR-0045 §§6/8](../adr/0045-modello-di-esecuzione.md), REQ-CON-001/002/004/005
e REQ-AFF-008; INV-P1/P2/P5/P6, INV-A8 e INV-V4.

## Contratto preregistrato

Ogni partizione è un ring FIFO con una guard locale acquisita con un solo
CAS. Nessuno spin, callback, I/O, contatore globale o allocazione per compito.
Il ring trasporta riferimenti ai writer, senza membership, generazioni o
cleanup dello stato del writer. Il protocollo di
[handoff](writer-handoff.md) resta invariato. La lista comune è toccata solo
per pubblicare o prendere un tratto, non per ciascun messaggio.

La costruzione accetta 1..64 partizioni, default 4, e 1..65536 slot per
partizione, default 1024; massimo 4194304 riferimenti preallocati. La scelta
della partizione di una Serie è un dato del chiamante, fissato prima del
percorso caldo. Non viene introdotto un algoritmo di hashing del catalogo.

`pubblica-writer-pronto(lista shard writer)` trasferisce un obbligo già
prodotto da `:schedule` e restituisce il count locale. Full/busy rifiutano
prima della mutazione: l'obbligo rimane al chiamante. Il retry riguarda
questa pubblicazione, senza accettare nuovamente il payload nel writer.
Un successo non si ritenta: l'API non deduplica pubblicazioni errate.

`preleva-writer-pronto(lista start)` prova al più K partizioni in ordine
circolare. Una guard contesa non impedisce di provarne un'altra. Restituisce
writer, `:writer` e cursore successivo alla partizione servita; senza successo
restituisce NIL, `:busy` se almeno una guard era contesa, altrimenti `:empty`,
e cursore successivo a start. Empty significa solo che ciascuna osservazione
locale era vuota: un producer concorrente può pubblicare subito dopo; non è
una prova di quiescenza globale né autorizza un parcheggio senza protocollo.
Ogni candidata ha un tentativo CAS di acquisizione; un'acquisizione riuscita
richiede anche il CAS di rilascio. Sono al più K acquisizioni e 2K CAS totali.

Il worker conserva il riferimento preso fino all'avvio riuscito del writer;
busy non lo duplica né lo perde. Non c'è cleanup tardivo di un flag scheduler
dopo `termina-tratto-writer`: una nuova ondata può già essere pubblicata.
Pool, risvegli, shutdown, controller FAULTED e adattività richiedono ancora
integrazione. Non si garantisce progresso se il chiamante abbandona un obbligo.

## Scelta e prove

Il ring con guard a tentativo singolo estende il protocollo già verificato
delle code locali. La partizione riduce il dominio di contesa; la scansione
circolare ha un limite statico e non introduce una ready queue globale per
richiesta. Non è una struttura lock-free e non viene dichiarata la soluzione
universalmente più veloce. I CAS seguono il
[contratto SBCL](https://www.sbcl.org/manual/#Atomic-Operations) e servono
anche da [barriere di memoria](https://www.sbcl.org/manual/#Barriers).
L'alternativa MPMC con sequenza per slot richiederebbe un nuovo protocollo
di pubblicazione, overflow e riuso; non viene selezionata senza prove proprie.

- Oracolo indipendente con liste FIFO e cursore, sequenze finite con seme,
  capacity 1 e altre cardinalità, wrap, pieno, vuoto e rotazione tra partizioni.
- Limiti/default, input invalidi, rifiuti senza mutazione, cleanup dopo full,
  guard posseduta da altro thread e FI privata sugli invarianti del ring.
- Handoff integrato: obbligo conservato su pubblicazione full/busy e avvio
  busy; entrambi gli ordini enqueue/fine vuota, nuova ondata e riaccodamento.
- Worker reali riusati su ondate con producer vivi e più consumer; una
  partizione occupata mentre l'altra avanza. Retry e join del solo harness
  hanno limiti e gli errori dei worker sono rilanciati.
- Due letture C1, inventario delle decisioni, copertura raw completa di tutti
  i file execution. Nessuna forma sottratta, esclusione approvata o MC/DC
  implicita. Build senza warning/style-warning, lint e `make check`.
- Dodici mutanti semantici preregistrati nel runner prima della campagna:
  ring, proprietà, capienza, scansione, busy, cursore e pubblicazione. Baseline
  riuscita obbligatoria; compilation failure e before-tests non sono rilevamenti.
- Allocazioni: due scenari preallocati con una e quattro partizioni, cinque
  campioni di 4096 cicli ciascuno, warmup 128 e GC fuori dal contatore. Capacità 3 e due writer per partizione forzano wrap; ogni ciclo include
  accettazione del payload preallocato, pubblicazione, prelievo e fine del
  tratto. Si misura la composizione handoff/lista pronta. Identità,
  count, status e cursore contribuiscono a un sink esatto; controllo positivo
  heap, sink errato rifiutato e clock nullo distinto. Percorsi d'errore esclusi;
  zero osservato non è una garanzia universale, né throughput o P99.

Tutti i tentativi sono registrati con `tools/record-command.lisp`, argv,
ambiente, sorgenti stabili e output integrali. I C4 hanno self-test e rapporti
parziali; le prove congelate vivono in una clone separata. Dati grandi vengono
compressi senza perdita e verificati dal lettore delle evidenze. I gate del
motore e i target integrati restano aperti.
")))
