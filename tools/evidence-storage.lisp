;;;; Prove conservate come bytes: dati Lisp plain o descriptor gzip verificato.
;;; REQ: REQ-VAL-001 REQ-AFF-012
;;; SB-POSIX e SB-ALIEN sono componenti di SBCL; nessuna libreria esterna.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :sb-posix))

(defpackage #:arcdocdb.evidence
  (:use #:cl)
  (:export #:read-evidence #:call-with-evidence-bytes
           #:file-bytes #:file-sha256 #:invalid-evidence))

(in-package #:arcdocdb.evidence)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(define-condition invalid-evidence (error)
  ((path :initarg :path :reader evidence-path)
   (diagnostic :initarg :diagnostic :reader evidence-diagnostic))
  (:report (lambda (condition stream)
             (format stream "Evidenza non valida ~A: ~A"
                     (evidence-path condition) (evidence-diagnostic condition)))))

(defun %invalid (path control &rest arguments)
  (error 'invalid-evidence :path path
         :diagnostic (apply #'format nil control arguments)))

(defmacro %with-evidence-errors ((path) &body body)
  `(handler-case (progn ,@body)
     (invalid-evidence (condition) (error condition))
     (error (condition) (%invalid ,path "~A" condition))))

(defun %check-limit (path limit)
  (unless (and (integerp limit) (not (minusp limit)))
    (%invalid path "MAX-EXPANDED-BYTES deve essere un intero non negativo.")))

(defun %directory-pathname (path)
  (make-pathname :name nil :type nil :version nil :defaults path))

;; OPENAT mantiene il payload nella directory posseduta, anche se il nome
;; della directory viene rinominato durante la verifica. NOFOLLOW impedisce
;; che una sostituzione del leaf con un symlink cambi il file aperto.
(sb-alien:define-alien-routine ("openat" %openat) sb-alien:int
  (directory-fd sb-alien:int) (name sb-alien:c-string) (flags sb-alien:int))

(defun %open-regular-at (directory-fd leaf path)
  (let ((fd (%openat directory-fd leaf
                    (logior sb-posix:o-rdonly sb-posix:o-nofollow
                            sb-posix:o-nonblock))))
    (when (minusp fd)
      (error 'sb-posix:syscall-error :name 'openat :errno (sb-alien:get-errno)))
    (unwind-protect
         (progn
           (unless (sb-posix:s-isreg (sb-posix:stat-mode (sb-posix:fstat fd)))
             (%invalid path "Il file deve essere un file regolare."))
           (prog1 (sb-sys:make-fd-stream fd :input t
                                       :element-type '(unsigned-byte 8)
                                       :auto-close t)
             (setf fd nil)))
      (when fd (ignore-errors (sb-posix:close fd))))))

(defun %call-with-source (path function)
  (let* ((real (truename path))
         (base (%directory-pathname real))
         (directory-fd (sb-posix:open
                        (namestring base)
                        (logior sb-posix:o-rdonly sb-posix:o-directory
                                sb-posix:o-nofollow sb-posix:o-nonblock))))
    (unwind-protect
         (with-open-stream (stream (%open-regular-at directory-fd
                                                   (file-namestring real) path))
           (funcall function stream real directory-fd))
      (ignore-errors (sb-posix:close directory-fd)))))

(defun %stream-bytes (stream)
  (sb-posix:stat-size (sb-posix:fstat (sb-sys:fd-stream-fd stream))))

(defun file-bytes (path)
  "Numero di bytes del file regolare, indipendente dalla codifica del testo."
  (%with-evidence-errors (path)
    (%call-with-source path
                       (lambda (stream real directory-fd)
                         (declare (ignore real directory-fd))
                         (%stream-bytes stream)))))

(defun %cleanup-process (process)
  (when process
    (unwind-protect
         (progn
           (when (member (sb-ext:process-status process) '(:running :stopped))
             (sb-ext:process-kill process sb-posix:sigkill))
           (sb-ext:process-wait process))
      (sb-ext:process-close process))))

(defun %check-process (process program path)
  (sb-ext:process-wait process)
  (unless (and (eq :exited (sb-ext:process-status process))
               (eql 0 (sb-ext:process-exit-code process)))
    (%invalid path "~A: stato ~S, exit/signal ~S."
              program (sb-ext:process-status process)
              (sb-ext:process-exit-code process))))

(defun %hex64-p (value)
  (and (stringp value) (= 64 (length value))
       (every (lambda (character)
                (or (char<= #\0 character #\9)
                    (char<= #\a character #\f)
                    (char<= #\A character #\F)))
              value)))

(defun %stream-sha256 (stream path)
  ;; Un FD regolare evita la copia implicita in tempfile di RUN-PROGRAM.
  ;; stdin evita anche l'escaping di nomi contenenti newline in shasum.
  (file-position stream 0)
  (let ((process nil)
        (output (make-array 69 :element-type '(unsigned-byte 8))))
    (unwind-protect
         (progn
           (setf process (sb-ext:run-program "shasum" '("-a" "256")
                                            :search t :wait nil :input stream
                                            :output :stream :error nil))
           (unless process (%invalid path "Impossibile avviare shasum -a 256."))
           (let ((count (read-sequence output (sb-ext:process-output process))))
             (unless (and (= count 68)
                          (= (aref output 64) 32) (= (aref output 65) 32)
                          (= (aref output 66) 45) (= (aref output 67) 10))
               (%invalid path "Output SHA256 di shasum non valido."))
             (%check-process process "shasum -a 256" path)
             (let ((hash (map 'string #'code-char (subseq output 0 64))))
               (unless (%hex64-p hash)
                 (%invalid path "shasum non ha restituito 64 cifre esadecimali."))
               (string-downcase hash))))
      (unwind-protect (%cleanup-process process)
        (file-position stream 0)))))

(defun file-sha256 (path)
  "SHA256 dei bytes originali: esattamente 64 cifre esadecimali lowercase."
  (%with-evidence-errors (path)
    (%call-with-source path
                       (lambda (stream real directory-fd)
                         (declare (ignore real directory-fd))
                         (%stream-sha256 stream path)))))

(defun %read-limited-octets (stream path limit)
  (let ((size (%stream-bytes stream)))
    (when (> size limit)
      (%invalid path "~D bytes superano MAX-EXPANDED-BYTES (~D)." size limit))
    (when (>= size array-dimension-limit)
      (%invalid path "~D bytes superano il limite degli array SBCL." size))
    (file-position stream 0)
    (let ((octets (make-array size :element-type '(unsigned-byte 8))))
      (unless (= size (read-sequence octets stream))
        (%invalid path "Il file si è accorciato durante la lettura (~D bytes)." size))
      (unless (eq :eof (read-byte stream nil :eof))
        (%invalid path "Il file è cresciuto durante la lettura limitata."))
      octets)))

(defun %descriptor-candidate-p (octets)
  "Riconosce il marker al primo livello senza interpretare simboli o dati.
Stringhe, commenti e valori annidati non sono marker. Il parser Lisp completo
viene usato soltanto per un candidato descriptor, mai per un report plain."
  (let ((position 0) (size (length octets)) (depth 0) (kind-p nil))
    (labels ((take () (when (< position size)
                       (prog1 (aref octets position) (incf position))))
             (peek () (when (< position size) (aref octets position)))
             (space-p (byte) (member byte '(9 10 12 13 32)))
             (delimiter-p (byte)
               (or (null byte) (space-p byte) (member byte '(40 41 34 59 39 96 44))))
             (skip-string ()
               (loop for byte = (take) while byte
                     do (cond ((= byte 92) (take))
                              ((= byte 34) (return)))))
             (skip-comment ()
               (loop with nesting = 1 for byte = (take) while byte
                     do (cond ((and (= byte 35) (eql (peek) 124))
                               (take) (incf nesting))
                              ((and (= byte 124) (eql (peek) 35))
                               (take) (when (zerop (decf nesting)) (return))))))
             (atom-token (first-byte)
               ;; Se il token supera 32 caratteri non può essere il marker.
               (let ((token (make-string 32)) (count 0) (quoted nil)
                     (escaped nil) (byte first-byte))
                 (loop
                   (cond
                     (escaped
                      (when (< count 32) (setf (char token count) (code-char byte)))
                      (incf count) (setf escaped nil))
                     ((= byte 92) (setf escaped t))
                     ((= byte 124) (setf quoted (not quoted)))
                     (t
                      (when (< count 32)
                        (setf (char token count)
                              (code-char (if (and (not quoted) (<= 97 byte 122))
                                             (- byte 32) byte))))
                      (incf count)))
                   (when (or (null (peek))
                             (and (not quoted) (not escaped) (delimiter-p (peek))))
                     (return (and (<= count 32) (subseq token 0 count))))
                   (setf byte (take)))))
             (next-token ()
               (loop for byte = (take)
                     do (cond
                          ((null byte) (return (values :eof nil)))
                          ((space-p byte))
                          ((= byte 59)
                           (loop for c = (take) while (and c (/= c 10))))
                          ((and (= byte 35) (eql (peek) 124))
                           (take) (skip-comment))
                          ((and (= byte 35) (eql (peek) 92))
                           (take) (take)
                           (loop until (delimiter-p (peek)) do (take))
                           (return (values :other nil)))
                          ((= byte 34) (skip-string) (return (values :other nil)))
                          ((= byte 40) (return (values :open nil)))
                          ((= byte 41) (return (values :close nil)))
                          ((member byte '(39 96 44))
                           (return (values :prefix nil)))
                          (t (return (values :atom (atom-token byte))))))))
      (loop
        (multiple-value-bind (type token) (next-token)
          (case type
            (:eof (return nil))
            (:open (incf depth) (setf kind-p nil))
            (:close
             (decf depth) (setf kind-p nil)
             (when (<= depth 0) (return nil)))
            (:prefix (setf kind-p nil))
            (otherwise
             (when (= depth 1)
               (when (and kind-p (equal token ":COMPRESSED-EVIDENCE"))
                 (return t))
               (setf kind-p (equal token ":KIND"))))))))))

(defun %read-plist-stream (stream path)
  (let ((*read-eval* nil) (*readtable* (copy-readtable nil)) (*read-base* 10)
        (*read-suppress* nil) (eof (gensym "EOF")))
    (let* ((data (read stream nil eof))
           (length (and (consp data) (list-length data))))
      (unless (and length (evenp length)
                   (loop for key in data by #'cddr always (keywordp key)))
        (%invalid path "È richiesta una plist non vuota, propria e aciclica con chiavi keyword."))
      (unless (eq eof (read stream nil eof))
        (%invalid path "Il file contiene più di una forma Lisp."))
      data)))

(defun %read-plist (octets path)
  ;; Solo descriptor piccoli; i report grandi si leggono direttamente dal file.
  (with-input-from-string (stream (sb-ext:octets-to-string octets :external-format :default))
    (%read-plist-stream stream path)))

(defun %descriptor-p (data)
  (loop for (key value) on data by #'cddr
        thereis (and (eq key :kind) (eq value :compressed-evidence))))

(defun %leaf-p (value)
  (and (stringp value) (plusp (length value))
       (not (member value '("." "..") :test #'string=))
       (not (find-if (lambda (character)
                       (or (zerop (char-code character))
                           (find character "/\\*?[]")))
                     value))))

(defun %validate-descriptor (data path limit)
  (let ((fields '(:schema-version :kind :codec :payload :uncompressed-bytes
                  :uncompressed-sha256 :compressed-bytes :compressed-sha256))
        (seen nil))
    (loop for (key value) on data by #'cddr
          do (unless (member key fields)
              (%invalid path "Campo descriptor sconosciuto: ~S." key))
             (when (member key seen)
               (%invalid path "Campo descriptor duplicato: ~S." key))
             (push key seen))
    (unless (= (length fields) (length seen))
      (%invalid path "Campi descriptor mancanti: ~S." (set-difference fields seen)))
    (unless (and (eql 1 (getf data :schema-version))
                 (eq :compressed-evidence (getf data :kind))
                 (eq :gzip (getf data :codec)))
      (%invalid path "Descriptor richiesto: schema-version 1, kind :compressed-evidence, codec :gzip."))
    (unless (%leaf-p (getf data :payload))
      (%invalid path "PAYLOAD deve essere un nome leaf non vuoto, senza NUL o wildcard."))
    (dolist (key '(:uncompressed-bytes :compressed-bytes))
      (unless (and (integerp (getf data key)) (not (minusp (getf data key))))
        (%invalid path "~S deve essere un intero non negativo." key)))
    (dolist (key '(:uncompressed-sha256 :compressed-sha256))
      (unless (%hex64-p (getf data key))
        (%invalid path "~S deve contenere esattamente 64 cifre esadecimali." key)))
    (when (> (getf data :uncompressed-bytes) limit)
      (%invalid path "UNCOMPRESSED-BYTES (~D) supera MAX-EXPANDED-BYTES (~D)."
                (getf data :uncompressed-bytes) limit))
    data))

(defun %make-temporary ()
  (let ((directory (or (sb-ext:posix-getenv "TMPDIR") "/tmp")))
    (sb-posix:mkstemp (concatenate 'string (string-right-trim "/" directory)
                                  "/arcdocdb-evidence-XXXXXX"))))

(defun %expand-to-temporary (input descriptor path limit)
  (multiple-value-bind (fd name) (%make-temporary)
    (let ((temporary (pathname name)) (stream nil) (process nil) (completed nil))
      (unwind-protect
           (progn
             (setf stream (sb-sys:make-fd-stream fd :input t :output t
                                               :element-type '(unsigned-byte 8)
                                               :auto-close t)
                   fd nil)
             (file-position input 0)
             (setf process (sb-ext:run-program "gzip" '("-dc")
                                              :search t :wait nil :input input
                                              :output :stream :error nil))
             (unless process (%invalid path "Impossibile avviare gzip -dc."))
             (let ((buffer (make-array 65536 :element-type '(unsigned-byte 8)))
                   (expected (getf descriptor :uncompressed-bytes)) (total 0))
               (loop for count = (read-sequence
                                  buffer (sb-ext:process-output process)
                                  :end (min (length buffer) (1+ (- expected total))))
                     until (zerop count)
                     do (when (or (> (+ total count) expected)
                                  (> (+ total count) limit))
                          (%invalid path "gzip supera la dimensione dichiarata (~D) o il limite (~D)."
                                    expected limit))
                        ;; Il controllo precede ogni write: mai un tempfile oltre N.
                        (write-sequence buffer stream :end count)
                        (incf total count))
               (%check-process process "gzip -dc" path)
               (unless (= total expected)
                 (%invalid path "Dimensione espansa ~D, attesa ~D." total expected)))
             (finish-output stream)
             (unless (string-equal (getf descriptor :uncompressed-sha256)
                                   (%stream-sha256 stream path))
               (%invalid path "SHA256 dei bytes espansi diverso da UNCOMPRESSED-SHA256."))
             (close stream) (setf stream nil)
             (setf completed t)
             temporary)
        (unwind-protect (%cleanup-process process)
          (unwind-protect
               (if stream (close stream :abort t)
                   (when fd (sb-posix:close fd)))
            (unless completed (delete-file temporary))))))))

(defun %prepare-evidence-bytes (path limit)
  (%call-with-source
   path
   (lambda (source real directory-fd)
     ;; Il budget dei byte espansi non include il piccolo descriptor. Anche un
     ;; record di pochi byte deve poter usare un descriptor con due SHA-256.
     (let ((octets (%read-limited-octets source path (max limit 1048576))))
       (unless (%descriptor-candidate-p octets)
         (when (> (length octets) limit)
           (%invalid path "~D bytes plain superano MAX-EXPANDED-BYTES (~D)."
                     (length octets) limit))
         (return-from %prepare-evidence-bytes (values (pathname path) nil)))
       (let ((descriptor (%read-plist octets path)))
         (unless (%descriptor-p descriptor)
           (when (> (length octets) limit)
             (%invalid path "~D bytes plain superano MAX-EXPANDED-BYTES (~D)."
                       (length octets) limit))
           (return-from %prepare-evidence-bytes (values (pathname path) nil)))
         (%validate-descriptor descriptor path limit)
         (let* ((base (%directory-pathname real))
                (candidate (make-pathname :name (getf descriptor :payload)
                                          :type nil :version nil :defaults base))
                (payload (truename candidate)))
           (unless (equal (%directory-pathname payload) base)
             (%invalid path "PAYLOAD ~S esce dalla directory reale ~A (risolto: ~A)."
                       (getf descriptor :payload) base payload))
           (with-open-stream (input (%open-regular-at directory-fd
                                                     (file-namestring payload) path))
             (unless (= (%stream-bytes input) (getf descriptor :compressed-bytes))
               (%invalid path "Dimensione PAYLOAD ~D, COMPRESSED-BYTES ~D."
                         (%stream-bytes input) (getf descriptor :compressed-bytes)))
             (unless (string-equal (getf descriptor :compressed-sha256)
                                   (%stream-sha256 input path))
               (%invalid path "SHA256 del PAYLOAD diverso da COMPRESSED-SHA256."))
             (let ((temporary (%expand-to-temporary input descriptor path limit)))
               (values temporary temporary)))))))))

(defun call-with-evidence-bytes (path function &key (max-expanded-bytes 134217728))
  "Chiama FUNCTION con un pathname plain e restituisce tutti i suoi valori.
Plain: limite sui bytes e pathname originale. Descriptor: campi, directory,
bytes/hash gzip, espansione limitata e hash espanso verificati prima del callback.
Il contenuto espanso NON viene letto come Lisp. Il pathname temporaneo è valido
solo durante il callback e viene eliminato anche se FUNCTION genera un errore."
  (%check-limit path max-expanded-bytes)
  (let ((temporary nil))
    (unwind-protect
         (multiple-value-bind (plain owned-temporary)
             (%with-evidence-errors (path)
               (%prepare-evidence-bytes path max-expanded-bytes))
           (setf temporary owned-temporary)
           (funcall function plain))
      (when temporary (delete-file temporary)))))

(defun read-evidence (path &key (max-expanded-bytes 134217728))
  "Una sola plist con chiavi keyword, READ-EVAL NIL, nessun LOAD dei dati.
Supporta plain e un solo livello di descriptor; un payload descriptor è vietato."
  (call-with-evidence-bytes
   path
   (lambda (plain)
     (%with-evidence-errors (path)
       (%call-with-source
        plain
        (lambda (stream real directory-fd)
          (declare (ignore real directory-fd))
          (let ((size (%stream-bytes stream)))
            (when (> size max-expanded-bytes)
              (%invalid path "~D bytes superano MAX-EXPANDED-BYTES (~D)."
                        size max-expanded-bytes))
            (file-position stream 0)
            ;; DUP mantiene il file regolare già aperto e verificato. Il lettore
            ;; testuale evita la copia integrale UTF-8 in una stringa a 4 byte/char.
            (with-open-stream
                (text (sb-sys:make-fd-stream (sb-posix:dup (sb-sys:fd-stream-fd stream))
                                             :input t :element-type 'character
                                             :external-format :default :auto-close t))
              (let ((data (%read-plist-stream text path)))
                (unless (= size (%stream-bytes stream))
                  (%invalid path "Il file è cambiato durante la lettura dei dati."))
                (when (%descriptor-p data)
                  (%invalid path "Un payload descriptor annidato non è consentito."))
                data)))))))
   :max-expanded-bytes max-expanded-bytes))
