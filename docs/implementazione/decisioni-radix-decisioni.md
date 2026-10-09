# Decisioni e guardie dell'ordinamento radix

Inventario per COD-54 e per la seconda lettura C1 dell'ordinamento
[`decisions-radix.lisp`](../../src/recovery/decisions-radix.lisp), con i
[`test radix e concorrenti`](../../tests/recovery/decisions-radix.lisp).
La versione esaminata è identificata nella [revisione](decisioni-radix-revisione.md).
Il builder pubblico usa i due wrapper di selezione: merge per meno di
1.024 partecipanti e meno di 256 entry, radix alle soglie e oltre.
La selezione usa le cardinalità effettive, prima della coalescenza dei
record duplicati; non usa campioni né cambia i budget del recovery.

Si applicano lo [standard di codifica](../affidabilita/standard-di-codifica.md)
e il [piano di verifica](../affidabilita/piano-di-verifica.md). Questa tabella
descrive predicati, casi e argomenti di revisione; non attesta copertura
MC/DC o il raggiungimento dei criteri C1. Non contiene esclusioni approvate.
I conteggi grezzi sono distinti dalla copertura delle condizioni; le
guardie restano attive e nel denominatore.

## Invarianti di conteggio e dei prefissi

Per una passata, `N` è il numero effettivo degli elementi e `F[k]` è la
frequenza della cifra `k`, per `0 <= k < 256`. L'istogramma viene azzerato
e conta tutti gli elementi della sorgente corrente, senza campionamento.
Le celle hanno tipo u64; totale, posizioni e cardinalità usano `index`.
La cardinalità delle entry non è limitata al count u16 dei partecipanti.

Durante la verifica, `total` è la somma delle frequenze già lette e vale
`0 <= total <= N`. Prima di ogni incremento viene verificato
`F[k] <= N - total`: la somma successiva non può superare `N`. Al termine
si richiede `sum(F) = N`. Se la distribuzione serve, il secondo ciclo
produce il prefisso esclusivo `P[k] = sum(F[j], j < k)`. Ogni prefisso è
entro `0..N`; il cursore può raggiungere `N` dopo l'ultima scrittura.

Con zero o una classe occupata non occorre distribuire. Per `N > 0`, una
sola classe occupata contiene tutti gli elementi, perché la somma è già
stata verificata. La passata è quindi l'identità stabile. Il chiamante
salta sia scatter sia `rotatef`; lo scratch, eventualmente non scritto,
non diventa sorgente. Se tutte le passate sono uniformi, il risultato è
la sorgente iniziale. Un campione non può giustificare questo salto.

## Decisioni composte

Nel sorgente radix ci sono due predicati booleani composti espliciti. I
confronti concatenati e le decisioni semplici sono inventariati sotto.
I nomi dei test sono abbreviati omettendo il prefisso `test-REQ-…`.
I casi citati sono presenti nella versione esaminata; non costituiscono
una certificazione MC/DC delle guardie private.

| ID e sito | Clausole | Casi e stato della verifica |
|---|---|---|
| RAD-D01, `radix-scatter-ids`, righe 95–97 | `and`: lunghezza sorgente = `16 × count`; lunghezza target = lunghezza sorgente; sorgente e target distinti per `eq` | Tutte vere per scratch costruito dal sorter. `radix-scatter-invalid-arrays` nega separatamente misura sorgente tramite count errato, misura target e identità distinta; controlla sorgente, target e istogramma prima/dopo il rifiuto. Sono chiamate private deliberate. `radix-participant-shape-before-sort` prova inoltre misure incompatibili all'ingresso del sorter. |
| RAD-D02, `radix-scatter-entries`, righe 116–117 | `and`: lunghezze uguali; sorgente e target distinti per `eq` | Tutte vere per lo scratch privato. `radix-scatter-invalid-arrays` prova target più corto/più lungo con identità distinta e target coincidente con misura uguale, verificando assenza di modifica. |
| RAD-D03, query esistente `partecipante-decisione-p`, righe 76–78 di `decisions-query.lisp` | `and`: TXID trovato; ID16 presente nell'entry trovata | Il test `concurrent-immutable-table-queries` dichiara TXID assente, TXID presente con ID assente e TXID presente con ID esatto. Il secondo operando non viene valutato se il TXID manca. Il controllo del range e dello span 16 resta precedente alla ricerca, come descritto nell'[inventario della tabella](decisioni-multiserie-decisioni.md). |

## Guardie locali del radix

