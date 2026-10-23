# Completamento dei nomi dell'intera Serie

`arcdocdb.recovery.series:stabilizza-nomi-serie-recuperata` coordina il
[completamento per fonte](stabilizzazione-nomi-recovery.md) sull'intero
insieme ACTIVE/CLOSED gia' recuperato. Il [metodo preregistrato](stabilizzazione-serie-metodo.md)
elenca decisioni SGS-D01…D09 e limiti della verifica, prima del codice.
Realizza ADR-0040 §2–3; nessun nuovo formato o punto di commit.

## Uso e responsabilita'

```lisp
(arcdocdb.recovery.series:stabilizza-nomi-serie-recuperata
 directory sources active closed :max-segmenti 65536)
;; Due valori: numero rinominati, numero gia' definitivi.
```

`sources` e' il set posseduto aperto. `active` e `closed` sono i risultati
di `leggi-serie-recuperata`: il vettore CLOSED e' completo e ordinato per
ID u64. Il caller mantiene CONTROL autorevole, set, vettore, FD e namespace
esclusivi e stabili per l'intera chiamata nel pool I/O. Non trasferisce
ownership e non chiude singoli child. Il gate completo dell'Archivio resta
necessario prima del completamento e dell'ammissione.

Tre passaggi separano validazione ed effetti:

| Passaggio | Controllo |
|---|---|
| Metadata di tutte le fonti | Budget/count, ID strettamente crescenti, unico ACTIVE, token CLOSED allineati e CONTROL identico per EQ |
| Nomi di tutte le fonti | Stesso FD regolare, esattamente un nome, backend coerente, rinomina esclusiva disponibile quando serve |
| Completamento | Ordine ID del set; primitiva per fonte con postcondizione e fsync parent in entrambi i rami |

Un errore di configurazione, token o namespace nell'ultima fonte non
esegue prima rinomine o fsync sulle altre. I preflight dei nomi leggono
soltanto identita', senza leggere header o contenuti dei segmenti. Le
primitive ripetono i controlli prima dell'uso: il preflight globale non
prenota nomi o protegge da mutatori esterni.

## Completezza senza un altro contenitore

Il numero di CLOSED coincide con quello del manifest; il numero delle
fonti e' CLOSED piu' uno. Il set ha ID strettamente crescenti e ogni riga
corrisponde allo stato del manifest tramite le guardie canoniche per fonte.
L'unico ACTIVE usa lo stesso ID/FD/EOF del token; ogni CLOSED consuma il
successivo token con ID/FD/P esatti e CONTROL identico per EQ. Cardinalita',
appartenenza e ordine provano completezza senza un altro array o hash.

Un vettore CLOSED permutato viene rifiutato, anche se contiene gli stessi
elementi. ID zero e bit alti restano significativi; NIL rappresenta
ACTIVE non ancora trovato, quindi anche la posizione zero e' valida.
Prima del ritorno si verificano consumo del vettore, somma dei due
conteggi, parent e CONTROL ancora aperti. Il risultato esce solo completo.

## Guasti ed effetti parziali

Il gruppo non e' una transazione atomica. Un guasto durante la terza fase
conserva i completamenti precedenti e propaga la stessa condizione, senza
conteggi parziali, rollback, retry o close. Un errore durante un effetto
I/O mantiene il fail-stop del parent della primitiva esistente. Se
l'interruzione cade fra due chiamate completate, non c'e' I/O pendente da
annullare; il coordinatore osserva nuovamente i nomi e mantiene il traffico
non ammesso. Una capacita' guasta richiede una nuova acquisizione.

La scelta ACTIVE/CLOSED e i controlli semantici vengono ripetuti dalla
primitiva per fonte. Il caller impedisce chiusure o mutazioni del vettore
durante l'esecuzione; il risultato non e' una lease sui FD. Il confine
generale COD-24 della Serie e il coordinamento del Recovery Manager
rimangono aperti.

## Preflight I/O riusabile e costo

`io:verifica-stabilizzazione-temporaneo(directory, file, temporary, final)`
restituisce T per il nome temporaneo o NIL per il definitivo, dopo gli
stessi controlli del completamento. Non esegue rinomina, fsync o close e
non modifica lo stato del parent. Il risultato non e' un token di
autorizzazione; l'helper privato che prepara le foglie e il ramo e' condiviso
con `io:stabilizza-nome-temporaneo`.

`max-segmenti` e' un `index`, default 65536 e zero ammesso; include ACTIVE.
Budget superato: `resource-exhausted` prima delle scansioni. Cardinalita',
ordine, insieme o autorita' errati: `invalid-argument`. Tipi/range scalari
seguono i controlli safety3 delle firme; guasti I/O e invarianti propagano
senza mascheramento. I budget uguali al count sono validi.

Il lavoro cresce con il numero delle fonti; i cicli sono limitati dal count
gia' ammesso. Nessun array o hash nuovo e nessun oggetto per documento.
Nomi privati, controlli del runtime e FFI possono allocare sul percorso
freddo; memoria effettiva e RSS non sono misurate. Ogni fonte riuscita
mantiene il proprio fsync parent, anche se gia' definitiva.

Non si aggiungono lock, thread o scritture condivise tra Serie: la
sequenza riguarda una sola Serie. Non vengono eseguite rimozioni, creato
il nuovo ACTIVE, pubblicati CONTROL/indici o ammesso traffico.
Compilazione e revisione statica sono distinte da test funzionali, FI,
copertura, MC/DC, crash e misure di prestazione, ancora da eseguire.
