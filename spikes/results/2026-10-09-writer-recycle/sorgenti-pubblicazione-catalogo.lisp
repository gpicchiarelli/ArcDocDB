(:SCHEMA-VERSION 1 :KIND :PUBLICATION-CATALOG-ADAPTER-SOURCES :SOURCES
 ((:PATH #A((39) BASE-CHAR . "spikes/out/recycle-publish-catalog.lisp") :BYTES
   479 :SHA256
   "ab8e30e15c4ab2ef67e3fd7a625f26b8d37559c070d97003b5531db0b48644db" :GIT-BLOB
   "6e6abed6fccf8aa8afdfc8f8c41b74c35189be72" :TEXT
   "(load \"spikes/out/recycle-publication-functions.lisp\")
(recycle-copy-process \"4000529382-command-84661-0\" \"pubblicazione-processo\")
(recycle-save-source-bundle
 '(\"spikes/out/recycle-publish-catalog.lisp\")
 (merge-pathnames \"sorgenti-pubblicazione-catalogo.lisp\" *recycle-publication-directory*)
 :publication-catalog-adapter-sources)
(recycle-refresh-catalog \"673987ad819dd48741a7c0a4ff259137a1ed0bef\")
(format t \"Processo della pubblicazione conservato; catalogo validato.~%\")
")))
