# SPK-01 — metodo preregistrato: lettura in buffer

> **Proposta** — Variante sperimentale di Fase 0, preregistrata prima delle prove.

Registrazione del 2026-10-08, Fase 0. Solo Common Lisp/SBCL, `safety 3`,
`speed 3`, `debug 1`; zero warning e style-warning. Nessun `eval`,
`ignore-errors` o `truly-the`. La compilazione non sostituisce CHECK.

## Ownership e dipendenza

Checkout esclusivo di lavoro:
`/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB`.
Questo agente possiede soltanto `lettura-buffer.lisp`, questo metodo e nuovi
direttori `spikes/SPK-01-primary-index/out/lettura-buffer-*`. Core e runner
esistenti, `tools/`, documenti condivisi e `src/` restano fuori dalla proprietà.
Nessun commit o push. Driver e diagnostica nuovi risiedono nei miei out.
Il modulo richiede il core caricato; importa internals senza ridefinirli.

## API e condizioni

Package `ARCDOCDB.SPK01.LETTURA-BUFFER`, unico export `LEGGI`:

```lisp
(leggi indice chiave destinazione
       &key (attempts 8) after-fragment after-fields)
;; => (values status-keyword retry-fixnum)
```

`indice` è un indice del core; `chiave` è un simple-array di 16 u8.
`destinazione` è esattamente `(simple-array (unsigned-byte 64) (4))`, privata
al chiamante: `[CSN, location, length, end-CSN]`. Tipi, callback e lunghezza
della chiave sono validati, e `attempts` deve essere intero 1..8, prima di hash,
accessi all'indice e scritture. Tipi errati producono `type-error`; chiave con
lunghezza diversa produce `limite-indice` con motivo `:chiave-16-byte`.
Callback accettati: NIL o oggetto funzione, non designatori simbolici.

Esiti: `:hit` e `:miss` con numero di tentativi scartati 0..7;
`:retry-limit` con esattamente `attempts` tentativi scartati. Quest'ultimo è
un esito di esaurimento esplicito, mai una lettura riuscita o parziale.
La destinazione viene scritta interamente soltanto su `:hit`, dopo tutte le
validazioni. Miss, esaurimento ed errori sincroni lasciano le quattro parole
immutate. Nessuna lettura di payload viene restituita come valore Lisp.

Il chiamante mantiene chiave e destinazione stabili e private durante la
chiamata, inclusi i callback. I callback di fixture non modificano questi
buffer e mantengono gli invarianti del core; `after-fragment` riceve il
frammento e `after-fields` riceve frammento e slot. Errori dei callback sono
propagati prima di qualsiasi scrittura. Le quattro scritture non costituiscono
una pubblicazione atomica a osservatori concorrenti della destinazione.

## Algoritmo, ordine e linearizzazione

La fonte è `LEGGI`/`SONDA-READER`/`LEGGI-SLOT` del core. Una sola macro locale
espande lo stesso algoritmo nei cammini diretto e strumentato. Il primo
esclude chiamate ai callback; il secondo inserisce soltanto i due punti di
iniezione. Payload e hash sono locali typed u64: nessun trasporto di payload
tra funzioni o valori multipli. Gli helper hash/sondaggio già inline del core
rimangono le dipendenze. Nessun abbassamento di safety.

Ordine conservato: acquisizione root/generazione; barriera read; selezione
frammento e callback; sondaggio nei gruppi di otto del core; sequenza iniziale
pari; barriera read; campi, ctrl, arena e confronto chiave; callback;
barriera read; uguaglianza sequenza; barriera read; rilettura root e generazione.
Una sequenza dispari o cambiata scarta l'intero tentativo. Una root diversa
scarta hit e miss. Skip prosegue il sondaggio, ctrl vuoto lo conclude con miss.
Nessun writer, lock, CAS o cambio dell'ordine delle barriere nel modulo.

Per hit il candidato è coerente nell'intervallo seqlock stabile e viene
accettato solo dopo il ricontrollo root/generazione. Quel controllo è il punto
di accettazione, non l'affermazione che il payload rappresenti lo stato
all'istante della rilettura root: un writer può aggiornare lo stesso slot dopo
la seconda lettura della sequenza. Miss conserva il criterio del core, anche
per root ritirata. Non si fissa la linearizzazione all'acquisizione della root;
valgono le qualificazioni del prototipo v1 e il vincolo di un singolo writer.

Layout: words4 v1 (end-CSN zero) e words5-extra-end v1 (quinta parola end-CSN),
non v2. CSN, location ed end-CSN u64 alti devono conservarsi esattamente.
Il limite per tentativo è C slot, con C limitata dal costruttore del core;
al massimo otto tentativi. Nessuna garanzia temporale per callback arbitrari.

## Campagna consentita e preregistrazione delle esecuzioni

