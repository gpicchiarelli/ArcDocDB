SBCL ?= sbcl

.PHONY: build test lint lint-selftest links trace trace-write check
build test:  ## compila senza avvisi (COD-01) ed esegue gli smoke test
	$(SBCL) --noinform --no-userinit --non-interactive --load tools/build.lisp

lint:  ## divieti dello standard di codifica sul codice di prodotto (src/)
	$(SBCL) --script tools/lint.lisp src

lint-selftest:  ## verifica il linter su codice di prova corretto e scorretto
	$(SBCL) --script tools/lint.lisp --self-test

links:  ## verifica link e ancore relativi nei file Markdown
	$(SBCL) --script tools/check-links.lisp .

trace:  ## verifica la tracciabilità: requisiti, invarianti, FI, ADR, riferimenti nel codice
	$(SBCL) --script tools/check-trace.lisp

trace-write:  ## rigenera docs/tracciabilita/matrice.md da requisiti.lisp
	$(SBCL) --script tools/check-trace.lisp --write

check: test lint lint-selftest trace links  ## tutti i controlli
