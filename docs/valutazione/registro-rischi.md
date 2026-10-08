# Registro dei rischi

> Valutazione preliminare. Vedi le [avvertenze](README.md). Probabilità e impatto sono giudizi
> qualitativi (B bassa, M media, A alta) da rivedere dopo ogni spike.

## Prima evidenza SPK-04 (2026-10-08)

> **Proposta** — La [campagna SPK-04](risultati-SPK-04-2026-10-08.md)
> verifica localmente FIFO, esclusività del writer, code limitate e modelli
> di parcheggio/ripartenza. RSK-04 resta aperto sulle prestazioni: finestre
> brevi, pool creato per caso e carico preaccodato non confermano i target.
> In SPK-04 lo scheduler adattivo e i controllori di RSK-12 non sono esercitati.

## Prima evidenza SPK-06 (2026-10-08)

> **Proposta** — La [campagna SPK-06](risultati-SPK-06-2026-10-08.md)
> verifica confini, timer continui e quote nel modello finito del carico;
> misura separatamente interferenza locale di copie buffered con letture.
> RSK-12 resta aperto sul feedback reale, sulla calibrazione e sull'AIMD del
> pool. La starvation di RSK-08 resta accettata: nessuna soglia di emergenza
> è introdotta. Le misure non verificano una compaction del motore.

## Quadro

> **Deciso (prime prove SPK-07 → ADR-0046, 2026-10-08)** — RSK-05 è nuovamente aperto
> sulla verifica: l'anello dell'orizzonte perde un completamento con un commit lento anche
> rispettando i crediti. Il registro limitato dei pendenti corregge il controesempio nel
> piccolo modello. Restano memoria debole, scadenza snapshot, interleaving di compaction e
> writer e fault injection sul futuro motore. Le mitigazioni di progetto non sono prove di
> correttezza dell'implementazione.

