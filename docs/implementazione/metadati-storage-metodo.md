# Metodo di verifica dei metadati storage

Ambito: header dei segmenti, payload e record EDIT/DECISION. Non include I/O,
applicazione al manifest, unicità degli ID, protocollo multiserie o durability.

## Correttezza

Gli oracoli costruiscono i byte con packing indipendente e CRC32C bitwise dei test
delle fondazioni. Si confrontano tutti i byte, inclusi campi a 64 bit con bit alto
impostato, versioni 1/2 e sentinelle prima/dopo l'output. Si controllano ogni punto
di troncamento, alterazioni dei byte, campi invalidi con CRC ricalcolato, conteggi
enormi in buffer piccoli, budget esatti e inferiori, esiti cumulativi, consumo
esatto e rifiuti dell'encoder senza modifiche parziali.

Comando: `make test lint`. Warning e style warning interrompono la compilazione.
La copertura strumentata è raccolta in un processo/cache separati dalla misura.
Le percentuali sono evidenza di esecuzione e non certificazione di correttezza.

## Prestazioni

Comandi: `sbcl --noinform --no-userinit --script tools/storage-bench.lisp --self-test`
e lo stesso con `--bench`. Il registro `tools/record-command.lisp` conserva
argomenti, ambiente, revisione, hash Git dei sorgenti, output grezzo ed esito.

Cinque campioni per campagna, un worker, safety 3, fixture preallocate, warmup
fino a 1.024 chiamate e GC completo prima di ogni campione. Si misurano tempo
monotono e byte heap tramite SBCL; un self-test prova anche l'allocazione
deliberata. Il risultato della chiamata alimenta un accumulatore osservabile.

Campagne: header 64 byte; EDIT con 2 o 1.024 chiusure e un esito per chiusura;
DECISION con 2 o 65.535 partecipanti. I verificatori di record includono CRC
sull'intero record. Gli encoder di payload includono preflight e copia, ma non
CRC della cornice. Gli ID nei payload rimangono opachi: non si misura il controllo
di duplicati o lo stato del catalogo. Gli u64 di stamp/CSN/segment-id sono alti.

Criteri: nessun warning, tutte le asserzioni superate, zero byte heap misurati
nei percorsi riusciti delle campagne. I tempi sono osservazioni locali, senza
soglia di throughput promessa. Il carico esterno non è controllato; queste
misure non sono prestazioni del database e non chiudono gli spike architetturali.

Il metodo è registrato prima della campagna prestazionale; i primi tentativi di
compilazione dei test lo precedono. Gli esiti falliti si conservano come tali.
