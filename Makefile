SBCL ?= sbcl
EVIDENCE_DYNAMIC_SPACE_SIZE ?= 2048
EVIDENCE_JOBS ?= 4
EVIDENCE_WORKER_SECONDS ?= 300

.PHONY: build test lint lint-selftest links trace trace-write evidence evidence-selftest compact-evidence check check-core spikes-check spikes-bench snapshot-mutation-selftest reader-mutation-selftest fulltext-check ci-status ci-selftest ci-audit
build test:  ## compila senza avvisi (COD-01) ed esegue gli smoke test
	$(SBCL) --noinform --no-userinit --non-interactive --load tools/build.lisp

lint:  ## divieti dello standard di codifica sul codice di prodotto (src/)
	$(SBCL) --script tools/lint.lisp src

lint-selftest:  ## verifica il linter su codice di prova corretto e scorretto
	$(SBCL) --script tools/lint.lisp --self-test

snapshot-mutation-selftest:  ## verifica classificazione e diagnostiche del runner snapshot
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/snapshot-mutation.lisp --self-test

reader-mutation-selftest:  ## verifica classificazione e diagnostiche del runner EBR/lettura
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/reader-mutation.lisp --self-test

links:  ## verifica link e ancore relativi nei file Markdown
	$(SBCL) --script tools/check-links.lisp .

trace:  ## verifica la tracciabilità: requisiti, invarianti, FI, ADR, riferimenti nel codice
	$(SBCL) --script tools/check-trace.lisp

trace-write:  ## rigenera docs/tracciabilita/matrice.md da requisiti.lisp
	$(SBCL) --script tools/check-trace.lisp --write

evidence:  ## verifica struttura e presenza degli artefatti conservati nel catalogo
	$(SBCL) --dynamic-space-size $(EVIDENCE_DYNAMIC_SPACE_SIZE) --noinform --no-userinit --no-sysinit --script tools/check-evidence.lisp --jobs $(EVIDENCE_JOBS) --worker-seconds $(EVIDENCE_WORKER_SECONDS) --worker-heap-mib $(EVIDENCE_DYNAMIC_SPACE_SIZE)

evidence-selftest:  ## controlli negativi e positivi della conservazione e della raccolta
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/check-evidence.lisp --self-test
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/check-evidence-storage.lisp
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/check-evidence-publication.lisp
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/check-evidence-normalize.lisp
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/collect-command-archive.lisp --self-test

compact-evidence:  ## comprime senza perdita i registri pubblicati grandi, con quattro worker
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- $(SBCL) --noinform --no-userinit --no-sysinit --script tools/compact-evidence.lisp --root spikes/results/ --jobs 4

spikes-check:  ## correttezza degli esperimenti Fase 0, processi isolati, senza benchmark
	$(SBCL) --noinform --no-userinit --script tools/run-spikes.lisp --check

spikes-bench:  ## misure locali, in serie; dati grezzi e ambiente in spikes/out/
	$(SBCL) --noinform --no-userinit --script tools/run-spikes.lisp --bench

check:  ## tutti i controlli, con record strutturato anche in caso di fallimento
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- $(MAKE) check-core

fulltext-check:  ## tabelle Unicode riproducibili, strumenti e sensibilita degli oracoli
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/fulltext-codec-fixture.lisp --self-test
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/fulltext-codec-fixture.lisp --check tests/fulltext/minimum-v2.hex
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/fulltext-unicode-tables.lisp --self-test
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/fulltext-unicode-tables.lisp --check data/unicode/18.0.0/ src/fulltext/unicode-tables.lisp
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/fulltext-qualification.lisp --self-test
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/fulltext-qualification.lisp --check
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/fulltext-persistence.lisp --self-test

ci-status:  ## dati riferiti esattamente ai sorgenti attuali
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/ci.lisp status

ci-selftest:  ## confini wire, catalogo, metriche, workflow e archivi CI
	$(SBCL) --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- $(SBCL) --noinform --no-userinit --no-sysinit --script tools/ci.lisp self-test --out spikes/out/ci/selftest-$(shell date +%s)-$(shell echo $$$$)

ci-audit: lint-selftest snapshot-mutation-selftest reader-mutation-selftest fulltext-check evidence-selftest evidence spikes-check ci-selftest

check-core: test lint lint-selftest snapshot-mutation-selftest reader-mutation-selftest trace links fulltext-check evidence-selftest evidence spikes-check ci-selftest  ## controlli chiamati dal registro
