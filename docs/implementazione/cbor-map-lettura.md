# Composizione delle mappe CBOR — seconda lettura C1

Lettura statica del responsabile del corpus cieco il 2026-10-14, dopo il
freeze dei test e la successiva scrittura del prodotto, prima della prima
compilazione, load o campagna. Il [metodo preregistrato](cbor-map-metodo.md)
ha blob `636dd2706c2903542978606cf029e7198bf4dbb3`, base comunicata `2968cdc`,
ramo `codex/cbor-map-write`. L'autore è distinto dall'autore del prodotto
e non ha consultato la nuova prima lettura o il suo inventario delle decisioni.
Prodotto e corpus congelati non sono stati modificati da questa lettura.

| Prodotto esaminato | Blob Git |
|---|---|
| src/codec/cbor-map-input.lisp | d7a593badeb6e6b71f28dc4e80c641b07189d0b8 |
| src/codec/cbor-map-write.lisp | 22e814ea68e606c5bc58033c2a31e945303a9d65 |

Nessun difetto funzionale o rilievo statico aperto individuato nei blob
esaminati. Compilazione rigorosa, lint, risultati del corpus, heap,
intervalli paralleli, copertura e mutazioni restano pendenti. Questa
lettura non chiude un gate C1, non attesta MC/DC e non qualifica il motore.

## Checklist C1

| Punto | Riscontro statico e limite |
|---|---|
| 1. Requisiti e ADR | REQ-CBR-006, LIM-001/002, AFF-004/008, INV-F1/P6/A8 e ADR-0014/0033/0035/0048 sono coerenti con una primitiva locale per mappe wire strutturali minime. COUNT conta coppie; ordine e duplicati sono conservati. Nessuna semantica applicativa o normalizzazione delle chiavi. |
| 2. Invarianti | Preflight protegge tipi, span, COUNT, alias, limiti, partizione e radice; scansione completa di chiavi e valori prima della testata. Guardie significative controllano bilanci, progresso, statistiche e copia finale, non soltanto i domini FTYPE. |
| 3. Errori | Le undici fasi del metodo rispettano l'ordine. Preflight INVALID-ARGUMENT/RESOURCE-EXHAUSTED con offset NIL; residuo0 dà :cbor-map-node-budget al prossimo START assoluto prima del reset. Errori scanner propagati invariati. Tutti i rifiuti pubblici precedono la prima scrittura e preservano i tre array fisici. INVARIANT-VIOLATION richiede fail-stop del proprietario, senza rollback. |
| 4. Limiti | Due LOOP nuovi, ciascuno limitato a ITEMS=2COUNT<=SPAN<=16MiB prima della lettura della tabella. Ogni scanner riceve span del segmento, nodi residui e MAX-DEPTH−1. Reset/drain preesistenti hanno102 frame; copia limitata a SPAN e header a5byte. Nessuna ricorsione, attesa o retry nel prodotto. |
| 5. Heap | Cursori e valori multipli, senza AST, closure, costruttori o array temporanei nel nuovo successo. Su SBCL64 le somme limitate restano fixnum. Keyword call e dipendenze richiedono comunque benchmark con baseline nulla e sensore positivo; heap zero non è attestato staticamente. |
| 6. Dati verificati | MT5 minimo con HIGH0/LOW=COUNT coppie; il payload è copiato dopo aver verificato tutti i2COUNT segmenti. Solo [START,NEXT) cambia. Controllati progresso header, span payload e NEXT finale; il risultato finale è una variabile, quindi un solo valore. |
| 7. Decisioni composte | Cinque AND/OR con14 operandi, due LOOP, nove relazioni numeriche concatenate e40 guardie WHEN/UNLESS, inventariate sotto. I rami d'errore interni restano nel perimetro: nessuna esclusione o attestazione d'indipendenza dinamica. |
| 8. Proprietario | OWNER/SHARED dichiarano BUFFER e SPACE esclusivi, SOURCE e ITEM-ENDS stabili e condivisibili in lettura. Simple array escludono backing displaced. Alias scratch rifiutati anche vuoti; BUFFER=SOURCE ammesso solo se lo span sorgente non interseca il footprint completo, testata inclusa. |
| 9. Integrazione | Export cbor-package:12; ASDF carica prodotto dopo scanner/header/copia, i tre file del corpus dopo i supporti precedenti e RUN:225. Scope dedicato seleziona esattamente due sorgenti e invoca il corpus; il dispatch aggregato codec finale invoca anche RUN mappe. Catalogo/matrice contengono REQ-CBR-006 senza :cov. Nessun make check eseguito da questa lettura. |
| 10. Standard | Safety3, FTYPE completi, tipi specializzati, REQ, docstring Pre/Post/errori e almeno due controlli significativi per ogni funzione non banale. Dieci funzioni di9–38 righe,3–9 percorsi nel conteggio dichiarato: entro60/10. Warning/style-warning e lint restano da osservare; nessuna deviazione proposta. |
| 11. Parallelismo | Nessuna attesa, thread, lock o scrittura condivisa nel nuovo prodotto. Corpus con due worker riusati, buffer e scratch privati, sorgente/tabella read-only, semafori distinti per due ondate, sink, timeout, join e cleanup limitati. Durate e overlap devono essere osservati; non dimostrano scaling o simultaneità sui core. |
| 12. Durabilità | Solo memoria esclusiva del chiamante, nessun I/O o pubblicazione durevole/atomica. Il codec non transiziona la Serie: FAULTED resta responsabilità del confine proprietario per gli invarianti interni. |

