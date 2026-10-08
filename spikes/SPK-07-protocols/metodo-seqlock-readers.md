# Metodo preregistrato: due reader seqlock, due slot, memoria SC

Registrato il 2026-10-08 prima di compilazioni e controlli di questo modulo.
Fase 0, Common Lisp/SBCL, `safety 3`; warning e style-warning sono errori.
Requisiti esistenti: REQ-IDX-003 (tuple coerenti, tentativi limitati e fallback),
REQ-CON-001 (writer unico), REQ-VAL-001 (esperimenti riproducibili).
Riferimenti: piano SPK-07 e ADR-0032; il limite sperimentale è **due** tentativi,
mentre ADR-0032 propone otto. Nessun codice di produzione o benchmark.

## Dominio e scheduling

Un writer, due reader identificati 0 e 1, due slot identificati 0 e 1.
Ogni reader esegue una sola operazione, su un solo slot, invocata nello stato
iniziale. Le assegnazioni sono `(0 0)`, `(1 1)`, `(0 1)`, `(1 0)`.
Il writer aggiorna una volta ciascuno slot, negli ordini `(0 1)` e `(1 0)`:
otto grafi corretti distinti, senza riduzione per simmetria.

Ogni aggiornamento consiste in quattro azioni: seq dispari, version,
location, seq pari e pubblicazione dell'evento nella storia logica.
`location` è un registro astratto atomico completo (segmento, offset,
lunghezza, chiave). I tre registri seq/version/location sono separati.
Le tuple iniziali e finali usano dati espliciti distinti, non un checksum.
Seq appartiene a `{0,1,2}`; generazione a `{0,1}`; nessun wrap o ABA.
Gli identificatori degli eventi logici sono distinti dai registri fisici.

Un tentativo reader legge seq iniziale; se dispari, rifiuta subito.
Altrimenti legge version, location, seq finale, poi valida uguaglianza e
parità. Il primo rifiuto avvia il secondo tentativo; il secondo inoltra
la richiesta al writer. Il servizio di fallback è un'azione del writer
abilitata solo tra aggiornamenti completi (pc 0, 4, 8): copia una tuple
intera, risponde e termina l'operazione. Il writer sceglie esplicitamente
fra aggiornamento successivo e richieste pendenti, una per azione.

Ogni arco sceglie un'azione abilitata del writer o di uno dei due reader.
Le azioni sono SC e indivisibili. Sono enumerati tutti gli interleaving
di queste azioni; le sospensioni sono rappresentate dalla scelta degli
altri attori, senza archi di stuttering. Nessun accorpamento dei reader.

Hit/miss: per ogni tuple accettata si controllano tre query per slot:
chiave iniziale, chiave sostitutiva, chiave sempre assente. Questa
fattorizzazione è esatta nel modello: la query interviene soltanto nella
decodifica della risposta, senza cambiare registri, passi o scheduling.
Si richiedono testimoni di hit e miss per entrambe le chiavi variabili,
oltre al miss permanente, per ciascun reader in ciascun grafo.
Non si modella il sondaggio di una tabella hash, la directory o uno
snapshot atomico fra slot: ogni risposta riguarda esclusivamente uno slot.

## Oracolo, mutanti e criteri preregistrati

Si riusano `ARCDOCDB.SPK07::EXPLORE` e `::REQUIRE-OUTCOME` del core.
Il core viene compilato e caricato prima del modulo.
L'oracolo viene chiamato per ogni stato estratto dalla BFS, anche quando
nessun reader ha ancora risposto. Ricostruisce dalla storia logica le
tuple attese usando dati dichiarati separatamente dalle scritture del
modello; controlla prefisso degli eventi, registri degli slot stabili,
domini, tentativi e ogni risposta conservata nello stato.

Ogni risposta porta una generazione, version, location e il prefisso
logico al suo punto di linearizzazione: lettura seq finale per il
percorso ottimistico, copia del writer per il fallback. Si confrontano
tutti i campi con l'oracolo a quel prefisso e si verifica che sia un
prefisso della storia corrente. Il calcolo indipendente delle risposte
hit/miss usa i record logici. Una risposta vecchia può restare valida
dopo una pubblicazione successiva: l'oracolo usa il punto registrato,
senza richiedere erroneamente la versione corrente alla risposta.

Per ciascuno degli otto scenari si esplorano mutanti diretti:
writer senza odd in ciascuno slot letto; reader 0 o 1 senza validazione finale.
Sono 28 grafi negativi: tre per scenario con slot comune, quattro con
slot distinti. Una mutazione su uno slot mai letto non potrebbe produrre
una tuple accettata scorretta: non viene contata come mutante rilevabile.
Ogni mutante deve produrre una `:accepted-tuple-mismatch`, con slot o
reader corrispondente al bersaglio, tuple osservata/attesa e percorso.
Una violazione generica o la sola assenza di validazione non basta.

