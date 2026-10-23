# Adozione dei CLOSED nel runtime

`runtime:adotta-directory-closed` collega le mappe GET già costruite e i
[risultati CLOSED](closed-recuperato.md) al nuovo ambito del
[runtime Archivio](runtime-archivio.md). Il costo dipende dal numero di
segmenti, senza ricopiare le righe dei PUT o rileggere header e dati.
Realizza i contratti esistenti di recovery, identità e durata sotto EBR;
non introduce formati persistenti o sezioni critiche per documento.

## Contratto

```lisp
(arcdocdb.runtime:adotta-directory-closed
 archive target-view control recovered-closed maps
 :max-segmenti 65536 :budget-payload 1310720)
```

`archive` è l'oggetto canonico già legato al runtime. `control` è il
risultato autorevole della Serie nell'ambito di bootstrap di quell'Archivio.
`target-view` appartiene per EQ al nuovo ambito runtime e ha lo stesso UUID
di sedici byte. Un clone dello scope con gli stessi registri non è ammesso.
La verifica non ricostruisce il catalogo e non certifica l'unicità fisica
dell'oggetto Archivio o la validità temporale del piano CSN.

I due simple-vector sono paralleli, stabili per tutta la chiamata e
ordinati per ID crescente. Devono contenere tutti e soli i CLOSED del
medesimo CONTROL. Il gate canonico verifica count, ID unici, appartenenza,
prefissi e capacità aperte. Per ciascuna coppia vengono poi confrontati:

- vista bootstrap esatta della mappa;
- stessa capacità `file-io` per EQ del risultato CLOSED, non solo nome o inode;
- ID, frontiera P, versione e origine writer/compaction;
- ordine stretto, FD readonly aperto e ID compatibile con la directory GET.

L'insieme vuoto è valido solo se il manifest non contiene CLOSED. Un insieme
parziale, una mappa di un altro FD o una frontiera diversa sono rifiutati
prima di costruire i wrapper. I limiti esistenti del resolver restano:
ID 1..2^32-1, nessun supporto nuovo agli esiti EDIT nella mappa GET.
Il recovery storage continua ad accettare ID u64, incluso zero; qui i valori
non rappresentabili vengono rifiutati, mai troncati.

## Proprietà, lifetime e pubblicazione

Ogni mappa riceve nuovi wrapper `segmento-get`/`mappa-segmento-get`.
Conserva FD, ID, versione, origine, frontiera e lo stesso array readonly
delle righe. La directory canonica copia il vettore dei riferimenti e
costruisce gli ID ordinati. I vettori del caller possono essere riusati
dopo il ritorno; non vengono trattenuti CONTROL, risultati CLOSED, vecchie
mappe o viste bootstrap. Nessun array interno viene esportato.

La condivisione riguarda esclusivamente righe immutabili e capacità readonly.
Non trasferisce la proprietà fisica dei FD: il proprietario già esistente
deve mantenerli aperti fino al termine di tutti i borrower di bootstrap e
runtime, poi al reclaim autorizzato da EBR. Nessuna nuova apertura o close,
nessun doppio cleanup implicito. Un errore lascia candidati privati al GC e
propaga la condizione originale; non chiude risorse del caller.

Il coordinatore congela file, namespace e ingressi per l'intera operazione.
I controlli di lifetime non sono una lease o una certificazione futura.
Accessi Lisp agli interni privati sono fuori dal contratto pubblico.

La directory restituita non è pubblicata. La vista target deve ricevere
un primary coerente, e le fonti vanno pubblicate prima delle location.
L'ACTIVE recuperato non viene implicitamente chiuso o incluso: se CONTROL
lo considera ancora ACTIVE, resta fuori da questa directory. Checkpoint,
nuovo CONTROL e nuovo insieme CLOSED devono essere coordinati esplicitamente;
non si accettano token di CONTROL differenti per evitare una nuova lettura.
Nessuna autorizzazione al traffico è dedotta dall'adozione.

## Budget e costo

`max-segmenti` è un intero 1..65536; `budget-payload` un `index` non negativo.
Forma, count e budget sono verificati prima del gate che alloca la tabella
dei duplicati e prima dei nuovi wrapper. Su SBCL 64 bit il picco degli array
nuovi è 20*N: vettore temporaneo 8*N, riferimenti della directory 8*N e ID
u32 4*N. Il payload finale nuovo è 12*N; le righe esistenti non sono copiate.
La configurazione di default copre 65536 segmenti. Sono esclusi hash del
gate, wrapper, header, capacità, righe condivise e GC: non è un limite RSS.

Le scansioni sono limitate da N. Il gate usa una tabella hash privata per
la completezza; la directory non ordina implicitamente gli ingressi.
Non vengono introdotte allocazioni o verifiche nel percorso GET già
esistente. Costo del bootstrap, GC, memoria e throughput restano da misurare.

## Decisioni e qualifica aperta

| ID | Casi da verificare |
|---|---|
| RCL-D01 | Entrambi simple-vector; entrambi i tipi errati separatamente |
| RCL-D02 | Tipo e limiti max; tipo budget; zero e 20*N esatto/meno uno |
| RCL-D03 | Count paralleli; completo/vuoto/mancante/duplicato; gate CONTROL canonico |
| RCL-D04 | Runtime presente; scope origine e destinazione EQ; clone con medesimi registri |
| RCL-D05 | UUID Serie uguale/diverso, compresa verifica difensiva durante il trasferimento |
| RCL-D06 | Mappe della vista esatta; FD EQ, anche contro una seconda apertura dello stesso file |
| RCL-D07 | ID AND P AND versione AND origine: ogni disaccordo separato |
| RCL-D08 | Ordine, duplicati, ID zero/u64 fuori range, capacità chiusa/faulted/append |
| RCL-D09 | Nuovo owner AND righe EQ AND FD EQ; FI di ogni postcondizione difensiva |
| RCL-D10 | Directory finale completa, input riusabili, vecchie viste non trattenute |

Questo incremento prevede compilazione del solo prodotto senza avvisi,
controlli statici, tracciabilità, link e conservazione dei record originali.
Non aggiunge o esegue test funzionali, FI, copertura, modelli o benchmark.
Due riletture dell'autore non costituiscono revisione indipendente.
RCL-D01…D10, MC/DC, confine generale COD-24, misure e qualifica C1 rimangono
aperti. Anche la CI generale non sostituisce una suite dedicata all'adattatore.

I [record locali e le due riletture dell'autore](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-17-runtime-closed/README.md)
conservano compilazione, controlli statici e disassemblaggio della revisione
congelata, senza promuoverli a qualifica funzionale.
