# Analisi progettuale

> Rilettura critica dell'intero progetto (specifica, ADR 0001–0035, architettura, formati,
> analisi dei guasti) eseguita il 2026-10-03 con quattro criteri: **robusta, snella, fattiva,
> elegante**. Ogni rilievo `AP-nn` indica che cosa diceva il progetto, perché non regge e quale
> decisione lo chiude. Le decisioni sono negli [ADR 0036–0045](adr/README.md#analisi-progettuale-fase-0-2026-10-03);
> il risultato consolidato è in [architettura.md](architettura.md) e
> [formati-su-disco.md](formati-su-disco.md). Nessun numero di prestazione in questo documento
> è una misura (INV-X2).

## Criteri

| Criterio | Significato operativo | Come si riconosce una violazione |
|---|---|---|
| **Robusta** | ogni invariante vale per costruzione in ogni interleaving e con un crash in ogni punto; ogni guasto del [modello](affidabilita/analisi-dei-guasti.md) ha una risposta definita | esiste un controesempio: una sequenza ammessa dal progetto che viola un invariante |
| **Snella** | un solo meccanismo per ogni problema; nessun campo, record, file, stato o struttura privo di una funzione che nessun altro svolge | lo si può togliere senza perdere una garanzia |
| **Fattiva** | ogni meccanismo è realizzabile con primitive di SBCL che esistono, a costo limitato, senza passi che richiedano memoria o tempo non disponibili | un passo richiede una primitiva assente, un'allocazione sul percorso caldo, una pausa o una memoria transitoria non limitate |
| **Elegante** | poche leggi generali da cui i casi particolari discendono; la stessa forma ricorre a ogni livello | un caso particolare ha una regola propria che non discende da una legge |

Un quinto criterio attraversa gli altri quattro e viene prima di tutti nella forma del sistema: il **parallelismo**. Una soluzione robusta, snella ed elegante che introduce un punto seriale tra Serie non è ammessa senza un ADR che lo dichiari ([Parallelismo](#parallelismo)).

## Esito

Il progetto regge nell'impianto: Serie indipendenti che lavorano in parallelo, storage
append-only, segmenti immutabili, un writer per Serie, reader senza lock, compaction
copy-on-write. L'analisi ha trovato **cinque difetti di
correttezza**, **sei punti non definiti**, **due limiti di fattibilità** e una serie di
**meccanismi ridondanti**. Tutti sono chiusi da dieci decisioni, che nel complesso *tolgono*
più di quanto aggiungono.

| Rilievo | Natura | Sintesi | Decisione |
|---|---|---|---|
| [AP-01](#ap-01) | difetto | uno snapshot può vedere comparire un lotto che era in volo alla sua creazione (viola INV-M1) | [ADR-0038](adr/0038-orizzonte-di-visibilita.md) |
| [AP-02](#ap-02) | difetto | il CSN preso a inizio lotto può invertire l'ordine causale con una multiserie | [ADR-0037](adr/0037-lotto-sigillato.md), [ADR-0038](adr/0038-orizzonte-di-visibilita.md) |
| [AP-03](#ap-03) | difetto | un crash ordinario con più lotti in volo è classificato «corruzione a metà log» | [ADR-0037](adr/0037-lotto-sigillato.md) |
| [AP-04](#ap-04) | difetto | la regola dei tombstone per lineage fa riapparire documenti eliminati | [ADR-0042](adr/0042-tombstone-e-indice-dei-vivi.md) |
| [AP-05](#ap-05) | difetto | il CLEAN può scartare un record OUTCOME ancora necessario: dati committed persi al riavvio | [ADR-0041](adr/0041-multiserie-segmenti-autosufficienti.md) |
| [AP-06](#ap-06) | non definito | conferma di una multiserie prima della sua visibilità | [ADR-0041](adr/0041-multiserie-segmenti-autosufficienti.md) |
| [AP-07](#ap-07) | non definito | protocollo del registro degli snapshot (gara tra creazione e sovrascrittura) | [ADR-0038](adr/0038-orizzonte-di-visibilita.md) |
| [AP-08](#ap-08) | non definito | coda troncata dei log di controllo; verifica in lettura dei record prepared; CSN «dopo» la decisione ma «dentro» il record | [ADR-0037](adr/0037-lotto-sigillato.md), [ADR-0039](adr/0039-cornice-unica-dei-record.md), [ADR-0041](adr/0041-multiserie-segmenti-autosufficienti.md) |
| [AP-09](#ap-09) | non definito | concorrenza della cache; la ri-etichettatura la lega alla compaction | [ADR-0044](adr/0044-cache-acceleratore-puro.md) |
| [AP-10](#ap-10) | non definito | passaggio di una lettura dal pool di calcolo al pool di I/O; che cosa blocca chi | [ADR-0045](adr/0045-modello-di-esecuzione.md) |
| [AP-11](#ap-11) | non definito | il Bloom filter sulle chiavi non ha alcuna funzione | [ADR-0042](adr/0042-tombstone-e-indice-dei-vivi.md), [ADR-0039](adr/0039-cornice-unica-dei-record.md) |
| [AP-12](#ap-12) | fattibilità | il raddoppio della tabella dell'indice richiede il triplo della memoria e ferma il writer per secondi; la key arena cresce senza limite | [ADR-0043](adr/0043-primary-index-a-frammenti.md) |
| [AP-13](#ap-13) | fattibilità | il CRC dell'intero record è calcolato dentro il writer; un TXID di Archivio per ogni operazione | [ADR-0039](adr/0039-cornice-unica-dei-record.md) |
| [AP-14](#ap-14) | ridondanza | control log con sette tipi di record; distruzione «per assenza»; recovery che tronca | [ADR-0040](adr/0040-manifest-a-record-unico.md), [ADR-0036](adr/0036-leggi-di-progetto.md) |
| [AP-15](#ap-15) | ridondanza | versione del documento e CSN sono due numeri per lo stesso fatto | [ADR-0038](adr/0038-orizzonte-di-visibilita.md) |
| [AP-16](#ap-16) | ridondanza | EBR per strutture che il collector già ritira | [ADR-0043](adr/0043-primary-index-a-frammenti.md) |

## Le leggi

L'eleganza cercata è questa: **dieci leggi**, e ogni meccanismo del sistema è l'applicazione
di una di esse a un livello. Sono normative ([ADR-0036](adr/0036-leggi-di-progetto.md)); gli
invarianti che le rendono verificabili sono indicati tra parentesi.

1. **Il parallelismo è fondante.** Lo stato è diviso in unità che procedono senza attendersi:
   gli Archivi, le Serie di un Archivio, i reader tra loro e rispetto al writer, i segmenti
   nella compaction, nel recovery e nelle query. Ciò che resta condiviso è un elenco chiuso,
   con costo limitato e mai pagato per singola operazione. Non è un'ottimizzazione: è la forma
   del sistema, e ogni meccanismo si giudica anzitutto da ciò che rende seriale (INV-P1…P4,
   INV-P6, INV-W1).
2. **Si scrive una volta.** Un byte scritto non si modifica; un file chiuso non cambia più; il
   recovery non modifica e non tronca ciò che trova (INV-S1, INV-S4, INV-A9).
3. **Un solo scrittore.** Ogni stato ha un proprietario unico che lo muta in un ordine totale:
   il writer logico per la Serie, il coordinatore per `multiserie.log`. Gli altri *propongono*
   (INV-P1, INV-V4).
4. **Un punto di atomicità per operazione.** Ogni cambiamento durevole è deciso da **un**
   record durevole. Prima c'è solo preparazione scartabile; dopo, solo completamento
   idempotente (INV-A11).
5. **Prepara, decidi, completa.** Ciò che si prepara ha nome `.tmp`; la decisione è un record
   nella fonte di verità; il file system si allinea dopo, e il recovery ripete l'allineamento
   (INV-A7, INV-A11).
6. **Nulla si distrugge per assenza.** Si elimina solo ciò che è `.tmp` o di cui una fonte di
   verità registra la rimozione. Un oggetto sconosciuto è un'anomalia segnalata, non spazzatura
   (INV-A10).
7. **Una versione nasce in sospeso, diventa durevole, poi pubblicata; solo allora è
   confermata.** Lo stesso ciclo vale per il lotto di una Serie e per la multiserie, che ha
   soltanto una sospensione più lunga (INV-V1, INV-V5).
8. **Il CSN è l'unico ordine e l'unico nome.** Ordina i commit, definisce che cosa vede uno
   snapshot, identifica la versione di un documento. Uno snapshot nasce quando l'orizzonte lo
   ha raggiunto (INV-M4, INV-M5).
9. **Verifica prima di fidarti, e dichiara.** Ogni dato che attraversa un confine (disco,
   cache, rete) è verificato; ciò che non verifica non esce; un guasto ferma, non indovina
   (INV-A1, INV-A2, INV-F1…F3).
10. **Tutto è limitato, e chi governa non decide.** Ogni risorsa ha un tetto controllato; lo
    scheduler sceglie numeri dentro intervalli verificati e non può cambiare un dato (INV-A8,
    INV-P5).

Le leggi 1 e 3 sono la stessa divisione vista da due lati: l'unità di parallelismo (la Serie)
è anche l'unità di proprietà dello stato. Per questo il parallelismo non costa garanzie, e la
gerarchia delle priorità di [ADR-0031](adr/0031-software-critico-criteri-e-priorita.md) resta
intatta.

## Parallelismo

Il parallelismo è **principio fondante** per decisione dell'autore (2026-10-03) e per la
specifica, che lo mette nell'obiettivo («forte parallelismo tra Serie indipendenti») e lo
vuole gerarchico. La gerarchia, livello per livello:

| Livello | Unità di parallelismo | Procede in parallelo | Che cosa resta seriale, e dove |
|---|---|---|---|
| Server | Archivio | ogni Archivio ha CSN, orizzonte, coordinatore e log propri | nulla tra Archivi |
| Archivio | Serie | scritture, letture, flush, compaction e recovery di Serie diverse | l'[elenco chiuso](architettura.md#archivio-coordinamento-minimo), pagato per lotto, per multiserie o per snapshot |
| Serie | reader, writer | i reader tra loro e rispetto al writer, senza lock | le mutazioni: un writer |
| Scrittura | richiesta | parsing, validazione, codifica e CRC del corpo, nei worker | controllo di versione, copia e sigillo, nel writer |
| Log | lotto | i flush di log diversi; il writer forma lotti mentre il flush è in corso | un compito di I/O per log |
| Compaction | segmento | CLEAN e MERGE su segmenti e Serie diversi; i reader non si fermano | l'EDIT e le rilocazioni, proposti al writer |
| Recovery | Serie, segmento | le Serie tra loro; gli hint di una Serie in qualsiasi ordine | nulla |
| Query | segmento | gli indici dei segmenti di una Serie | nulla |
| Indice | frammento | la divisione di un frammento non ferma i reader né gli altri frammenti | la divisione stessa, nel writer |

Che cosa le decisioni di questa analisi danno al parallelismo:

- **tolta** una scrittura condivisa da tutte le Serie a ogni operazione (il TXID di Archivio,
  AP-13): resta un CSN per lotto;
- **tolto** dal writer il lavoro proporzionale ai byte (il CRC del corpo, AP-13): la parte
  seriale di una Serie non cresce con la dimensione dei documenti;
- l'attesa dell'orizzonte sta alla **nascita dello snapshot**, non alla conferma delle
  scritture (AP-01): una Serie non aspetta mai il flush di un'altra per scrivere o leggere;
- la ricostruzione dell'indice **non dipende dall'ordine** dei segmenti (AP-04): il recovery
  è parallelo anche dentro la Serie;
- la crescita dell'indice **non ferma** writer e reader (AP-12); hint e indici di un segmento
  chiuso si costruiscono fuori dal writer (AP-14); il writer non scrive nella cache (AP-09);
- nessun worker di calcolo si blocca, e una lettura non attraversa alcuna coda comune (AP-10).

Che cosa il progetto non può rendere parallelo, e dichiara: il dispositivo, i worker e il
garbage collector di SBCL, che ferma ogni thread (RSK-01).

## Punti di atomicità

La legge 4 applicata a tutte le operazioni del sistema. Il recovery è, per ogni riga: *scarta
ciò che sta prima, completa ciò che sta dopo* — per questo è idempotente senza logica propria.

| Operazione | Preparazione (scartabile) | **Punto di atomicità** | Completamento (idempotente) |
|---|---|---|---|
| Scrittura single-Series | record del lotto nel buffer e nel file | **SEAL del lotto durevole** | pubblicazione nell'indice, conferma |
| Transazione multiserie | record prepared sigillati nei partecipanti | **DECISION durevole in `multiserie.log`** | applicazione, record OUTCOME, conferma |
| Rotazione dell'`ACTIVE` | nuovo segmento `.tmp` | **EDIT nel control log** | rinomina |
| CLEAN / MERGE | segmento di output `.tmp` con hint e indici | **EDIT nel control log** | rinomina, rilocazioni, ritiro ed eliminazione dei sorgenti |
| Recovery di una Serie | sola lettura; nuovo `ACTIVE` e control log compattato `.tmp` | **rinomina del control log compattato** (il suo EDIT chiude il vecchio `ACTIVE` alla lunghezza valida, con gli esiti) | rinomina del nuovo `ACTIVE` |
| Creazione di una Serie | directory `.tmp` completa | **documento nel catalogo** | rinomina |
| Eliminazione di una Serie | — | **documento nel catalogo in stato `dropping`** | rimozione della directory, tombstone |
| Compattazione di un log di controllo | nuovo file `.tmp` | **rinomina atomica** | — |

## Rilievi

### AP-01

**Uno snapshot vedeva comparire i lotti in volo.** [ADR-0020](adr/0020-csn-snapshot-isolamento.md)
assegnava il CSN al lotto *prima* del flush (il CSN sta nel record) e
[ADR-0019](adr/0019-durability-e-group-commit-pipelined.md) pubblicava il lotto *dopo* il flush.
La creazione di uno snapshot prendeva `s ← CSN corrente` e attendeva solo le multiserie «in
applicazione».

*Controesempio.* La Serie A chiude un lotto con CSN 10 e avvia il flush. La Serie B committa
con CSN 11 e pubblica. Nasce uno snapshot con `s = 11`: legge il documento X della Serie A e
ne vede la versione vecchia. Il flush di A termina, il lotto 10 è pubblicato: lo stesso
snapshot rilegge X e vede la versione nuova (10 ≤ 11). La vista è cambiata: INV-M1 è violato.

*Soluzione.* L'**orizzonte di visibilità** `H`: il più grande CSN tale che ogni commit con
CSN ≤ `H` è pubblicato. Uno snapshot prende `s` e nasce quando `H ≥ s`. Lotti e multiserie
usano lo stesso meccanismo: l'insieme «in applicazione» scompare come concetto a sé.

### AP-02

**Il CSN preso all'inizio del lotto poteva invertire la causalità.** Il writer apre un lotto e
prende il CSN 20; poi applica l'esito di una multiserie T con CSN 21 su X; poi, nello stesso
lotto, accetta un aggiornamento di X che ne dipende. La versione successiva porta 20, la
precedente 21: uno snapshot a 20 vede l'effetto senza la causa, e non vede T sulle altre Serie.

*Soluzione.* Il CSN di un lotto si prende **alla chiusura**, cioè quando si scrive il SEAL.
Poiché un intento blocca le altre scritture sullo stesso documento fino all'esito, ne discende
INV-M5: per ogni documento, ordine dei CSN = ordine delle versioni.

### AP-03

**Un crash ordinario diventava un guasto.** Con più lotti in volo sullo stesso file
(ADR-0019) il sistema operativo può aver reso persistente il lotto N+1 e non il lotto N — è il
punto 2 del modello dei guasti. La regola di [ADR-0033](adr/0033-fail-stop-e-integrita-end-to-end.md)
§4 («un record valido dopo un'anomalia = corruzione a metà log») portava allora la Serie in
`FAULTED` dopo una normale perdita di alimentazione. Inoltre la stessa sezione dichiarava
«sempre corruzione» un record non valido in `control.log` e `multiserie.log`, dove invece un
append interrotto produce una coda legittima.

*Soluzione.* Il **lotto sigillato** e la **frontiera durevole**: ogni SEAL registra fino a
dove il log era durevole quando il lotto è stato chiuso. Un'anomalia in `P` è corruzione solo
se un SEAL valido successivo testimonia una frontiera `> P`; altrimenti è una coda. La
decisione dipende dal contenuto del log, non da come il supporto ordina le scritture. Tutti i
log (segmento `ACTIVE`, control log, `multiserie.log`) sono sequenze di lotti sigillati con un
flush alla volta: un solo meccanismo, tre istanze.

*Limite dichiarato.* Resta indistinguibile da una coda il danno, avvenuto a riposo, ai soli
lotti resi durevoli dall'ultimo flush prima di un arresto improvviso e non ancora testimoniati
da un lotto successivo ([RES-05](affidabilita/analisi-dei-guasti.md#rischi-residui-accettati)).

### AP-04

**La regola dei tombstone non era sicura.** [ADR-0023](adr/0023-politiche-di-compaction.md):
un tombstone in un segmento con lineage `L` si scarta quando nessun segmento ha
`lineage-min < L`.

*Controesempio.* Segmenti 3, 5, 7; il 5 contiene `PUT k`; il 7 contiene `TOMBSTONE k`. Un
MERGE dei segmenti piccoli 3 e 7 (il 5 non è piccolo) produce un segmento con
`lineage-min = 3`: il tombstone ora «ha» lineage 3. Al CLEAN successivo nessun segmento ha
lineage inferiore a 3, il tombstone è scartato. Il segmento 5 contiene ancora `PUT k`: al
riavvio l'indice si ricostruisce e **k riappare**. La variante sicura della regola (lineage
massimo) non scarterebbe quasi mai.

*Soluzione.* Tre cambi che si reggono a vicenda: (1) l'indice in memoria contiene **solo
documenti vivi** (un'eliminazione toglie la entry: nessuna memoria spesa per i documenti
eliminati); (2) la ricostruzione sceglie per ogni chiave il **CSN massimo**, e non dipende
dall'ordine dei segmenti; (3) un tombstone si scarta quando **nessun altro segmento può
contenere un record più vecchio della stessa chiave**, verificato con il filtro di esistenza
(Bloom) e il CSN minimo di ogni segmento. Il lineage scompare da formati e manifest.

### AP-05

**Un OUTCOME poteva sparire prima dei record che risolve.** I record prepared di T stanno nel
segmento 5; la rotazione porta l'OUTCOME nel segmento 6; la decisione, ormai «dimenticabile»,
è troncata da `multiserie.log`. L'elenco dei record che il CLEAN conserva non comprendeva gli
OUTCOME: un CLEAN del 6 lo elimina. Se l'hint del 5 va rigenerato, i record prepared non hanno
più esito: *presumed abort* → **dati committed persi**.

*Soluzione.* **Segmenti autosufficienti**: la rotazione attende che non ci siano intenti
pendenti, quindi l'esito di ogni record prepared sta nello stesso segmento; per l'`ACTIVE`
chiuso da un recovery, gli esiti stanno nel record di chiusura del manifest. Un segmento
`CLOSED` si interpreta da solo (INV-S7). Scompaiono il record PREPARE (il SEAL e il flag
bastano), la decisione ABORT e l'OUTCOME ABORT (*presumed abort*: l'assenza di un COMMIT è
l'abort).

### AP-06

**Confermata ma non ancora visibile.** La multiserie era confermata al client quando la
decisione era durevole, prima dell'applicazione ai partecipanti: un GET successivo alla
conferma poteva non vederla. *Soluzione:* legge 7 — si conferma dopo la pubblicazione su tutti
i partecipanti sani; il costo è l'applicazione in memoria.

### AP-07

**Il registro degli snapshot non aveva un protocollo.** Il writer decide se trattenere la
versione che sovrascrive guardando «gli snapshot attivi»; se uno snapshot si registra mentre
il writer decide, la versione che gli serve può non essere trattenuta. *Soluzione:* la
registrazione pubblica **prima** un limite inferiore (`soglia`), **poi** legge il CSN, con una
barriera di memoria completa tra le due; il writer trattiene quando `soglia < CSN nuovo`. La
decisione è conservativa per costruzione: nel dubbio si trattiene.

### AP-08

**Tre incoerenze di dettaglio.** (a) La coda dei log di controllo: vedi AP-03. (b) La
verifica in lettura confrontava il CSN del record con l'indice, ma un record prepared porta
CSN zero: regola ora definita in [formati](formati-su-disco.md#verifica-in-lettura). (c)
ADR-0020 assegnava il CSN di una multiserie «dopo» che la decisione era durevole, ma il CSN è
un campo del record della decisione: ora è assegnato alla chiusura del lotto che contiene la
decisione, e resta fuori dall'orizzonte finché non è applicato.

### AP-09

**La cache partecipava alla coerenza.** La ri-etichettatura delle entry alla rilocazione
faceva scrivere al writer una struttura in cui inseriscono molti reader, senza un protocollo
definito. *Soluzione:* la cache è una **funzione pura** `location → byte`: non si invalida,
non si ri-etichetta, non si svuota. I reader la leggono con lo stesso seqlock dell'indice; in
caso di contesa il ripiego è un *miss*. Il sistema è corretto con la cache disattivata
(INV-A12).

### AP-10

**Chi si blocca, e dove.** Il percorso di lettura passava dal pool di calcolo al pool di I/O
senza dire come, e teneva un'epoca attraverso il passaggio. *Soluzione:* **compiti a
completamento**. Un compito non si sospende mai a metà; una lettura che deve andare su disco
*migra* al pool di I/O **ripartendo dall'inizio** (nessuno stato attraversa il passaggio);
un'attesa è un parcheggio in una lista limitata. È questa proprietà a rendere possibile il
simulatore deterministico in Common Lisp senza continuazioni.

### AP-11

**Un file senza funzione.** Il file `.bloom` conteneva le chiavi `_id` del segmento, ma
nessuna lettura cerca una chiave per segmento: l'indice primario è in memoria ed è completo.
La specifica chiede il Bloom per i *valori* degli indici secondari. *Soluzione:* il filtro
sulle chiavi diventa una sezione dell'hint e trova la sua funzione nello scarto dei tombstone
(AP-04); i filtri sui valori diventano una sezione dei file di indice. Un file in meno per
segmento.

### AP-12

**L'indice non poteva crescere.** Una tabella unica che raddoppia richiede, durante la copia,
vecchia e nuova insieme: tre volte la vecchia. Una Serie da 300 milioni di documenti avrebbe
bisogno di ~80 GB transitori, e il writer resterebbe fermo per tutta la copia (secondi). La
cifra «56 byte per entry» valeva solo nell'istante prima del raddoppio. Inoltre la key arena,
solo in aggiunta, non recuperava mai lo spazio delle chiavi eliminate (contro INV-A8).

*Soluzione.* **Directory di frammenti** (hashing estendibile): frammenti di dimensione fissa,
ciascuno una piccola tabella Swiss con le proprie chiavi; un frammento pieno si divide in due.
Il costo di una crescita è la copia di un frammento (frazioni di millisecondo), la memoria
transitoria è un frammento, lo spazio di chiavi e slot eliminati si recupera alla divisione.
Lo slot scende da sei a **quattro parole** (la versione è il CSN, l'hash non serve nello
slot, le chiavi sono locali).

### AP-13

**Lavoro per byte dentro il writer.** Versione e CSN stavano nell'intestazione coperta
dall'unico CRC: il CRC di tutto il record andava calcolato dopo la loro assegnazione, cioè
dal writer — microsecondi per documento, proprio dove il tempo è contato. *Soluzione:* **due
CRC**. Quello del corpo (chiave e documento) è calcolato dal worker che riceve la richiesta;
il writer calcola solo quello dell'intestazione, 20 byte, che copre anche il CRC del corpo.
Inoltre ogni operazione riceveva un TXID da un contatore di Archivio, cioè una scrittura
condivisa per operazione: ora il lotto è atomico per posizione (tutto ciò che precede il
SEAL), e il TXID esiste solo per le multiserie.

### AP-14

**Più stati su disco di quanti ne servano.** Il control log aveva sette tipi di record
(`SEG-OPEN`, `SEG-CLOSE`, `SWAP`, `SEG-OBSOLETE`, `SEG-RECLAIMABLE`, `SEG-DELETED`,
`CHECKPOINT`), ma l'unico fatto durevole è *quali segmenti fanno parte della Serie*.
*Soluzione:* un solo record, **EDIT** `{apre, chiude, rimuove}`; `OBSOLETE` e `RECLAIMABLE`
sono stati in memoria; un checkpoint è un EDIT che dichiara tutto. Il recovery non tronca più
la coda dell'`ACTIVE`: lo chiude con la sua lunghezza valida e ne apre uno nuovo (legge 2).
L'eliminazione di file «non menzionati» è sostituita dalla legge 6.

### AP-15

**Due numeri per un fatto.** Ogni versione portava un contatore per documento *e* il CSN. Il
contatore ripartiva dopo l'eliminazione definitiva di un documento, esponendo il controllo
ottimistico a un falso successo (stesso numero, altra incarnazione). *Soluzione:* **la
versione è il CSN**. È unico, crescente, non riparte mai. Un campo in meno nel record,
nell'hint e nello slot.

### AP-16

**Due collector.** L'EBR ritirava anche tabelle e frammenti, che sono oggetti dello heap: il
garbage collector li tiene vivi finché un reader li referenzia e li recupera dopo. *Soluzione:*
l'EBR governa solo le risorse esterne (descrittori e file dei segmenti).

## Bilancio

| Elemento | Prima | Dopo |
|---|---|---|
| Tipi di record nel segmento | 5 | 4 (PUT, TOMBSTONE, SEAL, OUTCOME) |
| Tipi di record nel control log | 7 | 1 (EDIT) |
| Tipi di record in `multiserie.log` | 3 | 1 (DECISION) |
| Cornici di record distinte | 3 | 1 |
| Intestazione del record | 40 byte | 24 byte |
| Entry dell'hint | 32 byte | 24 byte |
| File per segmento | `.seg` `.hint` `.bloom` `.idx` | `.seg` `.hint` `.idx` |
| Slot del primary index | 6 parole + 1 byte | 4 parole + 1 byte |
| Numeri che identificano una versione | versione, CSN, TXID | CSN (TXID solo per le multiserie) |
| Scritture condivise di Archivio per operazione | un TXID | nessuna (un CSN per lotto) |
| Stati durevoli di un segmento | 5 | appartenenza all'insieme |
| Stati DDL nel catalogo | `creating` `active` `dropping` | `active` `dropping` |
| Strutture concorrenti da verificare | tabella, arena, versioni trattenute, tabella della cache | una tabella a frammenti (tre usi) e un insieme associativo, stesso seqlock |
| Meccanismi di ritiro | EBR per file e strutture | EBR per i file; il collector per le strutture |
| Ciò che le Serie condividono | non enumerato | elenco chiuso, con costo e frequenza dichiarati |
| Lineage, timestamp nel manifest, ri-etichettatura della cache, record PREPARE, ABORT | presenti | rimossi |

## Fattibilità in SBCL

Ogni meccanismo poggia su una primitiva che esiste. La colonna «Stato» riporta ciò che è stato
controllato il 2026-10-03 su SBCL 2.6.9, macOS/ARM64: è una verifica di **presenza e di codice
generato**, non di prestazioni; le prestazioni restano agli spike.

| Meccanismo | Primitiva | Stato |
|---|---|---|
| Parole lette e scritte in modo atomico | `aref` su `(simple-array (unsigned-byte 64) (*))` | una sola istruzione di carico per parola con `(safety 2)`, controllo dei limiti presente; da ripetere su x86-64 (SPK-01) |
| Barriere del seqlock | `sb-thread:barrier` | presente; su ARM64 emette l'istruzione di barriera |
| Contatore CSN, crediti | `sb-ext:atomic-incf` su slot di struttura e su array di parole | presente |
| Scambi atomici (riferimenti, parole) | `sb-ext:compare-and-swap` su `svref`, slot di struttura, array di parole | presente |
| Acquisizione senza attesa | `sb-thread:with-mutex (… :wait-p nil)` | presente |
| Flush durevole, rinomina, lock | `sb-posix`: `fdatasync`, `fsync`, `rename`, `fcntl`, `lockf` | presenti |
| Letture e scritture posizionali | `pread`, `pwrite` tramite `sb-alien` | **non** in `sb-posix`: definizione aliena verso la libc ([ADR-0017](adr/0017-piattaforma-e-io.md)); SPK-05 |
| Frammenti non copiati dal collector | array specializzati oltre la soglia degli oggetti grandi (256 KiB su questa piattaforma) | la capacità del frammento è scelta di conseguenza; pause da misurare (SPK-02) |
| Simulazione deterministica | compiti a completamento su uno scheduler iniettato | non richiede continuazioni né thread ([ADR-0045](adr/0045-modello-di-esecuzione.md)) |
| CRC32C | tabellare in Common Lisp tipizzato | costo da misurare (SPK-09) |

Due dipendenze dalla piattaforma che gli spike devono misurare e che questa analisi rende
esplicite: la pausa del collector in funzione del **numero di thread** (ogni worker di I/O in
più è un thread da fermare a ogni collezione), e il costo della divisione di un frammento sotto
carico.

## Che cosa non cambia

La specifica, salvo la numerazione delle versioni (AP-15). Il modello logico, lo storage
append-only, CLEAN e MERGE con le loro condizioni, i livelli di durability, il 2PC con writer
non bloccante, gli indici secondari per segmento, lo scheduler dinamico, il fail-stop, la
strategia di verifica. Le dieci decisioni rifiniscono i meccanismi; nessuna sposta un confine
dell'architettura.

## Limiti che restano

- **Costo delle query sugli indici secondari.** Cresce con il numero di segmenti della Serie
  (~4.000 per TB): è il prezzo degli indici per segmento, decisione dell'autore
  ([ADR-0026](adr/0026-indici-secondari-segmentati.md)). I filtri di esistenza sui valori lo
  riducono per le uguaglianze, non per gli intervalli. Resta in [limiti.md](limiti.md) come
  limite dichiarato e come primo candidato a una misura.
- **L'orizzonte accoppia le Serie nella sola nascita degli snapshot**: una Serie con un flush
  lento ritarda gli snapshot dell'Archivio, mai le letture e le scritture delle altre Serie.
  L'attesa è limitata e una Serie `FAULTED` libera subito l'orizzonte. È l'unico punto in cui
  la legge 1 cede a una garanzia superiore (INV-M1), ed è dichiarato nell'elenco chiuso.
- **Danno a riposo dell'ultimo flush** (AP-03): dichiarato, non eliminabile.
