# Risultati del contesto worker dei writer

Campagne del 2026-10-09 sulla base `cf60913`, con sorgenti congelati dopo
la prima lettura C1. Contratto in [writer-worker](writer-worker.md),
[metodo preregistrato](writer-worker-metodo.md),
[inventario completo](writer-worker-decisioni.md) e
[catalogo dei dati conservati](../../spikes/results/2026-10-09-writer-worker/catalogo.lisp).
Le qualificazioni riguardano questa composizione locale, non il pool completo.

## Correttezza e integrazione

Il processo `4000547204-command-93189-0` termina OK/STABLE/exit0:
387 test più smoke, compilazione senza warning o style-warning, lint su
63 file con zero violazioni, tracciabilità di 114 requisiti/65 invarianti/
13 scenari FI/52 ADR senza errori, 221 documenti e 2007 link senza rotture,
self-test della conservazione, verifica delle evidenze e dieci spike.
Il [record completo](../../spikes/results/2026-10-09-writer-worker/check-finale-processo.lisp)
conserva anche i rifiuti intenzionali delle fixture negative dei tool.

I test execution sono 89, di cui 23 nuovi. L'oracolo a liste indipendenti
esegue 8000 passi su otto combinazioni K1/4, capacità ready1/2 e quantum1/2,
13 writer, drain finale e uguaglianza payload accettati/consegnati.
Le fixture verificano quote cumulative, FIFO, buffer/sentinelle, home/cursor,
ack stale, busy con snapshot, latch finishing, ricircolo room/full,
adozione/cessione senza lease attive, overflow senza wrap e fault persistenti.
La regressione not-ready conserva la condizione originale e impedisce al
vecchio contesto di consumare una nuova ondata.

Una prova riusa quattro thread su sei ondate, con produttori vivi e 36
payload controllati mediante CRC, verificando progresso su uno shard mentre
un altro è occupato. Un'altra riusa due contesti proprietari concorrenti
su otto ondate, con un solo vincitore per obbligo. Queste prove non attestano
fairness, wake/park, shutdown o migrazione delle lease tra thread.

## Integrazione della base aggiornata

Dopo queste campagne la primaria integra l’inventario recovery in `e2f7a75`.
Il controllo distinto `4000548048-command-40192-0` è OK/STABLE/exit0:
400 test più smoke (execution89, recovery95), lint66/zero, tracciabilità
114/65/13/52 senza errori, 224 documenti/2017 link senza rotture e dieci spike.
Il [record integrato](../../spikes/results/2026-10-09-writer-worker/check-integrazione-processo.lisp)
e il [catalogo dei suoi spike](../../spikes/results/2026-10-09-writer-worker-integration/catalogo.lisp)
conservano il nuovo gate. Lo scope `4000548017-command-37007-0` confronta
i byte execution, test e tool worker con la copia qualificata: invariati;
ASDF e indice incorporano anche l’inventario. Le campagne worker già concluse
non sono rieseguite per cambiamenti della recovery indipendente. I due
master conservano i rispettivi descriptor/payload originali in directory
distinte, evitando collisioni dei nomi gzip. I documenti conclusivi sono
controllati separatamente dalla compilazione dei sorgenti congelati.

## Mutazioni e qualità degli strumenti

I due C4 sono compilati integralmente con COMPILE-FILE e self-test eseguiti
dai FASL, con avvisi fatali: `4000547221-command-94073-0` e
`4000547221-command-94074-0`, entrambi OK/STABLE/exit0. L'adapter conservato
ha un marker finale editoriale ereditato `RECYCLE-TOOL-STRICT-SELF-TEST-PASS`;
argv, sorgente compilata e risultati identificano esplicitamente worker.

La [campagna di mutazione](../../spikes/results/2026-10-09-writer-worker/mutazioni-dati.lisp)
`4000547268-command-97067-0` completa la baseline di 89 test e rileva
12/12 mutanti preregistrati. Ogni mutante ha exit1, segnale NIL e un vero
marker di avvio dei test; zero survived, compilation-failure, before-tests
o worker-error. Tutti i tredici log sono conservati con i bersagli esatti.

Il [catalogo del probe di revisione](../../spikes/results/2026-10-09-writer-worker-review/catalogo.lisp)
conserva separatamente il grande record processuale originale, con il
payload gzip originale. L’audit integrale e la sua proiezione compatta
sono entrambi conservati; il fallimento iniziale dell’adapter di proiezione
è dichiarato nell’inventario e non attribuito al prodotto.

La fixture OS separata usa SIGKILL reale: segnale9/exit137, classificazione
worker-error e detected0. Completamento autentico seguito da exit nonzero,
marker citati, warning/compilation failure, report parziali e destinazioni
preesistenti sono controllati dai self-test e non promossi a detection.

## Allocazione del percorso composto

La [campagna di allocazione](../../spikes/results/2026-10-09-writer-worker/allocazioni-dati.lisp)
`4000547268-command-97066-0` è OK/STABLE/exit0. Un contesto creato sul thread
proprietario, writer, ready ring e buffer sono preallocati. Ogni ciclo
compone enqueue, publish, claim, begin, pop/ack, end e recycle full/room;
identità dei writer, count/status/cursor e generazioni persistenti sono
verificati. Ruota il ruolo iniziale fra C+1 writer distinti per shard.

| Shard K | Capacità C | Chiamate/ciclo | Token | Sink per replica | Campioni completi | Heap osservato |
|---|---|---|---|---|---|---|
| 1 | 1 | 35 | 578 | 10754048 | 5 × 4096 cicli | 0 byte |
| 1 | 3 | 49 | 858 | 11900928 | 5 × 4096 cicli | 0 byte |
| 4 | 1 | 137 | 2520 | 18708480 | 5 × 4096 cicli | 0 byte |
| 4 | 3 | 193 | 4084 | 25114624 | 5 × 4096 cicli | 0 byte |

