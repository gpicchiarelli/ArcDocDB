# SPK-07 — Metodo compaction con writer ACTIVE

Metodo registrato prima della compilazione e del check, 2026-10-08.
Ambito: solo modello logico Common Lisp/SBCL, `safety 3`, nel package
`arcdocdb.spk07.compaction`, con `CHECK` esportato. Il core SPK-07 è caricato
prima del modulo; si riusano soltanto `explore` e `require-outcome`.

## Domanda e criterio di esito

CLEAN e copia di sorgenti CLOSED non adiacenti conservano il valore al CSN
dello snapshot e il latest committed mentre il writer committa in ACTIVE?
Il controllo positivo deve esaurire ogni grafo finito senza violazioni né
raggiungere il limite. Ciascuno dei quattro mutanti deve produrre la
violazione attesa con un witness non vuoto: repoint incondizionato,
tombstone eliminato, versione snapshot persa, reclaim pinned.
`CHECK` restituisce una plist `:status :ok` solo dopo questi controlli,
con conteggi effettivi, report positivi/negativi, assunzioni e limiti.

## Modello e oracle

Workload deterministici di una o due chiavi, quattro segmenti CLOSED,
sorgenti CLEAN singole oppure coppia non adiacente, record esterni più
vecchi, un ACTIVE distinto e uno snapshot già registrato. Si enumerano
PUT/DELETE nei CLOSED, aggiornamenti/DELETE/ricreazioni ACTIVE e due modi
di risolvere prepared committed: OUTCOME locale e esito nella chiusura
del manifest (ADR-0041). Prepared abortiti e metadati SEAL/OUTCOME non
devono finire nell'output; i committed sono copiati come ordinari.

La copia avanza per record, il writer per commit atomico durevole e
pubblicato. Le due sequenze intercalano con sync tmp, syncdir, EDIT,
rename, repoint per chiave, rilascio del pin e reclaim. L'EDIT è un solo
fatto durevole: prima si recuperano i sorgenti; dopo si completa l'output.
I sorgenti sono immutabili; il reclaim elimina soltanto segmenti rimossi,
dopo completamento e rilocazioni, con pin rilasciato. Il pin è un booleano
di contratto, senza implementazione delle epoche o scadenza snapshot.

Il repoint del writer cambia solo entry ancora sui sorgenti e con lo
stesso CSN della copia; una entry ACTIVE più recente resta intatta.
Le versioni trattenute per lo snapshot sono rilocate separatamente.
Un tombstone viene conservato se versioni trattenute o record esterni
più vecchi potrebbero riemergere; ACTIVE non giustifica lo scarto.
Il filtro di esistenza è esatto oppure conservativamente «forse», mai
con falsi negativi (ADR-0042).

L'oracle usa una storia committed immutabile e il prefisso dei commit
ACTIVE, senza chiamare selezione, repoint o ricostruzione del modello.
Confronta valori e CSN dopo ogni stato/interleaving. Da ogni stato si
controlla anche il crash e la riconciliazione, ricostruendo dalle sole
fonti ammesse dal manifest e dal prefisso ACTIVE durevole; si confrontano
latest e valore storico al CSNsnapshot e si verifica l'idempotenza del
recovery. Dopo un vero riavvio lo snapshot non sopravvive (ADR-0040): il
valore storico resta una query dell'oracle sui record conservati, non
una nuova decisione sulla persistenza degli snapshot.

## Confini e conflitti dichiarati

Riferimenti letti: ADR-0040/0041/0042 e INV-C1…C11. La policy MERGE della
specifica esclude segmenti necessari a snapshot attivi. La coppia non
adiacente con snapshot qui richiesta verifica il protocollo di copia
e la conservazione delle versioni, sotto ammissione astratta: **non**
dimostra né modifica la policy MERGE, INV-C5/C6, stabilità o basso carico.
Nessuna modifica alle decisioni o al gate globale SPK-07.

Assunzioni: memoria sequenzialmente consistente; transizioni atomiche;
CSN totali, un solo record per chiave e CSN; CLOSED autosufficienti e
ACTIVE con CSN superiori ai CLOSED; commit ACTIVE durevole/pubblicato
atomico; snapshot e scelta dei sorgenti fissati prima della copia;
conservazione prudente delle versioni selezionate anche dopo rilascio.
Si verifica safety e completabilità bounded, senza fairness o liveness
del motore. Nessun filesystem reale, byte/CRC, errore I/O, memoria debole,
decoder, benchmark, epoch internals o scadenza snapshot.

## Esecuzione e registrazione

