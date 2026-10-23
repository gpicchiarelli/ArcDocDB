# Lettura delle stringhe CBOR — seconda revisione C1

2026-10-15. Lettura statica indipendente precedente alla prima compilazione
del nuovo prodotto. Esito locale: **PASS statico, nessun difetto concreto
rilevato**. Il revisore ha proposto il contratto, ma non ha scritto kernel,
corpus o driver; non ha consultato la prima revisione C1. Nessun LOAD,
compilazione o esecuzione del prodotto durante questa lettura.
Le verifiche dinamiche, heap e qualifica C1/MC/DC restano aperti.

## Fonti osservate

HEAD `b83a0bdaa597d1cb53c7ae4a5ebadc11ae2511ff`; il kernel è stato
consegnato dopo il freeze del corpus e dei driver. I pin sono stati letti
direttamente dal worktree, senza modificare fonti, corpus, indice o HEAD.

| File | Git blob |
|---|---|
| `src/codec/cbor-string-read.lisp` | `d4a4f774c2264c46349e7eda61ee4a2a3118d742` |
| `arcdocdb.asd` | `79f28d84f3b05bbbac6a0c2ce3aa9a3951f8e1ee` |
| `src/codec/cbor-package.lisp` | `3e31d60234585442baa5664be96a83915e034397` |
| `tools/foundation-coverage.lisp` | `1b40e4e6433e4ca38b68adca93ff39fa523053a7` |
| `tests/codec/cbor-string-read-support.lisp` | `cfd55cd47d782673113e67af625c1360195a345c` |
| `tests/codec/cbor-string-read.lisp` | `8437bdcaa4cf308dbf4614e748cdab4be2ae6d62` |
| `tests/codec/cbor-string-read-threads.lisp` | `8fc4ae5d9214108a6ae6bf26e644db1a42733cdd` |
| `docs/implementazione/cbor-stringa-lettura-metodo.md` | `0b0fe8acea7677d34334d347d949901b3ae9698d` |
| `docs/tracciabilita/requisiti.lisp` | `a5739604a02fe494a57fda61e7f95c8a7d20adcd` |
| `docs/tracciabilita/matrice.md` | `4ee14ed1c657e1f419cfcc1b0418c28653125dcf` |

Dipendenze lette: `cbor-string-write.lisp:10–21`
(`a2c5c77dd51bff760bff4508e998d94370921eda`), `cbor-header.lisp`
(`db635a50678f2712ec9516be335717ea254d4d09`), `cbor-minimal.lisp:48–66`
(`761302dad1073c841397f6c88d595b114af8d9ef`), `utf8.lisp`
(`26726c45555ae8490e0dff31f61f70735183acc7`) e costante byte in
`cbor-space.lisp:8` (`a8330e50a77b52a6b9044ebbb48f62bb4b3222a3`).
I tipi `octets/index` sono definiti in `src/foundation/binary.lisp:4–5`.
Non sono stati letti i driver benchmark/audit/mutazione né risultati runtime.

## Contratto, precedenze e limiti

Il preflight `check-input-string-cbor-read`, righe9–22, chiama il
controllo span esistente prima di leggere byte. Range invalido precede
budget invalido, che precede esaurimento dell'intera finestra END−START.
Lo span vuoto arriva poi al lettore header, che segnala troncatura a END.
Il caso `40 FF` con budget1 è rifiutato prima di leggere l'header.

`leggi-stringa-cbor-minima`, righe27–61, chiama il lettore minimo prima
del controllo MT2/3. Riservati, indefiniti, testate troncate o nonminime
mantengono quindi la precedenza rispetto a `:cbor-string-type` a START.
FORM è controllato esplicitamente alla riga41; il callee restituisce
soltanto `:argument` o segnala una condizione. AI, ignorato alla riga40,
è metadato della larghezza, non un indicatore di errore trascurato.

HIGH nonzero è rifiutato prima del confronto LOW con END−PAYLOAD-START.
La somma alla riga49 avviene soltanto dopo queste prove: non viene
ricostruito un intero u64 e NEXT non può superare END. Una lunghezza
minima di almeno 2^32 non entra nella finestra massima di 16 MiB e produce
`:cbor-truncated` a END. Il payload completo precede ogni lettura UTF-8.

MT2 non legge i byte del payload. MT3 passa soltanto
`[PAYLOAD-START,NEXT)` al validatore, con budget LOW; il conteggio
restituito è controllato. Un byte oltre NEXT non completa una sequenza
UTF-8 troncata. Nessuna coda, copia, conversione in stringa Lisp,
normalizzazione o semantica dei tag viene introdotta. Il chiamante
mantiene stabile il buffer anche mentre usa l'intervallo restituito.
Il ritorno alla riga61 contiene esattamente tre valori fixnum.

## Inventario completo del nuovo controllo di flusso

