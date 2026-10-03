# ADR-0030 — Scope della v1

- **Stato:** Proposta (richiede conferma dell'autore)
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-23
- **Riferimenti:** RSK-14

## Decisione

**Dentro la v1:** tutto ciò che la specifica descrive — un processo, un dispositivo, più
Archivi, Serie, transazioni locali e multiserie, snapshot, compaction, indici, cache,
scheduler dinamico, recovery, osservabilità, benchmark, fault injection, protocollo e query.

**Fuori dalla v1**, senza precluderlo nei formati:

| Funzione | Perché rinviata | Che cosa resta predisposto |
|---|---|---|
| Replica e alta disponibilità | richiede un log di replica e consenso | segmenti immutabili e CSN sono una base naturale per lo shipping dei segmenti |
| Backup e restore | — | un backup coerente è la copia dei segmenti chiusi + control log a un CSN: da aggiungere come comando |
| Autenticazione e autorizzazione | — | handshake versionato nel protocollo |
| Cifratura in transito e a riposo | — | il modulo `io` è l'unico punto di scrittura |
| Compressione dei record | va misurata | flag riservato nell'intestazione del record |
| Più dispositivi per server | — | il percorso di una Serie è configurabile nel catalogo |

## Conseguenze

- L'ampiezza (RSK-14) è contenuta a ciò che la specifica richiede.
- Le funzioni rinviate hanno un punto di innesto dichiarato: nessun formato va riscritto.
