# Ricerca delle chiavi e directory dell'indice primario

## Ambito — 2026-10-09

`arcdocdb.index.primary` collega i [banchi v2](slot-indice-v2.md) a controlli
Swiss, chiavi locali e directory estendibile: lookup in memoria della versione
corrente, upsert/rimozione/rilocazione nel writer, crescita esplicita dell'arena e
pubblicazione di un rebuild/split già costruito.

Segue [ADR-0015](../adr/0015-primary-index-swiss-table-swmr.md),
[ADR-0043](../adr/0043-primary-index-a-frammenti.md),
[ADR-0048](../adr/0048-limiti-documentali-e-formato-v2.md) e
[ADR-0050](../adr/0050-pubblicazione-e-costi-della-directory.md).
Formati persistenti e decisioni architetturali invariati.

Classe C1: REQ-IDX-001, REQ-IDX-003, REQ-IDX-004, REQ-IDX-005, REQ-IDX-006,
REQ-IDX-007, REQ-LIM-001, REQ-LIM-003, REQ-CON-004, REQ-AFF-004,
REQ-AFF-008. Invarianti INV-I1, INV-I3, INV-V3, INV-A8, INV-P6.
Requisiti e qualifica restano progettati.

## Confine fidato e proprietà

Un indice per Serie; solo il writer con gettone modifica frammenti,
revisioni e root. Ogni worker e il writer hanno scratch privato preallocato
di cinque u64. Nessun oggetto per entry, mutex, thread, callback o I/O.
Sul successo il reader scrive solo lo scratch/output; sul guasto può
pubblicare salute terminale.

La API riceve un **digest già calcolato**, in due u32: metà alta per la
directory, metà bassa per gruppo e fingerprint. Il chiamante fidato usa
la stessa funzione/seed della Serie per lookup, mutazioni e ricostruzioni;
il digest non viene dal client. Hashing di chiavi arbitrarie e gestione
seed restano da collegare. Il kernel v1 limitato a `_id` di 16 byte non
qualifica v2. Un digest incoerente viola il contratto e può causare
duplicati/miss. Il confronto finale è sempre byte per byte.

Frammenti canonici del dominio: BUILDING fuori directory, PUBLISHED
corrente, RETIRED terminale. Il banco ritirato si congela prima del CAS.
Array interni; le primitive del banco non devono aggirare revisione e
controlli. Root e frammenti sono recuperati dal GC; EBR governa le risorse
esterne, senza promessa sul tempo di rilascio dello heap.

Guasto composto => indice FAULTED, senza rollback/reset/riapertura.
Il confine della Serie ferma ammissione e consegna dei risultati e chiama
`invalida-indice-primario` anche su errori del banco. Il controllo successivo
del frammento riconosce il banco faulted. Recovery del dominio da integrare.

## Lookup e budget comune

| Passo | Protocollo |
|---|---|
| Ingresso | Salute; span binario 1..65.535; contesto libero; output distinto dallo scratch. |
| Directory | Root acquisita; G bit alti scelgono il frammento. |
| Controlli | Gruppi allineati di 16, scalarmente; 7 bit H2 filtrano i candidati. |
| Payload | Un tentativo seqlock per candidato nel budget comune. |
| Chiave | Arena acquisita **dopo** il payload; byte già pubblicati immutabili. |
| Conferma | Identità/generazione root ricontrollate dopo barriera, anche sul miss. |
| Uscita | `:live` copia cinque u64; `:absent`/`:retry-limit` non toccano l'output. |

Massimo **otto campioni slot e cambi root complessivi**: ogni campione,
anche una collisione stabile, consuma uno; una root cambiata dopo un
risultato provvisorio consuma un altro. Una conferma riuscita non consuma
credito. Niente retry annidati, attese o crescita nel lookup. Al limite,
scartare location/scratch e inoltrare la richiesta originale al writer.
Il collegamento alla coda è esterno.

Ogni tentativo visita al massimo C/16 gruppi; il miss si decide dopo tutti
i candidati del gruppo con EMPTY, oppure dopo C slot senza EMPTY.
DELETED non termina la ricerca. Confronto limitato a 65.535 byte per
candidato; collisioni ostili possono causare ripiego al writer.
Il caso peggiore non è O(1); allocazione, distribuzione hash e P99 da misurare.

