# Pubblicazione del checkpoint del control log

`pubblica-control-recuperato` completa la preparazione del
[checkpoint](checkpoint-control.md) tramite la rinomina prevista da
[ADR-0040](../adr/0040-manifest-a-record-unico.md#3-riconciliazione-al-riavvio).
Il punto di atomicità è la sostituzione di `control.log` con il temporaneo
durevole; il risultato è consegnato soltanto dopo fsync della directory.

## Contratto e dipendenze

| API | Risultato |
|---|---|
| `pubblica-control-recuperato(prepared, previous)` | risultato completo dopo rinomina verificata e fsync parent |
| `stato-pubblicazione-control(prepared)` | stato e successo della rinomina osservato al confine del publisher |
| `log-control-pubblicato(result)` | log canonico del nuovo control log |
| `manifest-control-pubblicato(result)` | manifest posseduto del checkpoint installato |
| `active-control-pubblicato(result)` | nuovo ACTIVE preparato, nominato dal manifest |

Il chiamante esegue **recovery esclusivo della Serie** nel pool I/O. Ha già
verificato il vecchio control log, il suo manifest, l'inventario necessario e
le decisioni delle transazioni. `previous` è la capacità readonly di quel
file autorevole, mantenuta aperta fino alla fine del compito. Il publisher
non deduce questa autorità dalla sola esistenza di un nome o di un FD.

Il risultato preparato conserva ora **directory canonica e lunghezza attesa**.
Il nuovo control log deve essere ancora fermo alla frontiera preparata,
scritta e durevole, con log sano e associazione readonly/append valida.
Il nuovo ACTIVE deve essere ancora al solo header durevole. La directory
deve essere esattamente quella sincronizzata durante la preparazione.

Il namespace è posseduto dal controller per l'intera chiamata: nessuna
rinomina, mutazione esterna, chiusura o sostituzione di FD concorrente.
I controlli di inode non sono un lock contro altri processi: tra verifica
e `renameat` questa esclusività rimane una precondizione del motore.

## Ordine degli effetti

1. Preflight senza I/O: gettone libero, capacità aperte, log e frontiere
   invariati, dipendenza ACTIVE, backend e callback richiesti.
2. Allocare il wrapper di risultato **prima** della rinomina e reclamare
   il gettone locale con CAS sul suo identificativo univoco.
3. Nella directory già aperta, confrontare device/inode delle capacità con
   quelli delle foglie `control.log.tmp` e `control.log`. Entrambe devono
   essere file regolari, senza seguire symlink, e fisicamente distinte.
4. Eseguire **una sola `renameat`**, usando lo stesso FD di directory per
   sorgente e destinazione. Nessun pathname di antenati viene risolto di nuovo.
5. Verificare che `control.log` individui il file nuovo, confrontandolo con
   la capacità readonly preparata. I FD vecchi restano aperti e del caller.
6. Registrare il successo osservato al confine I/O e sincronizzare la directory.
7. Ricontrollare capacità, frontiera del checkpoint e nuovo ACTIVE. Segnare
   `:published` e consegnare il wrapper completo.

Il publisher non riscrive il file, prende CSN, chiude FD, elimina segmenti,
pubblica indici o ammette traffico. Il risultato collega manifest, log e
ACTIVE preparato; il controller deve ancora completare il gate del recovery.

## Gettone, rientri ed errori

Il gettone è locale al risultato preparato; non introduce lock tra Serie.
Il cleanup è installato **prima del CAS**. Identifica il proprietario tramite
il wrapper privato, anche se un'uscita non locale avviene immediatamente dopo
il CAS e prima dell'aggiornamento dello stato. Un tentativo perdente non può
invalidare il gettone del vincitore. Il risultato non è riutilizzabile.

| Stato | Significato |
|---|---|
| `:prepared` | preflight e presa possibili, purché il gettone sia ancora libero |
| `:publishing` | un solo proprietario può eseguire verifica/rinomina/fsync |
| `:published` | rinomina verificata, directory sincronizzata e postcondizioni concluse |
| `:faulted` | uscita incompleta dopo la presa; richiede nuova riconciliazione autorevole |

Le osservazioni dello stato sono per il proprietario o il controller dopo
consegna/join: non sono una fotografia concorrente dei campi o un permesso a
chiudere/eliminare/ritentare. Il booleano `rename-observed = nil` **non prova
che i nomi siano invariati**: un errore può avvenire durante la syscall o nella
verifica successiva. Se è vero e il fsync fallisce, la rinomina è stata
osservata ma la pubblicazione non è confermata durevole.

Qualsiasi errore dopo la presa, compreso un rientro non gestito dal callback,
un guasto di verifica o un'uscita non locale, lascia `:faulted`. La condizione
originale propaga; nessun handler generico, retry, rollback, close o cleanup
del namespace è eseguito. Il controller applica fail-stop della Serie e
ricostruisce la decisione dal disco. Prima della presa, un rifiuto della
preflight lascia il risultato preparato.

## Confine I/O e piattaforme

`verifica-capacita-sostituzione` controlla capacità, nomi foglia ASCII,
relazione `.tmp`/definitivo e backend prima delle syscall.
`sostituisci-temporaneo` confronta i nomi con i FD, rifiuta un alias fisico,
esegue la rinomina e verifica il nome installato. Il caller fornisce lo stato
completo durevole e il target autorevole: la primitiva I/O non interpreta EDIT.

Il backend mantiene i sei argomenti posizionali e `:identity` già esistenti;
aggiunge due callback opzionali:

- `:entry-identity(directory-fd, leaf)` → device/inode di un regolare,
  senza seguire symlink;
- `:rename(directory-fd, source-leaf, target-leaf)` → zero per successo.

Un backend incompleto è rifiutato prima della presa: nessun fallback nativo.
I callback sono fidati e non mutano nomi, FD o capacità fuori dal contratto.
Le foglie vengono copiate in stringhe private prima delle osservazioni I/O.
La rinomina e le sue postcondizioni delegano al
[confine comune](io-rinomina.md), con copie simple-base-string e limite di
255 byte per foglia. Il cleanup locale protetto conserva una capacità già
chiusa e guasta una capacità aperta anche su uscita incompleta o guasto della
verifica dopo la rinomina.

Nel percorso nativo, `fstatat` usa lo `struct stat` grovelled di SB-POSIX,
con lo stesso selettore `INODE64` delle sue funzioni stat: nessun offset di
struct è duplicato nel prodotto. Il flag `AT_SYMLINK_NOFOLLOW` è 0x100
nell'[header Linux](https://raw.githubusercontent.com/torvalds/linux/master/include/uapi/linux/fcntl.h)
e 0x20 in `sys/fcntl.h` del SDK macOS. ABI e piattaforme restano quelle del
[confine I/O](io.md); la qualifica dinamica di queste nuove chiamate è aperta.

## Costi e decisioni da qualificare

Al massimo sei osservazioni d'identità: due fstat e due fstatat prima della
rinomina, una fstat e una fstatat dopo. Seguono una renameat e un fsync del
parent. Nessun nuovo FD è aperto. Sono creati un wrapper e due stringhe private;
le osservazioni native usano inoltre istanze `stat` del runtime e possono
richiedere boxing degli interi POSIX. Nessun buffer dati o lotto nuovo. Sono costi statici,
non misure di latenza, heap, throughput o contesa.

| ID | Decisione | Casi da qualificare |
|---|---|---|
| CPU-D01 | stato preparato e gettone libero | ogni condizione falsa, entrambe vere, due contendenti |
| CPU-D02 | frontiere scritta/durevole uguali alla preparata | ciascuna frontiera diversa, entrambe esatte |
| CPU-D03 | nomi foglia ammessi | vuoto, dot/dotdot, ogni separatore, NUL/non ASCII, valido |
| CPU-D04 | relazione temporaneo/definitivo | lunghezza, prefisso e suffisso separatamente errati |
| CPU-D05 | directory/source/target nello stesso backend | ogni associazione diversa, tutte uguali |
| CPU-D06 | tre callback presenti | ogni callback mancante, tutte presenti, nativo |
| CPU-D07 | device/inode dei nomi uguali ai FD | ciascuna componente diversa, entrambe uguali, symlink/non regolare |
| CPU-D08 | sorgente e target distinti | stesso device/altro inode, altro device/stesso inode, entrambi uguali |
| CPU-D09 | proprietà del cleanup e uscita incompleta | CAS vinto/perso, uscita subito dopo CAS, successo/errore |
| CPU-D10 | entry identity di tipo ammesso | ciascun componente invalido, entrambi validi |

Qualifica C1, casi funzionali, fault injection in ogni passo e misure restano
aperti. Le letture statiche dell'autore non sono revisione indipendente.
Questo percorso sostituisce un vecchio control log già autorevole; creazione
iniziale della Serie, pubblicazione senza target, rotazione online e recovery
completo restano da integrare.

Il [completamento I/O](io-completamento.md) impedisce il riuso delle capacità append/flush dopo uscite incomplete, mantenendo CLOSED terminale. Le sonde funzionali del percorso completo e il benchmark preregistrato sono descritti nel [metodo](control-verifica-metodo.md); gli esiti vengono conservati separatamente dal metodo.
