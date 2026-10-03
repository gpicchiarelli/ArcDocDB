# ADR-0019 — Livelli di durability e group commit pipelined

- **Stato:** Accettata
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-05; precisa «WAL» (group commit)
- **Riferimenti:** [architettura](../architettura.md#percorso-di-scrittura), INV-D1, INV-V1

## Decisione

### Livelli

| Livello | Conferma al client | Visibilità ai reader | Uso |
|---|---|---|---|
| `:strong` | dopo il flush del gruppo, avviato **subito** | dopo il flush | operazioni critiche |
| `:group` (**default**) | dopo il flush del gruppo, avviato alla chiusura del lotto | dopo il flush | uso generale |
| `:async` | all'applicazione in memoria | immediata | ingestione massiva |

- Il livello è configurato **per Serie**; una singola operazione può chiederne uno più forte,
  mai più debole.
- **«Committed» per INV-D1** = confermato a un livello `:group` o `:strong`. Con `:async` il
  contratto è: le operazioni confermate e non ancora flushate possono andare perse in un
  crash; l'ordine delle sopravvissute è rispettato (prefisso del log).
- Una transazione multiserie usa almeno `:group` su tutti i partecipanti.
- INV-V1: con `:group` e `:strong` un reader non vede mai una versione non ancora durevole.

### Group commit pipelined

Il writer logico forma un lotto, lo codifica nel buffer del segmento `ACTIVE`, esegue
`write` e **consegna il flush al pool di I/O**, poi passa subito al lotto successivo. Al
completamento del flush, il callback (eseguito dal writer stesso, in coda alle operazioni)
pubblica gli aggiornamenti dell'indice e conferma i client del lotto. Possono esserci più
lotti in volo; le pubblicazioni avvengono in ordine di lotto.

Parametri per Serie: dimensione massima del lotto (byte e operazioni) e attesa massima di
formazione (default 0: il lotto si chiude quando il writer ha svuotato la coda o raggiunto la
dimensione, cioè si adatta al carico senza timer).

Pattern: group commit pipelined (MySQL binlog group commit; PostgreSQL WAL writer); livelli
di sincronizzazione configurabili (PostgreSQL `synchronous_commit`).

> **Revisione 2026-10-03 ([ADR-0033](0033-fail-stop-e-integrita-end-to-end.md) §10):** `:async` non è mai il default, richiede una scelta esplicita per Serie, è vietato per Registri e per i partecipanti a transazioni multiserie.

## Conseguenze

- Il writer non si blocca mai su I/O: il tetto per Serie è dettato dalla CPU, non dal flush.
- La latenza di `:group` è ≈ un flush + attesa del lotto; `:strong` elimina l'attesa del lotto
  ma non il flush.
- Il modulo `io` deve offrire flush asincrono con completamento in coda al writer.

## Alternative considerate

- *Timer di formazione del lotto:* aggiunge latenza a basso carico; il lotto adattivo è
  sufficiente.
- *Writer che attende il flush:* semplice, ma dimezza il throughput per Serie.

## Valutazione

- Verifica: SPK-03 (flush), FI-01, FI-02; test di ordine di pubblicazione dei lotti.
