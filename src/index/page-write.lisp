;;; OWNER: destinazione esclusiva e sorgente stabile distinto; controllore del derivato.
;;; SHARED: nessuno; prepara byte in RAM, senza atomicita' durevole.
(in-package #:arcdocdb.index.page)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-009
(declaim (ftype (function (octets index index descrittore-pagina index) null) scrivi-header-pagina))
(defun scrivi-header-pagina (buffer start size descriptor used)
  "Pre: preflight completo, destinazione azzerata. Post: header canonico con CRC dei metadati.
Nessuna condizione recuperabile dopo l'avvio; nessuna pubblicazione o I/O."
  (unless (and (<= (+ start size) (length buffer))
               (<= used (- size +page-header+)))
    (error 'invariant-violation :reason :index-page-header-write-range))
  (let ((identity (descrittore-pagina-identity descriptor)))
    (scrivi-u32 buffer start +page-magic-low+)
    (scrivi-u32 buffer (+ start +off-magic-high+) +page-magic-high+)
    (scrivi-u16 buffer (+ start +off-version+) +page-version+)
    (setf (aref buffer (+ start +off-kind+)) (codice-tipo-pagina (descrittore-pagina-kind descriptor))
          (aref buffer (+ start +off-size+)) (nth-value 0 (geometria-pagina size)))
    (replace buffer (identita-pagina-serie identity) :start1 (+ start +off-series+))
    (scrivi-u64 buffer (+ start +off-image+) (identita-pagina-image identity))
    (scrivi-u64 buffer (+ start +off-page+) (identita-pagina-page identity))
    (scrivi-u64 buffer (+ start +off-generation+) (identita-pagina-generation identity))
    (scrivi-u32 buffer (+ start +off-used+) used)
    (scrivi-u32 buffer (+ start +off-count+) (descrittore-pagina-count descriptor))
    (scrivi-u64 buffer (+ start +off-next+) (descrittore-pagina-next descriptor))
    (scrivi-u64 buffer (+ start +off-next-generation+) (descrittore-pagina-next-generation descriptor))
    (scrivi-u32 buffer (+ start +off-parameter+) (descrittore-pagina-parameter descriptor))
    (scrivi-u32 buffer (+ start +off-header-crc+)
                (crc32c buffer start (+ start +off-header-crc+)))
    (unless (and (u64-equal-p buffer (+ start +off-page+) (identita-pagina-page identity))
                 (u64-equal-p buffer (+ start +off-generation+) (identita-pagina-generation identity)))
      (error 'invariant-violation :reason :index-page-header-write-result)))
  nil)

;;; REQ: REQ-IDX-009 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets integer integer descrittore-pagina octets integer integer)
                         index) scrivi-pagina-indice))
(defun scrivi-pagina-indice (buffer start end descriptor body from to)
  "Pre: buffer esclusivo, corpo canonico gia' preparato e stabile, descrittore fidato.
Post: pagina completa verificabile, guardie e sorgente invariati; restituisce END.
INVALID-ARGUMENT su range, alias, geometria o corpo prima di ogni modifica.
Solo preparazione in memoria, senza commit/flush/root o promessa sul lookup caldo."
  (check-range buffer start end) (check-range body from to)
  (let ((size (- end start)) (used (- to from)))
    (esigi-pagina (plusp (nth-value 0 (geometria-pagina size)))
                  'invalid-argument :index-page-size)
    (esigi-pagina (not (eq buffer body)) 'invalid-argument :index-page-alias)
    (verifica-corpo-pagina
     body from used size (descrittore-pagina-identity descriptor)
     (descrittore-pagina-kind descriptor) (descrittore-pagina-count descriptor)
     (descrittore-pagina-parameter descriptor) (descrittore-pagina-next descriptor)
     (descrittore-pagina-next-generation descriptor) 'invalid-argument)
    (fill buffer 0 :start start :end end)
    (scrivi-header-pagina buffer start size descriptor used)
    (replace buffer body :start1 (+ start +page-header+) :start2 from :end2 to)
    (scrivi-u32 buffer (+ start +off-body-crc+) (crc32c buffer (+ start +page-header+) end))
    (unless (and (= (leggi-u32 buffer (+ start +off-header-crc+))
                    (crc32c buffer start (+ start +off-header-crc+)))
                 (= (leggi-u32 buffer (+ start +off-used+)) used))
      (error 'invariant-violation :reason :index-page-write-result)))
  end)
