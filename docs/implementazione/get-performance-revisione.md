# GET: revisione indipendente statica del codice e delle misure

Data: 2026-10-11. Checkout esaminato:
`/Users/gpicchiarelli/.codex/worktrees/get-verificato/ArcDocDB`.
Baseline prodotto: commit `65972a4e6e84bd4c31d1d654c9a9a29bf6c44eb0`.

Questa revisione riguarda `src/get` e le interazioni con read, cache, indice,
I/O, record, snapshot ed epoche. Include la lettura degli strumenti della
campagna `2026-10-11-get-performance` disponibili durante l'esame.
La suite funzionale GET dell'altra sessione resta fuori dall'attività di
scrittura di questa revisione.

Sono state effettuate soltanto letture di sorgenti, documentazione, metadati
Git e disassemblato già conservato. Nessuna compilazione, esecuzione Lisp,
suite, benchmark o verifica dinamica. Nessuna modifica del prodotto o degli
strumenti, nessun commit, nessun altro agente. L'unico file scritto da questa
revisione è questo rapporto. Le modifiche concorrenti agli strumenti sono
attribuite alle rispettive attività, senza alterarle.

## Esito della revisione attuale, prima delle prove del padre

Non sono emersi difetti P0/P1 dimostrabili staticamente nel percorso GET
esaminato. Questo esito non certifica la qualifica C1 o l'assenza di difetti
concorrenti. Il difetto P2 del selettore C4 (R1) è corretto staticamente.
R2 è chiuso come scope chiarito dal padre: l'oracolo completo appartiene
intenzionalmente alla finestra. Resta un rilievo P2 sul driver, la perdita
delle metriche del self-test fallito (R3). È confermato staticamente il difetto P2 cache
segnalato dal padre: un tag rifiutato/disabilitato nasconde una copia valida
reinserita (R4). Il fallback preserva il valore GET, ma ripete miss e I/O.
PEF-01–PEF-03 sono osservazioni sui costi, senza severità di bug.

La lettura del benchmark e del metodo è completata sulla variante
`e3d41cac51ab5f060d2a8a9c4f3bb4cf3f17387d` /
`78647ca7a9013d10456219e154a2fa4928ba5e1a`.
La correzione delle due aperture V16 è presente. Il perimetro della misura
è conforme alla decisione esplicita del padre, compreso l'oracolo nel ciclo;
la conservazione delle prove negative del self-test richiede il fix R3 prima
della qualifica benchmark. Questo rapporto conclude la revisione attuale per consentire al
padre di congelare e registrare la riproduzione della baseline; non chiude
la successiva revisione del fix cache. Nessuna scrittura di questo rapporto
durante le prove del padre; ripresa soltanto alla sua richiesta.

## R1 — P2 corretto staticamente: selettore delle evidenze

**Sorgente:** [tools/get-performance-evidence.lisp](../../tools/get-performance-evidence.lisp),
righe 115–131; blob dei byte esaminati
`6e298625a54a18fcc7337df8a4d8dc5dc3a2a86c`.

`publish` ammette tutte le directory di `spikes/out/` il cui nome contiene
`-command-` oppure `-check-`. Questi due rami non richiedono il prefisso
`get-performance`. Per esempio una directory `reader-command-final/` con un
`report.lisp` concluso, schema 1, è ammessa dal medesimo predicato dei comandi
GET. Il catalogo risultante viene etichettato `:scope :get-performance` alle
righe 150–152 e i conteggi includono anche quel record.

La conservazione dei byte e del campo `:source` consente di ricostruirne
l'origine, ma non rende corretta l'attribuzione al perimetro della campagna.
Con directory di lavoro condivise o residui di un'altra sessione, la
pubblicazione può contaminare l'inventario delle prove della baseline.
Non è stato osservato un catalogo contaminato: `spikes/out/` non era presente
al momento dell'ispezione. Il difetto è nel predicato e il controesempio è
dedotto dal codice, senza eseguirlo.

Il padre ha confermato che `spikes/out/` parte vuoto e isolato: non c'è
contaminazione osservata. Ha indicato una correzione prima del freeze con
allowlist chiusa degli argv, distinzione dei report GET dai controlli C4 del
repository, scope esplicito per entry e casi positivi/negativi del selettore.
La variante corretta è stata successivamente letta con blob
`f098cdb4cf5f0447365cf0bf255e1935d04bc53b`: il predicato
`publication-directory-p` (`:111–115`) ammette prefissi propri GET o nomi
esatti nel manifesto. `publication-roots` (`:116–128`) verifica schema,
unicità, quantità e nomi semplici, senza slash. `publish` usa quel predicato
e aggiunge uno scope per entry (`:136–150`); il self-test include il nome
estraneo `reader-command-final`, un check non elencato e un nome comune
esplicito (`:199–207`). Il controesempio originale non è più ammesso dal
predicato quando manca nel manifesto.

