;;; OWNER: writer con gettone della Serie; array digest privati prenotati dal controller.
;;; SHARED: legge soltanto la root corrente e il sorgente; nessun coordinamento tra Serie.
(in-package #:arcdocdb.index.primary)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-IDX-005 REQ-LIM-003 REQ-AFF-004
(declaim (ftype (function (fixnum t t t t) null) esigi-mappe-hash))
(defun esigi-mappe-hash (capacity highs lows seed-high seed-low)
  "Pre: capacita della Serie. Post: mappe u32 distinte di C elementi e seme in due u32.
INVALID-ARGUMENT prima di ogni allocazione/scrittura: :primary-hash-arrays o :primary-hash-seed."
  (unless (and (typep highs 'digests-frammento) (typep lows 'digests-frammento)
               (= capacity (length highs)) (= capacity (length lows)) (not (eq highs lows)))
    (error 'invalid-argument :reason :primary-hash-arrays))
  (unless (and (typep seed-high 'u32) (typep seed-low 'u32))
    (error 'invalid-argument :reason :primary-hash-seed))
  nil)

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-IDX-005 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (indice-primario frammento-indice t t t t)
                         (values fixnum fixnum fixnum &optional)) calcola-digests-frammento))
(defun calcola-digests-frammento (index source highs lows seed-high seed-low)
  "Pre: writer esclusivo, sorgente pubblicato corrente, mappe u32 private e seme della Serie.
Post: digest XXH64 agli slot fisici vivi, altri elementi invariati; tre valori C, vivi, byte chiave.
I due u32 del seme devono uguagliare la configurazione immutabile dell'indice, prima delle mappe.
Root, banco, arena e revisione invariati. Alloca due scratch fissi di cinque u64: manutenzione.
Rifiuti preflight senza scritture; seed incoerente => INVALID-ARGUMENT, corruzione => FAULTED.
Su rifiuto durante la scansione scartare le mappe parziali private; nessun rollback dell'indice."
  (esigi-indice-sano index)
  (esigi-sorgente-directory index (acquisisci-root index) source)
  (let ((capacity (indice-primario-capacity index)))
    (esigi-mappe-hash capacity highs lows seed-high seed-low)
    (multiple-value-bind (expected-high expected-low) (esigi-seme-hash index)
      (unless (and (= expected-high seed-high) (= expected-low seed-low))
        (error 'invalid-argument :reason :primary-hash-seed-mismatch)))
    (when (> (frammento-indice-used source) (length (frammento-indice-arena source)))
      (guasto-indice index :primary-rebuild-arena-used))
    (let ((words (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0))
          (work (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0))
          (live 0) (bytes 0) (arena (frammento-indice-arena source)))
      (declare (type fixnum live bytes))
      (dotimes (slot capacity)
        (when (campiona-ricostruzione source slot words)
          (let ((offset (ldb (byte 32 0) (aref words 2))) (size (ldb (byte 16 32) (aref words 2))))
            (multiple-value-bind (high low)
                (hash-con-seme-indice index arena offset (+ offset size) seed-high seed-low)
              ;; Il seme e il digest sono interni: una discordanza non e input esterno.
              (handler-case (verifica-digest-ricostruzione source slot high low words work)
                (invalid-argument () (guasto-indice index :primary-hash-source-digest)))
              (setf (aref (the digests-frammento highs) slot) high
                    (aref (the digests-frammento lows) slot) low))
            (incf live) (incf bytes size))))
      (unless (= live (frammento-indice-live source)) (guasto-indice index :primary-rebuild-live-count))
      (values capacity live bytes))))
