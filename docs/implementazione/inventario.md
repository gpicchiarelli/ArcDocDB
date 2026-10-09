# Piano di riconciliazione dei segmenti

Il package `arcdocdb.recovery.manifest` confronta il manifest completato
con un inventario di nomi fornito dal chiamante. Realizza in memoria
la tabella di [ADR-0040§3](../adr/0040-manifest-a-record-unico.md#3-riconciliazione-al-riavvio):
riconosce rinomine, rimozioni decise, anomalie e segmenti mancanti.
Le query consultano il piano senza eseguire operazioni sul filesystem.

## API e responsabilità

| API | Risultato |
|---|---|
| `file-segmento(id, forma)` | Descrittore immutabile, ID u64 incluso zero, forma `:temporary` o `:final` |
| `pianifica-riconciliazione(manifest, files, :max-files, :max-segmenti)` | Piano posseduto da un simple-vector completo e stabile di descrittori |
| `stato-riconciliazione(plan)` | `:ready`, `:degraded` o `:faulted` per la disponibilità dei nomi richiesti |
| `numero-azioni-riconciliazione(plan)` | Numero di ID distinti del piano |
| `azione-riconciliazione(plan, indice)` | ID, forma, azione e stato nel manifest, tutti scalari |

Il chiamante interpreta `.seg` e `.seg.tmp`, esclude altre categorie
e fornisce un inventario completo: un elenco parziale renderebbe
falsamente mancanti i segmenti esclusi. Il modulo non verifica questa
precondizione, la stabilità del filesystem, header, identità fisica,
CRC o contenuti. `:ready` non attesta integrità né autorizza traffico.

Il piano contiene ogni ID dell'inventario e tutti gli ACTIVE/CLOSED
mancanti, una volta ciascuno, in ordine crescente unsigned u64.
REMOVED assenti non generano entry. Due nomi per lo stesso ID diventano
una entry `:both`. Il piano possiede il suo vettore; il chiamante può
riusare l'inventario e il buffer EDIT dopo il ritorno. Nessun hash
interno o vettore viene esportato e il manifest resta in sola lettura.

## Azioni

| Presenza | Stato manifest | Forma / azione |
|---|---|---|
| solo `.seg.tmp` | ACTIVE o CLOSED | `:temporary / :rename` |
| solo `.seg.tmp` | REMOVED o UNKNOWN | `:temporary / :delete` |
| solo `.seg` | ACTIVE o CLOSED | `:final / :use` |
| solo `.seg` | REMOVED | `:final / :delete` |
| solo `.seg` | UNKNOWN | `:final / :anomaly`, conservare |
| nessuno | ACTIVE o CLOSED | `:absent / :missing` |
| entrambi | qualunque | `:both / :conflict`, conservare entrambi |

La doppia forma non è risolta dalla tabella ADR: questo **contratto
applicativo conservativo** evita di scegliere o sovrascrivere un file
senza verificarne identità e contenuti. La proposta locale per un
temporaneo REMOVED usa la prova positiva di rimozione del manifest.
Le azioni sono indicazioni: il futuro esecutore I/O dovrà controllare
prove, identità e stabilità prima degli effetti durevoli.

ACTIVE mancante o in conflitto produce `:faulted`; CLOSED mancante o
in conflitto produce `:degraded`. FAULTED prevale su DEGRADED. Anomalie
UNKNOWN e conflitti REMOVED/UNKNOWN restano espliciti nel piano senza
cambiare questa sola misura di disponibilità dei nomi richiesti.
Il prossimo ID del manifest non dimostra appartenenza storica: un
definitivo sconosciuto sotto quel limite resta un'anomalia.

## Budget, errori e parallelismo

Budget configurabili proposti: 65.536 file fisici e 65.536 segmenti
richiesti (`1 + CLOSED`). Zero è ammesso; l'uguaglianza al limite è
valida. I budget precedono validazione e coalescenza delle entry:
duplicati e doppie forme consumano il budget fisico. Il bound del
workspace è file fisici più segmenti richiesti. Questo percorso di
apertura alloca; non promette zero heap o prestazioni misurate.

Budget interi fuori `index`, descrittori invalidi e nomi duplicati
segnalano `invalid-argument`; per entry invalida/duplicata l'offset è
l'indice nel vettore. Query fuori range segnalano `invalid-argument`.
Budget insufficienti segnalano `resource-exhausted`; incoerenze private
segnalano `invariant-violation`. I tipi `ftype` sono controllati con
safety3 e segnalano `type-error`. Nessun errore esporta un piano parziale.

Le chiamate possiedono workspace separati; le query su un piano
pubblicato sono in sola lettura. Il planner non crea thread, non
modifica input e non introduce lock o scritture condivise fra Serie.

## Verifica

Il [metodo preregistrato](inventario-metodo.md) prescrive un oracle
indipendente, matrice esaustiva, permutazioni, u64 e budget, ownership,
quattro thread, mutazioni isolate e copertura grezza. La
[tabella delle decisioni](inventario-decisioni.md) include le guardie
difensive. Le prove non chiudono il gate del recovery completo.

La campagna del 2026-10-09 è conservata nel
[catalogo dell'inventario](../../spikes/results/2026-10-09-inventory/catalogo.lisp):
13 test dedicati, 95 recovery e 307 complessivi più smoke nella fotografia
integrata. Il modello confronta 6.144 piani (1.024 inventari × due versioni
× tre ordini) e altre 1.440 permutazioni (720 × due versioni).
Quattro thread costruiscono 32 piani privati e consultano un piano
comune dopo il riuso degli input. Questa prova non misura prestazioni.

La baseline di mutazione esegue i 13 test dedicati; tutti gli otto
mutanti sono rilevati con quattro processi isolati, zero sopravvissuti,
errori di compilazione, pre-test o worker. Il self-test verifica le copie
ASDF, ora comprensive di CSN, e conserva il segnale SIGKILL di un figlio
come errore del worker. Questa classificazione riguarda lo strumento
`foundation-mutation.lisp`; non qualifica gli altri runner del progetto.

| File | Forme osservate / totali | Rami osservati / totali |
|---|---|---|
| `inventory-build.lisp` | 306 / 390 | 41 / 56 |
| `inventory-query.lisp` | 27 / 32 | 2 / 2 |
| `inventory-types.lisp` | 7 / 18 | 0 / 2 |
| Totale grezzo | 340 / 440 | 43 / 60 |

Le 100 forme e 17 alternative non osservate restano nel denominatore,
comprese le guardie private. Nessuna esclusione è approvata e MC/DC non
è dimostrata. Il catalogo conserva stato originale `sb-cover`, index e
HTML dei tre file. Conserva anche le due letture C1, il finding iniziale
sulle guardie e il primo build fallito per una parentesi mancante, poi
corretta. Una diagnostica di lettura delle prove resta distinta dai
fallimenti del prodotto. `make check` e le campagne conservano hash,
ambiente, comando e output originali.

Requisiti: REQ-REC-001/002/004, REQ-AFF-008/017/018.
Invarianti: INV-A7/A8/A9/A10/A11, INV-C7, INV-P6.
