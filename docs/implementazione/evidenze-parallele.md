# Verifica parallela dei cataloghi

`tools/check-evidence.lisp` è uno strumento C4 per REQ-VAL-001 e
REQ-AFF-012. Controlla struttura, presenza, dimensioni e integrità delle
evidenze compresse. La verifica dell'inventario chiuso rimane affidata a
`tools/check-command-archive.lisp`.

## Contratto e risorse

Il controllo globale delle dimensioni rimane seriale e precede la lettura
dei cataloghi. Seguono i cataloghi nell'ordine restituito da `directory`;
ciascuno mantiene l'ordine delle entry e delle chiavi `:artifact`,
`:original`, `:process-artifact`. Anche riferimenti ripetuti vengono letti
e contati ogni volta. Non si interpretano i risultati conservati.

Con `--jobs 1` si usa il percorso seriale diretto. Con `--jobs 2..4`, ogni
catalogo è verificato in un processo SBCL distinto. I risultati vengono
ridotti per indice dopo la raccolta dei processi; il primo catalogo fallito
nell'ordine seriale determina il rifiuto, indipendentemente dall'ordine
di completamento. La diagnostica originale è conservata, mentre la
condizione del parent identifica il catalogo. Nessuna ripetizione del
catalogo fallito nel parent e nessuna conversione del fallimento in successo.

I default sono quattro processi, 300 secondi per catalogo e 2048 MiB di
heap per processo. Il limite di heap vale separatamente per ogni worker:
quattro worker possono quindi usare fino a 8192 MiB di heap complessivo,
oltre al parent, agli stack e alle utility native. Il parent non legge i
record estesi. La modalità seriale è disponibile su macchine con meno RAM.
`EVIDENCE_JOBS`, `EVIDENCE_WORKER_SECONDS` ed
`EVIDENCE_DYNAMIC_SPACE_SIZE` configurano `make evidence`.

Il worker crea una sessione POSIX privata e ne pubblica il marker prima
delle utility gzip/SHA-256. Questo copre anche i gruppi distinti creati
da `run-program` su Darwin/Linux. Alla scadenza, o dopo un'uscita anomala,
il parent enumera i PID della sola sessione posseduta, li termina e
raccoglie il figlio con un ulteriore limite di cinque secondi. L'eventuale
raccolta forzata del processo `ps` ha un secondo di margine aggiuntivo;
un errore di cleanup impedisce sempre l'esito positivo. Per i nipoti si
osserva la cessazione, mentre il reap riguarda il solo figlio diretto.
L'enumerazione richiede uno snapshot `ps` concluso con exit zero, nessun
segnale o diagnostica, PID positivi e presenza del parent: può
riprovare fino a tre volte entro la stessa deadline. Uno snapshot fallito
o incompleto non dimostra mai l'assenza di processi; stdout, stderr e stato
di ogni tentativo vengono conservati accanto ai log del worker.
Si ritentano soltanto gli snapshot invalidi. Errori di avvio, I/O,
cleanup e timeout si propagano senza essere convertiti in una nuova scansione.
Anche dopo una condizione grave durante il cleanup vengono tentate le
chiusure degli altri worker; tutti i guasti confluiscono nel rifiuto finale.
Log e temporanei appartengono a una
directory esclusiva sotto `spikes/out/evidence-check-*`, conservata anche
in caso di errore. Un protocollo malformato, un segnale o un exit incoerente
non può produrre un esito positivo.

La directory delle evidenze deve restare immutata durante la verifica.
`make -j check-core` non è il modo supportato per ottenere parallelismo:
alcuni self-test introducono deliberatamente file fuori budget nello
stesso albero. Il parallelismo è interno alla sola fase di lettura dei
cataloghi, dopo il controllo globale delle dimensioni.

## Verifica

`--self-test` esercita fixture separate dai cataloghi pubblicati e fa
parte di `make evidence-selftest`. Include equivalenza seriale/parallela,
ordine dei rifiuti, conteggio dei riferimenti, limiti degli argomenti,
protocollo, concorrenza effettiva e timeout con raccolta dei figli.
Le regressioni del lettore compresso rimangono nella suite storage già
richiamata dallo stesso target. Tempi osservati e risultati della
qualificazione sono registrati separatamente; nessuno speedup è assunto.

## Risultati del 2026-10-16

Il giro completo su `33ffda01` è positivo, con sorgenti stabili: build e
test senza avvisi, lint, self-test degli strumenti, tracciabilità, link,
evidenze ed esperimenti. La suite del checker ha eseguito 46 casi e 738
asserzioni. Il successivo completamento del cleanup è verificato con due
casi permanenti aggiuntivi e 18 asserzioni, richiamando la stessa funzione
di test; i 46 casi precedenti non sono stati ripetuti in quella probe.

Dopo l'integrazione finale su `15a17713`, build/test, lint, tracciabilità
e link sono positivi. Un controllo globale delle evidenze separato è
positivo sul medesimo stato, con checker `e3df9f52`. I due comandi sono
stati eseguiti in parallelo, senza i self-test che mutano l'albero results.
Questo qualifica lo strumento C4; non chiude criteri C1 o MC/DC del motore.

Un confronto precedente, con checker `d75c465b` e base `fc487afa`, ha
restituito gli stessi 150 cataloghi, 3747 riferimenti e 44686 file
(1190618013 byte conservati): 197,929 secondi con un processo e 110,730
con quattro. È un solo campione per modalità, seriale prima del parallelo,
prima dell'ultimo completamento delle diagnostiche e del cleanup. Cache e
carico esterno non erano controllati; non è una garanzia di scalabilità.

Il [catalogo della campagna](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-evidenze-parallele/catalogo.lisp)
conserva 13 record conclusi, compresi i tentativi falliti e interrotti.
Il [riepilogo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-evidenze-parallele/tools/results-report.lisp)
ne distingue i motivi senza modificare gli originali. Le fixture, i log
dei worker, le osservazioni dei processi e i symlink intenzionalmente
invalidi sono nel [contenitore raw](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-evidenze-parallele/raw.tar.gz).
Il collector ha verificato copie, metadati dei processi e inventario chiuso.
