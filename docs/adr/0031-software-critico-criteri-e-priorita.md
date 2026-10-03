# ADR-0031 — ArcDocDB è software critico: priorità, classi di integrità, regole

- **Stato:** Accettata (decisione dell'autore, 2026-10-03)
- **Data:** 2026-10-03
- **Rapporto con la specifica:** **emenda** la specifica nell'ordine delle priorità: gli
  obiettivi di prestazione della specifica diventano subordinati all'affidabilità. Nessun
  requisito funzionale della specifica viene rimosso.
- **Riferimenti:** [affidabilità](../affidabilita/README.md),
  [analisi dei guasti](../affidabilita/analisi-dei-guasti.md),
  [standard di codifica](../affidabilita/standard-di-codifica.md),
  [piano di verifica](../affidabilita/piano-di-verifica.md),
  [tracciabilità](../tracciabilita/README.md)

## Contesto

L'autore ha richiesto di adottare i criteri tipici del software critico: codice perfetto,
funzionalità perfetta, tracciabilità; fine ultimo l'affidabilità totale ed estrema; vincoli di
prestazione «ragionevolissimi». Il progetto era stato impostato con le prestazioni come
motivazione principale (la specifica parla di «elevata velocità» come obiettivo principale).

## Decisione

### 1. Gerarchia delle priorità

In ordine decrescente:

1. **Integrità dei dati committed.**
2. **Correttezza funzionale** rispetto alla specifica.
3. **Comportamento definito in presenza di guasti:** fail-stop o degrado controllato, mai
   dati sbagliati.
4. **Verificabilità e tracciabilità.**
5. **Disponibilità.**
6. **Prestazioni.**

Regola: **una scelta di livello inferiore non può indebolire una garanzia di livello
superiore.** Ogni compromesso a favore delle prestazioni richiede un ADR, una misura, e la
dimostrazione che i livelli superiori non sono toccati.

### 2. Che cosa significa «affidabilità totale»

Non è l'assenza di guasti, che nessun software può garantire. È l'insieme delle quattro
proprietà seguenti, ciascuna verificabile:

- (a) **nessun dato committed è perso o corrotto senza che il sistema lo rilevi e lo
  dichiari**;
- (b) **nessuna risposta errata è data in silenzio**: un dato non verificato non viene mai
  restituito;
- (c) **ogni guasto del [modello dei guasti](../affidabilita/analisi-dei-guasti.md) ha una
  risposta definita e verificata** (rilevazione, contenimento, recupero);
- (d) **ogni requisito è tracciato** dalla specifica fino alla verifica, e la tracciabilità è
  controllata da uno strumento.

I guasti **fuori** dal modello (perdita simultanea di tutti i supporti, un sistema operativo
o un firmware che mentono su un flush, difetti del compilatore) non si possono escludere:
vengono resi rilevabili dove possibile e dichiarati nel
[registro dei rischi](../valutazione/registro-rischi.md) come rischi residui.

### 3. Classi di integrità del software

| Classe | Contenuto | Effetto di un difetto |
|---|---|---|
| **C1** — percorso dei dati | codec di record e file, segmenti, control log, `multiserie.log`, recovery, indice primario, MVCC e CSN, transazioni, compaction (swap, reclaim), modulo `io`, catalogo, verifica in lettura, cache (percorso dei dati) | perdita o corruzione di dati |
| **C2** — correttezza funzionale senza effetti persistenti | Query Engine, protocollo, validazione del contratto, indici secondari (interrogazione) | risposta errata |
| **C3** — governo delle risorse | scheduler, thread pool, politica di sostituzione della cache, metriche, compaction scheduler | degrado di prestazioni o disponibilità; **non** deve poter violare C1/C2 |
| **C4** — strumenti | linter, controllo di tracciabilità, harness di test, benchmark | falsa fiducia (si verificano comunque) |

Un modulo ha la classe del suo componente più critico. Il codice C3 opera dentro **barriere
di protezione** verificate: un errore dello scheduler può rallentare o rifiutare lavoro, mai
cambiare dati.

### 4. Rigore per classe

| Attività | C1 | C2 | C3 | C4 |
|---|---|---|---|---|
| Requisito tracciato fino a test | obbligatorio | obbligatorio | obbligatorio | — |
| Standard di codifica ([ADR-0034](0034-policy-di-compilazione-e-standard-di-codifica.md)) | integrale | integrale | integrale | parziale |
| Revisione | due passaggi con lista di controllo | due passaggi | uno | uno |
| Copertura di istruzioni e rami | 100 %, eccezioni elencate e motivate | 100 % | ≥ 95 % | — |
| Copertura delle condizioni nelle decisioni composte | 100 % (equivalente di MC/DC) | sulle decisioni segnalate | — | — |
| Modello del protocollo, esplorato | sì, per i protocolli | — | — | — |
| Fault injection | sì (FI-01…FI-13) | — | inversione di carico | — |
| Test differenziale contro il modello di riferimento | sì | sì | — | — |
| Fuzzing dei decoder | sì | sì | — | — |
| Mutation testing | sì | — | — | — |
| Soak test con crash ripetuti | sì | — | — | — |

Strategia completa in [ADR-0035](0035-strategia-di-verifica-e-tracciabilita.md) e nel
[piano di verifica](../affidabilita/piano-di-verifica.md).

### 5. Prestazioni

- Gli obiettivi della specifica restano **obiettivi**. I requisiti **vincolanti** sono i
  minimi di [ADR-0028](0028-target-e-obiettivi-di-latenza.md), ragionevoli per costruzione.
- Il costo dei controlli di affidabilità (verifica in lettura, controlli di limiti e di tipo,
  scrubbing) è **accettato** e non è un motivo per rimuoverli: se un minimo non è raggiunto,
  si interviene su algoritmi e strutture, non sui controlli.
- Nessuna ottimizzazione senza misura riproducibile (INV-X2) e senza che la suite di verifica
  della classe interessata resti verde.

### 6. Deviazioni

Le regole valgono per tutto il codice di prodotto. Uno scostamento è ammesso solo come
**deviazione registrata** (`DEV-nnn`) in
[deviazioni.md](../affidabilita/deviazioni.md): giustificazione, rischio, misura
compensativa, approvazione dell'autore.

## Basi di riferimento

Criteri adattati, non certificati. Fonti: DO-178C e DO-333 (obiettivi di verifica,
tracciabilità bidirezionale, copertura strutturale, metodi formali); IEC 61508-3 (tecniche
raccomandate: programmazione difensiva, fault injection, test basati su modello); le regole
«Power of 10» di G. Holzmann (JPL) per la codifica; la pratica dei database affidabili:
SQLite (copertura dei rami, fault injection su I/O e memoria), FoundationDB e TigerBeetle
(simulazione deterministica, asserzioni sempre attive), PostgreSQL (fallimento di `fsync`
trattato come fatale dopo il difetto noto del 2018).

## Limiti dichiarati

- **Nessuna certificazione formale** è rivendicata; si adottano le tecniche, non il
  processo di un ente.
- **Indipendenza della verifica limitata**: l'autore è uno; la mitigazione sono gli strumenti
  automatici, la revisione con liste di controllo e la rilettura da parte di un secondo
  revisore indipendente (anche automatico) *su dati, non su conclusioni* (RSK-20).
- **SBCL non è qualificato**: compilatore, GC e runtime fanno parte della base di fiducia
  (RSK-18); le difese sono i controlli end-to-end, le versioni fissate e il test su più
  piattaforme.

## Conseguenze

- Tre nuovi insiemi di artefatti: analisi dei guasti, requisiti tracciati, standard e piano
  di verifica.
- Otto nuovi invarianti (INV-A1…INV-A8).
- Alcune scelte precedenti vanno riviste con questo criterio: ADR-0015 (seqlock,
  → [ADR-0032](0032-seqlock-a-64-bit.md)), ADR-0019 (`:async`), ADR-0028 (obiettivi),
  ADR-0030 (scope: copia unica dei dati).

## Alternative considerate

- *Mantenere la priorità alle prestazioni con una buona suite di test:* incompatibile con la
  richiesta dell'autore.
- *Adottare formalmente uno standard (DO-178C, IEC 61508) con livello di integrità
  dichiarato:* richiede processi e valutazioni di un ente che non sono nello scopo; si
  adottano le tecniche con una tracciabilità propria.

## Valutazione

- Rischi: RSK-17…RSK-20 (nuovi).
- Verifica: la [matrice di tracciabilità](../tracciabilita/matrice.md) è controllata da
  `make trace`; ogni invariante e ogni scenario FI è coperto da almeno un requisito.
