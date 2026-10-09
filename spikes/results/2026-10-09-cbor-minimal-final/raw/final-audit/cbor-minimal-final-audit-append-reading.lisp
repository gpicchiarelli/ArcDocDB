(:schema-version 1 :kind :static-c4-reading :subject :archive-audit-supplement
 :reader :cbor-tools :independent-of-author t :runtime-executed nil
 :findings-before-first-use
 ((:cli-not-enforced-before-load :risk :collector-could-handle-other-command)
  (:empty-glob-guard-ineffective :risk :helper-files-made-sources-nonempty))
 :original-code "cbor-minimal-final-audit-append-before-fix.lisp"
 :original-git-blob "13f2e1fdda3f4173b4b74cdcc0378dc91d80a709"
 :fix (:two-argument-audit-cli-before-load :separate-audit-files
       :required-successful-schema1-report)
 :second-reading :no-open-findings :fix-reviewed-before-runtime t
 :limits (:static-findings-not-product-failures :original-files-preserved))
