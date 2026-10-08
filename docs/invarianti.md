# Invarianti

Regole che nessuna implementazione, ottimizzazione o decisione successiva può violare senza un
cambio esplicito di specifica (ADR). Derivano dai «Principi architetturali fondamentali», dagli
invarianti della sezione «Fault injection» e dalle regole normative delle singole sezioni della
[specifica](specifica/prompt-originale.md).

Ogni invariante ha un identificativo stabile. La colonna **Verifica** indica come se ne
controlla il rispetto: scenari di [fault injection](14-fault-injection.md) (`FI-…`), test,
revisione del progetto o benchmark.

## Storage

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-S1 | Lo storage è append-only: i record già scritti nei segmenti non vengono mai modificati in-place. | Storage append-only | test, revisione |
| INV-S2 | Per ogni Serie esiste esattamente un segmento `ACTIVE`. | Storage append-only | test, recovery |
| INV-S3 | Solo il segmento `ACTIVE` è scrivibile. | Segmenti | test |
| INV-S4 | I segmenti `CLOSED`, `OBSOLETE` e `RECLAIMABLE` sono sempre immutabili; un segmento non torna mai `ACTIVE` né viene riaperto in scrittura. | Storage append-only, Segmenti | test |
| INV-S5 | Le nuove scritture vanno sempre in un nuovo segmento `ACTIVE`; non si aggiungono mai record a un segmento prodotto dalla compaction. | Segmenti | test |
| INV-S6 | I segment metadata sono dati derivati: non sono l'unica fonte di verità e devono poter essere ricostruiti, verificati e corretti da WAL, dati e indice. | Segment metadata | FI-10, test |

## Compaction

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-C1 | CLEAN: 1 segmento sorgente → 1 nuovo segmento immutabile con i soli record live/necessari. | Clean | test |
| INV-C2 | MERGE: N segmenti → 1 nuovo segmento immutabile. | Merge | test |
| INV-C3 | CLEAN e MERGE sono copy-on-write: non modificano mai i segmenti sorgente. | Clean, Merge | FI-07, FI-08 |
| INV-C4 | I segmenti prodotti dalla compaction non hanno requisiti di dimensione; MERGE non è automatico dopo CLEAN; un segmento pulito può restare piccolo indefinitamente. | Segmenti, Merge | test della policy |
| INV-C5 | MERGE solo su segmenti stabili da almeno 50 secondi (dal timestamp di chiusura/stabilizzazione). | Condizioni obbligatorie per Merge | test della policy |
| INV-C6 | MERGE solo quando il carico del motore è basso; non deve competere con il traffico utente. | Low-load merge policy | test della policy, benchmark |
| INV-C7 | Un nuovo segmento non diventa visibile come definitivo prima che i suoi dati siano durevoli. | Recovery | FI-06 |
| INV-C8 | Un segmento sorgente resta recuperabile fino al completamento dello swap. | Fault injection (5) | FI-06, FI-07, FI-08 |
| INV-C9 | Una compaction interrotta è ripetibile o completabile durante il recovery. | Fault injection (6) | FI-07, FI-08 |
| INV-C10 | La compaction non blocca globalmente le letture; i reader già attivi terminano sui segmenti vecchi. | Readers durante compaction | test di concorrenza, benchmark |

## Reclaim

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-R1 | Un segmento viene eliminato solo quando nessun indice corrente, nessuno snapshot, nessuna transazione attiva e nessun reader lo referenzia o lo utilizza. | Index/Snapshot/Reclaim; Fault injection (3) | FI-09, FI-11 |

## WAL e log

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-W1 | Ogni Serie ha un WAL indipendente ed è fisicamente indipendente dalle altre; non esiste un global data WAL. | WAL, Layout fisico | revisione |
| INV-W2 | Esiste un unico `Registri/multiserie.log` per Archivio; non esiste un file per transazione. | Serie speciale Registri | revisione |

