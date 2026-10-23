# Scrittura semplici CBOR — lettura C4 di strumenti e dati

Questa copia pubblica la lettura originaria, blob
`a42a47b5651378d71b760642057e2b2538490849`, conservata
[nell'archivio](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-cbor-simple-write/raw/readings/c4-review-draft.md.txt).
Le dichiarazioni di scrittura ignorata sotto descrivono quella lettura.

Data dichiarata dal client: 2026-10-11. Questa lettura riguarda strumenti congelati e record già prodotti; conserva i tempi universali del runtime senza convertirli nella data del client. Non ha caricato il prodotto, la suite, il driver o gli auditor, né ripetuto self-test o campagne. I record sono stati letti come dati con `tools/evidence-storage.lisp`; le sole operazioni aggiuntive sono letture di sorgenti e impronte di cinque file. L'unica scrittura è questo documento ignorato.

## Perimetro e impronte verificate

| File | Git blob |
| --- | --- |
| `spikes/out/cbor-simple-write-20261011/data-audit.lisp` | `4ca865ddfca6da36a73c81fb5041df4df60d79ab` |
| `tools/cbor-simple-write-mutation.lisp` | `ec2fe6b3235591ec5b3bb82b32046e906b045bf6` |
| `tools/cbor-simple-write-audit.lisp` | `6acfcc656bfed5f8b4c59e487cffb5325d30d790` |
| `tools/cbor-simple-write-bench.lisp` | `07e5b0b7773f95ddae9458267b285c0ccb24dba9` |
| `src/codec/cbor-simple-write.lisp` | `58c7a3a040ec814fae2dfe636f569b5623cba8f0` |

L'autore di questa lettura è anche autore dell'auditor del benchmark: non si attribuisce indipendenza alla revisione del proprio strumento. La lettura indipendente di quel codice è stata svolta dal coordinatore. Il suo controllo dei dati deriva comunque byte, NEXT, token e sink da VALUE, senza caricare prodotto o driver né riusarne builder e oracoli.

## Lettura statica

- **Reader:** helper righe 101–116 e auditor righe 61–72 usano `*read-eval* NIL`, readtable standard, package CL-USER e una sola forma seguita da EOF. Le plist richiedono forma propria e chiavi keyword uniche. Il preambolo delle mutazioni è distinto dalla plist finale e deve corrispondere al preambolo noto. Nessuna lettura valuta codice del record. Questo è un controllo del formato previsto, non una sandbox generale contro ogni costo o comportamento del reader su dati ostili.
- **Dati del benchmark:** auditor righe 208–303 controlla schema, sei fixture, trenta campioni, arità fredda esatta, array completo, token ponderato, sink modulare, heap e sensori; verifica metadata, safety 3, workers 1, impronte selezionate e snapshot dichiarati prima/dopo. La data ambiente può precedere STARTED di un tick, coerentemente con l'ordine del registratore. I tempi devono essere coerenti, senza soglia di velocità. Le impronte attese del prodotto sono argomenti espliciti della CLI.
- **Copie e mutazioni:** catalogo di otto target, sostituzione univoca e confronto integrale del file mutato. La mutazione physical-capacity usa `(max span (- (length bytes) begin))`; extra-return-value modifica insieme FTYPE e DEFUN nella copia, evitando di classificare un errore di compilazione come rilevamento. Il prodotto originale resta escluso dalle scritture. Mutatore righe 323–361 crea directory nuove, runner e cache FASL locali, conserva log completi, exit e segnale; righe 185–189 e 215–225 separano compilazione, sopravvivenza e worker error.
- **Snapshot:** helper righe 131–145 e auditor verificano uguaglianza prima/dopo e stato STABLE, con il blob prodotto congelato. Helper righe 467–473 ricontrolla anche byte e SHA256 degli input osservati. Sono confronti locali su inventari dichiarati; non dimostrano autenticità, esecuzione del processo attestato o assenza di modifiche transitorie tra due osservazioni.
- **Copertura:** helper righe 322–355 confronta scope singolo, stato raw e due HTML esatti, con tutti i denominatori. Il parser conserva il caso SB-COVER di chiusura implicita del primo TR. La mappa dei gap associa sintatticamente path raw e sorgente: non prova irraggiungibilità, non esclude guardie e non attesta MC/DC.
- **Output:** helper righe 357–363 scrive soltanto un nuovo output nel perimetro ignorato, rifiutando file esistenti; il mutatore conserva copie e rapporti anche in caso di fallimento. Il controllo lessicale dei percorsi non è una prova di assenza di symlink o di contenimento canonico di un albero arbitrario.

## Fragilità concrete e limiti da conservare

1. **Classificazione del rifiuto runtime:** helper righe 188–198 cerca smoke esatto e un qualsiasi `Unhandled `; non verifica l'ordine smoke → rifiuto né l'origine della condizione. Mutatore righe 215–225 classifica l'exit nonzero con smoke presente senza richiedere il rifiuto o la sua causa. Un guasto runtime estraneo dopo uno smoke, oppure un log artificiale con ordine invertito, può quindi soddisfare il classificatore. Il coordinatore ha comunicato l'esito della lettura separata degli otto log: smoke esatto prima di Unhandled, callsite REQ-CBR-003 della suite, nessun warning, fallimento di compilazione o segnale e otto sostituzioni esatte rilevate. Questo esito è attribuito al secondo lettore; questa revisione non ha duplicato la sua lettura integrale dei log.
2. **Inventario delle copie:** helper righe 206–231 prova la sola differenza per i fingerprint dichiarati, non la completezza dell'albero copiato. Un catalogo che omette un file non viene scoperto da questo confronto. Il rapporto dichiara correttamente `NO-CLOSED-COPY-TREE-CLAIM`; runner e cache sono verificati per esistenza e configurazione, non mediante un inventario chiuso dell'intera copia.
3. **Negativi del helper:** righe 380–381 accettano qualsiasi ERROR nelle fixture negative. Il PASS non prova quindi che ogni rifiuto provenga dalla guardia e dalla reason attesa: anche un errore di programmazione potrebbe soddisfarlo. L'auditor del benchmark richiede invece la propria condizione audit-rejection e la reason prevista. Non si estende tale garanzia al helper.
4. **Autenticità e stabilità:** le impronte attese della CLI e gli snapshot dichiarati richiedono fiducia nel registratore e nel chiamante. L'uguaglianza delle osservazioni locali non costituisce una firma, una prova di isolamento OS o una prova atomica contro modifiche e ripristini intermedi. I controlli MD5 sulle copie non sono tutti compresi nelle osservazioni SHA256 finali.

Nessun difetto obbligatorio che impedisca la lettura dei dati attuali è emerso. Le fragilità sopra impediscono claims più forti di quelli dichiarati; non richiedono di modificare i sorgenti congelati durante la raccolta.

## Record effettivamente letti

I quattro wrapper completi riportano schema 1, KIND COMMAND-VERIFICATION, STATUS OK, exit 0, STDERR vuoto, SOURCE-CONSISTENCY STABLE e 685 voci SOURCE-BLOBS identiche prima/dopo. Lo stdout dell'auditor benchmark è una plist; quello del helper è un riepilogo testuale, verificato insieme al rispettivo artifact Lisp.

| Wrapper | Intervallo universale runtime | Wall seconds | Esito dati |
| --- | --- | --- | --- |
| `spikes/out/4000714388-command-46985-0/report.lisp` | 4000714389–4000714390 | 1.009074 | audit benchmark OK, 20409 controlli |
| `spikes/out/4000714391-command-47195-0/report.lisp` | 4000714391–4000714392 | 1.073152 | helper self-test OK, 529 controlli, 27 casi |
| `spikes/out/4000714393-command-47353-0/report.lisp` | 4000714394–4000714400 | 6.516856 | audit mutazioni OK, 15320 controlli |
| `spikes/out/4000714401-command-47888-0/report.lisp` | 4000714402–4000714403 | 1.613452 | audit copertura OK, 1178 controlli |

### Benchmark

Il primo wrapper invoca `tools/cbor-simple-write-audit.lisp --bench` sul record `spikes/out/4000713808-command-19171-0/report.lisp`, fornendo blob prodotto `58c7a3a040ec814fae2dfe636f569b5623cba8f0` e MD5 `200373402e6e082dd8c7afde305302bb`. Il rapporto attesta sei celle e trenta campioni, heap osservato 0, arità fredda 1, baseline heap 0 e controllo positivo 16777472 byte per il budget di 16 MiB. Timer 1000000 tick/s; somma tempi campioni 0.022090000000000002 s e controlli 0.000064 s. Il record benchmark conserva STARTED 4000713809, FINISHED 4000713810 e RECORDED-AT 4000713809. L'osservazione locale del record di 183455 byte ha SHA256 `49e218bbe4a9eee8f137c381755929cab53c4cf298bb7df73a019ea0b7467e02` identico prima/dopo. Questi sono esiti di coerenza dei dati, senza claim di velocità, parallelismo, autenticità o esecuzione provata.

### Helper e mutazioni

Letto integralmente `audit-self-test/report.lisp`: STATUS OK, 529 controlli, 27 casi sintetici, prodotto non caricato e nessuna campagna eseguita dal self-test; una osservazione input uguale prima/dopo. Il limite sui negativi descritto sopra resta applicabile.

Letto integralmente `audit-mutations.lisp`: STATUS OK, 15320 controlli e 36 osservazioni input identiche prima/dopo. Il record della campagna riporta otto detected, zero survived, zero invalid e zero worker errors. Baseline exit 0, smoke riga 2 e completamento riga 925; otto copie exit 1 senza segnale o completamento, smoke riga 2 e un rifiuto presente nei rispettivi log. Il helper verifica 254 file dichiarati per ciascuna delle nove copie: nessuna differenza nella baseline, soltanto `src/codec/cbor-simple-write.lisp` differente in ciascun mutante e sostituzioni esatte. Non si trasforma questo esito in inventario chiuso, né in prova indipendente dell'origine dei rifiuti runtime.

### Copertura

Letto integralmente `audit-coverage.lisp`: STATUS OK, 1178 controlli e cinque osservazioni input identiche prima/dopo. Lo stato salvato comprende 248 file, ma il perimetro HTML è esattamente un sorgente e due HTML: `cover-index.html` e `9ae2ab0021850480ee0bbfa07aef40ba.html`. Conteggi raw/index/source concordi: **95/111 espressioni, 20/24 esiti di ramo**. Mancano 16 espressioni, associate a quattro dichiarazioni e dodici nodi dei tre rami di errore interno; mancano quattro esiti delle guardie interne. Altre categorie: zero. Le reason e righe sono `cbor-simple-span` riga 22, `cbor-simple-target-span` riga 46 e `cbor-simple-progress` riga 52. Tutti i path raw restano nel rapporto e nel denominatore.

L'osservazione effettuata dal helper sullo stato raw riporta 1762263 byte e SHA256 `370f3694f1361132877df4dca8140e24160f338318d69dc108783f76585da6c8`. La successiva compressione degli output ignorati avviene dopo gli audit e va conservata tramite evidence-storage senza cambiare questi valori osservati sui byte decodificati. Questo documento non riqualifica MC/DC, la copertura completa, un gate o il rilascio.

## Chiusura

Lettura C4 completata, con risultati e limiti separati. Il documento è congelato dopo questa scrittura; nessun altro file è di competenza di questa attività. Il coordinatore ha comunicato anche la chiusura del controllo separato dei log; la fragilità generale del classificatore resta documentata.
