Questa pagina pubblica integralmente la lettura runtime congelata, blob originale
`1872e19955ddcec09a83d8e9e78d7c51f8838b12`, conservata nell'[archivio della lettura](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-cbor-float-write/raw/readings/runtime-review-draft.md.txt).
Per la raccolta conclusiva e le verifiche successive, il riferimento è la
[relazione dei risultati finali](cbor-float-scrittura-risultati.md).

L'unico adattamento editoriale è questa introduzione con i due collegamenti:
il contenuto congelato seguente è preservato integralmente, comprese le diciture
riferite alla bozza e al momento originario della lettura.

# Scrittura float CBOR — lettura dei dati runtime

Lettura del 2026-10-13 sul worktree isolato, completata prima della
raccolta finale. Questo lettore è autore del corpus cieco e della seconda
lettura statica: il controllo dei risultati non è indipendente dal
corpus. Il ricalcolo del benchmark è separato dal driver e dall'auditor,
mediante fixture fredde esaminate aritmeticamente. Non sono stati caricati
o chiamati prodotto, driver benchmark, mutatore o suite. Sono stati
caricati soltanto lo strumento fidato `tools/evidence-storage.lisp` e il
componente SBCL SB-MD5 per le impronte delle copie. I record sono dati;
stdout strutturati sono letti con READ-EVAL NIL, readtable standard,
package CL-USER, una forma e EOF, senza eval dei dati.

Questa bozza resta esclusa dalla raccolta fino al freeze comunicato al
coordinatore. La copertura grezza è affidata a un altro lettore. Nessuna
qualifica C1, MC/DC, del motore o di durabilità viene attestata da questa
lettura. Nessuna campagna è stata rieseguita e nessun file sorgente,
matrice, indice Git o configurazione è stato modificato.

## Registri letti

Tutti gli otto record riportano STATUS OK, EXIT-CODE 0 e
SOURCE-CONSISTENCY STABLE. Le 738 entry before/after sono identiche e lo
snapshot è uguale fra le campagne, verificato anche nel controllo finale
`fa5967`. HEAD registrato `364ac3b8c6dc3877e978ce551dc6e2fbab8ea1f0`,
working tree vuoto al momento delle campagne.

| Registro in `spikes/out/` | Operazione | Secondi processo |
|---|---|---:|
| `4000905572-command-32032-0/report.lisp` | test/lint/trace preliminari | 25.805550 |
| `4000905572-command-32033-0/report.lisp` | self-test scope coverage | 1.107459 |
| `4000905572-command-32030-0/report.lisp` | self-test mutatore | 1.388969 |
| `4000905572-command-32031-0/report.lisp` | self-test auditor dati benchmark | 1.203470 |
| `4000905644-command-32361-0/report.lisp` | self-test benchmark | 0.994824 |
| `4000905677-command-32530-0/report.lisp` | benchmark | 1.416727 |
| `4000905717-command-32851-0/report.lisp` | audit dati benchmark | 1.323565 |
| `4000905717-command-32852-0/report.lisp` | baseline e otto mutazioni | 184.386720 |

Snapshot: narrow `cd5749edc0a757ee3a5b470eda566a6685d32fd8`, writer
`03c6aed61e2c243d8b1a6c4332ce1837c4e9a77c`; tre file del corpus
`6ba7c20701b60789d92ff232fc02b0f476334911`,
`747cd8a72445a3ea638cd1910bc9faa63f4cdc33`,
`f95bf450148fa2aab9bb28c178b986dee049de6e`, uguali ai freeze ciechi.
Metodo `755b13a91ab72f54383d96faee5780da36e750d6`; letture statiche prima
`0d644768dc2f8efeb86136a8a4c4206c4c464bb6` e seconda
`134173468ca2bfd538eb1f6bbeda4dda128e800b`.
Benchmark `d992c9f8cf6ff0d748fcb77f871fb77969480bca`, auditor
`485544868eeadff247968b86c2d5da9b3b610295`, mutatore
`5d0d6bd46b0286f153ee9c482734c659959396e2` e scope coverage
`6262967597ab1c0c142ce1a988ec2ecf49543865`.

Ambiente registrato: SBCL 2.6.9, Darwin 27.0.0 ARM64, Apple M4, memoria
17.179.869.184 byte e 10 CPU logiche; carico esterno UNCONTROLLED.
Sono metadata osservati, senza inferenza su frequenza o core attivi.

## Corpus e controlli preliminari

Sono presenti 989 righe `ok` distinte: 987 test nominali e due smoke
espliciti, package radice e stringa versione. Fra esse 18 sono i test
REQ-CBR-004. I marker del corpus confermano:

