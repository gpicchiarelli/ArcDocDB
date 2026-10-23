;;;; SWMR reale e bounded; non e un modello esaustivo di interleaving/barriere.
;;;; OWNER: writer unico per banco; ciascun reader possiede output e cella dei conteggi.
;;;; SHARED: banco della fixture e soli semafori del protocollo; main legge dopo JOIN.
(in-package #:arcdocdb.index.slots.tests)
(declaim (optimize (safety 3) (debug 3)))

;;; REQ: REQ-IDX-003 REQ-CON-004 REQ-AFF-008
(defstruct (slot-race (:constructor %make-slot-race) (:copier nil))
  "Pre: fixture privata costruita prima dei worker. Post: configurazione e handoff immutabili.
Il writer modifica solo BANK; i reader modificano celle disgiunte di COUNTS."
  (bank (crea-banco-slot :capacity 1) :type banco-slot :read-only t)
  (retained-p nil :type boolean :read-only t)
  (remove-p nil :type boolean :read-only t)
  (rounds 64 :type (integer 1 256) :read-only t)
  (burst 32 :type (integer 1 128) :read-only t)
  (samples 64 :type (integer 1 256) :read-only t)
  (readers 3 :type (integer 1 8) :read-only t)
  (deadline 0 :type integer :read-only t)
  (start (sb-thread:make-semaphore) :type sb-thread:semaphore :read-only t)
  (checkpoint (vector (sb-thread:make-semaphore) (sb-thread:make-semaphore)
                      (sb-thread:make-semaphore)) :type simple-vector :read-only t)
  (ready (sb-thread:make-semaphore) :type sb-thread:semaphore :read-only t)
  (finished (sb-thread:make-semaphore) :type sb-thread:semaphore :read-only t)
  (counts (make-array 0 :element-type t) :type simple-vector :read-only t))

;;; REQ: REQ-IDX-001 REQ-IDX-003
(declaim (ftype (function (slot-test-buffer (integer 1 65536) boolean) null)
                slot-fill-pattern))
(defun slot-fill-pattern (source id retained)
  "Pre: SOURCE privata del writer, ID bounded. Post: cinque parole correlate, CSN oltre fixnum.
Nessuna modifica di SOURCE mentre una primitiva di prodotto la sta leggendo."
  (let* ((csn (+ #x8000000000000000 id)) (key-length (1+ (mod id 257)))
         (document-length (1+ (mod id 11))))
    (setf (aref source 0) csn
          (aref source 1) (logior (ash (+ #x80000000 id) 32) (+ 64 (* id 64)))
          (aref source 2) (logior (ash 1 48) (ash key-length 32) (* id 17))
          (aref source 3) (+ +header-bytes+ key-length document-length)
          (aref source 4) (if retained (+ csn 100000) 0)))
  nil)

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-IDX-005
(declaim (ftype (function (slot-test-buffer boolean (integer 1 65536))
                         (integer 1 65536)) slot-check-pattern))
(defun slot-check-pattern (output retained maximum)
  "Pre: snapshot LIVE. Post: ogni campo deriva dallo stesso CSN; un campione torn causa fallimento.
Oracolo aritmetico C4 senza validatori, letture raw o helper di packing del prodotto."
  (let ((id (- (aref output 0) #x8000000000000000)))
    (is (<= 1 id maximum))
    (is (= (aref output 1) (+ (* (+ #x80000000 id) #x100000000) 64 (* id 64))))
    (is (= (aref output 2) (+ #x1000000000000 (* (1+ (mod id 257)) #x100000000)
                             (* id 17))))
    (is (= (aref output 3) (+ 24 (1+ (mod id 257)) (1+ (mod id 11)))))
    (is (= (aref output 4) (if retained (+ #x8000000000000000 id 100000) 0)))
    id))

;;; REQ: REQ-IDX-003 REQ-IDX-006 REQ-CON-004
(declaim (ftype (function (banco-slot slot-test-buffer boolean (integer 1 65536))
                         (values (integer 0 65536) (member :live :empty :retry-limit) &optional))
                slot-observe))
(defun slot-observe (bank output retained maximum)
  "Pre: output di un solo reader. Post: LIVE correlato; EMPTY/RETRY-LIMIT preservano ogni sentinel."
  (fill output #xcafebabedeadbeef)
  (let ((status (leggi-slot-v2 bank 0 output)))
    (case status
      (:live (values (slot-check-pattern output retained maximum) status))
      ((:empty :retry-limit)
       (is (every (lambda (word) (= word #xcafebabedeadbeef)) output))
       (values 0 status))
      (otherwise (error 'invariant-violation :reason :slot-test-read-status)))))

;;; REQ: REQ-CON-004 REQ-AFF-008
(declaim (ftype (function ((simple-array fixnum (3)) keyword) null) slot-count-status))
(defun slot-count-status (counts status)
  "Pre: conteggi di un solo reader. Post: incremento disgiunto e nessun esito ignorato."
  (case status
    (:live (incf (aref counts 0)))
    (:empty (incf (aref counts 1)))
    (:retry-limit (incf (aref counts 2)))
    (otherwise (error 'invariant-violation :reason :slot-test-count-status)))
  nil)

;;; REQ: REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (slot-race) null) slot-race-notify))
(defun slot-race-notify (race)
  "Pre: writer solo, un semaforo per reader. Post: un token di fase per ciascun reader.
Un reader veloce non puo consumare il checkpoint destinato a un altro reader."
  (is (= (slot-race-readers race) (length (slot-race-checkpoint race))))
  (dotimes (reader (slot-race-readers race))
    (sb-thread:signal-semaphore (svref (slot-race-checkpoint race) reader)))
  nil)

;;; REQ: REQ-IDX-003 REQ-IDX-006 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (slot-race) (eql :ok)) slot-race-writer))
(defun slot-race-writer (race)
  "Pre: writer unico della fixture. Post: pubblicazioni e rimozioni bounded, poi banco FROZEN.
Checkpoint senza scritture in corso obbligano i reader a osservare LIVE e, se richiesto, EMPTY."
  (let ((source (slot-buffer 0 0 0 0 0)) (bank (slot-race-bank race))
        (deadline (slot-race-deadline race)) (id 0))
    (slot-wait (slot-race-start race) deadline)
    (dotimes (round (slot-race-rounds race))
      (when (slot-race-remove-p race)
        (let ((result (rimuovi-slot-v2 bank 0))) (is (null result)))
        (slot-race-notify race)
        (dotimes (reader (slot-race-readers race)) (slot-wait (slot-race-ready race) deadline)))
      (slot-fill-pattern source (incf id) (slot-race-retained-p race))
      (let ((result (pubblica-slot-v2 bank 0 source))) (is (null result)))
      (slot-race-notify race)
      (dotimes (reader (slot-race-readers race)) (slot-wait (slot-race-ready race) deadline))
      (dotimes (mutation (slot-race-burst race))
        (slot-seconds-left deadline)
        (when (slot-race-remove-p race)
          (let ((result (rimuovi-slot-v2 bank 0))) (is (null result))))
        (slot-fill-pattern source (incf id) (slot-race-retained-p race))
        (let ((result (pubblica-slot-v2 bank 0 source))) (is (null result)))
        (sb-thread:thread-yield))
      (dotimes (reader (slot-race-readers race)) (slot-wait (slot-race-finished race) deadline)))
    (is (= id (* (slot-race-rounds race) (1+ (slot-race-burst race)))))
    (let ((result (congela-banco-slot bank))) (is (null result)))
    :ok))

;;; REQ: REQ-IDX-003 REQ-IDX-006 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (slot-race (integer 0 7)) (eql :ok)) slot-race-reader))
(defun slot-race-reader (race reader)
  "Pre: worker possiede output e sua cella COUNTS. Post: snapshot correlati e CSN mai regressivo.
Ogni checkpoint deve essere osservato: il test non puo passare vedendo soltanto retry."
  (let ((output (slot-buffer 0 0 0 0 0)) (counts (svref (slot-race-counts race) reader))
        (bank (slot-race-bank race)) (deadline (slot-race-deadline race)) (previous 0)
        (retained (slot-race-retained-p race))
        (maximum (* (slot-race-rounds race) (1+ (slot-race-burst race)))))
    (declare (type (simple-array fixnum (3)) counts))
    (slot-wait (slot-race-start race) deadline)
    (dotimes (round (slot-race-rounds race))
      (when (slot-race-remove-p race)
        (slot-wait (svref (slot-race-checkpoint race) reader) deadline)
        (multiple-value-bind (id status) (slot-observe bank output retained maximum)
          (is (zerop id)) (is (eq :empty status)) (slot-count-status counts status))
        (sb-thread:signal-semaphore (slot-race-ready race)))
      (slot-wait (svref (slot-race-checkpoint race) reader) deadline)
      (multiple-value-bind (id status) (slot-observe bank output retained maximum)
        (is (eq :live status))
        (is (= id (1+ (* round (1+ (slot-race-burst race))))))
        (is (> id previous)) (setf previous id)
        (slot-count-status counts status))
      (sb-thread:signal-semaphore (slot-race-ready race))
      (dotimes (sample (slot-race-samples race))
        (slot-seconds-left deadline)
        (multiple-value-bind (id status) (slot-observe bank output retained maximum)
          (when (eq :live status)
            (is (<= previous id (* (1+ round) (1+ (slot-race-burst race)))))
            (setf previous id))
          (unless (slot-race-remove-p race) (is (not (eq :empty status))))
          (slot-count-status counts status))
        (sb-thread:thread-yield))
      (sb-thread:signal-semaphore (slot-race-finished race)))
    :ok))

;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-IDX-006 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (boolean boolean) null) slot-parallel-snapshots))
(defun slot-parallel-snapshots (retained remove)
  "Pre: fixture di banco privata. Post: un writer e tre reader joined entro deadline verificata.
Cleanup terminate/join bounded su fallimento; nessuna evidenza prestazionale prodotta."
  (let* ((bank (crea-banco-slot :capacity 1 :retained-p retained))
         (counts (make-array 3 :element-type t))
         (race (%make-slot-race :bank bank :retained-p retained :remove-p remove
                                :deadline (slot-deadline 20) :counts counts))
         (threads nil))
    (dotimes (reader 3)
      (setf (svref counts reader) (make-array 3 :element-type 'fixnum :initial-element 0)))
    (unwind-protect
         (progn
           (dotimes (reader 3)
             (let ((id reader))
               (push (slot-worker (format nil "slot v2 reader ~D" id)
                                  (lambda () (slot-race-reader race id))) threads)))
           (push (slot-worker "slot v2 single writer" (lambda () (slot-race-writer race))) threads)
           (sb-thread:signal-semaphore (slot-race-start race) 4)
           (dolist (thread threads) (slot-join thread (slot-race-deadline race)))
           (let* ((writes (* (slot-race-rounds race) (1+ (slot-race-burst race))))
                  (mutations (+ writes (if remove (1- writes) 0)))
                  (source (slot-buffer 0 0 0 0 0)))
             (is (= (* 2 mutations) (slot-sequence bank 0)))
             (is (eq :frozen (arcdocdb.index.slots::banco-slot-state bank)))
             (is (eq :open (arcdocdb.index.slots::banco-slot-health bank)))
             (slot-fill-pattern source writes retained) (slot-read-equals bank 0 source))
           (dotimes (reader 3)
             (let ((observed (svref counts reader))
                   (expected (* (slot-race-rounds race)
                                (+ (slot-race-samples race) 1 (if remove 1 0)))))
               (is (= expected (reduce #'+ observed)))
               (is (>= (aref observed 0) (slot-race-rounds race)))
               (if remove (is (>= (aref observed 1) (slot-race-rounds race)))
                   (is (zerop (aref observed 1)))))))
      ;; Sblocca la partenza prima di reclamare i worker; nessuna attesa senza timeout.
      (sb-thread:signal-semaphore (slot-race-start race) 4)
      (slot-stop-workers threads)))
  nil)

;;; REQ: REQ-IDX-003 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-IDX-003-slot-primary-writer-three-readers-correlated-u64-snapshots
  (slot-parallel-snapshots nil nil))

;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-IDX-003-slot-retained-writer-three-readers-correlated-five-word-snapshots
  (slot-parallel-snapshots t nil))

;;; REQ: REQ-IDX-003 REQ-IDX-006 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-IDX-006-slot-retained-concurrent-remove-republish-preserves-empty-output
  (slot-parallel-snapshots t t))
