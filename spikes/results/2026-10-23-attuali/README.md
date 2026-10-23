# Campagne recenti rilevanti

La [sintesi strutturata](risultati.lisp) conserva revisione, hash dei cataloghi
originali e riferimento all'archivio esterno. Questa selezione non è una nuova
esecuzione e non cambia gli esiti delle prove.

| Campagna | Risultato e documentazione corrente |
|---|---|
| CRC32C, srotolamento e GET | [Confronto 16/32 byte](../../../docs/implementazione/crc32c-unroll32.md): mantenuto il kernel 16 byte; GET caldo da 4 KiB a 1,647 µs senza oracolo nella finestra e 9,813 µs con oracolo, sull'M4 misurato. |
| Portabilità CRC32C | [Caricamento e fallback](../../../docs/adr/0060-crc32c-caricamento-portabile.md): prove hardware e software, selezione runtime e limiti delle piattaforme qualificate. |
| Costi GET | [Originali della campagna](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-23-get-costs). |
| Pagine dell'indice | [Originali della verifica finale](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-23-index-pages-final). |
| Selezione automatica dell'indice | [Originali della verifica](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-index-auto-final). |
| Socket Unix M1 | [Qualifica e limiti](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-23-production-unix-m1/report.md). |
| Full text | [Verifica finale](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-fulltext-rows-final-check) e [copertura](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-fulltext-rows-final-coverage). |

Le misure restano specifiche della campagna e della macchina indicate negli originali.
Gli originali completi si recuperano dall'[archivio storico](../../evidence/README.md).

## Verifica della pulizia e dei pacchetti CI

La [suite CI](ci-selftest.lisp) supera 364 controlli in sette moduli; il
[comando nativo](report.lisp) conserva sorgenti stabili, stdout, stderr e uscita zero.
Il messaggio di timeout in stderr appartiene a un controllo negativo previsto.

La [ricompressione](ci-repack.lisp) dei sei pacchetti originali del run
`40010510208` passa da 2.128.803 a 2.028.608 byte, sotto il limite invariato
di 2.097.152 byte. Le copie raw sono verificate per hash. Sono conservati il
[sorgente C4 del confronto](ci-repack-source.txt) e il suo SHA-256 nel risultato.
È un confronto di impacchettamento: non riesegue i test del vecchio run e non
attesta una nuova esecuzione GitHub. Per ripeterlo, scaricare gli asset del run
in `spikes/out/evidence-cleanup/ci-input/` ed eseguire il sorgente dalla root
con SBCL, usando una nuova directory di output.
