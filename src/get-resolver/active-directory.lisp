;;; OWNER: writer costruisce al più quattro nuovi vettori, senza mutare quelli pubblicati.
;;; SHARED: struttura persistente per Serie; reader percorre soltanto riferimenti immutabili.
(in-package #:arcdocdb.get.resolver)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-AFF-008 REQ-AFF-002
(declaim (ftype (function ((or null simple-vector)) null) verifica-nodo-attivo))
(defun verifica-nodo-attivo (node)
  "Pre: nodo NIL o vettore interno. Post: geometria di sedici figli validata prima dell'accesso.
INVARIANT-VIOLATION per forma impossibile; nessuna mutazione o attesa."
  (unless (or (null node) (= (length node) +active-directory-width+))
    (error 'invariant-violation :reason :active-directory-shape))
  nil)

;;; REQ: REQ-IDX-001 REQ-AFF-008 REQ-AFF-002
(declaim (ftype (function ((or null simple-vector) (integer 0 65535) mappa-segmento-get
                          (member 0 4 8 12)) (values simple-vector index &optional))
                appendi-pagina-attiva))
(defun appendi-pagina-attiva (node rank page shift)
  "Pre: rank libero, shift 12/8/4/0 e nodo immutabile. Post: nuovo cammino, vecchio intatto.
Ricorsione ESATTAMENTE quattro livelli al massimo; sedici copie/level, nessuna scansione storica.
Secondo valore: nuovi nodi nella vista, esclude copie che sostituiscono nodi già esistenti.
INVARIANT-VIOLATION per foglia occupata/geometria; array privati non esposti su errore."
  (verifica-nodo-attivo node)
  (let* ((slot (ldb (byte 4 shift) rank))
         (copy (if node (copy-seq node) (make-array +active-directory-width+ :initial-element nil)))
         (added (if node 0 1)))
    (declare (type simple-vector copy) (type index added))
    (if (zerop shift)
        (progn
          (when (svref copy slot) (error 'invariant-violation :reason :active-directory-occupied))
          (setf (svref copy slot) page))
        (multiple-value-bind (child delta)
            (appendi-pagina-attiva (svref copy slot) rank page (- shift 4))
          (setf (svref copy slot) child) (incf added delta)))
    (unless (<= added +active-directory-levels+)
      (error 'invariant-violation :reason :active-directory-growth))
    (values copy added)))

;;; REQ: REQ-IDX-001 REQ-AFF-002 REQ-CMP-007
(declaim (ftype (function (contesto-get radice-get-attiva (integer 0 65535)) mappa-segmento-get)
                pagina-attiva))
(defun pagina-attiva (context root rank)
  "Pre: CANDIDATE, root acquisita sotto EBR, rank nella vista. Post: pagina esatta in quattro accessi.
Forma/figlio/foglia impossibili rendono GET FAULTED; nessun I/O, allocazione esplicita o retry."
  (unless (< rank (radice-get-attiva-count root)) (guasto-get context :active-page-rank))
  (let ((node (radice-get-attiva-directory root)))
    (declare (type t node))
    (loop for shift of-type fixnum from +active-directory-shift+ downto 0 by 4
          do (unless (and (typep node 'simple-vector) (= (length node) +active-directory-width+))
               (guasto-get context :active-directory-shape))
             (setf node (svref node (ldb (byte 4 shift) rank))))
    (unless (typep node 'mappa-segmento-get) (guasto-get context :active-page-type))
    node))

;;; REQ: REQ-IDX-001 REQ-CMP-007 REQ-AFF-002
(declaim (ftype (function (contesto-get radice-get-attiva u32) mappa-segmento-get) trova-pagina-attiva))
(defun trova-pagina-attiva (context root offset)
  "Pre: root pubblicata sotto EBR. Post: prima pagina con fine maggiore dell'offset.
Al più diciassette confronti, ciascuno con quattro accessi; poi lookup PUT separato.
Location oltre frontiera/mancante è un guasto, mai assenza del documento."
  (unless (<= +segment-header-bytes+ offset (1- (radice-get-attiva-end root)))
    (guasto-get context :active-location-frontier))
  (let ((left 0) (right (radice-get-attiva-count root)))
    (declare (type (integer 0 65536) left right))
    (loop repeat +active-page-attempts+
          do (when (= left right)
               (unless (< left (radice-get-attiva-count root)) (guasto-get context :active-page-absent))
               (return-from trova-pagina-attiva (pagina-attiva context root left)))
             (let* ((middle (+ left (floor (- right left) 2))) (page (pagina-attiva context root middle)))
               (if (<= (mappa-segmento-get-end page) offset) (setf left (1+ middle)) (setf right middle))))
    ;; N=65536 può usare tutti i diciassette confronti: controllare anche la convergenza finale.
    (unless (and (= left right) (< left (radice-get-attiva-count root)))
      (guasto-get context :active-page-search-bound))
    (pagina-attiva context root left)))
