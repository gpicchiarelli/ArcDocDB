# Decisioni composte della scrittura CBOR

Inventario del file `src/codec/cbor-write.lisp`, blob
`61f0d6e2783e4790ed7e19a45bba6407d6e5b3de`, prima delle campagne.
Le righe si riferiscono a questo file congelato. Quattro forme composte,
compreso l'OR annidato; nessuna rimossa dal denominatore di copertura.

| Forma | Condizioni | Evidenza e limite |
|---|---|---|
| AND, riga35 | spazio per WIDTH; parola rappresentabile nella larghezza | Percorsi riusciti per WIDTH1/2/4. Il preflight della funzione pubblica impedisce di raggiungere il fallimento della guardia interna; non si dichiara copertura delle condizioni. |
| OR, riga36 | WIDTH=4; WORD sotto 2^(8×WIDTH) | WIDTH1/2 e WIDTH4 riusciti. Nel dominio u32, per WIDTH4 anche il secondo termine sarebbe vero: il primo non ha un witness decisivo indipendente. Nessuna attestazione MC/DC. |
| AND, riga42 | progresso positivo; NEXT entro END | Tutte le larghezze e capacità esatta; i falsi interni non sono raggiungibili attraverso l'API valida. |
| AND, riga53 | buffer simple u8; START index; END index; range ordinato e fisico | Test indipendenti non-simple, START invalido con resto valido, END invalido con resto valido, range invertito/fuori buffer con tipi validi, successo. Il controllo finale è una relazione a più operandi, non un'attestazione di indipendenza per ogni confronto espanso. |

Le priorità range/major/high/low/capacità hanno test concorrenti e singoli.
Le relazioni concatenate `START≤END≤length` (riga33) e
`BEGIN≤CURSOR≤NEXT≤LIMIT` (riga84) sono inoltre guardie interne a più
operandi; rimangono nel denominatore, senza attestazione di indipendenza
per ogni confronto. La relazione del preflight è inclusa nella riga53.
Le guardie interne sono sempre attive: un mutante che supera il preflight
può essere rilevato dall'invariante. Questa evidenza locale non chiude il
gate C1 della copertura100% richiesto da ADR-0035.
