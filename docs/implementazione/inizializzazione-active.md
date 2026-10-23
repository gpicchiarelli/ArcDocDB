# Inizializzazione di un nuovo segmento writer

`arcdocdb.active` prepara l'header di un nuovo `.seg.tmp` e collega il risultato
al [resolver ACTIVE](get-active.md). Esegue la preparazione del file prevista da
[ADR-0040](../adr/0040-manifest-a-record-unico.md#2-prepara-decidi-completa): header,
flush del file e sincronizzazione della directory. L'**EDIT durevole** rimane
la decisione che apre il segmento nel manifest; questo modulo non lo scrive.

## API e responsabilità

| API | Risultato |
|---|---|
| `prepara-segmento-attivo(view, input, append, directory, id, created-at, header, scratch, :version)` | log, capacità GET e prova di identità, dopo flush e rilettura |
| `log-segmento-attivo-preparato(prepared)` | log canonico per costruire un solo controller della Serie |
| `crea-sorgente-get-preparata(controller, lease, prepared, :limiti…)` | sorgente ACTIVE con associazione fisica obbligatoria, senza I/O |
| `verifica-capienza-lettura(file, count)` | preflight del budget readonly, senza buffer, offset o syscall |

Il controller riserva il namespace e l'identificativo, crea il nuovo append con
`crea-temporaneo` (**O_EXCL**, mai riapertura di un segmento esistente), apre la
capacità readonly e la directory parent autorevole. Le capacità e i due buffer
sono esclusivi fino al ritorno della preparazione, eseguita nel pool I/O.
`created-at` è fornito dal chiamante come u64; il modulo non legge un orologio.

L'associazione dei due file è [verificata tramite device/inode](associazione-file.md).
La directory deve essere il parent effettivo del nome riservato: è una
precondizione del controller, non deducibile dai due inode. I tre file devono
usare la medesima istanza di backend, compreso `nil` per il percorso nativo.
I callback restano fidati e rispettano ownership e stabilità dei buffer.

## Ordine degli effetti

1. Verificare formato v1/v2, ID positivo u32, due range di almeno 64 byte,
   assenza di alias, capacità aperte, budget di lettura/append e frontiere
   append scritta/durevole entrambe zero. Nessun effetto I/O o sui buffer.
2. Verificare l'identità fisica readonly/append e creare il log privato.
   Un callback `identity` assente o un'identità diversa impedisce la scrittura.
3. Preparare l'header canonico **writer**, con Serie, ID, versione, timestamp,
   riservati zero e CRC. Scrivere esattamente 64 byte nel nuovo append.
4. Sincronizzare il file; verificare il ritorno a 64.
5. Rileggere con `crea-segmento-get` attraverso la capacità readonly associata:
   verificare header/CRC/Serie/ID/formato. Confrontare tutti i 64 byte con quelli
   scritti, inclusi timestamp, origine e riservati.
6. Sincronizzare la directory parent. Ricontrollare apertura delle capacità
   e frontiere del file entrambe a 64, prima di restituire il risultato.
7. Il writer esegue la decisione EDIT e il completamento previsti da ADR-0040.
   Solo dopo questa decisione ammette traffico sul nuovo ACTIVE.

Il controller usa il log restituito, root iniziale `nil` e `next-offset = 64`.
Con la sua lease, `crea-sorgente-get-preparata` confronta il log effettivo e il
registro CSN dell'Archivio con quello degli snapshot nella vista GET; richiede
il file ancora fermo al solo header. La factory ACTIVE esistente riceve sempre
la prova di identità, senza syscall, mutex o letture di H.

Il caller costruisce **un solo controller per log** e impedisce altri writer,
close/dup2 concorrenti e modifiche esterne. Il risultato non è un token di
unicità del catalogo. Gli header non sono record WAL, non ricevono CSN e non
attestano il commit di un documento. La durabilità del file e della directory
non sostituisce la decisione di apertura dell'EDIT.

## Guasti e cleanup

Configurazione, range, alias, capienza e file già iniziato sono rifiutati
prima di fstat/write/flush. I buffer troppo piccoli non producono header
parziali. Con formati validi, fstat fallita o backend non verificabile precede
la preparazione dell'header.

Append e flush falliti applicano il normale stato `FAULTED` del
[confine I/O](io.md). Read/CRC/rilettura discordante o fsync della directory
falliti impediscono il ritorno del risultato. Le condizioni originali propagano:
nessun handler generico, retry degli errori, troncamento o rollback.

Il caller conserva la proprietà delle capacità su ogni uscita. Gestisce
quarantena e cleanup al proprio confine, senza ignorare l'errore o aprire il
segmento nel catalogo. Dopo progresso positivo, ripetere la preparazione sullo
stesso file viene rifiutato perché la posizione non è più zero; write/flush
guasti sono inoltre terminali. Un crash lascia un temporaneo da riconciliare
secondo [manifest e inventario](inventario.md), non autorizza a eliminarlo senza
la prova richiesta. Il modulo non elimina, rinomina o chiude file.

| Rifiuto locale | Condizione / reason |
|---|---|
| ID non rappresentabile dal percorso ACTIVE | `invalid-argument / :active-initialization-id` |
| buffer alias | `invalid-argument / :active-initialization-alias` |
| backend diversi | `invalid-argument / :active-initialization-backend` |
| append non vuoto o avanzato dopo preparazione | `invalid-argument / :active-initialization-started` |
| controller usa altro log | `invalid-argument / :active-initialization-log` |
| registro CSN diverso | `invalid-argument / :active-initialization-csn` |
| header riletto diverso | `corruption-detected / :active-initialization-readback` |
| ritorni/frontiere interni impossibili | `invariant-violation / :active-initialization-*` |

## Costi e decisioni da qualificare

Al massimo due fstat, due flush e un range write/read di 64 byte ciascuno.
Short I/O positivo usa al massimo 64 passi per range; gli errori non vengono
ritentati. Il confronto ha 64 iterazioni massime. Due buffer del caller,
almeno 128 byte totali, e pochi oggetti di apertura; il risultato non trattiene
buffer o liste di record. GET e commit dei documenti non aggiungono operazioni
per questa preparazione. Non sono misure di latenza o allocazione.

| ID | Decisione | Casi da verificare |
|---|---|---|
| AIN-D01 | header/scratch/identità non alias | ogni alias separato; buffer distinti |
| AIN-D02 | backend readonly = append = directory | ogni associazione diversa; nativo; backend identico |
| AIN-D03 | append scritto = 0 e durevole = 0 | ciascuna frontiera non zero; entrambe zero |
| AIN-D04 | post-I/O scritto = 64 e durevole = 64 | ciascuna frontiera diversa; entrambe esatte |
| AIN-D05 | uguaglianza dei 64 byte riletti | primo/centrale/ultimo byte, timestamp, CRC, origine, riservati |
| AIN-D06 | frontiere ancora a 64 all'adozione | append avanzato, frontiera durevole diversa, capacità invariata |
| AIN-D07 | log del controller identico al preparato | altro oggetto log con stessi numeri; log canonico |
| AIN-D08 | registro CSN della Serie identico a quello della vista | altro Archivio; registro canonico |

Qualifica C1, casi funzionali, fault injection in ciascun passo, stress concorrente
e misure dinamiche restano aperti. Le letture statiche dell'autore non sono
revisione indipendente e non promuovono i requisiti del motore.
[Catalogo locale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-active-init/catalogo.lisp).

Resta da collegare il preparatore all'esecutore di apertura/rotazione e alla
decisione EDIT del catalogo. I limiti prepared/OUTCOME del resolver ACTIVE
ordinario e la pubblicazione dell'indice concreto restano quelli documentati.

Il [checkpoint del control log](checkpoint-control.md) può ora usare questo
risultato per preparare header, EDIT completo e SEAL, verificando lo stesso
ACTIVE e mantenendo il control log fisicamente distinto. La decisione
autorevole del recovery resta la rinomina prevista da ADR-0040.
