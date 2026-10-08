(:SCHEMA 1 :STATUS :OK :MODE :STRICT-COMPILE-LOAD-ONLY :ARGV
 ("/opt/homebrew/bin/sbcl" "--noinform" "--disable-debugger" "--script"
  "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/driver.lisp"
  "003")
 :STDIN "" :CWD
 "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/"
 :RECORDER-ARGV ("/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl" "003")
 :RECORDER-STDIN "" :ENVIRONMENT
 (:IMPLEMENTATION "SBCL" :VERSION "2.6.9" :MACHINE "ARM64" :OS "Darwin"
  :OS-VERSION "27.0.0" :TIMER-UNITS-PER-SECOND 1000000 :SAFETY 3)
 :SOURCE-BEFORE
 ((:PATH
   "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/core.lisp"
   :HASH-KIND "MD5" :HASH "1acc82229e9ebb3b43032e70dfb7de4a" :CONTENTS
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
   "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/lettura-buffer.lisp"
   :HASH-KIND "MD5" :HASH "f5c8c3a80b3f9bb83e4eb733f7f751bc" :CONTENTS
   ";;;; SPK-01, Fase 0: lettura in buffer del layout v1, parole 4/5-extra-end.
;;;; Proprietà e metodo preregistrato: metodo-lettura-buffer.md.
;;; REQ: REQ-IDX-001 REQ-IDX-007 REQ-VAL-001
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
   "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/bench-lettura-buffer.lisp"
   :HASH-KIND "MD5" :HASH "25cad8e4e8aa2bf1d51a76e70218d742" :CONTENTS
   ";;;; Fase0, layout v1. Nessuna esecuzione al caricamento.
;;;; Preregistrazione: metodo-bench-lettura-buffer.md.
;;;; REQ: REQ-VAL-001 REQ-BEN-001
(defpackage #:arcdocdb.spk01.bench-lettura-buffer
  (:use #:cl)
  (:export #:bench))
(in-package #:arcdocdb.spk01.bench-lettura-buffer)
(declaim (optimize (safety 3) (speed 3) (debug 1)))

(deftype u64 () '(unsigned-byte 64))
(deftype octets () '(simple-array (unsigned-byte 8) (*)))
(deftype words () '(simple-array (unsigned-byte 64) (*)))
(deftype destination () '(simple-array (unsigned-byte 64) (4)))
(defconstant +u64-max+ #xffffffffffffffff)
(defconstant +checksum-mask+ #x0fffffffffffffff)
(defconstant +positive-elements+ 262144)
(defvar *consed-positive-control* nil)

;; Proclamazione della sola dipendenza; nessuna implementazione del reader.
(declaim (ftype (function (arcdocdb.spk01::indice octets destination
                          &key (:attempts integer)
                          (:after-fragment (or null function))
                          (:after-fields (or null function)))
                         (values keyword fixnum &optional))
                arcdocdb.spk01.lettura-buffer:leggi))

(define-condition budget-error (error)
  ((reason :initarg :reason :reader budget-reason))
  (:report (lambda (condition stream)
             (format stream \"BENCH lettura buffer: ~A\" (budget-reason condition)))))

(defstruct (cell (:constructor %cell))
  (number 0 :type fixnum :read-only t)
  (width 4 :type fixnum :read-only t)
  (profile :fields-fixnum :type keyword :read-only t)
  (workload :hit-only :type keyword :read-only t)
  (index (arcdocdb.spk01:make-indice) :type arcdocdb.spk01::indice :read-only t)
  (queries #() :type simple-vector :read-only t)
  (oracle (make-array 0 :element-type '(unsigned-byte 64)) :type words :read-only t)
  (expected (make-array 0 :element-type '(unsigned-byte 8)) :type octets :read-only t)
  ;; Privato a questa cella e al singolo chiamante; mai condiviso fra worker.
  (output (make-array 4 :element-type '(unsigned-byte 64))
          :type destination :read-only t))

(declaim (ftype (function (t integer integer keyword) integer) %bounded))
(defun %bounded (value low high reason)
  (unless (and (integerp value) (<= low value high))
    (error 'budget-error :reason reason))
  value)

(declaim (ftype (function (fixnum integer integer integer) null) %guard))
(defun %guard (deadline consed-start consed-limit heap-limit)
  (declare (type fixnum deadline)
           (type integer consed-start consed-limit heap-limit))
  (when (>= (get-internal-real-time) deadline)
    (error 'budget-error :reason :deadline))
  (let ((used (- (sb-ext:get-bytes-consed) consed-start)))
    (when (or (minusp used) (> used consed-limit))
      (error 'budget-error :reason :consed)))
  (when (> (sb-kernel:dynamic-usage) heap-limit)
    (error 'budget-error :reason :dynamic-heap))
  nil)

(declaim (inline %fold %verify-and-fold))
(declaim (ftype (function (fixnum u64) fixnum) %fold))
(defun %fold (checksum value)
  (declare (type fixnum checksum) (type u64 value))
  ;; La rotazione resta sotto 2^61; entrambe le parti dell'u64 sono fixnum.
  (logxor (logand +checksum-mask+ (ash checksum 1)) (ash checksum -59)
          (logand +checksum-mask+ value) (ash value -60)))

(declaim (ftype (function (keyword fixnum (unsigned-byte 8) words fixnum
                           u64 u64 u64 u64 fixnum) fixnum) %verify-and-fold))
(defun %verify-and-fold (status retry expected oracle offset csn location length end checksum)
  (declare (type keyword status) (type fixnum retry offset checksum)
           (type (unsigned-byte 8) expected) (type words oracle)
           (type u64 csn location length end))
  (unless (and (if (= expected 1) (eq status :hit) (eq status :miss))
               (zerop retry))
    (error 'budget-error :reason :status-or-retries))
  (unless (and (= csn (aref oracle offset))
               (= location (aref oracle (+ offset 1)))
               (= length (aref oracle (+ offset 2)))
               (= end (aref oracle (+ offset 3))))
    (error 'budget-error :reason :oracle-payload))
  (logxor (%fold (%fold (%fold (%fold checksum csn) location) length) end)
          expected retry))

;; Due chiamate dirette in espansioni distinte, consumatore identico.
;; La macro alloca solo durante la compilazione; nessun cons nel ciclo.
(macrolet ((%define-consumer (name method)
  (let ((lookup
          (ecase method
            (:baseline
             '(multiple-value-bind (read-csn read-location read-length read-end state discarded)
                  (arcdocdb.spk01:leggi index key :attempts attempts)
                (declare (type u64 read-csn read-location read-end)
                         (type (unsigned-byte 24) read-length)
                         (type keyword state) (type fixnum discarded))
                (setf status state retry discarded)
                (when (eq state :hit)
                  (setf csn read-csn location read-location
                        payload-length read-length end read-end))))
            (:buffer
             '(multiple-value-bind (state discarded)
                  (arcdocdb.spk01.lettura-buffer:leggi index key output :attempts attempts)
                (declare (type keyword state) (type fixnum discarded))
                (setf status state retry discarded
                      csn (aref output 0) location (aref output 1)
                      payload-length (aref output 2) end (aref output 3)))))))
    `(progn
       (declaim (ftype (function (cell fixnum fixnum fixnum integer integer integer)
                                (values fixnum fixnum fixnum fixnum fixnum)) ,name))
       (defun ,name (fixture operations attempts deadline consed-start consed-limit heap-limit)
         (declare (type cell fixture) (type fixnum operations attempts deadline)
                  (type integer consed-start consed-limit heap-limit))
         (let* ((index (cell-index fixture)) (queries (cell-queries fixture))
                (oracle (cell-oracle fixture)) (expected (cell-expected fixture))
                ,@(when (eq method :buffer) '((output (cell-output fixture))))
                (query-count (length queries))
                (cursor 0) (offset 0) (completed 0) (checksum 0) (retries 0)
                (hits 0) (misses 0) (csn 0) (location 0) (payload-length 0) (end 0))
           (declare (type arcdocdb.spk01::indice index)
                    (type simple-vector queries) (type words oracle) (type octets expected)
                    ,@(when (eq method :buffer) '((type destination output)))
                    (type fixnum query-count cursor offset completed checksum retries hits misses)
                    (type u64 csn location payload-length end))
           (dotimes (step operations)
             (declare (type fixnum step))
             (when (zerop (logand step 255))
               (%guard deadline consed-start consed-limit heap-limit))
             (let ((key (the octets (aref queries cursor))) (status :miss) (retry 0))
               (declare (type octets key) (type keyword status) (type fixnum retry))
               ,lookup
               (setf checksum
                     (%verify-and-fold status retry (aref expected cursor) oracle offset
                                       csn location payload-length end checksum))
               (incf retries retry)
               (if (eq status :hit) (incf hits) (incf misses))
               (incf completed)
               (incf cursor)
               (incf offset 4)
               (when (= cursor query-count) (setf cursor 0 offset 0))))
           (%guard deadline consed-start consed-limit heap-limit)
           (unless (= completed operations (+ hits misses))
             (error 'budget-error :reason :incomplete-operations))
           (values completed checksum retries hits misses)))))))

(%define-consumer %baseline-loop :baseline)
(%define-consumer %buffer-loop :buffer))

(declaim (ftype (function (destination) null) %reset-output))
(defun %reset-output (output)
  (declare (type destination output))
  (setf (aref output 0) 0 (aref output 1) 0 (aref output 2) 0 (aref output 3) 0)
  nil)

(declaim (ftype (function (keyword fixnum fixnum fixnum words) null) %prepare-tuple))
(defun %prepare-tuple (profile width id documents tuples)
  (declare (type keyword profile) (type fixnum width id documents) (type words tuples))
  (let ((offset (* 4 id)))
    (declare (type fixnum offset))
    (ecase profile
      (:fields-fixnum
       (setf (aref tuples offset) (+ 11 (* 3 id))
             (aref tuples (+ offset 1)) (+ 101 (* 5 id))
             (aref tuples (+ offset 2)) (1+ (mod (+ 23 (* 17 id)) 65536))
             (aref tuples (+ offset 3)) (if (= width 5) (+ 251 (* 7 id)) 0)))
      (:u64-massimi
       (setf (aref tuples offset) (- +u64-max+ id)
             (aref tuples (+ offset 1)) (- +u64-max+ (mod (+ id (1- documents)) documents))
             (aref tuples (+ offset 2)) (- #xffffff (mod (+ id 3) documents))
             (aref tuples (+ offset 3))
             (if (= width 5) (- +u64-max+ (mod (+ id 2) documents)) 0)))))
  nil)

(declaim (ftype (function (fixnum fixnum fixnum keyword keyword simple-vector
                          simple-vector fixnum integer integer integer) cell) %prepare-cell))
(defun %prepare-cell (number documents capacity profile workload keys queries
                      deadline consed-start consed-limit heap-limit)
  (declare (type fixnum number documents capacity deadline)
           (type keyword profile workload) (type simple-vector keys queries)
           (type integer consed-start consed-limit heap-limit))
  (let* ((width (if (< number 4) 4 5))
         (index (arcdocdb.spk01:make-indice :capacity capacity :words width :max-depth 0
                                         :memory-mib (ceiling heap-limit 1048576)))
         (tuples (make-array (* 4 documents) :element-type '(unsigned-byte 64)))
         (oracle (make-array (* 8 documents) :element-type '(unsigned-byte 64)))
         (expected (make-array (* 2 documents) :element-type '(unsigned-byte 8)))
         (output (make-array 4 :element-type '(unsigned-byte 64) :initial-element 0)))
    (declare (type arcdocdb.spk01::indice index) (type words tuples oracle)
             (type octets expected) (type destination output) (type fixnum width))
    (dotimes (id documents)
      (declare (type fixnum id))
      (when (zerop (logand id 127))
        (%guard deadline consed-start consed-limit heap-limit))
      (%prepare-tuple profile width id documents tuples)
      (let* ((offset (* 4 id)) (location (aref tuples (+ offset 1))))
        (declare (type fixnum offset) (type u64 location))
        (unless (arcdocdb.spk01:inserisci
                 index (the octets (aref keys id)) (aref tuples offset)
                 (ldb (byte 32 32) location) (ldb (byte 32 0) location)
                 (aref tuples (+ offset 2)) :end-csn (aref tuples (+ offset 3)))
          (error 'budget-error :reason :non-new-document))))
    (dotimes (query (* 2 documents))
      (declare (type fixnum query))
      (when (zerop (logand query 255))
        (%guard deadline consed-start consed-limit heap-limit))
      (let* ((hit (or (eq workload :hit-only) (evenp query)))
             (id (mod (* (if (eq workload :hit-only) query (ash query -1)) 104729) documents))
             (target (* 4 query)) (source (* 4 id)))
        (declare (type fixnum id target source))
        (setf (aref expected query) (if hit 1 0))
        (dotimes (field 4)
          (setf (aref oracle (+ target field))
                (if hit (aref tuples (+ source field))
                    (aref oracle (+ (- target 4) field)))))))
    ;; Interroghiamo contatori O(1), senza costruire statistiche/hash-table.
    (unless (and (= documents (arcdocdb.spk01::indice-documenti index))
                 (= 1 (arcdocdb.spk01::indice-frammenti index))
                 (zerop (arcdocdb.spk01::indice-split index))
                 (zerop (arcdocdb.spk01::indice-rebuild index))
                 (zerop (arcdocdb.spk01::indice-chiavi-byte-copiati index)))
      (error 'budget-error :reason :unexpected-maintenance))
    (%cell :number number :width width :profile profile :workload workload :index index
           :queries queries :oracle oracle :expected expected :output output)))

(declaim (ftype (function (fixnum fixnum integer integer integer)
                         (values simple-vector simple-vector simple-vector)) %prepare-queries))
(defun %prepare-queries (documents deadline consed-start consed-limit heap-limit)
  (declare (type fixnum documents deadline) (type integer consed-start consed-limit heap-limit))
  (let ((keys (make-array (* 2 documents)))
        (hit-queries (make-array (* 2 documents)))
        (mixed-queries (make-array (* 2 documents))))
    (declare (type simple-vector keys hit-queries mixed-queries))
    (dotimes (id (* 2 documents))
      (when (zerop (logand id 127))
        (%guard deadline consed-start consed-limit heap-limit))
      (let ((key (make-array 16 :element-type '(unsigned-byte 8))))
        (arcdocdb.spk01:scrivi-chiave key id)
        (setf (aref keys id) key)))
    (dotimes (query (* 2 documents))
      (when (zerop (logand query 255))
        (%guard deadline consed-start consed-limit heap-limit))
      (setf (aref hit-queries query) (aref keys (mod (* query 104729) documents))
            (aref mixed-queries query)
            (aref keys (+ (if (oddp query) documents 0)
                          (mod (* (ash query -1) 104729) documents)))))
    (values keys hit-queries mixed-queries)))

(declaim (ftype (function (fixnum integer integer integer) list) %positive-control))
(defun %positive-control (deadline consed-start consed-limit heap-limit)
  (declare (type fixnum deadline) (type integer consed-start consed-limit heap-limit))
  (setf *consed-positive-control* nil)
  (sb-ext:gc :full t)
  (%guard deadline consed-start consed-limit heap-limit)
  (let ((before (sb-ext:get-bytes-consed)))
    (setf *consed-positive-control*
          (make-array +positive-elements+ :element-type '(unsigned-byte 8) :initial-element 172))
    (let* ((after (sb-ext:get-bytes-consed)) (delta (- after before))
           ;; Tutte queste letture seguono AFTER; l'oggetto è pubblicato nel globale.
           (object (the octets *consed-positive-control*))
           (value (aref object (1- (length object))))
           (size (sb-ext:primitive-object-size object)))
      (unless (and (>= delta +positive-elements+) (= value 172)
                   (>= size +positive-elements+))
        (error 'budget-error :reason :consed-positive-control))
      (%guard deadline consed-start consed-limit heap-limit)
      (list :status :ok :before before :after after :bytes-consed delta
            :elements (length object) :payload-bytes +positive-elements+
            :observed-value value :primitive-object-size size
            :object-type \"(SIMPLE-ARRAY (UNSIGNED-BYTE 8) (*))\"
            :escaped-global \"ARCDOCDB.SPK01.BENCH-LETTURA-BUFFER::*CONSED-POSITIVE-CONTROL*\"
            :retention :through-delta-and-size))))

(declaim (ftype (function (cell keyword fixnum fixnum fixnum integer integer integer)
                         (values fixnum fixnum fixnum fixnum fixnum)) %consume))
(defun %consume (fixture method operations attempts deadline consed-start consed-limit heap-limit)
  (declare (type cell fixture) (type keyword method)
           (type fixnum operations attempts deadline) (type integer consed-start consed-limit heap-limit))
  (ecase method
    (:baseline (%baseline-loop fixture operations attempts deadline consed-start consed-limit heap-limit))
    (:buffer (%buffer-loop fixture operations attempts deadline consed-start consed-limit heap-limit))))

(declaim (ftype (function (cell keyword fixnum fixnum fixnum integer integer integer) list) %warm))
(defun %warm (fixture method operations attempts deadline consed-start consed-limit heap-limit)
  (declare (type cell fixture) (type keyword method) (type fixnum operations attempts deadline)
           (type integer consed-start consed-limit heap-limit))
  (%reset-output (cell-output fixture))
  (multiple-value-bind (completed checksum retries hits misses)
      (%consume fixture method operations attempts deadline consed-start consed-limit heap-limit)
    (list :method method :operations completed :checksum checksum :retries retries :hits hits :misses misses)))

(declaim (ftype (function (cell keyword fixnum fixnum fixnum fixnum fixnum keyword
                          integer integer integer) list) %measure))
(defun %measure (fixture method operations attempts deadline ordinal replica order
                 consed-start consed-limit heap-limit)
  (declare (type cell fixture) (type keyword method order)
           (type fixnum operations attempts deadline ordinal replica)
           (type integer consed-start consed-limit heap-limit))
  (%reset-output (cell-output fixture))
  (%guard deadline consed-start consed-limit heap-limit)
  (sb-ext:gc :full t)
  (%guard deadline consed-start consed-limit heap-limit)
  (let* ((heap-before (sb-kernel:dynamic-usage))
         (before (sb-ext:get-bytes-consed)) (start (get-internal-real-time)))
    (multiple-value-bind (completed checksum retries hits misses)
        (%consume fixture method operations attempts deadline consed-start consed-limit heap-limit)
      (let* ((stop (get-internal-real-time)) (after (sb-ext:get-bytes-consed))
             (ticks (- stop start)) (bytes (- after before)))
        (when (or (<= ticks 0) (minusp bytes))
          (error 'budget-error :reason :invalid-measurement-counter))
        (%guard deadline consed-start consed-limit heap-limit)
        (list :sample ordinal :cell (cell-number fixture) :replica replica :order order :method method
              :operations completed :ticks ticks :timer-units-per-second internal-time-units-per-second
              :ns-per-operation (/ (* ticks 1000000000) (* internal-time-units-per-second completed))
              :bytes-consed-before before :bytes-consed-after after :bytes-consed bytes
              :bytes-consed-per-operation (/ bytes completed)
              :heap-before heap-before :heap-after (sb-kernel:dynamic-usage)
              :checksum checksum :retries retries :hits hits :misses misses)))))

(declaim (ftype (function (list list) list) %pair))
(defun %pair (baseline buffer)
  (dolist (key '(:cell :replica :order :operations :checksum :retries :hits :misses))
    (unless (eql (getf baseline key) (getf buffer key))
      (error 'budget-error :reason :paired-disagreement)))
  (list :replica (getf baseline :replica) :order (getf baseline :order)
        :baseline-sample (getf baseline :sample) :buffer-sample (getf buffer :sample)
        :buffer-over-baseline-ticks (/ (getf buffer :ticks) (getf baseline :ticks))
        :buffer-minus-baseline-ticks (- (getf buffer :ticks) (getf baseline :ticks))
        :buffer-minus-baseline-bytes (- (getf buffer :bytes-consed) (getf baseline :bytes-consed))
        :checksum (getf baseline :checksum) :retries (getf baseline :retries)))

(declaim (ftype (function (&key (:documents integer) (:capacity integer) (:operations integer)
                          (:replicas integer) (:warmup integer) (:time-limit-seconds real)
                          (:memory-mib integer) (:attempts integer) (:max-documents integer)
                          (:max-operations integer) (:max-warmup integer) (:max-payload-bytes integer)
                          (:max-copy-bytes integer) (:max-consed-bytes integer)
                          (:max-time-limit-seconds real)) list) bench))
(defun bench (&key (documents 4096) (capacity 8192) (operations 128000) (replicas 5)
                   (warmup 4096) (time-limit-seconds 120) (memory-mib 256) (attempts 8)
                   (max-documents 16384) (max-operations 1000000) (max-warmup 65536)
                   (max-payload-bytes 33554432) (max-copy-bytes 16777216)
                   (max-consed-bytes 1073741824) (max-time-limit-seconds 300))
  \"Matrice paired completa o errore; nessun risultato parziale.\"
  (%bounded max-documents 1 28672 :max-documents)
  (%bounded max-operations 1 10000000 :max-operations)
  (%bounded max-warmup 1 1000000 :max-warmup)
  (%bounded max-payload-bytes 1 268435456 :max-payload-bytes)
  (%bounded max-copy-bytes 1 67108864 :max-copy-bytes)
  (%bounded max-consed-bytes 1 4294967296 :max-consed-bytes)
  (%bounded documents 1 max-documents :documents)
  (%bounded operations 1 max-operations :operations)
  (%bounded warmup 1 (min operations max-warmup) :warmup)
  (%bounded capacity 8 32768 :capacity)
  (%bounded replicas 5 5 :replicas-must-be-five)
  (%bounded memory-mib 1 1024 :memory-mib)
  (%bounded attempts 1 8 :attempts)
  (unless (and (= 1 (logcount capacity)) (<= documents (* 7 (floor capacity 8))))
    (error 'budget-error :reason :capacity-or-load))
  (unless (and (typep max-time-limit-seconds '(real (0) 300))
               (typep time-limit-seconds '(real (0) 300))
               (<= time-limit-seconds max-time-limit-seconds))
    (error 'budget-error :reason :time-limit-seconds))
  ;; Contratto ABI del fixture, anche su piattaforme con fixnum più piccoli.
  (unless (and (> most-positive-fixnum +checksum-mask+)
               (<= (* operations attempts) most-positive-fixnum))
    (error 'budget-error :reason :fixnum-width))
  (let* ((heap-limit (* memory-mib 1048576))
         (index-payload (+ (* 4 capacity (+ 49 57)) 64))
         ;; Chiavi 32d, tre vettori di riferimenti 48d, otto oracle 512d,
         ;; otto status 16d, tuple temporanee 32d, destinazioni 256, controllo.
         (planned-payload (+ index-payload (* documents (+ 32 48 512 16 32))
                             256 +positive-elements+))
         (planned-copy (* documents (+ (* 8 16) (* 8 2 32))))
         (start (get-internal-real-time))
         (deadline (+ start (ceiling (* time-limit-seconds internal-time-units-per-second)))))
    (declare (type fixnum start deadline))
    (when (or (> planned-payload max-payload-bytes) (> planned-payload heap-limit))
      (error 'budget-error :reason :planned-payload))
    (when (> planned-copy max-copy-bytes)
      (error 'budget-error :reason :planned-copy))
    ;; Tutti i budget sono validati prima di controllo positivo, warmup o misura.
    (sb-ext:gc :full t)
    (let* ((consed-start (sb-ext:get-bytes-consed))
           (positive (%positive-control deadline consed-start max-consed-bytes heap-limit))
           (fixtures (make-array 8)) (reports (make-array 8)) (samples (make-array 80))
           (ordinal 0) (ab 0) (ba 0))
      (declare (type simple-vector fixtures reports samples) (type fixnum ordinal ab ba))
      (multiple-value-bind (keys hit-queries mixed-queries)
          (%prepare-queries documents deadline consed-start max-consed-bytes heap-limit)
        (dotimes (number 8)
          (let ((profile (if (< (mod number 4) 2) :fields-fixnum :u64-massimi))
                (workload (if (evenp number) :hit-only :mixed-hit-miss)))
            (setf (aref fixtures number)
                  (%prepare-cell number documents capacity profile workload keys
                                 (if (evenp number) hit-queries mixed-queries)
                                 deadline consed-start max-consed-bytes heap-limit)))))
      ;; Tutta la matrice è preparata e validata prima del primo campione.
      (sb-ext:gc :full t)
      (%guard deadline consed-start max-consed-bytes heap-limit)
      (dotimes (number 8)
        (let* ((fixture (the cell (aref fixtures number)))
               (warm-a (%warm fixture :baseline warmup attempts deadline consed-start max-consed-bytes heap-limit))
               (warm-b (%warm fixture :buffer warmup attempts deadline consed-start max-consed-bytes heap-limit))
               (pairs nil))
          (dolist (key '(:operations :checksum :retries :hits :misses))
            (unless (eql (getf warm-a key) (getf warm-b key))
              (error 'budget-error :reason :warmup-disagreement)))
          (dotimes (replica replicas)
            (%guard deadline consed-start max-consed-bytes heap-limit)
            (let* ((order (if (evenp (+ number replica)) :ab :ba))
                   (first-method (if (eq order :ab) :baseline :buffer))
                   (second-method (if (eq order :ab) :buffer :baseline))
                   (first (%measure fixture first-method operations attempts deadline ordinal (1+ replica) order
                                    consed-start max-consed-bytes heap-limit)))
              (setf (aref samples ordinal) first)
              (incf ordinal)
              (let ((second (%measure fixture second-method operations attempts deadline ordinal (1+ replica) order
                                      consed-start max-consed-bytes heap-limit)))
                (setf (aref samples ordinal) second)
                (incf ordinal)
                (push (if (eq order :ab) (%pair first second) (%pair second first)) pairs))
              (if (eq order :ab) (incf ab) (incf ba))))
          (setf (aref reports number)
                (list :cell number :layout (if (= (cell-width fixture) 4) :words4 :words5-extra-end)
                      :words (cell-width fixture) :profile (cell-profile fixture) :workload (cell-workload fixture)
                      :documents documents :queries (* 2 documents) :warmup (list warm-a warm-b)
                      :pairs (nreverse pairs)))))
      (unless (and (= ordinal 80) (= ab 20) (= ba 20))
        (error 'budget-error :reason :incomplete-matrix))
      (%guard deadline consed-start max-consed-bytes heap-limit)
      (let ((result
              (list :schema 1 :status :ok :spike :spk-01 :kind :paired-lettura-buffer :layout :v1
                    :environment (list :implementation (lisp-implementation-type)
                                       :version (lisp-implementation-version) :machine (machine-type)
                                       :os (software-type) :os-version (software-version)
                                       :safety 3 :speed 3 :core-speed 2
                                       :timer-units-per-second internal-time-units-per-second)
                    :functions (list :baseline \"ARCDOCDB.SPK01:LEGGI\"
                                     :buffer \"ARCDOCDB.SPK01.LETTURA-BUFFER:LEGGI\")
                    :parameters (list :documents documents :capacity capacity :operations operations
                                      :replicas replicas :warmup warmup :time-limit-seconds time-limit-seconds
                                      :memory-mib memory-mib :attempts attempts :max-documents max-documents
                                      :max-operations max-operations :max-warmup max-warmup
                                      :max-payload-bytes max-payload-bytes :max-copy-bytes max-copy-bytes
                                      :max-consed-bytes max-consed-bytes
                                      :max-time-limit-seconds max-time-limit-seconds)
                    :budgets (list :planned-payload-bytes planned-payload :planned-copy-bytes planned-copy
                                   :index-payload-bytes index-payload :heap-limit-bytes heap-limit
                                   :run-consed-start consed-start :run-consed-stop (sb-ext:get-bytes-consed)
                                   :elapsed-ticks (- (get-internal-real-time) start)
                                   :deadline-policy :cooperative-error-on-exhaustion)
                    :allocation-positive-control positive
                    :completed-cells 8 :completed-pairs 40 :completed-samples ordinal :ab-pairs ab :ba-pairs ba
                    :inclusions '(:direct-lookup :query-and-oracle-access :four-u64-verification
                                  :miss-previous-payload-verification :fixnum-checksum :status-and-retries
                                  :operation-counts :cooperative-guards :gc-inside-loop)
                    :exclusions '(:preparation :key-generation :oracle-construction :warmup :full-gc-before-sample
                                  :buffer-initialization :report :pair-comparison :positive-control)
                    :allocation-scope :process-counter-between-sample-boundaries
                    :payload-scope :array-payload-and-references-excluding-headers
                    :heap-scope :sbcl-dynamic-usage-including-runtime-and-garbage
                    :constraints '(:serial :no-writer-in-measurement :no-thread-created :no-statistical-claim)
                    :cells (coerce reports 'list) :samples (coerce samples 'list))))
        (%guard deadline consed-start max-consed-bytes heap-limit)
        result))))
")
  (:PATH
   "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/metodo-bench-lettura-buffer.md"
   :HASH-KIND "MD5" :HASH "cc3eed0ae1cb1e5f549849f9b07a7131" :CONTENTS
   "# SPK-01 — metodo preregistrato del confronto lettura buffer

> **Proposta** — confronto sperimentale Fase0; REQ-VAL-001, REQ-BEN-001.

Registrato prima di qualsiasi compilazione il 2026-10-08. Fase0, Common
Lisp/SBCL, safety 3. Proprietà esclusiva: questo metodo,
`bench-lettura-buffer.lisp` e nuovi file sotto
`out/bench-lettura-buffer-agent/`. Il checkout è esclusivamente
`/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB`.
Core, runner, tools, documenti condivisi e sorgenti degli altri agenti non
sono modificati. Nessun commit/push. L'agente compila soltanto; **non esegue
BENCH, warmup, CHECK o kernel di altri agenti**. Profilazione, integrazione e
tutte le misure seriali sono del parent.

## Ipotesi e matrice fissa

Confrontare la baseline `ARCDOCDB.SPK01:LEGGI`, che restituisce quattro campi,
stato e retry, con `ARCDOCDB.SPK01.LETTURA-BUFFER:LEGGI`, che restituisce stato
e retry e pubblica quattro u64 nel buffer privato dopo seqlock e root validati.
Una sola istanza immutabile dell'indice per cella serve entrambi i metodi.
Nessun writer durante warmup/misure. Barriere, ricontrollo root e writer
restano responsabilità dei moduli esistenti; il benchmark non li reimplementa.

| Layout v1 | Profilo | Workload | Coppie | Campioni |
| --- | --- | --- | ---: | ---: |
| words4 | fields-fixnum | hit-only | 5 | 10 |
| words4 | fields-fixnum | mixed-hit-miss | 5 | 10 |
| words4 | u64-massimi | hit-only | 5 | 10 |
| words4 | u64-massimi | mixed-hit-miss | 5 | 10 |
| words5-extra-end | fields-fixnum | hit-only | 5 | 10 |
| words5-extra-end | fields-fixnum | mixed-hit-miss | 5 | 10 |
| words5-extra-end | u64-massimi | hit-only | 5 | 10 |
| words5-extra-end | u64-massimi | mixed-hit-miss | 5 | 10 |

Totale obbligatorio: 8 celle, 40 coppie, 80 campioni. A = baseline, B = buffer.
Per cella e replica si alterna AB/BA secondo la parità di cella + replica:
20 coppie AB e 20 BA nell'intera matrice. Cinque repliche esatte; nessun filtro
di celle o interruzione con successo parziale. Le comparazioni paired
conservano numeri di campione, ordine, delta e rapporti, senza proclamare
superiorità statistica da cinque coppie.

## Dati e consumatore comune

Default: 4096 documenti, C8192, 128000 lookup effettivi per campione
(qui 128k significa 128000), 4096 lookup di warmup per metodo/cella.
Si preparano fuori misura chiavi univoche di 16 byte per documenti e miss
nuovi, due query array di lunghezza 2*documents, quattro campi indipendenti
per documento/cella, oracle u64 e status byte preallocati per cella.
Hit-only percorre due permutazioni della popolazione; mixed alterna hit e
miss (50% su ogni periodo completo), cominciando da un hit. Il miss usa
un ID distinto da ogni documento. Ordine deterministico con moltiplicatore
104729, senza RNG o generazione chiavi nel ciclo.

Le tuple sono generate prima dell'inserimento e l'oracle è costruito dalle
tuple, mai leggendo l'indice. CSN, location, length ed end-CSN hanno formule
distinte. Nel profilo estremo CSN/location/end includono 2^64-1 e valori
vicini; length include 2^24-1, il limite v1. words4 ha sempre end-CSN zero.
La location viene scomposta in segmento/offset u32 solo per inserire.
Non si usa il pattern correlato del core né il layout v2.

Due cicli compilati, generati da una macro comune, chiamano direttamente le
API tipizzate: nessun FUNCALL di lookup. Il consumatore e il controllo
dell'oracle sono la stessa espansione nei due cicli. Su hit si confrontano
esattamente quattro u64. Su miss la baseline mantiene i quattro valori del
precedente hit; la variante legge il buffer che deve mantenere quel payload.
L'oracle del miss è il payload del precedente hit. Non si copia la baseline
nel buffer per simulare l'altra API. I quattro valori restituiti dalla
baseline su miss sono ignorati: non costituiscono un payload valido.
Un retry-limit, uno stato inatteso, un retry in questo fixture immutabile,
un campo diverso o un numero di operazioni insufficiente sono errori.

Il checksum resta un fixnum non negativo di 60 bit: per ogni u64 si uniscono
parte bassa di 60 bit e parte alta di 4 bit dopo rotazione del checksum.
Nessuna estrazione del sink u64 per stamparlo durante il ciclo. Il checksum
non sostituisce il confronto integrale dei quattro campi. Sono inclusi anche
stato e retry; entrambi i metodi devono avere checksum, hit, miss e retry
uguali per ogni coppia. Nessun hash-table, cons esplicito, report, lista,
generazione di chiave o costruzione di oracle nel ciclo. Le allocazioni delle
API, compreso il boxing della baseline, sono precisamente ciò che si misura.

## Finestra, GC e contatore positivo

Preparazione, inizializzazione del buffer, warmup, full GC e report sono
fuori dalla finestra. Full GC precede ogni campione. La finestra comprende
lookup, accessi alle query/oracle, verifica, checksum, conteggi e guardie
cooperative ogni 256 operazioni. Il GC provocato dentro il ciclo è incluso.
Wall ticks da GET-INTERNAL-REAL-TIME, ns/op esatto derivato da ticks e unità
del timer, delta GET-BYTES-CONSED; tick zero o delta negativo sono errori.
Il contatore consed è di processo: nessun altro benchmark o worker deve
operare contemporaneamente. La destinazione è un simple-array u64 di
lunghezza esatta 4, privata alla cella/chiamante; questo modulo non crea thread.

Prima della preparazione/misura si esegue, fuori misura, un controllo positivo
del contatore: full GC, before, allocazione di un vector u8 di 262144 byte
pubblicato in un globale del modulo, after. Il globale resta vivo almeno fino
al delta; solo dopo after si leggono il contenuto e
SB-EXT:PRIMITIVE-OBJECT-SIZE dell'oggetto effettivo. Si riportano before,
after, delta, elementi, payload, valore letto e dimensione reale. Un delta
non positivo o più piccolo del payload è errore. Nessuna inferenza sul payload
heap di array non escaped. La dimensione reale è diagnostica fuori misura;
il tetto payload esclude header, mentre quello heap include l'uso dinamico
osservato dal runtime.

## API e budget

Package `ARCDOCDB.SPK01.BENCH-LETTURA-BUFFER`, unico export `BENCH`.

| Keyword | Default | Vincolo |
| --- | ---: | --- |
| documents | 4096 | 1..max-documents; <=7*C/8 |
| capacity | 8192 | potenza di due, 8..32768 |
| operations | 128000 | 1..max-operations |
| replicas | 5 | esattamente 5 |
| warmup | 4096 | 1..min(max-warmup,operations) |
| time-limit-seconds | 120 | reale positivo <=max-time-limit-seconds |
| memory-mib | 256 | heap dinamico, 1..1024 MiB |
| attempts | 8 | 1..8 |
| max-documents | 16384 | 1..28672 |
| max-operations | 1000000 | 1..10000000 |
| max-warmup | 65536 | 1..1000000 |
| max-payload-bytes | 33554432 | 1..268435456 |
| max-copy-bytes | 16777216 | 1..67108864 |
| max-consed-bytes | 1073741824 | 1..4294967296 |
| max-time-limit-seconds | 300 | reale positivo <=300 |

Tutti i parametri, il carico senza split e le stime di payload/copie sono
validati **prima di qualunque campione**. Payload preventivo conservativo:
otto frammenti/directory v1, chiavi e query condivise, otto oracle/status/buffer,
una tabella temporanea di tuple e vector del controllo positivo. Le copie
contate sono le chiavi inserite (8*documents*16) e i campi copiati nell'oracle
(8*2*documents*32). Nessuna manutenzione è ammessa; i contatori del core
devono restare a zero per split/rebuild/copie di manutenzione.

Scadenza unica cooperativa per l'intera BENCH, default <=120 s, hard cap 300 s,
controllata in preparazione, tra GC, warmup, campioni, report e ogni blocco
di lookup. Controlli del tetto heap tramite SB-KERNEL:DYNAMIC-USAGE e del
consed cumulativo dell'intera BENCH alle stesse guardie. Consed cumulativo
include preparazione, controllo positivo, warmup e report; il delta del
campione comprende solo la finestra dichiarata. GC/allocazioni/chiamate non
sono interrotti asincronamente: l'overshoot cooperativo può essere osservato,
ma dopo scadenza si segnala errore. Nessun budget esaurito restituisce :ok.

BENCH restituisce dati plain readable: liste di keyword/stringhe/numeri;
tipi e nomi di funzioni come stringhe, niente simboli dei package dello spike,
array, pathname o strutture nel risultato. :ok è costruito soltanto dopo
80 campioni completi, 40 confronti paired e ultima guardia. Il parent registra
anche gli errori nel proprio envelope schema1, senza promuovere prefissi
di campioni a risultati completi.

## CLI pianificato e compilazione locale

CLI parent pianificato, non eseguito da questo agente:

```sh
sbcl --noinform --disable-debugger --script spikes/SPK-01-primary-index/run.lisp --bench --variant buffer --documents 4096 --capacity 8192 --operations 128000 --replicas 5 --warmup 4096 --time-limit-seconds 120 --memory-mib 256
# harness integrato: --bench SPK-01 -- --variant buffer [stesse opzioni]
```

Prima di ogni tentativo compile si aggiunge qui il piano e si crea un nuovo
direttorio esclusivo `out/bench-lettura-buffer-agent/attempt-NNN/`. Il driver
Common Lisp registra schema1 con argv e stdin esatti, ambiente, source-before
e source-after (hash MD5 SBCL e contenuti integrali di core, modulo, metodo
e driver), stdout/stderr originali, warning/style-warning come stringhe,
tutti i valori compile-file normalizzati a keyword/stringhe e risultato.
Il compilatore/core vengono caricati con warning e style-warning fatali.
Per compilare il consumer senza eseguire codice dell'altro agente è sufficiente
un package/proclamazione dell'API buffer; non si definisce alcun kernel stub.
Si compilano e caricano core e benchmark; nessuna chiamata a BENCH o warmup.
Se il reader reale è disponibile, si compila/carica anche quel file come
dipendenza immutata, senza invocarne funzioni. La proclamazione dei valori
del reader include `&optional`, identica al kernel, per evitare incompatibilità.

Un recorder separato lancia il driver con stdin conservato, cattura i due
stream originali e il codice di uscita. Un **terzo processo SBCL senza alcun
package dello spike** rilegge dati/envelope con *read-eval*=nil, controlla che
ogni foglia sia keyword/stringa/numero, e salva la decodifica leggibile.
Anche i fallimenti restano registrati; mai sovrascrivere un tentativo.

### Piano attempt-001

Compilare strict core, reader reale ora disponibile e consumer; caricare
tutti e tre senza invocazioni. Il reader resta immutato e viene incluso nei
source-before/after. Nessun kernel stub. La proclamazione ftype coincide
con quella del reader, incluso `(values keyword fixnum &optional)`.
CLI locale previsto: `sbcl --noinform --disable-debugger --script
spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/recorder.lisp 001`.
Accettazione: zero warning/style-warning, warnings-p/failure-p :no,
FASL non nulli; dati rilette nel processo neutro. Non prova la correttezza
del kernel, la riuscita del warmup o alcuna prestazione.

Il parent ha comunicato un precedente profilo lookup-fixed-key di
47.96064 B/op e key/hash 0 B osservati: contesto esterno, non risultato di
questa matrice e non prova di allocazione zero generale.

### Esito attempt-001 e piano attempt-002

001: core e reader compilati/caricati senza warning; consumer non compilato
per EOF nella forma BENCH (binding list di deadline non chiusa). warnings-p
e failure-p del consumer :yes, output :none; zero warning/style-warning
segnalati, un errore del reader Lisp. Driver uscita 1, decoder neutro uscita 0.
Record e decodifica conservati in `out/bench-lettura-buffer-agent/attempt-001/`.
Nessuna invocazione di BENCH/warmup/CHECK/lookup.

002 preregistrato prima dell'esecuzione: chiudere la binding list della
deadline, stesso strict compile/load di core, reader reale e consumer.
Il writer dell'evidenza usa stringhe letterali comuni evitando la notazione
SBCL #A per base-string; ogni foglia resta validata e i dati sono riletti con
*read-eval*=nil nel decoder neutro. CLI identico con argomento `002`.
Accettazione invariata, senza alcuna esecuzione di benchmark o warmup.

### Esito attempt-002 e piano attempt-003

002: compilazione dei tre file senza warning/style-warning e tutti i valori
compile-file :no/:no. Il load del consumer segnala un solo style-warning
REDEFINITION-WITH-DEFMACRO: COMPILE-FILE lascia definito il generatore
globale %DEFINE-CONSUMER e il FASL lo ridefinisce. Il driver carica ciascun
FASL una sola volta. L'avviso è fatale, non soppresso. Uscita driver 1,
decoder neutro 0; stdout/stderr, condizioni e source-before/after conservati.

003 preregistrato: generatore locale MACROLET con le due espansioni nel suo
corpo comune; nessuna definizione di macro persistente nel FASL o nel package.
Strict compile/load di core, reader e consumer nel medesimo processo, stesso
driver, CLI con argomento `003`. Zero warning/style-warning anche al load,
rilettura neutra e zero invocazioni BENCH/warmup/CHECK/lookup richiesti.
")
  (:PATH
   "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/evidence.lisp"
   :HASH-KIND "MD5" :HASH "1a2c8218bce863606155fb0e6db0280c" :CONTENTS
   "(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 2) (debug 1)))
(require :sb-md5)

(defparameter *evidence-root*
  \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/\")
(defparameter *evidence-dir*
  (concatenate 'string *evidence-root* \"spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/\"))
(defparameter *evidence-sources*
  '(\"spikes/SPK-01-primary-index/core.lisp\"
    \"spikes/SPK-01-primary-index/lettura-buffer.lisp\"
    \"spikes/SPK-01-primary-index/bench-lettura-buffer.lisp\"
    \"spikes/SPK-01-primary-index/metodo-bench-lettura-buffer.md\"
    \"spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/evidence.lisp\"
    \"spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/driver.lisp\"
    \"spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/recorder.lisp\"
    \"spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/decode.lisp\"))

(defun evidence-text (path)
  (with-open-file (stream path :direction :input :external-format :utf-8)
    (with-output-to-string (out)
      (loop for char = (read-char stream nil nil) while char do (write-char char out)))))

(defun evidence-write (path datum)
  (with-open-file (stream path :direction :output :if-exists :error :if-does-not-exist :create
                          :external-format :utf-8)
    ;; Le foglie sono già validate plain; stringhe normali senza #A SBCL.
    (let ((*print-readably* nil) (*print-escape* t) (*print-pretty* t)
          (*print-circle* nil) (*package* (find-package \"CL-USER\")))
      (write datum :stream stream)
      (terpri stream))))

(defun evidence-read (path)
  (with-open-file (stream path :direction :input :external-format :utf-8)
    (let* ((*read-eval* nil) (datum (read stream nil :empty)))
      (when (or (eq datum :empty) (not (eq (read stream nil :eof) :eof)))
        (error \"Non un singolo dato: ~A\" path))
      datum)))

(defun evidence-plain (datum)
  (cond ((null datum) t)
        ((consp datum) (and (evidence-plain (car datum)) (evidence-plain (cdr datum))))
        ((or (keywordp datum) (stringp datum) (numberp datum)) t)
        (t (error \"Foglia non plain: ~S\" (type-of datum)))))

(defun evidence-snapshot ()
  (loop for relative in *evidence-sources*
        for path = (concatenate 'string *evidence-root* relative)
        collect (list :path path :hash-kind \"MD5\"
                      :hash (format nil \"~(~{~2,'0X~}~)\" (coerce (sb-md5:md5sum-file path) 'list))
                      :contents (evidence-text path))))

(defun evidence-environment ()
  (list :implementation (lisp-implementation-type) :version (lisp-implementation-version)
        :machine (machine-type) :os (software-type) :os-version (software-version)
        :timer-units-per-second internal-time-units-per-second :safety 3))
")
  (:PATH
   "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/driver.lisp"
   :HASH-KIND "MD5" :HASH "40548d9bcc8d80f27b0acbf8c2ea7886" :CONTENTS
   "(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 2) (debug 1)))
(load \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/evidence.lisp\"
      :verbose nil :print nil)

(let* ((attempt (second sb-ext:*posix-argv*))
       (target (concatenate 'string *evidence-dir* \"attempt-\" attempt \"/\"))
       (compilations nil) (conditions nil) (warnings 0) (styles 0) (status :error)
       (start (get-internal-real-time)))
  (handler-case
      (handler-bind
          ((style-warning
             (lambda (condition)
               (incf styles)
               (push (list :type (princ-to-string (type-of condition))
                           :text (princ-to-string condition)) conditions)
               (error \"Style-warning strict: ~A\" condition)))
           (warning
             (lambda (condition)
               (incf warnings)
               (push (list :type (princ-to-string (type-of condition))
                           :text (princ-to-string condition)) conditions)
               (error \"Warning strict: ~A\" condition))))
        (dolist (file '(\"core\" \"lettura-buffer\" \"bench-lettura-buffer\"))
          (let ((source (concatenate 'string *evidence-root* \"spikes/SPK-01-primary-index/\" file \".lisp\"))
                (fasl (concatenate 'string target file \".fasl\")))
            (multiple-value-bind (output warnings-p failure-p)
                (compile-file source :output-file fasl :verbose nil :print nil)
              (push (list :source source :output (if output (namestring output) :none)
                          :warnings-p (if warnings-p :yes :no) :failure-p (if failure-p :yes :no)
                          :load :not-started) compilations)
              (when (or warnings-p failure-p (null output))
                (error \"Valori compile-file strict non accettabili: ~A\" file))
              (load output :verbose nil :print nil)
              (setf (getf (first compilations) :load) :ok))))
        (setf status :ok))
    (error (condition)
      (push (list :type (princ-to-string (type-of condition))
                  :text (princ-to-string condition)) conditions)))
  (let ((result (list :schema 1 :status status :mode :strict-compile-load-only
                      :argv (copy-list sb-ext:*posix-argv*) :stdin \"\" :cwd *evidence-root*
                      :environment (evidence-environment)
                      :warnings warnings :style-warnings styles
                      :compile-values (if compilations (nreverse compilations) :none)
                      :conditions (if conditions (nreverse conditions) :none)
                      :invocations '(:bench 0 :warmup 0 :check 0 :lookups 0)
                      :elapsed-ticks (- (get-internal-real-time) start))))
    (evidence-plain result)
    (evidence-write (concatenate 'string target \"data.sexp\") result)
    (let ((*print-readably* nil) (*print-escape* t) (*print-pretty* t))
      (write result) (terpri) (finish-output))
    (sb-ext:exit :code (if (eq status :ok) 0 1))))
")
  (:PATH
   "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/recorder.lisp"
   :HASH-KIND "MD5" :HASH "8facb2158c7d116e232ff8ac580bd181" :CONTENTS
   "(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 2) (debug 1)))
(load \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/evidence.lisp\"
      :verbose nil :print nil)

(let* ((attempt (second sb-ext:*posix-argv*))
       (target (concatenate 'string *evidence-dir* \"attempt-\" attempt \"/\"))
       (driver (concatenate 'string *evidence-dir* \"driver.lisp\"))
       (decoder (concatenate 'string *evidence-dir* \"decode.lisp\"))
       (argv (list \"/opt/homebrew/bin/sbcl\" \"--noinform\" \"--disable-debugger\" \"--script\" driver attempt))
       (decode-argv (list \"/opt/homebrew/bin/sbcl\" \"--noinform\" \"--disable-debugger\" \"--script\" decoder attempt))
       (before (evidence-snapshot))
       (start (get-internal-real-time)))
  (when (probe-file target) (error \"Tentativo già presente: ~A\" target))
  (ensure-directories-exist (concatenate 'string target \"stdin.txt\"))
  (with-open-file (stream (concatenate 'string target \"stdin.txt\") :direction :output
                          :if-exists :error :if-does-not-exist :create) (write-string \"\" stream))
  (evidence-write (concatenate 'string target \"planned.sexp\")
                  (list :schema 1 :status :planned :argv argv :stdin \"\" :cwd *evidence-root*
                        :recorder-argv (copy-list sb-ext:*posix-argv*) :environment (evidence-environment)
                        :source-before before :decoder-argv decode-argv
                        :scope :strict-compile-load-only))
  (let* ((process (sb-ext:run-program (first argv) (rest argv) :search nil :wait t
                                    :directory *evidence-root* :input (concatenate 'string target \"stdin.txt\")
                                    :output (concatenate 'string target \"stdout.txt\")
                                    :error (concatenate 'string target \"stderr.txt\")
                                    :if-output-exists :error :if-error-exists :error))
         (code (sb-ext:process-exit-code process))
         (after (evidence-snapshot))
         (data-path (concatenate 'string target \"data.sexp\"))
         (data (if (probe-file data-path) (evidence-read data-path)
                   (list :schema 1 :status :error :reason :driver-no-data)))
         (record (list :schema 1 :status (if (and (= code 0) (equal before after)) :ok :error)
                       :mode :strict-compile-load-only :argv argv :stdin \"\" :cwd *evidence-root*
                       :recorder-argv (copy-list sb-ext:*posix-argv*) :recorder-stdin \"\"
                       :environment (evidence-environment) :source-before before :source-after after
                       :source-stability (if (equal before after) :stable :changed)
                       :stdout (evidence-text (concatenate 'string target \"stdout.txt\"))
                       :stderr (evidence-text (concatenate 'string target \"stderr.txt\"))
                       :exit-code code :decoded-data data :decoder-argv decode-argv
                       :elapsed-ticks (- (get-internal-real-time) start))))
    (evidence-plain record)
    (evidence-write (concatenate 'string target \"record.sexp\") record)
    (let* ((decode-before (evidence-snapshot))
           (decode-process (sb-ext:run-program
                            (first decode-argv) (rest decode-argv) :search nil :wait t
                            :directory *evidence-root* :input (concatenate 'string target \"stdin.txt\")
                            :output (concatenate 'string target \"decode-stdout.txt\")
                            :error (concatenate 'string target \"decode-stderr.txt\")
                            :if-output-exists :error :if-error-exists :error))
           (decode-code (sb-ext:process-exit-code decode-process))
           (decode-output (evidence-text (concatenate 'string target \"decode-stdout.txt\")))
           (decode-error (evidence-text (concatenate 'string target \"decode-stderr.txt\"))))
      (evidence-write (concatenate 'string target \"decode-process.sexp\")
                      (list :schema 1 :status (if (= decode-code 0) :ok :error)
                            :argv decode-argv :stdin \"\" :cwd *evidence-root* :environment (evidence-environment)
                            :source-before decode-before :source-after (evidence-snapshot)
                            :stdout decode-output :stderr decode-error :exit-code decode-code
                            :decoded-data (if (= decode-code 0)
                                              (evidence-read (concatenate 'string target \"decoded.sexp\")) :none)))
      (format t \"~S~%\" (list :schema 1 :status (getf record :status) :attempt attempt
                             :compile-exit code :decoder-exit decode-code
                             :record (concatenate 'string target \"record.sexp\")))
      (sb-ext:exit :code (if (and (= code 0) (= decode-code 0) (equal before after)) 0 1)))))
")
  (:PATH
   "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/decode.lisp"
   :HASH-KIND "MD5" :HASH "de815b400feedb09fcdc8c25c7d0158d" :CONTENTS
   "(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 2) (debug 1)))
(load \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/evidence.lisp\"
      :verbose nil :print nil)

(let* ((attempt (second sb-ext:*posix-argv*))
       (target (concatenate 'string *evidence-dir* \"attempt-\" attempt \"/\"))
       (before (evidence-snapshot))
       (record (evidence-read (concatenate 'string target \"record.sexp\")))
       (data (evidence-read (concatenate 'string target \"data.sexp\"))))
  (dolist (name '(\"ARCDOCDB.SPK01\" \"ARCDOCDB.SPK01.LETTURA-BUFFER\" \"ARCDOCDB.SPK01.BENCH-LETTURA-BUFFER\"))
    (when (find-package name) (error \"Package dello spike nel decoder: ~A\" name)))
  (evidence-plain record)
  (evidence-plain data)
  (unless (equal data (getf record :decoded-data)) (error \"Dati diversi dall'envelope\"))
  (unless (and (string= (getf record :stdout) (evidence-text (concatenate 'string target \"stdout.txt\")))
               (string= (getf record :stderr) (evidence-text (concatenate 'string target \"stderr.txt\"))))
    (error \"Stream originali diversi dall'envelope\"))
  (let* ((summary \"(:schema 1 :status :ok :mode :neutral-decode :packages :absent)\")
         (stdout (concatenate 'string summary (string #\\Newline)))
         (decoded (list :schema 1 :status :ok :mode :neutral-decode :packages :absent
                        :argv (copy-list sb-ext:*posix-argv*) :stdin \"\" :cwd *evidence-root*
                        :environment (evidence-environment) :source-before before :source-after (evidence-snapshot)
                        :stdout stdout :stderr \"\" :decoded-data data :decoded-record record)))
    (evidence-plain decoded)
    (evidence-write (concatenate 'string target \"decoded.sexp\") decoded)
    (write-string stdout)
    (finish-output)))
"))
 :SOURCE-AFTER
 ((:PATH
   "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/core.lisp"
   :HASH-KIND "MD5" :HASH "1acc82229e9ebb3b43032e70dfb7de4a" :CONTENTS
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
   "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/lettura-buffer.lisp"
   :HASH-KIND "MD5" :HASH "f5c8c3a80b3f9bb83e4eb733f7f751bc" :CONTENTS
   ";;;; SPK-01, Fase 0: lettura in buffer del layout v1, parole 4/5-extra-end.
;;;; Proprietà e metodo preregistrato: metodo-lettura-buffer.md.
;;; REQ: REQ-IDX-001 REQ-IDX-007 REQ-VAL-001
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
   "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/bench-lettura-buffer.lisp"
   :HASH-KIND "MD5" :HASH "25cad8e4e8aa2bf1d51a76e70218d742" :CONTENTS
   ";;;; Fase0, layout v1. Nessuna esecuzione al caricamento.
;;;; Preregistrazione: metodo-bench-lettura-buffer.md.
;;;; REQ: REQ-VAL-001 REQ-BEN-001
(defpackage #:arcdocdb.spk01.bench-lettura-buffer
  (:use #:cl)
  (:export #:bench))
(in-package #:arcdocdb.spk01.bench-lettura-buffer)
(declaim (optimize (safety 3) (speed 3) (debug 1)))

(deftype u64 () '(unsigned-byte 64))
(deftype octets () '(simple-array (unsigned-byte 8) (*)))
(deftype words () '(simple-array (unsigned-byte 64) (*)))
(deftype destination () '(simple-array (unsigned-byte 64) (4)))
(defconstant +u64-max+ #xffffffffffffffff)
(defconstant +checksum-mask+ #x0fffffffffffffff)
(defconstant +positive-elements+ 262144)
(defvar *consed-positive-control* nil)

;; Proclamazione della sola dipendenza; nessuna implementazione del reader.
(declaim (ftype (function (arcdocdb.spk01::indice octets destination
                          &key (:attempts integer)
                          (:after-fragment (or null function))
                          (:after-fields (or null function)))
                         (values keyword fixnum &optional))
                arcdocdb.spk01.lettura-buffer:leggi))

(define-condition budget-error (error)
  ((reason :initarg :reason :reader budget-reason))
  (:report (lambda (condition stream)
             (format stream \"BENCH lettura buffer: ~A\" (budget-reason condition)))))

(defstruct (cell (:constructor %cell))
  (number 0 :type fixnum :read-only t)
  (width 4 :type fixnum :read-only t)
  (profile :fields-fixnum :type keyword :read-only t)
  (workload :hit-only :type keyword :read-only t)
  (index (arcdocdb.spk01:make-indice) :type arcdocdb.spk01::indice :read-only t)
  (queries #() :type simple-vector :read-only t)
  (oracle (make-array 0 :element-type '(unsigned-byte 64)) :type words :read-only t)
  (expected (make-array 0 :element-type '(unsigned-byte 8)) :type octets :read-only t)
  ;; Privato a questa cella e al singolo chiamante; mai condiviso fra worker.
  (output (make-array 4 :element-type '(unsigned-byte 64))
          :type destination :read-only t))

(declaim (ftype (function (t integer integer keyword) integer) %bounded))
(defun %bounded (value low high reason)
  (unless (and (integerp value) (<= low value high))
    (error 'budget-error :reason reason))
  value)

(declaim (ftype (function (fixnum integer integer integer) null) %guard))
(defun %guard (deadline consed-start consed-limit heap-limit)
  (declare (type fixnum deadline)
           (type integer consed-start consed-limit heap-limit))
  (when (>= (get-internal-real-time) deadline)
    (error 'budget-error :reason :deadline))
  (let ((used (- (sb-ext:get-bytes-consed) consed-start)))
    (when (or (minusp used) (> used consed-limit))
      (error 'budget-error :reason :consed)))
  (when (> (sb-kernel:dynamic-usage) heap-limit)
    (error 'budget-error :reason :dynamic-heap))
  nil)

(declaim (inline %fold %verify-and-fold))
(declaim (ftype (function (fixnum u64) fixnum) %fold))
(defun %fold (checksum value)
  (declare (type fixnum checksum) (type u64 value))
  ;; La rotazione resta sotto 2^61; entrambe le parti dell'u64 sono fixnum.
  (logxor (logand +checksum-mask+ (ash checksum 1)) (ash checksum -59)
          (logand +checksum-mask+ value) (ash value -60)))

(declaim (ftype (function (keyword fixnum (unsigned-byte 8) words fixnum
                           u64 u64 u64 u64 fixnum) fixnum) %verify-and-fold))
(defun %verify-and-fold (status retry expected oracle offset csn location length end checksum)
  (declare (type keyword status) (type fixnum retry offset checksum)
           (type (unsigned-byte 8) expected) (type words oracle)
           (type u64 csn location length end))
  (unless (and (if (= expected 1) (eq status :hit) (eq status :miss))
               (zerop retry))
    (error 'budget-error :reason :status-or-retries))
  (unless (and (= csn (aref oracle offset))
               (= location (aref oracle (+ offset 1)))
               (= length (aref oracle (+ offset 2)))
               (= end (aref oracle (+ offset 3))))
    (error 'budget-error :reason :oracle-payload))
  (logxor (%fold (%fold (%fold (%fold checksum csn) location) length) end)
          expected retry))

;; Due chiamate dirette in espansioni distinte, consumatore identico.
;; La macro alloca solo durante la compilazione; nessun cons nel ciclo.
(macrolet ((%define-consumer (name method)
  (let ((lookup
          (ecase method
            (:baseline
             '(multiple-value-bind (read-csn read-location read-length read-end state discarded)
                  (arcdocdb.spk01:leggi index key :attempts attempts)
                (declare (type u64 read-csn read-location read-end)
                         (type (unsigned-byte 24) read-length)
                         (type keyword state) (type fixnum discarded))
                (setf status state retry discarded)
                (when (eq state :hit)
                  (setf csn read-csn location read-location
                        payload-length read-length end read-end))))
            (:buffer
             '(multiple-value-bind (state discarded)
                  (arcdocdb.spk01.lettura-buffer:leggi index key output :attempts attempts)
                (declare (type keyword state) (type fixnum discarded))
                (setf status state retry discarded
                      csn (aref output 0) location (aref output 1)
                      payload-length (aref output 2) end (aref output 3)))))))
    `(progn
       (declaim (ftype (function (cell fixnum fixnum fixnum integer integer integer)
                                (values fixnum fixnum fixnum fixnum fixnum)) ,name))
       (defun ,name (fixture operations attempts deadline consed-start consed-limit heap-limit)
         (declare (type cell fixture) (type fixnum operations attempts deadline)
                  (type integer consed-start consed-limit heap-limit))
         (let* ((index (cell-index fixture)) (queries (cell-queries fixture))
                (oracle (cell-oracle fixture)) (expected (cell-expected fixture))
                ,@(when (eq method :buffer) '((output (cell-output fixture))))
                (query-count (length queries))
                (cursor 0) (offset 0) (completed 0) (checksum 0) (retries 0)
                (hits 0) (misses 0) (csn 0) (location 0) (payload-length 0) (end 0))
           (declare (type arcdocdb.spk01::indice index)
                    (type simple-vector queries) (type words oracle) (type octets expected)
                    ,@(when (eq method :buffer) '((type destination output)))
                    (type fixnum query-count cursor offset completed checksum retries hits misses)
                    (type u64 csn location payload-length end))
           (dotimes (step operations)
             (declare (type fixnum step))
             (when (zerop (logand step 255))
               (%guard deadline consed-start consed-limit heap-limit))
             (let ((key (the octets (aref queries cursor))) (status :miss) (retry 0))
               (declare (type octets key) (type keyword status) (type fixnum retry))
               ,lookup
               (setf checksum
                     (%verify-and-fold status retry (aref expected cursor) oracle offset
                                       csn location payload-length end checksum))
               (incf retries retry)
               (if (eq status :hit) (incf hits) (incf misses))
               (incf completed)
               (incf cursor)
               (incf offset 4)
               (when (= cursor query-count) (setf cursor 0 offset 0))))
           (%guard deadline consed-start consed-limit heap-limit)
           (unless (= completed operations (+ hits misses))
             (error 'budget-error :reason :incomplete-operations))
           (values completed checksum retries hits misses)))))))

(%define-consumer %baseline-loop :baseline)
(%define-consumer %buffer-loop :buffer))

(declaim (ftype (function (destination) null) %reset-output))
(defun %reset-output (output)
  (declare (type destination output))
  (setf (aref output 0) 0 (aref output 1) 0 (aref output 2) 0 (aref output 3) 0)
  nil)

(declaim (ftype (function (keyword fixnum fixnum fixnum words) null) %prepare-tuple))
(defun %prepare-tuple (profile width id documents tuples)
  (declare (type keyword profile) (type fixnum width id documents) (type words tuples))
  (let ((offset (* 4 id)))
    (declare (type fixnum offset))
    (ecase profile
      (:fields-fixnum
       (setf (aref tuples offset) (+ 11 (* 3 id))
             (aref tuples (+ offset 1)) (+ 101 (* 5 id))
             (aref tuples (+ offset 2)) (1+ (mod (+ 23 (* 17 id)) 65536))
             (aref tuples (+ offset 3)) (if (= width 5) (+ 251 (* 7 id)) 0)))
      (:u64-massimi
       (setf (aref tuples offset) (- +u64-max+ id)
             (aref tuples (+ offset 1)) (- +u64-max+ (mod (+ id (1- documents)) documents))
             (aref tuples (+ offset 2)) (- #xffffff (mod (+ id 3) documents))
             (aref tuples (+ offset 3))
             (if (= width 5) (- +u64-max+ (mod (+ id 2) documents)) 0)))))
  nil)

(declaim (ftype (function (fixnum fixnum fixnum keyword keyword simple-vector
                          simple-vector fixnum integer integer integer) cell) %prepare-cell))
(defun %prepare-cell (number documents capacity profile workload keys queries
                      deadline consed-start consed-limit heap-limit)
  (declare (type fixnum number documents capacity deadline)
           (type keyword profile workload) (type simple-vector keys queries)
           (type integer consed-start consed-limit heap-limit))
  (let* ((width (if (< number 4) 4 5))
         (index (arcdocdb.spk01:make-indice :capacity capacity :words width :max-depth 0
                                         :memory-mib (ceiling heap-limit 1048576)))
         (tuples (make-array (* 4 documents) :element-type '(unsigned-byte 64)))
         (oracle (make-array (* 8 documents) :element-type '(unsigned-byte 64)))
         (expected (make-array (* 2 documents) :element-type '(unsigned-byte 8)))
         (output (make-array 4 :element-type '(unsigned-byte 64) :initial-element 0)))
    (declare (type arcdocdb.spk01::indice index) (type words tuples oracle)
             (type octets expected) (type destination output) (type fixnum width))
    (dotimes (id documents)
      (declare (type fixnum id))
      (when (zerop (logand id 127))
        (%guard deadline consed-start consed-limit heap-limit))
      (%prepare-tuple profile width id documents tuples)
      (let* ((offset (* 4 id)) (location (aref tuples (+ offset 1))))
        (declare (type fixnum offset) (type u64 location))
        (unless (arcdocdb.spk01:inserisci
                 index (the octets (aref keys id)) (aref tuples offset)
                 (ldb (byte 32 32) location) (ldb (byte 32 0) location)
                 (aref tuples (+ offset 2)) :end-csn (aref tuples (+ offset 3)))
          (error 'budget-error :reason :non-new-document))))
    (dotimes (query (* 2 documents))
      (declare (type fixnum query))
      (when (zerop (logand query 255))
        (%guard deadline consed-start consed-limit heap-limit))
      (let* ((hit (or (eq workload :hit-only) (evenp query)))
             (id (mod (* (if (eq workload :hit-only) query (ash query -1)) 104729) documents))
             (target (* 4 query)) (source (* 4 id)))
        (declare (type fixnum id target source))
        (setf (aref expected query) (if hit 1 0))
        (dotimes (field 4)
          (setf (aref oracle (+ target field))
                (if hit (aref tuples (+ source field))
                    (aref oracle (+ (- target 4) field)))))))
    ;; Interroghiamo contatori O(1), senza costruire statistiche/hash-table.
    (unless (and (= documents (arcdocdb.spk01::indice-documenti index))
                 (= 1 (arcdocdb.spk01::indice-frammenti index))
                 (zerop (arcdocdb.spk01::indice-split index))
                 (zerop (arcdocdb.spk01::indice-rebuild index))
                 (zerop (arcdocdb.spk01::indice-chiavi-byte-copiati index)))
      (error 'budget-error :reason :unexpected-maintenance))
    (%cell :number number :width width :profile profile :workload workload :index index
           :queries queries :oracle oracle :expected expected :output output)))

(declaim (ftype (function (fixnum fixnum integer integer integer)
                         (values simple-vector simple-vector simple-vector)) %prepare-queries))
(defun %prepare-queries (documents deadline consed-start consed-limit heap-limit)
  (declare (type fixnum documents deadline) (type integer consed-start consed-limit heap-limit))
  (let ((keys (make-array (* 2 documents)))
        (hit-queries (make-array (* 2 documents)))
        (mixed-queries (make-array (* 2 documents))))
    (declare (type simple-vector keys hit-queries mixed-queries))
    (dotimes (id (* 2 documents))
      (when (zerop (logand id 127))
        (%guard deadline consed-start consed-limit heap-limit))
      (let ((key (make-array 16 :element-type '(unsigned-byte 8))))
        (arcdocdb.spk01:scrivi-chiave key id)
        (setf (aref keys id) key)))
    (dotimes (query (* 2 documents))
      (when (zerop (logand query 255))
        (%guard deadline consed-start consed-limit heap-limit))
      (setf (aref hit-queries query) (aref keys (mod (* query 104729) documents))
            (aref mixed-queries query)
            (aref keys (+ (if (oddp query) documents 0)
                          (mod (* (ash query -1) 104729) documents)))))
    (values keys hit-queries mixed-queries)))

(declaim (ftype (function (fixnum integer integer integer) list) %positive-control))
(defun %positive-control (deadline consed-start consed-limit heap-limit)
  (declare (type fixnum deadline) (type integer consed-start consed-limit heap-limit))
  (setf *consed-positive-control* nil)
  (sb-ext:gc :full t)
  (%guard deadline consed-start consed-limit heap-limit)
  (let ((before (sb-ext:get-bytes-consed)))
    (setf *consed-positive-control*
          (make-array +positive-elements+ :element-type '(unsigned-byte 8) :initial-element 172))
    (let* ((after (sb-ext:get-bytes-consed)) (delta (- after before))
           ;; Tutte queste letture seguono AFTER; l'oggetto è pubblicato nel globale.
           (object (the octets *consed-positive-control*))
           (value (aref object (1- (length object))))
           (size (sb-ext:primitive-object-size object)))
      (unless (and (>= delta +positive-elements+) (= value 172)
                   (>= size +positive-elements+))
        (error 'budget-error :reason :consed-positive-control))
      (%guard deadline consed-start consed-limit heap-limit)
      (list :status :ok :before before :after after :bytes-consed delta
            :elements (length object) :payload-bytes +positive-elements+
            :observed-value value :primitive-object-size size
            :object-type \"(SIMPLE-ARRAY (UNSIGNED-BYTE 8) (*))\"
            :escaped-global \"ARCDOCDB.SPK01.BENCH-LETTURA-BUFFER::*CONSED-POSITIVE-CONTROL*\"
            :retention :through-delta-and-size))))

(declaim (ftype (function (cell keyword fixnum fixnum fixnum integer integer integer)
                         (values fixnum fixnum fixnum fixnum fixnum)) %consume))
(defun %consume (fixture method operations attempts deadline consed-start consed-limit heap-limit)
  (declare (type cell fixture) (type keyword method)
           (type fixnum operations attempts deadline) (type integer consed-start consed-limit heap-limit))
  (ecase method
    (:baseline (%baseline-loop fixture operations attempts deadline consed-start consed-limit heap-limit))
    (:buffer (%buffer-loop fixture operations attempts deadline consed-start consed-limit heap-limit))))

(declaim (ftype (function (cell keyword fixnum fixnum fixnum integer integer integer) list) %warm))
(defun %warm (fixture method operations attempts deadline consed-start consed-limit heap-limit)
  (declare (type cell fixture) (type keyword method) (type fixnum operations attempts deadline)
           (type integer consed-start consed-limit heap-limit))
  (%reset-output (cell-output fixture))
  (multiple-value-bind (completed checksum retries hits misses)
      (%consume fixture method operations attempts deadline consed-start consed-limit heap-limit)
    (list :method method :operations completed :checksum checksum :retries retries :hits hits :misses misses)))

(declaim (ftype (function (cell keyword fixnum fixnum fixnum fixnum fixnum keyword
                          integer integer integer) list) %measure))
(defun %measure (fixture method operations attempts deadline ordinal replica order
                 consed-start consed-limit heap-limit)
  (declare (type cell fixture) (type keyword method order)
           (type fixnum operations attempts deadline ordinal replica)
           (type integer consed-start consed-limit heap-limit))
  (%reset-output (cell-output fixture))
  (%guard deadline consed-start consed-limit heap-limit)
  (sb-ext:gc :full t)
  (%guard deadline consed-start consed-limit heap-limit)
  (let* ((heap-before (sb-kernel:dynamic-usage))
         (before (sb-ext:get-bytes-consed)) (start (get-internal-real-time)))
    (multiple-value-bind (completed checksum retries hits misses)
        (%consume fixture method operations attempts deadline consed-start consed-limit heap-limit)
      (let* ((stop (get-internal-real-time)) (after (sb-ext:get-bytes-consed))
             (ticks (- stop start)) (bytes (- after before)))
        (when (or (<= ticks 0) (minusp bytes))
          (error 'budget-error :reason :invalid-measurement-counter))
        (%guard deadline consed-start consed-limit heap-limit)
        (list :sample ordinal :cell (cell-number fixture) :replica replica :order order :method method
              :operations completed :ticks ticks :timer-units-per-second internal-time-units-per-second
              :ns-per-operation (/ (* ticks 1000000000) (* internal-time-units-per-second completed))
              :bytes-consed-before before :bytes-consed-after after :bytes-consed bytes
              :bytes-consed-per-operation (/ bytes completed)
              :heap-before heap-before :heap-after (sb-kernel:dynamic-usage)
              :checksum checksum :retries retries :hits hits :misses misses)))))

(declaim (ftype (function (list list) list) %pair))
(defun %pair (baseline buffer)
  (dolist (key '(:cell :replica :order :operations :checksum :retries :hits :misses))
    (unless (eql (getf baseline key) (getf buffer key))
      (error 'budget-error :reason :paired-disagreement)))
  (list :replica (getf baseline :replica) :order (getf baseline :order)
        :baseline-sample (getf baseline :sample) :buffer-sample (getf buffer :sample)
        :buffer-over-baseline-ticks (/ (getf buffer :ticks) (getf baseline :ticks))
        :buffer-minus-baseline-ticks (- (getf buffer :ticks) (getf baseline :ticks))
        :buffer-minus-baseline-bytes (- (getf buffer :bytes-consed) (getf baseline :bytes-consed))
        :checksum (getf baseline :checksum) :retries (getf baseline :retries)))

(declaim (ftype (function (&key (:documents integer) (:capacity integer) (:operations integer)
                          (:replicas integer) (:warmup integer) (:time-limit-seconds real)
                          (:memory-mib integer) (:attempts integer) (:max-documents integer)
                          (:max-operations integer) (:max-warmup integer) (:max-payload-bytes integer)
                          (:max-copy-bytes integer) (:max-consed-bytes integer)
                          (:max-time-limit-seconds real)) list) bench))
(defun bench (&key (documents 4096) (capacity 8192) (operations 128000) (replicas 5)
                   (warmup 4096) (time-limit-seconds 120) (memory-mib 256) (attempts 8)
                   (max-documents 16384) (max-operations 1000000) (max-warmup 65536)
                   (max-payload-bytes 33554432) (max-copy-bytes 16777216)
                   (max-consed-bytes 1073741824) (max-time-limit-seconds 300))
  \"Matrice paired completa o errore; nessun risultato parziale.\"
  (%bounded max-documents 1 28672 :max-documents)
  (%bounded max-operations 1 10000000 :max-operations)
  (%bounded max-warmup 1 1000000 :max-warmup)
  (%bounded max-payload-bytes 1 268435456 :max-payload-bytes)
  (%bounded max-copy-bytes 1 67108864 :max-copy-bytes)
  (%bounded max-consed-bytes 1 4294967296 :max-consed-bytes)
  (%bounded documents 1 max-documents :documents)
  (%bounded operations 1 max-operations :operations)
  (%bounded warmup 1 (min operations max-warmup) :warmup)
  (%bounded capacity 8 32768 :capacity)
  (%bounded replicas 5 5 :replicas-must-be-five)
  (%bounded memory-mib 1 1024 :memory-mib)
  (%bounded attempts 1 8 :attempts)
  (unless (and (= 1 (logcount capacity)) (<= documents (* 7 (floor capacity 8))))
    (error 'budget-error :reason :capacity-or-load))
  (unless (and (typep max-time-limit-seconds '(real (0) 300))
               (typep time-limit-seconds '(real (0) 300))
               (<= time-limit-seconds max-time-limit-seconds))
    (error 'budget-error :reason :time-limit-seconds))
  ;; Contratto ABI del fixture, anche su piattaforme con fixnum più piccoli.
  (unless (and (> most-positive-fixnum +checksum-mask+)
               (<= (* operations attempts) most-positive-fixnum))
    (error 'budget-error :reason :fixnum-width))
  (let* ((heap-limit (* memory-mib 1048576))
         (index-payload (+ (* 4 capacity (+ 49 57)) 64))
         ;; Chiavi 32d, tre vettori di riferimenti 48d, otto oracle 512d,
         ;; otto status 16d, tuple temporanee 32d, destinazioni 256, controllo.
         (planned-payload (+ index-payload (* documents (+ 32 48 512 16 32))
                             256 +positive-elements+))
         (planned-copy (* documents (+ (* 8 16) (* 8 2 32))))
         (start (get-internal-real-time))
         (deadline (+ start (ceiling (* time-limit-seconds internal-time-units-per-second)))))
    (declare (type fixnum start deadline))
    (when (or (> planned-payload max-payload-bytes) (> planned-payload heap-limit))
      (error 'budget-error :reason :planned-payload))
    (when (> planned-copy max-copy-bytes)
      (error 'budget-error :reason :planned-copy))
    ;; Tutti i budget sono validati prima di controllo positivo, warmup o misura.
    (sb-ext:gc :full t)
    (let* ((consed-start (sb-ext:get-bytes-consed))
           (positive (%positive-control deadline consed-start max-consed-bytes heap-limit))
           (fixtures (make-array 8)) (reports (make-array 8)) (samples (make-array 80))
           (ordinal 0) (ab 0) (ba 0))
      (declare (type simple-vector fixtures reports samples) (type fixnum ordinal ab ba))
      (multiple-value-bind (keys hit-queries mixed-queries)
          (%prepare-queries documents deadline consed-start max-consed-bytes heap-limit)
        (dotimes (number 8)
          (let ((profile (if (< (mod number 4) 2) :fields-fixnum :u64-massimi))
                (workload (if (evenp number) :hit-only :mixed-hit-miss)))
            (setf (aref fixtures number)
                  (%prepare-cell number documents capacity profile workload keys
                                 (if (evenp number) hit-queries mixed-queries)
                                 deadline consed-start max-consed-bytes heap-limit)))))
      ;; Tutta la matrice è preparata e validata prima del primo campione.
      (sb-ext:gc :full t)
      (%guard deadline consed-start max-consed-bytes heap-limit)
      (dotimes (number 8)
        (let* ((fixture (the cell (aref fixtures number)))
               (warm-a (%warm fixture :baseline warmup attempts deadline consed-start max-consed-bytes heap-limit))
               (warm-b (%warm fixture :buffer warmup attempts deadline consed-start max-consed-bytes heap-limit))
               (pairs nil))
          (dolist (key '(:operations :checksum :retries :hits :misses))
            (unless (eql (getf warm-a key) (getf warm-b key))
              (error 'budget-error :reason :warmup-disagreement)))
          (dotimes (replica replicas)
            (%guard deadline consed-start max-consed-bytes heap-limit)
            (let* ((order (if (evenp (+ number replica)) :ab :ba))
                   (first-method (if (eq order :ab) :baseline :buffer))
                   (second-method (if (eq order :ab) :buffer :baseline))
                   (first (%measure fixture first-method operations attempts deadline ordinal (1+ replica) order
                                    consed-start max-consed-bytes heap-limit)))
              (setf (aref samples ordinal) first)
              (incf ordinal)
              (let ((second (%measure fixture second-method operations attempts deadline ordinal (1+ replica) order
                                      consed-start max-consed-bytes heap-limit)))
                (setf (aref samples ordinal) second)
                (incf ordinal)
                (push (if (eq order :ab) (%pair first second) (%pair second first)) pairs))
              (if (eq order :ab) (incf ab) (incf ba))))
          (setf (aref reports number)
                (list :cell number :layout (if (= (cell-width fixture) 4) :words4 :words5-extra-end)
                      :words (cell-width fixture) :profile (cell-profile fixture) :workload (cell-workload fixture)
                      :documents documents :queries (* 2 documents) :warmup (list warm-a warm-b)
                      :pairs (nreverse pairs)))))
      (unless (and (= ordinal 80) (= ab 20) (= ba 20))
        (error 'budget-error :reason :incomplete-matrix))
      (%guard deadline consed-start max-consed-bytes heap-limit)
      (let ((result
              (list :schema 1 :status :ok :spike :spk-01 :kind :paired-lettura-buffer :layout :v1
                    :environment (list :implementation (lisp-implementation-type)
                                       :version (lisp-implementation-version) :machine (machine-type)
                                       :os (software-type) :os-version (software-version)
                                       :safety 3 :speed 3 :core-speed 2
                                       :timer-units-per-second internal-time-units-per-second)
                    :functions (list :baseline \"ARCDOCDB.SPK01:LEGGI\"
                                     :buffer \"ARCDOCDB.SPK01.LETTURA-BUFFER:LEGGI\")
                    :parameters (list :documents documents :capacity capacity :operations operations
                                      :replicas replicas :warmup warmup :time-limit-seconds time-limit-seconds
                                      :memory-mib memory-mib :attempts attempts :max-documents max-documents
                                      :max-operations max-operations :max-warmup max-warmup
                                      :max-payload-bytes max-payload-bytes :max-copy-bytes max-copy-bytes
                                      :max-consed-bytes max-consed-bytes
                                      :max-time-limit-seconds max-time-limit-seconds)
                    :budgets (list :planned-payload-bytes planned-payload :planned-copy-bytes planned-copy
                                   :index-payload-bytes index-payload :heap-limit-bytes heap-limit
                                   :run-consed-start consed-start :run-consed-stop (sb-ext:get-bytes-consed)
                                   :elapsed-ticks (- (get-internal-real-time) start)
                                   :deadline-policy :cooperative-error-on-exhaustion)
                    :allocation-positive-control positive
                    :completed-cells 8 :completed-pairs 40 :completed-samples ordinal :ab-pairs ab :ba-pairs ba
                    :inclusions '(:direct-lookup :query-and-oracle-access :four-u64-verification
                                  :miss-previous-payload-verification :fixnum-checksum :status-and-retries
                                  :operation-counts :cooperative-guards :gc-inside-loop)
                    :exclusions '(:preparation :key-generation :oracle-construction :warmup :full-gc-before-sample
                                  :buffer-initialization :report :pair-comparison :positive-control)
                    :allocation-scope :process-counter-between-sample-boundaries
                    :payload-scope :array-payload-and-references-excluding-headers
                    :heap-scope :sbcl-dynamic-usage-including-runtime-and-garbage
                    :constraints '(:serial :no-writer-in-measurement :no-thread-created :no-statistical-claim)
                    :cells (coerce reports 'list) :samples (coerce samples 'list))))
        (%guard deadline consed-start max-consed-bytes heap-limit)
        result))))
")
  (:PATH
   "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/metodo-bench-lettura-buffer.md"
   :HASH-KIND "MD5" :HASH "cc3eed0ae1cb1e5f549849f9b07a7131" :CONTENTS
   "# SPK-01 — metodo preregistrato del confronto lettura buffer

> **Proposta** — confronto sperimentale Fase0; REQ-VAL-001, REQ-BEN-001.

Registrato prima di qualsiasi compilazione il 2026-10-08. Fase0, Common
Lisp/SBCL, safety 3. Proprietà esclusiva: questo metodo,
`bench-lettura-buffer.lisp` e nuovi file sotto
`out/bench-lettura-buffer-agent/`. Il checkout è esclusivamente
`/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB`.
Core, runner, tools, documenti condivisi e sorgenti degli altri agenti non
sono modificati. Nessun commit/push. L'agente compila soltanto; **non esegue
BENCH, warmup, CHECK o kernel di altri agenti**. Profilazione, integrazione e
tutte le misure seriali sono del parent.

## Ipotesi e matrice fissa

Confrontare la baseline `ARCDOCDB.SPK01:LEGGI`, che restituisce quattro campi,
stato e retry, con `ARCDOCDB.SPK01.LETTURA-BUFFER:LEGGI`, che restituisce stato
e retry e pubblica quattro u64 nel buffer privato dopo seqlock e root validati.
Una sola istanza immutabile dell'indice per cella serve entrambi i metodi.
Nessun writer durante warmup/misure. Barriere, ricontrollo root e writer
restano responsabilità dei moduli esistenti; il benchmark non li reimplementa.

| Layout v1 | Profilo | Workload | Coppie | Campioni |
| --- | --- | --- | ---: | ---: |
| words4 | fields-fixnum | hit-only | 5 | 10 |
| words4 | fields-fixnum | mixed-hit-miss | 5 | 10 |
| words4 | u64-massimi | hit-only | 5 | 10 |
| words4 | u64-massimi | mixed-hit-miss | 5 | 10 |
| words5-extra-end | fields-fixnum | hit-only | 5 | 10 |
| words5-extra-end | fields-fixnum | mixed-hit-miss | 5 | 10 |
| words5-extra-end | u64-massimi | hit-only | 5 | 10 |
| words5-extra-end | u64-massimi | mixed-hit-miss | 5 | 10 |

Totale obbligatorio: 8 celle, 40 coppie, 80 campioni. A = baseline, B = buffer.
Per cella e replica si alterna AB/BA secondo la parità di cella + replica:
20 coppie AB e 20 BA nell'intera matrice. Cinque repliche esatte; nessun filtro
di celle o interruzione con successo parziale. Le comparazioni paired
conservano numeri di campione, ordine, delta e rapporti, senza proclamare
superiorità statistica da cinque coppie.

## Dati e consumatore comune

Default: 4096 documenti, C8192, 128000 lookup effettivi per campione
(qui 128k significa 128000), 4096 lookup di warmup per metodo/cella.
Si preparano fuori misura chiavi univoche di 16 byte per documenti e miss
nuovi, due query array di lunghezza 2*documents, quattro campi indipendenti
per documento/cella, oracle u64 e status byte preallocati per cella.
Hit-only percorre due permutazioni della popolazione; mixed alterna hit e
miss (50% su ogni periodo completo), cominciando da un hit. Il miss usa
un ID distinto da ogni documento. Ordine deterministico con moltiplicatore
104729, senza RNG o generazione chiavi nel ciclo.

Le tuple sono generate prima dell'inserimento e l'oracle è costruito dalle
tuple, mai leggendo l'indice. CSN, location, length ed end-CSN hanno formule
distinte. Nel profilo estremo CSN/location/end includono 2^64-1 e valori
vicini; length include 2^24-1, il limite v1. words4 ha sempre end-CSN zero.
La location viene scomposta in segmento/offset u32 solo per inserire.
Non si usa il pattern correlato del core né il layout v2.

Due cicli compilati, generati da una macro comune, chiamano direttamente le
API tipizzate: nessun FUNCALL di lookup. Il consumatore e il controllo
dell'oracle sono la stessa espansione nei due cicli. Su hit si confrontano
esattamente quattro u64. Su miss la baseline mantiene i quattro valori del
precedente hit; la variante legge il buffer che deve mantenere quel payload.
L'oracle del miss è il payload del precedente hit. Non si copia la baseline
nel buffer per simulare l'altra API. I quattro valori restituiti dalla
baseline su miss sono ignorati: non costituiscono un payload valido.
Un retry-limit, uno stato inatteso, un retry in questo fixture immutabile,
un campo diverso o un numero di operazioni insufficiente sono errori.

Il checksum resta un fixnum non negativo di 60 bit: per ogni u64 si uniscono
parte bassa di 60 bit e parte alta di 4 bit dopo rotazione del checksum.
Nessuna estrazione del sink u64 per stamparlo durante il ciclo. Il checksum
non sostituisce il confronto integrale dei quattro campi. Sono inclusi anche
stato e retry; entrambi i metodi devono avere checksum, hit, miss e retry
uguali per ogni coppia. Nessun hash-table, cons esplicito, report, lista,
generazione di chiave o costruzione di oracle nel ciclo. Le allocazioni delle
API, compreso il boxing della baseline, sono precisamente ciò che si misura.

## Finestra, GC e contatore positivo

Preparazione, inizializzazione del buffer, warmup, full GC e report sono
fuori dalla finestra. Full GC precede ogni campione. La finestra comprende
lookup, accessi alle query/oracle, verifica, checksum, conteggi e guardie
cooperative ogni 256 operazioni. Il GC provocato dentro il ciclo è incluso.
Wall ticks da GET-INTERNAL-REAL-TIME, ns/op esatto derivato da ticks e unità
del timer, delta GET-BYTES-CONSED; tick zero o delta negativo sono errori.
Il contatore consed è di processo: nessun altro benchmark o worker deve
operare contemporaneamente. La destinazione è un simple-array u64 di
lunghezza esatta 4, privata alla cella/chiamante; questo modulo non crea thread.

Prima della preparazione/misura si esegue, fuori misura, un controllo positivo
del contatore: full GC, before, allocazione di un vector u8 di 262144 byte
pubblicato in un globale del modulo, after. Il globale resta vivo almeno fino
al delta; solo dopo after si leggono il contenuto e
SB-EXT:PRIMITIVE-OBJECT-SIZE dell'oggetto effettivo. Si riportano before,
after, delta, elementi, payload, valore letto e dimensione reale. Un delta
non positivo o più piccolo del payload è errore. Nessuna inferenza sul payload
heap di array non escaped. La dimensione reale è diagnostica fuori misura;
il tetto payload esclude header, mentre quello heap include l'uso dinamico
osservato dal runtime.

## API e budget

Package `ARCDOCDB.SPK01.BENCH-LETTURA-BUFFER`, unico export `BENCH`.

| Keyword | Default | Vincolo |
| --- | ---: | --- |
| documents | 4096 | 1..max-documents; <=7*C/8 |
| capacity | 8192 | potenza di due, 8..32768 |
| operations | 128000 | 1..max-operations |
| replicas | 5 | esattamente 5 |
| warmup | 4096 | 1..min(max-warmup,operations) |
| time-limit-seconds | 120 | reale positivo <=max-time-limit-seconds |
| memory-mib | 256 | heap dinamico, 1..1024 MiB |
| attempts | 8 | 1..8 |
| max-documents | 16384 | 1..28672 |
| max-operations | 1000000 | 1..10000000 |
| max-warmup | 65536 | 1..1000000 |
| max-payload-bytes | 33554432 | 1..268435456 |
| max-copy-bytes | 16777216 | 1..67108864 |
| max-consed-bytes | 1073741824 | 1..4294967296 |
| max-time-limit-seconds | 300 | reale positivo <=300 |

Tutti i parametri, il carico senza split e le stime di payload/copie sono
validati **prima di qualunque campione**. Payload preventivo conservativo:
otto frammenti/directory v1, chiavi e query condivise, otto oracle/status/buffer,
una tabella temporanea di tuple e vector del controllo positivo. Le copie
contate sono le chiavi inserite (8*documents*16) e i campi copiati nell'oracle
(8*2*documents*32). Nessuna manutenzione è ammessa; i contatori del core
devono restare a zero per split/rebuild/copie di manutenzione.

Scadenza unica cooperativa per l'intera BENCH, default <=120 s, hard cap 300 s,
controllata in preparazione, tra GC, warmup, campioni, report e ogni blocco
di lookup. Controlli del tetto heap tramite SB-KERNEL:DYNAMIC-USAGE e del
consed cumulativo dell'intera BENCH alle stesse guardie. Consed cumulativo
include preparazione, controllo positivo, warmup e report; il delta del
campione comprende solo la finestra dichiarata. GC/allocazioni/chiamate non
sono interrotti asincronamente: l'overshoot cooperativo può essere osservato,
ma dopo scadenza si segnala errore. Nessun budget esaurito restituisce :ok.

BENCH restituisce dati plain readable: liste di keyword/stringhe/numeri;
tipi e nomi di funzioni come stringhe, niente simboli dei package dello spike,
array, pathname o strutture nel risultato. :ok è costruito soltanto dopo
80 campioni completi, 40 confronti paired e ultima guardia. Il parent registra
anche gli errori nel proprio envelope schema1, senza promuovere prefissi
di campioni a risultati completi.

## CLI pianificato e compilazione locale

CLI parent pianificato, non eseguito da questo agente:

```sh
sbcl --noinform --disable-debugger --script spikes/SPK-01-primary-index/run.lisp --bench --variant buffer --documents 4096 --capacity 8192 --operations 128000 --replicas 5 --warmup 4096 --time-limit-seconds 120 --memory-mib 256
# harness integrato: --bench SPK-01 -- --variant buffer [stesse opzioni]
```

Prima di ogni tentativo compile si aggiunge qui il piano e si crea un nuovo
direttorio esclusivo `out/bench-lettura-buffer-agent/attempt-NNN/`. Il driver
Common Lisp registra schema1 con argv e stdin esatti, ambiente, source-before
e source-after (hash MD5 SBCL e contenuti integrali di core, modulo, metodo
e driver), stdout/stderr originali, warning/style-warning come stringhe,
tutti i valori compile-file normalizzati a keyword/stringhe e risultato.
Il compilatore/core vengono caricati con warning e style-warning fatali.
Per compilare il consumer senza eseguire codice dell'altro agente è sufficiente
un package/proclamazione dell'API buffer; non si definisce alcun kernel stub.
Si compilano e caricano core e benchmark; nessuna chiamata a BENCH o warmup.
Se il reader reale è disponibile, si compila/carica anche quel file come
dipendenza immutata, senza invocarne funzioni. La proclamazione dei valori
del reader include `&optional`, identica al kernel, per evitare incompatibilità.

Un recorder separato lancia il driver con stdin conservato, cattura i due
stream originali e il codice di uscita. Un **terzo processo SBCL senza alcun
package dello spike** rilegge dati/envelope con *read-eval*=nil, controlla che
ogni foglia sia keyword/stringa/numero, e salva la decodifica leggibile.
Anche i fallimenti restano registrati; mai sovrascrivere un tentativo.

### Piano attempt-001

Compilare strict core, reader reale ora disponibile e consumer; caricare
tutti e tre senza invocazioni. Il reader resta immutato e viene incluso nei
source-before/after. Nessun kernel stub. La proclamazione ftype coincide
con quella del reader, incluso `(values keyword fixnum &optional)`.
CLI locale previsto: `sbcl --noinform --disable-debugger --script
spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/recorder.lisp 001`.
Accettazione: zero warning/style-warning, warnings-p/failure-p :no,
FASL non nulli; dati rilette nel processo neutro. Non prova la correttezza
del kernel, la riuscita del warmup o alcuna prestazione.

Il parent ha comunicato un precedente profilo lookup-fixed-key di
47.96064 B/op e key/hash 0 B osservati: contesto esterno, non risultato di
questa matrice e non prova di allocazione zero generale.

### Esito attempt-001 e piano attempt-002

001: core e reader compilati/caricati senza warning; consumer non compilato
per EOF nella forma BENCH (binding list di deadline non chiusa). warnings-p
e failure-p del consumer :yes, output :none; zero warning/style-warning
segnalati, un errore del reader Lisp. Driver uscita 1, decoder neutro uscita 0.
Record e decodifica conservati in `out/bench-lettura-buffer-agent/attempt-001/`.
Nessuna invocazione di BENCH/warmup/CHECK/lookup.

002 preregistrato prima dell'esecuzione: chiudere la binding list della
deadline, stesso strict compile/load di core, reader reale e consumer.
Il writer dell'evidenza usa stringhe letterali comuni evitando la notazione
SBCL #A per base-string; ogni foglia resta validata e i dati sono riletti con
*read-eval*=nil nel decoder neutro. CLI identico con argomento `002`.
Accettazione invariata, senza alcuna esecuzione di benchmark o warmup.

### Esito attempt-002 e piano attempt-003

002: compilazione dei tre file senza warning/style-warning e tutti i valori
compile-file :no/:no. Il load del consumer segnala un solo style-warning
REDEFINITION-WITH-DEFMACRO: COMPILE-FILE lascia definito il generatore
globale %DEFINE-CONSUMER e il FASL lo ridefinisce. Il driver carica ciascun
FASL una sola volta. L'avviso è fatale, non soppresso. Uscita driver 1,
decoder neutro 0; stdout/stderr, condizioni e source-before/after conservati.

003 preregistrato: generatore locale MACROLET con le due espansioni nel suo
corpo comune; nessuna definizione di macro persistente nel FASL o nel package.
Strict compile/load di core, reader e consumer nel medesimo processo, stesso
driver, CLI con argomento `003`. Zero warning/style-warning anche al load,
rilettura neutra e zero invocazioni BENCH/warmup/CHECK/lookup richiesti.
")
  (:PATH
   "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/evidence.lisp"
   :HASH-KIND "MD5" :HASH "1a2c8218bce863606155fb0e6db0280c" :CONTENTS
   "(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 2) (debug 1)))
(require :sb-md5)

(defparameter *evidence-root*
  \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/\")
(defparameter *evidence-dir*
  (concatenate 'string *evidence-root* \"spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/\"))
(defparameter *evidence-sources*
  '(\"spikes/SPK-01-primary-index/core.lisp\"
    \"spikes/SPK-01-primary-index/lettura-buffer.lisp\"
    \"spikes/SPK-01-primary-index/bench-lettura-buffer.lisp\"
    \"spikes/SPK-01-primary-index/metodo-bench-lettura-buffer.md\"
    \"spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/evidence.lisp\"
    \"spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/driver.lisp\"
    \"spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/recorder.lisp\"
    \"spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/decode.lisp\"))

(defun evidence-text (path)
  (with-open-file (stream path :direction :input :external-format :utf-8)
    (with-output-to-string (out)
      (loop for char = (read-char stream nil nil) while char do (write-char char out)))))

(defun evidence-write (path datum)
  (with-open-file (stream path :direction :output :if-exists :error :if-does-not-exist :create
                          :external-format :utf-8)
    ;; Le foglie sono già validate plain; stringhe normali senza #A SBCL.
    (let ((*print-readably* nil) (*print-escape* t) (*print-pretty* t)
          (*print-circle* nil) (*package* (find-package \"CL-USER\")))
      (write datum :stream stream)
      (terpri stream))))

(defun evidence-read (path)
  (with-open-file (stream path :direction :input :external-format :utf-8)
    (let* ((*read-eval* nil) (datum (read stream nil :empty)))
      (when (or (eq datum :empty) (not (eq (read stream nil :eof) :eof)))
        (error \"Non un singolo dato: ~A\" path))
      datum)))

(defun evidence-plain (datum)
  (cond ((null datum) t)
        ((consp datum) (and (evidence-plain (car datum)) (evidence-plain (cdr datum))))
        ((or (keywordp datum) (stringp datum) (numberp datum)) t)
        (t (error \"Foglia non plain: ~S\" (type-of datum)))))

(defun evidence-snapshot ()
  (loop for relative in *evidence-sources*
        for path = (concatenate 'string *evidence-root* relative)
        collect (list :path path :hash-kind \"MD5\"
                      :hash (format nil \"~(~{~2,'0X~}~)\" (coerce (sb-md5:md5sum-file path) 'list))
                      :contents (evidence-text path))))

(defun evidence-environment ()
  (list :implementation (lisp-implementation-type) :version (lisp-implementation-version)
        :machine (machine-type) :os (software-type) :os-version (software-version)
        :timer-units-per-second internal-time-units-per-second :safety 3))
")
  (:PATH
   "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/driver.lisp"
   :HASH-KIND "MD5" :HASH "40548d9bcc8d80f27b0acbf8c2ea7886" :CONTENTS
   "(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 2) (debug 1)))
(load \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/evidence.lisp\"
      :verbose nil :print nil)

(let* ((attempt (second sb-ext:*posix-argv*))
       (target (concatenate 'string *evidence-dir* \"attempt-\" attempt \"/\"))
       (compilations nil) (conditions nil) (warnings 0) (styles 0) (status :error)
       (start (get-internal-real-time)))
  (handler-case
      (handler-bind
          ((style-warning
             (lambda (condition)
               (incf styles)
               (push (list :type (princ-to-string (type-of condition))
                           :text (princ-to-string condition)) conditions)
               (error \"Style-warning strict: ~A\" condition)))
           (warning
             (lambda (condition)
               (incf warnings)
               (push (list :type (princ-to-string (type-of condition))
                           :text (princ-to-string condition)) conditions)
               (error \"Warning strict: ~A\" condition))))
        (dolist (file '(\"core\" \"lettura-buffer\" \"bench-lettura-buffer\"))
          (let ((source (concatenate 'string *evidence-root* \"spikes/SPK-01-primary-index/\" file \".lisp\"))
                (fasl (concatenate 'string target file \".fasl\")))
            (multiple-value-bind (output warnings-p failure-p)
                (compile-file source :output-file fasl :verbose nil :print nil)
              (push (list :source source :output (if output (namestring output) :none)
                          :warnings-p (if warnings-p :yes :no) :failure-p (if failure-p :yes :no)
                          :load :not-started) compilations)
              (when (or warnings-p failure-p (null output))
                (error \"Valori compile-file strict non accettabili: ~A\" file))
              (load output :verbose nil :print nil)
              (setf (getf (first compilations) :load) :ok))))
        (setf status :ok))
    (error (condition)
      (push (list :type (princ-to-string (type-of condition))
                  :text (princ-to-string condition)) conditions)))
  (let ((result (list :schema 1 :status status :mode :strict-compile-load-only
                      :argv (copy-list sb-ext:*posix-argv*) :stdin \"\" :cwd *evidence-root*
                      :environment (evidence-environment)
                      :warnings warnings :style-warnings styles
                      :compile-values (if compilations (nreverse compilations) :none)
                      :conditions (if conditions (nreverse conditions) :none)
                      :invocations '(:bench 0 :warmup 0 :check 0 :lookups 0)
                      :elapsed-ticks (- (get-internal-real-time) start))))
    (evidence-plain result)
    (evidence-write (concatenate 'string target \"data.sexp\") result)
    (let ((*print-readably* nil) (*print-escape* t) (*print-pretty* t))
      (write result) (terpri) (finish-output))
    (sb-ext:exit :code (if (eq status :ok) 0 1))))
")
  (:PATH
   "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/recorder.lisp"
   :HASH-KIND "MD5" :HASH "8facb2158c7d116e232ff8ac580bd181" :CONTENTS
   "(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 2) (debug 1)))
(load \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/evidence.lisp\"
      :verbose nil :print nil)

(let* ((attempt (second sb-ext:*posix-argv*))
       (target (concatenate 'string *evidence-dir* \"attempt-\" attempt \"/\"))
       (driver (concatenate 'string *evidence-dir* \"driver.lisp\"))
       (decoder (concatenate 'string *evidence-dir* \"decode.lisp\"))
       (argv (list \"/opt/homebrew/bin/sbcl\" \"--noinform\" \"--disable-debugger\" \"--script\" driver attempt))
       (decode-argv (list \"/opt/homebrew/bin/sbcl\" \"--noinform\" \"--disable-debugger\" \"--script\" decoder attempt))
       (before (evidence-snapshot))
       (start (get-internal-real-time)))
  (when (probe-file target) (error \"Tentativo già presente: ~A\" target))
  (ensure-directories-exist (concatenate 'string target \"stdin.txt\"))
  (with-open-file (stream (concatenate 'string target \"stdin.txt\") :direction :output
                          :if-exists :error :if-does-not-exist :create) (write-string \"\" stream))
  (evidence-write (concatenate 'string target \"planned.sexp\")
                  (list :schema 1 :status :planned :argv argv :stdin \"\" :cwd *evidence-root*
                        :recorder-argv (copy-list sb-ext:*posix-argv*) :environment (evidence-environment)
                        :source-before before :decoder-argv decode-argv
                        :scope :strict-compile-load-only))
  (let* ((process (sb-ext:run-program (first argv) (rest argv) :search nil :wait t
                                    :directory *evidence-root* :input (concatenate 'string target \"stdin.txt\")
                                    :output (concatenate 'string target \"stdout.txt\")
                                    :error (concatenate 'string target \"stderr.txt\")
                                    :if-output-exists :error :if-error-exists :error))
         (code (sb-ext:process-exit-code process))
         (after (evidence-snapshot))
         (data-path (concatenate 'string target \"data.sexp\"))
         (data (if (probe-file data-path) (evidence-read data-path)
                   (list :schema 1 :status :error :reason :driver-no-data)))
         (record (list :schema 1 :status (if (and (= code 0) (equal before after)) :ok :error)
                       :mode :strict-compile-load-only :argv argv :stdin \"\" :cwd *evidence-root*
                       :recorder-argv (copy-list sb-ext:*posix-argv*) :recorder-stdin \"\"
                       :environment (evidence-environment) :source-before before :source-after after
                       :source-stability (if (equal before after) :stable :changed)
                       :stdout (evidence-text (concatenate 'string target \"stdout.txt\"))
                       :stderr (evidence-text (concatenate 'string target \"stderr.txt\"))
                       :exit-code code :decoded-data data :decoder-argv decode-argv
                       :elapsed-ticks (- (get-internal-real-time) start))))
    (evidence-plain record)
    (evidence-write (concatenate 'string target \"record.sexp\") record)
    (let* ((decode-before (evidence-snapshot))
           (decode-process (sb-ext:run-program
                            (first decode-argv) (rest decode-argv) :search nil :wait t
                            :directory *evidence-root* :input (concatenate 'string target \"stdin.txt\")
                            :output (concatenate 'string target \"decode-stdout.txt\")
                            :error (concatenate 'string target \"decode-stderr.txt\")
                            :if-output-exists :error :if-error-exists :error))
           (decode-code (sb-ext:process-exit-code decode-process))
           (decode-output (evidence-text (concatenate 'string target \"decode-stdout.txt\")))
           (decode-error (evidence-text (concatenate 'string target \"decode-stderr.txt\"))))
      (evidence-write (concatenate 'string target \"decode-process.sexp\")
                      (list :schema 1 :status (if (= decode-code 0) :ok :error)
                            :argv decode-argv :stdin \"\" :cwd *evidence-root* :environment (evidence-environment)
                            :source-before decode-before :source-after (evidence-snapshot)
                            :stdout decode-output :stderr decode-error :exit-code decode-code
                            :decoded-data (if (= decode-code 0)
                                              (evidence-read (concatenate 'string target \"decoded.sexp\")) :none)))
      (format t \"~S~%\" (list :schema 1 :status (getf record :status) :attempt attempt
                             :compile-exit code :decoder-exit decode-code
                             :record (concatenate 'string target \"record.sexp\")))
      (sb-ext:exit :code (if (and (= code 0) (= decode-code 0) (equal before after)) 0 1)))))
")
  (:PATH
   "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/decode.lisp"
   :HASH-KIND "MD5" :HASH "de815b400feedb09fcdc8c25c7d0158d" :CONTENTS
   "(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 2) (debug 1)))
(load \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/evidence.lisp\"
      :verbose nil :print nil)

(let* ((attempt (second sb-ext:*posix-argv*))
       (target (concatenate 'string *evidence-dir* \"attempt-\" attempt \"/\"))
       (before (evidence-snapshot))
       (record (evidence-read (concatenate 'string target \"record.sexp\")))
       (data (evidence-read (concatenate 'string target \"data.sexp\"))))
  (dolist (name '(\"ARCDOCDB.SPK01\" \"ARCDOCDB.SPK01.LETTURA-BUFFER\" \"ARCDOCDB.SPK01.BENCH-LETTURA-BUFFER\"))
    (when (find-package name) (error \"Package dello spike nel decoder: ~A\" name)))
  (evidence-plain record)
  (evidence-plain data)
  (unless (equal data (getf record :decoded-data)) (error \"Dati diversi dall'envelope\"))
  (unless (and (string= (getf record :stdout) (evidence-text (concatenate 'string target \"stdout.txt\")))
               (string= (getf record :stderr) (evidence-text (concatenate 'string target \"stderr.txt\"))))
    (error \"Stream originali diversi dall'envelope\"))
  (let* ((summary \"(:schema 1 :status :ok :mode :neutral-decode :packages :absent)\")
         (stdout (concatenate 'string summary (string #\\Newline)))
         (decoded (list :schema 1 :status :ok :mode :neutral-decode :packages :absent
                        :argv (copy-list sb-ext:*posix-argv*) :stdin \"\" :cwd *evidence-root*
                        :environment (evidence-environment) :source-before before :source-after (evidence-snapshot)
                        :stdout stdout :stderr \"\" :decoded-data data :decoded-record record)))
    (evidence-plain decoded)
    (evidence-write (concatenate 'string target \"decoded.sexp\") decoded)
    (write-string stdout)
    (finish-output)))
"))
 :SOURCE-STABILITY :STABLE :STDOUT
 "(:SCHEMA 1 :STATUS :OK :MODE :STRICT-COMPILE-LOAD-ONLY :ARGV
 (\"/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl\" \"003\") :STDIN \"\" :CWD
 \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/\" :ENVIRONMENT
 (:IMPLEMENTATION \"SBCL\" :VERSION \"2.6.9\" :MACHINE \"ARM64\" :OS \"Darwin\"
  :OS-VERSION \"27.0.0\" :TIMER-UNITS-PER-SECOND 1000000 :SAFETY 3)
 :WARNINGS 0 :STYLE-WARNINGS 0 :COMPILE-VALUES
 ((:SOURCE
   \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/core.lisp\"
   :OUTPUT
   \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/attempt-003/core.fasl\"
   :WARNINGS-P :NO :FAILURE-P :NO :LOAD :OK)
  (:SOURCE
   \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/lettura-buffer.lisp\"
   :OUTPUT
   \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/attempt-003/lettura-buffer.fasl\"
   :WARNINGS-P :NO :FAILURE-P :NO :LOAD :OK)
  (:SOURCE
   \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/bench-lettura-buffer.lisp\"
   :OUTPUT
   \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/attempt-003/bench-lettura-buffer.fasl\"
   :WARNINGS-P :NO :FAILURE-P :NO :LOAD :OK))
 :CONDITIONS :NONE :INVOCATIONS (:BENCH 0 :WARMUP 0 :CHECK 0 :LOOKUPS 0)
 :ELAPSED-TICKS 609085)
"
 :STDERR "" :EXIT-CODE 0 :DECODED-DATA
 (:SCHEMA 1 :STATUS :OK :MODE :STRICT-COMPILE-LOAD-ONLY :ARGV
  ("/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl" "003") :STDIN "" :CWD
  "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/" :ENVIRONMENT
  (:IMPLEMENTATION "SBCL" :VERSION "2.6.9" :MACHINE "ARM64" :OS "Darwin"
   :OS-VERSION "27.0.0" :TIMER-UNITS-PER-SECOND 1000000 :SAFETY 3)
  :WARNINGS 0 :STYLE-WARNINGS 0 :COMPILE-VALUES
  ((:SOURCE
    "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/core.lisp"
    :OUTPUT
    "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/attempt-003/core.fasl"
    :WARNINGS-P :NO :FAILURE-P :NO :LOAD :OK)
   (:SOURCE
    "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/lettura-buffer.lisp"
    :OUTPUT
    "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/attempt-003/lettura-buffer.fasl"
    :WARNINGS-P :NO :FAILURE-P :NO :LOAD :OK)
   (:SOURCE
    "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/bench-lettura-buffer.lisp"
    :OUTPUT
    "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/attempt-003/bench-lettura-buffer.fasl"
    :WARNINGS-P :NO :FAILURE-P :NO :LOAD :OK))
  :CONDITIONS :NONE :INVOCATIONS (:BENCH 0 :WARMUP 0 :CHECK 0 :LOOKUPS 0)
  :ELAPSED-TICKS 609085)
 :DECODER-ARGV
 ("/opt/homebrew/bin/sbcl" "--noinform" "--disable-debugger" "--script"
  "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/decode.lisp"
  "003")
 :ELAPSED-TICKS 817862)
