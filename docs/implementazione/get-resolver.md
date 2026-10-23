# Resolver GET dei segmenti CLOSED

Il modulo [`arcdocdb.get.resolver`](../../src/get-resolver/) collega il
[nucleo GET](get-record.md) ai segmenti CLOSED nominati dal
[manifest](manifest-control-log.md). Risolve posizione, flag storage, CSN e
offset della prova OUTCOME mediante una mappa immutabile verificata.

È un componente del percorso di lettura, con **qualifica C1 aperta**.
Il [percorso ACTIVE ordinario](get-active.md) ha un ponte dedicato alla radice
del controller. Le prove ACTIVE multiserie, la directory delle capacità, le prove EDIT e il server
restano da integrare. Non modifica le decisioni architetturali o i formati.
Riferimenti: [ADR-0037](../adr/0037-lotto-sigillato.md),
[ADR-0041](../adr/0041-multiserie-segmenti-autosufficienti.md),
[ADR-0044](../adr/0044-cache-acceleratore-puro.md),
[ADR-0047](../adr/0047-verifica-csn-dei-record-prepared.md).

## Costruzione e autorità

`crea-mappa-segmento-get(view, file, manifest, id, buffer, …)` si esegue nel
pool I/O, fuori dai GET. Il controller associa manifest e vista della stessa
Serie; il manifest attuale non porta un'identità Serie verificabile dal
resolver. Il file è readonly e il segmento rimane immutabile.

1. Verifica budget, ID positivo u32 e stato CLOSED nel manifest. ACTIVE,
   REMOVED e UNKNOWN sono rifiutati. Un ID u64 oltre u32 richiede un futuro
   layout dell'indice: non viene troncato.
2. Prende `valid-bytes` dalla chiusura del manifest. Un limite impossibile è
   corruzione; buffer o budget insufficienti sono `resource-exhausted`.
   La dimensione fisica del file non sostituisce questa frontiera.
3. Costruisce la capacità GET leggendo e verificando l'header dal file dato.
   Legge il resto **dallo stesso FD**, soltanto fino a `valid-bytes`.
4. Per origine writer verifica tutti i lotti, i SEAL, il file-id, i confini,
   il checksum del lotto e i CRC dei record. La frontiera deve terminare
   esattamente dopo un lotto completo. Per origine compaction riusa il
   verificatore CLOSED: solo PUT/TOMBSTONE ordinari.
5. Conta PUT e OUTCOME, autorizza il picco del payload, copia le prove in
   array u32 e le ordina stabilmente per TXID con otto passate radix limitate.
   Duplicati con lo stesso CSN sono ammessi; CSN discordi producono corruzione.
6. Costruisce una riga compatta per ogni PUT, in ordine fisico. Un prepared
   risolto conserva CSN e offset dell'OUTCOME successivo al PUT. Un prepared
   senza esito conserva prova zero; non può essere restituito da un GET.

Il buffer deve restare esclusivo e stabile dall'I/O al ritorno. La verifica
integrale del body avviene nel passo 4. Gli attraversamenti successivi
ricontrollano CRC e forma delle intestazioni, senza scandire di nuovo i body;
la copia degli OUTCOME verifica nuovamente anche il loro body. Le passate
interne non sono parser autonomi e non sono esportate.
Senza OUTCOME si evita l'attraversamento dedicato alla copia delle prove.

Non si usa il classificatore TAIL: qui si verifica un prefisso fissato dal
manifest, senza affermare che coincida con l'EOF fisico. Eventuali byte oltre
la frontiera rimangono intatti e non vengono letti.

La chiusura che contiene esiti aggiuntivi nell'EDIT è rifiutata con
`invalid-argument / :resolver-edit-proof-unsupported` prima dell'I/O. È un
caso valido del formato ancora da implementare, senza interpretazioni
approssimative dei metadati come prova durevole.

## Memoria e lavoro limitato

| Struttura | Payload |
|---|---|
| Mappa permanente | `24 × P` byte, P = numero di PUT nel prefisso |
| Prove temporanee | `20 × O` byte, O = numero di OUTCOME, inclusi duplicati |
| Scratch radix, se O ≥ 2 | altri `20 × O + 1024` byte |
| Buffer sorgente | del caller, capacità almeno `valid-bytes` |

Il picco degli array creati è quindi `24P + 20O`, oppure
`24P + 40O + 1024` per O ≥ 2. `budget-payload` lo controlla **prima** degli
array. `payload-mappa-segmento-get` riporta soltanto `24P` dopo la costruzione.
Questi valori escludono oggetti/header Lisp, FD, buffer del caller e GC;
non sono un limite dell'RSS. Il garbage collector può trattenere lo scratch
anche dopo il ritorno. Nessun oggetto Lisp viene creato per singola riga.

I default sono 256 MiB di prefisso, 1.048.576 record non-SEAL, 65.536 lotti,
65.536 record per lotto, 64 MiB per lotto e 64 MiB di payload allocato.
Sono budget di questa costruzione, configurabili entro i formati esistenti;
non restringono i limiti documentali. Il caller deve già possedere il buffer
sorgente e il controller deve contabilizzare anche i costruttori simultanei.

Ogni attraversamento è limitato dai byte disponibili; count e budget sono
controllati. Ordinamento `O(8 × (O + 256))`, risoluzione delle righe prepared
`O(P × log(O + 1))`, ricerca GET `O(log(P + 1))`, al massimo 33 passi.
La costruzione è un percorso freddo: I/O, scansione integrale e allocazioni
sono ammessi, il loro costo deve ancora essere misurato.

