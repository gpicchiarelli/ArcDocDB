# Stabilizzazione dell'insieme Serie — metodo

> **Proposta di API** — Metodo preregistrato il 2026-10-22 sulla base
> `3b874756`, prima del codice e delle diagnostiche. Realizza il completamento
> dei nomi vivi di ADR-0040 §2–3; nessun nuovo formato o punto di commit.

## Contratto previsto

`recovery.series:stabilizza-nomi-serie-recuperata(directory, sources,
active, closed, :max-segmenti 65536)` riceve il set posseduto aperto e i
due risultati di `leggi-serie-recuperata`. CLOSED è un simple-vector
completo ordinato per ID u64; ACTIVE può comparire in qualunque posizione
del set delle fonti. Il controller mantiene catalogo, CONTROL, namespace,
set, vettore e capacità esclusivi/stabili nel pool I/O, prima del checkpoint
e dell'ammissione. Il gate Archivio resta obbligo del coordinatore.

Tre fasi, tutte limitate dal numero delle fonti:

1. Verifica metadata completa: count/budget prima delle scansioni, ID
   strettamente crescenti, unico ACTIVE, allineamento con ogni token CLOSED,
   stesso CONTROL per EQ, stessi FD, EOF ACTIVE e P CLOSED canonici.
2. Preflight I/O di tutti i nomi: modi/backend, nome/FD, esattamente una
   forma presente; capacità esclusiva soltanto per un temporaneo. Nessuna
   rinomina o fsync prima del completamento di questa scansione.
3. Completamento in ordine ID con la primitiva per fonte esistente:
   pubblicazione esclusiva se temporaneo, postcondizione e fsync parent
   anche se già definitivo. Due conteggi escono solo al successo completo:
   rinominati e già definitivi, con somma uguale al numero delle fonti.

L'ordine stretto degli ID del set, la cardinalità esatta del manifest e
l'appartenenza di ogni riga dimostrano completezza senza un'altra tabella
seen. Ogni CLOSED consumato deve avere lo stesso ID della riga: duplicati,
permutazioni e omissioni non sono accettati. Zero e bit alti u64 restano
validi per CLOSED; NIL indica ACTIVE non ancora incontrato, anche se la
sua posizione finale è zero. Si riusano le guardie semantiche per fonte.

Il budget `max-segmenti` è un `index`, zero ammesso; include ACTIVE. Il
superamento produce `resource-exhausted` prima delle scansioni. Nessun
array, hash o piano per fonte aggiunto: soltanto cursor/count e nomi privati
brevi delle primitive esistenti. Le copie e la FFI possono allocare sul
percorso freddo; non è un budget RSS o una promessa di zero heap.

## Preflight I/O condiviso

`io:verifica-stabilizzazione-temporaneo` esegue il medesimo preflight della
primitiva di completamento e restituisce T per temporaneo o NIL per
definitivo. Un helper privato possiede le due foglie e il ramo selezionato;
sia il preflight pubblico sia il completamento lo riusano. Il risultato
non è una lease o una prenotazione: il completamento ricontrolla prima
degli effetti. Nessun nuovo backend o ripiego meno restrittivo.

## Guasti e proprietà

Un errore nell'ultima riga o nell'ultimo preflight dei nomi precede tutti
gli effetti. Durante la terza fase ogni fonte completata resta completata:
il gruppo non è una transazione atomica. Un guasto della primitiva I/O
mantiene il suo fail-stop del parent e la causa originale; il gruppo non
chiude, annulla, ritenta o nasconde errori e non restituisce conteggi parziali.
L'interruzione fra due chiamate completate non implica I/O pendente.
Riacquisizione dopo capacità guasta e nuova osservazione dei nomi restano
quelle del completamento idempotente esistente. L'ammissione resta chiusa
finché il coordinatore non completa l'intero recovery.

Nessun lock, thread, registro o scrittura condivisa fra Serie. La sequenza
interna appartiene a una sola Serie; Serie distinte mantengono capacità e
workspace separati. Rimozioni, nuovo ACTIVE, checkpoint CONTROL, indici,
frontiera CSN e traffico non sono completati da questa API.

## Decisioni C1 da qualificare

| ID | Confine |
|---|---|
| SGS-D01 | Budget valido/count ammesso; count set = 1 + CLOSED e CLOSED = manifest |
| SGS-D02 | ID set strettamente crescenti; primo zero, duplicato e regressione |
| SGS-D03 | Unico ACTIVE; posizione zero valida, token/EOF/FD/manifest esatti |
| SGS-D04 | CLOSED successivo disponibile e tipizzato; ID/P/FD esatti, stesso CONTROL EQ |
| SGS-D05 | Consumo intero CLOSED e presenza ACTIVE; nessuna omissione o permutazione |
| SGS-D06 | Tutti i preflight dei nomi precedono gli effetti, inclusa l'ultima fonte |
| SGS-D07 | Primo/ultimo temporaneo o definitivo; backend esclusivo richiesto solo quando serve |
| SGS-D08 | Conteggi completi e somma esatta, FD/CONTROL/parent ancora aperti |
| SGS-D09 | Errore/interruzione durante completamento; effetti precedenti conservati, nessun output parziale |

Prima dei processi: codice committed, due letture dell'autore, revisione
indipendente statica e agenti chiusi. Compilazione forzata del solo prodotto
con avvisi fatali e cache privata gerarchica; lint, trace, link e lettura
del compilato. Tutte le diagnostiche, inclusi fallimenti, passano dal
recorder; copie lossless, collector comune con quattro worker e inventario
chiuso verificato. Rapporti preparatori usano suffisso `.source` anche in
staging; i conteggi dei preparatori usano liste già riordinate e stabili.

Non si aggiungono o eseguono test funzionali, FI, copertura, mutazioni o
benchmark. SGS-D01…D09, MC/DC, qualifica C1, guasti del filesystem e recovery
completo restano aperti. Compilazione e revisione statica non li sostituiscono.
