;;; OWNER: writer prepara un rebuild/split per volta; nessuna callback nella pubblicazione.
;;; SHARED: directory e generazione immutabili; CAS locale alla Serie, sorgente congelato prima.
(in-package #:arcdocdb.index.primary)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-AFF-004
(declaim (ftype (function (indice-primario root-indice frammento-indice) null) esigi-sorgente-directory))
(defun esigi-sorgente-directory (index root source)
  "Pre: writer, root corrente acquisita. Post: SOURCE è un frammento pubblicato della root.
Riferimento vecchio/estraneo rifiutato prima della costruzione o del congelamento."
  (esigi-frammento-sano index source)
  (unless (and (eq (frammento-indice-exposure source) :published)
               (<= (frammento-indice-depth source) (root-indice-depth root))
               (eq source (aref (root-indice-directory root)
                                (ash (frammento-indice-prefix source)
                                     (- (root-indice-depth root) (frammento-indice-depth source))))))
    (error 'invalid-argument :reason :primary-directory-source))
  (esigi-banco-writer (frammento-indice-bank source))
  nil)

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-AFF-008
(declaim (ftype (function (indice-primario frammento-indice integer integer) null) esigi-nuovo-frammento))
(defun esigi-nuovo-frammento (index fragment depth prefix)
  "Pre: writer, candidato costruito fuori dalla root. Post: BUILDING della geometria richiesta.
Identità/arena/banco non cambiano dopo la preparazione; il piano rileva ogni mutazione via REVISION."
  (esigi-frammento-sano index fragment)
  (unless (and (eq (frammento-indice-exposure fragment) :building)
               (= depth (frammento-indice-depth fragment)) (= prefix (frammento-indice-prefix fragment)))
    (error 'invalid-argument :reason :primary-directory-replacement))
  (esigi-banco-writer (frammento-indice-bank fragment))
  nil)

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-AFF-008
(declaim (ftype (function (indice-primario root-indice frammento-indice frammento-indice
                                         (or null frammento-indice) integer) fixnum) verifica-piano-directory))
(defun verifica-piano-directory (index old source first second transient-budget)
  "Pre: writer; copie complete già verificate dal costruttore. Post: nuova profondità e budget validi.
Il conteggio vivo uguale è necessario, non dimostra uguaglianza di chiavi/dati o correttezza dell'hash."
  (esigi-sorgente-directory index old source)
  (let* ((depth (+ (frammento-indice-depth source) (if second 1 0)))
         (prefix (* (frammento-indice-prefix source) (if second 2 1)))
         (global (max (root-indice-depth old) depth)))
    (esigi-nuovo-frammento index first depth prefix)
    (when second (esigi-nuovo-frammento index second depth (1+ prefix)))
    (unless (and (not (eq source first)) (not (eq source second)) (not (eq first second))
                 (= (frammento-indice-live source)
                    (+ (frammento-indice-live first) (if second (frammento-indice-live second) 0)))
                 (<= 1 transient-budget most-positive-fixnum))
      (error 'invalid-argument :reason :primary-directory-plan))
    (when (> global (indice-primario-max-depth index))
      (error 'resource-exhausted :reason :primary-directory-depth))
    (when (>= (root-indice-generation old) (1- +revision-limit+))
      (error 'resource-exhausted :reason :primary-directory-generation-exhausted))
    (let ((bytes (* 8 (ash 1 global))))
      (when (> bytes (indice-primario-directory-budget index))
        (error 'resource-exhausted :reason :primary-directory-memory-budget))
      (when (> (+ (payload-root old) bytes (payload-frammento first)
                  (if second (payload-frammento second) 0)) transient-budget)
        (error 'resource-exhausted :reason :primary-directory-transient-budget)))
    (esigi-revisione index)
    global))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-AFF-008
(declaim (ftype (function (root-indice frammento-indice frammento-indice (or null frammento-indice)
                                      fixnum) simple-vector) costruisci-directory))
(defun costruisci-directory (old source first second depth)
  "Pre: geometria/budget verificati. Post: nuova directory intera, nessun array corrente modificato.
Costo O(2^G nuovo), anche senza raddoppio; il solo frammento SOURCE viene sostituito."
  (let* ((previous (root-indice-directory old)) (size (ash 1 depth))
         (directory (make-array size)) (expanded (> depth (root-indice-depth old))))
    (dotimes (i size)
      (let ((fragment (aref previous (if expanded (ash i -1) i))))
        (setf (aref directory i)
              (if (eq fragment source)
                  (if (and second (logbitp (- depth (frammento-indice-depth source) 1) i)) second first)
                  fragment))))
    directory))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-AFF-008
(declaim (ftype (function (indice-primario frammento-indice frammento-indice integer
                                         &optional (or null frammento-indice)) pubblicazione-indice)
                prepara-directory-indice))
(defun prepara-directory-indice (index source first transient-budget-bytes &optional second)
  "Pre: writer, copie esatte vive del sorgente già costruite/verificate con lo stesso hash della Serie.
FIRST stesso prefisso per rebuild; FIRST/SECOND figli ordinati per split. Nessuna modifica tra fasi.
Post: piano privato monouso, directory pronta; budget corrente + candidati + nuova directory.
La prenotazione prima di costruire i candidati e le altre root trattenute restano al controller."
  (esigi-indice-sano index)
  (let* ((old (acquisisci-root index))
         (depth (verifica-piano-directory index old source first second transient-budget-bytes))
         (directory (costruisci-directory old source first second depth)))
    (%make-pubblicazione-indice index old (indice-primario-revision index) source first second
                               (%make-root-indice depth (1+ (root-indice-generation old)) directory))))

;;; REQ: REQ-IDX-005 REQ-IDX-007 REQ-AFF-004
(declaim (ftype (function (pubblicazione-indice) null) pubblica-directory-indice))
(defun pubblica-directory-indice (plan)
  "Pre: stesso gettone writer; piano valido, copie verificate e immutate. Post: nuova root via CAS.
Congela SOURCE prima dello swap, mai riaperto; piani vecchi/riusati rifiutati senza congelare.
Interruzione dopo l'avvio => indice/piano FAULTED, nessun rollback della root o I/O."
  (let* ((index (pubblicazione-indice-owner plan)) (source (pubblicazione-indice-source plan))
         (first (pubblicazione-indice-first plan)) (second (pubblicazione-indice-second plan))
         (old (pubblicazione-indice-expected plan)) (new (pubblicazione-indice-replacement plan))
         (complete nil))
    (esigi-indice-sano index)
    (unless (and (eq (pubblicazione-indice-state plan) :prepared)
                 (eq old (acquisisci-root index))
                 (= (pubblicazione-indice-revision plan) (indice-primario-revision index)))
      (error 'invalid-argument :reason :primary-directory-stale-plan))
    (esigi-sorgente-directory index old source)
    (esigi-frammento-sano index first)
    (when second (esigi-frammento-sano index second))
    (esigi-revisione index)
    (unwind-protect
         (progn
           (incf (indice-primario-revision index))
           (congela-banco-slot (frammento-indice-bank source))
           (setf (frammento-indice-exposure source) :retired (frammento-indice-exposure first) :published)
           (when second (setf (frammento-indice-exposure second) :published))
           (sb-thread:barrier (:write))
           (unless (eq old (sb-ext:compare-and-swap (indice-primario-root index) old new))
             (guasto-indice index :primary-directory-cas))
           (esigi-indice-sano index)
           (setf (pubblicazione-indice-state plan) :published complete t))
      (unless complete
        (setf (pubblicazione-indice-state plan) :faulted)
        (invalida-indice-primario index))))
  nil)