**Stato:** il difetto del selettore è corretto staticamente. Non sono stati
eseguiti il self-test o la pubblicazione da questa revisione. Il manifesto
effettivo non era ancora disponibile: attribuzione dei run posseduti e scope
dei report comuni restano da confrontare con quel file quando presente.

**Correzione proposta al padre:** applicare un prefisso esclusivo
`get-performance-` anche ai comandi/check, oppure una lista esplicita dei
comandi comuni ammessi con attribuzione separata. Conservare gli eventuali
tentativi già prodotti; cambiare il selettore prima di usare il catalogo per
descrivere il perimetro concluso. Nessuna correzione applicata qui.

## R2 — chiuso: scope dell'oracolo confermato dal padre

**Sorgente:** `tools/get-performance-bench.lisp:192–250`, blob
`e3d41cac51ab5f060d2a8a9c4f3bb4cf3f17387d`;
`docs/implementazione/get-performance-metodo.md:99–113`, blob
`78647ca7a9013d10456219e154a2fa4928ba5e1a`.

`make-cycle` riempie la risposta di sentinelle e controlla tutti i byte,
sommando il checksum, prima di tornare al loop misurato. `observe` avvolge
quel loop: costo O(V), clock, stati, sentinelle e checksum sono inclusi sia
nel tempo sia nello heap globale. La precedente richiesta di oracolo fuori
finestra aveva prodotto un rilievo di conformità, comunicato prima del freeze.
Il padre l'ha corretta esplicitamente: l'oracolo dentro la finestra è
intenzionale e il metodo attuale è confermato. R2 non è quindi un bug aperto.
Le misure descrivono il ciclo GET verificato, con il suo controllo completo;
non isolano il costo delle primitive o il throughput del database.

## R3 — P2 aperto: perdita delle metriche di un self-test fallito

**Sorgente:** `tools/get-performance-bench.lisp:509–523,622–623`, blob
`e3d41cac51ab5f060d2a8a9c4f3bb4cf3f17387d`;
promessa di conservazione in `get-performance-metodo.md:152–168`.

`product-self-test` accumula le metriche in una lista locale. Scrive
`self-test-metrics.lisp` solo dopo tutti i casi e restituisce il riepilogo
assegnato a `report :self-test` soltanto al ritorno normale. Se `run-loop`
registra un errore GET, `run-window` può produrre una metrica `:failed` con
conteggio parziale, checksum e diagnostica originale. La successiva
`validate-window` solleva invece il generico «finestra incompleta o metriche
incoerenti»: il controllo esce prima della scrittura e dell'assegnazione al
report. La lista locale, compresa la finestra fallita, viene perduta.

Il processo conserva un report failed/exit 1, ma perde i contatori e
l'errore GET originali del self-test. Il ramo `run-bench:588–590` conserva
invece la metrica nel report prima di validarla; il difetto riguarda
l'autoverifica preliminare, eseguita anche da `--bench`.

**Correzione richiesta:** rendere le metriche self-test già possedute dal
report o persistibili sul percorso di unwind prima della validazione;
conservare stato failed, coordinate, contatori e diagnostica della finestra.
Non consumare raw/output di worker non quiescenti per riempire il rapporto.
Il padre ha accettato R3 e indica il fix prima della qualifica benchmark.
Fix ed evidenze saranno riletti alla ripresa; nessuna modifica qui.

## R4 — P2 aperto: un tag cache scartato nasconde la copia riparata

Difetto segnalato dal test agent attraverso il padre e verificato qui
staticamente sulla baseline prodotto.

**Sorgenti:** `src/cache/read.lisp:62–65,84–96`, blob
`1b2e5eb00fe15187b74fe0fb87ebd43a3c8fb726`;
`src/cache/clock.lisp:12–20,40–49`, blob
`5aca4d48de7bf0d849eafe87ae89f6e7800282d8`;
`src/cache/write.lisp:49–56`, blob
`bcd7de80241f809dcfce472741f120a61ac787b4`.

Controesempio senza concorrenza: la prima copia si trova nello slot 0 e la
mano CLOCK è avanzata a 1. La verifica CRC fallisce e marca slot 0 rejected.
Il fallback legge il PUT valido dal file. `gia-in-cache-p` ignora la copia
rejected e l'inserimento può scegliere lo slot 1 vuoto, mantenendo il vecchio
tag nello slot 0. Al GET successivo `cerca-record-cache` vede per primo quel
tag: chiama `copia-posto-cache`, che rifiuta lo slot rejected, e ritorna
immediatamente `:miss`. Non raggiunge la copia valida nello slot 1. Il
reinserimento successivo può tornare `:present`, poiché il writer vede già
la copia valida: il miss e la rilettura del file continuano. Un tag disabled
precedente alla copia valida produce lo stesso oscuramento.

