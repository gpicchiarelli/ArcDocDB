# Verifiche della composizione array CBOR

Campagne del 2026-10-13 sul [metodo preregistrato](cbor-array-metodo.md),
blob `2f257c9e8a56a5182142934dada3f3b38b5bef65`. Il corpus è congelato
prima del prodotto; entrambe le letture C1 precedono la prima compilazione.
Le versioni provate sono input `d3b3d07fc18bd2a077c1a2d79020a76263b2779e`
e writer `a410297c29c5d043ad60d3804bd3711e22c2833b`.

## Corpus e parallelismo

I venti test comprendono diciannove prove seriali e una con due worker
riusati. Vettori letterali coprono array vuoto, scalari, cinque tipi,
COUNT23/24/255/256, figli array/map/tag, testo UTF-8 e float grezzi.
Si controllano arità esatta, destinazione fisica completa, sorgente,
tabella, precedenza degli errori, alias dello scratch, overlap della
testata, confini toccanti, offset assoluti e riuso dopo errore.
Sono provati i budget esatti di 16MiB, la radice nel conteggio dei nodi,
il residuo zero prima del figlio successivo e profondità figlio99/100.
La coda ignorata della tabella non viene letta né limitata dal budget.

Il fuzz usa 1.024 casi e seed `41525235`: 512 successi e 64 rifiuti
per ciascuna delle otto classi capacità, byte, fini, nodi, profondità,
parsing, range sorgente e COUNT. Il conteggio di 9.474 chiamate della
suite deriva dai loop congelati, senza un contatore runtime separato.

Due worker reali, con buffer e scratch privati, condividono sorgente e
indice in lettura. Due ondate di 2.048 chiamate per worker danno 8.192
operazioni, con READY/GO/DONE, timeout e cleanup limitati. I sink sono
52.178.944/75.218.944 per worker in entrambe le ondate. Gli intervalli
del primo build si sovrappongono per 3.939/3.151 tick, a 1.000.000 tick/s;
questa osservazione non misura scaling o simultaneità sui core.

## Misure e mutazioni

Sei fixture congelate coprono vuoto, scalare, cinque tipi, 24 scalari,
256 scalari e array/tag/testo. Cinque campioni da 1.024 chiamate per
fixture, dopo warmup64, producono trenta campioni con heap osservato
zero. Baseline nulla e sensore positivo di 16 × 1MiB osservano
rispettivamente zero e 16.777.472 byte.

NEXT, arità fredda, array completo, sorgente, tabella, token e sink
sono verificati. Il loop caldo usa il valore primario; il corpus verifica
l'arità di ogni successo. I campioni sommano 0,336716s, il wrapper dura
1,716347s. L'auditor ricalcola le sei fixture aritmeticamente e controlla
67.470 relazioni senza caricare prodotto o driver. Non vi è una soglia
di velocità né una prova assoluta di assenza di allocazione.

Otto mutazioni compilabili verificano capacità fisica contro END,
major type, COUNT, omissione dello scanner, overlap senza testata,
tabella non verificata, radice esclusa dai nodi e valore NIL aggiuntivo.
Il catalogo semantico precede il prodotto; le sostituzioni concrete
sono materializzate successivamente su copie private. La mutazione
dell'arità aggiorna coerentemente FTYPE e dichiarazioni della sola copia.

La baseline termina con 1.101 righe OK totali, di cui venti del corpus
array. Tutti gli otto log hanno smoke prima di Unhandled, exit1 senza
segnale o warning e un frame nominale esatto del corpus: `8 DETECTED`,
nessun `SURVIVED`, `INVALID` o `WORKER-ERROR`. Le nove copie contengono
308 file ciascuna: 2.772 confronti verificano la baseline e, per ogni
mutante, 307 file invariati più la sostituzione unica prevista.
Le 313 impronte interne includono cinque helper non copiati; non sono
una chiusura transitiva completa. La riclassificazione e le impronte
rimangono osservazioni locali, senza prova di causalità esclusiva.

Il classificatore richiede smoke, Unhandled e un frame numerato con
simbolo esatto di uno dei venti test nominali a zero argomenti. Rifiuta
namespace citati, stringhe, funzioni estranee, warning, fallimenti di
compilazione, segnali e guasti successivi al completamento. Due difetti
preparatori del driver, matching permissivo dei frame e sentinel EOF
costante, sono corretti prima della campagna; versioni e storia restano
conservate. Il lettore finale usa READ-EVAL NIL, readtable standard e
sentinel GENSYM; rifiuta anche una seconda forma letterale `:eof`.

## Copertura e letture

| Sorgente | Espressioni | Esiti di ramo |
|---|---:|---:|
| cbor-array-input.lisp | 248/281 | 42/48 |
| cbor-array-write.lisp | 184/256 | 18/34 |
| Totale | 432/537 | 60/82 |

