;;;; Client di produzione: un comando esplicito, risposta o errore, nessun retry.
(require :asdf)
(handler-case
    (progn
      (asdf:load-asd (merge-pathnames "../arcdocdb.asd" *load-truename*))
      (let ((*standard-output* *error-output*)) (asdf:load-system "arcdocdb/local"))
      (uiop:symbol-call :arcdocdb.local :client-cli-main (uiop:command-line-arguments)))
  (error (condition)
    (format *error-output* "~&LOCAL-CLIENT-FAIL ~A: ~A~%" (type-of condition) condition)
    (sb-ext:exit :code 1)))