È un difetto dell'acceleratore e della raggiungibilità della copia riparata,
non un requisito trustcontroller. Non autorizza bytes corrotti: il reader
ritorna range zero e GET usa il fallback verificato. Ha però costo concreto
di I/O e CRC ripetuti e impedisce il successivo hit atteso.

**Proposta del padre, ancora non applicata nei bytes esaminati:** filtrare
disabled/rejected prima di `tag-cache-p`, mantenendo i controlli completi
in `copia-posto-cache`. Staticamente la proposta conserva il limite di otto
tag, una sola copia/verifica e nessuna attesa/retry. Il filtro preliminare
non autorizza un hit: la copia deve ancora verificare sequenza pari,
credito, bit di scarto, tag e sequenza stabile, poi CRC/chiave/CSN/prova.
Una lettura conservativa dei bit può perdere un hit; non sostituisce il
seqlock o la prova del record. Il primo `:verify-failed` continua a imporre
fallback e allarme: il filtro riguarda slot già scartati.

**Schema e decisioni:** nessun cambio necessario al layout tag, al record
v1/v2 o alla forma degli esiti cache. In
`docs/implementazione/cache-record.md:187–197` il caso ricade in CCH-D04
(posto leggibile), CCH-D07 (vittima/reinserimento) e CCH-D09
(scarto della copia senza quarantena del file). La correzione deve mantenere
CCH-D05 e CCH-D06, inclusa la prova prepared e il controllo seqlock finale.
La revisione della patch effettiva resta distinta da questa valutazione
della proposta.

**Riproduzione preparata dal padre:**
`tests/get-performance/guards.lisp:137–157`, blob
`9bbf7b2ceb817d6ecf2e7c67b0928373c2c07f70`, controlla v1/v2,
fallback/reinserimento, poi hit senza pread, e un secondo caso disabled.
Nessuna esecuzione o risultato attribuito qui; il padre registra prima il
fallimento baseline e poi il fix. I sorgenti prodotto erano ancora immutati
all'ultima lettura.

## Lettura del percorso GET

| Area | Evidenza localizzata | Esito e limite |
|---|---|---|
| Ammissione | `src/get/lookup.lisp:32–60`; `src/read/task.lisp:24–42` | Stato iniziale e ambito canonico sono controllati prima dell'avvio. Un ingresso EBR non confermato torna `:retry` con cleanup. Hash e lookup sono dentro il confine di abbandono. |
| Snapshot | `src/get/lookup.lisp:13–20`; `src/read/task.lisp:61–77`; `src/mvcc/snapshots-read.lisp:25–74` | CSN corrente sopra `s` e miss primario sotto snapshot diventano `:history-required`. Il risultato con valore richiede copia e controllo snapshot finale con tempo fresco. Il resolver storico resta un'integrazione dichiarata. |
| Fonte | `src/get/build.lisp:38–55`; `src/get/target.lisp:13–32` | L'header viene letto dal file della capacità e confrontato con Serie e ID attesi. Il target deve appartenere alla stessa vista ed essere entro il prefisso committed fornito dal resolver. Non c'è conversione di file size in prova di commit. |
| Prepared | `src/get/segment.lisp:12–42,104–121`; `src/foundation/record.lisp:269–283,306–325` | Offset obbligatorio, prefisso e non sovrapposizione sono controllati. OUTCOME viene letto dal medesimo file e verificato prima della cache; il verificatore comune confronta TXID e CSN. Non viene autorizzato un prepared soltanto perché ha CRC valido. |
| Cache | `src/get/target.lisp:39–53,79–90`; `src/cache/read.lisp:53–65,80–96`; `src/get/segment.lisp:111–122` | Solo un hit verificato imposta il range. `:verify-failed` consente il ripiego sul segmento. La prova letta dal file è verificata fuori dal gestore che converte la corruzione della copia cache in miss. |
| I/O esatto | `src/io/transfer.lisp:32–52`; `src/get/segment.lisp:33–35,53–55` | GET passa range con start zero, coerenti con il ritorno END di `leggi-esatto`. Short I/O viene completato; EOF/errore propaga senza autorizzare bytes parziali. Nessun retry di errore viene aggiunto da GET. |
| Copia e conferma | `src/get/lifecycle.lisp:46–69,75–94` | Output distinto da scratch e chiave; capienza controllata prima della somma. `:copied` resta provvisorio. `concludi-lettura` precede il ritorno del risultato e il cleanup GET precede il ritorno al chiamante. |
| Cleanup | `src/get/lifecycle.lisp:28–42`; `src/read/core.lisp:53–66`; `src/epochs/read.lisp:31–44,48–58` | Il cleanup marca prima `:faulted`, rilascia il pin e azzera range/riferimenti; un contesto già faulted resta terminale. Non sono stati individuati rami ordinari di errore ammesso che saltino il confine esterno di cleanup. |

