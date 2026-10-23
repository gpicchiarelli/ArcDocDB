# Lettura delle stringhe CBOR — decisioni

Inventario statico prima della prima compilazione, 2026-10-15.
Sorgente [cbor-string-read.lisp](../../src/codec/cbor-string-read.lisp),
blob `d4a4f774c2264c46349e7eda61ee4a2a3118d742`.
Il [metodo](cbor-stringa-lettura-metodo.md) mantiene aperta la qualifica C1.

Due funzioni: helper righe9–22, 14 righe e cinque percorsi sintattici
(base, tre guardie, un AND aggiuntivo); ingresso righe27–61, 35 righe e
dieci percorsi (base e nove guardie). Nessun ciclo o ricorsione nuovi.
Denominatore intero: dodici siti di controllo, un AND a due operandi,
undici ERROR, nove confronti numerici binari, zero catene. Un default
keyword a riga27, incluso nell'eventuale copertura strumentata.

| ID | Riga | Predicato | Esiti e obbligo |
|---|---:|---|---|
| D1 |16| A=`TYPEP MAX-BYTES INDEX` AND B=`MAX-BYTES<=16MiB` | A vero/B vero: budget0 o16MiB. A falso/B non valutato: NIL, negativo, float, bignum. A vero/B falso:16777217. I due operandi restano distinti; le coppie del corpus non costituiscono una misura MC/DC. |
| D2 |18| `SPAN>MAX-BYTES` | Vero: finestra `40 FF`, budget1. Falso: stessa finestra, budget2. Include la coda. |
| D3 |20| `SPAN<=16MiB` | Vero dopo D1/D2; falso implicherebbe violazione del preflight. Nessuna coppia pubblica dichiarata. |
| D4 |41| `FORM=:ARGUMENT` | Vero dal contratto del lettore minimo. Falso è un guasto interno del callee. |
| D5 |43| `MAJOR` di tipo integer2..3 | Vero per stringhe; falso per tutti gli altri major, dopo la verifica della testata. |
| D6 |45| `HIGH=0` | Falso per lunghezza minima u64 oltre u32, troncamento a END senza somma. |
| D7 |47| `LOW>LIMIT−PAYLOAD-START` | Vero per payload incompleto, prima dell'UTF-8; falso per payload completo, anche vuoto. |
| D8 |51| `MAJOR=3` | Vero testo da verificare, falso byte opachi; coda non validata in entrambi. |
| D9 |53| `COUNT<=LOW` | Vero per validatore UTF-8 corretto; falso rileva un conteggio interno impossibile. |
| D10 |55| `BEGIN<PAYLOAD-START` | Vero dopo una testata completa. Falso è un guasto interno di progresso. |
| D11 |57| `PAYLOAD-START<=NEXT` | Vero da LOW non negativo e somma dopo fit. Falso è un guasto interno. |
| D12 |59| `NEXT<=LIMIT` | Vero dopo fit. Falso è un guasto interno di frontiera. |

Le guardie interne e gli ERROR non raggiunti restano nel denominatore
grezzo. Non sono sottratti per migliorare percentuali. I controlli
dipendenti di range, header minimo e UTF-8 sono nel contratto e nei
test, ma non appartengono allo scope locale del nuovo file.

Il lettore C4 `review/read-decisions.lisp`, conservato nella campagna,
legge sei forme con READ-EVAL NIL fino a EOF e conferma i conteggi.
Non carica, compila o valuta il prodotto. stdout conservato, stderr
vuoto, exit0. Il conteggio in righe e percorsi è statico; SB-COVER e
qualifica MC/DC hanno obblighi distinti.
