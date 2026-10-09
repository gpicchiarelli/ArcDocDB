# Verifica dei segmenti compattati

`arcdocdb.storage.format:verifica-segmento-compattato` verifica il formato
dei segmenti CLOSED con origine compaction, già definito da
[ADR-0041](../adr/0041-multiserie-segmenti-autosufficienti.md) e dai
[formati su disco](../formati-su-disco.md#contenuto).
Il modulo non sceglie i record da conservare né esegue CLEAN/MERGE.

## Contratto

Argomenti: `buffer`, `valid-bytes`, `id-serie`, `segment-id`;
budget keyword `max-bytes` (default 64 MiB) e `max-records` (default 65.536).
Il buffer specializzato di byte inizia all'offset zero del file, resta stabile
durante la chiamata e contiene tutto il prefisso valido. Identità e lunghezza
valida sono fornite dalla fonte autorevole del segmento chiuso.

Si verifica l'header contro Serie e segment-id, si seleziona la versione 1/2
effettiva e si richiede origine compaction. Dall'offset 64 al limite valido
si verificano cornici contigue, CRC e soli PUT/TOMBSTONE ordinari. PUT con flag
contratto-versionato è ammesso; prepared, OUTCOME, SEAL, EDIT e DECISION sono
rifiutati. I CSN restano opachi: nessun ordine o positività viene imposto.

Solo al termine vengono restituiti cinque valori: fine del prefisso, versione,
numero di record, PUT e TOMBSTONE. I conteggi descrivono record fisici; non
attestano numero di chiavi distinte, visibilità o policy di conservazione.
Un segmento vuoto composto dal solo header è valido per il codec; spetta
al manifest decidere se un output vuoto debba essere registrato o rimosso.

La coda fisica dopo `valid-bytes` non viene letta. Il limite logico CLOSED
non viene spacciato per EOF fisico: questa API non usa la scansione dei lotti
e non restituisce TAIL. Un record incompleto nel prefisso dichiarato valido
è corruzione, senza conteggi parziali utilizzabili.

| Esito negativo | Condizione |
|---|---|
| Input incompleto per il prefisso, identità o budget del chiamante invalidi | `invalid-argument` |
| Segmento writer valido fornito al verificatore compaction | `invalid-argument`, `:compaction-origin` |
| Header, CRC, cornice, tipi o prepared non validi | `corruption-detected` |
| Versione ignota con header integro | `unsupported-format` |
| Budget byte/record superato | `resource-exhausted` |
| Mancato progresso o conteggi interni incoerenti | `invariant-violation` |

## Lavoro e proprietà

Il budget byte precede la scansione dei CRC; il budget record precede il
record successivo. Il ciclo ha un limite derivato dai byte del prefisso e
dalla cornice minima; ogni passo deve avanzare entro il limite valido.
Niente allocazioni dipendenti da lunghezze del file, copie di record, letture
u64 materializzate, attese o stato condiviso. Il chiamante mantiene i buffer
stabili; il verificatore non li modifica e non apre, tronca o elimina file.

> **Proposta** — I budget iniziali sono operativi e configurabili, distinti
> dal limite persistente del segmento (4 GiB meno un byte). Questa prima API
> richiede il prefisso in memoria; una scansione streaming resta da integrare.

## Verifica

[Metodo registrato prima delle campagne](segmenti-compattati-metodo.md).

| Decisione | Condizioni e prove |
|---|---|
| Configurazione valida (`and`) | Indice valido, limite 64..4 GiB−1 contenuto nel buffer, budget byte nello stesso intervallo, budget record indice, identità di 16 byte. Ogni limite invalido viene rifiutato prima dei CRC; fixture vuote ed esatte esercitano il successo. |
| Budget byte (`>`) | Limite esatto ammesso; un byte sotto il prefisso esaurisce il budget. |
| Origine (`=`) | Compaction ammessa; writer integro rifiutato; origine malformata resta errore dell'header. |
| Progresso (`and`) | `pos < next <= end`, garantito dal codec verificato. Troncamenti esercitano il codec; il rifiuto difensivo resta nel denominatore della copertura. |
| Tipo ordinario (`or`) | PUT e TOMBSTONE ammessi separatamente; SEAL, OUTCOME, EDIT e DECISION integri rifiutati. |
| Prepared (`logtest`) | PUT con flag 0/4 e TOMBSTONE ordinari; PUT con flag 1/5 e TOMBSTONE prepared rifiutati. |
| Fine e budget record | Fine esatta prima del budget, compreso il vuoto con budget 0; limite record esatto ammesso e 0/1 insufficienti rifiutati. |
| Conteggi (`and`, `if`) | PUT e TOMBSTONE incrementano contatori distinti; totale uguale alla somma e compatibile con le cornici minime. L'incoerenza interna resta ramo difensivo. |
| Risultato (`and`) | Fine uguale al limite autorevole e totale uguale alla somma. Conteggi dichiarati dalle fixture per vuoto, misti e prefissi sui confini; rifiuto difensivo senza simulare errori dei helper. |
| Limite del ciclo | Derivato dal numero massimo di cornici nel prefisso; l'esaurimento senza ritorno è una difesa interna, non una condizione di input raggiungibile. |

Le [evidenze conservate](../../spikes/results/2026-10-09-compaction/catalogo.lisp)
comprendono due letture C1, 15 test con fixture indipendenti, self-test degli
strumenti, comandi, ambiente, hash prima/dopo e output grezzi. Otto mutanti
compilabili sono rilevati dopo una baseline invariata riuscita. Il controllo
integrato viene registrato separatamente nel catalogo.

Il benchmark seriale osserva zero byte heap in tutte le 20 repliche:
versioni 1/2, header vuoto o 256 record alternati, cinque repliche di 4.096
chiamate per caso. Tutti i cinque valori restituiti alimentano un risultato
osservabile confrontato con un atteso esplicito. Il self-test osserva zero
heap nella baseline e almeno 16 MiB nel controllo positivo. La misura riguarda
queste fixture in memoria e non prova assenza assoluta di allocazioni o
prestazioni del motore completo.

### Inventario della copertura locale

La copertura grezza del modulo è 202/234 espressioni e 30/36 rami. Le sei
alternative mancanti sono gli esiti falsi dei tre `and` difensivi riportati
qui; i loro rifiuti non sono raggiungibili tramite l'API pubblica con buffer
stabile e codec corretto.

| Guardia, funzione e riga | Motivazione e verifica sostitutiva |
|---|---|
| `:compaction-progress`, `verifica-record-compattato`, 35–36 | Il codec restituisce la fine di una cornice completa dentro il range. Due letture e troncamento in ogni posizione; nessuna simulazione di un decoder incoerente. |
| `:compaction-count`, `scansiona-compattato`, 61–63 | Un incremento totale e uno del tipo per ogni cornice di almeno 24 byte. Oracoli di conteggi fisici e mutante che scambia PUT/TOMBSTONE. |
| `:compaction-loop-bound`, `scansiona-compattato`, 65 | Ogni passo consuma almeno una cornice minima; un controllo di fine precede il budget e il record successivo. Ispezione del limite del ciclo, fixture vuote e confini esatti. |
| `:compaction-result`, `verifica-segmento-compattato`, 87–88 | Lo scanner restituisce solo sulla fine esatta e conserva la somma dei contatori. Due letture, cinque valori verificati per ogni fixture e coda fisica ignorata. |

Le 32 espressioni non marcate sono sei forme dichiarative, 24 forme nelle
quattro segnalazioni difensive e due inizializzatori keyword. I default
sono esercitati dalle chiamate senza keyword delle fixture vuote e miste,
pur restando non marcati da `sb-cover`; non sono classificati come codice
irraggiungibile. Tutti i rami pubblici di argomenti, origine, tipi, prepared
e budget hanno entrambi gli esiti osservati.

Il denominatore resta completo: questo inventario è una motivazione locale,
non un'esclusione approvata, una qualifica MC/DC o la chiusura del gate C1.

Requisiti collegati: REQ-CMP-009, REQ-FOR-001/002/003, REQ-AFF-008.
Invarianti: INV-C1, INV-S7, INV-F1/F2, INV-A8/A9, INV-P6.
Il controllo del formato è una parte di quei requisiti: non verifica la scelta
dei record, il manifest, la pubblicazione atomica della compaction, la salute
del database o il recovery completo. Nessuno stato di requisito viene promosso.
