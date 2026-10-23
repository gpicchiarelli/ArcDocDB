# Composizione degli array CBOR — contratto e metodo

Incremento C1 preregistrato il 2026-10-13, prima del nuovo corpus,
del prodotto e delle campagne. REQ-CBR-005 deriva da ADR-0014;
REQ-LIM-001/002 e ADR-0048 governano i budget del risultato completo.

## Contratto locale

```lisp
(scrivi-array-cbor-minimo
 buffer start end source source-start source-end item-ends count space
 :max-bytes 16777216 :max-nodes 16777216 :max-depth 100)
;; => esattamente NEXT
```

BUFFER e SOURCE sono simple u8; START/END e SOURCE-START/SOURCE-END
sono index e delimitano span half-open validi. Destinazione e SPACE
esclusivi fino al ritorno; sorgente e tabella stabili, condivisibili in
lettura. ITEM-ENDS e simple u32: solo le prime COUNT celle vengono lette.
Contengono fini relative a SOURCE-START, strettamente crescenti, non
maggiori di SPAN, ultima uguale a SPAN. Ogni segmento contiene un item
minimo esatto. COUNT index non supera lunghezza tabella o SPAN;
COUNT0 richiede SPAN0 e non legge entry.

Si emette una testata MT4 minima per COUNT, seguita dai byte esatti
della sorgente. NEXT=START+HEADER-SIZE+SPAN; solo [START,NEXT) cambia.
Tutti gli errori pubblici precedono la prima scrittura e preservano
l'intera destinazione fisica, sorgente e tabella. Guasti d'invariante
interni sono fail-stop, senza rollback. Nessuna pubblicazione durevole,
AST, ordinamento/deduplica delle mappe o normalizzazione NaN: vale la
preferenza locale dello [scanner minimo](cbor-minimo-struttura.md).

Si rifiuta BUFFER o SOURCE eq SPACE.KINDS, o ITEM-ENDS eq SPACE.REMAINING,
anche per array vuoto: il reset dello scanner modifica tutto lo scratch.
BUFFER=SOURCE e ammesso solo se la sorgente e disgiunta dal footprint
completo, inclusa testata. Confini toccanti e sorgente vuota sono ammessi.

MAX-BYTES index 0..16MiB include testata e payload; MAX-NODES index
1..16MiB include la radice e tutti i nodi dei figli, compresi tag;
MAX-DEPTH index 0..100 conta soltanto array/map, radice a livello1.
Un array vuoto richiede un byte, un nodo e un livello. Figli scalari/tag
sono ammessi con profondita1. Picco=1+max(picchi dei figli), nodi=1+somma.
Ogni figlio usa lo scanner minimo con budget byte pari al proprio span,
nodi residui e profondita MAX-DEPTH-1. Residuo nodi1 e valido; residuo0
prima del prossimo reset genera RESOURCE-EXHAUSTED :cbor-array-node-budget,
offset assoluto all'inizio del prossimo figlio. Gli errori dello scanner
sono propagati invariati, con offset assoluto SOURCE.

## Precedenza congelata

Tutte le fasi seguenti precedono parsing/reset:

1. Range destinazione: INVALID-ARGUMENT :cbor-range, offset NIL.
2. Range sorgente: INVALID-ARGUMENT :cbor-array-source-range, NIL.
3. Tipo tabella: :cbor-array-item-ends; tipo/range COUNT o COUNT0/SPAN0:
   :cbor-array-count, entrambi INVALID-ARGUMENT, NIL.
4. Tipo SPACE: :cbor-workspace; alias scratch:
   :cbor-array-workspace-alias, INVALID-ARGUMENT, NIL.
5. Limiti configurati: motivi esistenti :cbor-byte-limit,
   :cbor-node-limit, :cbor-depth-limit, INVALID-ARGUMENT, NIL.
6. SPAN, poi dimensione completa contro MAX-BYTES:
   RESOURCE-EXHAUSTED :cbor-array-byte-budget, NIL.
