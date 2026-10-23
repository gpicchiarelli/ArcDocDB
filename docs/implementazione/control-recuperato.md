# Lettura del control log e transizione di recovery

Il percorso collega il [manifest](manifest-control-log.md) alla
[pubblicazione del checkpoint](pubblicazione-control.md), secondo
[ADR-0040](../adr/0040-manifest-a-record-unico.md#3-riconciliazione-al-riavvio).
Il vecchio file viene letto dalla stessa capacità readonly poi consegnata
alla rinomina. Il nuovo checkpoint conserva lo stato precedente e chiude
il vecchio ACTIVE prima di aprirne uno nuovo.

## API

| API | Contratto |
|---|---|
| `leggi-control-recuperato(view, input, size, scratch, …)` | lettura fino all'EOF attestato, header verificato e replay del prefisso; risultato posseduto senza buffer |
| `frontiere-control-recuperato(result)` | EOF attestato, fine assoluta del prefisso, `:complete`/`:tail`, versione 1/2 |
| `manifest-control-recuperato(result)` | manifest immutabile consultabile con le query scalari esistenti |
| `verifica-transizione-recovery(previous, current)` | verifica pura della chiusura conservativa di ACTIVE; nessun I/O |
| `pubblica-control-validato(prepared, recovered)` | verifica vista canonica e transizione, poi delega al publisher con il vecchio file esatto |

`control-recuperato` ha un costruttore privato e nessun copier. Conserva
vista canonica, capacità readonly, manifest posseduto e quattro scalari.
Non conserva scratch, byte del log o un secondo FD. Il manifest non contiene
alias ai byte letti; lo scratch può essere riutilizzato dopo il ritorno.

## Autorità e stabilità

Il controller mantiene il recovery **esclusivo della Serie**, nel pool I/O.
Dal catalogo provengono la vista canonica e l'autorità del vecchio
`control.log`. Il chiamante attesta `size` come EOF fisico stabile: questa
API non misura la dimensione del file. Un limite scelto dal chiamante o la
lunghezza di un buffer non possono sostituire quell'attestazione.

File, FD e namespace rimangono congelati dalla lettura fino alla conclusione
della pubblicazione. Readonly descrive la capacità; non impedisce una scrittura
esterna sullo stesso inode. Il risultato non è un certificato contro modifiche
esterne, né un permesso autonomo a sostituire il catalogo o avviare il traffico.
La rinomina esistente controlla ancora entrambe le foglie contro le capacità.

La pubblicazione richiede **la stessa vista per identità di oggetto**, oltre
all'identità di Serie verificata nell'header. Una vista diversa con UUID uguale
è rifiutata: indice e ambito dell'Archivio non vengono ricollegati implicitamente.

## Lettura e budget

1. Verificare input aperto, scratch distinto dall'identità della vista,
   dimensione e budget, prima di leggere o modificare lo scratch.
2. Leggere esattamente `size` byte dallo stesso FD in trasferimenti limitati.
3. Verificare magic, CRC, riservati, identità della Serie e versione dell'header.
4. Passare **tutto il file fino a EOF** allo scanner e al replay esistenti.
   Una coda è ammessa soltanto dopo la ricerca completa dei testimoni durevoli.
5. Verificare frontiere e capacità ancora aperta, poi consegnare il risultato.

Lo scratch contiene tutto il file e deve avere almeno `size` byte. Il default
è un budget di apertura di **64 MiB**, modificabile con `:max-bytes`; non è
un nuovo limite persistente del database. `:chunk-bytes` vale 64 KiB; il
massimo trasferimento dell'input deve permettere `min(size, chunk-bytes)`.
Il numero di iterazioni è `ceiling(size/chunk-bytes)`; gli short read hanno
il limite finito già definito nel modulo I/O.

`:max-batches`, `:max-batch-records`, `:max-edits`, `:max-segmenti` e
`:max-esiti` valgono inizialmente 65.536. Segmenti/esiti limitano sia le
occorrenze cumulative sia quelle per EDIT, comprese eventuali ripetizioni.
Il budget byte limita anche il lotto e la ricerca di testimoni. Restano
invariati i limiti del codec dei payload. Un budget esaurito è un errore;
non viene convertito in una coda utilizzabile.

Header mancante/invalido, EOF incompleto, corruzione durevole, EDIT non
applicabile o budget esaurito non producono un risultato parziale. Le
condizioni originali propagano al controller per quarantena/fail-stop.
La lettura non apre, chiude, scrive, sincronizza o tronca il file.

## Transizione conservativa

Il confronto è dedicato alla chiusura dopo un crash, prima di CLEAN, MERGE
o reclaim. Richiede:

- nuovo ACTIVE con ID almeno pari al vecchio high-water; spazio ID esaurito
  produce `resource-exhausted`;
- vecchio ACTIVE presente come CLOSED nel nuovo manifest;
- tutti i precedenti CLOSED con identici ID, lunghezza valida ed esiti;
- tutti i precedenti REMOVED conservati, anche se i relativi file sono già assenti;
- esattamente un CLOSED aggiunto e nessun REMOVED aggiunto o omesso.

La presenza di un esito è verificata separatamente dal CSN: zero non significa
assenza. I confronti usano gli interi u64 completi. Cardinalità e inclusione
insieme escludono l'aggiunta o sostituzione silenziosa di altri segmenti.
I rimossi possono essere omessi da una successiva compattazione autorevole
del control log; questo ingresso conserva deliberatamente tutti quelli letti.
Il confronto non è un guard generico per la rotazione online o la compaction.

**Restano precondizioni** la validazione dell'inventario, la scansione del
vecchio ACTIVE e la correttezza della lunghezza/esiti usati per chiuderlo.
Il confronto dei due manifest non può provare i byte di un segmento che non
ha letto. Non risolve transazioni multiserie o autorizza eliminazioni.

Il [lettore del vecchio ACTIVE](active-recuperato.md) collega ora quella
precondizione allo scanner readonly e alla tabella delle decisioni. Il suo
ingresso di pubblicazione richiede P ed esiti derivati esattamente uguali
nella chiusura, prima di delegare alla transizione conservativa qui descritta.

## Pubblicazione ed errori

`pubblica-control-validato` rifiuta vista diversa, capacità chiusa e transizione
invalida prima di reclamare il gettone o effettuare I/O. Delega quindi a
`pubblica-control-recuperato`: stesso CAS, stesso punto di atomicità nella
rinomina, stesso fsync della directory prima della conferma, stessi errori
terminali dopo la presa. Nessuna seconda macchina a stati o logica di retry.

L'ingresso esistente resta disponibile per i chiamanti che attestano
direttamente l'autorità e la validazione del vecchio log. La creazione iniziale
della Serie, l'adozione degli indici e il gate del Recovery Manager restano
da integrare.

## Decisioni e costi

| ID | Decisione | Casi da qualificare |
|---|---|---|
| CRV-D01 | chunk positivo, EOF e budget almeno un header | ciascuna falsa, tutte vere, EOF esatto |
| CRV-D02 | prefisso entro range e COMPLETE equivalente a EOF | frontiere errate, COMPLETE/TAIL coerenti e incoerenti |
| CRV-D03 | CLOSED conserva stato, lunghezza e numero esiti | ogni condizione falsa separatamente, tutte vere |
| CRV-D04 | esito presente e CSN identico | assente, CSN diverso, zero presente, u64 con parte alta |
| CRV-D05 | cardinalità CLOSED precedente più uno e REMOVED invariata | ciascuna falsa, entrambe vere, sostituzione con stesso conteggio |
| CRV-D06 | nuovo ACTIVE oltre high-water e vecchio ACTIVE chiuso | riuso, spazio esaurito, vecchio ACTIVE omesso/rimosso, transizione valida |
| CRV-D07 | stessa vista canonica e vecchio input ancora aperto | altra vista con UUID uguale/diverso, CLOSED/FAULTED, valida |

Lettura sequenziale O(byte), oltre al costo dello scanner/replay esistente.
Il confronto visita O(CLOSED + REMOVED + esiti) con lookup medi O(1); non
espone hash table. Nessun lock tra Serie, clock, attesa o contatore condiviso.
Sono percorsi di apertura con allocazioni: scratch del caller, workspace e
manifest del decoder, wrapper del risultato. Non ci sono nuove copie complete
del file o delle tabelle nel bridge di pubblicazione.

Costi statici, non benchmark. Compilazione, lint, tracciabilità, collegamenti
e conservazione delle prove vengono registrati nella
[campagna](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-control-recovery/README.md).
La successiva [campagna di modulo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-control-transizione/report.md)
conserva 84 nuovi test passati, revisione indipendente, copertura dei quattro
file e 216 finestre di misura. I limiti e le forme non raggiunte rimangono
espliciti; questi esiti non chiudono il gate C1 o la Fase 0. Il
[metodo delle misure](control-transizione-metodo.md) distingue il confronto
puro dalla decodifica e dalla pubblicazione su disco. Esiti e limiti vengono
conservati insieme ai produttori; la qualifica del Recovery Manager completo
resta aperta.
