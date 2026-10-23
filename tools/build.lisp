;;;; build.lisp — compila il sistema e ne esegue i test; ogni avviso è un errore.
;;;;
;;;; Uso:  sbcl --noinform --no-userinit --non-interactive --load tools/build.lisp
;;;;
;;;; Regola COD-01 (docs/affidabilita/standard-di-codifica.md): compilazione senza
;;;; WARNING né STYLE-WARNING. Il caricamento forza la ricompilazione, così un avviso non
;;;; può essere nascosto da una compilazione precedente.
;;;;
;;;; REQ: REQ-AFF-003

(require :asdf)

(setf asdf:*compile-file-failure-behaviour* :error
      asdf:*compile-file-warnings-behaviour* :error)

(defun treat-as-error (condition)
  "Trasforma un avviso di compilazione in errore, indicando il testo dell'avviso.
Esclusi solo gli avvisi di ridefinizione, prodotti da ASDF quando rilegge il file .asd:
non dipendono dal codice di prodotto."
  (unless (typep condition 'sb-kernel:redefinition-warning)
    (error "~A non ammesso (COD-01): ~A" (type-of condition) condition)))

(handler-bind ((warning #'treat-as-error)
               (style-warning #'treat-as-error))
  (asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
  (asdf:load-system "arcdocdb" :force t)
  (asdf:test-system "arcdocdb"))

(format t "~&build e test: nessun avviso, tutti i controlli superati~%")
