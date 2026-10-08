# SPK-07 — Metodo della pubblicazione (registrato prima delle prove)

Ambito: solo `pubblicazione.lisp`, package `arcdocdb.spk07.pubblicazione`,
Common Lisp/SBCL con safety 3. Il core esistente viene caricato prima del modulo.
Riferimenti letti: ADR0043, ADR0050, INV-I1, INV-I3, INV-A8, INV-P1,
REQ-IDX-003/007. Nessun componente di produzione, benchmark o decisione nuova.

Il modello SC enumera interleaving di un writer, un lookup e un ritiro.
Due chiavi, un frammento sorgente, una scrittura e una manutenzione seriale
(rebuild oppure split) bastano a distinguere hit aggiornato, miss diventato hit
e hit diventato miss. Lo split instrada le due chiavi in frammenti diversi;
il rebuild mantiene l'alias delle due voci. Root e generazione sono una coppia
immutabile pubblicata in un passo indivisibile, dopo la costruzione privata.
Il vecchio frammento può cambiare sotto seqlock prima del ritiro, poi è congelato.
Versione, location, flag live e controllo sono passi distinti del writer.
Il reader protegge prima del sondaggio, legge i campi separatamente, valida
il seqlock, passa una barriera SC astratta e ricontrolla root/generazione anche
su miss. Due tentativi condividono il budget; il fallback è un lookup atomico
eseguito dal writer dopo i suoi lavori finiti. La schedulazione del fallback
e la sua implementazione non sono oggetto di questa prova.

Due astrazioni di durata: riferimento forte alla root (che mantiene i frammenti)
e annuncio epoch prima del caricamento della root. Il reclaim esige il ritiro
e l'assenza di protezioni pertinenti. ADR0043 assegna i frammenti heap al GC e
l'EBR alle risorse esterne: la variante epoch verifica solo l'astrazione di
durata, non cambia questa decisione e non simula un contatore comune di prodotto.

Gli oracoli sono separati dalle transizioni: (1) ogni risultato hit è una
tupla completa ammessa dalla specifica; (2) nessun accesso usa un frammento
reclaimed; (3) il contratto di generazione confronta la coppia catturata con
quella presente al punto di accettazione, non alla risposta successiva;
(4) un enumeratore indipendente cerca una serializzazione della storia finita
di invocazioni/risposte rispettando precedenze in tempo reale. La manutenzione
è un'identità sulla mappa astratta. Operazioni pendenti possono essere omesse
o completate; l'oracolo non usa root, campi o il punto di linearizzazione del
protocollo. Una lettura della vecchia root non è respinta per questo solo fatto.
Un oracolo strutturale controlla anche entrambe le chiavi della root nuova,
l'instradamento rebuild/split e la completezza dei frammenti pubblicati.

Controlli negativi: omettere il ricontrollo di tutte le risposte oppure solo
dei miss; rilasciare la protezione prima del sondaggio; omettere la validazione
dei campi/seqlock nel caso hit. Ogni mutante deve produrre un witness mirato.
Per i mutanti di generazione si esplora anche il solo oracolo dati/storia:
se non viola linearizzabilità nel dominio finito, lo si dichiara esplicitamente.
Query di raggiungibilità positive devono testimoniare retry hit/miss, fallback
e lettura coerente aggiornata della vecchia root dopo la sostituzione.
Sei storie controllano direttamente l'oracolo indipendente: hit/miss vecchi
con operazioni sovrapposte ammessi; hit da scrittura pendente ammesso;
hit/miss vecchi dopo la risposta della scrittura e tupla strappata respinti.

Budget: massimo 200000 stati per esplorazione e complessivi del CHECK,
64 passi per esecuzione, due tentativi del reader, tre operazioni nella storia,
128 nodi per ricerca di serializzazione. Un budget esaurito solleva errore;
nessun taglio è interpretato come successo. Conteggi di stati/transizioni,
accettazioni, risultati e terminali sono effettivi; non contano tutte le tracce.
La fine di ogni esecuzione completa richiede writer e reader conclusi e reclaim.

