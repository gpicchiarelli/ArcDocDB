# Decisioni della consegna locale dei writer

Inventario C1 di [`handoff.lisp`](../../src/execution/handoff.lisp) e del nuovo
helper `%accoda-sotto-guard` in [`queue.lisp`](../../src/execution/queue.lisp).
Le decisioni delle primitive delegate restano nell'
[inventario delle code e delle lease](code-writer-decisioni.md); questo
documento aggiunge i controlli della consegna locale e ne esplicita i cleanup.
Il [metodo](writer-handoff-metodo.md) distingue test pubblici, fault injection
su oggetti privati e prove su thread reali.

Riferimenti: REQ-CON-001/002/004/005, REQ-AFF-008;
INV-P1/P2/P5/P6, INV-A8, INV-V4;
[ADR-0045, punti 6 e 8](../adr/0045-modello-di-esecuzione.md).

## Predicati scalari e stati

Nel sorgente finale `handoff.lisp` non vi sono nuove decisioni composte con
`and`/`or`: le verifiche di owner e quota inattivi sono `unless` separati.
L'assenza di nuove decisioni composte non elimina le decisioni scalari,
i rami del `case`, i controlli delegati o i percorsi di errore dal denominatore.
I tipi dei parametri e degli slot sono precondizioni controllate dal runtime
con `safety 3`; non vengono disattivati per costruire fixture impossibili.

La tabella riporta le fixture contenute in
[`tests/execution/handoff.lisp`](../../tests/execution/handoff.lisp).
I nomi abbreviati nella terza colonna sono i suffissi dei test con ID `REQ-…`.
Questa corrispondenza descrive il contenuto dei test; il successo delle campagne
e i rami effettivamente marcati devono essere attestati dalle evidenze raw.

| Punto | Condizione ed esiti | Fixture o limite |
|---|---|---|
| `writer-programmabile`: default `queue` | Il costruttore privato riceve una coda esplicita; il default difensivo segnala `:writer-scheduling`. | Factory pubblica; default difensivo non richiamato dalla factory, conservato nel denominatore. |
| `%accoda-sotto-guard`: guard | Guardia uguale al thread corrente oppure `invariant-violation`, `:writer-guard`. | `helpers-require-current-thread-guard`, senza guard e con guard di altro thread; nessuna accettazione. |
| `%accoda-sotto-guard`: ring | Bounds e relazione FIFO verificati prima e dopo la mutazione da `%check-queue`. | Inventario delegato; test precedenti della coda più oracolo FIFO del wrapper. |
| `%accoda-sotto-guard`: pieno | `count = capacity`: `resource-exhausted`, `:writer-queue-full`; altrimenti un'accettazione. | `full-ready-and-running-retain-state`, configurazioni minime/default/massime e oracolo con wrap. Il payload rifiutato resta al produttore. |
| `%check-writer-inattivo`: guard | Guardia del thread corrente oppure `:writer-guard`. | `helpers-require-current-thread-guard`, entrambi i rifiuti dichiarati. |
| `%check-writer-inattivo`: owner | Owner NIL oppure `:writer-scheduling`. | `rejects-inconsistent-scheduling-states`: FI `idle-owner` e `ready-owner`; oggetti privati sacrificati. |
| `%check-writer-inattivo`: quota | `extracted = 0` oppure `:writer-scheduling`. | Stessa fixture: FI `idle-extracted` e `ready-extracted`; quota attiva verificata separatamente dal protocollo lease. |
| `%check-programmabile`: guard | Guardia del thread corrente oppure `:writer-guard`. | `helpers-require-current-thread-guard`; controlli pre/post delle API. |
| `%check-programmabile`: ring | `%check-queue` prima di interpretare lo stato. | Inventario delegato; la FI degli stati mantiene coerenti gli indici del ring. |
| `%check-programmabile`: `case` | `:idle`, `:ready`, `:running`; `otherwise` segnala `:writer-scheduling`. | Tre stati attraversati dall'API. `otherwise` è difensivo e non costruito aggirando il tipo dello slot; resta nel denominatore raw. |
| Stato idle: count | `count = 0` oppure `:writer-scheduling`. | Factory e termine vuoto; FI `idle-count`, con ring coerente. |
| Stato ready: count | `count > 0` oppure `:writer-scheduling`. | Primo enqueue e riaccodamento; FI `ready-count`, con ring coerente. |
| Stato running: owner | Owner presente oppure `:writer-scheduling`. | Tratti attivi; FI `running-owner` dopo un avvio legale. |
| `accoda-lavoro-writer`: `schedule` | Stato prima dell'accettazione uguale a idle; falso per ready e running. | `single-obligation-and-duplicate-begin`, race prima/dopo il termine vuoto, producer su tratto attivo. |
| `accoda-lavoro-writer`: `when schedule` | Solo il primo messaggio da idle imposta ready. | Stesse fixture; full e busy non producono una transizione. |
| `accoda-lavoro-writer`: `if schedule` | `:schedule` oppure `:queued`; entrambi con count dell'accettazione. | Numero di obblighi e FIFO nell'oracolo indipendente; notifica fallita ritentata senza ripetere enqueue. |
| `inizia-tratto-writer`: ready | Ready acquisisce lease e passa a running; idle/running segnalano `:writer-not-ready`. | `single-obligation-and-duplicate-begin`, oracolo finito e prova del thread estraneo. Not-ready non autorizza retry ciechi. |
| `inizia-tratto-writer`: acquisizione | CAS guard busy: nessun cambiamento; generazione esaurita: cleanup della proprietà acquisita e ready conservato. | `busy-idle-and-ready-preserve-state`, `generation-exhaustion-preserves-ready`. Generazione preparata a max−1 su oggetto quiescente; due rifiuti successivi senza wrap. |
| `termina-tratto-writer`: lease | Controlli delegati prima dell'acquisizione della guard; gettone valido oppure `:writer-lease`. | `lease-validation-and-stale-generation`, `foreign-thread-cannot-use-lease`; doppio termine rifiutato. |
| `termina-tratto-writer`: pending | `count > 0` oppure zero, sotto la stessa guard dell'enqueue. | Backlog, conclusione anticipata, quota cumulativa e vuoto; due ordini della race. |
| `termina-tratto-writer`: `if` stato | Pending imposta ready; assenza di pending imposta idle. | `early-release-conserves-entire-backlog`, `cumulative-quantum-and-successive-slices`, `enqueue-before-and-after-empty-release`. |
| `termina-tratto-writer`: `if` risultato | Pending restituisce `:schedule`; altrimenti `:idle`. | Oracolo delle notifiche e nuova ondata dopo idle; worker differenti su tratti successivi. |

