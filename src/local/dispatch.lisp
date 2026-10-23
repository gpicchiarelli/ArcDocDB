;;; OWNER: stesso attore del motore; buffer di risposta gia' riservato alla connessione.
;;; SHARED: nessun lease/pin esce da questa chiamata; attesa peer soltanto dopo il ritorno.
(in-package #:arcdocdb.local)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IPC-002 REQ-REC-001 REQ-AFF-008
(defun local-record-validator (space)
  "Pre: scratch privato della startup. Post: callback readonly per tutto il prefisso committed.
Rifiuta archivi incompatibili prima del checkpoint o listener, inclusi valori storici."
  (lambda (kind buffer ks ke vs ve)
    (unless (<= 1 (- ke ks) 1024)
      (error 'arcdocdb.conditions:unsupported-format :reason :local-stored-key-budget))
    (when (= kind arcdocdb.record:+put+)
      (unless (<= 1 (- ve vs) 60000)
        (error 'arcdocdb.conditions:unsupported-format :reason :local-stored-document-budget))
      (arcdocdb.cbor:verifica-struttura-cbor-minima buffer vs ve space
        :max-bytes 60000 :max-nodes 60000 :max-depth 100))
    nil))

;;; REQ: REQ-IPC-002 REQ-WAL-006 REQ-IDX-001
(defun local-execute (engine connection id opcode key document)
  "Pre: argomenti validati, ID ammesso, risposta massima gia' riservata. Post: frame terminale.
PUT/DELETE rispondono dopo strong; GET termina la copia e libera pin prima dell'invio."
  (let ((out (local-connection-output connection)))
    (case opcode
      (0 (encode-local-response out id 0))
      (1 (encode-local-response out id 0 :csn (e:scrivi-documento engine key document)))
      (2 (multiple-value-bind (status size)
             (e:leggi-documento engine key (local-connection-value connection))
           (encode-local-response out id 0 :found (eq status :found)
             :document (local-connection-value connection) :document-end size)))
      (3 (encode-local-response out id 0 :csn (e:cancella-documento engine key)))
      (otherwise (error 'arcdocdb.conditions:invariant-violation :reason :local-dispatch-opcode)))))

;;; REQ: REQ-IPC-002 REQ-LIM-003 REQ-AFF-004
(defun local-dispatch (engine connection envelope)
  "Pre: envelope e ID validi; un solo owner, buffer privati. Post: risposta oppure guasto propagato.
Solo RESOURCE-EXHAUSTED con motore ancora READY e' un rifiuto prima dell'ammissione.
Un guasto ammesso non viene tradotto in busy; il servizio chiude preservando la causa."
  (let ((id (envelope-id envelope)) (opcode (envelope-code envelope))
        (out (local-connection-output connection)))
    (multiple-value-bind (status key document)
        (decode-local-command (local-connection-input connection) envelope (local-connection-space connection))
      (cond
        ((plusp status) (encode-local-response out id status))
        ((not (eq :ready (e:stato-motore engine))) (encode-local-response out id 3))
        ((and (= opcode 2) (< (local-connection-limit connection) 60032))
         (encode-local-response out id 5))
        (t (handler-case (local-execute engine connection id opcode key document)
             (arcdocdb.conditions:resource-exhausted (condition)
               (unless (eq :ready (e:stato-motore engine)) (error condition))
               (encode-local-response out id 2))))))))
