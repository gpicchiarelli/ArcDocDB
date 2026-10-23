;;; OWNER: solo writer, un gettone esclusivo per scansione/copia/verifica/preparazione.
;;; SHARED: nessun coordinamento fra Serie; root invariata finché il chiamante pubblica il piano.
(in-package #:arcdocdb.index.primary)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-LIM-003 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (indice-primario frammento-indice digests-frammento digests-frammento integer
                                         &key (:split-p boolean))
                         (values pubblicazione-indice fixnum fixnum fixnum fixnum &optional))
                ricostruisci-frammento-indice))
(defun ricostruisci-frammento-indice (index source highs lows transient-budget-bytes &key (split-p nil))
  "Pre: writer; HIGH/LOW di C u32, stesso hash/seed fidato della Serie per ogni slot vivo originale.
Prenotazioni di memoria/tempo, lotti pendenti e root pregresse gestite dal controller prima della chiamata.
Post: piano verificato monouso NON pubblicato, C slot sorgente, byte chiavi copiati, riferimenti directory,
payload transitorio. Rebuild compatta l'arena; split divide secondo il bit alto successivo del digest.
Rifiuti di input/budget prima dei candidati; copie errate => FAULTED. Interruzioni delle mutazioni
seguono il fail-stop del writer; fuori dalle mutazioni i candidati privati sono scartabili dal GC."
  (let* ((root (esigi-ricostruzione index source highs lows split-p transient-budget-bytes))
         (words (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0))
         (work (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0))
         (context (crea-contesto-indice)))
    (multiple-value-bind (first-bytes second-bytes) (misura-ricostruzione source highs lows split-p words work)
      (multiple-value-bind (global payload)
          (budget-ricostruzione index root source split-p first-bytes second-bytes transient-budget-bytes)
        (let* ((depth (+ (frammento-indice-depth source) (if split-p 1 0)))
               (prefix (* (frammento-indice-prefix source) (if split-p 2 1)))
               (first (crea-frammento-indice index :depth depth :prefix prefix :arena-bytes first-bytes))
               (second (when split-p (crea-frammento-indice index :depth depth :prefix (1+ prefix)
                                                           :arena-bytes second-bytes))))
          (copia-ricostruzione index source first second highs lows words context)
          (verifica-ricostruzione index source first second highs lows words work)
          (let ((plan (prepara-directory-indice index source first transient-budget-bytes second)))
            (values plan (indice-primario-capacity index)
                    (+ (frammento-indice-used first) (if second (frammento-indice-used second) 0))
                    (ash 1 global) payload)))))))
