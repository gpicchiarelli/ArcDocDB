# Hash delle chiavi: contratto e metodo C4

Preregistrazione del 2026-10-11 per
[key-hash-bench.lisp](../../tools/key-hash-bench.lisp), secondo COD-60/61
degli [standard di codifica](../affidabilita/standard-di-codifica.md).
Questo documento fissa prove da eseguire soltanto su istruzione del parent,
dopo il freeze dei sorgenti. L'implementazione del driver e la sua compilazione
non costituiscono risultati di performance. Il parent possiede `src/hash` e
l'integrazione ASDF; questo lavoro interessa soltanto il driver e il metodo.

## Algoritmo e API fissata

La fonte normativa è la sezione **XXH64 Algorithm Description** della
[specifica ufficiale xxHash v0.8.3](https://raw.githubusercontent.com/Cyan4973/xxHash/v0.8.3/doc/xxhash_spec.md).
Si usa XXH64 originale: aritmetica modulo 2^64, lane little-endian,
stripe di 32 byte con quattro accumulatori, convergenza, aggiunta della
lunghezza, code da 8/4/1 byte e avalanche finale. Il valore canonico completo
ha ordine big-endian; la API restituisce separatamente le due parole.

```lisp
(arcdocdb.hash64:xxh64 buffer start end seed-high seed-low)
;; => ESATTAMENTE due valori: high u32, low u32
(ftype (function (t t t t t)
                 (values (unsigned-byte 32) (unsigned-byte 32) &optional))
       arcdocdb.hash64:xxh64)
```

`buffer` è un vettore semplice specializzato u8. `start` ed `end` sono
interi fixnum non negativi. Lo span è `[start,end)`, di **0..65535 byte**,
inclusi i due estremi: il vuoto è ammesso dalla primitiva hash. I seed
sono due u32 espliciti; matematicamente `seed = seed-high × 2^32 + seed-low`.
Analogamente il digest è `high × 2^32 + low`. Tutti gli u32 restituiti sono
fixnum immediati su SBCL64. Non si restituiscono un u64 boxed, una lista,
un oggetto risultato o valori aggiuntivi, neppure NIL.

Il percorso di successo non conserva stato e non modifica alcun byte del
buffer. Heap previsto nella finestra seriale: **zero**, senza sottrarre una
baseline. I rifiuti precedono il kernel, nell'ordine seguente:

| Controllo | Condizione e reason |
|---|---|
| Tipo del buffer, tipo/segno/fixnum degli indici, seed u32 | `INVALID-ARGUMENT :hash-arguments` |
| `check-range`: `0 <= start <= end <= length(buffer)` | `INVALID-ARGUMENT :buffer-range` |
| `end - start > 65535`, dopo un range valido | `INVALID-ARGUMENT :hash-span-limit` |

L'FTYPE pubblico accetta cinque `t`: gli argomenti errati raggiungono i
controlli espliciti e la condizione prevista. Il driver verifica l'FTYPE
registrato da SBCL dopo ASDF e usa chiamate generiche nelle fixture negative.

XXH64 è [non crittografico](https://raw.githubusercontent.com/Cyan4973/xxHash/v0.8.3/doc/xxhash_spec.md):
non promette protezione da collisioni intenzionali o input ostili. Il seed
esplicito consente ripetibilità e isolamento del chiamante; generazione,
persistenza, distribuzione e rotazione dei seed del database restano lavoro
futuro. Queste prove non qualificano l'integrazione nel database, il confronto
di chiavi dopo collisioni, throughput DB o prestazioni di storage/NVMe.

## Caricamento, CLI e budget finiti

Prima di **qualsiasi clock**, compresi quelli del sensore, il driver carica
il sistema RUN `arcdocdb` con `asdf:load-asd` e `asdf:load-system :force t`.
Avvisi e fallimenti di compilazione del prodotto causano un errore. Il
processo deve essere SBCL64 senza SB-COVER; la raccolta coverage è disabilitata.
I simboli del prodotto sono risolti con `find-symbol` soltanto dopo il load.
Non viene caricata la suite di test ASDF.

| Invocazione | Lavoro |
|---|---|
| `--self-test DIR/` | Sensore, metriche negative, alias/freeze/rilettura e fixture funzionali cold |
| `--negative-fixture DIR/` | Metrica senza `:completed`; report `:failed`, uscita **1** |
| `--bench DIR/ [--parallel] [count]` | Autoverifica e matrice seriale; con flag anche matrice 1/2/4 worker |

`DIR/` è obbligatoria e deve terminare con `/`. Un percorso relativo è
risolto dalla radice del worktree del driver. `mkdir` crea una directory
esclusiva 0700; un percorso esistente, anche vuoto, viene rifiutato.
`count` è un intero decimale **20000..100000**, default **20000**.
I due argomenti facoltativi del benchmark possono apparire in qualunque
ordine, una sola volta. Nessuna campagna parte senza un modo CLI.

La matrice comprende **0, 1, 7, 8, 16, 31, 32, 33, 64, 256, 1024, 65535**
byte, con seed zero e massimo u64 (`#xffffffff`, `#xffffffff`). Ogni
configurazione ha cinque repliche. I conteggi sono determinati dalla
lunghezza, mai dai tempi osservati:

| Lunghezze | Divisore | Iterazioni con count=20000 | maxIters con count=100000 |
|---|---:|---:|---:|
| 0..64 della matrice | 1 | 20000 | 100000 |
| 256 | 4 | 5000 | 25000 |
| 1024 | 16 | 1250 | 6250 |
| 65535 | 1024 | 20 | 98 |

Formula: `ceiling(count/divisore)`; warmup per replica e worker:
`min(256, iterazioni)`. Il report conserva questi conteggi e i massimi
preregistrati. Il benchmark seriale produce **120** metriche; il parallelo
aggiunge **360** metriche di gruppo, con **840** risultati worker annidati.
Non si aumentano automaticamente le iterazioni quando il clock è poco risoluto.

## Fixture, oracolo e finestre seriali

Ogni replica prepara un buffer semplice lungo `lunghezza+8`, con tre byte
di prefisso e cinque di suffisso: lo span principale parte da offset 3.
Il byte all'indice `i` vale `(131*i + floor(i/251) + 17*worker) mod 256`.
Si conserva una copia dell'intero buffer, incluso il padding.

L'oracolo cold è una traduzione indipendente della specifica in interi CL
generici, con maschere modulo 2^64. Non usa helper né risultati del prodotto.
Può allocare bignum **fuori misura**. Tre anchor statici con seed zero
controllano anche l'oracolo: vuoto `EF46DB3751D8E999`, `a`
`D24EC4F1A98C6E5B`, `abc` `44BC2CF5AD770999`.

L'autoverifica controlla 24 fixture principali, le riprova in ordine
inverso per rilevare stato residuo, esercita 24 span con offset 0/1/8 sulle
lunghezze 0/32/33/65535 e due vettori realmente vuoti. Verifica l'esatto
numero dei valori restituiti con `multiple-value-call`, senza MV-LIST.
Le 26 fixture di rifiuto coprono buffer non semplici/non u8, indici
negativi/frazionari/float/bignum, seed invalidi, range invertiti o fuori
buffer, limite di span e precedenza fra controlli.

Per ogni replica il driver verifica la fixture, esegue warmup, ricontrolla
digest e buffer, effettua GC completo, poi apre la finestra. Una hash reale
per iterazione restituisce due u32, confrontati con le parole attese e
conservati nei sink; il completamento è aggiornato con contatori fixnum.
Il tempo include chiamata, validazione dell'API, confronto e aggiornamento
dei contatori. Nel clock non si creano liste di valori multipli, digest u64
boxed, fixture o rapporti; non si esegue l'oracolo né GC esplicito.

Dopo il clock, il driver ricalcola il digest indipendente sulla copia,
ricontrolla la chiamata e confronta tutti i byte. Il gate seriale esige
heap dell'intero processo **esattamente zero** in tutte le 120 finestre.
Ogni ritorno nel kernel è confrontato: gli errori non possono cancellarsi
in un sink XOR su un numero pari di iterazioni.

## Parallelismo e metriche

Ogni worker possiede buffer, copia, seed, raw e sink distinti. Per il
worker `w`, a partire dalla parola base zero o `#xffffffff`, i seed sono:
`high = base XOR ((w * #x9e3779b1) mod 2^32)` e
`low = base XOR ((w * #x85ebca77) mod 2^32)`. Il worker zero coincide
con la fixture seriale; gli altri hanno byte e seed diversi.

Il main verifica le fixture prima di creare i thread. Ciascun worker
esegue warmup e verifica cold, segnala ready e attende start per al massimo
30 secondi. Un'unica deadline assoluta di 30 secondi limita ready/join
della replica. Un solo GC precede l'apertura del gate. Il cleanup termina
soltanto i thread del driver ancora vivi e limita ogni join a due secondi
(al massimo quattro thread). Errori, readiness e join sono catturati nel
report; il main legge raw soltanto dopo quiescenza. Un timeout rimane un
fallimento anche se il cleanup riesce.

Il contatore `get-bytes-consed` è **globale del processo**. Nel parallelo
lo legge soltanto il main, da prima dello start a dopo i join: include
l'orchestrazione. Nessuna misura heap per worker viene sommata. I tick
locali worker sono diagnostici; le rate di gruppo usano tempo globale,
somma delle chiamate completate e somma dei byte hashati. Il parallelo
non riceve il gate seriale zero heap.

Le metriche schema 1 conservano kind, workload, status, lunghezza, seed,
replica, worker, iterazioni richieste/completate, byte, heap, tick originali,
secondi, qualità temporale, sink/attesi, immutabilità e diagnostica.
`ns/call = secondi * 1e9 / chiamate`; `byte/sec = byte / secondi`.
Per span vuoto i byte sono zero. Con zero tick: `:below-resolution`,
secondi zero e **entrambe le rate NIL**, presenti nello schema.
Non si inventano velocità, non si sottrae la baseline e non si fissano
soglie di prestazione, scaling o p99. Il carico esterno resta incontrollato.

## Sensore, freeze e persistenza

Il sensore impone zero heap su 20000 cicli vuoti. Il controllo positivo
alloca **quattro vettori u8 da 1 MiB**, li trattiene fino alla verifica e
richiede almeno 4194304 byte osservati. Nessun dato del sensore è una
prestazione della hash. Le fixture dello strumento rimuovono ogni campo
obbligatorio, iniettano 12 metriche negative, rifiutano heap positivo al
gate zero e verificano stato fallito/codice 1 su completamento mancante.

`:metrics` esiste dall'inizio. La pubblicazione copia cons e stringhe:
gli alias alla testa del report vedono i nuovi record, ma le modifiche
successive del produttore a sottoliste/stringhe non alterano le copie.
Il report di successo deve avere tutte le identità delle repliche in
ordine, nessun duplicato e conteggi esatti. Un run fallito conserva le
metriche raccolte, anche la metrica deliberatamente incompleta.

Prima della compilazione RUN, il driver fotografa SHA-256 dei sorgenti
ASDF, dell'ASD, del driver, del lettore evidence e di questo metodo; verifica
la stessa fotografia dopo il load e alla fine del run. La fotografia è
nel report. Il parent congela questi sorgenti prima della campagna e
registra i comandi tramite [record-command.lisp](../../tools/record-command.lisp).

`self-test-sensor.lisp` e `report.lisp` sono snapshot scritti **una sola
volta**, con `:if-exists :error`, nella directory esclusiva. Entrambi sono
riletti con [evidence-storage.lisp](../../tools/evidence-storage.lisp),
senza valutare Lisp dai dati, confrontati integralmente e validati di nuovo.
Ogni errore dà una diagnostica con file/regola e uscita non nulla;
un errore di persistenza/rilettura resta un fallimento del processo.
Un'interruzione improvvisa può lasciare una directory senza report finale:
la sua sola esistenza non prova successo.

Comandi preregistrati, **da eseguire soltanto su istruzione del parent**,
dalla radice del worktree, ciascuno con directory nuova:

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script tools/key-hash-bench.lisp --self-test spikes/out/key-hash-self-test/
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script tools/key-hash-bench.lisp --negative-fixture spikes/out/key-hash-bench-negative/
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script tools/key-hash-bench.lisp --bench spikes/out/key-hash-bench-serial/ 20000
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script tools/key-hash-bench.lisp --bench spikes/out/key-hash-bench-parallel/ --parallel 20000
```
