(in-package #:arcdocdb.fulltext.document)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-007
(declaim (ftype (function (simple-vector) simple-vector) copia-campi-documento))
(defun copia-campi-documento (fields)
  "Pre: forma e budget gia verificati. Post: copie possedute, testi UTF-8 verificati.
Nessun buffer o vettore del chiamante viene trattenuto."
  (let ((result (make-array (length fields))))
    (dotimes (i (length fields) result)
      (let* ((field (svref fields i)) (alias (svref field 1)) (path (svref field 2))
             (copy (make-array (length path))))
        (arcdocdb.utf8:verifica-utf8 alias 0 (length alias))
        (dotimes (j (length path))
          (let ((key (svref path j)))
            (arcdocdb.utf8:verifica-utf8 key 0 (length key))
            (setf (svref copy j) (copy-seq key))))
        (setf (svref result i) (%campo-full-text (svref field 0) (copy-seq alias) copy))))))

;;; REQ: REQ-SEC-003 REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (t t t t &key (:limits t) (:profile t) (:max-memory t)) configurazione-full-text)
                crea-configurazione-full-text))
(defun crea-configurazione-full-text (fields index-id generation-id contract-version
                                    &key (limits #(16777216 1024 1048576 67108864 268435456))
                                      (profile c::+profile+) (max-memory 67108864))
  "Pre: ID positivi gia assegnati; FIELDS=#(#(id alias-u8 #(key-u8 ...)) ...), ordinati.
LIMITS=#(input-bytes term-bytes tokens prepared-bytes work), cinque u64 positivi.
Post: dichiarazione copiata immutabile e bound META conservativo, senza autorita di catalogo.
INVALID-ARGUMENT per forma/duplicati, UNSUPPORTED-FORMAT per profilo;
RESOURCE-EXHAUSTED prima di copiare oltre META/memoria; propaga errori UTF-8."
  (unless (and (typep fields 'simple-vector) (<= 1 (length fields) 16)
               (typep index-id '(integer 1 18446744073709551615))
               (typep generation-id '(integer 1 18446744073709551615))
               (typep contract-version '(integer 1 18446744073709551615))
               (typep limits '(simple-vector 5)) (typep profile 'octets) (typep max-memory 'index))
    (error 'invalid-argument :reason :fulltext-config-input))
  (dotimes (i 5)
    (unless (typep (svref limits i) '(integer 1 18446744073709551615))
      (error 'invalid-argument :reason :fulltext-config-limits)))
  (when (> (svref limits 2) #xffffffff) (error 'invalid-argument :reason :fulltext-config-token-limit))
  (unless (equalp profile c::+profile+) (error 'unsupported-format :reason :fulltext-profile))
  (multiple-value-bind (meta memory) (misure-campi-documento fields max-memory)
    (unless (<= memory max-memory) (error 'invariant-violation :reason :fulltext-config-memory-result))
    (controlla-duplicati-configurazione fields)
    (let ((identity (make-array 24 :element-type '(unsigned-byte 8) :initial-element 0))
          (declared (make-array 5 :element-type 'u64)) (effective (make-array 5 :element-type 'fixnum)))
      (scrivi-u64 identity 0 index-id) (scrivi-u64 identity 8 generation-id) (scrivi-u64 identity 16 contract-version)
      (dotimes (i 5) (setf (aref declared i) (svref limits i)
                          (aref effective i) (min most-positive-fixnum (svref limits i))))
      (%configurazione-full-text identity (copia-campi-documento fields) declared effective meta))))

;;; REQ: REQ-SEC-010
(declaim (ftype (function (t) index) limite-fisso-indice-full-text))
(defun limite-fisso-indice-full-text (config)
  "Pre: dichiarazione validata. Post: header/directory, META massimo della dichiarazione,
35 byte padding e footer; riservare una volta per segmento, poi sommare U(documento).
INVALID-ARGUMENT per tipo, INVARIANT-VIOLATION per bound interno incoerente."
  (unless (typep config 'configurazione-full-text) (error 'invalid-argument :reason :fulltext-config-input))
  (unless (<= 1 (configurazione-full-text-meta-bound config) f::+meta-max-bytes+)
    (error 'invariant-violation :reason :fulltext-config-meta-bound))
  (+ f::+sections-offset+ (configurazione-full-text-meta-bound config) 35 f::+footer-bytes+))