Sono elencati i 17 siti locali che segnalano `invariant-violation`.
`index`, u16, u64 e i tipi degli array sono inoltre precondizioni
controllate dal runtime con `safety 3`. I controlli delegati a
`check-entry-shape`, `copy-id16` e `check-participant-order` mantengono
il contratto del modulo preesistente e non sono ricontati come siti nuovi.

| ID, funzione e riga | Predicato e conseguenza | Invariante e casi pertinenti |
|---|---|---|
| RAD-G01, `radix-prefix-starts`, 23 | `frequency <= count - total`; altrimenti `decision-radix-count` | Impedisce di superare N durante la somma. `radix-prefix-invalid-total` prova eccesso nella prima classe e dopo una somma parziale. `radix-entry-65536-bucket-counts` comprende una classe con 65.536 elementi e una dominante con outlier. |
| RAD-G02, `radix-prefix-starts`, 27 | `total = count`; altrimenti `decision-radix-consumption` | Verifica la somma prima di usare prefissi o saltare la passata. `radix-prefix-invalid-total` prova frequenza insufficiente e istogramma invariato al rifiuto. |
| RAD-G03, `radix-id-starts`, 45 | `length(source) = 16 × count`; altrimenti `decision-participant-size` | `radix-scatter-invalid-arrays` chiama anche questa funzione con count incompatibile. Misure errate provate inoltre all'ingresso del sorter; cardinalità 0/1 sono casi privati, non DECISION pubbliche valide. |
| RAD-G04, `radix-id-starts`, 47 | `digit < 16`; altrimenti `decision-radix-digit` | `digit` è non negativo per tipo `index`; il sorter lo genera come `15 - pass`. `radix-invalid-digit-before-access` prova 16, 17 e massimo fixnum, mantenendo l'istogramma invariato. Ogni byte e bit è confrontato con l'oracolo. |
| RAD-G05, `radix-entry-starts`, 61 | `digit < 8`; altrimenti `decision-radix-digit` | Il sorter usa `dotimes` con limite 8. `radix-invalid-digit-before-access` prova 8, 9 e massimo fixnum; i 64 bit del TXID sono provati in entrambi gli ordini di ingresso. |
| RAD-G06, `radix-entry-starts`, 63 | lunghezza sorgente di tipo u64; altrimenti `decision-radix-count` | Evita cardinalità non rappresentabili nelle celle u64. Sul runtime con `index` fixnum più stretto di u64, il caso contrario è già escluso dai limiti degli array. |
| RAD-G07, `radix-check-cursors`, 81 | `previous <= cursor <= count`; altrimenti `decision-radix-position` | Due limiti distinti: monotonia degli estremi delle classi e limite superiore N. `radix-invalid-final-cursors` nega separatamente monotonia e limite superiore. Cursori non negativi per tipo u64. |
| RAD-G08, `radix-check-cursors`, 84 | ultimo cursore = N; altrimenti `decision-radix-consumption` | `radix-invalid-final-cursors` prova estremi monotoni entro N che terminano prima di N. `radix-scatter-invalid-cursors` prova inoltre prefissi deliberatamente sovrapposti nei due scatter. Non è un controllo esatto delle frequenze consumate per ciascuna classe. |
| RAD-G09, `radix-scatter-ids`, 95 | RAD-D01; altrimenti `decision-radix-arrays` | Misura, uguaglianza delle capienze e assenza di alias prima delle scritture. |
| RAD-G10, `radix-scatter-ids`, 98 | `digit < 16`; altrimenti `decision-radix-digit` | `radix-invalid-digit-before-access` verifica rifiuto prima di modificare target e istogramma. Lo scatter usa la stessa cifra dei prefissi. |
| RAD-G11, `radix-scatter-ids`, 103 | `position < count`; altrimenti `decision-radix-position` | Cursore non negativo; cast a `index` solo dopo il limite. `radix-scatter-invalid-cursors` pone il primo cursore a N e verifica rifiuto prima di scrivere. |
| RAD-G12, `radix-scatter-entries`, 116 | RAD-D02; altrimenti `decision-radix-arrays` | Vettori privati distinti della stessa misura, senza alterare i campi delle entry. |
| RAD-G13, `radix-scatter-entries`, 118 | `digit < 8`; altrimenti `decision-radix-digit` | `radix-invalid-digit-before-access` prova cifre oltre il TXID u64 prima di modificare target e istogramma. |
| RAD-G14, `radix-scatter-entries`, 124 | `position < length(source)`; altrimenti `decision-radix-position` | `radix-scatter-invalid-cursors` verifica rifiuto di cursore N prima dello store. Il test a 65.536 elementi verifica anche un cursore finale oltre u16. |
| RAD-G15, `radix-sort-participants`, 138 | `length(participants) = 16 × count`; altrimenti `decision-participant-size` | Verifica precedente all'allocazione dello scratch e alla prima lettura per cifra. Casi negativi in `radix-participant-shape-before-sort`. |
| RAD-G16, `radix-sort-entries`, 161 | ogni elemento è `decision-entry`; altrimenti `decision-entry-shape` | `radix-entry-invalid-object-before-slot-access` prova NIL, intero e vettore. `check-entry-shape` verifica poi count minimo e misura, negati in `radix-entry-shape-before-sort`. |
| RAD-G17, `radix-sort-entries`, 171–174 | TXID adiacenti non decrescenti; altrimenti `decision-entry-order` | Postcondizione di ordinamento. Identità e stabilità sono confrontate separatamente con `CL:STABLE-SORT`, anche con TXID ripetuti. |

