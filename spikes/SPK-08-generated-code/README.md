# SPK-08 — Impronte e codice generato

> **Proposta** — Valutazione locale in Common Lisp/SBCL, `safety 3`.
> Le varianti sono esperimenti: nessuna è introdotta nell'indice del motore.

## Domanda e metodo

Quale codice genera SBCL per confrontare 16 ctrl byte con un'impronta a
7 bit, e quale costo resta dopo i controlli dei range? L'esperimento separa
il confronto scalare, due parole u64 con SWAR e il backend SIMD locale.
Ogni risultato è una maschera esatta: un bit per posizione, senza falsi
positivi dovuti al prestito fra byte. I ctrl empty/deleted sono dati del
confronto; lo spike non implementa probing, inserimento o seqlock.

Metodi registrati prima dei controlli e delle misure:

- [Scalar e SWAR](metodo-impronte.md), con oracolo scalare e mutante borrow.
- [SIMD](metodo-simd.md), NEON su ARM64 e ramo SSE2 su x86-64.

I dataset delle due campagne sono distinti e dichiarati nei metodi.
I confronti di tempo valgono soltanto fra metodi sullo stesso dataset e
nella stessa campagna. Un vantaggio sul singolo kernel non è un vantaggio
di throughput per il database.

## Riproduzione e registrazione

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/run-spikes.lisp --check SPK-08
sbcl --noinform --no-userinit --no-sysinit --script tools/run-spikes.lisp --bench SPK-08
```

`run.lisp` compila in nuovi FASL per processo; warning/style-warning e
valori warnings/failure di `compile-file` sono fatali. L'harness conserva
comando, ambiente, revisione, sorgenti prima/dopo, risultati decodificati,
stdout/stderr originali e fallimenti. I report restano in `spikes/out/`;
quelli citati sono conservati in `spikes/results/`.

Il solo modulo nativo può essere eseguito con `run.lisp --simd-check`
o `--simd-bench`, usando `tools/record-command.lisp`. Contrib o backend
assente produce `:unsupported`, senza fingere una verifica SIMD riuscita.

## Ambiente e limiti

Prima piattaforma: Apple M4, macOS ARM64, SBCL 2.6.9, 16 GiB RAM.
Le misure sono eseguite in serie, con carico esterno non controllato.
Nessuna misura su Linux x86-64, dati oltre RAM, accessi concorrenti,
directory dell'indice, seqlock, durabilità o frontiera dei commit.
Il gate SIMD delle due architetture resta aperto fino a verifiche reali.

## Primo controllo locale

Il kernel NEON supera 589.824 confronti: tutte le 65.536 maschere e
128 × 256 × 16 casi di query/ctrl/posizione. Superati anche 16 casi
di input immutato e 4 rifiuti dei parametri. Il disassemblato conservato
mostra load e confronto SIMD.
Il [record iniziale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-08-avanzamento/native-simd-check-initial.lisp)
conserva ambiente, sorgenti e output originale.

## Campagna integrata e benchmark

Il CHECK scalar/SWAR passa 3.035.203 gruppi, 12.140.812 confronti,
77 controlli negativi e 28 witness del mutante. Il
[CHECK integrato](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-08-avanzamento/integrated-check.lisp)
legge anche il risultato SIMD senza caricare i package dei moduli.

Il [benchmark](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-08-avanzamento/spk08-benchmark.lisp)
conclude 70 campioni, cinque repliche/cella, con zero byte consed osservati
nei cicli misurati. Mediane NEON: 2,164 ns/gruppo sul misto, 2,168 su tutti
hit e 2,165 sui byte speciali senza hit. SWAR su u64 già preparati misura
4,745/4,791 ns/gruppo nei propri dataset; packing incluso: 17,319/17,288.
Le matrici SWAR e NEON usano dati diversi: questi numeri non confrontano
le due tecniche fra loro. I risultati completi, la dispersione, il sensore
di allocazione e la raccomandazione sono nel
[resoconto](../../docs/valutazione/risultati-SPK-07-08-2026-10-08.md).

Raccomandazione: misurare tutte le varianti nello stesso layout dell'indice,
con query variabili e accessi concorrenti, prima di scegliere un kernel.

## Estensione sulle bitmap

Il [metodo CRC32C](metodo-crc32c.md) confronta software e istruzioni ARM64
generate in Common Lisp. [Integrazione e risultati di prodotto](../../docs/implementazione/crc32c-arm64.md)
restano distinti dallo spike; il kernel srotolato più lento non è stato scelto.

Il successivo [confronto 16/32 B](metodo-crc32c-unroll32.md) misura anche
64 B e il corpo reale da 4112 B, con coda byte oppure 4/1 B. I
[risultati e il GET completo](../../docs/implementazione/crc32c-unroll32.md)
confermano la scelta del kernel 16 B. Per riprodurre, usare il registro con
`run-crc32c-unroll32.lisp --bench DIRECTORY-NUOVA`; `--self-test` e
`--negative-fixture` verificano il driver, con esito unsupported distinto.

Il [metodo bitmap](metodo-bitmap.md) confronta il conteggio dei bit comuni
in array byte e u64 equivalenti. [Risultati e limiti](../../docs/valutazione/risultati-SPK-08-bitmap-2026-10-08.md):
24 fixture, 30 rifiuti e 90 campioni locali con sink e input immutati verificati.
Il disassemblato distingue il popcount hardware del singolo elemento da
un ciclo vettorizzato. L'harness integrato esegue anche questi controlli;
`run-bitmap.lisp` consente la prova separata tramite il registro dei comandi.

## Confronto sullo stesso buffer e sulla stessa query

`comparison.lisp` aggiunge una campagna distinta: `scalar16`, `packedmask16`
e, quando disponibile, `maschera-simd` ricevono **gli stessi array byte,
offset e query**. Il packing little-endian resta dentro il kernel SWAR.
Le varianti su u64 gia preparati sono escluse dal confronto diretto.
Le prove e misure storiche precedenti restano separate.

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-08-generated-code/run.lisp --compare-check
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-08-generated-code/run.lisp --compare-bench
```

