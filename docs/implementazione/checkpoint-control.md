# Preparazione del checkpoint del control log

`arcdocdb.control` costruisce e prepara un nuovo `control.log.tmp` contenente
un header, un EDIT completo e un SEAL. Realizza la preparazione del file di
[ADR-0040](../adr/0040-manifest-a-record-unico.md#3-riconciliazione-al-riavvio),
con l'header di [ADR-0052](../adr/0052-header-dei-log-di-controllo.md).
Il **punto di atomicità del recovery** resta la successiva rinomina sopra il
control log autorevole. Il preparatore non rinomina; il
[publisher del recovery](pubblicazione-control.md) esegue questo passaggio
su un vecchio control log già verificato e autorevole.

## API e proprietà

| API | Contratto |
|---|---|
| `crea-checkpoint-control(active, payload, stamp, :limiti…)` | costruisce in memoria il file privato e ne ricostruisce il manifest |
| `lunghezza-checkpoint-control(plan)` | dimensione esatta del file, per configurare capacità e scratch |
| `manifest-checkpoint-control(plan)` | manifest posseduto, consultabile tramite le query scalari esistenti |
| `prepara-checkpoint-control(plan, input, append, directory, scratch, :chunk-bytes)` | scrittura, flush, rilettura completa, confronto e fsync del parent |
| `log-control-preparato(prepared)` | log canonico `:control`, file-id zero, per il suo unico proprietario |
| `manifest-control-preparato(prepared)` | manifest del checkpoint preparato e riletto uguale |
| `io:verifica-file-distinti(left, right)` | due capacità readonly del medesimo backend, device/inode fisicamente diversi |

Il nuovo ACTIVE deve essere il risultato di
[`prepara-segmento-attivo`](inizializzazione-active.md), ancora fermo al solo
header: capacità aperte, log sano e frontiere scritta/durevole entrambe 64.
Il controllo viene ripetuto prima e dopo la costruzione e la preparazione.
Il controller impedisce scritture e close concorrenti durante l'intero ciclo.

Il payload è uno stato completo, codificato con `scrivi-valore-edit` dalla
fonte autorevole: prossimo ID, nuovo ACTIVE, CLOSED con lunghezze/esiti e
rimossi ancora da riconciliare. Il modulo lo copia nel piano privato;
il chiamante può riusarlo dopo la costruzione. Non espone il buffer del piano.
Identità della Serie e versione vengono dal nuovo ACTIVE già verificato;
lo stamp u64 è il numero d'ordine fornito dal controller, **non un CSN**.

## Costruzione senza I/O

1. Verificare salute, associazione e frontiere del nuovo ACTIVE, senza syscall.
2. Verificare il budget del payload e la capienza del record nella versione v1/v2.
3. Costruire un lotto CONTROL privato di un solo EDIT completo, TXID zero,
   sigillato tramite il builder WAL esistente: file-id zero, inizio a 64 e
   frontiera durevole **storica zero**, dato che il nuovo file non è ancora scritto.
4. Aggiungere l'header canonico della Serie e copiare il lotto nel file privato.
5. Verificare header, cornici, CRC, SEAL e payload usando il recovery esistente.
   Richiedere un manifest completo che consumi l'intero file e nomini lo stesso
   nuovo ACTIVE. Budget, disgiunzione degli insiemi, lunghezze, esiti e next-id
   sono controllati dal ripiegamento del manifest.
6. Ricontrollare il nuovo ACTIVE e restituire il piano completo.

La costruzione può allocare; non appartiene al percorso caldo dei documenti.
Non crea file, legge orologi, prenota ID, prende CSN o pubblica indici.
Lo scanner in memoria non attesta la presenza dei CLOSED: inventario, verifica
dei relativi dati e correttezza dell'allocatore restano obblighi del controller.

Il [builder del recovery](checkpoint-recovery.md) ricava il payload completo
da CONTROL e ACTIVE recuperati, conservando CLOSED, REMOVED ed esiti e
verificando la transizione prima di restituire questo stesso piano.

## Preparazione nel pool I/O

Il controller crea il nuovo `control.log.tmp` con **O_EXCL**, apre readonly e
directory parent autorevole e riserva il namespace. Il parent effettivo è una
precondizione del controller; il modulo non lo deduce dagli inode dei file.
Readonly, append, directory e nuovo ACTIVE usano lo stesso backend, incluso
`nil` sul percorso nativo. I callback sono fidati e rispettano ownership e buffer.

La preflight controlla alias, scratch, budget di trasferimento, budget totale
del file, backend e frontiere append a zero, prima di fstat o modifiche.
L'associazione readonly/append prova che le due capacità del control log
individuano lo stesso file. Un secondo controllo prova che quel file sia
**distinto dal nuovo ACTIVE**, prima di qualsiasi scrittura.

Il compito scrive il piano per blocchi, sincronizza il file, lo rilegge per
blocchi e confronta **ogni byte**, inclusi header, payload, stamp e SEAL.
Il primo disaccordo segnala corruzione con offset assoluto. Poi sincronizza
la directory e verifica capacità, dipendenza ACTIVE e frontiere esatte.
Restituisce il risultato soltanto a completamento di tutti i passi.

Il risultato conserva log, manifest, dipendenza ACTIVE e associazione fisica;
conserva anche directory canonica e frontiera preparata. Non conserva il piano
serializzato o lo scratch. Il controller conserva tutte
le capacità e completa la rinomina/adozione secondo ADR-0040. Il file completo
e durevole non è ancora il control log autorevole e non conferma un documento.

## Errori e risorse

Gli errori tipizzati dei codec, recovery e I/O propagano senza handler generico,
retry degli errori, rollback, troncamento, close o eliminazione implicita.
Il caller mantiene la proprietà delle risorse e gestisce quarantena/cleanup.
Nessun risultato parziale è consegnato. Dopo progresso, una nuova preparazione
sullo stesso append viene rifiutata; write/flush guasti applicano `FAULTED`.
Il temporaneo va riconciliato rispetto alla fonte autorevole prima di eliminarlo.

| Rifiuto locale | Reason |
|---|---|
| ACTIVE avanzato oltre l'header | `:control-active-advanced` |
| log ACTIVE non sano | `:control-active-log` |
| budget/payload non ammessi | `:control-checkpoint-budget` / `:control-checkpoint-payload` |
| manifest riferisce un altro ACTIVE | `:control-checkpoint-active` |
| chunk nullo / scratch alias / backend diverso | `:control-checkpoint-chunk` / `:control-checkpoint-alias` / `:control-checkpoint-backend` |
| append già iniziato | `:control-checkpoint-started` |
| control log e ACTIVE sono lo stesso file | `:io-file-alias` |
| rilettura diversa | `:control-checkpoint-readback` |
| ritorni/frontiere interne impossibili | `:control-checkpoint-*`, condizione `invariant-violation` |

## Costi e decisioni da qualificare

Con payload P, il file occupa **P + 144 byte**: 64 di header, 24 di cornice EDIT
e 56 di SEAL. P è al massimo 16 MiB, con il limite del record v1 verificato
separatamente. I budget del manifest sono quelli esistenti: 65.536 menzioni
di segmenti ed esiti cumulativi per default, configurabili tramite l'API.

Chunk predefinito 64 KiB; qualsiasi chunk positivo è limitato dai byte del
piano e dalle capacità I/O. Lo scratch richiede `min(file-size, chunk)` byte.
Ci sono `ceiling(file-size/chunk)` trasferimenti esatti in ciascuna direzione;
gli short I/O positivi hanno il limite delle primitive esistenti. Al massimo
quattro fstat e due flush. La rilettura non ricostruisce il manifest. Il piano
trattiene il file privato e il manifest; il lotto intermedio può essere
recuperato dal GC dopo la costruzione. Questi sono limiti statici, non misure
di latenza, RSS, heap o throughput.

| ID | Decisione | Casi da qualificare |
|---|---|---|
| CPL-D01 | ACTIVE scritto/durevole a 64 | ciascuna frontiera diversa, entrambe esatte |
| CPL-D02 | budget min/max e payload rappresentabile | ogni limite, v1/v2, un byte oltre |
| CPL-D03 | header end/version corretti | ciascun valore discordante, entrambi corretti |
| CPL-D04 | prefisso completo fino a EOF | prefisso corto, tail, completo |
| CPL-D05 | manifest nomina il nuovo ACTIVE | altro ID, ID canonico |
| CPL-D06 | scratch senza i tre alias | ciascun alias separato, buffer distinto |
| CPL-D07 | i quattro backend sono identici | ciascuna associazione diversa, identici, nativo |
| CPL-D08 | append scritto/durevole zero | ciascuna frontiera diversa, entrambe zero |
| CPL-D09 | device/inode distinti | stesso device/altro inode, altro device/stesso inode, entrambi uguali |
| CPL-D10 | frontiere finali uguali alla dimensione | ciascuna frontiera diversa, entrambe esatte |
| CPL-D11 | size SEAL/lotto corretta | ciascun ritorno discordante, tutti corretti |
| CPL-D12 | uguaglianza byte in ogni chunk | primo/centrale/ultimo byte, confine chunk e ultimo blocco corto |

Qualifica C1, casi funzionali, fault injection, stress concorrente e misure
dinamiche sono aperti. Le letture statiche dell'autore non costituiscono
revisione indipendente. La [rinomina autorevole](pubblicazione-control.md)
è ora un passaggio distinto del modulo; l'esecutore recovery, la creazione
della Serie nel catalogo e la rotazione in esercizio restano da integrare.
