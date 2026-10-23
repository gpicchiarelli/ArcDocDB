# Sessione locale M16

**Proposta — ADR-0056.** Questo è un contratto da accettare prima del codice
M16, non un servizio già disponibile. Attua la priorità di
[ADR-0055](../adr/0055-interfaccia-locale-unix-socket.md). Il
[metodo SPK-11](../../spikes/SPK-11-unix-socket/README.md) distingue prove del
trasporto da quelle ancora necessarie al prodotto.

## Frame e vocabolario

Per il primo servizio di produzione, l'autore ha autorizzato il
[profilo M1](production-unix-m1.md): stesso vocabolario di sessione e
quattro comandi con payload fissato, un proprietario e limiti inferiori.
La proposta estesa qui sotto resta distinta da quel profilo e dalla sua qualifica.

Ogni frame è `length:u32be | body:length bytes`. La lunghezza esclude il
prefisso e deve essere 1…17.825.792 byte (17 MiB). Zero e valori superiori
chiudono la connessione dopo i quattro byte, prima di riservare il corpo.
Non ci sono magic, delimitatore, padding, compressione o negoziazione TCP.
EOF con prefisso o corpo incompleto è una troncatura; EOF tra frame è chiusura.

Il corpo contiene esattamente un item CBOR deterministico RFC 8949: header
minimi, lunghezze definite, mappe ordinate lessicograficamente sui byte
delle chiavi secondo [RFC 8949 §4.2.1](https://www.rfc-editor.org/rfc/rfc8949.html#section-4.2.1)
e senza chiavi duplicate, niente
byte finali. Si riusa il codec del prodotto. Il suo scanner strutturale da
solo non certifica ordinamento/deduplica delle mappe: questi controlli sono
obblighi del decoder della sessione. Nessun dato esterno passa dal reader Lisp.

L'envelope è un array di cinque elementi `[version, kind, id, code, payload]`.
`version=1`; gli altri primi quattro campi sono interi unsigned, `id` al più
u64, `kind` e `code` al più u16. Il payload è un item CBOR, la cui forma è
stabilita dal comando. Profondità massima dell'envelope 8, esclusi eventuali
documenti trasportati come byte string e verificati separatamente con il
limite di 16 MiB/100 livelli. L'envelope e i metadati occupano al più 64 KiB;
documenti e chiavi hanno budget separati. Un batch richiede un contratto
ulteriore con limite di operazioni e byte; non è un comando implicito.

## Handshake e correlazione

| Kind | Direzione | ID/code | Payload |
|---|---|---|---|
| 0 HELLO | client → server, primo e unico | 0/0 | mappa `{0: max-frame, 1: max-inflight}` |
| 1 WELCOME | server → client | 0/0 | mappa `{0: max-frame, 1: max-inflight, 2: [opcodes]}` |
| 2 REQUEST | client → server dopo WELCOME | ID positivo/opcode | argomenti del comando |
| 3 RESPONSE | server → client | stesso ID/status | risultato o `null` per errore |

Le mappe HELLO/WELCOME hanno esattamente le chiavi indicate. Le capacità
del client sono `4096 <= max-frame <= 17825792`, `1 <= max-inflight <= 16`;
il server sceglie il minimo dei propri limiti e di quelli richiesti. I
limiti valgono in entrambe le direzioni e WELCOME li conferma. HELLO/WELCOME
stanno entro 4096 byte; prima dell'handshake il decoder applica quel limite.
Nessuna richiesta è eseguita prima di WELCOME. Versione, kind, direzione,
forma o ID invalidi chiudono senza risposta, compreso un secondo HELLO.

Gli ID REQUEST crescono strettamente nell'ordine dei frame ricevuti, anche
dopo il completamento; bastano ultimo ID e tabella delle richieste in volo.
Non rappresentano un ordine di commit. Ogni richiesta ammessa ha una sola
risposta terminale se la connessione sopravvive; le risposte possono arrivare
fuori ordine. Risposta duplicata o sconosciuta è errore di protocollo del
client. A u64 massimo si termina il lavoro in volo e si riconnette.

L'unico opcode qui definito è `0 PING`, argomento `null`, risultato `null`.
È disponibile soltanto dopo il gate del motore. Altri opcode producono
`unsupported` senza ammissione al motore e senza chiudere la sessione;
GET/PUT/DELETE, query e multiserie richiedono ciascuno un payload approvato.
WELCOME annuncia soltanto le operazioni effettivamente abilitate.
La lista degli opcode è strettamente crescente, senza duplicati, di interi u16.

| Status | Significato |
|---|---|
| 0 ok | Risultato secondo il comando |
| 1 invalid-arguments | Envelope valido, argomenti del comando non validi; non ammesso |
| 2 busy | Capacità del comando esaurita; non ammesso |
| 3 unavailable | Stato del motore non operativo; non ammesso |
| 4 unsupported | Opcode assente dalle capacità; non ammesso |
| 5 limit-exceeded | Budget del comando superato prima dell'ammissione |

Questi errori non descrivono una scrittura già ammessa. L'esito dopo
ammissione dipende dal comando e non può essere tradotto in un generico
`busy` o `aborted`. Se il server non può completare una risposta corretta
chiude; il client considera ignoto l'esito di richieste prive di risposta.

## Capacità, proprietà e scadenze

Default proposti, tutti verificati prima dell'apertura:

| Risorsa | Limite |
|---|---|
| Proprietari I/O del trasporto | 8, configurabili 1…64 |
| Connessioni per proprietario | 8, inclusi handshake; backlog 64 per listener |
| Richieste in volo per connessione | 16, inclusi risultati ancora da inviare |
| Byte trattenuti in ingresso per connessione | 17 MiB + 4 |
| Byte trattenuti in uscita per connessione | 17 MiB + 4 |
| Pool byte per proprietario | 128 MiB, condiviso solo dalle sue connessioni |
| HELLO completo | 5 s dall'accept |
| Assemblaggio di un frame successivo | 30 s dal suo primo byte |
| Risposta in coda fino all'ultimo byte inviato | 30 s dall'accodamento |
| Connessione inattiva, senza lavoro in volo | 300 s dall'ultimo frame completo |

Nessuna scadenza viene rinnovata da un trasferimento parziale. Il tempo è
monotono e iniettabile. Il pool include i buffer trattenuti da richieste,
risultati, prefissi e I/O pendente; lo spostamento di proprietà non libera
il budget. Contesti, scratch del codec e metadati hanno dimensione fissa
preallocata secondo capacità: vanno contabilizzati separatamente dal pool
byte, prima di avviare il servizio. Questi limiti non sono un budget RSS.

Le connessioni hanno proprietario immutabile; il limite complessivo è il
prodotto di proprietari e capacità locale. I pool sono disgiunti, senza
contatore globale per richiesta. Si riserva il corpo dopo il prefisso
valido, prima di riceverlo. Se manca capacità si sospende la lettura con
scadenza conservata, senza accodare altrove. Al limite di richieste in volo
si ferma la lettura; dati già accorpati restano nel buffer contabilizzato.
Il prefisso non autorizza il comando: validazione completa e prenotazione
del risultato precedono l'ammissione al motore.

Scadenza, EOF incompleto o peer lento chiudono solo quella connessione.
Il risultato copiato nel buffer d'uscita non trattiene pin EBR o lease del
writer. La chiusura libera i contesti una volta completati gli I/O che li
possiedono, senza liberare buffer ancora prestati. Il futuro codice deve
verificare saturazione e isolamento con il pool ADR-0045 reale.

## Percorso, avvio e arresto

Path assoluto esplicito, senza NUL, componente finale non vuota, massimo
100 byte UTF-8 escluso NUL: tetto conservativo comune a Linux/macOS da
verificare su entrambi, non dedotto dalla lunghezza in caratteri Lisp.
La directory runtime deve già esistere, appartenere all'UID di servizio
ed essere 0700 (stesso account) o 0750 (gruppo client configurato).
Socket 0600 o 0660 secondo il modo; directory e catena del namespace devono
essere possedute e non sostituibili da account non fidati. Si rifiutano
symlink e directory scrivibili da gruppo/altri; l'apertura posseduta e le
verifiche devono impedire gare fra controllo e uso del namespace.

Il listener compare dopo recovery, pubblicazione delle radici e gate di
ammissione del motore. La sola capsula runtime o H=M non è un'attestazione
di recovery completato. Non esiste un listener TCP alternativo automatico.
Un nodo occupato resta intatto, anche se è un socket orfano. All'arresto si
chiude l'ammissione, poi connessioni/listener; si elimina soltanto il nodo
con identità device/inode ancora uguale a quella creata dall'istanza nella
directory protetta. Nodo sostituito: diagnostica e nessuna rimozione.
La gestione degli orfani resta un'azione esplicita a servizio fermo.

## Fixture indipendenti e gate residui

PING richiesta ID 1: `00 00 00 06 85 01 02 01 00 f6`.
Risposta: `00 00 00 06 85 01 03 01 00 f6`.
L'ID 2 può ricevere risposta prima dell'ID 1. HELLO con capacità 4096/1:
`00 00 00 0c 85 01 00 00 00 a2 00 19 10 00 01 01`.
Una variante negativa usa `0d` come lunghezza del corpo e deve risultare
troncata a EOF. I test M16 dovranno includere entrambe.

Il [sorgente SBCL 2.6.9 di socket-receive](https://github.com/sbcl/sbcl/blob/sbcl-2.6.9/contrib/sb-bsd-sockets/sockets.lisp)
alloca un buffer alien temporaneo e copia i byte ricevuti. Lo spike C4 può
usarlo; il percorso caldo del prodotto richiede un adattatore I/O nativo
con buffer posseduti/preallocati e offset espliciti, verificato anche nelle
allocazioni native. Il contrib resta utilizzabile per il ciclo di vita del
socket. Nessun collegamento diretto dal worker di calcolo a recv/send.

Prima del codice di prodotto servono accettazione ADR-0056, fixture del
decoder della sessione (incluse mappe e negoziazione), API I/O iniettabile e
contratti dei comandi dati. Prima dell'integrazione applicativa restano tutti
i gate del [piano di verifica](../affidabilita/piano-di-verifica.md#interfaccia-locale-unix-socket).

La [variante C4 di SPK-11](../../spikes/SPK-11-unix-socket/session-method.md)
verifica ora il profilo di controllo da 4096 byte: handshake, limiti,
mappe, ID, risposte invertite e deadline logiche. L'indicatore di gate e i
crediti sono un modello; il pool e l'ammissione reali restano da collegare.
Non si estende quel risultato a documenti, comandi dati o listener di prodotto.
Il [rapporto e gli originali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-17-unix-session/report.md)
conservano le tre varianti, il fallimento dell'harness e la verifica completa.

La [variante I/O su buffer posseduti](../../spikes/SPK-11-unix-socket/native-io-method.md)
prepara ora un passo recv/send diretto su vettori preallocati, con backend
sostituibile, offset e deadline espliciti. Attesa FD e parsing restano fuori
dall'adattatore. Fault injection, peer indipendente e guardie controllano
progresso e confini; il contatore Lisp e il disassemblato non qualificano
malloc nativo, pool/scheduler o l'intera sessione. Resta codice sperimentale C4.
La [raccolta degli originali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-unix-native-io/report.md)
conserva i quattordici scenari, le cinque varianti e i due controlli completi
eseguiti prima della successiva integrazione generale.
