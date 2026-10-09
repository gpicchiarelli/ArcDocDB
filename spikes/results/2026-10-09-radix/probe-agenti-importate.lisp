(:SCHEMA-VERSION 1 :KIND :PROBE-IMPORT :ENTRIES
 ((:SOURCE-PATH
   "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/check.log"
   :GIT-BLOB "d4159e7e3e2e62e1ad5ca083a4d0178059d2be96" :TEXT
   "RADIX EQUIVALENCE OK: 1290 cases
RADIX DUPLICATE OFFSET OK
")
  (:SOURCE-PATH
   "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/compile-final.log"
   :GIT-BLOB "460c8e15ec3d0a6f307f3efe508ba42034c3cbb0" :TEXT
   "RADIX STRICT COMPILE OK
")
  (:SOURCE-PATH
   "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/compile-initial.log"
   :GIT-BLOB "460c8e15ec3d0a6f307f3efe508ba42034c3cbb0" :TEXT
   "RADIX STRICT COMPILE OK
")
  (:SOURCE-PATH
   "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/lint.log"
   :GIT-BLOB "7309c7d09f1d8f135ed0d616b1638dd0a5f62dfb" :TEXT
   "8 file, 0 violazioni
")
  (:SOURCE-PATH
   "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/build.lisp"
   :GIT-BLOB "a633c1251b1852bffec468c2f0f39912eefffed6" :TEXT "(require :asdf)
(handler-bind ((warning (lambda (c) (error \"Compilation warning: ~A\" c))))
  (loop for file in '(                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/foundation/package.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/foundation/conditions.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/foundation/binary.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/foundation/crc32c.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/foundation/record.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/foundation/batch.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/storage/package.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/storage/formats.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/storage/control-payload.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/storage/payload-record.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/recovery/package.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/recovery/scan.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/recovery/decisions-package.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/recovery/decisions-types.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/recovery/decisions-sort.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/recovery/decisions-build.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/recovery/decisions-query.lisp\"
                 \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/src/recovery/decisions-radix.lisp\")
        for i from 0
        do (multiple-value-bind (fasl warnings failure)
               (compile-file file :output-file (format nil \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/compile-~D.fasl\" i))
             (when (or warnings failure) (error \"Compilation failed: ~A\" file))
             (load fasl))))
(format t \"RADIX STRICT COMPILE OK~%\")
")
  (:SOURCE-PATH
   "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/check.lisp"
   :GIT-BLOB "9f285bf8187bddb153fcd2a6b9da54400d082cc8" :TEXT
   "(loop for i below 18 do (load (format nil \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-decisions-radix-6mry25zg/compile-~D.fasl\" i)))
(in-package #:arcdocdb.recovery.decisions)
(defun probe-id (value)
  (let ((id (make-array 16 :element-type '(unsigned-byte 8))))
    (dotimes (i 16 id)
      (setf (aref id i) (ldb (byte 8 (* 8 (- 15 i))) value)))))
(defun probe-entry (txid offset)
  (let ((parts (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)))
    (setf (aref parts 31) 1)
    (%make-decision-entry txid 0 2 parts offset)))
(let ((cases 0))
  (loop for n from 0 to 257 do
    (dotimes (pattern 2)
      (let ((input (make-array (* 16 n) :element-type '(unsigned-byte 8))))
        (dotimes (i n)
          (let ((key (+ 256 (- n i 1))))
            (replace input (probe-id (if (= pattern 0) key
                                        (+ (ash key 112) (ash key 56) key))) :start1 (* i 16))))
        (assert (equalp (sort-participants (copy-seq input) n 0)
                        (radix-sort-participants (copy-seq input) n 0)))
        (incf cases)))
    (dotimes (pattern 3)
      (let ((input (make-array n :element-type t)))
        (dotimes (i n)
          (let ((key (- n i 1)))
            (setf (aref input i)
                  (probe-entry (case pattern (0 key) (1 (mod key 3))
                                      (otherwise (logxor #xffffffffffffffff key))) i))))
        (let ((merge (sort-entries (copy-seq input)))
              (radix (radix-sort-entries (copy-seq input))))
          (dotimes (i n) (assert (eq (aref merge i) (aref radix i)))))
        (incf cases))))
  (format t \"RADIX EQUIVALENCE OK: ~D cases~%\" cases))
(let ((duplicates (make-array 32 :element-type '(unsigned-byte 8) :initial-element 255)))
  (handler-case (progn (radix-sort-participants duplicates 2 18446744073709551615)
                       (error \"Expected duplicate participant\"))
    (corruption-detected (condition)
      (assert (eq (arcdocdb.conditions:error-reason condition) :decision-duplicate-participant))
      (assert (= (arcdocdb.conditions:error-offset condition) 18446744073709551615)))))
(format t \"RADIX DUPLICATE OFFSET OK~%\")
")
  (:SOURCE-PATH
   "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/script-self-test.log"
   :GIT-BLOB "7fdb6514c6c3fb13656d0eb4f446560a0e210297" :TEXT
   "Benchmark ordinamenti: self-test superato.
")
  (:SOURCE-PATH
   "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/strict-attempt-02.log"
   :GIT-BLOB "01810164324c67ce5a72ca7ac226568bfd08a1ba" :TEXT
   "FULL DRIVER STRICT COMPILE OK
NIL
")
  (:SOURCE-PATH
   "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/strict-final.log"
   :GIT-BLOB "b48334bd75c9fbf90c44fd5f2dc5d6322b1c9fa6" :TEXT
   "FULL DRIVER STRICT COMPILE OK
Benchmark ordinamenti: self-test superato.
")
  (:SOURCE-PATH
   "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/strict-initial.log"
   :GIT-BLOB "facd0afa7e2fe6d1d955fcdd41f53f6700b3dca8" :TEXT
   "FULL DRIVER STRICT COMPILE OK
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80052703C3}>: Driver compilation warning: redefining PERFORM (#<STANDARD-CLASS ASDF/LISP-ACTION:TEST-OP> #<SB-MOP:EQL-SPECIALIZER #<SYSTEM \"arcdocdb/tests\">>) in DEFMETHOD

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80052703C3}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Driver compilation warning: ~A\" {80069462C3}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK SB-EXT:*INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Driver compilation warning: ~A\" {80069462C3}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Driver compilation warning: ~A\" {80069462C3}>)
3: (ERROR \"Driver compilation warning: ~A\" #<SB-KERNEL:REDEFINITION-WITH-DEFMETHOD {8006946253}>)
4: ((LAMBDA (COMMON-LISP-USER::C) :IN \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/strict.lisp\") #<SB-KERNEL:REDEFINITION-WITH-DEFMETHOD {8006946253}>)
5: (SB-KERNEL::%SIGNAL #<SB-KERNEL:REDEFINITION-WITH-DEFMETHOD {8006946253}>)
6: ((FLET SB-KERNEL::%WARN :IN \"SYS:SRC;CODE;WARM-ERROR.LISP\") SB-KERNEL:REDEFINITION-WITH-DEFMETHOD #<SB-KERNEL::CONDITION-CLASSOID WARNING> SIMPLE-WARNING :NAME PERFORM :NEW-LOCATION #S(SB-C:DEFINITION-SOURCE-LOCATION :NAMESTRING \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/arcdocdb.asd\" :INDICES 98304) :OLD-METHOD #<STANDARD-METHOD ASDF/ACTION:PERFORM (TEST-OP (EQL #<SYSTEM \"arcdocdb/tests\">)) {80055154B3}> :QUALIFIERS NIL :SPECIALIZERS (#<STANDARD-CLASS ASDF/LISP-ACTION:TEST-OP> #<SB-MOP:EQL-SPECIALIZER #<SYSTEM \"arcdocdb/tests\">>))
7: (SB-PCL::LOAD-DEFMETHOD-INTERNAL STANDARD-METHOD PERFORM NIL (#<STANDARD-CLASS ASDF/LISP-ACTION:TEST-OP> #<SB-MOP:EQL-SPECIALIZER #<SYSTEM \"arcdocdb/tests\">>) (O C) (:FUNCTION #<%METHOD-FUNCTION (LAMBDA (SB-PCL::METHOD-ARGS SB-PCL::NEXT-METHODS) :IN SB-PCL::METHOD-FUNCTION-FROM-FAST-FUNCTION) {800691C3CB}> SB-PCL::PLIST (:ARG-INFO (2)) SB-PCL::SIMPLE-NEXT-METHOD-CALL T) #S(SB-C:DEFINITION-SOURCE-LOCATION :NAMESTRING \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/arcdocdb.asd\" :INDICES 98304))
8: (SB-INT:SIMPLE-EVAL-IN-LEXENV (SB-PCL::%DEFMETHOD-EXPANDER PERFORM NIL ((O TEST-OP) (C (EQL #<SYSTEM \"arcdocdb/tests\">))) ((SYMBOL-CALL (QUOTE #:ARCDOCDB.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.FOUNDATION.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.EXECUTION.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.STORAGE.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.IO.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.RECOVERY.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.WAL.TESTS) (QUOTE #:RUN)))) #<NULL-LEXENV>)
9: (SB-INT:SIMPLE-EVAL-IN-LEXENV (EVAL-WHEN (:EXECUTE) (SB-PCL::%DEFMETHOD-EXPANDER PERFORM NIL ((O TEST-OP) (C (EQL #<SYSTEM \"arcdocdb/tests\">))) ((SYMBOL-CALL (QUOTE #:ARCDOCDB.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.FOUNDATION.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.EXECUTION.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.STORAGE.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.IO.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.RECOVERY.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.WAL.TESTS) (QUOTE #:RUN))))) #<NULL-LEXENV>)
10: (SB-INT:SIMPLE-EVAL-IN-LEXENV (DEFMETHOD PERFORM ((O TEST-OP) (C (EQL #<SYSTEM \"arcdocdb/tests\">))) (SYMBOL-CALL (QUOTE #:ARCDOCDB.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.FOUNDATION.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.EXECUTION.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.STORAGE.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.IO.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.RECOVERY.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.WAL.TESTS) (QUOTE #:RUN))) #<NULL-LEXENV>)
11: (EVAL (DEFMETHOD PERFORM ((O TEST-OP) (C (EQL #<SYSTEM \"arcdocdb/tests\">))) (SYMBOL-CALL (QUOTE #:ARCDOCDB.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.FOUNDATION.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.EXECUTION.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.STORAGE.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.IO.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.RECOVERY.TESTS) (QUOTE #:RUN)) (SYMBOL-CALL (QUOTE #:ARCDOCDB.WAL.TESTS) (QUOTE #:RUN))))
12: (ASDF/PARSE-DEFSYSTEM::%DEFINE-COMPONENT-INLINE-METHODS #<SYSTEM \"arcdocdb/tests\"> (:PATHNAME #P\"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/tests/\" :DESCRIPTION \"Test di ArcDocDB.\" :AUTHOR \"Giacomo Picchiarelli\" :LICENSE \"BSD-2-Clause\" :DEPENDS-ON (\"arcdocdb\") :PATHNAME \"tests/\" ...))
13: (ASDF/PARSE-DEFSYSTEM:PARSE-COMPONENT-FORM NIL (:MODULE \"arcdocdb/tests\" :PATHNAME #P\"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/tests/\" :DESCRIPTION \"Test di ArcDocDB.\" :AUTHOR \"Giacomo Picchiarelli\" :LICENSE \"BSD-2-Clause\" :DEPENDS-ON (\"arcdocdb\") ...) :PREVIOUS-SERIAL-COMPONENT NIL)
14: (SB-INT:SIMPLE-EVAL-IN-LEXENV (DEFSYSTEM \"arcdocdb/tests\" :DESCRIPTION \"Test di ArcDocDB.\" :AUTHOR \"Giacomo Picchiarelli\" :LICENSE \"BSD-2-Clause\" :DEPENDS-ON (\"arcdocdb\") :PATHNAME \"tests/\" ...) #<NULL-LEXENV>)
15: (SB-EXT:EVAL-TLF (DEFSYSTEM \"arcdocdb/tests\" :DESCRIPTION \"Test di ArcDocDB.\" :AUTHOR \"Giacomo Picchiarelli\" :LICENSE \"BSD-2-Clause\" :DEPENDS-ON (\"arcdocdb\") :PATHNAME \"tests/\" ...) 2 NIL)
16: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (DEFSYSTEM \"arcdocdb/tests\" :DESCRIPTION \"Test di ArcDocDB.\" :AUTHOR \"Giacomo Picchiarelli\" :LICENSE \"BSD-2-Clause\" :DEPENDS-ON (\"arcdocdb\") :PATHNAME \"tests/\" ...) 2)
17: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (DEFSYSTEM \"arcdocdb/tests\" :DESCRIPTION \"Test di ArcDocDB.\" :AUTHOR \"Giacomo Picchiarelli\" :LICENSE \"BSD-2-Clause\" :DEPENDS-ON (\"arcdocdb\") :PATHNAME \"tests/\" ...) :CURRENT-INDEX 2)
18: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1071D374B}> #<SB-C::SOURCE-INFO {80067CFE63}> SB-C::INPUT-ERROR-IN-LOAD)
19: (SB-INT:LOAD-AS-SOURCE #<SB-INT:FORM-TRACKING-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/arcdocdb.asd\" {8006893793}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
20: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/arcdocdb.asd\" {8006893793}> NIL)
21: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1071D321B}> #<SB-INT:FORM-TRACKING-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/arcdocdb.asd\" {8006893793}> NIL #<SB-INT:FORM-TRACKING-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/arcdocdb.asd\" {8006893793}>)
22: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/arcdocdb.asd\" {8006893793}> NIL)
23: (LOAD #P\"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/arcdocdb.asd\" :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :UTF-8)
24: (CALL-WITH-MUFFLED-CONDITIONS #<FUNCTION (LAMBDA NIL :IN LOAD*) {80068921DB}> (\"Overwriting already existing readtable ~S.\" #(#:FINALIZERS-OFF-WARNING :ASDF-FINALIZERS)))
25: ((FLET \"THUNK\" :IN PERFORM))
26: (SB-IMPL::%WITH-STANDARD-IO-SYNTAX #<FUNCTION (FLET \"THUNK\" :IN PERFORM) {1071D2F6B}>)
27: ((:METHOD PERFORM (DEFINE-OP SYSTEM)) #<DEFINE-OP > #<SYSTEM \"arcdocdb\">) [fast-method]
28: ((SB-PCL::EMF PERFORM) #<unused argument> #<unused argument> #<DEFINE-OP > #<SYSTEM \"arcdocdb\">)
29: ((LAMBDA NIL :IN ASDF/ACTION:CALL-WHILE-VISITING-ACTION))
30: ((:METHOD PERFORM-WITH-RESTARTS :AROUND (T T)) #<DEFINE-OP > #<SYSTEM \"arcdocdb\">) [fast-method]
31: ((:METHOD PERFORM-PLAN (T)) #<SEQUENTIAL-PLAN {80067CEF53}>) [fast-method]
32: ((FLET SB-C::WITH-IT :IN SB-C::%WITH-COMPILATION-UNIT))
33: ((:METHOD PERFORM-PLAN :AROUND (T)) #<SEQUENTIAL-PLAN {80067CEF53}>) [fast-method]
34: ((:METHOD OPERATE (OPERATION COMPONENT)) #<DEFINE-OP > #<SYSTEM \"arcdocdb\"> :PLAN-CLASS NIL :PLAN-OPTIONS NIL) [fast-method]
35: ((SB-PCL::EMF OPERATE) #<unused argument> #<unused argument> #<DEFINE-OP > #<SYSTEM \"arcdocdb\">)
36: ((LAMBDA NIL :IN OPERATE))
37: ((:METHOD OPERATE :AROUND (T T)) #<DEFINE-OP > #<SYSTEM \"arcdocdb\">) [fast-method]
38: ((LAMBDA NIL :IN FIND-SYSTEM))
39: (ASDF/SESSION:CONSULT-ASDF-CACHE (FIND-SYSTEM \"arcdocdb\") #<FUNCTION (LAMBDA NIL :IN FIND-SYSTEM) {800688FCCB}>)
40: ((:METHOD FIND-COMPONENT (STRING T)) \"arcdocdb\" (NIL) :REGISTERED NIL) [fast-method]
41: ((:METHOD OPERATE (OPERATION T)) #<DEFINE-OP > (\"arcdocdb\")) [fast-method]
42: ((SB-PCL::EMF OPERATE) #<unused argument> #<unused argument> #<DEFINE-OP > (\"arcdocdb\"))
43: ((LAMBDA NIL :IN OPERATE))
44: ((:METHOD OPERATE :AROUND (T T)) #<DEFINE-OP > (\"arcdocdb\")) [fast-method]
45: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN OPERATE) {800688FA6B}> :OVERRIDE T :KEY NIL :OVERRIDE-CACHE T :OVERRIDE-FORCING NIL)
46: ((LAMBDA NIL :IN OPERATE))
47: ((:METHOD OPERATE :AROUND (T T)) #<DEFINE-OP > #<SYSTEM \"arcdocdb\">) [fast-method]
48: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN LOAD-ASD) {800688EB6B}> :OVERRIDE NIL :KEY NIL :OVERRIDE-CACHE NIL :OVERRIDE-FORCING NIL)
49: (ARCDOCDB.DECISIONS.SORT-BENCH::LOAD-PRODUCT)
50: (\"top level form\") [toplevel]
51: (SB-FASL::LOAD-FASL-GROUP #S(SB-FASL::FASL-INPUT :STREAM #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/tools/driver.fasl\" {8006884B23}> :TABLE #(348 #1=\"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/tools/decisions-sort-bench.lisp\" REQUIRE #<PACKAGE \"SB-IMPL\"> SB-IMPL::%DEFPACKAGE :ASDF :SB-POSIX #2=\"ARCDOCDB.DECISIONS.SORT-BENCH\" #3=\"CL\" (#3#) (#2#) #<SB-KERNEL:LAYOUT (ID=-5) for SB-C:DEFINITION-SOURCE-LOCATION {8003032803}> ...) :STACK #(0 #<FUNCTION \"top level form\" {8005AA212B}> #<SB-KERNEL:FDEFN ARCDOCDB.DECISIONS.SORT-BENCH::LOAD-PRODUCT> #<SB-KERNEL:FDEFN SB-IMPL::%DEFCONSTANT> #<SB-KERNEL:FDEFN SB-KERNEL::%DEFINE-CONDITION> #<SB-KERNEL:FDEFN SB-KERNEL::%SET-CONDITION-REPORT> ARCDOCDB.DECISIONS.SORT-BENCH::LOAD-PRODUCT ARCDOCDB.DECISIONS.SORT-BENCH::+SEED+ #S(SB-C:DEFINITION-SOURCE-LOCATION :NAMESTRING #1# :INDICES 262145) ARCDOCDB.DECISIONS.SORT-BENCH::+MASK+ 18446744073709551615 #S(SB-C:DEFINITION-SOURCE-LOCATION :NAMESTRING #1# :INDICES 294913) ...) :NAME-BUFFER #(\" \" \"REPORTER-PROBE-FAILURES+RAVIOUR**\") :PRINT NIL :CODEBLOBS NIL :PARTIAL-SOURCE-INFO #S(SB-C::DEBUG-SOURCE :NAMESTRING #1# :CREATED 4000509384 :START-POSITIONS NIL :PLIST NIL)))
52: ((LAMBDA NIL :IN SB-FASL::LOAD-AS-FASL))
53: (SB-IMPL::CALL-WITH-LOADER-PACKAGE-NAMES #<FUNCTION (LAMBDA NIL :IN SB-FASL::LOAD-AS-FASL) {800688802B}>)
54: (SB-FASL::LOAD-AS-FASL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/tools/driver.fasl\" {8006884B23}> NIL NIL)
55: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/tools/driver.fasl\" {8006884B23}> T)
56: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1071D189B}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/tools/driver.fasl\" {8006884B23}> T #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/tools/driver.fasl\" {8006884B23}>)
57: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/tools/driver.fasl\" {8006884B23}> T)
58: (LOAD #P\"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/tools/driver.fasl\" :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
59: (\"top level form\") [toplevel]
60: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
61: (SB-C::%COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LIST #) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (PROGN (MULTIPLE-VALUE-BIND (COMMON-LISP-USER::FASL COMMON-LISP-USER::WARNINGS COMMON-LISP-USER::FAILURE) (COMPILE-FILE \"tools/decisions-sort-bench.lisp\" :OUTPUT-FILE \"driver.fasl\") (WHEN (OR COMMON-LISP-USER::WARNINGS COMMON-LISP-USER::FAILURE) (ERROR \"Full driver compilation failed\")) (FORMAT T \"FULL DRIVER STRICT COMPILE OK~%\") (LOAD COMMON-LISP-USER::FASL)))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {8003870423}> 6 NIL T T)
62: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LIST #) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (PROGN (MULTIPLE-VALUE-BIND (COMMON-LISP-USER::FASL COMMON-LISP-USER::WARNINGS COMMON-LISP-USER::FAILURE) (COMPILE-FILE \"tools/decisions-sort-bench.lisp\" :OUTPUT-FILE \"driver.fasl\") (WHEN (OR COMMON-LISP-USER::WARNINGS COMMON-LISP-USER::FAILURE) (ERROR \"Full driver compilation failed\")) (FORMAT T \"FULL DRIVER STRICT COMPILE OK~%\") (LOAD COMMON-LISP-USER::FASL)))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {8003870423}> 6 NIL)
63: (SB-IMPL::%SIMPLE-EVAL (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LIST #) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (PROGN (MULTIPLE-VALUE-BIND (COMMON-LISP-USER::FASL COMMON-LISP-USER::WARNINGS COMMON-LISP-USER::FAILURE) (COMPILE-FILE \"tools/decisions-sort-bench.lisp\" :OUTPUT-FILE \"driver.fasl\") (WHEN (OR COMMON-LISP-USER::WARNINGS COMMON-LISP-USER::FAILURE) (ERROR \"Full driver compilation failed\")) (FORMAT T \"FULL DRIVER STRICT COMPILE OK~%\") (LOAD COMMON-LISP-USER::FASL)))) #<NULL-LEXENV>)
64: (SB-INT:SIMPLE-EVAL-IN-LEXENV (HANDLER-BIND ((WARNING (LAMBDA (COMMON-LISP-USER::C) (ERROR \"Driver compilation warning: ~A\" COMMON-LISP-USER::C)))) (MULTIPLE-VALUE-BIND (COMMON-LISP-USER::FASL COMMON-LISP-USER::WARNINGS COMMON-LISP-USER::FAILURE) (COMPILE-FILE \"tools/decisions-sort-bench.lisp\" :OUTPUT-FILE \"driver.fasl\") (WHEN (OR COMMON-LISP-USER::WARNINGS COMMON-LISP-USER::FAILURE) (ERROR \"Full driver compilation failed\")) (FORMAT T \"FULL DRIVER STRICT COMPILE OK~%\") (LOAD COMMON-LISP-USER::FASL))) #<NULL-LEXENV>)
65: (SB-EXT:EVAL-TLF (HANDLER-BIND ((WARNING (LAMBDA (COMMON-LISP-USER::C) (ERROR \"Driver compilation warning: ~A\" COMMON-LISP-USER::C)))) (MULTIPLE-VALUE-BIND (COMMON-LISP-USER::FASL COMMON-LISP-USER::WARNINGS COMMON-LISP-USER::FAILURE) (COMPILE-FILE \"tools/decisions-sort-bench.lisp\" :OUTPUT-FILE \"driver.fasl\") (WHEN (OR COMMON-LISP-USER::WARNINGS COMMON-LISP-USER::FAILURE) (ERROR \"Full driver compilation failed\")) (FORMAT T \"FULL DRIVER STRICT COMPILE OK~%\") (LOAD COMMON-LISP-USER::FASL))) 6 NIL)
66: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (LAMBDA (COMMON-LISP-USER::C) (ERROR \"Driver compilation warning: ~A\" COMMON-LISP-USER::C)))) (MULTIPLE-VALUE-BIND (COMMON-LISP-USER::FASL COMMON-LISP-USER::WARNINGS COMMON-LISP-USER::FAILURE) (COMPILE-FILE \"tools/decisions-sort-bench.lisp\" :OUTPUT-FILE \"driver.fasl\") (WHEN (OR COMMON-LISP-USER::WARNINGS COMMON-LISP-USER::FAILURE) (ERROR \"Full driver compilation failed\")) (FORMAT T \"FULL DRIVER STRICT COMPILE OK~%\") (LOAD COMMON-LISP-USER::FASL))) 6)
67: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (LAMBDA (COMMON-LISP-USER::C) (ERROR \"Driver compilation warning: ~A\" COMMON-LISP-USER::C)))) (MULTIPLE-VALUE-BIND (COMMON-LISP-USER::FASL COMMON-LISP-USER::WARNINGS COMMON-LISP-USER::FAILURE) (COMPILE-FILE \"tools/decisions-sort-bench.lisp\" :OUTPUT-FILE \"driver.fasl\") (WHEN (OR COMMON-LISP-USER::WARNINGS COMMON-LISP-USER::FAILURE) (ERROR \"Full driver compilation failed\")) (FORMAT T \"FULL DRIVER STRICT COMPILE OK~%\") (LOAD COMMON-LISP-USER::FASL))) :CURRENT-INDEX 6)
68: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1071D0F1B}> #<SB-C::SOURCE-INFO {8003870423}> SB-C::INPUT-ERROR-IN-LOAD)
69: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/strict.lisp\" {8003870043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
70: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/strict.lisp\" {8003870043}> NIL)
71: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1071D09EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/strict.lisp\" {8003870043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/strict.lisp\" {8003870043}>)
72: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/strict.lisp\" {8003870043}> NIL)
73: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/strict.lisp\" {8003870043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
74: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/strict.lisp\" {8003870043}>)
75: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
76: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
77: (SB-IMPL::PROCESS-SCRIPT \"strict.lisp\")
78: (SB-IMPL::TOPLEVEL-INIT)
79: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
80: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
81: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
; 
; compilation unit aborted
;   caught 1 fatal ERROR condition
")
  (:SOURCE-PATH
   "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-driver-06xb5leo/strict.lisp"
   :GIT-BLOB "89a7e1fa6862aa313a79a849a9e4e0feb83b8887" :TEXT "(require :asdf)
(require :sb-posix)
(asdf:initialize-output-translations `(:output-translations (,(truename \"./\") ,(merge-pathnames \"fasl/\" (truename \"./\"))) :ignore-inherited-configuration))
(setf asdf:*compile-file-warnings-behaviour* :error asdf:*compile-file-failure-behaviour* :error)
(handler-bind ((warning (lambda (c) (error \"Product preparation warning: ~A\" c))))
  (asdf:load-asd (truename \"arcdocdb.asd\"))
  (asdf:load-system \"arcdocdb\"))
(unless (fboundp 'arcdocdb.recovery.decisions::radix-sort-entries)
  (handler-bind ((warning (lambda (c) (error \"Candidate warning: ~A\" c))))
    (multiple-value-bind (fasl warnings failure)
        (compile-file \"src/recovery/decisions-radix.lisp\" :output-file \"radix.fasl\")
      (when (or warnings failure) (error \"Candidate compilation failed\"))
      (load fasl))))
(handler-bind ((warning (lambda (c) (error \"Driver compilation warning: ~A\" c))))
  (multiple-value-bind (fasl warnings failure)
      (compile-file \"tools/decisions-sort-bench.lisp\" :output-file \"driver.fasl\")
    (when (or warnings failure) (error \"Full driver compilation failed\"))
    (format t \"FULL DRIVER STRICT COMPILE OK~%\")
    (load fasl)))
")
  (:SOURCE-PATH
   "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-test-final-4gdf32sf/baseline/test.log"
   :GIT-BLOB "149284bc97905ce2a89b407a736fb342cc8f133b" :TEXT "; 
; caught ERROR:
;   READ error during COMPILE-FILE:
;   
;     unmatched close parenthesis
;   
;       Line: 410, Column: 67, File-Position: 22743
;   
;       Stream: #<SB-INT:FORM-TRACKING-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-test-final-4gdf32sf/baseline/tests/recovery/decisions-radix.lisp\" {8009520393}>
Unhandled UIOP/LISP-BUILD:COMPILE-FILE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                          {8005A003C3}>:
  COMPILE-FILE-ERROR while
  compiling #<CL-SOURCE-FILE \"arcdocdb/tests\" \"recovery\" \"decisions-radix\">

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005A003C3}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<UIOP/LISP-BUILD:COMPILE-FILE-ERROR {80083E2A63}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<UIOP/LISP-BUILD:COMPILE-FILE-ERROR {80083E2A63}>)
2: (INVOKE-DEBUGGER #<UIOP/LISP-BUILD:COMPILE-FILE-ERROR {80083E2A63}>)
3: (ERROR UIOP/LISP-BUILD:COMPILE-FILE-ERROR :CONTEXT-FORMAT \"~/asdf-action::format-action/\" :CONTEXT-ARGUMENTS ((#<ASDF/LISP-ACTION:COMPILE-OP > . #<ASDF/LISP-ACTION:CL-SOURCE-FILE \"arcdocdb/tests\" \"recovery\" \"decisions-radix\">)))
4: (UIOP/LISP-BUILD:CHECK-LISP-COMPILE-RESULTS NIL T T \"~/asdf-action::format-action/\" ((#<ASDF/LISP-ACTION:COMPILE-OP > . #<ASDF/LISP-ACTION:CL-SOURCE-FILE \"arcdocdb/tests\" \"recovery\" \"decisions-radix\">)))
5: ((SB-PCL::EMF ASDF/ACTION:PERFORM) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:COMPILE-OP > #<ASDF/LISP-ACTION:CL-SOURCE-FILE \"arcdocdb/tests\" \"recovery\" \"decisions-radix\">)
6: ((LAMBDA NIL :IN ASDF/ACTION:CALL-WHILE-VISITING-ACTION))
7: ((:METHOD ASDF/ACTION:PERFORM-WITH-RESTARTS :AROUND (T T)) #<ASDF/LISP-ACTION:COMPILE-OP > #<ASDF/LISP-ACTION:CL-SOURCE-FILE \"arcdocdb/tests\" \"recovery\" \"decisions-radix\">) [fast-method]
8: ((:METHOD ASDF/PLAN:PERFORM-PLAN (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052B09A3}>) [fast-method]
9: ((FLET SB-C::WITH-IT :IN SB-C::%WITH-COMPILATION-UNIT))
10: ((:METHOD ASDF/PLAN:PERFORM-PLAN :AROUND (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052B09A3}>) [fast-method]
11: ((:METHOD ASDF/OPERATE:OPERATE (ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT)) #<ASDF/LISP-ACTION:LOAD-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\"> :PLAN-CLASS NIL :PLAN-OPTIONS NIL) [fast-method]
12: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:LOAD-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\"> :FORCE T)
13: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
14: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) #<ASDF/LISP-ACTION:LOAD-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\"> :FORCE T) [fast-method]
15: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> ASDF/LISP-ACTION:LOAD-OP \"arcdocdb/tests\" :FORCE T)
16: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
17: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:LOAD-OP \"arcdocdb/tests\" :FORCE T) [fast-method]
18: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052B080B}> :OVERRIDE T :KEY NIL :OVERRIDE-CACHE T :OVERRIDE-FORCING NIL)
19: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
20: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052B073B}> :OVERRIDE NIL :KEY NIL :OVERRIDE-CACHE NIL :OVERRIDE-FORCING NIL)
21: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:LOAD-OP \"arcdocdb/tests\" :FORCE T) [fast-method]
22: (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T)
23: (\"top level form\") [toplevel]
24: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
25: (SB-C::%COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LIST #) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 2 NIL T T)
26: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LIST #) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 2 NIL)
27: (SB-IMPL::%SIMPLE-EVAL (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LIST #) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T))) #<NULL-LEXENV>)
28: (SB-INT:SIMPLE-EVAL-IN-LEXENV (HANDLER-BIND ((WARNING (LAMBDA (CONDITION) (UNLESS # #)))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T)) #<NULL-LEXENV>)
29: (EVAL-TLF (HANDLER-BIND ((WARNING (LAMBDA (CONDITION) (UNLESS # #)))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T)) 2 NIL)
30: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (LAMBDA (CONDITION) (UNLESS # #)))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T)) 2)
31: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (LAMBDA (CONDITION) (UNLESS # #)))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb/tests\" :FORCE T)) :CURRENT-INDEX 2)
32: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {109370F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
33: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-test-final-4gdf32sf/baseline/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
34: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-test-final-4gdf32sf/baseline/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
35: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1093709EB}> #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-test-final-4gdf32sf/baseline/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-test-final-4gdf32sf/baseline/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
36: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-test-final-4gdf32sf/baseline/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> NIL)
37: (LOAD #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-test-final-4gdf32sf/baseline/tools/decisions-radix-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
38: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-test-final-4gdf32sf/baseline/tools/decisions-radix-isolated-build.lisp\" {80052B0043}>)
39: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
40: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
41: (SB-IMPL::PROCESS-SCRIPT \"tools/decisions-radix-isolated-build.lisp\")
42: (SB-IMPL::TOPLEVEL-INIT)
43: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
44: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
45: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
; 
; compilation unit aborted
;   caught 2 fatal ERROR conditions
;   caught 1 ERROR condition
")
  (:SOURCE-PATH
   "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-test-final-4gdf32sf/probe.log"
   :GIT-BLOB "29ad85685b218efe34ac9f89d63b1418b733d3c3" :TEXT
   "radix-probe-result :COMPILATION-FAILURE exit 1 log /var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-test-final-4gdf32sf/baseline/test.log
")
  (:SOURCE-PATH
   "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-test-final-4gdf32sf/baseline/tests/recovery/decisions-radix.lisp"
   :GIT-BLOB "c52a34d51a7861fad565c69054e2bd08f8a7d6b8" :TEXT
   ";;;; Oracoli indipendenti per gli ordinamenti DECISION e lettori concorrenti.
(in-package #:arcdocdb.recovery.tests)

(defun radix-test-packed-ids (ids)
  \"Concatena gli ID16 dichiarati dalla fixture, senza primitive del prodotto.\"
  (let ((packed (make-array (* 16 (length ids)) :element-type '(unsigned-byte 8))))
    (loop for id in ids for position from 0
          do (replace packed id :start1 (* 16 position)))
    packed))

(defun radix-test-id-number (packed start)
  \"Interpreta un ID16 come intero big-endian, indipendentemente dal comparatore.\"
  (reduce (lambda (number byte) (+ (* number 256) byte)) packed
          :start start :end (+ start 16) :initial-value 0))

(defun radix-test-id-oracle (packed)
  \"Ordina interi con CL:STABLE-SORT e ricostruisce tutti i 128 bit degli ID.\"
  (let* ((count (/ (length packed) 16))
         (numbers (make-array count :element-type t))
         (result (make-array (length packed) :element-type '(unsigned-byte 8))))
    (dotimes (i count) (setf (aref numbers i) (radix-test-id-number packed (* i 16))))
    (setf numbers (stable-sort numbers #'<))
    (dotimes (i count)
      (dotimes (byte 16)
        (setf (aref result (+ (* i 16) byte))
              (ldb (byte 8 (* 8 (- 15 byte))) (aref numbers i)))))
    result))

(defun radix-test-id-fixture (count pattern)
  \"ID unici, cardinalità nota e seme locale; ultimi due byte dichiarano l'identità.\"
  (let ((packed (make-array (* count 16) :element-type '(unsigned-byte 8)))
        (state 193))
    (dotimes (position count)
      (let ((number (- count position 1)) (start (* position 16)))
        (dotimes (byte 14)
          (setf state (logand #xffffffff (+ (* state 1664525) 1013904223)))
          (setf (aref packed (+ start byte))
                (case pattern
                  (:uniform #xa5)
                  (:random (ldb (byte 8 24) state))
                  (:cluster #x80)
                  (otherwise (error \"Pattern della fixture sconosciuto: ~S\" pattern)))))
        (when (eq pattern :cluster)
          (setf (aref packed start) (mod (floor number 17) 3)
                (aref packed (+ start 7)) (if (oddp number) #xff 0)))
        (setf (aref packed (+ start 14)) (ldb (byte 8 8) number)
              (aref packed (+ start 15)) (ldb (byte 8 0) number))))
    packed))

(defun radix-test-assert-id-sorts (packed source-offset)
  \"Confronta radix e merge con un oracolo numerico, su copie private distinte.\"
  (let ((expected (radix-test-id-oracle packed)) (before (copy-seq packed))
        (count (/ (length packed) 16)))
    (dolist (sorter (list #'arcdocdb.recovery.decisions::radix-sort-participants
                          #'arcdocdb.recovery.decisions::sort-participants))
      (let ((result (funcall sorter (copy-seq packed) count source-offset)))
        (is (typep result '(simple-array (unsigned-byte 8) (*))))
        (is (equalp expected result))))
    (is (equalp packed before))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-TXM-005-radix-participant-cardinalities-and-patterns
  (dolist (count '(0 1 2 3 5 17 256 257 65535))
    (dolist (pattern '(:uniform :random :cluster))
      (radix-test-assert-id-sorts (radix-test-id-fixture count pattern)
                                #xffffffffffffffff))))

;;; REQ: REQ-TXM-001 REQ-TXM-005 REQ-FOR-003
(deftest test-REQ-TXM-001-radix-participant-every-byte-and-bit
  (let ((base (make-array 16 :element-type '(unsigned-byte 8) :initial-element #x80)))
    (dotimes (byte 16)
      (dotimes (bit 8)
        (let ((changed (copy-seq base)))
          (setf (aref changed byte) (logxor #x80 (ash 1 bit)))
          (radix-test-assert-id-sorts (radix-test-packed-ids (list base changed)) 17)
          (radix-test-assert-id-sorts (radix-test-packed-ids (list changed base)) 17))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-017
(deftest test-REQ-TXM-005-radix-duplicate-participant-offset
  (dolist (offset '(0 4294967296 18446744073709551615))
    (dolist (count '(2 3 5 17 257))
      (let ((packed (radix-test-id-fixture count :random)))
        (replace packed packed :start1 (* 16 (1- count)) :end1 (* 16 count)
                                :start2 0 :end2 16)
        (dolist (sorter (list #'arcdocdb.recovery.decisions::radix-sort-participants
                              #'arcdocdb.recovery.decisions::sort-participants))
          (let ((condition (signals corruption-detected
                                   (funcall sorter (copy-seq packed) count offset)
                                   :decision-duplicate-participant)))
            (is (= offset (error-offset condition)))))))))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-TXM-005-radix-participant-shape-before-sort
  (dolist (size '(0 15 17 32))
    (let ((packed (make-array size :element-type '(unsigned-byte 8) :initial-element 0)))
      (dolist (sorter (list #'arcdocdb.recovery.decisions::radix-sort-participants
                            #'arcdocdb.recovery.decisions::sort-participants))
        (signals arcdocdb.conditions:invariant-violation
                 (funcall sorter packed 1 0) :decision-participant-size)))))

(defun radix-test-entry-fixture (count pattern)
  \"Entry dichiarate con offset crescenti; TXID uguali conservano l'ordine fisico.\"
  (let ((entries (make-array count :element-type t)) (state 913)
        (participants (radix-test-packed-ids (list (participant-id 0) (participant-id 1))))
        (extremes (vector 0 #xffffffffffffffff #x8000000000000000
                          #x7fffffffffffffff #x100000000 #xff #x100 1)))
    (dotimes (i count)
      (setf state (logand #xffffffffffffffff
                         (+ (* state 6364136223846793005) 1442695040888963407)))
      (let ((txid (case pattern
                    (:uniform #xffffffffffffffff)
                    (:random state)
                    (:cluster (aref extremes (mod i (length extremes))))
                    (:dominant (if (= i (1- count)) 0 #xffffffffffffffff))
                    (otherwise (error \"Pattern delle entry sconosciuto: ~S\" pattern)))))
        (setf (aref entries i)
              (arcdocdb.recovery.decisions::%make-decision-entry
                txid (- #xffffffffffffffff i) 2 participants (+ (ash 1 63) (* i 64))))))
    entries))

(defun radix-test-entry-oracle (entries)
  \"CL:STABLE-SORT sul solo TXID; l'identità delle entry prova anche la stabilità.\"
  (stable-sort (copy-seq entries) #'< :key #'arcdocdb.recovery.decisions::%entry-txid))

(defun radix-test-assert-entry-sorts (entries)
  \"Oracolo indipendente dal merge e dal radix; nessuna ricostruzione dei loro passaggi.\"
  (let ((expected (radix-test-entry-oracle entries)) (before (copy-seq entries)))
    (dolist (sorter (list #'arcdocdb.recovery.decisions::radix-sort-entries
                          #'arcdocdb.recovery.decisions::sort-entries))
      (let ((result (funcall sorter (copy-seq entries))))
        (is (= (length expected) (length result)))
        (dotimes (i (length expected))
          (is (eq (aref expected i) (aref result i)))
          (when (and (plusp i)
                     (= (arcdocdb.recovery.decisions::%entry-txid (aref result (1- i)))
                        (arcdocdb.recovery.decisions::%entry-txid (aref result i))))
            (is (< (arcdocdb.recovery.decisions::%entry-source-offset (aref result (1- i)))
                   (arcdocdb.recovery.decisions::%entry-source-offset (aref result i))))))))
    (is (equalp entries before))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008
(deftest test-REQ-TXM-005-radix-entry-cardinalities-patterns-and-stability
  (dolist (count '(0 1 2 3 5 17 256 257 65535))
    (dolist (pattern '(:uniform :random :cluster))
      (radix-test-assert-entry-sorts (radix-test-entry-fixture count pattern)))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008
(deftest test-REQ-AFF-008-radix-entry-65536-bucket-counts
  ;; Il numero di DECISION fisiche non è limitato al count u16 dei partecipanti.
  ;; Una classe con 65.536 entry e una classe dominante con un outlier
  ;; rendono osservabili sia il conteggio sia il cursore finale oltre u16.
  (dolist (pattern '(:uniform :dominant))
    (radix-test-assert-entry-sorts (radix-test-entry-fixture 65536 pattern))))

;;; REQ: REQ-TXM-001 REQ-TXM-005
(deftest test-REQ-TXM-001-radix-entry-every-txid-bit
  (dotimes (bit 64)
    (let* ((a (arcdocdb.recovery.decisions::%make-decision-entry
                #x8000000000000000 0 2
                (radix-test-id-oracle (radix-test-id-fixture 2 :uniform)) 31))
           (b (arcdocdb.recovery.decisions::%make-decision-entry
                (logxor #x8000000000000000 (ash 1 bit)) 0 2
                (radix-test-id-oracle (radix-test-id-fixture 2 :uniform)) 32)))
      (radix-test-assert-entry-sorts (vector a b))
      (radix-test-assert-entry-sorts (vector b a)))))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-TXM-005-radix-entry-shape-before-sort
  (dolist (sorter (list #'arcdocdb.recovery.decisions::radix-sort-entries
                        #'arcdocdb.recovery.decisions::sort-entries))
    (signals arcdocdb.conditions:invariant-violation
             (funcall sorter (vector (arcdocdb.recovery.decisions::%make-decision-entry
                                     0 0 1 (radix-test-id-fixture 1 :uniform) 0)))
             :decision-entry-count)
    (signals arcdocdb.conditions:invariant-violation
             (funcall sorter (vector (arcdocdb.recovery.decisions::%make-decision-entry
                                     0 0 2 (radix-test-id-fixture 1 :uniform) 0)))
             :decision-entry-size)))

(defun radix-test-query-probes (specs)
  \"Ogni probe dichiara TXID, ID16 e risposta, senza consultare la tabella del prodotto.\"
  (append
   (loop for (txid csn ids) in (decision-oracle specs) append
     (list (list txid (first ids) t csn (length ids) t)
           (list txid (participant-id 0 #x7f) t csn (length ids) nil)))
   (list (list 1 (participant-id 0) nil 0 0 nil)
         (list 49 (participant-id 0) nil 0 0 nil)
         (list 51 (participant-id 0) nil 0 0 nil))))

(defun radix-test-query-expected (probes rounds)
  \"Output piatto dichiarativo; ciascun worker possiede un vettore della stessa misura.\"
  (let ((out (make-array (* rounds (length probes) 5)
                         :element-type '(unsigned-byte 64))) (position 0))
    (dotimes (round rounds)
      (dolist (probe probes)
        (destructuring-bind (txid id found csn count member) probe
          (declare (ignore id))
          (dolist (value (list txid (if found 1 0) csn count (if member 1 0)))
            (setf (aref out position) value) (incf position)))))
    out))

(defun radix-test-query-worker (table probes rounds out ready release)
  \"Query scalari su tabella condivisa; buffer ID e output sono esclusivi del worker.\"
  (handler-case
      (let ((id-buffer (make-array 22 :element-type '(unsigned-byte 8) :initial-element #xcc))
            (position 0))
        (sb-thread:signal-semaphore ready)
        (unless (sb-thread:wait-on-semaphore release :timeout 10)
          (error \"Worker delle query non rilasciato dalla fixture.\"))
        (dotimes (round rounds)
          (dolist (probe probes)
            (let ((txid (first probe)) (id (second probe)))
              (replace id-buffer id :start1 3)
              (multiple-value-bind (found csn count)
                  (arcdocdb.recovery.decisions:trova-decisione table txid)
                (setf (aref out position) txid
                      (aref out (+ position 1)) (if found 1 0)
                      (aref out (+ position 2)) csn
                      (aref out (+ position 3)) count
                      (aref out (+ position 4))
                      (if (arcdocdb.recovery.decisions:partecipante-decisione-p
                            table txid id-buffer 3 19) 1 0)))
              (incf position 5))))
        t)
    (error (condition) condition)))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-TXM-005-concurrent-immutable-table-queries
  (let* ((specs (append (loop for i below 17 collect
                         (decision-spec (+ 50 (* 2 i)) (if (oddp i) 0 #xffffffffffffffff)
                           (loop for j below (nth (mod i 3) '(3 5 17)) collect
                             (participant-id (+ (* i 32) j) (if (oddp j) #x80 0)))))
                        (list (decision-spec 0 0 (list (participant-id 1) (participant-id 2)))
                              (decision-spec #xffffffffffffffff 17
                                             (list (participant-id 3 #xff)
                                                   (participant-id 4 #xff))))))
         (probes (radix-test-query-probes specs)) (rounds 64) (workers 6)
         (expected (radix-test-query-expected probes rounds))
         (outputs (make-array workers :element-type t))
         (ready (sb-thread:make-semaphore)) (release (sb-thread:make-semaphore))
         (threads nil) (joined nil))
    (multiple-value-bind (buffer start end)
        (decision-log-fixture (list (permute-decisions specs 193)))
      (let ((table (decision-fixture-read buffer start end)))
        (assert-decision-table table specs '(1 49 51))
        ;; I lettori devono dipendere soltanto dalle copie possedute dalla tabella.
        (fill buffer #xdd)
        (let ((before (copy-seq buffer)))
          (dotimes (i workers)
            (setf (aref outputs i)
                  (make-array (length expected) :element-type '(unsigned-byte 64)
                                                :initial-element #xffffffffffffffff)))
          (unwind-protect
               (progn
                 (dotimes (i workers)
                   (let ((out (aref outputs i)))
                     (push (sb-thread:make-thread
                            (lambda () (radix-test-query-worker table probes rounds out ready release)))
                           threads)))
                 (dotimes (i workers) (is (sb-thread:wait-on-semaphore ready :timeout 10))))
            (sb-thread:signal-semaphore release workers)
            (setf joined (mapcar (lambda (thread)
                                  (sb-thread:join-thread thread :timeout 10 :default :join-failed))
                                threads)))
          (is (= workers (length threads)))
          (is (every (lambda (result) (eq result t)) joined))
          (is (every (lambda (thread) (not (sb-thread:thread-alive-p thread))) threads))
          (dotimes (i workers)
            (is (equalp expected (aref outputs i)))
            (dotimes (j i) (is (not (eq (aref outputs i) (aref outputs j))))))
          (assert-decision-table table specs '(1 49 51))
          (is (equalp buffer before)))))))

(defun radix-test-histogram (&optional (value 0))
  \"Stato privato iniettato dalla fixture: 256 conteggi/cursori u64 dichiarati.\"
  (make-array 256 :element-type '(unsigned-byte 64) :initial-element value))

(defun radix-test-internal-call (name &rest arguments)
  \"Invoca il confine interno con dati corrotti senza piegare i tipi statici del test.\"
  (apply (fdefinition name) arguments))

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-prefix-invalid-total
  ;; Tre elementi in una classe non possono appartenere a un input di due.
  ;; Due elementi dichiarati non consumano invece un input di tre.
  (dolist (case '((3 0 2 :decision-radix-count) (2 1 2 :decision-radix-count)
                 (2 0 3 :decision-radix-consumption)))
    (destructuring-bind (frequency second-frequency count reason) case
      (let ((histogram (radix-test-histogram)))
        (setf (aref histogram 0) frequency (aref histogram 129) second-frequency)
        (let ((before (copy-seq histogram)))
          (signals arcdocdb.conditions:invariant-violation
                   (radix-test-internal-call
                    'arcdocdb.recovery.decisions::radix-prefix-starts histogram count)
                   reason)
          (is (equalp before histogram)))))))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-entry-invalid-object-before-slot-access
  (dolist (object (list nil 42 (bytes 0)))
    (signals arcdocdb.conditions:invariant-violation
             (arcdocdb.recovery.decisions::radix-sort-entries (vector object))
             :decision-entry-shape)))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-invalid-digit-before-access
  (let ((ids (radix-test-id-fixture 2 :uniform))
        (entries (radix-test-entry-fixture 2 :cluster)))
    (dolist (digit (list 16 17 most-positive-fixnum))
      (let ((histogram (radix-test-histogram 7)) (target (copy-seq ids)))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-id-starts
                                          ids 2 digit histogram)
                 :decision-radix-digit)
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-ids
                                          ids target 2 digit histogram)
                 :decision-radix-digit)
        (is (equalp ids target))
        (is (every (lambda (value) (= value 7)) histogram))))
    (dolist (digit (list 8 9 most-positive-fixnum))
      (let ((histogram (radix-test-histogram 7)) (target (copy-seq entries)))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-entry-starts
                                          entries digit histogram)
                 :decision-radix-digit)
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-entries
                                          entries target digit histogram)
                 :decision-radix-digit)
        (is (equalp entries target))
        (is (every (lambda (value) (= value 7)) histogram))))))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-scatter-invalid-arrays
  (let* ((ids (radix-test-id-fixture 2 :uniform)) (before (copy-seq ids))
         (entries (radix-test-entry-fixture 2 :cluster)) (entries-before (copy-seq entries)))
    (dolist (target (list ids
                         (make-array 15 :element-type '(unsigned-byte 8) :initial-element 0)
                         (make-array 31 :element-type '(unsigned-byte 8) :initial-element 0)
                         (make-array 33 :element-type '(unsigned-byte 8) :initial-element 0)))
      (let ((histogram (radix-test-histogram 7)) (target-before (copy-seq target)))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-ids
                                          ids target 2 0 histogram)
                 :decision-radix-arrays)
        (is (equalp target-before target))
        (is (equalp before ids))
        (is (every (lambda (value) (= value 7)) histogram))))
    (let ((histogram (radix-test-histogram 7)))
      (signals arcdocdb.conditions:invariant-violation
               (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-ids
                                        ids (copy-seq ids) 1 0 histogram)
               :decision-radix-arrays)
      (signals arcdocdb.conditions:invariant-violation
               (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-id-starts
                                        ids 1 0 histogram)
               :decision-participant-size))
    (dolist (target (list entries (make-array 1) (make-array 3)))
      (let ((histogram (radix-test-histogram 7)) (target-before (copy-seq target)))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-entries
                                          entries target 0 histogram)
                 :decision-radix-arrays)
        (is (equalp target-before target))
        (is (equalp entries-before entries))
        (is (every (lambda (value) (= value 7)) histogram))))))

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-invalid-final-cursors
  (dolist (case '(:decreasing :past-end :incomplete))
    (let ((histogram (radix-test-histogram (if (eq case :incomplete) 1 2))))
      (case case
        (:decreasing (setf (aref histogram 12) 1))
        (:past-end (setf (aref histogram 37) 3)))
      (let ((before (copy-seq histogram)))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-check-cursors
                                          histogram 2)
                 (if (eq case :incomplete) :decision-radix-consumption
                     :decision-radix-position))
        (is (equalp before histogram))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-scatter-invalid-cursors
  ;; Le due chiavi distinte partono erroneamente dalla stessa posizione: nessun
  ;; accesso eccede N, ma il cursore finale denuncia la perdita di un elemento.
  (let ((ids (radix-test-id-fixture 2 :uniform))
        (entries (radix-test-entry-fixture 2 :cluster)))
    (dolist (case '(:past-end :incomplete))
      (let ((histogram (radix-test-histogram (if (eq case :past-end) 2 1)))
            (target (copy-seq ids)) (before (copy-seq ids)))
        (when (eq case :incomplete)
          (setf (aref histogram 0) 0 (aref histogram 1) 0))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-ids
                                          ids target 2 15 histogram)
                 (if (eq case :past-end) :decision-radix-position :decision-radix-consumption))
        (is (equalp before ids))
        (when (eq case :past-end) (is (equalp before target))))
      (let ((histogram (radix-test-histogram (if (eq case :past-end) 2 1)))
            (target (copy-seq entries)) (before (copy-seq entries)))
        (when (eq case :incomplete)
          (setf (aref histogram 0) 0 (aref histogram 255) 0))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-entries
                                          entries target 0 histogram)
                 (if (eq case :past-end) :decision-radix-position :decision-radix-consumption))
        (is (equalp before entries))
        (when (eq case :past-end) (is (equalp before target))))))))

(defun radix-test-unpacked-ids (packed)
  \"Copie ID16 dichiarate dalla fixture; nessun decoder o comparatore del prodotto.\"
  (loop for start from 0 below (length packed) by 16
        collect (subseq packed start (+ start 16))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-TXM-005-public-participant-sort-threshold-boundaries
  (let ((threshold arcdocdb.recovery.decisions::+radix-participant-threshold+))
    (is (<= 2 threshold 65534))
    (dolist (count (list (1- threshold) threshold (1+ threshold)))
      (dolist (pattern '(:uniform :random :cluster))
        (let* ((ids (radix-test-unpacked-ids (radix-test-id-fixture count pattern)))
               (specs (list (decision-spec 0 #xffffffffffffffff ids)
                            (decision-spec 0 #xffffffffffffffff (reverse ids)))))
          (dolist (version '(1 2))
            (multiple-value-bind (buffer start end)
                (decision-log-fixture (list specs) :version version :file-offset 4294967296)
              (let ((before (copy-seq buffer)))
                (multiple-value-bind (table prefix status)
                    (decision-fixture-read buffer start end :version version
                                           :file-offset 4294967296)
                  (is (= end prefix)) (is (eq :complete status))
                  (assert-decision-table table specs '(1 1024 1025))
                  (is (not (arcdocdb.recovery.decisions:partecipante-decisione-p
                            table 0 (participant-id 65535 #x7f) 0 16)))
                  (is (equalp before buffer)))))))))))

(defun radix-test-public-entry-specs (count)
  \"TXID unici dichiarati, estremi u64, CSN condivisi e ID con bit alto.\"
  (loop for i below count collect
    (decision-spec (case i (0 0) (1 #xffffffffffffffff) (otherwise (+ (ash 1 32) (* i 257))))
                   (mod i 5)
                   (loop for j below (nth (mod i 3) '(2 3 5)) collect
                     (participant-id (+ (* i 32) j) (if (oddp j) #x80 0))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-TXM-005-public-entry-sort-threshold-boundaries
  (let ((threshold arcdocdb.recovery.decisions::+radix-entry-threshold+))
    (is (<= 3 threshold 65535))
    (dolist (count (list (1- threshold) threshold (1+ threshold)))
      (let ((specs (radix-test-public-entry-specs count)))
        (dolist (physical-order (list (reverse specs) (permute-decisions specs 913)))
          (dolist (version '(1 2))
            (multiple-value-bind (buffer start end)
                (decision-log-fixture (list physical-order) :version version
                                                           :file-offset 4294967296)
              (let ((before (copy-seq buffer)))
                (multiple-value-bind (table prefix status)
                    (decision-fixture-read buffer start end :version version
                                           :file-offset 4294967296)
                  (is (= end prefix)) (is (eq :complete status))
                  (assert-decision-table table specs '(1 1024 1025))
                  (is (equalp before buffer)))))))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-017
(deftest test-REQ-TXM-005-public-radix-first-physical-conflict-across-groups
  (let* ((threshold arcdocdb.recovery.decisions::+radix-entry-threshold+)
         (a (list (participant-id 0) (participant-id 1)))
         (b (list (participant-id 0) (participant-id 2)))
         (first (list (decision-spec #xffffffffffffffff 0 a) (decision-spec 0 0 a)))
         (filler (loop for i below (- threshold 2) collect (decision-spec (+ 17 i) 0 a)))
         (conflicts (list (decision-spec #xffffffffffffffff 0 b) (decision-spec 0 1 a))))
    (is (>= threshold 3))
    ;; Il gruppo TXID zero è visitato per primo nell'ordine numerico, ma il suo
    ;; record discordante è fisicamente successivo a quello del TXID massimo.
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end layouts)
          (decision-log-fixture (list first filler conflicts) :version version
                                                              :file-offset 4294967296)
        (let ((before (copy-seq buffer))
              (expected (+ 4294967296 (first (getf (third layouts) :records)))))
          (dotimes (attempt 2)
            (let ((condition (signals corruption-detected
                               (decision-fixture-read buffer start end :version version
                                                      :file-offset 4294967296)
                               :decision-conflict)))
              (is (= expected (error-offset condition)))
              (is (equalp before buffer))))))))))
")
  (:SOURCE-PATH
   "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-test-corrected-kbi2xy7r/baseline/test.log"
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
  (:SOURCE-PATH
   "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-test-corrected-kbi2xy7r/probe.log"
   :GIT-BLOB "c466f2034906ec25844eb6b68196ae174b72a146" :TEXT
   "radix-probe-result :SURVIVED exit 0 log /var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-test-corrected-kbi2xy7r/baseline/test.log
")
  (:SOURCE-PATH
   "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-radix-test-corrected-kbi2xy7r/baseline/tests/recovery/decisions-radix.lisp"
   :GIT-BLOB "232312cdd4ed6b1efcedc33ddda0fd8d1d8545d7" :TEXT
   ";;;; Oracoli indipendenti per gli ordinamenti DECISION e lettori concorrenti.
(in-package #:arcdocdb.recovery.tests)

(defun radix-test-packed-ids (ids)
  \"Concatena gli ID16 dichiarati dalla fixture, senza primitive del prodotto.\"
  (let ((packed (make-array (* 16 (length ids)) :element-type '(unsigned-byte 8))))
    (loop for id in ids for position from 0
          do (replace packed id :start1 (* 16 position)))
    packed))

(defun radix-test-id-number (packed start)
  \"Interpreta un ID16 come intero big-endian, indipendentemente dal comparatore.\"
  (reduce (lambda (number byte) (+ (* number 256) byte)) packed
          :start start :end (+ start 16) :initial-value 0))

(defun radix-test-id-oracle (packed)
  \"Ordina interi con CL:STABLE-SORT e ricostruisce tutti i 128 bit degli ID.\"
  (let* ((count (/ (length packed) 16))
         (numbers (make-array count :element-type t))
         (result (make-array (length packed) :element-type '(unsigned-byte 8))))
    (dotimes (i count) (setf (aref numbers i) (radix-test-id-number packed (* i 16))))
    (setf numbers (stable-sort numbers #'<))
    (dotimes (i count)
      (dotimes (byte 16)
        (setf (aref result (+ (* i 16) byte))
              (ldb (byte 8 (* 8 (- 15 byte))) (aref numbers i)))))
    result))

(defun radix-test-id-fixture (count pattern)
  \"ID unici, cardinalità nota e seme locale; ultimi due byte dichiarano l'identità.\"
  (let ((packed (make-array (* count 16) :element-type '(unsigned-byte 8)))
        (state 193))
    (dotimes (position count)
      (let ((number (- count position 1)) (start (* position 16)))
        (dotimes (byte 14)
          (setf state (logand #xffffffff (+ (* state 1664525) 1013904223)))
          (setf (aref packed (+ start byte))
                (case pattern
                  (:uniform #xa5)
                  (:random (ldb (byte 8 24) state))
                  (:cluster #x80)
                  (otherwise (error \"Pattern della fixture sconosciuto: ~S\" pattern)))))
        (when (eq pattern :cluster)
          (setf (aref packed start) (mod (floor number 17) 3)
                (aref packed (+ start 7)) (if (oddp number) #xff 0)))
        (setf (aref packed (+ start 14)) (ldb (byte 8 8) number)
              (aref packed (+ start 15)) (ldb (byte 8 0) number))))
    packed))

(defun radix-test-assert-id-sorts (packed source-offset)
  \"Confronta radix e merge con un oracolo numerico, su copie private distinte.\"
  (let ((expected (radix-test-id-oracle packed)) (before (copy-seq packed))
        (count (/ (length packed) 16)))
    (dolist (sorter (list #'arcdocdb.recovery.decisions::radix-sort-participants
                          #'arcdocdb.recovery.decisions::sort-participants))
      (let ((result (funcall sorter (copy-seq packed) count source-offset)))
        (is (typep result '(simple-array (unsigned-byte 8) (*))))
        (is (equalp expected result))))
    (is (equalp packed before))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-TXM-005-radix-participant-cardinalities-and-patterns
  (dolist (count '(0 1 2 3 5 17 256 257 65535))
    (dolist (pattern '(:uniform :random :cluster))
      (radix-test-assert-id-sorts (radix-test-id-fixture count pattern)
                                #xffffffffffffffff))))

;;; REQ: REQ-TXM-001 REQ-TXM-005 REQ-FOR-003
(deftest test-REQ-TXM-001-radix-participant-every-byte-and-bit
  (let ((base (make-array 16 :element-type '(unsigned-byte 8) :initial-element #x80)))
    (dotimes (byte 16)
      (dotimes (bit 8)
        (let ((changed (copy-seq base)))
          (setf (aref changed byte) (logxor #x80 (ash 1 bit)))
          (radix-test-assert-id-sorts (radix-test-packed-ids (list base changed)) 17)
          (radix-test-assert-id-sorts (radix-test-packed-ids (list changed base)) 17))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-017
(deftest test-REQ-TXM-005-radix-duplicate-participant-offset
  (dolist (offset '(0 4294967296 18446744073709551615))
    (dolist (count '(2 3 5 17 257))
      (let ((packed (radix-test-id-fixture count :random)))
        (replace packed packed :start1 (* 16 (1- count)) :end1 (* 16 count)
                                :start2 0 :end2 16)
        (dolist (sorter (list #'arcdocdb.recovery.decisions::radix-sort-participants
                              #'arcdocdb.recovery.decisions::sort-participants))
          (let ((condition (signals corruption-detected
                                   (funcall sorter (copy-seq packed) count offset)
                                   :decision-duplicate-participant)))
            (is (= offset (error-offset condition)))))))))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-TXM-005-radix-participant-shape-before-sort
  (dolist (size '(0 15 17 32))
    (let ((packed (make-array size :element-type '(unsigned-byte 8) :initial-element 0)))
      (dolist (sorter (list #'arcdocdb.recovery.decisions::radix-sort-participants
                            #'arcdocdb.recovery.decisions::sort-participants))
        (signals arcdocdb.conditions:invariant-violation
                 (funcall sorter packed 1 0) :decision-participant-size)))))

(defun radix-test-entry-fixture (count pattern)
  \"Entry dichiarate con offset crescenti; TXID uguali conservano l'ordine fisico.\"
  (let ((entries (make-array count :element-type t)) (state 913)
        (participants (radix-test-packed-ids (list (participant-id 0) (participant-id 1))))
        (extremes (vector 0 #xffffffffffffffff #x8000000000000000
                          #x7fffffffffffffff #x100000000 #xff #x100 1)))
    (dotimes (i count)
      (setf state (logand #xffffffffffffffff
                         (+ (* state 6364136223846793005) 1442695040888963407)))
      (let ((txid (case pattern
                    (:uniform #xffffffffffffffff)
                    (:random state)
                    (:cluster (aref extremes (mod i (length extremes))))
                    (:dominant (if (= i (1- count)) 0 #xffffffffffffffff))
                    (otherwise (error \"Pattern delle entry sconosciuto: ~S\" pattern)))))
        (setf (aref entries i)
              (arcdocdb.recovery.decisions::%make-decision-entry
                txid (- #xffffffffffffffff i) 2 participants (+ (ash 1 63) (* i 64))))))
    entries))

(defun radix-test-entry-oracle (entries)
  \"CL:STABLE-SORT sul solo TXID; l'identità delle entry prova anche la stabilità.\"
  (stable-sort (copy-seq entries) #'< :key #'arcdocdb.recovery.decisions::%entry-txid))

(defun radix-test-assert-entry-sorts (entries)
  \"Oracolo indipendente dal merge e dal radix; nessuna ricostruzione dei loro passaggi.\"
  (let ((expected (radix-test-entry-oracle entries)) (before (copy-seq entries)))
    (dolist (sorter (list #'arcdocdb.recovery.decisions::radix-sort-entries
                          #'arcdocdb.recovery.decisions::sort-entries))
      (let ((result (funcall sorter (copy-seq entries))))
        (is (= (length expected) (length result)))
        (dotimes (i (length expected))
          (is (eq (aref expected i) (aref result i)))
          (when (and (plusp i)
                     (= (arcdocdb.recovery.decisions::%entry-txid (aref result (1- i)))
                        (arcdocdb.recovery.decisions::%entry-txid (aref result i))))
            (is (< (arcdocdb.recovery.decisions::%entry-source-offset (aref result (1- i)))
                   (arcdocdb.recovery.decisions::%entry-source-offset (aref result i))))))))
    (is (equalp entries before))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008
(deftest test-REQ-TXM-005-radix-entry-cardinalities-patterns-and-stability
  (dolist (count '(0 1 2 3 5 17 256 257 65535))
    (dolist (pattern '(:uniform :random :cluster))
      (radix-test-assert-entry-sorts (radix-test-entry-fixture count pattern)))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008
(deftest test-REQ-AFF-008-radix-entry-65536-bucket-counts
  ;; Il numero di DECISION fisiche non è limitato al count u16 dei partecipanti.
  ;; Una classe con 65.536 entry e una classe dominante con un outlier
  ;; rendono osservabili sia il conteggio sia il cursore finale oltre u16.
  (dolist (pattern '(:uniform :dominant))
    (radix-test-assert-entry-sorts (radix-test-entry-fixture 65536 pattern))))

;;; REQ: REQ-TXM-001 REQ-TXM-005
(deftest test-REQ-TXM-001-radix-entry-every-txid-bit
  (dotimes (bit 64)
    (let* ((a (arcdocdb.recovery.decisions::%make-decision-entry
                #x8000000000000000 0 2
                (radix-test-id-oracle (radix-test-id-fixture 2 :uniform)) 31))
           (b (arcdocdb.recovery.decisions::%make-decision-entry
                (logxor #x8000000000000000 (ash 1 bit)) 0 2
                (radix-test-id-oracle (radix-test-id-fixture 2 :uniform)) 32)))
      (radix-test-assert-entry-sorts (vector a b))
      (radix-test-assert-entry-sorts (vector b a)))))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-TXM-005-radix-entry-shape-before-sort
  (dolist (sorter (list #'arcdocdb.recovery.decisions::radix-sort-entries
                        #'arcdocdb.recovery.decisions::sort-entries))
    (signals arcdocdb.conditions:invariant-violation
             (funcall sorter (vector (arcdocdb.recovery.decisions::%make-decision-entry
                                     0 0 1 (radix-test-id-fixture 1 :uniform) 0)))
             :decision-entry-count)
    (signals arcdocdb.conditions:invariant-violation
             (funcall sorter (vector (arcdocdb.recovery.decisions::%make-decision-entry
                                     0 0 2 (radix-test-id-fixture 1 :uniform) 0)))
             :decision-entry-size)))

(defun radix-test-query-probes (specs)
  \"Ogni probe dichiara TXID, ID16 e risposta, senza consultare la tabella del prodotto.\"
  (append
   (loop for (txid csn ids) in (decision-oracle specs) append
     (list (list txid (first ids) t csn (length ids) t)
           (list txid (participant-id 0 #x7f) t csn (length ids) nil)))
   (list (list 1 (participant-id 0) nil 0 0 nil)
         (list 49 (participant-id 0) nil 0 0 nil)
         (list 51 (participant-id 0) nil 0 0 nil))))

(defun radix-test-query-expected (probes rounds)
  \"Output piatto dichiarativo; ciascun worker possiede un vettore della stessa misura.\"
  (let ((out (make-array (* rounds (length probes) 5)
                         :element-type '(unsigned-byte 64))) (position 0))
    (dotimes (round rounds)
      (dolist (probe probes)
        (destructuring-bind (txid id found csn count member) probe
          (declare (ignore id))
          (dolist (value (list txid (if found 1 0) csn count (if member 1 0)))
            (setf (aref out position) value) (incf position)))))
    out))

(defun radix-test-query-worker (table probes rounds out ready release)
  \"Query scalari su tabella condivisa; buffer ID e output sono esclusivi del worker.\"
  (handler-case
      (let ((id-buffer (make-array 22 :element-type '(unsigned-byte 8) :initial-element #xcc))
            (position 0))
        (sb-thread:signal-semaphore ready)
        (unless (sb-thread:wait-on-semaphore release :timeout 10)
          (error \"Worker delle query non rilasciato dalla fixture.\"))
        (dotimes (round rounds)
          (dolist (probe probes)
            (let ((txid (first probe)) (id (second probe)))
              (replace id-buffer id :start1 3)
              (multiple-value-bind (found csn count)
                  (arcdocdb.recovery.decisions:trova-decisione table txid)
                (setf (aref out position) txid
                      (aref out (+ position 1)) (if found 1 0)
                      (aref out (+ position 2)) csn
                      (aref out (+ position 3)) count
                      (aref out (+ position 4))
                      (if (arcdocdb.recovery.decisions:partecipante-decisione-p
                            table txid id-buffer 3 19) 1 0)))
              (incf position 5))))
        t)
    (error (condition) condition)))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-TXM-005-concurrent-immutable-table-queries
  (let* ((specs (append (loop for i below 17 collect
                         (decision-spec (+ 50 (* 2 i)) (if (oddp i) 0 #xffffffffffffffff)
                           (loop for j below (nth (mod i 3) '(3 5 17)) collect
                             (participant-id (+ (* i 32) j) (if (oddp j) #x80 0)))))
                        (list (decision-spec 0 0 (list (participant-id 1) (participant-id 2)))
                              (decision-spec #xffffffffffffffff 17
                                             (list (participant-id 3 #xff)
                                                   (participant-id 4 #xff))))))
         (probes (radix-test-query-probes specs)) (rounds 64) (workers 6)
         (expected (radix-test-query-expected probes rounds))
         (outputs (make-array workers :element-type t))
         (ready (sb-thread:make-semaphore)) (release (sb-thread:make-semaphore))
         (threads nil) (joined nil))
    (multiple-value-bind (buffer start end)
        (decision-log-fixture (list (permute-decisions specs 193)))
      (let ((table (decision-fixture-read buffer start end)))
        (assert-decision-table table specs '(1 49 51))
        ;; I lettori devono dipendere soltanto dalle copie possedute dalla tabella.
        (fill buffer #xdd)
        (let ((before (copy-seq buffer)))
          (dotimes (i workers)
            (setf (aref outputs i)
                  (make-array (length expected) :element-type '(unsigned-byte 64)
                                                :initial-element #xffffffffffffffff)))
          (unwind-protect
               (progn
                 (dotimes (i workers)
                   (let ((out (aref outputs i)))
                     (push (sb-thread:make-thread
                            (lambda () (radix-test-query-worker table probes rounds out ready release)))
                           threads)))
                 (dotimes (i workers) (is (sb-thread:wait-on-semaphore ready :timeout 10))))
            (sb-thread:signal-semaphore release workers)
            (setf joined (mapcar (lambda (thread)
                                  (sb-thread:join-thread thread :timeout 10 :default :join-failed))
                                threads)))
          (is (= workers (length threads)))
          (is (every (lambda (result) (eq result t)) joined))
          (is (every (lambda (thread) (not (sb-thread:thread-alive-p thread))) threads))
          (dotimes (i workers)
            (is (equalp expected (aref outputs i)))
            (dotimes (j i) (is (not (eq (aref outputs i) (aref outputs j))))))
          (assert-decision-table table specs '(1 49 51))
          (is (equalp buffer before)))))))

(defun radix-test-histogram (&optional (value 0))
  \"Stato privato iniettato dalla fixture: 256 conteggi/cursori u64 dichiarati.\"
  (make-array 256 :element-type '(unsigned-byte 64) :initial-element value))

(defun radix-test-internal-call (name &rest arguments)
  \"Invoca il confine interno con dati corrotti senza piegare i tipi statici del test.\"
  (apply (fdefinition name) arguments))

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-prefix-invalid-total
  ;; Tre elementi in una classe non possono appartenere a un input di due.
  ;; Due elementi dichiarati non consumano invece un input di tre.
  (dolist (case '((3 0 2 :decision-radix-count) (2 1 2 :decision-radix-count)
                 (2 0 3 :decision-radix-consumption)))
    (destructuring-bind (frequency second-frequency count reason) case
      (let ((histogram (radix-test-histogram)))
        (setf (aref histogram 0) frequency (aref histogram 129) second-frequency)
        (let ((before (copy-seq histogram)))
          (signals arcdocdb.conditions:invariant-violation
                   (radix-test-internal-call
                    'arcdocdb.recovery.decisions::radix-prefix-starts histogram count)
                   reason)
          (is (equalp before histogram)))))))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-entry-invalid-object-before-slot-access
  (dolist (object (list nil 42 (bytes 0)))
    (signals arcdocdb.conditions:invariant-violation
             (arcdocdb.recovery.decisions::radix-sort-entries (vector object))
             :decision-entry-shape)))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-invalid-digit-before-access
  (let ((ids (radix-test-id-fixture 2 :uniform))
        (entries (radix-test-entry-fixture 2 :cluster)))
    (dolist (digit (list 16 17 most-positive-fixnum))
      (let ((histogram (radix-test-histogram 7)) (target (copy-seq ids)))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-id-starts
                                          ids 2 digit histogram)
                 :decision-radix-digit)
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-ids
                                          ids target 2 digit histogram)
                 :decision-radix-digit)
        (is (equalp ids target))
        (is (every (lambda (value) (= value 7)) histogram))))
    (dolist (digit (list 8 9 most-positive-fixnum))
      (let ((histogram (radix-test-histogram 7)) (target (copy-seq entries)))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-entry-starts
                                          entries digit histogram)
                 :decision-radix-digit)
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-entries
                                          entries target digit histogram)
                 :decision-radix-digit)
        (is (equalp entries target))
        (is (every (lambda (value) (= value 7)) histogram))))))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-scatter-invalid-arrays
  (let* ((ids (radix-test-id-fixture 2 :uniform)) (before (copy-seq ids))
         (entries (radix-test-entry-fixture 2 :cluster)) (entries-before (copy-seq entries)))
    (dolist (target (list ids
                         (make-array 15 :element-type '(unsigned-byte 8) :initial-element 0)
                         (make-array 31 :element-type '(unsigned-byte 8) :initial-element 0)
                         (make-array 33 :element-type '(unsigned-byte 8) :initial-element 0)))
      (let ((histogram (radix-test-histogram 7)) (target-before (copy-seq target)))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-ids
                                          ids target 2 0 histogram)
                 :decision-radix-arrays)
        (is (equalp target-before target))
        (is (equalp before ids))
        (is (every (lambda (value) (= value 7)) histogram))))
    (let ((histogram (radix-test-histogram 7)))
      (signals arcdocdb.conditions:invariant-violation
               (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-ids
                                        ids (copy-seq ids) 1 0 histogram)
               :decision-radix-arrays)
      (signals arcdocdb.conditions:invariant-violation
               (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-id-starts
                                        ids 1 0 histogram)
               :decision-participant-size))
    (dolist (target (list entries (make-array 1) (make-array 3)))
      (let ((histogram (radix-test-histogram 7)) (target-before (copy-seq target)))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-entries
                                          entries target 0 histogram)
                 :decision-radix-arrays)
        (is (equalp target-before target))
        (is (equalp entries-before entries))
        (is (every (lambda (value) (= value 7)) histogram))))))

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-invalid-final-cursors
  (dolist (case '(:decreasing :past-end :incomplete))
    (let ((histogram (radix-test-histogram (if (eq case :incomplete) 1 2))))
      (case case
        (:decreasing (setf (aref histogram 12) 1))
        (:past-end (setf (aref histogram 37) 3)))
      (let ((before (copy-seq histogram)))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-check-cursors
                                          histogram 2)
                 (if (eq case :incomplete) :decision-radix-consumption
                     :decision-radix-position))
        (is (equalp before histogram))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(deftest test-REQ-AFF-008-radix-scatter-invalid-cursors
  ;; Le due chiavi distinte partono erroneamente dalla stessa posizione: nessun
  ;; accesso eccede N, ma il cursore finale denuncia la perdita di un elemento.
  (let ((ids (radix-test-id-fixture 2 :uniform))
        (entries (radix-test-entry-fixture 2 :cluster)))
    (dolist (case '(:past-end :incomplete))
      (let ((histogram (radix-test-histogram (if (eq case :past-end) 2 1)))
            (target (copy-seq ids)) (before (copy-seq ids)))
        (when (eq case :incomplete)
          (setf (aref histogram 0) 0 (aref histogram 1) 0))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-ids
                                          ids target 2 15 histogram)
                 (if (eq case :past-end) :decision-radix-position :decision-radix-consumption))
        (is (equalp before ids))
        (when (eq case :past-end) (is (equalp before target))))
      (let ((histogram (radix-test-histogram (if (eq case :past-end) 2 1)))
            (target (copy-seq entries)) (before (copy-seq entries)))
        (when (eq case :incomplete)
          (setf (aref histogram 0) 0 (aref histogram 255) 0))
        (signals arcdocdb.conditions:invariant-violation
                 (radix-test-internal-call 'arcdocdb.recovery.decisions::radix-scatter-entries
                                          entries target 0 histogram)
                 (if (eq case :past-end) :decision-radix-position :decision-radix-consumption))
        (is (equalp before entries))
        (when (eq case :past-end) (is (equalp before target)))))))

(defun radix-test-unpacked-ids (packed)
  \"Copie ID16 dichiarate dalla fixture; nessun decoder o comparatore del prodotto.\"
  (loop for start from 0 below (length packed) by 16
        collect (subseq packed start (+ start 16))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-TXM-005-public-participant-sort-threshold-boundaries
  (let ((threshold arcdocdb.recovery.decisions::+radix-participant-threshold+))
    (is (<= 2 threshold 65534))
    (dolist (count (list (1- threshold) threshold (1+ threshold)))
      (dolist (pattern '(:uniform :random :cluster))
        (let* ((ids (radix-test-unpacked-ids (radix-test-id-fixture count pattern)))
               (specs (list (decision-spec 0 #xffffffffffffffff ids)
                            (decision-spec 0 #xffffffffffffffff (reverse ids)))))
          (dolist (version '(1 2))
            (multiple-value-bind (buffer start end)
                (decision-log-fixture (list specs) :version version :file-offset 4294967296)
              (let ((before (copy-seq buffer)))
                (multiple-value-bind (table prefix status)
                    (decision-fixture-read buffer start end :version version
                                           :file-offset 4294967296 :max-participants (* 2 count))
                  (is (= end prefix)) (is (eq :complete status))
                  (assert-decision-table table specs '(1 1024 1025))
                  (is (not (arcdocdb.recovery.decisions:partecipante-decisione-p
                            table 0 (participant-id 65535 #x7f) 0 16)))
                  (is (equalp before buffer)))))))))))

(defun radix-test-public-entry-specs (count)
  \"TXID unici dichiarati, estremi u64, CSN condivisi e ID con bit alto.\"
  (loop for i below count collect
    (decision-spec (case i (0 0) (1 #xffffffffffffffff) (otherwise (+ (ash 1 32) (* i 257))))
                   (mod i 5)
                   (loop for j below (nth (mod i 3) '(2 3 5)) collect
                     (participant-id (+ (* i 32) j) (if (oddp j) #x80 0))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-TXM-005-public-entry-sort-threshold-boundaries
  (let ((threshold arcdocdb.recovery.decisions::+radix-entry-threshold+))
    (is (<= 3 threshold 65535))
    (dolist (count (list (1- threshold) threshold (1+ threshold)))
      (let ((specs (radix-test-public-entry-specs count))
            (ids (list (participant-id 0 #x80) (participant-id 1 #x80))))
        ;; La soglia riguarda i record fisici anche quando COLLAPSE produrrà un solo TXID.
        (dolist (physical-order
                 (list (reverse specs) (permute-decisions specs 913)
                       (loop for i below count collect
                         (decision-spec #xffffffffffffffff 0 (if (oddp i) (reverse ids) ids)))))
          (dolist (version '(1 2))
            (multiple-value-bind (buffer start end)
                (decision-log-fixture (list physical-order) :version version
                                                           :file-offset 4294967296)
              (let ((before (copy-seq buffer)))
                (multiple-value-bind (table prefix status)
                    (decision-fixture-read buffer start end :version version
                                           :file-offset 4294967296 :max-participants (* 5 count))
                  (is (= end prefix)) (is (eq :complete status))
                  (assert-decision-table table physical-order '(1 1024 1025))
                  (is (equalp before buffer)))))))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-017
(deftest test-REQ-TXM-005-public-radix-first-physical-conflict-across-groups
  (let* ((threshold arcdocdb.recovery.decisions::+radix-entry-threshold+)
         (a (list (participant-id 0) (participant-id 1)))
         (b (list (participant-id 0) (participant-id 2)))
         (first (list (decision-spec #xffffffffffffffff 0 a) (decision-spec 0 0 a)))
         (filler (loop for i below (- threshold 2) collect (decision-spec (+ 17 i) 0 a)))
         (conflicts (list (decision-spec #xffffffffffffffff 0 b) (decision-spec 0 1 a))))
    (is (>= threshold 3))
    ;; Il gruppo TXID zero è visitato per primo nell'ordine numerico, ma il suo
    ;; record discordante è fisicamente successivo a quello del TXID massimo.
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end layouts)
          (decision-log-fixture (list first filler conflicts) :version version
                                                              :file-offset 4294967296)
        (let ((before (copy-seq buffer))
              (expected (+ 4294967296 (first (getf (third layouts) :records)))))
          (dotimes (attempt 2)
            (let ((condition (signals corruption-detected
                               (decision-fixture-read buffer start end :version version
                                                      :file-offset 4294967296)
                               :decision-conflict)))
              (is (= expected (error-offset condition)))
              (is (equalp before buffer)))))))))
"))
 :LIMITS
 (:VERBATIM-FILES-AND-GIT-BLOBS :MISSING-PROCESS-METADATA-NOT-RECONSTRUCTED
  :INITIAL-LINT-OF-FILE-COUNTED-ZERO-FILES-NOT-A-VALIDATION
  :FAILED-ATTEMPTS-PRESERVED))
