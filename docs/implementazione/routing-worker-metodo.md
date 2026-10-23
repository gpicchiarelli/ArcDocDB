# Metodo preregistrato del routing worker/Serie

Base iniziale `92decf4265554cd4959e32a1c881cf00758bb6a1`.
Metodo fissato prima delle campagne dedicate al routing nuovo.
Ambito: estensione immutabile del writer programmabile, registro condiviso,
tabella locale e lookup, dichiarazioni package/ASDF, test e C4 di misura.
Il [contratto](routing-worker.md) mantiene espliciti i confini non integrati.

Verifiche previste:

- Ordinale `NIL` compatibile con writer esistenti, 0 e 65535 validi;
  valori fuori tipo/budget rifiutati all'avvio prima della pubblicazione.
- Registro da 1 a 65536 slot, input di tipo/lunghezza coerenti,
  ordinale esattamente uguale allo slot; controller duplicati EQ rifiutati.
  Copie private: modificare entrambi gli input dopo la factory non cambia
  il lookup. Registri indipendenti possono usare gli stessi numeri.
- Tabella creata sul thread owner del contesto IDLE, collegamenti locali
  preallocati, distinti fra worker e riferiti allo stesso registro.
  Owner e fase errati non consumano obblighi o lease.
- Catena reale accettazione, pubblicazione ready, claim, lookup, doppia lease,
  FIFO, pop, ack, fine e ricircolo. Il ricircolo full deve cambiare writer e
  quindi collegamento senza ripetere il tratto del precedente writer.
- Lookup ripetuto su CLAIMED/IDLE restituisce lo stesso collegamento senza
  mutare il grafo di stato; nessuna lease Serie è acquisita dal lookup.
- Writer estraneo con ordinale valido, writer senza ordinale e indice oltre
  la tabella diventano fault terminali del worker dopo claim. Stessa
  condizione EQ conservata e propagata; writer/home/obbligo restano disponibili
  alla diagnosi. Nessuna mutazione di alcun controller non acquisito.
- FI quiescente della tabella privata: slot o binding incoerente, contesto
  estraneo, collegamento non IDLE. Il rifiuto precede begin/pop e non libera
  o marca una Serie di cui il routing non possiede la lease.
- Due worker reali, due Serie e stesso registro: collegamenti locali distinti,
  due Serie contemporaneamente ACTIVE. Semafori e deadline sono nel solo
  harness. Si distingue il controllo d'identità dall'esclusione già provata
  dal bridge; la fixture non misura throughput o equità del pool.
- Serie FAULTED selezionabile per il drenaggio già previsto dal controller.
  Nessun gate di salute aggiunto al lookup; nuova pubblicazione resta regolata
  dal controller. Nessuna prova di arresto globale Archivio è dedotta.
- Due letture C1 sui dodici punti, inventario di tutte le decisioni e dei
  controlli delegati, comprese eventuali decisioni composte condizione per
  condizione. Copertura nativa e HTML nello stesso processo che esegue le
  suite Series ed execution: unione completa di 15 sorgenti Series e
  11 sorgenti execution, package e helper inclusi. Il denominatore contiene
  anche le forme preesistenti di handoff, macro worker e bridge; nessuna
  decisione execution è attribuita al solo scope Series. Tutte le identità
  dei percorsi mancanti restano nell'audit, senza esclusioni approvate.
- Allocazione locale su ciclo completo con due writer, due controller,
  un worker, ready con una partizione/capacità1 e tabella preallocati.
  Ogni ciclo alterna il writer e compone enqueue, publish, claim, due lookup
  EQ/indice atteso, begin/lease, pop/ack ed end idle. Due cicli di startup
  popolano le identità fuori sensore. Warmup128, cinque campioni da4096 cicli,
  GC/stampa fuori misura. Sink indipendente del driver:
  `12+17+19+13+11+13+3+25+7+23=143`,
  campione `N*143+N*(N-1)/2`; token bridge e lease Serie monotoni per writer,
  token batch monotono nel worker. Controlli baseline, heap positivo16×1MiB,
  sink errato e clock sotto risoluzione dimostrano il rilevamento del C4.
- C4 compilato integralmente con warning e style-warning fatali, self-test
  del FASL, rilevamento heap/sink errato e CLI invalida. La sola eccezione
  runtime ASDF è `sb-kernel:redefinition-warning`, già prevista dal build;
  nessuna eccezione agli avvisi di compilazione del nuovo strumento.
- Build e test mirati prima del controllo generale; `make check` una volta
  sul codice finale congelato, salvo cambiamenti o failure reali.

Ogni campagna usa `tools/record-command.lisp`, con stdout/stderr, argv,
ambiente, snapshot iniziale/finale e tentativi falliti conservati. Le campagne
usano copie congelate e cache separate. Dati grandi compressi senza perdita,
catalogo e verifica dei byte conservati; nessun raw viene ricostruito.

Le misure locali distinguono startup e percorso normale. Non si deducono
heap nullo universale, throughput, P99, fairness, scalabilità o chiusura dei
gate della Fase0. Stati globali dei requisiti restano `progettato`.
