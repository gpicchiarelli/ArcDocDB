(:SCHEMA-VERSION 1 :KIND :MUTATION-LOG-IMPORT :ENTRIES
 ((:NAME :BASELINE :RESULT :SURVIVED :EXIT-CODE 0 :ARGV
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/decisions-radix-isolated-build.lisp")
   :LOG
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/baseline/test.log"
    :GIT-BLOB "f8e3e9a6f1ff65afe6d68cb16d6622bb7fd34213" :TEXT
    "decision-test-start TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
ok    TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
decision-test-start TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
ok    TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
decision-test-start TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
ok    TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
decision-test-start TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
ok    TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
ok    TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
decision-test-start TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
ok    TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
decision-test-start TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
ok    TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
decision-test-start TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
ok    TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
decision-test-start TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
ok    TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
decision-test-start TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
ok    TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
decision-test-start TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
ok    TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
decision-test-start TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
ok    TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
decision-test-start TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
ok    TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
decision-test-start TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
ok    TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
decision-test-start TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
ok    TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
decision-test-start TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
ok    TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
decision-test-start TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
ok    TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
decision-test-start TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
ok    TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
ok    TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
decision-test-start TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
ok    TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
decision-test-start TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
ok    TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
decision-test-start TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
ok    TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
decision-test-start TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
ok    TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
decision-test-start TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
ok    TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
decision-test-start TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT
ok    TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT
decision-test-start TEST-REQ-TXM-005-RADIX-PARTICIPANT-CARDINALITIES-AND-PATTERNS
ok    TEST-REQ-TXM-005-RADIX-PARTICIPANT-CARDINALITIES-AND-PATTERNS
decision-test-start TEST-REQ-TXM-001-RADIX-PARTICIPANT-EVERY-BYTE-AND-BIT
ok    TEST-REQ-TXM-001-RADIX-PARTICIPANT-EVERY-BYTE-AND-BIT
decision-test-start TEST-REQ-TXM-005-RADIX-DUPLICATE-PARTICIPANT-OFFSET
ok    TEST-REQ-TXM-005-RADIX-DUPLICATE-PARTICIPANT-OFFSET
decision-test-start TEST-REQ-TXM-005-RADIX-PARTICIPANT-SHAPE-BEFORE-SORT
ok    TEST-REQ-TXM-005-RADIX-PARTICIPANT-SHAPE-BEFORE-SORT
decision-test-start TEST-REQ-TXM-005-RADIX-ENTRY-CARDINALITIES-PATTERNS-AND-STABILITY
ok    TEST-REQ-TXM-005-RADIX-ENTRY-CARDINALITIES-PATTERNS-AND-STABILITY
decision-test-start TEST-REQ-AFF-008-RADIX-ENTRY-65536-BUCKET-COUNTS
ok    TEST-REQ-AFF-008-RADIX-ENTRY-65536-BUCKET-COUNTS
decision-test-start TEST-REQ-TXM-001-RADIX-ENTRY-EVERY-TXID-BIT
ok    TEST-REQ-TXM-001-RADIX-ENTRY-EVERY-TXID-BIT
decision-test-start TEST-REQ-TXM-005-RADIX-ENTRY-SHAPE-BEFORE-SORT
ok    TEST-REQ-TXM-005-RADIX-ENTRY-SHAPE-BEFORE-SORT
decision-test-start TEST-REQ-TXM-005-CONCURRENT-IMMUTABLE-TABLE-QUERIES
ok    TEST-REQ-TXM-005-CONCURRENT-IMMUTABLE-TABLE-QUERIES
decision-test-start TEST-REQ-AFF-008-RADIX-PREFIX-INVALID-TOTAL
ok    TEST-REQ-AFF-008-RADIX-PREFIX-INVALID-TOTAL
decision-test-start TEST-REQ-AFF-008-RADIX-ENTRY-INVALID-OBJECT-BEFORE-SLOT-ACCESS
ok    TEST-REQ-AFF-008-RADIX-ENTRY-INVALID-OBJECT-BEFORE-SLOT-ACCESS
decision-test-start TEST-REQ-AFF-008-RADIX-INVALID-DIGIT-BEFORE-ACCESS
ok    TEST-REQ-AFF-008-RADIX-INVALID-DIGIT-BEFORE-ACCESS
decision-test-start TEST-REQ-AFF-008-RADIX-SCATTER-INVALID-ARRAYS
ok    TEST-REQ-AFF-008-RADIX-SCATTER-INVALID-ARRAYS
decision-test-start TEST-REQ-AFF-008-RADIX-INVALID-FINAL-CURSORS
ok    TEST-REQ-AFF-008-RADIX-INVALID-FINAL-CURSORS
decision-test-start TEST-REQ-AFF-008-RADIX-SCATTER-INVALID-CURSORS
ok    TEST-REQ-AFF-008-RADIX-SCATTER-INVALID-CURSORS
decision-test-start TEST-REQ-TXM-005-PUBLIC-PARTICIPANT-SORT-THRESHOLD-BOUNDARIES
ok    TEST-REQ-TXM-005-PUBLIC-PARTICIPANT-SORT-THRESHOLD-BOUNDARIES
decision-test-start TEST-REQ-TXM-005-PUBLIC-ENTRY-SORT-THRESHOLD-BOUNDARIES
ok    TEST-REQ-TXM-005-PUBLIC-ENTRY-SORT-THRESHOLD-BOUNDARIES
decision-test-start TEST-REQ-TXM-005-PUBLIC-RADIX-FIRST-PHYSICAL-CONFLICT-ACROSS-GROUPS
ok    TEST-REQ-TXM-005-PUBLIC-RADIX-FIRST-PHYSICAL-CONFLICT-ACROSS-GROUPS
decision-tests-complete 43
")
   :RUNNER
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/baseline/tools/decisions-radix-isolated-build.lisp"
    :GIT-BLOB "f345ccd265e0eebbba7e7c0dc7dc02a817388443" :TEXT "(REQUIRE :ASDF)
(SETF UIOP/CONFIGURATION:*USER-CACHE* (MERGE-PATHNAMES \"fasl/\" (TRUENAME \"./\"))
      UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (FILES
        '(\"tests/recovery/decisions.lisp\"
          \"tests/recovery/decisions-audit.lisp\"))
       (TESTS NIL))
  (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\")
    (UNLESS
        (ASDF/COMPONENT:FIND-COMPONENT
         (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\")
         '(\"recovery\" \"decisions-radix\"))
      (ERROR \"Test radix presente ma non registrato in ASDF.\"))
    (SETF FILES (APPEND FILES '(\"tests/recovery/decisions-radix.lisp\"))))
  (DOLIST (FILE FILES)
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test DECISION: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test DECISION non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&decision-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH TESTS)))
")
   :SOURCE-BLOBS
   ((:PATH "src/foundation/batch.lisp" :GIT-BLOB
     "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
    (:PATH "src/foundation/binary.lisp" :GIT-BLOB
     "2d514f6fe2e81eecb29fa53de611fa5e28696904")
    (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
     "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
    (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
     "f9c691d28620427099d1d89a89a1ff5d04cbe257")
    (:PATH "src/foundation/package.lisp" :GIT-BLOB
     "0658b083f1e777aa0ada67a63535d36946921eac")
    (:PATH "src/foundation/record.lisp" :GIT-BLOB
     "8df53d416747131d9ed9921abb4ef356d9ce5696")
    (:PATH "src/io/flush.lisp" :GIT-BLOB
     "ba31b07379219fa8fd80fca169d43a053d28063b")
    (:PATH "src/io/lifecycle.lisp" :GIT-BLOB
     "0b93448ffe9c6dd4f3a0a2f3f35d5cd656700bd7")
    (:PATH "src/io/native.lisp" :GIT-BLOB
     "1b6fe64ea7145f33bcf08c02e8550034ebd6a40c")
    (:PATH "src/io/package.lisp" :GIT-BLOB
     "6b840a0eb039afa7e55304bffba309f0ab72acdc")
    (:PATH "src/io/transfer.lisp" :GIT-BLOB
     "93acbd608b1af475aa505a6a7dedceb3b15e8d4b")
    (:PATH "src/io/types.lisp" :GIT-BLOB
     "b496c1df87108127da568a1fb7b0fd32856afcc5")
    (:PATH "src/package.lisp" :GIT-BLOB
     "3d0181717e3f334580bab9a6a507e2dfe57261ff")
    (:PATH "src/recovery/decisions-build.lisp" :GIT-BLOB
     "87cc54024e59757c16e20f3025970b1699b11662")
    (:PATH "src/recovery/decisions-package.lisp" :GIT-BLOB
     "878fd1afdcbf035a232166ef87066af4420e1aae")
    (:PATH "src/recovery/decisions-query.lisp" :GIT-BLOB
     "a6ce94b8be3c8c84043abfd6441599f9780b2c11")
    (:PATH "src/recovery/decisions-radix.lisp" :GIT-BLOB
     "e58176890a26751bf5767582b279cb667a29744e")
    (:PATH "src/recovery/decisions-sort.lisp" :GIT-BLOB
     "b133ea00a3b8063e9e934a1b41f10cad024471ae")
    (:PATH "src/recovery/decisions-types.lisp" :GIT-BLOB
     "0dbb2b3bdfbf5447a5904ce0fa6e4a97337a6827")
    (:PATH "src/recovery/package.lisp" :GIT-BLOB
     "b97b5c9bca6955e5dc45d9d4257089ab7132f3fb")
    (:PATH "src/recovery/scan.lisp" :GIT-BLOB
     "7ad6b7541397611f1ecbda7dffdda98c4453dbf1")
    (:PATH "src/storage/compaction-scan.lisp" :GIT-BLOB
     "233556c366a99b7b263af1c7bc19b47ceaebf940")
    (:PATH "src/storage/control-payload.lisp" :GIT-BLOB
     "7980cac6cc8070836b9aa49fc8a0d6fb42630749")
    (:PATH "src/storage/formats.lisp" :GIT-BLOB
     "fc942f1c8e30e637abaf13dc26343d40417fc72f")
    (:PATH "src/storage/log-header.lisp" :GIT-BLOB
     "fde8608e6ad3fe062937c48bdcb7d2d5870207bf")
    (:PATH "src/storage/package.lisp" :GIT-BLOB
     "c15553a65171e5dfb2dbadb62c92ed4dc48aee3a")
    (:PATH "src/storage/payload-record.lisp" :GIT-BLOB
     "0012eaf90064c4cc2949834a60e83c9db8ba6308")
    (:PATH "src/storage/payload-write.lisp" :GIT-BLOB
     "6cbbb89f681965173e9b1b95edf3f7f870af1eca")
    (:PATH "src/storage/segment-header.lisp" :GIT-BLOB
     "f1d99b205b1ea5e6ad059ecd7971d3633411b040")
    (:PATH "src/wal/builder.lisp" :GIT-BLOB
     "a488813eca3f6dcd251affd2017162861cd729d3")
    (:PATH "src/wal/executor.lisp" :GIT-BLOB
     "932eb39a61d9cf66d9394a25dac0e3912c3e3811")
    (:PATH "src/wal/group.lisp" :GIT-BLOB
     "ad43e8547f4b148116c00be5801ad82790240ff2")
    (:PATH "src/wal/package.lisp" :GIT-BLOB
     "608fca13f42115e74941bcbbe359d9541126c050")
    (:PATH "src/wal/types.lisp" :GIT-BLOB
     "adcfd153cb55c0c30d0ff7b610702315fc3cf485")
    (:PATH "tests/foundation/batch.lisp" :GIT-BLOB
     "00bb40ad87340ee86f5da281c09207c8da8888a6")
    (:PATH "tests/foundation/binary.lisp" :GIT-BLOB
     "ff6df200a7ace3af204b622969a387ce7a1e1504")
    (:PATH "tests/foundation/record.lisp" :GIT-BLOB
     "5c7c0d619e9637af6704ec51d564bbfdbc0df551")
    (:PATH "tests/foundation/support.lisp" :GIT-BLOB
     "d383b1cddf929ba0340d1b74eec3ec03673eac09")
    (:PATH "tests/io/native.lisp" :GIT-BLOB
     "bb3f9a460953d5575d7333b8b6eef6ecdb8e1e7d")
    (:PATH "tests/io/support.lisp" :GIT-BLOB
     "0179a0c19bdde944f47fe83716ecc6241e37c686")
    (:PATH "tests/io/transfer.lisp" :GIT-BLOB
     "40c8f4d5e2d493db090d5d09ab024c67ca6f4037")
    (:PATH "tests/lint-fixtures/bad.lisp" :GIT-BLOB
     "d0d5fd7285428e569d3dd595a0c38de5211e10a5")
    (:PATH "tests/lint-fixtures/good.lisp" :GIT-BLOB
     "35558ab0ab2be7688e9fd55a38be44ebe9a57f37")
    (:PATH "tests/recovery/corruption.lisp" :GIT-BLOB
     "2f9ead22a4e3b45cb3a680aa3a32a94bfcc6d77f")
    (:PATH "tests/recovery/decisions-audit.lisp" :GIT-BLOB
     "1b79a76515d8b8c2e67c46700cd6968b40047d62")
    (:PATH "tests/recovery/decisions-radix.lisp" :GIT-BLOB
     "232312cdd4ed6b1efcedc33ddda0fd8d1d8545d7")
    (:PATH "tests/recovery/decisions-support.lisp" :GIT-BLOB
     "f67450a9d681512a4b66efe1af1bfc82180e0058")
    (:PATH "tests/recovery/decisions.lisp" :GIT-BLOB
     "28d04d8738f077bf21ac22393a4014b518a6a0f2")
    (:PATH "tests/recovery/scan.lisp" :GIT-BLOB
     "1c7d71c32d58b05f7e06450680270cb55f6325dc")
    (:PATH "tests/recovery/support.lisp" :GIT-BLOB
     "f784671c59065b4363bcc5e49f06559b11e6562c")
    (:PATH "tests/smoke.lisp" :GIT-BLOB
     "6bd4ab9af1f3d9eedd54822eae10b7f167aa99ed")
    (:PATH "tests/storage/compaction-scan.lisp" :GIT-BLOB
     "16e5c9e5231883844ecd7956c7f790349acd2a05")
    (:PATH "tests/storage/control-payload.lisp" :GIT-BLOB
     "72358c6f324e1c7aaab2bb2c9d03d39ccf78f664")
    (:PATH "tests/storage/log-header.lisp" :GIT-BLOB
     "b3c4c96603ee769429b847569559defda5059744")
    (:PATH "tests/storage/segment-header.lisp" :GIT-BLOB
     "7155aaf2e9c0df4f96533a0be0f6532b54f44590")
    (:PATH "tests/storage/support.lisp" :GIT-BLOB
     "6aa5df3b3cc62b552f5da890583654b82df99431")
    (:PATH "tests/wal/builder.lisp" :GIT-BLOB
     "d62777cd09f8c30fc7246f59fd1bca8ea80c4559")
    (:PATH "tests/wal/fault.lisp" :GIT-BLOB
     "6361a87d73ce90f78438008693a7cd9d6461fe9b")
    (:PATH "tests/wal/group.lisp" :GIT-BLOB
     "04281d9ea3837ed2af0e7fa33b7e17df814982d7")
    (:PATH "tests/wal/native.lisp" :GIT-BLOB
     "077a835fb47524d97e449ae87c74461ebb374653")
    (:PATH "tests/wal/support.lisp" :GIT-BLOB
     "638262b264c64b96774ddb0a6095f4e582debe3e")))
  (:NAME "decision-count-boundary" :RESULT :DETECTED :EXIT-CODE 1 :ARGV
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/decisions-radix-isolated-build.lisp")
   :LOG
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/0/test.log"
    :GIT-BLOB "4a888deffab464d01220166f7d80ce5d79fba87c" :TEXT
    "decision-test-start TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
ok    TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
decision-test-start TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
ok    TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
decision-test-start TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
ok    TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
decision-test-start TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
ok    TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
ok    TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
decision-test-start TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
ok    TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
decision-test-start TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
ok    TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
decision-test-start TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
ok    TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
decision-test-start TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
ok    TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
decision-test-start TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
ok    TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
decision-test-start TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
ok    TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
decision-test-start TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
Unhandled RESOURCE-EXHAUSTED in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                          {8005AD0393}>:
  ArcDocDB: DECISION-COUNT-BUDGET all'offset 71

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005AD0393}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<RESOURCE-EXHAUSTED {800744F963}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<RESOURCE-EXHAUSTED {800744F963}>)
2: (INVOKE-DEBUGGER #<RESOURCE-EXHAUSTED {800744F963}>)
3: (ERROR RESOURCE-EXHAUSTED :REASON :DECISION-COUNT-BUDGET :OFFSET 71)
4: (ARCDOCDB.RECOVERY.DECISIONS:RICOSTRUISCI-DECISIONI #(204 204 204 204 204 204 204) 7 7 :VERSION 2 :FILE-OFFSET 64 :FILE-SIZE 71 :MAX-BYTES 67108864 :MAX-BATCHES 65536 :MAX-BATCH-RECORDS 65536 :MAX-BATCH-BYTES 67108864 :MAX-SEARCH-BYTES 67108864 :MAX-DECISIONS 0 :MAX-PARTICIPANTS 0 :MAX-PARTICIPANTS-PER-DECISION 0)
5: (TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS)
6: (\"top level form\") [toplevel]
7: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
8: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL T T)
9: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL)
10: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
11: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
12: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3 NIL)
13: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3)
14: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 3)
15: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107B90F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
16: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/0/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
17: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/0/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
18: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {107B909EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/0/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/0/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
19: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/0/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
20: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/0/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
21: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/0/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
22: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
23: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
24: (SB-IMPL::PROCESS-SCRIPT \"tools/decisions-radix-isolated-build.lisp\")
25: (SB-IMPL::TOPLEVEL-INIT)
26: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
27: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
28: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
   :RUNNER
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/0/tools/decisions-radix-isolated-build.lisp"
    :GIT-BLOB "f345ccd265e0eebbba7e7c0dc7dc02a817388443" :TEXT "(REQUIRE :ASDF)
(SETF UIOP/CONFIGURATION:*USER-CACHE* (MERGE-PATHNAMES \"fasl/\" (TRUENAME \"./\"))
      UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (FILES
        '(\"tests/recovery/decisions.lisp\"
          \"tests/recovery/decisions-audit.lisp\"))
       (TESTS NIL))
  (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\")
    (UNLESS
        (ASDF/COMPONENT:FIND-COMPONENT
         (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\")
         '(\"recovery\" \"decisions-radix\"))
      (ERROR \"Test radix presente ma non registrato in ASDF.\"))
    (SETF FILES (APPEND FILES '(\"tests/recovery/decisions-radix.lisp\"))))
  (DOLIST (FILE FILES)
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test DECISION: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test DECISION non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&decision-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH TESTS)))
")
   :SOURCE-BLOBS
   ((:PATH "src/foundation/batch.lisp" :GIT-BLOB
     "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
    (:PATH "src/foundation/binary.lisp" :GIT-BLOB
     "2d514f6fe2e81eecb29fa53de611fa5e28696904")
    (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
     "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
    (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
     "f9c691d28620427099d1d89a89a1ff5d04cbe257")
    (:PATH "src/foundation/package.lisp" :GIT-BLOB
     "0658b083f1e777aa0ada67a63535d36946921eac")
    (:PATH "src/foundation/record.lisp" :GIT-BLOB
     "8df53d416747131d9ed9921abb4ef356d9ce5696")
    (:PATH "src/io/flush.lisp" :GIT-BLOB
     "ba31b07379219fa8fd80fca169d43a053d28063b")
    (:PATH "src/io/lifecycle.lisp" :GIT-BLOB
     "0b93448ffe9c6dd4f3a0a2f3f35d5cd656700bd7")
    (:PATH "src/io/native.lisp" :GIT-BLOB
     "1b6fe64ea7145f33bcf08c02e8550034ebd6a40c")
    (:PATH "src/io/package.lisp" :GIT-BLOB
     "6b840a0eb039afa7e55304bffba309f0ab72acdc")
    (:PATH "src/io/transfer.lisp" :GIT-BLOB
     "93acbd608b1af475aa505a6a7dedceb3b15e8d4b")
    (:PATH "src/io/types.lisp" :GIT-BLOB
     "b496c1df87108127da568a1fb7b0fd32856afcc5")
    (:PATH "src/package.lisp" :GIT-BLOB
     "3d0181717e3f334580bab9a6a507e2dfe57261ff")
    (:PATH "src/recovery/decisions-build.lisp" :GIT-BLOB
     "3d80316d283ce9e1763c8e008389ccd56b7ea407")
    (:PATH "src/recovery/decisions-package.lisp" :GIT-BLOB
     "878fd1afdcbf035a232166ef87066af4420e1aae")
    (:PATH "src/recovery/decisions-query.lisp" :GIT-BLOB
     "a6ce94b8be3c8c84043abfd6441599f9780b2c11")
    (:PATH "src/recovery/decisions-radix.lisp" :GIT-BLOB
     "e58176890a26751bf5767582b279cb667a29744e")
    (:PATH "src/recovery/decisions-sort.lisp" :GIT-BLOB
     "b133ea00a3b8063e9e934a1b41f10cad024471ae")
    (:PATH "src/recovery/decisions-types.lisp" :GIT-BLOB
     "0dbb2b3bdfbf5447a5904ce0fa6e4a97337a6827")
    (:PATH "src/recovery/package.lisp" :GIT-BLOB
     "b97b5c9bca6955e5dc45d9d4257089ab7132f3fb")
    (:PATH "src/recovery/scan.lisp" :GIT-BLOB
     "7ad6b7541397611f1ecbda7dffdda98c4453dbf1")
    (:PATH "src/storage/compaction-scan.lisp" :GIT-BLOB
     "233556c366a99b7b263af1c7bc19b47ceaebf940")
    (:PATH "src/storage/control-payload.lisp" :GIT-BLOB
     "7980cac6cc8070836b9aa49fc8a0d6fb42630749")
    (:PATH "src/storage/formats.lisp" :GIT-BLOB
     "fc942f1c8e30e637abaf13dc26343d40417fc72f")
    (:PATH "src/storage/log-header.lisp" :GIT-BLOB
     "fde8608e6ad3fe062937c48bdcb7d2d5870207bf")
    (:PATH "src/storage/package.lisp" :GIT-BLOB
     "c15553a65171e5dfb2dbadb62c92ed4dc48aee3a")
    (:PATH "src/storage/payload-record.lisp" :GIT-BLOB
     "0012eaf90064c4cc2949834a60e83c9db8ba6308")
    (:PATH "src/storage/payload-write.lisp" :GIT-BLOB
     "6cbbb89f681965173e9b1b95edf3f7f870af1eca")
    (:PATH "src/storage/segment-header.lisp" :GIT-BLOB
     "f1d99b205b1ea5e6ad059ecd7971d3633411b040")
    (:PATH "src/wal/builder.lisp" :GIT-BLOB
     "a488813eca3f6dcd251affd2017162861cd729d3")
    (:PATH "src/wal/executor.lisp" :GIT-BLOB
     "932eb39a61d9cf66d9394a25dac0e3912c3e3811")
    (:PATH "src/wal/group.lisp" :GIT-BLOB
     "ad43e8547f4b148116c00be5801ad82790240ff2")
    (:PATH "src/wal/package.lisp" :GIT-BLOB
     "608fca13f42115e74941bcbbe359d9541126c050")
    (:PATH "src/wal/types.lisp" :GIT-BLOB
     "adcfd153cb55c0c30d0ff7b610702315fc3cf485")
    (:PATH "tests/foundation/batch.lisp" :GIT-BLOB
     "00bb40ad87340ee86f5da281c09207c8da8888a6")
    (:PATH "tests/foundation/binary.lisp" :GIT-BLOB
     "ff6df200a7ace3af204b622969a387ce7a1e1504")
    (:PATH "tests/foundation/record.lisp" :GIT-BLOB
     "5c7c0d619e9637af6704ec51d564bbfdbc0df551")
    (:PATH "tests/foundation/support.lisp" :GIT-BLOB
     "d383b1cddf929ba0340d1b74eec3ec03673eac09")
    (:PATH "tests/io/native.lisp" :GIT-BLOB
     "bb3f9a460953d5575d7333b8b6eef6ecdb8e1e7d")
    (:PATH "tests/io/support.lisp" :GIT-BLOB
     "0179a0c19bdde944f47fe83716ecc6241e37c686")
    (:PATH "tests/io/transfer.lisp" :GIT-BLOB
     "40c8f4d5e2d493db090d5d09ab024c67ca6f4037")
    (:PATH "tests/lint-fixtures/bad.lisp" :GIT-BLOB
     "d0d5fd7285428e569d3dd595a0c38de5211e10a5")
    (:PATH "tests/lint-fixtures/good.lisp" :GIT-BLOB
     "35558ab0ab2be7688e9fd55a38be44ebe9a57f37")
    (:PATH "tests/recovery/corruption.lisp" :GIT-BLOB
     "2f9ead22a4e3b45cb3a680aa3a32a94bfcc6d77f")
    (:PATH "tests/recovery/decisions-audit.lisp" :GIT-BLOB
     "1b79a76515d8b8c2e67c46700cd6968b40047d62")
    (:PATH "tests/recovery/decisions-radix.lisp" :GIT-BLOB
     "232312cdd4ed6b1efcedc33ddda0fd8d1d8545d7")
    (:PATH "tests/recovery/decisions-support.lisp" :GIT-BLOB
     "f67450a9d681512a4b66efe1af1bfc82180e0058")
    (:PATH "tests/recovery/decisions.lisp" :GIT-BLOB
     "28d04d8738f077bf21ac22393a4014b518a6a0f2")
    (:PATH "tests/recovery/scan.lisp" :GIT-BLOB
     "1c7d71c32d58b05f7e06450680270cb55f6325dc")
    (:PATH "tests/recovery/support.lisp" :GIT-BLOB
     "f784671c59065b4363bcc5e49f06559b11e6562c")
    (:PATH "tests/smoke.lisp" :GIT-BLOB
     "6bd4ab9af1f3d9eedd54822eae10b7f167aa99ed")
    (:PATH "tests/storage/compaction-scan.lisp" :GIT-BLOB
     "16e5c9e5231883844ecd7956c7f790349acd2a05")
    (:PATH "tests/storage/control-payload.lisp" :GIT-BLOB
     "72358c6f324e1c7aaab2bb2c9d03d39ccf78f664")
    (:PATH "tests/storage/log-header.lisp" :GIT-BLOB
     "b3c4c96603ee769429b847569559defda5059744")
    (:PATH "tests/storage/segment-header.lisp" :GIT-BLOB
     "7155aaf2e9c0df4f96533a0be0f6532b54f44590")
    (:PATH "tests/storage/support.lisp" :GIT-BLOB
     "6aa5df3b3cc62b552f5da890583654b82df99431")
    (:PATH "tests/wal/builder.lisp" :GIT-BLOB
     "d62777cd09f8c30fc7246f59fd1bca8ea80c4559")
    (:PATH "tests/wal/fault.lisp" :GIT-BLOB
     "6361a87d73ce90f78438008693a7cd9d6461fe9b")
    (:PATH "tests/wal/group.lisp" :GIT-BLOB
     "04281d9ea3837ed2af0e7fa33b7e17df814982d7")
    (:PATH "tests/wal/native.lisp" :GIT-BLOB
     "077a835fb47524d97e449ae87c74461ebb374653")
    (:PATH "tests/wal/support.lisp" :GIT-BLOB
     "638262b264c64b96774ddb0a6095f4e582debe3e")))
  (:NAME "decision-cumulative-participants" :RESULT :DETECTED :EXIT-CODE 1
   :ARGV
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/decisions-radix-isolated-build.lisp")
   :LOG
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/1/test.log"
    :GIT-BLOB "23e7e11d41dd2bf9338109779841e47667920170" :TEXT
    "decision-test-start TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
ok    TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
decision-test-start TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
ok    TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
decision-test-start TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
ok    TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
decision-test-start TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
ok    TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
ok    TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
decision-test-start TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
ok    TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
decision-test-start TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
ok    TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
decision-test-start TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
ok    TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
decision-test-start TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
ok    TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
decision-test-start TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
ok    TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
decision-test-start TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
ok    TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
decision-test-start TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
ok    TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
decision-test-start TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {8005AD0393}>:
  Asserzione recovery fallita: (TYPEP CONDITION 'RESOURCE-EXHAUSTED)

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005AD0393}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8007432023}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8007432023}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8007432023}>)
3: (ERROR \"Asserzione recovery fallita: ~S\" (TYPEP CONDITION (QUOTE RESOURCE-EXHAUSTED)))
4: (TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS)
5: (\"top level form\") [toplevel]
6: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
7: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL T T)
8: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL)
9: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
10: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
11: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3 NIL)
12: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3)
13: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 3)
14: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {105BB0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
15: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/1/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
16: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/1/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
17: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {105BB09EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/1/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/1/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
18: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/1/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
19: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/1/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
20: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/1/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
21: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
22: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
23: (SB-IMPL::PROCESS-SCRIPT \"tools/decisions-radix-isolated-build.lisp\")
24: (SB-IMPL::TOPLEVEL-INIT)
25: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
26: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
27: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
   :RUNNER
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/1/tools/decisions-radix-isolated-build.lisp"
    :GIT-BLOB "f345ccd265e0eebbba7e7c0dc7dc02a817388443" :TEXT "(REQUIRE :ASDF)
(SETF UIOP/CONFIGURATION:*USER-CACHE* (MERGE-PATHNAMES \"fasl/\" (TRUENAME \"./\"))
      UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (FILES
        '(\"tests/recovery/decisions.lisp\"
          \"tests/recovery/decisions-audit.lisp\"))
       (TESTS NIL))
  (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\")
    (UNLESS
        (ASDF/COMPONENT:FIND-COMPONENT
         (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\")
         '(\"recovery\" \"decisions-radix\"))
      (ERROR \"Test radix presente ma non registrato in ASDF.\"))
    (SETF FILES (APPEND FILES '(\"tests/recovery/decisions-radix.lisp\"))))
  (DOLIST (FILE FILES)
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test DECISION: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test DECISION non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&decision-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH TESTS)))
")
   :SOURCE-BLOBS
   ((:PATH "src/foundation/batch.lisp" :GIT-BLOB
     "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
    (:PATH "src/foundation/binary.lisp" :GIT-BLOB
     "2d514f6fe2e81eecb29fa53de611fa5e28696904")
    (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
     "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
    (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
     "f9c691d28620427099d1d89a89a1ff5d04cbe257")
    (:PATH "src/foundation/package.lisp" :GIT-BLOB
     "0658b083f1e777aa0ada67a63535d36946921eac")
    (:PATH "src/foundation/record.lisp" :GIT-BLOB
     "8df53d416747131d9ed9921abb4ef356d9ce5696")
    (:PATH "src/io/flush.lisp" :GIT-BLOB
     "ba31b07379219fa8fd80fca169d43a053d28063b")
    (:PATH "src/io/lifecycle.lisp" :GIT-BLOB
     "0b93448ffe9c6dd4f3a0a2f3f35d5cd656700bd7")
    (:PATH "src/io/native.lisp" :GIT-BLOB
     "1b6fe64ea7145f33bcf08c02e8550034ebd6a40c")
    (:PATH "src/io/package.lisp" :GIT-BLOB
     "6b840a0eb039afa7e55304bffba309f0ab72acdc")
    (:PATH "src/io/transfer.lisp" :GIT-BLOB
     "93acbd608b1af475aa505a6a7dedceb3b15e8d4b")
    (:PATH "src/io/types.lisp" :GIT-BLOB
     "b496c1df87108127da568a1fb7b0fd32856afcc5")
    (:PATH "src/package.lisp" :GIT-BLOB
     "3d0181717e3f334580bab9a6a507e2dfe57261ff")
    (:PATH "src/recovery/decisions-build.lisp" :GIT-BLOB
     "32cfe8759cb68f1aa40904a89a2883c9fdfce742")
    (:PATH "src/recovery/decisions-package.lisp" :GIT-BLOB
     "878fd1afdcbf035a232166ef87066af4420e1aae")
    (:PATH "src/recovery/decisions-query.lisp" :GIT-BLOB
     "a6ce94b8be3c8c84043abfd6441599f9780b2c11")
    (:PATH "src/recovery/decisions-radix.lisp" :GIT-BLOB
     "e58176890a26751bf5767582b279cb667a29744e")
    (:PATH "src/recovery/decisions-sort.lisp" :GIT-BLOB
     "b133ea00a3b8063e9e934a1b41f10cad024471ae")
    (:PATH "src/recovery/decisions-types.lisp" :GIT-BLOB
     "0dbb2b3bdfbf5447a5904ce0fa6e4a97337a6827")
    (:PATH "src/recovery/package.lisp" :GIT-BLOB
     "b97b5c9bca6955e5dc45d9d4257089ab7132f3fb")
    (:PATH "src/recovery/scan.lisp" :GIT-BLOB
     "7ad6b7541397611f1ecbda7dffdda98c4453dbf1")
    (:PATH "src/storage/compaction-scan.lisp" :GIT-BLOB
     "233556c366a99b7b263af1c7bc19b47ceaebf940")
    (:PATH "src/storage/control-payload.lisp" :GIT-BLOB
     "7980cac6cc8070836b9aa49fc8a0d6fb42630749")
    (:PATH "src/storage/formats.lisp" :GIT-BLOB
     "fc942f1c8e30e637abaf13dc26343d40417fc72f")
    (:PATH "src/storage/log-header.lisp" :GIT-BLOB
     "fde8608e6ad3fe062937c48bdcb7d2d5870207bf")
    (:PATH "src/storage/package.lisp" :GIT-BLOB
     "c15553a65171e5dfb2dbadb62c92ed4dc48aee3a")
    (:PATH "src/storage/payload-record.lisp" :GIT-BLOB
     "0012eaf90064c4cc2949834a60e83c9db8ba6308")
    (:PATH "src/storage/payload-write.lisp" :GIT-BLOB
     "6cbbb89f681965173e9b1b95edf3f7f870af1eca")
    (:PATH "src/storage/segment-header.lisp" :GIT-BLOB
     "f1d99b205b1ea5e6ad059ecd7971d3633411b040")
    (:PATH "src/wal/builder.lisp" :GIT-BLOB
     "a488813eca3f6dcd251affd2017162861cd729d3")
    (:PATH "src/wal/executor.lisp" :GIT-BLOB
     "932eb39a61d9cf66d9394a25dac0e3912c3e3811")
    (:PATH "src/wal/group.lisp" :GIT-BLOB
     "ad43e8547f4b148116c00be5801ad82790240ff2")
    (:PATH "src/wal/package.lisp" :GIT-BLOB
     "608fca13f42115e74941bcbbe359d9541126c050")
    (:PATH "src/wal/types.lisp" :GIT-BLOB
     "adcfd153cb55c0c30d0ff7b610702315fc3cf485")
    (:PATH "tests/foundation/batch.lisp" :GIT-BLOB
     "00bb40ad87340ee86f5da281c09207c8da8888a6")
    (:PATH "tests/foundation/binary.lisp" :GIT-BLOB
     "ff6df200a7ace3af204b622969a387ce7a1e1504")
    (:PATH "tests/foundation/record.lisp" :GIT-BLOB
     "5c7c0d619e9637af6704ec51d564bbfdbc0df551")
    (:PATH "tests/foundation/support.lisp" :GIT-BLOB
     "d383b1cddf929ba0340d1b74eec3ec03673eac09")
    (:PATH "tests/io/native.lisp" :GIT-BLOB
     "bb3f9a460953d5575d7333b8b6eef6ecdb8e1e7d")
    (:PATH "tests/io/support.lisp" :GIT-BLOB
     "0179a0c19bdde944f47fe83716ecc6241e37c686")
    (:PATH "tests/io/transfer.lisp" :GIT-BLOB
     "40c8f4d5e2d493db090d5d09ab024c67ca6f4037")
    (:PATH "tests/lint-fixtures/bad.lisp" :GIT-BLOB
     "d0d5fd7285428e569d3dd595a0c38de5211e10a5")
    (:PATH "tests/lint-fixtures/good.lisp" :GIT-BLOB
     "35558ab0ab2be7688e9fd55a38be44ebe9a57f37")
    (:PATH "tests/recovery/corruption.lisp" :GIT-BLOB
     "2f9ead22a4e3b45cb3a680aa3a32a94bfcc6d77f")
    (:PATH "tests/recovery/decisions-audit.lisp" :GIT-BLOB
     "1b79a76515d8b8c2e67c46700cd6968b40047d62")
    (:PATH "tests/recovery/decisions-radix.lisp" :GIT-BLOB
     "232312cdd4ed6b1efcedc33ddda0fd8d1d8545d7")
    (:PATH "tests/recovery/decisions-support.lisp" :GIT-BLOB
     "f67450a9d681512a4b66efe1af1bfc82180e0058")
    (:PATH "tests/recovery/decisions.lisp" :GIT-BLOB
     "28d04d8738f077bf21ac22393a4014b518a6a0f2")
    (:PATH "tests/recovery/scan.lisp" :GIT-BLOB
     "1c7d71c32d58b05f7e06450680270cb55f6325dc")
    (:PATH "tests/recovery/support.lisp" :GIT-BLOB
     "f784671c59065b4363bcc5e49f06559b11e6562c")
    (:PATH "tests/smoke.lisp" :GIT-BLOB
     "6bd4ab9af1f3d9eedd54822eae10b7f167aa99ed")
    (:PATH "tests/storage/compaction-scan.lisp" :GIT-BLOB
     "16e5c9e5231883844ecd7956c7f790349acd2a05")
    (:PATH "tests/storage/control-payload.lisp" :GIT-BLOB
     "72358c6f324e1c7aaab2bb2c9d03d39ccf78f664")
    (:PATH "tests/storage/log-header.lisp" :GIT-BLOB
     "b3c4c96603ee769429b847569559defda5059744")
    (:PATH "tests/storage/segment-header.lisp" :GIT-BLOB
     "7155aaf2e9c0df4f96533a0be0f6532b54f44590")
    (:PATH "tests/storage/support.lisp" :GIT-BLOB
     "6aa5df3b3cc62b552f5da890583654b82df99431")
    (:PATH "tests/wal/builder.lisp" :GIT-BLOB
     "d62777cd09f8c30fc7246f59fd1bca8ea80c4559")
    (:PATH "tests/wal/fault.lisp" :GIT-BLOB
     "6361a87d73ce90f78438008693a7cd9d6461fe9b")
    (:PATH "tests/wal/group.lisp" :GIT-BLOB
     "04281d9ea3837ed2af0e7fa33b7e17df814982d7")
    (:PATH "tests/wal/native.lisp" :GIT-BLOB
     "077a835fb47524d97e449ae87c74461ebb374653")
    (:PATH "tests/wal/support.lisp" :GIT-BLOB
     "638262b264c64b96774ddb0a6095f4e582debe3e")))
  (:NAME "decision-duplicate-participant" :RESULT :DETECTED :EXIT-CODE 1 :ARGV
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/decisions-radix-isolated-build.lisp")
   :LOG
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/2/test.log"
    :GIT-BLOB "a73628ecf712d8e12cec173d66572e37bba47b5f" :TEXT
    "decision-test-start TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
ok    TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
decision-test-start TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
ok    TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
decision-test-start TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
ok    TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
decision-test-start TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
ok    TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
ok    TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
decision-test-start TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
ok    TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
decision-test-start TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {8005AA0433}>:
  Asserzione recovery fallita: (TYPEP CONDITION 'CORRUPTION-DETECTED)

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005AA0433}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {800739E613}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {800739E613}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {800739E613}>)
3: (ERROR \"Asserzione recovery fallita: ~S\" (TYPEP CONDITION (QUOTE CORRUPTION-DETECTED)))
4: (TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD)
5: (\"top level form\") [toplevel]
6: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
7: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL T T)
8: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL)
9: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
10: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
11: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3 NIL)
12: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3)
13: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 3)
14: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {109370F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
15: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/2/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
16: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/2/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
17: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1093709EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/2/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/2/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
18: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/2/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
19: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/2/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
20: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/2/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
21: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
22: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
23: (SB-IMPL::PROCESS-SCRIPT \"tools/decisions-radix-isolated-build.lisp\")
24: (SB-IMPL::TOPLEVEL-INIT)
25: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
26: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
27: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
   :RUNNER
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/2/tools/decisions-radix-isolated-build.lisp"
    :GIT-BLOB "f345ccd265e0eebbba7e7c0dc7dc02a817388443" :TEXT "(REQUIRE :ASDF)
(SETF UIOP/CONFIGURATION:*USER-CACHE* (MERGE-PATHNAMES \"fasl/\" (TRUENAME \"./\"))
      UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (FILES
        '(\"tests/recovery/decisions.lisp\"
          \"tests/recovery/decisions-audit.lisp\"))
       (TESTS NIL))
  (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\")
    (UNLESS
        (ASDF/COMPONENT:FIND-COMPONENT
         (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\")
         '(\"recovery\" \"decisions-radix\"))
      (ERROR \"Test radix presente ma non registrato in ASDF.\"))
    (SETF FILES (APPEND FILES '(\"tests/recovery/decisions-radix.lisp\"))))
  (DOLIST (FILE FILES)
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test DECISION: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test DECISION non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&decision-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH TESTS)))
")
   :SOURCE-BLOBS
   ((:PATH "src/foundation/batch.lisp" :GIT-BLOB
     "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
    (:PATH "src/foundation/binary.lisp" :GIT-BLOB
     "2d514f6fe2e81eecb29fa53de611fa5e28696904")
    (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
     "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
    (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
     "f9c691d28620427099d1d89a89a1ff5d04cbe257")
    (:PATH "src/foundation/package.lisp" :GIT-BLOB
     "0658b083f1e777aa0ada67a63535d36946921eac")
    (:PATH "src/foundation/record.lisp" :GIT-BLOB
     "8df53d416747131d9ed9921abb4ef356d9ce5696")
    (:PATH "src/io/flush.lisp" :GIT-BLOB
     "ba31b07379219fa8fd80fca169d43a053d28063b")
    (:PATH "src/io/lifecycle.lisp" :GIT-BLOB
     "0b93448ffe9c6dd4f3a0a2f3f35d5cd656700bd7")
    (:PATH "src/io/native.lisp" :GIT-BLOB
     "1b6fe64ea7145f33bcf08c02e8550034ebd6a40c")
    (:PATH "src/io/package.lisp" :GIT-BLOB
     "6b840a0eb039afa7e55304bffba309f0ab72acdc")
    (:PATH "src/io/transfer.lisp" :GIT-BLOB
     "93acbd608b1af475aa505a6a7dedceb3b15e8d4b")
    (:PATH "src/io/types.lisp" :GIT-BLOB
     "b496c1df87108127da568a1fb7b0fd32856afcc5")
    (:PATH "src/package.lisp" :GIT-BLOB
     "3d0181717e3f334580bab9a6a507e2dfe57261ff")
    (:PATH "src/recovery/decisions-build.lisp" :GIT-BLOB
     "87cc54024e59757c16e20f3025970b1699b11662")
    (:PATH "src/recovery/decisions-package.lisp" :GIT-BLOB
     "878fd1afdcbf035a232166ef87066af4420e1aae")
    (:PATH "src/recovery/decisions-query.lisp" :GIT-BLOB
     "a6ce94b8be3c8c84043abfd6441599f9780b2c11")
    (:PATH "src/recovery/decisions-radix.lisp" :GIT-BLOB
     "e58176890a26751bf5767582b279cb667a29744e")
    (:PATH "src/recovery/decisions-sort.lisp" :GIT-BLOB
     "95e6213d2f35f0495b2eb65c3e1e25a618f37436")
    (:PATH "src/recovery/decisions-types.lisp" :GIT-BLOB
     "0dbb2b3bdfbf5447a5904ce0fa6e4a97337a6827")
    (:PATH "src/recovery/package.lisp" :GIT-BLOB
     "b97b5c9bca6955e5dc45d9d4257089ab7132f3fb")
    (:PATH "src/recovery/scan.lisp" :GIT-BLOB
     "7ad6b7541397611f1ecbda7dffdda98c4453dbf1")
    (:PATH "src/storage/compaction-scan.lisp" :GIT-BLOB
     "233556c366a99b7b263af1c7bc19b47ceaebf940")
    (:PATH "src/storage/control-payload.lisp" :GIT-BLOB
     "7980cac6cc8070836b9aa49fc8a0d6fb42630749")
    (:PATH "src/storage/formats.lisp" :GIT-BLOB
     "fc942f1c8e30e637abaf13dc26343d40417fc72f")
    (:PATH "src/storage/log-header.lisp" :GIT-BLOB
     "fde8608e6ad3fe062937c48bdcb7d2d5870207bf")
    (:PATH "src/storage/package.lisp" :GIT-BLOB
     "c15553a65171e5dfb2dbadb62c92ed4dc48aee3a")
    (:PATH "src/storage/payload-record.lisp" :GIT-BLOB
     "0012eaf90064c4cc2949834a60e83c9db8ba6308")
    (:PATH "src/storage/payload-write.lisp" :GIT-BLOB
     "6cbbb89f681965173e9b1b95edf3f7f870af1eca")
    (:PATH "src/storage/segment-header.lisp" :GIT-BLOB
     "f1d99b205b1ea5e6ad059ecd7971d3633411b040")
    (:PATH "src/wal/builder.lisp" :GIT-BLOB
     "a488813eca3f6dcd251affd2017162861cd729d3")
    (:PATH "src/wal/executor.lisp" :GIT-BLOB
     "932eb39a61d9cf66d9394a25dac0e3912c3e3811")
    (:PATH "src/wal/group.lisp" :GIT-BLOB
     "ad43e8547f4b148116c00be5801ad82790240ff2")
    (:PATH "src/wal/package.lisp" :GIT-BLOB
     "608fca13f42115e74941bcbbe359d9541126c050")
    (:PATH "src/wal/types.lisp" :GIT-BLOB
     "adcfd153cb55c0c30d0ff7b610702315fc3cf485")
    (:PATH "tests/foundation/batch.lisp" :GIT-BLOB
     "00bb40ad87340ee86f5da281c09207c8da8888a6")
    (:PATH "tests/foundation/binary.lisp" :GIT-BLOB
     "ff6df200a7ace3af204b622969a387ce7a1e1504")
    (:PATH "tests/foundation/record.lisp" :GIT-BLOB
     "5c7c0d619e9637af6704ec51d564bbfdbc0df551")
    (:PATH "tests/foundation/support.lisp" :GIT-BLOB
     "d383b1cddf929ba0340d1b74eec3ec03673eac09")
    (:PATH "tests/io/native.lisp" :GIT-BLOB
     "bb3f9a460953d5575d7333b8b6eef6ecdb8e1e7d")
    (:PATH "tests/io/support.lisp" :GIT-BLOB
     "0179a0c19bdde944f47fe83716ecc6241e37c686")
    (:PATH "tests/io/transfer.lisp" :GIT-BLOB
     "40c8f4d5e2d493db090d5d09ab024c67ca6f4037")
    (:PATH "tests/lint-fixtures/bad.lisp" :GIT-BLOB
     "d0d5fd7285428e569d3dd595a0c38de5211e10a5")
    (:PATH "tests/lint-fixtures/good.lisp" :GIT-BLOB
     "35558ab0ab2be7688e9fd55a38be44ebe9a57f37")
    (:PATH "tests/recovery/corruption.lisp" :GIT-BLOB
     "2f9ead22a4e3b45cb3a680aa3a32a94bfcc6d77f")
    (:PATH "tests/recovery/decisions-audit.lisp" :GIT-BLOB
     "1b79a76515d8b8c2e67c46700cd6968b40047d62")
    (:PATH "tests/recovery/decisions-radix.lisp" :GIT-BLOB
     "232312cdd4ed6b1efcedc33ddda0fd8d1d8545d7")
    (:PATH "tests/recovery/decisions-support.lisp" :GIT-BLOB
     "f67450a9d681512a4b66efe1af1bfc82180e0058")
    (:PATH "tests/recovery/decisions.lisp" :GIT-BLOB
     "28d04d8738f077bf21ac22393a4014b518a6a0f2")
    (:PATH "tests/recovery/scan.lisp" :GIT-BLOB
     "1c7d71c32d58b05f7e06450680270cb55f6325dc")
    (:PATH "tests/recovery/support.lisp" :GIT-BLOB
     "f784671c59065b4363bcc5e49f06559b11e6562c")
    (:PATH "tests/smoke.lisp" :GIT-BLOB
     "6bd4ab9af1f3d9eedd54822eae10b7f167aa99ed")
    (:PATH "tests/storage/compaction-scan.lisp" :GIT-BLOB
     "16e5c9e5231883844ecd7956c7f790349acd2a05")
    (:PATH "tests/storage/control-payload.lisp" :GIT-BLOB
     "72358c6f324e1c7aaab2bb2c9d03d39ccf78f664")
    (:PATH "tests/storage/log-header.lisp" :GIT-BLOB
     "b3c4c96603ee769429b847569559defda5059744")
    (:PATH "tests/storage/segment-header.lisp" :GIT-BLOB
     "7155aaf2e9c0df4f96533a0be0f6532b54f44590")
    (:PATH "tests/storage/support.lisp" :GIT-BLOB
     "6aa5df3b3cc62b552f5da890583654b82df99431")
    (:PATH "tests/wal/builder.lisp" :GIT-BLOB
     "d62777cd09f8c30fc7246f59fd1bca8ea80c4559")
    (:PATH "tests/wal/fault.lisp" :GIT-BLOB
     "6361a87d73ce90f78438008693a7cd9d6461fe9b")
    (:PATH "tests/wal/group.lisp" :GIT-BLOB
     "04281d9ea3837ed2af0e7fa33b7e17df814982d7")
    (:PATH "tests/wal/native.lisp" :GIT-BLOB
     "077a835fb47524d97e449ae87c74461ebb374653")
    (:PATH "tests/wal/support.lisp" :GIT-BLOB
     "638262b264c64b96774ddb0a6095f4e582debe3e")))
  (:NAME "decision-csn-conflict" :RESULT :DETECTED :EXIT-CODE 1 :ARGV
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/decisions-radix-isolated-build.lisp")
   :LOG
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/3/test.log"
    :GIT-BLOB "7dc68426db8a88c7e76f7368fdd309d8032ec19b" :TEXT
    "decision-test-start TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
ok    TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
decision-test-start TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
ok    TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
decision-test-start TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
ok    TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
decision-test-start TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
ok    TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
ok    TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
decision-test-start TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {8005AD0423}>:
  Asserzione recovery fallita: (TYPEP CONDITION 'CORRUPTION-DETECTED)

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005AD0423}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8007373E53}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8007373E53}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8007373E53}>)
3: (ERROR \"Asserzione recovery fallita: ~S\" (TYPEP CONDITION (QUOTE CORRUPTION-DETECTED)))
4: (TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT)
5: (\"top level form\") [toplevel]
6: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
7: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL T T)
8: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL)
9: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
10: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
11: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3 NIL)
12: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3)
13: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 3)
14: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107130F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
15: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/3/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
16: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/3/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
17: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1071309EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/3/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/3/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
18: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/3/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
19: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/3/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
20: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/3/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
21: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
22: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
23: (SB-IMPL::PROCESS-SCRIPT \"tools/decisions-radix-isolated-build.lisp\")
24: (SB-IMPL::TOPLEVEL-INIT)
25: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
26: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
27: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
   :RUNNER
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/3/tools/decisions-radix-isolated-build.lisp"
    :GIT-BLOB "f345ccd265e0eebbba7e7c0dc7dc02a817388443" :TEXT "(REQUIRE :ASDF)
(SETF UIOP/CONFIGURATION:*USER-CACHE* (MERGE-PATHNAMES \"fasl/\" (TRUENAME \"./\"))
      UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (FILES
        '(\"tests/recovery/decisions.lisp\"
          \"tests/recovery/decisions-audit.lisp\"))
       (TESTS NIL))
  (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\")
    (UNLESS
        (ASDF/COMPONENT:FIND-COMPONENT
         (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\")
         '(\"recovery\" \"decisions-radix\"))
      (ERROR \"Test radix presente ma non registrato in ASDF.\"))
    (SETF FILES (APPEND FILES '(\"tests/recovery/decisions-radix.lisp\"))))
  (DOLIST (FILE FILES)
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test DECISION: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test DECISION non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&decision-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH TESTS)))
")
   :SOURCE-BLOBS
   ((:PATH "src/foundation/batch.lisp" :GIT-BLOB
     "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
    (:PATH "src/foundation/binary.lisp" :GIT-BLOB
     "2d514f6fe2e81eecb29fa53de611fa5e28696904")
    (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
     "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
    (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
     "f9c691d28620427099d1d89a89a1ff5d04cbe257")
    (:PATH "src/foundation/package.lisp" :GIT-BLOB
     "0658b083f1e777aa0ada67a63535d36946921eac")
    (:PATH "src/foundation/record.lisp" :GIT-BLOB
     "8df53d416747131d9ed9921abb4ef356d9ce5696")
    (:PATH "src/io/flush.lisp" :GIT-BLOB
     "ba31b07379219fa8fd80fca169d43a053d28063b")
    (:PATH "src/io/lifecycle.lisp" :GIT-BLOB
     "0b93448ffe9c6dd4f3a0a2f3f35d5cd656700bd7")
    (:PATH "src/io/native.lisp" :GIT-BLOB
     "1b6fe64ea7145f33bcf08c02e8550034ebd6a40c")
    (:PATH "src/io/package.lisp" :GIT-BLOB
     "6b840a0eb039afa7e55304bffba309f0ab72acdc")
    (:PATH "src/io/transfer.lisp" :GIT-BLOB
     "93acbd608b1af475aa505a6a7dedceb3b15e8d4b")
    (:PATH "src/io/types.lisp" :GIT-BLOB
     "b496c1df87108127da568a1fb7b0fd32856afcc5")
    (:PATH "src/package.lisp" :GIT-BLOB
     "3d0181717e3f334580bab9a6a507e2dfe57261ff")
    (:PATH "src/recovery/decisions-build.lisp" :GIT-BLOB
     "35958a64152c9a0fe9d4210dfc2540db8ba21113")
    (:PATH "src/recovery/decisions-package.lisp" :GIT-BLOB
     "878fd1afdcbf035a232166ef87066af4420e1aae")
    (:PATH "src/recovery/decisions-query.lisp" :GIT-BLOB
     "a6ce94b8be3c8c84043abfd6441599f9780b2c11")
    (:PATH "src/recovery/decisions-radix.lisp" :GIT-BLOB
     "e58176890a26751bf5767582b279cb667a29744e")
    (:PATH "src/recovery/decisions-sort.lisp" :GIT-BLOB
     "b133ea00a3b8063e9e934a1b41f10cad024471ae")
    (:PATH "src/recovery/decisions-types.lisp" :GIT-BLOB
     "0dbb2b3bdfbf5447a5904ce0fa6e4a97337a6827")
    (:PATH "src/recovery/package.lisp" :GIT-BLOB
     "b97b5c9bca6955e5dc45d9d4257089ab7132f3fb")
    (:PATH "src/recovery/scan.lisp" :GIT-BLOB
     "7ad6b7541397611f1ecbda7dffdda98c4453dbf1")
    (:PATH "src/storage/compaction-scan.lisp" :GIT-BLOB
     "233556c366a99b7b263af1c7bc19b47ceaebf940")
    (:PATH "src/storage/control-payload.lisp" :GIT-BLOB
     "7980cac6cc8070836b9aa49fc8a0d6fb42630749")
    (:PATH "src/storage/formats.lisp" :GIT-BLOB
     "fc942f1c8e30e637abaf13dc26343d40417fc72f")
    (:PATH "src/storage/log-header.lisp" :GIT-BLOB
     "fde8608e6ad3fe062937c48bdcb7d2d5870207bf")
    (:PATH "src/storage/package.lisp" :GIT-BLOB
     "c15553a65171e5dfb2dbadb62c92ed4dc48aee3a")
    (:PATH "src/storage/payload-record.lisp" :GIT-BLOB
     "0012eaf90064c4cc2949834a60e83c9db8ba6308")
    (:PATH "src/storage/payload-write.lisp" :GIT-BLOB
     "6cbbb89f681965173e9b1b95edf3f7f870af1eca")
    (:PATH "src/storage/segment-header.lisp" :GIT-BLOB
     "f1d99b205b1ea5e6ad059ecd7971d3633411b040")
    (:PATH "src/wal/builder.lisp" :GIT-BLOB
     "a488813eca3f6dcd251affd2017162861cd729d3")
    (:PATH "src/wal/executor.lisp" :GIT-BLOB
     "932eb39a61d9cf66d9394a25dac0e3912c3e3811")
    (:PATH "src/wal/group.lisp" :GIT-BLOB
     "ad43e8547f4b148116c00be5801ad82790240ff2")
    (:PATH "src/wal/package.lisp" :GIT-BLOB
     "608fca13f42115e74941bcbbe359d9541126c050")
    (:PATH "src/wal/types.lisp" :GIT-BLOB
     "adcfd153cb55c0c30d0ff7b610702315fc3cf485")
    (:PATH "tests/foundation/batch.lisp" :GIT-BLOB
     "00bb40ad87340ee86f5da281c09207c8da8888a6")
    (:PATH "tests/foundation/binary.lisp" :GIT-BLOB
     "ff6df200a7ace3af204b622969a387ce7a1e1504")
    (:PATH "tests/foundation/record.lisp" :GIT-BLOB
     "5c7c0d619e9637af6704ec51d564bbfdbc0df551")
    (:PATH "tests/foundation/support.lisp" :GIT-BLOB
     "d383b1cddf929ba0340d1b74eec3ec03673eac09")
    (:PATH "tests/io/native.lisp" :GIT-BLOB
     "bb3f9a460953d5575d7333b8b6eef6ecdb8e1e7d")
    (:PATH "tests/io/support.lisp" :GIT-BLOB
     "0179a0c19bdde944f47fe83716ecc6241e37c686")
    (:PATH "tests/io/transfer.lisp" :GIT-BLOB
     "40c8f4d5e2d493db090d5d09ab024c67ca6f4037")
    (:PATH "tests/lint-fixtures/bad.lisp" :GIT-BLOB
     "d0d5fd7285428e569d3dd595a0c38de5211e10a5")
    (:PATH "tests/lint-fixtures/good.lisp" :GIT-BLOB
     "35558ab0ab2be7688e9fd55a38be44ebe9a57f37")
    (:PATH "tests/recovery/corruption.lisp" :GIT-BLOB
     "2f9ead22a4e3b45cb3a680aa3a32a94bfcc6d77f")
    (:PATH "tests/recovery/decisions-audit.lisp" :GIT-BLOB
     "1b79a76515d8b8c2e67c46700cd6968b40047d62")
    (:PATH "tests/recovery/decisions-radix.lisp" :GIT-BLOB
     "232312cdd4ed6b1efcedc33ddda0fd8d1d8545d7")
    (:PATH "tests/recovery/decisions-support.lisp" :GIT-BLOB
     "f67450a9d681512a4b66efe1af1bfc82180e0058")
    (:PATH "tests/recovery/decisions.lisp" :GIT-BLOB
     "28d04d8738f077bf21ac22393a4014b518a6a0f2")
    (:PATH "tests/recovery/scan.lisp" :GIT-BLOB
     "1c7d71c32d58b05f7e06450680270cb55f6325dc")
    (:PATH "tests/recovery/support.lisp" :GIT-BLOB
     "f784671c59065b4363bcc5e49f06559b11e6562c")
    (:PATH "tests/smoke.lisp" :GIT-BLOB
     "6bd4ab9af1f3d9eedd54822eae10b7f167aa99ed")
    (:PATH "tests/storage/compaction-scan.lisp" :GIT-BLOB
     "16e5c9e5231883844ecd7956c7f790349acd2a05")
    (:PATH "tests/storage/control-payload.lisp" :GIT-BLOB
     "72358c6f324e1c7aaab2bb2c9d03d39ccf78f664")
    (:PATH "tests/storage/log-header.lisp" :GIT-BLOB
     "b3c4c96603ee769429b847569559defda5059744")
    (:PATH "tests/storage/segment-header.lisp" :GIT-BLOB
     "7155aaf2e9c0df4f96533a0be0f6532b54f44590")
    (:PATH "tests/storage/support.lisp" :GIT-BLOB
     "6aa5df3b3cc62b552f5da890583654b82df99431")
    (:PATH "tests/wal/builder.lisp" :GIT-BLOB
     "d62777cd09f8c30fc7246f59fd1bca8ea80c4559")
    (:PATH "tests/wal/fault.lisp" :GIT-BLOB
     "6361a87d73ce90f78438008693a7cd9d6461fe9b")
    (:PATH "tests/wal/group.lisp" :GIT-BLOB
     "04281d9ea3837ed2af0e7fa33b7e17df814982d7")
    (:PATH "tests/wal/native.lisp" :GIT-BLOB
     "077a835fb47524d97e449ae87c74461ebb374653")
    (:PATH "tests/wal/support.lisp" :GIT-BLOB
     "638262b264c64b96774ddb0a6095f4e582debe3e")))
  (:NAME "decision-last-id-byte" :RESULT :DETECTED :EXIT-CODE 1 :ARGV
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/decisions-radix-isolated-build.lisp")
   :LOG
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/4/test.log"
    :GIT-BLOB "e0da098ae2c3fe753990f7f24ae8e5133edd33b6" :TEXT
    "decision-test-start TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
Unhandled CORRUPTION-DETECTED in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                           {8005B00003}>:
  ArcDocDB: DECISION-DUPLICATE-PARTICIPANT all'offset 71

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005B00003}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<CORRUPTION-DETECTED {800722D153}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<CORRUPTION-DETECTED {800722D153}>)
2: (INVOKE-DEBUGGER #<CORRUPTION-DETECTED {800722D153}>)
3: (ERROR CORRUPTION-DETECTED :REASON :DECISION-DUPLICATE-PARTICIPANT :OFFSET 71)
4: (ARCDOCDB.RECOVERY.DECISIONS::CHECK-PARTICIPANT-ORDER #(0 0 0 0 0 0 0 0 0 0 0 0 ...) 3 71)
5: (ARCDOCDB.RECOVERY.DECISIONS::SORT-PARTICIPANTS #(0 0 0 0 0 0 0 0 0 0 0 0 ...) 3 71)
6: (ARCDOCDB.RECOVERY.DECISIONS::DECODE-DECISIONS #(204 204 204 204 204 204 204 58 152 247 120 39 ...) 7 145 1 2 1 3 65535 64)
7: (ARCDOCDB.RECOVERY.DECISIONS:RICOSTRUISCI-DECISIONI #(204 204 204 204 204 204 204 58 152 247 120 39 ...) 7 145 :VERSION 1 :FILE-OFFSET 64 :FILE-SIZE 209 :MAX-BYTES 67108864 :MAX-BATCHES 65536 :MAX-BATCH-RECORDS 65536 :MAX-BATCH-BYTES 67108864 :MAX-SEARCH-BYTES 67108864 :MAX-DECISIONS 65536 :MAX-PARTICIPANTS 65536 :MAX-PARTICIPANTS-PER-DECISION 65535)
8: (TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE)
9: (\"top level form\") [toplevel]
10: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
11: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL T T)
12: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL)
13: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
14: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
15: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3 NIL)
16: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3)
17: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 3)
18: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107350F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
19: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/4/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
20: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/4/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
21: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1073509EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/4/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/4/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
22: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/4/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
23: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/4/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
24: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/4/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
25: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
26: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
27: (SB-IMPL::PROCESS-SCRIPT \"tools/decisions-radix-isolated-build.lisp\")
28: (SB-IMPL::TOPLEVEL-INIT)
29: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
30: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
31: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
   :RUNNER
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/4/tools/decisions-radix-isolated-build.lisp"
    :GIT-BLOB "f345ccd265e0eebbba7e7c0dc7dc02a817388443" :TEXT "(REQUIRE :ASDF)
(SETF UIOP/CONFIGURATION:*USER-CACHE* (MERGE-PATHNAMES \"fasl/\" (TRUENAME \"./\"))
      UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (FILES
        '(\"tests/recovery/decisions.lisp\"
          \"tests/recovery/decisions-audit.lisp\"))
       (TESTS NIL))
  (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\")
    (UNLESS
        (ASDF/COMPONENT:FIND-COMPONENT
         (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\")
         '(\"recovery\" \"decisions-radix\"))
      (ERROR \"Test radix presente ma non registrato in ASDF.\"))
    (SETF FILES (APPEND FILES '(\"tests/recovery/decisions-radix.lisp\"))))
  (DOLIST (FILE FILES)
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test DECISION: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test DECISION non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&decision-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH TESTS)))
")
   :SOURCE-BLOBS
   ((:PATH "src/foundation/batch.lisp" :GIT-BLOB
     "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
    (:PATH "src/foundation/binary.lisp" :GIT-BLOB
     "2d514f6fe2e81eecb29fa53de611fa5e28696904")
    (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
     "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
    (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
     "f9c691d28620427099d1d89a89a1ff5d04cbe257")
    (:PATH "src/foundation/package.lisp" :GIT-BLOB
     "0658b083f1e777aa0ada67a63535d36946921eac")
    (:PATH "src/foundation/record.lisp" :GIT-BLOB
     "8df53d416747131d9ed9921abb4ef356d9ce5696")
    (:PATH "src/io/flush.lisp" :GIT-BLOB
     "ba31b07379219fa8fd80fca169d43a053d28063b")
    (:PATH "src/io/lifecycle.lisp" :GIT-BLOB
     "0b93448ffe9c6dd4f3a0a2f3f35d5cd656700bd7")
    (:PATH "src/io/native.lisp" :GIT-BLOB
     "1b6fe64ea7145f33bcf08c02e8550034ebd6a40c")
    (:PATH "src/io/package.lisp" :GIT-BLOB
     "6b840a0eb039afa7e55304bffba309f0ab72acdc")
    (:PATH "src/io/transfer.lisp" :GIT-BLOB
     "93acbd608b1af475aa505a6a7dedceb3b15e8d4b")
    (:PATH "src/io/types.lisp" :GIT-BLOB
     "b496c1df87108127da568a1fb7b0fd32856afcc5")
    (:PATH "src/package.lisp" :GIT-BLOB
     "3d0181717e3f334580bab9a6a507e2dfe57261ff")
    (:PATH "src/recovery/decisions-build.lisp" :GIT-BLOB
     "87cc54024e59757c16e20f3025970b1699b11662")
    (:PATH "src/recovery/decisions-package.lisp" :GIT-BLOB
     "878fd1afdcbf035a232166ef87066af4420e1aae")
    (:PATH "src/recovery/decisions-query.lisp" :GIT-BLOB
     "a6ce94b8be3c8c84043abfd6441599f9780b2c11")
    (:PATH "src/recovery/decisions-radix.lisp" :GIT-BLOB
     "e58176890a26751bf5767582b279cb667a29744e")
    (:PATH "src/recovery/decisions-sort.lisp" :GIT-BLOB
     "b976547c4abf7810c7d8d285f89ba948f0d66f5e")
    (:PATH "src/recovery/decisions-types.lisp" :GIT-BLOB
     "0dbb2b3bdfbf5447a5904ce0fa6e4a97337a6827")
    (:PATH "src/recovery/package.lisp" :GIT-BLOB
     "b97b5c9bca6955e5dc45d9d4257089ab7132f3fb")
    (:PATH "src/recovery/scan.lisp" :GIT-BLOB
     "7ad6b7541397611f1ecbda7dffdda98c4453dbf1")
    (:PATH "src/storage/compaction-scan.lisp" :GIT-BLOB
     "233556c366a99b7b263af1c7bc19b47ceaebf940")
    (:PATH "src/storage/control-payload.lisp" :GIT-BLOB
     "7980cac6cc8070836b9aa49fc8a0d6fb42630749")
    (:PATH "src/storage/formats.lisp" :GIT-BLOB
     "fc942f1c8e30e637abaf13dc26343d40417fc72f")
    (:PATH "src/storage/log-header.lisp" :GIT-BLOB
     "fde8608e6ad3fe062937c48bdcb7d2d5870207bf")
    (:PATH "src/storage/package.lisp" :GIT-BLOB
     "c15553a65171e5dfb2dbadb62c92ed4dc48aee3a")
    (:PATH "src/storage/payload-record.lisp" :GIT-BLOB
     "0012eaf90064c4cc2949834a60e83c9db8ba6308")
    (:PATH "src/storage/payload-write.lisp" :GIT-BLOB
     "6cbbb89f681965173e9b1b95edf3f7f870af1eca")
    (:PATH "src/storage/segment-header.lisp" :GIT-BLOB
     "f1d99b205b1ea5e6ad059ecd7971d3633411b040")
    (:PATH "src/wal/builder.lisp" :GIT-BLOB
     "a488813eca3f6dcd251affd2017162861cd729d3")
    (:PATH "src/wal/executor.lisp" :GIT-BLOB
     "932eb39a61d9cf66d9394a25dac0e3912c3e3811")
    (:PATH "src/wal/group.lisp" :GIT-BLOB
     "ad43e8547f4b148116c00be5801ad82790240ff2")
    (:PATH "src/wal/package.lisp" :GIT-BLOB
     "608fca13f42115e74941bcbbe359d9541126c050")
    (:PATH "src/wal/types.lisp" :GIT-BLOB
     "adcfd153cb55c0c30d0ff7b610702315fc3cf485")
    (:PATH "tests/foundation/batch.lisp" :GIT-BLOB
     "00bb40ad87340ee86f5da281c09207c8da8888a6")
    (:PATH "tests/foundation/binary.lisp" :GIT-BLOB
     "ff6df200a7ace3af204b622969a387ce7a1e1504")
    (:PATH "tests/foundation/record.lisp" :GIT-BLOB
     "5c7c0d619e9637af6704ec51d564bbfdbc0df551")
    (:PATH "tests/foundation/support.lisp" :GIT-BLOB
     "d383b1cddf929ba0340d1b74eec3ec03673eac09")
    (:PATH "tests/io/native.lisp" :GIT-BLOB
     "bb3f9a460953d5575d7333b8b6eef6ecdb8e1e7d")
    (:PATH "tests/io/support.lisp" :GIT-BLOB
     "0179a0c19bdde944f47fe83716ecc6241e37c686")
    (:PATH "tests/io/transfer.lisp" :GIT-BLOB
     "40c8f4d5e2d493db090d5d09ab024c67ca6f4037")
    (:PATH "tests/lint-fixtures/bad.lisp" :GIT-BLOB
     "d0d5fd7285428e569d3dd595a0c38de5211e10a5")
    (:PATH "tests/lint-fixtures/good.lisp" :GIT-BLOB
     "35558ab0ab2be7688e9fd55a38be44ebe9a57f37")
    (:PATH "tests/recovery/corruption.lisp" :GIT-BLOB
     "2f9ead22a4e3b45cb3a680aa3a32a94bfcc6d77f")
    (:PATH "tests/recovery/decisions-audit.lisp" :GIT-BLOB
     "1b79a76515d8b8c2e67c46700cd6968b40047d62")
    (:PATH "tests/recovery/decisions-radix.lisp" :GIT-BLOB
     "232312cdd4ed6b1efcedc33ddda0fd8d1d8545d7")
    (:PATH "tests/recovery/decisions-support.lisp" :GIT-BLOB
     "f67450a9d681512a4b66efe1af1bfc82180e0058")
    (:PATH "tests/recovery/decisions.lisp" :GIT-BLOB
     "28d04d8738f077bf21ac22393a4014b518a6a0f2")
    (:PATH "tests/recovery/scan.lisp" :GIT-BLOB
     "1c7d71c32d58b05f7e06450680270cb55f6325dc")
    (:PATH "tests/recovery/support.lisp" :GIT-BLOB
     "f784671c59065b4363bcc5e49f06559b11e6562c")
    (:PATH "tests/smoke.lisp" :GIT-BLOB
     "6bd4ab9af1f3d9eedd54822eae10b7f167aa99ed")
    (:PATH "tests/storage/compaction-scan.lisp" :GIT-BLOB
     "16e5c9e5231883844ecd7956c7f790349acd2a05")
    (:PATH "tests/storage/control-payload.lisp" :GIT-BLOB
     "72358c6f324e1c7aaab2bb2c9d03d39ccf78f664")
    (:PATH "tests/storage/log-header.lisp" :GIT-BLOB
     "b3c4c96603ee769429b847569559defda5059744")
    (:PATH "tests/storage/segment-header.lisp" :GIT-BLOB
     "7155aaf2e9c0df4f96533a0be0f6532b54f44590")
    (:PATH "tests/storage/support.lisp" :GIT-BLOB
     "6aa5df3b3cc62b552f5da890583654b82df99431")
    (:PATH "tests/wal/builder.lisp" :GIT-BLOB
     "d62777cd09f8c30fc7246f59fd1bca8ea80c4559")
    (:PATH "tests/wal/fault.lisp" :GIT-BLOB
     "6361a87d73ce90f78438008693a7cd9d6461fe9b")
    (:PATH "tests/wal/group.lisp" :GIT-BLOB
     "04281d9ea3837ed2af0e7fa33b7e17df814982d7")
    (:PATH "tests/wal/native.lisp" :GIT-BLOB
     "077a835fb47524d97e449ae87c74461ebb374653")
    (:PATH "tests/wal/support.lisp" :GIT-BLOB
     "638262b264c64b96774ddb0a6095f4e582debe3e")))
  (:NAME "decision-missing-found" :RESULT :DETECTED :EXIT-CODE 1 :ARGV
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/decisions-radix-isolated-build.lisp")
   :LOG
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/5/test.log"
    :GIT-BLOB "7fc0877fe516f030a9fa6f837bcf84446b7a8771" :TEXT
    "decision-test-start TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {8005AD0393}>:
  Asserzione recovery fallita: (EQUAL '(NIL 0 0)
                                      (MULTIPLE-VALUE-LIST
                                       (ARCDOCDB.RECOVERY.DECISIONS:TROVA-DECISIONE
                                        TABLE TXID)))

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005AD0393}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8007245573}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8007245573}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8007245573}>)
3: (ERROR \"Asserzione recovery fallita: ~S\" (EQUAL (QUOTE (NIL 0 0)) (MULTIPLE-VALUE-LIST (ARCDOCDB.RECOVERY.DECISIONS:TROVA-DECISIONE TABLE TXID))))
4: (ASSERT-DECISION-TABLE #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-TABLE :ENTRIES #()) NIL (0 49 51 1024 1025))
5: (TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE)
6: (\"top level form\") [toplevel]
7: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
8: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL T T)
9: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL)
10: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
11: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
12: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3 NIL)
13: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3)
14: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 3)
15: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1054D0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
16: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/5/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
17: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/5/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
18: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1054D09EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/5/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/5/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
19: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/5/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
20: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/5/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
21: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/5/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
22: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
23: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
24: (SB-IMPL::PROCESS-SCRIPT \"tools/decisions-radix-isolated-build.lisp\")
25: (SB-IMPL::TOPLEVEL-INIT)
26: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
27: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
28: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
   :RUNNER
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/5/tools/decisions-radix-isolated-build.lisp"
    :GIT-BLOB "f345ccd265e0eebbba7e7c0dc7dc02a817388443" :TEXT "(REQUIRE :ASDF)
(SETF UIOP/CONFIGURATION:*USER-CACHE* (MERGE-PATHNAMES \"fasl/\" (TRUENAME \"./\"))
      UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (FILES
        '(\"tests/recovery/decisions.lisp\"
          \"tests/recovery/decisions-audit.lisp\"))
       (TESTS NIL))
  (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\")
    (UNLESS
        (ASDF/COMPONENT:FIND-COMPONENT
         (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\")
         '(\"recovery\" \"decisions-radix\"))
      (ERROR \"Test radix presente ma non registrato in ASDF.\"))
    (SETF FILES (APPEND FILES '(\"tests/recovery/decisions-radix.lisp\"))))
  (DOLIST (FILE FILES)
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test DECISION: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test DECISION non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&decision-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH TESTS)))
")
   :SOURCE-BLOBS
   ((:PATH "src/foundation/batch.lisp" :GIT-BLOB
     "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
    (:PATH "src/foundation/binary.lisp" :GIT-BLOB
     "2d514f6fe2e81eecb29fa53de611fa5e28696904")
    (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
     "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
    (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
     "f9c691d28620427099d1d89a89a1ff5d04cbe257")
    (:PATH "src/foundation/package.lisp" :GIT-BLOB
     "0658b083f1e777aa0ada67a63535d36946921eac")
    (:PATH "src/foundation/record.lisp" :GIT-BLOB
     "8df53d416747131d9ed9921abb4ef356d9ce5696")
    (:PATH "src/io/flush.lisp" :GIT-BLOB
     "ba31b07379219fa8fd80fca169d43a053d28063b")
    (:PATH "src/io/lifecycle.lisp" :GIT-BLOB
     "0b93448ffe9c6dd4f3a0a2f3f35d5cd656700bd7")
    (:PATH "src/io/native.lisp" :GIT-BLOB
     "1b6fe64ea7145f33bcf08c02e8550034ebd6a40c")
    (:PATH "src/io/package.lisp" :GIT-BLOB
     "6b840a0eb039afa7e55304bffba309f0ab72acdc")
    (:PATH "src/io/transfer.lisp" :GIT-BLOB
     "93acbd608b1af475aa505a6a7dedceb3b15e8d4b")
    (:PATH "src/io/types.lisp" :GIT-BLOB
     "b496c1df87108127da568a1fb7b0fd32856afcc5")
    (:PATH "src/package.lisp" :GIT-BLOB
     "3d0181717e3f334580bab9a6a507e2dfe57261ff")
    (:PATH "src/recovery/decisions-build.lisp" :GIT-BLOB
     "87cc54024e59757c16e20f3025970b1699b11662")
    (:PATH "src/recovery/decisions-package.lisp" :GIT-BLOB
     "878fd1afdcbf035a232166ef87066af4420e1aae")
    (:PATH "src/recovery/decisions-query.lisp" :GIT-BLOB
     "ceec2f8ede4ef2655d59ab2a683d4a403a9786e2")
    (:PATH "src/recovery/decisions-radix.lisp" :GIT-BLOB
     "e58176890a26751bf5767582b279cb667a29744e")
    (:PATH "src/recovery/decisions-sort.lisp" :GIT-BLOB
     "b133ea00a3b8063e9e934a1b41f10cad024471ae")
    (:PATH "src/recovery/decisions-types.lisp" :GIT-BLOB
     "0dbb2b3bdfbf5447a5904ce0fa6e4a97337a6827")
    (:PATH "src/recovery/package.lisp" :GIT-BLOB
     "b97b5c9bca6955e5dc45d9d4257089ab7132f3fb")
    (:PATH "src/recovery/scan.lisp" :GIT-BLOB
     "7ad6b7541397611f1ecbda7dffdda98c4453dbf1")
    (:PATH "src/storage/compaction-scan.lisp" :GIT-BLOB
     "233556c366a99b7b263af1c7bc19b47ceaebf940")
    (:PATH "src/storage/control-payload.lisp" :GIT-BLOB
     "7980cac6cc8070836b9aa49fc8a0d6fb42630749")
    (:PATH "src/storage/formats.lisp" :GIT-BLOB
     "fc942f1c8e30e637abaf13dc26343d40417fc72f")
    (:PATH "src/storage/log-header.lisp" :GIT-BLOB
     "fde8608e6ad3fe062937c48bdcb7d2d5870207bf")
    (:PATH "src/storage/package.lisp" :GIT-BLOB
     "c15553a65171e5dfb2dbadb62c92ed4dc48aee3a")
    (:PATH "src/storage/payload-record.lisp" :GIT-BLOB
     "0012eaf90064c4cc2949834a60e83c9db8ba6308")
    (:PATH "src/storage/payload-write.lisp" :GIT-BLOB
     "6cbbb89f681965173e9b1b95edf3f7f870af1eca")
    (:PATH "src/storage/segment-header.lisp" :GIT-BLOB
     "f1d99b205b1ea5e6ad059ecd7971d3633411b040")
    (:PATH "src/wal/builder.lisp" :GIT-BLOB
     "a488813eca3f6dcd251affd2017162861cd729d3")
    (:PATH "src/wal/executor.lisp" :GIT-BLOB
     "932eb39a61d9cf66d9394a25dac0e3912c3e3811")
    (:PATH "src/wal/group.lisp" :GIT-BLOB
     "ad43e8547f4b148116c00be5801ad82790240ff2")
    (:PATH "src/wal/package.lisp" :GIT-BLOB
     "608fca13f42115e74941bcbbe359d9541126c050")
    (:PATH "src/wal/types.lisp" :GIT-BLOB
     "adcfd153cb55c0c30d0ff7b610702315fc3cf485")
    (:PATH "tests/foundation/batch.lisp" :GIT-BLOB
     "00bb40ad87340ee86f5da281c09207c8da8888a6")
    (:PATH "tests/foundation/binary.lisp" :GIT-BLOB
     "ff6df200a7ace3af204b622969a387ce7a1e1504")
    (:PATH "tests/foundation/record.lisp" :GIT-BLOB
     "5c7c0d619e9637af6704ec51d564bbfdbc0df551")
    (:PATH "tests/foundation/support.lisp" :GIT-BLOB
     "d383b1cddf929ba0340d1b74eec3ec03673eac09")
    (:PATH "tests/io/native.lisp" :GIT-BLOB
     "bb3f9a460953d5575d7333b8b6eef6ecdb8e1e7d")
    (:PATH "tests/io/support.lisp" :GIT-BLOB
     "0179a0c19bdde944f47fe83716ecc6241e37c686")
    (:PATH "tests/io/transfer.lisp" :GIT-BLOB
     "40c8f4d5e2d493db090d5d09ab024c67ca6f4037")
    (:PATH "tests/lint-fixtures/bad.lisp" :GIT-BLOB
     "d0d5fd7285428e569d3dd595a0c38de5211e10a5")
    (:PATH "tests/lint-fixtures/good.lisp" :GIT-BLOB
     "35558ab0ab2be7688e9fd55a38be44ebe9a57f37")
    (:PATH "tests/recovery/corruption.lisp" :GIT-BLOB
     "2f9ead22a4e3b45cb3a680aa3a32a94bfcc6d77f")
    (:PATH "tests/recovery/decisions-audit.lisp" :GIT-BLOB
     "1b79a76515d8b8c2e67c46700cd6968b40047d62")
    (:PATH "tests/recovery/decisions-radix.lisp" :GIT-BLOB
     "232312cdd4ed6b1efcedc33ddda0fd8d1d8545d7")
    (:PATH "tests/recovery/decisions-support.lisp" :GIT-BLOB
     "f67450a9d681512a4b66efe1af1bfc82180e0058")
    (:PATH "tests/recovery/decisions.lisp" :GIT-BLOB
     "28d04d8738f077bf21ac22393a4014b518a6a0f2")
    (:PATH "tests/recovery/scan.lisp" :GIT-BLOB
     "1c7d71c32d58b05f7e06450680270cb55f6325dc")
    (:PATH "tests/recovery/support.lisp" :GIT-BLOB
     "f784671c59065b4363bcc5e49f06559b11e6562c")
    (:PATH "tests/smoke.lisp" :GIT-BLOB
     "6bd4ab9af1f3d9eedd54822eae10b7f167aa99ed")
    (:PATH "tests/storage/compaction-scan.lisp" :GIT-BLOB
     "16e5c9e5231883844ecd7956c7f790349acd2a05")
    (:PATH "tests/storage/control-payload.lisp" :GIT-BLOB
     "72358c6f324e1c7aaab2bb2c9d03d39ccf78f664")
    (:PATH "tests/storage/log-header.lisp" :GIT-BLOB
     "b3c4c96603ee769429b847569559defda5059744")
    (:PATH "tests/storage/segment-header.lisp" :GIT-BLOB
     "7155aaf2e9c0df4f96533a0be0f6532b54f44590")
    (:PATH "tests/storage/support.lisp" :GIT-BLOB
     "6aa5df3b3cc62b552f5da890583654b82df99431")
    (:PATH "tests/wal/builder.lisp" :GIT-BLOB
     "d62777cd09f8c30fc7246f59fd1bca8ea80c4559")
    (:PATH "tests/wal/fault.lisp" :GIT-BLOB
     "6361a87d73ce90f78438008693a7cd9d6461fe9b")
    (:PATH "tests/wal/group.lisp" :GIT-BLOB
     "04281d9ea3837ed2af0e7fa33b7e17df814982d7")
    (:PATH "tests/wal/native.lisp" :GIT-BLOB
     "077a835fb47524d97e449ae87c74461ebb374653")
    (:PATH "tests/wal/support.lisp" :GIT-BLOB
     "638262b264c64b96774ddb0a6095f4e582debe3e")))
  (:NAME "decision-set-conflict" :RESULT :DETECTED :EXIT-CODE 1 :ARGV
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/decisions-radix-isolated-build.lisp")
   :LOG
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/6/test.log"
    :GIT-BLOB "80166cd43613cd4138714b421f0e4886977f137c" :TEXT
    "decision-test-start TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
ok    TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
decision-test-start TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
ok    TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
decision-test-start TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
ok    TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
decision-test-start TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
ok    TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
ok    TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
decision-test-start TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {8005AD0423}>:
  Asserzione recovery fallita: (TYPEP CONDITION 'CORRUPTION-DETECTED)

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005AD0423}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8007368D13}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8007368D13}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione recovery fallita: ~S\" {8007368D13}>)
3: (ERROR \"Asserzione recovery fallita: ~S\" (TYPEP CONDITION (QUOTE CORRUPTION-DETECTED)))
4: (TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT)
5: (\"top level form\") [toplevel]
6: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
7: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL T T)
8: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL)
9: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
10: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
11: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3 NIL)
12: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3)
13: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 3)
14: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107B60F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
15: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/6/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
16: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/6/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
17: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {107B609EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/6/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/6/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
18: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/6/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
19: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/6/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
20: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/6/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
21: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
22: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
23: (SB-IMPL::PROCESS-SCRIPT \"tools/decisions-radix-isolated-build.lisp\")
24: (SB-IMPL::TOPLEVEL-INIT)
25: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
26: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
27: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
   :RUNNER
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/6/tools/decisions-radix-isolated-build.lisp"
    :GIT-BLOB "f345ccd265e0eebbba7e7c0dc7dc02a817388443" :TEXT "(REQUIRE :ASDF)
(SETF UIOP/CONFIGURATION:*USER-CACHE* (MERGE-PATHNAMES \"fasl/\" (TRUENAME \"./\"))
      UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (FILES
        '(\"tests/recovery/decisions.lisp\"
          \"tests/recovery/decisions-audit.lisp\"))
       (TESTS NIL))
  (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\")
    (UNLESS
        (ASDF/COMPONENT:FIND-COMPONENT
         (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\")
         '(\"recovery\" \"decisions-radix\"))
      (ERROR \"Test radix presente ma non registrato in ASDF.\"))
    (SETF FILES (APPEND FILES '(\"tests/recovery/decisions-radix.lisp\"))))
  (DOLIST (FILE FILES)
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test DECISION: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test DECISION non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&decision-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH TESTS)))
")
   :SOURCE-BLOBS
   ((:PATH "src/foundation/batch.lisp" :GIT-BLOB
     "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
    (:PATH "src/foundation/binary.lisp" :GIT-BLOB
     "2d514f6fe2e81eecb29fa53de611fa5e28696904")
    (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
     "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
    (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
     "f9c691d28620427099d1d89a89a1ff5d04cbe257")
    (:PATH "src/foundation/package.lisp" :GIT-BLOB
     "0658b083f1e777aa0ada67a63535d36946921eac")
    (:PATH "src/foundation/record.lisp" :GIT-BLOB
     "8df53d416747131d9ed9921abb4ef356d9ce5696")
    (:PATH "src/io/flush.lisp" :GIT-BLOB
     "ba31b07379219fa8fd80fca169d43a053d28063b")
    (:PATH "src/io/lifecycle.lisp" :GIT-BLOB
     "0b93448ffe9c6dd4f3a0a2f3f35d5cd656700bd7")
    (:PATH "src/io/native.lisp" :GIT-BLOB
     "1b6fe64ea7145f33bcf08c02e8550034ebd6a40c")
    (:PATH "src/io/package.lisp" :GIT-BLOB
     "6b840a0eb039afa7e55304bffba309f0ab72acdc")
    (:PATH "src/io/transfer.lisp" :GIT-BLOB
     "93acbd608b1af475aa505a6a7dedceb3b15e8d4b")
    (:PATH "src/io/types.lisp" :GIT-BLOB
     "b496c1df87108127da568a1fb7b0fd32856afcc5")
    (:PATH "src/package.lisp" :GIT-BLOB
     "3d0181717e3f334580bab9a6a507e2dfe57261ff")
    (:PATH "src/recovery/decisions-build.lisp" :GIT-BLOB
     "9e2e8e15518c432c3cb9768cf834526119c47e9e")
    (:PATH "src/recovery/decisions-package.lisp" :GIT-BLOB
     "878fd1afdcbf035a232166ef87066af4420e1aae")
    (:PATH "src/recovery/decisions-query.lisp" :GIT-BLOB
     "a6ce94b8be3c8c84043abfd6441599f9780b2c11")
    (:PATH "src/recovery/decisions-radix.lisp" :GIT-BLOB
     "e58176890a26751bf5767582b279cb667a29744e")
    (:PATH "src/recovery/decisions-sort.lisp" :GIT-BLOB
     "b133ea00a3b8063e9e934a1b41f10cad024471ae")
    (:PATH "src/recovery/decisions-types.lisp" :GIT-BLOB
     "0dbb2b3bdfbf5447a5904ce0fa6e4a97337a6827")
    (:PATH "src/recovery/package.lisp" :GIT-BLOB
     "b97b5c9bca6955e5dc45d9d4257089ab7132f3fb")
    (:PATH "src/recovery/scan.lisp" :GIT-BLOB
     "7ad6b7541397611f1ecbda7dffdda98c4453dbf1")
    (:PATH "src/storage/compaction-scan.lisp" :GIT-BLOB
     "233556c366a99b7b263af1c7bc19b47ceaebf940")
    (:PATH "src/storage/control-payload.lisp" :GIT-BLOB
     "7980cac6cc8070836b9aa49fc8a0d6fb42630749")
    (:PATH "src/storage/formats.lisp" :GIT-BLOB
     "fc942f1c8e30e637abaf13dc26343d40417fc72f")
    (:PATH "src/storage/log-header.lisp" :GIT-BLOB
     "fde8608e6ad3fe062937c48bdcb7d2d5870207bf")
    (:PATH "src/storage/package.lisp" :GIT-BLOB
     "c15553a65171e5dfb2dbadb62c92ed4dc48aee3a")
    (:PATH "src/storage/payload-record.lisp" :GIT-BLOB
     "0012eaf90064c4cc2949834a60e83c9db8ba6308")
    (:PATH "src/storage/payload-write.lisp" :GIT-BLOB
     "6cbbb89f681965173e9b1b95edf3f7f870af1eca")
    (:PATH "src/storage/segment-header.lisp" :GIT-BLOB
     "f1d99b205b1ea5e6ad059ecd7971d3633411b040")
    (:PATH "src/wal/builder.lisp" :GIT-BLOB
     "a488813eca3f6dcd251affd2017162861cd729d3")
    (:PATH "src/wal/executor.lisp" :GIT-BLOB
     "932eb39a61d9cf66d9394a25dac0e3912c3e3811")
    (:PATH "src/wal/group.lisp" :GIT-BLOB
     "ad43e8547f4b148116c00be5801ad82790240ff2")
    (:PATH "src/wal/package.lisp" :GIT-BLOB
     "608fca13f42115e74941bcbbe359d9541126c050")
    (:PATH "src/wal/types.lisp" :GIT-BLOB
     "adcfd153cb55c0c30d0ff7b610702315fc3cf485")
    (:PATH "tests/foundation/batch.lisp" :GIT-BLOB
     "00bb40ad87340ee86f5da281c09207c8da8888a6")
    (:PATH "tests/foundation/binary.lisp" :GIT-BLOB
     "ff6df200a7ace3af204b622969a387ce7a1e1504")
    (:PATH "tests/foundation/record.lisp" :GIT-BLOB
     "5c7c0d619e9637af6704ec51d564bbfdbc0df551")
    (:PATH "tests/foundation/support.lisp" :GIT-BLOB
     "d383b1cddf929ba0340d1b74eec3ec03673eac09")
    (:PATH "tests/io/native.lisp" :GIT-BLOB
     "bb3f9a460953d5575d7333b8b6eef6ecdb8e1e7d")
    (:PATH "tests/io/support.lisp" :GIT-BLOB
     "0179a0c19bdde944f47fe83716ecc6241e37c686")
    (:PATH "tests/io/transfer.lisp" :GIT-BLOB
     "40c8f4d5e2d493db090d5d09ab024c67ca6f4037")
    (:PATH "tests/lint-fixtures/bad.lisp" :GIT-BLOB
     "d0d5fd7285428e569d3dd595a0c38de5211e10a5")
    (:PATH "tests/lint-fixtures/good.lisp" :GIT-BLOB
     "35558ab0ab2be7688e9fd55a38be44ebe9a57f37")
    (:PATH "tests/recovery/corruption.lisp" :GIT-BLOB
     "2f9ead22a4e3b45cb3a680aa3a32a94bfcc6d77f")
    (:PATH "tests/recovery/decisions-audit.lisp" :GIT-BLOB
     "1b79a76515d8b8c2e67c46700cd6968b40047d62")
    (:PATH "tests/recovery/decisions-radix.lisp" :GIT-BLOB
     "232312cdd4ed6b1efcedc33ddda0fd8d1d8545d7")
    (:PATH "tests/recovery/decisions-support.lisp" :GIT-BLOB
     "f67450a9d681512a4b66efe1af1bfc82180e0058")
    (:PATH "tests/recovery/decisions.lisp" :GIT-BLOB
     "28d04d8738f077bf21ac22393a4014b518a6a0f2")
    (:PATH "tests/recovery/scan.lisp" :GIT-BLOB
     "1c7d71c32d58b05f7e06450680270cb55f6325dc")
    (:PATH "tests/recovery/support.lisp" :GIT-BLOB
     "f784671c59065b4363bcc5e49f06559b11e6562c")
    (:PATH "tests/smoke.lisp" :GIT-BLOB
     "6bd4ab9af1f3d9eedd54822eae10b7f167aa99ed")
    (:PATH "tests/storage/compaction-scan.lisp" :GIT-BLOB
     "16e5c9e5231883844ecd7956c7f790349acd2a05")
    (:PATH "tests/storage/control-payload.lisp" :GIT-BLOB
     "72358c6f324e1c7aaab2bb2c9d03d39ccf78f664")
    (:PATH "tests/storage/log-header.lisp" :GIT-BLOB
     "b3c4c96603ee769429b847569559defda5059744")
    (:PATH "tests/storage/segment-header.lisp" :GIT-BLOB
     "7155aaf2e9c0df4f96533a0be0f6532b54f44590")
    (:PATH "tests/storage/support.lisp" :GIT-BLOB
     "6aa5df3b3cc62b552f5da890583654b82df99431")
    (:PATH "tests/wal/builder.lisp" :GIT-BLOB
     "d62777cd09f8c30fc7246f59fd1bca8ea80c4559")
    (:PATH "tests/wal/fault.lisp" :GIT-BLOB
     "6361a87d73ce90f78438008693a7cd9d6461fe9b")
    (:PATH "tests/wal/group.lisp" :GIT-BLOB
     "04281d9ea3837ed2af0e7fa33b7e17df814982d7")
    (:PATH "tests/wal/native.lisp" :GIT-BLOB
     "077a835fb47524d97e449ae87c74461ebb374653")
    (:PATH "tests/wal/support.lisp" :GIT-BLOB
     "638262b264c64b96774ddb0a6095f4e582debe3e")))
  (:NAME "radix-id-msd-first" :RESULT :DETECTED :EXIT-CODE 1 :ARGV
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/decisions-radix-isolated-build.lisp")
   :LOG
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/7/test.log"
    :GIT-BLOB "ff7df505961b8e81f6e43056904d3960e897bafc" :TEXT
    "decision-test-start TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
ok    TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
decision-test-start TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
ok    TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
decision-test-start TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
ok    TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
decision-test-start TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
ok    TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
ok    TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
decision-test-start TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
ok    TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
decision-test-start TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
ok    TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
decision-test-start TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
ok    TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
decision-test-start TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
ok    TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
decision-test-start TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
ok    TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
decision-test-start TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
ok    TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
decision-test-start TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
ok    TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
decision-test-start TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
ok    TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
decision-test-start TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
ok    TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
decision-test-start TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
ok    TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
decision-test-start TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
ok    TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
decision-test-start TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
ok    TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
decision-test-start TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
ok    TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
ok    TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
decision-test-start TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
ok    TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
decision-test-start TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
ok    TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
decision-test-start TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
ok    TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
decision-test-start TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
ok    TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
decision-test-start TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
ok    TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
decision-test-start TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT
Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {8005B00003}>:
  ArcDocDB: DECISION-PARTICIPANT-ORDER

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005B00003}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8007762C53}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8007762C53}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8007762C53}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION :REASON :DECISION-PARTICIPANT-ORDER)
4: (ARCDOCDB.RECOVERY.DECISIONS::CHECK-PARTICIPANT-ORDER #(0 0 0 0 0 0 0 0 0 0 0 0 ...) 65535 71)
5: (ARCDOCDB.RECOVERY.DECISIONS::RADIX-SORT-PARTICIPANTS #(0 0 0 0 0 0 0 0 0 0 0 0 ...) 65535 71)
6: (ARCDOCDB.RECOVERY.DECISIONS::DECODE-DECISIONS #(204 204 204 204 204 204 204 128 164 214 82 218 ...) 7 1048657 1 2 1 65535 65535 64)
7: (ARCDOCDB.RECOVERY.DECISIONS:RICOSTRUISCI-DECISIONI #(204 204 204 204 204 204 204 128 164 214 82 218 ...) 7 1048657 :VERSION 1 :FILE-OFFSET 64 :FILE-SIZE 1048721 :MAX-BYTES 67108864 :MAX-BATCHES 65536 :MAX-BATCH-RECORDS 65536 :MAX-BATCH-BYTES 67108864 :MAX-SEARCH-BYTES 67108864 :MAX-DECISIONS 1 :MAX-PARTICIPANTS 65535 :MAX-PARTICIPANTS-PER-DECISION 65535)
8: (TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT)
9: (\"top level form\") [toplevel]
10: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
11: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL T T)
12: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL)
13: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
14: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
15: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3 NIL)
16: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3)
17: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 3)
18: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {106F30F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
19: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/7/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
20: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/7/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
21: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {106F309EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/7/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/7/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
22: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/7/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
23: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/7/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
24: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/7/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
25: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
26: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
27: (SB-IMPL::PROCESS-SCRIPT \"tools/decisions-radix-isolated-build.lisp\")
28: (SB-IMPL::TOPLEVEL-INIT)
29: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
30: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
31: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
   :RUNNER
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/7/tools/decisions-radix-isolated-build.lisp"
    :GIT-BLOB "f345ccd265e0eebbba7e7c0dc7dc02a817388443" :TEXT "(REQUIRE :ASDF)
(SETF UIOP/CONFIGURATION:*USER-CACHE* (MERGE-PATHNAMES \"fasl/\" (TRUENAME \"./\"))
      UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (FILES
        '(\"tests/recovery/decisions.lisp\"
          \"tests/recovery/decisions-audit.lisp\"))
       (TESTS NIL))
  (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\")
    (UNLESS
        (ASDF/COMPONENT:FIND-COMPONENT
         (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\")
         '(\"recovery\" \"decisions-radix\"))
      (ERROR \"Test radix presente ma non registrato in ASDF.\"))
    (SETF FILES (APPEND FILES '(\"tests/recovery/decisions-radix.lisp\"))))
  (DOLIST (FILE FILES)
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test DECISION: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test DECISION non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&decision-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH TESTS)))
")
   :SOURCE-BLOBS
   ((:PATH "src/foundation/batch.lisp" :GIT-BLOB
     "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
    (:PATH "src/foundation/binary.lisp" :GIT-BLOB
     "2d514f6fe2e81eecb29fa53de611fa5e28696904")
    (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
     "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
    (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
     "f9c691d28620427099d1d89a89a1ff5d04cbe257")
    (:PATH "src/foundation/package.lisp" :GIT-BLOB
     "0658b083f1e777aa0ada67a63535d36946921eac")
    (:PATH "src/foundation/record.lisp" :GIT-BLOB
     "8df53d416747131d9ed9921abb4ef356d9ce5696")
    (:PATH "src/io/flush.lisp" :GIT-BLOB
     "ba31b07379219fa8fd80fca169d43a053d28063b")
    (:PATH "src/io/lifecycle.lisp" :GIT-BLOB
     "0b93448ffe9c6dd4f3a0a2f3f35d5cd656700bd7")
    (:PATH "src/io/native.lisp" :GIT-BLOB
     "1b6fe64ea7145f33bcf08c02e8550034ebd6a40c")
    (:PATH "src/io/package.lisp" :GIT-BLOB
     "6b840a0eb039afa7e55304bffba309f0ab72acdc")
    (:PATH "src/io/transfer.lisp" :GIT-BLOB
     "93acbd608b1af475aa505a6a7dedceb3b15e8d4b")
    (:PATH "src/io/types.lisp" :GIT-BLOB
     "b496c1df87108127da568a1fb7b0fd32856afcc5")
    (:PATH "src/package.lisp" :GIT-BLOB
     "3d0181717e3f334580bab9a6a507e2dfe57261ff")
    (:PATH "src/recovery/decisions-build.lisp" :GIT-BLOB
     "87cc54024e59757c16e20f3025970b1699b11662")
    (:PATH "src/recovery/decisions-package.lisp" :GIT-BLOB
     "878fd1afdcbf035a232166ef87066af4420e1aae")
    (:PATH "src/recovery/decisions-query.lisp" :GIT-BLOB
     "a6ce94b8be3c8c84043abfd6441599f9780b2c11")
    (:PATH "src/recovery/decisions-radix.lisp" :GIT-BLOB
     "e8d445b60440456b182d909779ebdb60d079b6ae")
    (:PATH "src/recovery/decisions-sort.lisp" :GIT-BLOB
     "b133ea00a3b8063e9e934a1b41f10cad024471ae")
    (:PATH "src/recovery/decisions-types.lisp" :GIT-BLOB
     "0dbb2b3bdfbf5447a5904ce0fa6e4a97337a6827")
    (:PATH "src/recovery/package.lisp" :GIT-BLOB
     "b97b5c9bca6955e5dc45d9d4257089ab7132f3fb")
    (:PATH "src/recovery/scan.lisp" :GIT-BLOB
     "7ad6b7541397611f1ecbda7dffdda98c4453dbf1")
    (:PATH "src/storage/compaction-scan.lisp" :GIT-BLOB
     "233556c366a99b7b263af1c7bc19b47ceaebf940")
    (:PATH "src/storage/control-payload.lisp" :GIT-BLOB
     "7980cac6cc8070836b9aa49fc8a0d6fb42630749")
    (:PATH "src/storage/formats.lisp" :GIT-BLOB
     "fc942f1c8e30e637abaf13dc26343d40417fc72f")
    (:PATH "src/storage/log-header.lisp" :GIT-BLOB
     "fde8608e6ad3fe062937c48bdcb7d2d5870207bf")
    (:PATH "src/storage/package.lisp" :GIT-BLOB
     "c15553a65171e5dfb2dbadb62c92ed4dc48aee3a")
    (:PATH "src/storage/payload-record.lisp" :GIT-BLOB
     "0012eaf90064c4cc2949834a60e83c9db8ba6308")
    (:PATH "src/storage/payload-write.lisp" :GIT-BLOB
     "6cbbb89f681965173e9b1b95edf3f7f870af1eca")
    (:PATH "src/storage/segment-header.lisp" :GIT-BLOB
     "f1d99b205b1ea5e6ad059ecd7971d3633411b040")
    (:PATH "src/wal/builder.lisp" :GIT-BLOB
     "a488813eca3f6dcd251affd2017162861cd729d3")
    (:PATH "src/wal/executor.lisp" :GIT-BLOB
     "932eb39a61d9cf66d9394a25dac0e3912c3e3811")
    (:PATH "src/wal/group.lisp" :GIT-BLOB
     "ad43e8547f4b148116c00be5801ad82790240ff2")
    (:PATH "src/wal/package.lisp" :GIT-BLOB
     "608fca13f42115e74941bcbbe359d9541126c050")
    (:PATH "src/wal/types.lisp" :GIT-BLOB
     "adcfd153cb55c0c30d0ff7b610702315fc3cf485")
    (:PATH "tests/foundation/batch.lisp" :GIT-BLOB
     "00bb40ad87340ee86f5da281c09207c8da8888a6")
    (:PATH "tests/foundation/binary.lisp" :GIT-BLOB
     "ff6df200a7ace3af204b622969a387ce7a1e1504")
    (:PATH "tests/foundation/record.lisp" :GIT-BLOB
     "5c7c0d619e9637af6704ec51d564bbfdbc0df551")
    (:PATH "tests/foundation/support.lisp" :GIT-BLOB
     "d383b1cddf929ba0340d1b74eec3ec03673eac09")
    (:PATH "tests/io/native.lisp" :GIT-BLOB
     "bb3f9a460953d5575d7333b8b6eef6ecdb8e1e7d")
    (:PATH "tests/io/support.lisp" :GIT-BLOB
     "0179a0c19bdde944f47fe83716ecc6241e37c686")
    (:PATH "tests/io/transfer.lisp" :GIT-BLOB
     "40c8f4d5e2d493db090d5d09ab024c67ca6f4037")
    (:PATH "tests/lint-fixtures/bad.lisp" :GIT-BLOB
     "d0d5fd7285428e569d3dd595a0c38de5211e10a5")
    (:PATH "tests/lint-fixtures/good.lisp" :GIT-BLOB
     "35558ab0ab2be7688e9fd55a38be44ebe9a57f37")
    (:PATH "tests/recovery/corruption.lisp" :GIT-BLOB
     "2f9ead22a4e3b45cb3a680aa3a32a94bfcc6d77f")
    (:PATH "tests/recovery/decisions-audit.lisp" :GIT-BLOB
     "1b79a76515d8b8c2e67c46700cd6968b40047d62")
    (:PATH "tests/recovery/decisions-radix.lisp" :GIT-BLOB
     "232312cdd4ed6b1efcedc33ddda0fd8d1d8545d7")
    (:PATH "tests/recovery/decisions-support.lisp" :GIT-BLOB
     "f67450a9d681512a4b66efe1af1bfc82180e0058")
    (:PATH "tests/recovery/decisions.lisp" :GIT-BLOB
     "28d04d8738f077bf21ac22393a4014b518a6a0f2")
    (:PATH "tests/recovery/scan.lisp" :GIT-BLOB
     "1c7d71c32d58b05f7e06450680270cb55f6325dc")
    (:PATH "tests/recovery/support.lisp" :GIT-BLOB
     "f784671c59065b4363bcc5e49f06559b11e6562c")
    (:PATH "tests/smoke.lisp" :GIT-BLOB
     "6bd4ab9af1f3d9eedd54822eae10b7f167aa99ed")
    (:PATH "tests/storage/compaction-scan.lisp" :GIT-BLOB
     "16e5c9e5231883844ecd7956c7f790349acd2a05")
    (:PATH "tests/storage/control-payload.lisp" :GIT-BLOB
     "72358c6f324e1c7aaab2bb2c9d03d39ccf78f664")
    (:PATH "tests/storage/log-header.lisp" :GIT-BLOB
     "b3c4c96603ee769429b847569559defda5059744")
    (:PATH "tests/storage/segment-header.lisp" :GIT-BLOB
     "7155aaf2e9c0df4f96533a0be0f6532b54f44590")
    (:PATH "tests/storage/support.lisp" :GIT-BLOB
     "6aa5df3b3cc62b552f5da890583654b82df99431")
    (:PATH "tests/wal/builder.lisp" :GIT-BLOB
     "d62777cd09f8c30fc7246f59fd1bca8ea80c4559")
    (:PATH "tests/wal/fault.lisp" :GIT-BLOB
     "6361a87d73ce90f78438008693a7cd9d6461fe9b")
    (:PATH "tests/wal/group.lisp" :GIT-BLOB
     "04281d9ea3837ed2af0e7fa33b7e17df814982d7")
    (:PATH "tests/wal/native.lisp" :GIT-BLOB
     "077a835fb47524d97e449ae87c74461ebb374653")
    (:PATH "tests/wal/support.lisp" :GIT-BLOB
     "638262b264c64b96774ddb0a6095f4e582debe3e")))
  (:NAME "radix-txid-missing-high-byte" :RESULT :DETECTED :EXIT-CODE 1 :ARGV
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/decisions-radix-isolated-build.lisp")
   :LOG
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/8/test.log"
    :GIT-BLOB "f19e4336024bfb2d55ec044bf3be1970939e652a" :TEXT
    "decision-test-start TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
ok    TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
decision-test-start TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
ok    TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
decision-test-start TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
ok    TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
decision-test-start TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
ok    TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
ok    TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
decision-test-start TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
ok    TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
decision-test-start TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
ok    TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
decision-test-start TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
ok    TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
decision-test-start TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
ok    TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
decision-test-start TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
ok    TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
decision-test-start TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
ok    TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
decision-test-start TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
ok    TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
decision-test-start TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
ok    TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
decision-test-start TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
ok    TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
decision-test-start TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
ok    TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
decision-test-start TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
ok    TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
decision-test-start TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
ok    TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
decision-test-start TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
ok    TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
ok    TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
decision-test-start TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
ok    TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
decision-test-start TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
ok    TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
decision-test-start TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
ok    TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
decision-test-start TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
ok    TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
decision-test-start TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
ok    TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
decision-test-start TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT
ok    TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT
decision-test-start TEST-REQ-TXM-005-RADIX-PARTICIPANT-CARDINALITIES-AND-PATTERNS
ok    TEST-REQ-TXM-005-RADIX-PARTICIPANT-CARDINALITIES-AND-PATTERNS
decision-test-start TEST-REQ-TXM-001-RADIX-PARTICIPANT-EVERY-BYTE-AND-BIT
ok    TEST-REQ-TXM-001-RADIX-PARTICIPANT-EVERY-BYTE-AND-BIT
decision-test-start TEST-REQ-TXM-005-RADIX-DUPLICATE-PARTICIPANT-OFFSET
ok    TEST-REQ-TXM-005-RADIX-DUPLICATE-PARTICIPANT-OFFSET
decision-test-start TEST-REQ-TXM-005-RADIX-PARTICIPANT-SHAPE-BEFORE-SORT
ok    TEST-REQ-TXM-005-RADIX-PARTICIPANT-SHAPE-BEFORE-SORT
decision-test-start TEST-REQ-TXM-005-RADIX-ENTRY-CARDINALITIES-PATTERNS-AND-STABILITY
Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {8005B00003}>:
  ArcDocDB: DECISION-ENTRY-ORDER

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005B00003}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {80071ECF63}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {80071ECF63}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {80071ECF63}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION :REASON :DECISION-ENTRY-ORDER)
4: (ARCDOCDB.RECOVERY.DECISIONS::RADIX-SORT-ENTRIES #(#S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 6266837879191087403 :CSN 18446744073709551614 :COUNT 2 :PARTICIPANTS #1=#(0 0 0 0 0 0 0 0 0 0 0 0 ...) :SOURCE-OFFSET 9223372036854775872) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 1174684194502217932 :CSN 18446744073709551615 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854775808) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 16551460182785888990 :CSN 18446744073709551613 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854775936)))
5: (RADIX-TEST-ASSERT-ENTRY-SORTS #(#S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 1174684194502217932 :CSN 18446744073709551615 :COUNT 2 :PARTICIPANTS #1=#(0 0 0 0 0 0 0 0 0 0 0 0 ...) :SOURCE-OFFSET 9223372036854775808) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 6266837879191087403 :CSN 18446744073709551614 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854775872) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 16551460182785888990 :CSN 18446744073709551613 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854775936)))
6: (TEST-REQ-TXM-005-RADIX-ENTRY-CARDINALITIES-PATTERNS-AND-STABILITY)
7: (\"top level form\") [toplevel]
8: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
9: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL T T)
10: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL)
11: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
12: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
13: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3 NIL)
14: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3)
15: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 3)
16: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1074F0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
17: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/8/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
18: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/8/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
19: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1074F09EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/8/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/8/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
20: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/8/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
21: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/8/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
22: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/8/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
23: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
24: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
25: (SB-IMPL::PROCESS-SCRIPT \"tools/decisions-radix-isolated-build.lisp\")
26: (SB-IMPL::TOPLEVEL-INIT)
27: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
28: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
29: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
   :RUNNER
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/8/tools/decisions-radix-isolated-build.lisp"
    :GIT-BLOB "f345ccd265e0eebbba7e7c0dc7dc02a817388443" :TEXT "(REQUIRE :ASDF)
(SETF UIOP/CONFIGURATION:*USER-CACHE* (MERGE-PATHNAMES \"fasl/\" (TRUENAME \"./\"))
      UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (FILES
        '(\"tests/recovery/decisions.lisp\"
          \"tests/recovery/decisions-audit.lisp\"))
       (TESTS NIL))
  (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\")
    (UNLESS
        (ASDF/COMPONENT:FIND-COMPONENT
         (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\")
         '(\"recovery\" \"decisions-radix\"))
      (ERROR \"Test radix presente ma non registrato in ASDF.\"))
    (SETF FILES (APPEND FILES '(\"tests/recovery/decisions-radix.lisp\"))))
  (DOLIST (FILE FILES)
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test DECISION: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test DECISION non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&decision-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH TESTS)))
")
   :SOURCE-BLOBS
   ((:PATH "src/foundation/batch.lisp" :GIT-BLOB
     "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
    (:PATH "src/foundation/binary.lisp" :GIT-BLOB
     "2d514f6fe2e81eecb29fa53de611fa5e28696904")
    (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
     "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
    (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
     "f9c691d28620427099d1d89a89a1ff5d04cbe257")
    (:PATH "src/foundation/package.lisp" :GIT-BLOB
     "0658b083f1e777aa0ada67a63535d36946921eac")
    (:PATH "src/foundation/record.lisp" :GIT-BLOB
     "8df53d416747131d9ed9921abb4ef356d9ce5696")
    (:PATH "src/io/flush.lisp" :GIT-BLOB
     "ba31b07379219fa8fd80fca169d43a053d28063b")
    (:PATH "src/io/lifecycle.lisp" :GIT-BLOB
     "0b93448ffe9c6dd4f3a0a2f3f35d5cd656700bd7")
    (:PATH "src/io/native.lisp" :GIT-BLOB
     "1b6fe64ea7145f33bcf08c02e8550034ebd6a40c")
    (:PATH "src/io/package.lisp" :GIT-BLOB
     "6b840a0eb039afa7e55304bffba309f0ab72acdc")
    (:PATH "src/io/transfer.lisp" :GIT-BLOB
     "93acbd608b1af475aa505a6a7dedceb3b15e8d4b")
    (:PATH "src/io/types.lisp" :GIT-BLOB
     "b496c1df87108127da568a1fb7b0fd32856afcc5")
    (:PATH "src/package.lisp" :GIT-BLOB
     "3d0181717e3f334580bab9a6a507e2dfe57261ff")
    (:PATH "src/recovery/decisions-build.lisp" :GIT-BLOB
     "87cc54024e59757c16e20f3025970b1699b11662")
    (:PATH "src/recovery/decisions-package.lisp" :GIT-BLOB
     "878fd1afdcbf035a232166ef87066af4420e1aae")
    (:PATH "src/recovery/decisions-query.lisp" :GIT-BLOB
     "a6ce94b8be3c8c84043abfd6441599f9780b2c11")
    (:PATH "src/recovery/decisions-radix.lisp" :GIT-BLOB
     "027115ae9cd5baf8670eb77131cd104abcd51461")
    (:PATH "src/recovery/decisions-sort.lisp" :GIT-BLOB
     "b133ea00a3b8063e9e934a1b41f10cad024471ae")
    (:PATH "src/recovery/decisions-types.lisp" :GIT-BLOB
     "0dbb2b3bdfbf5447a5904ce0fa6e4a97337a6827")
    (:PATH "src/recovery/package.lisp" :GIT-BLOB
     "b97b5c9bca6955e5dc45d9d4257089ab7132f3fb")
    (:PATH "src/recovery/scan.lisp" :GIT-BLOB
     "7ad6b7541397611f1ecbda7dffdda98c4453dbf1")
    (:PATH "src/storage/compaction-scan.lisp" :GIT-BLOB
     "233556c366a99b7b263af1c7bc19b47ceaebf940")
    (:PATH "src/storage/control-payload.lisp" :GIT-BLOB
     "7980cac6cc8070836b9aa49fc8a0d6fb42630749")
    (:PATH "src/storage/formats.lisp" :GIT-BLOB
     "fc942f1c8e30e637abaf13dc26343d40417fc72f")
    (:PATH "src/storage/log-header.lisp" :GIT-BLOB
     "fde8608e6ad3fe062937c48bdcb7d2d5870207bf")
    (:PATH "src/storage/package.lisp" :GIT-BLOB
     "c15553a65171e5dfb2dbadb62c92ed4dc48aee3a")
    (:PATH "src/storage/payload-record.lisp" :GIT-BLOB
     "0012eaf90064c4cc2949834a60e83c9db8ba6308")
    (:PATH "src/storage/payload-write.lisp" :GIT-BLOB
     "6cbbb89f681965173e9b1b95edf3f7f870af1eca")
    (:PATH "src/storage/segment-header.lisp" :GIT-BLOB
     "f1d99b205b1ea5e6ad059ecd7971d3633411b040")
    (:PATH "src/wal/builder.lisp" :GIT-BLOB
     "a488813eca3f6dcd251affd2017162861cd729d3")
    (:PATH "src/wal/executor.lisp" :GIT-BLOB
     "932eb39a61d9cf66d9394a25dac0e3912c3e3811")
    (:PATH "src/wal/group.lisp" :GIT-BLOB
     "ad43e8547f4b148116c00be5801ad82790240ff2")
    (:PATH "src/wal/package.lisp" :GIT-BLOB
     "608fca13f42115e74941bcbbe359d9541126c050")
    (:PATH "src/wal/types.lisp" :GIT-BLOB
     "adcfd153cb55c0c30d0ff7b610702315fc3cf485")
    (:PATH "tests/foundation/batch.lisp" :GIT-BLOB
     "00bb40ad87340ee86f5da281c09207c8da8888a6")
    (:PATH "tests/foundation/binary.lisp" :GIT-BLOB
     "ff6df200a7ace3af204b622969a387ce7a1e1504")
    (:PATH "tests/foundation/record.lisp" :GIT-BLOB
     "5c7c0d619e9637af6704ec51d564bbfdbc0df551")
    (:PATH "tests/foundation/support.lisp" :GIT-BLOB
     "d383b1cddf929ba0340d1b74eec3ec03673eac09")
    (:PATH "tests/io/native.lisp" :GIT-BLOB
     "bb3f9a460953d5575d7333b8b6eef6ecdb8e1e7d")
    (:PATH "tests/io/support.lisp" :GIT-BLOB
     "0179a0c19bdde944f47fe83716ecc6241e37c686")
    (:PATH "tests/io/transfer.lisp" :GIT-BLOB
     "40c8f4d5e2d493db090d5d09ab024c67ca6f4037")
    (:PATH "tests/lint-fixtures/bad.lisp" :GIT-BLOB
     "d0d5fd7285428e569d3dd595a0c38de5211e10a5")
    (:PATH "tests/lint-fixtures/good.lisp" :GIT-BLOB
     "35558ab0ab2be7688e9fd55a38be44ebe9a57f37")
    (:PATH "tests/recovery/corruption.lisp" :GIT-BLOB
     "2f9ead22a4e3b45cb3a680aa3a32a94bfcc6d77f")
    (:PATH "tests/recovery/decisions-audit.lisp" :GIT-BLOB
     "1b79a76515d8b8c2e67c46700cd6968b40047d62")
    (:PATH "tests/recovery/decisions-radix.lisp" :GIT-BLOB
     "232312cdd4ed6b1efcedc33ddda0fd8d1d8545d7")
    (:PATH "tests/recovery/decisions-support.lisp" :GIT-BLOB
     "f67450a9d681512a4b66efe1af1bfc82180e0058")
    (:PATH "tests/recovery/decisions.lisp" :GIT-BLOB
     "28d04d8738f077bf21ac22393a4014b518a6a0f2")
    (:PATH "tests/recovery/scan.lisp" :GIT-BLOB
     "1c7d71c32d58b05f7e06450680270cb55f6325dc")
    (:PATH "tests/recovery/support.lisp" :GIT-BLOB
     "f784671c59065b4363bcc5e49f06559b11e6562c")
    (:PATH "tests/smoke.lisp" :GIT-BLOB
     "6bd4ab9af1f3d9eedd54822eae10b7f167aa99ed")
    (:PATH "tests/storage/compaction-scan.lisp" :GIT-BLOB
     "16e5c9e5231883844ecd7956c7f790349acd2a05")
    (:PATH "tests/storage/control-payload.lisp" :GIT-BLOB
     "72358c6f324e1c7aaab2bb2c9d03d39ccf78f664")
    (:PATH "tests/storage/log-header.lisp" :GIT-BLOB
     "b3c4c96603ee769429b847569559defda5059744")
    (:PATH "tests/storage/segment-header.lisp" :GIT-BLOB
     "7155aaf2e9c0df4f96533a0be0f6532b54f44590")
    (:PATH "tests/storage/support.lisp" :GIT-BLOB
     "6aa5df3b3cc62b552f5da890583654b82df99431")
    (:PATH "tests/wal/builder.lisp" :GIT-BLOB
     "d62777cd09f8c30fc7246f59fd1bca8ea80c4559")
    (:PATH "tests/wal/fault.lisp" :GIT-BLOB
     "6361a87d73ce90f78438008693a7cd9d6461fe9b")
    (:PATH "tests/wal/group.lisp" :GIT-BLOB
     "04281d9ea3837ed2af0e7fa33b7e17df814982d7")
    (:PATH "tests/wal/native.lisp" :GIT-BLOB
     "077a835fb47524d97e449ae87c74461ebb374653")
    (:PATH "tests/wal/support.lisp" :GIT-BLOB
     "638262b264c64b96774ddb0a6095f4e582debe3e")))
  (:NAME "radix-entry-unstable-scatter" :RESULT :DETECTED :EXIT-CODE 1 :ARGV
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/decisions-radix-isolated-build.lisp")
   :LOG
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/9/test.log"
    :GIT-BLOB "64fef7e42e8bd7b7f67d79e6a43c5e5dab71c4a2" :TEXT
    "decision-test-start TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
ok    TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
decision-test-start TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
ok    TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
decision-test-start TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
ok    TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
decision-test-start TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
ok    TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
ok    TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
decision-test-start TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
ok    TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
decision-test-start TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
ok    TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
decision-test-start TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
ok    TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
decision-test-start TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
ok    TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
decision-test-start TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
ok    TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
decision-test-start TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
ok    TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
decision-test-start TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
ok    TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
decision-test-start TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
ok    TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
decision-test-start TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
ok    TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
decision-test-start TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
ok    TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
decision-test-start TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
ok    TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
decision-test-start TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
ok    TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
decision-test-start TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
ok    TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
ok    TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
decision-test-start TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
ok    TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
decision-test-start TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
ok    TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
decision-test-start TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
ok    TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
decision-test-start TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
ok    TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
decision-test-start TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
ok    TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
decision-test-start TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT
ok    TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT
decision-test-start TEST-REQ-TXM-005-RADIX-PARTICIPANT-CARDINALITIES-AND-PATTERNS
ok    TEST-REQ-TXM-005-RADIX-PARTICIPANT-CARDINALITIES-AND-PATTERNS
decision-test-start TEST-REQ-TXM-001-RADIX-PARTICIPANT-EVERY-BYTE-AND-BIT
ok    TEST-REQ-TXM-001-RADIX-PARTICIPANT-EVERY-BYTE-AND-BIT
decision-test-start TEST-REQ-TXM-005-RADIX-DUPLICATE-PARTICIPANT-OFFSET
ok    TEST-REQ-TXM-005-RADIX-DUPLICATE-PARTICIPANT-OFFSET
decision-test-start TEST-REQ-TXM-005-RADIX-PARTICIPANT-SHAPE-BEFORE-SORT
ok    TEST-REQ-TXM-005-RADIX-PARTICIPANT-SHAPE-BEFORE-SORT
decision-test-start TEST-REQ-TXM-005-RADIX-ENTRY-CARDINALITIES-PATTERNS-AND-STABILITY
Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {8005AD0423}>:
  ArcDocDB: DECISION-ENTRY-ORDER

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005AD0423}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {800727AC33}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {800727AC33}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {800727AC33}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION :REASON :DECISION-ENTRY-ORDER)
4: (ARCDOCDB.RECOVERY.DECISIONS::RADIX-SORT-ENTRIES #(#S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 4294967296 :CSN 18446744073709551611 :COUNT 2 :PARTICIPANTS #1=#(0 0 0 0 0 0 0 0 0 0 0 0 ...) :SOURCE-OFFSET 9223372036854776064) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 0 :CSN 18446744073709551615 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854775808) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 9223372036854775807 :CSN 18446744073709551612 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776000) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 9223372036854775808 :CSN 18446744073709551613 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854775936) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551614 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854775872)))
5: (RADIX-TEST-ASSERT-ENTRY-SORTS #(#S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 0 :CSN 18446744073709551615 :COUNT 2 :PARTICIPANTS #1=#(0 0 0 0 0 0 0 0 0 0 0 0 ...) :SOURCE-OFFSET 9223372036854775808) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551614 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854775872) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 9223372036854775808 :CSN 18446744073709551613 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854775936) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 9223372036854775807 :CSN 18446744073709551612 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776000) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 4294967296 :CSN 18446744073709551611 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776064)))
6: (TEST-REQ-TXM-005-RADIX-ENTRY-CARDINALITIES-PATTERNS-AND-STABILITY)
7: (\"top level form\") [toplevel]
8: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
9: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL T T)
10: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL)
11: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
12: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
13: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3 NIL)
14: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3)
15: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 3)
16: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1073F0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
17: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/9/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
18: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/9/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
19: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1073F09EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/9/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/9/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
20: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/9/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
21: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/9/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
22: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/9/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
23: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
24: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
25: (SB-IMPL::PROCESS-SCRIPT \"tools/decisions-radix-isolated-build.lisp\")
26: (SB-IMPL::TOPLEVEL-INIT)
27: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
28: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
29: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
   :RUNNER
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/9/tools/decisions-radix-isolated-build.lisp"
    :GIT-BLOB "f345ccd265e0eebbba7e7c0dc7dc02a817388443" :TEXT "(REQUIRE :ASDF)
(SETF UIOP/CONFIGURATION:*USER-CACHE* (MERGE-PATHNAMES \"fasl/\" (TRUENAME \"./\"))
      UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (FILES
        '(\"tests/recovery/decisions.lisp\"
          \"tests/recovery/decisions-audit.lisp\"))
       (TESTS NIL))
  (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\")
    (UNLESS
        (ASDF/COMPONENT:FIND-COMPONENT
         (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\")
         '(\"recovery\" \"decisions-radix\"))
      (ERROR \"Test radix presente ma non registrato in ASDF.\"))
    (SETF FILES (APPEND FILES '(\"tests/recovery/decisions-radix.lisp\"))))
  (DOLIST (FILE FILES)
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test DECISION: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test DECISION non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&decision-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH TESTS)))
")
   :SOURCE-BLOBS
   ((:PATH "src/foundation/batch.lisp" :GIT-BLOB
     "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
    (:PATH "src/foundation/binary.lisp" :GIT-BLOB
     "2d514f6fe2e81eecb29fa53de611fa5e28696904")
    (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
     "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
    (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
     "f9c691d28620427099d1d89a89a1ff5d04cbe257")
    (:PATH "src/foundation/package.lisp" :GIT-BLOB
     "0658b083f1e777aa0ada67a63535d36946921eac")
    (:PATH "src/foundation/record.lisp" :GIT-BLOB
     "8df53d416747131d9ed9921abb4ef356d9ce5696")
    (:PATH "src/io/flush.lisp" :GIT-BLOB
     "ba31b07379219fa8fd80fca169d43a053d28063b")
    (:PATH "src/io/lifecycle.lisp" :GIT-BLOB
     "0b93448ffe9c6dd4f3a0a2f3f35d5cd656700bd7")
    (:PATH "src/io/native.lisp" :GIT-BLOB
     "1b6fe64ea7145f33bcf08c02e8550034ebd6a40c")
    (:PATH "src/io/package.lisp" :GIT-BLOB
     "6b840a0eb039afa7e55304bffba309f0ab72acdc")
    (:PATH "src/io/transfer.lisp" :GIT-BLOB
     "93acbd608b1af475aa505a6a7dedceb3b15e8d4b")
    (:PATH "src/io/types.lisp" :GIT-BLOB
     "b496c1df87108127da568a1fb7b0fd32856afcc5")
    (:PATH "src/package.lisp" :GIT-BLOB
     "3d0181717e3f334580bab9a6a507e2dfe57261ff")
    (:PATH "src/recovery/decisions-build.lisp" :GIT-BLOB
     "87cc54024e59757c16e20f3025970b1699b11662")
    (:PATH "src/recovery/decisions-package.lisp" :GIT-BLOB
     "878fd1afdcbf035a232166ef87066af4420e1aae")
    (:PATH "src/recovery/decisions-query.lisp" :GIT-BLOB
     "a6ce94b8be3c8c84043abfd6441599f9780b2c11")
    (:PATH "src/recovery/decisions-radix.lisp" :GIT-BLOB
     "a9d682cd74ca6fd9a0239d4a246d93a11473710e")
    (:PATH "src/recovery/decisions-sort.lisp" :GIT-BLOB
     "b133ea00a3b8063e9e934a1b41f10cad024471ae")
    (:PATH "src/recovery/decisions-types.lisp" :GIT-BLOB
     "0dbb2b3bdfbf5447a5904ce0fa6e4a97337a6827")
    (:PATH "src/recovery/package.lisp" :GIT-BLOB
     "b97b5c9bca6955e5dc45d9d4257089ab7132f3fb")
    (:PATH "src/recovery/scan.lisp" :GIT-BLOB
     "7ad6b7541397611f1ecbda7dffdda98c4453dbf1")
    (:PATH "src/storage/compaction-scan.lisp" :GIT-BLOB
     "233556c366a99b7b263af1c7bc19b47ceaebf940")
    (:PATH "src/storage/control-payload.lisp" :GIT-BLOB
     "7980cac6cc8070836b9aa49fc8a0d6fb42630749")
    (:PATH "src/storage/formats.lisp" :GIT-BLOB
     "fc942f1c8e30e637abaf13dc26343d40417fc72f")
    (:PATH "src/storage/log-header.lisp" :GIT-BLOB
     "fde8608e6ad3fe062937c48bdcb7d2d5870207bf")
    (:PATH "src/storage/package.lisp" :GIT-BLOB
     "c15553a65171e5dfb2dbadb62c92ed4dc48aee3a")
    (:PATH "src/storage/payload-record.lisp" :GIT-BLOB
     "0012eaf90064c4cc2949834a60e83c9db8ba6308")
    (:PATH "src/storage/payload-write.lisp" :GIT-BLOB
     "6cbbb89f681965173e9b1b95edf3f7f870af1eca")
    (:PATH "src/storage/segment-header.lisp" :GIT-BLOB
     "f1d99b205b1ea5e6ad059ecd7971d3633411b040")
    (:PATH "src/wal/builder.lisp" :GIT-BLOB
     "a488813eca3f6dcd251affd2017162861cd729d3")
    (:PATH "src/wal/executor.lisp" :GIT-BLOB
     "932eb39a61d9cf66d9394a25dac0e3912c3e3811")
    (:PATH "src/wal/group.lisp" :GIT-BLOB
     "ad43e8547f4b148116c00be5801ad82790240ff2")
    (:PATH "src/wal/package.lisp" :GIT-BLOB
     "608fca13f42115e74941bcbbe359d9541126c050")
    (:PATH "src/wal/types.lisp" :GIT-BLOB
     "adcfd153cb55c0c30d0ff7b610702315fc3cf485")
    (:PATH "tests/foundation/batch.lisp" :GIT-BLOB
     "00bb40ad87340ee86f5da281c09207c8da8888a6")
    (:PATH "tests/foundation/binary.lisp" :GIT-BLOB
     "ff6df200a7ace3af204b622969a387ce7a1e1504")
    (:PATH "tests/foundation/record.lisp" :GIT-BLOB
     "5c7c0d619e9637af6704ec51d564bbfdbc0df551")
    (:PATH "tests/foundation/support.lisp" :GIT-BLOB
     "d383b1cddf929ba0340d1b74eec3ec03673eac09")
    (:PATH "tests/io/native.lisp" :GIT-BLOB
     "bb3f9a460953d5575d7333b8b6eef6ecdb8e1e7d")
    (:PATH "tests/io/support.lisp" :GIT-BLOB
     "0179a0c19bdde944f47fe83716ecc6241e37c686")
    (:PATH "tests/io/transfer.lisp" :GIT-BLOB
     "40c8f4d5e2d493db090d5d09ab024c67ca6f4037")
    (:PATH "tests/lint-fixtures/bad.lisp" :GIT-BLOB
     "d0d5fd7285428e569d3dd595a0c38de5211e10a5")
    (:PATH "tests/lint-fixtures/good.lisp" :GIT-BLOB
     "35558ab0ab2be7688e9fd55a38be44ebe9a57f37")
    (:PATH "tests/recovery/corruption.lisp" :GIT-BLOB
     "2f9ead22a4e3b45cb3a680aa3a32a94bfcc6d77f")
    (:PATH "tests/recovery/decisions-audit.lisp" :GIT-BLOB
     "1b79a76515d8b8c2e67c46700cd6968b40047d62")
    (:PATH "tests/recovery/decisions-radix.lisp" :GIT-BLOB
     "232312cdd4ed6b1efcedc33ddda0fd8d1d8545d7")
    (:PATH "tests/recovery/decisions-support.lisp" :GIT-BLOB
     "f67450a9d681512a4b66efe1af1bfc82180e0058")
    (:PATH "tests/recovery/decisions.lisp" :GIT-BLOB
     "28d04d8738f077bf21ac22393a4014b518a6a0f2")
    (:PATH "tests/recovery/scan.lisp" :GIT-BLOB
     "1c7d71c32d58b05f7e06450680270cb55f6325dc")
    (:PATH "tests/recovery/support.lisp" :GIT-BLOB
     "f784671c59065b4363bcc5e49f06559b11e6562c")
    (:PATH "tests/smoke.lisp" :GIT-BLOB
     "6bd4ab9af1f3d9eedd54822eae10b7f167aa99ed")
    (:PATH "tests/storage/compaction-scan.lisp" :GIT-BLOB
     "16e5c9e5231883844ecd7956c7f790349acd2a05")
    (:PATH "tests/storage/control-payload.lisp" :GIT-BLOB
     "72358c6f324e1c7aaab2bb2c9d03d39ccf78f664")
    (:PATH "tests/storage/log-header.lisp" :GIT-BLOB
     "b3c4c96603ee769429b847569559defda5059744")
    (:PATH "tests/storage/segment-header.lisp" :GIT-BLOB
     "7155aaf2e9c0df4f96533a0be0f6532b54f44590")
    (:PATH "tests/storage/support.lisp" :GIT-BLOB
     "6aa5df3b3cc62b552f5da890583654b82df99431")
    (:PATH "tests/wal/builder.lisp" :GIT-BLOB
     "d62777cd09f8c30fc7246f59fd1bca8ea80c4559")
    (:PATH "tests/wal/fault.lisp" :GIT-BLOB
     "6361a87d73ce90f78438008693a7cd9d6461fe9b")
    (:PATH "tests/wal/group.lisp" :GIT-BLOB
     "04281d9ea3837ed2af0e7fa33b7e17df814982d7")
    (:PATH "tests/wal/native.lisp" :GIT-BLOB
     "077a835fb47524d97e449ae87c74461ebb374653")
    (:PATH "tests/wal/support.lisp" :GIT-BLOB
     "638262b264c64b96774ddb0a6095f4e582debe3e")))
  (:NAME "radix-skip-two-buckets" :RESULT :DETECTED :EXIT-CODE 1 :ARGV
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/decisions-radix-isolated-build.lisp")
   :LOG
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/10/test.log"
    :GIT-BLOB "2371ced4f3de984507803cef83067cd3b479ffea" :TEXT
    "decision-test-start TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
ok    TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
decision-test-start TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
ok    TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
decision-test-start TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
ok    TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
decision-test-start TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
ok    TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
ok    TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
decision-test-start TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
ok    TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
decision-test-start TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
ok    TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
decision-test-start TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
ok    TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
decision-test-start TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
ok    TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
decision-test-start TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
ok    TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
decision-test-start TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
ok    TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
decision-test-start TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
ok    TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
decision-test-start TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
ok    TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
decision-test-start TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
ok    TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
decision-test-start TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
ok    TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
decision-test-start TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
ok    TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
decision-test-start TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
ok    TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
decision-test-start TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
ok    TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
ok    TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
decision-test-start TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
ok    TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
decision-test-start TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
ok    TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
decision-test-start TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
ok    TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
decision-test-start TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
ok    TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
decision-test-start TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
ok    TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
decision-test-start TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT
ok    TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT
decision-test-start TEST-REQ-TXM-005-RADIX-PARTICIPANT-CARDINALITIES-AND-PATTERNS
Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {8005AD0393}>:
  ArcDocDB: DECISION-PARTICIPANT-ORDER

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005AD0393}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {800776C5D3}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {800776C5D3}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {800776C5D3}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION :REASON :DECISION-PARTICIPANT-ORDER)
4: (ARCDOCDB.RECOVERY.DECISIONS::CHECK-PARTICIPANT-ORDER #(165 165 165 165 165 165 165 165 165 165 165 165 ...) 2 18446744073709551615)
5: (ARCDOCDB.RECOVERY.DECISIONS::RADIX-SORT-PARTICIPANTS #(165 165 165 165 165 165 165 165 165 165 165 165 ...) 2 18446744073709551615)
6: (RADIX-TEST-ASSERT-ID-SORTS #(165 165 165 165 165 165 165 165 165 165 165 165 ...) 18446744073709551615)
7: (TEST-REQ-TXM-005-RADIX-PARTICIPANT-CARDINALITIES-AND-PATTERNS)
8: (\"top level form\") [toplevel]
9: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
10: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL T T)
11: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL)
12: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
13: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
14: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3 NIL)
15: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3)
16: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 3)
17: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {105900F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
18: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/10/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
19: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/10/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
20: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1059009EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/10/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/10/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
21: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/10/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
22: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/10/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
23: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/10/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
24: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
25: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
26: (SB-IMPL::PROCESS-SCRIPT \"tools/decisions-radix-isolated-build.lisp\")
27: (SB-IMPL::TOPLEVEL-INIT)
28: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
29: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
30: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
   :RUNNER
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/10/tools/decisions-radix-isolated-build.lisp"
    :GIT-BLOB "f345ccd265e0eebbba7e7c0dc7dc02a817388443" :TEXT "(REQUIRE :ASDF)
(SETF UIOP/CONFIGURATION:*USER-CACHE* (MERGE-PATHNAMES \"fasl/\" (TRUENAME \"./\"))
      UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (FILES
        '(\"tests/recovery/decisions.lisp\"
          \"tests/recovery/decisions-audit.lisp\"))
       (TESTS NIL))
  (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\")
    (UNLESS
        (ASDF/COMPONENT:FIND-COMPONENT
         (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\")
         '(\"recovery\" \"decisions-radix\"))
      (ERROR \"Test radix presente ma non registrato in ASDF.\"))
    (SETF FILES (APPEND FILES '(\"tests/recovery/decisions-radix.lisp\"))))
  (DOLIST (FILE FILES)
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test DECISION: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test DECISION non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&decision-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH TESTS)))
")
   :SOURCE-BLOBS
   ((:PATH "src/foundation/batch.lisp" :GIT-BLOB
     "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
    (:PATH "src/foundation/binary.lisp" :GIT-BLOB
     "2d514f6fe2e81eecb29fa53de611fa5e28696904")
    (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
     "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
    (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
     "f9c691d28620427099d1d89a89a1ff5d04cbe257")
    (:PATH "src/foundation/package.lisp" :GIT-BLOB
     "0658b083f1e777aa0ada67a63535d36946921eac")
    (:PATH "src/foundation/record.lisp" :GIT-BLOB
     "8df53d416747131d9ed9921abb4ef356d9ce5696")
    (:PATH "src/io/flush.lisp" :GIT-BLOB
     "ba31b07379219fa8fd80fca169d43a053d28063b")
    (:PATH "src/io/lifecycle.lisp" :GIT-BLOB
     "0b93448ffe9c6dd4f3a0a2f3f35d5cd656700bd7")
    (:PATH "src/io/native.lisp" :GIT-BLOB
     "1b6fe64ea7145f33bcf08c02e8550034ebd6a40c")
    (:PATH "src/io/package.lisp" :GIT-BLOB
     "6b840a0eb039afa7e55304bffba309f0ab72acdc")
    (:PATH "src/io/transfer.lisp" :GIT-BLOB
     "93acbd608b1af475aa505a6a7dedceb3b15e8d4b")
    (:PATH "src/io/types.lisp" :GIT-BLOB
     "b496c1df87108127da568a1fb7b0fd32856afcc5")
    (:PATH "src/package.lisp" :GIT-BLOB
     "3d0181717e3f334580bab9a6a507e2dfe57261ff")
    (:PATH "src/recovery/decisions-build.lisp" :GIT-BLOB
     "87cc54024e59757c16e20f3025970b1699b11662")
    (:PATH "src/recovery/decisions-package.lisp" :GIT-BLOB
     "878fd1afdcbf035a232166ef87066af4420e1aae")
    (:PATH "src/recovery/decisions-query.lisp" :GIT-BLOB
     "a6ce94b8be3c8c84043abfd6441599f9780b2c11")
    (:PATH "src/recovery/decisions-radix.lisp" :GIT-BLOB
     "a221b71a29df87a454940cba4855c47ea82ee36e")
    (:PATH "src/recovery/decisions-sort.lisp" :GIT-BLOB
     "b133ea00a3b8063e9e934a1b41f10cad024471ae")
    (:PATH "src/recovery/decisions-types.lisp" :GIT-BLOB
     "0dbb2b3bdfbf5447a5904ce0fa6e4a97337a6827")
    (:PATH "src/recovery/package.lisp" :GIT-BLOB
     "b97b5c9bca6955e5dc45d9d4257089ab7132f3fb")
    (:PATH "src/recovery/scan.lisp" :GIT-BLOB
     "7ad6b7541397611f1ecbda7dffdda98c4453dbf1")
    (:PATH "src/storage/compaction-scan.lisp" :GIT-BLOB
     "233556c366a99b7b263af1c7bc19b47ceaebf940")
    (:PATH "src/storage/control-payload.lisp" :GIT-BLOB
     "7980cac6cc8070836b9aa49fc8a0d6fb42630749")
    (:PATH "src/storage/formats.lisp" :GIT-BLOB
     "fc942f1c8e30e637abaf13dc26343d40417fc72f")
    (:PATH "src/storage/log-header.lisp" :GIT-BLOB
     "fde8608e6ad3fe062937c48bdcb7d2d5870207bf")
    (:PATH "src/storage/package.lisp" :GIT-BLOB
     "c15553a65171e5dfb2dbadb62c92ed4dc48aee3a")
    (:PATH "src/storage/payload-record.lisp" :GIT-BLOB
     "0012eaf90064c4cc2949834a60e83c9db8ba6308")
    (:PATH "src/storage/payload-write.lisp" :GIT-BLOB
     "6cbbb89f681965173e9b1b95edf3f7f870af1eca")
    (:PATH "src/storage/segment-header.lisp" :GIT-BLOB
     "f1d99b205b1ea5e6ad059ecd7971d3633411b040")
    (:PATH "src/wal/builder.lisp" :GIT-BLOB
     "a488813eca3f6dcd251affd2017162861cd729d3")
    (:PATH "src/wal/executor.lisp" :GIT-BLOB
     "932eb39a61d9cf66d9394a25dac0e3912c3e3811")
    (:PATH "src/wal/group.lisp" :GIT-BLOB
     "ad43e8547f4b148116c00be5801ad82790240ff2")
    (:PATH "src/wal/package.lisp" :GIT-BLOB
     "608fca13f42115e74941bcbbe359d9541126c050")
    (:PATH "src/wal/types.lisp" :GIT-BLOB
     "adcfd153cb55c0c30d0ff7b610702315fc3cf485")
    (:PATH "tests/foundation/batch.lisp" :GIT-BLOB
     "00bb40ad87340ee86f5da281c09207c8da8888a6")
    (:PATH "tests/foundation/binary.lisp" :GIT-BLOB
     "ff6df200a7ace3af204b622969a387ce7a1e1504")
    (:PATH "tests/foundation/record.lisp" :GIT-BLOB
     "5c7c0d619e9637af6704ec51d564bbfdbc0df551")
    (:PATH "tests/foundation/support.lisp" :GIT-BLOB
     "d383b1cddf929ba0340d1b74eec3ec03673eac09")
    (:PATH "tests/io/native.lisp" :GIT-BLOB
     "bb3f9a460953d5575d7333b8b6eef6ecdb8e1e7d")
    (:PATH "tests/io/support.lisp" :GIT-BLOB
     "0179a0c19bdde944f47fe83716ecc6241e37c686")
    (:PATH "tests/io/transfer.lisp" :GIT-BLOB
     "40c8f4d5e2d493db090d5d09ab024c67ca6f4037")
    (:PATH "tests/lint-fixtures/bad.lisp" :GIT-BLOB
     "d0d5fd7285428e569d3dd595a0c38de5211e10a5")
    (:PATH "tests/lint-fixtures/good.lisp" :GIT-BLOB
     "35558ab0ab2be7688e9fd55a38be44ebe9a57f37")
    (:PATH "tests/recovery/corruption.lisp" :GIT-BLOB
     "2f9ead22a4e3b45cb3a680aa3a32a94bfcc6d77f")
    (:PATH "tests/recovery/decisions-audit.lisp" :GIT-BLOB
     "1b79a76515d8b8c2e67c46700cd6968b40047d62")
    (:PATH "tests/recovery/decisions-radix.lisp" :GIT-BLOB
     "232312cdd4ed6b1efcedc33ddda0fd8d1d8545d7")
    (:PATH "tests/recovery/decisions-support.lisp" :GIT-BLOB
     "f67450a9d681512a4b66efe1af1bfc82180e0058")
    (:PATH "tests/recovery/decisions.lisp" :GIT-BLOB
     "28d04d8738f077bf21ac22393a4014b518a6a0f2")
    (:PATH "tests/recovery/scan.lisp" :GIT-BLOB
     "1c7d71c32d58b05f7e06450680270cb55f6325dc")
    (:PATH "tests/recovery/support.lisp" :GIT-BLOB
     "f784671c59065b4363bcc5e49f06559b11e6562c")
    (:PATH "tests/smoke.lisp" :GIT-BLOB
     "6bd4ab9af1f3d9eedd54822eae10b7f167aa99ed")
    (:PATH "tests/storage/compaction-scan.lisp" :GIT-BLOB
     "16e5c9e5231883844ecd7956c7f790349acd2a05")
    (:PATH "tests/storage/control-payload.lisp" :GIT-BLOB
     "72358c6f324e1c7aaab2bb2c9d03d39ccf78f664")
    (:PATH "tests/storage/log-header.lisp" :GIT-BLOB
     "b3c4c96603ee769429b847569559defda5059744")
    (:PATH "tests/storage/segment-header.lisp" :GIT-BLOB
     "7155aaf2e9c0df4f96533a0be0f6532b54f44590")
    (:PATH "tests/storage/support.lisp" :GIT-BLOB
     "6aa5df3b3cc62b552f5da890583654b82df99431")
    (:PATH "tests/wal/builder.lisp" :GIT-BLOB
     "d62777cd09f8c30fc7246f59fd1bca8ea80c4559")
    (:PATH "tests/wal/fault.lisp" :GIT-BLOB
     "6361a87d73ce90f78438008693a7cd9d6461fe9b")
    (:PATH "tests/wal/group.lisp" :GIT-BLOB
     "04281d9ea3837ed2af0e7fa33b7e17df814982d7")
    (:PATH "tests/wal/native.lisp" :GIT-BLOB
     "077a835fb47524d97e449ae87c74461ebb374653")
    (:PATH "tests/wal/support.lisp" :GIT-BLOB
     "638262b264c64b96774ddb0a6095f4e582debe3e")))
  (:NAME "radix-rotate-uniform-id-pass" :RESULT :DETECTED :EXIT-CODE 1 :ARGV
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/decisions-radix-isolated-build.lisp")
   :LOG
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/11/test.log"
    :GIT-BLOB "b4ae456b68b3a0c4df097118e53a77f19a1db3dc" :TEXT
    "decision-test-start TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
ok    TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
decision-test-start TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
ok    TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
decision-test-start TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
ok    TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
decision-test-start TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
ok    TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
ok    TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
decision-test-start TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
ok    TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
decision-test-start TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
ok    TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
decision-test-start TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
ok    TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
decision-test-start TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
ok    TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
decision-test-start TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
ok    TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
decision-test-start TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
ok    TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
decision-test-start TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
ok    TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
decision-test-start TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
ok    TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
decision-test-start TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
ok    TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
decision-test-start TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
ok    TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
decision-test-start TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
ok    TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
decision-test-start TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
ok    TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
decision-test-start TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
ok    TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
ok    TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
decision-test-start TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
ok    TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
decision-test-start TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
ok    TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
decision-test-start TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
ok    TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
decision-test-start TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
ok    TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
decision-test-start TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
ok    TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
decision-test-start TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT
ok    TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT
decision-test-start TEST-REQ-TXM-005-RADIX-PARTICIPANT-CARDINALITIES-AND-PATTERNS
Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {8005AD0393}>:
  ArcDocDB: DECISION-PARTICIPANT-ORDER

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005AD0393}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8007796A73}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8007796A73}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8007796A73}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION :REASON :DECISION-PARTICIPANT-ORDER)
4: (ARCDOCDB.RECOVERY.DECISIONS::CHECK-PARTICIPANT-ORDER #(165 165 165 165 165 165 165 165 165 165 165 165 ...) 2 18446744073709551615)
5: (ARCDOCDB.RECOVERY.DECISIONS::RADIX-SORT-PARTICIPANTS #(165 165 165 165 165 165 165 165 165 165 165 165 ...) 2 18446744073709551615)
6: (RADIX-TEST-ASSERT-ID-SORTS #(165 165 165 165 165 165 165 165 165 165 165 165 ...) 18446744073709551615)
7: (TEST-REQ-TXM-005-RADIX-PARTICIPANT-CARDINALITIES-AND-PATTERNS)
8: (\"top level form\") [toplevel]
9: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
10: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL T T)
11: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL)
12: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
13: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
14: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3 NIL)
15: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3)
16: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 3)
17: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {109150F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
18: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/11/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
19: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/11/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
20: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1091509EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/11/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/11/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
21: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/11/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
22: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/11/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
23: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/11/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
24: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
25: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
26: (SB-IMPL::PROCESS-SCRIPT \"tools/decisions-radix-isolated-build.lisp\")
27: (SB-IMPL::TOPLEVEL-INIT)
28: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
29: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
30: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
   :RUNNER
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/11/tools/decisions-radix-isolated-build.lisp"
    :GIT-BLOB "f345ccd265e0eebbba7e7c0dc7dc02a817388443" :TEXT "(REQUIRE :ASDF)
(SETF UIOP/CONFIGURATION:*USER-CACHE* (MERGE-PATHNAMES \"fasl/\" (TRUENAME \"./\"))
      UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (FILES
        '(\"tests/recovery/decisions.lisp\"
          \"tests/recovery/decisions-audit.lisp\"))
       (TESTS NIL))
  (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\")
    (UNLESS
        (ASDF/COMPONENT:FIND-COMPONENT
         (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\")
         '(\"recovery\" \"decisions-radix\"))
      (ERROR \"Test radix presente ma non registrato in ASDF.\"))
    (SETF FILES (APPEND FILES '(\"tests/recovery/decisions-radix.lisp\"))))
  (DOLIST (FILE FILES)
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test DECISION: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test DECISION non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&decision-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH TESTS)))
")
   :SOURCE-BLOBS
   ((:PATH "src/foundation/batch.lisp" :GIT-BLOB
     "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
    (:PATH "src/foundation/binary.lisp" :GIT-BLOB
     "2d514f6fe2e81eecb29fa53de611fa5e28696904")
    (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
     "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
    (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
     "f9c691d28620427099d1d89a89a1ff5d04cbe257")
    (:PATH "src/foundation/package.lisp" :GIT-BLOB
     "0658b083f1e777aa0ada67a63535d36946921eac")
    (:PATH "src/foundation/record.lisp" :GIT-BLOB
     "8df53d416747131d9ed9921abb4ef356d9ce5696")
    (:PATH "src/io/flush.lisp" :GIT-BLOB
     "ba31b07379219fa8fd80fca169d43a053d28063b")
    (:PATH "src/io/lifecycle.lisp" :GIT-BLOB
     "0b93448ffe9c6dd4f3a0a2f3f35d5cd656700bd7")
    (:PATH "src/io/native.lisp" :GIT-BLOB
     "1b6fe64ea7145f33bcf08c02e8550034ebd6a40c")
    (:PATH "src/io/package.lisp" :GIT-BLOB
     "6b840a0eb039afa7e55304bffba309f0ab72acdc")
    (:PATH "src/io/transfer.lisp" :GIT-BLOB
     "93acbd608b1af475aa505a6a7dedceb3b15e8d4b")
    (:PATH "src/io/types.lisp" :GIT-BLOB
     "b496c1df87108127da568a1fb7b0fd32856afcc5")
    (:PATH "src/package.lisp" :GIT-BLOB
     "3d0181717e3f334580bab9a6a507e2dfe57261ff")
    (:PATH "src/recovery/decisions-build.lisp" :GIT-BLOB
     "87cc54024e59757c16e20f3025970b1699b11662")
    (:PATH "src/recovery/decisions-package.lisp" :GIT-BLOB
     "878fd1afdcbf035a232166ef87066af4420e1aae")
    (:PATH "src/recovery/decisions-query.lisp" :GIT-BLOB
     "a6ce94b8be3c8c84043abfd6441599f9780b2c11")
    (:PATH "src/recovery/decisions-radix.lisp" :GIT-BLOB
     "c485a7b1fc4aa400f93fcb38a538a18d3431ebf8")
    (:PATH "src/recovery/decisions-sort.lisp" :GIT-BLOB
     "b133ea00a3b8063e9e934a1b41f10cad024471ae")
    (:PATH "src/recovery/decisions-types.lisp" :GIT-BLOB
     "0dbb2b3bdfbf5447a5904ce0fa6e4a97337a6827")
    (:PATH "src/recovery/package.lisp" :GIT-BLOB
     "b97b5c9bca6955e5dc45d9d4257089ab7132f3fb")
    (:PATH "src/recovery/scan.lisp" :GIT-BLOB
     "7ad6b7541397611f1ecbda7dffdda98c4453dbf1")
    (:PATH "src/storage/compaction-scan.lisp" :GIT-BLOB
     "233556c366a99b7b263af1c7bc19b47ceaebf940")
    (:PATH "src/storage/control-payload.lisp" :GIT-BLOB
     "7980cac6cc8070836b9aa49fc8a0d6fb42630749")
    (:PATH "src/storage/formats.lisp" :GIT-BLOB
     "fc942f1c8e30e637abaf13dc26343d40417fc72f")
    (:PATH "src/storage/log-header.lisp" :GIT-BLOB
     "fde8608e6ad3fe062937c48bdcb7d2d5870207bf")
    (:PATH "src/storage/package.lisp" :GIT-BLOB
     "c15553a65171e5dfb2dbadb62c92ed4dc48aee3a")
    (:PATH "src/storage/payload-record.lisp" :GIT-BLOB
     "0012eaf90064c4cc2949834a60e83c9db8ba6308")
    (:PATH "src/storage/payload-write.lisp" :GIT-BLOB
     "6cbbb89f681965173e9b1b95edf3f7f870af1eca")
    (:PATH "src/storage/segment-header.lisp" :GIT-BLOB
     "f1d99b205b1ea5e6ad059ecd7971d3633411b040")
    (:PATH "src/wal/builder.lisp" :GIT-BLOB
     "a488813eca3f6dcd251affd2017162861cd729d3")
    (:PATH "src/wal/executor.lisp" :GIT-BLOB
     "932eb39a61d9cf66d9394a25dac0e3912c3e3811")
    (:PATH "src/wal/group.lisp" :GIT-BLOB
     "ad43e8547f4b148116c00be5801ad82790240ff2")
    (:PATH "src/wal/package.lisp" :GIT-BLOB
     "608fca13f42115e74941bcbbe359d9541126c050")
    (:PATH "src/wal/types.lisp" :GIT-BLOB
     "adcfd153cb55c0c30d0ff7b610702315fc3cf485")
    (:PATH "tests/foundation/batch.lisp" :GIT-BLOB
     "00bb40ad87340ee86f5da281c09207c8da8888a6")
    (:PATH "tests/foundation/binary.lisp" :GIT-BLOB
     "ff6df200a7ace3af204b622969a387ce7a1e1504")
    (:PATH "tests/foundation/record.lisp" :GIT-BLOB
     "5c7c0d619e9637af6704ec51d564bbfdbc0df551")
    (:PATH "tests/foundation/support.lisp" :GIT-BLOB
     "d383b1cddf929ba0340d1b74eec3ec03673eac09")
    (:PATH "tests/io/native.lisp" :GIT-BLOB
     "bb3f9a460953d5575d7333b8b6eef6ecdb8e1e7d")
    (:PATH "tests/io/support.lisp" :GIT-BLOB
     "0179a0c19bdde944f47fe83716ecc6241e37c686")
    (:PATH "tests/io/transfer.lisp" :GIT-BLOB
     "40c8f4d5e2d493db090d5d09ab024c67ca6f4037")
    (:PATH "tests/lint-fixtures/bad.lisp" :GIT-BLOB
     "d0d5fd7285428e569d3dd595a0c38de5211e10a5")
    (:PATH "tests/lint-fixtures/good.lisp" :GIT-BLOB
     "35558ab0ab2be7688e9fd55a38be44ebe9a57f37")
    (:PATH "tests/recovery/corruption.lisp" :GIT-BLOB
     "2f9ead22a4e3b45cb3a680aa3a32a94bfcc6d77f")
    (:PATH "tests/recovery/decisions-audit.lisp" :GIT-BLOB
     "1b79a76515d8b8c2e67c46700cd6968b40047d62")
    (:PATH "tests/recovery/decisions-radix.lisp" :GIT-BLOB
     "232312cdd4ed6b1efcedc33ddda0fd8d1d8545d7")
    (:PATH "tests/recovery/decisions-support.lisp" :GIT-BLOB
     "f67450a9d681512a4b66efe1af1bfc82180e0058")
    (:PATH "tests/recovery/decisions.lisp" :GIT-BLOB
     "28d04d8738f077bf21ac22393a4014b518a6a0f2")
    (:PATH "tests/recovery/scan.lisp" :GIT-BLOB
     "1c7d71c32d58b05f7e06450680270cb55f6325dc")
    (:PATH "tests/recovery/support.lisp" :GIT-BLOB
     "f784671c59065b4363bcc5e49f06559b11e6562c")
    (:PATH "tests/smoke.lisp" :GIT-BLOB
     "6bd4ab9af1f3d9eedd54822eae10b7f167aa99ed")
    (:PATH "tests/storage/compaction-scan.lisp" :GIT-BLOB
     "16e5c9e5231883844ecd7956c7f790349acd2a05")
    (:PATH "tests/storage/control-payload.lisp" :GIT-BLOB
     "72358c6f324e1c7aaab2bb2c9d03d39ccf78f664")
    (:PATH "tests/storage/log-header.lisp" :GIT-BLOB
     "b3c4c96603ee769429b847569559defda5059744")
    (:PATH "tests/storage/segment-header.lisp" :GIT-BLOB
     "7155aaf2e9c0df4f96533a0be0f6532b54f44590")
    (:PATH "tests/storage/support.lisp" :GIT-BLOB
     "6aa5df3b3cc62b552f5da890583654b82df99431")
    (:PATH "tests/wal/builder.lisp" :GIT-BLOB
     "d62777cd09f8c30fc7246f59fd1bca8ea80c4559")
    (:PATH "tests/wal/fault.lisp" :GIT-BLOB
     "6361a87d73ce90f78438008693a7cd9d6461fe9b")
    (:PATH "tests/wal/group.lisp" :GIT-BLOB
     "04281d9ea3837ed2af0e7fa33b7e17df814982d7")
    (:PATH "tests/wal/native.lisp" :GIT-BLOB
     "077a835fb47524d97e449ae87c74461ebb374653")
    (:PATH "tests/wal/support.lisp" :GIT-BLOB
     "638262b264c64b96774ddb0a6095f4e582debe3e")))
  (:NAME "radix-histogram-u16" :RESULT :DETECTED :EXIT-CODE 1 :ARGV
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/decisions-radix-isolated-build.lisp")
   :LOG
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/12/test.log"
    :GIT-BLOB "3bf6b46007fd0e779d478009c5a8346de5835bf4" :TEXT
    "decision-test-start TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
ok    TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
decision-test-start TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
ok    TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
decision-test-start TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
ok    TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
decision-test-start TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
ok    TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
ok    TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
decision-test-start TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
ok    TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
decision-test-start TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
ok    TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
decision-test-start TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
ok    TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
decision-test-start TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
ok    TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
decision-test-start TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
ok    TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
decision-test-start TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
ok    TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
decision-test-start TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
ok    TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
decision-test-start TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
ok    TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
decision-test-start TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
ok    TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
decision-test-start TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
ok    TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
decision-test-start TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
ok    TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
decision-test-start TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
ok    TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
decision-test-start TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
ok    TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
ok    TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
decision-test-start TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
ok    TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
decision-test-start TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
ok    TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
decision-test-start TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
ok    TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
decision-test-start TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
ok    TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
decision-test-start TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
ok    TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
decision-test-start TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT
ok    TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT
decision-test-start TEST-REQ-TXM-005-RADIX-PARTICIPANT-CARDINALITIES-AND-PATTERNS
ok    TEST-REQ-TXM-005-RADIX-PARTICIPANT-CARDINALITIES-AND-PATTERNS
decision-test-start TEST-REQ-TXM-001-RADIX-PARTICIPANT-EVERY-BYTE-AND-BIT
ok    TEST-REQ-TXM-001-RADIX-PARTICIPANT-EVERY-BYTE-AND-BIT
decision-test-start TEST-REQ-TXM-005-RADIX-DUPLICATE-PARTICIPANT-OFFSET
ok    TEST-REQ-TXM-005-RADIX-DUPLICATE-PARTICIPANT-OFFSET
decision-test-start TEST-REQ-TXM-005-RADIX-PARTICIPANT-SHAPE-BEFORE-SORT
ok    TEST-REQ-TXM-005-RADIX-PARTICIPANT-SHAPE-BEFORE-SORT
decision-test-start TEST-REQ-TXM-005-RADIX-ENTRY-CARDINALITIES-PATTERNS-AND-STABILITY
ok    TEST-REQ-TXM-005-RADIX-ENTRY-CARDINALITIES-PATTERNS-AND-STABILITY
decision-test-start TEST-REQ-AFF-008-RADIX-ENTRY-65536-BUCKET-COUNTS
Unhandled TYPE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                  {8005AD04B3}>:
  The value
    65536
  is not of type
    (UNSIGNED-BYTE 16)
  when setting an element of (ARRAY (UNSIGNED-BYTE 16))

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005AD04B3}>
0: (ARCDOCDB.RECOVERY.DECISIONS::RADIX-ENTRY-STARTS #(#S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551615 :COUNT 2 :PARTICIPANTS #1=#(0 0 0 0 0 0 0 0 0 0 0 0 ...) :SOURCE-OFFSET 9223372036854775808) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551614 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854775872) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551613 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854775936) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551612 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776000) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551611 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776064) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551610 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776128) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551609 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776192) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551608 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776256) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551607 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776320) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551606 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776384) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551605 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776448) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551604 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776512) ...) 0 #(0 0 0 0 0 0 0 0 0 0 0 0 ...))
1: (ARCDOCDB.RECOVERY.DECISIONS::RADIX-SORT-ENTRIES #(#S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551615 :COUNT 2 :PARTICIPANTS #1=#(0 0 0 0 0 0 0 0 0 0 0 0 ...) :SOURCE-OFFSET 9223372036854775808) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551614 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854775872) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551613 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854775936) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551612 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776000) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551611 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776064) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551610 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776128) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551609 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776192) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551608 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776256) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551607 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776320) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551606 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776384) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551605 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776448) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551604 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776512) ...))
2: (RADIX-TEST-ASSERT-ENTRY-SORTS #(#S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551615 :COUNT 2 :PARTICIPANTS #1=#(0 0 0 0 0 0 0 0 0 0 0 0 ...) :SOURCE-OFFSET 9223372036854775808) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551614 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854775872) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551613 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854775936) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551612 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776000) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551611 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776064) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551610 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776128) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551609 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776192) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551608 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776256) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551607 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776320) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551606 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776384) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551605 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776448) #S(ARCDOCDB.RECOVERY.DECISIONS::DECISION-ENTRY :TXID 18446744073709551615 :CSN 18446744073709551604 :COUNT 2 :PARTICIPANTS #1# :SOURCE-OFFSET 9223372036854776512) ...))
3: (TEST-REQ-AFF-008-RADIX-ENTRY-65536-BUCKET-COUNTS)
4: (\"top level form\") [toplevel]
5: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
6: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL T T)
7: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL)
8: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
9: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
10: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3 NIL)
11: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3)
12: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 3)
13: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107230F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
14: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/12/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
15: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/12/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
16: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1072309EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/12/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/12/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
17: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/12/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
18: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/12/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
19: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/12/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
20: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
21: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
22: (SB-IMPL::PROCESS-SCRIPT \"tools/decisions-radix-isolated-build.lisp\")
23: (SB-IMPL::TOPLEVEL-INIT)
24: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
25: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
26: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
   :RUNNER
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/12/tools/decisions-radix-isolated-build.lisp"
    :GIT-BLOB "f345ccd265e0eebbba7e7c0dc7dc02a817388443" :TEXT "(REQUIRE :ASDF)
(SETF UIOP/CONFIGURATION:*USER-CACHE* (MERGE-PATHNAMES \"fasl/\" (TRUENAME \"./\"))
      UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (FILES
        '(\"tests/recovery/decisions.lisp\"
          \"tests/recovery/decisions-audit.lisp\"))
       (TESTS NIL))
  (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\")
    (UNLESS
        (ASDF/COMPONENT:FIND-COMPONENT
         (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\")
         '(\"recovery\" \"decisions-radix\"))
      (ERROR \"Test radix presente ma non registrato in ASDF.\"))
    (SETF FILES (APPEND FILES '(\"tests/recovery/decisions-radix.lisp\"))))
  (DOLIST (FILE FILES)
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test DECISION: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test DECISION non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&decision-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH TESTS)))
")
   :SOURCE-BLOBS
   ((:PATH "src/foundation/batch.lisp" :GIT-BLOB
     "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
    (:PATH "src/foundation/binary.lisp" :GIT-BLOB
     "2d514f6fe2e81eecb29fa53de611fa5e28696904")
    (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
     "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
    (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
     "f9c691d28620427099d1d89a89a1ff5d04cbe257")
    (:PATH "src/foundation/package.lisp" :GIT-BLOB
     "0658b083f1e777aa0ada67a63535d36946921eac")
    (:PATH "src/foundation/record.lisp" :GIT-BLOB
     "8df53d416747131d9ed9921abb4ef356d9ce5696")
    (:PATH "src/io/flush.lisp" :GIT-BLOB
     "ba31b07379219fa8fd80fca169d43a053d28063b")
    (:PATH "src/io/lifecycle.lisp" :GIT-BLOB
     "0b93448ffe9c6dd4f3a0a2f3f35d5cd656700bd7")
    (:PATH "src/io/native.lisp" :GIT-BLOB
     "1b6fe64ea7145f33bcf08c02e8550034ebd6a40c")
    (:PATH "src/io/package.lisp" :GIT-BLOB
     "6b840a0eb039afa7e55304bffba309f0ab72acdc")
    (:PATH "src/io/transfer.lisp" :GIT-BLOB
     "93acbd608b1af475aa505a6a7dedceb3b15e8d4b")
    (:PATH "src/io/types.lisp" :GIT-BLOB
     "b496c1df87108127da568a1fb7b0fd32856afcc5")
    (:PATH "src/package.lisp" :GIT-BLOB
     "3d0181717e3f334580bab9a6a507e2dfe57261ff")
    (:PATH "src/recovery/decisions-build.lisp" :GIT-BLOB
     "87cc54024e59757c16e20f3025970b1699b11662")
    (:PATH "src/recovery/decisions-package.lisp" :GIT-BLOB
     "878fd1afdcbf035a232166ef87066af4420e1aae")
    (:PATH "src/recovery/decisions-query.lisp" :GIT-BLOB
     "a6ce94b8be3c8c84043abfd6441599f9780b2c11")
    (:PATH "src/recovery/decisions-radix.lisp" :GIT-BLOB
     "b6b24e272442bb601a27618b7b1f51db732e49ca")
    (:PATH "src/recovery/decisions-sort.lisp" :GIT-BLOB
     "b133ea00a3b8063e9e934a1b41f10cad024471ae")
    (:PATH "src/recovery/decisions-types.lisp" :GIT-BLOB
     "0dbb2b3bdfbf5447a5904ce0fa6e4a97337a6827")
    (:PATH "src/recovery/package.lisp" :GIT-BLOB
     "b97b5c9bca6955e5dc45d9d4257089ab7132f3fb")
    (:PATH "src/recovery/scan.lisp" :GIT-BLOB
     "7ad6b7541397611f1ecbda7dffdda98c4453dbf1")
    (:PATH "src/storage/compaction-scan.lisp" :GIT-BLOB
     "233556c366a99b7b263af1c7bc19b47ceaebf940")
    (:PATH "src/storage/control-payload.lisp" :GIT-BLOB
     "7980cac6cc8070836b9aa49fc8a0d6fb42630749")
    (:PATH "src/storage/formats.lisp" :GIT-BLOB
     "fc942f1c8e30e637abaf13dc26343d40417fc72f")
    (:PATH "src/storage/log-header.lisp" :GIT-BLOB
     "fde8608e6ad3fe062937c48bdcb7d2d5870207bf")
    (:PATH "src/storage/package.lisp" :GIT-BLOB
     "c15553a65171e5dfb2dbadb62c92ed4dc48aee3a")
    (:PATH "src/storage/payload-record.lisp" :GIT-BLOB
     "0012eaf90064c4cc2949834a60e83c9db8ba6308")
    (:PATH "src/storage/payload-write.lisp" :GIT-BLOB
     "6cbbb89f681965173e9b1b95edf3f7f870af1eca")
    (:PATH "src/storage/segment-header.lisp" :GIT-BLOB
     "f1d99b205b1ea5e6ad059ecd7971d3633411b040")
    (:PATH "src/wal/builder.lisp" :GIT-BLOB
     "a488813eca3f6dcd251affd2017162861cd729d3")
    (:PATH "src/wal/executor.lisp" :GIT-BLOB
     "932eb39a61d9cf66d9394a25dac0e3912c3e3811")
    (:PATH "src/wal/group.lisp" :GIT-BLOB
     "ad43e8547f4b148116c00be5801ad82790240ff2")
    (:PATH "src/wal/package.lisp" :GIT-BLOB
     "608fca13f42115e74941bcbbe359d9541126c050")
    (:PATH "src/wal/types.lisp" :GIT-BLOB
     "adcfd153cb55c0c30d0ff7b610702315fc3cf485")
    (:PATH "tests/foundation/batch.lisp" :GIT-BLOB
     "00bb40ad87340ee86f5da281c09207c8da8888a6")
    (:PATH "tests/foundation/binary.lisp" :GIT-BLOB
     "ff6df200a7ace3af204b622969a387ce7a1e1504")
    (:PATH "tests/foundation/record.lisp" :GIT-BLOB
     "5c7c0d619e9637af6704ec51d564bbfdbc0df551")
    (:PATH "tests/foundation/support.lisp" :GIT-BLOB
     "d383b1cddf929ba0340d1b74eec3ec03673eac09")
    (:PATH "tests/io/native.lisp" :GIT-BLOB
     "bb3f9a460953d5575d7333b8b6eef6ecdb8e1e7d")
    (:PATH "tests/io/support.lisp" :GIT-BLOB
     "0179a0c19bdde944f47fe83716ecc6241e37c686")
    (:PATH "tests/io/transfer.lisp" :GIT-BLOB
     "40c8f4d5e2d493db090d5d09ab024c67ca6f4037")
    (:PATH "tests/lint-fixtures/bad.lisp" :GIT-BLOB
     "d0d5fd7285428e569d3dd595a0c38de5211e10a5")
    (:PATH "tests/lint-fixtures/good.lisp" :GIT-BLOB
     "35558ab0ab2be7688e9fd55a38be44ebe9a57f37")
    (:PATH "tests/recovery/corruption.lisp" :GIT-BLOB
     "2f9ead22a4e3b45cb3a680aa3a32a94bfcc6d77f")
    (:PATH "tests/recovery/decisions-audit.lisp" :GIT-BLOB
     "1b79a76515d8b8c2e67c46700cd6968b40047d62")
    (:PATH "tests/recovery/decisions-radix.lisp" :GIT-BLOB
     "232312cdd4ed6b1efcedc33ddda0fd8d1d8545d7")
    (:PATH "tests/recovery/decisions-support.lisp" :GIT-BLOB
     "f67450a9d681512a4b66efe1af1bfc82180e0058")
    (:PATH "tests/recovery/decisions.lisp" :GIT-BLOB
     "28d04d8738f077bf21ac22393a4014b518a6a0f2")
    (:PATH "tests/recovery/scan.lisp" :GIT-BLOB
     "1c7d71c32d58b05f7e06450680270cb55f6325dc")
    (:PATH "tests/recovery/support.lisp" :GIT-BLOB
     "f784671c59065b4363bcc5e49f06559b11e6562c")
    (:PATH "tests/smoke.lisp" :GIT-BLOB
     "6bd4ab9af1f3d9eedd54822eae10b7f167aa99ed")
    (:PATH "tests/storage/compaction-scan.lisp" :GIT-BLOB
     "16e5c9e5231883844ecd7956c7f790349acd2a05")
    (:PATH "tests/storage/control-payload.lisp" :GIT-BLOB
     "72358c6f324e1c7aaab2bb2c9d03d39ccf78f664")
    (:PATH "tests/storage/log-header.lisp" :GIT-BLOB
     "b3c4c96603ee769429b847569559defda5059744")
    (:PATH "tests/storage/segment-header.lisp" :GIT-BLOB
     "7155aaf2e9c0df4f96533a0be0f6532b54f44590")
    (:PATH "tests/storage/support.lisp" :GIT-BLOB
     "6aa5df3b3cc62b552f5da890583654b82df99431")
    (:PATH "tests/wal/builder.lisp" :GIT-BLOB
     "d62777cd09f8c30fc7246f59fd1bca8ea80c4559")
    (:PATH "tests/wal/fault.lisp" :GIT-BLOB
     "6361a87d73ce90f78438008693a7cd9d6461fe9b")
    (:PATH "tests/wal/group.lisp" :GIT-BLOB
     "04281d9ea3837ed2af0e7fa33b7e17df814982d7")
    (:PATH "tests/wal/native.lisp" :GIT-BLOB
     "077a835fb47524d97e449ae87c74461ebb374653")
    (:PATH "tests/wal/support.lisp" :GIT-BLOB
     "638262b264c64b96774ddb0a6095f4e582debe3e")))
  (:NAME "radix-id-missing-first-byte" :RESULT :DETECTED :EXIT-CODE 1 :ARGV
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/decisions-radix-isolated-build.lisp")
   :LOG
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/13/test.log"
    :GIT-BLOB "a6f71bb81e8a6e35a1adf8d42580497c79cfc8bb" :TEXT
    "decision-test-start TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
ok    TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
decision-test-start TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
ok    TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
decision-test-start TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
ok    TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
decision-test-start TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
ok    TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
ok    TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
decision-test-start TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
ok    TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
decision-test-start TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
ok    TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
decision-test-start TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
ok    TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
decision-test-start TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
ok    TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
decision-test-start TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
ok    TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
decision-test-start TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
ok    TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
decision-test-start TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
ok    TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
decision-test-start TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
ok    TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
decision-test-start TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
ok    TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
decision-test-start TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
ok    TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
decision-test-start TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
ok    TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
decision-test-start TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
ok    TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
decision-test-start TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
ok    TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
decision-test-start TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
ok    TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
decision-test-start TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
ok    TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
decision-test-start TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
ok    TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
decision-test-start TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
ok    TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
decision-test-start TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
ok    TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
decision-test-start TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
ok    TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
decision-test-start TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT
ok    TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT
decision-test-start TEST-REQ-TXM-005-RADIX-PARTICIPANT-CARDINALITIES-AND-PATTERNS
Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {8005AD0423}>:
  ArcDocDB: DECISION-PARTICIPANT-ORDER

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005AD0423}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8008411C83}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8008411C83}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8008411C83}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION :REASON :DECISION-PARTICIPANT-ORDER)
4: (ARCDOCDB.RECOVERY.DECISIONS::CHECK-PARTICIPANT-ORDER #(193 70 192 245 74 105 175 183 237 209 96 215 ...) 3 18446744073709551615)
5: (ARCDOCDB.RECOVERY.DECISIONS::RADIX-SORT-PARTICIPANTS #(193 70 192 245 74 105 175 183 237 209 96 215 ...) 3 18446744073709551615)
6: (RADIX-TEST-ASSERT-ID-SORTS #(79 200 247 207 3 238 136 117 176 171 93 232 ...) 18446744073709551615)
7: (TEST-REQ-TXM-005-RADIX-PARTICIPANT-CARDINALITIES-AND-PATTERNS)
8: (\"top level form\") [toplevel]
9: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
10: (SB-C::%COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL T T)
11: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 3 NIL)
12: (SB-IMPL::%SIMPLE-EVAL (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
13: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) #<NULL-LEXENV>)
14: (SB-EXT:EVAL-TLF (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3 NIL)
15: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) 3)
16: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((*PACKAGE* (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\") (ERROR \"Harness recovery non caricato.\"))) (*READ-EVAL* NIL) (COMMON-LISP-USER::DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*)) (COMMON-LISP-USER::FILES (QUOTE (\"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"))) (COMMON-LISP-USER::TESTS NIL)) (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\") (UNLESS (ASDF/COMPONENT:FIND-COMPONENT (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\") (QUOTE #)) (ERROR \"Test radix presente ma non registrato in ASDF.\")) (SETF COMMON-LISP-USER::FILES (APPEND COMMON-LISP-USER::FILES (QUOTE #)))) (DOLIST (COMMON-LISP-USER::FILE COMMON-LISP-USER::FILES) (LET ((COMMON-LISP-USER::SELECTED 0)) (WITH-OPEN-FILE (COMMON-LISP-USER::INPUT COMMON-LISP-USER::FILE :EXTERNAL-FORMAT :UTF-8) (LOOP COMMON-LISP-USER::FOR COMMON-LISP-USER::FORM = # COMMON-LISP-USER::UNTIL # WHEN # DO # #)) (UNLESS (PLUSP COMMON-LISP-USER::SELECTED) (ERROR \"File senza test DECISION: ~A\" COMMON-LISP-USER::FILE)))) (UNLESS (AND COMMON-LISP-USER::TESTS (EVERY (FUNCTION FBOUNDP) COMMON-LISP-USER::TESTS)) (ERROR \"Test DECISION non caricati dal sistema ASDF.\")) (SETF COMMON-LISP-USER::TESTS (NREVERSE COMMON-LISP-USER::TESTS)) (DOLIST (COMMON-LISP-USER::TEST COMMON-LISP-USER::TESTS) (FORMAT T \"~&decision-test-start ~A~%\" COMMON-LISP-USER::TEST) (FINISH-OUTPUT) (FUNCALL COMMON-LISP-USER::TEST) (FORMAT T \"ok    ~A~%\" COMMON-LISP-USER::TEST)) (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH COMMON-LISP-USER::TESTS))) :CURRENT-INDEX 3)
17: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1070F0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
18: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/13/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
19: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/13/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
20: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1070F09EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/13/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/13/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
21: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/13/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
22: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/13/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
23: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/13/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
24: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
25: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
26: (SB-IMPL::PROCESS-SCRIPT \"tools/decisions-radix-isolated-build.lisp\")
27: (SB-IMPL::TOPLEVEL-INIT)
28: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
29: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
30: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
   :RUNNER
   (:SOURCE-PATH
    "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-final-pen8ap8t/spikes/out/decisions-radix-mutants-final/13/tools/decisions-radix-isolated-build.lisp"
    :GIT-BLOB "f345ccd265e0eebbba7e7c0dc7dc02a817388443" :TEXT "(REQUIRE :ASDF)
(SETF UIOP/CONFIGURATION:*USER-CACHE* (MERGE-PATHNAMES \"fasl/\" (TRUENAME \"./\"))
      UIOP/LISP-BUILD:*COMPILE-FILE-FAILURE-BEHAVIOUR* :ERROR
      UIOP/LISP-BUILD:*COMPILE-FILE-WARNINGS-BEHAVIOUR* :ERROR)
(HANDLER-BIND ((WARNING
                (LAMBDA (CONDITION)
                  (UNLESS (TYPEP CONDITION 'SB-KERNEL:REDEFINITION-WARNING)
                    (ERROR \"~A non ammesso (COD-01): ~A\" (TYPE-OF CONDITION)
                           CONDITION)))))
  (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\")))
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T)
  (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))
(LET* ((*PACKAGE*
        (OR (FIND-PACKAGE \"ARCDOCDB.RECOVERY.TESTS\")
            (ERROR \"Harness recovery non caricato.\")))
       (*READ-EVAL* NIL)
       (DEFTEST (FIND-SYMBOL \"DEFTEST\" *PACKAGE*))
       (FILES
        '(\"tests/recovery/decisions.lisp\"
          \"tests/recovery/decisions-audit.lisp\"))
       (TESTS NIL))
  (WHEN (PROBE-FILE \"tests/recovery/decisions-radix.lisp\")
    (UNLESS
        (ASDF/COMPONENT:FIND-COMPONENT
         (ASDF/SYSTEM:FIND-SYSTEM \"arcdocdb/tests\")
         '(\"recovery\" \"decisions-radix\"))
      (ERROR \"Test radix presente ma non registrato in ASDF.\"))
    (SETF FILES (APPEND FILES '(\"tests/recovery/decisions-radix.lisp\"))))
  (DOLIST (FILE FILES)
    (LET ((SELECTED 0))
      (WITH-OPEN-FILE (INPUT FILE :EXTERNAL-FORMAT :UTF-8)
        (LOOP FOR FORM = (READ INPUT NIL :EOF)
              UNTIL (EQ FORM :EOF)
              WHEN (AND (CONSP FORM) (EQ (FIRST FORM) DEFTEST))
              DO (PUSH (SECOND FORM) TESTS) (INCF SELECTED)))
      (UNLESS (PLUSP SELECTED) (ERROR \"File senza test DECISION: ~A\" FILE))))
  (UNLESS (AND TESTS (EVERY #'FBOUNDP TESTS))
    (ERROR \"Test DECISION non caricati dal sistema ASDF.\"))
  (SETF TESTS (NREVERSE TESTS))
  (DOLIST (TEST TESTS)
    (FORMAT T \"~&decision-test-start ~A~%\" TEST)
    (FINISH-OUTPUT)
    (FUNCALL TEST)
    (FORMAT T \"ok    ~A~%\" TEST))
  (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH TESTS)))
")
   :SOURCE-BLOBS
   ((:PATH "src/foundation/batch.lisp" :GIT-BLOB
     "2cbd40c539b13dd80070eedf4af82bd1b26f4b28")
    (:PATH "src/foundation/binary.lisp" :GIT-BLOB
     "2d514f6fe2e81eecb29fa53de611fa5e28696904")
    (:PATH "src/foundation/conditions.lisp" :GIT-BLOB
     "dd5b46acca9106fb07e92e22ec4fbaca0cafa30a")
    (:PATH "src/foundation/crc32c.lisp" :GIT-BLOB
     "f9c691d28620427099d1d89a89a1ff5d04cbe257")
    (:PATH "src/foundation/package.lisp" :GIT-BLOB
     "0658b083f1e777aa0ada67a63535d36946921eac")
    (:PATH "src/foundation/record.lisp" :GIT-BLOB
     "8df53d416747131d9ed9921abb4ef356d9ce5696")
    (:PATH "src/io/flush.lisp" :GIT-BLOB
     "ba31b07379219fa8fd80fca169d43a053d28063b")
    (:PATH "src/io/lifecycle.lisp" :GIT-BLOB
     "0b93448ffe9c6dd4f3a0a2f3f35d5cd656700bd7")
    (:PATH "src/io/native.lisp" :GIT-BLOB
     "1b6fe64ea7145f33bcf08c02e8550034ebd6a40c")
    (:PATH "src/io/package.lisp" :GIT-BLOB
     "6b840a0eb039afa7e55304bffba309f0ab72acdc")
    (:PATH "src/io/transfer.lisp" :GIT-BLOB
     "93acbd608b1af475aa505a6a7dedceb3b15e8d4b")
    (:PATH "src/io/types.lisp" :GIT-BLOB
     "b496c1df87108127da568a1fb7b0fd32856afcc5")
    (:PATH "src/package.lisp" :GIT-BLOB
     "3d0181717e3f334580bab9a6a507e2dfe57261ff")
    (:PATH "src/recovery/decisions-build.lisp" :GIT-BLOB
     "87cc54024e59757c16e20f3025970b1699b11662")
    (:PATH "src/recovery/decisions-package.lisp" :GIT-BLOB
     "878fd1afdcbf035a232166ef87066af4420e1aae")
    (:PATH "src/recovery/decisions-query.lisp" :GIT-BLOB
     "a6ce94b8be3c8c84043abfd6441599f9780b2c11")
    (:PATH "src/recovery/decisions-radix.lisp" :GIT-BLOB
     "efb0005c0933d33f0d61bbf2e458e110e1f92539")
    (:PATH "src/recovery/decisions-sort.lisp" :GIT-BLOB
     "b133ea00a3b8063e9e934a1b41f10cad024471ae")
    (:PATH "src/recovery/decisions-types.lisp" :GIT-BLOB
     "0dbb2b3bdfbf5447a5904ce0fa6e4a97337a6827")
    (:PATH "src/recovery/package.lisp" :GIT-BLOB
     "b97b5c9bca6955e5dc45d9d4257089ab7132f3fb")
    (:PATH "src/recovery/scan.lisp" :GIT-BLOB
     "7ad6b7541397611f1ecbda7dffdda98c4453dbf1")
    (:PATH "src/storage/compaction-scan.lisp" :GIT-BLOB
     "233556c366a99b7b263af1c7bc19b47ceaebf940")
    (:PATH "src/storage/control-payload.lisp" :GIT-BLOB
     "7980cac6cc8070836b9aa49fc8a0d6fb42630749")
    (:PATH "src/storage/formats.lisp" :GIT-BLOB
     "fc942f1c8e30e637abaf13dc26343d40417fc72f")
    (:PATH "src/storage/log-header.lisp" :GIT-BLOB
     "fde8608e6ad3fe062937c48bdcb7d2d5870207bf")
    (:PATH "src/storage/package.lisp" :GIT-BLOB
     "c15553a65171e5dfb2dbadb62c92ed4dc48aee3a")
    (:PATH "src/storage/payload-record.lisp" :GIT-BLOB
     "0012eaf90064c4cc2949834a60e83c9db8ba6308")
    (:PATH "src/storage/payload-write.lisp" :GIT-BLOB
     "6cbbb89f681965173e9b1b95edf3f7f870af1eca")
    (:PATH "src/storage/segment-header.lisp" :GIT-BLOB
     "f1d99b205b1ea5e6ad059ecd7971d3633411b040")
    (:PATH "src/wal/builder.lisp" :GIT-BLOB
     "a488813eca3f6dcd251affd2017162861cd729d3")
    (:PATH "src/wal/executor.lisp" :GIT-BLOB
     "932eb39a61d9cf66d9394a25dac0e3912c3e3811")
    (:PATH "src/wal/group.lisp" :GIT-BLOB
     "ad43e8547f4b148116c00be5801ad82790240ff2")
    (:PATH "src/wal/package.lisp" :GIT-BLOB
     "608fca13f42115e74941bcbbe359d9541126c050")
    (:PATH "src/wal/types.lisp" :GIT-BLOB
     "adcfd153cb55c0c30d0ff7b610702315fc3cf485")
    (:PATH "tests/foundation/batch.lisp" :GIT-BLOB
     "00bb40ad87340ee86f5da281c09207c8da8888a6")
    (:PATH "tests/foundation/binary.lisp" :GIT-BLOB
     "ff6df200a7ace3af204b622969a387ce7a1e1504")
    (:PATH "tests/foundation/record.lisp" :GIT-BLOB
     "5c7c0d619e9637af6704ec51d564bbfdbc0df551")
    (:PATH "tests/foundation/support.lisp" :GIT-BLOB
     "d383b1cddf929ba0340d1b74eec3ec03673eac09")
    (:PATH "tests/io/native.lisp" :GIT-BLOB
     "bb3f9a460953d5575d7333b8b6eef6ecdb8e1e7d")
    (:PATH "tests/io/support.lisp" :GIT-BLOB
     "0179a0c19bdde944f47fe83716ecc6241e37c686")
    (:PATH "tests/io/transfer.lisp" :GIT-BLOB
     "40c8f4d5e2d493db090d5d09ab024c67ca6f4037")
    (:PATH "tests/lint-fixtures/bad.lisp" :GIT-BLOB
     "d0d5fd7285428e569d3dd595a0c38de5211e10a5")
    (:PATH "tests/lint-fixtures/good.lisp" :GIT-BLOB
     "35558ab0ab2be7688e9fd55a38be44ebe9a57f37")
    (:PATH "tests/recovery/corruption.lisp" :GIT-BLOB
     "2f9ead22a4e3b45cb3a680aa3a32a94bfcc6d77f")
    (:PATH "tests/recovery/decisions-audit.lisp" :GIT-BLOB
     "1b79a76515d8b8c2e67c46700cd6968b40047d62")
    (:PATH "tests/recovery/decisions-radix.lisp" :GIT-BLOB
     "232312cdd4ed6b1efcedc33ddda0fd8d1d8545d7")
    (:PATH "tests/recovery/decisions-support.lisp" :GIT-BLOB
     "f67450a9d681512a4b66efe1af1bfc82180e0058")
    (:PATH "tests/recovery/decisions.lisp" :GIT-BLOB
     "28d04d8738f077bf21ac22393a4014b518a6a0f2")
    (:PATH "tests/recovery/scan.lisp" :GIT-BLOB
     "1c7d71c32d58b05f7e06450680270cb55f6325dc")
    (:PATH "tests/recovery/support.lisp" :GIT-BLOB
     "f784671c59065b4363bcc5e49f06559b11e6562c")
    (:PATH "tests/smoke.lisp" :GIT-BLOB
     "6bd4ab9af1f3d9eedd54822eae10b7f167aa99ed")
    (:PATH "tests/storage/compaction-scan.lisp" :GIT-BLOB
     "16e5c9e5231883844ecd7956c7f790349acd2a05")
    (:PATH "tests/storage/control-payload.lisp" :GIT-BLOB
     "72358c6f324e1c7aaab2bb2c9d03d39ccf78f664")
    (:PATH "tests/storage/log-header.lisp" :GIT-BLOB
     "b3c4c96603ee769429b847569559defda5059744")
    (:PATH "tests/storage/segment-header.lisp" :GIT-BLOB
     "7155aaf2e9c0df4f96533a0be0f6532b54f44590")
    (:PATH "tests/storage/support.lisp" :GIT-BLOB
     "6aa5df3b3cc62b552f5da890583654b82df99431")
    (:PATH "tests/wal/builder.lisp" :GIT-BLOB
     "d62777cd09f8c30fc7246f59fd1bca8ea80c4559")
    (:PATH "tests/wal/fault.lisp" :GIT-BLOB
     "6361a87d73ce90f78438008693a7cd9d6461fe9b")
    (:PATH "tests/wal/group.lisp" :GIT-BLOB
     "04281d9ea3837ed2af0e7fa33b7e17df814982d7")
    (:PATH "tests/wal/native.lisp" :GIT-BLOB
     "077a835fb47524d97e449ae87c74461ebb374653")
    (:PATH "tests/wal/support.lisp" :GIT-BLOB
     "638262b264c64b96774ddb0a6095f4e582debe3e"))))
 :LIMITS
 (:EXACT-LOGS-AND-RUNNER :CHILD-ENVIRONMENT-NOT-RECONSTRUCTED :NO-MCDC-CLAIM))
