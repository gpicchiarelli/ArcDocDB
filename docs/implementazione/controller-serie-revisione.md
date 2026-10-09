# Revisione indipendente del controller di Serie

Data: 2026-10-09. Base dichiarata e osservata:
`cf6091367853ec311fed7b05961a2812fd05a8f1`. Worktree condiviso:
`/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB`.

## Stato della lettura

Prima fase: contratto, rischi e inventario delle decisioni attese preparati.
`src/series/` e le nuove preflight WAL non erano presenti alla prima ricognizione.
Sono poi comparsi tutti gli otto file di `src/series/` e le nuove preflight WAL.
Le letture statiche complete B/C e l'addendum D sono svolti. Nella fase D il
parent dichiara congelato il prodotto, mentre test/strumenti sono ancora in
integrazione. L'aggiornamento comprende fix P2 e ritiro I/O senza consegna:
42 funzioni Series e 6 helper WAL, massimo di complessità 8 includendo corto
circuito, case e handler. I due P2 B/C sono chiusi alla rilettura D; nessun
nuovo P1/P2 individuato sotto le precondizioni dichiarate. La review C1 della
modifica con prove e due letture resta alla campagna di integrazione.

Attività esclusivamente statica; nessun test, build, benchmark, driver, misurazione
di heap o campagna di mutazione eseguita. Nessuna certificazione umana, MC/DC o garanzia del
motore completo. Il parent esegue la propria prima lettura e l'integrazione; questa
è la lettura indipendente assegnata.

## Ambito e proprietà dei file

Scritture di questo incarico limitate a:

- `docs/implementazione/controller-serie-decisioni.md`;
- `docs/implementazione/controller-serie-revisione.md`.

Nessuna modifica a prodotto, ASDF, test, strumenti o documenti degli altri agenti.
Nessun branch, commit o push creato. Non vengono duplicati prodotti, prove o
benchmark degli incarichi paralleli.

Sorgenti del perimetro letti: **tutti** i file di `src/series/`, le
preflight pubbliche `verifica-token-lotto`, `verifica-pubblicazione-lotto` e
`marca-log-faulted`, con `verifica-log-segmento`, `verifica-riuso-lotto`,
`verifica-ritiro-lotto`, relativi export e contesto del resolver WAL preservato.
ASDF viene consultato per il confine delle dipendenze, senza modificarlo.

Contesto già letto: `src/wal/csn.lisp`, `src/wal/types.lisp`,
`src/wal/group.lisp`, `src/wal/executor.lisp`, `src/wal/package.lisp`,
`src/csn/registry.lisp`, `src/csn/package.lisp`, condizioni di fondazione,
ADR-0037/0046/0033 e standard di codifica.

## Criterio per l'identità delle evidenze

La base Git identifica il punto di partenza; nel worktree condiviso non identifica
automaticamente il contenuto corrente. A ogni lettura del prodotto si registrano
file e impronte del contenuto letto, distinguendo una revisione intermedia dalla
revisione congelata. Un confronto d'impronte prima/dopo documenta solo la stabilità
durante quell'osservazione; non sostituisce la dichiarazione di congelamento
dell'integrazione. I registri runtime source-stable competono alla campagna del
parent dopo il congelamento.

| Fase | Identità | Conclusione permessa |
|---|---|---|
| Preparazione | Base `cf6091367853ec311fed7b05961a2812fd05a8f1`, controller assente. | Obblighi/rischi attesi e contesto WAL. |
| Lettura intermedia A | Quattro file Series: package/types/ownership/events; WAL builder/csn/executor/package. Impronte del percorso CS-REV-01 sotto. | Osservazioni statiche sul solo contenuto letto; integrazione ancora aperta. |
| Addendum D prima delle prove | Congelamento del prodotto dichiarato dal parent nel messaggio; blob C1 e SHA-256 sotto. Test/strumenti ancora in scrittura. | Chiusura statica dei P2 e revisione del nuovo ritiro; nessun esito runtime attribuito a questa review. |

Impronte SHA-256 della lettura intermedia A (non registro source-stable di campagna):

| File | SHA-256 |
|---|---|
| `src/series/events.lisp` | `08f85caf9911a11d0564d320c05b236cbbca4edde5b5160df9e752950933e7d1` |
| `src/series/ownership.lisp` | `ce9292668f85d7cc5ba036c0ebd71a8910d67029d02eaab82d9bcf8650489c0c` |
| `src/wal/csn.lisp` | `7439be1ce198f9d894988108d5aa05ef2c692a2af732e94304f4b6393b172339` |

Impronte SHA-256 della lettura completa B, successiva all'annuncio del prodotto
scritto. Questa è identità della lettura statica, **non congelamento né registro
source-stable di campagna**:

