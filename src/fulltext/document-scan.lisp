(in-package #:arcdocdb.fulltext.document)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text index) null) azzera-frame-documento))
(defun azzera-frame-documento (task top)
  "Pre: nuovo frame CBOR entro i 102 slot. Post: nessun percorso ereditato da frame riusati."
  (unless (< top 102) (error 'invariant-violation :reason :fulltext-document-frame))
  (setf (aref (preparazione-full-text-masks task) top) 0
        (aref (preparazione-full-text-pending task) top) 0
        (aref (preparazione-full-text-seen task) top) 0
        (aref (preparazione-full-text-levels task) top) 0)
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text index index index index (unsigned-byte 3) boolean) null)
                tratta-nodo-documento))
(defun tratta-nodo-documento (task top kind remaining payload major tagged)
  "Pre: nodo CBOR verificato; stato del padre catturato prima dello step.
Post: solo span/corrispondenze su chiavi semplici, nessun AST o conversione in Lisp."
  (let ((scratch (preparazione-full-text-cbor task)))
    (when (> (cb::spazio-cbor-top scratch) top) (azzera-frame-documento task (1+ top)))
    (case kind
      (0
       (unless (= major 5) (error 'invalid-argument :reason :fulltext-document-root))
       (setf (aref (preparazione-full-text-masks task) 1)
             (1- (ash 1 (length (preparazione-full-text-present task))))))
      (2
       (if (evenp remaining)
           (if (= major 3)
               (seleziona-chiave-documento task top payload (cb::spazio-cbor-cursor scratch) tagged)
               (setf (aref (preparazione-full-text-pending task) top) 0))
           (seleziona-valore-documento task top major payload (cb::spazio-cbor-cursor scratch) tagged)))
      (1 nil)
      (otherwise (error 'invariant-violation :reason :fulltext-document-cbor-kind))))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text) null) nodo-documento))
(defun nodo-documento (task)
  "Pre: root non conclusa. Post: un nodo minimo/UTF-8, lavoro riservato prima del kernel.
Le stringhe usano il kernel CBOR esistente: al piu lo span del documento per passo.
Lunghezze ostili non diventano indici/costi u64; il kernel le rifiuta prima del payload."
  (let* ((scratch (preparazione-full-text-cbor task)) (lead (cb::spazio-cbor-cursor scratch))
         (end (preparazione-full-text-end task)) (input (preparazione-full-text-input task))
         (top (cb::spazio-cbor-top scratch)) (kind (aref (cb::spazio-cbor-kinds scratch) top))
         (remaining (aref (cb::spazio-cbor-remaining scratch) top)) (tagged (cb::spazio-cbor-pending-tag scratch)))
    (multiple-value-bind (major ai high low payload form) (cb:leggi-header-cbor-minimo input lead end)
      (declare (ignore ai)) ; minimalita verificata dal lettore; non e un esito.
      (unless (eq form :argument) (error 'invariant-violation :reason :fulltext-document-header-form))
      (lavoro-documento task (+ 1 (* 2 (- payload lead))
                               (if (and (member major '(2 3)) (zerop high) (<= low (- end payload))) low 0)))
      (cb::passo-struttura-cbor input scratch end (preparazione-full-text-node-limit task) 100 t)
      (tratta-nodo-documento task top kind remaining payload major tagged)))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text) null) passo-scansione-documento))
(defun passo-scansione-documento (task)
  "Pre: SCAN esclusivo. Post: un nodo o FIELD dopo conclusione integrale e coda assente.
Risultati/spans parziali rimangono privati fino alla preparazione completa."
  (let ((scratch (preparazione-full-text-cbor task)))
    (lavoro-documento task)
    (if (cb::svuota-frame-cbor scratch (preparazione-full-text-end task))
        (progn
          (unless (and (= (cb::spazio-cbor-cursor scratch) (preparazione-full-text-end task))
                       (zerop (cb::spazio-cbor-top scratch)))
            (error 'invariant-violation :reason :fulltext-document-scan-result))
          (setf (preparazione-full-text-phase task) :field))
        (nodo-documento task)))
  nil)
