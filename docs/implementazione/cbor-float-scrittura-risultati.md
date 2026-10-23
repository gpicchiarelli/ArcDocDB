# Verifiche della scrittura float CBOR

Campagne del 2026-10-13 sul [metodo preregistrato](cbor-float-scrittura-metodo.md),
blob `755b13a91ab72f54383d96faee5780da36e750d6`. Il corpus è congelato
prima del prodotto; due letture C1 precedono la prima compilazione.
Le versioni provate sono narrow `cd5749edc0a757ee3a5b470eda566a6685d32fd8`
e write `03c6aed61e2c243d8b1a6c4332ce1837c4e9a77c`.

## Corpus e parallelismo

I 18 test comprendono 17 prove seriali e una con due worker riusati.
Tutti i 65.536 valori binary16 e le espansioni esatte binary32/64 danno
196.608 successi, ruotando otto offset e tre configurazioni. Le capacità
0/1/2 producono altri 196.608 rifiuti, con AI25/26/27 ruotati.
Le configurazioni ruotate non costituiscono un prodotto cartesiano.
Vettori letterali e un oracolo aritmetico controllano soglie normali e
subnormali, segno, NaN, attraversamento delle parole e intero array fisico.

Il fuzz usa 2.048 casi e seed `464C5434`: 768 successi, 256 capacità
insufficienti, 128 AI invalidi, 128 HIGH, 128 LOW, 256 incoerenze delle
parole e 384 range invalidi. Sono verificati anche arità esatta, precedenze,
array displaced, riuso e concatenazione di 38 byte.

Due worker reali eseguono due ondate di 8.192 chiamate ciascuno:
32.768 operazioni con buffer privati e piani immutabili. Ogni ondata ha
segnali READY/GO/DONE distinti, timeout e cleanup limitati. I sink sono
2.115.584/2.148.352 in entrambe le ondate; nell'integrazione `1f36b40`
gli intervalli si sovrappongono per 2.564/2.559 tick, a 1.000.000 tick/s.
Questo dato non misura scaling o simultaneità sui core.

## Misure e mutazioni

Sei fixture congelate coprono half 1,5, double ridotto a half 1,5,
double ridotto a single non half, double mantenuto, minimo subnormale
half da double e NaN double negativo con payload non accorciabile.
Cinque repliche di 4.096 chiamate, dopo 128 chiamate di warmup, producono
30 campioni con heap osservato zero. Baseline nulla e sensore positivo
di 16 × 1 MiB osservano rispettivamente zero e 16.777.472 byte.

NEXT, arità fredda, array completo, token e sink sono controllati.
Il ciclo caldo usa il valore primario; il corpus verifica l'arità di
ogni successo. I campioni sommano 0,033414 s; il wrapper dura 1,416727 s.
L'auditor ricalcola i byte IEEE tramite interi e razionali: 55.824
controlli riusciti, senza chiamare prodotto o driver. Non vi è soglia
di velocità né prova assoluta di assenza di allocazione. Il percorso
subnormale binary64→32 che attraversa le parole ha prove funzionali,
ma non appartiene alle sei fixture misurate.

Otto mutanti compilabili sono rilevati: `8 DETECTED`, nessun
`SURVIVED`, `INVALID` o `WORKER-ERROR`. Le nove copie hanno 280 file
ciascuna: 2.520 file confrontati, con cache private e una sostituzione
esatta per mutante. Le 281 impronte dichiarate comprendono anche il
driver non copiato; non provano la chiusura degli alberi privati.

I nove log completi mostrano baseline con 989 OK, smoke alla riga 2
e termine alla riga 1.067. Ogni mutante ha smoke prima di Unhandled,
exit 1 senza segnale o warning e un frame numerato del corpus
REQ-CBR-004. Il classificatore rifiuta errori di compilazione, warning,
segnali e guasti successivi al completamento. La mutazione del valore
aggiuntivo NIL modifica FTYPE e DEFUN della sola copia in modo coerente.
Classificazione e log restano osservazioni locali dell'esecuzione.

## Copertura e letture

| Sorgente | Espressioni | Esiti di ramo |
|---|---:|---:|
| cbor-float-narrow.lisp | 175/220 | 26/36 |
| cbor-float-write.lisp | 190/220 | 35/40 |
| Totale | 365/440 | 61/76 |

Mancano 75 espressioni: 11 dichiarazioni e 64 nodi ERROR interni.
Mancano 15 esiti: 13 guardie e due fallback degli esponenti subnormali.
Tutti restano nel denominatore. Il raw con 274 file, le due entry
selezionate e i tre HTML concordano; nove osservazioni restano stabili.
Non vi è attestazione di MC/DC, irraggiungibilità o qualifica C1.
L'[inventario delle decisioni](cbor-float-scrittura-decisioni.md) comprende
AND/OR, relazioni concatenate e postcondizione del quoziente.

Il raw originario ha 1.991.414 byte e SHA256
`e6d67d0e7c452205c2531375b68ec584740e47d6e45302ebdaef1f5d730a54f4`.
La compressione lossless segue le letture e conserva descriptor,
gzip e impronta dei byte ricostruiti.

La [prima lettura C1](cbor-float-scrittura-revisione.md) ha trovato una
postguardia ridondante con il tipo u23. Prima della compilazione è
sostituita dalla ricostruzione separata di HIGH e LOW, senza u64.
Originale, correzione e nota sono conservati. Le due letture finali,
inclusa la [seconda lettura C1](cbor-float-scrittura-lettura.md), non
hanno rilievi aperti. La revisione statica non è un fallimento runtime.

