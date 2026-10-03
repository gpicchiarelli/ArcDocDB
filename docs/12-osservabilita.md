# 12 — Osservabilità

> **Fonte:** «Osservabilità» della [specifica](specifica/prompt-originale.md).
> **Moduli:** trasversale (modulo di supporto *metrics*, vedi [16 Moduli](16-moduli.md)).

Le metriche non sono un accessorio: sono l'**ingresso dei controllori** del sistema. Lo
scheduler del thread pool e la low-load policy del MERGE decidono sulla base di questi valori,
e le scelte rinviate ai benchmark (2Q, SIMD) dipendono da essi.

## Metriche richieste

| Area | Metriche | Usate anche da |
|---|---|---|
| Request | throughput; P50, P95, P99, P99.9 | scheduler, low-load policy |
| Storage | segment count; segment size; live/dead ratio; bytes reclaimed; CLEAN throughput; MERGE throughput | selezione dei candidati alla compaction |
| WAL | append throughput; fsync latency; group size; WAL queue depth | scheduler, low-load policy |
| Index | hit rate; lookup latency; rebuild time | — |
| Cache | hit/miss; eviction; occupazione per Serie; scan pollution | decisione CLOCK → 2Q |
| Scheduler | worker count; queue depth; CPU utilization; I/O utilization; compaction concurrency | scheduler, low-load policy |
| GC/SBCL | allocation rate; GC frequency; GC pause; heap usage | valutazione di RSK-01 |

## Requisiti derivati

> **Proposta** — Dalla natura del sistema discendono alcuni requisiti non scritti nella
> specifica:
>
> - **Costo sul hot path.** Le metriche si aggiornano a ogni richiesta: l'aggiornamento non
>   deve allocare né contendere (contatori per worker o per Serie, aggregati in lettura).
> - **Percentili.** P99 e P99.9 richiedono istogrammi a memoria limitata, non la conservazione
>   dei campioni.
> - **Dimensioni.** Le metriche di richiesta, WAL, storage e cache vanno raccolte **per Serie**
>   oltre che aggregate: l'isolamento tra Serie (INV-P3) si verifica solo così.
> - **Finestre.** I controllori leggono valori smussati (EWMA); l'esposizione verso l'esterno
>   può usare finestre diverse.

## Questioni decise

- Esposizione delle metriche: attraverso il protocollo a frame CBOR
  ([ADR-0029](adr/0029-interfacce-protocollo-query-contratto.md)).
- «Scan pollution»: quota di slot inseriti da scansioni ed espulsi senza essere mai riletti
  ([ADR-0025](adr/0025-cache-per-location.md)).
- Utilizzo del dispositivo: banda di flush e letture misurata dal modulo `io` rispetto alla
  banda rilevata all'avvio ([ADR-0023](adr/0023-politiche-di-compaction.md)); la profondità
  della coda di I/O del sistema operativo non è usata dai controllori.
- Affidabilità: stati di salute di Serie e Archivio, segmenti in quarantena, avanzamento dello
  scrubbing, ripieghi del seqlock, Serie in `:async`
  ([ADR-0033](adr/0033-fail-stop-e-integrita-end-to-end.md)).
- Dall'[analisi progettuale](analisi-progettuale.md): CSN in volo e distanza tra CSN e
  orizzonte, attesa alla nascita degli snapshot ([ADR-0038](adr/0038-orizzonte-di-visibilita.md));
  lunghezza di ogni lista di parcheggio ([ADR-0045](adr/0045-modello-di-esecuzione.md));
  divisioni di frammenti e byte per documento dell'indice
  ([ADR-0043](adr/0043-primary-index-a-frammenti.md)); verifiche fallite in cache
  ([ADR-0044](adr/0044-cache-acceleratore-puro.md)); tombstone conservati
  ([ADR-0042](adr/0042-tombstone-e-indice-dei-vivi.md)); oggetti sconosciuti trovati al
  riavvio ([ADR-0036](adr/0036-leggi-di-progetto.md)).
