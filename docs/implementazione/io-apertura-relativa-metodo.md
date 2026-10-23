# Apertura readonly relativa: metodo

Metodo registrato prima delle esecuzioni. L'incremento collega il
namespace già posseduto ai reader, secondo ADR-0017, ADR-0033 e COD-37.
Non modifica formati, decisioni durevoli o la tabella di ADR-0040.

## Contratto e ownership

`apri-lettura-nella-directory(directory, nome, …)` restituisce una nuova
capacità readonly e la dimensione osservata tramite lo stesso FD.
Il parent resta preso in prestito, aperto e riutilizzabile. Il controller
impedisce mutazioni del namespace e del file durante la chiamata e
chiusure concorrenti delle capacità. Il proprietario mantiene poi vivo
il child fino alla quiescenza dei suoi reader.

Il nome è una foglia ASCII stampabile, da 1 a 255 byte, esclusi `.`, `..`,
NUL e separatori. La copia privata e la capacità sono preparate prima
dell'apertura. Il modo nativo usa `openat` sul parent, readonly,
`O_CLOEXEC`, `O_NOFOLLOW`, `O_NONBLOCK`; `fstat` deve attestare un regolare.
Device/inode completi vengono confrontati con l'entry relativa nofollow
dello stesso parent prima della pubblicazione. Nessun percorso del parent
viene riaperto. Il nome non è un'attestazione di header o appartenenza
al manifest: quelle verifiche rimangono ai reader e al controller.

Il backend è ereditato dal parent. Le estensioni opzionali sono
`open-relative(fd-parent, nome, :input) → fd-child` e
`file-metadata(fd-child) → device, inode, dimensione`; è inoltre richiesta
`entry-identity`. Le callback verificano il tipo regolare e rispettano
ownership e nomi immutabili. Fino al ritorno di un FD valido il callback
di apertura possiede il proprio rollback; dopo il ritorno il prodotto
possiede il child. Un FD uguale al parent è rifiutato senza chiuderlo.
Callback mancanti non ricadono sulle primitive native.

Budget proposti: trasferimento da 1 a 256 MiB e dimensione massima da
zero a `most-positive-fixnum`, predefinita 4 GiB−1. Zero ammette soltanto
un file vuoto. La dimensione è una fotografia di apertura: non è una
frontiera validata, committed o durevole, né un limite RSS. Le frontiere
`written` e `durable` della capacità readonly restano zero.

## Guasti e cleanup

Ogni FD valido acquisito ma non pubblicato riceve una sola richiesta di
chiusura, attraverso il backend che lo ha aperto. La capacità privata
diventa `:closed` prima della richiesta; non si ritenta EINTR. Questo
cleanup viene tentato anche se una callback ha invalidato il parent.
Nessun rifiuto chiude il parent o una capacità già posseduta dal chiamante.

Se la chiusura riesce, la condizione tipizzata originaria viene propagata
come stesso oggetto. Se fallisce anche il cleanup, `io-fault` conserva
reason e offset primari e cleanup-errno; per una causa I/O conserva anche
operazione, errno e progresso. Il cambio di classe per una causa primaria
non I/O è esplicito e segue la politica budget+cleanup dell'inventario.
Un ritorno nonzero del close è fallimento anche senza errno disponibile.
Il valore errno NIL non attesta quindi la riuscita di una chiusura.

Un'uscita non locale estranea ai normali errori tipizzati tenta il
cleanup, senza allegare alla causa l'eventuale errno secondario.
Le callback di close devono rispettare il contratto degli errori I/O;
errori estranei nel cleanup restano fuori da questo protocollo.
Le finestre senza interrupt proteggono l'handoff del FD e la chiusura;
non introducono un protocollo di cancellazione asincrona. Le syscall
possono bloccare: il percorso appartiene al pool I/O e non promette
una deadline wall.

## Decisioni e prove preregistrate

| ID | Decisione / confine | Casi |
|---|---|---|
| OR-D01 | parent e configurazione validi | modi, chiuso/faulted, budget fuori range, zero/esatto |
| OR-D02 | nome foglia valido e privato | vuoto, dot path, separatori, NUL, non ASCII, 255/256 byte, riuso del nome chiamante |
| OR-D03 | capacità del backend | nativo, tre callback presenti, ciascuna assente, nessun fallback |
| OR-D04 | acquisizione FD | valido, risultato invalido, alias del parent, errore prima del trasferimento |
| OR-D05 | metadati regolari e limitati | componenti intere complete, ciascuna invalida, dimensione zero/esatta/eccessiva |
| OR-D06 | FD e nome legati | stesso device/inode, ciascun componente diverso, guasto del controllo |
| OR-D07 | parent ancora aperto | invalidazione da ciascuna callback prima di altre operazioni |
| OR-D08 | cleanup senza pubblicazione | una close, nessun retry, backend corretto, errno primario/secondario, nonzero |
| OR-D09 | nativo readonly ancorato | byte, EOF, flags, symlink/FIFO/directory, assente e parent rinominato con decoy |
| OR-D10 | uso nei reader verticali | CONTROL, decision log e ACTIVE con EOF della stessa capacità; v1/v2 e crash già previsti |

Le fixture native riusano registri bounded di risorse, namespace esclusivi
0700, deadline cooperative finite e cleanup dei soli nomi creati dal test.
I controlli fra operazioni non interrompono una syscall bloccata. Confrontano
byte, identità, stato/frontiere e proprietà del FD con oracoli POSIX C4.
I test iniettati osservano anche l'ordine e il numero delle callback.
Le prove pure sugli errori non attestano fault injection di syscall native.

Due letture statiche precedono compilazione ed esecuzione. I sorgenti
vengono congelati in un commit; il controllo completo è registrato con
`record-command` e cache ASDF nuova. Ogni tentativo resta distinto,
compresi fallimenti e correzioni. La CI Linux/macOS della versione
integrata è una fotografia separata. Le evidenze citate saranno raccolte
con il collector esistente, manifest esplicito e inventario chiuso.

Requisiti: REQ-STO-003, REQ-REC-001, REQ-AFF-001/004/008/018,
REQ-FOR-001 e REQ-VAL-001. Invarianti: INV-A7/A9/A10, INV-P6 e INV-X3.
Restano aperti raccolta posseduta di tutti i segmenti vivi, esecuzione
della riconciliazione, Recovery Manager, ammissione, C1 completo, MC/DC,
mutation testing dei nuovi percorsi e misure di prestazione.
