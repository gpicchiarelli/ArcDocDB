# Lettura delle stringhe CBOR — prima revisione C1

Lettura statica del responsabile del corpus freddo il2026-10-15,
distinto dall'autore del kernel. Avviene dopo il freeze del corpus
e dei driver, prima di LOAD/COMPILE o campagne del nuovo prodotto.
Il revisore non consulta la seconda revisione. Sorgente esaminato:
[cbor-string-read.lisp](../../src/codec/cbor-string-read.lisp), blob
**d4a4f774c2264c46349e7eda61ee4a2a3118d742**. Metodo preregistrato
[cbor-stringa-lettura-metodo.md](cbor-stringa-lettura-metodo.md), blob
`0b0fe8acea7677d34334d347d949901b3ae9698d`.

Nessun difetto funzionale o rilievo statico aperto individuato nel
blob. Corpus e prodotto non sono modificati da questa lettura.
Compilazione rigorosa, lint, test, heap, tempi paralleli, copertura e
mutazioni restano pendenti. REQ-CBR-009 è ancora **progettato** nel
catalogo letto; la matrice sarà rigenerata dall'integrazione.
Questa revisione non chiude la qualifica C1/MC/DC o i limiti documentali.

## Checklist C1

| Punto | Riscontro statico e limite |
| --- | --- |
| 1. Requisiti e ADR | REQ-CBR-009, LIM-001/002, AFF-004/008 e INV-A5/A8/P6 sono coerenti con ADR-0014/0024/0035/0048. La primitiva legge soltanto una stringa MT2/3 minima e restituisce coordinate nel buffer originale; profilo documentale, normalizzazione e conversione del testo restano fuori dall'incremento. |
| 2. Invarianti | Preflight verifica range, dominio del budget e finestra intera. Header minimo precede tipo MT2/3, HIGH e fit LOW precedono la somma; count UTF8 e tre guardie esplicite delle frontiere precedono il risultato. Nessuna mutazione del buffer o risultato parziale. |
| 3. Errori | Ordine range→byte-limit→byte-budget→sintassi/minimalità→tipo→fit→UTF8 rispettato. Offset NIL per preflight, START per tipo, END per troncamento CBOR e offset assoluti preesistenti per UTF8. La lunghezza completa precede l'UTF8 anche quando i byte disponibili sono già invalidi. |
| 4. Limiti | Preflight limita END−START a16MiB, compresa la coda. Header al più9byte; MT2 non attraversa il payload, MT3 delega UTF8 entro LOW byte. Zero cicli, ricorsione, attese o retry nuovi. Somma soltanto dopo HIGH=0 e LOW<=END−PAYLOAD-START. |
| 5. Heap | Due funzioni con sole variabili locali, parole u32 e tre valori multipli. Nessun array, cons, stringa, closure, AST o scratch nuovo nel successo. Il valore wire u64 non è ricostruito; la somma effettiva resta index/fixnum. Heap zero richiede ancora benchmark con baseline nulla e controllo positivo, senza inferirlo dalla lettura statica. |
| 6. Dati verificati | FTYPE pubblico dichiara esattamente MAJOR2/3, PAYLOAD-START index, NEXT index. Header minimo restituisce PAYLOAD-START; NEXT è la fine aritmetica del payload. UTF8 riceve quell'intervallo, non la fine della finestra. Payload vuoto ammesso e coda ignorata. |
| 7. Decisioni composte | Dodici predicati espliciti di controllo,11 siti ERROR, un AND a2operandi,9 confronti binari e0 catene/cicli. Inventario completo sotto, compreso il default keyword e i rami interni irraggiungibili con callee corretti. Nessuna esclusione o attestazione MC/DC. |
| 8. Proprietario | OWNER/SHARED dichiarano buffer stabile del chiamante e sole letture concorrenti. Nessuno scratch, destinazione, slot mutabile o stato globale nel prodotto. Il chiamante conserva il buffer stabile anche mentre usa l'intervallo restituito; il tipo simple u8 esclude backing displaced negli argomenti pubblici. |
| 9. Integrazione | Export package riga13; ASDF sorgente dopo i lettori/header già presenti, tre file corpus righe182–183, RUN riga270. Coverage dedicato seleziona solo il nuovo file, un positivo/quattro negativi di scope e RUN diretto/aggregato codec. Catalogo009 progettato senza :cov; matrice ancora da rigenerare, nessun trace/make check attestato. |
| 10. Standard | Safety3, due FTYPE completi, REQ e docstring Pre/Post/errori. Due funzioni14/35righe e5/10percorsi nella convenzione esplicita sotto, entro60/10, senza deviazioni. Entrambe hanno almeno due controlli significativi. Warning/style-warning e lint devono ancora essere osservati. |
| 11. Parallelismo | Nessuna attesa, thread, lock o scrittura condivisa nuova nel kernel. Corpus con due worker reali riusati e un solo buffer readonly, finestre MT2/MT3 distinte, due ondate, primo item verificato prima del rendezvous, sink/timestamp/timeout/cleanup. Tempi e overlap ancora da osservare; nessuna inferenza su core o scaling. |
| 12. Durabilità | Solo byte già presenti in memoria; nessun I/O, pubblicazione durevole o passaggio di proprietà. Il codec non modifica la Serie; gestione FAULTED degli invarianti interni resta al confine proprietario. |

