# ADR-0002 — La Serie come unità di storage e parallelismo

- **Stato:** Accettata
- **Data:** 2026-10-01
- **Rapporto con la specifica:** registra una decisione della specifica («Architettura
  logica», «Parallelismo»)
- **Riferimenti:** [02 Modello logico](../02-modello-logico.md),
  [10 Concorrenza](../10-concorrenza-e-scheduling.md), INV-W1, INV-P3

## Contesto

Gli obiettivi sono forte parallelismo, bassa latenza di coda e tenuta sotto burst. Serve
un'unità chiara entro cui serializzare e tra cui parallelizzare.

## Decisione

La Serie è l'unità primaria di storage e di parallelismo. Ogni Serie possiede WAL, segmenti e
indici propri, è fisicamente indipendente e opera in parallelo alle altre. L'Archivio è il
livello a cui si coordinano transazioni e snapshot multiserie.

## Conseguenze

- L'isolamento del carico è strutturale: nessun file condiviso sul percorso delle operazioni
  single-Series.
- Recovery e compaction si parallelizzano per Serie.
- Il parallelismo in scrittura si ottiene *tra* Serie, non *dentro* una Serie
  ([ADR-0005](0005-writer-logico-per-serie.md)): un carico concentrato su una sola Serie non
  ne beneficia.
- Le operazioni che attraversano più Serie richiedono un protocollo apposito
  ([ADR-0006](0006-transazioni-multiserie-2pc.md)).
- Restano condivise le risorse di calcolo, la cache, il dispositivo e il GC: vanno governate
  dallo scheduler.

## Alternative considerate

- *Storage unico per Archivio con namespace logici:* un solo log e un solo indice sono punti
  di contesa globali; contrario all'obiettivo di isolamento.
- *Partizionamento automatico per hash dentro la Serie:* aumenterebbe il parallelismo in
  scrittura ma renderebbe multi-partizione anche le transazioni locali. Non previsto.

## Valutazione

- Rischi: RSK-04 (tetto per Serie), RSK-01 (il GC attraversa l'isolamento).
- Verifica: SPK-04; benchmark di burst su una Serie con misura della latenza sulle altre
  (INV-P3).
- Punto di attenzione: molti WAL indipendenti eseguono flush concorrenti sullo stesso
  dispositivo (SPK-03).