Due DEFUN: helper 9–22, **14 righe**; lettore 27–61, **35 righe**, includendo
docstring e dichiarazioni. Helper: base 1 + 3 guardie = 4 flussi; aggiungendo
il cortocircuito dell'unico AND, **5 percorsi** nella convenzione
conservativa. Lettore: base 1 + 9 guardie = **10 percorsi**. Entrambi entro
COD-12/13. Non si espandono i rami dei callee nel conto del nuovo file.
Nessun LOOP, DOTIMES, DOLIST, IF, COND, CASE o ricorsione nuovo.

| Decisione | Riga | Predicato e raggiungibilità dei due esiti |
|---|---:|---|
| D1 |16| MAX-BYTES è index e non supera il tetto: valido oppure `:cbor-byte-limit`; tipi e tetto nel corpus. |
| D2 |18| SPAN>MAX-BYTES: rifiuto oppure header; provati finestra intera, budget inferiore e confine esatto. |
| D3 |20| SPAN≤tetto interno: vero dopo D1/D2; falso viola il contratto del preflight. |
| D4 |41| FORM=`:argument`: vero dal lettore minimo; falso richiede callee incoerente. |
| D5 |43| MAJOR in 2..3: bytes/testo ammessi, altri sei major rifiutati dopo header. |
| D6 |45| HIGH=0: LOW utilizzabile oppure troncatura; vettori u64 minimi con HIGH positivo. |
| D7 |47| LOW>END−PAYLOAD-START: troncatura oppure payload completo; include vuoti e END ristretto. |
| D8 |51| MAJOR=3: UTF-8 sul solo payload oppure MT2 opaco. |
| D9 |53| COUNT≤LOW: vero da UTF-8 corretto; falso richiede violazione del suo contratto. |
| D10 |55| START<PAYLOAD-START: vero da header riuscito; falso è errore interno. |
| D11 |57| PAYLOAD-START≤NEXT: vero per LOW u32, compreso 0; falso è errore interno. |
| D12 |59| NEXT≤END: vero dal fit prima della somma; falso è errore interno. |

Un AND a due operandi, nella sola D1; zero OR. Il primo operando è
`typep max-bytes 'index`, il secondo `max-bytes≤tetto`. Se il primo è
falso, il secondo non viene valutato: non gli si attribuisce un valore
osservato. Il corpus include tipi invalidi, budget sopra tetto e validi;
non sono ancora coppie runtime che chiudano MC/DC.

Nove confronti numerici binari: helper `<=`16, `>`18, `<=`20; lettore
`>`47, `=`51, `<=`53, `<`55, `<=`57, `<=`59. In più ZEROP(HIGH)45.
Zero confronti con almeno tre operandi. Tipi interval e confronto EQ
di FORM restano distinti dai confronti numerici. Il default MAX-BYTES
della riga27 rimane nel denominatore strumentato, insieme alle
dichiarazioni e a tutti i bracci di errore.

Una lettura meccanica Common Lisp delle sei forme del sorgente, con
READ-EVAL NIL fino a EOF, senza valutarle, ha confermato: helper con 3
decisioni, 1 AND, 2 operandi, 3 ERROR e 3 confronti; lettore con 9 decisioni,
zero AND/OR, 8 ERROR, 6 confronti e 1 ZEROP. Righe ricavate dal testo numerato.
Il cortocircuito è aggiunto separatamente nel conto conservativo dei percorsi.

## Tutti gli errori diretti

| Riga ERROR | Classe / reason | Offset | Natura |
|---:|---|---|---|
|17| INVALID-ARGUMENT `:cbor-byte-limit` | NIL | Budget fuori tipo o intervallo. |
|19| RESOURCE-EXHAUSTED `:cbor-byte-budget` | NIL | Intera finestra oltre budget, anche se il primo item è breve. |
|21| INVARIANT-VIOLATION `:cbor-string-read-span` | NIL | Tetto interno difeso dopo preflight. |
|42| INVARIANT-VIOLATION `:cbor-string-read-form` | START | Forma impossibile dopo header minimo corretto. |
|44| CORRUPTION-DETECTED `:cbor-string-type` | START | Header minimo valido di un altro major. |
|46| CORRUPTION-DETECTED `:cbor-truncated` | END | HIGH nonzero. |
|48| CORRUPTION-DETECTED `:cbor-truncated` | END | LOW supera i byte autorizzati disponibili. |
|54| INVARIANT-VIOLATION `:cbor-string-read-count` | PAYLOAD-START | Conteggio UTF-8 incoerente. |
|56| INVARIANT-VIOLATION `:cbor-string-read-progress` | START | Header privo di progresso. |
|58| INVARIANT-VIOLATION `:cbor-string-read-payload` | PAYLOAD-START | Frontiera payload invertita. |
|60| INVARIANT-VIOLATION `:cbor-string-read-range` | NEXT | Frontiera oltre END. |

