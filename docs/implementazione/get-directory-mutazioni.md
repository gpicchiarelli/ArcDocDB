# Mutazioni della directory GET CLOSED

<!-- REQ: REQ-IDX-001 REQ-CMP-007 REQ-AFF-002 REQ-AFF-008 REQ-VAL-001 -->

Il driver [get-directory-mutation.lisp](../../tools/get-directory-mutation.lisp)
preregistra cinque mutanti semantici della costruzione e selezione della directory.
La preparazione è stata esclusivamente statica: nessuna compilazione, caricamento
del prodotto, esecuzione della suite, self-test o campagna è stata effettuata
dall'autore di questi due file. Il padre congela i sorgenti e registra ogni
esecuzione successiva. Questa pagina descrive metodo e risultati richiesti;
non attesta risultati già ottenuti.

## Scope e contratto

Si possono modificare nelle copie private soltanto
`src/get-directory/build.lisp` e `src/get-directory/read.lisp`. Il resolver CLOSED
e il nucleo GET preesistenti sono dipendenze compilate, senza mutazioni.
Non si include il resolver ACTIVE, né si aggiungono pubblicazione, celle condivise
o CAS. La directory deve essere acquisita dal controller dopo `avvia-get`,
nella stessa epoca EBR del candidato; pubblicazione, FD e reclaim rimangono al
controller. Il contratto completo è in [get-directory.md](get-directory.md).

La suite usa il package `arcdocdb.get.directory.tests` e il registro
`*get-directory-tests*`. Si compila e si esegue soltanto la suite directory:
`support.lisp`, `construction.lisp`, `read.lisp`, `threads.lisp`. Prima si
compila `tests/foundation/support.lisp`, per importare gli oracoli di asserzione;
non si eseguono test delle fondazioni. `arcdocdb/tests` non viene caricato e
le altre suite non vengono copiate. Tutti i sorgenti del prodotto e
`arcdocdb.asd` sono invece copiati; ASDF carica il solo sistema `arcdocdb` con
compilazione forzata. Il metodo non è una misura del solo prodotto.

Il dominio della directory rimane 0–65.536 segmenti, ID positivi u32 ordinati,
al massimo 17 passi di ricerca e payload degli array di `12*N` byte su SBCL64.
Header, mappe e FD non entrano in quel payload. La campagna non misura memoria,
latenza o throughput; i limiti geometrici sono osservazioni dei test.

## Mutanti preregistrati

Ogni mutante sostituisce una sola occorrenza letterale di un anchor. Anchor
assente, duplicato o test nominato assente impediscono l'avvio della baseline.
Le stringhe multilinea contengono newline reali. Nessun anchor viene cercato
per somiglianza, né aggiornato automaticamente dopo il freeze.

| Mutante | Bersaglio | Test esatto | Difetto e osservazione attesa |
| --- | --- | --- | --- |
| `omit-directory-owner` | `src/get-directory/build.lisp` | `TEST-REQ-CMP-007-DIRECTORY-CANONICAL-OWNER-AND-FOREIGN-OWNER` | La guardia `(unless (eq view (segmento-get-owner segment))` diventa `(unless (or (eq view (segmento-get-owner segment)) view)`. La vista canonica, sempre vera come oggetto, fa accettare una vista estranea: l'asserzione sul rifiuto `invalid-argument :directory-source-owner` deve fallire. Il riferimento a `view` è conservato. |
| `missing-location-first-map` | `src/get-directory/read.lisp` | `TEST-REQ-IDX-001-DIRECTORY-MISSING-PUBLISHED-CANDIDATE-FAILSTOP` | A intervallo esaurito, una directory non vuota restituisce la prima mappa. La directory vuota conserva il guasto originario, così il test raggiunge anche il candidato pubblicato nel gap. Deve fallire l'asserzione sul guasto `:directory-location-absent`; nessuna falsa assenza è ammessa. |
| `alias-input-maps` | `src/get-directory/build.lisp` | `TEST-REQ-IDX-001-DIRECTORY-INPUT-ARRAY-COPIED` | `(owned (copy-seq maps))` diventa `(owned maps)`. Dopo `fill` dell'input a `nil`, la directory perde le mappe. Il successo atteso dal test è sostituito da `invariant-violation :directory-shape`, con GET FAULTED. |
| `truncate-directory-id` | `src/get-directory/read.lisp` | `TEST-REQ-IDX-001-DIRECTORY-NATIVE-READ-V1-V2-VALUES-AND-MAXID` | `(ldb (byte 32 32) location)` diventa `(ldb (byte 31 32) location)`. Il candidato con ID `#xffffffff` viene cercato come `#x7fffffff` e rifiutato, invece di selezionare e leggere il segmento esatto. |
| `bypass-closed-resolver` | `src/get-directory/read.lisp` | `TEST-REQ-IDX-001-DIRECTORY-CANDIDATE-SIZE-AND-HIGHBITS` | `risolvi-candidato-directory-get` seleziona la mappa e restituisce segmento, frontiera, `0`, `nil` direttamente. Deve fallire l'asserzione sul controllo CLOSED della size del candidato. L'anchor interessa soltanto questo wrapper della directory. |

