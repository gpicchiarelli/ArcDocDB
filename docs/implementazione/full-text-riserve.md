# Riserve full text del writer

`arcdocdb.fulltext.admission` realizza la prenotazione locale prevista da
[ADR-0054](../adr/0054-contratto-e-formato-full-text.md), prima dell'append e
di SEAL/PREPARE. Riceve i [task documentali](full-text-documenti.md) DONE,
prenota insieme capacita e costi di tutti gli indici e copia i run in buffer
posseduti dal writer. Il caso di riferimento resta NNTP Usenet in Common Lisp,
con indici su subject/body e interfaccia locale via [socket Unix](../adr/0055-interfaccia-locale-unix-socket.md).

Il [ponte PUT/WAL](full-text-put.md) puo ora possedere la cornice del record,
analizzare quegli esatti byte e accodarli dopo la riserva. Le primitive di questa pagina,
usate da sole, non attestano questo legame. Il gate completo richiede ancora
validazione generale di Serie, integrazione della pubblicazione durevole, esito autorevole dei prepared, pubblicazione
con documento/H/ACK, MVCC e il ritiro dopo quiescenza. Le funzioni non eseguono I/O,
non assegnano CSN o ID del catalogo e non rendono un indice READY per le query.

## Pool e proprietario

`crea-riserve-full-text(queue, configs, segment)` costruisce il pool per un ACTIVE
nuovo vuoto. `queue` e la coda canonica del writer della Serie; ogni operazione calda
richiede la lease corrente della coda e il suo thread proprietario. Il caller mantiene
un solo pool autorevole per quel segmento/insieme di generazioni: la factory non
dimostra canonicalita di coda, catalogo o file e non ammette un ACTIVE gia popolato.
Il passaggio di ownership worker→writer deve essere sincronizzato dal chiamante.

`configs` e un simple-vector di 1…16 configurazioni canoniche immutabili,
ordinate strettamente per `(index-id, generation-id)`, al massimo otto indici e
due generazioni per indice. Il vettore viene copiato. Le configurazioni sono condivise
in sola lettura; i task devono riferirsi agli stessi oggetti adottati, non a dichiarazioni
ricostruite dai soli ID. Una configurazione superata produce `:fulltext-contract-changed`.
L'adozione effettiva del catalogo e il drenaggio dei vecchi contratti restano esterni.

Default: otto slot, 4096 token e 262144 byte di termini per run/generazione,
256 MiB di memoria preallocata, 256 MiB di delta, 64 MiB di staging, 16 GiB per file.
Le capacita sono finite e configurabili; possono rifiutare documenti che entrano nello
scratch analitico. Non si promette di raggiungere insieme tutti i massimi.

Prima delle allocazioni viene verificato il costo conservativo degli array e degli
oggetti: `4096 + 128*N + slot*(1032 + N*(4096 + 20*token + term-bytes + 12*16))`.
Gli 8 byte aggiuntivi per slot coprono la [directory locale delle righe](full-text-righe.md).
Questo budget fisico e distinto dai byte logici usati; configurazioni, scratch del
worker, input originale, RSS e pool preesistenti sono esterni. Il coordinatore dovra
contare insieme anche pool congelati, nuove generazioni e viste trattenute della Serie;
creare un altro pool non autorizza ad azzerare i costi del precedente.

## Prenotazione e copia

`prenota-full-text(pool, lease, sources)` riceve un simple-vector con un task DONE
per configurazione. Controlla tutti i task, stessa row u32, configurazioni e capacita
fisiche dei run; nessuna row gia trattenuta puo essere ammessa due volte.
La row e ancora un ordinale proposto: non e una prova di appartenenza al PUT/hint.
Il chiamante garantisce che tutti i task rappresentino il medesimo documento immutabile.

Il payload cumulativo e `somma(20*token + byte-termini + 12*campi-presenti)`.
Il file di ogni generazione conta il costo fisso una volta piu tutti gli `U(documento)`
[gia definiti](../formato-indice-full-text.md#limite-superiore-e-rotazione). Nessuna
riduzione per versioni storiche, PUT prepared o assenze da uno snapshot.
Una richiesta maggiore del file vuoto produce `:fulltext-reservation-request-too-large`;
una somma che richiede rotazione produce `:fulltext-reservation-rotation` prima dell'append.
Non viene eseguita la rotazione e non si ignorano gli intenti pendenti.

Ogni rifiuto ordinario precede gli effetti: anche se fallisce l'ultima configurazione,
non cambiano slot, generation, costi o prestiti. A successo si restituiscono uno slot
stabile e una generation fixnum positiva senza wrap, da catturare nel messaggio.
Il vettore del caller non viene trattenuto. I task restano DONE ma il loro riavvio
pubblico rifiuta con `:fulltext-document-borrowed` finche la copia ne possiede il run.

`passo-riserva-full-text(pool, lease, slot, generation, quantum)` copia al massimo
`quantum` byte/parole o transizioni, con quantum 1…65536. Nessuna analisi, ordinamento
o attesa nel writer. Si puo rilasciare la lease e continuare con quella nuova; il token
dello slot rimane catturato. I singoli task sono liberati a copia conclusa; READY del
bundle richiede tutti i run. Il quantum e un limite logico, non una deadline realtime.

`leggi-run-riserva-full-text(..., indice-zero-based)` restituisce un prestito dei run
solo READY/TRANSFERRED e sotto lease del writer. Il worker puo ormai riusare il proprio
scratch senza cambiare le copie. Non e una vista di query MVCC o un riferimento protetto
da EBR; non va consegnato ai client. `leggi-budget-riserve-full-text` espone delta,
staging e slot occupati, `leggi-bound-riserve-full-text` il costo fisso piu gli U trattenuti.

## Cancellazione, trasferimento ed errori

`annulla-riserva-full-text` si usa solo prima di append/SEAL/PREPARE e trasferimento,
senza prestiti esterni del run. Rilascia costi e fonti anche a copia parziale; e
idempotente fino al riuso dello slot. Il token vecchio viene rifiutato dopo il riuso.
Non costituisce abort di una transazione gia preparata o decisa.

`trasferisci-riserva-full-text` richiede READY e precede l'append: il writer accetta
l'ownership permanente dei buffer. Restituisce staging, conserva delta/file/slot e
rende impossibile la cancellazione con questa API. Non attesta un commit e non modifica
H/ACK. I trasferiti rimangono conservati: un futuro ingresso di risoluzione/ritiro dovra
verificare esito autorevole e quiescenza prima di liberarli. Saturazione significa
backpressure prima di un nuovo append, non eliminazione o riuso per assenza.

Un'invariante o un'uscita incompleta durante una mutazione porta il pool a FAULTED e
conserva riferimenti e costi per la diagnosi. Nessun rollback di effetti incerti o ACK.
Il confine worker deve rendere FAULTED la Serie e avviare il recovery: questo componente
non possiede il controller di durability. Un errore di lease/token ordinario precede
gli effetti e non guasta un pool sano. Tra Serie non ci sono lock, attese o scritture condivise.

Il [metodo e la tabella delle decisioni](full-text-riserve-metodo.md) distinguono prove
locali, due letture dello stesso autore e qualifica C1 completa ancora aperta.
I requisiti complessivi restano `:progettato`.

Le [prove conservate](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-17-fulltext-reservation-dev-targeted/README.md)
riportano comandi, sorgenti effettivi, risultati e limiti delle verifiche.