`copia-candidato-get` (`src/get/lookup.lisp:64–72`) esegue una copia senza
`unwind-protect` proprio. Un'uscita non locale durante questa fase è coperta
dal cleanup del compito esterno, che il contratto richiede di installare
prima di `avvia-get`. Non viene segnalata come perdita del pin con quel
contratto. Anche il rifiuto di un ordine di API invalido prima di acquisire
l'operazione non va trasformato automaticamente in abbandono del compito
attivo di un altro chiamante. Il driver deve rispettare l'ownership del
contesto e scartare qualsiasi risposta dopo un unwind.

## Confini u64 e packedword

- Il CSN e il limite snapshot rimangono word u64 negli scratch. Il confronto
  `CSN <= s` è dichiarato u64 in `src/get/lookup.lisp:15–18`. Il disassemblato
  ARM64 già conservato mostra load di word e confronto unsigned con `BHI`,
  alle righe 2511–2524 di
  [disassemblato-hash-archive.lisp](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-record/disassemblato-hash-archive.lisp).
  Questo supporta quel confronto, non l'assenza di allocazioni dell'intero GET.
- `location` codifica ID segmento u32 alto e offset u32 basso. Il controllo
  `segmento-get-high = 0` in `src/get/target.lisp:21–24` respinge una capacità
  storage u64 non rappresentabile, anche quando la sua parola bassa coincide.
  È un limite del layout v2 dichiarato; non un troncamento silenzioso.
- La word della lunghezza ha la metà alta riservata a zero:
  `src/index/validation.lisp:19–27,31–36`. Il reader valida i campi dopo la
  conferma del seqlock (`src/index/read.lisp:25–33`). Perciò i confronti del
  buffer con l'intera word in `src/get/target.lisp:82` e
  `src/get/segment.lisp:105` sono coerenti con il candidato ammesso.
- Fine PUT e fine OUTCOME sono somme di u32 e dimensioni limitate dal
  formato, entro il fixnum delle piattaforme previste. Non vengono ridotte
  modulo 2^32. Il limite GET/storage è `#xffffffff`, coerente con lo slot;
  il limite più permissivo `#x100000000` dell'API cache non allarga questo
  controllo. I limiti v1/v2 sono derivati dalla versione della capacità.
- I confronti di CSN/TXID letti dal record usano le due u32 in
  `src/get/segment.lisp:38–41,57–61` e
  `src/foundation/record.lisp:269–283,306–325`; non passano per
  `verifica-record`, l'API ispettiva che restituisce uno stamp Lisp u64.
- La capienza di output è verificata per sottrazione prima di costruire END
  (`src/get/lifecycle.lisp:60–66`). Non è emerso un overflow o un range
  autorizzato oltre il buffer per un input che rispetti i tipi dell'API.

## Requisiti trustcontroller, distinti dai bug

| Garanzia affidata al controller/driver | Riferimento | Perché non è un bug dimostrato di GET |
|---|---|---|
| Un unico ambito canonico e registri EBR/snapshot dello stesso Archivio; ID worker esclusivi | `src/get/types.lisp:14–19`; `src/get/build.lisp:20–34`; `src/read/types.lisp:27–33` | I registri non portano un'identità comune verificabile dal modulo. Il check runtime confronta l'ambito già costruito; non può certificare una configurazione originaria errata. |
| Indice, cache e identità appartenenti alla medesima Serie | `src/get/types.lisp:23–30`; `src/get/build.lisp:9–14` | L'indice non ha un'identità storage da confrontare. Il legame iniziale è una precondizione esplicita, distinta dai controlli della capacità segmento. |
| Pubblicazione di soli commit visibili, prefisso committed, flag del record e appartenenza dell'OUTCOME al lotto pubblicato | `src/get/lookup.lisp:1`; `src/get/target.lisp:1–12`; `src/get/segment.lisp:8–11`; `docs/implementazione/get-record.md:100–118` | CRC, header e range non attestano un lotto committed. GET controlla coerenza, identità e bytes a partire dal target autorevole. La produzione di quel target resta da integrare. |
| File/binding vivi e bytes del prefisso immutabili fino al reclaim EBR | `src/get/types.lisp:33–43`; `src/io/types.lisp:28–40` | Una capacità Lisp non impedisce una close concorrente o una modifica esterna. La durata del file è responsabilità del proprietario; non viene aperto/chiuso da GET. |
| Clock fresco e monotono; output privato fino alla conclusione; cleanup prima della migrazione; pool I/O | `src/get/lifecycle.lisp:46–49,75–78`; `src/read/task.lisp:62–76`; `docs/implementazione/get-record.md:55–80,133–138` | È rilevabile una regressione del tempo, non un timestamp vecchio ma crescente. GET non espone una risposta di rete o un scheduler: il driver deve consegnare solo dopo ritorno normale e migrare la richiesta originale. |

