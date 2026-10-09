(:SCHEMA-VERSION 1 :KIND :PUBLICATION-FINAL-ADAPTER-SOURCES :SOURCES
 ((:PATH #A((37) BASE-CHAR . "spikes/out/recycle-publish-final.lisp") :BYTES
   580 :SHA256
   "fe867e857ec51b7fd7e1e4f19d76137ac5f433f10c4084600669340c089d5d6c" :GIT-BLOB
   "54d6e19f9b083dfd77880dcc7d3055e92413da93" :TEXT
   "(load \"spikes/out/recycle-publication-functions.lisp\")
(recycle-copy-process \"4000529512-command-87244-0\" \"catalogo-pubblicazione-processo\")
(recycle-copy-process \"4000529540-command-87595-0\" \"chiusura-editoriale-processo\")
(recycle-save-source-bundle
 '(\"spikes/out/recycle-publish-final.lisp\")
 (merge-pathnames \"sorgenti-chiusura-pubblicazione.lisp\" *recycle-publication-directory*)
 :publication-final-adapter-sources)
(recycle-refresh-catalog \"673987ad819dd48741a7c0a4ff259137a1ed0bef\")
(format t \"Check editoriale conservato; tutti i dati riletti e catalogo aggiornato.~%\")
")))
