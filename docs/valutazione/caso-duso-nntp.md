# Caso d'uso di riferimento: server NNTP in Common Lisp

> **Deciso (indirizzo dell'autore, 2026-10-15; priorità confermata il 2026-10-16)** —
> Il primo impiego di ArcDocDB sarà come database di un server NNTP Usenet
> scritto in Common Lisp. È il caso applicativo prioritario per l'implementazione
> e la validazione del motore general-purpose.

## Obiettivo applicativo

Il futuro server conserva articoli, appartenenze ai newsgroup, informazioni
di overview e metadati di retention. ArcDocDB fornisce storage, transazioni,
indici, scheduling e recovery; l'applicazione NNTP possiede protocollo,
connessioni e regole di pubblicazione. Il caso d'uso aiuta a valutare i
contratti esistenti e il lavoro residuo della [roadmap](../roadmap.md).
Le scelte di API, indici, concorrenza e recovery vanno valutate prima rispetto
ai carichi NNTP descritti qui: pubblicazione, lookup per Message-ID, overview,
cross-posting, ricerca testuale e retention.

ArcDocDB mantiene la propria natura general-purpose. L'indirizzo NNTP da solo
non modifica formati, invarianti, livelli di durability o scope degli ADR
accettati; le modifiche ai contratti passano dal normale ADR. La successiva
richiesta dell'autore di ricerca full text è registrata in
[ADR-0053](../adr/0053-ricerca-full-text-indici-invertiti.md).
La richiesta successiva del 2026-10-16 fissa il socket Unix locale come interfaccia
predefinita e prioritaria in [ADR-0055](../adr/0055-interfaccia-locale-unix-socket.md).
Protocollo NNTP, demone, TLS, autenticazione e benchmark applicativo sono
lavori futuri: questo documento non li introduce nell'implementazione attuale.

## Esigenze da considerare nelle scelte del motore

| Esigenza NNTP | Implicazione da valutare per ArcDocDB |
|---|---|
| Articoli normalmente immutabili e letture per Message-ID | Append-only, lookup puntuale, conservazione dei byte e verifica in lettura |
| Un articolo presente in più newsgroup | Una copia del contenuto e più appartenenze; coerenza delle pubblicazioni fra Serie |
| Overview per intervallo di numeri in un gruppo | Scansioni ordinate, indici secondari e visibilità coerente con gli articoli |
| Ricerca per parole e frasi in oggetto, autore e corpo | Indici invertiti dedicati sui campi testuali, combinati con filtri per gruppo e data nella stessa vista |
| Molti lettori e picchi di nuove pubblicazioni | Parallelismo, code e buffer limitati, controllo dell'ammissione e isolamento fra Serie |
| Demone NNTP e database sulla stessa macchina | Socket Unix locale come interfaccia predefinita, priorità alla prima integrazione client/server, directory runtime protetta |
| Scadenza degli articoli e lettori già attivi | Tombstone, retention delle appartenenze, CLEAN/MERGE e reclaim dopo quiescenza |
| Riavvio dopo un arresto forzato | Recupero delle pubblicazioni confermate con durability esplicita, indice ricostruibile e ritentativi applicativi senza duplicazione |

Il riferimento di protocollo è [RFC 3977](https://www.rfc-editor.org/rfc/rfc3977.txt),
in particolare §§3.6, 6 e 8.3. Message-ID e numero dell'articolo nel gruppo
sono identità distinte: il primo è confrontato come sequenza opaca di byte;
il secondo appartiene al singolo gruppo. Un articolo pubblicato in più gruppi
può avere numeri diversi in ciascuno. Il CSN del database rimane una versione
e un ordine di commit, separato dalla numerazione NNTP.

## Modello applicativo da valutare

> **Proposta** — Separare contenuto e appartenenze: `Message-ID → articolo`
> e `(gruppo, numero) → Message-ID + overview`. Metadati dei gruppi e policy
> di retention hanno responsabilità proprie. Lo schema e il partizionamento
> concreti restano da decidere con i contratti del motore disponibili.

Una singola Serie per tutti gli articoli concentra le scritture su un writer;
lo stesso vale per una Serie globale delle overview o dei contatori. Nelle
valutazioni del parallelismo occorre considerare il partizionamento e il
caso dei gruppi molto attivi. Il cross-posting aggiunge coordinamento
multiserie: la visibilità atomica desiderata è una scelta applicativa da
realizzare con le transazioni del motore, non una garanzia già dimostrata
dal solo formato del decision log.

La retention può rimuovere un'appartenenza senza eliminare il contenuto ancora
usato da altri gruppi. La rimozione fisica richiede inoltre il rispetto di
snapshot e lettori attivi. Un ritentativo dopo commit riuscito e risposta
persa deve avere una semantica esplicita per deduplicazione e numerazione.

## Ricerca full text degli articoli

> **Deciso ([ADR-0053](../adr/0053-ricerca-full-text-indici-invertiti.md))** — Il motore
> prevede indici full text dedicati. L'applicazione NNTP ne guida la valutazione;
> il primo [nucleo general-purpose](../implementazione/full-text.md) implementa analisi,
> run posizionali e cornice; l'integrazione completa rimane nella fase 8.

L'applicazione estrae testo ricercabile da `Subject`, autore e corpo: decodifica MIME,
charset e selezione delle parti sono responsabilità del server NNTP. I campi indicizzati
sono stringhe esplicite nel documento; i byte originali dell'articolo restano conservati.
Message-ID rimane una chiave opaca per il lookup puntuale; la ricerca testuale usa il
profilo versionato dell'indice, senza modificare identità o numerazione del gruppo.

Una copia dell'articolo può essere indicizzata una volta e collegata alle sue appartenenze.
Una ricerca limitata a un gruppo combina i risultati testuali con appartenenze e retention
visibili nello stesso snapshot, anche se distribuite tra Serie; non deve ritrovare un
articolo attraverso un'appartenenza già scaduta. Il risultato applicativo è deduplicato
per Message-ID. Partizionamento e costo di questa combinazione restano da valutare.

`ARTICLE` continua a richiedere lookup puntuale e `OVER` intervalli ordinati: l'indice
full text si aggiunge a questi percorsi. L'esposizione della ricerca al client richiederà
una scelta applicativa esplicita; questo documento non definisce un nuovo comando NNTP
né attribuisce la ricerca full text al protocollo standard di RFC 3977.

## Integrazione con il futuro demone

> **Deciso ([ADR-0055](../adr/0055-interfaccia-locale-unix-socket.md), 2026-10-16)** —
> Il futuro demone NNTP comunica con ArcDocDB attraverso un socket Unix locale
> di tipo stream. Questo percorso ha priorità di sviluppo; TCP è opzionale e successivo.

L'[architettura](../architettura.md#interfacce) conserva il motore libreria con
interfaccia «richiesta più continuazione». Il percorso NNTP di riferimento usa
due processi sulla stessa macchina e frame CBOR con identificativi di richiesta;
percorso del socket, directory e accesso locale sono configurati per istanza.
Il listener TCP è disabilitato per default e un errore locale non lo attiva.
L'embedding resta possibile per il motore, ma la scelta di integrazione NNTP
è ora fissata sul socket Unix. Listener e client sono ancora da implementare.

La prima integrazione locale segue avvio, recovery e ammissione del motore,
senza attendere il completamento del Query Engine o di TCP. I comandi NNTP e
le query avanzate dipendono comunque dai rispettivi contratti di prodotto.

La gestione delle connessioni conserva stato e ordine richiesti da NNTP,
usa capacità limitate e rispetta il controllo dell'ammissione del motore.
I worker di ArcDocDB mantengono proprietà delle code e dei compiti di storage;
le sezioni EBR terminano prima di attendere la rete o un client lento.
La distribuzione dei compiti, le copie dei buffer e il costo del GC vanno
valutati sul percorso completo.

Una disconnessione può lasciare ignoto al demone l'esito di una scrittura già
committed. La riconnessione non ripete automaticamente le richieste e gli ID
del multiplexing non deduplicano tra connessioni. Le prove applicative devono
includere questa condizione insieme al controllo per Message-ID.

## Criteri per le valutazioni future

> **Proposta** — Usare le operazioni applicative `POST`, `ARTICLE` e `OVER`
> per valutare i percorsi del motore quando i contratti necessari saranno
> disponibili. Le prove di correttezza precedono le misure prestazionali.

Le valutazioni dovranno distinguere lookup puntuale, intervalli ordinati e ricerca
full text con filtri di gruppo/data;
pubblicazione singola e cross-posting; cache calda e accesso al dispositivo;
durability della conferma; cancellazione di appartenenze e reclaim fisico.
I casi di guasto rilevanti includono commit prima della perdita della risposta,
riavvio con transazioni in corso e retention durante letture già ammesse.
Le misure future comprendono throughput, p50/p99, memoria degli indici,
interferenza di compaction/GC e durata del recovery, con parametri e limiti
registrati secondo il [metodo delle prove](registro-delle-prove.md).
Il percorso di riferimento include client e server in processi distinti collegati
dal socket Unix: framing, copie, buffer, ammissione e invio della risposta sono
parte della misura. Eventuali misure del solo motore restano distinte.
La [campagna full text](../13-benchmark.md#ricerca-full-text) aggiunge corpus testuali,
analizzatori riproducibili, memoria dei posting/posizioni e confronto con scansione;
nessuna prestazione è già dimostrata per questo caso d'uso.

La [prova verticale esistente](../implementazione/prova-verticale.md) verifica
componenti generici di una Serie con crash e riapertura. Il suo coordinamento
è nella fixture C4; non esercita il protocollo NNTP, un indice ordinato per
`OVER` o il percorso completo delle transazioni multiserie. La fattibilità
del futuro server dipende anche dalla chiusura di questi collegamenti.
