# Prova verticale con arresto del processo

> **Proposta** — Campagna C4 di integrazione, preregistrata il 2026-10-15.

Domanda: i componenti pubblici consentono di scrivere, aggiornare e cancellare
documenti, leggerli e recuperarli in un processo nuovo dopo SIGKILL?

Una Serie, formati v1/v2, namespace temporaneo esclusivo 0700. Il writer usa
preparatore ACTIVE, WAL/CSN, controller, indice primario e GET del prodotto.
Il bootstrap e il coordinamento sono espliciti nella fixture C4: nessun server,
catalogo o Recovery Manager completo viene dichiarato implementato.

Quattro interruzioni per formato: dopo commit durevoli; dopo un frammento di
record senza SEAL; dopo preparazione del checkpoint prima della pubblicazione;
dopo pubblicazione, rotazione e nuovi commit sul secondo segmento. SIGKILL è
reale e non esegue cleanup Lisp. Un processo distinto apre CONTROL, decision
log e segmenti readonly, risolve ACTIVE, costruisce e pubblica il checkpoint,
ricostruisce l'indice dai prefissi verificati e legge i valori attesi.
Un terzo processo ripete apertura e verifica del checkpoint pubblicato.

Gli attesi sono costanti del workload: ultimo valore di A e C, assenza di B,
e, dopo rotazione, assenza di A, nuovo C e presenza di D. Non derivano da
indice, manifest o output del recovery. Un controllo negativo altera soltanto
l'atteso del verificatore: deve produrre esito non nullo. Byte e lunghezze dei
segmenti preesistenti devono restare identici dopo il recovery, coda inclusa.
Il temporaneo CONTROL non pubblicato viene conservato con un nome distinto.

Limiti: massimo 8 KiB per file, quattro segmenti, 32 record, un worker seriale,
60 secondi per processo figlio. UUID e namespace dell'Archivio sono fatti
della fixture. Il replay dell'indice e l'ordine dei passi appartengono al test;
sono limitati ai record ordinari e rifiutano prepared/OUTCOME. Le prove non
qualificano MVCC storico, concorrenza indice/radice, multiserie, compaction,
power loss, P99, throughput, GC o C1/MC/DC. Non si misurano prestazioni.

Esecuzione prevista attraverso `tools/record-command.lisp`, anche per tentativi
falliti; controllo completo finale con `make check`. La suite fa parte di ASDF;
il driver dedicato consente di ripeterla separatamente. I registri originali
e i blob dei sorgenti vengono conservati nella campagna dei risultati.

## Estensione preregistrata: nuove scritture dopo il recovery

Il 2026-10-15, prima di modificare la fixture, si aggiunge una domanda:
la Serie recuperata può assegnare CSN successivi, scrivere nuovamente e
conservare questi effetti dopo un secondo SIGKILL?

Per ciascuno degli otto scenari precedenti, dopo il primo recovery un nuovo
processo verifica tutti i CLOSED, ricostruisce il massimo CSN da tutti i
record ordinari, tombstone inclusi, e verifica che ACTIVE sia vuoto. Chiude
le capacità dell'ispezione e crea un ambiente distinto: registro CSN,
snapshot, ambito GET e controller condividono la stessa nuova base.
Un checkpoint conserva anche l'ACTIVE vuoto e apre un segmento nuovo.
Seguono quattro commit: inserimento E, aggiornamento C, cancellazione A,
cancellazione E. Ogni effetto è letto subito; poi il processo subisce SIGKILL.
Due ulteriori processi eseguono recovery e verifica indipendente.

Gli attesi restano costanti: massimo e numero di record 9 oppure 12 dopo
rotazione; A/B/E assenti, C aggiornato, D presente solo dopo rotazione.
L'ultimo CSN è una tombstone, non una chiave viva. H deve coincidere con
l'ultimo CSN dopo ogni commit risolto. Tutti i byte preesistenti restano
immutati, inclusa la coda senza SEAL. Un negativo reinizializza intenzionalmente
il registro a zero: l'oracolo tipizzato deve intercettare il CSN riusato
prima di appendere dati, con uscita 1 e ACTIVE ancora di soli 64 byte.

