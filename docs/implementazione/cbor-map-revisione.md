# Prima lettura C1 della composizione delle mappe CBOR

Lettura statica del 2026-10-14 **prima della prima compilazione**, effettuata da
un revisore distinto dall'autore del prodotto. Nessun LOAD/compile del prodotto,
corpus o driver; nessuna suite o campagna eseguita durante questa lettura.
Il corpus era congelato prima della scrittura del prodotto, secondo il piano
blind `def50d1650ada2447dffedf13895ac85a40ee84a`.

## Fonti e perimetro

| Fonte | Blob congelato |
|---|---|
| [cbor-map-input.lisp](../../src/codec/cbor-map-input.lisp) | `d7a593badeb6e6b71f28dc4e80c641b07189d0b8` |
| [cbor-map-write.lisp](../../src/codec/cbor-map-write.lisp) | `22e814ea68e606c5bc58033c2a31e945303a9d65` |
| [Metodo](cbor-map-metodo.md) | `636dd2706c2903542978606cf029e7198bf4dbb3` |
| `tests/codec/cbor-map-write-support.lisp` | `a389e51f2416437d608c4f7745b9680eca27bc60` |
| `tests/codec/cbor-map-write.lisp` | `6ad0e9b5a48ba9c32c46d720f2f7f1821368d6c8` |
| `tests/codec/cbor-map-write-threads.lisp` | `6a65b58ce236b92b33772e1861dbd8c1257bee13` |

L'incremento implementa REQ-CBR-006, derivato da ADR-0014, con REQ-LIM-001/002,
REQ-AFF-004/008 e invarianti INV-F1, INV-P6, INV-A8. È una primitiva MT5
strutturale: preserva ordine e byte dei figli minimi; non certifica ordinamento,
unicità/equivalenza delle chiavi, semantica applicativa dei tag o il profilo
documentale deterministico.

## Esito e rilievo risolto

**Nessun difetto bloccante residuo individuato nei due sorgenti.** Le dieci
funzioni hanno FTYPE completo, safety3, requisiti/docstring/ownership; massimi
38 righe e nove percorsi sintattici secondo la convenzione esplicitata
nell'[inventario completo](cbor-map-decisioni.md).

È stato rilevato prima di qualsiasi compilazione un gap C4 nell'integrazione:
lo scope aggregato `codec` di `tools/foundation-coverage.lisp` terminava con
RUN array e ometteva RUN mappe, mentre scope mappe diretto e ASDF erano corretti.
Il coordinatore ha aggiunto RUN mappe dopo array; il solo delta è stato riletto,
tool finale **`e273f103df929f6c00ab504641e9e38ab04857ce`**. Prodotto e corpus
conservano tutti i pin sopra. Il revisore non ha modificato prodotto, corpus o tool.

## Contratto, domini e invarianti

COUNT conta coppie, ITEMS=2*COUNT. input:14/16/19 valida tipo simple U32 e
COUNT INDEX contro **due confronti separati** con metà tabella e metà SPAN,
prima del raddoppio input:21. Quindi ITEMS<=SPAN INDEX senza overflow; COUNT0
richiede SPAN0. Code inattive anche dispari non vengono limitate a SPAN né lette.
input:50 clampa SPAN contro il budget già validato <=16MiB prima del cast
u32 di COUNT, della somma e del loop; i cast successivi di ITEMS sono entro16MiB.

La sequenza pubblica riproduce tutte le undici fasi del metodo: range
destinazione/sorgente, tabella/COUNT, SPACE/alias, configurazione, byte completo,
capacità logica, overlap del footprint, fini, minimo nodi/livello radice,
scansione completa e infine emissione. Range e capacità sono half-open;
il calcolo NEXT è già entro END, non nella coda fisica. Ultima fine=SPAN
e crescita stretta garantiscono una partizione di 2*COUNT item non vuoti.

BUFFER/SOURCE eq SPACE.KINDS e ITEM-ENDS eq SPACE.REMAINING sono rifiutati
prima del reset, anche per mappa vuota. BUFFER=SOURCE è ammesso soltanto con
span sorgente disgiunto dall'intero [START,NEXT), header compreso; END può
essere più ampio del footprint. A successo, quando sono EQ, è immutato lo
span sorgente, mentre lo stesso array fisico cambia nel footprint destinazione.
Il corpus `cmw-accept` distingue esplicitamente questo caso; ogni rifiuto
pubblico conserva invece interi array fisici.

La radice parte con nodi1/picco1. Si verifica il minimo1+ITEMS e MAX-DEPTH>=1
prima di sottrarre il livello della radice. Ogni chiave/valore è scansionato
separatamente con span proprio, residuo MAX-NODES-NODES e MAX-DEPTH-1.
Residuo1 è valido; residuo0 produce `:cbor-map-node-budget` all'inizio assoluto
del prossimo item prima del reset. Esaurimento dentro un valore mantiene
`:cbor-node-budget` dello scanner, senza convertirlo nel motivo del compositore.
I tag sono nodi senza livelli container; picco=1+picco massimo dei figli.

