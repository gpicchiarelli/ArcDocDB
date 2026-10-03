# ADR-0040 — Manifest a record unico (EDIT); il catalogo decide, le directory seguono

- **Stato:** Accettata
- **Data:** 2026-10-03
- **Rapporto con la specifica:** nessuna emenda; realizza «Segmenti» (stati), «Workflow
  Clean/Merge», «Recovery», «Catalogo». **Sostituisce in parte**
  [ADR-0018](0018-control-log-manifest-swap.md) (tipi di record, ordine tra rinomina e record,
  timestamp, orfani) e [ADR-0022](0022-registri-come-serie-catalogo.md) punto 3 (creazione ed
  eliminazione di una Serie). Resta di ADR-0018: il control log è il manifest; lo swap è un
  solo record.
- **Riferimenti:** [analisi progettuale](../analisi-progettuale.md) AP-14;
  [leggi](0036-leggi-di-progetto.md); [formati](../formati-su-disco.md#control-log);
  INV-A9, INV-A10, INV-A11, INV-C7, INV-C8, INV-C9

## Contesto

Il control log registrava sette tipi di evento, ma l'unico fatto che deve sopravvivere a un
riavvio è **quali segmenti compongono la Serie**. Dopo un riavvio non esistono reader né
snapshot: `OBSOLETE` e `RECLAIMABLE` non hanno contenuto durevole; i contatori sono derivati
(INV-S6); i timestamp monotoni non si confrontano tra riavvii. L'ordine «rinomina, poi
record» lasciava file con nome definitivo sconosciuti al manifest, da eliminare «per assenza».

## Decisione

### 1. Un solo record: EDIT

```
EDIT { completo?,  apre: id | nessuno,
       chiude:  [(id, lunghezza-valida, esiti: [(txid, csn)…])…],
       rimuove: [id…] }
```

Lo stato strutturale di una Serie è il **ripiegamento** degli EDIT nell'ordine del log:

- l'insieme dei segmenti `CLOSED`, ciascuno con la sua lunghezza valida e gli eventuali esiti
  ([ADR-0041](0041-multiserie-segmenti-autosufficienti.md));
- l'unico `ACTIVE`;
- l'insieme dei **rimossi** il cui file può esistere ancora.

Un EDIT con il flag `completo` dichiara l'intero stato: è il primo record di ogni file di
control log, e sostituisce il vecchio `CHECKPOINT`. Porta anche il **prossimo segment-id**:
un identificativo nominato da un EDIT non viene mai riusato, nemmeno dopo l'eliminazione del
segmento e la compattazione del log, così nessun file derivato o dato in cache può essere
attribuito a un segmento diverso da quello per cui è nato.

| Operazione | EDIT |
|---|---|
| Rotazione | `chiude: (a, n)` · `apre: b` |
| CLEAN, MERGE | `chiude: (output, n)` · `rimuove: sorgenti` |
| Segmento senza record necessari | `rimuove: s` |
| Chiusura dopo un crash | `chiude: (a, P, esiti)` · `apre: b`, dentro un EDIT `completo` |

Gli stati della specifica restano gli stati del modello: `ACTIVE` e `CLOSED` sono l'essere
nell'insieme; `OBSOLETE` (rimosso, ancora letto), `RECLAIMABLE` (rimosso, nessun reader:
[ADR-0016](0016-epoch-based-reclamation.md)) e `DELETED` sono stati **in memoria** di un
segmento rimosso.

### 2. Prepara, decidi, completa

Per ogni file nuovo (segmento `ACTIVE`, output di compaction):

1. **prepara**: si scrive `<id>.seg.tmp`, lo si rende durevole, si sincronizza la directory;
2. **decidi**: l'EDIT, scritto dal writer della Serie in un lotto sigillato del control log
   ([ADR-0037](0037-lotto-sigillato.md)), durevole;
3. **completa**: rinomina in `<id>.seg`; per i sorgenti rimossi, attesa dell'epoca,
   chiusura dei descrittori, eliminazione.

Il writer scrive nel nuovo `ACTIVE` attraverso il descrittore già aperto: non attende la
rinomina. Le rilocazioni dell'indice seguono l'EDIT, come in ADR-0018.

### 3. Riconciliazione al riavvio

