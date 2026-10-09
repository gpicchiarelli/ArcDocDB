(:schema-version 1 :kind :imported-agent-setup
 :origin :agent-tool-history :agent "/root/handoff_evidence"
 :limits (:file-copy-guards-only :not-lisp-tests-or-campaigns :no-reconstructed-process-metadata)
 :unavailable-metadata (:process-start-and-end-times :environment :source-fingerprints
                        :source-consistency :separate-stdout-stderr)
 :attempts (
  (:tool :exec-command :command "python3 - <<'PY'
from pathlib import Path
import shutil
source=Path('/Users/gpicchiarelli/.codex/worktrees/writer-ready/ArcDocDB')
clone=Path('/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z')
for name in ('writer-ready-bench.lisp','writer-ready-mutation.lisp'):
    target=clone/'tools'/name
    if target.exists():
        raise RuntimeError(f'Destinazione già presente: {target}')
    shutil.copyfile(source/'tools'/name,target)
helper=clone/'spikes/out/writer-ready-tool-self-test.lisp'
helper.parent.mkdir(parents=True,exist_ok=True)
helper.write_text(''';;;; Adapter C4: compila interamente un tool e carica il FASL con --self-test.
;;;; Contrib pre-caricati prima della compilazione rigorosa; argv espliciti per MAIN.
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(let* ((arguments (uiop:command-line-arguments))
       (tool (first arguments))
       (fasl (and tool (merge-pathnames (concatenate 'string (pathname-name tool) \".fasl\")
                                        \"spikes/out/ready-tool-fasl/\"))))
  (unless (and (= 1 (length arguments))
               (member tool '(\"tools/writer-ready-bench.lisp\" \"tools/writer-ready-mutation.lisp\")
                       :test #'string=))
    (error \"COD-61: adapter richiede il path di uno dei due nuovi tool ready.\"))
  (ensure-directories-exist fasl)
  (setf asdf:*compile-file-failure-behaviour* :error
        asdf:*compile-file-warnings-behaviour* :error
        asdf:*user-cache* (merge-pathnames \"spikes/out/ready-tool-product-fasl/\" (truename \"./\")))
  (handler-bind
      ((warning (lambda (condition)
                  (unless (typep condition 'sb-kernel:redefinition-warning)
                    (error \"~A non ammesso (COD-01): ~A\" (type-of condition) condition)))))
    (multiple-value-bind (output warnings failure) (compile-file tool :output-file fasl)
      (unless (and output (not warnings) (not failure))
        (error \"COD-01: compile-file completo non riuscito per ~A.\" tool))
      (setf uiop/image:*command-line-arguments* '(\"--self-test\")
            sb-ext:*posix-argv* '(\"sbcl\" \"--self-test\"))
      (load output)))
  (format t \"~&Tool ready ~A: COMPILE-FILE completo e --self-test FASL superati.~%\" tool))
''')
print(helper)
PY"
   :workdir "/Users/gpicchiarelli/.codex/worktrees/writer-ready/ArcDocDB"
   :max-output-tokens 2000
   :tool-returned-result (:chunk-id "a19179" :wall-time-seconds 0.000011417
                          :exit-code 1 :original-token-count 57 :output "Traceback (most recent call last):
  File \"<stdin>\", line 8, in <module>
RuntimeError: Destinazione già presente: /var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tools/writer-ready-bench.lisp
")
   :stdout :not-separately-exposed :stderr :not-separately-exposed)
  (:tool :exec-command :command "python3 - <<'PY'
from pathlib import Path
import shutil
source=Path('/Users/gpicchiarelli/.codex/worktrees/writer-ready/ArcDocDB')
clone=Path('/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z')
for name in ('writer-ready-bench.lisp','writer-ready-mutation.lisp'):
    target=clone/'tools'/name
    if target.exists():
        if target.read_bytes() != (source/'tools'/name).read_bytes():
            raise RuntimeError(f'Tool differente nella clone: {target}')
    else:
        shutil.copyfile(source/'tools'/name,target)
helper=clone/'spikes/out/writer-ready-tool-self-test.lisp'
helper.parent.mkdir(parents=True,exist_ok=True)
with helper.open('x',encoding='utf8') as stream:
    stream.write(''';;;; Adapter C4: compila interamente un tool e carica il FASL con --self-test.
;;;; Contrib pre-caricati prima della compilazione rigorosa; argv espliciti per MAIN.
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(let* ((arguments (uiop:command-line-arguments))
       (tool (first arguments))
       (fasl (and tool (merge-pathnames (concatenate 'string (pathname-name tool) \".fasl\")
                                        \"spikes/out/ready-tool-fasl/\"))))
  (unless (and (= 1 (length arguments))
               (member tool '(\"tools/writer-ready-bench.lisp\" \"tools/writer-ready-mutation.lisp\")
                       :test #'string=))
    (error \"COD-61: adapter richiede il path di uno dei due nuovi tool ready.\"))
  (ensure-directories-exist fasl)
  (setf asdf:*compile-file-failure-behaviour* :error
        asdf:*compile-file-warnings-behaviour* :error
        asdf:*user-cache* (merge-pathnames \"spikes/out/ready-tool-product-fasl/\" (truename \"./\")))
  (handler-bind
      ((warning (lambda (condition)
                  (unless (typep condition 'sb-kernel:redefinition-warning)
                    (error \"~A non ammesso (COD-01): ~A\" (type-of condition) condition)))))
    (multiple-value-bind (output warnings failure) (compile-file tool :output-file fasl)
      (unless (and output (not warnings) (not failure))
        (error \"COD-01: compile-file completo non riuscito per ~A.\" tool))
      (setf uiop/image:*command-line-arguments* '(\"--self-test\")
            sb-ext:*posix-argv* '(\"sbcl\" \"--self-test\"))
      (load output)))
  (format t \"~&Tool ready ~A: COMPILE-FILE completo e --self-test FASL superati.~%\" tool))
''')
print(helper)
PY"
   :workdir "/Users/gpicchiarelli/.codex/worktrees/writer-ready/ArcDocDB"
   :max-output-tokens 2000
   :tool-returned-result (:chunk-id "69f9d1" :wall-time-seconds 0.000010041
                          :exit-code 1 :original-token-count 57 :output "Traceback (most recent call last):
  File \"<stdin>\", line 9, in <module>
RuntimeError: Tool differente nella clone: /var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tools/writer-ready-bench.lisp
")
   :stdout :not-separately-exposed :stderr :not-separately-exposed)
 ))
