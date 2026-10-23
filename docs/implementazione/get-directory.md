# Directory GET dei segmenti CLOSED

`arcdocdb.get.directory` collega il candidato del primary alla mappa del
[resolver CLOSED](get-resolver.md) senza una scansione lineare dei segmenti.
Ogni directory appartiene alla vista canonica di una sola Serie. Non modifica
formato, ordinamento dei commit, isolamento o protocolli di pubblicazione.

## Preparazione e memoria

`crea-directory-get-serie(view, maps, :max-segments M, :budget-payload B)`
accetta un simple-vector di mappe CLOSED già verificate, in ordine di ID
positivo u32 strettamente crescente. Rifiuta una vista estranea, ID storage
con parola alta non zero, ID zero, duplicati, ordine inverso, FD non readonly
oppure chiuso. Il caller mantiene l'input esclusivo e stabile fino al ritorno.

Forma, cardinalità e payload sono controllati prima di scandire le mappe o
allocare i due array. Poi ogni mappa viene controllata, i riferimenti copiati
e gli ID copiati in un array u32. Il risultato non espone array mutabili.
Il vettore input può essere riusato; mappe e capacità rimangono immutabili.
Le mappe non sono ricostruite né i file riletti durante questa preparazione.

| Limite/dato | Valore |
|---|---|
| Segmenti per directory | 0–65.536; massimo configurato positivo ≤ 65.536 |
| Payload proprio | `12 × N` byte su SBCL a 64 bit |
| Payload predefinito | 786.432 byte |
| Ricerca del segmento | Al più 17 passi, ciascuno con ≤ 2 confronti fra ID; nessun retry |
| Costruzione | Due scansioni limitate e una copia di riferimenti |

Il budget di dodici byte per segmento comprende un u32 e un riferimento.
Esclude oggetti/header Lisp, input del caller, mappe, FD, scratch GET,
vecchie directory trattenute e GC: **non è RSS** o un budget del processo.
`conta-segmenti-directory-get` e `payload-directory-get-serie` osservano
soltanto la vista completata. Saturazione implica backpressure o revisione
della configurazione del controller, senza crescita implicita.

## Lettura sotto EBR

1. Avviare GET con il contesto del worker e la richiesta originale.
2. Se l'esito è `:candidate`, acquisire la directory immutabile pubblicata
   dal controller **dopo l'ammissione EBR**, nella stessa epoca del candidato.
3. `trova-mappa-directory-get` seleziona l'ID del segmento dalla word della
   location. Una directory vuota o priva di quell'ID provoca `FAULTED`:
   un indice già pubblicato non può riferire una fonte inesistente.
4. `risolvi-candidato-directory-get` delega al resolver CLOSED i controlli
   di offset, lunghezza, entrambe le word CSN, frontiera, flag, prova e FD.
   La directory da sola non autorizza la consegna di un valore.
5. `sonda-cache-directory-get` non esegue I/O. Il pool I/O usa
   `leggi-record-directory-get`, che restituisce i cinque esiti del GET.
   Prepared conserva la prova OUTCOME autorevole e la rilettura dal file.
6. Copiare il valore nella risposta privata; concludere con tempo fresco.
   Snapshot e pin sono controllati/rilasciati prima di autorizzare il valore.

Il cleanup esterno resta obbligatorio e viene installato prima di avviare
GET. Precondizioni d'ordine errate sono respinte prima di prendere possesso
del cleanup; errori o uscite non locali dopo l'ammissione liberano il pin.
Nessun FD, candidato, directory o pin attraversa una coda: un worker I/O
riavvia GET e riacquisisce la directory dopo il nuovo lookup.

## Pubblicazione e lifetime

Il controller pubblica directory/mappe prima che le location corrispondenti
siano osservabili dal primary. Una radice acquisita prima del pin non è
protetta dal successivo ingresso EBR. Riferimenti Lisp e immutabilità degli
array non autorizzano la chiusura dei FD.

Rotazione/rilocazione devono lasciare raggiungibili tutte le fonti di un
candidato che un reader già ammesso può ancora utilizzare. I FD restano
aperti fino al reclaim autorizzato. La validità della mappa CLOSED deriva
dal manifest e dai byte verificati dal suo costruttore; la directory non
usa EOF, H, hint o la cache per inventare una frontiera.

Il [ponte delle fonti](get-fonti-serie.md) associa la directory al contenuto
della radice ACTIVE pubblicata dal controller esistente, oppure alla radice
CLOSED iniziale. La selezione usa una sola lettura acquire dopo il lookup.
Rotazione, rilocazione/reclaim completo e ricerca storica restano aperti.
Serie indipendenti hanno directory
indipendenti; la selezione non tocca stato condiviso fra Serie.

## Errori e decisioni C1

Errori di input/configurazione hanno tipo `invalid-argument`; saturazioni
`resource-exhausted`. Vista estranea durante GET libera il pin e propaga
l'errore. Geometria interna impossibile o ID mancante rende il contesto
`FAULTED` e propaga `invariant-violation`; il coordinatore deve isolare la
Serie. La selezione non traduce questi casi in `:absent` o `:retry`.
Le condizioni del resolver/GET restano quelle dei moduli delegati.

| ID | Decisione | Verifica richiesta |
|---|---|---|
| GDR-D01 | Massimo di tipo index, positivo e ≤ 65.536; budget index | Ogni condizione separata, zero/estremi/tipi |
| GDR-D02 | Mappa con ID alto zero e basso positivo | Ciascuna word e ID massimo |
| GDR-D03 | FD readonly e aperto | Ciascuna condizione separata |
| GDR-D04 | Array di pari cardinalità entro il massimo | Geometria corrotta e cardinalità massima |

Anche il tipo della entry selezionata è un invariante sempre controllato:
una entry privata NIL da fault injection produce `FAULTED` prima del ritorno,
senza essere classificata come normale errore di configurazione.

Riferimenti: [ADR-0044](../adr/0044-cache-acceleratore-puro.md),
[ADR-0045](../adr/0045-modello-di-esecuzione.md),
[compiti GET](get-record.md), [campagna](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-directory/README.md).
I requisiti rimangono progettati fino alla qualifica C1 completa; nessuna
qualifica del motore viene dedotta dalla presenza di questa directory.