| File letto | SHA-256 |
|---|---|
| `src/series/package.lisp` | `a13ff4b2a08ac287203575f99a04c4c23653d5ffeb86cf5290b44562e7ec8bcd` |
| `src/series/types.lisp` | `a225d83965f7a9e049a46a1a9c5715829e060284840527814904463e3bba8eed` |
| `src/series/ownership.lisp` | `e2622e71628cc78d0d940aac5673ef4817d08d7f3e826dd10a9d27bf9e591f7b` |
| `src/series/events.lisp` | `598b23b09c0c031524c1f72c113872e3f6ad263a2a2763187ceecc2806b70f54` |
| `src/series/io-events.lisp` | `d03cd08f9c291d79777f040e7b532d283effee5633dbe134d6d77b5000b39a87` |
| `src/series/publication.lisp` | `288cb3fa41fad76a0e6919dfa0b2fce2beef15f5880129393bee35bc8795c762` |
| `src/series/query.lisp` | `6848ee27967c8f4128d4026fbcc06727af9e30dfaac1a7695317c4827051de03` |
| `src/series/retirement.lisp` | `360a59f603306ca270446a23d998801c692e9451060736163c9d19fa41d13a32` |
| `src/wal/csn.lisp` | `7439be1ce198f9d894988108d5aa05ef2c692a2af732e94304f4b6393b172339` |
| `src/wal/builder.lisp` | `b105dbd8a704694fd061bca155692e8c394c3d2272b9f9f0a06285cf9849d22b` |
| `src/wal/executor.lisp` | `d5fce79d73f6d5115602fabb822ba36ab4ec376dfba5025c5bf1426f6ec438d8` |
| `src/wal/package.lisp` | `ed438c9bad09752e8b898b8ad858a62e3129c4f723803e65cb9af67abbca43f8` |
| `arcdocdb.asd` | `61bad4cbfbb0defe8cc325beb5ddf7100b265829e06af40523f609a04e5697e3` |

### Aggiornamento C: geometria ring, log segmento e contratto parent

La lettura C sostituisce nella tabella B le seguenti impronte; per gli altri
file le impronte B sono immutate. Il contratto del parent viene aggiunto come
fonte. Ancora nessun congelamento o esecuzione di campagna:

| File | SHA-256 lettura C |
|---|---|
| `src/series/types.lisp` | `f4421765dc166310ab2f1801052d2c4b8083be19cb0b32d84d2dcdfd41afb3e4` |
| `src/series/ownership.lisp` | `640368ff404af2c02f31ac2525a8a1887de5d1c0e62f645bc64a9ecbe708fb6d` |
| `src/series/io-events.lisp` | `f238e614e39c03e2564210bbc83907597a97bf89b1b05f43e42b13a2b1c64731` |
| `src/series/package.lisp` | `57c89fbf69170c6d05cee004bc294d16c63b53adb3dd7ace39591d95605ba630` |
| `src/wal/csn.lisp` | `2fc52ddc064a87c32c44d1a8a9756de65b75b25dd705fdf24be1da53ef5ab810` |
| `src/wal/package.lisp` | `471a9f9da06d22db4b6cea4b7d0856515ddb879427dd682cf76757319f8c13c5` |
| `arcdocdb.asd` | `3863976de1b2b6ba63c8fafa42b1549f8e596d40a885992de41ffc5d2923da19` |
| `docs/implementazione/controller-serie.md` | `6a593ca77f1987f55221e5e901c957782597a35a373e283abb8decaa4bd78509` |

`%check-ring` chiama `%check-geometry` dopo i limiti: verifica entrambe le
identità modulari `tail=head+count` e `tail=publish-head+unresolved`.
`%position-after` somma solo position<capacity e amount≤capacity: somma massima
2047, al più una sottrazione, nessun wrap fixnum. I nuovi helper sono senza
scansione e senza mutazione del ring. Le post-guardie di adozione, advance e
riuso vengono eseguite dopo gli aggiornamenti di tutti i cursori/contatori.

La factory delega `verifica-log-segmento` prima delle allocazioni, con
invalid-argument `:log-segment-kind` per control/multiserie e io-fault per log
guasto. La preflight di pubblicazione delega la stessa verifica; la guardia
originale del resolver su `lotto-csn-log` è invariata, con una sola occorrenza
dell'anchor del mutatore WAL precedente. Questo è confronto testuale statico:
nessun test o mutatore è stato avviato.

## Obblighi prioritari della lettura

1. Separare CAS della radice, risoluzione del token, fine I/O e due FIFO;
   `:async` risolto può restare occupato/attivo fino al flush.
