# ADR-0003 — WAL per Serie, nessun global data WAL

- **Stato:** Accettata
- **Data:** 2026-10-01
- **Rapporto con la specifica:** registra una decisione della specifica («WAL», «Layout
  fisico»)
- **Riferimenti:** [04 WAL e durability](../04-wal-e-durability.md), INV-W1, INV-W2

## Contesto

Un WAL unico è il modo classico di ottenere durability e un ordine globale, ma è anche un
punto di serializzazione per tutte le scritture del sistema.

## Decisione

Ogni Serie ha un WAL indipendente. Non esiste un WAL dei dati globale. L'unico log condiviso a
livello di Archivio è `Registri/multiserie.log`, che contiene decisioni e non dati. Il sistema
privilegia il group commit, anche su `multiserie.log`.

## Conseguenze

- Le scritture su Serie diverse non si contendono un log.
- Non esiste un ordine globale dei commit: va costruito dove serve (QA-06).
- Il recovery tratta ogni WAL separatamente e in parallelo.
- I flush di più WAL concorrono sullo stesso dispositivo.

## Alternative considerate

- *WAL globale con group commit:* gruppi più grandi e un solo flusso di flush, ma tutte le
  Serie condividono latenza e contesa; esplicitamente escluso dalla specifica.

## Valutazione

- Rischi: RSK-03 (amplificazione, legata a QA-02), RSK-06.
- Verifica: SPK-03 misura il flush con 1…64 WAL concorrenti. Se il dispositivo serializza i
  flush, il vantaggio sul percorso durevole è minore dell'atteso: il dato va riportato qui.
- Aperto: rapporto WAL ↔ segmenti e troncamento (QA-02); livelli di durability (QA-05).
