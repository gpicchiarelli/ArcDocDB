# ADR-0042 — Tombstone: l'indice contiene solo documenti vivi; scarto per filtro di esistenza

- **Stato:** Accettata
- **Data:** 2026-10-03
- **Rapporto con la specifica:** nessuna emenda; chiude di nuovo QA-15. **Sostituisce** la
  sezione «Tombstone» di [ADR-0023](0023-politiche-di-compaction.md) e la ricostruzione «in
  ordine di lineage» di [ADR-0015](0015-primary-index-swiss-table-swmr.md); assegna una
  funzione al filtro di Bloom sulle chiavi di [ADR-0026](0026-indici-secondari-segmentati.md).
  Soglie, stati di carico e limitatore di ADR-0023 restano.
- **Riferimenti:** [analisi progettuale](../analisi-progettuale.md) AP-04, AP-11;
  [architettura](../architettura.md#compaction); INV-C11, INV-D1, INV-I2

## Contesto

Un tombstone esiste su disco per una sola ragione: impedire che, quando l'indice viene
ricostruito dai segmenti, una versione più vecchia dello stesso documento torni a sembrare
corrente. La regola per lineage di ADR-0023 non lo garantisce quando un MERGE unisce segmenti
non adiacenti (controesempio in AP-04), e nella sua forma sicura non scarterebbe quasi mai.
Inoltre non era definito se l'indice in memoria conservasse una entry per i documenti
eliminati: in tal caso la memoria crescerebbe con le eliminazioni, senza limite.

## Decisione

### 1. L'indice contiene solo documenti vivi

Alla pubblicazione di un tombstone il writer trattiene la versione precedente se uno snapshot
ne ha bisogno ([ADR-0038](0038-orizzonte-di-visibilita.md)) e **rimuove la entry**. Un
documento eliminato non occupa memoria. Una successiva creazione dello stesso `_id` è un
documento nuovo, con un CSN maggiore di ogni versione passata.

### 2. Ricostruzione: vince il CSN massimo

Per ogni chiave, il record committed con il **CSN più alto** tra tutti i segmenti è la
versione corrente; se è un tombstone, la chiave non ha entry. A parità di CSN (due scritture
dello stesso documento nello stesso lotto, quindi nello stesso segmento) vince l'offset
maggiore. Il risultato **non dipende dall'ordine** in cui i segmenti sono letti: la
ricostruzione procede in parallelo e in qualsiasi ordine. Durante la ricostruzione i tombstone
occupano una entry provvisoria, tolta alla fine.

### 3. Quando un tombstone si scarta

Sia `t` un tombstone per la chiave `k` con CSN `c`, incontrato da una compaction con sorgenti
`I`. `t` **non viene copiato** se vale una delle due:

- **(a) superato**: l'indice ha una entry per `k` con CSN `> c` il cui record sta in un
  segmento `CLOSED`, quindi è durevole (il documento è stato ricreato: quel record, o il
  tombstone che un giorno lo eliminerà, nasconde tutto ciò che `t` nascondeva);
- **(b) senza più nulla da nascondere**: nessuna versione di `k` è trattenuta, e per ogni
  segmento `S` della Serie non in `I` con `csn-min(S) < c`, il filtro di esistenza di `S`
  risponde «sicuramente assente» per `k`.

In ogni altro caso `t` è un record necessario e viene copiato. Il filtro di esistenza è la
sezione Bloom dell'hint ([ADR-0039](0039-cornice-unica-dei-record.md)); un hint mancante o non
valido vale «forse presente»; l'`ACTIVE` contiene solo record più recenti di qualunque
tombstone in un segmento chiuso e non partecipa. Un falso positivo del filtro conserva un
tombstone più a lungo: l'errore è nella direzione sicura, come prescrive INV-I2.

Le versioni più vecchie di `k` dentro i sorgenti `I` sono morte e non vengono copiate: per
questo `I` è escluso dal controllo.

### 4. Contabilità

Un tombstone è contato tra i byte **necessari** finché una compaction non stabilisce che è
scartabile. Un segmento che contiene tombstone non è mai eliminato direttamente con la regola
«live = 0»: passa da un CLEAN.

Pattern: purga dei tombstone solo se nessun altro file può contenere dati più vecchi della
stessa chiave, deciso con il filtro di Bloom e il timestamp minimo di ogni file (Apache
Cassandra); indice in memoria dei soli vivi con tombstone solo su disco (Bitcask).

## Conseguenze

- Nessuna riapparizione di documenti eliminati, per costruzione e senza ipotesi su quali
  segmenti vengano uniti.
- I tombstone su disco sono limitati dai record morti non ancora recuperati: ogni tombstone
  conservato corrisponde ad almeno un record più vecchio della stessa chiave ancora presente
  (o a un falso positivo del filtro, ~1 %).
- Memoria dell'indice proporzionale ai documenti vivi.
- `lineage-min` scompare da intestazione del segmento e manifest.
- Costo: per ogni tombstone candidato, un test di Bloom per ogni segmento più vecchio. È
  lavoro di compaction, fuori dal percorso delle richieste; i filtri si leggono su richiesta
  dai file hint.

## Alternative considerate

- *Lineage (ADR-0023):* non sicura con MERGE non adiacenti.
- *Scartare solo quando il segmento del tombstone è il più vecchio della Serie:* sicura, ma i
  tombstone si accumulerebbero sopra i dati freddi per sempre.
- *Checkpoint dell'indice come fonte di verità su ciò che è morto:* renderebbe l'indice non
  più un dato derivato.

## Valutazione

- Verifica: test di proprietà contro il modello di riferimento con eliminazioni, ricreazioni,
  CLEAN, MERGE di segmenti non adiacenti, snapshot attivi e riavvio in ogni punto (nessuna
  chiave eliminata riappare; nessuna chiave viva scompare); FI-07, FI-08, FI-10.
- Rivedere se: il costo dei test di Bloom rallenta il CLEAN sotto il minimo di
  [ADR-0028](0028-target-e-obiettivi-di-latenza.md) con carichi ricchi di eliminazioni.