## Preflight, COUNT e aritmetica

`check-input-mappa-cbor` (input:122–132) compone in ordine: range BUFFER,
range SOURCE, tipo ITEM-ENDS e COUNT, SPACE/alias, limiti configurati,
SPAN e dimensione completa contro byte, capacità, overlap, fini attive,
minimo nodi e radice. Nessun reset o byte scritto in questo percorso.
Gli offset omessi restano NIL per l'initform di `arcdocdb-error`
(conditions:8). Tipo spazio precede ogni accesso ai suoi slot.

COUNT è index e deve essere <=FLOOR(LENGTH(ITEM-ENDS)/2) e <=FLOOR(SPAN/2)
prima di `(* 2 count)` (input:16–21). Il risultato ITEMS è <=SPAN, quindi
index senza overflow anche prima del budget documentale. COUNT0/SPAN>0
è rifiutato separatamente; il vuoto non legge entry, anche con coda sporca.

`dimensioni-mappa-cbor` controlla SPAN<=MAX-BYTES<=16MiB prima di selezione
header, cast COUNT a u32 e somma (input:50–54). COUNT<=8MiB, ITEMS<=16MiB;
testata per coppie1/2/3/5byte e dimensione completa restano fixnum.
Prima del cast ITEMS a u32 e del loop vale il medesimo bound.
Capacità contro END−START precede NEXT=START+ITEM-SIZE (input:58–59,
130): NEXT<=END rende sicura la somma index. Ogni fine relativa è
crescente e <=SPAN, ultima=SPAN (input:92–98); STOP assoluto <=SOURCE-END
e ogni segmento è non vuoto. Solo le prime ITEMS celle sono lette.

La coda fisica della tabella non deve stare nel budget16MiB: è inattiva.
Le guardie controllano il prefisso attivo e SPAN, non l'intera lunghezza
fisica (input:86–89; write:46–49). I confronti non sono implicati dal solo
tipo u32. BUFFER/SOURCE eq KINDS o ITEM-ENDS eq REMAINING sono rifiutati
prima di limiti, scanner e reset (input:30–35).

