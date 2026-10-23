# Recovery readonly dei CLOSED

`arcdocdb.recovery.closed` verifica i segmenti CLOSED nominati dal
[CONTROL recuperato](control-recuperato.md), secondo
[ADR-0040](../adr/0040-manifest-a-record-unico.md#3-riconciliazione-al-riavvio)
e [ADR-0041](../adr/0041-multiserie-segmenti-autosufficienti.md#3-segmenti-autosufficienti-inv-s7).
Non cambia formati, politica CLEAN/MERGE o publisher canonico.

## API

| API | Contratto |
|---|---|
| `leggi-closed-recuperato(control, input, id, scratch, …)` | header e prefisso dal medesimo FD readonly, prepared risolti localmente |
| `frontiere-closed-recuperato(result)` | ID u64, P dal manifest, versione 1/2 e origine writer=1/compaction=2 |
| `statistiche-closed-recuperato(result)` | lotti, record esclusi SEAL, TXID prepared distinti, commit locali, commit solo EDIT, abort |
| `massimo-csn-closed-recuperato(result)` | presenza e massimo locale, includendo EDIT orfani; NIL/0 distinto da T/0 |
| `massimo-csn-serie-recuperata(active, vector, :max-segmenti)` | massimo ACTIVE + insieme completo dei CLOSED; fonti ancora aperte |
| `verifica-closed-completi(control, vector, :max-segmenti)` | tutti e soli i vecchi CLOSED, una volta per ID, con stesso CONTROL, P e file aperti |
| `pubblica-control-con-closed(prepared, active, vector, :max-segmenti)` | verifica l'insieme prima del claim, poi delega a `pubblica-control-da-active` |

Il risultato trattiene CONTROL, capacità readonly e scalari, senza scratch,
workspace, array o FD numerico esportato. Gli ID del formato sono u64 completi,
anche zero: il lettore non costruisce una capacità GET e non applica i limiti
dell'attuale indice primario. Non costruisce mappe GET o indici.

## Autorità, lettura e frontiera

Il controller garantisce un recovery esclusivo della Serie e l'associazione
dal catalogo fra CONTROL, input e nomi dei file. File, FD e namespace restano
autorevoli, congelati e aperti fino alla pubblicazione; scratch esclusivo
per tutta la lettura. Readonly non impedisce mutazioni esterne. Backend
CONTROL e segmento devono coincidere, incluso `nil` per il percorso nativo.

1. Senza syscall: verificare capacità, alias con UUID della Serie, budget,
   backend e stato CLOSED dell'ID. Prendere P dal manifest; verificare range
   e capacità di trasferimento prima di leggere.
2. Leggere l'header dal FD dato e verificare CRC, Serie, tutti i bit dell'ID,
   riservati, versione effettiva e origine prima del corpo.
3. Leggere il corpo in chunk fino a **P esatto**, senza rileggere l'header.
4. Verificare l'intero prefisso in memoria, poi applicare la semantica locale.
   Consegnare il risultato solo con CONTROL e input ancora aperti.

P non è una misura dell'EOF fisico. Il lettore non usa lo scanner TAIL a EOF,
non legge né interpreta byte oltre P e non tronca file. Un lotto rotto prima
di P è un errore, non una coda da ignorare. Un file più corto di P causa
l'errore I/O originale. Il manifest non sostituisce header, CRC o dati.
Non vengono confrontati numeri FD o inode: l'autorità dei nomi e la stabilità
restano del controller; l'header verifica identità logica sullo stesso FD.

## Origine e prepared

Per origine writer si verificano lotti interi con il verificatore canonico:
cornici, CRC, SEAL, ID u64 e frontiere. P deve coincidere con la fine di un
lotto completo. Solo dopo tutti i CRC si riusa l'attraversamento semantico
ACTIVE su un workspace privato: un TXID prepared in un solo lotto, OUTCOME
successivi, duplicati identici ammessi e CSN discordi rifiutati. Il secondo
passaggio ricontrolla gli header senza ricalcolare i CRC dei documenti.

| OUTCOME locale | Esito EDIT per il TXID | Risoluzione del prepared |
|---|---|---|
| presente | assente | commit locale |
| presente | presente, stesso CSN | commit locale, una sola classificazione |
| assente | presente | commit da chiusura |
| assente | assente | abort nel CLOSED autosufficiente |
| presente | presente, CSN diverso | corruzione |

Nessun accesso a `multiserie.log`. Zero presente è distinto dall'assenza;
nessun troncamento dei bit alti. Ogni TXID prepared è classificato una volta:
`prepared = locali + solo-EDIT + abort`. OUTCOME o esiti EDIT senza prepared
nel prefisso non creano versioni o nuovi commit. Tutti gli OUTCOME, anche
orfani, sono confrontati con l'eventuale EDIT omonimo: prove discordanti
impediscono il risultato e il massimo CSN. I metadati del manifest
restano intatti e non vengono scartati.

Per origine compaction si riusa il verificatore integrale esistente: solo
PUT/TOMBSTONE ordinari fino a P, senza prepared, OUTCOME o SEAL. L'header
viene riverificato in memoria dal codec, senza seconda lettura del file.
Le statistiche hanno zero lotti/prepared/esiti e count PUT+TOMBSTONE. Eventuali
metadati di chiusura senza prepared non autorizzano modifiche agli stamp.

## Insieme completo e pubblicazione

Il vettore dell'insieme deve restare completo e stabile durante la chiamata.
Il budget precede la tabella `seen`, dimensionata sul numero di risultati.
Ogni risultato deve provenire dallo **stesso oggetto CONTROL recuperato**,
nominare un CLOSED con P identico, avere input aperto ed essere unico per ID.
Appartenenza, unicità e cardinalità uguale al manifest dimostrano la copertura
dei vecchi CLOSED. Il vettore può essere vuoto solo se non vi sono CLOSED.

L'ingresso di pubblicazione esegue il controllo prima di qualsiasi claim e
delega al publisher ACTIVE, che verifica chiusura del vecchio ACTIVE,
transizione conservativa e nuovo ACTIVE. Il punto atomico resta la rinomina
CONTROL, con conferma dopo fsync del parent e gli stessi stati terminali.
Non c'è un nuovo gettone, seconda rinomina o rilettura dei segmenti.

Questo non esegue riconciliazione fisica dei nomi, rimozioni o verifica di
un inventario directory. Non autorizza dimenticanza delle decisioni globali,
ricostruzione indici/CSN o riapertura del traffico: resta il gate del Recovery
Manager. Le API di pubblicazione precedenti mantengono i loro contratti.

## Budget e costi

| Budget di apertura | Default |
|---|---:|
| prefisso/scratch | 256 MiB, configurabile; resta il massimo del formato segmento |
| chunk del corpo | 64 KiB |
| lotti / record per lotto | 65.536 / 65.536 |
| byte per lotto | 64 MiB |
| record totali, esclusi SEAL | 1.048.576 |
| TXID prepared distinti / OUTCOME fisici | 65.536 / 65.536 |
| `max-esiti-chiusura` | 65.536 esiti unici già ripiegati nel manifest |
| insieme `max-segmenti` | 65.536 CLOSED, escluso ACTIVE |

Sono budget del compito, non nuovi limiti del database. Esaurimento non
significa assenza o abort. Zero record/prepared/outcome/esiti è ammesso
quando il prefisso non li contiene; chunk, lotti e record per lotto sono
positivi anche sul vuoto. `max-bytes` è fra header e massimo del formato,
controllato prima di leggere per entrambe le origini. L'OUTCOME budget conta duplicati fisici; gli esiti
EDIT sono già canonici dal replay CONTROL.

La capacità I/O ammette `max(64, min(P-64, chunk))` byte per trasferimento.
Header e `ceiling((P-64)/chunk)` trasferimenti esatti; ogni byte letto una
volta. Writer: verifica CRC integrale, poi visita limitata a lotti+record
e query EDIT per OUTCOME distinti prima della classificazione dei prepared.
Il fold EDIT verifica valori u64 e cardinalità attraversata. Compaction:
codec integrale delle cornici.
Workspace semantico con hash table del parser canonico, limitato da
prepared/OUTCOME; non viene trattenuto dal risultato. Il controllo insieme
usa una tabella privata e lavoro medio O(N). Nessuna misura di heap zero,
RSS, latenza o throughput. Nessun nuovo lock o scrittura condivisa tra Serie.

## Decisioni e qualifica

| ID | Decisione composta / confine | Casi richiesti, aperti |
|---|---|---|
| CDR-D01 | cinque condizioni della configurazione | ciascuna falsa, tutte vere; byte sotto header/sopra formato; header-only writer/compaction |
| CDR-D02 | fine header e offset created nel range | ciascuna falsa, entrambe vere; versioni 1/2 |
| CDR-D03 | chunk positivo e P almeno header nel lettore corpo | ciascuna falsa, entrambe vere; chunk corto/esatto |
| CDR-D04 | progresso/fine/stamp/durable del lotto | ciascun risultato impossibile, tutti coerenti; budget al limite |
| CDR-D05 | fine/versione/count/budget compaction | ogni discordanza separata; prepared/OUTCOME/SEAL rifiutati |
| CDR-D06 | EDIT presente e CSN diverso per ogni OUTCOME; poi presenza locale/EDIT per prepared | ogni combinazione, anche OUTCOME orfani, zero e bit alti |
| CDR-D07 | stato CLOSED e P uguale nell'insieme | ciascuna falsa, entrambe vere |
| CDR-G01 | preflight e identità prima del corpo | alias, scratch, backend, stato e budget; UUID/ID/CRC/riservati/origine |
| CDR-G02 | prefisso esatto | metà lotto, corruzione prima di P, file corto, coda dopo P intatta/non letta |
| CDR-G03 | semantica e conteggi | prepared fra lotti, OUTCOME antecedenti/duplicati, tutte le risoluzioni, esiti orfani |
| CDR-G04 | copertura del manifest | mancante/extra/duplicato, altro CONTROL, FD chiuso, vettore vuoto, ID zero/u64 alto |
| CDR-G05 | ingresso publisher | rifiuti prima del claim senza effetti, stesso gettone e guasti canonici dopo il claim |

Le [prime evidenze locali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-closed-recovery/README.md)
riguardano compilazione e controlli statici. La
[campagna dedicata](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-closed-verifica/report.md)
conserva 69 test composti, FI, prove native e revisione statica.
Qualifica C1/MC/DC e misure dei nuovi ingressi restano aperte.
Le prove dei parser preesistenti non qualificano automaticamente il nuovo
binding CLOSED/CONTROL, la risoluzione EDIT o il controllo dell'insieme.
Il [metodo della verifica dedicata](closed-recuperato-verifica.md) definisce
oracoli, matrici funzionali, prove native, copertura e conservazione della
campagna successiva, mantenendo distinti esiti eseguiti e requisiti aperti.
