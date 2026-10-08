# Registro delle decisioni architetturali (ADR)

[Documentazione](../README.md) · [Architettura](../architettura.md) · [Invarianti](../invarianti.md)

Un ADR registra **una** decisione: contesto, scelta, conseguenze, e come se ne valuta la
tenuta. Gli ADR sono la memoria del progetto: spiegano perché l'architettura è fatta così.

## Regole

- Numerazione progressiva a quattro cifre; un ADR non si rinumera e non si cancella.
- Stati: **Proposta** → **Accettata** → eventualmente **Sostituita da ADR-nnnn** o
  **Ritirata**.
- Un ADR accettato non si riscrive: per cambiare decisione se ne scrive uno nuovo che
  sostituisce il precedente.
- Un ADR che emenda la [specifica](../specifica/specifica-originale.md) lo dichiara nel campo
  «Rapporto con la specifica».
- Ogni [questione aperta](../questioni-aperte.md) si chiude con un ADR.
- Modello: [0000-modello.md](0000-modello.md).

## Decisioni registrate

Gli ADR 0001–0012 registrano le decisioni **già contenute nella specifica v1**. Le sezioni
«Alternative» e «Valutazione» sono contributi della fase di valutazione, non parte della
specifica.

| ADR | Decisione | Stato |
|---|---|---|
| [0001](0001-common-lisp-sbcl.md) | Common Lisp/SBCL; solo Common Lisp per ora | Accettata (emenda la specifica) |
| [0002](0002-serie-unita-di-storage-e-parallelismo.md) | La Serie come unità di storage e parallelismo | Accettata |
| [0003](0003-wal-per-serie.md) | WAL per Serie, nessun global data WAL | Accettata |
| [0004](0004-storage-append-only-un-solo-active.md) | Storage append-only con un solo segmento ACTIVE | Accettata |
| [0005](0005-writer-logico-per-serie.md) | Un writer logico per Serie con controllo ottimistico | Accettata |
| [0006](0006-transazioni-multiserie-2pc.md) | Transazioni multiserie 2PC-like con un unico `multiserie.log` | Accettata |
| [0007](0007-clean-e-merge-distinti.md) | CLEAN e MERGE distinti, copy-on-write | Accettata |
| [0008](0008-merge-opportunistico.md) | MERGE opportunistico: 50 s di stabilità + basso carico | Accettata |
| [0009](0009-indici-immutabili-atomic-swap.md) | Indici immutabili per i reader, atomic swap | Accettata |
| [0010](0010-cache-clock.md) | Cache CLOCK, partizionabile per Serie | Accettata |
| [0011](0011-thread-pool-dinamico.md) | Thread pool dinamico con EWMA/AIMD/isteresi | Accettata |
| [0012](0012-simd-guidato-dai-benchmark.md) | SIMD solo dove i benchmark lo giustificano | Accettata |

## Software critico (Fase 0, 2026-10-03)

Decisioni prese applicando i criteri del software critico richiesti dall'autore
([ADR-0031](0031-software-critico-criteri-e-priorita.md)); formano un blocco con le
[analisi di affidabilità](../affidabilita/README.md).

| ADR | Decisione | Stato |
|---|---|---|
| [0031](0031-software-critico-criteri-e-priorita.md) | Gerarchia delle priorità (affidabilità sopra prestazioni), classi di integrità, rigore per classe | Accettata (emenda la specifica) |
| [0032](0032-seqlock-a-64-bit.md) | Seqlock a 64 bit, tentativi limitati, ripiego sul writer; slot a 6 parole | Accettata (sostituisce in parte 0015; layout dello slot: 0043) |
| [0033](0033-fail-stop-e-integrita-end-to-end.md) | Fail-stop sugli errori di I/O, verifica in lettura, corruzione a metà log, scrubbing, verificatore offline, stati di salute | Accettata (coda troncata: 0037) |
| [0034](0034-policy-di-compilazione-e-standard-di-codifica.md) | `safety` ≥ 2, nessun avviso, divieti, linter | Accettata |
| [0035](0035-strategia-di-verifica-e-tracciabilita.md) | Tracciabilità bidirezionale controllata, simulatore deterministico, livelli di verifica, criteri di rilascio | Accettata |

