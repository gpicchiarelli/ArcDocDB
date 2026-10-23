# Metodo preregistrato del collegamento worker/Serie

Base iniziale `2a0011f9d2bef104b22f7ad1eb86d7e5d60d5e11`.
La qualificazione finale incorpora `main` fino a
`8101eb856cbe9d7540682babb53afb00fde30f70`, inclusa la fondazione hash:
le due prove preliminari sul primo scope rimangono distinte dalla verifica integrata.
Metodo fissato prima delle campagne e delle misure del nuovo collegamento.
Ambito: quattro sorgenti late in `src/series/worker-*.lisp`, ASDF, test della
suite Serie e strumento C4 `tools/worker-series-bench.lisp`.
Contratto e limiti nel [documento del modulo](worker-serie.md).

Verifiche previste, con input e oggetti preallocati:

- Tratto completo, ordine FIFO e identità dei payload, buffer con sentinelle,
  token/lease monotoni su ondate successive e ack prima della fine.
- Busy writer prima di acquisire Serie; busy della seconda lease e generation
  Serie esaurita, distinti nei tre valori del begin. Nessun pop e obbligo
  schedule conservato fino a ricircolo e nuovo tratto.
- Fine busy dopo release Serie: CLOSING/FINISHING, sola fine ritentabile,
  controller subito acquisibile e nessuna seconda release sul retry.
- Binding, fase, owner, token e generazioni invalidi prima delle mutazioni;
  batch debt, ack stale, alias/span e wrong-thread senza poisoning.
- Fault durante release Serie: stessa condizione, riferimento e lease
  conservati, worker non concluso; fault dopo release senza scrivere sul
  controller consegnato. Bypass delle lease catturate rifiutato prima del pop.
- Decisione composta del fault marking: tre condizioni scalari, ciascuna
  falsa indipendentemente con le altre vere, e tutte vere. Copertura manuale
  per le condizioni, senza dedurre MC/DC da sb-cover.
- Competizione sulla stessa Serie e due Serie contemporaneamente attive con
  thread reali, semafori e deadline del solo harness; nessun thread nel prodotto.
  Acquisizione di Serie FAULTED consentita per drenaggio già previsto dal controller.
- Macro boundary: espansione, valutazione singola, valori multipli, errore EQ
  e gate owner/faulted prima del handler. Allowlist esatte per tipo e ragione.
  Sottopassi di acquisizione e rilascio Serie isolati con allowlist vuote:
  una ragione ammessa soltanto dal writer non nasconde un errore della Serie,
  e il fault del worker sottostante non torna recuperabile nel bridge.
- Due letture C1 con dodici punti e inventario di tutte le decisioni; raw
  sb-cover e HTML per l'intero scope Series, file late inclusi, denominatore
  completo e lacune conservate. Nessuna esclusione approvata.
- Allocazione locale: warmup128, cinque campioni da4096 cicli completi su
  collegamento/worker/controller/target preallocati; GC e stampa fuori misura.
  Ogni ciclo accoda un payload, adotta obbligo, begin, legge lease, pop, ack,
  end idle e controlla identità/esiti/generazioni. Sink indipendente fisso
  per ciclo nel driver, non ricavato dalle funzioni di prodotto:
  `12+7+11+13+3+25+7+23=101`, sink campione `4096*101+4096*4095/2=8800256`.
  Controlli
  positivi dell'heap e sink errato dimostrano il rilevamento del C4.
- Strict COMPILE-FILE completo dello strumento e self-test del FASL con warning
  e style-warning fatali; il caricamento ASDF applica la sola eccezione per
  `sb-kernel:redefinition-warning` già dichiarata da `tools/build.lisp` per
  riletture/ridefinizioni del caricatore. Nessuna esclusione di avvisi di
  compilazione del C4. Build e test mirati prima del controllo completo.
  `make check` una volta sul codice finale congelato, salvo cambiamenti o failure.

Ogni campagna viene registrata con `tools/record-command.lisp`, conservando
stdout/stderr, argv, ambiente, report originali, snapshot iniziale/finale e
tentativi falliti. Le campagne usano copie congelate e cache distinte. I dati
grandi vengono compressi senza perdita con catalogo conservativo.
Non si deducono throughput, P99, fairness, scalabilità o heap zero universale
da questi campioni. Nessun gate della Fase0 viene chiuso per questa fondazione.
