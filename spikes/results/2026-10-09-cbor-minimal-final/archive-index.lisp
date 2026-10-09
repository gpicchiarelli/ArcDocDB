(:SCHEMA-VERSION 1 :KIND :ORIGINAL-COMMAND-ARCHIVE :METADATA-POLICY
 :READ-WITHOUT-RESULT-INFERENCE :PROCESSES
 ((:LABEL "collection" :RECORD-PATH "processes/collection/report.lisp" :STATUS
   :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((47) BASE-CHAR . "spikes/out/cbor-minimal-collection/collect.lisp")
    #A((9) BASE-CHAR . "--collect")
    #A((48) BASE-CHAR . "spikes/out/cbor-minimal-collection/manifest.lisp")
    #A((39) BASE-CHAR . "spikes/results/2026-10-09-cbor-minimal/")))
  (:LABEL "full-check" :RECORD-PATH "processes/full-check/report.lisp" :STATUS
   :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((55) BASE-CHAR
       . "/Applications/Xcode.app/Contents/Developer/usr/bin/make")
    #A((10) BASE-CHAR . "check-core")))
  (:LABEL #A((16) BASE-CHAR . "final-collection") :RECORD-PATH
   "processes/final-collection/report.lisp" :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((47) BASE-CHAR . "spikes/out/cbor-minimal-collection/collect.lisp")
    #A((9) BASE-CHAR . "--collect")
    #A((43) BASE-CHAR . "spikes/out/cbor-minimal-final-manifest.lisp")
    #A((45) BASE-CHAR . "spikes/results/2026-10-09-cbor-minimal-final/")))
  (:LABEL #A((17) BASE-CHAR . "publication-check") :RECORD-PATH
   "processes/publication-check/report.lisp" :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "make") #A((5) BASE-CHAR . "links")
    #A((8) BASE-CHAR . "evidence")))
  (:LABEL #A((16) BASE-CHAR . "audit-supplement") :RECORD-PATH
   "processes/audit-supplement/report.lisp" :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((41) BASE-CHAR . "spikes/out/cbor-minimal-append-audit.lisp")
    #A((7) BASE-CHAR . "--audit")
    #A((45) BASE-CHAR . "spikes/results/2026-10-09-cbor-minimal-final/")))
  (:LABEL #A((11) BASE-CHAR . "final-links") :RECORD-PATH
   "processes/final-links/report.lisp" :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "make") #A((5) BASE-CHAR . "links"))))
 :FILES
 ((:PATH "collection-manifest.lisp" :SOURCE
   #A((105) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-manifest.lisp")
   :BYTES 7308 :SHA256
   "0a26681a8df6c9dc69f4c317c345d9f71ebbfbbfab5e95a9159868a5ab974f8a")
  (:PATH "collection-source.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/collect.lisp")
   :BYTES 9657 :SHA256
   "09adae7145af41bbb8bd6fd91d33d5cbdfa47d4b10908f004d46b70f1ae6597a")
  (:PATH "processes/collection/conservazione.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000547797-command-24349-0/conservazione.lisp")
   :BYTES 1147 :SHA256
   "54f68b5cf5379500531535b5aaf68b69ddb1e0cf0bb4eddd60d9fcfe2691f8d6")
  (:PATH "processes/collection/report.lisp" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000547797-command-24349-0/report.lisp")
   :BYTES 94799 :SHA256
   "9623c1cd7500e2b7dfc133a8c1bc4a60ab7cc965dfae32f37660c10d0f19ee72")
  (:PATH "processes/full-check/conservazione.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548089-command-42461-0/conservazione.lisp")
   :BYTES 1147 :SHA256
   "1c500cb8066869e15676453e0a26e384d796fe9181880fd4f2fee85f490b3e44")
  (:PATH "processes/full-check/report.lisp" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548089-command-42461-0/report.lisp")
   :BYTES 216504 :SHA256
   "36811ac193111b2301e87a9bf95e91cf0287df574ed1e8a88c2c7bf967b9b72f")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-1.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-1.lisp")
   :BYTES 191052 :SHA256
   "76dd034d29d74a64fd82e986c3c12c2a8e85b1c32471494e88f14c6ea07f59db")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-1.stderr.log" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-1.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-10.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-10.lisp")
   :BYTES 568 :SHA256
   "08f4e2c09cfefa648183f50f653ada55a5258f44781eb5649a19633d3fb536a4")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-10.stderr.log" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-10.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-11.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-11.lisp")
   :BYTES 135855 :SHA256
   "931c655633c465fe8ca55ccd8f7ea6f1c5adfdf1d6ee3561f80bd7a90fa80889")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-11.stderr.log" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-11.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-12.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-12.lisp")
   :BYTES 28986 :SHA256
   "b8bcb4de379f3fab34bf9066cc4dfd1c9abc971eeea5817d52d2b7dc7b2b9975")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-12.stderr.log" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-12.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-13.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-13.lisp")
   :BYTES 191052 :SHA256
   "76dd034d29d74a64fd82e986c3c12c2a8e85b1c32471494e88f14c6ea07f59db")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-13.stderr.log" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-13.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-2.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-2.lisp")
   :BYTES 290 :SHA256
   "ac4ba276d77f97777df10dd55f05192936119a5dc217dec6e9f06ad626f2dc66")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-2.stderr.log" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-2.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-3.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-3.lisp")
   :BYTES 289 :SHA256
   "e96a8df9a78fa4d14ab239cd36987c0a5ddfd034961459827b3183ba2e8eda3d")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-3.stderr.log" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-3.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-4.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-4.lisp")
   :BYTES 290 :SHA256
   "8a4780bf98a1924846c8033cea747ab7ec77c303178f4d2193ae4f031e25c4da")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-4.stderr.log" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-4.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-5.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-5.lisp")
   :BYTES 290 :SHA256
   "cd9451a47d0c67a4da8afcc13f1222eaff48223d9882fabc37019662ec94301a")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-5.stderr.log" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-5.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-6.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-6.lisp")
   :BYTES 289 :SHA256
   "f9c8c76896f715195cf20fb1177cc62c9c52248041aa75ddfd7812fff180da10")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-6.stderr.log" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-6.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-7.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-7.lisp")
   :BYTES 290 :SHA256
   "fc73c8511f3c16008fd141963fafcb56908798afc3406e3652b2e5194cbf1eb3")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-7.stderr.log" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-7.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-8.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-8.lisp")
   :BYTES 289 :SHA256
   "6e485ab421467d4f94b257e57b95d5db494c0f168020f6f8800521efbd69f156")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-8.stderr.log" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-8.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-9.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-9.lisp")
   :BYTES 290 :SHA256
   "3f38fd273607f963b258e408adb9a68b2a07804b4cb2e47ca2e04789b39ddaea")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-9.stderr.log" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-9.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-publication-audit-inventory-attempt-1.py" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory-attempt-1.py")
   :BYTES 2103 :SHA256
   "480ba9990a2434381137f66d01196fc96ddadbbb3eb14aa6f73a799d10c7a2e5")
  (:PATH "raw/cbor-minimal-publication-audit-inventory.py" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-inventory.py")
   :BYTES 2103 :SHA256
   "480ba9990a2434381137f66d01196fc96ddadbbb3eb14aa6f73a799d10c7a2e5")
  (:PATH "raw/cbor-minimal-publication-audit-reader-attempt-1.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-reader-attempt-1.lisp")
   :BYTES 12319 :SHA256
   "ef9ffc299a33bbcd2e55406b243a81af5aafa5e96ad02c3f9e1a3e0ae1ded477")
  (:PATH "raw/cbor-minimal-publication-audit-reader-attempt-1.stderr.log"
   :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-reader-attempt-1.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-publication-audit-reader-attempt-1.stdout.log"
   :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-reader-attempt-1.stdout.log")
   :BYTES 93 :SHA256
   "2e5f7de5820001e9f4b157ed7ac56e80200060e6f2d15a32fa9188c6eec56bb7")
  (:PATH "raw/cbor-minimal-publication-audit-reader.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit-reader.lisp")
   :BYTES 12319 :SHA256
   "ef9ffc299a33bbcd2e55406b243a81af5aafa5e96ad02c3f9e1a3e0ae1ded477")
  (:PATH "raw/cbor-minimal-publication-audit.lisp" :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-publication-audit.lisp")
   :BYTES 4360 :SHA256
   "d7f2fd31edc9ef0138a06947b07f8fdf932b8928683d8d6fec19dba7155696cf")
  (:PATH "raw/full-spikes/SPK-01.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/SPK-01.lisp")
   :BYTES 27228 :SHA256
   "1c8aa439288d09acf4016bc0ac5f416e4a6849aaa4b1dec5d037d843d38252ab")
  (:PATH "raw/full-spikes/SPK-02.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/SPK-02.lisp")
   :BYTES 1607 :SHA256
   "5deacd21957848fb097cfe3ae6662110fd37c35a61a6566047e1f04c21259b1d")
  (:PATH "raw/full-spikes/SPK-03.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/SPK-03.lisp")
   :BYTES 3640 :SHA256
   "765f553e1ce7fc2b970708e38dbb4e3f0a02c883e52503d6e509787b7be9d34b")
  (:PATH "raw/full-spikes/SPK-04.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/SPK-04.lisp")
   :BYTES 6752 :SHA256
   "bcf67d0c846480b6851ad274cc723b4fa12ef858496df2e82310b8cc3395a9fc")
  (:PATH "raw/full-spikes/SPK-05.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/SPK-05.lisp")
   :BYTES 10125 :SHA256
   "de561447526eaaf2910b2ca704356dfab3eda5949a5f719cc05f2cdfd3cf4d13")
  (:PATH "raw/full-spikes/SPK-06.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/SPK-06.lisp")
   :BYTES 24070 :SHA256
   "bd49cec7043c6c6b89ff2959ba2d50a3ed988f5b2964e3bf600d99821e86c78c")
  (:PATH "raw/full-spikes/SPK-07.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/SPK-07.lisp")
   :BYTES 318 :SHA256
   "f6ba63720905e3b8892c0662e179da730e1cb174b7b87eed9dd1606720a9bd5f")
  (:PATH "raw/full-spikes/SPK-07.lisp.gz" :SOURCE
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/SPK-07.lisp.gz")
   :BYTES 410675 :SHA256
   "6d4c492345f9cf1cad669733b4502a21fdf96c2f14eaa0707400ea9103fe1e0a")
  (:PATH "raw/full-spikes/SPK-08.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/SPK-08.lisp")
   :BYTES 291712 :SHA256
   "d7789eded71d4769bf4c07054daca882b991f01252551abfd41198c16121025f")
  (:PATH "raw/full-spikes/SPK-09.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/SPK-09.lisp")
   :BYTES 2472 :SHA256
   "c507c4760ce71585b5802e1cb96ccb9d1563a96c3d298ec7d2a41c2c7dae3ac4")
  (:PATH "raw/full-spikes/SPK-10.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/SPK-10.lisp")
   :BYTES 22975 :SHA256
   "0d12ca7555eed7046bbcc2acefbdfe9bb2f74929e0c1031483477412f31b837f")
  (:PATH "raw/full-spikes/conservazione.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/conservazione.lisp")
   :BYTES 2289 :SHA256
   "cfcd1accd1398c02c1b0b2893a743e5a556f12a410ed0e2af0e86f61f8b362a7")
  (:PATH "raw/full-spikes/report.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/report.lisp")
   :BYTES 318 :SHA256
   "7973c81bdf904b15c054a46c94474355f06647374e38e4bf1eb6161dcaa69ed6")
  (:PATH "raw/full-spikes/report.lisp.gz" :SOURCE
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/report.lisp.gz")
   :BYTES 466995 :SHA256
   "06a5008ad4e0bbf65ec57bca01e5c64e878d258d6511771283c9e5bbdbc33a11")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-append-before-fix.lisp"
   :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-append-before-fix.lisp")
   :BYTES 1288 :SHA256
   "2718272c160f0277b878464bd2da2fda42145eb67b38b2edb2f9856778fb21e1")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-append-reading.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-append-reading.lisp")
   :BYTES 710 :SHA256
   "1867986eb83a3987f1cae487733a1d41aea2d6247ec16b6bb68b6636e60e8a84")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-build-extract.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-build-extract.lisp")
   :BYTES 1429 :SHA256
   "393db40668a010454e1df73354378bcb8ec5673c3665190af207159552027998")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-build-reader-attempt-1.lisp"
   :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-build-reader-attempt-1.lisp")
   :BYTES 2322 :SHA256
   "47f615e779942d13ec1282e7ddb8b7007eec33b0a79e48f8d230fe0671fac254")
  (:PATH
   "raw/final-audit/cbor-minimal-final-audit-build-reader-attempt-1.stderr.log"
   :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-build-reader-attempt-1.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH
   "raw/final-audit/cbor-minimal-final-audit-build-reader-attempt-1.stdout.log"
   :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-build-reader-attempt-1.stdout.log")
   :BYTES 1429 :SHA256
   "393db40668a010454e1df73354378bcb8ec5673c3665190af207159552027998")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-build-reader.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-build-reader.lisp")
   :BYTES 2322 :SHA256
   "47f615e779942d13ec1282e7ddb8b7007eec33b0a79e48f8d230fe0671fac254")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-inventory-1.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-inventory-1.lisp")
   :BYTES 7811 :SHA256
   "8b32a0bd2412dc62814b5729bc3f78ebc34973e3707e063a33a09527065bc496")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-inventory-1.stderr.log"
   :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-inventory-1.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-inventory-2.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-inventory-2.lisp")
   :BYTES 289 :SHA256
   "a26315aaa1b80f74c50e09ebde12646b1b727a61e60da2540bba3f495e0bfca4")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-inventory-2.stderr.log"
   :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-inventory-2.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-inventory-3.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-inventory-3.lisp")
   :BYTES 290 :SHA256
   "dc10dee65e987d8851f3a32df250f849f165770cbf164691fdad2289d413d284")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-inventory-3.stderr.log"
   :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-inventory-3.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-inventory-4.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-inventory-4.lisp")
   :BYTES 1610 :SHA256
   "c199e5dfbcf00f31ae712ec8e5cc8055b83f9a489861e69a4a885ce10ee615ed")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-inventory-4.stderr.log"
   :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-inventory-4.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-inventory-5.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-inventory-5.lisp")
   :BYTES 7811 :SHA256
   "8b32a0bd2412dc62814b5729bc3f78ebc34973e3707e063a33a09527065bc496")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-inventory-5.stderr.log"
   :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-inventory-5.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-inventory-attempt-1.py"
   :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-inventory-attempt-1.py")
   :BYTES 2103 :SHA256
   "480ba9990a2434381137f66d01196fc96ddadbbb3eb14aa6f73a799d10c7a2e5")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-inventory.py" :SOURCE
   #A((110) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-inventory.py")
   :BYTES 2103 :SHA256
   "480ba9990a2434381137f66d01196fc96ddadbbb3eb14aa6f73a799d10c7a2e5")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-reader-attempt-1.lisp"
   :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-reader-attempt-1.lisp")
   :BYTES 15143 :SHA256
   "b0f6bdb31ed2a4fa361f4713b18d2a11bb47762f966c22f3d8b559638300e628")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-reader-attempt-1.stderr.log"
   :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-reader-attempt-1.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-reader-attempt-1.stdout.log"
   :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-reader-attempt-1.stdout.log")
   :BYTES 90 :SHA256
   "47f204f9d40f03998b2125b679bca19f6265555ac5da8aab9b7df051fa7f9250")
  (:PATH "raw/final-audit/cbor-minimal-final-audit-reader.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit-reader.lisp")
   :BYTES 15143 :SHA256
   "b0f6bdb31ed2a4fa361f4713b18d2a11bb47762f966c22f3d8b559638300e628")
  (:PATH "raw/final-audit/cbor-minimal-final-audit.lisp" :SOURCE
   #A((102) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-audit.lisp")
   :BYTES 7448 :SHA256
   "a09a11cf5078e652a933560d5f62eccd7e877347ed7eeb81046f7663201c0b4a")
  (:PATH "raw/final-audit/cbor-minimal-append-audit.lisp" :SOURCE
   #A((103) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-append-audit.lisp")
   :BYTES 1799 :SHA256
   "c8f8185f36bef23d72ec96efa12e00b99a284c9d45e329af8302300637329e5f")
  (:PATH "raw/final-audit/cbor-minimal-final-manifest-writer.lisp" :SOURCE
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-final-manifest-writer.lisp")
   :BYTES 1051 :SHA256
   "b241bf2c4245386f1b785a657201cf4fd5646b6cb8e554957120cfa238d1f625")
  (:PATH "processes/final-collection/conservazione.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548370-command-56434-0/conservazione.lisp")
   :BYTES 1147 :SHA256
   "42cab1aafaca399bc073d84937e6905691aa1f878b1e54a63356f3a11f2c4c10")
  (:PATH "processes/final-collection/report.lisp" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548370-command-56434-0/report.lisp")
   :BYTES 95675 :SHA256
   "e4b6da4a4a97d7f38a03306aa83b2702a248fc375112aa582be938895ca7abd7")
  (:PATH "processes/publication-check/conservazione.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548573-command-63749-0/conservazione.lisp")
   :BYTES 1147 :SHA256
   "d0c7e879a483e5869f408d453fd317aec7080549bc83e7b77a2675e2e9538c24")
  (:PATH "processes/publication-check/report.lisp" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548573-command-63749-0/report.lisp")
   :BYTES 95740 :SHA256
   "aa76fa614a4dcce4e49f048fc67b8765369a38c13ccd364be753784dc9dc831f")
  (:PATH "processes/audit-supplement/conservazione.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548792-command-74070-0/conservazione.lisp")
   :BYTES 1147 :SHA256
   "f9c2f9ed44a467e27b5bb9b2bba624f4adc4013d97d73bb85c94cd9068eca70f")
  (:PATH "processes/audit-supplement/report.lisp" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548792-command-74070-0/report.lisp")
   :BYTES 95761 :SHA256
   "d1b3fc9cd12ea41f55dc001632c4ba6253cb64a29e48be5f7cd561e5831b0ac4")
  (:PATH "processes/final-links/conservazione.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548793-command-74099-0/conservazione.lisp")
   :BYTES 1147 :SHA256
   "c42d686e507d3b0ecc23692d8362463688a571e6a262f3c33d569827f8f79db1")
  (:PATH "processes/final-links/report.lisp" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548793-command-74099-0/report.lisp")
   :BYTES 95440 :SHA256
   "cf05d71ea976feb70da622c61bc39a1eeaae599c3b4611f78ad6fe26039857f3"))
 :LIMITS
 (:SHA256-BYTE-COPY-CHECK :RAW-ORIGINALS-PRESERVED
  :FASL-EXCLUDED-FROM-PUBLISHED-MUTATION-TREES
  :NO-REQUIREMENT-OR-RELEASE-PROMOTION))
