# I/O Unix su buffer posseduti — metodo preregistrato

Variante C4 di SPK-11, 17 ottobre 2026, prima dei run. Prepara il percorso
prioritario NNTP di ADR-0055 senza introdurre codice M16 di prodotto o
accettare ADR-0056. REQ-IPC-002, REQ-VAL-001.

## Domanda e criterio

Una singola chiamata `recv`/`send` può trasferire uno span di un vettore
di byte preallocato, senza slice o buffer alien temporaneo nell'adattatore,
con offset esplicito, risultato/errno immediati e backend sostituibile?
Riuscita: byte identici alle fixture, guardie esterne intatte, avanzamento
solo per byte confermati, al massimo una syscall per passo e nessuna
chiamata dopo completamento, EOF, errore o scadenza.

## Proprietà e oracoli

- Il proprietario conserva FD e vettore semplice specializzato per tutta
  l'operazione sincrona. Il pin e il puntatore vivono soltanto nella syscall;
  nessun prestito asincrono, close concorrente o riciclo viene modellato.
- Span non vuoto entro vettore, FD, direzione, chunk e clock verificati
  prima del backend. Callback fidati: ricevono FD/vettore/offset/count e
  restituiscono numero di byte e errno, con le stesse regole del nativo.
- Script deterministici provano short I/O, EAGAIN/EWOULDBLOCK, EINTR senza
  retry interno, EOF parziale, zero in invio, errno fatale e risultati
  impossibili. Errori di range/direzione e deadline devono lasciare a zero
  il numero di chiamate. Nessun progresso rinnova la deadline assoluta.
- Il passo non attende FD e non esegue cicli di retry. L'harness C4 attende
  fuori dall'adattatore con la deadline preesistente, senza worker di calcolo.
- Due processi SBCL reali scambiano byte con offset non zero e guardie,
  chunk di un byte e piu grandi; handshake/PING restano fixture C4. Il
  vecchio trasporto funge da peer indipendente del nuovo adattatore.
  Una chiusura a meta trasferimento deve produrre EOF con progresso esatto.
- Una coppia locale prova recv a vuoto, saturazione dell'invio senza reader
  e peer chiuso. Invio con soppressione SIGPIPE per chiamata, nessuna
  modifica globale dei segnali. Limiti finiti di byte/chiamate e deadline.

## Allocazioni e sensibilità

Preallocare buffer/contesti e riscaldare le funzioni prima della finestra
osservata. Registrare `sb-ext:get-bytes-consed` prima/dopo passi nativi
riusciti e recv EAGAIN; un'allocazione nota deve essere rilevata dal contatore.
Non sottrarre una baseline. Conservare disassemblato dei due wrapper FFI e
del passo. Il risultato non misura malloc transitori di libc/runtime,
memoria kernel, RSS, apertura socket, attesa FD o codec/sessione. Il sorgente
deve rendere visibile l'assenza di `make-alien`, slice e copie temporanee
nel solo adattatore; questa osservazione non qualifica l'allocatore nativo.

Mutazioni note verificano gli oracoli di contenuto/guardie, progresso,
numero di chiamate e scadenza. Conservare compilazioni e tentativi falliti
con i rispettivi sorgenti, senza sovrascrivere la campagna sessione chiusa.

## Riferimenti e confini

Il contratto di ritorno, short I/O, EOF ed errno segue i manuali Apple di
[recv](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/recv.2.html)
e [send](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/send.2.html).
ABI e flag sono espliciti per macOS ARM64/Linux x86-64; la prova eseguita
qualifica soltanto l'ambiente registrato. L'FFI usa i
[puntatori SBCL](https://www.sbcl.org/manual/index.html#Foreign-Function-Interface).

Non sono provati pool/scheduler reali, engine gate, crediti globali,
documento/envelope massimo, commit, EBR, perdita risposta dopo commit,
utenti distinti o Linux. Nessun benchmark. Requisiti IPC ancora progettati;
restano accettazione ADR-0056 e integrazione del motore prima del servizio.
