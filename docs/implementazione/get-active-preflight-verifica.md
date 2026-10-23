# Verifica dei rifiuti OPEN del GET ACTIVE

La campagna segue il [metodo preregistrato](get-active-preflight-metodo.md),
committato insieme ai test e al driver prima delle esecuzioni. Il freeze
locale è `8c0866711c50d047f87b9c484ce56d42a87ba19c`, sulla base
`a5715a1aa0b2571d650d1b794e9bb7b7324e951e`. Il protocollo del prodotto
rimane invariato.

I **14 nuovi test** portano la suite ACTIVE da 28 a **42 test nominali**.
Le iterazioni v1/v2 e sui confini sono casi interni degli stessi test.
Si osservano identità e versione del lotto, OPEN vuoto o con binding,
SEALED con token del caller, radici precedenti, ring pieno, generazione,
contiguità e budget di spazio, record e byte comprensivi del SEAL.

Ogni chiamata conserva byte, token e frontiere CSN, intero ring,
identità delle radici e dei grafi, offset, stato e posizioni dei file.
Il backend non osserva letture, scritture, flush o interrogazioni di identità.
I rifiuti ordinari lasciano il controller HEALTHY; CRC dell'header e count
incongruente propagano la stessa causa e portano al fail-stop di Archivio.
Le FI sono esplicite, ripristinate dopo il witness; i token reali mai
adottati vengono annullati dopo le osservazioni.

## Risultati locali

`make check` supera **1.278 test di modulo in 30 suite e due smoke check**,
oltre ai controlli statici e ai dieci spike di correttezza. La compilazione
rispetta il contratto del builder sugli avvisi. L'audit indipendente deriva
dal Git congelato conteggi e ordine, associa record esterno e interno e
verifica tutti gli **852 path/blob** prima e dopo. La cache del sistema e
dei test contiene esattamente **335 FASL privati**, letti soltanto come byte.

Le coperture usano due processi e due cache separati, ciascuna con gli
stessi 335 FASL previsti dai componenti ASDF. Nomi e ordine dei 42 test
ACTIVE e dei 42 CLOSED coincidono con il Git congelato. Stato SB-COVER,
riepiloghi e HTML coincidono per ogni file; gli inventari byte/SHA sono
stabili nei due passaggi.

| File in `src/get-resolver/` | Espressioni eseguite/totali | Rami eseguiti/totali |
|---|---:|---:|
| package.lisp | 0/1 | 0/0 |
| types.lisp | 1/29 | 0/0 |
| rows.lisp | 0/167 | 0/16 |
| read.lisp | 208/265 | 27/40 |
| active-types.lisp | 12/39 | 0/4 |
| active-directory.lisp | 145/161 | 24/28 |
| active-scan.lisp | 186/247 | 19/34 |
| active-build.lisp | 248/274 | 30/36 |
| active-preflight.lisp | 174/193 | 25/26 |
| active-read.lisp | 102/115 | 7/8 |
| **Totale ACTIVE** | **1076/1491** | **132/192** |

Il processo CLOSED mantiene **1156/1416 espressioni e 131/184 rami**,
su sette sorgenti e otto HTML. ACTIVE conserva dieci sorgenti e undici
HTML. `active-init.lisp` rimane fuori da questo profilo.

Il file preflight è identico a quello della [prima campagna](get-active-verifica.md):
i rami osservati passano da 16/26 a **25/26**. Il ramo falso di progresso
OPEN resta irraggiungibile sotto il contratto di `checked-header`, che
richiede una testata conforme e un avanzamento di almeno 24 byte.
Il limite del segmento viene provato sul solo helper locale, senza
costruire un file o una radice artificiale da 4 GiB.

## Mutanti e compatibilità del driver

Il nuovo profilo `--suite preflight` supera la baseline di tutti i 42 test
ACTIVE e rileva **quattro mutanti su quattro**. Ciascuna copia contiene
una sola sostituzione preregistrata del preflight e conserva patch,
sorgente modificato, driver, configurazione e tutti i FASL utilizzati.
Il registro completo rimane di 42 nomi in ciascuno dei cinque child;
ogni mutante esegue il singolo test previsto e già passato nella baseline.

| Modifica intenzionale | Rilevamento osservato |
|---|---|
| Omissione file-ID | Asserzione nel test di identità |
| Omissione versione | Asserzione nel test di versione |
| Esclusione SEAL dal budget | Asserzione nel test del confine dei byte |
| Rifiuto del numero esatto di record | `RESOURCE-EXHAUSTED`, package e reason `:active-batch-record-budget` esatti |

Le **109 operazioni** del nuovo profilo sono terminali e raccolte, con
sei namespace separati: parent e cinque child. I self-test sintetici
verificano 38 casi del classificatore preflight e 30 del bootstrap.
Questi dati non attestano l'iniezione di ogni possibile timeout reale.

