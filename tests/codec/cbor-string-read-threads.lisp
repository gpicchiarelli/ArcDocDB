(in-package #:arcdocdb.cbor.string.read.tests)

;;; REQ: REQ-CBR-009 REQ-CON-005 REQ-LIM-001 REQ-LIM-002
(deftest test-REQ-CBR-009-string-two-reused-workers-share-buffer-with-distinct-raw-and-text-windows
  (multiple-value-bind (buffer start end)
      (csr-fixture '(#x44 0 #xff #x1c #x80 #x63 #xe2 #x82 #xac) '(#xff #x1c #x18 0))
    (let* ((rounds 2048) (before (copy-seq buffer)) (begins #(7 12))
           (expected #((2 8 12) (3 13 16))) (tokens #(41333 41509)) (expected-sinks #(84649984 85010432))
           (ready (vector (sb-thread:make-semaphore) (sb-thread:make-semaphore)))
           (go (vector (sb-thread:make-semaphore) (sb-thread:make-semaphore)))
           (done (vector (sb-thread:make-semaphore) (sb-thread:make-semaphore)))
           (starts (make-array '(2 2) :initial-element 0))
           (firsts (make-array '(2 2) :initial-element 0))
           (finishes (make-array '(2 2) :initial-element 0))
           (sinks (make-array '(2 2) :initial-element 0)) (threads nil))
      (is (= start 7)) (is (= end 20)) (is (= (length buffer) 25))
      (is (= (* 2 2 rounds) 8192))
      (dotimes (index 2)
        (is (= (svref tokens index) (apply #'csr-token buffer (svref expected index))))
        (is (= (svref expected-sinks index) (* rounds (svref tokens index)))))
      (unwind-protect
           (progn
             (dotimes (i 2)
               (let ((index i))
                 (push (sb-thread:make-thread
                        (lambda ()
                          (csr-worker index buffer (svref begins index) end (svref expected index)
                                      (svref tokens index) before rounds ready go done starts firsts finishes sinks))
                        :name "CBOR string raw/text readonly-shared-buffer worker") threads)))
             (dotimes (wave 2)
               ;; READY segue la prima chiamata verificata di entrambi; poi lavoro restante.
               (dotimes (i 2) (cs-wait (svref ready wave)))
               (sb-thread:signal-semaphore (svref go wave) 2)
               (dotimes (i 2) (cs-wait (svref done wave)))
               (let ((overlap (- (min (aref finishes 0 wave) (aref finishes 1 wave))
                                 (max (aref starts 0 wave) (aref starts 1 wave)))))
                 (format t "  CBOR string read: onda ~D, 2 worker riusati, ~D letture; WALL fixture con rendezvous/controlli: worker 0 start/first/end ~D/~D/~D, sink ~D; worker 1 start/first/end ~D/~D/~D, sink ~D; overlap ~D tick (~D tick/s); nessuna inferenza su tempo puro decoder, CPU o scaling.~%"
                         wave (* 2 rounds)
                         (aref starts 0 wave) (aref firsts 0 wave) (aref finishes 0 wave) (aref sinks 0 wave)
                         (aref starts 1 wave) (aref firsts 1 wave) (aref finishes 1 wave) (aref sinks 1 wave)
                         overlap internal-time-units-per-second)
                 (force-output)
                 (dotimes (index 2)
                   (is (= (aref sinks index wave) (svref expected-sinks index)))
                   ;; Il clock può quantizzare un'ondata intera nello stesso tick.
                   (is (>= (aref finishes index wave) (aref starts index wave)))
                   (is (<= (aref starts index wave) (aref firsts index wave) (aref finishes index wave))))
                 (is (<= (max (aref firsts 0 wave) (aref firsts 1 wave))
                         (min (aref finishes 0 wave) (aref finishes 1 wave))))
                 ;; READY dopo la prima lettura attesta entrambi i partecipanti;
                 ;; un overlap di zero tick non misura una durata negativa.
                 (is (not (minusp overlap)))))
             (dolist (thread threads) (cs-join thread)) (is (equalp buffer before)))
        (dotimes (wave 2) (sb-thread:signal-semaphore (svref go wave) 2))
        (cs-stop-workers threads)))))
