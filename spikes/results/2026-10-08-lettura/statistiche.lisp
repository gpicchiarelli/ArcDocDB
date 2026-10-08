(:SCHEMA-VERSION 1 :KIND :DERIVED-STATISTICS :STATUS :OK :INPUT
 #A((48) BASE-CHAR . "spikes/results/2026-10-08-lettura/benchmark.lisp")
 :INPUT-GIT-BLOB "9df4efb5ae3680fcd939767f1c8bb670654a788e" :SOURCE
 (:PATH #A((46) BASE-CHAR . "/private/tmp/arcdocdb-lettura-statistiche.lisp")
  :GIT-BLOB "7ac3beee3e33e55b9cdf027db3ea2b09985fab7b" :CONTENTS
  "(require :asdf)
(declaim (optimize (safety 3)))
(defun read-data (path)
  (let ((*read-eval* nil) (eof (gensym)))
    (with-open-file (s path)
      (let ((r (read s nil eof))) (assert (eq eof (read s nil eof))) r))))
(defun text-file (path)
  (uiop:read-file-string path))
(defun git-blob (path)
  (string-trim '(#\\Newline #\\Return) (uiop:run-program (list \"git\" \"hash-object\" path) :output :string)))
(defun median (values)
  (let* ((s (sort (copy-list values) #'<)) (n (length s)))
    (assert (plusp n))
    (if (oddp n) (nth (floor n 2) s)
        (/ (+ (nth (1- (floor n 2)) s) (nth (floor n 2) s)) 2))))
(defun range-stats (values)
  (list :median (coerce (median values) 'double-float)
        :minimum (coerce (reduce #'min values) 'double-float)
        :maximum (coerce (reduce #'max values) 'double-float)))
(let* ((args (uiop:command-line-arguments)) (input (first args)) (output (second args))
       (record (read-data input)) (bench (getf (getf record :result) :benchmark))
       (samples (getf bench :samples)) (cells (getf bench :cells)) (rows nil)
       (check (getf (getf record :result) :buffer-check)))
  (assert (and (= 2 (length args)) (eq :ok (getf record :status))
               (eq :stable (getf record :source-consistency))
               (eq :ok (getf bench :status)) (eq :ok (getf check :status))))
  (assert (= 80 (length samples) (getf bench :completed-samples)))
  (assert (= 8 (length cells) (getf bench :completed-cells)))
  (assert (= 40 (getf bench :completed-pairs)))
  (assert (= 20 (getf bench :ab-pairs) (getf bench :ba-pairs)))
  (dolist (cell cells)
    (let ((base nil) (buffer nil) (ratios nil))
      (dolist (sample samples)
        (when (= (getf cell :cell) (getf sample :cell))
          (ecase (getf sample :method)
            (:baseline (push sample base)) (:buffer (push sample buffer)))))
      (assert (= 5 (length base) (length buffer)))
      (dolist (a base)
        (let ((b (find (getf a :replica) buffer :key (lambda (x) (getf x :replica)))))
          (assert b)
          (dolist (key '(:operations :checksum :retries :hits :misses))
            (assert (= (getf a key) (getf b key))))
          (push (/ (getf a :ns-per-operation) (getf b :ns-per-operation)) ratios)))
      (push (list :cell (getf cell :cell) :layout (getf cell :layout)
                  :profile (getf cell :profile) :workload (getf cell :workload)
                  :baseline-ns-per-operation (range-stats (mapcar (lambda (x) (getf x :ns-per-operation)) base))
                  :buffer-ns-per-operation (range-stats (mapcar (lambda (x) (getf x :ns-per-operation)) buffer))
                  :baseline-consed-per-operation (range-stats (mapcar (lambda (x) (getf x :bytes-consed-per-operation)) base))
                  :buffer-consed-per-operation (range-stats (mapcar (lambda (x) (getf x :bytes-consed-per-operation)) buffer))
                  :paired-time-ratio-baseline-over-buffer (range-stats ratios)) rows)))
  (let ((result (list :schema-version 1 :kind :derived-statistics :status :ok
                      :input input :input-git-blob (git-blob input)
                      :source (list :path (namestring *load-truename*)
                                    :git-blob (git-blob (namestring *load-truename*))
                                    :contents (text-file *load-truename*))
                      :argv sb-ext:*posix-argv* :cells 8 :pairs 40 :samples 80
                      :measured-operations (reduce #'+ samples :key (lambda (x) (getf x :operations)))
                      :buffer-zero-consed-samples (count-if (lambda (x) (and (eq :buffer (getf x :method))
                                                                            (zerop (getf x :bytes-consed)))) samples)
                      :positive-control (getf bench :allocation-positive-control)
                      :check-counts (list :principal (getf check :principal-cases)
                                          :negative (getf check :negative-controls)
                                          :reads (getf check :read-comparisons)
                                          :budget (getf check :budget))
                      :rows (nreverse rows)
                      :limits '(:local-measurement :five-paired-replicas :no-significance-claim
                                :floating-display-from-exact-ratios :no-database-throughput))))
    (ensure-directories-exist output)
    (with-open-file (s output :direction :output :if-exists :error)
      (let ((*print-readably* t)) (write result :stream s :pretty t) (terpri s)))
    (format t \"~S~%\" (getf result :rows))))
")
 :ARGV
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  #A((48) BASE-CHAR . "spikes/results/2026-10-08-lettura/benchmark.lisp")
  #A((50) BASE-CHAR . "spikes/results/2026-10-08-lettura/statistiche.lisp"))
 :CELLS 8 :PAIRS 40 :SAMPLES 80 :MEASURED-OPERATIONS 10240000
 :BUFFER-ZERO-CONSED-SAMPLES 0 :POSITIVE-CONTROL
 (:STATUS :OK :BEFORE 333721664 :AFTER 333983824 :BYTES-CONSED 262160 :ELEMENTS
  262144 :PAYLOAD-BYTES 262144 :OBSERVED-VALUE 172 :PRIMITIVE-OBJECT-SIZE
  262160 :OBJECT-TYPE "(SIMPLE-ARRAY (UNSIGNED-BYTE 8) (*))" :ESCAPED-GLOBAL
  "ARCDOCDB.SPK01.BENCH-LETTURA-BUFFER::*CONSED-POSITIVE-CONTROL*" :RETENTION
  :THROUGH-DELTA-AND-SIZE)
 :CHECK-COUNTS
 (:PRINCIPAL 54 :NEGATIVE 79 :READS 2032 :BUDGET
  (:MAXIMUM 200000 :REMAINING 173773 :ASSERTIONS 26227))
 :ROWS
 ((:CELL 0 :LAYOUT :WORDS4 :PROFILE :FIELDS-FIXNUM :WORKLOAD :HIT-ONLY
   :BASELINE-NS-PER-OPERATION
   (:MEDIAN 148.140625d0 :MINIMUM 146.8515625d0 :MAXIMUM 149.875d0)
   :BUFFER-NS-PER-OPERATION
   (:MEDIAN 144.734375d0 :MINIMUM 143.7578125d0 :MAXIMUM 145.8359375d0)
   :BASELINE-CONSED-PER-OPERATION
   (:MEDIAN 47.604375d0 :MINIMUM 47.604375d0 :MAXIMUM 47.604375d0)
   :BUFFER-CONSED-PER-OPERATION
   (:MEDIAN 47.604375d0 :MINIMUM 47.604375d0 :MAXIMUM 47.604375d0)
   :PAIRED-TIME-RATIO-BASELINE-OVER-BUFFER
   (:MEDIAN 1.0188050719965613d0 :MINIMUM 1.016517326999892d0 :MAXIMUM
    1.0366927857335855d0))
  (:CELL 1 :LAYOUT :WORDS4 :PROFILE :FIELDS-FIXNUM :WORKLOAD :MIXED-HIT-MISS
   :BASELINE-NS-PER-OPERATION
   (:MEDIAN 144.8515625d0 :MINIMUM 144.1484375d0 :MAXIMUM 147.515625d0)
   :BUFFER-NS-PER-OPERATION
   (:MEDIAN 135.9609375d0 :MINIMUM 135.46875d0 :MAXIMUM 139.0703125d0)
   :BASELINE-CONSED-PER-OPERATION
   (:MEDIAN 47.604375d0 :MINIMUM 47.604375d0 :MAXIMUM 47.604375d0)
   :BUFFER-CONSED-PER-OPERATION
   (:MEDIAN 47.604375d0 :MINIMUM 47.604375d0 :MAXIMUM 47.604375d0)
   :PAIRED-TIME-RATIO-BASELINE-OVER-BUFFER
   (:MEDIAN 1.0624784060808476d0 :MINIMUM 1.0388742205494073d0 :MAXIMUM
    1.0889273356401383d0))
  (:CELL 2 :LAYOUT :WORDS4 :PROFILE :U64-MASSIMI :WORKLOAD :HIT-ONLY
   :BASELINE-NS-PER-OPERATION
   (:MEDIAN 162.359375d0 :MINIMUM 159.40625d0 :MAXIMUM 173.6484375d0)
   :BUFFER-NS-PER-OPERATION
   (:MEDIAN 145.875d0 :MINIMUM 143.890625d0 :MAXIMUM 146.3359375d0)
   :BASELINE-CONSED-PER-OPERATION
   (:MEDIAN 111.604375d0 :MINIMUM 111.604375d0 :MAXIMUM 111.604375d0)
   :BUFFER-CONSED-PER-OPERATION
   (:MEDIAN 47.604375d0 :MINIMUM 47.604375d0 :MAXIMUM 47.604375d0)
   :PAIRED-TIME-RATIO-BASELINE-OVER-BUFFER
   (:MEDIAN 1.116190683027473d0 :MINIMUM 1.089317174737067d0 :MAXIMUM
    1.1941653682909794d0))
  (:CELL 3 :LAYOUT :WORDS4 :PROFILE :U64-MASSIMI :WORKLOAD :MIXED-HIT-MISS
   :BASELINE-NS-PER-OPERATION
   (:MEDIAN 154.1171875d0 :MINIMUM 151.546875d0 :MAXIMUM 170.4375d0)
   :BUFFER-NS-PER-OPERATION
   (:MEDIAN 139.453125d0 :MINIMUM 135.1640625d0 :MAXIMUM 145.5625d0)
   :BASELINE-CONSED-PER-OPERATION
   (:MEDIAN 79.860375d0 :MINIMUM 79.860375d0 :MAXIMUM 79.860375d0)
   :BUFFER-CONSED-PER-OPERATION
   (:MEDIAN 47.604375d0 :MINIMUM 47.604375d0 :MAXIMUM 47.604375d0)
   :PAIRED-TIME-RATIO-BASELINE-OVER-BUFFER
   (:MEDIAN 1.1212068666551067d0 :MINIMUM 1.054851867754401d0 :MAXIMUM
    1.2310123010946845d0))
  (:CELL 4 :LAYOUT :WORDS5-EXTRA-END :PROFILE :FIELDS-FIXNUM :WORKLOAD
   :HIT-ONLY :BASELINE-NS-PER-OPERATION
   (:MEDIAN 149.765625d0 :MINIMUM 148.3984375d0 :MAXIMUM 151.8125d0)
   :BUFFER-NS-PER-OPERATION
   (:MEDIAN 144.546875d0 :MINIMUM 143.6953125d0 :MAXIMUM 149.2265625d0)
   :BASELINE-CONSED-PER-OPERATION
   (:MEDIAN 47.604375d0 :MINIMUM 47.604375d0 :MAXIMUM 47.604375d0)
   :BUFFER-CONSED-PER-OPERATION
   (:MEDIAN 47.604375d0 :MINIMUM 47.604375d0 :MAXIMUM 47.604375d0)
   :PAIRED-TIME-RATIO-BASELINE-OVER-BUFFER
   (:MEDIAN 1.0327298428750067d0 :MINIMUM 1.0036123763153761d0 :MAXIMUM
    1.0502648362339206d0))
  (:CELL 5 :LAYOUT :WORDS5-EXTRA-END :PROFILE :FIELDS-FIXNUM :WORKLOAD
   :MIXED-HIT-MISS :BASELINE-NS-PER-OPERATION
   (:MEDIAN 145.84375d0 :MINIMUM 144.8515625d0 :MAXIMUM 147.484375d0)
   :BUFFER-NS-PER-OPERATION
   (:MEDIAN 137.1171875d0 :MINIMUM 135.3359375d0 :MAXIMUM 141.71875d0)
   :BASELINE-CONSED-PER-OPERATION
   (:MEDIAN 47.604375d0 :MINIMUM 47.604375d0 :MAXIMUM 47.604375d0)
   :BUFFER-CONSED-PER-OPERATION
   (:MEDIAN 47.604375d0 :MINIMUM 47.604375d0 :MAXIMUM 47.604375d0)
   :PAIRED-TIME-RATIO-BASELINE-OVER-BUFFER
   (:MEDIAN 1.0636430972594155d0 :MINIMUM 1.0221058434399117d0 :MAXIMUM
    1.0897650522426832d0))
  (:CELL 6 :LAYOUT :WORDS5-EXTRA-END :PROFILE :U64-MASSIMI :WORKLOAD :HIT-ONLY
   :BASELINE-NS-PER-OPERATION
   (:MEDIAN 166.0078125d0 :MINIMUM 163.1953125d0 :MAXIMUM 178.53125d0)
   :BUFFER-NS-PER-OPERATION
   (:MEDIAN 145.640625d0 :MINIMUM 143.8046875d0 :MAXIMUM 155.3671875d0)
   :BASELINE-CONSED-PER-OPERATION
   (:MEDIAN 143.860375d0 :MINIMUM 143.860375d0 :MAXIMUM 143.860375d0)
   :BUFFER-CONSED-PER-OPERATION
   (:MEDIAN 47.604375d0 :MINIMUM 47.604375d0 :MAXIMUM 47.604375d0)
   :PAIRED-TIME-RATIO-BASELINE-OVER-BUFFER
   (:MEDIAN 1.1482970286273018d0 :MINIMUM 1.134840006519259d0 :MAXIMUM
    1.1886344449134656d0))
  (:CELL 7 :LAYOUT :WORDS5-EXTRA-END :PROFILE :U64-MASSIMI :WORKLOAD
   :MIXED-HIT-MISS :BASELINE-NS-PER-OPERATION
   (:MEDIAN 155.921875d0 :MINIMUM 153.34375d0 :MAXIMUM 167.3828125d0)
   :BUFFER-NS-PER-OPERATION
   (:MEDIAN 143.015625d0 :MINIMUM 136.9765625d0 :MAXIMUM 144.8984375d0)
   :BASELINE-CONSED-PER-OPERATION
   (:MEDIAN 96.244375d0 :MINIMUM 96.244375d0 :MAXIMUM 96.244375d0)
   :BUFFER-CONSED-PER-OPERATION
   (:MEDIAN 47.604375d0 :MINIMUM 47.604375d0 :MAXIMUM 47.604375d0)
   :PAIRED-TIME-RATIO-BASELINE-OVER-BUFFER
   (:MEDIAN 1.1383106142702333d0 :MINIMUM 1.0857642303070032d0 :MAXIMUM
    1.1621284443480147d0)))
 :LIMITS
 (:LOCAL-MEASUREMENT :FIVE-PAIRED-REPLICAS :NO-SIGNIFICANCE-CLAIM
  :FLOATING-DISPLAY-FROM-EXACT-RATIOS :NO-DATABASE-THROUGHPUT))
