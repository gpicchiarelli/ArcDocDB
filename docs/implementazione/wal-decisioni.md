# Decisioni dei lotti WAL

Inventario COD-54; [test](../../tests/wal/), ID REQ nei nomi. Non certifica MC/DC.

| Decisione composta | Casi |
|---|---|
| Configurazione kind/file-id/versione | segmento, control/multiserie id zero, control id non zero, v1/v2 |
| Budget lotto | minimo SEAL, esatto ultimo record+SEAL, byte insufficienti, count pieno, budget 0/oltre tetto |
| Record ordinario e non prepared | PUT/tombstone/EDIT ristampati; prepared PUT, OUTCOME e DECISION preservati |
| durable ≤ start e end nel fixnum | offset zero/non zero, frontiera storica, falsa frontiera futura, overflow |
| Identità e contiguità del gruppo | file-id/log/versione errati, primo lotto, secondo contiguo e fuori ordine |
| Budget lotti oppure byte | gruppo esatto, slot pieno, byte pieni; file troppo piccolo per l'intero gruppo |
| async su log dati | written/durable coperti; sealed/faulted esclusi, async control/multiserie rifiutato |
| Proprietà lotto/log/gruppo | doppio gruppo, lotto già posseduto, riuso prematuro, ready annullato, flush concorrenti |

I guardrail interni e i percorsi di corruzione delle strutture private restano nel
denominatore sb-cover, insieme a definizioni e proclamazioni. I CAS di concorrenza
non sono qualificati da una percentuale di copertura: i test usano eventi espliciti
per forzare un flush in corso e provare il rifiuto degli altri. Timeout limitano
le fixture, non sono argomenti di correttezza. Serve ancora revisione C1 indipendente.