## Analisi progettuale (Fase 0, 2026-10-03)

Decisioni nate dall'[analisi progettuale](../analisi-progettuale.md): chiudono i rilievi
`AP-01…AP-16`. Ognuna dichiara quali parti degli ADR precedenti sostituisce; gli ADR
sostituiti in parte restano validi per tutto il resto e portano una nota nello stato.

| ADR | Decisione | Rilievi | Stato |
|---|---|---|---|
| [0036](0036-leggi-di-progetto.md) | Leggi di progetto: il parallelismo è fondante; un punto di atomicità per operazione; prepara, decidi, completa; nulla si distrugge per assenza | AP-13, AP-14 | Accettata |
| [0037](0037-lotto-sigillato.md) | Lotto sigillato: un percorso di scrittura, un flush alla volta, frontiera durevole, recovery che non tronca | AP-02, AP-03, AP-08 | Accettata |
| [0038](0038-orizzonte-di-visibilita.md) | Orizzonte di visibilità; registro degli snapshot; la versione è il CSN | AP-01, AP-02, AP-07, AP-15 | Accettata (emenda la specifica; registro dei pendenti: 0046) |
| [0039](0039-cornice-unica-dei-record.md) | Cornice unica dei record: due CRC, quattro tipi nei segmenti, hint risolto con filtro di esistenza | AP-08, AP-11, AP-13 | Accettata |
| [0040](0040-manifest-a-record-unico.md) | Manifest a record unico (EDIT); il catalogo decide, le directory seguono | AP-14 | Accettata |
| [0041](0041-multiserie-segmenti-autosufficienti.md) | Multiserie: segmenti autosufficienti, abort senza traccia, conferma dopo la pubblicazione | AP-05, AP-06, AP-08 | Accettata |
| [0042](0042-tombstone-e-indice-dei-vivi.md) | Tombstone: indice dei soli vivi, ricostruzione per CSN massimo, scarto per filtro di esistenza | AP-04, AP-11 | Accettata |
| [0043](0043-primary-index-a-frammenti.md) | Primary index a frammenti: directory estendibile, slot a quattro parole, chiavi locali | AP-12, AP-16 | Accettata |
| [0044](0044-cache-acceleratore-puro.md) | La cache è un acceleratore puro | AP-09 | Accettata |
| [0045](0045-modello-di-esecuzione.md) | Compiti a completamento, migrazione senza stato, attese come parcheggi | AP-10 | Accettata |

## Decisioni di progetto (Fase 0, 2026-10-03)

Chiudono le [questioni aperte](../questioni-aperte.md). Ogni ADR cita il pattern adottato e
dove è usato in produzione ([principi di ingegneria](../principi-di-ingegneria.md)). Il
risultato consolidato è in [architettura.md](../architettura.md) e
[formati-su-disco.md](../formati-su-disco.md).

