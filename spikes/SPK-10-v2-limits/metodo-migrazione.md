# SPK-10 — Metodo per selezione del formato e modello di migrazione

> **Proposta** — Esperimento in `migrazione.lisp`, package
> `arcdocdb.spk10.migrazione`. Questo metodo è registrato prima dell'esecuzione.
> Non conclude il gate v2 e non implementa un convertitore su disco.

## Domanda e riferimenti

Verificare che il fileheader scelga esplicitamente v1/v2 e rifiuti versioni ignote;
esplorare un modello finito della conversione offline interrotta e rieseguita,
con sorgenti immutabili, un solo EDIT di pubblicazione e reclaim subordinato ai pin.
Requisiti: REQ-FOR-002, REQ-LIM-003, REQ-AFF-007, REQ-AFF-018, REQ-AFF-019.
Fonti: ADR-0048; ADR-0036; ADR-0040; `docs/formati-su-disco.md`, intestazione
del segmento e nomi temporanei; specifica, workflow CLEAN/MERGE e reader.

> **Deciso (versionamento → ADR-0048)** — Il layout si sceglie dalla versione
> del file. Il solo magic documentato per il segmento è `ARCDSEG1`: il carattere
> finale non sostituisce il campo u16 little-endian a offset 8. La tabella storica
> indica versione 1; le fixture v2 usano quel medesimo magic e versione 2 secondo
> ADR-0048. Non si introduce `ARCDSEG2` o un nuovo formato persistente.

## Metodo registrato

- Costruire fixture di soli 64 byte, con origine 1/2, id Serie di 16 byte,
  segment-id e timestamp u64, riservati zero, CRC32C a offset 56 sui byte 0–55.
  Riutilizzare il CRC reference di SPK-09, già caricato dal runner; nessuna
  dipendenza dal codec v2, dagli indici o dal decoder CBOR degli altri moduli.
- Validare tipo e bounds prima degli accessi, poi magic, CRC, origine e tutti i
  riservati (11–15, 48–55, 60–63), poi versione 1/2. Versioni ignote rifiutate
  prima di restituire o invocare un parser. Verificare fixture con CRC corretto
  anche per campi semanticamente invalidi, tutti i troncamenti e tutti i bit flip.
- Modello separato: un sorgente v1, un output v2, pin 0/1, presenza del `.tmp`
  e del definitivo, validità, verifica, durabilità del file e della directory,
  EDIT durevole e completamento. I contenuti sono simboli/booleani, non record
  codificati; il modello non dimostra conversione dei byte o crash reali.
- Fasi: prepara `.tmp`; scrivi v2 (anche prefissi parziali); verifica;
  rendi durevole il file; rendi durevole la directory; pubblica EDIT;
  completa la rinomina; reclaim solo senza pin. Prima dell'EDIT il manifest
  seleziona v1 e la sorgente resta intatta; dopo seleziona v2 e la sorgente
  resta intatta fino al reclaim autorizzato dal record di rimozione.
  Sono dieci fasi distinte: preparazione, scrittura parziale, scrittura completa,
  verifica, durabilità file, durabilità directory, EDIT, rename, durabilità
  directory dopo rename, reclaim. Un rename interrotto lascia il nome precedente
  oppure quello nuovo. Output mancante dopo EDIT significa che mancano **entrambi**
  `.tmp` e definitivo; un `.tmp` nominato viene completato dal recovery.
- Enumerare crash prima/dopo ciascuna fase, inclusi scrittura parziale,
  output corrotto, verifica negativa e falsa verifica positiva. Esplorare
  separatamente interruzioni del recovery e confrontare il risultato della
  riesecuzione con quello senza interruzione. Un output nominato dall'EDIT ma
  assente/corrotto produce un errore di integrità, conservando i sorgenti;
  un definitivo sconosciuto resta presente ed è segnalato.
- Oracle indipendente dalle transizioni: verifica selezione, integrità,
  immutabilità, prova di rimozione, pin, numero di EDIT e punto di atomicità.
  I mutanti `unlink-before-EDIT`, `skip-verification`, `reclaim-pinned` devono
  essere rilevati con un controesempio deterministico.
  La falsa verifica positiva è un responso deliberatamente scorretto rispetto
  alla validità booleana nota all'oracle: viene rilevata dall'oracle e il caso
  si ferma prima della pubblicazione. Non è una dimostrazione dell'infallibilità
  di un verificatore reale. Una verifica negativa su output valido è un rifiuto.
