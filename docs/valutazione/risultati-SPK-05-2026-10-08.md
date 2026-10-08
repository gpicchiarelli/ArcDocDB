# SPK-05 — prima campagna locale, 2026-10-08

[Valutazione](README.md) · [Metodo e codice](../../spikes/SPK-05-segment-read/README.md)

> **Proposta** — Confronto sperimentale di letture da file immutabili sintetici,
> con CRC32C, chiave e stamp verificati. Non attesta commit, visibilità,
> validità CBOR, durability o i target del database.

## Ambiente e prove

SBCL 2.6.9, `safety 3`, heap dei processi 4 GiB, Apple M4 ARM64,
16 GiB RAM; SBCL riporta Darwin 27.0.0. Il commit di riferimento è `eca1ab5`,
con modifiche locali esplicite. Hardware, carico esterno non controllato,
comando e blob dei sorgenti sono nei report. I quattro sorgenti dello spike
e l'harness sono identificati prima/dopo: check e benchmark finali riportano
`:source-consistency :stable`.

- [Controlli finali](../../spikes/results/2026-10-08/spk05-check.lisp).
- [Benchmark finale](../../spikes/results/2026-10-08/spk05-bench.lisp).
- [Verifica completa](../../spikes/results/2026-10-08/spk05-full-check.lisp):
  `make check` riuscito, sorgenti stabili, otto spike e controlli del repository.
- [Prima variante](../../spikes/results/2026-10-08/spk05-bench-initial.lisp) e
  [relativo check](../../spikes/results/2026-10-08/spk05-check-initial.lisp).
- [Seconda variante](../../spikes/results/2026-10-08/spk05-bench-inline-shared-sap.lisp) e
  [relativo check](../../spikes/results/2026-10-08/spk05-check-inline-shared-sap.lisp).
- [Prime iniezioni I/O](../../spikes/results/2026-10-08/spk05-io-first-check.lisp),
  [iniezioni estese](../../spikes/results/2026-10-08/spk05-io-check.lisp) e
  [fixture del record](../../spikes/results/2026-10-08/spk05-record-check.lisp).
- [Errore iniziale di compilazione del record](../../spikes/results/2026-10-08/spk05-record-compilation-failed.lisp).
- [Errore iniziale del controller](../../spikes/results/2026-10-08/spk05-check-compilation-failed.lisp)
  e [diagnostica del processo](../../spikes/results/2026-10-08/spk05-check-compilation-failed-process.lisp).

I due errori iniziali erano parentesi in eccesso. I fallimenti restano
conservati; compilazione e caricamento finali non producono avvisi.

## Correttezza osservata

| Ambito | Controllo ed esito |
|---|---|
| Primitive I/O | 14 gruppi di iniezione: short read/write, offset e SAP crescenti, reset e tetto EINTR, EOF anche parziale, ritorni invalidi, EIO e limiti prima della syscall |
| File reale | 5 casi: apertura esclusiva su file esistente rifiutata, scrittura su fd readonly rifiutata, lettura oltre EOF, mapping troppo lungo, fd chiuso verificato con EBADF |
| Record sintetico | 49 casi, golden CRC32C `123456789`, oracolo bitwise separato, 12.096 byte di payload controllati con ricorrenza indipendente, numeri fino a u32 massimo, offset, troncamenti e corruzioni |
| CRC validi e dati errati | Layout, chiave e stamp alterati con CRC ricalcolati restano rifiutati |
| Worker | Due errori reali, EOF per pread e range incompleto per mmap, propagati dopo join; il file viene verificato integralmente dopo gli errori |
| Letture concorrenti | 4 casi reali sul file da 12 record: 2 worker, casuale/sequenziale, pread/mmap; conteggi e range coerenti |

La fixture usa PUT v2, flag zero, chiave u64 e stamp derivati dal numero
del record. Il body non è CBOR. Il verificatore controlla l'header prima di
interpretare le lunghezze, poi body, chiave e stamp prima di restituire il range.
Il CRC non rende impossibile una corruzione né copre errori con CRC coerente.

## Confronto locale