| ID | Rischio | Prob. | Impatto | Verifica | Questioni |
|---|---|---|---|---|---|
| [RSK-01](#rsk-01) | Pause del GC di SBCL incompatibili con il P99 | M | A | SPK-02 | QA-18 |
| [RSK-02](#rsk-02) | Primary index: progetto non ancora definito su concorrenza, snapshot, rilocazione | M | A | SPK-01, SPK-07 | QA-24, QA-04 |
| [RSK-03](#rsk-03) | Amplificazione di scrittura oltre la banda del dispositivo | M | A | SPK-03 | QA-02 |
| [RSK-04](#rsk-04) | Tetto del writer singolo per Serie sotto i target | M | M | SPK-04 | QA-26, QA-25 |
| [RSK-05](#rsk-05) | Transazioni multiserie: visibilità atomica e stato PREPARED | M | A | SPK-07 | QA-06, QA-07, QA-09 |
| [RSK-06](#rsk-06) | `multiserie.log` come punto di contesa dell'Archivio | B | M | SPK-03 | QA-08 |
| [RSK-07](#rsk-07) | Memoria dell'indice e tempo di riavvio | M | M | SPK-01 | QA-03 |
| [RSK-08](#rsk-08) | MERGE mai eseguito sotto carico sostenuto | M | M | SPK-06 | QA-12 |
| [RSK-09](#rsk-09) | Spazio trattenuto da snapshot longevi | M | M | — | QA-14 |
| [RSK-10](#rsk-10) | Cache: doppia memorizzazione e raffreddamento dopo la compaction | M | B | SPK-05 | QA-17 |
| [RSK-11](#rsk-11) | Divergenza tra piattaforma di sviluppo e di riferimento | A | M | SPK-03, SPK-08 | QA-19 |
| [RSK-12](#rsk-12) | Instabilità dei controllori dinamici | M | M | SPK-06 | QA-12 |
| [RSK-13](#rsk-13) | Costo e consistenza degli indici secondari | M | M | — | QA-25 |
| [RSK-14](#rsk-14) | Ampiezza del progetto | A | M | — | QA-23 |
| [RSK-15](#rsk-15) | Bootstrap di Registri e del catalogo | B | M | — | QA-10 |
| [RSK-16](#rsk-16) | Vincolo «solo Common Lisp» sulle primitive di I/O e SIMD | M | M | SPK-03, SPK-05, SPK-08 | QA-19, QA-22 |
| [RSK-17](#rsk-17) | Copia unica dei dati: perdita del supporto = perdita dei dati | M | A | backup (ADR-0030), verificatore | — |
| [RSK-18](#rsk-18) | Difetti nella base di fiducia: SBCL (compilatore, GC, runtime), sistema operativo, firmware | B | A | CI su due piattaforme, soak, controlli end-to-end | — |
| [RSK-19](#rsk-19) | Il costo dei controlli di affidabilità (CRC in lettura, safety ≥ 2, scrubbing) supera il budget di prestazione | M | M | SPK-09 | — |
| [RSK-20](#rsk-20) | Indipendenza della verifica limitata: autore unico | A | M | strumenti, liste di controllo, revisione su dati | — |

## Stato dopo gli ADR (2026-10-03)

| ID | Stato | Effetto delle decisioni |
|---|---|---|
| RSK-01 | **aperto (quantitativo)** | ADR-0024 minimizza il lavoro del GC; ADR-0028 fissa il criterio (pausa ≤ 5 ms); decide SPK-02 |
| RSK-02 | mitigato sul progetto; **aperto sulle prestazioni** | ADR-0015/0016/0018 definiscono struttura, concorrenza, rilocazione; SPK-01 e SPK-07 verificano |
| RSK-03 | mitigato | ADR-0013: 1× scrittura; residuo: flush concorrenti di molte Serie (SPK-03) |
| RSK-04 | mitigato | ADR-0019: writer mai bloccato; ADR-0028: target per Serie = 1/4 dell'aggregato |
| RSK-05 | mitigato sul progetto | ADR-0020/0021: CSN dopo decisione, attesa delle multiserie in applicazione, intenti no-wait; modello SPK-07 |
| RSK-06 | mitigato | ADR-0021: group commit e troncamento per checkpoint |
| RSK-07 | accettato, quantificato | ~56 B/entry (ADR-0032); riavvio dagli hint (ADR-0015) |
| RSK-08 | accettato esplicitamente | ADR-0023: metrica e allarme, nessuna soglia di emergenza |
| RSK-09 | mitigato | ADR-0020: durata massima degli snapshot |
| RSK-10 | mitigato | ADR-0025: ri-etichettatura delle entry alla rilocazione |
| RSK-11 | mitigato | ADR-0017: piattaforma di riferimento fissata; `durable-flush` per piattaforma |
| RSK-12 | mitigato | ADR-0023: due segnali, isteresi, stati espliciti |
| RSK-13 | mitigato | ADR-0026: indici per segmento, costruiti alla chiusura, nessuna fusione separata |
| RSK-14 | mitigato | ADR-0030: scope v1; roadmap a fette verticali |
| RSK-15 | mitigato | ADR-0022: configurazione incorporata, macchina a stati DDL |
| RSK-16 | mitigato | ADR-0017/0027: chiamate di sistema via contrib; primitive proprie |
| RSK-17 | **aperto** | ADR-0030 (proposta): backup consistente e verificatore offline nella v1; mirroring in v1.1 |
| RSK-18 | residuo dichiarato | ADR-0033/0034: verifica end-to-end, controlli sempre attivi; versione di SBCL fissata; CI su Linux e macOS |
| RSK-19 | **aperto (quantitativo)** | ADR-0031 §5: i minimi di prestazione sono ragionevoli; SPK-09 misura il costo |
| RSK-20 | residuo dichiarato | ADR-0031: strumenti automatici, lista di controllo, rilettura su dati |
| RSK-02 (aggiornamento) | mitigato più a fondo | ADR-0032: seqlock a 64 bit, nessun argomento temporale |

## Stato dopo l'analisi progettuale (2026-10-03)

L'[analisi progettuale](../analisi-progettuale.md) ha trovato difetti in mitigazioni date per
acquisite; le decisioni 0036–0045 li chiudono sul progetto. Restano da verificare su modello
(SPK-07) e con misure.

| ID | Stato | Effetto delle decisioni |
|---|---|---|
| RSK-02 | mitigato sul progetto; **aperto sulle prestazioni** | ADR-0043: frammenti; nessun fermo del writer né picco di memoria alla crescita; slot a 4 parole. SPK-01 misura |
| RSK-03 | mitigato; residuo dichiarato | ADR-0037: un crash ordinario non è più classificato come corruzione; resta RES-05 (danno a riposo dell'ultimo flush) |
| RSK-04 | mitigato più a fondo | ADR-0039: nessun lavoro per byte nel writer oltre alla copia; nessun TXID per operazione |
| RSK-05 | mitigato più a fondo | ADR-0038: l'orizzonte copre anche i lotti in volo (prima uno snapshot poteva cambiare vista); ADR-0041: l'esito non può essere separato dai record che risolve |
| RSK-07 | accettato, **stima corretta** | ~75–80 B per documento in media, ~650 milioni di documenti per 64 GB (prima: 56 B, valore valido solo al riempimento massimo) |
| RSK-10 | accettato, da misurare | ADR-0044: nessuna ri-etichettatura; la perdita di calore dopo la compaction si misura (SPK-05) prima di aggiungere un meccanismo |
| RSK-13 | **aperto (quantitativo)** | il costo di una query cresce con il numero di segmenti: limite dichiarato in [limiti.md](../limiti.md); filtri sui valori nei file indice |
| RSK-15 | mitigato più a fondo | ADR-0040: creazione con directory `.tmp`, nessuno stato `creating`, nessuna eliminazione per assenza |
| RSK-01 | **aperto (quantitativo)** | in più: pausa in funzione del numero di thread e dei frammenti sostituiti (SPK-02) |
| RSK-18, RSK-20 | residuo dichiarato, ridotto | ADR-0036: un difetto nel calcolo di manifest o catalogo lascia un oggetto sconosciuto segnalato, non una perdita; il recovery non scrive nei segmenti |

---

## Stato dopo la prima campagna locale (2026-10-08)

Fonte: [misure e dati grezzi](risultati-2026-10-08.md). Nessun rischio è chiuso
dai soli microbenchmark. Le evidenze v1 e v2 sono distinte e parziali.

| Rischio | Evidenza | Azione restante |
|---|---|---|
| RSK-01 | 48 casi a 128 MiB; chiamate GC con 64 worker attivi possono durare decine di ms o più; non è tempo STW esatto | pool reale, worker parcheggiati/I/O, heap grandi e Linux |
| RSK-02, RSK-07 | v1 a 10 milioni: 82,21 B/doc e split massimo 98,827 ms; v2: 664 confronti con oracle e sette rifiuti senza modifica dello stato; costo O(2^G) della directory precisato da ADR-0050 | scala superiore, churn lungo, directory/split v2, memoria debole e RSS |
| RSK-03, RSK-11 | F_FULLFSYNC circa 4 ms con un file; mediana circa 12 ms con quattro file | pipeline reale, numero di Serie, campagna Linux e fault injection |
| RSK-05 | anello dell'orizzonte corretto; prova del CSN prepared aggiunta con ADR-0047 | resolver autorevole, interleaving mancanti e crash reali |
| RSK-19 | slicing-by-8 circa 0,7 GB/s sui corpi v1; inline evita boxing osservato del CSN; codec v2: 416 casi e record massimo verificato | I/O, prepared e percorso completo v2, disassemblato x86-64 |

Le vecchie righe sul costo C della manutenzione e sull'assenza di picchi sono
storiche: slot, chiavi, directory, oggetti trattenuti e collector hanno costi
distinti. La correzione non aggiunge coordinamento fra Serie.

---

### RSK-01


**Pause del GC di SBCL.** Il collector di SBCL ferma tutti i thread durante una collezione:
è una contesa *globale*, che attraversa l'isolamento tra Serie. Con heap grandi e alta
allocazione le pause possono dominare il P99.

- *Mitigazioni:* nessuna allocazione sul hot path; indici e cache in array specializzati senza
  puntatori o fuori dallo heap gestito; regolazione del collector; valutazione delle varianti
  di collector disponibili in SBCL.
- *Segnale di allarme:* pause superiori all'obiettivo di P99 con il solo carico di lettura.
- *Nota:* la specifica prevede già le metriche GC e le strutture compatte; non prevede un
  obiettivo numerico di pausa (QA-26).

### RSK-02

**Primary index.** Vedi tensioni T1 e T3 nell'[analisi critica](analisi-critica.md). La
struttura più sollecitata del sistema ha tre requisiti in conflitto apparente e nessun
meccanismo specificato.

- *Mitigazioni:* decidere QA-24 con un ADR sostenuto da un prototipo (SPK-01) e da un modello
  dello swap (SPK-07) prima di qualsiasi altro lavoro sullo storage.

### RSK-03

**Amplificazione di scrittura.** Vedi [stime](stime-ordine-di-grandezza.md#banda-di-scrittura).

- *Mitigazioni:* scelta di QA-02 che scriva i dati una sola volta; compressione; limitazione
  della banda di CLEAN/MERGE; revisione della fascia alta dei target.

### RSK-04

**Tetto del writer singolo.** Tutto ciò che entra nella parte seriale riduce il throughput
massimo di una Serie.

- *Mitigazioni:* lavoro parallelizzabile fuori dal writer; elaborazione a lotti; indici
  secondari aggiornati fuori dal percorso critico; chiarire QA-26. Per carichi che superano
  una Serie, il modello prevede già di distribuire su più Serie.

### RSK-05

**Transazioni multiserie.** Vedi tensioni T4 e T5. I rischi sono di correttezza (uno snapshot
che vede metà transazione) e di prestazioni (documenti bloccati in PREPARED, writer in
attesa).

- *Mitigazioni:* modello del protocollo esplorato esaustivamente con i crash FI-03, FI-04,
  FI-05, FI-12 prima dell'implementazione (SPK-07); regola di recovery esplicita.

### RSK-06

**`multiserie.log` condiviso.** È l'unico log attraversato da tutte le transazioni multiserie
di un Archivio. Con group commit il rischio è contenuto, ma un flush lento su questo file
rallenta tutte le multiserie. Inoltre è un file unico che cresce.

- *Mitigazioni:* group commit; politica di troncamento (QA-08); metrica dedicata.

### RSK-07

**Memoria e riavvio.** Vedi [stime](stime-ordine-di-grandezza.md#memoria-del-primary-index).

- *Mitigazioni:* entry compatte; file di hint o checkpoint (QA-03); recovery parallelo per
  Serie; documentare il limite di capacità per server.

### RSK-08

**MERGE mai eseguito.** Vedi tensione T7.

- *Mitigazioni:* metrica e allarme sul numero di segmenti piccoli; strutture che tollerano
  migliaia di segmenti; decisione esplicita sull'eventuale soglia di emergenza (QA-12).

> **Deciso (QA-12 → ADR-0023)** — La starvation del MERGE è accettata con
> metrica e allarme; non è prevista una soglia di emergenza. SPK-06 verifica
> la policy su tracce finite e non dimostra progresso sotto carico sostenuto.

### RSK-09

**Snapshot longevi.** Trattengono versioni e segmenti; con molte scritture lo spazio occupato
cresce senza limite per la durata dello snapshot.

- *Mitigazioni:* metrica sull'età del più vecchio snapshot; durata massima configurabile
  (QA-14).

### RSK-10

**Cache.** Se i segmenti si leggono attraverso la page cache del sistema operativo, i dati
stanno in memoria due volte. Inoltre la rilocazione di CLEAN/MERGE cambia le location: una
cache indicizzata per location perde il calore dei record spostati.

- *Mitigazioni:* decidere la modalità di lettura (QA-19); valutare il trasferimento delle
  entry calde durante la compaction; misurare prima di complicare.

> **Proposta** — La [campagna SPK-05](risultati-SPK-05-2026-10-08.md)
> confronta pread e mapping su file da 16 MiB. Non esercita cache propria,
> rilocazioni o dataset oltre RAM: RSK-10 rimane quantitativamente aperto.

### RSK-11

**Piattaforme.** Sviluppo su macOS/ARM64; l'hardware di riferimento (16–32 core, NVMe PCIe
4/5) fa pensare a server x86-64 con Linux, ma non è deciso. Differiscono la semantica del
flush, le primitive di I/O, il supporto SIMD in SBCL e il comportamento del GC.

- *Mitigazioni:* decidere QA-19 subito; eseguire gli spike di I/O sulla piattaforma di
  riferimento; trattare le misure sulla macchina di sviluppo come indicative.

### RSK-12

**Controllori dinamici.** La low-load policy usa due segnali smussati secondo ADR-0023;
il thread pool considera anche code, CPU e backlog secondo ADR-0011. Un controllore
mal tarato oscilla o reagisce in ritardo, e i suoi difetti possono emergere sotto
carico reale.

- *Mitigazioni:* partire da pochi segnali e regole semplici con isteresi; simulare il
  controllore su tracce di carico; rendere osservabile ogni decisione dello scheduler.

> **Proposta** — SPK-06 verifica soglie e transizioni nel modello finito.
> Feedback sul dispositivo, EWMA da metriche reali e AIMD del pool restano
> da verificare; la campagna I/O è indipendente dal modello del controllore.

### RSK-13

**Indici secondari.** Quattro strutture diverse più Bloom filter, ciascuna con modello a
delta, da tenere coerenti con commit, snapshot e recovery. Se aggiornati dal writer logico,
ne consumano il budget.

- *Mitigazioni:* rinviare a dopo lo storage di base; decidere QA-25; introdurre un tipo di
  indice alla volta.

### RSK-14

**Ampiezza.** Diciotto moduli, tra cui un motore di query, un protocollo di rete e un
controllore adattivo, sono un impegno considerevole.

- *Mitigazioni:* fetta verticale minima (una Serie, GET/PUT, WAL, recovery) prima di ogni
  altra cosa; funzioni fuori scope dichiarate (QA-23); fasi con criteri di uscita
  ([roadmap](../roadmap.md)).

### RSK-15

**Bootstrap.** Vedi tensione T9.

- *Mitigazioni:* configurazione di Registri incorporata nel codice; recovery di Registri come
  primo passo, separato da quello delle altre Serie.

### RSK-16

**Solo Common Lisp.** Il vincolo esclude librerie C per I/O asincrono, compressione, hashing
e SIMD. Tutto deve essere ottenuto con SBCL, i suoi contrib ed eventuali librerie Common Lisp.

- *Mitigazioni:* verificare negli spike che flush, letture posizionali e operazioni atomiche
  siano disponibili senza allocazione; scrivere in Common Lisp le poche primitive necessarie
  (checksum, hash); riaprire il vincolo con un ADR solo davanti a una misura.

> **Proposta** — [SPK-05](risultati-SPK-05-2026-10-08.md) esegue pread,
> mmap e verifica CRC in Common Lisp/SBCL su macOS ARM64. Il ciclo isolato
> finale non mostra allocazioni nel campione; Linux e le altre primitive
> rimangono da verificare. La disponibilità locale non chiude RSK-16.
- *Lato positivo:* un solo linguaggio, un solo modello di memoria da capire, nessun confine
  foreign da attraversare sul hot path.

### RSK-17

**Copia unica dei dati.** Un solo dispositivo nella v1: la perdita del supporto è perdita dei
dati, qualunque sia la qualità del software. Con l'affidabilità come fine ultimo è il rischio
residuo più grande ([analisi dei guasti](../affidabilita/analisi-dei-guasti.md), RES-03).

- *Mitigazioni:* backup consistente (segmenti chiusi, control log, hint a un CSN) verificabile
  dal verificatore offline; i segmenti immutabili rendono il backup incrementale e poco
  costoso; mirroring dei segmenti su un secondo percorso come estensione prevista.
- *Decisione richiesta all'autore:* [ADR-0030](../adr/0030-scope-v1.md) (backup e verificatore
  nella v1).

### RSK-18

**Base di fiducia.** Compilatore, GC e runtime di SBCL, kernel e firmware non sono qualificati.

- *Mitigazioni:* verifica end-to-end (CRC e confronto con l'indice a ogni lettura); controlli
  di tipo e limiti sempre attivi; versione di SBCL fissata; CI su Linux e macOS; soak test.
- *Limite:* un difetto che produce un dato sbagliato **con CRC valido** non è rilevabile da
  dentro.

### RSK-19

**Costo dei controlli.** CRC32C in Common Lisp tipizzato, `safety` ≥ 2, scrubbing in
background: tutti consumano CPU e banda.

- *Mitigazioni:* i minimi di prestazione di [ADR-0028](../adr/0028-target-e-obiettivi-di-latenza.md)
  sono ragionevoli per costruzione; SPK-09 misura throughput del CRC (anche a tabelle) e
  overhead; se un minimo non è raggiunto si interviene su algoritmi, non sui controlli.

### RSK-20

**Indipendenza limitata.** Chi scrive è anche chi verifica.

- *Mitigazioni:* strumenti che non dipendono dall'autore (linter, tracciabilità, simulatore,
  modelli, fuzzing, mutation testing); lista di controllo di revisione; rilettura da un secondo
  revisore su dati verificabili ([piano di verifica](../affidabilita/piano-di-verifica.md)).

## Impatto dei limiti v2

ADR-0048 amplia chiavi e slot: aumenta RSK-07 (memoria) e il costo di split, hashing e verifica. Le evidenze SPK-01/SPK-09 v1 non chiudono questi rischi per v2. Richieste massime e profondità richiedono budget di decoder e protocollo. ADR-0049 resta una proposta: lookup freddi, write amplification e crash del nuovo indice richiedono evidenze prima dell’adozione.
