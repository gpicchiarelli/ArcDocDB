# 15 — Ottimizzazioni native e SIMD

> **Fonte:** «SIMD e ottimizzazioni native» della [specifica](specifica/specifica-originale.md),
> emendata da [ADR-0001](adr/0001-common-lisp-sbcl.md).
> **Moduli:** M18 SIMD/Hot Path Optimization Layer.

## Vincolo corrente: solo Common Lisp

**Decisione del 2026-10-01:** per ora il progetto è **solo Common Lisp**. La specifica ammette,
per hot path estremi, il ricorso a C/C++ o Rust tramite funzioni foreign; questa possibilità è
**sospesa** finché non viene riaperta con un nuovo ADR. Tutto il codice del repository,
compresi spike e strumenti di benchmark, è Common Lisp su SBCL.

Restano utilizzabili le estensioni e i contrib di SBCL (thread, primitive atomiche, accesso
alle chiamate di sistema), perché sono Common Lisp sull'implementazione di riferimento.

## Progettare «SIMD-friendly»

Il database DEVE essere progettato per essere SIMD-friendly. In Common Lisp/SBCL questo
significa, nell'ordine:

1. usare strutture dati compatte;
2. usare typed arrays;
3. dichiarare i tipi;
4. minimizzare boxing e allocazioni;
5. favorire accessi sequenziali;
6. profilare;
7. valutare sistematicamente le varianti SIMD utilizzabili in sicurezza **su ogni hot path
   misurato**, adottando quelle il cui beneficio è dimostrato (INV-X1).

I primi cinque punti sono scelte di *layout dei dati*, e vanno fatte in fase di architettura:
non si recuperano dopo. Gli ultimi due sono attività guidate dalle misure.

SBCL può generare codice SIMD automaticamente in alcuni casi numerici opportunamente tipizzati.

## Scala di intervento

| Livello | Strumento | Stato |
|---|---|---|
| 1 | Common Lisp tipizzato: array specializzati, dichiarazioni, nessuna allocazione | sempre |
| 2 | Operazioni specifiche di SBCL | ammesso, sugli hot path misurati |
| 3 | Funzioni foreign, C/C++, Rust | **sospeso** (solo Common Lisp per ora) |

Si valuta il livello successivo sui percorsi caldi misurati; lo si adotta solo quando
le prove mostrano un beneficio mantenendo tutti i controlli.

## Selezione sicura e verifica dei backend

Questi sono criteri obbligatori per introdurre un kernel nel motore; gli spike esistenti
non attestano dispatcher, ripiego o qualificazione del prodotto.

La precisazione del 2026-10-22 ad [ADR-0012](adr/0012-simd-guidato-dai-benchmark.md)
richiede di valutare tutte le varianti disponibili per gli hot path misurati su **Linux
x86-64**, piattaforma di riferimento, e **macOS ARM64**, sviluppo supportato. La scelta
dipende dall'operazione, dalla dimensione e dalle misure; una maggiore larghezza vettoriale
non dimostra un vantaggio. Le estensioni non provate restano da qualificare.

Prima di eseguire un kernel, la selezione deve verificare il supporto effettivo della CPU,
del sistema operativo e del runtime SBCL. La sola architettura dichiarata non basta.
Il percorso scalare di riferimento rimane sempre eseguibile e forzabile, come ogni backend
disponibile nei test; viene usato se la variante è assente, non qualificata o non conveniente
per quel carico. Un errore di dati o di invarianti conserva la propria semantica e non
innesca un ripiego che lo nasconda.

Ogni kernel conserva tipo, limiti, immutabilità degli input e semantica degli errori del
riferimento. Vale `safety 3` predefinito, con le sole eccezioni già regolate da
[ADR-0034](adr/0034-policy-di-compilazione-e-standard-di-codifica.md). Ogni caricamento
e scrittura vettoriale deve rientrare interamente nella finestra logica autorizzata:
nessuna lettura oltre la fine, neppure in padding accessibile. Le code hanno un percorso
scalare verificato; un accesso disallineato è ammesso solo con semantica verificata sul
backend, altrimenti si usa il percorso scalare.

La verifica differenziale usa un oracolo indipendente e forza ciascun backend disponibile
e quello scalare: buffer vuoti e corti, lunghezze attorno alla larghezza vettoriale,
offset disallineati, code, input avversari e rifiuti devono dare risultati ed errori
equivalenti senza modifiche estranee. Dataset, parametri e metodo dei benchmark sono comuni
alle due piattaforme; per ciascuna si conservano ambiente, codice generato, risultati,
allocazioni e costo della selezione. `unsupported` resta distinto da una prova superata.
Un microbenchmark o una misura ARM64 non qualificano il percorso completo o x86-64.

## Candidati SIMD

- bitmap AND/OR/XOR;
- Bloom filter;
- scansioni;
- confronti;
- filtri;
- parsing;
- hashing;
- compressione/decompressione.

Lo storage append-only con segmenti immutabili e scansioni sequenziali favorisce queste
ottimizzazioni: i dati sono contigui e non cambiano sotto il lettore.

## Questioni decise e rischi

- **QA-18** ([ADR-0024](adr/0024-memoria-e-gc.md)) — Garbage collector e memoria: quali strutture vivono nello heap Lisp e quali
  fuori (RSK-01). È il rischio tecnico principale della scelta di SBCL.
- **QA-19** ([ADR-0017](adr/0017-piattaforma-e-io.md)) — Architettura di riferimento. Il supporto SIMD esplicito di SBCL va verificato
  per architettura (x86-64 e ARM64): lo sviluppo avviene su macOS/ARM64, la piattaforma di
  riferimento è Linux x86-64 (RSK-11).
- Il vincolo «solo Common Lisp» riguarda anche le chiamate di sistema per l'I/O: va verificato
  nello spike sul WAL che `fsync` e le letture posizionali siano raggiungibili senza codice
  non-Lisp e senza allocazioni sul percorso critico (SPK-03, SPK-05).
