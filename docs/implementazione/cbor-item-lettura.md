# Primo item CBOR minimo — seconda lettura C1

2026-10-15. Lettura statica indipendente precedente alla prima
compilazione, senza LOAD, esecuzione del prodotto o campagne.
Nessuna nota dell'altra lettura C1 è stata consultata; l'inventario
è stato ricavato direttamente dalle fonti.
Esito locale: nessun difetto concreto rilevato; le verifiche dinamiche
e la qualifica C1/MC/DC restano aperte.

## Perimetro immutabile letto

| Unità | Git blob |
|---|---|
| `src/codec/cbor-item-read.lisp` | `b9099dc8a8c96281063811e686deb4dcb2b1d39b` |
| `arcdocdb.asd` | `8e36893806e499946cbffcc2c8475690ea40cba0` |
| `src/codec/cbor-package.lisp` | `64b3a838f6d5b432148e64604d5e1dfa4a3c32d4` |
| `tests/codec/cbor-item-read-support.lisp` | `0326100362a1c4b24d2c7e511e45357f09a56d33` |
| `tests/codec/cbor-item-read.lisp` | `b2cbdcb4255c51d9da4fe73b28939c1cb923fefe` |
| `tests/codec/cbor-item-read-threads.lisp` | `a0da65545ed80ede0a967cadbb337731f6fe1ce9` |
| `docs/implementazione/cbor-item-metodo.md` | `a67a79bf4fefe11c4778cd881eb5279a006966ca` |
| `tools/foundation-coverage.lisp` | `19369e3ea8f944a420efa1918383c7ac28544c6d` |

HEAD osservato `03dbc4e2`. Il corpus è quello congelato prima del
kernel. Sono stati letti direttamente anche preflight, spazio, header,
minimalità, stack, passo e risultato riusati; nessuna modifica locale
a tali moduli risulta nel diff. Non sono stati letti driver benchmark,
audit o mutazione in preparazione.

## Contratto e riuso

REQ-CBR-008 (`docs/tracciabilita/requisiti.lisp:321–324`) e
[ADR-0014](../adr/0014-formato-record-documento-id.md), precisata da
[ADR-0048](../adr/0048-limiti-documentali-e-formato-v2.md), sostengono
la primitiva strutturale. Non ne segue un profilo documentale
deterministico, né semantica dei tag o unicità/ordine delle mappe.
REQ-LIM-001/002 rimangono progettati per il contratto documentale
complessivo; i limiti locali del kernel non li qualificano integralmente.

Il preflight della riga20 riusa `cbor-scan-input.lisp:22–38` prima
del reset28: buffer/range, workspace, alias KINDS, configurazioni
byte/nodi/depth, poi budget dell'intera finestra. Non legge byte e
non modifica scratch sui rifiuti. Una coda oltre MAX-BYTES viene
quindi rifiutata anche se il primo item è uno scalare di un byte.

Entrambi i drain, righe30 e32, ricevono END uguale al cursore corrente:
soddisfano la precondizione di `cbor-scan-stack.lisp:89–107` e
permettono a `esito-radice-cbor` di controllare root/depth/tag senza
chiedere EOF fisico. Il passo31 conserva invece END originale e
MINIMAL=T (`cbor-scan.lisp:10–31`); header, payload e UTF8 restano
limitati alla finestra autorizzata. Il drain successivo all'ultimo
passo è presente anche quando LOOP esaurisce SPAN.

Se la root resta incompleta, le righe33–36 richiedono cursore=END e
invocano l'header vuoto per il medesimo :cbor-truncated a END, senza
restituire valori parziali. Dopo drain positivo, NEXT viene verificato
crescente e nella finestra; `risultato-struttura-cbor` riceve NEXT,
verifica conteggi e stato inattivo (`cbor-scan.lisp:36–47`) e restituisce
esattamente tre valori. La coda non è letta o inclusa nei conteggi.
I casi 00 FF e 81 00 1C producono rispettivamente 1,0,1 e 2,1,2 per
ispezione del flusso; non sono risultati di un'esecuzione in questa lettura.
Gli scanner esatti conservano i loro drain su END fisico e :cbor-trailing.

## Inventario completo del nuovo controllo di flusso

Una DEFUN, righe 10–43 incluse: 34 righe fisiche, anche docstring e
dichiarazioni; FTYPE completo alle righe8–9; safety3 alla riga5.
Conteggio conservativo: base 1 + 6 predicati espliciti + 1 LOOP = 8
percorsi indipendenti, entro60 righe/10 percorsi. Non si espandono
le decisioni dei callee già esistenti nel conteggio del nuovo wrapper.

| Decisione | Riga | Condizione e due esiti |
|---|---:|---|
| D1 | 22 | SPAN entro massimo; prosegue oppure invariant-violation |
| D2 | 29 | LOOP REPEAT SPAN: iterazione disponibile oppure termine |
| D3 | 30 | drain: root conclusa e RETURN oppure passo sull'item |
| D4 | 32 | drain finale: risultato oppure percorso incompleto |
| D5 | 33 | cursore=END nel percorso incompleto oppure invariant-violation |
| D6 | 39 | BEGIN<NEXT oppure invariant-violation |
| D7 | 41 | NEXT<=LIMIT oppure invariant-violation |

AND/OR nel nuovo sorgente:0, quindi0 operandi di cortocircuito.
Catene numeriche con almeno tre operandi:0. Tutti i confronti
numerici espliciti sono quattro confronti binari: `<=` riga22,
`=` riga33, `<` riga39, `<=` riga41. LOOP aggiunge la propria
decisione di controllo, senza introdurre una catena numerica nel testo.

