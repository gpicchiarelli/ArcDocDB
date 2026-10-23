# ADR-0025 — Cache dei record per location, arena a slot, CLOCK per partizione

- **Stato:** Accettata; **sostituita in parte da [ADR-0044](0044-cache-acceleratore-puro.md)**: insieme associativo al posto della tabella hash (punto 3), nessuna ri-etichettatura (punto 5), nessuno svuotamento per segmento. Unità, chiave, CLOCK e partizioni restano.
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-17; realizza [ADR-0010](0010-cache-clock.md)
- **Riferimenti:** [architettura](../architettura.md#percorso-di-lettura), INV-M3

## Decisione

1. **Unità:** il record (documento + intestazione).
2. **Chiave:** la location `(segment-id, offset)`. I segmenti chiusi sono immutabili: una entry
   non diventa mai stale, non serve invalidazione e INV-M3 vale per costruzione, perché il
   reader arriva alla cache con la location della versione che il suo snapshot vede.
3. **Memoria:** arena per Serie di slot a dimensione fissa in classi (es. 1, 2, 4, 8, 16 KB),
   in array `(unsigned-byte 8)`; il record è copiato nello slot da `pread`. Indice della cache:
   tabella hash compatta `(segment-id, offset) → slot`, stesso layout del primary index.
4. **Sostituzione:** CLOCK per partizione; una partizione per Serie, con budget assegnato
   dallo scheduler (quota configurabile per Serie, il resto proporzionale all'uso recente
   con un minimo garantito). Il bit di riferimento è un byte per slot.
5. **Letture durante la compaction:** quando il writer applica una rilocazione condizionale,
   se la location vecchia è in cache la entry viene **ri-etichettata** con la nuova location
   (stesso contenuto): nessuna perdita di calore.
6. La page cache del sistema operativo è un secondo livello non controllato; i benchmark
   misurano con dataset maggiore della RAM.
7. **Metrica di scan pollution:** quota di slot inseriti da scansioni ed espulsi senza mai
   essere stati riletti. Se supera il 30 % in un benchmark di riferimento, un nuovo ADR
   valuta 2Q (come previsto dalla specifica).

Pattern: cache a blocchi con CLOCK (PostgreSQL buffer pool, clock-sweep); chiave per
posizione fisica immutabile (block cache di RocksDB per SST immutabili).

## Conseguenze

- Nessuna invalidazione sulle scritture; la cache non partecipa ai protocolli di coerenza.
- Il record resta in cache finché il segmento esiste, anche se la versione è morta: lo spazio
  si libera con CLOCK o al reclaim del segmento (le entry del segmento sono eliminate).
- Il costo per Serie è un budget da governare: parte dello scheduler.

## Valutazione

- Verifica: SPK-05; benchmark GET con cache hit/miss e con scansioni concorrenti.
