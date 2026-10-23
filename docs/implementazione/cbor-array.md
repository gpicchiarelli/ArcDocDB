# Composizione degli array CBOR

`arcdocdb.cbor:scrivi-array-cbor-minimo` compone un array da item CBOR
già codificati, verificando tutte le parti prima di scrivere. Il
[metodo preregistrato](cbor-array-metodo.md) definisce REQ-CBR-005 e la
precedenza degli errori.
Le [verifiche conservate](cbor-array-risultati.md) documentano corpus,
misure, mutazioni, copertura e limiti delle osservazioni.

```lisp
(scrivi-array-cbor-minimo
 buffer start end source source-start source-end item-ends count space
 :max-bytes 16777216 :max-nodes 16777216 :max-depth 100)
;; => NEXT, un solo valore
```

SOURCE contiene gli item consecutivi in uno span half-open di un array
simple u8. Le prime COUNT celle della tabella simple u32 ITEM-ENDS
contengono le fini relative a SOURCE-START: crescenti, ultima uguale
alla lunghezza dello span. Le celle successive sono ignorate. COUNT0
richiede sorgente vuota e produce `80`.

Per esempio SOURCE=`00 38 18 61 41 F5 F9 3E 00` e fini `#(1 3 5 6 9)`
descrivono cinque elementi. Il risultato è `85` seguito dagli stessi
nove byte. Ogni segmento deve contenere esattamente un item minimo;
troncamenti, trailing, testate non minime e testo UTF-8 invalido vengono
rifiutati prima della prima scrittura.

MAX-BYTES comprende testata e payload dell'array completo. MAX-NODES
comprende la radice e tutti i nodi figli, inclusi tag. MAX-DEPTH conta
array/map, con la radice al livello1; figli scalari non aggiungono
livelli. I massimi sono16MiB,16Mi nodi e100 livelli. Un array vuoto
richiede un byte, un nodo e un livello. Il residuo nodi viene applicato
allo scanner di ciascun figlio; esaurirlo prima del prossimo figlio
genera un errore di risorsa al suo offset assoluto nella sorgente.

BUFFER e SPACE appartengono in esclusiva al chiamante durante la
chiamata. SOURCE e ITEM-ENDS devono restare stabili; più worker possono
condividerli in lettura, usando destinazioni e scratch distinti.
Lo stesso array sorgente/destinazione è ammesso con span disgiunti dal
footprint completo `[START,NEXT)`, testata inclusa. Confini toccanti e
sorgente vuota sono ammessi. Gli array dello scratch non possono essere
usati come destinazione, sorgente o tabella.
Quando BUFFER e SOURCE sono lo stesso array, il successo conserva lo
span sorgente e cambia soltanto il footprint della destinazione; gli
errori pubblici conservano l'intero array fisico.

Range, tipi, limiti configurati, capacità, overlap e tabella vengono
verificati prima del reset o parsing. Ogni errore pubblico conserva
l'intera destinazione fisica, sorgente e tabella. Il parsing fallito
può lasciare lo scratch sporco, riusabile alla chiamata successiva;
il suo contenuto dopo successo descrive l'ultimo figlio. Con array
vuoto lo scratch resta intatto. Gli errori interni d'invariante sono
fail-stop, senza rollback.

Solo `[START,NEXT)` cambia; la coda fisica oltre END non offre capacità
aggiuntiva. La scansione, la verifica della tabella e la copia sono
limitate dai budget; non si creano thread o AST e non si pubblicano
dati durevoli. L'ordinamento delle mappe, i tag applicativi e il profilo
documentale rimangono responsabilità dei livelli superiori.
