;;;; C4: hazard slot e riuso di un frame; non e' una cache del prodotto.
;;; REQ: REQ-IDX-008 REQ-AFF-017 REQ-AFF-008
;;; OWNER: BFS seriale; ogni successore e' una copia privata dello stato.
;;; SHARED: nessuno; SC e' un'ipotesi del modello, non una proprieta' di Lisp.
(defpackage #:arcdocdb.spk07.page-lifetime (:use #:cl) (:export #:check))
(in-package #:arcdocdb.spk07.page-lifetime)
(declaim (optimize (safety 3) (speed 1) (debug 3)))

;;; Stato: (fase-reclaimer stato-frame token incarnazione campo-a campo-b
;;;         numero-hazard-letto protetto readers).
;;; Reader: (fase token-letto incarnazione-attesa hazard copia-a copia-b esito).
(defun initial-state (readers)
  (list 0 :ready 0 0 0 0 0 nil
        (loop repeat readers collect (list 0 nil nil nil nil nil nil))))

(defun reader-edge (state index mutant)
  "Un solo passo SC del reader; nessun retry o attesa nel suo automa."
  (let* ((s (copy-tree state)) (r (nth index (nth 8 s))) (phase (first r)))
    (when (= phase 6) (return-from reader-edge nil))
    (incf (first r))
    (case phase
      (0 (if (eq (second s) :ready)
             (setf (second r) (third s) (third r) (fourth s))
             (setf (first r) 6 (nth 6 r) :miss)))
      (1 (setf (fourth r) (second r)))
      (2 (unless (or (eq mutant :no-revalidation)
                     (and (eq (second s) :ready) (eql (third s) (second r))))
           (setf (first r) 5 (nth 6 r) :miss)))
      (3 (setf (nth 4 r) (nth 4 s))
         (when (eq mutant :early-release) (setf (fourth r) nil)))
      (4 (setf (nth 5 r) (nth 5 s) (nth 6 r) :hit))
      (5 (setf (fourth r) nil))
      (otherwise (error "Fase reader non prevista: ~S" phase)))
    (cons (list :reader index :step phase) s)))

(defun manager-edge (state cycles mutant)
  "Chiude, scansiona per singolo slot, riscrive in due passi e pubblica."
  (let* ((s (copy-tree state)) (phase (first s)) (readers (nth 8 s)))
    (when (and (= phase 0) (>= (fourth s) cycles))
      (return-from manager-edge nil))
    (case phase
      (0 (setf (second s) :retiring (first s) 1 (nth 6 s) 0 (nth 7 s) nil))
      (1 (let ((hazard (fourth (nth (nth 6 s) readers))))
           (when (eql hazard (third s)) (setf (nth 7 s) t))
           (incf (nth 6 s))
           (when (= (nth 6 s) (length readers)) (setf (first s) 2))))
      (2 (if (and (nth 7 s) (not (eq mutant :ignore-hazard)))
             (setf (first s) 1 (nth 6 s) 0 (nth 7 s) nil)
             (progn
               (incf (fourth s))
               (setf (third s) (if (eq mutant :aba) (mod (fourth s) 2) (fourth s))
                     (second s) :building (first s) 3))))
      (3 (setf (nth 4 s) (fourth s) (first s) 4))
      (4 (setf (nth 5 s) (fourth s) (first s) 5))
      (5 (setf (second s) :ready (first s) 0))
      (otherwise (error "Fase reclaimer non prevista: ~S" phase)))
    (cons (list :reclaimer :step phase) s)))

(defun successors (state cycles mutant)
  (let ((edges nil) (manager (manager-edge state cycles mutant)))
    (when manager (push manager edges))
    (dotimes (i (length (nth 8 state)))
      (let ((edge (reader-edge state i mutant))) (when edge (push edge edges))))
    edges))

(defun violation (state)
  "Oracolo indipendente: ogni campo letto deve appartenere all'incarnazione richiesta."
  (dolist (r (nth 8 state))
    (when (or (and (nth 4 r) (/= (nth 4 r) (third r)))
              (and (nth 5 r) (/= (nth 5 r) (third r))))
      (return-from violation :copied-reused-incarnation)))
  nil)

(defun observe (state witnesses)
  (dolist (r (nth 8 state))
    (when (eq (nth 6 r) :hit) (setf (gethash :success witnesses) t))
    (when (and (member (first r) '(3 4)) (eq (second state) :retiring))
      (setf (gethash :copy-while-retiring witnesses) t))
    (when (and (= (first r) 2) (not (eq (second state) :ready)))
      (setf (gethash :late-announcement witnesses) t)))
  (when (and (= (first state) 2) (nth 7 state))
    (setf (gethash :protected-reuse-blocked witnesses) t)))

(defun one-model (readers cycles mutant)
  (let* ((witnesses (make-hash-table))
         (report
           (arcdocdb.spk07::explore
            (list :page-lifetime :readers readers :cycles cycles :mutant mutant)
            (initial-state readers)
            (lambda (s) (successors s cycles mutant))
            (lambda (s) (observe s witnesses) (violation s)) :limit 200000)))
    (unless (if mutant (getf report :violation) (null (getf report :violation)))
      (error "Esito inatteso: ~S" report))
    (unless mutant
      (dolist (key '(:success :copy-while-retiring :late-announcement :protected-reuse-blocked))
        (unless (gethash key witnesses) (error "Caso non raggiunto: ~A" key))))
    (append report (list :observations
                        (loop for key in '(:success :copy-while-retiring :late-announcement
                                          :protected-reuse-blocked)
                              when (gethash key witnesses) collect key)))))

(defun check ()
  (list :model :page-lifetime :status :ok :memory-model :sequential-consistency
        :positive (loop for readers in '(1 2) append
                        (loop for cycles in '(1 2) collect (one-model readers cycles nil)))
        :negative (loop for mutant in '(:no-revalidation :early-release :ignore-hazard :aba)
                        collect (one-model 1 2 mutant))
        :reader-step-bound 6 :gate :open
        :pending '(:sbcl-atomics :weak-memory :directory-lookup :cache-budget
                   :snapshots :io :end-to-end-get-progress)))
