# ADR-0020 — CSN di Archivio, snapshot e livelli di isolamento

- **Stato:** Accettata; **sostituita in parte da [ADR-0038](0038-orizzonte-di-visibilita.md)**: lo snapshot nasce quando l'orizzonte di visibilità lo ha raggiunto (non attende le sole multiserie), il CSN è preso alla chiusura del lotto, la versione del documento è il CSN. Isolamento, durata massima e `snapshot-too-old` restano.
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-06, QA-09 e QA-14; realizza «Snapshot/MVCC»
- **Riferimenti:** [architettura](../architettura.md#snapshot-e-mvcc), INV-M1, INV-M2, INV-V2

## Decisione

### Commit Sequence Number

- Ogni Archivio ha un **CSN**: contatore a 64 bit, incrementato con un'operazione atomica.
- Transazioni single-Series: il writer assegna **un CSN per lotto** di group commit (un
  incremento atomico per lotto). Tutte le versioni del lotto portano quel CSN nel record.
- Transazioni multiserie: il CSN è assegnato dal coordinatore **dopo** che la decisione
  COMMIT è durevole in `multiserie.log` ([ADR-0021](0021-2pc-intenti-outcome.md)).
- Ogni versione nell'indice porta il CSN con cui è diventata visibile.

### Snapshot

- Uno snapshot è un numero `s`: vede la versione di ogni documento con il CSN più alto
  `≤ s`. Serie e Archivio usano lo stesso meccanismo.
- Creazione: `s ← CSN corrente`; poi si attende che nessuna transazione multiserie con CSN
  `≤ s` sia ancora in applicazione (insieme ordinato delle multiserie «in applicazione»,
  tenuto dal coordinatore; l'applicazione è in memoria, microsecondi). INV-V2: uno snapshot
  vede una transazione multiserie tutta o per niente.
- Gli snapshot attivi sono registrati per Archivio con il loro CSN; il minimo attivo
  governa le versioni trattenute ([ADR-0015](0015-primary-index-swiss-table-swmr.md)) e il
  CLEAN.
- **Durata massima** configurabile (default 1 ora): oltre, lo snapshot è terminato e le
  operazioni che lo usano ricevono l'errore `snapshot-too-old`. Metrica: età del più vecchio
  snapshot attivo.

### Isolamento

| Operazione | Livello |
|---|---|
| GET senza snapshot | read committed: ultima versione pubblicata della Serie |
| Transazione (single-Series o multiserie) | **snapshot isolation**: legge dallo snapshot, scrive con expected-version (first-committer-wins) |
| Transazione con `:serializable` | come sopra, più validazione al commit delle versioni di tutti i documenti **letti** (read-set), in ciascun partecipante |

Due GET senza snapshot su Serie diverse non sono atomici rispetto a una multiserie in
applicazione: chi lo richiede usa uno snapshot.

Pattern: CSN/SCN per la visibilità (Oracle SCN, PostgreSQL CSN); snapshot isolation con
first-committer-wins; `snapshot too old` (Oracle ORA-01555, PostgreSQL
`old_snapshot_threshold`); validazione del read-set per la serializzabilità (OCC classico).

## Conseguenze

- Un solo elemento condiviso tra Serie: un incremento atomico per lotto. Nessun I/O condiviso.
- Il CSN finisce nei record e negli hint: 8 byte per record.
- Dopo un riavvio il CSN riparte dal massimo osservato + 1; gli snapshot non sopravvivono al
  processo.

## Alternative considerate

- *Vettore di posizioni per Serie:* nessun contatore condiviso, ma coordinamento complesso per
  le multiserie e snapshot di dimensione O(Serie).
- *Timestamp fisici:* richiedono orologi affidabili; non necessari in un solo processo.

## Valutazione

- Verifica: FI-11, FI-12; modello in SPK-07 (snapshot durante l'applicazione di una
  multiserie); test di write-skew per `:serializable`.
