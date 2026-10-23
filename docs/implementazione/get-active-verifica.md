# Verifica funzionale del GET ACTIVE ordinario

La suite dedicata aggiunge **28 test nominati**: 12 per costruzione e
preflight, quattro per la geometria della directory e 12 per lettura.
Segue il [metodo preregistrato](get-active-metodo.md). Le iterazioni sui
formati e sui confini rimangono casi interni degli stessi test.

La [prima raccolta](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-get-active/) conserva
comandi, output, compilazioni, stato grezzo e HTML di copertura, fixture
di processo e tutti i dieci spike. I suoi
[audit delle copie](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-get-active-audits/)
conservano separatamente verificatori, contratti, tentativi e risultati.
La [ripetizione integrata](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-get-active-integration/)
e i relativi
[audit delle copie](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-get-active-integration-audits/)
mantengono l'attribuzione al secondo freeze. FASL e report sono dati,
mai codice da caricare; la compressione dei file grandi è senza perdita
e conserva l'impronta del contenuto espanso.

## Risultati locali e attribuzione

Il primo freeze, `42dcad77530c09784f9d77fabb92ff4477927983`, supera
`make check` R2 senza avvisi: **1.080 test di modulo in 29 suite e due
smoke check**. I processi separati di copertura eseguono i 28 test ACTIVE
e i 42 CLOSED. I record positivi hanno exit 0, working tree iniziale
pulito e gli stessi **771 path/blob** prima e dopo, verificati contro il
commit; l'inventario esclude `spikes/results/`.

L'integrazione delle fonti GET della Serie con il main esatto
`64a5ef06987af61c36ce9818eb24ca8f0a0eb7f4` modifica il wrapper ACTIVE
per delegare al resolver della radice catturata e aggiunge 27 test di
un'altra suite. Sul freeze `e8c88a4cdc697422eb05b0c6a7f79d0ec9480e26`
il controllo completo passa senza avvisi con **1.107 test di modulo in
29 suite e due smoke check**. Le due coperture isolate ripassano 28 test
ACTIVE e 42 CLOSED. I record hanno exit 0 e **781 path/blob** stabili,
corrispondenti all'intero inventario Git del freeze, esclusi i risultati.
L'audit indipendente ricava dal Git congelato nomi, ordine e totali dei
test; verifica anche l'associazione fra comando esterno e record interno.
Questi esiti appartengono ai rispettivi freeze locali, non alla CI.

Prima della pull request si integra anche il main esatto
`061e638200f0d97fc2443c7dec38d4362ef274e1`. Le 18 nuove prove del pool
di worker portano il totale a **1.125 test di modulo in 29 suite e due
smoke check**. Una terza copia separata supera `make check` sul freeze
`ae4022fb66914c53a8f9fba69298e88ce2a35d98`, con working tree pulito,
exit 0 e **807 path/blob** stabili e corrispondenti al Git congelato.
Non compaiono WARNING o STYLE-WARNING; le NOTE del compilatore nello
stderr originale rimangono conservate. L'audit indipendente ricava
conteggi e ordine dai sorgenti, associa i record esterno/interno, verifica
i quattro errori attesi delle fixture e l'esatto inventario dei 314 FASL
del sistema e dei test, letti soltanto come byte.

La [raccolta finale](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-get-active-final/)
conserva i gruppi completi di questa verifica e i suoi due audit locali;
gli [audit delle copie](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-get-active-final-audits/)
sono separati. R1 usa un controllo di associazione della cache basato
sulla presenza della directory nell'argomento ASDF. R2 rafforza il solo
helper: legge l'argomento come dati con `read-eval` disabilitato ed EOF e
verifica esattamente i due pathname wildcard sorgente/destinazione e
l'esclusione della configurazione ereditata. Entrambi i tentativi e le
rispettive fonti sono conservati; la verifica del mapping esatto appartiene
a R2. I dieci sorgenti di copertura sono invariati rispetto a `e8c88a4`:
le misure rimangono attribuite a quel freeze, senza una nuova esecuzione.

Nota editoriale sul README originale conservato nella raccolta finale:
645.763 è il numero di **caratteri** della stringa `:stderr` del core,
corrispondente a **645.773 byte UTF-8**. L'etichetta originale «byte» è
imprecisa; gli output, le impronte e gli esiti rimangono invariati.

Le fixture ACTIVE usano file reali, header v1/v2, cornici e CRC attesi
indipendenti dagli encoder del prodotto. Le frontiere derivano da offset
letterali e dal piano del lotto; la mappa costruita non fornisce l'oracolo.
I test comprendono CSN oltre la word bassa, flag ordinari 0/4, tombstone,
budget esatti e un byte sotto, persistenza della radice e riuso del lotto.
La vista sintetica di 65.536 pagine verifica la ricerca e la convergenza,
non rappresenta altrettanti lotti nativi.

