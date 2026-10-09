(:schema-version 1 :kind :local-static-reading :date "2026-10-09"
 :reading :directory-lifecycle-memory :independent-review nil :qualification nil
 :source-paths ("src/index/primary-types.lisp" "src/index/primary-build.lisp"
                "src/index/primary-arena.lisp" "src/index/primary-directory.lisp")
 :observations
 ((:id :geometry :finding "Root costruita inizialmente con G=0; sostituzione di un blocco canonico con stesso prefisso o due figli.")
  (:id :plan :finding "Identità root e revisione invalidate da tutte le mutazioni, inclusi candidati; piani monouso.")
  (:id :freeze :finding "Sorgente congelato prima del CAS; nuovi reader ricontrollano root anche su miss; nessun reopen.")
  (:id :wrap :finding "Revisione/generazione sotto 2^60, seqlock sotto 2^62; credito verificato prima dei cambi.")
  (:id :budget :finding "41*C+arena, directory O(2^G), payload transitorio esplicito; overflow contabilità rifiutato.")
  (:id :copy-limit :finding "Conteggio vivo dei candidati non dimostra copia esatta; costruttore/verifica e prenotazione prima dei candidati ancora esterni.")
  (:id :arm64 :finding "Disassemblato: load/store NL dei payload, DMB ISHLD/ISHST, CASAL sulla root; sola ispezione statica."))
 :open (:independent-review :copy-builder :arm64-stress :x86-64-disassembly :memory-controller
        :gc-retention :split-duration :p99 :c1-qualification))
