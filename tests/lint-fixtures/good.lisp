;;;; good.lisp — fixture: codice conforme, nessuna violazione attesa.
;;; EXPECT:

(declaim (optimize (safety 3) (debug 2)))

(defun somma (a b)
  "Somma A e B. Precondizioni: interi. Segnala type-error altrimenti."
  (declare (type integer a b) (optimize (safety 2) (speed 3)))
  (+ a b))

(defmacro con-valore ((var valore) &body corpo)
  "Lega VAR a VALORE ed esegue CORPO."
  `(let ((,var ,valore)) ,@corpo))

;; I token vietati in commenti e stringhe non contano: (safety 0) truly-the ignore-errors
(defparameter *nota* "eval compile (safety 0) ignore-errors truly-the")
(defun carattere ()
  "Restituisce una parentesi come carattere, non come struttura."
  #\()
