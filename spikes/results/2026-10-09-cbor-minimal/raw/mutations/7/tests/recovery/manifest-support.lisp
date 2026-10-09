;;;; Fixture EDIT indipendenti: packing bytewise e modello a liste del manifest.
(in-package #:arcdocdb.recovery.tests)

(defun manifest-spec (&key completo (next-id 0) (open 0) chiusi rimossi)
  "Fatto logico dichiarato: chiusi = (id valid-bytes ((txid csn)...))."
  (list :completo completo :next-id next-id :open open :chiusi chiusi :rimossi rimossi))

(defun reference-manifest-payload (spec)
  "Layout EDIT indipendente da encoder, decoder e costanti del prodotto."
  (let* ((closed (getf spec :chiusi)) (removed (getf spec :rimossi))
         (size (+ 24 (* 8 (length removed))
                  (loop for entry in closed sum (+ 20 (* 16 (length (third entry)))))))
         (body (make-array size :element-type '(unsigned-byte 8) :initial-element 0))
         (pos 20))
    (reference-le body 0 8 (getf spec :next-id))
    (reference-le body 8 8 (getf spec :open))
    (reference-le body 16 4 (length closed))
    (dolist (entry closed)
      (destructuring-bind (id valid outcomes) entry
        (reference-le body pos 8 id) (reference-le body (+ pos 8) 8 valid)
        (reference-le body (+ pos 16) 4 (length outcomes))
        (incf pos 20)
        (dolist (outcome outcomes)
          (reference-le body pos 8 (first outcome))
          (reference-le body (+ pos 8) 8 (second outcome))
          (incf pos 16))))
    (reference-le body pos 4 (length removed))
    (incf pos 4)
    (dolist (id removed) (reference-le body pos 8 id) (incf pos 8))
    (is (= size pos))
    body))

(defun reference-manifest-record (spec stamp version)
  "Cornice EDIT con flag completo e CRC bitwise senza encoder del prodotto."
  (reference-record 5 stamp (bytes) (reference-manifest-payload spec)
                    :version version :flags (if (getf spec :completo) 8 0)))

(defun reference-manifest-seal (records start file-offset durable stamp version)
  "SEAL di control.log: file-id zero, posizioni e CRC di cornici indipendenti."
  (let ((body (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))
        (checksum 0))
    (dolist (record records) (setf checksum (reference-crc record 0 4 checksum)))
    (reference-le body 8 8 (+ file-offset start))
    (reference-le body 16 8 durable)
    (reference-le body 24 4 (length records))
    (reference-le body 28 4 checksum)
    (reference-record 3 stamp (bytes) body :version version)))

(defun manifest-record-log-fixture (batches &key (version 2) (prefix 7) (file-offset 64)
                                               durables stamps)
  "Liste di cornici raw; SEAL corretto anche per payload semanticamente invalido.
Restituisce buffer/start/end/layouts, ciascuno con :records, :seal e :end noti."
  (let ((chunks nil) (layouts nil) (pos prefix))
    (loop for records in batches for number from 0 do
      (let ((start pos) (positions nil))
        (dolist (record records)
          (push pos positions) (push record chunks) (incf pos (length record)))
        (let* ((seal-start pos)
               (seal (reference-manifest-seal records start file-offset
                         (if durables (nth number durables) (+ file-offset start))
                         (if stamps (nth number stamps) 17) version)))
          (push seal chunks) (incf pos (length seal))
          (push (list :start start :records (nreverse positions) :seal seal-start :end pos)
                layouts))))
    (let ((buffer (make-array pos :element-type '(unsigned-byte 8) :initial-element #xcc))
          (next prefix))
      (dolist (chunk (nreverse chunks))
        (replace buffer chunk :start1 next) (incf next (length chunk)))
      (values buffer prefix pos (nreverse layouts)))))

(defun manifest-log-fixture (batches &key (version 2) (prefix 7) (file-offset 64) durables stamps)
  "Liste di fatti logici; EDIT e SEAL nello stesso lotto condividono lo stamp."
  (manifest-record-log-fixture
   (loop for batch in batches for number from 0 collect
     (mapcar (lambda (spec) (reference-manifest-record spec
                             (if stamps (nth number stamps) 17) version)) batch))
   :version version :prefix prefix :file-offset file-offset :durables durables :stamps stamps))

(defun repair-manifest-batch (buffer layout)
  "Ripara solo fixture note dopo alterazione semantica, incluso CRC aggregato."
  (let ((records (getf layout :records)) (seal (getf layout :seal)) (checksum 0))
    (loop for remaining on records for start = (first remaining)
          for end = (if (rest remaining) (second remaining) seal)
          do (repair-reference-record buffer start end)
             (setf checksum (reference-crc buffer start (+ start 4) checksum)))
    (reference-le buffer (+ seal 52) 4 checksum)
    (repair-reference-record buffer seal (getf layout :end))))

(defun manifest-fixture-read (buffer start end
                             &key (version 2) (file-offset 64) (file-size (+ file-offset end))
                                  (max-bytes 67108864) (max-batches 65536)
                                  (max-batch-records 65536) (max-batch-bytes 67108864)
                                  (max-search-bytes 67108864) (max-edits 65536)
                                  (max-segmenti 65536) (max-esiti 65536)
                                  (max-chiusi-per-edit 65536) (max-rimossi-per-edit 65536)
                                  (max-esiti-per-edit 65536) (max-metadata-bytes 16777216))
  "Invoca solo l'API pubblica con EOF completo e tutti i budget espliciti."
  (arcdocdb.recovery.manifest:ricostruisci-manifest buffer start end
    :version version :file-offset file-offset :file-size file-size
    :max-bytes max-bytes :max-batches max-batches :max-batch-records max-batch-records
    :max-batch-bytes max-batch-bytes :max-search-bytes max-search-bytes
    :max-edits max-edits :max-segmenti max-segmenti :max-esiti max-esiti
    :max-chiusi-per-edit max-chiusi-per-edit :max-rimossi-per-edit max-rimossi-per-edit
    :max-esiti-per-edit max-esiti-per-edit :max-metadata-bytes max-metadata-bytes))

(defun manifest-model-row (id state &optional (valid 0) outcomes)
  "Entry del modello a liste: nessuna struttura, sort o accessore del prodotto."
  (list id state valid (remove-duplicates (copy-tree outcomes) :key #'first :test #'eql)))

(defun manifest-oracle (specs)
  "Fold dichiarativo a mappe/insiemi su storie valide, senza decodifica dei byte."
  (let ((active 0) (next 0) (rows nil))
    (dolist (spec specs)
      (when (getf spec :completo)
        (setf rows nil active 0 next (getf spec :next-id)))
      (dolist (entry (getf spec :chiusi))
        (setf rows (cons (manifest-model-row (first entry) :closed
                                            (second entry) (third entry))
                         (remove (first entry) rows :key #'first :test #'eql))))
      (dolist (id (getf spec :rimossi))
        (setf rows (cons (manifest-model-row id :removed)
                         (remove id rows :key #'first :test #'eql))))
      (unless (zerop (getf spec :open))
        (setf active (getf spec :open)
              rows (cons (manifest-model-row active :active)
                         (remove active rows :key #'first :test #'eql))))
      (let ((maximum (loop for row in rows maximize (first row))))
        (setf next (if (or (zerop next) (= maximum #xffffffffffffffff)) 0
                       (max next (1+ maximum))))))
    (list :active active :next next :rows rows)))

(defun assert-manifest-model (manifest expected &optional (unknown-ids '(1024 1025)))
  "Compare solo query scalari pubbliche al modello; CSN zero resta distinto da assenza."
  (let ((rows (getf expected :rows)) (next (getf expected :next)))
    (is (= (getf expected :active) (arcdocdb.recovery.manifest:segmento-attivo manifest)))
    (is (equal (list (not (zerop next)) next)
               (multiple-value-list (arcdocdb.recovery.manifest:prossimo-id-segmento manifest))))
    (is (= (count :closed rows :key #'second)
           (arcdocdb.recovery.manifest:numero-segmenti-chiusi manifest)))
    (is (= (count :removed rows :key #'second)
           (arcdocdb.recovery.manifest:numero-segmenti-rimossi manifest)))
    (dolist (row rows)
      (destructuring-bind (id state valid outcomes) row
        (is (equal (list state valid (length outcomes))
                   (multiple-value-list (arcdocdb.recovery.manifest:trova-segmento manifest id))))
        (dolist (outcome outcomes)
          (is (equal (list t (second outcome))
                     (multiple-value-list
                       (arcdocdb.recovery.manifest:trova-esito-chiusura
                         manifest id (first outcome))))))
        (dolist (txid '(1024 1025))
          (is (null (assoc txid outcomes)))
          (is (equal '(nil 0) (multiple-value-list
                               (arcdocdb.recovery.manifest:trova-esito-chiusura
                                 manifest id txid)))))))
    (dolist (id unknown-ids)
      (is (null (assoc id rows)))
      (is (equal '(:unknown 0 0)
                 (multiple-value-list (arcdocdb.recovery.manifest:trova-segmento manifest id))))
      (is (equal '(nil 0) (multiple-value-list
                           (arcdocdb.recovery.manifest:trova-esito-chiusura manifest id 0)))))))

(defun manifest-basic-history ()
  "Rotazione, output compaction prenotato prima del checkpoint, MERGE e rimozione."
  (list (manifest-spec :completo t :next-id 100 :open 10
                       :chiusi '((1 64 ((0 0) (7 17))) (2 512 nil)) :rimossi '(3))
        (manifest-spec :open 101 :chiusi '((10 256 ((8 19)))))
        (manifest-spec :chiusi '((4 128 nil)) :rimossi '(1 2))
        (manifest-spec :open 104 :chiusi '((101 512 ((9 20) (10 20)))))
        (manifest-spec :chiusi '((102 128 nil)) :rimossi '(4 101))
        (manifest-spec :rimossi '(102))))
