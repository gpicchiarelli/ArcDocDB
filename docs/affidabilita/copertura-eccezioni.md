# Eccezioni alla copertura

Elenco delle righe di codice C1/C2 che la suite **non** può raggiungere, con motivazione e
verifica sostitutiva ([piano di verifica](piano-di-verifica.md#copertura)). Una riga non
raggiungibile senza motivo è un difetto di test o codice morto: va coperta o rimossa.

| Campo | Contenuto |
|---|---|
| ID | `COV-nnn`, stabile |
| Dove | modulo, funzione, riga |
| Perché non raggiungibile | ad esempio ramo difensivo su un invariante già garantito dal tipo |
| Verifica sostitutiva | ispezione, asserzione, test del modello |
| Approvazione | data |

## Eccezioni approvate

Nessuna eccezione è approvata. Le misure locali seguenti conservano il denominatore grezzo.


## Inventario locale delle decisioni multiserie

Misura iniziale del 2026-10-09: 935/1121 espressioni e 82/122 rami sui cinque
file `decisions-*`, con tutte le forme nel denominatore. Le 40 alternative
di ramo mancanti appartengono a 30 siti di segnalazione difensiva: una
condizione composta può registrare più alternative. Le letture dell'autore
e di un revisore indipendente sono conservate nel
[catalogo](../../spikes/results/2026-10-09-decisions-verifica/catalogo.lisp).

La successiva [variante radix](../implementazione/decisioni-radix-decisioni.md)
osserva 1.332/1.530 espressioni e 138/176 alternative sui sei file.
I test privati di forma coprono anche le negazioni prima mancanti di
COV-020, COV-029 e COV-030: le alternative mancanti dei cinque file
preesistenti scendono da 40 a 37. Il file radix aggiunge una alternativa
non osservata, per 38 complessive. Il controllo richiede una lunghezza
array non rappresentabile in u64, impossibile sul runtime esaminato con
`index` fixnum più stretto. L'inventario iniziale sotto è conservato come
storia della misura; l'inventario radix descrive guardie, forme dichiarative
e postcondizioni ancora mancanti. Nessuna eccezione viene approvata.

Queste sono motivazioni osservate e verifiche sostitutive locali; non sono
esclusioni approvate, copertura MC/DC o chiusura del gate C1. Il contratto
richiede input stabile e passaggio attraverso l'API pubblica; un bypass
che costruisca oggetti privati incoerenti è fuori da quel contratto.

| ID | Sorgente, funzione e riga | Controllo | Motivazione / verifica sostitutiva |
|---|---|---|---|
| COV-001 | [`decisions-build.lisp`](../../src/recovery/decisions-build.lisp), `decision-frame`, riga 26 | posizione prima della fine | Lo scanner conta cornici intere del prefisso. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-002 | [`decisions-build.lisp`](../../src/recovery/decisions-build.lisp), `decision-frame`, riga 30 | avanzamento, confine, chiave e flag | Cornice di controllo già validata; buffer stabile. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-003 | [`decisions-build.lisp`](../../src/recovery/decisions-build.lisp), `decision-frame`, riga 37 | span e misura del payload | Il codec garantisce span ordinati e consumo esatto. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-004 | [`decisions-build.lisp`](../../src/recovery/decisions-build.lisp), `decision-frame`, riga 41 | tipo DECISION o SEAL | Il log multiserie verificato ammette soltanto questi tipi. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-005 | [`decisions-build.lisp`](../../src/recovery/decisions-build.lisp), `preflight-decisions`, riga 53 | capienza del numero di cornici | Contatori prodotti dallo scanner; ogni cornice occupa almeno un header. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-006 | [`decisions-build.lisp`](../../src/recovery/decisions-build.lisp), `preflight-decisions`, riga 60 | misura dei partecipanti | Il codec ha verificato count e span di ID16. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-007 | [`decisions-build.lisp`](../../src/recovery/decisions-build.lisp), `preflight-decisions`, riga 68 | consumo del prefisso e numero di decisioni | Rilettura stabile delle stesse cornici contate dallo scanner. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-008 | [`decisions-build.lisp`](../../src/recovery/decisions-build.lisp), `decode-decisions`, riga 80 | count, frames e capienza | Scanner e preflight hanno fissato i conteggi. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-009 | [`decisions-build.lisp`](../../src/recovery/decisions-build.lisp), `decode-decisions`, riga 87 | capienza del vettore entry | Una entry per ogni DECISION contata dal preflight. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-010 | [`decisions-build.lisp`](../../src/recovery/decisions-build.lisp), `decode-decisions`, riga 99 | consumo, entry e partecipanti | Le copie non modificano il buffer e ripetono il preflight. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-011 | [`decisions-build.lisp`](../../src/recovery/decisions-build.lisp), `unique-decision-count`, riga 124 | ordine TXID | Il merge stabile precede la coalescenza. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-012 | [`decisions-build.lisp`](../../src/recovery/decisions-build.lisp), `unique-decision-count`, riga 133 | unici non oltre entry | Ogni iterazione incrementa al massimo una volta. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-013 | [`decisions-build.lisp`](../../src/recovery/decisions-build.lisp), `collapse-decisions`, riga 147 | capienza del risultato | Il conteggio degli unici ha letto lo stesso vettore privato. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-014 | [`decisions-build.lisp`](../../src/recovery/decisions-build.lisp), `collapse-decisions`, riga 151 | consumo del risultato | Ogni nuovo TXID produce esattamente una entry. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-015 | [`decisions-sort.lisp`](../../src/recovery/decisions-sort.lisp), `merge-id-runs`, riga 35 | misura, identità e multiplo di 16 | Workspace distinto della misura della copia privata di ID16. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-016 | [`decisions-sort.lisp`](../../src/recovery/decisions-sort.lisp), `merge-id-runs`, riga 38 | intervalli dei run | I confini sono calcolati con min sul count verificato. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-017 | [`decisions-sort.lisp`](../../src/recovery/decisions-sort.lisp), `merge-id-runs`, riga 48 | consumo di entrambi i run | Una copia e un avanzamento per right-left passi. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-018 | [`decisions-sort.lisp`](../../src/recovery/decisions-sort.lisp), `check-participant-order`, riga 58 | forma dei partecipanti | Count e copia provengono dallo stesso payload verificato. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-019 | [`decisions-sort.lisp`](../../src/recovery/decisions-sort.lisp), `check-participant-order`, riga 66 | ordine crescente | Il merge ordina tutti i16byte; duplicati sono invece un errore pubblico coperto. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-020 | [`decisions-sort.lisp`](../../src/recovery/decisions-sort.lisp), `sort-participants`, riga 75 | forma della copia | Il builder copia esattamente lo span verificato. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-021 | [`decisions-sort.lisp`](../../src/recovery/decisions-sort.lisp), `merge-entry-runs`, riga 95 | misura e identità dei vettori | Workspace distinto della stessa lunghezza del vettore entry. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-022 | [`decisions-sort.lisp`](../../src/recovery/decisions-sort.lisp), `merge-entry-runs`, riga 97 | intervalli dei run | I confini sono limitati dal numero di entry. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-023 | [`decisions-sort.lisp`](../../src/recovery/decisions-sort.lisp), `merge-entry-runs`, riga 108 | consumo dei run | Una entry e un avanzamento per right-left passi. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-024 | [`decisions-sort.lisp`](../../src/recovery/decisions-sort.lisp), `sort-entries`, riga 131 | ordine TXID | Merge stabile su tutte le passate fino alla lunghezza totale. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-025 | [`decisions-query.lisp`](../../src/recovery/decisions-query.lisp), `find-decision-index`, riga 22 | intervallo della ricerca | Middle è calcolato dentro il range semiaperto non vuoto. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-026 | [`decisions-query.lisp`](../../src/recovery/decisions-query.lisp), `find-decision-index`, riga 29 | limite dei passi | Il range si dimezza; integer-length(N) copre la ricerca. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-027 | [`decisions-query.lisp`](../../src/recovery/decisions-query.lisp), `participant-present-p`, riga 61 | risultato del confronto | compare-id16 restituisce soltanto -1,0,1 per contratto e implementazione. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-028 | [`decisions-query.lisp`](../../src/recovery/decisions-query.lisp), `participant-present-p`, riga 62 | limite dei passi | Il range si dimezza; integer-length(count) copre la ricerca. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-029 | [`decisions-types.lisp`](../../src/recovery/decisions-types.lisp), `check-entry-shape`, riga 32 | almeno due partecipanti | Il codec ha verificato la cardinalità prima della costruzione. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |
| COV-030 | [`decisions-types.lisp`](../../src/recovery/decisions-types.lisp), `check-entry-shape`, riga 34 | misura del vettore ID16 | Count e copia derivano dal medesimo span verificato. Ispezione delle due letture; oracoli su input arbitrari, cardinalità dispari e valori estremi. |

Le ulteriori 46 forme non marcate sono 30 forme dichiarative di package,
`in-package` e `declaim`, sei forme degli slot `defstruct` e dieci
inizializzatori `&key`. Questi ultimi sono raggiungibili e verificati dal
test pubblico `public-default-budgets-and-explicit-version`: restano
non marcati da `sb-cover` e non vengono presentati come invarianti
irraggiungibili. Le altre 140 espressioni mancanti appartengono alle
segnalazioni difensive e ai loro operandi. Nessuna forma viene sottratta
dalle 1121 espressioni o dai 122 rami pubblicati.

La [tabella dei predicati composti](../implementazione/decisioni-multiserie-decisioni.md)
collega le clausole pubbliche ai test e le guardie interne a questo inventario.
Le eccezioni degli altri moduli non sono inventariate da questa misura.
