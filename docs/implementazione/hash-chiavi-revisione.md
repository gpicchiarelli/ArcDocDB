# Hash delle chiavi — revisioni del candidato

## Prima lettura indipendente

Herschel ha letto il prodotto nel commit
`0460a6e723325ff925b8c678e81544fbad2a2684`, senza eseguire build o test.
Il successivo `68a4125` modificava solo documentazione. Riscontri iniziali
conservati, anche dopo la correzione:

| ID | Priorita | Riscontro dedotto, non eseguito dal revisore | Correzione del parent |
|---|---|---|---|
| HASH-R01 | P1 | Digest interno discordante: INVALID-ARGUMENT lasciava l'indice OPEN | La discordanza del verificatore interno porta a FAULTED con `:primary-hash-source-digest`; i guasti del banco conservano causa e condizione |
| HASH-R02 | P2 | Root NIL passata direttamente produceva TYPE-ERROR | Uso di `acquisisci-root`, guasto terminale `:primary-index-missing-root` |
| HASH-R03 | Standard | Relazioni dei blocchi/coda garantite solo dalla API | Preflight relazionali e postcondizioni sui cursori, sempre attivi; negazioni interne testate |

Il confronto statico della formula con la
[specifica XXH64 v0.8.3](https://github.com/Cyan4973/xxHash/blob/v0.8.3/doc/xxhash_spec.md)
non ha individuato difetti: costanti, rotazioni, endian, round, quattro merge,
lunghezza, coda e avalanche. Bounds: 2.047 stripe, tre lane da otto,
una da quattro e tre byte residui. Seme read-only e confronto completo
prima degli scratch/mappe. Heap e inlining ancora da misurare.

## Seconda lettura dell'aritmetica

Pauli ha letto separatamente i quattro file hash del medesimo freeze,
tree `e1968e56faef339fd7b29b2b93f77e35e30c0eef`, dopo aver scritto
l'oracolo indipendente. Nessun difetto statico trovato nelle formule,
nei cinque typep pubblici, nel seed high/low o nell'ordine del ritorno.
Sette helper u64 dichiarati inline; l'effettiva eliminazione delle chiamate
e del boxing non e dedotta dalle dichiarazioni.

## Lettura dell'autore sulle correzioni

| Punto C1 | Argomento e limite |
|---|---|
| 1. REQ/ADR | ADR-0014; REQ-IDX-001/003/005/007, LIM-003, AFF-004/008 |
| 2. Invarianti | Span, progresso, seed immutabile, slot originale, live count; regressioni R01/R02 |
| 3. Errori | Rifiuto esterno distinto da discordanza interna terminale; guasti bancari propagati |
| 4. Cicli | Hash bounded da K<=65535; mappa C campioni e fino a C probe ciascuno |
| 5. Heap | Kernel senza scratch; manutenzione 80 byte payload. Misure e disassemblato pendenti |
| 6. Uscite | Due u32; mappe scritte solo dopo verifica; private e scartabili se parziali |
| 7. Decisioni | HASH-D01..D12; copertura delle guardie incluse, nessuna MC/DC dedotta |
| 8. Proprietari | Buffer e mappe privati; writer esclusivo, seed read-only |
| 9. Traccia | REQ nelle definizioni e nomi delle prove; gate strutturati da eseguire |
| 10. Standard | safety3, tipi specializzati, pre/post blocchi/coda; helper aritmetici puri elementari |
| 11. Parallelismo | Nessun lock, I/O o stato condiviso nuovo; worker test con join bounded |
| 12. Durabilita | Nessuna scrittura durevole o cambio formato; seed lifecycle al controller |

Questo documento conserva letture automatizzate e argomenti delimitati.
Non certifica C1, copertura completa, MC/DC, Linux x86-64 o il motore completo.
Le esecuzioni preliminari auto-attestate degli agenti sono separate dai
registri ripetibili della campagna del parent.

## Supplemento dopo il freeze fdde3a9

Pauli ha chiuso staticamente il delta dei cursori senza rilievi; tree hash
`56810923096a086cc43429b0f3a5343e92e00b4a`.
Herschel ha chiuso R01/R02 e le guardie locali di R03, individuando R04:
le asserzioni del kernel propagavano senza invalidare l'indice chiamante.
Il parent aggiunge `hash-con-seme-indice` a entrambe le API: cattura solo
INVARIANT-VIOLATION, invalida il proprietario e rilancia la stessa condizione.
La regressione inietta una condizione concreta e verifica identita,
FAULTED e mappe invariate. I rifiuti degli argomenti esterni non sono trasformati.
Docstring blocchi/coda aggiornate con classi e ragioni (COD-50).

Il primo controllo completo aveva exit 0 (622 test piu due smoke), ma il
registratore ha rilevato un aggiornamento tardivo dei soli percorsi di
output nel metodo: stato SOURCE-CHANGED, conservato e non accettato come
freeze stabile. Anche il primo comando mutazioni e conservato con tale stato.
Le successive esecuzioni ripetono i controlli sul candidato definitivo.

Herschel ha riletto il delta `c9c7561`: nessun finding statico aperto,
R01–R04 e COD-50 chiusi; file esaminati stabili anche dopo l'integrazione
`344e8fb`. [Rapporto strutturato](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-key-hash/revisione-herschel-finale.lisp).
I [risultati](hash-chiavi-risultati.md) distinguono le prove osservate da
copertura, heap parallelo, MC/DC e qualifiche ancora aperte.