Le letture [dei dati](cbor-float-scrittura-dati.md) e
[della copertura](cbor-float-scrittura-copertura.md) conservano la propria
provenienza. L'autore del corpus non rivendica indipendenza dalla suite;
l'autore dell'auditor dichiara la paternità e il coordinatore ne legge
il codice. Gli errori degli estrattori ad hoc sono dichiarati separatamente
dalle campagne, con osservazioni disponibili parziali. Gli inventari
e le impronte non autenticano l'esecuzione. Il reader C4 controlla
cons propri e aciclici, senza promettere un controllo generale dei vettori.

## Integrazione

Il preliminare su `364ac3b` passa con 987 test nominali e due smoke:
989 OK distinti, 25,80555 s, 738 impronte sorgente identiche prima/dopo,
165 file lint senza violazioni e 118 REQ/65 INV/13 FI/52 ADR senza errori.
Non vi sono warning o style-warning.

Il `make check` su `1f36b4073a0595f3bd215305ffce4715b171e4a6` integra
`main` a `3106a49` e l'associazione fisica readonly/append dei file:
987 nominali + due smoke = 989 OK della suite; quattro self-test del
linter portano il totale a 993 OK unici. Le 741 impronte sono stabili,
il working tree è pulito e il tempo è 210,370008 s. Lint: 167 file,
zero violazioni; tracciabilità: 118/65/13/52, zero errori; link:
348 file e 2.598 collegamenti, zero errori. Passano i 123 self-check
dello storage delle evidenze e gli altri verificatori.

Dieci spike danno nove OK e SPK-07 PASS, tutti exit 0/STABLE. Gli
artifact coincidono con i risultati aggregati anche per tipo, dimensioni
ed elementi degli array; 62 impronte su 50 percorsi concordano con
il wrapper. Questo non chiude i gate degli spike o del motore.

La successiva integrazione delle 42 prove OUTCOME del resolver GET,
su `56e0a3acc26633bc8a9c5377f7b6a946466d9a45`, passa con 1.029 test
nominali, due smoke e quattro self-test linter: 1.035 OK unici.
Le 751 impronte sono identiche prima/dopo; il controllo core dura
225,684821 s e il wrapper 228,782840 s. Lint e tracciabilità restano
senza errori; i link sono 2.638 su 356 file, tutti validi. Le evidenze
comprendono 79 cataloghi, 2.585 riferimenti e 17.967 file. I sink float
restano 2.115.584/2.148.352; gli overlap osservati sono 2.586/2.722 tick.

L'integrazione finale su `3ed6ebfba4dc692b524a4cf3416c8757de978e41`
include anche il controllore del pool pubblicato a `45eb153`: `make check`
è OK/0/STABLE in 209,526331 s, con 766 impronte identiche prima/dopo
e working tree pulito. La suite passa con 1.052 nominali e due smoke;
i quattro self-test linter portano il totale a 1.058 OK unici.
Lint: 173 file, zero violazioni; tracciabilità: 118/65/13/52, zero errori.
Writer e corpus float conservano le impronte congelate iniziali.
I link sono 2.668 su 363 file, tutti validi; il controllo delle evidenze
passa su 80 cataloghi, 2.610 riferimenti e 18.053 file. Le dieci prove
spike restano OK/PASS, exit 0/STABLE e identiche ai rispettivi aggregati,
con 62 impronte su 50 percorsi corrispondenti. Le due ondate float
mantengono i sink originali; gli overlap sono 2.570/2.564 tick.
Il primo conteggio sintetico includeva quattro self-test linter fra i
nominali: è corretto prima della conservazione del documento finale.

## Conservazione

L'[archivio principale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-cbor-float-write/catalogo.lisp)
conserva 2.795 file indicizzati, 2.797 file complessivi e 26.641.257 byte
indicizzati: registri, codice congelato, copie mutanti, log, misure,
raw/HTML e letture. I 15 processi comprendono 13 OK e due tentativi
falliti dell'helper C4 di raccolta, per parentesi e firma di
SIGNAL-SEMAPHORE, senza caricamento del prodotto. Versioni e registri
sono conservati; i successivi self-test passano con 18 copie, quattro
worker e rifiuti specifici di corruzione, target duplicato e destinazione
esistente. La correzione della data al 2026-10-13 conserva la versione
precedente e un ulteriore self-test riuscito.

La raccolta usa quattro worker, tre SHA per copia, directory create
prima dei worker e indice pubblicato dopo i confronti. I worker copiano
380/632/852/931 file, senza errori; il wrapper dura 628,033756 s,
inclusa la verifica indipendente dell'inventario chiuso. Non è un
benchmark del parallelismo. L'archivio principale resta immutato dopo
la raccolta. Le osservazioni sono locali, senza confronto live delle
origini, pubblicazione atomica o promozione C1.

Il [supplemento finale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-cbor-float-write-final/catalogo.lisp)
conserva i controlli delle integrazioni successive, la raccolta originale,
la sua osservazione e il log di chiusura, le letture finali e le copie dei
documenti pubblicati. Il suo inventario è verificato separatamente.
La [lettura dell'integrazione finale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-cbor-float-write-final/raw/pool-integration-review-final.md.txt)
conserva i confronti dei dati e i relativi limiti.
