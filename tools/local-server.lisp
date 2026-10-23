;;;; Ingresso di produzione; nessun caricamento del test harness.
(require :asdf)
(handler-case
    (progn
      (asdf:load-asd (merge-pathnames "../arcdocdb.asd" *load-truename*))
      (let ((*standard-output* *error-output*)) (asdf:load-system "arcdocdb/local"))
      (uiop:symbol-call :arcdocdb.local :server-cli-main (uiop:command-line-arguments)))
  (error (condition)
    (format *error-output* "~&LOCAL-SERVER-FAIL ~A: ~A~%" (type-of condition) condition)
    (sb-ext:exit :code 1)))
