# Catena pool, dispatcher e Serie: risultati locali

Incremento C4 sulla base `a34cede6fbc9215908d50aa85311d5d703660040`, secondo
il [metodo preregistrato](pool-catena-metodo.md). Due nuovi test registrati
nel sistema ASDF eseguono sei scenari su thread reali. Nessun file in `src/`
è modificato; le qualifiche C1/C3 precedenti mantengono il loro ambito.

## Rilettura C4 dell'autore

Rilettura del codice e degli oracoli prima della chiusura della campagna;
non è una revisione indipendente né una nuova qualifica C1.

| Controllo | Evidenza nel codice |
|---|---|
| Owner e pubblicazione | Context, porta, tabella e link creati nel rispettivo worker; registro costruito prima dell'avvio; porte pubblicate tramite semaforo. |
| Indipendenza delle Serie | A raggiunge RUNNING o BATCH con lease; B è joined dopo 32 quantum prima di segnalare la release di A. |
| Routing e capacità | Writer atteso controllato per EQ, link ancora IDLE e link di begin EQ a quello del passo; lease positiva e token originale. |
| Payload e debito | Ogni pop verifica count/status/token, payload atteso e sentinelle dello span; ACK esplicito, poi end e verifica fase. |
| Full e room | Risultati dei cinque valori, origine recycle, count 1 o 2; full usa B, room non prende un secondo writer. |
| Ritiro e migrazione | Comando dal registro pubblico; retirement al successivo IDLE; altro owner prende A residuo; registro finale `(1 1 NIL)`. |
| Risorse della fixture | Cicli finiti; wait/join con timeout 15s; cleanup libera barriere, arresta/unisce thread prima di chiudere backend. |
| Confini del prodotto | Nessuna sostituzione di funzione o slot privato nella nuova fixture; semafori e pause con lease appartengono soltanto al test. |

Identità SHA-256 dei quattro file congelati prima del controllo completo:

| File | SHA-256 |
|---|---|
| `arcdocdb.asd` | `6af6230a08151f71826b8566f052320a005e1d67e92e52e8701c414af554de14` |
| `tests/scheduler/pool-chain-support.lisp` | `3a1cfd174c8ca8ee7bb713b026e644e45ab444aa762f0e28d95d6e502b7fbfaf` |
| `tests/scheduler/pool-chain.lisp` | `81da71e08d0e5196b01fb51666b9c123dc3c1d1b206f02076ab5a1c74d6f0c85` |
| `docs/implementazione/pool-catena-metodo.md` | `5d6677962c2dc40bcfb7425c08e9b5ed7f509d16b9722530cf74110f39e8cc97` |

## Registri ed esiti

| Processo originale | Esito | Tempo wall | Sorgenti stabili |
|---|---|---:|---:|
| [Sviluppo, tentativo 01](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-catena/processes/development/report.lisp) | OK, exit 0; due test, sei scenari | 18,677892 s | 947 |
| [Controllo completo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-catena/processes/check-core/report.lisp) | OK, exit 0; 1.607 test nominati, 2 smoke, 4 fixture lint | 300,889764 s | 947 |
| [Build integrata](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-catena/processes/integrated/report.lisp) | OK, exit 0; 1.624 test nominati e 2 smoke | 53,042596 s | 963 |

Il controllo completo registra tutte le sei righe degli scenari, 112 test
scheduler, 231 file lint/0 violazioni, 121 requisiti/65 invarianti/13 scenari
FI/52 ADR senza errori e 462 Markdown/3.139 link/0 rotti. Tutti i 10 spike
completati sono conservati con i loro file originali nel manifesto della
campagna. Verifica archivio precedente alla nuova pubblicazione: 118 cataloghi,
3.518 riferimenti, 40.972 file, 1.090.326.637 byte.

Dopo la campagna congelata è stato integrato il parent
`1bdfce485633cacc924d5e7a3b1149b0185a4fa9` (checkpoint di recovery e lettura
item CBOR), con merge `6f830dd3f2fa16fc6de8536dba33bcf4d439ca5f`.
La build integrata esegue nuovamente l'intera suite: 237 file lint/0
violazioni e 122 requisiti/65 invarianti/13 FI/52 ADR senza errori.
I due file nuovi dei test e il metodo mantengono le impronte frozen; ASDF
include anche i nuovi moduli del parent. La versione ASDF premerge è
conservata nel bundle, insieme alle altre tre copie frozen.

