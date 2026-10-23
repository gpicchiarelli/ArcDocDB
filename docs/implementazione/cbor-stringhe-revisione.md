# Prima lettura C1 della scrittura di stringhe CBOR

Lettura statica del 2026-10-11, **prima delle campagne e della compilazione**.
Il revisore ha letto il contratto e il nuovo prodotto, senza scrivere il
prodotto o le nuove prove e senza leggere il corpus cieco in costruzione.
Non sono stati eseguiti build, test, benchmark, copertura o mutazioni.

Base: `2a0011f9d2bef104b22f7ad1eb86d7e5d60d5e11`.
Sorgente letto: `src/codec/cbor-string-write.lisp`, blob Git
`a2c5c77dd51bff760bff4508e998d94370921eda`.
Contratto: [metodo](cbor-stringhe-metodo.md), blob
`56342dae95caf8705e0b28b3c0ea7ac86fdd8fa0`.

## Esito statico

Nessun difetto funzionale o correzione obbligatoria individuato sul blob
letto. Il sorgente puo essere congelato per le prove preregistrate; questo
esito non attesta compilazione senza avvisi, heap zero, successo del corpus,
copertura, MC/DC o completamento dei gate.

Il preflight verifica destinazione, major, sorgente e budget prima del cast
del payload a u32. Il rifiuto preliminare `span > budget` impedisce che una
sorgente fisicamente grande raggiunga il selettore tipizzato. La testata e
inclusa nel budget, poi viene verificata la capacita dello span destinazione.
Solo dopo si calcola NEXT: dalla capacita verificata segue NEXT <= END e
quindi NEXT resta un index. Lo spazio fisico dopo END non viene utilizzato.

L'overlap riguarda `[START,NEXT)`, compresa la testata, e viene controllato
prima di UTF-8 e di ogni scrittura. Con array simple u8 il caso di memoria
condivisa ammesso dal contratto e lo stesso oggetto array: il confronto EQ
e sufficiente nel dominio dichiarato. Le disuguaglianze strette ammettono
gli intervalli toccanti; il controllo della lunghezza sorgente ammette
anche lo span vuoto, qualunque sia la sua posizione nell'array.

MT3 verifica l'intero span sorgente prima di scrivere la testata e controlla
il conteggio restituito da UTF-8. MT2 non interpreta il contenuto. Lunghezza
e testata usano sempre i byte, non il numero di scalari. Gli errori UTF-8
conservano classe, motivo e offset nella sorgente; gli errori di preflight
hanno offset NIL. Dopo la prima scrittura restano soltanto guardie interne
su dati gia verificati, con fail-stop esterno e senza rollback.

## Lunghezza e complessita

Conteggio sintattico dei percorsi indipendenti: uno iniziale, un incremento
per ciascun controllo di flusso, ciascun AND/OR aggiuntivo e il ciclo LOOP.
Non comprende l'espansione dei controlli dei tipi o dei confronti primitivi.
L'inventario delle decisioni e un artefatto separato curato dall'autore.

| Funzione | Righe DEFUN incluse | Percorsi |
|---|---:|---:|
| `check-span-string-cbor-write` (10-21) | 12 | 6 |
| `check-input-string-cbor-write` (27-53) | 27 | 8 |
| `check-overlap-string-cbor-write` (58-70) | 13 | 7 |
| `copia-stringa-cbor-write` (75-93) | 19 | 8 |
| `scrivi-stringa-cbor-minima` (98-129) | 32 | 5 |

Tutte rispettano COD-12 e COD-13. La copia esegue esattamente SPAN passi,
con SPAN controllato entro 16 MiB e uguale alla lunghezza destinazione.
Le guardie prima del ciclo verificano entrambi i range; quelle successive
verificano fine di lettura e scrittura. Lo span vuoto non legge ne scrive
payload. Il percorso pubblico controlla anche la fine della testata e il
cursore finale restituito dalla copia.

