# SPK-07 — Metodo crash sui byte, preregistrato

;;; REQ: REQ-VAL-001 REQ-FOR-003 REQ-FOR-004 REQ-AFF-002 REQ-AFF-007 REQ-AFF-008 REQ-AFF-009 REQ-AFF-017

Metodo registrato il 2026-10-08 prima di qualsiasi compilazione o CHECK di
questa campagna. Ambito esclusivo: checkout
`/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB`, nuovi
`byte-crash.lisp`, questo metodo e nuovi file ignored nella sua `out/`.
Common Lisp/SBCL, safety 3, warning e style-warning fatali. Nessun codice di
produzione, benchmark, commit o push. Non si caricano core, suite o runner
SPK-07 né altri spike. Fonti lette: ADR0033 (con §4 sostituito da ADR0037),
ADR0037, formati-su-disco, src/foundation/{record,batch,package,crc32c,conditions},
tests/foundation/batch e requisiti già esistenti.

## Domanda e dominio finito

Un recovery in sola lettura conserva la storia dei lotti validi, segnala
esplicitamente il danno che attraversa il prefisso confermato e può essere
interrotto a ogni passo del suo piano finito e rieseguito senza cambiare bytes?

Quattro fixture deterministiche: ordinaria e prepared/OUTCOME, ciascuna in
v1 e v2. Ogni fixture ha tre lotti piccoli. Le chiavi sono singoli byte;
i PUT contengono un intero CBOR di un byte. La fixture ordinaria contiene
PUT a=1, PUT b=2; DELETE a, PUT a=3; DELETE b, PUT c=4. Quella transazionale
contiene prepared PUT p (TXID 100) e PUT a; prepared DELETE p (TXID 101) e
OUTCOME 100→20; OUTCOME 101→30, prepared PUT q senza esito e DELETE a.
CSN dei SEAL: 10, 20, 30; file-id esplicito, offset del buffer nel file 64.
Si verificano anche esiti che risolvono prepared di un lotto precedente.
La storia committed attesa per ciascuno dei quattro prefissi di lotti è
dichiarata letteralmente e non ricostruita mediante un decoder di produzione.

Packing little endian e CRC32C bitwise sono implementati nel nuovo modulo:
nessuna chiamata all'encoder, al packing o al CRC di produzione. Il CRC è
ancorato al vettore noto ASCII 123456789 → E3069283 e al vuoto → 0. Le fixture
sono lette davvero da ARCDOCDB.RECORD:VERIFICA-LOTTO, con versione, file-id,
offset e budget espliciti; i record sono decodificati solo dopo il SEAL valido.
L'oracolo confronta tutta la storia, compresi DELETE, CSN, chiavi e valori,
non soltanto lo stato finale. La risoluzione dei prepared usa solo OUTCOME
dei lotti interamente validi del prefisso; l'assenza di esito lascia il record
invisibile. Non si simula la tabella DECISION di un Archivio ACTIVE reale.

Per ogni fixture si enumerano: identità; tutte le N troncature con lunghezza
disponibile 0..N−1 (buffer fisicamente accorciato); tutte le 8N alterazioni
di un singolo bit in un singolo byte, inclusi header, body e SEAL. Ogni
scenario è incrociato con quattro frontiere confermate, agli estremi dei
prefissi di 0, 1, 2, 3 lotti. Identità rappresenta il taglio N. Le lunghezze
previste sono 322 e 360 byte per le due forme, duplicate per v1/v2:
49.120 casi principali, senza casualità. Ulteriori witness mirati sono
conteggiati separatamente, incluse cornici SEAL semanticamente alterate ma
con CRC riparati dal packing indipendente.

## Frontiera, coda e oracolo

La frontiera F è un fatto esplicito del modello: prova esterna affidabile del
flush e delle conferme, fornita al recovery. Non è una frontiera scoperta
cercando magic o SEAL nel garbage. I SEAL delle fixture dichiarano la
frontiera del prefisso precedente, limitata a F, ma non costituiscono un algoritmo per
trovare tale fatto dopo danno arbitrario. Il primo lotto che non verifica
inizia in P. P<F, o EOF prima di F, produce FAULTED; P≥F produce coda e
lunghezza valida P. Nessun dato viene restituito in FAULTED. Un lotto valido
oltre F può essere recuperato; non viene dichiarato confermato dal modello.
I casi con F=0 rendono esplicita questa differenza. Un secondo calcolo
indipendente usa solo posizioni e tipo del guasto enumerato per determinare
il numero di lotti integri prima del primo danno; non decodifica la fixture.
Il sottoinsieme confermato deve essere interamente presente per ogni esito
accettato. Un danno a un SEAL sotto F rende FAULTED anche se tutti i suoi
record restano leggibili.

