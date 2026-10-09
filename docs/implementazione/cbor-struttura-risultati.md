# Risultati della scansione strutturale CBOR

Campagne locali del 9 ottobre 2026 sul kernel congelato del
[referto C1](cbor-struttura-revisione.md), con il supplemento allo stack
dichiarato separatamente. Comandi, output e tentativi sono conservati nel
[catalogo](../../spikes/results/2026-10-09-cbor-structure/catalogo.lisp).
Le letture statiche sono locali e non costituiscono approvazione umana.

| Verifica mirata | Esito osservato |
|---|---|
| Build rigorosa, lint e tracciabilità | PASS; zero avvisi, 57 file di prodotto senza violazioni, zero errori di tracciabilità. |
| Suite del nuovo scanner | 24 test nominali PASS, inclusi span da 16MiB e ultimo slot dello stack. |
| Corpus AST | 256 item generati e 256 suffix trailing errati verificati. |
| Tutti i lead su due span | 512 casi: 41 accettati e 471 rifiutati. |
| Fuzz finito | Seed `49CBA017`, 4096 span da 1..64 byte: 30 accettati, 4066 rifiutati. |
| Due worker privati | 48 scansioni, 2.359.344 nodi, 5.505.168 byte; sink 4.718.784 e 3.145.920; tutti e tre i valori e buffer integri. |
| Heap sul successo | 6 fixture ×5 repliche ×32 chiamate, warmup 128: tutti e tre i0 campioni a zero byte osservati. |
| Sensore heap | Baseline 0; controllo positivo 16×1MiB osserva 16.777.472 byte, sia nel self-test sia nella campagna. |
| Mutazioni mirate | Baseline completa PASS, 10/10 mutanti compilabili DETECTED dopo smoke esatto; zero INVALID e zero SURVIVED. |
| Copertura grezza focale | 742/956 espressioni e 144/200 esiti di ramo; nessuna esclusione dal denominatore. |

Lo stato SB-COVER completo contiene anche moduli e test fuori dallo scope;
il report focale comprende soltanto i sei file package/spazio/scan.
Le 214 espressioni non osservate sono associate a 33 forme dichiarative,
8 forme negli slot di `defstruct`, 170 forme in 42 siti di errore interno e
3 forme dei default. I 56 esiti di ramo mancanti sono associati a 10 forme
dei slot e 46 guardie interne. L'audit confronta i percorsi dello stato grezzo
con HTML e sorgenti; le precise cause strumentali per slot e default restano
non stabilite. Questa associazione non prova irraggiungibilità o copertura
completa e non concede esclusioni o una qualifica MC/DC.

L'overlap del lavoro è positivo dopo la barriera: 79.346 tick nella build
preliminare e 212.802 tick nella copertura, su clock reale da 1.000.000 tick/s.
Il dato non misura tempo CPU o esecuzione simultanea su core distinti e non
attesta scaling del pool. I worker mantengono input e scratch esclusivi;
il kernel non crea thread, usa lock, attese o I/O per operazione.

Il mutante `tag-child-consumption` cambia la partizione tag/non-tag; il suo
primo fallimento osservato riguarda il valore semplice F4 che smette di
consumare il figlio. Il log non viene presentato come kill di un vettore tag.
La baseline completa include gli oracoli specifici delle catene di tag;
la campagna di dieci mutanti rimane mirata, non esaustiva.

Le misure usano safety3, fixture e scratch preparati a freddo, tre risultati
verificati e sink indipendente. Setup, warmup, GC e report sono fuori dai
contatori. Il costo comprende i controlli del driver; il carico esterno è
incontrollato. Zero heap osservato riguarda queste chiamate riuscite, non
factory, errori o una prova assoluta di assenza di allocazione.

Il blocco verifica struttura e UTF-8, senza attestare semantica dei tag,
chiavi duplicate, rappresentazione deterministica, ammissione al writer,
durabilità o motore completo. Il controllo complessivo `make check` è PASS: 320 test ASDF, inclusi due
smoke, e tutti i 10 spike con exit 0. Snapshot prima/dopo identico e nove blob
di prodotto/test coincidenti con il freeze. Il master compresso è riletto
con verifica dei byte espansi; audit e originali sono conservati nel catalogo.
