# Directory delle righe full text

La directory privata collega la row u32 dei posting alla riserva canonica del
pool e al [riferimento fisico PUT](full-text-riferimenti.md). Per il primo impiego
NNTP serve a risalire da un risultato full text al record dell'articolo, senza
dipendere dall'incarnazione riusabile del buffer WAL. La row non e il numero di
articolo di un newsgroup, un Message-ID o un ordinale dell'hint.

## Proprietario e limiti

Ogni pool di un nuovo ACTIVE possiede due array u32 preallocati, ordinati per row:
chiavi e posizioni degli slot. La stessa row e ammessa in pool distinti; tutte le
generazioni degli indici di un documento condividono invece una sola entry locale.
`0` e `UINT32_MAX` sono chiavi valide: l'occupazione e determinata dal contatore.

La ricerca binaria esegue al piu 11 confronti di chiavi con capacita 1..1024.
Inserimento e rimozione spostano al piu 1024 coppie di metadati sotto lease del
writer, senza leggere il documento. Non e una misura di latenza del motore.
Il limite conservativo C0 delle [riserve](full-text-riserve.md) cresce di 8 byte
per slot; la base copre anche gli header dei due array. La capacita e del pool,
non un limite complessivo agli articoli memorizzabili dal futuro database.

La directory sostituisce la scansione lineare dei duplicati e cambia solo dopo
i preflight esistenti. La cancellazione pre-append rimuove l'entry prima di
liberare fonti e costi; idempotenza e protezione dei token obsoleti restano valide.
Un trasferimento trattiene entry, slot, run e costi. Il ritiro richiede ancora un
protocollo dedicato con esito autorevole e quiescenza.

## Ricerca sotto lease

`admission:trova-riga-trasferita-full-text(pool, lease, row)` restituisce:

| Stato | Slot e generazione |
|---|---|
| `:absent` | `nil`, `0`: nessuna entry nel pool corrente |
| `:pending` | `nil`, `0`: COPYING/READY, senza esporre gli handle privati del ponte PUT |
| `:transferred` | Slot canonico e sua generazione, senza attestazione di commit |

`put:leggi-riferimento-riga-full-text(pool, lease, row)` restituisce otto valori:
stato, segmento, offset, size, formato, stamp-kind, high e low.

| Stato | Altri valori |
|---|---|
| `:absent` | `0 0 0 0 :none 0 0` |
| `:pending` | `0 0 0 0 :none 0 0`: riserva privata oppure riferimento non ancora catturato |
| `:sealed` | Posizione stabile verificata, v1/v2, `:csn` ordinario o `:txid` prepared |

Anche un trasferimento generico senza PUT resta `:pending`. La lettura sealed
usa solo metadati della riserva e sopravvive al riuso del lotto; non consulta
il WAL, H, il filesystem o l'esito 2PC. Lease estranee o row non u32 sono rifiutate
senza effetti. Contatori, mapping canonico o fase fisica incoerenti causano
FAULTED; una mutazione interrotta conserva slot, fonti e costi, senza rollback.

Queste API appartengono al writer. Gli array vengono spostati e non possono
essere condivisi con reader concorrenti. La mappa immutabile della vista delta,
pubblicazione, snapshot/MVCC, risoluzione dei prepared, recovery della directory
e collegamento alla query completa restano da implementare. Nessun requisito
full text viene chiuso nel suo perimetro complessivo.

## Verifica

Il [metodo preregistrato](full-text-righe-metodo.md) usa un modello associativo
indipendente, 64 sequenze di inserimento/cancellazione/trasferimento, estremi u32,
capacita 1/1024, limiti memoria, rifiuti senza effetti e guasti iniettati. Le misure
esistenti di riserva e PUT includono la ricerca; quattro contesti privati usano le
stesse row. Un mutante che restituisce sempre assente deve essere rilevato.
La copertura strumentata resta diagnostica e separata dalle misure di heap;
revisione indipendente, MC/DC e qualifica C1 rimangono aperte.
