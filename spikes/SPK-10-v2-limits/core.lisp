;;;; Integrazione C4 dei quattro esperimenti v2. Non è il motore.
;;; REQ: REQ-VAL-001 REQ-LIM-001 REQ-LIM-002 REQ-LIM-003
(defpackage #:arcdocdb.spk10 (:use #:cl) (:export #:check #:benchmark))
(in-package #:arcdocdb.spk10)
(declaim (optimize (safety 3) (speed 2) (debug 1)))

(define-condition integration-error (error)
  ((messaggio :initarg :messaggio :reader messaggio))
  (:report (lambda (condizione stream) (write-string (messaggio condizione) stream))))

(defparameter *moduli*
  '("ARCDOCDB.SPK10.CODEC" "ARCDOCDB.SPK10.INDICE"
    "ARCDOCDB.SPK10.CBOR" "ARCDOCDB.SPK10.MIGRAZIONE"))

(defun funzione-modulo (nome api)
  "Risolve soltanto le API dichiarate dei moduli caricati dal runner."
  (let* ((package (find-package nome))
         (symbol (and package (find-symbol api package))))
    (unless (and symbol (fboundp symbol))
      (error 'integration-error :messaggio (format nil "API ~A::~A assente." nome api)))
    (symbol-function symbol)))

(defun esigi-integrazione (condizione contesto)
  "Un oracle fallito interrompe la prova, conservata dall'harness."
  (unless condizione
    (error 'integration-error :messaggio (format nil "Integrazione v2: ~A." contesto)))
  nil)

(defun documento-fixture (tipo)
  "Mappe CBOR deterministiche; la fixture massima conta anche i sette byte di cornice."
  (ecase tipo
    (:breve (make-array 4 :element-type '(unsigned-byte 8)
                          :initial-contents '(#xa1 0 #x81 0)))
    (:profondita-100
     (let ((buffer (make-array 102 :element-type '(unsigned-byte 8) :initial-element #x81)))
       (setf (aref buffer 0) #xa1 (aref buffer 1) 0 (aref buffer 101) 0)
       buffer))
    (:documento-16mib
     (let* ((totale 16777216) (payload (- totale 7))
            (buffer (make-array totale :element-type '(unsigned-byte 8) :initial-element 0)))
       (setf (aref buffer 0) #xa1 (aref buffer 1) 0 (aref buffer 2) #x5a)
       (dotimes (n 4) (setf (aref buffer (+ 3 n)) (ldb (byte 8 (* 8 (- 3 n))) payload)))
       buffer))))

;;; REQ: REQ-VAL-001 REQ-LIM-001 REQ-LIM-002 REQ-LIM-003 REQ-FOR-002
(defun test-req-val-001-integration ()
  "Collega fileheader, codec, CBOR, hint e indice; nessun I/O o commit durevole."
  (let ((casi 0) (assertioni 0) (massimo-record 0))
    (dolist (tipo '(:breve :profondita-100 :documento-16mib))
      (let ((documento (documento-fixture tipo)))
        (dolist (versione '(1 2))
          (dolist (key-len (if (= versione 1) '(1 255) '(1 255 256 65535)))
            (let* ((chiave (make-array key-len :element-type '(unsigned-byte 8) :initial-element 17))
                   (csn #xfffffffffffffff0)
                   ;; Il formato v1 non rappresenta il documento massimo: il suo
                   ;; totale u24 include header e chiave. Questi casi sono omessi.
                   (compatibile (or (= versione 2) (not (eq tipo :documento-16mib)))))
              (when compatibile
                (let* ((record (arcdocdb.spk10.codec:costruisci-record versione chiave documento csn))
                       (totale (length record))
                       (header (arcdocdb.spk10.migrazione:costruisci-fileheader :versione versione))
                       (segmento (make-array (+ 64 totale) :element-type '(unsigned-byte 8)
                                                             :initial-element 0))
                       (indice (arcdocdb.spk10.indice:make-indice :capacity 8 :maintenance-seconds 3))
                       (hint (arcdocdb.spk10.codec:costruisci-hint-entry
                              versione 64 totale csn 0 key-len)))
                  (replace segmento header) (replace segmento record :start1 64)
                  (esigi-integrazione (= versione (arcdocdb.spk10.migrazione:versione-fileheader segmento))
                                      "versione del file")
                  (incf assertioni)
                  (let* ((parser-v1 (lambda () (arcdocdb.spk10.codec:verifica-record
                                                1 segmento 64 (length segmento) chiave csn totale)))
                         (parser-v2 (lambda () (arcdocdb.spk10.codec:verifica-record
                                                2 segmento 64 (length segmento) chiave csn totale)))
                         (parser (arcdocdb.spk10.migrazione:seleziona-parser segmento parser-v1 parser-v2)))
                    (esigi-integrazione (eq parser (if (= versione 1) parser-v1 parser-v2)) "selezione parser")
                    (incf assertioni)
                    (multiple-value-bind (inizio fine stamp) (funcall parser)
                      (esigi-integrazione (and (= stamp csn) (= inizio (+ 64 24 key-len))
                                               (= fine (length segmento))) "offset e CSN del codec")
                      (incf assertioni)
                      ;; Copia esplicita del solo harness: il validatore attuale
                      ;; accetta un vettore intero, non un intervallo del segmento.
                      (let ((esito (arcdocdb.spk10.cbor:valida-documento (subseq segmento inizio fine))))
                        (esigi-integrazione (and (eq :ok (getf esito :status))
                                                 (= (getf esito :depth) (if (eq tipo :profondita-100) 100
                                                                          (if (eq tipo :breve) 2 1))))
                                            "documento e profondita CBOR")
                        (incf assertioni))))
                  (let ((entry (arcdocdb.spk10.codec:verifica-hint-entry
                                versione hint 0 24 key-len (length segmento))))
                    (esigi-integrazione (and (= (getf entry :offset) 64) (= (getf entry :lunghezza) totale)
                                             (= (getf entry :csn) csn) (= (getf entry :key-len) key-len)
                                             (not (getf entry :prepared))) "metadati hint")
                    (incf assertioni))
                  (esigi-integrazione (arcdocdb.spk10.indice:inserisci indice chiave csn 1 64 totale)
                                      "inserimento dopo verifica")
                  (incf assertioni)
                  (multiple-value-bind (stamp location lunghezza stato) (arcdocdb.spk10.indice:leggi indice chiave)
                    (esigi-integrazione (and (eq stato :hit) (= stamp csn) (= location #x100000040)
                                             (= lunghezza totale)) "entry dell'indice")
                    (incf assertioni))
                  (setf massimo-record (max massimo-record totale)) (incf casi))))))))
    ;; CRC validi non implicano CBOR valido. Il codec verifica prima il record;
    ;; il validatore deve poi rilevare la codifica non minima dell'intero zero.
    (let* ((chiave (make-array 1 :element-type '(unsigned-byte 8) :initial-element 1))
           (documento (make-array 2 :element-type '(unsigned-byte 8) :initial-contents '(#x18 0)))
           (record (arcdocdb.spk10.codec:costruisci-record 2 chiave documento 1)))
      (multiple-value-bind (inizio fine) (arcdocdb.spk10.codec:verifica-record 2 record 0 (length record)
                                                                           chiave 1 (length record))
        (handler-case
            (progn (arcdocdb.spk10.cbor:valida-documento (subseq record inizio fine))
                   (esigi-integrazione nil "CBOR non minimo accettato"))
          (arcdocdb.spk10.cbor:errore-cbor (c)
            (esigi-integrazione (eq :nonminimal (arcdocdb.spk10.cbor:ragione c)) "rifiuto CBOR")
            (incf assertioni)))))
    (list :status :ok :positive-cases casi :assertions assertioni :negative-cases 1
          :document-bytes '(4 102 16777216) :depths '(2 100 1)
          :key-lengths '(1 255 256 65535) :maximum-record-bytes massimo-record
          :limits '(:ordinary-put-only :test-only-value-copy :no-storage-or-durable-commit
                    :hint-section-crc-not-integrated :v1-max-document-not-representable))))

(defun check ()
  "Conserva gli esiti indipendenti; non promuove il gate del motore."
  (let ((risultati (loop for nome in *moduli*
                        collect (list :module nome
                                      :result (funcall (funzione-modulo nome "CHECK"))))))
    (dolist (r risultati)
      (unless (eq :ok (getf (getf r :result) :status))
        (error 'integration-error :messaggio (format nil "Check v2 fallito: ~S" r))))
    (list :spike :spk-10 :status :ok :format-version 2 :modules risultati
          :integration (test-req-val-001-integration)
          :production-gate-complete nil)))

(defun benchmark ()
  "Esegue i benchmark dei moduli in serie; il modello non produce throughput."
  (let ((verifica (check)))
    (list :spike :spk-10 :status :ok :format-version 2 :check verifica
          :measurements
          (loop for nome in (butlast *moduli*)
                collect (list :module nome
                              :result (funcall (funzione-modulo nome "BENCHMARK"))))
          :limits '(:local-environment :experimental-components
                    :no-real-filesystem-migration :no-reference-platform-claim))))
