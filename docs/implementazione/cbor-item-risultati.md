# Verifiche della lettura del primo item CBOR minimo

Campagna del 2026-10-15 per [REQ-CBR-008](cbor-item-metodo.md):
lettura strutturale del primo item senza interpretare la coda.
MAX-BYTES limita l'intera finestra autorizzata, coda inclusa.
Gli scanner esatti conservano l'obbligo di EOF.
Le [prove originali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-cbor-item-read/catalogo.lisp)
conservano corpus, letture, processi e risultati grezzi.

## Sorgenti e cronologia

Metodo `a67a79bf4fefe11c4778cd881eb5279a006966ca`, preregistrazione
`03dbc4e2b59e021456d2c3d67e7d8ff12662e2e2`. Il nuovo kernel viene
scritto dopo il freeze del corpus; ASDF/export e scope di copertura
sono predisposti come integrazione dichiarativa. Due letture C1
precedono ogni compilazione del kernel.
Il freeze compilato è `46aee8b920d447aafae4a4e47a44d13631c47cb1`.

| File | Blob Git |
|---|---|
| src/codec/cbor-item-read.lisp | b9099dc8a8c96281063811e686deb4dcb2b1d39b |
| tests/codec/cbor-item-read-support.lisp | 0326100362a1c4b24d2c7e511e45357f09a56d33 |
| tests/codec/cbor-item-read.lisp | b2cbdcb4255c51d9da4fe73b28939c1cb923fefe |
| tests/codec/cbor-item-read-threads.lisp | a0da65545ed80ede0a967cadbb337731f6fe1ce9 |

Inventario completo del kernel: una funzione di 34 righe, otto percorsi
sintattici includendo LOOP, sei predicati, cinque bracci ERROR,
quattro confronti binari, zero AND/OR e zero catene numeriche.
Il ciclo ha limite SPAN, il drain ha limite102; preflight e lettori
mantengono i controlli esistenti. Tutti i rami e le guardie interne
rimangono nei denominatori. Lo snapshot conserva 24 file,
240535 byte e tre confronti bytes/SHA per copia, 72 in totale.

## Corpus e parallelismo

Passano 17 test nominali, 16 seriali e uno parallelo.
Oracoli letterali e aritmetici per tutti i major, larghezze, float raw,
UTF8 e contenitori; code vuote, valide, malformate e non minime.
Frontiere concatenate, START nonzero, END logico, intero array fisico,
arità tre, alias, preflight immutabile e precedenze, byte 16 MiB/+1,
nodi comprensivi di radice/tag, depth 0/100/101 e riuso dopo errore.
Gli scanner esatti sono controlli secondari: 520 sul prefisso,
390 rifiuti trailing e due sul concatenato, fuori dal totale della nuova API.

Fuzz 1024: seme `49544538`, finale `6CB25938`, 512 successi e
512 rifiuti in otto famiglie. Il finale è asserito nel corpus e
ricalcolato a freddo, senza attribuirgli una stampa runtime.

Due worker reali riusati per due ondate di2048 chiamate ciascuno:
8192 letture con buffer condiviso in sola lettura e scratch privati.
Contenuto C0 A1 61 61 82 F4 F5, coda FF 1C 18 00, START 7/END 18;
6 nodi, picco 2 e NEXT 14 sono controllati per chiamata dal corpus.
Token 36196 e sink 74129408 per worker/ondata concordano con gli oracoli.
START/FIRST/END, sink e overlap sono stampati. Overlap iniziali
4831/3652 tick a un milione di tick/s; nel check completo3339/2681.
Gli intervalli includono rendezvous dopo il primo item e controlli:
non misurano il solo decoder né attestano scaling o simultaneità sui core.

Le 9901 chiamate sono un denominatore aritmetico del piano:
685 non fuzz (551 successi/134 rifiuti), 1024 fuzz e 8192 parallele;
9255 successi e 646 rifiuti. Non è un contatore strumentato.

## Benchmark e mutazioni

Sei fixture fredde, cinque repliche da1024 chiamate e warmup 64:
30 campioni con contatore heap presente e pari a zero.
Tutti i tre valori, buffer fisico e sei scalari dello scratch sono
controllati per chiamata. Baseline nulla zero e controllo positivo
16 × 1 MiB:16777472 byte. Somma campioni 0,035106 s; wrapper 3,358691 s.
Carico esterno non controllato e costo dei controlli incluso:
non si attestano assenza assoluta di allocazioni o throughput del motore.
L'audit passa71252 verifiche; la lettura DATA indipendente8389.

Otto mutanti compilabili risultano DETECTED: minimalità disattivata,
drain su END fisico, NEXT=END con coda saltata, budget nodi ignorato,
profondità ignorata, budget byte ignorato, START saltato e arità extra.
Due smoke precedono Unhandled e una sola funzione nominale esatta
della whitelist17 compare come frame a zero argomenti: exit1,
segnale NIL, nessun warning, compilefail o marker di completamento.
Questi guasti estranei non valgono come rilevamenti.

