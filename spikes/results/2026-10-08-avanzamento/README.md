# Prove SPK-07 e SPK-08 — 2026-10-08

Il [catalogo](catalogo.lisp) elenca dati schema 1; non si caricano con LOAD.
Risultati e raccomandazione: [resoconto](../../../docs/valutazione/risultati-SPK-07-08-2026-10-08.md).

## Tentativi e provenienza

- Byte: dieci record originali. 01/02/04–09 sono fallimenti attesi di budget;
  03 è preliminare e superato dalla correzione del dominio; 10 è la campagna
  corretta completa. Ogni record include il report del figlio, con fixture,
  casi e conteggi, più stdout/stderr e snapshot integrali dei sorgenti.
- Seqlock: il record portabile contiene l'intera campagna di sette tentativi,
  con originali, report del figlio e wrapper. Include errore sintattico,
  fallimenti di budget, errore di decodifica e recupero dichiarato.
- Impronte: quattro record portabili. Il primo caricamento è rifiutato per
  style-warning; i tre successivi concludono CHECK. `:raw-original` conserva
  ogni record integralmente. `:decoded-record` cambia soltanto i simboli dei
  package sperimentali in stringhe qualificate, mantenendo i dati e gli output.
- `evidence-read-failure.lisp` conserva il fallimento della lettura autonoma
  del vecchio catalogo seqlock. `evidence-read-success.lisp` conserva la
  riuscita dopo la conversione di rappresentazione; nessuna prova del modulo
  è ripetuta dal normalizzatore.
- `integrated-check.lisp` e `spk08-benchmark.lisp` sono copie immutate dei
  report dell'harness. I record riportano comando, ambiente, sorgenti
  selezionati prima/dopo e risultati decodificati. I benchmark sono seriali,
  con carico esterno non controllato.
- `spk08-summary.lisp` contiene soltanto statistiche derivate: hash del
  report originale e mediana come terzo valore di cinque tempi ordinati,
  oltre a estremi, conteggi e contatore di allocazione. Non è un nuovo BENCH.
- `merged-verification.lisp` e `merged-spikes-check.lisp` verificano il
  commit `70dfd93` in checkout pulito, dopo l'integrazione di recovery e
  SPK-06. Il primo conserva `make check`; il secondo i risultati decodificati
  di tutti i dieci spike, con hash dei rispettivi input stabili.

I percorsi assoluti di esecuzione restano metadata storici. Le copie qui
conservate comprendono i dati necessari anche quando le directory ignored
`out/` del checkout isolato non sono più presenti. Nessun fallimento è
trasformato in successo e nessun output grezzo è ripulito.
