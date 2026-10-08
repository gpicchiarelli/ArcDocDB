(:SCHEMA 1 :COMMAND
 (:PROGRAM "sbcl" :ARGUMENTS
  ("--noinform" "--no-userinit" "--script" "/dev/stdin") :CWD
  "/Users/gpicchiarelli/Documents/ArcDocDB" :STEPS
  ((:LOAD #A((33) COMMON-LISP:BASE-CHAR . "spikes/SPK-09-integrity/core.lisp"))
   (:COMPILE-FILE
    #A((39) COMMON-LISP:BASE-CHAR . "spikes/SPK-10-v2-limits/migrazione.lisp")
    :OUTPUT-FILE
    #A((41) COMMON-LISP:BASE-CHAR
       . "/tmp/arcdocdb-spk10-migrazione-agent.fasl")
    :WARNINGS-FATAL COMMON-LISP:T)
   (:LOAD
    #A((41) COMMON-LISP:BASE-CHAR
       . "/tmp/arcdocdb-spk10-migrazione-agent.fasl"))
   (:FUNCALL "arcdocdb.spk10.migrazione:check")))
 :ENVIRONMENT
 (:IMPLEMENTATION #A((4) COMMON-LISP:BASE-CHAR . "SBCL") :VERSION
  #A((5) COMMON-LISP:BASE-CHAR . "2.6.9") :OS
  #A((6) COMMON-LISP:BASE-CHAR . "Darwin") :OS-VERSION
  #A((6) COMMON-LISP:BASE-CHAR . "27.0.0") :MACHINE
  #A((5) COMMON-LISP:BASE-CHAR . "ARM64") :SAFETY 3)
 :SOURCE-BLOBS
 ((:PATH
   #A((79) COMMON-LISP:BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-10-v2-limits/migrazione.lisp")
   :GIT-BLOB "cab850dc32ff9908b487b24edf3e1df2cc90008c")
  (:PATH
   #A((73) COMMON-LISP:BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-09-integrity/core.lisp")
   :GIT-BLOB "80cdac4c0e52703618e1f274413b2ecbe00e6b14"))
 :COMPILE-STATUS
 (:STATUS :OK :WARNINGS COMMON-LISP:NIL :FAILURE COMMON-LISP:NIL) :RESULT
 (:STATUS :OK :FILEHEADERS
  (:ACCETTATI 8 :RIFIUTATI 2393 :BIT-FLIP 2048 :TRONCAMENTI 256
   :RISERVATI-CRC-VALIDO 68 :ORIGINI-INVALIDE 12 :VERSIONI-IGNOTE 4
   :BOUNDS-INVALIDI 4 :MAGIC-ALTERNATIVO-RIFIUTATO 1
   :PARSER-INVOCATI-SU-HEADER-INVALIDI 0)
  :MODELLO
  (:SCENARI 4 :STATI-PIN 2 :PREFISSI 52 :CRASH 208 :INTERRUZIONI-RECOVERY 4160
   :RERUN 208 :MASSIMO-PASSI 22 :MASSIMO-COPIE 4
   :FALSE-VERIFICHE-RILEVATE-DA-ORACLE 2 :VERIFICHE-NEGATIVE 4)
  :ANOMALIE
  (:CASI 4 :TMP-NOMINATO-RINOMINATO 1 :ERRORI-INTEGRITA 2
   :DEFINITIVI-SCONOSCIUTI-CONSERVATI 1)
  :BUDGET (:SATURAZIONI 13 :PIN-TRATTENUTO 1 :PIN-RILASCIATO 1)
  :MUTANTI-RILEVATI 3 :MUTANTI-ATTESI
  ((:MUTANTE :UNLINK-BEFORE-EDIT :RILEVATO COMMON-LISP:T :FASE :PREPARE.TMP
    :ORACLE :UNLINK-BEFORE-EDIT)
   (:MUTANTE :SKIP-VERIFICATION :RILEVATO COMMON-LISP:T :FASE :PUBLISH.EDIT
    :ORACLE :SKIP-VERIFICATION)
   (:MUTANTE :RECLAIM-PINNED :RILEVATO COMMON-LISP:T :FASE :RECLAIM :ORACLE
    :RECLAIM-PINNED))
  :LIMITI
  (:FILEHEADER-BYTE 64 :CRC-BYTE 56 :SORGENTI 1 :OUTPUT 1 :PIN-MASSIMO 1
   :PASSI-PER-ESECUZIONE 32 :COPIE 4 :COPIE-PER-TENTATIVO 2 :FASI 10
   :PASSI-RECOVERY 4 :PREFISSI-PER-SCENARIO 11 :SCENARI 4 :ALTERNATIVE-CRASH 4)
  :CONVERSIONE-BYTE COMMON-LISP:NIL :CRASH-REALI-VERIFICATI COMMON-LISP:NIL)
 :LIMITS
 (:FILEHEADER-BYTE 64 :CRC-BYTE 56 :SORGENTI 1 :OUTPUT 1 :PIN-MASSIMO 1
  :PASSI-PER-ESECUZIONE 32 :COPIE 4 :COPIE-PER-TENTATIVO 2 :FASI 10
  :PASSI-RECOVERY 4 :PREFISSI-PER-SCENARIO 11 :SCENARI 4 :ALTERNATIVE-CRASH 4)
 :TIME
 (:STARTED-UNIVERSAL 4000474793 :COMPILE-SECONDS 0.179701d0 :CHECK-SECONDS
  0.007486d0 :TOTAL-SECONDS 0.651317d0)
 :STDOUT "" :STDERR "" :FAILURE COMMON-LISP:NIL :ATTEMPTS
 ((:SCHEMA 1 :COMMAND
   (:PROGRAM "sbcl" :ARGUMENTS
    ("--noinform" "--no-userinit" "--script" "/dev/stdin") :CWD
    "/Users/gpicchiarelli/Documents/ArcDocDB" :STEPS
    ((:LOAD
      #A((33) COMMON-LISP:BASE-CHAR . "spikes/SPK-09-integrity/core.lisp"))
     (:COMPILE-FILE
      #A((39) COMMON-LISP:BASE-CHAR
         . "spikes/SPK-10-v2-limits/migrazione.lisp")
      :OUTPUT-FILE
      #A((41) COMMON-LISP:BASE-CHAR
         . "/tmp/arcdocdb-spk10-migrazione-agent.fasl")
      :WARNINGS-FATAL COMMON-LISP:T)
     (:LOAD
      #A((41) COMMON-LISP:BASE-CHAR
         . "/tmp/arcdocdb-spk10-migrazione-agent.fasl"))
     (:FUNCALL "arcdocdb.spk10.migrazione:check")))
   :ENVIRONMENT
   (:IMPLEMENTATION #A((4) COMMON-LISP:BASE-CHAR . "SBCL") :VERSION
    #A((5) COMMON-LISP:BASE-CHAR . "2.6.9") :OS
    #A((6) COMMON-LISP:BASE-CHAR . "Darwin") :OS-VERSION
    #A((6) COMMON-LISP:BASE-CHAR . "27.0.0") :MACHINE
    #A((5) COMMON-LISP:BASE-CHAR . "ARM64") :SAFETY 3)
   :SOURCE-BLOBS
   ((:PATH
     #A((79) COMMON-LISP:BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-10-v2-limits/migrazione.lisp")
     :GIT-BLOB "8e6cc0fa719541aeb9f886b61f83ae5d014394ac")
    (:PATH
     #A((73) COMMON-LISP:BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-09-integrity/core.lisp")
     :GIT-BLOB "80cdac4c0e52703618e1f274413b2ecbe00e6b14"))
   :COMPILE-STATUS :FALLITO :RESULT COMMON-LISP:NIL :LIMITS
   (:FILEHEADER-BYTE 64 :CRC-BYTE 56 :PASSI-PER-ESECUZIONE 32 :COPIE 2 :FASI 10
    :PASSI-RECOVERY 4 :PREFISSI-PER-SCENARIO 11 :SCENARI 4 :ALTERNATIVE-CRASH 4
    :PIN-MASSIMO 1)
   :TIME
   (:STARTED-UNIVERSAL 4000474550 :COMPILE-SECONDS 0.149195d0 :CHECK-SECONDS
    COMMON-LISP:NIL :TOTAL-SECONDS 0.588637d0)
   :STDOUT "" :STDERR "; 
; caught ERROR:
;   READ error during COMPILE-FILE:
;   
;     unmatched close parenthesis
;   
;       Line: 512, Column: 56, File-Position: 25490
;   
;       Stream: #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-10-v2-limits/migrazione.lisp\" {80089D0233}>
; 
; compilation unit aborted
;   caught 1 fatal ERROR condition
;   caught 1 ERROR condition
"
   :FAILURE
   (:TYPE #A((12) COMMON-LISP:BASE-CHAR . "SIMPLE-ERROR") :MESSAGE
    #A((29) COMMON-LISP:BASE-CHAR . "Compile-file fallito: NIL T T")))
  (:SCHEMA 1 :COMMAND
   (:PROGRAM "sbcl" :ARGUMENTS
    ("--noinform" "--no-userinit" "--script" "/dev/stdin") :CWD
    "/Users/gpicchiarelli/Documents/ArcDocDB" :STEPS
    ((:LOAD
      #A((33) COMMON-LISP:BASE-CHAR . "spikes/SPK-09-integrity/core.lisp"))
     (:COMPILE-FILE
      #A((39) COMMON-LISP:BASE-CHAR
         . "spikes/SPK-10-v2-limits/migrazione.lisp")
      :OUTPUT-FILE
      #A((41) COMMON-LISP:BASE-CHAR
         . "/tmp/arcdocdb-spk10-migrazione-agent.fasl")
      :WARNINGS-FATAL COMMON-LISP:T)
     (:LOAD
      #A((41) COMMON-LISP:BASE-CHAR
         . "/tmp/arcdocdb-spk10-migrazione-agent.fasl"))
     (:FUNCALL "arcdocdb.spk10.migrazione:check")))
   :ENVIRONMENT
   (:IMPLEMENTATION #A((4) COMMON-LISP:BASE-CHAR . "SBCL") :VERSION
    #A((5) COMMON-LISP:BASE-CHAR . "2.6.9") :OS
    #A((6) COMMON-LISP:BASE-CHAR . "Darwin") :OS-VERSION
    #A((6) COMMON-LISP:BASE-CHAR . "27.0.0") :MACHINE
    #A((5) COMMON-LISP:BASE-CHAR . "ARM64") :SAFETY 3)
   :SOURCE-BLOBS
   ((:PATH
     #A((79) COMMON-LISP:BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-10-v2-limits/migrazione.lisp")
     :GIT-BLOB "682d88166e3869c2579ce359e4af7e149ac38065")
    (:PATH
     #A((73) COMMON-LISP:BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-09-integrity/core.lisp")
     :GIT-BLOB "80cdac4c0e52703618e1f274413b2ecbe00e6b14"))
   :COMPILE-STATUS
   (:STATUS :OK :WARNINGS COMMON-LISP:NIL :FAILURE COMMON-LISP:NIL) :RESULT
   COMMON-LISP:NIL :LIMITS
   (:FILEHEADER-BYTE 64 :CRC-BYTE 56 :PASSI-PER-ESECUZIONE 32 :COPIE 2 :FASI 10
    :PASSI-RECOVERY 4 :PREFISSI-PER-SCENARIO 11 :SCENARI 4 :ALTERNATIVE-CRASH 4
    :PIN-MASSIMO 1)
   :TIME
   (:STARTED-UNIVERSAL 4000474579 :COMPILE-SECONDS 0.154654d0 :CHECK-SECONDS
    COMMON-LISP:NIL :TOTAL-SECONDS 0.582739d0)
   :STDOUT "" :STDERR "" :FAILURE
   (:TYPE #A((12) COMMON-LISP:BASE-CHAR . "ERRORE-SPIKE") :MESSAGE
    #A((44) COMMON-LISP:BASE-CHAR
       . "REQ-AFF-007: recovery/rerun non idempotente.")))
  (:SCHEMA 1 :COMMAND
   (:PROGRAM "sbcl" :ARGUMENTS
    ("--noinform" "--no-userinit" "--script" "/dev/stdin") :CWD
    "/Users/gpicchiarelli/Documents/ArcDocDB" :STEPS
    ((:LOAD
      #A((33) COMMON-LISP:BASE-CHAR . "spikes/SPK-09-integrity/core.lisp"))
     (:COMPILE-FILE
      #A((39) COMMON-LISP:BASE-CHAR
         . "spikes/SPK-10-v2-limits/migrazione.lisp")
      :OUTPUT-FILE
      #A((41) COMMON-LISP:BASE-CHAR
         . "/tmp/arcdocdb-spk10-migrazione-agent.fasl")
      :WARNINGS-FATAL COMMON-LISP:T)
     (:LOAD
      #A((41) COMMON-LISP:BASE-CHAR
         . "/tmp/arcdocdb-spk10-migrazione-agent.fasl"))
     (:FUNCALL "arcdocdb.spk10.migrazione:check")))
   :ENVIRONMENT
   (:IMPLEMENTATION #A((4) COMMON-LISP:BASE-CHAR . "SBCL") :VERSION
    #A((5) COMMON-LISP:BASE-CHAR . "2.6.9") :OS
    #A((6) COMMON-LISP:BASE-CHAR . "Darwin") :OS-VERSION
    #A((6) COMMON-LISP:BASE-CHAR . "27.0.0") :MACHINE
    #A((5) COMMON-LISP:BASE-CHAR . "ARM64") :SAFETY 3)
   :SOURCE-BLOBS
   ((:PATH
     #A((79) COMMON-LISP:BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-10-v2-limits/migrazione.lisp")
     :GIT-BLOB "530e532543de2ffcfa3d3a1491b5d267f82872f3")
    (:PATH
     #A((73) COMMON-LISP:BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-09-integrity/core.lisp")
     :GIT-BLOB "80cdac4c0e52703618e1f274413b2ecbe00e6b14"))
   :COMPILE-STATUS
   (:STATUS :OK :WARNINGS COMMON-LISP:NIL :FAILURE COMMON-LISP:NIL) :RESULT
   COMMON-LISP:NIL :LIMITS
   (:FILEHEADER-BYTE 64 :CRC-BYTE 56 :PASSI-PER-ESECUZIONE 32 :COPIE 2 :FASI 10
    :PASSI-RECOVERY 4 :PREFISSI-PER-SCENARIO 11 :SCENARI 4 :ALTERNATIVE-CRASH 4
    :PIN-MASSIMO 1)
   :TIME
   (:STARTED-UNIVERSAL 4000474592 :COMPILE-SECONDS 0.156606d0 :CHECK-SECONDS
    COMMON-LISP:NIL :TOTAL-SECONDS 0.578344d0)
   :STDOUT "" :STDERR "" :FAILURE
   (:TYPE #A((12) COMMON-LISP:BASE-CHAR . "ERRORE-SPIKE") :MESSAGE
    #A((869) COMMON-LISP:BASE-CHAR
       . "REQ-AFF-007: recovery/rerun non idempotente: (:V1 T :V1-IMMUTABILE T NIL NIL
                                              NIL NIL NIL NIL :NESSUNO NIL NIL
                                              0 NIL NIL 0 :BUDGET) / (:V1 T
                                                                      :V1-IMMUTABILE
                                                                      T NIL T
                                                                      NIL NIL
                                                                      NIL NIL
                                                                      :NESSUNO
                                                                      NIL NIL 0
                                                                      NIL NIL 0
                                                                      :BUDGET).")))
  (:SCHEMA 1 :COMMAND
   (:PROGRAM "sbcl" :ARGUMENTS
    ("--noinform" "--no-userinit" "--script" "/dev/stdin") :CWD
    "/Users/gpicchiarelli/Documents/ArcDocDB" :STEPS
    ((:LOAD
      #A((33) COMMON-LISP:BASE-CHAR . "spikes/SPK-09-integrity/core.lisp"))
     (:COMPILE-FILE
      #A((39) COMMON-LISP:BASE-CHAR
         . "spikes/SPK-10-v2-limits/migrazione.lisp")
      :OUTPUT-FILE
      #A((41) COMMON-LISP:BASE-CHAR
         . "/tmp/arcdocdb-spk10-migrazione-agent.fasl")
      :WARNINGS-FATAL COMMON-LISP:T)
     (:LOAD
      #A((41) COMMON-LISP:BASE-CHAR
         . "/tmp/arcdocdb-spk10-migrazione-agent.fasl"))
     (:FUNCALL "arcdocdb.spk10.migrazione:check")))
   :ENVIRONMENT
   (:IMPLEMENTATION #A((4) COMMON-LISP:BASE-CHAR . "SBCL") :VERSION
    #A((5) COMMON-LISP:BASE-CHAR . "2.6.9") :OS
    #A((6) COMMON-LISP:BASE-CHAR . "Darwin") :OS-VERSION
    #A((6) COMMON-LISP:BASE-CHAR . "27.0.0") :MACHINE
    #A((5) COMMON-LISP:BASE-CHAR . "ARM64") :SAFETY 3)
   :SOURCE-BLOBS
   ((:PATH
     #A((79) COMMON-LISP:BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-10-v2-limits/migrazione.lisp")
     :GIT-BLOB "843255bd87a9918fde42087e69983da473bbbbae")
    (:PATH
     #A((73) COMMON-LISP:BASE-CHAR
        . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-09-integrity/core.lisp")
     :GIT-BLOB "80cdac4c0e52703618e1f274413b2ecbe00e6b14"))
   :COMPILE-STATUS
   (:STATUS :OK :WARNINGS COMMON-LISP:NIL :FAILURE COMMON-LISP:NIL) :RESULT
   (:STATUS :OK :FILEHEADERS
    (:ACCETTATI 8 :RIFIUTATI 2393 :BIT-FLIP 2048 :TRONCAMENTI 256
     :RISERVATI-CRC-VALIDO 68 :ORIGINI-INVALIDE 12 :VERSIONI-IGNOTE 4
     :BOUNDS-INVALIDI 4 :MAGIC-ALTERNATIVO-RIFIUTATO 1
     :PARSER-INVOCATI-SU-HEADER-INVALIDI 0)
    :MODELLO
    (:SCENARI 4 :STATI-PIN 2 :PREFISSI 52 :CRASH 208 :INTERRUZIONI-RECOVERY
     4160 :RERUN 208 :MASSIMO-PASSI 18 :FALSE-VERIFICHE-RILEVATE-DA-ORACLE 2
     :VERIFICHE-NEGATIVE 4)
    :ANOMALIE
    (:CASI 4 :TMP-NOMINATO-RINOMINATO 1 :ERRORI-INTEGRITA 2
     :DEFINITIVI-SCONOSCIUTI-CONSERVATI 1)
    :BUDGET (:SATURAZIONI 13 :PIN-TRATTENUTO 1 :PIN-RILASCIATO 1)
    :MUTANTI-RILEVATI 3 :MUTANTI-ATTESI
    ((:MUTANTE :UNLINK-BEFORE-EDIT :RILEVATO COMMON-LISP:T :FASE :PREPARE.TMP
      :ORACLE :UNLINK-BEFORE-EDIT)
     (:MUTANTE :SKIP-VERIFICATION :RILEVATO COMMON-LISP:T :FASE :PUBLISH.EDIT
      :ORACLE :SKIP-VERIFICATION)
     (:MUTANTE :RECLAIM-PINNED :RILEVATO COMMON-LISP:T :FASE :RECLAIM :ORACLE
      :RECLAIM-PINNED))
    :LIMITI
    (:FILEHEADER-BYTE 64 :CRC-BYTE 56 :SORGENTI 1 :OUTPUT 1 :PIN-MASSIMO 1
     :PASSI-PER-ESECUZIONE 32 :COPIE 4 :FASI 10 :PASSI-RECOVERY 4
     :PREFISSI-PER-SCENARIO 11 :SCENARI 4 :ALTERNATIVE-CRASH 4)
    :CONVERSIONE-BYTE COMMON-LISP:NIL :CRASH-REALI-VERIFICATI COMMON-LISP:NIL)
   :LIMITS
   (:FILEHEADER-BYTE 64 :CRC-BYTE 56 :SORGENTI 1 :OUTPUT 1 :PIN-MASSIMO 1
    :PASSI-PER-ESECUZIONE 32 :COPIE 4 :FASI 10 :PASSI-RECOVERY 4
    :PREFISSI-PER-SCENARIO 11 :SCENARI 4 :ALTERNATIVE-CRASH 4)
   :TIME
   (:STARTED-UNIVERSAL 4000474639 :COMPILE-SECONDS 0.156794d0 :CHECK-SECONDS
    0.006798d0 :TOTAL-SECONDS 0.656576d0)
   :STDOUT "" :STDERR "" :FAILURE COMMON-LISP:NIL)))
