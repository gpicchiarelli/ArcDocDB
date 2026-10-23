# Recovery semantico dell'insieme Serie

`arcdocdb.recovery.series` collega le [fonti readonly possedute](fonti-recovery.md)
ai reader [ACTIVE](active-recuperato.md) e [CLOSED](closed-recuperato.md).
Usa il CONTROL autorevole e lo stesso replay completo delle decisioni
dell'Archivio. Non aggiunge formati, log o punti di atomicità durevole.

## API

```lisp
(let ((limits (arcdocdb.recovery.series:crea-limiti-recovery-serie)))
  (arcdocdb.recovery.series:leggi-serie-recuperata
   control sources decisions scratch limits))
```

Due valori al successo: `active-recuperato` e un nuovo simple-vector di
`closed-recuperato`, completo e ordinato per ID u64. Il caller possiede il
vettore e lo mantiene stabile quando lo passa ai gate successivi. I token
sono immutabili e legati allo stesso CONTROL; ACTIVE conserva il marker
del replay realmente usato. Nessuna tabella interna o buffer viene esposto.

Il proprietario del set mantiene le capacità aperte per tutta la chiamata
e per tutti gli usi dei risultati. Fonti, CONTROL, decisioni, namespace e
scratch devono restare stabili sotto recovery esclusivo nel pool I/O.
L'autorità del catalogo e la completezza del decision log rimangono quelle
dei reader esistenti; l'acquisizione dei nomi da sola non le dimostra.

## Preflight prima dei dati

Prima del primo header vengono verificati:

1. count del set uguale a CLOSED del manifest più un ACTIVE;
2. limite complessivo dei segmenti e budget del nuovo vettore;
3. ambito esatto fra CONTROL e decisioni, assenza di alias UUID, decision FD aperto;
4. ID strettamente crescenti e stato di ogni fonte uguale al manifest;
5. unico ACTIVE uguale a quello del CONTROL;
6. preflight canonico di ogni reader: FD readonly, backend, scratch e limiti;
7. P di ogni CLOSED non maggiore dell'EOF attestato del suo FD;
8. somma EOF ACTIVE + P dei CLOSED entro il budget cumulativo di lettura.

Appartenenza, ordine stretto e cardinalità provano completezza senza
allocare un'altra tabella dei duplicati. ID zero è un precedente valido:
NIL indica l'assenza di un precedente. Anche la posizione ACTIVE zero è
valida. I CLOSED mantengono gli ID u64 del reader; ACTIVE conserva il
limite esistente di ID positivo del costruttore GET. Nessun troncamento.

La forma final/temporary del nome rimane un fatto del planner. Questa API
non applica rinomine o cancellazioni. Il set può essere acquisito usando
un altro manifest: eventuali disaccordi di count, ID o stato vengono
rifiutati; header e prefissi sono poi verificati contro il CONTROL fornito.
La provenienza fisica e la stabilità del namespace restano obblighi del
coordinatore, senza inferenze da UUID uguali o nomi simili.

## Esecuzione e fallimenti

Viene letto prima ACTIVE, con il suo EOF completo e le decisioni
multiserie canoniche. Poi tutti i CLOSED, sequenzialmente, con lo stesso
scratch e con P dal manifest. Nessun byte oltre P è letto per CLOSED;
l'eventuale coda ACTIVE segue lo scanner canonico fino all'EOF attestato.
I reader non trattengono lo scratch e possono usarlo serialmente.

Prima del ritorno vengono verificati count consumato, insieme CLOSED
canonico, capacità ACTIVE e decision log ancora aperti. I due valori
escono insieme soltanto dopo questi controlli. Un errore in qualunque
segmento non consegna un risultato parziale. Lo scratch può essere stato
modificato; nessuna promessa di rollback dei buffer privati.

Il set è prestato, non trasferito. Non viene chiuso sul successo o sul
fallimento e nessun child viene chiuso individualmente. Le condizioni
originarie propagano senza retry o mascheramento: il proprietario esegue
poi il cleanup del set dopo tutti i borrower. Non è introdotto un nuovo
gestore generico di errori o un protocollo di cleanup concorrente.

Il risultato consente al coordinatore di alimentare i gate esistenti:
massimo CSN di Serie, piano CSN completo dell'Archivio e checkpoint del
vecchio ACTIVE. Non ricostruisce primary/secondary index, non pubblica
fonti o radici, non completa la riconciliazione fisica o il gate del
traffico. Il confine generale di arresto su invariante C1 resta aperto.

