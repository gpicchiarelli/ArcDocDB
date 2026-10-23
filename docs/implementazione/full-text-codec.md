# Codec completo degli indici full text

Il [nucleo full text](full-text.md) dispone ora di serializzazione e validazione
delle sei sezioni del [formato v2/type 5](../formato-indice-full-text.md), oltre alla
cornice. Una vista verificata cerca direttamente nei byte serializzati senza ricostruire
il run in memoria. Le API sono in `arcdocdb.fulltext.codec`, codice in
[`src/fulltext/`](../../src/fulltext/), secondo [ADR-0054](../adr/0054-contratto-e-formato-full-text.md).

Il primo impiego rimane il database di un server NNTP Usenet in Common Lisp.
La prova di riapertura usa campi `subject` e `body`; protocollo e decodifica MIME
rimangono responsabilita dell'applicazione. Non viene introdotto un demone NNTP.

## Descrittore e autorita

`crea-descrittore-full-text(meta, identity, segment, source-bytes, hint, hint-start,
hint-end, rows)` e un costruttore freddo. Riceve la dichiarazione META autorevole in
CBOR, identita Serie, segmento e lunghezza del prefisso, byte esatti dell'hint e
una bitmap con un bit per ordinale: uno solo per i PUT committed risolti, anche storici.
Il chiamante deve aver verificato hint, prefisso e decisioni prima di fornire questi dati.
La creazione di questo oggetto non sostituisce quella verifica.

Il costruttore controlla array CBOR definiti/minimi, tre ID u64 positivi, lunghezze,
CRC32C dell'intero span hint, numero di righe e PUT, profilo Unicode 18.0.0/revisione 1,
campi ordinati, alias e percorsi unici, UTF-8 e limiti positivi. Il limite token e entro
u32. Produce copie private di META, identita, campi e bitmap; non trattiene l'hint.
I percorsi hanno 1…100 chiavi testuali; il costruttore corrente ammette fino a 16 campi,
oltre segnala `resource-exhausted`. META e al massimo 64 KiB. `:max-memory` viene
controllato conservativamente prima delle copie e delle tabelle temporanee.
L'ID segmento viene conservato gia boxed in una cella privata creata all'apertura:
la lettura ripetuta di uno slot raw u64 allocava su SBCL x86-64 per ID oltre fixnum.
La cella e immutabile dopo la costruzione e rientra nell'overhead del descrittore.

Un file deve coincidere byte per byte con questo META canonico: non basta un hash
della configurazione. Un hint ricostruito con byte o ordine diversi richiede un nuovo
legame e un nuovo indice. Il CRC identifica i byte secondo il modello di integrita
del formato; non autentica i dati e non dimostra la correttezza dei documenti.

## Scratch e scrittura

`crea-spazio-codec-full-text` prealloca prefissi per LENGTHS, bitmap delle posizioni,
sei offset/lunghezze e uno spazio analitico privato. Capacita configurabili:
`:max-lengths` (default 65536), `:max-positions` (1048576), `:max-term-bytes` (1024),
`:max-memory` (64 MiB). Il conto conservativo comprende payload e 8192 byte di overhead;
non misura memoria dell'intero processo, file sorgenti o tabelle Unicode condivise.
Un file valido puo richiedere piu scratch: il rifiuto e di risorse, non di corruzione.

`dimensione-indice-full-text(run, descriptor, space)` richiede un run sigillato.
Calcola la dimensione esatta, verificando righe ammesse, campi, token per documento,
termini, ordini e copertura delle posizioni. Non e la riserva pre-SEAL/PREPARE del writer.
`scrivi-indice-full-text(run, descriptor, space, buffer, start, end)` ripete il preflight,
controlla alias/capacita e riserva il lavoro del completamento prima di mutare il buffer.
Restituisce la fine effettiva del file; prefisso e coda della destinazione restano invariati.
Un rifiuto di preflight lascia intatta la destinazione. Un errore interno non offre rollback:
il proprietario scarta quel buffer e applica il fail-stop al confine del worker.

La scrittura raggruppa occorrenze in dizionario, stringhe uniche, posting/frequenze e
posizioni; conserva anche le lunghezze dei campi presenti vuoti. Header, riservati,
padding e CRC sono quelli gia definiti da ADR-0054. Gli offset di formato hanno una
sola fonte in `format-constants.lisp`. Nessun I/O, rename, flush o punto di atomicita
durevole viene introdotto dal codec.

## Lettura e ricerca

