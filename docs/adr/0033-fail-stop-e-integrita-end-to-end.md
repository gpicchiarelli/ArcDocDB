# ADR-0033 — Fail-stop, integrità end-to-end, politica degli errori

- **Stato:** Accettata
- **Data:** 2026-10-03
- **Rapporto con la specifica:** nessuna emenda; specifica **come** si realizzano «recovery
  crash-safe» e «nessun dato committed deve andare perso» in presenza di guasti; precisa
  [ADR-0019](0019-durability-e-group-commit-pipelined.md) per il livello `:async`.
- **Riferimenti:** [analisi dei guasti](../affidabilita/analisi-dei-guasti.md), INV-A1…INV-A8,
  INV-F1

## Contesto

La specifica descrive il comportamento corretto e il recovery dopo un crash; non descrive
come il sistema reagisce a guasti che **non** sono un arresto pulito: errori di I/O, bit-rot,
scritture parziali, esaurimento di risorse, difetti interni. Un sistema critico deve avere per
ciascuno una risposta definita (ADR-0031).

## Decisione

### 1. Stati di salute

| Livello | Stati |
|---|---|
| Serie | `HEALTHY` · `DEGRADED` (uno o più segmenti in quarantena) · `FAULTED` |
| Archivio | `HEALTHY` · `MULTI-DISABLED` (`multiserie.log` in guasto) · `FAULTED` (Registri in guasto) |

- `FAULTED`: la Serie non accetta né conferma alcuna operazione; si riparte solo con il
  recovery (o con la verifica offline). Lo stato su disco non viene toccato (append-only).
- `DEGRADED`: le letture dei documenti nei segmenti in quarantena rispondono
  `corruption-detected`; il resto della Serie funziona; il CLEAN e il MERGE saltano i segmenti
  in quarantena.
- Ogni transizione è un evento registrato e una metrica.

### 2. Errori di scrittura e di flush: fail-stop, mai ritentati (INV-A1)

