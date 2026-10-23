# Metodo del passo pool/Serie

Preregistrazione del 2026-10-15, base
`5be241d8f295e3c82df06e75c9b12e0bf75eb202`, prima delle campagne formali.
Scope C3: tutti i sette file di `src/dispatch/`, inclusi `step.lisp` e i sei
precedenti. Nessuna modifica C1. Il [contratto](pool-step.md) specifica
origine, dettaglio e azione, con una sola operazione delegata per passo.

## Prove funzionali e revisione

- IDLE con attivazione, inattività, empty e busy: cinque risultati, cursore
  originale e azione lifecycle, un solo ingresso operativo.
- CLAIMED da presa, adozione o full: current senza gate, comandi o ACK;
  dettaglio e azione NIL, selezione del writer corrente senza begin.
- RESCHEDULE room termina IDLE senza seconda presa; full avvia soltanto il
  routing del nuovo CLAIMED. Count e cursore volutamente differenti.
- Ritiro pendente: gli obblighi precedono l'ammissione; ACK soltanto al
  successivo passo IDLE, mai dopo room nella stessa chiamata.
- Guard ready realmente occupata: ritorno BUSY del claim distinto dalla
  condizione busy del ricircolo; preimage e obbligo conservati.
- Binding e owner prima della lettura fase e di ogni ingresso operativo.
  RUNNING/BATCH/FINISHING/FAULTED rifiutati senza cambiare debiti o causa.
- Routing fallito dopo scambio: causa EQ, effetti già riusciti conservati,
  nessuna deduzione di rollback. Stato incoerente delegato alle barriere C1.
- Getter interposto fuori ftype: rifiuto effettivo della fase inattesa;
  FI quiescente ripristinata, distinta dal contratto nominale C1.
- Una revisione indipendente C3 con lista di controllo; compilazione strict
  safety 3, lint, tracciabilità e controllo completo con dieci spike.

Nessuna nuova prova positiva di concorrenza è richiesta dal passo owner-only.
L'owner estraneo usa un thread distinto come prova negativa. Non si deduce
overlap temporale o stress da una sola barriera di partenza.

## Copertura, misure e conservazione

Gate almeno 95% di espressioni e rami sull'intero package, senza esclusioni.
Conservare nativo SB-COVER, otto HTML e audit native/HTML con tutti i missing.
Il reader C4 verificato viene adattato allo scope esplicito di sette file;
nessuna copertura C1 o equivalenza MC/DC viene ereditata.

Due campagne: EMPTY attivo su quattro shard vuoti, quattro passi per ciclo
con rotazione del cursore; CURRENT su CLAIMED reale e porta inattiva,
quattro lookup stabili per ciclo. Cinque repliche da 4096 cicli e 128
warmup per campagna, fixture nuova per replica. Fixture, factory, claim
iniziale, lookup API, GC e drain pubblico finale restano fuori clock.
I cinque valori e le identità sono verificati nel clock; nessun reset
privato, begin o applicazione di payload nel tratto misurato.

INACTIVE/IDLE e i cinque valori del rifiuto sono coperti dai self-test;
RESCHEDULE, CLOSING e contese rimangono nelle prove funzionali, senza una
misura di latenza dedicata. Conservare heap, tick, sink e cicli completati:
heap zero osservato non dimostra non allocazione universale. Carico esterno
incontrollato, nessuna soglia, taratura o attribuzione al solo adapter;
i delegati C1 e gli oracoli scalari sono parte del costo.

Self-test positivi e negativi per cinque risultati difformi, sink, clock
sotto risoluzione, heap deliberato, CLI, destinazioni preesistenti e raw
parziali. Campagne formali su copia congelata, cache dedicate e
`record-command.lisp`: argv, output, exit e impronte iniziali/finali.
Conservare fallimenti e sviluppo separati; copie byte per byte e manifesti
nuovi esclusivi, senza riscrivere le prove originali.
