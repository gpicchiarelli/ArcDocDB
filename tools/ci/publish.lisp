;;;; Pubblicazione append-only: unione per attempt e push ottimista senza force.
;;; REQ: REQ-VAL-001 REQ-AFF-012
(in-package #:arcdocdb.ci)
(declaim (optimize (safety 3) (debug 3)))

(defparameter *ci-store-prefix* "spikes/results/ci/")
(defparameter *ci-push-attempts* 5)

(defun ci-fresh-directory (label)
  (ensure-directories-exist (merge-pathnames "spikes/out/ci/.parent" *ci-root*))
  (loop for n below 1000
        for path = (merge-pathnames (format nil "spikes/out/ci/~A-~D-~D-~D/"
                                           label (get-universal-time) (sb-posix:getpid) n) *ci-root*)
        unless (ci-lstat path) return (ci-mkdir path)
        finally (error "Impossibile allocare una directory CI privata.")))

(defun ci-fetch-commit (sha)
  (unless (ci-hex-id-p sha 40) (error "SHA GitHub non valida."))
  (handler-case (ci-git (list "cat-file" "-e" (concatenate 'string sha "^{commit}")))
    (error () (ci-git (list "fetch" "--no-tags" "origin" sha))))
  (%ci-ref sha))

(defun ci-pr-source-proof (actual server merge-info)
  "Attesta equivalenza dei contenuti con un'ancora API; non attesta l'esecuzione del producer PR."
  (let ((head (getf server :head-sha)))
    (dolist (anchor (ci-github-pr-anchors head))
      (let* ((sha (ci-fetch-commit (getf anchor :github-merge-sha)))
             (key (ci-source-key sha)))
        (when (and (equal (getf actual :source-id) (getf key :source-id))
                   (equal (getf actual :policy-id) (getf key :policy-id)))
          (return-from ci-pr-source-proof
            (list :method :github-pr-merge-source-v1 :tested-sha (getf actual :tested-sha)
                  :run-head-sha head :base-sha (getf merge-info :base-sha)
                  :pull-request (getf anchor :pull-request) :github-merge-sha sha
                  :source-id (getf key :source-id) :policy-id (getf key :policy-id)
                  :github-verified t)))))
    (error "Nessuna ancora PR GitHub con sorgenti e policy equivalenti.")))

(defun ci-validate-provenance (summary server)
  (let* ((identity (getf summary :identity)) (sha (getf identity :tested-sha))
         (head (getf server :head-sha))
         (direct (or (equal sha head)
                     (and (equal "pull_request" (getf server :event))
                          (equal sha (getf server :check-suite-sha)))))
         (proof nil))
    (unless (and (ci-hex-id-p sha 40) (ci-hex-id-p (getf identity :source-id))
                 (ci-hex-id-p (getf identity :policy-id)))
      (error "Identità sorgenti incompleta."))
    (unless (or direct (and (equal "pull_request" (getf server :event)) (ci-hex-id-p head 40)))
      (error "Commit provato non attestato dai metadata GitHub."))
    (let* ((merge-info (unless direct (ci-github-merge-candidate sha head)))
           (checked (ci-fetch-commit sha))
           (actual (ci-source checked)))
      (unless (equal identity (ci-identity-summary actual))
        (error "Identità dichiarata diversa dagli oggetti Git del commit provato."))
      (setf proof (if direct
                      (list :method :github-run-commit-v1 :tested-sha sha :run-head-sha head)
                      (ci-pr-source-proof actual server merge-info))))
    (dolist (payload (getf summary :packets))
      (let ((context (getf (getf payload :result) :context)))
        (dolist (key '(:run-id :attempt :repository :event))
          (unless (equal (getf context key) (getf server key))
            (error "Provenienza divergente: ~A." key)))
        (when (and (member (getf server :event) '("push" "workflow_dispatch") :test #'equal)
                   (not (equal (getf context :ref) (getf server :ref))))
          (error "Ref del producer divergente dal run GitHub."))))
    proof))

(defun ci-copy-immutable (source target)
  (if (ci-lstat target)
      (unless (and (ci-regular-file-p target) (= (ci-bytes source) (ci-bytes target))
                   (equal (ci-sha256 source) (ci-sha256 target)))
        (error "Collisione su un file immutabile: ~A." target))
      (ci-copy-new source target)))

(defun ci-store-run-path (store source-id run-id attempt)
  (merge-pathnames (format nil "by-source/~A/runs/~A/~A/" source-id run-id attempt) store))

(defun ci-union-packets (input existing destination)
  "Una sola versione dei byte per job/attempt; il recupero aggiunge solo job mancanti."
  (let ((root (ci-mkdir destination)) (seen (make-hash-table :test #'equal)))
    (labels ((add (dir)
               (let* ((manifest (ci-verify-packet dir)) (job (getf manifest :job))
                      (digest (ci-packet-digest dir)) (old (gethash job seen)))
                 (unless (string= job "sealed")
                   (cond ((and old (not (string= old digest)))
                          (error "Due versioni per job/attempt: ~A." job))
                         ((null old)
                          (ci-copy-packet dir (merge-pathnames (format nil "~A/" job) root))
                          (setf (gethash job seen) digest)))))))
      (dolist (dir (ci-discover-packets input)) (add dir))
      (when (ci-lstat existing)
        (dolist (file (ci-files existing :limit 100000 :max-depth 20))
          (when (and (string= "manifest.lisp" (file-namestring file))
                     (= 3 (length (uiop:split-string (enough-namestring file existing) :separator "/"))))
            (add (uiop:pathname-directory-pathname file))))))
    root))

(defun ci-collection-id (summary server)
  ;; L'ordine di download non deve cambiare l'identità della raccolta.
  (ci-digest-string
   (ci-wire-string (list :server server :summary (ci-public-summary summary)
     :payloads (sort (mapcar (lambda (p) (list :job (getf p :job) :digest (getf p :digest)))
                             (getf summary :packets)) #'string< :key (lambda (p) (getf p :job)))))))

(defun ci-write-store (checkout input server initial-identity work)
  (let* ((store (merge-pathnames *ci-store-prefix* checkout))
         (run (ci-store-run-path store (getf initial-identity :source-id)
                                 (getf server :run-id) (getf server :attempt)))
         (merged (ci-union-packets input (merge-pathnames "payloads/" run)
                                  (merge-pathnames "merged/" work)))
         (summary (ci-collect merged :expected-context server)))
    (unless (getf summary :identity)
      ;; Un run morto prima del piano resta una raccolta incompleta, mai verde.
      (setf (getf summary :identity) initial-identity
            (getf summary :source-id) (getf initial-identity :source-id)
            (getf summary :policy-id) (getf initial-identity :policy-id)
            (getf summary :tested-sha) (getf initial-identity :tested-sha)))
    (setf (getf summary :source-attribution) (ci-validate-provenance summary server))
    (setf (getf summary :server) server
          (getf summary :producer-trust) (if (string= "pull_request" (getf server :event))
                                             :untrusted-pr :repository-workflow))
    (let* ((id (ci-collection-id summary server))
           (collection (merge-pathnames (format nil "collections/~A/" id) run))
           (receipt-id (ci-digest-string (format nil "~A/~A" id (ci-git '("rev-parse" "HEAD") checkout))))
           (receipt (merge-pathnames (format nil "publications/~A.lisp" receipt-id) run))
           (already (ci-lstat collection)))
      (dolist (payload (getf summary :packets))
        (let* ((target (merge-pathnames (format nil "payloads/~A/~A/" (getf payload :job)
                                               (getf payload :digest)) run))
               (origin (ci-directory (getf payload :directory))))
          (if (ci-lstat target)
              (unless (string= (ci-packet-digest target) (getf payload :digest))
                (error "Payload immutabile divergente."))
              (ci-copy-packet origin target))))
      (unless already
        (ci-mkdir collection)
        (ci-save (merge-pathnames "summary.lisp" collection) (ci-public-summary summary))
        (ci-report-markdown summary (merge-pathnames "report.md" collection))
        (ci-save (merge-pathnames "manifest.lisp" collection)
                 (list :schema-version 1 :kind :ci-collection-manifest :collection-id id
                       :files (loop for p in '("summary.lisp" "report.md") collect
                                (ci-file-entry (merge-pathnames p collection) p)))))
      (unless already
        (ensure-directories-exist receipt)
        (ci-save receipt (list :schema-version 1 :kind :ci-publication-receipt
                              :collection-id id :publisher-sha (string-trim '(#\Newline)
                                                              (ci-git '("rev-parse" "HEAD")))
                              :publication-parent (string-trim '(#\Newline)
                                                         (ci-git '("rev-parse" "HEAD") checkout))
                              :source-id (getf summary :source-id)
                              :tested-sha (getf summary :tested-sha) :server server)))
      (unless already (ci-update-index store summary id collection server))
      (when (> (loop for file in (ci-files run :limit 100000 :max-depth 32) sum (ci-bytes file))
               +ci-packet-bytes+)
        (error "Payload, raccolte e ricevute dell'attempt oltre 2MiB."))
      (let ((bytes (loop for file in (ci-files store :limit 200000 :max-depth 32)
                         sum (ci-bytes file))))
        (when (> bytes (- +ci-store-bytes+ (* 2 1024 1024)))
          (error "Archivio CI oltre 254MiB; 2MiB riservati a stato e lacune, artifact GitHub conservati."))
        (when (> bytes (* 128 1024 1024)) (format *error-output* "~&Archivio CI oltre 128MiB.~%")))
      (values summary id (not already)))))

(defun ci-update-index (store summary id collection server)
  (let* ((index-path (merge-pathnames "index.lisp" store))
         (index (if (ci-lstat index-path) (ci-read index-path) (list :schema-version 1 :kind :ci-index :runs nil)))
         (entry (list :source-id (getf summary :source-id) :tested-sha (getf summary :tested-sha)
                      :policy-id (getf summary :policy-id) :run-id (getf server :run-id)
                      :attempt (getf server :attempt) :collection-id id
                      :path (enough-namestring collection store)
                      :collection-closed (getf summary :collection-closed)
                      :metrics-complete (getf summary :metrics-complete)
                      :verification-passed (getf summary :verification-passed))))
    (setf (getf index :runs)
          (cons entry (remove-if (lambda (old)
                         (and (equal (getf old :run-id) (getf entry :run-id))
                              (equal (getf old :attempt) (getf entry :attempt)))) (getf index :runs))))
    (ci-save index-path index :replace t)
    (with-open-file (out (merge-pathnames "README.md" store) :direction :output :if-exists :supersede)
      (format out "# Risultati CI archiviati~%~%Ultima raccolta archiviata: [run ~A, attempt ~A](~Areport.md).~%~%"
              (getf server :run-id) (getf server :attempt) (getf entry :path))
      (format out "Codice provato: `~A`. Questo indice descrive l'ultima pubblicazione, e può riferirsi a codice precedente al main attuale.~%~%"
              (getf summary :tested-sha))
      (format out "Per conoscere lo stato dei sorgenti attuali: `make ci-status`.~%~%Prestazioni esplorative su runner GitHub; copertura di forme e rami, senza attestazione MC/DC.~%"))
    entry))

(defun ci-git-fetch-main ()
  (ci-git '("-c" "credential.helper=" "-c" "credential.helper=!gh auth git-credential"
            "fetch" "--no-tags" "origin" "main"))
  (string-trim '(#\Newline) (ci-git '("rev-parse" "refs/remotes/origin/main"))))

(defun ci-publish-data (input server identity &key dry-run)
  (let ((work (ci-fresh-directory "publisher")))
    (loop for attempt from 1 to *ci-push-attempts*
          for parent = (ci-git-fetch-main)
          for round = (ci-mkdir (merge-pathnames (format nil "round-~D/" attempt) work))
          for checkout = (merge-pathnames "checkout/" round)
          do (ci-git (list "worktree" "add" "--detach" (namestring checkout) parent))
             (unwind-protect
                  (multiple-value-bind (summary id changed)
                      (ci-write-store checkout input server identity round)
                    (ci-save (merge-pathnames "publication.lisp" round)
                             (list :schema-version 1 :kind :ci-publication :dry-run (not (null dry-run))
                                   :collection-id id :parent parent :summary (ci-public-summary summary)))
                    (unless changed (return-from ci-publish-data (values :unchanged round)))
                    (ci-git (list "add" "--" *ci-store-prefix*) checkout)
                    (let ((paths (%ci-nul-records (ci-git '("diff" "--cached" "--name-only" "-z") checkout))))
                      (unless (and paths (every (lambda (p) (%ci-prefix-p *ci-store-prefix* p)) paths))
                        (error "Il publisher ha toccato percorsi esterni all'archivio CI.")))
                    (ci-git (list "-c" "user.name=github-actions[bot]"
                                  "-c" "user.email=41898282+github-actions[bot]@users.noreply.github.com"
                                  "commit" "-m" (format nil "ci(results): archive run ~A attempt ~A"
                                                       (getf server :run-id) (getf server :attempt))) checkout)
                    (when dry-run (return-from ci-publish-data (values :dry-run round)))
                    (handler-case
                        (progn
                          (ci-git '("-c" "credential.helper=" "-c" "credential.helper=!gh auth git-credential"
                                    "push" "origin" "HEAD:refs/heads/main") checkout)
                          (return-from ci-publish-data (values :published round)))
                      (error (c)
                        (ci-save (merge-pathnames "push-failure.lisp" round)
                                 (list :kind :ci-push-failure :round attempt :reason (princ-to-string c)))
                        (when (= attempt *ci-push-attempts*) (error c)))))
               ;; Rimuove soltanto il checkout temporaneo posseduto dal publisher.
               (ci-git (list "worktree" "remove" "--force" (namestring checkout)))))))

(defun ci-publish (run-id attempt &key dry-run)
  (let* ((server (ci-github-run run-id attempt)) (work (ci-fresh-directory "download"))
         (input (ci-github-download run-id attempt (merge-pathnames "input/" work)))
         (summary (ci-collect input :expected-context server))
         (identity (getf summary :identity)))
    (unless identity
      (let ((sha (getf server :head-sha)))
        (ci-git (list "fetch" "--no-tags" "origin" sha))
        (setf identity (ci-identity-summary (ci-source sha)))))
    (ci-publish-data input server identity :dry-run dry-run)))

(defun ci-publish-reconciliation (state)
  "Il cursore compete con gli altri publisher tramite gli stessi normali push."
  (let ((work (ci-fresh-directory "cursor")))
    (loop for attempt from 1 to *ci-push-attempts*
          for parent = (ci-git-fetch-main)
          for checkout = (merge-pathnames (format nil "checkout-~D/" attempt) work)
          do (ci-git (list "worktree" "add" "--detach" (namestring checkout) parent))
             (unwind-protect
                  (let* ((relative (concatenate 'string *ci-store-prefix* "reconciliation/state.lisp"))
                         (path (merge-pathnames relative checkout))
                         (receipt (merge-pathnames
                                   (format nil "~Areconciliation/runs/~A-~A.lisp" *ci-store-prefix*
                                           (ci-positive-id (or (uiop:getenv "GITHUB_RUN_ID")
                                                               (format nil "~D" (get-universal-time))))
                                           (ci-positive-id (or (uiop:getenv "GITHUB_RUN_ATTEMPT") "1"))) checkout)))
                    (ensure-directories-exist receipt)
                    (ci-save path state :replace t)
                    (if (ci-lstat receipt)
                        (unless (equal (ci-read receipt) state) (error "Ricevuta cursore già presente e diversa."))
                        (ci-save receipt state))
                    (when (> (loop for file in (ci-files (merge-pathnames *ci-store-prefix* checkout)
                                                        :limit 200000 :max-depth 32)
                                   sum (ci-bytes file)) +ci-store-bytes+)
                      (error "Archivio CI, compresi i marker di recupero, oltre 256MiB."))
                    (ci-git (list "add" "--" relative (enough-namestring receipt checkout)) checkout)
                    (ci-git (list "-c" "user.name=github-actions[bot]"
                                  "-c" "user.email=41898282+github-actions[bot]@users.noreply.github.com"
                                  "commit" "-m" "ci(results): persist reconciliation cursor") checkout)
                    (handler-case
                        (progn
                          (ci-git '("-c" "credential.helper=" "-c" "credential.helper=!gh auth git-credential"
                                    "push" "origin" "HEAD:refs/heads/main") checkout)
                          (return-from ci-publish-reconciliation :published))
                      (error (c) (when (= attempt *ci-push-attempts*) (error c)))))
               (ci-git (list "worktree" "remove" "--force" (namestring checkout)))))))

(defun ci-pair-less-p (a b)
  (or (< (parse-integer (first a)) (parse-integer (first b)))
      (and (equal (first a) (first b)) (< (second a) (second b)))))

(defun ci-reconcile (limit)
  (unless (<= 1 limit 100) (error "Limite riconciliazione: 1..100."))
  (let* ((results nil) (count 0) (pairs nil) (last nil) (window-truncated nil)
         (parent (ci-git-fetch-main))
         (previous (handler-case
                       (%ci-parse-wire (ci-git (list "show" (concatenate 'string parent ":"
                                                                 *ci-store-prefix* "reconciliation/state.lisp"))))
                     (error () nil)))
         (cursor (getf previous :cursor)))
    ;; Finestra bounded di 14 giorni; si visita ogni attempt terminale, non solo l'ultimo.
    (loop for page from 1 to 20
          for rows = (ci-api-lines
             (format nil "repos/~A/actions/workflows/ci.yml/runs?per_page=100&page=~D&status=completed&created=>=~A"
                     (ci-repository) page
                     (multiple-value-bind (s m h d month y) (decode-universal-time (- (get-universal-time) (* 14 86400)) 0)
                       (declare (ignore s m h)) (format nil "~4,'0D-~2,'0D-~2,'0D" y month d)))
             ".workflow_runs[] | [.id,.run_attempt] | @tsv")
          do (dolist (row rows)
               (unless (= 2 (length row)) (error "Inventario run GitHub invalido."))
               (ci-positive-id (first row)) (ci-positive-id (second row))
               (when (> (parse-integer (second row)) 1000) (error "Troppi attempt per run."))
               (loop for a from 1 to (parse-integer (second row))
                     do (push (list (first row) a) pairs)))
          when (< (length rows) 100) return nil
          finally (setf window-truncated t))
    (setf pairs (sort pairs #'ci-pair-less-p))
    (let* ((remaining (if cursor (remove-if-not (lambda (p) (ci-pair-less-p cursor p)) pairs) pairs))
           (selected (subseq remaining 0 (min limit (length remaining)))))
      (dolist (pair selected)
        (let ((attempt (format nil "~D" (second pair))) (run-id (first pair)))
                          (handler-case
                              (multiple-value-bind (state path) (ci-publish run-id attempt)
                                (push (list :run-id run-id :attempt attempt :status state
                                            :record (namestring path)) results))
                            (error (c) (push (list :run-id run-id :attempt attempt
                                                  :status :failed :reason (princ-to-string c)) results)))
          (incf count) (setf last pair)))
    (let ((out (ci-fresh-directory "reconciliation")))
      (let ((state (list :schema-version 1 :kind :ci-reconciliation :limit limit :window-days 14
                         :visited count :results (reverse results)
                         :cursor (when (< count (length remaining)) last)
                         :cursor-policy :run-and-attempt :truncated (< count (length remaining))
                         :window-truncated window-truncated :recorded-at (get-universal-time)
                         :gap-before-cursor (and cursor pairs (ci-pair-less-p cursor (first pairs)))
                         :retention-days 30 :maximum-lag-days 7 :interval-hours 6)))
        (ci-save (merge-pathnames "report.lisp" out) state)
        (ci-publish-reconciliation state))
      (if (or window-truncated (some (lambda (r) (eq :failed (getf r :status))) results)) 1 0)))))
