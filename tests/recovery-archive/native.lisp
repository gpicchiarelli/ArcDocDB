;;;; Catena nativa: Archivio -> ACTIVE -> checkpoint CONTROL -> rename/fsync.
;;; OWNER: fixture ct::rp-run, directory 0700, <=128 FD/64 nomi/4096 byte, deadline 30s.
;;; SHARED: runner seriale, nessuna FI globale o worker; log congelati e FD mantenuti vivi.
;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-TXM-007 REQ-AFF-008 REQ-AFF-018
(in-package #:arcdocdb.recovery.archive.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun dar-native-log (case tail-p)
  "UUID Archivio distinto dalla Serie; decisione locale contraddittoria solo nella coda non sigillata."
  (let* ((version (av::apub-case-version case))
         (participants (list (av::apub-case-identity case) (rt::participant-id 99 128)))
         (specs (list (rt::decision-spec #xffffffffffffffff #xfedcba9876543210 participants)
                      (rt::decision-spec 777 8 participants) (rt::decision-spec 17 0 participants)))
         (tail (when tail-p (rt::reference-decision-record (rt::decision-spec 43 1 participants) version))))
    (values (dar-log (list specs) :version version :tail tail) specs)))

(defun dar-native-read (fixture case input bytes tail-p deadline)
  "EOF misurato dalla fixture, reader pubblico, oracoli indipendenti e contatori syscall esatti."
  (let* ((size (sb-posix:stat-size (sb-posix:fstat (io::file-fd input))))
         (scratch (ct::crr-bytes size #xa5))
         (scope (arcdocdb.get::vista-get-serie-scope (av::apub-case-view case)))
         (archive (da:crea-archivio-recovery scope (dar-identity)))
         (before (ct::rp-observations fixture)) (namespace (av::apub-namespace fixture))
         (snapshots (av::apub-file-bytes fixture deadline)))
    (is (= size (length bytes)))
    (is (not (equalp (dar-identity) (av::apub-case-identity case))))
    (ct::native-reset-calls fixture)
    (let ((result (ct::native-bounded deadline :archive-native-read
                    (lambda () (da:leggi-decisioni-recuperate archive input size scratch
                                 :chunk-bytes 31 :max-bytes size :max-batches (if tail-p 2 1)
                                 :max-batch-records 3 :max-batch-bytes 4096
                                 :max-decisions 3 :max-participants 6 :max-participants-per-decision 2)))))
      (is (equalp bytes scratch))
      (is (equalp (vector 0 (1+ (ceiling (- size 64) 31)) 0 0 0 0 0 0 0)
                  (ct::native-observer-calls (ct::native-fixture-observer fixture))))
      (is (= 3 (da:numero-decisioni-recuperate result)))
      (is (equal '(t 0 2) (multiple-value-list (da:trova-decisione-recuperata result 17))))
      (is (equal '(nil 0 0) (multiple-value-list (da:trova-decisione-recuperata result 43))))
      (multiple-value-bind (eof prefix status version) (da:frontiere-decisioni-recuperate result)
        (is (= eof size)) (is (= version (av::apub-case-version case)))
        (is (eq status (if tail-p :tail :complete)))
        (is (= prefix (if tail-p (- size (length (rt::reference-decision-record
                                                   (rt::decision-spec 43 1
                                                     (list (av::apub-case-identity case)
                                                           (rt::participant-id 99 128))) version))) size))))
      (fill scratch #xa5)
      (is (equal before (ct::rp-observations fixture)))
      (is (equal namespace (av::apub-namespace fixture)))
      (is (equalp snapshots (av::apub-file-bytes fixture deadline)))
      result)))

(defun dar-native-active (fixture case decisions deadline)
  "Nuovo ingresso autorevole, poi la stessa pubblicazione già qualificata del caso ACTIVE."
  (let* ((size (length (av::apub-case-bytes case))) (scratch (ct::crr-bytes size))
         (before (ct::rp-observations fixture)) (namespace (av::apub-namespace fixture))
         (snapshots (av::apub-file-bytes fixture deadline)))
    (ct::native-reset-calls fixture)
    (let ((result (ct::native-bounded deadline :archive-native-active
                    (lambda ()
                      (da:leggi-active-con-decisioni (av::apub-case-control case) (av::apub-case-input case)
                        size decisions scratch :chunk-bytes 29 :max-bytes size :max-batches 3
                        :max-batch-records 5 :max-batch-bytes 4096 :max-records 7
                        :max-prepared 4 :max-outcomes 2)))))
      (is (equalp scratch (av::apub-case-bytes case)))
      (is (equalp (vector 0 (1+ (ceiling (- size 64) 29)) 0 0 0 0 2 0 0)
                  (ct::native-observer-calls (ct::native-fixture-observer fixture))))
      (is (equal '(2 7 4 1 2 1)
                 (multiple-value-list (arcdocdb.recovery.active:statistiche-active-recuperato result))))
      (dolist (entry (av::apub-outcomes))
        (is (equal (list t (second entry))
                   (multiple-value-list (arcdocdb.recovery.active:esito-chiusura-active result (first entry))))))
      (dolist (txid '(43 61 777))
        (is (equal '(nil 0) (multiple-value-list (arcdocdb.recovery.active:esito-chiusura-active result txid)))))
      (fill scratch #xa5)
      (is (equal before (ct::rp-observations fixture)))
      (is (equal namespace (av::apub-namespace fixture)))
      (is (equalp snapshots (av::apub-file-bytes fixture deadline)))
      (setf (av::apub-case-recovered case) result))))

(defun dar-native-chain (version tail-p)
  "Setup tramite temporanei esclusivi; lettura completa autorevole prima di chiudere il vecchio ACTIVE."
  (ct::rp-run
   (lambda (fixture deadline)
     (let ((case (av::apub-setup fixture version deadline :tail-p tail-p)))
       (multiple-value-bind (bytes specs) (dar-native-log case tail-p)
         (is (= 3 (length specs)))
         (multiple-value-bind (input append)
             (av::apub-seed fixture (av::apub-case-path case) (av::apub-case-directory case)
                            "archive-authoritative.log" bytes deadline)
           (is (= (length bytes) (io:posizione-durevole append) (io:posizione-scritta append)))
           (let ((decisions (dar-native-read fixture case input bytes tail-p deadline)))
             (dar-native-active fixture case decisions deadline)
             (av::apub-prepare fixture case deadline)
             (av::apub-success fixture case deadline)
             (is (eq :open (io:stato-file input)))
             (ct::native-read-bytes input bytes deadline))))))))

(deftest test-REQ-REC-001-ARCHIVE-native-v1-v2-complete-through-published-checkpoint
  (dolist (version '(1 2)) (dar-native-chain version nil)))

(deftest test-REQ-TXM-007-ARCHIVE-native-v1-v2-tail-excluded-through-published-checkpoint
  (dolist (version '(1 2)) (dar-native-chain version t)))
