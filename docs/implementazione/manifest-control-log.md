# Manifest ricostruito dal control log

Il modulo `arcdocdb.recovery.manifest` ripiega in memoria gli EDIT del
prefisso verificato di `control.log`, secondo
[ADR-0040](../adr/0040-manifest-a-record-unico.md). Prepara la fonte di
verità per l'inventario di una Serie: ACTIVE, CLOSED con lunghezza valida
ed esiti di chiusura, segmenti rimossi e limite degli identificativi.

## Contratto

`ricostruisci-manifest` riceve buffer stabile, intervallo dei record,
versione esplicita, `file-offset` e `file-size` autorevole. Identità della
Serie e intestazione sono verificate dal chiamante. L'intervallo termina
all'EOF fisico, secondo il contratto della [scansione](scansione-log.md).
Restituisce manifest posseduto, fine del prefisso nel buffer e stato
`:complete` oppure `:tail`.

Prima verifica l'intero log e cerca un eventuale testimone durevole oltre
la coda. Poi verifica payload e budget degli EDIT nel prefisso e li
applica in ordine fisico. Un errore non restituisce uno stato parziale.
Un errore semantico dentro il prefisso con cornici e SEAL verificati non
diventa una coda. Una cornice troppo corta resta soggetta alla
classificazione dello scanner.

Il primo EDIT deve essere completo, con ACTIVE nonzero e `next-id`
nonzero superiore a tutti gli ID nominati. Un log vuoto o un primo lotto
incompleto non fornisce un manifest utilizzabile. Gli EDIT successivi
sono differenziali; `open = 0` conserva l'ACTIVE.

| Query | Risultato |
|---|---|
| `segmento-attivo(manifest)` | ID u64 dell'ACTIVE |
| `prossimo-id-segmento(manifest)` | presenza esplicita e ID u64; `nil, 0` se lo spazio è esaurito |
| `numero-segmenti-chiusi(manifest)` | numero di CLOSED distinti |
| `numero-segmenti-rimossi(manifest)` | numero di rimossi distinti |
| `trova-segmento(manifest, id)` | `:active`, `:closed`, `:removed` o `:unknown`; lunghezza valida e numero di esiti, entrambi zero fuori da CLOSED |
| `trova-esito-chiusura(manifest, id, txid)` | presenza esplicita e CSN, incluso zero; `nil, 0` dopo la rimozione del segmento |

Le query restituiscono soltanto scalari. Il risultato possiede i dati e
non conserva span nel buffer; il chiamante può riusarlo dopo il ritorno.
ACTIVE, CLOSED e rimossi sono disgiunti. Un ID sconosciuto resta diverso
da un ID esplicitamente rimosso: l'assenza non è una prova di eliminazione.

Argomenti fuori dai tipi dichiarati segnalano `TYPE-ERROR` con `safety 3`.
Configurazioni, corruzione, risorse esaurite e incoerenze interne usano
le condizioni tipizzate del modulo, con l'offset descritto dal contratto.

## Applicabilità e duplicati

> **Proposta — contratto applicativo locale.** I controlli seguenti rendono
> esplicita l'interpretazione conservativa del ripiegamento; i codec
> esistenti verificano la struttura, senza decidere queste transizioni.

Le sezioni `open`, `closed` e `removed` di un EDIT sono disgiunte. Una
rotazione chiude il vecchio ACTIVE e apre quello nuovo nello stesso
EDIT. Chiudere l'ACTIVE senza sostituirlo, oppure sostituirlo senza
chiuderlo, è un errore. Un nuovo CLOSED può essere un output di
compaction precedentemente sconosciuto. Un CLOSED o un rimosso non può
diventare nuovamente ACTIVE.

Ripetizioni identiche sono idempotenti: CLOSED con stessa lunghezza e
stesso insieme TXID/CSN; esito ripetuto con stesso CSN; rimozione già
registrata; `open` che ripete l'ACTIVE corrente. Lunghezze o esiti
discordanti sono corruzione. Rimuovere un ACTIVE o un ID sconosciuto è
un errore. I duplicati consumano comunque i budget fisici.

