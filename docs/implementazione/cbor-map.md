# Composizione delle mappe CBOR

`arcdocdb.cbor:scrivi-mappa-cbor-minima` compone una mappa da chiavi e
valori già codificati, verificandoli prima della prima scrittura.
Il [metodo preregistrato](cbor-map-metodo.md) definisce REQ-CBR-006,
precedenza degli errori e campagne previste.
Le [verifiche conservate](cbor-map-risultati.md) riportano corpus,
parallelismo, mutazioni, copertura grezza e limiti della qualifica.

```lisp
(scrivi-mappa-cbor-minima
 buffer start end source source-start source-end item-ends count space
 :max-bytes 16777216 :max-nodes 16777216 :max-depth 100)
;; => NEXT, un solo valore
```

COUNT conta le coppie. SOURCE è un simple u8 che contiene chiave,
valore, chiave, valore in uno span half-open. Le prime 2*COUNT celle
della tabella simple u32 ITEM-ENDS delimitano i singoli item con fini
relative a SOURCE-START, crescenti, ultima uguale allo span. Le celle
successive sono ignorate, anche se la tabella fisica è molto più lunga.
COUNT0 richiede sorgente vuota e produce `A0` senza leggere entry.

Per esempio `61 61 01 61 62 82 F4 F5`, fini `#(2 3 5 8)` e COUNT2
producono `A2 61 61 01 61 62 82 F4 F5`. La testata usa il numero delle
coppie; il payload conserva esattamente ordine e byte della sorgente.
Ogni segmento deve essere un item strutturale minimo completo:
troncamenti, trailing, testate non minime e UTF-8 invalido vengono
rifiutati anche quando si trovano in una chiave o nell'ultimo valore.

MAX-BYTES include testata e payload della mappa completa. MAX-NODES
include radice, tutte le chiavi, tutti i valori e i tag. MAX-DEPTH
conta array/map con la radice al livello1; scalari e tag non aggiungono
livelli. I massimi sono16MiB,16Mi nodi e100 livelli. Una mappa vuota
richiede un byte, un nodo e un livello; una coppia scalare tre nodi.
L'esaurimento del residuo prima del prossimo item viene segnalato al
suo offset assoluto nella sorgente, prima del reset dello scanner.

BUFFER e SPACE appartengono in esclusiva al chiamante durante la
chiamata. SOURCE e ITEM-ENDS restano stabili e possono essere condivisi
in lettura fra worker con destinazioni e scratch distinti. Gli array
interni dello scratch non possono essere destinazione, sorgente o tabella.
Lo stesso array sorgente/destinazione è ammesso con span disgiunti dal
footprint completo [START,NEXT), testata inclusa. Confini toccanti e
sorgente vuota sono ammessi. A successo viene conservato lo span sorgente,
mentre cambia soltanto il footprint destinazione nello stesso array fisico.

Tipi, range, limiti, capacità, overlap e tabella vengono verificati
prima del parsing o reset. Ogni errore pubblico conserva l'intera
destinazione fisica, sorgente e tabella. Il preflight conserva anche
lo scratch già sporco; il parsing fallito può modificarlo ed è riusabile
alla chiamata successiva. Dopo successo descrive l'ultimo valore;
con mappa vuota resta intatto. Gli invarianti interni sono fail-stop,
senza rollback. La coda fisica oltre END non offre capacità aggiuntiva.

La primitiva preserva l'ordine ricevuto e non impone unicità o tipi
delle chiavi. Il profilo documentale deterministico di ADR-0014,
l'ordinamento e i tag applicativi restano ai livelli superiori.
Scansione e copia sono limitate dai budget, senza AST, thread,
attese, I/O o pubblicazione durevole.