2. Verificare authority della lease: CAS singolo, thread, generazione corrente,
   budget fixnum senza wrap e rilascio/riacquisizione per trasferimento.
3. Verificare authority dell'evento: oggetto del ring del controller più
   generazione catturata; mai autorizzazione tramite soli slot/CSN numerici.
4. Verificare adozione `:sealed` prima del dispatch, root `nil` valida,
   contiguità offset, CSN crescente in due parole, capacità e budget pre-mutazione.
5. Verificare preflight di log/token/copertura prima del CAS; solo `:csn-busy`
   diventa pendente; `:pubblicato` ritenta il resolver senza un nuovo CAS.
6. Verificare fine I/O dopo handoff conclusivo durable/faulted, doppio dispatch
   rifiutato, decremento esatto e drenaggio possibile dopo fault.
7. Verificare guasto terminale e upgrade Serie→Archivio; stato incerto o
   invariant richiede Archivio, guasto I/O noto Serie.
8. Verificare annullamento FIFO solo faulted Serie con **tutto** l'I/O quiescente;
   token catturato e log faulted; rifiuto automatico in ambito Archivio.
9. Verificare riuso FIFO solo risolto/retired/durable/owner nullo;
   rifiuti prematuri prima del reset e generazione conservata.
10. Inventariare ogni funzione e decisione composta, complessità massimo 10
    includendo corto circuito, tipi/docstring/pre-post e limiti di scansione.

La matrice dei predicati e dei rischi è in
[controller-serie-decisioni.md](controller-serie-decisioni.md).

## Precondizioni che la review non può dimostrare dal solo controller

La root è immutabile e preparata fuori dal controller. Il chiamante esegue un
handoff attendibile della fine I/O. L'adozione precede il dispatch. Un confine
chiamante deve applicare fail-stop Archivio per interruzioni nonlocali nella
finestra root/stadio o registro/token incerta. L'unicità controller/log e il
rilascio del gruppo prima del riuso sono discipline di ownership. La lettura
statica può verificare che queste precondizioni siano esplicite e rispettate dai
percorsi locali; non certifica scheduler, indice o recovery del motore.

## Riscontri sul prodotto

| ID | Priorità | File/funzione | Trigger e conseguenza | Stato |
|---|---|---|---|---|
| CS-REV-01 | P2 originario | `src/series/events.lisp:83` e `src/series/retirement.lisp:21` nella versione B/C. | Le preflight token e riuso potevano propagare un'invariante prima di `%begin-effect`, lasciando il controller healthy. | Chiuso staticamente nell'addendum D tramite `%capture-token` e `%check-lotto-release`. |
| CS-REV-02 | P2 originario | `src/series/query.lisp:48` nella versione B/C. | Il getter poteva restituire la phase interna `:pubblicando`, fuori dai cinque esiti contrattuali. | Chiuso staticamente nell'addendum D: case su cinque stati; altrimenti serie-event-uncertain e Archivio. |
| CS-REV-03 | Osservazione normativa | `src/series/ownership.lisp`, `%end-effect`; sei percorsi originali e nuovo ritiro I/O. | Prima lettura letterale conservativa proponeva una deviazione; riesaminata la risorsa acquisita/rilasciata e il contratto del parent. | Richiesta di deviazione ritirata: cleanup di proprietà con marcatura terminale protettiva, secondo l'interpretazione motivata sotto. Nessuna approvazione umana attribuita. |

Le spiegazioni CS-REV-01/02 seguenti conservano i percorsi della versione B/C;
la chiusura effettiva e le identità D sono nell'addendum successivo.

**CS-REV-01 — Fail-stop della preflight di adozione (storico B/C).** La guardia di lease/ring
è già passata, ma la chiamata diretta a `verifica-token-lotto` può propagare
un'invariante del ponte WAL senza `%mark-fault`. Un esempio di stato corrotto
è `csn-pending=t` con `csn-high=csn-low=0` oppure log assente: il ponte segnala
l'invariante senza mutare il registro, mentre il controller resta healthy.
Non è un normale rifiuto stale/full e non va normalizzato a pending.
La stessa funzione usa già `%check-captured-token` per convertire difetti di
un evento adottato in fault Archivio, ma l'adozione iniziale bypassa quel confine.
Nella lettura B lo stesso problema è presente nel riuso: un lotto durable con
`lotto-used > length(lotto-buffer)` attraversa le guardie evento/retired/FIFO e
`verifica-riuso-lotto` segnala `invariant-violation :lotto-length` tramite
`esigi-lotto`. La prima preflight è esterna all'effetto protetto; evento e lotto
non vengono riusati, ma la Serie resta healthy. Il secondo controllo dentro
`riusa-lotto` è protetto e non compensa quello precedente.

