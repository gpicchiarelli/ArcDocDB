# ADR-0021 — 2PC con writer non bloccante: intenti no-wait, record OUTCOME, troncamento di `multiserie.log`

- **Stato:** Accettata; **sostituita in parte da [ADR-0041](0041-multiserie-segmenti-autosufficienti.md)**: nessun record PREPARE né esito ABORT, OUTCOME nello stesso segmento dei record prepared, conferma dopo l'applicazione, `multiserie.log` con il solo record DECISION. Restano: writer non bloccante, intenti senza attesa, *presumed abort*.
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-07 e QA-08; realizza [ADR-0006](0006-transazioni-multiserie-2pc.md)
- **Riferimenti:** [architettura](../architettura.md#transazioni-multiserie),
  [formati su disco](../formati-su-disco.md#multiserielog), INV-T3, INV-T4, INV-P3

## Decisione

### Protocollo

1. Il coordinatore (il worker che serve la richiesta) invia a ogni Serie partecipante
   `PREPARE(T, operazioni)` tramite la coda del writer.
2. Il writer, nel lotto: verifica expected-version e **intenti**; in caso di conflitto
   risponde `abort`; altrimenti appende i record dati con flag *prepared* e CSN 0, poi un
   record `PREPARE T`; registra gli intenti `chiave → T`; il lotto va a flush (`:group` o
   più forte); al completamento risponde `prepared`. **Il writer non attende la decisione.**
3. Il coordinatore, ricevuti tutti i `prepared`, appende la decisione a `multiserie.log` (group
   commit). Quando è durevole: assegna il CSN, inserisce `T` nell'insieme «in applicazione»,
   conferma il client (INV-T3), invia `OUTCOME(T, COMMIT, csn)` ai partecipanti.
4. Il writer, all'`OUTCOME`: aggiorna l'indice (versione, CSN), rimuove gli intenti, appende
   un record `OUTCOME T` nel segmento (flush con il lotto successivo), risponde.
5. Quando tutti i partecipanti hanno reso durevole l'`OUTCOME`, il coordinatore rimuove `T`
   da «in applicazione» e lo segna **dimenticabile**.
6. Se un partecipante risponde `abort` o non risponde entro il timeout: decisione `ABORT`,
   stesso percorso; gli intenti si rimuovono e i record restano morti nel segmento.

### Stato PREPARED

- **Reader (read committed e snapshot):** vedono la versione precedente. Un intento non è
  mai visibile.
- **Scritture concorrenti sullo stesso documento (single-Series o multiserie):** il writer
  risponde subito `conflict` (**no-wait**). Nessuna attesa dentro il writer.
- Un conflitto single-Series contro un intento è indistinguibile per il client da un
  conflitto di versione: ritenta.

### Recovery

- *Presumed abort.* Al riavvio il Recovery Manager carica le decisioni da `multiserie.log`.
  Un `PREPARE T` senza `OUTCOME` nel segmento si risolve: COMMIT se la decisione COMMIT è
  nel log, altrimenti ABORT. L'`OUTCOME` mancante viene appeso.
- Il coordinatore non scrive nulla prima della decisione: senza decisione, nessun client ha
  avuto conferma.

### `multiserie.log`

- Record `{seq, tipo: COMMIT|ABORT|CHECKPOINT, txid, csn, partecipanti, CRC32C}`.
- Troncamento: quando le decisioni dimenticabili superano una soglia, il coordinatore scrive
  `multiserie.log.new` con un `CHECKPOINT` e le sole decisioni non dimenticabili, flush,
  rinomina sopra l'originale, `fsync` della directory. Il file resta uno.

Pattern: 2PC presumed-abort (Mohan et al.); intenti con no-wait (Percolator usa lock
pendenti; qui senza attesa perché il writer è unico); log delle decisioni compattato per
checkpoint.

## Conseguenze

- La Serie non si ferma mai per una multiserie: costa due record nel lotto (PREPARE e
  OUTCOME) e una voce di intento.
- Latenza di commit: flush dei PREPARE + flush della decisione.
- Record morti nei segmenti per le transazioni abortite (recuperati dal CLEAN).

## Alternative considerate

- *Attesa (wait) sugli intenti:* code di attesa dentro il writer e possibilità di deadlock tra
  Serie.
- *Decisione scritta anche nel segmento di ogni partecipante prima della conferma:* un flush
  in più per partecipante senza beneficio: la decisione nel log unico basta.

## Valutazione

- Verifica: FI-03, FI-04, FI-05, FI-12; modello in SPK-07 con crash in ogni passo.