## Lettura, lifetime e risposta

Il controller pubblica la mappa **prima** che un reader possa osservare una
location dell'indice che la richiede. Conserva capacità e FD fino al reclaim
autorizzato EBR. La mappa non pubblica radici, non gestisce il manifest e non
chiude file. Una capacità Lisp non sostituisce l'autorizzazione EBR.

Il driver installa il cleanup GET prima di `avvia-get`. Dopo `:candidate`
acquisisce la mappa dalla directory del controller nella stessa epoca:

| API | Esito e responsabilità |
|---|---|
| `risolvi-candidato-get(context, map)` | capacità, frontiera, flag storage e offset OUTCOME/NIL |
| `sonda-cache-risolta-get(context, map)` | esiti del probe GET, senza I/O; prepared → `:proof-required` |
| `leggi-record-risolto-get(context, map)` | esiti della lettura GET, soltanto nel pool I/O |

La risoluzione verifica vista, segment-id, FD ancora aperto, offset esatto,
lunghezza e CSN del candidato, flag e posizione della prova. Un miss della
mappa per una location già pubblicata è un guasto di integrità: **non**
diventa un documento assente. Il flag LIVE dell'indice non è PREPARED.
Il resolver non modifica array, indice, cache, registri o contatori condivisi.

Per i prepared la mappa è un acceleratore derivato: il nucleo GET rilegge
l'OUTCOME dallo stesso FD, ne verifica CRC, TXID e CSN anche prima di una
cache hit. Per ogni valore restano i controlli CRC, chiave e versione del GET.
La mappa non autorizza da sola una risposta.

`copia-valore-get` produce output provvisorio; `concludi-get`, con tempo fresco
dopo copia/ultimo accesso, verifica lo snapshot e rilascia EBR prima di
autorizzare il valore. Su errore o uscita non locale si scarta il risultato.
Gli invarianti del resolver rendono il contesto FAULTED; il confine worker
deve isolare Serie/Archivio secondo la causa. Errori della sorgente propagano.
Un ordine d'API errato è rifiutato prima di assumere un nuovo cleanup.

Prima della migrazione si abbandona GET e si scartano mappa, capacità,
location e prova. Il nuovo worker ricomincia da richiesta e indice sotto una
nuova epoca. Il modulo conserva la semantica `:history-required`: non cerca
le versioni storiche e non inventa l'assenza per uno snapshot.

## Decisioni composte e qualifica

I requisiti interessati restano **progettati**: REQ-IDX-001, REQ-FOR-001/003/004,
REQ-STO-006, REQ-CCH-002, REQ-CMP-007, REQ-CON-004, REQ-AFF-002/008.
Invarianti toccati: INV-A2, INV-F2, INV-S7 e protezione EBR del reclaim.

| ID | Decisione composta | Copertura richiesta |
|---|---|---|
| RSG-D01 | configurazione: byte, count, batch e payload | ogni limite/zero, prima degli effetti |
| RSG-D02 | capacità sorgente: budget byte oppure buffer | ognuna insufficiente, entrambe sufficienti |
| RSG-D03 | risultato lotto: progresso, fine, stamp, frontiera | ogni risultato impossibile separato |
| RSG-D04 | compaction: fine/versione/count/budget | ogni discordanza separata |
| RSG-D05 | copia prova: fine/tipo/flag/key/value | ogni discordanza separata |
| RSG-D06 | radix: source/target/alias/istogramma | ogni violazione prima della distribuzione |
| RSG-D07 | ordine TXID: high crescente oppure high uguale e low crescente | confini u32 e inversioni |
| RSG-D08 | duplicato TXID e uguaglianza CSN high/low | entrambe le word divergenti, duplicati identici |
| RSG-D09 | prima prova: indice presente e TXID high/low | miss ai bordi e high/low diversi |
| RSG-D10 | binary TXID: high minore oppure uguale e low minore | entrambe le direzioni, duplicati |
| RSG-D11 | riga: progresso e capacità residua | ciascun confine |
| RSG-D12 | candidato: size, word riservata, CSN low/high | ogni word discordante, u64 alto |
| RSG-D13 | flag: u8 e maschera PUT | word eccedente e bit non ammessi |
| RSG-D14 | identità segmento: high zero e low uguale | high nonzero e segmento diverso |
| RSG-D15 | lifetime FD: readonly e open | modo errato e chiusura anticipata |

Restano da verificare anche i rami semplici: segmento vuoto, tombstone,
frontiera nel mezzo di un lotto, tail oltre la frontiera, prepared abortito,
OUTCOME antecedente, duplicati discordi, saturazione, interruzione della
costruzione, cleanup/reentry/migrazione e corruzione di sorgente/mappa.
I controlli di API/EBR/copia del nucleo GET restano nel suo contratto.

La [campagna conservata](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-resolver/README.md)
contiene compilazione, controlli statici e due letture locali dell'autore.
Non aggiunge né esegue localmente test, modelli, fault injection o benchmark.
Allocazioni reali del GET, latenza, costo di costruzione e concorrenza restano
da misurare; revisione indipendente e qualifica C1 non sono dichiarate concluse.

La [suite funzionale dedicata alle prove OUTCOME](get-resolver-verifica.md)
aggiunge 42 test di costruzione, ordinamento/ricerca e lettura, con file
readonly v1/v2 e oracoli wire indipendenti. Conserva il
[metodo preregistrato](get-resolver-metodo.md) e risultati attribuiti al freeze
locale. La lettura indipendente e la copertura diagnostica di questa suite
non chiudono qualifica C1 o MC/DC dell'intero componente.
