# 10 — Concorrenza e scheduling

> **Fonte:** «Concorrenza», «Thread pool dinamico», «Compaction scheduler dinamico»,
> «Parallelismo» della [specifica](specifica/prompt-originale.md).
> **Moduli:** M13 Scheduler, M14 Dynamic Thread Pool.
> **Decisioni:** [ADR-0017](adr/0017-piattaforma-e-io.md) (pool CPU e pool I/O),
> [ADR-0019](adr/0019-durability-e-group-commit-pipelined.md) (writer mai bloccato),
> [ADR-0016](adr/0016-epoch-based-reclamation.md) (epoche), [ADR-0023](adr/0023-politiche-di-compaction.md)
> (stato di carico).

## Modello

```
1 writer logico per Serie  +  molti reader concorrenti
```

NON usare:

- un thread permanente per ogni Serie;
- un thread per ogni richiesta;
- un global writer lock.

Serie indipendenti DEVONO poter scrivere in parallelo:

```
client → queue Serie A → Writer A → WAL A
client → queue Serie B → Writer B → WAL B
```

Il writer serializza **solo ciò che deve essere serializzato** all'interno della singola Serie.

> **Proposta** — «Writer logico» senza thread dedicato si realizza come **esecutore seriale**:
> ogni Serie ha una coda di scrittura; quando la coda non è vuota, un worker del pool la prende
> in carico e la svuota a lotti, e nessun altro worker può farlo contemporaneamente. La mutua
> esclusione è sulla coda, non su un thread. Il lotto coincide naturalmente con il gruppo del
> group commit ([04](04-wal-e-durability.md)).

> **Proposta** — «Solo ciò che deve essere serializzato» suggerisce di tenere fuori dal writer
> tutto il lavoro parallelizzabile: parsing, validazione rispetto allo schema, codifica del
> record avvengono nel worker che riceve la richiesta; al writer restano controllo di versione,
> assegnazione dell'ordine, append al WAL/segmento e aggiornamento dell'indice. Da questo
> dipende il tetto di throughput per singola Serie (RSK-04, QA-26).

## Isolamento tra Serie

La Serie è l'unità principale di isolamento del carico (INV-P3). Un burst di letture sulla
Serie A non deve impedire:

- scritture sulla Serie B;
- query sulla Serie C;
- compaction controllata sulla Serie D.

Le risorse effettivamente condivise, e quindi da governare, sono: i worker del pool, la cache
(partizionabile, [09](09-cache.md)), il dispositivo NVMe, la memoria e — in SBCL — il garbage
collector, che ferma tutti i thread (RSK-01).

## Thread pool dinamico

- Pool dinamico di worker thread, **riutilizzati**: non si creano e distruggono thread di
  continuo.
- Lo scheduler adatta il numero di worker in base a:

| Area | Segnali |
|---|---|
| Code | queue depth |
| CPU | utilizzo |
| Richieste | throughput, P50, P95, P99 |
| Serie | numero di Serie attive, distribuzione del carico tra Serie |
| I/O | utilizzo I/O, WAL throughput |
| Compaction | backlog |

Strategia di controllo: **EWMA** (smussare i segnali), **AIMD** (crescita additiva, riduzione
moltiplicativa), **isteresi** (evitare oscillazioni).

Regole indicative:

| Osservazione | Azione |
|---|---|
| coda in crescita + CPU libera | aumentare i worker |
| coda in crescita + CPU satura | non aumentare ciecamente |
| P99 peggiora significativamente | fermare l'espansione o ridurre i worker |
| coda vuota + CPU bassa | ridurre i worker |

Lo stesso scheduler coordina il carico di query, writer, WAL e compaction.

## Compaction Scheduler

Ha limiti **indipendenti** dal request scheduler ([07](07-compaction.md#parallelismo-e-scheduling)).
Ordine di priorità (INV-P4):

```
traffico utente  >  WAL/durability  >  CLEAN necessario  >  MERGE opportunistico
```

## Punti aperti e rischi

- **QA-12** — Definizione operativa di basso/alto carico, condivisa tra scheduler e low-load
  policy del MERGE.
- **QA-16** — Tracciamento dei reader attivi (necessario al reclaim) con costo trascurabile sul
  percorso di lettura.
- **QA-26** — I target di throughput sono per Serie o aggregati?
- **RSK-04** — Tetto del writer singolo; **RSK-12** — stabilità del controllore (molti segnali,
  rischio di oscillazione); **RSK-01** — pause del GC come fonte di contesa globale.
- Le chiamate bloccanti (`fsync`, letture da NVMe) occupano un worker per la loro durata: il
  dimensionamento del pool deve distinguere worker bloccati su I/O da worker che usano CPU
  (QA-19).

## Metriche

Worker count, queue depth, utilizzo CPU e I/O, compaction concurrency
([12 Osservabilità](12-osservabilita.md)).
