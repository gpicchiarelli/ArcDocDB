# ADR-0038 — Orizzonte di visibilità: nascita degli snapshot, registro degli snapshot, la versione è il CSN

- **Stato:** Accettata (emenda la specifica nella sola numerazione delle versioni)
- **Data:** 2026-10-03
- **Rapporto con la specifica:** realizza «Snapshot/MVCC». **Emenda** l'esempio di
  «Transazioni single-series» (`v18 → v19`): i numeri di versione sono crescenti ma non
  consecutivi. **Sostituisce in parte** [ADR-0020](0020-csn-snapshot-isolamento.md) (creazione
  dello snapshot, momento di assegnazione del CSN) e [ADR-0015](0015-primary-index-swiss-table-swmr.md)
  (campo versione). Isolamento, durata massima e `snapshot-too-old` di ADR-0020 restano.
- **Riferimenti:** [analisi progettuale](../analisi-progettuale.md) AP-01, AP-02, AP-07, AP-15;
  [architettura](../architettura.md#snapshot-e-mvcc); INV-M1, INV-M2, INV-M4, INV-M5, INV-V2

## Contesto

ADR-0020 definisce lo snapshot come un numero `s` e fa attendere, alla creazione, le sole
multiserie in applicazione. Ma anche un lotto single-Series ha un CSN assegnato prima di
essere pubblicato: uno snapshot nato in quella finestra vede comparire il lotto (AP-01). Il
registro degli snapshot attivi non aveva un protocollo (AP-07). La versione del documento
duplicava il CSN e ripartiva dopo un'eliminazione (AP-15).

## Decisione

### 1. Il CSN nasce con il punto di atomicità

- Lotto single-Series: il CSN è preso **alla chiusura** del lotto
  ([ADR-0037](0037-lotto-sigillato.md)).
- Multiserie: il CSN è preso alla chiusura del lotto di `multiserie.log` che contiene la
  DECISION ([ADR-0041](0041-multiserie-segmenti-autosufficienti.md)).

Un CSN è **in volo** dal momento in cui è preso a quando il suo commit è pubblicato (lotto) o
applicato su tutti i partecipanti sani (multiserie), oppure annullato perché la Serie è
passata in `FAULTED`.

**INV-M5.** Per ogni documento, l'ordine dei CSN coincide con l'ordine delle versioni: un
intento blocca ogni altra scrittura sul documento fino all'esito, e un lotto prende il CSN
dopo aver fissato il proprio contenuto.

### 2. L'orizzonte

L'**orizzonte di visibilità** `H` dell'Archivio è il più grande CSN tale che nessun CSN ≤ `H`
è in volo. Realizzazione:

- un anello di `N` parole `fatto[]` e la parola `H`, con un mutex di Archivio usato **solo**
  da chi pubblica (una volta per lotto, mai dai reader);
- pubblicato o annullato il commit `c`: sotto il mutex, `fatto[c mod N] ← c`, poi finché
  `fatto[(H+1) mod N] = H+1` si incrementa `H`; si risvegliano gli snapshot in attesa;
- i CSN in volo sono limitati a `N/2` da un contatore di crediti: senza credito il writer non
  chiude il lotto (continua ad accumulare); nessun ciclo è illimitato (INV-A8).

`H` si legge con una lettura atomica.

### 3. Nascita di uno snapshot (INV-M4)

1. Registrazione nel registro (punto 4), che fissa `s` = ultimo CSN preso.
2. **Attesa finché `H ≥ s`.** Solo allora lo snapshot esegue la prima lettura.

Ne discende: ogni commit con CSN ≤ `s` è già pubblicato quando lo snapshot legge, e nessuno
potrà comparire dopo (INV-M1); una multiserie è vista per intero o per niente (INV-V2); uno
snapshot creato dopo la conferma di un commit lo vede sempre. L'attesa è al più quella dei
flush in corso; ha un limite di tempo configurato, oltre il quale la richiesta riceve
`resource-exhausted`. Un GET senza snapshot non attende nulla.

### 4. Registro degli snapshot

Array di dimensione fissa di CSN attivi, più la parola **`soglia`** = minimo CSN attivo
(o «nessuno»). Creazione e rilascio sono sotto il mutex del registro; `soglia` si legge senza
lock.

- *Creazione:* `soglia ← min(soglia, H)`; **barriera di memoria completa**; `s ← ultimo CSN
  preso`; si registra `s`.
- *Rilascio:* si toglie `s` e si ricalcola `soglia`.
- *Writer, alla pubblicazione* di una versione con CSN `c` che ne sostituisce una: se
  `soglia < c` la versione precedente va nelle **versioni trattenute** *prima* di aggiornare
  lo slot; altrimenti no.
- *Potatura:* una versione trattenuta con fine validità `a` si elimina quando `soglia ≥ a`.

Correttezza: se il writer non vede la registrazione, la sua lettura di `soglia` precede la
scrittura dello snapshot; quindi il suo CSN `c` era già preso quando lo snapshot legge `s`, e
`s ≥ c`: lo snapshot vedrà la versione nuova e non ha bisogno della vecchia. In ogni altro
caso `soglia ≤ s` e la versione è trattenuta. Nel dubbio si trattiene.

Una lettura con snapshot verifica, **dopo** la ricerca, che lo snapshot sia ancora attivo: se
è scaduto risponde `snapshot-too-old`, mai «non trovato».

### 5. La versione è il CSN

La **versione** di un documento è il CSN del commit che l'ha prodotta. `expected-version` è un
CSN (zero = il documento non deve esistere). Non esiste un contatore per documento.

- La location dell'indice resta `(segment-id, offset, length, versione)` come chiede la
  specifica: la versione è il CSN.
- Un CSN non si ripete e non riparte: un controllo ottimistico non può riuscire contro
  un'altra incarnazione dello stesso `_id`.
- All'apertura di una Serie il contatore dell'Archivio avanza almeno al massimo CSN che la
  Serie contiene; all'avvio riparte dal massimo osservato più uno.

Pattern: orizzonte dei commit pubblicati (PostgreSQL: uno snapshot esclude le transazioni
ancora in corso; WiredTiger `all_durable`; CockroachDB *closed timestamp*); registrazione con
pubblicazione del limite prima della lettura (stesso schema delle epoche,
[ADR-0016](0016-epoch-based-reclamation.md)); versione = numero di sequenza del commit
(etcd `mod_revision`, FoundationDB *versionstamp*).

## Conseguenze

- Un solo meccanismo per lotti e multiserie; l'insieme «in applicazione» di ADR-0020 e
  ADR-0021 non esiste più come struttura a sé.
- Costo condiviso tra Serie: un incremento atomico alla chiusura e un passaggio sotto mutex
  alla pubblicazione, per lotto. Nessun costo per i reader.
- La nascita di uno snapshot dipende dal flush più lento in corso nell'Archivio: è l'unico
  punto in cui una Serie può ritardarne un'altra, limitato nel tempo e dichiarato in
  [architettura](../architettura.md#archivio-coordinamento-minimo).
- Un campo in meno in record, hint e slot.

## Alternative considerate

- *Snapshot a `s = H` senza attesa:* non vedrebbe un commit appena confermato dallo stesso
  client.
- *Far attendere l'orizzonte a ogni conferma di scrittura:* snapshot immediati, ma ogni
  scrittura dipenderebbe dal flush di tutte le altre Serie (contro INV-P3).
- *Scansione del CSN più vecchio in volo per ogni Serie:* nessun mutex, ma costo proporzionale
  al numero di Serie a ogni snapshot.
- *Anello senza mutex:* possibile, ma richiede un argomento sull'ordinamento della memoria per
  non fermare l'orizzonte; il mutex è preso una volta per lotto e l'argomento scompare
  ([principi](../principi-di-ingegneria.md), condizione 4).

## Valutazione

- Rischi: RSK-05 (visibilità atomica) chiuso sul progetto.
- Verifica: modello in SPK-07 — due Serie, un lotto in volo, una multiserie, uno snapshot
  creato in ogni punto, una Serie che va in `FAULTED` con un CSN in volo; test di proprietà
  «due letture dello stesso snapshot danno lo stesso risultato» nel simulatore; FI-11, FI-12.
- Rivedere se: l'attesa alla nascita degli snapshot supera gli obiettivi di latenza delle
  transazioni ([ADR-0028](0028-target-e-obiettivi-di-latenza.md)).
