;;;; Fixture C4 per GET, fonti pubblicate e lifetime del singolo FD CLOSED.
;;; OWNER: controller unico per writer/ticket; ogni worker possiede il proprio GET.
;;; SHARED: hook installato prima dello spawn e invariato fino a tutti i join; osservatore sotto mutex.
;;; Il gate nel native-read e' FI C4: non descrive un parcheggio ammesso dentro EBR nel prodotto.
;;; Le fonti vengono ridotte soltanto dopo che l'unico vecchio reader ha catturato il suo FD.
;;; Nessuna decisione durevole di catalogo, compaction o snapshot viene simulata o qualificata.
(in-package #:arcdocdb.get.directory.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

;;; REQ: REQ-CMP-007 REQ-WAL-006 REQ-IDX-001
(defstruct (directory-lifetime-fixture (:constructor %make-directory-lifetime-fixture))
  "Pre: setup esclusivo. Post: CLOSED nativo e ACTIVE vuoto della stessa Serie.
I riferimenti della fixture restano dati C4: non concedono il diritto di chiudere il FD."
  (series nil :type t :read-only t) (directory nil :type t :read-only t)
  (key nil :type t :read-only t) (value nil :type t :read-only t)
  (file nil :type t :read-only t) (id 0 :type (unsigned-byte 32) :read-only t)
  (ticket nil :type (or null e:ritiro))
  (generation 0 :type (unsigned-byte 64)))

;;; REQ: REQ-CMP-007 REQ-WAL-006 REQ-FOR-003
(defun make-directory-lifetime-fixture (version)
  "Pre: VERSION 1 o 2, setup seriale. Post: un CLOSED CSN1 e ACTIVE13 vuoto pubblicato.
Due worker con scratch/output distinti; cache disattivata e nessuno snapshot registrato.
Errori di setup propagati dopo cleanup dei soli file temporanei della fixture."
  (let ((series (make-directory-series-fixture :count 1 :workers 2 :version version
                                              :cache-p nil :record-bytes 56 :empty-active-p t))
        (complete nil))
    (unwind-protect
         (let ((directory (directory-series-fixture-directory series)))
           (prog1
               (%make-directory-lifetime-fixture
                :series series :directory directory
                :key (aref (directory-fixture-keys directory) 0)
                :value (aref (directory-fixture-values directory) 0)
                :file (aref (directory-fixture-files directory) 0)
                :id (aref (directory-fixture-ids directory) 0))
             (setf complete t)))
      (unless complete (close-directory-series-fixture series)))))

;;; REQ: REQ-CMP-007 REQ-CON-004
(defun close-directory-lifetime-fixture (fixture)
  "Pre: TUTTI i worker joined; nessun hook in esecuzione. Post: contesti poi FD propri chiusi.
Cleanup eccezionale non attesta il reclaim del ticket e non nasconde condizioni I/O.
Il test verifica il ticket prima di chiamare questa funzione; le close ripetute sono no-op."
  (let ((directory (directory-lifetime-fixture-directory fixture)))
    (setf (directory-observer-hook (directory-fixture-observer directory)) nil)
    (close-directory-series-fixture (directory-lifetime-fixture-series fixture)))
  nil)

;;; REQ: REQ-CMP-007 REQ-AFF-008
(defun directory-lifetime-reserve (fixture)
  "Pre: writer proprietario, nessun riferimento CLOSED rimosso e nessun ticket precedente.
Post: ticket/generazione reali riservati prima dell'upsert o della riduzione delle fonti.
Rifiuto di prenotazione propagato senza chiusura, pubblicazione o annullamento implicito."
  (when (directory-lifetime-fixture-ticket fixture)
    (error 'directory-fixture-error :reason :lifetime-already-reserved))
  (multiple-value-bind (ticket generation)
      (e:prenota-ritiro (directory-fixture-epochs (directory-lifetime-fixture-directory fixture))
                       (directory-lifetime-fixture-file fixture))
    (setf (directory-lifetime-fixture-ticket fixture) ticket
          (directory-lifetime-fixture-generation fixture) generation)
    (values ticket generation)))

;;; REQ: REQ-WAL-006 REQ-IDX-001 REQ-CMP-007
(defun directory-lifetime-publish-superset (fixture)
  "Pre: writer, primo lotto ACTIVE; prenotazione gia' fatta se seguira' il ritiro.
Post: PUT della stessa chiave/valore con CSN2; CAS delle fonti precede l'upsert pubblico.
Il CLOSED resta nelle fonti: candidato CSN1 gia' copiato ancora risolvibile dopo il CAS.
Non e' una rilocazione: la nuova versione ordinaria usa il proprio CSN del lotto."
  (let ((series (directory-lifetime-fixture-series fixture)))
    (directory-series-publish
     series (directory-series-stage series (directory-lifetime-fixture-key fixture)
                                    (directory-lifetime-fixture-value fixture)))))

;;; REQ: REQ-WAL-006 REQ-IDX-001 REQ-CMP-007
(defun directory-lifetime-drop-source (fixture)
  "Pre: ticket riservato, primary corrente su ACTIVE; unico vecchio GET gia' nel native-read.
Post: secondo lotto ordinario/CAS con CLOSED vuoti, poi ritiro EBR pubblicato senza close.
La fase controllata non ammette altri vecchi candidati; niente versioni trattenute/snapshot.
Errori WAL/EBR propagati; manifest durevole e rotazione generale restano precondizioni esterne."
  (let* ((series (directory-lifetime-fixture-series fixture))
         (directory (directory-lifetime-fixture-directory fixture))
         (sources (d:crea-fonti-get-serie
                   (d:crea-directory-get-serie (directory-fixture-view directory) #()))))
    (unless (directory-lifetime-fixture-ticket fixture)
      (error 'directory-fixture-error :reason :lifetime-not-reserved))
    (directory-series-publish
     series (directory-series-stage series (directory-series-fixture-active-key series)
                                    (directory-series-fixture-active-value series) :sources sources))
    (e:pubblica-ritiro (directory-lifetime-fixture-ticket fixture)
                      (directory-lifetime-fixture-generation fixture))
    (directory-series-fixture-root series)))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(defun directory-lifetime-claim (fixture)
  "Pre: ritiro pubblicato e manutenzione proprietaria. Post: T solo per soglia stretta r<s.
NIL conserva ticket e FD aperto; non scade il worker, non libera pin e non effettua I/O."
  (e:aggiorna-soglia-reclaim (directory-fixture-epochs (directory-lifetime-fixture-directory fixture)))
  (e:acquisisci-reclaim (directory-lifetime-fixture-ticket fixture)
                       (directory-lifetime-fixture-generation fixture)))

;;; REQ: REQ-CMP-007 REQ-AFF-001
(defun directory-lifetime-reclaim (fixture)
  "Pre: claim T e ultimo GET terminato/joined; FD temporaneo non piu' fonte pubblicata.
Post: una close nativa, poi completamento EBR; nessun unlink del file fino al cleanup.
Errore I/O propagato prima di COMPLETA-RECLAIM; il test non rivendica autorizzazione manifest."
  (let ((ticket (directory-lifetime-fixture-ticket fixture))
        (generation (directory-lifetime-fixture-generation fixture)))
    (unless (eq :claimed (nth-value 0 (e:leggi-ritiro ticket generation)))
      (error 'directory-fixture-error :reason :lifetime-not-claimed))
    (io:chiudi (directory-lifetime-fixture-file fixture))
    (e:completa-reclaim ticket generation))
  nil)
