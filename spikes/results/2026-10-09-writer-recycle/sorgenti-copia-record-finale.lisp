(:SCHEMA-VERSION 1 :KIND :PUBLICATION-RECORD-COPY-SOURCES :SOURCES
 ((:PATH #A((43) BASE-CHAR . "spikes/out/recycle-attach-final-record.lisp")
   :BYTES 558 :SHA256
   "344f8063fc31b810ba9cf717b31dd18336e062b95c6abc38aff484af4ccecf07" :GIT-BLOB
   "dccb1c231179b04914354470aa3ad5a7701f1095" :TEXT
   ";;;; Costruzione finale: copia lossless del record della chiusura e aggiornamento catalogo.
(load \"spikes/out/recycle-publication-functions.lisp\")
(recycle-copy-process \"4000529653-command-88586-0\" \"chiusura-pubblicazione-processo\")
(recycle-save-source-bundle
 '(\"spikes/out/recycle-attach-final-record.lisp\")
 (merge-pathnames \"sorgenti-copia-record-finale.lisp\" *recycle-publication-directory*)
 :publication-record-copy-sources)
(recycle-refresh-catalog \"673987ad819dd48741a7c0a4ff259137a1ed0bef\")
(format t \"Copia finale validata e catalogo chiuso.~%\")
")))
