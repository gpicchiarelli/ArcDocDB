# Risultati locali del collegamento worker/Serie

Campagna del 2026-10-11, Apple M4 ARM64, SBCL 2.6.9, safety 3.
Il [contratto](worker-serie.md), il [metodo preregistrato](worker-serie-metodo.md),
l'[inventario completo](worker-serie-decisioni.md) e le
[due letture C1](worker-serie-revisione.md) delimitano gli esiti.
Gli originali leggibili e le prove di conservazione sono nel
[catalogo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/catalogo.lisp).

La base iniziale è `2a0011f9d2bef104b22f7ad1eb86d7e5d60d5e11`.
Il congelamento v3 qualificato incorpora l'hash fino a
`8101eb856cbe9d7540682babb53afb00fde30f70`: tutti i quattro SHA-256 del
bridge coincidono con l'inventario. Il controllo generale incorpora anche
GET fino a `96c0f4f4d6d1f1882723da1b631e78f89e613059`, senza cambiamenti
alle dipendenze execution/Serie o ai quattro sorgenti. Il modulo GET non
chiama il bridge e conserva la propria qualifica aperta.
La successiva [integrazione della PR reader](worker-serie-integrazione.md)
su `65972a4` aggiunge verifiche senza cambiare codice di prodotto; richiede
un nuovo controllo generale, separato dal PASS precedente. Quel controllo
passa con **796 test nominati, due smoke e dieci spike**, nel
[record finale integrato](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/full-check-reader-integration.lisp)
`4000710249-command-34111-0`, `:OK/:STABLE`, exit 0.

## Correttezza e strumenti

Le 26 prove nuove passano con compilazione rigorosa nel
[record finale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/target-final.lisp)
`4000708313-command-79577-0`, `:OK`, `:STABLE`, exit 0. Coprono il tratto
completo, FIFO/identità/span, debito batch, token e capacità, busy prima e
dopo la seconda lease, ordine del rilascio e retry di end, errori originali,
owner estraneo, bypass stale, generazione nulla e quattro finding chiusi.
Thread reali verificano una Serie contesa e due Serie attive contemporaneamente;
queste prove finite non dimostrano fairness o scalabilità.

Il C4 `tools/worker-series-bench.lisp` è compilato interamente con warning e
style-warning fatali; self-test sul FASL e relativi controlli negativi passano
nel [record C4](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/c4-final.lisp)
`4000708361-command-83427-0`. Il caricamento ASDF conserva la sola eccezione
runtime `sb-kernel:redefinition-warning` già documentata da `tools/build.lisp`.
Il SHA-256 del sorgente è
`93db07d3e553b61404926094650a2c0d69d1593017a82c62270cc11ddfb6438c`;
quello del FASL è
`d22c6afc647678d3f807130f66c3664eb78fcecd0694254062aad009731dd019`.

Il primo controllo generale `make check` passa nel
[record originale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/full-check.lisp)
`4000709286-command-15279-0`: `:OK`, `:STABLE`, exit 0, con 632 sorgenti e
documenti invariati nel congelamento finale. Passano 732 test nominati e due
smoke, linter/self-test, runner snapshot/self-test, tracciabilità, link,
conservazione ed evidenze e tutti i dieci esperimenti Fase 0. Il
[master degli esperimenti](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series-spikes-check/report.lisp)
`4000709427-check-16929-0` è `:COMPLETE`; ciascun run ha sorgenti `:STABLE`
ed exit 0 (SPK-07 `:PASS`, gli altri `:OK`). I loro stderr sono vuoti;
lo stderr del comando generale conserva note del compilatore e annunci
del runner, senza warning o style-warning. Il controllo generale successivo
è motivato dalle nuove suite e dal nuovo gate reader incorporati da `main`.
Le due fixture intenzionalmente fallite del self-test snapshot e il loro
report `:PASSED` sono conservati nel
[bundle](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/snapshot-selftest-bundle.lisp).
I documenti aggiornati dopo questo esito e i nuovi cataloghi vengono
controllati separatamente prima della pubblicazione.

## Copertura senza esclusioni

La campagna nativa esegue tutte le 70 prove Series (44 esistenti e 26 nuove),
con [record](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/coverage-process.lisp)
`4000708333-command-80909-0`, `:OK`, `:STABLE`, exit 0. Conserva tutte le
12 righe sb-cover, anche package e tipi; nessuna esclusione approvata.

