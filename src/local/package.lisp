;;; OWNER: attore locale; buffer e scratch esclusivi del chiamante.
;;; SHARED: nessuno stato globale scrivibile, nessuna dipendenza da spike o test.
;;; REQ: REQ-IPC-001 REQ-IPC-002 REQ-IPC-003 REQ-AFF-004
(defpackage #:arcdocdb.local
  (:use #:cl)
  (:local-nicknames (#:b #:arcdocdb.binary) (#:cbor #:arcdocdb.cbor)
                   (#:e #:arcdocdb.engine))
  (:export #:serve-local #:connect-local #:close-local
           #:client-put #:client-get #:client-delete #:client-ping
           #:protocol-error #:protocol-error-reason
           #:request-rejected #:rejection-status #:outcome-unknown #:unknown-cause
           #:local-cleanup-error #:local-primary #:local-failures
           #:envelope #:envelope-kind #:envelope-id #:envelope-code
           #:envelope-payload-start #:envelope-payload-end
           #:envelope-max-frame #:envelope-max-inflight
           #:decode-local-envelope #:decode-local-hello #:decode-local-welcome
           #:decode-local-command #:decode-local-response
           #:encode-local-hello #:encode-local-welcome
           #:encode-local-request #:encode-local-response #:encode-local-frame
           #:read-frame-length
           #:+server-max-frame+ #:+hello-limit+ #:+max-key-bytes+
           #:+max-document-bytes+ #:+max-get-frame+ #:+output-buffer-size+))