Compilazione stretta senza warning/style-warning in tutti i processi.
Gli stderr del controllo completo e della build integrata contengono note
del compilatore (1.186.895 e 1.219.731 byte UTF-8), conservate integralmente;
non sono presentati come stderr vuoti. Quello dello sviluppo è vuoto.
Il [manifesto](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-catena/manifesto.lisp)
e il [catalogo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-catena/catalogo.lisp)
collegano sorgenti, record originali, conservazione e campagna spike.
Le funzioni di conservazione precedentemente verificate sono riusate
invariate; la famiglia generica `writer-worker` del catalogo è dichiarata
nel manifesto e non amplia lo scope dei test.


Il primo sviluppo non stampava le sei righe descrittive dei singoli scenari.
La variante iniziale è conservata nel bundle sorgenti e il suo Git blob è
stato confrontato con il record originale (`d7ad221b3e665eca54e9d532b54f04d4e53c301c`).
La sola modifica successiva ai test è la stampa delle righe; la qualifica
completa usa la versione congelata indicata sopra. Nessun tentativo fallito
è omesso.

Il [primo controllo finale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-catena/processes/final-attempt-01/report.lisp)
è FAILED/exit 2, sorgenti STABLE, 4,720478 s: il verificatore scandisce anche
le copie Markdown sotto `spikes/out/` e segnala tre riferimenti relativi
mancanti nella copia isolata del metodo. Non è un fallimento della suite.
La sola copia locale è stata rinominata da `.md` a `.md.txt`, con identità
SHA-256 verificata prima e dopo; il bundle della pubblicazione conserva
integralmente il nome e i byte del file al momento della copia.
Il record fallito e la sua conservazione rimangono originali.

## Ambito del risultato

Nei due scenari di isolamento B completa 32 quantum (64 in totale) mentre A
mantiene la propria lease, prima senza pop e poi con debito batch pendente.
Nei quattro scenari di ritiro, i payload sono A1, B1 e A2 una sola volta,
con B e A residuo presi secondo la capacità del ring. La ready finale vuota
è soltanto un'osservazione locale; non autorizza shutdown o park globale.

Questi sono ordini sincronizzati di thread reali con backend in memoria.
Non sono una misura di speedup, un'esplorazione esaustiva di interleaving,
una prova universale su memoria debole o una misura di allocazione.
Non vengono applicati payload del database né eseguiti commit/I/O durevoli.
I timeout sono budget della fixture, non target di latenza del prodotto.

## Chiusura e integrazione della suite recovery

La [pubblicazione](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-catena/processes/publication/report.lisp)
è OK/STABLE/exit 0, 85,510822 s, 964 sorgenti e stderr vuoto.
Dopo la correzione della copia locale, il
[secondo controllo finale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-catena/processes/final-verification/report.lisp)
è OK/STABLE/exit 0, 200,360344 s, 964 sorgenti e stderr vuoto:
471 Markdown, 3.184 link senza rotture; 122 cataloghi, 3.561 riferimenti,
41.484 file e 1.104.173.105 byte. Questi conteggi precedono le copie di
chiusura, i nuovi collegamenti di questa sezione e l'integrazione seguente.

La [PR 15](https://github.com/gpicchiarelli/ArcDocDB/pull/15), head
`49e66e14f8cade401978b9b969a97989995bcb77`, aggiunge 27 test recovery
in un package distinto, ASDF e documentazione; nessuna modifica a `src/`,
agli strumenti o alla CI. Il merge locale
`284b1248` conserva entrambe le voci del changelog e le due suite.
Il [controllo successivo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-catena/processes/post-pr-integration/report.lisp)
è OK/STABLE/exit 0, 56,903611 s, 969 sorgenti: **1.651 test nominati e
2 smoke**, 237 file lint/0 violazioni, 122 requisiti/65 invarianti/13 FI/
52 ADR senza errori, 473 Markdown/3.191 link/0 rotti. Compilazione stretta
senza avvisi; stderr di note conservato integralmente (1.248.665 byte UTF-8).
I file nuovi della catena e il metodo rimangono identici al congelamento;
ASDF e changelog finali sono conservati nel bundle di chiusura.

Il [manifesto di chiusura](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-catena/chiusura-01.lisp)
aggiunge i tre registri originali senza riscrivere quelli precedenti,
conserva stati, descriptor/payload e sorgenti finali. Non trasforma la
qualifica locale di questa catena in qualifica dell'intero motore.
