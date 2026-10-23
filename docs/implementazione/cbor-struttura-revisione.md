# Seconda lettura della scansione strutturale CBOR

L'autore degli oracoli ha congelato lo snapshot originale dei tre file di test
prima di leggere i sei file nuovi del kernel. Il supporto è stato scritto da un revisore subordinato
nativo, anch'esso senza leggere il nuovo prodotto o lo spike; la consegna e il
modello sono stati riletti dall'autore principale. Sono stati usati solo il
contratto congelato, RFC 8949, documentazione del repository e oracolo freddo
dell'header già congelato. Nessun parser di prodotto è usato come expected.
Questa lettura statica locale è indipendente dall'autore del kernel e non è
un'approvazione umana. Nessuna campagna è stata eseguita dal revisore.

Dopo la lettura, il coordinatore ha autorizzato soltanto un supplemento al
test di profondità esistente: 100 array singolo figlio seguiti da stringa
indefinita, chunk vuoto e break, sia testo sia bytes. I due expected
(102 nodi, picco 100, uso di slot 101) derivano dal contratto, ma sono stati
scritti dopo aver letto il prodotto. Non si dichiara quindi che l'intero file
attuale sia stato congelato prima della lettura. Il file originale e il
referto dati originale sono stati conservati byte per byte prima di cambiarli:
`/tmp/cbor-structure-tests-original-before-read.lisp` (blob originale
`d2f1ee8e57c0d587c7c1a7274ed171c16fb4fb53`) e
`/tmp/cbor-structure-independent-review-before-supplement.lisp`. L'oracolo,
gli altri expected, il test concorrente e il kernel sono rimasti invariati.

## Identità dello snapshot

Git blob, verificati dopo il freeze dei test e prima delle campagne:

| File | Blob |
|---|---|
| `src/codec/cbor-package.lisp` | `411212b04f96be32516425aa2a7ac53aac5b921d` |
| `src/codec/cbor-space.lisp` | `a8330e50a77b52a6b9044ebbb48f62bb4b3222a3` |
| `src/codec/cbor-scan-input.lisp` | `57ffc48cc688a4de8ebec5cb14c1e69c4209704a` |
| `src/codec/cbor-scan-stack.lisp` | `c574e87af5e195ddf3f596a4ae527e69c7a3c6a6` |
| `src/codec/cbor-scan-items.lisp` | `70272936e323b3e0cb05173c9fb68cb2b614c355` |
| `src/codec/cbor-scan.lisp` | `1f89112b43a39d98cf25dc6dfb34e412428ba843` |
| `tests/codec/cbor-structure-support.lisp` | `e9cc8a08917903cab7b7f5617225884b7d89e6c4` |
| `tests/codec/cbor-structure.lisp` con supplemento | `7e9b7a518bc3a260d721e85d62ff986553bb06de` |
| `tests/codec/cbor-structure-threads.lisp` | `3624e1dde5f5a484a117f4c783d4e6b88027cc89` |

I 24 test nominali comprendono vettori manuali, 256 AST con metadata generati
durante la costruzione e mutazione trailing di ciascuno, 512 span sui 256 lead,
4096 span casuali deterministici di 1..64 byte (seed `49CBA017`), troncature ad
ogni offset di due fixture miste. Il modello indipendente è ricorsivo a freddo
con limiti di 64 byte e 64 chiamate; accumula argomenti aritmeticamente e usa
la grammatica UTF-8 manuale per la priorità degli errori. SBCL conferma solo
l'accettazione del testo, senza fornire gli offset attesi.

## Riscontri statici

Il preflight non legge byte e precede `azzera-spazio-cbor`. Verifica l'array
semplice, gli estremi index e lo span prima dell'accesso allo scratch; poi
workspace, alias, configurazioni e byte-budget nell'ordine pattuito. Nel test
alias l'array kinds viene reso nonzero prima del rifiuto per osservare una
modifica indebita. Questa fixture osserva kinds, mentre l'assenza di qualsiasi
scrittura preflight viene verificata staticamente sul kernel completo.

Il padre è addebitato una volta all'inizio del terminale non-tag. Il tag conta
un nodo e conserva pending senza aggiungere frame; un tag davanti a un
contenitore consuma arità solo quando quel contenitore inizia. Le map
indefinite alternano chiave/valore anche per figli taggati o contenitori. Il
break controlla tag, frame indefinito e parità, non conta un nodo e chiude un
solo frame. Il drain poppa soltanto i frame definiti con arità esaurita.