Fingerprint occupato con payload vuoto è uno stato transitorio possibile
per il reader durante rimozione; nel writer esclusivo è un guasto.
Payload coerente e confronto della chiave governano anche il riuso.
Controlli riservati o intervallo chiave stabile fuori arena sono guasti.
Su errore/uscita non locale non consegnare l'output privato, anche se già
copiato. Cleanup libera il contesto. Il rientro si rifiuta prima del
cleanup, senza liberare il contesto della chiamata già attiva.

Non è un GET completo: serve il [contesto di lettura](compiti-lettura.md)
per EBR e verifica snapshot finale, oltre a storage/cache e consegna dopo
cleanup. Snapshot precedenti al CSN corrente richiedono versioni trattenute,
ancora non ricercabili in questo blocco.

## API e mutazioni del writer

| API | Contratto |
|---|---|
| `crea-indice-primario` | Root G=0, generazione 0, un frammento vuoto. |
| `crea-frammento-indice` | Candidato BUILDING con prefisso/profondità e arena propria. |
| `crea-contesto-indice` | Scratch esclusivo preallocato prima del pool. |
| `frammento-corrente-indice` | Selezione per il writer; non autorizza pin nel reader. |
| `leggi-indice-primario` | Lookup in output privato con conferma root e budget condiviso. |
| `pubblica-chiave-indice` | Upsert in memoria; offset chiave interno; CSN crescente su update. |
| `rimuovi-chiave-indice` | T rimossa, NIL assente; payload zero poi DELETED. |
| `riloca-chiave-indice` | Lookup corrente per chiave; T applicabile, NIL versione/location superate. |
| `estendi-arena-indice` | Array più grande con gli stessi byte agli stessi offset. |
| `prepara-directory-indice` | Piano monouso per sostituire un frammento con uno o due candidati. |
| `pubblica-directory-indice` | Congelamento sorgente e CAS; piano stale rifiutato prima. |
| `invalida-indice-primario` | Salute terminale; nessuna risorsa reclamata. |

Preflight upsert: key-len uguale allo span, fonte/scratch distinti,
dominio/prefisso corretti, slot disponibile, carico vivo sotto 7/8 su
insert, arena sufficiente, CSN crescente e credito seqlock/revisione.
Poi chiave, payload, controllo, conteggio. Update riusa i byte della chiave;
delete non li cancella. Assenza non consuma sequenza/revisione.
Controlli: EMPTY → occupato → DELETED → occupato, mai di nuovo EMPTY.

Expected-version, retention, tombstone, WAL, decisione committed,
durability e **prenotazioni di tutti i lotti pendenti** sono precondizioni
del writer superiore. Questi controlli prima della mutazione in memoria
non costituiscono il preflight transazionale del motore. Il ritorno non
autorizza una conferma al client. Niente auto-split post-commit.

Rilocazione: ricerca della chiave nella root corrente, confronto di
CSN/location/lunghezza/fine originali, offset arena ricostruito dal lookup.
Un messaggio precedente a un rebuild non porta lo slot o l'offset locale
nel nuovo banco. Solo location può cambiare; mismatch/assenza non mutano,
location già identica è un no-op senza credito. Copia identica durevole,
manifest e reclaim rimangono esterni; non si sovrascrive una versione nuova.
Versioni trattenute e loro rilocazione restano da collegare.

## Directory, memoria e costi

Rebuild: candidato con stessa profondità/prefisso del sorgente corrente.
Split: due figli ordinati, d+1 e 2p/2p+1. Directory raddoppiata se d=G,
altrimenti G invariato. Sempre array nuovo, root immutabile, generazione +1.
Generazione e revisione restano sotto 2^60 senza wrap.

Il costruttore superiore deve copiare e verificare tutte le chiavi vive e
i payload con lo stesso hash. La API verifica dominio, geometria e numero
vivo complessivo: **il conteggio non dimostra la fedeltà della copia**.
Costruzione automatica e verifica del rebuild/split da implementare.
Ogni mutazione successiva alla preparazione, anche sui candidati, rende
stale il piano via revisione. Piani consumati non si riutilizzano.

Pubblicazione: congela solo il sorgente, marca candidati pubblicati,
barriera e CAS. Frammenti condivisi restano scrivibili. Interruzione
dall'inizio della fase => indice/piano faulted anche dopo CAS riuscito.
Il piano trattiene la root precedente fino al rilascio del piano stesso.

