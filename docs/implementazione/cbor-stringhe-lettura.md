# Scrittura delle stringhe CBOR — seconda lettura C1

La successiva [lettura dei dati](cbor-stringhe-dati.md) confronta questa
lettura statica con i record runtime, senza cambiare il prodotto o i test.

Lettura statica del responsabile del corpus cieco, il 2026-10-11, dopo
il congelamento delle prove e prima delle campagne. Base
`2a0011f9d2bef104b22f7ad1eb86d7e5d60d5e11`; prodotto esaminato
`src/codec/cbor-string-write.lisp`, blob Git
`a2c5c77dd51bff760bff4508e998d94370921eda`.
Il [contratto preregistrato](cbor-stringhe-metodo.md) conserva il blob
`56342dae95caf8705e0b28b3c0ea7ac86fdd8fa0`.
La [prima lettura](cbor-stringhe-revisione.md) e l'[inventario](cbor-stringhe-decisioni.md)
sono artefatti separati; questa lettura non modifica prodotto o test.

Nessun difetto funzionale o rilievo statico aperto individuato nei blob
esaminati. Build, risultati del corpus, heap, concorrenza osservata,
copertura e mutazioni sono ancora pendenti. Questo esito non chiude i
gate C1, non attesta MC/DC o copertura completa e non qualifica il motore.

## Checklist C1

| Punto | Riscontro statico e verifica ancora necessaria |
|---|---|
| 1. Requisiti e ADR | REQ-CBR-002 da ADR-0014/0048, AFF-004/008 e limite locale LIM-002 sono coerenti con un item MT2/3 definite-length minimo. Il budget include testata e payload; non realizza composizione documentale, configurazione della Serie o normalizzazione del testo. |
| 2. Invarianti | Destinazione simple u8 esclusiva, sorgente stabile, range half-open, budget completo e footprint disgiunto precedono ogni mutazione. Le guardie controllano span, selezione, estremi della copia e cursori finali. Le prove congelate falsificano violazioni pubbliche tramite array interi e sentinelle; gli esiti runtime restano da registrare. |
| 3. Errori | Ordine conforme: destinazione → major → sorgente → tipo/limite budget → budget payload → budget item → capacità → overlap → UTF-8. I motivi coincidono con il metodo; gli offset di preflight sono NIL per initform della condizione. UTF-8 propaga classe, motivo e offset assoluto della sorgente. Ogni rifiuto pubblico precede la testata; le guardie interne dopo il write restano senza rollback, con fail-stop del proprietario. |
| 4. Limiti | La copia ripete esattamente SPAN passi, con SPAN≤16 MiB verificato e pari alla lunghezza destinazione. MT3 chiama il validatore con budget SPAN; anche quel ciclo è limitato. Nessuna ricorsione, attesa, retry o creazione di worker nel prodotto. |
| 5. Heap | Il nuovo successo usa cursori, valori multipli e chiamate dirette, senza costruttori, closure, AST o oggetti u64. I valori sono index/u32 limitati prima dell'uso. NTH-VALUE, chiamata keyword UTF-8 e aritmetica devono comunque essere misurati con baseline nulla e sensore positivo: heap zero non è attestato dalla lettura. |
| 6. Dati verificati | MT2 copia byte arbitrari; MT3 verifica integralmente UTF-8 prima della prima scrittura, senza ricontare la lunghezza in scalari. Header e copia ricevono range e dimensioni già controllati. Il wrapper controlla il conteggio UTF-8, la fine della testata e il NEXT finale; restituisce un solo valore. |
| 7. Decisioni composte | L'inventario comprende tutte le cinque forme AND e le sei relazioni concatenate; non vi sono OR. Le guardie interne rimangono nel denominatore della copertura, anche quando il contratto pubblico non permette di falsificarle. I testimoni dell'inventario sono piani, senza attestazione dinamica di indipendenza delle condizioni o MC/DC. |
| 8. Proprietario | OWNER/SHARED espliciti: destinazione del chiamante, byte sorgente stabili fino al ritorno, variabili locali. I simple array non condividono backing storage mediante displacement nel dominio ammesso: EQ identifica l'alias previsto. Lo stesso array è consentito solo disgiunto dal footprint effettivo; vuoti e confini toccanti sono ammessi. |
| 9. Integrazione | Export pubblico presente; ASDF seriale carica il prodotto dopo UTF-8, limiti e header writer, poi i tre file del corpus e il loro RUN. Le suite CBOR già presenti, MVCC, worker e index restano nel runner. REQ-CBR-002 è nel catalogo; build rigorosa, rigenerazione/verifica della matrice e MAKE CHECK completo restano pendenti. |
| 10. Standard | FTYPE completi, safety3, docstring Pre/Post/errori, REQ e guardie attive presenti. Cinque funzioni entro 60 righe e dieci percorsi secondo il conteggio dichiarato sotto. Nessuna deroga statica proposta; lint e compilazione senza warning/style-warning non eseguiti in questa lettura. |
| 11. Parallelismo | Il prodotto non introduce lock, attese, contatori o scritture condivise tra Serie. Il corpus usa due destinazioni private e una sorgente immutabile condivisa, con worker riusati e attese/join/cleanup limitati. La sovrapposizione temporale deve essere osservata nella campagna; non dimostra simultaneità sui core o scaling. |
| 12. Durabilità | La mutazione riguarda memoria esclusiva del chiamante; nessun I/O, punto di commit, eliminazione o pubblicazione durevole. Non è un'operazione atomica e non promette rollback di invariant-violation. Il confine fail-stop resta esterno al codec. |

