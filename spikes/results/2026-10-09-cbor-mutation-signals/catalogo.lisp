(:SCHEMA-VERSION 1 :KIND :EVIDENCE-CATALOG :DATE "2026-10-09" :SCOPE
 :CBOR-MUTATION-PROCESSES :PATH-BASE
 "spikes/results/2026-10-09-cbor-mutation-signals/" :ENTRIES
 ((:ARTIFACT "SPK-01.lisp" :KIND NIL :STATUS :OK)
  (:ARTIFACT "SPK-02.lisp" :KIND NIL :STATUS :OK)
  (:ARTIFACT "SPK-03.lisp" :KIND NIL :STATUS :OK)
  (:ARTIFACT "SPK-04.lisp" :KIND NIL :STATUS :OK)
  (:ARTIFACT "SPK-05.lisp" :KIND NIL :STATUS :OK)
  (:ARTIFACT "SPK-06.lisp" :KIND NIL :STATUS :OK)
  (:ARTIFACT "SPK-07.lisp" :KIND NIL :STATUS :PASS)
  (:ARTIFACT "SPK-08.lisp" :KIND NIL :STATUS :OK)
  (:ARTIFACT "SPK-09.lisp" :KIND NIL :STATUS :OK)
  (:ARTIFACT "SPK-10.lisp" :KIND NIL :STATUS :OK)
  (:ARTIFACT "audit-conservazione.lisp" :KIND :EVIDENCE-RETENTION-AUDIT :STATUS
   :OK)
  (:ARTIFACT "command-0-conservazione.lisp" :KIND :EVIDENCE-FINALIZATION
   :STATUS :OK)
  (:ARTIFACT "command-0.lisp" :KIND :COMMAND-VERIFICATION :STATUS :OK)
  (:ARTIFACT "command-1-conservazione.lisp" :KIND :EVIDENCE-FINALIZATION
   :STATUS :OK)
  (:ARTIFACT "command-1.lisp" :KIND :COMMAND-VERIFICATION :STATUS :OK)
  (:ARTIFACT "command-2-conservazione.lisp" :KIND :EVIDENCE-FINALIZATION
   :STATUS :OK)
  (:ARTIFACT "command-2.lisp" :KIND :COMMAND-VERIFICATION :STATUS :OK)
  (:ARTIFACT "command-3-conservazione.lisp" :KIND :EVIDENCE-FINALIZATION
   :STATUS :OK)
  (:ARTIFACT "command-3.lisp" :KIND :COMMAND-VERIFICATION :STATUS :FAILED)
  (:ARTIFACT "command-4-conservazione.lisp" :KIND :EVIDENCE-FINALIZATION
   :STATUS :OK)
  (:ARTIFACT "command-4.lisp" :KIND :COMMAND-VERIFICATION :STATUS :FAILED)
  (:ARTIFACT "command-5-conservazione.lisp" :KIND :EVIDENCE-FINALIZATION
   :STATUS :OK)
  (:ARTIFACT "command-5.lisp" :KIND :COMMAND-VERIFICATION :STATUS :OK)
  (:ARTIFACT "command-6-conservazione.lisp" :KIND :EVIDENCE-FINALIZATION
   :STATUS :OK)
  (:ARTIFACT "command-6.lisp" :KIND :COMMAND-VERIFICATION :STATUS :OK)
  (:ARTIFACT "correzione-leaf.lisp" :KIND :PUBLICATION-DIAGNOSTIC :STATUS
   :METADATA-REPAIRED)
  (:ARTIFACT "diagnostica-adattatore-leaf.lisp" :KIND :PUBLICATION-DIAGNOSTIC
   :STATUS :FAILED)
  (:ARTIFACT "diagnostica-lettura.lisp" :KIND :INSPECTION-DIAGNOSTIC :STATUS
   :READER-PACKAGE-ERROR)
  (:ARTIFACT "diagnostica-percorsi.lisp" :KIND :PUBLICATION-DIAGNOSTIC :STATUS
   :INVALID-RELATIVE-PATHS)
  (:ARTIFACT "diagnostica-pubblicazione.lisp" :KIND :PUBLICATION-DIAGNOSTIC
   :STATUS :FAILED)
  (:ARTIFACT "fixture-0.lisp" :KIND :PROCESS-FIXTURE-OUTPUT :STATUS NIL)
  (:ARTIFACT "fixture-1.lisp" :KIND :PROCESS-FIXTURE-OUTPUT :STATUS NIL)
  (:ARTIFACT "fixture-2.lisp" :KIND :PROCESS-FIXTURE-OUTPUT :STATUS NIL)
  (:ARTIFACT "fixture-3.lisp" :KIND :PROCESS-FIXTURE-OUTPUT :STATUS NIL)
  (:ARTIFACT "header-mutazioni.lisp" :KIND :MUTATION-OUTPUT :STATUS NIL)
  (:ARTIFACT "lettura-c4.lisp" :KIND :C4-READING :STATUS
   :STATIC-REVIEW-COMPLETE)
  (:ARTIFACT "metodo.lisp" :KIND :CBOR-MUTATION-PROCESS-METHOD :STATUS NIL)
  (:ARTIFACT "pubblicazione.lisp" :KIND :EVIDENCE-PUBLICATION :STATUS
   :ASSEMBLED)
  (:ARTIFACT "riepilogo.lisp" :KIND :CBOR-PROCESS-VERIFICATION-SUMMARY :STATUS
   :OK)
  (:ARTIFACT "spikes-conservazione.lisp" :KIND :EVIDENCE-FINALIZATION :STATUS
   :OK)
  (:ARTIFACT "spikes-report.lisp" :KIND NIL :STATUS :COMPLETE)
  (:ARTIFACT "struttura-mutazioni.lisp" :KIND :MUTATION-OUTPUT :STATUS NIL)
  (:ARTIFACT "verifica-finale-preliminare-conservazione.lisp" :KIND
   :EVIDENCE-FINALIZATION :STATUS :OK)
  (:ARTIFACT "verifica-finale-preliminare.lisp" :KIND :COMMAND-VERIFICATION
   :STATUS :FAILED)
  (:ARTIFACT "verifica-leaf-preliminare.lisp" :KIND :METADATA-VERIFICATION
   :STATUS :OK)
  (:ARTIFACT "verifica-finale.lisp" :KIND :COMMAND-VERIFICATION :STATUS :OK)
  (:ARTIFACT "verifica-finale-conservazione.lisp" :KIND :EVIDENCE-FINALIZATION
   :STATUS :OK))
 :ASSOCIATED-RAW-FILES
 ((:FILE "SPK-07.lisp.gz" :BYTES 410619 :SHA256
   "51b1bb608f189e1b767f817801f046efeb2231a01642da1b20f38494a4333f0f" :GIT-BLOB
   "987301be897cb739d5b11587a0b9b63b1cc40329")
  (:FILE "adattatore-leaf-preliminare-source.lisp.txt" :BYTES 7677 :SHA256
   "723f645b81a22fa9c5205e04eac7dd704782ae36569b35b3c5a72587234a64fd" :GIT-BLOB
   "58b607f0a2925b16a2d86baebd0579839795d1d2")
  (:FILE "adattatore-leaf-source.lisp.txt" :BYTES 7807 :SHA256
   "7d0bd74d3c58b2d374a5a513e7d0dfadf9d7e9a2ac1e821bf2911e0794b48e4d" :GIT-BLOB
   "0be960bffb2ade166a19a17ea750c9838b9168cf")
  (:FILE "catalogo-annidato.lisp.txt" :BYTES 1835 :SHA256
   "3aea90af0e6d8bd861b6eb3f9fcafd03a20eb99ddd561439717b8cf0b7d71792" :GIT-BLOB
   "1940ea4cc09bd1845bdc07b2fa48c2e55dba0ed8")
  (:FILE "catalogo-preliminare.lisp.txt" :BYTES 6497 :SHA256
   "49b7105e85cce64e3a684c705bdd97d9fb31f3694fcb8bef6b383634452d8aad" :GIT-BLOB
   "b5a14fbeee2ccebde65b15eeabbc548faa93a6d6")
  (:FILE "pubblicazione-finale-source.lisp.txt" :BYTES 4986 :SHA256
   "4795fa998752f380b61095dbe700e92982f9bfff4fc49d4652583897814d9be0" :GIT-BLOB
   "2edaa355d2377190158722da1cebcd591b1260d1")
  (:FILE "pubblicazione-portabile-source.lisp.txt" :BYTES 5008 :SHA256
   "e4840d493ca3c95edd3004f08e87e168162c09be472fc1d93f734245e52e429e" :GIT-BLOB
   "1b86081089ff4ab6391d35ebf4fdb2c6c7ba78fb")
  (:FILE "pubblicazione-source.lisp.txt" :BYTES 4848 :SHA256
   "9453b09e3e0c63bd119575c713bcc724375c7a62fdbc29ebdb33182a3dc7a0da" :GIT-BLOB
   "3c3a98909b8c09163fa88f350bd0f9d5ee57c3b8")
  (:FILE "raccolta-source.lisp.txt" :BYTES 5245 :SHA256
   "4bcb25128af2fbab29fc12a13b53408a74f84d552926a615c47b12d3d68a20f1" :GIT-BLOB
   "54f4370cbb8f4b54662c2eb7997b007e1bdba6ef")
  (:FILE "report.lisp.gz" :BYTES 467404 :SHA256
   "75648e1adc9ea3c411d3f57a5c8dbeb6456d11659d18817e4ce9a3d071b6c35c" :GIT-BLOB
   "4762a99339e5fc520eeb932cfbc3509700801b1f")
  (:FILE "riepilogo-annidato.lisp.txt" :BYTES 3375 :SHA256
   "4141437b95d09a19e2189278b2b0e9767faa9d25cd364b1ea2cd283c33e4e03b" :GIT-BLOB
   "aee8fd31adc54d58295848d88745b712ae265993")
  (:FILE "riepilogo-preliminare.lisp.txt" :BYTES 4233 :SHA256
   "b86ca7097f2301ed032f03dc1c82077269e44c84532a43348a5d6eceda742047" :GIT-BLOB
   "909ef5864e10c98b1d75bcbef977176ea06a2f22")
  (:FILE "verifica-leaf-preliminare.stdout.log" :BYTES 188 :SHA256
   "c62fccaa42a49dce5d314f5e5db43cd667561527106f91ced65275366565ab6b")
  (:FILE "verifica-leaf-preliminare.stderr.log" :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:FILE "verifica-finale.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000548719-command-72130-0/report.lisp")
   :BYTES 92782 :SHA256
   "af202f3ec188afb9deecea7864922566b79311875cddc279582aa56291d81060" :GIT-BLOB
   "2d99dbc4af8f666f3ccaf3831003e120135ae6ff" :BYTE-COMPARISON :IDENTICAL)
  (:FILE "verifica-finale-conservazione.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000548719-command-72130-0/conservazione.lisp")
   :BYTES 1168 :SHA256
   "e9174cea8adff7eafbe735fba49428b9c39a1f5deb3fddbec27bb0663bb31a8b" :GIT-BLOB
   "953af7c1f12d1e530ce67e8dd52b528683f3d938" :BYTE-COMPARISON :IDENTICAL))
 :LIMITS
 (:LEAF-ARTIFACT-NAMES :STRUCTURE-PRESENCE-SIZE-AND-COMPRESSED-INTEGRITY
  :ORIGINAL-NATIVE-AND-WRAPPER-BYTES-PRESERVED :ORIGINAL-STATUSES-PRESERVED
  :NO-AUTOMATIC-GATE-PROMOTION))
