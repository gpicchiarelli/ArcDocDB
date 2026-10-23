# ADR-0060 — Caricamento portabile del backend CRC32C

- **Stato:** Accettata per l'integrazione autorizzata del 2026-10-23
- **Data:** 2026-10-23
- **Riferimenti:** REQ-FOR-003, REQ-AFF-004;
  [ADR-0017](0017-piattaforma-e-io.md), [ADR-0059](0059-crc32c-arm64-sbcl.md)
- **Rapporto con le decisioni precedenti:** precisa il caricamento di ADR-0059;
  algoritmo, formato e perimetro dell'accelerazione restano invariati.

## Contesto

La selezione runtime del software non basta a garantire la portabilità:
compilare VOP ARM su una piattaforma o versione SBCL non qualificata può
fallire prima della selezione. Linux x86-64 resta la piattaforma di riferimento.
Il guadagno misurato su macOS ARM64 non qualifica altre CPU o sistemi.

## Decisione

Un bootstrap Lisp comune ad ASDF e al loader di misura calcola una feature
privata di compilazione. La abilita soltanto per SBCL 2.6.9, ARM64,
macOS, 64 bit e little endian. Su ogni altra combinazione non richiede
SB-SIMD e non legge le definizioni VOP o i riferimenti NEON. La feature
descrive la compatibilità del compilatore, non la capacità della CPU.
Il probing OS e NEON rimane necessario prima di scegliere il kernel.

La feature pubblica di avvio `:arcdocdb-crc32c-software`, impostata prima
di caricare il sistema, forza il software anche sull'host qualificato.
Serve per diagnosi, test differenziali e rollback; nessun cambio a caldo
durante il servizio. Il bootstrap rimuove eventuali feature native obsolete.

Le decisioni di compatibilità, validità della risposta OS e selezione del
kernel sono funzioni pure con test per ciascuna condizione. Il percorso
GET continua a leggere soltanto il kernel già scelto. Nessuna dipendenza
checksum foreign e nessuna variazione dei dati persistenti.

## Verifica e limiti

Build e suite complete in due processi freschi, normale e software forzato;
test di isolamento del reader senza package SB-SIMD e matrice sintetica di
OS, architettura e versione. Questi test locali non sostituiscono una run
Linux. La CI esistente esegue il prodotto su Linux x86-64 e macOS ARM64;
le prestazioni hardware pubblicate rimangono riferite all'M4 locale.

Linux ARM64, macOS x86-64, altri SBCL e CPU senza CRC32C usano il software
per il checksum; questo non estende a nuovi sistemi il supporto dell'intero
motore. Windows non è una piattaforma del motore POSIX attuale. Un futuro
backend SSE4.2 o Linux ARM richiederà prove e qualifica proprie.