Le negazioni delle guardie di istogramma, cifra, alias e cursore non sono
input del builder pubblico: il sorter produce quelle strutture dopo
preflight e copie private. I test le chiamano deliberatamente attraverso
confini privati, senza indebolire i tipi del prodotto. RAD-G06 dipende
dai limiti rappresentabili del runtime; RAD-G17 resta una postcondizione
che intercetta difetti dell'algoritmo. Eventuali rami non osservati vanno
motivati con la misura finale, mantenendo i totali grezzi.

## Selezione e collegamento al builder

I wrapper aggiungono soltanto due decisioni semplici `if`; nessun nuovo
predicato composto, budget o gestore di errore.

| ID e sito | Decisione | Casi pubblici |
|---|---|---|
| RAD-S01, `sort-recovery-participants`, 192 | `count < 1024`: merge se vero, radix altrimenti | `public-participant-sort-threshold-boundaries`: 1.023, 1.024 e 1.025 ID16, tre pattern, versioni 1/2, duplicati di record con set permutato, log invariato e tabella confrontata con l'oracolo. |
| RAD-S02, `sort-recovery-entries`, 204 | `length(entries) < 256`: merge se vero, radix altrimenti | `public-entry-sort-threshold-boundaries`: 255, 256 e 257 entry, ordine inverso e permutato, versioni 1/2, TXID zero/massimo e query contro l'oracolo. Gli stessi conteggi fisici sono provati con duplicati coerenti che producono un solo TXID dopo coalescenza. |

`decode-decisions`, riga 95 di `decisions-build.lisp`, passa la copia dei
partecipanti e l'offset fisico al primo wrapper. `ricostruisci-decisioni`,
riga 190, passa le entry al secondo wrapper prima di `collapse-decisions`.
Il resto del builder mantiene scanner completo, budget fisici comprensivi
dei duplicati, preflight e copia prima degli ordinamenti. Nessun errore
viene riclassificato come assenza, coda o presumed abort.

`public-radix-first-physical-conflict-across-groups` costruisce più di
256 record e pone il primo conflitto fisico nel gruppo TXID massimo,
prima del conflitto del gruppo TXID zero. L'API deve segnalare il minimo
offset fisico globale, in entrambe le versioni e in due ricostruzioni,
con sorgente invariata. Il ramo radix viene raggiunto senza modificare
la soglia per il test.

## Distribuzione stabile e controlli delegati

Lo scatter visita `i = 0..N-1` in ordine crescente. Per la cifra `k`, il
cursore parte da `P[k]` e cresce di uno a ogni elemento di quella classe:
gli elementi con cifra uguale mantengono l'ordine della sorgente. Dopo N
iterazioni, ogni classe ha cursore `P[k] + F[k]`. Questa proprietà deriva
dal conteggio completo, dai prefissi validati e da un incremento per
elemento; `radix-check-cursors` verifica monotonia e termine totale, senza
conservare una seconda copia delle frequenze per confrontarle a fine
passata. Il controllo finale non è presentato come prova autonoma contro
qualsiasi possibile difetto futuro dello scatter.

TXID usa cifre da meno a più significative, con `ldb` su u64 e nessun
riordino del segno. ID16 usa byte da posizione 15 a 0. Ogni passata
stabile conserva il risultato delle precedenti; TXID uguali conservano
l'ordine fisico originario. Nessun confronto usa CSN, partecipanti o
offset come chiave secondaria. La coalescenza può quindi continuare a
usare il primo record fisico del gruppo. L'oracolo confronta l'identità
delle entry, oltre ai TXID ordinati.

