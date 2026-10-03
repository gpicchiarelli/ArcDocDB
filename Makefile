SBCL ?= sbcl

.PHONY: test links check
test:   ## carica il sistema ed esegue gli smoke test
	$(SBCL) --noinform --non-interactive --load arcdocdb.asd --eval '(asdf:test-system "arcdocdb")'

links:  ## verifica link e ancore relativi nei file Markdown
	$(SBCL) --script tools/check-links.lisp .

check: test links
