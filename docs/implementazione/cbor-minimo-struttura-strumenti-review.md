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

La lettura è stata rinnovata dopo l'integrazione con main
`b8cc54d81510bf0573e3c68abe3d51fa1d43a61a`. Lo scope upstream `series`
conserva il filtro di modulo `/src/series/`, il positivo publication e il
negativo tests/controller, il dispatcher `arcdocdb.series.tests:run` e la
presenza nella whitelist CLI, nell'uso e nella diagnostica. Entrambi gli
scope `series` e `cbor-minimal-scan` sono presenti nel file risultante.

## Importazione del motore di mutazione

La risoluzione importa interamente il motore upstream dello stesso main:
trasporto reale con exit/segnale, classificazione distinta `:worker-error`
per segnali e guasti dopo il marker finale, contatori, log e self-test dei
child SIGKILL/exit7 e dei rifiuti di copia/trasporto della baseline. Il gruppo
`--scan` seleziona soltanto il catalogo e i metadata; copie, cache privata,
baseline, classificatori e worker sono comuni ai due gruppi. Il report
iniziale conserva `:worker-errors 0` e `:mutants NIL` richiesti dal motore.
Il precedente driver blob `80a3b0ddd84a3827872d8b4d45fb8b7af178002a` è stato
conservato byte per byte in
`spikes/out/cbor-minimal-mutation-before-upstream.lisp`. Questa lettura è
statica: self-test reali del motore e campagne di entrambi i gruppi restano
da eseguire. Il catalogo scan preregistrato non è stato modificato.

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
| `tools/foundation-coverage.lisp`, dopo integrazione | `f40669cb156abf7d781b1359fc1406f58bbb45e5` |
| Motore mutazione upstream, main b8cc54d | `a9a94354a24bd3dc6bfe3a1511adbeb1d52c88d6` |
| `tools/cbor-minimal-mutation.lisp`, dopo integrazione | `60b1ac184498623d1364df66e1d95f93165af159` |

I file sono stati letti come forme con `*read-eval* NIL`, fino a EOF, senza
caricarli o eseguirli. Nessun finding aperto nella modifica dello scope o
nell'importazione statica del motore. Benchmark e raccolta delle evidenze
sono fuori da questa lettura;
la verifica runtime della copertura deve essere registrata separatamente.