Si dichiara il limite dell'ultimo flush non testimoniato: un log da solo non
può distinguere tale danno da una coda (ADR0037, RES-05). F non è una soluzione
di produzione a questa indistinguibilità. Questa campagna colma solo parte
del gap sui byte: niente ricerca di testimoni tra byte arbitrari, intestazione
di segmento, persistenza non ordinata di più guasti simultanei, manifest,
rename/flush reali, filesystem reale o CRC collision-free.

## Interruzioni e controlli negativi

Il piano di lettura ha checkpoint prima di ogni VERIFICA-LOTTO, prima di ogni
decodifica di record del lotto verificato, prima della pubblicazione privata
del lotto e prima del risultato finale. Per ogni caso si interrompe il piano
a ogni checkpoint effettivamente raggiunto, si scarta lo stato privato e si
riesegue da zero. Esito, frontiera valida e storia devono coincidere col primo
risultato. Anche i percorsi FAULTED e coda partecipano. Il confronto bytewise
prima/dopo è richiesto per ogni recovery, interruzione e ripartenza: nessun
truncate, scrittura di segmento o distruzione. Non si promette un crash tra
le singole istruzioni interne al verifier di produzione.

Tre mutanti devono produrre witness pertinenti, con input, guasto, aspettativa
e risultato effettivo: (1) ignorare CRC e accettare un body monobit alterato
nel prefisso confermato; (2) applicare un PUT integro prima del suo SEAL,
troncando prima del SEAL del primo lotto; (3) trattare ogni errore come coda,
nascondendo un danno nel prefisso confermato. I witness devono mostrare,
rispettivamente, dato alterato accettato, storia non committed pubblicata e
perdita silenziosa del prefisso confermato. Non basta un errore generico.

## Budget e registrazione di tutti i tentativi

CHECK esportato dal package ARCDOCDB.SPK07.BYTE-CRASH restituisce una plist
con :status :ok soltanto a campagna interamente conclusa. Budget predefiniti:
60.000 casi, 16 checkpoint per recovery, 2.000.000 recovery avviati,
40.000.000 checkpoint complessivi, 150 secondi per CHECK, buffer ≤512 byte,
tre lotti, quattro record per lotto, 512 byte per VERIFICA-LOTTO. Esaurire
un limite è errore, mai successo parziale. Un controllo atteso con case-limit=1
e uno con step-limit=1 devono fallire esplicitamente; non entrano nel totale
positivo. Il recorder limita ogni figlio a 180 secondi e heap a 512 MiB;
stdout/stderr hanno soglia 8 MiB ciascuno, il superamento è fallimento e gli
originali vengono comunque conservati integralmente. Nessuna misura di
prestazione viene ricavata dal tempo usato per il budget.

Un recorder Common Lisp nuovo in out/ salva il record schema 1 prima di
avviare ciascun figlio SBCL con inizializzazioni disabilitate. Ogni record
contiene argv e stdin esatti (stdin vuoto con script identificato e incluso),
ambiente, contenuti integrali dei sorgenti pertinenti prima/dopo, risultato
decodificato, stdout/stderr integrali, exit code, limiti e fallimenti. Le sole
fondazioni necessarie vengono compilate manualmente, in ordine, in FASL nuovi
in out/: foundation package, conditions, binary, crc32c,
record, batch; quindi il nuovo modulo. I primi tre tentativi caricavano anche
il package radice; non è una dipendenza del modulo. Avvisi fatali e valori warnings/failure
fatali in tutte le compilazioni. Le fasi del figlio sono salvate anche in un
report dati schema 1, compreso il punto del fallimento. Il recorder non legge
altri file di lavoro di altri agenti; commit Git non acquisito. Il bootstrap
del recorder è infrastruttura, non un CHECK aggiuntivo.

I report del modulo conservano fixtures (bytes, lotti e storie dichiarate),
ogni scenario/frontiera, condizioni decodificate, conteggi di interruzione e
restart, witness, limiti e copertura. Report e fixture serializzate sono
artefatti dati: mai LOAD, EVAL o COMPILE-FILE; lettura con *READ-EVAL*=NIL.
Un tentativo fallito resta registrato, e ogni modifica necessaria precede un
nuovo tentativo. Alla consegna si aggiunge qui il consuntivo dei tentativi.
Nessun esito promuove requisiti del motore o chiude il gate della Fase 0.

