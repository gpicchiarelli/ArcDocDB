# Metodo del pianificatore di inventario

Registrato prima delle prove del 2026-10-09. Ambito C1 limitato alla
tabella di riconciliazione di [ADR-0040§3](../adr/0040-manifest-a-record-unico.md#3-riconciliazione-al-riavvio),
senza accesso al filesystem. Le fixture EDIT sono bytewise, con CRC
indipendente; l'oracolo dell'inventario usa liste logiche e non i helper
del prodotto. Non si rivendicano crash reali, verifica dei contenuti,
durabilità o completamento del recovery del motore.

## Casi e oracolo

Si confrontano tutte le combinazioni di presenza assente, temporary,
final e entrambe per ACTIVE, CLOSED, REMOVED e sconosciuto. Il modello
include i CLOSED mancanti, non include REMOVED assenti e assegna priorità
FAULTED a un ACTIVE mancante o in conflitto. Le permutazioni del vettore
devono dare le stesse entry ordinate per ID unsigned u64. Si verificano
ID zero, parole alte, massimo u64, stessi ID nelle due forme, duplicati
esatti, budget fisici esatti e superati, budget dei segmenti vivi e
argomenti/query fuori contratto. Nessun risultato parziale su errore.

I piani devono restare immutati dopo il riuso del vettore e del buffer
EDIT. Una prova usa quattro thread SBCL con input privati e un piano
comune letto dopo il riuso dell'input: errore del worker e join con
limite finito fanno fallire la prova. Il parallelismo è una verifica di
correttezza; non misura throughput o latenza.

## Strumenti ed evidenze

Lo scope `inventory` dello strumento di mutazione seleziona soltanto i
test dedicati, dopo una baseline integra. Le copie, le cache e i log
sono privati; quattro processi possono operare in parallelo. Nessun
errore di compilazione, segnale OS o exit nonzero dopo il completamento
dei test conta come rilevamento runtime. La campagna usa mutazioni note
che conservano i limiti dei cicli, senza timeout automatico dei processi.
Il self-test controlla classificazione, copia ASDF, errori e parallelismo.

`tools/foundation-coverage.lisp` registra il denominatore recovery
grezzo, stato originale `sb-cover` e HTML. Il riepilogo separa i tre
file inventory senza sottrarre le guardie difensive. Due letture C1
controllano invarianti, errori, cicli, ownership e tabella delle decisioni;
forme non osservate non diventano eccezioni approvate, né MC/DC dimostrata.

Ogni esecuzione è registrata con `tools/record-command.lisp`: argv,
ambiente, revisione, hash prima/dopo, exit e output originali. Si
congelano sorgenti, test, strumenti e documentazione durante le prove.
Si conservano anche fallimenti e tentativi preliminari distinti.
