# Esiti dei processi nelle mutazioni CBOR

I runner delle testate e della struttura CBOR devono distinguere un rifiuto
del mutante da un errore del processo che esegue i test. La revisione del
2026-10-09 ha trovato due falsi rilevamenti: un'uscita non nulla dopo la riga
esatta di completamento del build era contata come mutante rilevato; il
trasporto del risultato perdeva il segnale del sistema operativo.

Il catalogo resta di 9 mutanti per le testate e 10 per la struttura. La
correzione riguarda gli strumenti di verifica e non cambia il codec.
Le campagne precedenti conservano i propri byte e stati originali.

La classificazione segue questo ordine:

1. Un segnale del sistema operativo produce `:worker-error`.
2. Un'uscita non nulla dopo il completamento esatto produce `:worker-error`.
3. Un errore di compilazione o un'esecuzione incompleta senza smoke valido
   resta una verifica non valida.
4. Un'uscita zero richiede smoke e completamento esatti per attestare
   la sopravvivenza del mutante.
5. Un normale errore runtime dopo smoke e prima del completamento attesta
   il rilevamento del mutante.

La baseline deve terminare senza segnale, con codice zero e con entrambi
i marker esatti. Baseline e mutanti conservano separatamente codice di
uscita e segnale. Gli errori di avvio e trasporto sono errori del worker.
I contatori e l'esito della campagna non trasformano questi errori in
rilevamenti. Le regole applicabili sono COD-60 e COD-61 dello
[standard di codifica](../affidabilita/standard-di-codifica.md).

## Metodo registrato prima delle esecuzioni

Per ciascun runner sono previste due fixture reali con lo stesso trasporto
usato dalla campagna: un figlio scrive smoke, svuota l'output e invia SIGKILL
al proprio PID; un altro scrive smoke e completamento, poi esce con codice 7.
Entrambi devono risultare `:worker-error`, senza rilevamento. I self-test
verificano anche le precedenze, le baseline e i marker LF/CRLF, respingendo
citazioni e testo aggiunto sulla stessa riga.

Dopo la revisione di entrambi i file, i sorgenti e l'indice Git vengono
congelati durante ogni esecuzione registrata. Si eseguono i due `--self-test`,
poi le due campagne complete e `make check-core`. Le campagne possono
procedere in parallelo in directory e copie indipendenti; ogni catalogo
viene eseguito serialmente. Si conservano registri del comando, report,
runner generati e log originali, comprese le fixture ripetute dai `--run`.
Il catalogo delle prove verifica presenza, dimensioni e integrità dei dati.
Due invocazioni con `--invalid` verificano inoltre COD-61: ciascun processo
deve fallire con codice non nullo e diagnostica del file e della regola.
I registri di questi controlli negativi conservano lo stato `:failed`.

Queste prove verificano l'affidabilità dei runner. Non ripetono benchmark o
copertura del codec e non approvano nuove condizioni C1, MC/DC o qualifiche
del motore.

## Risultati osservati

I due self-test e le due campagne complete sono riusciti con hash dei
sorgenti stabili. Le baseline completano 377 test più smoke senza segnali
o avvisi; le campagne rilevano tutti i 9 mutanti delle testate e i 10 della
struttura, con zero errori dei worker. `make check-core` completa inoltre
lint, tracciabilità, link, verifiche delle evidenze e dieci spike.

Le quattro esecuzioni delle fixture, incluse le ripetizioni nelle campagne,
conservano SIGKILL come exit 137 / signal 9 e il fallimento dopo completamento
come exit 7 / signal nil: sempre `:worker-error`, mai `:detected`.
Le fixture della struttura conservano anche i rifiuti iniettati di copia e
trasporto della baseline, con codice e segnale non osservati, log e contatore.
Entrambe le CLI rifiutano `--invalid` con exit 1 e diagnostica del file e
di COD-61; i due registri restano `:failed` come previsto dal metodo.

Il [catalogo](../../spikes/results/2026-10-09-cbor-mutation-signals/catalogo.lisp)
conserva i comandi, le letture C4, i report e i byte originali di log e runner.
Non è imposto un timeout automatico ai processi delle campagne.
