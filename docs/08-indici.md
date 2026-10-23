# 08 — Indici

> **Fonte:** «Index», «Secondary index», «Secondary index delta», «Index snapshot» della
> [specifica](specifica/specifica-originale.md).
> **Moduli:** M05 Primary Index Manager, M06 Secondary Index Manager.
> **Decisioni:** [ADR-0015](adr/0015-primary-index-swiss-table-swmr.md) e
> [ADR-0043](adr/0043-primary-index-a-frammenti.md) (primary index Swiss SWMR a frammenti),
> [ADR-0039](adr/0039-cornice-unica-dei-record.md) (hint per segmento),
> [ADR-0042](adr/0042-tombstone-e-indice-dei-vivi.md) (solo documenti vivi, ricostruzione per
> CSN massimo), [ADR-0026](adr/0026-indici-secondari-segmentati.md) (indici
> secondari **per segmento**, a formato fisso, con delta in memoria per l'ACTIVE),
> [ADR-0053](adr/0053-ricerca-full-text-indici-invertiti.md) (ricerca full text con indici
> invertiti dedicati; nucleo disponibile, integrazione da completare). Formati in
> [formati-su-disco.md](formati-su-disco.md#file-indice).

## Primary index

```
_id → location
```

La `location` contiene almeno:

| Campo | Significato |
|---|---|
| `segment-id` | segmento che contiene il record |
| `offset` | posizione nel segmento |
| `length` | lunghezza del record |
| `version` | versione del documento (usata dall'optimistic version checking, [05](05-transazioni.md)): è il CSN del commit ([ADR-0038](adr/0038-orizzonte-di-visibilita.md)) |

Requisiti:

- lookup **O(1) medio**, altamente ottimizzato;
- valutare una struttura tipo **Swiss Table**;
- evitare milioni di oggetti Lisp separati (uno per entry);
- preferire packed arrays, vectors, strutture compatte, metadata binari, memoria contigua.

La specifica colloca il primary index **in RAM** (sezione sul confronto con altri sistemi).
Il vincolo sugli oggetti Lisp non è solo una questione di velocità: milioni di oggetti con
puntatori sono lavoro per il garbage collector, mentre array specializzati non contengono
puntatori da tracciare ([15](15-ottimizzazioni-native.md)).

> **Deciso (QA-03 → [ADR-0015](adr/0015-primary-index-swiss-table-swmr.md))** — Persistenza dell'indice: la directory `index/` della Serie esiste nel
> layout, ma la specifica non dice se contiene un checkpoint del primary index o solo indici
> secondari. La scelta determina il tempo di riavvio.

> **Deciso (QA-01 → [ADR-0014](adr/0014-formato-record-documento-id.md))** — Tipo e lunghezza di `_id` condizionano il formato della tabella (chiavi
> a lunghezza fissa inline oppure hash + verifica).

## Indici secondari

Strutture diverse per tipo di query:

| Tipo di dato / query | Struttura |
|---|---|
| Stringhe, prefix | ART (Adaptive Radix Tree) |
| Numeri, date, range | B+ tree o struttura ordinata equivalente |
| Categorie | posting lists |
| Boolean, bassa cardinalità | bitmap |
| Testo, parole e frasi | indice invertito dedicato: dizionario, posting list e posizioni ([ADR-0053](adr/0053-ricerca-full-text-indici-invertiti.md)) |

**Bloom filter per segmento.** Serve solo a stabilire che un valore è *sicuramente assente*
oppure *potenzialmente presente*. NON DEVE essere usato come struttura di localizzazione
definitiva (INV-I2).

> **Deciso ([ADR-0039](adr/0039-cornice-unica-dei-record.md), [ADR-0042](adr/0042-tombstone-e-indice-dei-vivi.md))** —
> I filtri sui **valori** sono una sezione dei file di indice del segmento e permettono a una
> query di uguaglianza di saltare il segmento. Il filtro sulle **chiavi** `_id` è una sezione
> dell'hint e serve a una cosa sola: decidere quando un tombstone si può scartare.

### Modello a delta

Per gli indici secondari soggetti a modifiche frequenti, un modello LSM-like:

```
base index + immutable delta(s)  →  merge asincrono  →  nuova base index
```

Un aggiornamento che sposta il documento 42 da `category="tech"` a `category="sport"` produce:

```
category="tech"  → REMOVE 42
category="sport" → ADD 42
```

La nuova base viene costruita **senza bloccare globalmente i reader**.

### Ricerca full text

> **Deciso ([ADR-0053](adr/0053-ricerca-full-text-indici-invertiti.md))** — La ricerca full text
> entra nel progetto della v1 con indici appositi. Il primo [nucleo](implementazione/full-text.md)
> implementa analisi, run posizionali, codec completo e viste verificate;
> integrazione e qualifica restano nella fase 8,
> anche in vista del [server NNTP](valutazione/caso-duso-nntp.md).

Il contratto della Serie dichiara i campi testuali e un analizzatore versionato, comune
a indicizzazione e query. Il profilo base normalizza Unicode e maiuscole/minuscole,
conserva gli accenti e non elimina parole o applica stemming implicitamente. Il documento
originale è conservato integralmente. Ogni indice ha questa struttura logica:

```
(campo, termine) → posting list di righe → frequenze e posizioni nel campo
                         │
                         └→ hint del segmento → chiave e CSN → versione visibile
```

Un file `.idx` immutabile per segmento `CLOSED` contiene dizionario, posting e posizioni;
il delta dell'`ACTIVE` include i nuovi documenti prima della loro pubblicazione.
Tokenizzazione e preparazione avvengono fuori dal writer; l'applicazione del delta resta
seriale nella Serie. Non si aggiungono un WAL o uno scheduler dedicati al full text.

Sono previsti predicati strutturati per tutti/almeno uno dei termini e per frasi con
posizioni consecutive nello stesso campo. Si combinano con `and/or/not`, filtri per data,
uguaglianza e intervallo. `not` usa i documenti vivi dello stesso snapshot; testo di query
senza termini produce un rifiuto esplicito. Ordinamento e spareggio per `_id` sono
deterministici; ranking per rilevanza e ricerche fuzzy restano decisioni successive.

Update, delete e abort non devono lasciare corrispondenze di versioni invisibili:
ogni candidato è verificato contro la versione committed dello snapshot, comprese le
versioni trattenute, prima di applicare insieme testo e filtri. CLEAN/MERGE ricostruiscono
i posting con le nuove righe. Gli indici sono derivati ricostruibili dai documenti;
file mancante o corrotto e generazione incompleta producono un errore esplicito.
Una nuova generazione di analizzatore diventa utilizzabile soltanto con copertura
completa, senza mescolare profili nella stessa query (INV-I4).

Byte analizzati, termini, posizioni, memoria del delta e lavoro della query hanno budget
finiti; nessun troncamento silenzioso in scrittura o risultato parziale dichiarato
completo. Semantica e protocollo di pubblicazione sono nell'ADR; sezioni logiche su
disco in [formati](formati-su-disco.md#indice-full-text) e prove future in
[benchmark](13-benchmark.md#ricerca-full-text).

> **Deciso ([ADR-0054](adr/0054-contratto-e-formato-full-text.md))** — Il
> [contratto operativo](full-text.md) completa profilo Unicode, foglie AST, ownership,
> generazioni, budget e criteri di accettazione. Il
> [formato `.idx` v2/type 5](formato-indice-full-text.md) fissa header, sezioni e array,
> con legame all'hint e riserva conservativa dei byte prima del commit. Questa versione
> iniziale usa array a larghezza fissa; le ottimizzazioni del codec richiedono una nuova
> versione e misure dedicate. Il [codec implementato](implementazione/full-text-codec.md)
> verifica sezioni e legame al descrittore/hint fornito; la verifica dell'hint stesso,
> dei documenti e della copertura della generazione rimane da integrare.

## Index snapshot

Gli indici DEVONO essere immutabili per i reader (INV-I1):

```
Reader → Index v17

Writer: costruisce Index v18, atomic swap

nuovi reader      → Index v18
reader precedenti → completano su v17
```

## Questioni decise e rischi

- **QA-24** ([ADR-0015](adr/0015-primary-index-swiss-table-swmr.md)) — Il modello «versione immutabile + swap» è naturale per gli indici secondari
  (base + delta) e per la rilocazione in blocco fatta dalla compaction. Per il **primary
  index**, che riceve una modifica per ogni scrittura, costruire una nuova versione completa a
  ogni commit non è praticabile: va definito come si concilia l'immutabilità per i reader con
  aggiornamenti continui del writer (RSK-02).
  Risolto con il seqlock per slot ([ADR-0032](adr/0032-seqlock-a-64-bit.md)) e la
  sostituzione atomica di un frammento alla volta
  ([ADR-0043](adr/0043-primary-index-a-frammenti.md)).
- **QA-25** ([ADR-0026](adr/0026-indici-secondari-segmentati.md)) — Indici secondari: aggiornati in modo sincrono con il commit o in ritardo? Che
  cosa vede uno snapshot? Sono persistiti o ricostruiti al riavvio?
- **QA-03** ([ADR-0015](adr/0015-primary-index-swiss-table-swmr.md)) — Persistenza e tempo di ricostruzione del primary index (RSK-07).

## Metriche

Hit rate, latenza di lookup, tempo di rebuild ([12 Osservabilità](12-osservabilita.md)).
Per il full text: byte di dizionario/posting/posizioni, memoria del delta, costo di
analisi e commit, posting visitati, candidati scartati per visibilità, latenza e
copertura della generazione. Sono misure da produrre, senza riusare i target del GET.
