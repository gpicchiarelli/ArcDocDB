# ADR-0030 — Scope della v1

- **Stato:** Accettata dall'autore il 2026-10-08, inclusi backup, restore verificato, verificatore offline e scrubbing della revisione 2026-10-03.
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-23
- **Riferimenti:** RSK-14

## Decisione

**Dentro la v1:** tutto ciò che la specifica descrive — un processo, un dispositivo, più
Archivi, Serie, transazioni locali e multiserie, snapshot, compaction, indici, cache,
scheduler dinamico, recovery, osservabilità, benchmark, fault injection, protocollo e query —
più, per l'affidabilità ([ADR-0031](0031-software-critico-criteri-e-priorita.md)):

- **backup consistente e restore verificato** (copia dei segmenti chiusi, control log e hint a
  un CSN; i segmenti immutabili lo rendono incrementale);
- **verificatore offline** `arcdocdb-verify` ([ADR-0033](0033-fail-stop-e-integrita-end-to-end.md) §7);
- **scrubbing** continuo dei segmenti chiusi.

Senza una seconda copia dei dati la perdita del supporto è la perdita dei dati (RSK-17): il
backup è la risposta minima.

**Fuori dalla v1**, senza precluderlo nei formati:

| Funzione | Perché rinviata | Che cosa resta predisposto |
|---|---|---|
| Mirroring dei segmenti su un secondo percorso (v1.1) | secondo livello di difesa contro RSK-17; non richiede consenso | i segmenti immutabili e il control log sono già l'unità di copia |
| Replica tra server e alta disponibilità | richiede un log di replica e consenso | segmenti immutabili e CSN sono una base naturale per lo shipping dei segmenti |
| Autenticazione e autorizzazione | — | handshake versionato nel protocollo |
| Cifratura in transito e a riposo | — | il modulo `io` è l'unico punto di scrittura |
| Compressione dei record | va misurata | flag riservato nell'intestazione del record |
| Più dispositivi per server | — | il percorso di una Serie è configurabile nel catalogo |

## Conseguenze

- L'ampiezza (RSK-14) è contenuta a ciò che la specifica richiede.
- Le funzioni rinviate hanno un punto di innesto dichiarato: nessun formato va riscritto.
