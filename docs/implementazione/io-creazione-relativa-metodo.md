# Creazione relativa: metodo

Metodo registrato il 2026-10-17 prima di compilazione ed esecuzione.
L'incremento completa il confine I/O relativo, secondo ADR-0017/0033 e
COD-37, senza modificare formati o decisioni durevoli di ADR-0040.

## Contratto e proprietà

`crea-temporaneo-nella-directory` restituisce una sola capacità append
per un nuovo `.tmp` regolare vuoto. Non apre file esistenti in scrittura.
Budget positivi, foglia e disponibilità delle tre callback sono
verificati prima degli effetti. Foglia privata e child sono allocati
prima dell'apertura. La callback `create-relative(parent-fd, leaf, :append)`
trasferisce ownership soltanto al ritorno di un FD valido distinto dal
parent; fino ad allora possiede il proprio rollback. FD zero è valido.

`file-metadata` attesta regolare, device, inode e dimensione zero;
`entry-identity` deve attestare la stessa identità nofollow rispetto
al parent. Componenti POSIX signed/unsigned a 64 bit restano esatti;
la dimensione viene limitata prima del restringimento. Metadati fuori
contratto, file non vuoto o identità discordante impediscono il ritorno.
Parent e child devono restare disponibili fino alla pubblicazione.

Il controller esclude mutazioni concorrenti di file/namespace e chiusure
delle capacità; il confronto non sostituisce questa precondizione.
Il parent è preso in prestito e non viene chiuso o messo in guasto
dall'API. La creazione modifica il namespace ma non le sue frontiere.
Il child riuscito parte con written/durable zero e passa al chiamante.

Il nativo usa `openat(parent-fd, leaf, flags, 0600)` con
`O_WRONLY|O_CREAT|O_EXCL|O_APPEND|O_CLOEXEC|O_NOFOLLOW`. La dichiarazione
alien deve marcare il quarto argomento come variadico: su Darwin ARM64
la convenzione dei vararg differisce dagli argomenti fissi. `mode_t`
subisce la promozione intera. La dichiarazione readonly a tre argomenti
non viene usata con `O_CREAT`. La umask può solo restringere i permessi.

## Errori e risorse

Un FD valido acquisito e non pubblicato riceve una sola close dal backend
che lo ha creato, con stato CLOSED prima della chiamata. Il cleanup viene
tentato anche con parent invalidato, senza retry EINTR e senza toccare un
FD alias del parent. Se riesce si propaga lo stesso oggetto di condizione
tipizzata. Se fallisce si espongono reason/offset primari e cleanup-errno;
una causa I/O conserva operazione, errno e progresso. Per una causa non
I/O l'operazione del doppio guasto è `:create-relative`. Close nonzero
è fallimento anche con errno NIL.

Uscite non locali estranee tentano il cleanup senza allegare l'errno
secondario. Condizioni estranee nel callback close restano fuori dal
protocollo. Le finestre senza interrupt proteggono handoff e cleanup,
senza introdurre cancellazione asincrona. Le syscall appartengono al pool
I/O e possono bloccare; nessuna deadline wall è promessa dal prodotto.

Non avvengono unlink, flush o rename impliciti. Dopo una creazione
riuscita e un successivo rifiuto può restare un temporaneo orfano, anche
quando close riesce. La riconciliazione fisica resta del controller.
L'esclusività non attesta contenuto, decisione del manifest o durability.

## Decisioni e prove preregistrate

| ID | Confine | Casi |
|---|---|---|
| CTR-D01 | Parent | directory aperta, altro modo, chiusa/faulted |
| CTR-D02 | Budget | tipi/range, zero rifiutato, estremi positivi |
| CTR-D03 | Foglia privata | ASCII, suffisso, separatori/NUL/dot, 255/256 byte, nome chiamante riusato |
| CTR-D04 | Backend completo | ciascuna callback assente, nessun fallback |
| CTR-D05 | Acquisizione e pubblicazione | FD zero, ordine callback, backend ereditato; guardia difensiva written=0 e durable=0 |
| CTR-D06 | FD fuori contratto | invalido e alias del parent senza close |
| CTR-D07 | Metadati | componenti esatte, forma invalida, regolare vuoto, EOF nonzero/eccessivo |
| CTR-D08 | Legame alla foglia | device/inode concordi e ciascuno discordante, entry invalida |
| CTR-D09 | Disponibilità | invalidazione parent da ogni callback, cleanup ancora tentato; child privato verificato prima del ritorno |
| CTR-D10 | Causa primaria | errore prima/dopo handoff, syscall normalizzata, stesso oggetto dopo cleanup riuscito |
| CTR-D11 | Doppio guasto | campi I/O/offset preservati, nonzero con errno NIL, una sola close |
| CTR-D12 | Uscita non locale | nessuna pubblicazione, cleanup una volta |
| CTR-D13 | Nuovo file nativo | append, identità readonly, contenuto, flags e permessi |
| CTR-D14 | Collisioni native | file/FIFO/directory/symlink restano immutati |
| CTR-D15 | Parent rinominato | creazione nel parent aperto, decoy al percorso precedente intatto |
| CTR-D16 | Fine ownership | close ripetute, riuso FD senza close tardiva |
| CTR-D17 | Effetto già avvenuto | rifiuto postcreazione con vero file, close del child e orfano conservato |

