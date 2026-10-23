;;;; Phase0: maschere esatte scalar/SWAR, senza integrazione del primary index.
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
  (:report (lambda (c s) (format s "SPK08 impronte: ~S" (motivo c)))))

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
  "Caricamento portabile LE; i controlli degli accessi restano attivi."
  (declare (type octets ctrl) (type fixnum start))
  (let ((word 0))
    (declare (type u64 word))
    (dotimes (i 8 word)
      (setf word (logior word (ash (aref ctrl (+ start i)) (* 8 i)))))))

(declaim (ftype (function (u64) u64) zeri-esatti))
(defun zeri-esatti (x)
  "Un bit alto per byte zero: ogni addendo di lane è <=254, senza riporto."
  (declare (type u64 x))
  (logand +high+
          (logxor +u64-mask+
                  (logior x +low7+ (+ (logand x +low7+) +low7+)))))

(declaim (ftype (function (u64) (unsigned-byte 8)) comprimi8))
(defun comprimi8 (high-bits)
  "Conserva solo i bit 7,15,...,63; li porta nelle posizioni 0,...,7."
  (declare (type u64 high-bits))
  (let* ((x (ash (logand high-bits +high+) -7))
         (y (logand #x0003000300030003 (logior x (ash x -7))))
         (z (logand #x0000000f0000000f (logior y (ash y -14)))))
    (logand #xff (logior z (ash z -28)))))

(declaim (ftype (function (octets fixnum h7) mask16) scalar16 packedmask16)
         (ftype (function (u64 u64 h7) mask16) typedu64 scalar-u64))
(defun scalar16 (ctrl start h)
  "Baseline su 16 byte; bit i = uguaglianza nella posizione i."
  (declare (type octets ctrl) (type fixnum start) (type h7 h))
  (finestra ctrl start)
  (let ((mask 0))
    (declare (type mask16 mask))
    (dotimes (i 16 mask)
      (when (= h (aref ctrl (+ start i)))
        (setf mask (logior mask (ash 1 i)))))))

(defun scalar-u64 (low high h)
  "Baseline scalare su due parole LE già preparate."
  (declare (type u64 low high) (type h7 h))
  (let ((mask 0))
    (declare (type mask16 mask))
    (dotimes (i 8 mask)
      (when (= h (ldb (byte 8 (* 8 i)) low))
        (setf mask (logior mask (ash 1 i))))
      (when (= h (ldb (byte 8 (* 8 i)) high))
        (setf mask (logior mask (ash 1 (+ i 8))))))))

(defun typedu64 (low high h)
  "SWAR su due u64; non è SIMD hardware. Restituisce un fixnum mask16."
  (declare (type u64 low high) (type h7 h))
  (let ((repeated (* h +ones+)))
    (declare (type u64 repeated))
    (logior (comprimi8 (zeri-esatti (logxor low repeated)))
            (ash (comprimi8 (zeri-esatti (logxor high repeated))) 8))))

(defun packedmask16 (ctrl start h)
  "Include il packing dei 16 byte in due parole LE, a safety 3."
  (declare (type octets ctrl) (type fixnum start) (type h7 h))
  (finestra ctrl start)
  (typedu64 (pack8-le ctrl start) (pack8-le ctrl (+ start 8)) h))

(defun mutante-sottrazione (low high h)
  "Mutante conservato: il prestito genera falsi bit di match. Mai nel BENCH."
  (declare (type u64 low high) (type h7 h))
  (let ((repeated (* h +ones+)))
    (labels ((word-mask (word)
               (let ((x (logxor word repeated)))
                 (comprimi8 (logand +high+ (lognot x)
                                    (logand +u64-mask+ (- x +ones+)))))))
      (logior (word-mask low) (ash (word-mask high) 8)))))

(defun oracle (ctrl start h)
  "Indipendente: byte, classificazione alto bit e somma di potenze di due."
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

(defun limite-intero (value low high name)
  (unless (and (integerp value) (<= low value high))
    (error 'errore-impronte :motivo (list :invalid-limit name value low high))))

(defun limite-secondi (seconds)
  (unless (and (realp seconds) (< 0 seconds) (<= seconds 300))
    (error 'errore-impronte :motivo (list :invalid-limit :seconds seconds))))

(defun deadline (seconds)
  (+ (get-internal-real-time) (ceiling (* seconds internal-time-units-per-second))))

(declaim (inline rispetta-tempo))
(defun rispetta-tempo (end)
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

(defun valida-bench (rows passes warmup-passes seconds byte-budget)
  "Preflight condiviso; permette di verificare rifiuti senza eseguire BENCH."
  (limite-intero rows 16 8192 :rows)
  (limite-intero passes 1 1024 :passes)
  (limite-intero warmup-passes 1 64 :warmup-passes)
  (limite-secondi seconds)
  (limite-intero byte-budget 1 67108864 :byte-budget)
  (let ((payload (* rows 104)) ; 2 datasets * (32+1+1+8+8+2) byte/riga.
        (operations (* 8 rows (+ warmup-passes (* 5 passes)))))
    (when (> payload byte-budget)
      (error 'errore-impronte :motivo :payload-budget))
    (when (> operations 200000000)
      (error 'errore-impronte :motivo :operation-budget))
    (values payload operations)))

(defun prepara-matrice (rows dataset)
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

(macrolet ((definisci-ciclo (name expression)
  ;; Quattro cicli diretti; nessuna macro globale ridefinita al caricamento.
  `(defun ,name (m passes end)
     (declare (type matrice m) (type fixnum passes end))
     (let ((ctrl (matrice-ctrl m)) (offsets (matrice-offsets m))
           (queries (matrice-queries m)) (low (matrice-low m)) (high (matrice-high m))
           (rows (matrice-rows m)) (acc 0) (operations 0))
       (declare (type octets ctrl offsets queries) (type words low high)
                (type fixnum rows acc operations) (ignorable ctrl offsets low high))
       (rispetta-tempo end)
       (let ((start-ticks (get-internal-real-time))
             (start-bytes (sb-ext:get-bytes-consed)))
         (dotimes (pass passes)
           (dotimes (row rows)
             (incf acc ,expression)
             (incf operations)
             (when (zerop (logand operations 4095)) (rispetta-tempo end))))
         (let* ((end-bytes (sb-ext:get-bytes-consed))
                (end-ticks (get-internal-real-time))
                (ticks (- end-ticks start-ticks)) (bytes (- end-bytes start-bytes)))
           (rispetta-tempo end)
           (unless (= acc (* passes (matrice-sum m)))
             (error 'errore-impronte :motivo (list :cycle-checksum ',name acc)))
           (values ticks bytes acc operations)))))))

(definisci-ciclo cycle-scalar16
  (scalar16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definisci-ciclo cycle-packedmask16
  (packedmask16 ctrl (+ (* row 32) (aref offsets row)) (aref queries row)))
(definisci-ciclo cycle-scalar-u64
  (scalar-u64 (aref low row) (aref high row) (aref queries row)))
(definisci-ciclo cycle-typedu64
  (typedu64 (aref low row) (aref high row) (aref queries row))))

(defun esegui-ciclo (kernel m passes end)
  "Dispatch prima della misura; il corpo del ciclo chiama direttamente il kernel."
  (ecase kernel
    (:scalar16 (cycle-scalar16 m passes end))
    (:packedmask16 (cycle-packedmask16 m passes end))
    (:scalar-u64 (cycle-scalar-u64 m passes end))
    (:typedu64 (cycle-typedu64 m passes end))))

(defun bench (&key (rows 1024) (passes 64) (warmup-passes 2)
                   (seconds 60) (byte-budget 16777216))
  "Matrice scalar/SWAR seriale, cinque repliche. Da eseguire soltanto nel parent."
  (multiple-value-bind (payload total-operations)
      (valida-bench rows passes warmup-passes seconds byte-budget)
    (let* ((end (deadline seconds))
           (mixed (prepara-matrice rows :mixed))
           (adversarial (prepara-matrice rows :adversarial))
           (measurements nil) (observable 0) (warmup-operations 0))
      (rispetta-tempo end)
      (loop for m in (list mixed adversarial) do
        (dolist (kernel '(:scalar16 :packedmask16 :scalar-u64 :typedu64))
          (multiple-value-bind (ticks bytes checksum operations)
              (esegui-ciclo kernel m warmup-passes end)
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
                  (esegui-ciclo kernel m passes end)
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
      (rispetta-tempo end)
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

(defun rifiuto-dinamico (function args expected-condition input)
  "Argomenti negativi opachi al compilatore; verifica l'assenza di mutazione."
  (let ((before (copy-seq input)) (caught nil))
    (handler-case (apply (symbol-function function) args)
      (error (c)
        (unless (typep c expected-condition) (error c))
        (setf caught (type-of c))))
    (unless (and caught (equalp before input))
      (error 'errore-impronte :motivo (list :negative-control function args)))
    (list :function function :arguments args :condition caught :input-unchanged t)))

(defun check (&key (max-cases 4000000) (differential-cases 20000) (seconds 120))
  "Campagne esaustive/differenziali limitate, oracle indipendente e mutante."
  (limite-intero max-cases 1 4000000 :max-cases)
  (limite-intero differential-cases 1 100000 :differential-cases)
  (limite-secondi seconds)
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
               (when (zerop (logand cases 4095)) (rispetta-tempo end))
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
               (push (rifiuto-dinamico function args condition ctrl) negatives)))
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
      ;; Argomenti invalidi: controlli del runtime a safety 3, byte sorgenti immutati.
      (dolist (function '(scalar16 packedmask16))
        (dolist (h '(-1 128 255 1/2 :bad))
          (negative function (list ctrl 0 h) 'type-error))
        (dolist (start '(-1 49 64))
          (negative function (list ctrl start 0) 'errore-impronte))
        (dolist (start '(1/2 :bad))
          (negative function (list ctrl start 0) 'type-error))
        (dolist (length '(0 1 15))
          (let ((short (make-array length :element-type '(unsigned-byte 8))))
            (push (rifiuto-dinamico function (list short 0 0) 'errore-impronte short)
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
      (negative 'rispetta-tempo (list (get-internal-real-time)) 'errore-impronte)
      (dolist (args '((15 1 1 60 16777216) (8193 1 1 60 16777216)
                      (16 0 1 60 16777216) (16 1025 1 60 16777216)
                      (16 1 0 60 16777216) (16 1 65 60 16777216)
                      (16 1 1 0 16777216) (16 1 1 301 16777216)
                      (16 1 1 60 0) (16 1 1 60 67108865)
                      (16 1 1 60 1) (8192 1024 64 60 67108864)))
        (negative 'valida-bench args 'errore-impronte))
      (rispetta-tempo end)
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