Configurazione preliminare, tarabile prima della qualifica:

| Parametro | Default | Range |
|---|---|---|
| C | 8.192 | Potenze di due 16..65.536 |
| Arena iniziale | 64 KiB | 1..2^32 byte, entro budget |
| Payload massimo per frammento | 8 MiB | Positivo, fixnum |
| Profondità massima G | 20 | 0..30, entro budget directory |
| Payload massimo directory | 8 MiB | Almeno 8 byte, fixnum |

Limiti della rappresentazione corrente, non capacità garantite del prodotto.
Nessuna preallocazione C × 65.535. Prima di allocare un frammento: 41*C +
arena. Prima della directory: 8*2^G e transitorio di root corrente
(frammenti distinti inclusi), candidati e directory nuova. Crescita arena:
root corrente, eventuale BUILDING, nuovo array, prima dell'allocazione.
Il controller prenota **prima della costruzione dei candidati**, e somma
altri piani/root/arena trattenute, garbage, header e runtime. Non è RSS o
un tetto globale. Catalogo e controller della memoria da collegare.

Costo directory O(2^G) anche senza raddoppio. C slot sorgente, byte chiavi,
memoria transitoria e durata si misurano separatamente. Nessuna promessa
di pausa indipendente dalla dimensione della Serie.

## Decisioni da coprire — COD-54

| ID | Decisione | Condizioni indipendenti |
|---|---|---|
| PRIM-D01 | Configurazione | Capacità/range/potenza di due; G; budget; arena. |
| PRIM-D02 | Contesto/span | Range/key-len; libero; alias input/output. |
| PRIM-D03 | Controllo | H2; EMPTY; DELETED; riservato; nessun reset EMPTY. |
| PRIM-D04 | Candidato | Budget; live/empty/retry; lunghezza; byte; range arena. |
| PRIM-D05 | Conferma | Identità/generazione root; salute; hit e miss. |
| PRIM-D06 | Preflight writer | Nuovo/esistente; carico; arena; CSN; crediti. |
| PRIM-D07 | Crescita arena | Stato; dimensione; u32; budget frammento/transitorio. |
| PRIM-D08 | Sorgente | Owner; published; profondità; identità corrente. |
| PRIM-D09 | Candidati | Building; geometria; identità; conteggio; profondità/budget/generazione. |
| PRIM-D10 | Pubblicazione | Preparato; root/revisione attese; freeze; CAS; interruzione. |
| PRIM-D11 | Rilocazione | Fonte/copia valide; CSN/length/end/key-len identici; lookup corrente; identità attesa; no-op/credito. |

Da esercitare: collisioni e gruppi senza EMPTY, riuso con nuovo H2, chiavi
massime/CSN oltre fixnum, crescita arena e rebuild durante hit/miss, doppio
piano, mutazione dopo preparazione, esaurimento, guasto concorrente e
interruzioni di tutte le pubblicazioni. Nessuna copertura dichiarata.

## Metodo delle evidenze e qualifica

Metodo fissato prima dei controlli: compilazione del solo prodotto con
avvisi come errori; lint, tracciabilità, link, cataloghi; disassemblato
ARM64 per ispezione statica senza chiamare le nuove API. Output originali,
sorgenti prima/dopo e rifiuti conservati nella
[campagna](../../spikes/results/2026-10-09-primary-lookup/README.md).

Due letture locali separate di payload/controlli e directory/costi sono
conservate come dati; non sono revisioni indipendenti. Il disassemblato
ARM64 mostra load/store nativi dei payload, `DMB ISHLD`/`DMB ISHST` e
`CASAL` della root; non dimostra correttezza concorrente o zero heap.
Il primo controllo link ha rifiutato il percorso di ritorno dalla campagna;
report originale conservato, percorso corretto e controllo ripetuto.

Nessun test funzionale, concorrente, fault injection, modello, benchmark
o auto-verifica degli strumenti aggiunto/eseguito localmente. Restano
qualifica C1, revisioni indipendenti, memoria ARM64/x86-64, allocazioni/P99,
hashing, costruttore split/rebuild, retention, prenotazioni, recovery,
cache e GET integrato. Codice v1 e suite preesistenti non qualificano v2.