| ADR | Decisione | Chiude | Stato |
|---|---|---|---|
| [0013](0013-log-structured-segmento-active-come-log.md) | Il segmento ACTIVE è il log dei dati; `wal/` è il control log | QA-02 | Accettata (emenda la specifica; record committed: 0037) |
| [0014](0014-formato-record-documento-id.md) | Record binario con CRC32C, documenti CBOR, `_id` 1–255 byte | QA-01 | Accettata (intestazione del record: 0039) |
| [0015](0015-primary-index-swiss-table-swmr.md) | Primary index Swiss SWMR, seqlock per slot, versioni trattenute, hint per segmento | QA-24, QA-03 | Accettata (struttura: 0043; hint: 0039; ricostruzione: 0042) |
| [0016](0016-epoch-based-reclamation.md) | Epoch-based reclamation | QA-16 | Accettata (ambito: 0043, 0045) |
| [0017](0017-piattaforma-e-io.md) | Linux x86-64 di riferimento; I/O bloccante su pool dedicato; `durable-flush` | QA-19 | Accettata (che cosa passa dal pool di I/O: 0045) |
| [0018](0018-control-log-manifest-swap.md) | Control log come manifest; `SWAP` come record unico; stabilizzazione | QA-04, QA-13 | Accettata (record e ordine: 0040) |
| [0019](0019-durability-e-group-commit-pipelined.md) | Livelli `:async`/`:group`/`:strong`; group commit pipelined | QA-05 | Accettata (meccanica: 0037) |
| [0020](0020-csn-snapshot-isolamento.md) | CSN di Archivio; snapshot = numero; SI + `:serializable`; `snapshot-too-old` | QA-06, QA-09, QA-14 | Accettata (nascita dello snapshot: 0038) |
| [0021](0021-2pc-intenti-outcome.md) | 2PC con intenti no-wait, record OUTCOME, presumed abort, troncamento | QA-07, QA-08 | Accettata (record e conferma: 0041) |
| [0022](0022-registri-come-serie-catalogo.md) | Registri è una Serie; catalogo di documenti; bootstrap | QA-10 | Accettata (creazione ed eliminazione: 0040) |
| [0023](0023-politiche-di-compaction.md) | Soglie, stati di carico, limitatore di banda, tombstone per lineage | QA-11, QA-12, QA-15 | Accettata (tombstone: 0042) |
| [0024](0024-memoria-e-gc.md) | Array specializzati a vita lunga; zero allocazione sul hot path | QA-18 | Accettata (crescita dell'indice: 0043) |
| [0025](0025-cache-per-location.md) | Cache per location, arena a slot, CLOCK per partizione | QA-17 | Accettata (struttura, nessuna ri-etichettatura: 0044) |
| [0026](0026-indici-secondari-segmentati.md) | Indici secondari per segmento, formato fisso, delta in memoria | QA-25 | Accettata (Bloom: 0039, 0042) |
| [0027](0027-dipendenze-e-test.md) | Nessuna dipendenza esterna; harness proprio | QA-22 | Accettata |
| [0028](0028-target-e-obiettivi-di-latenza.md) | Target aggregati; obiettivi numerici di latenza e di pausa GC | QA-26 | Accettata dall'autore il 2026-10-08 |
| [0029](0029-interfacce-protocollo-query-contratto.md) | Protocollo a frame CBOR; query come dati; contratto additivo | QA-20, QA-21 | Accettata |
| [0030](0030-scope-v1.md) | Scope della v1 | QA-23 | Accettata dall'autore il 2026-10-08 |

## Valutazione sperimentale (2026-10-08)

| ADR | Decisione | Evidenza | Stato |
|---|---|---|---|
| [0046](0046-orizzonte-con-registro-limitato.md) | Registro limitato dei CSN in volo; assegnazione e registrazione indivisibili; H ricavato dal minimo pendente | controesempio riproducibile in SPK-07 | Accettata |
| [0047](0047-verifica-csn-dei-record-prepared.md) | CSN dei prepared verificato attraverso OUTCOME o esito autorevole nel manifest; il flag da solo è insufficiente | verifica dei record in SPK-09 | Accettata |
| [0050](0050-pubblicazione-e-costi-della-directory.md) | Root ricontrollata anche su miss; costo della directory e memoria transitoria distinti dai C slot | pubblicazione e contatori SPK-01 | Accettata; verifica di scala e memoria aperta |

## Limiti e capacità (2026-10-08)

| ADR | Decisione | Stato |
|---|---|---|
| [0048](0048-limiti-documentali-e-formato-v2.md) | 16 MiB effettivi, 100 livelli, chiavi estese, formato v2 | Accettata; evidenze da produrre |
| [0049](0049-capacita-oltre-la-ram.md) | Indice persistente con cache per superare la RAM | Proposta |

## Organizzazione della documentazione (2026-10-08)

| ADR | Decisione | Stato |
|---|---|---|
| [0051](0051-presentazione-della-documentazione.md) | Presentazione della specifica, guida comune e conservazione delle prove originali | Accettata; requisiti invariati |
