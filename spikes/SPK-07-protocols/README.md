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

## Esecuzione

```bash
sbcl --noinform --no-userinit --script spikes/SPK-07-protocols/run.lisp --check
```

Il codice è compilato con `safety 3`; warning e style-warning interrompono l'esecuzione.
L'output è una plist con conteggi, dimensioni del modello e controesempi. Nessuna casualità
o dipendenza esterna. I file compilati vanno in `out/`, ignorata da Git.

## Limiti dichiarati prima dell'esecuzione

- Le transizioni atomiche e la memoria sequenzialmente consistente sono assunzioni del
  modello; non è una prova delle barriere ARM64 o del codice macchina di SBCL.
- I lotti sono entità logiche con validità già determinata: la verifica byte per byte del
  decoder appartiene a SPK-09 e al futuro motore.
- Due partecipanti, un trasferimento, due versioni per snapshot e un numero finito di CSN;
  il risultato non prova configurazioni arbitrarie.
- Gli scenari corrispondono a FI-01…FI-13 a livello astratto; non sostituiscono fault
  injection su un motore né crash reali su file system.
- Il gate della Fase 0 resta aperto finché le lacune indicate nel risultato non sono coperte:
  pubblicazione dei frammenti, scadenza degli snapshot, memoria debole, crash byte per byte e
  compaction con writer attivo. Il modello tombstone assume un filtro esatto senza falsi
  negativi e non mantiene snapshot attivi.

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
