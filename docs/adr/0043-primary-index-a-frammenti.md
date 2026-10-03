# ADR-0043 — Primary index a frammenti: directory estendibile, slot a quattro parole, chiavi locali

- **Stato:** Accettata (capacità del frammento tarabile da SPK-01)
- **Data:** 2026-10-03
- **Rapporto con la specifica:** nessuna emenda; realizza «Index» (Swiss Table, strutture
  compatte, nessun oggetto per entry). **Sostituisce in parte**
  [ADR-0015](0015-primary-index-swiss-table-swmr.md) (tabella unica, key arena,
  ridimensionamento), [ADR-0032](0032-seqlock-a-64-bit.md) punto 2 (layout dello slot),
  [ADR-0016](0016-epoch-based-reclamation.md) (ambito dell'EBR) e
  [ADR-0024](0024-memoria-e-gc.md) punto 3 (crescita per sostituzione dell'intera struttura).
  Restano: un writer e reader senza lock, seqlock a 64 bit con tentativi limitati e ripiego
  sul writer, versioni trattenute, rilocazione condizionale, indice come dato derivato.
- **Riferimenti:** [analisi progettuale](../analisi-progettuale.md) AP-12, AP-16;
  [architettura](../architettura.md#primary-index); [limiti](../limiti.md); INV-I1, INV-I3,
  INV-A8

## Contesto

Una tabella unica che cresce per raddoppio ha tre difetti che l'analisi rende espliciti
(AP-12): durante la copia servono vecchia e nuova tabella insieme, cioè il **triplo** della
vecchia; il writer della Serie resta fermo per tutta la copia; lo spazio degli slot e delle
chiavi eliminate non si recupera mai, perché la key arena è solo in aggiunta. Su una Serie
grande il primo difetto rende il raddoppio impossibile entro la RAM, il secondo ferma le
scritture per secondi, il terzo viola INV-A8.

## Decisione

### 1. Struttura

```
Serie ──▶ directory (vettore di 2^G riferimenti) ──▶ frammento
                                                      ├─ ctrl   : byte di controllo (uno per slot)
                                                      ├─ slots  : 4 parole da 64 bit per slot, contigue
                                                      └─ chiavi : byte delle chiavi, in aggiunta
```

- **Hashing estendibile.** I `G` bit alti dell'hash a 64 bit scelgono la voce della
  directory; più voci possono indicare lo stesso frammento (profondità locale ≤ `G`).
- **Frammento**: tabella Swiss di capacità fissa `C` slot (default **8.192**: l'array degli
  slot supera la soglia degli oggetti grandi del collector, che quindi non lo copia), con un
  byte di controllo per slot e sondaggio per gruppi. Fattore di carico massimo 7/8.
- **Slot: 4 parole contigue** nello stesso array (32 byte: due slot per linea di cache).

  | Parola | Contenuto |
  |---|---|
  | 0 | CSN della versione corrente (è la versione, [ADR-0038](0038-orizzonte-di-visibilita.md)) |
  | 1 | segment-id (32) · offset (32) |
  | 2 | key-off (24) · key-len (8) · lunghezza del record (24) · flag (8) |
  | 3 | contatore seqlock (64) |

  L'hash non sta nello slot: i 7 bit del byte di controllo filtrano, il confronto della chiave
  decide, e alla divisione l'hash si ricalcola dalle chiavi.
- **Chiavi locali**: ogni frammento ha la propria area di chiavi, in aggiunta, immutabile dopo
  la pubblicazione dello slot che vi punta; cresce per sostituzione dell'array.

### 2. Crescita e pulizia: una divisione alla volta (INV-I3)

Quando un frammento raggiunge il fattore di carico massimo, il writer ne costruisce **due**
nuovi ridistribuendo le entry vive sul bit successivo dell'hash, e pubblica i riferimenti
nella directory. Se la profondità locale è già `G`, prima raddoppia la directory (copia di
riferimenti). La divisione copia solo entry vive: slot eliminati e chiavi non più
referenziate **non sopravvivono**. Un frammento con molti slot eliminati o con l'area chiavi
piena di chiavi morte, o il cui contatore seqlock più alto si avvicina alla soglia di
[ADR-0032](0032-seqlock-a-64-bit.md), viene **ricostruito** allo stesso modo senza dividersi:
il fail-stop per il contatore diventa una ricostruzione.

Costo massimo di una qualsiasi manutenzione dell'indice: la copia di `C` slot. Memoria
transitoria: due frammenti. Profondità massima della directory dichiarata; oltre, rifiuto
esplicito (INV-A8).

### 3. Concorrenza

- **Reader**: legge il riferimento alla directory, poi al frammento, poi sonda i gruppi; ogni
  slot è letto con il protocollo seqlock di ADR-0032 (lettura del contatore, dei campi, di
  nuovo del contatore). Un reader che ha già preso il riferimento a un frammento poi
  sostituito legge uno stato **congelato e coerente**: il writer non modifica più un
  frammento dopo averlo sostituito. La lettura è linearizzabile nell'istante in cui il
  riferimento è stato letto.
- **Byte di controllo**: passano da vuoto a occupato, da occupato a eliminato, da eliminato a
  occupato; **mai di nuovo a vuoto** dentro la vita di un frammento. Così un sondaggio non si
  ferma mai prima di uno slot che esisteva quando è partito.
- **Writer**: scrive la chiave nell'area chiavi; poi lo slot (contatore dispari, campi,
  contatore pari); poi il byte di controllo. All'eliminazione: slot marcato libero (flag)
  sotto seqlock, poi byte di controllo.
- **Area chiavi**: il reader ne legge il riferimento **dopo** aver letto lo slot; poiché il
  writer pubblica un'area più grande prima di scrivere lo slot che vi punta, l'area letta
  contiene sempre la chiave.

### 4. Una struttura, tre usi

La stessa tabella a frammenti, con larghezza dello slot parametrica, realizza:

| Uso | Slot | Letta da |
|---|---|---|
| indice primario | 4 parole | tutti i reader |
| versioni trattenute (più entry per chiave; in più: CSN di fine validità) | 5 parole | reader con snapshot |
| versioni in sospeso: lotti non pubblicati e intenti ([ADR-0037](0037-lotto-sigillato.md), [ADR-0041](0041-multiserie-segmenti-autosufficienti.md)) | 4 parole | solo il writer |

Una sola struttura concorrente di classe C1 da modellare, provare e sottoporre a mutazione.

### 5. Chi ritira che cosa

Directory e frammenti sostituiti sono oggetti dello heap: restano vivi finché un reader li
referenzia e poi li recupera il **garbage collector**. L'epoch-based reclamation di ADR-0016
governa solo le **risorse esterne**: descrittori e file dei segmenti rimossi.

Pattern: tabella Swiss (Abseil) dentro una directory a hashing estendibile con divisione di
una tabella alla volta (mappe di Go dalla versione 1.24; Fagin et al. 1979); seqlock (kernel
Linux).

## Conseguenze

- Nessuna pausa del writer proporzionale alla dimensione della Serie; nessun picco di memoria.
- Memoria: 33 byte per slot. A riempimento massimo ~38 byte per documento più la chiave;
  subito dopo una divisione il doppio. La media attesa è nell'ordine di **75–80 byte per
  documento** con `_id` da 16 byte: è una **stima**, da misurare (SPK-01). La cifra «56 byte»
  dei documenti precedenti valeva solo nell'istante prima di un raddoppio.
- Un salto di riferimento in più per lookup (directory → frammento), su strutture piccole e
  calde.
- I frammenti sono allocazioni del writer: rare, grandi, non sul percorso dei reader. Il
  tasso di allocazione dovuto alle divisioni entra nelle misure di SPK-02.

## Alternative considerate

- *Tabella unica con raddoppio (ADR-0015):* picco di memoria e fermo del writer.
- *Raddoppio incrementale con due tabelle vive:* ogni lookup può dover guardare due tabelle;
  resta un'unica allocazione enorme.
- *Slot a 8 parole con la chiave in linea:* una linea di cache per lookup con gli `_id`
  generati, ma due rappresentazioni della chiave da verificare.
- *EBR anche per i frammenti:* un secondo meccanismo per ciò che il collector fa già.

## Valutazione

- Rischi: RSK-02, RSK-07.
- Verifica: SPK-01 (lookup e inserimenti al secondo, byte per documento misurati, durata
  della divisione, correttezza sotto stress con divisioni continue); modello del seqlock e
  della divisione in SPK-07; test differenziale contro una tabella di riferimento.
- Rivedere se: la durata di una divisione o il costo del salto in più portano il lookup sotto
  i minimi di [ADR-0028](0028-target-e-obiettivi-di-latenza.md).