- Saturare budget di fasi e copie: rifiuto esplicito prima della fase che
  supera il budget, nessun EDIT incompleto. Nessuna attesa dei pin: si rinvia
  il reclaim e si riesegue dopo rilascio esplicito. Stato locale a un modello;
  nessun lock, stato condiviso per Serie o I/O.

## Costi e limiti dichiarati

> **Proposta** — Limiti sperimentali, non prestazioni garantite: fileheader
> esattamente 64 byte; CRC su 56 byte; confronti e riservati al più 64 byte;
> scritture intere al più 8 byte, id Serie 16 byte. Tutte le fixture sono bounded.
> Il modello usa un sorgente e un output, due stati di pin e un numero fisso di
> fasi; scrittura e durabilità sono azioni simboliche finite. Ogni fase e ogni
> passo del recovery consuma un'unità del budget; la scrittura parziale e completa
> consuma anche unità di copia. I conteggi effettivi e i tetti controllati sono
> restituiti da `check`. Le azioni atomiche astratte non modellano syscall,
> fsync/rename reali, reorder del dispositivo, corruzioni non rilevate dai CRC,
> sincronizzazione di reader concorrenti o conversione dei record. I pin del
> modello sono conservativi anche nel recovery; dopo un riavvio reale non
> sopravvivono i reader del vecchio processo (ADR-0040).

> **Proposta** — Tetti controllati: 32 passi per esecuzione del modello e 2
> unità di copia per tentativo (4 includendo tentativo interrotto e rerun);
> 10 fasi; 4 passi di recovery; 11 prefissi per scenario;
> 4 scenari (sano, corrotto, verifica negativa, verifica falsa); pin 0/1;
> 4 alternative di crash (nome e contenuto conservati/persi quando non durevoli).
> Ogni recovery è interrotto dopo 0..4 passi e riceve a sua volta ciascuna
> alternativa di crash. L'idempotenza confronta tutti i fatti logici e durevoli;
> esclude soltanto budget e contatori del lavoro già svolto. Il sorgente è un
> contenuto simbolico immutabile; il fileheader è invece verificato su byte reali.

Ogni fase costa un passo simbolico, incluso il reclaim rinviato per un pin:

| Fase | Effetto e costo di copia |
|---|---|
| `prepare.tmp` | Presenza del temporaneo; zero copie |
| `write.partial` | Output parziale; una unità di copia |
| `write.v2` | Output completo, validità fissata dallo scenario; una unità di copia |
| `verify` | Responso del verificatore, distinto dalla verità dell'oracle; zero copie |
| `durable.file` | Durabilità astratta del contenuto; zero copie |
| `durable.directory` | Nome `.tmp` durevole; zero copie |
| `publish.edit` | Unico EDIT durevole e prova di rimozione dei sorgenti; zero copie |
| `complete.rename` | Rinomina dopo EDIT, ripetibile; zero copie |
| `complete.directory` | Nome definitivo durevole; zero copie |
| `reclaim` | Rimozione solo con prova, completamento e zero pin; zero copie |

Il recovery esegue al massimo due passi prima di EDIT (`discard.tmp`,
`report.unknown`) o quattro dopo EDIT (`inspect.output`, rename, syncdir,
reclaim). Anche scarto, segnalazione e ispezione consumano un passo, senza copie.
Lo stato ha dimensione fissa: le copie di `stato` non dipendono dai byte del
documento. Le unità di copia sono un costo **simbolico**, non byte o tempo di I/O.
Le fasi sono seriali dentro questa singola migrazione; non c'è serializzazione
fra Serie. I conteggi riguardano iniezioni eseguite: alternative con fatti già
durevoli possono convergere al medesimo stato, senza essere contate come nuovi
stati distinti.

## Ambiente e riproduzione

