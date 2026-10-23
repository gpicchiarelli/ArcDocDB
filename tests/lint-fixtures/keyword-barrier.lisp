;;; EXPECT:
(defun acquire-fixture ()
  "Le opzioni keyword del compilatore non chiamano il reader Lisp."
  (sb-thread:barrier (:read))
  (list :read :load :eval :compile :intern :read-from-string))
