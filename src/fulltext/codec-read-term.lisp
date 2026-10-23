(in-package #:arcdocdb.fulltext.codec)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-007 REQ-SEC-008 REQ-SEC-010
(declaim (ftype (function (octets index index spazio-codec-full-text) null) verifica-termine-profilo))
(defun verifica-termine-profilo (buffer start end space)
  "Pre: termine entro capacita, scratch esclusivo. Post: esattamente un token identico ai byte.
Verifica UTF-8, NFC/folding/NFC e Word_Break; non confronta il documento sorgente.
Budget globale include il lavoro analitico; nessun input trattenuto su errore."
  (let* ((analysis (spazio-codec-full-text-analysis space))
         (remaining (- (spazio-codec-full-text-work-limit space) (spazio-codec-full-text-work space)))
         (capacity (spazio-codec-full-text-term-capacity space)))
    (when (zerop remaining) (error 'resource-exhausted :reason :fulltext-codec-work))
    (a:inizia-analisi-full-text analysis buffer start end :max-tokens capacity
                              :max-term-bytes (* 4 capacity) :max-work remaining)
    (unwind-protect
         (progn
           (loop repeat remaining until (eq :done (a:passo-analisi-full-text analysis 4096)))
           (unless (eq :done (a::spazio-full-text-phase analysis))
             (error 'invariant-violation :reason :fulltext-term-analysis-bound))
           (lavoro-codec space (a::spazio-full-text-work analysis))
           (multiple-value-bind (bytes begins ends n used) (a:risultati-analisi-full-text analysis)
             (unless (<= used (length bytes)) (error 'invariant-violation :reason :fulltext-term-analysis-size))
             (unless (and (= n 1)
                          (zerop (confronta-span-codec buffer start end bytes (aref begins 0) (aref ends 0) space)))
               (error 'corruption-detected :reason :fulltext-term-profile :offset start))))
      ;; Solo rilascio del prestito: il parser non conserva il file dopo un errore.
      (setf (a::spazio-full-text-input analysis) nil)
      (unless (eq :done (a::spazio-full-text-phase analysis)) (setf (a::spazio-full-text-phase analysis) :failed))))
  nil)
