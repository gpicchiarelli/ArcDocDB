;;;; SPK-01, Fase 0: lettura in buffer del layout v1, parole 4/5-extra-end.
;;;; Proprietà e metodo preregistrato: metodo-lettura-buffer.md.
;;; REQ: REQ-IDX-001 REQ-IDX-007 REQ-VAL-001
(defpackage #:arcdocdb.spk01.lettura-buffer
  (:use #:cl)
  (:import-from #:arcdocdb.spk01
                #:indice #:indice-root #:ottetti #:parole #:u64
                #:radice #:radice-generazione #:frammento
                #:frammento-capacita #:frammento-larghezza #:frammento-slots
                #:frammento-ctrl #:frammento-chiavi
                #:hash-chiave #:scegli-frammento #:posizione-sonda #:impronta
                #:stessa-chiave-p #:limite-indice
                #:+gruppo+ #:+vuoto+)
  (:export #:leggi))
(in-package #:arcdocdb.spk01.lettura-buffer)
(declaim (optimize (safety 3) (speed 3) (debug 1)))

(deftype destinazione-lettura () '(simple-array (unsigned-byte 64) (4)))

(declaim
 (ftype (function (indice ottetti destinazione-lettura
                   &key (:attempts integer)
                        (:after-fragment (or null function))
                        (:after-fields (or null function)))
                  (values keyword fixnum &optional))
        leggi))
(defun leggi (indice chiave destinazione
              &key (attempts 8) after-fragment after-fields)
  "Restituisce :HIT/:MISS/:RETRY-LIMIT e tentativi scartati (0..8).
Solo :HIT scrive [CSN, location, length, end-CSN] dopo seqlock e root.
CHIAVE e DESTINAZIONE restano private al chiamante durante la lettura."
  (declare (type indice indice) (type ottetti chiave)
           (type destinazione-lettura destinazione) (type integer attempts)
           (type (or null function) after-fragment after-fields))
  ;; Tutti gli ingressi sono controllati prima dell'hash e degli accessi indice.
  (check-type indice indice)
  (check-type chiave ottetti)
  (check-type destinazione destinazione-lettura)
  (check-type after-fragment (or null function))
  (check-type after-fields (or null function))
  ;; Tipo letterale: lo stesso rifiuto, senza costruire una lista a ogni GET.
  (unless (typep attempts '(integer 1 8))
    (error 'type-error :datum attempts :expected-type '(integer 1 8)))
  (unless (= 16 (length chiave))
    (error 'limite-indice :motivo :chiave-16-byte))
  (let ((limite (the (integer 1 8) attempts)))
    ;; Un solo algoritmo espanso due volte: nessuna chiamata u64 tra helper.
    ;; Il percorso diretto non contiene FUNCALL né ritorni di payload Lisp.
    (macrolet
        ((lettura (strumentata)
           `(let ((hash (hash-chiave chiave 0)))
              (declare (type u64 hash))
              (dotimes (tentativo limite (values :retry-limit limite))
                (declare (type (integer 0 8) tentativo))
                (let* ((root (indice-root indice))
                       (generazione (radice-generazione root)))
                  (declare (type radice root) (type fixnum generazione))
                  (sb-thread:barrier (:read))
                  (let* ((frammento (scegli-frammento root hash))
                         (csn 0) (posizione 0) (lunghezza 0) (fine 0)
                         (stato :miss))
                    (declare (type frammento frammento)
                             (type u64 csn posizione fine)
                             (type (unsigned-byte 24) lunghezza)
                             (type keyword stato))
                    ,@(when strumentata
                        '((when after-fragment
                            (funcall after-fragment frammento))))
                    (let ((capacita (frammento-capacita frammento)))
                      (declare (type fixnum capacita))
                      (block sondaggio
                        (dotimes (gruppo (ceiling capacita +gruppo+))
                          (declare (type fixnum gruppo))
                          (dotimes (n +gruppo+)
                            (declare (type fixnum n))
                            (let* ((slot (posizione-sonda
                                          hash capacita
                                          (+ (* gruppo +gruppo+) n)))
                                   (controllo (aref (frammento-ctrl frammento)
                                                   slot)))
                              (declare (type fixnum slot)
                                       (type (unsigned-byte 8) controllo))
                              (when (= controllo +vuoto+)
                                (return-from sondaggio nil))
                              (when (= controllo (impronta hash))
                                (let* ((parole (frammento-slots frammento))
                                       (base (* slot
                                                (frammento-larghezza frammento)))
                                       (sequenza (aref parole (+ base 3))))
                                  (declare (type parole parole)
                                           (type fixnum base) (type u64 sequenza))
                                  (when (oddp sequenza)
                                    (setf stato :retry)
                                    (return-from sondaggio nil))
                                  (sb-thread:barrier (:read))
                                  (let* ((csn-letto (aref parole base))
                                         (posizione-letta (aref parole (+ base 1)))
                                         (metadati (aref parole (+ base 2)))
                                         (fine-letta
                                           (if (= 5 (frammento-larghezza frammento))
                                               (aref parole (+ base 4)) 0))
                                         (controllo-letto
                                           (aref (frammento-ctrl frammento) slot))
                                         (arena (frammento-chiavi frammento))
                                         (offset (ldb (byte 24 0) metadati))
                                         (corrisponde
                                           (and (= controllo-letto (impronta hash))
                                                (= 1 (ldb (byte 8 56) metadati))
                                                (= 16 (ldb (byte 8 24) metadati))
                                                (<= (+ offset 16) (length arena))
                                                (stessa-chiave-p chiave arena offset))))
                                    (declare (type u64 csn-letto posizione-letta
                                                   metadati fine-letta)
                                             (type (unsigned-byte 8) controllo-letto)
                                             (type ottetti arena) (type fixnum offset)
                                             (type boolean corrisponde))
                                    ,@(when strumentata
                                        '((when after-fields
                                            (funcall after-fields frammento slot))))
                                    (sb-thread:barrier (:read))
                                    (when (/= sequenza (aref parole (+ base 3)))
                                      (setf stato :retry)
                                      (return-from sondaggio nil))
                                    (when corrisponde
                                      (setf csn csn-letto posizione posizione-letta
                                            lunghezza (ldb (byte 24 32) metadati)
                                            fine fine-letta stato :hit)
                                      (return-from sondaggio nil))))))))))
                    ;; Anche un miss deve appartenere alla root ancora corrente.
                    (sb-thread:barrier (:read))
                    (let ((corrente (indice-root indice)))
                      (declare (type radice corrente))
                      (when (and (not (eq stato :retry)) (eq corrente root)
                                 (= generazione (radice-generazione corrente)))
                        ;; Nessun callback o accesso condiviso dopo la validazione.
                        (when (eq stato :hit)
                          (setf (aref destinazione 0) csn
                                (aref destinazione 1) posizione
                                (aref destinazione 2) lunghezza
                                (aref destinazione 3) fine))
                        (return-from leggi (values stato tentativo))))))))))
      (if (or after-fragment after-fields)
          (lettura t)
          (lettura nil)))))
