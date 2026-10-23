# ADR-0059 — CRC32C ARM64 generato da Common Lisp/SBCL

- **Stato:** Accettata per l'implementazione autorizzata del 2026-10-23
- **Data:** 2026-10-23
- **Riferimenti:** REQ-FOR-003, REQ-AFF-002, REQ-AFF-004, INV-A3, INV-A4;
  [ADR-0001](0001-common-lisp-sbcl.md), [ADR-0034](0034-policy-di-compilazione-e-standard-di-codifica.md)

## Contesto e prova discriminante

Il [benchmark isolato](../implementazione/get-costi-risultati.md) misura circa
5,8 microsecondi per CRC di 4 KiB. Lo spike preregistrato
[SPK-08 CRC](../../spikes/SPK-08-generated-code/metodo-crc32c.md) confronta
software e istruzioni CRC32C: 6.624 casi con oracolo bitwise, semi, offset e
incrementalità; cinque repliche per dimensione. Il kernel a blocchi di 16 B
misura circa 0,73 microsecondi a 4 KiB, con heap osservato zero. La variante
srotolata a 64 B misura circa 0,81 microsecondi: non viene scelta. Entrambe
le campagne e il primo errore di API dell'assembler restano conservati.

## Decisione

1. L'API `crc32c` mantiene range, seme/checksum finalizzati, polinomio,
   errori e formato persistente. L'algoritmo slicing-by-8 resta disponibile
   come fallback e riferimento differenziale; è un backend necessario per
   piattaforme senza accelerazione qualificata.
2. Su SBCL 2.6.9, macOS ARM64, il modulo I/O interroga `sysctlbyname`
   (`hw.optional.armv8_crc32`) prima dell'uso del backend. Fallimento,
   feature assente, sistema o versione non qualificati selezionano il
   software. Nessun probing tramite esecuzione di istruzioni potenzialmente
   illegali; nessun processo esterno nel prodotto.
3. Due VOP privati implementano CRC32CX e CRC32CB sui soli registri. La
   codifica delle istruzioni viene emessa in Lisp attraverso l'assembler
   SBCL, con vincoli sui registri e test degli opcode. Il disassembler
   installato non conosce questi mnemonici e mostra i quattro byte.
4. I load a 16 B passano dalle API SB-SIMD NEON con bounds check attivi a
   safety 3. Nessun puntatore/SAP, pinning, array reinterpretato senza
   controlli o sospensione del GC nel checksum. La coda usa `aref` e CRC32CB.
   Il vettore Lisp mantiene la sua vita utile; nessun indirizzo sopravvive
   a un'istruzione o viene conservato tra chiamate.
5. La selezione del kernel avviene al caricamento, prima di avviare reader
   o writer. Un riferimento privato alla funzione resta immutato durante
   il servizio: il GET non interroga OS/CPU e non scrive stato condiviso.
   Caricamenti standalone del solo file software conservano il fallback.
6. Il codice dello spike non è promosso. L'implementazione C1 ha contratti,
   tipi e verifiche propri. Nessun cambiamento a commit, WAL, checksum su
   disco, EBR, cache o garanzie di progresso; nessuna riduzione di safety.

Il rilevamento OS è parte del modulo I/O, pur caricandone la piccola
interfaccia CPU prima delle fondazioni, senza dipendenze circolari.
L'uso di `sysctlbyname` segue il modello dei binding OS esistenti: tutto
il codice del repository resta Common Lisp; nessuna libreria checksum foreign.

## Verifica e limiti

Differenziale pubblico/software/oracolo, lunghezze e offset sui confini dei
blocchi, tutti gli split piccoli, semi arbitrari, corruzioni e range invalidi;
standalone software, build senza warning, test GET/record/WAL esistenti,
allocazioni, compilazione FASL e due letture C1. La verifica complessiva
deve passare prima della consegna. Il controllo dell'oracolo byte per byte
rimane nella suite di integrità; una campagna di throughput distinta lo
sposta fuori dal timing e controlla il risultato dopo ogni finestra.

0,4–0,6 microsecondi per CRC e 2 microsecondi per GET restano obiettivi;
si pubblicano i numeri ottenuti senza sottrazioni dal benchmark storico.
Linux/x86-64 e Linux/ARM64 mantengono il software; l'accelerazione su altre
piattaforme richiede rilevamento e qualifica propri. Versioni SBCL diverse
non attivano il kernel senza una nuova qualifica.

Fonti primarie: [Arm CRC32C](https://support.arm.com/documentation/100069/0609/A64-General-Instructions/CRC32CB--CRC32CH--CRC32CW--CRC32CX?lang=en),
[SBCL ARM64](https://github.com/sbcl/sbcl/tree/master/src/compiler/arm64).
