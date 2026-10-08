(:SCHEMA-VERSION 1 :KIND :PORTABLE-EVIDENCE :STATUS :OK :REPRESENTATION
 :FOREIGN-SYMBOLS-AS-QUALIFIED-STRINGS :RAW-ORIGINAL
 "(:SOURCE-CONSISTENCY :STABLE :SOURCE-AFTER
 ((:PATH #1=\"spikes/SPK-08-generated-code/impronte.lisp\" :GIT-BLOB
   \"2ad6de50fdb7ef94cda1991dce08140fa2ed8ce8\" :CONTENTS
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

(macrolet ((definit-cycle (name expression)
  ;; Quattro cicli diretti; nessun macro globale ridefinito al caricamento.
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
           (values ticks bytes acc operations)))))))

(definit-cycle cycle-scalar16
  (scalar16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definit-cycle cycle-packedmask16
  (packedmask16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definit-cycle cycle-scalar-u64
  (scalar-u64 (aref low row) (aref high row) (aref queries row)))
(definit-cycle cycle-typedu64
  (typedu64 (aref low row) (aref high row) (aref queries row))))

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
   \"fbbfc43ea30ebe9a79384735efe256a09c393d23\" :CONTENTS
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
              (setf (getf record :stage) :compile)
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
                (setf (getf record :stage) :load)
                (load fasl)
                (setf (getf record :load) (list :status :ok :fasl (namestring fasl))
                      (getf record :stage) :check)
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
              (setf (getf record :status) :ok (getf record :stage) :complete)))
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
 :WALL-SECONDS 1.005499d0 :FINISHED-AT-UNIVERSAL-TIME 4000480869 :EXIT-CODE 0
 :STYLE-WARNING-COUNT 0 :WARNING-COUNT 0 :STDERR \"\" :STDOUT
 \"CHECK :OK; groups=3035203 kernels=12140812 negatives=77 mutants=28
