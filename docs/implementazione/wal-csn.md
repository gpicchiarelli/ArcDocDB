# Collegamento fra lotti WAL e registro CSN

Il ponte `arcdocdb.wal` realizza la chiusura dei lotti di segmento prevista da
[ADR-0037](../adr/0037-lotto-sigillato.md), conservando il token del
[registro di Archivio](csn.md) secondo [ADR-0046](../adr/0046-orizzonte-con-registro-limitato.md).
Il writer logico possiede il lotto; osserva gli esiti del compito I/O dopo un
handoff sincronizzato. Il registro condiviso viene toccato due volte per lotto.

| Passaggio | API e risultato |
|---|---|
| Preparazione | `aggiungi-record`: buffer privato, spazio SEAL riservato, nessun CSN. |
| Chiusura | `sigilla-lotto-con-csn lotto registro log inizio durable`: verifica le precondizioni, prende il CSN, conserva registro/log/slot/parole nel lotto, prepara SEAL. Ritorna lunghezza, high, low. |
| Scrittura e flush | API dei [gruppi WAL](wal.md): copertura dei byte, nessuna risoluzione automatica. |
| Pubblicazione | Il controller pubblica atomicamente nell'indice e rispetta l'ordine della Serie. |
| Risoluzione | `risolvi-lotto-pubblicato lotto registro slot high low livello`: verifica log sano e copertura, libera il token; ritorna H-high, H-low. |
| Guasto | Dopo transizione della Serie in FAULTED e completamento/ritiro dei consumatori, `annulla-csn-lotto lotto registro slot high low` richiede anche il log FAULTED. Libera il token senza modificare file. |
| Riuso | `riusa-gruppo`, poi `riusa-lotto`: richiedono durability, nessun consumatore e nessun CSN pendente. |

## Identità e rifiuti

Il token è conservato insieme al registro di provenienza e al log effettivo.
`aggiungi-lotto` rifiuta il trasferimento verso un altro oggetto log, anche se
file-id e versione coincidono. `leggi-csn-lotto` ritorna slot/high/low senza
materializzare un u64; l'identità resta leggibile dopo la risoluzione e viene
azzerata solo al riuso. Gli eventi conservano registro e slot/high/low catturati
alla chiusura: le API di risoluzione confrontano l’identità attesa prima di
liberare il credito, anche dopo il riuso o fra Archivi con valori numerici uguali.
`stato-csn-lotto` distingue libero, pendente e risolto.

Prima di prendere il CSN si verificano stato aperto, budget interni, offset,
segmento non vuoto, identità/versione del log, salute e disponibilità del file append.
Il budget di trasferimento e quello del file comprendono anche le chiusure
pianificate prima del lotto corrente; un inizio precedente ai byte scritti
è rifiutato. L’esecutore ripete i controlli prima delle syscall. La frontiera storica
non può superare né l'inizio pianificato né la frontiera durevole osservata.
Il log può avere altre chiusure pianificate: l'inizio non deve coincidere già
con la posizione scritta; l'esecutore controlla la contiguità prima dell'append.

Registro pieno, occupato o esaurito lascia invariati lotto e registro. Un rifiuto
successivo del gruppo conserva il token: il controller riprogramma il lavoro;
non prende un secondo CSN. Un rifiuto busy alla risoluzione conserva l'obbligo.
Una seconda risoluzione è rifiutata; un errore di identità del token è propagato.
Non esistono attese, retry interni, callback o allocazioni di contesti per chiusura.

## Copertura, pubblicazione e guasti

Durability e H sono frontiere diverse. Un flush riuscito lascia il CSN pendente
finché l'indice non è pubblicato. In async, il writer può risolvere dopo append
e pubblicazione; il buffer resta protetto dal normale vincolo di durability
fino al completamento del flush. Questo impedisce il riuso durante l'I/O.

Il controller deve validare identità dell’evento, salute, copertura e ordine
prima della pubblicazione esterna. Deve conservare l’esito già pubblicato
se la sola risoluzione rifiuta busy, evitando di pubblicare due volte.
La salute del log viene ricontrollata alla risoluzione: anche un vecchio lotto
durevole non autorizza una nuova pubblicazione dopo un guasto successivo.
L'annullamento richiede la transizione FAULTED della Serie applicata dal
controller. Il ponte possiede solo il log: non può dimostrare autonomamente
quella transizione, la pubblicazione dell'indice o l'assenza di consumatori.
Queste sono precondizioni interne esplicite, non capability per input esterno.

Un errore inatteso dopo l'assegnazione, oppure un'interruzione asincrona durante
il passaggio fra registro e campi del lotto, richiede fail-stop dell'Archivio.
Il ponte non promette rollback o retry in quella finestra. I normali rifiuti
tipizzati prima dell'assegnazione e il busy del registro sono invece riprogrammabili.

## Codifica e confini

`scrivi-record-parole` è il codec comune con stamp high/low u32; la precedente
`scrivi-record` delega allo stesso codec. Record ordinari e SEAL usano le parole
direttamente; prepared e OUTCOME conservano il TXID. Il file-id del SEAL resta
codificato una volta alla costruzione. Il buffer diventa immutabile alla chiusura.
Il punto atomico è il SEAL persistito dalla scrittura; la chiusura lo prepara.

Il ponte accetta solo segmenti non vuoti. Gli ordinali del control.log e il CSN
della DECISION multiserie richiedono coordinatori distinti, ancora da collegare.
Restano da realizzare indice, controller delle Serie, pubblicazione ordinata,
conferme e registrazione/risveglio degli snapshot. Non viene dichiarata una
transazione completa o una prestazione del database.

Il [metodo di verifica](wal-csn-metodo.md), la
[matrice delle decisioni](wal-csn-decisioni.md) e la
[revisione C1](wal-csn-revisione.md) conservano gli argomenti verificabili.
