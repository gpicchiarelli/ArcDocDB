;;;; API di analisi riprendibile; nessuna dipendenza dalle tabelle del runtime.
;;; OWNER: un solo compito accede a SPACE e ai risultati presi in prestito.
;;; SHARED: l'input puo essere condiviso solo in lettura fino a DONE/errore.
(in-package #:arcdocdb.fulltext.analysis)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (t t t t t t t) null) verifica-avvio-analisi))
(defun verifica-avvio-analisi (space input start end max-term max-tokens max-work)
  "Pre: confine pubblico. Post: argomenti e stato ammessi senza mutazioni.
INVALID-ARGUMENT per tipi/limiti; analisi in corso non sovrascrivibile."
  (unless (and (typep space 'spazio-full-text) (typep input 'octets)
               (typep start 'index) (typep end 'index) (<= start end (length input))
               (typep max-term 'index) (plusp max-term)
               (typep max-tokens 'index) (plusp max-tokens)
               (<= max-tokens (length (spazio-full-text-begins space)))
               (typep max-work 'index) (plusp max-work))
    (error 'invalid-argument :reason :fulltext-analysis-arguments))
  (unless (member (spazio-full-text-phase space) '(:idle :done :failed))
    (error 'invalid-argument :reason :fulltext-analysis-busy))
  (when (> (- end start) 16777216) (error 'resource-exhausted :reason :fulltext-input-bytes))
  nil)

;;; REQ: REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (t t t t &key (:max-term-bytes t) (:max-tokens t) (:max-work t)) keyword)
                inizia-analisi-full-text))
(defun inizia-analisi-full-text (space input start end &key (max-term-bytes 1024)
                                (max-tokens 1048576) (max-work 268435456))
  "Pre: scratch esclusivo, input UTF-8 immutabile fino a completamento/errore.
Post: RUNNING; risultati precedenti invalidati. Controlli prima di mutare SPACE.
INVALID-ARGUMENT/RESOURCE-EXHAUSTED per configurazione non ammessa."
  (verifica-avvio-analisi space input start end max-term-bytes max-tokens max-work)
  (setf (spazio-full-text-input space) input (spazio-full-text-input-pos space) start
        (spazio-full-text-input-end space) end (spazio-full-text-phase space) :decode
        (spazio-full-text-pass space) 1 (spazio-full-text-a-count space) 0
        (spazio-full-text-b-count space) 0 (spazio-full-text-cursor space) 0
        (spazio-full-text-stack-top space) 0 (spazio-full-text-byte-count space) 0
        (spazio-full-text-token-count space) 0 (spazio-full-text-work space) 0
        (spazio-full-text-term-limit space) max-term-bytes (spazio-full-text-token-limit space) max-tokens
        (spazio-full-text-work-limit space) max-work (spazio-full-text-nfc-only space) nil)
  :running)

;;; REQ: REQ-SEC-007
(declaim (ftype (function (spazio-full-text) null) passo-decodifica-full-text))
(defun passo-decodifica-full-text (space)
  "Pre: input preso in prestito. Post: uno scalare validato o inizio NFC.
CORRUPTION-DETECTED per UTF-8 non canonico; nessuna sostituzione silenziosa."
  (if (= (spazio-full-text-input-pos space) (spazio-full-text-input-end space))
      (setf (spazio-full-text-phase space) :decompose (spazio-full-text-cursor space) 0)
      (multiple-value-bind (scalar next)
          (arcdocdb.utf8:leggi-scalare-utf8 (spazio-full-text-input space)
                                         (spazio-full-text-input-pos space) (spazio-full-text-input-end space))
        (setf (spazio-full-text-a-count space)
              (aggiungi-scalare space (spazio-full-text-a space) (spazio-full-text-a-count space) scalar)
              (spazio-full-text-input-pos space) next)))
  nil)

;;; REQ: REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (spazio-full-text) null) avanza-analisi-full-text))
(defun avanza-analisi-full-text (space)
  "Pre: analisi in corso. Post: un passo limitato; fasi inattese sono errori interni."
  (consuma-lavoro-full-text space)
  (case (spazio-full-text-phase space)
    (:decode (passo-decodifica-full-text space)) (:decompose (passo-decomposizione-nfc space))
    (:reorder (passo-riordino-nfc space)) (:compose (passo-composizione-nfc space))
    (:fold (passo-case-folding space)) (:left (passo-contesto-sinistro space))
    (:right (passo-contesto-destro space)) (:boundaries (passo-confini-full-text space))
    (:emit (passo-emissione-full-text space))
    (otherwise (error 'invariant-violation :reason :fulltext-analysis-phase)))
  nil)

;;; REQ: REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (t t) keyword) passo-analisi-full-text))
(defun passo-analisi-full-text (space quantum)
  "Pre: analisi iniziata, quantum fra 1 e 65536 passi. Post: RUNNING o DONE.
Su errore di dominio passa a FAILED, rilascia input e invalida risultati parziali.
Ogni passo ha numero limitato di lookup/scalari; il lavoro totale ha budget proprio."
  (unless (and (typep space 'spazio-full-text) (typep quantum '(integer 1 65536)))
    (error 'invalid-argument :reason :fulltext-analysis-step))
  (when (eq :done (spazio-full-text-phase space)) (return-from passo-analisi-full-text :done))
  (when (member (spazio-full-text-phase space) '(:idle :failed))
    (error 'invalid-argument :reason :fulltext-analysis-state))
  (handler-case
      (dotimes (i quantum)
        (when (eq :done (spazio-full-text-phase space)) (return))
        (avanza-analisi-full-text space))
    (arcdocdb-error (condition)
      (setf (spazio-full-text-phase space) :failed (spazio-full-text-input space) nil
            (spazio-full-text-token-count space) 0 (spazio-full-text-byte-count space) 0)
      (error condition)))
  (if (eq :done (spazio-full-text-phase space)) :done :running))

;;; REQ: REQ-SEC-007
(declaim (ftype (function (t) (values octets vettore-u32 vettore-u32 index index &optional))
                risultati-analisi-full-text))
(defun risultati-analisi-full-text (space)
  "Pre: analisi DONE. Post: byte, inizi, fini, numero token, byte usati, presi in prestito.
Posizione del token e il suo indice da zero; validi fino al prossimo avvio sullo spazio.
INVALID-ARGUMENT se incompleta/fallita; nessun accesso a dati parziali."
  (unless (and (typep space 'spazio-full-text) (eq :done (spazio-full-text-phase space)))
    (error 'invalid-argument :reason :fulltext-analysis-incomplete))
  (values (spazio-full-text-bytes space) (spazio-full-text-begins space) (spazio-full-text-ends space)
          (spazio-full-text-token-count space) (spazio-full-text-byte-count space)))
