;;;; SPK-06: letture indipendenti durante una copia verificata e limitata.
;;; REQ: REQ-BEN-001 REQ-BEN-002 REQ-AFF-016 REQ-AFF-002
(defpackage #:arcdocdb.spk06.interferenza
  (:use #:cl)
  (:import-from #:arcdocdb.spk05.io #:apri-lettura #:crea-esclusivo #:chiudi
                #:leggi-esatto #:scrivi-esatto #:elimina-file)
  (:import-from #:arcdocdb.spk05.record #:+record-bytes+ #:+value-bytes+
                #:scrivi-fixture #:verifica-record)
  (:export #:check #:benchmark #:worker-incompleto))
(in-package #:arcdocdb.spk06.interferenza)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(deftype octets () '(simple-array (unsigned-byte 8) (*)))
(deftype piano () '(simple-array (unsigned-byte 32) (*)))
(deftype campioni () '(simple-array (unsigned-byte 64) (*)))
(defconstant +blocco-bytes+ 65536)
(defconstant +attesa-secondi+ 10)
(defconstant +massimo-record+ 8192)
(defconstant +massimo-operazioni+ 32768)

;;; REQ: REQ-AFF-016
(define-condition worker-incompleto (error)
  ((numeri :initarg :numeri :reader numeri-worker)
   (precedenti :initarg :precedenti :initform nil :reader errori-precedenti))
  (:report (lambda (condizione flusso)
             (format flusso "SPK-06: worker ancora vivi ~S; risorse conservate fino all'uscita. Errori: ~S."
                     (numeri-worker condizione) (errori-precedenti condizione)))))

;;; REQ: REQ-AFF-016
(define-condition guasto-iniettato (error)
  ((ruolo :initarg :ruolo :reader ruolo-guasto))
  (:report (lambda (condizione flusso)
             (format flusso "SPK-06: guasto iniettato nel worker ~S."
                     (ruolo-guasto condizione)))))

;;; OWNER: controller prepara piano, descrittore e buffer; un solo worker li usa.
;;; SHARED: porte comuni ai confini del caso; nessuna scrittura condivisa per record.
;;; REQ: REQ-BEN-001 REQ-AFF-016
(defstruct lettore
  "Pre: risorse pronte. Post: conteggi, campioni e incidente locali dopo join."
  (fd -1 :type (integer -1 2147483647))
  (buffer (make-array +record-bytes+ :element-type '(unsigned-byte 8)) :type octets)
  (piano (make-array 0 :element-type '(unsigned-byte 32)) :type piano)
  (inizi (make-array 0 :element-type '(unsigned-byte 64)) :type campioni)
  (fini (make-array 0 :element-type '(unsigned-byte 64)) :type campioni)
  (inizio 0 :type fixnum) (fine 0 :type fixnum) (completati 0 :type fixnum)
  (sink 0 :type fixnum) (sink-atteso 0 :type fixnum)
  (guasto-p nil :type boolean) (incidente nil :type (or null error))
  (thread nil :type (or null sb-thread:thread)))

;;; OWNER: worker di copia; nessun altro legge i campi prima del join.
;;; REQ: REQ-BEN-001 REQ-AFF-002 REQ-AFF-016
(defstruct copia
  "Pre: source read-only e target esclusivo. Post: bytes e clock reali, prima della riapertura."
  (source -1 :type (integer -1 2147483647))
  (target -1 :type (integer -1 2147483647))
  (buffer (make-array +blocco-bytes+ :element-type '(unsigned-byte 8)) :type octets)
  (record 0 :type fixnum) (quota 0 :type fixnum)
  (inizio 0 :type fixnum) (fine 0 :type fixnum) (bytes 0 :type fixnum)
  (blocchi 0 :type fixnum) (attese 0 :type fixnum)
  (guasto-p nil :type boolean) (incidente nil :type (or null error))
  (thread nil :type (or null sb-thread:thread)))

;;; REQ: REQ-BEN-001
(defun secondi (ticks)
  "Converte ticks dello stesso clock in secondi double-float."
  (/ ticks (coerce internal-time-units-per-second 'double-float)))

;;; REQ: REQ-AFF-002
(defun esigi (condizione dettaglio)
  "Segnala un'incoerenza dell'oracolo, senza consentire un report di successo."
  (unless condizione (error "SPK-06: oracolo non soddisfatto: ~S." dettaglio))
  nil)

;;; REQ: REQ-AFF-016
(defun con-descrittore (fd funzione)
  "Chiude esattamente una volta, conservando errore primario e errore di close."
  (let ((risultato nil) (primario nil) (pulizia nil))
    (unwind-protect
         (handler-case (setf risultato (funcall funzione fd))
           (error (condizione) (setf primario condizione)))
      (handler-case (chiudi fd) (error (condizione) (setf pulizia condizione))))
    (when pulizia (error "SPK-06: close fallito: ~A; errore primario: ~A." pulizia primario))
    (when primario (error primario))
    risultato))

;;; REQ: REQ-BEN-002 REQ-AFF-002
(defun nuova-directory (base)
  "Crea una directory esclusiva sotto out/data; nessun file esistente è riutilizzato."
  (let ((radice (merge-pathnames "out/data/" base)))
    (ensure-directories-exist (merge-pathnames "segnaposto" radice))
    (pathname (concatenate 'string
                           (sb-posix:mkdtemp (namestring (merge-pathnames "copia-XXXXXX" radice)))
                           "/"))))

;;; REQ: REQ-AFF-002 REQ-BEN-002
(defun verifica-fixture (path numero)
  "Riapre e verifica CRC, chiave, stamp e ogni byte contro il generatore deterministico."
  (let ((buffer (make-array +record-bytes+ :element-type '(unsigned-byte 8)))
        (atteso (make-array +record-bytes+ :element-type '(unsigned-byte 8))))
    (con-descrittore (apri-lettura path)
      (lambda (fd)
        (esigi (= (sb-posix:stat-size (sb-posix:fstat fd)) (* numero +record-bytes+)) :dimensione-fixture)
        (sb-sys:with-pinned-objects (buffer)
          (dotimes (n numero)
            (leggi-esatto fd (sb-sys:vector-sap buffer) +record-bytes+ (* n +record-bytes+))
            (verifica-record (sb-sys:vector-sap buffer) 0 +record-bytes+ n)
            (scrivi-fixture atteso n)
            (esigi (equalp buffer atteso) (list :fixture-byte n)))))))
  (* numero +record-bytes+))

;;; REQ: REQ-AFF-002 REQ-BEN-002
(defun verifica-copia (source target numero)
  "Dopo join riapre entrambi i file, controlla ogni record e confronta ogni octet."
  (let ((origine (make-array +record-bytes+ :element-type '(unsigned-byte 8)))
        (destinazione (make-array +record-bytes+ :element-type '(unsigned-byte 8))))
    (con-descrittore (apri-lettura source)
      (lambda (fd-source)
        (con-descrittore (apri-lettura target)
          (lambda (fd-target)
            (dolist (fd (list fd-source fd-target))
              (esigi (= (sb-posix:stat-size (sb-posix:fstat fd)) (* numero +record-bytes+))
                     :dimensione-copia))
            (sb-sys:with-pinned-objects (origine destinazione)
              (dotimes (n numero)
                (let ((offset (* n +record-bytes+)))
                  (leggi-esatto fd-source (sb-sys:vector-sap origine) +record-bytes+ offset)
                  (leggi-esatto fd-target (sb-sys:vector-sap destinazione) +record-bytes+ offset)
                  (verifica-record (sb-sys:vector-sap origine) 0 +record-bytes+ n)
                  (verifica-record (sb-sys:vector-sap destinazione) 0 +record-bytes+ n)
                  (esigi (equalp origine destinazione) (list :copia-byte n))))))))))
  (* numero +record-bytes+))

;;; REQ: REQ-BEN-002 REQ-AFF-016
(defun con-fixture (base numero funzione)
  "Genera una volta, verifica prima e dopo la matrice; rimuove solo file e directory propri.
Un worker incompleto conserva l'intera fixture fino alla fine del processo."
  (esigi (and (typep numero 'fixnum) (<= 1 numero +massimo-record+)) :budget-fixture)
  (let* ((dir (nuova-directory base)) (source (merge-pathnames "origine.dat.tmp" dir))
         (creato nil) (primario nil) (pulizia nil) (risultato nil))
    (unwind-protect
         (handler-case
             (progn
               (let ((buffer (make-array +record-bytes+ :element-type '(unsigned-byte 8)))
                     (fd (crea-esclusivo source)))
                 (setf creato t)
                 (con-descrittore fd
                   (lambda (fd)
                     (sb-sys:with-pinned-objects (buffer)
                       (dotimes (n numero)
                         (scrivi-fixture buffer n)
                         (scrivi-esatto fd (sb-sys:vector-sap buffer) +record-bytes+))))))
               (verifica-fixture source numero)
               (setf risultato (funcall funzione source dir numero))
               (verifica-fixture source numero))
           (error (condizione) (setf primario condizione)))
      (unless (typep primario 'worker-incompleto)
        (when creato
          (handler-case (elimina-file source) (error (condizione) (push condizione pulizia))))
        (handler-case (sb-posix:rmdir dir) (error (condizione) (push condizione pulizia)))))
    (when pulizia (error "SPK-06: pulizia fixture: ~S; errore primario: ~A." pulizia primario))
    (when primario (error primario))
    risultato))

;;; REQ: REQ-BEN-002
(defun prepara-piano (numero operazioni id workers)
  "LCG32 ripetibile parità di worker e replica; costruzione esclusa dall'intervallo I/O."
  (esigi (and (<= 1 numero +massimo-record+) (<= 1 operazioni +massimo-operazioni+)
              (member workers '(1 2)) (<= 0 id) (< id workers)
              (zerop (mod operazioni workers))) :parametri-piano)
  (let ((piano (make-array (/ operazioni workers) :element-type '(unsigned-byte 32)))
        (seed (1+ id)) (sink 0))
    (dotimes (i (length piano))
      (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))
      (let* ((n (mod seed numero)) (primo (mod (+ 165 (* 17 n)) 256))
             (ultimo (mod (+ primo (* 29 (1- +value-bytes+))) 256)))
        (setf (aref piano i) n)
        (incf sink (+ +value-bytes+ primo ultimo))))
    (values piano sink)))

;;; REQ: REQ-AFF-002 REQ-BEN-001
(defun esegui-lettore (lavoro pronti partenza)
  "Ogni lettura pread verifica il record e consuma lunghezza e due byte del valore validato."
  (let ((segnalato nil))
    (handler-case
        (let ((buffer (lettore-buffer lavoro)))
          (sb-sys:with-pinned-objects (buffer)
            (sb-thread:signal-semaphore pronti)
            (setf segnalato t)
            (unless (sb-thread:wait-on-semaphore partenza :timeout +attesa-secondi+)
              (error "SPK-06: timeout della partenza lettore."))
            (when (lettore-guasto-p lavoro) (error 'guasto-iniettato :ruolo :lettore))
            (setf (lettore-inizio lavoro) (get-internal-real-time))
            (let ((sap (sb-sys:vector-sap buffer)) (piano (lettore-piano lavoro))
                  (inizi (lettore-inizi lavoro)) (fini (lettore-fini lavoro)) (sink 0))
              (declare (type sb-sys:system-area-pointer sap) (type piano piano)
                       (type campioni inizi fini) (type fixnum sink))
              (dotimes (i (length piano))
                (let ((n (aref piano i)))
                  (setf (aref inizi i) (get-internal-real-time))
                  (leggi-esatto (lettore-fd lavoro) sap +record-bytes+ (* n +record-bytes+))
                  (multiple-value-bind (inizio fine) (verifica-record sap 0 +record-bytes+ n)
                    (esigi (= (- fine inizio) +value-bytes+) :range-valore)
                    (incf sink (+ (- fine inizio) (sb-sys:sap-ref-8 sap inizio)
                                  (sb-sys:sap-ref-8 sap (1- fine)))))
                  (setf (aref fini i) (get-internal-real-time))))
              (setf (lettore-fine lavoro) (get-internal-real-time)
                    (lettore-completati lavoro) (length piano) (lettore-sink lavoro) sink))))
      (error (condizione) (setf (lettore-incidente lavoro) condizione)))
    (unless segnalato (sb-thread:signal-semaphore pronti)))
  :completato)

;;; REQ: REQ-BEN-001 REQ-AFF-016
(defun ottieni-quota (bytes quota credito ultimo)
  "Token bucket locale: cap 64 KiB e credito iniziale di un blocco.
Prima del read attende solo il worker di copia. Massimo 16 ricalcoli e 10 secondi
diagnostici per blocco; scheduler, sleep e clock non costituiscono garanzie temporali."
  (if (zerop quota)
      (values credito ultimo 0)
      (let* ((unita internal-time-units-per-second)
             (necessario (* bytes unita)) (cap (* +blocco-bytes+ unita))
             (inizio (get-internal-real-time)) (attese 0))
        (dotimes (tentativo 16)
          (let* ((ora (get-internal-real-time)) (elapsed (- ora ultimo)))
            (esigi (>= elapsed 0) :clock-regredito)
            (setf credito (min cap (+ credito (* elapsed quota))) ultimo ora)
            (when (>= credito necessario)
              (return-from ottieni-quota (values (- credito necessario) ultimo attese)))
            (when (> (- ora inizio) (* +attesa-secondi+ unita))
              (error "SPK-06: quota fuori budget diagnostico."))
            (let ((durata (/ (- necessario credito) (coerce (* quota unita) 'double-float))))
              (esigi (> durata 0d0) :attesa-quota-positiva)
              (sleep durata)
              (incf attese))))
        (error "SPK-06: quota non ottenuta dopo 16 ricalcoli."))))

;;; REQ: REQ-AFF-002 REQ-BEN-001
(defun esegui-copia (lavoro pronti partenza)
  "Copia blocchi pread/CRC/write; quota acquisita prima del read e buffer pinned per il worker."
  (let ((segnalato nil))
    (handler-case
        (let ((buffer (copia-buffer lavoro)))
          (sb-sys:with-pinned-objects (buffer)
            (sb-thread:signal-semaphore pronti)
            (setf segnalato t)
            (unless (sb-thread:wait-on-semaphore partenza :timeout +attesa-secondi+)
              (error "SPK-06: timeout della partenza copia."))
            (when (copia-guasto-p lavoro) (error 'guasto-iniettato :ruolo :copia))
            (let* ((sap (sb-sys:vector-sap buffer)) (totale (* (copia-record lavoro) +record-bytes+))
                   (credito (* +blocco-bytes+ internal-time-units-per-second))
                   (ultimo (get-internal-real-time)))
              (setf (copia-inizio lavoro) ultimo)
              (loop for offset from 0 below totale by +blocco-bytes+
                    for bytes = (min +blocco-bytes+ (- totale offset))
                    do (multiple-value-bind (nuovo-credito nuovo-ultimo attese)
                           (ottieni-quota bytes (copia-quota lavoro) credito ultimo)
                         (setf credito nuovo-credito ultimo nuovo-ultimo)
                         (incf (copia-attese lavoro) attese))
                       (leggi-esatto (copia-source lavoro) sap bytes offset)
                       (dotimes (r (/ bytes +record-bytes+))
                         (verifica-record sap (* r +record-bytes+) bytes
                                          (+ (/ offset +record-bytes+) r)))
                       (scrivi-esatto (copia-target lavoro) sap bytes)
                       (incf (copia-bytes lavoro) bytes)
                       (incf (copia-blocchi lavoro)))
              (setf (copia-fine lavoro) (get-internal-real-time)))))
      (error (condizione) (setf (copia-incidente lavoro) condizione)))
    (unless segnalato (sb-thread:signal-semaphore pronti)))
  :completato)

;;; REQ: REQ-AFF-016
(defun thread-lavoro (lavoro)
  "Restituisce il thread già creato, per join e controllo unico della vita."
  (etypecase lavoro (lettore (lettore-thread lavoro)) (copia (copia-thread lavoro))))

;;; REQ: REQ-AFF-016
(defun incidente-lavoro (lavoro)
  "Legge l'incidente locale soltanto dopo join."
  (etypecase lavoro (lettore (lettore-incidente lavoro)) (copia (copia-incidente lavoro))))

;;; REQ: REQ-AFF-016
(defun avvia-worker (lettori lavoro-copia)
  "Rilascia una volta la partenza anche su creazione parziale; join e guasti restano distinti."
  (let* ((lavori (append lettori (when lavoro-copia (list lavoro-copia))))
         (pronti (sb-thread:make-semaphore)) (partenza (sb-thread:make-semaphore))
         (primario nil) (errori-join nil) (sentinella (gensym "JOIN")))
    (handler-case
        (progn
          (dolist (lavoro lavori)
            (let ((corrente lavoro))
              (etypecase corrente
                (lettore
                 (setf (lettore-thread corrente)
                       (sb-thread:make-thread
                        (lambda () (esegui-lettore corrente pronti partenza)) :name "SPK-06-lettura")))
                (copia
                 (setf (copia-thread corrente)
                       (sb-thread:make-thread
                        (lambda () (esegui-copia corrente pronti partenza)) :name "SPK-06-copia"))))))
          (dotimes (n (length lavori))
            (unless (sb-thread:wait-on-semaphore pronti :timeout +attesa-secondi+)
              (error "SPK-06: preparazione worker fuori budget."))))
      (error (condizione) (setf primario condizione)))
    ;; Le risorse restano possedute dal caso, anche quando la creazione è parziale.
    (sb-thread:signal-semaphore partenza (length lavori))
    (dolist (lavoro lavori)
      (let ((thread (thread-lavoro lavoro)))
        (when thread
          (handler-case
              (let ((esito (sb-thread:join-thread thread :timeout +attesa-secondi+ :default sentinella)))
                (unless (eq esito :completato)
                  (push (list :join esito) errori-join)))
            (error (condizione) (push condizione errori-join))))))
    (let ((vivi (loop for lavoro in lavori for n from 0
                      for thread = (thread-lavoro lavoro)
                      when (and thread (sb-thread:thread-alive-p thread)) collect n)))
      (when vivi (error 'worker-incompleto :numeri vivi :precedenti (cons primario errori-join))))
    (when errori-join
      (error "SPK-06: join falliti: ~S; errore primario: ~A." errori-join primario))
    (when primario (error primario))
    (dolist (lavoro lavori) (when (incidente-lavoro lavoro) (error (incidente-lavoro lavoro)))))
  nil)

;;; REQ: REQ-BEN-001
(defun statistiche-campioni (campioni)
  "Percentili nearest-rank calcolati dopo join; campioni vuoti dichiarati senza numero."
  (let ((n (length campioni)))
    (if (zerop n)
        (list :count 0 :p99 :not-measured)
        (let ((ordinati (sort (copy-seq campioni) #'<)))
          (list :count n :min (secondi (aref ordinati 0))
                :p50 (secondi (aref ordinati (1- (ceiling (* 0.50d0 n)))))
                :p99 (secondi (aref ordinati (1- (ceiling (* 0.99d0 n)))))
                :max (secondi (aref ordinati (1- n))))))))

;;; REQ: REQ-BEN-001 REQ-BEN-002
(defun risultato-caso (lettori lavoro-copia modalita replica operazioni)
  "Usa solo intervalli osservati: nessuna porta di partenza garantisce sovrapposizione."
  (let* ((inizio (reduce #'min lettori :key #'lettore-inizio))
         (fine (reduce #'max lettori :key #'lettore-fine))
         (wall (secondi (- fine inizio)))
         (latenze (make-array operazioni :element-type '(unsigned-byte 64)))
         (sovrapposti (make-array operazioni :element-type '(unsigned-byte 64)))
         (posizione 0) (coperti 0) (intervalli nil))
    (esigi (= operazioni (reduce #'+ lettori :key #'lettore-completati)) :operazioni-completate)
    (esigi (> wall 0d0) :intervallo-letture)
    (dolist (lavoro lettori)
      (esigi (= (lettore-sink lavoro) (lettore-sink-atteso lavoro)) :consumo-valore)
      (let* ((a (when lavoro-copia (max (lettore-inizio lavoro) (copia-inizio lavoro-copia))))
             (b (when lavoro-copia (min (lettore-fine lavoro) (copia-fine lavoro-copia)))))
        (push (when (and a b (< a b)) (list :start-ticks a :end-ticks b)) intervalli)
        (dotimes (i (length (lettore-piano lavoro)))
          (let* ((da (aref (lettore-inizi lavoro) i)) (a-fine (aref (lettore-fini lavoro) i))
                 (durata (- a-fine da)))
            (esigi (>= durata 0) :durata-lettura)
            (setf (aref latenze posizione) durata)
            (incf posizione)
            (when (and a b (< a b) (<= a da a-fine b))
              (setf (aref sovrapposti coperti) durata)
              (incf coperti))))))
    (list :status :ok :method :pread :mode modalita :replica replica :workers (length lettori)
          :operations operazioni :verified-read-bytes (* operazioni +record-bytes+)
          :read-wall-seconds wall :reads-per-second (/ operazioni wall)
          :latency-seconds (statistiche-campioni latenze) :raw-latency-ticks latenze
          :worker-start-ticks (mapcar #'lettore-inizio lettori)
          :worker-end-ticks (mapcar #'lettore-fine lettori)
          :worker-operation-counts (mapcar #'lettore-completati lettori)
          :raw-operation-start-ticks (mapcar #'lettore-inizi lettori)
          :raw-operation-end-reconstruction :start-plus-latency-in-worker-order
          :overall-p99-ratio-to-baseline :not-applicable
          :overlap-p99-ratio-to-baseline :not-applicable
          :overlap-status (cond ((null lavoro-copia) :not-applicable)
                                ((plusp coperti) :observed) (t :no-covered-samples))
          :overlap-operation-count coperti :overlap-sample-fraction (/ (coerce coperti 'double-float) operazioni)
          :overlap-worker-intervals (nreverse intervalli)
          :overlap-latency-seconds (statistiche-campioni (subseq sovrapposti 0 coperti))
          :copy (when lavoro-copia
                  (let* ((bytes (copia-bytes lavoro-copia))
                         (durata (secondi (- (copia-fine lavoro-copia) (copia-inizio lavoro-copia)))))
                    (esigi (= bytes (* (copia-record lavoro-copia) +record-bytes+)) :bytes-copia)
                    (esigi (> durata 0d0) :intervallo-copia)
                    (list :bytes bytes :blocks (copia-blocchi lavoro-copia)
                          :rate-bytes-per-second (copia-quota lavoro-copia)
                          :start-ticks (copia-inizio lavoro-copia) :end-ticks (copia-fine lavoro-copia)
                          :wall-seconds durata :bytes-per-second (/ bytes durata)
                          :pacing-sleeps (copia-attese lavoro-copia)
                          :initial-burst-bytes +blocco-bytes+
                          :quota-before-read t :target-reopened-and-byte-matched t))))))

;;; REQ: REQ-AFF-016
(defun libera-descrittori (lettori lavoro-copia)
  "Tenta ogni close una sola volta e conserva tutti gli incidenti di rilascio."
  (let ((errori nil))
    (dolist (lavoro lettori)
      (when (>= (lettore-fd lavoro) 0)
        (handler-case (chiudi (lettore-fd lavoro)) (error (condizione) (push condizione errori)))))
    (when lavoro-copia
      (dolist (fd (list (copia-source lavoro-copia) (copia-target lavoro-copia)))
        (when (>= fd 0)
          (handler-case (chiudi fd) (error (condizione) (push condizione errori))))))
    errori))

;;; REQ: REQ-BEN-001 REQ-AFF-016 REQ-AFF-002
(defun misura-caso (source dir numero workers modalita replica operazioni &key guasto)
  "Prepara prima del timing; dopo join chiude, riapre e verifica target, poi elimina solo il proprio file."
  (let ((lettori nil) (lavoro-copia nil) (creato nil) (primario nil) (pulizia nil)
        (risultato nil) (vivi nil)
        (target (merge-pathnames (format nil "copia-~D-~D-~(~A~).dat.tmp" replica workers modalita) dir)))
    (unwind-protect
         (handler-case
             (progn
               (dotimes (id workers)
                 (multiple-value-bind (piano sink) (prepara-piano numero operazioni id workers)
                   (let ((lavoro (make-lettore :piano piano :sink-atteso sink
                                             :inizi (make-array (length piano) :element-type '(unsigned-byte 64))
                                             :fini (make-array (length piano) :element-type '(unsigned-byte 64))
                                             :guasto-p (and (eq guasto :lettore) (zerop id)))))
                     (push lavoro lettori)
                     (setf (lettore-fd lavoro) (apri-lettura source)))))
               (setf lettori (nreverse lettori))
               (unless (eq modalita :none)
                 (setf lavoro-copia
                       (make-copia :record numero
                                   :quota (ecase modalita (:unlimited 0) (:mib16 (* 16 1024 1024))
                                                 (:mib64 (* 64 1024 1024)))
                                   :guasto-p (eq guasto :copia)))
                 (setf (copia-source lavoro-copia) (apri-lettura source))
                 (setf (copia-target lavoro-copia) (crea-esclusivo target) creato t))
               (avvia-worker lettori lavoro-copia))
           (error (condizione) (setf primario condizione)))
      ;; Una sola fotografia dei worker vivi; una condition incompleta conserva
      ;; le risorse anche se il worker terminasse immediatamente dopo il join.
      (setf vivi
            (or (typep primario 'worker-incompleto)
                (loop for lavoro in (append lettori (when lavoro-copia (list lavoro-copia)))
                      for thread = (thread-lavoro lavoro)
                      thereis (and thread (sb-thread:thread-alive-p thread)))))
      (unless vivi (setf pulizia (libera-descrittori lettori lavoro-copia))))
    (when vivi
      (if (typep primario 'worker-incompleto) (error primario)
          (error 'worker-incompleto :numeri :case-release :precedenti (list primario))))
    ;; La verifica riapre il target solo quando ogni descrittore di scrittura è chiuso.
    (when (and (null primario) (null pulizia))
      (handler-case
          (progn
            (when lavoro-copia (verifica-copia source target numero))
            (setf risultato (risultato-caso lettori lavoro-copia modalita replica operazioni)))
        (error (condizione) (setf primario condizione))))
    (when creato
      (handler-case (elimina-file target) (error (condizione) (push condizione pulizia))))
    (when pulizia (error "SPK-06: rilascio caso: ~S; errore primario: ~A." pulizia primario))
    (when primario (error primario))
    risultato))

;;; REQ: REQ-AFF-016
(defun check-guasti (source dir numero)
  "Iniezioni finite in due worker reali; propagazione dopo join e riapertura della source."
  (dolist (ruolo '(:lettore :copia))
    (let ((rilevato nil))
      (handler-case (misura-caso source dir numero 2 :unlimited
                                (if (eq ruolo :lettore) 10 11) 96 :guasto ruolo)
        (guasto-iniettato (condizione)
          (esigi (eq ruolo (ruolo-guasto condizione)) :ruolo-guasto)
          (setf rilevato t)))
      (esigi rilevato :guasto-propagato)))
  (verifica-fixture source numero)
  (list :status :ok :worker-errors 2 :propagation :after-join :cleanup :complete))

;;; REQ: REQ-BEN-002 REQ-AFF-002 REQ-AFF-016
(defun check (base)
  "Fixture di 12 record, 96 letture per caso, quattro modalità e due guasti espliciti."
  (con-fixture base 12
    (lambda (source dir numero)
      (let ((errori (check-guasti source dir numero)))
        (list :status :ok :file-records numero :file-bytes (* numero +record-bytes+)
              :cases (loop for modalita in '(:none :unlimited :mib16 :mib64)
                           collect (misura-caso source dir numero 2 modalita 0 96))
              :worker-errors errori :fixture-cleanup :complete)))))

;;; REQ: REQ-BEN-001 REQ-BEN-002
(defun aggiungi-rapporto-baseline (casi)
  "Rapporto al p99 della baseline abbinata; overlap assente o clock zero restano dichiarati."
  (dolist (caso casi)
    (unless (eq (getf caso :mode) :none)
      (let* ((baseline (find-if (lambda (altro)
                                 (and (eq (getf altro :mode) :none)
                                      (= (getf altro :workers) (getf caso :workers))
                                      (= (getf altro :replica) (getf caso :replica)))) casi))
             (p99 (getf (getf baseline :latency-seconds) :p99))
             (sovrapposto (getf (getf caso :overlap-latency-seconds) :p99)))
        (esigi baseline :baseline-abbinata)
        (setf (getf caso :overall-p99-ratio-to-baseline)
              (if (plusp p99) (/ (getf (getf caso :latency-seconds) :p99) p99) :clock-resolution)
              (getf caso :overlap-p99-ratio-to-baseline)
              (cond ((eq sovrapposto :not-measured) :not-measured)
                    ((zerop p99) :clock-resolution) (t (/ sovrapposto p99)))))))
  casi)

;;; REQ: REQ-BEN-001 REQ-BEN-002
(defun benchmark (base)
  "24 casi: 1/2 lettori, quattro carichi copia, tre repliche con ordine alternato.
Il file di 16 MiB è appena scritto e rientra nella RAM; cache e scheduler non controllati."
  (let ((inizio (get-internal-real-time)))
    (con-fixture base 8192
      (lambda (source dir numero)
        (let ((casi nil))
          (dotimes (replica 3)
            (dolist (workers (if (evenp replica) '(1 2) '(2 1)))
              (dolist (modalita (if (evenp replica) '(:none :unlimited :mib16 :mib64)
                                   '(:mib64 :mib16 :unlimited :none)))
                (push (misura-caso source dir numero workers modalita replica 32768) casi))))
          (setf casi (aggiungi-rapporto-baseline (nreverse casi)))
          (list :status :ok :method :pread :file-records numero :file-bytes (* numero +record-bytes+)
                :case-count (length casi) :cases casi :fixture-cleanup :complete
                :matrix-wall-seconds-before-source-final-check-and-cleanup
                (secondi (- (get-internal-real-time) inizio))
                :parameters (list :workers '(1 2) :copy-modes '(:none :unlimited :mib16 :mib64)
                                  :replicas 3 :operations-per-case 32768 :record-bytes +record-bytes+
                                  :copy-block-bytes +blocco-bytes+ :clock-ticks-per-second internal-time-units-per-second
                                  :pacing :local-token-bucket :initial-burst-bytes +blocco-bytes+
                                  :overlap :operations-fully-contained-in-measured-copy-and-reader-intervals)
                :limits '(:small-newly-written-file :uncontrolled-page-cache :synthetic-body-not-cbor
                          :copy-includes-crc-not-real-compaction :no-fsync-or-durability-claim
                          :no-latency-guarantee :no-reference-platform-claim)))))))
