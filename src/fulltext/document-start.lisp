(in-package #:arcdocdb.fulltext.document)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text octets) null) controlla-alias-documento))
(defun controlla-alias-documento (task input)
  "Pre: tipi pubblici verificati. Post: input distinto dai byte analitici e del run.
INVALID-ARGUMENT prima di resettare qualunque risultato precedente."
  (when (or (eq input (a::spazio-full-text-bytes (preparazione-full-text-analysis task)))
            (eq input (r::indice-posizionale-bytes (preparazione-full-text-run task)))
            (eq input (cb::spazio-cbor-kinds (preparazione-full-text-cbor task)))
            (eq input (preparazione-full-text-levels task))
            (eq input (configurazione-full-text-identity (preparazione-full-text-config task))))
    (error 'invalid-argument :reason :fulltext-document-alias))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text) null) azzera-run-documento))
(defun azzera-run-documento (task)
  "Pre: risultato precedente non piu posseduto da reader, task non in corso.
Post: run/analisi privati iniziali; buffer non azzerati, contatori escludono dati residui."
  (let ((run (preparazione-full-text-run task)) (analysis (preparazione-full-text-analysis task)))
    (setf (r::indice-posizionale-count run) 0 (r::indice-posizionale-byte-count run) 0
          (r::indice-posizionale-field-count run) 0 (r::indice-posizionale-state run) :building
          (r::indice-posizionale-source run) nil (r::indice-posizionale-work run) 0
          (r::indice-posizionale-work-limit run) (preparazione-full-text-work-limit task)
          (a::spazio-full-text-phase analysis) :idle (a::spazio-full-text-input analysis) nil
          (a::spazio-full-text-token-count analysis) 0 (a::spazio-full-text-byte-count analysis) 0))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (t t t t t &key (:max-work t) (:max-file-bytes t) (:max-nodes t)) keyword)
                inizia-preparazione-full-text))
(defun inizia-preparazione-full-text (task input start end row &key (max-work 268435456)
                                      (max-file-bytes 17179869184) (max-nodes 16777216))
  "Pre: documento CBOR immutabile <=16MiB, ordinale fisico u32 proposto dal chiamante.
Post: RUNNING, input prestato; il risultato precedente e invalidato solo dopo preflight.
Task non condiviso, prestiti precedenti conclusi. INVALID-ARGUMENT per busy/tipi/alias;
RESOURCE-EXHAUSTED per span; nessun WAL, riserva di Serie, commit o I/O."
  (unless (and (typep task 'preparazione-full-text) (typep input 'octets)
               (typep start 'index) (typep end 'index) (<= start end (length input)) (typep row 'u32)
               (typep max-work 'index) (plusp max-work) (typep max-file-bytes 'index) (plusp max-file-bytes)
               (typep max-nodes '(integer 1 16777216)))
    (error 'invalid-argument :reason :fulltext-document-input))
  (unless (member (preparazione-full-text-phase task) '(:idle :done :failed :cancelled))
    (error 'invalid-argument :reason :fulltext-document-busy))
  (when (preparazione-full-text-borrower task)
    (error 'invalid-argument :reason :fulltext-document-borrowed))
  (controlla-alias-documento task input)
  (when (> (- end start) 16777216) (error 'resource-exhausted :reason :fulltext-document-bytes))
  (setf (preparazione-full-text-work-limit task)
        (min max-work (aref (configurazione-full-text-effective (preparazione-full-text-config task)) 4)))
  (azzera-run-documento task)
  (cb::azzera-spazio-cbor (preparazione-full-text-cbor task) start)
  (fill (preparazione-full-text-present task) 0)
  (setf (preparazione-full-text-input task) input (preparazione-full-text-start task) start
        (preparazione-full-text-end task) end (preparazione-full-text-row task) row
        (preparazione-full-text-work task) 0 (preparazione-full-text-input-bytes task) 0
        (preparazione-full-text-prepared-bytes task) 0 (preparazione-full-text-bound task) 0
        (preparazione-full-text-field task) 0 (preparazione-full-text-measure task) 0
        (preparazione-full-text-node-limit task) max-nodes (preparazione-full-text-file-limit task) max-file-bytes
        (preparazione-full-text-phase task) :scan)
  :running)
