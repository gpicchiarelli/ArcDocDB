# Percorso GET: candidato, cache e record verificato

Il modulo [`arcdocdb.get`](../../src/get/) collega indice primario, contesto
di lettura, cache e I/O readonly. Implementa la lettura di un PUT corrente
committed, anche quando tale versione è visibile a uno snapshot. La risposta
rimane privata fino alla verifica snapshot finale e al rilascio EBR.

Non è ancora un endpoint del server. Il [resolver CLOSED](get-resolver.md)
collega manifest e prove sul file; la [directory CLOSED](get-directory.md)
seleziona il segmento del candidato. Il [resolver ACTIVE ordinario](get-active.md)
acquisisce le pagine dalla radice pubblicata della Serie. Prove ACTIVE multiserie,
pubblicazione della directory complessiva della Serie,
ricerca delle versioni trattenute, lifecycle del seme, pool e protocollo restano da collegare.
I requisiti restano **progettati**: compilazione e letture statiche non chiudono
la qualifica C1. Il modulo non modifica formato, isolamento o decisioni ADR.

Riferimenti: [ADR-0038](../adr/0038-orizzonte-di-visibilita.md),
[ADR-0044](../adr/0044-cache-acceleratore-puro.md),
[ADR-0045](../adr/0045-modello-di-esecuzione.md),
[ADR-0047](../adr/0047-verifica-csn-dei-record-prepared.md),
[indice primario](indice-primario.md), [cache](cache-record.md),
[compiti di lettura](compiti-lettura.md).

## Proprietari e configurazione

- Un `ambito-get` associa dominio EBR e registro snapshot dello stesso Archivio.
  Il controller costruisce una sola identità canonica, prima dei pool. Viste
  e worker la condividono: `avvia-get` rifiuta un'altra identità prima del pin.
