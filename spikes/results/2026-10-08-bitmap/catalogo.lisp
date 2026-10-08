(:schema-version 1 :kind :evidence-catalog :date "2026-10-08"
 :path-base "spikes/results/2026-10-08-bitmap/"
 :metadata-policy :read-from-artifact-without-inference
 :entries
 ((:kind :failed-attempt :formats nil :variant :bitmap-readable-disassembly
   :artifact "check-disassembly-failed.lisp")
  (:kind :check :formats nil :variant :bitmap-scalar-byte-and-word
   :artifact "check.lisp")
  (:kind :failed-attempt :formats nil :variant :bitmap-allocation-sensor-64k
   :artifact "benchmark-sensor-failed.lisp")
  (:kind :benchmark :formats nil :variant :bitmap-scalar-byte-and-word
   :artifact "benchmark.lisp")
  (:kind :derived-comparison :formats nil :variant :bitmap-scalar-byte-and-word
   :artifact "comparison.lisp")
  (:kind :command-verification :formats nil :variant :simd-local-availability
   :artifact "simd-availability.lisp")
  (:kind :command-verification :formats nil :variant :simd-local-popcount-inventory
   :artifact "simd-popcount-inventory.lisp")
  (:kind :failed-attempt :formats (1 2) :variant :bitmap-full-check-source-changed
   :artifact "full-check-source-changed.lisp")
  (:kind :command-verification :formats (1 2) :variant :bitmap-full-check
   :artifact "full-check.lisp"))
 :limits (:local-small-array :no-engine-qualification :no-production-promotion))