Ambiente individuato prima dell'esecuzione: SBCL 2.6.9, Darwin arm64.
Policy del modulo: `(safety 3)`. Nessuna dipendenza esterna oltre Common Lisp/SBCL;
CRC reference dal modulo locale SPK-09. Il runner carica SPK-09 e i moduli
nell'ordine codec, index, cbor, migrazione. Compilare con `warning` e
`style-warning` fatali, controllare tutti i valori di `compile-file`, caricare
il FASL e chiamare `arcdocdb.spk10.migrazione:check`. L'output è una plist con
`:status :ok`, conteggi, limiti e i tre mutanti attesi. Nessun benchmark lungo;
le misure aggregate si eseguono in serie nell'harness integrato.
Ogni prova locale produce una plist schema 1 in `out/migrazione-check.lisp`,
letta con `*read-eval* nil`, con comando, ambiente, blob dei sorgenti, stato
compile, risultato, limiti, tempi, stdout/stderr ed eventuale fallimento.
Il record conserva anche i tentativi precedenti se occorrono riparazioni.

## Risultati

> **Proposta** — Evidenza locale per i soli fileheader e il modello finito;
> non completa il gate v2 del motore. Prova del 2026-10-08 su SBCL 2.6.9,
> Darwin 27.0.0 / ARM64, policy safety 3.

Compilazione strict: `:status :ok`, `warnings nil`, `failure nil`; caricamento
del FASL e `check`: `:status :ok`. Stdout/stderr catturati vuoti, nessun warning
o style-warning. Il risultato e i blob sono in
[`v2-migrazione-check.lisp`](../results/2026-10-08/v2-migrazione-check.lisp), una singola plist
schema 1 leggibile con `*read-eval* nil`. Il sorgente verificato ha blob Git
`cab850dc32ff9908b487b24edf3e1df2cc90008c`; il CRC reference SPK-09 ha blob
`80cdac4c0e52703618e1f274413b2ecbe00e6b14`.

| Verifica | Conteggio effettivo |
|---|---:|
| Fileheader validi, inclusi intervalli traslati | 8 |
| Fileheader invalidi rifiutati prima del parser | 2.393 |
| Bit flip / troncamenti / riservati con CRC valido | 2.048 / 256 / 68 |
| Origini invalide / versioni ignote / bounds invalidi / magic alternativo | 12 / 4 / 4 / 1 |
| Prefissi raggiungibili dei quattro scenari con pin 0/1 | 52 |
| Crash di migrazione / rerun sani | 208 / 208 |
| Interruzioni del recovery con nuovo crash e riesecuzione | 4.160 |
| Verifiche negative / false verifiche rilevate dall'oracle | 4 / 2 |
| Output committed assente o corrotto, errore di integrità | 2 |
| `.tmp` nominato completato / definitivo sconosciuto conservato e segnalato | 1 / 1 |
| Saturazioni del budget / trattenimento e rilascio pin | 13 / 2 |
| Massimo lavoro osservato / tetto | 22 passi / 32 |
| Massimo copie osservato / tetto, includendo tentativo interrotto e rerun | 4 / 4 |

Mutanti rilevati: `unlink-before-EDIT` alla preparazione, `skip-verification`
alla pubblicazione EDIT, `reclaim-pinned` al reclaim. Tutti e tre producono
controesempi dell'oracle. Prima e dopo EDIT il sorgente resta immutabile e
presente finché il reclaim non è autorizzato e i pin sono zero.

Tempi **misurati per questa sola esecuzione**, non benchmark o garanzie:
compile 0,179701 s; check 0,007486 s; harness completo 0,651317 s. L'artefatto
conserva quattro tentativi precedenti: tre fallimenti (parentesi in eccesso,
budget di copia insufficiente per il rerun e relativa diagnosi) e un check
riuscito prima di precisare il conteggio del massimo lavoro. Ogni tentativo
ha comando, ambiente, blob, stato compile, risultato o fallimento, tempi e log.

## Limiti ancora aperti

> **Proposta** — Servono ancora convertitore offline reale v1/v2, verifica dei
> byte dei record e della loro equivalenza, budget di byte/memoria/I/O, prove
> con fsync e filesystem reali, crash dentro syscall/scritture e test dei reader
> concorrenti. La durabilità e l'EDIT sono azioni atomiche astratte, i contenuti
> dei segmenti sono booleani/simboli. La falsa verifica è riconosciuta perché
> l'oracle conosce la validità del caso, non perché un verificatore reale sia
> garantito infallibile. La dipendenza CRC è il modulo locale SPK-09, non il
> codec v2; questo esperimento non certifica gli altri moduli né il gate v2.
