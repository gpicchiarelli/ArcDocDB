# ADR-0053 — Ricerca full text con indici invertiti dedicati

- **Stato:** Accettata per il progetto; implementazione e qualifica da produrre
- **Data:** 2026-10-15
- **Rapporto con la specifica:** su richiesta dell'autore aggiunge la ricerca full text
  a «Secondary index», «Query» e «Benchmark»; estende lo scope v1 di
  [ADR-0030](0030-scope-v1.md), nella fase 8. Integra
  [ADR-0026](0026-indici-secondari-segmentati.md) e
  [ADR-0029](0029-interfacce-protocollo-query-contratto.md), senza sostituirne gli altri contratti.
- **Riferimenti:** [indici](../08-indici.md#ricerca-full-text),
  [caso NNTP](../valutazione/caso-duso-nntp.md), REQ-SEC-003…REQ-SEC-006, INV-I4

## Contesto

Uguaglianza, prefissi e categorie non bastano per cercare parole e frasi nel contenuto
di un documento. Il futuro server NNTP in Common Lisp richiede di considerare anche
la ricerca in oggetto, autore e corpo degli articoli, combinata con gruppo e data.
La funzionalità appartiene al motore general-purpose: MIME e protocollo NNTP restano
responsabilità dell'applicazione. La richiesta attuale è progettuale, senza sviluppo di codice.

## Decisione

### Contratto e semantica

Il contratto della Serie dichiara indici di tipo **full-text**, distinti dagli indici
di uguaglianza, categoria e intervallo. Ogni dichiarazione identifica nome, campi
testuali scalari e profilo di analisi immutabile e versionato. Un campo assente o una
stringa vuota non produce termini; un valore di tipo errato segue il rifiuto previsto
dal contratto. Il testo originale resta nel documento, senza normalizzazioni distruttive.

Il profilo identifica versione Unicode, normalizzazione, case folding, segmentazione
e ogni parametro linguistico. Il profilo base usa la sequenza **NFC → case folding
Unicode completo → NFC → segmentazione in parole**; conserva i segmenti che contengono
lettere o numeri, conserva gli accenti e non applica stemming né stopword implicite.
Regole e tabelle sono fissate dalla versione del profilo, mai dalla locale del processo
o dall'ultima versione disponibile. Documento e query usano esattamente lo stesso profilo.
Eventuali profili linguistici aggiuntivi richiedono un contratto verificabile proprio.

L'AST di query di ADR-0029 si estende con due predicati, ciascuno su un campo dichiarato:

| Predicato logico | Significato |
|---|---|
| `text-match(campo, testo, all/any)` | analizza il testo della query; richiede tutti oppure almeno uno dei termini |
| `text-phrase(campo, testo)` | richiede gli stessi termini in posizioni consecutive, nello stesso campo |

Le foglie si combinano con `and/or/not` e con i filtri strutturati esistenti. Una frase
non attraversa due campi. Il complemento di `not` si calcola sull'insieme dei documenti
vivi visibili nello snapshot della query, inclusi quelli privi del campo. Una query che
dopo l'analisi non contiene termini è rifiutata esplicitamente. Non si esegue codice
ricevuto dal client. Nomi e codifica dei nodi sul wire si fissano con la superficie API
della fase 8–9; qui è fissata la semantica, non un parser testuale.

La prima versione offre corrispondenza booleana e frasi, con ordinamento esplicito e
spareggio stabile per `_id`. Ranking per rilevanza (ad esempio BM25), fuzzy search,
sinonimi e prossimità diversa dalla frase richiedono decisioni successive. Le frequenze
conservate nell'indice non implicano un ranking già definito.

### Indice invertito per segmento

Ogni segmento `CLOSED` ha un file immutabile dedicato per indice full text, nella
famiglia `.idx` di ADR-0026. Il contenuto logico è:

| Sezione | Contenuto |
|---|---|
| Identità | Serie, segmento, nome/generazione dell'indice, contratto e profilo di analisi |
| Dizionario | coppie `(campo, termine)` ordinate e riferimenti alle posting list |
| Posting list | ordinali di riga ordinati, frequenza del termine nella riga e riferimenti alle posizioni |
| Posizioni | ordinali dei token nel campo, necessari alle frasi; niente attraversamento di campi |
| Controlli | conteggi, limiti delle sezioni e CRC32C; eventuale Bloom sui termini solo come filtro negativo |

La riga identifica il record tramite l'hint dello stesso segmento: chiave e CSN non
sono sostituiti da un identificativo testuale globale. Le posting list possono usare
delta encoding e blocchi per saltare intervalli; codec, offset e limiti binari si fissano
prima dell'implementazione con una versione esplicita del tipo di indice. Il formato
dei record documentali v1/v2 non cambia. Non si adotta una dipendenza esterna.

Per l'`ACTIVE` si mantiene un delta in memoria coerente con la frontiera pubblicata,
in array compatti e blocchi leggibili in modo stabile. Tokenizzazione e preparazione
dei buffer avvengono sui worker di calcolo prima di sottoporre il lavoro al writer;
contratto e generazione vengono ricontrollati prima del commit. La pubblicazione del
delta resta seriale sul solo writer della Serie. Query e costruzione dei file `CLOSED`
si distribuiscono per segmento, con budget propri; nessun nuovo lock o contatore globale
per documento e nessun secondo scheduler full text.

### Commit, snapshot e manutenzione

L'indice è **derivato dai documenti committed**, senza WAL o commit autonomo. Il punto
di atomicità durevole resta SEAL per la scrittura locale e DECISION per la transazione
multiserie. Prima di avanzare l'orizzonte di visibilità e confermare la pubblicazione,
ogni indice full text utilizzabile deve includere anche il delta dei nuovi record.
Se la pubblicazione derivata fallisce dopo la decisione, si completa o si dichiara il
guasto secondo i contratti esistenti: non si conferma uno stato ricercabile incompleto.

I posting sono **candidati**. Prima di restituire un risultato si risolvono chiave,
esito committed e versione effettivamente visibile nello snapshot, con le versioni
trattenute del motore; il confronto con la sola versione corrente non basta. Termini
e filtri devono riferirsi alla stessa versione. Aggiornamenti e tombstone rendono i
vecchi posting invisibili alle nuove viste; una vista precedente conserva i risultati
dovuti finché è valida. Ogni documento viene emesso una sola volta e il record letto
passa le verifiche di integrità ordinarie.

CLEAN/MERGE ricostruiscono dizionario, posting e posizioni per le righe dei nuovi
segmenti, conservando le versioni necessarie agli snapshot: non copiano ordinali
legati ai vecchi hint. Pubblicazione e reclaim seguono EDIT ed EBR già previsti.

Aggiunta di un indice o modifica dell'analizzatore crea una **nuova generazione**.
Il contratto nel catalogo è la decisione durevole; readiness e file sono stato derivato
ricostruibile. Il build copre i segmenti e il delta concorrente fino a una frontiera
pubblicata, poi espone atomicamente una vista completa sulla Serie. Una query fissa
generazione e profilo per tutta la propria durata; non mescola analizzatori. La vecchia
generazione resta utilizzabile dai reader già ammessi fino alla loro quiescenza.

File assente, CRC errato, identità incoerente o rebuild incompleto non significano
«nessun risultato». Recovery e restore ricostruiscono dagli stessi documenti e dal
contratto autorevole; finché manca copertura completa la query riceve un errore
esplicito di indice non disponibile. Un eventuale ripiego su scansione deve applicare
la stessa semantica e rispettare i budget, senza essere presentato come indice pronto.
Un file corrotto si segnala e si esclude; la sua sostituzione segue il protocollo di
pubblicazione dei derivati, senza modificare o cancellare alla cieca file definitivi.

### Risorse e stato del lavoro

Sono obbligatori limiti configurati per byte di testo analizzati, lunghezza dei termini,
token e posizioni per documento, dimensione del delta, nodi e profondità della query,
posting visitati, memoria temporanea, risultati e durata. Il superamento in scrittura
è rifiutato prima della decisione durevole: nessun testo viene indicizzato a metà in
silenzio. In lettura si restituisce un errore esplicito se il budget non consente il
completamento; un `limit` richiesto è distinto da risultati parziali per esaurimento
del budget. Cancellazione, parcheggi e I/O seguono il modello di esecuzione del motore.

M06 possiede i derivati full text e M15 i predicati e gli iteratori. La fase 8 comprende
implementazione e verifica; questa decisione aggiunge il requisito e i criteri di
accettazione, senza dichiarare disponibili codice, prove di correttezza o prestazioni.

## Conseguenze

- La ricerca testuale diventa una capacità esplicita del progetto, anche per NNTP.
- Posizioni e delta aggiungono memoria, spazio su disco e costo di scrittura/rebuild:
  i target delle query semplici non si trasferiscono alla ricerca full text.
- La disponibilità della ricerca dipende dalla copertura verificata dell'indice; la
  perdita di un derivato non modifica la fonte di verità documentale.

## Alternative considerate

- Scansione del testo a ogni query: utile come oracolo, costosa sui corpus grandi.
- Riutilizzare gli indici di categoria senza posizioni: non risolve le frasi.
- Motore esterno: aggiunge dipendenze e un secondo protocollo di consistenza e recovery.
- Indicizzazione asincrona con risultati incompleti dopo il commit: incompatibile con
  il contratto di visibilità scelto.

## Valutazione

Verifiche **da realizzare**, tracciate in REQ-SEC-003…REQ-SEC-006: confronto con scansione
indipendente per termini/frasi e Unicode; aggiornamenti, delete, abort e snapshot;
`ACTIVE` più `CLOSED`; CLEAN/MERGE; build concorrente e cambio generazione; restart,
restore e corruzione dei derivati; saturazione e cancellazione. Misure e corpus sono
descritti in [13 Benchmark](../13-benchmark.md#ricerca-full-text). Nessuna di queste
prove è già dimostrata dai test esistenti del primary index o della prova verticale.

Il pattern di riferimento è l'indice invertito posizionale, descritto in
[Introduction to Information Retrieval, §2.4.2](https://nlp.stanford.edu/IR-book/html/htmledition/positional-indexes-1.html).
Per l'analisi Unicode i riferimenti sono
[UAX #29](https://www.unicode.org/reports/tr29/) e
[UAX #15](https://www.unicode.org/reports/tr15/); la versione concreta deve essere
fissata nel profilo, non desunta da questi collegamenti aggiornabili.