## Transazioni e durability

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-D1 | Nessun dato committed va perso. | Fault injection (1) | FI-01, FI-02, FI-05, FI-06, FI-09, FI-10 |
| INV-T1 | Una transazione single-Series usa solo il WAL della Serie e non scrive su `multiserie.log`. | Transazioni single-series | test |
| INV-T2 | Il controllo della versione attesa è atomico rispetto all'applicazione della modifica da parte del writer della Serie. | Transazioni single-series | test di concorrenza |
| INV-T3 | Una transazione multiserie è committed solo quando la decisione `COMMIT` è durevole in `multiserie.log`. | Transazioni multiserie | FI-04, FI-05 |
| INV-T4 | Nessuna transazione multiserie risulta parzialmente committed. | Fault injection (2) | FI-03, FI-04, FI-05, FI-12 |
| INV-T5 | Tutte le modifiche di una transazione multiserie condividono un unico TXID. | Transazioni multiserie | FI-12 |

## MVCC e snapshot

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-M1 | Nessuno snapshot osserva una versione non coerente: la vista resta quella del suo punto di creazione fino alla conclusione. | Snapshot/MVCC; Fault injection (4) | FI-11, test di concorrenza |
| INV-M2 | Uno snapshot impedisce alla compaction di eliminare le versioni di cui ha bisogno. | Snapshot/MVCC | FI-11 |
| INV-M3 | La cache è consapevole della versione/epoch: non restituisce a un reader una versione incompatibile con il suo snapshot. | Cache e snapshot | test di concorrenza |

## Indici

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-I1 | Gli indici sono immutabili per i reader; gli aggiornamenti diventano visibili tramite atomic swap e i reader precedenti completano sulla versione vecchia. | Index snapshot | test di concorrenza, FI-06 |
| INV-I2 | Il Bloom filter per segmento indica solo «sicuramente assente / potenzialmente presente»; non è mai la struttura di localizzazione definitiva. | Secondary index | revisione, test |

## Concorrenza e priorità

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-P1 | Un solo writer logico per Serie; molti reader concorrenti. | Concorrenza | revisione, test |
| INV-P2 | Nessun global writer lock, nessun thread permanente per Serie, nessun thread per richiesta. | Concorrenza | revisione |
| INV-P3 | Le Serie sono isolate nel carico: il traffico su una Serie non impedisce scritture, query o compaction controllata sulle altre. | Parallelismo | benchmark (burst) |
| INV-P4 | Priorità: traffico utente > WAL/durability > CLEAN necessario > MERGE opportunistico. | Compaction scheduler dinamico | benchmark, test della policy |

## Metodo

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-X1 | SIMD e ottimizzazioni native si introducono solo sugli hot path dove i benchmark ne dimostrano l'utilità. | SIMD e ottimizzazioni native | revisione |
| INV-X2 | I target di prestazione sono ipotesi finché non verificati da benchmark riproducibili; nessuna dichiarazione di superiorità da benchmark eterogenei. | Target preliminari, Confronto | revisione |
| INV-X3 | Il codice del progetto è solo Common Lisp, finché un ADR non riapre l'uso di codice foreign; lo stesso vale per i modelli e gli strumenti di verifica (nessun TLA+ o equivalente per ora). | [ADR-0001](adr/0001-common-lisp-sbcl.md) (decisione del 2026-10-01) | revisione |

