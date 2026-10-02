# ADR-0010 — Cache CLOCK, partizionabile per Serie

- **Stato:** Accettata
- **Data:** 2026-10-01
- **Rapporto con la specifica:** registra una decisione della specifica («Cache», «Cache e
  snapshot»)
- **Riferimenti:** [09 Cache](../09-cache.md), INV-M3

## Contesto

La cache sta sul percorso di ogni lettura; deve costare poco in concorrenza e non farsi
svuotare da scansioni o da burst su una singola Serie.

## Decisione

- La cache iniziale usa CLOCK.
- 2Q si valuta solo se i benchmark mostrano scan pollution significativa.
- La cache può essere partizionata per Serie.
- La cache è consapevole della versione/epoch: non restituisce a un reader una versione
  incompatibile con il suo snapshot.
- Read path: request → Serie → snapshot/index → cache → segment.

## Conseguenze

- CLOCK aggiorna un bit in lettura: poco costoso e poco conteso.
- Il partizionamento protegge le Serie tra loro, ma richiede una politica di ripartizione del
  budget.
- La scelta di una politica più sofisticata è rinviata a una misura, che richiede una metrica
  di scan pollution definita.

## Alternative considerate

- *LRU:* aggiornamento della lista a ogni lettura, conteso tra thread.
- *2Q o simili fin dall'inizio:* più resistenti alle scansioni, ma complessità non ancora
  giustificata da misure.

## Valutazione

- Rischi: RSK-10.
- Verifica: SPK-05; benchmark con scansioni concorrenti alle letture puntuali.
- Aperto: granularità, chiave e budget (QA-17); memoria fuori dallo heap gestito (QA-18).
- Proposta collegata: chiave per location, che rende INV-M3 vero per costruzione
  ([09](../09-cache.md#cache-e-snapshot)).