L'assenza attuale di resolver storico, prova EDIT/manifest, scheduler e
metriche è un limite di integrazione già dichiarato. Non viene confusa con
un valore scorretto restituito dal sottoinsieme corrente implementato.

## Costi evidenti da attribuire nelle misure

**PEF-01 — verifica ripetuta del PUT anche prima di un inserimento che può
rinunciare.** Nel ramo segmento `src/get/segment.lisp:118–120`,
`leggi-put-get` verifica il PUT e `inserisci-cache-get` richiama l'API pubblica
cache. `src/cache/write.lisp:72–79` verifica di nuovo tutti i bytes prima di
provare il mutex o verificare presenza/disponibilità del posto. Con classe
cache selezionabile, quindi, anche `:busy`, `:present` e `:unavailable`
sostengono la seconda scansione CRC/chiave. È costo O(record-bytes) concreto,
già in parte dichiarato nella documentazione; non un bug di correttezza.
Una misura del ramo segmento con cache disattivata esclude questo costo.
Il padre può valutarne l'ottimizzazione soltanto dopo la baseline, preservando
il contratto di verifica dell'API cache.

**PEF-02 — verifica ripetuta della prova prepared.**
`leggi-prova-get` verifica la cornice OUTCOME prima della cache.
`verifica-put-parole` la verifica nuovamente quando confronta TXID e CSN.
Sul miss, con inserimento in una classe cache, il verificatore cache la
verifica una terza volta. È una prova fissa di 32 byte: il costo è limitato,
ma la misura prepared-hit include almeno un I/O OUTCOME e due verifiche
della prova. Non può essere descritta come hit privo di I/O o equiparata al
prepared con certificato cached, che questa API non implementa.

**PEF-03 — perimetro del percorso e u64 del driver.**
La migrazione calcolo → I/O riesegue ammissione, hash della chiave, lookup e
resolver. Un ciclo che chiama direttamente `leggi-record-get` dopo un solo
`avvia-get` misura il compito nel pool I/O; non misura il costo della
migrazione prevista dal driver. Inoltre `avvia-get` riceve generazione e
NOW come valori Lisp u64, mentre il CSN del candidato/limite resta negli
array. Estrarre una word oltre fixnum per passarla come argomento a una
funzione non inline può materializzare un bignum nel chiamante. È necessario
distinguere valori già preparati fuori misura da boxing ripetuto nella
finestra, senza attribuire automaticamente l'uno al kernel GET.

Non è stata individuata una nuova allocazione esplicita per richiesta nei
sorgenti `src/get`; le allocazioni visibili sono nella costruzione di viste,
capacità e contesti. La precedente assenza di `ALLOC-TRAMP` in dodici
disassemblati non copre tutte le funzioni chiamate né
`copia-candidato-get`/la copia generica `replace`. L'esito zero heap full u64
rimane da misurare; la lettura statica non lo anticipa.

## Attendibilità del benchmark: esame statico completato

Il tool autonomo e il metodo sono stati letti integralmente. Le identità
finali di questa lettura sono rispettivamente
`e3d41cac51ab5f060d2a8a9c4f3bb4cf3f17387d` e
`78647ca7a9013d10456219e154a2fa4928ba5e1a`.
Il driver non carica la suite complementare e non usa il suo observer I/O.