Lo stack fisso copre radice + 100 array/map + una stringa indefinita: top 101
è l'ultimo indice valido dei 102 slot. Le stringhe indefinite non si annidano
tra chunk; le due fixture supplementari esercitano quel limite combinato.
I tag non occupano frame. Array e map vuoti aumentano comunque il
picco. I limiti di nodi e profondità precedono incremento/push; ogni passo
consuma almeno un byte, il ciclo esterno è limitato allo span e il drain a 102
passi. Non c'è ricorsione, attesa o creazione di thread nel prodotto.

Argomenti u64 rimangono high/low u32. La guardia high zero e low entro il room
precede l'addizione del payload; map confronta coppie con floor(room/2) prima
di raddoppiarle. Non è necessario costruire un intero u64 boxed. Payload
troncato precede UTF-8; ogni chunk viene validato separatamente con offset
assoluti. La radice completa segnala trailing prima di interpretare un secondo
header. Escono esattamente tre valori dopo controllo di cursore, budget e
assenza di frame/depth/tag residui; nessun AST o contenuto decodificato esce.

Scratch e buffer sono del chiamante. Lo scratch non conserva riferimenti al
buffer; i due array hanno riferimenti read-only e contenuto esclusivo. Il
successo non presenta costruttori espliciti; ciò non attesta zero heap, che
deve essere misurato su chiamate riuscite con fixture e scratch preallocati.
Factory fredda e condizioni d'errore restano fuori dalla misura.

Il test concorrente prealloca due buffer e due scratch distinti, controlla
esattamente tre valori, sink e copie integrali. Sono previste 48 scansioni,
2.359.344 nodi e 5.505.168 byte; sink attesi 4.718.784 e 3.145.920. Questi
conteggi sono derivati dalle fixture, non risultati osservati. L'intervallo
misurato con `get-internal-real-time` comincia dopo la barriera e termina
dopo il calcolo; overlap degli intervalli di lavoro deve essere positivo.
Non misura tempo CPU, simultaneità su core distinti o numero di core usati.
Wait 15 s, join 20 s e cleanup 1 s sono limitati; cleanup
verifica che ciascun worker noto sia terminato. Non è una misura di scaling
del pool o un'implementazione di apply concorrente.

Nessun difetto funzionale aperto rilevato. Restano pendenti build rigorosa,
lint, tracciabilità, runtime, copertura, heap e mutazioni. Le difese interne
propagano `invariant-violation`; il kernel non possiede una Serie o controller
e non implementa la transizione `FAULTED`. Profilo deterministico, semantica
dei tag, chiavi duplicate/ordinate, writer admission e gate del motore restano
da implementare o verificare nei proprietari successivi.

## Dodici punti C1

| Punto | Lettura e limite |
|---|---|
| 1. Requisiti/ADR | LIM-001/002 e AFF-004/008; CON-005 solo nella fixture concorrente. ADR-0048 per byte/profondità; ADR-0014 limitata allo scope strutturale, profilo ancora successivo. |
| 2. Invarianti | Progresso, arità, parità, budget, frame/depth, ownership, immutable input e riuso hanno fixture indipendenti. Difese interne non sono dichiarate tutte esercitate. |
| 3. Errori | Gerarchia tipizzata e reason/offset/precedenze pubbliche controllate; gestione del fault owner futura. Campagne pendenti. |
| 4. Limiti | Prodotto iterativo: span passi, drain 102, depth 100; test/model/worker con tetti espliciti. |
| 5. Heap | Nessun costruttore sul successo; factory separata. Attestazione heap **pendente**. |
| 6. Uscita | Tre contatori/offset soltanto dopo item esatto e postcondizioni; buffer mai modificato. |
| 7. Decisioni | [Inventario](cbor-struttura-decisioni.md): 20 composte, nessuna esclusione del denominatore; copertura e MC/DC non attestati. |
| 8. Ownership | Buffer immutabile, scratch esclusivo per chiamata/worker, nessun buffer trattenuto o stato globale mutabile. |
| 9. Integrazione | ASDF ordina header/UTF-8 prima dello scanner e supporto test prima della suite; `make check` e matrice restano da acquisire sullo snapshot. |
| 10. Standard | FTYPE completi, slot tipizzati, safety3, docstring e guardie attive; controlli automatici pendenti, nessuna deroga approvata. |
| 11. Parallelismo | Nessuna attesa/lock/scrittura condivisa per operazione tra Serie nel kernel; fixture privata a due worker, prova runtime ancora pendente. |
| 12. Durabilità | Nessun I/O, delete o cambiamento durevole: non applicabile al kernel. |
