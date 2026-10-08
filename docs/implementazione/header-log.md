# Header dei log di controllo

Il modulo [log-header.lisp](../../src/storage/log-header.lisp) prepara e verifica
gli header di `control.log` e `multiserie.log` secondo
[ADR-0052](../adr/0052-header-dei-log-di-controllo.md).
Opera su buffer stabili ed esclusivi, senza I/O o stato condiviso.

## Contratto

`scrivi-header-log(buffer, start, log-kind, identity, :version)` restituisce la
fine dell'header di 64 byte. `verifica-header-log(buffer, start, end, log-kind,
identity)` restituisce fine header e versione effettiva. `log-kind` è obbligatorio:
`:control` oppure `:multiserie`; l'identità attesa è un vettore specializzato di
16 byte fornito dalla fonte autorevole. La versione scritta predefinita è 2;
sono riconosciute soltanto 1 e 2. Il buffer può contenere altri byte successivi.

Ogni preflight dell'encoder precede la prima scrittura. Destinazione e identità
non possono essere lo stesso vettore. Il verificatore non scrive né restituisce
viste dell'identità: confronta tutti i 16 byte e restituisce solo due interi.
Il lavoro è limitato dai 64 byte dell'header; niente lock o scritture tra Serie.

| Errore | Condizione |
|---|---|
| Range, tipo di log o lunghezza dell'identità del chiamante errati; alias in scrittura | `invalid-argument` |
| Header troncato, CRC, magic, riservati o identità non validi | `corruption-detected` |
| Versione ignota, dopo CRC corretto | `unsupported-format` |

Il codec non decide se aprire o mettere in `FAULTED` un Archivio/una Serie;
il proprietario tratta la condizione. Il chiamante usa la versione verificata
per i decoder dei lotti. Le API di scansione attuali partono dopo un header
già verificato: questo modulo fornisce quel controllo senza introdurre un
coordinatore di recovery o una nuova operazione durevole.

## Decisioni composte

| Decisione | Condizioni e prove indipendenti |
|---|---|
| Magic valido | metà ARCD e metà del tipo: ciascuna alterata con CRC valido; entrambe valide e tipo scambiato |
| Riservati zero | aree 10–15, 32–55 e 60–63: ogni byte alterato con CRC valido; tutte zero |
| Identità valida | confronto esatto di 16 byte: ogni byte atteso diverso; tutti uguali |

La selezione del tipo ha ramo di errore esplicito. Guardie di range, lunghezza,
versione e alias sono singole decisioni e hanno prove dedicate.

## Verifica

[Metodo registrato prima delle campagne](header-log-metodo.md) e
[catalogo delle prove](../../spikes/results/2026-10-08-header-log/catalogo.lisp).
Undici nuovi test: oracoli indipendenti per tipi/versioni, tutti i troncamenti
e bit alterati, ogni riservato e byte di identità, versione predefinita 2,
classificazione degli errori e buffer invariati. La build rigorosa e il lint
passano; le prove precedenti restano incluse.

[Otto mutazioni](../../spikes/results/2026-10-08-header-log/mutazioni.lisp)
rilevate dopo una baseline invariata riuscita: CRC, ciascuna metà del magic,
identità, limite di troncamento e ciascuna area riservata. I log completi e il
report della campagna sono [conservati come dati](../../spikes/results/2026-10-08-header-log/mutazioni-dati.lisp).
I self-test verificano contatore delle allocazioni, ramo mancante, bersaglio
assente/ambiguo e distinzione fra difetto rilevato e compilazione fallita.

La [copertura](../../spikes/results/2026-10-08-header-log/copertura-dati-finali.lisp)
riporta 218/224 forme (97,3%) e 22/22 rami del nuovo codec. Il denominatore
completo resta conservato. Cinque forme dichiarative e la forma di default
`(version 2)` risultano non eseguite per SB-COVER; il test pubblico senza
`:version` è comunque eseguito e confronta l'oracolo v2. Non si modifica la
strumentazione per incrementare il conteggio. La copertura dei rami non
equivale a qualifica MC/DC.

[Benchmark](../../spikes/results/2026-10-08-header-log/benchmark.lisp): otto
campagne (due tipi, due versioni, scrittura/verifica), cinque repliche di
262.144 chiamate; heap misurato zero in tutti i 40 campioni. Il controllo
positivo rileva le allocazioni deliberate di 16 × 1 MiB. Sono osservazioni
locali su Apple M4, SBCL 2.6.9, safety 3, buffer pronti e un worker; niente
prestazioni del database dedotte dai codec in memoria.

## Due letture C1

Prima lettura: formato, confini ed errori. Seconda: oracoli, proprietà dei
buffer, limiti e integrazione; ricontrollato il test della versione predefinita.
Nessun difetto del codec rilevato. L'audit degli strumenti ha corretto, prima
delle campagne, l'ordine di caricamento dei package del benchmark e aggiunto
la baseline invariata obbligatoria alle mutazioni.

| Punto della checklist | Riscontro |
|---|---|
| 1. Requisiti e ADR | REQ-FOR-001/002, ADR-0052, layout e API coerenti |
| 2. Invarianti | INV-F1: integrità, identità, riservati e versione verificati prima dei risultati |
| 3. Errori | Classi e ragioni esplicite; ogni rifiuto significativo ha una prova |
| 4. Limiti | Header 64 byte, CRC 56 byte, riservati 34 byte, identità 16 byte; niente attese/ricorsione |
| 5. Allocazioni | Zero heap nei 40 campioni riusciti; contatore verificato con controllo positivo |
| 6. Dati verificati | Solo fine header e versione dopo tutti i controlli; nessuna vista dell'identità |
| 7. Decisioni | Tabella sopra, condizioni isolate dai test e mutazioni mirate |
| 8. Proprietà | Buffer esclusivo/stabile del chiamante, costanti centralizzate, nessuno stato mutabile nuovo |
| 9. Tracciabilità | Matrice aggiornata, componenti ASDF di prodotto e test registrati |
| 10. Standard | Safety 3, ftype, docstring e REQ; compilazione rigorosa e lint riusciti |
| 11. Parallelismo | Nessun lock, contatore o scrittura condivisa tra Serie |
| 12. Atomicità | Preparazione in memoria, nessun I/O o cambiamento durevole |

I requisiti restano nello stato del motore. Apertura con identità autorevole,
catalogo, gestione `FAULTED`, recovery completo e criteri di rilascio restano
da integrare; queste prove riguardano il solo codec in memoria.
