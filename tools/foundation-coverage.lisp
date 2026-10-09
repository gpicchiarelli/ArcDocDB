;;;; Copertura con contrib SBCL; processo e cache separati dai benchmark.
;;;; Uso: --report directory/ [foundation|codec|cbor|cbor-minimal|cbor-structure|csn|execution|storage|recovery|io|wal] oppure --self-test directory/
;;;; REQ: REQ-FOR-003 REQ-AFF-002 REQ-LIM-001 REQ-VAL-001
(require :asdf)
(require :sb-cover)

(defpackage #:arcdocdb.foundation.coverage
  (:use #:cl))
(in-package #:arcdocdb.foundation.coverage)

(defun read-report (pathname)
  (uiop:read-file-string pathname :external-format :utf-8))

(defun scope-path-p (scope path)
  "Gli scope CBOR selezionano file esatti; gli altri il modulo intero."
  (let ((suffixes
          (cond ((string= scope "cbor")
                 '("/src/codec/cbor-package.lisp" "/src/codec/cbor-header.lisp"))
                ((string= scope "cbor-minimal")
                 '("/src/codec/cbor-float-minimal.lisp" "/src/codec/cbor-minimal.lisp"))
                ((string= scope "cbor-structure")
                 '("/src/codec/cbor-package.lisp" "/src/codec/cbor-space.lisp"
                   "/src/codec/cbor-scan-input.lisp" "/src/codec/cbor-scan-stack.lisp"
                   "/src/codec/cbor-scan-items.lisp" "/src/codec/cbor-scan.lisp")))))
    (if suffixes
        (some (lambda (suffix)
                (let ((pos (search suffix path :from-end t)))
                  (and pos (= (+ pos (length suffix)) (length path)))))
              suffixes)
        (search (format nil "/src/~A/" scope) path))))

(defun isolate-output (root directory)
  "Mappa esplicitamente ogni file del checkout; rifiuta una destinazione fuori dalla cache privata."
  (let ((destination (merge-pathnames "fasl/" directory)))
    (asdf:initialize-output-translations
     `(:output-translations
       (,(merge-pathnames "**/*.*" root) ,(merge-pathnames "**/*.*" destination))
       :ignore-inherited-configuration))
    (let ((actual (asdf:apply-output-translations (merge-pathnames "src/foundation/record.fasl" root))))
      (unless (uiop:subpathp actual destination)
        (error "foundation-coverage.lisp COD-60: cache non isolata: ~A." actual))
      actual)))

(defun self-test (directory)
  (let ((actual (isolate-output (truename "./") directory)))
    (unless (search "/fasl/src/foundation/record.fasl" (namestring actual))
      (error "foundation-coverage.lisp COD-60: mapping ricorsivo della cache errato.")))
  (unless (and (scope-path-p "cbor" "/repo/src/codec/cbor-package.lisp")
               (scope-path-p "cbor" "/repo/src/codec/cbor-header.lisp")
               (not (scope-path-p "cbor" "/repo/src/codec/utf8.lisp"))
               (not (scope-path-p "cbor" "/repo/src/codec/cbor-header.lisp.fake"))
               (not (scope-path-p "cbor" "/repo/src/codec/cbor-package.lisp/child"))
               (not (scope-path-p "cbor" "/repo/tests/codec/cbor-header.lisp"))
               (scope-path-p "codec" "/repo/src/codec/utf8.lisp")
               (every (lambda (name)
                        (scope-path-p "cbor-minimal" (format nil "/repo/src/codec/~A.lisp" name)))
                      '("cbor-float-minimal" "cbor-minimal"))
               (every (lambda (path) (not (scope-path-p "cbor-minimal" path)))
                      '("/repo/src/codec/cbor-header.lisp" "/repo/src/codec/utf8.lisp"
                        "/repo/tests/codec/cbor-minimal.lisp"
                        "/repo/src/codec/cbor-minimal.lisp.fake"
                        "/repo/src/codec/cbor-float-minimal.lisp/child"))
               (every (lambda (name)
                        (scope-path-p "cbor-structure" (format nil "/repo/src/codec/~A.lisp" name)))
                      '("cbor-package" "cbor-space" "cbor-scan-input" "cbor-scan-stack"
                        "cbor-scan-items" "cbor-scan"))
               (every (lambda (path) (not (scope-path-p "cbor-structure" path)))
                      '("/repo/src/codec/cbor-header.lisp" "/repo/src/codec/utf8.lisp"
                        "/repo/tests/codec/cbor-scan.lisp"
                        "/repo/src/codec/cbor-scan.lisp.fake"
                        "/repo/src/codec/cbor-space.lisp/child")))
    (error "foundation-coverage.lisp: COD-60, scope CBOR errato."))
  (let* ((source (merge-pathnames "coverage-fixture.lisp" directory))
         (fasl (merge-pathnames "coverage-fixture.fasl" directory)))
    (with-open-file (stream source :direction :output :if-exists :supersede)
      (write-line "(in-package #:cl-user)" stream)
      (write-line "(declaim (optimize (sb-cover:store-coverage-data 3)))" stream)
      (write-line "(defun coverage-fixture (flag) (if (plusp flag) (1+ flag) (1- flag)))" stream))
    (load (compile-file source :output-file fasl))
    (uiop:symbol-call '#:cl-user '#:coverage-fixture 1)
    (let ((report (sb-cover:report directory)))
      (unless (search "50.0" (read-report report))
        (error "foundation-coverage.lisp: COD-60, ramo mancante non rilevato.")))
    (format t "Copertura: self-test del ramo mancante superato.~%")))

(defun coverage (directory scope)
  (let ((root (truename "./")))
    (proclaim '(optimize (sb-cover:store-coverage-data 3)))
    (handler-bind ((warning (lambda (condition) (error condition))))
      (asdf:load-asd (merge-pathnames "arcdocdb.asd" root))
      (isolate-output root directory)
      (asdf:load-system "arcdocdb" :force t)
      (asdf:load-system "arcdocdb/tests" :force t)
      (uiop:symbol-call (cond ((string= scope "cbor") '#:arcdocdb.cbor.tests)
                             ((string= scope "cbor-minimal") '#:arcdocdb.cbor.minimal.tests)
                             ((string= scope "cbor-structure") '#:arcdocdb.cbor.structure.tests)
                             ((string= scope "codec") '#:arcdocdb.utf8.tests)
                             ((string= scope "csn") '#:arcdocdb.csn.tests)
                             ((string= scope "execution") '#:arcdocdb.execution.tests)
                             ((string= scope "storage") '#:arcdocdb.storage.tests)
                             ((string= scope "recovery") '#:arcdocdb.recovery.tests)
                             ((string= scope "io") '#:arcdocdb.io.tests)
                             ((string= scope "wal") '#:arcdocdb.wal.tests)
                             (t '#:arcdocdb.foundation.tests)) '#:run)
      (when (string= scope "codec")
        (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)
        (uiop:symbol-call '#:arcdocdb.cbor.minimal.tests '#:run)
        (uiop:symbol-call '#:arcdocdb.cbor.structure.tests '#:run)))
    (sb-cover:save-coverage-in-file (merge-pathnames "coverage-state.lisp" directory))
    (let ((report (sb-cover:report directory :if-matches
                                  (lambda (path) (scope-path-p scope path)))))
      (unless report
        (error "foundation-coverage.lisp: COD-60, nessun dato per scope ~A." scope))
      (format t "Rapporto: ~A~%" report))))

(let ((args (rest sb-ext:*posix-argv*)))
  (unless (and (<= 2 (length args) 3) (member (first args) '("--report" "--self-test")
                                            :test #'string=)
               (or (= (length args) 2)
                   (member (third args) '("foundation" "codec" "cbor" "cbor-minimal" "cbor-structure" "csn" "execution" "storage" "recovery" "io" "wal") :test #'string=)))
    (error "foundation-coverage.lisp: usare --report directory/ [foundation|codec|cbor|cbor-minimal|cbor-structure|csn|execution|storage|recovery|io|wal] o --self-test directory/."))
  (let ((directory (merge-pathnames (uiop:ensure-directory-pathname (second args))
                                   (truename "./")))
        (scope (or (third args) "foundation")))
    (ensure-directories-exist directory)
    (if (string= (first args) "--self-test")
        (self-test directory)
        (coverage directory scope))))
