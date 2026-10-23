;;;; Fixture DECISION indipendenti: packing bytewise e oracolo per mappe/insiemi.
(in-package #:arcdocdb.recovery.tests)

(defun participant-id (number &optional (first-byte 0))
  "ID16 di test: prefisso esplicito e numero negli ultimi otto byte big-endian."
  (let ((id (make-array 16 :element-type '(unsigned-byte 8) :initial-element 0)))
    (setf (aref id 0) first-byte)
    (dotimes (i 8) (setf (aref id (- 15 i)) (ldb (byte 8 (* i 8)) number)))
    id))

(defun decision-spec (txid csn participants)
  "Operazione logica dichiarata dalla fixture, senza strutture del prodotto."
  (list txid csn participants))

(defun reference-decision-record (spec version)
  "Payload little-endian e cornice con CRC bitwise, senza encoder del prodotto."
  (destructuring-bind (txid csn participants) spec
    (let ((body (make-array (+ 10 (* 16 (length participants)))
                            :element-type '(unsigned-byte 8) :initial-element 0)))
      (reference-le body 0 8 csn)
      (reference-le body 8 2 (length participants))
      (loop for id in participants for i from 0
            do (replace body id :start1 (+ 10 (* 16 i))))
      (reference-record 6 txid (bytes) body :version version))))

(defun reference-decision-seal (records start file-offset durable stamp version)
  "SEAL indipendente: file-id zero, count fisico e CRC dei CRC delle cornici."
  (let ((body (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))
        (checksum 0))
    (dolist (record records) (setf checksum (reference-crc record 0 4 checksum)))
    (reference-le body 8 8 (+ file-offset start))
    (reference-le body 16 8 durable)
    (reference-le body 24 4 (length records))
    (reference-le body 28 4 checksum)
    (reference-record 3 stamp (bytes) body :version version)))

(defun repair-decision-batch (buffer layout)
  "Ripara le sole fixture note dopo una mutazione semantica, incluso batch-crc."
  (let ((records (getf layout :records)) (seal (getf layout :seal)) (checksum 0))
    (loop for remaining on records for start = (first remaining)
          for end = (if (rest remaining) (second remaining) seal)
          do (repair-reference-record buffer start end)
             (setf checksum (reference-crc buffer start (+ start 4) checksum)))
    (reference-le buffer (+ seal 52) 4 checksum)
    (repair-reference-record buffer seal (getf layout :end))))

(defun decision-record-log-fixture (batches &key (version 2) (prefix 7) (file-offset 64)
                                               durables (seal-stamp 17))
  "BATCHES contiene cornici indipendenti, anche con payload semanticamente invalido.
Restituisce buffer/start/end/layouts noti, sempre con SEAL e CRC corretti.
Ogni layout porta :start, :records (offset nel buffer), :seal, :end."
  (let ((chunks nil) (layouts nil) (pos prefix))
    (loop for records in batches for batch-number from 0 do
      (let ((start pos) (positions nil))
        (dolist (record records)
          (push pos positions) (push record chunks) (incf pos (length record)))
        (let* ((seal-start pos)
               (seal (reference-decision-seal records start file-offset
                         (if durables (nth batch-number durables) (+ file-offset start))
                         seal-stamp version)))
          (push seal chunks) (incf pos (length seal))
          (push (list :start start :records (nreverse positions) :seal seal-start :end pos)
                layouts))))
    (let ((buffer (make-array pos :element-type '(unsigned-byte 8) :initial-element #xcc))
          (next prefix))
      (dolist (chunk (nreverse chunks))
        (replace buffer chunk :start1 next) (incf next (length chunk)))
      (values buffer prefix pos (nreverse layouts)))))

(defun decision-log-fixture (batches &key (version 2) (prefix 7) (file-offset 64)
                                        durables (seal-stamp 17))
  "BATCHES contiene liste di spec; packing e SEAL indipendenti dal prodotto."
  (decision-record-log-fixture
   (mapcar (lambda (batch)
             (mapcar (lambda (spec) (reference-decision-record spec version)) batch)) batches)
   :version version :prefix prefix :file-offset file-offset
   :durables durables :seal-stamp seal-stamp))

(defun decision-fixture-read (buffer start end
                             &key (version 2) (file-offset 64) (file-size (+ file-offset end))
                                  (max-bytes 67108864) (max-batches 65536)
                                  (max-batch-records 65536) (max-batch-bytes 67108864)
                                  (max-search-bytes 67108864) (max-decisions 65536)
                                  (max-participants 65536) (max-participants-per-decision 65535))
  "Invoca la ricostruzione con ogni opzione una sola volta ed EOF esplicito."
  (arcdocdb.recovery.decisions:ricostruisci-decisioni buffer start end
    :version version :file-offset file-offset :file-size file-size
    :max-bytes max-bytes :max-batches max-batches :max-batch-records max-batch-records
    :max-batch-bytes max-batch-bytes :max-search-bytes max-search-bytes
    :max-decisions max-decisions :max-participants max-participants
    :max-participants-per-decision max-participants-per-decision))

(defun decision-oracle (specs)
  "Mappe e insiemi logici: non decodifica byte e non usa sort/fold del prodotto."
  (let ((entries nil))
    (dolist (spec specs)
      (unless (assoc (first spec) entries)
        (push (list (first spec) (second spec)
                    (remove-duplicates (third spec) :test #'equalp)) entries)))
    entries))

(defun assert-decision-table (table specs &optional (missing-txids '(1024 1025)))
  "Confronta solo API pubbliche con l'oracolo dichiarativo, senza accessori privati."
  (let ((expected (decision-oracle specs)))
    (is (= (length expected) (arcdocdb.recovery.decisions:numero-decisioni table)))
    (dolist (entry expected)
      (destructuring-bind (txid csn participants) entry
        (is (equal (list t csn (length participants))
                   (multiple-value-list (arcdocdb.recovery.decisions:trova-decisione table txid))))
        (dolist (id participants)
          (is (arcdocdb.recovery.decisions:partecipante-decisione-p table txid id 0 16)))))
    (dolist (txid missing-txids)
      (is (null (assoc txid expected)))
      (is (equal '(nil 0 0)
                 (multiple-value-list (arcdocdb.recovery.decisions:trova-decisione table txid)))))))

(defun permute-decisions (items seed)
  "Permutazione Fisher-Yates con LCG locale: seme esplicito, nessuno stato random."
  (let ((array (coerce items 'vector)))
    (loop for i downfrom (1- (length array)) above 0 do
      (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))
      (rotatef (aref array i) (aref array (mod seed (1+ i)))))
    (coerce array 'list)))
