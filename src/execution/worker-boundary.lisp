;;;; Confine del worker: fault locale persistente, campi diagnostici conservati.
;;; OWNER: solo thread creatore; il controller della Serie resta da integrare.
;;; SHARED: nessuno stato globale o tra worker; handler solo in questo confine.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer list list error) null) %classifica-guasto-worker))
(defun %classifica-guasto-worker (context resources arguments condition)
  "Pre: owner verificato e errore nel passo. Post: recuperabile propagato oppure
FAULTED con condizione e campi conservati; non nasconde né risolleva l'errore.
Liste di ragioni letterali bounded; solo resource/invalid attesi sono recuperabili."
  (when (typep condition 'resource-exhausted)
    (when (member (arcdocdb.conditions:error-reason condition) resources)
      (return-from %classifica-guasto-worker nil)))
  (when (typep condition 'invalid-argument)
    (when (member (arcdocdb.conditions:error-reason condition) arguments)
      (return-from %classifica-guasto-worker nil)))
  (setf (contesto-worker-writer-fault context) condition
        (contesto-worker-writer-state context) :faulted)
  (unless (eq (contesto-worker-writer-fault context) condition)
    (error 'invariant-violation :reason :worker-state))
  (unless (eq (contesto-worker-writer-state context) :faulted)
    (error 'invariant-violation :reason :worker-state))
  nil)

;;; REQ: REQ-CON-004 REQ-AFF-008
(defmacro %passo-worker ((context resources arguments) &body body)
  "Pre: contesto owner-only non rientrante, ragioni letterali bounded. Post:
valori del corpo oppure errore propagato e fault locale registrato se inatteso.
Owner e FAULTED rifiutati prima del handler; nessun callback applicativo o retry."
  (let ((value (gensym "WORKER")) (handler (gensym "WORKER-ERROR")))
    `(let ((,value ,context))
       (%check-owner-worker ,value)
       (when (eq (contesto-worker-writer-state ,value) :faulted)
         (error 'resource-exhausted :reason :worker-state))
       (flet ((,handler (condition)
                (%classifica-guasto-worker ,value ',resources ',arguments condition)))
         (declare (dynamic-extent #',handler))
         (handler-bind ((error #',handler)) ,@body)))))