Un errore di `write`, `fdatasync`/`F_FULLFSYNC`, `rename` o sincronizzazione della directory
porta la Serie (o l'Archivio per `multiserie.log` e Registri) in `FAULTED`. **Non si ritenta
e non si ignora.** Motivo: dopo un fallimento di `fsync` lo stato delle pagine nella cache del
sistema operativo non è definito; un nuovo `fsync` può riuscire senza che i dati siano
durevoli (difetto di PostgreSQL scoperto nel 2018). Nessuna conferma è mai data per un lotto
il cui flush non è riuscito.

`ENOSPC`: si previene con una **riserva di spazio** — sotto la soglia configurata di spazio
libero il sistema rifiuta le nuove scritture con `resource-exhausted` (backpressure), così lo
spazio per compaction e recovery resta garantito. Un `ENOSPC` che si verifica comunque su una
scrittura è trattato come errore di scrittura (`FAULTED`).

### 3. Verifica in lettura (INV-A2)

Ogni record letto — da disco **e dalla cache** — è verificato prima di essere restituito:
CRC32C del record, corrispondenza di chiave, versione e CSN con la entry dell'indice che lo ha
indicato. Una verifica fallita non restituisce mai il dato: `corruption-detected`, il segmento
va in quarantena (`DEGRADED`), l'evento è registrato. Il costo (CRC32C in Common Lisp tipizzato)
è accettato (ADR-0031 §5) e misurato da SPK-09.

### 4. Recovery: coda troncata o corruzione a metà log

Alla lettura del segmento `ACTIVE`, il primo record con lunghezza incoerente o CRC errato
fissa un **punto di arresto**. Poi il recovery esegue una **scansione di risincronizzazione**
nel resto del segmento, byte per byte, cercando un record valido (intestazione plausibile,
CRC corretto) con CSN maggiore dell'ultimo noto:

- nessun record valido dopo il punto di arresto → **coda troncata** da un crash: si tronca e
  si prosegue;
- un record valido dopo il punto di arresto → **corruzione a metà log**: i dati committed
  potrebbero essere dopo; la Serie va in `FAULTED` e non si tronca nulla. Serve la decisione
  dell'operatore (verifica offline, restore).

L'errore possibile della scansione è nella direzione sicura: un falso positivo (record «valido»
trovato per caso, probabilità ≈ 2⁻³² per posizione) produce un rifiuto di apertura, mai una
perdita silenziosa. Un record non valido in un segmento **CLOSED** o in `control.log`,
`multiserie.log` è sempre corruzione (non c'è una coda da troncare): quarantena del segmento
(`DEGRADED`) o `FAULTED` per i log di controllo.

### 5. Recovery idempotente (INV-A7)

Il recovery può essere interrotto e rieseguito in qualsiasi punto: lo stato finale è lo
stesso. Ne consegue che ogni passo del recovery è descritto da record durevoli del control log
o da file con rinomina atomica, mai da stato in memoria.

### 6. Scrubbing (INV-A6)

Un processo in background, a banda limitata e a priorità inferiore al CLEAN, rilegge i segmenti
chiusi: CRC di ogni record, coerenza di hint, indici e Bloom con il segmento, presenza dei file
elencati dal control log. Un ciclo completo è obiettivo **entro 7 giorni**; lo scarto è una
metrica con allarme. Un errore rilevato porta il segmento in quarantena **prima** che una
lettura ne abbia bisogno.

### 7. Verificatore offline `arcdocdb-verify`

Strumento in Common Lisp che apre un Archivio **in sola lettura** e verifica tutto ciò che è
verificabile offline: formati e CRC, coerenza di control log, segmenti, hint, indici,
`multiserie.log`, catalogo e directory. Esce con codice non nullo e un rapporto dettagliato.
Serve all'operatore, al backup e ai test (oracolo dopo ogni crash simulato).

### 8. Condizioni ed errori (INV-A4)

- Gerarchia di condizioni: `arcdocdb-error` ← `corruption-detected`, `io-fault`,
  `resource-exhausted`, `conflict`, `invalid-request`, `snapshot-too-old`,
  `serie-faulted`, `invariant-violation`.
- Vietati `ignore-errors` e i gestori che catturano `error`/`serious-condition` senza
  rilanciare o registrare e portare in uno stato definito. Un gestore generico ammesso solo ai
  confini (richiesta, worker) con registrazione e transizione di stato.
- **Le asserzioni sugli invarianti interni restano sempre attive in produzione.** Una
  violazione in codice C1 porta la Serie in `FAULTED` (`invariant-violation`), non nel
  proseguire. Un crash del processo è riservato all'esaurimento dello heap o a un errore fatale
  del runtime.

### 9. Limiti di risorse (INV-A8)

Ogni risorsa è limitata da un valore configurato **e controllato**: lunghezza di ogni coda,
dimensione di ogni buffer, richiesta massima, numero di connessioni, numero e durata degli
snapshot, tentativi di ogni ciclo, profondità di ogni ricorsione, memoria dello heap. Il
superamento produce un rifiuto esplicito (`resource-exhausted`), mai un degrado non definito.
L'esaurimento dello heap si previene con un bilancio di memoria all'avvio e con soglie di
rifiuto ben sotto il limite.

### 10. Livello `:async`

`:async` **non è mai il default**, richiede una scelta esplicita per Serie registrata nel
catalogo, è **vietato per Registri e per i partecipanti a transazioni multiserie**, è escluso
da INV-D1 (già in ADR-0019) ed è una metrica di sistema («Serie in `:async`»).

### 11. Lock dell'Archivio

All'apertura il processo acquisisce un **lock esclusivo** sul file `LOCK` dell'Archivio e lo
tiene fino alla chiusura: una seconda istanza che apra lo stesso Archivio fallisce
immediatamente.

Pattern: fail-stop (Gray, 1985), checksum end-to-end (ZFS, RocksDB, TigerBeetle), scrubbing
(ZFS), asserzioni sempre attive e recovery deterministico (TigerBeetle), `fsync` fatale
(PostgreSQL post-2018).

## Conseguenze

- La Serie si ferma più spesso (fail-stop) di quanto un sistema orientato alla disponibilità
  farebbe: è voluto (ADR-0031 §1).
- Costo in prestazioni di CRC in lettura e scrubbing: misurato (SPK-09), accettato.
- Ogni stato di errore è un elemento della macchina a stati da verificare (FI, modello).

## Alternative considerate

- *Ritentare `fsync` con backoff:* scartata (difetto noto).
- *Troncare sempre alla prima anomalia:* scartata: perderebbe in silenzio dati committed in
  caso di corruzione a metà log.
- *Restituire il dato anche se il CRC fallisce, con avviso:* scartata (priorità 2).

## Valutazione

- Rischi: RSK-18, RSK-19.
- Verifica: [analisi dei guasti](../affidabilita/analisi-dei-guasti.md) (ogni guasto → test);
  FI-01, FI-02, FI-10; fuzzing dei decoder; test di corruzione deliberata di ogni file.
