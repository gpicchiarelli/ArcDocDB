# Recovery readonly del vecchio ACTIVE

Il risultato conserva anche il marker privato del replay DECISION usato,
senza trattenere la tabella. Il [piano CSN dell'Archivio](csn-archivio-recovery.md)
confronta questa provenienza prima di aggregare le Serie.

Il modulo [`src/recovery-active/`](../../src/recovery-active/) collega il
[control log recuperato](control-recuperato.md) alla chiusura del vecchio
ACTIVE, secondo [ADR-0037](../adr/0037-lotto-sigillato.md#4-il-recovery-non-tronca-inv-a9),
[ADR-0040](../adr/0040-manifest-a-record-unico.md#3-riconciliazione-al-riavvio) e
[ADR-0041](../adr/0041-multiserie-segmenti-autosufficienti.md#4-recovery).
La lunghezza valida e gli esiti da registrare provengono ora dal file letto
e dalla tabella delle decisioni dell'Archivio.

## API

| API | Risultato |
|---|---|
| `leggi-active-recuperato(control, input, size, decisions, scratch, …)` | vecchio ACTIVE readonly, prefisso verificato e prepared risolti |
| `frontiere-active-recuperato(result)` | EOF attestato, P assoluto, `:complete`/`:tail`, formato 1/2 |
| `statistiche-active-recuperato(result)` | lotti, record esclusi SEAL, TXID prepared distinti, commit locali, commit derivati, abort |
| `segmento-active-recuperato(result)` | capacità opaca del vecchio segmento, senza trasferire ownership |
| `esito-chiusura-active(result, txid)` | presenza e CSN **da DECISION da inserire nell'EDIT**, `nil/0` se assente |
| `lunghezza-chiusura-active(result)` | byte esatti della entry CLOSED, esclusi gli altri campi dell'EDIT |
| `scrivi-chiusura-active(result, output, start)` | entry CLOSED deterministica con ID, P ed esiti derivati ordinati |
| `pubblica-control-da-active(prepared, result)` | verifica la chiusura ricavata dalla scansione e delega al publisher canonico |

Un esito assente nella query non significa abort: può già esserci un OUTCOME
nel segmento. I CSN zero presenti e tutti i bit u64 di ID/TXID/CSN sono
significativi. Nessun buffer, array, hash table o FD numerico è esportato.

## Autorità e ownership

Il compito si esegue nel pool I/O durante il recovery esclusivo della Serie.
`control` è il risultato della lettura del control log dal catalogo; da quel
manifest proviene l'ID dell'ACTIVE. L'header letto dalla stessa capacità
readonly verifica Serie, ID, CRC, riservati e versione. L'origine deve essere
writer, controllata prima di leggere il corpo.

Il chiamante attesta `size` come **EOF fisico completo e stabile**, mantiene
aperti control log e segmento, e congela file/FD/namespace fino alla pubblicazione.
Readonly non impedisce una mutazione esterna. La dimensione fisica e la
riconciliazione dell'inventario restano responsabilità del controller.

`decisions` è obbligatoriamente la tabella completa e autorevole di
`Registri/multiserie.log` **dello stesso Archivio**, con header già verificato.
Il tipo esistente della tabella non conserva l'identità dell'Archivio: il
collegamento e la completezza restano precondizioni esplicite. Una tabella
parziale, di un altro Archivio o costruita solo per rappresentare «nessuna
decisione» non autorizza presumed abort. Non esiste fallback da `nil`.

Il nuovo ingresso [`leggi-active-con-decisioni`](decisioni-recuperate.md)
riceve il risultato completo del lettore readonly del decision log e
verifica lo stesso ambito canonico dell'Archivio prima dell'I/O ACTIVE.
La precondizione sulla tabella nuda resta per l'API precedente.

Il risultato trattiene control log recuperato, capacità del segmento e
scalari; gli esiti derivati occupano due array u64 privati. Non trattiene
scratch, workspace o tabella dell'Archivio. Il controller mantiene il FD
del vecchio segmento fino al reclaim previsto da EBR; nessun close implicito.

## Ordine della lettura

1. Preflight senza I/O: capacità, alias dello scratch, range e budget completi.
2. Verificare che vecchio segmento e control log siano file fisicamente
   distinti nello stesso backend, con la primitiva I/O esistente.
3. Creare la capacità GET dall'header letto dallo stesso FD; rifiutare
   origine compaction. L'header viene letto una sola volta.
4. Leggere il corpo fino a EOF per chunk, senza rileggere l'header.
5. Usare lo scanner esistente sull'**intero file**. CRC, SEAL, file-id,
   frontiere e ricerca dei testimoni precedono qualsiasi semantica.
6. Attraversare soltanto il prefisso verificato: header ricontrollati,
   body già coperti dal primo passaggio CRC e buffer ancora esclusivo.
7. Risolvere i TXID prepared, controllare i conteggi, ordinare e copiare
   gli esiti da conservare; consegnare solo un risultato completo.

Una coda resta sul file ed è ignorata oltre P; non viene troncata. Un SEAL
testimone di corruzione durevole, un budget esaurito o una contraddizione
semantica propagano condizioni tipizzate al controller per fail-stop.
Non viene pubblicato un risultato parziale o un record della coda.

## Risoluzione dei prepared

| OUTCOME nel prefisso | DECISION autorevole | Risoluzione |
|---|---|---|
| presente | assente | committed locale; la decisione può essere già dimenticata |
| presente | presente, stessa Serie e stesso CSN | committed locale, nessun esito duplicato nell'EDIT |
| assente | presente, Serie partecipante | committed; coppia TXID/CSN da registrare nella chiusura |
| assente | assente | presumed abort, nessun esito scritto |
| qualsiasi | presente ma partecipante/CSN incoerente | corruzione, nessuna pubblicazione |

Le operazioni prepared dello stesso TXID devono appartenere a un solo lotto
([ADR-0041](../adr/0041-multiserie-segmenti-autosufficienti.md#1-protocollo)).
Un prepared che segue un OUTCOME per lo stesso TXID è rifiutato, come nel
[resolver CLOSED](get-resolver.md). Duplicati OUTCOME con lo stesso CSN sono
coalescenti; un CSN differente è corruzione. Gli OUTCOME senza prepared in
questo segmento non creano effetti o esiti di chiusura da soli.

Il controllo visita i TXID distinti: ciascuno è classificato una volta.
`prepared = locali + derivati + abort` è verificato prima del risultato.
Il formato dei documenti resta opaco; questa API non verifica schema/CBOR
o ricostruisce il primary index.

## Chiusura e pubblicazione

La entry CLOSED è esattamente `20 + 16 × E` byte: ID u64, P u64, count u32,
poi coppie TXID/CSN ordinate per TXID. Le dimensioni e gli offset provengono
dalle costanti del codec esistente. Il writer del checkpoint conserva gli
altri CLOSED e REMOVED e costruisce un EDIT completo con questa entry.

Il serializer verifica alias, forma e tutto il range prima della prima
scrittura in memoria. Il packing rifiuta una entry oltre il limite del
codec metadata prima di allocare gli array; il budget dell'EDIT intero
resta verificato dal preparatore del checkpoint.

`pubblica-control-da-active` richiede nel nuovo manifest CLOSED per il
vecchio ID, **lunghezza esattamente P e tutti e soli gli esiti derivati**.
Verifica che il vecchio FD sia ancora aperto, prima di qualsiasi claim.
Delega poi alla transizione conservativa del control log: stessa vista,
conservazione degli altri segmenti/esiti, nuovo ID e publisher unico.
Il punto atomico resta la rinomina del control log; la conferma segue il
fsync della directory, con gli stessi stati terminali e condizioni originali.

## Budget e costi

| Budget di apertura | Default |
|---|---:|
| file/scratch intero | 256 MiB |
| chunk del corpo | 64 KiB |
| lotti / record per lotto | 65.536 / 65.536 |
| byte per lotto | 64 MiB |
| record totali, SEAL esclusi | 1.048.576 |
| TXID prepared distinti | 65.536 |
| OUTCOME fisici, inclusi duplicati | 65.536 |

Sono budget configurabili del compito, non nuovi limiti persistenti del
database. Resta il massimo del formato del segmento. La capacità deve
consentire `max(64, min(size-64, chunk))` byte per trasferimento.
I limiti zero di prepared/outcome permettono l'apertura di file che non li
contengono; non cancellano o ignorano record oltre il budget.

Costo di lettura: due osservazioni d'identità, header e
`ceiling((size-64)/chunk)` trasferimenti esatti. Scanner e attraversamento
sono limitati da byte/lotti/cornici; il secondo passaggio non ricalcola il
CRC dei documenti. Le query DECISION usano le ricerche binarie esistenti.
Il packing ordina TXID privati; gli esiti nel risultato occupano `16 × E`
byte di payload, esclusi oggetti Lisp. Gli hash table transitori sono
limitati dai conteggi configurati, con lookup medi O(1).

Percorso di apertura con allocazioni, boxing u64 e ordinamento: nessuna
promessa di heap zero, latenza o throughput. Nessun lock, incremento di
CSN o scrittura condivisa tra Serie viene introdotto.

## Decisioni da qualificare

Il [metodo delle prove funzionali](active-recovery-metodo.md) registra
la verifica integrata readonly, degli esiti e del collegamento al publisher.
Esiti e limiti delle esecuzioni restano distinti dalla matrice C1 completa.
La [campagna parallela di verifica](active-recuperato-verifica.md) conserva
altri 59 test e le proprie letture, fault injection e misure. Le due suite
usano package e registri distinti e vengono eseguite entrambe da ASDF.

| ID | Decisione | Casi |
|---|---|---|
| ARV-D01 | chunk positivo e byte budget almeno header | ciascuna falsa, entrambe vere; size 63/64; soglie byte |
| ARV-D02 | superamento budget caller o formato | ciascuna vera, entrambe false; backend diverso/alias fisico |
| ARV-D03 | progresso header, fine entro prefisso, range valore coerente | ciascuna falsa, tutte vere; v1/v2 |
| ARV-D04 | TXID già presente e lotto diverso | primo, ripetuto nello stesso/altro lotto; prepared dopo OUTCOME |
| ARV-D05 | OUTCOME già presente e CSN diverso | assente, duplicato identico, differente, zero/u64 alto |
| ARV-D06 | consumo prefisso/lotti/record esatti | ogni conteggio diverso; header-only; coda e corruzione durevole |
| ARV-D07 | DECISION con almeno due partecipanti e Serie presente | ciascuna falsa, entrambe vere |
| ARV-D08 | OUTCOME presente e CSN differente da DECISION | ogni ramo della tabella di risoluzione |
| ARV-D09 | contatori locali/abort/derivati iniziali a zero | ciascuno diverso; conteggio finale delle classi |
| ARV-D10 | packing: ordine crescente e presenza/tipo del CSN | input disordinato, zero, high bits, entry oltre codec |
| ARV-D11 | prefisso entro range e stato COMPLETE/TAIL coerente | confini e ciascun ramo incoerente |
| ARV-D12 | serializer: lunghezze uguali e count u32 | ciascuna falsa; alias, range esatto/insufficiente |
| ARV-D13 | checkpoint CLOSED con P/count esatti | stato, P, count falsi separatamente; esito omesso/aggiunto/modificato |
| ARV-D14 | esito presente e CSN identico | assente, differente, zero presente; FD chiuso prima del claim |

Le [prime prove locali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-active-recovery/README.md)
riguardano compilazione e controlli statici. La successiva
[campagna funzionale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-active-recovery-verification/README.md)
aggiunge 27 test con varianti v1/v2 su FD reali: risoluzione, errori,
query e serializer, chiusura verso il publisher e riapertura del control log.
Il risultato locale appartiene al commit congelato dichiarato nella campagna;
qualifica C1, matrice completa delle decisioni e misure restano aperte.
Il [lettore del decision log legato all'Archivio](decisioni-recuperate.md)
è ora disponibile con qualifica dedicata ancora aperta. Restano da integrare
la riconciliazione fisica dei nomi, gli
indici/orizzonte CSN e il gate di ammissione del Recovery Manager.
Questo risultato non autorizza da solo a dimenticare decisioni globali o
riaprire il traffico della Serie.

Il [builder completo del checkpoint](checkpoint-recovery.md) deriva ora
lo stato dal risultato ACTIVE e dal CONTROL trattenuto, con qualifica
dedicata ancora aperta; conserva il publisher unico già descritto.

Il [lettore CLOSED e il controllo dell'insieme](closed-recuperato.md) verificano
ora i prefissi nominati e offrono `pubblica-control-con-closed` prima del
publisher canonico. La qualifica dedicata di questi nuovi ingressi resta aperta.
