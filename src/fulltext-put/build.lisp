(in-package #:arcdocdb.fulltext.put)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010 REQ-WAL-005
(declaim (ftype (function (t &key (:version t) (:document-bytes t) (:key-bytes t)
                          (:max-scalars t) (:max-tokens t) (:term-bytes t) (:max-memory t)) preparazione-put-full-text)
                crea-preparazione-put-full-text))
(defun crea-preparazione-put-full-text (configs &key (version 2) (document-bytes 16777216) (key-bytes 65535)
                                               (max-scalars 65536) (max-tokens 4096) (term-bytes 262144)
                                               (max-memory 67108864))
  "Pre: configurazioni canoniche ordinate, capacita fredde finite. Post: frame e task privati.
Budget dell'intero cohort prima delle allocazioni; non conta configurazioni, pool delta o RSS.
Propaga INVALID-ARGUMENT/UNSUPPORTED-FORMAT; RESOURCE-EXHAUSTED oltre memoria."
  (unless (and (typep configs 'simple-vector) (<= 1 (length configs) 16)
               (integerp version) (typep document-bytes '(integer 1 16777216))
               (typep key-bytes '(integer 1 65535)) (typep max-scalars '(integer 1 4294967295))
               (typep max-tokens '(integer 1 4294967295)) (typep term-bytes '(integer 1 4294967295))
               (typep max-memory 'index))
    (error 'invalid-argument :reason :fulltext-put-capacity))
  (r::format-limits version) (f::verifica-configurazioni-riserve configs)
  (let* ((count (length configs)) (frame-bytes (+ r:+header-bytes+ key-bytes document-bytes))
         (per-task (+ (* 20 max-scalars) (* 28 max-tokens) (* 2 term-bytes) (* 12 16) 65536))
         (memory (+ 4096 (* 128 count) frame-bytes (* count per-task))))
    (when (> memory max-memory) (error 'resource-exhausted :reason :fulltext-put-memory))
    (let ((tasks (make-array count)))
      (dotimes (i count)
        (setf (svref tasks i) (d:crea-preparazione-full-text (svref configs i) :max-scalars max-scalars
                                                          :max-tokens max-tokens :token-bytes term-bytes :max-memory max-memory)))
      (%preparazione-put-full-text tasks (make-array frame-bytes :element-type '(unsigned-byte 8) :initial-element 0)
                                   version document-bytes key-bytes))))