Gli EDIT nello stesso lotto possono condividere lo stamp. L'ordine di
pubblicazione degli ID non deve essere crescente: un worker può
prenotare l'ID di compaction e pubblicarne l'EDIT dopo una rotazione.
Il limite è il massimo fra `next-id` del completo iniziale e uno più il
massimo ID osservato; non diminuisce con le rimozioni. L'introduzione di
u64 massimo esaurisce lo spazio, rappresentato soltanto in memoria dalla
query senza prossimo ID. Il formato persistente non cambia.

Il manifest rileva il riuso degli ID ancora presenti fra CLOSED e
rimossi. Non può distinguere una prenotazione legittima da un riuso
storico di un ID ormai assente dal checkpoint: quella garanzia resta
responsabilità dell'allocatore del writer. Il limite numerico da solo
non dimostra il riuso.

## Budget e parallelismo

> **Proposta — budget configurabili.** 65.536 EDIT, 65.536 menzioni di
> segmenti e 65.536 esiti cumulativi; 65.536 CLOSED, rimossi ed esiti per
> EDIT; 16 MiB per payload. I budget della scansione restano separati.

Le menzioni comprendono ogni CLOSED, ogni rimosso e ogni `open` nonzero,
prima della coalescenza. I controlli precedono la costruzione del
risultato. Questo percorso di apertura può allocare; non promette zero
heap. I cicli sono limitati da byte e conteggi verificati.

Ogni chiamata possiede il proprio workspace. Le Serie possono costruire
manifest indipendenti in parallelo, senza lock o scritture condivise;
le query su un manifest pubblicato sono in sola lettura. Il modulo non
crea thread e non introduce uno scheduler del motore. Le campagne di
mutazione usano processi e cache separati; le misure di prestazione, se
richieste, restano seriali.

## Verifica e limiti

Il [metodo](manifest-control-log-metodo.md) distingue fixture indipendenti,
oracle logico, prove reali parallele, mutazioni e copertura grezza. La
[tabella delle decisioni](manifest-control-log-decisioni.md) registra i
predicati composti e le guardie interne.

La campagna del 2026-10-09 conserva i risultati nel
[catalogo](../../spikes/results/2026-10-09-manifest/catalogo.lisp): 20 test
dedicati, 64 test recovery nella fotografia iniziale, quattro thread con 32 ricostruzioni private e
un manifest comune; otto mutanti manifest rilevati e sette mutanti
DECISION rilevati per verificare la compatibilità del tool. La copertura
grezza dei sei file manifest è 888/1067 forme e 114/146 rami; nessuna
esclusione è approvata. Le query hanno 8/8 rami osservati. I dati HTML e
lo stato originale `sb-cover` restano conservati insieme ai fallimenti
preliminari e ai record dei comandi.

L'allineamento alle code writer e al selettore radix mantiene questi dati
storici e aggiunge una verifica integrata distinta nel catalogo. Il copier
delle campagne isolate include anche i componenti e i test `execution`;
ogni mutante continua a partire dalla baseline verificata. La campagna
DECISION della fotografia iniziale selezionava 25 test; dopo l'allineamento
il runner seleziona anche i 18 test radix, per 43 test dedicati. La suite
integrata comprende 82 test recovery e 17 test delle code writer.

Il runner radix conserva exit code e segnale del processo: un'interruzione
OS o un exit nonzero dopo il completamento dei test è un errore del worker,
distinto da un mutante rilevato. Il self-test usa un processo figlio che
stampa il marker di avvio e termina sé stesso con SIGKILL; runner, log e
report originali sono conservati nel catalogo. Questa prova riguarda lo
strumento, non un guasto del prodotto.

Questo modulo non riconcilia file o directory, non rinomina o elimina,
non legge i segmenti, non risolve i prepared e non scrive un nuovo control
log. La ricostruzione in memoria non chiude il gate del recovery completo.

Requisiti: REQ-WAL-001/005, REQ-REC-001/002/004, REQ-FOR-003,
REQ-AFF-008/009/017/018/019, REQ-VAL-001.
Invarianti: INV-S2/S4/S5/S7, INV-F1/F2/F3, INV-A7/A8/A9/A10/A11, INV-P6/X3.
