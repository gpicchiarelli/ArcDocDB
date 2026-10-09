# Tabella delle decisioni multiserie

Il modulo [`src/recovery/`](../../src/recovery/) ricostruisce in memoria
TXID → CSN e insieme dei partecipanti dal prefisso verificato di
`multiserie.log`, secondo [ADR-0041](../adr/0041-multiserie-segmenti-autosufficienti.md).
È il risultato del passo 2 del recovery, da usare poi per interpretare
i record prepared delle Serie.

## Contratto

`arcdocdb.recovery.decisions:ricostruisci-decisioni` riceve un buffer stabile,
`start`, `end`, versione esplicita e dimensione fisica autorevole. Restituisce
una tabella posseduta, il confine del prefisso nel **buffer** e `:complete`
o `:tail`. Gli argomenti `file-offset` e `file-size` hanno lo stesso contratto
della [scansione dei log](scansione-log.md): l'intervallo arriva all'EOF fisico
stabile; intestazione, versione e identità dell'Archivio sono verificate
dal chiamante. Il file-id del log multiserie è zero.

Prima si verifica l'intero log e si cerca un eventuale SEAL successivo che
testimoni corruzione. Poi si verificano i payload di tutte le DECISION nel
prefisso, i conteggi e i budget. Solo dopo questi controlli si costruisce
il risultato. Non viene restituita una tabella parziale in caso di errore.

| Query | Risultato |
|---|---|
| `numero-decisioni(tabella)` | numero di TXID distinti |
| `trova-decisione(tabella, txid)` | presenza esplicita, CSN, numero di partecipanti |
| `partecipante-decisione-p(tabella, txid, buffer, start, end)` | appartenenza dell'ID di Serie di 16 byte all'insieme |

Una decisione assente restituisce `nil, 0, 0`. Una decisione presente con
CSN zero restituisce `t, 0, count`: il chiamante usa la presenza, non il
valore del CSN. Un TXID assente può essere interpretato come presumed abort
solo dopo una costruzione riuscita della tabella. Un errore di scansione,
corruzione o budget non diventa un esito ABORT.
Il controller verifica anche che la Serie sia fra i partecipanti; la
semplice presenza del TXID non autorizza l'applicazione su qualsiasi Serie.

## Identità, duplicati e ownership

I partecipanti di una singola DECISION devono essere almeno due e distinti.
TXID e CSN restano interi u64 opachi, inclusi zero e il massimo; non si
aggiungono vincoli di monotonia o unicità del CSN fra transazioni diverse.
L'ordine delle DECISION e degli ID di Serie non cambia il risultato.

Una ripetizione dello stesso TXID con CSN e insieme dei partecipanti uguali
è idempotente. CSN o insiemi discordanti producono `corruption-detected`
con motivo `:decision-conflict`. Un partecipante ripetuto nella stessa
DECISION produce `:decision-duplicate-participant`. Questi errori semantici
in un lotto sigillato non sono trattati come una coda incompleta.

La lunghezza minima della cornice è verificata dallo scanner prima che un
lotto entri nel prefisso. Una cornice DECISION troppo corta segue quindi
la classificazione coda/testimone della [scansione](scansione-log.md), anche
se la fixture contiene CRC e un SEAL integri. I controlli semantici di
questa tabella si applicano soltanto al prefisso con cornici già verificate.

La tabella ordina i TXID e gli ID di Serie e possiede copie dei dati. Non
restituisce i vettori interni e non conserva span nel buffer sorgente.
Dopo la costruzione il chiamante può riusare il buffer senza cambiare
le query. La tabella non contiene stato globale o scritture condivise
fra Serie; le consultazioni sono in sola lettura.

## Budget e confini

> **Proposta** — Budget della tabella: 65.536 DECISION fisiche, 65.536
> partecipanti cumulativi, al massimo 65.535 partecipanti per decisione.
> I budget della scansione restano configurabili separatamente.

I conteggi cumulativi includono i record duplicati prima di coalescerli.
Un log vuoto è valido anche con budget zero; non si alloca memoria in
proporzione a un budget inutilizzato. Tutti i cicli sono limitati dai byte,
dai conteggi verificati o dalla profondità della ricerca binaria.
Questo è un percorso di apertura/recovery: copie e ordinamento possono
allocare, senza promessa di zero heap.