- Una `vista-get-serie` lega indice, cache opzionale e copia dell'identità
  canonica della Serie. Il controller deve associare i tre dati correttamente;
  il modulo non può dedurlo da un indice privo di identità storage.
  `avvia-get` calcola il digest tramite il [seme posseduto dall'indice](hash-chiavi.md),
  senza accettare digest forniti dalla richiesta. Un seme assente viene rifiutato.
- Un `segmento-get` lega la vista a un file readonly. La costruzione legge
  l'header **dal medesimo file**, verifica CRC, identità Serie/segmento e
  formato, poi conserva campi immutabili. Si esegue nel pool I/O, fuori GET.
- Un `contesto-get` appartiene a un worker e a un Archivio. Possiede contesto
  EBR/snapshot, scratch indice, cinque word del candidato, limite snapshot,
  buffer record e prova OUTCOME. Non appartiene a una richiesta o a una Serie.

Il controller mantiene file e binding aperti fino al reclaim autorizzato
dall'EBR. Un riferimento Lisp alla capacità non sostituisce questa garanzia.
La costruzione non certifica il prefisso committed né la salute della Serie.

`crea-contesto-get(ambito, worker-id, :record-bytes B, :budget-payload P)`
controlla `1 ≤ B ≤ 16.842.775` e `B + 152 ≤ P` prima delle allocazioni.
Default: 65.536 byte record e 65.688 byte payload. I 152 byte comprendono
scratch indice 40, candidato 40, snapshot 8, contesto read 32 e prova 32.
`payload-contesto-get` restituisce questo payload, **non RSS**: oggetti,
header, EBR, registri, vista, cache, risposta e GC sono esclusi.

Una versione più grande del buffer produce `:buffer-required` prima di
qualsiasi I/O del record/prova. Il driver deve assegnare un worker con scratch
adeguato e rieseguire la richiesta originale. Non è un limite documentale
aggiuntivo; il driver deve prevedere anche la capacità massima del formato.

## Contratto del compito

Il confine installa `unwind-protect` con `abbandona-get` **prima** di avviare
il compito. Chiave e richiesta restano stabili ed esclusive fino alla fine.
Nessun accessor di scratch è esportato. Non usare il contesto su due worker,
non annidare una richiesta sullo stesso contesto, non inviare dati in rete
dentro la sezione EBR.

| Operazione | Esito e responsabilità |
|---|---|
| `avvia-get(ctx, vista, chiave, snapshot, generazione, now)` | Un tentativo EBR, hash con seme della Serie e lookup primario con budget di otto. `:candidate`, `:absent`, `:history-required`, `:retry` sono provvisori. `:retry` con stato `:idle` indica mancata ammissione, senza pin. |
| `copia-candidato-get(ctx, cinque-u64)` | Copia le word del candidato dentro lo stesso compito EBR, per il resolver. Nessuna location attraversa una coda. |
| `sonda-cache-get(ctx, segmento, valid-bytes, flags)` | Nessun I/O. `:hit` lascia `:verified`; `:miss`, `:verify-failed`, `:disabled`, `:proof-required`, `:buffer-required` lasciano `:candidate`. |
| `leggi-record-get(ctx, segmento, valid-bytes, flags, :outcome-offset …)` | Solo pool I/O, dopo un nuovo lookup. Restituisce fonte, esito cache, esito inserimento, espulsione e scan. Fonte `:cache`/`:segment` lascia `:verified`; `:buffer-required` non legge e lascia `:candidate`. |
| `copia-valore-get(ctx, risposta, start)` | Copia il valore nella risposta privata, lascia `:copied`, restituisce fine output. La copia non è ancora consegnabile. |
| `concludi-get(ctx, now-fresco)` | Dopo la copia e ogni accesso: controlla snapshot e rilascia EBR prima di restituire `:found` e lunghezza. `:absent`, `:history-required`, `:retry` hanno lunghezza zero. |
| `abbandona-get(ctx)` | Cleanup idempotente in `:idle`; scarta riferimenti, candidato e range. Non autorizza una risposta. `:faulted` resta terminale. |

Un errore di precondizione/ordine viene respinto prima di prendere possesso
dell'operazione: non deve liberare il compito eventualmente già attivo di un
chiamante annidato. Il cleanup esterno resta obbligatorio. Dopo l'ammissione,
errori/uscite non locali delle fasi operative liberano il pin. Un'interruzione
del cleanup rende il contesto terminale; il controller lo isola.

Lo scratch record/prova non viene azzerato a ogni richiesta. Rimane privato,
e i byte precedenti non sono leggibili tramite API: stato e range validi
vengono azzerati. Qualsiasi errore o uscita non locale invalida anche la copia
nella risposta; solo il ritorno normale di `concludi-get` la autorizza.

## Visibilità e ricerca storica

GET corrente non attende H: l'indice deve pubblicare soltanto commit visibili
secondo il contratto del controller. Con snapshot, `avvia-lettura` verifica
identità, generazione, attivazione e deadline, e cattura `s` sotto EBR.

- Candidato corrente con `CSN ≤ s`: leggibile nello snapshot.
- Candidato con `CSN > s`: `:history-required`.
- Miss primario con snapshot: `:history-required`, perché una cancellazione
  successiva a `s` potrebbe aver rimosso una versione da trattenere.
- Miss primario senza snapshot: `:absent`, da confermare con `concludi-get`.

Il driver conclude il compito anche per gli esiti senza valore. Non può
trasformare `:history-required` in un miss. Il futuro resolver storico deve
provare l'assenza e ripetere i controlli snapshot. Non è implementato qui.

## Fonte autorevole, cache e prepared

Il resolver fornisce, sotto la stessa epoca, capacità del segmento, frontiera
committed `valid-bytes` e flag **del record**. Il flag LIVE dello slot indice
non è PREPARED. File size, hint e cache non determinano la frontiera.
Il modulo controlla vista canonica, identità segmento, offset dopo l'header,
fine entro prefisso, limiti del formato effettivo e flag PUT ammessi.

Gli slot v2 rappresentano l'ID segmento in 32 bit: la capacità deve avere
parola alta zero e parola bassa uguale al candidato. Non si tronca un ID
storage u64 per farlo coincidere. Il limite di rappresentazione è quello
già documentato nel [payload v2](slot-indice-v2.md).

Nel pool di calcolo, un prepared restituisce `:proof-required`. Nel pool I/O
la tabella autorevole deve fornire l'offset dell'OUTCOME nel medesimo segmento
e prefisso committed. Non basta che l'OUTCOME abbia CRC valido o che esista nel
file: il resolver deve certificarne l'appartenenza al lotto pubblicato.
Il modulo legge la prova dallo stesso FD, ne controlla cornice, tipo e CSN
prima del sondaggio cache. Il verificatore comune confronta poi TXID del PUT
con quello della prova e CSN con quello del candidato. Un prepared in un
segmento di origine compaction è un'invariante violata.

Un hit cache ordinario non esegue I/O. Un hit prepared nel pool I/O richiede
la lettura della prova; la cache non conserva un certificato di commit.
Una `:verify-failed` della copia richiede allarme/metrica e lettura del PUT
dal segmento. Corruzione della prova o dei byte letti dal file propaga come
guasto della sorgente, senza essere nascosta come miss cache.
La variante che risolve la prova dagli esiti EDIT del manifest resta aperta.

Il PUT letto viene verificato prima dell'inserimento opportunistico. Contesa,
bypass e indisponibilità della cache non attendono. L'inserimento ricontrolla
l'input con l'API pubblica della cache: costo CRC aggiuntivo da misurare.
Gli enum e i booleani permettono metriche locali del worker; aggregazione e
allarme sono compiti del driver, senza contatori globali per operazione.

## Migrazione e costi

Su miss/prova necessaria/buffer insufficiente, il worker di calcolo abbandona
il contesto e accoda solo la richiesta originale. Il worker I/O riparte da
`avvia-get`, riesegue il resolver e ricontrolla la cache. Nessun FD, location,
prova o pin migra. La lettura bloccante esiste soltanto nel pool I/O.

Lavoro limitato dalla chiave di massimo 65.535 byte, dai budget esistenti dell'indice, dagli otto posti cache, da
un PUT entro il limite formato e da una prova fissa. Nessuna nuova coda,
retry infinito, mutex di Archivio sul GET, oggetto per entry o scrittura fra
Serie. Le copie sono record → scratch → risposta, con verifiche CRC esplicite.
Le misure del nucleo corrente sono raccolte nella [campagna prestazioni GET](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-performance/README.md),
con [metodo preregistrato](get-performance-metodo.md). Il rapporto distingue heap
globale, finestre seriali e gruppi paralleli; non misura la latenza del server.
La [campagna di isolamento dei costi](get-costi-risultati.md) distingue CRC,
copie e oracolo e misura la lookup fino a 4,19 milioni di chiavi; non cambia
il percorso prodotto o le garanzie di progresso dichiarate.

## Decisioni C1 e qualifica aperta

| ID | Decisione composta | Copertura richiesta |
|---|---|---|
| GET-D01 | Configurazione, capienza payload e identità della vista | Ogni limite, budget insufficiente prima di allocare, copie identità |
| GET-D02 | Stato iniziale, Archivio canonico, alias chiave e residui del worker | Rientro, altro Archivio, contesti faulted, residui e cleanup interrotto |
| GET-D03 | Snapshot presente, CSN candidato rispetto a s e miss | Limiti CSN, cancellazione dopo snapshot, H e scadenza |
| GET-D04 | Proprietario/ID/offset/frontiera/formato/flag del target | Ogni campo discordante, parola alta ID, v1/v2, limiti estremi |
| GET-D05 | Buffer insufficiente o prova necessaria | Nessuna syscall nel calcolo; nessun I/O con scratch insufficiente |
| GET-D06 | Prova prepared obbligatoria, range e non sovrapposizione | Assente/inattesa, fuori prefisso, overlap, prova in altro segmento/lotto |
| GET-D07 | OUTCOME: cornice/tipo/flag/CSN e TXID contro PUT | Ogni discordanza e bit alto; corruzione persistente distinta da cache |
| GET-D08 | Hit/miss/errore cache e inserimento opportunistico | Cache disattivata, contesa, input corrotto, fallback e metriche |
| GET-D09 | Range/alias output e conferma finale | Copia interrotta, scadenza dopo copia, errore su miss, no dati dopo unwind |

Evidenze statiche nella [campagna GET](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-record/README.md).
La [prima verifica funzionale](get-verifica.md) registra una campagna distinta,
con esiti e ambito propri; non sostituisce le evidenze statiche precedenti.
Restano qualifica C1 condizione per condizione, stress concorrente, fault
injection, misure di allocazione e prestazioni; integrazioni con resolver,
retention, scheduler, metriche e protocollo. Le due letture della sola campagna statica
sono dell'autore; la prima campagna funzionale registra anche una revisione indipendente. La
[revisione indipendente](get-performance-revisione.md) e le
[prove di prestazione e stress](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-performance/README.md)
hanno ambiti espliciti e non chiudono la qualifica completa C1.
