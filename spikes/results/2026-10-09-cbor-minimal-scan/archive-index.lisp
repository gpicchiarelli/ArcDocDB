(:SCHEMA-VERSION 1 :KIND :ORIGINAL-COMMAND-ARCHIVE :METADATA-POLICY
 :READ-WITHOUT-RESULT-INFERENCE :PROCESSES
 ((:LABEL "preliminary" :RECORD-PATH "processes/preliminary/report.lisp"
   :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "make") #A((4) BASE-CHAR . "test")
    #A((4) BASE-CHAR . "lint") #A((5) BASE-CHAR . "trace")))
  (:LABEL "coverage-self" :RECORD-PATH "processes/coverage-self/report.lisp"
   :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((30) BASE-CHAR . "tools/foundation-coverage.lisp")
    #A((11) BASE-CHAR . "--self-test")
    #A((52) BASE-CHAR
       . "spikes/out/cbor-minimal-scan-coverage-self-20261009/")))
  (:LABEL "legacy-mutator-self" :RECORD-PATH
   "processes/legacy-mutator-self/report.lisp" :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((32) BASE-CHAR . "tools/cbor-minimal-mutation.lisp")
    #A((11) BASE-CHAR . "--self-test")))
  (:LABEL "archive-self" :RECORD-PATH "processes/archive-self/report.lisp"
   :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((32) BASE-CHAR . "tools/check-command-archive.lisp")
    #A((11) BASE-CHAR . "--self-test")
    #A((49) BASE-CHAR . "spikes/out/command-archive-check-self-20261009-a/")))
  (:LABEL "benchmark" :RECORD-PATH "processes/benchmark/report.lisp" :STATUS
   :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((34) BASE-CHAR . "tools/cbor-minimal-scan-bench.lisp")
    #A((7) BASE-CHAR . "--bench")))
  (:LABEL "coverage" :RECORD-PATH "processes/coverage/report.lisp" :STATUS :OK
   :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((30) BASE-CHAR . "tools/foundation-coverage.lisp")
    #A((8) BASE-CHAR . "--report")
    #A((47) BASE-CHAR . "spikes/out/cbor-minimal-scan-coverage-20261009/")
    #A((17) BASE-CHAR . "cbor-minimal-scan")))
  (:LABEL "old-final-audit" :RECORD-PATH
   "processes/old-final-audit/report.lisp" :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((32) BASE-CHAR . "tools/check-command-archive.lisp")
    #A((9) BASE-CHAR . "--archive")
    #A((45) BASE-CHAR . "spikes/results/2026-10-09-cbor-minimal-final/")))
  (:LABEL "mutations" :RECORD-PATH "processes/mutations/report.lisp" :STATUS
   :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((32) BASE-CHAR . "tools/cbor-minimal-mutation.lisp")
    #A((6) BASE-CHAR . "--scan") #A((5) BASE-CHAR . "--run")
    #A((48) BASE-CHAR . "spikes/out/cbor-minimal-scan-mutations-20261009/")))
  (:LABEL "old-archive-audit" :RECORD-PATH
   "processes/old-archive-audit/report.lisp" :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((32) BASE-CHAR . "tools/check-command-archive.lisp")
    #A((9) BASE-CHAR . "--archive")
    #A((39) BASE-CHAR . "spikes/results/2026-10-09-cbor-minimal/")))
  (:LABEL "coverage-compaction" :RECORD-PATH
   "processes/coverage-compaction/report.lisp" :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((27) BASE-CHAR . "tools/compact-evidence.lisp")
    #A((6) BASE-CHAR . "--root")
    #A((47) BASE-CHAR . "spikes/out/cbor-minimal-scan-coverage-20261009/")
    #A((6) BASE-CHAR . "--jobs") #A((1) BASE-CHAR . "1"))))
 :FILES
 ((:PATH "collection-manifest.lisp" :SOURCE
   #A((105) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/scan-collection-manifest.lisp")
   :BYTES 14048 :SHA256
   "6bf5181aca1f603d24167454023a8408bcd9d54e01db1e25e453719ce04fe0d0")
  (:PATH "collection-source.lisp" :SOURCE
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-collection/collect.lisp")
   :BYTES 9657 :SHA256
   "09adae7145af41bbb8bd6fd91d33d5cbdfa47d4b10908f004d46b70f1ae6597a")
  (:PATH "processes/archive-self/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552284-command-64447-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "94303490316bc7edafc5c0720df6d6ef4f6909d22532eea49336cce7833d082c")
  (:PATH "processes/archive-self/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552284-command-64447-0/report.lisp")
   :BYTES 129529 :SHA256
   "5864cffc78b15bebdb0b36d87fec2757df2b5ce4aa2eeb24bf6402429801fd73")
  (:PATH "processes/benchmark/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552318-command-65001-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "a7c621bae23ffc8be0592601a5d2495b7abbf1c105b1b40041017e7771705b06")
  (:PATH "processes/benchmark/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552318-command-65001-0/report.lisp")
   :BYTES 146823 :SHA256
   "81eed10a22062c26c2f304a96c34541fd50ee2e9088334a1144bd6fb6a302751")
  (:PATH "processes/coverage-compaction/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552418-command-67182-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "8e181361a1628ec5a9b98e734388528a590af72695d20abbf308905167b70a26")
  (:PATH "processes/coverage-compaction/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552418-command-67182-0/report.lisp")
   :BYTES 112660 :SHA256
   "31ce7f2f15c5e54e60fe85538a0746c832899c4856145f535f2c094c7f272289")
  (:PATH "processes/coverage-self/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552284-command-64445-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "449e3927147549be70a2521f7b7f6203bea578d3c1672e622f78dbea935ea364")
  (:PATH "processes/coverage-self/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552284-command-64445-0/report.lisp")
   :BYTES 111580 :SHA256
   "d960845395c61344342945bf12cacc739eb342801f833e14f6fad6cce23b02a1")
  (:PATH "processes/coverage/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552339-command-65156-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "c8439e0f7e73a0a8d7b0ecda83a365075b158045c31b727f385b5f1a8b416568")
  (:PATH "processes/coverage/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552339-command-65156-0/report.lisp")
   :BYTES 115777 :SHA256
   "e1652a16e16d01020443fcc34528d7a3ea6fe5e34b989ff72e1b2c923a4472cf")
  (:PATH "processes/legacy-mutator-self/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552284-command-64446-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "828fc71e5e8f4140fbe68dfcc0f6012aaf261b86b2fbfa461f60c52005bb6343")
  (:PATH "processes/legacy-mutator-self/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552284-command-64446-0/report.lisp")
   :BYTES 152003 :SHA256
   "5b1c9c6fe3c385b49038d669b1341f158e139f97c639a1be3374dd38fef3da6e")
  (:PATH "processes/mutations/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552339-command-65155-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "18edf57fc2e2dd412ab43431620163f8db3ef3aac7111aa49a4d98392aba4254")
  (:PATH "processes/mutations/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552339-command-65155-0/report.lisp")
   :BYTES 155847 :SHA256
   "af28696c5a96c8b5e4f9fd657bfc4c1d6013d20432378b2aa5c761c7d03ef546")
  (:PATH "processes/old-archive-audit/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552339-command-65158-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "3885617fe99de5432b32c7f04c2158aeb55f13ab633d27f8751e4febac15978a")
  (:PATH "processes/old-archive-audit/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552339-command-65158-0/report.lisp")
   :BYTES 114790 :SHA256
   "c16a2c5a53b742d78428473c94a3fd5ee31a39c292c5395e166c66a3bfb5f8a9")
  (:PATH "processes/old-final-audit/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552339-command-65157-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "7240d1d08899573a379760f95a829ed3f4e4f75c2d52ad1ce9ee7607a5394b15")
  (:PATH "processes/old-final-audit/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552339-command-65157-0/report.lisp")
   :BYTES 114032 :SHA256
   "8416bda9b0b4532a08028abbbf6772085382e2783eab66a9f5199f16120c4990")
  (:PATH "processes/preliminary/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552268-command-64251-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "bb7b3a8a679328434d4fe87a095df419aa43b943f9e8e2e4c35335e0555ee6d2")
  (:PATH "processes/preliminary/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552268-command-64251-0/report.lisp")
   :BYTES 285763 :SHA256
   "373126e8165deb55898b0f19effa6a09d6c33ed5c67dd1a90b1e6f96ce3b7f7e")
  (:PATH "raw/archive-self-cases/absolute.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/absolute.lisp")
   :BYTES 697 :SHA256
   "a9f6957d21546dae4a6d9163547c1a1c3d0bb9f85ed7e84bec3c2ff211832f7f")
  (:PATH "raw/archive-self-cases/bytes.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/bytes.lisp")
   :BYTES 529 :SHA256
   "7347ad43fd4965e5e8bf1fd3796738d8d01ecdd73a929c8bdd8148f4952c19a5")
  (:PATH "raw/archive-self-cases/catalogue-entries.lisp" :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/catalogue-entries.lisp")
   :BYTES 713 :SHA256
   "28f8d51e70d75120cfb341fe3f050e79651ed584718a633343f06e913e11fe2c")
  (:PATH "raw/archive-self-cases/catalogue-pending.lisp" :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/catalogue-pending.lisp")
   :BYTES 758 :SHA256
   "5235b3586524e72cfec655fce13cd833f5ec90e6514a938c4ae1da3cf66606e9")
  (:PATH "raw/archive-self-cases/corrupt.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/corrupt.lisp")
   :BYTES 533 :SHA256
   "7aeebb39678466c9302acc0778f55f7a7a4bcff53326e079e9fd19a765c0ad48")
  (:PATH "raw/archive-self-cases/directory-symlink.lisp" :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/directory-symlink.lisp")
   :BYTES 721 :SHA256
   "fb515d56fd86592b5853c0f50f29f43ac27fcdeab27aaae9d7a69ca534c46fd2")
  (:PATH "raw/archive-self-cases/duplicate.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/duplicate.lisp")
   :BYTES 557 :SHA256
   "fd3017fefdf1a9354fcbbee45637198e2bc99981c3d58d4a11858e167e7ce776")
  (:PATH "raw/archive-self-cases/escape.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/escape.lisp")
   :BYTES 578 :SHA256
   "acb71130bb58af0f30c7d4b776e54cd03c231265d8bfffc5a8e5a905725b95eb")
  (:PATH "raw/archive-self-cases/extra.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/extra.lisp")
   :BYTES 535 :SHA256
   "213530e1774a25a28ab7600af269f832950d7f9585a9853d43773c8e8d960a8c")
  (:PATH "raw/archive-self-cases/gzip-budget.lisp" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/gzip-budget.lisp")
   :BYTES 559 :SHA256
   "b5ff40b6147842504537a5b0b233d2f86274ee651bb9872e3eefa1dd4f85d370")
  (:PATH "raw/archive-self-cases/index-read-eval.lisp" :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/index-read-eval.lisp")
   :BYTES 959 :SHA256
   "6b320d92423f23442c5396401e407b9920e20827cf0d1eefb4fddd29f065ddfc")
  (:PATH "raw/archive-self-cases/index-schema.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/index-schema.lisp")
   :BYTES 720 :SHA256
   "4065682c8b57f18d1d27c9748b18806fc072036e07444c0bbadc0f35353b9b5c")
  (:PATH "raw/archive-self-cases/index-trailing.lisp" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/index-trailing.lisp")
   :BYTES 891 :SHA256
   "5e33887605a8e0f76e3d60c5e5229273e08eac03600de64b90af582904562570")
  (:PATH "raw/archive-self-cases/missing.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/missing.lisp")
   :BYTES 557 :SHA256
   "3e673c88704d0a57a548a579215e783e70964661cbd350d2d73260eb34590a24")
  (:PATH "raw/archive-self-cases/plain-budget.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/plain-budget.lisp")
   :BYTES 563 :SHA256
   "ee81bf92ddf9df0f392e88a5e541dcde6b21e49af2f8f1d75796e3fe3bcda83b")
  (:PATH "raw/archive-self-cases/process-command.lisp" :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/process-command.lisp")
   :BYTES 601 :SHA256
   "5fe04b5ef8830a4c9f63b1a7cf2a896f1611fa724049ac7486f6514a599d6590")
  (:PATH "raw/archive-self-cases/process-duplicate.lisp" :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/process-duplicate.lisp")
   :BYTES 595 :SHA256
   "872b2accf0a4de6b7eb3757eab747262cccee8afeacc6808e60cd5848dd718f0")
  (:PATH "raw/archive-self-cases/process-exit.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/process-exit.lisp")
   :BYTES 594 :SHA256
   "b309eb489a5a60373af57d9b1e591b4e8c2db357c22ce62a72cfefbf4eda2b1a")
  (:PATH "raw/archive-self-cases/process-source.lisp" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/process-source.lisp")
   :BYTES 609 :SHA256
   "22f3c7e7f3837e6432bbddd7bb539507b801ed7b98d3d736d858a4b0f8c0c6d3")
  (:PATH "raw/archive-self-cases/process-status.lisp" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/process-status.lisp")
   :BYTES 597 :SHA256
   "ec97f4dce2f43c14b4c63132233c4388c9d6aca7b18dc4f1885651a7e762e7af")
  (:PATH "raw/archive-self-cases/report-read-eval.lisp" :SOURCE
   #A((141) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/report-read-eval.lisp")
   :BYTES 982 :SHA256
   "3483280f65021fa6011f1d40443c67dcd7424a5817c9ffc410b3cf9276f9d91f")
  (:PATH "raw/archive-self-cases/report-trailing.lisp" :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/report-trailing.lisp")
   :BYTES 914 :SHA256
   "c97d45ca395413b62ad5b6724670d28992531b551e026d4e69bee2efdadf43d6")
  (:PATH "raw/archive-self-cases/symlink.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/cases/symlink.lisp")
   :BYTES 689 :SHA256
   "b211e5d393aef513cc9890929c86cd657499fe6fe9e9fed5e2e4819a7462e675")
  (:PATH "raw/archive-self-logs/absolute.stderr.log" :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/absolute.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/absolute.stdout.log" :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/absolute.stdout.log")
   :BYTES 297 :SHA256
   "33704935e0c9e07e26414d543b50dd28a44b91b48f3d9a09879b12d7634383f4")
  (:PATH "raw/archive-self-logs/bytes.stderr.log" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/bytes.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/bytes.stdout.log" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/bytes.stdout.log")
   :BYTES 148 :SHA256
   "d145707ddbce6e406e76f5a715d0035373b71bfbb60eec9d0fa567438fc55e5c")
  (:PATH "raw/archive-self-logs/catalogue-entries.stderr.log" :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/catalogue-entries.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/catalogue-entries.stdout.log" :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/catalogue-entries.stdout.log")
   :BYTES 283 :SHA256
   "415eb06f9f84299001bcd468f1792f21cb407486ab32cf6b547c545481e908a2")
  (:PATH "raw/archive-self-logs/catalogue-pending.stderr.log" :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/catalogue-pending.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/catalogue-pending.stdout.log" :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/catalogue-pending.stdout.log")
   :BYTES 326 :SHA256
   "f4a13f2440bd446619dc848f80e019a5eebb0433f01e55f914bc407fe8f0aa2f")
  (:PATH "raw/archive-self-logs/corrupt.stderr.log" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/corrupt.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/corrupt.stdout.log" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/corrupt.stdout.log")
   :BYTES 145 :SHA256
   "a5ea258632ee0d775e64c468f5e7d196e4636536ff0de9fc242936f75e0794ee")
  (:PATH "raw/archive-self-logs/directory-symlink.stderr.log" :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/directory-symlink.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/directory-symlink.stdout.log" :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/directory-symlink.stdout.log")
   :BYTES 292 :SHA256
   "7ba6467bc836e5998777c367669ae27477b0d2b7912ee55468707f357bb6bc6e")
  (:PATH "raw/archive-self-logs/duplicate.stderr.log" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/duplicate.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/duplicate.stdout.log" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/duplicate.stdout.log")
   :BYTES 153 :SHA256
   "6f5d8ca4ecc462ee44e407ff90a0e4612090df888ad27822f466f1b44294e028")
  (:PATH "raw/archive-self-logs/escape.stderr.log" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/escape.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/escape.stdout.log" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/escape.stdout.log")
   :BYTES 185 :SHA256
   "db3ebadbbd78d10a8a32b0353654aaec61e20f07b5ece44ce4b4b1292af4af38")
  (:PATH "raw/archive-self-logs/extra.stderr.log" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/extra.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/extra.stdout.log" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/extra.stdout.log")
   :BYTES 150 :SHA256
   "bbda23b1325096bfd32cb7a542eee27da44a31a5de0ee3f0db4a776b7360a4af")
  (:PATH "raw/archive-self-logs/gzip-budget.stderr.log" :SOURCE
   #A((141) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/gzip-budget.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/gzip-budget.stdout.log" :SOURCE
   #A((141) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/gzip-budget.stdout.log")
   :BYTES 152 :SHA256
   "7aea8b28cca1672314037644bf630d13c586beff91c62dff4094f99f6f66c921")
  (:PATH "raw/archive-self-logs/index-read-eval.stderr.log" :SOURCE
   #A((145) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/index-read-eval.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/index-read-eval.stdout.log" :SOURCE
   #A((145) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/index-read-eval.stdout.log")
   :BYTES 537 :SHA256
   "8daa282fa97a6ca1fa7a49a080b6f5121babd05740a112b468be96db010d1cca")
  (:PATH "raw/archive-self-logs/index-schema.stderr.log" :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/index-schema.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/index-schema.stdout.log" :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/index-schema.stdout.log")
   :BYTES 309 :SHA256
   "8d0b568469da3a60b6f7f5185bff8c934c2af6b2608fb2dd9e0510d74978a0d4")
  (:PATH "raw/archive-self-logs/index-trailing.stderr.log" :SOURCE
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/index-trailing.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/index-trailing.stdout.log" :SOURCE
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/index-trailing.stdout.log")
   :BYTES 472 :SHA256
   "2591663e43f8679b0abf8b8b378040425f02dd752393fff16d7823d4d1008498")
  (:PATH "raw/archive-self-logs/missing.stderr.log" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/missing.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/missing.stdout.log" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/missing.stdout.log")
   :BYTES 162 :SHA256
   "75638bbcbaded0f36c683929f655a1dd5a8887b27ef55f3b03fdf68da5f79719")
  (:PATH "raw/archive-self-logs/plain-budget.stderr.log" :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/plain-budget.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/plain-budget.stdout.log" :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/plain-budget.stdout.log")
   :BYTES 153 :SHA256
   "eacd169d732fdc9bbae2d254643a35f0ff9005eb597713068214dfb7a2d75f9e")
  (:PATH "raw/archive-self-logs/positive.stderr.log" :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/positive.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/positive.stdout.log" :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/positive.stdout.log")
   :BYTES 1074 :SHA256
   "5f5b7bea04a12032a813bbae43ca1421eb180ec61e11f1d33b1a12e63417eb59")
  (:PATH "raw/archive-self-logs/process-command.stderr.log" :SOURCE
   #A((145) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-command.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/process-command.stdout.log" :SOURCE
   #A((145) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-command.stdout.log")
   :BYTES 178 :SHA256
   "78868ae4fb06b145b688802be5f051b469d075c24193d1b6c2d8ec31a445f04b")
  (:PATH "raw/archive-self-logs/process-duplicate.stderr.log" :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-duplicate.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/process-duplicate.stdout.log" :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-duplicate.stdout.log")
   :BYTES 169 :SHA256
   "453fc82c0b831e4f68ce3eab3d63435c0d38943691e5a6d28fc424cd00439c5a")
  (:PATH "raw/archive-self-logs/process-exit.stderr.log" :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-exit.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/process-exit.stdout.log" :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-exit.stdout.log")
   :BYTES 180 :SHA256
   "d503a69409269071473cfd58c42514b8a6df97f7b9fdab96c353f0e0200859e0")
  (:PATH "raw/archive-self-logs/process-source.stderr.log" :SOURCE
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-source.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/process-source.stdout.log" :SOURCE
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-source.stdout.log")
   :BYTES 189 :SHA256
   "6d170860b5ef1e13384603e98e1f374c1a4f6704559ef83f511c2a5f5d90df7a")
  (:PATH "raw/archive-self-logs/process-status.stderr.log" :SOURCE
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-status.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/process-status.stdout.log" :SOURCE
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-status.stdout.log")
   :BYTES 177 :SHA256
   "f36bd9e33974bc4517075d97385fcf82028fcb0fe1a88a4491df04733d87bd3e")
  (:PATH "raw/archive-self-logs/report-read-eval.stderr.log" :SOURCE
   #A((146) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/report-read-eval.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/report-read-eval.stdout.log" :SOURCE
   #A((146) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/report-read-eval.stdout.log")
   :BYTES 557 :SHA256
   "ad481ebc71900e2a7f3c3133abf8876021bf3441bcd535e81b1a6aa0b2c98740")
  (:PATH "raw/archive-self-logs/report-trailing.stderr.log" :SOURCE
   #A((145) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/report-trailing.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/report-trailing.stdout.log" :SOURCE
   #A((145) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/report-trailing.stdout.log")
   :BYTES 492 :SHA256
   "759497941923b4755a50b75ee2ab59396f0800c5de8535e05a66c2e75159ab0d")
  (:PATH "raw/archive-self-logs/symlink.stderr.log" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/symlink.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/archive-self-logs/symlink.stdout.log" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/symlink.stdout.log")
   :BYTES 290 :SHA256
   "c74e6837a645d5c104a3e07c4fdf4b9b44fa7341bb99ebc9706bf769cedd59cd")
  (:PATH "raw/archive-self/report.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/report.lisp")
   :BYTES 17729 :SHA256
   "1b2b1e437abae2f3bf8dba782b6b343c3590afb37e738d640396fa78933866e1")
  (:PATH "raw/coverage-self/c301e9def08d4ad8610af6fcad382479.html" :SOURCE
   #A((154) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-coverage-self-20261009/c301e9def08d4ad8610af6fcad382479.html")
   :BYTES 2836 :SHA256
   "127dee4565568888a4bf75d33564502807ada7512ade7cc74f1ebbea3dba8e04")
  (:PATH "raw/coverage-self/cover-index.html" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-coverage-self-20261009/cover-index.html")
   :BYTES 1796 :SHA256
   "6e0156111373a1a8c702ead170949cba44d23575ca7ca934f7505ccc7ce2b197")
  (:PATH "raw/coverage-self/coverage-fixture.lisp" :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-coverage-self-20261009/coverage-fixture.lisp")
   :BYTES 147 :SHA256
   "3767518fde8bde1e1286dbf663e97eac01f02e038d7f3161df436d9fd3e92559")
  (:PATH "raw/coverage/75d58828265f6f5e79a3824bc266a6b2.html" :SOURCE
   #A((149) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-coverage-20261009/75d58828265f6f5e79a3824bc266a6b2.html")
   :BYTES 9508 :SHA256
   "6bbec8ade0f1ad4846639ad581c3600911f0f8b1dffeb0da3e23bd162d543e8a")
  (:PATH "raw/coverage/ae0927d0c00b0b447525ad574ea384f2.html" :SOURCE
   #A((149) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-coverage-20261009/ae0927d0c00b0b447525ad574ea384f2.html")
   :BYTES 33467 :SHA256
   "65be3b8adc2c9f5d10e023e6aa973ebbdf9d4f6e06b0ff16af803b426bb32000")
  (:PATH "raw/coverage/cover-index.html" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-coverage-20261009/cover-index.html")
   :BYTES 1942 :SHA256
   "ca3dfb925f3dca2cb48e95057fa203c9b146f8f0008381327463660ba07ae51c")
  (:PATH "raw/coverage/coverage-state.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-coverage-20261009/coverage-state.lisp")
   :BYTES 325 :SHA256
   "faf8d7f01db7678323f46dd1c7d469f224f2daef459e1da96c729b3b321bf077")
  (:PATH "raw/coverage/coverage-state.lisp.gz" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-coverage-20261009/coverage-state.lisp.gz")
   :BYTES 155686 :SHA256
   "b48a6f29223692cbd89c0ac09bc7ecf224bcb25518f9221c29a4e0b3576caa6e")
  (:PATH "raw/frozen/src/codec/cbor-package.lisp" :SOURCE
   #A((92) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/src/codec/cbor-package.lisp")
   :BYTES 511 :SHA256
   "1021ffbdf1bf2f91af3305bd96052ccc123cf64da76213194b11be9e4947244e")
  (:PATH "raw/frozen/src/codec/cbor-scan-minimal.lisp" :SOURCE
   #A((97) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/src/codec/cbor-scan-minimal.lisp")
   :BYTES 1665 :SHA256
   "e6a39d5e39d79c93e19f03bb4e5cd0f07bc6682b768e191095c2359bb910bd79")
  (:PATH "raw/frozen/src/codec/cbor-scan.lisp" :SOURCE
   #A((89) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/src/codec/cbor-scan.lisp")
   :BYTES 5981 :SHA256
   "37a552faab3463e0bb0d967d04381102d8bf8135986ffd4f643213e235a58b6a")
  (:PATH "raw/frozen/tests/codec/cbor-minimal-scan-support.lisp" :SOURCE
   #A((107) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/tests/codec/cbor-minimal-scan-support.lisp")
   :BYTES 8363 :SHA256
   "cc0e49ba0aa0434413a80f484ba4660d5df8ac183560ab7ecb88cf3c80831421")
  (:PATH "raw/frozen/tests/codec/cbor-minimal-scan-threads.lisp" :SOURCE
   #A((107) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/tests/codec/cbor-minimal-scan-threads.lisp")
   :BYTES 4547 :SHA256
   "1c7918faa4077f159990a7419a5de5d846f6301e6e3e728c883edad3e51b8660")
  (:PATH "raw/frozen/tests/codec/cbor-minimal-scan.lisp" :SOURCE
   #A((99) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/tests/codec/cbor-minimal-scan.lisp")
   :BYTES 19217 :SHA256
   "c5f4ad4f625e9f875c4b696482d1e59540375abe335bedb7c42031e0212aa2c8")
  (:PATH "raw/frozen/tools/cbor-minimal-mutation.lisp" :SOURCE
   #A((97) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/tools/cbor-minimal-mutation.lisp")
   :BYTES 34332 :SHA256
   "1cf110c609e009439f221a9fe9ed46ac79a46ebf5ad9e37ebdde7b35b692ff32")
  (:PATH "raw/frozen/tools/cbor-minimal-scan-bench.lisp" :SOURCE
   #A((99) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/tools/cbor-minimal-scan-bench.lisp")
   :BYTES 10528 :SHA256
   "4ec9ff51ef303d5601407e2051808cf893df53b15ebb61e274200a30f63a4c16")
  (:PATH "raw/frozen/tools/check-command-archive.lisp" :SOURCE
   #A((97) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/tools/check-command-archive.lisp")
   :BYTES 28734 :SHA256
   "d1ebbd45d645cbf58ed8254e5216b1367de5c65f1dbb711545dc0ab5bfa9f5bf")
  (:PATH "raw/frozen/tools/foundation-coverage.lisp" :SOURCE
   #A((95) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/tools/foundation-coverage.lisp")
   :BYTES 9099 :SHA256
   "44a69c3153e145d73d3585ccf2f804a53d07815c80fa62ed3209d2e56091cc2e")
  (:PATH "raw/mutation/0/src/codec/cbor-scan-minimal.lisp" :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/0/src/codec/cbor-scan-minimal.lisp")
   :BYTES 1667 :SHA256
   "ed7e0d62629a8dd764ec0d731e9b6af022304fd169625b13e4e2efc9f5c86988")
  (:PATH "raw/mutation/0/src/codec/cbor-scan.lisp" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/0/src/codec/cbor-scan.lisp")
   :BYTES 5981 :SHA256
   "37a552faab3463e0bb0d967d04381102d8bf8135986ffd4f643213e235a58b6a")
  (:PATH "raw/mutation/0/test.log" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/0/test.log")
   :BYTES 18136 :SHA256
   "8dcc204cdac7b09ff1f971db91b70bc872596d609e1f837745d3f3a90c0db5d4")
  (:PATH "raw/mutation/0/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/0/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 478 :SHA256
   "b092db78e31c041c881bbecd209e7d9f231096ecd0db735babb7cdaceeaacc7e")
  (:PATH "raw/mutation/1/src/codec/cbor-scan-minimal.lisp" :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/1/src/codec/cbor-scan-minimal.lisp")
   :BYTES 1665 :SHA256
   "e6a39d5e39d79c93e19f03bb4e5cd0f07bc6682b768e191095c2359bb910bd79")
  (:PATH "raw/mutation/1/src/codec/cbor-scan.lisp" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/1/src/codec/cbor-scan.lisp")
   :BYTES 6023 :SHA256
   "c7ec78742533aad948269206ae3f7ae09979a667549120b26f5bfa145a78c9f8")
  (:PATH "raw/mutation/1/test.log" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/1/test.log")
   :BYTES 18212 :SHA256
   "739460bd9075c80dfba8bea7e7181fefaed1c6b18cefbb93d0aa1147a7ea1b4f")
  (:PATH "raw/mutation/1/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/1/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 478 :SHA256
   "c2c97db33a3eca75dbdfbc1c12262b764570cbbe3d380efcf60be16331769912")
  (:PATH "raw/mutation/2/src/codec/cbor-scan-minimal.lisp" :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/2/src/codec/cbor-scan-minimal.lisp")
   :BYTES 1665 :SHA256
   "e6a39d5e39d79c93e19f03bb4e5cd0f07bc6682b768e191095c2359bb910bd79")
  (:PATH "raw/mutation/2/src/codec/cbor-scan.lisp" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/2/src/codec/cbor-scan.lisp")
   :BYTES 6025 :SHA256
   "f1c7452943284d3ef3366edb3e8e0837ab74ab8f50c977be4a3462c66ebd6161")
  (:PATH "raw/mutation/2/test.log" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/2/test.log")
   :BYTES 18214 :SHA256
   "ac9d437a05f8e363c3cbbcfb5e915b23141ccaca89ba112d709735bb8f930e32")
  (:PATH "raw/mutation/2/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/2/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 478 :SHA256
   "be339df8f30916a6180bdc8610aff0ff8993ae7bfac001a90c58724fd631e32a")
  (:PATH "raw/mutation/3/src/codec/cbor-scan-minimal.lisp" :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/3/src/codec/cbor-scan-minimal.lisp")
   :BYTES 1665 :SHA256
   "e6a39d5e39d79c93e19f03bb4e5cd0f07bc6682b768e191095c2359bb910bd79")
  (:PATH "raw/mutation/3/src/codec/cbor-scan.lisp" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/3/src/codec/cbor-scan.lisp")
   :BYTES 6024 :SHA256
   "38c1977c3548708424fb797827722bf9ce666f7d6d4bb779e6d21d91a81eebc7")
  (:PATH "raw/mutation/3/test.log" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/3/test.log")
   :BYTES 16274 :SHA256
   "3b6a6d6a2009564faf4fd8ed6f8b78d390a616a2994421608ade062696bbc03f")
  (:PATH "raw/mutation/3/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/3/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 478 :SHA256
   "e0ac6266aacfd98dedf14b28b7baf02218e6976430340a19fd57f052cea4a5b7")
  (:PATH "raw/mutation/4/src/codec/cbor-scan-minimal.lisp" :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/4/src/codec/cbor-scan-minimal.lisp")
   :BYTES 1665 :SHA256
   "e6a39d5e39d79c93e19f03bb4e5cd0f07bc6682b768e191095c2359bb910bd79")
  (:PATH "raw/mutation/4/src/codec/cbor-scan.lisp" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/4/src/codec/cbor-scan.lisp")
   :BYTES 6014 :SHA256
   "673246a0272e1c30c3b034a6dfa8e5ba98c4dcb7a4bf5ef6ed0559b3b8f55a53")
  (:PATH "raw/mutation/4/test.log" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/4/test.log")
   :BYTES 16610 :SHA256
   "a4ca93bc469dec1da1e9b7e28e78c0cd5795b6717124ab9321672a94d69dfa09")
  (:PATH "raw/mutation/4/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/4/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 478 :SHA256
   "dc4da55c56620ed5358d7c901b779cb8d3e5b2284672ba5cc355b891589b2677")
  (:PATH "raw/mutation/5/src/codec/cbor-scan-minimal.lisp" :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/5/src/codec/cbor-scan-minimal.lisp")
   :BYTES 1665 :SHA256
   "e6a39d5e39d79c93e19f03bb4e5cd0f07bc6682b768e191095c2359bb910bd79")
  (:PATH "raw/mutation/5/src/codec/cbor-scan.lisp" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/5/src/codec/cbor-scan.lisp")
   :BYTES 6014 :SHA256
   "ced36c8b6a996cfbeb850786b67548cb6dc65784fb7341067afa61fb833ee091")
  (:PATH "raw/mutation/5/test.log" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/5/test.log")
   :BYTES 16935 :SHA256
   "7ce9c9d959c9aa5d41d99fc508002615dafcfee53540d75f807841ea25addebb")
  (:PATH "raw/mutation/5/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/5/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 478 :SHA256
   "5e86cf8381fe718bf54e5f14aa43a707f4ae30c7afb459d3a1463b63df53c135")
  (:PATH "raw/mutation/6/src/codec/cbor-scan-minimal.lisp" :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/6/src/codec/cbor-scan-minimal.lisp")
   :BYTES 1665 :SHA256
   "e6a39d5e39d79c93e19f03bb4e5cd0f07bc6682b768e191095c2359bb910bd79")
  (:PATH "raw/mutation/6/src/codec/cbor-scan.lisp" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/6/src/codec/cbor-scan.lisp")
   :BYTES 5994 :SHA256
   "37961d6915e794b98f8e155c01a80c0a63242fdd18b56deaaa352991c34ac73f")
  (:PATH "raw/mutation/6/test.log" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/6/test.log")
   :BYTES 15943 :SHA256
   "16ad69a85a8a51f096b2c0694efc1047483e99910d21ea9ebe2009cf2c015696")
  (:PATH "raw/mutation/6/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/6/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 478 :SHA256
   "be6612c6874650d1a50707c7c9e28ae3b20abc5ec701cb481eb90100e4b2bcf9")
  (:PATH "raw/mutation/7/src/codec/cbor-scan-minimal.lisp" :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/7/src/codec/cbor-scan-minimal.lisp")
   :BYTES 1665 :SHA256
   "e6a39d5e39d79c93e19f03bb4e5cd0f07bc6682b768e191095c2359bb910bd79")
  (:PATH "raw/mutation/7/src/codec/cbor-scan.lisp" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/7/src/codec/cbor-scan.lisp")
   :BYTES 5994 :SHA256
   "9e2ea593da5614b8f018dca3b2d7f4503cff7c44470471cbc0c03d8621751b7f")
  (:PATH "raw/mutation/7/test.log" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/7/test.log")
   :BYTES 15943 :SHA256
   "10cd7ef30d667161b93ce0204caaf69a2835ebf6f181b4ed6158a9bcfa1ae463")
  (:PATH "raw/mutation/7/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/7/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 478 :SHA256
   "41570ec63a759ef1c88bebc84378a8cec2806cf691f37b29ec2144e445f4d448")
  (:PATH "raw/mutation/baseline/src/codec/cbor-scan-minimal.lisp" :SOURCE
   #A((154) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/baseline/src/codec/cbor-scan-minimal.lisp")
   :BYTES 1665 :SHA256
   "e6a39d5e39d79c93e19f03bb4e5cd0f07bc6682b768e191095c2359bb910bd79")
  (:PATH "raw/mutation/baseline/src/codec/cbor-scan.lisp" :SOURCE
   #A((146) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/baseline/src/codec/cbor-scan.lisp")
   :BYTES 5981 :SHA256
   "37a552faab3463e0bb0d967d04381102d8bf8135986ffd4f643213e235a58b6a")
  (:PATH "raw/mutation/baseline/test.log" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/baseline/test.log")
   :BYTES 32368 :SHA256
   "7335dbfb1a457e4c7cb2a9eb03908aef184b9c88f6b164115c1480dc591760c7")
  (:PATH "raw/mutation/baseline/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((160) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/baseline/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 492 :SHA256
   "2f9c09ba32f511e40e296a54aa01084262955b341d79f56df266554c485cd1c9")
  (:PATH "raw/mutation/report.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/report.lisp")
   :BYTES 42593 :SHA256
   "0208e668cfba5bedcbbdb34873900815963250ba9346e94dcfed784e88cdb935")
  (:PATH "raw/pre-campaign/cbor-minimal-mutation-before-upstream.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-mutation-before-upstream.lisp")
   :BYTES 21628 :SHA256
   "d237ce344b2c8087689aa4d55b0b19348decf45ec7344963c4bbe7a3608b0821")
  (:PATH "raw/pre-campaign/cbor-minimal-mutation-upstream-engine.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-mutation-upstream-engine.lisp")
   :BYTES 29386 :SHA256
   "e9c3a57a430880dab8c01cf63d607ea882cca5df402276bc6b7e583a6a4f5da7")
  (:PATH "raw/pre-campaign/cbor-minimal-scan-bench-arity-finding.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-bench-arity-finding.lisp")
   :BYTES 970 :SHA256
   "a64625fe0286cea0c2b0ac7ba03ba2f53c61463a78f70ab83586e1a7d202cbd2")
  (:PATH "raw/pre-campaign/cbor-minimal-scan-bench-before-arity.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-bench-before-arity.lisp")
   :BYTES 10125 :SHA256
   "41121c679169eff7857231f675b3eff81d586e084cd7b0d1791c9a000d7e021d")
  (:PATH "raw/pre-campaign/cbor-minimal-scan-build-manifest.lisp" :SOURCE
   #A((113) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-build-manifest.lisp")
   :BYTES 4241 :SHA256
   "a7f67c10a09b1e3fe443b66d914008c0d6f2d2601d6be26eed4769fe816070a9")
  (:PATH "raw/pre-campaign/cbor-minimal-scan-coverage-transcript.stderr.log"
   :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-coverage-transcript.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/pre-campaign/cbor-minimal-scan-coverage-transcript.stdout.log"
   :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-coverage-transcript.stdout.log")
   :BYTES 4211 :SHA256
   "44e6aecec515084afab847125d1ea76e6cfc4ff8efef91bb5f107aaffe424b9c")
  (:PATH "raw/pre-campaign/cbor-minimal-scan-independent-review.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-independent-review.lisp")
   :BYTES 6576 :SHA256
   "23923b771ac5f8a1d5c96d5f89669e3544d522f7386db70546c1680ede95cf7a")
  (:PATH "raw/pre-campaign/cbor-minimal-scan-preliminary.stderr.log" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-preliminary.stderr.log")
   :BYTES 80283 :SHA256
   "dde287a01823beadf3858dc43bcaf73e45137f7c414ab47c5c7a96cb178608f3")
  (:PATH "raw/pre-campaign/cbor-minimal-scan-preliminary.stdout.log" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-preliminary.stdout.log")
   :BYTES 93776 :SHA256
   "bfb3137cda6b780509d10834d4b09ce99e8a39b1ada8fefab1fec1928019ce81")
  (:PATH "raw/pre-campaign/cbor-minimal-scan-read-command.lisp" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-read-command.lisp")
   :BYTES 1231 :SHA256
   "437414e53f3beffaa2a5a8d806f62b11b164fe8c424eed655c411fd05f43e953")
  (:PATH "raw/pre-campaign/check-command-archive-before-enumeration-note.lisp"
   :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/check-command-archive-before-enumeration-note.lisp")
   :BYTES 28658 :SHA256
   "1bf9a46b41ab42a88c00df7254dbb300ce6d7eb21541e93ed5e26fe48708cae2")
  (:PATH
   "raw/pre-campaign/check-command-archive-source-read-attempt-1-failed.lisp"
   :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/check-command-archive-source-read-attempt-1-failed.lisp")
   :BYTES 707 :SHA256
   "86a671900f98ff16b72ed65eab76ce2e11f5e77cf5e9cec8aca8be164a0814d5")
  (:PATH
   "raw/pre-campaign/check-command-archive-source-read-attempt-1-transcription.txt"
   :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/check-command-archive-source-read-attempt-1-transcription.txt")
   :BYTES 1234 :SHA256
   "ae89f0cf818bfe900f7a83f1a3872c6f106f1aed9ef87a4cd021470a74eac8a5")
  (:PATH "raw/pre-campaign/check-command-archive-source-read-attempt-1.lisp"
   :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/check-command-archive-source-read-attempt-1.lisp")
   :BYTES 28659 :SHA256
   "8ef2e5be9c4e488bbbff84acc5a63a0a2926eecd978954eca38d0c5d3ce9abb4")
  (:PATH
   "raw/pre-campaign/check-command-archive-source-read-attempt-2.stderr.log"
   :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/check-command-archive-source-read-attempt-2.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH
   "raw/pre-campaign/check-command-archive-source-read-attempt-2.stdout.log"
   :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/check-command-archive-source-read-attempt-2.stdout.log")
   :BYTES 51 :SHA256
   "a9dc8a2538919490b7d1fe6ca9bdcce236ba1b25938e451a322c9f798ce20c15")
  (:PATH "raw/syntax/source-read-final.log" :SOURCE
   #A((52) BASE-CHAR . "/private/tmp/cbor-minimal-scan-source-read-final.log")
   :BYTES 217 :SHA256
   "803ac39ebab8b18ed0bec9d190860b8380732b461513602039db5a8f56d6c480")
  (:PATH "raw/syntax/source-read-first.log" :SOURCE
   #A((52) BASE-CHAR . "/private/tmp/cbor-minimal-scan-source-read-first.log")
   :BYTES 217 :SHA256
   "803ac39ebab8b18ed0bec9d190860b8380732b461513602039db5a8f56d6c480")
  (:PATH "raw/syntax/source-read.lisp" :SOURCE
   #A((47) BASE-CHAR . "/private/tmp/cbor-minimal-scan-source-read.lisp")
   :BYTES 1495 :SHA256
   "52d431c040fa07ae9571f7badbef498180ae83160ab9c28a25619302f10299a7"))
 :LIMITS
 (:SHA256-BYTE-COPY-CHECK :RAW-ORIGINALS-PRESERVED
  :FASL-EXCLUDED-FROM-PUBLISHED-MUTATION-TREES
  :NO-REQUIREMENT-OR-RELEASE-PROMOTION))
