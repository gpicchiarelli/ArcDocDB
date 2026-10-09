(:SCHEMA-VERSION 1 :KIND :MUTATION-OUTPUT :SCOPE :INVENTORY
 :ORIGINAL-COMMAND-RECORD "spikes/out/4000528743-command-79671-0/report.lisp"
 :ORIGINAL-DIRECTORY
 #A((103) BASE-CHAR
    . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/")
 :ORIGINAL-REPORT
 (:WORKER-ERRORS 0 :BEFORE-TESTS 0 :COMPILATION-FAILURES 0 :SURVIVED 0
  :DETECTED 8 :MUTANTS
  ((:NAME "inventory-file-boundary" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL
    :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/0/test.log")
   (:NAME "inventory-missing-closed" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL
    :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/1/test.log")
   (:NAME "inventory-id-high-word" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL
    :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/2/test.log")
   (:NAME "inventory-unknown-final" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL
    :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/3/test.log")
   (:NAME "inventory-conflict-action" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL
    NIL :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/4/test.log")
   (:NAME "inventory-active-severity" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL
    NIL :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/5/test.log")
   (:NAME "inventory-health-priority" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL
    NIL :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/6/test.log")
   (:NAME "inventory-query-zero" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL
    :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/7/test.log"))
  :BASELINE-LOG
  "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/baseline/test.log"
  :BASELINE-SIGNAL NIL :BASELINE-EXIT-CODE 0 :BASELINE :PASSED :SCOPE
  :INVENTORY :JOBS 4 :STATUS :OK)
 :RAW-FILES
 ((:PATH "report.lisp" :ORIGINAL-PATH
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/report.lisp")
   :BYTE-COUNT 1982 :GIT-BLOB "f7c16e5cdbd73f940a347e9a7072bd90905b12a3"
   :CONTENT
   "(:WORKER-ERRORS 0 :BEFORE-TESTS 0 :COMPILATION-FAILURES 0 :SURVIVED 0 :DETECTED
 8 :MUTANTS
 ((:NAME \"inventory-file-boundary\" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL
   :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/0/test.log\")
  (:NAME \"inventory-missing-closed\" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL
   :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/1/test.log\")
  (:NAME \"inventory-id-high-word\" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL
   :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/2/test.log\")
  (:NAME \"inventory-unknown-final\" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL
   :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/3/test.log\")
  (:NAME \"inventory-conflict-action\" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL
   :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/4/test.log\")
  (:NAME \"inventory-active-severity\" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL
   :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/5/test.log\")
  (:NAME \"inventory-health-priority\" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL
   :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/6/test.log\")
  (:NAME \"inventory-query-zero\" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/7/test.log\"))
 :BASELINE-LOG
 \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/baseline/test.log\"
 :BASELINE-SIGNAL NIL :BASELINE-EXIT-CODE 0 :BASELINE :PASSED :SCOPE :INVENTORY
 :JOBS 4 :STATUS :OK)
")
  (:PATH "baseline/test.log" :ORIGINAL-PATH
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/baseline/test.log")
   :BYTE-COUNT 1879 :GIT-BLOB "394e5ae78b4c8278a164500b98936cd9dc1c81af"
   :CONTENT "inventory-test-start TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE
ok    TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE
inventory-test-start TEST-REQ-REC-001-INVENTORY-ZERO-CLOSED-AND-REMOVED
ok    TEST-REQ-REC-001-INVENTORY-ZERO-CLOSED-AND-REMOVED
inventory-test-start TEST-REQ-REC-002-INVENTORY-MISSING-LIVE-AND-HEALTH-PRIORITY
ok    TEST-REQ-REC-002-INVENTORY-MISSING-LIVE-AND-HEALTH-PRIORITY
inventory-test-start TEST-REQ-REC-002-INVENTORY-BOTH-NAMES-ALWAYS-CONSERVATIVE
ok    TEST-REQ-REC-002-INVENTORY-BOTH-NAMES-ALWAYS-CONSERVATIVE
inventory-test-start TEST-REQ-REC-001-INVENTORY-EXHAUSTIVE-SMALL-MODEL-AND-INPUT-ORDERS
ok    TEST-REQ-REC-001-INVENTORY-EXHAUSTIVE-SMALL-MODEL-AND-INPUT-ORDERS
inventory-test-start TEST-REQ-AFF-008-INVENTORY-DUPLICATES-AND-INVALID-ENTRIES
ok    TEST-REQ-AFF-008-INVENTORY-DUPLICATES-AND-INVALID-ENTRIES
inventory-test-start TEST-REQ-AFF-008-INVENTORY-PHYSICAL-AND-LIVE-BUDGETS
ok    TEST-REQ-AFF-008-INVENTORY-PHYSICAL-AND-LIVE-BUDGETS
inventory-test-start TEST-REQ-AFF-008-INVENTORY-BUDGET-COUNTS-LIVE-NOT-OUTPUT-ROWS
ok    TEST-REQ-AFF-008-INVENTORY-BUDGET-COUNTS-LIVE-NOT-OUTPUT-ROWS
inventory-test-start TEST-REQ-AFF-008-INVENTORY-INVALID-ARGUMENTS-AND-QUERY-RANGE
ok    TEST-REQ-AFF-008-INVENTORY-INVALID-ARGUMENTS-AND-QUERY-RANGE
inventory-test-start TEST-REQ-REC-001-INVENTORY-UNSIGNED-U64-ORDER-AND-EXACT-IDENTITIES
ok    TEST-REQ-REC-001-INVENTORY-UNSIGNED-U64-ORDER-AND-EXACT-IDENTITIES
inventory-test-start TEST-REQ-REC-001-INVENTORY-MAXIMUM-U64-ACTIVE
ok    TEST-REQ-REC-001-INVENTORY-MAXIMUM-U64-ACTIVE
inventory-test-start TEST-REQ-AFF-017-INVENTORY-PLAN-OWNS-DATA-AFTER-INPUT-REUSE
ok    TEST-REQ-AFF-017-INVENTORY-PLAN-OWNS-DATA-AFTER-INPUT-REUSE
inventory-test-start TEST-REQ-AFF-017-INVENTORY-FOUR-PRIVATE-SERIES-AND-SHARED-PLAN
ok    TEST-REQ-AFF-017-INVENTORY-FOUR-PRIVATE-SERIES-AND-SHARED-PLAN
inventory-tests-complete 13
")
  (:PATH "baseline/tools/mutation-isolated-build.lisp" :ORIGINAL-PATH
   #A((146) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/baseline/tools/mutation-isolated-build.lisp")
   :BYTE-COUNT 1933 :GIT-BLOB "a6ef1686447288cfaaeffa5fa4dd6fd08ecf8285"
   :CONTENT "(REQUIRE :ASDF)
(ASDF/OUTPUT-TRANSLATIONS:INITIALIZE-OUTPUT-TRANSLATIONS
 '(:OUTPUT-TRANSLATIONS
   (\"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/baseline/\"
    \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/baseline/fasl/\")
   :IGNORE-INHERITED-CONFIGURATION))
(SETF UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (TESTS NIL))
  (DOLIST (FILE '(\"tests/recovery/inventory.lisp\"))
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test dedicati: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test dedicati non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&inventory-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH TESTS)))
")
  (:PATH "baseline/src/recovery/inventory-build.lisp" :ORIGINAL-PATH
   #A((145) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/baseline/src/recovery/inventory-build.lisp")
   :BYTE-COUNT 9592 :GIT-BLOB "60057f6a50c657f016bee3c21c21911b582f86fe"
   :CONTENT
   ";;;; ADR0040§3: un piano completo, conservativo per collisioni fra i due nomi.
;;; OWNER: workspace EQL e vettore delle decisioni esclusivi della singola chiamata.
;;; SHARED: nessuna scrittura su manifest/inventario; piani indipendenti fra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector integer integer) (values index &optional))
                check-inventory-budgets))
(defun check-inventory-budgets (manifest files max-files max-segments)
  \"Pre: manifest completo e inventario stabile. Post: budget fisici e bound del workspace.
INVALID-ARGUMENT per budget non index; RESOURCE-EXHAUSTED prima di ogni coalescenza.\"
  (unless (typep max-files 'index)
    (error 'invalid-argument :reason :inventory-budget))
  (unless (typep max-segments 'index)
    (error 'invalid-argument :reason :inventory-budget))
  (when (> (length files) max-files)
    (error 'resource-exhausted :reason :inventory-file-budget))
  (let ((live (1+ (numero-segmenti-chiusi manifest))))
    (when (> live max-segments)
      (error 'resource-exhausted :reason :inventory-segment-budget))
    (unless (typep (+ live (length files)) 'index)
      (error 'resource-exhausted :reason :inventory-plan-budget))
    (+ live (length files))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (simple-vector) (values hash-table &optional)) inventory-presence))
(defun inventory-presence (files)
  \"Pre: inventario stabile entro il budget fisico. Post: mappa EQL privata ID→maschera1/2/3.
INVALID-ARGUMENT per descrittore invalido o nome ripetuto; nessuna entry parziale esportata.
Il ciclo ha length(FILES) passi; entrambi i nomi per ID restano distinguibili.\"
  (let ((presence (make-hash-table :test 'eql)))
    (dotimes (i (length files))
      (let ((file (aref files i)))
        (unless (typep file 'segment-file)
          (error 'invalid-argument :reason :inventory-entry :offset i))
        (let* ((bit (case (%file-form file)
                      (:temporary 1) (:final 2)
                      (otherwise (error 'invariant-violation :reason :inventory-form))))
               (old (gethash (%file-id file) presence 0)))
          (unless (zerop (logand bit old))
            (error 'invalid-argument :reason :inventory-duplicate :offset i))
          (setf (gethash (%file-id file) presence) (logior bit old)))))
    (unless (<= (hash-table-count presence) (length files))
      (error 'invariant-violation :reason :inventory-count))
    presence))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest hash-table index) (values list &optional)) inventory-ids))
(defun inventory-ids (manifest presence bound)
  \"Pre: mappa privata e bound=nomi fisici+1+CLOSED. Post: union ID u64 distinti ordinati.
INVARIANT-VIOLATION per incoerenza interna; cicli sulle cardinalità già limitate.
SORT modifica soltanto la lista privata; nessun hash del manifest viene modificato.\"
  (unless (plusp (segmento-attivo manifest))
    (error 'invariant-violation :reason :inventory-active))
  (setf (gethash (segmento-attivo manifest) presence)
        (gethash (segmento-attivo manifest) presence 0))
  (maphash (lambda (id entry)
             (unless (typep entry 'manifest-closed)
               (error 'invariant-violation :reason :inventory-closed))
             (setf (gethash id presence) (gethash id presence 0)))
           (%manifest-closed manifest))
  (unless (<= (hash-table-count presence) bound)
    (error 'invariant-violation :reason :inventory-count))
  (let ((ids nil))
    (maphash (lambda (id mask)
               (unless (typep mask '(integer 0 3))
                 (error 'invariant-violation :reason :inventory-presence))
               (push id ids)) presence)
    (sort ids #'<)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(declaim (ftype (function ((member :active :closed :removed :unknown)
                          (member :temporary :final) (member :use :rename :delete :anomaly)) null)
                check-single-file-action))
(defun check-single-file-action (state form action)
  \"Pre: stato, forma e azione nei tipi dichiarati, controllati con safety3.
Post: nessuna rimozione senza prova e nessuna rinomina di un ID non vivo.
INVARIANT-VIOLATION per implicazioni incoerenti; nessuna mutazione o I/O.\"
  (when (eq action :delete)
    (unless (or (eq state :removed) (and (eq state :unknown) (eq form :temporary)))
      (error 'invariant-violation :reason :inventory-delete-proof)))
  (when (eq action :rename)
    (unless (member state '(:active :closed))
      (error 'invariant-violation :reason :inventory-rename-proof)))
  nil)

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(declaim (ftype (function ((member :active :closed :removed :unknown) (member :temporary :final))
                         (values (member :use :rename :delete :anomaly) &optional))
                single-file-action))
(defun single-file-action (state form)
  \"Pre: stato autorevole e un solo nome. Post: azione ADR0040§3, senza effetti durevoli.
INVARIANT-VIOLATION per stato inatteso; unknown final non viene mai eliminato.\"
  (let ((action (case state
                  ((:active :closed) (if (eq form :temporary) :rename :use))
                  (:removed :delete)
                  (:unknown (if (eq form :temporary) :delete :anomaly))
                  (otherwise (error 'invariant-violation :reason :inventory-state)))))
    (check-single-file-action state form action)
    action))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest u64 (integer 0 3))
                         (values reconciliation-entry &optional)) inventory-entry))
(defun inventory-entry (manifest id mask)
  \"Pre: ID dell'union limitata, maschera privata verificata. Post: una entry immutabile.
INVARIANT-VIOLATION per assenza di ID non vivo; conflitto domina ogni azione su file singolo.\"
  (let* ((state (trova-segmento manifest id))
         (entry
           (case mask
             (0 (unless (member state '(:active :closed))
                  (error 'invariant-violation :reason :inventory-missing-state))
                (%make-reconciliation-entry id :absent :missing state))
             (1 (%make-reconciliation-entry id :temporary (single-file-action state :temporary) state))
             (2 (%make-reconciliation-entry id :final (single-file-action state :final) state))
             (3 (%make-reconciliation-entry id :both :conflict state))
             (otherwise (error 'invariant-violation :reason :inventory-presence)))))
    (unless (and (= (%re-id entry) id) (eq (%re-state entry) state)
                 (eq (%re-form entry) (aref #(:absent :temporary :final :both) mask)))
      (error 'invariant-violation :reason :inventory-entry-proof))
    entry))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(declaim (ftype (function (reconciliation-entry) (values (integer 0 2) &optional)) entry-severity))
(defun entry-severity (entry)
  \"Pre: entry costruita dal planner. Post:0nomi disponibili,1CLOSED perso,2ACTIVE perso.
INVARIANT-VIOLATION per stato inatteso; anomaly/conflict unknown non attestano contenuti.\"
  (when (eq (%re-action entry) :missing)
    (unless (member (%re-state entry) '(:active :closed))
      (error 'invariant-violation :reason :inventory-missing-state)))
  (let ((severity (if (member (%re-action entry) '(:missing :conflict))
                      (case (%re-state entry)
                        (:active 2) (:closed 1) ((:removed :unknown) 0)
                        (otherwise (error 'invariant-violation :reason :inventory-state)))
                      0)))
    (when (plusp severity)
      (unless (member (%re-action entry) '(:missing :conflict))
        (error 'invariant-violation :reason :inventory-severity-proof)))
    severity))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-AFF-008 REQ-AFF-017 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector &key (:max-files integer) (:max-segmenti integer))
                         (values reconciliation-plan &optional)) pianifica-riconciliazione))
(defun pianifica-riconciliazione (manifest files &key (max-files 65536) (max-segmenti 65536))
  \"Pre: manifest completo, inventario completo/stabile di nomi interpretati dal chiamante.
Post: piano posseduto in ordine ID u64, stato della disponibilità dei soli nomi richiesti.
Propaga errori tipizzati; nessun piano su errore, nessun I/O, alias o mutazione degli input.
Non verifica header/CRC/identità fisica né attesta che la Serie sia apribile al traffico.
Percorso di apertura con allocazioni, cicli limitati da budget e cardinalità verificate.\"
  (let* ((bound (check-inventory-budgets manifest files max-files max-segmenti))
         (presence (inventory-presence files))
         (ids (inventory-ids manifest presence bound))
         (entries (make-array (length ids) :element-type t))
         (severity 0) (pos 0))
    (dolist (id ids)
      (let ((entry (inventory-entry manifest id (gethash id presence))))
        (setf (aref entries pos) entry severity (max severity (entry-severity entry))))
      (incf pos))
    (unless (= pos (hash-table-count presence))
      (error 'invariant-violation :reason :inventory-count))
    (%make-reconciliation-plan entries
                              (case severity
                                (0 :ready) (1 :degraded) (2 :faulted)
                                (otherwise (error 'invariant-violation :reason :inventory-health))))))
")
  (:PATH "baseline/src/recovery/inventory-query.lisp" :ORIGINAL-PATH
   #A((145) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/baseline/src/recovery/inventory-query.lisp")
   :BYTE-COUNT 2100 :GIT-BLOB "47810fb2944b4b5c18d9a9c8e60dfdc1c5f19db4"
   :CONTENT
   ";;;; Query scalari sul piano completo: non eseguono le azioni suggerite.
;;; OWNER: piano immutabile del chiamante, entry private non esportate.
;;; SHARED: letture concorrenti senza cache, lock o scritture condivise fra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(declaim (ftype (function (reconciliation-plan)
                         (values (member :ready :degraded :faulted) &optional)) stato-riconciliazione))
(defun stato-riconciliazione (plan)
  \"Pre: piano completato. Post: disponibilità dei nomi richiesti, non stato del motore.
TYPE-ERROR per tipi invalidi con safety3; nessuna modifica o autorizzazione al traffico.\"
  (%plan-health plan))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(declaim (ftype (function (reconciliation-plan) (values index &optional))
                numero-azioni-riconciliazione))
(defun numero-azioni-riconciliazione (plan)
  \"Pre: piano completato. Post: numero di ID distinti, incluse anomalie e mancanti.
TYPE-ERROR per tipi invalidi con safety3; nessun contenitore privato restituito.\"
  (length (%plan-entries plan)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (reconciliation-plan integer)
                         (values u64 (member :temporary :final :absent :both)
                                 (member :use :rename :delete :anomaly :missing :conflict)
                                 (member :active :closed :removed :unknown) &optional))
                azione-riconciliazione))
(defun azione-riconciliazione (plan position)
  \"Pre: piano completato e indice intero. Post: ID, forma, azione, stato del manifest scalari.
INVALID-ARGUMENT per indice fuori range; TYPE-ERROR per tipi invalidi, nessun alias esposto.\"
  (unless (<= 0 position (1- (numero-azioni-riconciliazione plan)))
    (error 'invalid-argument :reason :reconciliation-index))
  (let ((entry (the reconciliation-entry (aref (%plan-entries plan) position))))
    (values (%re-id entry) (%re-form entry) (%re-action entry) (%re-state entry))))
")
  (:PATH #A((10) BASE-CHAR . "0/test.log") :ORIGINAL-PATH
   #A((113) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/0/test.log")
   :BYTE-COUNT 13960 :GIT-BLOB "b5cf0c55a796720eec3bfc6d0b91f80513d1c869"
   :CONTENT "inventory-test-start TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE
ok    TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE
inventory-test-start TEST-REQ-REC-001-INVENTORY-ZERO-CLOSED-AND-REMOVED
ok    TEST-REQ-REC-001-INVENTORY-ZERO-CLOSED-AND-REMOVED
inventory-test-start TEST-REQ-REC-002-INVENTORY-MISSING-LIVE-AND-HEALTH-PRIORITY
ok    TEST-REQ-REC-002-INVENTORY-MISSING-LIVE-AND-HEALTH-PRIORITY
inventory-test-start TEST-REQ-REC-002-INVENTORY-BOTH-NAMES-ALWAYS-CONSERVATIVE
ok    TEST-REQ-REC-002-INVENTORY-BOTH-NAMES-ALWAYS-CONSERVATIVE
inventory-test-start TEST-REQ-REC-001-INVENTORY-EXHAUSTIVE-SMALL-MODEL-AND-INPUT-ORDERS
ok    TEST-REQ-REC-001-INVENTORY-EXHAUSTIVE-SMALL-MODEL-AND-INPUT-ORDERS
inventory-test-start TEST-REQ-AFF-008-INVENTORY-DUPLICATES-AND-INVALID-ENTRIES
ok    TEST-REQ-AFF-008-INVENTORY-DUPLICATES-AND-INVALID-ENTRIES
inventory-test-start TEST-REQ-AFF-008-INVENTORY-PHYSICAL-AND-LIVE-BUDGETS
Unhandled RESOURCE-EXHAUSTED in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                          {80058C0543}>:
  ArcDocDB: INVENTORY-FILE-BUDGET

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80058C0543}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<RESOURCE-EXHAUSTED {8007658913}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<RESOURCE-EXHAUSTED {8007658913}>)
2: (INVOKE-DEBUGGER #<RESOURCE-EXHAUSTED {8007658913}>)
3: (ERROR RESOURCE-EXHAUSTED :REASON :INVENTORY-FILE-BUDGET)
4: (ARCDOCDB.RECOVERY.MANIFEST::CHECK-INVENTORY-BUDGETS #S(ARCDOCDB.RECOVERY.MANIFEST::MANIFEST :ACTIVE 7 :NEXT-ID 8 :CLOSED #<HASH-TABLE :TEST EQL :COUNT 2 {80076583F3}> :REMOVED #<HASH-TABLE :TEST EQL :COUNT 1 {80076585E3}>) #(#S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 7 :FORM :FINAL) #S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 1 :FORM :TEMPORARY) #S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 2 :FORM :FINAL) #S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 3 :FORM :FINAL) #S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 9 :FORM :TEMPORARY) #S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 10 :FORM :FINAL)) 6 3)
5: (ARCDOCDB.RECOVERY.MANIFEST:PIANIFICA-RICONCILIAZIONE #S(ARCDOCDB.RECOVERY.MANIFEST::MANIFEST :ACTIVE 7 :NEXT-ID 8 :CLOSED #<HASH-TABLE :TEST EQL :COUNT 2 {80076583F3}> :REMOVED #<HASH-TABLE :TEST EQL :COUNT 1 {80076585E3}>) #(#S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 7 :FORM :FINAL) #S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 1 :FORM :TEMPORARY) #S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 2 :FORM :FINAL) #S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 3 :FORM :FINAL) #S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 9 :FORM :TEMPORARY) #S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 10 :FORM :FINAL)) :MAX-FILES 6 :MAX-SEGMENTI 3)
6: (INVENTORY-CHECK #S(ARCDOCDB.RECOVERY.MANIFEST::MANIFEST :ACTIVE 7 :NEXT-ID 8 :CLOSED #<HASH-TABLE :TEST EQL :COUNT 2 {80076583F3}> :REMOVED #<HASH-TABLE :TEST EQL :COUNT 1 {80076585E3}>) 7 (1 2) (3) ((7 . #1=(:FINAL)) (1 . #2=(:TEMPORARY)) (2 . #1#) (3 . #1#) (9 . #2#) (10 . #1#)) :MAX-FILES 6 :MAX-SEGMENTI 3)
7: (TEST-REQ-AFF-008-INVENTORY-PHYSICAL-AND-LIVE-BUDGETS)
8: (\"top level form\") [toplevel]
9: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
10: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
11: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
12: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
13: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
14: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4 NIL)
15: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4)
16: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 4)
17: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {109090F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
18: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/0/tools/mutation-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
19: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/0/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL)
20: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1090909EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/0/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/0/tools/mutation-isolated-build.lisp\" {80052B0043}>)
21: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/0/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL)
22: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/0/tools/mutation-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
23: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/0/tools/mutation-isolated-build.lisp\" {80052B0043}>)
24: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
25: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
26: (SB-IMPL::PROCESS-SCRIPT \"tools/mutation-isolated-build.lisp\")
27: (SB-IMPL::TOPLEVEL-INIT)
28: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
29: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
30: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH #A((36) BASE-CHAR . "0/tools/mutation-isolated-build.lisp")
   :ORIGINAL-PATH
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/0/tools/mutation-isolated-build.lisp")
   :BYTE-COUNT 1919 :GIT-BLOB "f65ea85cd40b5ec40aab6eb375773effeec04214"
   :CONTENT "(REQUIRE :ASDF)
(ASDF/OUTPUT-TRANSLATIONS:INITIALIZE-OUTPUT-TRANSLATIONS
 '(:OUTPUT-TRANSLATIONS
   (\"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/0/\"
    \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/0/fasl/\")
   :IGNORE-INHERITED-CONFIGURATION))
(SETF UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (TESTS NIL))
  (DOLIST (FILE '(\"tests/recovery/inventory.lisp\"))
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test dedicati: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test dedicati non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&inventory-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH TESTS)))
")
  (:PATH #A((35) BASE-CHAR . "0/src/recovery/inventory-build.lisp")
   :ORIGINAL-PATH
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/0/src/recovery/inventory-build.lisp")
   :BYTE-COUNT 9593 :GIT-BLOB "b5f57ed5712ddf6346cf13ddf6c7d80697684939"
   :CONTENT
   ";;;; ADR0040§3: un piano completo, conservativo per collisioni fra i due nomi.
;;; OWNER: workspace EQL e vettore delle decisioni esclusivi della singola chiamata.
;;; SHARED: nessuna scrittura su manifest/inventario; piani indipendenti fra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector integer integer) (values index &optional))
                check-inventory-budgets))
(defun check-inventory-budgets (manifest files max-files max-segments)
  \"Pre: manifest completo e inventario stabile. Post: budget fisici e bound del workspace.
INVALID-ARGUMENT per budget non index; RESOURCE-EXHAUSTED prima di ogni coalescenza.\"
  (unless (typep max-files 'index)
    (error 'invalid-argument :reason :inventory-budget))
  (unless (typep max-segments 'index)
    (error 'invalid-argument :reason :inventory-budget))
  (when (>= (length files) max-files)
    (error 'resource-exhausted :reason :inventory-file-budget))
  (let ((live (1+ (numero-segmenti-chiusi manifest))))
    (when (> live max-segments)
      (error 'resource-exhausted :reason :inventory-segment-budget))
    (unless (typep (+ live (length files)) 'index)
      (error 'resource-exhausted :reason :inventory-plan-budget))
    (+ live (length files))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (simple-vector) (values hash-table &optional)) inventory-presence))
(defun inventory-presence (files)
  \"Pre: inventario stabile entro il budget fisico. Post: mappa EQL privata ID→maschera1/2/3.
INVALID-ARGUMENT per descrittore invalido o nome ripetuto; nessuna entry parziale esportata.
Il ciclo ha length(FILES) passi; entrambi i nomi per ID restano distinguibili.\"
  (let ((presence (make-hash-table :test 'eql)))
    (dotimes (i (length files))
      (let ((file (aref files i)))
        (unless (typep file 'segment-file)
          (error 'invalid-argument :reason :inventory-entry :offset i))
        (let* ((bit (case (%file-form file)
                      (:temporary 1) (:final 2)
                      (otherwise (error 'invariant-violation :reason :inventory-form))))
               (old (gethash (%file-id file) presence 0)))
          (unless (zerop (logand bit old))
            (error 'invalid-argument :reason :inventory-duplicate :offset i))
          (setf (gethash (%file-id file) presence) (logior bit old)))))
    (unless (<= (hash-table-count presence) (length files))
      (error 'invariant-violation :reason :inventory-count))
    presence))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest hash-table index) (values list &optional)) inventory-ids))
(defun inventory-ids (manifest presence bound)
  \"Pre: mappa privata e bound=nomi fisici+1+CLOSED. Post: union ID u64 distinti ordinati.
INVARIANT-VIOLATION per incoerenza interna; cicli sulle cardinalità già limitate.
SORT modifica soltanto la lista privata; nessun hash del manifest viene modificato.\"
  (unless (plusp (segmento-attivo manifest))
    (error 'invariant-violation :reason :inventory-active))
  (setf (gethash (segmento-attivo manifest) presence)
        (gethash (segmento-attivo manifest) presence 0))
  (maphash (lambda (id entry)
             (unless (typep entry 'manifest-closed)
               (error 'invariant-violation :reason :inventory-closed))
             (setf (gethash id presence) (gethash id presence 0)))
           (%manifest-closed manifest))
  (unless (<= (hash-table-count presence) bound)
    (error 'invariant-violation :reason :inventory-count))
  (let ((ids nil))
    (maphash (lambda (id mask)
               (unless (typep mask '(integer 0 3))
                 (error 'invariant-violation :reason :inventory-presence))
               (push id ids)) presence)
    (sort ids #'<)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(declaim (ftype (function ((member :active :closed :removed :unknown)
                          (member :temporary :final) (member :use :rename :delete :anomaly)) null)
                check-single-file-action))
(defun check-single-file-action (state form action)
  \"Pre: stato, forma e azione nei tipi dichiarati, controllati con safety3.
Post: nessuna rimozione senza prova e nessuna rinomina di un ID non vivo.
INVARIANT-VIOLATION per implicazioni incoerenti; nessuna mutazione o I/O.\"
  (when (eq action :delete)
    (unless (or (eq state :removed) (and (eq state :unknown) (eq form :temporary)))
      (error 'invariant-violation :reason :inventory-delete-proof)))
  (when (eq action :rename)
    (unless (member state '(:active :closed))
      (error 'invariant-violation :reason :inventory-rename-proof)))
  nil)

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(declaim (ftype (function ((member :active :closed :removed :unknown) (member :temporary :final))
                         (values (member :use :rename :delete :anomaly) &optional))
                single-file-action))
(defun single-file-action (state form)
  \"Pre: stato autorevole e un solo nome. Post: azione ADR0040§3, senza effetti durevoli.
INVARIANT-VIOLATION per stato inatteso; unknown final non viene mai eliminato.\"
  (let ((action (case state
                  ((:active :closed) (if (eq form :temporary) :rename :use))
                  (:removed :delete)
                  (:unknown (if (eq form :temporary) :delete :anomaly))
                  (otherwise (error 'invariant-violation :reason :inventory-state)))))
    (check-single-file-action state form action)
    action))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest u64 (integer 0 3))
                         (values reconciliation-entry &optional)) inventory-entry))
(defun inventory-entry (manifest id mask)
  \"Pre: ID dell'union limitata, maschera privata verificata. Post: una entry immutabile.
INVARIANT-VIOLATION per assenza di ID non vivo; conflitto domina ogni azione su file singolo.\"
  (let* ((state (trova-segmento manifest id))
         (entry
           (case mask
             (0 (unless (member state '(:active :closed))
                  (error 'invariant-violation :reason :inventory-missing-state))
                (%make-reconciliation-entry id :absent :missing state))
             (1 (%make-reconciliation-entry id :temporary (single-file-action state :temporary) state))
             (2 (%make-reconciliation-entry id :final (single-file-action state :final) state))
             (3 (%make-reconciliation-entry id :both :conflict state))
             (otherwise (error 'invariant-violation :reason :inventory-presence)))))
    (unless (and (= (%re-id entry) id) (eq (%re-state entry) state)
                 (eq (%re-form entry) (aref #(:absent :temporary :final :both) mask)))
      (error 'invariant-violation :reason :inventory-entry-proof))
    entry))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(declaim (ftype (function (reconciliation-entry) (values (integer 0 2) &optional)) entry-severity))
(defun entry-severity (entry)
  \"Pre: entry costruita dal planner. Post:0nomi disponibili,1CLOSED perso,2ACTIVE perso.
INVARIANT-VIOLATION per stato inatteso; anomaly/conflict unknown non attestano contenuti.\"
  (when (eq (%re-action entry) :missing)
    (unless (member (%re-state entry) '(:active :closed))
      (error 'invariant-violation :reason :inventory-missing-state)))
  (let ((severity (if (member (%re-action entry) '(:missing :conflict))
                      (case (%re-state entry)
                        (:active 2) (:closed 1) ((:removed :unknown) 0)
                        (otherwise (error 'invariant-violation :reason :inventory-state)))
                      0)))
    (when (plusp severity)
      (unless (member (%re-action entry) '(:missing :conflict))
        (error 'invariant-violation :reason :inventory-severity-proof)))
    severity))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-AFF-008 REQ-AFF-017 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector &key (:max-files integer) (:max-segmenti integer))
                         (values reconciliation-plan &optional)) pianifica-riconciliazione))
(defun pianifica-riconciliazione (manifest files &key (max-files 65536) (max-segmenti 65536))
  \"Pre: manifest completo, inventario completo/stabile di nomi interpretati dal chiamante.
Post: piano posseduto in ordine ID u64, stato della disponibilità dei soli nomi richiesti.
Propaga errori tipizzati; nessun piano su errore, nessun I/O, alias o mutazione degli input.
Non verifica header/CRC/identità fisica né attesta che la Serie sia apribile al traffico.
Percorso di apertura con allocazioni, cicli limitati da budget e cardinalità verificate.\"
  (let* ((bound (check-inventory-budgets manifest files max-files max-segmenti))
         (presence (inventory-presence files))
         (ids (inventory-ids manifest presence bound))
         (entries (make-array (length ids) :element-type t))
         (severity 0) (pos 0))
    (dolist (id ids)
      (let ((entry (inventory-entry manifest id (gethash id presence))))
        (setf (aref entries pos) entry severity (max severity (entry-severity entry))))
      (incf pos))
    (unless (= pos (hash-table-count presence))
      (error 'invariant-violation :reason :inventory-count))
    (%make-reconciliation-plan entries
                              (case severity
                                (0 :ready) (1 :degraded) (2 :faulted)
                                (otherwise (error 'invariant-violation :reason :inventory-health))))))
")
  (:PATH #A((10) BASE-CHAR . "1/test.log") :ORIGINAL-PATH
   #A((113) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/1/test.log")
   :BYTE-COUNT 12558 :GIT-BLOB "bc1c9247aba4a6787129469a434bf1955412a1dd"
   :CONTENT "inventory-test-start TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE
ok    TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE
inventory-test-start TEST-REQ-REC-001-INVENTORY-ZERO-CLOSED-AND-REMOVED
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {80058C0423}>:
  Asserzione recovery fallita: (EQUAL (LIST (GETF EXPECTED :HEALTH))
                                      (MULTIPLE-VALUE-LIST
                                       (ARCDOCDB.RECOVERY.MANIFEST:STATO-RICONCILIAZIONE
                                        PLAN)))

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80058C0423}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8005891763}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8005891763}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8005891763}>)
3: (ERROR \"Asserzione recovery fallita: ~S\" (EQUAL (LIST (GETF EXPECTED :HEALTH)) (MULTIPLE-VALUE-LIST (ARCDOCDB.RECOVERY.MANIFEST:STATO-RICONCILIAZIONE PLAN))))
4: (INVENTORY-ASSERT-PLAN #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-PLAN :ENTRIES #(#S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 7 :FORM :TEMPORARY :ACTION :RENAME :STATE :ACTIVE)) :HEALTH :READY) (:HEALTH :DEGRADED :ROWS ((0 :ABSENT :MISSING :CLOSED) (7 :TEMPORARY :RENAME :ACTIVE))))
5: (INVENTORY-CHECK #S(ARCDOCDB.RECOVERY.MANIFEST::MANIFEST :ACTIVE 7 :NEXT-ID 8 :CLOSED #<HASH-TABLE :TEST EQL :COUNT 1 {8005891223}> :REMOVED #<HASH-TABLE :TEST EQL :COUNT 0 {8005891363}>) 7 (0) NIL ((7 :TEMPORARY)))
6: (TEST-REQ-REC-001-INVENTORY-ZERO-CLOSED-AND-REMOVED)
7: (\"top level form\") [toplevel]
8: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
9: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
10: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
11: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
12: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
13: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4 NIL)
14: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4)
15: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 4)
16: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107360F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
17: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/1/tools/mutation-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
18: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/1/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL)
19: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1073609EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/1/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/1/tools/mutation-isolated-build.lisp\" {80052B0043}>)
20: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/1/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL)
21: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/1/tools/mutation-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
22: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/1/tools/mutation-isolated-build.lisp\" {80052B0043}>)
23: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
24: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
25: (SB-IMPL::PROCESS-SCRIPT \"tools/mutation-isolated-build.lisp\")
26: (SB-IMPL::TOPLEVEL-INIT)
27: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
28: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
29: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH #A((36) BASE-CHAR . "1/tools/mutation-isolated-build.lisp")
   :ORIGINAL-PATH
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/1/tools/mutation-isolated-build.lisp")
   :BYTE-COUNT 1919 :GIT-BLOB "2819849d776c8714f3f2b90bc7d9666c4944198e"
   :CONTENT "(REQUIRE :ASDF)
(ASDF/OUTPUT-TRANSLATIONS:INITIALIZE-OUTPUT-TRANSLATIONS
 '(:OUTPUT-TRANSLATIONS
   (\"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/1/\"
    \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/1/fasl/\")
   :IGNORE-INHERITED-CONFIGURATION))
(SETF UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (TESTS NIL))
  (DOLIST (FILE '(\"tests/recovery/inventory.lisp\"))
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test dedicati: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test dedicati non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&inventory-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH TESTS)))
")
  (:PATH #A((35) BASE-CHAR . "1/src/recovery/inventory-build.lisp")
   :ORIGINAL-PATH
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/1/src/recovery/inventory-build.lisp")
   :BYTE-COUNT 9650 :GIT-BLOB "8c0ee1142926f113da8a8c772d8b0e5e82ffe5c9"
   :CONTENT
   ";;;; ADR0040§3: un piano completo, conservativo per collisioni fra i due nomi.
;;; OWNER: workspace EQL e vettore delle decisioni esclusivi della singola chiamata.
;;; SHARED: nessuna scrittura su manifest/inventario; piani indipendenti fra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector integer integer) (values index &optional))
                check-inventory-budgets))
(defun check-inventory-budgets (manifest files max-files max-segments)
  \"Pre: manifest completo e inventario stabile. Post: budget fisici e bound del workspace.
INVALID-ARGUMENT per budget non index; RESOURCE-EXHAUSTED prima di ogni coalescenza.\"
  (unless (typep max-files 'index)
    (error 'invalid-argument :reason :inventory-budget))
  (unless (typep max-segments 'index)
    (error 'invalid-argument :reason :inventory-budget))
  (when (> (length files) max-files)
    (error 'resource-exhausted :reason :inventory-file-budget))
  (let ((live (1+ (numero-segmenti-chiusi manifest))))
    (when (> live max-segments)
      (error 'resource-exhausted :reason :inventory-segment-budget))
    (unless (typep (+ live (length files)) 'index)
      (error 'resource-exhausted :reason :inventory-plan-budget))
    (+ live (length files))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (simple-vector) (values hash-table &optional)) inventory-presence))
(defun inventory-presence (files)
  \"Pre: inventario stabile entro il budget fisico. Post: mappa EQL privata ID→maschera1/2/3.
INVALID-ARGUMENT per descrittore invalido o nome ripetuto; nessuna entry parziale esportata.
Il ciclo ha length(FILES) passi; entrambi i nomi per ID restano distinguibili.\"
  (let ((presence (make-hash-table :test 'eql)))
    (dotimes (i (length files))
      (let ((file (aref files i)))
        (unless (typep file 'segment-file)
          (error 'invalid-argument :reason :inventory-entry :offset i))
        (let* ((bit (case (%file-form file)
                      (:temporary 1) (:final 2)
                      (otherwise (error 'invariant-violation :reason :inventory-form))))
               (old (gethash (%file-id file) presence 0)))
          (unless (zerop (logand bit old))
            (error 'invalid-argument :reason :inventory-duplicate :offset i))
          (setf (gethash (%file-id file) presence) (logior bit old)))))
    (unless (<= (hash-table-count presence) (length files))
      (error 'invariant-violation :reason :inventory-count))
    presence))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest hash-table index) (values list &optional)) inventory-ids))
(defun inventory-ids (manifest presence bound)
  \"Pre: mappa privata e bound=nomi fisici+1+CLOSED. Post: union ID u64 distinti ordinati.
INVARIANT-VIOLATION per incoerenza interna; cicli sulle cardinalità già limitate.
SORT modifica soltanto la lista privata; nessun hash del manifest viene modificato.\"
  (unless (plusp (segmento-attivo manifest))
    (error 'invariant-violation :reason :inventory-active))
  (setf (gethash (segmento-attivo manifest) presence)
        (gethash (segmento-attivo manifest) presence 0))
  (maphash (lambda (id entry)
             (unless (typep entry 'manifest-closed)
               (error 'invariant-violation :reason :inventory-closed))
             (when (nth-value 1 (gethash id presence))
               (setf (gethash id presence) (gethash id presence 0))))
           (%manifest-closed manifest))
  (unless (<= (hash-table-count presence) bound)
    (error 'invariant-violation :reason :inventory-count))
  (let ((ids nil))
    (maphash (lambda (id mask)
               (unless (typep mask '(integer 0 3))
                 (error 'invariant-violation :reason :inventory-presence))
               (push id ids)) presence)
    (sort ids #'<)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(declaim (ftype (function ((member :active :closed :removed :unknown)
                          (member :temporary :final) (member :use :rename :delete :anomaly)) null)
                check-single-file-action))
(defun check-single-file-action (state form action)
  \"Pre: stato, forma e azione nei tipi dichiarati, controllati con safety3.
Post: nessuna rimozione senza prova e nessuna rinomina di un ID non vivo.
INVARIANT-VIOLATION per implicazioni incoerenti; nessuna mutazione o I/O.\"
  (when (eq action :delete)
    (unless (or (eq state :removed) (and (eq state :unknown) (eq form :temporary)))
      (error 'invariant-violation :reason :inventory-delete-proof)))
  (when (eq action :rename)
    (unless (member state '(:active :closed))
      (error 'invariant-violation :reason :inventory-rename-proof)))
  nil)

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(declaim (ftype (function ((member :active :closed :removed :unknown) (member :temporary :final))
                         (values (member :use :rename :delete :anomaly) &optional))
                single-file-action))
(defun single-file-action (state form)
  \"Pre: stato autorevole e un solo nome. Post: azione ADR0040§3, senza effetti durevoli.
INVARIANT-VIOLATION per stato inatteso; unknown final non viene mai eliminato.\"
  (let ((action (case state
                  ((:active :closed) (if (eq form :temporary) :rename :use))
                  (:removed :delete)
                  (:unknown (if (eq form :temporary) :delete :anomaly))
                  (otherwise (error 'invariant-violation :reason :inventory-state)))))
    (check-single-file-action state form action)
    action))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest u64 (integer 0 3))
                         (values reconciliation-entry &optional)) inventory-entry))
(defun inventory-entry (manifest id mask)
  \"Pre: ID dell'union limitata, maschera privata verificata. Post: una entry immutabile.
INVARIANT-VIOLATION per assenza di ID non vivo; conflitto domina ogni azione su file singolo.\"
  (let* ((state (trova-segmento manifest id))
         (entry
           (case mask
             (0 (unless (member state '(:active :closed))
                  (error 'invariant-violation :reason :inventory-missing-state))
                (%make-reconciliation-entry id :absent :missing state))
             (1 (%make-reconciliation-entry id :temporary (single-file-action state :temporary) state))
             (2 (%make-reconciliation-entry id :final (single-file-action state :final) state))
             (3 (%make-reconciliation-entry id :both :conflict state))
             (otherwise (error 'invariant-violation :reason :inventory-presence)))))
    (unless (and (= (%re-id entry) id) (eq (%re-state entry) state)
                 (eq (%re-form entry) (aref #(:absent :temporary :final :both) mask)))
      (error 'invariant-violation :reason :inventory-entry-proof))
    entry))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(declaim (ftype (function (reconciliation-entry) (values (integer 0 2) &optional)) entry-severity))
(defun entry-severity (entry)
  \"Pre: entry costruita dal planner. Post:0nomi disponibili,1CLOSED perso,2ACTIVE perso.
INVARIANT-VIOLATION per stato inatteso; anomaly/conflict unknown non attestano contenuti.\"
  (when (eq (%re-action entry) :missing)
    (unless (member (%re-state entry) '(:active :closed))
      (error 'invariant-violation :reason :inventory-missing-state)))
  (let ((severity (if (member (%re-action entry) '(:missing :conflict))
                      (case (%re-state entry)
                        (:active 2) (:closed 1) ((:removed :unknown) 0)
                        (otherwise (error 'invariant-violation :reason :inventory-state)))
                      0)))
    (when (plusp severity)
      (unless (member (%re-action entry) '(:missing :conflict))
        (error 'invariant-violation :reason :inventory-severity-proof)))
    severity))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-AFF-008 REQ-AFF-017 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector &key (:max-files integer) (:max-segmenti integer))
                         (values reconciliation-plan &optional)) pianifica-riconciliazione))
(defun pianifica-riconciliazione (manifest files &key (max-files 65536) (max-segmenti 65536))
  \"Pre: manifest completo, inventario completo/stabile di nomi interpretati dal chiamante.
Post: piano posseduto in ordine ID u64, stato della disponibilità dei soli nomi richiesti.
Propaga errori tipizzati; nessun piano su errore, nessun I/O, alias o mutazione degli input.
Non verifica header/CRC/identità fisica né attesta che la Serie sia apribile al traffico.
Percorso di apertura con allocazioni, cicli limitati da budget e cardinalità verificate.\"
  (let* ((bound (check-inventory-budgets manifest files max-files max-segmenti))
         (presence (inventory-presence files))
         (ids (inventory-ids manifest presence bound))
         (entries (make-array (length ids) :element-type t))
         (severity 0) (pos 0))
    (dolist (id ids)
      (let ((entry (inventory-entry manifest id (gethash id presence))))
        (setf (aref entries pos) entry severity (max severity (entry-severity entry))))
      (incf pos))
    (unless (= pos (hash-table-count presence))
      (error 'invariant-violation :reason :inventory-count))
    (%make-reconciliation-plan entries
                              (case severity
                                (0 :ready) (1 :degraded) (2 :faulted)
                                (otherwise (error 'invariant-violation :reason :inventory-health))))))
")
  (:PATH #A((10) BASE-CHAR . "2/test.log") :ORIGINAL-PATH
   #A((113) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/2/test.log")
   :BYTE-COUNT 14776 :GIT-BLOB "992abb2eb99e6bd22ae884188fc83b147b6de406"
   :CONTENT "inventory-test-start TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE
ok    TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE
inventory-test-start TEST-REQ-REC-001-INVENTORY-ZERO-CLOSED-AND-REMOVED
ok    TEST-REQ-REC-001-INVENTORY-ZERO-CLOSED-AND-REMOVED
inventory-test-start TEST-REQ-REC-002-INVENTORY-MISSING-LIVE-AND-HEALTH-PRIORITY
ok    TEST-REQ-REC-002-INVENTORY-MISSING-LIVE-AND-HEALTH-PRIORITY
inventory-test-start TEST-REQ-REC-002-INVENTORY-BOTH-NAMES-ALWAYS-CONSERVATIVE
ok    TEST-REQ-REC-002-INVENTORY-BOTH-NAMES-ALWAYS-CONSERVATIVE
inventory-test-start TEST-REQ-REC-001-INVENTORY-EXHAUSTIVE-SMALL-MODEL-AND-INPUT-ORDERS
ok    TEST-REQ-REC-001-INVENTORY-EXHAUSTIVE-SMALL-MODEL-AND-INPUT-ORDERS
inventory-test-start TEST-REQ-AFF-008-INVENTORY-DUPLICATES-AND-INVALID-ENTRIES
ok    TEST-REQ-AFF-008-INVENTORY-DUPLICATES-AND-INVALID-ENTRIES
inventory-test-start TEST-REQ-AFF-008-INVENTORY-PHYSICAL-AND-LIVE-BUDGETS
ok    TEST-REQ-AFF-008-INVENTORY-PHYSICAL-AND-LIVE-BUDGETS
inventory-test-start TEST-REQ-AFF-008-INVENTORY-BUDGET-COUNTS-LIVE-NOT-OUTPUT-ROWS
ok    TEST-REQ-AFF-008-INVENTORY-BUDGET-COUNTS-LIVE-NOT-OUTPUT-ROWS
inventory-test-start TEST-REQ-AFF-008-INVENTORY-INVALID-ARGUMENTS-AND-QUERY-RANGE
ok    TEST-REQ-AFF-008-INVENTORY-INVALID-ARGUMENTS-AND-QUERY-RANGE
inventory-test-start TEST-REQ-REC-001-INVENTORY-UNSIGNED-U64-ORDER-AND-EXACT-IDENTITIES
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {80058C0513}>:
  Asserzione recovery fallita: (EQUAL (GETF EXPECTED :ROWS)
                                      (INVENTORY-PLAN-ROWS PLAN))

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80058C0513}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {80076552F3}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {80076552F3}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {80076552F3}>)
3: (ERROR \"Asserzione recovery fallita: ~S\" (EQUAL (GETF EXPECTED :ROWS) (INVENTORY-PLAN-ROWS PLAN)))
4: (INVENTORY-ASSERT-PLAN #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-PLAN :ENTRIES #(#S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 0 :FORM :FINAL :ACTION :USE :STATE :CLOSED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 4294967296 :FORM :FINAL :ACTION :USE :STATE :CLOSED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 9223372036854775808 :FORM :FINAL :ACTION :USE :STATE :CLOSED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 1 :FORM :FINAL :ACTION :USE :STATE :CLOSED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 4294967297 :FORM :FINAL :ACTION :USE :STATE :CLOSED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 7 :FORM :TEMPORARY :ACTION :RENAME :STATE :ACTIVE) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 18446744073709551614 :FORM :FINAL :ACTION :ANOMALY :STATE :UNKNOWN) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 18446744073709551615 :FORM :FINAL :ACTION :USE :STATE :CLOSED)) :HEALTH :READY) (:HEALTH :READY :ROWS ((0 :FINAL :USE :CLOSED) (1 :FINAL :USE :CLOSED) (7 :TEMPORARY :RENAME :ACTIVE) (4294967296 :FINAL :USE :CLOSED) (4294967297 :FINAL :USE :CLOSED) (9223372036854775808 :FINAL :USE :CLOSED) (18446744073709551614 :FINAL :ANOMALY :UNKNOWN) (18446744073709551615 :FINAL :USE :CLOSED))))
5: (INVENTORY-CHECK #S(ARCDOCDB.RECOVERY.MANIFEST::MANIFEST :ACTIVE 7 :NEXT-ID 18446744073709551616 :CLOSED #<HASH-TABLE :TEST EQL :COUNT 6 {8007654623}> :REMOVED #<HASH-TABLE :TEST EQL :COUNT 0 {8007654A43}>) 7 (0 1 4294967296 4294967297 9223372036854775808 18446744073709551615) NIL ((18446744073709551615 :FINAL) (9223372036854775808 :FINAL) (4294967297 :FINAL) (4294967296 :FINAL) (1 :FINAL) (0 :FINAL) (7 :TEMPORARY) (18446744073709551614 :FINAL)))
6: (TEST-REQ-REC-001-INVENTORY-UNSIGNED-U64-ORDER-AND-EXACT-IDENTITIES)
7: (\"top level form\") [toplevel]
8: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
9: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
10: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
11: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
12: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
13: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4 NIL)
14: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4)
15: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 4)
16: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1097A0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
17: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/2/tools/mutation-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
18: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/2/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL)
19: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1097A09EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/2/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/2/tools/mutation-isolated-build.lisp\" {80052B0043}>)
20: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/2/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL)
21: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/2/tools/mutation-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
22: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/2/tools/mutation-isolated-build.lisp\" {80052B0043}>)
23: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
24: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
25: (SB-IMPL::PROCESS-SCRIPT \"tools/mutation-isolated-build.lisp\")
26: (SB-IMPL::TOPLEVEL-INIT)
27: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
28: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
29: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH #A((36) BASE-CHAR . "2/tools/mutation-isolated-build.lisp")
   :ORIGINAL-PATH
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/2/tools/mutation-isolated-build.lisp")
   :BYTE-COUNT 1919 :GIT-BLOB "d2e9f93312f2dd02cf31030a3a7e36a8b03ee641"
   :CONTENT "(REQUIRE :ASDF)
(ASDF/OUTPUT-TRANSLATIONS:INITIALIZE-OUTPUT-TRANSLATIONS
 '(:OUTPUT-TRANSLATIONS
   (\"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/2/\"
    \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/2/fasl/\")
   :IGNORE-INHERITED-CONFIGURATION))
(SETF UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (TESTS NIL))
  (DOLIST (FILE '(\"tests/recovery/inventory.lisp\"))
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test dedicati: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test dedicati non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&inventory-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH TESTS)))
")
  (:PATH #A((35) BASE-CHAR . "2/src/recovery/inventory-build.lisp")
   :ORIGINAL-PATH
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/2/src/recovery/inventory-build.lisp")
   :BYTE-COUNT 9678 :GIT-BLOB "16963f18d751dc395b9ca323eb087d5ef81d22d4"
   :CONTENT
   ";;;; ADR0040§3: un piano completo, conservativo per collisioni fra i due nomi.
;;; OWNER: workspace EQL e vettore delle decisioni esclusivi della singola chiamata.
;;; SHARED: nessuna scrittura su manifest/inventario; piani indipendenti fra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector integer integer) (values index &optional))
                check-inventory-budgets))
(defun check-inventory-budgets (manifest files max-files max-segments)
  \"Pre: manifest completo e inventario stabile. Post: budget fisici e bound del workspace.
INVALID-ARGUMENT per budget non index; RESOURCE-EXHAUSTED prima di ogni coalescenza.\"
  (unless (typep max-files 'index)
    (error 'invalid-argument :reason :inventory-budget))
  (unless (typep max-segments 'index)
    (error 'invalid-argument :reason :inventory-budget))
  (when (> (length files) max-files)
    (error 'resource-exhausted :reason :inventory-file-budget))
  (let ((live (1+ (numero-segmenti-chiusi manifest))))
    (when (> live max-segments)
      (error 'resource-exhausted :reason :inventory-segment-budget))
    (unless (typep (+ live (length files)) 'index)
      (error 'resource-exhausted :reason :inventory-plan-budget))
    (+ live (length files))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (simple-vector) (values hash-table &optional)) inventory-presence))
(defun inventory-presence (files)
  \"Pre: inventario stabile entro il budget fisico. Post: mappa EQL privata ID→maschera1/2/3.
INVALID-ARGUMENT per descrittore invalido o nome ripetuto; nessuna entry parziale esportata.
Il ciclo ha length(FILES) passi; entrambi i nomi per ID restano distinguibili.\"
  (let ((presence (make-hash-table :test 'eql)))
    (dotimes (i (length files))
      (let ((file (aref files i)))
        (unless (typep file 'segment-file)
          (error 'invalid-argument :reason :inventory-entry :offset i))
        (let* ((bit (case (%file-form file)
                      (:temporary 1) (:final 2)
                      (otherwise (error 'invariant-violation :reason :inventory-form))))
               (old (gethash (%file-id file) presence 0)))
          (unless (zerop (logand bit old))
            (error 'invalid-argument :reason :inventory-duplicate :offset i))
          (setf (gethash (%file-id file) presence) (logior bit old)))))
    (unless (<= (hash-table-count presence) (length files))
      (error 'invariant-violation :reason :inventory-count))
    presence))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest hash-table index) (values list &optional)) inventory-ids))
(defun inventory-ids (manifest presence bound)
  \"Pre: mappa privata e bound=nomi fisici+1+CLOSED. Post: union ID u64 distinti ordinati.
INVARIANT-VIOLATION per incoerenza interna; cicli sulle cardinalità già limitate.
SORT modifica soltanto la lista privata; nessun hash del manifest viene modificato.\"
  (unless (plusp (segmento-attivo manifest))
    (error 'invariant-violation :reason :inventory-active))
  (setf (gethash (segmento-attivo manifest) presence)
        (gethash (segmento-attivo manifest) presence 0))
  (maphash (lambda (id entry)
             (unless (typep entry 'manifest-closed)
               (error 'invariant-violation :reason :inventory-closed))
             (setf (gethash id presence) (gethash id presence 0)))
           (%manifest-closed manifest))
  (unless (<= (hash-table-count presence) bound)
    (error 'invariant-violation :reason :inventory-count))
  (let ((ids nil))
    (maphash (lambda (id mask)
               (unless (typep mask '(integer 0 3))
                 (error 'invariant-violation :reason :inventory-presence))
               (push id ids)) presence)
    (sort ids (lambda (left right)
                 (< (ldb (byte 32 0) left) (ldb (byte 32 0) right))))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(declaim (ftype (function ((member :active :closed :removed :unknown)
                          (member :temporary :final) (member :use :rename :delete :anomaly)) null)
                check-single-file-action))
(defun check-single-file-action (state form action)
  \"Pre: stato, forma e azione nei tipi dichiarati, controllati con safety3.
Post: nessuna rimozione senza prova e nessuna rinomina di un ID non vivo.
INVARIANT-VIOLATION per implicazioni incoerenti; nessuna mutazione o I/O.\"
  (when (eq action :delete)
    (unless (or (eq state :removed) (and (eq state :unknown) (eq form :temporary)))
      (error 'invariant-violation :reason :inventory-delete-proof)))
  (when (eq action :rename)
    (unless (member state '(:active :closed))
      (error 'invariant-violation :reason :inventory-rename-proof)))
  nil)

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(declaim (ftype (function ((member :active :closed :removed :unknown) (member :temporary :final))
                         (values (member :use :rename :delete :anomaly) &optional))
                single-file-action))
(defun single-file-action (state form)
  \"Pre: stato autorevole e un solo nome. Post: azione ADR0040§3, senza effetti durevoli.
INVARIANT-VIOLATION per stato inatteso; unknown final non viene mai eliminato.\"
  (let ((action (case state
                  ((:active :closed) (if (eq form :temporary) :rename :use))
                  (:removed :delete)
                  (:unknown (if (eq form :temporary) :delete :anomaly))
                  (otherwise (error 'invariant-violation :reason :inventory-state)))))
    (check-single-file-action state form action)
    action))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest u64 (integer 0 3))
                         (values reconciliation-entry &optional)) inventory-entry))
(defun inventory-entry (manifest id mask)
  \"Pre: ID dell'union limitata, maschera privata verificata. Post: una entry immutabile.
INVARIANT-VIOLATION per assenza di ID non vivo; conflitto domina ogni azione su file singolo.\"
  (let* ((state (trova-segmento manifest id))
         (entry
           (case mask
             (0 (unless (member state '(:active :closed))
                  (error 'invariant-violation :reason :inventory-missing-state))
                (%make-reconciliation-entry id :absent :missing state))
             (1 (%make-reconciliation-entry id :temporary (single-file-action state :temporary) state))
             (2 (%make-reconciliation-entry id :final (single-file-action state :final) state))
             (3 (%make-reconciliation-entry id :both :conflict state))
             (otherwise (error 'invariant-violation :reason :inventory-presence)))))
    (unless (and (= (%re-id entry) id) (eq (%re-state entry) state)
                 (eq (%re-form entry) (aref #(:absent :temporary :final :both) mask)))
      (error 'invariant-violation :reason :inventory-entry-proof))
    entry))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(declaim (ftype (function (reconciliation-entry) (values (integer 0 2) &optional)) entry-severity))
(defun entry-severity (entry)
  \"Pre: entry costruita dal planner. Post:0nomi disponibili,1CLOSED perso,2ACTIVE perso.
INVARIANT-VIOLATION per stato inatteso; anomaly/conflict unknown non attestano contenuti.\"
  (when (eq (%re-action entry) :missing)
    (unless (member (%re-state entry) '(:active :closed))
      (error 'invariant-violation :reason :inventory-missing-state)))
  (let ((severity (if (member (%re-action entry) '(:missing :conflict))
                      (case (%re-state entry)
                        (:active 2) (:closed 1) ((:removed :unknown) 0)
                        (otherwise (error 'invariant-violation :reason :inventory-state)))
                      0)))
    (when (plusp severity)
      (unless (member (%re-action entry) '(:missing :conflict))
        (error 'invariant-violation :reason :inventory-severity-proof)))
    severity))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-AFF-008 REQ-AFF-017 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector &key (:max-files integer) (:max-segmenti integer))
                         (values reconciliation-plan &optional)) pianifica-riconciliazione))
(defun pianifica-riconciliazione (manifest files &key (max-files 65536) (max-segmenti 65536))
  \"Pre: manifest completo, inventario completo/stabile di nomi interpretati dal chiamante.
Post: piano posseduto in ordine ID u64, stato della disponibilità dei soli nomi richiesti.
Propaga errori tipizzati; nessun piano su errore, nessun I/O, alias o mutazione degli input.
Non verifica header/CRC/identità fisica né attesta che la Serie sia apribile al traffico.
Percorso di apertura con allocazioni, cicli limitati da budget e cardinalità verificate.\"
  (let* ((bound (check-inventory-budgets manifest files max-files max-segmenti))
         (presence (inventory-presence files))
         (ids (inventory-ids manifest presence bound))
         (entries (make-array (length ids) :element-type t))
         (severity 0) (pos 0))
    (dolist (id ids)
      (let ((entry (inventory-entry manifest id (gethash id presence))))
        (setf (aref entries pos) entry severity (max severity (entry-severity entry))))
      (incf pos))
    (unless (= pos (hash-table-count presence))
      (error 'invariant-violation :reason :inventory-count))
    (%make-reconciliation-plan entries
                              (case severity
                                (0 :ready) (1 :degraded) (2 :faulted)
                                (otherwise (error 'invariant-violation :reason :inventory-health))))))
")
  (:PATH #A((10) BASE-CHAR . "3/test.log") :ORIGINAL-PATH
   #A((113) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/3/test.log")
   :BYTE-COUNT 13040 :GIT-BLOB "fb78f25bb1dfbc1fe9d556d12613a758041b14f5"
   :CONTENT "inventory-test-start TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE
Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {80058C0573}>:
  ArcDocDB: INVENTORY-DELETE-PROOF

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80058C0573}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {80058563B3}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {80058563B3}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {80058563B3}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION :REASON :INVENTORY-DELETE-PROOF)
4: (ARCDOCDB.RECOVERY.MANIFEST::CHECK-SINGLE-FILE-ACTION :UNKNOWN :FINAL :DELETE)
5: (ARCDOCDB.RECOVERY.MANIFEST::SINGLE-FILE-ACTION :UNKNOWN :FINAL)
6: (ARCDOCDB.RECOVERY.MANIFEST::INVENTORY-ENTRY #S(ARCDOCDB.RECOVERY.MANIFEST::MANIFEST :ACTIVE 7 :NEXT-ID 8 :CLOSED #<HASH-TABLE :TEST EQL :COUNT 2 {8005855D53}> :REMOVED #<HASH-TABLE :TEST EQL :COUNT 2 {8005855F43}>) 10 2)
7: (ARCDOCDB.RECOVERY.MANIFEST:PIANIFICA-RICONCILIAZIONE #S(ARCDOCDB.RECOVERY.MANIFEST::MANIFEST :ACTIVE 7 :NEXT-ID 8 :CLOSED #<HASH-TABLE :TEST EQL :COUNT 2 {8005855D53}> :REMOVED #<HASH-TABLE :TEST EQL :COUNT 2 {8005855F43}>) #(#S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 7 :FORM :FINAL) #S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 1 :FORM :FINAL) #S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 2 :FORM :TEMPORARY) #S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 3 :FORM :FINAL) #S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 4 :FORM :TEMPORARY) #S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 9 :FORM :TEMPORARY) #S(ARCDOCDB.RECOVERY.MANIFEST::SEGMENT-FILE :ID 10 :FORM :FINAL)) :MAX-FILES 65536 :MAX-SEGMENTI 65536)
8: (INVENTORY-CHECK #S(ARCDOCDB.RECOVERY.MANIFEST::MANIFEST :ACTIVE 7 :NEXT-ID 8 :CLOSED #<HASH-TABLE :TEST EQL :COUNT 2 {8005855D53}> :REMOVED #<HASH-TABLE :TEST EQL :COUNT 2 {8005855F43}>) 7 (1 2) (3 4) ((7 . #1=(:FINAL)) (1 . #1#) (2 . #2=(:TEMPORARY)) (3 . #1#) (4 . #2#) (9 . #2#) (10 . #1#)))
9: (TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE)
10: (\"top level form\") [toplevel]
11: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
12: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
13: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
14: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
15: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
16: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4 NIL)
17: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4)
18: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 4)
19: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1074A0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
20: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/3/tools/mutation-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
21: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/3/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL)
22: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1074A09EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/3/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/3/tools/mutation-isolated-build.lisp\" {80052B0043}>)
23: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/3/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL)
24: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/3/tools/mutation-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
25: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/3/tools/mutation-isolated-build.lisp\" {80052B0043}>)
26: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
27: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
28: (SB-IMPL::PROCESS-SCRIPT \"tools/mutation-isolated-build.lisp\")
29: (SB-IMPL::TOPLEVEL-INIT)
30: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
31: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
32: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH #A((36) BASE-CHAR . "3/tools/mutation-isolated-build.lisp")
   :ORIGINAL-PATH
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/3/tools/mutation-isolated-build.lisp")
   :BYTE-COUNT 1919 :GIT-BLOB "4af992c9543763fab3910945f40ab58bb70bc315"
   :CONTENT "(REQUIRE :ASDF)
(ASDF/OUTPUT-TRANSLATIONS:INITIALIZE-OUTPUT-TRANSLATIONS
 '(:OUTPUT-TRANSLATIONS
   (\"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/3/\"
    \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/3/fasl/\")
   :IGNORE-INHERITED-CONFIGURATION))
(SETF UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (TESTS NIL))
  (DOLIST (FILE '(\"tests/recovery/inventory.lisp\"))
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test dedicati: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test dedicati non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&inventory-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH TESTS)))
")
  (:PATH #A((35) BASE-CHAR . "3/src/recovery/inventory-build.lisp")
   :ORIGINAL-PATH
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/3/src/recovery/inventory-build.lisp")
   :BYTE-COUNT 9588 :GIT-BLOB "afb0ea7707ba15b210b3716fb8fd148318589e9f"
   :CONTENT
   ";;;; ADR0040§3: un piano completo, conservativo per collisioni fra i due nomi.
;;; OWNER: workspace EQL e vettore delle decisioni esclusivi della singola chiamata.
;;; SHARED: nessuna scrittura su manifest/inventario; piani indipendenti fra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector integer integer) (values index &optional))
                check-inventory-budgets))
(defun check-inventory-budgets (manifest files max-files max-segments)
  \"Pre: manifest completo e inventario stabile. Post: budget fisici e bound del workspace.
INVALID-ARGUMENT per budget non index; RESOURCE-EXHAUSTED prima di ogni coalescenza.\"
  (unless (typep max-files 'index)
    (error 'invalid-argument :reason :inventory-budget))
  (unless (typep max-segments 'index)
    (error 'invalid-argument :reason :inventory-budget))
  (when (> (length files) max-files)
    (error 'resource-exhausted :reason :inventory-file-budget))
  (let ((live (1+ (numero-segmenti-chiusi manifest))))
    (when (> live max-segments)
      (error 'resource-exhausted :reason :inventory-segment-budget))
    (unless (typep (+ live (length files)) 'index)
      (error 'resource-exhausted :reason :inventory-plan-budget))
    (+ live (length files))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (simple-vector) (values hash-table &optional)) inventory-presence))
(defun inventory-presence (files)
  \"Pre: inventario stabile entro il budget fisico. Post: mappa EQL privata ID→maschera1/2/3.
INVALID-ARGUMENT per descrittore invalido o nome ripetuto; nessuna entry parziale esportata.
Il ciclo ha length(FILES) passi; entrambi i nomi per ID restano distinguibili.\"
  (let ((presence (make-hash-table :test 'eql)))
    (dotimes (i (length files))
      (let ((file (aref files i)))
        (unless (typep file 'segment-file)
          (error 'invalid-argument :reason :inventory-entry :offset i))
        (let* ((bit (case (%file-form file)
                      (:temporary 1) (:final 2)
                      (otherwise (error 'invariant-violation :reason :inventory-form))))
               (old (gethash (%file-id file) presence 0)))
          (unless (zerop (logand bit old))
            (error 'invalid-argument :reason :inventory-duplicate :offset i))
          (setf (gethash (%file-id file) presence) (logior bit old)))))
    (unless (<= (hash-table-count presence) (length files))
      (error 'invariant-violation :reason :inventory-count))
    presence))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest hash-table index) (values list &optional)) inventory-ids))
(defun inventory-ids (manifest presence bound)
  \"Pre: mappa privata e bound=nomi fisici+1+CLOSED. Post: union ID u64 distinti ordinati.
INVARIANT-VIOLATION per incoerenza interna; cicli sulle cardinalità già limitate.
SORT modifica soltanto la lista privata; nessun hash del manifest viene modificato.\"
  (unless (plusp (segmento-attivo manifest))
    (error 'invariant-violation :reason :inventory-active))
  (setf (gethash (segmento-attivo manifest) presence)
        (gethash (segmento-attivo manifest) presence 0))
  (maphash (lambda (id entry)
             (unless (typep entry 'manifest-closed)
               (error 'invariant-violation :reason :inventory-closed))
             (setf (gethash id presence) (gethash id presence 0)))
           (%manifest-closed manifest))
  (unless (<= (hash-table-count presence) bound)
    (error 'invariant-violation :reason :inventory-count))
  (let ((ids nil))
    (maphash (lambda (id mask)
               (unless (typep mask '(integer 0 3))
                 (error 'invariant-violation :reason :inventory-presence))
               (push id ids)) presence)
    (sort ids #'<)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(declaim (ftype (function ((member :active :closed :removed :unknown)
                          (member :temporary :final) (member :use :rename :delete :anomaly)) null)
                check-single-file-action))
(defun check-single-file-action (state form action)
  \"Pre: stato, forma e azione nei tipi dichiarati, controllati con safety3.
Post: nessuna rimozione senza prova e nessuna rinomina di un ID non vivo.
INVARIANT-VIOLATION per implicazioni incoerenti; nessuna mutazione o I/O.\"
  (when (eq action :delete)
    (unless (or (eq state :removed) (and (eq state :unknown) (eq form :temporary)))
      (error 'invariant-violation :reason :inventory-delete-proof)))
  (when (eq action :rename)
    (unless (member state '(:active :closed))
      (error 'invariant-violation :reason :inventory-rename-proof)))
  nil)

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(declaim (ftype (function ((member :active :closed :removed :unknown) (member :temporary :final))
                         (values (member :use :rename :delete :anomaly) &optional))
                single-file-action))
(defun single-file-action (state form)
  \"Pre: stato autorevole e un solo nome. Post: azione ADR0040§3, senza effetti durevoli.
INVARIANT-VIOLATION per stato inatteso; unknown final non viene mai eliminato.\"
  (let ((action (case state
                  ((:active :closed) (if (eq form :temporary) :rename :use))
                  (:removed :delete)
                  (:unknown (if (eq form :final) :delete :anomaly))
                  (otherwise (error 'invariant-violation :reason :inventory-state)))))
    (check-single-file-action state form action)
    action))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest u64 (integer 0 3))
                         (values reconciliation-entry &optional)) inventory-entry))
(defun inventory-entry (manifest id mask)
  \"Pre: ID dell'union limitata, maschera privata verificata. Post: una entry immutabile.
INVARIANT-VIOLATION per assenza di ID non vivo; conflitto domina ogni azione su file singolo.\"
  (let* ((state (trova-segmento manifest id))
         (entry
           (case mask
             (0 (unless (member state '(:active :closed))
                  (error 'invariant-violation :reason :inventory-missing-state))
                (%make-reconciliation-entry id :absent :missing state))
             (1 (%make-reconciliation-entry id :temporary (single-file-action state :temporary) state))
             (2 (%make-reconciliation-entry id :final (single-file-action state :final) state))
             (3 (%make-reconciliation-entry id :both :conflict state))
             (otherwise (error 'invariant-violation :reason :inventory-presence)))))
    (unless (and (= (%re-id entry) id) (eq (%re-state entry) state)
                 (eq (%re-form entry) (aref #(:absent :temporary :final :both) mask)))
      (error 'invariant-violation :reason :inventory-entry-proof))
    entry))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(declaim (ftype (function (reconciliation-entry) (values (integer 0 2) &optional)) entry-severity))
(defun entry-severity (entry)
  \"Pre: entry costruita dal planner. Post:0nomi disponibili,1CLOSED perso,2ACTIVE perso.
INVARIANT-VIOLATION per stato inatteso; anomaly/conflict unknown non attestano contenuti.\"
  (when (eq (%re-action entry) :missing)
    (unless (member (%re-state entry) '(:active :closed))
      (error 'invariant-violation :reason :inventory-missing-state)))
  (let ((severity (if (member (%re-action entry) '(:missing :conflict))
                      (case (%re-state entry)
                        (:active 2) (:closed 1) ((:removed :unknown) 0)
                        (otherwise (error 'invariant-violation :reason :inventory-state)))
                      0)))
    (when (plusp severity)
      (unless (member (%re-action entry) '(:missing :conflict))
        (error 'invariant-violation :reason :inventory-severity-proof)))
    severity))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-AFF-008 REQ-AFF-017 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector &key (:max-files integer) (:max-segmenti integer))
                         (values reconciliation-plan &optional)) pianifica-riconciliazione))
(defun pianifica-riconciliazione (manifest files &key (max-files 65536) (max-segmenti 65536))
  \"Pre: manifest completo, inventario completo/stabile di nomi interpretati dal chiamante.
Post: piano posseduto in ordine ID u64, stato della disponibilità dei soli nomi richiesti.
Propaga errori tipizzati; nessun piano su errore, nessun I/O, alias o mutazione degli input.
Non verifica header/CRC/identità fisica né attesta che la Serie sia apribile al traffico.
Percorso di apertura con allocazioni, cicli limitati da budget e cardinalità verificate.\"
  (let* ((bound (check-inventory-budgets manifest files max-files max-segmenti))
         (presence (inventory-presence files))
         (ids (inventory-ids manifest presence bound))
         (entries (make-array (length ids) :element-type t))
         (severity 0) (pos 0))
    (dolist (id ids)
      (let ((entry (inventory-entry manifest id (gethash id presence))))
        (setf (aref entries pos) entry severity (max severity (entry-severity entry))))
      (incf pos))
    (unless (= pos (hash-table-count presence))
      (error 'invariant-violation :reason :inventory-count))
    (%make-reconciliation-plan entries
                              (case severity
                                (0 :ready) (1 :degraded) (2 :faulted)
                                (otherwise (error 'invariant-violation :reason :inventory-health))))))
")
  (:PATH #A((10) BASE-CHAR . "4/test.log") :ORIGINAL-PATH
   #A((113) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/4/test.log")
   :BYTE-COUNT 12958 :GIT-BLOB "a9d200cded4028005fb3661dfc06915f10064226"
   :CONTENT "inventory-test-start TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE
ok    TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE
inventory-test-start TEST-REQ-REC-001-INVENTORY-ZERO-CLOSED-AND-REMOVED
ok    TEST-REQ-REC-001-INVENTORY-ZERO-CLOSED-AND-REMOVED
inventory-test-start TEST-REQ-REC-002-INVENTORY-MISSING-LIVE-AND-HEALTH-PRIORITY
ok    TEST-REQ-REC-002-INVENTORY-MISSING-LIVE-AND-HEALTH-PRIORITY
inventory-test-start TEST-REQ-REC-002-INVENTORY-BOTH-NAMES-ALWAYS-CONSERVATIVE
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {80058C0423}>:
  Asserzione recovery fallita: (EQUAL (LIST (GETF EXPECTED :HEALTH))
                                      (MULTIPLE-VALUE-LIST
                                       (ARCDOCDB.RECOVERY.MANIFEST:STATO-RICONCILIAZIONE
                                        PLAN)))

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80058C0423}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8005824AF3}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8005824AF3}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8005824AF3}>)
3: (ERROR \"Asserzione recovery fallita: ~S\" (EQUAL (LIST (GETF EXPECTED :HEALTH)) (MULTIPLE-VALUE-LIST (ARCDOCDB.RECOVERY.MANIFEST:STATO-RICONCILIAZIONE PLAN))))
4: (INVENTORY-ASSERT-PLAN #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-PLAN :ENTRIES #(#S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 1 :FORM :BOTH :ACTION :ANOMALY :STATE :CLOSED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 7 :FORM :FINAL :ACTION :USE :STATE :ACTIVE)) :HEALTH :READY) (:HEALTH :DEGRADED :ROWS ((1 :BOTH :CONFLICT :CLOSED) (7 :FINAL :USE :ACTIVE))))
5: (INVENTORY-CHECK #S(ARCDOCDB.RECOVERY.MANIFEST::MANIFEST :ACTIVE 7 :NEXT-ID 8 :CLOSED #<HASH-TABLE :TEST EQL :COUNT 1 {80058246D3}> :REMOVED #<HASH-TABLE :TEST EQL :COUNT 1 {8005824813}>) 7 (1) (3) ((7 :FINAL) (1 :TEMPORARY) (1 :FINAL)))
6: (TEST-REQ-REC-002-INVENTORY-BOTH-NAMES-ALWAYS-CONSERVATIVE)
7: (\"top level form\") [toplevel]
8: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
9: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
10: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
11: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
12: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
13: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4 NIL)
14: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4)
15: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 4)
16: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {106D20F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
17: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/4/tools/mutation-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
18: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/4/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL)
19: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {106D209EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/4/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/4/tools/mutation-isolated-build.lisp\" {80052B0043}>)
20: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/4/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL)
21: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/4/tools/mutation-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
22: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/4/tools/mutation-isolated-build.lisp\" {80052B0043}>)
23: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
24: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
25: (SB-IMPL::PROCESS-SCRIPT \"tools/mutation-isolated-build.lisp\")
26: (SB-IMPL::TOPLEVEL-INIT)
27: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
28: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
29: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH #A((36) BASE-CHAR . "4/tools/mutation-isolated-build.lisp")
   :ORIGINAL-PATH
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/4/tools/mutation-isolated-build.lisp")
   :BYTE-COUNT 1919 :GIT-BLOB "4d6fc30ee2aca68f50823e8063463fa9e5231177"
   :CONTENT "(REQUIRE :ASDF)
(ASDF/OUTPUT-TRANSLATIONS:INITIALIZE-OUTPUT-TRANSLATIONS
 '(:OUTPUT-TRANSLATIONS
   (\"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/4/\"
    \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/4/fasl/\")
   :IGNORE-INHERITED-CONFIGURATION))
(SETF UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (TESTS NIL))
  (DOLIST (FILE '(\"tests/recovery/inventory.lisp\"))
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test dedicati: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test dedicati non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&inventory-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH TESTS)))
")
  (:PATH #A((35) BASE-CHAR . "4/src/recovery/inventory-build.lisp")
   :ORIGINAL-PATH
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/4/src/recovery/inventory-build.lisp")
   :BYTE-COUNT 9591 :GIT-BLOB "1313f242e908e281aa8be56057a0db2cd5e6069e"
   :CONTENT
   ";;;; ADR0040§3: un piano completo, conservativo per collisioni fra i due nomi.
;;; OWNER: workspace EQL e vettore delle decisioni esclusivi della singola chiamata.
;;; SHARED: nessuna scrittura su manifest/inventario; piani indipendenti fra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector integer integer) (values index &optional))
                check-inventory-budgets))
(defun check-inventory-budgets (manifest files max-files max-segments)
  \"Pre: manifest completo e inventario stabile. Post: budget fisici e bound del workspace.
INVALID-ARGUMENT per budget non index; RESOURCE-EXHAUSTED prima di ogni coalescenza.\"
  (unless (typep max-files 'index)
    (error 'invalid-argument :reason :inventory-budget))
  (unless (typep max-segments 'index)
    (error 'invalid-argument :reason :inventory-budget))
  (when (> (length files) max-files)
    (error 'resource-exhausted :reason :inventory-file-budget))
  (let ((live (1+ (numero-segmenti-chiusi manifest))))
    (when (> live max-segments)
      (error 'resource-exhausted :reason :inventory-segment-budget))
    (unless (typep (+ live (length files)) 'index)
      (error 'resource-exhausted :reason :inventory-plan-budget))
    (+ live (length files))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (simple-vector) (values hash-table &optional)) inventory-presence))
(defun inventory-presence (files)
  \"Pre: inventario stabile entro il budget fisico. Post: mappa EQL privata ID→maschera1/2/3.
INVALID-ARGUMENT per descrittore invalido o nome ripetuto; nessuna entry parziale esportata.
Il ciclo ha length(FILES) passi; entrambi i nomi per ID restano distinguibili.\"
  (let ((presence (make-hash-table :test 'eql)))
    (dotimes (i (length files))
      (let ((file (aref files i)))
        (unless (typep file 'segment-file)
          (error 'invalid-argument :reason :inventory-entry :offset i))
        (let* ((bit (case (%file-form file)
                      (:temporary 1) (:final 2)
                      (otherwise (error 'invariant-violation :reason :inventory-form))))
               (old (gethash (%file-id file) presence 0)))
          (unless (zerop (logand bit old))
            (error 'invalid-argument :reason :inventory-duplicate :offset i))
          (setf (gethash (%file-id file) presence) (logior bit old)))))
    (unless (<= (hash-table-count presence) (length files))
      (error 'invariant-violation :reason :inventory-count))
    presence))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest hash-table index) (values list &optional)) inventory-ids))
(defun inventory-ids (manifest presence bound)
  \"Pre: mappa privata e bound=nomi fisici+1+CLOSED. Post: union ID u64 distinti ordinati.
INVARIANT-VIOLATION per incoerenza interna; cicli sulle cardinalità già limitate.
SORT modifica soltanto la lista privata; nessun hash del manifest viene modificato.\"
  (unless (plusp (segmento-attivo manifest))
    (error 'invariant-violation :reason :inventory-active))
  (setf (gethash (segmento-attivo manifest) presence)
        (gethash (segmento-attivo manifest) presence 0))
  (maphash (lambda (id entry)
             (unless (typep entry 'manifest-closed)
               (error 'invariant-violation :reason :inventory-closed))
             (setf (gethash id presence) (gethash id presence 0)))
           (%manifest-closed manifest))
  (unless (<= (hash-table-count presence) bound)
    (error 'invariant-violation :reason :inventory-count))
  (let ((ids nil))
    (maphash (lambda (id mask)
               (unless (typep mask '(integer 0 3))
                 (error 'invariant-violation :reason :inventory-presence))
               (push id ids)) presence)
    (sort ids #'<)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(declaim (ftype (function ((member :active :closed :removed :unknown)
                          (member :temporary :final) (member :use :rename :delete :anomaly)) null)
                check-single-file-action))
(defun check-single-file-action (state form action)
  \"Pre: stato, forma e azione nei tipi dichiarati, controllati con safety3.
Post: nessuna rimozione senza prova e nessuna rinomina di un ID non vivo.
INVARIANT-VIOLATION per implicazioni incoerenti; nessuna mutazione o I/O.\"
  (when (eq action :delete)
    (unless (or (eq state :removed) (and (eq state :unknown) (eq form :temporary)))
      (error 'invariant-violation :reason :inventory-delete-proof)))
  (when (eq action :rename)
    (unless (member state '(:active :closed))
      (error 'invariant-violation :reason :inventory-rename-proof)))
  nil)

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(declaim (ftype (function ((member :active :closed :removed :unknown) (member :temporary :final))
                         (values (member :use :rename :delete :anomaly) &optional))
                single-file-action))
(defun single-file-action (state form)
  \"Pre: stato autorevole e un solo nome. Post: azione ADR0040§3, senza effetti durevoli.
INVARIANT-VIOLATION per stato inatteso; unknown final non viene mai eliminato.\"
  (let ((action (case state
                  ((:active :closed) (if (eq form :temporary) :rename :use))
                  (:removed :delete)
                  (:unknown (if (eq form :temporary) :delete :anomaly))
                  (otherwise (error 'invariant-violation :reason :inventory-state)))))
    (check-single-file-action state form action)
    action))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest u64 (integer 0 3))
                         (values reconciliation-entry &optional)) inventory-entry))
(defun inventory-entry (manifest id mask)
  \"Pre: ID dell'union limitata, maschera privata verificata. Post: una entry immutabile.
INVARIANT-VIOLATION per assenza di ID non vivo; conflitto domina ogni azione su file singolo.\"
  (let* ((state (trova-segmento manifest id))
         (entry
           (case mask
             (0 (unless (member state '(:active :closed))
                  (error 'invariant-violation :reason :inventory-missing-state))
                (%make-reconciliation-entry id :absent :missing state))
             (1 (%make-reconciliation-entry id :temporary (single-file-action state :temporary) state))
             (2 (%make-reconciliation-entry id :final (single-file-action state :final) state))
             (3 (%make-reconciliation-entry id :both :anomaly state))
             (otherwise (error 'invariant-violation :reason :inventory-presence)))))
    (unless (and (= (%re-id entry) id) (eq (%re-state entry) state)
                 (eq (%re-form entry) (aref #(:absent :temporary :final :both) mask)))
      (error 'invariant-violation :reason :inventory-entry-proof))
    entry))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(declaim (ftype (function (reconciliation-entry) (values (integer 0 2) &optional)) entry-severity))
(defun entry-severity (entry)
  \"Pre: entry costruita dal planner. Post:0nomi disponibili,1CLOSED perso,2ACTIVE perso.
INVARIANT-VIOLATION per stato inatteso; anomaly/conflict unknown non attestano contenuti.\"
  (when (eq (%re-action entry) :missing)
    (unless (member (%re-state entry) '(:active :closed))
      (error 'invariant-violation :reason :inventory-missing-state)))
  (let ((severity (if (member (%re-action entry) '(:missing :conflict))
                      (case (%re-state entry)
                        (:active 2) (:closed 1) ((:removed :unknown) 0)
                        (otherwise (error 'invariant-violation :reason :inventory-state)))
                      0)))
    (when (plusp severity)
      (unless (member (%re-action entry) '(:missing :conflict))
        (error 'invariant-violation :reason :inventory-severity-proof)))
    severity))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-AFF-008 REQ-AFF-017 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector &key (:max-files integer) (:max-segmenti integer))
                         (values reconciliation-plan &optional)) pianifica-riconciliazione))
(defun pianifica-riconciliazione (manifest files &key (max-files 65536) (max-segmenti 65536))
  \"Pre: manifest completo, inventario completo/stabile di nomi interpretati dal chiamante.
Post: piano posseduto in ordine ID u64, stato della disponibilità dei soli nomi richiesti.
Propaga errori tipizzati; nessun piano su errore, nessun I/O, alias o mutazione degli input.
Non verifica header/CRC/identità fisica né attesta che la Serie sia apribile al traffico.
Percorso di apertura con allocazioni, cicli limitati da budget e cardinalità verificate.\"
  (let* ((bound (check-inventory-budgets manifest files max-files max-segmenti))
         (presence (inventory-presence files))
         (ids (inventory-ids manifest presence bound))
         (entries (make-array (length ids) :element-type t))
         (severity 0) (pos 0))
    (dolist (id ids)
      (let ((entry (inventory-entry manifest id (gethash id presence))))
        (setf (aref entries pos) entry severity (max severity (entry-severity entry))))
      (incf pos))
    (unless (= pos (hash-table-count presence))
      (error 'invariant-violation :reason :inventory-count))
    (%make-reconciliation-plan entries
                              (case severity
                                (0 :ready) (1 :degraded) (2 :faulted)
                                (otherwise (error 'invariant-violation :reason :inventory-health))))))
")
  (:PATH #A((10) BASE-CHAR . "5/test.log") :ORIGINAL-PATH
   #A((113) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/5/test.log")
   :BYTE-COUNT 12933 :GIT-BLOB "d3610d2eae6f3d85ff6b178a2de3e44bcb5c0fec"
   :CONTENT "inventory-test-start TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE
ok    TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE
inventory-test-start TEST-REQ-REC-001-INVENTORY-ZERO-CLOSED-AND-REMOVED
ok    TEST-REQ-REC-001-INVENTORY-ZERO-CLOSED-AND-REMOVED
inventory-test-start TEST-REQ-REC-002-INVENTORY-MISSING-LIVE-AND-HEALTH-PRIORITY
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {80058C0393}>:
  Asserzione recovery fallita: (EQUAL (LIST (GETF EXPECTED :HEALTH))
                                      (MULTIPLE-VALUE-LIST
                                       (ARCDOCDB.RECOVERY.MANIFEST:STATO-RICONCILIAZIONE
                                        PLAN)))

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80058C0393}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {80057FF3B3}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {80057FF3B3}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {80057FF3B3}>)
3: (ERROR \"Asserzione recovery fallita: ~S\" (EQUAL (LIST (GETF EXPECTED :HEALTH)) (MULTIPLE-VALUE-LIST (ARCDOCDB.RECOVERY.MANIFEST:STATO-RICONCILIAZIONE PLAN))))
4: (INVENTORY-ASSERT-PLAN #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-PLAN :ENTRIES #(#S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 1 :FORM :ABSENT :ACTION :MISSING :STATE :CLOSED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 2 :FORM :ABSENT :ACTION :MISSING :STATE :CLOSED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 7 :FORM :ABSENT :ACTION :MISSING :STATE :ACTIVE)) :HEALTH :DEGRADED) (:HEALTH :FAULTED :ROWS ((1 :ABSENT :MISSING :CLOSED) (2 :ABSENT :MISSING :CLOSED) (7 :ABSENT :MISSING :ACTIVE))))
5: (INVENTORY-CHECK #S(ARCDOCDB.RECOVERY.MANIFEST::MANIFEST :ACTIVE 7 :NEXT-ID 8 :CLOSED #<HASH-TABLE :TEST EQL :COUNT 2 {80057FEF43}> :REMOVED #<HASH-TABLE :TEST EQL :COUNT 2 {80057FF133}>) 7 (1 2) (3 4) NIL)
6: (TEST-REQ-REC-002-INVENTORY-MISSING-LIVE-AND-HEALTH-PRIORITY)
7: (\"top level form\") [toplevel]
8: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
9: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
10: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
11: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
12: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
13: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4 NIL)
14: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4)
15: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 4)
16: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107630F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
17: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/5/tools/mutation-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
18: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/5/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL)
19: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1076309EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/5/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/5/tools/mutation-isolated-build.lisp\" {80052B0043}>)
20: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/5/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL)
21: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/5/tools/mutation-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
22: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/5/tools/mutation-isolated-build.lisp\" {80052B0043}>)
23: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
24: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
25: (SB-IMPL::PROCESS-SCRIPT \"tools/mutation-isolated-build.lisp\")
26: (SB-IMPL::TOPLEVEL-INIT)
27: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
28: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
29: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH #A((36) BASE-CHAR . "5/tools/mutation-isolated-build.lisp")
   :ORIGINAL-PATH
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/5/tools/mutation-isolated-build.lisp")
   :BYTE-COUNT 1919 :GIT-BLOB "34dca6c0720a0de74bd7fda90fc97b3c837c6cb4"
   :CONTENT "(REQUIRE :ASDF)
(ASDF/OUTPUT-TRANSLATIONS:INITIALIZE-OUTPUT-TRANSLATIONS
 '(:OUTPUT-TRANSLATIONS
   (\"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/5/\"
    \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/5/fasl/\")
   :IGNORE-INHERITED-CONFIGURATION))
(SETF UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (TESTS NIL))
  (DOLIST (FILE '(\"tests/recovery/inventory.lisp\"))
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test dedicati: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test dedicati non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&inventory-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH TESTS)))
")
  (:PATH #A((35) BASE-CHAR . "5/src/recovery/inventory-build.lisp")
   :ORIGINAL-PATH
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/5/src/recovery/inventory-build.lisp")
   :BYTE-COUNT 9592 :GIT-BLOB "32e479f519d098569cf5a61387c4ebd7e5192e4d"
   :CONTENT
   ";;;; ADR0040§3: un piano completo, conservativo per collisioni fra i due nomi.
;;; OWNER: workspace EQL e vettore delle decisioni esclusivi della singola chiamata.
;;; SHARED: nessuna scrittura su manifest/inventario; piani indipendenti fra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector integer integer) (values index &optional))
                check-inventory-budgets))
(defun check-inventory-budgets (manifest files max-files max-segments)
  \"Pre: manifest completo e inventario stabile. Post: budget fisici e bound del workspace.
INVALID-ARGUMENT per budget non index; RESOURCE-EXHAUSTED prima di ogni coalescenza.\"
  (unless (typep max-files 'index)
    (error 'invalid-argument :reason :inventory-budget))
  (unless (typep max-segments 'index)
    (error 'invalid-argument :reason :inventory-budget))
  (when (> (length files) max-files)
    (error 'resource-exhausted :reason :inventory-file-budget))
  (let ((live (1+ (numero-segmenti-chiusi manifest))))
    (when (> live max-segments)
      (error 'resource-exhausted :reason :inventory-segment-budget))
    (unless (typep (+ live (length files)) 'index)
      (error 'resource-exhausted :reason :inventory-plan-budget))
    (+ live (length files))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (simple-vector) (values hash-table &optional)) inventory-presence))
(defun inventory-presence (files)
  \"Pre: inventario stabile entro il budget fisico. Post: mappa EQL privata ID→maschera1/2/3.
INVALID-ARGUMENT per descrittore invalido o nome ripetuto; nessuna entry parziale esportata.
Il ciclo ha length(FILES) passi; entrambi i nomi per ID restano distinguibili.\"
  (let ((presence (make-hash-table :test 'eql)))
    (dotimes (i (length files))
      (let ((file (aref files i)))
        (unless (typep file 'segment-file)
          (error 'invalid-argument :reason :inventory-entry :offset i))
        (let* ((bit (case (%file-form file)
                      (:temporary 1) (:final 2)
                      (otherwise (error 'invariant-violation :reason :inventory-form))))
               (old (gethash (%file-id file) presence 0)))
          (unless (zerop (logand bit old))
            (error 'invalid-argument :reason :inventory-duplicate :offset i))
          (setf (gethash (%file-id file) presence) (logior bit old)))))
    (unless (<= (hash-table-count presence) (length files))
      (error 'invariant-violation :reason :inventory-count))
    presence))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest hash-table index) (values list &optional)) inventory-ids))
(defun inventory-ids (manifest presence bound)
  \"Pre: mappa privata e bound=nomi fisici+1+CLOSED. Post: union ID u64 distinti ordinati.
INVARIANT-VIOLATION per incoerenza interna; cicli sulle cardinalità già limitate.
SORT modifica soltanto la lista privata; nessun hash del manifest viene modificato.\"
  (unless (plusp (segmento-attivo manifest))
    (error 'invariant-violation :reason :inventory-active))
  (setf (gethash (segmento-attivo manifest) presence)
        (gethash (segmento-attivo manifest) presence 0))
  (maphash (lambda (id entry)
             (unless (typep entry 'manifest-closed)
               (error 'invariant-violation :reason :inventory-closed))
             (setf (gethash id presence) (gethash id presence 0)))
           (%manifest-closed manifest))
  (unless (<= (hash-table-count presence) bound)
    (error 'invariant-violation :reason :inventory-count))
  (let ((ids nil))
    (maphash (lambda (id mask)
               (unless (typep mask '(integer 0 3))
                 (error 'invariant-violation :reason :inventory-presence))
               (push id ids)) presence)
    (sort ids #'<)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(declaim (ftype (function ((member :active :closed :removed :unknown)
                          (member :temporary :final) (member :use :rename :delete :anomaly)) null)
                check-single-file-action))
(defun check-single-file-action (state form action)
  \"Pre: stato, forma e azione nei tipi dichiarati, controllati con safety3.
Post: nessuna rimozione senza prova e nessuna rinomina di un ID non vivo.
INVARIANT-VIOLATION per implicazioni incoerenti; nessuna mutazione o I/O.\"
  (when (eq action :delete)
    (unless (or (eq state :removed) (and (eq state :unknown) (eq form :temporary)))
      (error 'invariant-violation :reason :inventory-delete-proof)))
  (when (eq action :rename)
    (unless (member state '(:active :closed))
      (error 'invariant-violation :reason :inventory-rename-proof)))
  nil)

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(declaim (ftype (function ((member :active :closed :removed :unknown) (member :temporary :final))
                         (values (member :use :rename :delete :anomaly) &optional))
                single-file-action))
(defun single-file-action (state form)
  \"Pre: stato autorevole e un solo nome. Post: azione ADR0040§3, senza effetti durevoli.
INVARIANT-VIOLATION per stato inatteso; unknown final non viene mai eliminato.\"
  (let ((action (case state
                  ((:active :closed) (if (eq form :temporary) :rename :use))
                  (:removed :delete)
                  (:unknown (if (eq form :temporary) :delete :anomaly))
                  (otherwise (error 'invariant-violation :reason :inventory-state)))))
    (check-single-file-action state form action)
    action))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest u64 (integer 0 3))
                         (values reconciliation-entry &optional)) inventory-entry))
(defun inventory-entry (manifest id mask)
  \"Pre: ID dell'union limitata, maschera privata verificata. Post: una entry immutabile.
INVARIANT-VIOLATION per assenza di ID non vivo; conflitto domina ogni azione su file singolo.\"
  (let* ((state (trova-segmento manifest id))
         (entry
           (case mask
             (0 (unless (member state '(:active :closed))
                  (error 'invariant-violation :reason :inventory-missing-state))
                (%make-reconciliation-entry id :absent :missing state))
             (1 (%make-reconciliation-entry id :temporary (single-file-action state :temporary) state))
             (2 (%make-reconciliation-entry id :final (single-file-action state :final) state))
             (3 (%make-reconciliation-entry id :both :conflict state))
             (otherwise (error 'invariant-violation :reason :inventory-presence)))))
    (unless (and (= (%re-id entry) id) (eq (%re-state entry) state)
                 (eq (%re-form entry) (aref #(:absent :temporary :final :both) mask)))
      (error 'invariant-violation :reason :inventory-entry-proof))
    entry))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(declaim (ftype (function (reconciliation-entry) (values (integer 0 2) &optional)) entry-severity))
(defun entry-severity (entry)
  \"Pre: entry costruita dal planner. Post:0nomi disponibili,1CLOSED perso,2ACTIVE perso.
INVARIANT-VIOLATION per stato inatteso; anomaly/conflict unknown non attestano contenuti.\"
  (when (eq (%re-action entry) :missing)
    (unless (member (%re-state entry) '(:active :closed))
      (error 'invariant-violation :reason :inventory-missing-state)))
  (let ((severity (if (member (%re-action entry) '(:missing :conflict))
                      (case (%re-state entry)
                        (:active 1) (:closed 1) ((:removed :unknown) 0)
                        (otherwise (error 'invariant-violation :reason :inventory-state)))
                      0)))
    (when (plusp severity)
      (unless (member (%re-action entry) '(:missing :conflict))
        (error 'invariant-violation :reason :inventory-severity-proof)))
    severity))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-AFF-008 REQ-AFF-017 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector &key (:max-files integer) (:max-segmenti integer))
                         (values reconciliation-plan &optional)) pianifica-riconciliazione))
(defun pianifica-riconciliazione (manifest files &key (max-files 65536) (max-segmenti 65536))
  \"Pre: manifest completo, inventario completo/stabile di nomi interpretati dal chiamante.
Post: piano posseduto in ordine ID u64, stato della disponibilità dei soli nomi richiesti.
Propaga errori tipizzati; nessun piano su errore, nessun I/O, alias o mutazione degli input.
Non verifica header/CRC/identità fisica né attesta che la Serie sia apribile al traffico.
Percorso di apertura con allocazioni, cicli limitati da budget e cardinalità verificate.\"
  (let* ((bound (check-inventory-budgets manifest files max-files max-segmenti))
         (presence (inventory-presence files))
         (ids (inventory-ids manifest presence bound))
         (entries (make-array (length ids) :element-type t))
         (severity 0) (pos 0))
    (dolist (id ids)
      (let ((entry (inventory-entry manifest id (gethash id presence))))
        (setf (aref entries pos) entry severity (max severity (entry-severity entry))))
      (incf pos))
    (unless (= pos (hash-table-count presence))
      (error 'invariant-violation :reason :inventory-count))
    (%make-reconciliation-plan entries
                              (case severity
                                (0 :ready) (1 :degraded) (2 :faulted)
                                (otherwise (error 'invariant-violation :reason :inventory-health))))))
")
  (:PATH #A((10) BASE-CHAR . "6/test.log") :ORIGINAL-PATH
   #A((113) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/6/test.log")
   :BYTE-COUNT 12663 :GIT-BLOB "9d3fccc6e7c2e1cc1de3be1ea4d65dd42674b508"
   :CONTENT "inventory-test-start TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE
ok    TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE
inventory-test-start TEST-REQ-REC-001-INVENTORY-ZERO-CLOSED-AND-REMOVED
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {80058C0393}>:
  Asserzione recovery fallita: (EQUAL (LIST (GETF EXPECTED :HEALTH))
                                      (MULTIPLE-VALUE-LIST
                                       (ARCDOCDB.RECOVERY.MANIFEST:STATO-RICONCILIAZIONE
                                        PLAN)))

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80058C0393}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {80057BF593}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {80057BF593}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {80057BF593}>)
3: (ERROR \"Asserzione recovery fallita: ~S\" (EQUAL (LIST (GETF EXPECTED :HEALTH)) (MULTIPLE-VALUE-LIST (ARCDOCDB.RECOVERY.MANIFEST:STATO-RICONCILIAZIONE PLAN))))
4: (INVENTORY-ASSERT-PLAN #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-PLAN :ENTRIES #(#S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 0 :FORM :ABSENT :ACTION :MISSING :STATE :CLOSED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 7 :FORM :TEMPORARY :ACTION :RENAME :STATE :ACTIVE)) :HEALTH :READY) (:HEALTH :DEGRADED :ROWS ((0 :ABSENT :MISSING :CLOSED) (7 :TEMPORARY :RENAME :ACTIVE))))
5: (INVENTORY-CHECK #S(ARCDOCDB.RECOVERY.MANIFEST::MANIFEST :ACTIVE 7 :NEXT-ID 8 :CLOSED #<HASH-TABLE :TEST EQL :COUNT 1 {80057BF023}> :REMOVED #<HASH-TABLE :TEST EQL :COUNT 0 {80057BF163}>) 7 (0) NIL ((7 :TEMPORARY)))
6: (TEST-REQ-REC-001-INVENTORY-ZERO-CLOSED-AND-REMOVED)
7: (\"top level form\") [toplevel]
8: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
9: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
10: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
11: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
12: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
13: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4 NIL)
14: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4)
15: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 4)
16: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {106FA0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
17: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/6/tools/mutation-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
18: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/6/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL)
19: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {106FA09EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/6/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/6/tools/mutation-isolated-build.lisp\" {80052B0043}>)
20: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/6/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL)
21: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/6/tools/mutation-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
22: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/6/tools/mutation-isolated-build.lisp\" {80052B0043}>)
23: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
24: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
25: (SB-IMPL::PROCESS-SCRIPT \"tools/mutation-isolated-build.lisp\")
26: (SB-IMPL::TOPLEVEL-INIT)
27: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
28: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
29: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH #A((36) BASE-CHAR . "6/tools/mutation-isolated-build.lisp")
   :ORIGINAL-PATH
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/6/tools/mutation-isolated-build.lisp")
   :BYTE-COUNT 1919 :GIT-BLOB "928abef5c8e8b9ac5ae2e8a8309fe40f5d622696"
   :CONTENT "(REQUIRE :ASDF)
(ASDF/OUTPUT-TRANSLATIONS:INITIALIZE-OUTPUT-TRANSLATIONS
 '(:OUTPUT-TRANSLATIONS
   (\"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/6/\"
    \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/6/fasl/\")
   :IGNORE-INHERITED-CONFIGURATION))
(SETF UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (TESTS NIL))
  (DOLIST (FILE '(\"tests/recovery/inventory.lisp\"))
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test dedicati: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test dedicati non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&inventory-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH TESTS)))
")
  (:PATH #A((35) BASE-CHAR . "6/src/recovery/inventory-build.lisp")
   :ORIGINAL-PATH
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/6/src/recovery/inventory-build.lisp")
   :BYTE-COUNT 9577 :GIT-BLOB "a1ec531e371604ca3860b32ea801d05fc2f144f9"
   :CONTENT
   ";;;; ADR0040§3: un piano completo, conservativo per collisioni fra i due nomi.
;;; OWNER: workspace EQL e vettore delle decisioni esclusivi della singola chiamata.
;;; SHARED: nessuna scrittura su manifest/inventario; piani indipendenti fra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector integer integer) (values index &optional))
                check-inventory-budgets))
(defun check-inventory-budgets (manifest files max-files max-segments)
  \"Pre: manifest completo e inventario stabile. Post: budget fisici e bound del workspace.
INVALID-ARGUMENT per budget non index; RESOURCE-EXHAUSTED prima di ogni coalescenza.\"
  (unless (typep max-files 'index)
    (error 'invalid-argument :reason :inventory-budget))
  (unless (typep max-segments 'index)
    (error 'invalid-argument :reason :inventory-budget))
  (when (> (length files) max-files)
    (error 'resource-exhausted :reason :inventory-file-budget))
  (let ((live (1+ (numero-segmenti-chiusi manifest))))
    (when (> live max-segments)
      (error 'resource-exhausted :reason :inventory-segment-budget))
    (unless (typep (+ live (length files)) 'index)
      (error 'resource-exhausted :reason :inventory-plan-budget))
    (+ live (length files))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (simple-vector) (values hash-table &optional)) inventory-presence))
(defun inventory-presence (files)
  \"Pre: inventario stabile entro il budget fisico. Post: mappa EQL privata ID→maschera1/2/3.
INVALID-ARGUMENT per descrittore invalido o nome ripetuto; nessuna entry parziale esportata.
Il ciclo ha length(FILES) passi; entrambi i nomi per ID restano distinguibili.\"
  (let ((presence (make-hash-table :test 'eql)))
    (dotimes (i (length files))
      (let ((file (aref files i)))
        (unless (typep file 'segment-file)
          (error 'invalid-argument :reason :inventory-entry :offset i))
        (let* ((bit (case (%file-form file)
                      (:temporary 1) (:final 2)
                      (otherwise (error 'invariant-violation :reason :inventory-form))))
               (old (gethash (%file-id file) presence 0)))
          (unless (zerop (logand bit old))
            (error 'invalid-argument :reason :inventory-duplicate :offset i))
          (setf (gethash (%file-id file) presence) (logior bit old)))))
    (unless (<= (hash-table-count presence) (length files))
      (error 'invariant-violation :reason :inventory-count))
    presence))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest hash-table index) (values list &optional)) inventory-ids))
(defun inventory-ids (manifest presence bound)
  \"Pre: mappa privata e bound=nomi fisici+1+CLOSED. Post: union ID u64 distinti ordinati.
INVARIANT-VIOLATION per incoerenza interna; cicli sulle cardinalità già limitate.
SORT modifica soltanto la lista privata; nessun hash del manifest viene modificato.\"
  (unless (plusp (segmento-attivo manifest))
    (error 'invariant-violation :reason :inventory-active))
  (setf (gethash (segmento-attivo manifest) presence)
        (gethash (segmento-attivo manifest) presence 0))
  (maphash (lambda (id entry)
             (unless (typep entry 'manifest-closed)
               (error 'invariant-violation :reason :inventory-closed))
             (setf (gethash id presence) (gethash id presence 0)))
           (%manifest-closed manifest))
  (unless (<= (hash-table-count presence) bound)
    (error 'invariant-violation :reason :inventory-count))
  (let ((ids nil))
    (maphash (lambda (id mask)
               (unless (typep mask '(integer 0 3))
                 (error 'invariant-violation :reason :inventory-presence))
               (push id ids)) presence)
    (sort ids #'<)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(declaim (ftype (function ((member :active :closed :removed :unknown)
                          (member :temporary :final) (member :use :rename :delete :anomaly)) null)
                check-single-file-action))
(defun check-single-file-action (state form action)
  \"Pre: stato, forma e azione nei tipi dichiarati, controllati con safety3.
Post: nessuna rimozione senza prova e nessuna rinomina di un ID non vivo.
INVARIANT-VIOLATION per implicazioni incoerenti; nessuna mutazione o I/O.\"
  (when (eq action :delete)
    (unless (or (eq state :removed) (and (eq state :unknown) (eq form :temporary)))
      (error 'invariant-violation :reason :inventory-delete-proof)))
  (when (eq action :rename)
    (unless (member state '(:active :closed))
      (error 'invariant-violation :reason :inventory-rename-proof)))
  nil)

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(declaim (ftype (function ((member :active :closed :removed :unknown) (member :temporary :final))
                         (values (member :use :rename :delete :anomaly) &optional))
                single-file-action))
(defun single-file-action (state form)
  \"Pre: stato autorevole e un solo nome. Post: azione ADR0040§3, senza effetti durevoli.
INVARIANT-VIOLATION per stato inatteso; unknown final non viene mai eliminato.\"
  (let ((action (case state
                  ((:active :closed) (if (eq form :temporary) :rename :use))
                  (:removed :delete)
                  (:unknown (if (eq form :temporary) :delete :anomaly))
                  (otherwise (error 'invariant-violation :reason :inventory-state)))))
    (check-single-file-action state form action)
    action))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest u64 (integer 0 3))
                         (values reconciliation-entry &optional)) inventory-entry))
(defun inventory-entry (manifest id mask)
  \"Pre: ID dell'union limitata, maschera privata verificata. Post: una entry immutabile.
INVARIANT-VIOLATION per assenza di ID non vivo; conflitto domina ogni azione su file singolo.\"
  (let* ((state (trova-segmento manifest id))
         (entry
           (case mask
             (0 (unless (member state '(:active :closed))
                  (error 'invariant-violation :reason :inventory-missing-state))
                (%make-reconciliation-entry id :absent :missing state))
             (1 (%make-reconciliation-entry id :temporary (single-file-action state :temporary) state))
             (2 (%make-reconciliation-entry id :final (single-file-action state :final) state))
             (3 (%make-reconciliation-entry id :both :conflict state))
             (otherwise (error 'invariant-violation :reason :inventory-presence)))))
    (unless (and (= (%re-id entry) id) (eq (%re-state entry) state)
                 (eq (%re-form entry) (aref #(:absent :temporary :final :both) mask)))
      (error 'invariant-violation :reason :inventory-entry-proof))
    entry))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(declaim (ftype (function (reconciliation-entry) (values (integer 0 2) &optional)) entry-severity))
(defun entry-severity (entry)
  \"Pre: entry costruita dal planner. Post:0nomi disponibili,1CLOSED perso,2ACTIVE perso.
INVARIANT-VIOLATION per stato inatteso; anomaly/conflict unknown non attestano contenuti.\"
  (when (eq (%re-action entry) :missing)
    (unless (member (%re-state entry) '(:active :closed))
      (error 'invariant-violation :reason :inventory-missing-state)))
  (let ((severity (if (member (%re-action entry) '(:missing :conflict))
                      (case (%re-state entry)
                        (:active 2) (:closed 1) ((:removed :unknown) 0)
                        (otherwise (error 'invariant-violation :reason :inventory-state)))
                      0)))
    (when (plusp severity)
      (unless (member (%re-action entry) '(:missing :conflict))
        (error 'invariant-violation :reason :inventory-severity-proof)))
    severity))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-AFF-008 REQ-AFF-017 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector &key (:max-files integer) (:max-segmenti integer))
                         (values reconciliation-plan &optional)) pianifica-riconciliazione))
(defun pianifica-riconciliazione (manifest files &key (max-files 65536) (max-segmenti 65536))
  \"Pre: manifest completo, inventario completo/stabile di nomi interpretati dal chiamante.
Post: piano posseduto in ordine ID u64, stato della disponibilità dei soli nomi richiesti.
Propaga errori tipizzati; nessun piano su errore, nessun I/O, alias o mutazione degli input.
Non verifica header/CRC/identità fisica né attesta che la Serie sia apribile al traffico.
Percorso di apertura con allocazioni, cicli limitati da budget e cardinalità verificate.\"
  (let* ((bound (check-inventory-budgets manifest files max-files max-segmenti))
         (presence (inventory-presence files))
         (ids (inventory-ids manifest presence bound))
         (entries (make-array (length ids) :element-type t))
         (severity 0) (pos 0))
    (dolist (id ids)
      (let ((entry (inventory-entry manifest id (gethash id presence))))
        (setf (aref entries pos) entry severity (entry-severity entry)))
      (incf pos))
    (unless (= pos (hash-table-count presence))
      (error 'invariant-violation :reason :inventory-count))
    (%make-reconciliation-plan entries
                              (case severity
                                (0 :ready) (1 :degraded) (2 :faulted)
                                (otherwise (error 'invariant-violation :reason :inventory-health))))))
")
  (:PATH #A((10) BASE-CHAR . "7/test.log") :ORIGINAL-PATH
   #A((113) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/7/test.log")
   :BYTE-COUNT 14563 :GIT-BLOB "9c3271ca238347fc5c29092e37b9a85db17bde73"
   :CONTENT "inventory-test-start TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE
Unhandled INVALID-ARGUMENT in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                        {80058E0423}>:
  ArcDocDB: RECONCILIATION-INDEX

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80058E0423}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<INVALID-ARGUMENT {80053F5113}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<INVALID-ARGUMENT {80053F5113}>)
2: (INVOKE-DEBUGGER #<INVALID-ARGUMENT {80053F5113}>)
3: (ERROR INVALID-ARGUMENT :REASON :RECONCILIATION-INDEX)
4: (ARCDOCDB.RECOVERY.MANIFEST:AZIONE-RICONCILIAZIONE #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-PLAN :ENTRIES #(#S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 1 :FORM :FINAL :ACTION :USE :STATE :CLOSED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 2 :FORM :TEMPORARY :ACTION :RENAME :STATE :CLOSED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 3 :FORM :FINAL :ACTION :DELETE :STATE :REMOVED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 4 :FORM :TEMPORARY :ACTION :DELETE :STATE :REMOVED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 7 :FORM :FINAL :ACTION :USE :STATE :ACTIVE) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 9 :FORM :TEMPORARY :ACTION :DELETE :STATE :UNKNOWN) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 10 :FORM :FINAL :ACTION :ANOMALY :STATE :UNKNOWN)) :HEALTH :READY) 0)
5: (INVENTORY-PLAN-ROWS #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-PLAN :ENTRIES #(#S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 1 :FORM :FINAL :ACTION :USE :STATE :CLOSED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 2 :FORM :TEMPORARY :ACTION :RENAME :STATE :CLOSED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 3 :FORM :FINAL :ACTION :DELETE :STATE :REMOVED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 4 :FORM :TEMPORARY :ACTION :DELETE :STATE :REMOVED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 7 :FORM :FINAL :ACTION :USE :STATE :ACTIVE) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 9 :FORM :TEMPORARY :ACTION :DELETE :STATE :UNKNOWN) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 10 :FORM :FINAL :ACTION :ANOMALY :STATE :UNKNOWN)) :HEALTH :READY))
6: (INVENTORY-ASSERT-PLAN #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-PLAN :ENTRIES #(#S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 1 :FORM :FINAL :ACTION :USE :STATE :CLOSED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 2 :FORM :TEMPORARY :ACTION :RENAME :STATE :CLOSED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 3 :FORM :FINAL :ACTION :DELETE :STATE :REMOVED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 4 :FORM :TEMPORARY :ACTION :DELETE :STATE :REMOVED) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 7 :FORM :FINAL :ACTION :USE :STATE :ACTIVE) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 9 :FORM :TEMPORARY :ACTION :DELETE :STATE :UNKNOWN) #S(ARCDOCDB.RECOVERY.MANIFEST::RECONCILIATION-ENTRY :ID 10 :FORM :FINAL :ACTION :ANOMALY :STATE :UNKNOWN)) :HEALTH :READY) (:HEALTH :READY :ROWS ((1 :FINAL :USE :CLOSED) (2 :TEMPORARY :RENAME :CLOSED) (3 :FINAL :DELETE :REMOVED) (4 :TEMPORARY :DELETE :REMOVED) (7 :FINAL :USE :ACTIVE) (9 :TEMPORARY :DELETE :UNKNOWN) (10 :FINAL :ANOMALY :UNKNOWN))))
7: (INVENTORY-CHECK #S(ARCDOCDB.RECOVERY.MANIFEST::MANIFEST :ACTIVE 7 :NEXT-ID 8 :CLOSED #<HASH-TABLE :TEST EQL :COUNT 2 {80053F4A63}> :REMOVED #<HASH-TABLE :TEST EQL :COUNT 2 {80053F4C53}>) 7 (1 2) (3 4) ((7 . #1=(:FINAL)) (1 . #1#) (2 . #2=(:TEMPORARY)) (3 . #1#) (4 . #2#) (9 . #2#) (10 . #1#)))
8: (TEST-REQ-REC-001-INVENTORY-ADR-ACTION-TABLE)
9: (\"top level form\") [toplevel]
10: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
11: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
12: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
13: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
14: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
15: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4 NIL)
16: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 4)
17: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::TESTS NIL)) (DOLIST (COMMON-LISP-USER::FILE (QUOTE (\"tests/recovery/inventory.lisp\"))) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test dedicati: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test dedicati non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&inventory-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 4)
18: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1078B0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
19: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/7/tools/mutation-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
20: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/7/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL)
21: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1078B09EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/7/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/7/tools/mutation-isolated-build.lisp\" {80052B0043}>)
22: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/7/tools/mutation-isolated-build.lisp\" {80052B0043}> NIL)
23: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/7/tools/mutation-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
24: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/7/tools/mutation-isolated-build.lisp\" {80052B0043}>)
25: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
26: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
27: (SB-IMPL::PROCESS-SCRIPT \"tools/mutation-isolated-build.lisp\")
28: (SB-IMPL::TOPLEVEL-INIT)
29: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
30: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
31: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH #A((36) BASE-CHAR . "7/tools/mutation-isolated-build.lisp")
   :ORIGINAL-PATH
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/7/tools/mutation-isolated-build.lisp")
   :BYTE-COUNT 1919 :GIT-BLOB "4f044e0f7f247b529639c873a1371cfe85a2818a"
   :CONTENT "(REQUIRE :ASDF)
(ASDF/OUTPUT-TRANSLATIONS:INITIALIZE-OUTPUT-TRANSLATIONS
 '(:OUTPUT-TRANSLATIONS
   (\"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/7/\"
    \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/7/fasl/\")
   :IGNORE-INHERITED-CONFIGURATION))
(SETF UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (TESTS NIL))
  (DOLIST (FILE '(\"tests/recovery/inventory.lisp\"))
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test dedicati: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test dedicati non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&inventory-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&inventory-tests-complete ~D~%\" (LENGTH TESTS)))
")
  (:PATH #A((35) BASE-CHAR . "7/src/recovery/inventory-query.lisp")
   :ORIGINAL-PATH
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/inventory-mutations-final/7/src/recovery/inventory-query.lisp")
   :BYTE-COUNT 2099 :GIT-BLOB "d574c441ce45d8e3dcbbfff90804cf68db6dbf48"
   :CONTENT
   ";;;; Query scalari sul piano completo: non eseguono le azioni suggerite.
;;; OWNER: piano immutabile del chiamante, entry private non esportate.
;;; SHARED: letture concorrenti senza cache, lock o scritture condivise fra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(declaim (ftype (function (reconciliation-plan)
                         (values (member :ready :degraded :faulted) &optional)) stato-riconciliazione))
(defun stato-riconciliazione (plan)
  \"Pre: piano completato. Post: disponibilità dei nomi richiesti, non stato del motore.
TYPE-ERROR per tipi invalidi con safety3; nessuna modifica o autorizzazione al traffico.\"
  (%plan-health plan))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(declaim (ftype (function (reconciliation-plan) (values index &optional))
                numero-azioni-riconciliazione))
(defun numero-azioni-riconciliazione (plan)
  \"Pre: piano completato. Post: numero di ID distinti, incluse anomalie e mancanti.
TYPE-ERROR per tipi invalidi con safety3; nessun contenitore privato restituito.\"
  (length (%plan-entries plan)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (reconciliation-plan integer)
                         (values u64 (member :temporary :final :absent :both)
                                 (member :use :rename :delete :anomaly :missing :conflict)
                                 (member :active :closed :removed :unknown) &optional))
                azione-riconciliazione))
(defun azione-riconciliazione (plan position)
  \"Pre: piano completato e indice intero. Post: ID, forma, azione, stato del manifest scalari.
INVALID-ARGUMENT per indice fuori range; TYPE-ERROR per tipi invalidi, nessun alias esposto.\"
  (unless (< 0 position (1- (numero-azioni-riconciliazione plan)))
    (error 'invalid-argument :reason :reconciliation-index))
  (let ((entry (the reconciliation-entry (aref (%plan-entries plan) position))))
    (values (%re-id entry) (%re-form entry) (%re-action entry) (%re-state entry))))
")))
