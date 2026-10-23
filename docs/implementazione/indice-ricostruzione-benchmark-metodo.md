# Metodo del benchmark di ricostruzione dell'indice v2

Preregistrazione C4 del 2026-10-09 per
[index-rebuild-bench.lisp](../../tools/index-rebuild-bench.lisp), secondo
[standard di codifica](../affidabilita/standard-di-codifica.md), COD-60/61.
Ambito: primitive dell'[indice primario](indice-primario.md) e dei
[payload v2](slot-indice-v2.md); REQ-IDX-003/005/007, REQ-BEN-001/002,
REQ-VAL-001. Il metodo descrive prove da eseguire dopo il freeze del parent.
La scrittura del driver non costituisce un risultato sperimentale.

## Caricamento e modi

Il driver carica `arcdocdb` tramite `asdf:load-asd` e `asdf:load-system`,
con compilazione forzata e avvisi del prodotto trattati come errori.
La definizione ASDF deve già includere i moduli `rebuild*.lisp` e
l'esportazione di `ricostruisci-frammento-indice`. Il driver risolve le
funzioni prima delle finestre e usa le implementazioni reali.

| Modo | Lavoro |
|---|---|
| `--self-test` | Sensore di heap, persistenza/alias, fixture funzionali e negative bounded. |
| `--bench` | Autoverifica, lookup seriale e ricostruzione/split con costi distinti. |
| `--parallel` | Autoverifica, lookup su 1/2/4 indici indipendenti. |
| `--negative-fixture` | Metrica deliberatamente incompleta: rapporto `:failed`, uscita 1. |

Ogni modo accetta una directory nuova facoltativa. `--bench` e
`--parallel` accettano poi `20000` oppure `100000`; default 20.000,
cinque repliche in entrambe le campagne. Senza directory esplicita il
driver crea un percorso nuovo sotto `spikes/out/`, con timestamp e PID.
Un percorso esistente è rifiutato. Nessuna prova parte senza un modo CLI.

## Fixture e associazione dei digest

Ogni indice, contesto, chiave, payload atteso e output di cinque u64 è
privato. Le chiavi binarie sono inserite in ordine inverso. La prima
chiave riceve un upsert con CSN strettamente maggiore e location nuova;
l'ultima viene cancellata, conservando il suo spazio nell'arena sorgente.
L'oracolo verifica hit, miss della chiave cancellata, cinque campi v2 e
byte dell'arena, prima e dopo le fasi. L'offset locale della chiave può
cambiare con la compattazione; lunghezza, flag e riservati devono coincidere.

Per la lookup ogni chiave distinta ha H2 distinto (massimo 96 chiavi).
Il low u32 sceglie anche gruppi allineati di 16; evita che un hit stabile
consumi il budget di otto candidati a causa delle collisioni della fixture.
Questa distribuzione è favorevole e intenzionale. I digest sono dati
fidati del chiamante, uguali per lookup, mutazioni e ricostruzione; non
qualificano una funzione hash o la resistenza a input ostili.

`source-digests` crea due array specializzati u32 di lunghezza **C**.
Per ogni chiave viva invoca `sonda-writer` sul sorgente attuale, controlla
found/range/unicità e scrive high/low allo **slot originale trovato**.
La fixture esige almeno una differenza tra slot e ordinale della chiave.
Le posizioni EMPTY/DELETED restano zero; non sono chiavi da copiare.
Nessuno slot locale viene riutilizzato dopo la pubblicazione del piano.

Per misurare directory maggiori il setup effettua al più quattro split
vuoti lungo il prefisso zero. Ogni split compatta l'arena vuota a un
byte: dopo il setup `estendi-arena-indice` porta l'arena del sorgente
corrente a `count × key-size`, prima degli inserimenti e fuori misura.
I bit high delle chiavi appartengono al prefisso zero corrente e dividono
i futuri figli secondo il bit successivo. Gli indici condividono frammenti
soltanto entro la propria directory.

