(:schema-version 1 :kind :audit-correction :formats NIL :status :ok
 :statement-source "root: nome test nel referto C4 confrontato con log mutante5"
 :first-audit "/tmp/cbor-header-evidence-audit-first.lisp"
 :first-md5 "2ffbac7cebfee03c74325c0cd0790f90"
 :first-byte-source :reconstructed-single-substitution-matching-declared-original-md5
 :corrected-audit "/tmp/cbor-header-evidence-audit.lisp"
 :corrected-md5 "969cb35d874a6cbbdd3d1f06cb6b11af"
 :field (:mutant "simple-31" :test)
 :before "TEST-REQ-AFF-004-CBOR-EXTENDED-SIMPLE-VALUES"
 :after "TEST-REQ-AFF-004-CBOR-ALL-256-EXTENDED-SIMPLE-VALUES"
 :source "spikes/out/cbor-mutations/5/test.log"
 :limits (:audit-name-correction-only :kernel-tests-and-campaign-outcomes-unchanged
          :initial-direct-copy-rejected-because-audit-already-corrected))
