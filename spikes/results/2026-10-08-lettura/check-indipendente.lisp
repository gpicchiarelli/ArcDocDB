(:SCHEMA-VERSION 1 :STATUS :OK :OPERATION :COMPILE-AND-CHECK :ARGV
 ("/opt/homebrew/bin/sbcl" "--dynamic-space-size" "1024" "--noinform"
  "--no-userinit" "--no-sysinit" "--script"
  #A((146) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/check-lettura-buffer-campagna-20261008-01/child.lisp")
  #A((139) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/check-lettura-buffer-campagna-20261008-01/k1/"))
 :STDIN "" :SOURCE-BEFORE
 ((:PATH
   #A((99) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/core.lisp")
   :HASH-ALGORITHM "MD5" :HASH
   #A((32) BASE-CHAR . "1acc82229e9ebb3b43032e70dfb7de4a") :CONTENTS
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
   :HASH-ALGORITHM "MD5" :HASH
   #A((32) BASE-CHAR . "f5c8c3a80b3f9bb83e4eb733f7f751bc") :CONTENTS
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
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/check-lettura-buffer.lisp")
   :HASH-ALGORITHM "MD5" :HASH
   #A((32) BASE-CHAR . "8f8ae70dac6378e20ee38e0878f48060") :CONTENTS
   ";;;; Fase 0. Owner CHECK; vedere metodo-check-lettura-buffer.md prima di eseguire.
;;; REQ: REQ-IDX-001 REQ-IDX-007 REQ-VAL-001
(defpackage #:arcdocdb.spk01.check-lettura-buffer
  (:use #:cl)
  (:export #:check))
(in-package #:arcdocdb.spk01.check-lettura-buffer)
(declaim (optimize (safety 3) (speed 1) (debug 2)))

(defconstant +max64+ #xffffffffffffffff)
(defconstant +max24+ #xffffff)
(deftype destination () '(simple-array (unsigned-byte 64) (4)))
(define-condition check-failure (error)
  ((kind :initarg :kind :reader failure-kind)
   (detail :initarg :detail :reader failure-detail))
  (:report (lambda (c s) (format s \"CHECK ~S: ~S\" (failure-kind c) (failure-detail c)))))
(define-condition check-budget-exhausted (error) ()
  (:report (lambda (c s) (declare (ignorable c)) (write-string \"CHECK assertion budget exhausted\" s))))
(define-condition callback-fixture-error (error) ()
  (:report (lambda (c s) (declare (ignorable c)) (write-string \"Original callback fixture error\" s))))
(defstruct audit
  (remaining 200000) (assertions 0) (reads 0) (principal 0) (negative 0)
  (mutants 0) (ingress 0) (writer-rejections 0) (budget-rejections 0)
  (witnesses 0) (retry-budgets 0))
(defvar *audit* nil)

(defun demand (truth kind &rest detail)
  (unless (plusp (audit-remaining *audit*)) (error 'check-budget-exhausted))
  (decf (audit-remaining *audit*))
  (incf (audit-assertions *audit*))
  (unless truth (error 'check-failure :kind kind :detail detail))
  :checked)
(defun buffer ()
  (make-array 4 :element-type '(unsigned-byte 64)
              :initial-contents '(#xfedcba9876543210 #x8000000000000001
                                  #x1122334455667788 #xffffffffffffffff)))
(defun words-list (a) (coerce a 'list))
(defun unchanged (a before where)
  (demand (equalp a before) :destination-before-validation where (words-list a)))
(defun key (id)
  ;; Full 128-bit keys constructed here; no core generator or pattern oracle.
  (let ((a (make-array 16 :element-type '(unsigned-byte 8) :initial-element 0)))
    (cond ((zerop id) a)
          ((= id 1) (fill a 255))
          (t (dotimes (n 8 a)
               (setf (aref a n) (ldb (byte 8 (* 8 n)) id)
                     (aref a (+ n 8))
                     (ldb (byte 8 (* 8 n)) (logxor id #xd1b54a32d192ed03))))))))
(defun token (k) (coerce k 'list))
(defun tuple (words n)
  (let ((csn (mod (+ #x8000000000000001 (* n 104729)) (1+ +max64+)))
        (seg (mod (+ #xffffffff (* n 17)) #x100000000))
        (off (mod (+ #xfffffff1 (* n 43)) #x100000000))
        (len (mod (* n 65537) (1+ +max24+)))
        (end (if (= words 5) (mod (+ +max64+ (* n 97)) (1+ +max64+)) 0)))
    (list csn (+ (* seg #x100000000) off) len end)))
(defun store-tuple (i k data)
  (destructuring-bind (csn loc len end) data
    (arcdocdb.spk01:inserisci i k csn (floor loc #x100000000)
                            (mod loc #x100000000) len :end-csn end)))
(defstruct model
  (map (make-hash-table :test 'equal)) (journal nil) (puts 0) (deletes 0))
(defun model-put (i m k data)
  (multiple-value-bind (old present) (gethash (token k) (model-map m))
    (declare (ignorable old))
    (demand (eq (store-tuple i k data) (not present)) :writer-put)
    (setf (gethash (token k) (model-map m)) (copy-list data))
    (push (list :put (token k) (copy-list data)) (model-journal m))
    (incf (model-puts m))))
(defun model-delete (i m k)
  (multiple-value-bind (old present) (gethash (token k) (model-map m))
    (declare (ignorable old))
    (demand (eq (arcdocdb.spk01:elimina i k) present) :writer-delete)
    (remhash (token k) (model-map m))
    (push (list :delete (token k)) (model-journal m))
    (incf (model-deletes m))))
(defun replay-model (i m)
  (let ((replay (make-hash-table :test 'equal)))
    (dolist (event (reverse (model-journal m)))
      (ecase (first event)
        (:put (setf (gethash (second event) replay) (copy-list (third event))))
        (:delete (remhash (second event) replay))))
    (demand (= (hash-table-count replay) (hash-table-count (model-map m))) :replay-count)
    (maphash (lambda (k data)
               (demand (equal data (gethash k replay)) :replay-payload k)) (model-map m))
    (demand (= (hash-table-count replay) (arcdocdb.spk01::indice-documenti i)) :document-count)))

(defun baseline (i k d &key (attempts 8) after-fragment after-fields)
  (multiple-value-bind (csn loc len end status retries)
      (arcdocdb.spk01:leggi i k :attempts attempts
                              :after-fragment after-fragment :after-fields after-fields)
    (when (eq status :hit)
      (setf (aref d 0) csn (aref d 1) loc (aref d 2) len (aref d 3) end))
    (values status retries)))
(defun outcome (reader i k d expected retries &rest options)
  (let ((before (copy-seq d))
        (result (multiple-value-list (apply reader i k d options))))
    (demand (= (length result) 2) :return-arity (length result))
    (demand (and (keywordp (first result)) (typep (second result) 'fixnum)) :return-types)
    (demand (eq (first result) (if expected :hit :miss)) :status (first result))
    (demand (= (second result) retries) :retry-count (second result) retries)
    (if expected (demand (equal expected (words-list d)) :payload (words-list d) expected)
        (unchanged d before :miss))
    result))
(defun read-model (reader i m k)
  (let* ((expected (gethash (token k) (model-map m))) (a (buffer)) (b (buffer)))
    (let ((ra (outcome reader i k a expected 0))
          (rb (outcome #'baseline i k b expected 0)))
      (demand (and (equal ra rb) (equalp a b)) :baseline-comparison))
    (incf (audit-reads *audit*))))
(defun principal () (incf (audit-principal *audit*)))
(defun negative () (incf (audit-negative *audit*)))

(defun campaign (reader words)
  (let ((i (arcdocdb.spk01:make-indice :capacity 16 :words words :max-depth 16))
        (m (make-model)) (state 424242) (steps 0) (reads-before (audit-reads *audit*)))
    (dotimes (id 64)
      (model-put i m (key id) (tuple words (+ 1 id)))
      (read-model reader i m (key id)))
    (dotimes (block 128)
      (setf state (mod (+ (* state 1664525) 1013904223) #x100000000))
      (let ((k (key (mod (ash state -8) 64))) (n (+ 1000 (* block 3))))
        (model-put i m k (tuple words n)) (incf steps)
        (model-put i m k (tuple words (+ n 1))) (incf steps)
        (read-model reader i m k) (incf steps)
        (model-delete i m k) (incf steps)
        (read-model reader i m k) (incf steps)
        (model-put i m k (tuple words (+ n 2))) (incf steps)
        (read-model reader i m k) (incf steps)
        (read-model reader i m (key (+ 256 (mod (ash state -8) 64)))) (incf steps))
      (demand (= 64 (arcdocdb.spk01::indice-documenti i)) :campaign-population))
    (dotimes (id 384) (read-model reader i m (key id)))
    (replay-model i m)
    (demand (= steps 1024) :campaign-steps)
    (demand (= (model-puts m) 448) :campaign-puts)
    (demand (= (model-deletes m) 128) :campaign-deletes)
    (demand (= (length (model-journal m)) 576) :campaign-history)
    (demand (= (- (audit-reads *audit*) reads-before) 960) :campaign-reads)
    (demand (plusp (arcdocdb.spk01::indice-split i)) :campaign-split)
    (principal)
    (list :words words :seed 424242 :steps steps :blocks 128 :initial-puts 64
          :campaign-puts 384 :campaign-deletes 128 :campaign-reads 512
          :initial-reads 64 :final-reads 384 :read-comparisons 960
          :history-events 576 :final-live 64 :final-state state
          :splits (arcdocdb.spk01::indice-split i)
          :rebuilds (arcdocdb.spk01::indice-rebuild i))))

(defun boundaries (reader words)
  (let ((i (arcdocdb.spk01:make-indice :capacity 16 :words words)) (m (make-model))
        (values (list 0 1 most-positive-fixnum (1+ most-positive-fixnum)
                      #x8000000000000000 +max64+)))
    (loop for value in values for n from 0 do
      (let* ((loc (nth n (list 0 +max64+ most-positive-fixnum
                              (1+ most-positive-fixnum) #x8000000000000000 +max64+)))
             (data (list value loc (nth (mod n 3) (list 0 1 +max24+))
                         (if (= words 5) value 0))) (k (key n)))
        (model-put i m k data) (read-model reader i m k)
        (principal)))
    (model-delete i m (key 0)) (read-model reader i m (key 0))
    (model-delete i m (key 0)) (read-model reader i m (key 0))
    (model-put i m (key 0) (tuple words 999)) (read-model reader i m (key 0))
    (principal) (replay-model i m)
    (list :words words :records 6 :zero-key :covered :all-ff-key :covered
          :max64 +max64+ :length-max +max24+ :delete-absent :covered)))

(defun locate (i k)
  (let* ((h (arcdocdb.spk01::hash-chiave k 0))
         (f (arcdocdb.spk01::scegli-frammento (arcdocdb.spk01::indice-root i) h)))
    (multiple-value-bind (s present) (arcdocdb.spk01::cerca-writer f k h)
      (demand present :fixture-slot)
      (values f s))))
(defun rebuilds (reader words)
  (let ((i (arcdocdb.spk01:make-indice :capacity 16 :words words)) (m (make-model)))
    (dotimes (n 6) (model-put i m (key n) (tuple words n)))
    (dotimes (n 4) (model-delete i m (key n)))
    (demand (= (arcdocdb.spk01::indice-rebuild i) 0) :before-tombstone-rebuild)
    (model-put i m (key 10) (tuple words 10))
    (demand (= (arcdocdb.spk01::indice-rebuild i) 1) :tombstone-rebuild)
    (dotimes (n 12) (read-model reader i m (key n)))
    (multiple-value-bind (f s) (locate i (key 4))
      (setf (aref (arcdocdb.spk01::frammento-slots f)
                  (+ (* s words) 3)) (- arcdocdb.spk01::+soglia-seq+ 2)))
    (model-put i m (key 4) (tuple words 200))
    (demand (= (arcdocdb.spk01::indice-rebuild i) 2) :sequence-rebuild)
    (dotimes (n 12) (read-model reader i m (key n)))
    (replay-model i m) (principal)
    (list :words words :tombstone-rebuilds 1 :sequence-rebuilds 1)))

(defun collision-keys ()
  (let ((found nil) (count 0) (examined 0))
    (dotimes (n 131072)
      (let* ((k (key (+ n 2))) (h (arcdocdb.spk01::hash-chiave k 0)))
        (incf examined)
        (when (and (= 53 (logand h 127)) (= 15 (logand 15 (ash h -7))))
          (push k found) (incf count)
          (when (= count 7) (return)))))
    (demand (= count 7) :collision-search-budget count examined)
    (values (nreverse found) examined)))
(defun collision-trace (reader i k expected expected-slots)
  (let* ((d (buffer)) (before (copy-seq d)) (trace nil) (fragments 0))
    (outcome reader i k d expected 0
             :after-fragment (lambda (f)
                               (demand (arcdocdb.spk01::frammento-p f) :callback-fragment)
                               (incf fragments) (unchanged d before :collision-fragment))
             :after-fields (lambda (f s)
                             (demand (arcdocdb.spk01::frammento-p f) :callback-fields)
                             (push s trace) (unchanged d before :collision-fields)))
    (demand (= fragments 1) :callback-fragments)
    (demand (equal (reverse trace) expected-slots) :callback-trace (reverse trace) expected-slots)))
(defun collisions (reader words keys examined)
  (let ((i (arcdocdb.spk01:make-indice :capacity 16 :words words)) (m (make-model)))
    (loop for k in (subseq keys 0 6) for n from 0 do
      (model-put i m k (tuple words (+ 300 n)))
      (multiple-value-bind (f s) (locate i k)
        (declare (ignorable f))
        (demand (= s (mod (+ 15 n) 16)) :wrap-probe-placement)))
    (loop for k in keys for n from 0 do
      (let ((slots (subseq '(15 0 1 2 3 4) 0 (min 6 (1+ n))))
            (data (gethash (token k) (model-map m))))
        (collision-trace reader i k data slots)
        (collision-trace #'baseline i k data slots)
        (read-model reader i m k)))
    (model-delete i m (first keys))
    (read-model reader i m (sixth keys)) ; tombstone cannot terminate search
    (model-put i m (seventh keys) (tuple words 9999))
    (read-model reader i m (seventh keys))
    (multiple-value-bind (f s) (locate i (seventh keys))
      (declare (ignorable f)) (demand (= s 15) :wrap-tombstone-reuse))
    (replay-model i m) (principal)
    (list :words words :fingerprint 53 :probe-start 15 :occupied-slots '(15 0 1 2 3 4)
          :keys-found 7 :search-candidates examined :candidate-callbacks :verified)))

;;; Deterministic witnesses. Each invocation creates an independent index.
(defun witness (reader words mode)
  (let* ((i (arcdocdb.spk01:make-indice :capacity 8 :words words))
         (k (key 0)) (d (buffer)) (before (copy-seq d))
         (one (tuple words 1)) (two (tuple words 2)) (three (tuple words 3))
         (fc 0) (sc 0) (retired nil) (saved-odd nil)
         (expected three) (expected-status :hit) (expected-retries 1)
         (expected-fc 2) (expected-sc 2)
         (original (make-condition 'callback-fixture-error)))
    (unless (eq mode :root-miss) (store-tuple i k one))
    (case mode
      (:root-miss (setf expected-sc 1))
      (:fields-delete (setf expected nil expected-status :miss expected-sc 1))
      (:fields-odd (setf expected nil expected-status :retry-limit expected-retries 8
                         expected-fc 8 expected-sc 1))
      ((:root-churn :fields-churn)
       (setf expected nil expected-status :retry-limit expected-retries 8
             expected-fc 8 expected-sc 8))
      (:error-fragment (setf expected-fc 1 expected-sc 0))
      (:error-fields (setf expected-fc 1 expected-sc 1)))
    (labels ((fragment (f)
               (incf fc) (unchanged d before :after-fragment)
               (demand (arcdocdb.spk01::frammento-p f) :callback-fragment)
               (case mode
                 (:root-hit (when (= fc 1)
                              (store-tuple i k two)
                              (arcdocdb.spk01::manutenzione i f t)
                              (setf retired f) (store-tuple i k three)))
                 (:root-miss (when (= fc 1)
                               (arcdocdb.spk01::manutenzione i f nil)
                               (setf retired f) (store-tuple i k three)))
                 (:root-churn (arcdocdb.spk01::manutenzione i f nil))
                 (:error-fragment (error original)))
               (unchanged d before :after-fragment-writer))
             (fields (f s)
               (incf sc) (unchanged d before :after-fields)
               (demand (and (arcdocdb.spk01::frammento-p f) (typep s 'fixnum)
                            (<= 0 s) (< s 8)) :callback-slot)
               (case mode
                 (:fields-update (when (= sc 1) (store-tuple i k three)))
                 (:fields-delete (when (= sc 1) (arcdocdb.spk01:elimina i k)))
                 (:fields-odd
                  (let* ((slots (arcdocdb.spk01::frammento-slots f))
                         (position (+ (* s words) 3)) (seq (aref slots position)))
                    (setf saved-odd (list slots position seq)
                          (aref slots position) (1+ seq))))
                 (:fields-churn (store-tuple i k (tuple words (+ sc 20))))
                 (:error-fields (error original)))
               (unchanged d before :after-fields-writer)))
      (unwind-protect
           (if (member mode '(:error-fragment :error-fields))
               (let ((caught (handler-case
                                 (progn (funcall reader i k d :after-fragment #'fragment
                                                :after-fields #'fields) nil)
                               (error (c) c))))
                 (demand (eq caught original) :callback-original-error)
                 (unchanged d before :callback-error))
               (let ((result (multiple-value-list
                              (funcall reader i k d :after-fragment #'fragment
                                       :after-fields #'fields))))
                 (demand (= (length result) 2) :return-arity)
                 (demand (eq (first result) expected-status) :status (first result) expected-status)
                 (demand (typep (second result) 'fixnum) :return-types)
                 (demand (= (second result) expected-retries) :retry-count)
                 (if expected (demand (equal expected (words-list d)) :payload)
                     (unchanged d before :non-hit))))
        (when saved-odd
          (setf (aref (first saved-odd) (second saved-odd)) (third saved-odd)))))
    (demand (= fc expected-fc) :fragment-callback-count fc expected-fc)
    (demand (= sc expected-sc) :fields-callback-count sc expected-sc)
    (when retired
      (multiple-value-bind (csn loc len end status)
          (arcdocdb.spk01::sonda-reader retired k (arcdocdb.spk01::hash-chiave k 0) nil)
        (demand (eq status (if (eq mode :root-hit) :hit :miss)) :retired-status)
        (when (eq mode :root-hit)
          (demand (equal (list csn loc len end) two) :retired-payload))))
    (list :case mode :words words :status (if (member mode '(:error-fragment :error-fields))
                                             :original-error expected-status)
          :retries (if (member mode '(:error-fragment :error-fields)) :not-returned expected-retries)
          :fragment-callbacks fc :fields-callbacks sc :buffer-publication :validated)))
(defun witnesses (reader words)
  (loop for mode in '(:root-hit :root-miss :fields-update :fields-delete :fields-odd
                     :root-churn :fields-churn :error-fragment :error-fields)
        collect (let ((a (witness reader words mode)) (b (witness #'baseline words mode)))
                  (demand (equal a b) :witness-baseline mode)
                  (incf (audit-witnesses *audit*)) (principal) a)))

(defun retry-budgets (reader words)
  (let* ((i (arcdocdb.spk01:make-indice :capacity 8 :words words)) (k (key 0)))
    (store-tuple i k (tuple words 1))
    (multiple-value-bind (f s) (locate i k)
      (let* ((slots (arcdocdb.spk01::frammento-slots f)) (pos (+ (* s words) 3))
             (seq (aref slots pos)))
        (setf (aref slots pos) (1+ seq))
        (unwind-protect
             (loop for attempts from 1 to 8 do
               (dolist (r (list reader #'baseline))
                 (let* ((d (buffer)) (before (copy-seq d)) (fc 0) (sc 0)
                        (result (multiple-value-list
                                 (funcall r i k d :attempts attempts
                                          :after-fragment (lambda (fragment)
                                                            (demand (eq fragment f) :odd-fragment)
                                                            (incf fc) (unchanged d before :odd-fragment))
                                          :after-fields (lambda (fragment slot)
                                                          (declare (ignorable fragment slot)) (incf sc))))))
                   (demand (equal result (list :retry-limit attempts)) :odd-retry-limit)
                   (demand (= fc attempts) :odd-all-attempts)
                   (demand (zerop sc) :odd-no-fields)
                   (unchanged d before :odd-budget)))
               (principal) (incf (audit-retry-budgets *audit*)))
          (setf (aref slots pos) seq))))
    (list :words words :attempts '(1 2 3 4 5 6 7 8) :status :retry-limit)))

;;; Local mutant implementation. Never installed into core/kernel symbol-functions.
(defun mutant-slot (mode f s k h d after-fields)
  (let* ((slots (arcdocdb.spk01::frammento-slots f))
         (width (arcdocdb.spk01::frammento-larghezza f)) (base (* s width))
         (seq (aref slots (+ base 3))))
    (when (and (not (eq mode :no-seqlock)) (oddp seq))
      (return-from mutant-slot (values 0 0 0 0 :retry)))
    (sb-thread:barrier (:read))
    (let* ((csn (aref slots base)) (loc (aref slots (+ base 1)))
           (meta (aref slots (+ base 2))) (end (if (= width 5) (aref slots (+ base 4)) 0))
           (arena (arcdocdb.spk01::frammento-chiavi f)) (off (ldb (byte 24 0) meta))
           (match (and (= (aref (arcdocdb.spk01::frammento-ctrl f) s) (logand 127 h))
                       (= 1 (ldb (byte 8 56) meta)) (= 16 (ldb (byte 8 24) meta))
                       (<= (+ off 16) (length arena))
                       (arcdocdb.spk01::stessa-chiave-p k arena off))))
      (when (and match (eq mode :early-destination))
        (setf (aref d 0) csn (aref d 1) loc (aref d 2) (ldb (byte 24 32) meta) (aref d 3) end))
      (when after-fields (funcall after-fields f s))
      (sb-thread:barrier (:read))
      (if (and (not (eq mode :no-seqlock)) (/= seq (aref slots (+ base 3))))
          (values 0 0 0 0 :retry)
          (values csn loc (ldb (byte 24 32) meta) end (if match :hit :skip))))))
(defun mutant-probe (mode f k h d after-fields)
  (dotimes (n (arcdocdb.spk01::frammento-capacita f) (values 0 0 0 0 :miss))
    (let* ((s (arcdocdb.spk01::posizione-sonda h (arcdocdb.spk01::frammento-capacita f) n))
           (ctrl (aref (arcdocdb.spk01::frammento-ctrl f) s)))
      (when (= ctrl 255) (return-from mutant-probe (values 0 0 0 0 :miss)))
      (when (= ctrl (logand h 127))
        (multiple-value-bind (csn loc len end status) (mutant-slot mode f s k h d after-fields)
          (unless (eq status :skip)
            (return-from mutant-probe (values csn loc len end status))))))))
(defun mutant (mode)
  (lambda (i k d &key (attempts 8) after-fragment after-fields)
    (let ((h (arcdocdb.spk01::hash-chiave k 0)))
      (block reading
        (dotimes (attempt attempts (values :retry-limit attempts))
          (let* ((root (arcdocdb.spk01::indice-root i))
                 (gen (arcdocdb.spk01::radice-generazione root)))
            (sb-thread:barrier (:read))
            (let ((f (arcdocdb.spk01::scegli-frammento root h)))
              (when after-fragment (funcall after-fragment f))
              (multiple-value-bind (csn loc len end status) (mutant-probe mode f k h d after-fields)
                (sb-thread:barrier (:read))
                (let ((actual (arcdocdb.spk01::indice-root i)))
                  (when (and (not (eq status :retry))
                             (or (eq mode :no-root)
                                 (and (eq root actual) (= gen (arcdocdb.spk01::radice-generazione actual)))))
                    (when (eq status :hit)
                      (let ((data (list csn loc len end)))
                        (when (eq mode :truncate-u64)
                          (setf data (mapcar (lambda (word) (logand word most-positive-fixnum)) data)))
                        (replace d data)))
                    (return-from reading (values status attempt))))))))))))
(defun mutant-rejections (words)
  (loop for (mode test kinds) in
        '((:no-root :root-hit (:retry-count :payload))
          (:no-root :root-miss (:status))
          (:no-seqlock :fields-update (:retry-count :payload))
          (:no-seqlock :fields-delete (:status))
          (:no-seqlock :fields-odd (:status))
          (:truncate-u64 :boundary (:payload))
          (:early-destination :fields-update (:destination-before-validation))
          (:early-destination :fields-delete (:destination-before-validation)))
        collect
        (let ((c (handler-case
                     (progn
                       (if (eq test :boundary)
                           (let* ((i (arcdocdb.spk01:make-indice :capacity 8 :words words))
                                  (k (key 1)) (data (list +max64+ +max64+ +max24+
                                                         (if (= words 5) +max64+ 0))))
                             (store-tuple i k data) (outcome (mutant mode) i k (buffer) data 0))
                           (witness (mutant mode) words test))
                       nil)
                   (check-failure (failure) failure))))
          (demand (and c (member (failure-kind c) kinds)) :mutant-not-rejected mode test)
          (negative) (incf (audit-mutants *audit*))
          (list :mutation mode :witness test :rejected-by (failure-kind c)))))

(defun reject-input (reader i k d options backing)
  (let* ((watched (and (arrayp d) d))
         (before (when watched (copy-seq watched)))
         (backing-before (when backing (copy-seq backing)))
         (key-before (when (arrayp k) (copy-seq k)))
         (caught (handler-case (progn (apply reader i k d options) nil) (error (c) c))))
    (demand (and caught (or (typep caught 'type-error) (typep caught 'program-error)
                           (typep caught 'arcdocdb.spk01:limite-indice))) :input-not-rejected)
    (when watched (unchanged watched before :invalid-input))
    (when backing (unchanged backing backing-before :invalid-input-backing))
    (when key-before (demand (equalp k key-before) :invalid-key-mutated))
    (negative) (incf (audit-ingress *audit*))
    (list :rejection-type (string (type-of caught)) :destination :unchanged)))
(defun ingress (reader words)
  (let* ((i (arcdocdb.spk01:make-indice :capacity 8 :words words)) (k (key 0))
         (backing (make-array 8 :element-type '(unsigned-byte 64) :initial-element 111))
         (cases nil))
    (store-tuple i k (tuple words 1))
    (push (list :index (reject-input reader nil k (buffer) nil nil)) cases)
    (dolist (bad-key (list nil #(0 0 0 0) (make-array 15 :element-type '(unsigned-byte 8))
                          (make-array 17 :element-type '(unsigned-byte 8))
                          (make-array 16 :element-type '(unsigned-byte 8) :adjustable t)
                          (make-array 16 :element-type '(unsigned-byte 16))))
      (push (list :key (reject-input reader i bad-key (buffer) nil nil)) cases))
    (dolist (bad-dest (list nil #(1 2 3 4)
                           (make-array 3 :element-type '(unsigned-byte 64))
                           (make-array 5 :element-type '(unsigned-byte 64))
                           (make-array 4 :element-type '(unsigned-byte 32))
                           (make-array 4 :element-type '(unsigned-byte 64) :adjustable t)
                           (make-array 4 :element-type '(unsigned-byte 64) :fill-pointer 4)
                           (make-array 4 :element-type '(unsigned-byte 64)
                                       :displaced-to backing :displaced-index-offset 2)))
      (push (list :destination (reject-input reader i k bad-dest nil backing)) cases))
    (dolist (bad-attempts '(0 9 -1 1.0 \"8\"))
      (push (list :attempts (reject-input reader i k (buffer) (list :attempts bad-attempts) nil)) cases))
    (dolist (name '(:after-fragment :after-fields))
      (push (list name (reject-input reader i k (buffer) (list name 42) nil)) cases))
    (push (list :unknown-keyword (reject-input reader i k (buffer) '(:unknown 1) nil)) cases)
    (demand (= (length cases) 23) :ingress-count)
    (list :words words :cases 23 :rejections (nreverse cases))))

(defun writer-rejections (reader words)
  (let* ((i (arcdocdb.spk01:make-indice :capacity 8 :words words)) (k (key 0))
         (data (tuple words 1)) (m (make-model)) (count 0))
    (model-put i m k data)
    (dolist (bad (list (list (1+ +max64+) 0 0 0 0)
                      (list 1 #x100000000 0 0 0) (list 1 0 #x100000000 0 0)
                      (list 1 0 0 (1+ +max24+) 0) (list 1 0 0 0 (1+ +max64+))
                      (list 1 0 0 0 (if (= words 4) 1 -1))))
      (let* ((d (buffer)) (before (copy-seq d))
             (caught (handler-case
                         (progn (destructuring-bind (csn seg off len end) bad
                                  (arcdocdb.spk01:inserisci i k csn seg off len :end-csn end)) nil)
                       (error (c) c))))
        (demand (and caught (or (typep caught 'type-error)
                               (typep caught 'arcdocdb.spk01:limite-indice))) :writer-not-rejected)
        (unchanged d before :writer-error)
        (read-model reader i m k) (negative) (incf count)
        (incf (audit-writer-rejections *audit*))))
    (demand (= count 6) :writer-rejection-count)
    (list :words words :cases count :original-record :preserved)))
(defun writer-budgets (reader words)
  (let ((i (arcdocdb.spk01:make-indice :capacity 8 :words words :max-depth 0))
        (m (make-model)))
    (dotimes (id 7) (model-put i m (key id) (tuple words (+ 1 id))))
    (let* ((d (buffer)) (before (copy-seq d))
           (caught (handler-case (progn (store-tuple i (key 7) (tuple words 99)) nil)
                     (arcdocdb.spk01:limite-indice (c) c))))
      (demand (and caught (eq (arcdocdb.spk01::limite-motivo caught) :profondita-directory))
              :depth-budget-not-rejected)
      (unchanged d before :depth-budget)
      (dotimes (id 8) (read-model reader i m (key id)))
      (replay-model i m) (negative) (incf (audit-writer-rejections *audit*)))
    (let ((caught (handler-case
                      (progn (arcdocdb.spk01:make-indice :capacity 32768 :words words :memory-mib 1) nil)
                    (arcdocdb.spk01:limite-indice (c) c))))
      (demand (and caught (eq (arcdocdb.spk01::limite-motivo caught) :payload-iniziale))
              :memory-budget-not-rejected)
      (negative) (incf (audit-writer-rejections *audit*)))
    (list :words words :depth-budget :explicit-error :memory-budget :explicit-error
          :partial-success :false :preserved-records 7)))
(defun budget-rejection ()
  (let ((caught (handler-case
                    (progn (check :budget 0) nil)
                  (check-budget-exhausted (c) c))))
    (demand (typep caught 'check-budget-exhausted) :budget-not-rejected)
    (negative) (incf (audit-budget-rejections *audit*))
    (list :status :explicit-error :condition-type \"CHECK-BUDGET-EXHAUSTED\")))

(defun portable-data-p (x)
  (typecase x
    (null t) (cons (and (portable-data-p (car x)) (portable-data-p (cdr x))))
    (string t) (number t) (symbol (keywordp x)) (t nil)))
(defun check (&key (budget 200000))
  \"Finite independent-model CHECK; no BENCH, no thread/scheduler assumptions.\"
  (unless (typep budget '(integer 0 200000))
    (error 'type-error :datum budget :expected-type '(integer 0 200000)))
  (let* ((*audit* (make-audit :remaining budget))
         (package (or (find-package \"ARCDOCDB.SPK01.LETTURA-BUFFER\")
                      (error \"Kernel package absent; CHECK not attempted\")))
         (symbol (find-symbol \"LEGGI\" package))
         (reader (and symbol (fboundp symbol) (symbol-function symbol))))
    (demand reader :kernel-function)
    (multiple-value-bind (keys examined) (collision-keys)
      (let ((campaigns nil) (boundary-reports nil) (rebuild-reports nil)
            (collision-reports nil) (witness-reports nil) (retry-reports nil)
            (ingress-reports nil) (writer-reports nil) (writer-budget-reports nil)
            (mutation-reports nil))
        (dolist (words '(4 5))
          (push (campaign reader words) campaigns)
          (push (boundaries reader words) boundary-reports)
          (push (rebuilds reader words) rebuild-reports)
          (push (collisions reader words keys examined) collision-reports)
          (push (list :words words :cases (witnesses reader words)) witness-reports)
          (push (retry-budgets reader words) retry-reports)
          (push (ingress reader words) ingress-reports)
          (push (writer-rejections reader words) writer-reports)
          (push (writer-budgets reader words) writer-budget-reports)
          (push (list :words words :cases (mutant-rejections words)) mutation-reports))
        (let ((exhaustion (budget-rejection)))
          (demand (= (audit-reads *audit*) 2032) :total-model-reads)
          (demand (= (audit-principal *audit*) 54) :total-principal)
          (demand (= (audit-negative *audit*) 79) :total-negative)
          (demand (= (audit-ingress *audit*) 46) :total-ingress)
          (demand (= (audit-writer-rejections *audit*) 16) :total-writer-rejections)
          (demand (= (audit-budget-rejections *audit*) 1) :total-budget-rejections)
          (demand (= (audit-mutants *audit*) 16) :total-mutants)
          (demand (= (audit-witnesses *audit*) 18) :total-witnesses)
          (demand (= (audit-retry-budgets *audit*) 16) :total-retry-budgets)
          (let ((report
                  (list :schema-version 1 :status :ok :spike :spk-01 :phase 0
                        :layout :v1 :layouts '(:words4 :words5-extra-end)
                        :verifies-format-v2 :false :safety 3 :bench-executed :false
                        :kernel \"ARCDOCDB.SPK01.LETTURA-BUFFER:LEGGI\"
                        :baseline \"ARCDOCDB.SPK01:LEGGI\"
                        :model :independent-map-with-journal-replay
                        :principal-cases (audit-principal *audit*)
                        :negative-controls (audit-negative *audit*)
                        :negative-counts (list :ingress 46 :writer 16 :budget 1 :mutants 16)
                        :read-comparisons (audit-reads *audit*)
                        :campaigns (nreverse campaigns) :boundaries (nreverse boundary-reports)
                        :rebuilds (nreverse rebuild-reports) :collisions (nreverse collision-reports)
                        :witnesses (nreverse witness-reports) :retry-budgets (nreverse retry-reports)
                        :invalid-inputs (nreverse ingress-reports)
                        :writer-rejections (nreverse writer-reports)
                        :writer-budgets (nreverse writer-budget-reports)
                        :mutants (nreverse mutation-reports) :budget-exhaustion exhaustion
                        :budget (list :maximum budget :remaining (audit-remaining *audit*)
                                      :assertions (audit-assertions *audit*))
                        :limitations '(:finite-campaign :synchronous-interleavings
                                       :no-hardware-memory-model-proof :no-thread-stress))))
            (demand (portable-data-p report) :foreign-symbol-in-report)
            (setf (getf report :budget)
                  (list :maximum budget :remaining (audit-remaining *audit*)
                        :assertions (audit-assertions *audit*)))
            report))))))
")
  (:PATH
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/metodo-check-lettura-buffer.md")
   :HASH-ALGORITHM "MD5" :HASH
   #A((32) BASE-CHAR . "de360da1ad98cdfc061d887bbddefa9b") :CONTENTS
   "# Metodo preregistrato — CHECK lettura-buffer, Fase 0

> **Proposta** — Verifica sperimentale preregistrata prima di compile/CHECK;
> riferimenti REQ-IDX-001, REQ-IDX-007 e REQ-VAL-001. Non codice di produzione.

Owner esclusivo: `check-lettura-buffer.lisp`, questo metodo e nuovi
`out/check-lettura-buffer-*/`. Checkout: indice-lettura/ArcDocDB. Nessuna
modifica a core, kernel dell'agente A, runner, tools, documenti condivisi.
Solo Common Lisp/SBCL, safety 3; warning e style-warning sono errori.
Nessun BENCH, commit o push. La misura e l'integrazione spettano al parent.

## Ipotesi e criteri registrati prima di compile/CHECK

API sotto prova: `ARCDOCDB.SPK01.LETTURA-BUFFER:LEGGI`, destinazione privata
simple-array u64 di lunghezza esattamente 4; due valori, status keyword e
retry fixnum. Layout v1 words4 / words5-extra-end. HIT pubblica CSN,
location, length, end-CSN soltanto dopo validazione seqlock e root; MISS,
retry-limit e ogni errore conservano tutte le parole della destinazione.
Le callback seguono il core: after-fragment su ogni tentativo, after-fields
per ogni candidato ctrl con seq iniziale pari, anche se la chiave non coincide.

Il modello è una mappa EQUAL di liste dei 16 ottetti, con journal indipendente
di PUT/DELETE e replay finale. Generazione chiavi, tuple e location aritmetica
sono nel CHECK, senza usare pattern o LEGGI del core per ottenere attesi.
Ogni lettura ordinaria confronta kernel, modello e baseline; il baseline
viene adattato alla destinazione solo dopo aver restituito HIT. Gli interleaving
usano fixture nuove per ciascun reader e gli stessi callback, senza scheduler.

Per layout: 64 chiavi iniziali; LCG32 seed 424242, 128 blocchi di otto
operazioni (1024): PUT, overwrite, hit, delete, miss, reinsertion, hit,
miss assente. Assert esatti: 384 PUT, 128 DELETE, 512 letture di campagna,
64 letture iniziali e 384 finali (960 confronti kernel/modello/baseline).
Il journal contiene 576 eventi per layout, replay completo e nessun limite
esaurito trattato come successo. Split deve essere realmente avvenuto.

Casi principali separati: valori 0/1/fixnum-max/fixnum-max+1/2^63/max64,
location con segment e offset max32, length 0/1/max24, chiavi zero/all-FF;
rebuild per tombstone e soglia seqlock; sette chiavi con ctrl 53 e sonda
iniziale 15 a capacità 16, ricerca limitata a 131072 candidati. Sei slot
occupati devono risultare 15,0,1,2,3,4; il settimo è un MISS e visita sei
candidati. I callback devono avere tracce identiche al baseline.

Witness, entrambi i layout e reader: root ritirata HIT e MISS; update/delete
in after-fields; odd persistente introdotto dopo i campi; swap root su tutti
gli otto tentativi; update su tutti gli otto tentativi; errori originali nelle
due callback. Ogni callback controlla il buffer prima e dopo il writer;
HIT dopo retry verifica la tupla corrente, non quella ritirata. Retry-limit
richiede conteggio esatto e destinazione intatta. Budget 1..8 anche con odd
già presente: otto distinti casi, non una sola prova del default.

Controlli negativi separati: index/key/destination/attempts/callback invalidi,
keyword sconosciuta, rifiuto writer di u64 oltre max64 e length oltre max24,
budget del CHECK esaurito con condizione esplicita. Gli array, incluse le
regioni di backing di viste/displaced, vengono confrontati per intero.
Budget strutturali: sette record in capacità 8/profondità massima 0, ottavo
PUT rifiutato per profondità e sette record conservati; capacità 32768 con
1 MiB rifiutata per payload iniziale. Totali attesi: 54 casi principali,
79 controlli negativi (46 ingressi, 16 rifiuti writer/budget strutturali,
1 budget assert, 16 mutanti), 2032 letture contro mappa e baseline.

Mutanti locali al CHECK, senza ridefinire o modificare kernel/core: omettere
ricontrollo root (witness HIT e MISS), omettere secondo seqlock (update,
delete, odd), troncare u64 a fixnum (boundary), scrivere prima della
validazione (update e delete). Otto rifiuti richiesti per layout, con ragione
pertinente verificata; un errore generico non conta come mutante rigettato.
Non è una prova universale del modello di memoria o hardware. Nessuno
stress threaded: i witness sono interleaving sincroni con un solo writer.

CHECK ha budget finito di 200000 assert, ricerche finite, conteggi di
campagna e categorie separati. `:status :ok` viene costruito soltanto dopo
tutte le prove e gli assert finali. Output composto da liste, keyword,
stringhe e numeri; tipi, funzioni e condizioni descritti come stringhe.

## Registrazione schema1 di ogni esecuzione

Prima di ogni compile/CHECK viene scritto un piano numerato in un nuovo
out esclusivo, con argv e stdin esatti e rinvio a questo metodo. Driver SBCL
separato dall'esistente runner: snapshot source-before/after (contenuti e
MD5 dichiarato per core, kernel, CHECK, metodo e driver); stdout/stderr
originali su file, exit code e risultato decodificato nel record schema1.
Il driver promuove warning/style-warning a errori e verifica compile-file.
Errori/fallimenti restano nei record e non vengono sovrascritti. Qualsiasi
revisione del metodo precede l'esecuzione a cui si applica.

Un secondo processo SBCL, senza caricare package spike, legge risultato e
record con `*read-eval* = nil`, rigetta simboli non keyword e oggetti non
ammessi e salva i dati leggibili. Nessun CHECK prima del kernel completo;
la sua esistenza non è una dichiarazione di correttezza o prontezza.

### Esecuzione K1 preregistrata

Driver nuovi in `out/check-lettura-buffer-campagna-20261008-01/`: `record.lisp`,
`child.lisp`, `decode.lisp`. K1 compila in ordine core, kernel completo e CHECK,
carica i FASL e chiama CHECK. Avvio solo dopo conferma A di kernel congelato.
Budget: heap 1024 MiB, timeout figlio 90 secondi, registratore 105 secondi,
cleanup 5 secondi, 200000 assert. Massimo sei revisioni compilate; ciascuna
richiede un nuovo piano e conserva i fallimenti precedenti. Il timer protegge
l'esecuzione da blocchi; non viene usato per la correttezza degli interleaving.
Ogni snapshot include anche i tre driver. Source-after diverso implica errore.

Comando esatto dalla radice del checkout isolato:

```sh
/opt/homebrew/bin/sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-01-primary-index/out/check-lettura-buffer-campagna-20261008-01/record.lisp k1
```

Il registratore non carica i package spike e scrive preregistered.sexp prima
del lancio; stdout/stderr sono conservati originali, inclusa diagnostica del
compilatore su stderr. Dopo il record, un ulteriore processo senza package
spike verifica record e decoded.sexp con read-eval disabilitato.
Il registratore richiede handoff A `:ready`/`:frozen` e conserva quell'handoff
nel piano e nel record; il parent ha chiesto i commenti REQ prima di C3.
")
  (:PATH
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/check-lettura-buffer-campagna-20261008-01/record.lisp")
   :HASH-ALGORITHM "MD5" :HASH
   #A((32) BASE-CHAR . "327c0b3798e5565c8cfd087cdc1d75df") :CONTENTS
   "(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 1) (debug 2)))
(require :sb-md5)
(defparameter *check-root* #p\"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/\")
(defparameter *record-base* (make-pathname :name nil :type nil :defaults *load-truename*))
(defun file-text (p)
  (with-open-file (s p :external-format :utf-8)
    (let ((text (make-string (file-length s))))
      (subseq text 0 (read-sequence text s)))))
(defun dump (p data)
  (with-open-file (s p :direction :output :if-exists :error :if-does-not-exist :create
                      :external-format :utf-8)
    (let ((*print-readably* t) (*print-pretty* t)) (write data :stream s) (terpri s))))
(defun snapshot (p)
  (if (probe-file p)
      (list :path (namestring p) :hash-algorithm \"MD5\"
            :hash (format nil \"~(~{~2,'0X~}~)\" (coerce (sb-md5:md5sum-file p) 'list))
            :contents (file-text p))
      (list :path (namestring p) :state :absent)))
(defun snapshots ()
  (mapcar #'snapshot
          (append
           (mapcar (lambda (name) (merge-pathnames name *check-root*))
                   '(\"spikes/SPK-01-primary-index/core.lisp\"
                     \"spikes/SPK-01-primary-index/lettura-buffer.lisp\"
                     \"spikes/SPK-01-primary-index/check-lettura-buffer.lisp\"
                     \"spikes/SPK-01-primary-index/metodo-check-lettura-buffer.md\"))
           (mapcar (lambda (name) (merge-pathnames name *record-base*))
                   '(\"record.lisp\" \"child.lisp\" \"decode.lisp\")))))
(defun safe-data-p (x)
  (typecase x
    (null t) (cons (and (safe-data-p (car x)) (safe-data-p (cdr x))))
    (string t) (number t) (symbol (keywordp x)) (t nil)))
(defun decode-output (text)
  (handler-case
      (with-input-from-string (s text)
        (let ((*read-eval* nil) (end (list :end)))
          (let ((data (read s nil end)))
            (when (eq data end) (error \"No structured stdout\"))
            (unless (safe-data-p data) (error \"Foreign symbol/object in stdout\"))
            (unless (eq (read s nil end) end) (error \"Trailing stdout\"))
            data)))
    (error (c) (list :status :decode-error :condition-type (string (type-of c))
                     :condition (princ-to-string c)))))
(defun kernel-handoff ()
  (let ((data (decode-output
               (file-text (merge-pathnames
                           \"spikes/SPK-01-primary-index/out/lettura-buffer-campagna-20261008-01/kernel-pronto-B.sexp\"
                           *check-root*)))))
    (unless (and (eq (getf data :status) :ready) (eq (getf data :kernel-state) :frozen))
      (error \"Kernel not frozen/ready; compilation forbidden\"))
    data))
(defun run-bounded (argv input output errors)
  (let ((process nil) (failure nil))
    (unwind-protect
         (handler-case
             (sb-ext:with-timeout 105
               (setf process (sb-ext:run-program (first argv) (rest argv) :search nil :wait nil
                                                :input input :output output :error errors
                                                :if-output-exists :error :if-error-exists :error))
               (sb-ext:process-wait process))
           (error (c) (setf failure (list :condition-type (string (type-of c))
                                        :condition (princ-to-string c)))))
      (when (and process (sb-ext:process-alive-p process))
        (sb-ext:process-kill process 9)
        (sb-ext:with-timeout 5 (sb-ext:process-wait process))))
    (values (if process (or (sb-ext:process-exit-code process) -1) -1)
            (or failure :none))))
(let* ((name (second sb-ext:*posix-argv*)))
  (unless (and name (<= 1 (length name) 16) (every (lambda (c) (or (alphanumericp c) (char= c #\\-))) name))
    (error \"Run id required\"))
  (let* ((dir (merge-pathnames (concatenate 'string name \"/\") *record-base*))
         (stdout (merge-pathnames \"stdout.raw\" dir)) (stderr (merge-pathnames \"stderr.raw\" dir))
         (stdin (merge-pathnames \"stdin.raw\" dir)) (record (merge-pathnames \"record.sexp\" dir))
         (argv (list \"/opt/homebrew/bin/sbcl\" \"--dynamic-space-size\" \"1024\" \"--noinform\"
                     \"--no-userinit\" \"--no-sysinit\" \"--script\"
                     (namestring (merge-pathnames \"child.lisp\" *record-base*)) (namestring dir)))
         (before (snapshots)) (handoff (kernel-handoff)))
    (when (probe-file dir) (error \"Exclusive run directory already exists\"))
    (ensure-directories-exist stdin)
    (with-open-file (s stdin :direction :output :if-exists :error :if-does-not-exist :create)
      (write-string \"\" s))
    (dump (merge-pathnames \"preregistered.sexp\" dir)
          (list :schema-version 1 :status :preregistered :operation :compile-and-check
                :method \"metodo-check-lettura-buffer.md\" :cwd (namestring *check-root*)
                :argv argv :stdin \"\" :source-before before
                :kernel-handoff handoff
                :budgets (list :child-seconds 90 :parent-seconds 105 :cleanup-seconds 5
                               :assertions 200000 :campaign-steps 2048)))
    (multiple-value-bind (exit failure) (run-bounded argv stdin stdout stderr)
      (let* ((after (snapshots)) (out-text (if (probe-file stdout) (file-text stdout) \"\"))
             (err-text (if (probe-file stderr) (file-text stderr) \"\"))
             (decoded (decode-output out-text))
             (status (if (and (= exit 0) (eq failure :none) (equal before after)
                              (eq (getf decoded :status) :ok)) :ok :error)))
        (dump record (list :schema-version 1 :status status :operation :compile-and-check
                           :argv argv :stdin \"\" :source-before before :source-after after
                           :kernel-handoff handoff
                           :source-stable (if (equal before after) :true :false)
                           :stdout-file (namestring stdout) :stderr-file (namestring stderr)
                           :stdout out-text :stderr err-text :exit-code exit
                           :process-error failure :decoded decoded))
        (dump (merge-pathnames \"decoded.sexp\" dir) decoded)
        ;; Independent decoder is another clean SBCL process with no spike packages.
        (let* ((decode-argv (list \"/opt/homebrew/bin/sbcl\" \"--noinform\" \"--no-userinit\" \"--no-sysinit\"
                                  \"--script\" (namestring (merge-pathnames \"decode.lisp\" *record-base*))
                                  (namestring record) (namestring (merge-pathnames \"decoded.sexp\" dir))))
               (decode-out (merge-pathnames \"readback.raw\" dir))
               (decode-err (merge-pathnames \"readback-stderr.raw\" dir)))
          (dump (merge-pathnames \"readback-preregistered.sexp\" dir)
                (list :schema-version 1 :operation :readback :argv decode-argv :stdin \"\"))
          (multiple-value-bind (decode-exit decode-failure) (run-bounded decode-argv stdin decode-out decode-err)
            (let ((readback (decode-output (file-text decode-out))))
              (dump (merge-pathnames \"readback-record.sexp\" dir)
                    (list :schema-version 1 :operation :readback :argv decode-argv :stdin \"\"
                          :exit-code decode-exit :process-error decode-failure
                          :stdout (file-text decode-out) :stderr (file-text decode-err) :decoded readback))
              (format t \"~S~%\" (list :schema-version 1 :status status :exit-code exit
                                     :readback-status (getf readback :status) :record (namestring record)))
              (unless (and (eq status :ok) (= decode-exit 0) (eq decode-failure :none)
                           (eq (getf readback :status) :ok))
                (sb-ext:exit :code 1)))))))))
")
  (:PATH
   #A((146) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/check-lettura-buffer-campagna-20261008-01/child.lisp")
   :HASH-ALGORITHM "MD5" :HASH
   #A((32) BASE-CHAR . "deb7b86ed7480b52ab518e7a61e1f23b") :CONTENTS
   "(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 1) (debug 2)))
(let ((*read-eval* nil) (*print-readably* t) (*print-pretty* t))
  (handler-case
      (let* ((run-dir (pathname (second sb-ext:*posix-argv*)))
             (root (pathname \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/\"))
             (base (merge-pathnames \"spikes/SPK-01-primary-index/\" root)))
        (sb-ext:with-timeout 90
          (handler-bind ((warning (lambda (c) (error \"Strict compilation warning (~A): ~A\" (type-of c) c))))
            (dolist (name '(\"core\" \"lettura-buffer\" \"check-lettura-buffer\"))
              (multiple-value-bind (output warnings failure)
                  (let ((*standard-output* *error-output*))
                    (compile-file (merge-pathnames (concatenate 'string name \".lisp\") base)
                                  :output-file (merge-pathnames (concatenate 'string name \".fasl\") run-dir)
                                  :verbose nil :print nil))
                (when (or warnings failure (null output)) (error \"Strict compilation failed: ~A\" name))
                (load output :verbose nil :print nil)))
            (let* ((package (or (find-package \"ARCDOCDB.SPK01.CHECK-LETTURA-BUFFER\")
                                (error \"CHECK package missing\")))
                   (symbol (or (find-symbol \"CHECK\" package) (error \"CHECK missing\")))
                   (report (funcall (symbol-function symbol))))
              (unless (eq (getf report :status) :ok) (error \"CHECK did not finish\"))
              (write report) (terpri) (finish-output)))))
    (error (c)
      (write (list :schema-version 1 :status :error
                   :condition-type (string (type-of c)) :condition (princ-to-string c)))
      (terpri) (finish-output) (sb-ext:exit :code 1))))
")
  (:PATH
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/check-lettura-buffer-campagna-20261008-01/decode.lisp")
   :HASH-ALGORITHM "MD5" :HASH
   #A((32) BASE-CHAR . "fc85393333c7fcd9d0c1c6637e90f1bc") :CONTENTS
   "(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 1) (debug 2)))
(defun allowed-data (x)
  (typecase x
    (null t) (cons (and (allowed-data (car x)) (allowed-data (cdr x))))
    (string t) (number t) (symbol (keywordp x)) (t nil)))
(defun read-one (path)
  (with-open-file (s path)
    (let ((*read-eval* nil) (end (list :end)))
      (let ((data (read s nil end)))
        (when (eq data end) (error \"Empty structured output\"))
        (unless (allowed-data data) (error \"Foreign symbol/object in data\"))
        (unless (eq (read s nil end) end) (error \"Trailing structured output\"))
        data))))
(let ((*read-eval* nil) (*print-readably* t) (*print-pretty* t))
  (handler-case
      (progn
        (when (some (lambda (name) (find-package name))
                    '(\"ARCDOCDB.SPK01\" \"ARCDOCDB.SPK01.LETTURA-BUFFER\"
                      \"ARCDOCDB.SPK01.CHECK-LETTURA-BUFFER\"))
          (error \"Decoder contains spike package\"))
        (let* ((record (read-one (second sb-ext:*posix-argv*)))
               (data (read-one (third sb-ext:*posix-argv*))))
          (write (list :schema-version 1 :status :ok :read-eval :false
                       :spike-packages :absent :record-status (getf record :status) :decoded data))
          (terpri) (finish-output)))
    (error (c)
      (write (list :schema-version 1 :status :error :condition-type (string (type-of c))
                   :condition (princ-to-string c)))
      (terpri) (finish-output) (sb-ext:exit :code 1))))
"))
 :SOURCE-AFTER
 ((:PATH
   #A((99) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/core.lisp")
   :HASH-ALGORITHM "MD5" :HASH
   #A((32) BASE-CHAR . "1acc82229e9ebb3b43032e70dfb7de4a") :CONTENTS
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
   :HASH-ALGORITHM "MD5" :HASH
   #A((32) BASE-CHAR . "f5c8c3a80b3f9bb83e4eb733f7f751bc") :CONTENTS
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
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/check-lettura-buffer.lisp")
   :HASH-ALGORITHM "MD5" :HASH
   #A((32) BASE-CHAR . "8f8ae70dac6378e20ee38e0878f48060") :CONTENTS
   ";;;; Fase 0. Owner CHECK; vedere metodo-check-lettura-buffer.md prima di eseguire.
;;; REQ: REQ-IDX-001 REQ-IDX-007 REQ-VAL-001
(defpackage #:arcdocdb.spk01.check-lettura-buffer
  (:use #:cl)
  (:export #:check))
(in-package #:arcdocdb.spk01.check-lettura-buffer)
(declaim (optimize (safety 3) (speed 1) (debug 2)))

(defconstant +max64+ #xffffffffffffffff)
(defconstant +max24+ #xffffff)
(deftype destination () '(simple-array (unsigned-byte 64) (4)))
(define-condition check-failure (error)
  ((kind :initarg :kind :reader failure-kind)
   (detail :initarg :detail :reader failure-detail))
  (:report (lambda (c s) (format s \"CHECK ~S: ~S\" (failure-kind c) (failure-detail c)))))
(define-condition check-budget-exhausted (error) ()
  (:report (lambda (c s) (declare (ignorable c)) (write-string \"CHECK assertion budget exhausted\" s))))
(define-condition callback-fixture-error (error) ()
  (:report (lambda (c s) (declare (ignorable c)) (write-string \"Original callback fixture error\" s))))
(defstruct audit
  (remaining 200000) (assertions 0) (reads 0) (principal 0) (negative 0)
  (mutants 0) (ingress 0) (writer-rejections 0) (budget-rejections 0)
  (witnesses 0) (retry-budgets 0))
(defvar *audit* nil)

(defun demand (truth kind &rest detail)
  (unless (plusp (audit-remaining *audit*)) (error 'check-budget-exhausted))
  (decf (audit-remaining *audit*))
  (incf (audit-assertions *audit*))
  (unless truth (error 'check-failure :kind kind :detail detail))
  :checked)
(defun buffer ()
  (make-array 4 :element-type '(unsigned-byte 64)
              :initial-contents '(#xfedcba9876543210 #x8000000000000001
                                  #x1122334455667788 #xffffffffffffffff)))
(defun words-list (a) (coerce a 'list))
(defun unchanged (a before where)
  (demand (equalp a before) :destination-before-validation where (words-list a)))
(defun key (id)
  ;; Full 128-bit keys constructed here; no core generator or pattern oracle.
  (let ((a (make-array 16 :element-type '(unsigned-byte 8) :initial-element 0)))
    (cond ((zerop id) a)
          ((= id 1) (fill a 255))
          (t (dotimes (n 8 a)
               (setf (aref a n) (ldb (byte 8 (* 8 n)) id)
                     (aref a (+ n 8))
                     (ldb (byte 8 (* 8 n)) (logxor id #xd1b54a32d192ed03))))))))
(defun token (k) (coerce k 'list))
(defun tuple (words n)
  (let ((csn (mod (+ #x8000000000000001 (* n 104729)) (1+ +max64+)))
        (seg (mod (+ #xffffffff (* n 17)) #x100000000))
        (off (mod (+ #xfffffff1 (* n 43)) #x100000000))
        (len (mod (* n 65537) (1+ +max24+)))
        (end (if (= words 5) (mod (+ +max64+ (* n 97)) (1+ +max64+)) 0)))
    (list csn (+ (* seg #x100000000) off) len end)))
(defun store-tuple (i k data)
  (destructuring-bind (csn loc len end) data
    (arcdocdb.spk01:inserisci i k csn (floor loc #x100000000)
                            (mod loc #x100000000) len :end-csn end)))
(defstruct model
  (map (make-hash-table :test 'equal)) (journal nil) (puts 0) (deletes 0))
(defun model-put (i m k data)
  (multiple-value-bind (old present) (gethash (token k) (model-map m))
    (declare (ignorable old))
    (demand (eq (store-tuple i k data) (not present)) :writer-put)
    (setf (gethash (token k) (model-map m)) (copy-list data))
    (push (list :put (token k) (copy-list data)) (model-journal m))
    (incf (model-puts m))))
(defun model-delete (i m k)
  (multiple-value-bind (old present) (gethash (token k) (model-map m))
    (declare (ignorable old))
    (demand (eq (arcdocdb.spk01:elimina i k) present) :writer-delete)
    (remhash (token k) (model-map m))
    (push (list :delete (token k)) (model-journal m))
    (incf (model-deletes m))))
(defun replay-model (i m)
  (let ((replay (make-hash-table :test 'equal)))
    (dolist (event (reverse (model-journal m)))
      (ecase (first event)
        (:put (setf (gethash (second event) replay) (copy-list (third event))))
        (:delete (remhash (second event) replay))))
    (demand (= (hash-table-count replay) (hash-table-count (model-map m))) :replay-count)
    (maphash (lambda (k data)
               (demand (equal data (gethash k replay)) :replay-payload k)) (model-map m))
    (demand (= (hash-table-count replay) (arcdocdb.spk01::indice-documenti i)) :document-count)))

(defun baseline (i k d &key (attempts 8) after-fragment after-fields)
  (multiple-value-bind (csn loc len end status retries)
      (arcdocdb.spk01:leggi i k :attempts attempts
                              :after-fragment after-fragment :after-fields after-fields)
    (when (eq status :hit)
      (setf (aref d 0) csn (aref d 1) loc (aref d 2) len (aref d 3) end))
    (values status retries)))
(defun outcome (reader i k d expected retries &rest options)
  (let ((before (copy-seq d))
        (result (multiple-value-list (apply reader i k d options))))
    (demand (= (length result) 2) :return-arity (length result))
    (demand (and (keywordp (first result)) (typep (second result) 'fixnum)) :return-types)
    (demand (eq (first result) (if expected :hit :miss)) :status (first result))
    (demand (= (second result) retries) :retry-count (second result) retries)
    (if expected (demand (equal expected (words-list d)) :payload (words-list d) expected)
        (unchanged d before :miss))
    result))
(defun read-model (reader i m k)
  (let* ((expected (gethash (token k) (model-map m))) (a (buffer)) (b (buffer)))
    (let ((ra (outcome reader i k a expected 0))
          (rb (outcome #'baseline i k b expected 0)))
      (demand (and (equal ra rb) (equalp a b)) :baseline-comparison))
    (incf (audit-reads *audit*))))
(defun principal () (incf (audit-principal *audit*)))
(defun negative () (incf (audit-negative *audit*)))

(defun campaign (reader words)
  (let ((i (arcdocdb.spk01:make-indice :capacity 16 :words words :max-depth 16))
        (m (make-model)) (state 424242) (steps 0) (reads-before (audit-reads *audit*)))
    (dotimes (id 64)
      (model-put i m (key id) (tuple words (+ 1 id)))
      (read-model reader i m (key id)))
    (dotimes (block 128)
      (setf state (mod (+ (* state 1664525) 1013904223) #x100000000))
      (let ((k (key (mod (ash state -8) 64))) (n (+ 1000 (* block 3))))
        (model-put i m k (tuple words n)) (incf steps)
        (model-put i m k (tuple words (+ n 1))) (incf steps)
        (read-model reader i m k) (incf steps)
        (model-delete i m k) (incf steps)
        (read-model reader i m k) (incf steps)
        (model-put i m k (tuple words (+ n 2))) (incf steps)
        (read-model reader i m k) (incf steps)
        (read-model reader i m (key (+ 256 (mod (ash state -8) 64)))) (incf steps))
      (demand (= 64 (arcdocdb.spk01::indice-documenti i)) :campaign-population))
    (dotimes (id 384) (read-model reader i m (key id)))
    (replay-model i m)
    (demand (= steps 1024) :campaign-steps)
    (demand (= (model-puts m) 448) :campaign-puts)
    (demand (= (model-deletes m) 128) :campaign-deletes)
    (demand (= (length (model-journal m)) 576) :campaign-history)
    (demand (= (- (audit-reads *audit*) reads-before) 960) :campaign-reads)
    (demand (plusp (arcdocdb.spk01::indice-split i)) :campaign-split)
    (principal)
    (list :words words :seed 424242 :steps steps :blocks 128 :initial-puts 64
          :campaign-puts 384 :campaign-deletes 128 :campaign-reads 512
          :initial-reads 64 :final-reads 384 :read-comparisons 960
          :history-events 576 :final-live 64 :final-state state
          :splits (arcdocdb.spk01::indice-split i)
          :rebuilds (arcdocdb.spk01::indice-rebuild i))))

(defun boundaries (reader words)
  (let ((i (arcdocdb.spk01:make-indice :capacity 16 :words words)) (m (make-model))
        (values (list 0 1 most-positive-fixnum (1+ most-positive-fixnum)
                      #x8000000000000000 +max64+)))
    (loop for value in values for n from 0 do
      (let* ((loc (nth n (list 0 +max64+ most-positive-fixnum
                              (1+ most-positive-fixnum) #x8000000000000000 +max64+)))
             (data (list value loc (nth (mod n 3) (list 0 1 +max24+))
                         (if (= words 5) value 0))) (k (key n)))
        (model-put i m k data) (read-model reader i m k)
        (principal)))
    (model-delete i m (key 0)) (read-model reader i m (key 0))
    (model-delete i m (key 0)) (read-model reader i m (key 0))
    (model-put i m (key 0) (tuple words 999)) (read-model reader i m (key 0))
    (principal) (replay-model i m)
    (list :words words :records 6 :zero-key :covered :all-ff-key :covered
          :max64 +max64+ :length-max +max24+ :delete-absent :covered)))

(defun locate (i k)
  (let* ((h (arcdocdb.spk01::hash-chiave k 0))
         (f (arcdocdb.spk01::scegli-frammento (arcdocdb.spk01::indice-root i) h)))
    (multiple-value-bind (s present) (arcdocdb.spk01::cerca-writer f k h)
      (demand present :fixture-slot)
      (values f s))))
(defun rebuilds (reader words)
  (let ((i (arcdocdb.spk01:make-indice :capacity 16 :words words)) (m (make-model)))
    (dotimes (n 6) (model-put i m (key n) (tuple words n)))
    (dotimes (n 4) (model-delete i m (key n)))
    (demand (= (arcdocdb.spk01::indice-rebuild i) 0) :before-tombstone-rebuild)
    (model-put i m (key 10) (tuple words 10))
    (demand (= (arcdocdb.spk01::indice-rebuild i) 1) :tombstone-rebuild)
    (dotimes (n 12) (read-model reader i m (key n)))
    (multiple-value-bind (f s) (locate i (key 4))
      (setf (aref (arcdocdb.spk01::frammento-slots f)
                  (+ (* s words) 3)) (- arcdocdb.spk01::+soglia-seq+ 2)))
    (model-put i m (key 4) (tuple words 200))
    (demand (= (arcdocdb.spk01::indice-rebuild i) 2) :sequence-rebuild)
    (dotimes (n 12) (read-model reader i m (key n)))
    (replay-model i m) (principal)
    (list :words words :tombstone-rebuilds 1 :sequence-rebuilds 1)))

(defun collision-keys ()
  (let ((found nil) (count 0) (examined 0))
    (dotimes (n 131072)
      (let* ((k (key (+ n 2))) (h (arcdocdb.spk01::hash-chiave k 0)))
        (incf examined)
        (when (and (= 53 (logand h 127)) (= 15 (logand 15 (ash h -7))))
          (push k found) (incf count)
          (when (= count 7) (return)))))
    (demand (= count 7) :collision-search-budget count examined)
    (values (nreverse found) examined)))
(defun collision-trace (reader i k expected expected-slots)
  (let* ((d (buffer)) (before (copy-seq d)) (trace nil) (fragments 0))
    (outcome reader i k d expected 0
             :after-fragment (lambda (f)
                               (demand (arcdocdb.spk01::frammento-p f) :callback-fragment)
                               (incf fragments) (unchanged d before :collision-fragment))
             :after-fields (lambda (f s)
                             (demand (arcdocdb.spk01::frammento-p f) :callback-fields)
                             (push s trace) (unchanged d before :collision-fields)))
    (demand (= fragments 1) :callback-fragments)
    (demand (equal (reverse trace) expected-slots) :callback-trace (reverse trace) expected-slots)))
(defun collisions (reader words keys examined)
  (let ((i (arcdocdb.spk01:make-indice :capacity 16 :words words)) (m (make-model)))
    (loop for k in (subseq keys 0 6) for n from 0 do
      (model-put i m k (tuple words (+ 300 n)))
      (multiple-value-bind (f s) (locate i k)
        (declare (ignorable f))
        (demand (= s (mod (+ 15 n) 16)) :wrap-probe-placement)))
    (loop for k in keys for n from 0 do
      (let ((slots (subseq '(15 0 1 2 3 4) 0 (min 6 (1+ n))))
            (data (gethash (token k) (model-map m))))
        (collision-trace reader i k data slots)
        (collision-trace #'baseline i k data slots)
        (read-model reader i m k)))
    (model-delete i m (first keys))
    (read-model reader i m (sixth keys)) ; tombstone cannot terminate search
    (model-put i m (seventh keys) (tuple words 9999))
    (read-model reader i m (seventh keys))
    (multiple-value-bind (f s) (locate i (seventh keys))
      (declare (ignorable f)) (demand (= s 15) :wrap-tombstone-reuse))
    (replay-model i m) (principal)
    (list :words words :fingerprint 53 :probe-start 15 :occupied-slots '(15 0 1 2 3 4)
          :keys-found 7 :search-candidates examined :candidate-callbacks :verified)))

;;; Deterministic witnesses. Each invocation creates an independent index.
(defun witness (reader words mode)
  (let* ((i (arcdocdb.spk01:make-indice :capacity 8 :words words))
         (k (key 0)) (d (buffer)) (before (copy-seq d))
         (one (tuple words 1)) (two (tuple words 2)) (three (tuple words 3))
         (fc 0) (sc 0) (retired nil) (saved-odd nil)
         (expected three) (expected-status :hit) (expected-retries 1)
         (expected-fc 2) (expected-sc 2)
         (original (make-condition 'callback-fixture-error)))
    (unless (eq mode :root-miss) (store-tuple i k one))
    (case mode
      (:root-miss (setf expected-sc 1))
      (:fields-delete (setf expected nil expected-status :miss expected-sc 1))
      (:fields-odd (setf expected nil expected-status :retry-limit expected-retries 8
                         expected-fc 8 expected-sc 1))
      ((:root-churn :fields-churn)
       (setf expected nil expected-status :retry-limit expected-retries 8
             expected-fc 8 expected-sc 8))
      (:error-fragment (setf expected-fc 1 expected-sc 0))
      (:error-fields (setf expected-fc 1 expected-sc 1)))
    (labels ((fragment (f)
               (incf fc) (unchanged d before :after-fragment)
               (demand (arcdocdb.spk01::frammento-p f) :callback-fragment)
               (case mode
                 (:root-hit (when (= fc 1)
                              (store-tuple i k two)
                              (arcdocdb.spk01::manutenzione i f t)
                              (setf retired f) (store-tuple i k three)))
                 (:root-miss (when (= fc 1)
                               (arcdocdb.spk01::manutenzione i f nil)
                               (setf retired f) (store-tuple i k three)))
                 (:root-churn (arcdocdb.spk01::manutenzione i f nil))
                 (:error-fragment (error original)))
               (unchanged d before :after-fragment-writer))
             (fields (f s)
               (incf sc) (unchanged d before :after-fields)
               (demand (and (arcdocdb.spk01::frammento-p f) (typep s 'fixnum)
                            (<= 0 s) (< s 8)) :callback-slot)
               (case mode
                 (:fields-update (when (= sc 1) (store-tuple i k three)))
                 (:fields-delete (when (= sc 1) (arcdocdb.spk01:elimina i k)))
                 (:fields-odd
                  (let* ((slots (arcdocdb.spk01::frammento-slots f))
                         (position (+ (* s words) 3)) (seq (aref slots position)))
                    (setf saved-odd (list slots position seq)
                          (aref slots position) (1+ seq))))
                 (:fields-churn (store-tuple i k (tuple words (+ sc 20))))
                 (:error-fields (error original)))
               (unchanged d before :after-fields-writer)))
      (unwind-protect
           (if (member mode '(:error-fragment :error-fields))
               (let ((caught (handler-case
                                 (progn (funcall reader i k d :after-fragment #'fragment
                                                :after-fields #'fields) nil)
                               (error (c) c))))
                 (demand (eq caught original) :callback-original-error)
                 (unchanged d before :callback-error))
               (let ((result (multiple-value-list
                              (funcall reader i k d :after-fragment #'fragment
                                       :after-fields #'fields))))
                 (demand (= (length result) 2) :return-arity)
                 (demand (eq (first result) expected-status) :status (first result) expected-status)
                 (demand (typep (second result) 'fixnum) :return-types)
                 (demand (= (second result) expected-retries) :retry-count)
                 (if expected (demand (equal expected (words-list d)) :payload)
                     (unchanged d before :non-hit))))
        (when saved-odd
          (setf (aref (first saved-odd) (second saved-odd)) (third saved-odd)))))
    (demand (= fc expected-fc) :fragment-callback-count fc expected-fc)
    (demand (= sc expected-sc) :fields-callback-count sc expected-sc)
    (when retired
      (multiple-value-bind (csn loc len end status)
          (arcdocdb.spk01::sonda-reader retired k (arcdocdb.spk01::hash-chiave k 0) nil)
        (demand (eq status (if (eq mode :root-hit) :hit :miss)) :retired-status)
        (when (eq mode :root-hit)
          (demand (equal (list csn loc len end) two) :retired-payload))))
    (list :case mode :words words :status (if (member mode '(:error-fragment :error-fields))
                                             :original-error expected-status)
          :retries (if (member mode '(:error-fragment :error-fields)) :not-returned expected-retries)
          :fragment-callbacks fc :fields-callbacks sc :buffer-publication :validated)))
(defun witnesses (reader words)
  (loop for mode in '(:root-hit :root-miss :fields-update :fields-delete :fields-odd
                     :root-churn :fields-churn :error-fragment :error-fields)
        collect (let ((a (witness reader words mode)) (b (witness #'baseline words mode)))
                  (demand (equal a b) :witness-baseline mode)
                  (incf (audit-witnesses *audit*)) (principal) a)))

(defun retry-budgets (reader words)
  (let* ((i (arcdocdb.spk01:make-indice :capacity 8 :words words)) (k (key 0)))
    (store-tuple i k (tuple words 1))
    (multiple-value-bind (f s) (locate i k)
      (let* ((slots (arcdocdb.spk01::frammento-slots f)) (pos (+ (* s words) 3))
             (seq (aref slots pos)))
        (setf (aref slots pos) (1+ seq))
        (unwind-protect
             (loop for attempts from 1 to 8 do
               (dolist (r (list reader #'baseline))
                 (let* ((d (buffer)) (before (copy-seq d)) (fc 0) (sc 0)
                        (result (multiple-value-list
                                 (funcall r i k d :attempts attempts
                                          :after-fragment (lambda (fragment)
                                                            (demand (eq fragment f) :odd-fragment)
                                                            (incf fc) (unchanged d before :odd-fragment))
                                          :after-fields (lambda (fragment slot)
                                                          (declare (ignorable fragment slot)) (incf sc))))))
                   (demand (equal result (list :retry-limit attempts)) :odd-retry-limit)
                   (demand (= fc attempts) :odd-all-attempts)
                   (demand (zerop sc) :odd-no-fields)
                   (unchanged d before :odd-budget)))
               (principal) (incf (audit-retry-budgets *audit*)))
          (setf (aref slots pos) seq))))
    (list :words words :attempts '(1 2 3 4 5 6 7 8) :status :retry-limit)))

;;; Local mutant implementation. Never installed into core/kernel symbol-functions.
(defun mutant-slot (mode f s k h d after-fields)
  (let* ((slots (arcdocdb.spk01::frammento-slots f))
         (width (arcdocdb.spk01::frammento-larghezza f)) (base (* s width))
         (seq (aref slots (+ base 3))))
    (when (and (not (eq mode :no-seqlock)) (oddp seq))
      (return-from mutant-slot (values 0 0 0 0 :retry)))
    (sb-thread:barrier (:read))
    (let* ((csn (aref slots base)) (loc (aref slots (+ base 1)))
           (meta (aref slots (+ base 2))) (end (if (= width 5) (aref slots (+ base 4)) 0))
           (arena (arcdocdb.spk01::frammento-chiavi f)) (off (ldb (byte 24 0) meta))
           (match (and (= (aref (arcdocdb.spk01::frammento-ctrl f) s) (logand 127 h))
                       (= 1 (ldb (byte 8 56) meta)) (= 16 (ldb (byte 8 24) meta))
                       (<= (+ off 16) (length arena))
                       (arcdocdb.spk01::stessa-chiave-p k arena off))))
      (when (and match (eq mode :early-destination))
        (setf (aref d 0) csn (aref d 1) loc (aref d 2) (ldb (byte 24 32) meta) (aref d 3) end))
      (when after-fields (funcall after-fields f s))
      (sb-thread:barrier (:read))
      (if (and (not (eq mode :no-seqlock)) (/= seq (aref slots (+ base 3))))
          (values 0 0 0 0 :retry)
          (values csn loc (ldb (byte 24 32) meta) end (if match :hit :skip))))))
(defun mutant-probe (mode f k h d after-fields)
  (dotimes (n (arcdocdb.spk01::frammento-capacita f) (values 0 0 0 0 :miss))
    (let* ((s (arcdocdb.spk01::posizione-sonda h (arcdocdb.spk01::frammento-capacita f) n))
           (ctrl (aref (arcdocdb.spk01::frammento-ctrl f) s)))
      (when (= ctrl 255) (return-from mutant-probe (values 0 0 0 0 :miss)))
      (when (= ctrl (logand h 127))
        (multiple-value-bind (csn loc len end status) (mutant-slot mode f s k h d after-fields)
          (unless (eq status :skip)
            (return-from mutant-probe (values csn loc len end status))))))))
(defun mutant (mode)
  (lambda (i k d &key (attempts 8) after-fragment after-fields)
    (let ((h (arcdocdb.spk01::hash-chiave k 0)))
      (block reading
        (dotimes (attempt attempts (values :retry-limit attempts))
          (let* ((root (arcdocdb.spk01::indice-root i))
                 (gen (arcdocdb.spk01::radice-generazione root)))
            (sb-thread:barrier (:read))
            (let ((f (arcdocdb.spk01::scegli-frammento root h)))
              (when after-fragment (funcall after-fragment f))
              (multiple-value-bind (csn loc len end status) (mutant-probe mode f k h d after-fields)
                (sb-thread:barrier (:read))
                (let ((actual (arcdocdb.spk01::indice-root i)))
                  (when (and (not (eq status :retry))
                             (or (eq mode :no-root)
                                 (and (eq root actual) (= gen (arcdocdb.spk01::radice-generazione actual)))))
                    (when (eq status :hit)
                      (let ((data (list csn loc len end)))
                        (when (eq mode :truncate-u64)
                          (setf data (mapcar (lambda (word) (logand word most-positive-fixnum)) data)))
                        (replace d data)))
                    (return-from reading (values status attempt))))))))))))
(defun mutant-rejections (words)
  (loop for (mode test kinds) in
        '((:no-root :root-hit (:retry-count :payload))
          (:no-root :root-miss (:status))
          (:no-seqlock :fields-update (:retry-count :payload))
          (:no-seqlock :fields-delete (:status))
          (:no-seqlock :fields-odd (:status))
          (:truncate-u64 :boundary (:payload))
          (:early-destination :fields-update (:destination-before-validation))
          (:early-destination :fields-delete (:destination-before-validation)))
        collect
        (let ((c (handler-case
                     (progn
                       (if (eq test :boundary)
                           (let* ((i (arcdocdb.spk01:make-indice :capacity 8 :words words))
                                  (k (key 1)) (data (list +max64+ +max64+ +max24+
                                                         (if (= words 5) +max64+ 0))))
                             (store-tuple i k data) (outcome (mutant mode) i k (buffer) data 0))
                           (witness (mutant mode) words test))
                       nil)
                   (check-failure (failure) failure))))
          (demand (and c (member (failure-kind c) kinds)) :mutant-not-rejected mode test)
          (negative) (incf (audit-mutants *audit*))
          (list :mutation mode :witness test :rejected-by (failure-kind c)))))

(defun reject-input (reader i k d options backing)
  (let* ((watched (and (arrayp d) d))
         (before (when watched (copy-seq watched)))
         (backing-before (when backing (copy-seq backing)))
         (key-before (when (arrayp k) (copy-seq k)))
         (caught (handler-case (progn (apply reader i k d options) nil) (error (c) c))))
    (demand (and caught (or (typep caught 'type-error) (typep caught 'program-error)
                           (typep caught 'arcdocdb.spk01:limite-indice))) :input-not-rejected)
    (when watched (unchanged watched before :invalid-input))
    (when backing (unchanged backing backing-before :invalid-input-backing))
    (when key-before (demand (equalp k key-before) :invalid-key-mutated))
    (negative) (incf (audit-ingress *audit*))
    (list :rejection-type (string (type-of caught)) :destination :unchanged)))
(defun ingress (reader words)
  (let* ((i (arcdocdb.spk01:make-indice :capacity 8 :words words)) (k (key 0))
         (backing (make-array 8 :element-type '(unsigned-byte 64) :initial-element 111))
         (cases nil))
    (store-tuple i k (tuple words 1))
    (push (list :index (reject-input reader nil k (buffer) nil nil)) cases)
    (dolist (bad-key (list nil #(0 0 0 0) (make-array 15 :element-type '(unsigned-byte 8))
                          (make-array 17 :element-type '(unsigned-byte 8))
                          (make-array 16 :element-type '(unsigned-byte 8) :adjustable t)
                          (make-array 16 :element-type '(unsigned-byte 16))))
      (push (list :key (reject-input reader i bad-key (buffer) nil nil)) cases))
    (dolist (bad-dest (list nil #(1 2 3 4)
                           (make-array 3 :element-type '(unsigned-byte 64))
                           (make-array 5 :element-type '(unsigned-byte 64))
                           (make-array 4 :element-type '(unsigned-byte 32))
                           (make-array 4 :element-type '(unsigned-byte 64) :adjustable t)
                           (make-array 4 :element-type '(unsigned-byte 64) :fill-pointer 4)
                           (make-array 4 :element-type '(unsigned-byte 64)
                                       :displaced-to backing :displaced-index-offset 2)))
      (push (list :destination (reject-input reader i k bad-dest nil backing)) cases))
    (dolist (bad-attempts '(0 9 -1 1.0 \"8\"))
      (push (list :attempts (reject-input reader i k (buffer) (list :attempts bad-attempts) nil)) cases))
    (dolist (name '(:after-fragment :after-fields))
      (push (list name (reject-input reader i k (buffer) (list name 42) nil)) cases))
    (push (list :unknown-keyword (reject-input reader i k (buffer) '(:unknown 1) nil)) cases)
    (demand (= (length cases) 23) :ingress-count)
    (list :words words :cases 23 :rejections (nreverse cases))))

(defun writer-rejections (reader words)
  (let* ((i (arcdocdb.spk01:make-indice :capacity 8 :words words)) (k (key 0))
         (data (tuple words 1)) (m (make-model)) (count 0))
    (model-put i m k data)
    (dolist (bad (list (list (1+ +max64+) 0 0 0 0)
                      (list 1 #x100000000 0 0 0) (list 1 0 #x100000000 0 0)
                      (list 1 0 0 (1+ +max24+) 0) (list 1 0 0 0 (1+ +max64+))
                      (list 1 0 0 0 (if (= words 4) 1 -1))))
      (let* ((d (buffer)) (before (copy-seq d))
             (caught (handler-case
                         (progn (destructuring-bind (csn seg off len end) bad
                                  (arcdocdb.spk01:inserisci i k csn seg off len :end-csn end)) nil)
                       (error (c) c))))
        (demand (and caught (or (typep caught 'type-error)
                               (typep caught 'arcdocdb.spk01:limite-indice))) :writer-not-rejected)
        (unchanged d before :writer-error)
        (read-model reader i m k) (negative) (incf count)
        (incf (audit-writer-rejections *audit*))))
    (demand (= count 6) :writer-rejection-count)
    (list :words words :cases count :original-record :preserved)))
(defun writer-budgets (reader words)
  (let ((i (arcdocdb.spk01:make-indice :capacity 8 :words words :max-depth 0))
        (m (make-model)))
    (dotimes (id 7) (model-put i m (key id) (tuple words (+ 1 id))))
    (let* ((d (buffer)) (before (copy-seq d))
           (caught (handler-case (progn (store-tuple i (key 7) (tuple words 99)) nil)
                     (arcdocdb.spk01:limite-indice (c) c))))
      (demand (and caught (eq (arcdocdb.spk01::limite-motivo caught) :profondita-directory))
              :depth-budget-not-rejected)
      (unchanged d before :depth-budget)
      (dotimes (id 8) (read-model reader i m (key id)))
      (replay-model i m) (negative) (incf (audit-writer-rejections *audit*)))
    (let ((caught (handler-case
                      (progn (arcdocdb.spk01:make-indice :capacity 32768 :words words :memory-mib 1) nil)
                    (arcdocdb.spk01:limite-indice (c) c))))
      (demand (and caught (eq (arcdocdb.spk01::limite-motivo caught) :payload-iniziale))
              :memory-budget-not-rejected)
      (negative) (incf (audit-writer-rejections *audit*)))
    (list :words words :depth-budget :explicit-error :memory-budget :explicit-error
          :partial-success :false :preserved-records 7)))
(defun budget-rejection ()
  (let ((caught (handler-case
                    (progn (check :budget 0) nil)
                  (check-budget-exhausted (c) c))))
    (demand (typep caught 'check-budget-exhausted) :budget-not-rejected)
    (negative) (incf (audit-budget-rejections *audit*))
    (list :status :explicit-error :condition-type \"CHECK-BUDGET-EXHAUSTED\")))

(defun portable-data-p (x)
  (typecase x
    (null t) (cons (and (portable-data-p (car x)) (portable-data-p (cdr x))))
    (string t) (number t) (symbol (keywordp x)) (t nil)))
(defun check (&key (budget 200000))
  \"Finite independent-model CHECK; no BENCH, no thread/scheduler assumptions.\"
  (unless (typep budget '(integer 0 200000))
    (error 'type-error :datum budget :expected-type '(integer 0 200000)))
  (let* ((*audit* (make-audit :remaining budget))
         (package (or (find-package \"ARCDOCDB.SPK01.LETTURA-BUFFER\")
                      (error \"Kernel package absent; CHECK not attempted\")))
         (symbol (find-symbol \"LEGGI\" package))
         (reader (and symbol (fboundp symbol) (symbol-function symbol))))
    (demand reader :kernel-function)
    (multiple-value-bind (keys examined) (collision-keys)
      (let ((campaigns nil) (boundary-reports nil) (rebuild-reports nil)
            (collision-reports nil) (witness-reports nil) (retry-reports nil)
            (ingress-reports nil) (writer-reports nil) (writer-budget-reports nil)
            (mutation-reports nil))
        (dolist (words '(4 5))
          (push (campaign reader words) campaigns)
          (push (boundaries reader words) boundary-reports)
          (push (rebuilds reader words) rebuild-reports)
          (push (collisions reader words keys examined) collision-reports)
          (push (list :words words :cases (witnesses reader words)) witness-reports)
          (push (retry-budgets reader words) retry-reports)
          (push (ingress reader words) ingress-reports)
          (push (writer-rejections reader words) writer-reports)
          (push (writer-budgets reader words) writer-budget-reports)
          (push (list :words words :cases (mutant-rejections words)) mutation-reports))
        (let ((exhaustion (budget-rejection)))
          (demand (= (audit-reads *audit*) 2032) :total-model-reads)
          (demand (= (audit-principal *audit*) 54) :total-principal)
          (demand (= (audit-negative *audit*) 79) :total-negative)
          (demand (= (audit-ingress *audit*) 46) :total-ingress)
          (demand (= (audit-writer-rejections *audit*) 16) :total-writer-rejections)
          (demand (= (audit-budget-rejections *audit*) 1) :total-budget-rejections)
          (demand (= (audit-mutants *audit*) 16) :total-mutants)
          (demand (= (audit-witnesses *audit*) 18) :total-witnesses)
          (demand (= (audit-retry-budgets *audit*) 16) :total-retry-budgets)
          (let ((report
                  (list :schema-version 1 :status :ok :spike :spk-01 :phase 0
                        :layout :v1 :layouts '(:words4 :words5-extra-end)
                        :verifies-format-v2 :false :safety 3 :bench-executed :false
                        :kernel \"ARCDOCDB.SPK01.LETTURA-BUFFER:LEGGI\"
                        :baseline \"ARCDOCDB.SPK01:LEGGI\"
                        :model :independent-map-with-journal-replay
                        :principal-cases (audit-principal *audit*)
                        :negative-controls (audit-negative *audit*)
                        :negative-counts (list :ingress 46 :writer 16 :budget 1 :mutants 16)
                        :read-comparisons (audit-reads *audit*)
                        :campaigns (nreverse campaigns) :boundaries (nreverse boundary-reports)
                        :rebuilds (nreverse rebuild-reports) :collisions (nreverse collision-reports)
                        :witnesses (nreverse witness-reports) :retry-budgets (nreverse retry-reports)
                        :invalid-inputs (nreverse ingress-reports)
                        :writer-rejections (nreverse writer-reports)
                        :writer-budgets (nreverse writer-budget-reports)
                        :mutants (nreverse mutation-reports) :budget-exhaustion exhaustion
                        :budget (list :maximum budget :remaining (audit-remaining *audit*)
                                      :assertions (audit-assertions *audit*))
                        :limitations '(:finite-campaign :synchronous-interleavings
                                       :no-hardware-memory-model-proof :no-thread-stress))))
            (demand (portable-data-p report) :foreign-symbol-in-report)
            (setf (getf report :budget)
                  (list :maximum budget :remaining (audit-remaining *audit*)
                        :assertions (audit-assertions *audit*)))
            report))))))
")
  (:PATH
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/metodo-check-lettura-buffer.md")
   :HASH-ALGORITHM "MD5" :HASH
   #A((32) BASE-CHAR . "de360da1ad98cdfc061d887bbddefa9b") :CONTENTS
   "# Metodo preregistrato — CHECK lettura-buffer, Fase 0

> **Proposta** — Verifica sperimentale preregistrata prima di compile/CHECK;
> riferimenti REQ-IDX-001, REQ-IDX-007 e REQ-VAL-001. Non codice di produzione.

Owner esclusivo: `check-lettura-buffer.lisp`, questo metodo e nuovi
`out/check-lettura-buffer-*/`. Checkout: indice-lettura/ArcDocDB. Nessuna
modifica a core, kernel dell'agente A, runner, tools, documenti condivisi.
Solo Common Lisp/SBCL, safety 3; warning e style-warning sono errori.
Nessun BENCH, commit o push. La misura e l'integrazione spettano al parent.

## Ipotesi e criteri registrati prima di compile/CHECK

API sotto prova: `ARCDOCDB.SPK01.LETTURA-BUFFER:LEGGI`, destinazione privata
simple-array u64 di lunghezza esattamente 4; due valori, status keyword e
retry fixnum. Layout v1 words4 / words5-extra-end. HIT pubblica CSN,
location, length, end-CSN soltanto dopo validazione seqlock e root; MISS,
retry-limit e ogni errore conservano tutte le parole della destinazione.
Le callback seguono il core: after-fragment su ogni tentativo, after-fields
per ogni candidato ctrl con seq iniziale pari, anche se la chiave non coincide.

Il modello è una mappa EQUAL di liste dei 16 ottetti, con journal indipendente
di PUT/DELETE e replay finale. Generazione chiavi, tuple e location aritmetica
sono nel CHECK, senza usare pattern o LEGGI del core per ottenere attesi.
Ogni lettura ordinaria confronta kernel, modello e baseline; il baseline
viene adattato alla destinazione solo dopo aver restituito HIT. Gli interleaving
usano fixture nuove per ciascun reader e gli stessi callback, senza scheduler.

Per layout: 64 chiavi iniziali; LCG32 seed 424242, 128 blocchi di otto
operazioni (1024): PUT, overwrite, hit, delete, miss, reinsertion, hit,
miss assente. Assert esatti: 384 PUT, 128 DELETE, 512 letture di campagna,
64 letture iniziali e 384 finali (960 confronti kernel/modello/baseline).
Il journal contiene 576 eventi per layout, replay completo e nessun limite
esaurito trattato come successo. Split deve essere realmente avvenuto.

Casi principali separati: valori 0/1/fixnum-max/fixnum-max+1/2^63/max64,
location con segment e offset max32, length 0/1/max24, chiavi zero/all-FF;
rebuild per tombstone e soglia seqlock; sette chiavi con ctrl 53 e sonda
iniziale 15 a capacità 16, ricerca limitata a 131072 candidati. Sei slot
occupati devono risultare 15,0,1,2,3,4; il settimo è un MISS e visita sei
candidati. I callback devono avere tracce identiche al baseline.

Witness, entrambi i layout e reader: root ritirata HIT e MISS; update/delete
in after-fields; odd persistente introdotto dopo i campi; swap root su tutti
gli otto tentativi; update su tutti gli otto tentativi; errori originali nelle
due callback. Ogni callback controlla il buffer prima e dopo il writer;
HIT dopo retry verifica la tupla corrente, non quella ritirata. Retry-limit
richiede conteggio esatto e destinazione intatta. Budget 1..8 anche con odd
già presente: otto distinti casi, non una sola prova del default.

Controlli negativi separati: index/key/destination/attempts/callback invalidi,
keyword sconosciuta, rifiuto writer di u64 oltre max64 e length oltre max24,
budget del CHECK esaurito con condizione esplicita. Gli array, incluse le
regioni di backing di viste/displaced, vengono confrontati per intero.
Budget strutturali: sette record in capacità 8/profondità massima 0, ottavo
PUT rifiutato per profondità e sette record conservati; capacità 32768 con
1 MiB rifiutata per payload iniziale. Totali attesi: 54 casi principali,
79 controlli negativi (46 ingressi, 16 rifiuti writer/budget strutturali,
1 budget assert, 16 mutanti), 2032 letture contro mappa e baseline.

Mutanti locali al CHECK, senza ridefinire o modificare kernel/core: omettere
ricontrollo root (witness HIT e MISS), omettere secondo seqlock (update,
delete, odd), troncare u64 a fixnum (boundary), scrivere prima della
validazione (update e delete). Otto rifiuti richiesti per layout, con ragione
pertinente verificata; un errore generico non conta come mutante rigettato.
Non è una prova universale del modello di memoria o hardware. Nessuno
stress threaded: i witness sono interleaving sincroni con un solo writer.

CHECK ha budget finito di 200000 assert, ricerche finite, conteggi di
campagna e categorie separati. `:status :ok` viene costruito soltanto dopo
tutte le prove e gli assert finali. Output composto da liste, keyword,
stringhe e numeri; tipi, funzioni e condizioni descritti come stringhe.

## Registrazione schema1 di ogni esecuzione

Prima di ogni compile/CHECK viene scritto un piano numerato in un nuovo
out esclusivo, con argv e stdin esatti e rinvio a questo metodo. Driver SBCL
separato dall'esistente runner: snapshot source-before/after (contenuti e
MD5 dichiarato per core, kernel, CHECK, metodo e driver); stdout/stderr
originali su file, exit code e risultato decodificato nel record schema1.
Il driver promuove warning/style-warning a errori e verifica compile-file.
Errori/fallimenti restano nei record e non vengono sovrascritti. Qualsiasi
revisione del metodo precede l'esecuzione a cui si applica.

Un secondo processo SBCL, senza caricare package spike, legge risultato e
record con `*read-eval* = nil`, rigetta simboli non keyword e oggetti non
ammessi e salva i dati leggibili. Nessun CHECK prima del kernel completo;
la sua esistenza non è una dichiarazione di correttezza o prontezza.

### Esecuzione K1 preregistrata

Driver nuovi in `out/check-lettura-buffer-campagna-20261008-01/`: `record.lisp`,
`child.lisp`, `decode.lisp`. K1 compila in ordine core, kernel completo e CHECK,
carica i FASL e chiama CHECK. Avvio solo dopo conferma A di kernel congelato.
Budget: heap 1024 MiB, timeout figlio 90 secondi, registratore 105 secondi,
cleanup 5 secondi, 200000 assert. Massimo sei revisioni compilate; ciascuna
richiede un nuovo piano e conserva i fallimenti precedenti. Il timer protegge
l'esecuzione da blocchi; non viene usato per la correttezza degli interleaving.
Ogni snapshot include anche i tre driver. Source-after diverso implica errore.

Comando esatto dalla radice del checkout isolato:

```sh
/opt/homebrew/bin/sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-01-primary-index/out/check-lettura-buffer-campagna-20261008-01/record.lisp k1
```

Il registratore non carica i package spike e scrive preregistered.sexp prima
del lancio; stdout/stderr sono conservati originali, inclusa diagnostica del
compilatore su stderr. Dopo il record, un ulteriore processo senza package
spike verifica record e decoded.sexp con read-eval disabilitato.
Il registratore richiede handoff A `:ready`/`:frozen` e conserva quell'handoff
nel piano e nel record; il parent ha chiesto i commenti REQ prima di C3.
")
  (:PATH
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/check-lettura-buffer-campagna-20261008-01/record.lisp")
   :HASH-ALGORITHM "MD5" :HASH
   #A((32) BASE-CHAR . "327c0b3798e5565c8cfd087cdc1d75df") :CONTENTS
   "(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 1) (debug 2)))
(require :sb-md5)
(defparameter *check-root* #p\"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/\")
(defparameter *record-base* (make-pathname :name nil :type nil :defaults *load-truename*))
(defun file-text (p)
  (with-open-file (s p :external-format :utf-8)
    (let ((text (make-string (file-length s))))
      (subseq text 0 (read-sequence text s)))))
(defun dump (p data)
  (with-open-file (s p :direction :output :if-exists :error :if-does-not-exist :create
                      :external-format :utf-8)
    (let ((*print-readably* t) (*print-pretty* t)) (write data :stream s) (terpri s))))
(defun snapshot (p)
  (if (probe-file p)
      (list :path (namestring p) :hash-algorithm \"MD5\"
            :hash (format nil \"~(~{~2,'0X~}~)\" (coerce (sb-md5:md5sum-file p) 'list))
            :contents (file-text p))
      (list :path (namestring p) :state :absent)))
(defun snapshots ()
  (mapcar #'snapshot
          (append
           (mapcar (lambda (name) (merge-pathnames name *check-root*))
                   '(\"spikes/SPK-01-primary-index/core.lisp\"
                     \"spikes/SPK-01-primary-index/lettura-buffer.lisp\"
                     \"spikes/SPK-01-primary-index/check-lettura-buffer.lisp\"
                     \"spikes/SPK-01-primary-index/metodo-check-lettura-buffer.md\"))
           (mapcar (lambda (name) (merge-pathnames name *record-base*))
                   '(\"record.lisp\" \"child.lisp\" \"decode.lisp\")))))
(defun safe-data-p (x)
  (typecase x
    (null t) (cons (and (safe-data-p (car x)) (safe-data-p (cdr x))))
    (string t) (number t) (symbol (keywordp x)) (t nil)))
(defun decode-output (text)
  (handler-case
      (with-input-from-string (s text)
        (let ((*read-eval* nil) (end (list :end)))
          (let ((data (read s nil end)))
            (when (eq data end) (error \"No structured stdout\"))
            (unless (safe-data-p data) (error \"Foreign symbol/object in stdout\"))
            (unless (eq (read s nil end) end) (error \"Trailing stdout\"))
            data)))
    (error (c) (list :status :decode-error :condition-type (string (type-of c))
                     :condition (princ-to-string c)))))
(defun kernel-handoff ()
  (let ((data (decode-output
               (file-text (merge-pathnames
                           \"spikes/SPK-01-primary-index/out/lettura-buffer-campagna-20261008-01/kernel-pronto-B.sexp\"
                           *check-root*)))))
    (unless (and (eq (getf data :status) :ready) (eq (getf data :kernel-state) :frozen))
      (error \"Kernel not frozen/ready; compilation forbidden\"))
    data))
(defun run-bounded (argv input output errors)
  (let ((process nil) (failure nil))
    (unwind-protect
         (handler-case
             (sb-ext:with-timeout 105
               (setf process (sb-ext:run-program (first argv) (rest argv) :search nil :wait nil
                                                :input input :output output :error errors
                                                :if-output-exists :error :if-error-exists :error))
               (sb-ext:process-wait process))
           (error (c) (setf failure (list :condition-type (string (type-of c))
                                        :condition (princ-to-string c)))))
      (when (and process (sb-ext:process-alive-p process))
        (sb-ext:process-kill process 9)
        (sb-ext:with-timeout 5 (sb-ext:process-wait process))))
    (values (if process (or (sb-ext:process-exit-code process) -1) -1)
            (or failure :none))))
(let* ((name (second sb-ext:*posix-argv*)))
  (unless (and name (<= 1 (length name) 16) (every (lambda (c) (or (alphanumericp c) (char= c #\\-))) name))
    (error \"Run id required\"))
  (let* ((dir (merge-pathnames (concatenate 'string name \"/\") *record-base*))
         (stdout (merge-pathnames \"stdout.raw\" dir)) (stderr (merge-pathnames \"stderr.raw\" dir))
         (stdin (merge-pathnames \"stdin.raw\" dir)) (record (merge-pathnames \"record.sexp\" dir))
         (argv (list \"/opt/homebrew/bin/sbcl\" \"--dynamic-space-size\" \"1024\" \"--noinform\"
                     \"--no-userinit\" \"--no-sysinit\" \"--script\"
                     (namestring (merge-pathnames \"child.lisp\" *record-base*)) (namestring dir)))
         (before (snapshots)) (handoff (kernel-handoff)))
    (when (probe-file dir) (error \"Exclusive run directory already exists\"))
    (ensure-directories-exist stdin)
    (with-open-file (s stdin :direction :output :if-exists :error :if-does-not-exist :create)
      (write-string \"\" s))
    (dump (merge-pathnames \"preregistered.sexp\" dir)
          (list :schema-version 1 :status :preregistered :operation :compile-and-check
                :method \"metodo-check-lettura-buffer.md\" :cwd (namestring *check-root*)
                :argv argv :stdin \"\" :source-before before
                :kernel-handoff handoff
                :budgets (list :child-seconds 90 :parent-seconds 105 :cleanup-seconds 5
                               :assertions 200000 :campaign-steps 2048)))
    (multiple-value-bind (exit failure) (run-bounded argv stdin stdout stderr)
      (let* ((after (snapshots)) (out-text (if (probe-file stdout) (file-text stdout) \"\"))
             (err-text (if (probe-file stderr) (file-text stderr) \"\"))
             (decoded (decode-output out-text))
             (status (if (and (= exit 0) (eq failure :none) (equal before after)
                              (eq (getf decoded :status) :ok)) :ok :error)))
        (dump record (list :schema-version 1 :status status :operation :compile-and-check
                           :argv argv :stdin \"\" :source-before before :source-after after
                           :kernel-handoff handoff
                           :source-stable (if (equal before after) :true :false)
                           :stdout-file (namestring stdout) :stderr-file (namestring stderr)
                           :stdout out-text :stderr err-text :exit-code exit
                           :process-error failure :decoded decoded))
        (dump (merge-pathnames \"decoded.sexp\" dir) decoded)
        ;; Independent decoder is another clean SBCL process with no spike packages.
        (let* ((decode-argv (list \"/opt/homebrew/bin/sbcl\" \"--noinform\" \"--no-userinit\" \"--no-sysinit\"
                                  \"--script\" (namestring (merge-pathnames \"decode.lisp\" *record-base*))
                                  (namestring record) (namestring (merge-pathnames \"decoded.sexp\" dir))))
               (decode-out (merge-pathnames \"readback.raw\" dir))
               (decode-err (merge-pathnames \"readback-stderr.raw\" dir)))
          (dump (merge-pathnames \"readback-preregistered.sexp\" dir)
                (list :schema-version 1 :operation :readback :argv decode-argv :stdin \"\"))
          (multiple-value-bind (decode-exit decode-failure) (run-bounded decode-argv stdin decode-out decode-err)
            (let ((readback (decode-output (file-text decode-out))))
              (dump (merge-pathnames \"readback-record.sexp\" dir)
                    (list :schema-version 1 :operation :readback :argv decode-argv :stdin \"\"
                          :exit-code decode-exit :process-error decode-failure
                          :stdout (file-text decode-out) :stderr (file-text decode-err) :decoded readback))
              (format t \"~S~%\" (list :schema-version 1 :status status :exit-code exit
                                     :readback-status (getf readback :status) :record (namestring record)))
              (unless (and (eq status :ok) (= decode-exit 0) (eq decode-failure :none)
                           (eq (getf readback :status) :ok))
                (sb-ext:exit :code 1)))))))))
")
  (:PATH
   #A((146) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/check-lettura-buffer-campagna-20261008-01/child.lisp")
   :HASH-ALGORITHM "MD5" :HASH
   #A((32) BASE-CHAR . "deb7b86ed7480b52ab518e7a61e1f23b") :CONTENTS
   "(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 1) (debug 2)))
(let ((*read-eval* nil) (*print-readably* t) (*print-pretty* t))
  (handler-case
      (let* ((run-dir (pathname (second sb-ext:*posix-argv*)))
             (root (pathname \"/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/\"))
             (base (merge-pathnames \"spikes/SPK-01-primary-index/\" root)))
        (sb-ext:with-timeout 90
          (handler-bind ((warning (lambda (c) (error \"Strict compilation warning (~A): ~A\" (type-of c) c))))
            (dolist (name '(\"core\" \"lettura-buffer\" \"check-lettura-buffer\"))
              (multiple-value-bind (output warnings failure)
                  (let ((*standard-output* *error-output*))
                    (compile-file (merge-pathnames (concatenate 'string name \".lisp\") base)
                                  :output-file (merge-pathnames (concatenate 'string name \".fasl\") run-dir)
                                  :verbose nil :print nil))
                (when (or warnings failure (null output)) (error \"Strict compilation failed: ~A\" name))
                (load output :verbose nil :print nil)))
            (let* ((package (or (find-package \"ARCDOCDB.SPK01.CHECK-LETTURA-BUFFER\")
                                (error \"CHECK package missing\")))
                   (symbol (or (find-symbol \"CHECK\" package) (error \"CHECK missing\")))
                   (report (funcall (symbol-function symbol))))
              (unless (eq (getf report :status) :ok) (error \"CHECK did not finish\"))
              (write report) (terpri) (finish-output)))))
    (error (c)
      (write (list :schema-version 1 :status :error
                   :condition-type (string (type-of c)) :condition (princ-to-string c)))
      (terpri) (finish-output) (sb-ext:exit :code 1))))
")
  (:PATH
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/check-lettura-buffer-campagna-20261008-01/decode.lisp")
   :HASH-ALGORITHM "MD5" :HASH
   #A((32) BASE-CHAR . "fc85393333c7fcd9d0c1c6637e90f1bc") :CONTENTS
   "(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 1) (debug 2)))
(defun allowed-data (x)
  (typecase x
    (null t) (cons (and (allowed-data (car x)) (allowed-data (cdr x))))
    (string t) (number t) (symbol (keywordp x)) (t nil)))
(defun read-one (path)
  (with-open-file (s path)
    (let ((*read-eval* nil) (end (list :end)))
      (let ((data (read s nil end)))
        (when (eq data end) (error \"Empty structured output\"))
        (unless (allowed-data data) (error \"Foreign symbol/object in data\"))
        (unless (eq (read s nil end) end) (error \"Trailing structured output\"))
        data))))
(let ((*read-eval* nil) (*print-readably* t) (*print-pretty* t))
  (handler-case
      (progn
        (when (some (lambda (name) (find-package name))
                    '(\"ARCDOCDB.SPK01\" \"ARCDOCDB.SPK01.LETTURA-BUFFER\"
                      \"ARCDOCDB.SPK01.CHECK-LETTURA-BUFFER\"))
          (error \"Decoder contains spike package\"))
        (let* ((record (read-one (second sb-ext:*posix-argv*)))
               (data (read-one (third sb-ext:*posix-argv*))))
          (write (list :schema-version 1 :status :ok :read-eval :false
                       :spike-packages :absent :record-status (getf record :status) :decoded data))
          (terpri) (finish-output)))
    (error (c)
      (write (list :schema-version 1 :status :error :condition-type (string (type-of c))
                   :condition (princ-to-string c)))
      (terpri) (finish-output) (sb-ext:exit :code 1))))
"))
 :KERNEL-HANDOFF
 (:SCHEMA-VERSION 1 :KIND :HANDOFF-TO-CHECK-AGENT :RECIPIENT "B" :STATUS :READY
  :KERNEL
  "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/lettura-buffer.lisp"
  :KERNEL-GIT-BLOB "28002439f931387cd6baebcf57adde7e88e2961b" :CORE-GIT-BLOB
  "c019f6ad53e173a0d336a4dbfaf903e274a66f08" :METHOD-GIT-BLOB
  "f7d9674884267ad4d22f962c762e1995b749fb44" :LAST-COMPILATION "c3"
  :COMPILATION-STATUS :OK :WARNINGS :ABSENT :STYLE-WARNINGS :ABSENT
  :SOURCE-STABILITY :STABLE :KERNEL-STATE :FROZEN :METHOD-STATE :FROZEN
  :MESSAGE
  "Kernel completo e congelato con i commenti REQ/Proposta richiesti dal parent. C3 ha compilato core e variante senza warning/style-warning, ha caricato i FASL e ha disassemblato LEGGI; sorgenti stabili. B può eseguire CHECK sugli hash finali C3. Solo modifiche documentali rispetto a C2, algoritmo invariato. A aggiunge soltanto artefatti finali in out e termina; nessun CHECK o BENCH eseguito da A."
  :API
  "ARCDOCDB.SPK01.LETTURA-BUFFER:LEGGI (indice chiave destinazione &key (attempts 8) after-fragment after-fields) => (values status-keyword retry-fixnum)"
  :DESTINATION
  "(simple-array (unsigned-byte 64) (4)): [CSN, location, length, end-CSN]"
  :COMPILATION-RECORD
  "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/lettura-buffer-campagna-20261008-01/c3/record.sexp")
 :SOURCE-STABLE :TRUE :STDOUT-FILE
 #A((149) BASE-CHAR
    . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/check-lettura-buffer-campagna-20261008-01/k1/stdout.raw")
 :STDERR-FILE
 #A((149) BASE-CHAR
    . "/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB/spikes/SPK-01-primary-index/out/check-lettura-buffer-campagna-20261008-01/k1/stderr.raw")
 :STDOUT
 "(:SCHEMA-VERSION 1 :STATUS :OK :SPIKE :SPK-01 :PHASE 0 :LAYOUT :V1 :LAYOUTS
 (:WORDS4 :WORDS5-EXTRA-END) :VERIFIES-FORMAT-V2 :FALSE :SAFETY 3
 :BENCH-EXECUTED :FALSE :KERNEL \"ARCDOCDB.SPK01.LETTURA-BUFFER:LEGGI\" :BASELINE
 \"ARCDOCDB.SPK01:LEGGI\" :MODEL :INDEPENDENT-MAP-WITH-JOURNAL-REPLAY
 :PRINCIPAL-CASES 54 :NEGATIVE-CONTROLS 79 :NEGATIVE-COUNTS
 (:INGRESS 46 :WRITER 16 :BUDGET 1 :MUTANTS 16) :READ-COMPARISONS 2032
 :CAMPAIGNS
 ((:WORDS 4 :SEED 424242 :STEPS 1024 :BLOCKS 128 :INITIAL-PUTS 64
   :CAMPAIGN-PUTS 384 :CAMPAIGN-DELETES 128 :CAMPAIGN-READS 512 :INITIAL-READS
   64 :FINAL-READS 384 :READ-COMPARISONS 960 :HISTORY-EVENTS 576 :FINAL-LIVE 64
   :FINAL-STATE 2846191538 :SPLITS 6 :REBUILDS 18)
  (:WORDS 5 :SEED 424242 :STEPS 1024 :BLOCKS 128 :INITIAL-PUTS 64
   :CAMPAIGN-PUTS 384 :CAMPAIGN-DELETES 128 :CAMPAIGN-READS 512 :INITIAL-READS
   64 :FINAL-READS 384 :READ-COMPARISONS 960 :HISTORY-EVENTS 576 :FINAL-LIVE 64
   :FINAL-STATE 2846191538 :SPLITS 6 :REBUILDS 18))
 :BOUNDARIES
 ((:WORDS 4 :RECORDS 6 :ZERO-KEY :COVERED :ALL-FF-KEY :COVERED :MAX64
   18446744073709551615 :LENGTH-MAX 16777215 :DELETE-ABSENT :COVERED)
  (:WORDS 5 :RECORDS 6 :ZERO-KEY :COVERED :ALL-FF-KEY :COVERED :MAX64
   18446744073709551615 :LENGTH-MAX 16777215 :DELETE-ABSENT :COVERED))
 :REBUILDS
 ((:WORDS 4 :TOMBSTONE-REBUILDS 1 :SEQUENCE-REBUILDS 1)
  (:WORDS 5 :TOMBSTONE-REBUILDS 1 :SEQUENCE-REBUILDS 1))
 :COLLISIONS
 ((:WORDS 4 :FINGERPRINT 53 :PROBE-START 15 :OCCUPIED-SLOTS (15 0 1 2 3 4)
   :KEYS-FOUND 7 :SEARCH-CANDIDATES 11870 :CANDIDATE-CALLBACKS :VERIFIED)
  (:WORDS 5 :FINGERPRINT 53 :PROBE-START 15 :OCCUPIED-SLOTS (15 0 1 2 3 4)
   :KEYS-FOUND 7 :SEARCH-CANDIDATES 11870 :CANDIDATE-CALLBACKS :VERIFIED))
 :WITNESSES
 ((:WORDS 4 :CASES
   ((:CASE :ROOT-HIT :WORDS 4 :STATUS :HIT :RETRIES 1 :FRAGMENT-CALLBACKS 2
     :FIELDS-CALLBACKS 2 :BUFFER-PUBLICATION :VALIDATED)
    (:CASE :ROOT-MISS :WORDS 4 :STATUS :HIT :RETRIES 1 :FRAGMENT-CALLBACKS 2
     :FIELDS-CALLBACKS 1 :BUFFER-PUBLICATION :VALIDATED)
    (:CASE :FIELDS-UPDATE :WORDS 4 :STATUS :HIT :RETRIES 1 :FRAGMENT-CALLBACKS
     2 :FIELDS-CALLBACKS 2 :BUFFER-PUBLICATION :VALIDATED)
    (:CASE :FIELDS-DELETE :WORDS 4 :STATUS :MISS :RETRIES 1 :FRAGMENT-CALLBACKS
     2 :FIELDS-CALLBACKS 1 :BUFFER-PUBLICATION :VALIDATED)
    (:CASE :FIELDS-ODD :WORDS 4 :STATUS :RETRY-LIMIT :RETRIES 8
     :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 1 :BUFFER-PUBLICATION :VALIDATED)
    (:CASE :ROOT-CHURN :WORDS 4 :STATUS :RETRY-LIMIT :RETRIES 8
     :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 8 :BUFFER-PUBLICATION :VALIDATED)
    (:CASE :FIELDS-CHURN :WORDS 4 :STATUS :RETRY-LIMIT :RETRIES 8
     :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 8 :BUFFER-PUBLICATION :VALIDATED)
    (:CASE :ERROR-FRAGMENT :WORDS 4 :STATUS :ORIGINAL-ERROR :RETRIES
     :NOT-RETURNED :FRAGMENT-CALLBACKS 1 :FIELDS-CALLBACKS 0
     :BUFFER-PUBLICATION :VALIDATED)
    (:CASE :ERROR-FIELDS :WORDS 4 :STATUS :ORIGINAL-ERROR :RETRIES
     :NOT-RETURNED :FRAGMENT-CALLBACKS 1 :FIELDS-CALLBACKS 1
     :BUFFER-PUBLICATION :VALIDATED)))
  (:WORDS 5 :CASES
   ((:CASE :ROOT-HIT :WORDS 5 :STATUS :HIT :RETRIES 1 :FRAGMENT-CALLBACKS 2
     :FIELDS-CALLBACKS 2 :BUFFER-PUBLICATION :VALIDATED)
    (:CASE :ROOT-MISS :WORDS 5 :STATUS :HIT :RETRIES 1 :FRAGMENT-CALLBACKS 2
     :FIELDS-CALLBACKS 1 :BUFFER-PUBLICATION :VALIDATED)
    (:CASE :FIELDS-UPDATE :WORDS 5 :STATUS :HIT :RETRIES 1 :FRAGMENT-CALLBACKS
     2 :FIELDS-CALLBACKS 2 :BUFFER-PUBLICATION :VALIDATED)
    (:CASE :FIELDS-DELETE :WORDS 5 :STATUS :MISS :RETRIES 1 :FRAGMENT-CALLBACKS
     2 :FIELDS-CALLBACKS 1 :BUFFER-PUBLICATION :VALIDATED)
    (:CASE :FIELDS-ODD :WORDS 5 :STATUS :RETRY-LIMIT :RETRIES 8
     :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 1 :BUFFER-PUBLICATION :VALIDATED)
    (:CASE :ROOT-CHURN :WORDS 5 :STATUS :RETRY-LIMIT :RETRIES 8
     :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 8 :BUFFER-PUBLICATION :VALIDATED)
    (:CASE :FIELDS-CHURN :WORDS 5 :STATUS :RETRY-LIMIT :RETRIES 8
     :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 8 :BUFFER-PUBLICATION :VALIDATED)
    (:CASE :ERROR-FRAGMENT :WORDS 5 :STATUS :ORIGINAL-ERROR :RETRIES
     :NOT-RETURNED :FRAGMENT-CALLBACKS 1 :FIELDS-CALLBACKS 0
     :BUFFER-PUBLICATION :VALIDATED)
    (:CASE :ERROR-FIELDS :WORDS 5 :STATUS :ORIGINAL-ERROR :RETRIES
     :NOT-RETURNED :FRAGMENT-CALLBACKS 1 :FIELDS-CALLBACKS 1
     :BUFFER-PUBLICATION :VALIDATED))))
 :RETRY-BUDGETS
 ((:WORDS 4 :ATTEMPTS (1 2 3 4 5 6 7 8) :STATUS :RETRY-LIMIT)
  (:WORDS 5 :ATTEMPTS (1 2 3 4 5 6 7 8) :STATUS :RETRY-LIMIT))
 :INVALID-INPUTS
 ((:WORDS 4 :CASES 23 :REJECTIONS
   ((:INDEX
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:KEY
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:KEY
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:KEY
     (:REJECTION-TYPE #A((13) BASE-CHAR . \"LIMITE-INDICE\") :DESTINATION
      :UNCHANGED))
    (:KEY
     (:REJECTION-TYPE #A((13) BASE-CHAR . \"LIMITE-INDICE\") :DESTINATION
      :UNCHANGED))
    (:KEY
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:KEY
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:DESTINATION
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:DESTINATION
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:DESTINATION
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:DESTINATION
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:DESTINATION
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:DESTINATION
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:DESTINATION
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:DESTINATION
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:ATTEMPTS
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:ATTEMPTS
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:ATTEMPTS
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:ATTEMPTS
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:ATTEMPTS
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:AFTER-FRAGMENT
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:AFTER-FIELDS
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:UNKNOWN-KEYWORD
     (:REJECTION-TYPE #A((24) BASE-CHAR . \"UNKNOWN-KEYWORD-ARGUMENT\")
      :DESTINATION :UNCHANGED))))
  (:WORDS 5 :CASES 23 :REJECTIONS
   ((:INDEX
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:KEY
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:KEY
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:KEY
     (:REJECTION-TYPE #A((13) BASE-CHAR . \"LIMITE-INDICE\") :DESTINATION
      :UNCHANGED))
    (:KEY
     (:REJECTION-TYPE #A((13) BASE-CHAR . \"LIMITE-INDICE\") :DESTINATION
      :UNCHANGED))
    (:KEY
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:KEY
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:DESTINATION
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:DESTINATION
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:DESTINATION
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:DESTINATION
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:DESTINATION
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:DESTINATION
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:DESTINATION
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:DESTINATION
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:ATTEMPTS
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:ATTEMPTS
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:ATTEMPTS
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:ATTEMPTS
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:ATTEMPTS
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:AFTER-FRAGMENT
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:AFTER-FIELDS
     (:REJECTION-TYPE #A((10) BASE-CHAR . \"TYPE-ERROR\") :DESTINATION
      :UNCHANGED))
    (:UNKNOWN-KEYWORD
     (:REJECTION-TYPE #A((24) BASE-CHAR . \"UNKNOWN-KEYWORD-ARGUMENT\")
      :DESTINATION :UNCHANGED)))))
 :WRITER-REJECTIONS
 ((:WORDS 4 :CASES 6 :ORIGINAL-RECORD :PRESERVED)
  (:WORDS 5 :CASES 6 :ORIGINAL-RECORD :PRESERVED))
 :WRITER-BUDGETS
 ((:WORDS 4 :DEPTH-BUDGET :EXPLICIT-ERROR :MEMORY-BUDGET :EXPLICIT-ERROR
   :PARTIAL-SUCCESS :FALSE :PRESERVED-RECORDS 7)
  (:WORDS 5 :DEPTH-BUDGET :EXPLICIT-ERROR :MEMORY-BUDGET :EXPLICIT-ERROR
   :PARTIAL-SUCCESS :FALSE :PRESERVED-RECORDS 7))
 :MUTANTS
 ((:WORDS 4 :CASES
   ((:MUTATION :NO-ROOT :WITNESS :ROOT-HIT :REJECTED-BY :RETRY-COUNT)
    (:MUTATION :NO-ROOT :WITNESS :ROOT-MISS :REJECTED-BY :STATUS)
    (:MUTATION :NO-SEQLOCK :WITNESS :FIELDS-UPDATE :REJECTED-BY :RETRY-COUNT)
    (:MUTATION :NO-SEQLOCK :WITNESS :FIELDS-DELETE :REJECTED-BY :STATUS)
    (:MUTATION :NO-SEQLOCK :WITNESS :FIELDS-ODD :REJECTED-BY :STATUS)
    (:MUTATION :TRUNCATE-U64 :WITNESS :BOUNDARY :REJECTED-BY :PAYLOAD)
    (:MUTATION :EARLY-DESTINATION :WITNESS :FIELDS-UPDATE :REJECTED-BY
     :DESTINATION-BEFORE-VALIDATION)
    (:MUTATION :EARLY-DESTINATION :WITNESS :FIELDS-DELETE :REJECTED-BY
     :DESTINATION-BEFORE-VALIDATION)))
  (:WORDS 5 :CASES
   ((:MUTATION :NO-ROOT :WITNESS :ROOT-HIT :REJECTED-BY :RETRY-COUNT)
    (:MUTATION :NO-ROOT :WITNESS :ROOT-MISS :REJECTED-BY :STATUS)
    (:MUTATION :NO-SEQLOCK :WITNESS :FIELDS-UPDATE :REJECTED-BY :RETRY-COUNT)
    (:MUTATION :NO-SEQLOCK :WITNESS :FIELDS-DELETE :REJECTED-BY :STATUS)
    (:MUTATION :NO-SEQLOCK :WITNESS :FIELDS-ODD :REJECTED-BY :STATUS)
    (:MUTATION :TRUNCATE-U64 :WITNESS :BOUNDARY :REJECTED-BY :PAYLOAD)
    (:MUTATION :EARLY-DESTINATION :WITNESS :FIELDS-UPDATE :REJECTED-BY
     :DESTINATION-BEFORE-VALIDATION)
    (:MUTATION :EARLY-DESTINATION :WITNESS :FIELDS-DELETE :REJECTED-BY
     :DESTINATION-BEFORE-VALIDATION))))
 :BUDGET-EXHAUSTION
 (:STATUS :EXPLICIT-ERROR :CONDITION-TYPE \"CHECK-BUDGET-EXHAUSTED\") :BUDGET
 (:MAXIMUM 200000 :REMAINING 173773 :ASSERTIONS 26227) :LIMITATIONS
 (:FINITE-CAMPAIGN :SYNCHRONOUS-INTERLEAVINGS :NO-HARDWARE-MEMORY-MODEL-PROOF
  :NO-THREAD-STRESS))
"
 :STDERR "" :EXIT-CODE 0 :PROCESS-ERROR :NONE :DECODED
 (:SCHEMA-VERSION 1 :STATUS :OK :SPIKE :SPK-01 :PHASE 0 :LAYOUT :V1 :LAYOUTS
  (:WORDS4 :WORDS5-EXTRA-END) :VERIFIES-FORMAT-V2 :FALSE :SAFETY 3
  :BENCH-EXECUTED :FALSE :KERNEL "ARCDOCDB.SPK01.LETTURA-BUFFER:LEGGI"
  :BASELINE "ARCDOCDB.SPK01:LEGGI" :MODEL :INDEPENDENT-MAP-WITH-JOURNAL-REPLAY
  :PRINCIPAL-CASES 54 :NEGATIVE-CONTROLS 79 :NEGATIVE-COUNTS
  (:INGRESS 46 :WRITER 16 :BUDGET 1 :MUTANTS 16) :READ-COMPARISONS 2032
  :CAMPAIGNS
  ((:WORDS 4 :SEED 424242 :STEPS 1024 :BLOCKS 128 :INITIAL-PUTS 64
    :CAMPAIGN-PUTS 384 :CAMPAIGN-DELETES 128 :CAMPAIGN-READS 512 :INITIAL-READS
    64 :FINAL-READS 384 :READ-COMPARISONS 960 :HISTORY-EVENTS 576 :FINAL-LIVE
    64 :FINAL-STATE 2846191538 :SPLITS 6 :REBUILDS 18)
   (:WORDS 5 :SEED 424242 :STEPS 1024 :BLOCKS 128 :INITIAL-PUTS 64
    :CAMPAIGN-PUTS 384 :CAMPAIGN-DELETES 128 :CAMPAIGN-READS 512 :INITIAL-READS
    64 :FINAL-READS 384 :READ-COMPARISONS 960 :HISTORY-EVENTS 576 :FINAL-LIVE
    64 :FINAL-STATE 2846191538 :SPLITS 6 :REBUILDS 18))
  :BOUNDARIES
  ((:WORDS 4 :RECORDS 6 :ZERO-KEY :COVERED :ALL-FF-KEY :COVERED :MAX64
    18446744073709551615 :LENGTH-MAX 16777215 :DELETE-ABSENT :COVERED)
   (:WORDS 5 :RECORDS 6 :ZERO-KEY :COVERED :ALL-FF-KEY :COVERED :MAX64
    18446744073709551615 :LENGTH-MAX 16777215 :DELETE-ABSENT :COVERED))
  :REBUILDS
  ((:WORDS 4 :TOMBSTONE-REBUILDS 1 :SEQUENCE-REBUILDS 1)
   (:WORDS 5 :TOMBSTONE-REBUILDS 1 :SEQUENCE-REBUILDS 1))
  :COLLISIONS
  ((:WORDS 4 :FINGERPRINT 53 :PROBE-START 15 :OCCUPIED-SLOTS (15 0 1 2 3 4)
    :KEYS-FOUND 7 :SEARCH-CANDIDATES 11870 :CANDIDATE-CALLBACKS :VERIFIED)
   (:WORDS 5 :FINGERPRINT 53 :PROBE-START 15 :OCCUPIED-SLOTS (15 0 1 2 3 4)
    :KEYS-FOUND 7 :SEARCH-CANDIDATES 11870 :CANDIDATE-CALLBACKS :VERIFIED))
  :WITNESSES
  ((:WORDS 4 :CASES
    ((:CASE :ROOT-HIT :WORDS 4 :STATUS :HIT :RETRIES 1 :FRAGMENT-CALLBACKS 2
      :FIELDS-CALLBACKS 2 :BUFFER-PUBLICATION :VALIDATED)
     (:CASE :ROOT-MISS :WORDS 4 :STATUS :HIT :RETRIES 1 :FRAGMENT-CALLBACKS 2
      :FIELDS-CALLBACKS 1 :BUFFER-PUBLICATION :VALIDATED)
     (:CASE :FIELDS-UPDATE :WORDS 4 :STATUS :HIT :RETRIES 1 :FRAGMENT-CALLBACKS
      2 :FIELDS-CALLBACKS 2 :BUFFER-PUBLICATION :VALIDATED)
     (:CASE :FIELDS-DELETE :WORDS 4 :STATUS :MISS :RETRIES 1
      :FRAGMENT-CALLBACKS 2 :FIELDS-CALLBACKS 1 :BUFFER-PUBLICATION :VALIDATED)
     (:CASE :FIELDS-ODD :WORDS 4 :STATUS :RETRY-LIMIT :RETRIES 8
      :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 1 :BUFFER-PUBLICATION :VALIDATED)
     (:CASE :ROOT-CHURN :WORDS 4 :STATUS :RETRY-LIMIT :RETRIES 8
      :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 8 :BUFFER-PUBLICATION :VALIDATED)
     (:CASE :FIELDS-CHURN :WORDS 4 :STATUS :RETRY-LIMIT :RETRIES 8
      :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 8 :BUFFER-PUBLICATION :VALIDATED)
     (:CASE :ERROR-FRAGMENT :WORDS 4 :STATUS :ORIGINAL-ERROR :RETRIES
      :NOT-RETURNED :FRAGMENT-CALLBACKS 1 :FIELDS-CALLBACKS 0
      :BUFFER-PUBLICATION :VALIDATED)
     (:CASE :ERROR-FIELDS :WORDS 4 :STATUS :ORIGINAL-ERROR :RETRIES
      :NOT-RETURNED :FRAGMENT-CALLBACKS 1 :FIELDS-CALLBACKS 1
      :BUFFER-PUBLICATION :VALIDATED)))
   (:WORDS 5 :CASES
    ((:CASE :ROOT-HIT :WORDS 5 :STATUS :HIT :RETRIES 1 :FRAGMENT-CALLBACKS 2
      :FIELDS-CALLBACKS 2 :BUFFER-PUBLICATION :VALIDATED)
     (:CASE :ROOT-MISS :WORDS 5 :STATUS :HIT :RETRIES 1 :FRAGMENT-CALLBACKS 2
      :FIELDS-CALLBACKS 1 :BUFFER-PUBLICATION :VALIDATED)
     (:CASE :FIELDS-UPDATE :WORDS 5 :STATUS :HIT :RETRIES 1 :FRAGMENT-CALLBACKS
      2 :FIELDS-CALLBACKS 2 :BUFFER-PUBLICATION :VALIDATED)
     (:CASE :FIELDS-DELETE :WORDS 5 :STATUS :MISS :RETRIES 1
      :FRAGMENT-CALLBACKS 2 :FIELDS-CALLBACKS 1 :BUFFER-PUBLICATION :VALIDATED)
     (:CASE :FIELDS-ODD :WORDS 5 :STATUS :RETRY-LIMIT :RETRIES 8
      :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 1 :BUFFER-PUBLICATION :VALIDATED)
     (:CASE :ROOT-CHURN :WORDS 5 :STATUS :RETRY-LIMIT :RETRIES 8
      :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 8 :BUFFER-PUBLICATION :VALIDATED)
     (:CASE :FIELDS-CHURN :WORDS 5 :STATUS :RETRY-LIMIT :RETRIES 8
      :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 8 :BUFFER-PUBLICATION :VALIDATED)
     (:CASE :ERROR-FRAGMENT :WORDS 5 :STATUS :ORIGINAL-ERROR :RETRIES
      :NOT-RETURNED :FRAGMENT-CALLBACKS 1 :FIELDS-CALLBACKS 0
      :BUFFER-PUBLICATION :VALIDATED)
     (:CASE :ERROR-FIELDS :WORDS 5 :STATUS :ORIGINAL-ERROR :RETRIES
      :NOT-RETURNED :FRAGMENT-CALLBACKS 1 :FIELDS-CALLBACKS 1
      :BUFFER-PUBLICATION :VALIDATED))))
  :RETRY-BUDGETS
  ((:WORDS 4 :ATTEMPTS (1 2 3 4 5 6 7 8) :STATUS :RETRY-LIMIT)
   (:WORDS 5 :ATTEMPTS (1 2 3 4 5 6 7 8) :STATUS :RETRY-LIMIT))
  :INVALID-INPUTS
  ((:WORDS 4 :CASES 23 :REJECTIONS
    ((:INDEX
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:KEY
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:KEY
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:KEY
      (:REJECTION-TYPE #A((13) BASE-CHAR . "LIMITE-INDICE") :DESTINATION
       :UNCHANGED))
     (:KEY
      (:REJECTION-TYPE #A((13) BASE-CHAR . "LIMITE-INDICE") :DESTINATION
       :UNCHANGED))
     (:KEY
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:KEY
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:DESTINATION
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:DESTINATION
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:DESTINATION
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:DESTINATION
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:DESTINATION
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:DESTINATION
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:DESTINATION
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:DESTINATION
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:ATTEMPTS
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:ATTEMPTS
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:ATTEMPTS
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:ATTEMPTS
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:ATTEMPTS
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:AFTER-FRAGMENT
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:AFTER-FIELDS
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:UNKNOWN-KEYWORD
      (:REJECTION-TYPE #A((24) BASE-CHAR . "UNKNOWN-KEYWORD-ARGUMENT")
       :DESTINATION :UNCHANGED))))
   (:WORDS 5 :CASES 23 :REJECTIONS
    ((:INDEX
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:KEY
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:KEY
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:KEY
      (:REJECTION-TYPE #A((13) BASE-CHAR . "LIMITE-INDICE") :DESTINATION
       :UNCHANGED))
     (:KEY
      (:REJECTION-TYPE #A((13) BASE-CHAR . "LIMITE-INDICE") :DESTINATION
       :UNCHANGED))
     (:KEY
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:KEY
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:DESTINATION
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:DESTINATION
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:DESTINATION
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:DESTINATION
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:DESTINATION
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:DESTINATION
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:DESTINATION
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:DESTINATION
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:ATTEMPTS
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:ATTEMPTS
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:ATTEMPTS
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:ATTEMPTS
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:ATTEMPTS
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:AFTER-FRAGMENT
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:AFTER-FIELDS
      (:REJECTION-TYPE #A((10) BASE-CHAR . "TYPE-ERROR") :DESTINATION
       :UNCHANGED))
     (:UNKNOWN-KEYWORD
      (:REJECTION-TYPE #A((24) BASE-CHAR . "UNKNOWN-KEYWORD-ARGUMENT")
       :DESTINATION :UNCHANGED)))))
  :WRITER-REJECTIONS
  ((:WORDS 4 :CASES 6 :ORIGINAL-RECORD :PRESERVED)
   (:WORDS 5 :CASES 6 :ORIGINAL-RECORD :PRESERVED))
  :WRITER-BUDGETS
  ((:WORDS 4 :DEPTH-BUDGET :EXPLICIT-ERROR :MEMORY-BUDGET :EXPLICIT-ERROR
    :PARTIAL-SUCCESS :FALSE :PRESERVED-RECORDS 7)
   (:WORDS 5 :DEPTH-BUDGET :EXPLICIT-ERROR :MEMORY-BUDGET :EXPLICIT-ERROR
    :PARTIAL-SUCCESS :FALSE :PRESERVED-RECORDS 7))
  :MUTANTS
  ((:WORDS 4 :CASES
    ((:MUTATION :NO-ROOT :WITNESS :ROOT-HIT :REJECTED-BY :RETRY-COUNT)
     (:MUTATION :NO-ROOT :WITNESS :ROOT-MISS :REJECTED-BY :STATUS)
     (:MUTATION :NO-SEQLOCK :WITNESS :FIELDS-UPDATE :REJECTED-BY :RETRY-COUNT)
     (:MUTATION :NO-SEQLOCK :WITNESS :FIELDS-DELETE :REJECTED-BY :STATUS)
     (:MUTATION :NO-SEQLOCK :WITNESS :FIELDS-ODD :REJECTED-BY :STATUS)
     (:MUTATION :TRUNCATE-U64 :WITNESS :BOUNDARY :REJECTED-BY :PAYLOAD)
     (:MUTATION :EARLY-DESTINATION :WITNESS :FIELDS-UPDATE :REJECTED-BY
      :DESTINATION-BEFORE-VALIDATION)
     (:MUTATION :EARLY-DESTINATION :WITNESS :FIELDS-DELETE :REJECTED-BY
      :DESTINATION-BEFORE-VALIDATION)))
   (:WORDS 5 :CASES
    ((:MUTATION :NO-ROOT :WITNESS :ROOT-HIT :REJECTED-BY :RETRY-COUNT)
     (:MUTATION :NO-ROOT :WITNESS :ROOT-MISS :REJECTED-BY :STATUS)
     (:MUTATION :NO-SEQLOCK :WITNESS :FIELDS-UPDATE :REJECTED-BY :RETRY-COUNT)
     (:MUTATION :NO-SEQLOCK :WITNESS :FIELDS-DELETE :REJECTED-BY :STATUS)
     (:MUTATION :NO-SEQLOCK :WITNESS :FIELDS-ODD :REJECTED-BY :STATUS)
     (:MUTATION :TRUNCATE-U64 :WITNESS :BOUNDARY :REJECTED-BY :PAYLOAD)
     (:MUTATION :EARLY-DESTINATION :WITNESS :FIELDS-UPDATE :REJECTED-BY
      :DESTINATION-BEFORE-VALIDATION)
     (:MUTATION :EARLY-DESTINATION :WITNESS :FIELDS-DELETE :REJECTED-BY
      :DESTINATION-BEFORE-VALIDATION))))
  :BUDGET-EXHAUSTION
  (:STATUS :EXPLICIT-ERROR :CONDITION-TYPE "CHECK-BUDGET-EXHAUSTED") :BUDGET
  (:MAXIMUM 200000 :REMAINING 173773 :ASSERTIONS 26227) :LIMITATIONS
  (:FINITE-CAMPAIGN :SYNCHRONOUS-INTERLEAVINGS :NO-HARDWARE-MEMORY-MODEL-PROOF
   :NO-THREAD-STRESS)))
