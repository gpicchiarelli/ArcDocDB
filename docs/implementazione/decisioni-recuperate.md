# Decision log recuperato dell'Archivio

Il modulo [`src/recovery-archive/`](../../src/recovery-archive/) legge
`Registri/multiserie.log` e collega il suo risultato al
[recovery ACTIVE](active-recuperato.md). Applica i formati e la semantica di
[ADR-0041](../adr/0041-multiserie-segmenti-autosufficienti.md) e
[ADR-0052](../adr/0052-header-dei-log-di-controllo.md), senza emendarli.

## API e autorità

Namespace: `arcdocdb.recovery.archive`.

| API | Contratto |
|---|---|
| `crea-archivio-recovery(scope, identity)` | associa l'ambito GET canonico dell'Archivio a una copia privata del suo UUID16 autorevole |
| `leggi-decisioni-recuperate(archive, input, size, scratch, …)` | legge header e corpo sullo stesso FD readonly; restituisce solo la tabella completa del prefisso verificato |
| `frontiere-decisioni-recuperate(result)` | EOF attestato, prefisso assoluto P, `:complete`/`:tail`, versione 1/2 |
| `numero-decisioni-recuperate(result)` | TXID distinti dopo la coalescenza |
| `trova-decisione-recuperata(result, txid)` | presenza, CSN, numero partecipanti; `nil/0/0` se assente |
| `partecipante-decisione-recuperata-p(result, txid, id, start, end)` | presenza esatta dell'ID16; range verificato anche per TXID assente |
| `leggi-active-con-decisioni(control, input, size, result, scratch, …)` | verifica ambito e lifetime del decision log, poi delega al recovery ACTIVE canonico |

Il bootstrap associa **una volta sola** UUID e `ambito-get` dello stesso
Archivio, provenienti dal catalogo. Il costruttore copia tutti i sedici byte;
non certifica il catalogo, l'unicità dell'associazione o i percorsi nel
filesystem. L'uguaglianza UUID da sola non sostituisce l'identità canonica
dell'ambito condiviso dalle viste delle Serie.

Il controller attesta `size` come **EOF fisico completo e stabile**. La
capacità readonly non misura EOF e non impedisce scritture esterne. File,
FD e namespace restano congelati e aperti fino al completamento del recovery
delle Serie; scratch esclusivo fino al ritorno del lettore. L'API non apre,
chiude, tronca, rinomina o rende durevole alcun file.

## Ordine dei controlli

1. Senza syscall: capacità aperta readonly, assenza di alias con UUID
   posseduto, chunk positivo, header completo, range e tutti i budget.
2. Leggere esattamente l'header di 64 byte dallo stesso FD; verificare
   magic `ARCDMSL1`, CRC, tutti i byte UUID, versione effettiva e riservati.
   Un header incompatibile fallisce prima di leggere il corpo.
3. Leggere il corpo fino all'EOF attestato, in chunk limitati, senza
   rileggere l'header.
4. Eseguire `ricostruisci-decisioni` con la versione dell'header e
   `file-size = size`: scanner, ricerca dei testimoni, preflight dei
   partecipanti, copie possedute, ordinamento e controllo dei conflitti.
5. Verificare frontiere e capacità ancora aperta; consegnare il risultato
   completo senza scratch, workspace o array esportati.

Il SEAL con file-id zero non sostituisce l'UUID dell'header. La coda resta
sul file: `:tail` significa ricerca completa dei testimoni ed esclusione
del lotto incompleto, non replay parziale di quel lotto. Un testimone di
corruzione durevole, un conflitto DECISION o un budget esaurito propagano
le condizioni originali; il controller applica fail-stop.

Il [replay canonico](decisioni-multiserie.md) conserva TXID e CSN u64 opachi,
anche zero e massimo; duplicati identici sono idempotenti, decisioni
contraddittorie sono corruzione. Le query restituiscono scalari e non
attestano che il file sia ancora aperto o sano al momento della query.

## Collegamento alla Serie

