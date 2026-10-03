# 04 — WAL e durability

> **Fonte:** «WAL» della [specifica](specifica/prompt-originale.md); riferimenti da «Transazioni
> multiserie» e «Recovery».
> **Moduli:** M02 WAL Manager.
> **Decisioni:** [ADR-0013](adr/0013-log-structured-segmento-active-come-log.md) **emenda
> questa sezione**: il log dei dati della Serie è il segmento ACTIVE; `wal/control.log` è il
> WAL strutturale. [ADR-0019](adr/0019-durability-e-group-commit-pipelined.md) definisce i
> livelli di durability e il group commit pipelined. Il testo sotto riporta la specifica
> originale; dove differisce, prevalgono gli ADR.

## Un WAL per Serie

Ogni Serie possiede un WAL indipendente, in `Serie/wal/`. NON DEVE esistere un WAL dei dati
globale (INV-W1).

Il WAL serve a:

- **durability** — ciò che è stato confermato sopravvive a un crash;
- **recovery** — ripartenza dopo crash ([11 Recovery](11-recovery.md));
- **ricostruzione dello stato** — indici e metadata sono derivabili;
- **registrazione ordinata delle modifiche** — l'ordine nel WAL è l'ordine di commit nella Serie.

Poiché il WAL è scritto solo dal writer logico della Serie
([10](10-concorrenza-e-scheduling.md)), l'append non richiede coordinamento con altre Serie.

## Group commit

Il sistema DEVE privilegiare il group commit: molte transazioni condividono una singola
operazione di flush.

```
TX101 ─┐
TX102 ─┼──> WAL append ──> fsync
TX103 ─┘
```

- Evitare un `fsync` per ogni singola operazione, **salvo** esplicita richiesta di durability
  forte.
- Anche `multiserie.log` DEVE usare group commit dove appropriato.

## Livelli di durability

La specifica presuppone più livelli, senza elencarli formalmente. Dal testo se ne ricavano tre:

| Livello | Da dove emerge nella specifica | Comportamento atteso |
|---|---|---|
| async | target «INSERT async durability» | conferma prima del flush; una finestra di scritture recenti può andare persa in caso di crash |
| group commit | «privilegiare group commit», target «INSERT group commit» | conferma dopo un `fsync` condiviso con altre transazioni |
| forte | «salvo esplicita richiesta di durability forte» | `fsync` dedicato all'operazione |

> **Aperto (QA-05)** — Nomi, semantica esatta, livello di default e granularità (per Serie, per
> richiesta, per transazione) vanno definiti. In particolare va precisato che cosa significa
> «committed» ai fini di INV-D1 quando il livello è async.

## Il WAL nelle transazioni multiserie

In una transazione multiserie ogni Serie partecipante registra il proprio PREPARE nel proprio
WAL, ed esegue flush/fsync secondo il livello di durability **prima** che la decisione venga
scritta in `multiserie.log`. Il WAL della Serie contiene quindi anche record di protocollo
(prepare, commit, abort) oltre alle modifiche. Vedi [05 Transazioni](05-transazioni.md).

## Metriche

Da esporre ([12 Osservabilità](12-osservabilita.md)): append throughput, latenza di `fsync`,
dimensione del gruppo, profondità della coda del WAL. Latenza di `fsync` e throughput del WAL
sono anche segnali di carico per la [low-load policy](07-compaction.md#low-load-policy) del
MERGE e per lo [scheduler](10-concorrenza-e-scheduling.md).

## Punti aperti

- **QA-02** — Rapporto WAL ↔ segmenti e politica di troncamento del WAL.
- **QA-05** — Livelli di durability.
- **QA-19** — Primitive di I/O per piattaforma. Nota rilevante per lo sviluppo su macOS: lì
  `fsync` non garantisce la persistenza su supporto fisico (serve `F_FULLFSYNC`); i test di
  durability vanno quindi interpretati per piattaforma.

> **Proposta** — Ogni record del WAL dovrebbe portare lunghezza e checksum, così che il recovery
> possa distinguere un record completo da una coda troncata da un crash durante l'append
> (scenario FI-01). Formato da definire con QA-01.
