;;;; Casi finiti EBR; nessuna gara interna alle funzioni inline viene simulata qui.
(in-package #:arcdocdb.epochs.tests)

;;; REQ: REQ-AFF-008 REQ-CMP-007
(deftest test-REQ-AFF-008-ebr-valid-capacities-and-initial-state
  (dolist (capacities '((1 1) (2 3) (4096 1) (1 65536)))
    (let ((registry (apply #'crea-registro-epoche capacities)))
      (epochs-check-state registry 1 1 0 0)
      (is (not (epoca-attiva-p (contesto-epoca registry (1- (first capacities)))))))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-ebr-worker-capacity-refusals
  (dolist (workers '(-1 0 4097 18446744073709551615))
    (signals invalid-argument (crea-registro-epoche workers 1) :epoch-registry-capacity)))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-ebr-retirement-capacity-refusals
  (dolist (retirements '(-1 0 65537 18446744073709551615))
    (signals invalid-argument (crea-registro-epoche 1 retirements) :epoch-registry-capacity)))

;;; REQ: REQ-CMP-005 REQ-AFF-008
(deftest test-REQ-CMP-005-ebr-canonical-context-and-worker-range
  (let ((registry (crea-registro-epoche 2 1)) (other (crea-registro-epoche 1 1)))
    (is (eq (contesto-epoca registry 0) (contesto-epoca registry 0)))
    (is (not (eq (contesto-epoca registry 0) (contesto-epoca registry 1))))
    (is (not (eq (contesto-epoca registry 0) (contesto-epoca other 0))))
    (dolist (worker '(-1 2 18446744073709551615))
      (epochs-refusal-preserves registry (lambda () (contesto-epoca registry worker))
                                'invalid-argument :epoch-worker-range))))

;;; REQ: REQ-CMP-005 REQ-CMP-007
(deftest test-REQ-CMP-005-ebr-enter-exit
  (let* ((registry (crea-registro-epoche 1 1)) (reader (contesto-epoca registry 0)))
    (is (not (epoca-attiva-p reader)))
    (is (entra-epoca reader))
    (is (epoca-attiva-p reader))
    (is (null (esci-epoca reader)))
    (is (not (epoca-attiva-p reader)))
    (epochs-check-state registry 1 1 0 0)))

;;; REQ: REQ-CMP-005 REQ-CMP-007
(deftest test-REQ-CMP-005-ebr-nested-entry-preserves-pin
  (let* ((registry (crea-registro-epoche 1 1)) (reader (contesto-epoca registry 0)))
    (is (entra-epoca reader))
    (unwind-protect
         (progn
           (epochs-refusal-preserves registry (lambda () (entra-epoca reader))
                                     'invalid-argument :epoch-reader-already-active)
           (is (epoca-attiva-p reader)))
      (when (epoca-attiva-p reader) (esci-epoca reader)))))

;;; REQ: REQ-CMP-005
(deftest test-REQ-CMP-005-ebr-inactive-exit-refused
  (let* ((registry (crea-registro-epoche 1 1)) (reader (contesto-epoca registry 0)))
    (epochs-refusal-preserves registry (lambda () (esci-epoca reader))
                              'invalid-argument :epoch-reader-inactive)))

;;; REQ: REQ-CMP-005 REQ-CMP-007
(deftest test-REQ-CMP-005-ebr-independent-readers
  (let* ((registry (crea-registro-epoche 2 1))
         (first (contesto-epoca registry 0)) (second (contesto-epoca registry 1)))
    (is (entra-epoca first)) (is (entra-epoca second))
    (unwind-protect
         (progn
           (esci-epoca first)
           (is (not (epoca-attiva-p first))) (is (epoca-attiva-p second))
           (is (entra-epoca first)) (is (epoca-attiva-p second)))
      (when (epoca-attiva-p first) (esci-epoca first))
      (when (epoca-attiva-p second) (esci-epoca second)))))

;;; REQ: REQ-CMP-005 REQ-CMP-007 REQ-AFF-004
(deftest test-REQ-CMP-005-ebr-owner-nonlocal-cleanup
  (let* ((registry (crea-registro-epoche 1 1)) (reader (contesto-epoca registry 0)))
    (is (eq :escaped
            (catch 'epochs-escape
              (unwind-protect
                   (progn (is (entra-epoca reader)) (throw 'epochs-escape :escaped))
                (when (epoca-attiva-p reader) (esci-epoca reader))))))
    (is (not (epoca-attiva-p reader)))
    (is (entra-epoca reader)) (esci-epoca reader)))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(deftest test-REQ-CMP-007-ebr-reservation-resource-and-credits
  (let ((registry (crea-registro-epoche 1 2)) (resource (list :segment)))
    (multiple-value-bind (ticket generation) (prenota-ritiro registry resource)
      (is (= 1 generation))
      (epochs-check-state registry 1 1 1 1)
      (epochs-check-ticket ticket generation :reserved 0)
      (is (eq resource (leggi-risorsa-ritiro ticket generation)))
      (annulla-ritiro ticket generation)
      (epochs-check-state registry 1 1 0 0))))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(deftest test-REQ-CMP-007-ebr-null-resource-preserves-state
  (let ((registry (crea-registro-epoche 1 1)))
    (epochs-refusal-preserves registry (lambda () (prenota-ritiro registry nil))
                              'invalid-argument :retirement-resource-null)
    (multiple-value-bind (ticket generation) (prenota-ritiro registry (list :first))
      (is (= generation 1)) (annulla-ritiro ticket generation))))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(deftest test-REQ-CMP-007-ebr-duplicate-resource-preserves-state
  (dolist (state '(:reserved :retired :claimed))
    (let ((registry (crea-registro-epoche 1 2)) (resource (list :same-segment)))
      (multiple-value-bind (ticket generation) (prenota-ritiro registry resource)
        (unless (eq state :reserved) (pubblica-ritiro ticket generation))
        (when (eq state :claimed)
          (aggiorna-soglia-reclaim registry) (is (acquisisci-reclaim ticket generation)))
        (epochs-refusal-preserves registry (lambda () (prenota-ritiro registry resource))
                                  'invalid-argument :retirement-resource-duplicate)
        (is (eq resource (leggi-risorsa-ritiro ticket generation)))))))

;;; REQ: REQ-AFF-008 REQ-CMP-007
(deftest test-REQ-AFF-008-ebr-full-capacity-preserves-state
  (let ((registry (crea-registro-epoche 1 1)))
    (multiple-value-bind (ticket generation) (prenota-ritiro registry (list :first))
      (epochs-refusal-preserves registry (lambda () (prenota-ritiro registry (list :second)))
                                'resource-exhausted :retirement-capacity)
      (annulla-ritiro ticket generation)
      (multiple-value-bind (next next-generation) (prenota-ritiro registry (list :second))
        (is (eq next ticket)) (is (= 2 next-generation))
        (annulla-ritiro next next-generation)))))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(deftest test-REQ-CMP-007-ebr-cancel-is-idempotent
  (let ((registry (crea-registro-epoche 1 1)))
    (multiple-value-bind (ticket generation) (prenota-ritiro registry (list :segment))
      (is (null (annulla-ritiro ticket generation)))
      (epochs-check-ticket ticket generation :cancelled 0)
      (let ((before (epochs-private-image registry)))
        (is (null (annulla-ritiro ticket generation)))
        (is (equalp before (epochs-private-image registry))))
      (epochs-check-state registry 1 1 0 0)
      (signals invalid-argument (leggi-risorsa-ritiro ticket generation)
               :retirement-resource-released))))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(deftest test-REQ-CMP-007-ebr-publish-advances-once
  (let ((registry (crea-registro-epoche 1 2)))
    (multiple-value-bind (first g1) (prenota-ritiro registry (list :first))
      (multiple-value-bind (second g2) (prenota-ritiro registry (list :second))
        (epochs-check-state registry 1 1 2 2)
        (is (null (pubblica-ritiro first g1)))
        (epochs-check-ticket first g1 :retired 1)
        (epochs-check-state registry 2 1 2 1)
        (epochs-refusal-preserves registry (lambda () (pubblica-ritiro first g1))
                                  'invalid-argument :retirement-not-reserved)
        (pubblica-ritiro second g2)
        (epochs-check-ticket second g2 :retired 2)
        (epochs-check-state registry 3 1 2 0)))))

;;; REQ: REQ-CMP-007
(deftest test-REQ-CMP-007-ebr-published-retirement-cannot-cancel
  (let ((registry (crea-registro-epoche 1 1)))
    (multiple-value-bind (ticket generation) (prenota-ritiro registry (list :segment))
      (pubblica-ritiro ticket generation)
      (epochs-refusal-preserves registry (lambda () (annulla-ritiro ticket generation))
                                'invalid-argument :retirement-cannot-cancel)
      (epochs-refusal-preserves registry (lambda () (completa-reclaim ticket generation))
                                'invalid-argument :retirement-not-claimed)
      (epochs-check-ticket ticket generation :retired 1))))

;;; REQ: REQ-CMP-007 REQ-AFF-004
(deftest test-REQ-CMP-007-ebr-invalid-ticket-state-operations
  (dolist (terminal '(:cancelled :completed))
    (let ((registry (crea-registro-epoche 1 1)))
      (multiple-value-bind (ticket generation) (prenota-ritiro registry (list :segment))
        (epochs-refusal-preserves registry (lambda () (completa-reclaim ticket generation))
                                  'invalid-argument :retirement-not-claimed)
        (epochs-refusal-preserves registry (lambda () (acquisisci-reclaim ticket generation))
                                  'invalid-argument :retirement-not-available)
        (if (eq terminal :cancelled)
            (annulla-ritiro ticket generation)
            (progn (pubblica-ritiro ticket generation) (aggiorna-soglia-reclaim registry)
                   (is (acquisisci-reclaim ticket generation)) (completa-reclaim ticket generation)))
        (epochs-refusal-preserves registry (lambda () (pubblica-ritiro ticket generation))
                                  'invalid-argument :retirement-not-reserved)
        (epochs-refusal-preserves registry (lambda () (acquisisci-reclaim ticket generation))
                                  'invalid-argument :retirement-not-available)
        (epochs-refusal-preserves registry (lambda () (leggi-risorsa-ritiro ticket generation))
                                  'invalid-argument :retirement-resource-released)
        (epochs-refusal-preserves
         registry
         (if (eq terminal :cancelled) (lambda () (completa-reclaim ticket generation))
             (lambda () (annulla-ritiro ticket generation)))
         'invalid-argument
         (if (eq terminal :cancelled) :retirement-not-claimed :retirement-cannot-cancel))))))

;;; REQ: REQ-CMP-007 REQ-CMP-005
(deftest test-REQ-CMP-007-ebr-strict-reclaim-threshold
  (let* ((registry (crea-registro-epoche 1 1)) (reader (contesto-epoca registry 0)))
    (is (entra-epoca reader))
    (unwind-protect
         (multiple-value-bind (ticket generation) (prenota-ritiro registry (list :segment))
           (pubblica-ritiro ticket generation) (aggiorna-soglia-reclaim registry)
           (epochs-check-state registry 2 1 1 0)
           (is (null (acquisisci-reclaim ticket generation)))
           (epochs-check-ticket ticket generation :retired 1)
           (esci-epoca reader) (aggiorna-soglia-reclaim registry)
           (epochs-check-state registry 2 2 1 0)
           (is (acquisisci-reclaim ticket generation))
           (epochs-check-ticket ticket generation :claimed 1))
      (when (epoca-attiva-p reader) (esci-epoca reader)))))

;;; REQ: REQ-CMP-007 REQ-CMP-005
(deftest test-REQ-CMP-007-ebr-two-old-readers-block-reclaim
  (let* ((registry (crea-registro-epoche 2 1))
         (first (contesto-epoca registry 0)) (second (contesto-epoca registry 1)))
    (is (entra-epoca first)) (is (entra-epoca second))
    (unwind-protect
         (multiple-value-bind (ticket generation) (prenota-ritiro registry (list :segment))
           (pubblica-ritiro ticket generation) (aggiorna-soglia-reclaim registry)
           (is (null (acquisisci-reclaim ticket generation)))
           (esci-epoca first) (aggiorna-soglia-reclaim registry)
           (epochs-check-state registry 2 1 1 0)
           (is (null (acquisisci-reclaim ticket generation)))
           (esci-epoca second) (aggiorna-soglia-reclaim registry)
           (is (acquisisci-reclaim ticket generation)))
      (when (epoca-attiva-p first) (esci-epoca first))
      (when (epoca-attiva-p second) (esci-epoca second)))))

;;; REQ: REQ-CMP-007 REQ-CMP-005
(deftest test-REQ-CMP-007-ebr-new-reader-does-not-block-old-retirement
  (let* ((registry (crea-registro-epoche 2 1))
         (old (contesto-epoca registry 0)) (new (contesto-epoca registry 1)))
    (is (entra-epoca old))
    (unwind-protect
         (multiple-value-bind (ticket generation) (prenota-ritiro registry (list :segment))
           (pubblica-ritiro ticket generation) (is (entra-epoca new))
           (aggiorna-soglia-reclaim registry) (is (null (acquisisci-reclaim ticket generation)))
           (esci-epoca old) (aggiorna-soglia-reclaim registry)
           (epochs-check-state registry 2 2 1 0)
           (is (epoca-attiva-p new)) (is (acquisisci-reclaim ticket generation)))
      (when (epoca-attiva-p old) (esci-epoca old))
      (when (epoca-attiva-p new) (esci-epoca new)))))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(deftest test-REQ-CMP-007-ebr-threshold-is-monotone
  (let* ((registry (crea-registro-epoche 1 1)) (reader (contesto-epoca registry 0)))
    (multiple-value-bind (ticket generation) (prenota-ritiro registry (list :segment))
      (pubblica-ritiro ticket generation) (aggiorna-soglia-reclaim registry)
      (epochs-check-state registry 2 2 1 0)
      ;; FI d'un annuncio vecchio non confermato: non rappresenta un reader ammesso.
      (setf (aref (arcdocdb.epochs::registro-epoche-announcements registry)
                  (arcdocdb.epochs::lettore-epoca-offset reader)) 1)
      (unwind-protect
           (progn (aggiorna-soglia-reclaim registry)
                  (epochs-check-state registry 2 2 1 0))
        (esci-epoca reader)))))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(deftest test-REQ-CMP-007-ebr-resource-until-completion
  (let ((registry (crea-registro-epoche 1 1)) (resource (list :canonical-segment)))
    (multiple-value-bind (ticket generation) (prenota-ritiro registry resource)
      (is (eq resource (leggi-risorsa-ritiro ticket generation)))
      (pubblica-ritiro ticket generation)
      (is (eq resource (leggi-risorsa-ritiro ticket generation)))
      (aggiorna-soglia-reclaim registry) (is (acquisisci-reclaim ticket generation))
      (is (eq resource (leggi-risorsa-ritiro ticket generation)))
      ;; Un I/O fallito non chiama completa-reclaim: il credito e la risorsa restano.
      (epochs-check-state registry 2 2 1 0)
      (epochs-check-ticket ticket generation :claimed 1)
      (epochs-refusal-preserves registry (lambda () (annulla-ritiro ticket generation))
                                'invalid-argument :retirement-cannot-cancel)
      (epochs-refusal-preserves registry (lambda () (pubblica-ritiro ticket generation))
                                'invalid-argument :retirement-not-reserved)
      (epochs-refusal-preserves registry (lambda () (prenota-ritiro registry (list :other)))
                                'resource-exhausted :retirement-capacity)
      (completa-reclaim ticket generation)
      (epochs-check-state registry 2 2 0 0)
      (epochs-check-ticket ticket generation :completed 1)
      (signals invalid-argument (leggi-risorsa-ritiro ticket generation)
               :retirement-resource-released))))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(deftest test-REQ-CMP-007-ebr-completion-is-idempotent
  (let ((registry (crea-registro-epoche 1 1)))
    (multiple-value-bind (ticket generation) (prenota-ritiro registry (list :segment))
      (pubblica-ritiro ticket generation) (aggiorna-soglia-reclaim registry)
      (is (acquisisci-reclaim ticket generation))
      (is (null (completa-reclaim ticket generation)))
      (let ((before (epochs-private-image registry)))
        (is (null (completa-reclaim ticket generation)))
        (is (equalp before (epochs-private-image registry))))
      (epochs-check-state registry 2 2 0 0))))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(deftest test-REQ-CMP-007-ebr-stale-generation-preserves-reuse
  (dolist (old-terminal '(:cancelled :completed))
    (let ((registry (crea-registro-epoche 1 1)) (new-resource (list :new-segment)))
      (multiple-value-bind (old old-generation) (prenota-ritiro registry (list :old-segment))
        (if (eq old-terminal :cancelled)
            (annulla-ritiro old old-generation)
            (progn (pubblica-ritiro old old-generation) (aggiorna-soglia-reclaim registry)
                   (is (acquisisci-reclaim old old-generation)) (completa-reclaim old old-generation)))
        (multiple-value-bind (new new-generation) (prenota-ritiro registry new-resource)
          (is (eq old new)) (is (= 1 old-generation)) (is (= 2 new-generation))
          (dolist (thunk (epochs-ticket-operations old old-generation))
            (epochs-refusal-preserves registry thunk 'invalid-argument :retirement-stale-identity))
          (epochs-check-ticket new new-generation :reserved 0)
          (is (eq new-resource (leggi-risorsa-ritiro new new-generation)))
          (annulla-ritiro new new-generation))))))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(deftest test-REQ-CMP-007-ebr-zero-and-wrong-generation-preserve-state
  (let ((registry (crea-registro-epoche 1 1)))
    (multiple-value-bind (ticket generation) (prenota-ritiro registry (list :segment))
      (dolist (wrong (list 0 (1+ generation) +epochs-maximum+))
        (dolist (thunk (epochs-ticket-operations ticket wrong))
          (epochs-refusal-preserves registry thunk 'invalid-argument :retirement-stale-identity)))
      (annulla-ritiro ticket generation))))

;;; REQ: REQ-AFF-008 REQ-CMP-007
(deftest test-REQ-AFF-008-ebr-generation-maximum-without-wrap
  (let ((registry (crea-registro-epoche 1 2)))
    (epochs-set-word registry arcdocdb.epochs::+word-generation+ (1- +epochs-maximum+))
    (multiple-value-bind (ticket generation) (prenota-ritiro registry (list :last-generation))
      (is (= generation +epochs-maximum+))
      (epochs-check-ticket ticket generation :reserved 0)
      (epochs-refusal-preserves registry (lambda () (prenota-ritiro registry (list :overflow)))
                                'resource-exhausted :retirement-sequence-exhausted)
      (annulla-ritiro ticket generation)
      (epochs-refusal-preserves registry (lambda () (prenota-ritiro registry (list :overflow)))
                                'resource-exhausted :retirement-sequence-exhausted))))

;;; REQ: REQ-AFF-008 REQ-CMP-007
(deftest test-REQ-AFF-008-ebr-epoch-credit-before-publication
  (let ((registry (crea-registro-epoche 1 2)))
    (epochs-set-word registry arcdocdb.epochs::+word-epoch+ (1- +epochs-maximum+))
    (multiple-value-bind (ticket generation) (prenota-ritiro registry (list :last-credit))
      (epochs-check-state registry (1- +epochs-maximum+) 1 1 1)
      (epochs-refusal-preserves registry (lambda () (prenota-ritiro registry (list :no-credit)))
                                'resource-exhausted :retirement-sequence-exhausted)
      (pubblica-ritiro ticket generation)
      (epochs-check-state registry +epochs-maximum+ 1 1 0)
      (epochs-check-ticket ticket generation :retired (1- +epochs-maximum+))
      (aggiorna-soglia-reclaim registry) (is (acquisisci-reclaim ticket generation))
      (completa-reclaim ticket generation)
      (epochs-refusal-preserves registry (lambda () (prenota-ritiro registry (list :no-wrap)))
                                'resource-exhausted :retirement-sequence-exhausted))))

;;; REQ: REQ-AFF-008 REQ-CMP-007
(deftest test-REQ-AFF-008-ebr-cancel-restores-epoch-credit
  (let ((registry (crea-registro-epoche 1 2)))
    (epochs-set-word registry arcdocdb.epochs::+word-epoch+ (1- +epochs-maximum+))
    (multiple-value-bind (ticket generation) (prenota-ritiro registry (list :cancelled-credit))
      (annulla-ritiro ticket generation)
      (epochs-check-state registry (1- +epochs-maximum+) 1 0 0)
      (multiple-value-bind (next next-generation) (prenota-ritiro registry (list :restored-credit))
        (is (= 2 next-generation))
        (pubblica-ritiro next next-generation)
        (epochs-check-state registry +epochs-maximum+ 1 1 0)))))

;;; REQ: REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-AFF-004-ebr-metadata-incoherence-faults
  (dolist (damage '(:generation-zero :generation-future :reserved-epoch :resource-missing
                    :cancelled-resource :cancelled-epoch :completed-resource :completed-zero
                    :retired-zero :retired-future :claimed-resource-missing :bad-state))
    (let ((registry (crea-registro-epoche 1 1)))
      (multiple-value-bind (ticket generation) (prenota-ritiro registry (list :segment))
        (let ((slot (arcdocdb.epochs::ritiro-slot ticket)))
          (ecase damage
            (:generation-zero (setf (aref (arcdocdb.epochs::registro-epoche-generations registry) slot) 0))
            (:generation-future
             (epochs-set-word registry arcdocdb.epochs::+word-generation+ 0))
            (:reserved-epoch (setf (aref (arcdocdb.epochs::registro-epoche-epochs registry) slot) 1))
            (:resource-missing (setf (aref (arcdocdb.epochs::registro-epoche-resources registry) slot) nil))
            ((:cancelled-resource :cancelled-epoch)
             (annulla-ritiro ticket generation)
             (if (eq damage :cancelled-resource)
                 (setf (aref (arcdocdb.epochs::registro-epoche-resources registry) slot) (list :unexpected))
                 (setf (aref (arcdocdb.epochs::registro-epoche-epochs registry) slot) 1)))
            ((:completed-resource :completed-zero :claimed-resource-missing)
             (pubblica-ritiro ticket generation) (aggiorna-soglia-reclaim registry)
             (is (acquisisci-reclaim ticket generation))
             (unless (eq damage :claimed-resource-missing) (completa-reclaim ticket generation))
             (if (eq damage :completed-zero)
                 (setf (aref (arcdocdb.epochs::registro-epoche-epochs registry) slot) 0)
                 (setf (aref (arcdocdb.epochs::registro-epoche-resources registry) slot)
                       (unless (eq damage :claimed-resource-missing) (list :unexpected)))))
            (:bad-state (setf (aref (arcdocdb.epochs::registro-epoche-states registry) slot) 6))
            ((:retired-zero :retired-future)
             (pubblica-ritiro ticket generation)
             (setf (aref (arcdocdb.epochs::registro-epoche-epochs registry) slot)
                   (if (eq damage :retired-zero) 0 2))))
          ;; Generazione zero: usiamo il controllo privato della forma, non l'evento valido.
          (if (eq damage :generation-zero)
              (sb-thread:with-mutex ((arcdocdb.epochs::registro-epoche-mutex registry))
                (signals invariant-violation (arcdocdb.epochs::verifica-slot-ritiro registry slot)
                         :retirement-metadata-inconsistent))
              (signals invariant-violation (leggi-ritiro ticket generation)
                       :retirement-metadata-inconsistent))
          (epochs-faulted-refusals registry (contesto-epoca registry 0) ticket generation))))))

;;; REQ: REQ-AFF-004 REQ-AFF-008 REQ-CMP-007
(deftest test-REQ-AFF-004-ebr-counter-incoherence-faults
  (dolist (damage '(:reserved-over-count :count-over-capacity :cursor :threshold-zero
                    :threshold-future :epoch-credit-overflow))
    (let ((registry (crea-registro-epoche 1 2)))
      (ecase damage
        (:reserved-over-count (setf (arcdocdb.epochs::registro-epoche-reserved registry) 1))
        (:count-over-capacity (setf (arcdocdb.epochs::registro-epoche-count registry) 3))
        (:cursor (setf (arcdocdb.epochs::registro-epoche-cursor registry) 2))
        (:threshold-zero (epochs-set-word registry arcdocdb.epochs::+word-threshold+ 0))
        (:threshold-future (epochs-set-word registry arcdocdb.epochs::+word-threshold+ 2))
        (:epoch-credit-overflow
         (prenota-ritiro registry (list :reserved-credit))
         (epochs-set-word registry arcdocdb.epochs::+word-epoch+ +epochs-maximum+)))
      (signals invariant-violation (leggi-registro-epoche registry) :epoch-counters-inconsistent)
      (epochs-faulted-refusals registry (contesto-epoca registry 0)))))

;;; REQ: REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-AFF-004-ebr-future-reader-faults
  (let* ((registry (crea-registro-epoche 1 1)) (reader (contesto-epoca registry 0)))
    (setf (aref (arcdocdb.epochs::registro-epoche-announcements registry)
                (arcdocdb.epochs::lettore-epoca-offset reader)) 2)
    (unwind-protect
         (progn
           (signals invariant-violation (aggiorna-soglia-reclaim registry) :epoch-reader-future)
           (epochs-faulted-refusals registry reader))
      (when (epoca-attiva-p reader) (esci-epoca reader))))
  (let* ((registry (crea-registro-epoche 1 1)) (reader (contesto-epoca registry 0)))
    (epochs-set-word registry arcdocdb.epochs::+word-epoch+ 0)
    (signals invariant-violation (entra-epoca reader) :epoch-zero)
    (is (not (epoca-attiva-p reader)))
    (epochs-faulted-refusals registry reader)))

;;; REQ: REQ-AFF-004 REQ-CMP-007 REQ-CMP-005
(deftest test-REQ-AFF-004-ebr-reader-cleanup-after-fault
  (let* ((registry (crea-registro-epoche 1 1)) (reader (contesto-epoca registry 0)))
    (is (entra-epoca reader))
    (epochs-set-word registry arcdocdb.epochs::+word-threshold+ 0)
    (unwind-protect
         (progn
           (signals invariant-violation (leggi-registro-epoche registry) :epoch-counters-inconsistent)
           (is (epoca-attiva-p reader))
           (is (null (esci-epoca reader)))
           (is (not (epoca-attiva-p reader)))
           (epochs-faulted-refusals registry reader))
      (when (epoca-attiva-p reader) (esci-epoca reader)))))
