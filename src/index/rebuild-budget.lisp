;;; OWNER: writer/controller prenota prima della costruzione; limiti locali dell'indice.
;;; SHARED: nessuna mutazione, nessun mutex globale o callback.
(in-package #:arcdocdb.index.primary)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-AFF-008
(declaim (ftype (function (indice-primario frammento-indice digests-frammento digests-frammento
                                         boolean integer) root-indice) esigi-ricostruzione))
(defun esigi-ricostruzione (index source highs lows split budget)
  "Pre: writer esclusivo, digest stabili indicizzati per slot originale. Post: sorgente corrente valido.
Rifiuta forma/budget/profondità prima della scansione; nessuna mutazione o pubblicazione."
  (esigi-indice-sano index)
  (let ((root (acquisisci-root index)) (capacity (indice-primario-capacity index)))
    (esigi-sorgente-directory index root source)
    (when (> (frammento-indice-used source) (length (frammento-indice-arena source)))
      (guasto-indice index :primary-rebuild-arena-used))
    (unless (and (= capacity (length highs)) (= capacity (length lows))
                 (<= 1 budget most-positive-fixnum))
      (error 'invalid-argument :reason :primary-rebuild-configuration))
    (when (and split (>= (frammento-indice-depth source) (indice-primario-max-depth index)))
      (error 'resource-exhausted :reason :primary-directory-depth))
    root))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-AFF-008
(declaim (ftype (function (indice-primario root-indice frammento-indice) null) credito-ricostruzione))
(defun credito-ricostruzione (index root source)
  "Pre: writer senza mutazioni concorrenti. Post: credito per tutte le copie e preparazione/pubblicazione.
Generazione e revisione non fanno wrap; esaurimento rifiutato prima dei candidati."
  (when (>= (root-indice-generation root) (1- +revision-limit+))
    (error 'resource-exhausted :reason :primary-directory-generation-exhausted))
  (when (>= (+ (indice-primario-revision index) (frammento-indice-live source))
            (1- +revision-limit+))
    (error 'resource-exhausted :reason :primary-index-revision-exhausted))
  nil)

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (indice-primario root-indice frammento-indice boolean fixnum fixnum integer)
                         (values fixnum fixnum &optional)) budget-ricostruzione))
(defun budget-ricostruzione (index root source split first second budget)
  "Pre: scansione completa senza mutazioni. Post: profondità globale e payload transitorio prenotabile.
Controlla vecchia root + candidati + nuova directory PRIMA dei grandi array. Non è RSS.
Buffer fissi, digests del chiamante, root pregresse e runtime spettano al controller superiore."
  (let* ((depth (max (root-indice-depth root) (+ (frammento-indice-depth source) (if split 1 0))))
         (directory (* 8 (ash 1 depth))) (slots (* 41 (indice-primario-capacity index)))
         (payload (+ (payload-root root) directory slots first (if split (+ slots second) 0))))
    (when (> directory (indice-primario-directory-budget index))
      (error 'resource-exhausted :reason :primary-directory-memory-budget))
    (when (or (> (+ slots first) (indice-primario-fragment-budget index))
              (and split (> (+ slots second) (indice-primario-fragment-budget index))))
      (error 'resource-exhausted :reason :primary-fragment-memory-budget))
    (when (> payload budget) (error 'resource-exhausted :reason :primary-directory-transient-budget))
    (credito-ricostruzione index root source)
    (values depth payload)))