L'overlap confronta SOURCE con [START,NEXT), non con tutto [START,END)
(input:69–75). Disuguaglianze strette ammettono confini toccanti; sorgente
vuota è ammessa. Al successo BUFFER=SOURCE modifica il solo footprint
destinazione e preserva lo span sorgente disgiunto. Agli errori pubblici
destinazione, sorgente e tabella fisiche complete restano immutate.
Il parsing può sporcare SPACE; un successivo scanner lo resetta.

## Scansione, nodi e scrittura

Il minimo è un nodo radice più ITEMS e livello radice1, in quest'ordine
(input:107–110). Il ciclo parte NODES=1, PEAK=1, CURSOR=START e
CHILD-DEPTH=MAX-DEPTH−1 (write:52). Ogni chiave/valore riceve il residuo
MAX-NODES−NODES; i nodi del segmento includono tag e vengono sommati,
mentre PEAK diventa MAX(PEAK,1+CHILD-PEAK). Le statistiche restituite
dallo scanner sono controllate prima di usarle (write:26–31).

Residuo1 è passato allo scanner; residuo0 viene rifiutato all'inizio
assoluto del prossimo segmento, prima del reset (write:17–25).
Chiave8100 o C000 più valore00: con budget3 il valore inizia a SS+2
quando il residuo è0, budget4 accetta. Un figlio con99 container più
radice raggiunge100; con100 viene rifiutato dal limite figlio99.
Scalari e tag non aggiungono livello di container. ITEMS0 salta tutto
il LOOP: SPACE resta intatto, nodi/picco aggregati sono1/1. Non vuoto
lascia nello scratch l'ultimo valore, non gli aggregati locali.

Nessun byte di BUFFER cambia prima della scansione integrale e dei
controlli degli aggregati (write:94–99). Poi header MT5/PAIRS (write:100),
controllo del suo progresso e del payload, copia preesistente e NEXT
finale (write:102–109). Il primo write avviene dentro l'header writer.
La copia ha soltanto guasti interni nel contratto prevalidato; le
guardie successive alla prima scrittura non promettono rollback.
Non si ordinano o deduplicano chiavi e non si decodifica un AST.

## Guardie, dimensione e percorsi

Conteggio manuale sul testo letto:1 iniziale,1 per WHEN/UNLESS o LOOP,
più1 per ciascun operando AND/OR oltre il primo. Le relazioni concatenate
non aggiungono percorsi nel conteggio, ma restano decisioni da coprire.
Non è un conteggio dei branch strumentati né una misura MC/DC.

| Funzione | File e righe inclusive | Righe | Percorsi |
|---|---|---:|---:|
| check-tabella-mappa-cbor | input:9–21 | 13 | 7 |
| check-spazio-mappa-cbor | input:26–36 | 11 | 5 |
| dimensioni-mappa-cbor | input:41–60 | 20 | 6 |
| check-overlap-mappa-cbor | input:65–76 | 12 | 7 |
| check-fini-mappa-cbor | input:81–99 | 19 | 7 |
| check-radice-mappa-cbor | input:103–111 | 9 | 3 |
| check-input-mappa-cbor | input:116–139 | 24 | 4 |
| verifica-figlio-mappa-cbor | write:10–32 | 23 | 7 |
| verifica-figli-mappa-cbor | write:38–66 | 29 | 9 |
| scrivi-mappa-cbor-minima | write:72–109 | 38 | 6 |

`input` è [cbor-map-input.lisp](../../src/codec/cbor-map-input.lisp),
`write` è [cbor-map-write.lisp](../../src/codec/cbor-map-write.lisp).
AND/OR input:16–17 (tre condizioni COUNT),19 (vuoto),32–34 (tre alias),
73–74 (EQ, non vuoto e intersezione),94 (crescita/bound fini).
LOOP input:92 e write:54. Relazioni concatenate: input:69/71/88;
write:15/28/44/50/62/64. Guardie WHEN/UNLESS:22 in input e18 in write.