Il mutante alias dipende dalla guardia di tipo della mappa selezionata, introdotta
dal padre in `cerca-mappa-directory-get`: una voce diversa da
`mappa-segmento-get` deve chiamare `guasto-get :directory-shape` prima del
ritorno. Senza quella guardia, il test potrebbe generare un `TYPE-ERROR` CL:
il classificatore lo tratta come infrastruttura e **non** come kill. Il
preflight non certifica questa guardia tramite un anchor aggiuntivo; la sua
presenza deve essere confermata staticamente prima del freeze.

Il mutante di delega elimina anche i controlli CSN, FD e prova dal wrapper
`risolvi-candidato-directory-get`, ma il test preregistrato testimonia il
controllo size, a partire dal primo caso errato. Non si rivendica un kill
indipendente per ogni altro controllo, né per i wrapper cache/lettura che
continuano a delegare al resolver originale. La baseline include comunque i
test dedicati a CSN basso/alto, FD, prepared e cleanup.

## Isolamento e attestazioni

`--check` richiede una directory di output nuova e acquisita esclusivamente.
La baseline riceve copie dei byte dei sorgenti congelati. Prima e dopo la copia
si confrontano le impronte originali; tutte le altre copie derivano dalla
baseline verificata. Un mutante deve cambiare esattamente il file preregistrato,
mentre ogni altro sorgente e ogni file della suite devono rimanere identici.

Ogni copia viene eseguita in un processo SBCL nuovo, senza init utente o
di sistema, con source registry ASDF locale e output translations private
sotto `fasl/`. I file di suite hanno anch'essi output espliciti privati. Una
compilazione con warning, salvo redefinition warning, o con indicatore di
fallimento non è una compilazione utile alla campagna.

Il child attesta il manifest completo dei sorgenti con MD5, i FASL di ogni
sorgente prodotto, i cinque FASL della suite/supporto e il bersaglio compilato.
Ogni voce contiene ruolo, percorso sorgente, MD5 sorgente, percorso assoluto
FASL e MD5 FASL. Le liste devono corrispondere esattamente al manifest previsto:
mancanze, duplicati, ordine diverso, output fuori dalla directory privata e
digest diversi invalidano il risultato. Non basta attestare il solo bersaglio.

Il supervisor ricalcola dopo il child i digest dei sorgenti, del runner generato
e dei FASL su disco e controlla i loro percorsi reali. Il registro dei test deve
corrispondere esattamente ai `deftest` letterali congelati e ogni nome deve
contenere `REQ-`. MD5 è usato per attestare identità dei byte nel metodo locale
ereditato da `get-performance-mutation.lisp`; non è un'attestazione crittografica
contro un child ostile o contro alterazioni coordinate di sorgenti e rapporti.

Prima dei mutanti, la baseline deve compilare prodotto e suite e completare
tutti i test directory nell'ordine congelato. In caso contrario non viene
lanciato alcun mutante e rimangono registrati gli esiti `:not-run`. Ogni
mutante esegue soltanto il test nominato, in una nuova copia con fixture proprie;
non eredita cache, FD, snapshot, pin o risultati dalla baseline.

## Classificazione C4 e self-test

Il rapporto principale e quelli delle copie sono plist con `:schema-version 1`,
`:kind` e `:status`. Il parser del rapporto child accetta una sola plist, con
chiavi keyword uniche, marker al primo livello ed EOF dopo i dati. Disabilita
read-eval, reader label, feature conditional, costruzione di array/strutture e
gli altri dispatch incompatibili con i dati del rapporto. Il testo è limitato
a 16 Mi caratteri; log o marker citati non sono rapporti.

Un kill (`:detected`) richiede insieme attestazioni valide, exit code 1,
fase `:tests`, stato `:failed`, nessun altro test superato e nome del test
fallito esattamente uguale a quello preregistrato. Il tipo del fallimento rimane
distinto: `:assertion` riconosce il formato dell'oracolo `is`, mentre
`:product-condition` riconosce le condizioni `arcdocdb-error`, escluso `io-fault`.
La reason effettiva e il tipo della condizione sono conservati nella diagnostica;
`:expected-failure` descrive il difetto atteso, senza effettuare matching sul log.

