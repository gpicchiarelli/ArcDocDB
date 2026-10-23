# Resolver GET del nuovo segmento ACTIVE

`arcdocdb.get.resolver` collega i **lotti ordinari** del writer alla radice
pubblicata da `arcdocdb.series`. Completa questo tratto del percorso ACTIVE,
senza cambiare le decisioni di [ADR-0037](../adr/0037-lotto-sigillato.md) e
[ADR-0041](../adr/0041-multiserie-segmenti-autosufficienti.md). Le prove
prepared/OUTCOME dell'ACTIVE restano da integrare: il wrapper le rifiuta
esplicitamente, senza interpretarle come abort o come corruzione del formato.

La directory introdotta qui contiene **pagine di uno stesso ACTIVE**. La
[directory della Serie](get-fonti-serie.md) sceglie fra ACTIVE e CLOSED.
L'indice concreto, la rotazione/reclaim e il server restano integrazioni distinte.

## Autorità e ordine di pubblicazione

La frontiera non è la dimensione del file, la posizione scritta del WAL, H
o un offset passato dal reader. Il reader acquisisce la radice effettiva
tramite `leggi-radice-serie`, con la barriera acquire esistente, **dopo**
`avvia-get` sotto EBR. Una radice soltanto pianificata non è acquisibile
attraverso le API ACTIVE del reader.

1. Nel pool I/O costruire `segmento-get` con header letto dal FD readonly.
   Nel pool I/O usare [associa-file](associazione-file.md) per provare che questo
   FD e quello append appartengono allo **stesso file fisico**, e mantenerli
   aperti fino al reclaim. Identità/versione/header
   non costituiscono, da soli, una prova di identità fisica dei due FD.
2. Creare un controller locale per il nuovo ACTIVE, con root `nil` e
   `:next-offset 64`, e acquisirne la lease. Con questa lease,
   `crea-sorgente-get-attiva` verifica origine writer, ID positivo u32,
   versione del log e configurazione. Passando `:associazione-file prova`,
   verifica anche le due capacità effettive senza I/O. Omettere la prova conserva
   l'obbligo originario del caller; il solo header non lo assolve.
   Il [preparatore del nuovo writer](inizializzazione-active.md) fornisce una
   factory che richiede la prova, dopo header durevole e verifica della rilettura.
   Prima dell'ammissione, l'[avvio vuoto](get-active-vuoto.md) può pubblicare
   le fonti recuperate con zero pagine e nessun evento o CSN.
3. Sul lotto OPEN, chiamare `verifica-capienza-get-attiva` **prima** del
   ponte WAL–CSN. La preflight verifica ring, contiguità, forma supportata,
   spazio segmento e budget; restituisce il numero PUT, senza assegnare CSN
   o riservare risorse. Mantenere lease, contenuto e radice precedente
   **pianificata**, inizialmente `nil` oppure la radice vuota pubblicata,
   stabili fino alla sigillatura/adozione.
   Poi sigillare e preparare il payload immutabile del caller. La preflight
   non certifica i CRC dei valori: la verifica completa segue la sigillatura.
4. `registra-lotto-get-attivo` controlla lease, ring, token, log e ordine;
   verifica **solo il nuovo lotto** in memoria, inclusi CRC, SEAL, posizione
   assoluta, count e CSN. Copia i metadati dei PUT ordinari in una pagina
   privata. I tombstone occupano il log e la frontiera, senza una riga PUT.
5. Il wrapper adotta lotto e nuova radice con il normale
   `registra-commit-serie`, prima del dispatch I/O. Restituisce evento,
   generazione catturata e nuova radice pianificata. Non pubblica né
   conferma al client.
6. Il normale `pubblica-commit-serie` verifica copertura e FIFO prima del
   CAS: `:async` dopo write, `:group`/`:strong` dopo la copertura durevole.
   La risoluzione CSN segue il CAS; `:pendente` conserva l'obbligo e non
   ripubblica. Fine I/O, ritiro e riuso restano al protocollo esistente.

Il SEAL persistito è il punto di atomicità WAL; la preparazione di una
pagina non attesta write/fsync. Il CAS pubblica memoria. Il payload del
caller è leggibile con `contenuto-radice-get-attiva`, ma il wrapper non
costruisce né verifica il contenuto di un indice concreto. Una location
deve diventare osservabile **dopo** la pagina corrispondente; mutare un
indice raggiungibile da radici pubblicate viola il contratto. Il collegamento
atomico all'indice primario resta da completare.

