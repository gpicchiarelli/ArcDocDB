(:DECODING-CONDITION
 #A((41) BASE-CHAR . "Output non decodificabile come soli dati.") :FINISHED-AT
 4000483598 :SCHEMA-VERSION 1 :KIND :COMPILATION-DISASSEMBLY :EXECUTION
 #A((2) BASE-CHAR . "c1") :STATUS :ERROR :CWD
 #A((62) BASE-CHAR
    . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/")
 :ARGV
 ("/opt/homebrew/bin/sbcl" "--noinform" "--no-userinit" "--no-sysinit"
  "--dynamic-space-size" "1024" "--script"
  #A((149) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/lettura-buffer-campagna-20261008-01/driver-compila.lisp")
  "compile-disassemble"
  #A((133) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/lettura-buffer-campagna-20261008-01/c1/"))
 :STDIN "" :DRIVER-ARGV
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  #A((2) BASE-CHAR . "c1"))
 :OPERATION
 "COMPILE-FILE CORE; LOAD; COMPILE-FILE LETTURA-BUFFER; LOAD; DISASSEMBLE LEGGI"
 :BUDGET
 (:CHILD-SECONDS 90 :PARENT-SECONDS 120 :CLEANUP-SECONDS 5 :HEAP-MIB 1024
  :MAX-REVISIONS 4)
 :SOURCE-BEFORE
 ((:PATH
   #A((99) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/core.lisp")
   :HASH-KIND :GIT-BLOB :HASH "c019f6ad53e173a0d336a4dbfaf903e274a66f08"
   :CONTENT
   ";;;; SPK-01: esperimento C4, layout v1 ADR-0043; non verifica v2 ADR-0048.
(defpackage #:arcdocdb.spk01
  (:use #:cl)
  (:export #:check #:benchmark #:make-indice #:inserisci #:elimina #:leggi
           #:scrivi-chiave #:indice-statistiche #:limite-indice))
(in-package #:arcdocdb.spk01)
(declaim (optimize (safety 3) (speed 2) (debug 1)))

(deftype u64 () '(unsigned-byte 64))
(deftype ottetti () '(simple-array (unsigned-byte 8) (*)))
(deftype parole () '(simple-array (unsigned-byte 64) (*)))
(defconstant +mask64+ #xffffffffffffffff)
(defconstant +vuoto+ 255)
(defconstant +eliminato+ 254)
(defconstant +soglia-seq+ (ash 1 62))
(defconstant +gruppo+ 8)
(define-condition limite-indice (error)
  ((motivo :initarg :motivo :reader limite-motivo))
  (:report (lambda (c s) (format s \"Limite SPK-01: ~A\" (limite-motivo c)))))

;;; OWNER: un writer per indice; root letta dai reader, pubblicata solo con CAS.
;;; SHARED: nessuno stato tra Serie; i contatori sono locali al writer.
;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-IDX-005 REQ-IDX-007
(defstruct (frammento (:constructor %frammento))
  (profondita 0 :type fixnum :read-only t)
  (capacita 8 :type fixnum :read-only t)
  (larghezza 4 :type fixnum :read-only t)
  (ctrl (make-array 0 :element-type '(unsigned-byte 8)) :type ottetti :read-only t)
  (slots (make-array 0 :element-type '(unsigned-byte 64)) :type parole :read-only t)
  (chiavi (make-array 0 :element-type '(unsigned-byte 8)) :type ottetti :read-only t)
  (vivi 0 :type fixnum) (morti 0 :type fixnum) (chiavi-usate 0 :type fixnum))
(defstruct (radice (:constructor %radice (generazione profondita directory)))
  (generazione 0 :type fixnum :read-only t)
  (profondita 0 :type fixnum :read-only t)
  (directory #() :type simple-vector :read-only t))
(defstruct (indice (:constructor %indice))
  (root (%radice 0 0 #()) :type radice)
  (capacita 8192 :type fixnum :read-only t)
  (larghezza 4 :type fixnum :read-only t)
  (profondita-massima 20 :type fixnum :read-only t)
  (budget-byte 536870912 :type integer :read-only t)
  (documenti 0 :type fixnum) (frammenti 1 :type fixnum)
  (split 0 :type fixnum) (rebuild 0 :type fixnum)
  (slot-copiati-max 0 :type fixnum)
  (split-ticks 0 :type integer) (split-max-ticks 0 :type integer)
  (rebuild-ticks 0 :type integer) (rebuild-max-ticks 0 :type integer)
  (directory-riferimenti-copiati 0 :type integer)
  (directory-riferimenti-max 0 :type fixnum)
  (directory-ticks 0 :type integer) (directory-max-ticks 0 :type integer)
  (frammento-copia-ticks 0 :type integer) (frammento-copia-max-ticks 0 :type integer)
  (chiavi-byte-copiati 0 :type integer)
  (picco-payload 0 :type integer) (picco-transitorio 0 :type integer))

(declaim (ftype (function (t integer integer) integer) intero-limitato))
(defun intero-limitato (valore minimo massimo)
  (unless (typep valore `(integer ,minimo ,massimo))
    (error 'type-error :datum valore :expected-type `(integer ,minimo ,massimo)))
  valore)
(declaim (ftype (function (frammento) integer) payload-frammento))
(defun payload-frammento (f)
  (* (frammento-capacita f) (+ 17 (* 8 (frammento-larghezza f)))))
(declaim (ftype (function (indice) integer) payload-indice))
(defun payload-indice (i)
  ;; O(1): conteggio dei frammenti del writer, LENGTH della directory.
  (+ (* (indice-frammenti i) (indice-capacita i)
        (+ 17 (* 8 (indice-larghezza i))))
     (* 8 (length (radice-directory (indice-root i))))))
(declaim (ftype (function (indice integer) null) controlla-budget))
(defun controlla-budget (i transitorio)
  (when (> transitorio (indice-budget-byte i))
    (error 'limite-indice :motivo :payload-transitorio))
  (setf (indice-picco-transitorio i)
        (max transitorio (indice-picco-transitorio i)))
  nil)
(declaim (ftype (function (fixnum fixnum fixnum) frammento) nuovo-frammento))
(defun nuovo-frammento (c w profondita)
  (%frammento :capacita c :larghezza w :profondita profondita
              :ctrl (make-array c :element-type '(unsigned-byte 8)
                                :initial-element +vuoto+)
              :slots (make-array (* c w) :element-type '(unsigned-byte 64)
                                        :initial-element 0)
              :chiavi (make-array (* c 16) :element-type '(unsigned-byte 8)
                                         :initial-element 0)))
(declaim (ftype (function (&key (:capacity integer) (:words integer)
                               (:max-depth integer) (:memory-mib integer)) indice)
                make-indice))
(defun make-indice (&key (capacity 8192) (words 4) (max-depth 20) (memory-mib 512))
  (intero-limitato capacity 8 32768)
  (unless (= 1 (logcount capacity))
    (error 'limite-indice :motivo :capacita-non-potenza-di-due))
  (intero-limitato words 4 5)
  (intero-limitato max-depth 0 24)
  (intero-limitato memory-mib 1 8192)
  (let* ((budget (* memory-mib 1024 1024))
         (payload (+ (* capacity (+ 17 (* 8 words))) 8)))
    (when (> payload budget) (error 'limite-indice :motivo :payload-iniziale))
    (%indice :root (%radice 0 0 (vector (nuovo-frammento capacity words 0)))
             :capacita capacity :larghezza words :profondita-massima max-depth
             :budget-byte budget :picco-payload payload
             :picco-transitorio payload)))

;;; REQ: REQ-IDX-001
(declaim (inline mix64 parola-chiave hash-chiave scrivi-chiave
                 scegli-frammento impronta posizione-sonda leggi-slot sonda-reader))
(declaim (ftype (function (u64) u64) mix64))
(defun mix64 (x)
  \"SplitMix64 deterministico, intermedi u64 mascherati; kernel inline.\"
  (declare (type u64 x))
  (let* ((z (logand +mask64+ (+ x #x9e3779b97f4a7c15)))
         (a (logand +mask64+ (* (logxor z (ash z -30)) #xbf58476d1ce4e5b9)))
         (b (logand +mask64+ (* (logxor a (ash a -27)) #x94d049bb133111eb))))
    (declare (type u64 z a b))
    (logxor b (ash b -31))))
(declaim (ftype (function (ottetti fixnum) u64) parola-chiave))
(defun parola-chiave (chiave off)
  (declare (type ottetti chiave) (type fixnum off))
  (let ((parola 0))
    (declare (type u64 parola))
    (dotimes (n 8 parola)
      (declare (type fixnum n))
      (setf parola (logior parola (ash (aref chiave (+ off n)) (* 8 n)))))))
(declaim (ftype (function (ottetti fixnum) u64) hash-chiave))
(defun hash-chiave (chiave off)
  (declare (type ottetti chiave) (type fixnum off))
  (let* ((basso (parola-chiave chiave off))
         (alto (parola-chiave chiave (+ off 8))) (misto (mix64 alto)))
    (declare (type u64 basso alto misto))
    (mix64 (logxor basso misto))))
(declaim (ftype (function (ottetti u64) ottetti) scrivi-chiave))
(defun scrivi-chiave (buffer id)
  \"Riutilizza BUFFER di 16 byte, chiave univoca deterministica per ID u64.\"
  (declare (type ottetti buffer) (type u64 id))
  (check-type buffer ottetti)
  (check-type id u64)
  (unless (= 16 (length buffer))
    (error 'limite-indice :motivo :chiave-deve-avere-16-byte))
  (let ((alto (logxor id #xd1b54a32d192ed03)))
    (declare (type u64 alto))
    (dotimes (n 8 buffer)
      (declare (type fixnum n))
      (setf (aref buffer n) (ldb (byte 8 (* n 8)) id)
            (aref buffer (+ 8 n)) (ldb (byte 8 (* n 8)) alto)))))
(declaim (ftype (function (ottetti ottetti fixnum) boolean) stessa-chiave-p))
(defun stessa-chiave-p (chiave arena off)
  (dotimes (n 16 t)
    (unless (= (aref chiave n) (aref arena (+ off n)))
      (return nil))))
(declaim (ftype (function (radice u64) frammento) scegli-frammento))
(defun scegli-frammento (r h)
  (declare (type radice r) (type u64 h))
  (aref (radice-directory r) (ash h (- (radice-profondita r) 64))))
(declaim (ftype (function (u64) (unsigned-byte 7)) impronta))
(defun impronta (h)
  (declare (type u64 h))
  (ldb (byte 7 0) h))
(declaim (ftype (function (u64 fixnum fixnum) fixnum) posizione-sonda))
(defun posizione-sonda (h c n)
  (declare (type u64 h) (type fixnum c n))
  ;; Gruppi contigui da otto, poi wrap; ogni slot è visitato una volta.
  (logand (1- c) (+ (logand (1- c) (ash h -7)) n)))

;;; REQ: REQ-IDX-001 REQ-IDX-005
(declaim (ftype (function (frammento ottetti u64) (values fixnum boolean)) cerca-writer))
(defun cerca-writer (f chiave h)
  (let ((libero -1) (ctrl (frammento-ctrl f)) (c (frammento-capacita f)))
    (dotimes (gruppo (ceiling c +gruppo+) (values libero nil))
      (dotimes (n +gruppo+)
        (let* ((s (posizione-sonda h c (+ (* gruppo +gruppo+) n)))
               (control (aref ctrl s)))
          (when (= control +vuoto+)
            (return-from cerca-writer (values (if (= libero -1) s libero) nil)))
          (when (and (= control +eliminato+) (= libero -1)) (setf libero s))
          (when (and (= control (impronta h))
                     (stessa-chiave-p chiave (frammento-chiavi f)
                                     (ldb (byte 24 0)
                                          (aref (frammento-slots f)
                                                (+ (* s (frammento-larghezza f)) 2)))))
            (return-from cerca-writer (values s t))))))))
(declaim (ftype (function (fixnum fixnum (unsigned-byte 24) (unsigned-byte 8)) u64)
                impacchetta))
(defun impacchetta (off len record-len flags)
  (logior off (ash len 24) (ash record-len 32) (ash flags 56)))
(declaim (ftype (function (frammento fixnum ottetti u64 u64
                         (unsigned-byte 24) u64) null) scrivi-slot))
(defun scrivi-slot (f s chiave csn loc len fine)
  (let* ((slots (frammento-slots f)) (base (* s (frammento-larghezza f)))
         (seq (aref slots (+ base 3))) (control (aref (frammento-ctrl f) s))
         (nuovo (>= control +eliminato+))
         (off (if nuovo (frammento-chiavi-usate f)
                  (ldb (byte 24 0) (aref slots (+ base 2))))))
    (when (>= seq (- +soglia-seq+ 2))
      (error 'limite-indice :motivo :seqlock-richiede-rebuild))
    (when nuovo
      (replace (frammento-chiavi f) chiave :start1 off)
      (incf (frammento-chiavi-usate f) 16))
    (setf (aref slots (+ base 3)) (1+ seq))
    (sb-thread:barrier (:write))
    (setf (aref slots base) csn (aref slots (+ base 1)) loc
          (aref slots (+ base 2)) (impacchetta off 16 len 1))
    (when (= 5 (frammento-larghezza f)) (setf (aref slots (+ base 4)) fine))
    (sb-thread:barrier (:write))
    (setf (aref slots (+ base 3)) (+ seq 2))
    (sb-thread:barrier (:write))
    (setf (aref (frammento-ctrl f) s) (impronta (hash-chiave chiave 0)))
    (when nuovo
      (incf (frammento-vivi f))
      (when (= control +eliminato+) (decf (frammento-morti f))))
    nil))
(declaim (ftype (function (frammento frammento frammento boolean) fixnum)
                copia-vivi))
(defun copia-vivi (fonte a b split-p)
  (let ((chiave (make-array 16 :element-type '(unsigned-byte 8))) (copiati 0))
    (dotimes (s (frammento-capacita fonte) copiati)
      (when (< (aref (frammento-ctrl fonte) s) 128)
        (let* ((base (* s (frammento-larghezza fonte))) (slots (frammento-slots fonte))
               (meta (aref slots (+ base 2))) (off (ldb (byte 24 0) meta)))
          (replace chiave (frammento-chiavi fonte) :start2 off :end2 (+ off 16))
          (let* ((h (hash-chiave chiave 0))
                 (dest (if (and split-p
                                (logbitp (- 64 (frammento-profondita a)) h)) b a)))
            (multiple-value-bind (slot present) (cerca-writer dest chiave h)
              (when (or present (< slot 0)) (error \"Copia SPK-01 incoerente.\"))
              (scrivi-slot dest slot chiave (aref slots base) (aref slots (+ base 1))
                           (ldb (byte 24 32) meta)
                           (if (= 5 (frammento-larghezza fonte))
                               (aref slots (+ base 4)) 0))))
          (incf copiati))))))
(declaim (ftype (function (radice frammento frammento frammento boolean) simple-vector)
                directory-sostituita))
(defun directory-sostituita (root old a b split-p)
  (let* ((doubling (and split-p (= (radice-profondita root)
                                    (frammento-profondita old))))
         (g (+ (radice-profondita root) (if doubling 1 0)))
         (dir (make-array (ash 1 g))))
    (dotimes (n (length dir) dir)
      (let ((f (aref (radice-directory root) (if doubling (ash n -1) n))))
        (setf (aref dir n)
              (if (eq f old)
                  (if (and split-p (logbitp (- g (frammento-profondita a)) n)) b a)
                  f))))))
;;; REQ: REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (indice frammento boolean) null) manutenzione))
(defun manutenzione (i f split-p)
  (let* ((start (get-internal-real-time)) (old (indice-root i))
         (depth (+ (frammento-profondita f) (if split-p 1 0)))
         (g (max depth (radice-profondita old)))
         (gen (radice-generazione old)))
    (when (> depth (indice-profondita-massima i))
      (error 'limite-indice :motivo :profondita-directory))
    (when (= gen most-positive-fixnum)
      (error 'limite-indice :motivo :generazione-root))
    (controlla-budget i (+ (payload-indice i) (* (if split-p 2 1) (payload-frammento f))
                          (* 8 (ash 1 g))))
    (let* ((a (nuovo-frammento (indice-capacita i) (indice-larghezza i) depth))
           (b (if split-p
                  (nuovo-frammento (indice-capacita i) (indice-larghezza i) depth) a))
           (copy-start (get-internal-real-time))
           (copiati (copia-vivi f a b split-p))
           (copy-stop (get-internal-real-time))
           (dir (directory-sostituita old f a b split-p))
           (dir-stop (get-internal-real-time))
           (new (%radice (1+ gen) g dir)))
      (incf (indice-frammento-copia-ticks i) (- copy-stop copy-start))
      (incf (indice-chiavi-byte-copiati i) (* 16 copiati))
      (setf (indice-frammento-copia-max-ticks i)
            (max (indice-frammento-copia-max-ticks i) (- copy-stop copy-start)))
      (incf (indice-directory-ticks i) (- dir-stop copy-stop))
      (incf (indice-directory-riferimenti-copiati i) (length dir))
      (setf (indice-directory-max-ticks i)
            (max (indice-directory-max-ticks i) (- dir-stop copy-stop))
            (indice-directory-riferimenti-max i)
            (max (indice-directory-riferimenti-max i) (length dir)))
      (sb-thread:barrier (:write))
      (unless (eq old (sb-ext:compare-and-swap (indice-root i) old new))
        (error \"Violazione del singolo writer SPK-01.\"))
      ;; F non viene più scritto; reader con riferimento precedente lo trattengono.
      (when split-p (incf (indice-frammenti i)))
      (setf (indice-slot-copiati-max i) (max copiati (indice-slot-copiati-max i))
            (indice-picco-payload i) (max (payload-indice i) (indice-picco-payload i)))
      (let ((ticks (- (get-internal-real-time) start)))
        (if split-p
            (progn (incf (indice-split i)) (incf (indice-split-ticks i) ticks)
                   (setf (indice-split-max-ticks i) (max ticks (indice-split-max-ticks i))))
            (progn (incf (indice-rebuild i)) (incf (indice-rebuild-ticks i) ticks)
                   (setf (indice-rebuild-max-ticks i)
                         (max ticks (indice-rebuild-max-ticks i)))))))
    nil))

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-IDX-005
(declaim (ftype (function (indice ottetti u64 (unsigned-byte 32) (unsigned-byte 32)
                         (unsigned-byte 24) &key (:end-csn u64)) boolean) inserisci))
(defun inserisci (i chiave csn segmento offset lunghezza &key (end-csn 0))
  \"Un solo writer. Ritorna T se nuova chiave, NIL per aggiornamento.\"
  (check-type i indice)
  (check-type chiave ottetti)
  (check-type csn u64)
  (check-type segmento (unsigned-byte 32))
  (check-type offset (unsigned-byte 32))
  (check-type lunghezza (unsigned-byte 24))
  (check-type end-csn u64)
  (unless (= 16 (length chiave)) (error 'limite-indice :motivo :chiave-16-byte))
  (when (and (= 4 (indice-larghezza i)) (/= 0 end-csn))
    (error 'limite-indice :motivo :end-csn-richiede-cinque-parole))
  (let ((h (hash-chiave chiave 0)))
    (dotimes (attempt (+ 3 (indice-profondita-massima i)))
      (let ((f (scegli-frammento (indice-root i) h)))
        (multiple-value-bind (s present) (cerca-writer f chiave h)
          (cond
            ((and (>= s 0) (>= (aref (frammento-slots f)
                                      (+ (* s (indice-larghezza i)) 3))
                                  (- +soglia-seq+ 2)))
             (manutenzione i f nil))
            ((and (not present) (>= (frammento-vivi f) (* 7 (/ (indice-capacita i) 8))))
             (manutenzione i f t))
            ((and (not present)
                  (or (>= (frammento-chiavi-usate f) (length (frammento-chiavi f)))
                      (>= (frammento-morti f) (/ (indice-capacita i) 4))))
             (manutenzione i f nil))
            (t
             (when (< s 0) (error 'limite-indice :motivo :sondaggio-saturo))
             (scrivi-slot f s chiave csn (logior (ash segmento 32) offset) lunghezza end-csn)
             (unless present (incf (indice-documenti i)))
             (return-from inserisci (not present)))))))
    (error 'limite-indice :motivo :tentativi-writer)))
(declaim (ftype (function (indice ottetti) boolean) elimina))
(defun elimina (i chiave)
  \"Un solo writer; la chiave eliminata sopravvive solo fino alla manutenzione.\"
  (check-type i indice)
  (check-type chiave ottetti)
  (unless (= 16 (length chiave)) (error 'limite-indice :motivo :chiave-16-byte))
  (let ((h (hash-chiave chiave 0)))
    (dotimes (attempt 2)
      (let ((f (scegli-frammento (indice-root i) h)))
        (multiple-value-bind (s present) (cerca-writer f chiave h)
          (unless present (return-from elimina nil))
          (let* ((slots (frammento-slots f)) (base (* s (indice-larghezza i)))
                 (seq (aref slots (+ base 3))))
            (if (>= seq (- +soglia-seq+ 2)) (manutenzione i f nil)
                (progn
                  (setf (aref slots (+ base 3)) (1+ seq))
                  (sb-thread:barrier (:write))
                  (setf (aref slots (+ base 2)) (ldb (byte 56 0) (aref slots (+ base 2))))
                  (sb-thread:barrier (:write))
                  (setf (aref slots (+ base 3)) (+ seq 2))
                  (sb-thread:barrier (:write))
                  (setf (aref (frammento-ctrl f) s) +eliminato+)
                  (decf (frammento-vivi f)) (incf (frammento-morti f))
                  (decf (indice-documenti i))
                  (return-from elimina t)))))))
    (error 'limite-indice :motivo :tentativi-delete)))

;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (frammento fixnum ottetti u64 (or null function))
                         (values u64 u64 (unsigned-byte 24) u64 keyword)) leggi-slot))
(defun leggi-slot (f s chiave h after-fields)
  (declare (type frammento f) (type fixnum s) (type ottetti chiave)
           (type u64 h) (type (or null function) after-fields))
  (let* ((slots (frammento-slots f)) (base (* s (frammento-larghezza f)))
         (seq1 (aref slots (+ base 3))))
    (declare (type parole slots) (type fixnum base) (type u64 seq1))
    (when (oddp seq1) (return-from leggi-slot (values 0 0 0 0 :retry)))
    (sb-thread:barrier (:read))
    (let* ((csn (aref slots base)) (loc (aref slots (+ base 1)))
           (meta (aref slots (+ base 2)))
           (fine (if (= 5 (frammento-larghezza f)) (aref slots (+ base 4)) 0))
           (ctrl (aref (frammento-ctrl f) s))
           (arena (frammento-chiavi f)) (off (ldb (byte 24 0) meta))
           (match (and (= ctrl (impronta h)) (= 1 (ldb (byte 8 56) meta))
                       (= 16 (ldb (byte 8 24) meta))
                       (<= (+ off 16) (length arena))
                       (stessa-chiave-p chiave arena off))))
      (declare (type u64 csn loc meta fine) (type (unsigned-byte 8) ctrl)
               (type ottetti arena) (type fixnum off) (type boolean match))
      (when after-fields (funcall after-fields f s))
      (sb-thread:barrier (:read))
      (if (/= seq1 (aref slots (+ base 3)))
          (values 0 0 0 0 :retry)
          (values csn loc (ldb (byte 24 32) meta) fine (if match :hit :skip))))))
(declaim (ftype (function (frammento ottetti u64 (or null function))
                         (values u64 u64 (unsigned-byte 24) u64 keyword)) sonda-reader))
(defun sonda-reader (f chiave h after-fields)
  (declare (type frammento f) (type ottetti chiave) (type u64 h)
           (type (or null function) after-fields))
  (let ((c (frammento-capacita f)))
    (declare (type fixnum c))
    (dotimes (gruppo (ceiling c +gruppo+) (values 0 0 0 0 :miss))
      (dotimes (n +gruppo+)
        (let* ((s (posizione-sonda h c (+ (* gruppo +gruppo+) n)))
               (ctrl (aref (frammento-ctrl f) s)))
          (declare (type fixnum s) (type (unsigned-byte 8) ctrl))
          (when (= ctrl +vuoto+) (return-from sonda-reader (values 0 0 0 0 :miss)))
          (when (= ctrl (impronta h))
            (multiple-value-bind (csn loc len fine status) (leggi-slot f s chiave h after-fields)
              (unless (eq status :skip)
                (return-from sonda-reader (values csn loc len fine status))))))))))
(declaim (ftype (function (indice ottetti &key (:attempts integer)
                         (:after-fragment (or null function))
                         (:after-fields (or null function)))
                         (values u64 u64 (unsigned-byte 24) u64 keyword fixnum)) leggi))
(defun leggi (i chiave &key (attempts 8) after-fragment after-fields)
  \"Reader senza mutex; :hit/:miss/:retry-limit e numero di tentativi scartati.\"
  (declare (type indice i) (type ottetti chiave) (type integer attempts)
           (type (or null function) after-fragment after-fields))
  (check-type i indice)
  (check-type chiave ottetti)
  (check-type after-fragment (or null function))
  (check-type after-fields (or null function))
  (intero-limitato attempts 1 8)
  (unless (= 16 (length chiave)) (error 'limite-indice :motivo :chiave-16-byte))
  (let ((h (hash-chiave chiave 0)))
    (declare (type u64 h))
    (dotimes (attempt attempts (values 0 0 0 0 :retry-limit attempts))
      (let* ((root (indice-root i)) (gen (radice-generazione root)))
        (declare (type radice root) (type fixnum gen))
        (sb-thread:barrier (:read))
        (let ((f (scegli-frammento root h)))
          (declare (type frammento f))
          (when after-fragment (funcall after-fragment f))
          (multiple-value-bind (csn loc len fine status) (sonda-reader f chiave h after-fields)
            (sb-thread:barrier (:read))
            (let ((actual (indice-root i)))
              (when (and (not (eq status :retry)) (eq actual root)
                         (= gen (radice-generazione actual)))
                (return-from leggi (values csn loc len fine status attempt))))))))))

(declaim (ftype (function (integer) double-float) secondi))
(defun secondi (ticks) (/ (coerce ticks 'double-float) internal-time-units-per-second))
(declaim (ftype (function (indice) list) indice-statistiche))
(defun indice-statistiche (i)
  (let* ((root (indice-root i)) (seen (make-hash-table :test 'eq))
         (key-used 0) (live-keys 0) (dead 0))
    (loop for f across (radice-directory root) do
      (unless (gethash f seen)
        (setf (gethash f seen) t)
        (incf key-used (frammento-chiavi-usate f))
        (incf live-keys (* 16 (frammento-vivi f))) (incf dead (frammento-morti f))))
    (list :documents (indice-documenti i) :fragments (hash-table-count seen)
          :directory-depth (radice-profondita root) :generation (radice-generazione root)
          :payload-bytes (payload-indice i)
          :payload-bytes-per-document (when (plusp (indice-documenti i))
                                       (/ (coerce (payload-indice i) 'double-float)
                                          (indice-documenti i)))
          :peak-current-payload-bytes (indice-picco-payload i)
          :peak-planned-transient-payload-bytes (indice-picco-transitorio i)
          :key-used-bytes key-used :live-key-bytes live-keys :dead-key-bytes (- key-used live-keys)
          :dead-slots dead :splits (indice-split i) :rebuilds (indice-rebuild i)
          :max-source-slots-copied (indice-slot-copiati-max i)
          :key-bytes-copied (indice-chiavi-byte-copiati i)
          :source-slots-scanned (* (indice-capacita i) (+ (indice-split i) (indice-rebuild i)))
          :max-source-slots-scanned (if (plusp (+ (indice-split i) (indice-rebuild i)))
                                       (indice-capacita i) 0)
          :directory-references-copied (indice-directory-riferimenti-copiati i)
          :max-directory-references-copied (indice-directory-riferimenti-max i)
          :directory-copy-wall-seconds (secondi (indice-directory-ticks i))
          :max-directory-copy-wall-seconds (secondi (indice-directory-max-ticks i))
          :fragment-copy-wall-seconds (secondi (indice-frammento-copia-ticks i))
          :max-fragment-copy-wall-seconds (secondi (indice-frammento-copia-max-ticks i))
          :split-wall-seconds (secondi (indice-split-ticks i))
          :max-split-wall-seconds (secondi (indice-split-max-ticks i))
          :rebuild-wall-seconds (secondi (indice-rebuild-ticks i))
          :max-rebuild-wall-seconds (secondi (indice-rebuild-max-ticks i)))))

;;; Harness C4: mutex locale al solo indice sotto stress, mai nel fast path.
;;; REQ: REQ-IDX-003
(declaim (ftype (function (sb-thread:mutex function) t) harness-writer))
(defun harness-writer (mutex funzione)
  (unless (sb-thread:grab-mutex mutex :timeout 2)
    (error 'limite-indice :motivo :harness-writer-timeout))
  (unwind-protect (funcall funzione) (sb-thread:release-mutex mutex)))
(declaim (ftype (function (indice ottetti sb-thread:mutex &key (:after-fields (or null function)))
                         (values u64 u64 (unsigned-byte 24) u64 keyword fixnum fixnum))
                harness-leggi))
(defun harness-leggi (i chiave mutex &key after-fields)
  (multiple-value-bind (csn loc len fine status retries) (leggi i chiave :after-fields after-fields)
    (unless (eq status :retry-limit)
      (return-from harness-leggi (values csn loc len fine status retries 0)))
    (unless (sb-thread:grab-mutex mutex :timeout 2)
      (error 'limite-indice :motivo :harness-fallback-timeout))
    (unwind-protect
         (multiple-value-bind (c l n e result discarded) (leggi i chiave)
           (when (or (eq result :retry-limit) (plusp discarded))
             (error \"Ripiego SPK-01 incoerente con writer escluso.\"))
           (values c l n e result retries 1))
      (sb-thread:release-mutex mutex))))
(declaim (ftype (function (function) list) worker-risultato))
(defun worker-risultato (funzione)
  ;; Confine worker: la condizione originale attraversa JOIN, non viene nascosta.
  (handler-case (list :ok (funcall funzione)) (error (c) (list :error c))))
(declaim (ftype (function (list) list) workers-con-join))
(defun workers-con-join (funzioni)
  (let ((threads nil) (risultati nil) (gate (sb-thread:make-semaphore :count 0)))
    (unwind-protect
         (progn
           (dolist (funzione funzioni)
             (let ((f funzione))
               (push (sb-thread:make-thread
                      (lambda ()
                        (worker-risultato
                         (lambda ()
                           (unless (sb-thread:wait-on-semaphore gate :timeout 3)
                             (error \"Start SPK-01 scaduto.\"))
                           (funcall f)))) :name \"SPK-01 worker\") threads)))
           (sb-thread:signal-semaphore gate (length threads))
           (dolist (thread (reverse threads))
             (push (sb-thread:join-thread thread :timeout 10) risultati))
           (dolist (result risultati)
             (when (eq (first result) :error) (error (second result))))
           (mapcar #'second (nreverse risultati)))
      ;; Creazione, errore o timeout: nessun worker viene lasciato attivo.
      (when threads (sb-thread:signal-semaphore gate (length threads)))
      (dolist (thread threads)
        (when (sb-thread:thread-alive-p thread)
          (sb-thread:terminate-thread thread))
        (sb-thread:join-thread thread :default :aborted :timeout 2)
        (when (sb-thread:thread-alive-p thread)
          (error \"Cleanup SPK-01 non ha terminato il worker.\"))))))

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-IDX-005
(declaim (ftype (function (indice ottetti integer) boolean) inserisci-pattern))
(defun inserisci-pattern (i chiave csn)
  (inserisci i chiave csn csn (* csn 3) (+ 64 (mod csn 1024))
             :end-csn (if (= 5 (indice-larghezza i)) (1+ csn) 0)))
(declaim (ftype (function (u64 u64 integer u64 integer) boolean) pattern-valido-p))
(defun pattern-valido-p (csn loc len fine words)
  (and (= (ldb (byte 32 32) loc) csn) (= (ldb (byte 32 0) loc) (* csn 3))
       (= len (+ 64 (mod csn 1024))) (= fine (if (= words 5) (1+ csn) 0))))
(declaim (ftype (function (indice ottetti integer) null) verifica-valore))
(defun verifica-valore (i chiave expected)
  (multiple-value-bind (csn loc len fine status retries) (leggi i chiave)
    (assert (zerop retries))
    (if (zerop expected) (assert (eq status :miss))
        (progn (assert (eq status :hit)) (assert (= csn expected))
               (assert (pattern-valido-p csn loc len fine (indice-larghezza i)))))
    nil))
(defun test-req-idx-001-golden ()
  (assert (= (mix64 0) #xe220a8397b1dcdaf))
  (assert (= (mix64 1) #x910a2dec89025cc1))
  (let ((i (make-indice :capacity 8 :words 5))
        (key (make-array 16 :element-type '(unsigned-byte 8))))
    (dolist (golden '((0 #x98bc9b3a9f64da94) (1 #xd76c10e8150d7703)
                      (424242 #xf7e167c9047e05bd)
                      (18446744073709551615 #x1fe490e95cf73e62)))
      (scrivi-chiave key (first golden))
      (assert (= (hash-chiave key 0) (second golden))))
    (scrivi-chiave key 1)
    (assert (= (parola-chiave key 0) 1))
    (assert (= (parola-chiave key 8) #xd1b54a32d192ed02))
    (assert (inserisci i key 9 7 11 123 :end-csn 10))
    (assert (equal (multiple-value-list (leggi i key))
                   '(9 30064771083 123 10 :hit 0)))
    (assert (elimina i key))
    (assert (equal (multiple-value-list (leggi i key)) '(0 0 0 0 :miss 0)))
    ;; Word u64 intere: CSN e location sopra MOST-POSITIVE-FIXNUM, flag/len ai limiti.
    (assert (inserisci i key +mask64+ #xffffffff #xffffffff #xffffff
                       :end-csn +mask64+))
    (assert (equal (multiple-value-list (leggi i key))
                   (list +mask64+ +mask64+ #xffffff +mask64+ :hit 0))))
  :ok)
(defun test-req-idx-001-differenziale (words)
  (let ((i (make-indice :capacity 32 :words words)) (reference (make-hash-table))
        (key (make-array 16 :element-type '(unsigned-byte 8))) (seed 424242))
    (dotimes (step 3000)
      (setf seed (mix64 seed))
      (let ((id (mod (ash seed -8) 700)) (value (1+ step)))
        (scrivi-chiave key id)
        (case (mod seed 4)
          ((0) (assert (eql (elimina i key) (not (null (gethash id reference)))))
               (remhash id reference))
          ((1 2) (assert (eql (inserisci-pattern i key value)
                              (null (gethash id reference))))
                 (setf (gethash id reference) value))
          (otherwise (verifica-valore i key (gethash id reference 0))))
        (assert (= (indice-documenti i) (hash-table-count reference)))
        (verifica-valore i key (gethash id reference 0))))
    (dotimes (id 700)
      (scrivi-chiave key id) (verifica-valore i key (gethash id reference 0)))
    (assert (plusp (indice-split i)))
    (assert (<= (indice-slot-copiati-max i) (indice-capacita i)))
    (list :words words :operations 3000 :seed 424242 :status :ok)))
(defun test-req-idx-005-collisioni ()
  (let ((i (make-indice :capacity 8 :max-depth 2))
        (key (make-array 16 :element-type '(unsigned-byte 8))) (ids nil))
    ;; Otto chiavi nello stesso prefisso a due bit: settima ammessa, ottava rifiutata.
    (dotimes (id 10000)
      (scrivi-chiave key id)
      (when (zerop (ash (hash-chiave key 0) -62)) (push id ids))
      (when (= (length ids) 8) (return)))
    (assert (= 8 (length ids)))
    (loop for id in (subseq ids 0 7) for value from 1 do
      (scrivi-chiave key id) (inserisci-pattern i key value))
    (scrivi-chiave key (eighth ids))
    (assert (handler-case (progn (inserisci-pattern i key 8) nil)
              (limite-indice (c) (eq (limite-motivo c) :profondita-directory))))
    (loop for id in (subseq ids 0 7) for value from 1 do
      (scrivi-chiave key id) (verifica-valore i key value))
    (assert (= 2 (indice-split i)))
    (scrivi-chiave key (first ids)) (assert (elimina i key))
    (scrivi-chiave key (eighth ids)) (assert (inserisci-pattern i key 8))
    (verifica-valore i key 8))
  :ok)
(defun test-req-idx-005-reclaim ()
  (let ((i (make-indice :capacity 16))
        (key (make-array 16 :element-type '(unsigned-byte 8))))
    (dotimes (cycle 100)
      (dotimes (n 6)
        (scrivi-chiave key (+ n (* cycle 6))) (inserisci-pattern i key (1+ n)))
      (dotimes (n 6)
        (scrivi-chiave key (+ n (* cycle 6))) (assert (elimina i key)))
      (assert (zerop (indice-documenti i))))
    (assert (plusp (indice-rebuild i)))
    (assert (= 1 (indice-frammenti i)))
    (let* ((f (aref (radice-directory (indice-root i)) 0))
           (before (frammento-chiavi-usate f)))
      (assert (plusp before)) (manutenzione i f nil)
      (let ((after (aref (radice-directory (indice-root i)) 0)))
        (assert (zerop (frammento-chiavi-usate after)))
        (assert (zerop (frammento-morti after))))))
  :ok)
;;; REQ: REQ-IDX-003 REQ-IDX-007
(defun test-req-idx-003-root-ritirata ()
  (let ((i (make-indice :capacity 8)) (once nil) (retired nil)
        (key (make-array 16 :element-type '(unsigned-byte 8))))
    (scrivi-chiave key 0) (inserisci-pattern i key 1)
    (multiple-value-bind (csn loc len fine status retries)
        (leggi i key :after-fragment
               (lambda (f)
                 (unless once
                   (setf once t retired f)
                   (inserisci-pattern i key 2) ; root acquisita quando era ancora 1
                   (manutenzione i f t) ; congela 2 nel frammento ritirato
                   (inserisci-pattern i key 3))))
      (assert (eq status :hit)) (assert (= csn 3)) (assert (= retries 1))
      (assert (pattern-valido-p csn loc len fine 4)))
    (multiple-value-bind (csn loc len fine status) (sonda-reader retired key (hash-chiave key 0) nil)
      (assert (eq status :hit)) (assert (= csn 2))
      (assert (pattern-valido-p csn loc len fine 4)))
    ;; Anche il MISS da un frammento ritirato deve essere scartato.
    (scrivi-chiave key 99) (setf once nil)
    (multiple-value-bind (csn loc len fine status retries)
        (leggi i key :after-fragment
               (lambda (f)
                 (unless once (setf once t) (manutenzione i f nil)
                         (inserisci-pattern i key 3))))
      (assert (eq status :hit)) (assert (= csn 3)) (assert (= retries 1))
      (assert (pattern-valido-p csn loc len fine 4))))
  (list :status :ok :root-acquired-csn 1 :unvalidated-retired-hit-csn 2
        :revalidated-hit-csn 3 :discarded-attempts 1 :retired-miss-revalidated t
        :falsified-claim :linearization-at-root-acquisition
        :general-linearizability-counterexample nil))
(defun test-req-idx-003-seqlock ()
  (let ((i (make-indice :capacity 8 :words 5)) (once nil)
        (key (make-array 16 :element-type '(unsigned-byte 8))))
    (scrivi-chiave key 0) (inserisci-pattern i key 1)
    (multiple-value-bind (csn loc len fine status retries)
        (leggi i key :after-fields
               (lambda (f s) (assert (>= s 0)) (assert (frammento-p f))
                 (unless once (setf once t) (inserisci-pattern i key 2))))
      (assert (eq status :hit)) (assert (= csn 2)) (assert (= retries 1))
      (assert (pattern-valido-p csn loc len fine 5)))
    (let* ((f (scegli-frammento (indice-root i) (hash-chiave key 0)))
           (s (cerca-writer f key (hash-chiave key 0))) (base (* s 5))
           (slots (frammento-slots f)) (seq (aref slots (+ base 3))))
      (setf (aref slots (+ base 3)) (1+ seq))
      (unwind-protect
           (progn (assert (eq :retry-limit (nth-value 4 (leggi i key))))
                  (assert (= 8 (nth-value 5 (leggi i key)))))
        (setf (aref slots (+ base 3)) seq))
      (setf (aref slots (+ base 3)) (- +soglia-seq+ 2))
      (inserisci-pattern i key 3) (verifica-valore i key 3)
      (assert (= 1 (indice-rebuild i))))
    ;; Forzatura nel solo harness per esercitare il percorso di fallback.
    (let ((mutex (sb-thread:make-mutex :name \"SPK-01 fallback fixture\")) (value 3))
      (multiple-value-bind (csn loc len fine status retry fb)
          (harness-leggi i key mutex :after-fields
                        (lambda (f s) (assert (frammento-p f)) (assert (>= s 0))
                          (incf value) (inserisci-pattern i key value)))
        (assert (eq status :hit)) (assert (= retry 8)) (assert (= fb 1))
        (assert (= csn 11)) (assert (pattern-valido-p csn loc len fine 5)))))
  :ok)
(defun test-req-idx-005-limiti ()
  (assert (handler-case (progn (make-indice :capacity 9) nil) (limite-indice () t)))
  (assert (handler-case (progn (make-indice :words 6) nil) (type-error () t)))
  (assert (handler-case (progn (make-indice :capacity 32768 :memory-mib 1) nil)
            (limite-indice () t)))
  (let ((i (make-indice :capacity 8)) (key (make-array 16 :element-type '(unsigned-byte 8))))
    (assert (handler-case (progn (leggi i key :attempts 9) nil) (type-error () t)))
    (assert (handler-case (progn (inserisci i key 1 1 1 1 :end-csn 2) nil)
              (limite-indice () t))))
  :ok)
(defun test-req-idx-003-workers ()
  (let ((before (sb-thread:list-all-threads)))
    (assert (handler-case
                (progn (workers-con-join (list (lambda () (error 'limite-indice :motivo :fixture))
                                              (lambda () :completed))) nil)
              (limite-indice (c) (eq (limite-motivo c) :fixture))))
    (assert (null (set-difference (sb-thread:list-all-threads) before))))
  :ok)
(defun test-req-idx-003-concorrenza (words)
  (let* ((i (make-indice :capacity 32 :words words))
         (mutex (sb-thread:make-mutex :name \"SPK-01 writer\"))
         (key (make-array 16 :element-type '(unsigned-byte 8)))
         (readers nil))
    (scrivi-chiave key 0) (inserisci-pattern i key 1)
    (dotimes (r 2)
      (let ((numero r))
        (push (lambda ()
                (let ((buffer (make-array 16 :element-type '(unsigned-byte 8)))
                      (retries 0) (fallback 0))
                  (dotimes (step 1200)
                    (scrivi-chiave buffer (if (evenp step) 0 (1+ (mod (+ step numero) 600))))
                    (multiple-value-bind (csn loc len fine status retry fb) (harness-leggi i buffer mutex)
                      (incf retries retry) (incf fallback fb)
                      (when (evenp step) (assert (eq status :hit)))
                      (when (eq status :hit) (assert (pattern-valido-p csn loc len fine words))))
                    (when (zerop (mod step 64)) (sb-thread:thread-yield)))
                  (list :reader numero :operations 1200 :retries retries :fallback fallback))) readers)))
    (let ((results
            (workers-con-join
             (cons (lambda ()
                     (dotimes (step 600)
                       (harness-writer mutex
                         (lambda ()
                           (scrivi-chiave key 0) (inserisci-pattern i key (+ step 2))
                           (scrivi-chiave key (1+ step)) (inserisci-pattern i key (+ step 2))
                           (when (>= step 50) (scrivi-chiave key (- step 49)) (elimina i key))))
                       (when (zerop (mod step 16)) (sb-thread:thread-yield)))
                     :writer-completed) (nreverse readers)))))
      (scrivi-chiave key 0) (verifica-valore i key 601)
      (assert (plusp (indice-split i)))
      (list :words words :status :ok :workers results))))
(declaim (ftype (function () list) check))
(defun check ()
  \"Verifica rapida: fixture deterministiche più stress limitato dello scheduler.\"
  (list :spike :spk-01 :status :ok :layout :adr-0043-v1 :verifies-format-v2 nil :seed 424242
        :golden (test-req-idx-001-golden)
        :differential (list (test-req-idx-001-differenziale 4)
                            (test-req-idx-001-differenziale 5))
        :collisions (test-req-idx-005-collisioni) :reclaim (test-req-idx-005-reclaim)
        :retired-root (test-req-idx-003-root-ritirata)
        :seqlock (test-req-idx-003-seqlock) :limits (test-req-idx-005-limiti)
        :worker-errors-and-cleanup (test-req-idx-003-workers)
        :concurrency (list (test-req-idx-003-concorrenza 4)
                           (test-req-idx-003-concorrenza 5))))

;;; REQ: REQ-BEN-001 REQ-IDX-001 REQ-IDX-005
(declaim (ftype (function (integer real) (or null double-float)) rapporto-tempo))
(defun rapporto-tempo (quantita durata)
  (when (plusp durata) (/ (coerce quantita 'double-float) (coerce durata 'double-float))))
(declaim (ftype (function (keyword integer integer integer integer u64) list) report-fase))
(defun report-fase (nome operations start allocated retries sink)
  (let* ((stop (get-internal-real-time)) (bytes (- (sb-ext:get-bytes-consed) allocated))
         (wall (secondi (- stop start))))
    (list :phase nome :operations operations :wall-seconds wall
          :operations-per-second (rapporto-tempo operations wall)
          :allocation-bytes bytes :allocation-bytes-per-second (rapporto-tempo bytes wall)
          :allocation-bytes-per-operation (when (plusp operations)
                                           (/ (coerce bytes 'double-float) operations))
          :reader-retries retries :sink sink)))
(declaim (ftype (function (indice integer integer) (values list integer)) bench-insert))
(defun bench-insert (i documents deadline)
  (let ((buffer (make-array 16 :element-type '(unsigned-byte 8))) (count 0) (sink 0)
        (start (get-internal-real-time)) (allocated (sb-ext:get-bytes-consed)))
    (dotimes (id documents)
      (when (and (zerop (mod id 256)) (>= (get-internal-real-time) deadline)) (return))
      (scrivi-chiave buffer id)
      (unless (inserisci-pattern i buffer (1+ id)) (error \"INSERT benchmark non nuovo.\"))
      (incf count) (setf sink (logxor sink (1+ id))))
    (values (report-fase :insert count start allocated 0 sink) count)))
(declaim (ftype (function (indice integer integer) list) bench-get))
(defun bench-get (i documents deadline)
  (let ((buffer (make-array 16 :element-type '(unsigned-byte 8))) (count 0) (sink 0)
        (start (get-internal-real-time)) (allocated (sb-ext:get-bytes-consed)) (retries 0))
    (dotimes (step (* 8 documents))
      (when (and (zerop (mod step 256)) (>= (get-internal-real-time) deadline)) (return))
      ;; Permutazione semplice della popolazione; chiave generata nel costo misurato.
      (let ((id (mod (* step 104729) documents)))
        (scrivi-chiave buffer id)
        (multiple-value-bind (csn loc len fine status retry) (leggi i buffer)
          (unless (and (eq status :hit) (= csn (1+ id))
                       (pattern-valido-p csn loc len fine (indice-larghezza i)))
            (error \"GET benchmark incoerente.\"))
          (incf retries retry) (setf sink (logxor sink csn loc len fine)) (incf count))))
    (report-fase :get count start allocated retries sink)))
(declaim (ftype (function (indice integer integer) list) bench-churn))
(defun bench-churn (i documents deadline)
  (let ((buffer (make-array 16 :element-type '(unsigned-byte 8))) (count 0) (sink 0)
        (start (get-internal-real-time)) (allocated (sb-ext:get-bytes-consed))
        (limit (min 50000 (max 0 (1- documents)))))
    (dotimes (step limit)
      (when (and (zerop (mod step 256)) (>= (get-internal-real-time) deadline)) (return))
      ;; Conserva key 0 per lo stress; ogni chiave sostituita una sola volta.
      (scrivi-chiave buffer (1+ step))
      (unless (elimina i buffer) (error \"DELETE churn non presente.\"))
      (scrivi-chiave buffer (+ documents step))
      (unless (inserisci-pattern i buffer (+ documents step 1))
        (error \"INSERT churn non nuovo.\"))
      (incf count 2) (setf sink (logxor sink (+ documents step 1))))
    (assert (= documents (indice-documenti i)))
    (report-fase :churn count start allocated 0 sink)))
(declaim (ftype (function (indice sb-thread:mutex integer integer integer) list)
                bench-reader-worker))
(defun bench-reader-worker (i mutex number maximum deadline)
  (let ((buffer (make-array 16 :element-type '(unsigned-byte 8)))
        (retries 0) (fallback 0) (sink 0) (operations 0))
    (scrivi-chiave buffer 0)
    (dotimes (step maximum)
      (when (and (zerop (mod step 128)) (>= (get-internal-real-time) deadline)) (return))
      (multiple-value-bind (csn loc len fine status retry fb) (harness-leggi i buffer mutex)
        (unless (and (eq status :hit) (pattern-valido-p csn loc len fine (indice-larghezza i)))
          (error \"Reader benchmark incoerente.\"))
        (incf retries retry) (incf fallback fb) (incf operations)
        (setf sink (logxor sink csn loc len fine))))
    (list :reader number :operations operations :retries retries :fallback fallback :sink sink)))
(declaim (ftype (function (indice integer integer) list) bench-concorrente))
(defun bench-concorrente (i readers deadline)
  (let* ((mutex (sb-thread:make-mutex :name \"SPK-01 benchmark writer\"))
         (buffer (make-array 16 :element-type '(unsigned-byte 8)))
         (workers nil) (start (get-internal-real-time))
         (allocated (sb-ext:get-bytes-consed)))
    (dotimes (r readers)
      (let ((number r))
        (push (lambda () (bench-reader-worker i mutex number 1000000 deadline)) workers)))
    (let* ((results
             (workers-con-join
              (cons (lambda ()
                      (let ((operations 0))
                        (scrivi-chiave buffer 0)
                        (dotimes (step 200000)
                          (when (and (zerop (mod step 128))
                                     (>= (get-internal-real-time) deadline)) (return))
                          (harness-writer mutex
                            (lambda () (inserisci-pattern i buffer (1+ step))))
                          (incf operations))
                        (list :writer-operations operations))) (nreverse workers))))
           (reader-results (rest results))
           (operations (loop for r in reader-results sum (getf r :operations)))
           (retries (loop for r in reader-results sum (getf r :retries)))
           (fallback (loop for r in reader-results sum (getf r :fallback)))
           (sink (reduce #'logxor reader-results :key (lambda (r) (getf r :sink)) :initial-value 0)))
      (append (report-fase :concurrent-get operations start allocated retries sink)
              (list :harness-writer-operations (getf (first results) :writer-operations)
                    :reader-fallback fallback :workers reader-results)))))
(declaim (ftype (function (integer integer) list) warmup))
(defun warmup (capacity words)
  (let* ((i (make-indice :capacity capacity :words words))
         (buffer (make-array 16 :element-type '(unsigned-byte 8)))
         (start (get-internal-real-time)) (sink 0))
    (dotimes (id 256)
      (scrivi-chiave buffer id) (inserisci-pattern i buffer (1+ id)))
    (dotimes (step 1024)
      (scrivi-chiave buffer (mod step 256))
      (multiple-value-bind (csn loc len fine status) (leggi i buffer)
        (assert (eq status :hit)) (setf sink (logxor sink csn loc len fine))))
    (list :insert-operations 256 :get-operations 1024 :sink sink
          :wall-seconds (secondi (- (get-internal-real-time) start)))))
(declaim (ftype (function (&key (:documents integer) (:seconds real) (:capacity integer)
                               (:words integer) (:readers integer) (:memory-mib integer)) list)
                benchmark))
(defun benchmark (&key (documents 100000) (seconds 12) (capacity 8192)
                       (words 4) (readers 2) (memory-mib 512))
  \"Misure wall limitate a blocchi; restituisce conteggi reali e fase incompleta.\"
  (intero-limitato documents 1 10000000)
  (unless (typep seconds '(real (0) 600))
    (error 'type-error :datum seconds :expected-type '(real (0) 600)))
  (intero-limitato readers 1 8)
  (let* ((i (make-indice :capacity capacity :words words :memory-mib memory-mib))
         (warmed (warmup capacity words)) (start (get-internal-real-time))
         (ticks (ceiling (* seconds internal-time-units-per-second)))
         (deadline (+ start ticks)) (insert-deadline (+ start (floor ticks 2))))
    (multiple-value-bind (insert-report actual) (bench-insert i documents insert-deadline)
      (when (zerop actual) (error 'limite-indice :motivo :budget-senza-documenti))
      (let* ((before-churn (indice-statistiche i))
             (get-report (bench-get i actual (+ start (floor (* ticks 7) 10))))
             (churn-report (bench-churn i actual (+ start (floor (* ticks 8) 10))))
             (after-churn (indice-statistiche i))
             (concurrent (bench-concorrente i readers
                          (min deadline (+ (get-internal-real-time)
                                           (* 5 internal-time-units-per-second))))))
        (list :spike :spk-01 :status :measured :layout :adr-0043-v1 :verifies-format-v2 nil
              :environment (list :implementation (lisp-implementation-type)
                                 :version (lisp-implementation-version) :machine (machine-type)
                                 :cpu (machine-version) :os (software-type) :os-version (software-version)
                                 :timer-units-per-second internal-time-units-per-second
                                 :safety 3 :speed 2)
              :parameters (list :documents documents :seconds seconds :capacity capacity
                                :words words :readers readers :memory-mib memory-mib :seed 424242)
              :warmup warmed :actual-documents actual :insert-complete (= actual documents)
              :measurement-wall-seconds (secondi (- (get-internal-real-time) start))
              :phases (list insert-report get-report churn-report concurrent)
              :before-churn before-churn :after-churn after-churn
              :allocation-scope :process-including-harness-and-bignums
              :memory-scope :live-array-payload-and-directory-excluding-headers
              :limits '(:local-scale :no-gc-pause-measurement :no-mvcc
                        :no-cross-architecture-disassembly :harness-fallback-mutex))))))
")
  (:PATH
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/lettura-buffer.lisp")
   :HASH-KIND :GIT-BLOB :HASH "899021815a7b1415d225ce5ba712564593504402"
   :CONTENT
   ";;;; SPK-01, Fase 0: lettura in buffer del layout v1, parole 4/5-extra-end.
;;;; Proprietà e metodo preregistrato: metodo-lettura-buffer.md.
(defpackage #:arcdocdb.spk01.lettura-buffer
  (:use #:cl)
  (:import-from #:arcdocdb.spk01
                #:indice #:indice-root #:ottetti #:parole #:u64
                #:radice #:radice-generazione #:frammento
                #:frammento-capacita #:frammento-larghezza #:frammento-slots
                #:frammento-ctrl #:frammento-chiavi
                #:hash-chiave #:scegli-frammento #:posizione-sonda #:impronta
                #:stessa-chiave-p #:intero-limitato #:limite-indice
                #:+gruppo+ #:+vuoto+)
  (:export #:leggi))
(in-package #:arcdocdb.spk01.lettura-buffer)
(declaim (optimize (safety 3) (speed 3) (debug 1)))

(deftype destinazione-lettura () '(simple-array (unsigned-byte 64) (4)))

(declaim
 (ftype (function (indice ottetti destinazione-lettura
                   &key (:attempts integer)
                        (:after-fragment (or null function))
                        (:after-fields (or null function)))
                  (values keyword fixnum &optional))
        leggi))
(defun leggi (indice chiave destinazione
              &key (attempts 8) after-fragment after-fields)
  \"Restituisce :HIT/:MISS/:RETRY-LIMIT e tentativi scartati (0..8).
Solo :HIT scrive [CSN, location, length, end-CSN] dopo seqlock e root.
CHIAVE e DESTINAZIONE restano private al chiamante durante la lettura.\"
  (declare (type indice indice) (type ottetti chiave)
           (type destinazione-lettura destinazione) (type integer attempts)
           (type (or null function) after-fragment after-fields))
  ;; Tutti gli ingressi sono controllati prima dell'hash e degli accessi indice.
  (check-type indice indice)
  (check-type chiave ottetti)
  (check-type destinazione destinazione-lettura)
  (check-type after-fragment (or null function))
  (check-type after-fields (or null function))
  (intero-limitato attempts 1 8)
  (unless (= 16 (length chiave))
    (error 'limite-indice :motivo :chiave-16-byte))
  (let ((limite (the (integer 1 8) attempts)))
    ;; Un solo algoritmo espanso due volte: nessuna chiamata u64 tra helper.
    ;; Il percorso diretto non contiene FUNCALL né ritorni di payload Lisp.
    (macrolet
        ((lettura (strumentata)
           `(let ((hash (hash-chiave chiave 0)))
              (declare (type u64 hash))
              (dotimes (tentativo limite (values :retry-limit limite))
                (declare (type (integer 0 8) tentativo))
                (let* ((root (indice-root indice))
                       (generazione (radice-generazione root)))
                  (declare (type radice root) (type fixnum generazione))
                  (sb-thread:barrier (:read))
                  (let* ((frammento (scegli-frammento root hash))
                         (csn 0) (posizione 0) (lunghezza 0) (fine 0)
                         (stato :miss))
                    (declare (type frammento frammento)
                             (type u64 csn posizione fine)
                             (type (unsigned-byte 24) lunghezza)
                             (type keyword stato))
                    ,@(when strumentata
                        '((when after-fragment
                            (funcall after-fragment frammento))))
                    (let ((capacita (frammento-capacita frammento)))
                      (declare (type fixnum capacita))
                      (block sondaggio
                        (dotimes (gruppo (ceiling capacita +gruppo+))
                          (declare (type fixnum gruppo))
                          (dotimes (n +gruppo+)
                            (declare (type fixnum n))
                            (let* ((slot (posizione-sonda
                                          hash capacita
                                          (+ (* gruppo +gruppo+) n)))
                                   (controllo (aref (frammento-ctrl frammento)
                                                   slot)))
                              (declare (type fixnum slot)
                                       (type (unsigned-byte 8) controllo))
                              (when (= controllo +vuoto+)
                                (return-from sondaggio nil))
                              (when (= controllo (impronta hash))
                                (let* ((parole (frammento-slots frammento))
                                       (base (* slot
                                                (frammento-larghezza frammento)))
                                       (sequenza (aref parole (+ base 3))))
                                  (declare (type parole parole)
                                           (type fixnum base) (type u64 sequenza))
                                  (when (oddp sequenza)
                                    (setf stato :retry)
                                    (return-from sondaggio nil))
                                  (sb-thread:barrier (:read))
                                  (let* ((csn-letto (aref parole base))
                                         (posizione-letta (aref parole (+ base 1)))
                                         (metadati (aref parole (+ base 2)))
                                         (fine-letta
                                           (if (= 5 (frammento-larghezza frammento))
                                               (aref parole (+ base 4)) 0))
                                         (controllo-letto
                                           (aref (frammento-ctrl frammento) slot))
                                         (arena (frammento-chiavi frammento))
                                         (offset (ldb (byte 24 0) metadati))
                                         (corrisponde
                                           (and (= controllo-letto (impronta hash))
                                                (= 1 (ldb (byte 8 56) metadati))
                                                (= 16 (ldb (byte 8 24) metadati))
                                                (<= (+ offset 16) (length arena))
                                                (stessa-chiave-p chiave arena offset))))
                                    (declare (type u64 csn-letto posizione-letta
                                                   metadati fine-letta)
                                             (type (unsigned-byte 8) controllo-letto)
                                             (type ottetti arena) (type fixnum offset)
                                             (type boolean corrisponde))
                                    ,@(when strumentata
                                        '((when after-fields
                                            (funcall after-fields frammento slot))))
                                    (sb-thread:barrier (:read))
                                    (when (/= sequenza (aref parole (+ base 3)))
                                      (setf stato :retry)
                                      (return-from sondaggio nil))
                                    (when corrisponde
                                      (setf csn csn-letto posizione posizione-letta
                                            lunghezza (ldb (byte 24 32) metadati)
                                            fine fine-letta stato :hit)
                                      (return-from sondaggio nil))))))))))
                    ;; Anche un miss deve appartenere alla root ancora corrente.
                    (sb-thread:barrier (:read))
                    (let ((corrente (indice-root indice)))
                      (declare (type radice corrente))
                      (when (and (not (eq stato :retry)) (eq corrente root)
                                 (= generazione (radice-generazione corrente)))
                        ;; Nessun callback o accesso condiviso dopo la validazione.
                        (when (eq stato :hit)
                          (setf (aref destinazione 0) csn
                                (aref destinazione 1) posizione
                                (aref destinazione 2) lunghezza
                                (aref destinazione 3) fine))
                        (return-from leggi (values stato tentativo))))))))))
      (if (or after-fragment after-fields)
          (lettura t)
          (lettura nil)))))
")
  (:PATH
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/metodo-lettura-buffer.md")
   :HASH-KIND :GIT-BLOB :HASH "595caf90327f7bd80f71ad4467960838f4cb8ad1"
   :CONTENT "# SPK-01 — metodo preregistrato: lettura in buffer

Registrazione del 2026-10-08, Fase 0. Solo Common Lisp/SBCL, `safety 3`,
`speed 3`, `debug 1`; zero warning e style-warning. Nessun `eval`,
`ignore-errors` o `truly-the`. La compilazione non sostituisce CHECK.

## Ownership e dipendenza

Checkout esclusivo di lavoro:
`/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB`.
Questo agente possiede soltanto `lettura-buffer.lisp`, questo metodo e nuovi
direttori `spikes/SPK-01-primary-index/out/lettura-buffer-*`. Core e runner
esistenti, `tools/`, documenti condivisi e `src/` restano fuori dalla proprietà.
Nessun commit o push. Driver e diagnostica nuovi risiedono nei miei out.
Il modulo richiede il core caricato; importa internals senza ridefinirli.

## API e condizioni

Package `ARCDOCDB.SPK01.LETTURA-BUFFER`, unico export `LEGGI`:

```lisp
(leggi indice chiave destinazione
       &key (attempts 8) after-fragment after-fields)
;; => (values status-keyword retry-fixnum)
```

`indice` è un indice del core; `chiave` è un simple-array di 16 u8.
`destinazione` è esattamente `(simple-array (unsigned-byte 64) (4))`, privata
al chiamante: `[CSN, location, length, end-CSN]`. Tipi, callback e lunghezza
della chiave sono validati, e `attempts` deve essere intero 1..8, prima di hash,
accessi all'indice e scritture. Tipi errati producono `type-error`; chiave con
lunghezza diversa produce `limite-indice` con motivo `:chiave-16-byte`.
Callback accettati: NIL o oggetto funzione, non designatori simbolici.

Esiti: `:hit` e `:miss` con numero di tentativi scartati 0..7;
`:retry-limit` con esattamente `attempts` tentativi scartati. Quest'ultimo è
un esito di esaurimento esplicito, mai una lettura riuscita o parziale.
La destinazione viene scritta interamente soltanto su `:hit`, dopo tutte le
validazioni. Miss, esaurimento ed errori sincroni lasciano le quattro parole
immutate. Nessuna lettura di payload viene restituita come valore Lisp.

Il chiamante mantiene chiave e destinazione stabili e private durante la
chiamata, inclusi i callback. I callback di fixture non modificano questi
buffer e mantengono gli invarianti del core; `after-fragment` riceve il
frammento e `after-fields` riceve frammento e slot. Errori dei callback sono
propagati prima di qualsiasi scrittura. Le quattro scritture non costituiscono
una pubblicazione atomica a osservatori concorrenti della destinazione.

## Algoritmo, ordine e linearizzazione

La fonte è `LEGGI`/`SONDA-READER`/`LEGGI-SLOT` del core. Una sola macro locale
espande lo stesso algoritmo nei cammini diretto e strumentato. Il primo
esclude chiamate ai callback; il secondo inserisce soltanto i due punti di
iniezione. Payload e hash sono locali typed u64: nessun trasporto di payload
tra funzioni o valori multipli. Gli helper hash/sondaggio già inline del core
rimangono le dipendenze. Nessun abbassamento di safety.

Ordine conservato: acquisizione root/generazione; barriera read; selezione
frammento e callback; sondaggio nei gruppi di otto del core; sequenza iniziale
pari; barriera read; campi, ctrl, arena e confronto chiave; callback;
barriera read; uguaglianza sequenza; barriera read; rilettura root e generazione.
Una sequenza dispari o cambiata scarta l'intero tentativo. Una root diversa
scarta hit e miss. Skip prosegue il sondaggio, ctrl vuoto lo conclude con miss.
Nessun writer, lock, CAS o cambio dell'ordine delle barriere nel modulo.

Per hit il candidato è coerente nell'intervallo seqlock stabile e viene
accettato solo dopo il ricontrollo root/generazione. Quel controllo è il punto
di accettazione, non l'affermazione che il payload rappresenti lo stato
all'istante della rilettura root: un writer può aggiornare lo stesso slot dopo
la seconda lettura della sequenza. Miss conserva il criterio del core, anche
per root ritirata. Non si fissa la linearizzazione all'acquisizione della root;
valgono le qualificazioni del prototipo v1 e il vincolo di un singolo writer.

Layout: words4 v1 (end-CSN zero) e words5-extra-end v1 (quinta parola end-CSN),
non v2. CSN, location ed end-CSN u64 alti devono conservarsi esattamente.
Il limite per tentativo è C slot, con C limitata dal costruttore del core;
al massimo otto tentativi. Nessuna garanzia temporale per callback arbitrari.

## Campagna consentita e preregistrazione delle esecuzioni

Budget: massimo quattro revisioni compilate, 90 secondi per processo figlio,
120 secondi nel registratore e 5 secondi per cleanup, heap 1024 MiB.
Un driver nuovo Common Lisp in out avvia processi SBCL senza
init utente e senza shell. Preregistra prima del lancio argv, stdin vuoto,
operazione, budget, snapshot integrali e hash Git blob di core, modulo, metodo
e driver. Snapshot before/after diversi, esaurimento, condizioni o ritorni
compile-file warning/failure sono fallimenti; nessun successo parziale.

Ogni compilazione ha un nuovo out esclusivo e record schema 1, con
`:schema-version 1`, `:argv`, `:stdin`, `:source-before`, `:source-after`,
stdout/stderr originali, exit code e `:decoded`. Anche gli insuccessi sono
conservati. I dati usano liste, keyword, stringhe e numeri; tipi e funzioni
figurano come stringhe, assenza come keyword. La decodifica con `*read-eval*`
NIL avviene nel processo registratore che non carica package dello spike.
Il driver promuove warning/style-warning a errori, verifica gli indicatori di
compile-file e carica il FASL solo se compilato senza avvisi. Non chiama LEGGI.

Esecuzione C1 preregistrata: compilare core e modulo, caricare i FASL,
disassemblare LEGGI, conservare diagnostica e sorgenti stabili. Scopo della
diagnostica: cercare boxing dei payload e chiamate u64 nel cammino diretto;
barriere e bounds check devono essere presenti. Nessuna misura di prestazioni,
allocazioni o throughput. Il disassemblato vale solo per il runtime osservato.
Eventuali revisioni avranno una motivazione e nuova preregistrazione qui,
prima della loro compilazione, senza sovrascrivere i record precedenti.

Driver della campagna: `out/lettura-buffer-campagna-20261008-01/driver-campagna.lisp`
e `driver-compila.lisp` nello stesso direttorio. Comando C1, dalla radice del
checkout isolato:

```sh
/opt/homebrew/bin/sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-01-primary-index/out/lettura-buffer-campagna-20261008-01/driver-campagna.lisp c1
```

La preregistrazione schema 1 viene salvata in `c1/record.sexp` prima di avviare
il processo figlio; stdin, stdout, stderr, FASL e disassemblato sono in `c1/`.

Gli agenti non eseguono BENCH; le misure, la profilazione iniziale e
l'integrazione competono al parent e vengono serializzate da lui. Questo
agente non esegue CHECK del modulo: è proprietà dell'altro agente. La
serializzazione dei writer del core resta responsabilità dell'harness parent.

## Controlli richiesti all'agente CHECK e al parent

Confronto con il core per hit, miss, collisioni e skip, parole 4/5, u64 zero,
massimi e oltre fixnum, lunghezza massima a 24 bit. Sentinel completa invariata
su miss, retry-limit, ingressi invalidi ed errori callback. Witness deterministici
root hit/miss ritirata, sequence odd e changing, contatore retry esatto;
attempts 1 e 8, valori invalidi, array non semplici o di lunghezza diversa,
callback errati. Verificare i due percorsi con lo stesso oracolo e gli invarianti
single writer; nessun BENCH prima della validazione del parent.
")
  (:PATH
   #A((150) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/lettura-buffer-campagna-20261008-01/driver-campagna.lisp")
   :HASH-KIND :GIT-BLOB :HASH "ea60c491369651197c2d7b767132aa31b4fabb50"
   :CONTENT
   ";;;; Registratore schema 1 senza package dello spike, nessuna shell.
(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 2) (debug 1)))
(require :asdf)
(require :sb-posix)

(defun lb-salva (dati percorso)
  (with-open-file (stream percorso :direction :output :if-exists :supersede)
    (let ((*print-readably* t) (*print-pretty* t))
      (write dati :stream stream) (terpri stream))))

(defun lb-snapshot (percorsi)
  (loop for percorso in percorsi collect
    (list :path (namestring percorso)
          :hash-kind :git-blob
          :hash (string-trim '(#\\Newline #\\Return)
                  (uiop:run-program
                    (list \"git\" \"hash-object\" \"--\" (namestring percorso))
                    :output :string :error-output :string))
          :content (uiop:read-file-string percorso :external-format :utf-8))))

(defun lb-dati-semplici-p (valore)
  (cond ((null valore) t)
        ((consp valore) (and (lb-dati-semplici-p (car valore))
                            (lb-dati-semplici-p (cdr valore))))
        (t (or (keywordp valore) (stringp valore) (numberp valore)))))

(defun lb-decodifica (testo)
  (when (> (length testo) 1048576) (error \"Budget di decodifica esaurito.\"))
  (let ((*read-eval* nil))
    (with-input-from-string (stream testo)
      (let ((dati (read stream nil :eof)))
        (unless (and (listp dati) dati (lb-dati-semplici-p dati)
                     (eq :eof (read stream nil :eof)))
          (error \"Output non decodificabile come soli dati.\"))
        dati))))

(defun lb-registra ()
  (let* ((radice #p\"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/\")
         (base (merge-pathnames \"spikes/SPK-01-primary-index/\" radice))
         (campagna (uiop:pathname-directory-pathname *load-truename*))
         (argomenti (uiop:command-line-arguments))
         (nome (first argomenti))
         (figlio (merge-pathnames \"driver-compila.lisp\" campagna)))
    (unless (and (= 1 (length argomenti))
                 (member nome '(\"c1\" \"c2\" \"c3\" \"c4\") :test #'string=))
      (error \"Budget: sono consentite solo le esecuzioni c1..c4.\"))
    (when (or (find-package \"ARCDOCDB.SPK01\")
              (find-package \"ARCDOCDB.SPK01.LETTURA-BUFFER\"))
      (error \"Il registratore deve essere privo dei package dello spike.\"))
    (let* ((uscita (merge-pathnames (format nil \"~A/\" nome) campagna))
           (record-path (merge-pathnames \"record.sexp\" uscita))
           (stdout-path (merge-pathnames \"stdout.txt\" uscita))
           (stderr-path (merge-pathnames \"stderr.txt\" uscita))
           (stdin-path (merge-pathnames \"stdin.txt\" uscita))
           (sorgenti (list (merge-pathnames \"core.lisp\" base)
                          (merge-pathnames \"lettura-buffer.lisp\" base)
                          (merge-pathnames \"metodo-lettura-buffer.md\" base)
                          *load-truename* figlio))
           (argv (list \"/opt/homebrew/bin/sbcl\" \"--noinform\" \"--no-userinit\"
                       \"--no-sysinit\" \"--dynamic-space-size\" \"1024\" \"--script\"
                       (namestring figlio) \"compile-disassemble\"
                       (namestring uscita)))
           (record
             (list :schema-version 1 :kind :compilation-disassembly
                   :execution nome :status :preregistered
                   :cwd (namestring radice) :argv argv :stdin \"\"
                   :driver-argv (copy-list sb-ext:*posix-argv*)
                   :operation \"COMPILE-FILE CORE; LOAD; COMPILE-FILE LETTURA-BUFFER; LOAD; DISASSEMBLE LEGGI\"
                   :budget '(:child-seconds 90 :parent-seconds 120
                             :cleanup-seconds 5 :heap-mib 1024 :max-revisions 4)
                   :source-before (lb-snapshot sorgenti) :source-after :not-collected
                   :source-stability :not-collected :stdout :not-collected
                   :stderr :not-collected :exit-code :not-collected
                   :decoded :not-collected :started-at (get-universal-time)
                   :environment (list :implementation (lisp-implementation-type)
                                      :version (lisp-implementation-version)
                                      :os (software-type) :os-version (software-version)
                                      :machine (machine-type)))))
      ;; mkdir esclusivo: non si sovrascrive un tentativo o un fallimento.
      (sb-posix:mkdir uscita #o700)
      (with-open-file (stream stdin-path :direction :output :if-exists :error)
        (write-string \"\" stream))
      (lb-salva record record-path)
      (let ((processo :not-started))
        (handler-case
            (progn
              (setf processo (uiop:launch-program argv :input stdin-path
                                                :output stdout-path :error-output stderr-path
                                                :directory radice))
              (setf (getf record :exit-code)
                    (sb-ext:with-timeout 120 (uiop:wait-process processo))))
          (sb-ext:timeout (condizione)
            (setf (getf record :status) :error
                  (getf record :condition) (princ-to-string condizione))
            (unless (eq processo :not-started)
              (uiop:terminate-process processo :urgent t)
              (handler-case
                  (setf (getf record :exit-code)
                        (sb-ext:with-timeout 5 (uiop:wait-process processo)))
                (sb-ext:timeout (cleanup)
                  (setf (getf record :cleanup-condition) (princ-to-string cleanup))))))
          (error (condizione)
            (setf (getf record :status) :error
                  (getf record :condition) (princ-to-string condizione))))
        (handler-case
            (progn
              (setf (getf record :stdout)
                    (if (probe-file stdout-path) (uiop:read-file-string stdout-path) \"\")
                    (getf record :stderr)
                    (if (probe-file stderr-path) (uiop:read-file-string stderr-path) \"\")
                    (getf record :source-after) (lb-snapshot sorgenti)
                    (getf record :finished-at) (get-universal-time))
              (setf (getf record :source-stability)
                    (if (equal (getf record :source-before) (getf record :source-after))
                        :stable :changed))
              ;; Qui nessun package dello spike è stato caricato.
              (setf (getf record :decoded) (lb-decodifica (getf record :stdout)))
              (when (probe-file (merge-pathnames \"leggi-disassembly.txt\" uscita))
                (setf (getf record :disassembly)
                      (uiop:read-file-string
                        (merge-pathnames \"leggi-disassembly.txt\" uscita))))
              (setf (getf record :status)
                    (if (and (not (eq :error (getf record :status)))
                             (eql 0 (getf record :exit-code))
                             (eq :stable (getf record :source-stability))
                             (eq :ok (getf (getf record :decoded) :status)))
                        :ok :error)))
          (error (condizione)
            (setf (getf record :status) :error
                  (getf record :decoding-condition) (princ-to-string condizione))))
        (lb-salva record record-path)
        ;; Verifica di rilettura del record, ancora priva dei package spike.
        (let ((*read-eval* nil))
          (with-open-file (stream record-path)
            (let ((dati (read stream nil :eof)))
              (unless (and (lb-dati-semplici-p dati) (equal dati record)
                           (eq :eof (read stream nil :eof)))
                (error \"Record finale non rileggibile.\")))))
        (write (list :schema-version 1 :status (getf record :status)
                     :record (namestring record-path)
                     :source-stability (getf record :source-stability)
                     :decoded (getf record :decoded)))
        (terpri) (finish-output)
        (unless (eq :ok (getf record :status)) (sb-ext:exit :code 1))))))

(lb-registra)
")
  (:PATH
   #A((149) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/lettura-buffer-campagna-20261008-01/driver-compila.lisp")
   :HASH-KIND :GIT-BLOB :HASH "f9968f3b223bb9ce977b87ffffcc0fb0562cec83"
   :CONTENT
   ";;;; Driver esclusivo: soltanto compile/load/disassemble, nessun CHECK/BENCH.
(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 3) (debug 1)))
(require :asdf)

(defun lb-compila (sorgente uscita)
  (handler-bind ((warning (lambda (condizione)
                           (error \"Avviso di compilazione: ~A\" condizione))))
    (multiple-value-bind (fasl avvisi fallimento)
        (compile-file sorgente :output-file uscita :verbose nil :print nil)
      (when (or avvisi fallimento (null fasl))
        (error \"Compilazione rifiutata: ~A, avvisi ~S, fallimento ~S.\"
               sorgente avvisi fallimento))
      (load fasl :verbose nil :print nil)
      (list :source (namestring sorgente) :output (namestring fasl)
            :warnings :absent :failure :absent :status :ok))))

(defun lb-esegui ()
  (let* ((argomenti (uiop:command-line-arguments))
         (uscita (pathname (second argomenti)))
         (base #p\"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/\")
         (compilazioni
           (list (lb-compila (merge-pathnames \"core.lisp\" base)
                             (merge-pathnames \"core.fasl\" uscita))
                 (lb-compila (merge-pathnames \"lettura-buffer.lisp\" base)
                             (merge-pathnames \"lettura-buffer.fasl\" uscita))))
         (package (or (find-package \"ARCDOCDB.SPK01.LETTURA-BUFFER\")
                      (error \"Package della variante assente.\")))
         (simbolo (or (find-symbol \"LEGGI\" package) (error \"API assente.\")))
         (disassemblato (merge-pathnames \"leggi-disassembly.txt\" uscita)))
    (unless (string= (first argomenti) \"compile-disassemble\")
      (error \"Operazione non autorizzata.\"))
    (with-open-file (stream disassemblato :direction :output :if-exists :error)
      (let ((*standard-output* stream))
        (disassemble (symbol-function simbolo))))
    (list :schema-version 1 :status :ok :kind :compilation-disassembly
          :compilations compilazioni
          :function \"ARCDOCDB.SPK01.LETTURA-BUFFER:LEGGI\"
          :type \"(FUNCTION (INDICE OTTETTI (SIMPLE-ARRAY (UNSIGNED-BYTE 64) (4)) &KEY (:ATTEMPTS INTEGER) (:AFTER-FRAGMENT (OR NULL FUNCTION)) (:AFTER-FIELDS (OR NULL FUNCTION))) (VALUES KEYWORD FIXNUM &OPTIONAL))\"
          :disassembly (namestring disassemblato) :checks :not-executed
          :benchmarks :not-executed :safety 3
          :implementation (lisp-implementation-type)
          :version (lisp-implementation-version) :machine (machine-type))))

(let ((*read-eval* nil) (*print-readably* t) (*print-pretty* t))
  (handler-case
      (let ((risultato (sb-ext:with-timeout 90 (lb-esegui))))
        (write risultato) (terpri) (finish-output))
    (sb-ext:timeout (condizione)
      (format *error-output* \"~&~A~%\" condizione)
      (write (list :schema-version 1 :status :error :kind :budget-exhausted
                   :condition (princ-to-string condizione)))
      (terpri) (finish-output) (sb-ext:exit :code 2))
    (error (condizione)
      (format *error-output* \"~&~A~%\" condizione)
      (write (list :schema-version 1 :status :error :kind :compilation-disassembly
                   :condition-type (princ-to-string (type-of condizione))
                   :condition (princ-to-string condizione)))
      (terpri) (finish-output) (sb-ext:exit :code 1))))
"))
 :SOURCE-AFTER
 ((:PATH
   #A((99) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/core.lisp")
   :HASH-KIND :GIT-BLOB :HASH "c019f6ad53e173a0d336a4dbfaf903e274a66f08"
   :CONTENT
   ";;;; SPK-01: esperimento C4, layout v1 ADR-0043; non verifica v2 ADR-0048.
(defpackage #:arcdocdb.spk01
  (:use #:cl)
  (:export #:check #:benchmark #:make-indice #:inserisci #:elimina #:leggi
           #:scrivi-chiave #:indice-statistiche #:limite-indice))
(in-package #:arcdocdb.spk01)
(declaim (optimize (safety 3) (speed 2) (debug 1)))

(deftype u64 () '(unsigned-byte 64))
(deftype ottetti () '(simple-array (unsigned-byte 8) (*)))
(deftype parole () '(simple-array (unsigned-byte 64) (*)))
(defconstant +mask64+ #xffffffffffffffff)
(defconstant +vuoto+ 255)
(defconstant +eliminato+ 254)
(defconstant +soglia-seq+ (ash 1 62))
(defconstant +gruppo+ 8)
(define-condition limite-indice (error)
  ((motivo :initarg :motivo :reader limite-motivo))
  (:report (lambda (c s) (format s \"Limite SPK-01: ~A\" (limite-motivo c)))))

;;; OWNER: un writer per indice; root letta dai reader, pubblicata solo con CAS.
;;; SHARED: nessuno stato tra Serie; i contatori sono locali al writer.
;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-IDX-005 REQ-IDX-007
(defstruct (frammento (:constructor %frammento))
  (profondita 0 :type fixnum :read-only t)
  (capacita 8 :type fixnum :read-only t)
  (larghezza 4 :type fixnum :read-only t)
  (ctrl (make-array 0 :element-type '(unsigned-byte 8)) :type ottetti :read-only t)
  (slots (make-array 0 :element-type '(unsigned-byte 64)) :type parole :read-only t)
  (chiavi (make-array 0 :element-type '(unsigned-byte 8)) :type ottetti :read-only t)
  (vivi 0 :type fixnum) (morti 0 :type fixnum) (chiavi-usate 0 :type fixnum))
(defstruct (radice (:constructor %radice (generazione profondita directory)))
  (generazione 0 :type fixnum :read-only t)
  (profondita 0 :type fixnum :read-only t)
  (directory #() :type simple-vector :read-only t))
(defstruct (indice (:constructor %indice))
  (root (%radice 0 0 #()) :type radice)
  (capacita 8192 :type fixnum :read-only t)
  (larghezza 4 :type fixnum :read-only t)
  (profondita-massima 20 :type fixnum :read-only t)
  (budget-byte 536870912 :type integer :read-only t)
  (documenti 0 :type fixnum) (frammenti 1 :type fixnum)
  (split 0 :type fixnum) (rebuild 0 :type fixnum)
  (slot-copiati-max 0 :type fixnum)
  (split-ticks 0 :type integer) (split-max-ticks 0 :type integer)
  (rebuild-ticks 0 :type integer) (rebuild-max-ticks 0 :type integer)
  (directory-riferimenti-copiati 0 :type integer)
  (directory-riferimenti-max 0 :type fixnum)
  (directory-ticks 0 :type integer) (directory-max-ticks 0 :type integer)
  (frammento-copia-ticks 0 :type integer) (frammento-copia-max-ticks 0 :type integer)
  (chiavi-byte-copiati 0 :type integer)
  (picco-payload 0 :type integer) (picco-transitorio 0 :type integer))

(declaim (ftype (function (t integer integer) integer) intero-limitato))
(defun intero-limitato (valore minimo massimo)
  (unless (typep valore `(integer ,minimo ,massimo))
    (error 'type-error :datum valore :expected-type `(integer ,minimo ,massimo)))
  valore)
(declaim (ftype (function (frammento) integer) payload-frammento))
(defun payload-frammento (f)
  (* (frammento-capacita f) (+ 17 (* 8 (frammento-larghezza f)))))
(declaim (ftype (function (indice) integer) payload-indice))
(defun payload-indice (i)
  ;; O(1): conteggio dei frammenti del writer, LENGTH della directory.
  (+ (* (indice-frammenti i) (indice-capacita i)
        (+ 17 (* 8 (indice-larghezza i))))
     (* 8 (length (radice-directory (indice-root i))))))
(declaim (ftype (function (indice integer) null) controlla-budget))
(defun controlla-budget (i transitorio)
  (when (> transitorio (indice-budget-byte i))
    (error 'limite-indice :motivo :payload-transitorio))
  (setf (indice-picco-transitorio i)
        (max transitorio (indice-picco-transitorio i)))
  nil)
(declaim (ftype (function (fixnum fixnum fixnum) frammento) nuovo-frammento))
(defun nuovo-frammento (c w profondita)
  (%frammento :capacita c :larghezza w :profondita profondita
              :ctrl (make-array c :element-type '(unsigned-byte 8)
                                :initial-element +vuoto+)
              :slots (make-array (* c w) :element-type '(unsigned-byte 64)
                                        :initial-element 0)
              :chiavi (make-array (* c 16) :element-type '(unsigned-byte 8)
                                         :initial-element 0)))
(declaim (ftype (function (&key (:capacity integer) (:words integer)
                               (:max-depth integer) (:memory-mib integer)) indice)
                make-indice))
(defun make-indice (&key (capacity 8192) (words 4) (max-depth 20) (memory-mib 512))
  (intero-limitato capacity 8 32768)
  (unless (= 1 (logcount capacity))
    (error 'limite-indice :motivo :capacita-non-potenza-di-due))
  (intero-limitato words 4 5)
  (intero-limitato max-depth 0 24)
  (intero-limitato memory-mib 1 8192)
  (let* ((budget (* memory-mib 1024 1024))
         (payload (+ (* capacity (+ 17 (* 8 words))) 8)))
    (when (> payload budget) (error 'limite-indice :motivo :payload-iniziale))
    (%indice :root (%radice 0 0 (vector (nuovo-frammento capacity words 0)))
             :capacita capacity :larghezza words :profondita-massima max-depth
             :budget-byte budget :picco-payload payload
             :picco-transitorio payload)))

;;; REQ: REQ-IDX-001
(declaim (inline mix64 parola-chiave hash-chiave scrivi-chiave
                 scegli-frammento impronta posizione-sonda leggi-slot sonda-reader))
(declaim (ftype (function (u64) u64) mix64))
(defun mix64 (x)
  \"SplitMix64 deterministico, intermedi u64 mascherati; kernel inline.\"
  (declare (type u64 x))
  (let* ((z (logand +mask64+ (+ x #x9e3779b97f4a7c15)))
         (a (logand +mask64+ (* (logxor z (ash z -30)) #xbf58476d1ce4e5b9)))
         (b (logand +mask64+ (* (logxor a (ash a -27)) #x94d049bb133111eb))))
    (declare (type u64 z a b))
    (logxor b (ash b -31))))
(declaim (ftype (function (ottetti fixnum) u64) parola-chiave))
(defun parola-chiave (chiave off)
  (declare (type ottetti chiave) (type fixnum off))
  (let ((parola 0))
    (declare (type u64 parola))
    (dotimes (n 8 parola)
      (declare (type fixnum n))
      (setf parola (logior parola (ash (aref chiave (+ off n)) (* 8 n)))))))
(declaim (ftype (function (ottetti fixnum) u64) hash-chiave))
(defun hash-chiave (chiave off)
  (declare (type ottetti chiave) (type fixnum off))
  (let* ((basso (parola-chiave chiave off))
         (alto (parola-chiave chiave (+ off 8))) (misto (mix64 alto)))
    (declare (type u64 basso alto misto))
    (mix64 (logxor basso misto))))
(declaim (ftype (function (ottetti u64) ottetti) scrivi-chiave))
(defun scrivi-chiave (buffer id)
  \"Riutilizza BUFFER di 16 byte, chiave univoca deterministica per ID u64.\"
  (declare (type ottetti buffer) (type u64 id))
  (check-type buffer ottetti)
  (check-type id u64)
  (unless (= 16 (length buffer))
    (error 'limite-indice :motivo :chiave-deve-avere-16-byte))
  (let ((alto (logxor id #xd1b54a32d192ed03)))
    (declare (type u64 alto))
    (dotimes (n 8 buffer)
      (declare (type fixnum n))
      (setf (aref buffer n) (ldb (byte 8 (* n 8)) id)
            (aref buffer (+ 8 n)) (ldb (byte 8 (* n 8)) alto)))))
(declaim (ftype (function (ottetti ottetti fixnum) boolean) stessa-chiave-p))
(defun stessa-chiave-p (chiave arena off)
  (dotimes (n 16 t)
    (unless (= (aref chiave n) (aref arena (+ off n)))
      (return nil))))
(declaim (ftype (function (radice u64) frammento) scegli-frammento))
(defun scegli-frammento (r h)
  (declare (type radice r) (type u64 h))
  (aref (radice-directory r) (ash h (- (radice-profondita r) 64))))
(declaim (ftype (function (u64) (unsigned-byte 7)) impronta))
(defun impronta (h)
  (declare (type u64 h))
  (ldb (byte 7 0) h))
(declaim (ftype (function (u64 fixnum fixnum) fixnum) posizione-sonda))
(defun posizione-sonda (h c n)
  (declare (type u64 h) (type fixnum c n))
  ;; Gruppi contigui da otto, poi wrap; ogni slot è visitato una volta.
  (logand (1- c) (+ (logand (1- c) (ash h -7)) n)))

;;; REQ: REQ-IDX-001 REQ-IDX-005
(declaim (ftype (function (frammento ottetti u64) (values fixnum boolean)) cerca-writer))
(defun cerca-writer (f chiave h)
  (let ((libero -1) (ctrl (frammento-ctrl f)) (c (frammento-capacita f)))
    (dotimes (gruppo (ceiling c +gruppo+) (values libero nil))
      (dotimes (n +gruppo+)
        (let* ((s (posizione-sonda h c (+ (* gruppo +gruppo+) n)))
               (control (aref ctrl s)))
          (when (= control +vuoto+)
            (return-from cerca-writer (values (if (= libero -1) s libero) nil)))
          (when (and (= control +eliminato+) (= libero -1)) (setf libero s))
          (when (and (= control (impronta h))
                     (stessa-chiave-p chiave (frammento-chiavi f)
                                     (ldb (byte 24 0)
                                          (aref (frammento-slots f)
                                                (+ (* s (frammento-larghezza f)) 2)))))
            (return-from cerca-writer (values s t))))))))
(declaim (ftype (function (fixnum fixnum (unsigned-byte 24) (unsigned-byte 8)) u64)
                impacchetta))
(defun impacchetta (off len record-len flags)
  (logior off (ash len 24) (ash record-len 32) (ash flags 56)))
(declaim (ftype (function (frammento fixnum ottetti u64 u64
                         (unsigned-byte 24) u64) null) scrivi-slot))
(defun scrivi-slot (f s chiave csn loc len fine)
  (let* ((slots (frammento-slots f)) (base (* s (frammento-larghezza f)))
         (seq (aref slots (+ base 3))) (control (aref (frammento-ctrl f) s))
         (nuovo (>= control +eliminato+))
         (off (if nuovo (frammento-chiavi-usate f)
                  (ldb (byte 24 0) (aref slots (+ base 2))))))
    (when (>= seq (- +soglia-seq+ 2))
      (error 'limite-indice :motivo :seqlock-richiede-rebuild))
    (when nuovo
      (replace (frammento-chiavi f) chiave :start1 off)
      (incf (frammento-chiavi-usate f) 16))
    (setf (aref slots (+ base 3)) (1+ seq))
    (sb-thread:barrier (:write))
    (setf (aref slots base) csn (aref slots (+ base 1)) loc
          (aref slots (+ base 2)) (impacchetta off 16 len 1))
    (when (= 5 (frammento-larghezza f)) (setf (aref slots (+ base 4)) fine))
    (sb-thread:barrier (:write))
    (setf (aref slots (+ base 3)) (+ seq 2))
    (sb-thread:barrier (:write))
    (setf (aref (frammento-ctrl f) s) (impronta (hash-chiave chiave 0)))
    (when nuovo
      (incf (frammento-vivi f))
      (when (= control +eliminato+) (decf (frammento-morti f))))
    nil))
(declaim (ftype (function (frammento frammento frammento boolean) fixnum)
                copia-vivi))
(defun copia-vivi (fonte a b split-p)
  (let ((chiave (make-array 16 :element-type '(unsigned-byte 8))) (copiati 0))
    (dotimes (s (frammento-capacita fonte) copiati)
      (when (< (aref (frammento-ctrl fonte) s) 128)
        (let* ((base (* s (frammento-larghezza fonte))) (slots (frammento-slots fonte))
               (meta (aref slots (+ base 2))) (off (ldb (byte 24 0) meta)))
          (replace chiave (frammento-chiavi fonte) :start2 off :end2 (+ off 16))
          (let* ((h (hash-chiave chiave 0))
                 (dest (if (and split-p
                                (logbitp (- 64 (frammento-profondita a)) h)) b a)))
            (multiple-value-bind (slot present) (cerca-writer dest chiave h)
              (when (or present (< slot 0)) (error \"Copia SPK-01 incoerente.\"))
              (scrivi-slot dest slot chiave (aref slots base) (aref slots (+ base 1))
                           (ldb (byte 24 32) meta)
                           (if (= 5 (frammento-larghezza fonte))
                               (aref slots (+ base 4)) 0))))
          (incf copiati))))))
(declaim (ftype (function (radice frammento frammento frammento boolean) simple-vector)
                directory-sostituita))
(defun directory-sostituita (root old a b split-p)
  (let* ((doubling (and split-p (= (radice-profondita root)
                                    (frammento-profondita old))))
         (g (+ (radice-profondita root) (if doubling 1 0)))
         (dir (make-array (ash 1 g))))
    (dotimes (n (length dir) dir)
      (let ((f (aref (radice-directory root) (if doubling (ash n -1) n))))
        (setf (aref dir n)
              (if (eq f old)
                  (if (and split-p (logbitp (- g (frammento-profondita a)) n)) b a)
                  f))))))
;;; REQ: REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (indice frammento boolean) null) manutenzione))
(defun manutenzione (i f split-p)
  (let* ((start (get-internal-real-time)) (old (indice-root i))
         (depth (+ (frammento-profondita f) (if split-p 1 0)))
         (g (max depth (radice-profondita old)))
         (gen (radice-generazione old)))
    (when (> depth (indice-profondita-massima i))
      (error 'limite-indice :motivo :profondita-directory))
    (when (= gen most-positive-fixnum)
      (error 'limite-indice :motivo :generazione-root))
    (controlla-budget i (+ (payload-indice i) (* (if split-p 2 1) (payload-frammento f))
                          (* 8 (ash 1 g))))
    (let* ((a (nuovo-frammento (indice-capacita i) (indice-larghezza i) depth))
           (b (if split-p
                  (nuovo-frammento (indice-capacita i) (indice-larghezza i) depth) a))
           (copy-start (get-internal-real-time))
           (copiati (copia-vivi f a b split-p))
           (copy-stop (get-internal-real-time))
           (dir (directory-sostituita old f a b split-p))
           (dir-stop (get-internal-real-time))
           (new (%radice (1+ gen) g dir)))
      (incf (indice-frammento-copia-ticks i) (- copy-stop copy-start))
      (incf (indice-chiavi-byte-copiati i) (* 16 copiati))
      (setf (indice-frammento-copia-max-ticks i)
            (max (indice-frammento-copia-max-ticks i) (- copy-stop copy-start)))
      (incf (indice-directory-ticks i) (- dir-stop copy-stop))
      (incf (indice-directory-riferimenti-copiati i) (length dir))
      (setf (indice-directory-max-ticks i)
            (max (indice-directory-max-ticks i) (- dir-stop copy-stop))
            (indice-directory-riferimenti-max i)
            (max (indice-directory-riferimenti-max i) (length dir)))
      (sb-thread:barrier (:write))
      (unless (eq old (sb-ext:compare-and-swap (indice-root i) old new))
        (error \"Violazione del singolo writer SPK-01.\"))
      ;; F non viene più scritto; reader con riferimento precedente lo trattengono.
      (when split-p (incf (indice-frammenti i)))
      (setf (indice-slot-copiati-max i) (max copiati (indice-slot-copiati-max i))
            (indice-picco-payload i) (max (payload-indice i) (indice-picco-payload i)))
      (let ((ticks (- (get-internal-real-time) start)))
        (if split-p
            (progn (incf (indice-split i)) (incf (indice-split-ticks i) ticks)
                   (setf (indice-split-max-ticks i) (max ticks (indice-split-max-ticks i))))
            (progn (incf (indice-rebuild i)) (incf (indice-rebuild-ticks i) ticks)
                   (setf (indice-rebuild-max-ticks i)
                         (max ticks (indice-rebuild-max-ticks i)))))))
    nil))

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-IDX-005
(declaim (ftype (function (indice ottetti u64 (unsigned-byte 32) (unsigned-byte 32)
                         (unsigned-byte 24) &key (:end-csn u64)) boolean) inserisci))
(defun inserisci (i chiave csn segmento offset lunghezza &key (end-csn 0))
  \"Un solo writer. Ritorna T se nuova chiave, NIL per aggiornamento.\"
  (check-type i indice)
  (check-type chiave ottetti)
  (check-type csn u64)
  (check-type segmento (unsigned-byte 32))
  (check-type offset (unsigned-byte 32))
  (check-type lunghezza (unsigned-byte 24))
  (check-type end-csn u64)
  (unless (= 16 (length chiave)) (error 'limite-indice :motivo :chiave-16-byte))
  (when (and (= 4 (indice-larghezza i)) (/= 0 end-csn))
    (error 'limite-indice :motivo :end-csn-richiede-cinque-parole))
  (let ((h (hash-chiave chiave 0)))
    (dotimes (attempt (+ 3 (indice-profondita-massima i)))
      (let ((f (scegli-frammento (indice-root i) h)))
        (multiple-value-bind (s present) (cerca-writer f chiave h)
          (cond
            ((and (>= s 0) (>= (aref (frammento-slots f)
                                      (+ (* s (indice-larghezza i)) 3))
                                  (- +soglia-seq+ 2)))
             (manutenzione i f nil))
            ((and (not present) (>= (frammento-vivi f) (* 7 (/ (indice-capacita i) 8))))
             (manutenzione i f t))
            ((and (not present)
                  (or (>= (frammento-chiavi-usate f) (length (frammento-chiavi f)))
                      (>= (frammento-morti f) (/ (indice-capacita i) 4))))
             (manutenzione i f nil))
            (t
             (when (< s 0) (error 'limite-indice :motivo :sondaggio-saturo))
             (scrivi-slot f s chiave csn (logior (ash segmento 32) offset) lunghezza end-csn)
             (unless present (incf (indice-documenti i)))
             (return-from inserisci (not present)))))))
    (error 'limite-indice :motivo :tentativi-writer)))
(declaim (ftype (function (indice ottetti) boolean) elimina))
(defun elimina (i chiave)
  \"Un solo writer; la chiave eliminata sopravvive solo fino alla manutenzione.\"
  (check-type i indice)
  (check-type chiave ottetti)
  (unless (= 16 (length chiave)) (error 'limite-indice :motivo :chiave-16-byte))
  (let ((h (hash-chiave chiave 0)))
    (dotimes (attempt 2)
      (let ((f (scegli-frammento (indice-root i) h)))
        (multiple-value-bind (s present) (cerca-writer f chiave h)
          (unless present (return-from elimina nil))
          (let* ((slots (frammento-slots f)) (base (* s (indice-larghezza i)))
                 (seq (aref slots (+ base 3))))
            (if (>= seq (- +soglia-seq+ 2)) (manutenzione i f nil)
                (progn
                  (setf (aref slots (+ base 3)) (1+ seq))
                  (sb-thread:barrier (:write))
                  (setf (aref slots (+ base 2)) (ldb (byte 56 0) (aref slots (+ base 2))))
                  (sb-thread:barrier (:write))
                  (setf (aref slots (+ base 3)) (+ seq 2))
                  (sb-thread:barrier (:write))
                  (setf (aref (frammento-ctrl f) s) +eliminato+)
                  (decf (frammento-vivi f)) (incf (frammento-morti f))
                  (decf (indice-documenti i))
                  (return-from elimina t)))))))
    (error 'limite-indice :motivo :tentativi-delete)))

;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (frammento fixnum ottetti u64 (or null function))
                         (values u64 u64 (unsigned-byte 24) u64 keyword)) leggi-slot))
(defun leggi-slot (f s chiave h after-fields)
  (declare (type frammento f) (type fixnum s) (type ottetti chiave)
           (type u64 h) (type (or null function) after-fields))
  (let* ((slots (frammento-slots f)) (base (* s (frammento-larghezza f)))
         (seq1 (aref slots (+ base 3))))
    (declare (type parole slots) (type fixnum base) (type u64 seq1))
    (when (oddp seq1) (return-from leggi-slot (values 0 0 0 0 :retry)))
    (sb-thread:barrier (:read))
    (let* ((csn (aref slots base)) (loc (aref slots (+ base 1)))
           (meta (aref slots (+ base 2)))
           (fine (if (= 5 (frammento-larghezza f)) (aref slots (+ base 4)) 0))
           (ctrl (aref (frammento-ctrl f) s))
           (arena (frammento-chiavi f)) (off (ldb (byte 24 0) meta))
           (match (and (= ctrl (impronta h)) (= 1 (ldb (byte 8 56) meta))
                       (= 16 (ldb (byte 8 24) meta))
                       (<= (+ off 16) (length arena))
                       (stessa-chiave-p chiave arena off))))
      (declare (type u64 csn loc meta fine) (type (unsigned-byte 8) ctrl)
               (type ottetti arena) (type fixnum off) (type boolean match))
      (when after-fields (funcall after-fields f s))
      (sb-thread:barrier (:read))
      (if (/= seq1 (aref slots (+ base 3)))
          (values 0 0 0 0 :retry)
          (values csn loc (ldb (byte 24 32) meta) fine (if match :hit :skip))))))
(declaim (ftype (function (frammento ottetti u64 (or null function))
                         (values u64 u64 (unsigned-byte 24) u64 keyword)) sonda-reader))
(defun sonda-reader (f chiave h after-fields)
  (declare (type frammento f) (type ottetti chiave) (type u64 h)
           (type (or null function) after-fields))
  (let ((c (frammento-capacita f)))
    (declare (type fixnum c))
    (dotimes (gruppo (ceiling c +gruppo+) (values 0 0 0 0 :miss))
      (dotimes (n +gruppo+)
        (let* ((s (posizione-sonda h c (+ (* gruppo +gruppo+) n)))
               (ctrl (aref (frammento-ctrl f) s)))
          (declare (type fixnum s) (type (unsigned-byte 8) ctrl))
          (when (= ctrl +vuoto+) (return-from sonda-reader (values 0 0 0 0 :miss)))
          (when (= ctrl (impronta h))
            (multiple-value-bind (csn loc len fine status) (leggi-slot f s chiave h after-fields)
              (unless (eq status :skip)
                (return-from sonda-reader (values csn loc len fine status))))))))))
(declaim (ftype (function (indice ottetti &key (:attempts integer)
                         (:after-fragment (or null function))
                         (:after-fields (or null function)))
                         (values u64 u64 (unsigned-byte 24) u64 keyword fixnum)) leggi))
(defun leggi (i chiave &key (attempts 8) after-fragment after-fields)
  \"Reader senza mutex; :hit/:miss/:retry-limit e numero di tentativi scartati.\"
  (declare (type indice i) (type ottetti chiave) (type integer attempts)
           (type (or null function) after-fragment after-fields))
  (check-type i indice)
  (check-type chiave ottetti)
  (check-type after-fragment (or null function))
  (check-type after-fields (or null function))
  (intero-limitato attempts 1 8)
  (unless (= 16 (length chiave)) (error 'limite-indice :motivo :chiave-16-byte))
  (let ((h (hash-chiave chiave 0)))
    (declare (type u64 h))
    (dotimes (attempt attempts (values 0 0 0 0 :retry-limit attempts))
      (let* ((root (indice-root i)) (gen (radice-generazione root)))
        (declare (type radice root) (type fixnum gen))
        (sb-thread:barrier (:read))
        (let ((f (scegli-frammento root h)))
          (declare (type frammento f))
          (when after-fragment (funcall after-fragment f))
          (multiple-value-bind (csn loc len fine status) (sonda-reader f chiave h after-fields)
            (sb-thread:barrier (:read))
            (let ((actual (indice-root i)))
              (when (and (not (eq status :retry)) (eq actual root)
                         (= gen (radice-generazione actual)))
                (return-from leggi (values csn loc len fine status attempt))))))))))

(declaim (ftype (function (integer) double-float) secondi))
(defun secondi (ticks) (/ (coerce ticks 'double-float) internal-time-units-per-second))
(declaim (ftype (function (indice) list) indice-statistiche))
(defun indice-statistiche (i)
  (let* ((root (indice-root i)) (seen (make-hash-table :test 'eq))
         (key-used 0) (live-keys 0) (dead 0))
    (loop for f across (radice-directory root) do
      (unless (gethash f seen)
        (setf (gethash f seen) t)
        (incf key-used (frammento-chiavi-usate f))
        (incf live-keys (* 16 (frammento-vivi f))) (incf dead (frammento-morti f))))
    (list :documents (indice-documenti i) :fragments (hash-table-count seen)
          :directory-depth (radice-profondita root) :generation (radice-generazione root)
          :payload-bytes (payload-indice i)
          :payload-bytes-per-document (when (plusp (indice-documenti i))
                                       (/ (coerce (payload-indice i) 'double-float)
                                          (indice-documenti i)))
          :peak-current-payload-bytes (indice-picco-payload i)
          :peak-planned-transient-payload-bytes (indice-picco-transitorio i)
          :key-used-bytes key-used :live-key-bytes live-keys :dead-key-bytes (- key-used live-keys)
          :dead-slots dead :splits (indice-split i) :rebuilds (indice-rebuild i)
          :max-source-slots-copied (indice-slot-copiati-max i)
          :key-bytes-copied (indice-chiavi-byte-copiati i)
          :source-slots-scanned (* (indice-capacita i) (+ (indice-split i) (indice-rebuild i)))
          :max-source-slots-scanned (if (plusp (+ (indice-split i) (indice-rebuild i)))
                                       (indice-capacita i) 0)
          :directory-references-copied (indice-directory-riferimenti-copiati i)
          :max-directory-references-copied (indice-directory-riferimenti-max i)
          :directory-copy-wall-seconds (secondi (indice-directory-ticks i))
          :max-directory-copy-wall-seconds (secondi (indice-directory-max-ticks i))
          :fragment-copy-wall-seconds (secondi (indice-frammento-copia-ticks i))
          :max-fragment-copy-wall-seconds (secondi (indice-frammento-copia-max-ticks i))
          :split-wall-seconds (secondi (indice-split-ticks i))
          :max-split-wall-seconds (secondi (indice-split-max-ticks i))
          :rebuild-wall-seconds (secondi (indice-rebuild-ticks i))
          :max-rebuild-wall-seconds (secondi (indice-rebuild-max-ticks i)))))

;;; Harness C4: mutex locale al solo indice sotto stress, mai nel fast path.
;;; REQ: REQ-IDX-003
(declaim (ftype (function (sb-thread:mutex function) t) harness-writer))
(defun harness-writer (mutex funzione)
  (unless (sb-thread:grab-mutex mutex :timeout 2)
    (error 'limite-indice :motivo :harness-writer-timeout))
  (unwind-protect (funcall funzione) (sb-thread:release-mutex mutex)))
(declaim (ftype (function (indice ottetti sb-thread:mutex &key (:after-fields (or null function)))
                         (values u64 u64 (unsigned-byte 24) u64 keyword fixnum fixnum))
                harness-leggi))
(defun harness-leggi (i chiave mutex &key after-fields)
  (multiple-value-bind (csn loc len fine status retries) (leggi i chiave :after-fields after-fields)
    (unless (eq status :retry-limit)
      (return-from harness-leggi (values csn loc len fine status retries 0)))
    (unless (sb-thread:grab-mutex mutex :timeout 2)
      (error 'limite-indice :motivo :harness-fallback-timeout))
    (unwind-protect
         (multiple-value-bind (c l n e result discarded) (leggi i chiave)
           (when (or (eq result :retry-limit) (plusp discarded))
             (error \"Ripiego SPK-01 incoerente con writer escluso.\"))
           (values c l n e result retries 1))
      (sb-thread:release-mutex mutex))))
(declaim (ftype (function (function) list) worker-risultato))
(defun worker-risultato (funzione)
  ;; Confine worker: la condizione originale attraversa JOIN, non viene nascosta.
  (handler-case (list :ok (funcall funzione)) (error (c) (list :error c))))
(declaim (ftype (function (list) list) workers-con-join))
(defun workers-con-join (funzioni)
  (let ((threads nil) (risultati nil) (gate (sb-thread:make-semaphore :count 0)))
    (unwind-protect
         (progn
           (dolist (funzione funzioni)
             (let ((f funzione))
               (push (sb-thread:make-thread
                      (lambda ()
                        (worker-risultato
                         (lambda ()
                           (unless (sb-thread:wait-on-semaphore gate :timeout 3)
                             (error \"Start SPK-01 scaduto.\"))
                           (funcall f)))) :name \"SPK-01 worker\") threads)))
           (sb-thread:signal-semaphore gate (length threads))
           (dolist (thread (reverse threads))
             (push (sb-thread:join-thread thread :timeout 10) risultati))
           (dolist (result risultati)
             (when (eq (first result) :error) (error (second result))))
           (mapcar #'second (nreverse risultati)))
      ;; Creazione, errore o timeout: nessun worker viene lasciato attivo.
      (when threads (sb-thread:signal-semaphore gate (length threads)))
      (dolist (thread threads)
        (when (sb-thread:thread-alive-p thread)
          (sb-thread:terminate-thread thread))
        (sb-thread:join-thread thread :default :aborted :timeout 2)
        (when (sb-thread:thread-alive-p thread)
          (error \"Cleanup SPK-01 non ha terminato il worker.\"))))))

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-IDX-005
(declaim (ftype (function (indice ottetti integer) boolean) inserisci-pattern))
(defun inserisci-pattern (i chiave csn)
  (inserisci i chiave csn csn (* csn 3) (+ 64 (mod csn 1024))
             :end-csn (if (= 5 (indice-larghezza i)) (1+ csn) 0)))
(declaim (ftype (function (u64 u64 integer u64 integer) boolean) pattern-valido-p))
(defun pattern-valido-p (csn loc len fine words)
  (and (= (ldb (byte 32 32) loc) csn) (= (ldb (byte 32 0) loc) (* csn 3))
       (= len (+ 64 (mod csn 1024))) (= fine (if (= words 5) (1+ csn) 0))))
(declaim (ftype (function (indice ottetti integer) null) verifica-valore))
(defun verifica-valore (i chiave expected)
  (multiple-value-bind (csn loc len fine status retries) (leggi i chiave)
    (assert (zerop retries))
    (if (zerop expected) (assert (eq status :miss))
        (progn (assert (eq status :hit)) (assert (= csn expected))
               (assert (pattern-valido-p csn loc len fine (indice-larghezza i)))))
    nil))
(defun test-req-idx-001-golden ()
  (assert (= (mix64 0) #xe220a8397b1dcdaf))
  (assert (= (mix64 1) #x910a2dec89025cc1))
  (let ((i (make-indice :capacity 8 :words 5))
        (key (make-array 16 :element-type '(unsigned-byte 8))))
    (dolist (golden '((0 #x98bc9b3a9f64da94) (1 #xd76c10e8150d7703)
                      (424242 #xf7e167c9047e05bd)
                      (18446744073709551615 #x1fe490e95cf73e62)))
      (scrivi-chiave key (first golden))
      (assert (= (hash-chiave key 0) (second golden))))
    (scrivi-chiave key 1)
    (assert (= (parola-chiave key 0) 1))
    (assert (= (parola-chiave key 8) #xd1b54a32d192ed02))
    (assert (inserisci i key 9 7 11 123 :end-csn 10))
    (assert (equal (multiple-value-list (leggi i key))
                   '(9 30064771083 123 10 :hit 0)))
    (assert (elimina i key))
    (assert (equal (multiple-value-list (leggi i key)) '(0 0 0 0 :miss 0)))
    ;; Word u64 intere: CSN e location sopra MOST-POSITIVE-FIXNUM, flag/len ai limiti.
    (assert (inserisci i key +mask64+ #xffffffff #xffffffff #xffffff
                       :end-csn +mask64+))
    (assert (equal (multiple-value-list (leggi i key))
                   (list +mask64+ +mask64+ #xffffff +mask64+ :hit 0))))
  :ok)
(defun test-req-idx-001-differenziale (words)
  (let ((i (make-indice :capacity 32 :words words)) (reference (make-hash-table))
        (key (make-array 16 :element-type '(unsigned-byte 8))) (seed 424242))
    (dotimes (step 3000)
      (setf seed (mix64 seed))
      (let ((id (mod (ash seed -8) 700)) (value (1+ step)))
        (scrivi-chiave key id)
        (case (mod seed 4)
          ((0) (assert (eql (elimina i key) (not (null (gethash id reference)))))
               (remhash id reference))
          ((1 2) (assert (eql (inserisci-pattern i key value)
                              (null (gethash id reference))))
                 (setf (gethash id reference) value))
          (otherwise (verifica-valore i key (gethash id reference 0))))
        (assert (= (indice-documenti i) (hash-table-count reference)))
        (verifica-valore i key (gethash id reference 0))))
    (dotimes (id 700)
      (scrivi-chiave key id) (verifica-valore i key (gethash id reference 0)))
    (assert (plusp (indice-split i)))
    (assert (<= (indice-slot-copiati-max i) (indice-capacita i)))
    (list :words words :operations 3000 :seed 424242 :status :ok)))
(defun test-req-idx-005-collisioni ()
  (let ((i (make-indice :capacity 8 :max-depth 2))
        (key (make-array 16 :element-type '(unsigned-byte 8))) (ids nil))
    ;; Otto chiavi nello stesso prefisso a due bit: settima ammessa, ottava rifiutata.
    (dotimes (id 10000)
      (scrivi-chiave key id)
      (when (zerop (ash (hash-chiave key 0) -62)) (push id ids))
      (when (= (length ids) 8) (return)))
    (assert (= 8 (length ids)))
    (loop for id in (subseq ids 0 7) for value from 1 do
      (scrivi-chiave key id) (inserisci-pattern i key value))
    (scrivi-chiave key (eighth ids))
    (assert (handler-case (progn (inserisci-pattern i key 8) nil)
              (limite-indice (c) (eq (limite-motivo c) :profondita-directory))))
    (loop for id in (subseq ids 0 7) for value from 1 do
      (scrivi-chiave key id) (verifica-valore i key value))
    (assert (= 2 (indice-split i)))
    (scrivi-chiave key (first ids)) (assert (elimina i key))
    (scrivi-chiave key (eighth ids)) (assert (inserisci-pattern i key 8))
    (verifica-valore i key 8))
  :ok)
(defun test-req-idx-005-reclaim ()
  (let ((i (make-indice :capacity 16))
        (key (make-array 16 :element-type '(unsigned-byte 8))))
    (dotimes (cycle 100)
      (dotimes (n 6)
        (scrivi-chiave key (+ n (* cycle 6))) (inserisci-pattern i key (1+ n)))
      (dotimes (n 6)
        (scrivi-chiave key (+ n (* cycle 6))) (assert (elimina i key)))
      (assert (zerop (indice-documenti i))))
    (assert (plusp (indice-rebuild i)))
    (assert (= 1 (indice-frammenti i)))
    (let* ((f (aref (radice-directory (indice-root i)) 0))
           (before (frammento-chiavi-usate f)))
      (assert (plusp before)) (manutenzione i f nil)
      (let ((after (aref (radice-directory (indice-root i)) 0)))
        (assert (zerop (frammento-chiavi-usate after)))
        (assert (zerop (frammento-morti after))))))
  :ok)
;;; REQ: REQ-IDX-003 REQ-IDX-007
(defun test-req-idx-003-root-ritirata ()
  (let ((i (make-indice :capacity 8)) (once nil) (retired nil)
        (key (make-array 16 :element-type '(unsigned-byte 8))))
    (scrivi-chiave key 0) (inserisci-pattern i key 1)
    (multiple-value-bind (csn loc len fine status retries)
        (leggi i key :after-fragment
               (lambda (f)
                 (unless once
                   (setf once t retired f)
                   (inserisci-pattern i key 2) ; root acquisita quando era ancora 1
                   (manutenzione i f t) ; congela 2 nel frammento ritirato
                   (inserisci-pattern i key 3))))
      (assert (eq status :hit)) (assert (= csn 3)) (assert (= retries 1))
      (assert (pattern-valido-p csn loc len fine 4)))
    (multiple-value-bind (csn loc len fine status) (sonda-reader retired key (hash-chiave key 0) nil)
      (assert (eq status :hit)) (assert (= csn 2))
      (assert (pattern-valido-p csn loc len fine 4)))
    ;; Anche il MISS da un frammento ritirato deve essere scartato.
    (scrivi-chiave key 99) (setf once nil)
    (multiple-value-bind (csn loc len fine status retries)
        (leggi i key :after-fragment
               (lambda (f)
                 (unless once (setf once t) (manutenzione i f nil)
                         (inserisci-pattern i key 3))))
      (assert (eq status :hit)) (assert (= csn 3)) (assert (= retries 1))
      (assert (pattern-valido-p csn loc len fine 4))))
  (list :status :ok :root-acquired-csn 1 :unvalidated-retired-hit-csn 2
        :revalidated-hit-csn 3 :discarded-attempts 1 :retired-miss-revalidated t
        :falsified-claim :linearization-at-root-acquisition
        :general-linearizability-counterexample nil))
(defun test-req-idx-003-seqlock ()
  (let ((i (make-indice :capacity 8 :words 5)) (once nil)
        (key (make-array 16 :element-type '(unsigned-byte 8))))
    (scrivi-chiave key 0) (inserisci-pattern i key 1)
    (multiple-value-bind (csn loc len fine status retries)
        (leggi i key :after-fields
               (lambda (f s) (assert (>= s 0)) (assert (frammento-p f))
                 (unless once (setf once t) (inserisci-pattern i key 2))))
      (assert (eq status :hit)) (assert (= csn 2)) (assert (= retries 1))
      (assert (pattern-valido-p csn loc len fine 5)))
    (let* ((f (scegli-frammento (indice-root i) (hash-chiave key 0)))
           (s (cerca-writer f key (hash-chiave key 0))) (base (* s 5))
           (slots (frammento-slots f)) (seq (aref slots (+ base 3))))
      (setf (aref slots (+ base 3)) (1+ seq))
      (unwind-protect
           (progn (assert (eq :retry-limit (nth-value 4 (leggi i key))))
                  (assert (= 8 (nth-value 5 (leggi i key)))))
        (setf (aref slots (+ base 3)) seq))
      (setf (aref slots (+ base 3)) (- +soglia-seq+ 2))
      (inserisci-pattern i key 3) (verifica-valore i key 3)
      (assert (= 1 (indice-rebuild i))))
    ;; Forzatura nel solo harness per esercitare il percorso di fallback.
    (let ((mutex (sb-thread:make-mutex :name \"SPK-01 fallback fixture\")) (value 3))
      (multiple-value-bind (csn loc len fine status retry fb)
          (harness-leggi i key mutex :after-fields
                        (lambda (f s) (assert (frammento-p f)) (assert (>= s 0))
                          (incf value) (inserisci-pattern i key value)))
        (assert (eq status :hit)) (assert (= retry 8)) (assert (= fb 1))
        (assert (= csn 11)) (assert (pattern-valido-p csn loc len fine 5)))))
  :ok)
(defun test-req-idx-005-limiti ()
  (assert (handler-case (progn (make-indice :capacity 9) nil) (limite-indice () t)))
  (assert (handler-case (progn (make-indice :words 6) nil) (type-error () t)))
  (assert (handler-case (progn (make-indice :capacity 32768 :memory-mib 1) nil)
            (limite-indice () t)))
  (let ((i (make-indice :capacity 8)) (key (make-array 16 :element-type '(unsigned-byte 8))))
    (assert (handler-case (progn (leggi i key :attempts 9) nil) (type-error () t)))
    (assert (handler-case (progn (inserisci i key 1 1 1 1 :end-csn 2) nil)
              (limite-indice () t))))
  :ok)
(defun test-req-idx-003-workers ()
  (let ((before (sb-thread:list-all-threads)))
    (assert (handler-case
                (progn (workers-con-join (list (lambda () (error 'limite-indice :motivo :fixture))
                                              (lambda () :completed))) nil)
              (limite-indice (c) (eq (limite-motivo c) :fixture))))
    (assert (null (set-difference (sb-thread:list-all-threads) before))))
  :ok)
(defun test-req-idx-003-concorrenza (words)
  (let* ((i (make-indice :capacity 32 :words words))
         (mutex (sb-thread:make-mutex :name \"SPK-01 writer\"))
         (key (make-array 16 :element-type '(unsigned-byte 8)))
         (readers nil))
    (scrivi-chiave key 0) (inserisci-pattern i key 1)
    (dotimes (r 2)
      (let ((numero r))
        (push (lambda ()
                (let ((buffer (make-array 16 :element-type '(unsigned-byte 8)))
                      (retries 0) (fallback 0))
                  (dotimes (step 1200)
                    (scrivi-chiave buffer (if (evenp step) 0 (1+ (mod (+ step numero) 600))))
                    (multiple-value-bind (csn loc len fine status retry fb) (harness-leggi i buffer mutex)
                      (incf retries retry) (incf fallback fb)
                      (when (evenp step) (assert (eq status :hit)))
                      (when (eq status :hit) (assert (pattern-valido-p csn loc len fine words))))
                    (when (zerop (mod step 64)) (sb-thread:thread-yield)))
                  (list :reader numero :operations 1200 :retries retries :fallback fallback))) readers)))
    (let ((results
            (workers-con-join
             (cons (lambda ()
                     (dotimes (step 600)
                       (harness-writer mutex
                         (lambda ()
                           (scrivi-chiave key 0) (inserisci-pattern i key (+ step 2))
                           (scrivi-chiave key (1+ step)) (inserisci-pattern i key (+ step 2))
                           (when (>= step 50) (scrivi-chiave key (- step 49)) (elimina i key))))
                       (when (zerop (mod step 16)) (sb-thread:thread-yield)))
                     :writer-completed) (nreverse readers)))))
      (scrivi-chiave key 0) (verifica-valore i key 601)
      (assert (plusp (indice-split i)))
      (list :words words :status :ok :workers results))))
(declaim (ftype (function () list) check))
(defun check ()
  \"Verifica rapida: fixture deterministiche più stress limitato dello scheduler.\"
  (list :spike :spk-01 :status :ok :layout :adr-0043-v1 :verifies-format-v2 nil :seed 424242
        :golden (test-req-idx-001-golden)
        :differential (list (test-req-idx-001-differenziale 4)
                            (test-req-idx-001-differenziale 5))
        :collisions (test-req-idx-005-collisioni) :reclaim (test-req-idx-005-reclaim)
        :retired-root (test-req-idx-003-root-ritirata)
        :seqlock (test-req-idx-003-seqlock) :limits (test-req-idx-005-limiti)
        :worker-errors-and-cleanup (test-req-idx-003-workers)
        :concurrency (list (test-req-idx-003-concorrenza 4)
                           (test-req-idx-003-concorrenza 5))))

;;; REQ: REQ-BEN-001 REQ-IDX-001 REQ-IDX-005
(declaim (ftype (function (integer real) (or null double-float)) rapporto-tempo))
(defun rapporto-tempo (quantita durata)
  (when (plusp durata) (/ (coerce quantita 'double-float) (coerce durata 'double-float))))
(declaim (ftype (function (keyword integer integer integer integer u64) list) report-fase))
(defun report-fase (nome operations start allocated retries sink)
  (let* ((stop (get-internal-real-time)) (bytes (- (sb-ext:get-bytes-consed) allocated))
         (wall (secondi (- stop start))))
    (list :phase nome :operations operations :wall-seconds wall
          :operations-per-second (rapporto-tempo operations wall)
          :allocation-bytes bytes :allocation-bytes-per-second (rapporto-tempo bytes wall)
          :allocation-bytes-per-operation (when (plusp operations)
                                           (/ (coerce bytes 'double-float) operations))
          :reader-retries retries :sink sink)))
(declaim (ftype (function (indice integer integer) (values list integer)) bench-insert))
(defun bench-insert (i documents deadline)
  (let ((buffer (make-array 16 :element-type '(unsigned-byte 8))) (count 0) (sink 0)
        (start (get-internal-real-time)) (allocated (sb-ext:get-bytes-consed)))
    (dotimes (id documents)
      (when (and (zerop (mod id 256)) (>= (get-internal-real-time) deadline)) (return))
      (scrivi-chiave buffer id)
      (unless (inserisci-pattern i buffer (1+ id)) (error \"INSERT benchmark non nuovo.\"))
      (incf count) (setf sink (logxor sink (1+ id))))
    (values (report-fase :insert count start allocated 0 sink) count)))
(declaim (ftype (function (indice integer integer) list) bench-get))
(defun bench-get (i documents deadline)
  (let ((buffer (make-array 16 :element-type '(unsigned-byte 8))) (count 0) (sink 0)
        (start (get-internal-real-time)) (allocated (sb-ext:get-bytes-consed)) (retries 0))
    (dotimes (step (* 8 documents))
      (when (and (zerop (mod step 256)) (>= (get-internal-real-time) deadline)) (return))
      ;; Permutazione semplice della popolazione; chiave generata nel costo misurato.
      (let ((id (mod (* step 104729) documents)))
        (scrivi-chiave buffer id)
        (multiple-value-bind (csn loc len fine status retry) (leggi i buffer)
          (unless (and (eq status :hit) (= csn (1+ id))
                       (pattern-valido-p csn loc len fine (indice-larghezza i)))
            (error \"GET benchmark incoerente.\"))
          (incf retries retry) (setf sink (logxor sink csn loc len fine)) (incf count))))
    (report-fase :get count start allocated retries sink)))
(declaim (ftype (function (indice integer integer) list) bench-churn))
(defun bench-churn (i documents deadline)
  (let ((buffer (make-array 16 :element-type '(unsigned-byte 8))) (count 0) (sink 0)
        (start (get-internal-real-time)) (allocated (sb-ext:get-bytes-consed))
        (limit (min 50000 (max 0 (1- documents)))))
    (dotimes (step limit)
      (when (and (zerop (mod step 256)) (>= (get-internal-real-time) deadline)) (return))
      ;; Conserva key 0 per lo stress; ogni chiave sostituita una sola volta.
      (scrivi-chiave buffer (1+ step))
      (unless (elimina i buffer) (error \"DELETE churn non presente.\"))
      (scrivi-chiave buffer (+ documents step))
      (unless (inserisci-pattern i buffer (+ documents step 1))
        (error \"INSERT churn non nuovo.\"))
      (incf count 2) (setf sink (logxor sink (+ documents step 1))))
    (assert (= documents (indice-documenti i)))
    (report-fase :churn count start allocated 0 sink)))
(declaim (ftype (function (indice sb-thread:mutex integer integer integer) list)
                bench-reader-worker))
(defun bench-reader-worker (i mutex number maximum deadline)
  (let ((buffer (make-array 16 :element-type '(unsigned-byte 8)))
        (retries 0) (fallback 0) (sink 0) (operations 0))
    (scrivi-chiave buffer 0)
    (dotimes (step maximum)
      (when (and (zerop (mod step 128)) (>= (get-internal-real-time) deadline)) (return))
      (multiple-value-bind (csn loc len fine status retry fb) (harness-leggi i buffer mutex)
        (unless (and (eq status :hit) (pattern-valido-p csn loc len fine (indice-larghezza i)))
          (error \"Reader benchmark incoerente.\"))
        (incf retries retry) (incf fallback fb) (incf operations)
        (setf sink (logxor sink csn loc len fine))))
    (list :reader number :operations operations :retries retries :fallback fallback :sink sink)))
(declaim (ftype (function (indice integer integer) list) bench-concorrente))
(defun bench-concorrente (i readers deadline)
  (let* ((mutex (sb-thread:make-mutex :name \"SPK-01 benchmark writer\"))
         (buffer (make-array 16 :element-type '(unsigned-byte 8)))
         (workers nil) (start (get-internal-real-time))
         (allocated (sb-ext:get-bytes-consed)))
    (dotimes (r readers)
      (let ((number r))
        (push (lambda () (bench-reader-worker i mutex number 1000000 deadline)) workers)))
    (let* ((results
             (workers-con-join
              (cons (lambda ()
                      (let ((operations 0))
                        (scrivi-chiave buffer 0)
                        (dotimes (step 200000)
                          (when (and (zerop (mod step 128))
                                     (>= (get-internal-real-time) deadline)) (return))
                          (harness-writer mutex
                            (lambda () (inserisci-pattern i buffer (1+ step))))
                          (incf operations))
                        (list :writer-operations operations))) (nreverse workers))))
           (reader-results (rest results))
           (operations (loop for r in reader-results sum (getf r :operations)))
           (retries (loop for r in reader-results sum (getf r :retries)))
           (fallback (loop for r in reader-results sum (getf r :fallback)))
           (sink (reduce #'logxor reader-results :key (lambda (r) (getf r :sink)) :initial-value 0)))
      (append (report-fase :concurrent-get operations start allocated retries sink)
              (list :harness-writer-operations (getf (first results) :writer-operations)
                    :reader-fallback fallback :workers reader-results)))))
(declaim (ftype (function (integer integer) list) warmup))
(defun warmup (capacity words)
  (let* ((i (make-indice :capacity capacity :words words))
         (buffer (make-array 16 :element-type '(unsigned-byte 8)))
         (start (get-internal-real-time)) (sink 0))
    (dotimes (id 256)
      (scrivi-chiave buffer id) (inserisci-pattern i buffer (1+ id)))
    (dotimes (step 1024)
      (scrivi-chiave buffer (mod step 256))
      (multiple-value-bind (csn loc len fine status) (leggi i buffer)
        (assert (eq status :hit)) (setf sink (logxor sink csn loc len fine))))
    (list :insert-operations 256 :get-operations 1024 :sink sink
          :wall-seconds (secondi (- (get-internal-real-time) start)))))
(declaim (ftype (function (&key (:documents integer) (:seconds real) (:capacity integer)
                               (:words integer) (:readers integer) (:memory-mib integer)) list)
                benchmark))
(defun benchmark (&key (documents 100000) (seconds 12) (capacity 8192)
                       (words 4) (readers 2) (memory-mib 512))
  \"Misure wall limitate a blocchi; restituisce conteggi reali e fase incompleta.\"
  (intero-limitato documents 1 10000000)
  (unless (typep seconds '(real (0) 600))
    (error 'type-error :datum seconds :expected-type '(real (0) 600)))
  (intero-limitato readers 1 8)
  (let* ((i (make-indice :capacity capacity :words words :memory-mib memory-mib))
         (warmed (warmup capacity words)) (start (get-internal-real-time))
         (ticks (ceiling (* seconds internal-time-units-per-second)))
         (deadline (+ start ticks)) (insert-deadline (+ start (floor ticks 2))))
    (multiple-value-bind (insert-report actual) (bench-insert i documents insert-deadline)
      (when (zerop actual) (error 'limite-indice :motivo :budget-senza-documenti))
      (let* ((before-churn (indice-statistiche i))
             (get-report (bench-get i actual (+ start (floor (* ticks 7) 10))))
             (churn-report (bench-churn i actual (+ start (floor (* ticks 8) 10))))
             (after-churn (indice-statistiche i))
             (concurrent (bench-concorrente i readers
                          (min deadline (+ (get-internal-real-time)
                                           (* 5 internal-time-units-per-second))))))
        (list :spike :spk-01 :status :measured :layout :adr-0043-v1 :verifies-format-v2 nil
              :environment (list :implementation (lisp-implementation-type)
                                 :version (lisp-implementation-version) :machine (machine-type)
                                 :cpu (machine-version) :os (software-type) :os-version (software-version)
                                 :timer-units-per-second internal-time-units-per-second
                                 :safety 3 :speed 2)
              :parameters (list :documents documents :seconds seconds :capacity capacity
                                :words words :readers readers :memory-mib memory-mib :seed 424242)
              :warmup warmed :actual-documents actual :insert-complete (= actual documents)
              :measurement-wall-seconds (secondi (- (get-internal-real-time) start))
              :phases (list insert-report get-report churn-report concurrent)
              :before-churn before-churn :after-churn after-churn
              :allocation-scope :process-including-harness-and-bignums
              :memory-scope :live-array-payload-and-directory-excluding-headers
              :limits '(:local-scale :no-gc-pause-measurement :no-mvcc
                        :no-cross-architecture-disassembly :harness-fallback-mutex))))))
")
  (:PATH
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/lettura-buffer.lisp")
   :HASH-KIND :GIT-BLOB :HASH "899021815a7b1415d225ce5ba712564593504402"
   :CONTENT
   ";;;; SPK-01, Fase 0: lettura in buffer del layout v1, parole 4/5-extra-end.
;;;; Proprietà e metodo preregistrato: metodo-lettura-buffer.md.
(defpackage #:arcdocdb.spk01.lettura-buffer
  (:use #:cl)
  (:import-from #:arcdocdb.spk01
                #:indice #:indice-root #:ottetti #:parole #:u64
                #:radice #:radice-generazione #:frammento
                #:frammento-capacita #:frammento-larghezza #:frammento-slots
                #:frammento-ctrl #:frammento-chiavi
                #:hash-chiave #:scegli-frammento #:posizione-sonda #:impronta
                #:stessa-chiave-p #:intero-limitato #:limite-indice
                #:+gruppo+ #:+vuoto+)
  (:export #:leggi))
(in-package #:arcdocdb.spk01.lettura-buffer)
(declaim (optimize (safety 3) (speed 3) (debug 1)))

(deftype destinazione-lettura () '(simple-array (unsigned-byte 64) (4)))

(declaim
 (ftype (function (indice ottetti destinazione-lettura
                   &key (:attempts integer)
                        (:after-fragment (or null function))
                        (:after-fields (or null function)))
                  (values keyword fixnum &optional))
        leggi))
(defun leggi (indice chiave destinazione
              &key (attempts 8) after-fragment after-fields)
  \"Restituisce :HIT/:MISS/:RETRY-LIMIT e tentativi scartati (0..8).
Solo :HIT scrive [CSN, location, length, end-CSN] dopo seqlock e root.
CHIAVE e DESTINAZIONE restano private al chiamante durante la lettura.\"
  (declare (type indice indice) (type ottetti chiave)
           (type destinazione-lettura destinazione) (type integer attempts)
           (type (or null function) after-fragment after-fields))
  ;; Tutti gli ingressi sono controllati prima dell'hash e degli accessi indice.
  (check-type indice indice)
  (check-type chiave ottetti)
  (check-type destinazione destinazione-lettura)
  (check-type after-fragment (or null function))
  (check-type after-fields (or null function))
  (intero-limitato attempts 1 8)
  (unless (= 16 (length chiave))
    (error 'limite-indice :motivo :chiave-16-byte))
  (let ((limite (the (integer 1 8) attempts)))
    ;; Un solo algoritmo espanso due volte: nessuna chiamata u64 tra helper.
    ;; Il percorso diretto non contiene FUNCALL né ritorni di payload Lisp.
    (macrolet
        ((lettura (strumentata)
           `(let ((hash (hash-chiave chiave 0)))
              (declare (type u64 hash))
              (dotimes (tentativo limite (values :retry-limit limite))
                (declare (type (integer 0 8) tentativo))
                (let* ((root (indice-root indice))
                       (generazione (radice-generazione root)))
                  (declare (type radice root) (type fixnum generazione))
                  (sb-thread:barrier (:read))
                  (let* ((frammento (scegli-frammento root hash))
                         (csn 0) (posizione 0) (lunghezza 0) (fine 0)
                         (stato :miss))
                    (declare (type frammento frammento)
                             (type u64 csn posizione fine)
                             (type (unsigned-byte 24) lunghezza)
                             (type keyword stato))
                    ,@(when strumentata
                        '((when after-fragment
                            (funcall after-fragment frammento))))
                    (let ((capacita (frammento-capacita frammento)))
                      (declare (type fixnum capacita))
                      (block sondaggio
                        (dotimes (gruppo (ceiling capacita +gruppo+))
                          (declare (type fixnum gruppo))
                          (dotimes (n +gruppo+)
                            (declare (type fixnum n))
                            (let* ((slot (posizione-sonda
                                          hash capacita
                                          (+ (* gruppo +gruppo+) n)))
                                   (controllo (aref (frammento-ctrl frammento)
                                                   slot)))
                              (declare (type fixnum slot)
                                       (type (unsigned-byte 8) controllo))
                              (when (= controllo +vuoto+)
                                (return-from sondaggio nil))
                              (when (= controllo (impronta hash))
                                (let* ((parole (frammento-slots frammento))
                                       (base (* slot
                                                (frammento-larghezza frammento)))
                                       (sequenza (aref parole (+ base 3))))
                                  (declare (type parole parole)
                                           (type fixnum base) (type u64 sequenza))
                                  (when (oddp sequenza)
                                    (setf stato :retry)
                                    (return-from sondaggio nil))
                                  (sb-thread:barrier (:read))
                                  (let* ((csn-letto (aref parole base))
                                         (posizione-letta (aref parole (+ base 1)))
                                         (metadati (aref parole (+ base 2)))
                                         (fine-letta
                                           (if (= 5 (frammento-larghezza frammento))
                                               (aref parole (+ base 4)) 0))
                                         (controllo-letto
                                           (aref (frammento-ctrl frammento) slot))
                                         (arena (frammento-chiavi frammento))
                                         (offset (ldb (byte 24 0) metadati))
                                         (corrisponde
                                           (and (= controllo-letto (impronta hash))
                                                (= 1 (ldb (byte 8 56) metadati))
                                                (= 16 (ldb (byte 8 24) metadati))
                                                (<= (+ offset 16) (length arena))
                                                (stessa-chiave-p chiave arena offset))))
                                    (declare (type u64 csn-letto posizione-letta
                                                   metadati fine-letta)
                                             (type (unsigned-byte 8) controllo-letto)
                                             (type ottetti arena) (type fixnum offset)
                                             (type boolean corrisponde))
                                    ,@(when strumentata
                                        '((when after-fields
                                            (funcall after-fields frammento slot))))
                                    (sb-thread:barrier (:read))
                                    (when (/= sequenza (aref parole (+ base 3)))
                                      (setf stato :retry)
                                      (return-from sondaggio nil))
                                    (when corrisponde
                                      (setf csn csn-letto posizione posizione-letta
                                            lunghezza (ldb (byte 24 32) metadati)
                                            fine fine-letta stato :hit)
                                      (return-from sondaggio nil))))))))))
                    ;; Anche un miss deve appartenere alla root ancora corrente.
                    (sb-thread:barrier (:read))
                    (let ((corrente (indice-root indice)))
                      (declare (type radice corrente))
                      (when (and (not (eq stato :retry)) (eq corrente root)
                                 (= generazione (radice-generazione corrente)))
                        ;; Nessun callback o accesso condiviso dopo la validazione.
                        (when (eq stato :hit)
                          (setf (aref destinazione 0) csn
                                (aref destinazione 1) posizione
                                (aref destinazione 2) lunghezza
                                (aref destinazione 3) fine))
                        (return-from leggi (values stato tentativo))))))))))
      (if (or after-fragment after-fields)
          (lettura t)
          (lettura nil)))))
")
  (:PATH
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/metodo-lettura-buffer.md")
   :HASH-KIND :GIT-BLOB :HASH "595caf90327f7bd80f71ad4467960838f4cb8ad1"
   :CONTENT "# SPK-01 — metodo preregistrato: lettura in buffer

Registrazione del 2026-10-08, Fase 0. Solo Common Lisp/SBCL, `safety 3`,
`speed 3`, `debug 1`; zero warning e style-warning. Nessun `eval`,
`ignore-errors` o `truly-the`. La compilazione non sostituisce CHECK.

## Ownership e dipendenza

Checkout esclusivo di lavoro:
`/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB`.
Questo agente possiede soltanto `lettura-buffer.lisp`, questo metodo e nuovi
direttori `spikes/SPK-01-primary-index/out/lettura-buffer-*`. Core e runner
esistenti, `tools/`, documenti condivisi e `src/` restano fuori dalla proprietà.
Nessun commit o push. Driver e diagnostica nuovi risiedono nei miei out.
Il modulo richiede il core caricato; importa internals senza ridefinirli.

## API e condizioni

Package `ARCDOCDB.SPK01.LETTURA-BUFFER`, unico export `LEGGI`:

```lisp
(leggi indice chiave destinazione
       &key (attempts 8) after-fragment after-fields)
;; => (values status-keyword retry-fixnum)
```

`indice` è un indice del core; `chiave` è un simple-array di 16 u8.
`destinazione` è esattamente `(simple-array (unsigned-byte 64) (4))`, privata
al chiamante: `[CSN, location, length, end-CSN]`. Tipi, callback e lunghezza
della chiave sono validati, e `attempts` deve essere intero 1..8, prima di hash,
accessi all'indice e scritture. Tipi errati producono `type-error`; chiave con
lunghezza diversa produce `limite-indice` con motivo `:chiave-16-byte`.
Callback accettati: NIL o oggetto funzione, non designatori simbolici.

Esiti: `:hit` e `:miss` con numero di tentativi scartati 0..7;
`:retry-limit` con esattamente `attempts` tentativi scartati. Quest'ultimo è
un esito di esaurimento esplicito, mai una lettura riuscita o parziale.
La destinazione viene scritta interamente soltanto su `:hit`, dopo tutte le
validazioni. Miss, esaurimento ed errori sincroni lasciano le quattro parole
immutate. Nessuna lettura di payload viene restituita come valore Lisp.

Il chiamante mantiene chiave e destinazione stabili e private durante la
chiamata, inclusi i callback. I callback di fixture non modificano questi
buffer e mantengono gli invarianti del core; `after-fragment` riceve il
frammento e `after-fields` riceve frammento e slot. Errori dei callback sono
propagati prima di qualsiasi scrittura. Le quattro scritture non costituiscono
una pubblicazione atomica a osservatori concorrenti della destinazione.

## Algoritmo, ordine e linearizzazione

La fonte è `LEGGI`/`SONDA-READER`/`LEGGI-SLOT` del core. Una sola macro locale
espande lo stesso algoritmo nei cammini diretto e strumentato. Il primo
esclude chiamate ai callback; il secondo inserisce soltanto i due punti di
iniezione. Payload e hash sono locali typed u64: nessun trasporto di payload
tra funzioni o valori multipli. Gli helper hash/sondaggio già inline del core
rimangono le dipendenze. Nessun abbassamento di safety.

Ordine conservato: acquisizione root/generazione; barriera read; selezione
frammento e callback; sondaggio nei gruppi di otto del core; sequenza iniziale
pari; barriera read; campi, ctrl, arena e confronto chiave; callback;
barriera read; uguaglianza sequenza; barriera read; rilettura root e generazione.
Una sequenza dispari o cambiata scarta l'intero tentativo. Una root diversa
scarta hit e miss. Skip prosegue il sondaggio, ctrl vuoto lo conclude con miss.
Nessun writer, lock, CAS o cambio dell'ordine delle barriere nel modulo.

Per hit il candidato è coerente nell'intervallo seqlock stabile e viene
accettato solo dopo il ricontrollo root/generazione. Quel controllo è il punto
di accettazione, non l'affermazione che il payload rappresenti lo stato
all'istante della rilettura root: un writer può aggiornare lo stesso slot dopo
la seconda lettura della sequenza. Miss conserva il criterio del core, anche
per root ritirata. Non si fissa la linearizzazione all'acquisizione della root;
valgono le qualificazioni del prototipo v1 e il vincolo di un singolo writer.

Layout: words4 v1 (end-CSN zero) e words5-extra-end v1 (quinta parola end-CSN),
non v2. CSN, location ed end-CSN u64 alti devono conservarsi esattamente.
Il limite per tentativo è C slot, con C limitata dal costruttore del core;
al massimo otto tentativi. Nessuna garanzia temporale per callback arbitrari.

## Campagna consentita e preregistrazione delle esecuzioni

Budget: massimo quattro revisioni compilate, 90 secondi per processo figlio,
120 secondi nel registratore e 5 secondi per cleanup, heap 1024 MiB.
Un driver nuovo Common Lisp in out avvia processi SBCL senza
init utente e senza shell. Preregistra prima del lancio argv, stdin vuoto,
operazione, budget, snapshot integrali e hash Git blob di core, modulo, metodo
e driver. Snapshot before/after diversi, esaurimento, condizioni o ritorni
compile-file warning/failure sono fallimenti; nessun successo parziale.

Ogni compilazione ha un nuovo out esclusivo e record schema 1, con
`:schema-version 1`, `:argv`, `:stdin`, `:source-before`, `:source-after`,
stdout/stderr originali, exit code e `:decoded`. Anche gli insuccessi sono
conservati. I dati usano liste, keyword, stringhe e numeri; tipi e funzioni
figurano come stringhe, assenza come keyword. La decodifica con `*read-eval*`
NIL avviene nel processo registratore che non carica package dello spike.
Il driver promuove warning/style-warning a errori, verifica gli indicatori di
compile-file e carica il FASL solo se compilato senza avvisi. Non chiama LEGGI.

Esecuzione C1 preregistrata: compilare core e modulo, caricare i FASL,
disassemblare LEGGI, conservare diagnostica e sorgenti stabili. Scopo della
diagnostica: cercare boxing dei payload e chiamate u64 nel cammino diretto;
barriere e bounds check devono essere presenti. Nessuna misura di prestazioni,
allocazioni o throughput. Il disassemblato vale solo per il runtime osservato.
Eventuali revisioni avranno una motivazione e nuova preregistrazione qui,
prima della loro compilazione, senza sovrascrivere i record precedenti.

Driver della campagna: `out/lettura-buffer-campagna-20261008-01/driver-campagna.lisp`
e `driver-compila.lisp` nello stesso direttorio. Comando C1, dalla radice del
checkout isolato:

```sh
/opt/homebrew/bin/sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-01-primary-index/out/lettura-buffer-campagna-20261008-01/driver-campagna.lisp c1
```

La preregistrazione schema 1 viene salvata in `c1/record.sexp` prima di avviare
il processo figlio; stdin, stdout, stderr, FASL e disassemblato sono in `c1/`.

Gli agenti non eseguono BENCH; le misure, la profilazione iniziale e
l'integrazione competono al parent e vengono serializzate da lui. Questo
agente non esegue CHECK del modulo: è proprietà dell'altro agente. La
serializzazione dei writer del core resta responsabilità dell'harness parent.

## Controlli richiesti all'agente CHECK e al parent

Confronto con il core per hit, miss, collisioni e skip, parole 4/5, u64 zero,
massimi e oltre fixnum, lunghezza massima a 24 bit. Sentinel completa invariata
su miss, retry-limit, ingressi invalidi ed errori callback. Witness deterministici
root hit/miss ritirata, sequence odd e changing, contatore retry esatto;
attempts 1 e 8, valori invalidi, array non semplici o di lunghezza diversa,
callback errati. Verificare i due percorsi con lo stesso oracolo e gli invarianti
single writer; nessun BENCH prima della validazione del parent.
")
  (:PATH
   #A((150) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/lettura-buffer-campagna-20261008-01/driver-campagna.lisp")
   :HASH-KIND :GIT-BLOB :HASH "ea60c491369651197c2d7b767132aa31b4fabb50"
   :CONTENT
   ";;;; Registratore schema 1 senza package dello spike, nessuna shell.
(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 2) (debug 1)))
(require :asdf)
(require :sb-posix)

(defun lb-salva (dati percorso)
  (with-open-file (stream percorso :direction :output :if-exists :supersede)
    (let ((*print-readably* t) (*print-pretty* t))
      (write dati :stream stream) (terpri stream))))

(defun lb-snapshot (percorsi)
  (loop for percorso in percorsi collect
    (list :path (namestring percorso)
          :hash-kind :git-blob
          :hash (string-trim '(#\\Newline #\\Return)
                  (uiop:run-program
                    (list \"git\" \"hash-object\" \"--\" (namestring percorso))
                    :output :string :error-output :string))
          :content (uiop:read-file-string percorso :external-format :utf-8))))

(defun lb-dati-semplici-p (valore)
  (cond ((null valore) t)
        ((consp valore) (and (lb-dati-semplici-p (car valore))
                            (lb-dati-semplici-p (cdr valore))))
        (t (or (keywordp valore) (stringp valore) (numberp valore)))))

(defun lb-decodifica (testo)
  (when (> (length testo) 1048576) (error \"Budget di decodifica esaurito.\"))
  (let ((*read-eval* nil))
    (with-input-from-string (stream testo)
      (let ((dati (read stream nil :eof)))
        (unless (and (listp dati) dati (lb-dati-semplici-p dati)
                     (eq :eof (read stream nil :eof)))
          (error \"Output non decodificabile come soli dati.\"))
        dati))))

(defun lb-registra ()
  (let* ((radice #p\"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/\")
         (base (merge-pathnames \"spikes/SPK-01-primary-index/\" radice))
         (campagna (uiop:pathname-directory-pathname *load-truename*))
         (argomenti (uiop:command-line-arguments))
         (nome (first argomenti))
         (figlio (merge-pathnames \"driver-compila.lisp\" campagna)))
    (unless (and (= 1 (length argomenti))
                 (member nome '(\"c1\" \"c2\" \"c3\" \"c4\") :test #'string=))
      (error \"Budget: sono consentite solo le esecuzioni c1..c4.\"))
    (when (or (find-package \"ARCDOCDB.SPK01\")
              (find-package \"ARCDOCDB.SPK01.LETTURA-BUFFER\"))
      (error \"Il registratore deve essere privo dei package dello spike.\"))
    (let* ((uscita (merge-pathnames (format nil \"~A/\" nome) campagna))
           (record-path (merge-pathnames \"record.sexp\" uscita))
           (stdout-path (merge-pathnames \"stdout.txt\" uscita))
           (stderr-path (merge-pathnames \"stderr.txt\" uscita))
           (stdin-path (merge-pathnames \"stdin.txt\" uscita))
           (sorgenti (list (merge-pathnames \"core.lisp\" base)
                          (merge-pathnames \"lettura-buffer.lisp\" base)
                          (merge-pathnames \"metodo-lettura-buffer.md\" base)
                          *load-truename* figlio))
           (argv (list \"/opt/homebrew/bin/sbcl\" \"--noinform\" \"--no-userinit\"
                       \"--no-sysinit\" \"--dynamic-space-size\" \"1024\" \"--script\"
                       (namestring figlio) \"compile-disassemble\"
                       (namestring uscita)))
           (record
             (list :schema-version 1 :kind :compilation-disassembly
                   :execution nome :status :preregistered
                   :cwd (namestring radice) :argv argv :stdin \"\"
                   :driver-argv (copy-list sb-ext:*posix-argv*)
                   :operation \"COMPILE-FILE CORE; LOAD; COMPILE-FILE LETTURA-BUFFER; LOAD; DISASSEMBLE LEGGI\"
                   :budget '(:child-seconds 90 :parent-seconds 120
                             :cleanup-seconds 5 :heap-mib 1024 :max-revisions 4)
                   :source-before (lb-snapshot sorgenti) :source-after :not-collected
                   :source-stability :not-collected :stdout :not-collected
                   :stderr :not-collected :exit-code :not-collected
                   :decoded :not-collected :started-at (get-universal-time)
                   :environment (list :implementation (lisp-implementation-type)
                                      :version (lisp-implementation-version)
                                      :os (software-type) :os-version (software-version)
                                      :machine (machine-type)))))
      ;; mkdir esclusivo: non si sovrascrive un tentativo o un fallimento.
      (sb-posix:mkdir uscita #o700)
      (with-open-file (stream stdin-path :direction :output :if-exists :error)
        (write-string \"\" stream))
      (lb-salva record record-path)
      (let ((processo :not-started))
        (handler-case
            (progn
              (setf processo (uiop:launch-program argv :input stdin-path
                                                :output stdout-path :error-output stderr-path
                                                :directory radice))
              (setf (getf record :exit-code)
                    (sb-ext:with-timeout 120 (uiop:wait-process processo))))
          (sb-ext:timeout (condizione)
            (setf (getf record :status) :error
                  (getf record :condition) (princ-to-string condizione))
            (unless (eq processo :not-started)
              (uiop:terminate-process processo :urgent t)
              (handler-case
                  (setf (getf record :exit-code)
                        (sb-ext:with-timeout 5 (uiop:wait-process processo)))
                (sb-ext:timeout (cleanup)
                  (setf (getf record :cleanup-condition) (princ-to-string cleanup))))))
          (error (condizione)
            (setf (getf record :status) :error
                  (getf record :condition) (princ-to-string condizione))))
        (handler-case
            (progn
              (setf (getf record :stdout)
                    (if (probe-file stdout-path) (uiop:read-file-string stdout-path) \"\")
                    (getf record :stderr)
                    (if (probe-file stderr-path) (uiop:read-file-string stderr-path) \"\")
                    (getf record :source-after) (lb-snapshot sorgenti)
                    (getf record :finished-at) (get-universal-time))
              (setf (getf record :source-stability)
                    (if (equal (getf record :source-before) (getf record :source-after))
                        :stable :changed))
              ;; Qui nessun package dello spike è stato caricato.
              (setf (getf record :decoded) (lb-decodifica (getf record :stdout)))
              (when (probe-file (merge-pathnames \"leggi-disassembly.txt\" uscita))
                (setf (getf record :disassembly)
                      (uiop:read-file-string
                        (merge-pathnames \"leggi-disassembly.txt\" uscita))))
              (setf (getf record :status)
                    (if (and (not (eq :error (getf record :status)))
                             (eql 0 (getf record :exit-code))
                             (eq :stable (getf record :source-stability))
                             (eq :ok (getf (getf record :decoded) :status)))
                        :ok :error)))
          (error (condizione)
            (setf (getf record :status) :error
                  (getf record :decoding-condition) (princ-to-string condizione))))
        (lb-salva record record-path)
        ;; Verifica di rilettura del record, ancora priva dei package spike.
        (let ((*read-eval* nil))
          (with-open-file (stream record-path)
            (let ((dati (read stream nil :eof)))
              (unless (and (lb-dati-semplici-p dati) (equal dati record)
                           (eq :eof (read stream nil :eof)))
                (error \"Record finale non rileggibile.\")))))
        (write (list :schema-version 1 :status (getf record :status)
                     :record (namestring record-path)
                     :source-stability (getf record :source-stability)
                     :decoded (getf record :decoded)))
        (terpri) (finish-output)
        (unless (eq :ok (getf record :status)) (sb-ext:exit :code 1))))))

(lb-registra)
")
  (:PATH
   #A((149) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/lettura-buffer-campagna-20261008-01/driver-compila.lisp")
   :HASH-KIND :GIT-BLOB :HASH "f9968f3b223bb9ce977b87ffffcc0fb0562cec83"
   :CONTENT
   ";;;; Driver esclusivo: soltanto compile/load/disassemble, nessun CHECK/BENCH.
(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 3) (debug 1)))
(require :asdf)

(defun lb-compila (sorgente uscita)
  (handler-bind ((warning (lambda (condizione)
                           (error \"Avviso di compilazione: ~A\" condizione))))
    (multiple-value-bind (fasl avvisi fallimento)
        (compile-file sorgente :output-file uscita :verbose nil :print nil)
      (when (or avvisi fallimento (null fasl))
        (error \"Compilazione rifiutata: ~A, avvisi ~S, fallimento ~S.\"
               sorgente avvisi fallimento))
      (load fasl :verbose nil :print nil)
      (list :source (namestring sorgente) :output (namestring fasl)
            :warnings :absent :failure :absent :status :ok))))

(defun lb-esegui ()
  (let* ((argomenti (uiop:command-line-arguments))
         (uscita (pathname (second argomenti)))
         (base #p\"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/\")
         (compilazioni
           (list (lb-compila (merge-pathnames \"core.lisp\" base)
                             (merge-pathnames \"core.fasl\" uscita))
                 (lb-compila (merge-pathnames \"lettura-buffer.lisp\" base)
                             (merge-pathnames \"lettura-buffer.fasl\" uscita))))
         (package (or (find-package \"ARCDOCDB.SPK01.LETTURA-BUFFER\")
                      (error \"Package della variante assente.\")))
         (simbolo (or (find-symbol \"LEGGI\" package) (error \"API assente.\")))
         (disassemblato (merge-pathnames \"leggi-disassembly.txt\" uscita)))
    (unless (string= (first argomenti) \"compile-disassemble\")
      (error \"Operazione non autorizzata.\"))
    (with-open-file (stream disassemblato :direction :output :if-exists :error)
      (let ((*standard-output* stream))
        (disassemble (symbol-function simbolo))))
    (list :schema-version 1 :status :ok :kind :compilation-disassembly
          :compilations compilazioni
          :function \"ARCDOCDB.SPK01.LETTURA-BUFFER:LEGGI\"
          :type \"(FUNCTION (INDICE OTTETTI (SIMPLE-ARRAY (UNSIGNED-BYTE 64) (4)) &KEY (:ATTEMPTS INTEGER) (:AFTER-FRAGMENT (OR NULL FUNCTION)) (:AFTER-FIELDS (OR NULL FUNCTION))) (VALUES KEYWORD FIXNUM &OPTIONAL))\"
          :disassembly (namestring disassemblato) :checks :not-executed
          :benchmarks :not-executed :safety 3
          :implementation (lisp-implementation-type)
          :version (lisp-implementation-version) :machine (machine-type))))

(let ((*read-eval* nil) (*print-readably* t) (*print-pretty* t))
  (handler-case
      (let ((risultato (sb-ext:with-timeout 90 (lb-esegui))))
        (write risultato) (terpri) (finish-output))
    (sb-ext:timeout (condizione)
      (format *error-output* \"~&~A~%\" condizione)
      (write (list :schema-version 1 :status :error :kind :budget-exhausted
                   :condition (princ-to-string condizione)))
      (terpri) (finish-output) (sb-ext:exit :code 2))
    (error (condizione)
      (format *error-output* \"~&~A~%\" condizione)
      (write (list :schema-version 1 :status :error :kind :compilation-disassembly
                   :condition-type (princ-to-string (type-of condizione))
                   :condition (princ-to-string condizione)))
      (terpri) (finish-output) (sb-ext:exit :code 1))))
"))
 :SOURCE-STABILITY :STABLE :STDOUT "" :STDERR
 "fatal error before reaching READ-EVAL-PRINT loop: 
  C runtime option --dynamic-space-size in the middle of Lisp options.
"
 :EXIT-CODE 1 :DECODED :NOT-COLLECTED :STARTED-AT 4000483597 :ENVIRONMENT
 (:IMPLEMENTATION #A((4) BASE-CHAR . "SBCL") :VERSION
  #A((5) BASE-CHAR . "2.6.9") :OS #A((6) BASE-CHAR . "Darwin") :OS-VERSION
  #A((6) BASE-CHAR . "27.0.0") :MACHINE #A((5) BASE-CHAR . "ARM64")))
