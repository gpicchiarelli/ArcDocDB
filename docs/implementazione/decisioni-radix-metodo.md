# Metodo: ordinamento delle decisioni e consultazioni parallele

Registrato prima delle misure del 2026-10-09. Ambito: ordinamento in
memoria del recovery, senza I/O, applicazione dei prepared o modifica del
formato persistente. La tabella pubblica resta posseduta e immutabile.

## Candidati e criterio

Baseline: merge bottom-up stabile già verificato. Candidato: LSD radix
stabile a base 256, otto cifre per TXID u64 e sedici per ID16. Le passate
con una sola classe occupata non cambiano l'ordine e possono essere saltate.
Il workspace resta limitato ai dati effettivi più 256 contatori, senza
allocazione in proporzione ai budget inutilizzati.

Per una larghezza fissa `w`, radix richiede `O(w × (N + 256))` lavoro;
merge richiede `O(N log N)` confronti. La distribuzione stabile di ogni
cifra conserva l'ordine fisico dei TXID uguali e quindi la provenienza del
primo conflitto. Riferimento primario: [Sedgewick e Wayne, LSD](https://algs4.cs.princeton.edu/code/edu/princeton/cs/algs4/LSD.java.html).
L'adattamento usa interi **unsigned** u64, senza il riordino del segno
necessario agli interi Java del riferimento.

Nessuna adozione sulla sola complessità asintotica. Si misurano cardinalità
piccole, medie e grandi, ID16 a prefisso comune e con tutti i byte variabili
(le due metà sono correlate), TXID ordinati, inversi, dispersi, duplicati
e uniformi. Si scelgono soglie separate per ID16 e TXID. Per ogni scenario
con `N >= soglia`, mediana radix deve essere al massimo il 90% della mediana
merge. La soglia stessa deve essere una cardinalità misurata. In caso di risultati discordanti si
mantiene merge nel relativo percorso; il candidato non viene lasciato
come codice di prodotto inutilizzato.

## Correttezza e concorrenza

Oracolo indipendente a `stable-sort` nei test, confrontando tutti i byte
e l'identità delle entry, compresi i duplicati. Valori estremi u64,
cardinalità dispari e confini delle cifre; passate uniformi, input già
ordinato e inverso, ID differenti in ciascuno dei 128 bit.
Si ripetono i contratti pubblici: duplicati idempotenti o discordanti,
primo conflitto fisico, budget e ownership, senza risultati parziali.

Worker reali consultano in parallelo la stessa tabella pubblicata prima
dello start: ogni worker possiede input, output e stato d'errore. Nessuna
scrittura nella tabella, contatore globale o lock nel percorso della
query. Il test confronta gli output con un oracolo seriale e attende i
thread con timeout. Questi worker appartengono all'harness; non introducono
thread per richiesta nel motore o un nuovo pool globale.

## Misure e conservazione

Solo ordinamento nelle finestre misurate; fixture, copie da ripristinare,
compilazione, warmup e confronto con l'oracolo sono fuori dalla finestra.
Le allocazioni interne dell'algoritmo e gli eventuali GC restano inclusi.
Repliche alternate tra merge/radix, seme fisso, contatori heap e tick grezzi,
risoluzione e durata effettiva conservati. Tre repliche per algoritmo,
con iterazioni calibrate separatamente, alternano l'ordine di esecuzione.
Campioni sotto la risoluzione o più brevi del target di 50 ms, anche dopo
raggiungimento del tetto, rendono inconcludente la scelta per quel suffisso
di cardinalità: non producono rapporti utilizzabili per l'adozione.
La calibrazione ha un numero massimo di tentativi, iterazioni e byte delle
copie. Il limite di 64 MiB riguarda il payload delle copie (otto byte per
riferimento a entry); non comprende header, output, oracolo e scratch.

Self-test del driver: fixture/oracolo deterministici, algoritmo errato
rilevato e corretta classificazione del tempo nullo. Due letture, lint,
mutanti mirati, copertura grezza e `make check`; comandi, hash e tentativi
falliti vengono conservati nel catalogo. La misura locale macOS/ARM64
non qualifica prestazioni Linux/x86-64, P99, zero heap o il motore completo.

## Ripetizione per durata insufficiente

La prima matrice completa ha conservato campioni sotto il minimo di 50 ms,
anche dopo una calibrazione inizialmente sufficiente. Non autorizza una
soglia TXID; resta conservata integralmente. Prima della seconda matrice,
il target di calibrazione sale a 100 ms per lasciare margine alla variazione
fra finestre. Il minimo di ogni campione resta 50 ms e il criterio del 10%
non cambia. Si ripete l'intera matrice con lo stesso seme, senza selezionare
soltanto i casi favorevoli. Una calibrazione che raggiunge il tetto prima
dei 100 ms resta insufficiente, anche con campioni successivi più lunghi.
