# Adozione dell'ACTIVE nel runtime

Metodo preregistrato prima dei run. Il [bootstrap Archivio](runtime-archivio.md)
fornisce la famiglia CSN/snapshot/EBR. Questo incremento collega il nuovo
ACTIVE preparato al controller reale e rende verificabile l'obbligo già
dichiarato di un solo controller per log.

## Contratto e proprietà

`crea-controllore-serie` conserva radice, offset e capacità configurabili.
Prima della pubblicazione verifica budget, log segmento sano e ring
preallocato. Un CAS passa lo slot privato del log da NIL al controller.
Un secondo costruttore, anche con registro diverso, segnala
`invalid-argument :serie-log-bound`. Non esiste reset. Nessuna lease o
assegnazione CSN viene acquisita dalla factory. Errori precedenti al CAS
non pubblicano il candidato; un concorrente può avere pubblicato il proprio.

`trova-controllore-serie(log)` carica una volta, acquisisce e restituisce
NIL o il riferimento canonico. Controlla tipo e legame inverso al medesimo
log; slot estraneo o controller di altro log segnalano
`invariant-violation :serie-log-binding`. Il getter non campiona salute,
ring o lease. Recupera il binding anche dopo interruzione del ritorno;
quest'ultima proprietà resta un argomento statico, senza hook nel prodotto.

Un'invariante del binding impone apertura fallita, arresto di bootstrap e
adozione, nessuna ammissione. Il coordinatore isola mediante riferimenti
autorevoli: il getter non può mutare un controller estraneo conservato in
uno slot corrotto. Prima del CAS le postverifiche e il ring rendono FAULTED
il candidato privato mediante `%serie-invariant`, senza alterare il log o
un vincitore concorrente. La conformità complessiva COD-24 resta aperta
finché il confine generale di arresto non è realizzato e verificato;
nessuna deroga viene dedotta dalle API recovery esistenti.

Il binding riguarda **l'oggetto log canonico**, non ogni wrapper/apertura
possibile sullo stesso file. Esclusione fisica e unicità del wrapper restano
del proprietario. La rotazione crea un nuovo log e controller; il vecchio
resta vivo fino al ritiro dei borrower. Lo slot opaco `t` evita un ciclo
ASDF WAL/Serie; un solo writer produttivo CAS, nessun accesso per documento,
lotto o GET. Il riferimento inverso è gestito dal GC; nessuna chiusura
automatica dei FD. Cambia un layout privato: ricompilare senza vecchie istanze.

## Adozione verificata

`runtime:adotta-controllore-active(runtime, prepared, :capacity 64)` richiede:

- vista del prepared nello **stesso ambito EQ** del runtime; uno scope clone
  che riusa lo stesso registro snapshot/CSN viene rifiutato;
- log segmento sano, ID completo e versione uguali alla capacità GET,
  origine writer;
- prova di associazione delle due capacità esatte, readonly e append,
  ancora aperte;
- frontiere append scritto e durevole entrambe pari a 64.

Tutto precede il binding. La factory reale riceve il CSN del runtime,
radice NIL e next-offset 64; restituisce un ring vuoto senza lease.
Rifiuti scope/start sono `invalid-argument :runtime-active-scope/started`;
identità incoerente è `invariant-violation :runtime-active-identity`.
Budget, log e capacità propagano le condizioni canoniche. Nessun I/O,
clock, registro CSN modificato o nuovo protocollo di lock.

Il prepared prova preparazione fisica; **non prova la decisione EDIT del
catalogo**. Il caller completa quella decisione prima di inizializzare e
pubblicare le fonti o usare il controller. Lease, sorgente GET preparata e
root seguono le API esistenti. Il binding è pubblicazione volatile, senza
un nuovo punto di atomicità durevole. Il Recovery Manager e il gate di
ammissione restano aperti, come la raccolta posseduta delle vecchie fonti.

## Decisioni e prove previste

