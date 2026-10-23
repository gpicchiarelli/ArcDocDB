;;;; Copertura con contrib SBCL; processo e cache separati dai benchmark.
;;;; Uso: --report directory/ [foundation|hash|key-hash|codec|cbor|cbor-write|cbor-string-write|cbor-simple-write|cbor-float-write|cbor-array-write|cbor-map-write|cbor-tag-write|cbor-item-read|cbor-string-read|cbor-minimal|cbor-minimal-scan|cbor-structure|csn|mvcc|epochs|read|get|get-performance|get-directory|get-series|get-active-init|io-rename|control-publication|control-recovery|recovery-active|recovery-archive|recovery-closed|recovery-archive-csn|runtime|runtime-active|execution|storage|recovery|io|wal|series|index] oppure --self-test directory/
;;;; REQ: REQ-FOR-003 REQ-AFF-002 REQ-LIM-001 REQ-VAL-001
(require :asdf)
(require :sb-cover)

(defpackage #:arcdocdb.foundation.coverage
  (:use #:cl))
(in-package #:arcdocdb.foundation.coverage)

(defun read-report (pathname)
  (uiop:read-file-string pathname :external-format :utf-8))

(defun scope-path-p (scope path)
  "Gli scope con elenchi espliciti selezionano file esatti; gli altri il modulo intero."
  (let ((suffixes
          (cond ((string= scope "runtime-active")
                 '("/src/runtime/active.lisp" "/src/series/types.lisp" "/src/wal/types.lisp"))
                ((string= scope "runtime")
                 '("/src/runtime/types.lisp" "/src/runtime/preflight.lisp"
                   "/src/runtime/query.lisp" "/src/runtime/build.lisp"
                   "/src/recovery-archive/types.lisp"))
                ((string= scope "recovery-archive-csn")
                 '("/src/recovery-archive-csn/types.lisp" "/src/recovery-archive-csn/series.lisp"
                   "/src/recovery-archive-csn/preflight.lisp" "/src/recovery-archive-csn/build.lisp"
                   "/src/recovery-archive-csn/query.lisp" "/src/recovery/decisions-types.lisp"
                   "/src/recovery/decisions-query.lisp"
                   "/src/recovery-active/types.lisp" "/src/recovery-active/build.lisp"))
                ((string= scope "recovery-closed")
                 '("/src/recovery-closed/types.lisp" "/src/recovery-closed/read.lisp"
                   "/src/recovery-closed/verify.lisp" "/src/recovery-closed/resolve.lisp"
                   "/src/recovery-closed/build.lisp" "/src/recovery-closed/csn.lisp"
                   "/src/recovery-closed/csn-serie.lisp" "/src/recovery-closed/publication.lisp"))
                ((string= scope "recovery-archive")
                 '("/src/recovery-archive/types.lisp" "/src/recovery-archive/read.lisp"
                   "/src/recovery-archive/build.lisp" "/src/recovery-archive/query.lisp"
                   "/src/recovery-archive/active.lisp"))
                ((string= scope "recovery-active")
                 '("/src/recovery-active/types.lisp" "/src/recovery-active/read.lisp"
                   "/src/recovery-active/frames.lisp" "/src/recovery-active/build.lisp"
                   "/src/recovery-active/resolve.lisp" "/src/recovery-active/query.lisp"
                   "/src/recovery-active/closure.lisp" "/src/recovery-active/publication.lisp"))
                ((string= scope "control-recovery")
                 '("/src/control/recovery-types.lisp" "/src/control/recovery-read.lisp"
                   "/src/control/recovery-publication.lisp" "/src/recovery/manifest-transition.lisp"))
                ((string= scope "control-publication")
                 '("/src/control/types.lisp" "/src/control/dependency.lisp" "/src/control/build.lisp"
                   "/src/control/preflight.lisp" "/src/control/transfer.lisp" "/src/control/prepare.lisp"
                   "/src/control/publication.lisp" "/src/control/publication-read.lisp"
                   "/src/active/preflight.lisp" "/src/active/prepare.lisp"
                   "/src/io/types.lisp" "/src/io/flush.lisp" "/src/io/transfer.lisp"))
                ((string= scope "io-rename")
                 '("/src/io/rename.lisp" "/src/io/namespace.lisp" "/src/io/native-namespace.lisp"
                   "/src/io/types.lisp" "/src/io/lifecycle.lisp"))
                ((string= scope "get-active-init")
                 '("/src/series/publication.lisp" "/src/get-resolver/active-types.lisp"
                   "/src/get-resolver/active-init.lisp" "/src/get-resolver/active-build.lisp"
                   "/src/get-directory/sources-types.lisp"))
                ((string= scope "get-series")
                 '("/src/get-directory/sources-types.lisp" "/src/get-directory/sources-read.lisp"
                   "/src/get-resolver/active-read.lisp"))
                ((string= scope "get-directory")
                 '("/src/get-directory/types.lisp" "/src/get-directory/build.lisp" "/src/get-directory/read.lisp"))
                ((string= scope "get")
                 '("/src/get/package.lisp" "/src/get/types.lisp" "/src/get/build.lisp"
                   "/src/get/lifecycle.lisp" "/src/get/lookup.lisp"
                   "/src/get/target.lisp" "/src/get/segment.lisp"))
                ((string= scope "get-performance")
                 '("/src/get/types.lisp" "/src/get/build.lisp" "/src/get/lifecycle.lisp"
                   "/src/get/lookup.lisp" "/src/get/target.lisp" "/src/get/segment.lisp"
                   "/src/cache/read.lisp"))
                ((string= scope "key-hash")
                 '("/src/hash/package.lisp" "/src/hash/arithmetic.lisp"
                   "/src/hash/blocks.lisp" "/src/hash/hash64.lisp"
                   "/src/index/hash-seed.lisp" "/src/index/hash-digests.lisp"
                   "/src/index/primary-build.lisp" "/src/index/primary-types.lisp"))
                ((string= scope "cbor")
                 '("/src/codec/cbor-package.lisp" "/src/codec/cbor-header.lisp"))
                ((string= scope "cbor-minimal")
                 '("/src/codec/cbor-float-minimal.lisp" "/src/codec/cbor-minimal.lisp"))
                ((string= scope "cbor-minimal-scan")
                 '("/src/codec/cbor-scan.lisp" "/src/codec/cbor-scan-minimal.lisp"))
                ((string= scope "cbor-write")
                 '("/src/codec/cbor-write.lisp"))
                ((string= scope "cbor-string-write")
                 '("/src/codec/cbor-string-write.lisp"))
                ((string= scope "cbor-simple-write")
                 '("/src/codec/cbor-simple-write.lisp"))
                ((string= scope "cbor-float-write")
                 '("/src/codec/cbor-float-narrow.lisp" "/src/codec/cbor-float-write.lisp"))
                ((string= scope "cbor-array-write")
                 '("/src/codec/cbor-array-input.lisp" "/src/codec/cbor-array-write.lisp"))
                ((string= scope "cbor-map-write")
                 '("/src/codec/cbor-map-input.lisp" "/src/codec/cbor-map-write.lisp"))
                ((string= scope "cbor-tag-write")
                 '("/src/codec/cbor-tag-input.lisp" "/src/codec/cbor-tag-write.lisp"))
                ((string= scope "cbor-item-read")
                 '("/src/codec/cbor-item-read.lisp"))
                ((string= scope "cbor-string-read")
                 '("/src/codec/cbor-string-read.lisp"))
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
  (unless (and (every (lambda (path) (scope-path-p "runtime-active" path))
                      '("/repo/src/runtime/active.lisp" "/repo/src/series/types.lisp"
                        "/repo/src/wal/types.lisp"))
               (every (lambda (path) (not (scope-path-p "runtime-active" path)))
                      '("/repo/src/runtime/build.lisp" "/repo/src/runtime/package.lisp"
                        "/repo/src/runtime/active.lisp.fake" "/repo/src/runtime/active.lisp/child"
                        "/repo/tests/runtime/adoption.lisp" "/repo/src/series/ownership.lisp")))
    (error "foundation-coverage.lisp COD-60: scope adoption runtime errato."))
  (unless (and (every (lambda (name)
                        (scope-path-p "runtime" (format nil "/repo/src/runtime/~A.lisp" name)))
                      '("types" "preflight" "query" "build"))
               (scope-path-p "runtime" "/repo/src/recovery-archive/types.lisp")
               (every (lambda (path) (not (scope-path-p "runtime" path)))
                      '("/repo/src/runtime/package.lisp" "/repo/tests/runtime/bootstrap.lisp"
                        "/repo/src/runtime/build.lisp.fake" "/repo/src/runtime/build.lisp/child"
                        "/repo/src/recovery-archive/build.lisp")))
    (error "foundation-coverage.lisp COD-60: scope runtime errato."))
  (unless (and (every (lambda (name)
                        (scope-path-p "recovery-archive-csn"
                                      (format nil "/repo/src/recovery-archive-csn/~A.lisp" name)))
                      '("types" "series" "preflight" "build" "query"))
               (every (lambda (path) (scope-path-p "recovery-archive-csn" path))
                      '("/repo/src/recovery/decisions-types.lisp" "/repo/src/recovery/decisions-query.lisp"
                        "/repo/src/recovery-active/types.lisp"
                        "/repo/src/recovery-active/build.lisp"))
               (every (lambda (path) (not (scope-path-p "recovery-archive-csn" path)))
                      '("/repo/src/recovery-archive-csn/package.lisp" "/repo/tests/recovery-archive-csn/plan.lisp"
                        "/repo/src/recovery-archive-csn/build.lisp.fake"
                        "/repo/src/recovery-archive-csn/build.lisp/child" "/repo/src/recovery/decisions-csn.lisp"
                        "/repo/src/recovery/decisions-query.lisp.fake")))
    (error "foundation-coverage.lisp COD-60: scope piano Archivio CSN errato."))
  (unless (and (every (lambda (name)
                        (scope-path-p "recovery-closed" (format nil "/repo/src/recovery-closed/~A.lisp" name)))
                      '("types" "read" "verify" "resolve" "build" "csn" "csn-serie" "publication"))
               (every (lambda (path) (not (scope-path-p "recovery-closed" path)))
                      '("/repo/src/recovery-closed/package.lisp" "/repo/tests/recovery-closed/read.lisp"
                        "/repo/src/recovery-closed/read.lisp.fake" "/repo/src/recovery-closed/read.lisp/child"
                        "/repo/src/recovery-active/build.lisp")))
    (error "foundation-coverage.lisp COD-60: scope CLOSED errato."))
  (let ((actual (isolate-output (truename "./") directory)))
    (unless (search "/fasl/src/foundation/record.fasl" (namestring actual))
      (error "foundation-coverage.lisp COD-60: mapping ricorsivo della cache errato.")))
  (unless (and (every (lambda (name)
                        (scope-path-p "recovery-archive" (format nil "/repo/src/recovery-archive/~A.lisp" name)))
                      '("types" "read" "build" "query" "active"))
               (every (lambda (path) (not (scope-path-p "recovery-archive" path)))
                      '("/repo/tests/recovery-archive/read.lisp" "/repo/src/recovery-archive/read.lisp.fake"
                        "/repo/src/recovery-archive/read.lisp/child" "/repo/src/recovery-archive/package.lisp"
                        "/repo/src/recovery-active/read.lisp")))
    (error "foundation-coverage.lisp COD-60: scope recovery Archivio errato."))
  (unless (and (every (lambda (name)
                        (scope-path-p "recovery-active" (format nil "/repo/src/recovery-active/~A.lisp" name)))
                      '("types" "read" "frames" "build" "resolve" "query" "closure" "publication"))
               (not (scope-path-p "recovery-active" "/repo/tests/recovery-active/read.lisp"))
               (not (scope-path-p "recovery-active" "/repo/src/recovery-active/read.lisp.fake"))
               (not (scope-path-p "recovery-active" "/repo/src/recovery-active/read.lisp/child"))
               (not (scope-path-p "recovery-active" "/repo/src/recovery/scan.lisp"))
               (scope-path-p "control-recovery" "/repo/src/control/recovery-read.lisp")
               (scope-path-p "control-recovery" "/repo/src/recovery/manifest-transition.lisp")
               (not (scope-path-p "control-recovery" "/repo/src/control/recovery-read.lisp.fake"))
               (not (scope-path-p "control-recovery" "/repo/tests/control/recovery-read.lisp"))
               (not (scope-path-p "control-recovery" "/repo/src/control/publication.lisp"))
               (scope-path-p "control-publication" "/repo/src/control/publication.lisp")
               (scope-path-p "cbor-tag-write" "/repo/src/codec/cbor-tag-input.lisp")
               (scope-path-p "cbor-item-read" "/repo/src/codec/cbor-item-read.lisp")
               (scope-path-p "cbor-string-read" "/repo/src/codec/cbor-string-read.lisp")
               (not (scope-path-p "cbor-string-read" "/repo/tests/codec/cbor-string-read.lisp"))
               (not (scope-path-p "cbor-string-read" "/repo/src/codec/cbor-string-read.lisp.fake"))
               (not (scope-path-p "cbor-string-read" "/repo/src/codec/cbor-string-read.lisp/child"))
               (not (scope-path-p "cbor-string-read" "/repo/src/codec/cbor-string-write.lisp"))
               (not (scope-path-p "cbor-item-read" "/repo/tests/codec/cbor-item-read.lisp"))
               (not (scope-path-p "cbor-item-read" "/repo/src/codec/cbor-item-read.lisp.fake"))
               (not (scope-path-p "cbor-item-read" "/repo/src/codec/cbor-item-read.lisp/child"))
               (not (scope-path-p "cbor-item-read" "/repo/src/codec/cbor-scan.lisp"))
               (scope-path-p "cbor-tag-write" "/repo/src/codec/cbor-tag-write.lisp")
               (not (scope-path-p "cbor-tag-write" "/repo/tests/codec/cbor-tag-write.lisp"))
               (not (scope-path-p "cbor-tag-write" "/repo/src/codec/cbor-tag-write.lisp.fake"))
               (not (scope-path-p "cbor-tag-write" "/repo/src/codec/cbor-tag-input.lisp/child"))
               (not (scope-path-p "cbor-tag-write" "/repo/src/codec/cbor-map-write.lisp"))
               (scope-path-p "control-publication" "/repo/src/io/flush.lisp")
               (not (scope-path-p "control-publication" "/repo/tests/control/publication.lisp"))
               (not (scope-path-p "control-publication" "/repo/src/control/publication.lisp.fake"))
               (scope-path-p "io-rename" "/repo/src/io/rename.lisp")
               (scope-path-p "io-rename" "/repo/src/io/types.lisp")
               (not (scope-path-p "io-rename" "/repo/src/io/rename.lisp.fake"))
               (not (scope-path-p "io-rename" "/repo/tests/io/rename.lisp"))
               (scope-path-p "cbor" "/repo/src/codec/cbor-package.lisp")
               (scope-path-p "hash" "/repo/src/hash/hash64.lisp")
               (not (scope-path-p "hash" "/repo/tests/hash/hash64.lisp"))
               (scope-path-p "key-hash" "/repo/src/index/hash-digests.lisp")
               (scope-path-p "key-hash" "/repo/src/hash/arithmetic.lisp")
               (not (scope-path-p "key-hash" "/repo/src/index/hash-digests.lisp.fake"))
               (not (scope-path-p "key-hash" "/repo/tests/hash/hash64.lisp"))
               (scope-path-p "series" "/repo/src/series/publication.lisp")
               (scope-path-p "get-active-init" "/repo/src/get-resolver/active-init.lisp")
               (scope-path-p "get-active-init" "/repo/src/series/publication.lisp")
               (not (scope-path-p "get-active-init" "/repo/src/get-resolver/active-init.lisp.fake"))
               (not (scope-path-p "get-active-init" "/repo/tests/get-directory/series-read.lisp"))
               (scope-path-p "index" "/repo/src/index/rebuild.lisp")
               (not (scope-path-p "index" "/repo/tests/index/rebuild.lisp"))
               (not (scope-path-p "series" "/repo/tests/series/controller.lisp"))
               (scope-path-p "mvcc" "/repo/src/mvcc/snapshots-read.lisp")
               (not (scope-path-p "mvcc" "/repo/tests/mvcc/lifecycle.lisp"))
               (scope-path-p "epochs" "/repo/src/epochs/reclaim.lisp")
               (not (scope-path-p "epochs" "/repo/tests/epochs/lifecycle.lisp"))
               (scope-path-p "read" "/repo/src/read/task.lisp")
               (scope-path-p "get-series" "/repo/src/get-directory/sources-read.lisp")
               (scope-path-p "get-series" "/repo/src/get-resolver/active-read.lisp")
               (not (scope-path-p "get-series" "/repo/tests/get-directory/series-read.lisp"))
               (not (scope-path-p "get-series" "/repo/src/get-directory/sources-read.lisp.fake"))
               (scope-path-p "get-directory" "/repo/src/get-directory/read.lisp")
               (not (scope-path-p "get-directory" "/repo/tests/get-directory/read.lisp"))
               (not (scope-path-p "get-directory" "/repo/src/get-directory/read.lisp.fake"))
               (scope-path-p "get-performance" "/repo/src/get/segment.lisp")
               (not (scope-path-p "get-performance" "/repo/tests/get-performance/segment.lisp"))
               (not (scope-path-p "read" "/repo/tests/read/lifecycle.lisp"))
               (every (lambda (name)
                        (scope-path-p "get" (format nil "/repo/src/get/~A.lisp" name)))
                      '("package" "types" "build" "lifecycle" "lookup" "target" "segment"))
               (every (lambda (path) (not (scope-path-p "get" path)))
                      '("/repo/tests/get/lifecycle.lisp" "/repo/src/read/task.lisp"
                        "/repo/src/get/segment.lisp.fake" "/repo/src/get/lookup.lisp/child"))
               (scope-path-p "cbor" "/repo/src/codec/cbor-header.lisp")
               (not (scope-path-p "cbor" "/repo/src/codec/utf8.lisp"))
               (not (scope-path-p "cbor" "/repo/src/codec/cbor-header.lisp.fake"))
               (not (scope-path-p "cbor" "/repo/src/codec/cbor-package.lisp/child"))
               (not (scope-path-p "cbor" "/repo/tests/codec/cbor-header.lisp"))
               (scope-path-p "cbor-write" "/repo/src/codec/cbor-write.lisp")
               (every (lambda (path) (not (scope-path-p "cbor-write" path)))
                      '("/repo/src/codec/cbor-header.lisp" "/repo/src/codec/cbor-package.lisp"
                        "/repo/tests/codec/cbor-write.lisp"
                        "/repo/src/codec/cbor-write.lisp.fake"
                        "/repo/src/codec/cbor-write.lisp/child"))
               (scope-path-p "cbor-string-write" "/repo/src/codec/cbor-string-write.lisp")
               (every (lambda (path) (not (scope-path-p "cbor-string-write" path)))
                      '("/repo/src/codec/cbor-write.lisp" "/repo/src/codec/cbor-package.lisp"
                        "/repo/src/codec/utf8.lisp" "/repo/tests/codec/cbor-string-write.lisp"
                        "/repo/src/codec/cbor-string-write.lisp.fake"
                        "/repo/src/codec/cbor-string-write.lisp/child"))
               (scope-path-p "cbor-simple-write" "/repo/src/codec/cbor-simple-write.lisp")
               (every (lambda (path) (not (scope-path-p "cbor-simple-write" path)))
                      '("/repo/src/codec/cbor-write.lisp" "/repo/src/codec/cbor-string-write.lisp"
                        "/repo/src/codec/cbor-package.lisp" "/repo/tests/codec/cbor-simple-write.lisp"
                        "/repo/src/codec/cbor-simple-write.lisp.fake"
                        "/repo/src/codec/cbor-simple-write.lisp/child"))
               (scope-path-p "codec" "/repo/src/codec/utf8.lisp")
               (every (lambda (name)
                        (scope-path-p "cbor-array-write" (format nil "/repo/src/codec/~A.lisp" name)))
                      '("cbor-array-input" "cbor-array-write"))
               (every (lambda (path) (not (scope-path-p "cbor-array-write" path)))
                      '("/repo/src/codec/cbor-string-write.lisp"
                        "/repo/src/codec/cbor-scan-minimal.lisp"
                        "/repo/tests/codec/cbor-array-write.lisp"
                        "/repo/src/codec/cbor-array-input.lisp.fake"
                        "/repo/src/codec/cbor-array-write.lisp/child"))
               (every (lambda (name)
                        (scope-path-p "cbor-map-write" (format nil "/repo/src/codec/~A.lisp" name)))
                      '("cbor-map-input" "cbor-map-write"))
               (every (lambda (path) (not (scope-path-p "cbor-map-write" path)))
                      '("/repo/src/codec/cbor-array-input.lisp"
                        "/repo/src/codec/cbor-scan-minimal.lisp"
                        "/repo/tests/codec/cbor-map-write.lisp"
                        "/repo/src/codec/cbor-map-input.lisp.fake"
                        "/repo/src/codec/cbor-map-write.lisp/child"))
               (every (lambda (name)
                        (scope-path-p "cbor-float-write" (format nil "/repo/src/codec/~A.lisp" name)))
                      '("cbor-float-narrow" "cbor-float-write"))
               (every (lambda (path) (not (scope-path-p "cbor-float-write" path)))
                      '("/repo/src/codec/cbor-float-minimal.lisp"
                        "/repo/src/codec/cbor-simple-write.lisp"
                        "/repo/tests/codec/cbor-float-write.lisp"
                        "/repo/src/codec/cbor-float-narrow.lisp.fake"
                        "/repo/src/codec/cbor-float-write.lisp/child"))
               (every (lambda (name)
                        (scope-path-p "cbor-minimal" (format nil "/repo/src/codec/~A.lisp" name)))
                      '("cbor-float-minimal" "cbor-minimal"))
               (every (lambda (path) (not (scope-path-p "cbor-minimal" path)))
                      '("/repo/src/codec/cbor-header.lisp" "/repo/src/codec/utf8.lisp"
                        "/repo/tests/codec/cbor-minimal.lisp"
                        "/repo/src/codec/cbor-minimal.lisp.fake"
                        "/repo/src/codec/cbor-float-minimal.lisp/child"))
               (every (lambda (name)
                        (scope-path-p "cbor-minimal-scan" (format nil "/repo/src/codec/~A.lisp" name)))
                      '("cbor-scan" "cbor-scan-minimal"))
               (every (lambda (path) (not (scope-path-p "cbor-minimal-scan" path)))
                      '("/repo/src/codec/cbor-header.lisp" "/repo/src/codec/cbor-scan-items.lisp"
                        "/repo/tests/codec/cbor-scan-minimal.lisp"
                        "/repo/src/codec/cbor-scan.lisp.fake"
                        "/repo/src/codec/cbor-scan-minimal.lisp/child"))
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
      (when (member scope '("runtime-active" "runtime" "recovery-active" "recovery-archive" "recovery-closed" "recovery-archive-csn") :test #'string=)
        (sb-cover:reset-coverage))
      (uiop:symbol-call (cond ((member scope '("runtime" "runtime-active") :test #'string=) '#:arcdocdb.runtime.tests)
                             ((string= scope "recovery-archive-csn") '#:arcdocdb.recovery.archive.csn.tests)
                             ((string= scope "recovery-closed") '#:arcdocdb.recovery.closed.tests)
                             ((string= scope "recovery-archive") '#:arcdocdb.recovery.archive.tests)
                             ((string= scope "recovery-active") '#:arcdocdb.recovery.active.tests)
                             ((member scope '("hash" "key-hash") :test #'string=) '#:arcdocdb.hash64.tests)
                             ((string= scope "cbor") '#:arcdocdb.cbor.tests)
                             ((string= scope "cbor-minimal") '#:arcdocdb.cbor.minimal.tests)
                             ((string= scope "cbor-minimal-scan") '#:arcdocdb.cbor.minimal.scan.tests)
                             ((string= scope "cbor-write") '#:arcdocdb.cbor.write.tests)
                             ((string= scope "cbor-string-write") '#:arcdocdb.cbor.string.write.tests)
                             ((string= scope "cbor-simple-write") '#:arcdocdb.cbor.simple.write.tests)
                             ((string= scope "cbor-float-write") '#:arcdocdb.cbor.float.write.tests)
                             ((string= scope "cbor-array-write") '#:arcdocdb.cbor.array.write.tests)
                             ((string= scope "cbor-map-write") '#:arcdocdb.cbor.map.write.tests)
                             ((string= scope "cbor-tag-write") '#:arcdocdb.cbor.tag.write.tests)
                             ((string= scope "cbor-item-read") '#:arcdocdb.cbor.item.read.tests)
                             ((string= scope "cbor-string-read") '#:arcdocdb.cbor.string.read.tests)
                             ((string= scope "cbor-structure") '#:arcdocdb.cbor.structure.tests)
                             ((string= scope "codec") '#:arcdocdb.utf8.tests)
                             ((string= scope "csn") '#:arcdocdb.csn.tests)
                             ((string= scope "mvcc") '#:arcdocdb.mvcc.tests)
                             ((string= scope "epochs") '#:arcdocdb.epochs.tests)
                             ((string= scope "get-active-init") '#:arcdocdb.series.tests)
                             ((string= scope "get-series") '#:arcdocdb.get.directory.tests)
                             ((string= scope "get-directory") '#:arcdocdb.get.directory.tests)
                             ((string= scope "get-performance") '#:arcdocdb.get.performance.tests)
                             ((string= scope "read") '#:arcdocdb.read.tests)
                   ((string= scope "get") '#:arcdocdb.get.tests)
                             ((string= scope "execution") '#:arcdocdb.execution.tests)
                             ((string= scope "storage") '#:arcdocdb.storage.tests)
                             ((member scope '("control-publication" "control-recovery") :test #'string=)
                              '#:arcdocdb.control.tests)
                             ((string= scope "recovery") '#:arcdocdb.recovery.tests)
                             ((member scope '("io" "io-rename") :test #'string=) '#:arcdocdb.io.tests)
                             ((string= scope "wal") '#:arcdocdb.wal.tests)
                             ((string= scope "series") '#:arcdocdb.series.tests)
                             ((string= scope "index") '#:arcdocdb.index.primary.tests)
                             (t '#:arcdocdb.foundation.tests)) '#:run)
      (when (string= scope "control-publication")
        (uiop:symbol-call '#:arcdocdb.io.tests '#:run))
      (when (string= scope "runtime-active")
        (uiop:symbol-call '#:arcdocdb.series.tests '#:run))
      (when (string= scope "control-recovery")
        (uiop:symbol-call '#:arcdocdb.recovery.tests '#:run))
      (when (string= scope "get-active-init")
        (uiop:symbol-call '#:arcdocdb.get.directory.tests '#:run))
      (when (string= scope "index")
        (uiop:symbol-call '#:arcdocdb.index.slots.tests '#:run))
      (when (string= scope "key-hash")
        (uiop:symbol-call '#:arcdocdb.index.primary.tests '#:run))
      (when (string= scope "cbor-minimal-scan")
        (uiop:symbol-call '#:arcdocdb.cbor.structure.tests '#:run))
      (when (string= scope "codec")
        (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)
        (uiop:symbol-call '#:arcdocdb.cbor.minimal.tests '#:run)
        (uiop:symbol-call '#:arcdocdb.cbor.structure.tests '#:run)
        (uiop:symbol-call '#:arcdocdb.cbor.minimal.scan.tests '#:run)
        (uiop:symbol-call '#:arcdocdb.cbor.write.tests '#:run)
        (uiop:symbol-call '#:arcdocdb.cbor.string.write.tests '#:run)
        (uiop:symbol-call '#:arcdocdb.cbor.simple.write.tests '#:run)
        (uiop:symbol-call '#:arcdocdb.cbor.float.write.tests '#:run)
        (uiop:symbol-call '#:arcdocdb.cbor.array.write.tests '#:run)
        (uiop:symbol-call '#:arcdocdb.cbor.map.write.tests '#:run)
        (uiop:symbol-call '#:arcdocdb.cbor.tag.write.tests '#:run)
        (uiop:symbol-call '#:arcdocdb.cbor.item.read.tests '#:run)
        (uiop:symbol-call '#:arcdocdb.cbor.string.read.tests '#:run)))
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
                   (member (third args) '("runtime-active" "runtime" "foundation" "hash" "key-hash" "codec" "cbor" "cbor-write" "cbor-string-write" "cbor-simple-write" "cbor-float-write" "cbor-array-write" "cbor-map-write" "cbor-tag-write" "cbor-item-read" "cbor-string-read" "cbor-minimal" "cbor-minimal-scan" "cbor-structure" "csn" "mvcc" "epochs" "read" "get" "get-performance" "get-directory" "get-series" "get-active-init" "io-rename" "control-publication" "control-recovery" "recovery-active" "recovery-archive" "recovery-closed" "recovery-archive-csn" "execution" "storage" "recovery" "io" "wal" "series" "index") :test #'string=)))
    (error "foundation-coverage.lisp: usare --report directory/ [foundation|hash|key-hash|codec|cbor|cbor-write|cbor-string-write|cbor-simple-write|cbor-float-write|cbor-array-write|cbor-map-write|cbor-tag-write|cbor-item-read|cbor-string-read|cbor-minimal|cbor-minimal-scan|cbor-structure|csn|mvcc|epochs|read|get|get-performance|get-directory|get-series|get-active-init|io-rename|control-publication|control-recovery|recovery-active|recovery-archive|recovery-closed|recovery-archive-csn|runtime|runtime-active|execution|storage|recovery|io|wal|series|index] o --self-test directory/."))
  (let ((directory (merge-pathnames (uiop:ensure-directory-pathname (second args))
                                   (truename "./")))
        (scope (or (third args) "foundation")))
    (ensure-directories-exist directory)
    (if (string= (first args) "--self-test")
        (self-test directory)
        (coverage directory scope))))