## Directory persistente e limiti di lavoro

La directory ha quattro livelli, ciascuno di sedici riferimenti, indicizzati
con le quattro cifre binarie di un rank u16. Le pagine seguono l'ordine fisico
dei lotti. Un append copia quattro vettori e condivide soltanto sottografi
immutabili. Non ricopia i PUT precedenti, non rilegge il file ACTIVE e non
conserva una catena di radici precedenti. Le radici vecchie rimangono valide.

| Percorso | Limite |
|---|---|
| Preflight prima del CSN | Header del lotto OPEN; nessuna copia del body, array o riserva |
| Verifica del nuovo lotto | Byte e record del lotto, configurati prima dell'adozione |
| Conteggio e copia metadati | Due passate sugli header del nuovo lotto; nessuna copia dei valori |
| Append directory | Quattro vettori × sedici riferimenti; ricorsione limitata a quattro livelli |
| Ricerca pagina per offset | Al più 17 confronti e un accesso finale, quattro livelli per accesso |
| Ricerca PUT nella pagina | Resolver comune: al più 33 passi |
| GET | Nessun I/O nella risoluzione/sonda; I/O soltanto nel pool dedicato |

Una ricerca nel caso massimo può usare tutti i diciassette confronti: la
convergenza viene controllata anche dopo il ciclo, senza richiedere un
diciottesimo confronto. Offset in header/SEAL/tombstone, fuori frontiera,
o senza riga concorde **non** significano documento assente. Sono guasti
di una location già pubblicata.

## Memoria

Budget predefiniti per sorgente: 65.536 pagine, 1.048.576 PUT, 65.536 record
per lotto, 64 MiB per lotto, 64 MiB di payload del resolver. Sono budget di
risorse, non nuovi limiti di dimensione dei documenti. La saturazione richiede
backpressure/rotazione del controller; non produce wrap o crescita implicita.

| Dato su SBCL a 64 bit | Payload |
|---|---|
| Riga PUT | Sei u32, 24 byte; offset assoluto, size, flag, due word CSN e proof zero |
| Nodo della directory | Sedici riferimenti, 128 byte escluso header Lisp |
| Vista con tutte le 65.536 pagine | 4.369 nodi, 559.232 byte per la directory |
| Picco preflight di un append | Payload precedente + `24 × nuovi PUT` + 512 byte |

`payload-radice-get-attiva` conta righe e nodi raggiungibili dalla singola
vista. Il picco considera la precedente vista durante la costruzione e
quattro nuovi vettori, anche quando alcuni sostituiscono nodi esistenti.
Array e pagine non vengono esposti al caller, che non può mutarli tramite
l'API pubblica. Il lotto/evento riusabile non rimane nel grafo della root.

Oggetti/header Lisp, payload dell'indice chiamante, FD, buffer dei lotti,
radici trattenute da eventi/reader e ritardi GC sono esclusi. Il controller
deve imporre il budget complessivo delle viste vive e del backlog. Il
costruttore alloca per lotto; assenza di heap esplicito nel lookup non è una
misura di allocazione, latenza, RSS o throughput. Non si rivendica COD-30.

## Lettura, guasti e lifetime

| API | Risultato |
|---|---|
| `risolvi-candidato-attivo-get(context, source)` | Capacità readonly, fine della pagina del candidato, flag storage, prova `nil` |
| `sonda-cache-attiva-get(context, source)` | Esito della sonda GET ordinaria con frontiera pubblicata |
| `leggi-record-attivo-get(context, source)` | Cinque esiti del nucleo GET nel pool I/O |

Le tre API legate alla sorgente non accettano una radice o una frontiera
fornita dal chiamante. Il [ponte delle fonti della Serie](get-fonti-serie.md)
usa invece il resolver della radice già catturata sotto EBR, con gli
obblighi di pubblicazione e lifetime dichiarati in quel contratto.
Controlla identità sorgente/root, geometria directory e candidato tramite il
resolver comune. GET verifica ancora CRC/chiave/CSN del record/cache; la
pagina non sostituisce il dato fisico. Risposta privata fino a copia e
`concludi-get` con tempo fresco; il cleanup esterno resta obbligatorio.
La migrazione richiede nuovo `avvia-get`, nuova epoca e nuova acquisizione.

