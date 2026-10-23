# Composizione dei tag CBOR

`arcdocdb.cbor:scrivi-tag-cbor-minimo` compone una testata MT6 e un
singolo contenuto già codificato, verificandolo prima della scrittura.
Il [metodo preregistrato](cbor-tag-metodo.md) definisce REQ-CBR-007,
precedenze e campagne; le [verifiche](cbor-tag-risultati.md) conservano
risultati e limiti della qualifica.

```lisp
(scrivi-tag-cbor-minimo
 buffer start end source source-start source-end high low space
 :max-bytes 16777216 :max-nodes 16777216 :max-depth 100)
;; => NEXT, un solo valore
```

HIGH/LOW sono parole u32 del numero wire del tag, senza ricostruire
un intero u64. La testata minima occupa 1/2/3/5/9 byte; il contenuto
resta identico. HIGH=0, LOW=55799 e SOURCE=`A0` producono `D9 D9 F7 A0`.
SOURCE è un simple u8 non vuoto con esattamente un item strutturale
minimo completo: trailing, troncamenti, UTF-8 invalido e forme non minime
vengono rifiutati con offset assoluti nella sorgente.

MAX-BYTES comprende testata e contenuto. MAX-NODES include un nodo tag
più i nodi del contenuto: minimo due. MAX-DEPTH conta soltanto array/map;
il tag non aggiunge livelli. Un tag su scalare è ammesso a profondità0,
un tag su array vuoto richiede profondità1. I massimi sono 16 MiB,
16 Mi nodi e 100 livelli. Anche lunghe catene di tag consumano nodi,
senza aggiungere frame allo scanner.

BUFFER e SPACE sono esclusivi durante la chiamata; SOURCE resta stabile
e può essere condiviso in lettura tra worker con destinazioni e scratch
distinti. L'array interno KINDS dello scratch non può essere
sorgente o destinazione. BUFFER=SOURCE è ammesso soltanto con span
sorgente disgiunto dal footprint completo [START,NEXT), testata inclusa;
confini toccanti sono ammessi.

Range, sorgente non vuota, parole, scratch/alias, limiti, byte, capacità,
overlap e minimo nodi vengono verificati prima del parsing o reset.
Tutti gli errori pubblici conservano l'intera destinazione fisica e
sorgente. Il preflight conserva anche lo scratch; un parsing fallito
può sporcarlo, riusabile alla chiamata successiva. Dopo successo le sue
statistiche descrivono il contenuto, senza il tag emesso. Solo il
footprint destinazione cambia; la coda fisica oltre END non offre capacità.
Gli invarianti interni sono fail-stop, senza rollback.

Questa primitiva è strutturale: non interpreta date, bignum, altri tag
applicativi o sentinelle IANA, e non impone ordine/unicità delle chiavi.
Il profilo documentale deterministico e l'ammissione semantica restano
ai livelli superiori. Nessun AST, thread, attesa, I/O o pubblicazione
durevole nel prodotto; qualifica C1/MC/DC ancora aperta.
