# Inventario dei segmenti dalla directory: metodo

Metodo registrato prima delle esecuzioni. L'incremento trasferisce nel
prodotto la raccolta dei nomi richiesta da ADR-0040 §3 e dai passi 3–4
del recovery, riusando il planner esistente. Non cambia formati o azioni.

## Contratto

Il controller possiede e congela il namespace per tutta la chiamata, nel
pool I/O della Serie. Il parent è una capacità directory già aperta e
presa in prestito. Un cursore indipendente viene aperto relativamente a
quel FD: `dup` non è sufficiente, perché condividerebbe l'offset. Solo
il cursore privato viene chiuso; il parent resta aperto e riutilizzabile.

`elenca-directory` consegna nomi posseduti e un'attestazione `T` soltanto
dopo EOF reale e chiusura riuscita. Il backend iniettato deve fornire
esplicitamente la stessa attestazione. Nessun prefisso di un elenco è
un successo. I nomi vengono copiati prima del prossimo `readdir`, usando
una corrispondenza byte/carattere Latin1 indipendente dal locale.

I tre budget limitano numero di nomi, byte complessivi dei nomi e byte
per nome; comprendono anche i nomi ignorati dal parser storage. `.` e
`..` sono esclusi. Budget pari al consumo sono validi; un nome ulteriore
deve fallire. Sono limiti di lavoro e payload, non una misura di heap/RSS.

Il parser usa la forma esatta dei formati su disco: sedici cifre ASCII
esadecimali minuscole, seguite da `.seg` o `.seg.tmp`. Zero e tutti i bit
u64 restano significativi. Nomi simili a segmenti ma non canonici sono
errori espliciti. Le altre categorie sono ignorate e conservate.

Ogni candidato è verificato con identità relativa allo stesso parent,
senza seguire symlink: sono ammessi solo file regolari. Due nomi distinti
di segmenti con il medesimo device/inode sono un'anomalia esplicita.
Il planner riceve solo l'insieme completo, dopo tutti questi controlli.

Il codice non certifica che un altro processo rispetti l'esclusività:
`readdir` non è uno snapshot atomico. Non verifica header/CRC/contenuti,
non riconcilia fisicamente nomi, non apre segmenti, non ricostruisce
indici/CSN e non ammette traffico. `:ready` resta disponibilità dei nomi.

## Errori e proprietà da osservare

Errori di configurazione, budget, callback incompleto, nomi malformati,
alias e guasti di identità producono condizioni tipizzate e nessun piano.
Le condizioni delle dipendenze sono propagate. Il cursore privato viene
chiuso nei percorsi documentati di errore, senza retry.

Il nativo conserva il motivo del primo rifiuto fino alla chiusura:
un budget esaurito con cleanup riuscito segnala `resource-exhausted`;
un guasto syscall conserva errno e l'eventuale cleanup-errno. Se falliscono
sia budget sia chiusura, `io-fault` conserva il motivo del budget e
cleanup-errno. Il solo guasto di chiusura resta un errore I/O. Nessun
risultato viene promosso dopo un errore di cleanup.

| ID | Decisione / confine | Casi |
|---|---|---|
| IND-D01 | capacità e callback disponibili | directory aperta, modo errato, chiusa, callback assente |
| IND-D02 | EOF distinto dal troncamento | vuota, esatta, un nome oltre limite, attestazione falsa |
| IND-D03 | tre budget prima dell'accumulo | esatti e insufficienti, anche con nomi ignorati |
| IND-D04 | nome canonico / altro / malformato | ID zero, alto e massimo; case, lunghezza, cifre e suffisso |
| IND-D05 | candidato entro max-files | esatto / insufficiente, prima dello stat eccedente |
| IND-D06 | identità e tipo dell'entry | regolare, symlink, FIFO/directory, due hardlink |
| IND-D07 | disponibilità dal manifest | use, rename, delete, anomaly, missing e conflict |
| IND-D08 | ownership e ritorno completo | copie dei nomi, callback che chiude il parent, due scansioni dallo stesso FD |
| IND-D09 | cursore e guasti nativi | apertura, trasferimento a DIR, read, EOF, close e doppio errore |
| IND-D10 | ancoraggio al parent | rinomina del parent dopo l'apertura della capacità |

## Esecuzione e conservazione

Fixture iniettate confrontano le query del piano con l'oracolo indipendente
già usato per l'inventario, nei formati v1/v2. Le fixture native usano
namespace esclusivi `0700`, solo foglie registrate, cardinalità e deadline
finite, cleanup delle proprie risorse. Verificano anche ripetibilità,
ancoraggio e immutabilità dei file, senza dipendere dall'ordine di readdir.

Prima delle esecuzioni si completano due letture C1 e un commit dei
sorgenti. Compilazione e test sono registrati tramite `record-command`;
`make check` esegue il controllo completo. Ogni fallimento resta conservato
con sorgenti e output originali; una correzione cambia commit. CI Linux e
macOS ed esecuzioni locali restano fotografie distinte. Nessuna misura
prestazionale, attestazione MC/DC o chiusura del Recovery Manager.

Requisiti: REQ-REC-001, REQ-REC-002, REQ-AFF-001, REQ-AFF-004,
REQ-AFF-008, REQ-AFF-018 e REQ-VAL-001. Invarianti: INV-A7, INV-A9,
INV-A10 e INV-P6.
