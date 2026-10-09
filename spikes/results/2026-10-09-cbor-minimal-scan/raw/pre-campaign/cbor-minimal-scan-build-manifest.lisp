;;;; Manifest della raccolta: originali chiusi e subset dichiarato delle copie.
(require :asdf)
(load "tools/evidence-storage.lisp")
(let ((files nil)
      (processes '(("preliminary" "spikes/out/4000552268-command-64251-0/report.lisp")
      ("coverage-self" "spikes/out/4000552284-command-64445-0/report.lisp")
      ("legacy-mutator-self" "spikes/out/4000552284-command-64446-0/report.lisp")
      ("archive-self" "spikes/out/4000552284-command-64447-0/report.lisp")
      ("benchmark" "spikes/out/4000552318-command-65001-0/report.lisp")
      ("coverage" "spikes/out/4000552339-command-65156-0/report.lisp")
      ("old-final-audit" "spikes/out/4000552339-command-65157-0/report.lisp")
      ("mutations" "spikes/out/4000552339-command-65155-0/report.lisp")
      ("old-archive-audit" "spikes/out/4000552339-command-65158-0/report.lisp")
      ("coverage-compaction" "spikes/out/4000552418-command-67182-0/report.lisp"))))
  (labels ((add (label source)
             (unless (probe-file source) (error "File assente: ~A." source))
             (when (assoc label files :test #'equal) (error "Label duplicato: ~A." label))
             (push (list label (namestring (truename source))) files)))
    (dolist (path '("src/codec/cbor-package.lisp" "src/codec/cbor-scan.lisp"
                    "src/codec/cbor-scan-minimal.lisp"
                    "tests/codec/cbor-minimal-scan-support.lisp"
                    "tests/codec/cbor-minimal-scan.lisp"
                    "tests/codec/cbor-minimal-scan-threads.lisp"
                    "tools/cbor-minimal-scan-bench.lisp" "tools/cbor-minimal-mutation.lisp"
                    "tools/foundation-coverage.lisp" "tools/check-command-archive.lisp"))
      (add (format nil "frozen/~A" path) path))
    (dolist (path (uiop:directory-files "spikes/out/"))
      (let ((name (file-namestring path)))
        (when (and (some (lambda (prefix) (uiop:string-prefix-p prefix name))
                         '("cbor-minimal-scan-" "check-command-archive-" "cbor-minimal-mutation-before-" "cbor-minimal-mutation-upstream-"))
                   (not (search "coverage-state-original" name))
                   (not (search "test-audit" name))
                   (not (search "measure-audit" name)))
          (add (format nil "pre-campaign/~A" name) path))))
    (dolist (name '("source-read.lisp" "source-read-first.log" "source-read-final.log"))
      (let ((path (format nil "/tmp/cbor-minimal-scan-~A" name)))
        (add (format nil "syntax/~A" name) path)))
    (add "mutation/report.lisp" "spikes/out/cbor-minimal-scan-mutations-20261009/report.lisp")
    (dolist (child '("baseline" "0" "1" "2" "3" "4" "5" "6" "7"))
      (dolist (path '("test.log" "tools/cbor-minimal-isolated-build.lisp"
                      "src/codec/cbor-scan.lisp" "src/codec/cbor-scan-minimal.lisp"))
        (add (format nil "mutation/~A/~A" child path)
             (format nil "spikes/out/cbor-minimal-scan-mutations-20261009/~A/~A" child path))))
    (add "archive-self/report.lisp" "spikes/out/command-archive-check-self-20261009-a/report.lisp")
    (dolist (path (uiop:directory-files "spikes/out/cbor-minimal-scan-coverage-self-20261009/"))
      (unless (equal "fasl" (pathname-type path))
        (add (format nil "coverage-self/~A" (file-namestring path)) path)))
    (with-open-file (out "spikes/out/scan-collection-manifest.lisp" :direction :output :if-exists :error)
      (write (list :schema-version 1 :processes processes
                   :trees '(("coverage" "spikes/out/cbor-minimal-scan-coverage-20261009/" :all)
                            ("archive-self-logs" "spikes/out/command-archive-check-self-20261009-a/logs/" :all)
                            ("archive-self-cases" "spikes/out/command-archive-check-self-20261009-a/cases/" :all))
                   :files (nreverse files)
                   :limits '(:full-mutant-copies-and-fasl-retained-locally
                             :full-negative-fixtures-retained-locally
                             :only-targets-and-runners-and-logs-in-published-mutation-subset))
             :stream out :pretty t)
      (terpri out))
    (format t "Manifest: ~D file scelti, ~D processi e tre alberi chiusi.~%" (length files) (length processes))))