- Tutti i 65.536 half e 131.072 espansioni: 196.608 successi e 196.608
  capacità insufficienti, con otto offset e tre configurazioni ruotati.
- Fuzz 2.048, seed 464C5434: 768 successi, 256 capacità, 128 AI, 128 HIGH,
  128 LOW, 256 parole e 384 range/destinazioni rifiutati.
- Due ondate da 16.384 chiamate aggregate, 32.768 totali, sink
  2.115.584/2.148.352 per entrambe. Overlap 2.576/2.580 tick a 1.000.000
  tick/s. Gli intervalli della fixture non attestano scaling sui core.
- Lint: 165 file, 0 violazioni. Trace: 118 requisiti, 65 invarianti,
  13 scenari FI, 52 ADR, 0 errori.

Nel transcript compilatore non compaiono WARNING, STYLE-WARNING o
Unhandled. Sono presenti 200 note per il prodotto e 743 per i test:
note di ottimizzazione/tipo, distinte dagli avvisi fatali. Il controllo
successivo è una lettura dei log, non una nuova compilazione.

## Self-test degli strumenti

Il self-test scope dichiara il rilevamento del ramo mancante. Quello del
mutatore conserva un processo realmente segnalato con signal 9/exit 137
e uno che completa i marker ma termina con exit 7. Entrambi sono
WORKER-ERROR, DETECTED NIL: due guasti worker attesi, nessuna falsa
mutazione rilevata. Conserva anche le fixture baseline-copy e
baseline-transport nei rispettivi record. Sono scenari sintetici,
separati dalla baseline reale.

L'auditor benchmark self-test registra 167.234 controlli, quattro report
positivi e 70 fixture negative con 70 nomi distinti e motivi specifici.
Comprende byte/subnormale, parole raw, span/NEXT/arità, sink/heap/timer,
metadata, impronte, inventario e dati reader-eval/trailing/impropri/ciclici.
Il riferimento freddo comprende sei casi del catalogo e sette casi
ulteriori di zero/infinito/NaN, con aritmetica intera/razionale senza float
nativi.

Benchmark self-test e benchmark includono baseline nulla a 4.096
chiamate, warmup 128, heap 0 e sink 8.386.560. Il positivo 16×1 MiB
registra 16.777.472 byte, almeno 16.777.216 deliberati, e sink 16.777.336.
Otto alterazioni output, due shape e sei byte, quattro arità/NEXT, sink
errato e heap nonzero sono rifiutati per il motivo previsto.

## Benchmark: ricalcolo freddo

1.5 è half 3E00, binary64 3FF80000/00000000. Binary64
3FF00000/20000000 rappresenta 1+2^-23 ed è single 3F800001, senza forma
half esatta. LOW 1 in 3FF00000/00000001 impedisce la riduzione da 64.
3E700000/00000000 rappresenta 2^-24, minimo subnormale half 0001.
FFF80000/00000001 conserva segno negativo, quiet NaN e payload non
allineato verso 32, quindi rimane 64. Questi riscontri non usano il codec.

| Fixture | Byte freddi | NEXT | Token | Sink per 4.096 |
|---|---|---:|---:|---:|
| half identity | 249 62 0 | 5 | 6445 | 34785280 |
| double→half | 249 62 0 | 5 | 6445 | 34785280 |
| double→single | 250 63 128 0 1 | 7 | 8421 | 42878976 |
| double only | 251 63 240 0 0 0 0 0 1 | 11 | 11632 | 56031232 |
| double→half subnormal | 249 0 1 | 5 | 6202 | 33789952 |
| double NaN payload | 251 255 248 0 0 0 0 0 1 | 11 | 12440 | 59340800 |

START 2, END=NEXT+2, buffer SIZE+6 a sentinella 165: due byte di prefisso,
due residui e due oltre END. Ricalcolati array completo, parole raw,
dimensione, NEXT, una sola cold-value, token NEXT+Σ(i+1)×byte[i] e sink
4.096×TOKEN+4.096×4.095/2. Per tutti i 30 campioni: 4.096 chiamate,
warmup 128, heap 0, token/sink esatti, secondi=RAW-TICKS/1.000.000 e
rate=4.096/secondi. Totale 33.414 tick=0,033414 secondi di campioni;
processo benchmark 1,416727 secondi. La misura include i controlli
completi della fixture e non rappresenta throughput del motore, scaling
o prova assoluta di nonallocazione.