Budget: massimo quattro revisioni compilate, 90 secondi per processo figlio,
120 secondi nel registratore e 5 secondi per cleanup, heap 1024 MiB.
Un driver nuovo Common Lisp in out avvia processi SBCL senza
init utente e senza shell. Preregistra prima del lancio argv, stdin vuoto,
operazione, budget, snapshot integrali e hash Git blob di core, modulo, metodo
e driver. Snapshot before/after diversi, esaurimento, condizioni o ritorni
compile-file warning/failure sono fallimenti; nessun successo parziale.

Ogni compilazione ha un nuovo out esclusivo e record schema 1, con
`:schema-version 1`, `:argv`, `:stdin`, `:source-before`, `:source-after`,
stdout/stderr originali, exit code e `:decoded`. Anche gli insuccessi sono
conservati. I dati usano liste, keyword, stringhe e numeri; tipi e funzioni
figurano come stringhe, assenza come keyword. La decodifica con `*read-eval*`
NIL avviene nel processo registratore che non carica package dello spike.
Il driver promuove warning/style-warning a errori, verifica gli indicatori di
compile-file e carica il FASL solo se compilato senza avvisi. Non chiama LEGGI.

Esecuzione C1 preregistrata: compilare core e modulo, caricare i FASL,
disassemblare LEGGI, conservare diagnostica e sorgenti stabili. Scopo della
diagnostica: cercare boxing dei payload e chiamate u64 nel cammino diretto;
barriere e bounds check devono essere presenti. Nessuna misura di prestazioni,
allocazioni o throughput. Il disassemblato vale solo per il runtime osservato.
Eventuali revisioni avranno una motivazione e nuova preregistrazione qui,
prima della loro compilazione, senza sovrascrivere i record precedenti.

Driver della campagna: `out/lettura-buffer-campagna-20261008-01/driver-campagna.lisp`
e `driver-compila.lisp` nello stesso direttorio. Comando C1, dalla radice del
checkout isolato:

```sh
/opt/homebrew/bin/sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-01-primary-index/out/lettura-buffer-campagna-20261008-01/driver-campagna.lisp c1
```

La preregistrazione schema 1 viene salvata in `c1/record.sexp` prima di avviare
il processo figlio; stdin, stdout, stderr, FASL e disassemblato sono in `c1/`.

### C1 fallito e C2 preregistrato

C1: il runtime ha rifiutato argv prima di leggere il driver figlio, perché
`--dynamic-space-size` seguiva le opzioni Lisp; exit 1, sorgenti stabili,
stdout vuoto, stderr originale nel record. Nessuna compilazione eseguita.
C2 preregistrato: stesso compile/load/disassemble, opzione heap spostata prima
delle opzioni Lisp. Il registratore stampa stringhe ordinarie con escape,
verifica la rilettura e conserva una diagnosi decodificata anche in assenza
di output strutturato. Comando identico a C1 salvo argomento finale `c2`;
nuovo direttorio `c2/`, stessi budget. Core e algoritmo invariati.

### C2 riuscito e C3 preregistrato

C2: exit 0, core e variante compilati/caricati senza warning/style-warning;
stderr vuoto, sorgenti before/after stabili, disassemblato LEGGI conservato.
Nessun CHECK o BENCH eseguito. Il parent ha richiesto prima del CHECK di B
la riga `;;; REQ: REQ-IDX-001 REQ-IDX-007 REQ-VAL-001` nel kernel e il blocco
`> **Proposta** —` nel metodo. Sono modifiche solo documentali: algoritmo,
API, dichiarazioni e barriere invariati.
C3 preregistrato: nuova compilazione rigorosa core/variante e disassemblato,
stessi driver e budget, nuovo direttorio `c3/`; comando della campagna con
argomento finale `c3`. Il segnale condiviso `kernel-pronto-B.sexp` indica
aggiornamento documentale finché non vengono pubblicati hash finali e READY.

Gli agenti non eseguono BENCH; le misure, la profilazione iniziale e
l'integrazione competono al parent e vengono serializzate da lui. Questo
agente non esegue CHECK del modulo: è proprietà dell'altro agente. La
serializzazione dei writer del core resta responsabilità dell'harness parent.

## Controlli richiesti all'agente CHECK e al parent

Confronto con il core per hit, miss, collisioni e skip, parole 4/5, u64 zero,
massimi e oltre fixnum, lunghezza massima a 24 bit. Sentinel completa invariata
su miss, retry-limit, ingressi invalidi ed errori callback. Witness deterministici
root hit/miss ritirata, sequence odd e changing, contatore retry esatto;
attempts 1 e 8, valori invalidi, array non semplici o di lunghezza diversa,
callback errati. Verificare i due percorsi con lo stesso oracolo e gli invarianti
single writer; nessun BENCH prima della validazione del parent.