## Limiti e costi

La configurazione readonly è creata prima delle letture. Tipi/range
scalari errati segnalano TYPE-ERROR; geometria invalida INVALID-ARGUMENT.
Le decisioni del reader CLOSED vengono riusate nella factory, senza I/O.

| Opzione | Default | Ambito |
|---|---:|---|
| `max-segmenti` | 65536 | Tutte le fonti, ACTIVE incluso; `index` positivo configurabile |
| `budget-riferimenti` | 524288 | 8*N CLOSED su SBCL 64 bit, prima del vettore |
| `max-byte-totali` | 4 GiB−1 | Somma EOF ACTIVE + P CLOSED; zero ammesso |
| `chunk-bytes` | 65536 | Trasferimento di ogni reader, positivo |
| `max-bytes` | 268435456 | Limite per segmento dei reader esistenti |
| `max-batches` | 65536 | Per segmento, positivo |
| `max-records` | 1048576 | Per segmento, zero ammesso |
| `max-batch-records` | 65536 | Per lotto, u32 positivo |
| `max-batch-bytes` | 67108864 | Per lotto; almeno cornice SEAL |
| `max-prepared`, `max-outcomes`, `max-esiti-chiusura` | 65536 ciascuno | Per segmento, u32; zero ammesso |

Lo scratch prestato deve contenere il massimo fra EOF ACTIVE e P CLOSED;
chunking limita il trasferimento, non la memoria integrale richiesta dai
reader attuali. Il limite cumulativo controlla i byte sorgente logici,
non IOPS, latenza o riletture in memoria. Il budget riferimenti esclude
scratch, token, workspace dei reader, hash del gate finale, header e GC:
non è RSS. Non vengono introdotti oggetti aggiuntivi per documento.

La verifica delle fonti usa scansioni limitate al numero di segmenti e
query del manifest; non ri-enumera la directory né riapre file. Il gate
finale conserva la sua tabella privata bounded. Nessuna allocazione o
verifica aggiunta al percorso delle richieste già esistente. Memoria
effettiva, GC e prestazioni del recovery rimangono da misurare.

## Decisioni e metodo prima delle esecuzioni

| ID | Casi dedicati da verificare |
|---|---|
| SRS-D01 | Factory: range segmenti e geometria canonica; limiti zero ammessi/non ammessi |
| SRS-D02 | Count completo; mancante, extra, vuoto, solo ACTIVE |
| SRS-D03 | Budget segmenti e riferimenti: uguaglianza e meno uno, prima del vettore/dati |
| SRS-D04 | Scope esatto, clone, decision FD chiuso, alias scratch/UUID Serie e Archivio |
| SRS-D05 | Ordine u64, duplicato, primo ID zero, ID sopra u32; appartenenza e stato |
| SRS-D06 | ACTIVE unico, mancante, duplicato, ID diverso; posizione zero valida |
| SRS-D07 | P <= EOF, P != EOF valido; backend/FD/range scratch e singoli budget |
| SRS-D08 | Somma byte esatta/meno uno; nessuna lettura parziale prima del rifiuto |
| SRS-D09 | v1/v2, writer/compaction, OUTCOME/EDIT/DECISION, abort e TAIL ACTIVE |
| SRS-D10 | Guasto primo/ultimo CLOSED dopo ACTIVE; nessun risultato o close, causa originale |
| SRS-D11 | Insieme finale, FD e decisioni aperti; scratch riusabile e vettore nuovo indipendente |

Sono previsti compilazione del solo prodotto senza avvisi, stile,
tracciabilità, link, lettura del disassemblaggio e controllo C4 degli
archivi. Due riletture statiche dell'autore restano distinte dalla revisione
indipendente. Nessun nuovo test funzionale, FI, copertura, modello o
benchmark viene aggiunto o eseguito in questo incremento. SRS-D01…D11,
MC/DC, qualifica C1, arresto generale e integrazione completa restano aperti;
la CI generale non sostituisce le prove dedicate mancanti.

I [registri delle tre revisioni e le due riletture](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-17-serie-semantic/README.md)
conservano compilazione e controlli statici, inclusi i log dei worker C4.