\"
 :CHECK-SECONDS 0.781766d0 :DECODED-CHECK
 (:STATUS :OK :MODULE :IMPRONTE-SCALAR-SWAR :RUNTIME
  (:LISP #4=#A((4) BASE-CHAR . \"SBCL\") :VERSION #5=#A((5) BASE-CHAR . \"2.6.9\")
   :OS #A((6) BASE-CHAR . \"Darwin\") :OS-VERSION #6=#A((6) BASE-CHAR . \"27.0.0\")
   :MACHINE #7=#A((5) BASE-CHAR . \"ARM64\") :MACHINE-VERSION
   #A((8) BASE-CHAR . \"Apple M4\") :SAFETY 3 :HARDWARE-SIMD NIL :PACKING-ENDIAN
   :LITTLE :HOST-ENDIAN :LITTLE :INTERNAL-TIME-UNITS-PER-SECOND 1000000)
  :GROUPS 3035203 :KERNEL-COMPARISONS 12140812 :CAMPAIGNS
  ((:NAME :ALL-BYTE-QUERY-POSITION :GROUPS 524288 :KERNEL-COMPARISONS 2097152
    :INPUT-UNCHANGED T)
   (:NAME :ALL-ADJACENT-BYTE-PAIRS :GROUPS 1966080 :KERNEL-COMPARISONS 7864320
    :INPUT-UNCHANGED T)
   (:NAME :ALL-POSITION-PAIRS-SMALL-DOMAIN :GROUPS 65536 :KERNEL-COMPARISONS
    262144 :INPUT-UNCHANGED T)
   (:NAME :EXHAUSTIVE-FOUR-TO-EIGHT :GROUPS 393216 :KERNEL-COMPARISONS 1572864
    :INPUT-UNCHANGED T)
   (:NAME :ALL-MASK16 :GROUPS 65536 :KERNEL-COMPARISONS 262144 :INPUT-UNCHANGED
    T)
   (:NAME :OFFSET-ENDIAN-BOUNDARIES :GROUPS 518 :KERNEL-COMPARISONS 2072
    :INPUT-UNCHANGED T)
   (:NAME :DETERMINISTIC-DIFFERENTIAL :GROUPS 20000 :KERNEL-COMPARISONS 80000
    :INPUT-UNCHANGED T))
  :DIFFERENTIAL-SEED 439041101 :FINAL-LCG-STATE 2997108077 :NEGATIVE-CONTROLS
  ((:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS
    (#8=#A((64) #9=(UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128
           128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
           128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
           128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
           128 128)
     0 -1)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS (#8# 0 128)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS (#8# 0 255)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS (#8# 0 1/2)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS (#8# 0 :BAD)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS (#8# -1 0)
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS (#8# 49 0)
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS (#8# 64 0)
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS (#8# 1/2 0)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS (#8# :BAD 0)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS (#A((0) #9#) 0 0)
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS (#A((1) #9# 0) 0 0)
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS
    (#A((15) #9# 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) 0 0) :CONDITION
    ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS
    (#(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) 0 0) :CONDITION TYPE-ERROR
    :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS
    (#A((4 4) #9# (0 0 0 0) (0 0 0 0) (0 0 0 0) (0 0 0 0)) 0 0) :CONDITION
    TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS
    (#A((16) #9# 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) 0 0) :CONDITION TYPE-ERROR
    :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :ARGUMENTS
    (#A((16) #9# 128 128 128 128 128 128 128 0 1 128 128 128 128 128 128 128) 0
     0)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS (#8# 0 -1)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS (#8# 0 128)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS (#8# 0 255)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS (#8# 0 1/2)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS (#8# 0 :BAD)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS (#8# -1 0)
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS (#8# 49 0)
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS (#8# 64 0)
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS (#8# 1/2 0)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS (#8# :BAD 0)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS
    (#A((0) #9#) 0 0) :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
    :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS
    (#A((1) #9# 0) 0 0) :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
    :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS
    (#A((15) #9# 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) 0 0) :CONDITION
    ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS
    (#(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) 0 0) :CONDITION TYPE-ERROR
    :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS
    (#A((4 4) #9# (0 0 0 0) (0 0 0 0) (0 0 0 0) (0 0 0 0)) 0 0) :CONDITION
    TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS
    (#A((16) #9# 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) 0 0) :CONDITION TYPE-ERROR
    :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :ARGUMENTS
    (#A((16) #9# 128 128 128 128 128 128 128 0 1 128 128 128 128 128 128 128) 0
     0)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64 :ARGUMENTS (-1 0 0)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64 :ARGUMENTS (0 -1 0)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64 :ARGUMENTS
    (18446744073709551616 0 0) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64 :ARGUMENTS
    (0 18446744073709551616 0) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64 :ARGUMENTS (1/2 0 0)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64 :ARGUMENTS (0 1/2 0)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64 :ARGUMENTS (:BAD 0 0)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64 :ARGUMENTS (0 :BAD 0)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64 :ARGUMENTS (0 0 -1)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64 :ARGUMENTS (0 0 128)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64 :ARGUMENTS (0 0 255)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64 :ARGUMENTS (0 0 1/2)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64 :ARGUMENTS (0 0 :BAD)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::TYPEDU64 :ARGUMENTS (-1 0 0) :CONDITION
    TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::TYPEDU64 :ARGUMENTS (0 -1 0) :CONDITION
    TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::TYPEDU64 :ARGUMENTS
    (18446744073709551616 0 0) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::TYPEDU64 :ARGUMENTS
    (0 18446744073709551616 0) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::TYPEDU64 :ARGUMENTS (1/2 0 0) :CONDITION
    TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::TYPEDU64 :ARGUMENTS (0 1/2 0) :CONDITION
    TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::TYPEDU64 :ARGUMENTS (:BAD 0 0)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::TYPEDU64 :ARGUMENTS (0 :BAD 0)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::TYPEDU64 :ARGUMENTS (0 0 -1) :CONDITION
    TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::TYPEDU64 :ARGUMENTS (0 0 128) :CONDITION
    TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::TYPEDU64 :ARGUMENTS (0 0 255) :CONDITION
    TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::TYPEDU64 :ARGUMENTS (0 0 1/2) :CONDITION
    TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::TYPEDU64 :ARGUMENTS (0 0 :BAD)
    :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE:CHECK :ARGUMENTS
    (:MAX-CASES 1 :DIFFERENTIAL-CASES 1 :SECONDS 120) :CONDITION
    ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE:CHECK :ARGUMENTS (:MAX-CASES . #10=(0))
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE:CHECK :ARGUMENTS
    (:DIFFERENTIAL-CASES 100001) :CONDITION
    ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE:CHECK :ARGUMENTS (:SECONDS . #10#)
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::RESPECTE-TEMPS :ARGUMENTS (1820530)
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH :ARGUMENTS
    (15 . #11=(1 . #12=(1 . #13=(60 . #14=(16777216))))) :CONDITION
    ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH :ARGUMENTS (8193 . #11#)
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH :ARGUMENTS (16 0 . #12#)
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH :ARGUMENTS (16 1025 . #12#)
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH :ARGUMENTS (16 1 0 . #13#)
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH :ARGUMENTS (16 1 65 . #13#)
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH :ARGUMENTS
    (16 1 1 0 . #14#) :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
    :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH :ARGUMENTS
    (16 1 1 301 . #14#) :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
    :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH :ARGUMENTS
    (16 1 1 60 . #10#) :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
    :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH :ARGUMENTS
    (16 1 1 60 67108865) :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
    :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH :ARGUMENTS (16 1 1 60 1)
    :CONDITION ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T)
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH :ARGUMENTS
    (8192 1024 64 60 67108864) :CONDITION
    ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE :INPUT-UNCHANGED T))
  :NEGATIVE-CONTROL-COUNT 77 :MUTANT :BORROW-SUBTRACTION :MUTANT-KILLED-COUNT
  28 :MUTANT-WITNESSES
  ((:QUERY 0 :POSITION 0 :CTRL
    (0 1 128 128 128 128 128 128 128 128 128 128 128 128 128 128) :ORACLE 1
    :MUTANT 3 :EXTRA-POSITION 1)
   (:QUERY 0 :POSITION 1 :CTRL
    (128 0 1 128 128 128 128 128 128 128 128 128 128 128 128 128) :ORACLE 2
    :MUTANT 6 :EXTRA-POSITION 2)
   (:QUERY 0 :POSITION 2 :CTRL
    (128 128 0 1 128 128 128 128 128 128 128 128 128 128 128 128) :ORACLE 4
    :MUTANT 12 :EXTRA-POSITION 3)
   (:QUERY 0 :POSITION 3 :CTRL
    (128 128 128 0 1 128 128 128 128 128 128 128 128 128 128 128) :ORACLE 8
    :MUTANT 24 :EXTRA-POSITION 4)
   (:QUERY 0 :POSITION 4 :CTRL
    (128 128 128 128 0 1 128 128 128 128 128 128 128 128 128 128) :ORACLE 16
    :MUTANT 48 :EXTRA-POSITION 5)
   (:QUERY 0 :POSITION 5 :CTRL
    (128 128 128 128 128 0 1 128 128 128 128 128 128 128 128 128) :ORACLE 32
    :MUTANT 96 :EXTRA-POSITION 6)
   (:QUERY 0 :POSITION 6 :CTRL
    (128 128 128 128 128 128 0 1 128 128 128 128 128 128 128 128) :ORACLE 64
    :MUTANT 192 :EXTRA-POSITION 7)
   (:QUERY 0 :POSITION 8 :CTRL
    (128 128 128 128 128 128 128 128 0 1 128 128 128 128 128 128) :ORACLE 256
    :MUTANT 768 :EXTRA-POSITION 9)
   (:QUERY 0 :POSITION 9 :CTRL
    (128 128 128 128 128 128 128 128 128 0 1 128 128 128 128 128) :ORACLE 512
    :MUTANT 1536 :EXTRA-POSITION 10)
   (:QUERY 0 :POSITION 10 :CTRL
    (128 128 128 128 128 128 128 128 128 128 0 1 128 128 128 128) :ORACLE 1024
    :MUTANT 3072 :EXTRA-POSITION 11)
   (:QUERY 0 :POSITION 11 :CTRL
    (128 128 128 128 128 128 128 128 128 128 128 0 1 128 128 128) :ORACLE 2048
    :MUTANT 6144 :EXTRA-POSITION 12)
   (:QUERY 0 :POSITION 12 :CTRL
    (128 128 128 128 128 128 128 128 128 128 128 128 0 1 128 128) :ORACLE 4096
    :MUTANT 12288 :EXTRA-POSITION 13)
   (:QUERY 0 :POSITION 13 :CTRL
    (128 128 128 128 128 128 128 128 128 128 128 128 128 0 1 128) :ORACLE 8192
    :MUTANT 24576 :EXTRA-POSITION 14)
   (:QUERY 0 :POSITION 14 :CTRL
    (128 128 128 128 128 128 128 128 128 128 128 128 128 128 0 1) :ORACLE 16384
    :MUTANT 49152 :EXTRA-POSITION 15)
   (:QUERY 127 :POSITION 0 :CTRL
    (127 126 128 128 128 128 128 128 128 128 128 128 128 128 128 128) :ORACLE 1
    :MUTANT 3 :EXTRA-POSITION 1)
   (:QUERY 127 :POSITION 1 :CTRL
    (128 127 126 128 128 128 128 128 128 128 128 128 128 128 128 128) :ORACLE 2
    :MUTANT 6 :EXTRA-POSITION 2)
   (:QUERY 127 :POSITION 2 :CTRL
    (128 128 127 126 128 128 128 128 128 128 128 128 128 128 128 128) :ORACLE 4
    :MUTANT 12 :EXTRA-POSITION 3)
   (:QUERY 127 :POSITION 3 :CTRL
    (128 128 128 127 126 128 128 128 128 128 128 128 128 128 128 128) :ORACLE 8
    :MUTANT 24 :EXTRA-POSITION 4)
   (:QUERY 127 :POSITION 4 :CTRL
    (128 128 128 128 127 126 128 128 128 128 128 128 128 128 128 128) :ORACLE
    16 :MUTANT 48 :EXTRA-POSITION 5)
   (:QUERY 127 :POSITION 5 :CTRL
    (128 128 128 128 128 127 126 128 128 128 128 128 128 128 128 128) :ORACLE
    32 :MUTANT 96 :EXTRA-POSITION 6)
   (:QUERY 127 :POSITION 6 :CTRL
    (128 128 128 128 128 128 127 126 128 128 128 128 128 128 128 128) :ORACLE
    64 :MUTANT 192 :EXTRA-POSITION 7)
   (:QUERY 127 :POSITION 8 :CTRL
    (128 128 128 128 128 128 128 128 127 126 128 128 128 128 128 128) :ORACLE
    256 :MUTANT 768 :EXTRA-POSITION 9)
   (:QUERY 127 :POSITION 9 :CTRL
    (128 128 128 128 128 128 128 128 128 127 126 128 128 128 128 128) :ORACLE
    512 :MUTANT 1536 :EXTRA-POSITION 10)
   (:QUERY 127 :POSITION 10 :CTRL
    (128 128 128 128 128 128 128 128 128 128 127 126 128 128 128 128) :ORACLE
    1024 :MUTANT 3072 :EXTRA-POSITION 11)
   (:QUERY 127 :POSITION 11 :CTRL
    (128 128 128 128 128 128 128 128 128 128 128 127 126 128 128 128) :ORACLE
    2048 :MUTANT 6144 :EXTRA-POSITION 12)
   (:QUERY 127 :POSITION 12 :CTRL
    (128 128 128 128 128 128 128 128 128 128 128 128 127 126 128 128) :ORACLE
    4096 :MUTANT 12288 :EXTRA-POSITION 13)
   (:QUERY 127 :POSITION 13 :CTRL
    (128 128 128 128 128 128 128 128 128 128 128 128 128 127 126 128) :ORACLE
    8192 :MUTANT 24576 :EXTRA-POSITION 14)
   (:QUERY 127 :POSITION 14 :CTRL
    (128 128 128 128 128 128 128 128 128 128 128 128 128 128 127 126) :ORACLE
    16384 :MUTANT 49152 :EXTRA-POSITION 15))
  :WORD-BOUNDARY-CONTROLS 1 :MASK-API
  ((ARCDOCDB.SPK08.IMPRONTE::SCALAR16
    . #15=(ARCDOCDB.SPK08.IMPRONTE::CTRL ARCDOCDB.SPK08.IMPRONTE::START
           . #16=(ARCDOCDB.SPK08.IMPRONTE::H7)))
   (ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 . #15#)
   (ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64
    . #17=(ARCDOCDB.SPK08.IMPRONTE::LOW ARCDOCDB.SPK08.IMPRONTE::HIGH . #16#))
   (ARCDOCDB.SPK08.IMPRONTE::TYPEDU64 . #17#))
  :BENCH-API
  (ARCDOCDB.SPK08.IMPRONTE:BENCH &KEY ARCDOCDB.SPK08.IMPRONTE::ROWS
                                 ARCDOCDB.SPK08.IMPRONTE::PASSES
                                 ARCDOCDB.SPK08.IMPRONTE::WARMUP-PASSES
                                 ARCDOCDB.SPK08.IMPRONTE::SECONDS
                                 ARCDOCDB.SPK08.IMPRONTE::BYTE-BUDGET)
  :BENCH-EXECUTED NIL :LIMITS
  (:MAX-CASES 4000000 :DIFFERENTIAL-CASES 20000 :SECONDS 120 :CHECKPOINT-GROUPS
   4096 :COOPERATIVE-DEADLINE T :DOMAIN-BYTE-VALUES 256 :QUERY-VALUES 128
   :GROUP-BYTES 16 :PACKED-WORDS 2 :SMALL-DOMAIN-WORD-STATES 65536
   :NO-SOURCE-MUTATION T :HARDWARE-SIMD NIL :PRODUCTION-INTEGRATION NIL)
  :DISASSEMBLY
  ((:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR16 :TEXT
    \"; disassembly for ARCDOCDB.SPK08.IMPRONTE::SCALAR16
; Size: 168 bytes. Origin: #x8005731298                       ; ARCDOCDB.SPK08.IMPRONTE::SCALAR16
; 298:       40915FF8         LDR NL0, [R0, #-7]
; 29C:       008000D1         SUB NL0, NL0, #32
; 2A0:       BF0100F1         CMP R3, #0
; 2A4:       A0A140FA         CCMP R3, NL0, #0, GE
; 2A8:       4C030054         BGT L3
; 2AC:       020080D2         MOVZ NL2, #0
; 2B0:       000080D2         MOVZ NL0, #0
; 2B4:       10000014         B L2
; 2B8: L0:   EB030DAA         MOV R1, R3
; 2BC:       6101008B         ADD NL1, R1, NL0
; 2C0:       43915FF8         LDR NL3, [R0, #-7]
; 2C4:       7F0001EB         CMP NL3, NL1
; 2C8:       89030054         BLS L4
; 2CC:       4905818B         ADD TMP, R0, NL1, ASR #1
; 2D0:       21054039         LDRB WNL1, [TMP, #1]
; 2D4:       21F87FD3         LSL NL1, NL1, #1
; 2D8:       3F000CEB         CMP NL1, R2
; 2DC:       A1000054         BNE L1
; 2E0:       01FC4193         ASR NL1, NL0, #1
; 2E4:       430080D2         MOVZ NL3, #2
; 2E8:       6120C19A         LSL NL1, NL3, NL1
; 2EC:       420001AA         ORR NL2, NL2, NL1
; 2F0: L1:   00080091         ADD NL0, NL0, #2
; 2F4: L2:   1F8000F1         CMP NL0, #32
; 2F8:       01FEFF54         BNE L0
; 2FC:       EA0302AA         MOV R0, NL2
; 300:       FB031DAA         MOV CSP, CFP
; 304:       5F0300F1         CMP NULL, #0
; 308:       BD7B40A9         LDP CFP, LR, [CFP]
; 30C:       C0035FD6         RET
; 310: L3:   7D0300F9         STR CFP, [CSP]
; 314:       2AF8FF58         LDR R0, #x8005731218            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 318:       4BF8FF58         LDR R1, #x8005731220            ; :MOTIVO
; 31C:       6CF8FF58         LDR R2, #x8005731228            ; :INVALID-WINDOW
; 320:       29A680D2         MOVZ TMP, #1329
; 324:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 328:       D70080D2         MOVZ NARGS, #6
; 32C:       FD031BAA         MOV CFP, CSP
; 330:       C0033FD6         BLR LR
; 334:       E00120D4         BRK #15                         ; Invalid argument count trap
; 338: L4:   604421D4         BRK #2595                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R0
; 33C:       04               BYTE #X04                       ; NL1
; 33D:       .ALIGN           4
\")
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16 :TEXT
    \"; disassembly for ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16
; Size: 444 bytes. Origin: #x80057317C8                       ; ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16
; 7C8:       40915FF8         LDR NL0, [R0, #-7]
; 7CC:       008000D1         SUB NL0, NL0, #32
; 7D0:       BF0100F1         CMP R3, #0
; 7D4:       A0A140FA         CCMP R3, NL0, #0, GE
; 7D8:       AC0B0054         BGT L4
; 7DC:       050080D2         MOVZ NL5, #0
; 7E0:       000080D2         MOVZ NL0, #0
; 7E4:       0E000014         B L1
; 7E8: L0:   EB030DAA         MOV R1, R3
; 7EC:       6101008B         ADD NL1, R1, NL0
; 7F0:       42915FF8         LDR NL2, [R0, #-7]
; 7F4:       5F0001EB         CMP NL2, NL1
; 7F8:       E90B0054         BLS L5
; 7FC:       4905818B         ADD TMP, R0, NL1, ASR #1
; 800:       21054039         LDRB WNL1, [TMP, #1]
; 804:       02FC4193         ASR NL2, NL0, #1
; 808:       42F07DD3         LSL NL2, NL2, #3
; 80C:       2120C29A         LSL NL1, NL1, NL2
; 810:       A10001AA         ORR NL1, NL5, NL1
; 814:       E50301AA         MOV NL5, NL1
; 818:       00080091         ADD NL0, NL0, #2
; 81C: L1:   1F4000F1         CMP NL0, #16
; 820:       41FEFF54         BNE L0
; 824:       A3410091         ADD NL3, R3, #16
; 828:       040080D2         MOVZ NL4, #0
; 82C:       000080D2         MOVZ NL0, #0
; 830:       0D000014         B L3
; 834: L2:   6100008B         ADD NL1, NL3, NL0
; 838:       42915FF8         LDR NL2, [R0, #-7]
; 83C:       5F0001EB         CMP NL2, NL1
; 840:       E9090054         BLS L6
; 844:       4905818B         ADD TMP, R0, NL1, ASR #1
; 848:       21054039         LDRB WNL1, [TMP, #1]
; 84C:       02FC4193         ASR NL2, NL0, #1
; 850:       42F07DD3         LSL NL2, NL2, #3
; 854:       2120C29A         LSL NL1, NL1, NL2
; 858:       810001AA         ORR NL1, NL4, NL1
; 85C:       E40301AA         MOV NL4, NL1
; 860:       00080091         ADD NL0, NL0, #2
; 864: L3:   1F4000F1         CMP NL0, #16
; 868:       61FEFF54         BNE L2
; 86C:       80FD4193         ASR NL0, R2, #1
; 870:       E9C300B2         MOV TMP, #72340172838076673
; 874:       037C099B         MUL NL3, NL0, TMP
; 878:       E00303AA         MOV NL0, NL3
; 87C:       A00000CA         EOR NL0, NL5, NL0
; 880:       01D800B2         ORR NL1, NL0, #9187201950435737471
; 884:       00D80092         AND NL0, NL0, #9187201950435737471
; 888:       E2DB00B2         MOV NL2, #9187201950435737471
; 88C:       0000028B         ADD NL0, NL0, NL2
; 890:       200000AA         ORR NL0, NL1, NL0
; 894:       01008092         MOVN NL1, #0
; 898:       000001CA         EOR NL0, NL0, NL1
; 89C:       00C00192         AND NL0, NL0, #9259542123273814144
; 8A0:       00FC47D3         LSR NL0, NL0, #7
; 8A4:       E10300AA         MOV NL1, NL0
; 8A8:       21FC47D3         LSR NL1, NL1, #7
; 8AC:       000001AA         ORR NL0, NL0, NL1
; 8B0:       00840092         AND NL0, NL0, #844437815230467
; 8B4:       E10300AA         MOV NL1, NL0
; 8B8:       21FC4ED3         LSR NL1, NL1, #14
; 8BC:       000001AA         ORR NL0, NL0, NL1
; 8C0:       000C0092         AND NL0, NL0, #64424509455
; 8C4:       00F87FD3         LSL NL0, NL0, #1
; 8C8:       01FC5C93         ASR NL1, NL0, #28
; 8CC:       22F87F92         AND NL2, NL1, #18446744073709551614
; 8D0:       000002AA         ORR NL0, NL0, NL2
; 8D4:       051C7F92         AND NL5, NL0, #510
; 8D8:       E00303AA         MOV NL0, NL3
; 8DC:       800000CA         EOR NL0, NL4, NL0
; 8E0:       01D800B2         ORR NL1, NL0, #9187201950435737471
; 8E4:       00D80092         AND NL0, NL0, #9187201950435737471
; 8E8:       E2DB00B2         MOV NL2, #9187201950435737471
; 8EC:       0000028B         ADD NL0, NL0, NL2
; 8F0:       200000AA         ORR NL0, NL1, NL0
; 8F4:       01008092         MOVN NL1, #0
; 8F8:       000001CA         EOR NL0, NL0, NL1
; 8FC:       00C00192         AND NL0, NL0, #9259542123273814144
; 900:       00FC47D3         LSR NL0, NL0, #7
; 904:       E10300AA         MOV NL1, NL0
; 908:       21FC47D3         LSR NL1, NL1, #7
; 90C:       000001AA         ORR NL0, NL0, NL1
; 910:       00840092         AND NL0, NL0, #844437815230467
; 914:       E10300AA         MOV NL1, NL0
; 918:       21FC4ED3         LSR NL1, NL1, #14
; 91C:       000001AA         ORR NL0, NL0, NL1
; 920:       000C0092         AND NL0, NL0, #64424509455
; 924:       00F87FD3         LSL NL0, NL0, #1
; 928:       01FC5C93         ASR NL1, NL0, #28
; 92C:       22F87F92         AND NL2, NL1, #18446744073709551614
; 930:       000002AA         ORR NL0, NL0, NL2
; 934:       001C7F92         AND NL0, NL0, #510
; 938:       AA2000AA         ORR R0, NL5, NL0, LSL #8
; 93C:       FB031DAA         MOV CSP, CFP
; 940:       5F0300F1         CMP NULL, #0
; 944:       BD7B40A9         LDP CFP, LR, [CFP]
; 948:       C0035FD6         RET
; 94C: L4:   7D0300F9         STR CFP, [CSP]
; 950:       CAEFFF58         LDR R0, #x8005731748            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 954:       EBEFFF58         LDR R1, #x8005731750            ; :MOTIVO
; 958:       0CF0FF58         LDR R2, #x8005731758            ; :INVALID-WINDOW
; 95C:       29A680D2         MOVZ TMP, #1329
; 960:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 964:       D70080D2         MOVZ NARGS, #6
; 968:       FD031BAA         MOV CFP, CSP
; 96C:       C0033FD6         BLR LR
; 970:       E00120D4         BRK #15                         ; Invalid argument count trap
; 974: L5:   604421D4         BRK #2595                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R0
; 978:       04               BYTE #X04                       ; NL1
; 979:       .ALIGN           4
; 97C: L6:   604421D4         BRK #2595                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R0
; 980:       04               BYTE #X04                       ; NL1
; 981:       .ALIGN           4
\")
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64 :TEXT
    \"; disassembly for ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64
; Size: 172 bytes. Origin: #x8005731454                       ; ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64
; 454:       040080D2         MOVZ NL4, #0
; 458:       030080D2         MOVZ NL3, #0
; 45C:       1C000014         B L3
; 460: L0:   E0018092         MOVN NL0, #15
; 464:       007C039B         MUL NL0, NL0, NL3
; 468:       02FC4193         ASR NL2, NL0, #1
; 46C:       E10302CB         NEG NL1, NL2
; 470:       A024C19A         LSR NL0, NL5, NL1
; 474:       00F87FD3         LSL NL0, NL0, #1
; 478:       00FC4193         ASR NL0, NL0, #1
; 47C:       001C7FD3         UBFIZ NL0, NL0, #1, #8
; 480:       1F000CEB         CMP NL0, R2
; 484:       20030054         BEQ L4
; 488: L1:   E0018092         MOVN NL0, #15
; 48C:       007C039B         MUL NL0, NL0, NL3
; 490:       02FC4193         ASR NL2, NL0, #1
; 494:       E10302CB         NEG NL1, NL2
; 498:       C024C19A         LSR NL0, NL6, NL1
; 49C:       00F87FD3         LSL NL0, NL0, #1
; 4A0:       00FC4193         ASR NL0, NL0, #1
; 4A4:       001C7FD3         UBFIZ NL0, NL0, #1, #8
; 4A8:       1F000CEB         CMP NL0, R2
; 4AC:       A1000054         BNE L2
; 4B0:       004080D2         MOVZ NL0, #512
; 4B4:       0020C39A         LSL NL0, NL0, NL3
; 4B8:       800000AA         ORR NL0, NL4, NL0
; 4BC:       E40300AA         MOV NL4, NL0
; 4C0: L2:   E00303AA         MOV NL0, NL3
; 4C4:       00040091         ADD NL0, NL0, #1
; 4C8:       E30300AA         MOV NL3, NL0
; 4CC: L3:   7F2000F1         CMP NL3, #8
; 4D0:       81FCFF54         BNE L0
; 4D4:       EA0304AA         MOV R0, NL4
; 4D8:       FB031DAA         MOV CSP, CFP
; 4DC:       5F0300F1         CMP NULL, #0
; 4E0:       BD7B40A9         LDP CFP, LR, [CFP]
; 4E4:       C0035FD6         RET
; 4E8: L4:   400080D2         MOVZ NL0, #2
; 4EC:       0020C39A         LSL NL0, NL0, NL3
; 4F0:       800000AA         ORR NL0, NL4, NL0
; 4F4:       E40300AA         MOV NL4, NL0
; 4F8:       E4FFFF17         B L1
; 4FC:       E00120D4         BRK #15                         ; Invalid argument count trap
\")
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::TYPEDU64 :TEXT
    \"; disassembly for ARCDOCDB.SPK08.IMPRONTE::TYPEDU64
; Size: 228 bytes. Origin: #x8005731624                       ; ARCDOCDB.SPK08.IMPRONTE::TYPEDU64
; 624:       81FD4193         ASR NL1, R2, #1
; 628:       E9C300B2         MOV TMP, #72340172838076673
; 62C:       237C099B         MUL NL3, NL1, TMP
; 630:       E10303AA         MOV NL1, NL3
; 634:       000001CA         EOR NL0, NL0, NL1
; 638:       01D800B2         ORR NL1, NL0, #9187201950435737471
; 63C:       00D80092         AND NL0, NL0, #9187201950435737471
; 640:       E2DB00B2         MOV NL2, #9187201950435737471
; 644:       0000028B         ADD NL0, NL0, NL2
; 648:       200000AA         ORR NL0, NL1, NL0
; 64C:       01008092         MOVN NL1, #0
; 650:       000001CA         EOR NL0, NL0, NL1
; 654:       00C00192         AND NL0, NL0, #9259542123273814144
; 658:       00FC47D3         LSR NL0, NL0, #7
; 65C:       E10300AA         MOV NL1, NL0
; 660:       21FC47D3         LSR NL1, NL1, #7
; 664:       000001AA         ORR NL0, NL0, NL1
; 668:       00840092         AND NL0, NL0, #844437815230467
; 66C:       E10300AA         MOV NL1, NL0
; 670:       21FC4ED3         LSR NL1, NL1, #14
; 674:       000001AA         ORR NL0, NL0, NL1
; 678:       000C0092         AND NL0, NL0, #64424509455
; 67C:       00F87FD3         LSL NL0, NL0, #1
; 680:       01FC5C93         ASR NL1, NL0, #28
; 684:       22F87F92         AND NL2, NL1, #18446744073709551614
; 688:       000002AA         ORR NL0, NL0, NL2
; 68C:       051C7F92         AND NL5, NL0, #510
; 690:       E10303AA         MOV NL1, NL3
; 694:       800001CA         EOR NL0, NL4, NL1
; 698:       01D800B2         ORR NL1, NL0, #9187201950435737471
; 69C:       00D80092         AND NL0, NL0, #9187201950435737471
; 6A0:       E2DB00B2         MOV NL2, #9187201950435737471
; 6A4:       0000028B         ADD NL0, NL0, NL2
; 6A8:       200000AA         ORR NL0, NL1, NL0
; 6AC:       01008092         MOVN NL1, #0
; 6B0:       000001CA         EOR NL0, NL0, NL1
; 6B4:       00C00192         AND NL0, NL0, #9259542123273814144
; 6B8:       00FC47D3         LSR NL0, NL0, #7
; 6BC:       E10300AA         MOV NL1, NL0
; 6C0:       21FC47D3         LSR NL1, NL1, #7
; 6C4:       000001AA         ORR NL0, NL0, NL1
; 6C8:       00840092         AND NL0, NL0, #844437815230467
; 6CC:       E10300AA         MOV NL1, NL0
; 6D0:       21FC4ED3         LSR NL1, NL1, #14
; 6D4:       000001AA         ORR NL0, NL0, NL1
; 6D8:       000C0092         AND NL0, NL0, #64424509455
; 6DC:       00F87FD3         LSL NL0, NL0, #1
; 6E0:       01FC5C93         ASR NL1, NL0, #28
; 6E4:       22F87F92         AND NL2, NL1, #18446744073709551614
; 6E8:       000002AA         ORR NL0, NL0, NL2
; 6EC:       001C7F92         AND NL0, NL0, #510
; 6F0:       AA2000AA         ORR R0, NL5, NL0, LSL #8
; 6F4:       FB031DAA         MOV CSP, CFP
; 6F8:       5F0300F1         CMP NULL, #0
; 6FC:       BD7B40A9         LDP CFP, LR, [CFP]
; 700:       C0035FD6         RET
; 704:       E00120D4         BRK #15                         ; Invalid argument count trap
\")
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::CYCLE-SCALAR16 :TEXT
    \"; disassembly for ARCDOCDB.SPK08.IMPRONTE::CYCLE-SCALAR16
; Size: 1144 bytes. Origin: #x8005735244                      ; ARCDOCDB.SPK08.IMPRONTE::CYCLE-SCALAR16
; 244:       AA0F40F9         LDR R0, [CFP, #24]
; 248:       4FD140F8         LDR R5, [R0, #13]
; 24C:       AF3700F9         STR R5, [CFP, #104]
; 250:       AA0F40F9         LDR R0, [CFP, #24]
; 254:       4B5141F8         LDR R1, [R0, #21]
; 258:       AB3B00F9         STR R1, [CFP, #112]
; 25C:       AA0F40F9         LDR R0, [CFP, #24]
; 260:       4DD141F8         LDR R3, [R0, #29]
; 264:       AD3F00F9         STR R3, [CFP, #120]
; 268:       AA0F40F9         LDR R0, [CFP, #24]
; 26C:       40D143F8         LDR NL0, [R0, #61]
; 270:       A02300F9         STR NL0, [CFP, #64]
; 274:       BF7F03A9         STP ZR, ZR, [CFP, #48]
; 278:       7D0300F9         STR CFP, [CSP]
; 27C:       B6F7FF58         LDR LEXENV, #x8005735170        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 280:       170080D2         MOVZ NARGS, #0
; 284:       DE9240F8         LDR LR, [LEXENV, #9]
; 288:       FD031BAA         MOV CFP, CSP
; 28C:       C0033FD6         BLR LR
; 290:       AB3747A9         LDP R1, R3, [CFP, #112]
; 294:       AF3740F9         LDR R5, [CFP, #104]
; 298:       A01740F9         LDR NL0, [CFP, #40]
; 29C:       5F0100EB         CMP R0, NL0
; 2A0:       AA1D0054         BGE L18
; 2A4:       AB3707A9         STP R1, R3, [CFP, #112]
; 2A8:       AF3700F9         STR R5, [CFP, #104]
; 2AC:       7D0300F9         STR CFP, [CSP]
; 2B0:       16F6FF58         LDR LEXENV, #x8005735170        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 2B4:       170080D2         MOVZ NARGS, #0
; 2B8:       DE9240F8         LDR LR, [LEXENV, #9]
; 2BC:       FD031BAA         MOV CFP, CSP
; 2C0:       C0033FD6         BLR LR
; 2C4:       AA2700F9         STR R0, [CFP, #72]
; 2C8:       7D0300F9         STR CFP, [CSP]
; 2CC:       76F5FF58         LDR LEXENV, #x8005735178        ; #<SB-KERNEL:FDEFN GET-BYTES-CONSED>
; 2D0:       170080D2         MOVZ NARGS, #0
; 2D4:       DE9240F8         LDR LR, [LEXENV, #9]
; 2D8:       FD031BAA         MOV CFP, CSP
; 2DC:       C0033FD6         BLR LR
; 2E0:       AFAF46A9         LDP R5, R1, [CFP, #104]
; 2E4:       AD3F40F9         LDR R3, [CFP, #120]
; 2E8:       AA2B00F9         STR R0, [CFP, #80]
; 2EC:       070080D2         MOVZ NL7, #0
; 2F0:       50000014         B L7
; 2F4: L0:   040080D2         MOVZ NL4, #0
; 2F8:       49000014         B L6
; 2FC: L1:   80FC4193         ASR NL0, NL4, #1
; 300:       01E87BD3         LSL NL1, NL0, #5
; 304:       60915FF8         LDR NL0, [R1, #-7]
; 308:       1F0004EB         CMP NL0, NL4
; 30C:       891B0054         BLS L19
; 310:       6905848B         ADD TMP, R1, NL4, ASR #1
; 314:       20054039         LDRB WNL0, [TMP, #1]
; 318:       2000008B         ADD NL0, NL1, NL0
; 31C:       01F87FD3         LSL NL1, NL0, #1
; 320:       A0915FF8         LDR NL0, [R3, #-7]
; 324:       1F0004EB         CMP NL0, NL4
; 328:       E91A0054         BLS L20
; 32C:       A905848B         ADD TMP, R3, NL4, ASR #1
; 330:       23054039         LDRB WNL3, [TMP, #1]
; 334:       E50303AA         MOV NL5, NL3
; 338:       7FE079F2         TST NL3, #18446744073709551488
; 33C:       81180054         BNE L17
; 340:       EA030FAA         MOV R0, R5
; 344:       E60301AA         MOV NL6, NL1
; 348:       E0915FF8         LDR NL0, [R5, #-7]
; 34C:       008000D1         SUB NL0, NL0, #32
; 350:       3F0000EB         CMP NL1, NL0
; 354:       AC160054         BGT L16
; 358:       010080D2         MOVZ NL1, #0
; 35C:       000080D2         MOVZ NL0, #0
; 360:       11000014         B L4
; 364: L2:   C2FC4193         ASR NL2, NL6, #1
; 368:       4204808B         ADD NL2, NL2, NL0, ASR #1
; 36C:       42F87FD3         LSL NL2, NL2, #1
; 370:       43915FF8         LDR NL3, [R0, #-7]
; 374:       7F0002EB         CMP NL3, NL2
; 378:       A9180054         BLS L21
; 37C:       4905828B         ADD TMP, R0, NL2, ASR #1
; 380:       22054039         LDRB WNL2, [TMP, #1]
; 384:       E30305AA         MOV NL3, NL5
; 388:       5F0003EB         CMP NL2, NL3
; 38C:       A1000054         BNE L3
; 390:       02FC4193         ASR NL2, NL0, #1
; 394:       430080D2         MOVZ NL3, #2
; 398:       6220C29A         LSL NL2, NL3, NL2
; 39C:       210002AA         ORR NL1, NL1, NL2
; 3A0: L3:   00080091         ADD NL0, NL0, #2
; 3A4: L4:   1F8000F1         CMP NL0, #32
; 3A8:       E1FDFF54         BNE L2
; 3AC:       A01B40F9         LDR NL0, [CFP, #48]
; 3B0:       200000AB         ADDS NL0, NL1, NL0
; 3B4:       06170054         BVS L22
; 3B8:       A01B00F9         STR NL0, [CFP, #48]
; 3BC:       A01F40F9         LDR NL0, [CFP, #56]
; 3C0:       000800B1         ADDS NL0, NL0, #2
; 3C4:       A6160054         BVS L23
; 3C8:       A01F00F9         STR NL0, [CFP, #56]
; 3CC:       A01F40F9         LDR NL0, [CFP, #56]
; 3D0:       1F2C7FF2         TST NL0, #8190
; 3D4:       01020054         BNE L5
; 3D8:       A49F05A9         STP NL4, NL7, [CFP, #88]
; 3DC:       AFAF06A9         STP R5, R1, [CFP, #104]
; 3E0:       AD3F00F9         STR R3, [CFP, #120]
; 3E4:       7D0300F9         STR CFP, [CSP]
; 3E8:       56ECFF58         LDR LEXENV, #x8005735170        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 3EC:       170080D2         MOVZ NARGS, #0
; 3F0:       DE9240F8         LDR LR, [LEXENV, #9]
; 3F4:       FD031BAA         MOV CFP, CSP
; 3F8:       C0033FD6         BLR LR
; 3FC:       AB3747A9         LDP R1, R3, [CFP, #112]
; 400:       A73F46A9         LDP NL7, R5, [CFP, #96]
; 404:       A42F40F9         LDR NL4, [CFP, #88]
; 408:       AC1740F9         LDR R2, [CFP, #40]
; 40C:       5F010CEB         CMP R0, R2
; 410:       AA0F0054         BGE L15
; 414: L5:   80080091         ADD NL0, NL4, #2
; 418:       E40300AA         MOV NL4, NL0
; 41C: L6:   A02340F9         LDR NL0, [CFP, #64]
; 420:       9F0000EB         CMP NL4, NL0
; 424:       CBF6FF54         BLT L1
; 428:       E0080091         ADD NL0, NL7, #2
; 42C:       E70300AA         MOV NL7, NL0
; 430: L7:   A01340F9         LDR NL0, [CFP, #32]
; 434:       FF0000EB         CMP NL7, NL0
; 438:       EBF5FF54         BLT L0
; 43C:       7D0300F9         STR CFP, [CSP]
; 440:       D6E9FF58         LDR LEXENV, #x8005735178        ; #<SB-KERNEL:FDEFN GET-BYTES-CONSED>
; 444:       170080D2         MOVZ NARGS, #0
; 448:       DE9240F8         LDR LR, [LEXENV, #9]
; 44C:       FD031BAA         MOV CFP, CSP
; 450:       C0033FD6         BLR LR
; 454:       EB030AAA         MOV R1, R0
; 458:       AB2F00F9         STR R1, [CFP, #88]
; 45C:       7D0300F9         STR CFP, [CSP]
; 460:       96E8FF58         LDR LEXENV, #x8005735170        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 464:       170080D2         MOVZ NARGS, #0
; 468:       DE9240F8         LDR LR, [LEXENV, #9]
; 46C:       FD031BAA         MOV CFP, CSP
; 470:       C0033FD6         BLR LR
; 474:       AB2F40F9         LDR R1, [CFP, #88]
; 478:       A02740F9         LDR NL0, [CFP, #72]
; 47C:       400100CB         SUB NL0, R0, NL0
; 480:       A02300F9         STR NL0, [CFP, #64]
; 484:       7D0300F9         STR CFP, [CSP]
; 488:       EA030BAA         MOV R0, R1
; 48C:       AB2B40F9         LDR R1, [CFP, #80]
; 490:       298280D2         MOVZ TMP, #1041
; 494:       5E6B69F8         LDR LR, [NULL, TMP]             ; SB-KERNEL:TWO-ARG--
; 498:       FD031BAA         MOV CFP, CSP
; 49C:       C0033FD6         BLR LR
; 4A0:       EB030AAA         MOV R1, R0
; 4A4:       AB2700F9         STR R1, [CFP, #72]
; 4A8:       7D0300F9         STR CFP, [CSP]
; 4AC:       36E6FF58         LDR LEXENV, #x8005735170        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 4B0:       170080D2         MOVZ NARGS, #0
; 4B4:       DE9240F8         LDR LR, [LEXENV, #9]
; 4B8:       FD031BAA         MOV CFP, CSP
; 4BC:       C0033FD6         BLR LR
; 4C0:       AB2740F9         LDR R1, [CFP, #72]
; 4C4:       AC1740F9         LDR R2, [CFP, #40]
; 4C8:       5F010CEB         CMP R0, R2
; 4CC:       AA080054         BGE L14
; 4D0:       AA0F40F9         LDR R0, [CFP, #24]
; 4D4:       405144F8         LDR NL0, [R0, #69]
; 4D8:       A11340F9         LDR NL1, [CFP, #32]
; 4DC:       21FC4193         ASR NL1, NL1, #1
; 4E0:       00FC4193         ASR NL0, NL0, #1
; 4E4:       237C409B         SMULH NL3, NL1, NL0
; 4E8:       227C009B         MUL NL2, NL1, NL0
; 4EC:       214280D2         MOVZ NL1, #529
; 4F0:       7FFC82EB         CMP NL3, NL2, ASR #63
; 4F4:       81000054         BNE L8
; 4F8:       4A0002AB         ADDS R0, NL2, NL2
; 4FC:       E7010054         BVC L10
; 500:       212280D2         MOVZ NL1, #273
; 504: L8:   BA2A00B9         STR WNULL, [THREAD, #40]        ; pseudo-atomic-bits
; 508:       A97A47A9         LDP TMP, LR, [THREAD, #112]     ; mixed-tlab.{free-pointer, end-addr}
; 50C:       2A810091         ADD R0, TMP, #32
; 510:       5F011EEB         CMP R0, LR
; 514:       480C0054         BHI L24
; 518:       AA3A00F9         STR R0, [THREAD, #112]          ; mixed-tlab
; 51C: L9:   2A3D0091         ADD R0, TMP, #15
; 520:       210900A9         STP NL1, NL2, [TMP]
; 524:       230900F9         STR NL3, [TMP, #16]
; 528:       BF2A00B9         STR WZR, [THREAD, #40]          ; pseudo-atomic-bits
; 52C:       BE2E40B9         LDR WLR, [THREAD, #44]          ; pseudo-atomic-bits
; 530:       5E0000B4         CBZ LR, L10
; 534:       200120D4         BRK #9                          ; Pending interrupt trap
; 538: L10:  A01B40F9         LDR NL0, [CFP, #48]
; 53C:       5F0100EB         CMP R0, NL0
; 540:       21010054         BNE L11
; 544:       AA2340F9         LDR R0, [CFP, #64]
; 548:       AC3743A9         LDP R2, R3, [CFP, #48]
; 54C:       F9031DAA         MOV OCFP, CFP
; 550:       3B830091         ADD CSP, OCFP, #32
; 554:       170180D2         MOVZ NARGS, #8
; 558:       FF031FEB         CMP ZR, ZR
; 55C:       BD7B40A9         LDP CFP, LR, [CFP]
; 560:       C0035FD6         RET
; 564: L11:  A01B40F9         LDR NL0, [CFP, #48]
; 568:       BA2A00B9         STR WNULL, [THREAD, #40]        ; pseudo-atomic-bits
; 56C:       A9FA45A9         LDP TMP, LR, [THREAD, #88]      ; cons-tlab.{free-pointer, end-addr}
; 570:       2CC10091         ADD R2, TMP, #48
; 574:       9F011EEB         CMP R2, LR
; 578:       A8090054         BHI L25
; 57C:       AC2E00F9         STR R2, [THREAD, #88]           ; cons-tlab
; 580: L12:  2C1D0091         ADD R2, TMP, #7
; 584:       EE030CAA         MOV R4, R2
; 588:       0FE0FF58         LDR R5, #x8005735188            ; :CYCLE-CHECKSUM
; 58C:       CF911FF8         STR R5, [R4, #-7]
; 590:       CE410091         ADD R4, R4, #16
; 594:       CE111FF8         STR R4, [R4, #-15]
; 598:       CFDFFF58         LDR R5, #x8005735190            ; 'ARCDOCDB.SPK08.IMPRONTE::CYCLE-SCALAR16
; 59C:       CF911FF8         STR R5, [R4, #-7]
; 5A0:       CE410091         ADD R4, R4, #16
; 5A4:       CE111FF8         STR R4, [R4, #-15]
; 5A8:       C0911FF8         STR NL0, [R4, #-7]
; 5AC:       DA1100F8         STR NULL, [R4, #1]
; 5B0:       BF2A00B9         STR WZR, [THREAD, #40]          ; pseudo-atomic-bits
; 5B4:       BE2E40B9         LDR WLR, [THREAD, #44]          ; pseudo-atomic-bits
; 5B8:       5E0000B4         CBZ LR, L13
; 5BC:       200120D4         BRK #9                          ; Pending interrupt trap
; 5C0: L13:  7D0300F9         STR CFP, [CSP]
; 5C4:       AADEFF58         LDR R0, #x8005735198            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 5C8:       CBDEFF58         LDR R1, #x80057351A0            ; :MOTIVO
; 5CC:       29A680D2         MOVZ TMP, #1329
; 5D0:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 5D4:       D70080D2         MOVZ NARGS, #6
; 5D8:       FD031BAA         MOV CFP, CSP
; 5DC:       C0033FD6         BLR LR
; 5E0: L14:  7D0300F9         STR CFP, [CSP]
; 5E4:       AADDFF58         LDR R0, #x8005735198            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 5E8:       CBDDFF58         LDR R1, #x80057351A0            ; :MOTIVO
; 5EC:       ECDDFF58         LDR R2, #x80057351A8            ; :TIME-BUDGET
; 5F0:       29A680D2         MOVZ TMP, #1329
; 5F4:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 5F8:       D70080D2         MOVZ NARGS, #6
; 5FC:       FD031BAA         MOV CFP, CSP
; 600:       C0033FD6         BLR LR
; 604: L15:  7D0300F9         STR CFP, [CSP]
; 608:       8ADCFF58         LDR R0, #x8005735198            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 60C:       ABDCFF58         LDR R1, #x80057351A0            ; :MOTIVO
; 610:       CCDCFF58         LDR R2, #x80057351A8            ; :TIME-BUDGET
; 614:       29A680D2         MOVZ TMP, #1329
; 618:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 61C:       D70080D2         MOVZ NARGS, #6
; 620:       FD031BAA         MOV CFP, CSP
; 624:       C0033FD6         BLR LR
; 628: L16:  7D0300F9         STR CFP, [CSP]
; 62C:       6ADBFF58         LDR R0, #x8005735198            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 630:       8BDBFF58         LDR R1, #x80057351A0            ; :MOTIVO
; 634:       ECDBFF58         LDR R2, #x80057351B0            ; :INVALID-WINDOW
; 638:       29A680D2         MOVZ TMP, #1329
; 63C:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 640:       D70080D2         MOVZ NARGS, #6
; 644:       FD031BAA         MOV CFP, CSP
; 648:       C0033FD6         BLR LR
; 64C: L17:  806328D4         BRK #17180                      ; OBJECT-NOT-TYPE-ERROR
                                                              ; NL3
; 650:       37               BYTE #X37                       ; '(UNSIGNED-BYTE 7)
; 651:       .ALIGN           4
; 654: L18:  7D0300F9         STR CFP, [CSP]
; 658:       0ADAFF58         LDR R0, #x8005735198            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 65C:       2BDAFF58         LDR R1, #x80057351A0            ; :MOTIVO
; 660:       4CDAFF58         LDR R2, #x80057351A8            ; :TIME-BUDGET
; 664:       29A680D2         MOVZ TMP, #1329
; 668:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 66C:       D70080D2         MOVZ NARGS, #6
; 670:       FD031BAA         MOV CFP, CSP
; 674:       C0033FD6         BLR LR
; 678:       E00120D4         BRK #15                         ; Invalid argument count trap
; 67C: L19:  606421D4         BRK #2851                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R1
; 680:       10               BYTE #X10                       ; NL4
; 681:       .ALIGN           4
; 684: L20:  60A421D4         BRK #3363                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R3
; 688:       10               BYTE #X10                       ; NL4
; 689:       .ALIGN           4
; 68C: L21:  604421D4         BRK #2595                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R0
; 690:       08               BYTE #X08                       ; NL2
; 691:       .ALIGN           4
; 694: L22:  A00520D4         BRK #45                         ; ADD-SUB-OVERFLOW-ERROR
                                                              ; NL0
; 698: L23:  A00520D4         BRK #45                         ; ADD-SUB-OVERFLOW-ERROR
                                                              ; NL0
; 69C: L24:  090480D2         MOVZ TMP, #32
; 6A0:       4AD9FF58         LDR R0, #x80057351C8            ; SB-VM::ALLOC-TRAMP
; 6A4:       40013FD6         BLR R0
; 6A8:       9DFFFF17         B L9
; 6AC: L25:  090680D2         MOVZ TMP, #48
; 6B0:       0CD9FF58         LDR R2, #x80057351D0            ; SB-VM::LIST-ALLOC-TRAMP
; 6B4:       80013FD6         BLR R2
; 6B8:       B2FFFF17         B L12
\")
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::CYCLE-PACKEDMASK16 :TEXT
    \"; disassembly for ARCDOCDB.SPK08.IMPRONTE::CYCLE-PACKEDMASK16
; Size: 1412 bytes. Origin: #x80057357D4                      ; ARCDOCDB.SPK08.IMPRONTE::CYCLE-PACKEDMASK16
; 7D4:       AA0F40F9         LDR R0, [CFP, #24]
; 7D8:       4FD140F8         LDR R5, [R0, #13]
; 7DC:       AF3700F9         STR R5, [CFP, #104]
; 7E0:       AA0F40F9         LDR R0, [CFP, #24]
; 7E4:       4B5141F8         LDR R1, [R0, #21]
; 7E8:       AB3B00F9         STR R1, [CFP, #112]
; 7EC:       AA0F40F9         LDR R0, [CFP, #24]
; 7F0:       4DD141F8         LDR R3, [R0, #29]
; 7F4:       AD3F00F9         STR R3, [CFP, #120]
; 7F8:       AA0F40F9         LDR R0, [CFP, #24]
; 7FC:       40D143F8         LDR NL0, [R0, #61]
; 800:       A02300F9         STR NL0, [CFP, #64]
; 804:       BF7F03A9         STP ZR, ZR, [CFP, #48]
; 808:       7D0300F9         STR CFP, [CSP]
; 80C:       36F7FF58         LDR LEXENV, #x80057356F0        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 810:       170080D2         MOVZ NARGS, #0
; 814:       DE9240F8         LDR LR, [LEXENV, #9]
; 818:       FD031BAA         MOV CFP, CSP
; 81C:       C0033FD6         BLR LR
; 820:       AB3747A9         LDP R1, R3, [CFP, #112]
; 824:       AF3740F9         LDR R5, [CFP, #104]
; 828:       A01740F9         LDR NL0, [CFP, #40]
; 82C:       5F0100EB         CMP R0, NL0
; 830:       CA250054         BGE L19
; 834:       AB3707A9         STP R1, R3, [CFP, #112]
; 838:       AF3700F9         STR R5, [CFP, #104]
; 83C:       7D0300F9         STR CFP, [CSP]
; 840:       96F5FF58         LDR LEXENV, #x80057356F0        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 844:       170080D2         MOVZ NARGS, #0
; 848:       DE9240F8         LDR LR, [LEXENV, #9]
; 84C:       FD031BAA         MOV CFP, CSP
; 850:       C0033FD6         BLR LR
; 854:       AA2700F9         STR R0, [CFP, #72]
; 858:       7D0300F9         STR CFP, [CSP]
; 85C:       F6F4FF58         LDR LEXENV, #x80057356F8        ; #<SB-KERNEL:FDEFN GET-BYTES-CONSED>
; 860:       170080D2         MOVZ NARGS, #0
; 864:       DE9240F8         LDR LR, [LEXENV, #9]
; 868:       FD031BAA         MOV CFP, CSP
; 86C:       C0033FD6         BLR LR
; 870:       AFAF46A9         LDP R5, R1, [CFP, #104]
; 874:       AD3F40F9         LDR R3, [CFP, #120]
; 878:       AA2B00F9         STR R0, [CFP, #80]
; 87C:       080080D2         MOVZ NL8, #0
; 880:       91000014         B L8
; 884: L0:   040080D2         MOVZ NL4, #0
; 888:       8A000014         B L7
; 88C: L1:   80FC4193         ASR NL0, NL4, #1
; 890:       01E87BD3         LSL NL1, NL0, #5
; 894:       60915FF8         LDR NL0, [R1, #-7]
; 898:       1F0004EB         CMP NL0, NL4
; 89C:       A9230054         BLS L20
; 8A0:       6905848B         ADD TMP, R1, NL4, ASR #1
; 8A4:       20054039         LDRB WNL0, [TMP, #1]
; 8A8:       2000008B         ADD NL0, NL1, NL0
; 8AC:       01F87FD3         LSL NL1, NL0, #1
; 8B0:       A0915FF8         LDR NL0, [R3, #-7]
; 8B4:       1F0004EB         CMP NL0, NL4
; 8B8:       09230054         BLS L21
; 8BC:       A905848B         ADD TMP, R3, NL4, ASR #1
; 8C0:       20054039         LDRB WNL0, [TMP, #1]
; 8C4:       E60300AA         MOV NL6, NL0
; 8C8:       1FE079F2         TST NL0, #18446744073709551488
; 8CC:       A1200054         BNE L18
; 8D0:       EA030FAA         MOV R0, R5
; 8D4:       E50301AA         MOV NL5, NL1
; 8D8:       E0915FF8         LDR NL0, [R5, #-7]
; 8DC:       008000D1         SUB NL0, NL0, #32
; 8E0:       3F0000EB         CMP NL1, NL0
; 8E4:       CC1E0054         BGT L17
; 8E8:       070080D2         MOVZ NL7, #0
; 8EC:       000080D2         MOVZ NL0, #0
; 8F0:       0D000014         B L3
; 8F4: L2:   A100008B         ADD NL1, NL5, NL0
; 8F8:       42915FF8         LDR NL2, [R0, #-7]
; 8FC:       5F0001EB         CMP NL2, NL1
; 900:       09210054         BLS L22
; 904:       4905818B         ADD TMP, R0, NL1, ASR #1
; 908:       22054039         LDRB WNL2, [TMP, #1]
; 90C:       01FC4193         ASR NL1, NL0, #1
; 910:       21F07DD3         LSL NL1, NL1, #3
; 914:       4120C19A         LSL NL1, NL2, NL1
; 918:       E10001AA         ORR NL1, NL7, NL1
; 91C:       E70301AA         MOV NL7, NL1
; 920:       00080091         ADD NL0, NL0, #2
; 924: L3:   1F4000F1         CMP NL0, #16
; 928:       61FEFF54         BNE L2
; 92C:       A3400091         ADD NL3, NL5, #16
; 930:       050080D2         MOVZ NL5, #0
; 934:       000080D2         MOVZ NL0, #0
; 938:       0D000014         B L5
; 93C: L4:   6100008B         ADD NL1, NL3, NL0
; 940:       42915FF8         LDR NL2, [R0, #-7]
; 944:       5F0001EB         CMP NL2, NL1
; 948:       091F0054         BLS L23
; 94C:       4905818B         ADD TMP, R0, NL1, ASR #1
; 950:       21054039         LDRB WNL1, [TMP, #1]
; 954:       02FC4193         ASR NL2, NL0, #1
; 958:       42F07DD3         LSL NL2, NL2, #3
; 95C:       2120C29A         LSL NL1, NL1, NL2
; 960:       A10001AA         ORR NL1, NL5, NL1
; 964:       E50301AA         MOV NL5, NL1
; 968:       00080091         ADD NL0, NL0, #2
; 96C: L5:   1F4000F1         CMP NL0, #16
; 970:       61FEFF54         BNE L4
; 974:       E9C300B2         MOV TMP, #72340172838076673
; 978:       C37C099B         MUL NL3, NL6, TMP
; 97C:       E00303AA         MOV NL0, NL3
; 980:       E00000CA         EOR NL0, NL7, NL0
; 984:       02D800B2         ORR NL2, NL0, #9187201950435737471
; 988:       00D80092         AND NL0, NL0, #9187201950435737471
; 98C:       E1DB00B2         MOV NL1, #9187201950435737471
; 990:       0000018B         ADD NL0, NL0, NL1
; 994:       400000AA         ORR NL0, NL2, NL0
; 998:       01008092         MOVN NL1, #0
; 99C:       000001CA         EOR NL0, NL0, NL1
; 9A0:       00C00192         AND NL0, NL0, #9259542123273814144
; 9A4:       00FC47D3         LSR NL0, NL0, #7
; 9A8:       E10300AA         MOV NL1, NL0
; 9AC:       21FC47D3         LSR NL1, NL1, #7
; 9B0:       000001AA         ORR NL0, NL0, NL1
; 9B4:       00840092         AND NL0, NL0, #844437815230467
; 9B8:       E10300AA         MOV NL1, NL0
; 9BC:       21FC4ED3         LSR NL1, NL1, #14
; 9C0:       000001AA         ORR NL0, NL0, NL1
; 9C4:       000C0092         AND NL0, NL0, #64424509455
; 9C8:       00F87FD3         LSL NL0, NL0, #1
; 9CC:       01FC5C93         ASR NL1, NL0, #28
; 9D0:       22F87F92         AND NL2, NL1, #18446744073709551614
; 9D4:       000002AA         ORR NL0, NL0, NL2
; 9D8:       061C7F92         AND NL6, NL0, #510
; 9DC:       E00303AA         MOV NL0, NL3
; 9E0:       A00000CA         EOR NL0, NL5, NL0
; 9E4:       01D800B2         ORR NL1, NL0, #9187201950435737471
; 9E8:       00D80092         AND NL0, NL0, #9187201950435737471
; 9EC:       E2DB00B2         MOV NL2, #9187201950435737471
; 9F0:       0000028B         ADD NL0, NL0, NL2
; 9F4:       200000AA         ORR NL0, NL1, NL0
; 9F8:       01008092         MOVN NL1, #0
; 9FC:       000001CA         EOR NL0, NL0, NL1
; A00:       00C00192         AND NL0, NL0, #9259542123273814144
; A04:       00FC47D3         LSR NL0, NL0, #7
; A08:       E10300AA         MOV NL1, NL0
; A0C:       21FC47D3         LSR NL1, NL1, #7
; A10:       000001AA         ORR NL0, NL0, NL1
; A14:       00840092         AND NL0, NL0, #844437815230467
; A18:       E10300AA         MOV NL1, NL0
; A1C:       21FC4ED3         LSR NL1, NL1, #14
; A20:       000001AA         ORR NL0, NL0, NL1
; A24:       000C0092         AND NL0, NL0, #64424509455
; A28:       00F87FD3         LSL NL0, NL0, #1
; A2C:       01FC5C93         ASR NL1, NL0, #28
; A30:       22F87F92         AND NL2, NL1, #18446744073709551614
; A34:       000002AA         ORR NL0, NL0, NL2
; A38:       001C7F92         AND NL0, NL0, #510
; A3C:       C02000AA         ORR NL0, NL6, NL0, LSL #8
; A40:       A11B40F9         LDR NL1, [CFP, #48]
; A44:       000001AB         ADDS NL0, NL0, NL1
; A48:       46170054         BVS L24
; A4C:       A01B00F9         STR NL0, [CFP, #48]
; A50:       A01F40F9         LDR NL0, [CFP, #56]
; A54:       000800B1         ADDS NL0, NL0, #2
; A58:       E6160054         BVS L25
; A5C:       A01F00F9         STR NL0, [CFP, #56]
; A60:       A01F40F9         LDR NL0, [CFP, #56]
; A64:       1F2C7FF2         TST NL0, #8190
; A68:       01020054         BNE L6
; A6C:       A4A305A9         STP NL4, NL8, [CFP, #88]
; A70:       AFAF06A9         STP R5, R1, [CFP, #104]
; A74:       AD3F00F9         STR R3, [CFP, #120]
; A78:       7D0300F9         STR CFP, [CSP]
; A7C:       B6E3FF58         LDR LEXENV, #x80057356F0        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; A80:       170080D2         MOVZ NARGS, #0
; A84:       DE9240F8         LDR LR, [LEXENV, #9]
; A88:       FD031BAA         MOV CFP, CSP
; A8C:       C0033FD6         BLR LR
; A90:       AB3747A9         LDP R1, R3, [CFP, #112]
; A94:       A83F46A9         LDP NL8, R5, [CFP, #96]
; A98:       A42F40F9         LDR NL4, [CFP, #88]
; A9C:       AC1740F9         LDR R2, [CFP, #40]
; AA0:       5F010CEB         CMP R0, R2
; AA4:       AA0F0054         BGE L16
; AA8: L6:   80080091         ADD NL0, NL4, #2
; AAC:       E40300AA         MOV NL4, NL0
; AB0: L7:   A02340F9         LDR NL0, [CFP, #64]
; AB4:       9F0000EB         CMP NL4, NL0
; AB8:       ABEEFF54         BLT L1
; ABC:       00090091         ADD NL0, NL8, #2
; AC0:       E80300AA         MOV NL8, NL0
; AC4: L8:   A01340F9         LDR NL0, [CFP, #32]
; AC8:       1F0100EB         CMP NL8, NL0
; ACC:       CBEDFF54         BLT L0
; AD0:       7D0300F9         STR CFP, [CSP]
; AD4:       36E1FF58         LDR LEXENV, #x80057356F8        ; #<SB-KERNEL:FDEFN GET-BYTES-CONSED>
; AD8:       170080D2         MOVZ NARGS, #0
; ADC:       DE9240F8         LDR LR, [LEXENV, #9]
; AE0:       FD031BAA         MOV CFP, CSP
; AE4:       C0033FD6         BLR LR
; AE8:       EB030AAA         MOV R1, R0
; AEC:       AB2F00F9         STR R1, [CFP, #88]
; AF0:       7D0300F9         STR CFP, [CSP]
; AF4:       F6DFFF58         LDR LEXENV, #x80057356F0        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; AF8:       170080D2         MOVZ NARGS, #0
; AFC:       DE9240F8         LDR LR, [LEXENV, #9]
; B00:       FD031BAA         MOV CFP, CSP
; B04:       C0033FD6         BLR LR
; B08:       AB2F40F9         LDR R1, [CFP, #88]
; B0C:       A02740F9         LDR NL0, [CFP, #72]
; B10:       400100CB         SUB NL0, R0, NL0
; B14:       A02300F9         STR NL0, [CFP, #64]
; B18:       7D0300F9         STR CFP, [CSP]
; B1C:       EA030BAA         MOV R0, R1
; B20:       AB2B40F9         LDR R1, [CFP, #80]
; B24:       298280D2         MOVZ TMP, #1041
; B28:       5E6B69F8         LDR LR, [NULL, TMP]             ; SB-KERNEL:TWO-ARG--
; B2C:       FD031BAA         MOV CFP, CSP
; B30:       C0033FD6         BLR LR
; B34:       EB030AAA         MOV R1, R0
; B38:       AB2700F9         STR R1, [CFP, #72]
; B3C:       7D0300F9         STR CFP, [CSP]
; B40:       96DDFF58         LDR LEXENV, #x80057356F0        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; B44:       170080D2         MOVZ NARGS, #0
; B48:       DE9240F8         LDR LR, [LEXENV, #9]
; B4C:       FD031BAA         MOV CFP, CSP
; B50:       C0033FD6         BLR LR
; B54:       AB2740F9         LDR R1, [CFP, #72]
; B58:       AC1740F9         LDR R2, [CFP, #40]
; B5C:       5F010CEB         CMP R0, R2
; B60:       AA080054         BGE L15
; B64:       AA0F40F9         LDR R0, [CFP, #24]
; B68:       405144F8         LDR NL0, [R0, #69]
; B6C:       A11340F9         LDR NL1, [CFP, #32]
; B70:       21FC4193         ASR NL1, NL1, #1
; B74:       00FC4193         ASR NL0, NL0, #1
; B78:       237C409B         SMULH NL3, NL1, NL0
; B7C:       227C009B         MUL NL2, NL1, NL0
; B80:       214280D2         MOVZ NL1, #529
; B84:       7FFC82EB         CMP NL3, NL2, ASR #63
; B88:       81000054         BNE L9
; B8C:       4A0002AB         ADDS R0, NL2, NL2
; B90:       E7010054         BVC L11
; B94:       212280D2         MOVZ NL1, #273
; B98: L9:   BA2A00B9         STR WNULL, [THREAD, #40]        ; pseudo-atomic-bits
; B9C:       A97A47A9         LDP TMP, LR, [THREAD, #112]     ; mixed-tlab.{free-pointer, end-addr}
; BA0:       2A810091         ADD R0, TMP, #32
; BA4:       5F011EEB         CMP R0, LR
; BA8:       880C0054         BHI L26
; BAC:       AA3A00F9         STR R0, [THREAD, #112]          ; mixed-tlab
; BB0: L10:  2A3D0091         ADD R0, TMP, #15
; BB4:       210900A9         STP NL1, NL2, [TMP]
; BB8:       230900F9         STR NL3, [TMP, #16]
; BBC:       BF2A00B9         STR WZR, [THREAD, #40]          ; pseudo-atomic-bits
; BC0:       BE2E40B9         LDR WLR, [THREAD, #44]          ; pseudo-atomic-bits
; BC4:       5E0000B4         CBZ LR, L11
; BC8:       200120D4         BRK #9                          ; Pending interrupt trap
; BCC: L11:  A01B40F9         LDR NL0, [CFP, #48]
; BD0:       5F0100EB         CMP R0, NL0
; BD4:       21010054         BNE L12
; BD8:       AA2340F9         LDR R0, [CFP, #64]
; BDC:       AC3743A9         LDP R2, R3, [CFP, #48]
; BE0:       F9031DAA         MOV OCFP, CFP
; BE4:       3B830091         ADD CSP, OCFP, #32
; BE8:       170180D2         MOVZ NARGS, #8
; BEC:       FF031FEB         CMP ZR, ZR
; BF0:       BD7B40A9         LDP CFP, LR, [CFP]
; BF4:       C0035FD6         RET
; BF8: L12:  A01B40F9         LDR NL0, [CFP, #48]
; BFC:       BA2A00B9         STR WNULL, [THREAD, #40]        ; pseudo-atomic-bits
; C00:       A9FA45A9         LDP TMP, LR, [THREAD, #88]      ; cons-tlab.{free-pointer, end-addr}
; C04:       2CC10091         ADD R2, TMP, #48
; C08:       9F011EEB         CMP R2, LR
; C0C:       E8090054         BHI L27
; C10:       AC2E00F9         STR R2, [THREAD, #88]           ; cons-tlab
; C14: L13:  2C1D0091         ADD R2, TMP, #7
; C18:       EE030CAA         MOV R4, R2
; C1C:       EFD7FF58         LDR R5, #x8005735718            ; :CYCLE-CHECKSUM
; C20:       CF911FF8         STR R5, [R4, #-7]
; C24:       CE410091         ADD R4, R4, #16
; C28:       CE111FF8         STR R4, [R4, #-15]
; C2C:       AFD7FF58         LDR R5, #x8005735720            ; 'ARCDOCDB.SPK08.IMPRONTE::CYCLE-PACKEDMASK16
; C30:       CF911FF8         STR R5, [R4, #-7]
; C34:       CE410091         ADD R4, R4, #16
; C38:       CE111FF8         STR R4, [R4, #-15]
; C3C:       C0911FF8         STR NL0, [R4, #-7]
; C40:       DA1100F8         STR NULL, [R4, #1]
; C44:       BF2A00B9         STR WZR, [THREAD, #40]          ; pseudo-atomic-bits
; C48:       BE2E40B9         LDR WLR, [THREAD, #44]          ; pseudo-atomic-bits
; C4C:       5E0000B4         CBZ LR, L14
; C50:       200120D4         BRK #9                          ; Pending interrupt trap
; C54: L14:  7D0300F9         STR CFP, [CSP]
; C58:       8AD6FF58         LDR R0, #x8005735728            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; C5C:       ABD6FF58         LDR R1, #x8005735730            ; :MOTIVO
; C60:       29A680D2         MOVZ TMP, #1329
; C64:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; C68:       D70080D2         MOVZ NARGS, #6
; C6C:       FD031BAA         MOV CFP, CSP
; C70:       C0033FD6         BLR LR
; C74: L15:  7D0300F9         STR CFP, [CSP]
; C78:       8AD5FF58         LDR R0, #x8005735728            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; C7C:       ABD5FF58         LDR R1, #x8005735730            ; :MOTIVO
; C80:       CCD5FF58         LDR R2, #x8005735738            ; :TIME-BUDGET
; C84:       29A680D2         MOVZ TMP, #1329
; C88:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; C8C:       D70080D2         MOVZ NARGS, #6
; C90:       FD031BAA         MOV CFP, CSP
; C94:       C0033FD6         BLR LR
; C98: L16:  7D0300F9         STR CFP, [CSP]
; C9C:       6AD4FF58         LDR R0, #x8005735728            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; CA0:       8BD4FF58         LDR R1, #x8005735730            ; :MOTIVO
; CA4:       ACD4FF58         LDR R2, #x8005735738            ; :TIME-BUDGET
; CA8:       29A680D2         MOVZ TMP, #1329
; CAC:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; CB0:       D70080D2         MOVZ NARGS, #6
; CB4:       FD031BAA         MOV CFP, CSP
; CB8:       C0033FD6         BLR LR
; CBC: L17:  7D0300F9         STR CFP, [CSP]
; CC0:       4AD3FF58         LDR R0, #x8005735728            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; CC4:       6BD3FF58         LDR R1, #x8005735730            ; :MOTIVO
; CC8:       CCD3FF58         LDR R2, #x8005735740            ; :INVALID-WINDOW
; CCC:       29A680D2         MOVZ TMP, #1329
; CD0:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; CD4:       D70080D2         MOVZ NARGS, #6
; CD8:       FD031BAA         MOV CFP, CSP
; CDC:       C0033FD6         BLR LR
; CE0: L18:  800328D4         BRK #16412                      ; OBJECT-NOT-TYPE-ERROR
                                                              ; NL0
; CE4:       3F               BYTE #X3F                       ; '(UNSIGNED-BYTE 7)
; CE5:       .ALIGN           4
; CE8: L19:  7D0300F9         STR CFP, [CSP]
; CEC:       EAD1FF58         LDR R0, #x8005735728            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; CF0:       0BD2FF58         LDR R1, #x8005735730            ; :MOTIVO
; CF4:       2CD2FF58         LDR R2, #x8005735738            ; :TIME-BUDGET
; CF8:       29A680D2         MOVZ TMP, #1329
; CFC:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; D00:       D70080D2         MOVZ NARGS, #6
; D04:       FD031BAA         MOV CFP, CSP
; D08:       C0033FD6         BLR LR
; D0C:       E00120D4         BRK #15                         ; Invalid argument count trap
; D10: L20:  606421D4         BRK #2851                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R1
; D14:       10               BYTE #X10                       ; NL4
; D15:       .ALIGN           4
; D18: L21:  60A421D4         BRK #3363                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R3
; D1C:       10               BYTE #X10                       ; NL4
; D1D:       .ALIGN           4
; D20: L22:  604421D4         BRK #2595                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R0
; D24:       04               BYTE #X04                       ; NL1
; D25:       .ALIGN           4
; D28: L23:  604421D4         BRK #2595                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R0
; D2C:       04               BYTE #X04                       ; NL1
; D2D:       .ALIGN           4
; D30: L24:  A00520D4         BRK #45                         ; ADD-SUB-OVERFLOW-ERROR
                                                              ; NL0
; D34: L25:  A00520D4         BRK #45                         ; ADD-SUB-OVERFLOW-ERROR
                                                              ; NL0
; D38: L26:  090480D2         MOVZ TMP, #32
; D3C:       EAD0FF58         LDR R0, #x8005735758            ; SB-VM::ALLOC-TRAMP
; D40:       40013FD6         BLR R0
; D44:       9BFFFF17         B L10
; D48: L27:  090680D2         MOVZ TMP, #48
; D4C:       ACD0FF58         LDR R2, #x8005735760            ; SB-VM::LIST-ALLOC-TRAMP
; D50:       80013FD6         BLR R2
; D54:       B0FFFF17         B L13
\")
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::CYCLE-SCALAR-U64 :TEXT
    \"; disassembly for ARCDOCDB.SPK08.IMPRONTE::CYCLE-SCALAR-U64
; Size: 1156 bytes. Origin: #x8005735E54                      ; ARCDOCDB.SPK08.IMPRONTE::CYCLE-SCALAR-U64
; 5E54:       AA0F40F9         LDR R0, [CFP, #24]
; 5E58:       4FD141F8         LDR R5, [R0, #29]
; 5E5C:       AF3F00F9         STR R5, [CFP, #120]
; 5E60:       AA0F40F9         LDR R0, [CFP, #24]
; 5E64:       4B5142F8         LDR R1, [R0, #37]
; 5E68:       AB3700F9         STR R1, [CFP, #104]
; 5E6C:       AA0F40F9         LDR R0, [CFP, #24]
; 5E70:       4DD142F8         LDR R3, [R0, #45]
; 5E74:       AD3B00F9         STR R3, [CFP, #112]
; 5E78:       AA0F40F9         LDR R0, [CFP, #24]
; 5E7C:       40D143F8         LDR NL0, [R0, #61]
; 5E80:       A02300F9         STR NL0, [CFP, #64]
; 5E84:       BF7F03A9         STP ZR, ZR, [CFP, #48]
; 5E88:       7D0300F9         STR CFP, [CSP]
; 5E8C:       B6F7FF58         LDR LEXENV, #x8005735D80       ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 5E90:       170080D2         MOVZ NARGS, #0
; 5E94:       DE9240F8         LDR LR, [LEXENV, #9]
; 5E98:       FD031BAA         MOV CFP, CSP
; 5E9C:       C0033FD6         BLR LR
; 5EA0:       ABB746A9         LDP R1, R3, [CFP, #104]
; 5EA4:       AF3F40F9         LDR R5, [CFP, #120]
; 5EA8:       A01740F9         LDR NL0, [CFP, #40]
; 5EAC:       5F0100EB         CMP R0, NL0
; 5EB0:       0A1E0054         BGE L19
; 5EB4:       AD3F07A9         STP R3, R5, [CFP, #112]
; 5EB8:       AB3700F9         STR R1, [CFP, #104]
; 5EBC:       7D0300F9         STR CFP, [CSP]
; 5EC0:       16F6FF58         LDR LEXENV, #x8005735D80       ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 5EC4:       170080D2         MOVZ NARGS, #0
; 5EC8:       DE9240F8         LDR LR, [LEXENV, #9]
; 5ECC:       FD031BAA         MOV CFP, CSP
; 5ED0:       C0033FD6         BLR LR
; 5ED4:       AA2700F9         STR R0, [CFP, #72]
; 5ED8:       7D0300F9         STR CFP, [CSP]
; 5EDC:       76F5FF58         LDR LEXENV, #x8005735D88       ; #<SB-KERNEL:FDEFN GET-BYTES-CONSED>
; 5EE0:       170080D2         MOVZ NARGS, #0
; 5EE4:       DE9240F8         LDR LR, [LEXENV, #9]
; 5EE8:       FD031BAA         MOV CFP, CSP
; 5EEC:       C0033FD6         BLR LR
; 5EF0:       ABB746A9         LDP R1, R3, [CFP, #104]
; 5EF4:       AF3F40F9         LDR R5, [CFP, #120]
; 5EF8:       AA2B00F9         STR R0, [CFP, #80]
; 5EFC:       100080D2         MOVZ R6, #0
; 5F00:       57000014         B L8
; 5F04: L0:   030080D2         MOVZ NL3, #0
; 5F08:       50000014         B L7
; 5F0C: L1:   60915FF8         LDR NL0, [R1, #-7]
; 5F10:       1F0003EB         CMP NL0, NL3
; 5F14:       291C0054         BLS L20
; 5F18:       6909038B         ADD TMP, R1, NL3, LSL #2
; 5F1C:       271140F8         LDR NL7, [TMP, #1]
; 5F20:       A0915FF8         LDR NL0, [R3, #-7]
; 5F24:       1F0003EB         CMP NL0, NL3
; 5F28:       C91B0054         BLS L21
; 5F2C:       A909038B         ADD TMP, R3, NL3, LSL #2
; 5F30:       281140F8         LDR NL8, [TMP, #1]
; 5F34:       E0915FF8         LDR NL0, [R5, #-7]
; 5F38:       1F0003EB         CMP NL0, NL3
; 5F3C:       691B0054         BLS L22
; 5F40:       E905838B         ADD TMP, R5, NL3, ASR #1
; 5F44:       25054039         LDRB WNL5, [TMP, #1]
; 5F48:       BFE079F2         TST NL5, #18446744073709551488
; 5F4C:       E1180054         BNE L18
; 5F50:       040080D2         MOVZ NL4, #0
; 5F54:       020080D2         MOVZ NL2, #0
; 5F58:       1E000014         B L5
; 5F5C: L2:   E0018092         MOVN NL0, #15
; 5F60:       007C029B         MUL NL0, NL0, NL2
; 5F64:       06FC4193         ASR NL6, NL0, #1
; 5F68:       E10306CB         NEG NL1, NL6
; 5F6C:       E024C19A         LSR NL0, NL7, NL1
; 5F70:       00F87FD3         LSL NL0, NL0, #1
; 5F74:       00FC4193         ASR NL0, NL0, #1
; 5F78:       001C4092         AND NL0, NL0, #255
; 5F7C:       E10305AA         MOV NL1, NL5
; 5F80:       1F0001EB         CMP NL0, NL1
; 5F84:       80160054         BEQ L17
; 5F88: L3:   E0018092         MOVN NL0, #15
; 5F8C:       007C029B         MUL NL0, NL0, NL2
; 5F90:       06FC4193         ASR NL6, NL0, #1
; 5F94:       E10306CB         NEG NL1, NL6
; 5F98:       0025C19A         LSR NL0, NL8, NL1
; 5F9C:       00F87FD3         LSL NL0, NL0, #1
; 5FA0:       00FC4193         ASR NL0, NL0, #1
; 5FA4:       001C4092         AND NL0, NL0, #255
; 5FA8:       E10305AA         MOV NL1, NL5
; 5FAC:       1F0001EB         CMP NL0, NL1
; 5FB0:       A1000054         BNE L4
; 5FB4:       004080D2         MOVZ NL0, #512
; 5FB8:       0020C29A         LSL NL0, NL0, NL2
; 5FBC:       800000AA         ORR NL0, NL4, NL0
; 5FC0:       E40300AA         MOV NL4, NL0
; 5FC4: L4:   E00302AA         MOV NL0, NL2
; 5FC8:       00040091         ADD NL0, NL0, #1
; 5FCC:       E20300AA         MOV NL2, NL0
; 5FD0: L5:   5F2000F1         CMP NL2, #8
; 5FD4:       41FCFF54         BNE L2
; 5FD8:       A01B40F9         LDR NL0, [CFP, #48]
; 5FDC:       800000AB         ADDS NL0, NL4, NL0
; 5FE0:       86160054         BVS L23
; 5FE4:       A01B00F9         STR NL0, [CFP, #48]
; 5FE8:       A01F40F9         LDR NL0, [CFP, #56]
; 5FEC:       000800B1         ADDS NL0, NL0, #2
; 5FF0:       26160054         BVS L24
; 5FF4:       A01F00F9         STR NL0, [CFP, #56]
; 5FF8:       A01F40F9         LDR NL0, [CFP, #56]
; 5FFC:       1F2C7FF2         TST NL0, #8190
; 6000:       01020054         BNE L6
; 6004:       A3C305A9         STP NL3, R6, [CFP, #88]
; 6008:       ABB706A9         STP R1, R3, [CFP, #104]
; 600C:       AF3F00F9         STR R5, [CFP, #120]
; 6010:       7D0300F9         STR CFP, [CSP]
; 6014:       76EBFF58         LDR LEXENV, #x8005735D80       ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 6018:       170080D2         MOVZ NARGS, #0
; 601C:       DE9240F8         LDR LR, [LEXENV, #9]
; 6020:       FD031BAA         MOV CFP, CSP
; 6024:       C0033FD6         BLR LR
; 6028:       AD3F47A9         LDP R3, R5, [CFP, #112]
; 602C:       B02F46A9         LDP R6, R1, [CFP, #96]
; 6030:       A32F40F9         LDR NL3, [CFP, #88]
; 6034:       AC1740F9         LDR R2, [CFP, #40]
; 6038:       5F010CEB         CMP R0, R2
; 603C:       AA0F0054         BGE L16
; 6040: L6:   60080091         ADD NL0, NL3, #2
; 6044:       E30300AA         MOV NL3, NL0
; 6048: L7:   A02340F9         LDR NL0, [CFP, #64]
; 604C:       7F0000EB         CMP NL3, NL0
; 6050:       EBF5FF54         BLT L1
; 6054:       000A0091         ADD NL0, R6, #2
; 6058:       F00300AA         MOV R6, NL0
; 605C: L8:   A01340F9         LDR NL0, [CFP, #32]
; 6060:       1F0200EB         CMP R6, NL0
; 6064:       0BF5FF54         BLT L0
; 6068:       7D0300F9         STR CFP, [CSP]
; 606C:       F6E8FF58         LDR LEXENV, #x8005735D88       ; #<SB-KERNEL:FDEFN GET-BYTES-CONSED>
; 6070:       170080D2         MOVZ NARGS, #0
; 6074:       DE9240F8         LDR LR, [LEXENV, #9]
; 6078:       FD031BAA         MOV CFP, CSP
; 607C:       C0033FD6         BLR LR
; 6080:       EB030AAA         MOV R1, R0
; 6084:       AB2F00F9         STR R1, [CFP, #88]
; 6088:       7D0300F9         STR CFP, [CSP]
; 608C:       B6E7FF58         LDR LEXENV, #x8005735D80       ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 6090:       170080D2         MOVZ NARGS, #0
; 6094:       DE9240F8         LDR LR, [LEXENV, #9]
; 6098:       FD031BAA         MOV CFP, CSP
; 609C:       C0033FD6         BLR LR
; 60A0:       AB2F40F9         LDR R1, [CFP, #88]
; 60A4:       A02740F9         LDR NL0, [CFP, #72]
; 60A8:       400100CB         SUB NL0, R0, NL0
; 60AC:       A02300F9         STR NL0, [CFP, #64]
; 60B0:       7D0300F9         STR CFP, [CSP]
; 60B4:       EA030BAA         MOV R0, R1
; 60B8:       AB2B40F9         LDR R1, [CFP, #80]
; 60BC:       298280D2         MOVZ TMP, #1041
; 60C0:       5E6B69F8         LDR LR, [NULL, TMP]            ; SB-KERNEL:TWO-ARG--
; 60C4:       FD031BAA         MOV CFP, CSP
; 60C8:       C0033FD6         BLR LR
; 60CC:       EB030AAA         MOV R1, R0
; 60D0:       AB2700F9         STR R1, [CFP, #72]
; 60D4:       7D0300F9         STR CFP, [CSP]
; 60D8:       56E5FF58         LDR LEXENV, #x8005735D80       ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 60DC:       170080D2         MOVZ NARGS, #0
; 60E0:       DE9240F8         LDR LR, [LEXENV, #9]
; 60E4:       FD031BAA         MOV CFP, CSP
; 60E8:       C0033FD6         BLR LR
; 60EC:       AB2740F9         LDR R1, [CFP, #72]
; 60F0:       AC1740F9         LDR R2, [CFP, #40]
; 60F4:       5F010CEB         CMP R0, R2
; 60F8:       AA080054         BGE L15
; 60FC:       AA0F40F9         LDR R0, [CFP, #24]
; 6100:       405144F8         LDR NL0, [R0, #69]
; 6104:       A11340F9         LDR NL1, [CFP, #32]
; 6108:       21FC4193         ASR NL1, NL1, #1
; 610C:       00FC4193         ASR NL0, NL0, #1
; 6110:       237C409B         SMULH NL3, NL1, NL0
; 6114:       227C009B         MUL NL2, NL1, NL0
; 6118:       214280D2         MOVZ NL1, #529
; 611C:       7FFC82EB         CMP NL3, NL2, ASR #63
; 6120:       81000054         BNE L9
; 6124:       4A0002AB         ADDS R0, NL2, NL2
; 6128:       E7010054         BVC L11
; 612C:       212280D2         MOVZ NL1, #273
; 6130: L9:   BA2A00B9         STR WNULL, [THREAD, #40]       ; pseudo-atomic-bits
; 6134:       A97A47A9         LDP TMP, LR, [THREAD, #112]    ; mixed-tlab.{free-pointer, end-addr}
; 6138:       2A810091         ADD R0, TMP, #32
; 613C:       5F011EEB         CMP R0, LR
; 6140:       C80B0054         BHI L25
; 6144:       AA3A00F9         STR R0, [THREAD, #112]         ; mixed-tlab
; 6148: L10:  2A3D0091         ADD R0, TMP, #15
; 614C:       210900A9         STP NL1, NL2, [TMP]
; 6150:       230900F9         STR NL3, [TMP, #16]
; 6154:       BF2A00B9         STR WZR, [THREAD, #40]         ; pseudo-atomic-bits
; 6158:       BE2E40B9         LDR WLR, [THREAD, #44]         ; pseudo-atomic-bits
; 615C:       5E0000B4         CBZ LR, L11
; 6160:       200120D4         BRK #9                         ; Pending interrupt trap
; 6164: L11:  A01B40F9         LDR NL0, [CFP, #48]
; 6168:       5F0100EB         CMP R0, NL0
; 616C:       21010054         BNE L12
; 6170:       AA2340F9         LDR R0, [CFP, #64]
; 6174:       AC3743A9         LDP R2, R3, [CFP, #48]
; 6178:       F9031DAA         MOV OCFP, CFP
; 617C:       3B830091         ADD CSP, OCFP, #32
; 6180:       170180D2         MOVZ NARGS, #8
; 6184:       FF031FEB         CMP ZR, ZR
; 6188:       BD7B40A9         LDP CFP, LR, [CFP]
; 618C:       C0035FD6         RET
; 6190: L12:  A01B40F9         LDR NL0, [CFP, #48]
; 6194:       BA2A00B9         STR WNULL, [THREAD, #40]       ; pseudo-atomic-bits
; 6198:       A9FA45A9         LDP TMP, LR, [THREAD, #88]     ; cons-tlab.{free-pointer, end-addr}
; 619C:       2CC10091         ADD R2, TMP, #48
; 61A0:       9F011EEB         CMP R2, LR
; 61A4:       28090054         BHI L26
; 61A8:       AC2E00F9         STR R2, [THREAD, #88]          ; cons-tlab
; 61AC: L13:  2C1D0091         ADD R2, TMP, #7
; 61B0:       EE030CAA         MOV R4, R2
; 61B4:       2FDFFF58         LDR R5, #x8005735D98           ; :CYCLE-CHECKSUM
; 61B8:       CF911FF8         STR R5, [R4, #-7]
; 61BC:       CE410091         ADD R4, R4, #16
; 61C0:       CE111FF8         STR R4, [R4, #-15]
; 61C4:       EFDEFF58         LDR R5, #x8005735DA0           ; 'ARCDOCDB.SPK08.IMPRONTE::CYCLE-SCALAR-U64
; 61C8:       CF911FF8         STR R5, [R4, #-7]
; 61CC:       CE410091         ADD R4, R4, #16
; 61D0:       CE111FF8         STR R4, [R4, #-15]
; 61D4:       C0911FF8         STR NL0, [R4, #-7]
; 61D8:       DA1100F8         STR NULL, [R4, #1]
; 61DC:       BF2A00B9         STR WZR, [THREAD, #40]         ; pseudo-atomic-bits
; 61E0:       BE2E40B9         LDR WLR, [THREAD, #44]         ; pseudo-atomic-bits
; 61E4:       5E0000B4         CBZ LR, L14
; 61E8:       200120D4         BRK #9                         ; Pending interrupt trap
; 61EC: L14:  7D0300F9         STR CFP, [CSP]
; 61F0:       CADDFF58         LDR R0, #x8005735DA8           ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 61F4:       EBDDFF58         LDR R1, #x8005735DB0           ; :MOTIVO
; 61F8:       29A680D2         MOVZ TMP, #1329
; 61FC:       5E6B69F8         LDR LR, [NULL, TMP]            ; ERROR
; 6200:       D70080D2         MOVZ NARGS, #6
; 6204:       FD031BAA         MOV CFP, CSP
; 6208:       C0033FD6         BLR LR
; 620C: L15:  7D0300F9         STR CFP, [CSP]
; 6210:       CADCFF58         LDR R0, #x8005735DA8           ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 6214:       EBDCFF58         LDR R1, #x8005735DB0           ; :MOTIVO
; 6218:       0CDDFF58         LDR R2, #x8005735DB8           ; :TIME-BUDGET
; 621C:       29A680D2         MOVZ TMP, #1329
; 6220:       5E6B69F8         LDR LR, [NULL, TMP]            ; ERROR
; 6224:       D70080D2         MOVZ NARGS, #6
; 6228:       FD031BAA         MOV CFP, CSP
; 622C:       C0033FD6         BLR LR
; 6230: L16:  7D0300F9         STR CFP, [CSP]
; 6234:       AADBFF58         LDR R0, #x8005735DA8           ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 6238:       CBDBFF58         LDR R1, #x8005735DB0           ; :MOTIVO
; 623C:       ECDBFF58         LDR R2, #x8005735DB8           ; :TIME-BUDGET
; 6240:       29A680D2         MOVZ TMP, #1329
; 6244:       5E6B69F8         LDR LR, [NULL, TMP]            ; ERROR
; 6248:       D70080D2         MOVZ NARGS, #6
; 624C:       FD031BAA         MOV CFP, CSP
; 6250:       C0033FD6         BLR LR
; 6254: L17:  400080D2         MOVZ NL0, #2
; 6258:       0020C29A         LSL NL0, NL0, NL2
; 625C:       800000AA         ORR NL0, NL4, NL0
; 6260:       E40300AA         MOV NL4, NL0
; 6264:       49FFFF17         B L3
; 6268: L18:  80A328D4         BRK #17692                     ; OBJECT-NOT-TYPE-ERROR
                                                              ; NL5
; 626C:       33               BYTE #X33                      ; '(UNSIGNED-BYTE 7)
; 626D:       .ALIGN           4
; 6270: L19:  7D0300F9         STR CFP, [CSP]
; 6274:       AAD9FF58         LDR R0, #x8005735DA8           ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 6278:       CBD9FF58         LDR R1, #x8005735DB0           ; :MOTIVO
; 627C:       ECD9FF58         LDR R2, #x8005735DB8           ; :TIME-BUDGET
; 6280:       29A680D2         MOVZ TMP, #1329
; 6284:       5E6B69F8         LDR LR, [NULL, TMP]            ; ERROR
; 6288:       D70080D2         MOVZ NARGS, #6
; 628C:       FD031BAA         MOV CFP, CSP
; 6290:       C0033FD6         BLR LR
; 6294:       E00120D4         BRK #15                        ; Invalid argument count trap
; 6298: L20:  606421D4         BRK #2851                      ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R1
; 629C:       0C               BYTE #X0C                      ; NL3
; 629D:       .ALIGN           4
; 62A0: L21:  60A421D4         BRK #3363                      ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R3
; 62A4:       0C               BYTE #X0C                      ; NL3
; 62A5:       .ALIGN           4
; 62A8: L22:  60E421D4         BRK #3875                      ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R5
; 62AC:       0C               BYTE #X0C                      ; NL3
; 62AD:       .ALIGN           4
; 62B0: L23:  A00520D4         BRK #45                        ; ADD-SUB-OVERFLOW-ERROR
                                                              ; NL0
; 62B4: L24:  A00520D4         BRK #45                        ; ADD-SUB-OVERFLOW-ERROR
                                                              ; NL0
; 62B8: L25:  090480D2         MOVZ TMP, #32
; 62BC:       EAD8FF58         LDR R0, #x8005735DD8           ; SB-VM::ALLOC-TRAMP
; 62C0:       40013FD6         BLR R0
; 62C4:       A1FFFF17         B L10
; 62C8: L26:  090680D2         MOVZ TMP, #48
; 62CC:       ACD8FF58         LDR R2, #x8005735DE0           ; SB-VM::LIST-ALLOC-TRAMP
; 62D0:       80013FD6         BLR R2
; 62D4:       B6FFFF17         B L13
\")
   (:FUNCTION ARCDOCDB.SPK08.IMPRONTE::CYCLE-TYPEDU64 :TEXT
    \"; disassembly for ARCDOCDB.SPK08.IMPRONTE::CYCLE-TYPEDU64
; Size: 1204 bytes. Origin: #x80057363E4                      ; ARCDOCDB.SPK08.IMPRONTE::CYCLE-TYPEDU64
; 3E4:       AA0F40F9         LDR R0, [CFP, #24]
; 3E8:       4FD141F8         LDR R5, [R0, #29]
; 3EC:       AF3F00F9         STR R5, [CFP, #120]
; 3F0:       AA0F40F9         LDR R0, [CFP, #24]
; 3F4:       4B5142F8         LDR R1, [R0, #37]
; 3F8:       AB3700F9         STR R1, [CFP, #104]
; 3FC:       AA0F40F9         LDR R0, [CFP, #24]
; 400:       4DD142F8         LDR R3, [R0, #45]
; 404:       AD3B00F9         STR R3, [CFP, #112]
; 408:       AA0F40F9         LDR R0, [CFP, #24]
; 40C:       40D143F8         LDR NL0, [R0, #61]
; 410:       A02300F9         STR NL0, [CFP, #64]
; 414:       BF7F03A9         STP ZR, ZR, [CFP, #48]
; 418:       7D0300F9         STR CFP, [CSP]
; 41C:       36F7FF58         LDR LEXENV, #x8005736300        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 420:       170080D2         MOVZ NARGS, #0
; 424:       DE9240F8         LDR LR, [LEXENV, #9]
; 428:       FD031BAA         MOV CFP, CSP
; 42C:       C0033FD6         BLR LR
; 430:       ABB746A9         LDP R1, R3, [CFP, #104]
; 434:       AF3F40F9         LDR R5, [CFP, #120]
; 438:       A01740F9         LDR NL0, [CFP, #40]
; 43C:       5F0100EB         CMP R0, NL0
; 440:       8A1F0054         BGE L14
; 444:       AD3F07A9         STP R3, R5, [CFP, #112]
; 448:       AB3700F9         STR R1, [CFP, #104]
; 44C:       7D0300F9         STR CFP, [CSP]
; 450:       96F5FF58         LDR LEXENV, #x8005736300        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 454:       170080D2         MOVZ NARGS, #0
; 458:       DE9240F8         LDR LR, [LEXENV, #9]
; 45C:       FD031BAA         MOV CFP, CSP
; 460:       C0033FD6         BLR LR
; 464:       AA2700F9         STR R0, [CFP, #72]
; 468:       7D0300F9         STR CFP, [CSP]
; 46C:       F6F4FF58         LDR LEXENV, #x8005736308        ; #<SB-KERNEL:FDEFN GET-BYTES-CONSED>
; 470:       170080D2         MOVZ NARGS, #0
; 474:       DE9240F8         LDR LR, [LEXENV, #9]
; 478:       FD031BAA         MOV CFP, CSP
; 47C:       C0033FD6         BLR LR
; 480:       ABB746A9         LDP R1, R3, [CFP, #104]
; 484:       AF3F40F9         LDR R5, [CFP, #120]
; 488:       AA2B00F9         STR R0, [CFP, #80]
; 48C:       070080D2         MOVZ NL7, #0
; 490:       68000014         B L4
; 494: L0:   030080D2         MOVZ NL3, #0
; 498:       61000014         B L3
; 49C: L1:   60915FF8         LDR NL0, [R1, #-7]
; 4A0:       1F0003EB         CMP NL0, NL3
; 4A4:       A91D0054         BLS L15
; 4A8:       6909038B         ADD TMP, R1, NL3, LSL #2
; 4AC:       211140F8         LDR NL1, [TMP, #1]
; 4B0:       A0915FF8         LDR NL0, [R3, #-7]
; 4B4:       1F0003EB         CMP NL0, NL3
; 4B8:       491D0054         BLS L16
; 4BC:       A909038B         ADD TMP, R3, NL3, LSL #2
; 4C0:       251140F8         LDR NL5, [TMP, #1]
; 4C4:       E0915FF8         LDR NL0, [R5, #-7]
; 4C8:       1F0003EB         CMP NL0, NL3
; 4CC:       E91C0054         BLS L17
; 4D0:       E905838B         ADD TMP, R5, NL3, ASR #1
; 4D4:       20054039         LDRB WNL0, [TMP, #1]
; 4D8:       1FE079F2         TST NL0, #18446744073709551488
; 4DC:       611A0054         BNE L13
; 4E0:       E9C300B2         MOV TMP, #72340172838076673
; 4E4:       047C099B         MUL NL4, NL0, TMP
; 4E8:       E00304AA         MOV NL0, NL4
; 4EC:       200000CA         EOR NL0, NL1, NL0
; 4F0:       02D800B2         ORR NL2, NL0, #9187201950435737471
; 4F4:       00D80092         AND NL0, NL0, #9187201950435737471
; 4F8:       E1DB00B2         MOV NL1, #9187201950435737471
; 4FC:       0000018B         ADD NL0, NL0, NL1
; 500:       400000AA         ORR NL0, NL2, NL0
; 504:       01008092         MOVN NL1, #0
; 508:       000001CA         EOR NL0, NL0, NL1
; 50C:       00C00192         AND NL0, NL0, #9259542123273814144
; 510:       00FC47D3         LSR NL0, NL0, #7
; 514:       E10300AA         MOV NL1, NL0
; 518:       21FC47D3         LSR NL1, NL1, #7
; 51C:       000001AA         ORR NL0, NL0, NL1
; 520:       00840092         AND NL0, NL0, #844437815230467
; 524:       E10300AA         MOV NL1, NL0
; 528:       21FC4ED3         LSR NL1, NL1, #14
; 52C:       000001AA         ORR NL0, NL0, NL1
; 530:       000C0092         AND NL0, NL0, #64424509455
; 534:       00F87FD3         LSL NL0, NL0, #1
; 538:       01FC5C93         ASR NL1, NL0, #28
; 53C:       22F87F92         AND NL2, NL1, #18446744073709551614
; 540:       000002AA         ORR NL0, NL0, NL2
; 544:       061C7F92         AND NL6, NL0, #510
; 548:       E00304AA         MOV NL0, NL4
; 54C:       A00000CA         EOR NL0, NL5, NL0
; 550:       01D800B2         ORR NL1, NL0, #9187201950435737471
; 554:       00D80092         AND NL0, NL0, #9187201950435737471
; 558:       E2DB00B2         MOV NL2, #9187201950435737471
; 55C:       0000028B         ADD NL0, NL0, NL2
; 560:       200000AA         ORR NL0, NL1, NL0
; 564:       01008092         MOVN NL1, #0
; 568:       000001CA         EOR NL0, NL0, NL1
; 56C:       00C00192         AND NL0, NL0, #9259542123273814144
; 570:       00FC47D3         LSR NL0, NL0, #7
; 574:       E10300AA         MOV NL1, NL0
; 578:       21FC47D3         LSR NL1, NL1, #7
; 57C:       000001AA         ORR NL0, NL0, NL1
; 580:       00840092         AND NL0, NL0, #844437815230467
; 584:       E10300AA         MOV NL1, NL0
; 588:       21FC4ED3         LSR NL1, NL1, #14
; 58C:       000001AA         ORR NL0, NL0, NL1
; 590:       000C0092         AND NL0, NL0, #64424509455
; 594:       00F87FD3         LSL NL0, NL0, #1
; 598:       01FC5C93         ASR NL1, NL0, #28
; 59C:       22F87F92         AND NL2, NL1, #18446744073709551614
; 5A0:       000002AA         ORR NL0, NL0, NL2
; 5A4:       001C7F92         AND NL0, NL0, #510
; 5A8:       C02000AA         ORR NL0, NL6, NL0, LSL #8
; 5AC:       A11B40F9         LDR NL1, [CFP, #48]
; 5B0:       000001AB         ADDS NL0, NL0, NL1
; 5B4:       E6150054         BVS L18
; 5B8:       A01B00F9         STR NL0, [CFP, #48]
; 5BC:       A01F40F9         LDR NL0, [CFP, #56]
; 5C0:       000800B1         ADDS NL0, NL0, #2
; 5C4:       86150054         BVS L19
; 5C8:       A01F00F9         STR NL0, [CFP, #56]
; 5CC:       A01F40F9         LDR NL0, [CFP, #56]
; 5D0:       1F2C7FF2         TST NL0, #8190
; 5D4:       01020054         BNE L2
; 5D8:       A39F05A9         STP NL3, NL7, [CFP, #88]
; 5DC:       ABB706A9         STP R1, R3, [CFP, #104]
; 5E0:       AF3F00F9         STR R5, [CFP, #120]
; 5E4:       7D0300F9         STR CFP, [CSP]
; 5E8:       D6E8FF58         LDR LEXENV, #x8005736300        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 5EC:       170080D2         MOVZ NARGS, #0
; 5F0:       DE9240F8         LDR LR, [LEXENV, #9]
; 5F4:       FD031BAA         MOV CFP, CSP
; 5F8:       C0033FD6         BLR LR
; 5FC:       AD3F47A9         LDP R3, R5, [CFP, #112]
; 600:       A72F46A9         LDP NL7, R1, [CFP, #96]
; 604:       A32F40F9         LDR NL3, [CFP, #88]
; 608:       AC1740F9         LDR R2, [CFP, #40]
; 60C:       5F010CEB         CMP R0, R2
; 610:       AA0F0054         BGE L12
; 614: L2:   60080091         ADD NL0, NL3, #2
; 618:       E30300AA         MOV NL3, NL0
; 61C: L3:   A02340F9         LDR NL0, [CFP, #64]
; 620:       7F0000EB         CMP NL3, NL0
; 624:       CBF3FF54         BLT L1
; 628:       E0080091         ADD NL0, NL7, #2
; 62C:       E70300AA         MOV NL7, NL0
; 630: L4:   A01340F9         LDR NL0, [CFP, #32]
; 634:       FF0000EB         CMP NL7, NL0
; 638:       EBF2FF54         BLT L0
; 63C:       7D0300F9         STR CFP, [CSP]
; 640:       56E6FF58         LDR LEXENV, #x8005736308        ; #<SB-KERNEL:FDEFN GET-BYTES-CONSED>
; 644:       170080D2         MOVZ NARGS, #0
; 648:       DE9240F8         LDR LR, [LEXENV, #9]
; 64C:       FD031BAA         MOV CFP, CSP
; 650:       C0033FD6         BLR LR
; 654:       EB030AAA         MOV R1, R0
; 658:       AB2F00F9         STR R1, [CFP, #88]
; 65C:       7D0300F9         STR CFP, [CSP]
; 660:       16E5FF58         LDR LEXENV, #x8005736300        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 664:       170080D2         MOVZ NARGS, #0
; 668:       DE9240F8         LDR LR, [LEXENV, #9]
; 66C:       FD031BAA         MOV CFP, CSP
; 670:       C0033FD6         BLR LR
; 674:       AB2F40F9         LDR R1, [CFP, #88]
; 678:       A02740F9         LDR NL0, [CFP, #72]
; 67C:       400100CB         SUB NL0, R0, NL0
; 680:       A02300F9         STR NL0, [CFP, #64]
; 684:       7D0300F9         STR CFP, [CSP]
; 688:       EA030BAA         MOV R0, R1
; 68C:       AB2B40F9         LDR R1, [CFP, #80]
; 690:       298280D2         MOVZ TMP, #1041
; 694:       5E6B69F8         LDR LR, [NULL, TMP]             ; SB-KERNEL:TWO-ARG--
; 698:       FD031BAA         MOV CFP, CSP
; 69C:       C0033FD6         BLR LR
; 6A0:       EB030AAA         MOV R1, R0
; 6A4:       AB2700F9         STR R1, [CFP, #72]
; 6A8:       7D0300F9         STR CFP, [CSP]
; 6AC:       B6E2FF58         LDR LEXENV, #x8005736300        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 6B0:       170080D2         MOVZ NARGS, #0
; 6B4:       DE9240F8         LDR LR, [LEXENV, #9]
; 6B8:       FD031BAA         MOV CFP, CSP
; 6BC:       C0033FD6         BLR LR
; 6C0:       AB2740F9         LDR R1, [CFP, #72]
; 6C4:       AC1740F9         LDR R2, [CFP, #40]
; 6C8:       5F010CEB         CMP R0, R2
; 6CC:       AA080054         BGE L11
; 6D0:       AA0F40F9         LDR R0, [CFP, #24]
; 6D4:       405144F8         LDR NL0, [R0, #69]
; 6D8:       A11340F9         LDR NL1, [CFP, #32]
; 6DC:       21FC4193         ASR NL1, NL1, #1
; 6E0:       00FC4193         ASR NL0, NL0, #1
; 6E4:       237C409B         SMULH NL3, NL1, NL0
; 6E8:       227C009B         MUL NL2, NL1, NL0
; 6EC:       214280D2         MOVZ NL1, #529
; 6F0:       7FFC82EB         CMP NL3, NL2, ASR #63
; 6F4:       81000054         BNE L5
; 6F8:       4A0002AB         ADDS R0, NL2, NL2
; 6FC:       E7010054         BVC L7
; 700:       212280D2         MOVZ NL1, #273
; 704: L5:   BA2A00B9         STR WNULL, [THREAD, #40]        ; pseudo-atomic-bits
; 708:       A97A47A9         LDP TMP, LR, [THREAD, #112]     ; mixed-tlab.{free-pointer, end-addr}
; 70C:       2A810091         ADD R0, TMP, #32
; 710:       5F011EEB         CMP R0, LR
; 714:       280B0054         BHI L20
; 718:       AA3A00F9         STR R0, [THREAD, #112]          ; mixed-tlab
; 71C: L6:   2A3D0091         ADD R0, TMP, #15
; 720:       210900A9         STP NL1, NL2, [TMP]
; 724:       230900F9         STR NL3, [TMP, #16]
; 728:       BF2A00B9         STR WZR, [THREAD, #40]          ; pseudo-atomic-bits
; 72C:       BE2E40B9         LDR WLR, [THREAD, #44]          ; pseudo-atomic-bits
; 730:       5E0000B4         CBZ LR, L7
; 734:       200120D4         BRK #9                          ; Pending interrupt trap
; 738: L7:   A01B40F9         LDR NL0, [CFP, #48]
; 73C:       5F0100EB         CMP R0, NL0
; 740:       21010054         BNE L8
; 744:       AA2340F9         LDR R0, [CFP, #64]
; 748:       AC3743A9         LDP R2, R3, [CFP, #48]
; 74C:       F9031DAA         MOV OCFP, CFP
; 750:       3B830091         ADD CSP, OCFP, #32
; 754:       170180D2         MOVZ NARGS, #8
; 758:       FF031FEB         CMP ZR, ZR
; 75C:       BD7B40A9         LDP CFP, LR, [CFP]
; 760:       C0035FD6         RET
; 764: L8:   A01B40F9         LDR NL0, [CFP, #48]
; 768:       BA2A00B9         STR WNULL, [THREAD, #40]        ; pseudo-atomic-bits
; 76C:       A9FA45A9         LDP TMP, LR, [THREAD, #88]      ; cons-tlab.{free-pointer, end-addr}
; 770:       2CC10091         ADD R2, TMP, #48
; 774:       9F011EEB         CMP R2, LR
; 778:       88080054         BHI L21
; 77C:       AC2E00F9         STR R2, [THREAD, #88]           ; cons-tlab
; 780: L9:   2C1D0091         ADD R2, TMP, #7
; 784:       EE030CAA         MOV R4, R2
; 788:       0FDDFF58         LDR R5, #x8005736328            ; :CYCLE-CHECKSUM
; 78C:       CF911FF8         STR R5, [R4, #-7]
; 790:       CE410091         ADD R4, R4, #16
; 794:       CE111FF8         STR R4, [R4, #-15]
; 798:       CFDCFF58         LDR R5, #x8005736330            ; 'ARCDOCDB.SPK08.IMPRONTE::CYCLE-TYPEDU64
; 79C:       CF911FF8         STR R5, [R4, #-7]
; 7A0:       CE410091         ADD R4, R4, #16
; 7A4:       CE111FF8         STR R4, [R4, #-15]
; 7A8:       C0911FF8         STR NL0, [R4, #-7]
; 7AC:       DA1100F8         STR NULL, [R4, #1]
; 7B0:       BF2A00B9         STR WZR, [THREAD, #40]          ; pseudo-atomic-bits
; 7B4:       BE2E40B9         LDR WLR, [THREAD, #44]          ; pseudo-atomic-bits
; 7B8:       5E0000B4         CBZ LR, L10
; 7BC:       200120D4         BRK #9                          ; Pending interrupt trap
; 7C0: L10:  7D0300F9         STR CFP, [CSP]
; 7C4:       AADBFF58         LDR R0, #x8005736338            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 7C8:       CBDBFF58         LDR R1, #x8005736340            ; :MOTIVO
; 7CC:       29A680D2         MOVZ TMP, #1329
; 7D0:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 7D4:       D70080D2         MOVZ NARGS, #6
; 7D8:       FD031BAA         MOV CFP, CSP
; 7DC:       C0033FD6         BLR LR
; 7E0: L11:  7D0300F9         STR CFP, [CSP]
; 7E4:       AADAFF58         LDR R0, #x8005736338            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 7E8:       CBDAFF58         LDR R1, #x8005736340            ; :MOTIVO
; 7EC:       ECDAFF58         LDR R2, #x8005736348            ; :TIME-BUDGET
; 7F0:       29A680D2         MOVZ TMP, #1329
; 7F4:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 7F8:       D70080D2         MOVZ NARGS, #6
; 7FC:       FD031BAA         MOV CFP, CSP
; 800:       C0033FD6         BLR LR
; 804: L12:  7D0300F9         STR CFP, [CSP]
; 808:       8AD9FF58         LDR R0, #x8005736338            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 80C:       ABD9FF58         LDR R1, #x8005736340            ; :MOTIVO
; 810:       CCD9FF58         LDR R2, #x8005736348            ; :TIME-BUDGET
; 814:       29A680D2         MOVZ TMP, #1329
; 818:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 81C:       D70080D2         MOVZ NARGS, #6
; 820:       FD031BAA         MOV CFP, CSP
; 824:       C0033FD6         BLR LR
; 828: L13:  800328D4         BRK #16412                      ; OBJECT-NOT-TYPE-ERROR
                                                              ; NL0
; 82C:       3B               BYTE #X3B                       ; '(UNSIGNED-BYTE 7)
; 82D:       .ALIGN           4
; 830: L14:  7D0300F9         STR CFP, [CSP]
; 834:       2AD8FF58         LDR R0, #x8005736338            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 838:       4BD8FF58         LDR R1, #x8005736340            ; :MOTIVO
; 83C:       6CD8FF58         LDR R2, #x8005736348            ; :TIME-BUDGET
; 840:       29A680D2         MOVZ TMP, #1329
; 844:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 848:       D70080D2         MOVZ NARGS, #6
; 84C:       FD031BAA         MOV CFP, CSP
; 850:       C0033FD6         BLR LR
; 854:       E00120D4         BRK #15                         ; Invalid argument count trap
; 858: L15:  606421D4         BRK #2851                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R1
; 85C:       0C               BYTE #X0C                       ; NL3
; 85D:       .ALIGN           4
; 860: L16:  60A421D4         BRK #3363                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R3
; 864:       0C               BYTE #X0C                       ; NL3
; 865:       .ALIGN           4
; 868: L17:  60E421D4         BRK #3875                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R5
; 86C:       0C               BYTE #X0C                       ; NL3
; 86D:       .ALIGN           4
; 870: L18:  A00520D4         BRK #45                         ; ADD-SUB-OVERFLOW-ERROR
                                                              ; NL0
; 874: L19:  A00520D4         BRK #45                         ; ADD-SUB-OVERFLOW-ERROR
                                                              ; NL0
; 878: L20:  090480D2         MOVZ TMP, #32
; 87C:       6AD7FF58         LDR R0, #x8005736368            ; SB-VM::ALLOC-TRAMP
; 880:       40013FD6         BLR R0
; 884:       A6FFFF17         B L6
; 888: L21:  090680D2         MOVZ TMP, #48
; 88C:       2CD7FF58         LDR R2, #x8005736370            ; SB-VM::LIST-ALLOC-TRAMP
; 890:       80013FD6         BLR R2
; 894:       BBFFFF17         B L9
\")))
 :LOAD
 (:STATUS :OK :FASL
  #A((142) BASE-CHAR
     . \"/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB/spikes/SPK-08-generated-code/out/4000480868-impronte-87419-0/impronte.fasl\"))
 :COMPILE
 (:STATUS :OK :OUTPUT
  #A((142) BASE-CHAR
     . \"/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB/spikes/SPK-08-generated-code/out/4000480868-impronte-87419-0/impronte.fasl\")
  :WARNINGS-P NIL :FAILURE-P NIL)
 :STAGE :COMPLETE :SCHEMA-VERSION 1 :KIND :IMPRONTE-COMPILE-CHECK :STATUS :OK
 :COMMAND
 (\"/opt/homebrew/bin/sbcl\" \"--noinform\" \"--no-sysinit\" \"--no-userinit\"
  \"--script\" #3# . #18=(#A((13) BASE-CHAR . \"compile-check\")))
 :RUNTIME-ARGV
 (#A((48) BASE-CHAR . \"/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl\")
  . #18#)
 :STDIN (:MODE :EOF :CONTENTS \"\" :REDIRECT \"/dev/null\") :ENVIRONMENT
 (:CWD
  #A((68) BASE-CHAR
     . \"/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB/\")
  :LISP #4# :VERSION #5# :OS #A((6) BASE-CHAR . \"Darwin\") :OS-VERSION #6#
  :MACHINE #7# :CPU \"Apple M4\" :MEMORY-BYTES \"17179869184\" :LOGICAL-CPUS \"10\"
  :LOAD-AVERAGE \"{ 2.97 4.19 7.63 }\" :EXTERNAL-LOAD :UNCONTROLLED :COMMIT
  \"62267c9811210c822973d240419daa986e8d8757\" :INTERNAL-TIME-UNITS-PER-SECOND
  1000000 :PROCESS-ID 87419 :FEATURES
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
 ((:PATH #1# :GIT-BLOB \"2ad6de50fdb7ef94cda1991dce08140fa2ed8ce8\" :CONTENTS
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

(macrolet ((definit-cycle (name expression)
  ;; Quattro cicli diretti; nessun macro globale ridefinito al caricamento.
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
           (values ticks bytes acc operations)))))))

(definit-cycle cycle-scalar16
  (scalar16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definit-cycle cycle-packedmask16
  (packedmask16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definit-cycle cycle-scalar-u64
  (scalar-u64 (aref low row) (aref high row) (aref queries row)))
(definit-cycle cycle-typedu64
  (typedu64 (aref low row) (aref high row) (aref queries row))))

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
  (:PATH #3# :GIT-BLOB \"fbbfc43ea30ebe9a79384735efe256a09c393d23\" :CONTENTS
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
              (setf (getf record :stage) :compile)
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
                (setf (getf record :stage) :load)
                (load fasl)
                (setf (getf record :load) (list :status :ok :fasl (namestring fasl))
                      (getf record :stage) :check)
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
              (setf (getf record :status) :ok (getf record :stage) :complete)))
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
 :STARTED-AT-UNIVERSAL-TIME 4000480868 :LIMITS
 (:SAFETY 3 :WARNING-FATAL T :STYLE-WARNING-FATAL T :COMPILE-ONLY-THIS-MODULE T
  :BENCH-NEVER-CALLED T :CHECK-MAX-CASES 4000000 :CHECK-SECONDS 120
  :STDOUT-TRUNCATED NIL :STDERR-TRUNCATED NIL :SOURCE-SCOPE
  :IMPRONTE-METHOD-AND-DRIVER :DEADLINE-COOPERATIVE T))
"
 :DECODED-RECORD
 (:SOURCE-CONSISTENCY :STABLE :SOURCE-AFTER
  ((:PATH "spikes/SPK-08-generated-code/impronte.lisp" :GIT-BLOB
    "2ad6de50fdb7ef94cda1991dce08140fa2ed8ce8" :CONTENTS
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

(macrolet ((definit-cycle (name expression)
  ;; Quattro cicli diretti; nessun macro globale ridefinito al caricamento.
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
           (values ticks bytes acc operations)))))))

(definit-cycle cycle-scalar16
  (scalar16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definit-cycle cycle-packedmask16
  (packedmask16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definit-cycle cycle-scalar-u64
  (scalar-u64 (aref low row) (aref high row) (aref queries row)))
(definit-cycle cycle-typedu64
  (typedu64 (aref low row) (aref high row) (aref queries row))))

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
    "fbbfc43ea30ebe9a79384735efe256a09c393d23" :CONTENTS
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
              (setf (getf record :stage) :compile)
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
                (setf (getf record :stage) :load)
                (load fasl)
                (setf (getf record :load) (list :status :ok :fasl (namestring fasl))
                      (getf record :stage) :check)
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
              (setf (getf record :status) :ok (getf record :stage) :complete)))
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
  :WALL-SECONDS 1.005499d0 :FINISHED-AT-UNIVERSAL-TIME 4000480869 :EXIT-CODE 0
  :STYLE-WARNING-COUNT 0 :WARNING-COUNT 0 :STDERR "" :STDOUT
  "CHECK :OK; groups=3035203 kernels=12140812 negatives=77 mutants=28
"
  :CHECK-SECONDS 0.781766d0 :DECODED-CHECK
  (:STATUS :OK :MODULE :IMPRONTE-SCALAR-SWAR :RUNTIME
   (:LISP #A((4) BASE-CHAR . "SBCL") :VERSION #A((5) BASE-CHAR . "2.6.9") :OS
    #A((6) BASE-CHAR . "Darwin") :OS-VERSION #A((6) BASE-CHAR . "27.0.0")
    :MACHINE #A((5) BASE-CHAR . "ARM64") :MACHINE-VERSION
    #A((8) BASE-CHAR . "Apple M4") :SAFETY 3 :HARDWARE-SIMD NIL :PACKING-ENDIAN
    :LITTLE :HOST-ENDIAN :LITTLE :INTERNAL-TIME-UNITS-PER-SECOND 1000000)
   :GROUPS 3035203 :KERNEL-COMPARISONS 12140812 :CAMPAIGNS
   ((:NAME :ALL-BYTE-QUERY-POSITION :GROUPS 524288 :KERNEL-COMPARISONS 2097152
     :INPUT-UNCHANGED T)
    (:NAME :ALL-ADJACENT-BYTE-PAIRS :GROUPS 1966080 :KERNEL-COMPARISONS 7864320
     :INPUT-UNCHANGED T)
    (:NAME :ALL-POSITION-PAIRS-SMALL-DOMAIN :GROUPS 65536 :KERNEL-COMPARISONS
     262144 :INPUT-UNCHANGED T)
    (:NAME :EXHAUSTIVE-FOUR-TO-EIGHT :GROUPS 393216 :KERNEL-COMPARISONS 1572864
     :INPUT-UNCHANGED T)
    (:NAME :ALL-MASK16 :GROUPS 65536 :KERNEL-COMPARISONS 262144
     :INPUT-UNCHANGED T)
    (:NAME :OFFSET-ENDIAN-BOUNDARIES :GROUPS 518 :KERNEL-COMPARISONS 2072
     :INPUT-UNCHANGED T)
    (:NAME :DETERMINISTIC-DIFFERENTIAL :GROUPS 20000 :KERNEL-COMPARISONS 80000
     :INPUT-UNCHANGED T))
   :DIFFERENTIAL-SEED 439041101 :FINAL-LCG-STATE 2997108077 :NEGATIVE-CONTROLS
   ((:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      0 -1)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      0 128)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      0 255)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      0 1/2)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      0 :BAD)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      -1 0)
     :CONDITION #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      49 0)
     :CONDITION #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      64 0)
     :CONDITION #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      1/2 0)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      :BAD 0)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS (#A((0) (UNSIGNED-BYTE 8)) 0 0) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS (#A((1) (UNSIGNED-BYTE 8) 0) 0 0) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS (#A((15) (UNSIGNED-BYTE 8) 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) 0 0)
     :CONDITION #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS (#(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) 0 0) :CONDITION TYPE-ERROR
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS
     (#A((4 4) (UNSIGNED-BYTE 8) (0 0 0 0) (0 0 0 0) (0 0 0 0) (0 0 0 0)) 0 0)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS
     (#A((16) (UNSIGNED-BYTE 8) 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) 0 0)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     :ARGUMENTS
     (#A((16) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128)
      0 0)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      0 -1)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      0 128)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      0 255)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      0 1/2)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      0 :BAD)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      -1 0)
     :CONDITION #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      49 0)
     :CONDITION #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      64 0)
     :CONDITION #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      1/2 0)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS
     (#A((64) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128
         128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128 128)
      :BAD 0)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS (#A((0) (UNSIGNED-BYTE 8)) 0 0) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS (#A((1) (UNSIGNED-BYTE 8) 0) 0 0) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS (#A((15) (UNSIGNED-BYTE 8) 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) 0 0)
     :CONDITION #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS (#(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) 0 0) :CONDITION TYPE-ERROR
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS
     (#A((4 4) (UNSIGNED-BYTE 8) (0 0 0 0) (0 0 0 0) (0 0 0 0) (0 0 0 0)) 0 0)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS
     (#A((16) (UNSIGNED-BYTE 8) 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) 0 0)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :ARGUMENTS
     (#A((16) (UNSIGNED-BYTE 8) 128 128 128 128 128 128 128 0 1 128 128 128 128
         128 128 128)
      0 0)
     :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((35) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64")
     :ARGUMENTS (-1 0 0) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((35) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64")
     :ARGUMENTS (0 -1 0) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((35) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64")
     :ARGUMENTS (18446744073709551616 0 0) :CONDITION TYPE-ERROR
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((35) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64")
     :ARGUMENTS (0 18446744073709551616 0) :CONDITION TYPE-ERROR
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((35) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64")
     :ARGUMENTS (1/2 0 0) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((35) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64")
     :ARGUMENTS (0 1/2 0) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((35) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64")
     :ARGUMENTS (:BAD 0 0) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((35) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64")
     :ARGUMENTS (0 :BAD 0) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((35) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64")
     :ARGUMENTS (0 0 -1) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((35) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64")
     :ARGUMENTS (0 0 128) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((35) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64")
     :ARGUMENTS (0 0 255) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((35) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64")
     :ARGUMENTS (0 0 1/2) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((35) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64")
     :ARGUMENTS (0 0 :BAD) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::TYPEDU64")
     :ARGUMENTS (-1 0 0) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::TYPEDU64")
     :ARGUMENTS (0 -1 0) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::TYPEDU64")
     :ARGUMENTS (18446744073709551616 0 0) :CONDITION TYPE-ERROR
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::TYPEDU64")
     :ARGUMENTS (0 18446744073709551616 0) :CONDITION TYPE-ERROR
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::TYPEDU64")
     :ARGUMENTS (1/2 0 0) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::TYPEDU64")
     :ARGUMENTS (0 1/2 0) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::TYPEDU64")
     :ARGUMENTS (:BAD 0 0) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::TYPEDU64")
     :ARGUMENTS (0 :BAD 0) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::TYPEDU64")
     :ARGUMENTS (0 0 -1) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::TYPEDU64")
     :ARGUMENTS (0 0 128) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::TYPEDU64")
     :ARGUMENTS (0 0 255) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::TYPEDU64")
     :ARGUMENTS (0 0 1/2) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::TYPEDU64")
     :ARGUMENTS (0 0 :BAD) :CONDITION TYPE-ERROR :INPUT-UNCHANGED T)
    (:FUNCTION #A((30) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::CHECK") :ARGUMENTS
     (:MAX-CASES 1 :DIFFERENTIAL-CASES 1 :SECONDS 120) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((30) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::CHECK") :ARGUMENTS
     (:MAX-CASES 0) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((30) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::CHECK") :ARGUMENTS
     (:DIFFERENTIAL-CASES 100001) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((30) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::CHECK") :ARGUMENTS
     (:SECONDS 0) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((39) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::RESPECTE-TEMPS")
     :ARGUMENTS (1820530) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH")
     :ARGUMENTS (15 1 1 60 16777216) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH")
     :ARGUMENTS (8193 1 1 60 16777216) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH")
     :ARGUMENTS (16 0 1 60 16777216) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH")
     :ARGUMENTS (16 1025 1 60 16777216) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH")
     :ARGUMENTS (16 1 0 60 16777216) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH")
     :ARGUMENTS (16 1 65 60 16777216) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH")
     :ARGUMENTS (16 1 1 0 16777216) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH")
     :ARGUMENTS (16 1 1 301 16777216) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH")
     :ARGUMENTS (16 1 1 60 0) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH")
     :ARGUMENTS (16 1 1 60 67108865) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH")
     :ARGUMENTS (16 1 1 60 1) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T)
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::VALIDE-BENCH")
     :ARGUMENTS (8192 1024 64 60 67108864) :CONDITION
     #A((40) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE")
     :INPUT-UNCHANGED T))
   :NEGATIVE-CONTROL-COUNT 77 :MUTANT :BORROW-SUBTRACTION :MUTANT-KILLED-COUNT
   28 :MUTANT-WITNESSES
   ((:QUERY 0 :POSITION 0 :CTRL
     (0 1 128 128 128 128 128 128 128 128 128 128 128 128 128 128) :ORACLE 1
     :MUTANT 3 :EXTRA-POSITION 1)
    (:QUERY 0 :POSITION 1 :CTRL
     (128 0 1 128 128 128 128 128 128 128 128 128 128 128 128 128) :ORACLE 2
     :MUTANT 6 :EXTRA-POSITION 2)
    (:QUERY 0 :POSITION 2 :CTRL
     (128 128 0 1 128 128 128 128 128 128 128 128 128 128 128 128) :ORACLE 4
     :MUTANT 12 :EXTRA-POSITION 3)
    (:QUERY 0 :POSITION 3 :CTRL
     (128 128 128 0 1 128 128 128 128 128 128 128 128 128 128 128) :ORACLE 8
     :MUTANT 24 :EXTRA-POSITION 4)
    (:QUERY 0 :POSITION 4 :CTRL
     (128 128 128 128 0 1 128 128 128 128 128 128 128 128 128 128) :ORACLE 16
     :MUTANT 48 :EXTRA-POSITION 5)
    (:QUERY 0 :POSITION 5 :CTRL
     (128 128 128 128 128 0 1 128 128 128 128 128 128 128 128 128) :ORACLE 32
     :MUTANT 96 :EXTRA-POSITION 6)
    (:QUERY 0 :POSITION 6 :CTRL
     (128 128 128 128 128 128 0 1 128 128 128 128 128 128 128 128) :ORACLE 64
     :MUTANT 192 :EXTRA-POSITION 7)
    (:QUERY 0 :POSITION 8 :CTRL
     (128 128 128 128 128 128 128 128 0 1 128 128 128 128 128 128) :ORACLE 256
     :MUTANT 768 :EXTRA-POSITION 9)
    (:QUERY 0 :POSITION 9 :CTRL
     (128 128 128 128 128 128 128 128 128 0 1 128 128 128 128 128) :ORACLE 512
     :MUTANT 1536 :EXTRA-POSITION 10)
    (:QUERY 0 :POSITION 10 :CTRL
     (128 128 128 128 128 128 128 128 128 128 0 1 128 128 128 128) :ORACLE 1024
     :MUTANT 3072 :EXTRA-POSITION 11)
    (:QUERY 0 :POSITION 11 :CTRL
     (128 128 128 128 128 128 128 128 128 128 128 0 1 128 128 128) :ORACLE 2048
     :MUTANT 6144 :EXTRA-POSITION 12)
    (:QUERY 0 :POSITION 12 :CTRL
     (128 128 128 128 128 128 128 128 128 128 128 128 0 1 128 128) :ORACLE 4096
     :MUTANT 12288 :EXTRA-POSITION 13)
    (:QUERY 0 :POSITION 13 :CTRL
     (128 128 128 128 128 128 128 128 128 128 128 128 128 0 1 128) :ORACLE 8192
     :MUTANT 24576 :EXTRA-POSITION 14)
    (:QUERY 0 :POSITION 14 :CTRL
     (128 128 128 128 128 128 128 128 128 128 128 128 128 128 0 1) :ORACLE
     16384 :MUTANT 49152 :EXTRA-POSITION 15)
    (:QUERY 127 :POSITION 0 :CTRL
     (127 126 128 128 128 128 128 128 128 128 128 128 128 128 128 128) :ORACLE
     1 :MUTANT 3 :EXTRA-POSITION 1)
    (:QUERY 127 :POSITION 1 :CTRL
     (128 127 126 128 128 128 128 128 128 128 128 128 128 128 128 128) :ORACLE
     2 :MUTANT 6 :EXTRA-POSITION 2)
    (:QUERY 127 :POSITION 2 :CTRL
     (128 128 127 126 128 128 128 128 128 128 128 128 128 128 128 128) :ORACLE
     4 :MUTANT 12 :EXTRA-POSITION 3)
    (:QUERY 127 :POSITION 3 :CTRL
     (128 128 128 127 126 128 128 128 128 128 128 128 128 128 128 128) :ORACLE
     8 :MUTANT 24 :EXTRA-POSITION 4)
    (:QUERY 127 :POSITION 4 :CTRL
     (128 128 128 128 127 126 128 128 128 128 128 128 128 128 128 128) :ORACLE
     16 :MUTANT 48 :EXTRA-POSITION 5)
    (:QUERY 127 :POSITION 5 :CTRL
     (128 128 128 128 128 127 126 128 128 128 128 128 128 128 128 128) :ORACLE
     32 :MUTANT 96 :EXTRA-POSITION 6)
    (:QUERY 127 :POSITION 6 :CTRL
     (128 128 128 128 128 128 127 126 128 128 128 128 128 128 128 128) :ORACLE
     64 :MUTANT 192 :EXTRA-POSITION 7)
    (:QUERY 127 :POSITION 8 :CTRL
     (128 128 128 128 128 128 128 128 127 126 128 128 128 128 128 128) :ORACLE
     256 :MUTANT 768 :EXTRA-POSITION 9)
    (:QUERY 127 :POSITION 9 :CTRL
     (128 128 128 128 128 128 128 128 128 127 126 128 128 128 128 128) :ORACLE
     512 :MUTANT 1536 :EXTRA-POSITION 10)
    (:QUERY 127 :POSITION 10 :CTRL
     (128 128 128 128 128 128 128 128 128 128 127 126 128 128 128 128) :ORACLE
     1024 :MUTANT 3072 :EXTRA-POSITION 11)
    (:QUERY 127 :POSITION 11 :CTRL
     (128 128 128 128 128 128 128 128 128 128 128 127 126 128 128 128) :ORACLE
     2048 :MUTANT 6144 :EXTRA-POSITION 12)
    (:QUERY 127 :POSITION 12 :CTRL
     (128 128 128 128 128 128 128 128 128 128 128 128 127 126 128 128) :ORACLE
     4096 :MUTANT 12288 :EXTRA-POSITION 13)
    (:QUERY 127 :POSITION 13 :CTRL
     (128 128 128 128 128 128 128 128 128 128 128 128 128 127 126 128) :ORACLE
     8192 :MUTANT 24576 :EXTRA-POSITION 14)
    (:QUERY 127 :POSITION 14 :CTRL
     (128 128 128 128 128 128 128 128 128 128 128 128 128 128 127 126) :ORACLE
     16384 :MUTANT 49152 :EXTRA-POSITION 15))
   :WORD-BOUNDARY-CONTROLS 1 :MASK-API
   ((#A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16")
     #A((29) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::CTRL")
     #A((30) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::START")
     #A((27) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::H7"))
    (#A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     #A((29) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::CTRL")
     #A((30) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::START")
     #A((27) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::H7"))
    (#A((35) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64")
     #A((28) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::LOW")
     #A((29) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::HIGH")
     #A((27) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::H7"))
    (#A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::TYPEDU64")
     #A((28) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::LOW")
     #A((29) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::HIGH")
     #A((27) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::H7")))
   :BENCH-API
   (#A((30) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::BENCH") &KEY
    #A((29) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::ROWS")
    #A((31) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PASSES")
    #A((38) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::WARMUP-PASSES")
    #A((32) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SECONDS")
    #A((36) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::BYTE-BUDGET"))
   :BENCH-EXECUTED NIL :LIMITS
   (:MAX-CASES 4000000 :DIFFERENTIAL-CASES 20000 :SECONDS 120
    :CHECKPOINT-GROUPS 4096 :COOPERATIVE-DEADLINE T :DOMAIN-BYTE-VALUES 256
    :QUERY-VALUES 128 :GROUP-BYTES 16 :PACKED-WORDS 2 :SMALL-DOMAIN-WORD-STATES
    65536 :NO-SOURCE-MUTATION T :HARDWARE-SIMD NIL :PRODUCTION-INTEGRATION NIL)
   :DISASSEMBLY
   ((:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR16") :TEXT
     "; disassembly for ARCDOCDB.SPK08.IMPRONTE::SCALAR16
; Size: 168 bytes. Origin: #x8005731298                       ; ARCDOCDB.SPK08.IMPRONTE::SCALAR16
; 298:       40915FF8         LDR NL0, [R0, #-7]
; 29C:       008000D1         SUB NL0, NL0, #32
; 2A0:       BF0100F1         CMP R3, #0
; 2A4:       A0A140FA         CCMP R3, NL0, #0, GE
; 2A8:       4C030054         BGT L3
; 2AC:       020080D2         MOVZ NL2, #0
; 2B0:       000080D2         MOVZ NL0, #0
; 2B4:       10000014         B L2
; 2B8: L0:   EB030DAA         MOV R1, R3
; 2BC:       6101008B         ADD NL1, R1, NL0
; 2C0:       43915FF8         LDR NL3, [R0, #-7]
; 2C4:       7F0001EB         CMP NL3, NL1
; 2C8:       89030054         BLS L4
; 2CC:       4905818B         ADD TMP, R0, NL1, ASR #1
; 2D0:       21054039         LDRB WNL1, [TMP, #1]
; 2D4:       21F87FD3         LSL NL1, NL1, #1
; 2D8:       3F000CEB         CMP NL1, R2
; 2DC:       A1000054         BNE L1
; 2E0:       01FC4193         ASR NL1, NL0, #1
; 2E4:       430080D2         MOVZ NL3, #2
; 2E8:       6120C19A         LSL NL1, NL3, NL1
; 2EC:       420001AA         ORR NL2, NL2, NL1
; 2F0: L1:   00080091         ADD NL0, NL0, #2
; 2F4: L2:   1F8000F1         CMP NL0, #32
; 2F8:       01FEFF54         BNE L0
; 2FC:       EA0302AA         MOV R0, NL2
; 300:       FB031DAA         MOV CSP, CFP
; 304:       5F0300F1         CMP NULL, #0
; 308:       BD7B40A9         LDP CFP, LR, [CFP]
; 30C:       C0035FD6         RET
; 310: L3:   7D0300F9         STR CFP, [CSP]
; 314:       2AF8FF58         LDR R0, #x8005731218            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 318:       4BF8FF58         LDR R1, #x8005731220            ; :MOTIVO
; 31C:       6CF8FF58         LDR R2, #x8005731228            ; :INVALID-WINDOW
; 320:       29A680D2         MOVZ TMP, #1329
; 324:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 328:       D70080D2         MOVZ NARGS, #6
; 32C:       FD031BAA         MOV CFP, CSP
; 330:       C0033FD6         BLR LR
; 334:       E00120D4         BRK #15                         ; Invalid argument count trap
; 338: L4:   604421D4         BRK #2595                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R0
; 33C:       04               BYTE #X04                       ; NL1
; 33D:       .ALIGN           4
")
    (:FUNCTION #A((37) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16")
     :TEXT "; disassembly for ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16
; Size: 444 bytes. Origin: #x80057317C8                       ; ARCDOCDB.SPK08.IMPRONTE::PACKEDMASK16
; 7C8:       40915FF8         LDR NL0, [R0, #-7]
; 7CC:       008000D1         SUB NL0, NL0, #32
; 7D0:       BF0100F1         CMP R3, #0
; 7D4:       A0A140FA         CCMP R3, NL0, #0, GE
; 7D8:       AC0B0054         BGT L4
; 7DC:       050080D2         MOVZ NL5, #0
; 7E0:       000080D2         MOVZ NL0, #0
; 7E4:       0E000014         B L1
; 7E8: L0:   EB030DAA         MOV R1, R3
; 7EC:       6101008B         ADD NL1, R1, NL0
; 7F0:       42915FF8         LDR NL2, [R0, #-7]
; 7F4:       5F0001EB         CMP NL2, NL1
; 7F8:       E90B0054         BLS L5
; 7FC:       4905818B         ADD TMP, R0, NL1, ASR #1
; 800:       21054039         LDRB WNL1, [TMP, #1]
; 804:       02FC4193         ASR NL2, NL0, #1
; 808:       42F07DD3         LSL NL2, NL2, #3
; 80C:       2120C29A         LSL NL1, NL1, NL2
; 810:       A10001AA         ORR NL1, NL5, NL1
; 814:       E50301AA         MOV NL5, NL1
; 818:       00080091         ADD NL0, NL0, #2
; 81C: L1:   1F4000F1         CMP NL0, #16
; 820:       41FEFF54         BNE L0
; 824:       A3410091         ADD NL3, R3, #16
; 828:       040080D2         MOVZ NL4, #0
; 82C:       000080D2         MOVZ NL0, #0
; 830:       0D000014         B L3
; 834: L2:   6100008B         ADD NL1, NL3, NL0
; 838:       42915FF8         LDR NL2, [R0, #-7]
; 83C:       5F0001EB         CMP NL2, NL1
; 840:       E9090054         BLS L6
; 844:       4905818B         ADD TMP, R0, NL1, ASR #1
; 848:       21054039         LDRB WNL1, [TMP, #1]
; 84C:       02FC4193         ASR NL2, NL0, #1
; 850:       42F07DD3         LSL NL2, NL2, #3
; 854:       2120C29A         LSL NL1, NL1, NL2
; 858:       810001AA         ORR NL1, NL4, NL1
; 85C:       E40301AA         MOV NL4, NL1
; 860:       00080091         ADD NL0, NL0, #2
; 864: L3:   1F4000F1         CMP NL0, #16
; 868:       61FEFF54         BNE L2
; 86C:       80FD4193         ASR NL0, R2, #1
; 870:       E9C300B2         MOV TMP, #72340172838076673
; 874:       037C099B         MUL NL3, NL0, TMP
; 878:       E00303AA         MOV NL0, NL3
; 87C:       A00000CA         EOR NL0, NL5, NL0
; 880:       01D800B2         ORR NL1, NL0, #9187201950435737471
; 884:       00D80092         AND NL0, NL0, #9187201950435737471
; 888:       E2DB00B2         MOV NL2, #9187201950435737471
; 88C:       0000028B         ADD NL0, NL0, NL2
; 890:       200000AA         ORR NL0, NL1, NL0
; 894:       01008092         MOVN NL1, #0
; 898:       000001CA         EOR NL0, NL0, NL1
; 89C:       00C00192         AND NL0, NL0, #9259542123273814144
; 8A0:       00FC47D3         LSR NL0, NL0, #7
; 8A4:       E10300AA         MOV NL1, NL0
; 8A8:       21FC47D3         LSR NL1, NL1, #7
; 8AC:       000001AA         ORR NL0, NL0, NL1
; 8B0:       00840092         AND NL0, NL0, #844437815230467
; 8B4:       E10300AA         MOV NL1, NL0
; 8B8:       21FC4ED3         LSR NL1, NL1, #14
; 8BC:       000001AA         ORR NL0, NL0, NL1
; 8C0:       000C0092         AND NL0, NL0, #64424509455
; 8C4:       00F87FD3         LSL NL0, NL0, #1
; 8C8:       01FC5C93         ASR NL1, NL0, #28
; 8CC:       22F87F92         AND NL2, NL1, #18446744073709551614
; 8D0:       000002AA         ORR NL0, NL0, NL2
; 8D4:       051C7F92         AND NL5, NL0, #510
; 8D8:       E00303AA         MOV NL0, NL3
; 8DC:       800000CA         EOR NL0, NL4, NL0
; 8E0:       01D800B2         ORR NL1, NL0, #9187201950435737471
; 8E4:       00D80092         AND NL0, NL0, #9187201950435737471
; 8E8:       E2DB00B2         MOV NL2, #9187201950435737471
; 8EC:       0000028B         ADD NL0, NL0, NL2
; 8F0:       200000AA         ORR NL0, NL1, NL0
; 8F4:       01008092         MOVN NL1, #0
; 8F8:       000001CA         EOR NL0, NL0, NL1
; 8FC:       00C00192         AND NL0, NL0, #9259542123273814144
; 900:       00FC47D3         LSR NL0, NL0, #7
; 904:       E10300AA         MOV NL1, NL0
; 908:       21FC47D3         LSR NL1, NL1, #7
; 90C:       000001AA         ORR NL0, NL0, NL1
; 910:       00840092         AND NL0, NL0, #844437815230467
; 914:       E10300AA         MOV NL1, NL0
; 918:       21FC4ED3         LSR NL1, NL1, #14
; 91C:       000001AA         ORR NL0, NL0, NL1
; 920:       000C0092         AND NL0, NL0, #64424509455
; 924:       00F87FD3         LSL NL0, NL0, #1
; 928:       01FC5C93         ASR NL1, NL0, #28
; 92C:       22F87F92         AND NL2, NL1, #18446744073709551614
; 930:       000002AA         ORR NL0, NL0, NL2
; 934:       001C7F92         AND NL0, NL0, #510
; 938:       AA2000AA         ORR R0, NL5, NL0, LSL #8
; 93C:       FB031DAA         MOV CSP, CFP
; 940:       5F0300F1         CMP NULL, #0
; 944:       BD7B40A9         LDP CFP, LR, [CFP]
; 948:       C0035FD6         RET
; 94C: L4:   7D0300F9         STR CFP, [CSP]
; 950:       CAEFFF58         LDR R0, #x8005731748            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 954:       EBEFFF58         LDR R1, #x8005731750            ; :MOTIVO
; 958:       0CF0FF58         LDR R2, #x8005731758            ; :INVALID-WINDOW
; 95C:       29A680D2         MOVZ TMP, #1329
; 960:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 964:       D70080D2         MOVZ NARGS, #6
; 968:       FD031BAA         MOV CFP, CSP
; 96C:       C0033FD6         BLR LR
; 970:       E00120D4         BRK #15                         ; Invalid argument count trap
; 974: L5:   604421D4         BRK #2595                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R0
; 978:       04               BYTE #X04                       ; NL1
; 979:       .ALIGN           4
; 97C: L6:   604421D4         BRK #2595                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R0
; 980:       04               BYTE #X04                       ; NL1
; 981:       .ALIGN           4
")
    (:FUNCTION #A((35) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64") :TEXT
     "; disassembly for ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64
; Size: 172 bytes. Origin: #x8005731454                       ; ARCDOCDB.SPK08.IMPRONTE::SCALAR-U64
; 454:       040080D2         MOVZ NL4, #0
; 458:       030080D2         MOVZ NL3, #0
; 45C:       1C000014         B L3
; 460: L0:   E0018092         MOVN NL0, #15
; 464:       007C039B         MUL NL0, NL0, NL3
; 468:       02FC4193         ASR NL2, NL0, #1
; 46C:       E10302CB         NEG NL1, NL2
; 470:       A024C19A         LSR NL0, NL5, NL1
; 474:       00F87FD3         LSL NL0, NL0, #1
; 478:       00FC4193         ASR NL0, NL0, #1
; 47C:       001C7FD3         UBFIZ NL0, NL0, #1, #8
; 480:       1F000CEB         CMP NL0, R2
; 484:       20030054         BEQ L4
; 488: L1:   E0018092         MOVN NL0, #15
; 48C:       007C039B         MUL NL0, NL0, NL3
; 490:       02FC4193         ASR NL2, NL0, #1
; 494:       E10302CB         NEG NL1, NL2
; 498:       C024C19A         LSR NL0, NL6, NL1
; 49C:       00F87FD3         LSL NL0, NL0, #1
; 4A0:       00FC4193         ASR NL0, NL0, #1
; 4A4:       001C7FD3         UBFIZ NL0, NL0, #1, #8
; 4A8:       1F000CEB         CMP NL0, R2
; 4AC:       A1000054         BNE L2
; 4B0:       004080D2         MOVZ NL0, #512
; 4B4:       0020C39A         LSL NL0, NL0, NL3
; 4B8:       800000AA         ORR NL0, NL4, NL0
; 4BC:       E40300AA         MOV NL4, NL0
; 4C0: L2:   E00303AA         MOV NL0, NL3
; 4C4:       00040091         ADD NL0, NL0, #1
; 4C8:       E30300AA         MOV NL3, NL0
; 4CC: L3:   7F2000F1         CMP NL3, #8
; 4D0:       81FCFF54         BNE L0
; 4D4:       EA0304AA         MOV R0, NL4
; 4D8:       FB031DAA         MOV CSP, CFP
; 4DC:       5F0300F1         CMP NULL, #0
; 4E0:       BD7B40A9         LDP CFP, LR, [CFP]
; 4E4:       C0035FD6         RET
; 4E8: L4:   400080D2         MOVZ NL0, #2
; 4EC:       0020C39A         LSL NL0, NL0, NL3
; 4F0:       800000AA         ORR NL0, NL4, NL0
; 4F4:       E40300AA         MOV NL4, NL0
; 4F8:       E4FFFF17         B L1
; 4FC:       E00120D4         BRK #15                         ; Invalid argument count trap
")
    (:FUNCTION #A((33) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::TYPEDU64") :TEXT
     "; disassembly for ARCDOCDB.SPK08.IMPRONTE::TYPEDU64
; Size: 228 bytes. Origin: #x8005731624                       ; ARCDOCDB.SPK08.IMPRONTE::TYPEDU64
; 624:       81FD4193         ASR NL1, R2, #1
; 628:       E9C300B2         MOV TMP, #72340172838076673
; 62C:       237C099B         MUL NL3, NL1, TMP
; 630:       E10303AA         MOV NL1, NL3
; 634:       000001CA         EOR NL0, NL0, NL1
; 638:       01D800B2         ORR NL1, NL0, #9187201950435737471
; 63C:       00D80092         AND NL0, NL0, #9187201950435737471
; 640:       E2DB00B2         MOV NL2, #9187201950435737471
; 644:       0000028B         ADD NL0, NL0, NL2
; 648:       200000AA         ORR NL0, NL1, NL0
; 64C:       01008092         MOVN NL1, #0
; 650:       000001CA         EOR NL0, NL0, NL1
; 654:       00C00192         AND NL0, NL0, #9259542123273814144
; 658:       00FC47D3         LSR NL0, NL0, #7
; 65C:       E10300AA         MOV NL1, NL0
; 660:       21FC47D3         LSR NL1, NL1, #7
; 664:       000001AA         ORR NL0, NL0, NL1
; 668:       00840092         AND NL0, NL0, #844437815230467
; 66C:       E10300AA         MOV NL1, NL0
; 670:       21FC4ED3         LSR NL1, NL1, #14
; 674:       000001AA         ORR NL0, NL0, NL1
; 678:       000C0092         AND NL0, NL0, #64424509455
; 67C:       00F87FD3         LSL NL0, NL0, #1
; 680:       01FC5C93         ASR NL1, NL0, #28
; 684:       22F87F92         AND NL2, NL1, #18446744073709551614
; 688:       000002AA         ORR NL0, NL0, NL2
; 68C:       051C7F92         AND NL5, NL0, #510
; 690:       E10303AA         MOV NL1, NL3
; 694:       800001CA         EOR NL0, NL4, NL1
; 698:       01D800B2         ORR NL1, NL0, #9187201950435737471
; 69C:       00D80092         AND NL0, NL0, #9187201950435737471
; 6A0:       E2DB00B2         MOV NL2, #9187201950435737471
; 6A4:       0000028B         ADD NL0, NL0, NL2
; 6A8:       200000AA         ORR NL0, NL1, NL0
; 6AC:       01008092         MOVN NL1, #0
; 6B0:       000001CA         EOR NL0, NL0, NL1
; 6B4:       00C00192         AND NL0, NL0, #9259542123273814144
; 6B8:       00FC47D3         LSR NL0, NL0, #7
; 6BC:       E10300AA         MOV NL1, NL0
; 6C0:       21FC47D3         LSR NL1, NL1, #7
; 6C4:       000001AA         ORR NL0, NL0, NL1
; 6C8:       00840092         AND NL0, NL0, #844437815230467
; 6CC:       E10300AA         MOV NL1, NL0
; 6D0:       21FC4ED3         LSR NL1, NL1, #14
; 6D4:       000001AA         ORR NL0, NL0, NL1
; 6D8:       000C0092         AND NL0, NL0, #64424509455
; 6DC:       00F87FD3         LSL NL0, NL0, #1
; 6E0:       01FC5C93         ASR NL1, NL0, #28
; 6E4:       22F87F92         AND NL2, NL1, #18446744073709551614
; 6E8:       000002AA         ORR NL0, NL0, NL2
; 6EC:       001C7F92         AND NL0, NL0, #510
; 6F0:       AA2000AA         ORR R0, NL5, NL0, LSL #8
; 6F4:       FB031DAA         MOV CSP, CFP
; 6F8:       5F0300F1         CMP NULL, #0
; 6FC:       BD7B40A9         LDP CFP, LR, [CFP]
; 700:       C0035FD6         RET
; 704:       E00120D4         BRK #15                         ; Invalid argument count trap
")
    (:FUNCTION #A((39) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::CYCLE-SCALAR16")
     :TEXT "; disassembly for ARCDOCDB.SPK08.IMPRONTE::CYCLE-SCALAR16
; Size: 1144 bytes. Origin: #x8005735244                      ; ARCDOCDB.SPK08.IMPRONTE::CYCLE-SCALAR16
; 244:       AA0F40F9         LDR R0, [CFP, #24]
; 248:       4FD140F8         LDR R5, [R0, #13]
; 24C:       AF3700F9         STR R5, [CFP, #104]
; 250:       AA0F40F9         LDR R0, [CFP, #24]
; 254:       4B5141F8         LDR R1, [R0, #21]
; 258:       AB3B00F9         STR R1, [CFP, #112]
; 25C:       AA0F40F9         LDR R0, [CFP, #24]
; 260:       4DD141F8         LDR R3, [R0, #29]
; 264:       AD3F00F9         STR R3, [CFP, #120]
; 268:       AA0F40F9         LDR R0, [CFP, #24]
; 26C:       40D143F8         LDR NL0, [R0, #61]
; 270:       A02300F9         STR NL0, [CFP, #64]
; 274:       BF7F03A9         STP ZR, ZR, [CFP, #48]
; 278:       7D0300F9         STR CFP, [CSP]
; 27C:       B6F7FF58         LDR LEXENV, #x8005735170        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 280:       170080D2         MOVZ NARGS, #0
; 284:       DE9240F8         LDR LR, [LEXENV, #9]
; 288:       FD031BAA         MOV CFP, CSP
; 28C:       C0033FD6         BLR LR
; 290:       AB3747A9         LDP R1, R3, [CFP, #112]
; 294:       AF3740F9         LDR R5, [CFP, #104]
; 298:       A01740F9         LDR NL0, [CFP, #40]
; 29C:       5F0100EB         CMP R0, NL0
; 2A0:       AA1D0054         BGE L18
; 2A4:       AB3707A9         STP R1, R3, [CFP, #112]
; 2A8:       AF3700F9         STR R5, [CFP, #104]
; 2AC:       7D0300F9         STR CFP, [CSP]
; 2B0:       16F6FF58         LDR LEXENV, #x8005735170        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 2B4:       170080D2         MOVZ NARGS, #0
; 2B8:       DE9240F8         LDR LR, [LEXENV, #9]
; 2BC:       FD031BAA         MOV CFP, CSP
; 2C0:       C0033FD6         BLR LR
; 2C4:       AA2700F9         STR R0, [CFP, #72]
; 2C8:       7D0300F9         STR CFP, [CSP]
; 2CC:       76F5FF58         LDR LEXENV, #x8005735178        ; #<SB-KERNEL:FDEFN GET-BYTES-CONSED>
; 2D0:       170080D2         MOVZ NARGS, #0
; 2D4:       DE9240F8         LDR LR, [LEXENV, #9]
; 2D8:       FD031BAA         MOV CFP, CSP
; 2DC:       C0033FD6         BLR LR
; 2E0:       AFAF46A9         LDP R5, R1, [CFP, #104]
; 2E4:       AD3F40F9         LDR R3, [CFP, #120]
; 2E8:       AA2B00F9         STR R0, [CFP, #80]
; 2EC:       070080D2         MOVZ NL7, #0
; 2F0:       50000014         B L7
; 2F4: L0:   040080D2         MOVZ NL4, #0
; 2F8:       49000014         B L6
; 2FC: L1:   80FC4193         ASR NL0, NL4, #1
; 300:       01E87BD3         LSL NL1, NL0, #5
; 304:       60915FF8         LDR NL0, [R1, #-7]
; 308:       1F0004EB         CMP NL0, NL4
; 30C:       891B0054         BLS L19
; 310:       6905848B         ADD TMP, R1, NL4, ASR #1
; 314:       20054039         LDRB WNL0, [TMP, #1]
; 318:       2000008B         ADD NL0, NL1, NL0
; 31C:       01F87FD3         LSL NL1, NL0, #1
; 320:       A0915FF8         LDR NL0, [R3, #-7]
; 324:       1F0004EB         CMP NL0, NL4
; 328:       E91A0054         BLS L20
; 32C:       A905848B         ADD TMP, R3, NL4, ASR #1
; 330:       23054039         LDRB WNL3, [TMP, #1]
; 334:       E50303AA         MOV NL5, NL3
; 338:       7FE079F2         TST NL3, #18446744073709551488
; 33C:       81180054         BNE L17
; 340:       EA030FAA         MOV R0, R5
; 344:       E60301AA         MOV NL6, NL1
; 348:       E0915FF8         LDR NL0, [R5, #-7]
; 34C:       008000D1         SUB NL0, NL0, #32
; 350:       3F0000EB         CMP NL1, NL0
; 354:       AC160054         BGT L16
; 358:       010080D2         MOVZ NL1, #0
; 35C:       000080D2         MOVZ NL0, #0
; 360:       11000014         B L4
; 364: L2:   C2FC4193         ASR NL2, NL6, #1
; 368:       4204808B         ADD NL2, NL2, NL0, ASR #1
; 36C:       42F87FD3         LSL NL2, NL2, #1
; 370:       43915FF8         LDR NL3, [R0, #-7]
; 374:       7F0002EB         CMP NL3, NL2
; 378:       A9180054         BLS L21
; 37C:       4905828B         ADD TMP, R0, NL2, ASR #1
; 380:       22054039         LDRB WNL2, [TMP, #1]
; 384:       E30305AA         MOV NL3, NL5
; 388:       5F0003EB         CMP NL2, NL3
; 38C:       A1000054         BNE L3
; 390:       02FC4193         ASR NL2, NL0, #1
; 394:       430080D2         MOVZ NL3, #2
; 398:       6220C29A         LSL NL2, NL3, NL2
; 39C:       210002AA         ORR NL1, NL1, NL2
; 3A0: L3:   00080091         ADD NL0, NL0, #2
; 3A4: L4:   1F8000F1         CMP NL0, #32
; 3A8:       E1FDFF54         BNE L2
; 3AC:       A01B40F9         LDR NL0, [CFP, #48]
; 3B0:       200000AB         ADDS NL0, NL1, NL0
; 3B4:       06170054         BVS L22
; 3B8:       A01B00F9         STR NL0, [CFP, #48]
; 3BC:       A01F40F9         LDR NL0, [CFP, #56]
; 3C0:       000800B1         ADDS NL0, NL0, #2
; 3C4:       A6160054         BVS L23
; 3C8:       A01F00F9         STR NL0, [CFP, #56]
; 3CC:       A01F40F9         LDR NL0, [CFP, #56]
; 3D0:       1F2C7FF2         TST NL0, #8190
; 3D4:       01020054         BNE L5
; 3D8:       A49F05A9         STP NL4, NL7, [CFP, #88]
; 3DC:       AFAF06A9         STP R5, R1, [CFP, #104]
; 3E0:       AD3F00F9         STR R3, [CFP, #120]
; 3E4:       7D0300F9         STR CFP, [CSP]
; 3E8:       56ECFF58         LDR LEXENV, #x8005735170        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 3EC:       170080D2         MOVZ NARGS, #0
; 3F0:       DE9240F8         LDR LR, [LEXENV, #9]
; 3F4:       FD031BAA         MOV CFP, CSP
; 3F8:       C0033FD6         BLR LR
; 3FC:       AB3747A9         LDP R1, R3, [CFP, #112]
; 400:       A73F46A9         LDP NL7, R5, [CFP, #96]
; 404:       A42F40F9         LDR NL4, [CFP, #88]
; 408:       AC1740F9         LDR R2, [CFP, #40]
; 40C:       5F010CEB         CMP R0, R2
; 410:       AA0F0054         BGE L15
; 414: L5:   80080091         ADD NL0, NL4, #2
; 418:       E40300AA         MOV NL4, NL0
; 41C: L6:   A02340F9         LDR NL0, [CFP, #64]
; 420:       9F0000EB         CMP NL4, NL0
; 424:       CBF6FF54         BLT L1
; 428:       E0080091         ADD NL0, NL7, #2
; 42C:       E70300AA         MOV NL7, NL0
; 430: L7:   A01340F9         LDR NL0, [CFP, #32]
; 434:       FF0000EB         CMP NL7, NL0
; 438:       EBF5FF54         BLT L0
; 43C:       7D0300F9         STR CFP, [CSP]
; 440:       D6E9FF58         LDR LEXENV, #x8005735178        ; #<SB-KERNEL:FDEFN GET-BYTES-CONSED>
; 444:       170080D2         MOVZ NARGS, #0
; 448:       DE9240F8         LDR LR, [LEXENV, #9]
; 44C:       FD031BAA         MOV CFP, CSP
; 450:       C0033FD6         BLR LR
; 454:       EB030AAA         MOV R1, R0
; 458:       AB2F00F9         STR R1, [CFP, #88]
; 45C:       7D0300F9         STR CFP, [CSP]
; 460:       96E8FF58         LDR LEXENV, #x8005735170        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 464:       170080D2         MOVZ NARGS, #0
; 468:       DE9240F8         LDR LR, [LEXENV, #9]
; 46C:       FD031BAA         MOV CFP, CSP
; 470:       C0033FD6         BLR LR
; 474:       AB2F40F9         LDR R1, [CFP, #88]
; 478:       A02740F9         LDR NL0, [CFP, #72]
; 47C:       400100CB         SUB NL0, R0, NL0
; 480:       A02300F9         STR NL0, [CFP, #64]
; 484:       7D0300F9         STR CFP, [CSP]
; 488:       EA030BAA         MOV R0, R1
; 48C:       AB2B40F9         LDR R1, [CFP, #80]
; 490:       298280D2         MOVZ TMP, #1041
; 494:       5E6B69F8         LDR LR, [NULL, TMP]             ; SB-KERNEL:TWO-ARG--
; 498:       FD031BAA         MOV CFP, CSP
; 49C:       C0033FD6         BLR LR
; 4A0:       EB030AAA         MOV R1, R0
; 4A4:       AB2700F9         STR R1, [CFP, #72]
; 4A8:       7D0300F9         STR CFP, [CSP]
; 4AC:       36E6FF58         LDR LEXENV, #x8005735170        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 4B0:       170080D2         MOVZ NARGS, #0
; 4B4:       DE9240F8         LDR LR, [LEXENV, #9]
; 4B8:       FD031BAA         MOV CFP, CSP
; 4BC:       C0033FD6         BLR LR
; 4C0:       AB2740F9         LDR R1, [CFP, #72]
; 4C4:       AC1740F9         LDR R2, [CFP, #40]
; 4C8:       5F010CEB         CMP R0, R2
; 4CC:       AA080054         BGE L14
; 4D0:       AA0F40F9         LDR R0, [CFP, #24]
; 4D4:       405144F8         LDR NL0, [R0, #69]
; 4D8:       A11340F9         LDR NL1, [CFP, #32]
; 4DC:       21FC4193         ASR NL1, NL1, #1
; 4E0:       00FC4193         ASR NL0, NL0, #1
; 4E4:       237C409B         SMULH NL3, NL1, NL0
; 4E8:       227C009B         MUL NL2, NL1, NL0
; 4EC:       214280D2         MOVZ NL1, #529
; 4F0:       7FFC82EB         CMP NL3, NL2, ASR #63
; 4F4:       81000054         BNE L8
; 4F8:       4A0002AB         ADDS R0, NL2, NL2
; 4FC:       E7010054         BVC L10
; 500:       212280D2         MOVZ NL1, #273
; 504: L8:   BA2A00B9         STR WNULL, [THREAD, #40]        ; pseudo-atomic-bits
; 508:       A97A47A9         LDP TMP, LR, [THREAD, #112]     ; mixed-tlab.{free-pointer, end-addr}
; 50C:       2A810091         ADD R0, TMP, #32
; 510:       5F011EEB         CMP R0, LR
; 514:       480C0054         BHI L24
; 518:       AA3A00F9         STR R0, [THREAD, #112]          ; mixed-tlab
; 51C: L9:   2A3D0091         ADD R0, TMP, #15
; 520:       210900A9         STP NL1, NL2, [TMP]
; 524:       230900F9         STR NL3, [TMP, #16]
; 528:       BF2A00B9         STR WZR, [THREAD, #40]          ; pseudo-atomic-bits
; 52C:       BE2E40B9         LDR WLR, [THREAD, #44]          ; pseudo-atomic-bits
; 530:       5E0000B4         CBZ LR, L10
; 534:       200120D4         BRK #9                          ; Pending interrupt trap
; 538: L10:  A01B40F9         LDR NL0, [CFP, #48]
; 53C:       5F0100EB         CMP R0, NL0
; 540:       21010054         BNE L11
; 544:       AA2340F9         LDR R0, [CFP, #64]
; 548:       AC3743A9         LDP R2, R3, [CFP, #48]
; 54C:       F9031DAA         MOV OCFP, CFP
; 550:       3B830091         ADD CSP, OCFP, #32
; 554:       170180D2         MOVZ NARGS, #8
; 558:       FF031FEB         CMP ZR, ZR
; 55C:       BD7B40A9         LDP CFP, LR, [CFP]
; 560:       C0035FD6         RET
; 564: L11:  A01B40F9         LDR NL0, [CFP, #48]
; 568:       BA2A00B9         STR WNULL, [THREAD, #40]        ; pseudo-atomic-bits
; 56C:       A9FA45A9         LDP TMP, LR, [THREAD, #88]      ; cons-tlab.{free-pointer, end-addr}
; 570:       2CC10091         ADD R2, TMP, #48
; 574:       9F011EEB         CMP R2, LR
; 578:       A8090054         BHI L25
; 57C:       AC2E00F9         STR R2, [THREAD, #88]           ; cons-tlab
; 580: L12:  2C1D0091         ADD R2, TMP, #7
; 584:       EE030CAA         MOV R4, R2
; 588:       0FE0FF58         LDR R5, #x8005735188            ; :CYCLE-CHECKSUM
; 58C:       CF911FF8         STR R5, [R4, #-7]
; 590:       CE410091         ADD R4, R4, #16
; 594:       CE111FF8         STR R4, [R4, #-15]
; 598:       CFDFFF58         LDR R5, #x8005735190            ; 'ARCDOCDB.SPK08.IMPRONTE::CYCLE-SCALAR16
; 59C:       CF911FF8         STR R5, [R4, #-7]
; 5A0:       CE410091         ADD R4, R4, #16
; 5A4:       CE111FF8         STR R4, [R4, #-15]
; 5A8:       C0911FF8         STR NL0, [R4, #-7]
; 5AC:       DA1100F8         STR NULL, [R4, #1]
; 5B0:       BF2A00B9         STR WZR, [THREAD, #40]          ; pseudo-atomic-bits
; 5B4:       BE2E40B9         LDR WLR, [THREAD, #44]          ; pseudo-atomic-bits
; 5B8:       5E0000B4         CBZ LR, L13
; 5BC:       200120D4         BRK #9                          ; Pending interrupt trap
; 5C0: L13:  7D0300F9         STR CFP, [CSP]
; 5C4:       AADEFF58         LDR R0, #x8005735198            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 5C8:       CBDEFF58         LDR R1, #x80057351A0            ; :MOTIVO
; 5CC:       29A680D2         MOVZ TMP, #1329
; 5D0:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 5D4:       D70080D2         MOVZ NARGS, #6
; 5D8:       FD031BAA         MOV CFP, CSP
; 5DC:       C0033FD6         BLR LR
; 5E0: L14:  7D0300F9         STR CFP, [CSP]
; 5E4:       AADDFF58         LDR R0, #x8005735198            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 5E8:       CBDDFF58         LDR R1, #x80057351A0            ; :MOTIVO
; 5EC:       ECDDFF58         LDR R2, #x80057351A8            ; :TIME-BUDGET
; 5F0:       29A680D2         MOVZ TMP, #1329
; 5F4:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 5F8:       D70080D2         MOVZ NARGS, #6
; 5FC:       FD031BAA         MOV CFP, CSP
; 600:       C0033FD6         BLR LR
; 604: L15:  7D0300F9         STR CFP, [CSP]
; 608:       8ADCFF58         LDR R0, #x8005735198            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 60C:       ABDCFF58         LDR R1, #x80057351A0            ; :MOTIVO
; 610:       CCDCFF58         LDR R2, #x80057351A8            ; :TIME-BUDGET
; 614:       29A680D2         MOVZ TMP, #1329
; 618:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 61C:       D70080D2         MOVZ NARGS, #6
; 620:       FD031BAA         MOV CFP, CSP
; 624:       C0033FD6         BLR LR
; 628: L16:  7D0300F9         STR CFP, [CSP]
; 62C:       6ADBFF58         LDR R0, #x8005735198            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 630:       8BDBFF58         LDR R1, #x80057351A0            ; :MOTIVO
; 634:       ECDBFF58         LDR R2, #x80057351B0            ; :INVALID-WINDOW
; 638:       29A680D2         MOVZ TMP, #1329
; 63C:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 640:       D70080D2         MOVZ NARGS, #6
; 644:       FD031BAA         MOV CFP, CSP
; 648:       C0033FD6         BLR LR
; 64C: L17:  806328D4         BRK #17180                      ; OBJECT-NOT-TYPE-ERROR
                                                              ; NL3
; 650:       37               BYTE #X37                       ; '(UNSIGNED-BYTE 7)
; 651:       .ALIGN           4
; 654: L18:  7D0300F9         STR CFP, [CSP]
; 658:       0ADAFF58         LDR R0, #x8005735198            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 65C:       2BDAFF58         LDR R1, #x80057351A0            ; :MOTIVO
; 660:       4CDAFF58         LDR R2, #x80057351A8            ; :TIME-BUDGET
; 664:       29A680D2         MOVZ TMP, #1329
; 668:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 66C:       D70080D2         MOVZ NARGS, #6
; 670:       FD031BAA         MOV CFP, CSP
; 674:       C0033FD6         BLR LR
; 678:       E00120D4         BRK #15                         ; Invalid argument count trap
; 67C: L19:  606421D4         BRK #2851                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R1
; 680:       10               BYTE #X10                       ; NL4
; 681:       .ALIGN           4
; 684: L20:  60A421D4         BRK #3363                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R3
; 688:       10               BYTE #X10                       ; NL4
; 689:       .ALIGN           4
; 68C: L21:  604421D4         BRK #2595                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R0
; 690:       08               BYTE #X08                       ; NL2
; 691:       .ALIGN           4
; 694: L22:  A00520D4         BRK #45                         ; ADD-SUB-OVERFLOW-ERROR
                                                              ; NL0
; 698: L23:  A00520D4         BRK #45                         ; ADD-SUB-OVERFLOW-ERROR
                                                              ; NL0
; 69C: L24:  090480D2         MOVZ TMP, #32
; 6A0:       4AD9FF58         LDR R0, #x80057351C8            ; SB-VM::ALLOC-TRAMP
; 6A4:       40013FD6         BLR R0
; 6A8:       9DFFFF17         B L9
; 6AC: L25:  090680D2         MOVZ TMP, #48
; 6B0:       0CD9FF58         LDR R2, #x80057351D0            ; SB-VM::LIST-ALLOC-TRAMP
; 6B4:       80013FD6         BLR R2
; 6B8:       B2FFFF17         B L12
")
    (:FUNCTION
     #A((43) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::CYCLE-PACKEDMASK16") :TEXT
     "; disassembly for ARCDOCDB.SPK08.IMPRONTE::CYCLE-PACKEDMASK16
; Size: 1412 bytes. Origin: #x80057357D4                      ; ARCDOCDB.SPK08.IMPRONTE::CYCLE-PACKEDMASK16
; 7D4:       AA0F40F9         LDR R0, [CFP, #24]
; 7D8:       4FD140F8         LDR R5, [R0, #13]
; 7DC:       AF3700F9         STR R5, [CFP, #104]
; 7E0:       AA0F40F9         LDR R0, [CFP, #24]
; 7E4:       4B5141F8         LDR R1, [R0, #21]
; 7E8:       AB3B00F9         STR R1, [CFP, #112]
; 7EC:       AA0F40F9         LDR R0, [CFP, #24]
; 7F0:       4DD141F8         LDR R3, [R0, #29]
; 7F4:       AD3F00F9         STR R3, [CFP, #120]
; 7F8:       AA0F40F9         LDR R0, [CFP, #24]
; 7FC:       40D143F8         LDR NL0, [R0, #61]
; 800:       A02300F9         STR NL0, [CFP, #64]
; 804:       BF7F03A9         STP ZR, ZR, [CFP, #48]
; 808:       7D0300F9         STR CFP, [CSP]
; 80C:       36F7FF58         LDR LEXENV, #x80057356F0        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 810:       170080D2         MOVZ NARGS, #0
; 814:       DE9240F8         LDR LR, [LEXENV, #9]
; 818:       FD031BAA         MOV CFP, CSP
; 81C:       C0033FD6         BLR LR
; 820:       AB3747A9         LDP R1, R3, [CFP, #112]
; 824:       AF3740F9         LDR R5, [CFP, #104]
; 828:       A01740F9         LDR NL0, [CFP, #40]
; 82C:       5F0100EB         CMP R0, NL0
; 830:       CA250054         BGE L19
; 834:       AB3707A9         STP R1, R3, [CFP, #112]
; 838:       AF3700F9         STR R5, [CFP, #104]
; 83C:       7D0300F9         STR CFP, [CSP]
; 840:       96F5FF58         LDR LEXENV, #x80057356F0        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 844:       170080D2         MOVZ NARGS, #0
; 848:       DE9240F8         LDR LR, [LEXENV, #9]
; 84C:       FD031BAA         MOV CFP, CSP
; 850:       C0033FD6         BLR LR
; 854:       AA2700F9         STR R0, [CFP, #72]
; 858:       7D0300F9         STR CFP, [CSP]
; 85C:       F6F4FF58         LDR LEXENV, #x80057356F8        ; #<SB-KERNEL:FDEFN GET-BYTES-CONSED>
; 860:       170080D2         MOVZ NARGS, #0
; 864:       DE9240F8         LDR LR, [LEXENV, #9]
; 868:       FD031BAA         MOV CFP, CSP
; 86C:       C0033FD6         BLR LR
; 870:       AFAF46A9         LDP R5, R1, [CFP, #104]
; 874:       AD3F40F9         LDR R3, [CFP, #120]
; 878:       AA2B00F9         STR R0, [CFP, #80]
; 87C:       080080D2         MOVZ NL8, #0
; 880:       91000014         B L8
; 884: L0:   040080D2         MOVZ NL4, #0
; 888:       8A000014         B L7
; 88C: L1:   80FC4193         ASR NL0, NL4, #1
; 890:       01E87BD3         LSL NL1, NL0, #5
; 894:       60915FF8         LDR NL0, [R1, #-7]
; 898:       1F0004EB         CMP NL0, NL4
; 89C:       A9230054         BLS L20
; 8A0:       6905848B         ADD TMP, R1, NL4, ASR #1
; 8A4:       20054039         LDRB WNL0, [TMP, #1]
; 8A8:       2000008B         ADD NL0, NL1, NL0
; 8AC:       01F87FD3         LSL NL1, NL0, #1
; 8B0:       A0915FF8         LDR NL0, [R3, #-7]
; 8B4:       1F0004EB         CMP NL0, NL4
; 8B8:       09230054         BLS L21
; 8BC:       A905848B         ADD TMP, R3, NL4, ASR #1
; 8C0:       20054039         LDRB WNL0, [TMP, #1]
; 8C4:       E60300AA         MOV NL6, NL0
; 8C8:       1FE079F2         TST NL0, #18446744073709551488
; 8CC:       A1200054         BNE L18
; 8D0:       EA030FAA         MOV R0, R5
; 8D4:       E50301AA         MOV NL5, NL1
; 8D8:       E0915FF8         LDR NL0, [R5, #-7]
; 8DC:       008000D1         SUB NL0, NL0, #32
; 8E0:       3F0000EB         CMP NL1, NL0
; 8E4:       CC1E0054         BGT L17
; 8E8:       070080D2         MOVZ NL7, #0
; 8EC:       000080D2         MOVZ NL0, #0
; 8F0:       0D000014         B L3
; 8F4: L2:   A100008B         ADD NL1, NL5, NL0
; 8F8:       42915FF8         LDR NL2, [R0, #-7]
; 8FC:       5F0001EB         CMP NL2, NL1
; 900:       09210054         BLS L22
; 904:       4905818B         ADD TMP, R0, NL1, ASR #1
; 908:       22054039         LDRB WNL2, [TMP, #1]
; 90C:       01FC4193         ASR NL1, NL0, #1
; 910:       21F07DD3         LSL NL1, NL1, #3
; 914:       4120C19A         LSL NL1, NL2, NL1
; 918:       E10001AA         ORR NL1, NL7, NL1
; 91C:       E70301AA         MOV NL7, NL1
; 920:       00080091         ADD NL0, NL0, #2
; 924: L3:   1F4000F1         CMP NL0, #16
; 928:       61FEFF54         BNE L2
; 92C:       A3400091         ADD NL3, NL5, #16
; 930:       050080D2         MOVZ NL5, #0
; 934:       000080D2         MOVZ NL0, #0
; 938:       0D000014         B L5
; 93C: L4:   6100008B         ADD NL1, NL3, NL0
; 940:       42915FF8         LDR NL2, [R0, #-7]
; 944:       5F0001EB         CMP NL2, NL1
; 948:       091F0054         BLS L23
; 94C:       4905818B         ADD TMP, R0, NL1, ASR #1
; 950:       21054039         LDRB WNL1, [TMP, #1]
; 954:       02FC4193         ASR NL2, NL0, #1
; 958:       42F07DD3         LSL NL2, NL2, #3
; 95C:       2120C29A         LSL NL1, NL1, NL2
; 960:       A10001AA         ORR NL1, NL5, NL1
; 964:       E50301AA         MOV NL5, NL1
; 968:       00080091         ADD NL0, NL0, #2
; 96C: L5:   1F4000F1         CMP NL0, #16
; 970:       61FEFF54         BNE L4
; 974:       E9C300B2         MOV TMP, #72340172838076673
; 978:       C37C099B         MUL NL3, NL6, TMP
; 97C:       E00303AA         MOV NL0, NL3
; 980:       E00000CA         EOR NL0, NL7, NL0
; 984:       02D800B2         ORR NL2, NL0, #9187201950435737471
; 988:       00D80092         AND NL0, NL0, #9187201950435737471
; 98C:       E1DB00B2         MOV NL1, #9187201950435737471
; 990:       0000018B         ADD NL0, NL0, NL1
; 994:       400000AA         ORR NL0, NL2, NL0
; 998:       01008092         MOVN NL1, #0
; 99C:       000001CA         EOR NL0, NL0, NL1
; 9A0:       00C00192         AND NL0, NL0, #9259542123273814144
; 9A4:       00FC47D3         LSR NL0, NL0, #7
; 9A8:       E10300AA         MOV NL1, NL0
; 9AC:       21FC47D3         LSR NL1, NL1, #7
; 9B0:       000001AA         ORR NL0, NL0, NL1
; 9B4:       00840092         AND NL0, NL0, #844437815230467
; 9B8:       E10300AA         MOV NL1, NL0
; 9BC:       21FC4ED3         LSR NL1, NL1, #14
; 9C0:       000001AA         ORR NL0, NL0, NL1
; 9C4:       000C0092         AND NL0, NL0, #64424509455
; 9C8:       00F87FD3         LSL NL0, NL0, #1
; 9CC:       01FC5C93         ASR NL1, NL0, #28
; 9D0:       22F87F92         AND NL2, NL1, #18446744073709551614
; 9D4:       000002AA         ORR NL0, NL0, NL2
; 9D8:       061C7F92         AND NL6, NL0, #510
; 9DC:       E00303AA         MOV NL0, NL3
; 9E0:       A00000CA         EOR NL0, NL5, NL0
; 9E4:       01D800B2         ORR NL1, NL0, #9187201950435737471
; 9E8:       00D80092         AND NL0, NL0, #9187201950435737471
; 9EC:       E2DB00B2         MOV NL2, #9187201950435737471
; 9F0:       0000028B         ADD NL0, NL0, NL2
; 9F4:       200000AA         ORR NL0, NL1, NL0
; 9F8:       01008092         MOVN NL1, #0
; 9FC:       000001CA         EOR NL0, NL0, NL1
; A00:       00C00192         AND NL0, NL0, #9259542123273814144
; A04:       00FC47D3         LSR NL0, NL0, #7
; A08:       E10300AA         MOV NL1, NL0
; A0C:       21FC47D3         LSR NL1, NL1, #7
; A10:       000001AA         ORR NL0, NL0, NL1
; A14:       00840092         AND NL0, NL0, #844437815230467
; A18:       E10300AA         MOV NL1, NL0
; A1C:       21FC4ED3         LSR NL1, NL1, #14
; A20:       000001AA         ORR NL0, NL0, NL1
; A24:       000C0092         AND NL0, NL0, #64424509455
; A28:       00F87FD3         LSL NL0, NL0, #1
; A2C:       01FC5C93         ASR NL1, NL0, #28
; A30:       22F87F92         AND NL2, NL1, #18446744073709551614
; A34:       000002AA         ORR NL0, NL0, NL2
; A38:       001C7F92         AND NL0, NL0, #510
; A3C:       C02000AA         ORR NL0, NL6, NL0, LSL #8
; A40:       A11B40F9         LDR NL1, [CFP, #48]
; A44:       000001AB         ADDS NL0, NL0, NL1
; A48:       46170054         BVS L24
; A4C:       A01B00F9         STR NL0, [CFP, #48]
; A50:       A01F40F9         LDR NL0, [CFP, #56]
; A54:       000800B1         ADDS NL0, NL0, #2
; A58:       E6160054         BVS L25
; A5C:       A01F00F9         STR NL0, [CFP, #56]
; A60:       A01F40F9         LDR NL0, [CFP, #56]
; A64:       1F2C7FF2         TST NL0, #8190
; A68:       01020054         BNE L6
; A6C:       A4A305A9         STP NL4, NL8, [CFP, #88]
; A70:       AFAF06A9         STP R5, R1, [CFP, #104]
; A74:       AD3F00F9         STR R3, [CFP, #120]
; A78:       7D0300F9         STR CFP, [CSP]
; A7C:       B6E3FF58         LDR LEXENV, #x80057356F0        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; A80:       170080D2         MOVZ NARGS, #0
; A84:       DE9240F8         LDR LR, [LEXENV, #9]
; A88:       FD031BAA         MOV CFP, CSP
; A8C:       C0033FD6         BLR LR
; A90:       AB3747A9         LDP R1, R3, [CFP, #112]
; A94:       A83F46A9         LDP NL8, R5, [CFP, #96]
; A98:       A42F40F9         LDR NL4, [CFP, #88]
; A9C:       AC1740F9         LDR R2, [CFP, #40]
; AA0:       5F010CEB         CMP R0, R2
; AA4:       AA0F0054         BGE L16
; AA8: L6:   80080091         ADD NL0, NL4, #2
; AAC:       E40300AA         MOV NL4, NL0
; AB0: L7:   A02340F9         LDR NL0, [CFP, #64]
; AB4:       9F0000EB         CMP NL4, NL0
; AB8:       ABEEFF54         BLT L1
; ABC:       00090091         ADD NL0, NL8, #2
; AC0:       E80300AA         MOV NL8, NL0
; AC4: L8:   A01340F9         LDR NL0, [CFP, #32]
; AC8:       1F0100EB         CMP NL8, NL0
; ACC:       CBEDFF54         BLT L0
; AD0:       7D0300F9         STR CFP, [CSP]
; AD4:       36E1FF58         LDR LEXENV, #x80057356F8        ; #<SB-KERNEL:FDEFN GET-BYTES-CONSED>
; AD8:       170080D2         MOVZ NARGS, #0
; ADC:       DE9240F8         LDR LR, [LEXENV, #9]
; AE0:       FD031BAA         MOV CFP, CSP
; AE4:       C0033FD6         BLR LR
; AE8:       EB030AAA         MOV R1, R0
; AEC:       AB2F00F9         STR R1, [CFP, #88]
; AF0:       7D0300F9         STR CFP, [CSP]
; AF4:       F6DFFF58         LDR LEXENV, #x80057356F0        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; AF8:       170080D2         MOVZ NARGS, #0
; AFC:       DE9240F8         LDR LR, [LEXENV, #9]
; B00:       FD031BAA         MOV CFP, CSP
; B04:       C0033FD6         BLR LR
; B08:       AB2F40F9         LDR R1, [CFP, #88]
; B0C:       A02740F9         LDR NL0, [CFP, #72]
; B10:       400100CB         SUB NL0, R0, NL0
; B14:       A02300F9         STR NL0, [CFP, #64]
; B18:       7D0300F9         STR CFP, [CSP]
; B1C:       EA030BAA         MOV R0, R1
; B20:       AB2B40F9         LDR R1, [CFP, #80]
; B24:       298280D2         MOVZ TMP, #1041
; B28:       5E6B69F8         LDR LR, [NULL, TMP]             ; SB-KERNEL:TWO-ARG--
; B2C:       FD031BAA         MOV CFP, CSP
; B30:       C0033FD6         BLR LR
; B34:       EB030AAA         MOV R1, R0
; B38:       AB2700F9         STR R1, [CFP, #72]
; B3C:       7D0300F9         STR CFP, [CSP]
; B40:       96DDFF58         LDR LEXENV, #x80057356F0        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; B44:       170080D2         MOVZ NARGS, #0
; B48:       DE9240F8         LDR LR, [LEXENV, #9]
; B4C:       FD031BAA         MOV CFP, CSP
; B50:       C0033FD6         BLR LR
; B54:       AB2740F9         LDR R1, [CFP, #72]
; B58:       AC1740F9         LDR R2, [CFP, #40]
; B5C:       5F010CEB         CMP R0, R2
; B60:       AA080054         BGE L15
; B64:       AA0F40F9         LDR R0, [CFP, #24]
; B68:       405144F8         LDR NL0, [R0, #69]
; B6C:       A11340F9         LDR NL1, [CFP, #32]
; B70:       21FC4193         ASR NL1, NL1, #1
; B74:       00FC4193         ASR NL0, NL0, #1
; B78:       237C409B         SMULH NL3, NL1, NL0
; B7C:       227C009B         MUL NL2, NL1, NL0
; B80:       214280D2         MOVZ NL1, #529
; B84:       7FFC82EB         CMP NL3, NL2, ASR #63
; B88:       81000054         BNE L9
; B8C:       4A0002AB         ADDS R0, NL2, NL2
; B90:       E7010054         BVC L11
; B94:       212280D2         MOVZ NL1, #273
; B98: L9:   BA2A00B9         STR WNULL, [THREAD, #40]        ; pseudo-atomic-bits
; B9C:       A97A47A9         LDP TMP, LR, [THREAD, #112]     ; mixed-tlab.{free-pointer, end-addr}
; BA0:       2A810091         ADD R0, TMP, #32
; BA4:       5F011EEB         CMP R0, LR
; BA8:       880C0054         BHI L26
; BAC:       AA3A00F9         STR R0, [THREAD, #112]          ; mixed-tlab
; BB0: L10:  2A3D0091         ADD R0, TMP, #15
; BB4:       210900A9         STP NL1, NL2, [TMP]
; BB8:       230900F9         STR NL3, [TMP, #16]
; BBC:       BF2A00B9         STR WZR, [THREAD, #40]          ; pseudo-atomic-bits
; BC0:       BE2E40B9         LDR WLR, [THREAD, #44]          ; pseudo-atomic-bits
; BC4:       5E0000B4         CBZ LR, L11
; BC8:       200120D4         BRK #9                          ; Pending interrupt trap
; BCC: L11:  A01B40F9         LDR NL0, [CFP, #48]
; BD0:       5F0100EB         CMP R0, NL0
; BD4:       21010054         BNE L12
; BD8:       AA2340F9         LDR R0, [CFP, #64]
; BDC:       AC3743A9         LDP R2, R3, [CFP, #48]
; BE0:       F9031DAA         MOV OCFP, CFP
; BE4:       3B830091         ADD CSP, OCFP, #32
; BE8:       170180D2         MOVZ NARGS, #8
; BEC:       FF031FEB         CMP ZR, ZR
; BF0:       BD7B40A9         LDP CFP, LR, [CFP]
; BF4:       C0035FD6         RET
; BF8: L12:  A01B40F9         LDR NL0, [CFP, #48]
; BFC:       BA2A00B9         STR WNULL, [THREAD, #40]        ; pseudo-atomic-bits
; C00:       A9FA45A9         LDP TMP, LR, [THREAD, #88]      ; cons-tlab.{free-pointer, end-addr}
; C04:       2CC10091         ADD R2, TMP, #48
; C08:       9F011EEB         CMP R2, LR
; C0C:       E8090054         BHI L27
; C10:       AC2E00F9         STR R2, [THREAD, #88]           ; cons-tlab
; C14: L13:  2C1D0091         ADD R2, TMP, #7
; C18:       EE030CAA         MOV R4, R2
; C1C:       EFD7FF58         LDR R5, #x8005735718            ; :CYCLE-CHECKSUM
; C20:       CF911FF8         STR R5, [R4, #-7]
; C24:       CE410091         ADD R4, R4, #16
; C28:       CE111FF8         STR R4, [R4, #-15]
; C2C:       AFD7FF58         LDR R5, #x8005735720            ; 'ARCDOCDB.SPK08.IMPRONTE::CYCLE-PACKEDMASK16
; C30:       CF911FF8         STR R5, [R4, #-7]
; C34:       CE410091         ADD R4, R4, #16
; C38:       CE111FF8         STR R4, [R4, #-15]
; C3C:       C0911FF8         STR NL0, [R4, #-7]
; C40:       DA1100F8         STR NULL, [R4, #1]
; C44:       BF2A00B9         STR WZR, [THREAD, #40]          ; pseudo-atomic-bits
; C48:       BE2E40B9         LDR WLR, [THREAD, #44]          ; pseudo-atomic-bits
; C4C:       5E0000B4         CBZ LR, L14
; C50:       200120D4         BRK #9                          ; Pending interrupt trap
; C54: L14:  7D0300F9         STR CFP, [CSP]
; C58:       8AD6FF58         LDR R0, #x8005735728            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; C5C:       ABD6FF58         LDR R1, #x8005735730            ; :MOTIVO
; C60:       29A680D2         MOVZ TMP, #1329
; C64:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; C68:       D70080D2         MOVZ NARGS, #6
; C6C:       FD031BAA         MOV CFP, CSP
; C70:       C0033FD6         BLR LR
; C74: L15:  7D0300F9         STR CFP, [CSP]
; C78:       8AD5FF58         LDR R0, #x8005735728            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; C7C:       ABD5FF58         LDR R1, #x8005735730            ; :MOTIVO
; C80:       CCD5FF58         LDR R2, #x8005735738            ; :TIME-BUDGET
; C84:       29A680D2         MOVZ TMP, #1329
; C88:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; C8C:       D70080D2         MOVZ NARGS, #6
; C90:       FD031BAA         MOV CFP, CSP
; C94:       C0033FD6         BLR LR
; C98: L16:  7D0300F9         STR CFP, [CSP]
; C9C:       6AD4FF58         LDR R0, #x8005735728            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; CA0:       8BD4FF58         LDR R1, #x8005735730            ; :MOTIVO
; CA4:       ACD4FF58         LDR R2, #x8005735738            ; :TIME-BUDGET
; CA8:       29A680D2         MOVZ TMP, #1329
; CAC:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; CB0:       D70080D2         MOVZ NARGS, #6
; CB4:       FD031BAA         MOV CFP, CSP
; CB8:       C0033FD6         BLR LR
; CBC: L17:  7D0300F9         STR CFP, [CSP]
; CC0:       4AD3FF58         LDR R0, #x8005735728            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; CC4:       6BD3FF58         LDR R1, #x8005735730            ; :MOTIVO
; CC8:       CCD3FF58         LDR R2, #x8005735740            ; :INVALID-WINDOW
; CCC:       29A680D2         MOVZ TMP, #1329
; CD0:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; CD4:       D70080D2         MOVZ NARGS, #6
; CD8:       FD031BAA         MOV CFP, CSP
; CDC:       C0033FD6         BLR LR
; CE0: L18:  800328D4         BRK #16412                      ; OBJECT-NOT-TYPE-ERROR
                                                              ; NL0
; CE4:       3F               BYTE #X3F                       ; '(UNSIGNED-BYTE 7)
; CE5:       .ALIGN           4
; CE8: L19:  7D0300F9         STR CFP, [CSP]
; CEC:       EAD1FF58         LDR R0, #x8005735728            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; CF0:       0BD2FF58         LDR R1, #x8005735730            ; :MOTIVO
; CF4:       2CD2FF58         LDR R2, #x8005735738            ; :TIME-BUDGET
; CF8:       29A680D2         MOVZ TMP, #1329
; CFC:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; D00:       D70080D2         MOVZ NARGS, #6
; D04:       FD031BAA         MOV CFP, CSP
; D08:       C0033FD6         BLR LR
; D0C:       E00120D4         BRK #15                         ; Invalid argument count trap
; D10: L20:  606421D4         BRK #2851                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R1
; D14:       10               BYTE #X10                       ; NL4
; D15:       .ALIGN           4
; D18: L21:  60A421D4         BRK #3363                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R3
; D1C:       10               BYTE #X10                       ; NL4
; D1D:       .ALIGN           4
; D20: L22:  604421D4         BRK #2595                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R0
; D24:       04               BYTE #X04                       ; NL1
; D25:       .ALIGN           4
; D28: L23:  604421D4         BRK #2595                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R0
; D2C:       04               BYTE #X04                       ; NL1
; D2D:       .ALIGN           4
; D30: L24:  A00520D4         BRK #45                         ; ADD-SUB-OVERFLOW-ERROR
                                                              ; NL0
; D34: L25:  A00520D4         BRK #45                         ; ADD-SUB-OVERFLOW-ERROR
                                                              ; NL0
; D38: L26:  090480D2         MOVZ TMP, #32
; D3C:       EAD0FF58         LDR R0, #x8005735758            ; SB-VM::ALLOC-TRAMP
; D40:       40013FD6         BLR R0
; D44:       9BFFFF17         B L10
; D48: L27:  090680D2         MOVZ TMP, #48
; D4C:       ACD0FF58         LDR R2, #x8005735760            ; SB-VM::LIST-ALLOC-TRAMP
; D50:       80013FD6         BLR R2
; D54:       B0FFFF17         B L13
")
    (:FUNCTION #A((41) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::CYCLE-SCALAR-U64")
     :TEXT "; disassembly for ARCDOCDB.SPK08.IMPRONTE::CYCLE-SCALAR-U64
; Size: 1156 bytes. Origin: #x8005735E54                      ; ARCDOCDB.SPK08.IMPRONTE::CYCLE-SCALAR-U64
; 5E54:       AA0F40F9         LDR R0, [CFP, #24]
; 5E58:       4FD141F8         LDR R5, [R0, #29]
; 5E5C:       AF3F00F9         STR R5, [CFP, #120]
; 5E60:       AA0F40F9         LDR R0, [CFP, #24]
; 5E64:       4B5142F8         LDR R1, [R0, #37]
; 5E68:       AB3700F9         STR R1, [CFP, #104]
; 5E6C:       AA0F40F9         LDR R0, [CFP, #24]
; 5E70:       4DD142F8         LDR R3, [R0, #45]
; 5E74:       AD3B00F9         STR R3, [CFP, #112]
; 5E78:       AA0F40F9         LDR R0, [CFP, #24]
; 5E7C:       40D143F8         LDR NL0, [R0, #61]
; 5E80:       A02300F9         STR NL0, [CFP, #64]
; 5E84:       BF7F03A9         STP ZR, ZR, [CFP, #48]
; 5E88:       7D0300F9         STR CFP, [CSP]
; 5E8C:       B6F7FF58         LDR LEXENV, #x8005735D80       ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 5E90:       170080D2         MOVZ NARGS, #0
; 5E94:       DE9240F8         LDR LR, [LEXENV, #9]
; 5E98:       FD031BAA         MOV CFP, CSP
; 5E9C:       C0033FD6         BLR LR
; 5EA0:       ABB746A9         LDP R1, R3, [CFP, #104]
; 5EA4:       AF3F40F9         LDR R5, [CFP, #120]
; 5EA8:       A01740F9         LDR NL0, [CFP, #40]
; 5EAC:       5F0100EB         CMP R0, NL0
; 5EB0:       0A1E0054         BGE L19
; 5EB4:       AD3F07A9         STP R3, R5, [CFP, #112]
; 5EB8:       AB3700F9         STR R1, [CFP, #104]
; 5EBC:       7D0300F9         STR CFP, [CSP]
; 5EC0:       16F6FF58         LDR LEXENV, #x8005735D80       ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 5EC4:       170080D2         MOVZ NARGS, #0
; 5EC8:       DE9240F8         LDR LR, [LEXENV, #9]
; 5ECC:       FD031BAA         MOV CFP, CSP
; 5ED0:       C0033FD6         BLR LR
; 5ED4:       AA2700F9         STR R0, [CFP, #72]
; 5ED8:       7D0300F9         STR CFP, [CSP]
; 5EDC:       76F5FF58         LDR LEXENV, #x8005735D88       ; #<SB-KERNEL:FDEFN GET-BYTES-CONSED>
; 5EE0:       170080D2         MOVZ NARGS, #0
; 5EE4:       DE9240F8         LDR LR, [LEXENV, #9]
; 5EE8:       FD031BAA         MOV CFP, CSP
; 5EEC:       C0033FD6         BLR LR
; 5EF0:       ABB746A9         LDP R1, R3, [CFP, #104]
; 5EF4:       AF3F40F9         LDR R5, [CFP, #120]
; 5EF8:       AA2B00F9         STR R0, [CFP, #80]
; 5EFC:       100080D2         MOVZ R6, #0
; 5F00:       57000014         B L8
; 5F04: L0:   030080D2         MOVZ NL3, #0
; 5F08:       50000014         B L7
; 5F0C: L1:   60915FF8         LDR NL0, [R1, #-7]
; 5F10:       1F0003EB         CMP NL0, NL3
; 5F14:       291C0054         BLS L20
; 5F18:       6909038B         ADD TMP, R1, NL3, LSL #2
; 5F1C:       271140F8         LDR NL7, [TMP, #1]
; 5F20:       A0915FF8         LDR NL0, [R3, #-7]
; 5F24:       1F0003EB         CMP NL0, NL3
; 5F28:       C91B0054         BLS L21
; 5F2C:       A909038B         ADD TMP, R3, NL3, LSL #2
; 5F30:       281140F8         LDR NL8, [TMP, #1]
; 5F34:       E0915FF8         LDR NL0, [R5, #-7]
; 5F38:       1F0003EB         CMP NL0, NL3
; 5F3C:       691B0054         BLS L22
; 5F40:       E905838B         ADD TMP, R5, NL3, ASR #1
; 5F44:       25054039         LDRB WNL5, [TMP, #1]
; 5F48:       BFE079F2         TST NL5, #18446744073709551488
; 5F4C:       E1180054         BNE L18
; 5F50:       040080D2         MOVZ NL4, #0
; 5F54:       020080D2         MOVZ NL2, #0
; 5F58:       1E000014         B L5
; 5F5C: L2:   E0018092         MOVN NL0, #15
; 5F60:       007C029B         MUL NL0, NL0, NL2
; 5F64:       06FC4193         ASR NL6, NL0, #1
; 5F68:       E10306CB         NEG NL1, NL6
; 5F6C:       E024C19A         LSR NL0, NL7, NL1
; 5F70:       00F87FD3         LSL NL0, NL0, #1
; 5F74:       00FC4193         ASR NL0, NL0, #1
; 5F78:       001C4092         AND NL0, NL0, #255
; 5F7C:       E10305AA         MOV NL1, NL5
; 5F80:       1F0001EB         CMP NL0, NL1
; 5F84:       80160054         BEQ L17
; 5F88: L3:   E0018092         MOVN NL0, #15
; 5F8C:       007C029B         MUL NL0, NL0, NL2
; 5F90:       06FC4193         ASR NL6, NL0, #1
; 5F94:       E10306CB         NEG NL1, NL6
; 5F98:       0025C19A         LSR NL0, NL8, NL1
; 5F9C:       00F87FD3         LSL NL0, NL0, #1
; 5FA0:       00FC4193         ASR NL0, NL0, #1
; 5FA4:       001C4092         AND NL0, NL0, #255
; 5FA8:       E10305AA         MOV NL1, NL5
; 5FAC:       1F0001EB         CMP NL0, NL1
; 5FB0:       A1000054         BNE L4
; 5FB4:       004080D2         MOVZ NL0, #512
; 5FB8:       0020C29A         LSL NL0, NL0, NL2
; 5FBC:       800000AA         ORR NL0, NL4, NL0
; 5FC0:       E40300AA         MOV NL4, NL0
; 5FC4: L4:   E00302AA         MOV NL0, NL2
; 5FC8:       00040091         ADD NL0, NL0, #1
; 5FCC:       E20300AA         MOV NL2, NL0
; 5FD0: L5:   5F2000F1         CMP NL2, #8
; 5FD4:       41FCFF54         BNE L2
; 5FD8:       A01B40F9         LDR NL0, [CFP, #48]
; 5FDC:       800000AB         ADDS NL0, NL4, NL0
; 5FE0:       86160054         BVS L23
; 5FE4:       A01B00F9         STR NL0, [CFP, #48]
; 5FE8:       A01F40F9         LDR NL0, [CFP, #56]
; 5FEC:       000800B1         ADDS NL0, NL0, #2
; 5FF0:       26160054         BVS L24
; 5FF4:       A01F00F9         STR NL0, [CFP, #56]
; 5FF8:       A01F40F9         LDR NL0, [CFP, #56]
; 5FFC:       1F2C7FF2         TST NL0, #8190
; 6000:       01020054         BNE L6
; 6004:       A3C305A9         STP NL3, R6, [CFP, #88]
; 6008:       ABB706A9         STP R1, R3, [CFP, #104]
; 600C:       AF3F00F9         STR R5, [CFP, #120]
; 6010:       7D0300F9         STR CFP, [CSP]
; 6014:       76EBFF58         LDR LEXENV, #x8005735D80       ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 6018:       170080D2         MOVZ NARGS, #0
; 601C:       DE9240F8         LDR LR, [LEXENV, #9]
; 6020:       FD031BAA         MOV CFP, CSP
; 6024:       C0033FD6         BLR LR
; 6028:       AD3F47A9         LDP R3, R5, [CFP, #112]
; 602C:       B02F46A9         LDP R6, R1, [CFP, #96]
; 6030:       A32F40F9         LDR NL3, [CFP, #88]
; 6034:       AC1740F9         LDR R2, [CFP, #40]
; 6038:       5F010CEB         CMP R0, R2
; 603C:       AA0F0054         BGE L16
; 6040: L6:   60080091         ADD NL0, NL3, #2
; 6044:       E30300AA         MOV NL3, NL0
; 6048: L7:   A02340F9         LDR NL0, [CFP, #64]
; 604C:       7F0000EB         CMP NL3, NL0
; 6050:       EBF5FF54         BLT L1
; 6054:       000A0091         ADD NL0, R6, #2
; 6058:       F00300AA         MOV R6, NL0
; 605C: L8:   A01340F9         LDR NL0, [CFP, #32]
; 6060:       1F0200EB         CMP R6, NL0
; 6064:       0BF5FF54         BLT L0
; 6068:       7D0300F9         STR CFP, [CSP]
; 606C:       F6E8FF58         LDR LEXENV, #x8005735D88       ; #<SB-KERNEL:FDEFN GET-BYTES-CONSED>
; 6070:       170080D2         MOVZ NARGS, #0
; 6074:       DE9240F8         LDR LR, [LEXENV, #9]
; 6078:       FD031BAA         MOV CFP, CSP
; 607C:       C0033FD6         BLR LR
; 6080:       EB030AAA         MOV R1, R0
; 6084:       AB2F00F9         STR R1, [CFP, #88]
; 6088:       7D0300F9         STR CFP, [CSP]
; 608C:       B6E7FF58         LDR LEXENV, #x8005735D80       ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 6090:       170080D2         MOVZ NARGS, #0
; 6094:       DE9240F8         LDR LR, [LEXENV, #9]
; 6098:       FD031BAA         MOV CFP, CSP
; 609C:       C0033FD6         BLR LR
; 60A0:       AB2F40F9         LDR R1, [CFP, #88]
; 60A4:       A02740F9         LDR NL0, [CFP, #72]
; 60A8:       400100CB         SUB NL0, R0, NL0
; 60AC:       A02300F9         STR NL0, [CFP, #64]
; 60B0:       7D0300F9         STR CFP, [CSP]
; 60B4:       EA030BAA         MOV R0, R1
; 60B8:       AB2B40F9         LDR R1, [CFP, #80]
; 60BC:       298280D2         MOVZ TMP, #1041
; 60C0:       5E6B69F8         LDR LR, [NULL, TMP]            ; SB-KERNEL:TWO-ARG--
; 60C4:       FD031BAA         MOV CFP, CSP
; 60C8:       C0033FD6         BLR LR
; 60CC:       EB030AAA         MOV R1, R0
; 60D0:       AB2700F9         STR R1, [CFP, #72]
; 60D4:       7D0300F9         STR CFP, [CSP]
; 60D8:       56E5FF58         LDR LEXENV, #x8005735D80       ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 60DC:       170080D2         MOVZ NARGS, #0
; 60E0:       DE9240F8         LDR LR, [LEXENV, #9]
; 60E4:       FD031BAA         MOV CFP, CSP
; 60E8:       C0033FD6         BLR LR
; 60EC:       AB2740F9         LDR R1, [CFP, #72]
; 60F0:       AC1740F9         LDR R2, [CFP, #40]
; 60F4:       5F010CEB         CMP R0, R2
; 60F8:       AA080054         BGE L15
; 60FC:       AA0F40F9         LDR R0, [CFP, #24]
; 6100:       405144F8         LDR NL0, [R0, #69]
; 6104:       A11340F9         LDR NL1, [CFP, #32]
; 6108:       21FC4193         ASR NL1, NL1, #1
; 610C:       00FC4193         ASR NL0, NL0, #1
; 6110:       237C409B         SMULH NL3, NL1, NL0
; 6114:       227C009B         MUL NL2, NL1, NL0
; 6118:       214280D2         MOVZ NL1, #529
; 611C:       7FFC82EB         CMP NL3, NL2, ASR #63
; 6120:       81000054         BNE L9
; 6124:       4A0002AB         ADDS R0, NL2, NL2
; 6128:       E7010054         BVC L11
; 612C:       212280D2         MOVZ NL1, #273
; 6130: L9:   BA2A00B9         STR WNULL, [THREAD, #40]       ; pseudo-atomic-bits
; 6134:       A97A47A9         LDP TMP, LR, [THREAD, #112]    ; mixed-tlab.{free-pointer, end-addr}
; 6138:       2A810091         ADD R0, TMP, #32
; 613C:       5F011EEB         CMP R0, LR
; 6140:       C80B0054         BHI L25
; 6144:       AA3A00F9         STR R0, [THREAD, #112]         ; mixed-tlab
; 6148: L10:  2A3D0091         ADD R0, TMP, #15
; 614C:       210900A9         STP NL1, NL2, [TMP]
; 6150:       230900F9         STR NL3, [TMP, #16]
; 6154:       BF2A00B9         STR WZR, [THREAD, #40]         ; pseudo-atomic-bits
; 6158:       BE2E40B9         LDR WLR, [THREAD, #44]         ; pseudo-atomic-bits
; 615C:       5E0000B4         CBZ LR, L11
; 6160:       200120D4         BRK #9                         ; Pending interrupt trap
; 6164: L11:  A01B40F9         LDR NL0, [CFP, #48]
; 6168:       5F0100EB         CMP R0, NL0
; 616C:       21010054         BNE L12
; 6170:       AA2340F9         LDR R0, [CFP, #64]
; 6174:       AC3743A9         LDP R2, R3, [CFP, #48]
; 6178:       F9031DAA         MOV OCFP, CFP
; 617C:       3B830091         ADD CSP, OCFP, #32
; 6180:       170180D2         MOVZ NARGS, #8
; 6184:       FF031FEB         CMP ZR, ZR
; 6188:       BD7B40A9         LDP CFP, LR, [CFP]
; 618C:       C0035FD6         RET
; 6190: L12:  A01B40F9         LDR NL0, [CFP, #48]
; 6194:       BA2A00B9         STR WNULL, [THREAD, #40]       ; pseudo-atomic-bits
; 6198:       A9FA45A9         LDP TMP, LR, [THREAD, #88]     ; cons-tlab.{free-pointer, end-addr}
; 619C:       2CC10091         ADD R2, TMP, #48
; 61A0:       9F011EEB         CMP R2, LR
; 61A4:       28090054         BHI L26
; 61A8:       AC2E00F9         STR R2, [THREAD, #88]          ; cons-tlab
; 61AC: L13:  2C1D0091         ADD R2, TMP, #7
; 61B0:       EE030CAA         MOV R4, R2
; 61B4:       2FDFFF58         LDR R5, #x8005735D98           ; :CYCLE-CHECKSUM
; 61B8:       CF911FF8         STR R5, [R4, #-7]
; 61BC:       CE410091         ADD R4, R4, #16
; 61C0:       CE111FF8         STR R4, [R4, #-15]
; 61C4:       EFDEFF58         LDR R5, #x8005735DA0           ; 'ARCDOCDB.SPK08.IMPRONTE::CYCLE-SCALAR-U64
; 61C8:       CF911FF8         STR R5, [R4, #-7]
; 61CC:       CE410091         ADD R4, R4, #16
; 61D0:       CE111FF8         STR R4, [R4, #-15]
; 61D4:       C0911FF8         STR NL0, [R4, #-7]
; 61D8:       DA1100F8         STR NULL, [R4, #1]
; 61DC:       BF2A00B9         STR WZR, [THREAD, #40]         ; pseudo-atomic-bits
; 61E0:       BE2E40B9         LDR WLR, [THREAD, #44]         ; pseudo-atomic-bits
; 61E4:       5E0000B4         CBZ LR, L14
; 61E8:       200120D4         BRK #9                         ; Pending interrupt trap
; 61EC: L14:  7D0300F9         STR CFP, [CSP]
; 61F0:       CADDFF58         LDR R0, #x8005735DA8           ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 61F4:       EBDDFF58         LDR R1, #x8005735DB0           ; :MOTIVO
; 61F8:       29A680D2         MOVZ TMP, #1329
; 61FC:       5E6B69F8         LDR LR, [NULL, TMP]            ; ERROR
; 6200:       D70080D2         MOVZ NARGS, #6
; 6204:       FD031BAA         MOV CFP, CSP
; 6208:       C0033FD6         BLR LR
; 620C: L15:  7D0300F9         STR CFP, [CSP]
; 6210:       CADCFF58         LDR R0, #x8005735DA8           ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 6214:       EBDCFF58         LDR R1, #x8005735DB0           ; :MOTIVO
; 6218:       0CDDFF58         LDR R2, #x8005735DB8           ; :TIME-BUDGET
; 621C:       29A680D2         MOVZ TMP, #1329
; 6220:       5E6B69F8         LDR LR, [NULL, TMP]            ; ERROR
; 6224:       D70080D2         MOVZ NARGS, #6
; 6228:       FD031BAA         MOV CFP, CSP
; 622C:       C0033FD6         BLR LR
; 6230: L16:  7D0300F9         STR CFP, [CSP]
; 6234:       AADBFF58         LDR R0, #x8005735DA8           ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 6238:       CBDBFF58         LDR R1, #x8005735DB0           ; :MOTIVO
; 623C:       ECDBFF58         LDR R2, #x8005735DB8           ; :TIME-BUDGET
; 6240:       29A680D2         MOVZ TMP, #1329
; 6244:       5E6B69F8         LDR LR, [NULL, TMP]            ; ERROR
; 6248:       D70080D2         MOVZ NARGS, #6
; 624C:       FD031BAA         MOV CFP, CSP
; 6250:       C0033FD6         BLR LR
; 6254: L17:  400080D2         MOVZ NL0, #2
; 6258:       0020C29A         LSL NL0, NL0, NL2
; 625C:       800000AA         ORR NL0, NL4, NL0
; 6260:       E40300AA         MOV NL4, NL0
; 6264:       49FFFF17         B L3
; 6268: L18:  80A328D4         BRK #17692                     ; OBJECT-NOT-TYPE-ERROR
                                                              ; NL5
; 626C:       33               BYTE #X33                      ; '(UNSIGNED-BYTE 7)
; 626D:       .ALIGN           4
; 6270: L19:  7D0300F9         STR CFP, [CSP]
; 6274:       AAD9FF58         LDR R0, #x8005735DA8           ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 6278:       CBD9FF58         LDR R1, #x8005735DB0           ; :MOTIVO
; 627C:       ECD9FF58         LDR R2, #x8005735DB8           ; :TIME-BUDGET
; 6280:       29A680D2         MOVZ TMP, #1329
; 6284:       5E6B69F8         LDR LR, [NULL, TMP]            ; ERROR
; 6288:       D70080D2         MOVZ NARGS, #6
; 628C:       FD031BAA         MOV CFP, CSP
; 6290:       C0033FD6         BLR LR
; 6294:       E00120D4         BRK #15                        ; Invalid argument count trap
; 6298: L20:  606421D4         BRK #2851                      ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R1
; 629C:       0C               BYTE #X0C                      ; NL3
; 629D:       .ALIGN           4
; 62A0: L21:  60A421D4         BRK #3363                      ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R3
; 62A4:       0C               BYTE #X0C                      ; NL3
; 62A5:       .ALIGN           4
; 62A8: L22:  60E421D4         BRK #3875                      ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R5
; 62AC:       0C               BYTE #X0C                      ; NL3
; 62AD:       .ALIGN           4
; 62B0: L23:  A00520D4         BRK #45                        ; ADD-SUB-OVERFLOW-ERROR
                                                              ; NL0
; 62B4: L24:  A00520D4         BRK #45                        ; ADD-SUB-OVERFLOW-ERROR
                                                              ; NL0
; 62B8: L25:  090480D2         MOVZ TMP, #32
; 62BC:       EAD8FF58         LDR R0, #x8005735DD8           ; SB-VM::ALLOC-TRAMP
; 62C0:       40013FD6         BLR R0
; 62C4:       A1FFFF17         B L10
; 62C8: L26:  090680D2         MOVZ TMP, #48
; 62CC:       ACD8FF58         LDR R2, #x8005735DE0           ; SB-VM::LIST-ALLOC-TRAMP
; 62D0:       80013FD6         BLR R2
; 62D4:       B6FFFF17         B L13
")
    (:FUNCTION #A((39) BASE-CHAR . "ARCDOCDB.SPK08.IMPRONTE::CYCLE-TYPEDU64")
     :TEXT "; disassembly for ARCDOCDB.SPK08.IMPRONTE::CYCLE-TYPEDU64
; Size: 1204 bytes. Origin: #x80057363E4                      ; ARCDOCDB.SPK08.IMPRONTE::CYCLE-TYPEDU64
; 3E4:       AA0F40F9         LDR R0, [CFP, #24]
; 3E8:       4FD141F8         LDR R5, [R0, #29]
; 3EC:       AF3F00F9         STR R5, [CFP, #120]
; 3F0:       AA0F40F9         LDR R0, [CFP, #24]
; 3F4:       4B5142F8         LDR R1, [R0, #37]
; 3F8:       AB3700F9         STR R1, [CFP, #104]
; 3FC:       AA0F40F9         LDR R0, [CFP, #24]
; 400:       4DD142F8         LDR R3, [R0, #45]
; 404:       AD3B00F9         STR R3, [CFP, #112]
; 408:       AA0F40F9         LDR R0, [CFP, #24]
; 40C:       40D143F8         LDR NL0, [R0, #61]
; 410:       A02300F9         STR NL0, [CFP, #64]
; 414:       BF7F03A9         STP ZR, ZR, [CFP, #48]
; 418:       7D0300F9         STR CFP, [CSP]
; 41C:       36F7FF58         LDR LEXENV, #x8005736300        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 420:       170080D2         MOVZ NARGS, #0
; 424:       DE9240F8         LDR LR, [LEXENV, #9]
; 428:       FD031BAA         MOV CFP, CSP
; 42C:       C0033FD6         BLR LR
; 430:       ABB746A9         LDP R1, R3, [CFP, #104]
; 434:       AF3F40F9         LDR R5, [CFP, #120]
; 438:       A01740F9         LDR NL0, [CFP, #40]
; 43C:       5F0100EB         CMP R0, NL0
; 440:       8A1F0054         BGE L14
; 444:       AD3F07A9         STP R3, R5, [CFP, #112]
; 448:       AB3700F9         STR R1, [CFP, #104]
; 44C:       7D0300F9         STR CFP, [CSP]
; 450:       96F5FF58         LDR LEXENV, #x8005736300        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 454:       170080D2         MOVZ NARGS, #0
; 458:       DE9240F8         LDR LR, [LEXENV, #9]
; 45C:       FD031BAA         MOV CFP, CSP
; 460:       C0033FD6         BLR LR
; 464:       AA2700F9         STR R0, [CFP, #72]
; 468:       7D0300F9         STR CFP, [CSP]
; 46C:       F6F4FF58         LDR LEXENV, #x8005736308        ; #<SB-KERNEL:FDEFN GET-BYTES-CONSED>
; 470:       170080D2         MOVZ NARGS, #0
; 474:       DE9240F8         LDR LR, [LEXENV, #9]
; 478:       FD031BAA         MOV CFP, CSP
; 47C:       C0033FD6         BLR LR
; 480:       ABB746A9         LDP R1, R3, [CFP, #104]
; 484:       AF3F40F9         LDR R5, [CFP, #120]
; 488:       AA2B00F9         STR R0, [CFP, #80]
; 48C:       070080D2         MOVZ NL7, #0
; 490:       68000014         B L4
; 494: L0:   030080D2         MOVZ NL3, #0
; 498:       61000014         B L3
; 49C: L1:   60915FF8         LDR NL0, [R1, #-7]
; 4A0:       1F0003EB         CMP NL0, NL3
; 4A4:       A91D0054         BLS L15
; 4A8:       6909038B         ADD TMP, R1, NL3, LSL #2
; 4AC:       211140F8         LDR NL1, [TMP, #1]
; 4B0:       A0915FF8         LDR NL0, [R3, #-7]
; 4B4:       1F0003EB         CMP NL0, NL3
; 4B8:       491D0054         BLS L16
; 4BC:       A909038B         ADD TMP, R3, NL3, LSL #2
; 4C0:       251140F8         LDR NL5, [TMP, #1]
; 4C4:       E0915FF8         LDR NL0, [R5, #-7]
; 4C8:       1F0003EB         CMP NL0, NL3
; 4CC:       E91C0054         BLS L17
; 4D0:       E905838B         ADD TMP, R5, NL3, ASR #1
; 4D4:       20054039         LDRB WNL0, [TMP, #1]
; 4D8:       1FE079F2         TST NL0, #18446744073709551488
; 4DC:       611A0054         BNE L13
; 4E0:       E9C300B2         MOV TMP, #72340172838076673
; 4E4:       047C099B         MUL NL4, NL0, TMP
; 4E8:       E00304AA         MOV NL0, NL4
; 4EC:       200000CA         EOR NL0, NL1, NL0
; 4F0:       02D800B2         ORR NL2, NL0, #9187201950435737471
; 4F4:       00D80092         AND NL0, NL0, #9187201950435737471
; 4F8:       E1DB00B2         MOV NL1, #9187201950435737471
; 4FC:       0000018B         ADD NL0, NL0, NL1
; 500:       400000AA         ORR NL0, NL2, NL0
; 504:       01008092         MOVN NL1, #0
; 508:       000001CA         EOR NL0, NL0, NL1
; 50C:       00C00192         AND NL0, NL0, #9259542123273814144
; 510:       00FC47D3         LSR NL0, NL0, #7
; 514:       E10300AA         MOV NL1, NL0
; 518:       21FC47D3         LSR NL1, NL1, #7
; 51C:       000001AA         ORR NL0, NL0, NL1
; 520:       00840092         AND NL0, NL0, #844437815230467
; 524:       E10300AA         MOV NL1, NL0
; 528:       21FC4ED3         LSR NL1, NL1, #14
; 52C:       000001AA         ORR NL0, NL0, NL1
; 530:       000C0092         AND NL0, NL0, #64424509455
; 534:       00F87FD3         LSL NL0, NL0, #1
; 538:       01FC5C93         ASR NL1, NL0, #28
; 53C:       22F87F92         AND NL2, NL1, #18446744073709551614
; 540:       000002AA         ORR NL0, NL0, NL2
; 544:       061C7F92         AND NL6, NL0, #510
; 548:       E00304AA         MOV NL0, NL4
; 54C:       A00000CA         EOR NL0, NL5, NL0
; 550:       01D800B2         ORR NL1, NL0, #9187201950435737471
; 554:       00D80092         AND NL0, NL0, #9187201950435737471
; 558:       E2DB00B2         MOV NL2, #9187201950435737471
; 55C:       0000028B         ADD NL0, NL0, NL2
; 560:       200000AA         ORR NL0, NL1, NL0
; 564:       01008092         MOVN NL1, #0
; 568:       000001CA         EOR NL0, NL0, NL1
; 56C:       00C00192         AND NL0, NL0, #9259542123273814144
; 570:       00FC47D3         LSR NL0, NL0, #7
; 574:       E10300AA         MOV NL1, NL0
; 578:       21FC47D3         LSR NL1, NL1, #7
; 57C:       000001AA         ORR NL0, NL0, NL1
; 580:       00840092         AND NL0, NL0, #844437815230467
; 584:       E10300AA         MOV NL1, NL0
; 588:       21FC4ED3         LSR NL1, NL1, #14
; 58C:       000001AA         ORR NL0, NL0, NL1
; 590:       000C0092         AND NL0, NL0, #64424509455
; 594:       00F87FD3         LSL NL0, NL0, #1
; 598:       01FC5C93         ASR NL1, NL0, #28
; 59C:       22F87F92         AND NL2, NL1, #18446744073709551614
; 5A0:       000002AA         ORR NL0, NL0, NL2
; 5A4:       001C7F92         AND NL0, NL0, #510
; 5A8:       C02000AA         ORR NL0, NL6, NL0, LSL #8
; 5AC:       A11B40F9         LDR NL1, [CFP, #48]
; 5B0:       000001AB         ADDS NL0, NL0, NL1
; 5B4:       E6150054         BVS L18
; 5B8:       A01B00F9         STR NL0, [CFP, #48]
; 5BC:       A01F40F9         LDR NL0, [CFP, #56]
; 5C0:       000800B1         ADDS NL0, NL0, #2
; 5C4:       86150054         BVS L19
; 5C8:       A01F00F9         STR NL0, [CFP, #56]
; 5CC:       A01F40F9         LDR NL0, [CFP, #56]
; 5D0:       1F2C7FF2         TST NL0, #8190
; 5D4:       01020054         BNE L2
; 5D8:       A39F05A9         STP NL3, NL7, [CFP, #88]
; 5DC:       ABB706A9         STP R1, R3, [CFP, #104]
; 5E0:       AF3F00F9         STR R5, [CFP, #120]
; 5E4:       7D0300F9         STR CFP, [CSP]
; 5E8:       D6E8FF58         LDR LEXENV, #x8005736300        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 5EC:       170080D2         MOVZ NARGS, #0
; 5F0:       DE9240F8         LDR LR, [LEXENV, #9]
; 5F4:       FD031BAA         MOV CFP, CSP
; 5F8:       C0033FD6         BLR LR
; 5FC:       AD3F47A9         LDP R3, R5, [CFP, #112]
; 600:       A72F46A9         LDP NL7, R1, [CFP, #96]
; 604:       A32F40F9         LDR NL3, [CFP, #88]
; 608:       AC1740F9         LDR R2, [CFP, #40]
; 60C:       5F010CEB         CMP R0, R2
; 610:       AA0F0054         BGE L12
; 614: L2:   60080091         ADD NL0, NL3, #2
; 618:       E30300AA         MOV NL3, NL0
; 61C: L3:   A02340F9         LDR NL0, [CFP, #64]
; 620:       7F0000EB         CMP NL3, NL0
; 624:       CBF3FF54         BLT L1
; 628:       E0080091         ADD NL0, NL7, #2
; 62C:       E70300AA         MOV NL7, NL0
; 630: L4:   A01340F9         LDR NL0, [CFP, #32]
; 634:       FF0000EB         CMP NL7, NL0
; 638:       EBF2FF54         BLT L0
; 63C:       7D0300F9         STR CFP, [CSP]
; 640:       56E6FF58         LDR LEXENV, #x8005736308        ; #<SB-KERNEL:FDEFN GET-BYTES-CONSED>
; 644:       170080D2         MOVZ NARGS, #0
; 648:       DE9240F8         LDR LR, [LEXENV, #9]
; 64C:       FD031BAA         MOV CFP, CSP
; 650:       C0033FD6         BLR LR
; 654:       EB030AAA         MOV R1, R0
; 658:       AB2F00F9         STR R1, [CFP, #88]
; 65C:       7D0300F9         STR CFP, [CSP]
; 660:       16E5FF58         LDR LEXENV, #x8005736300        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 664:       170080D2         MOVZ NARGS, #0
; 668:       DE9240F8         LDR LR, [LEXENV, #9]
; 66C:       FD031BAA         MOV CFP, CSP
; 670:       C0033FD6         BLR LR
; 674:       AB2F40F9         LDR R1, [CFP, #88]
; 678:       A02740F9         LDR NL0, [CFP, #72]
; 67C:       400100CB         SUB NL0, R0, NL0
; 680:       A02300F9         STR NL0, [CFP, #64]
; 684:       7D0300F9         STR CFP, [CSP]
; 688:       EA030BAA         MOV R0, R1
; 68C:       AB2B40F9         LDR R1, [CFP, #80]
; 690:       298280D2         MOVZ TMP, #1041
; 694:       5E6B69F8         LDR LR, [NULL, TMP]             ; SB-KERNEL:TWO-ARG--
; 698:       FD031BAA         MOV CFP, CSP
; 69C:       C0033FD6         BLR LR
; 6A0:       EB030AAA         MOV R1, R0
; 6A4:       AB2700F9         STR R1, [CFP, #72]
; 6A8:       7D0300F9         STR CFP, [CSP]
; 6AC:       B6E2FF58         LDR LEXENV, #x8005736300        ; #<SB-KERNEL:FDEFN GET-INTERNAL-REAL-TIME>
; 6B0:       170080D2         MOVZ NARGS, #0
; 6B4:       DE9240F8         LDR LR, [LEXENV, #9]
; 6B8:       FD031BAA         MOV CFP, CSP
; 6BC:       C0033FD6         BLR LR
; 6C0:       AB2740F9         LDR R1, [CFP, #72]
; 6C4:       AC1740F9         LDR R2, [CFP, #40]
; 6C8:       5F010CEB         CMP R0, R2
; 6CC:       AA080054         BGE L11
; 6D0:       AA0F40F9         LDR R0, [CFP, #24]
; 6D4:       405144F8         LDR NL0, [R0, #69]
; 6D8:       A11340F9         LDR NL1, [CFP, #32]
; 6DC:       21FC4193         ASR NL1, NL1, #1
; 6E0:       00FC4193         ASR NL0, NL0, #1
; 6E4:       237C409B         SMULH NL3, NL1, NL0
; 6E8:       227C009B         MUL NL2, NL1, NL0
; 6EC:       214280D2         MOVZ NL1, #529
; 6F0:       7FFC82EB         CMP NL3, NL2, ASR #63
; 6F4:       81000054         BNE L5
; 6F8:       4A0002AB         ADDS R0, NL2, NL2
; 6FC:       E7010054         BVC L7
; 700:       212280D2         MOVZ NL1, #273
; 704: L5:   BA2A00B9         STR WNULL, [THREAD, #40]        ; pseudo-atomic-bits
; 708:       A97A47A9         LDP TMP, LR, [THREAD, #112]     ; mixed-tlab.{free-pointer, end-addr}
; 70C:       2A810091         ADD R0, TMP, #32
; 710:       5F011EEB         CMP R0, LR
; 714:       280B0054         BHI L20
; 718:       AA3A00F9         STR R0, [THREAD, #112]          ; mixed-tlab
; 71C: L6:   2A3D0091         ADD R0, TMP, #15
; 720:       210900A9         STP NL1, NL2, [TMP]
; 724:       230900F9         STR NL3, [TMP, #16]
; 728:       BF2A00B9         STR WZR, [THREAD, #40]          ; pseudo-atomic-bits
; 72C:       BE2E40B9         LDR WLR, [THREAD, #44]          ; pseudo-atomic-bits
; 730:       5E0000B4         CBZ LR, L7
; 734:       200120D4         BRK #9                          ; Pending interrupt trap
; 738: L7:   A01B40F9         LDR NL0, [CFP, #48]
; 73C:       5F0100EB         CMP R0, NL0
; 740:       21010054         BNE L8
; 744:       AA2340F9         LDR R0, [CFP, #64]
; 748:       AC3743A9         LDP R2, R3, [CFP, #48]
; 74C:       F9031DAA         MOV OCFP, CFP
; 750:       3B830091         ADD CSP, OCFP, #32
; 754:       170180D2         MOVZ NARGS, #8
; 758:       FF031FEB         CMP ZR, ZR
; 75C:       BD7B40A9         LDP CFP, LR, [CFP]
; 760:       C0035FD6         RET
; 764: L8:   A01B40F9         LDR NL0, [CFP, #48]
; 768:       BA2A00B9         STR WNULL, [THREAD, #40]        ; pseudo-atomic-bits
; 76C:       A9FA45A9         LDP TMP, LR, [THREAD, #88]      ; cons-tlab.{free-pointer, end-addr}
; 770:       2CC10091         ADD R2, TMP, #48
; 774:       9F011EEB         CMP R2, LR
; 778:       88080054         BHI L21
; 77C:       AC2E00F9         STR R2, [THREAD, #88]           ; cons-tlab
; 780: L9:   2C1D0091         ADD R2, TMP, #7
; 784:       EE030CAA         MOV R4, R2
; 788:       0FDDFF58         LDR R5, #x8005736328            ; :CYCLE-CHECKSUM
; 78C:       CF911FF8         STR R5, [R4, #-7]
; 790:       CE410091         ADD R4, R4, #16
; 794:       CE111FF8         STR R4, [R4, #-15]
; 798:       CFDCFF58         LDR R5, #x8005736330            ; 'ARCDOCDB.SPK08.IMPRONTE::CYCLE-TYPEDU64
; 79C:       CF911FF8         STR R5, [R4, #-7]
; 7A0:       CE410091         ADD R4, R4, #16
; 7A4:       CE111FF8         STR R4, [R4, #-15]
; 7A8:       C0911FF8         STR NL0, [R4, #-7]
; 7AC:       DA1100F8         STR NULL, [R4, #1]
; 7B0:       BF2A00B9         STR WZR, [THREAD, #40]          ; pseudo-atomic-bits
; 7B4:       BE2E40B9         LDR WLR, [THREAD, #44]          ; pseudo-atomic-bits
; 7B8:       5E0000B4         CBZ LR, L10
; 7BC:       200120D4         BRK #9                          ; Pending interrupt trap
; 7C0: L10:  7D0300F9         STR CFP, [CSP]
; 7C4:       AADBFF58         LDR R0, #x8005736338            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 7C8:       CBDBFF58         LDR R1, #x8005736340            ; :MOTIVO
; 7CC:       29A680D2         MOVZ TMP, #1329
; 7D0:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 7D4:       D70080D2         MOVZ NARGS, #6
; 7D8:       FD031BAA         MOV CFP, CSP
; 7DC:       C0033FD6         BLR LR
; 7E0: L11:  7D0300F9         STR CFP, [CSP]
; 7E4:       AADAFF58         LDR R0, #x8005736338            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 7E8:       CBDAFF58         LDR R1, #x8005736340            ; :MOTIVO
; 7EC:       ECDAFF58         LDR R2, #x8005736348            ; :TIME-BUDGET
; 7F0:       29A680D2         MOVZ TMP, #1329
; 7F4:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 7F8:       D70080D2         MOVZ NARGS, #6
; 7FC:       FD031BAA         MOV CFP, CSP
; 800:       C0033FD6         BLR LR
; 804: L12:  7D0300F9         STR CFP, [CSP]
; 808:       8AD9FF58         LDR R0, #x8005736338            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 80C:       ABD9FF58         LDR R1, #x8005736340            ; :MOTIVO
; 810:       CCD9FF58         LDR R2, #x8005736348            ; :TIME-BUDGET
; 814:       29A680D2         MOVZ TMP, #1329
; 818:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 81C:       D70080D2         MOVZ NARGS, #6
; 820:       FD031BAA         MOV CFP, CSP
; 824:       C0033FD6         BLR LR
; 828: L13:  800328D4         BRK #16412                      ; OBJECT-NOT-TYPE-ERROR
                                                              ; NL0
; 82C:       3B               BYTE #X3B                       ; '(UNSIGNED-BYTE 7)
; 82D:       .ALIGN           4
; 830: L14:  7D0300F9         STR CFP, [CSP]
; 834:       2AD8FF58         LDR R0, #x8005736338            ; 'ARCDOCDB.SPK08.IMPRONTE::ERRORE-IMPRONTE
; 838:       4BD8FF58         LDR R1, #x8005736340            ; :MOTIVO
; 83C:       6CD8FF58         LDR R2, #x8005736348            ; :TIME-BUDGET
; 840:       29A680D2         MOVZ TMP, #1329
; 844:       5E6B69F8         LDR LR, [NULL, TMP]             ; ERROR
; 848:       D70080D2         MOVZ NARGS, #6
; 84C:       FD031BAA         MOV CFP, CSP
; 850:       C0033FD6         BLR LR
; 854:       E00120D4         BRK #15                         ; Invalid argument count trap
; 858: L15:  606421D4         BRK #2851                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R1
; 85C:       0C               BYTE #X0C                       ; NL3
; 85D:       .ALIGN           4
; 860: L16:  60A421D4         BRK #3363                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R3
; 864:       0C               BYTE #X0C                       ; NL3
; 865:       .ALIGN           4
; 868: L17:  60E421D4         BRK #3875                       ; INVALID-VECTOR-INDEX-ERROR
                                                              ; R5
; 86C:       0C               BYTE #X0C                       ; NL3
; 86D:       .ALIGN           4
; 870: L18:  A00520D4         BRK #45                         ; ADD-SUB-OVERFLOW-ERROR
                                                              ; NL0
; 874: L19:  A00520D4         BRK #45                         ; ADD-SUB-OVERFLOW-ERROR
                                                              ; NL0
; 878: L20:  090480D2         MOVZ TMP, #32
; 87C:       6AD7FF58         LDR R0, #x8005736368            ; SB-VM::ALLOC-TRAMP
; 880:       40013FD6         BLR R0
; 884:       A6FFFF17         B L6
; 888: L21:  090680D2         MOVZ TMP, #48
; 88C:       2CD7FF58         LDR R2, #x8005736370            ; SB-VM::LIST-ALLOC-TRAMP
; 890:       80013FD6         BLR R2
; 894:       BBFFFF17         B L9
")))
  :LOAD
  (:STATUS :OK :FASL
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB/spikes/SPK-08-generated-code/out/4000480868-impronte-87419-0/impronte.fasl"))
  :COMPILE
  (:STATUS :OK :OUTPUT
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB/spikes/SPK-08-generated-code/out/4000480868-impronte-87419-0/impronte.fasl")
   :WARNINGS-P NIL :FAILURE-P NIL)
  :STAGE :COMPLETE :SCHEMA-VERSION 1 :KIND :IMPRONTE-COMPILE-CHECK :STATUS :OK
  :COMMAND
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
   "17179869184" :LOGICAL-CPUS "10" :LOAD-AVERAGE "{ 2.97 4.19 7.63 }"
   :EXTERNAL-LOAD :UNCONTROLLED :COMMIT
   "62267c9811210c822973d240419daa986e8d8757" :INTERNAL-TIME-UNITS-PER-SECOND
   1000000 :PROCESS-ID 87419 :FEATURES
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
    "2ad6de50fdb7ef94cda1991dce08140fa2ed8ce8" :CONTENTS
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

(macrolet ((definit-cycle (name expression)
  ;; Quattro cicli diretti; nessun macro globale ridefinito al caricamento.
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
           (values ticks bytes acc operations)))))))

(definit-cycle cycle-scalar16
  (scalar16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definit-cycle cycle-packedmask16
  (packedmask16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definit-cycle cycle-scalar-u64
  (scalar-u64 (aref low row) (aref high row) (aref queries row)))
(definit-cycle cycle-typedu64
  (typedu64 (aref low row) (aref high row) (aref queries row))))

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
    "fbbfc43ea30ebe9a79384735efe256a09c393d23" :CONTENTS
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
              (setf (getf record :stage) :compile)
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
                (setf (getf record :stage) :load)
                (load fasl)
                (setf (getf record :load) (list :status :ok :fasl (namestring fasl))
                      (getf record :stage) :check)
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
              (setf (getf record :status) :ok (getf record :stage) :complete)))
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
  :STARTED-AT-UNIVERSAL-TIME 4000480868 :LIMITS
  (:SAFETY 3 :WARNING-FATAL T :STYLE-WARNING-FATAL T :COMPILE-ONLY-THIS-MODULE
   T :BENCH-NEVER-CALLED T :CHECK-MAX-CASES 4000000 :CHECK-SECONDS 120
   :STDOUT-TRUNCATED NIL :STDERR-TRUNCATED NIL :SOURCE-SCOPE
   :IMPRONTE-METHOD-AND-DRIVER :DEADLINE-COOPERATIVE T))
 :LIMITS (:REPRESENTATION-ONLY :ORIGINAL-OUTPUT-UNCHANGED))
