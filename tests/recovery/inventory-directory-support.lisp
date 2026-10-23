;;;; C4: inventari dichiarati, backend privato e namespace nativi CONTROL 0700.
;;; OWNER: ogni chiamata possiede nomi, contatori e capacità fino al cleanup seriale.
;;; SHARED: nessun override globale, worker o stato condiviso fra fixture.
(in-package #:arcdocdb.recovery.tests)
(declaim (optimize (safety 3) (debug 3)))

(defstruct (idr-state (:constructor idr-make-state (names)))
  "Backend C4: al massimo 64 nomi; nessun FD nativo è fabbricato o riutilizzato."
  names (complete t) directory enum-hook identity-hook (events nil))

(defun idr-name (id form)
  "Oracolo letterale: sedici cifre esadecimali minuscole e suffisso della specifica."
  (string-downcase (format nil "~16,'0X.seg~A" id (if (eq form :temporary) ".tmp" ""))))

(defun idr-names (specs &rest ignored)
  "Vettore posseduto; l'ordine fisico è quello dichiarato, non quello del planner."
  (coerce (append (mapcar (lambda (spec) (idr-name (first spec) (second spec))) specs)
                  (mapcar #'copy-seq ignored)) 'simple-vector))

(defun idr-forbidden (state operation &rest arguments)
  "Ogni effetto diverso da enum/identità/close rende la fixture immediatamente falsa."
  (push (cons operation arguments) (idr-state-events state))
  (error "Operazione inventario inattesa: ~S" operation))

(defun idr-backend (state enumeration-p identity-p)
  "Solo callback della fixture: apertura/chiusura locali, nessun fallback nativo."
  (arcdocdb.io:make-backend
   (lambda (path mode) (declare (ignore path mode)) 71)
   (lambda (&rest args) (apply #'idr-forbidden state :read args))
   (lambda (&rest args) (apply #'idr-forbidden state :write args))
   (lambda (&rest args) (apply #'idr-forbidden state :flush args))
   (lambda (&rest args) (apply #'idr-forbidden state :directory-flush args))
   (lambda (fd) (is (= fd 71)) (push '(:close) (idr-state-events state)) 0)
   :directory-entries
   (when enumeration-p
     (lambda (fd names total single)
       (is (= fd 71))
       (push (list :enumerate names total single) (idr-state-events state))
       (when (idr-state-enum-hook state) (funcall (idr-state-enum-hook state) state))
       (values (idr-state-names state) (idr-state-complete state))))
   :entry-identity
   (when identity-p
     (lambda (fd name)
       (is (= fd 71)) (push (list :identity (copy-seq name)) (idr-state-events state))
       (if (idr-state-identity-hook state)
           (funcall (idr-state-identity-hook state) state name)
           (values 5 (1+ (position name (idr-state-names state) :test #'string=))))))))

(defun idr-run (names thunk &key (enumeration-p t) (identity-p t) (mode :directory))
  "Confine C4 seriale: capacità presa in prestito dal prodotto, cleanup una sola volta."
  (is (or (not (vectorp names)) (<= (length names) 64)))
  (let* ((state (idr-make-state names)) (backend (idr-backend state enumeration-p identity-p))
         (directory (ecase mode
                      (:directory (arcdocdb.io:apri-directory "/inventory-fixture" :backend backend))
                      (:input (arcdocdb.io:apri-lettura "/inventory-fixture" :backend backend)))))
    (setf (idr-state-directory state) directory)
    (unwind-protect (funcall thunk state directory)
      (arcdocdb.io:chiudi directory))))

(defun idr-observation (directory)
  "Stato e frontiere pubbliche: l'inventario non consuma la capacità prestata."
  (list (arcdocdb.io:stato-file directory) (arcdocdb.io:posizione-scritta directory)
        (arcdocdb.io:posizione-durevole directory)))

(defun idr-enumerations (state)
  (count :enumerate (idr-state-events state) :key #'first))

(defun idr-plan (manifest directory &rest options)
  "Invoca soltanto l'ingresso pubblico del nuovo adattatore."
  (apply #'arcdocdb.recovery.manifest:pianifica-riconciliazione-directory
         manifest directory options))

(defun idr-check (state directory manifest active closed removed specs &rest options)
  "Oracolo ADR già indipendente; preservazione dei nomi e della capacità anche dopo errore."
  (let ((before (map 'simple-vector #'copy-seq (idr-state-names state)))
        (observation (idr-observation directory)))
    (unwind-protect
         (let ((plan (apply #'idr-plan manifest directory options)))
           (inventory-assert-plan plan (inventory-oracle active closed removed specs)) plan)
      (is (equalp before (idr-state-names state)))
      (is (equal observation (idr-observation directory))))))

(defun idr-native-file (fixture path name deadline)
  "Due nomi registrati prima di create/rename C4; byte indipendenti e FD readonly conservato."
  (let* ((target (arcdocdb.control.tests::native-leaf fixture path name))
         (seed (arcdocdb.control.tests::native-leaf fixture path (concatenate 'string name ".seed.tmp")))
         (image (make-array 5 :element-type '(unsigned-byte 8) :initial-contents '(0 13 255 7 81))))
    (arcdocdb.control.tests::native-write-copy fixture seed image deadline)
    (sb-posix:rename (namestring seed) (namestring target))
    (list target (arcdocdb.control.tests::native-open fixture target :input deadline) image)))

(defun idr-native-check-files (files deadline)
  "Oracolo fisico separato: byte, EOF, identità e frontiere dei soli FD registrati."
  (loop for file in files collect
    (progn (arcdocdb.control.tests::native-read-bytes (second file) (third file) deadline)
           (arcdocdb.control.tests::native-observation (second file)))))

(defun idr-native-plan (directory manifest deadline)
  "La deadline riguarda solo capacità già registrate; nessuna apertura interrotta."
  (arcdocdb.control.tests::native-bounded deadline :inventory-directory
    (lambda () (idr-plan manifest directory :max-files 32 :max-segmenti 32
                         :max-names 64 :max-total-name-bytes 4096 :max-name-bytes 255))))

(defun idr-native-check (fixture directory manifest active closed removed specs files deadline)
  "Input nativi intatti: FD e byte uguali, zero effetti sugli altri adattatori osservati."
  (let ((before (idr-native-check-files files deadline))
        (observation (arcdocdb.control.tests::native-observation directory))
        (calls (copy-seq (arcdocdb.control.tests::native-observer-calls
                         (arcdocdb.control.tests::native-fixture-observer fixture)))))
    (unwind-protect
         (let ((plan (idr-native-plan directory manifest deadline)))
           (inventory-assert-plan plan (inventory-oracle active closed removed specs)) plan)
      (is (equal observation (arcdocdb.control.tests::native-observation directory)))
      (is (equalp calls (arcdocdb.control.tests::native-observer-calls
                        (arcdocdb.control.tests::native-fixture-observer fixture))))
      (is (equal before (idr-native-check-files files deadline))))))
