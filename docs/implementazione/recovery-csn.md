# Massimo CSN osservato nel recovery

Il recovery raccoglie i CSN verificati prima di inizializzare il registro
dell'Archivio, come previsto da [ADR-0020](../adr/0020-csn-snapshot-isolamento.md)
e dall'[architettura](../architettura.md#recovery). Questo incremento fornisce
le query sui risultati readonly e l'aggregazione di una Serie completa.
Non costruisce il registro e non apre il traffico.

Il [piano dell'Archivio](csn-archivio-recovery.md) aggrega ora queste query
rispetto all'elenco canonico fornito dal controller, inclusa Registri,
e verifica che ogni ACTIVE abbia usato lo stesso replay delle decisioni.
Catalogo persistente e ammissione restano da collegare.

## Contratto pubblico

Ogni query restituisce **due valori: presenza, massimo u64**.
`NIL, 0` significa nessuna fonte; `T, 0` significa CSN zero realmente osservato.
Nessuna somma o conversione in u32 tronca il massimo.

| Namespace | API | Fonte |
|---|---|---|
| `arcdocdb.recovery.active` | `massimo-csn-active-recuperato(result)` | Vecchio ACTIVE completamente verificato e risolto |
| `arcdocdb.recovery.closed` | `massimo-csn-closed-recuperato(result)` | CLOSED verificato fino al P del CONTROL e suoi esiti EDIT |
| `arcdocdb.recovery.closed` | `massimo-csn-serie-recuperata(active, closed :max-segmenti 65536)` | ACTIVE e tutti i CLOSED dello stesso CONTROL |
| `arcdocdb.recovery.archive` | `massimo-csn-decisioni-recuperate(result)` | Tutte le DECISION del prefisso verificato di `multiserie.log` |
| `arcdocdb.recovery.decisions` | `massimo-csn-decisioni(table)` | Query scalare della tabella canonica, priva da sola dell'identità di Archivio |

I risultati dei reader conservano due scalari readonly aggiuntivi. Non
trattengono scratch, nuove tabelle o callback. ACTIVE conserva inoltre un
marker privato del replay, che non trattiene la tabella. Le firme pubbliche e i
valori precedenti dei reader restano gli stessi; cambia la rappresentazione
privata dei risultati ACTIVE/CLOSED, che richiede ricaricamento del sistema.

## Che cosa contribuisce

| Fonte già verificata | Valore incluso |
|---|---|
| PUT/TOMBSTONE ordinario | `stamp`, che è il CSN |
| PUT/TOMBSTONE prepared | Nessun contributo dal suo `stamp`: è un TXID |
| SEAL di un segmento writer | CSN del lotto, anche se contiene soltanto prepared |
| OUTCOME nel segmento | CSN del payload, anche senza prepared locale |
| DECISION che risolve un prepared ACTIVE senza OUTCOME | CSN della decisione |
| Esiti EDIT del CLOSED | Tutti i CSN, anche senza prepared raggiungibile nel prefisso |
| Segmento compattato | Stamp dei soli PUT/TOMBSTONE ordinari, più gli eventuali esiti EDIT conservati |
| Tabella completa delle DECISION | Tutti i CSN, anche senza prepared nelle Serie aperte |
| Header, TXID, ID segmento, frontiere, SEAL di CONTROL/multiserie | Nessun contributo |
| Byte oltre P, coda ACTIVE non valida, coda del decision log | Nessun contributo |

Il risultato è un **massimo osservato**, non l'orizzonte di visibilità H
o un elenco di transazioni da confermare. Conservare il massimo di una
prova valida senza documento locale evita di abbassare la base quando
alcuni dati sono stati eliminati. Un esito non crea un documento; un SEAL
non rende committed un prepared privo di prova. Conflitti fra prove e
partecipanti restano errori dei reader canonici e impediscono il risultato.

## Autorità e insieme completo

L'aggregazione della Serie usa `verifica-closed-completi` prima di
consumare i massimi: cardinalità esatta, stesso token CONTROL per identità
`EQ`, ID u64 unici, appartenenza CLOSED e P esatto. Controlla anche che
ACTIVE, CONTROL e CLOSED mantengano aperte le capacità readonly.
Il budget `max-segmenti` precede la tabella privata dei duplicati.

Il controller congela fonti, vettore e namespace per l'intera operazione.
Il risultato non certifica riconciliazione fisica, nomi, inode, catalogo,
salute futura dei FD o inventario completo dell'Archivio. Le query scalari
sui singoli token descrivono la lettura già conclusa; non rileggono i file.
La query sul decision log controlla che il suo FD resti aperto.

Il coordinatore dell'Archivio deve ancora:

1. conoscere tutte le Serie canoniche, inclusa Registri;
2. recuperarle e verificare le decisioni e gli obblighi pendenti;
3. aggregare i massimi delle Serie **e del decision log completo**;
4. costruire l'unico registro CSN e il registro snapshot che lo usa;
5. completare pubblicazioni e obblighi prima dell'ammissione.

La [creazione del registro](csn.md) riceve l'**ultimo CSN**, non il prossimo.
Con base `M`, la prima assegnazione produce `M+1`; passare `M+1` alla
creazione salterebbe un valore. Se `M = 2^64-1`, il registro esistente
rifiuta ogni nuova assegnazione con `:csn-exhausted`: nessun wrap o reset.
Un sottoinsieme delle Serie non autorizza una base di Archivio.

## Costi e limiti

- Writer ACTIVE/CLOSED: aggiornamenti scalari durante l'attraversamento
  semantico esistente; nessun nuovo passaggio o I/O.
- CLOSED compattato: un passaggio aggiuntivo di `COUNT` header sullo
  scratch già verificato; non ricalcola i CRC dei body e non rilegge il file.
- EDIT: un passaggio sui suoi esiti già limitati dal budget del reader.
- DECISION: un passaggio sulle entry uniche della tabella posseduta.
- Serie: un passaggio sui CLOSED oltre al gate completo. Il gate alloca
  la tabella privata degli ID come già documentato; non è un tetto RSS.

Nessun contenitore aggiuntivo per record. Boxing degli interi u64, oggetti
Lisp e GC restano da misurare. Non ci sono modifiche ai percorsi delle
richieste o dei commit, né misure di throughput/latency in questo incremento.

## Decisioni e qualifica

Requisiti: REQ-REC-001, REQ-MVC-005/006, REQ-TXM-005/007, REQ-STO-006,
REQ-CMP-009, REQ-AFF-008. Invarianti coinvolti: INV-A2, INV-M5 e INV-P6;
il massimo non sostituisce le prove di commit né produce scritture fra Serie.

| Caso | Decisione/obbligo di verifica dedicata |
|---|---|
| CSR-D01 | Ordinario/prepared: stessi bit di stamp, solo l'ordinario contribuisce come stamp |
| CSR-D02 | Presenza distinta dal valore: vuoto, CSN zero, bit alti e massimo u64 |
| CSR-D03 | SEAL writer e OUTCOME: inclusi anche senza dati ordinari o prepared locale |
| CSR-D04 | DECISION/OUTCOME/EDIT coerenti; conflitto rifiutato prima del risultato |
| CSR-D05 | EDIT presente/assente, anche senza prepared e per compaction vuota |
| CSR-D06 | Compaction: `(PUT OR TOMBSTONE) AND NOT PREPARED`; ogni condizione, progresso e count |
| CSR-D07 | Intero prefisso e coda esclusa, v1/v2, origine writer/compaction |
| CSR-D08 | Serie completa: count, duplicati, CONTROL diverso, P diverso, FD chiuso, budget |
| CSR-D09 | DECISION senza prepared locale, duplicati identici, ordine TXID diverso dall'ordine CSN |
| CSR-D10 | Registro unico, base M, prima assegnazione M+1, esaurimento senza wrap |

Le [prime evidenze](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-recovery-csn/README.md)
separavano compilazione, controlli statici e letture dell'autore dalle prove
funzionali. Le campagne dedicate [CLOSED/Serie](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-closed-verifica/report.md)
e [piano Archivio](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-archivio-csn-verifica/report.md)
conservano test funzionali, FI, prove native, revisione e copertura grezza,
con i rispettivi confini. Restano MC/DC/C1, allocazioni/prestazioni e
integrazione del controller/registro unico; la CI non chiude questi obblighi.
