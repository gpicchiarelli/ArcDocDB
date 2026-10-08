# 06 — MVCC e snapshot

> **Fonte:** «Snapshot / MVCC», «Index/Snapshot/Reclaim», «Cache e snapshot» della
> [specifica](specifica/specifica-originale.md).
> **Moduli:** M08 Snapshot/MVCC Manager.
> **Decisioni:** [ADR-0020](adr/0020-csn-snapshot-isolamento.md) (snapshot = CSN, durata
> massima), [ADR-0038](adr/0038-orizzonte-di-visibilita.md) (orizzonte di visibilità,
> registro degli snapshot), [ADR-0015](adr/0015-primary-index-swiss-table-swmr.md) (versioni
> trattenute), [ADR-0016](adr/0016-epoch-based-reclamation.md) (reclaim).

> **Deciso (controesempio SPK-07 → ADR-0046)** — Il punto 2 di ADR-0038 è sostituito dal
> [registro limitato dei CSN in volo](adr/0046-orizzonte-con-registro-limitato.md).
> Assegnazione e registrazione sono indivisibili rispetto all'avanzamento di H; non si usa
> più un anello indicizzato dal CSN, che poteva perdere completamenti con un commit lento.

## Che cos'è uno snapshot

Uno snapshot è una **vista logica consistente** a un determinato punto/versione. Non è una
copia fisica del database. Lo storage append-only conserva naturalmente le versioni storiche
fino al reclaim: lo snapshot si limita a stabilire quali versioni sono visibili e a impedirne
la rimozione.

```
Snapshot S vede:   A = 100, B = 200
Un'altra transazione aggiorna A e B.
Snapshot S vede ancora:   A = 100, B = 200   (fino alla sua conclusione)
```

> **Deciso ([ADR-0038](adr/0038-orizzonte-di-visibilita.md))** — Perché la vista non cambi
> davvero, uno snapshot con CSN `s` nasce solo quando l'**orizzonte di visibilità** ha
> raggiunto `s`: tutti i commit con CSN ≤ `s` sono già pubblicati, compresi i lotti il cui
> flush era in corso quando lo snapshot è stato chiesto (INV-M4). Un GET senza snapshot non
> attende nulla.

## Chi usa che cosa

| Operazione | Vista |
|---|---|
| GET semplice | nessuno snapshot globale: legge la versione corrente committed |
| Transazione locale (single-Series) | PUÒ usare uno snapshot della Serie |
| Transazione multiserie | PUÒ usare uno snapshot coerente a livello di Archivio |

## Obblighi

- Uno snapshot DEVE impedire alla compaction di eliminare le versioni di cui ha bisogno
  (INV-M2). Queste versioni sono classificate `SNAPSHOT-LIVE` ([03 Storage](03-storage.md)).
- Nessuno snapshot deve osservare una versione non coerente (INV-M1).
- La cache DEVE essere consapevole della versione/epoch del dato: un reader non deve ottenere
  una versione incompatibile con il proprio snapshot (INV-M3). Vedi [09 Cache](09-cache.md).

## Reclaim

Il reclaim di un segmento avviene solo quando (INV-R1):

- nessun indice corrente lo referenzia;
- nessuno snapshot lo referenzia;
- nessuna transazione attiva lo necessita;
- nessun reader lo sta ancora utilizzando.

Le quattro condizioni corrispondono alla transizione `OBSOLETE → RECLAIMABLE`
([03 Storage](03-storage.md#stati-del-segmento)).

## Questioni decise e rischi

La specifica fissa il *comportamento* degli snapshot ma non il *meccanismo*. I punti seguenti
erano architetturali e sono stati chiusi dagli ADR indicati.

- **QA-24** ([ADR-0015](adr/0015-primary-index-swiss-table-swmr.md)) — Come uno snapshot localizza una versione non più corrente. Il primary index
  mappa `_id → location` della versione corrente; serve una struttura che, per i documenti
  aggiornati mentre uno snapshot è attivo, conservi anche le location precedenti, e che resti
  valida quando la compaction riloca i record.
- **QA-06** ([ADR-0020](adr/0020-csn-snapshot-isolamento.md)) — Snapshot coerente a livello di Archivio con writer indipendenti per Serie: serve
  un punto di riferimento comune (sequenza di commit dell'Archivio o vettore di posizioni per
  Serie) e la garanzia che una transazione multiserie diventi visibile in modo atomico rispetto
  allo snapshot.
- **QA-14** ([ADR-0020](adr/0020-csn-snapshot-isolamento.md)) — Snapshot longevi: bloccano il reclaim (spazio) e, per le condizioni del MERGE,
  anche la deframmentazione. Serve una politica (limite di durata, metrica, allarme).
- **QA-16** ([ADR-0016](adr/0016-epoch-based-reclamation.md)) — Come si tracciano i reader attivi per il reclaim (epoch, refcount per segmento).
- Rischi collegati: RSK-02, RSK-05, RSK-09.
