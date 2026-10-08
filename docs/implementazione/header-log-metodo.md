# Metodo di verifica degli header dei log

Ambito: encoder e verificatore in memoria degli header di `control.log` e
`multiserie.log`, layout fissato da [ADR-0052](../adr/0052-header-dei-log-di-controllo.md).
Il metodo precede le campagne. I file e il loro contenuto non sono modificati
dal codec; la versione restituita seleziona il decoder dei record successivi.

## Correttezza

Oracolo distinto: magic scritto come caratteri ASCII, packing little-endian
manuale e CRC32C bitwise dei test delle fondazioni. Confronto integrale dei
64 byte per entrambi i tipi e le versioni 1/2, con prefisso disallineato,
sentinelle esterne e identità con byte alti. Verifica senza mutare input.

Per ciascun tipo: tutti i 64 troncamenti; tutti i 512 bit alterati; tutti i byte
riservati non zero con CRC ricalcolato; tutti i 16 byte dell'identità attesa
diversi; magic errato in ciascuna metà e tipo scambiato con CRC valido; versioni
0, 3 e 65535 con CRC valido. CRC errato precede l'interpretazione della versione.
I rifiuti dell'encoder (range, identità, versione, tipo e alias) non modificano
la destinazione. Nessun errore semantico dell'header viene classificato come
coda di record.

Build rigorosa, test, lint, collegamenti e tracciabilità. Copertura strumentata
in processo/cache separati, con self-test del rilevamento del ramo mancante.
Mutazioni mirate in copie isolate: CRC, ciascuna metà del magic, identità,
ciascuna area riservata e limite di troncamento. La campagna ha un self-test
di sostituzione e classificazione; una compilazione fallita non conta come
mutante rilevato. Tutti gli esiti, compresi i fallimenti, sono conservati.

## Allocazioni e tempo

Fixture preallocate, un worker, safety 3; entrambi i tipi e versioni 1/2.
Encoder e verificatore: cinque repliche di 262.144 chiamate ciascuna, warmup
di 1.024 chiamate e GC completo prima di ogni replica. Risultato osservabile,
tempo monotono e contatore dei byte heap SBCL. Il controllo positivo alloca
1 MiB per chiamata per 16 chiamate; baseline e self-test prima della campagna.

Criteri: nessun avviso, prove riuscite, mutanti compilabili rilevati, nessuna
allocazione heap misurata sui percorsi riusciti. Il contatore non dimostra
assenza assoluta di allocazioni; tempi locali senza soglia prestazionale, carico
esterno non controllato. Sono codec seriali in memoria, senza I/O, concorrenza
o commit durevole. Nessun requisito del motore viene promosso per queste prove.

Due letture C1: formato/confini/classificazione degli errori e poi proprietà
dei buffer, limiti dei cicli, decisioni composte e integrazione. Si registrano
i rilievi e la loro risoluzione nella nota di implementazione.