Il budget dei nomi sale da quattro a otto ID; gli altri limiti restano.
La suite completa prevede 18 workload, 71 processi, 26 SIGKILL intenzionali
e due errori attesi. Nessuna misura di prestazione. È ancora una fixture C4
seriale, con una sola Serie, soli record ordinari e decision log vuoto;
non è un'API di recovery o un gate generale di ammissione dell'Archivio.

## Collegamento alla proposta ID di prodotto

Il 2026-10-15 la fixture sostituisce la ricerca del primo ID libero con
`scegli-id-segmento-recovery`: manifest autorevole e inventario completo
dei nomi `.tmp`/`.seg` nel suo namespace di otto ID. Verifica lo stato
`:ready`, il successore e il proprio budget; non applica le azioni del piano.
La prova resta C4, con gli stessi 18 workload e gli stessi oracoli costanti.
Il contratto e la verifica C1 della proposta ID sono separati dalla fixture.

## Collegamento preregistrato alle aperture relative e all'EOF

Il 2026-10-16, prima delle esecuzioni, si collega `input` alla nuova API
`io:apri-lettura-nella-directory`. Ogni capacità readonly viene aperta
rispetto al FD della directory già posseduta dalla fixture, con budget
di trasferimento e dimensione pari a 8 KiB. L'API restituisce la capacità
posseduta e l'EOF rilevato sullo stesso FD; la fixture registra subito la
capacità per la chiusura e conserva i due valori.

Le letture canoniche di CONTROL, decision log e vecchio ACTIVE ricevono
questo EOF e uno scratch della stessa dimensione. Non ricavano più la
dimensione da un'immagine aperta separatamente tramite pathname.
`file-image` resta indipendente per i confronti dei byte preesistenti e
le altre operazioni C4. In questa estensione preparazione e output, selezione
tramite probe fra il nome temporaneo e definitivo e orchestrazione restano della fixture.
L'inventario e la proposta ID usano il prodotto, come descritto sotto;
il limite di otto ID proposti resta un budget distinto C4.

Restano identici i 16 scenari positivi e i due negativi, i 71 processi,
i 26 SIGKILL intenzionali, gli attesi costanti e gli oracoli sui byte.
Questa estensione esercita apertura relativa ed EOF di prodotto; non
introduce un bundle di capacità, riconciliazione fisica o un coordinatore
di recovery. Il contratto e la verifica dell'API I/O restano distinti
dalle prove C4 della composizione.

## Collegamento alla directory posseduta — 2026-10-16

La fixture adotta nomi canonici di sedici cifre esadecimali minuscole,
seguiti da `.seg`/`.seg.tmp`. La scelta ID usa ora direttamente
`scegli-id-segmento-recovery-directory` sul parent posseduto, con una sola
enumerazione fino a EOF, senza costruire un inventario C4 cercando otto ID.
Limiti espliciti: 16 nomi segmento, otto segmenti vivi, 64 nomi complessivi,
8.192 byte complessivi dei nomi e 255 byte per nome. Il limite di otto ID
proposti resta un controllo distinto della fixture. Gli scenari, i processi,
i crash e gli oracoli restano quelli preregistrati; nessuna azione del piano
è eseguita. La raccolta reale controlla anche gli altri nomi dei processi,
ignorati dal parser storage ma inclusi nei budget.

## Verifica della composizione delle due integrazioni

Prima della nuova esecuzione, root e revisore distinto leggono la
composizione con `main` a `110e79f1`: apertura/EOF e raccolta dei nomi
usano lo stesso parent posseduto, con nomi canonici e budget indipendenti.
Il codice I/O resta identico a S1; cambia la composizione della fixture.
Si congela il merge e si esegue `make test lint trace links` con cache
ASDF nuova. Il record originale resta distinto dal full S1 e dalla CI;
non si promuove questo controllo a un nuovo full `make check`.

## Creazione relativa dei temporanei — 2026-10-17

Prima delle esecuzioni, `output` viene collegato a
`io:crea-temporaneo-nella-directory`: riceve il parent già posseduto dalla
fixture e la sola foglia `.tmp`, con gli stessi budget di 8 KiB. La capacità
append restituita viene subito registrata per il cleanup. CONTROL, decision
log e nuovi segmenti usano così la creazione esclusiva relativa di prodotto;
la fixture continua a scegliere i nomi e l'ordine della preparazione.

