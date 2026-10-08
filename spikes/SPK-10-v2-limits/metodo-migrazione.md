# SPK-10 — Metodo per selezione del formato e modello di migrazione

> **Proposta** — Esperimento assegnato a `migrazione.lisp`, package
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
  dipendenza dal codec v2, dagli indici o dal decoder CBOR degli altri agenti.
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

## Ambiente e riproduzione

Ambiente individuato prima dell'esecuzione: SBCL 2.6.9, Darwin arm64.
Policy del modulo: `(safety 3)`. Nessuna dipendenza esterna oltre Common Lisp/SBCL;
CRC reference dal modulo locale SPK-09. Il parent carica SPK-09 e i moduli
nell'ordine codec, index, cbor, migrazione. Compilare con `warning` e
`style-warning` fatali, controllare tutti i valori di `compile-file`, caricare
il FASL e chiamare `arcdocdb.spk10.migrazione:check`. L'output è una plist con
`:status :ok`, conteggi, limiti e i tre mutanti attesi. Nessun benchmark lungo;
le misure aggregate sono responsabilità del parent e si eseguono in serie.
Ogni prova locale produce una plist schema 1 in `out/migrazione-check.lisp`,
letta con `*read-eval* nil`, con comando, ambiente, blob dei sorgenti, stato
compile, risultato, limiti, tempi, stdout/stderr ed eventuale fallimento.
Il record conserva anche i tentativi precedenti se occorrono riparazioni.

## Risultati

Da registrare dopo la compilazione strict e `check` del solo modulo assegnato.
