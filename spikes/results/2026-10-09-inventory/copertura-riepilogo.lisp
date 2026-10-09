(:SCHEMA-VERSION 1 :KIND :COVERAGE-SUMMARY :SCOPE
 "src/recovery/inventory-*.lisp" :RAW-ARTIFACT "copertura-dati.lisp"
 :PROCESS-COMMAND-RECORD "spikes/out/4000528743-command-79670-0/report.lisp"
 :INPUT-HASHES
 ((:PATH "arcdocdb.asd" :GIT-BLOB "e3eba2b0baf54d851e71c0eeb7eb837930ff7fc5"
   :RECORD-BEFORE-AFTER-CURRENT-MATCH T)
  (:PATH "src/recovery/manifest-package.lisp" :GIT-BLOB
   "5405bd515df8b26b792bd0430c9ec3dbadce63e7"
   :RECORD-BEFORE-AFTER-CURRENT-MATCH T)
  (:PATH "src/recovery/inventory-types.lisp" :GIT-BLOB
   "68c357d2d522fcabe79284c540c2631e5fa87780"
   :RECORD-BEFORE-AFTER-CURRENT-MATCH T)
  (:PATH "src/recovery/inventory-build.lisp" :GIT-BLOB
   "60057f6a50c657f016bee3c21c21911b582f86fe"
   :RECORD-BEFORE-AFTER-CURRENT-MATCH T)
  (:PATH "src/recovery/inventory-query.lisp" :GIT-BLOB
   "47810fb2944b4b5c18d9a9c8e60dfdc1c5f19db4"
   :RECORD-BEFORE-AFTER-CURRENT-MATCH T)
  (:PATH "tests/recovery/inventory-support.lisp" :GIT-BLOB
   "06eeff2101a97f9abdec6b6f14aa621c2fec29fd"
   :RECORD-BEFORE-AFTER-CURRENT-MATCH T)
  (:PATH "tests/recovery/inventory.lisp" :GIT-BLOB
   "0d5722e4f5ba0025d3a6fb38f0bd056a3ea0b8e9"
   :RECORD-BEFORE-AFTER-CURRENT-MATCH T)
  (:PATH "tools/foundation-coverage.lisp" :GIT-BLOB
   "5147ebea1b60c4e5c7b1d95fbea7f272cfc63a1a"
   :RECORD-BEFORE-AFTER-CURRENT-MATCH T))
 :DEDICATED-TESTS 13 :RECOVERY-TESTS 95 :SOURCE-OF-COUNTS
 :ORIGINAL-SB-COVER-HTML-INDEX-ROWS :STATE-AND-PER-FILE-HTML-CROSS-CHECK T
 :PER-FILE
 ((:PATH "inventory-build.lisp" :HTML "ca9cac30e59efb11e130e4b51e224df4.html"
   :EXPRESSIONS (306 390) :BRANCHES (41 56) :RAW-INDEX-ROW
   "<tr class='odd'><td class='text-cell'><a href='ca9cac30e59efb11e130e4b51e224df4.html'>inventory-build.lisp</a></td><td>306</td><td>390</td><td> 78.5</td><td>41</td><td>56</td><td> 73.2</td></tr>"
   :SOURCE-GIT-BLOB "60057f6a50c657f016bee3c21c21911b582f86fe"
   :MISSING-BRANCH-PATHS
   ((:ELSE 1 3 7 3) (:ELSE 1 3 4 5) (:ELSE 1 4 7) (:ELSE 1 2 1 6 7)
    (:ELSE 1 7 7) (:ELSE 1 2 1 2 8 7) (:ELSE 1 2 1 2 4 9) (:ELSE 1 2 4 9)
    (:ELSE 1 2 5 9) (:ELSE 1 1 2 4 13) (:ELSE 1 2 4 13)
    (:ELSE 1 1 2 1 1 1 4 13) (:ELSE 1 2 4 15) (:ELSE 1 2 2 5 15)
    (:ELSE 1 3 4 17)))
  (:PATH "inventory-query.lisp" :HTML "83bbf903052d3815a36b35ee7ffb7952.html"
   :EXPRESSIONS (27 32) :BRANCHES (2 2) :RAW-INDEX-ROW
   "<tr class='even'><td class='text-cell'><a href='83bbf903052d3815a36b35ee7ffb7952.html'>inventory-query.lisp</a></td><td>27</td><td>32</td><td> 84.4</td><td>2</td><td>2</td><td>100.0</td></tr>"
   :SOURCE-GIT-BLOB "47810fb2944b4b5c18d9a9c8e60dfdc1c5f19db4"
   :MISSING-BRANCH-PATHS NIL)
  (:PATH "inventory-types.lisp" :HTML "c0b10ff98fb5b75d16950465dc259746.html"
   :EXPRESSIONS (7 18) :BRANCHES (0 2) :RAW-INDEX-ROW
   "<tr class='odd'><td class='text-cell'><a href='c0b10ff98fb5b75d16950465dc259746.html'>inventory-types.lisp</a></td><td>7</td><td>18</td><td> 38.9</td><td>0</td><td>2</td><td>  0.0</td></tr>"
   :SOURCE-GIT-BLOB "68c357d2d522fcabe79284c540c2631e5fa87780"
   :MISSING-BRANCH-PATHS ((:THEN 3 4 5) (:ELSE 3 4 5))))
 :INVENTORY-TOTALS
 (:EXPRESSIONS-COVERED 340 :EXPRESSIONS-TOTAL 440 :BRANCHES-COVERED 43
  :BRANCHES-TOTAL 60)
 :FULL-RECOVERY-TOTALS
 (:EXPRESSIONS-COVERED 2976 :EXPRESSIONS-TOTAL 3518 :BRANCHES-COVERED 347
  :BRANCHES-TOTAL 448)
 :FULL-RECOVERY-FILE-COUNT 17 :FULL-RECOVERY-INDEX-ROWS
 ((:PATH "decisions-build.lisp" :HTML "1a5946f7236cba8d19b2cc458d02fb07.html"
   :EXPRESSIONS (417 513) :BRANCHES (41 60) :RAW-INDEX-ROW
   "<tr class='odd'><td class='text-cell'><a href='1a5946f7236cba8d19b2cc458d02fb07.html'>decisions-build.lisp</a></td><td>417</td><td>513</td><td> 81.3</td><td>41</td><td>60</td><td> 68.3</td></tr>")
  (:PATH "decisions-package.lisp" :HTML "3b906fa7177d860852f32384f7cac68c.html"
   :EXPRESSIONS (0 1) :BRANCHES (0 0) :RAW-INDEX-ROW
   "<tr class='even'><td class='text-cell'><a href='3b906fa7177d860852f32384f7cac68c.html'>decisions-package.lisp</a></td><td>0</td><td>1</td><td>  0.0</td><td>0</td><td>0</td><td>-</td></tr>")
  (:PATH "decisions-query.lisp" :HTML "77b7b104d4572cd6d5b385c558957992.html"
   :EXPRESSIONS (152 175) :BRANCHES (13 16) :RAW-INDEX-ROW
   "<tr class='odd'><td class='text-cell'><a href='77b7b104d4572cd6d5b385c558957992.html'>decisions-query.lisp</a></td><td>152</td><td>175</td><td> 86.9</td><td>13</td><td>16</td><td> 81.3</td></tr>")
  (:PATH "decisions-radix.lisp" :HTML "ebe25c9755590138367ffc28dd419399.html"
   :EXPRESSIONS (384 409) :BRANCHES (53 54) :RAW-INDEX-ROW
   "<tr class='even'><td class='text-cell'><a href='ebe25c9755590138367ffc28dd419399.html'>decisions-radix.lisp</a></td><td>384</td><td>409</td><td> 93.9</td><td>53</td><td>54</td><td> 98.1</td></tr>")
  (:PATH "decisions-sort.lisp" :HTML "6a10586c422503226cb2d0a4644e5d89.html"
   :EXPRESSIONS (355 400) :BRANCHES (27 42) :RAW-INDEX-ROW
   "<tr class='odd'><td class='text-cell'><a href='6a10586c422503226cb2d0a4644e5d89.html'>decisions-sort.lisp</a></td><td>355</td><td>400</td><td> 88.8</td><td>27</td><td>42</td><td> 64.3</td></tr>")
  (:PATH "decisions-types.lisp" :HTML "703b0f7fd80c9b9dfbf9e01a72123f10.html"
   :EXPRESSIONS (24 32) :BRANCHES (4 4) :RAW-INDEX-ROW
   "<tr class='even'><td class='text-cell'><a href='703b0f7fd80c9b9dfbf9e01a72123f10.html'>decisions-types.lisp</a></td><td>24</td><td>32</td><td> 75.0</td><td>4</td><td>4</td><td>100.0</td></tr>")
  (:PATH "inventory-build.lisp" :HTML "ca9cac30e59efb11e130e4b51e224df4.html"
   :EXPRESSIONS (306 390) :BRANCHES (41 56) :RAW-INDEX-ROW
   "<tr class='odd'><td class='text-cell'><a href='ca9cac30e59efb11e130e4b51e224df4.html'>inventory-build.lisp</a></td><td>306</td><td>390</td><td> 78.5</td><td>41</td><td>56</td><td> 73.2</td></tr>")
  (:PATH "inventory-query.lisp" :HTML "83bbf903052d3815a36b35ee7ffb7952.html"
   :EXPRESSIONS (27 32) :BRANCHES (2 2) :RAW-INDEX-ROW
   "<tr class='even'><td class='text-cell'><a href='83bbf903052d3815a36b35ee7ffb7952.html'>inventory-query.lisp</a></td><td>27</td><td>32</td><td> 84.4</td><td>2</td><td>2</td><td>100.0</td></tr>")
  (:PATH "inventory-types.lisp" :HTML "c0b10ff98fb5b75d16950465dc259746.html"
   :EXPRESSIONS (7 18) :BRANCHES (0 2) :RAW-INDEX-ROW
   "<tr class='odd'><td class='text-cell'><a href='c0b10ff98fb5b75d16950465dc259746.html'>inventory-types.lisp</a></td><td>7</td><td>18</td><td> 38.9</td><td>0</td><td>2</td><td>  0.0</td></tr>")
  (:PATH "manifest-build.lisp" :HTML "af160f7d69063851b7c2b6c6b66e5710.html"
   :EXPRESSIONS (376 451) :BRANCHES (38 52) :RAW-INDEX-ROW
   "<tr class='even'><td class='text-cell'><a href='af160f7d69063851b7c2b6c6b66e5710.html'>manifest-build.lisp</a></td><td>376</td><td>451</td><td> 83.4</td><td>38</td><td>52</td><td> 73.1</td></tr>")
  (:PATH "manifest-decode.lisp" :HTML "e3717728142ca3e5070b92edb9ad945c.html"
   :EXPRESSIONS (210 261) :BRANCHES (20 30) :RAW-INDEX-ROW
   "<tr class='odd'><td class='text-cell'><a href='e3717728142ca3e5070b92edb9ad945c.html'>manifest-decode.lisp</a></td><td>210</td><td>261</td><td> 80.5</td><td>20</td><td>30</td><td> 66.7</td></tr>")
  (:PATH "manifest-fold.lisp" :HTML "4605cc81553167482f509695bbd7a3b0.html"
   :EXPRESSIONS (230 247) :BRANCHES (48 52) :RAW-INDEX-ROW
   "<tr class='even'><td class='text-cell'><a href='4605cc81553167482f509695bbd7a3b0.html'>manifest-fold.lisp</a></td><td>230</td><td>247</td><td> 93.1</td><td>48</td><td>52</td><td> 92.3</td></tr>")
  (:PATH "manifest-package.lisp" :HTML "019ae71f27863e0c490a01a9380a89da.html"
   :EXPRESSIONS (0 1) :BRANCHES (0 0) :RAW-INDEX-ROW
   "<tr class='odd'><td class='text-cell'><a href='019ae71f27863e0c490a01a9380a89da.html'>manifest-package.lisp</a></td><td>0</td><td>1</td><td>  0.0</td><td>0</td><td>0</td><td>-</td></tr>")
  (:PATH "manifest-query.lisp" :HTML "567daf99bef7b5c5195f28537607b821.html"
   :EXPRESSIONS (67 75) :BRANCHES (8 8) :RAW-INDEX-ROW
   "<tr class='even'><td class='text-cell'><a href='567daf99bef7b5c5195f28537607b821.html'>manifest-query.lisp</a></td><td>67</td><td>75</td><td> 89.3</td><td>8</td><td>8</td><td>100.0</td></tr>")
  (:PATH "manifest-types.lisp" :HTML "0960c3b62b155bef245fc6d605cf8845.html"
   :EXPRESSIONS (5 32) :BRANCHES (0 4) :RAW-INDEX-ROW
   "<tr class='odd'><td class='text-cell'><a href='0960c3b62b155bef245fc6d605cf8845.html'>manifest-types.lisp</a></td><td>5</td><td>32</td><td> 15.6</td><td>0</td><td>4</td><td>  0.0</td></tr>")
  (:PATH "package.lisp" :HTML "857b25e2f6739313dd4f5c58e8ccbec6.html"
   :EXPRESSIONS (0 1) :BRANCHES (0 0) :RAW-INDEX-ROW
   "<tr class='even'><td class='text-cell'><a href='857b25e2f6739313dd4f5c58e8ccbec6.html'>package.lisp</a></td><td>0</td><td>1</td><td>  0.0</td><td>0</td><td>0</td><td>-</td></tr>")
  (:PATH "scan.lisp" :HTML "315c2750abc38015eddb5d448fb3d951.html" :EXPRESSIONS
   (416 480) :BRANCHES (52 66) :RAW-INDEX-ROW
   "<tr class='odd'><td class='text-cell'><a href='315c2750abc38015eddb5d448fb3d951.html'>scan.lisp</a></td><td>416</td><td>480</td><td> 86.7</td><td>52</td><td>66</td><td> 78.8</td></tr>"))
 :DENOMINATOR-POLICY :RAW-UNCHANGED :COVERAGE-EXCLUSIONS NIL
 :MISSING-FORM-APPROVAL :NOT-APPROVED :MISSING-BRANCH-APPROVAL :NOT-APPROVED
 :MCDC :NOT-DEMONSTRATED :COMPLETE-RECOVERY-QUALIFICATION :NOT-DEMONSTRATED
 :LIMITS
 ("Conteggi osservati nel processo recovery, non percentuali rettificate."
  "Le forme e le alternative mancanti, incluse guardie e defstruct, restano nel denominatore."
  "Query inventory 2/2 rami non dimostra MC/DC o copertura completa degli altri file."
  "Nessuna prova di crash, I/O, identita o contenuti dei file, ne prestazioni."
  "Il helper legge e impacchetta dati gia raccolti; non carica prodotto o test."))
