# ADR-0016 — Epoch-based reclamation per segmenti, tabelle e indici ritirati

- **Stato:** Accettata; **precisata da [ADR-0043](0043-primary-index-a-frammenti.md)** (l'EBR governa solo descrittori e file dei segmenti; directory e frammenti li ritira il collector) e da [ADR-0045](0045-modello-di-esecuzione.md) (una sezione di lettura è un compito).
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-16; realizza INV-R1 e INV-C10
- **Riferimenti:** [architettura](../architettura.md#reclaim), INV-R1

## Contesto

Il reclaim di un segmento `OBSOLETE`, di una tabella dell'indice sostituita o di una base di
indice secondario richiede di sapere quando nessun reader li usa più, senza costo apprezzabile
sul percorso di lettura e senza contatori condivisi.

## Decisione

**Epoch-based reclamation (EBR)** a livello di Archivio:

- Un contatore di epoca globale `E` (64 bit).
- Ogni worker ha uno slot proprio (riga di cache separata) in cui pubblica l'epoca corrente
  quando entra in una sezione di lettura e un valore «inattivo» quando esce. Entrare costa una
  lettura di `E` e una scrittura locale.
- Chi ritira un oggetto (segmento, tabella, base di indice) lo accoda con l'epoca di ritiro
  `r` e incrementa `E`.
- Un oggetto ritirato è **reclamabile** quando ogni worker è inattivo o ha pubblicato un'epoca
  `> r`. Il controllo avviene periodicamente dal Compaction Scheduler.

Gli snapshot non detengono riferimenti ai segmenti: detengono un CSN, e le location arrivano
da indice e versioni trattenute ([ADR-0015](0015-primary-index-swiss-table-swmr.md)). Le
transazioni detengono (chiave, versione), non location. Quindi, dopo la rilocazione
condizionale, le quattro condizioni di INV-R1 si riducono a: *nessun riferimento residuo da
indice e versioni trattenute* (garantito dalla rilocazione completata) **e** *epoca
superata*.

Pattern: EBR (Fraser 2004; Crossbeam; RCU nel kernel Linux).

## Conseguenze

- Reader attesa-liberi e senza scritture condivise.
- Un worker bloccato dentro una sezione di lettura trattiene il reclaim: le sezioni di lettura
  sono brevi per costruzione (non includono I/O di rete né attese).
- Il reclaim è differito di qualche epoca: spazio su disco liberato con ritardo di
  millisecondi–secondi, mai di più.

## Alternative considerate

- *Contatore di riferimenti per segmento:* una scrittura atomica condivisa per ogni lettura.
- *Hazard pointer:* più complessi per oggetti grandi e numerosi come i segmenti.

## Valutazione

- Verifica: FI-09, FI-11; modello in SPK-07; stress test di lettura durante compaction.
