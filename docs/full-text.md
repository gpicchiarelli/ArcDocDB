# Ricerca full text — contratto di progetto

> **Deciso ([ADR-0054](adr/0054-contratto-e-formato-full-text.md))** — Specifica normativa
> che completa [ADR-0053](adr/0053-ricerca-full-text-indici-invertiti.md).
> Stato: integrazione progettata; disponibile il primo [nucleo implementato](implementazione/full-text.md)
> per analisi e run posizionali, con [codec completo e viste verificate](implementazione/full-text-codec.md).
> Disponibile anche la [preparazione dai documenti CBOR](implementazione/full-text-documenti.md)
> con budget cumulativi e limite superiore, e le [riserve locali del writer](implementazione/full-text-riserve.md)
> con copie possedute. Il [ponte PUT/WAL](implementazione/full-text-put.md) collega
> analisi e append degli stessi byte; pubblicazione durevole e MVCC restano da collegare.
> I [riferimenti fisici](implementazione/full-text-riferimenti.md) conservano posizione
> e stamp dopo il riuso del buffer WAL, senza anticipare commit o visibilita.
> La [directory privata delle righe](implementazione/full-text-righe.md) li risolve
> sotto lease; la mappa immutabile pubblicata del delta resta da collegare.
> Nessun benchmark del motore full text completo.

La prima versione cerca termini e frasi in campi testuali scalari di una Serie, insieme
ai filtri strutturati. Ranking, fuzzy search, sinonimi, wildcard testuali, stemming e
array di testi richiedono decisioni successive. Il [formato binario](formato-indice-full-text.md)
è separato dal formato documentale; il [caso NNTP](valutazione/caso-duso-nntp.md) resta
un'applicazione del motore general-purpose.

## Contratto della Serie

Ogni indice full text è una dichiarazione immutabile per generazione:

| Campo | Regola |
|---|---|
| `index-id` | `u64` positivo, allocato dal catalogo della Serie; mai riusato, neppure dopo drop |
| `name` | alias UTF-8, 1–64 byte, univoco fra gli indici della Serie; non diventa un percorso filesystem |
| `generation-id` | `u64` positivo crescente per indice; esaurimento rifiutato, nessun wrap |
| `contract-version` | versione del contratto che introduce la generazione |
| `profile` | `unicode-word-18.0.0-v1` nella prima versione |
| `fields` | lista ordinata per `field-id`, senza duplicati di ID, alias o percorso |
| campo | `field-id u16` positivo; alias UTF-8 1–64 byte; percorso non vuoto di chiavi testuali CBOR, attraverso sole mappe, entro 100 livelli |
| `analysis-limits` | byte di testo, byte per termine, token per documento/indice, byte dei buffer preparati e unità di analisi |

Alias e percorsi sono confrontati byte per byte, senza case folding. Un percorso assente
non produce token; una stringa vuota produce zero token; `null`, array, numeri o altri
valori presenti sono errori di tipo. Il contratto continua a validare i documenti prima
della scrittura. Per un indice aggiunto su dati esistenti, un valore incompatibile o oltre
budget fa fallire il build esplicitamente: nessun documento viene omesso in silenzio.

Il catalogo conserva la generazione desiderata, le precedenti ancora possedute da reader
e le generazioni esplicitamente ritirate in attesa di cleanup. Ogni generazione conserva
la propria dichiarazione completa. La rimozione del record di ritiro avviene solo dopo
la verifica del cleanup; gli ID rimangono non riutilizzabili attraverso i contatori.
Al massimo due generazioni per indice sono mantenute in costruzione/lettura/ritiro:
un terzo cambio viene rifiutato finché una precedente non è stata liberata.

## Profilo di analisi

`unicode-word-18.0.0-v1` fissa la seguente sequenza:

