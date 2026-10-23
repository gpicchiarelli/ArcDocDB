# ADR-0001 — Common Lisp/SBCL; solo Common Lisp per ora

- **Stato:** Accettata
- **Data:** 2026-10-01
- **Rapporto con la specifica:** registra la scelta di linguaggio della specifica ed **emenda**
  la sezione «SIMD e ottimizzazioni native» (vedi Decisione, punto 2)
- **Riferimenti:** [15 Ottimizzazioni native](../15-ottimizzazioni-native.md), INV-X3

## Contesto

La specifica chiede un database «scritto principalmente in Common Lisp, con SBCL come
implementazione di riferimento», e ammette per gli hot path estremi operazioni specifiche di
SBCL, funzioni foreign, C/C++ o Rust.

Il 2026-10-01, durante la strutturazione del progetto, l'autore ha deciso che per ora il
progetto sia **solo Common Lisp**.

## Decisione

1. Il linguaggio del progetto è Common Lisp; SBCL è l'implementazione di riferimento.
2. **Per ora tutto il codice del repository è Common Lisp**: nessun componente in C, C++ o
   Rust, nemmeno per gli hot path. La possibilità prevista dalla specifica è sospesa.
3. Le estensioni e i contrib di SBCL sono ammessi.
4. Il vincolo si riapre solo con un nuovo ADR, sostenuto da una misura che mostri un hot path
   non risolvibile altrimenti.

## Conseguenze

- Un solo linguaggio, un solo modello di memoria, nessun confine foreign sul hot path.
- Primitive che altrove si prenderebbero da librerie C (checksum, hash, compressione, I/O
  asincrono) vanno scritte in Common Lisp o ottenute dalle facility di SBCL.
- Il comportamento del GC di SBCL diventa un vincolo di progetto: strutture compatte, nessuna
  allocazione sul hot path.
- Da chiarire: se sono ammesse librerie Common Lisp di terze parti (QA-22).

## Alternative considerate

- *Nucleo in C/Rust con logica in Lisp:* scartata dalla decisione dell'autore; rinviabile.
- *Altra implementazione Common Lisp:* SBCL è indicata dalla specifica come riferimento.

## Valutazione

- Rischi: RSK-01 (GC), RSK-16 (primitive senza codice foreign), RSK-11 (piattaforme).
- Verifica: SPK-02 (GC), SPK-01 (indice), SPK-03 e SPK-05 (I/O), SPK-08 (codice generato).
- Porterebbe a rivedere la decisione: pause del GC incompatibili con l'obiettivo di P99 anche
  nella configurazione migliore; un hot path misurato fuori target senza rimedio in Common
  Lisp.
