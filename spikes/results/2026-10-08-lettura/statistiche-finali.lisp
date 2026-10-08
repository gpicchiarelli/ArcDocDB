(:SCHEMA-VERSION 1 :KIND :DERIVED-STATISTICS :STATUS :OK :INPUT
 #A((55) BASE-CHAR . "spikes/results/2026-10-08-lettura/benchmark-finale.lisp")
 :INPUT-GIT-BLOB "c37fa78ad038ef11e8fce6da14d21dfe8ba98542" :SOURCE
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
  #A((55) BASE-CHAR
     . "spikes/results/2026-10-08-lettura/benchmark-finale.lisp")
  #A((57) BASE-CHAR
     . "spikes/results/2026-10-08-lettura/statistiche-finali.lisp"))
 :CELLS 8 :PAIRS 40 :SAMPLES 80 :MEASURED-OPERATIONS 10240000
 :BUFFER-ZERO-CONSED-SAMPLES 40 :POSITIVE-CONTROL
 (:STATUS :OK :BEFORE 333663888 :AFTER 333926048 :BYTES-CONSED 262160 :ELEMENTS
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
   (:MEDIAN 153.15625d0 :MINIMUM 150.21875d0 :MAXIMUM 153.375d0)
   :BUFFER-NS-PER-OPERATION
   (:MEDIAN 78.0859375d0 :MINIMUM 77.8203125d0 :MAXIMUM 78.6171875d0)
   :BASELINE-CONSED-PER-OPERATION
   (:MEDIAN 47.604375d0 :MINIMUM 47.604375d0 :MAXIMUM 47.604375d0)
   :BUFFER-CONSED-PER-OPERATION (:MEDIAN 0.0d0 :MINIMUM 0.0d0 :MAXIMUM 0.0d0)
   :PAIRED-TIME-RATIO-BASELINE-OVER-BUFFER
   (:MEDIAN 1.9613806903451725d0 :MINIMUM 1.9107621981516447d0 :MAXIMUM
    1.9708864571830138d0))
  (:CELL 1 :LAYOUT :WORDS4 :PROFILE :FIELDS-FIXNUM :WORKLOAD :MIXED-HIT-MISS
   :BASELINE-NS-PER-OPERATION
   (:MEDIAN 150.28125d0 :MINIMUM 148.9609375d0 :MAXIMUM 168.734375d0)
   :BUFFER-NS-PER-OPERATION
   (:MEDIAN 68.703125d0 :MINIMUM 68.265625d0 :MAXIMUM 68.9375d0)
   :BASELINE-CONSED-PER-OPERATION
   (:MEDIAN 47.604375d0 :MINIMUM 47.604375d0 :MAXIMUM 47.604375d0)
   :BUFFER-CONSED-PER-OPERATION (:MEDIAN 0.0d0 :MINIMUM 0.0d0 :MAXIMUM 0.0d0)
   :PAIRED-TIME-RATIO-BASELINE-OVER-BUFFER
   (:MEDIAN 2.187151790790222d0 :MINIMUM 2.18207827878233d0 :MAXIMUM
    2.447642792384406d0))
  (:CELL 2 :LAYOUT :WORDS4 :PROFILE :U64-MASSIMI :WORKLOAD :HIT-ONLY
   :BASELINE-NS-PER-OPERATION
   (:MEDIAN 171.578125d0 :MINIMUM 168.1015625d0 :MAXIMUM 178.75d0)
   :BUFFER-NS-PER-OPERATION
   (:MEDIAN 79.34375d0 :MINIMUM 78.0d0 :MAXIMUM 82.28125d0)
   :BASELINE-CONSED-PER-OPERATION
   (:MEDIAN 111.604375d0 :MINIMUM 111.604375d0 :MAXIMUM 111.604375d0)
   :BUFFER-CONSED-PER-OPERATION (:MEDIAN 0.0d0 :MINIMUM 0.0d0 :MAXIMUM 0.0d0)
   :PAIRED-TIME-RATIO-BASELINE-OVER-BUFFER
   (:MEDIAN 2.199719551282051d0 :MINIMUM 2.081466008355488d0 :MAXIMUM
    2.2852576907710747d0))
  (:CELL 3 :LAYOUT :WORDS4 :PROFILE :U64-MASSIMI :WORKLOAD :MIXED-HIT-MISS
   :BASELINE-NS-PER-OPERATION
   (:MEDIAN 160.328125d0 :MINIMUM 159.1953125d0 :MAXIMUM 161.5390625d0)
   :BUFFER-NS-PER-OPERATION
   (:MEDIAN 68.59375d0 :MINIMUM 68.3203125d0 :MAXIMUM 69.1953125d0)
   :BASELINE-CONSED-PER-OPERATION
   (:MEDIAN 79.860375d0 :MINIMUM 79.860375d0 :MAXIMUM 79.860375d0)
   :BUFFER-CONSED-PER-OPERATION (:MEDIAN 0.0d0 :MINIMUM 0.0d0 :MAXIMUM 0.0d0)
   :PAIRED-TIME-RATIO-BASELINE-OVER-BUFFER
   (:MEDIAN 2.3225186524983044d0 :MINIMUM 2.3102630687591734d0 :MAXIMUM
    2.3644368210405946d0))
  (:CELL 4 :LAYOUT :WORDS5-EXTRA-END :PROFILE :FIELDS-FIXNUM :WORKLOAD
   :HIT-ONLY :BASELINE-NS-PER-OPERATION
   (:MEDIAN 153.6015625d0 :MINIMUM 152.640625d0 :MAXIMUM 156.46875d0)
   :BUFFER-NS-PER-OPERATION
   (:MEDIAN 78.7421875d0 :MINIMUM 78.6484375d0 :MAXIMUM 79.0234375d0)
   :BASELINE-CONSED-PER-OPERATION
   (:MEDIAN 47.604375d0 :MINIMUM 47.604375d0 :MAXIMUM 47.604375d0)
   :BUFFER-CONSED-PER-OPERATION (:MEDIAN 0.0d0 :MINIMUM 0.0d0 :MAXIMUM 0.0d0)
   :PAIRED-TIME-RATIO-BASELINE-OVER-BUFFER
   (:MEDIAN 1.9530148008344095d0 :MINIMUM 1.9384859609088203d0 :MAXIMUM
    1.989075379878836d0))
  (:CELL 5 :LAYOUT :WORDS5-EXTRA-END :PROFILE :FIELDS-FIXNUM :WORKLOAD
   :MIXED-HIT-MISS :BASELINE-NS-PER-OPERATION
   (:MEDIAN 149.359375d0 :MINIMUM 148.6015625d0 :MAXIMUM 149.96875d0)
   :BUFFER-NS-PER-OPERATION
   (:MEDIAN 68.4296875d0 :MINIMUM 68.2421875d0 :MAXIMUM 68.7421875d0)
   :BASELINE-CONSED-PER-OPERATION
   (:MEDIAN 47.604375d0 :MINIMUM 47.604375d0 :MAXIMUM 47.604375d0)
   :BUFFER-CONSED-PER-OPERATION (:MEDIAN 0.0d0 :MINIMUM 0.0d0 :MAXIMUM 0.0d0)
   :PAIRED-TIME-RATIO-BASELINE-OVER-BUFFER
   (:MEDIAN 2.1782042494859493d0 :MINIMUM 2.1641825008533395d0 :MAXIMUM
    2.1975958786491128d0))
  (:CELL 6 :LAYOUT :WORDS5-EXTRA-END :PROFILE :U64-MASSIMI :WORKLOAD :HIT-ONLY
   :BASELINE-NS-PER-OPERATION
   (:MEDIAN 177.296875d0 :MINIMUM 175.421875d0 :MAXIMUM 180.265625d0)
   :BUFFER-NS-PER-OPERATION
   (:MEDIAN 78.75d0 :MINIMUM 78.203125d0 :MAXIMUM 79.046875d0)
   :BASELINE-CONSED-PER-OPERATION
   (:MEDIAN 143.860375d0 :MINIMUM 143.860375d0 :MAXIMUM 143.860375d0)
   :BUFFER-CONSED-PER-OPERATION (:MEDIAN 0.0d0 :MINIMUM 0.0d0 :MAXIMUM 0.0d0)
   :PAIRED-TIME-RATIO-BASELINE-OVER-BUFFER
   (:MEDIAN 2.246253746253746d0 :MINIMUM 2.2404709638794653d0 :MAXIMUM
    2.2888602321198293d0))
  (:CELL 7 :LAYOUT :WORDS5-EXTRA-END :PROFILE :U64-MASSIMI :WORKLOAD
   :MIXED-HIT-MISS :BASELINE-NS-PER-OPERATION
   (:MEDIAN 166.078125d0 :MINIMUM 164.4296875d0 :MAXIMUM 167.0234375d0)
   :BUFFER-NS-PER-OPERATION
   (:MEDIAN 69.234375d0 :MINIMUM 68.3203125d0 :MAXIMUM 69.5234375d0)
   :BASELINE-CONSED-PER-OPERATION
   (:MEDIAN 96.244375d0 :MINIMUM 96.244375d0 :MAXIMUM 96.244375d0)
   :BUFFER-CONSED-PER-OPERATION (:MEDIAN 0.0d0 :MINIMUM 0.0d0 :MAXIMUM 0.0d0)
   :PAIRED-TIME-RATIO-BASELINE-OVER-BUFFER
   (:MEDIAN 2.4031967582170193d0 :MINIMUM 2.3987813134732567d0 :MAXIMUM
    2.407626636311895d0)))
 :LIMITS
 (:LOCAL-MEASUREMENT :FIVE-PAIRED-REPLICAS :NO-SIGNIFICANCE-CLAIM
  :FLOATING-DISPLAY-FROM-EXACT-RATIOS :NO-DATABASE-THROUGHPUT))