## Checklist C1

| Voce | Prima lettura |
|---|---|
| 1. Requisiti e ADR | REQ-CBR-002, ADR-0014/0048 e AFF-004/008 coerenti con MT2/3, budget dell'item e preflight. Il limite locale non qualifica il documento composito o il contratto della Serie. |
| 2. Invarianti | Budget comprensivo della testata, capacita half-open, sorgente stabile, destinazione esclusiva e assenza di overlap verificati prima della mutazione. Prove falsificanti ancora pendenti. |
| 3. Errori | Ordine conforme al metodo: range destinazione, major, range sorgente, tipo/limite budget, budget payload/item, capacita, overlap, UTF-8. Tutti i rifiuti pubblici precedono la prima scrittura. Gli invarianti interni restano senza rollback. |
| 4. Limiti | Un ciclo di copia con tetto esplicito; UTF-8 gia limitato e chiamato con budget SPAN. Nessuna ricorsione, attesa o creazione di thread. |
| 5. Heap | Nessun costruttore, closure o materializzazione di u64/float/AST nel nuovo successo. Aritmetica su index/u32 entro range gia controllati; chiamata keyword UTF-8 e NTH-VALUE richiedono comunque misura locale. Heap zero non attestato. |
| 6. Dati verificati | MT3 valida tutto UTF-8 prima della testata; MT2 conserva byte arbitrari per contratto. Header e copia ricevono span e lunghezze gia verificati; il conteggio UTF-8 viene controllato. |
| 7. Decisioni composte | AND del range, budget, overlap e guardie di copia presenti; conteggio statico entro limite. Inventario e coppie di indipendenza restano da verificare separatamente. Nessuna attestazione MC/DC. |
| 8. Proprietario | Commenti OWNER/SHARED espliciti. Il chiamante possiede la destinazione; i byte sorgente restano stabili. Stesso array consentito solo con footprint disgiunto. |
| 9. Integrazione | Export aggiunta e ASDF seriale dopo UTF-8, limiti e header writer. REQ-CBR-002 inserito; matrice generata, build rigorosa e MAKE CHECK ancora pendenti. |
| 10. Regole | FTYPE completi, docstring con pre/post/errori, safety 3, guardie di ingresso e uscita senza effetti collaterali. Nessuna deviazione statica individuata; compilazione senza avvisi non eseguita. |
| 11. Parallelismo | Stato soltanto locale, nessun lock o contatore condiviso per operazione. Sorgenti immutabili possono essere condivise tra worker con destinazioni private; concorrenza effettiva e scaling non dimostrati da questa lettura. |
| 12. Durabilita | Nessun I/O, pubblicazione o cambiamento durevole. La destinazione resta del chiamante; una guardia interna puo fallire dopo una scrittura e richiede il confine fail-stop previsto dal contratto. |

## Confini e verifiche ancora necessarie

Non risultano differenze nei kernel gia integrati `cbor-write.lisp`,
`utf8.lisp` e `cbor-scan-input.lisp` rispetto alla base. La prima lettura
non rinnova la qualifica completa di queste dipendenze. I loro limiti di
copertura e i gate storici restano quelli conservati nelle relative campagne.

La seconda lettura dovra valutare i dati del corpus cieco, inclusi ordine
degli errori, massimo e massimo+1, alias nei due ordini, overlap della sola
testata, UTF-8 malformato con offset sorgente, sentinelle e arita esatta.
Le misure devono conservare il contenuto completo e verificare i sensori;
copertura e mutazioni devono preservare denominatori, copie, log e tentativi
falliti secondo il metodo preregistrato.

Altri blob letti: package `12d573ec29468f1fdae3e674a494d786a390c33e`,
ASDF `0f3902e2459e9bda66a27046d640e35e0feadc1a`, requisiti
`52300ff2ab7310e14b02fce2dc414b56a08c8f6c`.