Nei grafi corretti si richiedono testimoni per entrambi i reader di:
retry, successo al secondo tentativo, richiesta di fallback e servizio
concluso; inoltre completamento di entrambi via fallback, generazioni
0 e 1, hit/miss dichiarati. Si conserva il cammino BFS verso ciascuno.
Si controlla un rango strettamente crescente su ogni arco; il massimo
è 36. Si ricostruiscono gli archi inversi e si verifica che **ogni stato**
raggiunga un terminale con writer e reader conclusi. Terminali bloccati
incompleti o stati senza cammino di completamento sono errori.

Tetto rigido **200000 stati per grafo**, parametro riducibile, mai
aumentabile. Raggiungere il tetto è un errore, anche prima del tentativo
di inserire lo stato successivo. Non si converte l'esaurimento in un
risultato positivo. Un tentativo separato con tetto 32 deve fallire e
conservare il record del fallimento. Nessuna ricerca casuale o seme.

Safety è la coerenza delle tuple in ogni stato raggiunto. I testimoni
positivi dimostrano reachability. La completabilità universale riguarda
il grafo finito senza stuttering; progressi reali richiedono che attori
abilitati siano prima o poi schedulati. Due tentativi e rango 36 limitano
il lavoro astratto, non il tempo trascorso durante sospensioni esterne.
Non è una prova hardware, delle barriere SBCL o della memoria debole,
né una prova per writer infiniti, più operazioni o wrap del contatore.

## Registrazione e consegna

Solo `seqlock-readers.lisp`, questo metodo e nuovi file ignored in
`spikes/SPK-07-protocols/out/` e `spikes/out/`. Nessun commit/push.
Il runner locale e i report dati sono nuovi artefatti sotto `out/`;
nessuna integrazione o modifica di core, suite, runner o tools esistenti.

Ogni tentativo compile/check usa il wrapper `tools/record-command.lisp`
con argv esplicito e stdin vuoto. Il runner salva inoltre un record
schema 1 con argv/stdin, ambiente, contenuti sorgenti prima/dopo,
risultati decodificati, stdout/stderr integrali, limiti e fasi di
compilazione. Anche fallimenti e tentativi correttivi devono conservarsi.
I report del modulo riportano conteggi per grafo e cumulativi, chiamate
all'oracolo, testimoni, controesempi e controllo di completabilità.
La consegna elencherà tutti i tentativi, percorsi, conteggi e limiti.

## Risultati

Esecuzioni nel checkout isolato
`/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB`.
SBCL 2.6.9, Darwin 27.0.0 ARM64, Apple M4, 16 GiB, 10 CPU logiche;
carico esterno non controllato. Seme assente. Questi sono controlli
logici, senza misure di prestazioni o benchmark.

| Ordine writer | Slot reader 0 / 1 | Stati e chiamate oracolo | Archi | Terminali |
|---|---|---:|---:|---:|
| 0, 1 | 0 / 0 | 5961 | 14385 | 49 |
| 0, 1 | 1 / 1 | 1938 | 4057 | 25 |
| 0, 1 | 0 / 1 | 3159 | 7053 | 35 |
| 0, 1 | 1 / 0 | 3159 | 7053 | 35 |
| 1, 0 | 0 / 0 | 1938 | 4057 | 25 |
| 1, 0 | 1 / 1 | 5961 | 14385 | 49 |
| 1, 0 | 0 / 1 | 3159 | 7053 | 35 |
| 1, 0 | 1 / 0 | 3159 | 7053 | 35 |

Totale corretto: **28434 stati**, **65096 archi**, **28434 chiamate
all'oracolo**, 288 terminali. Tutti gli stati raggiungono un terminale
completo; zero deadlock e violazioni. Sono conservati 24 testimoni per
grafo, **192** complessivi, compresi retry, secondo tentativo riuscito,
richiesta/servizio di fallback di entrambi i reader, hit/miss e generazioni.
8240 controlli di tuple accettate e 24720 controlli delle risposte alle query;
sono conteggi di controlli negli stati, non di operazioni distinte.

I **28 mutanti** vengono tutti rilevati con `:accepted-tuple-mismatch`:
14994 stati scoperti, 28238 archi, 10222 stati effettivamente visitati
dall'oracolo prima dei controesempi; 1080 controlli di tuple e 3156
controlli di query realmente eseguiti. Le BFS negative si fermano alla
prima violazione e non sono esplorazioni esaustive del grafo mutante.
Il massimo fra tutti i grafi è **5961 stati**, inferiore al tetto 200000.
I contatori di controlli sulle risposte nella versione finale avanzano
all'interno dell'oracolo, fino al punto effettivo di interruzione.

Esempio specifico: saltando odd nello slot 0, il reader accetta
`(0 47 (:seg-a 13 9 :alpha))`, mentre la storia impone
`(0 11 (:seg-a 13 9 :alpha))`: version nuova, location e generazione
vecchie. Saltando la validazione finale del reader 0 o 1 si ottiene lo
stesso tipo di tuple mista, con bersaglio distinto e cammino riproducibile.
I testimoni annotano esplicitamente `:odd-skipped` o `:validation-skipped`.