| Confine esaminato | Sorgente del tool | Esito statico |
|---|---|---|
| Aperture V16 | `:123–125,160–166`; `src/io/transfer.lisp:12–15`; `src/get/build.lisp:46–47` | Correzione segnalata dal padre presente in entrambe: `max(64, record-size)`. Con V16 il PUT è 56 B ma l'header è 64 B; il precedente limite 56 avrebbe fermato il setup prima dei GET. |
| Popolamento cache | `:154–158`; `src/cache/write.lisp:15–17,37,49–56` | `:inserted`, evicted NIL e scan NIL sono corretti per otto slot inizialmente vuoti. I due eventi restituiti sono booleani, non conteggi. |
| Esiti nel ciclo | `:213–240` | Esige candidate/absent, hit/disabled, source segment, inserimento non tentato, lunghezza di copia e conclusione, IDLE/EBR libero e risposta completa. Errori non diventano retry o GET completati. |
| Contatori | `:244–250,277–330` | Raw preallocati; completed/checksum aggiornati dopo ritorno normale e cleanup del ciclo. Totali e ogni worker devono uguagliare COUNT e checksum previsto; nessun arrotondamento bytes/op o sottrazione baseline. |
| Heap e tempo | `:254–261,350–353,388–395` | Due letture heap globali del main, tick grezzi, metadati/rate fuori finestra. GC esplicito prima, GC automatico incluso. Ordine tick-start/heap-start/heap-end/tick-end dichiarato. |
| Parallelo | `:354–387` | Closure/semafori/raw/nomi cold; creazione thread, gate, cicli e join dentro la stessa finestra globale. Warmup nel main, senza warmup runtime dei nuovi thread. Heap non attribuito per worker. |
| Quiescenza e ownership | `:180–185,336–346,393–395`; `tests/get-performance/threads.lisp:78–82` | Controller consuma i raw dopo join e controllo dei thread vivi; FD non chiuso se resta un worker vivo. Anche la suite evita close quando stop/join fallisce. Nessuna osservazione del controller sui buffer durante il loop parallelo. |
| Negative/zero tick | `:469–507,608–614` | Campi mancanti, negativi, worker corrotti, rate incoerente, schema mancante/diverso e confine failed/exit 1 sono esplicitamente verificati. Zero tick dà rate NIL e qualità below-resolution. `--negative-fixture` conserva la metrica senza completed e richiede fallimento. |
| Matrice e conservazione | `:545–593` | COUNT 20.000 fisso, 5 repliche, seriale 90 e parallelo 270 finestre, coordinate esatte senza duplicati; campagne conservano la metrica prima della validazione. R3 delimita l'eccezione nel self-test preliminare. |
| Sensore | `:441–467` | Controllo vuoto 20.000 cicli e positivo con quattro array u8 da 1 MiB trattenuti; delta almeno 4 MiB, nessuna sottrazione né gate heap-zero sui GET. Il positivo non certifica la sensibilità a piccole allocazioni o a ogni confine runtime. |
| Persistenza/schema | `:398–419,578–580,640–647` | Schema 1, kind e status richiesti per ogni foglia; budget UTF-8 <1 MiB, rilettura come dati ed uguaglianza. Exit 0 richiede report positivo validato e persistito; R3 resta requisito prima della qualifica. |

### Full u64 e limiti della conclusione

Il massimo `#xffffffffffffffff` viene scritto nel record tramite due u32 e
pubblicato nell'array u64 (`:97–98,138–147`). Nel ciclo il driver non estrae
quel CSN in un valore Lisp generico: passa generazione zero e clock fresco;
il verificatore GET riceve le due parole del candidato. Il profilo massimo
attraversa quindi il percorso corrente. Non copre snapshot, TXID prepared,
generazione/NOW oltre fixnum o ID storage oltre u32, che il metodo esclude.
Non viene anticipato un risultato zero heap dalla tipizzazione dei raw o
dall'assenza di boxing esplicito nel driver.

La finestra comprende fill delle sentinelle, oracolo completo O(V), checksum,
clock per GET, stati, cleanup e contatori, come confermato dal padre in R2.
Nel parallelo include startup e join: il rate aggregato non misura un pool
persistente. File piccoli e page cache riscaldata non qualificano NVMe,
latenza/P99 o throughput DB. Il caso segmento ha cache disattivata, quindi
esclude PEF-01; prepared e migrazione sono esclusi. Le cinque repliche e i
delta globali non consentono attribuzione di allocazioni a una componente.
Questi confini sono espliciti nel metodo e nei `:limits` del report.

### Pubblicazione C4 e responsabilità del padre

R1 è corretto nel collector con blob
`f098cdb4cf5f0447365cf0bf255e1935d04bc53b`: le tre foglie benchmark/self-test
sono selezionabili; i record comuni richiedono un nome esatto nel manifesto
dati e ricevono scope `:explicit-command-or-repository-check` se il nome
contiene `-command-`/`-check-`. Non sono prove isolate del prodotto GET.
Il self-test contiene nomi positivo, prefix estraneo negativo e common
unlisted negativo. Il manifesto è conservato nel catalogo con digest raw.

All'ultima lettura non era presente `publication-roots.lisp`: non sono
certificati nomi/argv di run futuri. Il padre ne possiede la generazione da
run realmente posseduti e conclusi, con allowlist di tools get-performance,
coverage scope get-performance e make check-core/controlli globali C4
esplicitamente attribuiti. Il collector verifica schema e nomi del manifesto,
non l'ownership o la semantica degli argv. Questa è una garanzia del
controller della campagna, distinta dal difetto del selettore già corretto.
SPK/repo-check restano evidenze del repository con scope esplicito.
`record-command.lisp:80–99` conserva argv e confronto sorgenti prima/dopo:
`source-consistency :stable` e blob effettivi sono da leggere nelle prove
registrate dal padre, senza eseguire nulla da questa revisione.

### Fixture complementare disponibile durante la revisione