Totale 11 ERROR: 6 invariant, 3 corruption, 1 invalid-argument, 1 resource.
Range, header/minimalità e UTF-8 propagano inoltre le proprie condizioni
tipizzate senza handler o riclassificazione. Le sei guardie interne
rimangono attive; i bracci impossibili con callee corretti sono obblighi
statici, non esclusioni di copertura o esiti nominali inventati. Il
proprietario esterno applica il fail-stop previsto per le invarianti;
questa primitiva non possiede lo stato della Serie.

## Checklist delle due letture C1: seconda lettura

| Punto dello standard | Riscontro e limite |
|---|---|
|1. REQ e ADR| REQ-CBR-009, LIM-001/002, AFF-004/008 sono su entrambe le DEFUN; ADR-0014/0024/0035/0048 e metodo coerenti. Il requisito locale non qualifica il documento deterministico. |
|2. Invarianti| INV-A5: solo esito completo o condizione; INV-A8: budget prima dei byte e fit prima della somma; INV-P6: buffer readonly, variabili locali. Corpus nominale/rifiuti/immutabilità e worker condivisi disponibili, non ancora eseguiti. |
|3. Errori| Tutti gli 11 siti espliciti inventariati sopra; precedenze concorrenti coperte dal corpus freddo, compresi tipo, HIGH, fit e UTF-8. Nessun ritorno di errore ignorato. |
|4. Lavoro bounded| Nessun ciclo nuovo. Header fino a 9 byte; UTF-8 usa LOOP REPEAT SPAN, al più 16 MiB; nessuna attesa, I/O o ricorsione. |
|5. Heap| Nessun costruttore, closure, AST o scratch nuovo. Parole u32, index e valori multipli; aritmetica e chiamata keyword UTF-8 restano da misurare con baseline nulla e sensore positivo. Heap zero non attestato. |
|6. Dati verificati| Buffer simple u8 e indici verificati prima dei THE; header minimo, major, HIGH/LOW e fit prima di NEXT; UTF-8 prima del ritorno MT3; frontiere finali controllate, tre valori esatti. |
|7. Decisioni composte| Un AND con 2 operandi, zero OR/catene; tabella e tutti i siti sopra. Nessuna deduzione di MC/DC delle dipendenze o del modulo. |
|8. Proprietà| OWNER/SHARED alle righe2–3; nessuna mutazione del buffer o stato globale. La vista non prolunga da sola la stabilità della memoria: obbligo del chiamante. |
|9. Integrazione| Export `cbor-package:13`; ASDF prodotto riga 36 dopo dipendenze, corpus 182–183 e RUN 270. Coverage: scope esatto 82–83, positivo/quattro negativi 134–138, RUN 304, aggregato 351, CLI 2/363–364. Matrice rigenerata con 127 requisiti e 66 invarianti; REQ-CBR-009 resta progettato. Build/check e campagne ancora da eseguire. |
|10. Regole| FTYPE completi alle righe 8/25–26, safety 3; 14/35 righe, 5/10 percorsi conservativi. Controlli esterni e postcondizione del preflight, forma/conteggio/frontiere del lettore attivi. Nessuna deviazione richiesta dalla lettura statica. |
|11. Parallelismo| Nessun lock, thread, attesa o scrittura tra Serie nel prodotto. Due worker reali del corpus condividono il buffer readonly, con due ondate da 2048 chiamate ciascuno: 8192 letture previste, rendezvous e cleanup bounded. Nessuna misura di scaling. |
|12. Durevolezza| Nessun cambiamento durevole, cancellazione, pubblicazione o punto di atomicità nuovo. Il ritorno è soltanto una vista nel buffer del chiamante. |

## Corpus e stato della verifica

Sedici test seriali e uno con due worker, congelati prima del kernel.
Oracolo letterale e testate costruite aritmeticamente senza writer del
prodotto: vuoti, tutti i byte MT2, UTF-8 e offset assoluti, soglie
23/24–255/256–65535/65536, HIGH u64, tutte le troncature selezionate,
finestre 16 MiB/+1, code non valide ignorate e budget dell'intera finestra.
MULTIPLE-VALUE-LIST controlla arità 3 fuori dalla misura heap. Il fuzz
congelato usa seme 53545239 e 1024 casi: 512 successi e 64 per ciascuna delle
otto classi di rifiuto, con stato finale previsto f8417639.
Sono attesi statici del corpus, non risultati runtime di questa revisione.

Il secondo documento non promuove REQ-CBR-009 a implementato/verificato.
Prima del completamento occorrono compilazione senza avvisi, test,
misure heap, mutazioni e self-test C4, lettura indipendente della copertura
completa e dei risultati, make check e conservazione delle prove. Tutti
i missed, incluse guardie interne, restano nei denominatori grezzi.
REQ-LIM-001/002, profilo documentale e qualifica C1/MC/DC rimangono aperti.
