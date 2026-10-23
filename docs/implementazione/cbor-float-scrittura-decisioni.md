# Float CBOR — decisioni composte

Inventario sintattico dei due nuovi file C1, dopo la correzione statica
della postcondizione del quoziente. Non esclude espressioni o rami e
non attesta MC/DC, copertura completa o irraggiungibilità delle guardie.

| Funzione | Decisione | Condizioni e priorità |
|---|---|---|
| check-float-cbor-range | AND di range | BUFFER octets; START index; END index; START≤END≤length |
| check-float-cbor-words | AND del caso AI25 | HIGH zero; LOW≤65535, dopo entrambi i controlli u32 |
| seleziona-float-cbor | OR di ingresso | AI27 oppure HIGH zero |
| seleziona-float-cbor | AND riduzione64 | AI27 e bit64 accorciabili esattamente |
| seleziona-float-cbor | AND riduzione32 | AI26 e bit32 accorciabili esattamente, anche dopo riduzione64 |
| seleziona-float-cbor | OR di uscita | AI scelto27 oppure HIGH scelto zero |

Anche le relazioni numeriche concatenate conservano le componenti:
START≤END e END≤length nel range; limite inferiore/esponente/limite
superiore nelle quattro finestre normali/subnormali dei riduttori;
BEGIN≤CURSOR, CURSOR≤NEXT e NEXT≤LIMIT nella guardia della destinazione.

La postcondizione del significando64 confronta separatamente le parole
originali con quelle ricostruite. La seconda guardia usa IF: SHIFT<32
ricostruisce LOW dai bit bassi del quoziente, altrimenti LOW deve essere
zero. Non ricompone un u64. Il corpus include i passaggi fra SHIFT30,
31, 32 e quelli superiori, nonché adiacenti non allineati.

I controlli freddi coprono argomenti, forme e risultato completo, inclusi
selezione64→32→16, NaN accorciabili/non accorciabili e coda fisica oltre
END. Le guardie interne e i default inattesi rimangono nel denominatore
della coverage anche quando non raggiunti dal dominio pubblico valido.
La [preregistrazione](cbor-float-scrittura-metodo.md) definisce il metodo;
gli esiti saranno distinti dall'inventario dopo le campagne.