Ogni tentativo di compilazione/check avvia un figlio SBCL con inizializzazioni
disabilitate e avvisi, inclusi style-warning, fatali. Un recorder Common Lisp
su stdin conserva un nuovo record plist `:schema-version 1` in `out/`:
argv/stdin esatti, ambiente, sorgenti come blob integrali e digest MD5 prima/dopo,
risultato decodificato, limiti, stdout/stderr grezzi, exit code e fallimenti.
Il record iniziale è scritto prima del figlio; i sorgenti devono essere stabili.
Git non viene consultato: commit e blob Git sono dichiarati non acquisiti.
FASL e record ricevono nomi nuovi. Non si misura throughput o latenza del motore.

Limiti dichiarati: memoria debole, disassemblato/barriere reali, snapshot expiry,
crash/persistenza, costi della directory/chiavi, wrap, allocator e scheduling
del runtime esclusi. Generazioni/seqlock non fanno wrap, nessun ABA né
riutilizzo di identità. Il probing Swiss completo, collisioni e capacità reali
sono astratti in due posizioni di directory e un controllo per chiave.
SC rende la barriera un passo di ordine esplicito, senza validarne il codice.

Tensione normativa da segnalare: la lettura letterale di INV-I1 («gli indici
sono immutabili per i reader») è più forte degli aggiornamenti di slot sotto
seqlock consentiti da ADR0043. Qui sono immutabili root/directory e frammenti
ritirati, mentre lo slot pubblicato può essere aggiornato prima del ritiro.
ADR0050 corregge inoltre il vecchio istante di linearizzazione proposto in
ADR0043. Nessun testo normativo o gate viene modificato.

## Registro dei tentativi intermedi

- `out/pubblicazione-4000478729-91239-record.lisp`: avvio fallito prima della
  compilazione per posizione errata dell'opzione runtime SBCL. Exit 1 e
  stderr originali conservati; argv corretto nei tentativi seguenti.
- `out/pubblicazione-4000478744-91419-record.lisp`: compilazione e check riusciti,
  64316 stati, 110401 transizioni, massimo 39 passi. Il campo riepilogativo
  `:explorations 1` è errato per una inversione distruttiva della lista:
  i 25 report integrali sono presenti. Corretto il conteggio prima della prova
  finale; questo record intermedio non è il riepilogo finale.
- `out/pubblicazione-4000478955-1496-record.lisp`: compilazione senza avvisi,
  poi CHECK con `:state-limit 1` interrotto come richiesto. Exit 1;
  `:expected-failure-matched t`, stdout/stderr integrali conservati.
- `out/pubblicazione-4000478956-1639-record.lisp`: compilazione senza avvisi,
  poi CHECK con `:step-limit 1` interrotto da `model-budget-exhausted`.
  Exit 1; `:expected-failure-matched t`. I fallimenti non diventano successi
  del modello e non contribuiscono al conteggio della campagna positiva.

## Prova finale predisposta

Il record `out/pubblicazione-finale-20261008-1791490231173-record.lisp` conserva il consuntivo
effettivo della compilazione e del CHECK finale. È scritto prima dell'avvio
e completato dopo l'esito; solo `:status :ok` con `:source-stability :stable`
attesta il successo. `:result` contiene i 12 modelli corretti, 6 controlli
negativi, 3 esplorazioni complete dati/storia dei mutanti di generazione,
4 witness di raggiungibilità e 6 storie indipendenti per l'oracolo.
I witness di raggiungibilità usano il campo generico `:violation` del BFS
come obiettivo atteso; il campo `:role` li distingue dai difetti del protocollo.
I conteggi osservati di hit/miss/fallback contano stati distinti (incluso il
punto di accettazione prima della risposta), non richieste o tutte le tracce.
La somma degli stati include anche gli stati scoperti ma non visitati quando
un witness interrompe anticipatamente un'esplorazione.

Il comando e lo stdin esatti per riprodurre la prova si leggono come dati dal
record (`:argv`, `:stdin`, `*read-eval* nil`); non si carica il record come codice.
FASL del core e del modulo hanno lo stesso prefisso del record e restano in
`out/`. Le prove non modificano core, runner, documenti normativi o Git.
Il gate generale resta aperto per i limiti di questo metodo e gli altri compiti.