Richiesta: garantire faulted Archivio anche per l'invariante di queste preflight,
conservando i normali rifiuti invalid-argument pre-adozione e lotto/token al caller.
Nessuna correzione di prodotto eseguita dal revisore.

**CS-REV-02 — Stato pubblico fuori dal contratto (storico B/C).** `%publish-root` assegna
`:pubblicando` prima del CAS e `:pubblicato` dopo. Un trasferimento nonlocale
fra quelle assegnazioni lascia la phase intermedia; `%end-effect` rende il
controller archive-faulted. Con oggetto/generazione ancora validi, il getter
pubblico ritorna comunque `:pubblicando`. È utile conservare questo marcatore
interno per riconoscere lo stato incerto, ma il chiamante non può trattarlo come
uno dei cinque esiti API promessi. Allineare il getter al contratto, rifiutando
la fase incerta con condizione tipizzata, oppure esplicitare l'estensione nella
specifica pubblica e nei suoi obblighi di verifica. Non normalizzare uno stato
incerto a `:preparato` o `:pubblicato`.

**CS-REV-03 — COD-26 e rilascio dell'effetto, rivalutazione.** Testo letto nello standard:
«`unwind-protect` solo per rilasciare risorse; mai per nascondere un errore».
`effect-active` è una proprietà locale: `%begin-effect` la acquisisce,
`%end-effect` la rilascia. Se `complete=nil`, prima del rilascio viene anche
marcato l'ambito Archivio. La seconda parte della norma è rispettata sul codice
letto: nessun catch generico, rollback o soppressione della condizione/trasferimento
originale nel cleanup; la strada Archivio di `%mark-fault` esegue solo il set della
parola di stato e ritorna. La prima lettura conservativa considerava la marcatura
un effetto aggiuntivo al rilascio e proponeva una deviazione. Dopo lettura del
[contratto del parent](controller-serie.md) e del protocollo completo, il revisore
ritira quella richiesta: l'effetto ha una proprietà effettiva acquisita prima
del corpo, controllata per rientranza e rilasciata in ogni cleanup, anche sul
successo. La marcatura terminale è parte del rilascio sicuro di questa proprietà
quando il corpo non l'ha finalizzata, mantenendo indisponibile alla prosecuzione
una risorsa con esito incerto. Non è un mero pretesto per eseguire recovery nel
cleanup.

La motivazione concreta è che un `handler-case` di condizioni tipizzate non
intercetta ogni uscita nonlocale, mentre la finestra CAS/stadio o registro/evento
incerta deve bloccare nuove operazioni e l'annullamento automatico. Eliminare il
fault dal cleanup lascerebbe quell'obbligo senza presidio locale. L'ambito della
conclusione comprende soltanto la marcatura terminale Archivio su uscita incompleta
durante il rilascio dell'effetto; riferimenti/token e causa originale sono
preservati. Rollback, risoluzione token, I/O, callback e retry non fanno parte del
cleanup letto e richiederebbero una nuova valutazione. Ambito:
adozione, inizio/fine/ritiro I/O, pubblicazione, riuso e annullamento. Il rilascio owner
durante acquisizione della lease è già un uso di rilascio risorsa distinto.

Questa è un'interpretazione motivata del revisore, non certificazione C1 o
approvazione umana. Non si registra né si inventa una deviazione approvata.
`docs/affidabilita/deviazioni.md`, letto e ancora senza deviazioni approvate,
non viene modificato da questo incarico. Il suo vincolo «approvazione dell'autore»
varrebbe per una vera deviazione da registrare, non costituisce un'autorizzazione
a inventare una persona/data di approvazione.

## Percorsi esaminati nella lettura completa B

