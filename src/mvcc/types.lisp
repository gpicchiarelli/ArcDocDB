;;; OWNER: budget e rappresentazioni degli snapshot; nessun secondo allocatore CSN.
;;; SHARED: il registro dei commit appartiene esclusivamente ad arcdocdb.csn.
(in-package #:arcdocdb.mvcc)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-MVC-004 REQ-MVC-007 REQ-AFF-008
(defconstant +max-csn+ #xffffffffffffffff)
(defconstant +max-csn-slots+ 65536)
(deftype csn-words () '(simple-array (unsigned-byte 64) (*)))
(deftype csn-slot () '(integer 0 65535))
