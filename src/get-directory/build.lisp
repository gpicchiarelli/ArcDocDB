;;; OWNER: controller/pool I/O prima della pubblicazione; input esclusivo e stabile.
;;; SHARED: nessuna radice pubblicata viene modificata o file aperto/chiuso qui.
(in-package #:arcdocdb.get.directory)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(declaim (ftype (function (t t t) index) verifica-configurazione-directory-get))
(defun verifica-configurazione-directory-get (maps maximum budget)
  "Pre: input e budget del caller. Post: cardinalità finita ammessa PRIMA di scansioni/array.
INVALID-ARGUMENT per forma/configurazione; RESOURCE-EXHAUSTED per segmenti/payload.
Nessun ordinamento implicito, nuova apertura, espansione o allocazione di array."
  (unless (and (typep maximum 'index) (<= 1 maximum +directory-max-segments+)
               (typep budget 'index))
    (error 'invalid-argument :reason :directory-configuration))
  (unless (typep maps 'simple-vector) (error 'invalid-argument :reason :directory-maps))
  (let ((count (length maps)))
    (when (> count maximum) (error 'resource-exhausted :reason :directory-segment-budget))
    (when (> (* count +directory-entry-bytes+) budget)
      (error 'resource-exhausted :reason :directory-payload-budget))
    count))

;;; REQ: REQ-IDX-001 REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (vista-get-serie t u32) u32) verifica-mappa-directory-get))
(defun verifica-mappa-directory-get (view map previous)
  "Pre: input stabile, ID precedente zero o positivo. Post: mappa canonica CLOSED e ID crescente.
INVALID-ARGUMENT per tipo, vista, ID, ordine o FD non readonly/aperto.
Non tronca ID storage u64 e non certifica identità fisica, salute o quiescenza dei FD."
  (unless (typep map 'mappa-segmento-get) (error 'invalid-argument :reason :directory-maps))
  (let* ((segment (mappa-segmento-get-segment map)) (id (segmento-get-low segment)))
    (unless (eq view (segmento-get-owner segment))
      (error 'invalid-argument :reason :directory-source-owner))
    (unless (and (zerop (segmento-get-high segment)) (plusp id))
      (error 'invalid-argument :reason :directory-source-segment))
    (unless (and (eq :input (mode-file (segmento-get-file segment)))
                 (eq :open (stato-file (segmento-get-file segment))))
      (error 'invalid-argument :reason :directory-source-lifetime))
    (unless (> id previous) (error 'invalid-argument :reason :directory-source-order))
    id))

;;; REQ: REQ-IDX-001 REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (vista-get-serie t &key (:max-segments t) (:budget-payload t))
                         directory-get-serie) crea-directory-get-serie))
(defun crea-directory-get-serie (view maps &key (max-segments 65536) (budget-payload 786432))
  "Pre: controller, simple-vector di mappe CLOSED ordinate, stabile/esclusivo fino al ritorno.
Post: directory completa, due array copiati/posseduti; input riusabile, zero segmenti valido.
Budget/identità/ordine/FD controllati prima di allocare; errori typed non pubblicano parziali.
Il controller acquisisce/pubblica la directory con EBR, separatamente dalle location del primary."
  (let ((count (verifica-configurazione-directory-get maps max-segments budget-payload)) (previous 0))
    (declare (type u32 previous))
    (dotimes (i count) (setf previous (verifica-mappa-directory-get view (svref maps i) previous)))
    (let ((ids (make-array count :element-type '(unsigned-byte 32) :initial-element 0))
          (owned (copy-seq maps)))
      (setf previous 0)
      (dotimes (i count)
        (setf previous (verifica-mappa-directory-get view (svref owned i) previous)
              (aref ids i) previous))
      (unless (= count (length ids) (length owned))
        (error 'invariant-violation :reason :directory-built-shape))
      (%make-directory-get-serie view ids owned))))
