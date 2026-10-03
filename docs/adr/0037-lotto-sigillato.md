# ADR-0037 — Il lotto sigillato: un solo percorso di scrittura, un flush alla volta, frontiera durevole

- **Stato:** Accettata
- **Data:** 2026-10-03
- **Rapporto con la specifica:** nessuna emenda; precisa «WAL» (group commit) e «Recovery».
  **Sostituisce in parte** [ADR-0019](0019-durability-e-group-commit-pipelined.md) (meccanica
  del group commit; i livelli restano), [ADR-0033](0033-fail-stop-e-integrita-end-to-end.md)
  §4 (coda troncata) e [ADR-0013](0013-log-structured-segmento-active-come-log.md) punto 4
  (quando un record è committed)
- **Riferimenti:** [analisi progettuale](../analisi-progettuale.md) AP-02, AP-03, AP-08;
  [architettura](../architettura.md#percorso-di-scrittura);
  [formati](../formati-su-disco.md#lotto-e-seal); INV-F2, INV-F3, INV-V5, INV-A9

## Contesto

ADR-0019 ammetteva più lotti in volo sullo stesso file e ADR-0033 classificava come corruzione
ogni record valido che seguisse un'anomalia: insieme, trasformano una perdita di alimentazione
ordinaria in un guasto della Serie (AP-03). Il CSN era preso prima che il contenuto del lotto
fosse fissato (AP-02). I log di controllo non avevano una regola per la propria coda (AP-08).

## Decisione

### 1. Il lotto

Il **lotto** è l'unità di atomicità, di durability e di pubblicazione di un log. È una
sequenza di record seguita da un record **SEAL** che ne fissa: file, posizione di inizio,
numero di record, contenuto (CRC dei CRC dei record), CSN, e la **frontiera durevole** nota
al momento della chiusura. Un lotto è valido per intero o non esiste (INV-F2): nessun suo
record è applicato se il SEAL manca o non corrisponde.

Un record non prepared è committed **se e solo se sta in un lotto valido**. Non esistono
elenchi di TXID: l'appartenenza è per posizione.

### 2. Il percorso, uguale per ogni log

```
in sospeso ──chiusura──▶ scritto ──flush──▶ durevole ──▶ pubblicato ──▶ confermato
```

1. Il writer valida ogni operazione e ne **mette in sospeso** l'effetto: record nel buffer
   del lotto aperto, voce nella tabella delle versioni in sospeso della Serie.
2. **Chiusura**: quando la coda è vuota o il lotto ha raggiunto il limite (byte, operazioni).
   Alla chiusura il writer prende il **CSN** (un incremento atomico), lo scrive nei record,
   calcola i CRC delle intestazioni e appende il SEAL. Il lotto chiuso è immutabile.
3. **Un compito di I/O alla volta** per log, eseguito dal pool di I/O: scrive (`write`) tutti
   i lotti chiusi e non ancora scritti, poi esegue il flush durevole. Al termine, se nel
   frattempo sono stati chiusi altri lotti, parte il successivo. Il writer non esegue
   chiamate bloccanti e non attende: continua a formare lotti
   ([ADR-0045](0045-modello-di-esecuzione.md)).
4. **Pubblicazione** in ordine di lotto, quando un flush completato copre il lotto: le
   versioni passano dalla tabella in sospeso all'indice.
5. **Conferma** al client dopo la pubblicazione (INV-V5).

Il livello di durability cambia **solo il momento** di pubblicazione e conferma:

| Livello | Pubblicazione e conferma |
|---|---|
| `:group` (default), `:strong` | dopo il flush che copre il lotto |
| `:async` | a `write` completata, prima del flush |

`:strong` e `:group` danno la stessa garanzia; `:strong` chiude il lotto subito, senza
l'eventuale attesa di formazione. Con `:async` i dati sono nella page cache alla conferma:
sopravvivono all'arresto del processo, non a quello della macchina. Le restrizioni di
ADR-0033 §10 restano.

I lotti chiusi e non ancora durevoli sono limitati in byte per Serie; oltre il limite il
writer non svuota la coda, che è a sua volta limitata (`resource-exhausted`, INV-A8).

### 3. Coda troncata o corruzione: decidibile dal contenuto (INV-F3)

Sia `P` la posizione del primo lotto non valido di un log. Si cercano, da `P` in poi, record
SEAL validi **di quel file** (identificativo e posizione dichiarati coincidono con quelli
reali). Sia `D` la massima frontiera durevole che dichiarano.

- `D > P` → quando quel lotto successivo fu chiuso, i byte in `P` erano già durevoli: sono
  stati alterati. **Corruzione**: `FAULTED`, nessuna scrittura, decisione dell'operatore.
- altrimenti (nessun SEAL, o `D ≤ P`) → i lotti da `P` in poi non erano coperti da un flush
  completato: **coda**. La lunghezza valida del log è `P`.

La regola non dipende dall'ordine in cui il supporto rende persistenti le scritture non
sincronizzate. Un falso SEAL trovato per caso produce un rifiuto di apertura, mai una perdita
silenziosa.

### 4. Il recovery non tronca (INV-A9)

La coda non viene rimossa. Il recovery **chiude** l'`ACTIVE` trovato con un record del
manifest che ne fissa la lunghezza valida `P` e apre un nuovo `ACTIVE`
([ADR-0040](0040-manifest-a-record-unico.md)). Un segmento `ACTIVE` vive quindi in un solo
processo; i byte oltre `P` sono ignorati da ogni lettore e spariscono con il CLEAN.

### 5. Tre log, un meccanismo

Il segmento `ACTIVE`, `wal/control.log` e `multiserie.log` sono **log di lotti sigillati**:
stessa cornice di record ([ADR-0039](0039-cornice-unica-dei-record.md)), stesso SEAL, stesso
flush singolo, stessa regola della coda. Cambia solo il tipo dei record contenuti. Per i due
log di controllo, che non si chiudono mai, la coda `P` si ignora in lettura e il primo lotto
dopo il riavvio viene scritto in un file compattato (rinomina atomica).

Pattern: group commit con un flush alla volta e conferma per copertura (PostgreSQL: scrittura
del WAL, flush di gruppo, attesa che il flush raggiunga il proprio LSN; `synchronous_commit`
per `:async`); intestazione e corpo verificati separatamente con il lotto come unità
(TigerBeetle); file attivo nuovo a ogni apertura (Bitcask).

## Conseguenze

- Un solo percorso di scrittura da verificare, per tre log e tre livelli.
- Stato del writer limitato: il lotto aperto, i lotti chiusi e non pubblicati, un compito di
  I/O.
- Dopo ogni riavvio resta un segmento chiuso in più, anche piccolo: è un candidato al MERGE.
- Latenza di `:group`: tra uno e due flush sotto carico (quello in corso e il proprio).

## Limite dichiarato

Un danno che colpisca, **a riposo**, i soli lotti resi durevoli dall'ultimo flush prima di un
arresto improvviso — e non ancora testimoniati dal SEAL di un lotto successivo — è
indistinguibile da una coda. È il confine di ciò che un log può sapere di sé; coincide con la
classe dei guasti non tollerati (flush non durevole, FM-03) ed è registrato come
[RES-05](../affidabilita/analisi-dei-guasti.md#rischi-residui-accettati). Un arresto ordinato
chiude il segmento: nessuna finestra.

## Alternative considerate

- *Più flush in volo sullo stesso file (ADR-0019):* nessun guadagno di throughput (un flush
  sincronizza comunque tutto il file) e stato del writer non limitato a priori.
- *Un solo lotto non sincronizzato per volta, accumulando in memoria:* regola della coda più
  semplice, ma con `:async` i dati confermati starebbero solo nella memoria del processo.
- *Troncare la coda in recovery:* è una scrittura distruttiva guidata da una classificazione;
  un errore di classificazione diventerebbe una perdita.

## Valutazione

- Rischi: chiude la parte di correttezza di RSK-03; RES-05 dichiarato.
- Verifica: FI-01, FI-02 con persistenza non ordinata dei lotti non sincronizzati
  ([FM-25](../affidabilita/analisi-dei-guasti.md#fmea)); modello in SPK-07 (ogni sottoinsieme
  dei lotti non sincronizzati può andare perso o risultare parziale); SPK-03 misura latenza e
  throughput con un flush alla volta.
- Rivedere se: SPK-03 mostra che un flush alla volta non raggiunge i minimi di
  [ADR-0028](0028-target-e-obiettivi-di-latenza.md).