| Protocollo | Evidenza statica e limite |
|---|---|
| Salute e ambito | Una sola parola enum `:healthy/:faulted/:archive-faulted`. `%mark-fault :serie` usa CAS healthy→faulted; su archive-faulted non fa downgrade. I due getter derivano ciascuno da una lettura di quella parola con barriera; due chiamate distinte possono naturalmente vedere tempi diversi. |
| Adozione | Guardie capacity/generation, livello, planned-root `eq`, sealed, next-offset e somma fixnum; token registry/log `eq`; CSN lessicografico crescente prima dell'effetto. Non prende un nuovo CSN; root nil lecita. Eccezione C1 CS-REV-01. |
| Evento e lease | Lease legata al current-thread e generation; evento con controller `eq`, generation, range position e identità nello slot. Riuso preserva generation dell'evento e avanza quella del controller al prossimo ingresso. |
| Root/token | `%check-publication` precede CAS; `:pubblicando` marca la finestra incerta. `%publish-root :pubblicato` non ripete CAS. Resolver usa i campi catturati; solo `:csn-busy` produce pending/zero/zero senza avanzare cursor. |
| I/O e async | Inizio idle→active prima del dispatch; fine ammette durable/faulted, mai il solo written. Pubblicazione accetta active per async coperto, senza diminuire count/active-io. Publish-head avanza alla risoluzione; head di ritiro avanza solo al riuso. |
| Guasto e cancellazione | Fault impedisce nuovi ingressi/dispatch/pubblicazioni, ma completa-io non richiede healthy. Annullamento richiede scope Serie e active-io zero, poi scansione di tutti gli slot senza active, token esatto, marca-log-faulted e resolver. Nessun riuso dei buffer annullati/guasti. |
| Riuso | Head FIFO, phase risolto, io retired, preflight WAL durable/CSN non pending/owner nullo prima del reset. Riferimenti liberati dopo `riusa-lotto`; generation non azzerata. Eccezione C1 CS-REV-01. |
| Parallelismo e limiti | CAS owner per tratto, CAS root per lotto, registro condiviso alla risoluzione per lotto. Scansione guasto ≤ 1024; factory ≤ 1024; nessun thread di prodotto, callback, I/O o ciclo di retry. |
| WAL e ASDF | Nuove preflight ed export coerenti; `verifica-riuso-lotto` estratta senza mutare prima delle guardie. `marca-log-faulted` non libera active e ha precondizione quiescente oppure chiamata dal worker proprietario sul proprio fault. Resolver esistente preservato; Series caricato dopo WAL. |

Il controller non possiede l'Archivio: archive-faulted codifica l'obbligo al
coordinatore di fermare tutti i controller dell'Archivio. Non realizza direttamente
quel fail-stop globale. L'handoff di write usato per async durante flush non è
l'handoff di fine: deve dare una lettura attendibile della copertura mentre il
buffer resta indisponibile al riuso.

Un P1/P2 viene segnalato appena riproducibile come percorso statico, con funzione,
trigger, conseguenza e correzione richiesta. La chiusura di un riscontro richiede
rilettura del codice modificato e nuova identità dei sorgenti; non la sola risposta
dell'autore. Nessuna riimplementazione viene introdotta dal revisore.

## Addendum D — fix P2, ritiro I/O e identità prima delle prove

Riletti i file cambiati, le nuove preflight, gli export e il contratto parent.
I file Series invariati sono identificati dallo stesso contenuto già letto in C.
Il congelamento riguarda il **prodotto dichiarato dal parent**, non tutto il
checkout condiviso: test, strumenti e documenti possono ancora cambiare. Questi
blob identificano il contenuto della review; non costituiscono un risultato di
build/test/benchmark o una certificazione source-stable della campagna futura.

| File C1 | Blob Git del contenuto letto | SHA-256 |
|---|---|---|
| `src/series/package.lisp` | `0cccb1f1b9bb8f63a308352d64426a420bd1e283` | `7433162105df63d324141167e6dcf6bfee74611aa1cf7291cc6c92f41f3c7408` |
| `src/series/types.lisp` | `ab736479f4e40237a060cab4f16cff139ed176e7` | `f4421765dc166310ab2f1801052d2c4b8083be19cb0b32d84d2dcdfd41afb3e4` |
| `src/series/ownership.lisp` | `59ec27d62ce32576a837abc56bf6d31562c957d2` | `640368ff404af2c02f31ac2525a8a1887de5d1c0e62f645bc64a9ecbe708fb6d` |
| `src/series/events.lisp` | `63fb4a20faeedceb47b8cd550262f1bdca497c06` | `c4c551e27c6858fe521b7a8736a42539c639e2e78ab17599b39079511a8e77c7` |
| `src/series/io-events.lisp` | `128fe9650a741541b46d1ad0887b872cb2e85012` | `5695cd60f16eec8b6c5da0b1c3c559dfd84a2e7e3a19b69643b00b2048385546` |
| `src/series/publication.lisp` | `48a789494e731732ae0b378347e133d50daacfe4` | `288cb3fa41fad76a0e6919dfa0b2fce2beef15f5880129393bee35bc8795c762` |
| `src/series/query.lisp` | `7f91ca22b7f2f339b450db0f4c26c97f86906c58` | `21363e48cf5c76b771501e54d16b1a6b8627da003a0852db0aadcfbd45d55eb9` |
| `src/series/retirement.lisp` | `fc42b51a0f8606687881e239ba650a9f1bb58124` | `23f3ab39b4176917e86064dff0a11e389df47e0286778a870f718fdc6f3fa059` |
| `src/wal/builder.lisp` | `6d30698383477880c693954314bab03ca8affe24` | `186d481c39ed0a339a6c884ed3a8b6f82da6c17315d8649c8d749efee29682f0` |
| `src/wal/csn.lisp` | `f65662b4dea8ef04e4e59ce38b29a94fecea4f6c` | `2fc52ddc064a87c32c44d1a8a9756de65b75b25dd705fdf24be1da53ef5ab810` |
| `src/wal/executor.lisp` | `edc8ce7474365e0885925d557a378779655d2e70` | `d5fce79d73f6d5115602fabb822ba36ab4ec376dfba5025c5bf1426f6ec438d8` |
| `src/wal/package.lisp` | `ad1b1356eeb10248526f15ac31d2cc9b59811fc5` | `483c7fd8debf44765375cca8429dfc111bc4775a6db2eb5f0d7e6991f1e5ad89` |

