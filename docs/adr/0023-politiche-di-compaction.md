# ADR-0023 — Politiche di compaction: soglie, stati di carico, tombstone

- **Stato:** Accettata (valori di default tarabili dai benchmark); **sezione «Tombstone» sostituita da [ADR-0042](0042-tombstone-e-indice-dei-vivi.md)** (la regola per lineage non è sicura). Soglie, stati di carico e limitatore restano.
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-11, QA-12 e QA-15; realizza [ADR-0007](0007-clean-e-merge-distinti.md) e [ADR-0008](0008-merge-opportunistico.md)
- **Riferimenti:** [architettura](../architettura.md#compaction), INV-C5, INV-C6, INV-P4

## Decisione

### Selezione dei candidati (per Serie, parametri configurabili)

| Regola | Default |
|---|---|
| CLEAN se `dead-bytes / total-bytes ≥ clean-ratio` | 0,5 |
| …oppure se `dead-bytes ≥ clean-min-dead` | 64 MB |
| Priorità del CLEAN | per `dead-bytes` decrescenti |
| Un segmento è «piccolo» se `total-bytes < small-ratio × target` | 0,25 (64 MB con target 256 MB) |
| MERGE se esistono `≥ merge-min-group` segmenti piccoli ammissibili | 8 |
| Dimensione massima dell'output di un MERGE | target della Serie (256 MB) |
| Stabilità minima per MERGE | 50 s (INV-C5, non riducibile) |

I contatori `dead-bytes` sono aggiornati dal writer a ogni sovrascrittura/tombstone (sono
derivati; vengono ricalcolati al riavvio dagli hint).

### Stato di carico

Lo scheduler mantiene uno **stato di carico** dell'Archivio in `{basso, normale, alto}`,
calcolato da due segnali smussati con EWMA (finestra ~1 s):

- `P99` delle richieste rispetto all'obiettivo ([ADR-0028](0028-target-e-obiettivi-di-latenza.md));
- utilizzo del dispositivo (banda usata dai flush e dalle letture rispetto a quella misurata).

Soglie con isteresi: `alto` se uno dei due supera l'80 % dell'obiettivo; `basso` se entrambi
sono sotto il 40 % per almeno 10 s; `normale` altrimenti. I segnali aggiuntivi elencati dalla
specifica (code, worker, backlog) sono esposti come metriche e usati dal controllore dei
worker; entrano nello stato di carico solo se una misura mostra che i due segnali non
bastano.

| Stato | CLEAN | MERGE |
|---|---|---|
| basso | fino a `clean-workers-max` | ammesso, fino a `merge-workers-max` |
| normale | fino a `clean-workers-normal` | nessun nuovo MERGE; quelli in corso proseguono con banda ridotta |
| alto | solo CLEAN urgenti (`dead-ratio ≥ 0,8`), 1 worker | nessun nuovo MERGE; quelli in corso sono sospesi, e abbandonati se lo stato resta `alto` per 30 s |

Ogni worker di compaction ha un **limitatore di banda** (token bucket in byte/s) impostato
dallo scheduler in base allo stato. Un MERGE abbandonato non lascia effetti (sorgenti
intatti, output `.tmp` eliminato).

**Starvation del MERGE:** accettata per specifica. Metrica `segments-small-pending` e
allarme oltre una soglia configurabile. Nessuna soglia di emergenza.

### Tombstone

Ogni segmento ha `lineage-min` = il più piccolo segment-id tra i suoi antenati (se stesso
per i segmenti del writer). Un tombstone per la chiave `k` in un segmento con lineage `L`
può essere scartato dal CLEAN/MERGE quando **nessun segmento presente ha `lineage-min < L`**
e nessuno snapshot attivo lo richiede. In tal caso nessuna versione più vecchia di `k` può
riapparire da una ricostruzione dell'indice.

Pattern: compaction a soglia di spazio morto (Bitcask `dead_bytes_threshold`); limitatore di
banda (RocksDB `RateLimiter`); regola dei tombstone per lineage (Bitcask merge).

## Conseguenze

- Il CLEAN parte dallo spazio morto misurato, non dal numero di segmenti.
- Il MERGE dipende da uno stato esplicito e osservabile; ogni transizione è una metrica.
- I valori sono default: SPK-06 e i benchmark li tarano senza cambiare il meccanismo.

## Valutazione

- Verifica: SPK-06; benchmark di interferenza; test della macchina a stati del carico su
  tracce.