Timeout, crash/segnali, errori I/O, fixture, errori CL generici e child
illeggibili sono `:infrastructure-error`. Gli errori in `:compile-product` o
`:compile-suite` sono `:compilation-error`. Attestazioni insufficienti,
test diverso, dati malformati o combinazioni incoerenti sono `:invalid`.
Un successo del test nominato è `:survived`. Nessuna di queste categorie conta
come kill. La baseline distingue `:baseline-passed` e `:baseline-failed`.

`--self-test` esamina soltanto dati sintetici e non carica prodotto o suite,
non compila e non avvia processi. Copre sostituzione unica e anchor negativi,
parser positivo/negativo, asserzione e condizione prodotto, baseline, sopravvivenza,
compilazione, timeout, segnali, fixture/infrastruttura, test sbagliato, digest
sbagliati, FASL fuori copia, coverage incompleta di prodotto o suite e campi
malformati. I contatori sono verificati sia con gli esiti del classificatore,
sia con una fixture di tutte le categorie, inclusi `:pending` e `:not-run`.
Questo self-test prepara controlli del sensore; non testimonia compilabilità
o correttezza dei cinque mutanti reali.

## Budget e registri parziali

Il budget operativo totale è 900 secondi dall'avvio del driver, comprendendo
preflight, copie, compilazioni e test. Ogni processo ha al massimo 120 secondi,
ridotti dal budget residuo, con due secondi riservati al cleanup. Il child
ancora vivo viene terminato; il supervisor attende la morte con polling
bounded per al massimo due secondi. Chiama `wait-process` soltanto dopo aver
osservato la morte. Cleanup non riuscito o processo non recuperato non possono
produrre un kill e impediscono l'avvio dei mutanti successivi. La persistenza conclusiva e il confronto delle impronte
avvengono anche dopo un timeout, fuori dalla finestra operativa. Il rapporto
misura anche il tempo conclusivo: un totale oltre 900 secondi rende comunque
la campagna fallita, anche se tutti i mutanti sono stati rilevati.

Il driver salva il rapporto iniziale, il piano completo, ciascuna copia prima
di copiarne i sorgenti, le attestazioni prima del lancio, lo stato del processo,
il cleanup e ogni risultato. Aggiorna `report.lisp` tramite un file pending
e rename. Se viene interrotto, rimangono i checkpoint più recenti, i file pending
e i log già scritti. Errori gestibili producono sempre un rapporto finale anche
su stdout; un errore del filesystem o l'impossibilità di acquisire la directory
nuova può impedire la copia su disco, ed è diagnosticato su stdout. Non si
promette un rapporto finale dopo SIGKILL del supervisor o perdita del sistema.

Sotto `raw/isolatedtests/` si conservano rapporti, `stdout.log`, `stderr.log`,
runner generato e, per ogni mutante, `original-source.lisp`,
`mutated-source.lisp`, `mutation.patch`, sorgenti e FASL. Il collector C4 del
padre deve trattare runner e patch/sorgenti conservati come raw e non come
rapporti; deve escludere le sottodirectory `src`, `tests`, `fasl` dalla scansione
dei rapporti, come nel pattern performance. I record del piano espongono
`:directory` e `:file` anche se una copia fallisce prima del child.

Il rapporto conclusivo conserva le impronte della workspace prima/dopo,
contatori separati e risultati mancanti. Per exit code 0 occorrono baseline
superata, cinque kill e sorgenti stabili. Ogni compilazione/infrastruttura
fallita, esito invalido, sopravvissuto o sorgente modificato dà exit code 1.
Non si cancellano copie, log o fallimenti parziali; i sorgenti della workspace
e la cache ASDF condivisa non vengono modificati dal driver.

## Esecuzioni riservate al padre

Questi comandi sono istruzioni per la fase successiva al freeze e **non sono
stati eseguiti** durante la preparazione:

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- \
  sbcl --noinform --no-userinit --no-sysinit --script tools/get-directory-mutation.lisp --self-test

sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- \
  sbcl --noinform --no-userinit --no-sysinit --script tools/get-directory-mutation.lisp \
  --check spikes/out/get-directory-mutations-frozen/
```

Prima del freeze vanno concordati la presenza della guardia `:directory-shape`,
i cinque nomi di test qui elencati, l'ASDF con i quattro componenti prodotto
directory e i file suite definitivi. Se l'implementazione evolve, si correggono
solo questi due file, poi il padre congela nuovamente. Nessun risultato di una
campagna precedente può qualificare una versione successiva dei sorgenti.
