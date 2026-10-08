# ArcDocDB — guida per il lavoro nel repository

## Fase corrente

**Fase 0: definizione architetturale e valutazione.** La definizione è completa (51 ADR,
[architettura](architettura.md), [formati](formati-su-disco.md)) ed è passata da
un'[analisi progettuale](analisi-progettuale.md) (ADR 0036–0045); non si scrive
codice di produzione. ADR-0028 e ADR-0030 sono confermati dall'autore (2026-10-08).
Restano le campagne complete degli [spike](valutazione/piano-spike.md),
compreso il gate v2 di SPK-10,
aggiornando la [valutazione](valutazione/README.md). Vedi la [roadmap](roadmap.md).

Principio operativo: si scrive una volta sola, con la soluzione migliore nota
([principi di ingegneria](principi-di-ingegneria.md)).

## Software critico (ADR-0031)

L'affidabilità è il fine ultimo; le prestazioni sono ragionevoli e subordinate. Regole che
valgono per ogni modifica:

- **Priorità:** integrità dei dati committed › correttezza › comportamento definito nei guasti
  › verificabilità › disponibilità › prestazioni. Mai indebolire un livello alto per uno basso.
- **Mai promettere l'impossibile:** il sistema rende gli errori *rilevabili e dichiarati*, non
  impossibili. Nei documenti si dichiarano sempre i limiti (analisi dei guasti, rischi residui).
- **Tracciabilità:** ogni requisito in `docs/tracciabilita/requisiti.lisp`; dopo una modifica
  `make trace-write` e `make trace`; nel codice `;;; REQ: REQ-…`, nei test l'ID nel nome.
- **Prove e benchmark sempre strutturati:** seguire `docs/valutazione/registro-delle-prove.md`;
  conservare parametri, comando, ambiente, revisione, hash dei sorgenti, risultati, limiti,
  output originale e fallimenti. Usare l'harness degli spike e `make check`; pubblicare
  le evidenze citate in `spikes/results/`, con varianti e formati v1/v2 distinti.
- **Standard di codifica:** `docs/affidabilita/standard-di-codifica.md`; `safety` ≥ 2, nessun
  avviso, nessun `ignore-errors`, `truly-the`, `eval`; `make lint`.
- **Nessun argomento probabilistico o temporale come garanzia** (vedi ADR-0032).
- **Il parallelismo è un principio fondante (ADR-0036, INV-P6):** le Serie non si attendono
  mai; tra Serie nessun lock e nessuna scrittura condivisa per operazione; ciò che è condiviso
  è l'elenco chiuso in [architettura](architettura.md#archivio-coordinamento-minimo).
  Ogni meccanismo dichiara che cosa rende seriale; una voce nuova nell'elenco richiede un ADR.
- **Leggi di progetto (ADR-0036):** ogni operazione durevole ha un solo punto di atomicità
  (SEAL, EDIT, DECISION, documento di catalogo); si prepara in `.tmp`, si decide con un record,
  si completa dopo; nulla si distrugge per assenza; il recovery non tronca. Un meccanismo che
  non discende dalle [leggi](analisi-progettuale.md#le-leggi) richiede un ADR.
- **Deviazioni** solo se registrate e approvate (`docs/affidabilita/deviazioni.md`).

## Fonti di verità, in ordine

1. [docs/specifica/specifica-originale.md](specifica/specifica-originale.md) — non si modifica
   senza un ADR.
2. [docs/adr/](adr/README.md) — possono emendare la specifica, dichiarandolo.
3. [docs/invarianti.md](invarianti.md) — regole `INV-…` inviolabili.
4. Documenti tematici in `docs/`.

## Vincoli

- **Solo Common Lisp** (INV-X3, [ADR-0001](adr/0001-common-lisp-sbcl.md)): nessun C,
  C++, Rust, nemmeno negli spike. Estensioni e contrib di SBCL ammessi.
- Nei documenti, ciò che non viene dalla specifica è marcato `> **Proposta** —`,
  `> **Deciso (… → ADR-nnnn)** —` o `> **Aperto (QA-nn)** —`. Non presentare un'interpretazione come requisito.
- Numeri di prestazione: solo da misure riproducibili, altrimenti sono dichiarati target o
  stime (INV-X2).
- Identificativi (`INV-`, `QA-`, `FI-`, `RSK-`, `SPK-`, `REQ-`, `FM-`, `COD-`, `AP-`, `M01…M18`, `ADR-`) stabili: non si
  rinumerano; una voce chiusa si marca, non si cancella.

## Convenzioni

- Documentazione in italiano. Termini di dominio in italiano anche nel codice (`archivio`,
  `serie`, `documento`, `registri`); termini tecnici consolidati in inglese (WAL, segment,
  snapshot, commit). Vedi il [glossario](glossario.md).
- Una modifica di requisito si propaga nello stesso commit a specifica/ADR, invarianti e
  documenti tematici.
- Gli spike vivono in `spikes/<id>-<nome>/` con un `README.md` che riporta domanda, metodo,
  ambiente e risultato.

## Comandi

Caricare e verificare il sistema:

```bash
make check
```