Le letture entrano da `avvia-get` con snapshot ed EBR reali. Confrontano
byte, sentinelle, i cinque esiti, cache fredda/calda e frontiera della
pagina anche dopo append. Una radice soltanto pianificata non autorizza
la lettura. Location incoerenti, CSN o dimensione errati, proprietario
estraneo e FD chiuso verificano i guasti; buffer piccolo, nuovo ingresso,
scadenza dopo copia provvisoria e uscita non locale durante pread
verificano il cleanup GET/EBR prima del cleanup esterno. Resolve e probe
non eseguono I/O.

## Copertura diagnostica isolata

SB-COVER viene azzerato dopo il caricamento e prima dei soli 28 test
ACTIVE. Stato grezzo, riepilogo e conteggi HTML sono confrontati per
ciascuna sorgente. Il profilo contiene dieci file e undici HTML, incluso
l'indice. La tabella appartiene al freeze integrato `e8c88a4`.

| File in `src/get-resolver/` | Espressioni eseguite/totali | Rami eseguiti/totali |
|---|---:|---:|
| package.lisp | 0/1 | 0/0 |
| types.lisp | 1/29 | 0/0 |
| rows.lisp | 0/167 | 0/16 |
| read.lisp | 208/265 | 27/40 |
| active-types.lisp | 12/39 | 0/4 |
| active-directory.lisp | 145/161 | 24/28 |
| active-scan.lisp | 186/247 | 19/34 |
| active-build.lisp | 244/274 | 29/36 |
| active-preflight.lisp | 130/193 | 16/26 |
| active-read.lisp | 102/115 | 7/8 |
| **Totale** | **1028/1491 (68,95%)** | **122/192 (63,54%)** |

Il primo freeze aveva 1001/1459 espressioni e 121/190 rami; i denominatori
appartengono ai rispettivi sorgenti congelati. Zero rami significa
denominatore zero, senza percentuale inventata. Il processo separato
CLOSED mantiene i **42 test** e il perimetro di sette sorgenti/otto HTML:
**1156/1416 espressioni (81,64%)** e **131/184 rami (71,20%)**, invariati
fra i due freeze. La [verifica CLOSED](get-resolver-verifica.md) descrive
il suo distinto perimetro OUTCOME.

## Tentativi conservati e limiti delle prove

Il primo `make check` R1 fallisce sulla configurazione della cache ASDF
privata, che usa stringhe wildcard anziché pathname: non si osservano
output di compilazione o riepiloghi dei test. R2 corregge soltanto
l'argomento del comando sullo stesso
freeze. Il fallimento e il suo audit separato restano conservati e non
sono promossi a esito complessivo positivo.

Le tre fixture CLI iniziali terminano con errore di uso senza creare
directory di rapporto. Il duplicato suite iniziale ha sei argomenti e
raggiunge soltanto il guard di cardinalità. La ripetizione integrata usa
quattro argomenti, `--suite active --suite active`, e verifica il messaggio
specifico del duplicato con exit 1, senza richiedere un rapporto. Le
fixture reader/snapshot conservano quattro errori di processo attesi:
SIGKILL prima del completamento ed exit 7 dopo `COMPLETE`. Non sono
fallimenti del prodotto; l'audit verifica record e output grezzi come dati.

Sono conservati anche i tentativi falliti degli helper. Il primo
verificatore indipendente dei report di copertura ha un errore sintattico
prima della lettura delle prove:
stdout/stderr sono disponibili, ma il suo sorgente iniziale non è stato
preservato. Questa lacuna non viene ricostruita né descritta come
provenienza completa. Gli altri tentativi corretti conservano il sorgente
precedente e gli output. L'audit delle copie iniziale R1 termina con exit
0 ma emette un avviso per una coda costante passata a `sort`; i contatori
console sono inoltre alterati da `nreverse`. R2 corregge il solo helper
e ripete con exit 0 senza avvisi, inventari e SHA stabili; il tentativo R1
rimane conservato.

La lettura indipendente usa `tools/evidence-storage.lisp`, `read-eval`
disabilitato e un solo dato seguito da EOF. Verifica inventari e hash in
due passaggi, senza caricare report o FASL. La copertura è diagnostica:
non dimostra MC/DC, qualifica C1 o risultati di mutazioni. Non si misurano
prestazioni, heap o RSS; i payload sono calcoli di geometria.

Questi 28 test ordinari non qualificano autonomamente la nuova API della
radice catturata, prepared/OUTCOME ACTIVE, EDIT, directory mista,
pubblicazione concorrente, indice concreto atomico, rotazione/reclaim,
multiserie o server. Restano aperti decisioni non esercitate, requisiti,
qualifica C1 e Fase 0.
