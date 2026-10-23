# Composizione delle mappe CBOR — contratto e metodo

Incremento C1 preregistrato il 2026-10-14, prima del nuovo corpus,
del prodotto e delle campagne. REQ-CBR-006 deriva da ADR-0014;
REQ-LIM-001/002 e ADR-0048 governano il risultato completo.

## Contratto locale

```lisp
(scrivi-mappa-cbor-minima
 buffer start end source source-start source-end item-ends count space
 :max-bytes 16777216 :max-nodes 16777216 :max-depth 100)
;; => esattamente NEXT
```

COUNT è il numero di coppie, non il numero di item. SOURCE contiene
chiave, valore, chiave, valore consecutivi, già codificati. BUFFER e
SOURCE sono simple u8 con span half-open validi. ITEM-ENDS è simple u32:
solo le prime 2*COUNT celle sono attive, con fini relative a SOURCE-START
strettamente crescenti, ultima uguale a SPAN. Le celle successive sono
ignorate. COUNT è index e non supera FLOOR(LENGTH(ITEM-ENDS)/2) o
FLOOR(SPAN/2): questi confronti precedono la moltiplicazione. COUNT0
richiede SPAN0 e non legge entry.

Si emette la testata MT5 minima per COUNT, poi il payload esatto.
Per due coppie SOURCE=`61 61 01 61 62 82 F4 F5`, fini `#(2 3 5 8)`,
il risultato è `A2 61 61 01 61 62 82 F4 F5`.
Ogni segmento deve contenere esattamente un item strutturale minimo;
valgono le preferenze locali dello [scanner](cbor-minimo-struttura.md).
L'ordine delle coppie viene conservato. Ordinamento delle chiavi,
unicità, tipi applicativi e profilo documentale deterministico restano
al livello superiore: questa primitiva non li attesta né li normalizza.

Destinazione e SPACE esclusivi, sorgente e tabella stabili fino al
ritorno e condivisibili in lettura tra worker con scratch separati.
Si rifiutano BUFFER/SOURCE eq SPACE.KINDS o ITEM-ENDS eq SPACE.REMAINING,
anche per mappa vuota. BUFFER=SOURCE è ammesso solo con span sorgente
disgiunto dal footprint completo [START,NEXT), testata inclusa;
confini toccanti e sorgente vuota sono ammessi.

MAX-BYTES index 0..16MiB include testata e payload. MAX-NODES index
1..16MiB include radice, chiavi, valori e tag. MAX-DEPTH index 0..100
conta array/map, radice al livello1, senza aggiungere un livello per
scalari o tag. Una mappa vuota richiede un byte, un nodo e un livello.
Nodi=1+somma dei figli, picco=1+max(picchi dei figli). Ogni figlio usa
lo scanner con byte pari al proprio span, nodi residui e MAX-DEPTH-1.
Residuo0 prima del prossimo figlio dà RESOURCE-EXHAUSTED
:cbor-map-node-budget al suo offset assoluto, prima del reset.

Tutti gli errori pubblici precedono la prima scrittura e conservano
l'intera destinazione fisica, sorgente e tabella. Preflight lascia
intatto lo scratch; il parsing fallito può sporcarlo, riusabile dopo
reset alla chiamata successiva. Con COUNT0 rimane intatto. Dopo successo
descrive l'ultimo valore, senza promettere statistiche aggregate.
Guasti interni d'invariante sono fail-stop, senza rollback. Solo
[START,NEXT) cambia; nessuna capacità della coda fisica oltre END.

## Precedenza congelata

Prima di parsing e reset:

1. Range destinazione: INVALID-ARGUMENT :cbor-range, offset NIL.
2. Range sorgente: INVALID-ARGUMENT :cbor-map-source-range, NIL.
3. Tipo tabella: :cbor-map-item-ends; COUNT fuori tipo/range o
   COUNT0/SPAN>0: :cbor-map-count, INVALID-ARGUMENT, NIL.
