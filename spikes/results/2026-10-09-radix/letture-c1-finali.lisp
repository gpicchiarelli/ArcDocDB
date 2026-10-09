(:SCHEMA-VERSION 1 :KIND :C1-REVIEW-IMPORT :STATUS :READINGS-COMPLETED :ENTRIES
 ((:PATH "docs/implementazione/decisioni-radix-revisione.md" :GIT-BLOB
   "4434a2412cbcc6bab1bc5292331eb2c2eeabeb6a" :TEXT
   "# Seconda lettura C1 dell'ordinamento radix integrato

Lettura indipendente del 2026-10-09, eseguita dall'agente
`/root/scan_audit` sull'ordinamento DECISION integrato e sul test dei
lettori concorrenti. Esito dell'ispezione: nessun difetto funzionale
individuato nei sorgenti delimitati sotto. È una lettura automatica su
file verificabili, non un'approvazione umana né una qualifica di rilascio.

## Versione e ambito

Gli hash sono SHA256 dei contenuti letti, non identificatori Git.

| File | SHA256 |
|---|---|
| [`src/recovery/decisions-radix.lisp`](../../src/recovery/decisions-radix.lisp) | `564becba75721f15317b260b9a949eba716e682a9062c4e009d5463040c21e54` |
| [`src/recovery/decisions-build.lisp`](../../src/recovery/decisions-build.lisp), due chiamate integrate | `be292ec655087a229a1630179876da9e302a6121985ec3141a5e35226885a115` |
| [`tests/recovery/decisions-radix.lisp`](../../tests/recovery/decisions-radix.lisp), freeze finale | `75296b2de5620afd4f67117445197cb227adb4b9f65203e299ef6a4ee79518c0` |
| [`src/recovery/decisions-sort.lisp`](../../src/recovery/decisions-sort.lisp), baseline e controlli delegati | `cfb4d0c6e02bb0253cff992b4ab0f9664c18b9054ee334d541e69931ff0876a2` |
| [`src/recovery/decisions-query.lisp`](../../src/recovery/decisions-query.lisp), query preesistenti rilette | `08196938136a920e5e1cc84838726f721d1f43b59f1f677fac10871574171e24` |

Sono stati consultati anche tipi, builder e fixture della tabella per
controllare ownership, provenienza degli offset e limiti dei conteggi.
Questa lettura comprende il collegamento al builder, non riqualifica
l'intero recovery. Il diff rispetto al candidato preliminare SHA256
`5093e1dda2876d3b31fd5a6e9196dc76bec04aa8a61ce933c63de59f73f36505`
cambia l'header e aggiunge due costanti e due wrapper `if` in fondo al
file; il corpo degli ordinamenti coincide esattamente. Ripristinando
soltanto le due chiamate del builder si ottiene il precedente SHA256
`1bfedd82822ac47e17dcfa1ccf185bb48125d316daa3423cc501a2e0e624b3fb`.
La versione preliminare dei test era SHA256
`81d22bb4c5ac5375cf0daaa7443011b15a9563007151dd29d91dbfbbdfe9b915`;
il freeze sopra aggiunge guardie e regressioni pubbliche.

Sorgente radix e test congelati coincidono per hash con la copia finale
`arcdocdb-radix-final-pen8ap8t`. Tale copia parte dalla baseline
`10576a0` più le aggiunte del modulo radix; l'ASD della root contiene
lavori del runtime di altre chat ancora in corso. Le evidenze del clone
non attestano quei lavori né la loro integrazione nella root. Nessun
ASD, sorgente o test viene modificato da questa revisione.

L'[inventario delle decisioni e delle guardie](decisioni-radix-decisioni.md)
riporta le clausole dei predicati, i casi dei test e i limiti delle
motivazioni difensive. Il [metodo delle misure](decisioni-radix-metodo.md)
è distinto da questa lettura.

## Controlli sull'ordinamento

| Oggetto | Riscontro della seconda lettura |
|---|---|
| Ordine unsigned | TXID u64 è ordinato con otto cifre da meno a più significative. Nessuna rotazione del bit di segno; zero, bit alto e massimo sono valori ordinari. ID16 è ordinato lessicograficamente con sedici passate dal byte 15 al byte 0. |
| Istogramma e somme | Ogni passata conta l'intera sorgente corrente. Celle u64; totale `index`. La guardia `frequency <= N - total` precede l'incremento e la somma finale deve essere N. I prefissi esclusivi sono calcolati soltanto dopo questa verifica. |
| Uniformità | Zero o una classe occupata restituiscono falso. Il chiamante non esegue né scatter né swap; nessuno scratch non inizializzato viene letto come sorgente. L'uniformità non è dedotta da campioni. |
| Stabilità | Scatter in ordine crescente della sorgente e cursore crescente della classe. TXID uguali mantengono l'ordine fisico; il riferimento iniziale del gruppo non viene sostituito da CSN o altre chiavi. |
| Limiti degli array | Misura ID16 esatta, scratch della stessa lunghezza e identità distinta prima delle scritture. Cifra limitata a 16/8 e posizione inferiore alla cardinalità prima del cast a `index`. |
| Cursori dopo scatter | Monotonia, limite N e ultimo estremo esattamente N. La frequenza esatta di ogni classe deriva dal prefisso validato e dall'incremento per ogni elemento; non viene confrontata con una copia separata delle frequenze dopo scatter. |
| Risultato e corruzione | Restituito il buffer corrente, anche dopo un numero dispari di passate effettive. Controllo finale di ordine TXID; controllo finale ID16 conserva errore tipizzato per duplicato e offset del record. Il builder mantiene coalescenza tutto-o-niente dopo l'ordinamento e non restituisce una tabella su errore. |
| Ownership | Sorgente iniziale e scratch sono privati della costruzione; il sorter può riordinare la copia iniziale. Lo scatter non modifica la sorgente della singola passata. Le entry sono riferimenti a strutture private, senza scrittura dei loro campi. Nessun buffer originale viene esportato. |
| Risorse e controllo del flusso | Nessuna ricorsione. Cicli di cifra limitati a 8/16; istogramma e cursori a 256; scan/scatter alla cardinalità effettiva. Workspace della misura effettiva più 256 celle, non della capienza inutilizzata di un budget. |
| Effetti | Nessun I/O, attesa, pubblicazione, lock o stato globale mutabile. Il file dichiara OWNER/SHARED; allocazioni ammesse nel percorso di apertura. `safety 3`, `ftype`, docstring e riferimenti REQ presenti. |
| Selezione | `count < 1024` sceglie merge per ID16; `length(entries) < 256` sceglie merge per TXID. Alla soglia e oltre viene scelto radix. IF semplici, senza campionamento o nuovi percorsi di gestione dell'errore. |
| Sequenza del builder | `decode-decisions` passa copie private al wrapper ID16; il builder ordina le entry con il wrapper TXID prima di collapse. Scanner, budget e preflight restano prima delle copie. La soglia TXID riguarda i duplicati fisici prima della coalescenza. |

Il principio LSD con passate stabili e conteggio per classi è descritto
nel [riferimento primario di Princeton](https://www.cs.princeton.edu/courses/archive/fall07/cos226/lectures/18RadixSort.pdf).
L'applicazione agli unsigned u64, il salto delle passate uniformi e
l'argomento sui buffer sono verifiche dell'adattamento locale, non
garanzie di prestazione tratte dal riferimento.

## Controlli sui test

L'oracolo ID16 converte tutti i 128 bit in interi big-endian, ordina con
`CL:STABLE-SORT` e ricostruisce ogni ottetto. L'oracolo delle entry
ordina una copia soltanto per TXID e confronta ogni riferimento con
`eq`; la stabilità non viene dedotta dal solo ordine numerico. Entrambi
i sorter ricevono copie distinte delle fixture.

La versione dei test identificata sopra include cardinalità 0/1 per
le funzioni private, cardinalità dispari e massimo u16 per ID16, tre
pattern deterministici, ciascuno dei 128 bit degli ID e dei 64 bit dei
TXID in entrambi gli ordini, errori di misura e offset dei partecipanti
duplicati. Il caso a 65.536 entry, uniforme e con classe dominante più
outlier, colma la lacuna rilevata nella prima ispezione: una frequenza o
un cursore oltre u16 diventano osservabili. Non si attribuisce a questi
casi privati la validità di una DECISION pubblica con meno di due
partecipanti.

Il freeze finale contiene 18 test: nove iniziali, sei per le guardie
private e tre regressioni pubbliche. Le guardie sono negate
deliberatamente per somme e consumo, tipo delle entry, cifra fuori
range, ogni clausola dei due array guard, cursori fuori limite e
cursori finali decrescenti/incompleti. Si verificano rifiuti tipizzati
prima delle scritture dove previsto, sorgenti invariate e controlli
postscatter per prefissi sovrapposti. Restano distinti il limite u64
della cardinalità e la postcondizione di ordine finale del sorter.

Le regressioni pubbliche provano ID16 1.023/1.024/1.025 ed entry
255/256/257, in versioni 1/2 e con oracolo indipendente. Gli stessi
conteggi di entry sono provati sia con TXID distinti sia con duplicati
fisici coerenti che diventano un solo TXID. Il conflitto globale usa
258 record in tre lotti: il gruppo TXID massimo presenta il primo
conflitto fisico, il gruppo zero quello successivo. L'API deve indicare
l'offset del primo, non quello del primo gruppo visitato numericamente.
Sono verificati due tentativi e buffer invariato.

Il test concorrente costruisce una tabella completa e sovrascrive il
log originale prima di creare sei thread reali. Le closure condividono
la tabella e probe dichiarativi immutati; ogni thread possiede buffer
ID, posizione e output distinti. I risultati includono esplicitamente
found, CSN, count e membership, quindi CSN zero non viene confuso con
assenza. Sono presenti TXID zero/massimo, gap e cardinalità 3/5/17.

Ready e release coordinano la fixture con timeout; il worker restituisce
una condizione in caso di errore. I join hanno timeout e default di
fallimento; il test accetta soltanto ritorni `t`, verifica thread
terminati e confronta tutti gli output con l'oracolo. Il cleanup
rilascia e attende i thread già creati senza sopprimere l'errore della
preparazione. Le attese sono dell'harness e non entrano nella query o
in un worker di calcolo del motore. Le query restano scalari, prive
di scritture condivise per operazione.

La baseline rigorosa isolata dell'agente `/root/review_changes` ha
riportato exit 0 e nessun warning, con 43 test DECISION selezionati
(25 preesistenti più i 18 sopra). È stato letto il termine del log
`arcdocdb-radix-test-corrected-kbi2xy7r/baseline/test.log`, che contiene
`decision-tests-complete 43`. Questa lettura non ripete la build.

## Selezione misurata riletta

Sono stati letti come dati, senza eseguire il driver, i registri
`spikes/results/2026-10-09-radix/benchmark-100ms-dati.lisp` e
`spikes/results/2026-10-09-radix/selezione-100ms.lisp` nella copia
finale. Il [metodo](decisioni-radix-metodo.md) conserva la prima matrice
e l'emendamento precedente alla ripetizione: target di calibrazione
100 ms, minimo di ogni campione 50 ms, stesso criterio di rapporto
fra mediane al massimo 0,9 e stessa matrice completa.

| Ambito | Soglia adottata | Scenari misurati alla soglia e oltre | Peggior rapporto mediana radix/merge fra questi scenari |
|---|---|---|---|
| ID16 | 1.024 partecipanti | 16, tutti usabili e conformi al criterio | `0.857956293237167` |
| TXID | 256 entry fisiche | 25, tutti usabili e conformi al criterio | `0.759877353704754` |

Il registro conserva 63 scenari, di cui 58 usabili. I cinque non
usabili sono entry di cardinalità 16, nei pattern ordered, reverse,
mixed, duplicates e uniform: la calibrazione non raggiunge il target
prima del limite e questi scenari non entrano nel criterio. Non si
afferma che tutti i 63 scenari siano qualificati. Tutti i 41 scenari
alla soglia adottata e oltre sono invece usabili e passano il criterio.

La scelta è locale all'ambiente della misura e alle distribuzioni
provate. Il pattern ID16 con tutti i byte variabili ha le due metà
correlate; non rappresenta campionamento uniforme di tutti i 128 bit.
La misura comprende scratch e GC dell'ordinamento, conserva i dati
heap e non dimostra zero heap. Non viene estrapolata a cardinalità
non misurate, Linux/x86-64, throughput del motore o P99.

## Copertura grezza e guardie residue

È stato letto come dati lo stato grezzo della copertura
`spikes/out/decisions-radix-coverage-final/` nella copia finale.
I conteggi ricalcolati e confrontati con l'inventario sono:

| Ambito | Espressioni osservate/totali | Alternative di ramo osservate/totali |
|---|---|---|
| Sei sorgenti DECISION | 1.332 / 1.530 | 138 / 176 |
| Solo `decisions-radix.lisp` | 384 / 409 | 53 / 54 |

Le 25 espressioni mancanti nel radix sono 16 forme top-level
(package, policy optimize, costanti, deftype e declaim), una sottoforma
del tipo histogram e otto forme di errore in due siti: quattro per
cardinalità non u64 e quattro per ordine finale delle entry errato.
L'unica alternativa mancante è la negazione di
`typep(length(source), u64)`, RAD-G06. Il limite fixnum `index` e i
limiti degli array del runtime SBCL usato sono più stretti di u64:
la lunghezza non può violare quel controllo. RAD-G17 resta una
postcondizione difensiva contro un difetto dell'algoritmo; nella
misura sono assenti le forme del suo errore, senza un'ulteriore
alternativa di ramo mancante associata al `loop`.

I test privati provano invece le negazioni di prefissi, cifre, array,
tipo delle entry e cursori, come registrato nell'inventario. Le forme
residue restano nel denominatore grezzo. Nessuna esclusione approvata
o attestazione MC/DC deriva da questi numeri. L'inventario qui riguarda
il nuovo sorgente radix. Le motivazioni dei residui degli altri cinque
sorgenti sono nell'[inventario preesistente](../affidabilita/copertura-eccezioni.md),
da confrontare con la nuova misura: i test coprono ora count e misura
di `check-entry-shape` e misura di `sort-participants`, cioè tre
alternative prima non osservate. Le 40 alternative mancanti precedenti
diventano 37; con la nuova alternativa radix sono 38 su 176.

La root ha comunicato una campagna finale con 14 mutanti rilevati,
zero sopravvissuti e zero guasti di compilazione o prima dei test.
Questa lettura non esegue la campagna né riesamina singolarmente
tutti i suoi log: il rapporto di mutazione è un'evidenza distinta.

## Lista di controllo C1 e limiti

La lettura usa lo [standard di codifica](../affidabilita/standard-di-codifica.md)
e il [piano di verifica](../affidabilita/piano-di-verifica.md). I requisiti
richiamati dal sorgente sono contributi locali a REQ-TXM-005,
REQ-TXM-001 e REQ-AFF-008; REQ-VAL-001 identifica la tracciabilità delle
prove; le due costanti richiamano anche REQ-BEN-001 per la scelta
misurata. Il test concorrente contribuisce a REQ-CON-005 senza completare
l'implementazione del runtime parallelo.

| Punto della lista C1 | Stato delimitato |
|---|---|
| Requisiti e ADR | Coerenza locale con ordinamento della tabella e limiti delle risorse; strategia di verifica ADR-0035 e standard ADR-0034. Nessuna modifica al formato persistente o al protocollo 2PC. |
| Invarianti e test | Somme/prefissi, stabilità, ordine unsigned, copia privata e dimensioni analizzati; oracoli indipendenti, caso oltre u16, negazioni delle guardie e confini pubblici presenti. La copertura grezza è distinta dalla copertura delle condizioni. |
| Errori | Guardie locali segnalano `invariant-violation`; il controllo delegato conserva `corruption-detected` con offset per ID duplicato. Errori di tipo restano quelli del contratto con safety 3. La transizione FAULTED appartiene al chiamante del recovery, non è implementata dal sorter. |
| Cicli e attese | Limiti espliciti verificati per tutti i cicli dell'ordinamento. Attese dei test finite; nessuna attesa nel prodotto. |
| Allocazione sul percorso caldo | L'ordinamento è di apertura e alloca scratch/istogramma. Il benchmark letto registra heap senza affermare zero heap; nessuna estensione alle query sul runtime di destinazione. |
| Dati verificati | Il contratto privato richiede copie e entry verificate; controlli di shape e postordine mantenuti. I wrapper non sostituiscono scanner e preflight né decidono presumed abort. |
| Decisioni composte | Due array guard nuove inventariate clausola per clausola; decisione della query preesistente e controlli della fixture esplicitati separatamente. Nessuna attestazione MC/DC. |
| Proprietario e condivisione | Scratch esclusivo della costruzione; tabella completa sola lettura; buffer/output dei lettori esclusivi. Pubblicazione attraverso il futuro runtime non provata dal test. |
| Trace, compilazione, lint e check | Riferimenti e diff ispezionati; termine della baseline isolata letto. Questa lettura non esegue i comandi e non estende tale esito all'ASD della root in corso di modifica. Gli esiti finali restano nei registri dedicati. |
| Deviazioni | Nessuna deroga richiesta dall'ispezione; nessuna esclusione di copertura approvata qui. |
| Parallelismo fra Serie | Nessun nuovo lock, attesa o store condiviso per query; nessun pool per richiesta. Il test non dimostra isolamento o scalabilità del motore rispetto a INV-P6. |
| Atomicità e rimozioni | Nessuna scrittura persistente, flush, rimozione o nuovo punto di atomicità nell'ordinamento o nei wrapper. Contratti di durability preesistenti non riqualificati. |

Questa seconda lettura non esegue la suite; distingue i registri
eseguibili dalla conclusione dell'ispezione. La scelta merge/radix
adottata è stata confrontata con i dati della seconda matrice.
Le passate uniformi risparmiano
scatter ma conservano scansione e verifica dell'istogramma; anche input
0/1 del radix privato alloca workspace e attraversa le cifre. Il
wrapper usa merge sotto soglia; nessun algoritmo viene scelto soltanto
sulla complessità asintotica.

I thread reali non costituiscono esplorazione esaustiva degli
interleaving, simulatore deterministico o misura di scalabilità. Il test
non qualifica il pool riusabile del runtime, la pubblicazione tramite
catalogo, P99, Linux/x86-64, durability o applicazione dei prepared.

L'integrazione e i test congelati sono riletti in questo addendum.
Copertura, mutanti, compilazione, lint e controllo complessivo finali
devono essere collegati ai rispettivi registri sugli stessi hash.
Eventuali ulteriori modifiche richiedono una nuova lettura del diff;
la presente conclusione resta riferita ai soli hash sopra.

## Prima lettura C1 dell'autore sul candidato preliminare

La lettura storica che segue precede l'integrazione dei wrapper.
La [lettura finale dell'autore](decisioni-radix-lettura-autore.md)
identifica gli hash integrati; l'addendum indipendente sopra usa quegli
stessi sorgenti e test congelati.

Lettura del 2026-10-09 dell'agente `/root/segment_header_code`, autore del
candidato. È distinta dalla seconda lettura indipendente conservata
sopra. Il sorgente riletto ha SHA256
`5093e1dda2876d3b31fd5a6e9196dc76bec04aa8a61ce933c63de59f73f36505`;
i test riletti hanno SHA256
`81d22bb4c5ac5375cf0daaa7443011b15a9563007151dd29d91dbfbbdfe9b915`.
Entrambi gli hash sono stati ricontrollati sui file della versione preliminare. Esito:
nessun difetto funzionale individuato nell'ambito del candidato privato.

La lista segue i dodici punti dello
[standard di codifica](../affidabilita/standard-di-codifica.md).
I nomi dei test nella tabella sono quelli dei
[test indipendenti](../../tests/recovery/decisions-radix.lisp).
L'ispezione non esegue processi di verifica durante la campagna delle
misure e non anticipa il relativo risultato o la scelta delle soglie.

| Punto C1 | Riscontro concreto dell'autore e limite |
|---|---|
| 1. Requisiti e ADR | Le otto funzioni riportano REQ-TXM-005, REQ-AFF-008 e REQ-VAL-001; le operazioni sulle entry richiamano anche REQ-TXM-001. La stabilità conserva l'identità fisica a parità di TXID senza introdurre vincoli su CSN, positività o monotonia. Coerenza locale con ADR-0034/0035 e con il contratto della tabella; nessuna modifica al formato o al 2PC. |
| 2. Invarianti e test | `radix-prefix-starts` verifica somma entro N ed esattamente N; gli scatter verificano range e capienze prima degli store; `radix-check-cursors` verifica monotonia e termine N. `radix-entry-cardinalities-patterns-and-stability` confronta ogni riferimento con l'oracolo e gli offset dei TXID uguali; `radix-entry-65536-bucket-counts` rende osservabili conteggi oltre u16. La regressione pubblica del primo conflitto fisico resta necessaria sul builder integrato. |
| 3. Errori e gestione | Le guardie locali segnalano `invariant-violation`; `check-participant-order` conserva `corruption-detected :decision-duplicate-participant` e l'offset del record. I test `radix-participant-shape-before-sort`, `radix-entry-shape-before-sort` e `radix-duplicate-participant-offset` verificano misure, count e offset, incluso u64 massimo. Tipi e allocazioni mantengono anche le condizioni del runtime; il sorter non gestisce il ciclo di vita FAULTED della Serie. Non si dichiara copertura di ogni guardia difensiva. |
| 4. Cicli e attese | Nessuna ricorsione o attesa nel candidato: 16/8 cifre, 256 classi e N elementi effettivi per conteggio e scatter. Il salto uniforme segue il conteggio completo e non ruota i buffer. I test per ogni bit, cardinalità dispari e pattern uniformi esercitano i confini; i timeout dei sei lettori appartengono soltanto all'harness. |
| 5. Allocazioni e percorso caldo | Scratch della lunghezza effettiva e 256 celle u64 sono allocati nella costruzione/apertura, anche per input privati 0/1. Operazioni su u64 possono inoltre allocare nel runtime. Il candidato non è un percorso caldo e non prova zero heap; i test di lettura concorrente non misurano allocazioni o pause del collector. |
| 6. Dati verificati | La misura dei partecipanti precede lo scratch; le entry sono controllate per tipo, count e lunghezza prima di leggere TXID. Prima del ritorno sono verificati ordine e, per ID16, distinzione. Il contratto richiede copie private già decodificate dal builder: scanner, CRC, preflight del payload e budget non vengono sostituiti. Count 0/1 nei test privati non rende valide DECISION pubbliche con meno di due partecipanti. |
| 7. Decisioni composte | Le due guardie degli array sono elencate per clausola come RAD-D01 e RAD-D02 nell'[inventario](decisioni-radix-decisioni.md), insieme ai 17 siti locali di errore e ai controlli delegati. Le negazioni private non esercitate restano nel denominatore delle misure successive; questa lettura non certifica MC/DC né approva esclusioni. |
| 8. Proprietario e condivisione | OWNER/SHARED dichiarano una sola costruzione. Sorgente iniziale e scratch sono privati e possono essere riordinati; lo scatter lascia invariata la sorgente della singola passata e non scrive i campi read-only delle entry. `concurrent-immutable-table-queries` sovrascrive il log prima dei thread, usa buffer e output distinti e ricontrolla la tabella dopo i join. Non prova la pubblicazione attraverso il futuro runtime. |
| 9. Trace, compilazione, lint e check | Prima della campagna l'autore ha compilato il candidato in copia isolata senza warning/style-warning, ottenuto lint su 8 file senza violazioni e superato 1.290 confronti con il merge, oltre al duplicato con offset massimo. Questa prova usa la baseline; gli oracoli indipendenti sono nei test riletti qui. `ftype`, tipi degli array, `safety 3`, docstring, REQ e funzioni entro 60 righe sono presenti. `make check`, trace, copertura e mutanti del diff adottato richiedono le evidenze finali. |
| 10. Deviazioni | Nessuna deroga individuata nell'ambito letto. Le allocazioni sono esplicitamente ammesse nell'apertura e non costituiscono una deroga al requisito dei percorsi caldi. Guardie e controlli dei limiti restano attivi; nessuna promessa di prestazione o esclusione di copertura è concessa dalla revisione. |
| 11. Parallelismo fra Serie | Il candidato non aggiunge lock, attese, pool o store condivisi per operazione di una Serie: modifica soltanto workspace posseduto durante il recovery. Le query preesistenti leggono la tabella immutabile; i sei worker possiedono il proprio output. Il test non dimostra scalabilità, isolamento fra Serie, scheduler o conformità completa a INV-P6 del motore. |
| 12. Atomicità e rimozioni | Nessun I/O, flush, pubblicazione, applicazione di prepared, eliminazione o cambiamento durevole nel candidato. Nessun nuovo punto di atomicità da dichiarare; i contratti di durability e recovery dello scanner restano esterni a questa modifica e non vengono riqualificati. |

Questa prima lettura riguarda il candidato congelato, ancora non
raggiunto dal builder pubblico. La revisione finale dovrà identificare
algoritmi e soglie scelti, rileggere il diff effettivamente integrato e
collegare le regressioni pubbliche agli stessi contenuti verificati.
Non costituisce una qualifica del runtime parallelo, del motore completo,
di P99, zero heap, durability o Linux/x86-64.
")
  (:PATH "docs/implementazione/decisioni-radix-lettura-autore.md" :GIT-BLOB
   "4474e5ced93e129bae0ae13255e2c56363334f20" :TEXT
   "# Prima lettura C1 dell'autore sul diff integrato

Lettura del 2026-10-09 dell'agente `/root/segment_header_code`, autore
dell'algoritmo radix. Esito dell'ispezione: nessun difetto funzionale
individuato nell'integrazione delimitata qui. Questo addendum completa la
[prima lettura del candidato](decisioni-radix-revisione.md#prima-lettura-c1-dellautore-sul-candidato-preliminare)
senza sostituire la seconda lettura indipendente o attestare una qualifica
del motore completo.

## Contenuti riletti e confini

Gli hash SHA256 seguenti sono stati ricontrollati dopo il congelamento
dei 18 test. Identificano contenuti, non commit Git.

| File | SHA256 |
|---|---|
| [`src/recovery/decisions-radix.lisp`](../../src/recovery/decisions-radix.lisp) | `564becba75721f15317b260b9a949eba716e682a9062c4e009d5463040c21e54` |
| [`src/recovery/decisions-build.lisp`](../../src/recovery/decisions-build.lisp) | `be292ec655087a229a1630179876da9e302a6121985ec3141a5e35226885a115` |
| [`tests/recovery/decisions-radix.lisp`](../../tests/recovery/decisions-radix.lisp) | `75296b2de5620afd4f67117445197cb227adb4b9f65203e299ef6a4ee79518c0` |

Il confronto con il candidato congelato
`5093e1dda2876d3b31fd5a6e9196dc76bec04aa8a61ce933c63de59f73f36505`
mostra soltanto il commento iniziale aggiornato, due costanti e due
wrapper aggiunti: gli otto corpi dell'algoritmo restano invariati.
Il builder differisce dalla baseline solo nelle due chiamate ai sorter;
la firma pubblica di `ricostruisci-decisioni` e i suoi valori restituiti
restano invariati. Le registrazioni recovery osservate in
[`arcdocdb.asd`](../../arcdocdb.asd) rispettano l'ordine
`decisions-sort` → `decisions-radix` → `decisions-build`, con
`decisions-radix` fra i test recovery. La lettura riguarda queste
registrazioni, non le altre modifiche concorrenti all'ASD o ai moduli.

`sort-recovery-participants` sceglie merge per `count < 1024` e radix
per `count >= 1024`: il conteggio è quello dei partecipanti del singolo
record, non il totale del log. `sort-recovery-entries` sceglie merge
per meno di 256 entry e radix da 256 incluse. Questa cardinalità conta
le DECISION fisiche, inclusi i duplicati, prima di `collapse-decisions`;
non conta i soli TXID unici. Entrambi i wrapper mantengono i tipi
completi e delegano le precondizioni e i controlli finali ai sorter.

## Scelta misurata e rilettura dei dati

Il [metodo](decisioni-radix-metodo.md) e i
[risultati](decisioni-radix-risultati.md) separano le soglie ID16/TXID e
richiedono rapporto delle mediane radix/merge al massimo 0,90 in tutti
gli scenari misurati con `N >= soglia`. L'autore ha riletto i plists
conservati della matrice a 100 ms con `*read-eval* = nil`, senza `load`
dei dati o nuove misure, e ricalcolato le mediane dai campioni grezzi.

Sono presenti 63 campagne e 63 scenari di selezione. Nei suffissi
adottati, tutte le calibrazioni raggiungono 100 ms e tutti i tre
campioni per algoritmo raggiungono almeno 50 ms con flag di usabilità:
16 scenari ID16 da 1.024 elementi hanno rapporti
`0,131160..0,857956`; 25 scenari TXID da 256 entry hanno rapporti
`0,143755..0,759877`. I rapporti ricalcolati coincidono con la selezione
conservata entro `1e-12`; il processo registrato termina con codice zero
e consistenza delle sorgenti stabile. La prima matrice insufficiente
resta distinta e conservata. Questi riscontri riguardano solo il costo
locale dell'ordinamento, con allocazioni e GC inclusi, sul sistema
misurato: non qualificano P99, zero heap, Linux/x86-64 o il motore.

## Lista di controllo C1 sul percorso adottato

La lista segue i dodici punti dello
[standard di codifica](../affidabilita/standard-di-codifica.md).
L'[inventario](decisioni-radix-decisioni.md) e la
[seconda lettura](decisioni-radix-revisione.md) restano documenti
separati; la presente lettura non anticipa gli esiti delle campagne
finali di copertura e mutazione.

| Punto C1 | Riscontro dell'autore sull'integrazione e limite |
|---|---|
| 1. Requisiti e ADR | I wrapper riportano REQ-TXM-005, REQ-AFF-008 e REQ-VAL-001; quello delle entry anche REQ-TXM-001. Le costanti richiamano REQ-BEN-001. La scelta segue il metodo misurato e preserva il contratto DECISION, in coerenza locale con ADR-0034/0035. Nessun nuovo vincolo su TXID/CSN o formato persistente. |
| 2. Invarianti e test | I controlli di somma, prefisso, posizione, consumo e ordine del radix sono invariati. I test pubblici `public-participant-sort-threshold-boundaries` e `public-entry-sort-threshold-boundaries` esercitano entrambi i lati e l'uguaglianza delle soglie; il test `public-radix-first-physical-conflict-across-groups` verifica l'offset fisico globale, anche se il gruppo numericamente minore viene visitato prima. |
| 3. Errori e gestione | I wrapper non intercettano né trasformano gli errori. Misure/count incoerenti, duplicati di partecipante e conflitti mantengono i controlli delegati; sei test negativi chiamano inoltre le guardie interne per istogramma, oggetto, cifra, array e cursori. Errori di tipo/allocazione del runtime e transizione della Serie a FAULTED restano esterni al sorter. |
| 4. Cicli e attese | Il dispatch aggiunge solo due confronti e chiamate. Restano i limiti di 16/8 passate, 256 classi e N elementi effettivi; nessun ciclo o attesa nuovi. Le attese finite dei sei lettori appartengono alla fixture e non al worker del prodotto. |
| 5. Allocazioni e percorso caldo | Il wrapper non prepara altro workspace; il sorter scelto alloca sul percorso di costruzione/apertura. Scratch e istogramma dipendono dai dati effettivi, non dai budget inutilizzati; anche count 0/1 privati possono allocare. Nessuna promessa o misura zero heap per query o runtime. |
| 6. Dati verificati | Il budget del numero di DECISION precede l'allocazione delle entry; il preflight dei payload e del totale partecipanti precede le copie. `decode-decisions` passa al wrapper una copia ID16 e l'offset assoluto; il wrapper delle entry riceve il vettore privato completo prima del controllo conflitti e della tabella. Nessun risultato parziale viene pubblicato e il buffer del log resta invariato. |
| 7. Decisioni composte | Il diff aggiunge due `if` semplici sui conteggi, senza nuovi predicati booleani composti. I confini sono 1023/1024/1025 e 255/256/257; la soglia stessa percorre radix. Le guardie composte dell'algoritmo restano quelle inventariate. Copertura grezza e criteri C1 finali richiedono i rapporti sul diff adottato. |
| 8. Proprietario e condivisione | I wrapper mantengono l'ownership della costruzione e non esportano vettori. I sorter riordinano soltanto copie private; le entry e la tabella pubblica conservano campi read-only. I test ai confini confrontano anche il log prima/dopo; quello concorrente consulta una tabella già completa dopo la sovrascrittura del log originale. |
| 9. Trace, compilazione, lint e check | I due nuovi wrapper hanno `ftype`, docstring pre/post/errori, REQ e `safety 3` del file; sono entro 60 righe. È stato riletto il log della baseline isolata del revisore: marker `decision-tests-complete 43` con gli ultimi tre test pubblici verdi; il revisore riferisce compilazione rigorosa senza warning. L'autore non ha rieseguito processi pesanti. Trace, lint, `make check`, copertura e mutanti finali sono evidenze distinte da questa lettura. |
| 10. Deviazioni | Nessuna deroga individuata nel diff delimitato. Le soglie sono scelte locali misurate, non limiti di formato; i budget esistenti e le guardie restano attivi. Non viene approvata alcuna esclusione di copertura o estensione delle misure ad altri sistemi. |
| 11. Parallelismo fra Serie | Nessun nuovo lock, parcheggio, pool o store condiviso per operazione della Serie: il lavoro aggiunto riguarda il workspace posseduto del recovery. Le query pubbliche restano scalari e prive di scritture nella tabella. Sei lettori reali verificano risposte/ownership, non isolamento, scheduler o scalabilità del motore rispetto a INV-P6. |
| 12. Atomicità e rimozioni | Il diff non introduce I/O, flush, pubblicazione, applicazione di prepared, eliminazioni o punti di atomicità durevoli. Scanner e protocollo di durability mantengono il proprio contratto, senza essere riqualificati dall'ordinamento adattivo. |

## Regressioni pubbliche e limiti della lettura

I test congelati coprono versione 1 e 2, offset assoluti oltre u32 e
nessuna modifica del log. Per 1023/1024/1025 partecipanti confrontano
DECISION duplicate con lo stesso insieme in ordine inverso, su tre
pattern; per 255/256/257 entry usano TXID distinti e N record duplicati
che producono un solo TXID. Il conflitto globale usa 258 record in tre
lotti, con primo record discordante nel gruppo TXID massimo e un
conflitto successivo nel gruppo zero; l'errore viene verificato due
volte sullo stesso buffer stabile. Gli oracoli privati rimangono
indipendenti dal merge e dal radix e confrontano byte completi e
identità delle entry.

Questa lettura non approva modifiche degli altri moduli o qualificazioni
di rilascio. Le prove finali di integrazione, le metriche grezze di
copertura e mutazione e i relativi tentativi falliti devono essere
conservati sugli stessi hash. Non si promuovono gli spike a runtime e
non si attribuisce a questo lavoro la completa applicazione del
recovery, l'implementazione del pool o la scalabilità fra Serie.
"))
 :LIMITS (:AUTOMATED-PEER-READINGS :NO-HUMAN-REVIEW-OR-MCDC-QUALIFICATION))
