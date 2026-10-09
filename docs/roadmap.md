# Roadmap

> La roadmap è una **proposta di organizzazione del lavoro**: la specifica non prescrive fasi.

## Stato attuale

**Fase 0 — Definizione architetturale e valutazione, con fondazioni in implementazione.**
L'autore ha autorizzato la scrittura delle fondazioni il 2026-10-08:
[moduli e contratti](implementazione/README.md). Questa attività non chiude
i gate sperimentali e non qualifica il motore completo.

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
| 8 | Indici secondari e Query Engine | M06, M15 | — |
| 9 | Protocollo di rete e server | M16 | — |
| 10 | Campagna di benchmark; ottimizzazioni sugli hot path misurati | M18 | [13 Benchmark](13-benchmark.md) |

## Avanzamento SPK-04

La [prima campagna SPK-04](valutazione/risultati-SPK-04-2026-10-08.md)
aggiunge un pool eseguibile e modelli finiti di parcheggio e ripartenza
delle letture. Restano carico vivo, messaggi, scheduler adattivo e misure
significative sulla piattaforma di riferimento; la Fase 0 resta aperta.

## Gate del formato v2

Prima del motore: campagne dei limiti ADR-0048 (documenti, profondità, chiavi), decoder v1/v2, migrazione interrotta e budget del nuovo slot. Aggiornare SPK-01 e SPK-09 con risultati distinti. La ricerca oltre RAM (ADR-0049) richiede confronto e ADR prima di cambiare lo scope v1.

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
