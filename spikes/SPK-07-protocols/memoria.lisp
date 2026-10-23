;;;; Modello C4 degli ordini osservati; non è il modello completo della CPU.
;;; REQ: REQ-IDX-003 REQ-AFF-017
(defpackage #:arcdocdb.spk07.memoria (:use #:cl) (:export #:check))
(in-package #:arcdocdb.spk07.memoria)
(declaim (optimize (safety 3) (speed 1) (debug 3)))

(defparameter *eventi* '(:w-odd :w-a :w-b :w-even :r-first :r-a :r-b :r-last))

(define-condition modello-invalido (error)
  ((contesto :initarg :contesto :reader contesto))
  (:report (lambda (c s) (format s "Modello memoria: ~S." (contesto c)))))

(defun prerequisiti (evento variante)
  "Archi espliciti; le scritture indicano propagazioni al singolo osservatore."
  (case evento
    (:w-odd nil)
    ((:w-a :w-b) (unless (eq variante :writer-open) '(:w-odd)))
    (:w-even (if (eq variante :writer-close) '(:w-odd) '(:w-odd :w-a :w-b)))
    (:r-first nil)
    ((:r-a :r-b) (unless (eq variante :reader-open) '(:r-first)))
    (:r-last (if (eq variante :reader-close) '(:r-first) '(:r-first :r-a :r-b)))
    (otherwise (error 'modello-invalido :contesto evento))))

(defun oracle-ordine (ordine)
  "Letture indipendenti dal generatore: se accettate devono coincidere con seq."
  (let ((seq 0) (a 10) (b 90) (s1 nil) (s2 nil) (ra nil) (rb nil))
    (dolist (evento ordine)
      (ecase evento
        (:w-odd (setf seq 1)) (:w-a (setf a 30)) (:w-b (setf b 70)) (:w-even (setf seq 2))
        (:r-first (setf s1 seq)) (:r-last (setf s2 seq))
        (:r-a (setf ra a)) (:r-b (setf rb b))))
    (unless (and s1 s2 ra rb) (error 'modello-invalido :contesto :incomplete-history))
    (let* ((accettato (and (evenp s1) (= s1 s2)))
           (coerente (case s1 (0 (and (= ra 10) (= rb 90)))
                               (2 (and (= ra 30) (= rb 70))) (otherwise nil))))
      (values (and accettato (not coerente)) accettato
              (list :first-sequence s1 :last-sequence s2 :fields (list ra rb))))))

(defun enumera-ordini (variante)
  "DFS di otto eventi, lavoro limitato da 8!: non usa schedulazione o clock."
  (let ((ordini 0) (prefissi 0) (accettati 0) (rifiutati 0) (violazioni 0) (testimone nil))
    (labels ((visita (restanti fatti)
               (incf prefissi)
               (when (> prefissi 109601) ; somma P(8,k), k=0..8.
                 (error 'modello-invalido :contesto :prefix-budget))
               (if restanti
                   (dolist (evento restanti)
                     (when (every (lambda (p) (member p fatti)) (prerequisiti evento variante))
                       (visita (remove evento restanti :count 1) (cons evento fatti))))
                   (progn
                     (incf ordini)
                     (when (> ordini 40320) (error 'modello-invalido :contesto :history-budget))
                     (let ((ordine (reverse fatti)))
                       (multiple-value-bind (violazione accettato letture) (oracle-ordine ordine)
                         (if accettato (incf accettati) (incf rifiutati))
                         (when violazione
                           (incf violazioni)
                           (unless testimone (setf testimone (list :events ordine :reads letture))))))))))
      (visita *eventi* nil))
    (unless (and (plusp ordini) (= ordini (+ accettati rifiutati)))
      (error 'modello-invalido :contesto :empty-or-inconsistent-count))
    (unless (if (eq variante :complete) (zerop violazioni) (plusp violazioni))
      (error 'modello-invalido :contesto (list :unexpected-outcome variante violazioni)))
    (list :variant variante :histories ordini :prefixes prefissi
          :accepted accettati :retry rifiutati :violations violazioni :witness testimone)))

(declaim (ftype (function ((simple-array (unsigned-byte 64) (3))) null) scrivi-kernel))
(defun scrivi-kernel (buffer)
  "Due barriere reali; una scrittura a generazione 2 senza wrap."
  (setf (aref buffer 0) 1)
  (sb-thread:barrier (:write))
  (setf (aref buffer 1) 30 (aref buffer 2) 70)
  (sb-thread:barrier (:write))
  (setf (aref buffer 0) 2)
  nil)

(declaim (ftype (function ((simple-array (unsigned-byte 64) (3)))
                         (values (unsigned-byte 64) (unsigned-byte 64)
                                 (unsigned-byte 64) (unsigned-byte 64))) leggi-kernel))
(defun leggi-kernel (buffer)
  "Un tentativo: solo fixture sequenziale, non stress di concorrenza reale."
  (let ((s1 (aref buffer 0)))
    (sb-thread:barrier (:read))
    (let ((a (aref buffer 1)) (b (aref buffer 2)))
      (sb-thread:barrier (:read))
      (values s1 a b (aref buffer 0)))))

(defun check ()
  "Conserva testimoni, istruzioni del runtime e parti del gate non coperte."
  (let ((risultati (mapcar #'enumera-ordini
                          '(:complete :writer-open :writer-close :reader-open :reader-close)))
        (buffer (make-array 3 :element-type '(unsigned-byte 64) :initial-contents '(0 10 90))))
    (scrivi-kernel buffer)
    (multiple-value-bind (s1 a b s2) (leggi-kernel buffer)
      (unless (equal (list s1 a b s2) '(2 30 70 2))
        (error 'modello-invalido :contesto :compiled-kernel-fixture)))
    (list :status :ok :module :memory-observation-orders :configurations 5
          :reports risultati :mutation-controls 4 :history-event-count 8
          :limits '(:one-writer :one-reader :one-slot :atomic-word-access
                    :single-observer-propagation :no-wrap :no-reclaim
                    :not-full-arm64-or-x86-64-memory-model)
          :runtime (list :sbcl (lisp-implementation-version) :machine (machine-type))
          :disassembly
          (list :writer (with-output-to-string (*standard-output*) (disassemble #'scrivi-kernel))
                :reader (with-output-to-string (*standard-output*) (disassemble #'leggi-kernel)))
          :hardware-gate-complete nil)))
