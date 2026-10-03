# ADR-0028 — Target per Serie e aggregati; obiettivi numerici di latenza

- **Stato:** Proposta (richiede conferma dell'autore: fissa obiettivi di prodotto)
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-26; precisa «Target preliminari»
- **Riferimenti:** [13 Benchmark](../13-benchmark.md), [stime](../valutazione/stime-ordine-di-grandezza.md)

## Decisione

1. I target di throughput della specifica si intendono **aggregati sull'intero server**, con
   il carico distribuito su almeno 8 Serie. Target **per singola Serie**: almeno 1/4 del
   target aggregato di fascia bassa (es. INSERT group commit ≥ 75k ops/s su una Serie).
2. Obiettivi di latenza sull'hardware di riferimento, misurati lato server con carico al 70 %
   del throughput di fascia bassa:

| Operazione | P99 | P99.9 |
|---|---|---|
| GET da cache/indice | ≤ 1 ms | ≤ 5 ms |
| GET da NVMe | ≤ 2 ms | ≤ 10 ms |
| Scrittura `:async` | ≤ 1 ms | ≤ 5 ms |
| Scrittura `:group` | ≤ flush P99 + 2 ms | ≤ flush P99 + 10 ms |
| Transazione multiserie `:group` | ≤ 2 × flush P99 + 3 ms | ≤ 2 × flush P99 + 15 ms |

3. **Pausa massima del GC** ammessa: 5 ms (P99.9 delle pause) — ne discende il criterio di
   SPK-02.
4. Gli obiettivi valgono **anche durante** CLEAN e con MERGE in corso: è il criterio con cui
   si misura la low-load policy.

## Conseguenze

- Il controllore di carico ([ADR-0023](0023-politiche-di-compaction.md)) ha un riferimento
  numerico per il P99.
- Un risultato di SPK-02 oltre 5 ms di pausa è un segnale di revisione di ADR-0024/ADR-0001.

## Alternative considerate

- *Target per Serie uguali agli aggregati:* incompatibile con un writer per Serie
  ([budget](../valutazione/stime-ordine-di-grandezza.md#budget-del-writer-logico)).