Warmup128 e GC fuori misura; controllo positivo 16777472 byte allocati,
baseline contatore zero, sink errato respinto e clockzero distinto da una
durata valida. La formula del metodo è ricalcolata rispetto alle operazioni
del driver. Tutti i tempi e campioni raw restano nei dati; carico esterno
non controllato, nessuna promessa di speedup, throughput, P99 o heapzero
universale. Startup ed errori sono fuori dal percorso normale misurato.
Il benchmark composto usa un worker; il parallelismo funzionale è verificato
dalle fixture con thread reali, non da una misura di scalabilità.

## Copertura e limiti

Copertura `4000547204-command-93188-0`, export
`4000547249-command-95826-0`, audit indipendente native/HTML/export
`4000547296-command-98426-0`: 1427/1660 espressioni e 199/230 esiti
su tutti gli undici file execution. I quattro nuovi file hanno 498/600
espressioni e 65/76 esiti. Le 233 espressioni e 31 alternative non marcate,
comprese quelle legacy, restano nel denominatore e nell'inventario.
Nessuna esclusione approvata o MC/DC dedotta da sb-cover; il gate C1 del
motore rimane aperto.

Il confine locale faulted è terminale e diagnostico: non realizza ancora
il controller FAULTED della Serie o il rilascio delle risorse dopo un fault.
Ack attesta il caller, senza verificare effetti WAL esterni. Catene full
rimangono sullo stesso shard; quote globali, admission, pool adattivo,
wakeup/park/shutdown e integrazione durevole restano lavoro successivo.
Empty è soltanto un'osservazione locale. Il probe iniziale
`4000545928-command-51771-0` è conservato come sviluppo precedente al codice
finale e non viene usato per qualificarlo.

## Conservazione finale delle evidenze

Il primo adapter di pubblicazione (`4000548817-command-74667-0`) ha respinto
una copia identica: confrontava con EQUALP oggetti riletti che contengono
simboli non internati. Il confronto corretto verifica byte originali e
decompressi, SHA256 e Git blob, con lettura validata e senza overwrite.
L’audit distinto `4000549512-command-14958-0` conserva quattordici fixture
positive/negative e il confronto di 46 copie canoniche, tutti passati.
Il marker finale dell’audit stampa un conteggio cosmetico errato; il report
contiene quindici risultati, verificati da `4000549715-command-34672-0`.
È conservato anche il tentativo iniziale dell’audit
`4000549424-command-9085-0`, fermato dal percorso relativo del payload
nella preparazione della fixture, senza coinvolgere il codice worker.

La ripresa `4000549781-command-39344-0` completa 69 coppie e cinque bundle,
poi esaurisce il limite heap predefinito del reader durante il catalogo
integrato. Le copie già valide rimangono originali. La sola chiusura usa
un limite heap di 4096 MiB e verifica nuovamente i file esistenti.
Questi tentativi riguardano la conservazione; i loro report e adapter
restano nei cataloghi e non qualificano la correttezza del prodotto.

## Verifica della consegna con il codec aggiornato

La base finale `e07d772` incorpora il controllo delle testate CBOR minime
pubblicato da un’altra chat. L’integrazione congelata esegue un solo nuovo
controllo completo, `4000550386-command-90070-0`: OK/STABLE/exit0, 415 test
più smoke su undici suite, nessun warning/style-warning, lint68/zero,
tracciabilità114/65/13/52 senza errori, 232 documenti/2044 link senza rotture,
self-test delle evidenze e dieci spike. I byte di execution, test e strumenti
worker rimangono quelli delle campagne qualificate; ASDF e indice conservano
sia i worker sia le aggiunte recovery e CBOR della primaria.

Il [record finale integrato](../../spikes/results/2026-10-09-writer-worker/check-consegna-processo.lisp)
e il [catalogo dei suoi spike](../../spikes/results/2026-10-09-writer-worker-final-integration/catalogo.lisp)
conservano gli originali. Cache di compilazione privata e limite heap
4096 MiB sono espliciti nell’argv; questo limite riguarda i processi di
verifica/conservazione. Il nuovo gate non estende le promesse delle misure
worker a throughput, latenza o scalabilità. La consegna mantiene tutte le
campagne precedenti e chiude separatamente i link e i cataloghi conclusivi.

La proiezione readonly finale conserva il tentativo
`4000550586-command-9874-0`, respinto da un’asserzione dell’adapter che
accettava soltanto il marker OK. SPK-07 usa il marker PASS, con exit0 e
sorgenti stabili. La proiezione corretta `4000550696-command-14941-0`
verifica i risultati effettivi e termina OK/STABLE/exit0; il controllo
completo non è stato ripetuto e nessun sorgente del prodotto è cambiato.

L’addendum C1 `4000550907-command-25363-0` è OK/STABLE/exit0:
venti file execution/test/tool identici, 3517 blob upstream conservati,
ASDF e indice con i soli inserimenti worker, 101 copie storiche integre.
I tre reader precedenti sono conservati: alias macOS var/private-var,
documento WT avanzato rispetto alla copia storica e differenza tra argv
make check e il reale env/make check-core. Le correzioni riguardano il reader;
non sono nuove prove del prodotto e non alterano i dati originari.
La consegna è sul ramo `codex/writer-worker` con base qualificata `e07d772`;
la primaria continua indipendentemente con le modifiche delle altre chat.

Il tentativo finale di conservazione `4000551045-command-31231-0` è
preservato: un helper del driver non era stato caricato. La ripresa definisce
il solo risolutore dei nomi flat e verifica le copie già presenti senza
sovrascriverle; non modifica il codice worker o i risultati delle campagne.
