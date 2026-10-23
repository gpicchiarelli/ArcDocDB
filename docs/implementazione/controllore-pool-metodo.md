# Metodo preregistrato del controllore di calcolo

Preregistrazione del 2026-10-13, prima delle campagne del componente, sulla
base `4344d9e1f2ceb45e5fa3d5076b57d09505e69ac3`. Scope: nuovo package
`arcdocdb.scheduler`, configurazione e stato owner-only, EWMA fixed-point,
policy bounded e getter, integrazione ASDF, test, documentazione e misure
locali. Il [contratto](controllore-pool.md) fissa API, domini e limiti.

Il componente è C3: [ADR-0031](../adr/0031-software-critico-criteri-e-priorita.md)
richiede lo standard integrale, una revisione e copertura di istruzioni e
rami almeno 95%. La lettura ulteriore sui dodici punti C1 è un rafforzamento
della verifica; non cambia classe né qualifica il percorso dei dati.
REQ-THR-001 è soddisfatto soltanto nella parte di controllo; REQ-AFF-008/013
e REQ-CON-005 delimitano budget, tempo iniettato e separazione dal percorso
delle richieste. REQ-OBS-001/002 e un pool operativo restano fuori scope.

## Controlli previsti

- Configurazione default ed esplicita, limiti cores 1/65536 e maximum 2×cores,
  minimum/maximum/initial coerenti. Valori negativi, zero dove vietato,
  valori oltre budget, float, simboli, stringhe e NIL fuori contratto sono
  rifiutati prima della pubblicazione dell'istanza.
- Period 1..2^20, dwell da period a 2^20 e queue-high1..2^20: soglie esatte,
  interval mismatch e budget sbagliati sono rifiutati. Nessun default è
  presentato come risultato di calibrazione o come unità temporale implicita.
- Domini completi dei campioni; actual è minimum..maximum, compreso il
  rifiuto di zero prima dell'avvio confermato. Snapshot pubblico dei sette
  valori invariato dopo ogni input rifiutato, anche con sensori già
  inizializzati e target pending; configurazione immutabile e validazione
  completa prima delle scritture verificate in lettura del sorgente.
- Tick iniziale zero, massimo 2^40−1, duplicati, regressioni, delta sotto
  period, delta uguale a period e a 2×period. Un gap maggiore di 2×period
  resetta EWMA e permanenza; non conta tempo di cui manca l'osservazione.
  Nessun wrap; la sottrazione esatta resta entro fixnum, anche quando il
  delta negativo serve a rifiutare una regressione prima della mutazione.
- EWMA iniziale esatta e successive floor((7E+256x)/8), incluse frazioni
  perse, sequenze alternate, tutti i segnali al massimo, ritorno verso zero
  e intervalli validi diversi. L'oracolo usa aritmetica razionale nel solo
  harness per confrontare i valori interi e l'arrotondamento del prodotto.
- Soglie composte, ciascun operando decisivo nei casi di test: coda<1 e
  CPU≤300 per riduzione idle; P99≥1200 che prevale anche con coda alta;
  coda≥queue-high, CPU<700 e P99≤1000 per crescita. Input ed EWMA scalate
  non si confondono. Provare i valori appena sotto, uguali e appena sopra.
- Permanenza inclusiva dwell; primo candidato, ripetizione, cambio di
  direzione, hold intermedio, gap e pending azzerano la continuità. Dopo un
  comando serve una nuova permanenza. Nessuna azione implicita al primo
  campione se manca una permanenza già osservata.
- AIMD: +1 e floor(3×target/4), inclusi arrotondamento, saturazione al massimo
  e clamp al minimo. Ai limiti, risultato hold senza falso comando grow/shrink.
  Il target non esce mai dall'intervallo configurato.
- Actual diverso dal target: EWMA aggiornate, target identico e pending,
  anche con molti campioni o pressione invertita. Conferma successiva del
  target riparte con una nuova permanenza. Una crescita pending con P99
  degradato resta pending: la fixture deve mostrare esplicitamente questo
  limite, senza dichiarare una revoca assente.
- Getter con sette valori prima e dopo campioni, rifiuti e comandi; nessun
  accesso owner estraneo. Secondo thread reale per il rifiuto del proprietario
  su aggiornamento e getter; deadline e sincronizzazione appartengono al
  solo harness. Controllori su thread diversi non condividono stato locale.
- Tracce finite con inversione brusca di carico, oscillazioni attorno alle
  soglie, assenza prolungata di campioni e attuazione ritardata. Oracolo
  indipendente per target, esito, sensori, candidato e permanenza. Non si
  deduce stabilità di un sistema reale da tracce sintetiche.
