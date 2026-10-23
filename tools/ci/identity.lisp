;;;; C4: identità dei soli oggetti Git e verifica separata dei byte del checkout.
;;; REQ: REQ-VAL-001 REQ-AFF-012
(in-package #:arcdocdb.ci)
(declaim (optimize (safety 3) (debug 3)))

(defparameter *ci-source-max-files* 200000)
(defparameter *ci-source-max-file-bytes* 268435456)
(defparameter *ci-source-max-total-bytes* 4294967296)

(defun %ci-prefix-p (prefix value)
  (and (<= (length prefix) (length value))
       (string= prefix value :end2 (length prefix))))

(defun %ci-results-path-p (path)
  (%ci-prefix-p "spikes/results/ci/" path))

(defun %ci-working-output-p (path)
  (or (%ci-results-path-p path) (%ci-prefix-p "spikes/out/" path)
      ;; Cache ricostruibili degli undici spike: nomi chiusi, non qualsiasi /out/.
      (loop for name in '("SPK-01-primary-index" "SPK-02-gc" "SPK-03-group-commit"
                           "SPK-04-writer-pool" "SPK-05-segment-read" "SPK-06-compaction-load"
                           "SPK-07-protocols" "SPK-08-generated-code" "SPK-09-integrity" "SPK-10-v2-limits"
                           "SPK-11-unix-socket")
            thereis (%ci-prefix-p (format nil "spikes/~A/out/" name) path))))