4. SPACE: :cbor-workspace; alias: :cbor-map-workspace-alias,
   INVALID-ARGUMENT, NIL.
5. Limiti configurati: :cbor-byte-limit, :cbor-node-limit,
   :cbor-depth-limit, INVALID-ARGUMENT, NIL.
6. SPAN, poi dimensione completa contro MAX-BYTES:
   RESOURCE-EXHAUSTED :cbor-map-byte-budget, NIL.
7. Dimensione completa contro END-START:
   RESOURCE-EXHAUSTED :cbor-map-capacity, NIL.
8. Overlap: INVALID-ARGUMENT :cbor-map-overlap, NIL.
9. Fini delle 2*COUNT entry: INVALID-ARGUMENT :cbor-map-item-ends, NIL.
10. Minimo nodi 1+2*COUNT, poi livello radice1:
    RESOURCE-EXHAUSTED :cbor-map-node-budget / :cbor-map-depth-budget, NIL.
11. Scansione completa di tutti gli item, nell'ordine. Errori scanner
    propagati invariati, con offset assoluti SOURCE. Poi scrittura.

SPAN<=MAX-BYTES<=16MiB viene verificato prima della somma e del loop
sulla tabella, limitando anche COUNT, conversioni u32 e lavoro.
Il costo è O(SPAN+2*COUNT*102), senza AST, allocazioni intenzionali,
attese, thread, I/O o pubblicazione durevole nel prodotto.

## Corpus e parallelismo

Un autore distinto congela il corpus senza leggere i nuovi sorgenti;
il prodotto viene scritto dopo il freeze. Oracoli freddi per testata
MT5 e payload, scanner soltanto come controllo aggiuntivo. Confini
COUNT23/24/255/256, coppie scalari e strutturate, chiavi e valori malformati,
UTF8/float non minimi, item trailing e troncamenti; coppie non ordinate
e chiavi ripetute confermano il solo scope strutturale.
Tipi/range, COUNT contro metà tabella/span, coda tabella ignorata,
precedenze, alias anche vuoti, overlap testata, sentinelle fisiche,
capacità esatta/-1, arità e riuso dopo errore. Profondità99/100 del
figlio con radice; limite completo16MiB con chiave scalare e byte string
di payload16777209, poi +1. Budget residuo esaurito fra chiave e valore.
Fuzz1024 con seed4D415035: validi e rifiuti, piano congelato dal corpus.

Due worker reali riusati per due ondate di2048 chiamate ciascuno:
8192 composizioni. Sorgente e tabella read-only condivise, destinazioni
e scratch privati, READY/GO/DONE, sink, timeout e cleanup limitati.
Intervalli osservati senza inferire scaling o simultaneità sui core.

## Campagne e conservazione

Sei fixture benchmark fredde: vuoto, una coppia scalare, due coppie
miste,24 coppie,256 coppie e coppia con array/tag/testo. Cinque repliche
x1024 chiamate, warmup64; NEXT e byte nel sink. Baseline nulla e
controllo positivo16x1MiB, criterio locale heap osservato zero, nessuna
soglia di velocità. Driver, fixture e lettura dei dati congelati.

Otto mutazioni compilabili uniche: capacità fisica, MT4, testata con
numero item anziché coppie, scansione omessa, overlap senza testata,
fini non verificati, radice esclusa dai nodi, arità extra. Catalogo
prima dell'esecuzione, copie/cache private, baseline completa e
classificazione rigorosa. Compilazioni fallite, segnali e guasti dopo
completamento non valgono come rilevamento.

Due letture C1 con checklist12punti prima della prima compilazione;
copertura grezza dei nuovi sorgenti e inventario delle decisioni
composte, senza esclusioni o attestazione MC/DC. Self-test dei driver,
letture distinte dei dati e make check integrato prima del push.
Strumenti Common Lisp (INV-X3), READ-EVAL NIL/EOF; sorgenti, indice e
HEAD stabili nei comandi registrati. Impronte, copie e inventario
chiuso conservano prove e fallimenti senza chiudere il gate C1.