## Lookup seriale e gate dello heap

Quattro casi: hit/miss × CSN basso/alto. Fixture C=128, 96 chiavi di 16
byte prima della cancellazione. CSN iniziali 17 e `#xfffffffffffffff0`;
location della fascia alta `#xfedcba9800000040`. L'upsert incrementa il
CSN di uno e l'offset di 64. Gli u64 alti sono creati prima delle misure.

Ogni replica ha 256 lookup di warmup, poi GC completo, quindi 20.000 o
100.000 lookup. La finestra contiene una lookup per iterazione, selezione
del cursore, controllo dello status e aggiornamento dei contatori fixnum
preallocati. Nessun upsert, rebuild, hashing, verifica dei campi u64,
scrittura di rapporti o GC esplicito fa parte della finestra. I controlli
del payload e dell'ultimo output effettivamente misurato avvengono dopo.
Sul miss l'output deve conservare la sentinella u64.

`get-bytes-consed` è un contatore dell'intero processo. Tutte le finestre
seriali di hit e miss, in entrambe le fasce CSN, devono avere differenza
zero. È un gate sperimentale del percorso di successo e del sensore;
non è una prova assoluta di assenza di allocazione in ogni interleaving.
Non si sottrae una baseline dallo heap o dal tempo.

Il rapporto conserva iterazioni richieste/completate, sink, heap,
tick originali, secondi, qualità del tempo e operazioni al secondo.
Il sink e il completamento devono coincidere con le iterazioni. Zero tick
è `:below-resolution`, secondi zero e rate NIL; non viene inventata una
velocità e non è prevista una soglia minima di prestazione.

## Ricostruzione e pubblicazione

Cinque repliche, rebuild e split per ciascuna configurazione:

| C | Chiavi iniziali | Byte per chiave | Profondità iniziale |
|---:|---:|---:|---:|
| 16 | 12 | 16 | 0 |
| 128 | 96 | 16 | 2 |
| 1024 | 96 | 1024 | 4 |
| 128 | 96 | 65535 | 0 |

Ogni replica usa una fixture nuova con CSN alto. La preparazione misura
solo `ricostruisci-frammento-indice(index, source, highs, lows, budget,
:split-p …)`, con budget transitorio 32 MiB. I cinque ritorni sono piano,
C, byte delle chiavi vive copiate, nuovi riferimenti directory e payload
transitorio. Prima della pubblicazione il driver verifica che il piano
sia PREPARED, che la root sia ancora quella originale e che i quattro
contatori coincidano con l'oracolo aritmetico della fixture.

`pubblica-directory-indice(plan)` viene chiamata e cronometrata
separatamente. Il driver controlla stato PUBLISHED, dimensione della nuova
directory e fedeltà di tutte le lookup. Il tempo della preparazione e
`:publication-raw-ticks` restano distinti; il rapporto conserva anche lo
heap osservato della preparazione, senza gate zero per la manutenzione.

`:source-slots = C` denota la capacità distinta del sorgente.
`:full-source-passes = 3` indica le scansioni complete di misura, copia e
verifica; `:probe-bound-per-call = C` è il limite di ogni sondaggio writer.
Non si dichiara che il totale effettivo di visite sia C: si aggiungono i
sondaggi e i confronti di chiavi, il cui costo dipende dalla distribuzione.
Il numero di visite non viene strumentato dentro le primitive.

L'oracolo transitorio somma vecchia directory, frammenti distinti correnti
(41×C più arena), candidati (41×C ciascuno più chiavi vive) e nuova directory
(8×riferimenti). Non include header degli oggetti, buffer fissi, array di
digest, root trattenute da altri chiamanti, garbage o runtime. I contatori
descrivono payload locali; non stimano RSS o un tetto globale del controller.

## Parallelismo e completamento

