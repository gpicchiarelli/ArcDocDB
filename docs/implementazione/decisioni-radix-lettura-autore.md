# Prima lettura C1 dell'autore sul diff integrato

Lettura del 2026-10-09 dell'agente `/root/segment_header_code`, autore
dell'algoritmo radix. Esito dell'ispezione: nessun difetto funzionale
individuato nell'integrazione delimitata qui. Questo addendum completa la
[prima lettura del candidato](decisioni-radix-revisione.md#prima-lettura-c1-dellautore-sul-candidato-preliminare)
senza sostituire la seconda lettura indipendente o attestare una qualifica
del motore completo.

## Contenuti riletti e confini

Gli hash SHA256 seguenti sono stati ricontrollati dopo il congelamento
dei 18 test. Identificano contenuti, non commit Git.

| File | SHA256 |
|---|---|
| [`src/recovery/decisions-radix.lisp`](../../src/recovery/decisions-radix.lisp) | `564becba75721f15317b260b9a949eba716e682a9062c4e009d5463040c21e54` |
| [`src/recovery/decisions-build.lisp`](../../src/recovery/decisions-build.lisp) | `be292ec655087a229a1630179876da9e302a6121985ec3141a5e35226885a115` |
| [`tests/recovery/decisions-radix.lisp`](../../tests/recovery/decisions-radix.lisp) | `75296b2de5620afd4f67117445197cb227adb4b9f65203e299ef6a4ee79518c0` |

Il confronto con il candidato congelato
`5093e1dda2876d3b31fd5a6e9196dc76bec04aa8a61ce933c63de59f73f36505`
mostra soltanto il commento iniziale aggiornato, due costanti e due
wrapper aggiunti: gli otto corpi dell'algoritmo restano invariati.
Il builder differisce dalla baseline solo nelle due chiamate ai sorter;
la firma pubblica di `ricostruisci-decisioni` e i suoi valori restituiti
restano invariati. Le registrazioni recovery osservate in
[`arcdocdb.asd`](../../arcdocdb.asd) rispettano l'ordine
`decisions-sort` → `decisions-radix` → `decisions-build`, con
`decisions-radix` fra i test recovery. La lettura riguarda queste
registrazioni, non le altre modifiche concorrenti all'ASD o ai moduli.

`sort-recovery-participants` sceglie merge per `count < 1024` e radix
per `count >= 1024`: il conteggio è quello dei partecipanti del singolo
record, non il totale del log. `sort-recovery-entries` sceglie merge
per meno di 256 entry e radix da 256 incluse. Questa cardinalità conta
le DECISION fisiche, inclusi i duplicati, prima di `collapse-decisions`;
non conta i soli TXID unici. Entrambi i wrapper mantengono i tipi
completi e delegano le precondizioni e i controlli finali ai sorter.

## Scelta misurata e rilettura dei dati

Il [metodo](decisioni-radix-metodo.md) e i
[risultati](decisioni-radix-risultati.md) separano le soglie ID16/TXID e
richiedono rapporto delle mediane radix/merge al massimo 0,90 in tutti
gli scenari misurati con `N >= soglia`. L'autore ha riletto i plists
conservati della matrice a 100 ms con `*read-eval* = nil`, senza `load`
dei dati o nuove misure, e ricalcolato le mediane dai campioni grezzi.

Sono presenti 63 campagne e 63 scenari di selezione. Nei suffissi
adottati, tutte le calibrazioni raggiungono 100 ms e tutti i tre
campioni per algoritmo raggiungono almeno 50 ms con flag di usabilità:
16 scenari ID16 da 1.024 elementi hanno rapporti
`0,131160..0,857956`; 25 scenari TXID da 256 entry hanno rapporti
`0,143755..0,759877`. I rapporti ricalcolati coincidono con la selezione
conservata entro `1e-12`; il processo registrato termina con codice zero
e consistenza delle sorgenti stabile. La prima matrice insufficiente
resta distinta e conservata. Questi riscontri riguardano solo il costo
locale dell'ordinamento, con allocazioni e GC inclusi, sul sistema
misurato: non qualificano P99, zero heap, Linux/x86-64 o il motore.

## Lista di controllo C1 sul percorso adottato

La lista segue i dodici punti dello
[standard di codifica](../affidabilita/standard-di-codifica.md).
L'[inventario](decisioni-radix-decisioni.md) e la
[seconda lettura](decisioni-radix-revisione.md) restano documenti
separati; la presente lettura non anticipa gli esiti delle campagne
finali di copertura e mutazione.

| Punto C1 | Riscontro dell'autore sull'integrazione e limite |
|---|---|
| 1. Requisiti e ADR | I wrapper riportano REQ-TXM-005, REQ-AFF-008 e REQ-VAL-001; quello delle entry anche REQ-TXM-001. Le costanti richiamano REQ-BEN-001. La scelta segue il metodo misurato e preserva il contratto DECISION, in coerenza locale con ADR-0034/0035. Nessun nuovo vincolo su TXID/CSN o formato persistente. |
| 2. Invarianti e test | I controlli di somma, prefisso, posizione, consumo e ordine del radix sono invariati. I test pubblici `public-participant-sort-threshold-boundaries` e `public-entry-sort-threshold-boundaries` esercitano entrambi i lati e l'uguaglianza delle soglie; il test `public-radix-first-physical-conflict-across-groups` verifica l'offset fisico globale, anche se il gruppo numericamente minore viene visitato prima. |
| 3. Errori e gestione | I wrapper non intercettano né trasformano gli errori. Misure/count incoerenti, duplicati di partecipante e conflitti mantengono i controlli delegati; sei test negativi chiamano inoltre le guardie interne per istogramma, oggetto, cifra, array e cursori. Errori di tipo/allocazione del runtime e transizione della Serie a FAULTED restano esterni al sorter. |
| 4. Cicli e attese | Il dispatch aggiunge solo due confronti e chiamate. Restano i limiti di 16/8 passate, 256 classi e N elementi effettivi; nessun ciclo o attesa nuovi. Le attese finite dei sei lettori appartengono alla fixture e non al worker del prodotto. |
| 5. Allocazioni e percorso caldo | Il wrapper non prepara altro workspace; il sorter scelto alloca sul percorso di costruzione/apertura. Scratch e istogramma dipendono dai dati effettivi, non dai budget inutilizzati; anche count 0/1 privati possono allocare. Nessuna promessa o misura zero heap per query o runtime. |
| 6. Dati verificati | Il budget del numero di DECISION precede l'allocazione delle entry; il preflight dei payload e del totale partecipanti precede le copie. `decode-decisions` passa al wrapper una copia ID16 e l'offset assoluto; il wrapper delle entry riceve il vettore privato completo prima del controllo conflitti e della tabella. Nessun risultato parziale viene pubblicato e il buffer del log resta invariato. |
| 7. Decisioni composte | Il diff aggiunge due `if` semplici sui conteggi, senza nuovi predicati booleani composti. I confini sono 1023/1024/1025 e 255/256/257; la soglia stessa percorre radix. Le guardie composte dell'algoritmo restano quelle inventariate. Copertura grezza e criteri C1 finali richiedono i rapporti sul diff adottato. |
| 8. Proprietario e condivisione | I wrapper mantengono l'ownership della costruzione e non esportano vettori. I sorter riordinano soltanto copie private; le entry e la tabella pubblica conservano campi read-only. I test ai confini confrontano anche il log prima/dopo; quello concorrente consulta una tabella già completa dopo la sovrascrittura del log originale. |
| 9. Trace, compilazione, lint e check | I due nuovi wrapper hanno `ftype`, docstring pre/post/errori, REQ e `safety 3` del file; sono entro 60 righe. È stato riletto il log della baseline isolata del revisore: marker `decision-tests-complete 43` con gli ultimi tre test pubblici verdi; il revisore riferisce compilazione rigorosa senza warning. L'autore non ha rieseguito processi pesanti. Trace, lint, `make check`, copertura e mutanti finali sono evidenze distinte da questa lettura. |
| 10. Deviazioni | Nessuna deroga individuata nel diff delimitato. Le soglie sono scelte locali misurate, non limiti di formato; i budget esistenti e le guardie restano attivi. Non viene approvata alcuna esclusione di copertura o estensione delle misure ad altri sistemi. |
| 11. Parallelismo fra Serie | Nessun nuovo lock, parcheggio, pool o store condiviso per operazione della Serie: il lavoro aggiunto riguarda il workspace posseduto del recovery. Le query pubbliche restano scalari e prive di scritture nella tabella. Sei lettori reali verificano risposte/ownership, non isolamento, scheduler o scalabilità del motore rispetto a INV-P6. |
| 12. Atomicità e rimozioni | Il diff non introduce I/O, flush, pubblicazione, applicazione di prepared, eliminazioni o punti di atomicità durevoli. Scanner e protocollo di durability mantengono il proprio contratto, senza essere riqualificati dall'ordinamento adattivo. |

## Regressioni pubbliche e limiti della lettura

I test congelati coprono versione 1 e 2, offset assoluti oltre u32 e
nessuna modifica del log. Per 1023/1024/1025 partecipanti confrontano
DECISION duplicate con lo stesso insieme in ordine inverso, su tre
pattern; per 255/256/257 entry usano TXID distinti e N record duplicati
che producono un solo TXID. Il conflitto globale usa 258 record in tre
lotti, con primo record discordante nel gruppo TXID massimo e un
conflitto successivo nel gruppo zero; l'errore viene verificato due
volte sullo stesso buffer stabile. Gli oracoli privati rimangono
indipendenti dal merge e dal radix e confrontano byte completi e
identità delle entry.

Questa lettura non approva modifiche degli altri moduli o qualificazioni
di rilascio. Le prove finali di integrazione, le metriche grezze di
copertura e mutazione e i relativi tentativi falliti devono essere
conservati sugli stessi hash. Non si promuovono gli spike a runtime e
non si attribuisce a questo lavoro la completa applicazione del
recovery, l'implementazione del pool o la scalabilità fra Serie.
