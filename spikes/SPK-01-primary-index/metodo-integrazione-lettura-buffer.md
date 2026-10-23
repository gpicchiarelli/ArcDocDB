# SPK-01 — integrazione della lettura in buffer

> **Proposta** — Registrato prima della verifica integrata e delle misure.
> Esperimento Common Lisp/SBCL di Fase 0: layout ADR-0043 v1, quattro parole
> oppure cinque con CSN finale. Non qualifica v2 o il motore di produzione.

## Domanda

Il trasporto dei quattro risultati u64 in un buffer privato del chiamante
riduce le allocazioni osservate conservando seqlock, barriere, ricontrollo della
root e tutti i risultati delle letture? Si confrontano direttamente i due
percorsi, anche oltre `most-positive-fixnum`, senza cambiare il kernel originale.

## Metodo e ordine

Il baseline precedente alla modifica del launcher usa `--profile SPK-01`:
chiave fissa, un milione di letture; key generation e hash sono controlli
separati. Il metodo del profilo è già registrato nel README dello spike.

Il nuovo launcher valida la CLI prima delle prove, compila ogni modulo con
avvisi promossi a errori e richiede CHECK originale e CHECK buffer completi.
Il CHECK buffer diventa parte di `make check`; il benchmark è esplicito:

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/run-spikes.lisp --check SPK-01
sbcl --noinform --no-userinit --no-sysinit --script tools/run-spikes.lisp --bench SPK-01 -- --variant buffer
```

Il metodo del [kernel](metodo-lettura-buffer.md), delle
[prove](metodo-check-lettura-buffer.md) e della
[matrice](metodo-bench-lettura-buffer.md) precede i rispettivi esperimenti.
Le misure sono seriali; la preparazione e il warmup sono esclusi. Carico
esterno non controllato: ogni valore resta una misura locale. Non si assume
allocazione zero, né si attribuisce un miglioramento universale al compilatore.
Il confronto riguarda la variante completa: buffer, intermedi tipizzati ed
espansione del sondaggio con `speed 3`; il core conserva `speed 2`. Non isola
il solo effetto del cambio di API. Entrambi mantengono `safety 3`.

Si registrano anche rifiuti CLI (variante ignota, opzione duplicata, opzioni
di matrice estranea) e rifiuto del benchmark con zero operazioni. Un rifiuto
atteso è un controllo negativo, distinto da CHECK riuscito. Le compilazioni,
le ispezioni del codice generato, tutti gli errori e i tentativi successivi
restano conservati; un tentativo fallito non viene sovrascritto.

## Registrazione e limiti

L'harness registra comando, ambiente, hash dei sorgenti prima/dopo, stdout e
stderr originali e risultato decodificato. I registri degli agenti aggiungono
i sorgenti integrali dei driver locali. I report pubblicati sono dati portabili
con `:schema-version 1`, letti con `*read-eval*=nil`. Il catalogo conserva
separatamente diagnosi, controlli negativi, campagna e verifica integrata.

Riferimenti: REQ-VAL-001, REQ-AFF-012, REQ-IDX-001, REQ-IDX-007, REQ-BEN-001.
Nessun requisito cambia stato sulla base dello spike. Nessun nuovo lock o
stato condiviso fra Serie: il solo writer dell'indice serializza gli
aggiornamenti; ogni reader possiede il proprio output. Non sono provati
memoria debole su entrambe le CPU, MVCC, persistenza, P99 o scala oltre cache.

## Revisione preregistrata dopo la prima matrice

La campagna `4000484172` completa 80 campioni ma osserva circa 47,6 B/op
anche nel buffer. Il kernel chiama `intero-limitato`, che costruisce il tipo
`(integer minimo massimo)` a ogni chiamata. Ipotesi da isolare con un driver
Common Lisp registrato: il confronto di un milione di controlli dinamici e
statici, con valori 1..8, medesimi risultati e rifiuti sui confini, attribuisce
il residuo alla costruzione della lista. Preparazione e report sono esclusi.
Non si assume una misura esatta degli header o del garbage collector.

Revisione del solo kernel buffer: usare `typep` con il tipo letterale
`(integer 1 8)` e segnalare lo stesso `type-error`, senza chiamare il
validatore generico. Il core rimane il baseline; seqlock, barriere e root
restano identici. Si ricompila strict, ripete CHECK completo e la stessa
matrice seriale senza cambiare i parametri. La prima campagna resta pubblicata.
Budget della diagnostica: 1.000.000 controlli per metodo, heap 1 GiB,
warmup separato di 10.000; nessun esito parziale. La nuova matrice conserva
i propri limiti finiti del metodo. La revisione è accettata solo dopo le
prove funzionali e la registrazione di tutti gli 80 campioni.
La diagnostica finale ricompila core/kernel strict e conserva il disassemblato
integrale, verificando su ARM64 l'assenza della chiamata al validatore generico.