7. Dimensione completa contro END-START:
   RESOURCE-EXHAUSTED :cbor-array-capacity, NIL.
8. Overlap: INVALID-ARGUMENT :cbor-array-overlap, NIL.
9. Monotonia/bounds/ultima fine: INVALID-ARGUMENT :cbor-array-item-ends, NIL.
10. Minimo nodi 1+COUNT, poi livello radice1:
    RESOURCE-EXHAUSTED :cbor-array-node-budget / :cbor-array-depth-budget, NIL.
11. Scansione completa dei figli nell'ordine; poi scrittura.

Il check SPAN contro MAX-BYTES precede la somma della dimensione e il loop
sulla tabella: COUNT<=SPAN<=16MiB limita lavoro e conversione u32.
Capacita/overlap prevalgono sulle entry malformate. Preflight lascia lo
scratch intatto; parsing fallito puo sporcarlo, il reset successivo lo
riusa. Con COUNT0 resta intatto. A successo lo scratch descrive l'ultimo
figlio, senza promettere statistiche aggregate.

## Corpus e parallelismo

Autore distinto prepara e congela il corpus senza leggere i nuovi
sorgenti; il prodotto viene scritto dopo il freeze. Oracolo freddo per
testata e payload letterali; scanner usato solo come controllo aggiuntivo.
Fixture: 80; 81 00; cinque figli 00/3818/6141/F5/F93E00 con fini
1/3/5/6/9; COUNT23/24/255/256; figli tag/map/array, UTF8 e float minimi;
item trailing 0000, nonminimo1800, troncamento e UTF8 invalido.
Profondita figlio99 accettata al limite100, figlio100 rifiutato;
byte string payload16777210 produce esattamente16MiB con radice,
payload+1 rifiutato. Residuo nodi con 810000 e fini2/3: budget3
rifiuta il secondo figlio, budget4 accetta. Tipi, range, tutte le fasi
di precedenza, alias anche vuoto, overlap testata, confini toccanti,
capacita esatta/-1, arita, sentinelle fisiche e riuso dopo errore.
Fuzz1024 seed41525235 su casi validi e rifiuti, piano e conteggi congelati.

Due worker reali riusati, due ondate di2048 chiamate per worker:
8192 composizioni. Sorgente/tabella condivise immutabili, destinazioni
e scratch privati, READY/GO/DONE per ondata, sink e buffer completi,
timeout/join/cleanup limitati. Intervalli osservati senza inferire
scaling, simultaneita sui core o prestazioni del motore.

## Campagne e conservazione

Benchmark seriale separato: sei fixture fredde congelate prima del
prodotto (vuoto, scalare, cinque tipi,24 scalari,256 scalari,
array/tag/testo). Cinque repliche x1024 chiamate, warmup64; NEXT e byte
nel sink, arita fredda. Baseline nulla e controllo positivo16x1MiB;
criterio locale heap osservato zero, senza soglia di velocita.

Otto mutazioni compilabili uniche, catalogo prima della campagna:
capacita fisica; major errato; COUNT errato; scansione omessa;
overlap senza testata; tabella non verificata; radice esclusa dai nodi;
arita extra. Copie/cache private, baseline completa, smoke/fine esatti.
Errori di compilazione, segnali o worker non valgono come rilevamento.

Due letture C1 con checklist12punti prima della prima compilazione;
coverage grezza dei nuovi sorgenti e inventario di tutte le decisioni
composte, senza esclusioni o attestazione MC/DC. Self-test dei driver,
letture distinte dei dati, make check integrato prima del push.
Strumenti Common Lisp (INV-X3), READ-EVAL NIL/EOF; sorgenti/indice/HEAD
stabili nei comandi registrati. Conservazione con impronte, copie e
verifica dell'inventario chiuso; fallimenti mantenuti. Nessuna chiusura
del gate C1 o qualifica dell'intero motore dalle prove locali.
