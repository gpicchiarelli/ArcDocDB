# Composizione degli array CBOR — prima lettura C1

Lettura statica del 2026-10-13, prima della compilazione dei nuovi sorgenti
e delle campagne. Il corpus è stato congelato prima della scrittura del
prodotto. Riferimenti: [metodo preregistrato](cbor-array-metodo.md),
[contratto](cbor-array.md), [inventario delle decisioni](cbor-array-decisioni.md),
[standard di codifica](../affidabilita/standard-di-codifica.md) e
ADR-0014/0024/0033/0035/0048. Questa lettura non misura allocazioni,
copertura, prestazioni o MC/DC e non chiude il gate C1.

## Versioni lette

| File | Git blob |
|---|---|
| `src/codec/cbor-array-input.lisp` | `d3b3d07fc18bd2a077c1a2d79020a76263b2779e` |
| `src/codec/cbor-array-write.lisp` | `a410297c29c5d043ad60d3804bd3711e22c2833b` |
| `docs/implementazione/cbor-array-metodo.md` | `2f257c9e8a56a5182142934dada3f3b38b5bef65` |
| `tests/codec/cbor-array-write-support.lisp` | `eb1fccadb205e375b4a2324a6b6725a860bb546f` |
| `tests/codec/cbor-array-write.lisp` | `b13f58264f3cd97e1947ee52936732a7fcebe672` |
| `tests/codec/cbor-array-write-threads.lisp` | `5720110265b67019937f08cbd949b4469a04b867` |

Letti anche gli helper di span/copia, testata, scratch, preflight e scanner
minimo esistenti, oltre a export, ordine ASDF, ambito coverage, requisito
e matrice. Le impronte delle dipendenze rilevanti sono:

| File in `src/codec/` | Git blob |
|---|---|
| `cbor-string-write.lisp` | `a2c5c77dd51bff760bff4508e998d94370921eda` |
| `cbor-write.lisp` | `61f0d6e2783e4790ed7e19a45bba6407d6e5b3de` |
| `cbor-space.lisp` | `a8330e50a77b52a6b9044ebbb48f62bb4b3222a3` |
| `cbor-scan-input.lisp` | `57ffc48cc688a4de8ebec5cb14c1e69c4209704a` |
| `cbor-scan.lisp` | `e3d7d77407046338d23e26eb0b8a2e8fdc3d699d` |
| `cbor-scan-minimal.lisp` | `f1afe79c7a4d49abd6a6e5f6975dec830ef7b1f6` |

L'autore del prodotto aveva già corretto, prima delle campagne, la guardia
`COUNT <= LENGTH(ITEM-ENDS) <= 16MiB`: limitava erroneamente anche la
coda ignorata della tabella. Le righe 46–49 di `cbor-array-write.lisp`
verificano separatamente COUNT contro la lunghezza e contro il limite;
nessun limite nuovo viene imposto alla coda. L'originale, blob
`b3135c8768199c23d58721ba528154461fdbda1e`, e la nota del rilievo restano
nelle prove preparatorie `spikes/out/cbor-array-write-20261013/precompile/`.
La presente lettura riguarda la versione corretta identificata sopra.

## Dimensioni, percorsi e guardie

Righe dalla DEFUN alla chiusura inclusa, con docstring e dichiarazioni.
Conteggio dei percorsi: base uno; un incremento per WHEN/UNLESS e LOOP;
un incremento per ogni operando AND/OR successivo al primo. I confronti
numerici concatenati sono predicati Lisp e vengono inventariati
separatamente. Il conteggio non è una misura della coverage SB-COVER.

| Funzione | File | Righe | Percorsi |
|---|---|---:|---:|
| `check-tabella-array-cbor` | input | 9–19: 11 | 7 |
| `check-spazio-array-cbor` | input | 24–34: 11 | 5 |
| `dimensioni-array-cbor` | input | 39–54: 16 | 4 |
| `check-overlap-array-cbor` | input | 59–70: 12 | 7 |
| `check-fini-array-cbor` | input | 75–93: 19 | 7 |
| `check-radice-array-cbor` | input | 97–105: 9 | 3 |
| `check-input-array-cbor` | input | 110–131: 22 | 3 |
| `verifica-figlio-array-cbor` | write | 10–32: 23 | 7 |
| `verifica-figli-array-cbor` | write | 38–64: 27 | 8 |
| `scrivi-array-cbor-minimo` | write | 70–105: 36 | 6 |

Tutte le funzioni restano entro COD-12/COD-13, hanno FTYPE completo,
docstring pre/post/errori e riferimenti REQ. Entrambi i file dichiarano
`safety 3`. Non ci sono COND/CASE nuovi cui applicare COD-15.
L'inventario contiene 36 siti WHEN/UNLESS, due LOOP, cinque AND/OR
con 14 operandi e otto confronti concatenati; nessun AND/OR è annidato.

COD-24: i validatori di tabella, spazio, dimensioni e radice hanno almeno
due controlli significativi di dominio; l'uscita normale attesta quelle
proprietà, senza produrre dati derivati non verificati. Questi controlli
segnalano errori pubblici e non sono tutti `invariant-violation`.
Overlap e fini aggiungono guardie interne su limiti fisici e budget;
il preflight confronta span e capacità restituiti dagli helper. La
scansione verifica intervalli, progresso, nodi e profondità effettivi;
il writer confronta risultati aggregati, cursore dopo la testata,
lunghezza da copiare e cursore finale. Sono relazioni fra valori e
confini, ulteriori rispetto al solo tipo INDEX/U32. Le guardie sono
sempre attive e non modificano dati; gli errori interni devono raggiungere
il confine fail-stop del proprietario della Serie.

## Ragionamento sul contratto