## Preflight, parole e frontiere

`check-span-string-cbor-write`, riusato soltanto per il controllo del
range, non legge o scrive byte. Verifica simple u8, START/END index,
START<=END<=LENGTH e restituisce END−START, anche zero. Il nuovo
preflight verifica prima tipo index e massimo di MAX-BYTES, poi
SPAN<=MAX-BYTES; soltanto dopo entra nel lettore della testata.
Perciò `40 FF` con budget1 fallisce con byte-budget, e una finestra
vuota con budget invalido fallisce con byte-limit prima del troncamento.

Il lettore minimo propaga tutta la sintassi della testata prima della
minimalità. Poi il kernel verifica MAJOR2/3 prima del fit: una testata
minima MT4 con HIGH1 deve produrre string-type a START, senza tentare
di far entrare un payload di lunghezza enorme. Su MT2/3 HIGH non zero
produce invece troncamento a END; nessun valore u64 viene ricomposto.

Con HIGH0, la verifica LOW<=LIMIT−PAYLOAD-START precede la somma.
Il lettore di header garantisce START<PAYLOAD-START<=LIMIT. Quindi
PAYLOAD-START+LOW<=LIMIT<=LENGTH e NEXT resta index/fixnum anche
con un offset iniziale alto. LOW diventa al più16MiB prima di passare
come budget UTF8; il conteggio di scalari non può superare LOW.

Solo MT3 chiama `verifica-utf8` su `[PAYLOAD-START,NEXT)`, con
MAX-BYTES=LOW. Per `61 C2` seguito da80 nella coda, UTF8 resta
troncato al NEXT del payload:80 non completa la sequenza. `63 FF`
con soli due byte nella finestra è troncato a END prima di ispezionare
FF come testo. MT2 accetta invece anche byte FF/C0 e non attraversa
il payload. Payload vuoto dà PAYLOAD-START=NEXT, ammesso dalle guardie.
Le sole tre coordinate vengono restituite dopo tutti i controlli.

## Inventario completo del nuovo sorgente

Righe DEFUN dalla prima alla parentesi finale incluse, comprese
docstring/dichiarazioni. Percorsi sintattici: base1 più ogni WHEN/UNLESS
e ogni operando AND/OR oltre il primo; nessun ciclo nel nuovo file.
Non sono i branch di SB-COVER o una misura MC/DC.

| Funzione | Righe inclusive | Righe | Percorsi | Predicati di controllo | ERROR |
| --- | --- | ---: | ---: | ---: | ---: |
| check-input-string-cbor-read |9–22|14|5|3|3|
| leggi-stringa-cbor-minima |27–61|35|10|9|8|

| ID | Riga | Predicato | Riscontro o obbligo statico |
| --- | ---: | --- | --- |
| D1 |16| AND(TYPEP MAX-BYTES INDEX, MAX-BYTES<=16MiB) | Corpus include entrambi veri, tipo falso e massimo falso. Nessun operando escluso. |
| D2 |18| SPAN>MAX-BYTES | Vero per finestra oltre budget, falso per budget esatto o maggiore. |
| D3 |20| SPAN<=16MiB | Vero dopo D1/D2; falso impedito dal preflight corretto. Obbligo interno non presentato come coppia runtime. |
| D4 |41| FORM=:ARGUMENT | Vero dal lettore minimo corretto; falso è violazione del callee, non un input nominale. |
| D5 |43| TYPEP MAJOR INTEGER2..3 | Vero per MT2/3, falso per tutti gli altri major minimi. |
| D6 |45| HIGH=0 | Vero per lunghezze entro u32; falso nei vettori u64 con parola alta nonzero. |
| D7 |47| LOW>LIMIT−PAYLOAD-START | Vero per payload incompleto con HIGH0; falso anche per payload vuoto ed esatto. |
| D8 |51| MAJOR=3 | Vero MT3 valida UTF8; falso MT2 opaco, incluso payload non UTF8. |
| D9 |53| COUNT<=LOW | Vero per UTF8 corretto, compreso vuoto/ASCII/multibyte; falso impedito dal callee corretto. |
| D10 |55| BEGIN<PAYLOAD-START | Vero per header valido; falso impedito dal lettore minimo corretto. |
| D11 |57| PAYLOAD-START<=NEXT | Vero per LOW non negativo; falso impedito dai tipi e dalla somma corretta. |
| D12 |59| NEXT<=LIMIT | Vero dopo il fit, falso impedito da D6/D7 e somma corretta. |

