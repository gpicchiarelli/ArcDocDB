# Visita dei record CLOSED recuperati

> **Deciso (ADR-0042, ADR-0047, ADR-0036)** — la ricostruzione considera
> i record committed di tutti i segmenti, conserva i tombstone fino alla
> selezione definitiva e risolve i prepared senza usare il TXID come CSN.

`arcdocdb.recovery.replay` collega il [reader CLOSED](closed-recuperato.md)
ai consumatori privati del bootstrap. Requisiti REQ-REC-001, REQ-STO-006,
REQ-TXM-007, REQ-IDX-006, REQ-AFF-002 e REQ-AFF-008; invarianti INV-D1,
INV-C11, INV-I2 e INV-A9. Nessun formato persistente o ADR modificato.

## Contratto

```lisp
(arcdocdb.recovery.replay:visita-record-closed-recuperato
 recovered scratch limits visitor)
;; => delivered-records, aborted-records
```

`recovered` è la prova canonica di un CLOSED writer o compaction.
`limits` è la configurazione readonly `limiti-recovery-serie` già usata
dal coordinatore. Lo scratch deve contenere il prefisso P intero.
Il compito appartiene al pool I/O della Serie: mantiene CONTROL, FD,
file e namespace congelati, con ammissione ancora chiusa. Le destinazioni
del visitor sono candidate private del bootstrap.

La funzione rilegge **lo stesso FD readonly**, fino al P autorevole del
manifest; non usa EOF come frontiera, non legge la coda e non riapre file.
Il reader canonico verifica alias, backend, capacità, budget, header,
CRC, lotti/SEAL e risoluzione OUTCOME/EDIT prima di qualunque callback.
La nuova prova deve coincidere con quella ricevuta per autorità,
geometria, conteggi, presenza e massimo CSN. Il confronto non dimostra
uguaglianza dei body: l'immutabilità delle fonti resta una precondizione.

Il reader con workspace è un ingresso **interno** condiviso: restituisce
al visitor lo stesso workspace semantico appena verificato, senza
ricostruire una seconda tabella. L'API pubblica `leggi-closed-recuperato`
continua a consegnare un solo risultato, privo di workspace e buffer.

## Callback e prepared

```lisp
(visitor buffer start end segment-id file-offset version prepared-csn)
;; => NIL
```

Vengono consegnati soltanto PUT e TOMBSTONE committed, in ordine fisico
nel segmento. OUTCOME e SEAL non entrano nel visitor. I byte sono prestati,
readonly e validi durante la chiamata sincrona: niente modifica, riuso,
reentrata sullo scratch o conservazione di un riferimento ai documenti.
Un consumatore che deve conservare dati ne copia esplicitamente soltanto
la parte prevista dal proprio contratto.

| Record | Consegna | `prepared-csn` |
|---|---|---|
| PUT/TOMBSTONE ordinario in prefisso verificato | Sì | NIL; CSN nello stamp |
| Prepared con OUTCOME locale | Sì | CSN dell'OUTCOME |
| Prepared senza OUTCOME, con esito EDIT | Sì | CSN dell'EDIT |
| Prepared senza entrambe le prove | No, conteggiato abortito | Nessuna callback |
| OUTCOME o SEAL | No | Nessuna callback |

Contraddizioni fra OUTCOME e EDIT sono rifiutate dal reader **prima**
della visita. Il CLOSED non consulta `multiserie.log`; un esito da
DECISION deve essere già conservato nell'EDIT canonico. Un CSN zero è
presente e viene passato come intero zero, distinto da NIL. ID segmento,
TXID e CSN conservano tutti i bit u64, senza introdurre i vincoli u32
del destinatario primary/GET.

