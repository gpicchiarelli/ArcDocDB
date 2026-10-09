# Lettura C4 degli strumenti CBOR header

Lettura locale del 9 ottobre 2026, conclusa prima delle campagne del prodotto.
Esito: nessun difetto aperto rilevato nei driver congelati. Il lettore è anche
autore del codec: questo referto riguarda gli strumenti C4 e non costituisce
una lettura C1 indipendente del prodotto né un'approvazione umana.
Non sono state eseguite nuove compilazioni, prove o misure durante questa lettura.

## Benchmark e sensore

`tools/cbor-header-bench.lisp` corrisponde al metodo: nove celle, cinque repliche
di 4096 chiamate, warmup 128 e GC fuori dalla misura. Fixture, copie e chiusure
sono preparate prima dei contatori. Ogni chiamata confronta tutti i sei valori
con costanti esplicite e li incorpora nel sink: major + 8·AI + 256·high +
65536·low + 1048576·next + 16777216·form, con form 1/2/3 rispettivamente per
argument/indefinite/break. Il costo misurato include questi confronti e il sink.

I token delle nove fixture, ricalcolati con aritmetica indipendente senza
chiamare il prodotto, coincidono: direct 21037192; u8 37683392; u16 4297851080;
u32 280224000901328; u64 282574516584408; float64 549649973471;
simple 37683399; indefinite 36700412; break 53477631. Il sink atteso è
N·token + N(N−1)/2, modulo most-positive-fixnum; per N=4096 il massimo prima
del modulo è 1157425219938121728, compatibile con il fixnum SBCL a 64 bit.

La baseline usa lo stesso numero di chiamate e deve osservare heap zero; il
controllo positivo conserva l'ultimo oggetto e richiede almeno 16 MiB osservati
su 16 allocazioni da 1 MiB. Un tempo nullo produce rate NIL. Questi sono criteri
da verificare nella campagna: la lettura statica non attesta heap zero del codec.
Snapshot prima/dopo, caricamento rigoroso con avvisi fatali, immutabilità delle
fixture e uscita nonzero per errore o sorgenti cambiati sono presenti.

## Copertura e mutazioni

Il filtro `cbor` di `tools/foundation-coverage.lisp` seleziona i soli suffissi
esatti `/src/codec/cbor-package.lisp` e `/src/codec/cbor-header.lisp`, ancorati
alla fine del pathname. Il self-test rifiuta nomi estesi, sottodirectory e test.
Lo scope `codec` esegue entrambe le suite UTF8 e CBOR. Stato grezzo e HTML sono
conservati; le guardie restano nel denominatore. Il runner deve assegnare una
directory nuova, poiché il driver di copertura non ne impone l'esclusività.

`tools/cbor-header-mutation.lisp` richiede baseline invariata completa PASS,
copie/cache esclusive e un solo target per sostituzione prima dei nove mutanti.
Compilazione fallita o assenza della riga smoke esatta sono INVALID; uscita zero
è SURVIVED; errore dopo il vero marker è DETECTED. Il self-test contempla anche
marker citati in backtrace. La pertinenza del test che rileva ogni mutante dovrà
essere verificata sui log finali: DETECTED da solo non la dimostra.

## Raccoglitore e provenienza

Il raccoglitore legge i dati con read-eval NIL e guardia EOF, copia gli originali
byte per byte e mantiene stdout/stderr incorporati come stringhe con provenienza
esplicita, compresi canali NIL o assenti. Conserva tutti gli stati dei processi,
stato/HTML di copertura e report/tutti i log delle mutazioni. Le entry superiori
sono datum schema 1 con basename; i file grezzi sono associati separatamente.
Metadata `formats NIL`, alias schema e append con catalogo precedente conservato,
controllo dei byte catturati e rifiuto dei nomi ripetuti sono presenti.

Rilievo chiuso prima delle campagne: una lista `:scope` non quotata nel primo
raccoglitore produceva diagnostica di compilazione, senza essere esercitata
dalla prima guardia. Il precedente apparente PASS 10/10 è INVALID e resta
conservato con il codice del tentativo. La correzione quota la lista, rende
fatali gli avvisi nel caricamento dello strumento fidato e aggiunge la guardia
di copertura su due sorgenti letterali, prefisso test e stato/due HTML bytewise.
Il report `/tmp/cbor-header-collector-self-test-v2.lisp`, letto come testo dati
senza load/eval, riporta 11 PASS, zero fallimenti; il log registra lo stesso esito.
La guardia riguarda fixture temporanee del raccoglitore, non campagne del prodotto.

## Versioni lette e limiti

MD5 dei file congelati alla chiusura:

| File | MD5 |
| --- | --- |
| src/codec/cbor-package.lisp | 41ace98eff0e92e6e002cf7b204b84d1 |
| src/codec/cbor-header.lisp | 6e8c6a49314c2f460aa6f8a1759200b6 |
| tools/cbor-header-bench.lisp | bb91c787dd47d263172866fc609e6ee1 |
| tools/cbor-header-mutation.lisp | 1ce45dc548d20ebc6f430bad974ae9df |
| tools/foundation-coverage.lisp | 5da6c65297dc7dd28be00b4c519ed48e |
| /tmp/collect-cbor-header-evidence.lisp | f39c4c1172d91570c745e69f2fbac48c |
| /tmp/cbor-header-collector-guard-test.lisp | d00b5cfe42f1c82b7752ce07417f3da4 |

Restano da acquisire e controllare le evidenze runtime, il catalogo finale e i
collegamenti. Il benchmark è seriale, su successi e buffer preallocati; non
qualifica parser CBOR completo, budget documentali, pool o scaling parallelo.
