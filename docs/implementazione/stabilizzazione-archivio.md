# Completamento dei nomi dell'intero Archivio

`recovery.bootstrap:stabilizza-nomi-archivio-recuperato` collega il
[gate Archivio](recovery-archivio.md) al [completamento Serie](stabilizzazione-serie.md).
Il [metodo preregistrato](stabilizzazione-archivio-metodo.md) precede il codice;
SGA-D01…D08 restano decisioni da qualificare.

## Contratto

```lisp
(arcdocdb.recovery.bootstrap:stabilizza-nomi-archivio-recuperato
 set decisions directories source-sets active closed
 :max-segmenti-serie 65536 :max-segmenti-totali 1048576)
;; Tre valori: piano CSN riconfermato, numero rinominati, numero gia' definitivi.
```

`set` e' l'insieme completo del catalogo, Registri inclusa, e `decisions`
il replay canonico dello stesso oggetto Archivio. I quattro simple-vector
sono paralleli alle viste del set: directory, set readonly posseduto,
ACTIVE recuperato, vettore CLOSED completo e ordinato per ID u64.
`active` e `closed` possono provenire da `leggi-archivio-recuperato`.
Il catalogo completo rimane attestato dal caller; l'API non scopre Serie omesse.

Il caller mantiene CONTROL, replay, set, FD, vettori e namespace esclusivi
e stabili per l'intera operazione nel pool I/O. Le directory corrispondono
alle rispettive Serie, senza mutatori o close concorrenti; i controlli dei
nomi le collegano agli stessi FD dei token gia' verificati. Non viene
trasferita ownership, riaperta alcuna fonte o creato un writer.

## Tutti i controlli prima degli effetti

| Passaggio | Controllo |
|---|---|
| Forma e capienza | Stesso Archivio EQ, quattro simple-vector di lunghezza esatta, tipi riga, count manifest/fonti e budget locali/globali |
| Metadata delle fonti | Tutte le guardie Serie: ordine u64, unico ACTIVE, CLOSED allineati, CONTROL EQ, stesso FD, EOF ACTIVE e P CLOSED |
| Gate canonico Archivio | Vista esatta e origine del replay, CLOSED completo, massimo di tutte le Serie e di tutte le DECISION |
| Nomi di tutte le Serie | Nome/FD, esattamente una forma presente, backend e rinomina esclusiva quando serve |
| Completamento | Ordine del catalogo, API Serie esistente, conteggi completi e fsync parent per fonte |

Il piano CSN scalare precedente non attesta i vettori correnti: non trattiene
token o FD. Il gate viene quindi ricreato usando esattamente i risultati
che saranno completati; piano e conteggi rimangono privati fino al successo.
Le statistiche del piano devono coincidere con count Serie e segmenti
ammessi prima delle scansioni. Prima di uscire, la somma dei due conteggi
deve coincidere con i segmenti e il FD decisioni deve essere ancora aperto.

Una fonte invalida o un nome incoerente nell'ultima Serie precede tutte le
rinomine e fsync. Il gate e i preflight non leggono nuovamente i byte dei
segmenti. Il completamento per Serie ripete i controlli metadata e nomi;
la primitiva per fonte ripete identita' e postcondizione. Il preflight
globale non prenota i nomi e non protegge da mutatori esterni.

## Budget e costo

I budget sono `index`, espliciti/configurabili con i default mostrati.
Zero e' valido e rifiuta un Archivio canonico non vuoto. Il limite per Serie
include ACTIVE e tutti i CLOSED; quello totale somma i segmenti di tutte
le Serie. La somma e le cardinalita' sono controllate prima delle scansioni
delle fonti. L'uguaglianza al limite e' ammessa. Il gate CSN ha un limite
locale sui soli CLOSED: il nuovo controllo che include ACTIVE e' piu' stretto.

Forma, autorita', count o tipi riga errati danno `invalid-argument`; budget
superati danno `resource-exhausted`. I tipi/range scalari usano safety3,
gli errori delle guardie e gli invarianti mantengono le condizioni originali.
Nessun default viene adattato automaticamente al carico.

I nuovi cicli sono limitati da Serie e segmenti ammessi, con soli cursori
e conteggi privati. Nessun nuovo array/hash o piano per fonte; restano il
piano scalare e le allocazioni dei gate canonici esistenti, dei nomi e della
FFI. Questo non definisce RSS o zero heap, ne' misura throughput o latenza.
Ogni fonte mantiene il proprio fsync, anche se gia' definitiva. La sequenza
appartiene al bootstrap; nessun lock/thread/stato condiviso nuovo nel traffico
operativo fra Serie.

## Guasti e lavoro restante

L'operazione non e' atomica fra Serie. Un guasto durante il completamento
conserva tutte le fonti gia' completate, comprese quelle di Serie precedenti,
e propaga la condizione originale senza piano o conteggi parziali, retry,
rollback o close. La primitiva I/O mantiene il proprio fail-stop del parent;
interruzioni fra chiamate concluse non implicano I/O pendente. Il caller
riacquisisce capacita' guaste e mantiene il traffico non ammesso fino alla
conclusione dell'intero recovery.

Rimozioni, nuovo ACTIVE, checkpoint CONTROL, ricostruzione indici, binding
runtime, registro CSN e ammissione restano da coordinare. Il confine generale
COD-24 non viene chiuso da questa API. Compilazione, lint, trace, link e
revisione statica sono distinti da test funzionali, FI, copertura, MC/DC,
mutazioni, guasti filesystem, crash e benchmark: la qualifica resta aperta.