Le postcondizioni attive controllano consumo esatto e nodi/picco effettivi,
ITEMS=2*COUNT, dimensione header, span payload e progresso della copia. Sono
relazioni significative fra risultati e input, non controlli del solo tipo
già dichiarato. I controlli pubblici con parametri T validano domini realmente
esterni. Ogni funzione non banale ha almeno due guardie attive; l'inventario
mantiene anche tutte le guardie IV e i rami di errore interni. Un guasto IV
rimane fail-stop senza rollback, da gestire al confine della Serie secondo
ADR-0033; questa API non possiede una Serie o un punto di commit.

L'emissione inizia con la chiamata write:100 dopo che tutte le scansioni
e i controlli aggregati sono conclusi. Il major passato è 5,
l'argomento header è COUNT coppie e il loop usa ITEMS: nessuna confusione con MT4
o con numero di item. La copia condivisa MT2/3 è riusata sotto le sue
precondizioni di span uguali, stabili e disgiunti; RESULT è restituito come
un solo valore lessicale NEXT.

## Lista di controllo C1 — dodici punti

1. **Requisiti/ADR:** REQ-CBR-006 e requisiti di limiti/affidabilità sono su ogni
   DEFUN; ADR-0014/0033/0035/0048 e matrice sono coerenti con il perimetro locale.
2. **Invarianti/testimoni:** integrità, ownership e budget sono riferiti; il
   corpus contiene coppie letterali, sentinelle, overflow, alias, profondità,
   residui nodi, errore/riuso. La loro esecuzione resta da osservare.
3. **Errori:** IA/RE/IV locali e scanner propagati sono tipizzati; motivi,
   precedenze e offset sono nell'inventario. Nessun ERROR stringa nel prodotto.
4. **Limiti:** due LOOP con ITEMS<=SPAN<=16MiB, scanner iterativo bounded con
   scratch 102; nessuna ricorsione nuova, attesa o I/O.
5. **Heap caldo:** nessun AST, oggetto u64, buffer o struttura creato nel nuovo
   codice; calcoli index/u32 dopo i clamp. Allocazione non misurata qui:
   la campagna dovrà conservarne dati, baseline e controllo positivo.
6. **Dati verificati:** tutte le chiavi e i valori esatti/minimi sono scanditi
   prima dell'emissione; UTF8 e float seguono lo scanner esistente. Nessun
   ordinamento/deduplica o semantica tag implicitamente aggiunta.
7. **Decisioni:** cinque AND/OR, 14 operandi; nove confronti concatenati con 18
   relazioni; 40 guardie e due LOOP, tutti inventariati senza esclusioni.
   Copertura delle condizioni e MC/DC non sono attestati dalla statica.
8. **Proprietà dello stato:** destinazione/scratch esclusivi, sorgente/tabella
   stabili; campi scratch non condivisi tra worker. Alias vietati prima del reset.
9. **Integrazione:** export pubblico presente; ASDF prodotto carica input poi
   write dopo le dipendenze; corpus support/seriale/thread e RUN globale
   sono presenti. Scope coverage esatto, dispatch, fixture positive/fake/child
   e RUN aggregato corretto. REQ-CBR-006 è implementato, non verificato;
   matrice contiene la nuova voce. Build/lint/trace/link/make check non eseguiti qui.
10. **Regole:** FTYPE 10/10, docstring/requisiti, safety3, <=60 righe e <=10
    percorsi sintattici; nessun nuovo CASE/COND, macro, stato globale mutabile,
    LOAD/EVAL/COMPILE/INTERN o chiamata di sistema nel prodotto. Nessuna deviazione
    introdotta o esclusione di copertura approvata da questa lettura.
11. **Parallelismo:** nessun lock, scrittura condivisa o attesa tra Serie;
    il prodotto non crea thread. Il corpus pianifica due worker privati,
    senza inferire scaling o simultaneità dai futuri intervalli.
12. **Durabilità:** nessuna pubblicazione o eliminazione durevole, quindi
    nessun nuovo punto di atomicità storage. Prima dell'emissione gli errori
    pubblici preservano dati; gli invarianti interni sono fail-stop senza rollback.

## Prove ancora da raccogliere

Il corpus congelato pianifica 20 nominali e 9499 chiamate alla nuova API,
incluse 1024 fuzz e 8192 parallele; sono conteggi preregistrati, non risultati.
Esecuzioni, misure heap, raw coverage, testimoni delle condizioni, mutazioni,
letture DATA e controllo integrato devono essere registrati dopo le due
letture C1 richieste. Questa prima lettura non chiude alcun gate C1 del motore
e non certifica qualificazione, autenticità delle prove o copertura completa.
