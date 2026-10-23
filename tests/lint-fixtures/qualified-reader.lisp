;;; EXPECT: COD-34
(defun forbidden-reader-fixture (stream)
  "Una chiamata esplicitamente qualificata conserva il divieto COD-34."
  (cl:read stream))
