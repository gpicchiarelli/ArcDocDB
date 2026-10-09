# Item CBOR con testate minime — contratto e metodo

Incremento C1 fissato prima delle campagne, sui requisiti REQ-LIM-001,
REQ-LIM-002, REQ-AFF-004 e REQ-AFF-008. Integra il lettore di testate minime
con lo scanner bounded di ADR-0048; il controllo documentale di ADR-0014
richiede ancora ordinamento/equivalenza delle chiavi e semantica dei tag.

## Contratto congelato

`arcdocdb.cbor:verifica-struttura-cbor-minima` accetta buffer simple u8
immutabile, span half-open, `spazio-cbor` esclusivo e gli stessi tre budget
del verificatore generico. Restituisce esattamente nodi, picco di profondità
degli array/map e END per un solo item completo. Lo spazio preallocato viene
riusato; non trattiene il buffer e non viene condiviso fra chiamate attive.

Preflight, reset, attraversamento, UTF-8 e conteggi sono comuni alle due API.
Il lettore minimo viene usato per ogni header: radice, figli, chiavi, valori
e tag. I payload delle stringhe di byte non sono interpretati come header.
Il controllo lavora su parole e cursori, senza AST, copie, materializzazione
dei float/u64, attese, I/O o stato globale mutabile. Il ciclo è limitato allo
span, lo stack fisso a 102 celle e il drain a 102 passi.

Ordine degli errori: preflight prima dei byte e del reset; sintassi completa
dell'header prima della minimalità; minimalità prima di contesto, nodi,
profondità e payload. Indefiniti e break, compreso un break dopo tag,
segnalano `:cbor-nonminimal` sul lead. Il drain conserva `:cbor-trailing`
prima di leggere la coda di una radice completa. Span vuoto e figlio/tag
incompleto mantengono `:cbor-truncated` a END. Preflight fallito lascia lo
scratch invariato; errore runtime consente il reset alla chiamata seguente.

Lo scanner generico conserva la propria API e le proprie precedenze.
L'API nuova usa un booleano interno fissato a T, il wrapper generico a NIL;
nessun nuovo parametro di modalità viene esposto sull'API generica.

## Verifiche fissate

Corpus cieco congelato prima della compilazione: major 0–7, soglie di
larghezza e high u64, float/NaN raw, annidamento, chiavi e tag; payload
opachi, UTF-8, troncature, tutti i lead e precedenze concorrenti. Generazione
e fuzz finiti con seme/conteggi registrati; budget byte/nodi/profondità,
16 MiB esatti e oltre, profondità 100/101, sentinelle, alias e riuso.
Due worker reali con buffer e scratch privati, timeout e sink controllati;
i tempi di sovrapposizione non dimostrano scaling o simultaneità sui core.

Due letture C1 con checklist e inventario delle decisioni, regressioni
dello scanner generico e copertura grezza dei due file dello scanner.
Il report dedicato esegue entrambe le suite; stato completo e HTML
conservati, senza esclusioni o attestazioni MC/DC.

Driver di misura: otto fixture, cinque repliche da 4096 scansioni, warmup
128, tre valori e sink verificati, input/scratch preparati fuori misura.
Baseline nulla e allocazione deliberata verificano il contatore. Heap
osservato zero è un criterio locale, senza soglie di velocità o scaling.
Mutazioni: otto difetti compilabili fissati prima della campagna, baseline
completa, marker esatti smoke/fine; compilazione INVALID e infrastruttura,
segnali OS o guasti dopo completamento WORKER-ERROR, mai rilevamenti.
Obiettivo locale: tutti rilevati, sopravvissuti analizzati.

Build senza avvisi, lint, tracciabilità e `make check` completo prima del
push. Strumenti e audit in Common Lisp (INV-X3), record letti come dati con
read-eval NIL ed EOF. Sorgenti, log, errori e risultati originali conservati;
le copie complete/FASL delle mutazioni restano anche nel backup locale.
