;;;; Importazione legacy: RESULT e STATUS rimangono nella plist pubblicata.
;;; REQ: REQ-VAL-001 REQ-BEN-001
(require :asdf)
(require :sb-posix)
(load (merge-pathnames "evidence-storage.lisp" *load-truename*))
(let* ((directory (uiop:ensure-directory-pathname
                   (sb-posix:mkdtemp (namestring (merge-pathnames "normalize-evidence-XXXXXX"
                                                                (uiop:temporary-directory))))))
       (source (merge-pathnames "source.lisp" directory))
       (payload (merge-pathnames "source.lisp.gz" directory))
       (descriptor (merge-pathnames "compressed.lisp" directory))
       (normalizer (namestring (truename "tools/normalize-spike-report.lisp")))
       (checks 0) (records nil))
  (unwind-protect
       (progn
         (with-open-file (s source :direction :output :if-exists :error)
           (write '(:environment (:cpu "fixture") :mode "--check"
                    :runs ((:id "SPK-fixture" :stdout "(:status :pass :n 1)"))) :stream s))
         (with-open-file (s payload :direction :output :if-exists :error
                                    :element-type '(unsigned-byte 8))
           (uiop:run-program (list "gzip" "-n" "-9" "-c" "--" (namestring source)) :output s))
         (with-open-file (s descriptor :direction :output :if-exists :error)
           (write (list :schema-version 1 :kind :compressed-evidence :codec :gzip
                        :payload (file-namestring payload)
                        :uncompressed-bytes (arcdocdb.evidence:file-bytes source)
                        :uncompressed-sha256 (arcdocdb.evidence:file-sha256 source)
                        :compressed-bytes (arcdocdb.evidence:file-bytes payload)
                        :compressed-sha256 (arcdocdb.evidence:file-sha256 payload)) :stream s))
         (loop for input in (list source descriptor) for i from 0
               for output = (merge-pathnames (format nil "normalized-~D.lisp" i) directory)
               for argv = (list (namestring sb-ext:*runtime-pathname*) "--noinform" "--no-userinit"
                                "--no-sysinit" "--script" normalizer
                                (namestring input) (namestring output))
               do (multiple-value-bind (stdout stderr code)
                      (uiop:run-program argv :output :string :error-output :string :ignore-error-status t)
                    (unless (zerop code) (error "Normalizer: ~A" stderr))
                    (incf checks)
                    (let* ((data (arcdocdb.evidence:read-evidence output))
                           (run (first (getf data :runs))))
                      (unless (and (eq :imported (getf data :status))
                                   (eq :pass (getf run :status))
                                   (equal '(:status :pass :n 1) (getf run :result)))
                        (error "Importazione errata."))
                      (incf checks)
                      (unless (equal (getf data :environment) '(:cpu "fixture"))
                        (error "Metadata modificati."))
                      (incf checks)
                      (push (list :command argv :stdout stdout :stderr stderr :exit-code code
                                  :result data) records))))
         (write (list :schema-version 1 :kind :normalizer-compression-tests :status :ok
                      :checks checks :cases (nreverse records)) :pretty t) (terpri))
    (uiop:delete-directory-tree directory :validate t)))
