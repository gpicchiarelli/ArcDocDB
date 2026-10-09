# Seconda lettura C1 indipendente — registro CSN

**Stato corrente:** CSN-C1-01 risolto dalla rilettura della rifattorizzazione;
nessun rilievo statico residuo nell'ambito letto. L'addendum finale aggiorna
la prima lettura qui conservata, inclusi gli hash iniziali e i test allora assenti.

Revisione statica delimitata del 2026-10-09, indipendente dalla realizzazione,
nel workspace `/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB`.
Riferimento Git: `92d8b0ebf498800e4847bc4828560c6dac879c0e`; i file CSN
letti sono modifiche del workspace, non una consegna congelata o un commit.
Rilevazione degli hash: 2026-10-09T07:38:05+00:00.

Sono stati letti il prodotto, il metodo preregistrato, la tabella delle decisioni,
il contratto pubblico, ADR-0046/0038/0045 e lo standard C1. L'ispezione del supporto
dei test e di sezioni del benchmark è statica. Nessuna compilazione, suite,
misura, mutazione, copertura o strumento del progetto è stata eseguita.
Le sole scritture del revisore sono questo documento e
`/tmp/arcdocdb-csn-review.lisp`, record dati con `:schema-version 1`.
Nessun commit. Questa lettura non conferisce approvazione C1, deroga o qualifica
del motore.

| File letto | SHA-256 |
|---|---|
| `src/csn/package.lisp` | `b9fa9bac97e89dd43bd91e6050ac7f6bbba47109403350478b2df8ca851f01a0` |
| `src/csn/registry.lisp` | `81fcc0181b883f299c6fe33b3b1bc05a8a6f0d756ef06717eaff1fdde73050a6` |
| `docs/implementazione/csn.md` | `c46cce29aa8fc6ae5f8390eb9cc8d1023b98328dfa6ec33d8c88fbaf2a42cecf` |
| `docs/implementazione/csn-metodo.md` | `f2b18cdf170478141c955c1d77f5393daf23c27888abd6e6dbd2f219a5de604c` |
| `docs/implementazione/csn-decisioni.md` | `ade75b4b0bb050f79b2f8ded23b21745c9a939839b35d1e521c1632ba80aaab6` |

Il record conserva anche gli hash degli altri riferimenti e dei file di
supporto presenti. La conclusione riguarda questi contenuti; una modifica
successiva del prodotto richiede una lettura del diff.

## Rilievo da restituire al parent

**CSN-C1-01 — COD-13, complessità dei due helper (P2, aperto).**
Lo [standard](../affidabilita/standard-di-codifica.md) impone al più dieci
percorsi indipendenti per funzione. Contando i rami del cortocircuito
`and`/`or`, oltre alle decisioni e ai cicli espliciti:

| Funzione e righe | Conteggio manuale |
|---|---|
| `%check-token-csn`, `src/csn/registry.lisp:130–146` | Base 1 + tre `unless` + 4 rami del primo `and` + 1 dell'`or` annidato + 1 del secondo `and` + 2 del terzo `and` = **12**. |
| `%frontiera-risolta-csn`, `src/csn/registry.lisp:150–171` | Base 1 + un `dotimes` + quattro `unless` + due `when` + un `if` + due rami dei due `and` = **11**. |

È un conteggio statico del flusso scritto, non una misura di copertura né
un conteggio dell'espansione di `with-mutex`. La tabella delle decisioni
inventaria le condizioni ma non documenta il rispetto di COD-13;
il registro delle deviazioni dichiara «Nessuna».
Il parent deve ridurre la complessità, per esempio separando validazione
della forma del token e controllo di un pendente residuo, oppure motivare
esplicitamente un diverso criterio di conteggio. Questa revisione non
approva una deroga. Nessun errore nel calcolo dei CSN o di H è stato individuato
nelle transizioni sane esaminate.

## Osservazioni proprie sul prodotto

- **Carry e borrow.** Le due parole restano u32; il confronto è lessicografico.
  Da base `(0,#xfffffffe)`, due prelievi producono `(0,#xffffffff)` e
  `(1,0)`. Risolvendo il primo, il minimo residuo `(1,0)` diventa
  H=`(0,#xffffffff)`: il borrow è corretto. Il guard sul massimo precede
  l'incremento, impedendo `high=2^32`. Sono passaggi dedotti dal sorgente,
  non test eseguiti.
- **Nessun CSN assegnato invisibile al registro nelle chiamate completate.**
  Lo slot viene scelto e le due parole scritte prima di aggiornare ultimo,
  cursore e conteggio; nessuna API pubblica può leggere o risolvere nel mezzo,
  perché usa la stessa guardia. H viene calcolato escludendo solo lo slot
  risolto e considerando tutti gli altri slot non zero, prima di mutare.