File di **8192 record da 2048 byte, 16 MiB**. Tre repliche, 1/2/4 worker,
accessi casuali deterministici e scansioni sequenziali disgiunte, ordine dei
due metodi alternato. I **36 casi** completano **294.912 letture verificate**,
576 MiB di record letti; il processo dura **3,897763 s**, inclusi compilazione,
controlli, preparazione e output. I tempi di ogni caso delimitano solo lettura,
verifica e campionamento tra primo avvio e ultima conclusione dei worker.

Throughput mediano delle tre repliche, con intervallo minimo–massimo:

| Accesso | Worker | pread, k record/s | mmap, k record/s |
|---|---:|---:|---:|
| Sequenziale | 1 | 81,3 (77,8–81,7) | 92,2 (88,3–95,3) |
| Sequenziale | 2 | 159,0 (156,0–160,8) | 188,7 (182,6–191,1) |
| Sequenziale | 4 | 307,0 (297,9–324,0) | 365,8 (349,3–369,0) |
| Casuale | 1 | 82,6 (80,7–84,1) | 89,5 (87,9–94,9) |
| Casuale | 2 | 158,6 (150,4–160,4) | 181,7 (179,6–190,2) |
| Casuale | 4 | 300,9 (272,6–305,9) | 367,4 (335,5–402,0) |

Il P99 dei campioni per lettura va da 13 a 20 µs in questi casi finali;
include syscall o accesso al mapping, CRC e due letture del clock.
I tempi sono espressi in secondi, con campioni grezzi in tick SBCL. Non è latenza client né P99 di
servizio sotto carico. La seconda campagna ha una variabilità maggiore
(un P99 locale arriva a 345 µs), conservata senza selezionare solo la variante
più veloce. Il carico esterno non è controllato.

## Allocazioni e varianti

La misura separata usa il solo thread del controller, buffer e piano già
pronti, warmup completo e nessun campione di tempo per operazione. Il delta
`get-bytes-consed` viene letto prima di creare il resoconto.

| Variante | pread, byte su 8192 letture | mmap, byte su 8192 letture |
|---|---:|---:|
| Callback nativo nel loop comune | 131.072 | 0 |
| Call nativo inline, SAP intermedio comune | 131.072 | 0 |
| Call nativo inline, SAP formato nel ramo usato | 0 | 0 |

La seconda variante non risolve l'allocazione. Il codice generato mostra
un oggetto SAP di 16 byte materializzato prima della scelta tra ramo nativo
e callback. Formarlo separatamente nel ramo usato elimina il delta osservato
nel campione finale. Short read, EINTR, budget, controlli di ritorno e
iniezioni restano nel medesimo loop, con `safety 3`.

Un delta nullo riguarda questo kernel e questo campione SBCL; non è una
garanzia sul motore o sugli errori. Le allocazioni della matrice comprendono
avvio dei thread, warmup, controller e join, e sono riportate separatamente.

## Conseguenze e limiti

> **Proposta** — Le primitive richieste sono raggiungibili da Common Lisp,
> e il ciclo pread con verifica non mostra allocazioni nel campione isolato.
> La scelta di prodotto resta pread in buffer riutilizzati (ADR-0017): il
> vantaggio locale del mapping su un file piccolo non giustifica un cambio di ADR.

Il file è appena generato e riletto; dataset e page cache restano piccoli,
senza controllo dell'evizione. Non si misurano GET da NVMe a cache fredda,
dataset oltre RAM, cache propria, perdita di calore dopo CLEAN/MERGE,
memoria trattenuta dalle epoche o page fault iniettati. RSK-10 rimane aperto;
RSK-16 riceve questa evidenza limitata sulle primitive, senza chiudere le
altre primitive o la verifica Linux x86-64.

Ogni worker possiede fd, buffer, piano e campioni. Non esistono scritture
condivise per lettura; mapping readonly e porte del controller riguardano
solo l'esperimento. Le syscall sono bloccanti, esclusivamente nei worker
di questa prova I/O. Timeout e limite di tentativi sono diagnostici:
una syscall bloccata può superarli. Un worker ancora vivo impedisce munmap,
close e rimozione della fixture fino all'uscita del processo. `MAP_PRIVATE`
non protegge da mutazioni esterne o `SIGBUS`; il file resta immutabile per
l'intera prova. Le fixture normali sono state rimosse al termine.