Ogni tentativo di compile/check produce un file nuovo sotto
`spikes/SPK-07-protocols/out/`, senza sovrascrivere prove precedenti.
Il record dati Common Lisp schema 1 conserva argv e stdin esatti,
ambiente SBCL/OS/CPU/RAM/heap, tempi, blob di contenuto prima/dopo,
esito/exit code, risultato, limiti, raw stdout/stderr e fallimenti.
Nessun comando Git: i blob sono identificati da digest del contenuto e
la storia Git non viene interrogata. Anche warning/style-warning,
errori di compilazione, budget esauriti e output malformato fanno fallire
il tentativo e vengono registrati. Compilati confinati nello stesso out.

Compilazione separata del core esistente e del modulo con ogni warning
(incluso style-warning) fatale, più verifica dei valori warnings-p e
failure-p di `compile-file`. Check breve con limite esplicito per grafo;
nessun benchmark e nessun commit.

## Risultati osservati e consegna

Check eseguito su SBCL 2.6.9, Darwin 27.0.0 ARM64, Apple M4, 16 GiB RAM;
heap del processo 1.024 MiB. Compilazione strict e caricamento completati,
stderr vuoto, `CHECK` restituisce `:status :ok`. Nessuna casualità.

| Controllo positivo | Conteggio effettivo |
|---|---:|
| Grafi esauriti senza violazioni | 98 |
| Stati distinti visitati | 7.994 |
| Transizioni esplorate | 16.952 |
| Stati finali con tutti i commit e reclaim completati | 98 |
| Massimo stati per grafo / limite | 140 / 10.000 |
| Letture dall'indice corrente / snapshot con pin | 12.034 / 5.750 |
| Proiezioni di crash | 11.592 |
| Prefissi di recupero verificati anche dopo riavvio | 46.368 |
| Ricostruzioni in ordine diretto/inverso | 92.736 |
| Confronti dopo crash, latest / storico al CSNsnapshot | 139.584 / 139.584 |

I 98 grafi comprendono 64 configurazioni a una chiave, 32 a due chiavi
complementari e due casi di scarto sicuro del tombstone isolato, con
filtro esatto/«forse». Sono 16 combinazioni PUT/DELETE a una chiave e
un campione dichiarato a due chiavi; risoluzione OUTCOME/manifest e
filtro esatto/«forse» sono alternati nei carichi, senza esaurire il loro
prodotto cartesiano. Le proiezioni di crash enumerano i nomi tmp/definitivo
e la possibile persistenza dei sorgenti già eliminati; non sono crash
del filesystem. Ogni proiezione ha quattro prefissi di recupero, inclusi
inizio e fine, e due ordini di ricostruzione, non tutte le permutazioni.

Controlli negativi: quattro mutanti per ciascuna cardinalità di chiavi,
otto controesempi specifici con percorso non vuoto. Il BFS scopre 568
stati e ne visita 510 prima delle violazioni (1.165 transizioni).

| Mutante | Controesempio a una chiave |
|---|---|
| Repoint incondizionato | Il commit ACTIVE CSN 5 viene sovrascritto dalla copia CLOSED CSN 4. |
| Tombstone eliminato | Dopo EDIT riappare il PUT esterno CSN 3, nascosto dal DELETE CSN 4. |
| Versione snapshot persa | Dopo EDIT lo snapshot CSN 2 restituisce il PUT CSN 1 invece del CSN 2. |
| Reclaim pinned | I sorgenti vengono eliminati con il riferimento ancora attivo, dopo completamento. |

Tutti i tentativi sono raccolti anche nel record unico schema 1
[`spk07-compaction-campaign.lisp`](../results/2026-10-08/spk07-compaction-campaign.lisp),
che incorpora integralmente i record individuali con comando/stdin,
ambiente, contenuti e digest dei blob, risultato, limiti e output grezzo.
I digest `:git-blob` sono SHA-1 di `blob <lunghezza> NUL <contenuto>`,
calcolati senza invocare Git; si conserva anche SHA-256 del contenuto.

Sono conservati quattro fallimenti iniziali: uno del wrapper (simbolo
UIOP inesistente, prima dell'avvio compile/check), tre di compilazione
del modulo (parentesi mancante, clausola LOOP non ammessa, parentesi in
eccesso). Il primo record è ricostruito dal log grezzo e dichiara
`:source-blobs-before :not-captured`; non inventa la provenienza mancante.
Seguono il check riuscito e la compilazione/check finale dopo la revisione
in italiano dei commenti e delle docstring. Le fonti vengono confrontate
prima/dopo ciascun tentativo gestito dal wrapper.

La consegna riguarda `compaction.lisp`, questo metodo e i nuovi artefatti
con prefisso `compaction-` sotto `out/`. `run-module.lisp` è destinato
all'integrazione successiva e non è modificato né usato da queste prove.
Il modulo è verificato caricando il core prima del suo FASL. Il gate
globale resta aperto, con i limiti dichiarati sopra e il conflitto di
ammissione MERGE esplicitato; nessuna decisione viene promossa o cambiata.
