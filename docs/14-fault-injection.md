# 14 — Fault injection

> **Fonte:** «Fault injection» della [specifica](specifica/prompt-originale.md).

## Scenari

Vanno implementati test di fault injection almeno per i seguenti punti di crash.

| ID | Crash… | Sottosistema | Invarianti da verificare |
|---|---|---|---|
| FI-01 | durante WAL append | [WAL](04-wal-e-durability.md) | INV-D1 |
| FI-02 | durante fsync | [WAL](04-wal-e-durability.md) | INV-D1 |
| FI-03 | dopo prepare | [Transazioni](05-transazioni.md) | INV-T4, INV-D1 |
| FI-04 | prima del commit decision | [Transazioni](05-transazioni.md) | INV-T4, INV-T3 |
| FI-05 | dopo commit decision | [Transazioni](05-transazioni.md) | INV-T4, INV-T3, INV-D1 |
| FI-06 | durante atomic index swap | [Compaction](07-compaction.md), [Indici](08-indici.md) | INV-C7, INV-C8, INV-D1 |
| FI-07 | durante CLEAN | [Compaction](07-compaction.md) | INV-C3, INV-C8, INV-C9 |
| FI-08 | durante MERGE | [Compaction](07-compaction.md) | INV-C3, INV-C8, INV-C9 |
| FI-09 | durante reclaim | [Compaction](07-compaction.md), [MVCC](06-mvcc-e-snapshot.md) | INV-R1, INV-D1 |
| FI-10 | durante rebuild index | [Recovery](11-recovery.md) | INV-D1, INV-S6 |
| FI-11 | con snapshot attivi | [MVCC](06-mvcc-e-snapshot.md) | INV-M1, INV-M2, INV-R1 |
| FI-12 | durante transazione multiserie | [Transazioni](05-transazioni.md) | INV-T4, INV-T5 |
| FI-13 | durante creazione/eliminazione di una Serie (aggiunto da [ADR-0022](adr/0022-registri-come-serie-catalogo.md)) | [Modello logico](02-modello-logico.md#catalogo) | catalogo coerente con le directory; nessuna Serie a metà |

## Invarianti da verificare

Dalla specifica, con il corrispondente identificativo in [invarianti.md](invarianti.md):

| # | Invariante | ID |
|---|---|---|
| 1 | nessun dato committed deve andare perso | INV-D1 |
| 2 | nessuna transazione multiserie deve risultare parzialmente committed | INV-T4 |
| 3 | nessun segmento ancora referenziato deve essere eliminato | INV-R1 |
| 4 | nessuno snapshot deve osservare una versione non coerente | INV-M1 |
| 5 | un segmento sorgente deve rimanere recuperabile fino al completamento dello swap | INV-C8 |
| 6 | una compaction interrotta deve essere ripetibile o completabile durante recovery | INV-C9 |

## Implicazioni architetturali

Il fault injection condiziona il progetto fin dall'inizio; non si aggiunge alla fine.

> **Proposta** — Requisiti di testabilità da assumere in fase di definizione:
>
> - **Punti di crash nominati.** Ogni passo dei protocolli (append, fsync, prepare, decisione,
>   swap, cambio di stato del segmento, cancellazione) attraversa un punto di iniezione
>   identificabile, così gli scenari FI si esprimono come «crash al punto X».
> - **Strato di I/O sostituibile.** Tutte le scritture e gli `fsync` passano da un'unica
>   interfaccia, che in test può simulare scritture parziali, `fsync` non eseguiti e perdita
>   dei dati non sincronizzati.
> - **Oracolo.** Un modello di riferimento registra che cosa è stato confermato al client; dopo
>   il recovery si confronta lo stato del database con il modello.
> - **Due livelli.** Simulazione deterministica in-process (veloce, esaustiva sui punti di
>   crash) e crash reali del processo SBCL (`kill -9`) su file system reale.
> - **Modelli dei protocolli.** 2PC + recovery e workflow di compaction + reclaim sono
>   abbastanza piccoli da essere descritti come macchine a stati ed esplorati esaustivamente
>   prima di scrivere il codice: è un'attività della fase di valutazione
>   ([piano degli spike](valutazione/piano-spike.md), SPK-07).

## Punti aperti

- Che cosa significa «committed» per il livello di durability async (QA-05): determina che cosa
  l'oracolo può pretendere dopo FI-01/FI-02.
- Semantica di `fsync` per piattaforma (QA-19): un test di durability è significativo solo se
  il flush raggiunge davvero il supporto.
