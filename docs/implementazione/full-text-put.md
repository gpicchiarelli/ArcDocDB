# Legame full text tra PUT e lotto WAL

`arcdocdb.fulltext.put` collega la [preparazione CBOR](full-text-documenti.md),
le [riserve del writer](full-text-riserve.md) e il lotto WAL esistente. Il primo
impiego resta un server NNTP Usenet scritto in Common Lisp, con Message-ID opaco
come chiave e campi subject/body indicizzati. Trasporto e decodifica MIME restano
al demone; il database riceve il documento CBOR.

## Una sola sorgente posseduta

`crea-preparazione-put-full-text(configs, ...)` prealloca una cornice record privata
e un task per ciascuna configurazione canonica ordinata, fino a sedici generazioni.
Il controllo cumulativo della memoria precede le allocazioni. Include frame, spazi
di analisi, run e metadati locali; configurazioni condivise, pool delle riserve,
altri contesti e RSS richiedono contabilita separata dal runtime.

I limiti predefiniti sono documento 16 MiB, chiave 65535 byte, 65536 scalari,
4096 token, 262144 byte di termini e memoria cumulativa 64 MiB. La dimensione
del frame include i 24 byte dell'header; il limite del formato puo rifiutare un
documento piu piccolo del limite applicativo. Il costruttore supporta v1/v2;
i rispettivi limiti fisici sono verificati nuovamente all'avvio.

`inizia-put-full-text(request, key, value, row, ...)` usa il codec record esistente
per copiare chiave e valore nella cornice, calcolarne i CRC e restituire una generation
senza wrap. Al ritorno, i buffer originari possono essere riutilizzati. La chiave
Message-ID e il documento originale restano byte esatti, senza normalizzazione.
Tutti i task analizzano esclusivamente lo span del valore nella stessa cornice.
L'identita deriva dall'ownership del buffer, senza affidarsi a un hash per confrontare
due copie esterne. Frame, task e handle delle riserve rimangono privati fino all'append.

L'API produce PUT ordinari, flag zero e stamp zero prima della chiusura, oppure
prepared, flag uno e TXID positivo passato come `txid-high`/`txid-low` u32.
Non introduce PUT contract-versioned o nuovi formati. La chiusura WAL successiva
ristampa solo gli ordinari con il CSN; conserva i TXID dei prepared.

## Analisi, consegna e ammissione

`passo-put-full-text(request, generation, quantum)` avanza fino a `:prepared`,
solo quando tutti i task sono DONE e il worker ha verificato CRC e span della cornice.
L'attestazione privata include la generation corrente e viene azzerata all'avvio,
al fallimento o alla cancellazione. Il frame resta immutabile fino all'append:
nessun ingresso pubblico permette di modificarlo o sostituirlo dopo l'attestazione.
Il lavoro e cumulativo per tutte le generazioni: tre volte la dimensione della
cornice (codifica e attestazione), passi di controllo e lavoro documentale,
con limite predefinito 268435456 unita. Il quantum 1..65536 limita i passi;
copia e CRC possono attraversare un intero record e non danno garanzie realtime.
Errore CBOR o esaurimento del budget invalidano il risultato prima dell'ammissione.
Rifiuti di avvio, invece, preservano un risultato precedente ancora valido.

Il worker possiede il request fino a PREPARED, poi lo consegna con handoff sincronizzato
al writer della Serie. Solo dopo l'analisi il runtime acquisisce la lease della coda
canonica. Non si aggiungono scheduler, thread o code concorrenti interne al ponte.

`prenota-put-full-text(pool, lease, request, generation)` adotta insieme i task;
`passo-riserva-put-full-text(..., quantum)` ne copia i run posseduti, passando da
`:reserving` a `:reserved`. Fino all'append il request non puo ripartire. La verifica
dei budget precede gli effetti; un rifiuto mantiene PREPARED e consente retry con
una capacita appropriata. Restano gli obblighi del runtime sulla canonicalita del
pool, sulle configurazioni e sulla contabilita di tutte le viste trattenute.

## Append e riferimenti stabili