È stata letta la variante di `tests/get-performance/support.lisp` con blob
`a92bf7f3161f611db32272a03018cf63214d9954`. La costruzione indipendente dei
bytes/CRC avviene nel setup (`:61–96,168–259`), prima della misura. Il backend
osservato (`:102–110`) usa mutex e liste per ogni pread: il benchmark deve
selezionare `:observe-io-p nil`, come previsto dal contratto della fixture.
`performance-checked-get` (`:300–340`) è esplicitamente un driver di
correttezza: alloca scratch candidato e liste per gli esiti ed esegue gli
oracoli. Non è un kernel per la misura zero heap.

La fixture consente CSN fino a `#xffffffffffffffff`, mantiene generazione
snapshot e NOW separati dal CSN e usa il clock controllato 10/11/12. Una
misura che la riusa deve dichiarare quel clock artificiale, il singolo
documento/segmento e l'assenza di prepared nella fixture attualmente letta.
Nessun risultato heap viene inferito dalla sola fixture; il driver autonomo
del benchmark è esaminato separatamente sopra.

È stata inoltre letta la variante successiva del supporto
`f7eac312809b34fa72dcd3b9a8b67d290cb08cd6`, che aggiunge il controllo dello
stato terminale e il percorso `:cache-record`, insieme a `paths.lisp`
(`160dae42a9723e9b0e93a085864affa96a4cd6be`) e `guards.lisp`
(`76157fb9424d4cf47847f2cec10c5bbcb977246b`). Le verifiche full u64 confrontano
anche uno stamp differente nei bit 0/63 con CRC validi. Il controllo numerico
snapshot è eseguito dopo il GET dal driver di correttezza, come dichiara il
sorgente; non è una prova delle allocazioni del ciclo prestazionale.
La variante del test di riparazione cache è localizzata in R4. La suite
rimane complementare alla campagna funzionale dell'altra sessione.

## Identità dei sorgenti esaminati

I blob nella tabella sono le identità Git dei bytes, senza scrittura di
oggetti (`hash-object` senza `-w` per i file di lavoro). Il prodotto era
identico alla baseline nelle verifiche readonly effettuate. Per gli
strumenti in lavorazione, il blob identifica la variante letta e non implica
che sia già committed o definitiva.

