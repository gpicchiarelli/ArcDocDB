# Pubblicazione di temporanei senza sostituzione

`arcdocdb.io:pubblica-temporaneo` fornisce il confine I/O per completare
un segmento `.tmp` nominato da una decisione già durevole, secondo
[ADR-0040](../adr/0040-manifest-a-record-unico.md#3-riconciliazione-al-riavvio).
La [stabilizzazione della fonte recuperata](stabilizzazione-nomi-recovery.md)
la collega ora al token semantico, al CONTROL e al flush parent per fonte.
Il Recovery Manager deve ancora coordinare l'insieme completo e l'ammissione.
Il [metodo e le decisioni](io-pubblicazione-metodo.md)
precedono codice e diagnostiche.

## Contratto

```lisp
(arcdocdb.io:pubblica-temporaneo
 directory source-readonly "0000000000000001.seg.tmp" "0000000000000001.seg")
(arcdocdb.io:durable-flush directory)
```

Il compito I/O possiede il namespace esclusivo e mantiene aperte le
capacità prestate. `directory` è un parent aperto; `source-readonly` è il
file regolare readonly già verificato. Il caller garantisce contenuti,
EDIT autorevole durevole e stabilità del sorgente; un nome `.tmp` non è
una prova di appartenenza. La primitiva accetta foglie ASCII stampabili,
1…255 byte, senza slash, backslash, NUL, `.` o `..`. Il nome sorgente è
esattamente il target seguito da `.tmp`, rispettando anche il limite 255.

Prima degli effetti controlla capacità, nomi e backend; copia i nomi in
stringhe private e confronta device/inode del FD con il sorgente relativo
allo stesso parent, senza seguire symlink. La rinomina esclusiva rifiuta
un target già presente nella syscall. Il nome finale viene verificato
contro il FD prima del ritorno. Le primitive native sono specificate nel metodo.

Il risultato NIL attesta la rinomina e le postcondizioni del namespace.
La decisione EDIT resta il punto atomico del database; la rinomina
completa quella decisione. La durability del parent richiede il flush
separato. Il FD readonly resta utilizzabile con la stessa identità; la
primitiva non modifica i byte del segmento o le frontiere I/O.

L'esclusione del target non protegge un sorgente sostituito fra controllo
e syscall. L'esclusività del namespace rimane una precondizione, come
per l'[apertura relativa](io-apertura-relativa.md) e l'inventario. Il
coordinatore non riusa i nomi osservati nel vecchio set delle fonti dopo
il completamento come se fossero ancora attuali. La stabilizzazione osserva
invece entrambi i nomi canonici e può completare il ramo già definitivo;
un esito incerto con capacità guasta richiede una nuova acquisizione.

## Backend, errori e costi

Il backend fidato aggiunge `:rename-exclusive` con firma
`(directory-fd source target) -> 0`. Sono obbligatorie anche `identity`
e `entry-identity`, sullo stesso backend del parent e del file. Le
callback esistenti di rinomina ordinaria non sono un fallback. Il nuovo
slot richiede ricompilazione e nuove istanze del backend.

| Confine | Esito |
|---|---|
| Modo, foglia o relazione `.tmp` errata | `invalid-argument`; nessun effetto |
| Backend diversi | `invalid-argument`, `:io-identity-backend` |
| Callback/simbolo non disponibile | `unsupported-format`, `:io-publish-unavailable` |
| ABI o piattaforma non ammessa | `unsupported-format`, `:io-abi` o `:io-platform` |
| Sorgente diverso dal FD prima della rinomina | `invalid-argument`, `:io-replacement-identity`; nessuna rinomina |
| Identità illeggibile/non regolare | Condizione originale; nessuna rinomina se il preflight non termina |
| Target occupato o errore della syscall | `io-fault`, operation `:rename`, errno originale |
| Callback non zero | `io-fault`, `:io-rename-result` |
| Postcondizione o uscita incompleta dall'effetto | Causa originale, parent ancora aperto portato a `:faulted` |

Il cleanup è quello comune della [rinomina nella directory](io-rinomina.md).
Non riapre una capacità chiusa o già faulted e non maschera la condizione.
Nessun retry, rollback, close, unlink o flush implicito. Un target presente
guasta conservativamente la capacità parent anche quando il kernel ha
rifiutato l'effetto: il caller deve riconciliare prima di proseguire.
Le condizioni di supporto del filesystem non producono un ripiego meno
restrittivo. Non vengono cancellati temporanei orfani o segmenti rimossi.

Due nomi bounded, un effetto di rinomina e verifiche di identità in numero
costante. Copie, callback e FFI possono allocare sul percorso freddo.
Nessun thread, lock o scrittura condivisa fra Serie, né modifica al
percorso caldo delle richieste. Non sono state misurate prestazioni.

## Stato della verifica

Il perimetro di questo incremento è compilazione senza avvisi e controlli
statici registrati, con revisione indipendente del codice. Non sono
aggiunti o eseguiti test funzionali, FI, copertura, mutazioni o benchmark.
Le decisioni PIO-D01…D09 restano da qualificare. La presenza della primitiva
non chiude il recovery fisico, l'ammissione o i gate C1/MC/DC.

La [campagna locale conservata](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-17-io-publish-exclusive/report.md)
comprende sei diagnostiche riuscite e il primo disassemblaggio fallito per
una cache C4 piatta, poi corretto senza modifiche al prodotto. Compilazione
forzata senza warning/style-warning; lint 351 file, tracciabilità e link
senza errori. Il secondo disassemblaggio legge sette funzioni senza
invocare la nuova API. Sorgenti, varianti dei metodi e originali sono
raccolti con hash e inventario chiuso.

La revisione indipendente è statica. Il supplemento conferma che sulle
architetture di riferimento Linux x86-64 e Darwin ARM64 il linkage SBCL
permette il rifiuto esplicito del simbolo assente nella preflight. Su altre
architetture un warning del loader può precedere l'API; questo confine
resta non qualificato. La campagna non ha eseguito la nuova syscall né
verificato il supporto di filesystem o piattaforme diverse.
