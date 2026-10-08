# SPK-06 — prima campagna locale, 2026-10-08

[Valutazione](README.md) · [Metodo e codice](../../spikes/SPK-06-compaction-load/README.md)

> **Proposta** — Modello finito della policy di carico e confronto di copie
> buffered concorrenti a letture. Le due prove sono separate; non attestano
> compaction, durability o rispetto degli obiettivi P99 del database.

## Ambiente ed evidenze

SBCL 2.6.9, `safety 3`, heap dei processi 4 GiB, Apple M4 ARM64,
16 GiB RAM, Darwin 27.0.0. Commit di riferimento `62267c9`, modifiche locali
esplicite, carico esterno e page cache non controllati. I report identificano
prima/dopo i cinque sorgenti dello spike, le due dipendenze pubbliche SPK-05
e l'harness. Check e benchmark finali hanno esito positivo e sorgenti stabili.

- [Controlli integrati](../../spikes/results/2026-10-08/spk06-check.lisp).
- [Benchmark e campioni grezzi](../../spikes/results/2026-10-08/spk06-bench.lisp).
- [Confronto derivato](../../spikes/results/2026-10-08/spk06-comparison.lisp):
  minimo, mediana e massimo delle tre repliche, raggruppate per worker e modalità.
- [Verifica completa](../../spikes/results/2026-10-08/spk06-full-check.lisp):
  `make check` riuscito, sorgenti stabili, nove spike, compilazione senza avvisi,
  test delle fondazioni, storage e scansione recovery, linter e tracciabilità.
- [Errore iniziale di compilazione I/O](../../spikes/results/2026-10-08/spk06-io-compilation-failed.lisp)
  e [compilazione corretta](../../spikes/results/2026-10-08/spk06-io-compilation.lisp).

Il primo errore era una parentesi mancante, rilevata come style-warning;
resta conservato. Il runner finale compila e carica con tutti gli avvisi fatali.
La compilazione intermedia precede l'ultima modifica del layout del report:
sono i check integrati a identificare la variante finale.

## Correttezza osservata

| Ambito | Controllo |
|---|---|
| Carico | Otto casi di soglia, EWMA razionale esatta, basso dopo 10 s continui, reset e ripartenza dei timer |
| MERGE | Sospensione immediata in alto, abbandono a 30 s continui, ripresa in normale; condizioni congiunte e stabilità inclusiva di 50 s, anche dopo recovery |
| CLEAN e quote | Priorità e selezione senza cambiare gli input, CLEAN urgente con un worker, cap del credito e conservazione aritmetica dei token |
| Input invalidi | Dodici campioni invalidi, cinque rifiuti di traccia, limite inclusivo di 256 campioni; nessuna mutazione parziale osservata |
| I/O reale | Quattro modalità su 12 record con due lettori e 96 letture aggregate per caso; CRC, chiave, stamp e consumo del valore verificati |
| Guasti dei worker | Due errori iniettati, nel lettore e nella copia, propagati dopo join; sorgente verificata e risorse rilasciate |
| Copie | Target riaperto dopo close, dimensione e ogni byte confrontati con la sorgente; sorgente verificata prima e dopo la matrice |

Il modello usa campioni ogni 500 ms e EWMA `alpha=1/2`: sono parametri
sperimentali, non una taratura di prodotto. Il clock è iniettato, senza attese
reali o segnali del dispositivo. Le quote del modello e quelle del worker I/O
sono prove distinte. Nessuna nuova scrittura condivisa per record: fd, buffer,
piani e campioni appartengono al singolo worker; la porta comune è al confine
del caso e il resoconto legge i campi solo dopo join.

## Confronto locale

File sintetico immutabile da 16 MiB, 8192 record da 2048 byte; body senza CBOR.
Tre repliche, 1/2 lettori, 32.768 letture casuali aggregate per caso, ordine
alternato di quattro modalità. I **24 casi** completano **786.432 letture
verificate** (1536 MiB) e **18 copie da 16 MiB** (288 MiB).
Il processo dura **21,415561 s**, inclusi compilazione, check, preparazione,
verifiche e serializzazione dei campioni.

Ogni riga riporta la mediana delle tre repliche e, tra parentesi, minimo–massimo.
Il P99 include pread, verifica del record e campionamento del clock; non è
latenza client. Il rapporto usa la baseline della stessa replica e numero
di lettori. La banda osservata comprende CRC e pacing ed è distinta dalla quota.

| Lettori | Copia | P99 durante sovrapposizione, µs | Rapporto P99/baseline | Copia osservata, MiB/s | Letture coperte, min–max |
|---|---|---:|---:|---:|---:|
| 1 | libera | 14 (14–19) | 0,93 (0,88–1,19) | 158,30 (157,51–160,57) | 7696–7974 |
| 1 | quota 16 MiB/s | 15 (15–18) | 1,00 (0,94–1,13) | 11,26 (11,11–11,43) | 32767–32768 |
| 1 | quota 64 MiB/s | 16 (15–16) | 1,00 (0,94–1,07) | 49,16 (48,80–49,21) | 24350–25317 |
| 2 | libera | 15 (14–16) | 1,00 (0,94–1,00) | 159,82 (152,10–161,39) | 15091–16146 |
| 2 | quota 16 MiB/s | 16 (15–16) | 1,00 (1,00–1,07) | 11,41 (11,35–11,45) | 32766–32767 |
| 2 | quota 64 MiB/s | 16 (16–19) | 1,00 (1,00–1,36) | 49,24 (49,22–49,29) | 32767–32768 |

Il P99 della baseline è 16 µs mediano, 15–16 µs con un lettore e 14–16 µs
con due. Tutti i 18 casi con copia hanno campioni nella sovrapposizione;
la copia libera copre solo una parte delle letture. La finestra osservata
comprende le attese del token bucket: non prova I/O attivo in ogni istante.
I campioni grezzi conservano gli inizi e le latenze in tick; le fini si
ricostruiscono come inizio più latenza, nell'ordine dei worker dichiarato.

> **Proposta** — Questi campioni non giustificano un cambio di ADR-0023.
> Rapporti sotto o sopra uno sono confronti locali con carico esterno non
> controllato. Le quote rallentano la copia; non garantiscono un throughput
> minimo né un limite alla latenza delle letture.

## Conseguenze e limiti

RSK-08 resta accettato: il MERGE può non partire sotto carico sostenuto e non
si introduce una soglia di emergenza. RSK-12 riceve evidenza sui confini del
modello, senza attestare stabilità del feedback reale o AIMD del pool.

Il file è appena scritto, piccolo rispetto alla RAM e con cache non controllata.
Mancano Linux x86-64/NVMe, dataset oltre RAM, WAL concorrente, cache fredda,
selezione MVCC, rilocazioni, reclaim e CLEAN/MERGE durevoli. Nessun fsync:
la copia buffered non misura la banda sostenuta del dispositivo. Le syscall
sono bloccanti nei worker; i timeout sono diagnostici, superabili da una syscall
bloccata. Un worker ancora vivo impedisce close e rimozione fino all'uscita.
Le fixture dei casi completati sono state rimosse.
