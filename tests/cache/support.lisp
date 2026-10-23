;;;; Fixture C4 della pubblicazione cache; record e attesi indipendenti dai writer.
;;; OWNER: controller prima/dopo i thread; ogni worker possiede buffer e risultati.
;;; SHARED: sola cache della fixture; entry e record immutabili durante le prove.
(defpackage #:arcdocdb.cache.tests
  (:use #:cl)
  (:local-nicknames (#:c #:arcdocdb.cache))
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:export #:run #:*tests*))
(in-package #:arcdocdb.cache.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  "Esegue ogni caso registrato; un errore propaga al runner isolato."
  (dolist (test (reverse *tests*))
    (funcall test)
    (format t "ok    ~A~%" test))
  (format t "~D test della pubblicazione cache superati.~%" (length *tests*))
  t)

(defstruct cache-entry
  record key value segment-high segment-low offset csn-high csn-low version)

(defun new-cache ()
  "Una classe, un insieme di otto posti, una striscia; budget del solo payload."
  (c:crea-cache-serie
   (make-array 1 :element-type '(unsigned-byte 32) :initial-element 8192)
   (make-array 1 :element-type '(unsigned-byte 32) :initial-element 1)
   70000 :stripes 1))

(defun cache-fixture-entry (version ordinal value-bytes)
  "Chiave e valore attesi distinti dalla copia record, CSN oltre 32 bit."
  (let ((key (make-array 16 :element-type '(unsigned-byte 8)))
        (value (make-array value-bytes :element-type '(unsigned-byte 8)))
        (csn-high (+ #x8ace0000 ordinal)) (csn-low (- #xfedcba98 ordinal)))
    (dotimes (i 16) (setf (aref key i) (mod (+ ordinal (* 19 i)) 256)))
    (dotimes (i value-bytes)
      (setf (aref value i) (mod (+ 17 (* 41 ordinal) (* 73 i)) 256)))
    (let ((image (arcdocdb.get.performance.tests::performance-image
                  version key value (logior (ash csn-high 32) csn-low))))
      (make-cache-entry
       :record (subseq image 64 (+ 64 40 value-bytes)) :key key :value value
       :segment-high (+ #x13579bdf ordinal) :segment-low (+ #x80000001 (* 17 ordinal))
       :offset (+ 64 (* 8192 ordinal)) :csn-high csn-high :csn-low csn-low
       :version version))))

(defun cache-fixture (version &key (count 32) (value-bytes 4096))
  "Cache fredda e vettore di record immutabili, tutti diretti allo stesso insieme."
  (unless (and (member version '(1 2)) (typep count '(integer 1 256))
               (member value-bytes '(16 4096)))
    (error "Configurazione non valida della fixture cache: ~S/~S/~S."
           version count value-bytes))
  (let ((entries (make-array count)))
    (dotimes (i count)
      (setf (aref entries i) (cache-fixture-entry version i value-bytes)))
    (values (new-cache) entries)))

(defun cache-class (cache)
  "Accesso FI del controller; mai usato per decidere un hit atteso."
  (aref (c::cache-serie-classes cache) 0))

(defun cache-insert (cache entry &key scan-p)
  "API pubblica senza riscrivere gli esiti o il record input."
  (c:inserisci-record-cache
   cache (cache-entry-segment-high entry) (cache-entry-segment-low entry)
   (cache-entry-offset entry) (length (cache-entry-record entry)) (cache-entry-key entry)
   (cache-entry-csn-high entry) (cache-entry-csn-low entry) 0
   (cache-entry-record entry) 0 :version (cache-entry-version entry) :scan-p scan-p))

(defun cache-buffer (entries)
  "Destinazione privata con tre sentinelle su ciascun lato del record più lungo."
  (make-array (+ 6 (loop for entry across entries maximize (length (cache-entry-record entry))))
              :element-type '(unsigned-byte 8) :initial-element #xcc))

(defun cache-read (cache entry destination)
  "Sonda pubblica, copia a offset tre; preserva i tre valori originali."
  (c:cerca-record-cache
   cache (cache-entry-segment-high entry) (cache-entry-segment-low entry)
   (cache-entry-offset entry) (length (cache-entry-record entry)) (cache-entry-key entry)
   (cache-entry-csn-high entry) (cache-entry-csn-low entry) 0
   destination 3 :version (cache-entry-version entry)))

(defun cache-check-sentinels (entry destination)
  "Controlla entrambi i confini anche quando lo scratch centrale è da scartare."
  (is (loop for i below 3 always (= #xcc (aref destination i))))
  (is (loop for i from (+ 3 (length (cache-entry-record entry))) below (length destination)
            always (= #xcc (aref destination i)))))

(defun cache-check-read (cache entry destination)
  "Ogni HIT confronta record e valore completi; MISS ammette byte provvisori.
Solo :HIT/:MISS: VERIFY-FAILED con input validi fa fallire la prova."
  (fill destination #xcc)
  (multiple-value-bind (status begin end) (cache-read cache entry destination)
    (cache-check-sentinels entry destination)
    (ecase status
      (:miss (is (zerop begin)) (is (zerop end)))
      (:hit
       (is (= 43 begin))
       (is (= (+ begin (length (cache-entry-value entry))) end))
       (is (loop for i below (length (cache-entry-record entry))
                 always (= (aref (cache-entry-record entry) i) (aref destination (+ 3 i)))))
       (is (loop for i below (length (cache-entry-value entry))
                 always (= (aref (cache-entry-value entry) i) (aref destination (+ begin i)))))))
    status))
