# ADR-0012 — SIMD solo dove i benchmark lo giustificano

- **Stato:** Accettata
- **Data:** 2026-10-01
- **Rapporto con la specifica:** registra una decisione della specifica («SIMD e
  ottimizzazioni native»), nel quadro di [ADR-0001](0001-common-lisp-sbcl.md)
- **Riferimenti:** [15 Ottimizzazioni native](../15-ottimizzazioni-native.md), INV-X1

## Contesto

Molte operazioni di un database si prestano al SIMD, ma il codice specializzato costa in
portabilità e manutenzione, e ottimizzare prima di misurare porta spesso a ottimizzare il
punto sbagliato.

## Decisione

- Il sistema è progettato per essere SIMD-friendly: strutture compatte, typed arrays,
  dichiarazioni di tipo, poche allocazioni, accessi sequenziali.
- Il SIMD esplicito si introduce solo sui veri hot path, dopo profilazione.
- Candidati: operazioni su bitmap, Bloom filter, scansioni, confronti, filtri, parsing,
  hashing, compressione.
- Per ora gli strumenti ammessi sono Common Lisp tipizzato e le operazioni specifiche di SBCL
  (ADR-0001).

## Conseguenze

- Il layout dei dati si decide subito in funzione di queste ottimizzazioni; le ottimizzazioni
  stesse arrivano dopo.
- Ogni primitiva ottimizzata ha una versione portabile di riferimento, usata anche per
  verificarne la correttezza.
- Serve un'infrastruttura di benchmark prima di qualunque ottimizzazione.

## Alternative considerate

- *SIMD pervasivo fin dall'inizio:* scartato; contrario al principio di misura.
- *Nessun SIMD:* rinuncia a guadagni noti su bitmap e scansioni.

## Valutazione

- Rischi: RSK-11, RSK-16.
- Verifica: SPK-08 (codice generato e strumenti disponibili per architettura).
- Aperto: architettura di riferimento (QA-19).