Impronte interne: 167 entry MD5 before/after uguali. L'audit runtime
registra 55.824 controlli, sei celle/trenta campioni, heap 0, arità 1 e lo
stesso totale 0,033414 secondi. Il wrapper benchmark osservato prima/dopo
ha 198.507 byte e SHA256
`1154975a7c27c433d402c7b7549a62fb321b1e43fb806f5def86dd8825bfceb6`.
L'auditor controlla coerenza dei dati e inventario dichiarato; non prova
autenticità/esecuzione, chiusura dell'intero albero o corrispondenza
intrinseca MD5/Git senza attese esplicite del chiamante.

## Baseline e otto mutazioni: log completi

Letto `spikes/out/cbor-float-write-20261013/mutations/report.lisp` e,
tramite lo strumento fidato, ogni riga dei nove log fino a EOF. La
baseline ha 1.067 righe, 989 `ok` distinti, exit 0, RESULT OK e SIGNAL NIL.
La riga smoke della versione è esattamente la 2; il marker completo
`build e test: nessun avviso, tutti i controlli superati` è esattamente
la 1.067. Non presenta Unhandled o diagnostiche compilatore invalidanti.

Tutti gli otto mutanti hanno 208 `ok` distinti, smoke versione esatto alla
riga 2 e `Unhandled ` a inizio della riga 250, quindi nell'ordine
richiesto. Il marker completo è assente. Tutti hanno exit 1, SIGNAL NIL,
RESULT DETECTED, DETECTED T e DIAGNOSTIC NIL. Conteggio finale: otto
rilevati, zero sopravvissuti, zero invalidi e zero worker error. Il
controllo compatto finale è il transcript tool `4934bf`.

Il frame numerato riportato sotto contiene nello stesso frame il
namespace `ARCDOCDB.CBOR.FLOAT.WRITE.TESTS::` e REQ-CBR-004. Per tutti è
il test `TEST-REQ-CBR-004-FLOAT-WRITE-LITERAL-ZERO-INFINITY-FINITE-AND-NAN-VECTORS`.
Non sono semplici citazioni dei marker in una stringa di backtrace.

| Mutante / log sotto `mutations/` | Righe EOF | Frame REQ | Origine runtime osservata |
|---|---:|---:|---|
| omit-single-reduction / `0/test.log` | 320 | 7 | Capacity rifiutata per AI 26, LOW 3FC00000, END 3; writer frame 4 e CFW-ACCEPT frame 5. |
| omit-double-reduction / `1/test.log` | 320 | 7 | Capacity rifiutata per AI 27, HIGH 3FF80000, LOW 0, END 3; writer frame 4 e CFW-ACCEPT frame 5. |
| half-sign-lost / `2/test.log` | 322 | 9 | Invariant CBOR-FLOAT32-NARROW-SIGN, input 80000000 nel riduttore frame 4; writer frame 6. |
| half-normal-fraction / `3/test.log` | 320 | 6 | EQUALP sul buffer fallisce: 249 61 0 contro 249 62 0, CFW-ACCEPT frame 4, input single 3FC00000. |
| single-subnormal / `4/test.log` | 323 | 10 | Invariant CBOR-FLOAT64-NARROW-HIGH, shifter frame 4 con HIGH 1048576, LOW 0, shift 52; writer frame 7, input 36A00000/0. |
| physical-capacity / `5/test.log` | 319 | 6 | TYPEP della condizione fallisce in CFW-REJECT frame 4; input half 3E00, START=END=0, atteso RESOURCE-EXHAUSTED/CBOR-FLOAT-CAPACITY. |
| wrong-float-lead / `6/test.log` | 320 | 6 | EQUALP sul buffer fallisce: 217 62 0 contro 249 62 0, CFW-ACCEPT frame 4, input half 3E00. |
| extra-return-value / `7/test.log` | 319 | 6 | Arity (= 1 LENGTH ACTUAL) fallisce in CFW-ACCEPT frame 4, input half 3E00. |

Quando il controllo fallisce dopo il ritorno del writer, il suo frame
non è più presente. Nel caso physical-capacity il corpus ha già catturato
la condizione: il log prova la discrepanza TYPEP, non conserva direttamente
il motivo della condizione catturata. Il controllo statico della sola
sostituzione mostra che la capacità viene confrontata anche con la coda
fisica; con span zero la guardia successiva del target interviene prima
della scrittura. Questa è un'inferenza dalla copia, distinta dal testo
del log. Il test non viene mascherato da un successivo errore sulla
conservazione del buffer.

