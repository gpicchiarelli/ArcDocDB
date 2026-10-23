;;;; SPK-07: modello finito, non codice del motore. Metodo preregistrato a fianco.
;;; REQ: REQ-IDX-002 REQ-AFF-017 REQ-VAL-001
(defpackage :arcdocdb.spk07.scadenza (:use :cl) (:export :check))
(in-package :arcdocdb.spk07.scadenza)
(declaim (optimize (safety 3) (speed 1) (debug 3)))

(defconstant +state-limit+ 200000)
(defconstant +no-snapshot+ 3)

(defun replacing (state key value)
  "Ogni chiave e ogni sottolista di stato sono immutabili dopo la pubblicazione."
  (let ((next (copy-list state))) (setf (getf next key) value) next))

(defun item-replacing (items index value)
  (let ((next (copy-list items))) (setf (nth index next) value) next))

(defun value-at (csn)
  "Storia logica dell'oracolo, indipendente dalle location fisiche."
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
        (unless (= (length matches) 1) (error "Witness ambiguo/non abilitato: ~S" action))
        (let ((next (cdar matches)))
          (push (list :action action :before state :after next) trace)
          (setf state next))))
    (unless (equal state expected-state) (error "Witness termina nello stato errato"))
    (nreverse trace)))

(defun terminal-reachability (parents predecessors terminals)
  "Ogni stato può essere drenato; nessuna affermazione di tempo reale/fairness reale."
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
      (error "Drenabilita incompleta: ~D di ~D stati, ~D terminali"
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
                           (error "Reclaim senza grace period: ~S ~S" (car edge) state))
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
        (error "Violazione specifica attesa ~S, ottenuta ~S: ~S" expected actual report))
      (if expected
          (let ((actions (getf report :witness)) (state (getf report :state)))
            (unless actions (error "Controllo negativo senza witness"))
            (append report (list :status :expected-counterexample
                                 :trace (replay initial actions successors state))))
          (let ((coverage-reports nil))
            (dolist (label required)
              (let* ((entry (or (gethash label covered) (error "Copertura assente: ~S" label)))
                     (state (getf entry :state))
                     (actions (append (path-to (getf entry :previous) parents)
                                      (list (getf entry :action)))))
                (push (list :name label :witness actions
                            :trace (replay initial actions successors state) :state state)
                      coverage-reports)))
            (unless (= (getf report :states) (hash-table-count parents))
              (error "Conteggio BFS incoerente"))
            (setf coverage-reports (nreverse coverage-reports))
            (append report
                    (list :status :ok :coverage coverage-reports
                          :coverage-count (length coverage-reports)
                          :reclaim-transitions-audited reclaim-audits
                          :epoch-blocked-states epoch-blocked-states
                          :terminal (when terminal-p
                                      (terminal-reachability parents predecessors terminals)))))))))

(defun check ()
  "Esaurisce i due grafi corretti, trova e riesegue cinque controlli negativi."
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
