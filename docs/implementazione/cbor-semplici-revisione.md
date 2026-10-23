# Prima lettura C1 della scrittura dei valori semplici CBOR

Lettura statica del 2026-10-11, **prima della compilazione e delle campagne**.
Il revisore non ha scritto il prodotto né le prove e non ha letto il nuovo
corpus cieco. Ha avviato prima del prodotto la preparazione dell'auditor
C4 dei dati del benchmark, dal contratto e dal driver congelati; il freeze
dell'auditor segue quello del prodotto. Non ha eseguito l'auditor.
Questa è la prima lettura C1; non sostituisce la seconda lettura o le prove.

Base Git: `d155db3f977677fa95280f59c23fbe46a5e116d2`.
Sorgente letto: `src/codec/cbor-simple-write.lisp`, blob
`58c7a3a040ec814fae2dfe636f569b5623cba8f0`.
[Metodo preregistrato](cbor-semplici-metodo.md), blob
`e8864f7c0124f86cebdcdbcb2449800e078e1cc8`.
Export `0a75ef778c3d5ea490ec0a61f11bf6c65a3183ee`,
ASDF `2a4f3cf6dd800e5e9c3d624c23971bec352d7988`,
catalogo requisiti `19223d1767a6b7eebb9636d99cea7d898560cbd2`.

## Esito statico

Nessun difetto funzionale o correzione obbligatoria individuato sul blob
letto. Il prodotto rispetta il contratto raw MT7: 0..23 usa E0+VALUE e
32..255 usa F8 seguito da VALUE. Il LOGIOR alla riga 47 coincide con la
somma nel dominio diretto, perché i bit del codice non intersecano E0.
Il TYPEP alla riga 17 rifiuta i codici riservati 24..31 e ogni valore
fuori dominio, compresi T/NIL, senza introdurre conversioni applicative.
Undefined resta il codice wire 23; nessuna semantica viene assegnata ai
codici non assegnati.

Il helper verifica tipo e range prima di LENGTH e della sottrazione;
verifica il codice prima del THE U8 nel percorso pubblico. La capacità
viene controllata alla riga 41 prima di calcolare NEXT e CURSOR e prima
di ogni AREF in scrittura. Da SIZE<=END-START segue START+SIZE<=END,
quindi NEXT e CURSOR restano index. Lo span valido vuoto segnala capacità
insufficiente soltanto dopo la verifica del codice.

Le guardie di span, footprint e avanzamento restano attive. Le ultime due
asserzioni pubbliche verificano NEXT crescente/entro END e CURSOR=NEXT.
Il primo write è alla riga 47; il secondo, soltanto per SIZE2, alla 49.
Tutti gli errori pubblici precedono entrambi. La guardia finale può fallire
dopo una mutazione interna: il contratto conserva fail-stop senza rollback.

## Dimensione e complessità

Conteggio sintattico conservativo: un percorso iniziale, uno per controllo
IF/WHEN/UNLESS e uno per ciascuna condizione AND aggiuntiva. Non comprende
l'espansione di TYPEP, della sua unione di tipi o dei confronti primitivi.
Le righe includono DEFUN e docstring.

| Funzione | Righe | Percorsi |
|---|---:|---:|
| `check-input-simple-cbor-write` (10–23) | 14 | 7 |
| `scrivi-semplice-cbor-minimo` (28–53) | 26 | 8 |

Entrambe rispettano COD-12 e COD-13. Nessun ciclo o ricorsione: un item
completo occupa uno o due byte e ogni chiamata modifica al massimo due
posizioni. L'inventario delle decisioni composte è curato separatamente
dall'autore; questa conta non attesta copertura o MC/DC.

## Checklist C1

| Voce | Prima lettura |
|---|---|
| 1. Requisiti e ADR | REQ-CBR-003 e AFF-004/008 sono indicati; il dominio locale è coerente con RFC 8949 §3.3 e ADR-0014. ADR-0048 mantiene budget e profilo documentale superiori. |
| 2. Invarianti | INV-F1/P6 nel requisito; destinazione esclusiva, capacità half-open, codice ben formato, byte esterni invariati e bound2 nel prodotto. Prove falsificanti pendenti. |
| 3. Errori | Range → codice → capacità, come preregistrato. INVALID-ARGUMENT e RESOURCE-EXHAUSTED con offset NIL derivato dalla condizione base e senza mutazione. INVARIANT-VIOLATION interno propagato al proprietario, senza rollback. |
| 4. Limiti | Nessun ciclo, ricorsione, attesa o thread creato; bound fisso di due byte. END è il limite effettivo; il suffisso fisico non aumenta la capacità. |
| 5. Heap | Sul successo non compaiono costruttori, closure, AST, float o u64. Cursori index e codice u8; aritmetica limitata prima dell'uso. Nessuna allocazione prevista dal sorgente; heap zero richiede misura locale con sensori e non è attestato. |
| 6. Dati verificati | Tutti gli ingressi freddi sono verificati prima dei THE e degli accessi. Il modulo restituisce un solo NEXT con VALUES e scrive il codice raw; non promette validazione semantica del documento. |
| 7. Decisioni composte | AND del range e del footprint presenti; range concatenato e unione TYPEP distinti dalle decisioni AND/OR esplicite. Inventario, casi indipendenti e copertura restano da verificare separatamente. |
| 8. Proprietario | OWNER/SHARED espliciti: destinazione del chiamante in esclusiva fino al ritorno, soli scalari locali. Il modulo non verifica l'esclusività né condivide stato per operazione. |
| 9. Integrazione | Export alla riga 11 del package; componente ASDF seriale dopo le dipendenze; nuova suite registrata senza rimuovere le precedenti. Requisito nel catalogo; matrice, compilazione e MAKE CHECK pendenti. |
| 10. Regole | FTYPE completi, safety3, docstring pre/post/errori, REQ per definizione, guardie senza effetti collaterali. Nessun gestore generico, costrutto vietato o deviazione statica individuato. Compilazione/lint non eseguiti. |
| 11. Parallelismo | Nessun lock, attesa, I/O o scrittura condivisa tra Serie introdotto. Worker distinti possono usare destinazioni private e piani immutabili; concorrenza reale e scaling non sono dimostrati dalla lettura. |
| 12. Durabilità | Nessuna pubblicazione, persistenza o eliminazione. Le due scritture non costituiscono pubblicazione atomica; il chiamante mantiene proprietà e confine fail-stop per eventuali guasti interni. |

## Verifiche ancora necessarie

Il diff dei kernel codec già presenti e delle fondazioni non mostra
modifiche; nel package è aggiunto soltanto l'export della nuova primitiva.
Questa lettura non rinnova la qualifica delle dipendenze e non ha
consultato le prove cieche o eseguito compilazione, test, benchmark,
coverage, mutazioni o self-test degli strumenti.

Restano seconda lettura C1, compilazione senza warning/style-warning,
corpus e concorrenza, misure con sensori, mutazioni, coverage grezza e
verifica delle decisioni composte, audit dei dati, matrice e MAKE CHECK.
Non sono attestati MC/DC, 100% di copertura, heap zero, gate C1 chiuso o
qualifica del documento completo e del motore.
