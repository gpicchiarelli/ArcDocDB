# Decisioni della scrittura delle stringhe CBOR

Inventario iniziale del blob `a2c5c77dd51bff760bff4508e998d94370921eda`,
prima delle campagne. Le decisioni di dipendenze già presenti non sono
riscritte. I rapporti grezzi del nuovo file conservano tutte le guardie;
nessuna esclusione o attestazione di MC/DC/100% è implicita.

| Funzione / forma | Condizioni, da sinistra | Testimoni previsti |
|---|---|---|
| `check-span-string-cbor-write` / `unless and` | array octets; START index; END index; range ordinato entro lunghezza | tipo array errato, START errato, END errato, START>END/END>lunghezza; validi e vuoti per entrambi gli span |
| `check-input-string-cbor-write` / `unless and` | budget index; budget≤16 MiB | NIL/float/negativo/bignum, 16 MiB+1, zero ed estremi validi |
| `check-overlap-string-cbor-write` / `when and` | identità array; sorgente non vuota; START<SOURCE-END; SOURCE-START<NEXT | array distinti, vuoti, sorgente prima/toccante/dopo, overlap della sola testata e del payload |
| `copia-stringa-cbor-write` / `unless and` | span≤16 MiB; span=fine-target | guardie interne; API valida garantisce entrambi prima di entrare |
| `copia-stringa-cbor-write` / `unless and` | cursor=END; read-cursor=STOP | completamento normale anche vuoto; invarianti di avanzamento interne |

Anche le relazioni con più operandi rappresentano più confronti:

| Funzione | Relazione | Confronti |
|---|---|---|
| `check-span-string-cbor-write` | `START≤END≤length(BUFFER)` | ordine span e limite fisico |
| `check-input-string-cbor-write` | `1≤header-size≤item-size` | dimensione positiva e contenuta nell'item |
| `check-overlap-string-cbor-write` | `START≤NEXT≤length(BUFFER)` | footprint ordinato e limite fisico |
| `check-overlap-string-cbor-write` | `SOURCE-START≤SOURCE-END≤length(SOURCE)` | ordine e limite sorgente |
| `copia-stringa-cbor-write` | `TARGET≤END≤length(BUFFER)` | copia ordinata e limite fisico |
| `copia-stringa-cbor-write` | `START≤STOP≤length(SOURCE)` | ordine e limite sorgente |

Conteggio sintattico dei percorsi, includendo AND/OR e loop: 6/8/7/8/5
rispettivamente per span, input, overlap, copia e wrapper pubblico. Le
guardie interne non raggiunte restano nel denominatore di coverage;
il numero di esiti verdi non chiude il gate C1 di ADR-0035. La seconda
lettura confronterà questo inventario con il codice e le prove congelate.
