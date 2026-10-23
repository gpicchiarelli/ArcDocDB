# Socket Unix di produzione — profilo M1

Profilo ristretto realizzato per l'indicazione dell'autore del 2026-10-22:
startup → recovery → admission → PUT/GET da processi distinti. Completa
[il bootstrap](production-engine-bootstrap.md), riusa ADR-0055 e il framing
di [ADR-0056](../adr/0056-sessione-locale-m16.md). I default multithread e
multiserie della proposta M16 restano fuori da questo profilo.

## Contratto fissato prima del codice

Il server e' una libreria separata `arcdocdb/local`, senza avvio al caricamento.
Il thread chiamante possiede motore e trasporto. Fino a otto connessioni sono
servite a passi non bloccanti, con una richiesta in volo per connessione.
Il listener viene aperto soltanto dopo il ritorno READY di `apri-motore`.
Nessun test ricostruisce a mano lo stato del server.

Frame: `u32be length | CBOR [1, kind, id, code, payload]`. HELLO/WELCOME,
correlazione, mappe ordinate e stati seguono il contratto della sessione.
Il limite del server e' 65.536 byte di corpo; il client richiede almeno 4096,
al piu' 17.825.792. Si negozia il minimo; in-flight e' sempre 1.
HELLO/WELCOME hanno limite 4096. Gli ID u64 sono positivi e strettamente
crescenti; nessun riuso o ripetizione automatica dopo una disconnessione.

| Opcode | Argomenti | Risultato con status 0 |
|---|---|---|
| 0 PING | `null` | `null` |
| 1 PUT | `[key: bstr, document: bstr]` | CSN unsigned u64 durevole |
| 2 GET | `key: bstr` | `[true, document: bstr]` oppure `[false, null]` |
| 3 DELETE | `key: bstr` | CSN unsigned u64 durevole, anche se gia' assente |

Chiavi binarie da 1 a 1024 byte; documenti da 1 a 60.000 byte. Il documento
contiene un solo item CBOR con testate minime e UTF-8 valido, profondita'
massima 100, verificato separatamente dal contenitore. Il profilo non
normalizza ne' promette ordine/deduplica delle mappe interne al documento.
L'envelope e le mappe del controllo sono deterministici, con forma esatta;
nessun byte esterno passa dal reader Lisp. Non c'e' payload di batch implicito.

Status 1: argomenti invalidi; 2: capacita' esaurita; 3: motore indisponibile;
4: opcode non supportato; 5: limite superato. Sono rifiuti prima
dell'ammissione al motore, con payload `null`. Errori di envelope, handshake,
ID o trasferimento chiudono la connessione. Un guasto dopo l'ammissione
che impedisce una risposta certa chiude; il client segnala esito ignoto.
PUT/DELETE rispondono solo dopo il completamento strong del motore.

Il buffer massimo di risposta e' posseduto prima del dispatch. GET richiede
un frame negoziato di almeno 60.032 byte, sufficiente per qualunque risultato
del profilo; altrimenti riceve status 5 prima della lettura. Il valore viene
copiato e il GET concluso prima di attendere il peer: nessun pin EBR o lease
writer trattenuto durante l'invio. Il limite e' conservativo e dichiarato.

## Risorse e ciclo di vita

Buffer di ingresso/uscita e scratch hanno capacita' finite per connessione,
allocate prima del listener. Il prefisso non causa allocazioni proporzionali
a lunghezze non verificate. Ricezione/invio mantengono offset espliciti;
letture esatte dei confini conservano nel kernel i frame accorpati successivi.
Nessun thread per connessione, spin illimitato o attesa del peer nel motore.
Il decoder usa lo scratch della connessione; ogni frame produce una struttura
envelope di dimensione fissa e copie degli argomenti entro i limiti dichiarati.
Queste allocazioni transitorie sono seriali nell'attore e non costituiscono
una coda. Il client verifica il documento con scratch fisso locale alla chiamata.
Il profilo non rivendica assenza di allocazioni o un tetto RSS.

La directory runtime resta bloccata esclusivamente fino alla chiusura del
servizio: il profilo ammette un listener per directory, anche con nomi diversi.
Tutti gli antenati sono mantenuti aperti e le identita' ricontrollate; root e
UID di servizio sono fidati e non devono mutare il namespace durante l'uso,
poiche' bind/chmod Unix operano per pathname.

