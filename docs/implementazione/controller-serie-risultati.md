# Controller della Serie — risultati locali

Data: 2026-10-09. Prodotto: `arcdocdb.series`, controller della pubblicazione,
risoluzione CSN e ritiro I/O. [Contratto](controller-serie.md),
[metodo](controller-serie-metodo.md), [decisioni](controller-serie-decisioni.md)
e [due letture statiche](controller-serie-revisione.md) delimitano il risultato.

La campagna finale usa `ffa210780d36036572046cc2135486927d11361e`, checkout
pulito e sorgenti stabili prima/dopo ogni invocazione riuscita. Include il merge
`80b4834` con `main` a `e07d772`, preservando inventario recovery e codec CBOR
minimo sviluppati in parallelo. Base del controller: `cf60913`.
Le aggiunte successive a questa campagna sono documenti e prove conservate.

## Correttezza e strumenti

| Verifica | Esito | Registro |
|---|---|---|
| Compilazione rigorosa, suite e controlli generali | 436 test unitari + 2 smoke; 44 test Series, inclusi 6 concorrenti; zero warning/style-warning. Lint su 72 file: zero violazioni. Tracciabilità, link, conservazione e spike di correttezza passano. | [Check integrato](../../spikes/results/2026-10-09-series-controller/4000549590-command-22639-0-report.lisp) |
| Controller: baseline e quattro difetti deliberati | Baseline passa; 4/4 mutanti compilano e falliscono nel test nominato, senza timeout. | [Mutazioni Series](../../spikes/results/2026-10-09-series-controller/series-mutations-02/report.lisp) |
| Regressione del ponte WAL–CSN | Baseline passa; 4/4 mutanti rilevati. | [Mutazioni WAL](../../spikes/results/2026-10-09-series-controller/series-wal-mutations-02/report.lisp) |
| Sensore delle misure | Finestra vuota: 0 byte; controllo positivo: 16 oggetti vivi da 1 MiB, 16.777.472 byte osservati; tempo nullo/negativo, heap nonzero e metrica mancante rifiutati. Campi persistiti e alias della plist verificati. | [Benchmark e self-test](../../spikes/results/2026-10-09-series-controller/series-bench-01-report.lisp) |
| Conservazione della nuova raccolta | 12 controlli positivi/negativi: copie integre, gzip senza perdita oltre 1 MiB, idempotenza, rifiuto della sovrascrittura diversa, link HTML relativi validi e link mancante rifiutato. | [Self-test della raccolta](../../spikes/results/2026-10-09-series-controller/4000548975-command-79587-0-report.lisp) |

I quattro difetti Series eliminano, rispettivamente, il confronto di generazione,
la FIFO di pubblicazione, il divieto di ripetere il CAS dopo busy e il vincolo di
ritiro I/O prima del riuso. Compilazione fallita, timeout o test diverso dal
bersaglio non vengono contati come rilevamento valido. Le copie ricostruibili
dei sorgenti e i FASL sono esclusi dalla pubblicazione; variante concreta,
ricetta, Git SHA, impronte, stdout e stderr sono conservati.

Le prove comprendono full senza adozione parziale, stale/foreign, CSN alto e
carry, H ritardato fra Serie, busy dopo CAS senza ripubblicazione, async con
cursori distinti, write/flush fault, quiescenza prima dell'annullamento, ritiro
di dispatch mai accettato, invarianti delle preflight e uscita nonlocale incerta.
Lease, root immutabile e ritiro I/O ricevono anche prove concorrenti reali.

### Condizioni composte e copertura

| Decisione diretta | Prova discriminante |
|---|---|
| D01, budget factory | `series-invalid-configuration-preserves-wal`: tipo/capacità/offset falsi separati, rifiuto prima di costruire. Default, 1 e 1024 passano nel test dei limiti. |
| D02, capacità e cursori | `series-ring-invalid-capacity-before-indexing` e `series-ring-cursors-fail-separately`: FI su capacità 0/1025 e head/tail/publish-head singolarmente. La capacità invalida è esclusa dalla factory normale e da SLOTS readonly. |
| D03, contatori | `series-ring-counts-fail-separately`: count oltre capacity, unresolved oltre count e active-io oltre count; scope Archivio e grafo conservato. |
| D04, lease | `series-lease-busy-stale-and-single-release` e prova di thread estraneo: tipo, zero, generazione e proprietario distinti. |
| D05, evento | `series-foreign-event-same-generation-and-csn`, `series-false-event-and-invalid-generation-before-mutation`, `series-free-and-stale-preallocated-event-after-wrap`. |
| D06, ordine CSN | `series-csn-after-explicit-truth-pairs`, carry e ordine stretto: high maggiore/minore, high uguale e low maggiore/uguale. |

Nomi abbreviati: i simboli completi nei registri includono prefissi `TEST-REQ-*`.
I casi FI ripristinano la corruzione prima del cleanup della fixture;
il fault resta terminale. Le decisioni WAL delegate mantengono la propria
[matrice](wal-csn-decisioni.md) e ricevono test WAL e Series combinati.

