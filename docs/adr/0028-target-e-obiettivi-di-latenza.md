# ADR-0028 — Target per Serie e aggregati; obiettivi numerici di latenza

- **Stato:** Proposta (richiede conferma dell'autore: fissa obiettivi di prodotto). Rivista il 2026-10-03 in applicazione di [ADR-0031](0031-software-critico-criteri-e-priorita.md).
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

## Revisione 2026-10-03: obiettivi e minimi vincolanti

Con l'affidabilità come fine ultimo ([ADR-0031](0031-software-critico-criteri-e-priorita.md)) i
target della specifica restano **obiettivi** e si aggiungono **minimi vincolanti**: valori
ragionevoli, raggiungibili con tutti i controlli di affidabilità attivi
([ADR-0033](0033-fail-stop-e-integrita-end-to-end.md), [ADR-0034](0034-policy-di-compilazione-e-standard-di-codifica.md)).
Un minimo non raggiunto è un difetto; un obiettivo non raggiunto è un'informazione.

| Operazione (hardware di riferimento) | Obiettivo (specifica) | **Minimo vincolante** |
|---|---|---|
| GET `_id`, cache/indice, aggregato | 1–4 M ops/s | **300 k ops/s** |
| GET `_id`, NVMe, aggregato | 150–600 k ops/s | **50 k ops/s** |
| INSERT `:group`, aggregato (≥ 8 Serie) | 300 k–1 M ops/s | **100 k ops/s** (≥ 25 k per Serie) |
| UPDATE / DELETE, aggregato | 400 k–1,5 M ops/s | **100 k ops/s** |
| Query indicizzata semplice | 500 k–2 M ops/s | **50 k ops/s** |
| Scansione sequenziale | 1–5+ GB/s | **500 MB/s** |
| CLEAN | 0,5–3+ GB/s | **200 MB/s** |
| Transazioni multiserie `:group` | decine–centinaia di migliaia/s | **10 k tx/s** |
| P99 delle operazioni | tabella sopra | **3 × i valori della tabella sopra** |
| Pausa massima del GC (P99.9) | 5 ms | **20 ms** |

I minimi sono proposte: l'autore le conferma o le modifica. Il costo dei controlli è misurato
da SPK-09; i minimi si verificano con benchmark riproducibili (REQ-AFF-012).
