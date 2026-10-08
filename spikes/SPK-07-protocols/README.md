# SPK-07 — Modelli eseguibili dei protocolli

> **Proposta** — Esperimento della Fase 0; nessun componente del motore è implementato qui.

## Domanda e metodo

I protocolli conservano dati e visibilità nei piccoli stati esplorati, anche quando il
processo si arresta tra due passi? Un esploratore in Common Lisp visita gli stati distinti
in ampiezza e conserva il percorso più breve verso una violazione. Le transizioni sono
pure; il limite di stati è esplicito. L'oracolo legge fatti durevoli, separatamente dalle
azioni del processo.

Modelli: anello dell'orizzonte, decisione multiserie e rotazione, EDIT e reclaim,
registrazione di snapshot, seqlock, lotti e frontiera durevole,
tombstone e ricostruzione indipendente dall'ordine. Le varianti difettose servono come
controlli negativi: la suite deve trovare un controesempio, altrimenti fallisce.

La suite integra anche quattro moduli con metodo preregistrato:
[pubblicazione](metodo-pubblicazione.md), [scadenza](metodo-scadenza.md),
[compaction con writer ACTIVE](metodo-compaction.md) e
[ordini di osservazione delle barriere](metodo-memoria.md).

## Esecuzione

```bash
sbcl --noinform --no-userinit --no-sysinit --script tools/run-spikes.lisp --check SPK-07
```

Il codice è compilato con `safety 3`; warning e style-warning interrompono l'esecuzione.
L'harness conserva una plist schema 1 con comando, ambiente, revisione, hash dei
sorgenti prima/dopo, risultati decodificati, output originale e fallimenti.
Il risultato contiene conteggi, dimensioni del modello e controesempi. Nessuna
casualità; gli ordini non dipendono dal clock. I file compilati vanno in `out/`,
ignorata da Git. Una prova individuale usa `run-module.lisp nome-modello` tramite
`tools/record-command.lisp`, come descritto nel metodo delle barriere.

## Limiti dichiarati prima dell'esecuzione

- Le transizioni atomiche e la memoria sequenzialmente consistente sono assunzioni del
  modello; non è una prova delle barriere ARM64 o del codice macchina di SBCL.
- I lotti sono entità logiche con validità già determinata: la verifica byte per byte del
  decoder appartiene a SPK-09 e al futuro motore.
- Due partecipanti, un trasferimento, due versioni per snapshot e un numero finito di CSN;
  il risultato non prova configurazioni arbitrarie.
- Gli scenari corrispondono a FI-01…FI-13 a livello astratto; non sostituiscono fault
  injection su un motore né crash reali su file system.
- Il gate della Fase 0 resta aperto: manca un modello architetturale completo della
  memoria debole, con più reader/slot, e restano crash byte per byte e fault injection
  sul motore. Pubblicazione, scadenza e writer ACTIVE sono coperti soltanto nei
  domini finiti dichiarati dai rispettivi metodi.
- Il modello tombstone di base assume un filtro esatto senza falsi negativi e non
  mantiene snapshot attivi; l'estensione compaction aggiunge uno snapshot e un
  filtro conservativo «forse», senza provare la policy concreta di ammissione MERGE.

## Ambiente e risultato

Eseguito il 2026-10-08 su Apple M4, 16 GiB, macOS/Darwin 27.0.0 ARM64, SBCL 2.6.9
GENCGC. Comando riportato sopra; seme assente, nessuna scelta casuale.

| Modello corretto | Stati distinti | Transizioni |
|---|---|---|
| Orizzonte, registro dei pendenti, fino a 6 CSN / capacità 2 | 43 | 72 |
| Multiserie, 2 partecipanti | 59 | 114 |
| EDIT e reclaim, 2 riferimenti | 19 | 28 |
| Seqlock, 2 campi e 1 aggiornamento | 127 | 164 |
| Registrazione snapshot, 1 sostituzione | 28 | 34 |

Altre enumerazioni: 85 combinazioni di persistenza non sincronizzata, 2 corruzioni
testimoniate da un SEAL successivo, 2.256 compaction/ordini di ricostruzione di quattro
record, 25 casi di riconciliazione/recovery. Nessuna violazione nei modelli corretti.
Questi conteggi non sono una copertura del codice del motore.

**Difetto trovato nel progetto:** il modello dell'anello di ADR-0038 produce `H=4` dopo
cinque commit già conclusi; il percorso riproducibile è conservato nell'output di `check` e
in [ADR-0046](../../docs/adr/0046-orizzonte-con-registro-limitato.md). Il registro dei veri
pendenti supera il modello; la soluzione alternativa basata sulla distanza supera 23 stati
e 32 transizioni ma consuma la finestra anche per commit già finiti.

Tre controlli negativi aggiuntivi sono rilevati: decisione dimenticata prima degli esiti
durevoli, reclaim con riferimenti ancora attivi, lettura senza validazione del seqlock. La
registrazione senza pubblicare la soglia perde inoltre la versione necessaria a uno
snapshot. I risultati positivi dipendono dalle assunzioni dichiarate sopra.

## Estensione dei modelli — 2026-10-08

| Modulo | Esplorazione osservata | Controlli negativi rilevati |
|---|---|---:|
| Pubblicazione | 25 esplorazioni, 64.316 stati complessivi, 110.401 transizioni | 6 |
| Scadenza | 2 grafi corretti, 67.558 stati, 256.971 transizioni; 14 witness positivi | 5 |
| Compaction con writer ACTIVE | 98 grafi corretti, 7.994 stati, 16.952 transizioni; 11.592 proiezioni di crash | 8 |
| Ordini osservati delle barriere | 280 ordini corretti; 840 ordini per ciascuno dei quattro mutanti | 4 |

Pubblicazione conserva anche tre esplorazioni delle storie dei mutanti di
generazione e quattro witness di raggiungibilità. Omettere il ricontrollo root
viola il contratto di generazione nel modello, ma le storie esplorate restano
linearizzabili: il risultato non dichiara una perdita di linearizzabilità.

Scadenza distingue pin snapshot ed epoche degli accessi già ammessi. Tutti i
67.507 stati del grafo lifetime hanno un percorso astratto verso un terminale;
questo non è un limite temporale per un reader bloccato. Compaction confronta
latest e storico con una storia committed indipendente; i crash sono proiezioni
logiche, non arresti reali del filesystem.

Le tensioni normative INV-I1/ADR-0043, ritardo di reclaim con reader bloccato in
ADR-0016 e ammissione MERGE con snapshot sono dichiarate nei metodi. Questi
spike non cambiano decisioni o requisiti del motore. Prove, tentativi falliti e
limiti sono conservati nel [catalogo](../results/2026-10-08/catalogo.lisp).

La [campagna integrata finale](../results/2026-10-08/spk07-final-spikes-check.lisp)
verifica il codice del commit `8e4f98f` in un checkout pulito e conserva i
risultati decodificati di tutti i sette spike allora registrati.
`make check` supera anche 26 test delle fondazioni, compilazione senza avvisi,
lint, tracciabilità, collegamenti e catalogo; il
[record del comando](../results/2026-10-08/spk07-final-verification.lisp)
conserva l'output originale. Nessun requisito del motore è promosso a verificato
sulla base dei soli modelli.