Rifiuti di configurazione, capacità e funzionalità non supportata precedono
l'adozione. Con la preflight OPEN obbligatoria nel protocollo non si assegna
CSN a un lotto che già supera questi budget. La successiva adozione
ricontrolla i limiti; chi la chiama direttamente conserva lotto/token su
rifiuto e deve gestirli col protocollo WAL esistente, senza scartarli.
La preflight non garantisce allocazione riuscita o disponibilità del registro
CSN condiviso. Corruzione di un buffer
sealed posseduto dal writer o invariante impossibile durante preparazione/
adozione marcano il controller FAULTED di Archivio e propagano la causa.
Un'interruzione dell'adozione segue il fail-stop esistente. Il coordinatore
deve fermare l'Archivio, non limitarsi a liberare il contesto della richiesta.
Sul reader, salute guasta propagata e incoerenze rendono il GET FAULTED;
gli errori e le uscite non locali rilasciano EBR senza autorizzare il valore.

FD e risorse esterne richiedono protezione EBR fino all'ultimo riferimento;
un riferimento GC non autorizza la chiusura. Rotazione, selezione fra i
segmenti, pubblicazione indice e reclaim devono rispettare questo ordine.

## Decisioni C1 e qualifica aperta

Ogni decisione composta introdotta è registrata qui; la copertura condizione
per condizione **non è stata eseguita** in questo incremento.

| ID | Decisione | Casi da qualificare |
|---|---|---|
| GSA-D01 | Nodo NIL oppure larghezza sedici | NIL, valido, geometria impossibile |
| GSA-D02 | Nodo reader è vettore e ha sedici figli | Tipo/forma errati separatamente |
| GSA-D03 | Convergenza finale e rank nella vista | 65.536 pagine, estremi, rank mancante |
| GSA-D04 | SEAL nella posizione/count esatti | Count, fine e ordine discordi |
| GSA-D05 | Lotto: ID e versione della sorgente | Ciascuna discordanza |
| GSA-D06 | Risultato lotto: fine, count, durable ≤ start | Ogni risultato impossibile separato |
| GSA-D07 | CSN alto e basso del SEAL | Ciascuna word discordante |
| GSA-D08 | Copia: fine e numero righe esatti | Fine/count discordi, zero PUT |
| GSA-D09 | Configurazione: pagine, PUT, record, byte, payload | Tutti gli estremi e saturazioni |
| GSA-D10 | Sorgente: high zero, low positivo, origine, ID e versione | Ogni identità discordante |
| GSA-D11 | FD readonly e aperto | Mode/stato/lifetime errati |
| GSA-D12 | Nuovo controller: root NIL, count zero, offset 64 | Controller già avviato/altro prefisso |
| GSA-D13 | Root reader del tipo corretto e stessa sorgente | Root solo pianificata, root estranea |
| GSA-D14 | Preflight OPEN: ID e versione della sorgente | Ciascuna discordanza prima del CSN |

Le [evidenze statiche](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-active/README.md)
conservano compilazione e controlli di prodotto/documentazione. Le due letture
sono locali dell'autore, non revisione indipendente. Nessun nuovo test,
benchmark, fault injection, modello o self-test era stato aggiunto/eseguito
localmente nell'incremento iniziale. La successiva [verifica funzionale
dedicata](get-active-verifica.md), secondo il [metodo preregistrato](get-active-metodo.md),
aggiunge 28 test ordinari, copertura diagnostica e audit indipendenti.
Il [metodo dei rifiuti OPEN](get-active-preflight-metodo.md) registra il
successivo approfondimento prima del CSN, con casi di identità, stato e
capacità e mutazioni selezionate, mantenendo separate le attribuzioni.
La [verifica dei rifiuti OPEN](get-active-preflight-verifica.md) conserva
42 test ACTIVE, quattro mutanti mirati e gli audit delle prove complete.
Restano aperti stress con thread reali, interruzioni in ogni fase, condition
coverage, misure di heap/performance, prove ACTIVE multiserie, directory della
Serie/rotazione/reclaim, indice concreto e qualifica C1.