1. Validazione della stringa come sequenza di scalari Unicode, con input UTF-8 valido.
2. NFC secondo [UAX #15 revisione 58](https://www.unicode.org/reports/tr15/tr15-58.html).
3. Case folding completo, con mapping **C + F**, esclusi **S e T**, di
   [CaseFolding-18.0.0.txt](https://www.unicode.org/Public/18.0.0/ucd/CaseFolding.txt).
4. Nuova NFC, poi confini di parola predefiniti di
   [UAX #29 revisione 49](https://www.unicode.org/reports/tr29/tr29-49.html), senza tailoring.
5. Conservazione dell'intero segmento se contiene almeno uno scalare delle categorie
   generali Unicode `L*` o `N*`; gli altri segmenti non diventano token. Codifica del
   termine come UTF-8 del segmento trasformato. Posizioni consecutive da zero per campo.

Accenti e segni interni a una parola rimangono; nessuna rimozione di stopword, sostituzione
di apostrofi, normalizzazione di compatibilità o inferenza della lingua. La segmentazione
predefinita non promette un'analisi linguistica di ogni lingua. Testo originale e Message-ID
rimangono invariati. Non si usano automaticamente tabelle di una diversa versione di SBCL.
Una versione non supportata produce un errore esplicito di profilo non supportato.

Versione, SHA256 e licenze dei file UCD usati per le tabelle sono conservati nei
[dati Unicode](../data/unicode/18.0.0/README.md), inclusi normalizzazione, categorie,
case folding e word break. La prima implementazione verifica i corpus ufficiali
della stessa release; questi controlli non qualificano le integrazioni ancora mancanti.

## Query e risultati

Le foglie AST sono mappe CBOR con i seguenti campi testuali esatti; le chiavi duplicate,
quelle sconosciute e i tipi errati sono rifiutati. In Common Lisp rimangono dati.

| Chiave | `text-match` | `text-phrase` |
|---|---|---|
| `op` | stringa `text-match` | stringa `text-phrase` |
| `index` | alias dell'indice, obbligatorio | alias dell'indice, obbligatorio |
| `field` | alias di un campo dell'indice | alias di un campo dell'indice |
| `text` | stringa da analizzare con il profilo della generazione | stessa regola |
| `mode` | stringa `all` oppure `any`, obbligatoria | vietata |

`all` opera sull'insieme dei termini distinti; ripetere una parola non cambia il match.
`any` è l'unione. La frase conserva ordine e ripetizioni: ogni termine deve occupare
la posizione precedente più uno, nello stesso campo e nella stessa versione. Query senza
termini dopo l'analisi: `invalid-query`. Foglie su campi diversi si combinano con l'AST
booleano esistente. Il complemento di `not` include tutti i documenti vivi visibili,
anche privi del campo; richiede l'enumerazione MVCC, non il solo insieme dei posting.

Prima dell'esecuzione M15 fissa snapshot, versioni di contratto, generazione per ciascun
indice e ordinamento. In assenza di un ordine esplicito usa `_id` crescente come byte;
ogni altro ordine termina con lo stesso spareggio. Le query iniziali sono su una Serie.
Il filtro di gruppo NNTP su appartenenze in un'altra Serie è una combinazione applicativa
sullo stesso snapshot di Archivio, con deduplicazione per Message-ID.

Ogni candidato porta Serie, segmento, riga e generazione; hint e MVCC risolvono chiave,
CSN e versione visibile. Termini e filtri della stessa foglia/AST si applicano a quella
versione; non si intersecano termini appartenenti a due versioni diverse della chiave.
Le foglie vengono prima valutate per riga/versione; solo dopo si combinano candidati
visibili e si deduplicano le chiavi. Il fetch segue i controlli CRC e identità ordinari.

La risposta logica contiene snapshot, generazioni usate, risultati ordinati e stato
terminale. I batch intermedi sono provvisori fino a `complete`; errore, timeout o
cancellazione rendono incompleta l'operazione e non certificano il prefisso ricevuto.
`limit` termina regolarmente il prefisso richiesto con `complete`, senza promettere il
conteggio totale. Nella prima versione non esiste cursore riprendibile fra richieste:
una nuova richiesta crea una nuova vista, salvo snapshot esplicitamente ancora valido.
Framing e envelope di rete generali rimangono quelli di ADR-0029.
Il `limit` si applica dopo filtri e ordinamento: i primi N posting non sono necessariamente
i primi N risultati. Un accumulatore top-N usa memoria limitata; l'uscita anticipata è
ammessa solo se il piano dimostra che nessun candidato residuo può precedere il prefisso.

## Confini tra moduli

Le operazioni qui sotto sono contratti logici, non nomi di funzioni già esportate.
Gli ingressi sono immutabili o capacità con proprietario; le uscite usano buffer del
chiamante. Gli esiti contengono codice, fase e contatori, senza cambiare ownership in
caso di rifiuto. Ogni richiesta asincrona ha una sola continuazione terminale.

| Operazione | Proprietario e ingresso | Esito e obblighi |
|---|---|---|
| Analizzare | worker M06: documento, dichiarazione, scratch privato | termini/posizioni e limite superiore dei byte, oppure errore; non scrive stato di Serie |
| Ammettere | writer M01/M06: buffer preparati, versione/generazione, budget | riserva delta, staging e costo indice; rifiuto prima di SEAL/PREPARE; una riserva non è un commit |
| Pubblicare | writer: esito committed e buffer già riservati | rende visibili documento e posting insieme prima di H/ACK; abort libera le riserve |
| Acquisire vista | M15 con M08: snapshot e indici richiesti | vista completa fissata, oppure indice non disponibile; nessuna attesa in EBR |
| Iterare e verificare | compiti M15/M06: vista e budget della query | candidati, controllo MVCC e risultati nel buffer; ripartenze limitate e stato terminale |
| Costruire/verificare file | worker M06 con M03/M12 e pool I/O: segmento, hint e configurazione verificati | file `.tmp` completo e validato, oppure errore; nessuno swap dal worker |
| Installare copertura | writer: risultato del build e identità della vista sorgente | adotta solo copertura ancora valida; un cambio di inventario richiede riconciliazione |
| Ritirare | catalogo M17, writer, M08/M11 | decisione di ritiro, poi quiescenza, chiusura e cleanup idempotente |

Le riserve dei record prepared restano possedute dalla transazione fino all'esito
autorevole. Dopo DECISION non si può convertire un'insufficienza di memoria in abort:
un errore inatteso di pubblicazione segue fail-stop e recovery, senza ACK riuscito.
Una preparazione con contratto superato viene rifiutata con `contract-changed` e può
essere rianalizzata fuori dal writer entro un numero finito di tentativi.

## Delta e frontiere

Il delta è organizzato in blocchi preallocati di coppie campo/termine, righe e posizioni.
I byte non pubblicati restano privati del writer. Un reader acquisisce una vista con
frontiera immutabile: modifiche successive non estendono i blocchi che può leggere.
I buffer preparati sono ordinati per campo/termine/riga e formano run immutabili;
la query consulta tutti i run della propria frontiera, entro il budget. La mappa delle
righe del delta fa parte della vista e risolve offset e CSN; il passaggio a un `.idx`
costruito con l'hint del CLOSED rimappa esplicitamente le righe, senza riusare ordinali
di un'altra mappa. La vista precedente conserva la propria mappa fino alla quiescenza.
L'indicizzazione di un lotto si prepara in staging prima della decisione. La pubblicazione
segue il protocollo esistente: aggiornamento delle entry documentali con seqlock,
completamento dei delta, pubblicazione dei riferimenti/frontiere e infine avanzamento
di H e ACK. Nessuna copia integrale della tabella primaria per commit. Il reader fissa
lo snapshot prima di acquisire la vista e verifica le frontiere pubblicate compatibili;
un'acquisizione superata viene ripetuta entro il limite dei tentativi. Un vecchio reader
termina sulla vecchia vista, protetta dagli stessi contratti MVCC/EBR.

Alla rotazione il delta diventa una fonte congelata del `CLOSED` e resta ricercabile
fino all'installazione del suo `.idx` verificato. Un file assente non crea una finestra
vuota. Anche i delta congelati e le viste trattenute contano nel budget della Serie;
la pressione produce backpressure limitata prima dell'ammissione di nuove scritture.

## Generazioni e costruzione concorrente

Gli stati seguenti sono derivati in memoria; la configurazione e i ritiri sono durevoli
nel catalogo. Il semplice avanzamento di un CSN non è prova di copertura.

| Stato | Query nuove | Transizione ammessa |
|---|---|---|
| `BUILDING` | `index-unavailable` per la generazione desiderata | cattura del delta attiva, segmenti/dati precedenti in costruzione |
| `READY` | vista completa acquisibile | ogni nuova pubblicazione mantiene la copertura; perdita di una fonte porta a `UNAVAILABLE` |
| `UNAVAILABLE` | errore esplicito | rebuild; corruzione di file definitivo richiede nuova generazione |
| `RETIRING` | nessuna nuova acquisizione | reader già ammessi, poi cleanup autorizzato |
| `RETIRED` | nessuna | completamento del cleanup e rimozione del relativo record di ritiro |

Per aggiunta, modifica del profilo o rebuild con nuova generazione:

1. Il catalogo decide con durability `:strong` la nuova dichiarazione e la conserva con
   la precedente. Le nuove query che la richiedono restano indisponibili fino a readiness.
2. Il writer adotta la dichiarazione a un confine di pubblicazione: deve avere completato
   i prepared e i lotti già decisi con il vecchio contratto. L'adozione usa ammissione e
   attese finite; non trattiene un worker né blocca l'intero Archivio. Le preparazioni
   non ancora ammesse con il contratto precedente vanno rianalizzate.
3. Nello stesso passo fissa inventario e frontiere iniziali e attiva la cattura dei
   posting della nuova generazione per ogni successiva scrittura ammessa. Tutti i PUT
   committed nel prefisso iniziale, comprese le versioni storiche fisicamente presenti,
   vengono analizzati in background; delete e abort non producono termini.
4. Ogni segmento ha copertura identificata da Serie, segmento, lunghezza valida, hint
   verificato e generazione. Per l'ACTIVE contano gli intervalli di record pubblicati
   coperti dai blocchi. Prima e dopo il confine di cattura non devono esserci buchi o
   doppie emissioni; un CSN di Archivio da solo non identifica questi intervalli.
5. Compaction e rotazione cambiano l'inventario: i risultati del build per fonti obsolete
   non si installano; si usano le nuove fonti o i delta congelati. Le capacità I/O
   possiedono il file per la durata del compito; descrittori e buffer non dipendono da
   un puntatore EBR conservato durante l'attesa. Pin MVCC e memoria del build sono limitati.
6. Il worker propone una vista completa; il writer controlla configurazione corrente,
   inventario e frontiere, incorpora il delta già catturato e pubblica `READY` con un solo
   scambio in memoria. Un cambio concorrente invalida la proposta; i tentativi sono limitati.

Il writer continua a pubblicare i commit ordinari entro i budget. Se il build non riesce
a completarsi entro i propri limiti, resta un errore amministrativo dichiarato: nessuna
promessa di completamento sotto scritture illimitate. Le vecchie query hanno già fissato
uno snapshot; non richiedono che la generazione precedente indicizzi commit successivi.

## File, recovery e ritiro

Il nome derivato è `segments/<segment-id>.ft-<index-id>-<generation-id>.idx`, con interi
decimali canonici senza zeri iniziali. La configurazione del catalogo e il segmento
nominato dal manifest autorizzano quella famiglia di derivati.

Un worker costruisce in un'area `.tmp` privata dello stesso filesystem, verifica il
file, esegue flush e sincronizzazione necessari e propone l'installazione. Per lo stesso
segmento/indice/generazione esiste un solo costruttore attivo: il ticket locale e limitato
è assegnato dal writer. Se un file finale già esiste, viene verificato e riusato;
non si rinomina sopra un file definitivo esistente. La rinomina completa un derivato
di una configurazione già decisa, poi la directory viene sincronizzata. In crash si può
perdere disponibilità dell'indice, senza perdere il commit del documento.

| Situazione al riavvio | Esito |
|---|---|
| Configurazione valida, file finale e hint integri e coerenti | verificare la copertura prima di readiness |
| File finale assente | ricostruire, query non disponibili fino a copertura completa |
| `.tmp` senza installazione completata | non usare come copertura; eliminare il temporaneo non pubblicato e ricostruire |
| File finale corrotto o associato a un altro hint | segnalare, generazione `UNAVAILABLE`; nuova generazione per il rebuild |
| Generazione esplicitamente ritirata nel catalogo | dopo recovery non ci sono reader: completare il cleanup idempotente |
| File definitivo di generazione/segmento mai nominato | anomalia, conservare; nessuna eliminazione per assenza |
| Documento/segmento sorgente non integro | applicare gli stati di salute del motore; un rebuild dell'indice non ripara il dato |

Il drop dell'indice decide il ritiro nel catalogo; un cambio di generazione decide
esplicitamente anche il ritiro della precedente, preservandone il descrittore per i
reader già ammessi. Un segmento rimosso da EDIT autorizza il cleanup dei suoi derivati
dopo quiescenza. Il restore ricava generazioni e configurazioni dal catalogo ripristinato
e ricostruisce i derivati rispetto ai segmenti ripristinati: un file più recente non basta.
Il ritiro ferma nuove autorizzazioni di build/installazione e attende anche la chiusura
dei ticket già concessi, con cancellazione e completamento limitati. Il descrittore di
ritiro resta autorevole fino al termine di reader, ticket e cleanup: una rinomina I/O
già autorizzata non può creare un file definitivo dopo la rimozione di tale descrittore.

## Budget iniziali

Questi **default di progetto** sono politiche configurabili, da qualificare; non sono
stime di throughput. Un limite effettivo è il minimo fra formato, dichiarazione e budget
di Serie/worker. Le somme sono controllate prima delle allocazioni, senza overflow.

| Risorsa | Default |
|---|---|
| Indici full text per Serie; campi per indice | 8; 16 |
| Generazioni contemporanee per indice | 2, inclusi build, reader e ritiro |
| Testo UTF-8 di input per documento, sommato sui campi di un indice | 16 MiB |
| Termine dopo trasformazione | 1.024 byte UTF-8 |
| Token/posizioni per documento e indice | 1.048.576, sommati su tutti i campi |
| Lavoro di analisi per documento e indice | 268.435.456 unità; ogni scalare consumato/emesso o confronto di normalizzazione costa almeno una unità |
| Memoria di analisi per worker e buffer preparati per richiesta | 64 MiB ciascuno; input e riserve già possedute conteggiati nei rispettivi pool |
| Delta della Serie, inclusi congelati, riserve e vecchie viste | 256 MiB complessivi |
| Memoria di build per Serie | 128 MiB, un build per indice e massimo due compiti di build per Serie |
| File `.idx` full text per segmento/indice/generazione | 16 GiB; budget distinto dal segmento dati |
| Spazio temporaneo di build per Serie | 32 GiB complessivi; ammissione prima di creare i file |
| META di un `.idx` | 64 KiB |
| AST di query; profondità; token analizzati per foglia | 256 nodi; 32 livelli; 256 token |
| Testo della query | 64 KiB complessivi prima e dopo normalizzazione |
| Memoria temporanea; posting visitati per query | 32 MiB; 1.000.000, conteggiati su tutte le foglie/segmenti |
| Budget di lavoro della query | 4.000.000 unità: avanzamento posting, confronto di posizione/byte, sonda nel dizionario o documento enumerato/verificato costa almeno una unità; include l'analisi del testo della query |
| Risultati; durata della query | 10.000; 5 secondi su orologio monotono iniettabile |
| Durata del build; riproposte di una vista invalidata | 300 secondi; 8 tentativi |

Budget globali dei pool, snapshot e code restano quelli del motore. Una capacità configurata
inferiore al massimo di una singola richiesta possibile provoca rifiuto esplicito, non una
prenotazione parziale. Il conteggio delle unità copre anche scansioni per `not` e confronti
di posizioni ripetute; il solo limite sul numero di posting non basta.
Le durate sono deadline logiche, controllate ai confini dei compiti e prima dell'esito;
non costituiscono una garanzia realtime o la possibilità di interrompere qualsiasi I/O.
Anche normalizzazione e tokenizzazione procedono per compiti limitati con contesto
privato riprendibile; un lungo testo con segni combinanti non autorizza un tratto di
calcolo illimitato. I limiti si applicano congiuntamente: non si promette di raggiungerli
tutti contemporaneamente sulla stessa richiesta.

M06 calcola prima del commit un limite superiore conservativo dei byte serializzati
([formula del formato](formato-indice-full-text.md#limite-superiore-e-rotazione)). M01 riserva
anche quel costo: se il segmento supererebbe il budget di un indice, propone la rotazione
prima dell'append. Se una singola richiesta non entra in un segmento vuoto, è rifiutata.
La rotazione rispetta gli intenti pendenti di ADR-0041; non avviene a metà di un prepared.

## Esiti

| Codice logico | Significato |
|---|---|
| `complete` | risultato richiesto completato sulla vista dichiarata |
| `invalid-query`, `invalid-document` | struttura, tipo o testo non valido |
| `unsupported-profile`, `unsupported-format` | versione non supportata; nessun ripiego implicito |
| `index-unavailable` | generazione richiesta non pronta o copertura mancante |
| `index-corrupt` | fallimento di integrità del derivato; evento e generazione identificati |
| `contract-changed` | preparazione precedente alla dichiarazione adottata; nessun commit eseguito |
| `resource-limit`, `query-budget-exceeded` | capacità di ammissione o lavoro esaurita; non è un risultato completo |
| `cancelled`, `timeout`, `snapshot-too-old` | richiesta terminata esplicitamente, cleanup delle risorse possedute |
| `build-failed` | build terminato senza readiness, con fase e causa conservate |

Gli errori dei dati sorgenti e gli stati `FAULTED`/`DEGRADED` rimangono quelli del motore.
Il retry di una richiesta che ha già una decisione durevole segue l'identità della
transazione: questi codici non autorizzano a ripetere una pubblicazione alla cieca.

## Criteri di accettazione

Queste prove sono **da implementare** nella fase 8. Ogni riga richiede attesi e ingressi
preregistrati, controllo negativo dell'oracolo e conservazione di tutti i tentativi.

| Requisiti | Prova e condizione di riuscita |
|---|---|
| REQ-SEC-003, REQ-SEC-007 | Corpus ufficiali Unicode 18.0.0, mapping C/F, casi manuali sotto e confronto con analisi indipendente; uguali token e posizioni |
| REQ-SEC-003, REQ-SEC-008 | Fixture binarie costruite indipendentemente, file vuoto, due campi, termini ripetuti, interi ai limiti, troncamenti a ogni confine e mutazioni; rifiuti anche con CRC valido |
| REQ-SEC-004, REQ-SEC-009 | Vecchia versione con un termine e nuova con un altro; `all` non li combina; delete/abort, snapshot storici, ACTIVE/CLOSED e compaction danno gli stessi risultati della scansione |
| REQ-SEC-005, REQ-SEC-009 | Writer fra taglio iniziale e cattura, rotazione/MERGE durante build, proposta con inventario superato, cambio profilo e ripartenza a ogni passo; nessun buco prima di READY |
| REQ-SEC-005, REQ-SEC-008 | Hint riordinato, CRC/ID alterati, file assenti, definitivi corrotti, temporanei e file sconosciuti; readiness e cleanup seguono le tabelle, senza eliminare anomalie |
| REQ-SEC-006, REQ-SEC-010 | Ogni budget a limite, limite meno uno e limite più uno; saturazione prima di PREPARE/SEAL; nessun errore di capacità normale dopo DECISION; cancellazione e rilascio esatto delle riserve |
| REQ-SEC-009, REQ-SEC-010 | Reader lento, scadenza snapshot, errore dopo un batch e drop della generazione; un prefisso senza `complete` non è consumato come successo |
| REQ-SEC-006 | Carico su più Serie e interferenza con GET/compaction; misure separate, nessuna scrittura condivisa per documento |

Corpus minimo manuale, senza invocare un analizzatore per produrre gli attesi:

| Documento/campo | Termini e posizioni attesi |
|---|---|
| `Subject = Caffè CAFÉ` | `caffè: [0]`, `café: [1]` |
| `corpo = Stra\u00DFe` (dove `\u00DF` indica U+00DF, non sei byte letterali) | `strasse: [0]` |
| `corpo = alpha, beta alpha` | `alpha: [0, 2]`, `beta: [1]`; frase `alpha beta` sì, `beta beta` no |
| un campo `alpha`, un altro `beta` | la frase `alpha beta` non corrisponde in nessun campo |
| campo assente oppure stringa vuota | nessun termine; `not text-match(..., alpha, all)` include il documento vivo |

Una seconda fixture usa `cafe` seguito da U+0301 e deve produrre `café`; `cafe` senza
accento non corrisponde. I test distinguono testo effettivo e notazione degli scalari.
Le [misure](13-benchmark.md#ricerca-full-text) partono soltanto dopo queste verifiche.
