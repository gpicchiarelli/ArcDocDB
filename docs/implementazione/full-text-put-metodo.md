# PUT full text — metodo di verifica e decisioni

Metodo del 17 ottobre 2026, prima delle prove: ADR-0054, REQ-SEC-003/006/010,
REQ-WAL-005 e REQ-CON-002. Una cornice privata posseduta, creata dal codec esistente,
fornisce il valore a tutti i task e gli stessi byte all'append del lotto.

Fixture: Message-ID NNTP come chiave opaca, CBOR subject/body di 25 byte congelati,
confronto completo del record con encoder indipendente, prefissi/suffissi sentinella.
Mutare key/value del caller dopo l'avvio deve lasciare invariati run e WAL.
Versioni v1/v2, ordinario/prepared e TXID u64 massimo in due parole; SEAL successivo
deve ristampare solo gli ordinari. Bordi di memoria/lavoro/formato/capacita batch,
rifiuti senza costi trasferiti, cancellazione prima dell'append, token stale e incarnazioni.

Heap: 100 warm-up con preparazione/prenotazione/copia/cancellazione, GC completa,
poi 1000 preparazioni/prenotazioni/copie/append/query su lotti preallocati;
misure distinte dalla copertura strumentata.
Quattro contesti privati possono condividere solo configurazioni readonly; attese finite.
Conservare comandi, sorgenti effettivi, output originali e ogni fallimento.

| Decisione composta | Condizioni |
|---|---|
| Costruzione | configurazioni canoniche ordinate, tutte le capacita e costo cumulativo prima delle allocazioni |
| Avvio | token/stato, input u8 non alias, row u32, prepared e TXID coerenti, generazione senza wrap |
| Frame | limiti v1/v2, copia chiave/valore e CRC prima dell'analisi; nessuna sorgente esterna trattenuta |
| Analisi | stesso span privato per tutti, lavoro cumulativo, tutti DONE e attestazione CRC/spans corrente nel worker |
| Riserva | lease canonica, task privati, configurazioni correnti; handle non esportati durante copia/cancellazione |
| Append | attestazione posseduta corrente, formato/segmento e batch aperto, spazio SEAL; solo metadati e copia sotto lease |
| Legame | slot trasferito, batch/incarnazione/ordinale/intervallo catturati; vecchi batch riusati rifiutati |
| Guasto | interruzione dopo trasferimento => request, pool e lotto FAULTED; riserva conservata, nessun rollback o ACK |

Questo metodo non chiude la qualifica C1 o MC/DC. Restano contratto documentale generale,
canonicalita runtime/pool/log, pubblicazione prima di H/ACK, esiti prepared, mappa del
delta, MVCC e ritiro dopo quiescenza. La row proposta non e l'ordinale di un hint.
PUT contract-versioned non introdotti: l'API produce solo i flag 0 o prepared gia supportati.

## Due letture dello stesso autore

Prima lettura: seguiti frame, span CBOR e tutte le generazioni fino alla copia WAL;
nessun input esterno trattenuto e nessun handle delle riserve esposto prima dell'append.
Controllati limiti e rifiuti prima degli effetti, saturazione dei token, due parole TXID,
distinzione fra row proposta, record nel lotto e future identita fisiche.

Seconda lettura, dopo le prove mirate: seguiti cancellazione e uscita non locale,
costi conservati, ritorno del request al worker e riuso del batch. Il controllo di
saturazione dell'incarnazione e stato spostato nel preflight pubblico `verifica-riuso-lotto`,
cosi il controller di Serie lo vede prima della propria mutazione. Rinforzati i
limiti dell'intervallo catturato e incluso il nuovo gruppo nel catalogo CI centrale.
Queste due letture non costituiscono una revisione indipendente.

La rilettura di integrazione ha individuato un calcolo body-CRC nel preflight del
writer, contrario ad ADR-0039. L'attestazione completa e spostata nel worker dopo
l'analisi; generation privata, stato e ownership del frame ne garantiscono il lifetime.
Il writer controlla attestazione corrente, formato/segmento, stato e capacita senza
scansioni del body. Due nuove prove coprono corruzioni prima dell'attestazione e
un probe CRC con controllo negativo del vecchio percorso, su due dimensioni.
Un tredicesimo mutante verifica che l'attestazione non possa essere ignorata.
Il percorso legacy `aggiungi-record` resta fuori da questo incremento.

Le [evidenze](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-17-fulltext-put-dev-targeted/README.md)
conservano anche i due arresti di compilazione e separano le verifiche finali.
