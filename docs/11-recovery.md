# 11 — Recovery

> **Fonte:** «Recovery» della [specifica](specifica/prompt-originale.md); riferimenti da
> «Transazioni multiserie», «Segment metadata», «Workflow Clean/Merge».
> **Moduli:** M12 Recovery Manager.
> **Decisioni:** la sequenza definitiva è in [architettura.md](architettura.md#recovery);
> meccanismi in [ADR-0018](adr/0018-control-log-manifest-swap.md), [ADR-0021](adr/0021-2pc-intenti-outcome.md),
> [ADR-0022](adr/0022-registri-come-serie-catalogo.md).

## Compito

Il Recovery Manager DEVE essere in grado di ricostruire il sistema dopo un crash. Verifica:

- WAL;
- segment metadata;
- index metadata;
- atomic swap;
- stato dei segmenti;
- stato delle transazioni;
- `multiserie.log`.

## Che cosa fa dopo un crash

- recupera i WAL delle singole Serie;
- ricostruisce o verifica gli indici;
- identifica i segmenti `ACTIVE` / `CLOSED` / `OBSOLETE`;
- completa o annulla le operazioni di compaction incomplete;
- processa `multiserie.log`;
- completa le transazioni multiserie preparate.

## Requisiti di crash-safety

- Le operazioni di compaction DEVONO essere crash-safe.
- Un segmento nuovo NON DEVE diventare visibile come definitivo prima che i suoi dati siano
  durevoli (INV-C7).
- Un atomic swap incompleto DEVE poter essere riconosciuto durante il recovery.
- I segment metadata sono dati derivati: il recovery li verifica e, se necessario, li
  ricostruisce da WAL, dati e indice (INV-S6).

## Sequenza

> **Proposta** — La specifica elenca le attività ma non l'ordine. L'ordine seguente rispetta le
> dipendenze tra le attività.

| # | Passo | Perché in questo punto |
|---|---|---|
| 1 | Recupero del catalogo in `Registri/` | senza catalogo non si conoscono le Serie da aprire |
| 2 | Lettura di `multiserie.log` → tabella delle decisioni | serve per interpretare i PREPARE nei WAL delle Serie |
| 3 | Per ogni Serie (**in parallelo**): inventario dei segmenti e loro stato | identifica ACTIVE/CLOSED/OBSOLETE e file di compaction incompleti |
| 4 | Per ogni Serie: risoluzione delle compaction interrotte | scartare l'output non ancora visibile, oppure completare lo swap |
| 5 | Per ogni Serie: replay del WAL | ricostruisce lo stato; le transazioni PREPARED si risolvono con la tabella del passo 2 |
| 6 | Per ogni Serie: ricostruzione o verifica di indici e segment metadata | dati derivati |
| 7 | Completamento delle transazioni multiserie preparate | COMMIT se la decisione è durevole, altrimenti ABORT |
| 8 | Apertura al traffico | — |

Le Serie sono fisicamente indipendenti, quindi i passi 3–6 si prestano al recovery parallelo
per Serie: il tempo di riavvio è dominato dalla Serie più lenta, non dalla somma.

## Casi di compaction interrotta

Con riferimento ai passi del [workflow](07-compaction.md#workflow):

| Crash… | Stato trovato | Azione |
|---|---|---|
| durante la copia (passi 4–6) | file di output parziale, non referenziato | scartare l'output; il sorgente è intatto; l'operazione è ripetibile |
| dopo `fsync`, prima dello swap (7–8) | output completo ma non visibile | scartare (o riutilizzare) l'output; sorgente intatto |
| durante lo swap (9) | swap parziale | DEVE essere riconoscibile; completare o annullare |
| dopo lo swap, prima di OBSOLETE (10) | output visibile, sorgente ancora `CLOSED` | segnare il sorgente `OBSOLETE` |
| durante il reclaim (11–13) | sorgente `OBSOLETE`/`RECLAIMABLE`, eventualmente file già rimosso | dopo un riavvio non esistono reader né snapshot precedenti: il reclaim può essere completato |

> **Aperto (QA-04)** — Per riconoscere uno swap incompleto serve una registrazione autorevole e
> atomica dell'insieme dei segmenti validi di una Serie (un *manifest*, oppure record dedicati
> nel WAL della Serie). È la decisione che rende deterministica tutta la tabella qui sopra.

## Punti aperti e rischi

- **QA-04** — Manifest dei segmenti e meccanismo dello swap.
- **QA-03** — Ricostruire l'indice da zero richiede di rileggere tutti i segmenti; senza
  checkpoint il tempo di riavvio cresce con la dimensione dei dati (RSK-07).
- **QA-10** — Bootstrap di Registri/catalogo (RSK-15).
- **QA-08** — Fino a quando una decisione resta in `multiserie.log`.
- Ogni riga delle tabelle sopra corrisponde a uno scenario di
  [fault injection](14-fault-injection.md).

## Metriche

Tempo di recovery complessivo e per Serie, tempo di rebuild degli indici, numero di transazioni
multiserie risolte, numero di compaction ripetute o completate.