| File Series | Espressioni colpite / totali | Rami colpiti / totali |
|---|---:|---:|
| events | 288 / 335 | 38 / 46 |
| io-events | 185 / 220 | 23 / 32 |
| ownership | 223 / 279 | 42 / 52 |
| package | 0 / 1 | 0 / 0 |
| publication | 156 / 203 | 16 / 22 |
| query | 65 / 79 | 5 / 6 |
| retirement | 166 / 182 | 14 / 18 |
| types | 75 / 84 | 4 / 10 |
| worker-boundary | 74 / 86 | 18 / 20 |
| worker-package | 0 / 1 | 0 / 0 |
| worker-run | 145 / 161 | 12 / 14 |
| worker-types | 124 / 168 | 19 / 30 |
| **Totale** | **1501 / 1799** | **191 / 250** |
| **Quattro file nuovi** | **343 / 416** | **49 / 64** |

Restano 298 espressioni e 59 rami non colpiti nello scope completo, di cui
73 e 15 nei file nuovi. I percorsi mancanti sono enumerati nell'
[audit](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/coverage-audit-final.lisp);
lo [stato nativo e tutti gli HTML](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/coverage-bundle.lisp)
sono compressi senza perdita, con checksum dei byte originali e rilettura.
Il reader verifica forme/bit/lunghezze e confronta le 12 righe HTML con i dati
nativi. Compilazione completa, self-test negativi e audit finale passano nel
[record](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/coverage-audit-final-process.lisp)
`4000708823-command-7776-0`, con stderr vuoto. Le tre coppie indipendenti
della decisione composta B01 sono descritte nell'inventario; i contatori
sb-cover non attestano MC/DC, revisione umana o copertura completa.

## Allocazione osservata sul percorso seriale

Il [processo benchmark](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/benchmark-process.lisp)
`4000708391-command-85710-0` e i
[dati grezzi](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/benchmark-data.lisp)
sono `:OK` e `:STABLE`; il processo termina con exit 0.
Cinque repliche da 4096 cicli completi,
ciascuna dopo 128 cicli di warmup, usano lo stesso contesto preallocato e
generazioni monotone reali. Il sink indipendente atteso e ottenuto in ogni
campione è 8800256.

| Replica | Byte consed osservati | Tick grezzi (unità/s: 1000000) |
|---|---:|---:|
| 1 | 0 | 5603 |
| 2 | 0 | 5558 |
| 3 | 0 | 5536 |
| 4 | 0 | 5487 |
| 5 | 0 | 5489 |

Il controllo positivo alloca deliberatamente 16 buffer da 1 MiB e rileva
16777472 byte; sink 16777336. Il sink errato 3 invece di 1 viene rifiutato;
clock nullo viene classificato sotto risoluzione; baseline heap 0.
GC, creazione delle fixture, mock I/O e stampa restano fuori misura.
Il SHA-256 del report originale da 49744 byte è
`418eed082f688416298fe28f593ed7282da79e23aaf4dc445b33831072a3eead`.
Questi dati osservano il solo successo seriale locale; non provano heap zero
universale, throughput, P99, fairness, uso I/O reale o prestazioni del pool.

## Tentativi e conservazione

Nessun tentativo viene sostituito dal risultato finale. Nel catalogo:

- `tool-probe-01` conserva il fallimento iniziale di lettura SB-MD5 nel C4;
  `tool-probe-02/03/04` le compilazioni preliminari successive.
- `target-01` conserva il fallimento per WRITER inutilizzato nella fixture;
  `target-02` il successo delle 23 prove preliminari prima di WS-REV-03/04
  e delle nuove regressioni. I due bundle preliminari ne conservano i sorgenti.
- `selftest-01` conserva il fallimento ASDF runtime prima del ripristino della
  politica di caricamento esistente; `c4-argv-probe` un handler CLI malformato
  rifiutato prima di qualsiasi compilazione del file.
- `coverage-audit-process` conserva il primo audit: il reader compila senza
  avvisi e l'audit passa, ma il runner emette due style-warning per chiamate
  anticipate in `-eval`. Il nuovo runner evita quelle chiamate statiche e
  qualifica separatamente compile/FASL/self-test/audit.
- `orchestration-final` conserva anche il wrapper di pubblicazione originale
  e il suo output: un style-warning per il compattatore caricato a runtime,
  seguito da validazione dei byte riuscita. Non è il gate C4 dello strumento.
  Copia e compattazione riusano gli helper di conservazione esistenti;
  descrittore, payload, byte espansi e catalogo vengono riletti e verificati.
- `source-final` conserva i sorgenti del congelamento v3;
  `orchestration` e `orchestration-final` conservano i driver e il reader.
- `source-make-check` conserva i sorgenti e i documenti del congelamento
  integrato finale. Il catalogo degli spike conserva separatamente master,
  dieci record originali e finalizzazione, inclusi payload gzip originali.

Routing, coordinatore Archivio, pool, admission, wake/park e applicazione dei
payload restano da integrare. Nessun gate del motore completo o della Fase 0
viene chiuso da questa campagna locale.
