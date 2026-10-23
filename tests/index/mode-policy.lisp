;;; OWNER: ogni test possiede campioni e politica.
;;; SHARED: nessuno; le decisioni non modificano l'indice o il budget.
(in-package #:arcdocdb.index.mode.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

;;; REQ: REQ-IDX-008
(deftest req-idx-008-avvio-residente-senza-paginazione-forzata
  (let ((p (m:crea-politica-indice)))
    (decisione p :iniziale 1000 1000 200 1200 :residente :avvia)
    (decisione p :iniziale 1000 1001 200 900 :paginato :avvia)
    (decisione p :iniziale 1000 1001 1000 1200 :paginato :avvia)
    (signals resource-exhausted (m:valuta-modo-indice p :iniziale 1000 1001 1001 1200)
             :index-mode-start-budget)
    (signals resource-exhausted (m:valuta-modo-indice p :iniziale 0 1 1 1)
             :index-mode-start-budget)))

;;; REQ: REQ-IDX-008
(deftest req-idx-008-crescita-prima-del-prossimo-lavoro
  (let ((p (m:crea-politica-indice)))
    (decisione p :residente 1000 1000 200 1200 :residente :mantieni)
    ;; Il prossimo lotto richiederebbe 1100, ma migrare il dataset attuale costa 950.
    (decisione p :residente 1000 1100 200 950 :paginato :prepara)
    (decisione p :residente 1000 1100 200 1000 :paginato :prepara)
    (decisione p :residente 1000 1100 200 1001 :paginato :budget-insufficiente)
    (decisione p :residente 1000 1100 1001 1200 :paginato :budget-insufficiente)))

;;; REQ: REQ-IDX-008
(deftest req-idx-008-rientro-e-banda-stabile
  (let ((p (m:crea-politica-indice)))
    (decisione p :paginato 1000 751 200 950 :paginato :mantieni)
    (decisione p :paginato 1000 750 200 1000 :residente :prepara)
    (decisione p :paginato 1000 750 200 1001 :residente :budget-insufficiente)
    ;; Dopo lo swap futuro, piccole oscillazioni non producono un cambio inverso.
    (decisione p :residente 1000 751 200 950 :residente :mantieni)
    (decisione p :paginato 1000 900 1001 1200 :paginato :budget-insufficiente)))

;;; REQ: REQ-IDX-008
(deftest req-idx-008-quote-dinamiche-e-serie-indipendenti
  (let ((p (m:crea-politica-indice)))
    (decisione p :paginato 800 700 200 900 :paginato :mantieni)
    (decisione p :paginato 1200 700 200 900 :residente :prepara)
    (decisione p :residente 600 700 200 550 :paginato :prepara)
    (decisione p :residente 1200 700 200 900 :residente :mantieni)
    (is (= 75 (m::politica-indice-rientro p)))))

;;; REQ: REQ-IDX-008
(deftest req-idx-008-arrotondamento-e-limiti-aritmetici
  (let ((p (m:crea-politica-indice :rientro-percentuale 99))
        (low (m:crea-politica-indice :rientro-percentuale 1)))
    (decisione p :paginato 101 100 1 101 :paginato :mantieni)
    (decisione p :paginato 101 99 1 101 :residente :prepara)
    (decisione low :paginato 100 1 1 100 :residente :prepara)
    (decisione low :paginato 100 2 1 100 :paginato :mantieni)
    (let* ((budget m::+max-byte-indice+) (threshold (floor (* budget 99) 100)))
      (decisione p :paginato budget threshold 1 budget :residente :prepara)
      (decisione p :paginato budget (1+ threshold) 1 budget :paginato :mantieni))))

;;; REQ: REQ-IDX-008 REQ-AFF-008
(deftest req-idx-008-rifiuti-prima-degli-effetti
  (dolist (bad '(0 100 -1 1/2 75.0 :auto))
    (signals invalid-argument (m:crea-politica-indice :rientro-percentuale bad)
             :index-mode-return-percent))
  (let ((p (m:crea-politica-indice)))
    (signals invalid-argument (m:valuta-modo-indice p :manuale 1000 700 200 900)
             :index-mode-current)
    (dolist (bad (list -1 1/2 10.0 (1+ m::+max-byte-indice+)))
      (signals invalid-argument (m:valuta-modo-indice p :residente bad 700 200 900)
               :index-mode-budget))
    (signals invalid-argument (m:valuta-modo-indice p :residente 1000 0 200 900)
             :index-mode-resident-peak)
    (signals invalid-argument (m:valuta-modo-indice p :residente 1000 700 0 900)
             :index-mode-paged-peak)
    (signals invalid-argument (m:valuta-modo-indice p :residente 1000 700 200 0)
             :index-mode-migration-peak)
    (signals invalid-argument (m:valuta-modo-indice p :residente 1000 1100 200 199)
             :index-mode-migration-underestimate)
    (signals invalid-argument (m:valuta-modo-indice p :paginato 1000 700 200 699)
             :index-mode-migration-underestimate)))

;;; REQ: REQ-IDX-008
(deftest req-idx-008-preflight-della-sola-transizione
  (let ((p (m:crea-politica-indice)))
    ;; Stesso campione, varia una condizione per volta del controllo transitorio.
    (decisione p :iniziale 1000 700 200 699 :residente :avvia)
    (decisione p :residente 1000 700 200 699 :residente :mantieni)
    (decisione p :paginato 1000 700 200 700 :residente :prepara)
    (signals invalid-argument (m:valuta-modo-indice p :paginato 1000 700 200 699)
             :index-mode-migration-underestimate)))

;;; REQ: REQ-IDX-008 REQ-AFF-008
(deftest req-idx-008-finestra-senza-allocazione
  ;; Contatore SBCL di processo: suite seriale, nessun worker ancora attivo.
  (let ((p (m:crea-politica-indice)) (sink 0))
    (declare (type fixnum sink))
    (dotimes (i 100)
      (m:valuta-modo-indice p :paginato 1000 (+ 700 (logand i 127)) 200 950))
    (sb-ext:get-bytes-consed)
    (let ((before (sb-ext:get-bytes-consed)))
      (dotimes (i 10000)
        (multiple-value-bind (target action)
            (m:valuta-modo-indice p :paginato 1000 (+ 700 (logand i 127)) 200 950)
          (when (and (eq target :residente) (eq action :prepara)) (incf sink))))
      (let ((allocated (- (sb-ext:get-bytes-consed) before)))
        (is (= 3994 sink))
        (is (zerop allocated))
        (format t "  Modo indice: 10000 decisioni, ~D byte Lisp osservati.~%" allocated)))))
