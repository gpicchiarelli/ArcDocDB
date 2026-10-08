;;;; SPK-06: modello finito del carico e delle quote, senza thread o I/O.
;;; REQ: REQ-VAL-001 REQ-MRG-003 REQ-MRG-004 REQ-CMP-006 REQ-AFF-013
(defpackage #:arcdocdb.spk06.controllore
  (:use #:cl)
  (:export #:check #:esegui-traccia))
(in-package #:arcdocdb.spk06.controllore)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defconstant +massimo-campioni+ 256)
(defconstant +massimo-tempo-ms+ 1000000)
(defconstant +passo-ms+ 500)
(defconstant +permanenza-bassa-ms+ 10000)
(defconstant +abbandono-alto-ms+ 30000)
(defconstant +stabilita-merge-ms+ 50000)
(defconstant +massimo-byte+ 268435456)

;;; OWNER: un solo esecutore della traccia; nessuno stato condiviso.
;;; REQ: REQ-MRG-004 REQ-CMP-006
(defstruct (carico (:constructor %nuovo-carico))
  "Stato del modello; EWMA esatta, massimo 256 aggiornamenti per istanza."
  (campioni 0 :type (integer 0 256))
  (ultimo-tempo nil :type (or null (integer 0 1000000)))
  (p99 nil :type (or null rational))
  (io nil :type (or null rational))
  (basso-da nil :type (or null (integer 0 1000000)))
  (alto-da nil :type (or null (integer 0 1000000)))
  (stato :normale :type (member :basso :normale :alto))
  (merge :inattivo :type (member :inattivo :in-corso :sospeso :abbandonato)))

;;; REQ: REQ-MRG-004 REQ-CMP-006
(defstruct (quota (:constructor %nuova-quota))
  "Token bucket finito: il credito in byte può avere denominatore 1000."
  (capacita 262144 :type (integer 1 1048576))
  (banda 16777216 :type (integer 1 134217728))
  (credito 262144 :type rational)
  (tempo 0 :type (integer 0 1000000)))

;;; REQ: REQ-VAL-001 REQ-AFF-013
(define-condition dato-rifiutato (error)
  ((regola :initarg :regola :reader regola-rifiuto))
  (:report (lambda (condizione flusso)
             (format flusso "SPK-06 controllore: ~S." (regola-rifiuto condizione)))))

(defun rifiuta (regola)
  "Segnala un input fuori dominio prima della pubblicazione del nuovo stato."
  (error 'dato-rifiutato :regola regola))

(defun elementi-limitati (lista massimo)
  "Accetta una lista propria entro MASSIMO cons; rifiuta anche liste circolari."
  (let ((resto lista))
    (dotimes (n massimo)
      (when (null resto) (return-from elementi-limitati lista))
      (unless (consp resto) (rifiuta :lista-impropria))
      (setf resto (cdr resto)))
    (unless (null resto) (rifiuta :lista-fuori-budget)))
  lista)

(defun valida-plist (lista chiavi)
  "Plist propria, senza duplicati o chiavi sconosciute, al massimo 32 elementi."
  (elementi-limitati lista 32)
  (unless (evenp (length lista)) (rifiuta :plist-incompleta))
  (let ((viste nil))
    (loop for chiave in lista by #'cddr
          do (unless (and (member chiave chiavi :test #'eq)
                          (not (member chiave viste :test #'eq)))
               (rifiuta :chiave-plist))
             (push chiave viste)))
  lista)

(defun booleano-p (valore)
  "Il modello ammette solo T e NIL per gli indicatori."
  (or (eq valore t) (null valore)))

(defun tempo-valido-p (tempo)
  "Dominio del clock iniettato: millisecondi interi da zero a un milione."
  (typep tempo '(integer 0 1000000)))

;;; REQ: REQ-MRG-003 REQ-AFF-013
(defun valida-candidato (candidato tempo)
  "Valida il candidato senza interpretare un timestamp del processo precedente."
  (valida-plist candidato '(:closed-p :immutabile-p :active-p :snapshot-p
                            :stabile-da-ms :fine-recovery-ms :gruppo))
  (dolist (chiave '(:closed-p :immutabile-p :active-p :snapshot-p))
    (unless (loop for presente in candidato by #'cddr thereis (eq presente chiave))
      (rifiuta :indicatore-candidato-mancante))
    (unless (booleano-p (getf candidato chiave)) (rifiuta :indicatore-candidato)))
  (let ((stabile (getf candidato :stabile-da-ms))
        (recovery (getf candidato :fine-recovery-ms))
        (gruppo (getf candidato :gruppo)))
    (unless (and (tempo-valido-p tempo) (tempo-valido-p stabile)
                 (or (null recovery) (tempo-valido-p recovery))
                 (typep gruppo '(integer 0 32)))
      (rifiuta :dominio-candidato))
    ;; Dopo recovery il vecchio clock non ha relazione con quello attuale.
    (when (> (if recovery recovery stabile) tempo) (rifiuta :stabilita-futura)))
  candidato)

;;; REQ: REQ-MRG-003
(defun merge-ammissibile-p (candidato tempo stato)
  "Congiunzione delle condizioni; i 50 s sono inclusivi e non garantiscono progressi."
  (valida-candidato candidato tempo)
  (unless (member stato '(:basso :normale :alto) :test #'eq) (rifiuta :stato-carico))
  (let ((origine (or (getf candidato :fine-recovery-ms)
                    (getf candidato :stabile-da-ms))))
    (and (getf candidato :closed-p) (getf candidato :immutabile-p)
         (not (getf candidato :active-p)) (not (getf candidato :snapshot-p))
         (>= (- tempo origine) +stabilita-merge-ms+)
         (>= (getf candidato :gruppo) 8) (eq stato :basso))))

;;; REQ: REQ-CMP-006 REQ-MRG-004
(defun valida-clean (candidati)
  "Al massimo 32 candidati CLEAN, identificativi distinti e contatori limitati."
  (elementi-limitati candidati 32)
  (let ((viste nil))
    (dolist (candidato candidati)
      (valida-plist candidato '(:id :dead-millimi :dead-bytes))
      (let ((id (getf candidato :id)) (rapporto (getf candidato :dead-millimi))
            (byte (getf candidato :dead-bytes)))
        (unless (and (typep id '(integer 0 31))
                     (not (member id viste :test #'eql))
                     (typep rapporto '(integer 0 1000))
                     (typep byte '(integer 0 268435456)))
          (rifiuta :dominio-clean))
        (push id viste))))
  candidati)

(defun politica-compaction (stato merge candidati)
  "Ordina solo copie delle liste; la priorità dichiarata non è uno scheduler reale."
  (valida-clean candidati)
  (let* ((ammessi (remove-if-not
                  (lambda (c)
                    (if (eq stato :alto)
                        (>= (getf c :dead-millimi) 800)
                        (or (>= (getf c :dead-millimi) 500)
                            (>= (getf c :dead-bytes) (* 64 1024 1024)))))
                  candidati))
         (ordinati (stable-sort ammessi #'> :key (lambda (c) (getf c :dead-bytes))))
         (limite (if (eq stato :basso) 2 1)))
    (list :priorita '(:utente :log :clean :merge)
          :clean-workers-max limite
          :clean-selezionati (mapcar (lambda (c) (getf c :id))
                                    (subseq ordinati 0 (min limite (length ordinati))))
          :nuovo-merge-ammesso (eq stato :basso)
          :merge-workers-max (if (eq stato :basso) 1 0)
          :banda-merge (case merge
                        (:in-corso (if (eq stato :basso) :piena :ridotta))
                        (:sospeso :sospesa)
                        (otherwise :nessuna)))))

;;; REQ: REQ-MRG-004 REQ-CMP-006 REQ-AFF-013
(defun aggiorna-carico (carico campione)
  "Un passo da 500 ms; calcola e valida tutto prima di cambiare CARICO.
Primo campione inizializza le EWMA; poi alpha=1/2 esatta, senza arrotondamento.
Il tetto di 256 passi limita anche il numero di bit dei razionali."
  (valida-plist campione '(:tempo-ms :p99-millimi :io-millimi :richiesta-merge :clean))
  (let* ((tempo (getf campione :tempo-ms)) (p99 (getf campione :p99-millimi))
         (io (getf campione :io-millimi))
         (candidato (getf campione :richiesta-merge))
         (clean (getf campione :clean)) (ultimo (carico-ultimo-tempo carico)))
    (unless (and (tempo-valido-p tempo) (typep p99 '(integer 0 2000))
                 (typep io '(integer 0 2000)))
      (rifiuta :dominio-campione))
    (when (>= (carico-campioni carico) +massimo-campioni+) (rifiuta :campioni-fuori-budget))
    (when (and ultimo (/= (- tempo ultimo) +passo-ms+)) (rifiuta :passo-clock))
    (when candidato (valida-candidato candidato tempo))
    (valida-clean clean)
    (let* ((smussato-p99 (if ultimo (/ (+ (carico-p99 carico) p99) 2) p99))
           (smussato-io (if ultimo (/ (+ (carico-io carico) io) 2) io))
           (alto-p (or (> smussato-p99 800) (> smussato-io 800)))
           (basso-p (and (< smussato-p99 400) (< smussato-io 400)))
           (basso-da (and basso-p (or (carico-basso-da carico) tempo)))
           (alto-da (and alto-p (or (carico-alto-da carico) tempo)))
           (stato (cond (alto-p :alto)
                        ((and basso-da (>= (- tempo basso-da) +permanenza-bassa-ms+)) :basso)
                        (t :normale)))
           (richiesta-ammessa (and candidato (merge-ammissibile-p candidato tempo stato)
                                  (member (carico-merge carico) '(:inattivo :abbandonato)
                                          :test #'eq)))
           (merge (cond (richiesta-ammessa :in-corso)
                        ((member (carico-merge carico) '(:in-corso :sospeso) :test #'eq)
                         (cond ((and alto-da (>= (- tempo alto-da) +abbandono-alto-ms+))
                                :abbandonato)
                               (alto-p :sospeso)
                               (t :in-corso)))
                        (t (carico-merge carico))))
           (politica (politica-compaction stato merge clean))
           (esito (list :tempo-ms tempo :stato stato :p99-ewma-millimi smussato-p99
                        :io-ewma-millimi smussato-io :basso-da-ms basso-da :alto-da-ms alto-da
                        :merge merge :richiesta-merge-ammessa (not (null richiesta-ammessa))
                        :politica politica)))
      (setf (carico-ultimo-tempo carico) tempo (carico-p99 carico) smussato-p99
            (carico-io carico) smussato-io (carico-basso-da carico) basso-da
            (carico-alto-da carico) alto-da (carico-stato carico) stato
            (carico-merge carico) merge)
      (incf (carico-campioni carico))
      esito)))

;;; REQ: REQ-MRG-004 REQ-CMP-006 REQ-AFF-013
(defun consuma-token (quota tempo byte)
  "Refill esatto e cap alla capacità; rifiuti e quota insufficiente non mutano nulla.
Secondo valore: attesa minima aritmetica in ms, senza promessa di latenza o scheduler."
  (unless (and (tempo-valido-p tempo) (>= tempo (quota-tempo quota))
               (typep byte '(integer 1 1048576)) (<= byte (quota-capacita quota)))
    (rifiuta :dominio-quota))
  (let ((disponibile (min (quota-capacita quota)
                         (+ (quota-credito quota)
                            (/ (* (quota-banda quota) (- tempo (quota-tempo quota))) 1000)))))
    (if (>= disponibile byte)
        (progn (setf (quota-tempo quota) tempo (quota-credito quota) (- disponibile byte))
               (values t 0))
        (values nil (ceiling (* (- byte disponibile) 1000) (quota-banda quota))))))

;;; REQ: REQ-VAL-001 REQ-MRG-004 REQ-CMP-006
(defun parametri-modello ()
  "Default dichiarati; limiti dei worker e CLEAN in MiB sono proposte dello spike."
  (list :sample-period-ms +passo-ms+ :ewma-alpha 1/2 :ewma-arithmetic :exact-rational
        :max-samples +massimo-campioni+ :max-time-ms +massimo-tempo-ms+
        :ratio-domain-millimi '(0 2000) :high-strictly-above 800 :low-strictly-below 400
        :low-continuous-ms +permanenza-bassa-ms+ :high-abandon-continuous-ms +abbandono-alto-ms+
        :merge-stability-ms +stabilita-merge-ms+ :merge-min-group 8
        :experimental-clean-low-workers 2 :experimental-clean-normal-workers 1
        :experimental-clean-min-dead-bytes (* 64 1024 1024)))

;;; REQ: REQ-VAL-001 REQ-MRG-003 REQ-MRG-004 REQ-CMP-006 REQ-AFF-013
(defun esegui-traccia (traccia &key (merge-iniziale :inattivo))
  "Esegue fino a 256 campioni da 500 ms senza attese reali, senza claim sulle allocazioni.
MERGE-INIZIALE può rappresentare un lavoro già avviato; nessun file è pubblicato o rimosso."
  (elementi-limitati traccia +massimo-campioni+)
  (unless (and traccia (member merge-iniziale '(:inattivo :in-corso :sospeso :abbandonato)
                                  :test #'eq))
    (rifiuta :inizializzazione-traccia))
  (let ((carico (%nuovo-carico :merge merge-iniziale)) (campioni nil) (transizioni nil))
    (dolist (campione traccia)
      (let* ((prima (carico-stato carico)) (merge-prima (carico-merge carico))
             (esito (aggiorna-carico carico campione)))
        (unless (and (eq prima (carico-stato carico)) (eq merge-prima (carico-merge carico)))
          (push (list :tempo-ms (carico-ultimo-tempo carico) :da prima :a (carico-stato carico)
                      :merge-da merge-prima :merge-a (carico-merge carico)) transizioni))
        (push esito campioni)))
    (list :status :ok :sample-count (carico-campioni carico) :transition-count (length transizioni)
          :transitions (nreverse transizioni) :samples (nreverse campioni)
          :policy-parameters (parametri-modello) :scope :finite-serial-model-no-io)))

(defun richiedi (condizione regola)
  "Oracle deterministico: ogni mancata proprietà produce un errore esplicito."
  (unless condizione (error "SPK-06 check: ~S." regola))
  nil)

(defun stato-copiato (carico)
  "Fotografia indipendente dei campi che possono cambiare nel passo."
  (list (carico-campioni carico) (carico-ultimo-tempo carico) (carico-p99 carico)
        (carico-io carico) (carico-basso-da carico) (carico-alto-da carico)
        (carico-stato carico) (carico-merge carico)))

(defun campione (tempo p99 io &rest opzioni)
  "Fixture di input; OPZIONI è una plist usata solo nei check finiti."
  (append (list :tempo-ms tempo :p99-millimi p99 :io-millimi io) opzioni))

(defun traccia-costante (numero p99 io &key (origine 0))
  "Costruisce un numero limitato di campioni equispaziati."
  (unless (typep numero '(integer 1 256)) (rifiuta :dimensione-fixture))
  (loop for n below numero collect (campione (+ origine (* n +passo-ms+)) p99 io)))

(defun attendi-rifiuto (funzione regola)
  "Verifica anche il tipo dell'errore e la regola segnalata."
  (let ((rilevato nil))
    (handler-case (funcall funzione)
      (dato-rifiutato (c)
        (richiedi (eq regola (regola-rifiuto c)) :regola-rifiuto-inattesa)
        (setf rilevato t)))
    (richiedi rilevato :input-non-rifiutato)))

;;; REQ: REQ-MRG-004
(defun check-req-mrg-004 ()
  "Soglie strette, EWMA esatta, timer inclusivi e ripartenza del timer alto."
  (let ((soglie '((399 399 :normale 0 nil) (400 399 :normale nil nil)
                  (799 799 :normale nil nil) (800 800 :normale nil nil)
                  (801 0 :alto nil 0) (0 801 :alto nil 0)
                  (399 800 :normale nil nil) (2000 2000 :alto nil 0))))
    (dolist (caso soglie)
      (destructuring-bind (p99 io stato basso alto) caso
        (let ((c (%nuovo-carico)))
          (aggiorna-carico c (campione 0 p99 io))
          (richiedi (and (eq stato (carico-stato c)) (eql basso (carico-basso-da c))
                         (eql alto (carico-alto-da c))) :soglie)))))
  (let ((c (%nuovo-carico)))
    (aggiorna-carico c (campione 0 1 3))
    (aggiorna-carico c (campione 500 2 0))
    (richiedi (and (= (carico-p99 c) 3/2) (= (carico-io c) 3/2)) :ewma-esatta))
  (let* ((esito (esegui-traccia (traccia-costante 21 399 399)))
         (punti (getf esito :samples)))
    (richiedi (eq :normale (getf (nth 19 punti) :stato)) :basso-prima-di-10s)
    (richiedi (eq :basso (getf (nth 20 punti) :stato)) :basso-a-10s)
    (richiedi (= 1 (getf esito :transition-count)) :conteggio-transizioni))
  (let ((c (%nuovo-carico)))
    (dolist (p (traccia-costante 21 399 399)) (aggiorna-carico c p))
    ;; 401 produce EWMA 400: deve interrompere la permanenza bassa.
    (aggiorna-carico c (campione 10500 401 401))
    (richiedi (and (eq :normale (carico-stato c)) (null (carico-basso-da c))) :reset-basso)
    (dolist (p (traccia-costante 20 399 399 :origine 11000)) (aggiorna-carico c p))
    (richiedi (and (= (carico-basso-da c) 11000) (eq :normale (carico-stato c)))
              :basso-riparte)
    (aggiorna-carico c (campione 21000 399 399))
    (richiedi (eq :basso (carico-stato c)) :nuovi-10s))
  (let* ((esito (esegui-traccia (traccia-costante 61 801 801) :merge-iniziale :in-corso))
         (punti (getf esito :samples)))
    (richiedi (eq :sospeso (getf (first punti) :merge)) :sospendi-subito)
    (richiedi (eq :sospeso (getf (nth 59 punti) :merge)) :prima-di-30s)
    (richiedi (eq :abbandonato (getf (nth 60 punti) :merge)) :abbandona-a-30s))
  (let ((c (%nuovo-carico :merge :in-corso)))
    (aggiorna-carico c (campione 0 801 801))
    (aggiorna-carico c (campione 500 799 799))
    (richiedi (and (null (carico-alto-da c)) (eq :in-corso (carico-merge c))) :reset-alto)
    (dolist (p (traccia-costante 60 802 802 :origine 1000)) (aggiorna-carico c p))
    (richiedi (and (= (carico-alto-da c) 1000) (eq :sospeso (carico-merge c))) :alto-riparte)
    (aggiorna-carico c (campione 31000 802 802))
    (richiedi (eq :abbandonato (carico-merge c)) :nuovi-30s))
  (list :status :ok :requirement :req-mrg-004 :groups 6 :threshold-cases 8))

;;; REQ: REQ-MRG-003
(defun check-req-mrg-003 ()
  "Candidato con condizioni congiunte, 50 s inclusivi e clock dopo recovery."
  (let ((base '(:closed-p t :immutabile-p t :active-p nil :snapshot-p nil
               :stabile-da-ms 0 :gruppo 8)))
    (richiedi (not (merge-ammissibile-p base 49999 :basso)) :merge-prima-di-50s)
    (richiedi (merge-ammissibile-p base 50000 :basso) :merge-a-50s)
    (dolist (variante '((:closed-p nil) (:immutabile-p nil) (:active-p t)
                       (:snapshot-p t) (:gruppo 7)))
      (let ((copia (copy-list base)))
        (setf (getf copia (first variante)) (second variante))
        (richiedi (not (merge-ammissibile-p copia 50000 :basso)) :condizione-obbligatoria)))
    (dolist (stato '(:normale :alto))
      (richiedi (not (merge-ammissibile-p base 50000 stato)) :merge-solo-a-basso-carico))
    (let ((recovery (append '(:fine-recovery-ms 1000) (copy-list base))))
      (setf (getf recovery :stabile-da-ms) 900000)
      (richiedi (not (merge-ammissibile-p recovery 50999 :basso)) :recovery-prima-di-50s)
      (richiedi (merge-ammissibile-p recovery 51000 :basso) :recovery-a-50s))
    (let ((c (%nuovo-carico)))
      (dolist (p (traccia-costante 21 0 0 :origine 40000)) (aggiorna-carico c p))
      (let ((p (aggiorna-carico c (campione 50500 0 0 :richiesta-merge base))))
        (richiedi (and (getf p :richiesta-merge-ammessa) (eq :in-corso (carico-merge c)))
                  :avvio-ammesso)))
    (let ((c (%nuovo-carico)))
      (aggiorna-carico c (campione 50000 800 800 :richiesta-merge base))
      (richiedi (eq :inattivo (carico-merge c)) :richiesta-in-normale)))
  (list :status :ok :requirement :req-mrg-003 :groups 6 :individual-conditions 5))

;;; REQ: REQ-CMP-006 REQ-MRG-004
(defun check-req-cmp-006 ()
  "Priorità CLEAN, nessuna mutazione dei candidati, quote finite e credito conservato."
  (let* ((candidati '((:id 0 :dead-millimi 799 :dead-bytes 90000000)
                     (:id 1 :dead-millimi 800 :dead-bytes 80000000)
                     (:id 2 :dead-millimi 900 :dead-bytes 70000000)))
         (prima (copy-tree candidati))
         (alto (politica-compaction :alto :sospeso candidati))
         (basso (politica-compaction :basso :in-corso candidati))
         (normale (politica-compaction :normale :in-corso candidati)))
    (richiedi (equal (getf alto :clean-selezionati) '(1)) :clean-urgente)
    (richiedi (and (= 1 (getf alto :clean-workers-max))
                   (not (getf alto :nuovo-merge-ammesso))
                   (eq :sospesa (getf alto :banda-merge))) :limiti-alto)
    (richiedi (and (equal (getf basso :clean-selezionati) '(0 1))
                   (getf basso :nuovo-merge-ammesso)
                   (eq :piena (getf basso :banda-merge))) :limiti-basso)
    (richiedi (and (not (getf normale :nuovo-merge-ammesso))
                   (eq :ridotta (getf normale :banda-merge))) :limiti-normale)
    (richiedi (equal (getf alto :priorita) '(:utente :log :clean :merge)) :ordine-priorita)
    (richiedi (equalp prima candidati) :candidati-immutati))
  (let ((q (%nuova-quota :capacita 100 :banda 100 :credito 100)) (consumati 0))
    (multiple-value-bind (ammesso attesa) (consuma-token q 0 100)
      (richiedi (and ammesso (zerop attesa) (zerop (quota-credito q))) :quota-esatta)
      (incf consumati 100))
    (let ((prima (list (quota-credito q) (quota-tempo q))))
      (multiple-value-bind (ammesso attesa) (consuma-token q 1 1)
        (richiedi (and (null ammesso) (= attesa 9)) :quota-insufficiente))
      (richiedi (equal prima (list (quota-credito q) (quota-tempo q))) :rifiuto-immutato))
    (dotimes (n 20)
      (richiedi (consuma-token q (* (1+ n) 500) 50) :quota-finita)
      (incf consumati 50)
      (richiedi (<= 0 (quota-credito q) (quota-capacita q)) :credito-limitato))
    (richiedi (= consumati (+ 100 (/ (* 100 10000) 1000))) :conservazione-quota)
    (richiedi (consuma-token q 11000 100) :refill-cap)
    (richiedi (zerop (quota-credito q)) :cap-esatto)
    (let ((prima (list (quota-credito q) (quota-tempo q))))
      (dolist (richiesta '((10999 1) (11000 101) (11000 0) (1000001 1)))
        (attendi-rifiuto (lambda () (consuma-token q (first richiesta) (second richiesta)))
                         :dominio-quota)
        (richiedi (equal prima (list (quota-credito q) (quota-tempo q))) :errore-quota-immutato))))
  (let ((q (%nuova-quota :capacita 100 :banda 100 :credito 0)))
    (richiedi (consuma-token q 10000 1) :refill-lungo)
    (richiedi (= 99 (quota-credito q)) :credito-non-supera-cap))
  (let ((q (%nuova-quota :capacita 100 :banda 1 :credito 0)))
    (multiple-value-bind (ammesso attesa) (consuma-token q 100 1)
      (richiedi (and (null ammesso) (= attesa 900)) :credito-frazionario))
    (richiedi (consuma-token q 1000 1) :credito-frazionario-completo)
    (richiedi (zerop (quota-credito q)) :credito-frazionario-esatto))
  (list :status :ok :requirement :req-cmp-006 :policy-groups 6 :quota-consumptions 22
        :quota-rejections 5 :quota-extra-groups 2))

;;; REQ: REQ-VAL-001 REQ-AFF-013
(defun check-req-aff-013 ()
  "Rifiuti prima delle mutazioni; schema, clock, numeri e limite di traccia."
  (let ((c (%nuovo-carico)))
    (aggiorna-carico c (campione 0 1 1))
    (let ((prima (stato-copiato c)))
      (dolist (caso (list (list (campione 499 1 1) :passo-clock)
                         (list (campione 0 1 1) :passo-clock)
                         (list (campione -1 1 1) :dominio-campione)
                         (list (campione 500 -1 1) :dominio-campione)
                         (list (campione 500 2001 1) :dominio-campione)
                         (list (campione 500 1 1/2) :dominio-campione)
                         (list (campione 500 1 1 :sconosciuta t) :chiave-plist)
                         (list (campione 500 1 1 :tempo-ms 500) :chiave-plist)
                         (list (campione 500 1 1 :richiesta-merge '(:gruppo 8))
                               :indicatore-candidato-mancante)
                         (list (campione 500 1 1 :richiesta-merge
                                         '(:closed-p 2 :immutabile-p t :active-p nil :snapshot-p nil
                                           :stabile-da-ms 0 :gruppo 8)) :indicatore-candidato)
                         (list (campione 500 1d0 1) :dominio-campione)
                         (list (campione 500 1 1 :clean '((:id 0 :dead-millimi 1001 :dead-bytes 1)))
                               :dominio-clean)))
        (attendi-rifiuto (lambda () (aggiorna-carico c (first caso))) (second caso))
        (richiedi (equal prima (stato-copiato c)) :nessuna-mutazione-parziale))))
  (let* ((traccia (traccia-costante 256 0 2000)) (esito (esegui-traccia traccia)))
    (richiedi (= 256 (getf esito :sample-count)) :limite-traccia-inclusivo)
    (attendi-rifiuto (lambda () (esegui-traccia (append traccia (list (campione 128000 0 2000)))))
                     :lista-fuori-budget))
  (let ((c (%nuovo-carico)))
    (dolist (p (traccia-costante 256 0 0)) (aggiorna-carico c p))
    (let ((prima (stato-copiato c)))
      (attendi-rifiuto (lambda () (aggiorna-carico c (campione 128000 0 0))) :campioni-fuori-budget)
      (richiedi (equal prima (stato-copiato c)) :budget-immutato)))
  (attendi-rifiuto (lambda () (esegui-traccia nil)) :inizializzazione-traccia)
  (let ((circolare (list (campione 0 1 1))))
    (setf (cdr circolare) circolare)
    (attendi-rifiuto (lambda () (esegui-traccia circolare)) :lista-fuori-budget))
  (attendi-rifiuto (lambda () (esegui-traccia (cons (campione 0 1 1) :fine))) :lista-impropria)
  (list :status :ok :requirement :req-aff-013 :invalid-samples 12 :trace-budget 256
        :trace-rejections 5 :partial-mutation :none-observed))

;;; REQ: REQ-VAL-001 REQ-MRG-003 REQ-MRG-004 REQ-CMP-006 REQ-AFF-013
(defun check ()
  "Prove deterministiche finite; nessun benchmark o lavoro di compaction reale."
  (let ((gruppi (list (check-req-mrg-004) (check-req-mrg-003)
                     (check-req-cmp-006) (check-req-aff-013))))
    (list :status :ok :module :controllore :groups gruppi
          :policy-parameters (parametri-modello)
          :limits '(:finite-model :exact-ewma-with-bounded-input-count :no-real-time-guarantee
                    :no-live-device-measurements :no-durability :no-worker-pool-aimd
                    :no-allocation-claim :merge-starvation-accepted))))
