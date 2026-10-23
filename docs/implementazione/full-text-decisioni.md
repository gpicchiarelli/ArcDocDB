# Full text — revisione del nucleo e decisioni

Perimetro: [analizzatore, run posizionale e cornice](full-text.md).
Classe C1 per la cornice; C2 per l'analisi e i predicati sul run.
Le due letture del 16 ottobre 2026 sono revisioni dello stesso autore della modifica,
non una revisione indipendente e non una qualifica del motore completo.

## Decisioni composte della cornice C1

Le asserzioni interne sono sempre attive; quando il nucleo sara collegato a un worker,
quel confine dovra convertire `invariant-violation` nel fail-stop della Serie.
I test dei rifiuti pubblici controllano condizione, motivo e preservazione dei byte.

| Funzione / decisione | Condizioni e copertura |
|---|---|
| `controlla-input-cornice`: range | Array semplice u8, start/end index, start <= end <= length; buffer nil, start negativo, fine oltre buffer e range invertito, oltre agli span validi non allineati |
| Stessa: identita e budget | Identita u8 di 16 byte; budget index positivo; identita corta/nil, budget zero/testuale e validi; segment-id fuori u64 rifiutato |
| `controlla-lunghezze-cornice`: layout | Array u64 di sei elementi, META 1..65536, dimensione minima, divisibilita e capacita di ogni sezione; vettore generico, META zero/65537, larghezza errata, capacita insufficiente e u64 enorme |
| Stessa: allineamento/fine | Padding entro capacita e cursore finale esatto; fixture con sezioni vuote, padding e META massimo; dimensione finale incompatibile rifiutata |
| `scrivi-cornice-indice-full-text` | Input e capacita controllati prima di ogni scrittura; buffer/identita senza alias; budget file minore, uguale e maggiore dello span |
| `verifica-header-full-text`: CRC/magic/versione/kind | Tutti i bit del campione; alterazioni con CRC ricalcolato; versione ignota distinta dal contenuto corrotto |
| Stessa: count/flags/riservati | Count 6, flags zero, riservato zero verificato anche fuori dalla copertura CRC dell'header; ciascuno alterato separatamente |
| Stessa: dimensione e directory | Dimensione esatta e offset directory 64; alterazione separata con CRC corretto |
| Stessa: segmento e Serie | U64 confrontato senza ricomporre un bignum; identita byte per byte; segmento/Serie scambiati rifiutati |
| `verifica-entry-full-text`: campi | Type ordinale esatto, flags e riservati zero; ciascun campo alterato per ognuna delle sei entry |
| Stessa: intervallo | Offset atteso e lunghezza <= residuo; offset alterati, lunghezza u64 enorme, ampiezze fisse e META zero, oltre alle fixture valide |
| `verifica-directory-full-text` | Allineamento entro footer e tutti i byte padding zero; padding alterato con CRC corretto, sezioni vuote e nessuna coda ammessa |
| API reader: cornice completa | Span minimo prima delle letture; budget prima del contenuto; header prima del footer; directory prima del ritorno dello span META |
| Guardie interne di header/directory/entry | Range e postcondizioni separati dai rifiuti del wire; i rami fail-stop non sono dichiarati tutti coperti dai casi pubblici |

Le asserzioni di postcondizione non scrivono e non riparano dati. La copertura SB-COVER
e diagnostica: le guardie interne non raggiunte, le decisioni composte e i limiti
estremi non diventano qualificati solo perche tutti i test passano.

## Lettura 1 — formato, invarianti ed errori

Riletti offset e larghezze contro ADR-0054: header 64, directory 144, sei sezioni da
208, footer quattro byte; CRC dell'header escluso dal proprio span e CRC finale da 64.
Nessun campo esterno diventa un oggetto Lisp o un percorso. Somme delle lunghezze
solo dopo confronto con il residuo; padding calcolato entro capacita; identificativi
u64 senza conversione lossy. Preflight del writer prima di modificare la destinazione.
Fixture e CRC dell'oracolo sono costruiti separatamente dal prodotto.

Il controllo del layout non sostiene ancora INV-I5: mancano META, confronto con il
descriptor autorevole e con l'hint, validazione di dizionario/posizioni/lunghezze.
La prova `REQ-SEC-008-NO-SEMANTIC-PROMOTION` rende questo limite osservabile.

## Lettura 2 — ownership, lavoro e risultati

Rilette le transizioni: analisi `idle/done/failed -> decode -> … -> done/failed`;
run `building -> copying -> building -> heap-build -> heap-sort -> sealed/failed`.
Un risultato analitico parziale non e accessibile; un run non sigillato non e cercabile.
La query cambia solo il proprio contatore di lavoro. Tabelle Unicode e run sigillati
sono condivisi solo in lettura; nessuna scrittura tra Serie per operazione.

I limiti di memoria precedono le allocazioni dei costruttori. I limiti del run
precedono l'acquisizione dello scratch; limiti di analisi, confronto, copia e sort
producono errori espliciti. Le frasi verificano posizione e ripetizioni nella medesima
riga/campo; il componente non unisce versioni o verifica visibilita da solo.
Nessun I/O, commit o cleanup durevole e introdotto qui; INV-I4/I6 richiedono ancora
il raccordo con writer e Query Engine. Misure di allocazione e prove parallele sono
separate dalla copertura strumentata. Il controllo completo del repository e
registrato con hash dei sorgenti, ambiente, stdout, stderr e codice di uscita.
