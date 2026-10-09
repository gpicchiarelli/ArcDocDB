# Item CBOR con testate minime — risultati del 2026-10-09

La [nuova API](cbor-minimo-struttura.md) verifica un item completo, UTF-8,
testate minime e budget in un solo attraversamento, con scratch privato
per ogni worker. Le campagne locali del [metodo](cbor-minimo-struttura-metodo.md)
passano; ordine/equivalenza delle chiavi e semantica dei tag restano fuori
dal contratto. Non si qualifica il profilo documentale completo o il motore.

## Correttezza e concorrenza

I 22 test nominali ciechi restano identici ai tre blob congelati nella
[seconda lettura C1](cbor-minimo-struttura-revisione.md), senza supplementi
o aggiustamenti dell'oracolo. Build preliminare: 458 test e due smoke,
**460 esiti**, senza avvisi; lint e tracciabilità passano.
Tutti i 768 casi lead sono verificati: 84 accettati e 684 rifiutati.
I 512 AST e il fuzz finito di 4096 span, seme `53434d31`, concordano con
l'oracolo: 41 validi e 4055 rifiutati nel fuzz. I casi nominali includono
16 MiB esatti/oltre, profondità 100/101, budget, preflight invariato,
immutabilità e riuso dopo errore, non solo il percorso positivo.

Due worker reali, ciascuno con buffer e scratch privati, completano
24 scansioni per worker; sink indipendenti 4718784 e 9437376.
La preliminare osserva sovrapposizione di 100317 tick su 1000000 tick/s:
tempo reale, senza inferenza su core, tempo CPU o scaling.
L'audit dei dati dei test passa 53 controlli, confermando anche i sei blob
del prodotto/corpus e gli snapshot completi before/after del record.

## Heap, mutazioni e copertura

Benchmark seriale su SBCL 2.6.9, ARM64/Darwin, safety 3: otto fixture,
cinque repliche da 4096 scansioni, warmup 128. Tutti i **40 campioni hanno
heap osservato zero**, baseline zero e controllo positivo 16777472 byte.
Arity fredda esattamente tre, valori, token, sink e input immutabili sono
verificati. Nessuna soglia di velocità o prova assoluta di nonallocazione.

Baseline completa e tutti gli **otto mutanti DETECTED**, senza SURVIVED,
INVALID o WORKER-ERROR. Nove copie private conformi; ogni mutante modifica
soltanto il file bersaglio e con la sostituzione preregistrata. Compilazione
fallita, segnali OS e guasti dopo completamento non sono rilevamenti.
Quando l'inlining omette il nome del test nella prima backtrace, il referto
conserva helper, condizione e ultimo PASS osservati senza inventare il nome.

| File focale | Forme osservate/totali | Esiti di ramo osservati/totali |
|---|---:|---:|
| `cbor-scan.lisp` | 160/207 | 20/32 |
| `cbor-scan-minimal.lisp` | 10/16 | 0/0 |
| Totale grezzo | 170/223 | 20/32 |

Le 53 forme mancanti sono attribuite a nove forme dichiarative, 38 forme
associate a errori interni e sei default keyword; i dodici esiti mancanti
appartengono a guardie interne. Stato integrale e tre HTML concordano.
Nessuna esclusione dal denominatore, attestazione MC/DC o prova di
irraggiungibilità. L'audit indipendente delle tre campagne passa **1895
controlli**, senza finding. La verifica bytewise conferma che il gzip
ricostruisce gli originali 1113055 byte dello stato di copertura.

## Verifica e conservazione

`make check` passa: 460 esiti della build, quattro marker di lint-selftest
distinti dai test, lint, tracciabilità, link, conservazione e dieci spike.
Il record originale ha exit zero e snapshot stabile. La successiva
integrazione di `edb043b` importa Makefile, documentazione e prove,
senza modificare sorgenti, test, strumenti o ASDF; il controllo conclusivo
di link e conservazione usa il budget di memoria aggiornato.

L'[archivio delle campagne](../../spikes/results/2026-10-09-cbor-minimal-scan/archive-index.lisp)
mantiene immutati 165 file indicizzati e dieci processi, con bytes/SHA256 e
metadata letti dai record. Il
[secondo archivio](../../spikes/results/2026-10-09-cbor-minimal-scan-final/archive-index.lisp)
conserva raccolta, controllo completo, spike, audit e tentativi dei lettori.
Le copie complete/FASL, lo stato plain originale e tutte le fixture negative
del checker, compresi symlink e file oltre budget, restano nel backup locale
`spikes/out/cbor-minimal-scan-isolated-20261009/`. Il subset pubblicato delle
mutazioni comprende bersagli, runner, report e log; non sostituisce le copie.

Il checker Common Lisp passa 24 fixture e verifica inventario chiuso,
dimensioni/SHA e i quattro metadata di processo; limiti ed enumerazione
non preventiva sono espliciti nella [lettura C4](archivi-comandi-lettura.md).
Passano anche le nuove verifiche CL dei due archivi CBOR precedenti,
1313/87 file e otto/sei processi, con i loro indici originali invariati.

Sono conservati i tentativi falliti dei soli helper: directory relativa
del lettore dei test, setup dei reader, preambolo stdout del mutatore e
prima TR HTML senza chiusura esplicita. Le correzioni riguardano i lettori;
le campagne originali non vengono ripetute o riscritte. Il generatore del
manifest stampava un conteggio uno dopo NREVERSE, pur salvando la lista
completa: originale e correzione della sola diagnostica sono conservati.
Le osservazioni restano locali/per file, senza snapshot atomico,
confronto di prestazioni della piattaforma o promozione di gate.
