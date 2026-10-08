(:SCHEMA-VERSION 1 :MODULE :SCADENZA :ATTEMPT 3 :STATUS :OK
 :STARTED-UNIVERSAL-TIME 4000478966 :FINISHED-UNIVERSAL-TIME 4000478969
 :COMMAND
 (:ARGV
  ("/opt/homebrew/bin/sbcl" "--noinform" "--no-userinit" "--no-sysinit"
   "--disable-debugger" "--script" "/dev/stdin")
  :CWD #A((40) BASE-CHAR . "/Users/gpicchiarelli/Documents/ArcDocDB/") :STDIN
  #A((7524) BASE-CHAR . "(require :asdf)
(declaim (optimize (safety 3) (speed 1) (debug 3)))
(let* ((root #p\"/Users/gpicchiarelli/Documents/ArcDocDB/\")
       (base (merge-pathnames \"spikes/SPK-07-protocols/\" root))
       (attempt (parse-integer (sb-ext:posix-getenv \"ARCDOCDB_SCADENZA_ATTEMPT\")))
       (record-path (merge-pathnames (format nil \"out/scadenza-attempt-~3,'0D.sexp\" attempt) base))
       (stdout (make-string-output-stream)) (stderr (make-string-output-stream))
       (original-out *standard-output*) (original-err *error-output*)
       (environment nil) (blobs nil) (units nil) (result nil) (failures nil)
       (warnings 0) (style-warnings 0) (stage :metadata)
       (started (get-universal-time))
       (sources '(\"core.lisp\" \"scadenza.lisp\" \"metodo-scadenza.md\")))
  (ensure-directories-exist record-path)
  (when (probe-file record-path) (error \"Record gia esistente: ~A\" record-path))
  (let ((*standard-output* (make-broadcast-stream stdout original-out))
        (*error-output* (make-broadcast-stream stderr original-err))
        (*trace-output* (make-broadcast-stream stderr original-err)))
    (handler-case
        (progn
          (setf environment
                (list :lisp (lisp-implementation-type) :lisp-version (lisp-implementation-version)
                      :os (software-type) :os-version (software-version)
                      :machine-type (machine-type) :machine-version (machine-version)
                      :machine-instance (machine-instance) :features *features*
                      :cwd (namestring (uiop:getcwd)) :timezone \"Europe/Rome\"
                      :locale (sb-ext:posix-getenv \"LANG\") :safety 3))
          (dolist (relative sources)
            (let* ((path (merge-pathnames relative base))
                   (content (uiop:read-file-string path :external-format :utf-8))
                   (octets (sb-ext:string-to-octets content :external-format :utf-8)))
              (push (list :path (namestring path) :encoding :utf-8
                          :octet-count (length octets) :content content) blobs)))
          (handler-bind
              ((warning (lambda (condition)
                          (if (typep condition 'style-warning)
                              (incf style-warnings) (incf warnings))
                          (error \"Warning/style-warning fatale: ~A\" condition))))
            (dolist (relative '(\"core.lisp\" \"scadenza.lisp\"))
              (let* ((source (merge-pathnames relative base))
                     (output (merge-pathnames
                              (format nil \"out/scadenza-attempt-~3,'0D-~A.fasl\"
                                      attempt (pathname-name source)) base)))
                (setf stage (list :compile relative))
                (when (probe-file output) (error \"FASL gia esistente: ~A\" output))
                (multiple-value-bind (fasl warnings-p failure-p)
                    (compile-file source :output-file output)
                  (push (list :source relative :fasl (and fasl (namestring fasl))
                              :warnings-p warnings-p :failure-p failure-p
                              :status (if (or warnings-p failure-p (null fasl)) :failed :ok)) units)
                  (when (or warnings-p failure-p (null fasl))
                    (error \"Compile-file strict fallita: ~A\" source))
                  (setf stage (list :load relative))
                  (load fasl))))
            (setf stage :check)
            (let ((check (find-symbol \"CHECK\" \"ARCDOCDB.SPK07.SCADENZA\")))
              (unless (and check (fboundp check)) (error \"CHECK mancante\"))
              (setf result (funcall check)))
            (unless (eq (getf result :status) :ok) (error \"CHECK non :ok: ~S\" result))
            (setf stage :complete)))
      (error (condition)
        (push (list :stage stage :type (princ-to-string (type-of condition))
                    :message (princ-to-string condition)) failures)
        (format *error-output* \"~&FALLIMENTO ~S: ~A~%\" stage condition)))
    (let ((*print-pretty* t) (*print-readably* t))
      (write (list :artifact (namestring record-path) :attempt attempt
                   :status (if failures :failed :ok)
                   :compile-units (reverse units)
                   :warning-count warnings :style-warning-count style-warnings
                   :counts (getf result :counts)
                   :models (mapcar (lambda (r) (list :model (getf r :model) :states (getf r :states)
                                                    :edges (getf r :edges)
                                                    :violation (getf r :violation)
                                                    :terminal (getf r :terminal)
                                                    :coverage-count (getf r :coverage-count)
                                                    :coverage (mapcar (lambda (c) (getf c :name)) (getf r :coverage))
                                                    :reclaim-transitions-audited (getf r :reclaim-transitions-audited)
                                                    :epoch-blocked-states (getf r :epoch-blocked-states)
                                                    :witness (getf r :witness)))
                                   (append (getf result :positive) (getf result :negative)))))
      (terpri)))
  (let* ((artifact
           (list :schema-version 1 :module :scadenza :attempt attempt
                 :status (if failures :failed :ok) :started-universal-time started
                 :finished-universal-time (get-universal-time)
                 :command (list :argv '(\"/opt/homebrew/bin/sbcl\" \"--noinform\" \"--no-userinit\"
                                       \"--no-sysinit\" \"--disable-debugger\" \"--script\" \"/dev/stdin\")
                                :cwd (namestring root)
                                :stdin (sb-ext:posix-getenv \"ARCDOCDB_SCADENZA_STDIN\")
                                :environment-overrides
                                (list :ARCDOCDB_SCADENZA_ATTEMPT (write-to-string attempt)))
                 :environment environment :source-blobs (nreverse blobs)
                 :compile-status (list :status (if (and (= (length units) 2) (every (lambda (u) (eq (getf u :status) :ok)) units)) :ok :failed)
                                       :warning-count warnings :style-warning-count style-warnings
                                       :units (nreverse units))
                 :result result
                 :limits (list :states-per-model 500000 :ticks 2 :snapshot-count 2
                               :reader-count 3 :samples-per-reader 2 :retirements 2
                               :memory-model :sequential-consistency :real-time-guarantee nil
                               :benchmarks nil :git-operations nil)
                 :stdout (get-output-stream-string stdout) :stderr (get-output-stream-string stderr)
                 :failures (nreverse failures))))
    (with-open-file (output record-path :direction :output :if-exists :error
                                        :if-does-not-exist :create :external-format :utf-8)
      (let ((*print-pretty* t) (*print-readably* t) (*print-circle* nil))
        (write artifact :stream output) (terpri output)))
    (let ((*read-eval* nil))
      (with-open-file (input record-path :external-format :utf-8)
        (unless (and (equal (read input) artifact) (eq (read input nil :eof) :eof))
          (error \"Record schema 1 non riletto fedelmente\"))))
    (sb-ext:exit :code (if failures 1 0))))
")
  :ENVIRONMENT-OVERRIDES (:ARCDOCDB_SCADENZA_ATTEMPT #A((1) BASE-CHAR . "3")))
 :ENVIRONMENT
 (:LISP #A((4) BASE-CHAR . "SBCL") :LISP-VERSION #A((5) BASE-CHAR . "2.6.9")
  :OS #A((6) BASE-CHAR . "Darwin") :OS-VERSION #A((6) BASE-CHAR . "27.0.0")
  :MACHINE-TYPE #A((5) BASE-CHAR . "ARM64") :MACHINE-VERSION
  #A((8) BASE-CHAR . "Apple M4") :MACHINE-INSTANCE "iMac-di-GIACOMO" :FEATURES
  (:ASDF3.3 :ASDF3.2 :ASDF3.1 :ASDF3 :ASDF2 :ASDF :OS-MACOSX :OS-UNIX
   :NON-BASE-CHARS-EXIST-P :ASDF-UNICODE :ARENA-ALLOCATOR :ARM64 :GENCGC
   :64-BIT :ANSI-CL :BSD :COMMON-LISP :DARWIN :IEEE-FLOATING-POINT
   :LITTLE-ENDIAN :MACH-O :PACKAGE-LOCAL-NICKNAMES :SB-CORE-COMPRESSION :SB-LDB
   :SB-PACKAGE-LOCKS :SB-THREAD :SB-UNICODE :SBCL :UNIX)
  :CWD #A((40) BASE-CHAR . "/Users/gpicchiarelli/Documents/ArcDocDB/")
  :TIMEZONE "Europe/Rome" :LOCALE #A((7) BASE-CHAR . "C.UTF-8") :SAFETY 3)
 :SOURCE-BLOBS
 ((:PATH
   #A((73) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/core.lisp")
   :ENCODING :UTF-8 :OCTET-COUNT 15029 :CONTENT
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
   #A((77) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/scadenza.lisp")
   :ENCODING :UTF-8 :OCTET-COUNT 26359 :CONTENT
   ";;;; SPK-07: modello finito, non codice del motore. Metodo preregistrato a fianco.
(defpackage :arcdocdb.spk07.scadenza (:use :cl) (:export :check))
(in-package :arcdocdb.spk07.scadenza)
(declaim (optimize (safety 3) (speed 1) (debug 3)))

(defconstant +state-limit+ 500000)
(defconstant +no-snapshot+ 3)

(defun replacing (state key value)
  \"Ogni chiave e ogni sottolista di stato sono immutabili dopo la pubblicazione.\"
  (let ((next (copy-list state))) (setf (getf next key) value) next))

(defun item-replacing (items index value)
  (let ((next (copy-list items))) (setf (nth index next) value) next))

(defun value-at (csn)
  \"Storia logica dell'oracolo, indipendente dalle location fisiche.\"
  (ecase csn (0 100) (1 200) (2 300)))

(defun failure (kind &rest details)
  (list* :kind kind details))

;;; Registrazione: writer 0=inizio,1=CSN preso,2=soglia letta,3=pubblicato,4=H.
;;; Snapshot 0=inizio,1=annuncio,2=s fissato,3=nato; due letture separate.
(defun registration-initial ()
  '(:writer 0 :registration 0 :threshold 3 :csn nil :horizon 0
    :keep-old nil :current 0 :reads ()))

(defun registration-edges (state mutant)
  (let ((edges nil) (w (getf state :writer)) (r (getf state :registration)))
    (when (< w 4)
      (let ((next (replacing state :writer (1+ w))))
        (case w
          (1 (setf next (replacing next :keep-old (< (getf state :threshold) 1))))
          (2 (setf next (replacing next :current 1)))
          (3 (setf next (replacing next :horizon 1))))
        (push (cons (list :writer (nth w '(:assign-csn :sample-threshold
                                          :publish-version :advance-horizon))) next) edges)))
    (when (and (< r 3)
               (or (/= r 2) (>= (getf state :horizon) (getf state :csn))
                   (eq mutant :birth-before-horizon)))
      (let ((next (replacing state :registration (1+ r))))
        (case r
          (0 (unless (eq mutant :omit-registration-threshold)
               (setf next (replacing next :threshold
                                     (min (getf state :threshold) (getf state :horizon))))))
          (1 (setf next (replacing next :csn (if (> w 0) 1 0)))))
        (push (cons (list :snapshot (nth r '(:announce-threshold :capture-csn :born)))
                    next) edges)))
    (when (and (= r 3) (< (length (getf state :reads)) 2))
      (let* ((s (getf state :csn))
             (observed (if (= s (getf state :current)) (value-at s)
                           (and (= s 0) (getf state :keep-old) (value-at 0)))))
        (push (cons (list :snapshot :read :csn s :observed observed)
                    (replacing state :reads (append (getf state :reads) (list observed)))) edges)))
    (nreverse edges)))

(defun registration-violation (state)
  (when (= (getf state :registration) 3)
    (let ((s (getf state :csn)) (h (getf state :horizon)))
      (cond ((< h s) (failure :birth-before-horizon :csn s :horizon h))
            ((some (lambda (observed) (not (eql observed (value-at s))))
                   (getf state :reads))
             (failure :snapshot-view-changed :csn s :expected (value-at s)
                      :reads (getf state :reads)))
            (t nil)))))

;;; Lifetime: pins logici distinti dagli slot EBR dei reader.
(defun lifetime-initial ()
  '(:published nil :tick 0 :epoch 0 :threshold 0
    :snapshots ((:csn 0 :status :active :pin t :deadline 1)
                (:csn 1 :status :active :pin t :deadline 2))
    :retained (t nil) :retired (nil nil) :reclaimed (nil nil)
    :readers ((:owner 0 :phase :idle :epoch nil :location nil :samples nil
               :reply nil :admitted-live nil :validated-live nil)
              (:owner 1 :phase :idle :epoch nil :location nil :samples nil
               :reply nil :admitted-live nil :validated-live nil)
              (:owner 0 :phase :idle :epoch nil :location nil :samples nil
               :reply nil :admitted-live nil :validated-live nil))
    :failure nil))

(defun snapshot-active-p (state owner)
  (eq (getf (nth owner (getf state :snapshots)) :status) :active))

(defun registry-minimum (snapshots)
  (reduce #'min snapshots :initial-value +no-snapshot+
          :key (lambda (snapshot) (if (getf snapshot :pin)
                                     (getf snapshot :csn) +no-snapshot+))))

(defun logical-reference-p (state version)
  (or (and (= version 1) (not (getf state :published)))
      (nth version (getf state :retained))))

(defun epochs-clear-p (state retired-at)
  (every (lambda (reader) (let ((epoch (getf reader :epoch)))
                           (or (null epoch) (> epoch retired-at))))
         (getf state :readers)))

(defun reader-replacing (state index reader)
  (replacing state :readers (item-replacing (getf state :readers) index reader)))

(defun validate-reader (state reader)
  (let ((active (snapshot-active-p state (getf reader :owner))))
    (replacing (replacing (replacing reader :phase :validated)
                          :validated-live active)
               :reply (if active :ok :snapshot-too-old))))

(defun lifetime-edges (state mutant)
  (let ((edges nil) (snapshots (getf state :snapshots)))
    (flet ((emit (action next) (push (cons action next) edges)))
      (unless (getf state :published)
        (emit '(:writer :publish-csn-2-and-horizon)
              (replacing (replacing state :published t) :retained
                         (item-replacing (getf state :retained) 1
                                         (< (getf state :threshold) 2)))))
      (when (< (getf state :tick) 2)
        (emit (list :abstract-tick (1+ (getf state :tick)))
              (replacing state :tick (1+ (getf state :tick)))))
      (loop for snapshot in snapshots for owner from 0 do
        (when (and (eq (getf snapshot :status) :active)
                   (>= (getf state :tick) (getf snapshot :deadline)))
          (emit (list :expire :snapshot owner)
                (replacing state :snapshots
                           (item-replacing snapshots owner
                                           (replacing snapshot :status :expired)))))
        (when (and (eq (getf snapshot :status) :expired) (getf snapshot :pin))
          (let* ((remaining (item-replacing snapshots owner (replacing snapshot :pin nil)))
                 (threshold (if (eq mutant :no-threshold-recount)
                                (getf state :threshold) (registry-minimum remaining))))
            (emit (list :release-snapshot-pin :snapshot owner :remaining-minimum
                        (registry-minimum remaining) :threshold threshold)
                  (replacing (replacing state :snapshots remaining) :threshold threshold)))))
      (loop for reader in (getf state :readers) for index from 0
            for owner = (getf reader :owner) do
        (case (getf reader :phase)
          (:idle
           (if (or (snapshot-active-p state owner) (eq mutant :admit-after-expiry))
               (emit (list :reader index :admit :snapshot owner :epoch (getf state :epoch))
                     (reader-replacing state index
                       (replacing (replacing (replacing reader :phase :entered)
                                             :epoch (getf state :epoch))
                                  :admitted-live (snapshot-active-p state owner))))
               (emit (list :reader index :reject :snapshot-too-old)
                     (reader-replacing state index
                       (replacing (replacing reader :phase :done) :reply :snapshot-too-old)))))
          (:entered
           (let ((location (if (logical-reference-p state owner) owner :missing)))
             (emit (list :reader index :lookup :location location)
                   (reader-replacing state index
                     (replacing (replacing reader :phase :located) :location location)))))
          ((:located :read-once)
           (let ((location (getf reader :location)))
             (if (eq location :missing)
                 (emit (list :reader index :validate-missing :snapshot-too-old)
                       (reader-replacing state index (validate-reader state reader)))
                 (let* ((reclaimed (nth location (getf state :reclaimed)))
                        (observed (unless reclaimed (value-at location)))
                        (updated (replacing
                                  (replacing reader :phase
                                    (if (eq (getf reader :phase) :located)
                                        :read-once :read-twice))
                                  :samples (append (getf reader :samples) (list observed))))
                        (next (reader-replacing state index updated)))
                   (when reclaimed
                     (setf next (replacing next :failure
                                          (failure :access-after-reclaim :reader index
                                                   :version location :epoch (getf reader :epoch)
                                                   :retired-at (nth location (getf state :retired))))))
                   (emit (list :reader index :access :version location :observed observed) next)))))
          (:read-twice
           (let ((updated (validate-reader state reader)))
             (emit (list :reader index :validate-response :reply (getf updated :reply))
                   (reader-replacing state index updated))))
          (:validated
           (emit (list :reader index :release-epoch)
                 (reader-replacing state index
                   (replacing (replacing reader :phase :done) :epoch nil))))))
      (dotimes (version 2)
        (when (and (nth version (getf state :retained))
                   (>= (getf state :threshold) (1+ version)))
          (emit (list :prune-retained-version version :threshold (getf state :threshold))
                (replacing state :retained (item-replacing (getf state :retained) version nil))))
        (let ((retired-at (nth version (getf state :retired))))
          (when (and (null retired-at) (not (logical-reference-p state version)))
            (emit (list :retire-version version :retired-at (getf state :epoch))
                  (replacing (replacing state :retired
                                        (item-replacing (getf state :retired) version
                                                        (getf state :epoch)))
                             :epoch (1+ (getf state :epoch)))))
          (when (and retired-at (not (nth version (getf state :reclaimed)))
                     (or (epochs-clear-p state retired-at)
                         (and (eq mutant :expiry-ignores-readers)
                              (not (snapshot-active-p state version)))))
            (emit (list :reclaim-version version :retired-at retired-at
                        :reader-epochs (mapcar (lambda (r) (getf r :epoch)) (getf state :readers)))
                  (replacing state :reclaimed
                             (item-replacing (getf state :reclaimed) version t)))))))
    (nreverse edges)))

(defun lifetime-violation (state)
  (or (getf state :failure)
      (let ((expected (registry-minimum (getf state :snapshots))))
        (unless (= (getf state :threshold) expected)
          (failure :threshold-stale-after-release :expected expected
                   :actual (getf state :threshold) :pins (getf state :snapshots))))
      (loop for reader in (getf state :readers) for index from 0
            for owner = (getf reader :owner) thereis
        (cond
          ((and (not (member (getf reader :phase) '(:idle :done)))
                (not (getf reader :admitted-live)))
           (failure :admission-after-expiry :reader index :snapshot owner))
          ((some (lambda (sample) (not (eql sample (value-at owner)))) (getf reader :samples))
           (failure :snapshot-view-changed :reader index :expected (value-at owner)
                    :samples (getf reader :samples)))
          ((and (eq (getf reader :phase) :located) (eq (getf reader :location) :missing)
                (snapshot-active-p state owner))
           (failure :live-snapshot-location-missing :reader index :snapshot owner))
          ((and (eq (getf reader :reply) :ok)
                (or (not (getf reader :validated-live))
                    (/= (length (getf reader :samples)) 2)))
           (failure :invalid-positive-response :reader index :details reader))
          (t nil)))
      (loop for version below 2 thereis
        (and (nth version (getf state :reclaimed)) (logical-reference-p state version)
             (failure :reclaimed-logical-reference :version version)))))

(defun lifetime-terminal-p (state)
  (and (getf state :published) (= (getf state :tick) 2)
       (every (lambda (s) (and (eq (getf s :status) :expired) (null (getf s :pin))))
              (getf state :snapshots))
       (every (lambda (r) (and (eq (getf r :phase) :done) (null (getf r :epoch))))
              (getf state :readers))
       (every #'null (getf state :retained)) (every #'identity (getf state :reclaimed))))

(defun registration-coverage (state &optional previous action)
  (declare (ignore previous action))
  (let ((w (getf state :writer)) (r (getf state :registration)) (names nil))
    (when (and (= r 3) (= (getf state :csn) 1) (>= w 2)
               (not (getf state :keep-old)))
      (push :writer-sampled-before-announcement names))
    (when (and (= r 3) (= (getf state :csn) 0) (>= w 3) (getf state :keep-old))
      (push :writer-observed-announcement names))
    (when (= (length (getf state :reads)) 2) (push :repeatable-registration-view names))
    names))

(defun lifetime-coverage (state &optional previous action)
  (let ((names nil) (readers (getf state :readers)))
    (when (and (getf state :published) (snapshot-active-p state 0)
               (getf (first (getf state :snapshots)) :pin)
               (first (getf state :retained)) (= (getf state :threshold) 0))
      (push :snapshot-pin-blocks-prune names))
    (when (and (eq (getf (first readers) :reply) :ok)
               (eq (getf (third readers) :reply) :ok))
      (push :two-successful-operations-same-snapshot names))
    (when (and previous (eq (first action) :reader) (eq (third action) :access))
      (let* ((r (nth (second action) (getf previous :readers))) (owner (getf r :owner)))
        (when (and (not (snapshot-active-p previous owner))
                   (not (getf (nth owner (getf previous :snapshots)) :pin))
                   (not (nth owner (getf previous :retained)))
                   (nth owner (getf previous :retired)))
          (push :inflight-access-after-expiry-pin-release-and-retirement names))))
    (when (some (lambda (r) (and (not (getf r :admitted-live))
                                 (eq (getf r :reply) :snapshot-too-old))) readers)
      (push :new-access-rejected-after-expiry names))
    (when (and previous (eq (first action) :reader) (eq (third action) :reject)
               (nth (getf (nth (second action) (getf previous :readers)) :owner)
                    (getf previous :reclaimed)))
      (push :new-access-rejected-after-reclaim names))
    (when (some (lambda (r) (and (getf r :admitted-live)
                                 (eq (getf r :reply) :snapshot-too-old)
                                 (= (length (getf r :samples)) 2))) readers)
      (push :inflight-response-invalidated-after-search names))
    (when (some (lambda (r) (and (getf r :admitted-live)
                                 (eq (getf r :location) :missing)
                                 (eq (getf r :reply) :snapshot-too-old))) readers)
      (push :inflight-missing-reported-too-old names))
    (dotimes (v 2)
      (let ((retired-at (nth v (getf state :retired))))
        (when (and retired-at (not (nth v (getf state :reclaimed)))
                   (not (epochs-clear-p state retired-at)))
          (pushnew :old-epoch-blocks-reclaim names))))
    (when (and previous (eq (first action) :reclaim-version) (eql (second action) 0)
               (first (getf state :reclaimed)) (getf (second readers) :epoch)
               (eql (getf (second readers) :location) 1))
      (push :old-resource-reclaimed-with-newer-reader-active names))
    (when (and (= (getf state :threshold) 1)
               (not (getf (first (getf state :snapshots)) :pin))
               (getf (second (getf state :snapshots)) :pin))
      (push :minimum-recounted-with-one-pin-remaining names))
    (when (lifetime-terminal-p state) (push :terminal names))
    names))

;;; Witness ricostruiti con gli stessi passi puri e validati prima di restituirli.
(defun path-to (state parents)
  (arcdocdb.spk07::witness state parents))

(defun replay (initial actions successors expected-state)
  (let ((state initial) (trace nil))
    (dolist (action actions)
      (let ((matches (remove-if-not (lambda (edge) (equal (car edge) action))
                                    (funcall successors state))))
        (unless (= (length matches) 1) (error \"Witness ambiguo/non abilitato: ~S\" action))
        (let ((next (cdar matches)))
          (push (list :action action :before state :after next) trace)
          (setf state next))))
    (unless (equal state expected-state) (error \"Witness termina nello stato errato\"))
    (nreverse trace)))

(defun terminal-reachability (parents predecessors terminals)
  \"Ogni stato può essere drenato; nessuna affermazione di tempo reale/fairness reale.\"
  (let ((reachable (make-hash-table :test 'equal))
        (queue (make-array 16 :adjustable t :fill-pointer 0)) (cursor 0))
    (dolist (state terminals)
      (setf (gethash state reachable) t) (vector-push-extend state queue))
    (loop while (< cursor (length queue)) do
      (let ((state (aref queue cursor)))
        (incf cursor)
        (dolist (previous (gethash state predecessors))
          (unless (gethash previous reachable)
            (setf (gethash previous reachable) t) (vector-push-extend previous queue)))))
    (unless (and terminals (= (hash-table-count reachable) (hash-table-count parents)))
      (error \"Drenabilita incompleta: ~D di ~D stati, ~D terminali\"
             (hash-table-count reachable) (hash-table-count parents) (length terminals)))
    (list :status :ok :terminal-states (length terminals)
          :states-reaching-terminal (hash-table-count reachable)
          :scheduling :abstract-enabled-steps :real-time-guarantee nil)))

(defun run-model (name initial successors violation expected coverage required
                  &key terminal-p)
  (let ((parents (make-hash-table :test 'equal))
        (predecessors (make-hash-table :test 'equal))
        (covered (make-hash-table :test 'eq)) (terminals nil)
        (reclaim-audits 0) (epoch-blocked-states 0))
    (setf (gethash initial parents) (cons nil nil))
    (let* ((report
             (arcdocdb.spk07::require-outcome
              (arcdocdb.spk07::explore
               name initial
               (lambda (state)
                 (let ((edges (funcall successors state)))
                   (dolist (edge edges)
                     (unless (nth-value 1 (gethash (cdr edge) parents))
                       (setf (gethash (cdr edge) parents) (cons state (car edge))))
                     (when terminal-p (push state (gethash (cdr edge) predecessors)))
                     (when (and terminal-p (eq (caar edge) :reclaim-version))
                       (let* ((v (second (car edge))) (r (nth v (getf state :retired))))
                         (unless (and r (not (logical-reference-p state v)) (epochs-clear-p state r))
                           (error \"Reclaim senza grace period: ~S ~S\" (car edge) state))
                         (incf reclaim-audits)))
                     (dolist (label (funcall coverage (cdr edge) state (car edge)))
                       (unless (gethash label covered)
                         (setf (gethash label covered)
                               (list :state (cdr edge) :previous state :action (car edge))))))
                   edges))
               (lambda (state)
                 (when terminal-p
                   (when (loop for r in (getf state :retired) for v from 0 thereis
                           (and r (not (nth v (getf state :reclaimed))) (not (epochs-clear-p state r))))
                     (incf epoch-blocked-states)))
                 (when (and terminal-p (funcall terminal-p state)) (push state terminals))
                 (funcall violation state))
               :limit +state-limit+) expected))
           (actual (getf (getf report :violation) :kind)))
      (unless (eq actual expected)
        (error \"Violazione specifica attesa ~S, ottenuta ~S: ~S\" expected actual report))
      (if expected
          (let ((actions (getf report :witness)) (state (getf report :state)))
            (unless actions (error \"Controllo negativo senza witness\"))
            (append report (list :status :expected-counterexample
                                 :trace (replay initial actions successors state))))
          (let ((coverage-reports nil))
            (dolist (label required)
              (let* ((entry (or (gethash label covered) (error \"Copertura assente: ~S\" label)))
                     (state (getf entry :state))
                     (actions (append (path-to (getf entry :previous) parents)
                                      (list (getf entry :action)))))
                (push (list :name label :witness actions
                            :trace (replay initial actions successors state) :state state)
                      coverage-reports)))
            (unless (= (getf report :states) (hash-table-count parents))
              (error \"Conteggio BFS incoerente\"))
            (setf coverage-reports (nreverse coverage-reports))
            (append report
                    (list :status :ok :coverage coverage-reports
                          :coverage-count (length coverage-reports)
                          :reclaim-transitions-audited reclaim-audits
                          :epoch-blocked-states epoch-blocked-states
                          :terminal (when terminal-p
                                      (terminal-reachability parents predecessors terminals)))))))))

(defun check ()
  \"Esaurisce i due grafi corretti, trova e riesegue cinque controlli negativi.\"
  (let ((positive nil) (negative nil))
    (push (run-model :registration (registration-initial)
                     (lambda (s) (registration-edges s nil)) #'registration-violation nil
                     #'registration-coverage
                     '(:writer-sampled-before-announcement :writer-observed-announcement
                       :repeatable-registration-view)) positive)
    (push (run-model :lifetime (lifetime-initial)
                     (lambda (s) (lifetime-edges s nil)) #'lifetime-violation nil
                     #'lifetime-coverage
                     '(:snapshot-pin-blocks-prune :two-successful-operations-same-snapshot
                       :inflight-access-after-expiry-pin-release-and-retirement
                       :new-access-rejected-after-expiry :new-access-rejected-after-reclaim
                       :inflight-response-invalidated-after-search :inflight-missing-reported-too-old
                       :old-epoch-blocks-reclaim :old-resource-reclaimed-with-newer-reader-active
                       :minimum-recounted-with-one-pin-remaining :terminal)
                     :terminal-p #'lifetime-terminal-p) positive)
    (dolist (case '((:expiry-ignores-readers :access-after-reclaim)
                    (:admit-after-expiry :admission-after-expiry)
                    (:no-threshold-recount :threshold-stale-after-release)))
      (destructuring-bind (mutant expected) case
        (push (run-model mutant (lifetime-initial)
                         (lambda (s) (lifetime-edges s mutant)) #'lifetime-violation expected
                         (constantly nil) nil) negative)))
    (dolist (case '((:omit-registration-threshold :snapshot-view-changed)
                    (:birth-before-horizon :birth-before-horizon)))
      (destructuring-bind (mutant expected) case
        (push (run-model mutant (registration-initial)
                         (lambda (s) (registration-edges s mutant)) #'registration-violation expected
                         (constantly nil) nil) negative)))
    (setf positive (nreverse positive) negative (nreverse negative))
    (list :spike :spk-07 :module :scadenza :status :ok :positive positive :negative negative
          :counts (list :positive-models (length positive) :negative-controls (length negative)
                        :positive-states (reduce #'+ positive :key (lambda (r) (getf r :states)))
                        :positive-edges (reduce #'+ positive :key (lambda (r) (getf r :edges)))
                        :negative-states-discovered
                        (reduce #'+ negative :key (lambda (r) (getf r :states)))
                        :negative-edges-before-witness
                        (reduce #'+ negative :key (lambda (r) (getf r :edges)))
                        :positive-coverage-witnesses
                        (reduce #'+ positive :key (lambda (r) (getf r :coverage-count))))
          :bounds '(:registration-commits 1 :registration-snapshots 1 :registration-reads 2
                    :lifetime-snapshots 2 :lifetime-readers 3 :samples-per-reader 2
                    :external-resources 2 :additional-commits 1 :ticks 2 :retirements 2
                    :maximum-epoch 2)
          :state-limit +state-limit+
          :assumptions '(:sequential-consistency :atomic-abstract-steps :immutable-values
                         :atomic-admission-and-epoch-publication :atomic-response-validation
                         :one-attempt-per-reader :independent-registration-and-lifetime-graphs
                         :abstract-scheduling-only :no-csn-or-epoch-wraparound)
          :limits '(:weak-memory :real-time-lease-guarantees :blocked-reader-time-bound
                    :unbounded-configurations :concrete-engine :disk-io :crashes :crc
                    :cache :relocation :transactions :series-health)
          :conflicts '((:source :adr-0016 :issue :bounded-delay-with-blocked-reader
                        :resolution :no-real-time-claim-no-decision-change))
          :gate :open :contribution :bounded-snapshot-expiry-and-reader-reclamation)))
")
  (:PATH
   #A((82) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/metodo-scadenza.md")
   :ENCODING :UTF-8 :OCTET-COUNT 8468 :CONTENT
   "# SPK-07 — Metodo preregistrato: scadenza, reader ed epoche

Metodo registrato il 2026-10-08 prima dell'implementazione e delle esecuzioni.
Ambito: solo `scadenza.lisp`, questo metodo e nuovi artefatti esclusivi in
`spikes/SPK-07-protocols/out/`. Common Lisp/SBCL, `safety 3`, nessun motore,
benchmark, modifica delle decisioni o operazione Git.

## Fonti e interpretazione

Letti ADR-0033 §§8–9 (errori definiti, limiti controllati), ADR-0038 §§3–4
(registrazione, soglia, attesa `H >= s`, verifica dopo la ricerca), ADR-0020
(durata massima e `snapshot-too-old`), ADR-0016 (EBR), architettura
§§Reclaim/Snapshot e MVCC, `06-mvcc-e-snapshot.md`, INV-M1/M2/M4 e INV-R1.
Si usa soltanto il significato di H: il vecchio anello di ADR-0038 §2 è già
sostituito da ADR-0046, come indicano architettura e intestazione di ADR-0038.

Il pin snapshot rappresenta l'iscrizione del CSN nel registro, non un puntatore
diretto al segmento. Scadenza, rimozione del pin, potatura, ritiro ed eliminazione
sono passi distinti. Un reader entrato pubblica la propria epoca e la mantiene
fino all'uscita, anche se nel frattempo lo snapshot scade. La risposta viene
validata dopo la ricerca: una lettura già iniziata può accedere a bytes protetti,
ma restituisce `snapshot-too-old` se lo snapshot è scaduto alla validazione.
Validazione e fissazione della risposta sono un unico passo astratto.

## Modelli finiti e oracoli

1. **Registrazione:** un documento, versioni immutabili 0/1, un writer con
   assegnazione CSN, lettura della soglia, pubblicazione e avanzamento di H
   separati; uno snapshot con annuncio conservativo `min(soglia,H)`, acquisizione
   di s e nascita separati; due letture. Si enumerano gli interleaving, compresa
   la soglia campionata prima dell'annuncio. Il valore atteso deriva dal CSN
   dello snapshot e dalla storia logica fissa, indipendentemente dalle location
   mantenute. Nascita e prima lettura richiedono H >= s; entrambe le letture
   devono restituire il valore atteso.
2. **Lifetime:** stato iniziale raggiungibile con snapshot S0 a s=0, S1 a s=1,
   H=1, versione corrente 1 e versione 0 trattenuta. Una pubblicazione atomica
   ulteriore porta a CSN/H=2. Due risorse esterne immutabili (versioni 0/1),
   tre tentativi di lettura (due di S0, uno di S1), due campioni per lettura,
   epoca globale 0..2, due ritiri e due reclaim al massimo. Ogni lettura separa
   ammissione/pubblicazione epoca, ricerca location, due accessi, validazione
   della risposta e rilascio dell'epoca. Una ricerca dopo potatura può fallire
   solo per uno snapshot ormai scaduto, con risposta `snapshot-too-old`.

Tick globali 0..2; scadenza eleggibile a tick 1 per S0 e 2 per S1. Sono soltanto
un ordine astratto per enumerare le corse: non modellano un orologio, la durata
reale delle lease o una garanzia in secondi. L'evento di scadenza è il punto
astratto di invalidazione. Non si inferisce una garanzia temporale da un tick.

Oracoli: vista immutata per ogni accesso ammesso; nessun accesso a bytes
eliminati; nessuna ammissione su snapshot scaduto; risposta positiva solo quando
attivo al punto di validazione; soglia ricalcolata sul minimo dei pin rimasti
dopo ogni rimozione; reclaim soltanto senza riferimenti logici e dopo tutte le
epoche <= epoca di ritiro. Il confronto di epoche è stretto (`reader > r`).

Si controlla che da **ogni** stato lifetime raggiunto esista un percorso verso
il terminale (pubblicazione, tick finali, scadenze, rilascio pin, completamento o
rifiuto di tutti i reader, potatura, ritiro e reclaim). Si usa raggiungibilità
inversa sul grafo completo; non basta osservare un solo terminale. Questo prova
solo drenabilità con scheduling astratto che esegue i passi abilitati, senza
garanzia di progresso per uno scheduler che non li esegue.

## Controlli negativi e witness

Mutanti obbligatori: `:expiry-ignores-readers` elimina una risorsa dopo la
scadenza ignorando le epoche attive; `:admit-after-expiry` ammette nuovi reader;
`:no-threshold-recount` lascia la vecchia soglia dopo rimozione del pin minimo.
L'ultimo è un errore di riconta e sovratrattenimento, non una perdita di bytes:
il witness deve rendere espliciti pin residui, soglia attesa ed effettiva.
Controlli supplementari: annuncio della soglia omesso nella registrazione e
nascita anticipata prima di H. Ogni mutante deve produrre la violazione
specifica attesa e un percorso non vuoto, rieseguito e corredato di stati
prima/dopo; un controesempio generico non basta.

I risultati positivi richiedono anche witness di copertura: writer che campiona
la soglia prima/dopo l'annuncio, letture ripetute dello stesso snapshot,
snapshot attivo che impedisce potatura, accesso in corso dopo scadenza e rilascio
pin, rifiuto nuovo accesso, risposta scaduta dopo ricerca, reclaim vecchio con
reader più nuovo ancora attivo, terminale. I conteggi sono misurati dal grafo.

## Esecuzione e registrazione

`CHECK` esportato da `arcdocdb.spk07.scadenza` restituisce una plist con
`:status :ok`, rapporti positivi, controlli negativi, witness, conteggi e
assunzioni. Usa l'esploratore e `require-outcome` del core esistente, caricato
prima del modulo, aggiungendo il confronto esatto della violazione attesa.
Limite iniziale: 500.000 stati per esplorazione; un limite esaurito è fallimento.

Ogni tentativo di compilazione/check ha un nuovo record leggibile come dati
con `*read-eval* nil`, schema 1, in `out/scadenza-attempt-NNN.sexp`.
Il record conserva argv, cwd e stdin esatto; ambiente SBCL/OS/macchina,
contenuto integrale dei sorgenti (blob senza Git), risultati `compile-file`,
conteggi warning/style-warning, risultato o condizione registrata, limiti e
raw stdout/stderr. Un harness solo Common Lisp, fornito via stdin e conservato
nel record, compila core e modulo in FASL nuovi in `out/`, controlla tutti i
valori di `compile-file`, carica core prima del modulo e invoca un solo CHECK.
Warning e style-warning sono fatali anche durante caricamento/check. Il
confine harness registra condizioni e stato di fallimento, poi esce non zero.

## Tentativi locali

Il tentativo 001 è fallito in compilazione per una parentesi chiusa in eccesso
in `run-model`; core compilato/caricato, CHECK non eseguito, zero warning e
style-warning. Il record `out/scadenza-attempt-001.sexp` conserva l'errore e i
blob precedenti alla correzione. Prima del tentativo successivo si corregge la
parentesi e si rende la copertura delle corse dipendente dalla transizione
effettiva: un accesso dopo scadenza e pin rimosso, e un reclaim mentre il reader
più nuovo è già attivo. Ogni reclaim del grafo positivo è anche verificato
indipendentemente dalla guardia delle transizioni contro riferimenti ed epoche.

Il tentativo 002 ha compilato entrambi i file senza warning/style-warning e
concluso CHECK con `:status :ok`: registrazione 51 stati/69 archi; lifetime
67.507 stati/256.902 archi, 128 terminali e tutti gli stati drenabili; i cinque
mutanti hanno prodotto le violazioni specifiche attese. Il record 002 contiene
tutti i witness, ma il contatore di copertura è errato (2 anziché 12), perché
calcolato dopo un `nreverse` senza conservarne la nuova testa. Prima del
tentativo 003 si corregge il contatore e si richiedono altri due witness:
rifiuto di una nuova lettura dopo reclaim già avvenuto, e lettura ammessa prima
della scadenza che trova la location potata e risponde `snapshot-too-old`.
Queste modifiche non estendono il grafo degli stati.

## Limiti e conflitti

Atomicità dei passi e memoria sequenzialmente consistente assunte; barriere,
memoria debole, ARM64/SBCL macchina, filesystem, CRC, crash, I/O, cache,
rilocazione/compaction concreta, wraparound CSN/epoche, transazioni, salute
Serie/Archivio e carichi arbitrari sono fuori ambito. Le risorse rappresentano
bytes/descrittori esterni; directory e frammenti heap restano sotto GC.
Il lifetime parte da una registrazione già conclusa; la race di nascita è
esaurita separatamente, non nel prodotto dei due modelli. L'aggancio fra
controllo attività e pubblicazione epoca è un passo atomico assunto.

Nessuna decisione cambiata. ADR-0016 contiene una frase di ritardo massimo
«millisecondi–secondi, mai di più» insieme alla possibilità che un worker
bloccato trattenga il reclaim: il modello non può sostenere quel limite reale
senza un'ipotesi sul completamento dei reader. Si segnala questa tensione e si
verifica soltanto il progresso terminale sotto scheduling astratto.
"))
 :COMPILE-STATUS
 (:STATUS :OK :WARNING-COUNT 0 :STYLE-WARNING-COUNT 0 :UNITS
  ((:SOURCE "core.lisp" :FASL
    #A((98) BASE-CHAR
       . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/scadenza-attempt-003-core.fasl")
    :WARNINGS-P NIL :FAILURE-P NIL :STATUS :OK)
   (:SOURCE "scadenza.lisp" :FASL
    #A((102) BASE-CHAR
       . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/scadenza-attempt-003-scadenza.fasl")
    :WARNINGS-P NIL :FAILURE-P NIL :STATUS :OK)))
 :RESULT
 (:SPIKE :SPK-07 :MODULE :SCADENZA :STATUS :OK :POSITIVE
  ((:MODEL :REGISTRATION :STATES 51 :EDGES 69 :VIOLATION NIL :STATUS :OK
    :COVERAGE
    ((:NAME :WRITER-SAMPLED-BEFORE-ANNOUNCEMENT :WITNESS
      ((:WRITER :ASSIGN-CSN) (:WRITER :SAMPLE-THRESHOLD)
       (:WRITER :PUBLISH-VERSION) (:WRITER :ADVANCE-HORIZON)
       (:SNAPSHOT :ANNOUNCE-THRESHOLD) (:SNAPSHOT :CAPTURE-CSN)
       (:SNAPSHOT :BORN))
      :TRACE
      ((:ACTION (:WRITER :ASSIGN-CSN) :BEFORE
        (:WRITER 0 :REGISTRATION 0 :THRESHOLD 3 :CSN NIL :HORIZON 0 :KEEP-OLD
         NIL :CURRENT 0 :READS NIL)
        :AFTER
        (:WRITER 1 :REGISTRATION 0 :THRESHOLD 3 :CSN NIL :HORIZON 0 :KEEP-OLD
         NIL :CURRENT 0 :READS NIL))
       (:ACTION (:WRITER :SAMPLE-THRESHOLD) :BEFORE
        (:WRITER 1 :REGISTRATION 0 :THRESHOLD 3 :CSN NIL :HORIZON 0 :KEEP-OLD
         NIL :CURRENT 0 :READS NIL)
        :AFTER
        (:WRITER 2 :REGISTRATION 0 :THRESHOLD 3 :CSN NIL :HORIZON 0 :KEEP-OLD
         NIL :CURRENT 0 :READS NIL))
       (:ACTION (:WRITER :PUBLISH-VERSION) :BEFORE
        (:WRITER 2 :REGISTRATION 0 :THRESHOLD 3 :CSN NIL :HORIZON 0 :KEEP-OLD
         NIL :CURRENT 0 :READS NIL)
        :AFTER
        (:WRITER 3 :REGISTRATION 0 :THRESHOLD 3 :CSN NIL :HORIZON 0 :KEEP-OLD
         NIL :CURRENT 1 :READS NIL))
       (:ACTION (:WRITER :ADVANCE-HORIZON) :BEFORE
        (:WRITER 3 :REGISTRATION 0 :THRESHOLD 3 :CSN NIL :HORIZON 0 :KEEP-OLD
         NIL :CURRENT 1 :READS NIL)
        :AFTER
        (:WRITER 4 :REGISTRATION 0 :THRESHOLD 3 :CSN NIL :HORIZON 1 :KEEP-OLD
         NIL :CURRENT 1 :READS NIL))
       (:ACTION (:SNAPSHOT :ANNOUNCE-THRESHOLD) :BEFORE
        (:WRITER 4 :REGISTRATION 0 :THRESHOLD 3 :CSN NIL :HORIZON 1 :KEEP-OLD
         NIL :CURRENT 1 :READS NIL)
        :AFTER
        (:WRITER 4 :REGISTRATION 1 :THRESHOLD 1 :CSN NIL :HORIZON 1 :KEEP-OLD
         NIL :CURRENT 1 :READS NIL))
       (:ACTION (:SNAPSHOT :CAPTURE-CSN) :BEFORE
        (:WRITER 4 :REGISTRATION 1 :THRESHOLD 1 :CSN NIL :HORIZON 1 :KEEP-OLD
         NIL :CURRENT 1 :READS NIL)
        :AFTER
        (:WRITER 4 :REGISTRATION 2 :THRESHOLD 1 :CSN 1 :HORIZON 1 :KEEP-OLD NIL
         :CURRENT 1 :READS NIL))
       (:ACTION (:SNAPSHOT :BORN) :BEFORE
        (:WRITER 4 :REGISTRATION 2 :THRESHOLD 1 :CSN 1 :HORIZON 1 :KEEP-OLD NIL
         :CURRENT 1 :READS NIL)
        :AFTER
        (:WRITER 4 :REGISTRATION 3 :THRESHOLD 1 :CSN 1 :HORIZON 1 :KEEP-OLD NIL
         :CURRENT 1 :READS NIL)))
      :STATE
      (:WRITER 4 :REGISTRATION 3 :THRESHOLD 1 :CSN 1 :HORIZON 1 :KEEP-OLD NIL
       :CURRENT 1 :READS NIL))
     (:NAME :WRITER-OBSERVED-ANNOUNCEMENT :WITNESS
      ((:SNAPSHOT :ANNOUNCE-THRESHOLD) (:SNAPSHOT :CAPTURE-CSN)
       (:WRITER :ASSIGN-CSN) (:WRITER :SAMPLE-THRESHOLD)
       (:WRITER :PUBLISH-VERSION) (:SNAPSHOT :BORN))
      :TRACE
      ((:ACTION (:SNAPSHOT :ANNOUNCE-THRESHOLD) :BEFORE
        (:WRITER 0 :REGISTRATION 0 :THRESHOLD 3 :CSN NIL :HORIZON 0 :KEEP-OLD
         NIL :CURRENT 0 :READS NIL)
        :AFTER
        (:WRITER 0 :REGISTRATION 1 :THRESHOLD 0 :CSN NIL :HORIZON 0 :KEEP-OLD
         NIL :CURRENT 0 :READS NIL))
       (:ACTION (:SNAPSHOT :CAPTURE-CSN) :BEFORE
        (:WRITER 0 :REGISTRATION 1 :THRESHOLD 0 :CSN NIL :HORIZON 0 :KEEP-OLD
         NIL :CURRENT 0 :READS NIL)
        :AFTER
        (:WRITER 0 :REGISTRATION 2 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
         :CURRENT 0 :READS NIL))
       (:ACTION (:WRITER :ASSIGN-CSN) :BEFORE
        (:WRITER 0 :REGISTRATION 2 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
         :CURRENT 0 :READS NIL)
        :AFTER
        (:WRITER 1 :REGISTRATION 2 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
         :CURRENT 0 :READS NIL))
       (:ACTION (:WRITER :SAMPLE-THRESHOLD) :BEFORE
        (:WRITER 1 :REGISTRATION 2 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
         :CURRENT 0 :READS NIL)
        :AFTER
        (:WRITER 2 :REGISTRATION 2 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD T
         :CURRENT 0 :READS NIL))
       (:ACTION (:WRITER :PUBLISH-VERSION) :BEFORE
        (:WRITER 2 :REGISTRATION 2 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD T
         :CURRENT 0 :READS NIL)
        :AFTER
        (:WRITER 3 :REGISTRATION 2 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD T
         :CURRENT 1 :READS NIL))
       (:ACTION (:SNAPSHOT :BORN) :BEFORE
        (:WRITER 3 :REGISTRATION 2 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD T
         :CURRENT 1 :READS NIL)
        :AFTER
        (:WRITER 3 :REGISTRATION 3 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD T
         :CURRENT 1 :READS NIL)))
      :STATE
      (:WRITER 3 :REGISTRATION 3 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD T
       :CURRENT 1 :READS NIL))
     (:NAME :REPEATABLE-REGISTRATION-VIEW :WITNESS
      ((:SNAPSHOT :ANNOUNCE-THRESHOLD) (:SNAPSHOT :CAPTURE-CSN)
       (:SNAPSHOT :BORN) (:SNAPSHOT :READ :CSN 0 :OBSERVED 100)
       (:SNAPSHOT :READ :CSN 0 :OBSERVED 100))
      :TRACE
      ((:ACTION (:SNAPSHOT :ANNOUNCE-THRESHOLD) :BEFORE
        (:WRITER 0 :REGISTRATION 0 :THRESHOLD 3 :CSN NIL :HORIZON 0 :KEEP-OLD
         NIL :CURRENT 0 :READS NIL)
        :AFTER
        (:WRITER 0 :REGISTRATION 1 :THRESHOLD 0 :CSN NIL :HORIZON 0 :KEEP-OLD
         NIL :CURRENT 0 :READS NIL))
       (:ACTION (:SNAPSHOT :CAPTURE-CSN) :BEFORE
        (:WRITER 0 :REGISTRATION 1 :THRESHOLD 0 :CSN NIL :HORIZON 0 :KEEP-OLD
         NIL :CURRENT 0 :READS NIL)
        :AFTER
        (:WRITER 0 :REGISTRATION 2 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
         :CURRENT 0 :READS NIL))
       (:ACTION (:SNAPSHOT :BORN) :BEFORE
        (:WRITER 0 :REGISTRATION 2 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
         :CURRENT 0 :READS NIL)
        :AFTER
        (:WRITER 0 :REGISTRATION 3 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
         :CURRENT 0 :READS NIL))
       (:ACTION (:SNAPSHOT :READ :CSN 0 :OBSERVED 100) :BEFORE
        (:WRITER 0 :REGISTRATION 3 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
         :CURRENT 0 :READS NIL)
        :AFTER
        (:WRITER 0 :REGISTRATION 3 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
         :CURRENT 0 :READS (100)))
       (:ACTION (:SNAPSHOT :READ :CSN 0 :OBSERVED 100) :BEFORE
        (:WRITER 0 :REGISTRATION 3 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
         :CURRENT 0 :READS (100))
        :AFTER
        (:WRITER 0 :REGISTRATION 3 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
         :CURRENT 0 :READS (100 100))))
      :STATE
      (:WRITER 0 :REGISTRATION 3 :THRESHOLD 0 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS (100 100))))
    :COVERAGE-COUNT 3 :RECLAIM-TRANSITIONS-AUDITED 0 :EPOCH-BLOCKED-STATES 0
    :TERMINAL NIL)
   (:MODEL :LIFETIME :STATES 67507 :EDGES 256902 :VIOLATION NIL :STATUS :OK
    :COVERAGE
    ((:NAME :SNAPSHOT-PIN-BLOCKS-PRUNE :WITNESS
      ((:WRITER :PUBLISH-CSN-2-AND-HORIZON)) :TRACE
      ((:ACTION (:WRITER :PUBLISH-CSN-2-AND-HORIZON) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED T :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T T) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)))
      :STATE
      (:PUBLISHED T :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T T) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:NAME :TWO-SUCCESSFUL-OPERATIONS-SAME-SNAPSHOT :WITNESS
      ((:READER 0 :ADMIT :SNAPSHOT 0 :EPOCH 0) (:READER 0 :LOOKUP :LOCATION 0)
       (:READER 0 :ACCESS :VERSION 0 :OBSERVED 100)
       (:READER 0 :ACCESS :VERSION 0 :OBSERVED 100)
       (:READER 0 :VALIDATE-RESPONSE :REPLY :OK)
       (:READER 2 :ADMIT :SNAPSHOT 0 :EPOCH 0) (:READER 2 :LOOKUP :LOCATION 0)
       (:READER 2 :ACCESS :VERSION 0 :OBSERVED 100)
       (:READER 2 :ACCESS :VERSION 0 :OBSERVED 100)
       (:READER 2 :VALIDATE-RESPONSE :REPLY :OK))
      :TRACE
      ((:ACTION (:READER 0 :ADMIT :SNAPSHOT 0 :EPOCH 0) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :LOOKUP :LOCATION 0) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :ACCESS :VERSION 0 :OBSERVED 100) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :READ-ONCE :EPOCH 0 :LOCATION 0 :SAMPLES (100)
           :REPLY NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :ACCESS :VERSION 0 :OBSERVED 100) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :READ-ONCE :EPOCH 0 :LOCATION 0 :SAMPLES (100)
           :REPLY NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :READ-TWICE :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :VALIDATE-RESPONSE :REPLY :OK) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :READ-TWICE :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY :OK :ADMITTED-LIVE T :VALIDATED-LIVE T)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 2 :ADMIT :SNAPSHOT 0 :EPOCH 0) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY :OK :ADMITTED-LIVE T :VALIDATED-LIVE T)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY :OK :ADMITTED-LIVE T :VALIDATED-LIVE T)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 2 :LOOKUP :LOCATION 0) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY :OK :ADMITTED-LIVE T :VALIDATED-LIVE T)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY :OK :ADMITTED-LIVE T :VALIDATED-LIVE T)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 2 :ACCESS :VERSION 0 :OBSERVED 100) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY :OK :ADMITTED-LIVE T :VALIDATED-LIVE T)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY :OK :ADMITTED-LIVE T :VALIDATED-LIVE T)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :READ-ONCE :EPOCH 0 :LOCATION 0 :SAMPLES (100)
           :REPLY NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 2 :ACCESS :VERSION 0 :OBSERVED 100) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY :OK :ADMITTED-LIVE T :VALIDATED-LIVE T)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :READ-ONCE :EPOCH 0 :LOCATION 0 :SAMPLES (100)
           :REPLY NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY :OK :ADMITTED-LIVE T :VALIDATED-LIVE T)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :READ-TWICE :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 2 :VALIDATE-RESPONSE :REPLY :OK) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY :OK :ADMITTED-LIVE T :VALIDATED-LIVE T)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :READ-TWICE :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY :OK :ADMITTED-LIVE T :VALIDATED-LIVE T)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY :OK :ADMITTED-LIVE T :VALIDATED-LIVE T))
         :FAILURE NIL)))
      :STATE
      (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
         :REPLY :OK :ADMITTED-LIVE T :VALIDATED-LIVE T)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
         :REPLY :OK :ADMITTED-LIVE T :VALIDATED-LIVE T))
       :FAILURE NIL))
     (:NAME :INFLIGHT-ACCESS-AFTER-EXPIRY-PIN-RELEASE-AND-RETIREMENT :WITNESS
      ((:ABSTRACT-TICK 1) (:READER 0 :ADMIT :SNAPSHOT 0 :EPOCH 0)
       (:EXPIRE :SNAPSHOT 0)
       (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1)
       (:READER 0 :LOOKUP :LOCATION 0) (:PRUNE-RETAINED-VERSION 0 :THRESHOLD 1)
       (:RETIRE-VERSION 0 :RETIRED-AT 0)
       (:READER 0 :ACCESS :VERSION 0 :OBSERVED 100))
      :TRACE
      ((:ACTION (:ABSTRACT-TICK 1) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :ADMIT :SNAPSHOT 0 :EPOCH 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:EXPIRE :SNAPSHOT 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION
        (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1)
        :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :LOOKUP :LOCATION 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:PRUNE-RETAINED-VERSION 0 :THRESHOLD 1) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:RETIRE-VERSION 0 :RETIRED-AT 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :ACCESS :VERSION 0 :OBSERVED 100) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :READ-ONCE :EPOCH 0 :LOCATION 0 :SAMPLES (100)
           :REPLY NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)))
      :STATE
      (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :READ-ONCE :EPOCH 0 :LOCATION 0 :SAMPLES (100) :REPLY
         NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:NAME :NEW-ACCESS-REJECTED-AFTER-EXPIRY :WITNESS
      ((:ABSTRACT-TICK 1) (:EXPIRE :SNAPSHOT 0)
       (:READER 0 :REJECT :SNAPSHOT-TOO-OLD))
      :TRACE
      ((:ACTION (:ABSTRACT-TICK 1) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:EXPIRE :SNAPSHOT 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :REJECT :SNAPSHOT-TOO-OLD) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)))
      :STATE
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
         :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:NAME :NEW-ACCESS-REJECTED-AFTER-RECLAIM :WITNESS
      ((:ABSTRACT-TICK 1) (:EXPIRE :SNAPSHOT 0)
       (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1)
       (:PRUNE-RETAINED-VERSION 0 :THRESHOLD 1)
       (:RETIRE-VERSION 0 :RETIRED-AT 0)
       (:RECLAIM-VERSION 0 :RETIRED-AT 0 :READER-EPOCHS (NIL NIL NIL))
       (:READER 0 :REJECT :SNAPSHOT-TOO-OLD))
      :TRACE
      ((:ACTION (:ABSTRACT-TICK 1) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:EXPIRE :SNAPSHOT 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION
        (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1)
        :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:PRUNE-RETAINED-VERSION 0 :THRESHOLD 1) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:RETIRE-VERSION 0 :RETIRED-AT 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:RECLAIM-VERSION 0 :RETIRED-AT 0 :READER-EPOCHS (NIL NIL NIL))
        :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (T NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :REJECT :SNAPSHOT-TOO-OLD) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (T NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (T NIL) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)))
      :STATE
      (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (T NIL) :READERS
       ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
         :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:NAME :INFLIGHT-RESPONSE-INVALIDATED-AFTER-SEARCH :WITNESS
      ((:ABSTRACT-TICK 1) (:READER 0 :ADMIT :SNAPSHOT 0 :EPOCH 0)
       (:EXPIRE :SNAPSHOT 0) (:READER 0 :LOOKUP :LOCATION 0)
       (:READER 0 :ACCESS :VERSION 0 :OBSERVED 100)
       (:READER 0 :ACCESS :VERSION 0 :OBSERVED 100)
       (:READER 0 :VALIDATE-RESPONSE :REPLY :SNAPSHOT-TOO-OLD))
      :TRACE
      ((:ACTION (:ABSTRACT-TICK 1) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :ADMIT :SNAPSHOT 0 :EPOCH 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:EXPIRE :SNAPSHOT 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :LOOKUP :LOCATION 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :ACCESS :VERSION 0 :OBSERVED 100) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :READ-ONCE :EPOCH 0 :LOCATION 0 :SAMPLES (100)
           :REPLY NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :ACCESS :VERSION 0 :OBSERVED 100) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :READ-ONCE :EPOCH 0 :LOCATION 0 :SAMPLES (100)
           :REPLY NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :READ-TWICE :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :VALIDATE-RESPONSE :REPLY :SNAPSHOT-TOO-OLD) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :READ-TWICE :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
           :REPLY :SNAPSHOT-TOO-OLD :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)))
      :STATE
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION 0 :SAMPLES (100 100)
         :REPLY :SNAPSHOT-TOO-OLD :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:NAME :INFLIGHT-MISSING-REPORTED-TOO-OLD :WITNESS
      ((:ABSTRACT-TICK 1) (:READER 0 :ADMIT :SNAPSHOT 0 :EPOCH 0)
       (:EXPIRE :SNAPSHOT 0)
       (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1)
       (:PRUNE-RETAINED-VERSION 0 :THRESHOLD 1)
       (:READER 0 :LOOKUP :LOCATION :MISSING)
       (:READER 0 :VALIDATE-MISSING :SNAPSHOT-TOO-OLD))
      :TRACE
      ((:ACTION (:ABSTRACT-TICK 1) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :ADMIT :SNAPSHOT 0 :EPOCH 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:EXPIRE :SNAPSHOT 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION
        (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1)
        :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:PRUNE-RETAINED-VERSION 0 :THRESHOLD 1) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :LOOKUP :LOCATION :MISSING) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION :MISSING :SAMPLES NIL
           :REPLY NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :VALIDATE-MISSING :SNAPSHOT-TOO-OLD) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION :MISSING :SAMPLES NIL
           :REPLY NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION :MISSING :SAMPLES NIL
           :REPLY :SNAPSHOT-TOO-OLD :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)))
      :STATE
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :VALIDATED :EPOCH 0 :LOCATION :MISSING :SAMPLES NIL
         :REPLY :SNAPSHOT-TOO-OLD :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:NAME :OLD-EPOCH-BLOCKS-RECLAIM :WITNESS
      ((:ABSTRACT-TICK 1) (:EXPIRE :SNAPSHOT 0)
       (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1)
       (:READER 1 :ADMIT :SNAPSHOT 1 :EPOCH 0)
       (:PRUNE-RETAINED-VERSION 0 :THRESHOLD 1)
       (:RETIRE-VERSION 0 :RETIRED-AT 0))
      :TRACE
      ((:ACTION (:ABSTRACT-TICK 1) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:EXPIRE :SNAPSHOT 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION
        (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1)
        :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 1 :ADMIT :SNAPSHOT 1 :EPOCH 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:PRUNE-RETAINED-VERSION 0 :THRESHOLD 1) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:RETIRE-VERSION 0 :RETIRED-AT 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)))
      :STATE
      (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
         NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:NAME :OLD-RESOURCE-RECLAIMED-WITH-NEWER-READER-ACTIVE :WITNESS
      ((:ABSTRACT-TICK 1) (:EXPIRE :SNAPSHOT 0)
       (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1)
       (:PRUNE-RETAINED-VERSION 0 :THRESHOLD 1)
       (:RETIRE-VERSION 0 :RETIRED-AT 0)
       (:READER 1 :ADMIT :SNAPSHOT 1 :EPOCH 1) (:READER 1 :LOOKUP :LOCATION 1)
       (:RECLAIM-VERSION 0 :RETIRED-AT 0 :READER-EPOCHS (NIL 1 NIL)))
      :TRACE
      ((:ACTION (:ABSTRACT-TICK 1) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:EXPIRE :SNAPSHOT 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION
        (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1)
        :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:PRUNE-RETAINED-VERSION 0 :THRESHOLD 1) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:RETIRE-VERSION 0 :RETIRED-AT 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 1 :ADMIT :SNAPSHOT 1 :EPOCH 1) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :ENTERED :EPOCH 1 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 1 :LOOKUP :LOCATION 1) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :ENTERED :EPOCH 1 :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :LOCATED :EPOCH 1 :LOCATION 1 :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:RECLAIM-VERSION 0 :RETIRED-AT 0 :READER-EPOCHS (NIL 1 NIL))
        :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :LOCATED :EPOCH 1 :LOCATION 1 :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (T NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :LOCATED :EPOCH 1 :LOCATION 1 :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)))
      :STATE
      (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (T NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :LOCATED :EPOCH 1 :LOCATION 1 :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:NAME :MINIMUM-RECOUNTED-WITH-ONE-PIN-REMAINING :WITNESS
      ((:ABSTRACT-TICK 1) (:EXPIRE :SNAPSHOT 0)
       (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1))
      :TRACE
      ((:ACTION (:ABSTRACT-TICK 1) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:EXPIRE :SNAPSHOT 0) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION
        (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1)
        :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)))
      :STATE
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:NAME :TERMINAL :WITNESS
      ((:ABSTRACT-TICK 1) (:ABSTRACT-TICK 2) (:EXPIRE :SNAPSHOT 0)
       (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1)
       (:EXPIRE :SNAPSHOT 1)
       (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 1 :REMAINING-MINIMUM 3 :THRESHOLD 3)
       (:WRITER :PUBLISH-CSN-2-AND-HORIZON)
       (:READER 0 :REJECT :SNAPSHOT-TOO-OLD)
       (:READER 1 :REJECT :SNAPSHOT-TOO-OLD)
       (:READER 2 :REJECT :SNAPSHOT-TOO-OLD)
       (:PRUNE-RETAINED-VERSION 0 :THRESHOLD 3)
       (:RETIRE-VERSION 0 :RETIRED-AT 0)
       (:RECLAIM-VERSION 0 :RETIRED-AT 0 :READER-EPOCHS (NIL NIL NIL))
       (:RETIRE-VERSION 1 :RETIRED-AT 1)
       (:RECLAIM-VERSION 1 :RETIRED-AT 1 :READER-EPOCHS (NIL NIL NIL)))
      :TRACE
      ((:ACTION (:ABSTRACT-TICK 1) :BEFORE
        (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:ABSTRACT-TICK 2) :BEFORE
        (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 2 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:EXPIRE :SNAPSHOT 0) :BEFORE
        (:PUBLISHED NIL :TICK 2 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 2 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION
        (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1)
        :BEFORE
        (:PUBLISHED NIL :TICK 2 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 2 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:EXPIRE :SNAPSHOT 1) :BEFORE
        (:PUBLISHED NIL :TICK 2 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 2 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION
        (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 1 :REMAINING-MINIMUM 3 :THRESHOLD 3)
        :BEFORE
        (:PUBLISHED NIL :TICK 2 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN T :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED NIL :TICK 2 :EPOCH 0 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:WRITER :PUBLISH-CSN-2-AND-HORIZON) :BEFORE
        (:PUBLISHED NIL :TICK 2 :EPOCH 0 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED T :TICK 2 :EPOCH 0 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 0 :REJECT :SNAPSHOT-TOO-OLD) :BEFORE
        (:PUBLISHED T :TICK 2 :EPOCH 0 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED T :TICK 2 :EPOCH 0 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 1 :REJECT :SNAPSHOT-TOO-OLD) :BEFORE
        (:PUBLISHED T :TICK 2 :EPOCH 0 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED T :TICK 2 :EPOCH 0 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:READER 2 :REJECT :SNAPSHOT-TOO-OLD) :BEFORE
        (:PUBLISHED T :TICK 2 :EPOCH 0 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED T :TICK 2 :EPOCH 0 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:PRUNE-RETAINED-VERSION 0 :THRESHOLD 3) :BEFORE
        (:PUBLISHED T :TICK 2 :EPOCH 0 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED T :TICK 2 :EPOCH 0 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:RETIRE-VERSION 0 :RETIRED-AT 0) :BEFORE
        (:PUBLISHED T :TICK 2 :EPOCH 0 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED T :TICK 2 :EPOCH 1 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:RECLAIM-VERSION 0 :RETIRED-AT 0 :READER-EPOCHS (NIL NIL NIL))
        :BEFORE
        (:PUBLISHED T :TICK 2 :EPOCH 1 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED T :TICK 2 :EPOCH 1 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (T NIL) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:RETIRE-VERSION 1 :RETIRED-AT 1) :BEFORE
        (:PUBLISHED T :TICK 2 :EPOCH 1 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (T NIL) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED T :TICK 2 :EPOCH 2 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 1) :RECLAIMED (T NIL) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL))
       (:ACTION (:RECLAIM-VERSION 1 :RETIRED-AT 1 :READER-EPOCHS (NIL NIL NIL))
        :BEFORE
        (:PUBLISHED T :TICK 2 :EPOCH 2 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 1) :RECLAIMED (T NIL) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)
        :AFTER
        (:PUBLISHED T :TICK 2 :EPOCH 2 :THRESHOLD 3 :SNAPSHOTS
         ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
          (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
         :RETAINED (NIL NIL) :RETIRED (0 1) :RECLAIMED (T T) :READERS
         ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 1 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
          (:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
           :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
         :FAILURE NIL)))
      :STATE
      (:PUBLISHED T :TICK 2 :EPOCH 2 :THRESHOLD 3 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :EXPIRED :PIN NIL :DEADLINE 2))
       :RETAINED (NIL NIL) :RETIRED (0 1) :RECLAIMED (T T) :READERS
       ((:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
         :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
         :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :DONE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY
         :SNAPSHOT-TOO-OLD :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL)))
    :COVERAGE-COUNT 11 :RECLAIM-TRANSITIONS-AUDITED 3430 :EPOCH-BLOCKED-STATES
    29440 :TERMINAL
    (:STATUS :OK :TERMINAL-STATES 128 :STATES-REACHING-TERMINAL 67507
     :SCHEDULING :ABSTRACT-ENABLED-STEPS :REAL-TIME-GUARANTEE NIL)))
  :NEGATIVE
  ((:MODEL :EXPIRY-IGNORES-READERS :STATES 5291 :EDGES 16154 :VIOLATION
    (:KIND :ACCESS-AFTER-RECLAIM :READER 0 :VERSION 0 :EPOCH 0 :RETIRED-AT 0)
    :WITNESS
    ((:ABSTRACT-TICK 1) (:READER 0 :ADMIT :SNAPSHOT 0 :EPOCH 0)
     (:EXPIRE :SNAPSHOT 0)
     (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1)
     (:READER 0 :LOOKUP :LOCATION 0) (:PRUNE-RETAINED-VERSION 0 :THRESHOLD 1)
     (:RETIRE-VERSION 0 :RETIRED-AT 0)
     (:RECLAIM-VERSION 0 :RETIRED-AT 0 :READER-EPOCHS (0 NIL NIL))
     (:READER 0 :ACCESS :VERSION 0 :OBSERVED NIL))
    :STATE
    (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
     ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
      (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
     :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (T NIL) :READERS
     ((:OWNER 0 :PHASE :READ-ONCE :EPOCH 0 :LOCATION 0 :SAMPLES (NIL) :REPLY
       NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
      (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
       :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
      (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
       :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
     :FAILURE
     (:KIND :ACCESS-AFTER-RECLAIM :READER 0 :VERSION 0 :EPOCH 0 :RETIRED-AT 0))
    :STATUS :EXPECTED-COUNTEREXAMPLE :TRACE
    ((:ACTION (:ABSTRACT-TICK 1) :BEFORE
      (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL)
      :AFTER
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:ACTION (:READER 0 :ADMIT :SNAPSHOT 0 :EPOCH 0) :BEFORE
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL)
      :AFTER
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
         NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:ACTION (:EXPIRE :SNAPSHOT 0) :BEFORE
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
         NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL)
      :AFTER
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
         NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:ACTION
      (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1)
      :BEFORE
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
         NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL)
      :AFTER
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
         NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:ACTION (:READER 0 :LOOKUP :LOCATION 0) :BEFORE
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
         NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL)
      :AFTER
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:ACTION (:PRUNE-RETAINED-VERSION 0 :THRESHOLD 1) :BEFORE
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL)
      :AFTER
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:ACTION (:RETIRE-VERSION 0 :RETIRED-AT 0) :BEFORE
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (NIL NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL)
      :AFTER
      (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:ACTION (:RECLAIM-VERSION 0 :RETIRED-AT 0 :READER-EPOCHS (0 NIL NIL))
      :BEFORE
      (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL)
      :AFTER
      (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (T NIL) :READERS
       ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:ACTION (:READER 0 :ACCESS :VERSION 0 :OBSERVED NIL) :BEFORE
      (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (T NIL) :READERS
       ((:OWNER 0 :PHASE :LOCATED :EPOCH 0 :LOCATION 0 :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL)
      :AFTER
      (:PUBLISHED NIL :TICK 1 :EPOCH 1 :THRESHOLD 1 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (NIL NIL) :RETIRED (0 NIL) :RECLAIMED (T NIL) :READERS
       ((:OWNER 0 :PHASE :READ-ONCE :EPOCH 0 :LOCATION 0 :SAMPLES (NIL) :REPLY
         NIL :ADMITTED-LIVE T :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE
       (:KIND :ACCESS-AFTER-RECLAIM :READER 0 :VERSION 0 :EPOCH 0 :RETIRED-AT
        0)))))
   (:MODEL :ADMIT-AFTER-EXPIRY :STATES 108 :EDGES 192 :VIOLATION
    (:KIND :ADMISSION-AFTER-EXPIRY :READER 0 :SNAPSHOT 0) :WITNESS
    ((:ABSTRACT-TICK 1) (:EXPIRE :SNAPSHOT 0)
     (:READER 0 :ADMIT :SNAPSHOT 0 :EPOCH 0))
    :STATE
    (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
     ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
      (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
     :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
     ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY NIL
       :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
      (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
       :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
      (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
       :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
     :FAILURE NIL)
    :STATUS :EXPECTED-COUNTEREXAMPLE :TRACE
    ((:ACTION (:ABSTRACT-TICK 1) :BEFORE
      (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL)
      :AFTER
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:ACTION (:EXPIRE :SNAPSHOT 0) :BEFORE
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL)
      :AFTER
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:ACTION (:READER 0 :ADMIT :SNAPSHOT 0 :EPOCH 0) :BEFORE
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL)
      :AFTER
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :ENTERED :EPOCH 0 :LOCATION NIL :SAMPLES NIL :REPLY
         NIL :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))))
   (:MODEL :NO-THRESHOLD-RECOUNT :STATES 104 :EDGES 186 :VIOLATION
    (:KIND :THRESHOLD-STALE-AFTER-RELEASE :EXPECTED 1 :ACTUAL 0 :PINS
     ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
      (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2)))
    :WITNESS
    ((:ABSTRACT-TICK 1) (:EXPIRE :SNAPSHOT 0)
     (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 0))
    :STATE
    (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
     ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
      (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
     :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
     ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
       :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
      (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
       :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
      (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
       :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
     :FAILURE NIL)
    :STATUS :EXPECTED-COUNTEREXAMPLE :TRACE
    ((:ACTION (:ABSTRACT-TICK 1) :BEFORE
      (:PUBLISHED NIL :TICK 0 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL)
      :AFTER
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:ACTION (:EXPIRE :SNAPSHOT 0) :BEFORE
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :ACTIVE :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL)
      :AFTER
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))
     (:ACTION
      (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 0)
      :BEFORE
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN T :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL)
      :AFTER
      (:PUBLISHED NIL :TICK 1 :EPOCH 0 :THRESHOLD 0 :SNAPSHOTS
       ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
        (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2))
       :RETAINED (T NIL) :RETIRED (NIL NIL) :RECLAIMED (NIL NIL) :READERS
       ((:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 1 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL)
        (:OWNER 0 :PHASE :IDLE :EPOCH NIL :LOCATION NIL :SAMPLES NIL :REPLY NIL
         :ADMITTED-LIVE NIL :VALIDATED-LIVE NIL))
       :FAILURE NIL))))
   (:MODEL :OMIT-REGISTRATION-THRESHOLD :STATES 35 :EDGES 49 :VIOLATION
    (:KIND :SNAPSHOT-VIEW-CHANGED :CSN 0 :EXPECTED 100 :READS (NIL)) :WITNESS
    ((:SNAPSHOT :ANNOUNCE-THRESHOLD) (:SNAPSHOT :CAPTURE-CSN)
     (:WRITER :ASSIGN-CSN) (:WRITER :SAMPLE-THRESHOLD)
     (:WRITER :PUBLISH-VERSION) (:SNAPSHOT :BORN)
     (:SNAPSHOT :READ :CSN 0 :OBSERVED NIL))
    :STATE
    (:WRITER 3 :REGISTRATION 3 :THRESHOLD 3 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
     :CURRENT 1 :READS (NIL))
    :STATUS :EXPECTED-COUNTEREXAMPLE :TRACE
    ((:ACTION (:SNAPSHOT :ANNOUNCE-THRESHOLD) :BEFORE
      (:WRITER 0 :REGISTRATION 0 :THRESHOLD 3 :CSN NIL :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL)
      :AFTER
      (:WRITER 0 :REGISTRATION 1 :THRESHOLD 3 :CSN NIL :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL))
     (:ACTION (:SNAPSHOT :CAPTURE-CSN) :BEFORE
      (:WRITER 0 :REGISTRATION 1 :THRESHOLD 3 :CSN NIL :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL)
      :AFTER
      (:WRITER 0 :REGISTRATION 2 :THRESHOLD 3 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL))
     (:ACTION (:WRITER :ASSIGN-CSN) :BEFORE
      (:WRITER 0 :REGISTRATION 2 :THRESHOLD 3 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL)
      :AFTER
      (:WRITER 1 :REGISTRATION 2 :THRESHOLD 3 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL))
     (:ACTION (:WRITER :SAMPLE-THRESHOLD) :BEFORE
      (:WRITER 1 :REGISTRATION 2 :THRESHOLD 3 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL)
      :AFTER
      (:WRITER 2 :REGISTRATION 2 :THRESHOLD 3 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL))
     (:ACTION (:WRITER :PUBLISH-VERSION) :BEFORE
      (:WRITER 2 :REGISTRATION 2 :THRESHOLD 3 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL)
      :AFTER
      (:WRITER 3 :REGISTRATION 2 :THRESHOLD 3 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 1 :READS NIL))
     (:ACTION (:SNAPSHOT :BORN) :BEFORE
      (:WRITER 3 :REGISTRATION 2 :THRESHOLD 3 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 1 :READS NIL)
      :AFTER
      (:WRITER 3 :REGISTRATION 3 :THRESHOLD 3 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 1 :READS NIL))
     (:ACTION (:SNAPSHOT :READ :CSN 0 :OBSERVED NIL) :BEFORE
      (:WRITER 3 :REGISTRATION 3 :THRESHOLD 3 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 1 :READS NIL)
      :AFTER
      (:WRITER 3 :REGISTRATION 3 :THRESHOLD 3 :CSN 0 :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 1 :READS (NIL)))))
   (:MODEL :BIRTH-BEFORE-HORIZON :STATES 28 :EDGES 33 :VIOLATION
    (:KIND :BIRTH-BEFORE-HORIZON :CSN 1 :HORIZON 0) :WITNESS
    ((:WRITER :ASSIGN-CSN) (:SNAPSHOT :ANNOUNCE-THRESHOLD)
     (:SNAPSHOT :CAPTURE-CSN) (:SNAPSHOT :BORN))
    :STATE
    (:WRITER 1 :REGISTRATION 3 :THRESHOLD 0 :CSN 1 :HORIZON 0 :KEEP-OLD NIL
     :CURRENT 0 :READS NIL)
    :STATUS :EXPECTED-COUNTEREXAMPLE :TRACE
    ((:ACTION (:WRITER :ASSIGN-CSN) :BEFORE
      (:WRITER 0 :REGISTRATION 0 :THRESHOLD 3 :CSN NIL :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL)
      :AFTER
      (:WRITER 1 :REGISTRATION 0 :THRESHOLD 3 :CSN NIL :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL))
     (:ACTION (:SNAPSHOT :ANNOUNCE-THRESHOLD) :BEFORE
      (:WRITER 1 :REGISTRATION 0 :THRESHOLD 3 :CSN NIL :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL)
      :AFTER
      (:WRITER 1 :REGISTRATION 1 :THRESHOLD 0 :CSN NIL :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL))
     (:ACTION (:SNAPSHOT :CAPTURE-CSN) :BEFORE
      (:WRITER 1 :REGISTRATION 1 :THRESHOLD 0 :CSN NIL :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL)
      :AFTER
      (:WRITER 1 :REGISTRATION 2 :THRESHOLD 0 :CSN 1 :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL))
     (:ACTION (:SNAPSHOT :BORN) :BEFORE
      (:WRITER 1 :REGISTRATION 2 :THRESHOLD 0 :CSN 1 :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL)
      :AFTER
      (:WRITER 1 :REGISTRATION 3 :THRESHOLD 0 :CSN 1 :HORIZON 0 :KEEP-OLD NIL
       :CURRENT 0 :READS NIL)))))
  :COUNTS
  (:POSITIVE-MODELS 2 :NEGATIVE-CONTROLS 5 :POSITIVE-STATES 67558
   :POSITIVE-EDGES 256971 :NEGATIVE-STATES-DISCOVERED 5566
   :NEGATIVE-EDGES-BEFORE-WITNESS 16614 :POSITIVE-COVERAGE-WITNESSES 14)
  :BOUNDS
  (:REGISTRATION-COMMITS 1 :REGISTRATION-SNAPSHOTS 1 :REGISTRATION-READS 2
   :LIFETIME-SNAPSHOTS 2 :LIFETIME-READERS 3 :SAMPLES-PER-READER 2
   :EXTERNAL-RESOURCES 2 :ADDITIONAL-COMMITS 1 :TICKS 2 :RETIREMENTS 2
   :MAXIMUM-EPOCH 2)
  :STATE-LIMIT 500000 :ASSUMPTIONS
  (:SEQUENTIAL-CONSISTENCY :ATOMIC-ABSTRACT-STEPS :IMMUTABLE-VALUES
   :ATOMIC-ADMISSION-AND-EPOCH-PUBLICATION :ATOMIC-RESPONSE-VALIDATION
   :ONE-ATTEMPT-PER-READER :INDEPENDENT-REGISTRATION-AND-LIFETIME-GRAPHS
   :ABSTRACT-SCHEDULING-ONLY :NO-CSN-OR-EPOCH-WRAPAROUND)
  :LIMITS
  (:WEAK-MEMORY :REAL-TIME-LEASE-GUARANTEES :BLOCKED-READER-TIME-BOUND
   :UNBOUNDED-CONFIGURATIONS :CONCRETE-ENGINE :DISK-IO :CRASHES :CRC :CACHE
   :RELOCATION :TRANSACTIONS :SERIES-HEALTH)
  :CONFLICTS
  ((:SOURCE :ADR-0016 :ISSUE :BOUNDED-DELAY-WITH-BLOCKED-READER :RESOLUTION
    :NO-REAL-TIME-CLAIM-NO-DECISION-CHANGE))
  :GATE :OPEN :CONTRIBUTION :BOUNDED-SNAPSHOT-EXPIRY-AND-READER-RECLAMATION)
 :LIMITS
 (:STATES-PER-MODEL 500000 :TICKS 2 :SNAPSHOT-COUNT 2 :READER-COUNT 3
  :SAMPLES-PER-READER 2 :RETIREMENTS 2 :MEMORY-MODEL :SEQUENTIAL-CONSISTENCY
  :REAL-TIME-GUARANTEE NIL :BENCHMARKS NIL :GIT-OPERATIONS NIL)
 :STDOUT "(:ARTIFACT
 #A((93) BASE-CHAR
    . \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/scadenza-attempt-003.sexp\")
 :ATTEMPT 3 :STATUS :OK :COMPILE-UNITS
 ((:SOURCE \"core.lisp\" :FASL
   #A((98) BASE-CHAR
      . \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/scadenza-attempt-003-core.fasl\")
   :WARNINGS-P NIL :FAILURE-P NIL :STATUS :OK)
  (:SOURCE \"scadenza.lisp\" :FASL
   #A((102) BASE-CHAR
      . \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-07-protocols/out/scadenza-attempt-003-scadenza.fasl\")
   :WARNINGS-P NIL :FAILURE-P NIL :STATUS :OK))
 :WARNING-COUNT 0 :STYLE-WARNING-COUNT 0 :COUNTS
 (:POSITIVE-MODELS 2 :NEGATIVE-CONTROLS 5 :POSITIVE-STATES 67558
  :POSITIVE-EDGES 256971 :NEGATIVE-STATES-DISCOVERED 5566
  :NEGATIVE-EDGES-BEFORE-WITNESS 16614 :POSITIVE-COVERAGE-WITNESSES 14)
 :MODELS
 ((:MODEL :REGISTRATION :STATES 51 :EDGES 69 :VIOLATION NIL :TERMINAL NIL
   :COVERAGE-COUNT 3 :COVERAGE
   (:WRITER-SAMPLED-BEFORE-ANNOUNCEMENT :WRITER-OBSERVED-ANNOUNCEMENT
    :REPEATABLE-REGISTRATION-VIEW)
   :RECLAIM-TRANSITIONS-AUDITED 0 :EPOCH-BLOCKED-STATES 0 :WITNESS NIL)
  (:MODEL :LIFETIME :STATES 67507 :EDGES 256902 :VIOLATION NIL :TERMINAL
   (:STATUS :OK :TERMINAL-STATES 128 :STATES-REACHING-TERMINAL 67507
    :SCHEDULING :ABSTRACT-ENABLED-STEPS :REAL-TIME-GUARANTEE NIL)
   :COVERAGE-COUNT 11 :COVERAGE
   (:SNAPSHOT-PIN-BLOCKS-PRUNE :TWO-SUCCESSFUL-OPERATIONS-SAME-SNAPSHOT
    :INFLIGHT-ACCESS-AFTER-EXPIRY-PIN-RELEASE-AND-RETIREMENT
    :NEW-ACCESS-REJECTED-AFTER-EXPIRY :NEW-ACCESS-REJECTED-AFTER-RECLAIM
    :INFLIGHT-RESPONSE-INVALIDATED-AFTER-SEARCH
    :INFLIGHT-MISSING-REPORTED-TOO-OLD :OLD-EPOCH-BLOCKS-RECLAIM
    :OLD-RESOURCE-RECLAIMED-WITH-NEWER-READER-ACTIVE
    :MINIMUM-RECOUNTED-WITH-ONE-PIN-REMAINING :TERMINAL)
   :RECLAIM-TRANSITIONS-AUDITED 3430 :EPOCH-BLOCKED-STATES 29440 :WITNESS NIL)
  (:MODEL :EXPIRY-IGNORES-READERS :STATES 5291 :EDGES 16154 :VIOLATION
   (:KIND :ACCESS-AFTER-RECLAIM :READER 0 :VERSION 0 :EPOCH 0 :RETIRED-AT 0)
   :TERMINAL NIL :COVERAGE-COUNT NIL :COVERAGE NIL :RECLAIM-TRANSITIONS-AUDITED
   NIL :EPOCH-BLOCKED-STATES NIL :WITNESS
   ((:ABSTRACT-TICK 1) (:READER 0 :ADMIT :SNAPSHOT 0 :EPOCH 0)
    (:EXPIRE :SNAPSHOT 0)
    (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 1)
    (:READER 0 :LOOKUP :LOCATION 0) (:PRUNE-RETAINED-VERSION 0 :THRESHOLD 1)
    (:RETIRE-VERSION 0 :RETIRED-AT 0)
    (:RECLAIM-VERSION 0 :RETIRED-AT 0 :READER-EPOCHS (0 NIL NIL))
    (:READER 0 :ACCESS :VERSION 0 :OBSERVED NIL)))
  (:MODEL :ADMIT-AFTER-EXPIRY :STATES 108 :EDGES 192 :VIOLATION
   (:KIND :ADMISSION-AFTER-EXPIRY :READER 0 :SNAPSHOT 0) :TERMINAL NIL
   :COVERAGE-COUNT NIL :COVERAGE NIL :RECLAIM-TRANSITIONS-AUDITED NIL
   :EPOCH-BLOCKED-STATES NIL :WITNESS
   ((:ABSTRACT-TICK 1) (:EXPIRE :SNAPSHOT 0)
    (:READER 0 :ADMIT :SNAPSHOT 0 :EPOCH 0)))
  (:MODEL :NO-THRESHOLD-RECOUNT :STATES 104 :EDGES 186 :VIOLATION
   (:KIND :THRESHOLD-STALE-AFTER-RELEASE :EXPECTED 1 :ACTUAL 0 :PINS
    ((:CSN 0 :STATUS :EXPIRED :PIN NIL :DEADLINE 1)
     (:CSN 1 :STATUS :ACTIVE :PIN T :DEADLINE 2)))
   :TERMINAL NIL :COVERAGE-COUNT NIL :COVERAGE NIL :RECLAIM-TRANSITIONS-AUDITED
   NIL :EPOCH-BLOCKED-STATES NIL :WITNESS
   ((:ABSTRACT-TICK 1) (:EXPIRE :SNAPSHOT 0)
    (:RELEASE-SNAPSHOT-PIN :SNAPSHOT 0 :REMAINING-MINIMUM 1 :THRESHOLD 0)))
  (:MODEL :OMIT-REGISTRATION-THRESHOLD :STATES 35 :EDGES 49 :VIOLATION
   (:KIND :SNAPSHOT-VIEW-CHANGED :CSN 0 :EXPECTED 100 :READS (NIL)) :TERMINAL
   NIL :COVERAGE-COUNT NIL :COVERAGE NIL :RECLAIM-TRANSITIONS-AUDITED NIL
   :EPOCH-BLOCKED-STATES NIL :WITNESS
   ((:SNAPSHOT :ANNOUNCE-THRESHOLD) (:SNAPSHOT :CAPTURE-CSN)
    (:WRITER :ASSIGN-CSN) (:WRITER :SAMPLE-THRESHOLD)
    (:WRITER :PUBLISH-VERSION) (:SNAPSHOT :BORN)
    (:SNAPSHOT :READ :CSN 0 :OBSERVED NIL)))
  (:MODEL :BIRTH-BEFORE-HORIZON :STATES 28 :EDGES 33 :VIOLATION
   (:KIND :BIRTH-BEFORE-HORIZON :CSN 1 :HORIZON 0) :TERMINAL NIL
   :COVERAGE-COUNT NIL :COVERAGE NIL :RECLAIM-TRANSITIONS-AUDITED NIL
   :EPOCH-BLOCKED-STATES NIL :WITNESS
   ((:WRITER :ASSIGN-CSN) (:SNAPSHOT :ANNOUNCE-THRESHOLD)
    (:SNAPSHOT :CAPTURE-CSN) (:SNAPSHOT :BORN)))))
"
 :STDERR "" :FAILURES NIL)
