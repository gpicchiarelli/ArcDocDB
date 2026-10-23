# Item CBOR con testate minime — prima lettura C1

Lettura del coordinatore indipendente dall'autore del prodotto, sul diff
congelato prima delle campagne. Riferimento: package `9c9edc4`, scanner
`e3d7d77`, wrapper minimo `f1afe79`. I risultati runtime sono separati.

| Punto della checklist | Riscontro e limite |
|---|---|
| 1. Requisiti e ADR | REQ-LIM-001/002, AFF-004/008 e ADR-0014/0048; incremento locale del codec, senza chiusura dei gate. |
| 2. Invarianti | INV-F1/A8/P6: input immutabile, budget prima dell'ammissione, scratch esclusivo; progresso e postcondizioni del kernel preservati. |
| 3. Errori | Preflight invariato prima del reset; scelta del lettore prima di contesto/nodi; minimalità precede payload/depth. Drain prima della lettura della coda; fallback vuoto dal lettore base. Nessun nuovo handler. |
| 4. Limiti | Repeat SPAN, drain102 e stack102 invariati; nessun nuovo ciclo, ricorsione o attesa. Ogni passo avanza almeno un byte o segnala errore. |
| 5. Heap | Nessun nuovo oggetto, closure, callback o parametro keyword dinamico; solo booleano posizionale e chiamate dirette. Misura locale e sensore positivo ancora necessari. |
| 6. Uscita | Tre valori della funzione risultato, dopo le postcondizioni su cursore/nodi/profondità/stato; nessuna vista o copia del payload. |
| 7. Decisioni | Tre compound preservati e selezione semplice MINIMAL; tabella confrontata con righe effettive. Nessuna attestazione MC/DC o esclusione. |
| 8. Proprietà | Buffer del chiamante; un solo worker possiede lo scratch. Nessuna mutazione globale, condivisione nuova o buffer trattenuto. |
| 9. Integrazione | ASDF predisposto per wrapper e suite dedicata; la build attende il congelamento del corpus. Build/lint/trace/check restano da registrare. |
| 10. Standard | safety3, FTYPE/docstring/REQ; funzioni entro 60 righe. Tre funzioni non banali preservano almeno due controlli attivi; wrapper deleganti banali. |
| 11. Parallelismo | Nessuna scrittura, attesa o lock fra Serie; buffer/scratch indipendenti nelle prove con due worker. La sovrapposizione temporale non prova scaling. |
| 12. Durabilità | Nessuna scrittura, eliminazione o pubblicazione durevole del kernel; punto di atomicità non applicabile. |

Il corpo della scansione generica è spostato senza cambiare ordine delle
operazioni. Il wrapper generico passa NIL; quello minimo passa T. Input,
UTF-8, stack, item e lettori header sono byte-identici alla base.
Nessun rilievo statico aperto. Compilazione, regressioni, corpus cieco,
copertura, mutazioni e heap devono ancora confermare il comportamento.
