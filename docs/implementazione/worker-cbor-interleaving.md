# Rendezvous dei worker nelle fixture concorrenti

Metodo preregistrato prima della verifica della correzione. Il tentativo
locale completo R1 della campagna [lifetime GET](get-lifetime.md) è fallito
sull'overlap dei worker float; la CI della PR 13, run `38634044870`, è
fallita su macOS sull'overlap dei worker tag. Ubuntu è riuscito. Le prove
originali e gli esiti falliti restano distinti e conservati.

Il rilascio simultaneo di due crediti del semaforo non impone allo
scheduler di avviare entrambi i corpi prima che uno termini. Un intervallo
non sovrapposto può quindi fallire il test dopo risultati corretti.
La prima correzione riguarda soltanto le fixture float/tag, senza cambiare
encoder, formati, conteggi di elementi, oracoli o API di prodotto.

## Ordine controllato

Ogni worker riusato registra il tempo reale iniziale, codifica il primo
elemento e verifica risultato, immagine completa e contributo al sink.
Registra poi il tempo del primo checkpoint, segnala `ready` e attende
`go`. Il controller attende entrambi i checkpoint prima di consentire le
rimanenti operazioni. Ogni onda mantiene semafori distinti; attese e join
restano limitati e il cleanup libera le gate prima di arrestare i worker.

Nessun worker può terminare il proprio corpo prima che l'altro abbia
completato il primo elemento. Si verificano `start <= first <= finish`,
`max(first) <= min(finish)`, durata positiva e overlap positivo. I tempi
sono osservati, senza arrotondamenti, clamp o timestamp sintetici. Prima
delle asserzioni temporali vengono stampati e scaricati gli intervalli,
i checkpoint, i sink e l'overlap, così anche un nuovo fallimento conserva
la diagnosi. Gli oracoli sui valori e sull'immutabilità restano invariati.

La metrica è l'intervallo wall della **fixture** e comprende il rendezvous
e i controlli. Dimostra l'interleaving imposto dei compiti; non misura
latency del solo encoder, simultaneità CPU o scaling. I due helper della
prima correzione hanno un solo chiamante ciascuno nei test e non sono
usati dai benchmark.

## Verifica

Prima delle campagne viene congelato un nuovo commit di sorgenti e
metodo. Una revisione indipendente verifica posizione del checkpoint,
conteggi e cleanup. `make check` ricompila senza warning ed esegue tutte
le suite, compresi i quattro casi lifetime v1/v2 invariati; la CI completa
verifica poi Linux e macOS. Output originali, errori, configurazioni e
cache private sono conservati; i dati sono letti con READ-EVAL NIL ed EOF,
mai caricati come codice. Nessuna promozione di qualifica C1 o prestazionale.

Requisiti: REQ-CBR-004, REQ-CBR-007, REQ-CON-005, REQ-AFF-004,
REQ-AFF-008 e REQ-VAL-001.

## Estensione preregistrata dopo il controllo su main

La PR 13 è stata integrata nel commit
`05a1c1f1688968c7c64b483a14528945a05b1335`, con la stessa tree del
checkout CI riuscito. Il successivo run main `38640790953` è riuscito
su Ubuntu e documentazione ma è fallito su macOS nell'overlap della
seconda onda ARRAY write. La prima onda stampa un overlap positivo;
il log della seconda precede ancora la correzione e non contiene gli
intervalli falliti. I due intervalli FLOAT corretti risultano positivi.
Il fallimento è conservato e non viene attribuito a un carico esterno.

Due letture indipendenti individuano lo stesso gate naturale in undici
fixture residue: ARRAY, MAP, SIMPLE e STRING write; header write/read;
header minimo; scansione minima/strutturale; UTF-8; calcolo della fixture
di due Serie. Questa estensione riguarda quei test, senza cambiare
prodotto, requisiti, nomi registrati o le fixture FLOAT/TAG già corrette.

Il checkpoint segue una prima operazione reale con i controlli e il sink
previsti, oppure il primo giro completo del piano. Header write completa
i sette header del piano e verifica immagine e cursore prima della gate.
Il test due Serie conserva separatamente il progresso di B mentre A
mantiene guardia e gettone: il rendezvous del calcolo segue il rilascio
di entrambe le lease e la prima CRC confrontata con il risultato freddo.
Nessuna gate trattiene una risorsa necessaria all'altro worker.

I conteggi restano invariati: 8.192 composizioni ARRAY/MAP ciascuno;
32.768 item SIMPLE/STRING ciascuno; 229.376 header write; 2.097.152 header
read; 524.288 header minimi; 48 scansioni minime e 48 strutturali;
128 chiamate UTF-8 per 83.886.080 byte; 64 CRC per ciascuna delle due
Serie. Nessuna chiamata aggiuntiva dell'operazione misurata. Gli oracoli
finali, gli input readonly, gli scratch privati e il cleanup limitato
restano attivi. Le onde riusate conservano semafori distinti.

Si mantengono overlap strettamente positivo, durata positiva, ordine dei
checkpoint e diagnostica scaricata prima delle asserzioni temporali.
Anche le etichette storiche CPU diventano WALL della fixture: includono
attese e controlli, senza una misura del tempo puro dell'operazione.

Tre autori lavorano su file esclusivi e si scambiano la revisione delle
modifiche. Si congela un nuovo commit prima di una sola verifica completa
con cache ASDF privata nuova. Conteggi e nomi sono derivati dal Git di
quel commit e dei checkout CI reali; il totale attuale è 1.528 test in
33 suite più due smoke. I tentativi originali, le configurazioni, i
registri e le cache vengono conservati prima della pulizia.
