# Decisioni della scansione CBOR con testate minime

Inventario e auto-lettura statica dell'autore del refactor, prima delle
campagne. Non costituisce lettura C1 indipendente o approvazione umana.
I nuovi test non sono stati letti dall'autore del prodotto. Build rigorosa,
lint, tracciabilità, test, copertura, mutazioni e misura heap sono pendenti;
le righe sotto si riferiscono ai sorgenti di questa consegna.

## Ambito e percorso

`verifica-struttura-cbor-minima` passa T a
`verifica-struttura-cbor-interna`; `verifica-struttura-cbor` conserva la
firma pubblica con gli stessi keyword e default, passando NIL. Nessun modo
nuovo è esposto sulla API generica. Il parametro booleano interno e
posizionale seleziona direttamente il lettore in `passo-struttura-cbor`;
non introduce closure, callback, keyword dinamici o un secondo attraversamento.

Il nucleo condiviso esegue il preflight prima del reset dello scratch.
Conserva lo spazio esclusivo di 102 celle, il ciclo limitato da SPAN e il
drain limitato a 102 frame. Contenitori e testi usano gli helper invariati:
profondità soltanto per array/map, UTF-8 dopo la disponibilità dell'intero
payload e nessuna ricostruzione u64/float. Tre valori escono soltanto dalle
postcondizioni di `risultato-struttura-cbor`.

La nuova API richiede testate minime in ogni posizione raggiunta, incluse
chiavi, valori e tag. Non verifica semantica dei tag, ordine o duplicati
delle mappe; non attesta il profilo documentale completo di ADR-0014/0048.
Il kernel non possiede una Serie e propaga gli invarianti: il controller
responsabile deve realizzare la transizione FAULTED, fuori da questa API.

## Decisioni composte

Le **tre decisioni composte nel file rifattorizzato sono preservate**;
la selezione nuova del lettore è una decisione semplice. I wrapper non
contengono decisioni: delegano con il booleano costante. Gli inventari
esistenti di header minimo, input, scratch, stack e item restano separati.

| ID | File, funzione e riga | Condizioni | Verifica prevista o limite |
|---|---|---|---|
| D01 | `cbor-scan.lisp`, `passo-struttura-cbor`, 29 | lead < cursore dopo il passo; cursore <= END | Corpus generico/minimo, troncature e input annidati devono avanzare o segnalare errore. Esito contrario è difesa interna, mantenuta nel denominatore. |
| D02 | `cbor-scan.lisp`, `risultato-struttura-cbor`, 41 | 1 <= nodi <= max-nodes; picco <= max-depth | Limiti esatti, scalari depth zero e profondità 100; la postcondizione interna resta nel denominatore. |
| D03 | stessa funzione, 44 | top zero; depth zero; nessun tag pendente | Item esatti, tag concatenati e contenitori vuoti/non vuoti. Stato residuo su successo è difesa interna; nessuna prova di irraggiungibilità. |

Fixture e risultati spettano all'oracolo indipendente e alle campagne.
Questa tabella non dimostra copertura condizione per condizione o MC/DC;
non approva esclusioni di guardie, dichiarazioni, default o fallback.

## Selezioni e priorità osservabili

| Punto del percorso | Ordine preservato o introdotto |
|---|---|
| Wrapper | Stessi keyword e default; generico NIL, minimo T. Nessun altro ingresso pubblico al booleano. |
| Preflight | Range → workspace → alias EQ kinds → byte-limit → node-limit → depth-limit → byte-budget, prima di reset o lettura dei byte. |
| Passo, righe 19–24 | T: lettore sintattico base dentro il lettore minimo → minimalità → contesto; NIL: lettore generico → contesto. Header sintatticamente incompleto o illegale precede `:cbor-nonminimal`. |
| Nodo e corpo, righe 25–28 | Minimalità completata prima di node-budget, depth-budget, disponibilità del payload e UTF-8. Indefinito/break sintatticamente ammesso è nonminimal sul lead nella API minima. |
| Drain, righe 70–73 | Frame/radice prima del prossimo header. Una radice già conclusa segnala `:cbor-trailing` al primo byte residuo, senza applicare minimalità alla coda. |
| Fine incompleta, righe 73–77 | Lo span `END..END` viene letto dal lettore base: `:cbor-truncated` a END anche per span vuoto o tag senza item terminale. Non esiste una testata completa cui applicare minimalità. |
| Riutilizzo | Rifiuto preflight lascia lo scratch invariato; rifiuto durante scansione può sporcarlo. La successiva chiamata valida esegue il reset prima di entrambi i percorsi. |

## Checklist C1 dell'autore

| Punto | Riscontro statico e limite |
|---|---|
| 1. Requisiti/ADR | REQ-LIM-001/002 e AFF-004/008 dichiarati; ADR-0014/0048 per header, ADR-0031/0035 per disciplina C1. Profilo completo fuori ambito. |
| 2. Invarianti | Buffer immutabile, scratch esclusivo, progresso e risultati controllati; INV-F1/A8/P6. Oracoli e prove dei confini ancora pendenti. |
| 3. Errori | Condizioni tipizzate propagate; priorità sintassi/minimalità e trailing descritte sopra. Nessun handler nuovo; transizione Serie FAULTED fuori dal kernel. |
| 4. Limiti | Un solo ciclo repeat SPAN e drain102 invariato, header massimo nove byte; nessuna ricorsione o attesa nuova. |
| 5. Heap | Solo argomenti/valori locali nel refactor, scratch esistente preallocato e chiamate dirette. Nonallocazione non attestata: misura e sensore positivo pendenti. |
| 6. Uscita | Solo tre valori dopo le postcondizioni condivise, nessun AST/payload decodificato o copiato. |
| 7. Decisioni | D01–D03 confrontate con il codice; selezione semplice T/NIL e priorità inventariate. Copertura grezza e MC/DC non attestati. |
| 8. Proprietà | Commenti OWNER/SHARED nei due file: buffer del chiamante, scratch di un solo worker/chiamata; nessun globale mutabile nuovo. |
| 9. Integrazione | Export aggiunto. ASDF, matrice, build/lint/trace e `make check` sono compito del coordinatore e restano pendenti. |
| 10. Standard | safety3, FTYPE completi, docstring/REQ, funzioni entro 60 righe. Passo, risultato e nucleo hanno almeno due controlli attivi; i wrapper sono deleghe banali. Nessuna deviazione introdotta o approvata. |
| 11. Parallelismo | Nessun lock, stato condiviso, attesa, I/O o creazione thread. La condivisione concorrente dello stesso scratch viola la precondizione; worker indipendenti devono averne uno ciascuno. |
| 12. Durabilità | Nessuna scrittura durevole, pubblicazione o eliminazione. Punto di atomicità non applicabile. |

Il riscontro statico non contiene rilievi aperti. Le campagne del
coordinatore devono ancora verificare il comportamento osservabile,
anche della API generica dopo lo spostamento del corpo, e quantificare
heap e copertura senza restringere il denominatore. Questa consegna non
chiude un gate del motore o un'approvazione umana.