## Preflight, aritmetica e copia

Il rifiuto `SPAN > BUDGET` avviene prima del cast del payload a u32 e
prima del selettore di testata: il budget già validato limita SPAN a
16.777.216. La testata è selezionata in base ai byte sorgente, con HIGH
zero; il controllo dell'item impedisce che payload e testata superino il
budget. Il massimo payload accettabile con il default è quindi
16.777.211 byte, seguito da una testata di cinque byte.

La capacità usa END−START, non la lunghezza fisica del buffer. Soltanto
dopo il controllo si calcola NEXT: da ITEM-SIZE≤END−START segue NEXT≤END,
e NEXT resta un index. PAYLOAD-START viene confrontato con
START+HEADER-SIZE; la copia verifica range, uguaglianza delle lunghezze
e progresso, quindi termina esattamente a NEXT. Il risultato pubblico è
il singolo valore numerico finale.

L'overlap usa disuguaglianze strette sui range sorgente e `[START,NEXT)`,
testata inclusa. Il residuo `[NEXT,END)` non estende il footprint. Una
sorgente vuota non interseca alcun byte; gli intervalli che si toccano
restano disgiunti. Nel caso ammesso di stesso array, la verifica UTF-8
precede la testata e la copia resta disgiunta dalla sorgente stabile.
Con sorgente vuota viene scritta soltanto la testata, senza leggere byte
sorgente. Su rifiuto pubblico non è ancora stato modificato alcun array.

## Dimensione e inventario

Conteggio sintattico: uno iniziale, un incremento per controllo di flusso,
per ciascuna condizione AND/OR aggiuntiva e per LOOP; non include
l'espansione dei controlli di tipo o dei confronti primitivi. Il confronto
con il sorgente conferma i numeri della prima lettura e dell'inventario.

| Funzione | Righe DEFUN inclusive | Percorsi |
|---|---:|---:|
| `check-span-string-cbor-write` (10–21) | 12 | 6 |
| `check-input-string-cbor-write` (27–53) | 27 | 8 |
| `check-overlap-string-cbor-write` (58–70) | 13 | 7 |
| `copia-stringa-cbor-write` (75–93) | 19 | 8 |
| `scrivi-stringa-cbor-minima` (98–129) | 32 | 5 |

Le cinque decisioni logiche AND sono range, budget, overlap, limite della
copia e progresso della copia. Le sei relazioni `<=` a tre operandi sono
range pubblico, selezione, due range di overlap e due range di copia.
Quella del range pubblico è già interna alla sua decisione AND:
contando senza duplicarla si hanno cinque decisioni logiche e cinque
relazioni concatenate autonome. Questo inventario sintattico non è una
misura di copertura né una prova di MC/DC.

## Provenienza e corpus congelato

I tre file seguenti sono stati scritti dal metodo e dalle dipendenze/oracoli
già esistenti, senza leggere `cbor-string-write.lisp`. Solo dopo il loro
congelamento è iniziata questa lettura del prodotto. Gli hash sono stati
ricontrollati e coincidono con quelli comunicati al coordinatore.

| File cieco | Blob Git | SHA-256 |
|---|---|---|
| `tests/codec/cbor-string-write-support.lisp` | `e45437a508fc7893c4df06f3129ab064d3a4dbdd` | `611ec1d825855d9df27988821ee45f0ecf81fbd3128a38df6ee5c727551cd9f2` |
| `tests/codec/cbor-string-write.lisp` | `ed0f6a67c46498bdc9c721480cb76bc727fc5b4f` | `ea9cc94d8e810942da019aade862711cbdf33216161433fef6953f75472a2115` |
| `tests/codec/cbor-string-write-threads.lisp` | `33c7e6a9a0d6bbd551d4171ece6681b66bf87657` | `d45b4dda658a96b9af9051b152df2b17859aecdbb9131505d1a2689b27ffb88a` |