- **Controesempio ADR-0046.** Con K=2, mantenendo 1 pendente e prendendo e
  risolvendo 2, 3, 4, 5, resta riusabile il credito del secondo slot e H resta
  0. Risolvendo infine 1, nessun pendente resta e H diventa 5.
  Non c'è indicizzazione tramite `csn mod K`.
- **Guardia senza attesa.** Il registro è valutato una volta; il controllo
  dell'owner corrente evita un'acquisizione ricorsiva. Il tentativo effettivo
  usa `sb-thread:with-mutex ... :wait-p nil`. Il flag `acquired` distingue
  il mutex occupato da un corpo che ritorna NIL; `multiple-value-prog1`
  conserva i valori multipli. Cleanup e gestione del mutex sono delegati
  alla macro del runtime. L'ispezione non prova gli interleaving o la gestione
  di un'interruzione asincrona durante gli store.
- **Token e rifiuti.** Range e tipo precedono l'accesso allo slot; entrambe
  le parole devono coincidere. Nessun wrap e nessuna modifica della base
  permettono a un token risolto di tornare valido nel medesimo registro.
  Un altro registro può emettere lo stesso `slot/high/low`: l'associazione
  al registro è un obbligo del chiamante, dichiarato nel codice e nel
  contratto. Non viene garantita l'identificazione dell'Archivio dal token.
- **Priorità degli errori.** `:csn-full` precede `:csn-exhausted`.
  Con K=1 e l'ultimo token uguale al massimo u64 ancora pendente, un nuovo
  prelievo segnala full; dopo la risoluzione segnala exhausted. Entrambi i
  rifiuti avvengono prima degli store. La suite finale deve conservare questa
  priorità o documentarne la modifica.
- **Limite delle difese.** `%check-registro-csn` verifica `used≤K`, non
  l'uguaglianza fra used e gli slot occupati. La cardinalità esatta viene
  verificata solo da `%frontiera-risolta-csn`. Per esempio, una FI che
  porta used da 1 a 2 in un registro K=2 con un solo pendente passa il
  controllo generale e può produrre full al prelievo; la risoluzione
  rileva poi l'incoerenza prima di mutare. Non è una transizione raggiunta
  da un uso sano dell'API. La docstring «conteggio ... coerenti» è più ampia
  del controllo generale effettivo: il parent deve delimitare tale garanzia.

## Checklist C1 compilata

La numerazione segue i dodici punti dello
[standard di codifica](../affidabilita/standard-di-codifica.md);
i criteri di evidenza seguono il
[piano di verifica](../affidabilita/piano-di-verifica.md).

| Punto | Riscontro e limite |
|---|---|
| 1. Requisiti e ADR | Annotazioni REQ-MVC-005/008 e REQ-AFF-008 presenti. ADR-0046 è realizzato dal registro dei soli pendenti. INV-M4/M6/A8 pertinenti; INV-P6 e ownership riguardano il coordinamento per lotto. REQ-MVC-005 resta un contributo locale: nessuno snapshot è implementato. |
| 2. Invarianti e test | Assegnazione/registrazione indivisibili, slot esclusivo, H≤ultimo, H<pendenti e convergenza a vuoto analizzati. Il supporto presente usa interi matematici e lista dei token, senza riusare gli helper aritmetici del prodotto. Test sequenziali e thread dichiarati da ASDF assenti alla rilevazione: non attestata la loro copertura. |
| 3. Errori e gestione | Config/token: `invalid-argument`; busy/full/exhausted: `resource-exhausted`; incoerenze: `invariant-violation`. I rifiuti ordinari precedono le modifiche. Risoluzione busy conserva token e obbligo; fail-stop dell'Archivio resta al controller. Suite per tutti gli errori e cleanup su errore non eseguita. |
| 4. Cicli e attese | Due scansioni al più K≤65536, nessuna ricorsione, callback, I/O o retry nel prodotto. Un solo tentativo del mutex per chiamata. Il supporto dei test ha deadline, join finiti e controllo di cessazione nel cleanup; mancano le fixture effettive su thread. |
| 5. Allocazione misurata | Array e mutex costruiti all'avvio. Successi usano parole u32 e valori multipli, senza costruire un u64/bignum o un token oggetto. Su SBCL a 64 bit le parole sono fixnum. Zero heap resta **da misurare** con controllo positivo, cinque campioni, basi alte e pendente più vecchio fisso. Presenza del benchmark non significa esecuzione riuscita. |
| 6. Dati verificati | Il token è validato prima di indicizzare; base e capacità sono validate prima della costruzione. Il registro non verifica effetti pubblicati/annullati, identità del chiamante o massimo recuperato dai file: sono precondizioni. La lettura delle frontiere verifica i limiti generali, non tutta la cardinalità degli slot. |
| 7. Decisioni composte | Configurazione, forma/frontiere, esaurimento, slot libero, forma/identità token, pendenti residui e confronto u64 sono nella tabella letta. Restano da collegare i casi effettivi alle singole condizioni, le coppie di indipendenza, copertura grezza e mutanti compilati. Nessuna attestazione MC/DC. |
| 8. Proprietà e condivisione | OWNER/SHARED espliciti, un registro per Archivio, slot privati, nessun copier, campi immutabili read-only. Le API acquisiscono la stessa guardia; i token restano associati al registro dal chiamante. Gli array read-only come slot contengono elementi mutabili protetti dal mutex. |
| 9. Trace e check | ASDF carica foundation prima di CSN e registra support/registry/threads per i test. Registry e threads dei test non sono presenti alla rilevazione. Requisiti e matrice restano `progettato`. Compilazione, lint, trace, link, copertura, mutanti e `make check` finali sono da acquisire dal parent su sorgenti fermi. |
| 10. Regole e deviazioni | Safety 3, FTYPE delle funzioni, slot tipizzati, docstring, annotazioni REQ e funzioni sotto 60 righe presenti. **COD-13 aperto**, come sopra. Il test di espansione della macro richiesto da COD-53 non è presente nel supporto letto e va ispezionato nella suite finale. Nessuna deroga approvata. |
| 11. Parallelismo fra Serie | Mutex e store condivisi sono dichiarati per assegnazione e risoluzione del lotto/decisione; la lettura è per coordinamento. Nessun accesso per documento o GET semplice richiesto dal contratto. Lo scheduler può riprogrammare busy/full; fairness, scalabilità e limiti dei parcheggi restano da implementare e misurare. |
| 12. Atomicità e rimozioni | Solo stato volatile; nessun I/O, flush, eliminazione o punto di atomicità durevole. Il mutex rende coerente la transizione in memoria. H non è la frontiera dei byte durevoli e risolvere non costituisce conferma di commit. |

