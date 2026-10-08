# SPK-08 — metodo preregistrato per le impronte

;;; REQ: REQ-SIM-001 REQ-SIM-002 REQ-BEN-002 REQ-VAL-001 REQ-AFF-003 REQ-AFF-008 REQ-AFF-016

Registrato prima di qualsiasi compile/CHECK. Ambito Phase0: solo il nuovo
`impronte.lisp`, package `ARCDOCDB.SPK08.IMPRONTE`, export `CHECK` e `BENCH`.
Tutto il lavoro avviene nel checkout isolato
`/Users/gpicchiarelli/.codex/worktrees/valutazione-avanzata/ArcDocDB`.
Common Lisp/SBCL, safety 3, nessuna dipendenza da altri spike e nessuna
integrazione dell'indice. Nessun commit o push.

## Contratto e algoritmo

Un gruppo contiene 16 byte ctrl. Le impronte valide sono 0–127; empty = 128,
deleted = 254. Tutti gli altri byte con alto bit acceso sono esclusi dal match.
La maschera risultante ha il bit i per la posizione i (0–15). Query fuori
0–127, tipi errati e finestre di meno di 16 byte producono errore.
L'input è di sola lettura. La serializzazione delle due parole u64 è
esplicitamente little endian: byte i nei bit 8*i; il risultato non dipende
dall'endian della macchina. Non si usano accessi di memoria non allineati o VOP.

Per x = word XOR query ripetuta, la maschera esatta degli zeri è
`NOT (((x AND 0x7f7f7f7f7f7f7f7f) + 0x7f7f7f7f7f7f7f7f) OR x OR
0x7f7f7f7f7f7f7f7f) AND 0x8080808080808080`.
Ogni somma di lane è al massimo 254: non c'è riporto fra byte.
Tre piegature comprimono gli otto bit alti in un byte; due parole danno u16.
Il mutante `(x - 0x0101010101010101) AND NOT x AND 0x8080808080808080`
conserva il limite del prestito, con x = byte 0 seguito da byte 1: utile come
test di esistenza di uno zero, inadeguato come maschera esatta per posizione.
Il mutante resta una funzione separata, mai una variante selezionabile dei kernel.

Kernel: `scalar16` e `packedmask16` su byte array e offset; `scalar-u64` e
`typedu64` su due u64. Tipi specializzati, safety 3 e chiamate dirette/inline
nei cicli. La compilazione/disassemblato e i campioni di bytes-consed
permettono di valutare le allocazioni; non si presume che una chiamata Lisp
esterna con u64 boxed non allochi. SWAR è aritmetica su parole intere, non
SIMD hardware. Un oracle scalare distinto legge solo i byte e somma potenze
di due, senza riusare packing, compressione o formula SWAR.

## CHECK e budget

1. Strict compile in processo SBCL senza init: warning e style-warning sono
   fatali, oltre ai valori warnings/failure di compile-file. FASL solo in `out/`.
2. Tutti i 256 byte, tutte le 128 query e tutte le 16 posizioni isolate.
3. Tutte le coppie di byte (256²) nelle 15 coppie adiacenti, query 0 e 127;
   comprende il confine fra le parole e ogni posizione con prestito.
4. Tutte le 16² coppie di posizioni, byte nel dominio piccolo
   {0, 1, 126, 127, 128, 129, 254, 255}, query {0, 1, 126, 127}.
5. Tutte le 4^8 parole su {0, 1, 128, 254}, ciascuna nelle due metà, query
   {0, 1, 127}; dominio piccolo interamente enumerato, non campionato.
6. Differenziale più grande: 20.000 gruppi da LCG u32 con seme fisso;
   offset 0–31, byte arbitrari, query 0–127. Fixture golden endian e maschere
   vuota/piena/alternata; tutte le maschere u16 per la compressione.
7. Controlli negativi del mutante, invalid args attraverso chiamata dinamica
   per evitare warning statici intenzionali; confronto integrale input
   prima/dopo, anche sul rifiuto. Rifiuti deterministici di budget CHECK/BENCH
   prima di qualsiasi misura BENCH.

CHECK ha limite massimo 4.000.000 confronti di gruppo, default uguale al
massimo, 20.000 gruppi differenziali (tetto 100.000), 120 secondi (tetto 300).
Scadenza controllata ogni 4096 confronti e alla conclusione, limite cooperativo;
un limite esaurito è errore, mai successo parziale. I conteggi sono riportati
per campagna, con controlli di congruenza. Conservare disassemblato locale
dei quattro kernel e dei cicli diretti. La plist riporta :status :ok solo
dopo tutte le campagne e include limiti e piattaforma reale.

## BENCH da eseguire soltanto nel parent

