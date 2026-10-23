;;;; SPK-07: modello finito SC, non implementazione dell'indice.
;;; Metodo registrato in metodo-pubblicazione.md prima della compilazione.
;;; REQ: REQ-IDX-003 REQ-IDX-007 REQ-AFF-017 REQ-VAL-001
(defpackage :arcdocdb.spk07.pubblicazione
  (:use :cl) (:export :check))
(in-package :arcdocdb.spk07.pubblicazione)
(declaim (optimize (safety 3) (speed 1) (debug 3)))

(define-condition model-budget-exhausted (error)
  ((resource :initarg :resource :reader budget-resource)
   (limit :initarg :limit :reader budget-limit))
  (:report (lambda (condition stream)
             (format stream "Budget ~A esaurito: ~D"
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
      (error "Frammento inesistente: ~S" id)))

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
         (when (assoc (second event) operations) (error "Invocazione duplicata"))
         (push (cons (second event)
                     (list :id (second event) :kind (third event) :key (fourth event)
                           :argument (fifth event) :invoke time :response nil :result nil))
               operations))
        (:respond
         (let ((operation (cdr (assoc (second event) operations))))
           (unless operation (error "Risposta senza invocazione"))
           (when (getf operation :response) (error "Risposta duplicata"))
           (setf (getf operation :response) time (getf operation :result) (third event))))))
    (when (> (length operations) 3) (budget-error :history-operations 3))
    (mapcar #'cdr (nreverse operations))))

(defun linearization (history)
  "Cerca un'estensione finita: pendenti omessi o completati, precedenza reale."
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
  "Controlla entrambe le chiavi e l'instradamento, anche senza un reader."
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
  "Controlli indipendenti: overlap ammesso, precedenza reale e pendenti."
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
          (unless (eql valid expected) (error "Oracolo storico errato: ~S" name))
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
  "CHECK breve; un budget insufficiente fallisce, non promuove la copertura."
  (unless (and (integerp state-limit) (<= 1 state-limit 200000)
               (integerp step-limit) (<= 1 step-limit 64))
    (error "Budget ammessi: stati 1..200000, passi 1..64"))
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
                             (error "Stallo nel modello: ~S" state))
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
                 (error "Nessun terminale completo: ~S" name))
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
              (error "Witness di generazione non mirato: ~S" negative))
            (run-model config mutant :data-history))))
      (dolist (protection '(:ref :epoch))
        (let ((report (run-model (scenario :split :update protection)
                                 :early-release :protocol)))
          (unless (eq (getf (getf report :violation) :kind) :access-to-reclaimed)
            (error "Witness reclaim non mirato"))))
      (let ((report (run-model (scenario :rebuild :update :ref) :skip-fields :protocol)))
        (unless (eq (getf (getf report :violation) :kind) :incoherent-result)
          (error "Witness dei campi non mirato")))
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
