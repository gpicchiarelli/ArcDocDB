# Lettura C4 dello scope di copertura CBOR minimo strutturale

Lettura statica dell'autore dei driver, prima delle campagne. Il perimetro
è la modifica del coordinatore a `tools/foundation-coverage.lisp`: filtro
`cbor-minimal-scan`, dispatcher delle suite e controlli sintetici del filtro.
Non è una lettura C1 del prodotto o un'approvazione umana. Nessun prodotto,
test, compilazione o campagna di coverage è stato eseguito dal revisore;
i nuovi test del prodotto non sono stati letti.

## Filtro e dispatcher

Il nuovo scope seleziona soltanto i suffissi esatti
`/src/codec/cbor-scan.lisp` e `/src/codec/cbor-scan-minimal.lisp`. Il confronto
richiede che il suffisso termini alla fine del percorso, quindi non include
nomi `.lisp.fake` o sottopercorsi `/child`. Il self-test aggiunge entrambi
i positivi e cinque negativi: header, gestore degli item, percorso dei test,
suffisso falso e sottopercorso. Il filtro `codec` conserva il modulo intero.

Il dispatcher `cbor-minimal-scan` chiama prima
`arcdocdb.cbor.minimal.scan.tests:run`, poi
`arcdocdb.cbor.structure.tests:run`. La seconda chiamata esercita anche
l'API generica nel file comune. Il ramo `codec` aggiunge la nuova suite dopo
UTF-8, header, testate minime e struttura generica. Il nuovo nome di scope
è presente nella whitelist CLI, nell'uso e nella diagnostica. I comandi
precedenti conservano i loro rami.

## Produzione delle evidenze e limiti

Il motore invariato compila prodotto e test con `:force t`, trasforma i
warning in errori e traduce gli output ASDF nella cache `fasl` della
directory di lavoro; verifica inoltre che il mapping della cache sia interno.
Il salvataggio `coverage-state.lisp` precede il report HTML filtrato: il filtro
non rimuove forme o guardie dai due file focali. Il report senza dati viene
rifiutato. I moduli di input, stack, item, header e UTF-8 sono caricati ma
restano fuori dal denominatore focale; questa selezione non attesta la loro
copertura né la copertura MC/DC.

La directory viene scelta dal chiamante. Il driver usa
`ensure-directories-exist`, quindi l'esclusività e l'assenza di vecchi report
devono essere garantite dal runner della campagna. La lettura conferma il
percorso statico delle chiamate; esistenza e completamento runtime delle
suite, self-test, numeratori e stato grezzo restano pendenti.

## Snapshot ed esito

| Fonte | Git blob letto |
|---|---|
| `tools/foundation-coverage.lisp` | `19f323b8b15831ca15b8b370723c0f407b04a816` |

Il file è stato letto come forme con `*read-eval* NIL`, fino a EOF, senza
caricarlo o eseguirlo. Nessun finding aperto nella modifica dello scope.
Benchmark, mutatore e raccolta delle evidenze sono fuori da questa lettura;
la verifica runtime della copertura deve essere registrata separatamente.