| ID | Obbligo |
|---|---|
| RCA-D01 | Budget capacità/offset, log sano, prima di costruire/pubblicare |
| RCA-D02 | Binding NIL oppure controller del log esatto; FI tipo e legame |
| RCA-D03 | Primo binding, doppio avvio e CAS perdente; worker 2/4 con join limitati |
| RCA-D04 | Ambito EQ, anche contro clone con stesso CSN; nessun binding al rifiuto |
| RCA-D05 | ID AND versione AND origine coerenti; FI separate |
| RCA-D06 | Associazione esatta e capacità aperte; frontiere written AND durable 64 |
| RCA-D07 | Un solo CSN per writer/snapshot; primo nuovo lotto M+1, riporto u32 |
| RCA-D08 | Root e GET coerenti dopo pubblicazione; file precedenti e registri di bootstrap intatti |
| RCA-D09 | Candidato: registro EQ AND log EQ prima del CAS; entrambe le condizioni difensive |
| RCA-D10 | Candidato: vettore slot EQ AND offset esatto prima del CAS; entrambe le condizioni difensive |

Test generici del binding in `tests/series/log-binding.lisp`; integrazione
runtime in `tests/runtime/adoption.lisp`. I positivi costruiscono piani e
ACTIVE tramite API pubbliche, v1/v2 e FD nativi. FI seriali dichiarate,
senza modificare primitive CL; nessuna ammissione inferita dal successo.
La vecchia fixture del default viene costruita direttamente senza capacità
esplicita: ricreare due controller sullo stesso log violerebbe il contratto.

Agenti con write set disgiunti; chiusura prima dei run, revisione committed
e sorgenti congelati. Ogni diagnostica o controllo usa il recorder, anche
in caso di errore. Copertura `runtime-active`: tre file esatti (nuovo
`runtime/active`, `series/types`, `wal/types`), contatori azzerati dopo load,
suite runtime e Serie. Gli scope storici restano invariati. Il self-test
verifica inclusioni/esclusioni e il ramo mancante. Denominatori grezzi e
codice generato restano visibili; SBCL forme/rami non sono MC/DC.

Due letture statiche indipendenti dall'autore del modulo runtime sono
registrate separatamente dalla rilettura del coordinatore. Raccolta con
il collector comune, hash e controllo indipendente chiuso. Restano esclusi
cache e ingressi dei casi negativi C4 ricostruibili; i loro risultati
strutturati rimangono nei report originali. Nessun benchmark nuovo: nessun
percorso caldo nuovo, costi del bootstrap/GC e piattaforma di riferimento
non misurati. Qualifica C1/MC/DC e obblighi del motore restano aperti.

## Revisione statica prima dei run

Due letture di Hume, revisore distinto dagli autori; riletture degli autori
e del coordinatore separate. Nessuna esecuzione o modifica del revisore.

| Lista C1 | Esito delle due letture |
|---|---|
| 1–3: requisiti, invarianti, errori | Contratti e ragioni tipizzate censiti; FI locali previste |
| 4: limiti | Factory limitata dalla capacità; adozione senza cicli o attese |
| 5: allocazioni | Costruzione a bootstrap; nessuna misura del costo GC o RSS |
| 6: confini | Controlli prima del binding; dopo CAS riuscito solo ritorno |
| 7: decisioni | RCA-D01…D10; postverifiche difensive nel denominatore |
| 8: proprietà | Un CAS per log, nessun reset; oggetti estranei non mutati |
| 9: tracciabilità | Rigenerazione e controllo completo previsti dopo il freeze |
| 10: standard | COD-24 complessivo e qualifica C1 aperti; nessuna deroga dichiarata |
| 11: parallelismo | Slot per log; nessuna coordinazione aggiunta tra Serie per operazione |
| 12: durevolezza | Nessun nuovo punto durevole; decisione catalogo esterna esplicita |

Rilievi recepiti prima del freeze: censimento delle due postverifiche
composte; `%serie-invariant` sul candidato privato con `ftype` anticipato;
obbligo del coordinatore di fermare bootstrap/adozione davanti a un binding
corrotto. Rilettura finale delle tre modifiche: nessun nuovo rilievo.
I test del binding sono otto; quelli dell'adozione undici, con 26 casi
parametrizzati dichiarati dall'autore. Questi conteggi sono inventario,
non esiti dei run.

## Risultati

La [campagna del 2026-10-16](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-runtime-active/report.md)
conserva 19 nuove prove, 147 test runtime/Serie, copertura grezza e controllo
completo locale. Conserva anche i due fallimenti iniziali e le tre varianti;
confine generale COD-24, ammissione e C1/MC/DC restano aperti.
