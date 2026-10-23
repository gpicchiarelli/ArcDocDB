;;;; Segmenti compattati: fixture manuali, senza encoder o resolver di prodotto.
(in-package #:arcdocdb.storage.tests)

;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-FOR-003 REQ-CMP-009
(defun compaction-record (kind key value &key (stamp 0) (flags 0))
  "Cornice manuale: packing little-endian e CRC bitwise indipendente."
  (let ((record (zeros (+ 24 (length key) (length value)))))
    (setf (aref record 8) kind (aref record 9) flags)
    (pack-le record 10 (length key) 2)
    (pack-le record 12 (length value) 4)
    (pack-le record 16 stamp 8)
    (replace record key :start1 24)
    (replace record value :start1 (+ 24 (length key)))
    (pack-le record 4 (reference-crc record 24 (length record)) 4)
    (pack-le record 0 (reference-crc record 4 24) 4)
    record))

;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-CMP-009
(defun compaction-fixture (records &key (version 2) (origin 2) (tail (bytes)))
  "Header-oracle et record manuali; confini ricavati dalle fixture dichiarate."
  (let* ((serie (bytes #x80 #xff #x00 #xa5 4 5 6 7 8 9 10 11 12 13 14 15))
         (segment-id #xfedcba9876543210)
         (valid (+ 64 (loop for record in records sum (length record))))
         (buffer (zeros (+ valid (length tail))))
         (position 64) (boundaries (list 64)))
    (replace buffer (header-oracle version origin serie segment-id #xffffffffffffffff))
    (dolist (record records)
      (replace buffer record :start1 position)
      (incf position (length record))
      (push position boundaries))
    (replace buffer tail :start1 valid)
    (values buffer valid serie segment-id (nreverse boundaries))))

;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-FOR-003 REQ-AFF-008 REQ-CMP-009
(defun compaction-assert-result (buffer valid serie segment-id expected &rest options)
  "Confronta tutti i valori pubblici e conserva input, identità e coda fisica."
  (let ((before (copy-seq buffer)) (serie-before (copy-seq serie)))
    (is (equal expected
               (multiple-value-list
                (apply #'arcdocdb.storage.format:verifica-segmento-compattato
                       buffer valid serie segment-id options))))
    (is (equalp before buffer))
    (is (equalp serie-before serie))))

;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-FOR-003 REQ-AFF-008 REQ-CMP-009
(defun compaction-expect-error (buffer valid serie segment-id type reason &rest options)
  "Errore del tipo atteso, nessun risultato parziale e tutti gli input invariati."
  (let ((before (copy-seq buffer)) (serie-before (copy-seq serie))
        (returned :not-returned) (caught nil))
    (handler-case
        (setf returned
              (multiple-value-list
               (apply #'arcdocdb.storage.format:verifica-segmento-compattato
                      buffer valid serie segment-id options)))
      (error (condition)
        (is (typep condition type))
        (when reason (is (eq reason (arcdocdb.conditions:error-reason condition))))
        (setf caught t)))
    (is caught)
    (is (eq returned :not-returned))
    (is (equalp before buffer))
    (is (equalp serie-before serie))))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(defun compaction-repair-file-crc (buffer)
  "Ripara solo il CRC dell'header, tramite l'oracolo bitwise."
  (pack-le buffer 56 (reference-crc buffer 0 56) 4))

;;; REQ: REQ-FOR-003
(defun compaction-repair-record-crc (buffer start)
  "Ripara solo il CRC della cornice per isolare campi semantici invalidi."
  (pack-le buffer start (reference-crc buffer (+ start 4) (+ start 24)) 4))

;;; REQ: REQ-FOR-002 REQ-AFF-008
(deftest test-REQ-FOR-002-compaction-empty-headers
  (dolist (version '(1 2))
    (multiple-value-bind (buffer valid serie segment-id)
        (compaction-fixture nil :version version)
      (compaction-assert-result buffer valid serie segment-id (list 64 version 0 0 0))
      (compaction-assert-result buffer valid serie segment-id (list 64 version 0 0 0)
                                :max-bytes 64 :max-records 0))))

;;; REQ: REQ-CMP-009 REQ-FOR-003
(deftest test-REQ-CMP-009-compaction-resolved-records-and-counts
  (let ((records (list (compaction-record 1 (bytes #xff) (bytes #xa0) :flags 4 :stamp 0)
                       (compaction-record 2 (bytes #x80) (bytes) :stamp #xffffffffffffffff)
                       (compaction-record 1 (bytes 1 2 3) (bytes #x82 1 2) :stamp 1)
                       (compaction-record 2 (bytes #xff) (bytes) :stamp 0))))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer valid serie segment-id boundaries)
          (compaction-fixture records :version version)
        (is (some (lambda (offset) (not (zerop (mod offset 4)))) boundaries))
        (compaction-assert-result buffer valid serie segment-id (list valid version 4 2 2))))))

;;; REQ: REQ-FOR-002 REQ-FOR-003
(deftest test-REQ-FOR-002-compaction-version-from-file
  (dolist (entry '((1 255) (2 256) (2 65535)))
    (destructuring-bind (version key-bytes) entry
      (let ((records (list (compaction-record 1
                                              (make-array key-bytes :element-type '(unsigned-byte 8)
                                                                    :initial-element #xa5)
                                              (bytes #x01) :stamp #x8000000000000000))))
        (multiple-value-bind (buffer valid serie segment-id)
            (compaction-fixture records :version version)
          (compaction-assert-result buffer valid serie segment-id (list valid version 1 1 0))
          (when (= key-bytes 256)
            (let ((copy (copy-seq buffer)))
              (pack-le copy 8 1 2)
              (compaction-repair-file-crc copy)
              (compaction-expect-error copy valid serie segment-id 'corruption-detected
                                       :v1-reserved))))))))

;;; REQ: REQ-FOR-003 REQ-CMP-009
(deftest test-REQ-FOR-003-compaction-every-content-truncation
  (let ((records (list (compaction-record 1 (bytes 1) (bytes #xa0))
                       (compaction-record 2 (bytes 2 3) (bytes))
                       (compaction-record 1 (bytes 4) (bytes #x82 1 2)))))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer valid serie segment-id boundaries)
          (compaction-fixture records :version version)
        (loop for limit from 64 to valid
              for count = (position limit boundaries)
              do (if count
                     (let ((puts (loop for record in records repeat count
                                       count (= 1 (aref record 8)))))
                       (compaction-assert-result buffer limit serie segment-id
                                                 (list limit version count puts (- count puts))))
                     (compaction-expect-error buffer limit serie segment-id
                                              'corruption-detected nil)))))))

;;; REQ: REQ-FOR-001 REQ-FOR-003
(deftest test-REQ-FOR-001-compaction-every-bit-corruption
  (dolist (version '(1 2))
    (multiple-value-bind (buffer valid serie segment-id)
        (compaction-fixture (list (compaction-record 1 (bytes #x80) (bytes #xa0))
                                  (compaction-record 2 (bytes #xff) (bytes)))
                            :version version)
      (dotimes (offset valid)
        (dotimes (bit 8)
          (let ((copy (copy-seq buffer)))
            (setf (aref copy offset) (logxor (ash 1 bit) (aref copy offset)))
            (compaction-expect-error copy valid serie segment-id 'corruption-detected nil)))))))

;;; REQ: REQ-FOR-002
(deftest test-REQ-FOR-002-compaction-authoritative-identities
  (dolist (version '(1 2))
    (multiple-value-bind (buffer valid serie segment-id)
        (compaction-fixture nil :version version)
      (dotimes (i 16)
        (let ((wrong (copy-seq serie)))
          (setf (aref wrong i) (logxor 1 (aref wrong i)))
          (compaction-expect-error buffer valid wrong segment-id 'corruption-detected
                                   :segment-identity)))
      (dolist (bit '(0 32 63))
        (compaction-expect-error buffer valid serie (logxor segment-id (ash 1 bit))
                                 'corruption-detected :segment-identity)))))

;;; REQ: REQ-FOR-002 REQ-FOR-001
(deftest test-REQ-FOR-002-compaction-header-fields-and-version
  (dolist (version '(1 2))
    (multiple-value-bind (buffer valid serie segment-id)
        (compaction-fixture nil :version version)
      (dolist (entry '((0 0 :segment-magic) (4 0 :segment-magic)
                       (10 0 :segment-origin) (10 3 :segment-origin)
                       (11 1 :segment-reserved) (48 1 :segment-reserved)
                       (60 1 :segment-reserved)))
        (destructuring-bind (offset byte reason) entry
          (let ((copy (copy-seq buffer)))
            (setf (aref copy offset) byte)
            (compaction-repair-file-crc copy)
            (compaction-expect-error copy valid serie segment-id 'corruption-detected reason))))
      (dolist (unknown '(0 3 65535))
        (let ((copy (copy-seq buffer)))
          (pack-le copy 8 unknown 2)
          (compaction-repair-file-crc copy)
          (compaction-expect-error copy valid serie segment-id 'unsupported-format :file-version)
          (setf (aref copy 56) (logxor 1 (aref copy 56)))
          (compaction-expect-error copy valid serie segment-id 'corruption-detected
                                   :segment-header-crc))))))

;;; REQ: REQ-CMP-009 REQ-FOR-002
(deftest test-REQ-CMP-009-compaction-rejects-writer-origin
  (dolist (version '(1 2))
    (multiple-value-bind (buffer valid serie segment-id)
        (compaction-fixture (list (compaction-record 1 (bytes 1) (bytes #xa0)))
                            :version version :origin 1)
      (compaction-expect-error buffer valid serie segment-id 'invalid-argument
                               :compaction-origin))))

;;; REQ: REQ-CMP-009
(deftest test-REQ-CMP-009-compaction-rejects-prepared-records
  (dolist (version '(1 2))
    (dolist (entry '((1 1) (1 5) (2 1)))
      (destructuring-bind (kind flags) entry
        (multiple-value-bind (buffer valid serie segment-id)
            (compaction-fixture
             (list (compaction-record 1 (bytes 1) (bytes #xa0))
                   (compaction-record kind (bytes 2) (if (= kind 1) (bytes #x01) (bytes))
                                      :flags flags :stamp #xffffffffffffffff))
             :version version)
          (compaction-expect-error buffer valid serie segment-id 'corruption-detected
                                   :compaction-prepared))))))

;;; REQ: REQ-CMP-009 REQ-FOR-003
(deftest test-REQ-CMP-009-compaction-rejects-control-records
  (let ((seal (zeros 32)) (outcome (zeros 8)) (edit (zeros 24)) (decision (zeros 42)))
    (pack-le seal 0 #xfedcba9876543210 8)
    (pack-le seal 8 64 8) (pack-le seal 16 64 8)
    (pack-le outcome 0 #xffffffffffffffff 8)
    (pack-le decision 0 19 8) (pack-le decision 8 2 2)
    (pack-le decision 10 1 16) (pack-le decision 26 2 16)
    (dolist (version '(1 2))
      (dolist (entry (list (list 3 seal) (list 4 outcome) (list 5 edit) (list 6 decision)))
        (multiple-value-bind (buffer valid serie segment-id)
            (compaction-fixture
             (list (compaction-record 1 (bytes 1) (bytes #xa0))
                   (compaction-record (first entry) (bytes) (second entry) :stamp 19))
             :version version)
          (compaction-expect-error buffer valid serie segment-id 'corruption-detected
                                   :compaction-record-kind))))))

;;; REQ: REQ-FOR-003
(deftest test-REQ-FOR-003-compaction-crc-valid-invalid-type-and-flags
  (dolist (version '(1 2))
    (multiple-value-bind (buffer valid serie segment-id)
        (compaction-fixture (list (compaction-record 1 (bytes 1) (bytes #xa0)))
                            :version version)
      (dolist (kind '(0 7 255))
        (let ((copy (copy-seq buffer)))
          (setf (aref copy 72) kind)
          (compaction-repair-record-crc copy 64)
          (compaction-expect-error copy valid serie segment-id 'corruption-detected :record-type)))
      (dolist (flags '(2 8 16 128))
        (let ((copy (copy-seq buffer)))
          (setf (aref copy 73) flags)
          (compaction-repair-record-crc copy 64)
          (compaction-expect-error copy valid serie segment-id 'corruption-detected
                                   :record-flags))))))

;;; REQ: REQ-FOR-003
(deftest test-REQ-FOR-003-compaction-crc-valid-inconsistent-lengths
  (dolist (version '(1 2))
    (multiple-value-bind (buffer valid serie segment-id)
        (compaction-fixture (list (compaction-record 1 (bytes 1) (bytes #xa0)))
                            :version version)
      (dolist (entry '((10 0 2) (10 65535 2) (12 2 4) (12 4294967295 4)))
        (destructuring-bind (offset value width) entry
          (let ((copy (copy-seq buffer)))
            (pack-le copy (+ 64 offset) value width)
            (compaction-repair-record-crc copy 64)
            (compaction-expect-error copy valid serie segment-id 'corruption-detected nil))))
      (let ((copy (copy-seq buffer)))
        (setf (aref copy 72) 2)
        (compaction-repair-record-crc copy 64)
        (compaction-expect-error copy valid serie segment-id 'corruption-detected nil)))))

;;; REQ: REQ-FOR-001 REQ-CMP-009
(deftest test-REQ-FOR-001-compaction-ignores-physical-tail
  (let ((tail (concatenate '(simple-array (unsigned-byte 8) (*))
                           (bytes #xff #xff #xff)
                           (compaction-record 1 (bytes 1) (bytes #xa0) :flags 1)
                           (compaction-record 3 (bytes) (zeros 32)))))
    (dolist (version '(1 2))
      (dolist (records (list nil (list (compaction-record 2 (bytes 1) (bytes)))))
        (multiple-value-bind (buffer valid serie segment-id)
            (compaction-fixture records :version version :tail tail)
          (compaction-assert-result buffer valid serie segment-id
                                    (list valid version (length records) 0 (length records)))
          (compaction-expect-error buffer (1+ valid) serie segment-id 'corruption-detected nil))))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-compaction-exact-and-exhausted-budgets
  (dolist (version '(1 2))
    (multiple-value-bind (buffer valid serie segment-id)
        (compaction-fixture (list (compaction-record 1 (bytes 1) (bytes #xa0))
                                  (compaction-record 2 (bytes 2) (bytes)))
                            :version version)
      (compaction-assert-result buffer valid serie segment-id (list valid version 2 1 1)
                                :max-bytes valid :max-records 2)
      (compaction-expect-error buffer valid serie segment-id 'resource-exhausted
                               :compaction-byte-budget :max-bytes (1- valid) :max-records 2)
      (dolist (max-records '(0 1))
        (compaction-expect-error buffer valid serie segment-id 'resource-exhausted
                                 :compaction-record-budget :max-bytes valid
                                 :max-records max-records)))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-compaction-invalid-arguments
  (multiple-value-bind (buffer valid serie segment-id)
      (compaction-fixture nil :tail (bytes #xff))
    (dolist (invalid-valid (list -1 0 1 63 (1+ (length buffer)) 4294967296))
      (compaction-expect-error buffer invalid-valid serie segment-id 'invalid-argument
                               :compaction-arguments))
    (dolist (max-bytes '(0 1 63 4294967296))
      (compaction-expect-error buffer valid serie segment-id 'invalid-argument
                               :compaction-arguments :max-bytes max-bytes))
    (dolist (max-records (list -1 (1+ most-positive-fixnum)))
      (compaction-expect-error buffer valid serie segment-id 'invalid-argument
                               :compaction-arguments :max-records max-records))
    (dolist (id-bytes '(0 15 17))
      (compaction-expect-error buffer valid (zeros id-bytes) segment-id 'invalid-argument
                               :compaction-arguments))
    (compaction-assert-result buffer valid serie segment-id (list valid 2 0 0 0)
                              :max-bytes 4294967295 :max-records most-positive-fixnum)))