Baseline 1545 nominali e due smoke; wrapper 405,513322 s.
Nove copie/cache/runner privati, 382 file per copia e 387 impronte
interne, di cui cinque driver/cataloghi ignored;931 fonti esterne STABLE.
Il lettore DATA esegue3438 confronti binari sull'intero contesto Git
e gli originali: baseline 0 differenze, una sostituzione esatta del
catalogo in ciascun mutante. FTYPE e ritorno extra cambiano coerentemente
nella sola copia. Il confronto non autentica l'esecuzione né dimostra
causalità esclusiva.

## Copertura grezza

Il report del solo nuovo sorgente osserva **64/90 espressioni e 8/12
rami**, pari a 71,111111% e 66,666667%. Denominatori integrali.
I 30 record mancanti sono 26 espressioni (tre dichiarazioni, 20 record
dei cinque ERROR e tre default keyword) e quattro rami ELSE.
HTML, indice e raw concordano; nessuna esclusione o riclassificazione.
Zero AND/OR nel nuovo kernel non qualifica MC/DC dell'intero decoder.

Dopo la lettura DATA congelata, il raw di3004878 byte è compattato
senza perdita. SHA256 decodificato
`795f90f4291b16ddc8fcb61ca82150eabd1499539a02e04275daf542dfcc54cd`;
payload428375 byte. Restano i limiti1 MiB plain e 8 MiB gzip.

## Verifiche integrate

Sul freeze 46aee8b9 passa il check completo:1545 nominali, due smoke,
quattro self-test linter, 225 file con zero violazioni, 122 requisiti,
65 invarianti,13 scenari FI e 52 ADR senza errori;511 file e 3076 link
senza rotture. Passano self-test di conservazione,114 cataloghi,
3393 riferimenti e 40699 file, e tutti i dieci spike.
Wrapper 469,05808 s;931 fonti STABLE e working tree pulito.
Note del compilatore e fallimenti intenzionali dei self-test sono conservati.

Dopo l'integrazione di main 2cf3c38d sul merge203e3c71 passano build,
lint, trace e link:1545 nominali e due smoke, 231 file con zero violazioni,
122 requisiti/65 invarianti/13 FI/52 ADR, 520 file e 3089 link senza rotture.
Wrapper 57,257384 s;938 fonti STABLE e working tree pulito. I quattro blob
del kernel/corpus restano identici; overlap worker 2151/2278 tick a 1 MHz.
Il precedente check completo conserva il proprio scope 46aee8b9:
questo comando non riesegue gli spike globali.

## Conservazione

La raccolta iniziale usa quattro worker e chiude 422 file per 14
processi, con copie per worker 140/140/141/1 e nessun errore.
Origine prima/dopo e copia concordano per bytes/SHA, i processi decodificati
sono identici e il validator indipendente verifica l'inventario chiuso.

Le append seriali conservano preparazione, preflight, raccolta, lettura DATA
e copie verificate dell'osservazione/closure originali. Prima e dopo ogni
append passa l'audit delle impronte e dei metadata. L'inventario finale
contiene 19 processi registrati, tutti OK/exit 0/STABLE: 436 file indicizzati,
438 con indice e catalogo, per 8560283 byte indicizzati. L'indice misura
154755 byte; i limiti restano 1 MiB plain e 8 MiB gzip.

Dopo l'ultima append passa anche il controllo indipendente rigoroso
dell'intero inventario finale. Il suo registro è nel
[supplemento conclusivo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-cbor-item-read-final/catalogo.lisp):
un processo e quattro file indicizzati, sei con indice e catalogo.
Il supplemento conserva quel risultato senza modificare l'archivio
appena verificato; la sua raccolta supera a sua volta il validator.
Raccolta iniziale, audit delle append e chiusura finale mantengono scope distinti.

I nove mirror integrali restano nel backup locale verificato.
L'archivio pubblicato conserva report, log, ASDF, runner e i quattro
sorgenti del codec/corpus per ogni copia; gli altri file immutati sono
ricostruibili dal commit 46aee8b9. I mirror completi non sono tutti duplicati
nell'archivio pubblicato.

Le preparazioni sono inventariate nelle note: seed provvisorio corretto
prima del kernel, escape nello snapshot helper, date ereditate del collector,
controlli sintetici dei driver e pin coerenti, lettori DATA adattati
agli schemi/percorsi effettivi e query inline parentetica. Varianti ed esiti
locali disponibili sono conservati; i diagnostici soltanto in conversazione
sono distinti dai log locali originali. Nessun fallimento di preparazione
è attribuito al prodotto o conteggiato come mutazione rilevata.

I riepiloghi storici di mappe e tag ora distinguono audit delle append
e chiusura indipendente della raccolta iniziale, con originali invariati.
C1, MC/DC e profilo documentale deterministico restano aperti.

