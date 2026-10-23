# ADR-0032 — Seqlock a 64 bit con tentativi limitati e ripiego sul writer

- **Stato:** Accettata; **punto 2 (layout dello slot) sostituito da [ADR-0043](0043-primary-index-a-frammenti.md)**: slot a 4 parole; al raggiungimento della soglia del contatore il frammento si ricostruisce invece di fermare la Serie. Protocollo, 64 bit e tentativi limitati restano.
- **Data:** 2026-10-03
- **Rapporto con la specifica:** nessuna emenda; **sostituisce in parte**
  [ADR-0015](0015-primary-index-swiss-table-swmr.md) (dettaglio del seqlock e layout dello
  slot). Il resto di ADR-0015 resta valido.
- **Riferimenti:** [architettura](../architettura.md#primary-index), INV-I1, INV-A8

## Contesto

[ADR-0015](0015-primary-index-swiss-table-swmr.md) usava un contatore seqlock a 8 bit,
giustificato così: un falso «uguale» richiederebbe 256 scritture sullo stesso slot durante
una lettura di ~100 ns. È un argomento sulla **velocità relativa dei thread**, non una
garanzia: un reader sospeso a metà lettura (preemption, pausa del GC, scheduler del sistema
operativo) può osservare 256 scritture e rilevare lo stesso contatore con campi incoerenti.
In un sistema critico la correttezza non può dipendere dai tempi (ADR-0031, priorità 2).

Inoltre un ciclo di tentativi illimitato non è ammesso (INV-A8): un writer che modifica
continuamente lo stesso slot affamerebbe un reader.

## Decisione

1. **Contatore a 64 bit per slot**, in un array `(unsigned-byte 64)` parallelo agli altri.
   Ogni scrittura lo incrementa due volte. Il ritorno a un valore già visto richiederebbe 2⁶³
   modifiche dello stesso slot: oltre 290 anni a 10⁹ modifiche al secondo. L'assunzione è
   dichiarata e verificata da un controllo che rende fatale (fail-stop) il superamento di
   2⁶² (ADR-0033).
2. **Slot: 6 parole da 64 bit + 1 byte di controllo = 49 byte**; a fattore di carico 7/8
   ≈ **56 byte per entry**. Il CSN torna a 64 bit pieni.

   | Parola | Contenuto |
   |---|---|
   | 0 | hash64 della chiave |
   | 1 | key-off (40 bit) · key-len (8) · tipo (8) · flag (8) |
   | 2 | segment-id (32) · offset (32) |
   | 3 | length (24) · versione (40) |
   | 4 | csn (64) |
   | 5 | contatore seqlock (64) |

3. **Protocollo.** Writer: `s ← seq`; `seq ← s+1` (dispari); barriera di scrittura; scrittura
   dei campi; barriera di scrittura; `seq ← s+2`. Reader: `s1 ← seq`; se dispari, nuovo
   tentativo; barriera di lettura; lettura dei campi; barriera di lettura; `s2 ← seq`; se
   `s1 ≠ s2`, nuovo tentativo. Le barriere sono `sb-thread:barrier`.
4. **Tentativi limitati: al più 8.** Se esauriti, il reader inoltra la lettura al **writer
   logico della Serie** come richiesta serializzata: sempre coerente per costruzione, mai
   illimitata. Il caso è raro ed è una metrica (`seqlock-fallback`).
5. La **key arena** è append-only e immutabile dopo la pubblicazione: si pubblica con barriera
   di scrittura e poi con l'aggiornamento dello slot; nessun seqlock è necessario. La
   **tabella delle versioni trattenute** usa lo stesso protocollo del punto 3.
6. **Verifica.** (a) Il protocollo è un modello esplorato in modo esaustivo (1 writer, 2
   reader, 2 slot, ogni interleaving, ogni sospensione) in SPK-07. (b) Stress test con writer
   che scrive pattern autoconsistenti (tutti i campi derivati da un solo valore) e reader che
   verificano la coerenza, con sospensioni artificiali tramite lo schedulatore iniettabile
   ([ADR-0035](0035-strategia-di-verifica-e-tracciabilita.md)).

Pattern: seqlock (kernel Linux) con contatore a larghezza piena; lettura ottimistica con
ripiego bloccante (SeqLock in Linux `seqlock_t`, Folly SeqLock).

## Conseguenze

- +8 byte per entry (48 → 56 B): [limiti](../limiti.md) e [stime](../valutazione/stime-ordine-di-grandezza.md)
  aggiornati.
- Nessun argomento di correttezza dipende dai tempi.
- Nessun ciclo illimitato sul percorso di lettura.

## Alternative considerate

- *Contatore a 8 o 16 bit:* correttezza probabilistica; scartata.
- *Lock lettore/scrittore per slot o per tabella:* contesa tra reader e writer sul percorso
  caldo.
- *Una nuova copia dell'entry a ogni modifica (RCU per entry):* un oggetto per entry, contro
  ADR-0024.

## Valutazione

- Rischi: RSK-02 (parte prestazionale, SPK-01).
- Rivedere se: la frequenza di `seqlock-fallback` è non trascurabile sotto carico (SPK-01).
