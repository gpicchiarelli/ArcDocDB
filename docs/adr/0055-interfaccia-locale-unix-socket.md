# ADR-0055 — Socket Unix locale come interfaccia prioritaria

- **Stato:** Accettata per indirizzo dell'autore; implementazione e qualifica da produrre
- **Data:** 2026-10-16
- **Rapporto con la specifica:** sostituisce la scelta TCP come trasporto primario
  di [ADR-0029](0029-interfacce-protocollo-query-contratto.md); query, contratto della
  Serie e framing CBOR restano validi. Anticipa l'integrazione locale di M16 nella roadmap.
- **Riferimenti:** [architettura](../architettura.md#interfacce),
  [caso NNTP](../valutazione/caso-duso-nntp.md#integrazione-con-il-futuro-demone),
  [roadmap](../roadmap.md), REQ-IPC-001…REQ-IPC-004, INV-N1

## Contesto

Il primo impiego previsto è il database di un server NNTP in Common Lisp.
L'autore richiede che l'interfaccia tra applicazione e database passi da un
socket Unix locale e abbia priorità di sviluppo. La precedente alternativa
aperta fra embedding e TCP non rappresenta più il percorso di riferimento.
Il livello M16 non è ancora implementato.

## Decisione

### Trasporto e confine applicativo

1. L'interfaccia client predefinita è un **socket Unix locale di tipo stream**
   (`AF_UNIX`/`AF_LOCAL`), con indirizzo nel filesystem. Il demone NNTP e il
   processo ArcDocDB comunicano attraverso questo socket sulla stessa macchina.
2. Il percorso assoluto del socket è configurabile per istanza, in una directory
   runtime dedicata. La configurazione deve dichiararlo; un percorso mancante,
   non valido o troppo lungo produce un errore esplicito prima dell'apertura.
3. TCP è un trasporto opzionale successivo, disabilitato nella configurazione
   predefinita e attivabile soltanto esplicitamente. Un errore del socket locale
   non causa ripiego automatico su TCP, nemmeno su loopback.
4. Il motore rimane una libreria con API «richiesta più continuazione».
   L'embedding resta tecnicamente possibile, ma l'integrazione NNTP di riferimento
   e le sue prove usano il socket Unix. M16 possiede connessioni e framing;
   protocollo NNTP, TLS e identità dei client NNTP appartengono all'applicazione.

### Protocollo e controllo dell'ammissione

Il socket trasporta lo stesso protocollo di ADR-0029: `u32 len` più corpo CBOR,
versione e handshake estendibile, identificativi di richiesta e risposte
multiplexate che possono completare fuori ordine. Non si introduce un secondo
codec o una semantica speciale per le richieste locali.

Lo stream può dividere o accorpare i frame: ricezione e invio conservano uno stato
esplicito per i trasferimenti parziali. Lunghezza e budget sono verificati prima
di allocare o accodare il corpo; documento, envelope e batch hanno i limiti
distinti di ADR-0029/ADR-0048. Connessioni, richieste in volo, buffer in ingresso
e uscita e durata delle attese hanno capacità e scadenze finite. I valori numerici
e la codifica wire completa si fissano nel contratto M16 prima del suo codice.

Una connessione lenta o satura ferma la propria ammissione o viene chiusa secondo
il contratto, senza trattenere epoche EBR né bloccare writer o worker di calcolo.
Le operazioni su socket passano dall'I/O iniettabile; i compiti rispettano
[ADR-0045](0045-modello-di-esecuzione.md). Risultati e buffer rimangono posseduti
fino al completamento o al rilascio della risposta.

### Accesso locale e ciclo di vita

La directory runtime è posseduta dall'account di servizio e scrivibile soltanto
da esso; accesso e attraversamento sono concessi solo agli account o al gruppo
configurati per il client. Si verificano directory, proprietario e permessi prima
di esporre il listener. I permessi del nodo socket si restringono dove supportato;
la protezione della directory resta necessaria. Questo controllo locale non
aggiunge autenticazione applicativa o cifratura allo scope di ADR-0030.

Un nome già occupato produce un errore: l'avvio non elimina automaticamente
file, link o socket preesistenti, anche dopo un crash. La rimozione di un orfano
richiede un intervento esplicito a servizio fermo. Durante l'arresto si chiudono
listener e connessioni; si rimuove il nodo solo se è ancora quello creato
dall'istanza nella directory protetta. Il nodo è una risorsa runtime, separata
dai file persistenti dell'Archivio.

### Guasti, parallelismo e atomicità

Una disconnessione non annulla un commit già deciso e non autorizza il trasporto
a ripetere una scrittura. Se la risposta si perde, l'esito può essere ignoto al
client: identificativo di richiesta e riconnessione non sono una garanzia di
deduplicazione. Il demone NNTP deve risolvere i ritentativi secondo il contratto
applicativo, inclusa la chiave Message-ID.

L'invio della risposta segue le stesse regole di pubblicazione e durability del
motore. I punti di atomicità restano SEAL, DECISION e gli altri già definiti;
il trasporto non introduce commit o log persistenti propri. L'ammissione del
traffico applicativo attende il completamento del recovery.

È ordinato soltanto il flusso di byte della singola connessione. Le richieste
sono distribuite sui percorsi esistenti delle Serie; nessun lock o contatore
globale per richiesta e nessun thread per connessione o richiesta. La priorità
qui stabilita riguarda il percorso di integrazione e l'ordine di sviluppo;
restano le priorità e l'isolamento dello scheduler già definiti.

### Priorità di realizzazione

Dopo avvio, recovery e ammissione del motore si realizza la prima integrazione
client/server locale di M16 con le operazioni fondamentali disponibili. Non
attende il completamento della fase 8 o del trasporto TCP della fase 9.
Le query, le transazioni multiserie e gli indici sono esposti quando i rispettivi
contratti di prodotto sono disponibili e verificati; il socket non li anticipa.

## Conseguenze

Il primo percorso applicativo esercita due processi e un'interfaccia locale
esplicita. TCP usa in seguito lo stesso dispatcher e codec; le prove NNTP e le
misure iniziali includono framing, copie, ammissione e risposta sul socket Unix.
Servono configurazione della directory runtime e gestione esplicita degli orfani.
Questa decisione definisce progetto e priorità; non rende disponibile un listener.

## Alternative considerate

- TCP su loopback come prima interfaccia: non soddisfa l'indirizzo locale richiesto.
- Embedding come percorso principale NNTP: non esercita il confine tra processi richiesto.
- Datagrammi o namespace astratto: il percorso scelto usa uno stream e un nodo nel
  filesystem, con directory protetta e ciclo di vita osservabile.

Il pattern di collegamento locale tramite socket Unix è impiegato da
[PostgreSQL/libpq](https://www.postgresql.org/docs/18/libpq-connect.html).
La directory scrivibile solo dall'account fidato segue la protezione descritta
nella [documentazione PostgreSQL](https://www.postgresql.org/docs/17/preventing-server-spoofing.html).
Il contrib [SBCL `sb-bsd-sockets`](https://www.sbcl.org/manual/index.html#Local-Domain-Sockets)
offre `local-socket`, senza dipendenze esterne al runtime consentito.

## Valutazione

Il [piano di verifica](../affidabilita/piano-di-verifica.md#interfaccia-locale-unix-socket)
lega i quattro requisiti a prove da realizzare: selezione del solo trasporto
locale, due processi reali, permessi e collisioni, frame parziali e malformati,
saturazione, client lenti, perdita della risposta e riavvio. La prima integrazione
deve superarle prima delle misure sul percorso completo.
Prestazioni del socket Unix e vantaggi rispetto a TCP non sono ancora misurati.