Anche i normali `--check` e `--bench` includono la nuova campagna. Il
benchmark richiede una richiesta esplicita: `--check` non lo esegue.
I kernel restano in Common Lisp/SBCL, `safety 3`, senza VOP o assembly
personalizzati, cambi al prodotto o abbassamento dei controlli.

Il CHECK pianifica 20.560 finestre condivise: tutte le query 0..127 e
gli offset 0..15 su otto pattern; tutti i ctrl ammessi dal prodotto
(0..127, DELETED=254, EMPTY=255) nelle sedici posizioni per query 0/127;
ultimi gruppi che terminano esattamente al confine dell'array. L'oracolo
indipendente somma una potenza di due per ogni byte uguale alla query.
Si confronta l'intero input prima/dopo ogni finestra. Tutti i buffer di
lunghezza 0..15 e tutte le finestre finali spostate di un byte vengono
rifiutati: nessuna coda incompleta viene caricata come vettore.

Sono pianificati anche 56 casi negativi su finestre, buffer non semplici,
tipi, offset e query, attraverso chiamate opache al compilatore e con
immutabilita verificata. Le categorie dei rifiuti sono quelle delle API
esistenti: i kernel scalar/SWAR dichiarano H7, il kernel SIMD dichiara u8
e poi rifiuta 128..255. Non si presume un contratto di errori identico;
un'eventuale promozione dovra precisarlo. Nove fixture negative verificano
il rilevamento di un kernel intenzionalmente errato, della scadenza e dei
limiti di righe, passaggi, warmup, secondi, payload e operazioni.

Limiti CHECK: 100.000 gruppi, 120 secondi predefiniti (massimo 300),
scadenza cooperativa verificata anche dopo la raccolta del disassemblato.
Sono conservati il codice dei kernel effettivi e quello del ciclo condiviso.
Il modulo non legge package SIMD al reader time. Senza contrib/backend
verifica scalar e SWAR, riportando `:scalar-swar-status :ok` e
`:native-status :unsupported`, con stato complessivo `:unsupported`.
Nessuna istruzione non supportata viene invocata; il gate usa il controllo
di backend gia presente in SPK-08.

Il BENCH usa tre dataset (`:mixed`, `:all-hit`, `:special`) di 2.048 righe
predefinite: tutte le 128 query e tutti i 16 offset, con oracoli preparati
prima delle misure. Cinque repliche per metodo/dataset, ordine ruotato
deterministicamente; 32 passaggi misurati e due di warmup. Stesso ciclo e
stessa chiamata indiretta per ogni metodo: **l'overhead della chiamata e
incluso**. Il costo di un eventuale dispatcher del prodotto non e misurato.
Si registrano ordine, checksum u32 verificato, ticks grezzi, operazioni,
ns/gruppo e delta bytes-consed; report, oracoli, CHECK, disassemblato, GC
esplicita e preparazione sono fuori dall'intervallo di ciascun campione.
Un sensore di allocazione osservabile e mantenuto vivo per l'intera misura.
Il delta del contatore globale SBCL puo includere contabilizzazioni differite:
zero significa nessun aumento osservato, non assenza dimostrata di allocazioni.
Il sensore positivo verifica una grande allocazione, non la precisione sulle piccole.

Limiti BENCH: righe 2.048..8.192 a multipli di 2.048, passaggi 1..1.024,
warmup 1..64, cinque repliche, massimo 200 milioni di chiamate misurate e
di warmup complessive, 120 secondi predefiniti (massimo 300), payload
massimo 4 MiB. Il preflight calcola 72 byte/riga per matrice e copie piu
1 MiB per il sensore; le tre matrici sono preparate una alla volta.
Header, strutture dei report, runtime e memoria in attesa del GC non sono
inclusi: questo limite non e RSS. La scadenza e cooperativa, al massimo
8.192 chiamate tra due controlli durante un ciclo. Timer non risolto,
checksum discordante, mutazione o budget esaurito producono fallimento.

Con tre metodi, il default pianifica 45 campioni e 2.985.984 chiamate di
warmup/misura; senza backend SIMD, 30 campioni e 1.990.656 chiamate.
La campagna non qualifica lookup concorrente, ordine di pubblicazione dei
ctrl, barriere, seqlock o throughput del database. Non dichiara vantaggi
prima di misure reali su ciascuna piattaforma prevista.

La [campagna locale del 2026-10-22](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-simd-comparison/README.md)
conserva confronti, misure, tentativi falliti e sorgenti. Il controllo Linux x86-64
passa attraverso il normale `--check` della CI; la sua esecuzione e le misure
su quella piattaforma restano da acquisire in questa campagna.