Metadati consultati: ASDF blob `fdbafde57394cefb7965beaf65e4ac04c0d6fe95`,
SHA-256 `3863976de1b2b6ba63c8fafa42b1549f8e596d40a885992de41ffc5d2923da19`;
contratto parent blob `fbd177aee0fe0d21532f9e7aaaa013b8755de10e`, SHA-256
`1d96cb0a16733a22020f09cfc4d089ca22e8dcbf01eb54610661ef86a5315d9b`.
Non si estende questa identità ai file di test/strumenti ancora in scrittura.

### Chiusura dei riscontri alla rilettura

| Riscontro | Correzione letta | Esito statico |
|---|---|---|
| CS-REV-01, adozione | `%capture-token` in `events.lisp:75`, chiamato da registra prima dell'effetto, protegge lettura/preflight WAL con handler invariant-violation. | Marca Archivio e ripropaga la condizione originale. Invalid-argument ordinari non vengono trasformati in busy/fault; nessuna mutazione di evento/credito prima del successo. Chiuso. |
| CS-REV-01, rilascio | `%check-lotto-release` in `events.lisp:87`, chiamato dal riuso con `:riuso` e dal ritiro I/O con `:ritiro`. | Invarianti della preflight → Archivio prima del reset/decremento; rifiuti prematuri ordinari lasciano riferimenti/obbligo. Chiuso anche sul nuovo percorso. |
| CS-REV-02 | Getter in `query.lisp:44`: case ammette solo libero/preparato/pubblicato/risolto/annullato; otherwise `%serie-invariant :serie-event-uncertain`. | Stato incerto resta interno; getter segnala invariante e Archivio, senza inventare una fase ordinaria. Chiuso. |

Nessun nuovo P1/P2 individuato nei percorsi aggiunti. Chiusura **statica**;
le prove discriminanti sono delegate alla campagna del parent, senza essere
anticipate, duplicate o certificate da questo incarico.

### Ritiro di un obbligo I/O senza esecuzione

`ritira-io-commit-serie` rifiuta healthy con `invalid-argument :serie-not-faulted`.
Richiede evento/generation correnti, phase preparato, io active, token catturato
esatto, lotto sealed senza owner di gruppo e active-io positivo. Le guardie
precedono l'effetto: stato scritto/durevole/guasto o gruppo ancora owner non
autorizzano questo ritiro. La preflight `verifica-ritiro-lotto` delega anche
l'invariante di lunghezza; il wrapper marca Archivio se questa fallisce.

Al successo cambia soltanto io-state→retired e active-io→active-io−1,
con post-guardie del ring e dell'evento. Token ancora pendente, phase preparato,
root, count, unresolved e i due cursori FIFO sono conservati. Un doppio ritiro
rifiuta io retired; non ripete il decremento. Non scrive, non fa flush, non
annulla il token e non riapre il lotto. Ambito Archivio consente il drenaggio
locale ma conserva il divieto di annullamento automatico.

La prova esterna del ritiro/mai accettato è **precondizione**, legata al compito
del messaggio con evento e generazione catturati. Il caller deve escludere
definitivamente accessi di worker, poi annullare il gruppo mai scritto prima
di questa API. `sealed` e owner nullo non provano autonomamente la quiescenza
dello scheduler. Dopo i ritiri, `annulla-commit-serie` ricontrolla ancora tutto
l'I/O della Serie, active-io zero e tutti gli slot non active, prima di marcare
il log e risolvere il token catturato. Questa separazione evita l'abbandono
permanente dell'obbligo active dopo un rifiuto scheduler seguito da fault.

