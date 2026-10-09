# Lettura C4 degli strumenti per le testate CBOR minime

Lettura statica dell'autore del nuovo kernel, conclusa prima delle campagne
del prodotto. Riguarda `tools/foundation-coverage.lisp` e
`spikes/out/cbor-minimal-collection/collect.lisp`, con lettura mirata della
dipendenza invariata `tools/evidence-storage.lisp`. Non costituisce una lettura
C1 indipendente del prodotto o un'approvazione umana. Nessun prodotto, test,
compilazione, coverage, collector o guard è stato eseguito dal revisore.

## Copertura

Lo scope `cbor-minimal` seleziona soltanto i suffissi esatti dei due file nuovi
`cbor-float-minimal.lisp` e `cbor-minimal.lisp`. Il self-test contiene entrambi
i positivi e negativi per header invariato, UTF-8, percorso dei test, suffisso
`.fake` e sottopercorso `/child`. Il dispatcher chiama la suite
`arcdocdb.cbor.minimal.tests:run`; lo scope `codec` include anche la nuova suite
oltre a UTF-8, header e struttura. Lo stato SB-COVER completo viene salvato
prima del report HTML filtrato; dichiarazioni e guardie dei file selezionati
restano nel denominatore. Export/package e moduli invariati non appartengono
al filtro focale, pur essendo caricati dalla build completa.

La cache viene tradotta esplicitamente sotto la directory di misura e il
driver controlla che il mapping FASL sia interno. Compilazioni forzate e
warning promossi ad errori impediscono una copertura apparentemente riuscita
dopo una build incompleta. Il chiamante assegna una directory nuova: il driver
non dimostra da solo che la directory sia esclusiva o priva di report vecchi.
Self-test e numeratori effettivi restano pendenti; nessuna attestazione MC/DC.

## Raccolta, finding e correzione

Il collector legge manifest e indice con `*read-eval* NIL` e EOF; legge i
rapporti tramite `read-evidence`, che valida anche descriptor, SHA256 e bytes
compressi/espansi. Il `load` presente riguarda il solo strumento locale
`tools/evidence-storage.lisp`, non manifest, report o log esterni.

È stato rilevato un difetto nel primo filtro dei tree `:lisp-and-log`: ammetteva
solo `.lisp`/`.log`, quindi copiava un descriptor `report.lisp` senza il
payload `.gz`. L'audit dei file copiati poteva riuscire senza garantire la
rilettura di quel rapporto. Finding sul blob originale collector
`4ec1aa3c993f0236caa44bd0ef30867ac37c73b7`, righe 43–45. Prima di eseguire il
collector, il coordinatore ha aggiunto `.gz` agli stessi suffissi. Il blob
corretto `12670016a52b29eaedca72bb746343f840824b53` è stato riletto: descriptor
e payload prodotti da `compact-evidence.lisp` (nome originale + `.gz`) vengono
copiati mantenendo lo stesso percorso relativo. Il guard separato deve ancora
verificare descriptor+payload in tree filtrato e tra i file di un processo.
Non si dichiara guard PASS sulla sola correzione statica.

Ogni copia conserva bytes e SHA256 del sorgente e confronta sia sorgente
dopo copia sia destinazione. Per i processi, il report decodificato viene
confrontato integralmente dopo la copia; la directory viene copiata senza
filtro di estensione, mantenendo il payload leaf del descriptor. Destinazioni
esistenti sono rifiutate. I tree filtrati includono ora `.lisp`, `.log`, `.gz`
e omettono i sottoalberi `fasl`; tree non filtrati conservano ogni file fuori
da quei sottoalberi. Il manifest stabilisce esplicitamente quali tree e file
singoli appartengono alla raccolta. Payload con un'altra estensione non sono
inclusi automaticamente dal modo filtrato: occorre un tree non filtrato o
un item esplicito; questa lettura attesta la correzione per i payload `.gz`
generati dallo strumento corrente, non per ogni possibile nome leaf.

I report originali non vengono riscritti. Status, exit, command e stabilità
vengono copiati come metadata osservati, senza trasformarli in attestazioni
di requisiti o gate. L'audit verifica hash/bytes dei file elencati e metadata
dei processi; non inferisce risultati delle campagne. L'append verifica prima
la raccolta precedente, aggiunge una directory di processo nuova e riscrive
solo l'indice derivato. Non fornisce pubblicazione atomica o storico automatico
dell'indice, né garanzie crash del collector. Il manifest locale e i suoi label
sono input del coordinatore: questo strumento non è un confine di sicurezza
per label arbitrari forniti da utenti esterni.

## Snapshot e limiti

| Fonte | Git blob letto |
|---|---|
| `tools/foundation-coverage.lisp` | `554b840090373179043aa39dd6491cd35433552a` |
| `spikes/out/cbor-minimal-collection/collect.lisp` corretto | `12670016a52b29eaedca72bb746343f840824b53` |
| `tools/evidence-storage.lisp`, dipendenza invariata | `fa2b5d36dca0837e2ed5e49b282887b2e110b2b7` |

Non resta un finding aperto per il filtro dei payload correnti dopo la
correzione. Restano pendenti guard del collector, self-test coverage, campagne
del prodotto e audit bytewise del dataset finale. Benchmark e mutatore sono
fuori da questa lettura. Il referto dati è
`spikes/out/cbor-minimal-tools-review.lisp`, schema 1, con fonte statica e
attribuzione del finding e della correzione.
