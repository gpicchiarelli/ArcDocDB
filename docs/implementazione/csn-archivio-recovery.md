# Piano CSN dell'Archivio recuperato

`arcdocdb.recovery.archive.csn` aggrega i [massimi recuperati](recovery-csn.md)
di un insieme completo di Serie e del decision log dell'Archivio. Realizza
un passo della sequenza di [recovery](../architettura.md#recovery), senza
cambiare ADR-0020, ADR-0038, ADR-0041 o ADR-0046.

Il piano prepara la base del futuro registro CSN. Non crea il registro,
non ricostruisce gli indici e non autorizza l'ammissione del traffico.
Il [bootstrap runtime](runtime-archivio.md) collega ora questa base alla
famiglia unica dei registri; l'ammissione resta responsabilità del controller.

## Insieme delle Serie

Il controller consegna l'oggetto canonico `archivio-recovery`, la vista
canonica di Registri e il vettore completo delle viste del catalogo.
`crea-insieme-serie-recovery` copia il vettore e controlla stesso ambito
GET, UUID distinti e presenza di Registri per identità `EQ`. Due viste
differenti con lo stesso UUID sono rifiutate. Gli UUID delle viste sono
già copie possedute, immutabili per protocollo; non vengono duplicati.
Modificare poi il vettore del caller non modifica l'insieme.

**Completezza rispetto al catalogo persistente e ruolo di Registri sono
precondizioni del controller.** L'API non legge il catalogo, non deduce
ruoli dal nome e non può rilevare una Serie omessa dall'elenco iniziale.
Il catalogo di prodotto resta da collegare.

## Provenienza delle decisioni

Ogni tabella del replay DECISION riceve un marker privato di identità,
privo di campi e riferimenti a entry, buffer o FD. ACTIVE conserva il
marker della tabella realmente usata nella risoluzione dei prepared.
Il marker non trattiene la tabella delle decisioni.

Il piano richiede lo stesso oggetto Archivio per insieme e decision log,
la stessa vista `EQ` per ogni ACTIVE, lo stesso marker del replay e il
gate canonico di tutti i CLOSED del rispettivo CONTROL. Un replay distinto
degli stessi byte riceve un marker diverso: non viene scambiato con la
fonte usata per i presumed abort, anche per ACTIVE senza prepared.

L'API ACTIVE di basso livello rimane disponibile: il piano accetta il suo
risultato solo se ha usato proprio la tabella del decision log fornito.
Il marker è un controllo interno, non una firma o un confine di sicurezza
contro codice Lisp che accede agli interni privati. Nessun formato su
disco o registro condiviso fra Serie cambia.

Cambiano i layout privati della tabella e del risultato ACTIVE: occorre
ricompilare e ricaricare il sistema, senza riutilizzare vecchie istanze.

## API pubbliche

| API | Risultato |
|---|---|
| `crea-insieme-serie-recovery(archive, registri, views :max-series 65536 :budget-riferimenti 524288)` | Insieme posseduto, ordine del catalogo |
| `numero-serie-recovery(set)` | Numero delle viste copiate |
| `crea-piano-csn-archivio(set, decisions, active, closed :max-segmenti-serie 65536 :max-segmenti-totali 1048576)` | Piano dopo tutte le verifiche |
| `massimo-csn-archivio(plan)` | Presenza e massimo u64; `NIL/0` distinto da `T/0` |
| `statistiche-piano-csn-archivio(plan)` | Numero Serie e numero segmenti ACTIVE+CLOSED |
| `parole-base-csn-archivio(plan)` | High/low u32 dell'ultimo CSN, senza incremento |

`active` è un simple-vector dei risultati ACTIVE. `closed` è un
simple-vector dei rispettivi simple-vector CLOSED. Count e ordine sono
quelli dell'insieme posseduto. Registri può occupare qualsiasi posizione.
I vettori del caller restano congelati fino al ritorno; non sono trattenuti.

Il massimo include tutte le DECISION, anche senza prepared nelle Serie,
e tutte le fonti già descritte per ciascuna Serie. TXID, ordini dei log di
controllo, frontiere e byte di coda non contribuiscono.
Il piano conserva solo l'oggetto Archivio e quattro scalari. Non conserva
insieme delle viste, risultati delle Serie, tabelle, decision log o FD.
La salute delle fonti è controllata durante la costruzione, non certificata
per il futuro. Un errore impedisce il risultato; nessun massimo parziale
è pubblicato e nessun registro runtime viene modificato.

## Budget e costi

Numero Serie e `8*N` byte di riferimenti sono controllati prima di copia e
tabella UUID. È il budget logico su SBCL a 64 bit: esclude hash table,
header Lisp, viste già esistenti e GC; non è un tetto RSS.
Il piano verifica cardinalità e somma `N + SUM(CLOSED_i)` prima dei gate
che allocano le tabelle dei duplicati. Il tetto globale include gli ACTIVE.
Le scansioni sono limitate a viste, CLOSED ed entry DECISION già verificate;
i gate CLOSED mantengono i loro budget. Nessun nuovo I/O, thread, timer,
callback o lock; nessuna modifica a GET o commit. Un marker per tabella e
un riferimento per ACTIVE; costi di oggetti, boxing e GC da misurare.

## Base e apertura del runtime

La base è **M**, ultimo CSN osservato, non M+1. Il registro esistente
assegna M+1 alla prima richiesta. Il massimo u64 rimane rappresentabile;
le assegnazioni successive sono rifiutate con `:csn-exhausted`, senza wrap.

L'ambito GET del recovery può essere un ambito di bootstrap. Il piano non
riscrive il suo registro snapshot o il registro CSN già associato. Il
bootstrap runtime costruisce la famiglia unica dei registri con la base
validata. Il controller deve ancora associare scritture/snapshot/viste e
completare gli obblighi di pubblicazione. Due piani non autorizzano due
allocatori per lo stesso Archivio canonico.

Prima dell'ammissione restano catalogo/inventari autorevoli, riconciliazione
fisica, indici e radici coerenti, chiusura/pubblicazione del vecchio ACTIVE,
obblighi multiserie completati e uso dello stesso registro da tutti i controller.

## Decisioni e qualifica

Requisiti REQ-REC-001/002, REQ-MVC-006, REQ-TXM-005/007 e REQ-AFF-008;
invarianti INV-M5, INV-T2, INV-S7, INV-A8 e INV-P6.

| Caso | Decisione e obbligo dedicato |
|---|---|
| ACR-D01 | Stesso N, N positivo, `8*N <= budget` prima della copia; ogni condizione |
| ACR-D02 | Vuoto, max Serie o budget riferimenti superati prima delle allocazioni |
| ACR-D03 | Scope diverso, UUID duplicati con viste EQ/diverse, Registri assente/clone |
| ACR-D04 | Stesso oggetto Archivio, count ACTIVE AND count CLOSED entrambi esatti |
| ACR-D05 | Budget per Serie OR somma globale, ACTIVE inclusi, zero CLOSED valido |
| ACR-D06 | Vista ACTIVE esatta e marker esatto, anche con CSN uguali |
| ACR-D07 | Gate CLOSED: CONTROL/P diversi, duplicati, count e lifetime |
| ACR-D08 | Massimo DECISION maggiore/minore/uguale alle Serie, ordine TXID diverso |
| ACR-D09 | Nessun CSN, zero presente, bit alti, massimo u64; nessun incremento |
| ACR-D10 | Consumo esatto AND (presenza OR massimo zero); ogni condizione |
| ACR-D11 | Copia del vettore posseduta; nessun elenco o fonte pesante trattenuto nel piano |
| ACR-D12 | Query DECISION: consumo esatto AND (count positivo OR massimo zero); forma entry verificata prima del massimo |

Le [prime evidenze](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-archive-csn-plan/README.md)
separavano build, statica e due letture dell'autore dalla qualifica.
La [campagna dedicata](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-archivio-csn-verifica/report.md)
conserva 54 test composti, prove native/FI, revisione indipendente e controllo
completo locale. C1/MC/DC, allocazioni/prestazioni e integrazione nel controller
restano aperte; quella campagna verificava il ponte al registro esistente
soltanto nei test. Il bootstrap di prodotto ha un metodo dedicato.
Il [metodo della verifica dedicata](archivio-csn-verifica.md) definisce le
fixture pubbliche, il ponte di prova al registro e la conservazione dei run.
La query fonte DECISION ricontrolla forma delle entry e consumo/normalizzazione
prima del ritorno; nessun nuovo contenitore o secondo attraversamento.