`check-participant-order` mantiene il controllo di misura, l'ordine
strettamente crescente e la corruzione tipizzata per ID ripetuto con
offset del record. I test cambiano ciascuno dei 128 bit, provano
cardinalità fino a 65.535 e verificano l'offset dei duplicati, compreso
u64 massimo. Non si modifica il trattamento del danno persistente dello
scanner.

## Decisioni della fixture concorrente

Questi controlli appartengono all'harness, non introducono attese o
thread per richiesta nel prodotto. La query preesistente legge soltanto
campi e vettori posseduti dalla tabella completa.

| Controllo | Casi e rilevamento |
|---|---|
| Oracolo di stabilità: `and` su `i > 0` e TXID adiacenti uguali | Primo elemento, nuovo TXID e TXID ripetuto; solo nell'ultimo caso si richiede offset fisico crescente. L'oracolo principale confronta comunque ogni riferimento con `eq`. |
| Presenza e valori scalari | I probe dichiarano found, CSN, count e membership. CSN zero è presente con found vero; assenza restituisce found falso e valori zero. TXID zero/massimo e gap sono inclusi. |
| `if` di membership | Partecipante presente e assente per ogni TXID presente; TXID mancanti con risposta falsa. Ogni worker copia l'ID in un proprio buffer e interroga lo span non allineato `[3,19)`. |
| Avvio coordinato | Sei thread segnalano ready e attendono release con timeout di 10 secondi. Il thread principale attende ogni ready con lo stesso limite; il cleanup rilascia i thread anche se la preparazione fallisce. |
| Errore nel worker | Il gestore restituisce la condizione al chiamante del join; non converte l'errore in `t`. |
| Join | `join-thread` ha timeout di 10 secondi e default `:join-failed`; il test richiede che tutti i ritorni siano precisamente `t` e che nessun thread risulti vivo. Timeout, condizione o terminazione anomala non soddisfano il controllo. |
| Output e ownership | Output distinti per identità, confronto integrale con l'oracolo, tabella ricontrollata dopo i join. Il log sorgente è sovrascritto prima di creare i thread e confrontato dopo le query. |

Ogni worker esegue 64 round su una lista finita di probe. Semafori e
join sono barriere della fixture: non fanno parte dei task del motore
e non dimostrano un nuovo protocollo di parcheggio. I thread reali
esercitano lettori concorrenti; non esplorano esaustivamente gli
interleaving e non qualificano scalabilità, zero heap o schedulazione
deterministica. La tabella è costruita prima di `make-thread` e passata
nelle closure; il test non prova la pubblicazione attraverso un futuro
catalogo globale del runtime.

## Residui della copertura radix

La misura sul clone congelato riporta radix 384/409 espressioni e
53/54 alternative di ramo; i sei sorgenti DECISION complessivi
riportano 1.332/1.530 e 138/176. Questo inventario dettaglia soltanto
i residui del nuovo radix. I test coprono inoltre tre guardie prima
non osservate nei sorgenti preesistenti: count e misura di
`check-entry-shape` e misura di `sort-participants`. Le 25 espressioni
mancanti del radix sono 16 forme
top-level/package/declarative, una sottoforma del tipo histogram e
otto forme di errore divise fra RAD-G06 e RAD-G17.

La sola alternativa mancante è la negazione di RAD-G06: una lunghezza
array non u64 non è rappresentabile entro il più stretto limite
fixnum/array del runtime in uso. RAD-G17 è il rifiuto di un ordine
finale errato, possibile in presenza di un difetto interno del sorter;
le sue quattro forme di errore restano assenti, senza un'ulteriore
alternativa mancante nel conteggio di `sb-cover`. Le negazioni degli
altri controlli privati citati sono ora provate, quindi non vengono
motivate come casi assenti dal test.

I totali grezzi non sottraggono queste forme o l'alternativa. Nessuna
eccezione approvata o copertura MC/DC è dichiarata. Fonte della lettura:
stato grezzo `spikes/out/decisions-radix-coverage-final/coverage-state.lisp`
nella copia finale; hash e delimitazione sono nella revisione.

## Evidenze finali da collegare

Il diff e la selezione misurata sono descritti nella revisione. I test
pubblici dei confini e del conflitto globale sono presenti, insieme alla
matrice preesistente di budget e duplicati. Copertura grezza, mutanti,
compilazione, lint e controllo complessivo devono riferirsi agli stessi
hash congelati. Questa tabella inventaria i casi e i residui grezzi;
gli esiti eseguibili finali restano nei rispettivi registri, senza
trasformarli in copertura MC/DC o approvazioni.