D1 è l'unica decisione composta, due operandi. Candidati statici:
budget−1 contro0 per il dominio index con confronto numerico
controfattuale vero; budget0 contro16777217 per il limite, con
dominio index vero. Il secondo operando non è valutato se il primo
è falso. Il corpus contiene questi casi ma non ha ancora eseguito
alcuna coppia: non si attesta MC/DC misurato o indipendenza dinamica.

Siti ERROR tutti conservati: righe17(byte-limit),19(byte-budget),
21(invariante span),42(invariante forma),44(string-type),46 e48
(troncamento a END),54(invariante conteggio),56(invariante progresso),
58(invariante payload) e60(invariante range). Il default keyword
MAX-BYTES a riga27 e tutte le dichiarazioni restano nel denominatore
eventualmente prodotto dalla strumentazione; nessuna esclusione.
Le guardie false impedite da preflight/callee corretti sono obblighi
statici ancora presenti, senza inventare test nominali che le eseguano.

Una lettura inline READ-EVAL NIL/EOF, senza LOAD/COMPILE del prodotto,
conferma6forme,2DEFUN,9UNLESS/3WHEN,11ERROR,1AND/2operandi,
9 confronti binari,0 catene e0 cicli. Il primo comando inline aveva
una parentesi in più nel solo contatore, prima di leggere il prodotto;
la variante corretta passa. I due stdout/diagnostici sono soltanto
nella conversazione, non dichiarati come file raw locali.

## Corpus congelato e integrazione letta

| File cieco | Blob Git |
| --- | --- |
| tests/codec/cbor-string-read-support.lisp |cfd55cd47d782673113e67af625c1360195a345c|
| tests/codec/cbor-string-read.lisp |8437bdcaa4cf308dbf4614e748cdab4be2ae6d62|
| tests/codec/cbor-string-read-threads.lisp |8fc4ae5d9214108a6ae6bf26e644db1a42733cdd|

Piano freddo `review/blind-plan.md` nel supporto ignored, blob
`ce5b075ef19b0fc0baa65e88bdbebf434172281f`, con SHA256 completi:
17 nominali, **9906 chiamate attese**,690non-fuzz336/354,
1024fuzz512/512,8192parallele;9040successi/866rifiuti.
Sono denominatori aritmetici, non risultati PASS o contatori runtime.
Nessuno scanner secondario come oracolo. READ del corpus prima del
kernel:12/17/2forme,31totali,17nomi unici; nessun BODY prodotto presente.
Seme53545239, finaleF8417639 ricomputato freddamente e asserito.

Il corpus confrontato include tutti i major, larghezze e u64, MT2 con
tutti i256octet, UTF8 valido/invalido e offset, precedenze, ogni
troncamento di header/payload, range/backing fisico, payload vuoto,
budget completo16MiB/+1, frontiere concatenate, coda valida/malformata
ignorata, arità tre e input immutabile. Non è stato modificato.

Parallelo: un buffer25byte, END20; worker0 START7 attesi2/8/12,
worker1 START12 attesi3/13/16; token41333/41509 e
sink84649984/85010432 per worker/ondata. Due worker×due ondate×2048
chiamate, timestamp START/FIRST/END stampati dopo lavoro verificato,
rendezvous dopo la prima chiamata, attesa15s, join20s e cleanup
limitato. Nessuno scratch o stato scrivibile comune nel prodotto.

Integrazione: package `3e31d60234585442baa5664be96a83915e034397`,
ASDF `79f28d84f3b05bbbac6a0c2ce3aa9a3951f8e1ee`, coverage
`1b40e4e6433e4ca38b68adca93ff39fa523053a7`.
Catalogo REQ009 progettato: `a5739604a02fe494a57fda61e7f95c8a7d20adcd`;
matrice letta `d5d9e112cc4a3676060c8886137ba402f1d5859b`, da rigenerare.
Questi pin descrivono la lettura statica, non verifiche integrate riuscite.

Dipendenze lette: controllo span in cbor-string-write
`a2c5c77dd51bff760bff4508e998d94370921eda`; header
`db635a50678f2712ec9516be335717ea254d4d09`; minimo
`761302dad1073c841397f6c88d595b114af8d9ef`; UTF8
`26726c45555ae8490e0dff31f61f70735183acc7`; costante byte nello spazio
`a8330e50a77b52a6b9044ebbb48f62bb4b3222a3`; tipi foundation
`2d514f6fe2e81eecb29fa53de611fa5e28696904`.

Rimangono seconda revisione indipendente, compilazione senza warning,
lint, test e campagne con fonti/indice/HEAD stabili, heap, copertura
grezza integrale, mutazioni e letture DATA distinte dei risultati.
REQ-LIM-001/002, profilo documentale e qualifica C1/MC/DC restano aperti.
