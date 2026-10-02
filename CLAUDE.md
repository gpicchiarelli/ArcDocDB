# ArcDocDB — guida per il lavoro nel repository

## Fase corrente

**Fase 0: definizione architetturale e valutazione.** Non si scrive codice di produzione. Il
lavoro consiste nel chiudere le [questioni aperte](docs/questioni-aperte.md) con ADR, eseguire
gli [spike](docs/valutazione/piano-spike.md) e tenere aggiornata la
[valutazione](docs/valutazione/README.md). Vedi la [roadmap](docs/roadmap.md).

## Fonti di verità, in ordine

1. [docs/specifica/prompt-originale.md](docs/specifica/prompt-originale.md) — non si modifica
   senza un ADR.
2. [docs/adr/](docs/adr/README.md) — possono emendare la specifica, dichiarandolo.
3. [docs/invarianti.md](docs/invarianti.md) — regole `INV-…` inviolabili.
4. Documenti tematici in `docs/`.

## Vincoli

- **Solo Common Lisp** (INV-X3, [ADR-0001](docs/adr/0001-common-lisp-sbcl.md)): nessun C,
  C++, Rust, nemmeno negli spike. Estensioni e contrib di SBCL ammessi.
- Nei documenti, ciò che non viene dalla specifica è marcato `> **Proposta** —` o
  `> **Aperto (QA-nn)** —`. Non presentare un'interpretazione come requisito.
- Numeri di prestazione: solo da misure riproducibili, altrimenti sono dichiarati target o
  stime (INV-X2).
- Identificativi (`INV-`, `QA-`, `FI-`, `RSK-`, `SPK-`, `M01…M18`, `ADR-`) stabili: non si
  rinumerano; una voce chiusa si marca, non si cancella.

## Convenzioni

- Documentazione in italiano. Termini di dominio in italiano anche nel codice (`archivio`,
  `serie`, `documento`, `registri`); termini tecnici consolidati in inglese (WAL, segment,
  snapshot, commit). Vedi il [glossario](docs/glossario.md).
- Una modifica di requisito si propaga nello stesso commit a specifica/ADR, invarianti e
  documenti tematici.
- Gli spike vivono in `spikes/<id>-<nome>/` con un `README.md` che riporta domanda, metodo,
  ambiente e risultato.

## Comandi

Caricare e verificare il sistema:

```bash
sbcl --non-interactive --eval '(asdf:load-asd (merge-pathnames "arcdocdb.asd" (uiop:getcwd)))' --eval '(asdf:test-system "arcdocdb")'
```