(defun %ci-one-line (text)
  ;; Rimuove soltanto il LF finale del protocollo, non spazi dei nomi Git.
  (unless (and (plusp (length text)) (char= #\Newline (char text (1- (length text)))))
    (%ci-fail "Risposta Git senza terminatore LF."))
  (let ((line (subseq text 0 (1- (length text)))))
    (when (find #\Newline line) (%ci-fail "Risposta Git con più righe."))
    line))

(defun %ci-hex-p (text size)
  (and (stringp text) (= size (length text))
       (every (lambda (character)
                (or (char<= #\0 character #\9) (char<= #\a character #\f)
                    (char<= #\A character #\F))) text)))

(defun %ci-ref (ref)
  (unless (and (stringp ref)
               (or (string= ref "HEAD") (%ci-hex-p ref 40) (%ci-hex-p ref 64)))
    (%ci-fail "Ref ammessa: HEAD oppure SHA completa di 40/64 cifre."))
  (let* ((format (%ci-one-line (ci-git '("rev-parse" "--show-object-format"))))
         (width (cond ((string= format "sha1") 40) ((string= format "sha256") 64)
                      (t (%ci-fail "Object format Git non supportato."))))
         (checked-ref (if (string= ref "HEAD") ref
                          (progn
                            (unless (= width (length ref))
                              (%ci-fail "SHA di larghezza diversa dall'object format Git."))
                            (string-downcase ref))))
         (sha (%ci-one-line
               (ci-git (list "rev-parse" "--verify" "--end-of-options"
                             (concatenate 'string checked-ref "^{commit}"))))))
    (unless (and (%ci-hex-p sha width)
                 (or (string= ref "HEAD") (string= sha checked-ref)))
      (%ci-fail "Commit Git non valido: richiesta SHA completa del commit, non tag/abbreviazione."))
    (values (string-downcase sha) format width)))

(defun %ci-nul-records (text)
  (let ((records nil) (start 0) (count 0))
    (loop for index below (length text)
          when (char= (char text index) #\Null)
            do (when (= start index) (%ci-fail "Record NUL vuoto."))
               (when (> (incf count) *ci-source-max-files*)
                 (%ci-fail "Inventario Git oltre il limite file."))
               (push (subseq text start index) records)
               (setf start (1+ index)))
    (unless (= start (length text)) (%ci-fail "Protocollo Git senza NUL finale."))
    (nreverse records)))

(defun %ci-git-path (path)
  ;; I path Git non sono path di payload: conserva UTF-8, tab, LF e metacaratteri.
  ;; Per tutti i nomi si usa argv o stdin, mai espansione della shell/pathspec.
  (unless (and (plusp (length path)) (<= (length (%ci-utf8 path)) 4096)
               (not (char= (char path 0) #\/)) (not (find #\Null path)))
    (%ci-fail "Path Git non rappresentabile."))
  (let ((parts (uiop:split-string path :separator "/")))
    (unless (and (<= (length parts) 128)
                 (every (lambda (part)
                          (and (plusp (length part))
                               (not (member part '("." "..") :test #'equal)))) parts))
      (%ci-fail "Path Git non canonico o troppo profondo.")))
  path)

(defun %ci-byte-less-p (left right)
  (let ((a (%ci-utf8 left)) (b (%ci-utf8 right)))
    (loop for index below (min (length a) (length b))
          when (/= (aref a index) (aref b index))
            do (return-from %ci-byte-less-p (< (aref a index) (aref b index))))
    (< (length a) (length b))))

(defun %ci-tree-rows (sha width)
  (let ((seen (make-hash-table :test #'equal)) (rows nil))
    (dolist (record (%ci-nul-records (ci-git (list "ls-tree" "-rz" "--full-tree" sha))))
      (let ((tab (position #\Tab record)))
        (unless tab (%ci-fail "Header ls-tree senza TAB."))
        (let* ((fields (uiop:split-string (subseq record 0 tab) :separator " "))
               (mode (first fields)) (type (second fields)) (blob (third fields))
               (path (%ci-git-path (subseq record (1+ tab)))))
          (unless (= 3 (length fields)) (%ci-fail "Header ls-tree non valido."))
          (when (gethash path seen) (%ci-fail "Path Git duplicato."))
          (setf (gethash path seen) t)
          (unless (%ci-results-path-p path)
            ;; Politica esplicita: symlink (120000) e gitlink (160000) vietati.
            (unless (and (member mode '("100644" "100755") :test #'string=)
                         (string= type "blob") (%ci-hex-p blob width))
              (%ci-fail "Sorgente ~S: symlink, submodule o modo Git non ammesso." path))
            (push (list :path path :mode mode :blob (string-downcase blob) :bytes 0) rows)))))
    (sort rows #'%ci-byte-less-p :key (lambda (row) (getf row :path)))))

(defun %ci-small-line (stream limit)
  (let ((line (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (loop for character = (read-char stream nil nil)
          do (unless character (%ci-fail "EOF nel protocollo cat-file."))
             (when (char= character #\Newline) (return (coerce line 'string)))
             (when (>= (length line) limit) (%ci-fail "Header cat-file troppo lungo."))
             (vector-push-extend character line))))

(defun %ci-decimal (text maximum)
  (unless (plusp (length text)) (%ci-fail "Dimensione Git vuota."))
  (let ((value 0))
    (loop for character across text
          do (unless (char<= #\0 character #\9) (%ci-fail "Dimensione Git non decimale."))
             (setf value (+ (* value 10) (- (char-code character) 48)))
             (when (> value maximum) (%ci-fail "Dimensione Git oltre il budget.")))
    value))

(defun %ci-object-statistics (rows)
  "CAT-FILE su OID validati: byte opachi contati progressivamente, mai caricati."
  (let ((total 0) (statistics (make-hash-table :test #'equal))
        (request (with-output-to-string (stream)
                   (dolist (row rows) (write-line (getf row :blob) stream)))))
    (when (> (length request) *ci-command-max-bytes*)
      (%ci-fail "Richiesta cat-file oltre il budget."))
    (with-input-from-string (input request)
      (%ci-call-program
       (%ci-git-argv '("cat-file" "--batch") *ci-root*) input
       (lambda (stream)
         (dolist (row rows)
           (let* ((fields (uiop:split-string (%ci-small-line stream 256) :separator " "))
                  (size (and (= 3 (length fields))
                             (%ci-decimal (third fields) *ci-source-max-file-bytes*)))
                  (lines 0) (last-byte nil))
             (unless (and size (string= (first fields) (getf row :blob))
                          (string= (second fields) "blob"))
               (%ci-fail "Header cat-file inatteso."))
             (incf total size)
             (when (> total *ci-source-max-total-bytes*)
               (%ci-fail "Sorgenti oltre il budget aggregato byte."))
             (loop repeat size for character = (read-char stream nil nil)
                   do (unless character (%ci-fail "EOF nei byte di un blob."))
                      (setf last-byte (char-code character))
                      (when (= last-byte 10) (incf lines)))
             (when (and last-byte (/= last-byte 10)) (incf lines))
             (unless (eql #\Newline (read-char stream nil nil))
               (%ci-fail "Separatore cat-file mancante."))
             (setf (getf row :bytes) size
                   (gethash (getf row :path) statistics) lines)))
         (when (read-char stream nil nil) (%ci-fail "Byte dopo l'inventario cat-file.")))))
    statistics))

(defun %ci-policy-path-p (path)
  (or (%ci-prefix-p "tools/ci/" path) (string= path "tools/ci.lisp")
      (string= path "tests/ci-catalog.lisp") (%ci-prefix-p ".github/" path)
      (string= path "Makefile")))

(defun %ci-inventory-digest (rows object-format domain)
  ;; V1: domain NUL object-format NUL [path NUL mode NUL blob NUL]*.
  ;; Path ordinati per byte UTF-8; né dimensioni né SHA del commit nel digest.
  (let ((canonical
          (with-output-to-string (stream)
            (write-string domain stream) (write-char #\Null stream)
            (write-string object-format stream) (write-char #\Null stream)
            (dolist (row rows)
              (dolist (key '(:path :mode :blob))
                (write-string (getf row key) stream) (write-char #\Null stream))))))
    (ci-digest-string canonical)))

(defun %ci-lisp-path-p (path)
  (let ((dot (position #\. path :from-end t)))
    (and dot (string-equal (subseq path dot) ".lisp"))))

(defun %ci-module (path)
  (let ((slash (position #\/ path)))
    (cond ((null slash) ".")
          ((%ci-prefix-p "src/" path)
           (let ((next (position #\/ path :start 4)))
             (if next (subseq path 0 next) "src")))
          (t (subseq path 0 slash)))))

(defun %ci-source-statistics (rows line-counts)
  (let ((bytes 0) (lisp 0) (lines 0) (modules (make-hash-table :test #'equal)))
    (dolist (row rows)
      (let* ((path (getf row :path)) (module (%ci-module path))
             (size (getf row :bytes)) (count (gethash path line-counts))
             (lisp-file (if (%ci-lisp-path-p path) 1 0))
             (summary (or (gethash module modules)
                          (setf (gethash module modules)
                                (list :path module :source-files 0 :source-bytes 0
                                      :lisp-files 0 :physical-lines 0)))))
        (incf bytes size) (incf lisp lisp-file) (incf lines count)
        (incf (getf summary :source-files)) (incf (getf summary :source-bytes) size)
        (incf (getf summary :lisp-files) lisp-file) (incf (getf summary :physical-lines) count)))
    (list :source-files (length rows) :source-bytes bytes :lisp-files lisp
          :physical-lines lines
          :modules (sort (loop for summary being the hash-values of modules collect summary)
                         #'%ci-byte-less-p :key (lambda (summary) (getf summary :path))))))

(defun %ci-source-key (sha rows object-format)
  (list :tested-sha sha
        :source-id (%ci-inventory-digest rows object-format "arcdocdb-ci-source-v1")
        :policy-id (%ci-inventory-digest (remove-if-not
                                        (lambda (row) (%ci-policy-path-p (getf row :path))) rows)
                                       object-format "arcdocdb-ci-policy-v1")))

(defun ci-source-key (ref)
  "Identità dei contenuti senza statistiche: stessi inventario, limiti ed esclusioni di CI-SOURCE."
  (multiple-value-bind (sha object-format width) (%ci-ref ref)
    (%ci-source-key sha (%ci-tree-rows sha width) object-format)))

(defun ci-source (&optional (ref "HEAD"))
  "Inventario del commit REF, anche diverso da HEAD; nessun checkout/load.
SOURCE-ID V1 include tutti i tracked salvo spikes/results/ci/. PHYSICAL-LINES
conta LF e ultima riga non terminata in tutti i blob, inclusi quelli binari;
non è una misura di forme Lisp o di righe eseguibili. POLICY-ID V1 seleziona
tools/ci[.lisp|/], tests/ci-catalog.lisp, .github/ e Makefile."
  (multiple-value-bind (sha object-format width) (%ci-ref ref)
    (let* ((rows (%ci-tree-rows sha width))
           (line-counts (%ci-object-statistics rows)))
      (append
       (%ci-source-key sha rows object-format)
       (list :sources rows)
       (%ci-source-statistics rows line-counts)))))

(defun %ci-dirty-index-or-untracked-p (sha)
  ;; --OTHERS senza --EXCLUDE-STANDARD include anche sorgenti nuovi ignorati.
  (or (some (lambda (path) (not (%ci-results-path-p path)))
            (%ci-nul-records (ci-git (list "diff" "--cached" "--name-only" "-z"
                                         "--no-ext-diff" "--no-renames" sha "--"))))
      (some (lambda (path) (not (%ci-working-output-p path)))
            (%ci-nul-records (ci-git '("ls-files" "--others" "-z"))))))

(defun %ci-working-stat (path)
  ;; Concatenazione letterale: nomi Git con wildcard restano nomi, non pattern.
  (let* ((absolute (concatenate 'string
                                (namestring (uiop:ensure-directory-pathname *ci-root*)) path))
         (stat (progn (%ci-check-parents absolute) (sb-posix:lstat absolute))))
    (unless (sb-posix:s-isreg (sb-posix:stat-mode stat))
      (%ci-fail "Sorgente del working tree non regolare: ~S." path))
    (values (list :bytes (sb-posix:stat-size stat)
                  :mode (if (zerop (logand #o111 (sb-posix:stat-mode stat))) "100644" "100755")
                  :device (sb-posix:stat-dev stat) :inode (sb-posix:stat-ino stat)
                  :mtime (sb-posix:stat-mtime stat) :ctime (sb-posix:stat-ctime stat))
            absolute)))

(defun %ci-working-snapshot (rows width)
  (let ((snapshot nil) (remaining rows))
    ;; Batch piccoli evitano ARG_MAX; --NO-FILTERS confronta i byte effettivi,
    ;; anche con assume-unchanged/skip-worktree o filtri/CRLF configurati.
    (loop while remaining
          do (let* ((batch (loop repeat 128 while remaining collect (pop remaining)))
                    (before (mapcar (lambda (row) (%ci-working-stat (getf row :path))) batch))
                   (paths (mapcar (lambda (row) (getf row :path)) batch)))
               (let* ((output (ci-git (append '("hash-object" "--no-filters" "--") paths)))
                      (hashes (uiop:split-string output :separator '(#\Newline))))
                 (unless (and (equal (car (last hashes)) "")
                              (= (length hashes) (1+ (length batch))))
                   (%ci-fail "Hash dei byte working incompleti."))
                 (loop for row in batch for stat in before for blob in hashes
                       for after = (%ci-working-stat (getf row :path))
                       do (unless (and (equal stat after) (%ci-hex-p blob width)
                                       (string= blob (getf row :blob))
                                       (string= (getf stat :mode) (getf row :mode)))
                            (%ci-fail "Byte/modo working mutati o diversi dal commit: ~S."
                                      (getf row :path)))
                          (push (list (getf row :path) blob stat) snapshot)))))
    (nreverse snapshot)))

(defun ci-working-clean-p ()
  "T soltanto per checkout stabile: due snapshot dei byte, index e untracked.
Solo per untracked sono ammesse le cache chiuse degli spike e spikes/out/;
spikes/results/ci/ è escluso dall'identità. Ogni altro tracked è verificato,
anche sotto una directory di output. Secondo valore: diagnostica o NIL.
Non prova assenza di una modifica transitoria poi perfettamente annullata."
  (handler-case
      (multiple-value-bind (sha object-format width) (%ci-ref "HEAD")
        (declare (ignore object-format))
        (let ((rows (%ci-tree-rows sha width)))
          (when (%ci-dirty-index-or-untracked-p sha) (%ci-fail "Index o sorgenti nuovi sporchi."))
          (let ((before (%ci-working-snapshot rows width))
                (after (%ci-working-snapshot rows width)))
            (unless (and (equal before after) (string= sha (nth-value 0 (%ci-ref "HEAD")))
                         (not (%ci-dirty-index-or-untracked-p sha)))
              (%ci-fail "Checkout mutato durante la verifica dei byte.")))
          (values t nil)))
    (error (condition) (values nil (princ-to-string condition)))))
