SBCL ?= sbcl
EVIDENCE_DYNAMIC_SPACE_SIZE ?= 2048

.PHONY: build test lint lint-selftest links trace trace-write evidence evidence-selftest compact-evidence check check-core spikes-check spikes-bench
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

evidence:  ## verifica struttura e presenza degli artefatti conservati nel catalogo
	$(SBCL) --dynamic-space-size $(EVIDENCE_DYNAMIC_SPACE_SIZE) --noinform --no-userinit --no-sysinit --script tools/check-evidence.lisp

evidence-selftest:  ## controlli negativi e positivi della conservazione compressa
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/check-evidence-storage.lisp
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/check-evidence-publication.lisp
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/check-evidence-normalize.lisp

compact-evidence:  ## comprime senza perdita i registri pubblicati grandi, con quattro worker
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- $(SBCL) --noinform --no-userinit --no-sysinit --script tools/compact-evidence.lisp --root spikes/results/ --jobs 4

spikes-check:  ## correttezza degli esperimenti Fase 0, processi isolati, senza benchmark
	$(SBCL) --noinform --no-userinit --script tools/run-spikes.lisp --check

spikes-bench:  ## misure locali, in serie; dati grezzi e ambiente in spikes/out/
	$(SBCL) --noinform --no-userinit --script tools/run-spikes.lisp --bench

check:  ## tutti i controlli, con record strutturato anche in caso di fallimento
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- $(MAKE) check-core

check-core: test lint lint-selftest trace links evidence-selftest evidence spikes-check  ## controlli chiamati dal registro