| Perimetro SB-COVER | Espressioni | Rami | Rapporto grezzo |
|---|---:|---:|---|
| Series, 44 test | 1.155 / 1.383 = 83,51% | 141 / 186 = 75,81% | [HTML Series](../../spikes/results/2026-10-09-series-controller/series-coverage-02/cover-index.html) |
| WAL, suite WAL + Series | 1.136 / 1.286 = 88,34% | 162 / 190 = 85,26% | [HTML WAL combinato](../../spikes/results/2026-10-09-series-controller/series-wal-coverage-03/cover-index.html) |

Sono somme dei conteggi grezzi, incluse forme generate e package; i test sono
esclusi dal denominatore. HTML e stato SB-COVER conservano i percorsi originali.
Le percentuali non attestano tutti i percorsi d'interruzione, MC/DC generale,
sicurezza o qualifica del motore. Le sei decisioni dirette hanno casi per
condizione espliciti; questo non estende la conclusione a macro/runtime o
alla totalità delle decisioni delegate.

## Prestazioni del ciclo integrato

Ambiente: Apple M4, 10 CPU logiche, 16 GiB RAM, Darwin 27.0.0, SBCL 2.6.9.
Un ciclo forma un PUT con chiave 16 byte e valore 64 byte, sigilla WAL con CSN,
adotta la radice, avvia I/O, scrive e sincronizza con backend simulato, riceve
fine I/O, pubblica con CAS, risolve e ritira gruppo/lotto/evento. Sono 160 byte
WAL per ciclo. L'oracolo di root, token, frontiere e contatori è nel clock.
Factory, radici preallocate, lease, warmup di 1.024 cicli e raccolta delle
metriche sono fuori dalla finestra seriale. Le finestre parallele hanno anche
un contatore globale separato comprendente avvio e join.

Dieci finestre seriali, cinque per base, 20.000 cicli ciascuna; **0 byte heap
in tutte e dieci**, zero busy/full/retry, tutti gli oracoli finali coerenti.
I tempi sono fra 73.458 e 87.856 tick, con 1.000.000 tick al secondo.

| Base CSN `(high low)` | Mediana cicli/s | Min–max cicli/s |
|---|---:|---:|
| `(0 0)` | 268.622 | 261.185–272.264 |
| `(#x80000000 #xfffffff0)` | 259.041 | 227.645–266.852 |

Nove finestre parallele, tre per numero di worker: ogni worker possiede
controller, log, gruppo, lotto e **Archivio/registro indipendente**.
Il test concorrente separato verifica il registro condiviso; queste misure
non dimostrano scalabilità di più Serie sullo stesso registro di Archivio.

| Worker | Mediana aggregata cicli/s | Min–max | Heap globale avvio/join per replica |
|---:|---:|---:|---:|
| 1 | 265.530 | 258.301–265.904 | 65.520 byte |
| 2 | 446.803 | 439.184–451.493 | 131.040 byte |
| 4 | 789.679 | 782.695–820.462 | 262.080 byte |

Con quattro worker la mediana locale è circa 2,97 volte quella a un worker.
Le finestre dei worker usano lo stesso contatore heap di processo e si
sovrappongono: **non sono sommabili**. L'heap parallelo resta un'osservazione,
non passa per il gate zero del seriale. Anche lo zero seriale è una misura
del sensore SBCL validato, non una prova assoluta di non allocazione.

Il backend non esegue I/O fisico: nessuna prestazione NVMe, durability reale,
latenza client o throughput del database è deducibile da questi numeri.
Carico esterno non controllato, nessuna soglia di throughput di accettazione.
Misure seriali completate prima di creare i worker; nessun altro controllo
del parent o agente di sviluppo eseguito durante la campagna.

## Diagnostiche preservate e spazio

Il [catalogo](../../spikes/results/2026-10-09-series-controller/catalogo.lisp)
include anche i tentativi falliti: prima compilazione fermata dal tipo `null`
del segnalatore d'invariante, CLI del self-test priva di `--output-dir`,
falso positivo lint su keyword `:read`, primo mutante di generazione non
compilabile. Gli strumenti non promuovono queste prove a successi. Nel primo
CLI rifiutato il driver non aveva ancora raccolto l'impronta iniziale e marca
il confronto locale changed; il wrapper osserva sorgenti stabili. Non è una
campagna misurata né un cambio del codice durante una misura.

I registri grandi sono descriptor più gzip verificato senza perdita;
nessun taglio di stdout/stderr o modifica di stringhe serializzate. I file
grezzi associati conservano dimensioni e SHA-256. Il raccoglitore applica
gzip anche al raw oltre 1 MiB e verifica il contenuto decompresso.
Ogni file pubblicato di questa campagna resta sotto 1 MiB; copie/FASL
temporanei vengono rimossi con l'archiviazione del worktree dopo il push.

Il controller è implementato nel perimetro dichiarato. Indice concreto,
registrazione snapshot, pool, conferma client e coordinatore di Archivio
restano lavoro successivo; nessun requisito dell'intero motore è promosso.
