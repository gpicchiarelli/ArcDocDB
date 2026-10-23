# Verifiche della scrittura delle testate CBOR

Campagne del 2026-10-11 sul contratto preregistrato nel
[metodo](cbor-scrittura-metodo.md), con prodotto congelato al blob
`61f0d6e2783e4790ed7e19a45bba6407d6e5b3de`. La funzione scrive soltanto
testate MT0..6 minime, fino a nove byte; payload e profilo del documento
completo restano fuori da questo incremento.

## Correttezza e parallelismo

17 nuovi test, compreso il round-trip supplementare di 77 coppie, portano
la build a 475 test e 2 smoke: 477 esiti riusciti, senza avvisi. Il corpus
cieco conserva i tre blob iniziali `92327e4…`, `903a213…`, `878f0fa…`.
Sono verificati 458.752 argomenti u16 × 7 major, 4.096 casi differenziali
seed57524342 e 140 capacità insufficienti, con intera destinazione
invariata nei rifiuti. Il fuzz esercita le cinque larghezze in
560/465/511/512/2048 casi rispettivamente.

Due worker reali con destinazioni esclusive eseguono 229.376 testate e
verificano i sink 15.466.496/17.006.592. Nella build preliminare gli
intervalli di lavoro si sovrappongono per 6140 tick a 1.000.000 tick/s;
nel controllo completo per 6134. Questa osservazione verifica concorrenza
funzionale; non dimostra simultaneità sui core, scaling o throughput del
pool. Semafori, join e cleanup hanno limiti espliciti.

Le [due](cbor-scrittura-revisione.md) [letture C1](cbor-scrittura-lettura.md)
non hanno rilievi statici aperti. Prima della compilazione è stato risolto
COD-13 estraendo il preflight dal wrapper pubblico. La tracciabilità
introduce REQ-CBR-001, senza attribuire la codifica al requisito di
versionamento dei file REQ-FOR-002. Un controllo iniziale di setup, prima
della creazione dei test, aveva segnalato correttamente il riferimento
mancante; trascrizione del risultato e successivo controllo verde sono
conservati, distinguendoli dai processi registrati.

## Heap, mutazioni e copertura

Sette fixture × cinque repliche × 4096 chiamate, warmup 128: 35 campioni con
heap osservato zero. Il sensore verifica baseline nulla e controllo
positivo 16 × 1 MiB; NEXT e tutti i byte, comprese le sentinelle, alimentano
token e sink verificati. Il costo dei controlli dell'output è incluso.
L'audit indipendente ricalcola codifiche, token e sink: questi risultati
locali non sono una prova assoluta di non allocazione o una soglia di
velocità. Le misure sono seriali, separate dalle campagne parallele.

Otto mutazioni: 8 DETECTED, 0 INVALID, 0 SURVIVED, 0 WORKER-ERROR, con baseline
completa riuscita e copie/cache private. Smoke e completamento sono
riconosciuti solo su righe esatte; compilazione fallita, segnali OS e
guasti dopo completamento non contano come rilevamento. Self-test con
processi reali ed errori di infrastruttura verificano queste distinzioni.
La capacità sul suffisso fisico produce una condizione interna diversa
da quella prevista: la guardia attiva impedisce comunque lo sconfinamento.

Copertura del solo `src/codec/cbor-write.lisp`: 224/258 espressioni e 43/52
rami; 34 espressioni e 9 rami mancanti restano nel denominatore. La mappa
indipendente distingue 6 dichiarazioni e 28 forme di errore interno;
i 9 rami mancanti sono guardie interne, senza casi non classificati. Stato
grezzo completo e due HTML conservati. Le guardie interne non raggiunte
dall'API valida e le dichiarazioni restano visibili; l'[inventario](cbor-scrittura-decisioni.md)
documenta anche la condizione ridondante nel dominio u32. Nessuna
attestazione di 100% o MC/DC, nessuna chiusura del gate C1 di ADR-0035.

