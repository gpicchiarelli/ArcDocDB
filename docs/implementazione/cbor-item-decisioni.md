# Primo item CBOR minimo — decisioni del nuovo sorgente

Inventario statico del 2026-10-15 prima della prima compilazione del
prodotto. Sorgente [cbor-item-read.lisp](../../src/codec/cbor-item-read.lisp),
blob `b9099dc8a8c96281063811e686deb4dcb2b1d39b`.
Il [metodo](cbor-item-metodo.md) e la [revisione](cbor-item-revisione.md)
distinguono inventario, obblighi statici e misure ancora da eseguire.

## Denominatore completo del sorgente

Una funzione, righe10–43 inclusive: **34 righe**. Percorsi sintattici:
base1 +5UNLESS +1WHEN +1LOOP = **8**. Sono inclusi i predicati interni
impediti dal preflight o da callee corretti; nessun sito è escluso.
Il numero non è il denominatore strumentato di SB-COVER né MC/DC.

**Sei predicati espliciti di controllo**, un ciclo bounded, cinque siti
ERROR; **zero AND/OR**, zero operandi AND/OR, quattro confronti numerici
binari e zero catene numeriche. Le tre inizializzazioni keyword default
di MAX-BYTES/MAX-NODES/MAX-DEPTH, righe11–12, sono dichiarate e non
escluse dall'eventuale copertura strumentata.

| ID | Riga | Predicato | Esito statico o coppia nominale prevista |
| --- | ---: | --- | --- |
| D1 |22| `SPAN <= +CBOR-SCAN-MAX-BYTES+` | Vero dopo il preflight. Falso implica violazione del contratto del callee: nessuna coppia pubblica dichiarata. |
| D2 |30| drain al cursore corrente, dentro LOOP | Falso prima del primo item; vero dopo item completo se esiste un'altra iterazione, per esempio `00 FF`. È il punto che termina senza leggere FF. |
| D3 |32| drain al cursore corrente, dopo LOOP | Vero nei successi, compreso `00` con un solo passo; falso nella finestra vuota e nella catena di soli tag troncata. |
| D4 |33| `CURSOR = LIMIT` | Vero nella finestra vuota e dopo esaurimento dei byte di una catena di tag. Falso impedito da progresso del passo e limite del ciclo: obbligo statico interno, non coppia eseguita. |
| D5 |39| `BEGIN < NEXT` | Vero nei successi. Falso impedito dal consumo di almeno un byte e dalla radice completata: obbligo statico interno. |
| D6 |41| `NEXT <= LIMIT` | Vero nei successi. Falso impedito dalle guardie del passo e dai lettori bounded: obbligo statico interno. |

I siti D2 e D3 chiamano lo stesso drain ma restano siti distinti del
denominatore. Non c'è decisione composta nuova per cui dichiarare
indipendenza delle condizioni; ciò non chiude MC/DC delle dipendenze
né la qualifica C1.

## Errori espliciti e ciclo

| Sito | Riga | Motivo INVARIANT-VIOLATION | Condizione e raggiungibilità nominale |
| --- | ---: | --- | --- |
| E1 |23| `:cbor-item-loop-span` | D1 falso, bloccato dal preflight corretto. |
| E2 |34| `:cbor-item-loop-bound` | D3 falso e D4 falso, bloccato da avanzamento/limiti corretti. |
| E3 |36| `:cbor-item-empty-header` | Solo se il lettore preesistente restituisse normalmente sullo span `[LIMIT,LIMIT)`. Il lettore deve invece lanciare `:cbor-truncated` a LIMIT. |
| E4 |40| `:cbor-item-read-progress` | D5 falso, bloccato da passo/root corretti. |
| E5 |42| `:cbor-item-read-range` | D6 falso, bloccato dai limiti del passo. |

`LOOP REPEAT SPAN`, riga29, ammette zero iterazioni per finestra vuota,
una per scalare senza coda e fino a SPAN passi che avanzano almeno un
byte. D2 può interrompere prima del passo successivo. Ogni drain ha
limite preesistente102; il passo riceve l'END originario e MINIMAL=T.
Il corpus prevede span0/1, tag concatenati, payload grandi e coda non
letta, senza inferire che il massimo teorico di iterazioni sia stato
eseguito da una fixture con payload che avanza in un solo passo.

I rifiuti pubblici range/workspace/alias/limiti/byte-budget e quelli
header/UTF8/nodi/depth sono propagati da funzioni preesistenti, senza
nuovi predicati in questo file. Restano nel contratto e nel corpus;
la copertura locale del nuovo file non misura i loro siti dipendenti.

## Lettura meccanica e stato

Il lettore C4 `review/read-product-decisions-v2.lisp`, conservato nel
supporto ignored dell'incremento, legge quattro forme DATA con
READ-EVAL NIL fino a EOF e conferma i conteggi sopra; stdout conservato,
stderr vuoto, exit0. Non carica, valuta o compila le forme del prodotto.
La prima variante aveva una parentesi mancante nel lettore stesso:
sorgente e stdout/stderr sono conservati separatamente e non contano
come test del prodotto. La misura in righe è un conteggio manuale.

I risultati runtime, tutti i denominatori grezzi, le eventuali forme
strumentate mancanti, heap e otto mutazioni restano da misurare.
Nessuna esclusione e nessuna attestazione C1/MC/DC da questa tabella.
