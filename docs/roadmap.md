# Roadmap

> La roadmap è una **proposta di organizzazione del lavoro**: la specifica non prescrive fasi.

## Stato attuale

**Definizione architetturale completata; valutazione e sviluppo delle fondazioni in corso.**
Dal 2026-10-08 l'autore ha autorizzato il codice di prodotto: i componenti già
realizzati e i loro confini sono nell'[indice di implementazione](implementazione/README.md).
La loro presenza non chiude i gate sperimentali né qualifica il motore completo.

Il perimetro della v1 include la **ricerca full text** approvata con
[ADR-0053](adr/0053-ricerca-full-text-indici-invertiti.md): implementazione
e qualifica sono nella fase 8, insieme a indici secondari e Query Engine.
I test attuali di indice primario e recovery non verificano questi nuovi
requisiti. [ADR-0054](adr/0054-contratto-e-formato-full-text.md) completa il
[contratto operativo](full-text.md) e il [formato binario](formato-indice-full-text.md).
Il nucleo Unicode, il codec e la preparazione documentale sono ora presenti;
commit, visibilità MVCC e pubblicazione durevole restano da integrare secondo il
[piano di verifica](affidabilita/piano-di-verifica.md#ricerca-full-text).

La [prova verticale con SIGKILL](implementazione/prova-verticale.md) collega
ora scrittura durevole, indice e GET, recovery, checkpoint e rotazione in
una fixture C4. Nei formati v1/v2 verifica anche nuove scritture dopo la
riapertura, seguite da un secondo crash e recupero. La fixture ricostruisce
la base CSN per una sola Serie con record ordinari; il coordinamento resta
nel test. Il [nucleo M1](implementazione/production-engine-bootstrap.md)
realizza ora startup, recovery e admission per una sola Serie. Recovery
Manager e frontiera dell'intero Archivio restano lavoro di prodotto.

La priorità di sviluppo è trasferire questa composizione nel motore e renderla
accessibile localmente. [ADR-0055](adr/0055-interfaccia-locale-unix-socket.md)
fissa il **socket Unix locale come interfaccia predefinita e prioritaria** per
il primo impiego NNTP: la prima integrazione M16 segue avvio, recovery e
ammissione, senza attendere il completamento delle fasi 8–9. TCP è opzionale
e successivo. Listener e client sono disponibili nel
[profilo Unix M1](implementazione/production-unix-m1.md); il completamento
del contratto M16 esteso resta aperto.

Il primo passo di prodotto è la [scelta dell'ID del nuovo segmento](implementazione/id-segmento-recovery.md):
proposta pura dal manifest e dall'inventario completo, usata anche dalla
fixture verticale. La raccolta del namespace e delle identità è descritta
sotto; riconciliazione fisica e coordinamento del recovery restano da implementare;
l’acquisizione readonly completa è ora collegata al piano della directory.
La [pubblicazione esclusiva di temporanei](implementazione/io-pubblicazione.md)
fornisce ora la primitiva I/O che rifiuta target esistenti e verifica il
legame nome/FD. La [stabilizzazione per fonte](implementazione/stabilizzazione-nomi-recovery.md)
collega token semantico, CONTROL, pubblicazione esclusiva e fsync parent,
anche per il nome già definitivo. Sequenza completa del Recovery Manager,
qualifica funzionale e ammissione restano aperte.

L'[ingresso ID dalla directory](implementazione/id-directory-recovery.md)
collega ora l'inventario reale alla proposta del nuovo segmento senza una
seconda scansione. Anche la fixture con SIGKILL usa questo percorso su nomi
canonici; il suo limite di otto ID non limita l'inventario di prodotto.

| Ordine | Incremento | Confine da verificare |
|---|---|---|
| 1 | Apertura e recovery di una Serie nel prodotto | Inventario generale, identità, ownership delle capacità e fallimenti a ogni passo |
| 2 | Ricostruzione CSN dell'Archivio e ammissione | Tutte le Serie e decisioni durevoli, pendenti risolti, registro unico per scritture e snapshot |
| 3 | Prima integrazione M16 su socket Unix locale, con le operazioni fondamentali disponibili | Due processi, framing CBOR, directory e permessi, collisioni, limiti, client lento e risposta persa; [piano di verifica](affidabilita/piano-di-verifica.md#interfaccia-locale-unix-socket) |
| 4 | Percorso completo concorrente | Pubblicazione coerente indice/radice, isolamento, MVCC e multiserie, esposti anche al client locale quando disponibili |
| 5 | Qualifica di carico | Pool persistente, crash ripetuti, GC e P99 sulla piattaforma di riferimento, includendo il socket Unix |

Questi incrementi non anticipano la chiusura dei gate della Fase 0.

Il [contratto di sessione M16](implementazione/sessione-locale.md) è una
proposta estesa. Il [profilo M1 autorizzato](implementazione/production-unix-m1.md)
realizza ora l'ordine 3 con PING/PUT/GET/DELETE dopo recovery e ammissione;
la [qualifica locale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-23-production-unix-m1/report.md)
verifica processi distinti, crash, riavvio e risposta persa. Il profilo usa
un owner e limiti inferiori; il completamento M16 e i gate restano aperti.
[SPK-11](../spikes/SPK-11-unix-socket/README.md) conserva l'istruttoria precedente.
La [variante di sessione C4](../spikes/SPK-11-unix-socket/session-method.md)
aggiunge handshake, negoziazione e PING fra processi, con ID u64 e modelli
di credito/deadline. Non anticipa l'accettazione del contratto o il gate reale.
Il [passo I/O C4](../spikes/SPK-11-unix-socket/native-io-method.md) aggiunge
recv/send su span posseduti e backend sostituibili: e un prerequisito del
successivo adattatore di prodotto. Il profilo M1 integra l'ammissione reale
con buffer preallocati e attore seriale; pool/scheduler estesi restano da integrare.

Il [bootstrap runtime dell'Archivio](implementazione/runtime-archivio.md)
collega ora il piano CSN completo alla famiglia unica CSN/snapshot/epoche
e al nuovo ambito GET. Riconciliazione, pubblicazione degli effetti,
costruzione dei controller Serie e ammissione restano da coordinare.

Il primo incremento dispone della [raccolta readonly dell'inventario](implementazione/inventario.md#raccolta-dalla-directory)
da una capacità directory, con nomi e identità verificati prima del planner.
L'[apertura readonly relativa](implementazione/io-apertura-relativa.md)
fornisce ora capacità e dimensione dallo stesso FD ed è usata nei reader
della prova verticale. L'[acquisizione posseduta delle fonti](implementazione/fonti-recovery.md)
collega ora il piano completo ad ACTIVE/CLOSED readonly con budget cumulativo
e cleanup dei figli; riconciliazione fisica e coordinamento del recovery
restano passi successivi.
La [creazione relativa dei temporanei](implementazione/io-creazione-relativa.md)
completa il confine per i nuovi output della prova verticale, senza
riaprire il percorso del parent o decidere la riconciliazione degli orfani.

Al 2026-10-03 la parte di **definizione è completa**: le 26 questioni aperte sono chiuse dagli
ADR 0013–0030, il progetto è consolidato in [architettura.md](architettura.md) e i formati in
[formati-su-disco.md](formati-su-disco.md). L'[analisi progettuale](analisi-progettuale.md)
dello stesso giorno ha riletto l'insieme, trovato cinque difetti di correttezza e li ha
chiusi con gli ADR 0036–0045. ADR-0028 e ADR-0030 sono stati confermati dall'autore il
2026-10-08. È in corso la **valutazione sperimentale**: suite degli spike SPK-01, SPK-02,
SPK-03, SPK-07, SPK-09, con `make spikes-check` e `make spikes-bench`. SPK-07 ha già
trovato un controesempio nell'anello dell'orizzonte, corretto da
[ADR-0046](adr/0046-orizzonte-con-registro-limitato.md).
La suite SPK-07 comprende ora modelli finiti di pubblicazione dei frammenti,
scadenza e protezione degli accessi già ammessi, compaction con writer ACTIVE
e ordini di osservazione delle barriere, due reader/due slot in SC e crash
sui byte con frontiera confermata esplicita. Metodo, risultati e lacune sono nel
[README dello spike](../spikes/SPK-07-protocols/README.md).

La [campagna locale 2026-10-08](valutazione/risultati-2026-10-08.md) conserva
misure e dati grezzi dei cinque spike v1 e di SPK-10: codec, indice, CBOR e
migrazione v2 su modello, con integrazione in memoria dei confini massimi.
`make check` registra l'intera verifica in forma strutturata, inclusi fallimenti.
Restano le parti complete del gate v2, memoria debole completa e crash sui byte
del motore, e le misure sulla
piattaforma di riferimento; il gate non è chiuso.

SPK-08 aggiunge [maschere esatte e kernel NEON/SWAR](valutazione/risultati-SPK-07-08-2026-10-08.md):
correttezza, disassemblato e 70 campioni seriali locali. Restano x86-64,
integrazione dell'indice, bitmap/checksum e piattaforma di riferimento.

## Fase 0 — Definizione architetturale e valutazione

Il [server NNTP in Common Lisp](valutazione/caso-duso-nntp.md) è il caso
applicativo di riferimento confermato dall'autore il 2026-10-15. Le esigenze
di lookup, intervalli ordinati, pubblicazione multiserie, retention e recovery
orientano la valutazione delle fasi esistenti. La richiesta attuale riguarda
la documentazione dell'obiettivo; sviluppo del demone e benchmark applicativi
restano futuri. La successiva richiesta di ricerca full text estende invece
esplicitamente lo scope v1 tramite ADR-0053, senza anticipare i gate.

Scopo: arrivare all'implementazione con le decisioni strutturali prese, i rischi principali
misurati e i protocolli critici verificati su modello.

### Filoni di lavoro

| Filone | Attività | Risultato |
|---|---|---|
| **A. Decisioni** | Chiudere le [questioni aperte](questioni-aperte.md) di priorità A | Un ADR per ciascuna |
| **B. Spike** | Eseguire gli [spike](valutazione/piano-spike.md) in ordine di rischio | Misure e raccomandazioni in `spikes/` |
| **C. Modelli** | Descrivere come macchine a stati 2PC + recovery e compaction + swap + reclaim; esplorarne i crash | Protocolli verificati rispetto agli [invarianti](invarianti.md) |
| **D. Formati** | Definire i formati persistenti: record, WAL, segmento, manifest, `multiserie.log`, catalogo | Documento dei formati su disco |
| **E. Contratti** | Definire le interfacce tra i [moduli](16-moduli.md#contratti-tra-moduli) | Contratto per modulo |
| **F. Valutazione** | Aggiornare [registro rischi](valutazione/registro-rischi.md) e [stime](valutazione/stime-ordine-di-grandezza.md) con i risultati | Verdetto di fattibilità |

### Ordine consigliato (parte restante)

1. Conferma di **ADR-0028** (target, latenze, pausa GC ≤ 5 ms) e **ADR-0030** (scope).
2. **SPK-02** (GC) e **SPK-01** (primary index): i due rischi che possono mettere in
   discussione le scelte di base.
3. **SPK-07** (modello di 2PC + compaction/swap/reclaim con crash in ogni punto).
4. **SPK-03** (flush concorrenti di molte Serie).
5. Completare le verifiche residue di SPK-04, SPK-05 e SPK-06, che hanno prime campagne
   locali, e completare SPK-08 sulla piattaforma di riferimento; gli spike restanti
   sono eseguibili anche durante la Fase 1.

### Criteri di uscita

- [x] Tutte le questioni di priorità A sono chiuse da un ADR (2026-10-03).
- [x] I formati persistenti sono documentati ([formati-su-disco.md](formati-su-disco.md)).
- [x] Ogni rischio con esposizione alta ha una mitigazione decisa o è stato accettato
      esplicitamente ([registro](valutazione/registro-rischi.md#stato-dopo-gli-adr-2026-10-03)).
- [x] I contratti tra moduli sono definiti ([architettura](architettura.md#contratti)).
- [x] Analisi progettuale eseguita; rilievi AP-01…AP-16 chiusi dagli ADR 0036–0045
      ([analisi](analisi-progettuale.md)).
- [x] Criteri di software critico adottati ([ADR-0031](adr/0031-software-critico-criteri-e-priorita.md)): analisi dei guasti, standard di codifica, piano di verifica, requisiti tracciati, `make check` con linter e tracciabilità.
- [x] ADR-0028 (con i minimi di prestazione) e ADR-0030 (con backup e verificatore nella v1) confermati dall'autore il 2026-10-08.
- [ ] SPK-01, SPK-02, SPK-03 e **SPK-09** eseguiti, con risultati riproducibili nel repository.
- [ ] Il modello SPK-07 (2PC, compaction/swap/reclaim, seqlock, idempotenza del recovery, lotto e frontiera durevole, orizzonte di visibilità, segmenti autosufficienti, tombstone, punti di atomicità) non viola gli invarianti in nessuno degli scenari FI-01…FI-13.
- [ ] I target di [13 Benchmark](13-benchmark.md) sono confermati o rivisti alla luce di stime
      e spike.
- [ ] Decisione esplicita di procedere alla Fase 1.

## Gate di ogni fase

Ogni fase successiva si chiude solo con i [criteri di rilascio](affidabilita/piano-di-verifica.md#criteri-di-rilascio-di-una-fase):
requisiti tracciati e verificati, copertura per classe, nessuna violazione in modelli e fault
injection, verificatore offline pulito dopo i crash, punteggio di mutazione di C1, `make check`
verde, nessuna deviazione non approvata.

## Fasi successive (schema)

L'ordine segue due principi: una **fetta verticale** funzionante il prima possibile e
l'infrastruttura di **fault injection** prima dei protocolli che deve verificare. Il dettaglio
si definisce alla chiusura della Fase 0.

| Fase | Contenuto | Moduli | Verifica |
|---|---|---|---|
| 1 | Una Serie: cornice dei record, lotti sigillati nel segmento ACTIVE, manifest a record EDIT, rotazione, primary index a frammenti con seqlock a 64 bit, GET/PUT/DELETE, recovery non distruttivo; compiti a completamento; **ambiente iniettabile** (tempo, casualità, schedulazione, I/O) e **simulatore deterministico**; verifica in lettura; **verificatore offline**; harness di test, modello di riferimento, fuzzing dei decoder, mutation testing | M01–M05, M12, io | FI-01, FI-02, FI-10 |
| 2 | Group commit con un compito di I/O alla volta, livelli di durability, cache, metriche | M02, M07, metrics | benchmark di base |
| 3 | Orizzonte di visibilità, snapshot/MVCC e transazioni single-Series | M08, M09 | FI-11 |
| 4 | CLEAN, swap, reclaim; **scrubbing** | M11, M04 | FI-06, FI-07, FI-09 |
| 5 | Archivio, Registri, catalogo, più Serie; writer logici su thread pool dinamico; scheduler; **backup e restore verificato** | M13, M14, M17 | FI-13, benchmark di isolamento tra Serie |
| 6 | Transazioni multiserie e `multiserie.log` | M09, M10 | FI-03, FI-04, FI-05, FI-12 |
| 7 | MERGE, low-load policy, Compaction Scheduler | M11, M13 | FI-08, benchmark di interferenza |
| 8 | Indici secondari, **ricerca full text con indici invertiti dedicati** e Query Engine ([ADR-0053](adr/0053-ricerca-full-text-indici-invertiti.md)) | M06, M15 | confronto con scansione, snapshot/update/delete, build/rebuild, corruzione e budget; [campagna full text](13-benchmark.md#ricerca-full-text) |
| 9 | Completamento protocollo/server M16 e trasporto TCP opzionale; prima integrazione Unix socket già anticipata dopo avvio/recovery/ammissione (ADR-0055) | M16 | stessa semantica e stessi limiti del percorso locale; TCP solo con attivazione esplicita |
| 10 | Campagna di benchmark; ottimizzazioni sugli hot path misurati | M18 | [13 Benchmark](13-benchmark.md) |

## Avanzamento SPK-04

La [prima campagna SPK-04](valutazione/risultati-SPK-04-2026-10-08.md)
aggiunge un pool eseguibile e modelli finiti di parcheggio e ripartenza
delle letture. Restano carico vivo, messaggi, scheduler adattivo e misure
significative sulla piattaforma di riferimento; la Fase 0 resta aperta.

## Gate del formato v2

Prima del motore: campagne dei limiti ADR-0048 (documenti, profondità, chiavi), decoder v1/v2, migrazione interrotta e budget del nuovo slot. Aggiornare SPK-01 e SPK-09 con risultati distinti. La ricerca oltre RAM (ADR-0049) richiede confronto e ADR prima di cambiare lo scope v1.

Il 2026-10-22 l'autore autorizza l'implementazione incrementale del modo
automatico [ADR-0057](adr/0057-selezione-automatica-indice.md). Il primo
[incremento](implementazione/indice-automatico.md#incrementi-successivi-e-completamento)
aggiunge il selettore di budget e il modello C4 del lifetime: seguono formato,
cache, backend differenziale, attuatore con crescita/rientro e qualifica.
L'indice del runtime rimane residente; nessun gate oltre RAM e' chiuso.

I2 introduce [ADR-0058](adr/0058-pagine-indice-primario.md) e il
[codec delle pagine](implementazione/pagine-indice.md). Pagine e PageRef sono
verificabili localmente; cache, split del writer, grafo completo, recovery e
cambi automatici in esercizio richiedono ancora gli incrementi successivi.

## Avanzamento SPK-05

> **Proposta** — Il [confronto locale](valutazione/risultati-SPK-05-2026-10-08.md)
> aggiunge letture posizionali e mapping di file reali, con controlli CRC,
> chiave e stamp. La scelta pread di ADR-0017 resta confermata dal progetto;
> dataset oltre RAM, granularità della cache e target NVMe restano da verificare.

## Avanzamento SPK-06

> **Proposta** — La [prima campagna locale](valutazione/risultati-SPK-06-2026-10-08.md)
> verifica il modello del carico, ammissibilità del MERGE e quote su input finiti;
> misura inoltre copie buffered concorrenti a letture posizionali. Le due prove
> sono indipendenti: il modello non governa le copie tramite segnali reali.
> Restano compaction del motore, calibrazione e feedback sul dispositivo,
> piattaforma di riferimento e rispetto del P99 durante CLEAN/MERGE. I gate
> della fase e i target di prestazione restano aperti.