Il terzo self-test dell'auditor aveva riportato OK emettendo un avviso
per una forma SETF errata nella nuova mappa dei gap: sorgente e log sono
conservati, la forma è stata corretta e i self-test ripetuti senza avvisi.
Il primo audit finale ha poi rifiutato i conteggi del report sorgente
per un proprio errore di parsing: SB-COVER lascia implicita la chiusura
della riga d'intestazione HTML. Il parser è stato corretto e verificato
anche sulla stessa forma HTML. I report originali restano invariati;
processo fallito, versioni del tool e tentativi successivi sono conservati.
Il quinto self-test passa senza avvisi: 30 fixture, 1561 controlli.
L'audit finale riuscito esegue 11.069 controlli su misure, coverage e
180 file dichiarati per copia delle mutazioni; non carica il prodotto per
calcolare gli expected. Conferma baseline e otto sostituzioni esatte.
Una lettura C4 aggiuntiva conserva due limiti del verificatore: il catalogo
dei fingerprint non è confrontato con l'intero inventario del progetto,
e il controllo automatico dei log non impone ordine/package del rifiuto.
La lettura dei log reali mostra in tutti gli otto casi un assert della
suite CBOR.WRITE.TESTS dopo lo smoke. La presenza di file ulteriori nelle
copie non è esclusa da questo audit; le copie integrali restano nel backup.

## Integrazione e conservazione

`make check` completo passa: build, lint e suoi self-test, tracciabilità,
link, conservazione delle evidenze e dieci spike. Il processo dura
135,727259 secondi, con sorgenti stabili; queste prove non qualificano il
motore o la piattaforma di riferimento. I controlli finali di link ed
evidenze verificano anche la documentazione e gli archivi aggiunti.

Dopo l'integrazione di `f16e978` (ricostruzione dell'indice pubblicata
separatamente), il controllo completo viene ripetuto su `7a8349c`:
594 test e 2 smoke, 596 esiti di build riusciti, senza avvisi; anche gli
altri controlli e dieci spike passano in 154,41837 secondi, sorgenti stabili.
Il self-test del driver di copertura unificato passa. Il solo conflitto
di integrazione riguardava elenco/uso degli scope nel driver C4, risolto
conservando sia `cbor-write` sia `index`. Prodotto e tre test ciechi
conservano gli stessi blob; le campagne locali non sono state riscritte.

Il merge `b4ea74f` include poi gli snapshot di `f23b33c` e i worker di
`d9aeae3`: controllo completo riuscito in 163,081183 secondi, con 660 test
e 2 smoke, sorgenti stabili. L'elenco degli scope conserva anche `mvcc`.
La successiva integrazione della cache `01dd641` su `997a85b` ripete tutti
i controlli in 166,766875 secondi: stessi 662 esiti di build, nessun avviso,
self-test del mutatore snapshot e dieci spike riusciti. Il driver di
copertura unificato passa il suo self-test. Il codec e i test ciechi
restano invariati; il nuovo modulo cache viene compilato, mentre le sue
verifiche dedicate restano pendenti come dichiarato nel relativo
[incremento](cache-record.md). Nel controllo finale i due worker CBOR
conservano i sink previsti e si sovrappongono per 6175 tick; resta la stessa
limitazione sulle conclusioni di scaling.

I [registri originali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-cbor-header-write/archive-index.lisp)
conservano stdout/stderr, sorgenti, test, driver, coverage, copie mutate
del nuovo file e log, self-test e audit Common Lisp con reader-eval NIL
ed EOF. Byte e SHA256 sono verificati durante la copia e dall'auditor
dell'archivio; il catalogo controlla struttura e presenza, senza inferire
risultati o autenticità dalle dichiarazioni. Le copie integrali delle
mutazioni e i FASL sono conservati anche nel backup locale
`spikes/out/cbor-header-write-isolated-20261011/` del checkout principale.
Le copie dei Markdown congelati sono dati originali `.md.txt`, senza
riscrivere i collegamenti storici. I [registri conclusivi](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-cbor-header-write-final/archive-index.lisp)
raccolgono verifiche della raccolta, i controlli integrati e la
documentazione finale. Ogni esecuzione conserva il proprio commit e i
propri conteggi: gli incrementi successivi non cambiano le prove originali.