I nuovi errori di conteggio, partecipanti duplicati e decisioni discordanti
riportano offset assoluti nel file. Le condizioni dei codec mantengono
gli offset nel buffer previsti dal loro contratto. Le query verificano
range e lunghezza dell'ID anche per un TXID assente.

## Verifica e limiti

[Metodo](decisioni-multiserie-metodo.md) e
[tabella delle decisioni](decisioni-multiserie-decisioni.md).
Le fixture bytewise e i CRC bitwise sono indipendenti dai codec del
prodotto; l'oracolo interpreta storie logiche dichiarate come dati.
Le prove coprono duplicati coerenti/discordanti, troncamenti e corruzioni,
budget, valori estremi, identificativi quasi uguali e ownership.
La suite comprende 25 prove dedicate (44 insieme allo scanner), tra cui
identità su tutti i 128 bit degli ID16 e il limite valido di 65.535
partecipanti nelle versioni v1 e v2.

I cinque sorgenti `decisions-*` e i tre file di fixture, test e seconda
lettura sono componenti di `arcdocdb.asd`: `make test` e `make check`
compilano il modulo senza avvisi e ne eseguono le prove insieme a quelle
della scansione recovery. La campagna `decisions` di mutazione seleziona
le definizioni dei test dedicati, verifica che siano effettivamente avviati
e distingue un difetto rilevato da un errore precedente all'esecuzione.

```sh
make check
sbcl --noinform --no-userinit --no-sysinit --script tools/foundation-mutation.lisp --self-test
sbcl --noinform --no-userinit --no-sysinit --script tools/foundation-mutation.lisp --run spikes/out/decisions-mutants/ decisions
sbcl --noinform --no-userinit --no-sysinit --script tools/foundation-coverage.lisp --self-test spikes/out/decisions-coverage-self-test/
sbcl --noinform --no-userinit --no-sysinit --script tools/foundation-coverage.lisp --report spikes/out/decisions-coverage/ recovery
```

La directory dei mutanti deve essere nuova. La copertura `recovery`
comprende scanner e tabella; il rapporto separa i file e conserva il
denominatore grezzo. Non equivale a copertura MC/DC o a qualifica del motore.

Le [evidenze conservate](../../spikes/results/2026-10-09-decisions-verifica/catalogo.lisp)
comprendono comandi, ambiente, hash dei sorgenti prima/dopo, output grezzi,
due letture del prodotto, sette mutanti rilevati e nove mutanti di regressione
dello scanner. Restano conservati anche i fallimenti della fixture iniziale
e le verifiche precedenti alla correzione del classificatore dei mutanti.

Le [evidenze del 2026-10-09](../../spikes/results/2026-10-09-decisions-verifica/catalogo.lisp)
conservano self-test, comandi, ambiente, hash prima/dopo, output delle
mutazioni e stato grezzo di `sb-cover`. La campagna rileva sette mutanti
su sette dopo l'avvio dei test dedicati, senza errori di compilazione o
fallimenti precedenti ai test. Per i soli cinque file `decisions-*`, la
copertura grezza osservata è 935 forme su 1.121 e 82 rami su 122.
Definizioni e guardie difensive restano nei totali; nessuna eccezione alla
copertura viene approvata o sottratta in questa integrazione.

Requisiti: REQ-TXM-001/005, REQ-FOR-003, REQ-AFF-008/009/017, REQ-VAL-001.
Invarianti interessati: INV-F1/F2/F3, INV-A7/A8/A9, INV-T4, INV-P6, INV-X3.
Il modulo non verifica il catalogo, non applica i prepared, non scrive
esiti nel manifest e non compatta `multiserie.log`. Non realizza il
coordinatore 2PC né l'apertura completa del database; nessun gate del
motore è chiuso sulla sola evidenza di questa tabella.


La copertura grezza dei soli cinque sorgenti della tabella misura
**935/1121 espressioni (83,41%) e 82/122 rami (67,21%)**. Le guardie
interne e le forme dichiarative restano incluse; l'
[inventario delle forme mancanti](../affidabilita/copertura-eccezioni.md)
riporta motivazioni e limiti senza escluderle o approvare eccezioni.