Il default senza `--suite` conserva la baseline di **25 test e quattro
mutanti rilevati**. I mutanti selezionano quella suite e si fermano al
test previsto: i conteggi effettivi sono rispettivamente 4, 14, 25 e 1,
nell'ordine del catalogo. Il vecchio profilo mantiene il proprio contratto
di deadline cooperativo. L'audit finale verifica **3.350 FASL**, 335 per
ognuno dei dieci child, e un inventario stabile di 8.079 file.

## Conservazione e tentativi degli helper

Le raccolte complete sono separate per
[controlli e audit locali](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-get-active-preflight-core/),
[nuovo profilo](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-get-active-preflight-mutation/)
e [regressione bootstrap](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-get-active-preflight-bootstrap/).
Comprendono output originali, manifesti, configurazioni, patch, copie
isolate, tutte le cache utilizzate e le operazioni del driver.
Gli [audit di conservazione](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-get-active-preflight-audits/)
conservano separatamente contratti, sorgenti dei collector, comandi e
risultati delle verifiche sulle copie. Le copie e i controlli delle entry
usano al massimo quattro worker per invocazione, raccolti prima di
propagare un errore. Gli SHA sono calcolati a lotti dalla libreria
congelata: ciascun input deve essere regolare e non superare 16 MiB;
byte, percorsi e identità sono ricontrollati dopo il calcolo.

La compressione dei file grandi è senza perdita. Gli indici compressi
restano leggibili con il reader del repository, che verifica descriptor,
payload e impronta espansa. Report, sorgenti mutati e FASL sono dati;
gli audit non li caricano come codice.

Le due fixture CLI sono errori di uso attesi, exit 2, senza creazione
di una campagna. Il controllo completo conserva anche i quattro errori
di processo attesi dei self-test snapshot/lettura.
Sono conservati i tentativi degli helper: errore sintattico iniziale
dell'inventario Git, controlli sintattici preparatori e R1 dell'audit
mutanti fermato da un `sort` distruttivo nel verificatore. R2 supera
i controlli; R3 corregge l'etichetta del conteggio bootstrap da selezione
a esecuzione effettiva. Le campagne del prodotto rimangono quelle R1
originarie, immutate; gli esiti degli helper mantengono la propria attribuzione.
Il primo avvio dei tre collector si ferma in lettura del sorgente per una
parentesi mancante. Nella seconda esecuzione la raccolta core termina
correttamente; i collector mutation e bootstrap vengono interrotti per
il costo dei digest individuali, con esito nativo FAILED. La raccolta core
R2 viene mantenuta. Le raccolte complete mutation e bootstrap sono poi
ripetute dagli stessi produttori terminali R1 con `collector-batch.lisp`
(fonte `e6b2cdec…`); l'audit finale `audit-batch.lisp` (`d17564b3…`)
verifica tutte e tre le raccolte. La libreria comune ha fonte `130f4285…`.
Sorgenti, comandi, tentativi e controlli sintattici restano conservati.

Le due copie parziali dei collector interrotti sono conservate separatamente
come **parziali non qualificate**: due flussi USTAR opachi in quindici parti
gzip, otto mutation e sette bootstrap. Il manifesto registra ordine,
offset, dimensioni e SHA delle parti e dei TAR ricostruiti. Ogni parte
espansa è al massimo 4 MiB e ogni gzip rimane sotto 8 MiB. Elenchi canonici,
byte e hash dei file originali e degli estratti temporanei coincidono;
i TAR completi sono confrontati anche byte per byte e tramite SHA nativo,
senza sottoporli al limite di 16 MiB del digest in lotto. Non vengono
interpretati i report incompleti o caricati i FASL. Gli estratti del
tentativo riuscito sono rimossi dopo la verifica; gli originali restano intatti.

Il tentativo precedente di produrre un solo gzip si ferma al limite di
8 MiB. Il payload fallito sovradimensionato rimane fuori dalla raccolta
pubblicata, nello staging per il successivo backup integrale del worktree;
fonte, manifesti e log del tentativo sono inclusi. È conservato anche il
primo spostamento fallito prima del rename per un pathname relativo;
il successivo spostamento usa il percorso assoluto e mantiene SHA,
dimensione, device e inode. Questi esiti riguardano la conservazione e
non cambiano la qualifica delle campagne del prodotto.

## Limiti

Quattro difetti scelti e la copertura diagnostica non qualificano MC/DC
globale o C1. Restano aperti stress concorrente, interruzioni in ogni fase,
prepared/OUTCOME ACTIVE, indice concreto, rotazione/reclaim e motore completo.
La campagna non misura throughput, latenza, RSS o allocazioni. I numeri
locali appartengono al freeze indicato; la CI qualifica i propri commit nativi.
