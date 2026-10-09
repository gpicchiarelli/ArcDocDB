# WAL e CSN: risultati della campagna locale

Data: 2026-10-09. Codice integrato `9a5af37699dbf90417ff9f96204a7a79f12e1df2`;
include il ricircolo dei writer arrivato su main con `75ada9d`.
[Contratto](wal-csn.md), [metodo preregistrato](wal-csn-metodo.md),
[decisioni](wal-csn-decisioni.md), [due letture C1](wal-csn-revisione.md).
I requisiti dell'intero motore conservano lo stato progettato.

## Correttezza e controlli

La verifica integrata passa **340 test più due smoke test**, compilazione senza
warning/style-warning, lint e autoverifica, trace, link, conservazione delle
evidenze e i dieci spike di correttezza. Ripartizione: 28 fondazioni, 17 UTF-8,
17 CBOR, 20 CSN, 66 writer, 44 storage, 18 I/O, 82 recovery e 48 WAL.

Il nuovo contributo comprende due test del codec a parole, 25 test del ponte
e quattro test di fault/concorrenza. Gli oracoli includono packing bytewise e
CRC bitwise indipendenti, immagini complete dei rifiuti, confronto v1/v2 con
il formato precedente e frontiere matematiche del registro. Sono verificati
carry, massimo u64, assenza di wrap, eventi obsoleti, registro diverso con
token numericamente uguale, log sbagliato, busy/full, pubblicazione distinta
da flush, riuso prematuro, append parziale e flush guasto.

Quattro Serie reali condividono K=3 e completano **500 cicli ciascuna**.
La prima onda forza saturazione; dopo ogni ciclo il buffer viene riusato.
Tutti i 2000 CSN sono unici e consecutivi, gli effetti della fixture precedono
la risoluzione e H converge all'ultimo CSN, attraversando un carry alto.
Retry e deadline appartengono all'harness, non al prodotto.

Quattro mutanti compilabili sono rilevati dai quattro test previsti:
omissione della parola alta, riuso con token pendente, risoluzione come
pubblicato dopo fault del log, trasferimento a un altro log con lo stesso ID.
La baseline passa prima dei mutanti. Compilazione fallita, timeout o errore
fuori dal test atteso rendono la prova invalida; non vengono contati come kill.

| File misurato | Espressioni | Rami |
|---|---:|---:|
| `src/wal/csn.lisp` | 231/242, 95,5% | 40/40, 100% |
| `src/wal/builder.lisp` | 302/322, 93,8% | 38/40, 95% |
| `src/foundation/record.lisp` | 670/744, 90,1% | 75/76, 98,7% |

Rapporti HTML e stato grezzo SB-COVER sono conservati. Il 100% riguarda i
rami del ponte: non è MC/DC, copertura dell'intero WAL o qualifica del motore.

## Prestazioni del ciclo simulato

Apple M4 ARM64, 16 GiB, SBCL 2.6.9, Darwin 27.0.0; safety 3.
Un ciclo comprende un PUT con chiave da 16 byte e valore da 64 byte,
CSN e SEAL, gruppo da un lotto, append/flush simulati, pubblicazione CAS
di un descrittore preallocato, risoluzione e riuso. Totale 160 byte per ciclo.
Registro K=256; file-id u64 massimo. Gli oracoli restano attivi nel ciclo.

Due invocazioni riuscite sono conservate. Ciascuna esegue dieci finestre
seriali e nove repliche parallele. **Tutte le venti finestre seriali osservano
zero byte heap**. Il controllo vuoto osserva zero; quello positivo della
campagna finale osserva 16.777.472 byte per sedici array vivi da 1 MiB.
Tempo invalido, heap nonzero e metrica mancante sono rifiutati dall'autoverifica.
Le metriche sono verificate anche dopo salvataggio e rilettura.

Mediane della seconda invocazione, sul checkout integrato:

| Scenario | Repliche | Cicli/s |
|---|---:|---:|
| Base CSN zero | 5 | 470.799 |
| Base alta con carry al sedicesimo ciclo | 5 | 470.699 |
| Un worker, registro/log privati | 3 | 471.576 |
| Due worker, registri/log indipendenti | 3 | 923.830 |
| Quattro worker, registri/log indipendenti | 3 | 1.731.977 |

Ogni finestra esegue 20.000 cicli; le seriali finali durano almeno 42.281 tick
con timer da 1.000.000 tick/s. Busy, full e retry sono zero nel parallelo.
La contesa di un Archivio condiviso è verificata dal test separato, non da
queste misure di scalabilità fra Archivi.

L'heap parallelo è osservazionale e globale al processo, con start/join:
65.520 byte nelle tre repliche a un worker, 131.040/131.040/0 a due e
262.080 nelle tre a quattro. Le finestre dei worker si sovrappongono e non
si sommano. Questi byte non sono attribuiti al singolo ciclo o worker.
Il gate zero heap riguarda le finestre seriali di successo. Errori e contesa
possono allocare condizioni; nessuna promessa di assenza assoluta di heap.

Il backend e la pubblicazione sono fixture: nessuna misura di NVMe, durability
reale, latenza client o throughput del database. Il carico esterno non è
controllato; non è una campagna soak o una qualifica di piattaforma.

## Diagnostici conservati e correzioni C4

La prima build ha rifiutato una parentesi in eccesso nel nuovo test FI:
corretta in `3c564f5`, poi build riuscita. Il tentativo conserva fonte e diagnostico.

La prima campagna parallela di copertura ha rilevato una collisione nella cache
ASDF: la precedente mappatura della sola radice non copriva i file discendenti.
La prima baseline dei mutanti ha rilevato la directory FASL del probe mancante.
`522172d` introduce wildcard ricorsivi, verifica della destinazione e creazione
esplicita della directory. Le campagne corrette hanno cache distinte e passano.
Le prove precedenti al fix restano osservazioni storiche; l'isolamento dichiarato
dalle vecchie invocazioni dello strumento non è attestato retroattivamente.

Il primo riepilogo della raccolta ha mostrato conteggi pari a uno dopo `nreverse`,
pur avendo salvato il catalogo completo. La versione successiva conta dalla
rilettura del catalogo e aggiunge un'autoverifica 3/2. Entrambe le fonti sono
conservate. Questa correzione riguarda il riepilogo, non i risultati delle prove.

## Conservazione e prossima integrazione

Il [catalogo strutturato](../../spikes/results/2026-10-09-wal-csn/catalogo.lisp)
conserva argv, ambiente, HEAD, impronte prima/dopo, stdout/stderr grezzi,
exit code, fallimenti, autoverifiche, campioni e report di copertura.
Le fonti dei mutanti concreti e degli adattatori C4 sono conservate.
I grandi registri degli spike sono compressi senza perdita; nessun output
viene tagliato per ottenere un file piccolo. FASL e copie complete ricostruibili
dalla fonte Git e dalle sostituzioni esatte restano fuori dal repository.

Resta da collegare il controller delle Serie: validare l'evento prima della
pubblicazione, conservare l'esito sul busy, applicare fail-stop e quiescenza,
rispettare ordine e conferme. Indice, snapshot e coordinatore multiserie non
sono implementati da questo ponte.