Lo span completo e la versione possono alimentare
`considera-record-recuperato` del [selettore](selezione-versioni-recovery.md),
con `prepared-csn` esplicito soltanto per i prepared. La visita non
raggruppa le chiavi: il consumatore deve raccogliere tutti i candidati
della stessa chiave da **tutti** i segmenti prima della
[materializzazione nell'indice](indice-da-recovery.md). Non è previsto
un replay completo ottenuto riscansionando ogni segmento per ogni chiave.

`file-offset` è assoluto nel file. Qui coincide con `start` perché il
buffer contiene il prefisso a partire dall'header; i due argomenti restano
distinti nel contratto del consumatore.

## Risultato, errori e durata

I due contatori riguardano **record**, non TXID: un prepared con più
modifiche abortite incrementa il secondo contatore per ogni modifica.
I conteggi del reader conservano il significato originario. Il ciclo ha
esattamente BATCHES + RECORDS passi e deve terminare esattamente a P,
con conteggi di cornici e lotti identici a quelli verificati.

Il visitor deve controllare gli esiti del proprio lavoro e restituire
NIL. Un altro valore produce INVALID-ARGUMENT dopo i suoi eventuali
effetti. Condizioni e uscite non locali propagano senza retry, rollback
o close implicita. Un errore dopo alcune callback lascia un candidato
privato incompleto: il coordinatore deve scartarlo o invalidarlo e
mantenere l'ammissione chiusa. Il confine FAULTED della Serie resta da
collegare; questa API non introduce un nuovo controller.

Prima del primo callback ogni errore del reader lascia il consumatore
intatto. Questo vale per il singolo segmento, non per l'intero Archivio.
Dopo l'ultima callback si verificano ancora capacità aperte e consumo.
Un risultato riuscito non pubblica indici, radici GET o visibilità dei
commit e non trasferisce la proprietà dei FD.

## Lavoro e memoria

Una rilettura sequenziale del prefisso, controlli integrali canonici e
un attraversamento aggiuntivo dei soli header per la consegna. I body
non sono copiati dal visitatore; il consumatore può ricontrollarli.
Il workspace delle prove resta limitato dai budget prepared/outcome
del reader e viene rilasciato dopo la visita. Nessuna nuova tabella o
entry Lisp viene creata esplicitamente per record dalla consegna.

Lo scratch di P byte, gli oggetti del reader e le sue tabelle sono
allocazioni del percorso a freddo, non una stima RSS. Il lavoro del
visitor, lookup EDIT, boxing, GC e latenza non sono misurati qui. Nessun
lavoro aggiunto al percorso ordinario GET/PUT e nessuna nuova scrittura
o attesa condivisa fra Serie. ACTIVE, raggruppamento delle chiavi e gate
complessivo rimangono incrementi separati.

## Decisioni e qualifica aperta

| ID | Decisione da qualificare | Stato |
|---|---|---|
| RCR-D01 | Reader interno con workspace; API pubblica con un solo valore | Aperta |
| RCR-D02 | Budget/alias/frontiera e verifiche complete prima del visitor | Aperta |
| RCR-D03 | Stessa autorità, geometria, conteggi e massimo CSN | Aperta |
| RCR-D04 | Ordinario, OUTCOME locale, EDIT o prepared abortito | Aperta |
| RCR-D05 | CSN zero presente, u64 alti e assenza distinta da zero | Aperta |
| RCR-D06 | Soli PUT/TOMBSTONE; esclusione OUTCOME/SEAL | Aperta |
| RCR-D07 | Visitor sincrono, NIL obbligatorio e propagazione delle uscite | Aperta |
| RCR-D08 | Ciclo limitato, conteggi per record e consumo esatto fino a P | Aperta |
| RCR-D09 | Compaction ordinaria, vuoto e workspace NIL | Aperta |
| RCR-D10 | Fonti aperte fino alla consegna; nessuna pubblicazione parziale | Aperta |

[Metodo preregistrato e risultati locali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-closed-replay/README.md).
Test funzionali dedicati, compatibilità del reader pubblico, FI, MC/DC,
copertura, revisione indipendente, misure di prestazione e qualifica C1
rimangono aperti. I controlli statici non chiudono queste voci.