Tutti i tentativi hanno stdin vuoto e sono elencati sotto; `record.lisp`
contiene contenuti/hash prima e dopo, argv, ambiente, dati decodificati
e stdout/stderr integrali. `data.lisp` contiene fasi compile/check,
conteggi, testimoni, limiti ed eventuale fallimento del processo figlio.

| Tentativo | Tetto | Esito e motivo |
|---|---:|---|
| [001](../results/2026-10-08-avanzamento/seqlock-readers-campaign-portable.lisp) | 200000 | Core compilato; modulo fallito per parentesi mancante nella forma `run-graph`; CHECK non avviato. |
| [002](../results/2026-10-08-avanzamento/seqlock-readers-campaign-portable.lisp) | 200000 | Compile rigoroso e CHECK `:ok`, 8 grafi corretti e 28 controesempi. |
| [003](../results/2026-10-08-avanzamento/seqlock-readers-campaign-portable.lisp) | 32 | Compilazioni riuscite; errore atteso al raggiungimento di 32 stati. Il diagnostico precede l'aggiunta dei contatori strutturati del budget. |
| [004](../results/2026-10-08-avanzamento/seqlock-readers-campaign-portable.lisp) | 200000 | Compile/CHECK `:ok` dopo l'aggiunta della condizione con dati di budget e annotazioni dei passi mutanti. |
| [005](../results/2026-10-08-avanzamento/seqlock-readers-campaign-portable.lisp) | 32 | Errore atteso: 32 stati, 13 chiamate oracolo, 39 archi enumerati. Ulteriore errore del registratore nel decodificare il simbolo qualificato della condizione: il processo padre non conosceva il package. Dati e output grezzi conservati; decodifica integrativa nel catalogo. |
| [006](../results/2026-10-08-avanzamento/seqlock-readers-campaign-portable.lisp) | 32 | Compilazioni riuscite; errore atteso a 32 stati, 13 chiamate oracolo, 39 archi enumerati; decodifica completa dopo serializzazione del tipo di condizione come stringa. |
| [007 finale](../results/2026-10-08-avanzamento/seqlock-readers-campaign-portable.lisp) | 200000 | Compile rigoroso e CHECK `:ok` sui sorgenti finali: conteggi confermati, warning e style-warning assenti. |

Comando riproducibile, da eseguire nel checkout isolato con un nome di
tentativo nuovo (il registratore rifiuta la sovrascrittura):

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- \
  sbcl --noinform --no-userinit --no-sysinit --script \
  spikes/SPK-07-protocols/out/seqlock-readers-20261008/record.lisp NOME-NUOVO 200000 < /dev/null
```

Il [catalogo della campagna](../results/2026-10-08-avanzamento/seqlock-readers-campaign-portable.lisp)
riunisce i record del modulo, i report dati e i record del wrapper generico,
conservando anche l'errore di decodifica del tentativo 005. Per leggere il
vecchio report dati 005 il catalogatore crea soltanto il package necessario
al reader Lisp: non carica o esegue codice del modulo. Il nuovo formato
usa una stringa per il tipo della condizione.

Il catalogo conservato nel repository è un record portabile: `:raw-original`
mantiene integralmente il catalogo originario, `:decoded-record` converte
i simboli del package sperimentale in stringhe qualificate. Il normalizzatore
è incluso come sorgente e non esegue dati. La prima lettura autonoma del
catalogo originario è fallita; [record del fallimento](../results/2026-10-08-avanzamento/evidence-read-failure.lisp)
e [lettura corretta](../results/2026-10-08-avanzamento/evidence-read-success.lisp)
sono conservati. I nuovi risultati del modulo usano già una stringa per la
condizione; l'intervento riguarda il vecchio dato recuperato del tentativo 005.

La campagna contiene sette tentativi compile/check: 14 compilazioni
(13 riuscite e un errore sintattico iniziale), sei invocazioni di CHECK
(tre riuscite e tre errori attesi di budget). Il tentativo 005 comprende
anche il fallimento della decodifica nel padre, riparato senza scartare
il record originale. Le compilazioni riuscite restituiscono
`:warnings nil :failure nil`; il CHECK finale restituisce `:status :ok`.
La catalogazione è una successiva lettura/aggregazione di dati, registrata
anch'essa dal wrapper; non compila né esegue il modulo.

Sono state osservate modifiche concorrenti ad altri spike e a runner/suite
nel checkout. Il wrapper del tentativo 003 segnala sorgenti globali
`:changed`; gli input specifici del modulo e il core sono stabili nei
relativi snapshot prima/dopo. Il catalogo distingue le due provenienze
e conserva integralmente i record originali. Questa attività scrive
soltanto i due file richiesti e i nuovi artefatti ignored sopra indicati.

Restano i limiti preregistrati: una lettura per reader, un aggiornamento
per slot, due tentativi, SC con location atomica, rango massimo 36.
La completabilità riguarda lavoro finito con scheduling degli attori
abilitati; nessun limite di tempo reale, snapshot fra slot, prova di
barriere hardware o memoria debole. Nessuna integrazione nella suite,
codice di produzione, modifica dei requisiti o decisioni, commit/push.
