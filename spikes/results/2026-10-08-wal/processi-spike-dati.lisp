(:SCHEMA-VERSION 1 :KIND :SPIKE-PROCESS-INDEX :CAMPAIGNS
 ((:COMMAND-RECORD
   "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485098-command-8643-0/report.lisp"
   :PARENT-WITH-RUN-REFERENCES
   (:SCHEMA-VERSION 1 :ENVIRONMENT
    (:LISP #A((4) BASE-CHAR . "SBCL") :VERSION #A((5) BASE-CHAR . "2.6.9") :OS
     #A((6) BASE-CHAR . "Darwin") :OS-VERSION #A((6) BASE-CHAR . "27.0.0")
     :MACHINE #A((5) BASE-CHAR . "ARM64") :CPU "Apple M4" :MEMORY-BYTES
     17179869184 :LOGICAL-CPUS 10 :EXTERNAL-LOAD-STATUS :UNCONTROLLED
     :LOAD-AVERAGE "{ 3.65 4.41 4.32 }" :COMMIT
     "74f09497b95c1a7e698e43c5112a65e7e29129b0" :WORKING-TREE "M arcdocdb.asd
 M docs/implementazione/README.md
 M docs/tracciabilita/README.md
 M src/foundation/conditions.lisp
 M src/foundation/package.lisp
 M tools/check-trace.lisp
 M tools/foundation-coverage.lisp
 M tools/foundation-mutation.lisp
?? docs/implementazione/io-decisioni.md
?? docs/implementazione/io-metodo.md
?? docs/implementazione/io.md
?? docs/implementazione/wal-decisioni.md
?? docs/implementazione/wal-metodo.md
?? docs/implementazione/wal.md
?? spikes/results/2026-10-08-io/
?? spikes/results/2026-10-08-wal/
?? src/io/
?? src/wal/
?? tests/io/
?? tests/wal/
?? tools/io-bench.lisp
?? tools/wal-bench.lisp"
     :SOURCE-BLOBS
     ((:PATH "spikes/SPK-01-primary-index/profile.lisp" :GIT-BLOB
       "a71fde100e32072b6e7b010228683b640ea4ff9a")
      (:PATH "spikes/SPK-01-primary-index/run.lisp" :GIT-BLOB
       "9b32673c5bda223ba7783ec082af0890078d1e25")
      (:PATH #A((37) BASE-CHAR . "spikes/SPK-01-primary-index/core.lisp")
       :GIT-BLOB "c019f6ad53e173a0d336a4dbfaf903e274a66f08")
      (:PATH "spikes/SPK-02-gc/run.lisp" :GIT-BLOB
       "9fbe499100da40c2f7a14072af67c35c734949c5")
      (:PATH #A((26) BASE-CHAR . "spikes/SPK-02-gc/core.lisp") :GIT-BLOB
       "01f6760c75fa6e96a480fca41b1426941a9f703d")
      (:PATH "spikes/SPK-03-group-commit/run.lisp" :GIT-BLOB
       "c0b093e87028dd587c43d3cd52e59492270fdc38")
      (:PATH #A((36) BASE-CHAR . "spikes/SPK-03-group-commit/core.lisp")
       :GIT-BLOB "d3c58f2866e299ba27b0fa820c20317438774410")
      (:PATH "spikes/SPK-04-writer-pool/run.lisp" :GIT-BLOB
       "77056cc1f695574ed0f4d34795b99aaea736f378")
      (:PATH #A((35) BASE-CHAR . "spikes/SPK-04-writer-pool/core.lisp")
       :GIT-BLOB "557b32e6378290c46c7d9b128fc8e59a0e7e0a44")
      (:PATH "spikes/SPK-04-writer-pool/pool.lisp" :GIT-BLOB
       "cbec51aad2b64fb8c5be026891eff859ba371c18")
      (:PATH "spikes/SPK-04-writer-pool/parcheggi.lisp" :GIT-BLOB
       "c0fee7b738395fcaf3359f297282cd266ce6dfad")
      (:PATH "spikes/SPK-05-segment-read/run.lisp" :GIT-BLOB
       "c67a3ae8e672f96d9105deb935fb621b07d67afb")
      (:PATH #A((36) BASE-CHAR . "spikes/SPK-05-segment-read/core.lisp")
       :GIT-BLOB "2c0c5a6b5c75a56a4db72fa88ff867cdb3db8508")
      (:PATH "spikes/SPK-06-compaction-load/run.lisp" :GIT-BLOB
       "b2863cbac49d0988b850bdeeae1713108a21bfca")
      (:PATH #A((39) BASE-CHAR . "spikes/SPK-06-compaction-load/core.lisp")
       :GIT-BLOB "375cb97e1490e0252c04fd1a3076a17342cefd68")
      (:PATH "spikes/SPK-06-compaction-load/controllore.lisp" :GIT-BLOB
       "4602972e2400d31d4d3b771f60703c68e23f0804")
      (:PATH "spikes/SPK-06-compaction-load/interferenza.lisp" :GIT-BLOB
       "6fe454e8018bcf21b40726f928bf4380b5d06a9d")
      (:PATH "spikes/SPK-05-segment-read/io.lisp" :GIT-BLOB
       "ba470bce3cae0ce14888dbec6e26c5656e9bbd1a")
      (:PATH "spikes/SPK-05-segment-read/record.lisp" :GIT-BLOB
       "baea7833c8e6f9a49b5ea2f8ee15f76fe35f93fe")
      (:PATH "spikes/SPK-07-protocols/run.lisp" :GIT-BLOB
       "648bd776767e4be914a2470069afced14bc1c1e5")
      (:PATH #A((33) BASE-CHAR . "spikes/SPK-07-protocols/core.lisp") :GIT-BLOB
       "489e2732cf5bfed4cd11251bb686a5d4f4e10b3e")
      (:PATH "spikes/SPK-07-protocols/pubblicazione.lisp" :GIT-BLOB
       "d317849b3f95394a7f604b82fb131495b5b3770c")
      (:PATH "spikes/SPK-07-protocols/scadenza.lisp" :GIT-BLOB
       "05a5e93591e2d6e96c2c7548e90888424cbb1f9f")
      (:PATH "spikes/SPK-07-protocols/compaction.lisp" :GIT-BLOB
       "93483f72f3bfe43f0e2afa93b022892114a824e1")
      (:PATH "spikes/SPK-07-protocols/memoria.lisp" :GIT-BLOB
       "96b6cf64d481643cdba7857f339a7cb7c029b765")
      (:PATH "spikes/SPK-07-protocols/suite.lisp" :GIT-BLOB
       "a813fbeb55cd03980b2215c99fc3170d6afa4d92")
      (:PATH "spikes/SPK-07-protocols/seqlock-readers.lisp" :GIT-BLOB
       "b2e704bbe7e699b9df68173319f64d2ae8abc5fc")
      (:PATH "spikes/SPK-07-protocols/byte-crash.lisp" :GIT-BLOB
       "66a6c3b458d808fc214f7c3bd96e09d239312c67")
      (:PATH "src/package.lisp" :GIT-BLOB
       "3d0181717e3f334580bab9a6a507e2dfe57261ff")
      (:PATH "src/foundation/package.lisp" :GIT-BLOB
       "0658b083f1e777aa0ada67a63535d36946921eac")
      (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
       "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
      (:PATH "src/foundation/binary.lisp" :GIT-BLOB
       "2d514f6fe2e81eecb29fa53de611fa5e28696904")
      (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
       "f9c691d28620427099d1d89a89a1ff5d04cbe257")
      (:PATH "src/foundation/record.lisp" :GIT-BLOB
       "8df53d416747131d9ed9921abb4ef356d9ce5696")
      (:PATH "src/foundation/batch.lisp" :GIT-BLOB
       "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
      (:PATH "spikes/SPK-08-generated-code/run.lisp" :GIT-BLOB
       "67afeb7724a23d5f6088818fd41aa3b8e9899002")
      (:PATH "spikes/SPK-08-generated-code/impronte.lisp" :GIT-BLOB
       "d187e3d95f0e85a0a8ae84843a67a326e803cd2c")
      (:PATH "spikes/SPK-08-generated-code/simd.lisp" :GIT-BLOB
       "dbd551322880f1e0ddac6436c8af8f0dd85ddb9f")
      (:PATH "spikes/SPK-09-integrity/run.lisp" :GIT-BLOB
       "c95660a4df5f2e6f6eb93e1078c2c36df6dabc85")
      (:PATH "tools/run-spikes.lisp" :GIT-BLOB
       "04e126b75eb8d4a9c6dd97e4ddedef18e43e9175")
      (:PATH "spikes/SPK-10-v2-limits/run.lisp" :GIT-BLOB
       "6aa63afeac91c3b75174b76daba61e354bb7fe4d")
      (:PATH #A((33) BASE-CHAR . "spikes/SPK-10-v2-limits/core.lisp") :GIT-BLOB
       "c5b7cfd27c663734b7d5fae481dde939418566b5")
      (:PATH "spikes/SPK-10-v2-limits/codec.lisp" :GIT-BLOB
       "567c84546d29e1b8ddc5cd9e1a31b4e93519c75d")
      (:PATH "spikes/SPK-10-v2-limits/indice.lisp" :GIT-BLOB
       "bc978eb16aa7f0d69e3deac2df86057a650f8551")
      (:PATH "spikes/SPK-10-v2-limits/cbor.lisp" :GIT-BLOB
       "d6a5c93e34a0444d64b206df875a25b380545631")
      (:PATH "spikes/SPK-10-v2-limits/migrazione.lisp" :GIT-BLOB
       "cab850dc32ff9908b487b24edf3e1df2cc90008c")
      (:PATH "spikes/SPK-09-integrity/core.lisp" :GIT-BLOB
       "80cdac4c0e52703618e1f274413b2ecbe00e6b14"))
     :DYNAMIC-SPACE-MIB 4096 :DATE-UNIVERSAL-TIME 4000485108)
    :MODE #A((7) BASE-CHAR . "--check") :STATUS :COMPLETE :RUNS
    ((:ARTIFACT #A((28) BASE-CHAR . "processo-isolata-SPK-01.lisp"))
     (:ARTIFACT #A((28) BASE-CHAR . "processo-isolata-SPK-02.lisp"))
     (:ARTIFACT #A((28) BASE-CHAR . "processo-isolata-SPK-03.lisp"))
     (:ARTIFACT #A((28) BASE-CHAR . "processo-isolata-SPK-04.lisp"))
     (:ARTIFACT #A((28) BASE-CHAR . "processo-isolata-SPK-05.lisp"))
     (:ARTIFACT #A((28) BASE-CHAR . "processo-isolata-SPK-06.lisp"))
     (:ARTIFACT #A((28) BASE-CHAR . "processo-isolata-SPK-07.lisp"))
     (:ARTIFACT #A((28) BASE-CHAR . "processo-isolata-SPK-08.lisp"))
     (:ARTIFACT #A((28) BASE-CHAR . "processo-isolata-SPK-09.lisp"))
     (:ARTIFACT #A((28) BASE-CHAR . "processo-isolata-SPK-10.lisp")))
    :RUN-ARTIFACTS
    (#A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485104-check-8694-0/SPK-01.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485104-check-8694-0/SPK-02.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485104-check-8694-0/SPK-03.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485104-check-8694-0/SPK-04.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485104-check-8694-0/SPK-05.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485104-check-8694-0/SPK-06.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485104-check-8694-0/SPK-07.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485104-check-8694-0/SPK-08.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485104-check-8694-0/SPK-09.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485104-check-8694-0/SPK-10.lisp"))))
  (:COMMAND-RECORD
   "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485238-command-9649-0/report.lisp"
   :PARENT-WITH-RUN-REFERENCES
   (:SCHEMA-VERSION 1 :ENVIRONMENT
    (:LISP #A((4) BASE-CHAR . "SBCL") :VERSION #A((5) BASE-CHAR . "2.6.9") :OS
     #A((6) BASE-CHAR . "Darwin") :OS-VERSION #A((6) BASE-CHAR . "27.0.0")
     :MACHINE #A((5) BASE-CHAR . "ARM64") :CPU "Apple M4" :MEMORY-BYTES
     17179869184 :LOGICAL-CPUS 10 :EXTERNAL-LOAD-STATUS :UNCONTROLLED
     :LOAD-AVERAGE "{ 2.54 3.67 4.03 }" :COMMIT
     "4003de02d6047c3aad6e6e102a250cd87427f18c" :WORKING-TREE "" :SOURCE-BLOBS
     ((:PATH "spikes/SPK-01-primary-index/profile.lisp" :GIT-BLOB
       "a71fde100e32072b6e7b010228683b640ea4ff9a")
      (:PATH "spikes/SPK-01-primary-index/run.lisp" :GIT-BLOB
       "9b32673c5bda223ba7783ec082af0890078d1e25")
      (:PATH #A((37) BASE-CHAR . "spikes/SPK-01-primary-index/core.lisp")
       :GIT-BLOB "c019f6ad53e173a0d336a4dbfaf903e274a66f08")
      (:PATH "spikes/SPK-02-gc/run.lisp" :GIT-BLOB
       "9fbe499100da40c2f7a14072af67c35c734949c5")
      (:PATH #A((26) BASE-CHAR . "spikes/SPK-02-gc/core.lisp") :GIT-BLOB
       "01f6760c75fa6e96a480fca41b1426941a9f703d")
      (:PATH "spikes/SPK-03-group-commit/run.lisp" :GIT-BLOB
       "c0b093e87028dd587c43d3cd52e59492270fdc38")
      (:PATH #A((36) BASE-CHAR . "spikes/SPK-03-group-commit/core.lisp")
       :GIT-BLOB "d3c58f2866e299ba27b0fa820c20317438774410")
      (:PATH "spikes/SPK-04-writer-pool/run.lisp" :GIT-BLOB
       "77056cc1f695574ed0f4d34795b99aaea736f378")
      (:PATH #A((35) BASE-CHAR . "spikes/SPK-04-writer-pool/core.lisp")
       :GIT-BLOB "557b32e6378290c46c7d9b128fc8e59a0e7e0a44")
      (:PATH "spikes/SPK-04-writer-pool/pool.lisp" :GIT-BLOB
       "cbec51aad2b64fb8c5be026891eff859ba371c18")
      (:PATH "spikes/SPK-04-writer-pool/parcheggi.lisp" :GIT-BLOB
       "c0fee7b738395fcaf3359f297282cd266ce6dfad")
      (:PATH "spikes/SPK-05-segment-read/run.lisp" :GIT-BLOB
       "c67a3ae8e672f96d9105deb935fb621b07d67afb")
      (:PATH #A((36) BASE-CHAR . "spikes/SPK-05-segment-read/core.lisp")
       :GIT-BLOB "2c0c5a6b5c75a56a4db72fa88ff867cdb3db8508")
      (:PATH "spikes/SPK-06-compaction-load/run.lisp" :GIT-BLOB
       "b2863cbac49d0988b850bdeeae1713108a21bfca")
      (:PATH #A((39) BASE-CHAR . "spikes/SPK-06-compaction-load/core.lisp")
       :GIT-BLOB "375cb97e1490e0252c04fd1a3076a17342cefd68")
      (:PATH "spikes/SPK-06-compaction-load/controllore.lisp" :GIT-BLOB
       "4602972e2400d31d4d3b771f60703c68e23f0804")
      (:PATH "spikes/SPK-06-compaction-load/interferenza.lisp" :GIT-BLOB
       "6fe454e8018bcf21b40726f928bf4380b5d06a9d")
      (:PATH "spikes/SPK-05-segment-read/io.lisp" :GIT-BLOB
       "ba470bce3cae0ce14888dbec6e26c5656e9bbd1a")
      (:PATH "spikes/SPK-05-segment-read/record.lisp" :GIT-BLOB
       "baea7833c8e6f9a49b5ea2f8ee15f76fe35f93fe")
      (:PATH "spikes/SPK-07-protocols/run.lisp" :GIT-BLOB
       "648bd776767e4be914a2470069afced14bc1c1e5")
      (:PATH #A((33) BASE-CHAR . "spikes/SPK-07-protocols/core.lisp") :GIT-BLOB
       "489e2732cf5bfed4cd11251bb686a5d4f4e10b3e")
      (:PATH "spikes/SPK-07-protocols/pubblicazione.lisp" :GIT-BLOB
       "d317849b3f95394a7f604b82fb131495b5b3770c")
      (:PATH "spikes/SPK-07-protocols/scadenza.lisp" :GIT-BLOB
       "05a5e93591e2d6e96c2c7548e90888424cbb1f9f")
      (:PATH "spikes/SPK-07-protocols/compaction.lisp" :GIT-BLOB
       "93483f72f3bfe43f0e2afa93b022892114a824e1")
      (:PATH "spikes/SPK-07-protocols/memoria.lisp" :GIT-BLOB
       "96b6cf64d481643cdba7857f339a7cb7c029b765")
      (:PATH "spikes/SPK-07-protocols/suite.lisp" :GIT-BLOB
       "a813fbeb55cd03980b2215c99fc3170d6afa4d92")
      (:PATH "spikes/SPK-07-protocols/seqlock-readers.lisp" :GIT-BLOB
       "b2e704bbe7e699b9df68173319f64d2ae8abc5fc")
      (:PATH "spikes/SPK-07-protocols/byte-crash.lisp" :GIT-BLOB
       "66a6c3b458d808fc214f7c3bd96e09d239312c67")
      (:PATH "src/package.lisp" :GIT-BLOB
       "3d0181717e3f334580bab9a6a507e2dfe57261ff")
      (:PATH "src/foundation/package.lisp" :GIT-BLOB
       "0658b083f1e777aa0ada67a63535d36946921eac")
      (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
       "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
      (:PATH "src/foundation/binary.lisp" :GIT-BLOB
       "2d514f6fe2e81eecb29fa53de611fa5e28696904")
      (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
       "f9c691d28620427099d1d89a89a1ff5d04cbe257")
      (:PATH "src/foundation/record.lisp" :GIT-BLOB
       "8df53d416747131d9ed9921abb4ef356d9ce5696")
      (:PATH "src/foundation/batch.lisp" :GIT-BLOB
       "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
      (:PATH "spikes/SPK-08-generated-code/run.lisp" :GIT-BLOB
       "a1fdf6705a10fcca3926f40e26051fe7b6df5bf0")
      (:PATH "spikes/SPK-08-generated-code/impronte.lisp" :GIT-BLOB
       "d187e3d95f0e85a0a8ae84843a67a326e803cd2c")
      (:PATH "spikes/SPK-08-generated-code/simd.lisp" :GIT-BLOB
       "dbd551322880f1e0ddac6436c8af8f0dd85ddb9f")
      (:PATH "spikes/SPK-08-generated-code/bitmap.lisp" :GIT-BLOB
       "cbeff7e2a58f268291b01cb6a1f124533063d5d6")
      (:PATH "spikes/SPK-08-generated-code/core-bitmap.lisp" :GIT-BLOB
       "a4be2005a702a77a631f35568778673c503c60b5")
      (:PATH "spikes/SPK-09-integrity/run.lisp" :GIT-BLOB
       "c95660a4df5f2e6f6eb93e1078c2c36df6dabc85")
      (:PATH "tools/run-spikes.lisp" :GIT-BLOB
       "3bef8bc2b224e7139a97ce5eed68c475c38cdd43")
      (:PATH "spikes/SPK-10-v2-limits/run.lisp" :GIT-BLOB
       "6aa63afeac91c3b75174b76daba61e354bb7fe4d")
      (:PATH #A((33) BASE-CHAR . "spikes/SPK-10-v2-limits/core.lisp") :GIT-BLOB
       "c5b7cfd27c663734b7d5fae481dde939418566b5")
      (:PATH "spikes/SPK-10-v2-limits/codec.lisp" :GIT-BLOB
       "567c84546d29e1b8ddc5cd9e1a31b4e93519c75d")
      (:PATH "spikes/SPK-10-v2-limits/indice.lisp" :GIT-BLOB
       "bc978eb16aa7f0d69e3deac2df86057a650f8551")
      (:PATH "spikes/SPK-10-v2-limits/cbor.lisp" :GIT-BLOB
       "d6a5c93e34a0444d64b206df875a25b380545631")
      (:PATH "spikes/SPK-10-v2-limits/migrazione.lisp" :GIT-BLOB
       "cab850dc32ff9908b487b24edf3e1df2cc90008c")
      (:PATH "spikes/SPK-09-integrity/core.lisp" :GIT-BLOB
       "80cdac4c0e52703618e1f274413b2ecbe00e6b14"))
     :DYNAMIC-SPACE-MIB 4096 :DATE-UNIVERSAL-TIME 4000485248)
    :MODE #A((7) BASE-CHAR . "--check") :STATUS :COMPLETE :RUNS
    ((:ARTIFACT #A((27) BASE-CHAR . "processo-bitmap-SPK-01.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-bitmap-SPK-02.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-bitmap-SPK-03.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-bitmap-SPK-04.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-bitmap-SPK-05.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-bitmap-SPK-06.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-bitmap-SPK-07.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-bitmap-SPK-08.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-bitmap-SPK-09.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-bitmap-SPK-10.lisp")))
    :RUN-ARTIFACTS
    (#A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485244-check-9696-0/SPK-01.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485244-check-9696-0/SPK-02.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485244-check-9696-0/SPK-03.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485244-check-9696-0/SPK-04.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485244-check-9696-0/SPK-05.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485244-check-9696-0/SPK-06.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485244-check-9696-0/SPK-07.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485244-check-9696-0/SPK-08.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485244-check-9696-0/SPK-09.lisp")
     #A((105) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485244-check-9696-0/SPK-10.lisp"))))
  (:COMMAND-RECORD
   "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485388-command-10267-0/report.lisp"
   :PARENT-WITH-RUN-REFERENCES
   (:SCHEMA-VERSION 1 :ENVIRONMENT
    (:LISP #A((4) BASE-CHAR . "SBCL") :VERSION #A((5) BASE-CHAR . "2.6.9") :OS
     #A((6) BASE-CHAR . "Darwin") :OS-VERSION #A((6) BASE-CHAR . "27.0.0")
     :MACHINE #A((5) BASE-CHAR . "ARM64") :CPU "Apple M4" :MEMORY-BYTES
     17179869184 :LOGICAL-CPUS 10 :EXTERNAL-LOAD-STATUS :UNCONTROLLED
     :LOAD-AVERAGE "{ 1.93 2.95 3.67 }" :COMMIT
     "4be51e78593f5d0e8f885c66c80e4cf524c5518f" :WORKING-TREE "" :SOURCE-BLOBS
     ((:PATH "spikes/SPK-01-primary-index/profile.lisp" :GIT-BLOB
       "a71fde100e32072b6e7b010228683b640ea4ff9a")
      (:PATH "spikes/SPK-01-primary-index/run.lisp" :GIT-BLOB
       "b6e680b0c2d1a96c1d7fc3b0e133c80b6564a01e")
      (:PATH #A((37) BASE-CHAR . "spikes/SPK-01-primary-index/core.lisp")
       :GIT-BLOB "c019f6ad53e173a0d336a4dbfaf903e274a66f08")
      (:PATH "spikes/SPK-01-primary-index/lettura-buffer.lisp" :GIT-BLOB
       "34b3574a554ca4e03a34f04b3fc66022abb7893b")
      (:PATH "spikes/SPK-01-primary-index/check-lettura-buffer.lisp" :GIT-BLOB
       "fd32c5260ffb7c6e96cf1a420765eb01effe70bc")
      (:PATH "spikes/SPK-02-gc/run.lisp" :GIT-BLOB
       "9fbe499100da40c2f7a14072af67c35c734949c5")
      (:PATH #A((26) BASE-CHAR . "spikes/SPK-02-gc/core.lisp") :GIT-BLOB
       "01f6760c75fa6e96a480fca41b1426941a9f703d")
      (:PATH "spikes/SPK-03-group-commit/run.lisp" :GIT-BLOB
       "c0b093e87028dd587c43d3cd52e59492270fdc38")
      (:PATH #A((36) BASE-CHAR . "spikes/SPK-03-group-commit/core.lisp")
       :GIT-BLOB "d3c58f2866e299ba27b0fa820c20317438774410")
      (:PATH "spikes/SPK-04-writer-pool/run.lisp" :GIT-BLOB
       "77056cc1f695574ed0f4d34795b99aaea736f378")
      (:PATH #A((35) BASE-CHAR . "spikes/SPK-04-writer-pool/core.lisp")
       :GIT-BLOB "557b32e6378290c46c7d9b128fc8e59a0e7e0a44")
      (:PATH "spikes/SPK-04-writer-pool/pool.lisp" :GIT-BLOB
       "cbec51aad2b64fb8c5be026891eff859ba371c18")
      (:PATH "spikes/SPK-04-writer-pool/parcheggi.lisp" :GIT-BLOB
       "c0fee7b738395fcaf3359f297282cd266ce6dfad")
      (:PATH "spikes/SPK-05-segment-read/run.lisp" :GIT-BLOB
       "c67a3ae8e672f96d9105deb935fb621b07d67afb")
      (:PATH #A((36) BASE-CHAR . "spikes/SPK-05-segment-read/core.lisp")
       :GIT-BLOB "2c0c5a6b5c75a56a4db72fa88ff867cdb3db8508")
      (:PATH "spikes/SPK-06-compaction-load/run.lisp" :GIT-BLOB
       "b2863cbac49d0988b850bdeeae1713108a21bfca")
      (:PATH #A((39) BASE-CHAR . "spikes/SPK-06-compaction-load/core.lisp")
       :GIT-BLOB "375cb97e1490e0252c04fd1a3076a17342cefd68")
      (:PATH "spikes/SPK-06-compaction-load/controllore.lisp" :GIT-BLOB
       "4602972e2400d31d4d3b771f60703c68e23f0804")
      (:PATH "spikes/SPK-06-compaction-load/interferenza.lisp" :GIT-BLOB
       "6fe454e8018bcf21b40726f928bf4380b5d06a9d")
      (:PATH "spikes/SPK-05-segment-read/io.lisp" :GIT-BLOB
       "ba470bce3cae0ce14888dbec6e26c5656e9bbd1a")
      (:PATH "spikes/SPK-05-segment-read/record.lisp" :GIT-BLOB
       "baea7833c8e6f9a49b5ea2f8ee15f76fe35f93fe")
      (:PATH "spikes/SPK-07-protocols/run.lisp" :GIT-BLOB
       "648bd776767e4be914a2470069afced14bc1c1e5")
      (:PATH #A((33) BASE-CHAR . "spikes/SPK-07-protocols/core.lisp") :GIT-BLOB
       "489e2732cf5bfed4cd11251bb686a5d4f4e10b3e")
      (:PATH "spikes/SPK-07-protocols/pubblicazione.lisp" :GIT-BLOB
       "d317849b3f95394a7f604b82fb131495b5b3770c")
      (:PATH "spikes/SPK-07-protocols/scadenza.lisp" :GIT-BLOB
       "05a5e93591e2d6e96c2c7548e90888424cbb1f9f")
      (:PATH "spikes/SPK-07-protocols/compaction.lisp" :GIT-BLOB
       "93483f72f3bfe43f0e2afa93b022892114a824e1")
      (:PATH "spikes/SPK-07-protocols/memoria.lisp" :GIT-BLOB
       "96b6cf64d481643cdba7857f339a7cb7c029b765")
      (:PATH "spikes/SPK-07-protocols/suite.lisp" :GIT-BLOB
       "a813fbeb55cd03980b2215c99fc3170d6afa4d92")
      (:PATH "spikes/SPK-07-protocols/seqlock-readers.lisp" :GIT-BLOB
       "b2e704bbe7e699b9df68173319f64d2ae8abc5fc")
      (:PATH "spikes/SPK-07-protocols/byte-crash.lisp" :GIT-BLOB
       "66a6c3b458d808fc214f7c3bd96e09d239312c67")
      (:PATH "src/package.lisp" :GIT-BLOB
       "3d0181717e3f334580bab9a6a507e2dfe57261ff")
      (:PATH "src/foundation/package.lisp" :GIT-BLOB
       "0658b083f1e777aa0ada67a63535d36946921eac")
      (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
       "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
      (:PATH "src/foundation/binary.lisp" :GIT-BLOB
       "2d514f6fe2e81eecb29fa53de611fa5e28696904")
      (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
       "f9c691d28620427099d1d89a89a1ff5d04cbe257")
      (:PATH "src/foundation/record.lisp" :GIT-BLOB
       "8df53d416747131d9ed9921abb4ef356d9ce5696")
      (:PATH "src/foundation/batch.lisp" :GIT-BLOB
       "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
      (:PATH "spikes/SPK-08-generated-code/run.lisp" :GIT-BLOB
       "a1fdf6705a10fcca3926f40e26051fe7b6df5bf0")
      (:PATH "spikes/SPK-08-generated-code/impronte.lisp" :GIT-BLOB
       "d187e3d95f0e85a0a8ae84843a67a326e803cd2c")
      (:PATH "spikes/SPK-08-generated-code/simd.lisp" :GIT-BLOB
       "dbd551322880f1e0ddac6436c8af8f0dd85ddb9f")
      (:PATH "spikes/SPK-08-generated-code/bitmap.lisp" :GIT-BLOB
       "cbeff7e2a58f268291b01cb6a1f124533063d5d6")
      (:PATH "spikes/SPK-08-generated-code/core-bitmap.lisp" :GIT-BLOB
       "a4be2005a702a77a631f35568778673c503c60b5")
      (:PATH "spikes/SPK-09-integrity/run.lisp" :GIT-BLOB
       "c95660a4df5f2e6f6eb93e1078c2c36df6dabc85")
      (:PATH "tools/run-spikes.lisp" :GIT-BLOB
       "04e1cd5c1a3c63c9fc47e307f7dfdb2cc3316540")
      (:PATH "spikes/SPK-10-v2-limits/run.lisp" :GIT-BLOB
       "6aa63afeac91c3b75174b76daba61e354bb7fe4d")
      (:PATH #A((33) BASE-CHAR . "spikes/SPK-10-v2-limits/core.lisp") :GIT-BLOB
       "c5b7cfd27c663734b7d5fae481dde939418566b5")
      (:PATH "spikes/SPK-10-v2-limits/codec.lisp" :GIT-BLOB
       "567c84546d29e1b8ddc5cd9e1a31b4e93519c75d")
      (:PATH "spikes/SPK-10-v2-limits/indice.lisp" :GIT-BLOB
       "bc978eb16aa7f0d69e3deac2df86057a650f8551")
      (:PATH "spikes/SPK-10-v2-limits/cbor.lisp" :GIT-BLOB
       "d6a5c93e34a0444d64b206df875a25b380545631")
      (:PATH "spikes/SPK-10-v2-limits/migrazione.lisp" :GIT-BLOB
       "cab850dc32ff9908b487b24edf3e1df2cc90008c")
      (:PATH "spikes/SPK-09-integrity/core.lisp" :GIT-BLOB
       "80cdac4c0e52703618e1f274413b2ecbe00e6b14"))
     :DYNAMIC-SPACE-MIB 4096 :DATE-UNIVERSAL-TIME 4000485399)
    :MODE #A((7) BASE-CHAR . "--check") :STATUS :COMPLETE :RUNS
    ((:ARTIFACT #A((27) BASE-CHAR . "processo-header-SPK-01.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-header-SPK-02.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-header-SPK-03.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-header-SPK-04.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-header-SPK-05.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-header-SPK-06.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-header-SPK-07.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-header-SPK-08.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-header-SPK-09.lisp"))
     (:ARTIFACT #A((27) BASE-CHAR . "processo-header-SPK-10.lisp")))
    :RUN-ARTIFACTS
    (#A((106) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485395-check-10324-0/SPK-01.lisp")
     #A((106) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485395-check-10324-0/SPK-02.lisp")
     #A((106) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485395-check-10324-0/SPK-03.lisp")
     #A((106) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485395-check-10324-0/SPK-04.lisp")
     #A((106) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485395-check-10324-0/SPK-05.lisp")
     #A((106) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485395-check-10324-0/SPK-06.lisp")
     #A((106) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485395-check-10324-0/SPK-07.lisp")
     #A((106) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485395-check-10324-0/SPK-08.lisp")
     #A((106) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485395-check-10324-0/SPK-09.lisp")
     #A((106) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/wal-batches/ArcDocDB/spikes/out/4000485395-check-10324-0/SPK-10.lisp"))))
  (:COMMAND-RECORD
   "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/4000485427-command-10606-0/report.lisp"
   :PARENT-WITH-RUN-REFERENCES
   (:SCHEMA-VERSION 1 :ENVIRONMENT
    (:LISP #A((4) BASE-CHAR . "SBCL") :VERSION #A((5) BASE-CHAR . "2.6.9") :OS
     #A((6) BASE-CHAR . "Darwin") :OS-VERSION #A((6) BASE-CHAR . "27.0.0")
     :MACHINE #A((5) BASE-CHAR . "ARM64") :CPU "Apple M4" :MEMORY-BYTES
     17179869184 :LOGICAL-CPUS 10 :EXTERNAL-LOAD-STATUS :UNCONTROLLED
     :LOAD-AVERAGE "{ 2.34 2.92 3.63 }" :COMMIT
     "67a2695aef4074a3269d3bb2191cf202cde9cd1e" :WORKING-TREE "M  arcdocdb.asd
M  docs/implementazione/README.md
M  docs/implementazione/io.md
A  docs/implementazione/wal-decisioni.md
A  docs/implementazione/wal-metodo.md
A  docs/implementazione/wal.md
A  spikes/results/2026-10-08-wal/4000483741-command-1603-0.lisp
A  spikes/results/2026-10-08-wal/4000483984-command-2219-0.lisp
A  spikes/results/2026-10-08-wal/4000484056-command-2929-0.lisp
A  spikes/results/2026-10-08-wal/4000484163-command-4031-0.lisp
A  spikes/results/2026-10-08-wal/4000484166-command-4062-0.lisp
A  spikes/results/2026-10-08-wal/4000484167-command-4023-0.lisp
A  spikes/results/2026-10-08-wal/4000484304-command-4933-0.lisp
A  spikes/results/2026-10-08-wal/4000484307-command-4925-0.lisp
A  spikes/results/2026-10-08-wal/4000484433-command-5860-0.lisp
A  spikes/results/2026-10-08-wal/4000484435-command-5902-0.lisp
A  spikes/results/2026-10-08-wal/4000484436-command-5933-0.lisp
A  spikes/results/2026-10-08-wal/4000484439-command-5852-0.lisp
A  spikes/results/2026-10-08-wal/4000484527-command-6293-0.lisp
A  spikes/results/2026-10-08-wal/4000484529-command-6328-0.lisp
A  spikes/results/2026-10-08-wal/4000484550-command-6283-0.lisp
A  spikes/results/2026-10-08-wal/4000484731-command-7217-0.lisp
A  spikes/results/2026-10-08-wal/4000484733-command-7258-0.lisp
A  spikes/results/2026-10-08-wal/4000484737-command-7209-0.lisp
A  spikes/results/2026-10-08-wal/4000484801-command-7432-0.lisp
A  spikes/results/2026-10-08-wal/4000484821-command-7424-0.lisp
A  spikes/results/2026-10-08-wal/catalogo.lisp
A  spikes/results/2026-10-08-wal/copertura-candidato-dati.lisp
A  spikes/results/2026-10-08-wal/copertura-iniziale-dati.lisp
A  spikes/results/2026-10-08-wal/mutazioni-dati.lisp
A  spikes/results/2026-10-08-wal/verifica-completa-isolata.lisp
A  spikes/results/2026-10-08-wal/verifica-con-bitmap-e-decisioni.lisp
M  src/io/package.lisp
M  src/io/transfer.lisp
M  src/io/types.lisp
A  src/wal/builder.lisp
A  src/wal/executor.lisp
A  src/wal/group.lisp
A  src/wal/package.lisp
A  src/wal/types.lisp
A  tests/wal/builder.lisp
A  tests/wal/fault.lisp
A  tests/wal/group.lisp
A  tests/wal/native.lisp
A  tests/wal/support.lisp
M  tools/foundation-coverage.lisp
MM tools/foundation-mutation.lisp
A  tools/wal-bench.lisp
?? tests/recovery/decisions-audit.lisp
?? tests/recovery/decisions-support.lisp
?? tests/recovery/decisions.lisp"
     :SOURCE-BLOBS
     ((:PATH "spikes/SPK-01-primary-index/profile.lisp" :GIT-BLOB
       "a71fde100e32072b6e7b010228683b640ea4ff9a")
      (:PATH "spikes/SPK-01-primary-index/run.lisp" :GIT-BLOB
       "b6e680b0c2d1a96c1d7fc3b0e133c80b6564a01e")
      (:PATH #A((37) BASE-CHAR . "spikes/SPK-01-primary-index/core.lisp")
       :GIT-BLOB "c019f6ad53e173a0d336a4dbfaf903e274a66f08")
      (:PATH "spikes/SPK-01-primary-index/lettura-buffer.lisp" :GIT-BLOB
       "34b3574a554ca4e03a34f04b3fc66022abb7893b")
      (:PATH "spikes/SPK-01-primary-index/check-lettura-buffer.lisp" :GIT-BLOB
       "fd32c5260ffb7c6e96cf1a420765eb01effe70bc")
      (:PATH "spikes/SPK-02-gc/run.lisp" :GIT-BLOB
       "9fbe499100da40c2f7a14072af67c35c734949c5")
      (:PATH #A((26) BASE-CHAR . "spikes/SPK-02-gc/core.lisp") :GIT-BLOB
       "01f6760c75fa6e96a480fca41b1426941a9f703d")
      (:PATH "spikes/SPK-03-group-commit/run.lisp" :GIT-BLOB
       "c0b093e87028dd587c43d3cd52e59492270fdc38")
      (:PATH #A((36) BASE-CHAR . "spikes/SPK-03-group-commit/core.lisp")
       :GIT-BLOB "d3c58f2866e299ba27b0fa820c20317438774410")
      (:PATH "spikes/SPK-04-writer-pool/run.lisp" :GIT-BLOB
       "77056cc1f695574ed0f4d34795b99aaea736f378")
      (:PATH #A((35) BASE-CHAR . "spikes/SPK-04-writer-pool/core.lisp")
       :GIT-BLOB "557b32e6378290c46c7d9b128fc8e59a0e7e0a44")
      (:PATH "spikes/SPK-04-writer-pool/pool.lisp" :GIT-BLOB
       "cbec51aad2b64fb8c5be026891eff859ba371c18")
      (:PATH "spikes/SPK-04-writer-pool/parcheggi.lisp" :GIT-BLOB
       "c0fee7b738395fcaf3359f297282cd266ce6dfad")
      (:PATH "spikes/SPK-05-segment-read/run.lisp" :GIT-BLOB
       "c67a3ae8e672f96d9105deb935fb621b07d67afb")
      (:PATH #A((36) BASE-CHAR . "spikes/SPK-05-segment-read/core.lisp")
       :GIT-BLOB "2c0c5a6b5c75a56a4db72fa88ff867cdb3db8508")
      (:PATH "spikes/SPK-06-compaction-load/run.lisp" :GIT-BLOB
       "b2863cbac49d0988b850bdeeae1713108a21bfca")
      (:PATH #A((39) BASE-CHAR . "spikes/SPK-06-compaction-load/core.lisp")
       :GIT-BLOB "375cb97e1490e0252c04fd1a3076a17342cefd68")
      (:PATH "spikes/SPK-06-compaction-load/controllore.lisp" :GIT-BLOB
       "4602972e2400d31d4d3b771f60703c68e23f0804")
      (:PATH "spikes/SPK-06-compaction-load/interferenza.lisp" :GIT-BLOB
       "6fe454e8018bcf21b40726f928bf4380b5d06a9d")
      (:PATH "spikes/SPK-05-segment-read/io.lisp" :GIT-BLOB
       "ba470bce3cae0ce14888dbec6e26c5656e9bbd1a")
      (:PATH "spikes/SPK-05-segment-read/record.lisp" :GIT-BLOB
       "baea7833c8e6f9a49b5ea2f8ee15f76fe35f93fe")
      (:PATH "spikes/SPK-07-protocols/run.lisp" :GIT-BLOB
       "648bd776767e4be914a2470069afced14bc1c1e5")
      (:PATH #A((33) BASE-CHAR . "spikes/SPK-07-protocols/core.lisp") :GIT-BLOB
       "489e2732cf5bfed4cd11251bb686a5d4f4e10b3e")
      (:PATH "spikes/SPK-07-protocols/pubblicazione.lisp" :GIT-BLOB
       "d317849b3f95394a7f604b82fb131495b5b3770c")
      (:PATH "spikes/SPK-07-protocols/scadenza.lisp" :GIT-BLOB
       "05a5e93591e2d6e96c2c7548e90888424cbb1f9f")
      (:PATH "spikes/SPK-07-protocols/compaction.lisp" :GIT-BLOB
       "93483f72f3bfe43f0e2afa93b022892114a824e1")
      (:PATH "spikes/SPK-07-protocols/memoria.lisp" :GIT-BLOB
       "96b6cf64d481643cdba7857f339a7cb7c029b765")
      (:PATH "spikes/SPK-07-protocols/suite.lisp" :GIT-BLOB
       "a813fbeb55cd03980b2215c99fc3170d6afa4d92")
      (:PATH "spikes/SPK-07-protocols/seqlock-readers.lisp" :GIT-BLOB
       "b2e704bbe7e699b9df68173319f64d2ae8abc5fc")
      (:PATH "spikes/SPK-07-protocols/byte-crash.lisp" :GIT-BLOB
       "66a6c3b458d808fc214f7c3bd96e09d239312c67")
      (:PATH "src/package.lisp" :GIT-BLOB
       "3d0181717e3f334580bab9a6a507e2dfe57261ff")
      (:PATH "src/foundation/package.lisp" :GIT-BLOB
       "0658b083f1e777aa0ada67a63535d36946921eac")
      (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
       "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
      (:PATH "src/foundation/binary.lisp" :GIT-BLOB
       "2d514f6fe2e81eecb29fa53de611fa5e28696904")
      (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
       "f9c691d28620427099d1d89a89a1ff5d04cbe257")
      (:PATH "src/foundation/record.lisp" :GIT-BLOB
       "8df53d416747131d9ed9921abb4ef356d9ce5696")
      (:PATH "src/foundation/batch.lisp" :GIT-BLOB
       "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
      (:PATH "spikes/SPK-08-generated-code/run.lisp" :GIT-BLOB
       "a1fdf6705a10fcca3926f40e26051fe7b6df5bf0")
      (:PATH "spikes/SPK-08-generated-code/impronte.lisp" :GIT-BLOB
       "d187e3d95f0e85a0a8ae84843a67a326e803cd2c")
      (:PATH "spikes/SPK-08-generated-code/simd.lisp" :GIT-BLOB
       "dbd551322880f1e0ddac6436c8af8f0dd85ddb9f")
      (:PATH "spikes/SPK-08-generated-code/bitmap.lisp" :GIT-BLOB
       "cbeff7e2a58f268291b01cb6a1f124533063d5d6")
      (:PATH "spikes/SPK-08-generated-code/core-bitmap.lisp" :GIT-BLOB
       "a4be2005a702a77a631f35568778673c503c60b5")
      (:PATH "spikes/SPK-09-integrity/run.lisp" :GIT-BLOB
       "c95660a4df5f2e6f6eb93e1078c2c36df6dabc85")
      (:PATH "tools/run-spikes.lisp" :GIT-BLOB
       "04e1cd5c1a3c63c9fc47e307f7dfdb2cc3316540")
      (:PATH "spikes/SPK-10-v2-limits/run.lisp" :GIT-BLOB
       "6aa63afeac91c3b75174b76daba61e354bb7fe4d")
      (:PATH #A((33) BASE-CHAR . "spikes/SPK-10-v2-limits/core.lisp") :GIT-BLOB
       "c5b7cfd27c663734b7d5fae481dde939418566b5")
      (:PATH "spikes/SPK-10-v2-limits/codec.lisp" :GIT-BLOB
       "567c84546d29e1b8ddc5cd9e1a31b4e93519c75d")
      (:PATH "spikes/SPK-10-v2-limits/indice.lisp" :GIT-BLOB
       "bc978eb16aa7f0d69e3deac2df86057a650f8551")
      (:PATH "spikes/SPK-10-v2-limits/cbor.lisp" :GIT-BLOB
       "d6a5c93e34a0444d64b206df875a25b380545631")
      (:PATH "spikes/SPK-10-v2-limits/migrazione.lisp" :GIT-BLOB
       "cab850dc32ff9908b487b24edf3e1df2cc90008c")
      (:PATH "spikes/SPK-09-integrity/core.lisp" :GIT-BLOB
       "80cdac4c0e52703618e1f274413b2ecbe00e6b14"))
     :DYNAMIC-SPACE-MIB 4096 :DATE-UNIVERSAL-TIME 4000485439)
    :MODE #A((7) BASE-CHAR . "--check") :STATUS :COMPLETE :RUNS
    ((:ARTIFACT #A((30) BASE-CHAR . "processo-integrata-SPK-01.lisp"))
     (:ARTIFACT #A((30) BASE-CHAR . "processo-integrata-SPK-02.lisp"))
     (:ARTIFACT #A((30) BASE-CHAR . "processo-integrata-SPK-03.lisp"))
     (:ARTIFACT #A((30) BASE-CHAR . "processo-integrata-SPK-04.lisp"))
     (:ARTIFACT #A((30) BASE-CHAR . "processo-integrata-SPK-05.lisp"))
     (:ARTIFACT #A((30) BASE-CHAR . "processo-integrata-SPK-06.lisp"))
     (:ARTIFACT #A((30) BASE-CHAR . "processo-integrata-SPK-07.lisp"))
     (:ARTIFACT #A((30) BASE-CHAR . "processo-integrata-SPK-08.lisp"))
     (:ARTIFACT #A((30) BASE-CHAR . "processo-integrata-SPK-09.lisp"))
     (:ARTIFACT #A((30) BASE-CHAR . "processo-integrata-SPK-10.lisp")))
    :RUN-ARTIFACTS
    (#A((87) BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/4000485434-check-10646-0/SPK-01.lisp")
     #A((87) BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/4000485434-check-10646-0/SPK-02.lisp")
     #A((87) BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/4000485434-check-10646-0/SPK-03.lisp")
     #A((87) BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/4000485434-check-10646-0/SPK-04.lisp")
     #A((87) BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/4000485434-check-10646-0/SPK-05.lisp")
     #A((87) BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/4000485434-check-10646-0/SPK-06.lisp")
     #A((87) BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/4000485434-check-10646-0/SPK-07.lisp")
     #A((87) BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/4000485434-check-10646-0/SPK-08.lisp")
     #A((87) BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/4000485434-check-10646-0/SPK-09.lisp")
     #A((87) BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/4000485434-check-10646-0/SPK-10.lisp")))))
 :LIMITS
 (:PARENT-RUNS-REPLACED-WITH-EXACT-PROCESS-RECORD-REFERENCES
  :RAW-CHILD-RECORDS-UNCHANGED :NO-REQUIREMENT-PROMOTION))
