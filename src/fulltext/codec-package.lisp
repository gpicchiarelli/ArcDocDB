;;;; Codec completo del file derivato, senza I/O o pubblicazione di generazioni.
;;; REQ: REQ-SEC-008 REQ-SEC-010
(defpackage #:arcdocdb.fulltext.codec
  (:use #:cl)
  (:local-nicknames (#:f #:arcdocdb.fulltext.format) (#:a #:arcdocdb.fulltext.analysis)
                    (#:r #:arcdocdb.fulltext.index))
  (:import-from #:arcdocdb.binary #:octets #:index #:u16 #:u32 #:u64
                #:leggi-u16 #:leggi-u32 #:leggi-u64 #:scrivi-u16 #:scrivi-u32 #:scrivi-u64 #:crc32c)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument #:resource-exhausted
                #:corruption-detected #:unsupported-format #:invariant-violation)
  (:import-from #:arcdocdb.fulltext.format #:+dict-width+ #:+dict-term-length+ #:+dict-term-offset+
                #:+dict-first-posting+ #:+dict-posting-count+ #:+posting-width+ #:+posting-frequency+
                #:+posting-first-position+ #:+position-width+ #:+length-width+ #:+length-field+ #:+length-count+)
  (:export #:descrittore-full-text #:crea-descrittore-full-text
           #:spazio-codec-full-text #:crea-spazio-codec-full-text
           #:dimensione-indice-full-text #:scrivi-indice-full-text #:verifica-indice-full-text
           #:vista-indice-full-text #:crea-vista-indice-full-text #:corrisponde-riga-indice-full-text))
(in-package #:arcdocdb.fulltext.codec)
(declaim (optimize (safety 3) (debug 2)))
(deftype vettore-u32 () '(simple-array (unsigned-byte 32) (*)))
;;; REQ: REQ-SEC-008
;;; OWNER: caricamento modulo, immutabile. SHARED: sole letture fra Serie.
;;; REQ: REQ-SEC-007 REQ-SEC-008
(defparameter +profile+
  (map '(simple-array (unsigned-byte 8) (*)) #'char-code "unicode-word-18.0.0-v1"))

;;; REQ: REQ-SEC-008
(defstruct (descrittore-full-text
             (:constructor %descrittore-full-text (meta identity segment-box rows fields term-limit token-limit))
             (:copier nil))
  "Autorita copiata dal chiamante: META canonico e mappa dei PUT gia risolti.
Non verifica il formato dell'hint o il replay dei record; mai una prova di readiness."
  (meta (make-array 0 :element-type '(unsigned-byte 8)) :type octets :read-only t)
  (identity (make-array 0 :element-type '(unsigned-byte 8)) :type octets :read-only t)
  ;; Il CAR conserva l'intero boxed freddo: leggere un raw slot u64 puo allocare su x86-64.
  (segment-box (list 0) :type (cons u64 null) :read-only t)
  (rows #* :type simple-bit-vector :read-only t)
  (fields (make-array 0 :element-type 'u32) :type vettore-u32 :read-only t)
  (term-limit 1 :type u64 :read-only t) (token-limit 1 :type u32 :read-only t))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index index octets index index) boolean) span-uguali-p))
(defun span-uguali-p (x a b y c d)
  "Pre: span validi immutabili. Post: uguaglianza esatta dei byte, senza copie."
  (and (= (- b a) (- d c))
       (loop for i below (- b a) always (= (aref x (+ a i)) (aref y (+ c i))))))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (descrittore-full-text u16) boolean) campo-dichiarato-p))
(defun campo-dichiarato-p (descriptor field)
  "Pre: descrittore validato. Post: appartenenza ai massimo 16 campi dichiarati."
  (not (null (find field (descrittore-full-text-fields descriptor) :test #'=))))
