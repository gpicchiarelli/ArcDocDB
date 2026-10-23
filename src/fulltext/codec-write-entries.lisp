(in-package #:arcdocdb.fulltext.codec)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (r:indice-posizionale index index) boolean) stesso-termine-run-p))
(defun stesso-termine-run-p (run first second)
  "Pre: run sigillato e verificato dal piano. Post: uguaglianza campo/termine.
Costo gia riservato prima delle scritture; nessun contatore del run modificato."
  (let* ((data (r::indice-posizionale-tokens run)) (x (* first r::+token-width+)) (y (* second r::+token-width+))
         (a (aref data (+ x r::+offset+))) (b (aref data (+ y r::+offset+)))
         (bytes (r::indice-posizionale-bytes run)))
    (and (= (aref data (+ x r::+field+)) (aref data (+ y r::+field+)))
         (span-uguali-p bytes a (+ a (aref data (+ x r::+length+)))
                        bytes b (+ b (aref data (+ y r::+length+)))))))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets spazio-codec-full-text r:indice-posizionale index index index index)
                         (values index index &optional)) scrivi-termine-run))
(defun scrivi-termine-run (buffer space run token dict-index term-bytes posting-index)
  "Pre: piano e span riservati, nuovo termine. Post: entry DICT e stringa TERMS, nuovi cursori.
Solo preparazione in memoria; postcondizioni sui limiti restano sempre attive."
  (let* ((data (r::indice-posizionale-tokens run)) (p (* token r::+token-width+))
         (entry (+ (aref (spazio-codec-full-text-starts space) 1) (* dict-index +dict-width+)))
         (size (aref data (+ p r::+length+))) (source (aref data (+ p r::+offset+)))
         (target (+ (aref (spazio-codec-full-text-starts space) 2) term-bytes)))
    (unless (<= (+ entry +dict-width+) (aref (spazio-codec-full-text-starts space) 2))
      (error 'invariant-violation :reason :fulltext-write-dict-range))
    (scrivi-u16 buffer entry (aref data (+ p r::+field+)))
    (scrivi-u32 buffer (+ entry +dict-term-length+) size)
    (scrivi-u64 buffer (+ entry +dict-term-offset+) term-bytes)
    (scrivi-u64 buffer (+ entry +dict-first-posting+) posting-index)
    (replace buffer (r::indice-posizionale-bytes run) :start1 target :start2 source :end2 (+ source size))
    (unless (<= (+ term-bytes size) (aref (spazio-codec-full-text-lengths space) 2))
      (error 'invariant-violation :reason :fulltext-write-term-result))
    (values entry (+ term-bytes size))))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets spazio-codec-full-text u32 index index index) index) scrivi-posting-run))
(defun scrivi-posting-run (buffer space row ordinal posting-index dictionary)
  "Pre: nuovo posting del termine corrente. Post: riga, primo ordinale e numero posting DICT.
Frequenza aggiornata per ogni occorrenza dal ciclo chiamante."
  (let ((entry (+ (aref (spazio-codec-full-text-starts space) 3) (* posting-index +posting-width+))))
    (unless (<= (+ entry +posting-width+) (aref (spazio-codec-full-text-starts space) 4))
      (error 'invariant-violation :reason :fulltext-write-posting-range))
    (scrivi-u32 buffer entry row)
    (scrivi-u64 buffer (+ entry +posting-first-position+) ordinal)
    (scrivi-u64 buffer (+ dictionary +dict-posting-count+)
                (1+ (leggi-u64 buffer (+ dictionary +dict-posting-count+))))
    (unless (< entry (length buffer)) (error 'invariant-violation :reason :fulltext-write-posting-result))
    entry))