`leggi-active-con-decisioni` accetta esclusivamente `decisioni-recuperate`.
Prima di qualsiasi I/O ACTIVE esige `eq` tra l'ambito dell'Archivio e
quello della vista nel CONTROL recuperato, rifiuta alias con UUID e
controlla che il decision log sia aperto readonly. Delega quindi al
lettore ACTIVE esistente, inoltrando tutti i budget; ricontrolla il
lifetime del decision log prima di restituire il risultato.

Un'assenza DECISION può così essere risolta dal percorso canonico a partire
da una scansione completa dell'Archivio corretto, sotto le precondizioni
di bootstrap ed EOF. OUTCOME locali, partecipanti e CSN restano controllati
dal resolver ACTIVE; non viene introdotta una seconda semantica.

`leggi-active-recuperato` resta disponibile con il precedente contratto:
chi passa direttamente una tabella nuda ne garantisce identità e completezza.
Non c'è fallback da `nil` o da un log non letto. Il risultato ACTIVE non
trattiene la tabella dell'Archivio. Il nuovo ingresso non autorizza
dimenticanza delle decisioni, nuovi CSN o ammissione del traffico.

## Budget, memoria e prestazioni

| Budget di apertura | Default |
|---|---:|
| byte totali del file, header incluso | 64 MiB |
| chunk del corpo | 64 KiB |
| lotti / record per lotto | 65.536 / 65.536 |
| byte per lotto | 64 MiB |
| DECISION fisiche, duplicati inclusi | 65.536 |
| partecipanti cumulativi, duplicati inclusi | 65.536 |
| partecipanti per DECISION | 65.535 |

Sono budget configurabili del compito di apertura, non nuovi limiti del
database. Il tetto per DECISION deriva dal campo u16 del formato. Zero è
ammesso per i conteggi DECISION/partecipanti quando il file non li contiene;
un record oltre il budget non viene ignorato. La capacità I/O consente
`max(64, min(size-64, chunk))` byte per trasferimento.

Scratch di almeno `size` byte, fornito dal chiamante; UUID posseduto di
16 byte; tabella e workspace del replay limitati da record e partecipanti.
Questi limiti non sono una misura di RSS o dell'overhead degli oggetti Lisp.
Il file è letto una volta: header e `ceiling((size-64)/chunk)` trasferimenti
esatti. Query binarie e ordinamento restano quelli del replay esistente.
Percorso di apertura con allocazioni: nessuna promessa di throughput,
latenza o heap zero. Nessun lock o nuova scrittura condivisa tra Serie.

## Decisioni e qualifica

| ID | Decisione composta o confine | Casi della campagna dedicata |
|---|---|---|
| DAR-D01 | chunk positivo e byte budget almeno header | ciascuna falsa, entrambe vere; size 63/64 e budget esatto/superato |
| DAR-D02 | chunk positivo e size almeno header nel lettore corpo | ciascuna falsa, entrambe vere; corpo vuoto e ultimo chunk corto |
| DAR-D03 | P nel range e stato coerente con EOF | ogni limite falso, complete/tail, header-only, coda, testimone durevole |
| DAR-G01 | UUID esatto e copia posseduta | UUID di 15/16/17 byte; modifica del caller; mismatch byte alto, CRC, riservati, versioni 1/2 |
| DAR-G02 | preflight completo prima di I/O | readonly/closed, alias, scratch insufficiente, budget scanner/replay e capacità chunk |
| DAR-G03 | ambito canonico identico prima di I/O ACTIVE | stessa/differente identità, anche con uguale UUID; log chiuso prima/durante lettura |
| DAR-G04 | replay e query canonici | duplicati, conflitti, zero/u64 alto, budget partecipanti, mutazione scratch dopo ritorno |

Le [prime evidenze locali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-archive-recovery/README.md)
distinguono compilazione, letture statiche e conservazione dei byte da prove
funzionali. Il [metodo della nuova verifica](decisioni-recuperate-verifica.md)
definisce prove funzionali, fault injection e catena nativa; la
[revisione indipendente](decisioni-recuperate-revisione.md) resta distinta
dai risultati eseguiti. Qualifica C1 completa e misure dei nuovi ingressi
restano aperte. Il componente non completa riconciliazione
CLOSED, indici/orizzonte CSN o gate del Recovery Manager. Il
[builder completo del checkpoint](checkpoint-recovery.md) è ora disponibile
con qualifica dedicata ancora aperta.