## Primitive delegate e cleanup

| Delega o percorso | Controlli ed effetti | Evidenza prevista o limite |
|---|---|---|
| `crea-writer-programmabile` → `crea-coda-writer` | Tipo/range di capacity e quantum; ring preallocato, esclusivo. | `configuration-and-limits`: input invalidi, default, `(1,65536)` e `(65536,1)`; le decisioni composte originarie restano nel loro inventario. |
| `%acquisisci-guard` / `%rilascia-guard` | Un CAS per acquisizione, proprietà e vecchio valore verificati; nessuno spin. | Inventario precedente; busy deterministico su wrapper idle/ready/running. I controlli difensivi CAS non vengono resi falsi corrompendo una guard condivisa con thread attivi. |
| `inizia-tratto-writer` → `acquisisci-writer` | CAS owner, extracted iniziale, generazione monotona, cleanup senza wrap. | Inventario precedente; massimo della generazione provato anche tramite wrapper. Owner busy non è un percorso legale di un wrapper ready con coda privata coerente. |
| `preleva-lavori-writer` → `preleva-messaggi` | Lease/thread/generazione, target e alias, span, quota cumulativa, minimo count/span/quota, FIFO e `:messages/:empty/:yield`. | `target-preflight-and-private-alias`, lease vecchie/estranee, quota e sentinelle; tutte le decisioni composte restano quelle della primitiva originaria. |
| `termina-tratto-writer` → `rilascia-writer` | Lease ricontrollata, extracted zero prima del CAS owner verso NIL; generazione conservata. | Lease e busy-termine; normale rilascio e successiva lease più alta. Coda privata: nessuna API bassa in parallelo al wrapper. |
| Cleanup della factory | Rilascio della guard dopo la verifica del wrapper appena costruito. | Costruzioni pubbliche; nessun wrapper pubblicato al rifiuto della configurazione. |
| Cleanup di accettazione | Dopo successo, full o errore interno con guard acquisita, `unwind-protect` rilascia la guard. | Full non altera snapshot; enqueue e drain successivi restano possibili. Busy d'ingresso non acquisisce la guard né accetta il payload. |
| Cleanup di avvio | La guard è rilasciata dopo successo, not-ready o overflow; running è impostato solo dopo acquisizione riuscita. | Duplicato e overflow conservano il lavoro e lo stato; overflow libera il CAS owner temporaneamente acquisito dalla primitiva. |
| Cleanup di termine | La guard è rilasciata dopo il trasferimento del gettone e la decisione ready/idle; busy d'ingresso conserva lease, quota e stato. | `busy-release-retains-lease-for-retry`: snapshot prima/dopo, anche dopo elaborazione; si ritenta solo il termine. |