Clock monotono iniettabile; HELLO entro 5 s dall'accept, frame entro 30 s
dal primo byte, risposta entro 30 s dall'accodamento, idle entro 300 s.
Il progresso parziale non rinnova la scadenza. Un client lento perde la
propria connessione; gli altri continuano nel giro dell'attore.

Path assoluto esplicito, massimo 100 byte UTF-8, nessun NUL. Directory runtime
preesistente 0700 dell'UID di servizio, antenati protetti senza symlink o
scrittura di gruppo/altri; socket 0600. Sono fidati root e UID di servizio.
Le verifiche del namespace e i descrittori posseduti accompagnano il bind.
La directory dei dati e quella runtime sono distinte. Un nodo occupato,
anche orfano dopo SIGKILL, viene conservato e l'avvio fallisce esplicitamente.
L'operatore rimuove l'orfano a servizio fermo, oppure sceglie un nuovo path.
Le prove di restart usano un nuovo path per conservare il nodo del crash.

Arresto: interrompere l'ammissione, chiudere connessioni e listener, rimuovere
solo il nodo con identita' ancora propria, liberare namespace e motore.
Il cleanup tenta tutte le risorse e conserva causa primaria e secondarie.
SIGKILL non esegue cleanup applicativo. Nessun ripiego TCP.

## Metodo preregistrato

1. Fixture wire indipendenti: HELLO, WELCOME, PING, PUT, GET, DELETE, u64,
   limiti esatti, mappe, duplicati, troncature e byte finali.
2. I/O iniettabile: short transfer, EAGAIN, EINTR, EOF, errore, FD zero,
   deadline assolute e invio senza SIGPIPE.
3. Namespace: occupato, link, permessi, sostituzione del nodo e cleanup.
4. Dispatcher reale: invalidita' e saturazione prima dell'append, risposta
   strong, GET copiato, errore ammesso senza falso busy, ID e handshake.
5. Processi indipendenti: server prodotto, client prodotto PUT/GET/DELETE,
   SIGKILL, reopen sullo stesso storage e nuovo path, nuovi commit, secondo
   SIGKILL, terza apertura e confronto esatto di dati e tombstone.
6. Client frammentato, frame accorpati, client lento e altro client operativo;
   listener assente durante recovery, collisione senza distruzione di file.
7. FI `:after-commit` attraverso il callback del motore nel servizio reale:
   client CLI con esito ignoto e nessuna falsa conferma, reopen con valore
   committed presente e CSN successivo 2. Il driver FI e' uno strumento C4
   separato; nessuna opzione di guasto compare nelle CLI di prodotto.

Due letture statiche dell'autore e review indipendente, poi commit di sorgenti
e test; tutti gli agenti chiusi prima delle esecuzioni. Ogni comando diagnostico
usa il recorder. Si conservano anche fallimenti e varianti, con originali
lossless e raccolta comune nel repository. Qualifica e rapporto devono indicare
esattamente piattaforma, sorgente, casi eseguiti e limiti residui.
Nessun benchmark o risultato di prestazione viene dedotto da questa campagna.
La milestone #1 resta aperta finche' tutti i suoi criteri sono dimostrati.

## Ingressi eseguibili

Il server riceve directory dati, path del socket, UUID Archivio/Serie in hex
(32 cifre ciascuno), eventuali `--create` e `--version 1|2`. `--create` e'
solo l'inizializzazione esplicita: non va passato al riavvio. La directory
runtime va predisposta con i permessi dichiarati. Il record `:state :ready`
su stdout segue l'apertura del listener; le diagnostiche vanno su stderr.
SIGTERM/SIGINT avviano l'arresto ordinato del processo CLI.

```text
sbcl --noinform --no-userinit --no-sysinit --script tools/local-server.lisp \
  DATA SOCKET ARCHIVE32 SERIES32 --create
sbcl --noinform --no-userinit --no-sysinit --script tools/local-client.lisp SOCKET put 01 182A
sbcl --noinform --no-userinit --no-sysinit --script tools/local-client.lisp SOCKET get 01
```

Il client rappresenta in hex chiave e documento CBOR, restituisce un record
strutturato e non usa il reader Lisp per gli argomenti. Per esempio `182A`
e' il documento CBOR unsigned 42. Un errore o un esito ignoto produce uscita
non zero; il chiamante decide come risolvere l'eventuale ritentativo.
