# ADR-0012 — SIMD solo dove i benchmark lo giustificano

- **Stato:** Accettata
- **Data:** 2026-10-01
- **Precisazione:** 2026-10-22, valutazione sistematica delle varianti SIMD utilizzabili in sicurezza.
- **Rapporto con la specifica:** registra una decisione della specifica («SIMD e
  ottimizzazioni native»), nel quadro di [ADR-0001](0001-common-lisp-sbcl.md)
- **Riferimenti:** [15 Ottimizzazioni native](../15-ottimizzazioni-native.md), INV-X1

## Contesto

Molte operazioni di un database si prestano al SIMD, ma il codice specializzato costa in
portabilità e manutenzione, e ottimizzare prima di misurare porta spesso a ottimizzare il
punto sbagliato.

## Decisione

Le prescrizioni seguenti sono criteri obbligatori per introdurre un kernel nel motore.
Gli spike esistenti non attestano dispatcher, ripiego o qualificazione del prodotto.

- Il sistema è progettato per essere SIMD-friendly: strutture compatte, typed arrays,
  dichiarazioni di tipo, poche allocazioni, accessi sequenziali.
- Per ogni hot path individuato dalla profilazione si valutano sistematicamente tutte le
  varianti SIMD disponibili e utilizzabili in sicurezza sulle piattaforme concordate:
  Linux x86-64 di riferimento e macOS ARM64 di sviluppo ([ADR-0017](0017-piattaforma-e-io.md)).
  Si adotta la variante che i benchmark dimostrano utile per operazione e dimensione;
  la larghezza vettoriale maggiore non è da sola un criterio di scelta.
- Candidati: operazioni su bitmap, Bloom filter, scansioni, confronti, filtri, parsing,
  hashing, compressione.
- Per ora gli strumenti ammessi sono Common Lisp tipizzato e le operazioni specifiche di SBCL
  (ADR-0001).
- La selezione verifica le funzionalità effettivamente utilizzabili da CPU, sistema operativo
  e runtime SBCL prima di eseguire il kernel. Una variante assente o non qualificata usa il
  riferimento scalare, sempre eseguibile e forzabile nei test; gli errori di dati o di
  invarianti seguono la stessa semantica e non vengono nascosti dal ripiego.
- Ogni variante mantiene i controlli di tipo e limiti, con `safety 3` predefinito e le sole
  eccezioni già previste da [ADR-0034](0034-policy-di-compilazione-e-standard-di-codifica.md).
  Nessun accesso vettoriale oltrepassa la finestra logica valida; code e allineamento hanno
  percorsi definiti e verificati, senza leggere padding o byte estranei.

## Conseguenze

- Il layout dei dati si decide subito in funzione di queste ottimizzazioni; le ottimizzazioni
  stesse arrivano dopo.
- Ogni primitiva ottimizzata ha una versione portabile di riferimento, usata anche per
  verificarne la correttezza con un oracolo differenziale indipendente; test e benchmark
  possono forzare ciascun backend e il percorso scalare.
- Serve un'infrastruttura di benchmark prima di qualunque ottimizzazione.
- Oracoli, dataset e metodo di confronto sono comuni alle due piattaforme; risultati,
  disassemblati e costi di selezione devono essere raccolti separatamente per ciascuna
  prima della promozione. Un backend
  `unsupported` è distinto da una verifica riuscita e non qualifica la piattaforma.

## Alternative considerate

- *SIMD pervasivo fin dall'inizio:* scartato; contrario al principio di misura.
- *Nessun SIMD:* rinuncia a guadagni noti su bitmap e scansioni.

## Valutazione

- Rischi: RSK-11, RSK-16.
- Verifica: SPK-08 (codice generato e strumenti disponibili per architettura).
- Piattaforme decise da ADR-0017 (QA-19); la qualificazione dei backend resta subordinata
  a prove reali su ciascuna piattaforma. Gli esperimenti SPK-08 non promuovono il motore
  né altre estensioni SIMD non verificate.