## Evidenze mancanti e integrazione successiva

Alla rilevazione erano presenti `tests/csn/support.lisp` e
`tools/csn-bench.lisp`; erano assenti `tests/csn/registry.lisp`,
`tests/csn/threads.lisp` e `tools/csn-mutation.lisp`.
Non sono stati letti risultati di campagne CSN. Il parent deve completare
e congelare la suite, includendo carry, borrow, confine fixnum, massimo u64,
token stale, rifiuti senza mutazione, contesa/ricorsione e valori/cleanup
della macro. Deve poi collegare oracolo, esplorazione finita, thread reali,
mutanti, sensore heap e check agli stessi hash del prodotto e rileggere
eventuali modifiche.

Il recovery deve determinare il massimo CSN validato dell'intero Archivio
prima della costruzione e dell'ammissione delle scritture. Apertura tardiva
di Serie con massimo superiore, WAL, pubblicazione dell'indice, fail-stop,
annullamento corretto, shutdown, riprogrammazione e registrazione/risveglio
degli snapshot sono integrazioni successive dichiarate. Un token perso o
un controller che abbandona la risoluzione può trattenere credito e H;
il registro non può liberarlo automaticamente. Nessuna prova di durability,
recovery completo, P99 o prestazioni del motore è dedotta da questa lettura.

## Addendum — rilettura della rifattorizzazione e dei test presenti

Rilettura statica conclusa a 2026-10-09T07:44:59+00:00, dopo la correzione
del parent. **CSN-C1-01 risolto nell'ambito della lettura statica.**
Il rilievo e gli hash iniziali sopra restano conservati. L'osservazione sulla
docstring del controllo generale è anch'essa risolta: ora distingue limiti
del conteggio e cardinalità esatta controllata alla risoluzione.

| File riletto o comparso | SHA-256 della rilettura |
|---|---|
| `src/csn/registry.lisp` | `56262b96c0b3fdfc92289e37e80dadb17c49870c57c57e89ab7afba4bb74f14a` |
| `src/csn/package.lisp` | `b9fa9bac97e89dd43bd91e6050ac7f6bbba47109403350478b2df8ca851f01a0` |
| `tests/csn/support.lisp` | `6b19e1c80a8b2e91b4a6bfc6b3cfeae962ed9cd919d6df1a92b58ab3b49255db` |
| `tests/csn/registry.lisp` | `c4e24c711f0ac63e33149bc866d8a62c0eb6e92528b2710a09b74ffc4c78a950` |
| `tests/csn/threads.lisp` | `0470dc35f8c5cd4ca294712fd439e7865e3702fe243a72b9f57194d099f2b5d2` |

La tabella delle decisioni mantiene l'hash iniziale e le condizioni restano
pertinenti. Il nuovo helper dei pendenti aggiunge nella scansione il controllo
`used>0`, già stabilito sul token risolto prima della scansione sotto lo
stesso mutex: è ridondante per questa chiamata e non modifica la transizione.