Il nuovo cleanup usa la stessa proprietà effect-active acquisita/rilasciata:
la motivazione COD-26 rimane valida per sette percorsi di effetto. Nessuna
deviazione o approvazione umana introdotta. L'anchor WAL precedente resta unica
e invariata; nessun mutatore eseguito.

## Checklist C1 e limiti della fase corrente

### Complessità preliminare — lettura intermedia A

Conteggio locale manuale, confrontato con scansione sintattica senza caricare o
compilare il prodotto. Base 1; `if/when/unless` e ciclo aggiungono 1;
`and/or` aggiungono N−1; ogni clausola `handler-case` aggiunge 1. Non si
espandono macro del runtime o helper chiamati. Massimo delle **20 funzioni
disponibili: 8 ≤ 10**; non è ancora il massimo del modulo completo.

| File | Funzioni e complessità |
|---|---|
| `src/series/types.lisp` | `crea-controllore-serie` 6. |
| `src/series/ownership.lisp` | `%mark-fault` 2; `%serie-invariant` 1; `%check-ring` 8; `%check-owner` 5; `%release-owner` 3; `acquisisci-controllore-serie` 4; `rilascia-controllore-serie` 2; `%require-healthy` 3; `%begin-effect` 2; `%end-effect` 2; `%next-position` 4. |
| `src/series/events.lisp` | `%check-event` 8; `%live-event` 3; `%csn-after-p` 3; `%check-admission` 8; `%check-new-slot` 4; `registra-commit-serie` 2; `%check-captured-token` 3; `%check-publish-head` 4. |

Nuove preflight WAL: `verifica-token-lotto` 2,
`verifica-pubblicazione-lotto` 3, `verifica-riuso-lotto` 3,
`marca-log-faulted` 1. Il conteggio non incorpora le guardie delegate;
queste restano nel contesto letto e negli obblighi di decisione.

### Checklist

| Voce dello standard | Evidenza corrente | Stato |
|---|---|---|
| 1. Requisiti e ADR coerenti | Contratto parent, otto file Series, preflight WAL, export e ASDF letti. Nessun requisito motore promosso. | Lettura statica svolta. |
| 2. Invarianti e test discriminanti | Obblighi elencati nella matrice; prove a un altro incarico. | Non attestato. |
| 3. Errori tipizzati, gestione e test | Reason effettive inventariate; CS-REV-01 e CS-REV-02 chiusi staticamente in D. Test non eseguiti/letti come evidenza della review. | Gestione statica riletta; prove non attestate. |
| 4. Cicli/attese limitati | Factory e quiescenza al più capacity≤1024, CAS singoli, nessuna attesa o retry. Massimo complessità 8; tabella D sotto. | Staticamente conforme ai limiti osservati. |
| 5. Allocazioni misurate | Nessuna misura eseguita o letta per il nuovo controller. | Non attestato. |
| 6. Dati verificati in uscita | Root/token/lease validati e stato pubblico ristretto ai cinque esiti; immutabilità/handoff e cancel-proof restano precondizioni. | Lettura statica svolta sotto precondizioni. |
| 7. Decisioni composte | Tutti i sei predicati composti diretti e selezioni/guardie effettive inventariati; helper WAL preesistenti identificati. | Inventario statico completo; MC/DC non attestata. |
| 8. Ownership | Thread/lease, oggetto+generation e log/registry sorgente distinti; effect-active risorsa reale con cleanup protettivo. | Lettura statica svolta; protocollo esterno resta precondizione. |
| 9. Tracciabilità e check | Competenza parent; nessun check durante integrazione. | Non attestato. |
| 10. Deviazioni | COD-26 rivalutata come rilascio sicuro della proprietà dell'effetto; motivazione CS-REV-03. Nessuna deviazione/approvazione umana registrata. | Interpretazione statica esplicita, non certificazione. |
| 11. Parallelismo fra Serie | Owner/root/count locali, registro CSN condiviso solo per lotto. Nessuna scrittura comune per documento introdotta. | Lettura statica svolta; benchmark non attestati. |
| 12. Atomicità e rimozioni | CAS root volatile distinto dal SEAL persistito; nessun file I/O o rimozione nel controller. Stato incerto richiede fail-stop Archivio. | Lettura statica svolta sotto precondizioni. |

### Complessità completa — lettura D

Stesso criterio della fase A, con `case` contato per alternativa esplicita
non default; per prudenza si contano anche i singoli valori di una clausola
raggruppata. Esempio `%mark-fault`: 1 base + 1 if + 3 valori accettati dal case
= 5. Esempio `%check-ring`: 1 base + 2 unless + 3 and + 2 and = 8;
il helper geometria viene contato separatamente. I rami delle macro del runtime
e degli helper chiamati non vengono espansi nella funzione chiamante.