Non compaiono WARNING:, STYLE-WARNING:, COMPILE-FILE-ERROR,
COMPILE-FILE-WARNED o `compilation aborted` nei nove log. Nei mutanti
compare in coda `compilation unit aborted`, con una fatal ERROR condition,
dopo l'Unhandled runtime e il backtrace del corpus: è l'unwind dell'unità
ASDF esterna. L'origine degli otto rilevamenti è il controllo runtime
sopra identificato, non un avviso di compilazione.

## Coerenza delle copie e sostituzioni

Il mutatore distingue source-files, che copia ASD/build/src/tests,
da fingerprints, che aggiunge il driver senza copiarlo. Le impronte
before/after reali sono 281, uguali: 280 file copiati e il driver.
Le copie dichiarate hanno 165 sorgenti, 113 test, ASD e tools/build.lisp.
Il catalogo source-files dei bersagli contiene invece solo due sorgenti,
narrow e writer: non è l'inventario delle copie.

Sono stati confrontati tutti i 280 file di ciascuna delle nove copie
contro le impronte originali: 2.520 confronti. La baseline non differisce;
ogni mutante differisce soltanto nel suo SOURCE-FILE dichiarato. Per
ciascuno, il frammento BEFORE ricorre una sola volta nell'originale e
l'intero testo della copia è esattamente prefisso+AFTER+suffisso. Otto
sostituzioni esatte confermate nel transcript tool `7c73e0`.

Extra-return-value sostituisce coerentemente il frammento DECLAIM+DEFUN:
la sola copia dichiara il secondo NIL e restituisce NEXT,NIL. Non sono
state alterate configurazioni, sorgenti del corpus o politiche di warning.
Questa verifica riguarda l'inventario dichiarato di ASD/build/src/tests;
runner generato, FASL e log sono separati. Non è un'attestazione che nessun
altro file esista negli alberi o una prova atomica/autentica di esecuzione.

## Errori del lettore ad hoc, separati dalle campagne

Sei fallimenti degli estrattori sono dichiarati qui come osservazioni
parziali dei transcript tool. Nessuno ha caricato o chiamato il prodotto
o rieseguito una campagna. Non sono nuovi archivi completi stdout/stderr
né esiti dei record di processo OK elencati sopra.

| Transcript fallito, exit 1 | Errore dell'estrattore | Correzione e risultato |
|---|---|---|
| `c4785a` | Entry snapshot plist trattata come coppia: FIRST restituisce :PATH e SEARCH segnala TYPE-ERROR, :PATH non SEQUENCE. I conteggi precedenti erano già stati estratti. | GETF :PATH; lettura completata `629503`. |
| `bbee86` | Tentativo inline dell'oracolo razionale con parentesi mancante: INPUT-ERROR-IN-LOAD, EOF nel DEFUN da line 1/column 36; nessun ricalcolo effettuato. | Catalogo letterale freddo e ricalcolo aritmetico di tutti i 30 campioni `569ad7`; valutazione dei sei valori esposta sopra. |
| `d794b5` | SUBSEQ fino a 4 su catalogue-source-files di lunghezza 2: BOUNDING-INDICES-BAD-ERROR prima della lettura dei log. | Ispezione della struttura; `f9379c` legge tutti i nove log a EOF, stampa del tool troncata, e `5c7274` stampa le origini compatte degli otto. |
| `a4be07` | Parentesi chiusa in eccesso nella forma inline: SIMPLE-READER-ERROR prima della lettura dei log. | Heredoc bilanciato; lettura compatta `5c7274`. |
| `096bad` | L'inventario delle impronte è scambiato per quello copiato: FILE-DOES-NOT-EXIST sul driver intenzionalmente assente dalla copia baseline. | Lettura della definizione source-files/fingerprints; tutti i 2.520 confronti e otto sostituzioni esatte completati `7c73e0`. |
| `464495` | Usata la chiave :EXIT anziché :EXIT-CODE: NIL passato a confronto numerico dopo la lettura della baseline. | Ispezione dei campi `ec0d0f`; lettura a EOF e controlli di tutti i nove log completati `4934bf`. |

## Esito circoscritto

I dati dei record, il ricalcolo freddo del benchmark, gli otto errori
runtime e le copie sono coerenti con le attese dichiarate. Non emergono
difetti da questa lettura. L'autore del corpus controlla i propri risultati;
la separazione dal driver benchmark e dall'auditor vale per il ricalcolo
dei dati, non rende indipendente la lettura del corpus. La copertura e
la raccolta finale hanno revisori propri. Le otto mutazioni esercitano
gli otto difetti dichiarati; non misurano esaustività generale, MC/DC,
scaling o qualifiche dell'intero motore.