1, 2 e 4 worker, per entrambe le fasce CSN e cinque repliche. Ogni worker
esegue hit sul proprio indice v2, contesto e output. Il main verifica tutte
le fixture prima dello start, attende il warmup tramite semaforo ed effettua
un solo GC prima di aprire il gate. Una deadline assoluta di 30 secondi
limita ready/join; anche l'attesa di start del worker è limitata a 30 secondi.
Il cleanup termina i soli thread del driver ancora vivi e ha join di due
secondi per thread, al massimo quattro thread.

Ogni worker deve completare il numero previsto, restituire lo status giusto
e superare l'oracolo dell'ultimo output e della fixture. Tutti gli errori
raccolti e gli esiti incompleti restano nel rapporto; un errore rende il run
fallito. Il main legge i contatori di un worker soltanto quando il thread
è terminato. La finestra del processo include apertura del gate e join.
Le finestre `get-bytes-consed` dei worker si sovrappongono: sono osservative,
non vengono sommate e non ricevono il gate seriale zero heap.

## Autoverifica, persistenza e registrazione

Il sensore esegue 20.000 cicli vuoti e pretende heap zero, poi alloca quattro
array di un MiB, li trattiene e verifica che il contatore osservi almeno
quattro MiB. Rifiuta metriche mancanti, completamento/sink errati,
tick/secondi/rate incoerenti e heap positivo al gate zero. Il confine del
driver è esercitato con una metrica priva di `:completed`: esige stato
`:failed` e codice di uscita 1. `--negative-fixture` permette al parent di
verificare anche lo stato reale del processo per la stessa regressione.

Le fixture reali bounded esercitano entrambi i CSN con rebuild/split,
array di digest della lunghezza errata, budget insufficiente, fingerprint
errato su uno slot effettivamente vivo e riuso di un piano pubblicato.
I rifiuti preflight devono lasciare root e salute intatte. Questa verifica
C4 non sostituisce la suite C1, le interruzioni o la copertura delle decisioni.

`:metrics` esiste fin dalla creazione del report. Ogni metrica viene
pubblicata come copia della lista e delle sottoliste; il produttore non
modifica stringhe di diagnostica già pubblicate. Il controllo di alias
mantiene un secondo riferimento alla testa del report, cambia la metrica
originale dopo la copia e verifica che i dati pubblicati siano intatti.
I rapporti e `self-test-sensor.lisp` vengono riletti con
[evidence-storage.lisp](../../tools/evidence-storage.lisp), senza valutare
Lisp dai dati; l'uguaglianza richiesta comprende tutte le metriche.

Dopo il freeze, il parent registra ciascun comando con
[record-command.lisp](../../tools/record-command.lisp), usando percorsi
espliciti diversi per ogni run. Esempi preregistrati, da eseguire dal worktree:

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script tools/index-rebuild-bench.lisp --self-test spikes/out/frozen-index-self-test/
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script tools/index-rebuild-bench.lisp --negative-fixture spikes/out/frozen-index-negative/
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script tools/index-rebuild-bench.lisp --bench spikes/out/frozen-index-bench/ 20000
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script tools/index-rebuild-bench.lisp --parallel spikes/out/frozen-index-parallel/ 20000
```

Il comando negativo deve produrre un record fallito con exit-code 1:
è il rilevamento atteso della fixture, da conservare con stdout/stderr.
Il collector deve leggere i percorsi espliciti `report.lisp` e
`self-test-sensor.lisp` tramite evidence-storage, anche dopo eventuale
compattazione esterna. I record di record-command conservano ambiente,
sorgenti prima/dopo e stato reale del processo.

Le misure riguardano primitive in memoria. Non attestano GET integrato,
snapshot/retention, WAL, commit, recovery, latenza client, throughput del
database, I/O o NVMe. Il carico esterno resta incontrollato e le campagne
si svolgono in sequenza. Nessun risultato è stato eseguito durante questa
implementazione; ogni affermazione quantitativa richiede i record del parent.
