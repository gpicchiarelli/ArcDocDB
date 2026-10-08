(:SCHEMA-VERSION 1 :KIND :PORTABLE-EVIDENCE :STATUS :FAILED :REPRESENTATION
 :FOREIGN-SYMBOLS-AS-QUALIFIED-STRINGS :RAW-ORIGINAL
 "(:SOURCE-CONSISTENCY :STABLE :SOURCE-AFTER
 ((:PATH #1=\"spikes/SPK-08-generated-code/impronte.lisp\" :GIT-BLOB
   \"bf62c65738ea6cece85c4281ec74eec2523a8d4b\" :CONTENTS
   \";;;; Phase0: maschere esatte scalar/SWAR, senza integrazione del primary index.
;;; REQ: REQ-SIM-001 REQ-SIM-002 REQ-BEN-002 REQ-VAL-001 REQ-AFF-003 REQ-AFF-008 REQ-AFF-016
(defpackage #:arcdocdb.spk08.impronte
  (:use #:cl) (:export #:check #:bench))
(in-package #:arcdocdb.spk08.impronte)
(declaim (optimize (safety 3) (speed 3) (debug 1)))

(deftype u64 () '(unsigned-byte 64))
(deftype h7 () '(unsigned-byte 7))
(deftype mask16 () '(unsigned-byte 16))
(deftype octets () '(simple-array (unsigned-byte 8) (*)))
(deftype words () '(simple-array (unsigned-byte 64) (*)))
(deftype masks () '(simple-array (unsigned-byte 16) (*)))
(defconstant +empty+ 128)
(defconstant +deleted+ 254)
(defconstant +low7+ #x7f7f7f7f7f7f7f7f)
(defconstant +high+ #x8080808080808080)
(defconstant +ones+ #x0101010101010101)
(defconstant +u64-mask+ #xffffffffffffffff)

(define-condition errore-impronte (error)
  ((motivo :initarg :motivo :reader motivo))
  (:report (lambda (c s) (format s \\\"SPK08 impronte: ~S\\\" (motivo c)))))

(declaim (inline finestra pack8-le zeri-esatti comprimi8 scalar16
                 scalar-u64 typedu64 packedmask16))
(declaim (ftype (function (octets fixnum) null) finestra))
(defun finestra (ctrl start)
  (declare (type octets ctrl) (type fixnum start))
  (unless (<= 0 start (- (length ctrl) 16))
    (error 'errore-impronte :motivo :invalid-window))
  nil)

(declaim (ftype (function (octets fixnum) u64) pack8-le))
(defun pack8-le (ctrl start)
  \\\"Caricamento portabile LE; i controlli degli accessi restano attivi.\\\"
  (declare (type octets ctrl) (type fixnum start))
  (let ((word 0))
    (declare (type u64 word))
    (dotimes (i 8 word)
      (setf word (logior word (ash (aref ctrl (+ start i)) (* 8 i)))))))

(declaim (ftype (function (u64) u64) zeri-esatti))
(defun zeri-esatti (x)
  \\\"Un bit alto per byte zero: ogni addendo di lane è <=254, senza riporto.\\\"
  (declare (type u64 x))
  (logand +high+
          (logxor +u64-mask+
                  (logior x +low7+ (+ (logand x +low7+) +low7+)))))

(declaim (ftype (function (u64) (unsigned-byte 8)) comprimi8))
(defun comprimi8 (high-bits)
  \\\"Conserva solo i bit 7,15,...,63; li porta nelle posizioni 0,...,7.\\\"
  (declare (type u64 high-bits))
  (let* ((x (ash (logand high-bits +high+) -7))
         (y (logand #x0003000300030003 (logior x (ash x -7))))
         (z (logand #x0000000f0000000f (logior y (ash y -14)))))
    (logand #xff (logior z (ash z -28)))))

(declaim (ftype (function (octets fixnum h7) mask16) scalar16 packedmask16)
         (ftype (function (u64 u64 h7) mask16) typedu64 scalar-u64))
(defun scalar16 (ctrl start h)
  \\\"Baseline su 16 byte; bit i = uguaglianza nella posizione i.\\\"
  (declare (type octets ctrl) (type fixnum start) (type h7 h))
  (finestra ctrl start)
  (let ((mask 0))
    (declare (type mask16 mask))
    (dotimes (i 16 mask)
      (when (= h (aref ctrl (+ start i)))
        (setf mask (logior mask (ash 1 i)))))))

(defun scalar-u64 (low high h)
  \\\"Baseline scalare su due parole LE già preparate.\\\"
  (declare (type u64 low high) (type h7 h))
  (let ((mask 0))
    (declare (type mask16 mask))
    (dotimes (i 8 mask)
      (when (= h (ldb (byte 8 (* 8 i)) low))
        (setf mask (logior mask (ash 1 i))))
      (when (= h (ldb (byte 8 (* 8 i)) high))
        (setf mask (logior mask (ash 1 (+ i 8))))))))

(defun typedu64 (low high h)
  \\\"SWAR su due u64; non è SIMD hardware. Restituisce un fixnum mask16.\\\"
  (declare (type u64 low high) (type h7 h))
  (let ((repeated (* h +ones+)))
    (declare (type u64 repeated))
    (logior (comprimi8 (zeri-esatti (logxor low repeated)))
            (ash (comprimi8 (zeri-esatti (logxor high repeated))) 8))))

(defun packedmask16 (ctrl start h)
  \\\"Include il packing dei 16 byte in due parole LE, a safety 3.\\\"
  (declare (type octets ctrl) (type fixnum start) (type h7 h))
  (finestra ctrl start)
  (typedu64 (pack8-le ctrl start) (pack8-le ctrl (+ start 8)) h))

(defun mutante-sottrazione (low high h)
  \\\"Mutante conservato: il prestito genera falsi bit di match. Mai nel BENCH.\\\"
  (declare (type u64 low high) (type h7 h))
  (let ((repeated (* h +ones+)))
    (labels ((word-mask (word)
               (let ((x (logxor word repeated)))
                 (comprimi8 (logand +high+ (lognot x)
                                    (logand +u64-mask+ (- x +ones+)))))))
      (logior (word-mask low) (ash (word-mask high) 8)))))

(defun oracle (ctrl start h)
  \\\"Indipendente: byte, classificazione alto bit e somma di potenze di due.\\\"
  (let ((result 0))
    (loop for i from 0 below 16
          for value = (aref ctrl (+ start i))
          when (and (< value 128) (= value h))
            do (incf result (expt 2 i)))
    result))

(defun passo-lcg (state)
  (declare (type (unsigned-byte 32) state))
  (ldb (byte 32 0) (+ (* state 1664525) 1013904223)))

(defun runtime ()
  (list :lisp (lisp-implementation-type) :version (lisp-implementation-version)
        :os (software-type) :os-version (software-version) :machine (machine-type)
        :machine-version (machine-version) :safety 3 :hardware-simd nil
        :packing-endian :little :host-endian
        #+little-endian :little #-little-endian :not-little-feature
        :internal-time-units-per-second internal-time-units-per-second))

(defun limite-entier (value low high name)
  (unless (and (integerp value) (<= low value high))
    (error 'errore-impronte :motivo (list :invalid-limit name value low high))))

(defun limite-secondes (seconds)
  (unless (and (realp seconds) (< 0 seconds) (<= seconds 300))
    (error 'errore-impronte :motivo (list :invalid-limit :seconds seconds))))

(defun deadline (seconds)
  (+ (get-internal-real-time) (ceiling (* seconds internal-time-units-per-second))))

(declaim (inline respecte-temps))
(defun respecte-temps (end)
  (declare (type fixnum end))
  (when (>= (get-internal-real-time) end)
    (error 'errore-impronte :motivo :time-budget)))

;; La matrice tiene byte, parole LE, query e oracle separati, preallocati.
(defstruct (matrice (:constructor %matrice))
  (ctrl (make-array 0 :element-type '(unsigned-byte 8)) :type octets)
  (offsets (make-array 0 :element-type '(unsigned-byte 8)) :type octets)
  (queries (make-array 0 :element-type '(unsigned-byte 8)) :type octets)
  (low (make-array 0 :element-type '(unsigned-byte 64)) :type words)
  (high (make-array 0 :element-type '(unsigned-byte 64)) :type words)
  (expected (make-array 0 :element-type '(unsigned-byte 16)) :type masks)
  (rows 0 :type fixnum)
  (sum 0 :type fixnum))

(defun valide-bench (rows passes warmup-passes seconds byte-budget)
  \\\"Preflight condiviso; permette di verificare rifiuti senza eseguire BENCH.\\\"
  (limite-entier rows 16 8192 :rows)
  (limite-entier passes 1 1024 :passes)
  (limite-entier warmup-passes 1 64 :warmup-passes)
  (limite-secondes seconds)
  (limite-entier byte-budget 1 67108864 :byte-budget)
  (let ((payload (* rows 104)) ; 2 datasets * (32+1+1+8+8+2) byte/riga.
        (operations (* 8 rows (+ warmup-passes (* 5 passes)))))
    (when (> payload byte-budget)
      (error 'errore-impronte :motivo :payload-budget))
    (when (> operations 200000000)
      (error 'errore-impronte :motivo :operation-budget))
    (values payload operations)))

(defun prepare-matrice (rows dataset)
  (declare (type fixnum rows))
  (let ((m (%matrice :rows rows
                    :ctrl (make-array (* rows 32) :element-type '(unsigned-byte 8)
                                      :initial-element +deleted+)
                    :offsets (make-array rows :element-type '(unsigned-byte 8))
                    :queries (make-array rows :element-type '(unsigned-byte 8))
                    :low (make-array rows :element-type '(unsigned-byte 64))
                    :high (make-array rows :element-type '(unsigned-byte 64))
                    :expected (make-array rows :element-type '(unsigned-byte 16))))
        (state #x6d61736b))
    (declare (type (unsigned-byte 32) state))
    (dotimes (row rows m)
      (let* ((offset (logand row 15)) (start (+ (* row 32) offset))
             (h (if (eq dataset :mixed) (logand (ash (setf state (passo-lcg state)) -16) 127)
                    (if (evenp (floor row 8)) 0 127))))
        (setf (aref (matrice-offsets m) row) offset
              (aref (matrice-queries m) row) h)
        (dotimes (i 16)
          (setf state (passo-lcg state))
          (setf (aref (matrice-ctrl m) (+ start i))
                (if (eq dataset :mixed)
                    (case (mod (+ row i) 8)
                      (0 h) (1 +empty+) (2 +deleted+)
                      (otherwise (ldb (byte 8 16) state)))
                    (case (mod row 8)
                      (0 (if (evenp i) h (logxor h 1)))
                      (1 h)
                      (2 (logxor h 1))
                      (3 (if (evenp i) +empty+ +deleted+))
                      (4 (logior 128 h))
                      (5 (case i (7 h) (8 (logxor h 1)) (otherwise 255)))
                      (6 (if (zerop i) h (logxor h 1)))
                      (otherwise (if (evenp i) 0 127))))))
        (let ((expected (oracle (matrice-ctrl m) start h)))
          (unless (= expected (scalar16 (matrice-ctrl m) start h)
                     (packedmask16 (matrice-ctrl m) start h))
            (error 'errore-impronte :motivo :bench-fixture))
          (setf (aref (matrice-low m) row) (pack8-le (matrice-ctrl m) start)
                (aref (matrice-high m) row) (pack8-le (matrice-ctrl m) (+ start 8))
                (aref (matrice-expected m) row) expected)
          (unless (= expected (scalar-u64 (aref (matrice-low m) row)
                                          (aref (matrice-high m) row) h)
                     (typedu64 (aref (matrice-low m) row)
                               (aref (matrice-high m) row) h))
            (error 'errore-impronte :motivo :bench-word-fixture))
          (incf (matrice-sum m) expected))))))

(defmacro definit-cycle (name expression)
  \\\"Quattro cicli diretti; nessun funcall o costruzione del report nella misura.\\\"
  `(defun ,name (m passes end)
     (declare (type matrice m) (type fixnum passes end))
     (let ((ctrl (matrice-ctrl m)) (offsets (matrice-offsets m))
           (queries (matrice-queries m)) (low (matrice-low m)) (high (matrice-high m))
           (rows (matrice-rows m)) (acc 0) (operations 0))
       (declare (type octets ctrl offsets queries) (type words low high)
                (type fixnum rows acc operations) (ignorable ctrl offsets low high))
       (respecte-temps end)
       (let ((start-ticks (get-internal-real-time))
             (start-bytes (sb-ext:get-bytes-consed)))
         (dotimes (pass passes)
           (dotimes (row rows)
             (incf acc ,expression)
             (incf operations)
             (when (zerop (logand operations 4095)) (respecte-temps end))))
         (let* ((end-bytes (sb-ext:get-bytes-consed))
                (end-ticks (get-internal-real-time))
                (ticks (- end-ticks start-ticks)) (bytes (- end-bytes start-bytes)))
           (respecte-temps end)
           (unless (= acc (* passes (matrice-sum m)))
             (error 'errore-impronte :motivo (list :cycle-checksum ',name acc)))
           (values ticks bytes acc operations))))))

(definit-cycle cycle-scalar16
  (scalar16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definit-cycle cycle-packedmask16
  (packedmask16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definit-cycle cycle-scalar-u64
  (scalar-u64 (aref low row) (aref high row) (aref queries row)))
(definit-cycle cycle-typedu64
  (typedu64 (aref low row) (aref high row) (aref queries row)))

(defun execute-cycle (kernel m passes end)
  \\\"Dispatch prima della misura; il corpo del ciclo chiama direttamente il kernel.\\\"
  (ecase kernel
    (:scalar16 (cycle-scalar16 m passes end))
    (:packedmask16 (cycle-packedmask16 m passes end))
    (:scalar-u64 (cycle-scalar-u64 m passes end))
    (:typedu64 (cycle-typedu64 m passes end))))

(defun bench (&key (rows 1024) (passes 64) (warmup-passes 2)
                   (seconds 60) (byte-budget 16777216))
  \\\"Matrice scalar/SWAR seriale, cinque repliche. Da eseguire soltanto nel parent.\\\"
  (multiple-value-bind (payload total-operations)
      (valide-bench rows passes warmup-passes seconds byte-budget)
    (let* ((end (deadline seconds))
           (mixed (prepare-matrice rows :mixed))
           (adversarial (prepare-matrice rows :adversarial))
           (measurements nil) (observable 0) (warmup-operations 0))
      (respecte-temps end)
      (loop for m in (list mixed adversarial) do
        (dolist (kernel '(:scalar16 :packedmask16 :scalar-u64 :typedu64))
          (multiple-value-bind (ticks bytes checksum operations)
              (execute-cycle kernel m warmup-passes end)
            (declare (ignore ticks bytes))
            (incf observable checksum) (incf warmup-operations operations))))
      (dotimes (replica 5)
        (loop for dataset in '(:mixed :adversarial)
              for m in (list mixed adversarial) for dataset-index from 0 do
          (loop for pair in '((:scalar16 :packedmask16) (:scalar-u64 :typedu64))
                for representation in '(:bytes-with-packing :prepacked-u64)
                for representation-index from 0
                for order = (if (evenp (+ replica dataset-index representation-index))
                                pair (reverse pair)) do
            (loop for kernel in order for order-index from 0 do
              (multiple-value-bind (ticks bytes checksum operations)
                  (execute-cycle kernel m passes end)
                (unless (plusp ticks)
                  (error 'errore-impronte :motivo :clock-resolution))
                (incf observable checksum)
                (push (list :dataset dataset :representation representation :kernel kernel
                            :replica (1+ replica) :order order :order-index order-index
                            :operations operations :ticks ticks :bytes-consed bytes
                            :checksum checksum
                            :ns/op (/ (* ticks 1d9)
                                      (* internal-time-units-per-second operations))
                            :bytes/op (/ bytes (coerce operations 'double-float)))
                      measurements))))))
      (respecte-temps end)
      (unless (= (length measurements) 40)
        (error 'errore-impronte :motivo :incomplete-bench))
      (list :status :ok :module :impronte-scalar-swar :runtime (runtime)
            :rows rows :passes passes :warmup-passes warmup-passes :replicas 5
            :measurements (nreverse measurements) :raw-samples t
            :observable-checksum observable :warmup-operations warmup-operations
            :measured-operations (* 40 rows passes) :total-operations total-operations
            :payload-bytes payload :seed #x6d61736b
            :limits (list :seconds seconds :byte-budget byte-budget :max-operations 200000000
                          :max-block-operations 4096 :cooperative-deadline t
                          :gc-and-scheduling-included t :report-and-fixtures-excluded t
                          :payload-excludes-object-headers t :no-rss t
                          :no-overhead-subtraction t :hardware-simd nil)))))

(defun refuse-dynamique (function args expected-condition input)
  \\\"Argomenti negativi opachi al compilatore; verifica l'assenza di mutazione.\\\"
  (let ((before (copy-seq input)) (caught nil))
    (handler-case (apply (symbol-function function) args)
      (error (c)
        (unless (typep c expected-condition) (error c))
        (setf caught (type-of c))))
    (unless (and caught (equalp before input))
      (error 'errore-impronte :motivo (list :negative-control function args)))
    (list :function function :arguments args :condition caught :input-unchanged t)))

(defun check (&key (max-cases 4000000) (differential-cases 20000) (seconds 120))
  \\\"Campagne esaustive/differenziali limitate, oracle indipendente e mutante.\\\"
  (limite-entier max-cases 1 4000000 :max-cases)
  (limite-entier differential-cases 1 100000 :differential-cases)
  (limite-secondes seconds)
  (let ((ctrl (make-array 64 :element-type '(unsigned-byte 8) :initial-element +empty+))
        (shadow (make-array 64 :element-type '(unsigned-byte 8)))
        (end (deadline seconds)) (cases 0) (campaigns nil) (negatives nil)
        (mutants nil) (state #x1a2b3c4d))
    (declare (type octets ctrl shadow) (type fixnum cases end)
             (type (unsigned-byte 32) state))
    (labels ((verify-group (start h)
               (declare (type fixnum start) (type h7 h))
               (when (>= cases max-cases)
                 (error 'errore-impronte :motivo :case-budget))
               (incf cases)
               (when (zerop (logand cases 4095)) (respecte-temps end))
               (replace shadow ctrl)
               (let* ((expected (oracle ctrl start h))
                      (low (pack8-le ctrl start)) (high (pack8-le ctrl (+ start 8)))
                      (a (scalar16 ctrl start h)) (b (packedmask16 ctrl start h))
                      (c (scalar-u64 low high h)) (d (typedu64 low high h)))
                 (unless (and (= expected a b c d) (equalp shadow ctrl))
                   (error 'errore-impronte
                          :motivo (list :differential cases start h :expected expected
                                        :actual (list a b c d) :ctrl (coerce ctrl 'list))))
                 expected))
             (campaign (name before expected)
               (let ((count (- cases before)))
                 (unless (= count expected)
                   (error 'errore-impronte :motivo (list :campaign-count name count expected)))
                 (push (list :name name :groups count :kernel-comparisons (* count 4)
                             :input-unchanged t) campaigns)))
             (negative (function args condition)
               (push (refuse-dynamique function args condition ctrl) negatives)))
      ;; Tutti i byte/query, ciascuna posizione isolata.
      (let ((before cases))
        (dotimes (h 128)
          (dotimes (position 16)
            (fill ctrl +empty+)
            (dotimes (value 256)
              (setf (aref ctrl position) value)
              (verify-group 0 h))))
        (campaign :all-byte-query-position before (* 128 16 256)))
      ;; Coppie adiacenti, incluse lane 7/8 tra parole; query ai due estremi.
      (let ((before cases))
        (dolist (h '(0 127))
          (dotimes (position 15)
            (fill ctrl +empty+)
            (dotimes (a 256)
              (setf (aref ctrl position) a)
              (dotimes (b 256)
                (setf (aref ctrl (1+ position)) b)
                (verify-group 0 h)))))
        (campaign :all-adjacent-byte-pairs before (* 2 15 256 256)))
      ;; Tutte le coppie ordinate di posizioni su dominio significativo.
      (let ((before cases) (alphabet '(0 1 126 127 128 129 254 255)))
        (dotimes (p 16)
          (dotimes (q 16)
            (dolist (a alphabet)
              (dolist (b alphabet)
                (fill ctrl +empty+)
                (setf (aref ctrl p) a (aref ctrl q) b)
                (dolist (h '(0 1 126 127)) (verify-group 0 h))))))
        (campaign :all-position-pairs-small-domain before (* 16 16 8 8 4)))
      ;; Esaustivo: tutte le parole 4^8, in entrambe le metà.
      (let ((before cases) (alphabet #(0 1 128 254)))
        (dotimes (code 65536)
          (dotimes (half 2)
            (fill ctrl +empty+)
            (dotimes (i 8)
              (setf (aref ctrl (+ (* half 8) i))
                    (aref alphabet (ldb (byte 2 (* 2 i)) code))))
            (dolist (h '(0 1 127)) (verify-group 0 h))))
        (campaign :exhaustive-four-to-eight before (* 65536 2 3)))
      ;; Tutte le mask16, controllo di compressione e dei bit alti.
      (let ((before cases))
        (fill ctrl +deleted+)
        (dotimes (mask 65536)
          (dotimes (i 16) (setf (aref ctrl i) (if (logbitp i mask) 127 +empty+)))
          (unless (= mask (verify-group 0 127))
            (error 'errore-impronte :motivo :compression-golden)))
        (campaign :all-mask16 before 65536))
      ;; Offset 0..31, finestra esatta e padding; golden LE non simmetrico.
      (let ((before cases))
        (dotimes (start 32)
          (fill ctrl +deleted+)
          (dotimes (i 16) (setf (aref ctrl (+ start i)) i))
          (unless (and (= (pack8-le ctrl start) #x0706050403020100)
                       (= (pack8-le ctrl (+ start 8)) #x0f0e0d0c0b0a0908))
            (error 'errore-impronte :motivo :endian-golden))
          (dotimes (h 16)
            (unless (= (verify-group start h) (ash 1 h))
              (error 'errore-impronte :motivo :position-golden))))
        (dolist (h '(0 127))
          (fill ctrl h)
          (unless (= (verify-group 48 h) #xffff)
            (error 'errore-impronte :motivo :full-mask-golden))
          (fill ctrl +empty+) (verify-group 48 h)
          (fill ctrl +deleted+) (verify-group 48 h))
        (campaign :offset-endian-boundaries before 518))
      ;; Stato u32 esplicito, nessun RANDOM/SXHASH e nessun clock negli input.
      (let ((before cases))
        (dotimes (n differential-cases)
          (dotimes (i 64)
            (setf state (passo-lcg state) (aref ctrl i) (ldb (byte 8 16) state)))
          (setf state (passo-lcg state))
          (verify-group (logand n 31) (logand (ash state -16) 127)))
        (campaign :deterministic-differential before differential-cases))
      ;; Testimoni del prestito per ogni coppia nella stessa parola, due query.
      (dolist (h '(0 127))
        (dolist (position '(0 1 2 3 4 5 6 8 9 10 11 12 13 14))
          (fill ctrl +empty+)
          (setf (aref ctrl position) h (aref ctrl (1+ position)) (logxor h 1))
          (let* ((expected (verify-group 0 h))
                 (actual (mutante-sottrazione (pack8-le ctrl 0) (pack8-le ctrl 8) h)))
            (unless (and (/= actual expected) (logbitp (1+ position) actual)
                         (not (logbitp (1+ position) expected)))
              (error 'errore-impronte :motivo :mutant-not-killed))
            (push (list :query h :position position :ctrl (coerce (subseq ctrl 0 16) 'list)
                        :oracle expected :mutant actual :extra-position (1+ position)) mutants))))
      ;; Il prestito non passa fra due parole; il mutante in questo caso concorda.
      (fill ctrl +empty+) (setf (aref ctrl 7) 0 (aref ctrl 8) 1)
      (unless (= (verify-group 0 0)
                 (mutante-sottrazione (pack8-le ctrl 0) (pack8-le ctrl 8) 0))
        (error 'errore-impronte :motivo :word-boundary-mutant))
      ;; Invalid args: runtime safety3, nessuna modifica dei byte sorgenti.
      (dolist (function '(scalar16 packedmask16))
        (dolist (h '(-1 128 255 1/2 :bad))
          (negative function (list ctrl 0 h) 'type-error))
        (dolist (start '(-1 49 64))
          (negative function (list ctrl start 0) 'errore-impronte))
        (dolist (start '(1/2 :bad))
          (negative function (list ctrl start 0) 'type-error))
        (dolist (length '(0 1 15))
          (let ((short (make-array length :element-type '(unsigned-byte 8))))
            (push (refuse-dynamique function (list short 0 0) 'errore-impronte short)
                  negatives)))
        (negative function (list (make-array 16 :initial-element 0) 0 0) 'type-error)
        (negative function (list (make-array '(4 4) :element-type '(unsigned-byte 8)) 0 0)
                  'type-error)
        (negative function (list (make-array 16 :element-type '(unsigned-byte 8)
                                            :fill-pointer 16) 0 0) 'type-error)
        (negative function (list (make-array 16 :element-type '(unsigned-byte 8)
                                            :displaced-to ctrl) 0 0) 'type-error))
      (dolist (function '(scalar-u64 typedu64))
        (dolist (value (list -1 (expt 2 64) 1/2 :bad))
          (negative function (list value 0 0) 'type-error)
          (negative function (list 0 value 0) 'type-error))
        (dolist (h '(-1 128 255 1/2 :bad))
          (negative function (list 0 0 h) 'type-error)))
      ;; Esaurimento: CHECK rifiuta il secondo caso, senza chiamare BENCH.
      (negative 'check '(:max-cases 1 :differential-cases 1 :seconds 120) 'errore-impronte)
      (negative 'check '(:max-cases 0) 'errore-impronte)
      (negative 'check '(:differential-cases 100001) 'errore-impronte)
      (negative 'check '(:seconds 0) 'errore-impronte)
      (negative 'respecte-temps (list (get-internal-real-time)) 'errore-impronte)
      (dolist (args '((15 1 1 60 16777216) (8193 1 1 60 16777216)
                      (16 0 1 60 16777216) (16 1025 1 60 16777216)
                      (16 1 0 60 16777216) (16 1 65 60 16777216)
                      (16 1 1 0 16777216) (16 1 1 301 16777216)
                      (16 1 1 60 0) (16 1 1 60 67108865)
                      (16 1 1 60 1) (8192 1024 64 60 67108864)))
        (negative 'valide-bench args 'errore-impronte))
      (respecte-temps end)
      (setf negatives (nreverse negatives))
      (list :status :ok :module :impronte-scalar-swar :runtime (runtime)
            :groups cases :kernel-comparisons (* 4 cases)
            :campaigns (nreverse campaigns) :differential-seed #x1a2b3c4d
            :final-lcg-state state :negative-controls negatives
            :negative-control-count (length negatives)
            :mutant :borrow-subtraction :mutant-killed-count (length mutants)
            :mutant-witnesses (nreverse mutants) :word-boundary-controls 1
            :mask-api '((scalar16 ctrl start h7) (packedmask16 ctrl start h7)
                        (scalar-u64 low high h7) (typedu64 low high h7))
            :bench-api '(bench &key rows passes warmup-passes seconds byte-budget)
            :bench-executed nil
            :limits (list :max-cases max-cases :differential-cases differential-cases
                          :seconds seconds :checkpoint-groups 4096
                          :cooperative-deadline t :domain-byte-values 256 :query-values 128
                          :group-bytes 16 :packed-words 2 :small-domain-word-states 65536
                          :no-source-mutation t :hardware-simd nil :production-integration nil)
            :disassembly
            (loop for name in '(scalar16 packedmask16 scalar-u64 typedu64
                                cycle-scalar16 cycle-packedmask16 cycle-scalar-u64 cycle-typedu64)
                  collect (list :function name :text
                                (with-output-to-string (*standard-output*)
                                  (disassemble (symbol-function name)))))))))
\")
  (:PATH #2=\"spikes/SPK-08-generated-code/metodo-impronte.md\" :GIT-BLOB
   \"060b10fd79901e6f3a664e28b3c2153c2c8aa214\" :CONTENTS
   \"# SPK-08 — metodo preregistrato per le impronte

;;; REQ: REQ-SIM-001 REQ-SIM-002 REQ-BEN-002 REQ-VAL-001 REQ-AFF-003 REQ-AFF-008 REQ-AFF-016

Registrato prima di qualsiasi compile/CHECK. Ambito Phase0: solo il nuovo
`impronte.lisp`, package `ARCDOCDB.SPK08.IMPRONTE`, export `CHECK` e `BENCH`.
Tutto il lavoro avviene nel checkout isolato
`/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB`.
Common Lisp/SBCL, safety 3, nessuna dipendenza da altri spike e nessuna
integrazione dell'indice. Nessun commit o push.

## Contratto e algoritmo

Un gruppo contiene 16 byte ctrl. Le impronte valide sono 0–127; empty = 128,
deleted = 254. Tutti gli altri byte con alto bit acceso sono esclusi dal match.
La maschera risultante ha il bit i per la posizione i (0–15). Query fuori
0–127, tipi errati e finestre di meno di 16 byte producono errore.
L'input è di sola lettura. La serializzazione delle due parole u64 è
esplicitamente little endian: byte i nei bit 8*i; il risultato non dipende
dall'endian della macchina. Non si usano accessi di memoria non allineati o VOP.

Per x = word XOR query ripetuta, la maschera esatta degli zeri è
`NOT (((x AND 0x7f7f7f7f7f7f7f7f) + 0x7f7f7f7f7f7f7f7f) OR x OR
0x7f7f7f7f7f7f7f7f) AND 0x8080808080808080`.
Ogni somma di lane è al massimo 254: non c'è riporto fra byte.
Tre piegature comprimono gli otto bit alti in un byte; due parole danno u16.
Il mutante `(x - 0x0101010101010101) AND NOT x AND 0x8080808080808080`
conserva il limite del prestito, con x = byte 0 seguito da byte 1: utile come
test di esistenza di uno zero, inadeguato come maschera esatta per posizione.
Il mutante resta una funzione separata, mai una variante selezionabile dei kernel.

Kernel: `scalar16` e `packedmask16` su byte array e offset; `scalar-u64` e
`typedu64` su due u64. Tipi specializzati, safety 3 e chiamate dirette/inline
nei cicli. La compilazione/disassemblato e i campioni di bytes-consed
permettono di valutare le allocazioni; non si presume che una chiamata Lisp
esterna con u64 boxed non allochi. SWAR è aritmetica su parole intere, non
SIMD hardware. Un oracle scalare distinto legge solo i byte e somma potenze
di due, senza riusare packing, compressione o formula SWAR.

## CHECK e budget

1. Strict compile in processo SBCL senza init: warning e style-warning sono
   fatali, oltre ai valori warnings/failure di compile-file. FASL solo in `out/`.
2. Tutti i 256 byte, tutte le 128 query e tutte le 16 posizioni isolate.
3. Tutte le coppie di byte (256²) nelle 15 coppie adiacenti, query 0 e 127;
   comprende il confine fra le parole e ogni posizione con prestito.
4. Tutte le 16² coppie di posizioni, byte nel dominio piccolo
   {0, 1, 126, 127, 128, 129, 254, 255}, query {0, 1, 126, 127}.
5. Tutte le 4^8 parole su {0, 1, 128, 254}, ciascuna nelle due metà, query
   {0, 1, 127}; dominio piccolo interamente enumerato, non campionato.
6. Differenziale più grande: 20.000 gruppi da LCG u32 con seme fisso;
   offset 0–31, byte arbitrari, query 0–127. Fixture golden endian e maschere
   vuota/piena/alternata; tutte le maschere u16 per la compressione.
7. Controlli negativi del mutante, invalid args attraverso chiamata dinamica
   per evitare warning statici intenzionali; confronto integrale input
   prima/dopo, anche sul rifiuto. Rifiuti deterministici di budget CHECK/BENCH
   prima di qualsiasi misura BENCH.

CHECK ha limite massimo 4.000.000 confronti di gruppo, default uguale al
massimo, 20.000 gruppi differenziali (tetto 100.000), 120 secondi (tetto 300).
Scadenza controllata ogni 4096 confronti e alla conclusione, limite cooperativo;
un limite esaurito è errore, mai successo parziale. I conteggi sono riportati
per campagna, con controlli di congruenza. Conservare disassemblato locale
dei quattro kernel e dei cicli diretti. La plist riporta :status :ok solo
dopo tutte le campagne e include limiti e piattaforma reale.

## BENCH da eseguire soltanto nel parent

API prevista: `(bench &key (rows 1024) (passes 64) (warmup-passes 2)
(seconds 60) (byte-budget 16777216))`. Cinque repliche obbligatorie.
Due dataset, misto e avversario (prestiti, hit pieno, miss, speciali, alto bit,
0/127, confine di parola); matrice di byte e parole preallocata, stessi query
e oracle per entrambi i kernel di ciascun confronto. Offset 0–15 su righe
da 32 byte. Packing/preparazione/validazione/oracle/warmup esclusi dalle
misure. Confronti: scalar16/packedmask16 e scalar-u64/typedu64.
Ordine alternato AB/BA per replica e cella della matrice, esplicitamente
riportato. Accumulatore numerico verificato contro oracle e pubblicato.

Ogni campione misura ticks e bytes-consed solo intorno al ciclo diretto;
riporta operazioni effettive, ns/op calcolati, byte totali e per operazione,
checksum, ordine e replica. Non si sottrae un overhead stimato e non si
inventano tempi; ticks = 0 rende la misura non risolta e produce errore.
GC e scheduling durante il ciclo restano inclusi. Allocazioni del report
e fixture escluse; bytes-consed non è RSS. Il ciclo legge i dati preallocati
e produce un checksum fixnum; non crea strutture per chiamata.
I limiti sono rows 16–8192, passes 1–1024, warmup 1–64, seconds >0 e ≤300,
payload byte-budget ≤64 MiB e operazioni totali ≤200.000.000.
La scadenza è cooperativa fra blocchi di al massimo 4096 operazioni, con
stessi controlli nei due cicli; esaurimento segnala errore senza plist :ok.
BENCH restituisce :status :ok, :measurements, limiti e campioni raw,
solo dopo cinque repliche complete per tutte le celle. Non viene eseguito
in questo lavoro, neppure per warmup o smoke test.

## Evidenze e limiti dell'inferenza

Ogni tentativo compile/CHECK, incluso un fallimento, avrà nuovi file ignored
`out/` con schema-version 1, argv e stdin esplicito, ambiente, hash/contenuti
prima/dopo, risultato decodificato, stdout/stderr integrali e limiti.
Il wrapper esistente `tools/record-command.lisp` può registrare il comando;
un driver nuovo in `out/` aggiunge risultato del modulo, warning, source
immutato e log senza troncamento. Driver e stdin vengono inclusi nelle prove.
Nessun file esistente di core/run/suite/tools/docs/ADR/REQ viene modificato.
Alla consegna si elencano tutti i tentativi, i percorsi e i conteggi reali.

Piattaforma osservata inizialmente: Darwin 27.0.0, arm64, SBCL da
`/opt/homebrew/bin/sbcl`. Versione SBCL, CPU, risoluzione clock e feature
endian vengono raccolte dai processi registrati. La prova riguarda questa
piattaforma; non qualifica x86-64, SIMD hardware, l'indice o il motore.
Nessuna superiorità prestazionale prima dei campioni del parent.
\")
  (:PATH #3=\"spikes/SPK-08-generated-code/out/record-impronte.lisp\" :GIT-BLOB
   \"57916fb52bb5c61900f8ec86399df6bbf8c899eb\" :CONTENTS
   \";;;; Driver locale delle sole prove compile/CHECK; nessuna misura BENCH.
(require :asdf)
(require :sb-posix)
(declaim (optimize (safety 3) (debug 3)))
(defparameter *root* #p\\\"/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB/\\\")
(defparameter *source* \\\"spikes/SPK-08-generated-code/impronte.lisp\\\")
(defparameter *method* \\\"spikes/SPK-08-generated-code/metodo-impronte.md\\\")
(defparameter *driver* \\\"spikes/SPK-08-generated-code/out/record-impronte.lisp\\\")

(defun raw-command (argv)
  (string-trim '(#\\\\Space #\\\\Return #\\\\Newline)
               (uiop:run-program argv :output :string :error-output :string)))
(defun contents (path) (uiop:read-file-string path))
(defun snapshot ()
  (loop for path in (list *source* *method* *driver*)
        collect (list :path path :git-blob (raw-command (list \\\"git\\\" \\\"hash-object\\\" \\\"--\\\" path))
                      :contents (contents path))))
(defun save-data (path data)
  (with-open-file (s path :direction :output :if-exists :supersede)
    (let ((*print-readably* t) (*print-pretty* t) (*print-circle* t))
      (write data :stream s) (terpri s))))
(defun save-text (path text)
  (with-open-file (s path :direction :output :if-exists :supersede)
    (write-string text s)))
(defun new-out ()
  (loop for n below 1000
        for dir = (merge-pathnames
                   (format nil \\\"spikes/SPK-08-generated-code/out/~D-impronte-~D-~D/\\\"
                           (get-universal-time) (sb-posix:getpid) n) *root*)
        do (handler-case (progn (sb-posix:mkdir dir #o700) (return-from new-out dir))
             (sb-posix:syscall-error (c)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno c)) (error c)))))
  (error \\\"Esauriti i tentativi di creare il record.\\\"))
(defun observed-environment ()
  (list :cwd (namestring (truename \\\"./\\\")) :lisp (lisp-implementation-type)
        :version (lisp-implementation-version) :os (software-type)
        :os-version (software-version) :machine (machine-type)
        :cpu (raw-command '(\\\"sysctl\\\" \\\"-n\\\" \\\"machdep.cpu.brand_string\\\"))
        :memory-bytes (raw-command '(\\\"sysctl\\\" \\\"-n\\\" \\\"hw.memsize\\\"))
        :logical-cpus (raw-command '(\\\"sysctl\\\" \\\"-n\\\" \\\"hw.logicalcpu\\\"))
        :load-average (raw-command '(\\\"sysctl\\\" \\\"-n\\\" \\\"vm.loadavg\\\"))
        :external-load :uncontrolled :commit (raw-command '(\\\"git\\\" \\\"rev-parse\\\" \\\"HEAD\\\"))
        :internal-time-units-per-second internal-time-units-per-second
        :process-id (sb-posix:getpid) :features *features*
        :inherited-environment
        (loop for name in '(\\\"PATH\\\" \\\"SBCL_HOME\\\" \\\"LANG\\\" \\\"LC_ALL\\\" \\\"LC_CTYPE\\\" \\\"TZ\\\")
              collect (list name (sb-ext:posix-getenv name)))
        :user-init nil :sys-init nil :stdin :eof))

(defun main ()
  (unless (equal (truename \\\"./\\\") (truename *root*))
    (error \\\"Il driver richiede il checkout isolato.\\\"))
  (let* ((args (uiop:command-line-arguments))
         (mode (first args))
         (out (new-out)) (path (merge-pathnames \\\"report.lisp\\\" out))
         (stdout (make-string-output-stream)) (stderr (make-string-output-stream))
         (warnings 0) (style-warnings 0)
         (record (list :schema-version 1 :kind :impronte-compile-check :status :running
                       :command (append (list \\\"/opt/homebrew/bin/sbcl\\\" \\\"--noinform\\\"
                                              \\\"--no-sysinit\\\" \\\"--no-userinit\\\" \\\"--script\\\"
                                              *driver*) args)
                       :runtime-argv sb-ext:*posix-argv*
                       :stdin (list :mode :eof :contents \\\"\\\" :redirect \\\"/dev/null\\\")
                       :environment (observed-environment) :source-before (snapshot)
                       :started-at-universal-time (get-universal-time)
                       :limits '(:safety 3 :warning-fatal t :style-warning-fatal t
                                 :compile-only-this-module t :bench-never-called t
                                 :check-max-cases 4000000 :check-seconds 120
                                 :stdout-truncated nil :stderr-truncated nil
                                 :source-scope :impronte-method-and-driver
                                 :deadline-cooperative t)))
         (start (get-internal-real-time)) (exit-code 0))
    (save-data path record)
    (let ((*standard-output* stdout) (*error-output* stderr) (*trace-output* stderr))
      (handler-case
          (handler-bind
              ((warning (lambda (c)
                          (if (typep c 'style-warning) (incf style-warnings) (incf warnings))
                          (format *error-output* \\\"~&~A: ~A~%\\\" (type-of c) c)
                          (error \\\"Avviso di compilazione/esecuzione fatale: ~A\\\" c))))
            (unless (member mode '(\\\"compile\\\" \\\"compile-check\\\") :test #'equal)
              (error \\\"Modalità non consentita: ~S\\\" mode))
            (let ((fasl (merge-pathnames \\\"impronte.fasl\\\" out)))
              (setf (getf record :compile) (list :status :running :source *source*
                                               :output (namestring fasl)))
              (save-data path record)
              (multiple-value-bind (file warned failed)
                  (compile-file *source* :output-file fasl)
                (setf (getf record :compile)
                      (list :status (if (or warned failed) :failed :ok)
                            :output (and file (namestring file)) :warnings-p warned :failure-p failed))
                (when (or warned failed (null file)) (error \\\"Strict compile fallita.\\\")))
              (when (equal mode \\\"compile-check\\\")
                (load fasl)
                (let* ((package (find-package \\\"ARCDOCDB.SPK08.IMPRONTE\\\"))
                       (fn (find-symbol \\\"CHECK\\\" package))
                       (check-start (get-internal-real-time))
                       (result (funcall fn)))
                  (unless (eq (getf result :status) :ok) (error \\\"CHECK senza :status :ok.\\\"))
                  (setf (getf record :decoded-check) result
                        (getf record :check-seconds)
                        (/ (- (get-internal-real-time) check-start)
                           (coerce internal-time-units-per-second 'double-float)))
                  (save-data (merge-pathnames \\\"check-data.lisp\\\" out)
                             (list :schema-version 1 :kind :module-check :result result))
                  (dolist (item (getf result :disassembly))
                    (save-text (merge-pathnames
                                (format nil \\\"disassembly-~(~A~).txt\\\" (getf item :function)) out)
                               (getf item :text)))
                  (format t \\\"~&CHECK :OK; groups=~D kernels=~D negatives=~D mutants=~D~%\\\"
                          (getf result :groups) (getf result :kernel-comparisons)
                          (getf result :negative-control-count) (getf result :mutant-killed-count))))
              (setf (getf record :status) :ok)))
        (error (c)
          (setf exit-code 1 (getf record :status) :failed
                (getf record :failure) (list :condition (type-of c) :message (princ-to-string c)))
          (format *error-output* \\\"~&FALLIMENTO ~A: ~A~%\\\" (type-of c) c))))
    (let ((out-text (get-output-stream-string stdout)) (err-text (get-output-stream-string stderr)))
      (setf (getf record :stdout) out-text (getf record :stderr) err-text)
      (save-text (merge-pathnames \\\"stdout.txt\\\" out) out-text)
      (save-text (merge-pathnames \\\"stderr.txt\\\" out) err-text))
    (setf (getf record :warning-count) warnings (getf record :style-warning-count) style-warnings
          (getf record :exit-code) exit-code
          (getf record :finished-at-universal-time) (get-universal-time)
          (getf record :wall-seconds)
          (/ (- (get-internal-real-time) start)
             (coerce internal-time-units-per-second 'double-float)))
    (save-data path record)
    (setf (getf record :source-after) (snapshot)
          (getf record :source-consistency)
          (if (equal (getf record :source-before) (getf record :source-after)) :stable :changed))
    (unless (eq (getf record :source-consistency) :stable)
      (setf exit-code 1 (getf record :exit-code) 1 (getf record :status) :source-changed))
    (save-data path record)
    (format t \\\"~&~S; warnings=~D style-warnings=~D; record: ~A~%\\\"
            (getf record :status) warnings style-warnings path)
    (when (getf record :failure) (format t \\\"~S~%\\\" (getf record :failure)))
    (sb-ext:exit :code exit-code)))
(main)
\"))
 :WALL-SECONDS 0.202686d0 :FINISHED-AT-UNIVERSAL-TIME 4000480809 :EXIT-CODE 1
 :STYLE-WARNING-COUNT 1 :WARNING-COUNT 0 :STDERR
 \"REDEFINITION-WITH-DEFMACRO: redefining ARCDOCDB.SPK08.IMPRONTE::DEFINIT-CYCLE in DEFMACRO
FALLIMENTO SIMPLE-ERROR: Avviso di compilazione/esecuzione fatale: redefining ARCDOCDB.SPK08.IMPRONTE::DEFINIT-CYCLE in DEFMACRO
\"
 :STDOUT \"\" :FAILURE
 (:CONDITION SIMPLE-ERROR :MESSAGE
  #A((103) BASE-CHAR
     . \"Avviso di compilazione/esecuzione fatale: redefining ARCDOCDB.SPK08.IMPRONTE::DEFINIT-CYCLE in DEFMACRO\"))
 :COMPILE
 (:STATUS :OK :OUTPUT
  #A((142) BASE-CHAR
     . \"/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB/spikes/SPK-08-generated-code/out/4000480808-impronte-86996-0/impronte.fasl\")
  :WARNINGS-P NIL :FAILURE-P NIL)
 :SCHEMA-VERSION 1 :KIND :IMPRONTE-COMPILE-CHECK :STATUS :FAILED :COMMAND
 (\"/opt/homebrew/bin/sbcl\" \"--noinform\" \"--no-sysinit\" \"--no-userinit\"
  \"--script\" #3# . #4=(#A((13) BASE-CHAR . \"compile-check\")))
 :RUNTIME-ARGV
 (#A((48) BASE-CHAR . \"/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl\")
  . #4#)
 :STDIN (:MODE :EOF :CONTENTS \"\" :REDIRECT \"/dev/null\") :ENVIRONMENT
 (:CWD
  #A((68) BASE-CHAR
     . \"/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB/\")
  :LISP #A((4) BASE-CHAR . \"SBCL\") :VERSION #A((5) BASE-CHAR . \"2.6.9\") :OS
  #A((6) BASE-CHAR . \"Darwin\") :OS-VERSION #A((6) BASE-CHAR . \"27.0.0\")
  :MACHINE #A((5) BASE-CHAR . \"ARM64\") :CPU \"Apple M4\" :MEMORY-BYTES
  \"17179869184\" :LOGICAL-CPUS \"10\" :LOAD-AVERAGE \"{ 3.11 4.49 7.98 }\"
  :EXTERNAL-LOAD :UNCONTROLLED :COMMIT
  \"62267c9811210c822973d240419daa986e8d8757\" :INTERNAL-TIME-UNITS-PER-SECOND
  1000000 :PROCESS-ID 86996 :FEATURES
  (:ASDF3.3 :ASDF3.2 :ASDF3.1 :ASDF3 :ASDF2 :ASDF :OS-MACOSX :OS-UNIX
   :NON-BASE-CHARS-EXIST-P :ASDF-UNICODE :ARENA-ALLOCATOR :ARM64 :GENCGC
   :64-BIT :ANSI-CL :BSD :COMMON-LISP :DARWIN :IEEE-FLOATING-POINT
   :LITTLE-ENDIAN :MACH-O :PACKAGE-LOCAL-NICKNAMES :SB-CORE-COMPRESSION :SB-LDB
   :SB-PACKAGE-LOCKS :SB-THREAD :SB-UNICODE :SBCL :UNIX)
  :INHERITED-ENVIRONMENT
  ((\"PATH\"
    #A((859) BASE-CHAR
       . \"/opt/homebrew/bin:/opt/homebrew/sbin:/opt/local/bin:/opt/local/sbin:/opt/local/bin:/opt/local/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/pkg/env/global/bin:/opt/X11/bin:/Library/Apple/usr/bin:/usr/local/share/dotnet:~/.dotnet/tools:/usr/local/go/bin:/opt/homebrew/bin:/Applications/ChatGPT.app/Contents/Resources/codex-cli/codex-path:/Users/gpicchiarelli/.codex/tmp/arg0/codex-arg0fNFNjS:/Users/gpicchiarelli/.local/bin:/opt/homebrew/sbin:/opt/local/bin:/opt/local/sbin:/Applications/ChatGPT.app/Contents/Resources:/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS\"))
   (\"SBCL_HOME\"
    #A((40) BASE-CHAR . \"/opt/homebrew/Cellar/sbcl/2.6.9/lib/sbcl\"))
   (\"LANG\" #A((7) BASE-CHAR . \"C.UTF-8\"))
   (\"LC_ALL\" #A((7) BASE-CHAR . \"C.UTF-8\"))
   (\"LC_CTYPE\" #A((7) BASE-CHAR . \"C.UTF-8\")) (\"TZ\" NIL))
  :USER-INIT NIL :SYS-INIT NIL :STDIN :EOF)
 :SOURCE-BEFORE
 ((:PATH #1# :GIT-BLOB \"bf62c65738ea6cece85c4281ec74eec2523a8d4b\" :CONTENTS
   \";;;; Phase0: maschere esatte scalar/SWAR, senza integrazione del primary index.
;;; REQ: REQ-SIM-001 REQ-SIM-002 REQ-BEN-002 REQ-VAL-001 REQ-AFF-003 REQ-AFF-008 REQ-AFF-016
(defpackage #:arcdocdb.spk08.impronte
  (:use #:cl) (:export #:check #:bench))
(in-package #:arcdocdb.spk08.impronte)
(declaim (optimize (safety 3) (speed 3) (debug 1)))

(deftype u64 () '(unsigned-byte 64))
(deftype h7 () '(unsigned-byte 7))
(deftype mask16 () '(unsigned-byte 16))
(deftype octets () '(simple-array (unsigned-byte 8) (*)))
(deftype words () '(simple-array (unsigned-byte 64) (*)))
(deftype masks () '(simple-array (unsigned-byte 16) (*)))
(defconstant +empty+ 128)
(defconstant +deleted+ 254)
(defconstant +low7+ #x7f7f7f7f7f7f7f7f)
(defconstant +high+ #x8080808080808080)
(defconstant +ones+ #x0101010101010101)
(defconstant +u64-mask+ #xffffffffffffffff)

(define-condition errore-impronte (error)
  ((motivo :initarg :motivo :reader motivo))
  (:report (lambda (c s) (format s \\\"SPK08 impronte: ~S\\\" (motivo c)))))

(declaim (inline finestra pack8-le zeri-esatti comprimi8 scalar16
                 scalar-u64 typedu64 packedmask16))
(declaim (ftype (function (octets fixnum) null) finestra))
(defun finestra (ctrl start)
  (declare (type octets ctrl) (type fixnum start))
  (unless (<= 0 start (- (length ctrl) 16))
    (error 'errore-impronte :motivo :invalid-window))
  nil)

(declaim (ftype (function (octets fixnum) u64) pack8-le))
(defun pack8-le (ctrl start)
  \\\"Caricamento portabile LE; i controlli degli accessi restano attivi.\\\"
  (declare (type octets ctrl) (type fixnum start))
  (let ((word 0))
    (declare (type u64 word))
    (dotimes (i 8 word)
      (setf word (logior word (ash (aref ctrl (+ start i)) (* 8 i)))))))

(declaim (ftype (function (u64) u64) zeri-esatti))
(defun zeri-esatti (x)
  \\\"Un bit alto per byte zero: ogni addendo di lane è <=254, senza riporto.\\\"
  (declare (type u64 x))
  (logand +high+
          (logxor +u64-mask+
                  (logior x +low7+ (+ (logand x +low7+) +low7+)))))

(declaim (ftype (function (u64) (unsigned-byte 8)) comprimi8))
(defun comprimi8 (high-bits)
  \\\"Conserva solo i bit 7,15,...,63; li porta nelle posizioni 0,...,7.\\\"
  (declare (type u64 high-bits))
  (let* ((x (ash (logand high-bits +high+) -7))
         (y (logand #x0003000300030003 (logior x (ash x -7))))
         (z (logand #x0000000f0000000f (logior y (ash y -14)))))
    (logand #xff (logior z (ash z -28)))))

(declaim (ftype (function (octets fixnum h7) mask16) scalar16 packedmask16)
         (ftype (function (u64 u64 h7) mask16) typedu64 scalar-u64))
(defun scalar16 (ctrl start h)
  \\\"Baseline su 16 byte; bit i = uguaglianza nella posizione i.\\\"
  (declare (type octets ctrl) (type fixnum start) (type h7 h))
  (finestra ctrl start)
  (let ((mask 0))
    (declare (type mask16 mask))
    (dotimes (i 16 mask)
      (when (= h (aref ctrl (+ start i)))
        (setf mask (logior mask (ash 1 i)))))))

(defun scalar-u64 (low high h)
  \\\"Baseline scalare su due parole LE già preparate.\\\"
  (declare (type u64 low high) (type h7 h))
  (let ((mask 0))
    (declare (type mask16 mask))
    (dotimes (i 8 mask)
      (when (= h (ldb (byte 8 (* 8 i)) low))
        (setf mask (logior mask (ash 1 i))))
      (when (= h (ldb (byte 8 (* 8 i)) high))
        (setf mask (logior mask (ash 1 (+ i 8))))))))

(defun typedu64 (low high h)
  \\\"SWAR su due u64; non è SIMD hardware. Restituisce un fixnum mask16.\\\"
  (declare (type u64 low high) (type h7 h))
  (let ((repeated (* h +ones+)))
    (declare (type u64 repeated))
    (logior (comprimi8 (zeri-esatti (logxor low repeated)))
            (ash (comprimi8 (zeri-esatti (logxor high repeated))) 8))))

(defun packedmask16 (ctrl start h)
  \\\"Include il packing dei 16 byte in due parole LE, a safety 3.\\\"
  (declare (type octets ctrl) (type fixnum start) (type h7 h))
  (finestra ctrl start)
  (typedu64 (pack8-le ctrl start) (pack8-le ctrl (+ start 8)) h))

(defun mutante-sottrazione (low high h)
  \\\"Mutante conservato: il prestito genera falsi bit di match. Mai nel BENCH.\\\"
  (declare (type u64 low high) (type h7 h))
  (let ((repeated (* h +ones+)))
    (labels ((word-mask (word)
               (let ((x (logxor word repeated)))
                 (comprimi8 (logand +high+ (lognot x)
                                    (logand +u64-mask+ (- x +ones+)))))))
      (logior (word-mask low) (ash (word-mask high) 8)))))

(defun oracle (ctrl start h)
  \\\"Indipendente: byte, classificazione alto bit e somma di potenze di due.\\\"
  (let ((result 0))
    (loop for i from 0 below 16
          for value = (aref ctrl (+ start i))
          when (and (< value 128) (= value h))
            do (incf result (expt 2 i)))
    result))

(defun passo-lcg (state)
  (declare (type (unsigned-byte 32) state))
  (ldb (byte 32 0) (+ (* state 1664525) 1013904223)))

(defun runtime ()
  (list :lisp (lisp-implementation-type) :version (lisp-implementation-version)
        :os (software-type) :os-version (software-version) :machine (machine-type)
        :machine-version (machine-version) :safety 3 :hardware-simd nil
        :packing-endian :little :host-endian
        #+little-endian :little #-little-endian :not-little-feature
        :internal-time-units-per-second internal-time-units-per-second))

(defun limite-entier (value low high name)
  (unless (and (integerp value) (<= low value high))
    (error 'errore-impronte :motivo (list :invalid-limit name value low high))))

(defun limite-secondes (seconds)
  (unless (and (realp seconds) (< 0 seconds) (<= seconds 300))
    (error 'errore-impronte :motivo (list :invalid-limit :seconds seconds))))

(defun deadline (seconds)
  (+ (get-internal-real-time) (ceiling (* seconds internal-time-units-per-second))))

(declaim (inline respecte-temps))
(defun respecte-temps (end)
  (declare (type fixnum end))
  (when (>= (get-internal-real-time) end)
    (error 'errore-impronte :motivo :time-budget)))

;; La matrice tiene byte, parole LE, query e oracle separati, preallocati.
(defstruct (matrice (:constructor %matrice))
  (ctrl (make-array 0 :element-type '(unsigned-byte 8)) :type octets)
  (offsets (make-array 0 :element-type '(unsigned-byte 8)) :type octets)
  (queries (make-array 0 :element-type '(unsigned-byte 8)) :type octets)
  (low (make-array 0 :element-type '(unsigned-byte 64)) :type words)
  (high (make-array 0 :element-type '(unsigned-byte 64)) :type words)
  (expected (make-array 0 :element-type '(unsigned-byte 16)) :type masks)
  (rows 0 :type fixnum)
  (sum 0 :type fixnum))

(defun valide-bench (rows passes warmup-passes seconds byte-budget)
  \\\"Preflight condiviso; permette di verificare rifiuti senza eseguire BENCH.\\\"
  (limite-entier rows 16 8192 :rows)
  (limite-entier passes 1 1024 :passes)
  (limite-entier warmup-passes 1 64 :warmup-passes)
  (limite-secondes seconds)
  (limite-entier byte-budget 1 67108864 :byte-budget)
  (let ((payload (* rows 104)) ; 2 datasets * (32+1+1+8+8+2) byte/riga.
        (operations (* 8 rows (+ warmup-passes (* 5 passes)))))
    (when (> payload byte-budget)
      (error 'errore-impronte :motivo :payload-budget))
    (when (> operations 200000000)
      (error 'errore-impronte :motivo :operation-budget))
    (values payload operations)))

(defun prepare-matrice (rows dataset)
  (declare (type fixnum rows))
  (let ((m (%matrice :rows rows
                    :ctrl (make-array (* rows 32) :element-type '(unsigned-byte 8)
                                      :initial-element +deleted+)
                    :offsets (make-array rows :element-type '(unsigned-byte 8))
                    :queries (make-array rows :element-type '(unsigned-byte 8))
                    :low (make-array rows :element-type '(unsigned-byte 64))
                    :high (make-array rows :element-type '(unsigned-byte 64))
                    :expected (make-array rows :element-type '(unsigned-byte 16))))
        (state #x6d61736b))
    (declare (type (unsigned-byte 32) state))
    (dotimes (row rows m)
      (let* ((offset (logand row 15)) (start (+ (* row 32) offset))
             (h (if (eq dataset :mixed) (logand (ash (setf state (passo-lcg state)) -16) 127)
                    (if (evenp (floor row 8)) 0 127))))
        (setf (aref (matrice-offsets m) row) offset
              (aref (matrice-queries m) row) h)
        (dotimes (i 16)
          (setf state (passo-lcg state))
          (setf (aref (matrice-ctrl m) (+ start i))
                (if (eq dataset :mixed)
                    (case (mod (+ row i) 8)
                      (0 h) (1 +empty+) (2 +deleted+)
                      (otherwise (ldb (byte 8 16) state)))
                    (case (mod row 8)
                      (0 (if (evenp i) h (logxor h 1)))
                      (1 h)
                      (2 (logxor h 1))
                      (3 (if (evenp i) +empty+ +deleted+))
                      (4 (logior 128 h))
                      (5 (case i (7 h) (8 (logxor h 1)) (otherwise 255)))
                      (6 (if (zerop i) h (logxor h 1)))
                      (otherwise (if (evenp i) 0 127))))))
        (let ((expected (oracle (matrice-ctrl m) start h)))
          (unless (= expected (scalar16 (matrice-ctrl m) start h)
                     (packedmask16 (matrice-ctrl m) start h))
            (error 'errore-impronte :motivo :bench-fixture))
          (setf (aref (matrice-low m) row) (pack8-le (matrice-ctrl m) start)
                (aref (matrice-high m) row) (pack8-le (matrice-ctrl m) (+ start 8))
                (aref (matrice-expected m) row) expected)
          (unless (= expected (scalar-u64 (aref (matrice-low m) row)
                                          (aref (matrice-high m) row) h)
                     (typedu64 (aref (matrice-low m) row)
                               (aref (matrice-high m) row) h))
            (error 'errore-impronte :motivo :bench-word-fixture))
          (incf (matrice-sum m) expected))))))

(defmacro definit-cycle (name expression)
  \\\"Quattro cicli diretti; nessun funcall o costruzione del report nella misura.\\\"
  `(defun ,name (m passes end)
     (declare (type matrice m) (type fixnum passes end))
     (let ((ctrl (matrice-ctrl m)) (offsets (matrice-offsets m))
           (queries (matrice-queries m)) (low (matrice-low m)) (high (matrice-high m))
           (rows (matrice-rows m)) (acc 0) (operations 0))
       (declare (type octets ctrl offsets queries) (type words low high)
                (type fixnum rows acc operations) (ignorable ctrl offsets low high))
       (respecte-temps end)
       (let ((start-ticks (get-internal-real-time))
             (start-bytes (sb-ext:get-bytes-consed)))
         (dotimes (pass passes)
           (dotimes (row rows)
             (incf acc ,expression)
             (incf operations)
             (when (zerop (logand operations 4095)) (respecte-temps end))))
         (let* ((end-bytes (sb-ext:get-bytes-consed))
                (end-ticks (get-internal-real-time))
                (ticks (- end-ticks start-ticks)) (bytes (- end-bytes start-bytes)))
           (respecte-temps end)
           (unless (= acc (* passes (matrice-sum m)))
             (error 'errore-impronte :motivo (list :cycle-checksum ',name acc)))
           (values ticks bytes acc operations))))))

(definit-cycle cycle-scalar16
  (scalar16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definit-cycle cycle-packedmask16
  (packedmask16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definit-cycle cycle-scalar-u64
  (scalar-u64 (aref low row) (aref high row) (aref queries row)))
(definit-cycle cycle-typedu64
  (typedu64 (aref low row) (aref high row) (aref queries row)))

(defun execute-cycle (kernel m passes end)
  \\\"Dispatch prima della misura; il corpo del ciclo chiama direttamente il kernel.\\\"
  (ecase kernel
    (:scalar16 (cycle-scalar16 m passes end))
    (:packedmask16 (cycle-packedmask16 m passes end))
    (:scalar-u64 (cycle-scalar-u64 m passes end))
    (:typedu64 (cycle-typedu64 m passes end))))

(defun bench (&key (rows 1024) (passes 64) (warmup-passes 2)
                   (seconds 60) (byte-budget 16777216))
  \\\"Matrice scalar/SWAR seriale, cinque repliche. Da eseguire soltanto nel parent.\\\"
  (multiple-value-bind (payload total-operations)
      (valide-bench rows passes warmup-passes seconds byte-budget)
    (let* ((end (deadline seconds))
           (mixed (prepare-matrice rows :mixed))
           (adversarial (prepare-matrice rows :adversarial))
           (measurements nil) (observable 0) (warmup-operations 0))
      (respecte-temps end)
      (loop for m in (list mixed adversarial) do
        (dolist (kernel '(:scalar16 :packedmask16 :scalar-u64 :typedu64))
          (multiple-value-bind (ticks bytes checksum operations)
              (execute-cycle kernel m warmup-passes end)
            (declare (ignore ticks bytes))
            (incf observable checksum) (incf warmup-operations operations))))
      (dotimes (replica 5)
        (loop for dataset in '(:mixed :adversarial)
              for m in (list mixed adversarial) for dataset-index from 0 do
          (loop for pair in '((:scalar16 :packedmask16) (:scalar-u64 :typedu64))
                for representation in '(:bytes-with-packing :prepacked-u64)
                for representation-index from 0
                for order = (if (evenp (+ replica dataset-index representation-index))
                                pair (reverse pair)) do
            (loop for kernel in order for order-index from 0 do
              (multiple-value-bind (ticks bytes checksum operations)
                  (execute-cycle kernel m passes end)
                (unless (plusp ticks)
                  (error 'errore-impronte :motivo :clock-resolution))
                (incf observable checksum)
                (push (list :dataset dataset :representation representation :kernel kernel
                            :replica (1+ replica) :order order :order-index order-index
                            :operations operations :ticks ticks :bytes-consed bytes
                            :checksum checksum
                            :ns/op (/ (* ticks 1d9)
                                      (* internal-time-units-per-second operations))
                            :bytes/op (/ bytes (coerce operations 'double-float)))
                      measurements))))))
      (respecte-temps end)
      (unless (= (length measurements) 40)
        (error 'errore-impronte :motivo :incomplete-bench))
      (list :status :ok :module :impronte-scalar-swar :runtime (runtime)
            :rows rows :passes passes :warmup-passes warmup-passes :replicas 5
            :measurements (nreverse measurements) :raw-samples t
            :observable-checksum observable :warmup-operations warmup-operations
            :measured-operations (* 40 rows passes) :total-operations total-operations
            :payload-bytes payload :seed #x6d61736b
            :limits (list :seconds seconds :byte-budget byte-budget :max-operations 200000000
                          :max-block-operations 4096 :cooperative-deadline t
                          :gc-and-scheduling-included t :report-and-fixtures-excluded t
                          :payload-excludes-object-headers t :no-rss t
                          :no-overhead-subtraction t :hardware-simd nil)))))

(defun refuse-dynamique (function args expected-condition input)
  \\\"Argomenti negativi opachi al compilatore; verifica l'assenza di mutazione.\\\"
  (let ((before (copy-seq input)) (caught nil))
    (handler-case (apply (symbol-function function) args)
      (error (c)
        (unless (typep c expected-condition) (error c))
        (setf caught (type-of c))))
    (unless (and caught (equalp before input))
      (error 'errore-impronte :motivo (list :negative-control function args)))
    (list :function function :arguments args :condition caught :input-unchanged t)))

(defun check (&key (max-cases 4000000) (differential-cases 20000) (seconds 120))
  \\\"Campagne esaustive/differenziali limitate, oracle indipendente e mutante.\\\"
  (limite-entier max-cases 1 4000000 :max-cases)
  (limite-entier differential-cases 1 100000 :differential-cases)
  (limite-secondes seconds)
  (let ((ctrl (make-array 64 :element-type '(unsigned-byte 8) :initial-element +empty+))
        (shadow (make-array 64 :element-type '(unsigned-byte 8)))
        (end (deadline seconds)) (cases 0) (campaigns nil) (negatives nil)
        (mutants nil) (state #x1a2b3c4d))
    (declare (type octets ctrl shadow) (type fixnum cases end)
             (type (unsigned-byte 32) state))
    (labels ((verify-group (start h)
               (declare (type fixnum start) (type h7 h))
               (when (>= cases max-cases)
                 (error 'errore-impronte :motivo :case-budget))
               (incf cases)
               (when (zerop (logand cases 4095)) (respecte-temps end))
               (replace shadow ctrl)
               (let* ((expected (oracle ctrl start h))
                      (low (pack8-le ctrl start)) (high (pack8-le ctrl (+ start 8)))
                      (a (scalar16 ctrl start h)) (b (packedmask16 ctrl start h))
                      (c (scalar-u64 low high h)) (d (typedu64 low high h)))
                 (unless (and (= expected a b c d) (equalp shadow ctrl))
                   (error 'errore-impronte
                          :motivo (list :differential cases start h :expected expected
                                        :actual (list a b c d) :ctrl (coerce ctrl 'list))))
                 expected))
             (campaign (name before expected)
               (let ((count (- cases before)))
                 (unless (= count expected)
                   (error 'errore-impronte :motivo (list :campaign-count name count expected)))
                 (push (list :name name :groups count :kernel-comparisons (* count 4)
                             :input-unchanged t) campaigns)))
             (negative (function args condition)
               (push (refuse-dynamique function args condition ctrl) negatives)))
      ;; Tutti i byte/query, ciascuna posizione isolata.
      (let ((before cases))
        (dotimes (h 128)
          (dotimes (position 16)
            (fill ctrl +empty+)
            (dotimes (value 256)
              (setf (aref ctrl position) value)
              (verify-group 0 h))))
        (campaign :all-byte-query-position before (* 128 16 256)))
      ;; Coppie adiacenti, incluse lane 7/8 tra parole; query ai due estremi.
      (let ((before cases))
        (dolist (h '(0 127))
          (dotimes (position 15)
            (fill ctrl +empty+)
            (dotimes (a 256)
              (setf (aref ctrl position) a)
              (dotimes (b 256)
                (setf (aref ctrl (1+ position)) b)
                (verify-group 0 h)))))
        (campaign :all-adjacent-byte-pairs before (* 2 15 256 256)))
      ;; Tutte le coppie ordinate di posizioni su dominio significativo.
      (let ((before cases) (alphabet '(0 1 126 127 128 129 254 255)))
        (dotimes (p 16)
          (dotimes (q 16)
            (dolist (a alphabet)
              (dolist (b alphabet)
                (fill ctrl +empty+)
                (setf (aref ctrl p) a (aref ctrl q) b)
                (dolist (h '(0 1 126 127)) (verify-group 0 h))))))
        (campaign :all-position-pairs-small-domain before (* 16 16 8 8 4)))
      ;; Esaustivo: tutte le parole 4^8, in entrambe le metà.
      (let ((before cases) (alphabet #(0 1 128 254)))
        (dotimes (code 65536)
          (dotimes (half 2)
            (fill ctrl +empty+)
            (dotimes (i 8)
              (setf (aref ctrl (+ (* half 8) i))
                    (aref alphabet (ldb (byte 2 (* 2 i)) code))))
            (dolist (h '(0 1 127)) (verify-group 0 h))))
        (campaign :exhaustive-four-to-eight before (* 65536 2 3)))
      ;; Tutte le mask16, controllo di compressione e dei bit alti.
      (let ((before cases))
        (fill ctrl +deleted+)
        (dotimes (mask 65536)
          (dotimes (i 16) (setf (aref ctrl i) (if (logbitp i mask) 127 +empty+)))
          (unless (= mask (verify-group 0 127))
            (error 'errore-impronte :motivo :compression-golden)))
        (campaign :all-mask16 before 65536))
      ;; Offset 0..31, finestra esatta e padding; golden LE non simmetrico.
      (let ((before cases))
        (dotimes (start 32)
          (fill ctrl +deleted+)
          (dotimes (i 16) (setf (aref ctrl (+ start i)) i))
          (unless (and (= (pack8-le ctrl start) #x0706050403020100)
                       (= (pack8-le ctrl (+ start 8)) #x0f0e0d0c0b0a0908))
            (error 'errore-impronte :motivo :endian-golden))
          (dotimes (h 16)
            (unless (= (verify-group start h) (ash 1 h))
              (error 'errore-impronte :motivo :position-golden))))
        (dolist (h '(0 127))
          (fill ctrl h)
          (unless (= (verify-group 48 h) #xffff)
            (error 'errore-impronte :motivo :full-mask-golden))
          (fill ctrl +empty+) (verify-group 48 h)
          (fill ctrl +deleted+) (verify-group 48 h))
        (campaign :offset-endian-boundaries before 518))
      ;; Stato u32 esplicito, nessun RANDOM/SXHASH e nessun clock negli input.
      (let ((before cases))
        (dotimes (n differential-cases)
          (dotimes (i 64)
            (setf state (passo-lcg state) (aref ctrl i) (ldb (byte 8 16) state)))
          (setf state (passo-lcg state))
          (verify-group (logand n 31) (logand (ash state -16) 127)))
        (campaign :deterministic-differential before differential-cases))
      ;; Testimoni del prestito per ogni coppia nella stessa parola, due query.
      (dolist (h '(0 127))
        (dolist (position '(0 1 2 3 4 5 6 8 9 10 11 12 13 14))
          (fill ctrl +empty+)
          (setf (aref ctrl position) h (aref ctrl (1+ position)) (logxor h 1))
          (let* ((expected (verify-group 0 h))
                 (actual (mutante-sottrazione (pack8-le ctrl 0) (pack8-le ctrl 8) h)))
            (unless (and (/= actual expected) (logbitp (1+ position) actual)
                         (not (logbitp (1+ position) expected)))
              (error 'errore-impronte :motivo :mutant-not-killed))
            (push (list :query h :position position :ctrl (coerce (subseq ctrl 0 16) 'list)
                        :oracle expected :mutant actual :extra-position (1+ position)) mutants))))
      ;; Il prestito non passa fra due parole; il mutante in questo caso concorda.
      (fill ctrl +empty+) (setf (aref ctrl 7) 0 (aref ctrl 8) 1)
      (unless (= (verify-group 0 0)
                 (mutante-sottrazione (pack8-le ctrl 0) (pack8-le ctrl 8) 0))
        (error 'errore-impronte :motivo :word-boundary-mutant))
      ;; Invalid args: runtime safety3, nessuna modifica dei byte sorgenti.
      (dolist (function '(scalar16 packedmask16))
        (dolist (h '(-1 128 255 1/2 :bad))
          (negative function (list ctrl 0 h) 'type-error))
        (dolist (start '(-1 49 64))
          (negative function (list ctrl start 0) 'errore-impronte))
        (dolist (start '(1/2 :bad))
          (negative function (list ctrl start 0) 'type-error))
        (dolist (length '(0 1 15))
          (let ((short (make-array length :element-type '(unsigned-byte 8))))
            (push (refuse-dynamique function (list short 0 0) 'errore-impronte short)
                  negatives)))
        (negative function (list (make-array 16 :initial-element 0) 0 0) 'type-error)
        (negative function (list (make-array '(4 4) :element-type '(unsigned-byte 8)) 0 0)
                  'type-error)
        (negative function (list (make-array 16 :element-type '(unsigned-byte 8)
                                            :fill-pointer 16) 0 0) 'type-error)
        (negative function (list (make-array 16 :element-type '(unsigned-byte 8)
                                            :displaced-to ctrl) 0 0) 'type-error))
      (dolist (function '(scalar-u64 typedu64))
        (dolist (value (list -1 (expt 2 64) 1/2 :bad))
          (negative function (list value 0 0) 'type-error)
          (negative function (list 0 value 0) 'type-error))
        (dolist (h '(-1 128 255 1/2 :bad))
          (negative function (list 0 0 h) 'type-error)))
      ;; Esaurimento: CHECK rifiuta il secondo caso, senza chiamare BENCH.
      (negative 'check '(:max-cases 1 :differential-cases 1 :seconds 120) 'errore-impronte)
      (negative 'check '(:max-cases 0) 'errore-impronte)
      (negative 'check '(:differential-cases 100001) 'errore-impronte)
      (negative 'check '(:seconds 0) 'errore-impronte)
      (negative 'respecte-temps (list (get-internal-real-time)) 'errore-impronte)
      (dolist (args '((15 1 1 60 16777216) (8193 1 1 60 16777216)
                      (16 0 1 60 16777216) (16 1025 1 60 16777216)
                      (16 1 0 60 16777216) (16 1 65 60 16777216)
                      (16 1 1 0 16777216) (16 1 1 301 16777216)
                      (16 1 1 60 0) (16 1 1 60 67108865)
                      (16 1 1 60 1) (8192 1024 64 60 67108864)))
        (negative 'valide-bench args 'errore-impronte))
      (respecte-temps end)
      (setf negatives (nreverse negatives))
      (list :status :ok :module :impronte-scalar-swar :runtime (runtime)
            :groups cases :kernel-comparisons (* 4 cases)
            :campaigns (nreverse campaigns) :differential-seed #x1a2b3c4d
            :final-lcg-state state :negative-controls negatives
            :negative-control-count (length negatives)
            :mutant :borrow-subtraction :mutant-killed-count (length mutants)
            :mutant-witnesses (nreverse mutants) :word-boundary-controls 1
            :mask-api '((scalar16 ctrl start h7) (packedmask16 ctrl start h7)
                        (scalar-u64 low high h7) (typedu64 low high h7))
            :bench-api '(bench &key rows passes warmup-passes seconds byte-budget)
            :bench-executed nil
            :limits (list :max-cases max-cases :differential-cases differential-cases
                          :seconds seconds :checkpoint-groups 4096
                          :cooperative-deadline t :domain-byte-values 256 :query-values 128
                          :group-bytes 16 :packed-words 2 :small-domain-word-states 65536
                          :no-source-mutation t :hardware-simd nil :production-integration nil)
            :disassembly
            (loop for name in '(scalar16 packedmask16 scalar-u64 typedu64
                                cycle-scalar16 cycle-packedmask16 cycle-scalar-u64 cycle-typedu64)
                  collect (list :function name :text
                                (with-output-to-string (*standard-output*)
                                  (disassemble (symbol-function name)))))))))
\")
  (:PATH #2# :GIT-BLOB \"060b10fd79901e6f3a664e28b3c2153c2c8aa214\" :CONTENTS
   \"# SPK-08 — metodo preregistrato per le impronte

;;; REQ: REQ-SIM-001 REQ-SIM-002 REQ-BEN-002 REQ-VAL-001 REQ-AFF-003 REQ-AFF-008 REQ-AFF-016

Registrato prima di qualsiasi compile/CHECK. Ambito Phase0: solo il nuovo
`impronte.lisp`, package `ARCDOCDB.SPK08.IMPRONTE`, export `CHECK` e `BENCH`.
Tutto il lavoro avviene nel checkout isolato
`/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB`.
Common Lisp/SBCL, safety 3, nessuna dipendenza da altri spike e nessuna
integrazione dell'indice. Nessun commit o push.

## Contratto e algoritmo

Un gruppo contiene 16 byte ctrl. Le impronte valide sono 0–127; empty = 128,
deleted = 254. Tutti gli altri byte con alto bit acceso sono esclusi dal match.
La maschera risultante ha il bit i per la posizione i (0–15). Query fuori
0–127, tipi errati e finestre di meno di 16 byte producono errore.
L'input è di sola lettura. La serializzazione delle due parole u64 è
esplicitamente little endian: byte i nei bit 8*i; il risultato non dipende
dall'endian della macchina. Non si usano accessi di memoria non allineati o VOP.

Per x = word XOR query ripetuta, la maschera esatta degli zeri è
`NOT (((x AND 0x7f7f7f7f7f7f7f7f) + 0x7f7f7f7f7f7f7f7f) OR x OR
0x7f7f7f7f7f7f7f7f) AND 0x8080808080808080`.
Ogni somma di lane è al massimo 254: non c'è riporto fra byte.
Tre piegature comprimono gli otto bit alti in un byte; due parole danno u16.
Il mutante `(x - 0x0101010101010101) AND NOT x AND 0x8080808080808080`
conserva il limite del prestito, con x = byte 0 seguito da byte 1: utile come
test di esistenza di uno zero, inadeguato come maschera esatta per posizione.
Il mutante resta una funzione separata, mai una variante selezionabile dei kernel.

Kernel: `scalar16` e `packedmask16` su byte array e offset; `scalar-u64` e
`typedu64` su due u64. Tipi specializzati, safety 3 e chiamate dirette/inline
nei cicli. La compilazione/disassemblato e i campioni di bytes-consed
permettono di valutare le allocazioni; non si presume che una chiamata Lisp
esterna con u64 boxed non allochi. SWAR è aritmetica su parole intere, non
SIMD hardware. Un oracle scalare distinto legge solo i byte e somma potenze
di due, senza riusare packing, compressione o formula SWAR.

## CHECK e budget

1. Strict compile in processo SBCL senza init: warning e style-warning sono
   fatali, oltre ai valori warnings/failure di compile-file. FASL solo in `out/`.
2. Tutti i 256 byte, tutte le 128 query e tutte le 16 posizioni isolate.
3. Tutte le coppie di byte (256²) nelle 15 coppie adiacenti, query 0 e 127;
   comprende il confine fra le parole e ogni posizione con prestito.
4. Tutte le 16² coppie di posizioni, byte nel dominio piccolo
   {0, 1, 126, 127, 128, 129, 254, 255}, query {0, 1, 126, 127}.
5. Tutte le 4^8 parole su {0, 1, 128, 254}, ciascuna nelle due metà, query
   {0, 1, 127}; dominio piccolo interamente enumerato, non campionato.
6. Differenziale più grande: 20.000 gruppi da LCG u32 con seme fisso;
   offset 0–31, byte arbitrari, query 0–127. Fixture golden endian e maschere
   vuota/piena/alternata; tutte le maschere u16 per la compressione.
7. Controlli negativi del mutante, invalid args attraverso chiamata dinamica
   per evitare warning statici intenzionali; confronto integrale input
   prima/dopo, anche sul rifiuto. Rifiuti deterministici di budget CHECK/BENCH
   prima di qualsiasi misura BENCH.

CHECK ha limite massimo 4.000.000 confronti di gruppo, default uguale al
massimo, 20.000 gruppi differenziali (tetto 100.000), 120 secondi (tetto 300).
Scadenza controllata ogni 4096 confronti e alla conclusione, limite cooperativo;
un limite esaurito è errore, mai successo parziale. I conteggi sono riportati
per campagna, con controlli di congruenza. Conservare disassemblato locale
dei quattro kernel e dei cicli diretti. La plist riporta :status :ok solo
dopo tutte le campagne e include limiti e piattaforma reale.

## BENCH da eseguire soltanto nel parent

API prevista: `(bench &key (rows 1024) (passes 64) (warmup-passes 2)
(seconds 60) (byte-budget 16777216))`. Cinque repliche obbligatorie.
Due dataset, misto e avversario (prestiti, hit pieno, miss, speciali, alto bit,
0/127, confine di parola); matrice di byte e parole preallocata, stessi query
e oracle per entrambi i kernel di ciascun confronto. Offset 0–15 su righe
da 32 byte. Packing/preparazione/validazione/oracle/warmup esclusi dalle
misure. Confronti: scalar16/packedmask16 e scalar-u64/typedu64.
Ordine alternato AB/BA per replica e cella della matrice, esplicitamente
riportato. Accumulatore numerico verificato contro oracle e pubblicato.

Ogni campione misura ticks e bytes-consed solo intorno al ciclo diretto;
riporta operazioni effettive, ns/op calcolati, byte totali e per operazione,
checksum, ordine e replica. Non si sottrae un overhead stimato e non si
inventano tempi; ticks = 0 rende la misura non risolta e produce errore.
GC e scheduling durante il ciclo restano inclusi. Allocazioni del report
e fixture escluse; bytes-consed non è RSS. Il ciclo legge i dati preallocati
e produce un checksum fixnum; non crea strutture per chiamata.
I limiti sono rows 16–8192, passes 1–1024, warmup 1–64, seconds >0 e ≤300,
payload byte-budget ≤64 MiB e operazioni totali ≤200.000.000.
La scadenza è cooperativa fra blocchi di al massimo 4096 operazioni, con
stessi controlli nei due cicli; esaurimento segnala errore senza plist :ok.
BENCH restituisce :status :ok, :measurements, limiti e campioni raw,
solo dopo cinque repliche complete per tutte le celle. Non viene eseguito
in questo lavoro, neppure per warmup o smoke test.

## Evidenze e limiti dell'inferenza

Ogni tentativo compile/CHECK, incluso un fallimento, avrà nuovi file ignored
`out/` con schema-version 1, argv e stdin esplicito, ambiente, hash/contenuti
prima/dopo, risultato decodificato, stdout/stderr integrali e limiti.
Il wrapper esistente `tools/record-command.lisp` può registrare il comando;
un driver nuovo in `out/` aggiunge risultato del modulo, warning, source
immutato e log senza troncamento. Driver e stdin vengono inclusi nelle prove.
Nessun file esistente di core/run/suite/tools/docs/ADR/REQ viene modificato.
Alla consegna si elencano tutti i tentativi, i percorsi e i conteggi reali.

Piattaforma osservata inizialmente: Darwin 27.0.0, arm64, SBCL da
`/opt/homebrew/bin/sbcl`. Versione SBCL, CPU, risoluzione clock e feature
endian vengono raccolte dai processi registrati. La prova riguarda questa
piattaforma; non qualifica x86-64, SIMD hardware, l'indice o il motore.
Nessuna superiorità prestazionale prima dei campioni del parent.
\")
  (:PATH #3# :GIT-BLOB \"57916fb52bb5c61900f8ec86399df6bbf8c899eb\" :CONTENTS
   \";;;; Driver locale delle sole prove compile/CHECK; nessuna misura BENCH.
(require :asdf)
(require :sb-posix)
(declaim (optimize (safety 3) (debug 3)))
(defparameter *root* #p\\\"/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB/\\\")
(defparameter *source* \\\"spikes/SPK-08-generated-code/impronte.lisp\\\")
(defparameter *method* \\\"spikes/SPK-08-generated-code/metodo-impronte.md\\\")
(defparameter *driver* \\\"spikes/SPK-08-generated-code/out/record-impronte.lisp\\\")

(defun raw-command (argv)
  (string-trim '(#\\\\Space #\\\\Return #\\\\Newline)
               (uiop:run-program argv :output :string :error-output :string)))
(defun contents (path) (uiop:read-file-string path))
(defun snapshot ()
  (loop for path in (list *source* *method* *driver*)
        collect (list :path path :git-blob (raw-command (list \\\"git\\\" \\\"hash-object\\\" \\\"--\\\" path))
                      :contents (contents path))))
(defun save-data (path data)
  (with-open-file (s path :direction :output :if-exists :supersede)
    (let ((*print-readably* t) (*print-pretty* t) (*print-circle* t))
      (write data :stream s) (terpri s))))
(defun save-text (path text)
  (with-open-file (s path :direction :output :if-exists :supersede)
    (write-string text s)))
(defun new-out ()
  (loop for n below 1000
        for dir = (merge-pathnames
                   (format nil \\\"spikes/SPK-08-generated-code/out/~D-impronte-~D-~D/\\\"
                           (get-universal-time) (sb-posix:getpid) n) *root*)
        do (handler-case (progn (sb-posix:mkdir dir #o700) (return-from new-out dir))
             (sb-posix:syscall-error (c)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno c)) (error c)))))
  (error \\\"Esauriti i tentativi di creare il record.\\\"))
(defun observed-environment ()
  (list :cwd (namestring (truename \\\"./\\\")) :lisp (lisp-implementation-type)
        :version (lisp-implementation-version) :os (software-type)
        :os-version (software-version) :machine (machine-type)
        :cpu (raw-command '(\\\"sysctl\\\" \\\"-n\\\" \\\"machdep.cpu.brand_string\\\"))
        :memory-bytes (raw-command '(\\\"sysctl\\\" \\\"-n\\\" \\\"hw.memsize\\\"))
        :logical-cpus (raw-command '(\\\"sysctl\\\" \\\"-n\\\" \\\"hw.logicalcpu\\\"))
        :load-average (raw-command '(\\\"sysctl\\\" \\\"-n\\\" \\\"vm.loadavg\\\"))
        :external-load :uncontrolled :commit (raw-command '(\\\"git\\\" \\\"rev-parse\\\" \\\"HEAD\\\"))
        :internal-time-units-per-second internal-time-units-per-second
        :process-id (sb-posix:getpid) :features *features*
        :inherited-environment
        (loop for name in '(\\\"PATH\\\" \\\"SBCL_HOME\\\" \\\"LANG\\\" \\\"LC_ALL\\\" \\\"LC_CTYPE\\\" \\\"TZ\\\")
              collect (list name (sb-ext:posix-getenv name)))
        :user-init nil :sys-init nil :stdin :eof))

(defun main ()
  (unless (equal (truename \\\"./\\\") (truename *root*))
    (error \\\"Il driver richiede il checkout isolato.\\\"))
  (let* ((args (uiop:command-line-arguments))
         (mode (first args))
         (out (new-out)) (path (merge-pathnames \\\"report.lisp\\\" out))
         (stdout (make-string-output-stream)) (stderr (make-string-output-stream))
         (warnings 0) (style-warnings 0)
         (record (list :schema-version 1 :kind :impronte-compile-check :status :running
                       :command (append (list \\\"/opt/homebrew/bin/sbcl\\\" \\\"--noinform\\\"
                                              \\\"--no-sysinit\\\" \\\"--no-userinit\\\" \\\"--script\\\"
                                              *driver*) args)
                       :runtime-argv sb-ext:*posix-argv*
                       :stdin (list :mode :eof :contents \\\"\\\" :redirect \\\"/dev/null\\\")
                       :environment (observed-environment) :source-before (snapshot)
                       :started-at-universal-time (get-universal-time)
                       :limits '(:safety 3 :warning-fatal t :style-warning-fatal t
                                 :compile-only-this-module t :bench-never-called t
                                 :check-max-cases 4000000 :check-seconds 120
                                 :stdout-truncated nil :stderr-truncated nil
                                 :source-scope :impronte-method-and-driver
                                 :deadline-cooperative t)))
         (start (get-internal-real-time)) (exit-code 0))
    (save-data path record)
    (let ((*standard-output* stdout) (*error-output* stderr) (*trace-output* stderr))
      (handler-case
          (handler-bind
              ((warning (lambda (c)
                          (if (typep c 'style-warning) (incf style-warnings) (incf warnings))
                          (format *error-output* \\\"~&~A: ~A~%\\\" (type-of c) c)
                          (error \\\"Avviso di compilazione/esecuzione fatale: ~A\\\" c))))
            (unless (member mode '(\\\"compile\\\" \\\"compile-check\\\") :test #'equal)
              (error \\\"Modalità non consentita: ~S\\\" mode))
            (let ((fasl (merge-pathnames \\\"impronte.fasl\\\" out)))
              (setf (getf record :compile) (list :status :running :source *source*
                                               :output (namestring fasl)))
              (save-data path record)
              (multiple-value-bind (file warned failed)
                  (compile-file *source* :output-file fasl)
                (setf (getf record :compile)
                      (list :status (if (or warned failed) :failed :ok)
                            :output (and file (namestring file)) :warnings-p warned :failure-p failed))
                (when (or warned failed (null file)) (error \\\"Strict compile fallita.\\\")))
              (when (equal mode \\\"compile-check\\\")
                (load fasl)
                (let* ((package (find-package \\\"ARCDOCDB.SPK08.IMPRONTE\\\"))
                       (fn (find-symbol \\\"CHECK\\\" package))
                       (check-start (get-internal-real-time))
                       (result (funcall fn)))
                  (unless (eq (getf result :status) :ok) (error \\\"CHECK senza :status :ok.\\\"))
                  (setf (getf record :decoded-check) result
                        (getf record :check-seconds)
                        (/ (- (get-internal-real-time) check-start)
                           (coerce internal-time-units-per-second 'double-float)))
                  (save-data (merge-pathnames \\\"check-data.lisp\\\" out)
                             (list :schema-version 1 :kind :module-check :result result))
                  (dolist (item (getf result :disassembly))
                    (save-text (merge-pathnames
                                (format nil \\\"disassembly-~(~A~).txt\\\" (getf item :function)) out)
                               (getf item :text)))
                  (format t \\\"~&CHECK :OK; groups=~D kernels=~D negatives=~D mutants=~D~%\\\"
                          (getf result :groups) (getf result :kernel-comparisons)
                          (getf result :negative-control-count) (getf result :mutant-killed-count))))
              (setf (getf record :status) :ok)))
        (error (c)
          (setf exit-code 1 (getf record :status) :failed
                (getf record :failure) (list :condition (type-of c) :message (princ-to-string c)))
          (format *error-output* \\\"~&FALLIMENTO ~A: ~A~%\\\" (type-of c) c))))
    (let ((out-text (get-output-stream-string stdout)) (err-text (get-output-stream-string stderr)))
      (setf (getf record :stdout) out-text (getf record :stderr) err-text)
      (save-text (merge-pathnames \\\"stdout.txt\\\" out) out-text)
      (save-text (merge-pathnames \\\"stderr.txt\\\" out) err-text))
    (setf (getf record :warning-count) warnings (getf record :style-warning-count) style-warnings
          (getf record :exit-code) exit-code
          (getf record :finished-at-universal-time) (get-universal-time)
          (getf record :wall-seconds)
          (/ (- (get-internal-real-time) start)
             (coerce internal-time-units-per-second 'double-float)))
    (save-data path record)
    (setf (getf record :source-after) (snapshot)
          (getf record :source-consistency)
          (if (equal (getf record :source-before) (getf record :source-after)) :stable :changed))
    (unless (eq (getf record :source-consistency) :stable)
      (setf exit-code 1 (getf record :exit-code) 1 (getf record :status) :source-changed))
    (save-data path record)
    (format t \\\"~&~S; warnings=~D style-warnings=~D; record: ~A~%\\\"
            (getf record :status) warnings style-warnings path)
    (when (getf record :failure) (format t \\\"~S~%\\\" (getf record :failure)))
    (sb-ext:exit :code exit-code)))
(main)
\"))
 :STARTED-AT-UNIVERSAL-TIME 4000480808 :LIMITS
 (:SAFETY 3 :WARNING-FATAL T :STYLE-WARNING-FATAL T :COMPILE-ONLY-THIS-MODULE T
  :BENCH-NEVER-CALLED T :CHECK-MAX-CASES 4000000 :CHECK-SECONDS 120
  :STDOUT-TRUNCATED NIL :STDERR-TRUNCATED NIL :SOURCE-SCOPE
  :IMPRONTE-METHOD-AND-DRIVER :DEADLINE-COOPERATIVE T))
"
 :DECODED-RECORD
 (:SOURCE-CONSISTENCY :STABLE :SOURCE-AFTER
  ((:PATH "spikes/SPK-08-generated-code/impronte.lisp" :GIT-BLOB
    "bf62c65738ea6cece85c4281ec74eec2523a8d4b" :CONTENTS
    ";;;; Phase0: maschere esatte scalar/SWAR, senza integrazione del primary index.
;;; REQ: REQ-SIM-001 REQ-SIM-002 REQ-BEN-002 REQ-VAL-001 REQ-AFF-003 REQ-AFF-008 REQ-AFF-016
(defpackage #:arcdocdb.spk08.impronte
  (:use #:cl) (:export #:check #:bench))
(in-package #:arcdocdb.spk08.impronte)
(declaim (optimize (safety 3) (speed 3) (debug 1)))

(deftype u64 () '(unsigned-byte 64))
(deftype h7 () '(unsigned-byte 7))
(deftype mask16 () '(unsigned-byte 16))
(deftype octets () '(simple-array (unsigned-byte 8) (*)))
(deftype words () '(simple-array (unsigned-byte 64) (*)))
(deftype masks () '(simple-array (unsigned-byte 16) (*)))
(defconstant +empty+ 128)
(defconstant +deleted+ 254)
(defconstant +low7+ #x7f7f7f7f7f7f7f7f)
(defconstant +high+ #x8080808080808080)
(defconstant +ones+ #x0101010101010101)
(defconstant +u64-mask+ #xffffffffffffffff)

(define-condition errore-impronte (error)
  ((motivo :initarg :motivo :reader motivo))
  (:report (lambda (c s) (format s \"SPK08 impronte: ~S\" (motivo c)))))

(declaim (inline finestra pack8-le zeri-esatti comprimi8 scalar16
                 scalar-u64 typedu64 packedmask16))
(declaim (ftype (function (octets fixnum) null) finestra))
(defun finestra (ctrl start)
  (declare (type octets ctrl) (type fixnum start))
  (unless (<= 0 start (- (length ctrl) 16))
    (error 'errore-impronte :motivo :invalid-window))
  nil)

(declaim (ftype (function (octets fixnum) u64) pack8-le))
(defun pack8-le (ctrl start)
  \"Caricamento portabile LE; i controlli degli accessi restano attivi.\"
  (declare (type octets ctrl) (type fixnum start))
  (let ((word 0))
    (declare (type u64 word))
    (dotimes (i 8 word)
      (setf word (logior word (ash (aref ctrl (+ start i)) (* 8 i)))))))

(declaim (ftype (function (u64) u64) zeri-esatti))
(defun zeri-esatti (x)
  \"Un bit alto per byte zero: ogni addendo di lane è <=254, senza riporto.\"
  (declare (type u64 x))
  (logand +high+
          (logxor +u64-mask+
                  (logior x +low7+ (+ (logand x +low7+) +low7+)))))

(declaim (ftype (function (u64) (unsigned-byte 8)) comprimi8))
(defun comprimi8 (high-bits)
  \"Conserva solo i bit 7,15,...,63; li porta nelle posizioni 0,...,7.\"
  (declare (type u64 high-bits))
  (let* ((x (ash (logand high-bits +high+) -7))
         (y (logand #x0003000300030003 (logior x (ash x -7))))
         (z (logand #x0000000f0000000f (logior y (ash y -14)))))
    (logand #xff (logior z (ash z -28)))))

(declaim (ftype (function (octets fixnum h7) mask16) scalar16 packedmask16)
         (ftype (function (u64 u64 h7) mask16) typedu64 scalar-u64))
(defun scalar16 (ctrl start h)
  \"Baseline su 16 byte; bit i = uguaglianza nella posizione i.\"
  (declare (type octets ctrl) (type fixnum start) (type h7 h))
  (finestra ctrl start)
  (let ((mask 0))
    (declare (type mask16 mask))
    (dotimes (i 16 mask)
      (when (= h (aref ctrl (+ start i)))
        (setf mask (logior mask (ash 1 i)))))))

(defun scalar-u64 (low high h)
  \"Baseline scalare su due parole LE già preparate.\"
  (declare (type u64 low high) (type h7 h))
  (let ((mask 0))
    (declare (type mask16 mask))
    (dotimes (i 8 mask)
      (when (= h (ldb (byte 8 (* 8 i)) low))
        (setf mask (logior mask (ash 1 i))))
      (when (= h (ldb (byte 8 (* 8 i)) high))
        (setf mask (logior mask (ash 1 (+ i 8))))))))

(defun typedu64 (low high h)
  \"SWAR su due u64; non è SIMD hardware. Restituisce un fixnum mask16.\"
  (declare (type u64 low high) (type h7 h))
  (let ((repeated (* h +ones+)))
    (declare (type u64 repeated))
    (logior (comprimi8 (zeri-esatti (logxor low repeated)))
            (ash (comprimi8 (zeri-esatti (logxor high repeated))) 8))))

(defun packedmask16 (ctrl start h)
  \"Include il packing dei 16 byte in due parole LE, a safety 3.\"
  (declare (type octets ctrl) (type fixnum start) (type h7 h))
  (finestra ctrl start)
  (typedu64 (pack8-le ctrl start) (pack8-le ctrl (+ start 8)) h))

(defun mutante-sottrazione (low high h)
  \"Mutante conservato: il prestito genera falsi bit di match. Mai nel BENCH.\"
  (declare (type u64 low high) (type h7 h))
  (let ((repeated (* h +ones+)))
    (labels ((word-mask (word)
               (let ((x (logxor word repeated)))
                 (comprimi8 (logand +high+ (lognot x)
                                    (logand +u64-mask+ (- x +ones+)))))))
      (logior (word-mask low) (ash (word-mask high) 8)))))

(defun oracle (ctrl start h)
  \"Indipendente: byte, classificazione alto bit e somma di potenze di due.\"
  (let ((result 0))
    (loop for i from 0 below 16
          for value = (aref ctrl (+ start i))
          when (and (< value 128) (= value h))
            do (incf result (expt 2 i)))
    result))

(defun passo-lcg (state)
  (declare (type (unsigned-byte 32) state))
  (ldb (byte 32 0) (+ (* state 1664525) 1013904223)))

(defun runtime ()
  (list :lisp (lisp-implementation-type) :version (lisp-implementation-version)
        :os (software-type) :os-version (software-version) :machine (machine-type)
        :machine-version (machine-version) :safety 3 :hardware-simd nil
        :packing-endian :little :host-endian
        #+little-endian :little #-little-endian :not-little-feature
        :internal-time-units-per-second internal-time-units-per-second))

(defun limite-entier (value low high name)
  (unless (and (integerp value) (<= low value high))
    (error 'errore-impronte :motivo (list :invalid-limit name value low high))))

(defun limite-secondes (seconds)
  (unless (and (realp seconds) (< 0 seconds) (<= seconds 300))
    (error 'errore-impronte :motivo (list :invalid-limit :seconds seconds))))

(defun deadline (seconds)
  (+ (get-internal-real-time) (ceiling (* seconds internal-time-units-per-second))))

(declaim (inline respecte-temps))
(defun respecte-temps (end)
  (declare (type fixnum end))
  (when (>= (get-internal-real-time) end)
    (error 'errore-impronte :motivo :time-budget)))

;; La matrice tiene byte, parole LE, query e oracle separati, preallocati.
(defstruct (matrice (:constructor %matrice))
  (ctrl (make-array 0 :element-type '(unsigned-byte 8)) :type octets)
  (offsets (make-array 0 :element-type '(unsigned-byte 8)) :type octets)
  (queries (make-array 0 :element-type '(unsigned-byte 8)) :type octets)
  (low (make-array 0 :element-type '(unsigned-byte 64)) :type words)
  (high (make-array 0 :element-type '(unsigned-byte 64)) :type words)
  (expected (make-array 0 :element-type '(unsigned-byte 16)) :type masks)
  (rows 0 :type fixnum)
  (sum 0 :type fixnum))

(defun valide-bench (rows passes warmup-passes seconds byte-budget)
  \"Preflight condiviso; permette di verificare rifiuti senza eseguire BENCH.\"
  (limite-entier rows 16 8192 :rows)
  (limite-entier passes 1 1024 :passes)
  (limite-entier warmup-passes 1 64 :warmup-passes)
  (limite-secondes seconds)
  (limite-entier byte-budget 1 67108864 :byte-budget)
  (let ((payload (* rows 104)) ; 2 datasets * (32+1+1+8+8+2) byte/riga.
        (operations (* 8 rows (+ warmup-passes (* 5 passes)))))
    (when (> payload byte-budget)
      (error 'errore-impronte :motivo :payload-budget))
    (when (> operations 200000000)
      (error 'errore-impronte :motivo :operation-budget))
    (values payload operations)))

(defun prepare-matrice (rows dataset)
  (declare (type fixnum rows))
  (let ((m (%matrice :rows rows
                    :ctrl (make-array (* rows 32) :element-type '(unsigned-byte 8)
                                      :initial-element +deleted+)
                    :offsets (make-array rows :element-type '(unsigned-byte 8))
                    :queries (make-array rows :element-type '(unsigned-byte 8))
                    :low (make-array rows :element-type '(unsigned-byte 64))
                    :high (make-array rows :element-type '(unsigned-byte 64))
                    :expected (make-array rows :element-type '(unsigned-byte 16))))
        (state #x6d61736b))
    (declare (type (unsigned-byte 32) state))
    (dotimes (row rows m)
      (let* ((offset (logand row 15)) (start (+ (* row 32) offset))
             (h (if (eq dataset :mixed) (logand (ash (setf state (passo-lcg state)) -16) 127)
                    (if (evenp (floor row 8)) 0 127))))
        (setf (aref (matrice-offsets m) row) offset
              (aref (matrice-queries m) row) h)
        (dotimes (i 16)
          (setf state (passo-lcg state))
          (setf (aref (matrice-ctrl m) (+ start i))
                (if (eq dataset :mixed)
                    (case (mod (+ row i) 8)
                      (0 h) (1 +empty+) (2 +deleted+)
                      (otherwise (ldb (byte 8 16) state)))
                    (case (mod row 8)
                      (0 (if (evenp i) h (logxor h 1)))
                      (1 h)
                      (2 (logxor h 1))
                      (3 (if (evenp i) +empty+ +deleted+))
                      (4 (logior 128 h))
                      (5 (case i (7 h) (8 (logxor h 1)) (otherwise 255)))
                      (6 (if (zerop i) h (logxor h 1)))
                      (otherwise (if (evenp i) 0 127))))))
        (let ((expected (oracle (matrice-ctrl m) start h)))
          (unless (= expected (scalar16 (matrice-ctrl m) start h)
                     (packedmask16 (matrice-ctrl m) start h))
            (error 'errore-impronte :motivo :bench-fixture))
          (setf (aref (matrice-low m) row) (pack8-le (matrice-ctrl m) start)
                (aref (matrice-high m) row) (pack8-le (matrice-ctrl m) (+ start 8))
                (aref (matrice-expected m) row) expected)
          (unless (= expected (scalar-u64 (aref (matrice-low m) row)
                                          (aref (matrice-high m) row) h)
                     (typedu64 (aref (matrice-low m) row)
                               (aref (matrice-high m) row) h))
            (error 'errore-impronte :motivo :bench-word-fixture))
          (incf (matrice-sum m) expected))))))

(defmacro definit-cycle (name expression)
  \"Quattro cicli diretti; nessun funcall o costruzione del report nella misura.\"
  `(defun ,name (m passes end)
     (declare (type matrice m) (type fixnum passes end))
     (let ((ctrl (matrice-ctrl m)) (offsets (matrice-offsets m))
           (queries (matrice-queries m)) (low (matrice-low m)) (high (matrice-high m))
           (rows (matrice-rows m)) (acc 0) (operations 0))
       (declare (type octets ctrl offsets queries) (type words low high)
                (type fixnum rows acc operations) (ignorable ctrl offsets low high))
       (respecte-temps end)
       (let ((start-ticks (get-internal-real-time))
             (start-bytes (sb-ext:get-bytes-consed)))
         (dotimes (pass passes)
           (dotimes (row rows)
             (incf acc ,expression)
             (incf operations)
             (when (zerop (logand operations 4095)) (respecte-temps end))))
         (let* ((end-bytes (sb-ext:get-bytes-consed))
                (end-ticks (get-internal-real-time))
                (ticks (- end-ticks start-ticks)) (bytes (- end-bytes start-bytes)))
           (respecte-temps end)
           (unless (= acc (* passes (matrice-sum m)))
             (error 'errore-impronte :motivo (list :cycle-checksum ',name acc)))
           (values ticks bytes acc operations))))))

(definit-cycle cycle-scalar16
  (scalar16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definit-cycle cycle-packedmask16
  (packedmask16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definit-cycle cycle-scalar-u64
  (scalar-u64 (aref low row) (aref high row) (aref queries row)))
(definit-cycle cycle-typedu64
  (typedu64 (aref low row) (aref high row) (aref queries row)))

(defun execute-cycle (kernel m passes end)
  \"Dispatch prima della misura; il corpo del ciclo chiama direttamente il kernel.\"
  (ecase kernel
    (:scalar16 (cycle-scalar16 m passes end))
    (:packedmask16 (cycle-packedmask16 m passes end))
    (:scalar-u64 (cycle-scalar-u64 m passes end))
    (:typedu64 (cycle-typedu64 m passes end))))

(defun bench (&key (rows 1024) (passes 64) (warmup-passes 2)
                   (seconds 60) (byte-budget 16777216))
  \"Matrice scalar/SWAR seriale, cinque repliche. Da eseguire soltanto nel parent.\"
  (multiple-value-bind (payload total-operations)
      (valide-bench rows passes warmup-passes seconds byte-budget)
    (let* ((end (deadline seconds))
           (mixed (prepare-matrice rows :mixed))
           (adversarial (prepare-matrice rows :adversarial))
           (measurements nil) (observable 0) (warmup-operations 0))
      (respecte-temps end)
      (loop for m in (list mixed adversarial) do
        (dolist (kernel '(:scalar16 :packedmask16 :scalar-u64 :typedu64))
          (multiple-value-bind (ticks bytes checksum operations)
              (execute-cycle kernel m warmup-passes end)
            (declare (ignore ticks bytes))
            (incf observable checksum) (incf warmup-operations operations))))
      (dotimes (replica 5)
        (loop for dataset in '(:mixed :adversarial)
              for m in (list mixed adversarial) for dataset-index from 0 do
          (loop for pair in '((:scalar16 :packedmask16) (:scalar-u64 :typedu64))
                for representation in '(:bytes-with-packing :prepacked-u64)
                for representation-index from 0
                for order = (if (evenp (+ replica dataset-index representation-index))
                                pair (reverse pair)) do
            (loop for kernel in order for order-index from 0 do
              (multiple-value-bind (ticks bytes checksum operations)
                  (execute-cycle kernel m passes end)
                (unless (plusp ticks)
                  (error 'errore-impronte :motivo :clock-resolution))
                (incf observable checksum)
                (push (list :dataset dataset :representation representation :kernel kernel
                            :replica (1+ replica) :order order :order-index order-index
                            :operations operations :ticks ticks :bytes-consed bytes
                            :checksum checksum
                            :ns/op (/ (* ticks 1d9)
                                      (* internal-time-units-per-second operations))
                            :bytes/op (/ bytes (coerce operations 'double-float)))
                      measurements))))))
      (respecte-temps end)
      (unless (= (length measurements) 40)
        (error 'errore-impronte :motivo :incomplete-bench))
      (list :status :ok :module :impronte-scalar-swar :runtime (runtime)
            :rows rows :passes passes :warmup-passes warmup-passes :replicas 5
            :measurements (nreverse measurements) :raw-samples t
            :observable-checksum observable :warmup-operations warmup-operations
            :measured-operations (* 40 rows passes) :total-operations total-operations
            :payload-bytes payload :seed #x6d61736b
            :limits (list :seconds seconds :byte-budget byte-budget :max-operations 200000000
                          :max-block-operations 4096 :cooperative-deadline t
                          :gc-and-scheduling-included t :report-and-fixtures-excluded t
                          :payload-excludes-object-headers t :no-rss t
                          :no-overhead-subtraction t :hardware-simd nil)))))

(defun refuse-dynamique (function args expected-condition input)
  \"Argomenti negativi opachi al compilatore; verifica l'assenza di mutazione.\"
  (let ((before (copy-seq input)) (caught nil))
    (handler-case (apply (symbol-function function) args)
      (error (c)
        (unless (typep c expected-condition) (error c))
        (setf caught (type-of c))))
    (unless (and caught (equalp before input))
      (error 'errore-impronte :motivo (list :negative-control function args)))
    (list :function function :arguments args :condition caught :input-unchanged t)))

(defun check (&key (max-cases 4000000) (differential-cases 20000) (seconds 120))
  \"Campagne esaustive/differenziali limitate, oracle indipendente e mutante.\"
  (limite-entier max-cases 1 4000000 :max-cases)
  (limite-entier differential-cases 1 100000 :differential-cases)
  (limite-secondes seconds)
  (let ((ctrl (make-array 64 :element-type '(unsigned-byte 8) :initial-element +empty+))
        (shadow (make-array 64 :element-type '(unsigned-byte 8)))
        (end (deadline seconds)) (cases 0) (campaigns nil) (negatives nil)
        (mutants nil) (state #x1a2b3c4d))
    (declare (type octets ctrl shadow) (type fixnum cases end)
             (type (unsigned-byte 32) state))
    (labels ((verify-group (start h)
               (declare (type fixnum start) (type h7 h))
               (when (>= cases max-cases)
                 (error 'errore-impronte :motivo :case-budget))
               (incf cases)
               (when (zerop (logand cases 4095)) (respecte-temps end))
               (replace shadow ctrl)
               (let* ((expected (oracle ctrl start h))
                      (low (pack8-le ctrl start)) (high (pack8-le ctrl (+ start 8)))
                      (a (scalar16 ctrl start h)) (b (packedmask16 ctrl start h))
                      (c (scalar-u64 low high h)) (d (typedu64 low high h)))
                 (unless (and (= expected a b c d) (equalp shadow ctrl))
                   (error 'errore-impronte
                          :motivo (list :differential cases start h :expected expected
                                        :actual (list a b c d) :ctrl (coerce ctrl 'list))))
                 expected))
             (campaign (name before expected)
               (let ((count (- cases before)))
                 (unless (= count expected)
                   (error 'errore-impronte :motivo (list :campaign-count name count expected)))
                 (push (list :name name :groups count :kernel-comparisons (* count 4)
                             :input-unchanged t) campaigns)))
             (negative (function args condition)
               (push (refuse-dynamique function args condition ctrl) negatives)))
      ;; Tutti i byte/query, ciascuna posizione isolata.
      (let ((before cases))
        (dotimes (h 128)
          (dotimes (position 16)
            (fill ctrl +empty+)
            (dotimes (value 256)
              (setf (aref ctrl position) value)
              (verify-group 0 h))))
        (campaign :all-byte-query-position before (* 128 16 256)))
      ;; Coppie adiacenti, incluse lane 7/8 tra parole; query ai due estremi.
      (let ((before cases))
        (dolist (h '(0 127))
          (dotimes (position 15)
            (fill ctrl +empty+)
            (dotimes (a 256)
              (setf (aref ctrl position) a)
              (dotimes (b 256)
                (setf (aref ctrl (1+ position)) b)
                (verify-group 0 h)))))
        (campaign :all-adjacent-byte-pairs before (* 2 15 256 256)))
      ;; Tutte le coppie ordinate di posizioni su dominio significativo.
      (let ((before cases) (alphabet '(0 1 126 127 128 129 254 255)))
        (dotimes (p 16)
          (dotimes (q 16)
            (dolist (a alphabet)
              (dolist (b alphabet)
                (fill ctrl +empty+)
                (setf (aref ctrl p) a (aref ctrl q) b)
                (dolist (h '(0 1 126 127)) (verify-group 0 h))))))
        (campaign :all-position-pairs-small-domain before (* 16 16 8 8 4)))
      ;; Esaustivo: tutte le parole 4^8, in entrambe le metà.
      (let ((before cases) (alphabet #(0 1 128 254)))
        (dotimes (code 65536)
          (dotimes (half 2)
            (fill ctrl +empty+)
            (dotimes (i 8)
              (setf (aref ctrl (+ (* half 8) i))
                    (aref alphabet (ldb (byte 2 (* 2 i)) code))))
            (dolist (h '(0 1 127)) (verify-group 0 h))))
        (campaign :exhaustive-four-to-eight before (* 65536 2 3)))
      ;; Tutte le mask16, controllo di compressione e dei bit alti.
      (let ((before cases))
        (fill ctrl +deleted+)
        (dotimes (mask 65536)
          (dotimes (i 16) (setf (aref ctrl i) (if (logbitp i mask) 127 +empty+)))
          (unless (= mask (verify-group 0 127))
            (error 'errore-impronte :motivo :compression-golden)))
        (campaign :all-mask16 before 65536))
      ;; Offset 0..31, finestra esatta e padding; golden LE non simmetrico.
      (let ((before cases))
        (dotimes (start 32)
          (fill ctrl +deleted+)
          (dotimes (i 16) (setf (aref ctrl (+ start i)) i))
          (unless (and (= (pack8-le ctrl start) #x0706050403020100)
                       (= (pack8-le ctrl (+ start 8)) #x0f0e0d0c0b0a0908))
            (error 'errore-impronte :motivo :endian-golden))
          (dotimes (h 16)
            (unless (= (verify-group start h) (ash 1 h))
              (error 'errore-impronte :motivo :position-golden))))
        (dolist (h '(0 127))
          (fill ctrl h)
          (unless (= (verify-group 48 h) #xffff)
            (error 'errore-impronte :motivo :full-mask-golden))
          (fill ctrl +empty+) (verify-group 48 h)
          (fill ctrl +deleted+) (verify-group 48 h))
        (campaign :offset-endian-boundaries before 518))
      ;; Stato u32 esplicito, nessun RANDOM/SXHASH e nessun clock negli input.
      (let ((before cases))
        (dotimes (n differential-cases)
          (dotimes (i 64)
            (setf state (passo-lcg state) (aref ctrl i) (ldb (byte 8 16) state)))
          (setf state (passo-lcg state))
          (verify-group (logand n 31) (logand (ash state -16) 127)))
        (campaign :deterministic-differential before differential-cases))
      ;; Testimoni del prestito per ogni coppia nella stessa parola, due query.
      (dolist (h '(0 127))
        (dolist (position '(0 1 2 3 4 5 6 8 9 10 11 12 13 14))
          (fill ctrl +empty+)
          (setf (aref ctrl position) h (aref ctrl (1+ position)) (logxor h 1))
          (let* ((expected (verify-group 0 h))
                 (actual (mutante-sottrazione (pack8-le ctrl 0) (pack8-le ctrl 8) h)))
            (unless (and (/= actual expected) (logbitp (1+ position) actual)
                         (not (logbitp (1+ position) expected)))
              (error 'errore-impronte :motivo :mutant-not-killed))
            (push (list :query h :position position :ctrl (coerce (subseq ctrl 0 16) 'list)
                        :oracle expected :mutant actual :extra-position (1+ position)) mutants))))
      ;; Il prestito non passa fra due parole; il mutante in questo caso concorda.
      (fill ctrl +empty+) (setf (aref ctrl 7) 0 (aref ctrl 8) 1)
      (unless (= (verify-group 0 0)
                 (mutante-sottrazione (pack8-le ctrl 0) (pack8-le ctrl 8) 0))
        (error 'errore-impronte :motivo :word-boundary-mutant))
      ;; Invalid args: runtime safety3, nessuna modifica dei byte sorgenti.
      (dolist (function '(scalar16 packedmask16))
        (dolist (h '(-1 128 255 1/2 :bad))
          (negative function (list ctrl 0 h) 'type-error))
        (dolist (start '(-1 49 64))
          (negative function (list ctrl start 0) 'errore-impronte))
        (dolist (start '(1/2 :bad))
          (negative function (list ctrl start 0) 'type-error))
        (dolist (length '(0 1 15))
          (let ((short (make-array length :element-type '(unsigned-byte 8))))
            (push (refuse-dynamique function (list short 0 0) 'errore-impronte short)
                  negatives)))
        (negative function (list (make-array 16 :initial-element 0) 0 0) 'type-error)
        (negative function (list (make-array '(4 4) :element-type '(unsigned-byte 8)) 0 0)
                  'type-error)
        (negative function (list (make-array 16 :element-type '(unsigned-byte 8)
                                            :fill-pointer 16) 0 0) 'type-error)
        (negative function (list (make-array 16 :element-type '(unsigned-byte 8)
                                            :displaced-to ctrl) 0 0) 'type-error))
      (dolist (function '(scalar-u64 typedu64))
        (dolist (value (list -1 (expt 2 64) 1/2 :bad))
          (negative function (list value 0 0) 'type-error)
          (negative function (list 0 value 0) 'type-error))
        (dolist (h '(-1 128 255 1/2 :bad))
          (negative function (list 0 0 h) 'type-error)))
      ;; Esaurimento: CHECK rifiuta il secondo caso, senza chiamare BENCH.
      (negative 'check '(:max-cases 1 :differential-cases 1 :seconds 120) 'errore-impronte)
      (negative 'check '(:max-cases 0) 'errore-impronte)
      (negative 'check '(:differential-cases 100001) 'errore-impronte)
      (negative 'check '(:seconds 0) 'errore-impronte)
      (negative 'respecte-temps (list (get-internal-real-time)) 'errore-impronte)
      (dolist (args '((15 1 1 60 16777216) (8193 1 1 60 16777216)
                      (16 0 1 60 16777216) (16 1025 1 60 16777216)
                      (16 1 0 60 16777216) (16 1 65 60 16777216)
                      (16 1 1 0 16777216) (16 1 1 301 16777216)
                      (16 1 1 60 0) (16 1 1 60 67108865)
                      (16 1 1 60 1) (8192 1024 64 60 67108864)))
        (negative 'valide-bench args 'errore-impronte))
      (respecte-temps end)
      (setf negatives (nreverse negatives))
      (list :status :ok :module :impronte-scalar-swar :runtime (runtime)
            :groups cases :kernel-comparisons (* 4 cases)
            :campaigns (nreverse campaigns) :differential-seed #x1a2b3c4d
            :final-lcg-state state :negative-controls negatives
            :negative-control-count (length negatives)
            :mutant :borrow-subtraction :mutant-killed-count (length mutants)
            :mutant-witnesses (nreverse mutants) :word-boundary-controls 1
            :mask-api '((scalar16 ctrl start h7) (packedmask16 ctrl start h7)
                        (scalar-u64 low high h7) (typedu64 low high h7))
            :bench-api '(bench &key rows passes warmup-passes seconds byte-budget)
            :bench-executed nil
            :limits (list :max-cases max-cases :differential-cases differential-cases
                          :seconds seconds :checkpoint-groups 4096
                          :cooperative-deadline t :domain-byte-values 256 :query-values 128
                          :group-bytes 16 :packed-words 2 :small-domain-word-states 65536
                          :no-source-mutation t :hardware-simd nil :production-integration nil)
            :disassembly
            (loop for name in '(scalar16 packedmask16 scalar-u64 typedu64
                                cycle-scalar16 cycle-packedmask16 cycle-scalar-u64 cycle-typedu64)
                  collect (list :function name :text
                                (with-output-to-string (*standard-output*)
                                  (disassemble (symbol-function name)))))))))
")
   (:PATH "spikes/SPK-08-generated-code/metodo-impronte.md" :GIT-BLOB
    "060b10fd79901e6f3a664e28b3c2153c2c8aa214" :CONTENTS
    "# SPK-08 — metodo preregistrato per le impronte

;;; REQ: REQ-SIM-001 REQ-SIM-002 REQ-BEN-002 REQ-VAL-001 REQ-AFF-003 REQ-AFF-008 REQ-AFF-016

Registrato prima di qualsiasi compile/CHECK. Ambito Phase0: solo il nuovo
`impronte.lisp`, package `ARCDOCDB.SPK08.IMPRONTE`, export `CHECK` e `BENCH`.
Tutto il lavoro avviene nel checkout isolato
`/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB`.
Common Lisp/SBCL, safety 3, nessuna dipendenza da altri spike e nessuna
integrazione dell'indice. Nessun commit o push.

## Contratto e algoritmo

Un gruppo contiene 16 byte ctrl. Le impronte valide sono 0–127; empty = 128,
deleted = 254. Tutti gli altri byte con alto bit acceso sono esclusi dal match.
La maschera risultante ha il bit i per la posizione i (0–15). Query fuori
0–127, tipi errati e finestre di meno di 16 byte producono errore.
L'input è di sola lettura. La serializzazione delle due parole u64 è
esplicitamente little endian: byte i nei bit 8*i; il risultato non dipende
dall'endian della macchina. Non si usano accessi di memoria non allineati o VOP.

Per x = word XOR query ripetuta, la maschera esatta degli zeri è
`NOT (((x AND 0x7f7f7f7f7f7f7f7f) + 0x7f7f7f7f7f7f7f7f) OR x OR
0x7f7f7f7f7f7f7f7f) AND 0x8080808080808080`.
Ogni somma di lane è al massimo 254: non c'è riporto fra byte.
Tre piegature comprimono gli otto bit alti in un byte; due parole danno u16.
Il mutante `(x - 0x0101010101010101) AND NOT x AND 0x8080808080808080`
conserva il limite del prestito, con x = byte 0 seguito da byte 1: utile come
test di esistenza di uno zero, inadeguato come maschera esatta per posizione.
Il mutante resta una funzione separata, mai una variante selezionabile dei kernel.

Kernel: `scalar16` e `packedmask16` su byte array e offset; `scalar-u64` e
`typedu64` su due u64. Tipi specializzati, safety 3 e chiamate dirette/inline
nei cicli. La compilazione/disassemblato e i campioni di bytes-consed
permettono di valutare le allocazioni; non si presume che una chiamata Lisp
esterna con u64 boxed non allochi. SWAR è aritmetica su parole intere, non
SIMD hardware. Un oracle scalare distinto legge solo i byte e somma potenze
di due, senza riusare packing, compressione o formula SWAR.

## CHECK e budget

1. Strict compile in processo SBCL senza init: warning e style-warning sono
   fatali, oltre ai valori warnings/failure di compile-file. FASL solo in `out/`.
2. Tutti i 256 byte, tutte le 128 query e tutte le 16 posizioni isolate.
3. Tutte le coppie di byte (256²) nelle 15 coppie adiacenti, query 0 e 127;
   comprende il confine fra le parole e ogni posizione con prestito.
4. Tutte le 16² coppie di posizioni, byte nel dominio piccolo
   {0, 1, 126, 127, 128, 129, 254, 255}, query {0, 1, 126, 127}.
5. Tutte le 4^8 parole su {0, 1, 128, 254}, ciascuna nelle due metà, query
   {0, 1, 127}; dominio piccolo interamente enumerato, non campionato.
6. Differenziale più grande: 20.000 gruppi da LCG u32 con seme fisso;
   offset 0–31, byte arbitrari, query 0–127. Fixture golden endian e maschere
   vuota/piena/alternata; tutte le maschere u16 per la compressione.
7. Controlli negativi del mutante, invalid args attraverso chiamata dinamica
   per evitare warning statici intenzionali; confronto integrale input
   prima/dopo, anche sul rifiuto. Rifiuti deterministici di budget CHECK/BENCH
   prima di qualsiasi misura BENCH.

CHECK ha limite massimo 4.000.000 confronti di gruppo, default uguale al
massimo, 20.000 gruppi differenziali (tetto 100.000), 120 secondi (tetto 300).
Scadenza controllata ogni 4096 confronti e alla conclusione, limite cooperativo;
un limite esaurito è errore, mai successo parziale. I conteggi sono riportati
per campagna, con controlli di congruenza. Conservare disassemblato locale
dei quattro kernel e dei cicli diretti. La plist riporta :status :ok solo
dopo tutte le campagne e include limiti e piattaforma reale.

## BENCH da eseguire soltanto nel parent

API prevista: `(bench &key (rows 1024) (passes 64) (warmup-passes 2)
(seconds 60) (byte-budget 16777216))`. Cinque repliche obbligatorie.
Due dataset, misto e avversario (prestiti, hit pieno, miss, speciali, alto bit,
0/127, confine di parola); matrice di byte e parole preallocata, stessi query
e oracle per entrambi i kernel di ciascun confronto. Offset 0–15 su righe
da 32 byte. Packing/preparazione/validazione/oracle/warmup esclusi dalle
misure. Confronti: scalar16/packedmask16 e scalar-u64/typedu64.
Ordine alternato AB/BA per replica e cella della matrice, esplicitamente
riportato. Accumulatore numerico verificato contro oracle e pubblicato.

Ogni campione misura ticks e bytes-consed solo intorno al ciclo diretto;
riporta operazioni effettive, ns/op calcolati, byte totali e per operazione,
checksum, ordine e replica. Non si sottrae un overhead stimato e non si
inventano tempi; ticks = 0 rende la misura non risolta e produce errore.
GC e scheduling durante il ciclo restano inclusi. Allocazioni del report
e fixture escluse; bytes-consed non è RSS. Il ciclo legge i dati preallocati
e produce un checksum fixnum; non crea strutture per chiamata.
I limiti sono rows 16–8192, passes 1–1024, warmup 1–64, seconds >0 e ≤300,
payload byte-budget ≤64 MiB e operazioni totali ≤200.000.000.
La scadenza è cooperativa fra blocchi di al massimo 4096 operazioni, con
stessi controlli nei due cicli; esaurimento segnala errore senza plist :ok.
BENCH restituisce :status :ok, :measurements, limiti e campioni raw,
solo dopo cinque repliche complete per tutte le celle. Non viene eseguito
in questo lavoro, neppure per warmup o smoke test.

## Evidenze e limiti dell'inferenza

Ogni tentativo compile/CHECK, incluso un fallimento, avrà nuovi file ignored
`out/` con schema-version 1, argv e stdin esplicito, ambiente, hash/contenuti
prima/dopo, risultato decodificato, stdout/stderr integrali e limiti.
Il wrapper esistente `tools/record-command.lisp` può registrare il comando;
un driver nuovo in `out/` aggiunge risultato del modulo, warning, source
immutato e log senza troncamento. Driver e stdin vengono inclusi nelle prove.
Nessun file esistente di core/run/suite/tools/docs/ADR/REQ viene modificato.
Alla consegna si elencano tutti i tentativi, i percorsi e i conteggi reali.

Piattaforma osservata inizialmente: Darwin 27.0.0, arm64, SBCL da
`/opt/homebrew/bin/sbcl`. Versione SBCL, CPU, risoluzione clock e feature
endian vengono raccolte dai processi registrati. La prova riguarda questa
piattaforma; non qualifica x86-64, SIMD hardware, l'indice o il motore.
Nessuna superiorità prestazionale prima dei campioni del parent.
")
   (:PATH "spikes/SPK-08-generated-code/out/record-impronte.lisp" :GIT-BLOB
    "57916fb52bb5c61900f8ec86399df6bbf8c899eb" :CONTENTS
    ";;;; Driver locale delle sole prove compile/CHECK; nessuna misura BENCH.
(require :asdf)
(require :sb-posix)
(declaim (optimize (safety 3) (debug 3)))
(defparameter *root* #p\"/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB/\")
(defparameter *source* \"spikes/SPK-08-generated-code/impronte.lisp\")
(defparameter *method* \"spikes/SPK-08-generated-code/metodo-impronte.md\")
(defparameter *driver* \"spikes/SPK-08-generated-code/out/record-impronte.lisp\")

(defun raw-command (argv)
  (string-trim '(#\\Space #\\Return #\\Newline)
               (uiop:run-program argv :output :string :error-output :string)))
(defun contents (path) (uiop:read-file-string path))
(defun snapshot ()
  (loop for path in (list *source* *method* *driver*)
        collect (list :path path :git-blob (raw-command (list \"git\" \"hash-object\" \"--\" path))
                      :contents (contents path))))
(defun save-data (path data)
  (with-open-file (s path :direction :output :if-exists :supersede)
    (let ((*print-readably* t) (*print-pretty* t) (*print-circle* t))
      (write data :stream s) (terpri s))))
(defun save-text (path text)
  (with-open-file (s path :direction :output :if-exists :supersede)
    (write-string text s)))
(defun new-out ()
  (loop for n below 1000
        for dir = (merge-pathnames
                   (format nil \"spikes/SPK-08-generated-code/out/~D-impronte-~D-~D/\"
                           (get-universal-time) (sb-posix:getpid) n) *root*)
        do (handler-case (progn (sb-posix:mkdir dir #o700) (return-from new-out dir))
             (sb-posix:syscall-error (c)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno c)) (error c)))))
  (error \"Esauriti i tentativi di creare il record.\"))
(defun observed-environment ()
  (list :cwd (namestring (truename \"./\")) :lisp (lisp-implementation-type)
        :version (lisp-implementation-version) :os (software-type)
        :os-version (software-version) :machine (machine-type)
        :cpu (raw-command '(\"sysctl\" \"-n\" \"machdep.cpu.brand_string\"))
        :memory-bytes (raw-command '(\"sysctl\" \"-n\" \"hw.memsize\"))
        :logical-cpus (raw-command '(\"sysctl\" \"-n\" \"hw.logicalcpu\"))
        :load-average (raw-command '(\"sysctl\" \"-n\" \"vm.loadavg\"))
        :external-load :uncontrolled :commit (raw-command '(\"git\" \"rev-parse\" \"HEAD\"))
        :internal-time-units-per-second internal-time-units-per-second
        :process-id (sb-posix:getpid) :features *features*
        :inherited-environment
        (loop for name in '(\"PATH\" \"SBCL_HOME\" \"LANG\" \"LC_ALL\" \"LC_CTYPE\" \"TZ\")
              collect (list name (sb-ext:posix-getenv name)))
        :user-init nil :sys-init nil :stdin :eof))

(defun main ()
  (unless (equal (truename \"./\") (truename *root*))
    (error \"Il driver richiede il checkout isolato.\"))
  (let* ((args (uiop:command-line-arguments))
         (mode (first args))
         (out (new-out)) (path (merge-pathnames \"report.lisp\" out))
         (stdout (make-string-output-stream)) (stderr (make-string-output-stream))
         (warnings 0) (style-warnings 0)
         (record (list :schema-version 1 :kind :impronte-compile-check :status :running
                       :command (append (list \"/opt/homebrew/bin/sbcl\" \"--noinform\"
                                              \"--no-sysinit\" \"--no-userinit\" \"--script\"
                                              *driver*) args)
                       :runtime-argv sb-ext:*posix-argv*
                       :stdin (list :mode :eof :contents \"\" :redirect \"/dev/null\")
                       :environment (observed-environment) :source-before (snapshot)
                       :started-at-universal-time (get-universal-time)
                       :limits '(:safety 3 :warning-fatal t :style-warning-fatal t
                                 :compile-only-this-module t :bench-never-called t
                                 :check-max-cases 4000000 :check-seconds 120
                                 :stdout-truncated nil :stderr-truncated nil
                                 :source-scope :impronte-method-and-driver
                                 :deadline-cooperative t)))
         (start (get-internal-real-time)) (exit-code 0))
    (save-data path record)
    (let ((*standard-output* stdout) (*error-output* stderr) (*trace-output* stderr))
      (handler-case
          (handler-bind
              ((warning (lambda (c)
                          (if (typep c 'style-warning) (incf style-warnings) (incf warnings))
                          (format *error-output* \"~&~A: ~A~%\" (type-of c) c)
                          (error \"Avviso di compilazione/esecuzione fatale: ~A\" c))))
            (unless (member mode '(\"compile\" \"compile-check\") :test #'equal)
              (error \"Modalità non consentita: ~S\" mode))
            (let ((fasl (merge-pathnames \"impronte.fasl\" out)))
              (setf (getf record :compile) (list :status :running :source *source*
                                               :output (namestring fasl)))
              (save-data path record)
              (multiple-value-bind (file warned failed)
                  (compile-file *source* :output-file fasl)
                (setf (getf record :compile)
                      (list :status (if (or warned failed) :failed :ok)
                            :output (and file (namestring file)) :warnings-p warned :failure-p failed))
                (when (or warned failed (null file)) (error \"Strict compile fallita.\")))
              (when (equal mode \"compile-check\")
                (load fasl)
                (let* ((package (find-package \"ARCDOCDB.SPK08.IMPRONTE\"))
                       (fn (find-symbol \"CHECK\" package))
                       (check-start (get-internal-real-time))
                       (result (funcall fn)))
                  (unless (eq (getf result :status) :ok) (error \"CHECK senza :status :ok.\"))
                  (setf (getf record :decoded-check) result
                        (getf record :check-seconds)
                        (/ (- (get-internal-real-time) check-start)
                           (coerce internal-time-units-per-second 'double-float)))
                  (save-data (merge-pathnames \"check-data.lisp\" out)
                             (list :schema-version 1 :kind :module-check :result result))
                  (dolist (item (getf result :disassembly))
                    (save-text (merge-pathnames
                                (format nil \"disassembly-~(~A~).txt\" (getf item :function)) out)
                               (getf item :text)))
                  (format t \"~&CHECK :OK; groups=~D kernels=~D negatives=~D mutants=~D~%\"
                          (getf result :groups) (getf result :kernel-comparisons)
                          (getf result :negative-control-count) (getf result :mutant-killed-count))))
              (setf (getf record :status) :ok)))
        (error (c)
          (setf exit-code 1 (getf record :status) :failed
                (getf record :failure) (list :condition (type-of c) :message (princ-to-string c)))
          (format *error-output* \"~&FALLIMENTO ~A: ~A~%\" (type-of c) c))))
    (let ((out-text (get-output-stream-string stdout)) (err-text (get-output-stream-string stderr)))
      (setf (getf record :stdout) out-text (getf record :stderr) err-text)
      (save-text (merge-pathnames \"stdout.txt\" out) out-text)
      (save-text (merge-pathnames \"stderr.txt\" out) err-text))
    (setf (getf record :warning-count) warnings (getf record :style-warning-count) style-warnings
          (getf record :exit-code) exit-code
          (getf record :finished-at-universal-time) (get-universal-time)
          (getf record :wall-seconds)
          (/ (- (get-internal-real-time) start)
             (coerce internal-time-units-per-second 'double-float)))
    (save-data path record)
    (setf (getf record :source-after) (snapshot)
          (getf record :source-consistency)
          (if (equal (getf record :source-before) (getf record :source-after)) :stable :changed))
    (unless (eq (getf record :source-consistency) :stable)
      (setf exit-code 1 (getf record :exit-code) 1 (getf record :status) :source-changed))
    (save-data path record)
    (format t \"~&~S; warnings=~D style-warnings=~D; record: ~A~%\"
            (getf record :status) warnings style-warnings path)
    (when (getf record :failure) (format t \"~S~%\" (getf record :failure)))
    (sb-ext:exit :code exit-code)))
(main)
"))
  :WALL-SECONDS 0.202686d0 :FINISHED-AT-UNIVERSAL-TIME 4000480809 :EXIT-CODE 1
  :STYLE-WARNING-COUNT 1 :WARNING-COUNT 0 :STDERR
  "REDEFINITION-WITH-DEFMACRO: redefining ARCDOCDB.SPK08.IMPRONTE::DEFINIT-CYCLE in DEFMACRO
FALLIMENTO SIMPLE-ERROR: Avviso di compilazione/esecuzione fatale: redefining ARCDOCDB.SPK08.IMPRONTE::DEFINIT-CYCLE in DEFMACRO
"
  :STDOUT "" :FAILURE
  (:CONDITION SIMPLE-ERROR :MESSAGE
   #A((103) BASE-CHAR
      . "Avviso di compilazione/esecuzione fatale: redefining ARCDOCDB.SPK08.IMPRONTE::DEFINIT-CYCLE in DEFMACRO"))
  :COMPILE
  (:STATUS :OK :OUTPUT
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB/spikes/SPK-08-generated-code/out/4000480808-impronte-86996-0/impronte.fasl")
   :WARNINGS-P NIL :FAILURE-P NIL)
  :SCHEMA-VERSION 1 :KIND :IMPRONTE-COMPILE-CHECK :STATUS :FAILED :COMMAND
  ("/opt/homebrew/bin/sbcl" "--noinform" "--no-sysinit" "--no-userinit"
   "--script" "spikes/SPK-08-generated-code/out/record-impronte.lisp"
   #A((13) BASE-CHAR . "compile-check"))
  :RUNTIME-ARGV
  (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
   #A((13) BASE-CHAR . "compile-check"))
  :STDIN (:MODE :EOF :CONTENTS "" :REDIRECT "/dev/null") :ENVIRONMENT
  (:CWD
   #A((68) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB/")
   :LISP #A((4) BASE-CHAR . "SBCL") :VERSION #A((5) BASE-CHAR . "2.6.9") :OS
   #A((6) BASE-CHAR . "Darwin") :OS-VERSION #A((6) BASE-CHAR . "27.0.0")
   :MACHINE #A((5) BASE-CHAR . "ARM64") :CPU "Apple M4" :MEMORY-BYTES
   "17179869184" :LOGICAL-CPUS "10" :LOAD-AVERAGE "{ 3.11 4.49 7.98 }"
   :EXTERNAL-LOAD :UNCONTROLLED :COMMIT
   "62267c9811210c822973d240419daa986e8d8757" :INTERNAL-TIME-UNITS-PER-SECOND
   1000000 :PROCESS-ID 86996 :FEATURES
   (:ASDF3.3 :ASDF3.2 :ASDF3.1 :ASDF3 :ASDF2 :ASDF :OS-MACOSX :OS-UNIX
    :NON-BASE-CHARS-EXIST-P :ASDF-UNICODE :ARENA-ALLOCATOR :ARM64 :GENCGC
    :64-BIT :ANSI-CL :BSD :COMMON-LISP :DARWIN :IEEE-FLOATING-POINT
    :LITTLE-ENDIAN :MACH-O :PACKAGE-LOCAL-NICKNAMES :SB-CORE-COMPRESSION
    :SB-LDB :SB-PACKAGE-LOCKS :SB-THREAD :SB-UNICODE :SBCL :UNIX)
   :INHERITED-ENVIRONMENT
   (("PATH"
     #A((859) BASE-CHAR
        . "/opt/homebrew/bin:/opt/homebrew/sbin:/opt/local/bin:/opt/local/sbin:/opt/local/bin:/opt/local/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/pkg/env/global/bin:/opt/X11/bin:/Library/Apple/usr/bin:/usr/local/share/dotnet:~/.dotnet/tools:/usr/local/go/bin:/opt/homebrew/bin:/Applications/ChatGPT.app/Contents/Resources/codex-cli/codex-path:/Users/gpicchiarelli/.codex/tmp/arg0/codex-arg0fNFNjS:/Users/gpicchiarelli/.local/bin:/opt/homebrew/sbin:/opt/local/bin:/opt/local/sbin:/Applications/ChatGPT.app/Contents/Resources:/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS"))
    ("SBCL_HOME"
     #A((40) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/lib/sbcl"))
    ("LANG" #A((7) BASE-CHAR . "C.UTF-8"))
    ("LC_ALL" #A((7) BASE-CHAR . "C.UTF-8"))
    ("LC_CTYPE" #A((7) BASE-CHAR . "C.UTF-8")) ("TZ" NIL))
   :USER-INIT NIL :SYS-INIT NIL :STDIN :EOF)
  :SOURCE-BEFORE
  ((:PATH "spikes/SPK-08-generated-code/impronte.lisp" :GIT-BLOB
    "bf62c65738ea6cece85c4281ec74eec2523a8d4b" :CONTENTS
    ";;;; Phase0: maschere esatte scalar/SWAR, senza integrazione del primary index.
;;; REQ: REQ-SIM-001 REQ-SIM-002 REQ-BEN-002 REQ-VAL-001 REQ-AFF-003 REQ-AFF-008 REQ-AFF-016
(defpackage #:arcdocdb.spk08.impronte
  (:use #:cl) (:export #:check #:bench))
(in-package #:arcdocdb.spk08.impronte)
(declaim (optimize (safety 3) (speed 3) (debug 1)))

(deftype u64 () '(unsigned-byte 64))
(deftype h7 () '(unsigned-byte 7))
(deftype mask16 () '(unsigned-byte 16))
(deftype octets () '(simple-array (unsigned-byte 8) (*)))
(deftype words () '(simple-array (unsigned-byte 64) (*)))
(deftype masks () '(simple-array (unsigned-byte 16) (*)))
(defconstant +empty+ 128)
(defconstant +deleted+ 254)
(defconstant +low7+ #x7f7f7f7f7f7f7f7f)
(defconstant +high+ #x8080808080808080)
(defconstant +ones+ #x0101010101010101)
(defconstant +u64-mask+ #xffffffffffffffff)

(define-condition errore-impronte (error)
  ((motivo :initarg :motivo :reader motivo))
  (:report (lambda (c s) (format s \"SPK08 impronte: ~S\" (motivo c)))))

(declaim (inline finestra pack8-le zeri-esatti comprimi8 scalar16
                 scalar-u64 typedu64 packedmask16))
(declaim (ftype (function (octets fixnum) null) finestra))
(defun finestra (ctrl start)
  (declare (type octets ctrl) (type fixnum start))
  (unless (<= 0 start (- (length ctrl) 16))
    (error 'errore-impronte :motivo :invalid-window))
  nil)

(declaim (ftype (function (octets fixnum) u64) pack8-le))
(defun pack8-le (ctrl start)
  \"Caricamento portabile LE; i controlli degli accessi restano attivi.\"
  (declare (type octets ctrl) (type fixnum start))
  (let ((word 0))
    (declare (type u64 word))
    (dotimes (i 8 word)
      (setf word (logior word (ash (aref ctrl (+ start i)) (* 8 i)))))))

(declaim (ftype (function (u64) u64) zeri-esatti))
(defun zeri-esatti (x)
  \"Un bit alto per byte zero: ogni addendo di lane è <=254, senza riporto.\"
  (declare (type u64 x))
  (logand +high+
          (logxor +u64-mask+
                  (logior x +low7+ (+ (logand x +low7+) +low7+)))))

(declaim (ftype (function (u64) (unsigned-byte 8)) comprimi8))
(defun comprimi8 (high-bits)
  \"Conserva solo i bit 7,15,...,63; li porta nelle posizioni 0,...,7.\"
  (declare (type u64 high-bits))
  (let* ((x (ash (logand high-bits +high+) -7))
         (y (logand #x0003000300030003 (logior x (ash x -7))))
         (z (logand #x0000000f0000000f (logior y (ash y -14)))))
    (logand #xff (logior z (ash z -28)))))

(declaim (ftype (function (octets fixnum h7) mask16) scalar16 packedmask16)
         (ftype (function (u64 u64 h7) mask16) typedu64 scalar-u64))
(defun scalar16 (ctrl start h)
  \"Baseline su 16 byte; bit i = uguaglianza nella posizione i.\"
  (declare (type octets ctrl) (type fixnum start) (type h7 h))
  (finestra ctrl start)
  (let ((mask 0))
    (declare (type mask16 mask))
    (dotimes (i 16 mask)
      (when (= h (aref ctrl (+ start i)))
        (setf mask (logior mask (ash 1 i)))))))

(defun scalar-u64 (low high h)
  \"Baseline scalare su due parole LE già preparate.\"
  (declare (type u64 low high) (type h7 h))
  (let ((mask 0))
    (declare (type mask16 mask))
    (dotimes (i 8 mask)
      (when (= h (ldb (byte 8 (* 8 i)) low))
        (setf mask (logior mask (ash 1 i))))
      (when (= h (ldb (byte 8 (* 8 i)) high))
        (setf mask (logior mask (ash 1 (+ i 8))))))))

(defun typedu64 (low high h)
  \"SWAR su due u64; non è SIMD hardware. Restituisce un fixnum mask16.\"
  (declare (type u64 low high) (type h7 h))
  (let ((repeated (* h +ones+)))
    (declare (type u64 repeated))
    (logior (comprimi8 (zeri-esatti (logxor low repeated)))
            (ash (comprimi8 (zeri-esatti (logxor high repeated))) 8))))

(defun packedmask16 (ctrl start h)
  \"Include il packing dei 16 byte in due parole LE, a safety 3.\"
  (declare (type octets ctrl) (type fixnum start) (type h7 h))
  (finestra ctrl start)
  (typedu64 (pack8-le ctrl start) (pack8-le ctrl (+ start 8)) h))

(defun mutante-sottrazione (low high h)
  \"Mutante conservato: il prestito genera falsi bit di match. Mai nel BENCH.\"
  (declare (type u64 low high) (type h7 h))
  (let ((repeated (* h +ones+)))
    (labels ((word-mask (word)
               (let ((x (logxor word repeated)))
                 (comprimi8 (logand +high+ (lognot x)
                                    (logand +u64-mask+ (- x +ones+)))))))
      (logior (word-mask low) (ash (word-mask high) 8)))))

(defun oracle (ctrl start h)
  \"Indipendente: byte, classificazione alto bit e somma di potenze di due.\"
  (let ((result 0))
    (loop for i from 0 below 16
          for value = (aref ctrl (+ start i))
          when (and (< value 128) (= value h))
            do (incf result (expt 2 i)))
    result))

(defun passo-lcg (state)
  (declare (type (unsigned-byte 32) state))
  (ldb (byte 32 0) (+ (* state 1664525) 1013904223)))

(defun runtime ()
  (list :lisp (lisp-implementation-type) :version (lisp-implementation-version)
        :os (software-type) :os-version (software-version) :machine (machine-type)
        :machine-version (machine-version) :safety 3 :hardware-simd nil
        :packing-endian :little :host-endian
        #+little-endian :little #-little-endian :not-little-feature
        :internal-time-units-per-second internal-time-units-per-second))

(defun limite-entier (value low high name)
  (unless (and (integerp value) (<= low value high))
    (error 'errore-impronte :motivo (list :invalid-limit name value low high))))

(defun limite-secondes (seconds)
  (unless (and (realp seconds) (< 0 seconds) (<= seconds 300))
    (error 'errore-impronte :motivo (list :invalid-limit :seconds seconds))))

(defun deadline (seconds)
  (+ (get-internal-real-time) (ceiling (* seconds internal-time-units-per-second))))

(declaim (inline respecte-temps))
(defun respecte-temps (end)
  (declare (type fixnum end))
  (when (>= (get-internal-real-time) end)
    (error 'errore-impronte :motivo :time-budget)))

;; La matrice tiene byte, parole LE, query e oracle separati, preallocati.
(defstruct (matrice (:constructor %matrice))
  (ctrl (make-array 0 :element-type '(unsigned-byte 8)) :type octets)
  (offsets (make-array 0 :element-type '(unsigned-byte 8)) :type octets)
  (queries (make-array 0 :element-type '(unsigned-byte 8)) :type octets)
  (low (make-array 0 :element-type '(unsigned-byte 64)) :type words)
  (high (make-array 0 :element-type '(unsigned-byte 64)) :type words)
  (expected (make-array 0 :element-type '(unsigned-byte 16)) :type masks)
  (rows 0 :type fixnum)
  (sum 0 :type fixnum))

(defun valide-bench (rows passes warmup-passes seconds byte-budget)
  \"Preflight condiviso; permette di verificare rifiuti senza eseguire BENCH.\"
  (limite-entier rows 16 8192 :rows)
  (limite-entier passes 1 1024 :passes)
  (limite-entier warmup-passes 1 64 :warmup-passes)
  (limite-secondes seconds)
  (limite-entier byte-budget 1 67108864 :byte-budget)
  (let ((payload (* rows 104)) ; 2 datasets * (32+1+1+8+8+2) byte/riga.
        (operations (* 8 rows (+ warmup-passes (* 5 passes)))))
    (when (> payload byte-budget)
      (error 'errore-impronte :motivo :payload-budget))
    (when (> operations 200000000)
      (error 'errore-impronte :motivo :operation-budget))
    (values payload operations)))

(defun prepare-matrice (rows dataset)
  (declare (type fixnum rows))
  (let ((m (%matrice :rows rows
                    :ctrl (make-array (* rows 32) :element-type '(unsigned-byte 8)
                                      :initial-element +deleted+)
                    :offsets (make-array rows :element-type '(unsigned-byte 8))
                    :queries (make-array rows :element-type '(unsigned-byte 8))
                    :low (make-array rows :element-type '(unsigned-byte 64))
                    :high (make-array rows :element-type '(unsigned-byte 64))
                    :expected (make-array rows :element-type '(unsigned-byte 16))))
        (state #x6d61736b))
    (declare (type (unsigned-byte 32) state))
    (dotimes (row rows m)
      (let* ((offset (logand row 15)) (start (+ (* row 32) offset))
             (h (if (eq dataset :mixed) (logand (ash (setf state (passo-lcg state)) -16) 127)
                    (if (evenp (floor row 8)) 0 127))))
        (setf (aref (matrice-offsets m) row) offset
              (aref (matrice-queries m) row) h)
        (dotimes (i 16)
          (setf state (passo-lcg state))
          (setf (aref (matrice-ctrl m) (+ start i))
                (if (eq dataset :mixed)
                    (case (mod (+ row i) 8)
                      (0 h) (1 +empty+) (2 +deleted+)
                      (otherwise (ldb (byte 8 16) state)))
                    (case (mod row 8)
                      (0 (if (evenp i) h (logxor h 1)))
                      (1 h)
                      (2 (logxor h 1))
                      (3 (if (evenp i) +empty+ +deleted+))
                      (4 (logior 128 h))
                      (5 (case i (7 h) (8 (logxor h 1)) (otherwise 255)))
                      (6 (if (zerop i) h (logxor h 1)))
                      (otherwise (if (evenp i) 0 127))))))
        (let ((expected (oracle (matrice-ctrl m) start h)))
          (unless (= expected (scalar16 (matrice-ctrl m) start h)
                     (packedmask16 (matrice-ctrl m) start h))
            (error 'errore-impronte :motivo :bench-fixture))
          (setf (aref (matrice-low m) row) (pack8-le (matrice-ctrl m) start)
                (aref (matrice-high m) row) (pack8-le (matrice-ctrl m) (+ start 8))
                (aref (matrice-expected m) row) expected)
          (unless (= expected (scalar-u64 (aref (matrice-low m) row)
                                          (aref (matrice-high m) row) h)
                     (typedu64 (aref (matrice-low m) row)
                               (aref (matrice-high m) row) h))
            (error 'errore-impronte :motivo :bench-word-fixture))
          (incf (matrice-sum m) expected))))))

(defmacro definit-cycle (name expression)
  \"Quattro cicli diretti; nessun funcall o costruzione del report nella misura.\"
  `(defun ,name (m passes end)
     (declare (type matrice m) (type fixnum passes end))
     (let ((ctrl (matrice-ctrl m)) (offsets (matrice-offsets m))
           (queries (matrice-queries m)) (low (matrice-low m)) (high (matrice-high m))
           (rows (matrice-rows m)) (acc 0) (operations 0))
       (declare (type octets ctrl offsets queries) (type words low high)
                (type fixnum rows acc operations) (ignorable ctrl offsets low high))
       (respecte-temps end)
       (let ((start-ticks (get-internal-real-time))
             (start-bytes (sb-ext:get-bytes-consed)))
         (dotimes (pass passes)
           (dotimes (row rows)
             (incf acc ,expression)
             (incf operations)
             (when (zerop (logand operations 4095)) (respecte-temps end))))
         (let* ((end-bytes (sb-ext:get-bytes-consed))
                (end-ticks (get-internal-real-time))
                (ticks (- end-ticks start-ticks)) (bytes (- end-bytes start-bytes)))
           (respecte-temps end)
           (unless (= acc (* passes (matrice-sum m)))
             (error 'errore-impronte :motivo (list :cycle-checksum ',name acc)))
           (values ticks bytes acc operations))))))

(definit-cycle cycle-scalar16
  (scalar16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definit-cycle cycle-packedmask16
  (packedmask16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definit-cycle cycle-scalar-u64
  (scalar-u64 (aref low row) (aref high row) (aref queries row)))
(definit-cycle cycle-typedu64
  (typedu64 (aref low row) (aref high row) (aref queries row)))

(defun execute-cycle (kernel m passes end)
  \"Dispatch prima della misura; il corpo del ciclo chiama direttamente il kernel.\"
  (ecase kernel
    (:scalar16 (cycle-scalar16 m passes end))
    (:packedmask16 (cycle-packedmask16 m passes end))
    (:scalar-u64 (cycle-scalar-u64 m passes end))
    (:typedu64 (cycle-typedu64 m passes end))))

(defun bench (&key (rows 1024) (passes 64) (warmup-passes 2)
                   (seconds 60) (byte-budget 16777216))
  \"Matrice scalar/SWAR seriale, cinque repliche. Da eseguire soltanto nel parent.\"
  (multiple-value-bind (payload total-operations)
      (valide-bench rows passes warmup-passes seconds byte-budget)
    (let* ((end (deadline seconds))
           (mixed (prepare-matrice rows :mixed))
           (adversarial (prepare-matrice rows :adversarial))
           (measurements nil) (observable 0) (warmup-operations 0))
      (respecte-temps end)
      (loop for m in (list mixed adversarial) do
        (dolist (kernel '(:scalar16 :packedmask16 :scalar-u64 :typedu64))
          (multiple-value-bind (ticks bytes checksum operations)
              (execute-cycle kernel m warmup-passes end)
            (declare (ignore ticks bytes))
            (incf observable checksum) (incf warmup-operations operations))))
      (dotimes (replica 5)
        (loop for dataset in '(:mixed :adversarial)
              for m in (list mixed adversarial) for dataset-index from 0 do
          (loop for pair in '((:scalar16 :packedmask16) (:scalar-u64 :typedu64))
                for representation in '(:bytes-with-packing :prepacked-u64)
                for representation-index from 0
                for order = (if (evenp (+ replica dataset-index representation-index))
                                pair (reverse pair)) do
            (loop for kernel in order for order-index from 0 do
              (multiple-value-bind (ticks bytes checksum operations)
                  (execute-cycle kernel m passes end)
                (unless (plusp ticks)
                  (error 'errore-impronte :motivo :clock-resolution))
                (incf observable checksum)
                (push (list :dataset dataset :representation representation :kernel kernel
                            :replica (1+ replica) :order order :order-index order-index
                            :operations operations :ticks ticks :bytes-consed bytes
                            :checksum checksum
                            :ns/op (/ (* ticks 1d9)
                                      (* internal-time-units-per-second operations))
                            :bytes/op (/ bytes (coerce operations 'double-float)))
                      measurements))))))
      (respecte-temps end)
      (unless (= (length measurements) 40)
        (error 'errore-impronte :motivo :incomplete-bench))
      (list :status :ok :module :impronte-scalar-swar :runtime (runtime)
            :rows rows :passes passes :warmup-passes warmup-passes :replicas 5
            :measurements (nreverse measurements) :raw-samples t
            :observable-checksum observable :warmup-operations warmup-operations
            :measured-operations (* 40 rows passes) :total-operations total-operations
            :payload-bytes payload :seed #x6d61736b
            :limits (list :seconds seconds :byte-budget byte-budget :max-operations 200000000
                          :max-block-operations 4096 :cooperative-deadline t
                          :gc-and-scheduling-included t :report-and-fixtures-excluded t
                          :payload-excludes-object-headers t :no-rss t
                          :no-overhead-subtraction t :hardware-simd nil)))))

(defun refuse-dynamique (function args expected-condition input)
  \"Argomenti negativi opachi al compilatore; verifica l'assenza di mutazione.\"
  (let ((before (copy-seq input)) (caught nil))
    (handler-case (apply (symbol-function function) args)
      (error (c)
        (unless (typep c expected-condition) (error c))
        (setf caught (type-of c))))
    (unless (and caught (equalp before input))
      (error 'errore-impronte :motivo (list :negative-control function args)))
    (list :function function :arguments args :condition caught :input-unchanged t)))

(defun check (&key (max-cases 4000000) (differential-cases 20000) (seconds 120))
  \"Campagne esaustive/differenziali limitate, oracle indipendente e mutante.\"
  (limite-entier max-cases 1 4000000 :max-cases)
  (limite-entier differential-cases 1 100000 :differential-cases)
  (limite-secondes seconds)
  (let ((ctrl (make-array 64 :element-type '(unsigned-byte 8) :initial-element +empty+))
        (shadow (make-array 64 :element-type '(unsigned-byte 8)))
        (end (deadline seconds)) (cases 0) (campaigns nil) (negatives nil)
        (mutants nil) (state #x1a2b3c4d))
    (declare (type octets ctrl shadow) (type fixnum cases end)
             (type (unsigned-byte 32) state))
    (labels ((verify-group (start h)
               (declare (type fixnum start) (type h7 h))
               (when (>= cases max-cases)
                 (error 'errore-impronte :motivo :case-budget))
               (incf cases)
               (when (zerop (logand cases 4095)) (respecte-temps end))
               (replace shadow ctrl)
               (let* ((expected (oracle ctrl start h))
                      (low (pack8-le ctrl start)) (high (pack8-le ctrl (+ start 8)))
                      (a (scalar16 ctrl start h)) (b (packedmask16 ctrl start h))
                      (c (scalar-u64 low high h)) (d (typedu64 low high h)))
                 (unless (and (= expected a b c d) (equalp shadow ctrl))
                   (error 'errore-impronte
                          :motivo (list :differential cases start h :expected expected
                                        :actual (list a b c d) :ctrl (coerce ctrl 'list))))
                 expected))
             (campaign (name before expected)
               (let ((count (- cases before)))
                 (unless (= count expected)
                   (error 'errore-impronte :motivo (list :campaign-count name count expected)))
                 (push (list :name name :groups count :kernel-comparisons (* count 4)
                             :input-unchanged t) campaigns)))
             (negative (function args condition)
               (push (refuse-dynamique function args condition ctrl) negatives)))
      ;; Tutti i byte/query, ciascuna posizione isolata.
      (let ((before cases))
        (dotimes (h 128)
          (dotimes (position 16)
            (fill ctrl +empty+)
            (dotimes (value 256)
              (setf (aref ctrl position) value)
              (verify-group 0 h))))
        (campaign :all-byte-query-position before (* 128 16 256)))
      ;; Coppie adiacenti, incluse lane 7/8 tra parole; query ai due estremi.
      (let ((before cases))
        (dolist (h '(0 127))
          (dotimes (position 15)
            (fill ctrl +empty+)
            (dotimes (a 256)
              (setf (aref ctrl position) a)
              (dotimes (b 256)
                (setf (aref ctrl (1+ position)) b)
                (verify-group 0 h)))))
        (campaign :all-adjacent-byte-pairs before (* 2 15 256 256)))
      ;; Tutte le coppie ordinate di posizioni su dominio significativo.
      (let ((before cases) (alphabet '(0 1 126 127 128 129 254 255)))
        (dotimes (p 16)
          (dotimes (q 16)
            (dolist (a alphabet)
              (dolist (b alphabet)
                (fill ctrl +empty+)
                (setf (aref ctrl p) a (aref ctrl q) b)
                (dolist (h '(0 1 126 127)) (verify-group 0 h))))))
        (campaign :all-position-pairs-small-domain before (* 16 16 8 8 4)))
      ;; Esaustivo: tutte le parole 4^8, in entrambe le metà.
      (let ((before cases) (alphabet #(0 1 128 254)))
        (dotimes (code 65536)
          (dotimes (half 2)
            (fill ctrl +empty+)
            (dotimes (i 8)
              (setf (aref ctrl (+ (* half 8) i))
                    (aref alphabet (ldb (byte 2 (* 2 i)) code))))
            (dolist (h '(0 1 127)) (verify-group 0 h))))
        (campaign :exhaustive-four-to-eight before (* 65536 2 3)))
      ;; Tutte le mask16, controllo di compressione e dei bit alti.
      (let ((before cases))
        (fill ctrl +deleted+)
        (dotimes (mask 65536)
          (dotimes (i 16) (setf (aref ctrl i) (if (logbitp i mask) 127 +empty+)))
          (unless (= mask (verify-group 0 127))
            (error 'errore-impronte :motivo :compression-golden)))
        (campaign :all-mask16 before 65536))
      ;; Offset 0..31, finestra esatta e padding; golden LE non simmetrico.
      (let ((before cases))
        (dotimes (start 32)
          (fill ctrl +deleted+)
          (dotimes (i 16) (setf (aref ctrl (+ start i)) i))
          (unless (and (= (pack8-le ctrl start) #x0706050403020100)
                       (= (pack8-le ctrl (+ start 8)) #x0f0e0d0c0b0a0908))
            (error 'errore-impronte :motivo :endian-golden))
          (dotimes (h 16)
            (unless (= (verify-group start h) (ash 1 h))
              (error 'errore-impronte :motivo :position-golden))))
        (dolist (h '(0 127))
          (fill ctrl h)
          (unless (= (verify-group 48 h) #xffff)
            (error 'errore-impronte :motivo :full-mask-golden))
          (fill ctrl +empty+) (verify-group 48 h)
          (fill ctrl +deleted+) (verify-group 48 h))
        (campaign :offset-endian-boundaries before 518))
      ;; Stato u32 esplicito, nessun RANDOM/SXHASH e nessun clock negli input.
      (let ((before cases))
        (dotimes (n differential-cases)
          (dotimes (i 64)
            (setf state (passo-lcg state) (aref ctrl i) (ldb (byte 8 16) state)))
          (setf state (passo-lcg state))
          (verify-group (logand n 31) (logand (ash state -16) 127)))
        (campaign :deterministic-differential before differential-cases))
      ;; Testimoni del prestito per ogni coppia nella stessa parola, due query.
      (dolist (h '(0 127))
        (dolist (position '(0 1 2 3 4 5 6 8 9 10 11 12 13 14))
          (fill ctrl +empty+)
          (setf (aref ctrl position) h (aref ctrl (1+ position)) (logxor h 1))
          (let* ((expected (verify-group 0 h))
                 (actual (mutante-sottrazione (pack8-le ctrl 0) (pack8-le ctrl 8) h)))
            (unless (and (/= actual expected) (logbitp (1+ position) actual)
                         (not (logbitp (1+ position) expected)))
              (error 'errore-impronte :motivo :mutant-not-killed))
            (push (list :query h :position position :ctrl (coerce (subseq ctrl 0 16) 'list)
                        :oracle expected :mutant actual :extra-position (1+ position)) mutants))))
      ;; Il prestito non passa fra due parole; il mutante in questo caso concorda.
      (fill ctrl +empty+) (setf (aref ctrl 7) 0 (aref ctrl 8) 1)
      (unless (= (verify-group 0 0)
                 (mutante-sottrazione (pack8-le ctrl 0) (pack8-le ctrl 8) 0))
        (error 'errore-impronte :motivo :word-boundary-mutant))
      ;; Invalid args: runtime safety3, nessuna modifica dei byte sorgenti.
      (dolist (function '(scalar16 packedmask16))
        (dolist (h '(-1 128 255 1/2 :bad))
          (negative function (list ctrl 0 h) 'type-error))
        (dolist (start '(-1 49 64))
          (negative function (list ctrl start 0) 'errore-impronte))
        (dolist (start '(1/2 :bad))
          (negative function (list ctrl start 0) 'type-error))
        (dolist (length '(0 1 15))
          (let ((short (make-array length :element-type '(unsigned-byte 8))))
            (push (refuse-dynamique function (list short 0 0) 'errore-impronte short)
                  negatives)))
        (negative function (list (make-array 16 :initial-element 0) 0 0) 'type-error)
        (negative function (list (make-array '(4 4) :element-type '(unsigned-byte 8)) 0 0)
                  'type-error)
        (negative function (list (make-array 16 :element-type '(unsigned-byte 8)
                                            :fill-pointer 16) 0 0) 'type-error)
        (negative function (list (make-array 16 :element-type '(unsigned-byte 8)
                                            :displaced-to ctrl) 0 0) 'type-error))
      (dolist (function '(scalar-u64 typedu64))
        (dolist (value (list -1 (expt 2 64) 1/2 :bad))
          (negative function (list value 0 0) 'type-error)
          (negative function (list 0 value 0) 'type-error))
        (dolist (h '(-1 128 255 1/2 :bad))
          (negative function (list 0 0 h) 'type-error)))
      ;; Esaurimento: CHECK rifiuta il secondo caso, senza chiamare BENCH.
      (negative 'check '(:max-cases 1 :differential-cases 1 :seconds 120) 'errore-impronte)
      (negative 'check '(:max-cases 0) 'errore-impronte)
      (negative 'check '(:differential-cases 100001) 'errore-impronte)
      (negative 'check '(:seconds 0) 'errore-impronte)
      (negative 'respecte-temps (list (get-internal-real-time)) 'errore-impronte)
      (dolist (args '((15 1 1 60 16777216) (8193 1 1 60 16777216)
                      (16 0 1 60 16777216) (16 1025 1 60 16777216)
                      (16 1 0 60 16777216) (16 1 65 60 16777216)
                      (16 1 1 0 16777216) (16 1 1 301 16777216)
                      (16 1 1 60 0) (16 1 1 60 67108865)
                      (16 1 1 60 1) (8192 1024 64 60 67108864)))
        (negative 'valide-bench args 'errore-impronte))
      (respecte-temps end)
      (setf negatives (nreverse negatives))
      (list :status :ok :module :impronte-scalar-swar :runtime (runtime)
            :groups cases :kernel-comparisons (* 4 cases)
            :campaigns (nreverse campaigns) :differential-seed #x1a2b3c4d
            :final-lcg-state state :negative-controls negatives
            :negative-control-count (length negatives)
            :mutant :borrow-subtraction :mutant-killed-count (length mutants)
            :mutant-witnesses (nreverse mutants) :word-boundary-controls 1
            :mask-api '((scalar16 ctrl start h7) (packedmask16 ctrl start h7)
                        (scalar-u64 low high h7) (typedu64 low high h7))
            :bench-api '(bench &key rows passes warmup-passes seconds byte-budget)
            :bench-executed nil
            :limits (list :max-cases max-cases :differential-cases differential-cases
                          :seconds seconds :checkpoint-groups 4096
                          :cooperative-deadline t :domain-byte-values 256 :query-values 128
                          :group-bytes 16 :packed-words 2 :small-domain-word-states 65536
                          :no-source-mutation t :hardware-simd nil :production-integration nil)
            :disassembly
            (loop for name in '(scalar16 packedmask16 scalar-u64 typedu64
                                cycle-scalar16 cycle-packedmask16 cycle-scalar-u64 cycle-typedu64)
                  collect (list :function name :text
                                (with-output-to-string (*standard-output*)
                                  (disassemble (symbol-function name)))))))))
")
   (:PATH "spikes/SPK-08-generated-code/metodo-impronte.md" :GIT-BLOB
    "060b10fd79901e6f3a664e28b3c2153c2c8aa214" :CONTENTS
    "# SPK-08 — metodo preregistrato per le impronte

;;; REQ: REQ-SIM-001 REQ-SIM-002 REQ-BEN-002 REQ-VAL-001 REQ-AFF-003 REQ-AFF-008 REQ-AFF-016

Registrato prima di qualsiasi compile/CHECK. Ambito Phase0: solo il nuovo
`impronte.lisp`, package `ARCDOCDB.SPK08.IMPRONTE`, export `CHECK` e `BENCH`.
Tutto il lavoro avviene nel checkout isolato
`/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB`.
Common Lisp/SBCL, safety 3, nessuna dipendenza da altri spike e nessuna
integrazione dell'indice. Nessun commit o push.

## Contratto e algoritmo

Un gruppo contiene 16 byte ctrl. Le impronte valide sono 0–127; empty = 128,
deleted = 254. Tutti gli altri byte con alto bit acceso sono esclusi dal match.
La maschera risultante ha il bit i per la posizione i (0–15). Query fuori
0–127, tipi errati e finestre di meno di 16 byte producono errore.
L'input è di sola lettura. La serializzazione delle due parole u64 è
esplicitamente little endian: byte i nei bit 8*i; il risultato non dipende
dall'endian della macchina. Non si usano accessi di memoria non allineati o VOP.

Per x = word XOR query ripetuta, la maschera esatta degli zeri è
`NOT (((x AND 0x7f7f7f7f7f7f7f7f) + 0x7f7f7f7f7f7f7f7f) OR x OR
0x7f7f7f7f7f7f7f7f) AND 0x8080808080808080`.
Ogni somma di lane è al massimo 254: non c'è riporto fra byte.
Tre piegature comprimono gli otto bit alti in un byte; due parole danno u16.
Il mutante `(x - 0x0101010101010101) AND NOT x AND 0x8080808080808080`
conserva il limite del prestito, con x = byte 0 seguito da byte 1: utile come
test di esistenza di uno zero, inadeguato come maschera esatta per posizione.
Il mutante resta una funzione separata, mai una variante selezionabile dei kernel.

Kernel: `scalar16` e `packedmask16` su byte array e offset; `scalar-u64` e
`typedu64` su due u64. Tipi specializzati, safety 3 e chiamate dirette/inline
nei cicli. La compilazione/disassemblato e i campioni di bytes-consed
permettono di valutare le allocazioni; non si presume che una chiamata Lisp
esterna con u64 boxed non allochi. SWAR è aritmetica su parole intere, non
SIMD hardware. Un oracle scalare distinto legge solo i byte e somma potenze
di due, senza riusare packing, compressione o formula SWAR.

## CHECK e budget

1. Strict compile in processo SBCL senza init: warning e style-warning sono
   fatali, oltre ai valori warnings/failure di compile-file. FASL solo in `out/`.
2. Tutti i 256 byte, tutte le 128 query e tutte le 16 posizioni isolate.
3. Tutte le coppie di byte (256²) nelle 15 coppie adiacenti, query 0 e 127;
   comprende il confine fra le parole e ogni posizione con prestito.
4. Tutte le 16² coppie di posizioni, byte nel dominio piccolo
   {0, 1, 126, 127, 128, 129, 254, 255}, query {0, 1, 126, 127}.
5. Tutte le 4^8 parole su {0, 1, 128, 254}, ciascuna nelle due metà, query
   {0, 1, 127}; dominio piccolo interamente enumerato, non campionato.
6. Differenziale più grande: 20.000 gruppi da LCG u32 con seme fisso;
   offset 0–31, byte arbitrari, query 0–127. Fixture golden endian e maschere
   vuota/piena/alternata; tutte le maschere u16 per la compressione.
7. Controlli negativi del mutante, invalid args attraverso chiamata dinamica
   per evitare warning statici intenzionali; confronto integrale input
   prima/dopo, anche sul rifiuto. Rifiuti deterministici di budget CHECK/BENCH
   prima di qualsiasi misura BENCH.

CHECK ha limite massimo 4.000.000 confronti di gruppo, default uguale al
massimo, 20.000 gruppi differenziali (tetto 100.000), 120 secondi (tetto 300).
Scadenza controllata ogni 4096 confronti e alla conclusione, limite cooperativo;
un limite esaurito è errore, mai successo parziale. I conteggi sono riportati
per campagna, con controlli di congruenza. Conservare disassemblato locale
dei quattro kernel e dei cicli diretti. La plist riporta :status :ok solo
dopo tutte le campagne e include limiti e piattaforma reale.

## BENCH da eseguire soltanto nel parent

API prevista: `(bench &key (rows 1024) (passes 64) (warmup-passes 2)
(seconds 60) (byte-budget 16777216))`. Cinque repliche obbligatorie.
Due dataset, misto e avversario (prestiti, hit pieno, miss, speciali, alto bit,
0/127, confine di parola); matrice di byte e parole preallocata, stessi query
e oracle per entrambi i kernel di ciascun confronto. Offset 0–15 su righe
da 32 byte. Packing/preparazione/validazione/oracle/warmup esclusi dalle
misure. Confronti: scalar16/packedmask16 e scalar-u64/typedu64.
Ordine alternato AB/BA per replica e cella della matrice, esplicitamente
riportato. Accumulatore numerico verificato contro oracle e pubblicato.

Ogni campione misura ticks e bytes-consed solo intorno al ciclo diretto;
riporta operazioni effettive, ns/op calcolati, byte totali e per operazione,
checksum, ordine e replica. Non si sottrae un overhead stimato e non si
inventano tempi; ticks = 0 rende la misura non risolta e produce errore.
GC e scheduling durante il ciclo restano inclusi. Allocazioni del report
e fixture escluse; bytes-consed non è RSS. Il ciclo legge i dati preallocati
e produce un checksum fixnum; non crea strutture per chiamata.
I limiti sono rows 16–8192, passes 1–1024, warmup 1–64, seconds >0 e ≤300,
payload byte-budget ≤64 MiB e operazioni totali ≤200.000.000.
La scadenza è cooperativa fra blocchi di al massimo 4096 operazioni, con
stessi controlli nei due cicli; esaurimento segnala errore senza plist :ok.
BENCH restituisce :status :ok, :measurements, limiti e campioni raw,
solo dopo cinque repliche complete per tutte le celle. Non viene eseguito
in questo lavoro, neppure per warmup o smoke test.

## Evidenze e limiti dell'inferenza

Ogni tentativo compile/CHECK, incluso un fallimento, avrà nuovi file ignored
`out/` con schema-version 1, argv e stdin esplicito, ambiente, hash/contenuti
prima/dopo, risultato decodificato, stdout/stderr integrali e limiti.
Il wrapper esistente `tools/record-command.lisp` può registrare il comando;
un driver nuovo in `out/` aggiunge risultato del modulo, warning, source
immutato e log senza troncamento. Driver e stdin vengono inclusi nelle prove.
Nessun file esistente di core/run/suite/tools/docs/ADR/REQ viene modificato.
Alla consegna si elencano tutti i tentativi, i percorsi e i conteggi reali.

Piattaforma osservata inizialmente: Darwin 27.0.0, arm64, SBCL da
`/opt/homebrew/bin/sbcl`. Versione SBCL, CPU, risoluzione clock e feature
endian vengono raccolte dai processi registrati. La prova riguarda questa
piattaforma; non qualifica x86-64, SIMD hardware, l'indice o il motore.
Nessuna superiorità prestazionale prima dei campioni del parent.
")
   (:PATH "spikes/SPK-08-generated-code/out/record-impronte.lisp" :GIT-BLOB
    "57916fb52bb5c61900f8ec86399df6bbf8c899eb" :CONTENTS
    ";;;; Driver locale delle sole prove compile/CHECK; nessuna misura BENCH.
(require :asdf)
(require :sb-posix)
(declaim (optimize (safety 3) (debug 3)))
(defparameter *root* #p\"/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB/\")
(defparameter *source* \"spikes/SPK-08-generated-code/impronte.lisp\")
(defparameter *method* \"spikes/SPK-08-generated-code/metodo-impronte.md\")
(defparameter *driver* \"spikes/SPK-08-generated-code/out/record-impronte.lisp\")

(defun raw-command (argv)
  (string-trim '(#\\Space #\\Return #\\Newline)
               (uiop:run-program argv :output :string :error-output :string)))
(defun contents (path) (uiop:read-file-string path))
(defun snapshot ()
  (loop for path in (list *source* *method* *driver*)
        collect (list :path path :git-blob (raw-command (list \"git\" \"hash-object\" \"--\" path))
                      :contents (contents path))))
(defun save-data (path data)
  (with-open-file (s path :direction :output :if-exists :supersede)
    (let ((*print-readably* t) (*print-pretty* t) (*print-circle* t))
      (write data :stream s) (terpri s))))
(defun save-text (path text)
  (with-open-file (s path :direction :output :if-exists :supersede)
    (write-string text s)))
(defun new-out ()
  (loop for n below 1000
        for dir = (merge-pathnames
                   (format nil \"spikes/SPK-08-generated-code/out/~D-impronte-~D-~D/\"
                           (get-universal-time) (sb-posix:getpid) n) *root*)
        do (handler-case (progn (sb-posix:mkdir dir #o700) (return-from new-out dir))
             (sb-posix:syscall-error (c)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno c)) (error c)))))
  (error \"Esauriti i tentativi di creare il record.\"))
(defun observed-environment ()
  (list :cwd (namestring (truename \"./\")) :lisp (lisp-implementation-type)
        :version (lisp-implementation-version) :os (software-type)
        :os-version (software-version) :machine (machine-type)
        :cpu (raw-command '(\"sysctl\" \"-n\" \"machdep.cpu.brand_string\"))
        :memory-bytes (raw-command '(\"sysctl\" \"-n\" \"hw.memsize\"))
        :logical-cpus (raw-command '(\"sysctl\" \"-n\" \"hw.logicalcpu\"))
        :load-average (raw-command '(\"sysctl\" \"-n\" \"vm.loadavg\"))
        :external-load :uncontrolled :commit (raw-command '(\"git\" \"rev-parse\" \"HEAD\"))
        :internal-time-units-per-second internal-time-units-per-second
        :process-id (sb-posix:getpid) :features *features*
        :inherited-environment
        (loop for name in '(\"PATH\" \"SBCL_HOME\" \"LANG\" \"LC_ALL\" \"LC_CTYPE\" \"TZ\")
              collect (list name (sb-ext:posix-getenv name)))
        :user-init nil :sys-init nil :stdin :eof))

(defun main ()
  (unless (equal (truename \"./\") (truename *root*))
    (error \"Il driver richiede il checkout isolato.\"))
  (let* ((args (uiop:command-line-arguments))
         (mode (first args))
         (out (new-out)) (path (merge-pathnames \"report.lisp\" out))
         (stdout (make-string-output-stream)) (stderr (make-string-output-stream))
         (warnings 0) (style-warnings 0)
         (record (list :schema-version 1 :kind :impronte-compile-check :status :running
                       :command (append (list \"/opt/homebrew/bin/sbcl\" \"--noinform\"
                                              \"--no-sysinit\" \"--no-userinit\" \"--script\"
                                              *driver*) args)
                       :runtime-argv sb-ext:*posix-argv*
                       :stdin (list :mode :eof :contents \"\" :redirect \"/dev/null\")
                       :environment (observed-environment) :source-before (snapshot)
                       :started-at-universal-time (get-universal-time)
                       :limits '(:safety 3 :warning-fatal t :style-warning-fatal t
                                 :compile-only-this-module t :bench-never-called t
                                 :check-max-cases 4000000 :check-seconds 120
                                 :stdout-truncated nil :stderr-truncated nil
                                 :source-scope :impronte-method-and-driver
                                 :deadline-cooperative t)))
         (start (get-internal-real-time)) (exit-code 0))
    (save-data path record)
    (let ((*standard-output* stdout) (*error-output* stderr) (*trace-output* stderr))
      (handler-case
          (handler-bind
              ((warning (lambda (c)
                          (if (typep c 'style-warning) (incf style-warnings) (incf warnings))
                          (format *error-output* \"~&~A: ~A~%\" (type-of c) c)
                          (error \"Avviso di compilazione/esecuzione fatale: ~A\" c))))
            (unless (member mode '(\"compile\" \"compile-check\") :test #'equal)
              (error \"Modalità non consentita: ~S\" mode))
            (let ((fasl (merge-pathnames \"impronte.fasl\" out)))
              (setf (getf record :compile) (list :status :running :source *source*
                                               :output (namestring fasl)))
              (save-data path record)
              (multiple-value-bind (file warned failed)
                  (compile-file *source* :output-file fasl)
                (setf (getf record :compile)
                      (list :status (if (or warned failed) :failed :ok)
                            :output (and file (namestring file)) :warnings-p warned :failure-p failed))
                (when (or warned failed (null file)) (error \"Strict compile fallita.\")))
              (when (equal mode \"compile-check\")
                (load fasl)
                (let* ((package (find-package \"ARCDOCDB.SPK08.IMPRONTE\"))
                       (fn (find-symbol \"CHECK\" package))
                       (check-start (get-internal-real-time))
                       (result (funcall fn)))
                  (unless (eq (getf result :status) :ok) (error \"CHECK senza :status :ok.\"))
                  (setf (getf record :decoded-check) result
                        (getf record :check-seconds)
                        (/ (- (get-internal-real-time) check-start)
                           (coerce internal-time-units-per-second 'double-float)))
                  (save-data (merge-pathnames \"check-data.lisp\" out)
                             (list :schema-version 1 :kind :module-check :result result))
                  (dolist (item (getf result :disassembly))
                    (save-text (merge-pathnames
                                (format nil \"disassembly-~(~A~).txt\" (getf item :function)) out)
                               (getf item :text)))
                  (format t \"~&CHECK :OK; groups=~D kernels=~D negatives=~D mutants=~D~%\"
                          (getf result :groups) (getf result :kernel-comparisons)
                          (getf result :negative-control-count) (getf result :mutant-killed-count))))
              (setf (getf record :status) :ok)))
        (error (c)
          (setf exit-code 1 (getf record :status) :failed
                (getf record :failure) (list :condition (type-of c) :message (princ-to-string c)))
          (format *error-output* \"~&FALLIMENTO ~A: ~A~%\" (type-of c) c))))
    (let ((out-text (get-output-stream-string stdout)) (err-text (get-output-stream-string stderr)))
      (setf (getf record :stdout) out-text (getf record :stderr) err-text)
      (save-text (merge-pathnames \"stdout.txt\" out) out-text)
      (save-text (merge-pathnames \"stderr.txt\" out) err-text))
    (setf (getf record :warning-count) warnings (getf record :style-warning-count) style-warnings
          (getf record :exit-code) exit-code
          (getf record :finished-at-universal-time) (get-universal-time)
          (getf record :wall-seconds)
          (/ (- (get-internal-real-time) start)
             (coerce internal-time-units-per-second 'double-float)))
    (save-data path record)
    (setf (getf record :source-after) (snapshot)
          (getf record :source-consistency)
          (if (equal (getf record :source-before) (getf record :source-after)) :stable :changed))
    (unless (eq (getf record :source-consistency) :stable)
      (setf exit-code 1 (getf record :exit-code) 1 (getf record :status) :source-changed))
    (save-data path record)
    (format t \"~&~S; warnings=~D style-warnings=~D; record: ~A~%\"
            (getf record :status) warnings style-warnings path)
    (when (getf record :failure) (format t \"~S~%\" (getf record :failure)))
    (sb-ext:exit :code exit-code)))
(main)
"))
  :STARTED-AT-UNIVERSAL-TIME 4000480808 :LIMITS
  (:SAFETY 3 :WARNING-FATAL T :STYLE-WARNING-FATAL T :COMPILE-ONLY-THIS-MODULE
   T :BENCH-NEVER-CALLED T :CHECK-MAX-CASES 4000000 :CHECK-SECONDS 120
   :STDOUT-TRUNCATED NIL :STDERR-TRUNCATED NIL :SOURCE-SCOPE
   :IMPRONTE-METHOD-AND-DRIVER :DEADLINE-COOPERATIVE T))
 :LIMITS (:REPRESENTATION-ONLY :ORIGINAL-OUTPUT-UNCHANGED))