### Conteggio indipendente della versione corretta

Uso lo stesso criterio del rilievo: base 1, una decisione per
`if/when/unless` e ciclo, più N−1 rami di cortocircuito per ogni
`and/or` di N condizioni. Non conto le funzioni chiamate o l'espansione
delle macro del runtime come rami della funzione chiamante.

| Funzione | Conteggio manuale |
|---|---|
| `%check-forma-token-csn`, riga 131 | 1 base + 1 unless + 4 and + 1 or = **7**. |
| `%check-pendente-csn`, riga 141 | 1 base + 1 unless + 2 and = **4**. |
| `%check-token-csn`, riga 154 | 1 base + 1 unless + 1 and = **3**. |
| `%frontiera-risolta-csn`, riga 167 | 1 base + 1 dotimes + 3 unless + 2 when + 1 if + 1 and = **9**. |
| `%check-registro-csn`, riga 53, flusso invariato | 1 base + 4 when/unless + 4 and + 1 or = **10**. |

Tutte queste funzioni rispettano il limite di 10 con il criterio usato.
I nuovi helper hanno FTYPE, docstring e annotazioni REQ; non scrivono
il registro. Forma e range continuano a precedere gli accessi allo slot,
l'identità precede il controllo delle frontiere, e la scansione continua
a concludere controllo dei residui/conteggio prima degli store.
Firma e valori delle API, mutex, carry/borrow, priorità degli errori,
slot, token e aggiornamenti delle frontiere risultano invariati alla lettura.
Nessun nuovo difetto funzionale individuato; nessuna esecuzione effettuata.

### Aggiornamento dei punti della checklist

| Punto iniziale | Aggiornamento della rilettura |
|---|---|
| 2. Invarianti/test | Registry e threads ora presenti e letti integralmente. Il modello usa interi/lista indipendenti; casi carry/borrow, confine fixnum, massimo u64, completamento inverso, credito, stale, controesempio fino a 65 e FI sono presenti. Esplorazione K=2/3 fino a sei commit e 10.000 azioni deterministiche sono codice di prova, non risultati ottenuti. |
| 3. Errori | Suite presente per configurazione, token, full/exhausted, shape, frontiere e conteggio residuo; immagini private confrontate nelle FI. Conservazione dello stato e tipi sono asserzioni da eseguire, non attestazioni della revisione. |
| 4. Cicli/attese | Fixture con mutex trattenuto esige il join del probe prima del rilascio: può rilevare un try-lock diventato bloccante. Quattro worker × 1.000 assegnazioni, K=3, due onde forzano full e riuso; deadline 20 s, cleanup con join limitato e controllo di cessazione. Nessuna esecuzione o prova esaustiva degli interleaving. |
| 5. Allocazione | Nessun costruttore nei nuovi helper; zero heap resta da misurare sul nuovo hash. Le campagne precedenti o sul vecchio hash non si trasferiscono automaticamente alla versione corretta. |
| 7. Decisioni | Le condizioni prima concentrate nel token sono distribuite nei due helper. La tabella resta applicabile; conteggio, copertura grezza, coppie di indipendenza e kill dei mutanti richiedono evidenze finali sul sorgente rifattorizzato. |
| 9. Integrazione/check | I file test dichiarati da ASDF sono ora presenti. Anche `tools/csn-mutation.lisp` è comparso e ne sono state ispezionate sezioni; non è stato eseguito o qualificato dal revisore. Build/lint/trace/link/check restano da acquisire. |
| 10. Standard | COD-13 chiuso con conteggi 7/4/3/9 e controllo generale 10. Il test della macro ora presente verifica valutazione singola, NIL, zero e più valori, errore, uscita non locale e ricorsione; il test su altro worker verifica busy con corpo non eseguito. Sono verifiche del comportamento dell'espansione da compilare/eseguire; nessuna macroespansione o suite eseguita qui. |

I punti 1, 6, 8, 11 e 12 conservano l'ambito della prima lettura.
Al punto 6 la precisazione della docstring ora coincide con il limite osservato;
restano obblighi del chiamante il legame token/registro e gli effetti pubblicati
o validamente annullati. I limiti di lifecycle, recovery, snapshot, durata
e parallelismo del motore già dichiarati restano aperti.

**Esito corrente:** nessun rilievo statico residuo nell'ambito letto.
Le assenze iniziali sono una rilevazione storica, superata dalla presenza
e lettura statica dei test nell'addendum. Il parent può congelare questo hash
per le proprie campagne; la revisione non dichiara che il congelamento o le
campagne siano già avvenuti. Nessuna approvazione C1 o deroga, nessun test,
benchmark, strumento del progetto o commit eseguito dal revisore.
