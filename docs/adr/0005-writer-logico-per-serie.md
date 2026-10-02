# ADR-0005 — Un writer logico per Serie con controllo ottimistico

- **Stato:** Accettata
- **Data:** 2026-10-01
- **Rapporto con la specifica:** registra una decisione della specifica («Concorrenza»,
  «Transazioni single-series»)
- **Riferimenti:** [10 Concorrenza](../10-concorrenza-e-scheduling.md),
  [05 Transazioni](../05-transazioni.md), INV-P1, INV-P2, INV-T1, INV-T2

## Contesto

Le scritture su una Serie devono essere ordinate (WAL, versioni) e i conflitti sullo stesso
documento rilevati, senza lock globali e senza un thread per Serie o per richiesta.

## Decisione

- Ogni Serie ha un solo writer logico e molti reader concorrenti.
- Il writer non è un thread dedicato: è un ruolo eseguito da worker del pool.
- Il writer serializza solo ciò che deve essere serializzato nella Serie.
- Le transazioni single-Series usano solo il WAL della Serie e rilevano i conflitti con
  optimistic version checking; il controllo della versione attesa è atomico rispetto
  all'applicazione della modifica.
- Nessun global writer lock.

## Conseguenze

- Nessun lock per documento: «verifica e applica» nel writer è atomico per costruzione.
- La Serie ha un ordine totale delle modifiche, che coincide con l'ordine del WAL.
- Il throughput di scrittura di una Serie è limitato dalla parte seriale: tutto il lavoro
  parallelizzabile deve restare fuori dal writer.
- I conflitti si pagano con abort/retry: carichi con forte contesa sullo stesso documento
  sprecano lavoro.
- Il writer non può attendere eventi esterni senza fermare la Serie (rilevante per il 2PC,
  QA-07).

## Alternative considerate

- *Più writer con lock per documento:* maggiore parallelismo dentro la Serie, al costo di
  lock, deadlock e ordine del WAL da coordinare.
- *Thread dedicato per Serie:* semplice, ma escluso dalla specifica (non scala con il numero
  di Serie).

## Valutazione

- Rischi: RSK-04.
- Verifica: SPK-04; [budget](../valutazione/stime-ordine-di-grandezza.md#budget-del-writer-logico).
- Aperto: livello di isolamento (QA-09); target per Serie o aggregati (QA-26).
