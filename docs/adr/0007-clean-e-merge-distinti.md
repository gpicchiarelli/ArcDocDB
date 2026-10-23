# ADR-0007 — CLEAN e MERGE distinti, copy-on-write

- **Stato:** Accettata
- **Data:** 2026-10-01
- **Rapporto con la specifica:** registra una decisione della specifica («Clean», «Merge»,
  «Politica generale di compaction», «Workflow Clean/Merge», «Compaction parallela»)
- **Riferimenti:** [07 Compaction](../07-compaction.md), INV-C1…INV-C4, INV-C7…INV-C10, INV-R1

## Contesto

Lo storage append-only accumula versioni morte. Recuperare spazio e ridurre la frammentazione
sono due esigenze con urgenze diverse.

## Decisione

- **CLEAN:** 1 segmento → 1 nuovo segmento immutabile con i soli record live/necessari.
- **MERGE:** N segmenti piccoli → 1 nuovo segmento immutabile.
- Entrambe sono copy-on-write: i sorgenti non vengono mai modificati; diventano `OBSOLETE`
  dopo lo swap e si eliminano solo quando nessuno li usa.
- Un segmento con `live = 0` si elimina direttamente; con `live ≈ total` non si tocca.
- Nessun MERGE automatico dopo un CLEAN; un segmento pulito può restare piccolo.
- I segmenti prodotti non hanno requisiti di dimensione e non ricevono mai nuove scritture.
- La compaction è parallelizzabile per segmento e per Serie; nessun worker globale unico.
- Il nuovo segmento diventa visibile solo dopo essere durevole; i reader non vengono bloccati
  globalmente.

## Conseguenze

- Fino allo swap un'operazione interrotta non lascia effetti e si può ripetere.
- Lo spazio si recupera senza dipendere dalla deframmentazione.
- Durante la compaction serve spazio aggiuntivo pari ai dati copiati.
- Il numero di segmenti può crescere (segmenti piccoli non fusi).
- Lo swap deve coordinarsi con il writer della Serie e con gli snapshot.

## Alternative considerate

- *Un'unica operazione di compaction che pulisce e fonde:* più semplice da descrivere, ma lega
  il recupero di spazio a un lavoro più pesante e meno rinviabile.
- *Riutilizzo in-place dello spazio morto:* contrario all'append-only.

## Valutazione

- Rischi: RSK-02 (swap), RSK-08, RSK-10.
- Verifica: SPK-07 (modello swap/reclaim), SPK-06 (interferenza); FI-06…FI-09.
- Aperto: manifest e swap (QA-04, QA-24), soglie (QA-11), tombstone (QA-15).
