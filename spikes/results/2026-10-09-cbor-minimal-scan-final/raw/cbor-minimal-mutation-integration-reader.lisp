;;;; Lettura statica soltanto; nessuna forma dei driver viene caricata o valutata.
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(require :sb-cover)

(defun forms-as-data (path)
  (with-open-file (stream path :external-format :utf-8)
    (let ((*read-eval* nil) (eof (gensym)))
      (loop for form = (read stream nil eof) until (eq form eof) collect form))))

(defun syntax-equal (left right)
  (tree-equal left right
              :test (lambda (a b)
                      (if (and (symbolp a) (symbolp b))
                          (and (string= (symbol-name a) (symbol-name b))
                               (equal (and (symbol-package a) (package-name (symbol-package a)))
                                      (and (symbol-package b) (package-name (symbol-package b)))))
                          (equal a b)))))

(defun named-form (forms operator name)
  (find-if (lambda (form) (and (consp form) (eq operator (first form))
                              (eq name (second form)))) forms))

(let* ((upstream "spikes/out/cbor-minimal-mutation-upstream-engine.lisp")
       (before "spikes/out/cbor-minimal-mutation-before-upstream.lisp")
       (current "tools/cbor-minimal-mutation.lisp")
       (up (forms-as-data upstream)) (old (forms-as-data before))
       (now (forms-as-data current)) (coverage (forms-as-data "tools/foundation-coverage.lisp"))
       (unchanged 0)
       (output "spikes/out/cbor-minimal-mutation-upstream-integration-review.lisp"))
  (dolist (form up)
    (unless (and (consp form) (eq 'defun (first form))
                 (member (second form) '(self-test main)))
      (assert (some (lambda (candidate) (syntax-equal form candidate)) now))
      (when (and (consp form) (eq 'defun (first form))) (incf unchanged))))
  (let* ((modified (copy-tree (named-form now 'defun 'self-test)))
         (result (car (last modified))) (position (position :dispatch result)))
    (assert position)
    (assert (syntax-equal '(dispatch-self-test) (nth (1+ position) result)))
    (setf (car (last modified)) (append (subseq result 0 position) (subseq result (+ 2 position))))
    (assert (syntax-equal modified (named-form up 'defun 'self-test))))
  (assert (syntax-equal (named-form old 'defparameter '*scan-mutants*)
                        (named-form now 'defparameter '*scan-mutants*)))
  (dolist (name '(parse-options dispatch-self-test))
    (assert (syntax-equal (named-form old 'defun name) (named-form now 'defun name))))
  (let* ((up-text (uiop:read-file-string upstream :external-format :utf-8))
         (now-text (uiop:read-file-string current :external-format :utf-8))
         (marker "(save-report report directory)")
         (up-main (search "(defun main ()" up-text))
         (now-main (search "(defun main ()" now-text))
         (up-start (search marker up-text :start2 up-main))
         (now-start (search marker now-text :start2 now-main)))
    (assert (and up-start now-start))
    (assert (string= (subseq up-text up-start) (subseq now-text now-start))))
  (let ((report (list :schema-version 1 :kind :static-upstream-integration-review :status :ok
                      :recorded-at (get-universal-time)
                      :driver current
                      :before-copy before :before-blob "80a3b0ddd84a3827872d8b4d45fb8b7af178002a"
                      :upstream-copy upstream :upstream-blob "a9a94354a24bd3dc6bfe3a1511adbeb1d52c88d6"
                      :upstream-commit "b8cc54d81510bf0573e3c68abe3d51fa1d43a61a"
                      :unchanged-upstream-defuns unchanged
                      :other-upstream-forms-preserved t
                      :self-test-change :dispatch-property-only
                      :main-execution-tail-byte-identical t
                      :scan-catalog-and-dispatch-preserved t
                      :driver-reader-forms (length now) :coverage-reader-forms (length coverage)
                      :read-eval nil :product-evaluated nil :campaigns-executed 0
                      :runtime-verification :pending)))
    (with-open-file (stream output :direction :output :if-exists :error :if-does-not-exist :create
                                   :external-format :utf-8)
      (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))
    (let ((reread (forms-as-data output)))
      (assert (= 1 (length reread)))
      (assert (equal report (first reread))))
    (write report :pretty t)
    (terpri)))
