(in-package #:arcdocdb.fulltext.admission)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-010
(declaim (ftype (function (simple-vector) null) verifica-configurazioni-riserve))
(defun verifica-configurazioni-riserve (configs)
  "Pre: vettore di 1..16 configurazioni canoniche. Post: ordine (indice,generazione),
al piu otto indici e due generazioni per indice; nessuna copia di ID sul percorso caldo."
  (let ((prior 0) (generation 0) (indices 0) (generations 0))
    (dotimes (i (length configs))
      (let ((config (svref configs i)))
        (unless (typep config 'd:configurazione-full-text)
          (error 'invalid-argument :reason :fulltext-reservation-config))
        (let* ((identity (d::configurazione-full-text-identity config))
               (id (leggi-u64 identity 0)) (next (leggi-u64 identity 8)))
          (unless (or (> id prior) (and (= id prior) (> next generation)))
            (error 'invalid-argument :reason :fulltext-reservation-order))
          (if (= id prior) (incf generations) (progn (incf indices) (setf generations 1)))
          (unless (and (<= indices 8) (<= generations 2))
            (error 'invalid-argument :reason :fulltext-reservation-generations))
          (setf prior id generation next)))))
  nil)

;;; REQ: REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (riserve-full-text index index index index index) riserva-full-text) costruisci-slot-riserva))
(defun costruisci-slot-riserva (pool position tokens bytes fields memory)
  "Pre: budget complessivo gia verificato. Post: run e vettori privati per ogni generazione.
Nessun input del worker viene trattenuto alla costruzione."
  (let* ((count (length (riserve-full-text-configs pool))) (runs (make-array count)))
    (dotimes (i count)
      (setf (svref runs i) (r:crea-indice-posizionale :max-tokens tokens :max-bytes bytes
                                                   :max-fields fields :max-memory memory)))
    (%riserva-full-text pool position runs (make-array count :initial-element nil)
                       (make-array count :element-type 'fixnum :initial-element 0))))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010 REQ-CON-002
(declaim (ftype (function (t t t &key (:capacity t) (:max-tokens t) (:term-bytes t)
                          (:max-memory t) (:delta-bytes t) (:staging-bytes t) (:file-bytes t)) riserve-full-text)
                crea-riserve-full-text))
(defun crea-riserve-full-text (queue configs segment &key (capacity 8) (max-tokens 4096) (term-bytes 262144)
                                              (max-memory 268435456) (delta-bytes 268435456)
                                              (staging-bytes 67108864) (file-bytes 17179869184))
  "Pre: coda canonica, configurazioni immutabili e ACTIVE nuovo vuoto con ID u32 positivo.
Post: pool privato; costo fisso prenotato una volta per file. Non adotta un catalogo o file esistente.
INVALID-ARGUMENT per forma/ordine, RESOURCE-EXHAUSTED prima delle allocazioni oltre budget."
  (unless (and (typep queue 'ex:coda-writer) (typep configs 'simple-vector) (<= 1 (length configs) 16)
               (typep segment '(integer 1 4294967295)) (typep capacity '(integer 1 1024))
               (typep max-tokens '(integer 1 4294967295)) (typep term-bytes '(integer 1 4294967295))
               (typep max-memory 'index) (typep delta-bytes 'index) (plusp delta-bytes)
               (typep staging-bytes 'index) (plusp staging-bytes)
               (typep file-bytes 'index) (plusp file-bytes))
    (error 'invalid-argument :reason :fulltext-reservation-input))
  (verifica-configurazioni-riserve configs)
  (let* ((n (length configs)) (fields 16)
         (memory (+ 4096 (* n 128) (* capacity (+ 1032 (* n (+ 4096 (* 20 max-tokens) term-bytes (* 12 fields))))))))
    (when (> memory max-memory) (error 'resource-exhausted :reason :fulltext-reservation-memory))
    (dotimes (i n)
      (when (> (d:limite-fisso-indice-full-text (svref configs i)) file-bytes)
        (error 'resource-exhausted :reason :fulltext-reservation-fixed)))
    (let* ((fixed (make-array n :element-type 'fixnum)) (slots (make-array capacity :initial-element nil))
           (pool (%riserve-full-text queue (copy-seq configs) slots
                                    (make-array capacity :element-type '(unsigned-byte 32) :initial-element 0)
                                    (make-array capacity :element-type '(unsigned-byte 32) :initial-element 0) fixed
                                    (make-array n :element-type 'fixnum :initial-element 0)
                                    (make-array n :element-type 'fixnum :initial-element file-bytes)
                                    delta-bytes staging-bytes segment)))
      (dotimes (i n) (setf (aref fixed i) (d:limite-fisso-indice-full-text (svref configs i))))
      (dotimes (i capacity) (setf (svref slots i) (costruisci-slot-riserva pool i max-tokens term-bytes fields max-memory)))
      pool)))