Un `invariant-violation` richiede fail-stop al proprietario: non si promette
rollback di una mutazione seguita da un guasto interno. Le condizioni normali
full/busy e gli errori di lease/target precedono invece la rispettiva mutazione.
Il wrapper non produce callback, thread, ready list, risvegli o cambiamenti
durevoli. Conservare ed eseguire una sola volta l'obbligo `:schedule` appartiene
al chiamante; abbandonarlo o duplicarlo esce dal contratto.

## Prima lettura indipendente e correzioni

La prima lettura ha esaminato `handoff.lisp` SHA-256
`256367a3acc48fffdd4c48db6b2f7a12583971b7cbe307d81906442ee939234b`
senza trovare una race funzionale. Ha registrato due rilievi, entrambi chiusi
nel sorgente finale SHA-256
`ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607`:

- La docstring di avvio accomunava busy, not-ready e generation con un invito
  a ritentare. Ora distingue busy transitorio, assegnazione non eleggibile o
  duplicata e generazione permanentemente esaurita; nessun nuovo percorso API.
- `%check-programmabile` superava COD-13 contando il cortocircuito dei due
  `and`. L'estrazione di `%check-writer-inattivo` lascia otto percorsi nel
  primo helper e quattro nel secondo; owner ed extracted hanno verifiche
  scalari separate. I rifiuti sono esercitati singolarmente dalla FI privata.

Sorgente `queue.lisp` confrontato:
`244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90`.
Test confrontati:
`7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e`.
La [revisione finale](writer-handoff-revisione.md) collega questi sorgenti ai risultati congelati;
questa prima lettura e l'inventario non attestano da soli `make check`,
assenza universale di allocazioni, MC/DC completa o qualifica del motore.

## Copertura raw osservata

La campagna nella copia congelata `arcdocdb-handoff-verify-0795g4qt`
ha prodotto `spikes/out/handoff-coverage/coverage-state.lisp` e l'indice HTML.
Il ricalcolo indipendente legge i vettori dei percorsi e i bit raw:
un percorso iniziante con `:then` o `:else` è un esito di ramo, gli altri
sono espressioni. Il risultato coincide con l'indice HTML; nessun elemento
viene sottratto dal denominatore.

| File execution | Espressioni marcate / totali | Esiti marcati / totali |
|---|---|---|
| `package.lisp` | 0 / 1 | 0 / 0 |
| `queue.lisp` | 142 / 184 | 24 / 34 |
| `writer.lisp` | 190 / 218 | 36 / 44 |
| `handoff.lisp` | 173 / 190 | 16 / 16 |
| Totale | 505 / 593 | 76 / 94 |

Le 17 espressioni non marcate di handoff sono nove forme top-level
(`in-package`, ottimizzazioni e `ftype`), due forme degli slot/default
della struttura, due forme dei default keyword della factory e quattro
forme dell'errore `otherwise` difensivo. Nessun esito di ramo strumentato
di handoff è scoperto; `otherwise` resta tra le espressioni raw.
Non si deduce da 16/16 copertura MC/DC completa.

Il nuovo helper `%accoda-sotto-guard` non ha esiti strumentati scoperti.
Le 42 espressioni non marcate di queue comprendono 22 forme di definizione
o default e 20 forme in cinque errori difensivi. I dieci esiti non marcati
sono due alternative dell'`or` del tipo dello slot DEFSTRUCT, cinque esiti
dei bounds/relazione del ring e tre controlli post-acquisizione/proprietà/CAS
della guard. Rispetto alla campagna precedente resta un'espressione non
marcata aggiuntiva, il nuovo `ftype` dell'helper; le lacune operative
precedenti non vengono dichiarate chiuse da questo refactor.

Le 28 espressioni non marcate di writer sono otto forme di definizione e
20 forme in cinque errori difensivi. Gli otto esiti non marcati sono due
del controllo di quota della lease, due del rilascio owner, due delle
postcondizioni di acquisizione e due delle postcondizioni del prelievo.
La forma non marcata del package resta anch'essa nel totale.
Non viene approvata alcuna esclusione C1; questi dati non qualificano
i risvegli, il pool adattivo, il percorso di fault del motore o la sua latenza.
