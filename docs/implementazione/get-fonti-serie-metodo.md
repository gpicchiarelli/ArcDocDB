# GET fonti Serie — metodo e revisione statica C4

Revisione del 2026-10-13 nel checkout
`/Users/gpicchiarelli/.codex/worktrees/get-controller/ArcDocDB`.
Scope di scrittura esclusivo: questo documento. Nessun benchmark, helper,
compilazione, test o processo figlio eseguito. Nessun risultato runtime
attestato. Il parent congela i sorgenti ed esegue le verifiche.

## Blocker comunicati durante la lettura

- **C4-01 — collector e runner di mutazioni non concordano sullo schema.**
  `collect.lisp`, SHA-256
  `616e5cef87f30d78f365035837555ce5a2342f29501f9d482801a16798e6df97`,
  righe 198–204, cerca `:directory` nei mutanti e tenta di costruire il
  percorso del sorgente modificato. Il runner comparso alla seconda
  osservazione, `get-series-mutation.lisp`, SHA-256
  `effe04cc8f2db9f93c51fe1642cb541bc0d2a813038e6f374b60c1bec0353948`,
  righe 291–299, scrive `:copy-directory` e `:evidence-directory`.
  La directory attesa dal collector è quindi assente. La pubblicazione
  dei mutanti non è staticamente compatibile: serve allineare il contratto
  prima della verifica centrale. Il runner conserva già sorgente mutato,
  patch, driver, config e log sotto `raw/evidence/<nome>/`.
- **C4-02 — collegamento raw/produttore incompleto.** `collect.lisp`,
  stessa versione, righe 147–165 e 226–231: una radice raw può nominare
  qualsiasi produttore elencato nel manifesto; si verificano terminalità e
  stato, senza confrontare comando e radice né un inventario di digest
  emesso dal produttore. I digest del catalogo attestano le copie al momento
  della raccolta, non l'origine nel processo nominato. Serve distinguere
  queste due proprietà e chiudere il collegamento richiesto.
- **C4-03 — helper esclusi dallo snapshot del wrapper.**
  `tools/record-command.lisp`, SHA-256
  `fae7e2a630e10ae6a1073d072065f9ae0ccef132f6221cb8b91c75124537cb16`,
  righe 17–34, esclude tutto `spikes/results/`, inclusi gli helper Lisp
  eseguiti. Alla lettura delle 18:35:08 UTC ciascuna copia TXT degli helper
  coincide byte per byte con il relativo Lisp. Questa conservazione non
  prova da sola quale versione sia stata eseguita: occorre una registrazione
  separata e congelata dei digest dei sorgenti helper.

`get-series-mutation.lisp` era assente alle 18:35:08 UTC e presente alle
18:36:06 UTC. L'assenza iniziale è un'osservazione storica, non un finding
aperto sulla versione successiva. Il revisore è stato interrotto e chiuso
prima del freeze senza consegna della rilettura finale. La lettura
indipendente C4 completa non è attestata.

## Integrazione dell'autore prima delle esecuzioni

Questa sezione è dell'integratore, dopo la chiusura del revisore. Non
attribuisce al revisore la chiusura delle correzioni successive.

- C4-01: rimosso il ramo del collector che presumeva `:directory`.
  La raccolta ricorsiva conserva `raw/evidence/`, comprese patch, sorgente
  modificato, configurazione, driver e log; esclude `isolatedtests` e cache.
- C4-02: `tools/get-series-capture.lisp` produce l'inventario SHA256 dei raw
  alla chiusura. La sua riga terminale è nello stdout del record produttore.
  Il collector confronta comando/radice, exit-code e inventario completo
  prima della copia. I propri digest sono ancora osservazioni della copia;
  il confronto col record produttore chiuso stabilisce il collegamento.
- C4-03: lo stesso wrapper acquisisce i digest degli helper `.lisp` prima
  e dopo l'invocazione. La riga è conservata dal registratore generale;
  le copie TXT permettono di ricostruire la versione invocata.

Self-test del collector aggiunti: roundtrip del capture, marker assente,
form finale aggiuntiva, dispatch reader vietato e modifica raw dopo il
digest del produttore. Il capture ha il proprio controllo negativo di
mutazione helper. Gli esiti runtime restano al
[rapporto della campagna](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-get-fonti-serie/report.md).

Benchmark: matrice N=1/8/64, due cicli, cinque repliche, seriale e uno/due/
quattro reader avviati tramite gate. Totale 120 finestre, 4.800.000 cicli
misurati e 240.000 di warmup. Il ciclo cache comprende risoluzione e sonda,
quindi due acquisizioni root; gli oracoli e il controllo dei pin restano
nel clock. Startup/gate/join sono inclusi nel parallelo. Heap è allocazione
del processo, non RSS; il gate non prova sovrapposizione temporale di ogni
ciclo. Nessun throughput del database, P99 o costo di durability è misurato.

La campagna muta soltanto i due read preregistrati: baseline isolata e
quattro mutanti. Crash, warning, tipo/fixture/I/O e timeout non sono kill.
La sensibilità della suite e gli esiti del classifier richiedono esecuzione.