## Derivati dalle decisioni di progetto (ADR 0013–0030)

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-F1 | Ogni record e ogni file persistente porta lunghezza e CRC32C; ciò che non si verifica è trattato come inesistente (coda), rigenerato (dato derivato) o dichiarato corrotto (dato confermato). | [ADR-0013](adr/0013-log-structured-segmento-active-come-log.md), [ADR-0014](adr/0014-formato-record-documento-id.md), [ADR-0039](adr/0039-cornice-unica-dei-record.md) | FI-01, FI-02, FI-10 |
| INV-V1 | Con durability `:group` o `:strong`, nessun reader vede una versione prima che sia durevole. | [ADR-0019](adr/0019-durability-e-group-commit-pipelined.md) | FI-01, FI-02 |
| INV-V2 | Uno snapshot vede una transazione multiserie per intero o per niente: il suo CSN resta fuori dall'orizzonte di visibilità finché non è applicata su tutti i partecipanti, e uno snapshot nasce solo quando l'orizzonte lo ha raggiunto (INV-M4). | [ADR-0020](adr/0020-csn-snapshot-isolamento.md), [ADR-0038](adr/0038-orizzonte-di-visibilita.md), [ADR-0041](adr/0041-multiserie-segmenti-autosufficienti.md) | FI-12, modello SPK-07 |
| INV-V3 | Una rilocazione da compaction aggiorna una entry dell'indice solo se punta ancora alla location sorgente; non sovrascrive mai una versione più nuova. | [ADR-0015](adr/0015-primary-index-swiss-table-swmr.md) | FI-06, test di concorrenza |
| INV-V4 | Ogni modifica allo stato di una Serie (indice, intenti, versioni trattenute, delta, contatori, control log) è applicata dal writer logico della Serie. | [architettura](architettura.md#contratti) | revisione |

## Affidabilità (ADR-0031…0035)

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-A1 | Un errore di scrittura, di flush, di rinomina o di sincronizzazione della directory non è mai ritentato né ignorato: la Serie (o l'Archivio, per `multiserie.log` e Registri) passa in `FAULTED` e nessuna operazione del lotto è confermata. | [ADR-0033](adr/0033-fail-stop-e-integrita-end-to-end.md) | simulatore con errori di I/O; FI-02 |
| INV-A2 | Ogni record letto, da disco o da cache, è verificato (CRC32C di intestazione e corpo, corrispondenza di chiave e CSN con l'indice; il CSN è la versione) prima di essere restituito; un dato non verificato non lascia mai il motore. | [ADR-0033](adr/0033-fail-stop-e-integrita-end-to-end.md), [ADR-0039](adr/0039-cornice-unica-dei-record.md) | corruzione deliberata, fuzzing, bit flip in memoria |
| INV-A3 | Nessun codice di prodotto è compilato con `safety` inferiore a 2; i controlli di tipo e di limiti sono sempre attivi; `truly-the` è vietato. | [ADR-0034](adr/0034-policy-di-compilazione-e-standard-di-codifica.md) | `make lint`, compilazione senza avvisi |
| INV-A4 | Nessun errore è silenzioso: ogni condizione di errore è un tipo dichiarato, gestito o propagato; `ignore-errors` è vietato; le asserzioni sugli invarianti restano attive in produzione e in C1 portano la Serie in `FAULTED`. | [ADR-0033](adr/0033-fail-stop-e-integrita-end-to-end.md), [ADR-0034](adr/0034-policy-di-compilazione-e-standard-di-codifica.md) | `make lint`, revisione, mutation testing |
| INV-A5 | Ogni requisito ha identificativo, fonte, classe e metodo di verifica; ogni invariante e ogni scenario di fault injection è coperto da almeno un requisito; la matrice è generata e controllata. | [ADR-0035](adr/0035-strategia-di-verifica-e-tracciabilita.md) | `make trace` |
| INV-A6 | I segmenti chiusi sono verificati periodicamente (scrubbing) contro CRC, hint, indici e control log; ogni ciclo completo avviene entro 7 giorni; un errore porta il segmento in quarantena prima che serva. | [ADR-0033](adr/0033-fail-stop-e-integrita-end-to-end.md) | test dello scrubber, metrica |
| INV-A7 | Il recovery è idempotente: interromperlo in qualsiasi punto e rieseguirlo produce lo stesso stato finale. | [ADR-0033](adr/0033-fail-stop-e-integrita-end-to-end.md) | interruzione in ogni punto nel simulatore |
| INV-A8 | Ogni risorsa è limitata da un valore configurato e controllato (code, buffer, richieste, connessioni, snapshot, tentativi, ricorsione, memoria); il superamento produce un rifiuto esplicito, mai un degrado non definito; nessun ciclo è illimitato. | [ADR-0033](adr/0033-fail-stop-e-integrita-end-to-end.md), [ADR-0032](adr/0032-seqlock-a-64-bit.md) | test di saturazione, revisione |

## Derivati dall'analisi progettuale (ADR 0036–0045)

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-F2 | Un lotto è atomico: è valido per intero — il suo SEAL ne fissa file, posizione, numero di record e contenuto — oppure non esiste; nessun record di un lotto non valido è mai applicato. Un record non prepared è committed se e solo se sta in un lotto valido. | [ADR-0037](adr/0037-lotto-sigillato.md), [ADR-0039](adr/0039-cornice-unica-dei-record.md) | FI-01, FI-02, fuzzing, corruzione deliberata |
| INV-F3 | Coda o corruzione si decidono dal contenuto del log: ogni SEAL porta la frontiera durevole nota alla chiusura del lotto; un'anomalia sotto la frontiera dichiarata da un SEAL successivo valido è corruzione (fail-stop, nessuna scrittura), altrimenti è una coda. La decisione non dipende dall'ordine in cui il supporto rende persistenti le scritture non sincronizzate. | [ADR-0037](adr/0037-lotto-sigillato.md) | FI-01, FI-02 con persistenza non ordinata, modello SPK-07 |
| INV-V5 | Una scrittura è confermata solo dopo essere stata pubblicata e, con `:group` o `:strong`, solo dopo essere durevole: dopo la conferma ogni lettura successiva la vede. Vale per le single-Series e per le multiserie. | [ADR-0037](adr/0037-lotto-sigillato.md), [ADR-0041](adr/0041-multiserie-segmenti-autosufficienti.md) | test differenziale, FI-05, FI-12 |
| INV-M4 | Uno snapshot con CSN `s` esegue la prima lettura solo quando l'orizzonte di visibilità è ≥ `s`: ogni commit con CSN ≤ `s` è già pubblicato o annullato, e nessuno può comparire dopo. | [ADR-0038](adr/0038-orizzonte-di-visibilita.md) | modello SPK-07, test di proprietà nel simulatore, FI-11 |
| INV-M5 | Per ogni documento l'ordine dei CSN coincide con l'ordine delle versioni; il CSN identifica la versione, è il valore di expected-version e non si ripete mai, nemmeno dopo l'eliminazione del documento. | [ADR-0038](adr/0038-orizzonte-di-visibilita.md) | modello SPK-07, test differenziale |
| INV-M6 | Ogni CSN assegnato e non ancora pubblicato o annullato occupa uno slot esclusivo del registro limitato dei CSN in volo; assegnazione e registrazione sono indivisibili rispetto all'avanzamento di H. Nessuno slot è riusato prima del completamento del suo CSN. Quando il registro è vuoto H raggiunge l'ultimo CSN assegnato, indipendentemente dalla distanza dal primo pendente. | [ADR-0046](adr/0046-orizzonte-con-registro-limitato.md) | controesempio dell'anello e modello del registro in SPK-07 |
| INV-S7 | Un segmento `CLOSED` è autosufficiente: un suo record prepared è committed se e solo se l'esito è nello stesso segmento o nel record del manifest che lo ha chiuso; ogni altro record prepared è abortito. La rotazione attende che la Serie non abbia intenti pendenti. | [ADR-0041](adr/0041-multiserie-segmenti-autosufficienti.md) | FI-03, FI-05, FI-12, modello SPK-07 |
| INV-C11 | Un tombstone è scartato solo se è superato da una versione durevole più recente, oppure se nessuna versione della chiave è trattenuta e nessun altro segmento può contenere un record più vecchio della stessa chiave. Il primary index contiene solo documenti vivi e la sua ricostruzione (CSN massimo per chiave) non dipende dall'ordine dei segmenti: nessun documento eliminato riappare. | [ADR-0042](adr/0042-tombstone-e-indice-dei-vivi.md) | test di proprietà con MERGE non adiacenti e riavvii, FI-07, FI-08, FI-10 |
| INV-I3 | Nessuna manutenzione del primary index copia gli slot di più di un frammento sorgente; lo spazio di slot e chiavi eliminati è recuperato alla divisione o ricostruzione del frammento; nessuna struttura dell'indice cresce senza limite per inserimenti ed eliminazioni ripetuti. Directory e chiavi hanno budget distinti. | [ADR-0043](adr/0043-primary-index-a-frammenti.md), [ADR-0050](adr/0050-pubblicazione-e-costi-della-directory.md) | SPK-01, test di saturazione |
| INV-P6 | Il parallelismo è strutturale: ogni lavoro appartiene a un'unità (Archivio, Serie, reader, lotto, segmento, frammento) che procede senza attendere le altre dello stesso livello. Tra Serie non esiste alcun lock né alcuna scrittura condivisa sul percorso di una singola operazione; gli elementi condivisi sono soltanto quelli dell'elenco chiuso in [architettura](architettura.md#archivio-coordinamento-minimo), ciascuno con costo limitato e pagato al più una volta per lotto, per transazione multiserie o per snapshot. | [ADR-0036](adr/0036-leggi-di-progetto.md), [ADR-0045](adr/0045-modello-di-esecuzione.md) | revisione dell'elenco chiuso, benchmark di scalabilità con Serie e core, benchmark di isolamento (burst), SPK-04 |
| INV-P5 | Un compito non si sospende e un worker di calcolo non esegue chiamate bloccanti: ogni attesa è un parcheggio in una lista con lunghezza e tempo massimi; ogni chiamata bloccante è un compito del pool di I/O. | [ADR-0045](adr/0045-modello-di-esecuzione.md) | revisione, test di saturazione, SPK-04 |
| INV-A9 | Il recovery non modifica e non tronca alcun segmento esistente: i suoi soli effetti durevoli sono record nelle fonti di verità e completamenti idempotenti; un `ACTIVE` trovato al riavvio viene chiuso alla sua lunghezza valida e sostituito da uno nuovo. | [ADR-0036](adr/0036-leggi-di-progetto.md), [ADR-0037](adr/0037-lotto-sigillato.md), [ADR-0040](adr/0040-manifest-a-record-unico.md) | interruzione del recovery in ogni punto, confronto byte a byte dei segmenti prima e dopo |
| INV-A10 | Nulla si distrugge per assenza: un file o una directory si elimina solo se è `.tmp` e nessuna fonte di verità lo nomina, o se una fonte di verità ne registra la rimozione; un oggetto con nome definitivo sconosciuto è un'anomalia segnalata e non viene toccato. | [ADR-0036](adr/0036-leggi-di-progetto.md), [ADR-0040](adr/0040-manifest-a-record-unico.md) | FI-09, FI-13, test del verificatore |
| INV-A11 | Ogni operazione che cambia lo stato durevole ha un solo punto di atomicità, un record durevole nella fonte di verità del suo livello; prima c'è solo preparazione scartabile, dopo solo completamento idempotente. | [ADR-0036](adr/0036-leggi-di-progetto.md) | modello SPK-07 con crash prima e dopo ogni punto |
| INV-A12 | La cache è un acceleratore puro: il sistema è corretto con la cache disattivata e la cache non compare in alcun protocollo; una verifica fallita su un dato in cache lo scarta e rilegge dal segmento, senza mettere in quarantena il segmento. | [ADR-0044](adr/0044-cache-acceleratore-puro.md) | test differenziale con e senza cache, bit flip nell'arena |

## Corrispondenza con i principi della specifica

Tutti i 33 punti dei «Principi architetturali fondamentali» sono coperti: i principi che sono
vincoli verificabili sono invarianti qui sopra; quelli che sono indirizzi di progetto (group
commit, scheduler dinamico, primary index altamente ottimizzato, secondary index specializzati,
cache anti-scan-pollution, thread pool dinamico, recovery crash-safe, fault injection, benchmark
riproducibili) sono requisiti dei rispettivi documenti tematici e ADR.

## Applicazione dei budget ai limiti documentali

ADR-0048 applica INV-A8 a documenti (16 MiB), profondità (100), chiavi (65.535 byte), arene e copie. INV-F1 richiede distinzione v1/v2; INV-A11 governa la migrazione. Nessun risultato v1 verifica automaticamente v2.
