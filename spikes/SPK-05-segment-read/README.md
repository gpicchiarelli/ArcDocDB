# SPK-05 — Lettura dei segmenti

> **Proposta** — Esperimento di valutazione con file immutabili sintetici. La
> scelta di prodotto resta `pread` in buffer riutilizzati
> ([ADR-0017](../../docs/adr/0017-piattaforma-e-io.md)); `mmap` è un confronto.

## Domanda e criterio dichiarati prima delle misure

Come cambiano costo, allocazioni osservate e concorrenza tra letture posizionali
e accesso diretto a una mappatura, verificando gli stessi record? Una prova è
accettata solo se ogni lettura verifica CRC32C di header e body, chiave e stamp,
e se short read, EOF, interruzioni e corruzioni producono gli esiti previsti.
Il confronto non chiude i target di GET o scansione, né la granularità della cache.

## Metodo

Common Lisp su SBCL a 64 bit, `safety 3`, senza warning o style-warning.
I moduli separano primitive I/O, fixture/verificatore e controllo della campagna.
Le chiamate POSIX passano dai contrib SBCL e dalla libc tramite `sb-alien`:
nessun codice C del progetto. La cornice sintetica v2 misura 2048 byte: header
24, chiave 8, valore 2016; il valore è un motivo deterministico, senza CBOR.
La verifica del record non attesta commit, visibilità o durability.

Un file esclusivo di 8192 record (16 MiB) viene generato e verificato prima
delle misure. Il controller registra il solo file creato e lo rimuove al termine,
insieme alla directory esclusiva sotto `out/data/`. La mappatura è `PROT_READ`
e `MAP_PRIVATE`, del file intero. Il file non viene modificato né troncato mentre
è aperto: `MAP_PRIVATE` non protegge da scritture esterne o da `SIGBUS` dopo un
troncamento. Questi guasti restano fuori dall'esperimento.

La matrice usa 1, 2 e 4 worker, accessi casuali deterministici e scansioni
sequenziali, tre repliche con ordine dei due metodi alternato. Ogni scansione
partiziona il file in intervalli disgiunti e lo attraversa una volta; il caso
casuale legge lo stesso numero di record e riusa il medesimo piano in entrambi
i metodi. Buffer, piani e campioni sono preallocati per worker. Dopo 32 letture
di warmup, una porta comune avvia il lavoro; durante la lettura non ci sono lock,
contatori o scritture condivisi. Ogni worker possiede buffer, descrittore e
campioni. La mappatura condivisa è in sola lettura.

Il percorso `pread` tiene pinned il buffer durante tutto il ciclo e completa
le letture parziali con offset crescente. Il percorso `mmap` verifica direttamente
il SAP, senza copia del record. Entrambi eseguono lo stesso verificatore SAP;
solo dopo i controlli viene usato il range del valore. Le misure includono
verifica e campionamento del tempo; preparazione, warmup, aggregazione e pulizia
sono separate. I percentili usano il rango superiore sui campioni grezzi.
Il dataset è piccolo e appena scritto: le letture sono influenzate dalla page
cache, senza controllo dell'evizione. Non è una prova su NVMe a cache fredda.

Le allocazioni della matrice sono del processo intero durante avvio, warmup,
letture e join: includono il controller e non sono byte per GET del motore.
Una prova separata esegue il solo ciclo di lettura nel thread del controller,
con buffer, mapping e piano già pronti, senza campioni di tempo per operazione;
riporta il delta osservato da `get-bytes-consed`. Anche un delta nullo riguarda
soltanto quel ciclo, quella versione di SBCL e quel campione.

Ogni ciclo ha un numero finito di passi. Le interruzioni consecutive della
syscall hanno un tetto. Attese alla porta e join hanno timeout di 10 secondi;
una syscall bloccata non è interrompibile da questo budget. Se un worker resta
vivo, mapping, descrittori e file non sono liberati mentre li usa: l'esecuzione
fallisce e il processo termina con risorse ancora possedute.

## Riproduzione e ambiente

Dal repository, con registro strutturato e processi isolati:

```sh
sbcl --script tools/run-spikes.lisp --check SPK-05
sbcl --script tools/run-spikes.lisp --bench SPK-05
```

Default: 8192 record, 1/2/4 worker, due accessi, due metodi, tre repliche,
36 casi. `--check` usa un file di 12 record e iniezioni finite. Nessun parametro
numerico viene interpretato dal reader Lisp. Il runner conserva una sola plist
di esito e un exit code non nullo in caso di errore; FASL separati per processo.
Hardware, OS, versione SBCL, heap configurato, sorgenti e carico osservato sono
registrati dall'harness. I risultati macOS/ARM64 sono locali; la piattaforma di
riferimento Linux x86-64 e un dataset oltre RAM restano da misurare.

## Risultati

La [prima variante](../results/2026-10-08/spk05-bench-initial.lisp) completa i
36 casi e misura 131.072 byte allocati nel ciclo isolato `pread` su 8192 record
(16 B/op), contro zero osservati nel ciclo su mapping. Il risultato iniziale
resta conservato. La [seconda variante](../results/2026-10-08/spk05-bench-inline-shared-sap.lisp)
introduce il ramo nativo inline, ma conserva il SAP intermedio comune al ramo
iniettato: il delta resta 16 B/op. L'ispezione del codice generato trova la
materializzazione di 16 byte prima del ramo. La terza variante forma il SAP
nei due rami separati; le primitive restano iniettabili per i check, con gli
stessi controlli, offset, limite EINTR ed errori. Si ripete la stessa matrice
per verificare il delta; nessun risultato nullo è assunto prima della misura.

La [terza campagna](../results/2026-10-08/spk05-bench.lisp) supera i 36 casi
e osserva delta zero in entrambi i cicli isolati. Il [risultato completo](../../docs/valutazione/risultati-SPK-05-2026-10-08.md)
riporta confronto, fallimenti conservati e limiti. Il [check finale](../results/2026-10-08/spk05-check.lisp)
supera 14 gruppi I/O, 49 casi di record, 5 casi filesystem, due errori worker
e quattro letture concorrenti reali. `out/data/` è vuoto dopo il termine.

Restano fuori
scope indice, cache propria, epoche, migrazione tra pool, prepared/OUTCOME,
compaction, fault di pagina iniettati e crash del sistema. I rischi RSK-10 e
RSK-16 rimangono aperti nelle parti non esercitate.
