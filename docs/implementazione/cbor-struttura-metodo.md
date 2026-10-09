# Metodo di verifica della struttura CBOR

Metodo registrato prima delle campagne. Il blocco attraversa un item completo
con stack iterativo preallocato e verifica struttura, testo UTF-8 e budget.
Il profilo deterministico e la semantica dei tag di ADR-0014 restano successivi:
chiavi duplicate o fuori ordine, interi non minimi e tutti i bit dei float
sono accettati dalla sola scansione. Non si materializza un documento.

## Contratto congelato

`crea-spazio-cbor()` crea a freddo uno `spazio-cbor` esclusivo del chiamante.
`verifica-struttura-cbor(buffer,start,end,spazio,&key max-bytes,max-nodes,max-depth)`
restituisce esattamente tre valori: numero di header item, massima profondità
di array/map e offset `end`. Lo span è `[start,end)` in un array semplice u8
immutabile durante la chiamata. Default: 16 MiB, 16 Mi header, 100 livelli.
Il tetto dei nodi è una scelta dell'API, derivata dal massimo numero di header
in quello span; ADR-0048 richiede il budget ma non ne stabilisce il valore.

I nodi comprendono tag, contenitori e chunk definiti, anche vuoti; escludono
il break. Solo array e map incrementano la profondità, compresi quelli vuoti;
il contenitore radice ha livello 1. Il tetto zero ammette scalari, tag e stringhe.
Una catena di tag non usa frame e addebita un solo figlio al padre, quando
inizia l'item seguente. Le 102 celle coprono radice, 100 contenitori e una
stringa indefinita. Quest'ultima ammette esclusivamente chunk definiti dello
stesso major type, con UTF-8 completo separatamente in ciascun chunk di testo.

La sintassi e il contesto dei break seguono [RFC 8949, §3.2](https://www.rfc-editor.org/rfc/rfc8949#section-3.2).
La scansione verifica anche UTF-8, ma non attesta tutta la validità semantica
né il profilo deterministico di un documento. Tag sconosciuti, tag 0 con un
contenuto generico, chiavi duplicate e NaN restano distinguibili da un errore
strutturale e saranno materia del controllo del profilo.

Preflight, nell'ordine: range, tipo dello spazio, alias EQ tra buffer e array
privato dei kind, configurazioni byte/nodi/profondità, span oltre budget byte.
I primi errori sono `invalid-argument`, reason `:cbor-range`, `:cbor-workspace`,
`:cbor-alias`, `:cbor-byte-limit`, `:cbor-node-limit`, `:cbor-depth-limit`;
lo span eccessivo è `resource-exhausted :cbor-byte-budget`. Tutti senza offset.
Il preflight invalido non modifica lo spazio; uno scan valido lo resetta.
Un errore durante lo scan può sporcare lo spazio, che è riusabile alla chiamata
successiva. Il buffer non viene mai modificato o trattenuto nello spazio.

Lo scanner legge prima l'header, preservando le reason e gli offset della
primitiva già verificata. Un chunk di tipo errato precede il budget nodi.
Un break segue l'ordine tag pendente, contesto non indefinito, map con chiave
senza valore. Reason: `:cbor-tag-break`, `:cbor-break`, `:cbor-map-value`.
Per un item si controlla il budget nodi prima di incrementarlo; per un
contenitore, profondità prima di arità e payload. Budget nodi/profondità sono
`resource-exhausted`, offset del lead. Lunghezza o arità irrealizzabile è
`corruption-detected :cbor-truncated`, offset `end`; parole u64 restano divise
in high/low e il numero delle coppie viene confrontato prima di raddoppiarlo.
Il completamento della radice seguito da altri byte dà `:cbor-trailing` al
primo byte restante. Gli errori UTF-8 mantengono reason e offset assoluti.

## Oracoli e letture

Tre file di test indipendenti vengono congelati prima della lettura del nuovo
prodotto da parte del loro autore. Fixture note e modello ricorsivo a freddo
separato dalla scansione iterativa; quest'ultimo può usare interi boxed, con
tetti espliciti per input e ricorsione. Fuzz differenziale finito: 4096 span
fino a 64 byte. Expected di nodi, profondità e fine vengono ricavati senza
chiamare il nuovo prodotto. Confini di range, budget, arità, troncatura, tag,
chunk e UTF-8; contenitori ai livelli 100/101, documento di esattamente 16 MiB,
sentinelle oltre lo span, immutabilità e riuso dopo errore. Dopo la lettura
statica viene aggiunta una fixture mirata, dichiarata separatamente: 100
array seguiti da una stringa indefinita con chunk vuoto, per osservare
l’ultimo slot dello stack. Il corpus precedente conserva il freeze originale.

Due worker reali usano buffer e scratch distinti, verificano tutti e tre i
valori e l'intero input. Intervalli di lavoro sovrapposti su tempo reale sono osservati fuori dalla
barriera di avvio; il clock non prova esecuzione simultanea su core distinti. Attese, iterazioni, join e cleanup hanno tetti espliciti.
Il test prova isolamento e uso concorrente dell'API; non misura scaling.

Classe conservativa C1: due letture indipendenti del prodotto, inventario
delle decisioni composte, FTYPE completi e safety 3. Le letture vengono
attribuite ai rispettivi esecutori; non rappresentano approvazione umana.
Controlli di compilazione rigorosa, lint e tracciabilità sullo snapshot.

## Campagne e conservazione

Copertura focale `cbor-structure`: package, spazio e quattro file scan; sono
esclusi dal filtro i moduli invariati header e UTF-8, mentre lo stato grezzo
ASDF completo viene conservato. Self-test del filtro su tutti i sei file e
suffissi falsi, più un ramo deliberatamente mancante. Tutti gli HTML e gli
esiti grezzi restano presenti; nessuna guardia esclusa dal denominatore,
nessuna attestazione MC/DC o del gate complessivo del motore.

Misure seriali, separate da copertura e mutazione: sei fixture preallocate
(u64 massimo, testo ASCII 32 KiB, 100 array, item misto con tag/map/chunk,
array con 4096 scalari, 4096 tag seguiti da scalare), cinque repliche di 32
chiamate, warmup 128. Tutti i tre valori alimentano un sink osservabile,
con costanti indipendenti. Workspace e input, GC e report sono fuori dalla
misura. Sensore con baseline zero e controllo positivo 16 × 1 MiB mantenuto
vivo; criterio zero heap osservato, nessuna soglia di throughput. Errori e
factory a freddo restano fuori dal percorso misurato.

Mutanti scelti solo dopo il congelamento del kernel, compilabili in copie
esclusive con cache separata. Baseline completa obbligatoria. Smoke e marker
di completamento devono essere righe esatte; compilazione fallita e exit zero
senza completamento sono INVALID. Un fallimento runtime dopo avvio reale è
DETECTED, un run completo a zero è SURVIVED. Tutti i log, compresi tentativi
invalidi, restano conservati con identità dei sorgenti prima e dopo.

Comandi e campagne registrano snapshot intero, stdout, stderr, exit e stato
stabile. Il catalogo viene chiuso con risultati effettivi e riferimenti alle
letture. La compressione eventualmente necessaria è senza perdita e mantiene
byte originali, checksum, descrittore e prova di rilettura.
