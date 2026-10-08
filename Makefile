SBCL ?= sbcl

.PHONY: build test lint lint-selftest links trace trace-write check spikes-check spikes-bench
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

spikes-check:  ## correttezza degli esperimenti Fase 0, processi isolati, senza benchmark
	$(SBCL) --noinform --no-userinit --script tools/run-spikes.lisp --check

spikes-bench:  ## misure locali, in serie; dati grezzi e ambiente in spikes/out/
	$(SBCL) --noinform --no-userinit --script tools/run-spikes.lisp --bench

check: test lint lint-selftest trace links spikes-check  ## tutti i controlli
