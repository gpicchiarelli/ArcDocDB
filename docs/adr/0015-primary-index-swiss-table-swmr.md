# ADR-0015 — Primary index: tabella Swiss single-writer/multi-reader, seqlock per slot, versioni trattenute

- **Stato:** Accettata (precisa l'interpretazione di INV-I1 per il primary index); **sostituita in parte da [ADR-0032](0032-seqlock-a-64-bit.md)**: seqlock a 64 bit con tentativi limitati e layout dello slot a 6 parole (56 B per entry). Dove questo ADR dice 8 bit e 48 byte, vale ADR-0032. **Sostituita in parte anche da [ADR-0043](0043-primary-index-a-frammenti.md)** (directory di frammenti al posto della tabella unica e della key arena; slot a 4 parole), da [ADR-0039](0039-cornice-unica-dei-record.md) (hint) e da [ADR-0042](0042-tombstone-e-indice-dei-vivi.md) (ricostruzione per CSN massimo, non per lineage).
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-24 e QA-03; precisa «Index snapshot» per il
  primary index
- **Riferimenti:** [architettura](../architettura.md#primary-index),
  [formati su disco](../formati-su-disco.md#file-hint), INV-I1, INV-V3

## Contesto

Il primary index riceve una modifica per ogni scrittura, serve lookup O(1) a milioni di
operazioni al secondo da molti reader, deve far trovare agli snapshot le versioni non più
correnti, e viene rilocato in blocco dalla compaction mentre il writer lavora (tensioni T1 e
T3 dell'[analisi critica](../valutazione/analisi-critica.md)).

## Decisione

### Struttura

Tabella hash a **indirizzamento aperto con metadati di controllo separati** (layout Swiss
Table: un byte di controllo per slot con 7 bit di hash secondario, sondaggio per gruppi di 16
slot), con gli slot in **array specializzati paralleli** `(unsigned-byte 64)`: hash a 64 bit;
riferimento alla chiave nella key arena; location (segment-id, offset); lunghezza e versione;
CSN e contatore seqlock. Nessun oggetto Lisp per entry. ~48 byte per entry a fattore di
carico 7/8.

**Key arena:** array di byte append-only per Serie che contiene le chiavi; l'indice vi punta.
La verifica della chiave avviene in memoria.

### Concorrenza

- **Un writer** (il writer logico della Serie) muta la tabella.
- **Reader senza lock**: ogni slot ha un contatore **seqlock** a 8 bit; il writer lo
  incrementa a dispari prima di modificare lo slot e a pari dopo (con barriere di memoria); il
  reader legge il contatore, i campi, di nuovo il contatore, e riprova se dispari o cambiato.
  La lettura di uno slot è attesa-libera per il writer e priva di contesa tra reader. Otto bit
  bastano: un falso «uguale» richiederebbe 256 scritture sullo stesso slot durante una lettura
  di ~100 ns, mentre il writer non supera qualche milione di operazioni al secondo in totale.
- **Ridimensionamento**: il writer costruisce una nuova tabella e la pubblica con uno scambio
  atomico del riferimento; la vecchia è ritirata con epoch-based reclamation
  ([ADR-0016](0016-epoch-based-reclamation.md)). È l'«atomic swap» della specifica, applicato
  al livello della tabella.

INV-I1 per il primary index va letto così: *un reader non osserva mai uno stato intermedio di
una entry né di una tabella*; il meccanismo è il seqlock per slot più lo scambio della
tabella.

### Versioni trattenute (MVCC)

La entry contiene solo la versione **corrente**. Quando il writer sovrascrive un documento e
esiste almeno uno snapshot con CSN inferiore al CSN della nuova versione, registra la versione
precedente nella **tabella delle versioni trattenute** della Serie (hash map compatta
`chiave → elenco di (csn-da, csn-a, location, versione)`). Un reader con snapshot `s` usa la
entry corrente se `csn(corrente) ≤ s`, altrimenti cerca nelle versioni trattenute. Le voci si
eliminano quando nessuno snapshot attivo ha CSN inferiore a `csn-a`. Senza snapshot attivi il
costo è zero.

### Rilocazione da compaction

La compaction non sostituisce la tabella: emette al writer un lotto di **rilocazioni
condizionali** `(chiave, location-vecchia → location-nuova)`; il writer applica ciascuna solo
se la entry (o la versione trattenuta) punta ancora alla location vecchia (INV-V3). Poiché la
copia è identica all'originale e l'originale resta leggibile finché `OBSOLETE`, un reader è
corretto con entrambe le location durante la finestra.

### Persistenza

L'indice è un dato derivato. Ogni segmento chiuso ha un **file hint** (`<id>.hint`) con
chiave, versione, CSN, offset, lunghezza e tipo di ogni record, scritto alla chiusura o alla
produzione da compaction. Al riavvio l'indice si ricostruisce leggendo gli hint dei segmenti
`CLOSED` in ordine di lineage e scansionando il segmento `ACTIVE`; i segmenti privi di hint si
scansionano per intero.

Pattern: Swiss Table (Abseil); seqlock (kernel Linux); RCU/EBR per la sostituzione delle
strutture; hint file (Bitcask).

## Conseguenze

- Lookup senza lock e senza allocazione; costo di scrittura una manciata di store per slot.
- Memoria ~48 B/entry + chiavi: 1 miliardo di documenti ≈ 48 GB + arena. Limite di capacità
  per server da documentare; oltre, si scala con più server (fuori scope v1).
- Il riavvio è proporzionale al numero di documenti (lettura degli hint), non ai dati.
- Il writer logico è l'unico punto che tocca indice, versioni trattenute e rilocazioni: nessun
  protocollo tra più scrittori.

## Alternative considerate

- *Struttura persistente con condivisione strutturale:* snapshot O(1) ma oggetti con puntatori,
  lookup più lento, GC; contraria al requisito di compattezza.
- *Catena di versioni su disco:* I/O per le versioni vecchie e puntatori invalidati dalla
  rilocazione.
- *Lock in lettura/scrittura sulla tabella:* contesa tra reader e writer.

## Valutazione

- Rischi: RSK-02 chiuso sul progetto; residuo prestazionale verificato da SPK-01 (lookup/s,
  byte/entry, correttezza concorrente sotto stress); modello della rilocazione in SPK-07.
- Porterebbe a rivedere: throughput di lookup inferiore di un ordine di grandezza al target
  o errori di coerenza nel test concorrente.
