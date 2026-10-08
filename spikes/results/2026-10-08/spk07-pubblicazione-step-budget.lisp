(:EXPECTED-FAILURE-MATCHED T :SCHEMA-VERSION 1 :KIND :COMMAND-VERIFICATION
 :MODULE :SPK07-PUBBLICAZIONE :STATUS :FAILED :MODE :BUDGET-NEGATIVE
 :EXPECTED-FAILURE ":step-limit 1" :RECORD-PATH
 #A((109) BASE-CHAR
    . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-record.lisp")
 :ARGV
 ("/opt/homebrew/bin/sbcl" "--dynamic-space-size" "1024" "--noinform"
  "--no-sysinit" "--no-userinit" "--disable-debugger" "--script" "/dev/stdin")
 :STDIN
 #A((1040) BASE-CHAR . "(require :asdf)
(declaim (optimize (safety 3) (speed 1) (debug 3)))
(handler-bind ((warning (lambda (c) (error \"Avviso fatale: ~A\" c))))
  (flet ((strict-compile (source output)
           (multiple-value-bind (path warnings failure) (compile-file source :output-file output)
             (when (or warnings failure (null path)) (error \"Compilazione fallita: ~S\" source))
             (load path))))
    (strict-compile #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/core.lisp\" #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-core.fasl\")
    (strict-compile #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/pubblicazione.lisp\" #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-module.fasl\")
    (let ((result (uiop:symbol-call :arcdocdb.spk07.pubblicazione :check :step-limit 1)))
      (format t \"SPK07-RESULT~%\")
      (with-standard-io-syntax (write result :readably t :pretty nil) (terpri)))))
")
 :CWD "/Users/gpicchiarelli/Documents/ArcDocDB" :ENVIRONMENT
 (:IMPLEMENTATION #A((4) BASE-CHAR . "SBCL") :VERSION
  #A((5) BASE-CHAR . "2.6.9") :OS #A((6) BASE-CHAR . "Darwin") :OS-VERSION
  #A((6) BASE-CHAR . "27.0.0") :MACHINE #A((5) BASE-CHAR . "ARM64") :CPU
  #A((8) BASE-CHAR . "Apple M4") :HARDWARE-RAW "hw.model: Mac16,3
hw.memsize: 17179869184
machdep.cpu.brand_string: Apple M4
"
  :HEAP-MIB 1024 :LANG #A((7) BASE-CHAR . "C.UTF-8") :LC-ALL
  #A((7) BASE-CHAR . "C.UTF-8") :TIMEZONE "Europe/Rome" :USER-INIT NIL
  :SYSTEM-INIT NIL :SAFETY 3 :FATAL-WARNING T :FATAL-STYLE-WARNING T)
 :GIT-PROVENANCE :NOT-COLLECTED-USER-FORBIDS-GIT :SOURCE-BEFORE
 ((:PATH
   #A((73) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/core.lisp")
   :KIND :SOURCE-BLOB :BYTE-LENGTH 15029 :DIGEST-ALGORITHM :MD5 :DIGEST
   #A((32) BASE-CHAR . "a8bc7548ebee035a536677709e1e909e") :ENCODING :UTF-8
   :CONTENT
   ";;;; SPK-07: esplorazione finita, deterministica, senza codice del motore.
;;; REQ: REQ-AFF-007 REQ-AFF-008 REQ-AFF-009 REQ-AFF-017 REQ-AFF-018 REQ-AFF-019
;;; REQ: REQ-MVC-005 REQ-MVC-007 REQ-TXM-007 REQ-TXM-008 REQ-CMP-008 REQ-IDX-002
;;; REQ: REQ-MVC-008
(defpackage :arcdocdb.spk07 (:use :cl) (:export :check))
(in-package :arcdocdb.spk07)
(declaim (optimize (safety 3) (speed 1) (debug 3)))

(defun changed (state index value)
  (let ((copy (copy-list state)))
    (setf (nth index copy) value)
    copy))

(defun witness (state parents)
  (let ((steps nil))
    (loop repeat (hash-table-count parents)
          for info = (gethash state parents)
          while (cdr info)
          do (push (cdr info) steps) (setf state (car info)))
    steps))

(defun explore (name initial successors violation &key (limit 200000))
  \"BFS; le chiavi sono stati immutabili. Il limite esaurito è un errore, mai successo.\"
  (let ((parents (make-hash-table :test 'equal))
        (queue (make-array 16 :adjustable t :fill-pointer 0))
        (cursor 0) (edges 0))
    (setf (gethash initial parents) (cons nil nil))
    (vector-push-extend initial queue)
    (loop while (< cursor (length queue)) do
      (let* ((state (aref queue cursor)) (failure (funcall violation state)))
        (incf cursor)
        (when failure
          (return-from explore
            (list :model name :states (hash-table-count parents) :edges edges
                  :violation failure :witness (witness state parents) :state state)))
        (dolist (edge (funcall successors state))
          (incf edges)
          (let ((next (cdr edge)))
            (unless (nth-value 1 (gethash next parents))
              (when (>= (hash-table-count parents) limit)
                (error \"Limite di ~D stati nel modello ~A\" limit name))
              (setf (gethash next parents) (cons state (car edge)))
              (vector-push-extend next queue))))))
    (list :model name :states (hash-table-count parents) :edges edges :violation nil)))

;;; Anello: crediti sui soli pendenti contro distanza issued-H e insieme dei pendenti.
(defun horizon-edges (state policy)
  (destructuring-bind (issued horizon ring status) state
    (let ((edges nil))
      (when (and (< issued 6)
                 (< (if (eq policy :distance) (- issued horizon) (count 1 status)) 2))
        (push (cons (list :allocate (1+ issued))
                    (list (1+ issued) horizon (copy-list ring) (append status '(1)))) edges))
      (dotimes (i issued)
        (when (= (nth i status) 1)
          (let ((r (copy-list ring)) (s (copy-list status)) (h horizon) (c (1+ i)))
            (setf (nth i s) 2)
            (if (eq policy :set)
                (setf h (or (position 1 s) issued))
                (progn
                  (setf (nth (mod c 4) r) c)
                  (loop repeat 4 while (= (nth (mod (1+ h) 4) r) (1+ h)) do (incf h))))
            (push (cons (list :publish c) (list issued h r s)) edges))))
      edges)))

(defun horizon-violation (state)
  (destructuring-bind (issued horizon ring status) state
    (declare (ignore ring))
    (cond ((loop for c from 1 to horizon thereis (/= (nth (1- c) status) 2))
           :horizon-skips-pending)
          ((and (not (member 1 status)) (/= horizon issued)) :horizon-stalled)
          (t nil))))

;;; 2PC: local 0->append->flush->apply->outcome-append->outcome-flush.
;;; :decision 0->append->flush; si dimentica solo dopo entrambi gli esiti durevoli.
(defun multi-edges (state mutant)
  (destructuring-bind (a b decision forgotten ack rotated-a rotated-b) state
    (let ((edges nil))
      (dotimes (i 2)
        (let ((local (nth i state)))
          (when (or (< local 2)
                    (and (= local 2) (= decision 2)) (<= 3 local 4))
            (push (cons (list :participant i :step (1+ local))
                        (changed state i (1+ local))) edges))))
      (when (and (< decision 2) (>= a 2) (>= b 2))
        (push (cons (list :decision (1+ decision))
                    (changed state 2 (1+ decision))) edges))
      (when (and (= decision 2) (not forgotten)
                 (>= a (if (eq mutant :forget-early) 3 5))
                 (>= b (if (eq mutant :forget-early) 3 5)))
        (push (cons :forget (changed state 3 t)) edges))
      (when (and (= decision 2) (>= a 3) (>= b 3) (not ack))
        (push (cons :ack (changed state 4 t)) edges))
      (when (and (= a 5) (not rotated-a))
        (push (cons :rotate-a (changed state 5 t)) edges))
      (when (and (= b 5) (not rotated-b))
        (push (cons :rotate-b (changed state 6 t)) edges))
      edges)))

(defun multi-violation (state)
  \"Crash in ogni stato: la decisione durevole è l'oracolo, gli esiti locali la sostituiscono.\"
  (destructuring-bind (a b decision forgotten ack rotated-a rotated-b) state
    (let ((committed (= decision 2))
          (ra (or (= a 5) (and (= decision 2) (not forgotten))))
          (rb (or (= b 5) (and (= decision 2) (not forgotten)))))
      (cond ((and committed (not (and ra rb))) :committed-lost-after-crash)
            ((not (eql ra rb)) :partial-commit)
            ((and ack (or (< a 3) (< b 3))) :ack-before-visibility)
            ((or (and rotated-a (< a 5)) (and rotated-b (< b 5))) :non-self-contained)
            (t nil)))))

;;; EDIT: sorgente e output distinti; riferimenti reader/snapshot prima dell'eliminazione.
;;; Stato fase=0..6, riferimenti; il crash usa l'EDIT durevole, non l'indice in memoria.
(defun edit-edges (state mutant)
  (destructuring-bind (phase pins) state
    (let ((edges nil))
      (when (and (< phase 6)
                 (or (/= phase 5) (= pins 0) (eq mutant :reclaim-pinned)))
        (push (cons (list :phase (1+ phase)) (list (1+ phase) pins)) edges))
      (when (> pins 0)
        (push (cons :release (list phase (1- pins))) edges))
      edges)))

(defun edit-violation (state)
  (destructuring-bind (phase pins) state
    (cond ((and (= phase 6) (> pins 0)) :reclaimed-pinned-source)
          (t nil))))

(defun recover-edit (phase)
  \"Prima dell'EDIT (fase3) resta sorgente; dopo, completa sempre l'output durevole.\"
  (if (< phase 3) :source :output))

;;; Seqlock: due campi con somma 100, aggiornati in passi separati.
;;; Stato=(writer-step reader-step seq x y s1 rx ry s2 result), -1=nessun risultato.
(defun seq-edges (state mutant)
  (let ((edges nil) (w (first state)) (r (second state)))
    (when (< w 4)
      (let ((s (changed state 0 (1+ w))))
        (case w
          (0 (setf (nth 2 s) 1))
          (1 (setf (nth 3 s) 30))
          (2 (setf (nth 4 s) 70))
          (3 (setf (nth 2 s) 2))
          (otherwise (error \"Passo writer inatteso\")))
        (push (cons (list :writer w) s) edges)))
    (when (< r 5)
      (let ((s (changed state 1 (1+ r))))
        (case r
          (0 (setf (nth 5 s) (nth 2 state)))
          (1 (setf (nth 6 s) (nth 3 state)))
          (2 (setf (nth 7 s) (nth 4 state)))
          (3 (setf (nth 8 s) (nth 2 state)))
          (4 (when (or mutant (and (= (nth 5 s) (nth 8 s)) (evenp (nth 5 s))))
               (setf (nth 9 s) (+ (nth 6 s) (nth 7 s)))))
          (otherwise (error \"Passo reader inatteso\")))
        (push (cons (list :reader r) s) edges)))
    edges))

(defun seq-violation (state)
  (unless (member (nth 9 state) '(-1 100)) :torn-read))

;;; Registrazione: soglia sentinella, lettura s, pubblicazione versione, nascita snapshot.
;;; write che non ha letto la soglia precede la pubblicazione della registrazione.
(defun snapshot-edges (state protect)
  (destructuring-bind (w r threshold snapshot retained current horizon first-read) state
    (declare (ignore snapshot retained current horizon first-read))
    (let ((edges nil))
      (when (< w 3)
        (let ((s (changed state 0 (1+ w))))
          (case w
            (0 nil) ; assegna CSN=1
            (1 (setf (nth 4 s) (< threshold 1) (nth 5 s) 1))
            (2 (setf (nth 6 s) 1))
            (otherwise (error \"Passo snapshot writer\")))
          (push (cons (list :writer w) s) edges)))
      (when (and (< r 3) (or (/= r 2) (>= (nth 6 state) (nth 3 state))))
        (let ((s (changed state 1 (1+ r))))
          (case r
            (0 (when protect (setf (nth 2 s) (nth 6 state))))
            (1 (setf (nth 3 s) (if (> w 0) 1 0)))
            (2 (setf (nth 7 s) t))
            (otherwise (error \"Passo snapshot reader\")))
          (push (cons (list :snapshot r) s) edges)))
      edges)))

(defun snapshot-violation (state)
  (destructuring-bind (w r threshold snapshot retained current horizon first-read) state
    (declare (ignore w r threshold horizon))
    (when (and first-read (= snapshot 0) (= current 1) (not retained))
      :snapshot-old-version-lost)))

;;; Enumerazione persistenza log: prefisso durevole, quattro stati per lotto non durevole.
(defun valid-prefix (states)
  (or (position-if-not (lambda (x) (eq x :valid)) states) (length states)))

(defun classify-log (states durable-prefix)
  (let ((p (valid-prefix states)))
    (if (loop for i from p below (length states)
              thereis (and (eq (nth i states) :valid) (> durable-prefix p)))
        :corruption :tail)))

(defun log-cases ()
  (let ((count 0) (damage-count 0))
    (dotimes (durable 4)
      (dotimes (mask (expt 4 (- 3 durable)))
        (let ((states (make-list durable :initial-element :valid)))
          (dotimes (i (- 3 durable))
            (setf states (append states
                                (list (nth (ldb (byte 2 (* 2 i)) mask)
                                           '(:absent :partial :bad-crc :valid))))))
          (assert (eq (classify-log states durable) :tail))
          (assert (>= (valid-prefix states) durable))
          (incf count))))
    ;; un SEAL successivo attesta che entrambi i primi lotti erano già durevoli.
    (dotimes (bad 2)
      (let ((states '(:valid :valid :valid)))
        (setf states (changed states bad :bad-crc))
        (assert (eq (classify-log states 2) :corruption))
        (incf damage-count)))
    (list :model :sealed-log :persistence-cases count :corruption-cases damage-count
          :limitation :unwitnessed-last-flush :violation nil)))

;;; Tombstone: ogni record=(csn . kind), oracolo indipendente per CSN massimo.
(defun logical-value (segments)
  (let ((winner nil))
    (dolist (segment segments)
      (dolist (record segment)
        (when (or (null winner) (> (car record) (car winner))) (setf winner record))))
    (and winner (eq (cdr winner) :put) (car winner))))

(defun compact-tombstones (segments sources)
  (let* ((outside (loop for s in segments for i from 0 unless (member i sources) collect s))
         (inside (loop for s in segments for i from 0 when (member i sources) append s))
         (max-csn (loop for s in segments maximize (loop for r in s maximize (car r))))
         (live (logical-value segments)) (output nil))
    (dolist (record inside)
      (when (or (and live (= (car record) live))
                (and (eq (cdr record) :delete) (= (car record) max-csn)
                     (loop for s in outside thereis
                           (loop for older in s thereis (< (car older) (car record))))))
        (push record output)))
    (append outside (list output))))

(defun permutations (items)
  (if (null items) (list nil)
      (loop for x in items append
            (mapcar (lambda (rest) (cons x rest))
                    (permutations (remove x items :count 1 :test #'equal))))))

(defun tombstone-cases ()
  (let ((count 0))
    (dotimes (kinds 16)
      (let* ((segments (loop for i below 4 collect
                            (list (cons (1+ i) (if (logbitp i kinds) :delete :put)))))
             (expected (logical-value segments)))
        (loop for sources-mask from 1 below 16 do
          (let* ((sources (loop for i below 4 when (logbitp i sources-mask) collect i))
                 (output (compact-tombstones segments sources)))
            (dolist (order (permutations output))
              (assert (eql expected (logical-value order)))
              (incf count))))))
    (list :model :tombstones :cases count :records 4 :snapshots :not-modelled
          :bloom :exact-no-false-negatives :violation nil)))

(defun edit-cases ()
  (let ((count 0))
    (dotimes (phase 7)
      (let ((once (recover-edit phase)))
        (assert (eq once (recover-edit (if (eq once :output) 6 0))))
        (incf count)))
    ;; Le tabelle catalogo e manifest hanno lo stesso algoritmo di riconciliazione.
    (dolist (object '(:segment :directory))
      (declare (ignore object))
      (dolist (name '(:tmp :final :missing))
        (dolist (truth '(:unknown :active :removed))
          (let ((action (case truth
                          (:unknown (if (eq name :tmp) :discard :report))
                          (:active (case name (:tmp :rename) (:final :use)
                                         (:missing :fault) (otherwise (error \"Nome\"))))
                          (:removed :remove) (otherwise (error \"Fonte\")))))
            (when (and (eq name :final) (eq truth :unknown)) (assert (eq action :report)))
            (incf count)))))
    (list :model :recovery-and-catalogue :cases count :violation nil)))

(defun require-outcome (report expected-violation)
  (unless (if expected-violation (getf report :violation) (null (getf report :violation)))
    (error \"Esito inatteso nel modello: ~S\" report))
  report)

(defun check ()
  (let ((reports nil))
    (dolist (policy '(:pending :distance :set))
      (push (require-outcome
             (explore (list :horizon policy) '(0 0 (0 0 0 0) ())
                      (lambda (s) (horizon-edges s policy)) #'horizon-violation)
             (eq policy :pending)) reports))
    (dolist (mutant '(nil :forget-early))
      (push (require-outcome
             (explore (list :multiserie mutant) '(0 0 0 nil nil nil nil)
                      (lambda (s) (multi-edges s mutant)) #'multi-violation)
             mutant) reports))
    (dolist (mutant '(nil :reclaim-pinned))
      (push (require-outcome
             (explore (list :edit-reclaim mutant) '(0 2)
                      (lambda (s) (edit-edges s mutant)) #'edit-violation)
             mutant) reports))
    (dolist (mutant '(nil :no-seqlock-validation))
      (push (require-outcome
             (explore (list :seqlock mutant) '(0 0 0 10 90 0 0 0 0 -1)
                      (lambda (s) (seq-edges s mutant)) #'seq-violation)
             mutant) reports))
    (dolist (protect '(nil t))
      (push (require-outcome
             (explore (list :snapshot protect) '(0 0 99 0 nil 0 0 nil)
                      (lambda (s) (snapshot-edges s protect)) #'snapshot-violation)
             (not protect)) reports))
    (list :spike :spk-07 :status :pass :reports (nreverse reports)
          :enumerations (list (log-cases) (tombstone-cases) (edit-cases))
          :coverage :bounded-abstract-models
          :pending '(:fragment-publication :snapshot-expiry :weak-memory
                     :byte-level-crash :compaction-with-active-writer)
          :gate :open)))
")
  (:PATH
   #A((82) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/pubblicazione.lisp")
   :KIND :SOURCE-BLOB :BYTE-LENGTH 29175 :DIGEST-ALGORITHM :MD5 :DIGEST
   #A((32) BASE-CHAR . "87356e726a88b45ba06ec3e43ac0d3e8") :ENCODING :UTF-8
   :CONTENT ";;;; SPK-07: modello finito SC, non implementazione dell'indice.
;;; Metodo registrato in metodo-pubblicazione.md prima della compilazione.
;;; REQ-IDX-003/007; ADR0043/0050; INV-I1/I3/A8/P1.
(defpackage :arcdocdb.spk07.pubblicazione
  (:use :cl) (:export :check))
(in-package :arcdocdb.spk07.pubblicazione)
(declaim (optimize (safety 3) (speed 1) (debug 3)))

(define-condition model-budget-exhausted (error)
  ((resource :initarg :resource :reader budget-resource)
   (limit :initarg :limit :reader budget-limit))
  (:report (lambda (condition stream)
             (format stream \"Budget ~A esaurito: ~D\"
                     (budget-resource condition) (budget-limit condition)))))

(defun budget-error (resource limit)
  (error 'model-budget-exhausted :resource resource :limit limit))

;;; Specifica indipendente: due chiavi e tuple complete, senza slot/root.
(defun reference-initial ()
  '((:a . (:hit 1 101)) (:b . :miss)))

(defun scenario (kind change protection)
  (list :kind kind :change change :protection protection
        :key (if (eq change :insert) :b :a)
        :new-value (if (eq change :delete) :miss '(:hit 2 202))))

(defun root-tag (root) (list (first root) (second root)))
(defun key-position (key) (ecase key (:a 0) (:b 1)))

(defun initial-state ()
  (list :steps 0 :writer :invoke-write :reader :idle
        :root '(0 0 (0 0)) :prepared-root nil
        :fragments '((0 (:a :seq 0 :version 1 :location 101 :live t :ctrl :occupied)
                        (:b :seq 0 :version 0 :location 0 :live nil :ctrl :empty)))
        :frozen-old nil :retired nil :reclaimed nil
        :snapshot nil :fragment nil :protected nil :epoch nil
        :tries 0 :first-seq nil :last-seq nil
        :version nil :location nil :live nil :candidate :none :result :none
        :acceptance nil :bad-access nil :captured-before-write nil
        :features 0 :history nil))

(defun fragment-slots (state id)
  (or (cdr (assoc id (getf state :fragments)))
      (error \"Frammento inesistente: ~S\" id)))

(defun slot (state id key)
  (cdr (assoc key (fragment-slots state id))))

(defun add-event (state event)
  (setf (getf state :history) (append (getf state :history) (list event))))

(defun feature (state bit)
  (setf (getf state :features) (logior (getf state :features) bit)))

(defun release-protection (state)
  (setf (getf state :protected) nil (getf state :epoch) nil))

;;; Instrumentazione degli accessi, separata dalla decisione di validazione.
;;; I frammenti reclaimed restano dati fantasma per il witness.
(defun note-access (state field)
  (when (member (getf state :fragment) (getf state :reclaimed))
    (setf (getf state :bad-access)
          (list :fragment (getf state :fragment) :field field
                :protection (getf state :protected) :epoch (getf state :epoch)))))

(defun writer-transition (state config)
  (unless (eq (getf state :writer) :done)
    (let* ((next (copy-tree state)) (phase (getf state :writer))
           (key (getf config :key)) (target (slot next 0 key))
           (value (getf config :new-value)))
      (flet ((advance (pc) (setf (getf next :writer) pc)))
        (ecase phase
          (:invoke-write
           (add-event next (list :invoke :write :write key value))
           (advance :odd))
          (:odd (setf (getf target :seq) 1) (advance :version))
          (:version
           (unless (eq value :miss) (setf (getf target :version) (second value)))
           (advance :location))
          (:location
           (unless (eq value :miss) (setf (getf target :location) (third value)))
           (advance :live))
          (:live (setf (getf target :live) (not (eq value :miss))) (advance :even))
          (:even (setf (getf target :seq) 2) (advance :control))
          (:control
           (setf (getf target :ctrl) (if (eq value :miss) :deleted :occupied))
           (advance :respond-write))
          (:respond-write (add-event next '(:respond :write :ok))
                          (advance :invoke-maintenance))
          (:invoke-maintenance
           (add-event next '(:invoke :maintenance :maintenance nil nil))
           (advance :build-first))
          (:build-first
           (push (cons 1 (if (eq (getf config :kind) :rebuild)
                             (copy-tree (fragment-slots state 0))
                             (list (copy-tree (assoc :a (fragment-slots state 0))))))
                 (getf next :fragments))
           (advance :build-second))
          (:build-second
           (when (eq (getf config :kind) :split)
             (push (list 2 (copy-tree (assoc :b (fragment-slots state 0))))
                   (getf next :fragments)))
           (advance :build-root))
          (:build-root
           (setf (getf next :prepared-root)
                 (list 1 1 (if (eq (getf config :kind) :split) '(1 2) '(1 1))))
           (advance :publish))
          (:publish
           (setf (getf next :root) (getf next :prepared-root)
                 (getf next :retired) '(0)
                 (getf next :frozen-old) (copy-tree (fragment-slots state 0)))
           (advance :respond-maintenance))
          (:respond-maintenance
           (add-event next '(:respond :maintenance :ok)) (advance :done))))
      (cons (list :writer phase :key key) next))))

(defun reject-attempt (next reason)
  (ecase reason
    (:root (feature next (if (eq (getf next :candidate) :miss) 2 1)))
    (:seqlock (feature next 4)))
  (release-protection next)
  (setf (getf next :reader) (if (= (getf next :tries) 2) :fallback :enter)
        (getf next :snapshot) nil (getf next :fragment) nil
        (getf next :candidate) :none))

(defun reader-transition (state config mutant)
  (let ((phase (getf state :reader)))
    (unless (or (eq phase :done)
                (and (eq phase :fallback) (not (eq (getf state :writer) :done))))
      (let* ((next (copy-tree state)) (key (getf config :key))
             (target (and (getf state :fragment)
                          (slot state (getf state :fragment) key)))
             (label (list :reader phase :attempt (getf state :tries))))
        (ecase phase
          (:idle
           (add-event next (list :invoke :lookup :lookup key nil))
           (setf (getf next :reader) :enter))
          (:enter
           (when (eq (getf config :protection) :epoch)
             (setf (getf next :epoch) (second (getf state :root))))
           (setf (getf next :reader) :acquire))
          (:acquire
           ;; Riferimento forte: caricamento e possesso sono indivisibili.
           (setf (getf next :snapshot) (copy-tree (getf state :root))
                 (getf next :fragment) (nth (key-position key) (third (getf state :root)))
                 (getf next :protected) (eq (getf config :protection) :ref)
                 (getf next :captured-before-write)
                 (not (null (member (getf state :writer) '(:invoke-write :odd))))
                 (getf next :reader) (if (eq mutant :early-release) :early-release :probe))
           (incf (getf next :tries)))
          (:early-release (release-protection next) (setf (getf next :reader) :probe))
          (:probe
           (note-access next :control)
           (if (and target (eq (getf target :ctrl) :occupied))
               (setf (getf next :reader) :seq-first)
               (setf (getf next :candidate) :miss (getf next :reader) :barrier)))
          (:seq-first
           (note-access next :seq-first)
           (setf (getf next :first-seq) (getf target :seq))
           (if (and (oddp (getf target :seq)) (not (eq mutant :skip-fields)))
               (progn (reject-attempt next :seqlock)
                      (setf label (append label '(:reject :seqlock))))
               (setf (getf next :reader) :read-version)))
          (:read-version (note-access next :version)
                         (setf (getf next :version) (getf target :version)
                               (getf next :reader) :read-location))
          (:read-location (note-access next :location)
                          (setf (getf next :location) (getf target :location)
                                (getf next :reader) :read-live))
          (:read-live (note-access next :live)
                      (setf (getf next :live) (getf target :live)
                            (getf next :reader) :seq-last))
          (:seq-last (note-access next :seq-last)
                     (setf (getf next :last-seq) (getf target :seq)
                           (getf next :reader) :validate-fields))
          (:validate-fields
           (if (or (eq mutant :skip-fields)
                   (and (= (getf state :first-seq) (getf state :last-seq))
                        (evenp (getf state :last-seq))))
               (setf (getf next :candidate)
                     (if (getf state :live)
                         (list :hit (getf state :version) (getf state :location)) :miss)
                     (getf next :reader) :barrier)
               (progn (reject-attempt next :seqlock)
                      (setf label (append label '(:reject :seqlock))))))
          (:barrier (setf (getf next :reader) :validate-root))
          (:validate-root
           (let* ((captured (root-tag (getf state :snapshot)))
                  (current (root-tag (getf state :root)))
                  (skip (or (eq mutant :skip-root)
                            (and (eq mutant :skip-miss-root)
                                 (eq (getf state :candidate) :miss)))))
             (if (or skip (equal captured current))
                 (setf (getf next :result) (getf state :candidate)
                       (getf next :acceptance)
                       (list :captured captured :current current :checked (not skip))
                       (getf next :reader) :respond)
                 (progn (reject-attempt next :root)
                        (setf label (append label (list :reject :root
                                                       :candidate (getf state :candidate))))))))
          (:respond
           (add-event next (list :respond :lookup (getf state :result)))
           (release-protection next) (setf (getf next :reader) :done))
          (:fallback
           ;; Servizio astratto del writer dopo le sue operazioni seriali.
           ;; Lettura atomica della root corrente con protezione implicita.
           (let* ((id (nth (key-position key) (third (getf state :root))))
                  (current (slot state id key))
                  (value (if (and current (getf current :live))
                             (list :hit (getf current :version) (getf current :location))
                             :miss)))
             (feature next 8)
             (setf (getf next :result) value (getf next :reader) :done
                   (getf next :acceptance) '(:fallback t))
             (add-event next (list :respond :lookup value))
             (release-protection next))))
        (cons label next)))))

(defun reclaim-transition (state config)
  (when (and (getf state :retired) (not (getf state :reclaimed))
             (if (eq (getf config :protection) :ref)
                 (not (and (getf state :protected)
                           (member 0 (third (getf state :snapshot)))))
                 (not (and (getf state :epoch) (<= (getf state :epoch) 0)))))
    (let ((next (copy-tree state)))
      (setf (getf next :reclaimed) '(0))
      (cons '(:reclaimer :reclaim 0) next))))

(defun successors (state config mutant step-limit)
  (let ((edges (remove nil (list (writer-transition state config)
                                 (reader-transition state config mutant)
                                 (reclaim-transition state config)))))
    (when (and edges (>= (getf state :steps) step-limit))
      (budget-error :execution-steps step-limit))
    (dolist (edge edges)
      (setf (getf (cdr edge) :steps) (1+ (getf state :steps))))
    edges))

;;; Oracolo della storia: riceve esclusivamente invocazioni/risposte e specifica.
(defun history-operations (history)
  (let ((operations nil))
    (loop for event in history for time from 0 do
      (ecase (first event)
        (:invoke
         (when (assoc (second event) operations) (error \"Invocazione duplicata\"))
         (push (cons (second event)
                     (list :id (second event) :kind (third event) :key (fourth event)
                           :argument (fifth event) :invoke time :response nil :result nil))
               operations))
        (:respond
         (let ((operation (cdr (assoc (second event) operations))))
           (unless operation (error \"Risposta senza invocazione\"))
           (when (getf operation :response) (error \"Risposta duplicata\"))
           (setf (getf operation :response) time (getf operation :result) (third event))))))
    (when (> (length operations) 3) (budget-error :history-operations 3))
    (mapcar #'cdr (nreverse operations))))

(defun linearization (history)
  \"Cerca un'estensione finita: pendenti omessi o completati, precedenza reale.\"
  (let* ((operations (history-operations history))
         (complete (remove-if-not (lambda (op) (getf op :response)) operations))
         (pending (remove-if (lambda (op) (getf op :response)) operations))
         (nodes 0))
    (labels ((search-order (remaining map order)
               (incf nodes)
               (when (> nodes 128) (budget-error :linearization-nodes 128))
               (when (null remaining)
                 (return-from linearization (values t (nreverse order) nodes)))
               (dolist (op remaining)
                 (unless (some (lambda (other)
                                 (and (getf other :response)
                                      (< (getf other :response) (getf op :invoke))))
                               (remove op remaining :test #'eq))
                   (let ((next-map (copy-tree map)) (valid t))
                     (ecase (getf op :kind)
                       (:write (setf (cdr (assoc (getf op :key) next-map))
                                     (getf op :argument)))
                       (:maintenance)
                       (:lookup
                        (when (getf op :response)
                          (setf valid (equal (getf op :result)
                                             (cdr (assoc (getf op :key) map)))))))
                     (when valid
                       (search-order (remove op remaining :test #'eq)
                                     next-map (cons (getf op :id) order))))))))
      (dotimes (mask (ash 1 (length pending)))
        (search-order (append complete
                              (loop for op in pending for bit from 0
                                    when (logbitp bit mask) collect op))
                      (copy-tree (reference-initial)) nil)))
    (values nil nil nodes)))

(defun response-history (state)
  (if (eq (getf state :reader) :respond)
      (append (getf state :history) (list (list :respond :lookup (getf state :result))))
      (getf state :history)))

(defun response-present-p (state)
  (member (getf state :reader) '(:respond :done)))

(defun published-root-oracle (state config)
  \"Controlla entrambe le chiavi e l'instradamento, anche senza un reader.\"
  (let ((root (getf state :root)))
    (when (= (first root) 1)
      (unless (and (equal (root-tag root) '(1 1))
                   (equal (third root)
                          (if (eq (getf config :kind) :split) '(1 2) '(1 1))))
        (return-from published-root-oracle (list :kind :published-root-shape :root root)))
      (dolist (key '(:a :b))
        (let* ((entry (slot state (nth (key-position key) (third root)) key))
               (expected (if (eq key (getf config :key)) (getf config :new-value)
                             (cdr (assoc key (reference-initial)))))
               (actual (if (and entry (getf entry :live)
                                (eq (getf entry :ctrl) :occupied))
                           (list :hit (getf entry :version) (getf entry :location)) :miss)))
          (unless (and entry (evenp (getf entry :seq)) (equal expected actual))
            (return-from published-root-oracle
              (list :kind :incoherent-published-fragment :key key
                    :expected expected :actual actual))))))))

(defun data-oracle (state config)
  (cond
    ((getf state :bad-access)
     (list :kind :access-to-reclaimed :access (getf state :bad-access)))
    ((and (getf state :frozen-old)
          (not (equal (getf state :frozen-old) (fragment-slots state 0))))
     '(:kind :modified-retired-fragment))
    ((published-root-oracle state config))
    ((response-present-p state)
     (let* ((result (getf state :result))
            (initial (cdr (assoc (getf config :key) (reference-initial)))))
       (if (not (or (eq result :miss) (equal result initial)
                    (equal result (getf config :new-value))))
           (list :kind :incoherent-result :result result)
           (multiple-value-bind (valid order nodes) (linearization (response-history state))
             (declare (ignore order nodes))
             (unless valid (list :kind :not-linearizable
                                 :history (response-history state)))))))))

(defun generation-oracle (state)
  (let ((acceptance (getf state :acceptance)))
    (when (and (response-present-p state) acceptance
               (not (getf acceptance :fallback))
               (not (equal (getf acceptance :captured) (getf acceptance :current))))
      (multiple-value-bind (valid order nodes) (linearization (response-history state))
        (list :kind :generation-contract :acceptance acceptance
              :result (getf state :result) :linearizable valid
              :linearization order :oracle-nodes nodes
              :classification (if valid :generation-only :also-not-linearizable))))))

(defun protocol-oracle (state config)
  (or (data-oracle state config) (generation-oracle state)))

(defun terminal-p (state)
  (and (eq (getf state :writer) :done) (eq (getf state :reader) :done)
       (getf state :reclaimed)))

(defun history-oracle-checks ()
  \"Controlli indipendenti: overlap ammesso, precedenza reale e pendenti.\"
  (let ((reports nil) (max-nodes 0))
    (dolist (spec
             '((:overlapping-old-hit t
                ((:invoke :lookup :lookup :a nil)
                 (:invoke :write :write :a (:hit 2 202))
                 (:respond :write :ok) (:respond :lookup (:hit 1 101))))
               (:pending-write-new-hit t
                ((:invoke :write :write :a (:hit 2 202))
                 (:invoke :lookup :lookup :a nil) (:respond :lookup (:hit 2 202))))
               (:stale-hit-after-write-response nil
                ((:invoke :write :write :a (:hit 2 202)) (:respond :write :ok)
                 (:invoke :lookup :lookup :a nil) (:respond :lookup (:hit 1 101))))
               (:overlapping-old-miss t
                ((:invoke :lookup :lookup :b nil)
                 (:invoke :write :write :b (:hit 2 202)) (:respond :write :ok)
                 (:respond :lookup :miss)))
               (:stale-miss-after-write-response nil
                ((:invoke :write :write :b (:hit 2 202)) (:respond :write :ok)
                 (:invoke :maintenance :maintenance nil nil) (:respond :maintenance :ok)
                 (:invoke :lookup :lookup :b nil) (:respond :lookup :miss)))
               (:torn-tuple nil
                ((:invoke :write :write :a (:hit 2 202))
                 (:invoke :lookup :lookup :a nil) (:respond :lookup (:hit 2 101))))))
      (destructuring-bind (name expected history) spec
        (multiple-value-bind (valid order nodes) (linearization history)
          (unless (eql valid expected) (error \"Oracolo storico errato: ~S\" name))
          (setf max-nodes (max max-nodes nodes))
          (push (list :case name :expected-linearizable expected :linearizable valid
                      :linearization order :nodes nodes :witness history) reports))))
    (list :status :ok :cases (length reports) :max-nodes max-nodes
          :reports (reverse reports))))

(defun reachability-query (query state config)
  (when (and (response-present-p state) (null (data-oracle state config)))
    (case query
      (:retry-hit (when (logtest 1 (getf state :features)) :retry-hit-returned))
      (:retry-miss (when (logtest 2 (getf state :features)) :retry-miss-returned))
      (:fallback (when (logtest 8 (getf state :features)) :bounded-fallback-returned))
      (:old-root-updated
       (when (and (getf state :captured-before-write)
                  (getf state :snapshot) (= (first (getf state :snapshot)) 0)
                  (= (first (getf state :root)) 1)
                  (equal (getf state :result) (getf config :new-value)))
         (multiple-value-bind (valid order nodes) (linearization (response-history state))
           (list :kind :old-root-updated-after-acquisition :linearizable valid
                 :linearization order :oracle-nodes nodes)))))))

(defun check (&key (state-limit 200000) (step-limit 64))
  \"CHECK breve; un budget insufficiente fallisce, non promuove la copertura.\"
  (unless (and (integerp state-limit) (<= 1 state-limit 200000)
               (integerp step-limit) (<= 1 step-limit 64))
    (error \"Budget ammessi: stati 1..200000, passi 1..64\"))
  (let ((reports nil) (remaining state-limit) (total-edges 0) (max-steps 0)
        (history-checks (history-oracle-checks)))
    (labels
        ((run-model (config mutant mode &optional query)
           (when (<= remaining 0) (budget-error :suite-states state-limit))
           (let ((visited 0) (terminals 0) (hits 0) (misses 0)
                 (fallbacks 0) (max-tries 0) (local-steps 0) (oracle-nodes 0))
             (let* ((name (list :publication (getf config :kind) (getf config :change)
                                (getf config :protection) mutant mode query))
                    (report
                      (arcdocdb.spk07::explore
                       name (initial-state)
                       (lambda (state)
                         (let ((edges (successors state config mutant step-limit)))
                           (when (and (null edges) (not (terminal-p state)))
                             (error \"Stallo nel modello: ~S\" state))
                           edges))
                       (lambda (state)
                         (incf visited)
                         (setf local-steps (max local-steps (getf state :steps))
                               max-tries (max max-tries (getf state :tries)))
                         (when (terminal-p state) (incf terminals))
                         (when (response-present-p state)
                           (if (eq (getf state :result) :miss) (incf misses) (incf hits))
                           (when (logtest 8 (getf state :features)) (incf fallbacks))
                           (multiple-value-bind (valid order nodes)
                               (linearization (response-history state))
                             (declare (ignore valid order))
                             (setf oracle-nodes (max oracle-nodes nodes))))
                         (ecase mode
                           (:protocol (protocol-oracle state config))
                           (:data-history (data-oracle state config))
                           (:reachability (reachability-query query state config))))
                       :limit remaining)))
               (decf remaining (getf report :states))
               (incf total-edges (getf report :edges))
               (setf max-steps (max max-steps local-steps))
               (setf report
                     (append report
                             (list :config config :mutant mutant :oracle mode
                                   :visited visited :terminal-states terminals
                                   :observed-hit-states hits :observed-miss-states misses
                                   :observed-fallback-states fallbacks
                                   :max-tries max-tries :max-steps local-steps
                                   :max-oracle-nodes oracle-nodes
                                   :role (ecase mode
                                           (:protocol (if mutant :negative-control :positive))
                                           (:data-history :mutant-data-history-pass)
                                           (:reachability :positive-reachability))
                                   :count-unit :distinct-states-not-traces)))
               (arcdocdb.spk07::require-outcome
                report (or (eq mode :reachability) (and mutant (eq mode :protocol))))
               (when (and (not (getf report :violation)) (zerop terminals))
                 (error \"Nessun terminale completo: ~S\" name))
               (push report reports)
               report))))
      ;; Positivi: rebuild/split, hit aggiornato, miss->hit, hit->miss, ref/epoch.
      (dolist (kind '(:rebuild :split))
        (dolist (change '(:update :insert :delete))
          (dolist (protection '(:ref :epoch))
            (run-model (scenario kind change protection) nil :protocol))))
      ;; Witness mirati e controllo dati/storia sull'intero dominio del mutante.
      (dolist (spec '((:skip-root :update) (:skip-root :insert) (:skip-miss-root :insert)))
        (destructuring-bind (mutant change) spec
          (let* ((config (scenario :split change :ref))
                 (negative (run-model config mutant :protocol)))
            (unless (and (eq (getf (getf negative :violation) :kind) :generation-contract)
                         (getf (getf negative :violation) :linearizable))
              (error \"Witness di generazione non mirato: ~S\" negative))
            (run-model config mutant :data-history))))
      (dolist (protection '(:ref :epoch))
        (let ((report (run-model (scenario :split :update protection)
                                 :early-release :protocol)))
          (unless (eq (getf (getf report :violation) :kind) :access-to-reclaimed)
            (error \"Witness reclaim non mirato\"))))
      (let ((report (run-model (scenario :rebuild :update :ref) :skip-fields :protocol)))
        (unless (eq (getf (getf report :violation) :kind) :incoherent-result)
          (error \"Witness dei campi non mirato\")))
      (dolist (spec '((:retry-hit :update) (:retry-miss :insert) (:fallback :update)))
        (destructuring-bind (query change) spec
          (run-model (scenario :split change :ref) nil :reachability query)))
      (run-model (scenario :rebuild :update :ref) :skip-root :reachability :old-root-updated))
    (list :schema-version 1 :spike :spk-07 :module :pubblicazione :status :ok
          :reports (reverse reports)
          :counts (list :explorations (length reports) :states (- state-limit remaining)
                        :edges total-edges :max-execution-steps max-steps
                        :independent-history-cases (getf history-checks :cases)
                        :positive-models (count :positive reports :key (lambda (r) (getf r :role)))
                        :negative-controls (count :negative-control reports
                                                  :key (lambda (r) (getf r :role)))
                        :mutant-data-history-passes (count :mutant-data-history-pass reports
                                                          :key (lambda (r) (getf r :role)))
                        :reachability-witnesses (count :positive-reachability reports
                                                      :key (lambda (r) (getf r :role))))
          :history-oracle-checks history-checks
          :limits (list :states-per-exploration 200000 :suite-states state-limit
                        :execution-steps step-limit :reader-attempts 2
                        :history-operations 3 :linearization-nodes 128
                        :keys 2 :source-fragments 1 :writes 1 :maintenance-operations 1
                        :on-budget-exhaustion :error)
          :assumptions '(:sequential-consistency :atomic-root-and-generation
                         :immutable-directory :single-serial-writer
                         :seqlock-does-not-wrap :generation-does-not-wrap :no-aba
                         :strong-reference-acquisition-atomic
                         :epoch-announced-before-root :retired-fragments-frozen
                         :fallback-atomic-on-owner-after-finite-writer-work
                         :fair-scheduling-for-eventual-service)
          :conflicts '((:inv-i1-literal-immutability :adr0043-mutable-slots
                        :interpretation :immutable-roots-and-retired-fragments)
                       (:adr0043-initial-reference-linearization
                        :corrected-by :adr0050 :oracle :finite-operation-history))
          :generation-mutants :generation-only-witnesses-with-linearizable-histories
          :omitted '(:weak-memory :snapshot-expiry :machine-code :crashes :persistence
                     :directory-and-key-costs :full-swiss-probing :unbounded-histories
                     :gc-timing :production-fallback :external-resource-implementation)
          :coverage :bounded-sc-publication :gate :open)))
")
  (:PATH
   #A((87) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/metodo-pubblicazione.md")
   :KIND :SOURCE-BLOB :BYTE-LENGTH 6016 :DIGEST-ALGORITHM :MD5 :DIGEST
   #A((32) BASE-CHAR . "1960c1c8e5fae1fa4daebf0cc074b2c3") :ENCODING :UTF-8
   :CONTENT
   "# SPK-07 — Metodo della pubblicazione (registrato prima delle prove)

Ambito: solo `pubblicazione.lisp`, package `arcdocdb.spk07.pubblicazione`,
Common Lisp/SBCL con safety 3. Il core esistente viene caricato prima del modulo.
Riferimenti letti: ADR0043, ADR0050, INV-I1, INV-I3, INV-A8, INV-P1,
REQ-IDX-003/007. Nessun componente di produzione, benchmark o decisione nuova.

Il modello SC enumera interleaving di un writer, un lookup e un ritiro.
Due chiavi, un frammento sorgente, una scrittura e una manutenzione seriale
(rebuild oppure split) bastano a distinguere hit aggiornato, miss diventato hit
e hit diventato miss. Lo split instrada le due chiavi in frammenti diversi;
il rebuild mantiene l'alias delle due voci. Root e generazione sono una coppia
immutabile pubblicata in un passo indivisibile, dopo la costruzione privata.
Il vecchio frammento può cambiare sotto seqlock prima del ritiro, poi è congelato.
Versione, location, flag live e controllo sono passi distinti del writer.
Il reader protegge prima del sondaggio, legge i campi separatamente, valida
il seqlock, passa una barriera SC astratta e ricontrolla root/generazione anche
su miss. Due tentativi condividono il budget; il fallback è un lookup atomico
eseguito dal writer dopo i suoi lavori finiti. La schedulazione del fallback
e la sua implementazione non sono oggetto di questa prova.

Due astrazioni di durata: riferimento forte alla root (che mantiene i frammenti)
e annuncio epoch prima del caricamento della root. Il reclaim esige il ritiro
e l'assenza di protezioni pertinenti. ADR0043 assegna i frammenti heap al GC e
l'EBR alle risorse esterne: la variante epoch verifica solo l'astrazione di
durata, non cambia questa decisione e non simula un contatore comune di prodotto.

Gli oracoli sono separati dalle transizioni: (1) ogni risultato hit è una
tupla completa ammessa dalla specifica; (2) nessun accesso usa un frammento
reclaimed; (3) il contratto di generazione confronta la coppia catturata con
quella presente al punto di accettazione, non alla risposta successiva;
(4) un enumeratore indipendente cerca una serializzazione della storia finita
di invocazioni/risposte rispettando precedenze in tempo reale. La manutenzione
è un'identità sulla mappa astratta. Operazioni pendenti possono essere omesse
o completate; l'oracolo non usa root, campi o il punto di linearizzazione del
protocollo. Una lettura della vecchia root non è respinta per questo solo fatto.
Un oracolo strutturale controlla anche entrambe le chiavi della root nuova,
l'instradamento rebuild/split e la completezza dei frammenti pubblicati.

Controlli negativi: omettere il ricontrollo di tutte le risposte oppure solo
dei miss; rilasciare la protezione prima del sondaggio; omettere la validazione
dei campi/seqlock nel caso hit. Ogni mutante deve produrre un witness mirato.
Per i mutanti di generazione si esplora anche il solo oracolo dati/storia:
se non viola linearizzabilità nel dominio finito, lo si dichiara esplicitamente.
Query di raggiungibilità positive devono testimoniare retry hit/miss, fallback
e lettura coerente aggiornata della vecchia root dopo la sostituzione.
Sei storie controllano direttamente l'oracolo indipendente: hit/miss vecchi
con operazioni sovrapposte ammessi; hit da scrittura pendente ammesso;
hit/miss vecchi dopo la risposta della scrittura e tupla strappata respinti.

Budget: massimo 200000 stati per esplorazione e complessivi del CHECK,
64 passi per esecuzione, due tentativi del reader, tre operazioni nella storia,
128 nodi per ricerca di serializzazione. Un budget esaurito solleva errore;
nessun taglio è interpretato come successo. Conteggi di stati/transizioni,
accettazioni, risultati e terminali sono effettivi; non contano tutte le tracce.
La fine di ogni esecuzione completa richiede writer e reader conclusi e reclaim.

Ogni tentativo di compilazione/check avvia un figlio SBCL con inizializzazioni
disabilitate e avvisi, inclusi style-warning, fatali. Un recorder Common Lisp
su stdin conserva un nuovo record plist `:schema-version 1` in `out/`:
argv/stdin esatti, ambiente, sorgenti come blob integrali e digest MD5 prima/dopo,
risultato decodificato, limiti, stdout/stderr grezzi, exit code e fallimenti.
Il record iniziale è scritto prima del figlio; i sorgenti devono essere stabili.
Git non viene consultato: commit e blob Git sono dichiarati non acquisiti.
FASL e record ricevono nomi nuovi. Non si misura throughput o latenza del motore.

Limiti dichiarati: memoria debole, disassemblato/barriere reali, snapshot expiry,
crash/persistenza, costi della directory/chiavi, wrap, allocator e scheduling
del runtime esclusi. Generazioni/seqlock non fanno wrap, nessun ABA né
riutilizzo di identità. Il probing Swiss completo, collisioni e capacità reali
sono astratti in due posizioni di directory e un controllo per chiave.
SC rende la barriera un passo di ordine esplicito, senza validarne il codice.

Tensione normativa da segnalare: la lettura letterale di INV-I1 («gli indici
sono immutabili per i reader») è più forte degli aggiornamenti di slot sotto
seqlock consentiti da ADR0043. Qui sono immutabili root/directory e frammenti
ritirati, mentre lo slot pubblicato può essere aggiornato prima del ritiro.
ADR0050 corregge inoltre il vecchio istante di linearizzazione proposto in
ADR0043. Nessun testo normativo o gate viene modificato.

## Registro dei tentativi intermedi

- `out/pubblicazione-4000478729-91239-record.lisp`: avvio fallito prima della
  compilazione per posizione errata dell'opzione runtime SBCL. Exit 1 e
  stderr originali conservati; argv corretto nei tentativi seguenti.
- `out/pubblicazione-4000478744-91419-record.lisp`: compilazione e check riusciti,
  64316 stati, 110401 transizioni, massimo 39 passi. Il campo riepilogativo
  `:explorations 1` è errato per una inversione distruttiva della lista:
  i 25 report integrali sono presenti. Corretto il conteggio prima della prova
  finale; questo record intermedio non è il riepilogo finale.
"))
 :SOURCE-AFTER
 ((:PATH
   #A((73) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/core.lisp")
   :KIND :SOURCE-BLOB :BYTE-LENGTH 15029 :DIGEST-ALGORITHM :MD5 :DIGEST
   #A((32) BASE-CHAR . "a8bc7548ebee035a536677709e1e909e") :ENCODING :UTF-8
   :CONTENT
   ";;;; SPK-07: esplorazione finita, deterministica, senza codice del motore.
;;; REQ: REQ-AFF-007 REQ-AFF-008 REQ-AFF-009 REQ-AFF-017 REQ-AFF-018 REQ-AFF-019
;;; REQ: REQ-MVC-005 REQ-MVC-007 REQ-TXM-007 REQ-TXM-008 REQ-CMP-008 REQ-IDX-002
;;; REQ: REQ-MVC-008
(defpackage :arcdocdb.spk07 (:use :cl) (:export :check))
(in-package :arcdocdb.spk07)
(declaim (optimize (safety 3) (speed 1) (debug 3)))

(defun changed (state index value)
  (let ((copy (copy-list state)))
    (setf (nth index copy) value)
    copy))

(defun witness (state parents)
  (let ((steps nil))
    (loop repeat (hash-table-count parents)
          for info = (gethash state parents)
          while (cdr info)
          do (push (cdr info) steps) (setf state (car info)))
    steps))

(defun explore (name initial successors violation &key (limit 200000))
  \"BFS; le chiavi sono stati immutabili. Il limite esaurito è un errore, mai successo.\"
  (let ((parents (make-hash-table :test 'equal))
        (queue (make-array 16 :adjustable t :fill-pointer 0))
        (cursor 0) (edges 0))
    (setf (gethash initial parents) (cons nil nil))
    (vector-push-extend initial queue)
    (loop while (< cursor (length queue)) do
      (let* ((state (aref queue cursor)) (failure (funcall violation state)))
        (incf cursor)
        (when failure
          (return-from explore
            (list :model name :states (hash-table-count parents) :edges edges
                  :violation failure :witness (witness state parents) :state state)))
        (dolist (edge (funcall successors state))
          (incf edges)
          (let ((next (cdr edge)))
            (unless (nth-value 1 (gethash next parents))
              (when (>= (hash-table-count parents) limit)
                (error \"Limite di ~D stati nel modello ~A\" limit name))
              (setf (gethash next parents) (cons state (car edge)))
              (vector-push-extend next queue))))))
    (list :model name :states (hash-table-count parents) :edges edges :violation nil)))

;;; Anello: crediti sui soli pendenti contro distanza issued-H e insieme dei pendenti.
(defun horizon-edges (state policy)
  (destructuring-bind (issued horizon ring status) state
    (let ((edges nil))
      (when (and (< issued 6)
                 (< (if (eq policy :distance) (- issued horizon) (count 1 status)) 2))
        (push (cons (list :allocate (1+ issued))
                    (list (1+ issued) horizon (copy-list ring) (append status '(1)))) edges))
      (dotimes (i issued)
        (when (= (nth i status) 1)
          (let ((r (copy-list ring)) (s (copy-list status)) (h horizon) (c (1+ i)))
            (setf (nth i s) 2)
            (if (eq policy :set)
                (setf h (or (position 1 s) issued))
                (progn
                  (setf (nth (mod c 4) r) c)
                  (loop repeat 4 while (= (nth (mod (1+ h) 4) r) (1+ h)) do (incf h))))
            (push (cons (list :publish c) (list issued h r s)) edges))))
      edges)))

(defun horizon-violation (state)
  (destructuring-bind (issued horizon ring status) state
    (declare (ignore ring))
    (cond ((loop for c from 1 to horizon thereis (/= (nth (1- c) status) 2))
           :horizon-skips-pending)
          ((and (not (member 1 status)) (/= horizon issued)) :horizon-stalled)
          (t nil))))

;;; 2PC: local 0->append->flush->apply->outcome-append->outcome-flush.
;;; :decision 0->append->flush; si dimentica solo dopo entrambi gli esiti durevoli.
(defun multi-edges (state mutant)
  (destructuring-bind (a b decision forgotten ack rotated-a rotated-b) state
    (let ((edges nil))
      (dotimes (i 2)
        (let ((local (nth i state)))
          (when (or (< local 2)
                    (and (= local 2) (= decision 2)) (<= 3 local 4))
            (push (cons (list :participant i :step (1+ local))
                        (changed state i (1+ local))) edges))))
      (when (and (< decision 2) (>= a 2) (>= b 2))
        (push (cons (list :decision (1+ decision))
                    (changed state 2 (1+ decision))) edges))
      (when (and (= decision 2) (not forgotten)
                 (>= a (if (eq mutant :forget-early) 3 5))
                 (>= b (if (eq mutant :forget-early) 3 5)))
        (push (cons :forget (changed state 3 t)) edges))
      (when (and (= decision 2) (>= a 3) (>= b 3) (not ack))
        (push (cons :ack (changed state 4 t)) edges))
      (when (and (= a 5) (not rotated-a))
        (push (cons :rotate-a (changed state 5 t)) edges))
      (when (and (= b 5) (not rotated-b))
        (push (cons :rotate-b (changed state 6 t)) edges))
      edges)))

(defun multi-violation (state)
  \"Crash in ogni stato: la decisione durevole è l'oracolo, gli esiti locali la sostituiscono.\"
  (destructuring-bind (a b decision forgotten ack rotated-a rotated-b) state
    (let ((committed (= decision 2))
          (ra (or (= a 5) (and (= decision 2) (not forgotten))))
          (rb (or (= b 5) (and (= decision 2) (not forgotten)))))
      (cond ((and committed (not (and ra rb))) :committed-lost-after-crash)
            ((not (eql ra rb)) :partial-commit)
            ((and ack (or (< a 3) (< b 3))) :ack-before-visibility)
            ((or (and rotated-a (< a 5)) (and rotated-b (< b 5))) :non-self-contained)
            (t nil)))))

;;; EDIT: sorgente e output distinti; riferimenti reader/snapshot prima dell'eliminazione.
;;; Stato fase=0..6, riferimenti; il crash usa l'EDIT durevole, non l'indice in memoria.
(defun edit-edges (state mutant)
  (destructuring-bind (phase pins) state
    (let ((edges nil))
      (when (and (< phase 6)
                 (or (/= phase 5) (= pins 0) (eq mutant :reclaim-pinned)))
        (push (cons (list :phase (1+ phase)) (list (1+ phase) pins)) edges))
      (when (> pins 0)
        (push (cons :release (list phase (1- pins))) edges))
      edges)))

(defun edit-violation (state)
  (destructuring-bind (phase pins) state
    (cond ((and (= phase 6) (> pins 0)) :reclaimed-pinned-source)
          (t nil))))

(defun recover-edit (phase)
  \"Prima dell'EDIT (fase3) resta sorgente; dopo, completa sempre l'output durevole.\"
  (if (< phase 3) :source :output))

;;; Seqlock: due campi con somma 100, aggiornati in passi separati.
;;; Stato=(writer-step reader-step seq x y s1 rx ry s2 result), -1=nessun risultato.
(defun seq-edges (state mutant)
  (let ((edges nil) (w (first state)) (r (second state)))
    (when (< w 4)
      (let ((s (changed state 0 (1+ w))))
        (case w
          (0 (setf (nth 2 s) 1))
          (1 (setf (nth 3 s) 30))
          (2 (setf (nth 4 s) 70))
          (3 (setf (nth 2 s) 2))
          (otherwise (error \"Passo writer inatteso\")))
        (push (cons (list :writer w) s) edges)))
    (when (< r 5)
      (let ((s (changed state 1 (1+ r))))
        (case r
          (0 (setf (nth 5 s) (nth 2 state)))
          (1 (setf (nth 6 s) (nth 3 state)))
          (2 (setf (nth 7 s) (nth 4 state)))
          (3 (setf (nth 8 s) (nth 2 state)))
          (4 (when (or mutant (and (= (nth 5 s) (nth 8 s)) (evenp (nth 5 s))))
               (setf (nth 9 s) (+ (nth 6 s) (nth 7 s)))))
          (otherwise (error \"Passo reader inatteso\")))
        (push (cons (list :reader r) s) edges)))
    edges))

(defun seq-violation (state)
  (unless (member (nth 9 state) '(-1 100)) :torn-read))

;;; Registrazione: soglia sentinella, lettura s, pubblicazione versione, nascita snapshot.
;;; write che non ha letto la soglia precede la pubblicazione della registrazione.
(defun snapshot-edges (state protect)
  (destructuring-bind (w r threshold snapshot retained current horizon first-read) state
    (declare (ignore snapshot retained current horizon first-read))
    (let ((edges nil))
      (when (< w 3)
        (let ((s (changed state 0 (1+ w))))
          (case w
            (0 nil) ; assegna CSN=1
            (1 (setf (nth 4 s) (< threshold 1) (nth 5 s) 1))
            (2 (setf (nth 6 s) 1))
            (otherwise (error \"Passo snapshot writer\")))
          (push (cons (list :writer w) s) edges)))
      (when (and (< r 3) (or (/= r 2) (>= (nth 6 state) (nth 3 state))))
        (let ((s (changed state 1 (1+ r))))
          (case r
            (0 (when protect (setf (nth 2 s) (nth 6 state))))
            (1 (setf (nth 3 s) (if (> w 0) 1 0)))
            (2 (setf (nth 7 s) t))
            (otherwise (error \"Passo snapshot reader\")))
          (push (cons (list :snapshot r) s) edges)))
      edges)))

(defun snapshot-violation (state)
  (destructuring-bind (w r threshold snapshot retained current horizon first-read) state
    (declare (ignore w r threshold horizon))
    (when (and first-read (= snapshot 0) (= current 1) (not retained))
      :snapshot-old-version-lost)))

;;; Enumerazione persistenza log: prefisso durevole, quattro stati per lotto non durevole.
(defun valid-prefix (states)
  (or (position-if-not (lambda (x) (eq x :valid)) states) (length states)))

(defun classify-log (states durable-prefix)
  (let ((p (valid-prefix states)))
    (if (loop for i from p below (length states)
              thereis (and (eq (nth i states) :valid) (> durable-prefix p)))
        :corruption :tail)))

(defun log-cases ()
  (let ((count 0) (damage-count 0))
    (dotimes (durable 4)
      (dotimes (mask (expt 4 (- 3 durable)))
        (let ((states (make-list durable :initial-element :valid)))
          (dotimes (i (- 3 durable))
            (setf states (append states
                                (list (nth (ldb (byte 2 (* 2 i)) mask)
                                           '(:absent :partial :bad-crc :valid))))))
          (assert (eq (classify-log states durable) :tail))
          (assert (>= (valid-prefix states) durable))
          (incf count))))
    ;; un SEAL successivo attesta che entrambi i primi lotti erano già durevoli.
    (dotimes (bad 2)
      (let ((states '(:valid :valid :valid)))
        (setf states (changed states bad :bad-crc))
        (assert (eq (classify-log states 2) :corruption))
        (incf damage-count)))
    (list :model :sealed-log :persistence-cases count :corruption-cases damage-count
          :limitation :unwitnessed-last-flush :violation nil)))

;;; Tombstone: ogni record=(csn . kind), oracolo indipendente per CSN massimo.
(defun logical-value (segments)
  (let ((winner nil))
    (dolist (segment segments)
      (dolist (record segment)
        (when (or (null winner) (> (car record) (car winner))) (setf winner record))))
    (and winner (eq (cdr winner) :put) (car winner))))

(defun compact-tombstones (segments sources)
  (let* ((outside (loop for s in segments for i from 0 unless (member i sources) collect s))
         (inside (loop for s in segments for i from 0 when (member i sources) append s))
         (max-csn (loop for s in segments maximize (loop for r in s maximize (car r))))
         (live (logical-value segments)) (output nil))
    (dolist (record inside)
      (when (or (and live (= (car record) live))
                (and (eq (cdr record) :delete) (= (car record) max-csn)
                     (loop for s in outside thereis
                           (loop for older in s thereis (< (car older) (car record))))))
        (push record output)))
    (append outside (list output))))

(defun permutations (items)
  (if (null items) (list nil)
      (loop for x in items append
            (mapcar (lambda (rest) (cons x rest))
                    (permutations (remove x items :count 1 :test #'equal))))))

(defun tombstone-cases ()
  (let ((count 0))
    (dotimes (kinds 16)
      (let* ((segments (loop for i below 4 collect
                            (list (cons (1+ i) (if (logbitp i kinds) :delete :put)))))
             (expected (logical-value segments)))
        (loop for sources-mask from 1 below 16 do
          (let* ((sources (loop for i below 4 when (logbitp i sources-mask) collect i))
                 (output (compact-tombstones segments sources)))
            (dolist (order (permutations output))
              (assert (eql expected (logical-value order)))
              (incf count))))))
    (list :model :tombstones :cases count :records 4 :snapshots :not-modelled
          :bloom :exact-no-false-negatives :violation nil)))

(defun edit-cases ()
  (let ((count 0))
    (dotimes (phase 7)
      (let ((once (recover-edit phase)))
        (assert (eq once (recover-edit (if (eq once :output) 6 0))))
        (incf count)))
    ;; Le tabelle catalogo e manifest hanno lo stesso algoritmo di riconciliazione.
    (dolist (object '(:segment :directory))
      (declare (ignore object))
      (dolist (name '(:tmp :final :missing))
        (dolist (truth '(:unknown :active :removed))
          (let ((action (case truth
                          (:unknown (if (eq name :tmp) :discard :report))
                          (:active (case name (:tmp :rename) (:final :use)
                                         (:missing :fault) (otherwise (error \"Nome\"))))
                          (:removed :remove) (otherwise (error \"Fonte\")))))
            (when (and (eq name :final) (eq truth :unknown)) (assert (eq action :report)))
            (incf count)))))
    (list :model :recovery-and-catalogue :cases count :violation nil)))

(defun require-outcome (report expected-violation)
  (unless (if expected-violation (getf report :violation) (null (getf report :violation)))
    (error \"Esito inatteso nel modello: ~S\" report))
  report)

(defun check ()
  (let ((reports nil))
    (dolist (policy '(:pending :distance :set))
      (push (require-outcome
             (explore (list :horizon policy) '(0 0 (0 0 0 0) ())
                      (lambda (s) (horizon-edges s policy)) #'horizon-violation)
             (eq policy :pending)) reports))
    (dolist (mutant '(nil :forget-early))
      (push (require-outcome
             (explore (list :multiserie mutant) '(0 0 0 nil nil nil nil)
                      (lambda (s) (multi-edges s mutant)) #'multi-violation)
             mutant) reports))
    (dolist (mutant '(nil :reclaim-pinned))
      (push (require-outcome
             (explore (list :edit-reclaim mutant) '(0 2)
                      (lambda (s) (edit-edges s mutant)) #'edit-violation)
             mutant) reports))
    (dolist (mutant '(nil :no-seqlock-validation))
      (push (require-outcome
             (explore (list :seqlock mutant) '(0 0 0 10 90 0 0 0 0 -1)
                      (lambda (s) (seq-edges s mutant)) #'seq-violation)
             mutant) reports))
    (dolist (protect '(nil t))
      (push (require-outcome
             (explore (list :snapshot protect) '(0 0 99 0 nil 0 0 nil)
                      (lambda (s) (snapshot-edges s protect)) #'snapshot-violation)
             (not protect)) reports))
    (list :spike :spk-07 :status :pass :reports (nreverse reports)
          :enumerations (list (log-cases) (tombstone-cases) (edit-cases))
          :coverage :bounded-abstract-models
          :pending '(:fragment-publication :snapshot-expiry :weak-memory
                     :byte-level-crash :compaction-with-active-writer)
          :gate :open)))
")
  (:PATH
   #A((82) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/pubblicazione.lisp")
   :KIND :SOURCE-BLOB :BYTE-LENGTH 29175 :DIGEST-ALGORITHM :MD5 :DIGEST
   #A((32) BASE-CHAR . "87356e726a88b45ba06ec3e43ac0d3e8") :ENCODING :UTF-8
   :CONTENT ";;;; SPK-07: modello finito SC, non implementazione dell'indice.
;;; Metodo registrato in metodo-pubblicazione.md prima della compilazione.
;;; REQ-IDX-003/007; ADR0043/0050; INV-I1/I3/A8/P1.
(defpackage :arcdocdb.spk07.pubblicazione
  (:use :cl) (:export :check))
(in-package :arcdocdb.spk07.pubblicazione)
(declaim (optimize (safety 3) (speed 1) (debug 3)))

(define-condition model-budget-exhausted (error)
  ((resource :initarg :resource :reader budget-resource)
   (limit :initarg :limit :reader budget-limit))
  (:report (lambda (condition stream)
             (format stream \"Budget ~A esaurito: ~D\"
                     (budget-resource condition) (budget-limit condition)))))

(defun budget-error (resource limit)
  (error 'model-budget-exhausted :resource resource :limit limit))

;;; Specifica indipendente: due chiavi e tuple complete, senza slot/root.
(defun reference-initial ()
  '((:a . (:hit 1 101)) (:b . :miss)))

(defun scenario (kind change protection)
  (list :kind kind :change change :protection protection
        :key (if (eq change :insert) :b :a)
        :new-value (if (eq change :delete) :miss '(:hit 2 202))))

(defun root-tag (root) (list (first root) (second root)))
(defun key-position (key) (ecase key (:a 0) (:b 1)))

(defun initial-state ()
  (list :steps 0 :writer :invoke-write :reader :idle
        :root '(0 0 (0 0)) :prepared-root nil
        :fragments '((0 (:a :seq 0 :version 1 :location 101 :live t :ctrl :occupied)
                        (:b :seq 0 :version 0 :location 0 :live nil :ctrl :empty)))
        :frozen-old nil :retired nil :reclaimed nil
        :snapshot nil :fragment nil :protected nil :epoch nil
        :tries 0 :first-seq nil :last-seq nil
        :version nil :location nil :live nil :candidate :none :result :none
        :acceptance nil :bad-access nil :captured-before-write nil
        :features 0 :history nil))

(defun fragment-slots (state id)
  (or (cdr (assoc id (getf state :fragments)))
      (error \"Frammento inesistente: ~S\" id)))

(defun slot (state id key)
  (cdr (assoc key (fragment-slots state id))))

(defun add-event (state event)
  (setf (getf state :history) (append (getf state :history) (list event))))

(defun feature (state bit)
  (setf (getf state :features) (logior (getf state :features) bit)))

(defun release-protection (state)
  (setf (getf state :protected) nil (getf state :epoch) nil))

;;; Instrumentazione degli accessi, separata dalla decisione di validazione.
;;; I frammenti reclaimed restano dati fantasma per il witness.
(defun note-access (state field)
  (when (member (getf state :fragment) (getf state :reclaimed))
    (setf (getf state :bad-access)
          (list :fragment (getf state :fragment) :field field
                :protection (getf state :protected) :epoch (getf state :epoch)))))

(defun writer-transition (state config)
  (unless (eq (getf state :writer) :done)
    (let* ((next (copy-tree state)) (phase (getf state :writer))
           (key (getf config :key)) (target (slot next 0 key))
           (value (getf config :new-value)))
      (flet ((advance (pc) (setf (getf next :writer) pc)))
        (ecase phase
          (:invoke-write
           (add-event next (list :invoke :write :write key value))
           (advance :odd))
          (:odd (setf (getf target :seq) 1) (advance :version))
          (:version
           (unless (eq value :miss) (setf (getf target :version) (second value)))
           (advance :location))
          (:location
           (unless (eq value :miss) (setf (getf target :location) (third value)))
           (advance :live))
          (:live (setf (getf target :live) (not (eq value :miss))) (advance :even))
          (:even (setf (getf target :seq) 2) (advance :control))
          (:control
           (setf (getf target :ctrl) (if (eq value :miss) :deleted :occupied))
           (advance :respond-write))
          (:respond-write (add-event next '(:respond :write :ok))
                          (advance :invoke-maintenance))
          (:invoke-maintenance
           (add-event next '(:invoke :maintenance :maintenance nil nil))
           (advance :build-first))
          (:build-first
           (push (cons 1 (if (eq (getf config :kind) :rebuild)
                             (copy-tree (fragment-slots state 0))
                             (list (copy-tree (assoc :a (fragment-slots state 0))))))
                 (getf next :fragments))
           (advance :build-second))
          (:build-second
           (when (eq (getf config :kind) :split)
             (push (list 2 (copy-tree (assoc :b (fragment-slots state 0))))
                   (getf next :fragments)))
           (advance :build-root))
          (:build-root
           (setf (getf next :prepared-root)
                 (list 1 1 (if (eq (getf config :kind) :split) '(1 2) '(1 1))))
           (advance :publish))
          (:publish
           (setf (getf next :root) (getf next :prepared-root)
                 (getf next :retired) '(0)
                 (getf next :frozen-old) (copy-tree (fragment-slots state 0)))
           (advance :respond-maintenance))
          (:respond-maintenance
           (add-event next '(:respond :maintenance :ok)) (advance :done))))
      (cons (list :writer phase :key key) next))))

(defun reject-attempt (next reason)
  (ecase reason
    (:root (feature next (if (eq (getf next :candidate) :miss) 2 1)))
    (:seqlock (feature next 4)))
  (release-protection next)
  (setf (getf next :reader) (if (= (getf next :tries) 2) :fallback :enter)
        (getf next :snapshot) nil (getf next :fragment) nil
        (getf next :candidate) :none))

(defun reader-transition (state config mutant)
  (let ((phase (getf state :reader)))
    (unless (or (eq phase :done)
                (and (eq phase :fallback) (not (eq (getf state :writer) :done))))
      (let* ((next (copy-tree state)) (key (getf config :key))
             (target (and (getf state :fragment)
                          (slot state (getf state :fragment) key)))
             (label (list :reader phase :attempt (getf state :tries))))
        (ecase phase
          (:idle
           (add-event next (list :invoke :lookup :lookup key nil))
           (setf (getf next :reader) :enter))
          (:enter
           (when (eq (getf config :protection) :epoch)
             (setf (getf next :epoch) (second (getf state :root))))
           (setf (getf next :reader) :acquire))
          (:acquire
           ;; Riferimento forte: caricamento e possesso sono indivisibili.
           (setf (getf next :snapshot) (copy-tree (getf state :root))
                 (getf next :fragment) (nth (key-position key) (third (getf state :root)))
                 (getf next :protected) (eq (getf config :protection) :ref)
                 (getf next :captured-before-write)
                 (not (null (member (getf state :writer) '(:invoke-write :odd))))
                 (getf next :reader) (if (eq mutant :early-release) :early-release :probe))
           (incf (getf next :tries)))
          (:early-release (release-protection next) (setf (getf next :reader) :probe))
          (:probe
           (note-access next :control)
           (if (and target (eq (getf target :ctrl) :occupied))
               (setf (getf next :reader) :seq-first)
               (setf (getf next :candidate) :miss (getf next :reader) :barrier)))
          (:seq-first
           (note-access next :seq-first)
           (setf (getf next :first-seq) (getf target :seq))
           (if (and (oddp (getf target :seq)) (not (eq mutant :skip-fields)))
               (progn (reject-attempt next :seqlock)
                      (setf label (append label '(:reject :seqlock))))
               (setf (getf next :reader) :read-version)))
          (:read-version (note-access next :version)
                         (setf (getf next :version) (getf target :version)
                               (getf next :reader) :read-location))
          (:read-location (note-access next :location)
                          (setf (getf next :location) (getf target :location)
                                (getf next :reader) :read-live))
          (:read-live (note-access next :live)
                      (setf (getf next :live) (getf target :live)
                            (getf next :reader) :seq-last))
          (:seq-last (note-access next :seq-last)
                     (setf (getf next :last-seq) (getf target :seq)
                           (getf next :reader) :validate-fields))
          (:validate-fields
           (if (or (eq mutant :skip-fields)
                   (and (= (getf state :first-seq) (getf state :last-seq))
                        (evenp (getf state :last-seq))))
               (setf (getf next :candidate)
                     (if (getf state :live)
                         (list :hit (getf state :version) (getf state :location)) :miss)
                     (getf next :reader) :barrier)
               (progn (reject-attempt next :seqlock)
                      (setf label (append label '(:reject :seqlock))))))
          (:barrier (setf (getf next :reader) :validate-root))
          (:validate-root
           (let* ((captured (root-tag (getf state :snapshot)))
                  (current (root-tag (getf state :root)))
                  (skip (or (eq mutant :skip-root)
                            (and (eq mutant :skip-miss-root)
                                 (eq (getf state :candidate) :miss)))))
             (if (or skip (equal captured current))
                 (setf (getf next :result) (getf state :candidate)
                       (getf next :acceptance)
                       (list :captured captured :current current :checked (not skip))
                       (getf next :reader) :respond)
                 (progn (reject-attempt next :root)
                        (setf label (append label (list :reject :root
                                                       :candidate (getf state :candidate))))))))
          (:respond
           (add-event next (list :respond :lookup (getf state :result)))
           (release-protection next) (setf (getf next :reader) :done))
          (:fallback
           ;; Servizio astratto del writer dopo le sue operazioni seriali.
           ;; Lettura atomica della root corrente con protezione implicita.
           (let* ((id (nth (key-position key) (third (getf state :root))))
                  (current (slot state id key))
                  (value (if (and current (getf current :live))
                             (list :hit (getf current :version) (getf current :location))
                             :miss)))
             (feature next 8)
             (setf (getf next :result) value (getf next :reader) :done
                   (getf next :acceptance) '(:fallback t))
             (add-event next (list :respond :lookup value))
             (release-protection next))))
        (cons label next)))))

(defun reclaim-transition (state config)
  (when (and (getf state :retired) (not (getf state :reclaimed))
             (if (eq (getf config :protection) :ref)
                 (not (and (getf state :protected)
                           (member 0 (third (getf state :snapshot)))))
                 (not (and (getf state :epoch) (<= (getf state :epoch) 0)))))
    (let ((next (copy-tree state)))
      (setf (getf next :reclaimed) '(0))
      (cons '(:reclaimer :reclaim 0) next))))

(defun successors (state config mutant step-limit)
  (let ((edges (remove nil (list (writer-transition state config)
                                 (reader-transition state config mutant)
                                 (reclaim-transition state config)))))
    (when (and edges (>= (getf state :steps) step-limit))
      (budget-error :execution-steps step-limit))
    (dolist (edge edges)
      (setf (getf (cdr edge) :steps) (1+ (getf state :steps))))
    edges))

;;; Oracolo della storia: riceve esclusivamente invocazioni/risposte e specifica.
(defun history-operations (history)
  (let ((operations nil))
    (loop for event in history for time from 0 do
      (ecase (first event)
        (:invoke
         (when (assoc (second event) operations) (error \"Invocazione duplicata\"))
         (push (cons (second event)
                     (list :id (second event) :kind (third event) :key (fourth event)
                           :argument (fifth event) :invoke time :response nil :result nil))
               operations))
        (:respond
         (let ((operation (cdr (assoc (second event) operations))))
           (unless operation (error \"Risposta senza invocazione\"))
           (when (getf operation :response) (error \"Risposta duplicata\"))
           (setf (getf operation :response) time (getf operation :result) (third event))))))
    (when (> (length operations) 3) (budget-error :history-operations 3))
    (mapcar #'cdr (nreverse operations))))

(defun linearization (history)
  \"Cerca un'estensione finita: pendenti omessi o completati, precedenza reale.\"
  (let* ((operations (history-operations history))
         (complete (remove-if-not (lambda (op) (getf op :response)) operations))
         (pending (remove-if (lambda (op) (getf op :response)) operations))
         (nodes 0))
    (labels ((search-order (remaining map order)
               (incf nodes)
               (when (> nodes 128) (budget-error :linearization-nodes 128))
               (when (null remaining)
                 (return-from linearization (values t (nreverse order) nodes)))
               (dolist (op remaining)
                 (unless (some (lambda (other)
                                 (and (getf other :response)
                                      (< (getf other :response) (getf op :invoke))))
                               (remove op remaining :test #'eq))
                   (let ((next-map (copy-tree map)) (valid t))
                     (ecase (getf op :kind)
                       (:write (setf (cdr (assoc (getf op :key) next-map))
                                     (getf op :argument)))
                       (:maintenance)
                       (:lookup
                        (when (getf op :response)
                          (setf valid (equal (getf op :result)
                                             (cdr (assoc (getf op :key) map)))))))
                     (when valid
                       (search-order (remove op remaining :test #'eq)
                                     next-map (cons (getf op :id) order))))))))
      (dotimes (mask (ash 1 (length pending)))
        (search-order (append complete
                              (loop for op in pending for bit from 0
                                    when (logbitp bit mask) collect op))
                      (copy-tree (reference-initial)) nil)))
    (values nil nil nodes)))

(defun response-history (state)
  (if (eq (getf state :reader) :respond)
      (append (getf state :history) (list (list :respond :lookup (getf state :result))))
      (getf state :history)))

(defun response-present-p (state)
  (member (getf state :reader) '(:respond :done)))

(defun published-root-oracle (state config)
  \"Controlla entrambe le chiavi e l'instradamento, anche senza un reader.\"
  (let ((root (getf state :root)))
    (when (= (first root) 1)
      (unless (and (equal (root-tag root) '(1 1))
                   (equal (third root)
                          (if (eq (getf config :kind) :split) '(1 2) '(1 1))))
        (return-from published-root-oracle (list :kind :published-root-shape :root root)))
      (dolist (key '(:a :b))
        (let* ((entry (slot state (nth (key-position key) (third root)) key))
               (expected (if (eq key (getf config :key)) (getf config :new-value)
                             (cdr (assoc key (reference-initial)))))
               (actual (if (and entry (getf entry :live)
                                (eq (getf entry :ctrl) :occupied))
                           (list :hit (getf entry :version) (getf entry :location)) :miss)))
          (unless (and entry (evenp (getf entry :seq)) (equal expected actual))
            (return-from published-root-oracle
              (list :kind :incoherent-published-fragment :key key
                    :expected expected :actual actual))))))))

(defun data-oracle (state config)
  (cond
    ((getf state :bad-access)
     (list :kind :access-to-reclaimed :access (getf state :bad-access)))
    ((and (getf state :frozen-old)
          (not (equal (getf state :frozen-old) (fragment-slots state 0))))
     '(:kind :modified-retired-fragment))
    ((published-root-oracle state config))
    ((response-present-p state)
     (let* ((result (getf state :result))
            (initial (cdr (assoc (getf config :key) (reference-initial)))))
       (if (not (or (eq result :miss) (equal result initial)
                    (equal result (getf config :new-value))))
           (list :kind :incoherent-result :result result)
           (multiple-value-bind (valid order nodes) (linearization (response-history state))
             (declare (ignore order nodes))
             (unless valid (list :kind :not-linearizable
                                 :history (response-history state)))))))))

(defun generation-oracle (state)
  (let ((acceptance (getf state :acceptance)))
    (when (and (response-present-p state) acceptance
               (not (getf acceptance :fallback))
               (not (equal (getf acceptance :captured) (getf acceptance :current))))
      (multiple-value-bind (valid order nodes) (linearization (response-history state))
        (list :kind :generation-contract :acceptance acceptance
              :result (getf state :result) :linearizable valid
              :linearization order :oracle-nodes nodes
              :classification (if valid :generation-only :also-not-linearizable))))))

(defun protocol-oracle (state config)
  (or (data-oracle state config) (generation-oracle state)))

(defun terminal-p (state)
  (and (eq (getf state :writer) :done) (eq (getf state :reader) :done)
       (getf state :reclaimed)))

(defun history-oracle-checks ()
  \"Controlli indipendenti: overlap ammesso, precedenza reale e pendenti.\"
  (let ((reports nil) (max-nodes 0))
    (dolist (spec
             '((:overlapping-old-hit t
                ((:invoke :lookup :lookup :a nil)
                 (:invoke :write :write :a (:hit 2 202))
                 (:respond :write :ok) (:respond :lookup (:hit 1 101))))
               (:pending-write-new-hit t
                ((:invoke :write :write :a (:hit 2 202))
                 (:invoke :lookup :lookup :a nil) (:respond :lookup (:hit 2 202))))
               (:stale-hit-after-write-response nil
                ((:invoke :write :write :a (:hit 2 202)) (:respond :write :ok)
                 (:invoke :lookup :lookup :a nil) (:respond :lookup (:hit 1 101))))
               (:overlapping-old-miss t
                ((:invoke :lookup :lookup :b nil)
                 (:invoke :write :write :b (:hit 2 202)) (:respond :write :ok)
                 (:respond :lookup :miss)))
               (:stale-miss-after-write-response nil
                ((:invoke :write :write :b (:hit 2 202)) (:respond :write :ok)
                 (:invoke :maintenance :maintenance nil nil) (:respond :maintenance :ok)
                 (:invoke :lookup :lookup :b nil) (:respond :lookup :miss)))
               (:torn-tuple nil
                ((:invoke :write :write :a (:hit 2 202))
                 (:invoke :lookup :lookup :a nil) (:respond :lookup (:hit 2 101))))))
      (destructuring-bind (name expected history) spec
        (multiple-value-bind (valid order nodes) (linearization history)
          (unless (eql valid expected) (error \"Oracolo storico errato: ~S\" name))
          (setf max-nodes (max max-nodes nodes))
          (push (list :case name :expected-linearizable expected :linearizable valid
                      :linearization order :nodes nodes :witness history) reports))))
    (list :status :ok :cases (length reports) :max-nodes max-nodes
          :reports (reverse reports))))

(defun reachability-query (query state config)
  (when (and (response-present-p state) (null (data-oracle state config)))
    (case query
      (:retry-hit (when (logtest 1 (getf state :features)) :retry-hit-returned))
      (:retry-miss (when (logtest 2 (getf state :features)) :retry-miss-returned))
      (:fallback (when (logtest 8 (getf state :features)) :bounded-fallback-returned))
      (:old-root-updated
       (when (and (getf state :captured-before-write)
                  (getf state :snapshot) (= (first (getf state :snapshot)) 0)
                  (= (first (getf state :root)) 1)
                  (equal (getf state :result) (getf config :new-value)))
         (multiple-value-bind (valid order nodes) (linearization (response-history state))
           (list :kind :old-root-updated-after-acquisition :linearizable valid
                 :linearization order :oracle-nodes nodes)))))))

(defun check (&key (state-limit 200000) (step-limit 64))
  \"CHECK breve; un budget insufficiente fallisce, non promuove la copertura.\"
  (unless (and (integerp state-limit) (<= 1 state-limit 200000)
               (integerp step-limit) (<= 1 step-limit 64))
    (error \"Budget ammessi: stati 1..200000, passi 1..64\"))
  (let ((reports nil) (remaining state-limit) (total-edges 0) (max-steps 0)
        (history-checks (history-oracle-checks)))
    (labels
        ((run-model (config mutant mode &optional query)
           (when (<= remaining 0) (budget-error :suite-states state-limit))
           (let ((visited 0) (terminals 0) (hits 0) (misses 0)
                 (fallbacks 0) (max-tries 0) (local-steps 0) (oracle-nodes 0))
             (let* ((name (list :publication (getf config :kind) (getf config :change)
                                (getf config :protection) mutant mode query))
                    (report
                      (arcdocdb.spk07::explore
                       name (initial-state)
                       (lambda (state)
                         (let ((edges (successors state config mutant step-limit)))
                           (when (and (null edges) (not (terminal-p state)))
                             (error \"Stallo nel modello: ~S\" state))
                           edges))
                       (lambda (state)
                         (incf visited)
                         (setf local-steps (max local-steps (getf state :steps))
                               max-tries (max max-tries (getf state :tries)))
                         (when (terminal-p state) (incf terminals))
                         (when (response-present-p state)
                           (if (eq (getf state :result) :miss) (incf misses) (incf hits))
                           (when (logtest 8 (getf state :features)) (incf fallbacks))
                           (multiple-value-bind (valid order nodes)
                               (linearization (response-history state))
                             (declare (ignore valid order))
                             (setf oracle-nodes (max oracle-nodes nodes))))
                         (ecase mode
                           (:protocol (protocol-oracle state config))
                           (:data-history (data-oracle state config))
                           (:reachability (reachability-query query state config))))
                       :limit remaining)))
               (decf remaining (getf report :states))
               (incf total-edges (getf report :edges))
               (setf max-steps (max max-steps local-steps))
               (setf report
                     (append report
                             (list :config config :mutant mutant :oracle mode
                                   :visited visited :terminal-states terminals
                                   :observed-hit-states hits :observed-miss-states misses
                                   :observed-fallback-states fallbacks
                                   :max-tries max-tries :max-steps local-steps
                                   :max-oracle-nodes oracle-nodes
                                   :role (ecase mode
                                           (:protocol (if mutant :negative-control :positive))
                                           (:data-history :mutant-data-history-pass)
                                           (:reachability :positive-reachability))
                                   :count-unit :distinct-states-not-traces)))
               (arcdocdb.spk07::require-outcome
                report (or (eq mode :reachability) (and mutant (eq mode :protocol))))
               (when (and (not (getf report :violation)) (zerop terminals))
                 (error \"Nessun terminale completo: ~S\" name))
               (push report reports)
               report))))
      ;; Positivi: rebuild/split, hit aggiornato, miss->hit, hit->miss, ref/epoch.
      (dolist (kind '(:rebuild :split))
        (dolist (change '(:update :insert :delete))
          (dolist (protection '(:ref :epoch))
            (run-model (scenario kind change protection) nil :protocol))))
      ;; Witness mirati e controllo dati/storia sull'intero dominio del mutante.
      (dolist (spec '((:skip-root :update) (:skip-root :insert) (:skip-miss-root :insert)))
        (destructuring-bind (mutant change) spec
          (let* ((config (scenario :split change :ref))
                 (negative (run-model config mutant :protocol)))
            (unless (and (eq (getf (getf negative :violation) :kind) :generation-contract)
                         (getf (getf negative :violation) :linearizable))
              (error \"Witness di generazione non mirato: ~S\" negative))
            (run-model config mutant :data-history))))
      (dolist (protection '(:ref :epoch))
        (let ((report (run-model (scenario :split :update protection)
                                 :early-release :protocol)))
          (unless (eq (getf (getf report :violation) :kind) :access-to-reclaimed)
            (error \"Witness reclaim non mirato\"))))
      (let ((report (run-model (scenario :rebuild :update :ref) :skip-fields :protocol)))
        (unless (eq (getf (getf report :violation) :kind) :incoherent-result)
          (error \"Witness dei campi non mirato\")))
      (dolist (spec '((:retry-hit :update) (:retry-miss :insert) (:fallback :update)))
        (destructuring-bind (query change) spec
          (run-model (scenario :split change :ref) nil :reachability query)))
      (run-model (scenario :rebuild :update :ref) :skip-root :reachability :old-root-updated))
    (list :schema-version 1 :spike :spk-07 :module :pubblicazione :status :ok
          :reports (reverse reports)
          :counts (list :explorations (length reports) :states (- state-limit remaining)
                        :edges total-edges :max-execution-steps max-steps
                        :independent-history-cases (getf history-checks :cases)
                        :positive-models (count :positive reports :key (lambda (r) (getf r :role)))
                        :negative-controls (count :negative-control reports
                                                  :key (lambda (r) (getf r :role)))
                        :mutant-data-history-passes (count :mutant-data-history-pass reports
                                                          :key (lambda (r) (getf r :role)))
                        :reachability-witnesses (count :positive-reachability reports
                                                      :key (lambda (r) (getf r :role))))
          :history-oracle-checks history-checks
          :limits (list :states-per-exploration 200000 :suite-states state-limit
                        :execution-steps step-limit :reader-attempts 2
                        :history-operations 3 :linearization-nodes 128
                        :keys 2 :source-fragments 1 :writes 1 :maintenance-operations 1
                        :on-budget-exhaustion :error)
          :assumptions '(:sequential-consistency :atomic-root-and-generation
                         :immutable-directory :single-serial-writer
                         :seqlock-does-not-wrap :generation-does-not-wrap :no-aba
                         :strong-reference-acquisition-atomic
                         :epoch-announced-before-root :retired-fragments-frozen
                         :fallback-atomic-on-owner-after-finite-writer-work
                         :fair-scheduling-for-eventual-service)
          :conflicts '((:inv-i1-literal-immutability :adr0043-mutable-slots
                        :interpretation :immutable-roots-and-retired-fragments)
                       (:adr0043-initial-reference-linearization
                        :corrected-by :adr0050 :oracle :finite-operation-history))
          :generation-mutants :generation-only-witnesses-with-linearizable-histories
          :omitted '(:weak-memory :snapshot-expiry :machine-code :crashes :persistence
                     :directory-and-key-costs :full-swiss-probing :unbounded-histories
                     :gc-timing :production-fallback :external-resource-implementation)
          :coverage :bounded-sc-publication :gate :open)))
")
  (:PATH
   #A((87) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/metodo-pubblicazione.md")
   :KIND :SOURCE-BLOB :BYTE-LENGTH 6016 :DIGEST-ALGORITHM :MD5 :DIGEST
   #A((32) BASE-CHAR . "1960c1c8e5fae1fa4daebf0cc074b2c3") :ENCODING :UTF-8
   :CONTENT
   "# SPK-07 — Metodo della pubblicazione (registrato prima delle prove)

Ambito: solo `pubblicazione.lisp`, package `arcdocdb.spk07.pubblicazione`,
Common Lisp/SBCL con safety 3. Il core esistente viene caricato prima del modulo.
Riferimenti letti: ADR0043, ADR0050, INV-I1, INV-I3, INV-A8, INV-P1,
REQ-IDX-003/007. Nessun componente di produzione, benchmark o decisione nuova.

Il modello SC enumera interleaving di un writer, un lookup e un ritiro.
Due chiavi, un frammento sorgente, una scrittura e una manutenzione seriale
(rebuild oppure split) bastano a distinguere hit aggiornato, miss diventato hit
e hit diventato miss. Lo split instrada le due chiavi in frammenti diversi;
il rebuild mantiene l'alias delle due voci. Root e generazione sono una coppia
immutabile pubblicata in un passo indivisibile, dopo la costruzione privata.
Il vecchio frammento può cambiare sotto seqlock prima del ritiro, poi è congelato.
Versione, location, flag live e controllo sono passi distinti del writer.
Il reader protegge prima del sondaggio, legge i campi separatamente, valida
il seqlock, passa una barriera SC astratta e ricontrolla root/generazione anche
su miss. Due tentativi condividono il budget; il fallback è un lookup atomico
eseguito dal writer dopo i suoi lavori finiti. La schedulazione del fallback
e la sua implementazione non sono oggetto di questa prova.

Due astrazioni di durata: riferimento forte alla root (che mantiene i frammenti)
e annuncio epoch prima del caricamento della root. Il reclaim esige il ritiro
e l'assenza di protezioni pertinenti. ADR0043 assegna i frammenti heap al GC e
l'EBR alle risorse esterne: la variante epoch verifica solo l'astrazione di
durata, non cambia questa decisione e non simula un contatore comune di prodotto.

Gli oracoli sono separati dalle transizioni: (1) ogni risultato hit è una
tupla completa ammessa dalla specifica; (2) nessun accesso usa un frammento
reclaimed; (3) il contratto di generazione confronta la coppia catturata con
quella presente al punto di accettazione, non alla risposta successiva;
(4) un enumeratore indipendente cerca una serializzazione della storia finita
di invocazioni/risposte rispettando precedenze in tempo reale. La manutenzione
è un'identità sulla mappa astratta. Operazioni pendenti possono essere omesse
o completate; l'oracolo non usa root, campi o il punto di linearizzazione del
protocollo. Una lettura della vecchia root non è respinta per questo solo fatto.
Un oracolo strutturale controlla anche entrambe le chiavi della root nuova,
l'instradamento rebuild/split e la completezza dei frammenti pubblicati.

Controlli negativi: omettere il ricontrollo di tutte le risposte oppure solo
dei miss; rilasciare la protezione prima del sondaggio; omettere la validazione
dei campi/seqlock nel caso hit. Ogni mutante deve produrre un witness mirato.
Per i mutanti di generazione si esplora anche il solo oracolo dati/storia:
se non viola linearizzabilità nel dominio finito, lo si dichiara esplicitamente.
Query di raggiungibilità positive devono testimoniare retry hit/miss, fallback
e lettura coerente aggiornata della vecchia root dopo la sostituzione.
Sei storie controllano direttamente l'oracolo indipendente: hit/miss vecchi
con operazioni sovrapposte ammessi; hit da scrittura pendente ammesso;
hit/miss vecchi dopo la risposta della scrittura e tupla strappata respinti.

Budget: massimo 200000 stati per esplorazione e complessivi del CHECK,
64 passi per esecuzione, due tentativi del reader, tre operazioni nella storia,
128 nodi per ricerca di serializzazione. Un budget esaurito solleva errore;
nessun taglio è interpretato come successo. Conteggi di stati/transizioni,
accettazioni, risultati e terminali sono effettivi; non contano tutte le tracce.
La fine di ogni esecuzione completa richiede writer e reader conclusi e reclaim.

Ogni tentativo di compilazione/check avvia un figlio SBCL con inizializzazioni
disabilitate e avvisi, inclusi style-warning, fatali. Un recorder Common Lisp
su stdin conserva un nuovo record plist `:schema-version 1` in `out/`:
argv/stdin esatti, ambiente, sorgenti come blob integrali e digest MD5 prima/dopo,
risultato decodificato, limiti, stdout/stderr grezzi, exit code e fallimenti.
Il record iniziale è scritto prima del figlio; i sorgenti devono essere stabili.
Git non viene consultato: commit e blob Git sono dichiarati non acquisiti.
FASL e record ricevono nomi nuovi. Non si misura throughput o latenza del motore.

Limiti dichiarati: memoria debole, disassemblato/barriere reali, snapshot expiry,
crash/persistenza, costi della directory/chiavi, wrap, allocator e scheduling
del runtime esclusi. Generazioni/seqlock non fanno wrap, nessun ABA né
riutilizzo di identità. Il probing Swiss completo, collisioni e capacità reali
sono astratti in due posizioni di directory e un controllo per chiave.
SC rende la barriera un passo di ordine esplicito, senza validarne il codice.

Tensione normativa da segnalare: la lettura letterale di INV-I1 («gli indici
sono immutabili per i reader») è più forte degli aggiornamenti di slot sotto
seqlock consentiti da ADR0043. Qui sono immutabili root/directory e frammenti
ritirati, mentre lo slot pubblicato può essere aggiornato prima del ritiro.
ADR0050 corregge inoltre il vecchio istante di linearizzazione proposto in
ADR0043. Nessun testo normativo o gate viene modificato.

## Registro dei tentativi intermedi

- `out/pubblicazione-4000478729-91239-record.lisp`: avvio fallito prima della
  compilazione per posizione errata dell'opzione runtime SBCL. Exit 1 e
  stderr originali conservati; argv corretto nei tentativi seguenti.
- `out/pubblicazione-4000478744-91419-record.lisp`: compilazione e check riusciti,
  64316 stati, 110401 transizioni, massimo 39 passi. Il campo riepilogativo
  `:explorations 1` è errato per una inversione distruttiva della lista:
  i 25 report integrali sono presenti. Corretto il conteggio prima della prova
  finale; questo record intermedio non è il riepilogo finale.
"))
 :SOURCE-STABILITY :STABLE :START 4000478957 :END 4000478957 :LIMITS
 (:SUITE-STATES 200000 :STATES-PER-MODEL 200000 :STEPS 64 :READER-ATTEMPTS 2
  :ORACLE-NODES 128 :HISTORY-OPERATIONS 3)
 :STDOUT "" :STDERR
 "Unhandled ARCDOCDB.SPK07.PUBBLICAZIONE::MODEL-BUDGET-EXHAUSTED in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                                            {80086C0693}>:
  Budget EXECUTION-STEPS esaurito: 1

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80086C0693}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.SPK07.PUBBLICAZIONE::MODEL-BUDGET-EXHAUSTED {80062B8A23}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.SPK07.PUBBLICAZIONE::MODEL-BUDGET-EXHAUSTED {80062B8A23}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.SPK07.PUBBLICAZIONE::MODEL-BUDGET-EXHAUSTED {80062B8A23}>)
3: (ERROR ARCDOCDB.SPK07.PUBBLICAZIONE::MODEL-BUDGET-EXHAUSTED :RESOURCE :EXECUTION-STEPS :LIMIT 1)
4: (ARCDOCDB.SPK07.PUBBLICAZIONE::BUDGET-ERROR :EXECUTION-STEPS 1)
5: (ARCDOCDB.SPK07.PUBBLICAZIONE::SUCCESSORS (:STEPS 1 :WRITER :ODD :READER :IDLE :ROOT (0 0 (0 0)) :PREPARED-ROOT NIL :FRAGMENTS ((0 (:A :SEQ 0 :VERSION 1 :LOCATION 101 :LIVE T :CTRL :OCCUPIED) (:B :SEQ 0 :VERSION 0 :LOCATION 0 :LIVE NIL :CTRL :EMPTY))) ...) (:KIND :REBUILD :CHANGE :UPDATE :PROTECTION :REF :KEY :A :NEW-VALUE (:HIT 2 202)) NIL 1)
6: ((LAMBDA (ARCDOCDB.SPK07.PUBBLICAZIONE::STATE) :IN ARCDOCDB.SPK07.PUBBLICAZIONE:CHECK) (:STEPS 1 :WRITER :ODD :READER :IDLE :ROOT (0 0 (0 0)) :PREPARED-ROOT NIL :FRAGMENTS ((0 (:A :SEQ 0 :VERSION 1 :LOCATION 101 :LIVE T :CTRL :OCCUPIED) (:B :SEQ 0 :VERSION 0 :LOCATION 0 :LIVE NIL :CTRL :EMPTY))) ...))
7: (ARCDOCDB.SPK07::EXPLORE (:PUBLICATION :REBUILD :UPDATE :REF NIL :PROTOCOL NIL) (:STEPS 0 :WRITER :INVOKE-WRITE :READER :IDLE :ROOT (0 0 (0 0)) :PREPARED-ROOT NIL :FRAGMENTS ((0 (:A :SEQ 0 :VERSION 1 :LOCATION 101 :LIVE T :CTRL :OCCUPIED) (:B :SEQ 0 :VERSION 0 :LOCATION 0 :LIVE NIL :CTRL :EMPTY))) ...) #<FUNCTION (LAMBDA (ARCDOCDB.SPK07.PUBBLICAZIONE::STATE) :IN ARCDOCDB.SPK07.PUBBLICAZIONE:CHECK) {80062B882B}> #<FUNCTION (LAMBDA (ARCDOCDB.SPK07.PUBBLICAZIONE::STATE) :IN ARCDOCDB.SPK07.PUBBLICAZIONE:CHECK) {80062B885B}> :LIMIT 200000)
8: ((LABELS ARCDOCDB.SPK07.PUBBLICAZIONE::RUN-MODEL :IN ARCDOCDB.SPK07.PUBBLICAZIONE:CHECK) (:KIND :REBUILD :CHANGE :UPDATE :PROTECTION :REF :KEY :A :NEW-VALUE (:HIT 2 202)) NIL :PROTOCOL NIL)
9: (ARCDOCDB.SPK07.PUBBLICAZIONE:CHECK :STATE-LIMIT 200000 :STEP-LIMIT 1)
10: (\"top level form\") [toplevel]
11: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
12: (SB-C::%COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LIST #) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (PROGN (FLET ((STRICT-COMPILE # #)) (STRICT-COMPILE #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/core.lisp\" #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-core.fasl\") (STRICT-COMPILE #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/pubblicazione.lisp\" #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-module.fasl\") (LET (#) (FORMAT T \"SPK07-RESULT~%\") (WITH-STANDARD-IO-SYNTAX # #))))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80086A0423}> 2 NIL T T)
13: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LIST #) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (PROGN (FLET ((STRICT-COMPILE # #)) (STRICT-COMPILE #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/core.lisp\" #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-core.fasl\") (STRICT-COMPILE #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/pubblicazione.lisp\" #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-module.fasl\") (LET (#) (FORMAT T \"SPK07-RESULT~%\") (WITH-STANDARD-IO-SYNTAX # #))))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80086A0423}> 2 NIL)
14: (SB-IMPL::%SIMPLE-EVAL (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LIST #) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (PROGN (FLET ((STRICT-COMPILE # #)) (STRICT-COMPILE #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/core.lisp\" #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-core.fasl\") (STRICT-COMPILE #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/pubblicazione.lisp\" #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-module.fasl\") (LET (#) (FORMAT T \"SPK07-RESULT~%\") (WITH-STANDARD-IO-SYNTAX # #))))) #<NULL-LEXENV>)
15: (SB-INT:SIMPLE-EVAL-IN-LEXENV (HANDLER-BIND ((WARNING (LAMBDA (C) (ERROR \"Avviso fatale: ~A\" C)))) (FLET ((STRICT-COMPILE (SOURCE OUTPUT) (MULTIPLE-VALUE-BIND # # # #))) (STRICT-COMPILE #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/core.lisp\" #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-core.fasl\") (STRICT-COMPILE #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/pubblicazione.lisp\" #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-module.fasl\") (LET ((RESULT #)) (FORMAT T \"SPK07-RESULT~%\") (WITH-STANDARD-IO-SYNTAX (WRITE RESULT :READABLY T :PRETTY NIL) (TERPRI))))) #<NULL-LEXENV>)
16: (EVAL-TLF (HANDLER-BIND ((WARNING (LAMBDA (C) (ERROR \"Avviso fatale: ~A\" C)))) (FLET ((STRICT-COMPILE (SOURCE OUTPUT) (MULTIPLE-VALUE-BIND # # # #))) (STRICT-COMPILE #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/core.lisp\" #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-core.fasl\") (STRICT-COMPILE #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/pubblicazione.lisp\" #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-module.fasl\") (LET ((RESULT #)) (FORMAT T \"SPK07-RESULT~%\") (WITH-STANDARD-IO-SYNTAX (WRITE RESULT :READABLY T :PRETTY NIL) (TERPRI))))) 2 NIL)
17: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (LAMBDA (C) (ERROR \"Avviso fatale: ~A\" C)))) (FLET ((STRICT-COMPILE (SOURCE OUTPUT) (MULTIPLE-VALUE-BIND # # # #))) (STRICT-COMPILE #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/core.lisp\" #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-core.fasl\") (STRICT-COMPILE #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/pubblicazione.lisp\" #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-module.fasl\") (LET ((RESULT #)) (FORMAT T \"SPK07-RESULT~%\") (WITH-STANDARD-IO-SYNTAX (WRITE RESULT :READABLY T :PRETTY NIL) (TERPRI))))) 2)
18: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (LAMBDA (C) (ERROR \"Avviso fatale: ~A\" C)))) (FLET ((STRICT-COMPILE (SOURCE OUTPUT) (MULTIPLE-VALUE-BIND # # # #))) (STRICT-COMPILE #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/core.lisp\" #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-core.fasl\") (STRICT-COMPILE #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/pubblicazione.lisp\" #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-module.fasl\") (LET ((RESULT #)) (FORMAT T \"SPK07-RESULT~%\") (WITH-STANDARD-IO-SYNTAX (WRITE RESULT :READABLY T :PRETTY NIL) (TERPRI))))) :CURRENT-INDEX 2)
19: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1078C0F1B}> #<SB-C::SOURCE-INFO {80086A0423}> SB-C::INPUT-ERROR-IN-LOAD)
20: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {80086A0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
21: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {80086A0043}> NIL)
22: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1078C09EB}> #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {80086A0043}> NIL #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {80086A0043}>)
23: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {80086A0043}> NIL)
24: (LOAD #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {80086A0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
25: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {80086A0043}>)
26: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
27: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
28: (SB-IMPL::PROCESS-SCRIPT \"/dev/stdin\")
29: (SB-IMPL::TOPLEVEL-INIT)
30: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
31: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
32: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
"
 :EXIT-CODE 1 :RESULT NIL :FAILURES
 ((:TYPE #A((12) BASE-CHAR . "SIMPLE-ERROR") :MESSAGE
   #A((34) BASE-CHAR . "Figlio SBCL terminato con codice 1")))
 :OUTPUTS
 (#A((107) BASE-CHAR
     . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-core.fasl")
  #A((109) BASE-CHAR
     . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/pubblicazione-4000478956-1639-module.fasl"))
 :OMITTED (:GIT-COMMIT :GIT-BLOB :PERFORMANCE-BENCHMARK))