La testata attesa usa divisione/modulo e potenze di 256, confrontata anche
con vettori letterali indipendenti. Il payload atteso deriva dalla sorgente
prima della chiamata; il successo confronta l'intera destinazione, un solo
NEXT fixnum e la preservazione della sorgente disgiunta. Su errori si
confrontano entrambi gli array fisici, anche per argomenti non simple.
Nessun encoder o scanner di prodotto genera gli expected.

I venti test seriali prevedono:

- 8.194 confronti di tutte le lunghezze 0..4096 per MT2/3; soglie e
  adiacenti fino a 65.537 byte, disallineamento e capacità esatta fino
  all'estremo fisico dell'array.
- 2.048 casi con seed `53574342`, payload arbitrari o scalari codificati
  dall'oracolo freddo già esistente, e classificazione UTF-8 dal modello
  manuale `cs-ref-utf8`, separato dal validatore del prodotto.
- 1.138 capacità insufficienti, con suffisso fisico disponibile ma escluso
  da END; budget comprendente la testata, item vuoto, massimo 16 MiB,
  item massimo+1 e payload massimo+1, con precedenze multi-invalid.
- Byte MT2 0..255, NUL/BOM/noncaratteri e scalari multibyte per MT3, testo
  composto/decomposto preservato, alias nei due ordini, vuoti/toccanti,
  footprint effettivo e overlap della sola testata.
- Venti sequenze UTF-8 malformate a tre offset sorgente: classe, motivo,
  offset assoluto e precedenze troncamento/continuazione/scalare;
  ciascuna è anche accettata come MT2. Riuso dopo errori e concatenazione.

Il controllo dello scanner minimo è supplementare: per ciascun major
avviene soltanto dopo il confronto completo con i byte freddi attesi,
verificando anche i tre valori di ritorno dello scanner.

Il ventunesimo test prevede due worker riusati per due ondate di 8.192
item ciascuno, 32.768 item complessivi. La sorgente condivisa ha 1.024 byte
con NUL e scalari multibyte; ciascun worker possiede una destinazione
distinta. Expected e token del sink vengono preparati prima dell'avvio;
ogni chiamata controlla arity, NEXT e l'intera destinazione. Il sink somma
NEXT, byte di testata e ultimo byte payload effettivamente osservati.
Il parent verifica sorgente integra, sink, intervalli e join; semafori
entro 15 secondi, join entro 20 secondi e cleanup con verifica della
terminazione. Il numero di worker o di item non costituisce un risultato
di scaling; tutti gli esiti restano da osservare.

## Lettura sintattica e verifiche pendenti

È conservata una ripetizione isolata della sola lettura sintattica:
[helper](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-cbor-string-write/raw/setup/cbor-string-write-static-reader.lisp) e
[log](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-cbor-string-write/raw/setup/cbor-string-write-static-reader.log). Usa package
segnaposto e `*read-eval* NIL`; non valuta, compila o carica alcuna forma
del prodotto o del corpus. Le fixture del helper controllano sintassi
valida, parentesi mancante e blocco di read-eval. Il reader registra PASS
con 12 forme del prodotto e 14/21/2 forme nei tre file ciechi. È un
controllo sintattico, distinto dalle campagne runtime preregistrate.

Le dipendenze `cbor-write.lisp`, `utf8.lisp`, `cbor-scan-input.lisp` e gli
oracoli usati non risultano modificati rispetto alla base. Altri blob letti:
package `12d573ec29468f1fdae3e674a494d786a390c33e`, ASDF
`e3a98df96d9e7be83e41bfef21a2bf08a59017e8`, inventario
`2df0a214fc5cfe64ceb239aab4f7d2a2d1827305`, prima lettura
`90bac509af0aff7b7085a2239de6e9dfddfc70ba`.

Nessuna build, chiamata ai test, misura heap, copertura o mutazione è stata
eseguita dal responsabile di questa lettura. Restano necessarie le
campagne registrate con sorgenti stabili, controlli dei sensori, baseline
e otto mutazioni, coverage grezza senza esclusioni, e regressioni complete.
Le qualifiche e i limiti storici delle dipendenze restano quelli delle loro
campagne; questa lettura non li rinnova e non è un'approvazione umana.
