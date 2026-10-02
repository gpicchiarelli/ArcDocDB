# ADR-0006 — Transazioni multiserie 2PC-like con un unico `multiserie.log`

- **Stato:** Accettata
- **Data:** 2026-10-01
- **Rapporto con la specifica:** registra una decisione della specifica («Serie speciale
  Registri», «Transazioni multiserie»)
- **Riferimenti:** [05 Transazioni](../05-transazioni.md), INV-T3, INV-T4, INV-T5, INV-W2

## Contesto

Le Serie sono fisicamente indipendenti e non esiste un WAL globale. Una transazione che
modifica più Serie deve comunque essere atomica, anche attraverso un crash.

## Decisione

- Una transazione che modifica più Serie segue un protocollo equivalente al two-phase commit:
  BEGIN, PREPARE sui partecipanti, flush dei loro WAL, decisione durevole, COMMIT o ABORT,
  applicazione sui partecipanti.
- Tutte le modifiche condividono un unico TXID.
- La decisione è registrata in `Registri/multiserie.log`: un solo file per Archivio, nessun
  file per transazione, group commit dove appropriato.
- La transazione è committed solo quando la decisione COMMIT è durevole in `multiserie.log`.
- In recovery il Recovery Manager legge `multiserie.log`, individua le transazioni preparate o
  incomplete e completa COMMIT o ABORT sui WAL dei partecipanti.

## Conseguenze

- Le transazioni single-Series non pagano nulla.
- Un commit multiserie costa almeno due flush in sequenza.
- Tra PREPARE e decisione i documenti coinvolti hanno una modifica pendente da gestire senza
  fermare il writer della Serie.
- `multiserie.log` è un punto condiviso dell'Archivio e va troncato.

## Alternative considerate

- *WAL globale per le transazioni multiserie:* atomicità con un solo flush, ma reintroduce un
  log di dati condiviso; escluso dalla specifica.
- *Un file per transazione:* escluso dalla specifica.
- *Nessuna transazione multiserie (saga applicative):* non soddisfa il requisito.

## Valutazione

- Rischi: RSK-05, RSK-06.
- Verifica: SPK-07 (modello del protocollo con crash in ogni punto); FI-03, FI-04, FI-05,
  FI-12.
- Aperto: ordine di commit di Archivio (QA-06), stato PREPARED (QA-07), troncamento (QA-08),
  isolamento (QA-09).
