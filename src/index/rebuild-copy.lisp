;;; OWNER: writer costruisce e verifica candidati BUILDING, senza pubblicarli.
;;; SHARED: legge solo il sorgente corrente; scrive candidati e revisione locale della Serie.
(in-package #:arcdocdb.index.primary)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-AFF-004
(declaim (ftype (function (frammento-indice frammento-indice (or null frammento-indice) u32)
                         frammento-indice) destinazione-ricostruzione))
(defun destinazione-ricostruzione (source first second high)
  "Pre: figli ordinati o candidato rebuild della geometria verificata. Post: destinazione del digest.
Prefisso del sorgente verificato in preflight; nessuna scelta basata sullo slot fisico."
  (esigi-frammento-sano (frammento-indice-owner source) first)
  (if second
      (progn
        (esigi-frammento-sano (frammento-indice-owner source) second)
        (if (oddp (prefix-hash high (frammento-indice-depth first))) second first))
      first))

;;; REQ: REQ-IDX-001 REQ-IDX-005 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (indice-primario frammento-indice frammento-indice (or null frammento-indice)
                                         digests-frammento digests-frammento contenuto-slot contesto-indice)
                         null) copia-ricostruzione))
(defun copia-ricostruzione (index source first second highs lows words context)
  "Pre: preflight completo, candidati vuoti, scratch privati distinti. Post: copie vive compatte.
C slot visitati; copia solo byte delle chiavi vive e payload identici salvo offset arena."
  (let ((arena (frammento-indice-arena source)))
    (dotimes (slot (indice-primario-capacity index))
      (when (campiona-ricostruzione source slot words)
        (let ((offset (ldb (byte 32 0) (aref words 2))) (size (ldb (byte 16 32) (aref words 2)))
              (target (destinazione-ricostruzione source first second (aref highs slot))))
          (pubblica-chiave-indice index target arena offset (+ offset size)
                                 (aref highs slot) (aref lows slot) words context)))))
  (esigi-frammento-sano index source)
  nil)

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-AFF-004
(declaim (ftype (function (contenuto-slot contenuto-slot) boolean) copia-ricostruzione-uguale-p))
(defun copia-ricostruzione-uguale-p (original copy)
  "Pre: due payload vivi privati validati. Post: identici salvo offset locale dell'arena.
Il seqlock non fa parte del payload; key-len/flag/riservato devono restare identici."
  (and (= (aref original 0) (aref copy 0)) (= (aref original 1) (aref copy 1))
       (= (ash (aref original 2) -32) (ash (aref copy 2) -32))
       (= (aref original 3) (aref copy 3)) (= (aref original 4) (aref copy 4))))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-AFF-004
(declaim (ftype (function (indice-primario frammento-indice frammento-indice (or null frammento-indice)
                                         digests-frammento digests-frammento contenuto-slot contenuto-slot)
                         null) verifica-ricostruzione))
(defun verifica-ricostruzione (index source first second highs lows words work)
  "Pre: copie costruite, writer esclusivo. Post: ogni chiave viva sorgente ritrovata con payload identico.
Conteggio candidati controllato poi dal piano; lookup byte-per-byte non assume fedeltà dal conteggio."
  (let ((arena (frammento-indice-arena source)))
    (dotimes (slot (indice-primario-capacity index))
      (when (campiona-ricostruzione source slot words)
        (let ((offset (ldb (byte 32 0) (aref words 2))) (size (ldb (byte 16 32) (aref words 2)))
              (target (destinazione-ricostruzione source first second (aref highs slot))))
          (multiple-value-bind (found-slot found)
              (sonda-ricostruzione target arena offset (+ offset size) (aref lows slot) work)
            (unless (and found (<= 0 found-slot) (copia-ricostruzione-uguale-p words work))
              (guasto-indice index :primary-rebuild-copy-mismatch)))))))
  (esigi-frammento-sano index first)
  nil)
