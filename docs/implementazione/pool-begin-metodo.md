# Metodo dell'avvio pool/Serie

Preregistrazione del 2026-10-14, base
`ad829a40f6ce72837b59982d2e4f83e8c9ca9f3e`, prima delle campagne formali.
Scope C3: tutti i sei file di `src/dispatch/`, inclusi `begin.lisp` e i cinque
gia qualificati. Nessuna modifica C1; [contratto](pool-begin.md).

## Prove funzionali e revisione

- Avvio reale: link/token/fase/ragione, doppia lease, pop/ack/end espliciti.
- Scambio full A→B: begin del link B corrente, mai del precedente A.
- CLAIMED con porta inattiva, ritiro pendente o comandi incoerenti: nessun
  accesso al gate, ACK, seconda presa o ricircolo.
- Writer busy reale: CLAIMED, IDLE e generazione del bridge conservati.
- Serie busy e generazione esaurita: CLOSING con token, nessun pop o
  riacquisizione; fine esplicita attraverso il bridge originale.
- Generazione del token bridge esaurita: rifiuto prima del begin, distinto
  dall'esaurimento della lease Serie successivo alla presa del writer.
- Owner estraneo e binding incoerente prima di routing e acquisizione.
- Fasi non ammesse, debito, lease e prima causa conservati; routing
  invalido e guasti di begin propagano la condizione C1 originale.
- Una lettura indipendente C3 con lista di controllo; compilazione strict,
  safety 3, lint, tracciabilita e regressione completa.

## Copertura, misura e conservazione

Gate C3 almeno 95% di espressioni e rami sull'intero package, senza
esclusioni manuali. Conservare SB-COVER nativo, HTML e audit concordante,
con denominatori e tutti i missing; nessuna deduzione MC/DC o qualifica C1.
Il reader C4 verificato viene riusato con adattamento esplicito di scope.

Sensore locale con cinque repliche di 4096 cicli e 128 warmup. Fixture,
factory, lookup API e GC fuori clock. Un ciclo comprende l'avvio del bridge
e la fine esplicita, ricircolo e nuova presa execution necessari per
ripetere il tratto; i quattro risultati e le identita entrano nell'oracolo.
Nessun reset privato, callback o applicazione dei payload. Il protocollo C1
fa parte del costo: nessuna attribuzione al solo adapter o conclusione sul
throughput del motore. Conservare cicli completati, sink, tick e heap;
heap zero osservato non dimostra non allocazione universale.

Unica campagna ACTIVE: un payload simbolico reale rimane accodato, senza
pop nel clock. Il drain finale fuori clock lo consuma e conferma attraverso
il bridge, poi termina entrambe le lease. CLOSING e i rifiuti busy sono
coperti dalle prove funzionali e non vengono misurati dal sensore.

Self-test positivi e negativi del sensore: ritorni errati, sink, clock sotto
risoluzione, allocazione deliberata, CLI, raw parziali e destinazione
preesistente. Carico esterno incontrollato; nessuna soglia o taratura.
Campagne su copia congelata con `record-command.lisp` e cache dedicate:
argv, output, exit e identita iniziali/finali. Conservare anche fallimenti
e versioni preliminari, copie byte per byte e nuovi manifesti esclusivi.
