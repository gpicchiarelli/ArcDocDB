# Decisioni del controllore del pool

Il componente è C3 ([ADR-0031](../adr/0031-software-critico-criteri-e-priorita.md));
la copertura minima è 95% di istruzioni e rami su tutti i sei file di
[`src/scheduler/`](../../src/scheduler/), inclusi gli accessor generati.
Non si deduce MC/DC dalla copertura dei rami. Le decisioni composte sono
elencate comunque per facilitare le due letture.

| Decisione | Condizioni, in ordine | Prova prevista |
|---|---|---|
| `%pool-range` | fixnum; lower ≤ value ≤ upper | tipo non intero, bignum, minimo/massimo validi e fuori intervallo |
| `%pool-direction` shrink | P99 ≥1200; oppure coda <1 e CPU ≤300 | P99 degradato con coda alta; coda vuota con CPU bassa/alta; coda occupata con CPU bassa |
| `%pool-direction` grow | coda ≥queue-high; CPU <700; P99 ≤1000 | soglie inclusive/esclusive e blocco per ciascun segnale |
| aggiornamento reset | primo campione; oppure gap >2×period | primo tick zero/nonzero, gap uguale al limite e un tick oltre |

Tutti i segnali confrontati sono EWMA con scala 256. Le soglie sono una
politica iniziale esplicita e configurabile solo per pressione della coda;
non sono tarate su carichi del database. Le condizioni singole comprendono
owner, intervallo dei campioni, limiti target, clock interno, pending,
direzione, permanenza e clamp. La fault injection è limitata alle due
invarianti controllate e alla direzione privata inattesa.
