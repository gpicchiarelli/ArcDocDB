# Contesto worker dei writer

Il contesto preallocato integra [handoff](writer-handoff.md),
[lista pronta](writer-ready.md) e [ricircolo](writer-recycle.md) sul thread
worker che lo crea. Conserva obblighi, lease, cursore, shard e debito del
batch; nessuna coda globale, thread o callback applicativa nel componente.
Un contesto ha un solo proprietario e non è rientrante né migrabile.

| API | Precondizione ed effetto |
|---|---|
| `crea-contesto-worker-writer ready :start` | Una volta all'avvio del worker corrente; parte idle, cursor default0. |
| `prendi-writer-worker ctx` | Idle; scansione bounded restituisce writer/claimed/cursor, oppure NIL/empty o busy/cursor. |
| `inizia-tratto-worker ctx` | Claimed; acquisisce la lease e passa running. Begin separato dal pop dei payload. |
| `preleva-lavori-worker ctx target start end` | Running; restituisce count/status/token. Messages crea batch; empty/yield lascia token0 e running. |
| `conferma-lavori-worker ctx token` | Batch completamente elaborato dal caller; ack corrente torna running, stesso tratto/quota/lease. |
| `termina-tratto-worker ctx` | Running dopo ack, oppure finishing; fissa finishing prima dell'end, poi idle o reschedule. |
| `ricircola-worker ctx` | Reschedule; room→NIL/published/count e idle, full→testa/claimed/count invariato. |
| `adotta-writer-worker ctx writer home` | Idle; riceve dal caller un unico obbligo non già nel ring, home stabile. |
| `cede-writer-worker ctx` | Claimed/reschedule; restituisce writer/home al caller e libera idle. Non cede lease attive. |
| `stato-worker-writer`, `writer-worker-writer`, `errore-worker-writer` | Getter owner-only per diagnosi; non trasferiscono proprietà. |

## Proprietà e retry

La testa tolta al ring resta nel contesto durante begin busy. La home viene
derivata dal predecessore modulo K del cursore restituito dalla lista pronta,
senza cercare il writer. Anche empty/busy ruotano cursor: sono osservazioni
locali, non una prova di quiescenza per parcheggio o shutdown.

Un pop messages produce un debito esplicito: nessun nuovo pop o end prima
dell'ack. Il token locale cresce una volta per batch, non su empty/yield,
non si resetta su idle/cessione e non fa wrap. È legato alla coppia
contesto/token; non è unico tra contesti. Ack attesta il caller: il componente
non può verificare effetti esterni, WAL o risposte senza integrare il motore.

Busy del primo end lascia finishing, con lease/riferimento conservati;
solo il retry dell'end è ammesso. Dopo schedule la lease è già rilasciata:
recycle busy conserva l'obbligo senza ripetere end. Full passa una nuova
testa al contesto senza aumentare la capacità; il precedente riferimento
appartiene ora al ring. Nessun cleanup sul writer può cancellare una nuova
ondata dopo una fine idle.

Cessione/adozione trasferiscono soltanto obblighi senza lease. Non verificano
dedup o eleggibilità: il caller mantiene la proprietà unica. Non abbandonare
un riferimento ceduto, non ripubblicare quello già trasferito al ring.
Il contesto può essere ritirato dopo cessione, con generation conservata;
questo non implementa il protocollo di retirement di un pool.

## Errori e confine locale

| Errore | Gestione |
|---|---|
| Owner diverso, `invalid-argument :worker-owner` | Rifiutato prima del handler e della mutazione, anche nei getter. |
| Fase errata, `resource-exhausted :worker-state` | Nessuna transizione; contesto faulted rifiuta tutti i passi successivi. |
| Token errato/stale, `:worker-batch`; target/span/alias, `:writer-target`; adozione, `:worker-writer` / `:ready-target` | Input rifiutato prima delle scritture, stessa fase. |
| Busy atteso di queue/ready | Solo il motivo previsto per quel passo è recuperabile; campi conservati, salvo il primo latch finishing. |
| `resource-exhausted :worker-generation` | Budget locale esaurito prima del pop dopo preflight target; anche empty/yield è rifiutato. End e cessione restano disponibili, nessun reset/wrap. |
| Altri errori, inclusi not-ready, writer-generation, lease privata e invarianti | Condizione originale registrata e propagata, fase faulted persistente e campi conservati; nessun rollback o riuso. |

Il confine usa un handler interno dynamic-extent: preserva la stessa
condizione e non la nasconde. Ragioni recuperabili distinte per tipo e API;
i controlli degli indici privati producono invarianti, così un home invalido
del caller non maschera un contesto corrotto. Un faulted non può cedere o
adottare: diagnostica e controllo esterno della Serie devono governare il guasto.
Il controller FAULTED della Serie e il rilascio controllato delle risorse
in questo caso restano da integrare; fault locale non qualifica l'intero motore.

## Costo e confini

I campi locali non sono condivisi fra worker. La lista condivisa viene
toccata per tratto, non per messaggio. Take delega la scansione esistente
≤64 shard/128 CAS; gli altri passaggi sono O(1), oltre alla copia bounded
del batch. Consumo e ack fuori dalle guard ready, zero attese/retry interni.
Factory all'avvio, input/target preallocati nel percorso normale.

Una catena full resta sullo stesso shard: quote del pool, equità globale,
admission, wake/park, shutdown, controller e applicazione degli effetti
richiedono integrazione. Il [metodo](writer-worker-metodo.md),
[decisioni](writer-worker-decisioni.md), [risultati](writer-worker-risultati.md)
e [revisione](writer-worker-revisione.md) delimitano la verifica locale.