| File | Ogni funzione e complessità C1 locale |
|---|---|
| `src/series/types.lisp` | `crea-controllore-serie` 5. |
| `src/series/ownership.lisp` | `%mark-fault` 5; `%serie-invariant` 1; `%check-ring` 8; `%position-after` 4; `%check-geometry` 3; `%check-owner` 5; `%release-owner` 3; `acquisisci-controllore-serie` 4; `rilascia-controllore-serie` 2; `%require-healthy` 3; `%begin-effect` 2; `%end-effect` 2; `%next-position` 4. |
| `src/series/events.lisp` | `%check-event` 8; `%live-event` 3; `%csn-after-p` 3; `%check-admission` 8; `%check-new-slot` 4; `%capture-token` 2; `%check-lotto-release` 4; `registra-commit-serie` 2; `%check-captured-token` 3; `%check-publish-head` 4. |
| `src/series/io-events.lisp` | `inizia-io-commit-serie` 4; `completa-io-commit-serie` 6; `ritira-io-commit-serie` 6; `%require-quiescent` 5. |
| `src/series/publication.lisp` | `%check-publication` 6; `%publish-root` 6; `%advance-publication` 3; `%resolve-publication` 5; `pubblica-commit-serie` 2. |
| `src/series/query.lisp` | `stato-controllore-serie` 2; `ambito-fault-serie` 4; `leggi-radice-serie` 3; `stato-commit-serie` 6; `leggi-csn-commit-serie` 1; `conta-commit-serie` 1. |
| `src/series/retirement.lisp` | `riusa-commit-serie` 6; `fault-controllore-serie` 3; `annulla-commit-serie` 4. |
| `src/wal/csn.lisp`, nuove preflight | `verifica-log-segmento` 3; `verifica-token-lotto` 2; `verifica-pubblicazione-lotto` 2. |
| `src/wal/builder.lisp`, nuovi helper | `verifica-riuso-lotto` 3; `verifica-ritiro-lotto` 2. |
| `src/wal/executor.lisp`, nuovo helper | `marca-log-faulted` 1. |

Sono 42 funzioni Series e 6 nuovi helper WAL. Massimo **8 ≤ 10**, inclusi
corto circuito e handler, per la versione D. Le definizioni Series arrivano a
29 righe dalla riga `defun` alla parentesi finale, includendo docstring/commenti;
nessuna oltre il limite COD-12 di 60. Sono osservazioni sintattiche, non esito
di lint/build o copertura. Tipi e docstring osservati; nessuna verifica runtime
dei rifiuti, barriere o interruzioni. I due P2 precedenti sono chiusi staticamente;
la checklist C1 complessiva con due letture e prove è responsabilità dell'integrazione.

## Addendum E — dichiarazioni e lettura dell'integratore

L'integratore ha riletto ownership, geometria del ring, adozione, pubblicazione,
ritiro, query e nuove preflight WAL; la lettura indipendente D ha prodotto i
due P2 poi corretti. Nessun P1/P2 aperto nel perimetro sotto le precondizioni
P01–P08. Pool, indice, snapshot e arresto globale dell'Archivio restano esterni.

Dopo il primo build fermato da COD-01, `%serie-invariant` dichiara ritorno
`nil`, il tipo vuoto, invece di `null`: la funzione segnala sempre una condizione
e non ritorna normalmente. La dichiarazione anticipata del getter di salute
coincide con quella in `query.lisp`. Una seconda rilettura indipendente del
delta non ha trovato regressioni o nuovi P1/P2; massimo 8 e 42 funzioni invariati.

| File riletto | Blob Git | SHA-256 |
|---|---|---|
| `src/series/ownership.lisp` | `7352a27581b8e2e68407611e65e46773efdc333c` | `195e71c81a6993d5c021ba520918885f6c91629af7940688f723fe421fc388e4` |
| `src/series/types.lisp` | `a0def7fc9452d291e2e60dbeff26a56a2b06e3a3` | `5b35f8f0b017476e14078ba073840e40f182438af41750dd1b3262d0a80c1ca9` |

Il lint distingue ora `(:read)` della barriera da `(cl:read stream)`: le due
fixture positive/negative verificano questa distinzione. La rilettura indipendente
conferma il divieto sulle chiamate dirette al reader, anche non qualificate o
con package `common-lisp:`. È una proprietà sintattica, non un'analisi semantica
generale del programma. La matrice D02/D03 riceve FI separate su capacità,
cursori e contatori; D06 riceve truth-pairs esplicite. Gli esiti runtime e
l'allocazione sono responsabilità dei registri della campagna, distinti dalle
due letture statiche.
