# Lifetime delle fonti GET: metodo della verifica integrata

Questo metodo precede le esecuzioni dell'incremento. Verifica il ponte
[fonti della Serie](get-fonti-serie.md) con le API GET, WAL, primary ed EBR
esistenti, FD nativi e worker distinti. Non introduce codice di prodotto,
formati o un esecutore di compaction/rotazione.

## Autorità e perimetro

Ogni caso usa una sola chiave CLOSED iniziale, un controller ACTIVE
ordinario, contesti privati e nessuno snapshot registrato. Le radici nuove
sono pubblicate da lotti reali attraverso `pubblica-commit-serie`; le
location correnti cambiano attraverso l'API pubblica del primary.
Un nuovo PUT della stessa chiave ha un nuovo CSN: è una sostituzione della
versione corrente, non la rilocazione fisica di una versione invariata.

La fixture mantiene valide le mappe native fino alla chiusura. La decisione
durabile del catalogo e la retention MVCC sono precondizioni del caller,
non conclusioni di questa prova. I file temporanei sono rimossi soltanto
nel cleanup esclusivo finale; il reclaim osservato chiude il FD e libera
il ticket, senza attestare una rimozione durabile del segmento.

L'obbligo `L ⊆ S(R)` vale a ogni acquisizione: il primo aggiornamento
conserva CLOSED e ACTIVE insieme. La riduzione della directory avviene
soltanto quando la vecchia location non è più nel primary corrente e
l'unico vecchio reader ha già acquisito la capacità nel medesimo compito
di lettura. Nessun nuovo lookup può allora copiare quella location.
EBR protegge la capacità catturata, senza rendere risolvibile una mappa
rimossa prima dell'acquisizione.

## Casi e oracoli preregistrati

Quattro test registrati, ciascuno nei formati v1/v2. Il primo impone
serialmente l'ordine lookup/pubblicazione/acquisizione; gli altri tre
usano un worker I/O distinto dal writer:

1. Un GET copia il candidato CLOSED; il writer pubblica un superset ACTIVE.
   L'acquisizione successiva risolve ancora il candidato e legge i byte
   attesi dal file nativo.
2. Un GET si ferma nell'hook della lettura nativa, dopo l'acquisizione.
   Il writer prenota il ritiro prima delle modifiche logiche, pubblica
   prima il superset, sostituisce la location corrente e poi pubblica
   fonti ridotte. Il ritiro pubblicato non è acquisibile con il vecchio
   pin attivo. Dopo lettura, copia e conclusione, il claim riesce,
   una sola chiusura nativa avviene e il credito torna libero. Un GET
   successivo verifica la nuova location ACTIVE e il valore atteso.
3. Lo stesso ordine con una condizione tipizzata nell'hook nativo:
   causa originale, output intatto e pin liberato prima del cleanup
   esterno; poi il reclaim può completare.
4. Lo stesso ordine con uscita non locale: cleanup interno del GET,
   output intatto e pin liberato prima del cleanup esterno; poi reclaim.

Gli oracoli confrontano input indipendenti, CSN/location del candidato,
sentinelle del buffer, eventi I/O, stato FD, ticket, pin e crediti EBR.
Le chiusure effettive sono osservate nel backend della fixture sotto
mutex. Non si sostituiscono funzioni globali con worker in volo.
Gate e timeout sono strumenti C4 per imporre l'interleaving, non attese
aggiunte al prodotto; il worker I/O conserva il pin durante la syscall.
Tutti i worker devono terminare prima di mutare contesti o chiudere FD
dal controller. Timeout o mancato join falliscono il caso.

## Esecuzioni e conservazione

Sorgenti, registrazione ASDF e metodo sono congelati in un commit prima
delle campagne. Compilazione senza warning, suite completa e controlli
del repository passano attraverso `tools/record-command.lisp`/`make check`.
La selezione ACTIVE preesistente resta invariata; questo incremento non
richiede di ripetere la sua campagna di mutazione senza cambiamenti del
prodotto o del driver. Una lettura indipendente verifica il protocollo e
gli esiti grezzi; la CI verifica anche Linux.

Output originali, errori eventualmente osservati, configurazioni e FASL
privati sono conservati prima della pulizia. Report ed evidenze sono dati:
lettura con `*read-eval* NIL` ed EOF, mai `LOAD`. La copia delle prove viene
verificata integralmente prima della pubblicazione. Esiti e identità dei
run saranno riportati nel catalogo della campagna dopo la verifica.

Requisiti: REQ-IDX-001, REQ-WAL-006, REQ-CMP-007, REQ-AFF-001,
REQ-AFF-008 e REQ-VAL-001. Questa verifica funzionale non qualifica
prestazioni, zero heap, C1 o MC/DC globale.
