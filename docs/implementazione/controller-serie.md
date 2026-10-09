# Controller della pubblicazione di una Serie

`arcdocdb.series` adotta i lotti già chiusi dal [ponte WAL–CSN](wal-csn.md)
e governa pubblicazione, risoluzione e ritiro. Il ring ha capacità fissa;
ogni slot è un evento preallocato, legato a un solo controller. La radice
è un riferimento a una vista immutabile costruita dall'indice chiamante.
Il modulo non costruisce ancora l'indice primario o uno snapshot.

## Protocollo

1. Creare un controller per registro/log segmento, con radice iniziale e
   `:next-offset` del primo lotto. La factory alloca tutti gli eventi.
2. Acquisire la lease locale per il tratto del writer. Nessuna attesa interna:
   busy conserva il lavoro al chiamante. Rilasciare prima di migrare il ruolo
   a un altro thread; la generazione non ricomincia e non fa wrap.
3. Sigillare il lotto con il ponte WAL–CSN. Costruire la nuova radice privata
   con il token ottenuto. `registra-commit-serie` conserva lotto, token,
   radice precedente/nuova e livello di durability **prima del dispatch I/O**.
4. `inizia-io-commit-serie` conserva il consumatore prima di consegnare il
   gruppo al pool I/O. Se la consegna rifiuta, si riprogramma quel compito;
   non si ripete la registrazione o l'ingresso I/O.
5. Dopo il messaggio sincronizzato di copertura, `pubblica-commit-serie`
   verifica evento, token, log, copertura e FIFO prima del CAS della radice.
   Il SEAL scritto rimane il punto di atomicità WAL; il CAS pubblica memoria.
6. Risolvere il token catturato. `:pendente` è il solo `:csn-busy`: la radice
   è già pubblicata, l'obbligo rimane nello slot e il retry risolve soltanto.
   Le parole H restituite con `:pendente` sono zero, non una misura di H.
7. Solo dopo **FINE I/O** sincronizzata, `completa-io-commit-serie` ritira il
   consumatore. `:written` non basta; il lotto deve essere durable o faulted.
8. Dopo ritiro del gruppo, `riusa-commit-serie` richiede FIFO del ritiro,
   risoluzione, consumer ritirato e le precondizioni WAL. Riapre il lotto e
   libera riferimenti dello slot, conservando la generazione anti ABA.

Il cursore dei CSN non risolti è distinto dal cursore del ritiro. In async
più lotti dello stesso gruppo possono pubblicare dopo write, mentre i loro
buffer restano protetti fino alla fine del flush e al ritiro del gruppo.
Non vi sono callback, syscall, thread, parcheggi o retry nel nuovo modulo.

## Identità, ordine e proprietà

Il messaggio conserva **oggetto evento e generazione catturata**. La verifica
usa l'identità fisica dell'evento, il controller di origine e lo slot fisico;
numeri uguali in un'altra Serie non sono una capacità valida. Una generazione
letta dall'evento dopo il riuso non è il token del messaggio originale.

L'adozione richiede offset contiguo, CSN crescente e radice precedente uguale
all'ultima radice pianificata. Full, generazione esaurita e rifiuti ordinari
precedono la mutazione del controller: il chiamante conserva il lotto già
sigillato e il suo CSN, fino all'adozione riuscita o alla gestione del guasto.
Un successo non si ritenta. Generation e contatori sono fixnum limitati;
le parole CSN restano u32, senza materializzare un u64 sul percorso caldo.

Un solo writer con lease modifica ring e metadati. Il CAS locale owner viene
toccato per tratto; il registro condiviso resta toccato per lotto. La radice
ha un CAS per pubblicazione e i reader usano una barriera di lettura. Le
radici e tutto il grafo raggiungibile devono restare immutabili. Un riferimento
GC forte protegge gli oggetti Lisp, senza attestare il reclaim di buffer
esterni, file o versioni MVCC. Il controller non verifica il contenuto della
radice, expected-version o il filtraggio degli intenti multiserie.

## Guasti e uscite incomplete

Salute e ambito sono codificati in **una sola parola**: healthy, faulted Serie
o faulted Archivio. La transizione non torna healthy; un fault locale non
riduce un precedente fault di Archivio. Un guasto I/O noto impedisce nuovi
ingressi/pubblicazioni, mantenendo il drenaggio dei compiti già accettati.

Un dispatch conservato dal caller che non è mai stato accettato dallo
scheduler, o che è stato definitivamente ritirato con handoff, può essere
drenato dopo FAULTED con `ritira-io-commit-serie`: prima si annulla il gruppo
mai scritto, poi si ritira l'obbligo dell'evento. Il buffer deve essere sealed
senza gruppo proprietario. Questo percorso non revoca un compito e non
attesta da solo l'assenza di worker: la prova del ritiro è precondizione.

Anche gli invarianti delle preflight WAL di adozione e rilascio rendono il
controller FAULTED. La fase interna `:pubblicando`, se osservata fuori
dall'effetto, è un esito incerto: il getter segnala l'invariante e richiede
fail-stop di Archivio, senza restituirla come stato pubblico ordinario.

Ogni effetto locale acquisisce una proprietà esplicita. Il cleanup ne rilascia
la risorsa; un'uscita incompleta rende il controller FAULTED di Archivio,
conservando riferimenti e causa originale. Non tenta rollback del CAS della
radice o del registro. In quella situazione il coordinatore deve fermare
**tutto l'Archivio**: il controller di una Serie non arresta gli altri.
Non si promette recupero automatico di una lease abbandonata dal task.

`annulla-commit-serie` richiede fault di Serie, tutti i compiti I/O ritirati
e ordine FIFO degli irrisolti. Sul percorso di guasto una scansione di tutti
gli slot (al più 1024) ricontrolla la quiescenza oltre al contatore. Solo allora
marca il log terminale e annulla il token catturato. Busy conserva l'obbligo.
In ambito Archivio il cleanup automatico è rifiutato; nessun buffer guasto
viene riaperto e nessun file viene eliminato.

## Verifica e confini

[Metodo](controller-serie-metodo.md), [decisioni](controller-serie-decisioni.md)
e [seconda lettura](controller-serie-revisione.md) definiscono l'ambito delle
prove locali. Pool, notifiche/scheduling, conferme client, indice concreto,
registrazione degli snapshot e coordinatore multiserie restano integrazioni
distinte. Nessun requisito dell'intero motore viene promosso con questo blocco.

[Risultati locali](controller-serie-risultati.md): check integrato, condizioni,
copertura, mutazioni, misure seriali/parallele e diagnostiche conservate.