`verifica-indice-full-text(buffer, start, end, descriptor, space)` restituisce `end`
solo dopo cornice, META atteso e tutte le verifiche locali:

- LENGTHS ordinate/uniche, campi dichiarati, righe PUT della bitmap e riservati zero;
  somma token per documento e totale uguale al numero di posizioni.
- DICT ordinato per campo e byte del termine; stringhe contigue, UTF-8 valido e
  gia un singolo token identico nel profilo dichiarato, senza normalizzazioni implicite.
- Posting contigui con righe crescenti, frequenze positive e riferimenti entro sezione.
- Posizioni crescenti nel posting, entro il campo, senza duplicati fra termini diversi;
  bitmap globale e prefissi dimostrano l'unione esatta `[0, token-count)` per campo.
- Nessun byte o elemento residuo nelle partizioni. Questi controlli valgono anche con
  CRC ricalcolati correttamente.

Le API CPU del codec sono sincrone e hanno un budget di lavoro finito, default
268435456 unita. Conteggiano CRC, confronti, analisi, entry e bitmap; lo scratch e
riusabile dopo errore. L'orchestrazione in compiti del build, I/O e deadline appartiene
al successivo raccordo con M06. Non vi sono allocazioni per entry sul percorso misurato.

`crea-vista-indice-full-text` verifica il file e, sul percorso freddo di apertura,
alloca la vista e copie dei soli sei span. Trattiene il buffer immutabile, non lo scratch.
Il proprietario deve mantenerlo vivo fino alla quiescenza dei reader e non puo riscriverlo.
`corrisponde-riga-indice-full-text(view, row, field, query, mode)` supporta `:all`,
`:any`, `:phrase`, con 1…256 token. Ricerca binaria in DICT, POSTINGS e POSITIONS;
le ripetizioni di una frase richiedono posizioni consecutive nella medesima riga/campo.
Ogni reader usa il proprio spazio query e budget cumulativo; nessuna scrittura nel file
o nella vista condivisa. Il predicato riguarda la versione fisica, senza risolvere MVCC.

## Prove e confini residui

La fixture indipendente [minimum-v2.hex](../../tests/fulltext/minimum-v2.hex) contiene
468 byte: riga 0 `alpha beta alpha`, riga 1 `beta`. SHA256 del file hex:
`d94f6144c7533cc273784446b803a5d872ba44a8d2833ef0c4d8f317ca699f80`.
L'[oracolo C4](../../tools/fulltext-codec-fixture.lisp) non carica il prodotto; genera
CBOR, little-endian e CRC con un algoritmo separato. I byte sono stati congelati
prima della prima esecuzione dell'encoder e vengono rigenerati/confrontati in `make check`.

Quindici test del codec si aggiungono ai 24 del nucleo: identita byte per byte su
32 prefissi, 3744 alterazioni singole, 468 troncamenti, 26 corruzioni semantiche con
CRC corretto, META/hint/configurazioni errate, budget, campi vuoti, quattro reader,
43200 confronti con scansione indipendente e fuzz di 1024 varianti con CRC corretto.
Il fuzz distingue 1020 rifiuti tipizzati e quattro varianti strutturalmente valide;
non confronta il documento sorgente. Dopo warm-up, 1000 scritture/verifiche/ricerche
non allocano byte sullo heap misurato, anche con ID u64 massimo, su SBCL 2.6.9 arm64.
I controlli negativi semantici del nucleo passano da quattro a sei.

La [prova C4 di persistenza](../../tools/fulltext-persistence.lisp) salva il file e
avvia due child SBCL con attese limitate: uno verifica nove query su subject/body,
l'altro rifiuta una posizione incoerente nonostante il CRC corretto. Dimostra il
round trip dopo chiusura normale, non durability dopo perdita di alimentazione o
recovery del motore. La [revisione C1](full-text-codec-decisioni.md) separa questi
risultati dalla qualifica completa.

Restano I/O/publish della generazione, riserve del writer prima della decisione,
inventario/frontiere READY, validazione dell'hint e rianalisi dei documenti,
MVCC, Query Engine e reclaim. REQ-SEC-003…REQ-SEC-010 restano progettati nel loro
perimetro complessivo. Una vista strutturalmente valida non certifica la copertura
di una Serie o una risposta NNTP completa.

La [preparazione documentale](full-text-documenti.md) estrae ora i campi CBOR,
produce un run SEALED e calcola il costo conservativo prima del futuro aggancio al writer.
