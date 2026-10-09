# Metodo di verifica degli header CBOR

Metodo registrato prima delle campagne. La primitiva legge un header di
al massimo nove byte dallo span immutabile del chiamante. Il profilo
documentale di ADR-0014/0048 resta al parser successivo: questo blocco non
attraversa payload, contenitori, tag o testo e non applica il limite di 100
livelli o il budget del documento completo.

## Contratto e oracoli

`arcdocdb.cbor:leggi-header-cbor(buffer,start,end)` restituisce sei valori:
major type, additional information, parola alta e bassa dell'argomento,
offset successivo e forma (`:argument`, `:indefinite`, `:break`). L'argomento
resta in due u32, compresi tutti i bit di un float64; non si crea un intero
u64 boxed né un oggetto float nell’implementazione prevista; la campagna
verificherà il percorso riuscito su SBCL a 64 bit.

Lo span è `[start,end)`, dentro un array semplice a byte. Range invalido:
`invalid-argument :cbor-range`, senza offset. Span vuoto o header incompleto:
`corruption-detected :cbor-truncated`, offset assoluto `end`. Si controlla
l'intera larghezza prima dei byte dell'argomento; un suffisso fisico fuori
dallo span non completa l'header. AI 28..30 sono riservati; AI 31 è ammesso
come forma indefinita per major 2..5 e come break per major 7, rifiutato
per 0/1/6. Un simple value con lead F8 e secondo byte sotto 32 è malformato.
Gli altri argomenti sono unsigned big-endian: larghezze 0/1/2/4/8 byte.

La sintassi segue [RFC 8949, §3 e §3.3](https://www.rfc-editor.org/rfc/rfc8949#section-3).
L'API conserva AI e bit originali: non rifiuta una rappresentazione intera
non minima, non interpreta float/tag e non attesta il contesto di un break.
Il profilo deterministico del documento deve applicare questi controlli
successivamente. Un esito riuscito non valida l'intero item CBOR.

Test indipendenti congelati prima di leggere il prodotto: tutti i 256 lead,
tutti i secondi byte di F8, tutti i 65.536 argomenti a due byte e fixture
asimmetriche per endianness e separazione high/low. Confini u32/u64,
float raw (zero, infinity, NaN), forme indefinite, non minimi e test di
priorità/troncatura con sentinelle. Fuzz differenziale finito di 4096 span
da 1..9 byte con modello aritmetico locale, che può usare bignum a freddo.
Nessun expected viene calcolato chiamando la primitiva di prodotto.

## Concorrenza e strumenti

Due thread reali percorrono header su buffer privati immutabili, verificano
tutti i sei valori, il contenuto integrale e intervalli di lavoro sovrapposti
fuori dalla barriera iniziale. Attese, iterazioni, join e cleanup hanno tetti
espliciti. Non è una misura dello scaling del pool.

Build rigorosa, lint, tracciabilità, due letture C1 e inventario delle
decisioni composte. Copertura con scope esplicito dei due sorgenti CBOR,
stato grezzo e tutti gli HTML; nessuna guardia viene rimossa dal denominatore.
Self-test del filtro e del ramo mancante. Mutanti compilabili in copie
esclusive: baseline completa obbligatoria, smoke su riga esatta,
compilazione fallita sempre invalida. Ogni tentativo e log resta conservato.

Allocazioni: fixture preallocate per tutte le larghezze, argomento u64
massimo, simple, float raw, indefinito e break; cinque repliche per cella,
4096 chiamate per replica, warmup 128 e GC fuori dalla misura. Tutti i sei valori alimentano un sink
osservabile confrontato con costanti indipendenti. Sensore con baseline
zero e controllo positivo 16 × 1 MiB. Criterio: zero heap osservato,
nessuna soglia di throughput. Le misure sono seriali e separate dalle
campagne di copertura/mutazione; non qualificano il motore completo.
