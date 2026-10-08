# Affidabilità

[Documentazione](../README.md) · [Tracciabilità](../tracciabilita/README.md) · [Valutazione](../valutazione/README.md)

ArcDocDB è progettato come **software critico**
([ADR-0031](../adr/0031-software-critico-criteri-e-priorita.md)): il fine ultimo è
l'affidabilità, le prestazioni sono ragionevoli e subordinate.

## Documenti

| Documento | Contenuto |
|---|---|
| [Analisi dei guasti](analisi-dei-guasti.md) | Modello dei guasti, FMEA (`FM-…`), rischi residui |
| [Standard di codifica](standard-di-codifica.md) | Regole `COD-…` per tutto il codice di prodotto, con il modo in cui ciascuna è verificata |
| [Piano di verifica](piano-di-verifica.md) | Livelli di verifica, copertura, revisione, criteri di rilascio |
| [Deviazioni](deviazioni.md) | Registro delle deviazioni dallo standard (`DEV-…`) |
| [Tracciabilità](../tracciabilita/README.md) | Requisiti `REQ-…`, matrice generata, controllo automatico |

## Il caso di affidabilità

Struttura dell'argomentazione: un'affermazione di vertice, sotto-affermazioni, e per ciascuna le
evidenze (documenti, test, modelli) che la sostengono. Le evidenze marcate «da produrre»
diventano verdi con il progredire delle fasi; un'affermazione senza evidenza verde non è
dichiarata.

**A0 — Nessun dato committed è perso o corrotto senza che il sistema lo rilevi e lo
dichiari** (ADR-0031 §2a).

| Sotto-affermazione | Argomento | Evidenza |
|---|---|---|
| A1 — Un dato confermato come committed è durevole | scrittura una volta, flush prima della conferma, fail-stop sugli errori | INV-D1, INV-A1, INV-V1; FI-01, FI-02, FI-05; modello SPK-07 *(da produrre)* |
| A2 — Un crash in qualsiasi punto non perde dati e non lascia stati ambigui | lotti sigillati, un punto di atomicità per operazione, coda o corruzione decidibili dal contenuto, recovery idempotente che non tronca e non elimina per assenza | INV-F1…F3, INV-C7…C9, INV-A7, INV-A9…A11; FI-01…FI-13; simulatore *(da produrre)* |
| A3 — Una transazione multiserie è atomica anche con crash | decisione durevole unica, presumed abort, esito nel segmento stesso dei record prepared | INV-T3, INV-T4, INV-V2, INV-S7; FI-03…FI-05, FI-12; modello SPK-07 *(da produrre)* |
| A4 — Un dato rovinato dopo la scrittura viene rilevato prima di essere usato | verifica in lettura, scrubbing, quarantena | INV-A2, INV-A6; corruzione deliberata, fuzzing *(da produrre)* |
| A5 — Nessuna risposta errata silenziosa | verifica end-to-end, controlli di tipo e limiti sempre attivi, errori tipizzati | INV-A2…A4; compilazione senza avvisi, linter *(attivi)* |
| A6 — Letture e scritture concorrenti non osservano stati intermedi | seqlock a 64 bit su una sola tabella concorrente, EBR, writer unico, orizzonte di visibilità per gli snapshot | INV-I1, INV-V3…V5, INV-M1…M5; modello e stress con thread reali *(da produrre)* |
| A9 — Un documento eliminato non riappare e uno vivo non scompare | indice dei soli vivi, ricostruzione per CSN massimo, tombstone scartati solo con il filtro di esistenza | INV-C11; test di proprietà con riavvii e MERGE non adiacenti *(da produrre)* |
| A7 — Ogni requisito è verificato | tracciabilità bidirezionale controllata | INV-A5; `make trace` *(attivo)* |
| A8 — Le risorse non si esauriscono in modo non definito | limiti su tutto, backpressure, attese come parcheggi limitati, indice che cresce un frammento alla volta | INV-A8, INV-P5, INV-I3; test di saturazione *(da produrre)* |

## Che cosa il sistema non promette

- Sopravvivenza alla perdita simultanea di tutti i supporti (serve il backup,
  [ADR-0030](../adr/0030-scope-v1.md)).
- Correttezza se il sistema operativo o il firmware mentono su un flush riuscito
  ([FM-03](analisi-dei-guasti.md#fm-03)).
- Assenza di difetti nel compilatore, nel GC o nel runtime di SBCL: i difetti vengono resi
  *rilevabili* dalla verifica end-to-end ([FM-12](analisi-dei-guasti.md#fm-12)).
- Protezione da un avversario (sicurezza informatica: fuori dallo scope v1).
