# Decisioni della scrittura dei valori semplici CBOR

Inventario statico prima della compilazione e delle campagne; le
dipendenze esistenti non sono riscritte. Nessuna esclusione dal
denominatore di coverage, attestazione MC/DC o copertura completa.

| Funzione / forma | Condizioni, da sinistra | Testimoni previsti |
|---|---|---|
| `check-input-simple-cbor-write` / `unless and` | BUFFER octets; START index; END index; range ordinato entro lunghezza | array/tipo START/tipo END errati, START>END, END>lunghezza; valido e vuoto |
| `scrivi-semplice-cbor-minimo` / `unless and` | BEGIN<NEXT; NEXT≤LIMIT | footprint positivo e contenuto sul successo; guardia interna conservata |

La relazione concatenata `START≤END≤length(BUFFER)` contiene due confronti:
ordine dello span e limite fisico. Il TYPEP di VALUE usa l'unione
`(or (integer 0 23) (integer 32 255))`: entrambi gli intervalli, estremi,
gap 24..31, -1 e 256, interi grandi e tipi diversi sono nel corpus.
Questo OR appartiene al descrittore di tipo, senza cortocircuito scritto
come forma di controllo; non viene omesso dall'inventario semantico.

Le decisioni semplici comprendono span coerente, selezione a 23/32,
capacità END−START, scelta del lead, secondo byte e cursore finale.
Tutte le capacità insufficienti e lo spazio fisico oltre END sono
falsificati nel corpus. Le guardie interne rimangono nei rapporti grezzi.

Conteggio sintattico dei percorsi: 7 per il preflight, 8 per la funzione
pubblica, includendo AND/OR di controllo ma non espansioni TYPEP o
confronti primitivi. La coppia di condizioni del footprint e la guardia
di span richiedono verifica separata; il successo dei test non ne prova
l'indipendenza. Il gate C1 di ADR-0035 rimane aperto.
