# 06 — MVCC e snapshot

> **Fonte:** «Snapshot / MVCC», «Index/Snapshot/Reclaim», «Cache e snapshot» della
> [specifica](specifica/prompt-originale.md).
> **Moduli:** M08 Snapshot/MVCC Manager.

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

## Punti aperti e rischi

La specifica fissa il *comportamento* degli snapshot ma non il *meccanismo*. I punti seguenti
sono architetturali: vanno chiusi prima di progettare primary index e compaction.

- **QA-24** — Come uno snapshot localizza una versione non più corrente. Il primary index
  mappa `_id → location` della versione corrente; serve una struttura che, per i documenti
  aggiornati mentre uno snapshot è attivo, conservi anche le location precedenti, e che resti
  valida quando la compaction riloca i record.
- **QA-06** — Snapshot coerente a livello di Archivio con writer indipendenti per Serie: serve
  un punto di riferimento comune (sequenza di commit dell'Archivio o vettore di posizioni per
  Serie) e la garanzia che una transazione multiserie diventi visibile in modo atomico rispetto
  allo snapshot.
- **QA-14** — Snapshot longevi: bloccano il reclaim (spazio) e, per le condizioni del MERGE,
  anche la deframmentazione. Serve una politica (limite di durata, metrica, allarme).
- **QA-16** — Come si tracciano i reader attivi per il reclaim (epoch, refcount per segmento).
- Rischi collegati: RSK-02, RSK-05, RSK-09.