API prevista: `(bench &key (rows 1024) (passes 64) (warmup-passes 2)
(seconds 60) (byte-budget 16777216))`. Cinque repliche obbligatorie.
Due dataset, misto e avversario (prestiti, hit pieno, miss, speciali, alto bit,
0/127, confine di parola); matrice di byte e parole preallocata, stessi query
e oracle per entrambi i kernel di ciascun confronto. Offset 0–15 su righe
da 32 byte. Packing/preparazione/validazione/oracle/warmup esclusi dalle
misure. Confronti: scalar16/packedmask16 e scalar-u64/typedu64.
Ordine alternato AB/BA per replica e cella della matrice, esplicitamente
riportato. Accumulatore numerico verificato contro oracle e pubblicato.

Ogni campione misura ticks e bytes-consed solo intorno al ciclo diretto;
riporta operazioni effettive, ns/op calcolati, byte totali e per operazione,
checksum, ordine e replica. Non si sottrae un overhead stimato e non si
inventano tempi; ticks = 0 rende la misura non risolta e produce errore.
GC e scheduling durante il ciclo restano inclusi. Allocazioni del report
e fixture escluse; bytes-consed non è RSS. Il ciclo legge i dati preallocati
e produce un checksum fixnum; non crea strutture per chiamata.
I limiti sono rows 16–8192, passes 1–1024, warmup 1–64, seconds >0 e ≤300,
payload byte-budget ≤64 MiB e operazioni totali ≤200.000.000.
La scadenza è cooperativa fra blocchi di al massimo 4096 operazioni, con
stessi controlli nei due cicli; esaurimento segnala errore senza plist :ok.
BENCH restituisce :status :ok, :measurements, limiti e campioni raw,
solo dopo cinque repliche complete per tutte le celle. Non viene eseguito
in questo lavoro, neppure per warmup o smoke test.

## Evidenze e limiti dell'inferenza

Ogni tentativo compile/CHECK, incluso un fallimento, avrà nuovi file ignored
`out/` con schema-version 1, argv e stdin esplicito, ambiente, hash/contenuti
prima/dopo, risultato decodificato, stdout/stderr integrali e limiti.
Il wrapper esistente `tools/record-command.lisp` può registrare il comando;
un driver nuovo in `out/` aggiunge risultato del modulo, warning, source
immutato e log senza troncamento. Driver e stdin vengono inclusi nelle prove.
Nessun file esistente di core/run/suite/tools/docs/ADR/REQ viene modificato.
Alla consegna si elencano tutti i tentativi, i percorsi e i conteggi reali.

Piattaforma osservata inizialmente: Darwin 27.0.0, arm64, SBCL da
`/opt/homebrew/bin/sbcl`. Versione SBCL, CPU, risoluzione clock e feature
endian vengono raccolte dai processi registrati. La prova riguarda questa
piattaforma; non qualifica x86-64, SIMD hardware, l'indice o il motore.
Nessuna superiorità prestazionale prima dei campioni del parent.

## API per il parent

Gli unici simboli esportati sono `ARCDOCDB.SPK08.IMPRONTE:CHECK` e
`ARCDOCDB.SPK08.IMPRONTE:BENCH`: entrambi accettano la chiamata senza argomenti.
I kernel rimangono simboli interni (`ARCDOCDB.SPK08.IMPRONTE::...`).

| Simbolo interno | Argomenti | Risultato |
|---|---|---|
| `SCALAR16` | ctrl simple-array u8, start fixnum, h7 | mask16 scalare |
| `PACKEDMASK16` | gli stessi argomenti | mask16 SWAR, packing LE incluso |
| `SCALAR-U64` | low u64, high u64, h7 | mask16 scalare su parole pronte |
| `TYPEDU64` | gli stessi argomenti | mask16 SWAR su parole pronte |

Il bit i corrisponde al byte i. Le due parole rappresentano rispettivamente
i byte 0–7 e 8–15 della finestra. I byte con alto bit acceso non corrispondono
mai a una query valida. Nessuna query viene troncata a sette bit.

La chiamata senza argomenti di BENCH prepara 1024 righe per dataset,
64 passaggi per campione e due passaggi di warmup. Sono previsti 40 campioni
raw, 2.621.440 operazioni misurate e 16.384 operazioni di warmup,
payload di 106.496 byte e termine cooperativo di 60 secondi. Questi sono
parametri e conteggi pianificati, non misure eseguite. Il parent può scegliere
più passaggi tramite `:passes`, mantenendo i limiti dichiarati e registrando
la chiamata completa. Nessun BENCH è stato eseguito durante questo lavoro.

## Esiti successivi alla preregistrazione

Ambiente dei processi registrati: SBCL 2.6.9, Darwin 27.0.0, ARM64, Apple M4,
16 GiB RAM, 10 CPU logiche; host little endian, clock con 1.000.000 unità/s.
Carico esterno non controllato. Safety 3 invariato in tutti i tentativi.

Tutti i tentativi usano lo stesso argv, con stdin vuoto da `/dev/null`:

```text
/opt/homebrew/bin/sbcl --noinform --no-sysinit --no-userinit --script spikes/SPK-08-generated-code/out/record-impronte.lisp compile-check
```

