# Directory delle righe full text — metodo preregistrato

22 ottobre 2026, REQ-SEC-003/004/006/010 e REQ-CON-002, ADR-0054 e INV-I5/I6.
La directory locale del pool collega una row u32 univoca alla riserva canonica;
il ponte PUT ne risolve il riferimento fisico senza dipendere dal buffer WAL.
Non introduce pubblicazione, reader concorrenti, esiti prepared o reclaim.

Due array u32 preallocati, ordinati per row, contengono chiave e posizione dello
slot. Ricerca binaria limitata a 11 passi per capacita massima 1024; inserimento
e cancellazione spostano al piu 1024 coppie di metadati sotto la lease del writer.
Nessuna scansione del documento, allocazione calda, lock o stato tra Serie.
La directory sostituisce il precedente controllo lineare dei duplicati.

| Decisione | Verifiche previste |
|---|---|
| Costruzione | capacita invariata, 8 byte per slot aggiunti al limite memoria prima dell'allocazione |
| Ricerca | 0 e UINT32_MAX validi; assenza distinta da riga presente ma incompleta |
| Prenotazione | tutte le verifiche e duplicato prima degli effetti; stesso errore pubblico esistente |
| Adozione | slot/generation/row canonici; ordinamento stretto e count uguale agli occupati |
| Cancellazione | rimuove solo COPYING/READY, prima dell'append; idempotenza e token vecchio preservati |
| Trasferimento | entry trattenuta senza riuso o cancellazione, come costi e run |
| Esposizione | COPYING/READY => pending senza handle; solo TRANSFERRED espone slot/generation al ponte |
| Risoluzione | absent/pending senza metadati; sealed conserva offset, formato e :CSN/:TXID verificati |
| Guasto | incoerenza o mutazione interrotta => pool FAULTED e dati/costi conservati, nessun rollback |

Oracolo C4 con lista associativa indipendente: sequenze finite di inserimenti in
ordine diverso, cancellazioni e trasferimenti; confronto di tutte le row dopo
ogni operazione. Capacita minima/massima, bordi, richieste estranee/stale, rifiuti
senza effetti e interruzioni durante adozione/rimozione. Fixture NNTP e file/record
gia verificati; ricerca dopo il riuso del lotto e distinzione TXID/CSN.

Estendere le misure gia presenti di riserva e PUT, lasciando sei esclusioni CI:
100 warm-up, GC, mille operazioni e lookup senza heap. Quattro writer privati
con gli stessi numeri di riga, attese finite. Mutante semantico sulla ricerca
pubblica che restituisce sempre assente, per dimostrare la sensibilita dell'oracolo. Conservare output originali,
sorgenti effettivi e tutti i fallimenti. Due letture dello stesso autore; C1 e MC/DC aperti.

## Decisioni composte introdotte o estese

| Funzione | Condizioni della decisione |
|---|---|
| `verifica-writer-riserve` | count entro slot; row-count uguale a count; tre capacita uguali; staging/delta/file entro i limiti gia presenti |
| `posizione-riga-riserve` | row-count entro array e massimo 1024; 0 <= low <= high <= count; convergenza low=high |
| `slot-riga-riserve` | posizione nel prefisso e chiave uguale; mapping entro slot; tipo, posizione, pool, row, generazione positiva e stato vivo canonici |
| `trova-riga-trasferita-full-text` | posizione nel prefisso e chiave uguale; solo transferred espone lo slot, gli altri stati vivi restituiscono pending |
| `preflight-riserva` | posizione nel prefisso e chiave uguale: verifica slot canonico e rifiuta duplicato prima di mutare |
| `verifica-posizione-inserimento-riga` | posizione <= count e spazio; bordo sinistro oppure vicino inferiore, bordo destro oppure vicino superiore |
| `inserisci-riga-riserva` | effetto attivo, pool dello slot uguale, stato copying; postcondizione di mapping allo stesso slot |
| `rimuovi-riga-riserva` | effetto attivo e stato copying/ready; stessa entry canonica, post count diminuito di uno |
| `prenota-full-text` | count=row-count dopo l'inserimento e budget delta/staging rispettati |
| `annulla-riserva-full-text` | rimozione soltanto pre-append secondo le guardie gia presenti, post count=row-count |
| `leggi-riferimento-riga-full-text` | absent/pending senza scalari; transferred con fisico absent resta pending, sealed verifica row, altro stato causa fault |

I test coprono il contratto pubblico e corruzioni selezionate, non dimostrano ancora
l'indipendenza di ogni condizione delle guardie interne. Il conteggio MC/DC non e
dedotto da SB-COVER o dai quindici mutanti dell'intera suite.

## Due letture del medesimo autore — 22 ottobre 2026

Prima lettura: verificati requisito/ADR, proprietario writer, chiavi senza sentinelle,
univocita per pool, limiti di ricerca/spostamento e ordine preflight/effetti.
Gli effetti di adozione e cancellazione iniziano dentro `unwind-protect`; un'uscita
incompleta lascia il pool faulted anche fra aggiornamento della directory e contatori.
Costi e prestiti non sono restituiti per simulare un rollback.

Seconda lettura: verificati array tipizzati e readonly nei riferimenti, assenza di
stato globale o I/O, contratti degli otto valori, nessun handle copying/ready,
distinzione CSN/TXID e nessuna dipendenza dal buffer WAL riusato. Separata la
verifica di posizione/vicini per contenere la complessita delle funzioni; uno slot
mancante viene riconosciuto come invariante prima di leggerne i campi. Ricontrollati
oracolo associativo, mutante semantico e limiti delle affermazioni documentate.
Nessuna modifica durevole o di formato, nessun ritiro di dati. Tracciabilita e
verifica completa devono essere registrate sui sorgenti congelati; questa e una
autolettura, non revisione indipendente ne qualifica C1.