Le guardie controllano relazioni fra input, risultati e limiti:
COUNT/partizione, separazione scratch, byte/capacità, range interni,
bilancio preflight, segmento non vuoto, residui/progresso/statistiche,
convergenza del ciclo, header/payload/copia. Ogni funzione ha almeno
due controlli attivi significativi, falsificabili oltre il solo dominio
dichiarato; non sono costanti TRUE. Guardie interne prive di un caso
pubblico diretto restano nel denominatore e devono
essere inventariate dalla copertura, senza dedurre irraggiungibilità.

## Corpus congelato e integrazione

| File cieco | Blob Git |
|---|---|
| tests/codec/cbor-map-write-support.lisp | a389e51f2416437d608c4f7745b9680eca27bc60 |
| tests/codec/cbor-map-write.lisp | 6ad0e9b5a48ba9c32c46d720f2f7f1821368d6c8 |
| tests/codec/cbor-map-write-threads.lisp | 6a65b58ce236b92b33772e1861dbd8c1257bee13 |

Impronte ricontrollate e immutate.19 test seriali e uno parallelo:
283 chiamate non fuzz previste,84 successi/199 rifiuti; fuzz1024
seed4D415035, finale0D123435,512 validi e8 classi da64 rifiuti.
I65 roundtrip scanner sono aggiuntivi all'oracolo freddo di byte/NEXT.
Precedenze, COUNT coppie/2COUNT fini, alias vuoti/non vuoti, coda ignorata,
key/value malformati, budget completo, residui, arità, sentinelle e riuso
sono coerenti staticamente con il contratto. Non è una campagna PASS;
non è provata una tabella fisica con più di16Mi celle.

Due worker riusati,2 ondate×2048 chiamate ciascuno=8192 composizioni.
READY/GO/DONE distinti per ondata, input comuni read-only, destinazioni
e scratch privati; ogni chiamata confronta arità e array fisici completi.
NEXT12/16, token26698/37860, sink per worker/ondata54677504/77537280.
Attesa15s, join20s e cleanup limitato con verifica della cessazione.
Totale previsto9499 chiamate,8788 successi/711 rifiuti; durate e overlap
comprendono anche i controlli del corpus. Nessuna conclusione su scaling.

Integrazione letta: package `f0174a51357730193aac5485afc993711d291e53`,
ASDF `1ec8da1a9c5b824c365454ec452b04cd5c414f54`, coverage finale
`e273f103df929f6c00ab504641e9e38ab04857ce`, catalogo requisiti
`b2642bb6608c96f8e8ccb9383f679eb921b0c457`, matrice
`6bceaf12d28c993e3d0cdf87460a2da217e67442`.
Il coordinatore ha comunicato una correzione C4 del RUN mappe nello
scope aggregato codec, prima di compilare: il tool finale è stato
ricontrollato, scope dedicato:58–59/234 e aggregato:262–272.
Il precedente tool letto `520ef727ff5bc22e9b0b3899b06728570015e990`
non è la versione finale. Prodotto e corpus restano ai blob sopra.

Dipendenze preesistenti lette: binary `2d514f6fe2e81eecb29fa53de611fa5e28696904`,
conditions `edbe5eaa88c50dc13af8e367b73f7f41fd7bd724`, copia/range
`a2c5c77dd51bff760bff4508e998d94370921eda`, limiti
`57ffc48cc688a4de8ebec5cb14c1e69c4209704a`, scanner
`e3d7d77407046338d23e26eb0b8a2e8fdc3d699d`, wrapper minimo
`f1afe79c7a4d49abd6a6e5f6975dec830ef7b1f6`, spazio
`a8330e50a77b52a6b9044ebbb48f62bb4b3222a3`, header writer
`61f0d6e2783e4790ed7e19a45bba6407d6e5b3de`.

Rimangono compilazione senza warning/style-warning, lint, campagne con
sorgenti/indice/HEAD stabili, self-test dei driver, heap, copertura senza
esclusioni, mutazioni, letture distinte dei dati e make check integrato.
Nessuna di queste attività è stata eseguita da questa lettura statica.