| Sorgente | Blob Git |
|---|---|
| `src/get/package.lisp` | `a22de99a63db56417822bb5e66f82e5c89d73bc2` |
| `src/get/types.lisp` | `032ad088b19ec3498a7c80a5e4b96d7777257dad` |
| `src/get/build.lisp` | `cb426426eac6e923224bc57c1dd602405f4bc040` |
| `src/get/lookup.lisp` | `5a105a141b43f5585f8e79c2965d59e96cd35ac6` |
| `src/get/target.lisp` | `c9b8488d0a1aa7643a6ab1570765ec870aa7c9e4` |
| `src/get/segment.lisp` | `cf168c44bfe5aedd2e34180ce4f766a6a89500a7` |
| `src/get/lifecycle.lisp` | `23f16c3039b71be0bd46d6bf92f05791e444683e` |
| `src/read/types.lisp` | `b30795fb7efad5f5313198d345ffabb43249e3fa` |
| `src/read/core.lisp` | `132e44c138e209d3f8840b098cca0424853d09c3` |
| `src/read/task.lisp` | `b3601060197a27c6e8a2aaee22b5576c6b0c6e5a` |
| `src/cache/core.lisp` | `9ab280c17b61b8f98f8299cbfae676942bb3ae47` |
| `src/cache/read.lisp` | `1b2e5eb00fe15187b74fe0fb87ebd43a3c8fb726` |
| `src/cache/clock.lisp` | `5aca4d48de7bf0d849eafe87ae89f6e7800282d8` |
| `src/cache/write.lisp` | `bcd7de80241f809dcfce472741f120a61ac787b4` |
| `src/index/read.lisp` | `abfdeb5397f8be1d390cbdf47f4f02cd2f36bf91` |
| `src/index/validation.lisp` | `a8088783354d2e4e5048d6ac7a3bee7afff92719` |
| `src/index/primary-read.lisp` | `b5b8243bc40b44af8c34ba76a5ab732675690af5` |
| `src/index/primary-probe.lisp` | `f36b55b9e2d9002ed2ce203a0289c92984c89ac9` |
| `src/index/primary-write.lisp` | `5db1d132d91fa11be2b2624ed4c0c8d5405ce591` |
| `src/index/hash-seed.lisp` | `5627b4179b115c008379aa3e60a4724e63f9657b` |
| `src/io/types.lisp` | `b496c1df87108127da568a1fb7b0fd32856afcc5` |
| `src/io/transfer.lisp` | `93acbd608b1af475aa505a6a7dedceb3b15e8d4b` |
| `src/io/native.lisp` | `1b6fe64ea7145f33bcf08c02e8550034ebd6a40c` |
| `src/foundation/record.lisp` | `09185339cab38ab937045b40c52bb1b9092ffb8e` |
| `src/foundation/crc32c.lisp` | `f9c691d28620427099d1d89a89a1ff5d04cbe257` |
| `src/mvcc/snapshots-read.lisp` | `09d73425a6e571c8fac6669b14b98e3ceeb7c96b` |
| `src/epochs/read.lisp` | `a3dfde4a4780554b88e6e037ab4f70731f9c884a` |
| `src/storage/formats.lisp` | `fc942f1c8e30e637abaf13dc26343d40417fc72f` |
| `src/storage/segment-header.lisp` | `f1d99b205b1ea5e6ad059ecd7971d3633411b040` |
| `docs/implementazione/get-record.md` | `07c59c267cac478c83ee2ab9d164cd7e1d0754f6` |
| `tools/get-performance-evidence.lisp` (lavoro) | `6e298625a54a18fcc7337df8a4d8dc5dc3a2a86c` |
| `tools/get-performance-evidence.lisp` (successiva variante, stesso selettore R1) | `dfaf5aabea2a58b95701da7d1f2431d791b77dc5` |
| `tools/get-performance-evidence.lisp` (selettore R1 corretto) | `f098cdb4cf5f0447365cf0bf255e1935d04bc53b` |
| `tools/get-performance-bench.lisp` (variante esaminata completa, max-transfer corretto) | `e3d41cac51ab5f060d2a8a9c4f3bb4cf3f17387d` |
| `docs/implementazione/get-performance-metodo.md` (variante esaminata completa) | `78647ca7a9013d10456219e154a2fa4928ba5e1a` |
| `tools/record-command.lisp` | `2e7364821e345b8b8714856a6a2f03c684140320` |
| `docs/implementazione/cache-record.md` | `bd3a4f9fc7a2136b068957bba9307dd4737fb539` |
| `tools/foundation-coverage.lisp` (lavoro) | `18d63b375401a58062752e7b4db43ad6be70a2ed` |
| `tests/get-performance/support.lisp` (lavoro) | `a92bf7f3161f611db32272a03018cf63214d9954` |
| `tests/get-performance/support.lisp` (variante successiva) | `f7eac312809b34fa72dcd3b9a8b67d290cb08cd6` |
| `tests/get-performance/paths.lisp` (lavoro) | `160dae42a9723e9b0e93a085864affa96a4cd6be` |
| `tests/get-performance/guards.lisp` (lavoro) | `76157fb9424d4cf47847f2cec10c5bbcb977246b` |
| `tests/get-performance/guards.lisp` (riproduzione cache-repair-hit) | `9bbf7b2ceb817d6ecf2e7c67b0928373c2c07f70` |
| `tests/get-performance/threads.lisp` (cleanup quiescenza) | `5780e3ef9c9e34a4098ddbd72e19cebfa6a34edd` |
| `spikes/results/2026-10-11-get-performance/README.md` (lavoro) | `050abf32446e1ca18603f5a0ac1e91494428dd05` |
| `spikes/results/2026-10-11-get-record/disassemblato-hash-archive.lisp` | `9910cd7902ab213f310e52225cfb29e579ca3f02` |

La lettura del disassemblato e delle due letture dell'autore è materiale di
supporto preesistente, non una nuova esecuzione o misura. Nessuna evidenza
della campagna funzionale dell'altra sessione viene attribuita a questa
revisione.

## Addendum definitivo: rilettura statica R3/R4

Questo addendum sostituisce gli stati aperti R3/R4 riportati sopra.
**R3 corretto staticamente:** `tools/get-performance-bench.lisp:509–532,631–644`,
blob `be5fc283b3c06bc60548ea32c240ebf8d9ecafc2`.
Ogni metrica è copiata e persistita prima di validate-window; il gestore salva
stato failed e diagnostica e rilancia la stessa condizione. --negative-self-test
toglie completed alla prima finestra prima della persistenza; il percorso normale
non attiva l'iniezione. La persistenza resta fuori dalle finestre misurate.
**R4 corretto staticamente:** `src/cache/read.lisp:89–100`,
blob `5f4f08a4609bd264fa058ec25ba8f6a516c162c8`.
Il predicato salta disabled/rejected prima del tag; copia-posto-cache conserva
entrambe le guardie, seqlock e verifica successiva. Restano otto way, una copia,
fallback su verify-failed e schema/esiti invariati; nessuna allocazione aggiunta.
**Mutante 7 coerente:** `tools/get-performance-mutation.lisp:86–94`,
blob `231cb906b55b9c92905deefc112f7baebecbd4af`: rimuove il prefiltro rejected
e ripristina l'oscuramento della copia riparata nel test nominato.
R2 resta chiuso come scope chiarito: oracolo completo dentro tempo/heap.
Esito finale statico favorevole alle patch; nessun run né risultato dinamico anticipato.
