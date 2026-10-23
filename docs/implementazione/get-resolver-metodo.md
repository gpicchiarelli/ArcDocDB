# Metodo di verifica funzionale: resolver CLOSED e prove OUTCOME

Questa campagna aggiunge una prima suite dedicata in
[`tests/get-resolver/`](../../tests/get-resolver/). Il perimetro è costruzione
della mappa CLOSED, ordinamento e ricerca delle prove OUTCOME, associazione
ai PUT prepared e lettura mediante le API pubbliche del resolver. Il metodo
è scritto prima delle esecuzioni. L'antenato di integrazione è `4344d9e`;
i commit di congelamento e gli esiti saranno registrati nelle prove native.

## Oracoli e casi fissati

La suite fissa 42 test nominati: 8 per ordinamento/ricerca, 13 per costruzione
e 21 per lettura. Un test può attraversare più formati, word o API;
queste iterazioni non aumentano il conteggio dei test nominati.

La fixture possiede un file reale, aperto readonly dal prodotto, una vista
canonica, un indice, un contesto GET, output privato e registri snapshot/EBR.
Header, cornici, SEAL e manifest sono codificati byte per byte con CRC32C
bitwise indipendente. Gli encoder provengono dal supporto della directory,
con attribuzione nel sorgente; non chiamano il writer o i codec del prodotto
per generare i dati attesi. Il manifest è interpretato dall'API pubblica
prima della costruzione della mappa. La fixture conserva offset, lunghezze,
TXID, CSN e valori attesi separati dalle strutture costruite dal resolver.

I formati sono v1 e v2, con chiavi di 16 byte. TXID e CSN attraversano il
confine `2^32` e raggiungono u64 massimo. L'ordine fisico degli OUTCOME può
differire da quello dei TXID. I casi comprendono zero, una e più prove,
duplicati identici stabili e CSN discordanti separatamente nella word alta
e bassa. Un OUTCOME antecedente al PUT è corruzione; un prepared senza prova
non autorizza una risposta. Byte invalidi dopo la frontiera CLOSED non
vanno letti né interpretati.

Il budget degli array è controllato al limite esatto e un byte sotto:
`24P + 20O` per O ≤ 1, `24P + 40O + 1024` per O ≥ 2. Il payload permanente
rimane `24P`. Riutilizzare il buffer sorgente dopo la costruzione non deve
alterare la mappa. Questi numeri descrivono payload degli array, non RSS,
allocazioni osservate o comportamento del GC.

Le prove seriali interne usano tuple esplicite (TXID, CSN, offset), senza
ordinamento o lookup del prodotto nell'oracolo. Esercitano tutte le otto
cifre radix, confini high/low, prima prova dei duplicati, miss ai bordi,
ordine fisico e rifiuto della geometria errata prima degli effetti.
Gli accessi interni sono dichiarati come verifiche di contratti locali;
non sostituiscono i casi attraverso `crea-mappa-segmento-get`.

Le letture usano `risolvi-candidato-get`, `sonda-cache-risolta-get` e
`leggi-record-risolto-get` dopo `avvia-get`. L'osservatore I/O registra FD,
offset e quantità: resolve/probe non leggono; prepared cold legge la prima
prova poi il PUT; prepared caldo rilegge la prova anche sulla cache hit.
Gli errori non autorizzano output. Copia provvisoria, conclusione con tempo
fresco, sentinelle, pin GET e annuncio EBR sono verificati esplicitamente.
Le fault injection riguardano soltanto risorse della fixture e sono
documentate nei test; il cleanup deve precedere riuso e chiusura del file.

## Esecuzione e conservazione

Prima di ogni gruppo si committano sorgenti, test, strumenti e questo
metodo. Nessuno di questi file cambia mentre il gruppo è in esecuzione.
I comandi sono avvolti da `tools/record-command.lisp`: conservano argv,
ambiente, commit, working tree, inventario/hash prima e dopo, stdout,
stderr ed exit code anche su errore. Un gruppo con sorgenti cambiati non
è accettato. Una correzione richiede un nuovo freeze; le prove precedenti
rimangono conservate e attribuite al proprio commit.

La verifica locale completa è `make check`. La copertura separata usa
[`get-resolver-coverage.lisp`](../../tools/get-resolver-coverage.lisp),
carica il sistema dei test senza invocarne `test-op` ed esegue soltanto
questa suite. Riporta i sette file CLOSED (package, types, scan, sort,
rows, build, read), con conteggi per file, stato grezzo e HTML. I sei file
ACTIVE sono esclusi dal rapporto locale. Espressioni e rami SB-COVER sono
diagnostici; non costituiscono prove MC/DC.

Prima della pull request devono passare compilazione senza avvisi,
regressione completa, controlli statici, tracciabilità, collegamenti e
verifica delle evidenze. La CI ripete i controlli su Linux e macOS, conserva
gli artefatti e controlla i documenti separatamente. I record si leggono
come dati tramite `tools/evidence-storage.lisp`; non si caricano report,
stato di copertura o FASL come codice. La pubblicazione conserva gruppi
completi, raw, errori e cataloghi LEAF originali, inclusi i FASL grezzi.

## Limiti delle conclusioni

Non si misurano prestazioni né allocazioni e non si eseguono mutanti in
questa campagna. La revisione indipendente comprende fixture, oracoli,
diff e risultati, distinta dall'autore. La suite non chiude qualifica C1,
MC/DC, requisito o Fase 0. Restano fuori ACTIVE, prove EDIT, storico,
directory mista, rotazione/reclaim, scheduler e integrazione del server.