Mancano 105 espressioni: 14 forme top-level di package/dichiarazioni,
88 sottoforme di 22 ERROR interni e tre default keyword. Mancano
22 esiti di ramo, sulle stesse guardie interne. Tutti restano nel
denominatore. Il raw globale contiene 302 file; lo scope selezionato
comprende soltanto i due nuovi sorgenti. Raw, HTML e ricalcolo freddo
concordano. Nessuna esclusione, attestazione di irraggiungibilità,
MC/DC o qualifica C1.

La [prima lettura C1](cbor-array-revisione.md), la
[seconda lettura C1](cbor-array-lettura.md) e l'
[inventario delle decisioni](cbor-array-decisioni.md) coprono dieci
funzioni, 9–36 righe e 3–8 percorsi: 36 WHEN/UNLESS, due LOOP,
cinque AND/OR con quattordici operandi e otto relazioni concatenate.
Prima della compilazione viene corretta la guardia che limitava anche
la coda ignorata della tabella; originale e nota del rilievo sono
conservati. Le due letture finali non hanno rilievi statici aperti.

Le letture runtime usano dati e reader C4 distinti senza chiamare
prodotto o driver. L'autore del corpus dichiara la propria paternità
nella lettura coverage; non rivendica una terza revisione C1 indipendente.
Il primo estrattore coverage applicava un lettore plist al raw non-plist:
la correzione e l'osservazione parziale sono dichiarate nella nota.
Inventari e impronte documentano confronti locali, senza autenticare
la provenienza dell'esecuzione o promuovere il profilo documentale.

La lettura delle mutazioni confronta le copie con la baseline congelata,
verificata contro i pin della campagna. Cinque file attuali erano cambiati
per i merge successivi: non sono usati come origine del confronto.
Il suo preliminare aveva due warning per STRING= e imponeva erroneamente
l'ASDF attuale. Output originale e versione ricostruita del reader sono
conservati, distinguendo quest'ultima da un originale fingerprintato.
Il reader corretto termina senza warning.

## Integrazione

Il primo `make check`, su `857bfc77962eb4d74b382bf225c8493824baef77`,
integra checkpoint CONTROL e lifecycle del pool: 1.117 nominali e due
smoke, più quattro self-test del linter. Le 811 impronte tracked sono
stabili. Lint: 194 file/zero violazioni; tracciabilità: 119 REQ,65 INV,
13 FI,52 ADR,zero errori; link: 390 file,2.779 collegamenti,zero rotti.

Dopo la presa dei writer governata dal pool, il controllo su
`bdf709edf713891410b4639f219e1c9c1ba1f31a` si ferma ai link della bozza
temporanea dei risultati: quattro relativi alla futura destinazione.
Suite, lint e tracciabilità erano già passati; il controllo complessivo
resta FAILED/exit2/STABLE. Bozza e record fallito sono conservati.
La bozza viene rinominata da `.md` a `.md.txt` con byte identici.

Il controllo completo ripetuto sullo stesso commit è OK/exit0/STABLE:
1.129 nominali, due smoke e quattro self-test linter; 818 impronte
tracked stabili. Lint: 195 file,zero violazioni; tracciabilità invariata;
link: 395 file,2.807 collegamenti,zero rotti. Passano i self-test della
conservazione: 123 controlli su40 casi, più publication2 e normalizer6.
Le evidenze allora presenti comprendono 86 cataloghi,2.927 riferimenti,
18.945 file. Le impronte dei due prodotti e dei tre corpus restano esatte.

Dieci spike terminano con nove OK e SPK-07 PASS, tutti exit0/STABLE.
I risultati figli coincidono con le copie aggregate anche per tipi e
contenuti degli array. Le 62 occorrenze delle impronte nei figli
corrispondono a 54 percorsi unici; coincidono con aggregato e wrapper.
Questi controlli non chiudono i gate degli spike o del motore.
I tentativi preparatori dei reader, inclusi forma dei dati, budget di
visita e conteggi inizialmente fissati, restano distinti dai fallimenti
del prodotto e conservati con i rispettivi limiti.

L'integrazione del bootstrap ACTIVE vuoto e dell'evoluzione delle fonti
Series termina sul commit `842064ad196e8ad4a9b32affe08773a996276656` con
un ulteriore controllo OK/exit0/STABLE: 1.154 nominali, due smoke e quattro
self-test linter; 822 impronte tracked stabili. Lint: 196 file e zero
violazioni; tracciabilità: 119/65/13/52 e zero errori; link: 403 file,
2.814 collegamenti e zero rotti. I dieci spike mantengono gli stessi
esiti e il rapporto 54 percorsi unici/62 occorrenze. Le evidenze allora
presenti comprendono 88 cataloghi, 2.985 riferimenti e 22.181 file.