- Invarianti verificati della rappresentazione privata: target fuori
  minimum..maximum e origine della permanenza oltre l'ultimo tick; iniezioni
  a quiescenza conservate senza riparazione. Direzione privata inattesa
  rifiutata dal helper AIMD. I domini degli slot sono protetti dai tipi e
  dalla factory, senza promettere rilevamento di ogni corruzione arbitraria.
  Diagnosi typed e rifiuti ordinari distinguibili; ogni ramo nuovo resta nel
  denominatore della copertura.

## Analisi, copertura e misura

Compilazione senza warning/style-warning, safety 3, dichiarazioni di tipi,
slot read-only dove appropriato, docstring e commenti REQ/OWNER/SHARED.
Verificare funzioni entro 60 righe, complessità contenuta, nessun ciclo o
attesa nascosti, nessuna sorgente temporale letta dal componente e nessun
aggiornamento condiviso per richiesta. La policy opera solo dentro barriere
che non cambiano dati, obblighi o lease di C1/C2.

Una prima e una seconda lettura della modifica confrontano sorgenti e
contratto; l'inventario conserva predicati scalari, decisioni composte,
precondizioni, postcondizioni ed eventuali macro/delegati. Le due letture
sono agenti automatici, non una certificazione o indipendenza umana.

La copertura include tutti i file del package, compresi package e helper,
senza attribuire al nuovo componente rami dei vecchi worker. Conservare
rapporti nativi e HTML, denominatori e identità di tutti i percorsi mancanti,
senza esclusioni implicite. Confrontare la misura con il minimo C3 del 95%
per istruzioni e rami; `sb-cover` non attesta MC/DC. Un'eventuale lacuna
resta dichiarata, non eliminata dal denominatore.

La misura locale del percorso normale esclude factory, startup e GC e
usa controllore, input, target ed oracolo preallocati. Warmup e cinque
campioni bounded conservano heap, tick grezzi e risultato osservato;
coprire aggiornamento inizializzato, hold, pending e azioni applicate dal
solo harness. Lo strumento C4 deve rilevare heap positivo e risultato errato
e indicare un clock sotto risoluzione; compilazione e self-test sono conservati.
Le misure riguardano questo calcolo, non un pool reale o i target del motore.

Il driver `tools/pool-controller-bench.lisp` fissa warmup 128 e cinque
campioni da 4096 cicli. Ogni ciclo contiene 160 update/getter del controllore
principale, con 80 input di coda alta e 80 di coda vuota, più un update/getter
pending e uno hold su due controllori privati distinti: 162 passi per ciclo.
CPU e P99 sono costanti nella trace principale; l'oracolo startup calcola
EWMA, target, candidato e origine della permanenza. I casi P99 e le soglie
restano anche nei vettori attesi dei test, senza inferire esplorazione
esaustiva della macchina a stati.

Build e test mirati precedono il controllo generale sul codice congelato.
Ogni campagna usa `tools/record-command.lisp` con argv, ambiente, output,
errori e snapshot iniziale/finale; i tentativi falliti sono conservati.
Cache e copie congelate separano i test dagli altri lavori nel repository.
Byte originali e SHA degli artefatti pubblicati sono verificati; nessun
output mancante è ricostruito come se provenisse dal processo iniziale.

I [risultati](controllore-pool-risultati.md) devono distinguere prove eseguite,
limiti e lavoro residuo. La [lettura del codice](controllore-pool-revisione.md)
rimane distinta dai record dei processi e dalle misure.
RSK-12 resta aperto su sensori, feedback reale, ritardo dell'attuatore,
stabilità e taratura. Pool vivo, park/wake, admission, retirement, shutdown,
I/O, compaction e coordinatore Archivio non sono inclusi; né i gate delle
fasi né gli stati `progettato` dei requisiti vengono chiusi dalla campagna.

## Chiusura del metodo prima della campagna congelata

I tentativi preliminari hanno richiesto checkpoint SAVE-COVERAGE dopo
ciascun caricamento per conservare anche le esecuzioni di startup, prima
che i componenti temporanei siano recuperati dal GC. Il conteggio finale
include ancora tutti i record nativi, senza esclusioni né modifiche dei
segni. Il confronto EQUALP generato è nel denominatore: due controllori
identici e differenze isolate in period, dwell, queue-high, CPU e P99
esercitano entrambi gli esiti dei suoi confronti. La suite finale ha
23 prove; le fixture da 20 prove lette nella prima revisione sono
conservate come preimmagine. I sei sorgenti di prodotto sono invariati.
