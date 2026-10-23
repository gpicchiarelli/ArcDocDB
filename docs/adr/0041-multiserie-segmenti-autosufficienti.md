# ADR-0041 — Multiserie su disco: segmenti autosufficienti, abort senza traccia, conferma dopo la pubblicazione

- **Stato:** Accettata
- **Data:** 2026-10-03
- **Rapporto con la specifica:** nessuna emenda; realizza «Transazioni multiserie» e i passi
  1–6 del protocollo. **Sostituisce in parte** [ADR-0021](0021-2pc-intenti-outcome.md)
  (record PREPARE, esiti ABORT, vita dei record OUTCOME, momento della conferma, formato di
  `multiserie.log`). Restano di ADR-0021: writer non bloccante, intenti senza attesa,
  *presumed abort*, decision log unico.
- **Riferimenti:** [analisi progettuale](../analisi-progettuale.md) AP-05, AP-06, AP-08;
  [architettura](../architettura.md#transazioni-multiserie);
  [formati](../formati-su-disco.md#multiserielog); INV-S7, INV-T3, INV-T4, INV-V5

## Contesto

ADR-0021 lasciava indefinita la vita del record OUTCOME: poteva trovarsi in un segmento
diverso da quello dei record che risolve ed essere scartato dal CLEAN mentre la decisione era
già stata troncata da `multiserie.log` — al riavvio i record prepared sarebbero stati
abortiti (AP-05). Il client riceveva la conferma prima che la transazione fosse visibile
(AP-06). Tre record (PREPARE, decisione ABORT, OUTCOME ABORT) non portavano informazione che
il resto del formato non desse già.

## Decisione

### 1. Protocollo

1. Il coordinatore invia `PREPARE(T, operazioni)` alla coda del writer di ogni partecipante.
2. Il writer verifica expected-version e versioni in sospeso; in caso di conflitto risponde
   `abort` (senza attesa). Altrimenti appende i record con flag *prepared* e `stamp = TXID`
   nel lotto aperto e registra gli **intenti** nella tabella delle versioni in sospeso. Tutte
   le operazioni di T sulla Serie stanno in **un** lotto: il SEAL le rende atomiche. Quando
   il lotto è durevole risponde `prepared`.
3. Il coordinatore, ricevuti tutti i `prepared`, accoda `DECISION(T, partecipanti)` al writer
   logico di `multiserie.log`; alla chiusura del lotto T riceve il suo **CSN**, che resta in
   volo ([ADR-0038](0038-orizzonte-di-visibilita.md)). Quando il lotto è durevole T è
   **committed** (INV-T3) e il coordinatore invia `OUTCOME(T, csn)` ai partecipanti.
4. Il writer, all'`OUTCOME`: pubblica le versioni di T nell'indice con quel CSN, toglie gli
   intenti, appende il record `OUTCOME` al lotto aperto e risponde `applicato`; quando il
   lotto è durevole risponde `esito durevole`.
5. Ricevuti tutti gli `applicato`: il CSN esce dall'orizzonte e il coordinatore **conferma
   il client** (INV-V5). Ricevuti tutti gli `esito durevole`: la decisione è
   **dimenticabile**.

### 2. Abort senza traccia

Con *presumed abort* l'assenza di una decisione COMMIT **è** l'abort. Quindi:

- `multiserie.log` contiene solo record `DECISION`, e ogni DECISION è un COMMIT;
- se un partecipante risponde `abort` o non risponde entro il limite, il coordinatore invia
  `ABORT(T)`: il writer toglie gli intenti e non scrive nulla; i record prepared restano nel
  segmento, senza esito, e sono morti.

### 3. Segmenti autosufficienti (INV-S7)

**La rotazione dell'`ACTIVE` attende che la Serie non abbia intenti pendenti.** Poiché
l'`OUTCOME` è appeso nello stesso `ACTIVE` che contiene i record prepared, e l'attesa è
limitata dal tempo massimo di una transazione, ne discende:

> in un segmento `CLOSED`, un record prepared è committed se e solo se il suo `OUTCOME` è
> nello stesso segmento, oppure — per un segmento chiuso da un recovery — il suo esito è nel
> record di chiusura del manifest. Altrimenti è abortito.

Un segmento chiuso si interpreta da solo: senza `multiserie.log`, senza altri segmenti. Se
l'`ACTIVE` raggiunge la dimensione massima con intenti ancora pendenti, il writer rifiuta
nuove scritture (`resource-exhausted`) finché non si risolvono.

Conseguenze dirette:

- hint e indici, scritti dopo la chiusura, sono sempre **risolti** (CSN definitivo);
- CLEAN e MERGE riscrivono i record prepared committed come record ordinari con il loro CSN e
  **non copiano mai** un `OUTCOME`: l'output di una compaction contiene solo record risolti;
- nessun tracciamento tra segmenti.

### 4. Recovery

1. Si legge `multiserie.log`: la tabella delle decisioni.
2. Per ogni Serie, nell'`ACTIVE` trovato: un record prepared con `OUTCOME` nel segmento è
   committed; senza `OUTCOME`, è committed se la tabella contiene T, altrimenti abortito. Gli
   esiti COMMIT ricavati dalla tabella sono scritti nell'EDIT che chiude il segmento
   ([ADR-0040](0040-manifest-a-record-unico.md)): da quel momento l'esito è durevole nel
   partecipante.
3. Quando ogni partecipante di T ha l'esito durevole, la decisione è dimenticabile. Al
   termine del recovery `multiserie.log` è riscritto con le sole decisioni che riguardano
   Serie non aperte (`FAULTED`).

### 5. `multiserie.log`

Log di lotti sigillati ([ADR-0037](0037-lotto-sigillato.md)) con un writer logico proprio
dell'Archivio e group commit. Compattazione: nuovo file con le decisioni non dimenticabili,
rinomina atomica. Se il flush di una decisione fallisce l'Archivio passa in `MULTI-DISABLED`:
l'esito di T è ignoto al processo, i suoi intenti restano fino al riavvio, il suo CSN è
annullato nell'orizzonte.

Pattern: 2PC *presumed abort* (Mohan, Lindsay, Obermarck: l'abort non si registra); esito
registrato nel partecipante per poter dimenticare la decisione; conferma dopo l'applicazione
(Percolator conferma dopo il commit del primario; qui l'applicazione è in memoria).

## Conseguenze

- Tre record in meno (PREPARE, decisione ABORT, OUTCOME ABORT) e un campo in meno nella
  decisione; una transazione abortita non costa alcuna scrittura dopo il PREPARE.
- Dopo la conferma, la transazione è visibile a ogni lettura successiva.
- La rotazione può ritardare di qualche millisecondo; un segmento può superare di poco il
  target.
- Latenza di commit invariata: flush dei PREPARE, flush della decisione, applicazione in
  memoria.

## Alternative considerate

- *OUTCOME in un segmento successivo con riferimento al segmento dei record prepared:* regge,
  ma obbliga la compaction a sapere quali segmenti esistono ancora per decidere se un OUTCOME
  serve.
- *Conservare le decisioni finché esiste il segmento dei record prepared:* `multiserie.log`
  crescerebbe con i segmenti freddi.
- *Conferma alla decisione durevole (ADR-0021):* un GET dopo la conferma può non vedere la
  transazione.

## Valutazione

- Rischi: RSK-05 chiuso sul progetto; RSK-06 invariato.
- Verifica: FI-03, FI-04, FI-05, FI-12; modello in SPK-07 con crash in ogni passo, rotazione
  concorrente, CLEAN del segmento che contiene un OUTCOME, rigenerazione dell'hint.
