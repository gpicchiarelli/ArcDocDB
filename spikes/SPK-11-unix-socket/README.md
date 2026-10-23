# SPK-11 — Trasporto Unix e sessione locale di controllo

Metodo preregistrato 2026-10-17, prima dei run. REQ-IPC-001…REQ-IPC-003,
REQ-VAL-001; [ADR-0055](../../docs/adr/0055-interfaccia-locale-unix-socket.md).
Il [contratto della sessione](../../docs/implementazione/sessione-locale.md)
è una proposta distinta: questo esperimento non lo implementa interamente.
La [variante preregistrata della sessione](session-method.md) aggiunge
HELLO/WELCOME e PING nel solo profilo C4 di controllo da 4096 byte.
La [variante I/O su buffer posseduti](native-io-method.md) confronta i
wrapper recv/send con il trasporto precedente e con backend deterministici.

## Domanda e criterio

Il contrib SBCL `sb-bsd-sockets` permette uno stream Unix con stato di
framing esplicito, I/O parziali e risorse runtime osservabili fra due
processi, senza librerie esterne? Riuscita: byte ricostruiti identici alle
fixture, lunghezze errate rifiutate prima dell'allocazione del corpo,
nessuna cancellazione di un nome occupato o sostituito, figli terminati
con esito atteso entro una scadenza assoluta. Nessuna misura di latenza.

## Metodo e oracoli

- Decoder C4 u32be bounded: ogni divisione di due frame accorpati, input
  un byte alla volta, 0/max+1/u32 massimo, EOF nel prefisso e nel corpo.
  Contatore esplicito delle allocazioni del solo corpo, non dei byte heap.
- Sensibilità: un byte corrotto, una lunghezza in eccesso e un body
  troncato devono far fallire l'oracolo. CBOR valido e malformato passano
  dal codec di prodotto, caricato senza introdurre un secondo codec.
- Server e client in due processi SBCL distinti. Listener già in ascolto
  prima di creare il figlio: nessun ritardo usato come sincronizzazione.
  Primo scambio con letture/invii limitati a un byte; secondo con due
  frame in un invio e risposte invertite, verificate per contenuto/ID.
- Un documento CBOR map da 16 MiB esatti e una chiave da 65.535 byte in
  uno stesso frame. Confronto byte per byte; documento e chiave verificati
  separatamente dal codec esistente, non envelope completo da oltre 16 MiB.
- Lunghezza zero e sopra 17 MiB inviate dal figlio: rifiuto del decoder,
  nessuna allocazione del corpo. Peer chiuso durante il frame: troncatura.
- Directory privata 0700, nodo ristretto 0600; preflight lstat contro
  listener, orfano, file regolare e symlink. Controllo `lstat` di identità
  prima/dopo. Arresto con nodo sostituito: il sostituto resta intatto.
  Il bind grezzo su un link pendente e una diagnostica separata del sistema
  operativo, confinata a un target nella directory privata.
- Tutti gli I/O socket sono non bloccanti con attesa FD e deadline di
  10 s per scambio; il supervisore del figlio ha deadline 15 s, quindi
  termina e raccoglie il figlio anche in caso di errore. Le scadenze sono
  limiti della prova, non quelli della proposta di prodotto.

Il codice C4 può allocare e usare direttamente socket/clock/processi.
Nessun file persistente del database viene aperto o modificato. I file
runtime di prova sono creati in una directory esclusiva sotto `/tmp`,
rimossa soltanto dopo aver chiuso e raccolto tutte le risorse possedute.

## Variante di sessione

Otto famiglie verificano fixture binarie congelate, mappe ordinate e senza
duplicati codificati anche annidati, negoziazione, correlazione u64, crediti,
clock logico e isolamento dei contesti. Quattro mutazioni controllano gli
oracoli. Il limite al prefisso passa da 4096 prima di HELLO a quello della
fase; le prove precedenti conservano il default di 17 MiB.

Cinque nuovi scambi fra due processi verificano handshake frammentato e
PING accorpati con risposte invertite, chiave HELLO duplicata, richiesta
prima di HELLO, prefisso oltre il limite handshake e ID riutilizzato.
I crediti logici dei risultati restano occupati fino all'ultimo byte;
la saturazione non consuma ID. Il massimo u64 arresta nuove letture e
impone riconnessione dopo lo svuotamento. I progressi non rinnovano le
deadline logiche. Il gate simulato produce `unavailable` senza chiamate
al motore; non costituisce una prova di recovery completato.

## Esecuzione

La variante I/O separa ogni passo sincrono dall'attesa FD: vettore semplice
preallocato, offset/count espliciti e un solo recv/send non bloccante.
Il pin resta nella syscall; EAGAIN/EINTR conservano il progresso senza retry
interno, deadline assoluta invariata. Guardie e backend iniettati verificano
range, short I/O, EOF ed errori prima di tre nuovi scenari fra processi:
server nativo, client nativo ed EOF parziale. Il peer della sessione usa
il trasporto precedente, con gli stessi golden byte HELLO/WELCOME/PING.

Una coppia locale prova ricezione a vuoto, saturazione senza reader e invio
con peer chiuso senza SIGPIPE. Le finestre del contatore Lisp escludono
costruzione, attesa, codec e report; il disassemblato viene conservato.
Il risultato non misura malloc transitori, memoria kernel o RSS. Frame e
sessione C4 continuano ad allocare; non e il pool I/O del prodotto.

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/run-spikes.lisp --check SPK-11
```

Il runner compila lo spike senza warning/style-warning, conserva gli
argv e gli output dei figli nel risultato. `--bench` restituisce
`:unsupported`: nessun benchmark è stato definito. Ambiente, versione,
commit e blob sono registrati dall'harness comune. Ogni fallimento resta
nei registri originali, comprese le varianti corrette successivamente.

## Limiti

Non sono prove di un listener o dispatcher di prodotto, API del motore,
recovery/ammissione, commit/durability, perdita di risposta, EBR,
saturazione del pool, negazione dell'accesso con un altro UID, o qualifica
Linux/macOS. Nessun thread per connessione viene proposto per il prodotto.
Le risposte invertite sono fixture di trasporto, non risultati di query.
La prova non chiude RSK-14/RSK-16 e non promuove REQ-IPC-001…REQ-IPC-004.
Il modello alloca e contabilizza soltanto i risultati REQUEST; restano il
pool reale del proprietario I/O, scratch/handshake, deadline idle, buffer
del prodotto, massimo envelope e comandi dati. Il controllo delle mappe
non attesta la semantica applicativa di tag o equivalenza delle chiavi.

## Risultati

La [raccolta I/O su buffer posseduti](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-unix-native-io/report.md)
conserva le varianti, i disassemblati e le verifiche complete originali del
17 ottobre, chiuse nella raccolta del 22 ottobre.

La [campagna locale e gli originali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-17-unix-socket/report.md)
conservano gli scambi riusciti, i rifiuti, i cinque fallimenti iniziali e i
controlli completi intermedi. Nessuna prestazione stimata o qualifica M16.

Variante del metodo dopo il primo controllo dei nomi: su macOS il bind
grezzo ha accettato il link pendente senza cambiarne l'identita. Il rifiuto
esplicito con lstat prima del bind attua l'obbligo di ADR-0055, senza
affidarlo al comportamento del kernel. I run precedenti rimangono falliti.
