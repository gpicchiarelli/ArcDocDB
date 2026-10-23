# Riferimenti fisici dei PUT full text

Il [ponte PUT/WAL](full-text-put.md) conserva ora un riferimento fisico stabile per
ogni riserva trasferita. La [directory privata delle righe](full-text-righe.md)
lo risolve sotto lease; serve alla futura mappa pubblicata del delta e collega
i posting di un articolo NNTP al record della stessa versione, anche dopo che
il writer riutilizza il buffer WAL. Non costituisce ancora una vista pubblicata.

## Cattura prima dell'I/O

`cattura-riferimento-put-full-text(pool, lease, slot, generation, registry, log)`
richiede il token restituito dall'append, la lease della coda canonica e il lotto
sigillato con `wal:sigilla-lotto-con-csn`. Il lotto deve essere ancora SEALED e
non posseduto da un gruppo I/O; il token CSN deve essere pendente e associato
agli esatti oggetti registro/log. Un semplice `sigilla-lotto` con stamp del caller
non fornisce questa autorita e viene rifiutato.

La funzione verifica incarnazione, ordinale e intervallo del legame originale,
CRC del solo header (20 byte), formato, span, tipo PUT e flag. All'append il ponte
ha conservato flag e stamp del frame privato del worker; alla cattura verifica
che un prepared conservi lo stesso TXID, mentre un ordinario porti il CSN del lotto.
Non ricalcola il CRC del body e non rianalizza il documento sotto lease.

Il riferimento viene fissato nei campi gia preallocati della riserva; la quota
conservativa di 1024 byte per slot nel costruttore comprende questi metadati.
Nessuna allocazione, ricerca per chiave, I/O o consultazione di H e aggiunta.
Offset e lunghezza devono restare rappresentabili prima della mutazione.
La pressione dei budget continua a essere verificata prima dell'append; una
incoerenza interna dopo SEAL richiede fail-stop, senza convertire una decisione in abort.

Il risultato `:sealed` indica una cattura completa in memoria. Il SEAL non e ancora
necessariamente scritto o sincronizzato e il documento non e pubblicato. Il caller
deve catturare tutti i riferimenti necessari prima della consegna del lotto all'I/O.
Canonicalita di pool, catalogo, log fisico e posizione iniziale rimangono al runtime
e al Segment Manager, come nel ponte WAL. Non si verificano qui header di segmento,
inventari, contratti di Serie o un file esistente.

## Lettura dopo il riuso del buffer

`leggi-riferimento-put-full-text(pool, lease, slot, generation)` restituisce:

| Valore | Significato |
|---|---|
| row | Riga proposta per il run; non e un ordinale hint |
| segmento | ID u32 dell'ACTIVE associato alla riserva |
| offset | Posizione del record nel file: inizio del lotto piu start relativo |
| size | Lunghezza esatta del record, senza il SEAL |
| formato | v1 oppure v2 |
| stamp-kind | `:csn` per un ordinario, `:txid` per un prepared |
| high, low | Due parole u32 dello stamp verificato |

Il getter legge solo lo slot, senza accedere al buffer WAL. La generazione della
riserva rimane valida perche non si introduce il riuso dei trasferiti. Il vecchio
`leggi-legame-put-full-text`, invece, continua a rifiutare l'incarnazione obsoleta
del buffer. Il riferimento fisico non prolunga quel prestito ne attesta commit.

Per i cross-post NNTP e essenziale conservare `:txid`: il CSN del lotto che contiene
un prepared non e il suo CSN effettivo. Quest'ultimo richiede l'esito autorevole
2PC/OUTCOME, che questo incremento non produce. Il getter non converte TXID in CSN.
Nemmeno uno stamp `:csn` da solo certifica visibilita o durability.

## Errori e ownership

Token o autorita sbagliati, lotto aperto, sigillo manuale, cattura tardiva o ripetuta
sono rifiutati prima degli effetti. Header incoerenti, overflow interno o uscita
incompleta durante la cattura rendono pool e lotto FAULTED, conservando byte, costi
e obbligo CSN. Il confine del writer deve fermare la Serie; nessun rollback o ACK.
Un riferimento assente o parzialmente catturato non viene restituito.

I campi catturati non cambiano e il contesto di preparazione resta riutilizzabile.
Non si rilasciano slot, run, file budget o riferimenti ai lotti: il ritiro sicuro
richiede ancora i protocolli di pubblicazione e quiescenza. Il getter mantiene la
lease del writer; non e un ingresso per i reader concorrenti o per il demone NNTP.
Le altre Serie non condividono contatori o lock di questo meccanismo.

## Verifica e limiti

Nove test nuovi portano il totale full text a 102, di cui 27 del ponte PUT/WAL.
Coprono v1/v2, ordinari/prepared, stamp fino a UINT64_MAX, ordinale diverso dalla
row, offset di record preceduti da altri record, riuso reale del lotto, corruzioni
anche con header-CRC ricalcolato, autorita sbagliata e interruzioni prima/dopo la
cattura. Un probe CRC verifica una sola lettura di 20 byte e nessuna nel getter.
Quattro writer indipendenti completano i propri riferimenti con attese limitate.

La prova nativa scrive header di segmento e lotto, sincronizza, chiude e riapre
in sola lettura: i byte raggiunti dal riferimento coincidono con l'encoder
indipendente bitwise. La fixture modella la pubblicazione necessaria a risolvere
il token del lotto e riusarlo; non e una pubblicazione primary/delta di prodotto
e non decide una transazione prepared.

La misura PUT esistente include ora chiusura WAL e mille catture/getter, restando
una delle sei misure escluse dalla copertura strumentata. Il quattordicesimo
mutante controlla che la verifica dell'header non possa essere omessa.
Il [metodo preregistrato e le letture](full-text-riferimenti-metodo.md) e i
[registri originali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-17-fulltext-physical-dev-targeted/README.md)
distinguono prove locali e qualifica complessiva.

Restano unicita delle righe e composizione della mappa del delta, esiti prepared,
pubblicazione atomica documento/posting prima di H/ACK, acquisizione MVCC/EBR,
Query Engine e ritiro sicuro. Nessun requisito complessivo viene dichiarato
qualificato, nessun formato o ADR cambia, nessun benchmark del database completo.
