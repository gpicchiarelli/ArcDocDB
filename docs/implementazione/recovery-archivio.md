# Lettura coordinata dell'Archivio

`arcdocdb.recovery.bootstrap` collega il [recovery semantico della Serie](recovery-serie.md)
al [piano CSN completo](csn-archivio-recovery.md). È un percorso di bootstrap
readonly: nessun nuovo formato o punto di atomicità durevole.

Il [completamento dei nomi dell'Archivio](stabilizzazione-archivio.md)
riconferma il gate sui risultati correnti e verifica tutti i nomi prima
degli effetti. Rimozioni, checkpoint, indici e ammissione restano aperti.

## Ingressi e risultati

```lisp
(arcdocdb.recovery.bootstrap:leggi-archivio-recuperato
 series-set decisions controls source-sets per-series-limits scratch max-total-bytes
 :max-segmenti-totali 1048576 :budget-riferimenti 16777216)
```

`series-set` è l'insieme canonico completo creato dal catalogo, Registri
inclusa. `decisions` è il replay completo dello **stesso oggetto Archivio**.
CONTROLS, SOURCE-SETS e PER-SERIES-LIMITS sono simple-vector nel medesimo
ordine delle viste del set. Ogni controllo deve riferire la vista esatta
per EQ; UUID uguali o ambiti clonati non sostituiscono questa autorità.
Ogni Serie conserva la propria configurazione readonly dei limiti.

Il caller mantiene tutti i set acquisiti, FD, namespace e ingressi stabili
per l'intera operazione, in recovery esclusivo nel pool I/O. Il catalogo
completo resta una precondizione: l'API non scopre una Serie omessa dal set
attestato dal chiamante. Non acquisisce directory o file e non effettua
riconciliazione fisica o modifiche dei nomi.

Al successo restituisce tre valori:

1. piano CSN canonico dell'Archivio;
2. nuovo simple-vector di ACTIVE recuperati;
3. nuovo simple-vector di vettori CLOSED recuperati, uno per Serie.

Gli output mantengono l'ordine del set. Vettori nuovi del caller, token
readonly dei reader; nessun buffer trattenuto. La chiamata successiva a
`crea-runtime-archivio` può usare il piano, con i propri obblighi ancora
aperti su effetti recuperati, indici e ammissione.

## Tutti i preflight prima dei dati

Prima di leggere il primo header vengono verificati autorità Archivio,
forma e lunghezze dei tre vettori. I budget minimi coprono almeno un ACTIVE
per Serie e i due vettori esterni. Poi ogni Serie viene verificata senza
leggerne i dati: vista esatta, cardinalità, stato/ordine ID, FD, backend,
scratch, P CLOSED rispetto a EOF e limiti locali.

Le capacità aggregate vengono controllate prima della scansione completa
delle fonti della riga: numero di segmenti e riferimenti. La somma dei byte
viene controllata dopo il preflight della riga, sempre prima di qualsiasi
header. Un errore di configurazione nell'ultima Serie non avvia prima la
lettura delle altre Serie. Identità binarie, CRC e semantica sono invece
verificati dai reader durante la successiva fase di lettura.

Il preflight interno della Serie restituisce ora anche il totale dei byte.
Il terzo valore aggiunge metadati, senza modificare i due risultati pubblici
di `leggi-serie-recuperata` o eseguire un'altra scansione dei dati.

## Budget globali e costo

Il budget byte è un `index` obbligatorio, esplicito e senza default o
clamping. Zero è ammesso e impedisce la lettura di qualunque Archivio non
vuoto. Misura somma EOF degli ACTIVE più P dei CLOSED; non IOPS o tempo.
`max-segmenti-totali` è un `index` configurabile, default 1048576, inclusi
ACTIVE. Zero rifiuta il set canonico non vuoto prima delle scansioni.

Per N Serie e S segmenti complessivi, i nuovi array di riferimenti hanno
payload 8*(N+S) su SBCL 64 bit: 16*N per i due vettori esterni e 8*(S−N)
per i vettori CLOSED. Default `budget-riferimenti`: 16 MiB, configurabile.
Ogni budget locale resta applicato alla relativa Serie. Il gate finale del
piano usa il budget globale come limite superiore per i CLOSED di una Serie;
i limiti più stretti sono già verificati prima dei dati e dai reader locali.

Sono esclusi scratch prestato, token, workspace e hash dei gate, oggetti,
header e GC: non è un limite RSS. Lo stesso scratch viene riusato per tutte
le Serie e deve contenere il massimo EOF ACTIVE/P CLOSED ammesso. Le Serie
vengono lette in sequenza in questo ingresso di bootstrap; nessun lock o
nuova serializzazione nel percorso operativo tra Serie. Restano disponibili
i reader separati per un futuro avvio parallelo governato dal coordinatore.

Le verifiche metadata vengono ripetute dai reader prima dell'uso; il gate
canonico finale riverifica insiemi, provenienza ACTIVE e tutte le decisioni.
Nessuna riapertura, enumerazione directory o nuova scansione dati per il
calcolo CSN. Non si deducono prestazioni da questa composizione; costo di
avvio, memoria, GC e parallelismo del bootstrap restano da misurare.

## Ritorno completo e lifetime

Dopo tutte le letture viene costruito il piano esistente, comprendendo
anche DECISION senza prepared locale. Il conteggio delle Serie e dei
segmenti del piano deve corrispondere al preflight. Solo allora escono i
tre valori. Se una qualunque lettura o l'ultimo gate fallisce, i risultati
precedenti restano privati e recuperabili dal GC, senza effetti pubblicati.
Lo scratch può essere stato modificato; nessun rollback dei buffer.

Le capacità rimangono dei proprietari dei set: nessuna close implicita su
successo o errore. I risultati non sono una lease sui FD e non impediscono
una chiusura illegittima del caller. Il proprietario termina i borrower
prima del cleanup. Condizioni originali propagate senza mascheramento o
retry. Il confine generale di arresto C1 e la gestione del cleanup del
coordinatore restano aperti.

## Decisioni e metodo preregistrato

| ID | Casi dedicati da verificare |
|---|---|
| RBA-D01 | Stesso Archivio EQ del replay; clone e UUID uguale non bastano |
| RBA-D02 | Tre simple-vector: ogni tipo e ogni lunghezza errati separatamente |
| RBA-D03 | Budget minimo ACTIVE/vettori, zero ed uguaglianza/meno uno prima delle scansioni |
| RBA-D04 | CONTROL della vista esatta per ogni riga; scambio e clone |
| RBA-D05 | Configurazioni diverse per Serie; tutti i preflight locali prima dei dati |
| RBA-D06 | Somma segmenti/riferimenti: uguaglianza/meno uno, compresa ultima riga |
| RBA-D07 | Somma byte: EOF ACTIVE e P CLOSED, limite esatto/meno uno; ultima riga invalida |
| RBA-D08 | Conteggio CLOSED stabile; Serie <= segmenti <= budget AND formula riferimenti AND byte nel budget |
| RBA-D09 | Reader canonici v1/v2, OUTCOME/EDIT/DECISION e provenienza del replay; scratch unico |
| RBA-D10 | Errore primo/ultimo reader o gate: nessun output/close/binding/CSN |
| RBA-D11 | Conteggio Serie AND segmenti del piano coerenti; singole FI; vettori nuovi |

Metodo: compilazione del solo prodotto senza avvisi, stile, tracciabilità,
link, disassemblaggio senza chiamare le nuove API, controllo C4 degli
archivi e conservazione degli originali. Due letture dell'autore separate
da revisione indipendente. Nessun test funzionale, FI, MC/DC, copertura,
modello o benchmark nuovo viene aggiunto o eseguito in questo incremento.
RBA-D01…D11, qualifica C1, pubblicazione degli effetti e gate del traffico
restano aperti; CI generale e controlli statici non li sostituiscono.

I [record locali e le riletture](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-17-archive-bootstrap/README.md)
conservano compilazione, controlli statici e disassemblaggio della revisione congelata.
