# Stabilizzazione dei nomi recuperati

Realizza il completamento dei nomi di segmenti vivi in ADR-0040 §2–3,
senza modificare le decisioni accettate. Requisiti REQ-REC-001,
REQ-REC-004, REQ-STO-003, REQ-STO-006, REQ-AFF-001, REQ-AFF-004,
REQ-AFF-008, REQ-AFF-018; invarianti INV-A9, INV-A10, INV-A11.

## Ingresso dal recovery

```lisp
(arcdocdb.recovery.series:stabilizza-nome-fonte-recuperata
 directory sources position recovered)
;; => T se rinominato, NIL se già definitivo; in entrambi i casi fsync parent riuscita.
```

Il coordinatore mantiene catalogo e CONTROL autorevoli, namespace
esclusivo, set delle [fonti possedute](fonti-recovery.md) aperto e token
semantico immutabile. Chiama questa funzione nel pool I/O dopo il gate
completo di [Serie](recovery-serie.md)/[Archivio](recovery-archivio.md),
prima del checkpoint e dell'ammissione. Il controllo locale riguarda
**una fonte**: non sostituisce quel gate completo.

Il [completamento dell'intera Serie](stabilizzazione-serie.md) applica ora
prima tutti i preflight semantici e dei nomi, poi questa primitiva a ogni
fonte. Restituisce i conteggi completi, conservando gli effetti gia'
riusciti se un completamento successivo fallisce.

Il token deve essere l'ACTIVE o il CLOSED della riga selezionata. Prima
dei nomi si verificano FD esatto, stato, ID u64 completo, CONTROL aperto
e appartenenza al manifest. Per ACTIVE l'EOF attestato deve essere
identico a quello letto; per CLOSED P deve coincidere con il manifest
ed essere entro l'EOF acquisito. Non si restringono gli ID CLOSED:
zero e bit alti restano significativi. Le capacità sono prestate, senza
trasferimento di proprietà o chiusura implicita.

I nomi sono ricavati dall'ID, non forniti dal client. La forma nel set
resta l'osservazione dell'acquisizione, anche dopo la promozione: le
chiamate successive osservano il namespace corrente e lo stesso FD.

## Completamento I/O

`arcdocdb.io:stabilizza-nome-temporaneo` riceve directory, FD readonly,
nome temporaneo e definitivo. È una primitiva interna al motore: il
chiamante deve avere già verificato file e decisione autorevole.
Controlla nomi foglia ASCII, relazione `final + ".tmp"`, modi, backend
identico e callback d'identità senza fallback nativo. Il ramo temporaneo
verifica anche la capacità di [pubblicazione esclusiva](io-pubblicazione.md)
prima di entrare nel confine dell'effetto. La [variante preregistrata](stabilizzazione-esclusiva-metodo.md)
definisce questo collegamento e le sue decisioni.

| Namespace corrente | Esito prima dell'effetto |
|---|---|
| Solo temporaneo, stesso device/inode del FD | Pubblicazione esclusiva, verifica finale, fsync parent |
| Solo definitivo, stesso device/inode del FD | Verifica finale e fsync parent; nessuna rinomina |
| Entrambi, anche se hard link dello stesso file | Rifiuto; nessuna sostituzione |
| Nessuno | Rifiuto |
| Unico nome di un altro file | Rifiuto |
| Symlink, tipo errato, errore diverso da ENOENT | Condizione propagata |

Le identità sono osservate rispetto al FD della directory con nofollow.
Soltanto IO-FAULT con operazione ENTRY-IDENTITY ed errno ENOENT equivale
ad assenza. Il ramo temporaneo delega a `pubblica-temporaneo`: verifica
nuovamente l'identità del sorgente e usa la syscall esclusiva, senza
sostituire un target comparso dopo l'osservazione. Il backend deve offrire
`:rename-exclusive`; `:rename` da solo non è sufficiente. Non esiste un
ripiego sulla rinomina ordinaria.

Nel ramo già definitivo non viene richiesta o chiamata alcuna callback
di rinomina, né verificato il suo simbolo nativo: restano necessari
identità e flush del parent. Entrambi i rami conservano nomi privati e
namespace esclusivo fino al ritorno. La syscall esclusiva protegge il
target; la stabilità del sorgente continua a richiedere l'esclusione
degli altri processi e del writer, oltre a un eventuale mutex locale.

La decisione è nell'EDIT già autorevole. La rinomina esclusiva ne completa il nome;
fsync del parent completa la persistenza del namespace. Non è il punto
di atomicità del [checkpoint di recovery](checkpoint-recovery.md),
che rimane lo swap del CONTROL. I dati non sono riscritti, troncati o
sincronizzati da questa primitiva; la verifica semantica non viene
confusa con una nuova attestazione della loro durability.

Superati i preflight del ramo selezionato, qualsiasi uscita incompleta rende la directory
FAULTED nel modulo I/O, conservando la causa. La postcondizione ricontrolla
entrambi i nomi e l'identità prima di fsync; il FD deve restare aperto.
Non si ritenta con la capacità guasta. Un successivo recovery acquisisce
capacità nuove, osserva temporaneo o definitivo e completa la stessa
decisione. Nel ramo già definitivo fsync resta obbligatoria, anche
quando il precedente tentativo si era interrotto dopo la rinomina.

## Costi e confini

O(1) osservazioni per fonte e stringhe private di 24/20 byte per i nomi
canonici, più le copie private della primitiva. Nessun buffer di segmento,
scansione del corpo, nuovo FD, thread, registro CSN o lock tra Serie.
Un fsync del parent per chiamata riuscita, inclusa quella idempotente:
è un completamento a freddo del recovery, fuori dal percorso delle
richieste. Nessuna misura di RSS, allocazioni, throughput o P99 è dedotta
da questa descrizione.

Restano l'esecuzione coordinata di tutte le azioni dell'inventario,
la rimozione con prova dei file eliminabili, gli indici e l'ammissione.
La funzione non riapre il vecchio ACTIVE in scrittura e non modifica
CLOSED, segmenti rimossi, hint o indici.

## Decisioni e qualifica aperta

| ID | Decisione da qualificare | Stato |
|---|---|---|
| SNR-D01 | Solo ENTRY-IDENTITY + ENOENT diventa assenza | Aperta |
| SNR-D02 | Coppia di nomi, modi e backend/callback coerenti | Aperta |
| SNR-D03 | Esattamente un nome; device e inode uguali al FD | Aperta |
| SNR-D04 | Rinomina solo se temporaneo; definitivo ricontrollato | Aperta |
| SNR-D05 | Ogni uscita incompleta dopo preflight guasta OPEN, mai riapre CLOSED | Aperta |
| SNR-D06 | Token ACTIVE: stato, ID, FD ed EOF della riga esatti | Aperta |
| SNR-D07 | Token ACTIVE e manifest concordano sull'ID | Aperta |
| SNR-D08 | Token CLOSED: stato, ID, FD e P entro EOF | Aperta |
| SNR-D09 | Token CLOSED e manifest concordano su stato e P | Aperta |

SNE-D01…D06 aggiungono i confini dell'integrazione esclusiva: callback
richiesta solo al ramo temporaneo, nessun fallback, ramo definitivo con
fsync obbligatoria e cleanup dei due livelli. Restano da qualificare.

Metodo preregistrato e risultati in
[campagna locale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-17-recovery-name-stabilization/README.md).
Compilazione e controlli statici non verificano rinomina, collisioni,
idempotenza o crash. Test dedicati, FI, MC/DC, copertura, revisione
indipendente e qualifica C1 rimangono aperti. Il confine generale COD-24
del coordinatore resta da integrare; qui è definita solo la quarantena
della capacità directory durante il completamento I/O.

La [campagna dell'integrazione esclusiva del 2026-10-22](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-recovery-exclusive/report.md)
conserva cinque diagnostiche OK/STABLE sul prodotto `e2cb7194`: compilazione
forzata senza avvisi, lint su 355 file, tracciabilità, link e lettura di
otto funzioni compilate. Una revisione indipendente statica non ha trovato
difetti nel cambiamento. I record sono conservati con gzip lossless,
hash e inventario chiuso; nessun test funzionale, FI o benchmark eseguito.
Questo esito aggiunge la lettura indipendente dell'integrazione, senza
qualificare i casi dinamici SNE/SNR/PIO o il recovery completo.
