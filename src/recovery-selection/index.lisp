;;; OWNER: writer della Serie, solo candidato privato; completezza di ogni chiave prima del trasferimento.
;;; SHARED: mutazione canonica dell'indice locale, nessun nuovo CAS o stato fra Serie.
(in-package #:arcdocdb.recovery.selection)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-IDX-003 REQ-IDX-006 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (selettore-versione-recuperata arcdocdb.index.primary:indice-primario
                          arcdocdb.index.primary:contesto-indice contenuto-slot)
                         (member :inserted :present :absent)) materializza-chiave-recuperata))
(defun materializza-chiave-recuperata (selector index context source)
  "Pre: tutti i candidati committed della chiave considerati; indice privato della stessa Serie, ammissione chiusa.
Writer esclusivo; SOURCE e CONTEXT preallocati, non alias; nessuna chiave/record modificati durante la chiamata.
Post: PUT inserito o identico; TOMBSTONE/NONE soltanto assenza verificata. Nessuna voce viva sovrascritta/rimossa.
Ambiguita, seme, alias, incompatibilita e budget rifiutati senza mutazioni dell'indice; scratch privato modificabile.
Invarianti guastano anche il selettore; source non e prova di commit. Nessun I/O, root pubblica o ammissione.
Capacita esaurita: manutenzione del candidato e nuova chiamata, mai perdita di un risultato precedente."
  (arcdocdb.index.primary::esigi-contesto-libero context)
  (when (eq source (arcdocdb.index.primary::contesto-indice-words context))
    (error 'invalid-argument :reason :recovery-index-source-alias))
  (handler-case
      (multiple-value-bind (kind csn segment offset bytes version flags) (leggi-versione-selezionata selector)
        (declare (ignore version flags)) ; fatti verificati: primary non codifica il formato/flag del record.
        (multiple-value-bind (high low)
            (arcdocdb.index.primary:digest-chiave-indice index (selection-key selector) 0 (selection-length selector))
          (prepara-payload-indice-recuperato selector source kind csn segment offset bytes)
          (arcdocdb.index.primary:ripristina-chiave-indice
           index (selection-key selector) 0 (selection-length selector) high low
           (when (eq kind :put) source) context)))
    (invariant-violation (condition)
      (setf (selection-state selector) :faulted)
      (error condition))))
