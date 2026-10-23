# Decisioni del percorso hash

Inventario per COD-54. Gli esiti del corpus e la copertura SB-Cover
non sono una dichiarazione MC/DC.

| ID | Funzione / decisione | Condizioni indipendenti |
|---|---|---|
| HASH-D01 | xxh64 / argomenti | simple u8; start index; end index; seed-high u32; seed-low u32 |
| HASH-D02 | check-range condivisa | 0 <= start <= end <= length |
| HASH-D03 | xxh64 / limite | lunghezza <= max-key-bytes; zero e massimo inclusi |
| HASH-D04 | blocchi / coda | sotto 32 oppure blocchi; 0..31 residui; lane 8, lane 4, byte |
| HASH-D05 | crea-indice-primario / seme | entrambi NIL; entrambi u32; ogni meta incompleta/non conforme |
| HASH-D06 | esigi-seme-hash / configurazione | salute; coppia assente; high assente con low; low assente con high |
| HASH-D07 | esigi-mappe-hash / array | highs simple u32; lows simple u32; lunghezze high e low; identita distinta |
| HASH-D08 | esigi-mappe-hash / seed | seed-high u32; seed-low u32 |
| HASH-D09 | calcola-digests-frammento / binding | uguaglianza high; uguaglianza low; configured; corrente/writable |
| HASH-D10 | scansione / invarianti | used dentro arena; campione/control; range chiave; lookup originale; conteggio vivo |
| HASH-D11 | hash-blocks / span | size >= 32; start + size <= length; avanzamento esatto di floor(size/32)*32 |
| HASH-D12 | hash-tail / span | start <= end; end <= length; residuo <= 31; cursor finale = end |

Le guardie originali di directory/banco/payload restano nelle rispettive
tabelle. Il seme non e cambiabile dopo la costruzione; memoria/array
privati e writer esclusivo sono precondizioni del controller.