Il [contratto](../../docs/implementazione/io-creazione-relativa.md) e il
[metodo I/O preregistrato](../../docs/implementazione/io-creazione-relativa-metodo.md)
distinguono le prove native dai guasti iniettati e restano separati da questa
composizione C4. Non cambiano i 16 scenari positivi, i due negativi, i 71
processi, i 26 SIGKILL intenzionali e gli oracoli costanti. Non si aggiunge
riconciliazione fisica o ammissione generale dell'Archivio: un errore dopo
la creazione può lasciare un `.tmp` orfano e non implica rimozione o flush.

## Conservazione del parent ed esito strutturato — 2026-10-22

Il parent raccoglie stdout e stderr in un solo punto del cleanup di ciascun
figlio, anche dopo timeout, errore di avvio o errore del processo. Dopo la
deadline di 60 secondi tenta SIGKILL e attende fino a cinque secondi per il
cleanup; acquisisce stato e codice osservati prima di chiudere l'handle.
Le due letture e le due emissioni sono tentate indipendentemente: il primo
errore resta la causa del fallimento, senza saltare l'altro canale. Ogni
canale viene emesso una sola volta nello stdout del parent, seguito da flush,
prima degli assert sugli oracoli e prima della rimozione della root.

La root viene cancellata soltanto al completamento riuscito dello scenario.
Qualunque fallimento, inclusi lettura o emissione dei log, conserva la root
e ne indica il percorso nello stderr con `VERTICAL-ROOT-RETAINED`. I file
originali restano quindi disponibili anche se lo stdout del parent non è
scrivibile. Un SIGKILL di cleanup dopo timeout non diventa un crash riuscito:
l'errore originale viene rilanciato e il run non emette una sintesi di successo.

Ogni `run` possiede una lista di eventi tramite binding dinamico nuovo;
la dichiarazione speciale non contiene un valore globale condiviso. Gli ID
di scenario e processo sono ordinali locali al run. Un evento di processo
registra scenario, formato, fase, modo, stato/codice osservati ed esito degli
assert. Lo scenario registra il proprio completamento dopo il cleanup riuscito.
Gli eventi restano nell'ordine deterministico della sequenza preregistrata.
I quattro casi restano invocabili direttamente dal catalogo CI: ciascun caso
crea un contesto temporaneo se non esiste quello dinamico di `run`, e lo
rilascia al ritorno. Questi ingressi non accumulano eventi fra chiamate e non
emettono la sintesi aggregata, che appartiene all'ingresso completo `run`
(driver dedicato `tools/vertical-crash.lisp --self-test`).

Soltanto alla fine di un run riuscito il parent emette una singola forma Lisp
leggibile, su una riga, con questa struttura (gli elenchi sono qui abbreviati):

```lisp
(:VERTICAL-SUMMARY :SCHEMA-VERSION 1 :RESULT :PASS
 :COUNTS (:SCENARIOS 18 :POSITIVE-SCENARIOS 16 :PROCESSES 71 :CRASHES 26 :NEGATIVES 2)
 :SCENARIOS (...) :PROCESSES (...) :CRASHES (...) :NEGATIVES (...))
```

`:SCENARIOS` e `:PROCESSES` contengono gli eventi; `:CRASHES` e `:NEGATIVES`
contengono gli ID dei processi corrispondenti. I conteggi vengono ricavati
dagli eventi registrati e confrontati con 18 scenari (16 positivi e due
negativi), 71 processi, 26 terminazioni osservate per SIGKILL e due uscite 1
dei modi negativi, dopo la verifica dei marcatori tipizzati già previsti.
Qualunque scostamento impedisce la sintesi `:PASS`. La forma non contiene
root casuali, PID, durate o log dei figli; il testo diagnostico originale
mantiene i propri dati variabili e non viene duplicato nella sintesi.

Il congelamento riguarda soltanto il parent e questo metodo: nessuna nuova
esecuzione è dichiarata. Restano invariati workload v1/v2, attesi e copertura
C4. La conservazione è diagnostica del processo parent e dei file temporanei;
non prova resistenza a power loss, arresto del parent o guasti del filesystem.
Se SIGKILL o l'attesa di cleanup falliscono, la root conservata non certifica
che il figlio sia terminato. Restano i limiti C4 di una Serie seriale, record
ordinari e decision log vuoto: questa modifica non qualifica startup, recovery
o ammissione generale di produzione, né il percorso server Unix PUT/GET.
