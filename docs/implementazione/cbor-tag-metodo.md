# Composizione dei tag CBOR — contratto e metodo

Incremento C1 preregistrato il 2026-10-14, prima del nuovo corpus,
del prodotto e delle campagne. REQ-CBR-007 deriva da ADR-0014.
Il tag MT6 contiene un singolo item; il numero wire è unsigned64,
rappresentato in due parole u32. Riferimento:
[RFC 8949 §3.4](https://www.rfc-editor.org/rfc/rfc8949.html#section-3.4).

## Contratto locale

```lisp
(scrivi-tag-cbor-minimo
 buffer start end source source-start source-end high low space
 :max-bytes 16777216 :max-nodes 16777216 :max-depth 100)
;; => esattamente NEXT
```

BUFFER e SOURCE sono simple u8 con span half-open validi. SOURCE
contiene esattamente un item strutturale minimo completo ed è non vuoto.
HIGH e LOW sono parole u32: nessun intero u64 viene ricostruito.
Si emette la testata MT6 minima (1/2/3/5/9 byte), poi i byte esatti
del contenuto. Esempio: HIGH0, LOW55799, SOURCE=A0 produce D9 D9 F7 A0.

La primitiva verifica il solo profilo strutturale minimo dello scanner,
senza interpretare tag applicativi, date, bignum, registro IANA, ordine
delle chiavi o equivalenza dei valori. Tutti i numeri wire sono ammessi,
compresi quelli riservati a sentinelle: l'ammissione semantica resta al
profilo documentale. Non si promette una codifica documentale deterministica.

BUFFER e SPACE sono esclusivi del chiamante; SOURCE resta stabile ed
è condivisibile in lettura fra worker con destinazioni e scratch privati.
BUFFER/SOURCE eq SPACE.KINDS vengono rifiutati. BUFFER=SOURCE è ammesso
solo se lo span sorgente è disgiunto dal footprint completo [START,NEXT),
testata inclusa; confini toccanti sono ammessi.

MAX-BYTES index 0..16 MiB include testata e contenuto; MAX-NODES index
1..16 MiB include il tag radice e tutti i nodi del contenuto. Il minimo
è due nodi. MAX-DEPTH index 0..100 conta solo array/map: un tag non
aggiunge un livello. Si passa MAX-DEPTH invariato allo scanner e
MAX-NODES-1 come residuo. Un tag su scalare è ammesso a profondità0,
un tag su array vuoto richiede profondità1. Il picco finale coincide
con quello del contenuto. I tag dello scanner non aggiungono frame.

Ogni errore pubblico precede la prima scrittura e conserva l'intera
destinazione fisica e SOURCE. Il preflight conserva lo scratch;
il parsing fallito può sporcarlo ed è riusabile alla chiamata successiva.
Dopo successo SPACE descrive il contenuto, senza includere il tag
emesso nelle proprie statistiche. Solo [START,NEXT) cambia; capacità
fisica oltre END inutilizzabile. Invariante interno: fail-stop senza rollback.
Nessun AST, thread, attesa, I/O, pubblicazione durevole o stato globale.

## Precedenza congelata

Prima di parsing e reset:

1. Destinazione: INVALID-ARGUMENT :cbor-range, offset NIL.
2. Sorgente: INVALID-ARGUMENT :cbor-tag-source-range, NIL;
   span vuoto: INVALID-ARGUMENT :cbor-tag-source-empty, NIL.
3. HIGH, poi LOW: INVALID-ARGUMENT :cbor-write-high / :cbor-write-low, NIL,
   riusando la verifica delle parole del writer di testate MT6.
4. SPACE: INVALID-ARGUMENT :cbor-workspace, poi alias
   INVALID-ARGUMENT :cbor-tag-workspace-alias, NIL.
5. Limiti: INVALID-ARGUMENT :cbor-byte-limit, :cbor-node-limit,
   :cbor-depth-limit, NIL.
6. SPAN, poi dimensione completa contro MAX-BYTES:
   RESOURCE-EXHAUSTED :cbor-tag-byte-budget, NIL.
7. Dimensione completa contro END-START:
   RESOURCE-EXHAUSTED :cbor-tag-capacity, NIL.
8. Overlap: INVALID-ARGUMENT :cbor-tag-overlap, NIL.
9. Minimo due nodi: RESOURCE-EXHAUSTED :cbor-tag-node-budget, NIL.
10. Scansione minima completa del contenuto: errori propagati invariati,
    con offset assoluti SOURCE. Poi testata e copia.

SPAN<=MAX-BYTES<=16 MiB viene verificato prima della somma o scansione.
Il lavoro è limitato da SPAN, nodi e stack fisso102 dello scanner.
Due letture C1 con checklist12 punti e inventario di tutte le decisioni
precedono la prima compilazione. Nessuna esclusione di copertura.

## Corpus indipendente

Un autore distinto congela fixture e test prima dei nuovi sorgenti.
Oracoli freddi per testata MT6, contenuto e interi buffer; scanner
solo come controllo aggiuntivo. Confini parole/tag0/1/23/24/255/256/
65535/65536/FFFFFFFF/100000000/FFFFFFFFFFFFFFFF e sentinelle,
header1/2/3/5/9, source nonzero, float raw minimo, UTF8 e contenitori.

Tipi/range, span vuoto, parole u32, SPACE e alias, tutti i limiti e
precedenze, capacità esatta/-1, overlap anche solo testata e confini
toccanti, arità e statistiche scratch. Troncamenti, trailing, UTF8,
header/float non minimi, tag senza contenuto; catene di tag e residuo
nodi. Profondità0 su scalare/tag, profondità100/101 di array senza
addebito del tag. Limite completo16 MiB e superamenti.
Fuzz1024 con seme54414737, piano freddo fissato dal corpus.

Due worker reali riusati per due ondate di2048 chiamate ciascuno:
8192 composizioni, SOURCE read-only condiviso, destinazioni/scratch
privati, READY/GO/DONE, sink, timeout e cleanup limitati.
Nessuna inferenza di scaling o simultaneità sui core.

## Campagne e conservazione

Sei fixture benchmark fredde: scalare/tag corto, tag24+testo, tag55799+
mappa vuota, tag65536+array, parola HIGH nonzero+bytes, catena tag+
contenitore/testo. Cinque repliche x1024 chiamate, warmup64,
NEXT/interi buffer nel sink. Baseline nulla e controllo positivo16x1MiB;
criterio locale zero heap osservato, senza soglia di velocità.

Otto mutanti compilabili unici: capacità fisica, MT5, parole scambiate,
scansione omessa, overlap senza testata, radice esclusa dai nodi,
tag addebitato alla profondità, arità extra. Catalogo prima dell'esecuzione,
copie/cache private, baseline completa, rilevamento soltanto con smoke
esatto e funzione nominale del corpus congelato nella traccia, exit1
e segnale NIL. Warning, compilazioni fallite, guasti helper, segnali
e fallimenti dopo completamento non valgono come rilevamento.

Driver e fixture congelati con self-test; copertura grezza dei soli
nuovi sorgenti e decisioni composte, senza attestazione MC/DC.
Letture indipendenti dei dati e make check integrato prima del push.
Strumenti Common Lisp (INV-X3), READ-EVAL NIL/EOF, sorgenti/indice/HEAD
stabili nei comandi registrati. Originali e tentativi preparatori
preservati; raccolta con quattro worker e inventario chiuso verificato.
REQ-LIM-001/002 e qualifica C1/MC/DC restano aperti.