Le fixture native usano namespace 0700 esclusivi, registri bounded di
risorse, cleanup dei soli nomi posseduti e deadline cooperative finite.
Oracoli POSIX C4 confrontano byte, identità e proprietà del FD; le prove
iniettate osservano ordine, numero e argomenti delle callback. I guasti
puri non attestano fault injection di syscall native. La fixture verticale
esercita i propri casi v1/v2 e crash usando la nuova creazione relativa.
Le callback non ricevono la capacità child privata: le guardie sul suo
stato e sulle frontiere sono lette staticamente, senza pretendere che una
fixture ne alteri direttamente gli slot prima della pubblicazione.

Due letture statiche del codice finale precedono compilazione e prove.
Commit congelato, cache ASDF nuova e `record-command` conservano ogni
tentativo, compresi fallimenti. `make trace-write` aggiorna la matrice;
`make check` resta richiesto. La raccolta usa il collector esistente,
manifest esplicito, quattro worker e inventario chiuso. La CI Linux/macOS
della versione integrata è un'osservazione distinta.

Requisiti: REQ-STO-003, REQ-REC-001, REQ-AFF-001/004/008/018,
REQ-FOR-001 e REQ-VAL-001. Invarianti: INV-A7/A9/A10/A11, INV-P6 e INV-X3.
Restano aperti Recovery Manager, esecuzione della riconciliazione,
ammissione, qualifica C1 completa, MC/DC, mutation testing dei nuovi
percorsi e misure di prestazione.

## Integrazione con main — 2026-10-22

Il controllo completo R1 del 2026-10-17 appartiene al freeze
`b5ad739ba1fc0252920c088e2442140e448451ad`. La ripresa del 2026-10-22
integra main `56fc1c1a`, che aggiunge la stabilizzazione dei nomi recuperati
e archivi CI. Le primitive di creazione, i relativi helper e i test
restano identici a R1; package e ASD devono conservare entrambe le API
e l'ordine dei moduli. Due letture statiche controllano questi raccordi.

Dopo il nuovo freeze si esegue `make test lint trace links` con cache
ASDF nuova e record distinto. Non si attribuisce il full R1 al merge;
la CI del merge effettivamente provato resta una fotografia separata.

## Secondo raccordo con main — 2026-10-22

Durante la CI di PR20, main avanza a `e75f9794` aggiungendo il selettore
in memoria delle versioni recuperate. Il nuovo modulo non esegue I/O
e non modifica namespace, callback o capacità. I sorgenti I/O, i tre
test e la fixture verticale restano identici al raccordo precedente.
ASD conserva il selettore dopo recovery-bootstrap, prima del runtime.
Due letture statiche precedono il freeze di questo raccordo.

Si esegue R4 `make test lint trace links` con cache nuova e si conserva
il record distinto. La CI già avviata sul merge `046c64cc` mantiene
quella precisa attribuzione; il nuovo head richiede la propria CI.

## Raccordo dei report CI (C4) — 2026-10-22

Il run PR20 `39817860664`, sul merge `046c64cc`, conclude con successo
Linux, macOS e audit. Anche `coverage-tests.lisp` è PASSED; il worker
si ferma dopo i test e LCOV, leggendo il risultato della verifica normale:
il vocabolario del consumer fresco non registra tutti i campi emessi
dal producer. Coverage e seal sono quindi FAILED e restano conservati
come tali. Nessun esito globale verde è attribuito a quel run.

Prima delle nuove prove si registra la correzione C4 minima: dichiarare
nel vocabolario trusted i campi del risultato normale già ammessi dallo
schema producer, senza internare simboli dall'input o ampliare gli schemi.
La regressione deve usare un SBCL fresco con i moduli del consumer:
il processo completo del self-test carica già il producer e maschera
il difetto. Un controllo sulla revisione precedente deve rilevarlo;
i rifiuti di token sconosciuti e forme eseguibili restano richiesti.

Si conservano separatamente tentativo fallito, regressione e controllo
C4 successivo; la nuova CI verificherà il nuovo head. La correzione
non cambia i sorgenti I/O, le decisioni CTR o i loro test.

Il raccordo successivo integra main `c46bc4c1` (PR21), che contiene
la stessa dichiarazione dei due campi, anche `:skipped` per il reader
data-only, e mantiene compatto il riepilogo coverage conservando
l'inventario originale. Restano entrambe le regressioni: reader data-only
e consumer coverage completo, con producer assente nei rispettivi figli.
I 328 controlli C4 della revisione `6c409f59` sono PASSED; il loro record
resta distinto dal nuovo controllo completo C4 sul raccordo con PR21.

Il raccordo `fc0a34a9` conclude i 334 controlli C4 con PASSED:
59 dati, 37 test registry, nove condizioni, 43 misure, 172 workflow e
14 confini. I recorder prima della correzione (`92fbfbbc`, exit 1 atteso),
dopo (`6c409f59`, exit 0), e dei due self-test completi riportano sorgenti
STABLE e checkout puliti. R4, a `1ebf8e71`, conclude
`make test lint trace links` con cache nuova ed exit 0/STABLE.
Questi esiti locali non sostituiscono la CI sul nuovo merge effettivo.