`aggiungi-put-full-text(pool, lease, request, generation, batch)` richiede riserva
pronta, attestazione corrente del worker, lotto segment aperto dello stesso formato
e segmento, posto per un record e spazio finale per SEAL. Il writer verifica solo
metadati, capacita e lifetime; il CRC del body e calcolato fuori dalla lease,
come richiede [ADR-0039](../adr/0039-cornice-unica-dei-record.md).
Questi preflight precedono
il trasferimento irreversibile della riserva. Il writer copia poi esattamente la
cornice privata nel buffer WAL, conserva delta/file/slot, restituisce staging e
registra il legame nello slot stabile. Restituisce slot, token, start ed end.
Il request diventa `:appended` e puo tornare al worker con handoff simmetrico.
La successiva [cattura del riferimento fisico](full-text-riferimenti.md) collega
lo slot al record del lotto sigillato e sopravvive al riuso del buffer WAL.

`leggi-legame-put-full-text(pool, lease, slot, token)` restituisce sei valori:
lotto, incarnazione, numero del record, start, end e row proposta. Il legame sopravvive
al riuso del request. Il riuso del lotto incrementa l'incarnazione senza wrap;
vecchi riferimenti sono rifiutati anche se il nuovo record occupa gli stessi byte.
La saturazione dell'incarnazione e verificata anche dal preflight pubblico di riuso,
prima degli effetti del controller di Serie. Il consumer deve catturare i dati
necessari prima di consentire il riuso del buffer.

La row u32 proposta non e il numero del record nel lotto, un offset fisico, un
ordinale hint, un CSN o una prova di commit. Il ponte non assegna tali identita.
`wal:verifica-append-cornice` e `wal:aggiungi-cornice` sono primitive generiche
di verifica completa per cornici non fidate: da sole verificano formato/CRC e capacita,
non analisi o contratto documentale. Eseguono una scansione e non sono usate dal
percorso writer del ponte, che riceve esclusivamente la cornice privata attestata.

## Cancellazione e guasti

`annulla-put-full-text` interrompe l'analisi prima della riserva;
`annulla-riserva-put-full-text` restituisce costi e fonti prima dell'append.
Nessuna delle due e l'abort di una transazione gia preparata. Gli handle trasferiti
non sono cancellabili o riciclabili con questa API.

Se l'uscita durante trasferimento/append e incompleta, request, pool e lotto diventano
FAULTED; riferimenti, costi e byte eventualmente copiati restano conservati.
Il confine del worker deve fermare la Serie e richiedere recovery. Non si tenta
rollback di effetti incerti e non si produce ACK. Nessuna funzione del ponte esegue I/O.

## Verifica e limiti

I primi 18 test del ponte sono ora affiancati da nove prove dei riferimenti fisici:
27 test del ponte, 102 full text complessivi. Fixture CBOR congelata, encoder
record indipendente bitwise, input originari sovrascritti e confronto completo dei
byte verificano l'ownership. Sono coperti v1/v2, ordinario/prepared, TXID massimo,
sedici generazioni, limiti cumulativi, troncamenti/CRC, errori senza effetti,
64 punti di cancellazione, riferimenti obsoleti e interruzioni prima/dopo la copia WAL.
Quattro contesti indipendenti condividono solo configurazioni immutabili.
Un probe sul CRC intercetta qualsiasi scansione oltre i 20 byte dell'header mentre
il writer detiene la lease: verifica il rifiuto del vecchio percorso come controllo
negativo e l'append corretto con padding 0/32768 byte. Verifica anche i calcoli CRC
nel worker e il confronto completo del record. Header o chiave corrotti prima
dell'attestazione falliscono nel worker; attestazioni assenti/stale non consentono append.

Il [metodo e la tabella delle decisioni](full-text-put-metodo.md) riportano le due
letture dello stesso autore. I [registri originali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-17-fulltext-put-dev-targeted/README.md)
distinguono tentativi falliti, prove mirate, verifica completa e copertura diagnostica.

Restano da integrare validazione generale e autorita del catalogo di Serie,
canonicalita del log runtime, pipeline durevole con pubblicazione documento/posting
prima di H/ACK, esiti autorevoli 2PC, mappa fisica del delta, MVCC e ritiro dopo
quiescenza. Non si dichiara il motore pronto al traffico NNTP, benchmark applicativi,
qualifica C1, MC/DC o fault injection completa. I requisiti complessivi restano
`:progettato`; nessun ADR o formato disco e modificato.
