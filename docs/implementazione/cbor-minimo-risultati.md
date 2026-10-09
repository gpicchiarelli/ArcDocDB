# Testate CBOR minime — risultati del 2026-10-09

Il lettore locale di [testate minime](cbor-minimo.md) passa le campagne
registrate nel [metodo](cbor-minimo-metodo.md). Il profilo documentale
completo e la qualifica del motore restano successivi.

## Correttezza e concorrenza

La build preliminare completa riporta **381 esiti `ok`**: 379 test delle
suite e due smoke; nessun avviso, lint e tracciabilità superati. La suite
nuova contiene 14 test con oracolo cieco più un supplemento dichiarato
dopo la lettura: [seconda revisione](cbor-minimo-revisione.md).
I tre file originali conservano il loro blob congelato.

Sono verificati tutti i 65536 binary16 e 131072 espansioni esatte a
binary32/64, compresi segni e payload NaN. Il fuzz con seme `4D494E43`
esamina 12288 input: 11223 accettati, 1065 rifiutati, inclusi 84 nonminimi.
Soglie, adiacenze, 152 troncature, tutti i lead e i simple value,
precedenze degli errori, sei valori esatti e buffer immutabili completano
i casi fissati. Il supplemento aggiunge 26 chiamate pubbliche su razionali.

Due worker su buffer privati leggono 524288 header, 4718592 byte;
sink 1406013828104192 e 5628138478764032. Nella preliminare la
sovrapposizione degli intervalli di lavoro è 13762 tick, su clock di
1000000 tick/s: osservazione di tempo reale, senza inferenza sul numero
di core, tempo CPU o scaling del pool.

## Allocazioni e mutazioni

Benchmark seriale su SBCL 2.6.9, ARM64/Darwin, safety 3: otto fixture,
cinque repliche da 4096 chiamate, warmup 128. Tutti i **40 campioni hanno
heap osservato zero**; baseline zero, controllo positivo 16 × 1 MiB
pari a 16777472 byte. I sei valori e il sink sono verificati, con input
preallocati e immutabili. Il contatore non dimostra nonallocazione universale;
nessuna soglia di velocità, confronto di throughput o scaling rivendicata.

La baseline completa delle copie passa; tutti gli **8 mutanti sono
DETECTED**, senza INVALID o SURVIVED. I difetti riguardano soglie delle
larghezze, parola alta u64, normale/subnormale binary16 e speciale/subnormale
binary32. Le compilazioni e i primi rifiuti sono attribuiti ai log effettivi,
con cache e sorgenti privati. Il self-test verifica marker esatti, assenza o
ambiguità dei bersagli e classificazione degli errori di compilazione.

## Copertura e limiti

| File nuovo | Forme osservate/totali | Esiti di ramo osservati/totali |
|---|---:|---:|
| `cbor-float-minimal.lisp` | 151/184 | 31/40 |
| `cbor-minimal.lisp` | 107/148 | 21/28 |
| Totale grezzo | 258/332 | 52/68 |

Le 74 forme mancanti comprendono 10 dichiarazioni e 64 forme associate a
15 siti di errore interno; i 16 esiti mancanti appartengono a guardie
interne. Stato completo e tutti e tre gli HTML sono conservati. Nessuna
esclusione dal denominatore, attestazione MC/DC, prova di irraggiungibilità
o chiusura di un gate. [Prima lettura](cbor-minimo-lettura.md),
[inventario delle dieci decisioni](cbor-minimo-decisioni.md),
[lettura dei driver](cbor-minimo-driver-review.md) e
[lettura degli strumenti](cbor-minimo-strumenti-review.md) distinguono
riscontri statici e runtime.

## Conservazione

L'[indice dell'archivio](../../spikes/results/2026-10-09-cbor-minimal/archive-index.lisp)
elenca ogni file con dimensione e SHA256, insieme a comando, status,
exit e stabilità letti dai rapporti. Le directory di processo mantengono
rapporti originali, descriptor, payload gzip e registri di conservazione.
Gli alberi raw conservano copertura, copie sorgenti/log delle mutazioni,
codice e dati delle revisioni; i FASL restano nella copia locale archiviata.
Il collector confronta sorgente prima/dopo e destinazione; non riscrive
i rapporti originali o inferisce requisiti dai loro risultati.

Una lettura C4 ha rilevato e corretto prima della raccolta il filtro che
ometteva i payload `.gz` nei tree. Il sorgente precedente è ricostruito
dalla sola sostituzione inversa e confrontato con il blob letto dal revisore;
la provenance lo distingue da una cattura originale del file.
Il primo guard è fallito perché il suo rapporto non preallocava i campi
plist `:cases` e `:invocations`: l'aggiunta nelle funzioni locali non
aggiornava la testa del rapporto del chiamante. Codice, fixture, log e
rapporto fallito sono conservati; la correzione riguarda l'harness C4.
Il secondo guard passa **8 casi e 10 invocazioni**, incluse due chiamate gzip:
copia e rilettura, collisioni, payload assente o corrotto, reader-eval vietato
e forma aggiuntiva. Il wrapper rimane stabile.

L'audit indipendente di misure e mutazioni passa 586 controlli di lettura.
Sono conservati anche i due tentativi falliti del suo lettore: struttura
Lisp incompleta e base relativa errata. Questi errori appartengono
all'utilità di audit; i dati originali delle campagne restano invariati.
L'audit della copertura conserva codice e output dei tre tentativi riusciti.

Le campagne del prodotto precedono questa utilità di raccolta e hanno
snapshot stabili. L'aggiornamento dell'indice dell'archivio è derivato e
non costituisce un protocollo durevole del database. Carico esterno non
controllato; prove locali, distinte dalla piattaforma di riferimento.