| Tentativo | Record schema 1 relativo a questo modulo | Esito |
|---|---|---|
| 1 | `out/4000480808-impronte-86996-0/report.lisp` | Compile riuscita, zero warning; caricamento fermato da uno style-warning di ridefinizione di DEFMACRO. CHECK non eseguito. |
| 2 | `out/4000480868-impronte-87419-0/report.lisp` | Macro resa locale con MACROLET. Compile, load e CHECK :ok, zero warning/style-warning. |
| 3 | `out/4000481031-impronte-88302-0/report.lisp` | Helper rinominati in italiano. Compile, load e CHECK :ok, zero warning/style-warning. |
| 4 | `out/4000481114-impronte-88523-0/report.lisp` | Ultima revisione dei commenti italiani. Compile, load e CHECK :ok, zero warning/style-warning. |

Quattro compilazioni riuscite, un caricamento rifiutato, tre CHECK completi.
Ogni record conserva integralmente stdout/stderr, argv/stdin, ambiente,
contenuti e Git blob prima/dopo di modulo, metodo e driver. Tutti gli snapshot
di ogni tentativo risultano stabili. Le successive modifiche intenzionali
sono documentate dai tentativi successivi; questa sezione è un'aggiunta
documentale dopo l'ultima esecuzione e non modifica il modulo compilato.
Non vengono fotografati i moduli di altri agenti, che lavorano in parallelo.

I tre CHECK riusciti hanno gli stessi conteggi:

| Campagna | Gruppi | Confronti dei quattro kernel |
|---|---:|---:|
| Tutti byte/query/posizione | 524.288 | 2.097.152 |
| Tutte le coppie di byte adiacenti, query 0/127 | 1.966.080 | 7.864.320 |
| Tutte le coppie di posizioni, dominio piccolo | 65.536 | 262.144 |
| Tutte le 4^8 parole, due metà, tre query | 393.216 | 1.572.864 |
| Tutte le maschere u16 | 65.536 | 262.144 |
| Offset, endian e frontiere | 518 | 2.072 |
| Differenziale deterministico | 20.000 | 80.000 |
| Testimoni del mutante e confine fra parole | 29 | 116 |
| Totale CHECK principale | 3.035.203 | 12.140.812 |

Inoltre, 77 controlli negativi per CHECK: 34 sugli ingressi byte, 26 sulle
parole/query, cinque sui limiti CHECK/tempo, 12 sul preflight BENCH (nessuna
chiamata a BENCH). Un CHECK annidato con budget di un gruppo rifiuta
l'operazione successiva; il suo gruppo appartiene al controllo negativo,
non al conteggio del CHECK principale. Il mutante è smentito da 28 testimoni,
per entrambe le query e tutte le coppie nella medesima parola. Il controllo
alla frontiera 7/8 conferma che il prestito non attraversa le due parole.
I buffer sono confrontati integralmente prima/dopo anche sul rifiuto.

Limiti effettivi CHECK: 4.000.000 gruppi, 20.000 casi differenziali,
120 secondi, checkpoint ogni 4096 gruppi. Ogni rifiuto è una condizione;
nessun limite esaurito restituisce :ok. Le tre esecuzioni complete sono
entro questi limiti. I tempi di CHECK nei record non sono benchmark.

L'ultima directory conserva `check-data.lisp`, il FASL, `stdout.txt`,
`stderr.txt` e otto file `disassembly-*.txt` dei quattro kernel e quattro
cicli. L'aritmetica osservata usa registri interi ARM64 (MUL/EOR/AND/ADD/ORR
e shift), con controlli safety 3 e rami di errore. Nei percorsi normali dei
kernel SWAR non si osservano chiamate di allocazione; i cicli contengono
anche percorsi freddi di errore. L'assenza di bytes-consed nel ciclo e
l'eventuale vantaggio prestazionale restano da misurare nel parent.

## Integrazione e lettura autonoma dei report

Prima del CHECK integrato, il runner converte soltanto gli identificatori
dei package sperimentali in stringhe qualificate. Numeri, byte, output e
risultati restano invariati. Il report può così essere letto con
`*read-eval*=nil` senza caricare il modulo. I quattro record originali sono
conservati integralmente nel campo `:raw-original` delle evidenze portabili
in [catalogo](../results/2026-10-08-avanzamento/catalogo.lisp); il campo
`:decoded-record` dichiara la stessa conversione di rappresentazione.
I kernel misurati non cambiano.

Il parent ha poi eseguito il BENCH con tutti i parametri predefiniti nel
[runner integrato](../results/2026-10-08-avanzamento/spk08-benchmark.lisp):
40 campioni scalar/SWAR completi, cinque repliche/cella, checksum congruenti,
zero byte consed osservati nei cicli. Il medesimo processo esegue dopo il
modulo nativo, in serie. Il [resoconto](../../docs/valutazione/risultati-SPK-07-08-2026-10-08.md)
distingue le due matrici e i limiti delle conclusioni.
