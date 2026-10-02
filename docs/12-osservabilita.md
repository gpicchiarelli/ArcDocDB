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

## Punti aperti

- Formato e canale di esposizione delle metriche (legato a QA-20, protocollo).
- Definizione precisa di «scan pollution» come metrica misurabile (QA-17).
- Come si misura l'utilizzo di NVMe e la I/O queue depth in modo portabile (QA-19).