| File trovato | Il manifest dice | Azione |
|---|---|---|
| `x.seg.tmp` | `x` non nominato | eliminare: mai deciso |
| `x.seg.tmp` | `x` aperto o chiuso | rinominare in `x.seg` |
| `x.seg` | `x` aperto o chiuso | usare |
| `x.seg` | `x` rimosso | eliminare, con hint e indici |
| `x.seg` | `x` mai nominato | **anomalia**: non toccare, registrare l'evento |
| nessuno | `x` chiuso | segmento mancante: quarantena, Serie `DEGRADED` |
| nessuno | `x` aperto | `FAULTED` |

Poi il recovery valida l'`ACTIVE` ([ADR-0037](0037-lotto-sigillato.md) §3), prepara il nuovo
`ACTIVE` e scrive un control log **compattato** in `control.log.tmp` — un EDIT `completo` che
chiude il vecchio `ACTIVE` alla sua lunghezza valida, con gli esiti, e apre il nuovo — lo
rende durevole e lo rinomina sopra l'originale. Quella rinomina è il punto di atomicità del
recovery della Serie: prima, nulla è cambiato; dopo, il recovery è completo. Lo stesso
passaggio compatta il log in esercizio quando supera una soglia; l'elenco dei rimossi non
ancora eliminati viene riportato nel nuovo file.

### 4. Che cosa non sta nel manifest

- **Contatori** (record, byte vivi e morti): derivati, ricalcolati dagli hint.
- **Stabilizzazione** (regola dei 50 s): l'istante, letto dall'orologio monotono del processo,
  in cui il segmento è diventato `CLOSED`; dopo un riavvio, la fine del recovery.
- **Hint e indici**: derivati; li produce un worker dopo la chiusura, con `.tmp` e rinomina, e
  si rigenerano se mancano. Finché non esistono, l'indice in memoria del segmento appena
  chiuso resta in uso e un riavvio scansiona il segmento.

### 5. Catalogo: stessa legge

- **Creazione di una Serie.** Si prepara la directory `<id>.tmp/` completa (control log con
  l'EDIT iniziale, primo segmento), durevole. Il **documento** della Serie nel catalogo, con
  stato `active` e durability `:strong`, è la decisione. Poi la rinomina in `<id>/`.
- **Eliminazione.** Il documento passa a `dropping`: è la decisione, e la Serie non accetta
  più richieste. Poi, superata l'epoca, si rimuove la directory e si scrive il tombstone del
  documento.

| Directory trovata | Il catalogo dice | Azione |
|---|---|---|
| `<id>.tmp/` | nessun documento | eliminare: mai decisa |
| `<id>.tmp/` | `active` | rinominare |
| `<id>/` | `active` | aprire |
| `<id>/` | `dropping` | rimuovere, poi tombstone |
| `<id>/` | nessun documento | **anomalia**: non toccare, registrare l'evento |
| nessuna | `active` | Serie `FAULTED` |
| nessuna | `dropping` | tombstone |

Lo stato `creating` non esiste più.

Pattern: MANIFEST come sequenza di modifiche all'insieme dei file, con uno stato completo in
testa (`VersionEdit` di LevelDB/RocksDB); file temporaneo, decisione, rinomina.

## Conseguenze

- Un tipo di record invece di sette; nessuno stato durevole che il riavvio debba interpretare.
- Lo swap resta un solo record (INV-C7, INV-C8, INV-C9); ogni riga delle tabelle sopra è uno
  scenario di fault injection.
- Un file definitivo non è mai eliminato senza un record che lo dica (INV-A10).
- La chiusura di un segmento non ferma più il writer per scrivere hint e indici.

## Alternative considerate

- *Nessun manifest: la directory è l'insieme* (Bitcask): più snello ancora, ma un segmento
  eliminato dall'esterno non sarebbe rilevabile (FM-16); il manifest è l'elenco di ciò che
  **deve** esistere.
- *Rinomina prima del record (ADR-0018):* lascia file definitivi sconosciuti dopo un crash e
  costringe a eliminarli per assenza.
- *Creazione della Serie con stato `creating`:* due scritture nel catalogo per un solo fatto.

## Valutazione

- Verifica: FI-06…FI-09, FI-13; modello in SPK-07 con un crash in ogni riga delle tabelle;
  test del verificatore su file e directory sconosciuti o mancanti.
