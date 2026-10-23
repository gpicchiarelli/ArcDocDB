# Changelog

Formato basato su [Keep a Changelog](https://keepachangelog.com/it-IT/1.1.0/). Il progetto
non ha ancora rilasci del prodotto; le versioni seguiranno la [roadmap](docs/roadmap.md).

## [Non rilasciato]

### Verificato

- Cronologia Git ridotta agli ultimi due commit su richiesta dell'autore
  ([ADR-0062](docs/adr/0062-cronologia-git-due-commit.md)). Albero del primo
  commit conservato integralmente, codice del secondo invariato; aggiornati
  i collegamenti alle prove per i nuovi hash. Cronologia precedente conservata
  in un bundle esterno verificato prima del push protetto da lease.
- Conservazione: snapshot esterno verificato di 52.277 file storici, con
  inventario SHA-256 e rilettura da GitHub. Nel checkout rimangono i riferimenti
  alle otto campagne recenti rilevanti e le tre pubblicazioni CI più recenti;
  citazioni precedenti ancorate ai contenuti originali. Migrazione iniziale
  senza riscrittura Git; successiva riduzione della cronologia descritta sopra.
- CI: compressione lossless dei raw oltre 4 KiB, mantenendo i budget aggregati
  esistenti e verificando il recupero dei byte nei test di confine.
- CRC32C: confronto preregistrato 16/32 B, misure a 64/256 B, vettore
  `123456789`, fallback e GET completo. Mantenuto il kernel 16 B:
  0,739 µs per corpo da 4112 B; GET caldo da 4 KiB 9,813 µs con oracolo
  e 1,647 µs nel driver throughput. [Risultati e limiti](docs/implementazione/crc32c-unroll32.md).

### Corretto

- CRC32C: bootstrap comune e componenti ASDF condizionali isolano VOP e
  dipendenze ARM sulle altre piattaforme/versioni, anche con FASL già in cache.
  Fallback forzabile all'avvio; decisioni OS/compilatore/kernel testate
  ([ADR-0060](docs/adr/0060-crc32c-caricamento-portabile.md)).

- M1: capienza, arena, credito slot e revisione dell'indice verificati prima
  di CSN e append durevole. Il rifiuto ordinario lascia READY e file invariati;
  un'invariante rilevata nel preflight chiude admission e conserva la causa.
  Riapertura con gli stessi budget, v1/v2, e due oracoli contro il writer
  precedente. Presenza Engine esplicita nel catalogo CI; l'integrazione con
  sessione Unix e codec delle pagine porta il catalogo a 57 suite.

- Pubblicatore C4 delle PR: merge sintetico firmato da GitHub legato all'head
  del run e inventari equivalenti al merge associato alla PR. SHA originale,
  ancora e metodo sono conservati; il producer PR resta non fidato. Prima
  ricevuta del riconciliatore salvata anche quando manca la directory `runs/`.

- Lettura dei risultati CI nel processo isolato di copertura: vocabolario
  trusted completo per SKIPPED, METRICS-STATUS ed EXECUTION, senza dipendere
  dal caricamento del prodotto. Regressioni in nuovi processi e rifiuto dei
  token sconosciuti; raccolte incomplete continuano a restituire errore.
  Riepilogo di copertura entro il budget: conteggio dei file nel risultato
  compatto, inventario completo negli allegati originali verificati.
  Conteggio assente distinto da inventario misurato vuoto.

- Fixture concorrente della lettura stringhe CBOR: durata e overlap WALL
  possono essere zero quando l'ondata cade nello stesso tick. Preservati
  rendezvous, risultati esatti, conteggi, immutabilità e limiti delle attese;
  nessuna attesa artificiale o modifica al decoder.

### Aggiunto

- CRC32C ARM64 scritto in Lisp/SBCL, con load controllati a safety 3,
  rilevamento CPU all'avvio e fallback slicing-by-8. GET cache hit da 4 KiB
  misurato a 1,68 microsecondi, con oracolo indipendente fuori dal timing;
  percorso di integrità originale, formati e semantiche di commit invariati.

- Diagnosi C4 del GET: CRC, verifica PUT, copie e oracolo misurati separatamente;
  lookup dell'indice reale fino a 4,19 milioni di chiavi, confronto caldo/uniforme,
  hash, budget e RSS distinti. Metodo preregistrato, cinque repliche e sorgenti
  stabili; nessuna modifica al percorso di prodotto o alla sua concorrenza.

- Codec C1 delle pagine derivate dell'indice primario: 4/16/64 KiB,
  identita' e CRC32C, bucket flat, directory radix e chiavi esterne fino a
  65535 byte. Preflight prima delle scritture, fixture indipendenti e
  corruzioni strutturali con CRC validi; backend e migrazione restano aperti.

- Primo selettore automatico dell'indice per Serie: residente se capiente,
  rientro con isteresi e preflight del picco di migrazione. ADR-0057, test
  delle soglie e modello C4 del lifetime con hazard e controlli negativi.
  Backend paginato, migrazione e collegamento al runtime restano aperti.

- M1 Single-Series Durable Core: ingresso di produzione per startup, recovery
  automatico e admission, riusando preparatori, gate, publisher, runtime e
  GET esistenti. Esclusione fisica del parent, un attore seriale, PUT/GET e
  tombstone strong; campagna dedicata di due SIGKILL. Nuove feature sospese
  nel lavoro M1; milestone Production Engine Bootstrap aperta.
  [Evidenze](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-production-engine-bootstrap/report.md):
  2164/2164 casi, 15 test engine, 80 primary, campagne dedicate e originali
  falliti conservati lossless. La successiva
  [qualifica Unix M1](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-23-production-unix-m1/report.md)
  aggiunge il profilo locale; il gate completo resta aperto.

- Completamento dei nomi dell'intero Archivio: capienza globale, metadata e
  gate canonico riconfermati prima dei preflight di tutti i nomi; effetti
  per Serie e conteggi completi. Causa originale e completamenti precedenti
  conservati; qualifica funzionale e Recovery Manager completo restano aperti.

- Completamento dei nomi dell'intera Serie recuperata: preflight completo
  dei token e di tutti i nomi prima degli effetti, poi rinomina esclusiva e
  fsync per fonte. Conteggi solo completi, nessun nuovo array/hash, rollback
  o stato condiviso fra Serie; qualifica funzionale e Recovery Manager aperti.

- Collegamento della stabilizzazione dei nomi recuperati alla pubblicazione
  esclusiva: nessuna sostituzione del target, callback richiesta solo al ramo
  temporaneo e fsync parent conservata nel ramo già definitivo. Qualifica
  funzionale e coordinamento completo del Recovery Manager restano aperti.

- Pubblicazione esclusiva di un temporaneo già deciso: rinomina relativa
  senza sostituzione del target, identità nome/FD prima e dopo, backend
  iniettabile e fail-stop comune. Compilazione e controlli statici distinti
  dalla qualifica funzionale e dall'integrazione del Recovery Manager.

- Variante C4 di SPK-11 con recv/send diretti su buffer posseduti: offset,
  backend iniettabile, short I/O, attese senza retry interno e deadline.
  Confronto fra trasporto precedente e nativo, saturazione ed EOF parziale;
  osservazioni Lisp separate dalla qualifica dell'allocatore nativo e del pool.

- Visita sincrona dei record CLOSED recuperati: stesso FD readonly,
  prefisso e risoluzione OUTCOME/EDIT verificati prima della consegna,
  PUT/TOMBSTONE committed e conteggio dei record prepared abortiti.
  Workspace canonico riusato senza esporlo nell'API pubblica del reader;
  replay ACTIVE, raggruppamento, pubblicazione e qualifica dedicata aperti.

- Confronto SPK-08 di scalare, SWAR con packing e SIMD su stessi byte e query
  variabili, con controlli dei limiti e oracolo indipendente. Valutazione
  sistematica delle SIMD sicure sui target Linux x86-64 e macOS ARM64,
  selezione delle funzionalità disponibili e ripiego scalare obbligatorio;
  integrazione nel prodotto e qualifica multipiattaforma restano aperte.

- Materializzazione della chiave recuperata nel primary privato: PUT
  inserito o identico, TOMBSTONE/NONE come assenza verificata; nessuna
  sovrascrittura o rimozione di una voce diversa. Budget writer canonici,
  scratch riusato e rifiuto delle location non rappresentabili. Qualifica
  dedicata, replay completo e pubblicazione delle radici ancora aperti.

- Creazione esclusiva dei `.tmp` relativa alla directory posseduta: nuovo
  regolare vuoto, identità verificata, append e cleanup del solo child.
  Collegata agli output della prova verticale; nessun unlink, flush o rename implicito.

- Selettore riusabile delle versioni recuperate per chiave (ADR-0042):
  massimo CSN, spareggio per offset nello stesso segmento e tombstone
  provvisorio. CRC completi, CSN prepared esplicito e ambiguità bloccante;
  nessun array per candidato. Qualifica dedicata e pubblicazione dell'indice aperte.

- Stabilizzazione del nome di una fonte recuperata: token ACTIVE/CLOSED,
  FD e ID esatti prima del completamento, collisioni preservate e fsync
  parent anche nel ramo già definitivo. Nessuna riapertura in scrittura;
  orchestrazione completa e qualifica funzionale dedicata ancora aperte.

- Directory privata delle righe full text: ricerca binaria sotto lease dal posting
  al riferimento PUT, stati assente/in preparazione/sigillato distinti e chiavi u32
  senza sentinelle. Cancellazione pre-append, riuso protetto e entry trasferite
  trattenute; mappa pubblicata del delta, MVCC e reclaim ancora aperti.

- Riferimenti fisici dei PUT full text: cattura preallocata da un lotto sigillato
  con token WAL autorevole, header verificato senza scansioni del body e posizione
  stabile dopo il riuso del buffer. CSN ordinari e TXID prepared restano distinti;
  nessuna pubblicazione o risoluzione 2PC anticipata.

- Estensione C4 di SPK-11 alla sessione locale proposta: HELLO/WELCOME,
  negoziazione, PING correlati e risposte invertite fra due processi.
  Fixture per mappe duplicate, limiti prima del corpo, ID u64, credito
  trattenuto e deadline assolute; gate simulato e integrazione M16 ancora aperta.

- Legame full text agli esatti byte PUT: cornice privata per tutte le generazioni,
  riserva collettiva e append nel lotto WAL dopo i preflight. Formati v1/v2,
  ordinari/prepared, riferimenti protetti dal riuso del lotto e fail-stop dopo
  trasferimento incompleto. CRC/spans attestati nel worker, controlli costanti e
  sola copia del body sotto lease writer. Pubblicazione durevole, esiti 2PC, MVCC e ritiro aperti.

- Lettura coordinata dell'Archivio: preflight di tutte le Serie e budget
  aggregati prima dei dati; scratch riusato e piano CSN completo solo dopo
  i reader canonici. Budget byte esplicito, nessun binding o risultato parziale;
  qualifica funzionale dedicata ancora aperta.

- Recovery semantico dell'intera Serie dalle fonti readonly possedute:
  preflight completo e budget cumulativo prima dei dati, ACTIVE con replay
  decisioni canonico, tutti i CLOSED con scratch riusato e gate finale.
  Nessuna pubblicazione parziale o gestione implicita dei FD; qualifica dedicata aperta.

- Proposta del contratto di sessione M16 (ADR-0056) e SPK-11 su socket Unix:
  due processi reali, frame parziali/accorpati, documento e chiave massimi,
  rifiuti prima dell'allocazione e nomi occupati preservati. Il listener di
  prodotto resta subordinato ad avvio, recovery e ammissione del motore.

- Acquisizione readonly posseduta di tutti i segmenti ACTIVE/CLOSED da un solo
  inventario directory, budget cumulativo degli EOF e cleanup completo anche
  con più errori di close. Collegamento alla fixture verticale; riconciliazione
  fisica e ammissione restano da implementare.

- Prove della cache con quattro worker che inseriscono e leggono record
  concorrenti nello stesso insieme, oltre a casi deterministici per contesa,
  sequenza dispari, credito esaurito e posti disabilitati. Confronto completo
  con record indipendenti nei formati v1/v2; qualifica C1 ancora aperta.

- Riserve full text locali sotto lease del writer: budget di tutte le generazioni
  verificati prima degli effetti, copia riprendibile in run posseduti e task protetti
  dal riuso. Cancellazione pre-append e trasferimento con costi trattenuti;
  il ponte PUT/WAL e aggiunto nell'incremento successivo; pubblicazione e ritiro aperti.

- Adozione delle mappe CLOSED recuperate nello scope runtime: insieme completo,
  autorità e FD esatti verificati, wrapper nuovi e righe immutabili condivise.
  Budget prima delle allocazioni; nessuna rilettura dei segmenti o pubblicazione
  del primary. Qualifica funzionale e ammissione restano aperte.

- Preparazione full text direttamente dai documenti CBOR: percorsi annidati,
  tipi e duplicati selezionati verificati, analisi riprendibile e run sigillato.
  Budget cumulativi e limite superiore del file prima del futuro aggancio al writer;
  fixture NNTP, scansione indipendente e cancellazione nei diversi stadi.

- Interfaccia locale prioritaria per il primo impiego NNTP (ADR-0055): socket
  Unix stream predefinito fra demone e database, TCP opzionale successivo e
  disabilitato per default. Anticipata la prima integrazione M16 dopo avvio,
  recovery e ammissione; tracciati requisiti, limiti, ciclo di vita e prove.
  Decisione progettuale; listener e client restano da implementare.

- Codec completo `.idx` full text v2/type 5: descriptor META canonico copiato,
  legame ai byte hint e mappa PUT fornita, serializzazione senza allocazioni per entry,
  verifica di termini/posting/posizioni e vista immutabile per all/any/frasi sul file.
  Fixture wire indipendente, fuzz con CRC corretto e riapertura in child SBCL su campi
  subject/body NNTP. I/O e pubblicazione durevole delle generazioni restano da integrare.

- Primo nucleo full text: analizzatore riprendibile Unicode 18.0.0 con dati e licenze
  versionati, run invertiti posizionali in memoria e ricerca all/any/frase per riga/campo,
  cornice `.idx` v2/type 5 con CRC e preflight. Corpus ufficiali, scansione indipendente,
  saturazione, concorrenza, allocazioni e controlli negativi in `make check`.
  Persistenza completa, writer, snapshot e Query Engine restano da integrare.

- Adozione dell'ACTIVE preparato nel runtime Archivio con ambito esatto e
  registro CSN comune. Binding unico del controller sul log canonico,
  recuperabile dopo interruzione senza reset o nuovo costo per operazione.

- Bootstrap del runtime dall'intero piano CSN dell'Archivio: famiglia unica
  CSN/snapshot/epoche e nuovo ambito GET, pubblicazione atomica senza reset
  e recupero del binding dopo interruzione. Nessun nuovo I/O o lock sul
  percorso delle Serie; gate del traffico e qualifica C1 ancora aperti.

- Verifica dei cataloghi delle evidenze con fino a quattro processi isolati,
  heap e tempo per catalogo configurabili, errori ridotti nell'ordine seriale
  e log dei worker conservati. Percorso seriale disponibile per confronto.

- Suite dedicata del piano CSN dell'Archivio: insieme completo delle Serie,
  Registri, provenienza del replay, gate CLOSED e base u64 senza incremento.
  Matrici v1/v2, catena nativa e collegamento di prova al registro esistente;
  risultati e limiti separati dalla qualifica C1 e dall'ammissione del traffico.

- Scelta dell'ID recovery direttamente dalla directory posseduta: una sola
  enumerazione attestata, cinque budget conservati, selezione comune dal
  piano canonico e nessuna prenotazione. La prova verticale usa nomi canonici
  e questo ingresso di prodotto al posto dell'inventario costruito nel test.

- Suite dedicata del recovery CLOSED: lettura fino al P del CONTROL,
  risoluzione OUTCOME/EDIT, origini writer/compaction, massimo CSN e gate
  dell'insieme. Oracoli indipendenti, matrice v1/v2 e pubblicazione nativa;
  copertura e risultati conservati separatamente dalla qualifica C1 completa.

- Piano CSN dell'Archivio: elenco Serie posseduto con Registri inclusa,
  UUID unici, stessa autorità delle decisioni e gate CLOSED per ogni Serie.
  Massimo completo rispetto all'elenco canonico fornito e parole della base
  senza incremento; marker di replay leggero nel risultato ACTIVE.
  Nessun nuovo I/O o allocatore; catalogo persistente, ammissione e qualifica
  dedicata restano da collegare.

- Lettura diretta delle stringhe CBOR MT2/3: tipo e intervallo assoluto
  del payload senza copie, UTF-8 verificato per il testo, coda ignorata
  e budget dell'intera finestra. Buffer condivisibile in sola lettura;
  qualifica C1 dedicata ancora aperta.

- Proposta dell'ID del nuovo segmento dopo recovery, oltre il high-water del
  manifest e ogni nome dell'inventario, inclusi i temporanei orfani. Piano
  posseduto, limiti u64 e budget espliciti; collegamento alla prova verticale.
  Nessuna prenotazione, modifica di file o ammissione del traffico.

- Completamento progettuale full text (ADR-0054): profilo Unicode 18.0.0,
  foglie query, contratti dei moduli, generazioni e ritiro, riserve prima del
  commit e default di ammissione. Definito il formato `.idx` v2/type 5 con
  sei sezioni e legame all'hint; quattro nuovi requisiti e due invarianti.
  Corpus e criteri di accettazione restano da realizzare nella fase 8;
  nessun codice full text introdotto.

- Massimo CSN osservato dai reader ACTIVE/CLOSED e dal decision log, con
  aggregazione di tutti i segmenti della stessa Serie dopo il gate canonico.
  Distinti zero e assenza; inclusi CSN dei SEAL writer, OUTCOME ed esiti EDIT,
  esclusi TXID e code non valide. Nessuna assegnazione CSN o ammissione del
  traffico; qualifica funzionale, fault injection e prestazioni ancora aperte.

- Documentazione full text riallineata fra scope v1, contratto/catalogo,
  interfacce query, roadmap, glossario, valutazione, costi, rischi e piano
  di verifica. ADR-0053 resta la decisione di riferimento; implementazione,
  formato binario e qualifica rimangono nella fase 8.

- Ripresa delle scritture nella prova verticale v1/v2: ricostruzione della
  base CSN, nuovo ambiente coerente, quattro commit e secondo SIGKILL con
  recupero indipendente. Oracolo negativo del riuso CSN prima dell'append;
  coordinamento ancora C4, con priorità di sviluppo aggiornate nella roadmap.

- Ricerca full text nel progetto della v1 (ADR-0053): indici invertiti dedicati
  per segmento, parole e frasi, analizzatori versionati, filtri strutturati e
  coerenza con commit/snapshot. Documentati rebuild, corruzione, budget e caso
  NNTP; quattro requisiti progettati e INV-I4. Implementazione e qualifica
  previste nella fase 8, senza codice full text introdotto.

- Obiettivo applicativo confermato: ArcDocDB come database di un futuro
  server NNTP in Common Lisp. Documentati lookup degli articoli, overview
  ordinate, cross-posting, retention, integrazione e criteri di valutazione;
  il motore resta general-purpose, con sviluppo NNTP futuro.

- Prova verticale di una Serie nei formati v1/v2: scrittura durevole,
  aggiornamenti, tombstone e GET, SIGKILL reale, recovery e checkpoint in
  un processo nuovo, seconda riapertura indipendente. Include coda senza
  SEAL, checkpoint non pubblicato, rotazione con nuovi commit, confronto
  dei segmenti originali e controllo negativo dell'oracolo. Coordinamento
  e replay dell'indice sono C4; nessuna promozione del motore completo.

- Preparazione bounded di un tratto pool/Serie: selezione e un solo begin
  sul link corrente, senza secondo routing. Sette valori conservano token,
  stato, ragione e metadati originali; pubblicazione senza seconda presa,
  CLOSING e guasti restano espliciti al caller.

- Strumento riusabile di raccolta delle prove: manifest esplicito, copie con
  quattro worker, record conclusi anche falliti e controllo indipendente
  dell'inventario chiuso prima dell'esito positivo.

- Recovery readonly dei CLOSED dal CONTROL autorevole: lettura solo fino a P,
  verifica writer/compaction e prepared risolti da OUTCOME o chiusura EDIT,
  senza decision log globale. Controllo dell'insieme completo prima del
  publisher canonico, ID u64 senza troncamento; qualifica C1 dedicata aperta.

- Verifica dedicata del decision log dell'Archivio: preflight, identità,
  query, ownership e collegamento al recovery ACTIVE, con catena nativa
  fino alla pubblicazione CONTROL nei formati v1/v2. Copertura separata
  del modulo e registrazione di ogni tentativo nella campagna dedicata.

- Verifica integrata pool/dispatcher/Serie con due worker reali: 32 quantum
  su una Serie mentre l'altra mantiene lease o debito batch, più ritiro con
  ring pieno/libero e trasferimento del lavoro residuo a un altro worker.
  Sei scenari sincronizzati; nessuna misura di speedup o modifica ai protocolli.

- Suite nativa indipendente del checkpoint dal vecchio ACTIVE: file v1/v2,
  risoluzione OUTCOME/DECISION, prefisso e coda, budget, chiusura CLOSED
  e collegamento al publisher del control log con oracoli indipendenti.

- Lettura del primo item CBOR minimo con frontiera assoluta: coda non
  letta, budget della finestra autorizzata e scratch privato per worker.
  Consente di ricavare le frontiere degli item concatenati; qualifica C1
  e profilo documentale restano aperti.

- Builder del checkpoint dal recovery ACTIVE: deriva lo stato completo
  dal CONTROL autorevole, conserva CLOSED/REMOVED/esiti, chiude il vecchio
  ACTIVE a P e collega il nuovo ID verificato. Budget prima degli array e
  verifica della transizione in memoria; preparatore e publisher canonici
  invariati, qualifica C1 dedicata aperta.

- Prove dedicate del recovery ACTIVE: lettura readonly, risoluzione dei
  prepared, chiusura deterministica e pubblicazione su file reali v1/v2.
  Oracoli indipendenti, fault injection, copertura e misure separate
  conservati nella campagna `2026-10-15-active-verifica`.

- Passo bounded del dispatcher pool/Serie: sceglie una sola operazione fra
  nuova presa IDLE, collegamento del CLAIMED e ricircolo RESCHEDULE.
  Origine esplicita distingue cursore, count e assenza di trasferimento;
  gli obblighi esistenti non consultano il pool. Nessun secondo claim,
  begin o retry implicito; fasi attive e prima causa restano conservate.

- Lettura readonly di `Registri/multiserie.log`: header UUID/CRC/formato
  verificato prima del corpo, replay completo fino all'EOF attestato e
  decisioni possedute. Nuovo ingresso ACTIVE vincolato allo stesso ambito
  canonico dell'Archivio; formati invariati, qualifica C1 dedicata aperta.

- Rendezvous delle fixture concorrenti residue CBOR, UTF-8 e due Serie:
  checkpoint dopo il primo lavoro effettivo, mantenendo conteggi, sink e
  oracoli. Diagnostica prima delle asserzioni temporali; intervalli WALL
  della fixture, comprensivi delle attese e dei controlli.

- Verifica integrata del lifetime delle fonti GET: lettori su FD CLOSED reali,
  pubblicazione ACTIVE con superset e riduzione controllata, ritiro EBR e
  chiusura dopo quiescenza. Include errore tipizzato e uscita non locale;
  decisione durabile del catalogo e rotazione completa restano da integrare.

- Rendezvous dopo il primo elemento realmente codificato nei test concorrenti
  CBOR float/tag, per imporre l'interleaving senza dipendere dall'avvio dello
  scheduler. Intervalli e checkpoint stampati prima delle asserzioni; metriche
  della fixture distinte dalla latenza del solo encoder.

- Prove dedicate della lettura CONTROL, transizione conservativa e
  pubblicazione validata: 84 nuovi test v1/v2, matrice finita e file reali
  con quattro Serie. Copertura, 216 finestre di confronto, sorgenti dei
  tentativi falliti e output originali conservati nella campagna
  `2026-10-14-control-transizione`; nessuna promozione del motore completo.

- Composizione di tag CBOR da contenuti già codificati: verifica completa
  prima della scrittura, testata MT6 minima e budget comprensivi del tag
  senza aggiungere profondità ai contenitori. Sorgenti condivisibili in
  lettura con scratch privati; semantica applicativa e qualifica C1 aperte.

- Recovery readonly del vecchio ACTIVE nominato dal control log: header
  e prefisso verificati fino a EOF, prepared risolti da OUTCOME/DECISION,
  esiti derivati in array u64 ordinati e serializer della chiusura CLOSED.
  La pubblicazione verifica P ed esiti prima del publisher unico; nessuna
  troncatura, modifica del formato o nuovo CSN. Qualifica C1 e gate del
  Recovery Manager restano aperti.

- Avvio esplicito dell'obbligo pool già acquisito: selezione del writer
  corrente e un solo begin del bridge, con restituzione del link e dei tre
  risultati originali. Writer-busy conserva CLAIMED; Serie-busy mantiene
  token e chiusura esplicita. Nessun nuovo gate, retry o cleanup implicito.

- Casi dedicati ai rifiuti del preflight GET ACTIVE prima del CSN: identità,
  stato OPEN/SEALED, ordine, capacità e guasti degli header, con witness
  indipendenti di byte, token, radici, frontiere e assenza di I/O.
  Suite ACTIVE a 42 test e quattro mutanti preflight rilevati; conservati
  copertura, regressione bootstrap e audit indipendenti delle prove complete.

- Composizione di mappe CBOR da chiavi e valori già codificati: verifica
  completa prima della scrittura, testata MT5 basata sulle coppie e budget
  comprensivi della radice. Sorgenti condivisibili in lettura con scratch
  privati; ordinamento delle chiavi e qualifica C1 restano aperti.

- Ricircolo esplicito dal dispatcher alla Serie: pubblica l'obbligo e termina
  IDLE se c'è spazio; a ring pieno restituisce il link del nuovo writer
  CLAIMED dopo un solo scambio FIFO. Nessun gate del pool, ritiro o nuova
  presa impliciti; busy e guasti conservano i confini execution esistenti.

- Lettura readonly del control log autorevole, con header verificato e replay
  fino all'EOF attestato. Risultato senza buffer, legato alla vista canonica;
  pubblicazione subordinata alla conservazione di CLOSED, esiti e REMOVED,
  chiusura del vecchio ACTIVE e apertura di un ID nuovo. Nessuna modifica
  al formato o agli ADR; recovery completo e qualifica C1 restano aperti.

- Composizione di array CBOR da elementi già codificati: verifica completa
  prima della scrittura, testata minima e budget comprensivi della radice.
  Sorgente e indice condivisibili in lettura, destinazione e scratch privati
  per worker. Profilo documentale e qualifica C1 restano aperti.

- Dispatcher logico dal pool al collegamento della Serie: binding preallocato
  sul medesimo contesto, routing solo dopo una presa autorizzata e ingresso
  distinto per completare gli obblighi già CLAIMED. Nessun begin, pop o retry
  implicito; ritiro e diagnosi conservano i confini C1 esistenti.

- Pubblicazione del checkpoint recuperato: rinomina ancorata alla directory
  preparata, verifica delle foglie contro i FD del nuovo e vecchio control log,
  controllo del nome installato e fsync del parent. Gettone locale unico con
  cleanup prima del CAS; errori terminali senza retry, rollback o risultati
  parziali. Recovery completo e qualifica delle nuove chiamate restano aperti.

- Suite funzionale dedicata al GET ACTIVE ordinario: 28 test con file reali,
  formati v1/v2, oracoli wire indipendenti, confini di payload e directory,
  cache, guasti e cleanup snapshot/EBR. Copertura isolata e compatibilità
  CLOSED conservate con prove grezze e audit indipendenti; qualifica C1 e
  MC/DC restano aperti.

- Presa dei writer governata dallo stato del pool: conferma il comando solo
  dopo la barriera IDLE, delega il claim C1 quando attivo e lascia ready e
  cursore intatti quando inattivo. Compiti e ricircoli già acquisiti completano
  i propri obblighi prima del ritiro; nessuna attesa o gestione fisica dei thread.

- Preparazione del checkpoint `control.log.tmp`: header della Serie, EDIT
  completo e SEAL costruiti senza I/O, manifest verificato contro il nuovo
  ACTIVE, file fisicamente distinto, trasferimenti a blocchi, rilettura esatta
  e fsync del parent. Nessun CSN o rinomina implicita; integrazione del recovery
  e qualifica C1 restano aperte.

- Attuazione logica del controllore pool su worker preesistenti: richieste
  persistenti e conteggio delle sole conferme, ritiro soltanto a contesto IDLE
  senza abbandonare lease o batch, riattivazione degli stessi contesti.
  Include 18 prove con worker reali, copertura C3 senza esclusioni e misure
  senza allocazioni dopo l'avvio. Dispatcher, risveglio e avvio fisico restano aperti.

- Preparazione del nuovo segmento writer: preflight senza effetti, identità
  readonly/append prima della write, header canonico durevole, rilettura esatta
  e fsync del parent. Adattatore ACTIVE con prova obbligatoria e verifica del
  registro CSN della vista; errori senza retry o risultati parziali. Decisione
  EDIT, apertura/rotazione del server e qualifica C1 restano da integrare.

- Ponte fonti GET della Serie: directory CLOSED nel contenuto della radice
  ACTIVE, acquisizione unica dal controller sotto EBR, risoluzione dalla
  stessa radice catturata e rifiuto di owner/ID duplicati prima dell'adozione.
  Mantiene il protocollo WAL e i cinque esiti del nucleo GET; rotazione e
  reclaim completo restano distinti.

- Scrittura dei float CBOR da parole IEEE: riduzione esatta della larghezza,
  preservazione di segno e payload NaN, preflight prima della mutazione
  e destinazioni private per i worker. Qualifica C1 e profilo documentale
  restano aperti.

- Controllore locale del numero di worker di calcolo: EWMA intere,
  crescita additiva, riduzione moltiplicativa e permanenza delle condizioni.
  Campioni e tempo iniettati, target distinto dai worker effettivi,
  aggiornamento limitato senza allocazioni dopo l’avvio. Avvio, risveglio
  e ritiro dei thread restano il prossimo componente del pool.

- Associazione fisica readonly/append: confronto esatto device/inode nel pool
  I/O, prova immutabile legata alle capacità e verifica senza syscall nel
  costruttore ACTIVE. Backend iniettabile esteso con identity opzionale;
  rifiuti senza fallback, retry o mutazioni. Percorso GET invariato;
  adozione nel server e qualifica C1 restano aperte.

- Directory GET dei segmenti CLOSED: ID u32 compatti e riferimenti privati
  immutabili, controllo di Serie/ordine/budget prima delle copie, ricerca
  limitata a diciassette passi e collegamento al resolver/cache/I/O.
  Una location pubblicata senza segmento è un guasto, mai un miss.
  Pubblicazione, ACTIVE, rotazione e reclaim restano integrazioni distinte.
  Corretto il confronto del ritorno di lettura nel resolver CLOSED: l'API
  restituisce END nel buffer, anche quando la regione comincia a 64.

- Scrittura minima dei valori semplici CBOR MT7: codici wire 0..23 e
  32..255, preflight di range/codice/capacità e destinazione esclusiva.
  Include confronto su tutti i codici, fuzz e due worker riusati;
  profilo applicativo, composizione e qualifica C1 restano aperti.

- Routing preallocato dei writer pronti alla Serie: ordinali immutabili,
  registro con associazioni verificate e tabella privata per worker.
  Selezione diretta in tempo costante, anche dopo ricircolo a coda piena,
  senza scritture condivise per messaggio. Include18 nuove regressioni,
  due letture C1, audit completo della copertura e cinque misure locali;
  pool e coordinatore restano aperti.

- Resolver GET ACTIVE per lotti ordinari: radice acquisita dalla pubblicazione
  della Serie, pagine immutabili e directory persistente con quattro piccoli
  vettori per append. Preflight prima del CSN, verifica del solo lotto nuovo e riuso cache/lettura GET;
  budget, fail-stop e confini documentati. Prepared/OUTCOME ACTIVE, indice
  concreto, rotazione/reclaim e qualifica C1 restano aperti.

- Collegamento preallocato worker/Serie: doppia lease, token monotoni, debito
  batch e rilascio Serie prima del worker, con retry limitato alla fine e
  conservazione dei guasti originali. Include 26 prove, due letture C1,
  copertura completa nel denominatore e cinque misure locali del percorso
  seriale; pool e coordinatore Archivio restano da integrare.

- Resolver GET dei segmenti CLOSED: frontiera dal manifest, prefisso writer
  sigillato o compaction verificato, righe u32 immutabili e prove OUTCOME
  risolte senza I/O nel lookup. Connessione a cache e lettura GET, budget
  espliciti e controlli di posizione/CSN; ACTIVE, prove EDIT, directory e
  qualifica C1 restano aperti.

- Hash delle chiavi XXH64 tipizzato: ritorno in due u32, seme esplicito
  immutabile nell'indice, mappe verificate degli slot fisici per rebuild/split,
  propagazione dei guasti interni. Include 46 nuove regressioni, mutazioni,
  misure seriali/parallele e registri strutturati; lifecycle del seme e GET
  integrato ancora aperti.

- Nucleo GET con contesto preallocato per worker: hash col seme dell'indice e lookup sotto EBR,
  capacità segmento con header verificato, cache e I/O readonly, prova
  OUTCOME letta dallo stesso file e risposta privata fino alla conferma
  snapshot. Ricerca storica richiesta esplicitamente sui casi non risolvibili
  dall'indice corrente; resolver, pool, protocollo e qualifica C1 aperti.

- Cache dei record per Serie: classi preallocate, insiemi di otto posti,
  CLOCK limitato, ricerca senza lock e inserimento opportunistico. Ogni hit
  verifica CRC, chiave, CSN e prova prepared; corruzione della cache distinta
  dall’input del segmento. Verificatore comune con CSN in due u32,
  budget e contratti documentati; GET integrato e qualifica C1 aperti.

- Indice primario v2 in memoria: controlli Swiss a gruppi di 16, chiavi binarie
  in arena, lookup con budget comune e conferma root anche sul miss, upsert e
  cancellazione/rilocazione condizionale nel writer, crescita arena e piani monouso di pubblicazione
  directory, con hash delle chiavi e costruttore verificato split/rebuild.
  Lifecycle del seme e GET integrato ancora aperti;
  include contratti, tracciabilità ed evidenze statiche, qualifica C1 aperta.

- Banco di slot v2 dell'indice: parole u64 contigue, lettura in buffer privato
  con otto tentativi, pubblicazione e rimozione sotto seqlock, rilocazione
  condizionale, credito di scrittura e congelamento permanente. Include
  contratti, decisioni da coprire ed evidenze statiche; qualifica C1 aperta.

- Contesto di lettura preallocato per worker: ingresso EBR a tentativo singolo,
  snapshot controllato prima e dopo il lookup, anche sul miss, e cleanup del
  pin prima della migrazione. Collegato ai registri CSN/snapshot/epoche;
  indice, cache e pool restano da integrare, qualifica concorrente aperta.

- Dominio EBR per Archivio: annunci dei worker distanti 128 byte, ingresso
  senza mutex a tentativo singolo, ticket preallocati e crediti di epoca prima
  dello swap. Frontiera condivisa da più ritiri e claim esclusivo del reclaim;
  integrazione con segmenti/pool e qualifica concorrente restano aperte.

- Registro snapshot per Archivio: soglia annunciata prima della cattura del CSN,
  contesti preallocati con generazione, controlli di lettura senza mutex,
  deadline e scadenze con budget. Interfaccia in buffer per i reader;
  qualifica concorrente, controller ed EBR restano da integrare.

- Registro CSN per Archivio con orizzonte monotono e budget finito;
  l’implementazione attiva è `arcdocdb.csn`, con token slot/high/low.
- Ricostruzione in memoria del manifest dal prefisso sigillato di `control.log`:
  ACTIVE, CLOSED con esiti, rimozioni esplicite e limite degli ID. Workspace
  indipendenti per Serie; nessuna riconciliazione o scrittura dei file.

- Validazione UTF-8 pura su span immutabili, con budget massimo di 16 MiB,
  conteggio dei valori scalari ed errori tipizzati con offset. Utilizzabile
  in parallelo dai worker prima del writer; il parser CBOR resta da integrare.
  Diciassette test, nove mutanti rilevati e zero heap nei 25 campioni locali;
  prove concorrenti ed evidenze grezze conservate.

- Code MPSC locali preallocate e gettone del writer con quota cumulativa:
  contesa e saturazione distinte, FIFO e rifiuto dei gettoni vecchi.
  Diciassette test, inclusi producer/consumer su thread reali e calcolo
  sovrapposto tra Serie; otto mutanti rilevati e zero heap nelle misure locali.

- Verifica in memoria dei segmenti compattati CLOSED v1/v2: identità, CRC,
  soli PUT/TOMBSTONE ordinari, limite valido autorevole e budget byte/record.
  Conteggi fisici restituiti dopo il controllo integrale; 15 test indipendenti,
  otto mutanti rilevati e misure locali delle allocazioni conservate.

- Tabella delle decisioni multiserie inclusa nella compilazione e nei test ordinari:
  ricostruzione dal prefisso sigillato, duplicati idempotenti o discordanti,
  budget finiti, query scalari e copie possedute dei partecipanti. Non applica
  i prepared e non realizza il recovery completo del database.

- SPK-08 bitmap: kernel scalari byte/u64 equivalenti, oracoli indipendenti,
  90 campioni locali e disassemblati conservati. Packing escluso e nessuna
  promozione a ottimizzazione del motore.

- SPK-07: due reader/due slot in SC, 28 mutanti rilevati; crash sui byte
  v1/v2, 49.120 casi e 303.432 interruzioni/ripartenze equivalenti. Frontiera
  esterna e limiti del modello dichiarati; tutti i tentativi conservati.

- SPK-08: maschere scalar/SWAR esatte e kernel NEON/SSE2 a safety 3;
  70 campioni seriali su Apple M4, zero byte consed osservati nei cicli.
  SSE2 e indice concorrente restano da verificare; report leggibili senza
  caricare i package sperimentali, originali integralmente conservati.

- Scansione recovery in memoria dei log v1/v2: prefisso verificato, coda e
  corruzione testimoniata da SEAL successivo, EOF esplicito e budget distinti
  dagli errori dei dati; 19 test, inclusi 20.256 casi di alterazione dei bit.

- SPK-06: modello finito del controllore di carico, quote e timer; 24 confronti
  locali tra letture e copie concorrenti, con verifica integrale, intervalli
  di sovrapposizione e campioni grezzi conservati. Compaction del motore e
  feedback reale restano da verificare.

- SPK-05: letture pread e mmap di file immutabili, CRC/chiave/stamp verificati,
  errori I/O e worker espliciti; 36 confronti locali per variante e profilo
  senza allocazioni osservate nel ciclo finale. Varianti e fallimenti conservati.

- SPK-04: writer sperimentale su pool, code limitate, modelli di parcheggio
  e ripartenza delle letture; controlli e 54 benchmark diagnostici conservati,
  con limiti e tentativi falliti espliciti.

- SPK-10: quattro moduli sperimentali Common Lisp per codec v1/v2, indice a
  cinque parole, CBOR iterativo e modello di migrazione; integrazione in memoria
  dei limiti massimi. Nessun codice di produzione, gate v2 ancora aperto.
- Registro strutturato di prove e benchmark, inclusi fallimenti e diagnostiche;
  blob dei sorgenti prima/dopo, risultati decodificati e output originali.
  `make check` registra l'intera verifica; la CI conserva gli artefatti.
- Campagne locali conservate: indice v1 fino a 10 milioni di documenti,
  profiling di allocazione e controlli/benchmark v2 separati.

- ADR-0050: root dell'indice ricontrollata anche su miss, costi e budget della
  directory separati dagli slot; nessuna promessa di pausa indipendente dalla Serie.
- ADR-0048: documenti da 16 MiB effettivi, profondità 100, chiavi fino a 65.535 byte e layout v2; tre requisiti progettati, gate di verifica e migrazione. ADR-0049 propone il percorso oltre RAM senza dichiararlo disponibile.

- Suite eseguibile della Fase 0 per SPK-01, SPK-02, SPK-03, SPK-07 e SPK-09; harness
  `tools/run-spikes.lisp`, compilazione senza avvisi, processi isolati, comandi e output
  grezzo; `make spikes-check` in CI e `make spikes-bench` per misure locali in serie.
- ADR-0046 e INV-M6: SPK-07 trova un controesempio nell'anello dell'orizzonte; il registro
  preallocato dei veri CSN pendenti lo sostituisce. I requisiti del motore restano progettati.
- ADR-0047: lettura dei prepared con prova autorevole del CSN (OUTCOME o manifest), oltre a
  CRC, chiave e flag. Una location verso un'altra versione della stessa chiave è rifiutata.

- Specifica originale, documentazione tematica (16 documenti), invarianti (`INV-…`),
  glossario.
- Valutazione architetturale: analisi critica, stime, registro dei rischi, piano degli spike.
- Progetto consolidato: [architettura](docs/architettura.md),
  [formati su disco](docs/formati-su-disco.md), [limiti dimensionali](docs/limiti.md).
- 30 ADR (0001–0030): le 26 questioni aperte sono chiuse; ADR-0028 e ADR-0030 attendono la
  conferma dell'autore.
- Sistema ASDF minimo, smoke test, `tools/check-links.lisp`, CI.
- Licenza BSD-2-Clause.
- **Software critico (ADR-0031…0035):** gerarchia delle priorità con l'affidabilità sopra le
  prestazioni; otto nuovi invarianti (INV-A1…A8); analisi dei guasti con 24 modi di guasto;
  standard di codifica (regole `COD-…`); piano di verifica; registro delle deviazioni.
- **Tracciabilità controllata da strumento:** 90 requisiti in `requisiti.lisp`, matrice generata,
  `make trace`.
- Strumenti in Common Lisp: build senza avvisi (`tools/build.lisp`), linter con auto-verifica
  (`tools/lint.lisp`), controllo della tracciabilità (`tools/check-trace.lisp`).
- SPK-09 (costo dei controlli di affidabilità).

- **Analisi progettuale** ([docs/analisi-progettuale.md](docs/analisi-progettuale.md)) e ADR
  0036–0045: dieci leggi di progetto — la prima: **il parallelismo è un principio fondante**,
  con l'elenco chiuso di ciò che le Serie condividono — tabella dei punti di atomicità, sedici
  rilievi `AP-…`; quattordici nuovi invarianti (INV-F2, F3, V5, M4, M5, S7, C11, I3, P5, P6,
  A9…A12), 107 requisiti, 27 modi di guasto, rischio residuo RES-05.

- Inventario dei segmenti dalla directory posseduta dalla Serie: cursore
  readonly indipendente e limitato, nomi canonici u64 e identità senza
  symlink verificati prima del piano di riconciliazione. Nessun elenco
  parziale su EOF mancante, budget esaurito o guasto di cleanup.

- Apertura readonly relativa alla capacità directory, con dimensione
  dello stesso FD, verifica del legame device/inode e cleanup del child
  non pubblicato. CONTROL, decision log e ACTIVE della prova verticale
  usano capacità e dimensione della stessa apertura; i file esistenti
  restano in sola lettura.

### Cambiato

- I test con worker riusati delle stringhe CBOR usano segnali distinti
  per ondata, evitando che un worker consumi il permesso dell'altro
  nell'ondata successiva.

- Snapshot collegati all'unico registro `arcdocdb.csn` dell'Archivio; rimosso
  l'allocatore CSN duplicato del ramo. Coordinamento snapshot senza attese,
  revoca della soglia provvisoria su `:csn-busy` e invalidazione terminale
  al guasto. API del registro canonico e sue evidenze conservate.

- Guide del repository consolidate, note degli esperimenti uniformate al metodo
  tecnico e specifica originale rinominata; requisiti ed evidenze conservati (ADR-0051).

- ADR-0028 e ADR-0030 confermati dall'autore il 2026-10-08, incluse le revisioni su minimi
  di prestazione, backup, restore verificato, verificatore offline e scrubbing.

- **Correzioni di progetto dall'analisi (nessun codice toccato, formati mai implementati):**
  - uno snapshot nasce quando l'orizzonte di visibilità lo ha raggiunto: prima poteva vedere
    comparire un lotto in volo (ADR-0038);
  - coda o corruzione di un log si decidono con la frontiera durevole dei SEAL: prima un crash
    ordinario con più lotti in volo portava la Serie in `FAULTED`; il recovery non tronca più
    (ADR-0037);
  - tombstone scartati con il filtro di esistenza: la regola per lineage faceva riapparire
    documenti eliminati dopo un MERGE di segmenti non adiacenti (ADR-0042);
  - l'esito di una multiserie sta nello stesso segmento dei record che risolve: prima un CLEAN
    poteva perderlo (ADR-0041);
  - primary index a frammenti: nessun raddoppio che triplica la memoria e ferma il writer; slot
    a 4 parole; stima corretta a ~75–80 byte per documento (ADR-0043).
- **Semplificazioni:** la versione di un documento è il CSN; una sola cornice di record con due
  CRC (24 byte); quattro tipi di record nei segmenti; control log con il solo record EDIT;
  `multiserie.log` con il solo record DECISION; nessun file `.bloom`, nessun lineage, nessuno
  stato `creating`; cache senza ri-etichettatura; EBR solo per i file (ADR 0038–0044).
- **Modello di esecuzione:** compiti a completamento, attese come parcheggi, ogni chiamata
  bloccante nel pool di I/O (ADR-0045).

- **Linguaggio visivo rifatto** ([assets/README.md](assets/README.md)): identità monocroma con un
  solo colore, l'ambra, riservato a ciò che può cambiare; nuovo marchio; illustrazione dei
  segmenti e diagramma del percorso di scrittura e lettura in vettoriale, chiaro e scuro; README
  riscritto; anteprima per i social. Il controllo dei link verifica anche i percorsi delle
  immagini.

- ADR-0032 sostituisce in parte ADR-0015: il contatore seqlock passa da 8 a 64 bit, con tentativi
  limitati e ripiego sul writer, perché l'argomento a 8 bit si reggeva sui tempi e non era una
  garanzia per costruzione. Costo: +8 byte per entry (56 B).
- ADR-0028 (proposta) distingue obiettivi e minimi vincolanti di prestazione; ADR-0030
  (proposta) porta backup e verificatore offline nella v1.