## Correzione preregistrata dopo il tentativo 03

I tentativi 01/02 hanno verificato l'errore esplicito per case-limit/step-limit;
il tentativo 03 ha concluso la prima campagna. Revisione successiva: il primo
packing dichiarava nei SEAL sempre tutta la frontiera precedente anche nei
casi incrociati con F=0 o F=primo-lotto. Tali combinazioni non rappresentano
un fatto durevole coerente: un SEAL successivo integro dichiarava più di F.
Il record 03 è conservato, ma non è l'evidenza finale del modello corretto.

Prima di nuove prove si corregge il dominio: per ciascuna delle quattro forme
si costruiscono quattro varianti, una per F; ogni SEAL dichiara
64 + min(inizio-lotto, F). Sono quindi 16 buffer, con 49.120 casi complessivi
invariati; ciascun buffer esaurisce identità, tagli e monobit sotto la propria
frontiera. Le storie letterali restano le medesime. L'oracolo delle posizioni
resta separato dal decoder. Un witness aggiuntivo conserva gli stessi bytes
del danno all'ultimo lotto e li legge con F alla fine del secondo o del terzo
lotto: coda oppure FAULTED dipendono dalla prova esterna. Entrambi i buffer
hanno gli stessi SEAL (l'ultimo flush manca di un testimone successivo).
Questo witness rende visibile RES-05 senza pretendere di risolverlo.

Si aggiungono tre prove attese di esaurimento: recovery-limit=1,
read-limit=1 e seconds-limit=1/1.000.000.000; insieme alle due già previste,
devono produrre una condizione BUDGET-EXHAUSTED con il limite pertinente.
I report del figlio conservano anche il caso e la fase del fallimento;
nessun fallimento atteso è dichiarato :status :ok del CHECK.

## Consuntivo e percorsi di tutti i tentativi

Tutti i percorsi seguenti sono relativi a questo metodo nel checkout isolato.
Ogni direttorio contiene `record.sexp` (schema 1 del comando e snapshot
integrali prima/dopo), `data.sexp` (schema 1 del driver e dati del modulo),
`stdin.txt` vuoto, `stdout.txt` e `stderr.txt` integrali e FASL esclusivi.
Il recorder e il driver sono `out/byte-crash-20261008/{record,child}.lisp`.
I report `.sexp` sono dati; non vanno caricati o compilati come sorgenti.

| Tentativo | Record | Esito CHECK e ruolo |
|---|---|---|
| 01 | [record](../results/2026-10-08-avanzamento/byte-crash-attempt-01.lisp) | :failed atteso, case-limit=1, used=2; prima variante |
| 02 | [record](../results/2026-10-08-avanzamento/byte-crash-attempt-02.lisp) | :failed atteso, step-limit=1, used=2; prima variante |
| 03 | [record](../results/2026-10-08-avanzamento/byte-crash-attempt-03.lisp) | :ok preliminare, 49.120 casi; sostituito dalla correzione delle frontiere sopra dichiarata |
| 04 | [record](../results/2026-10-08-avanzamento/byte-crash-attempt-04.lisp) | :failed atteso, case-limit=1, used=2; packing corretto, prima dell'aggiunta del contesto strutturato agli errori di budget |
| 05 | [record](../results/2026-10-08-avanzamento/byte-crash-attempt-05.lisp) | :failed atteso, case-limit=1, used=2; sorgente finale |
| 06 | [record](../results/2026-10-08-avanzamento/byte-crash-attempt-06.lisp) | :failed atteso, step-limit=1, used=2; sorgente finale |
| 07 | [record](../results/2026-10-08-avanzamento/byte-crash-attempt-07.lisp) | :failed atteso, recovery-limit=1, used=2; sorgente finale |
| 08 | [record](../results/2026-10-08-avanzamento/byte-crash-attempt-08.lisp) | :failed atteso, read-limit=1, used=2; sorgente finale |
| 09 | [record](../results/2026-10-08-avanzamento/byte-crash-attempt-09.lisp) | :failed atteso, seconds-limit=1/1.000.000.000, used=477/1.000.000; sorgente finale |
| 10 | [record finale](../results/2026-10-08-avanzamento/byte-crash-attempt-10.lisp) | :ok, campagna corretta completa; sorgente finale |

Otto fallimenti di budget previsti e due CHECK completi; nessun fallimento
imprevisto di compilazione o esecuzione. Le otto compilazioni dei tentativi
01–03 e le sette dei tentativi 04–10 fanno 73 compilazioni strict concluse,
senza warning/style-warning né valori warnings/failure. Tutti i record hanno
`:source-stability :stable`. La shell del recorder esce 0 anche per un
fallimento atteso riconosciuto: il CHECK e il figlio restano :failed/exit 1.
Il metodo è completato con questo consuntivo dopo il tentativo 10; il suo
snapshot preregistrato integrale è conservato nel record del tentativo.

La prova finale compila solamente i sei file foundation e byte-crash.lisp:
non occorrono package radice, storage, test, core o suite. Comando esatto del
recorder (argv del figlio e contenuto del driver sono nel record):

```sh
cd /Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB
/opt/homebrew/bin/sbcl --dynamic-space-size 512 --noinform --no-userinit --no-sysinit --script spikes/SPK-07-protocols/out/byte-crash-20261008/record.lisp attempt-10 full
```

`attempt-10` esiste già e il recorder rifiuta di sovrascriverlo. Per una nuova
prova si usa un nuovo nome di tentativo. Il modulo esporta CHECK nel package
ARCDOCDB.SPK07.BYTE-CRASH ed è autonomo rispetto agli altri modelli.

### Conteggi finali

- 16 fixture: quattro forme (ordinaria/prepared, v1/v2), ciascuna con quattro
  fatti di frontiera coerenti. Buffer di 322 o 360 byte; tre lotti ciascuno.
- 49.120 casi principali: 16 identità, 5.456 troncature byte per byte,
  43.648 alterazioni monobit. Nessuno scenario casuale o campionato.
- 16 esiti complete, 25.092 code, 24.012 danni sotto il prefisso confermato
  esplicitamente respinti come FAULTED. Nessun risultato FAULTED pubblica dati.
- 655.997 recovery avviati, 3.760.830 checkpoint eseguiti, massimo 14
  checkpoint per recovery; 303.432 interruzioni e 303.432 ripartenze complete
  con risultato identico e bytes immutati. Conteggi dei checkpoint interrotti
  prima dell'esecuzione esclusi dal totale dei checkpoint eseguiti.
- Tre controlli negativi con witness pertinenti; cinque campi del SEAL
  alterati e CRC riparati indipendentemente, tutti respinti con :seal-mismatch;
  un witness aggiuntivo sull'ultimo flush non testimoniato (due letture).
- I 13 recovery dei witness si aggiungono ai 49.120 recovery iniziali e ai
  606.864 recovery di interruzione/ripartenza. I witness sono aggiuntivi e
  non rientrano nei 49.120 casi principali né nella loro campagna di restart.

Il [report dati finale](../results/2026-10-08-avanzamento/byte-crash-attempt-10.lisp) conserva
tutte le fixture e storie letterali, le 49.120 righe di scenario, condizioni
tipizzate e posizioni osservate, witness e conteggi. Ogni riga identifica
fixture, guasto, frontiera, prefisso atteso/ottenuto, classe, checkpoint e
numero di interruzioni/ripartenze; la storia verificata è quella dichiarata
per il prefisso nella fixture (oppure nessuna per FAULTED).

Limiti applicati nella prova finale: 60.000 casi, 16 checkpoint per recovery,
2.000.000 recovery, 40.000.000 checkpoint complessivi, 150 secondi del CHECK;
buffer e budget del lotto 512 byte, massimo quattro record prima del SEAL,
tre lotti per fixture. Il figlio ha watchdog 180 secondi, heap 512 MiB e
soglie di stdout/stderr 8 MiB ciascuno con output originale integrale. Nessun
limite è stato raggiunto nella campagna positiva. Le cinque prove di budget
del sorgente finale conservano nome, valore, massimo e caso della condizione.

La copertura resta finita e condizionata alla prova esterna di F. L'ultimo
flush senza testimone successivo resta indistinguibile sul solo log; il
witness conserva proprio bytes identici con esiti diversi per i due fatti
esterni. Non sono provati filesystem, flush/rename reali, CRC senza collisioni,
persistenza con guasti simultanei, intestazioni di file, DECISION, manifest
o recovery completo del motore. Nessun benchmark, commit/push o modifica ai
file esistenti è stato eseguito da questa campagna.