Tutti i cinque bracci ERROR diretti sono condizioni
INVARIANT-VIOLATION, attive senza ASSERT rimovibili o side effect
nelle condizioni:

| Guardia/reason | Riga ERROR | Significato e limite della lettura |
|---|---:|---|
| `:cbor-item-loop-span` | 23 | difende il tetto del ciclo dopo preflight |
| `:cbor-item-loop-bound` | 34 | difende l'esaurimento a END se manca la root |
| `:cbor-item-empty-header` | 36 | fail-stop se l'header vuoto ritorna inaspettatamente |
| `:cbor-item-read-progress` | 40 | difende NEXT strettamente successivo a START |
| `:cbor-item-read-range` | 42 | difende NEXT entro END originale |

I primi due e gli ultimi due controllano contratti dei callee; il
terzo è il fallback del callee che deve segnalare troncamento. Con
callee corretti non si attende di raggiungerne i bracci ERROR da input
esterni validamente preflightati. Questo argomento statico non è
un'esclusione di copertura: tutti rimangono nei denominatori grezzi;
eventuali missed dovranno essere riportati e classificati integralmente.

## Errori e prove fredde disponibili

Il wrapper propaga, senza handler, INVALID-ARGUMENT per range,
workspace, alias e configurazioni; RESOURCE-EXHAUSTED per budget
byte/nodi/depth; CORRUPTION-DETECTED per sintassi, troncamento,
minimalità e UTF8 con offset assoluti; INVARIANT-VIOLATION dei
cinque bracci elencati e dei callee invariati. Non introduce motivi
di rifiuto esterni o inversioni di precedenza. La condizione di
invariante resta destinata al fail-stop del proprietario della Serie;
qui non esiste ancora integrazione con uno stato Serie.

Il corpus contiene16 test seriali e1 test con worker, non eseguiti
da questo revisore. `cir-accept` controlla arità3, valori, intero buffer,
cursore e stato scratch; `cir-cold-reject` conserva anche scratch sporco
(`cbor-item-read-support.lisp:43–78`). I test seriali coprono MT0..7
e code velenose4–12, frontiere concatenate24–41, END fisico/autorizzato
43–49, tipi/range51–64, workspace/alias66–71, precedenze73–86,
budget finestra88–94, nodi/tag96–108, depth100/101 a110–121,
errori assoluti/minimalità123–137, tutti i troncamenti139–146,
precedenza header148–157, riuso159–165,16MiB/+1 a167–176 e
fuzz1024 con seed/distribuzione congelati178–209.
I cinque errori interni non sono qui dichiarati esercitati dai test.

## Lista di controllo C1 a dodici punti

| Punto | Esito statico e gate ancora aperto |
|---:|---|
| 1 | REQ-CBR-008 e ADR0014/0048 coerenti con scope e API; annotazioni REQ presenti. |
| 2 | INV-A5: tracciabilità; INV-A8: budget/limiti; INV-P6: proprietà privata. Test freddi di rifiuto, immutabilità e due worker sono presenti; esiti ancora da acquisire. INV-A3/A4 restano rispettati tramite safety3 e condizioni tipizzate. |
| 3 | Tutte le cinque guardie dirette sono inventariate; famiglie propagate e precedenze sopra. Nessun errore ignorato o convertito in successo; misura della copertura/efficacia dei detector pendente. |
| 4 | LOOP al più SPAN<=16777216 passi. Ogni passo consuma almeno un byte; ciascun drain è limitato a102 frame, reset a102 slot, niente ricorsione/attesa nuova. |
| 5 | Nessuna costruzione AST, copia, cons, array o closure nel nuovo percorso caldo. Zero heap richiede benchmark con baseline e positivo: non misurato qui. |
| 6 | Risultato solo dopo root conclusa, progress/range e verifica integrale del risultato; nessun payload decodificato o risultato parziale esportato. |
| 7 | Inventario sopra:6 predicati,1 LOOP,0 AND/OR,4 confronti binari,0 catene. Copertura senza esclusioni ancora da raccogliere. |
| 8 | OWNER/SHARED righe2–3: buffer stabile condivisibile in lettura, scratch esclusivo per worker; nessun globale mutabile nuovo. |
| 9 | ASDF seriale registra kernel dopo dipendenze alla riga 36, corpus alle 171–172 e RUN aggregato alla 246; package esporta API alla 13. REQ-CBR-008 è implementato e compare nella matrice 103; build, trace/lint e make check finali non attestati da questa lettura. |
| 10 | FTYPE, docstring PRE/POST/errori, safety3 e limiti60/10 presenti; nessuna deviazione richiesta dalla lettura. COD-01 richiede ancora compilazione senza warning/style-warning. |
| 11 | Nessun thread, lock, I/O, attesa o scrittura condivisa per operazione nel kernel. Test worker con scratch distinti e buffer condiviso esiste; il rendezvous non dimostra scaling né simultaneità sui core. |
| 12 | Nessuna modifica durevole o eliminazione introdotta: punto di atomicità storage non applicabile alla primitiva in memoria. |

La riga di matrice è stata osservata già aggiornata, senza eseguire
il generatore. REQ e matrice osservati: rispettivamente
`f24c47fda225ed8420a77b467a36f83a3bb3a871` e
`0ed6c9c6b9a3c3046ed06c73eac18e2f05f1a021`.
Le successive prove e decisioni vanno conservate separatamente;
questa seconda lettura resta la fotografia anteriore alla compilazione.