La sequenza del preflight alle righe 116–126 di input rispetta le undici
fasi preregistrate. Solo le prime COUNT entry vengono lette, alla fase 9;
nessun byte del payload viene parsato e lo scratch resta intatto fino
alla scansione. SPAN è verificato contro MAX-BYTES prima della somma e
del cast U32; COUNT è già limitato da SPAN. La capacità usa END-START,
non la lunghezza fisica della destinazione. L'overlap usa l'intero
`[START,NEXT)`, compresa la testata, prima di leggere le entry.

La tabella forma una partizione strettamente crescente che termina a
SPAN. Quindi `SOURCE-START + ITEM-ENDS[i]` non supera SOURCE-END e ogni
segmento è non vuoto. Il minimo `1+COUNT` precede il parsing. Nodi e picco
partono da uno per la radice; il residuo nodi viene controllato prima del
reset successivo. Residuo uno è passato allo scanner, residuo zero genera
`:cbor-array-node-budget` all'inizio assoluto del prossimo figlio.
MAX-DEPTH è almeno uno prima della sottrazione; lo scanner conta soltanto
array/map e il writer aggiunge il livello della radice. I tag aggiungono
nodi, senza aggiungere livelli di contenitore.

Tutti i figli sono verificati prima della prima emissione, riga 96 di
write. Testata MT4 e copia condivisa conservano i byte wire esatti:
non aggiungono ordinamento delle mappe, deduplica, semantica dei tag o
politiche NaN. La copia in avanti esistente è utilizzabile perché il
preflight ha provato la disgiunzione anche della testata; i suoi motivi
interni `:cbor-string-copy-*` restano applicabili. Con COUNT zero entrambi
i LOOP vengono saltati, lo scanner non viene chiamato e tutto lo scratch
resta intatto. A successo non vuoto lo scratch descrive l'ultimo figlio,
mentre le somme aggregate rimangono locali.

## Checklist C1 a dodici punti

1. **Requisiti e ADR.** REQ-CBR-005, REQ-LIM-001/002 e REQ-AFF-004/008
   sono indicati e coerenti con ADR-0014/0033/0035/0048. Il profilo locale
   minimo resta distinto dalle regole documentali superiori.
2. **Invarianti e test previsti.** INV-F1: testata fredda, payload letterale,
   un solo NEXT, array completi e sentinelle. INV-A8: limiti esatti byte,
   radice/nodi/tag e profondità 99/100 dei figli. INV-P6: sorgente/tabella
   stabili e destinazioni/scratch privati nei due worker riusati. I test
   di rifiuto confrontano tutti gli array; il preflight confronta anche
   lo scratch già sporco. La presenza dei test non equivale al loro PASS.
3. **Errori.** Tipi e motivi pubblici sono distinti e propagati senza
   catture: INVALID-ARGUMENT, RESOURCE-EXHAUSTED e CORRUPTION-DETECTED
   dello scanner. Il corpus contiene precedenze, offset NIL/assoluti,
   trailing, nonminimo, troncamento, UTF-8 e riuso dopo errore. I motivi
   interni sono elencati nell'inventario; non si presume un test runtime
   negativo per ogni guardia resa irraggiungibile dal dominio pubblico.
4. **Cicli e attese.** Due LOOP nuovi limitati da COUNT<=SPAN<=16MiB;
   copia limitata da SPAN, scanner e scratch fissi da 102 frame. Nessuna
   ricorsione, attesa, I/O o thread nuovo. Costo dichiarato
   `O(SPAN + COUNT*102)`, senza un conteggio esatto delle operazioni.
5. **Allocazioni.** La misura COD-30 rimane da eseguire con le sei fixture,
   baseline nulla e controllo positivo preregistrati. La lettura delle
   forme e dei tipi non dimostra heap zero, nemmeno nei casi limite.
6. **Dati verificati.** I valori esterni vengono validati prima dei cast,
   degli accessi alla tabella, del reset e della scrittura. Nessun AST o
   riferimento a buffer esce dal modulo: il risultato pubblico è NEXT.
7. **Decisioni composte.** L'inventario collega tutte le condizioni ai
   testimoni previsti e include guardie e relazioni concatenate. Coverage
   grezza e verifica condizione per condizione restano da produrre;
   nessuna esclusione dal denominatore o attestazione MC/DC.
8. **Proprietà.** OWNER/SHARED dichiarano destinazione e scratch esclusivi,
   sorgente e tabella stabili. I tre alias dello scratch sono rifiutati
   anche per array vuoto. Nessuno stato globale mutabile nuovo.
9. **Tracciabilità e check.** Export, ordine ASDF prodotto/corpus, RUN,
   requisito e matrice aggiornati sono coerenti staticamente. Lo scope
   coverage identifica esattamente i due nuovi file e il gruppo codec
   include il RUN array. `make check` e i self-test restano da eseguire.
10. **Regole e deviazioni.** Nessuna ulteriore deviazione statica richiesta
    per i blob letti; la guardia sul COUNT è stata corretta prima delle
    campagne. Compilazione, misure e copertura non sono anticipate.
11. **Parallelismo.** Il prodotto non introduce lock, attese o scritture
    condivise per operazione. Le prove preregistrate hanno due worker
    reali, due ondate e 8192 composizioni su risorse private; i risultati
    futuri non dimostreranno scaling o simultaneità sui core.
12. **Durabilità.** Nessuna pubblicazione, modifica durevole o eliminazione.
    Gli errori pubblici precedono la scrittura; guasti interni dopo
    l'emissione sono fail-stop senza rollback, come dichiarato.

Esito della prima lettura: nessun ulteriore difetto statico rilevato nei
due blob identificati. Rimangono necessarie la seconda lettura distinta,
le campagne preregistrate e le verifiche richieste dal gate C1.