La lettura DATA del record interno conferma questi numeri, gli artefatti
figli e le sedici osservazioni fisiche stabili, senza caricare il prodotto.
Il wrapper esterno conserva separatamente l'invocazione del controllo
interno. Le cinque impronte array sono invariate; i conflitti del tool
coverage sono risolti mantenendo gli scope array e ACTIVE. La lettura
statica e il self-test del tool integrato passano. I controlli di
conservazione mantengono 123/2/6 verifiche e le fixture dei processi
distinguono segnali e guasti successivi al completamento.

L'integrazione remota `06cc1354cd6843c40da0570e5314fef7cf68a667`
aggiunge 28 test GET ACTIVE e il relativo tool di copertura, mantenendo
identico l'albero dei sorgenti di prodotto. Il merge conserva modulo,
RUN e scope degli array. Il controllo conclusivo ricompila il sistema
ed esegue 1.182 nominali e due smoke, senza avvisi; lint, tracciabilità e
collegamenti passano. La verifica globale delle evidenze e i dieci spike
precedono questa integrazione di test; i nuovi record sono conservati
nel supplemento. Gli archivi già chiusi conservano le versioni esatte
dei documenti e dei dati osservati durante le campagne precedenti.

Viene poi integrata la pubblicazione CONTROL del main
`e599703a6d840f3788e642042facf3ea71d8d32a`. La compilazione e l'intera
suite combinata passano con gli stessi 1.182 nominali e due smoke;
lint, tracciabilità e link restano validi. Prodotti, corpus e scope degli
array mantengono le impronte congelate. Le prove globali e gli spike
precedenti restano distinti da questo controllo dell'integrazione;
le qualifiche aperte della pubblicazione CONTROL non sono promosse.

Il dispatcher pool/Serie del main
`6253f0389337a3712146a885b3c3abddf570199e` viene integrato conservando
modulo, RUN e impronte degli array. Il sistema combinato viene ricompilato
senza avvisi: passano 1.196 nominali e due smoke, con 204 file e zero
violazioni lint, tracciabilità valida e 2.887 link senza errori.
Il record finale di 1.050.740 byte viene compresso senza perdita dal tool
di conservazione dopo il completamento, entro i limiti esistenti.
Questa verifica riguarda compilazione, suite, lint, tracciabilità e link;
non ripete le campagne globali precedenti o chiude le qualifiche aperte.

## Conservazione delle prove

L'[archivio principale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-cbor-array-write/catalogo.lisp)
conserva 3.003 file indicizzati e 3.005 file complessivi, con quattordici
processi: tredici OK e il controllo fallito della bozza. I file indicizzati
sommano 30.037.030 byte; indice e catalogo occupano 1.008.588 e 318 byte.
Quattro worker hanno copiato 379/827/845/952 file senza errori. La verifica
di chiusura indipendente termina OK/exit0 prima del risultato COMPLETE.
Tre impronte per copia confrontano origine prima/dopo e destinazione;
non attestano una pubblicazione atomica o la provenienza dell'esecuzione.

Il raw coverage di 2.195.898 byte è conservato senza perdita mediante
descrittore e payload gzip. Il SHA256 decodificato è
`1fe31c9fd8fa60689f910672a5c53cdcbabbd73da6d71f87209afdc3007a68ec`.
I limiti di 1MiB per file plain e 8MiB per gzip restano invariati.
Il preflight della raccolta concorda con le dimensioni finali.
L'osservazione finale esterna alla raccolta, di 1.086.541 byte, è copiata
con confronto delle impronte e compressa separatamente senza perdita
dopo la lettura dei dati; l'originale resta intatto nel backup locale.
Il SHA256 dei byte ricostruiti è
`fd97df991f566b23f331318484640d55572af32db8811b14b11151ff3df03599`.

Un tentativo di raccolta viene interrotto prima della chiusura quando
viene rilevato il raw coverage sopra il limite plain. SBCL termina con
exit0 dopo SIGTERM, quindi il wrapper OK non indica una raccolta completa.
Il tentativo conserva soltanto copie parziali senza indice o catalogo;
resta nel backup locale insieme alla nota, senza essere presentato come
archivio chiuso. Originale, record e motivo sono conservati.

Il [supplemento](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-cbor-array-write-final/catalogo.lisp)
conserva i controlli d'integrazione successivi, le letture dei dati, i
preflight e i record della raccolta, inclusi i tentativi preparatori.
La chiusura verificata riguarda i file effettivamente indicizzati;
non chiude la qualifica C1, MC/DC o i gate degli spike.
