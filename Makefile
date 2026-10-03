SBCL ?= sbcl

.PHONY: test links check
test:   ## carica il sistema ed esegue gli smoke test
	$(SBCL) --noinform --no-userinit --non-interactive --eval '(require :asdf)' --load arcdocdb.asd --eval '(asdf:test-system "arcdocdb")'

links:  ## verifica link e ancore relativi nei file Markdown
	$(SBCL) --no-userinit --script tools/check-links.lisp .

check: test links
