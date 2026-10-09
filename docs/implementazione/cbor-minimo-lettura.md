# Testate CBOR minime — prima lettura C1

Lettura indipendente dell'autore del kernel, svolta dal coordinatore di
contratto, ASDF e campagne. La seconda lettura è affidata all'autore
dell'oracolo, dopo il congelamento dei suoi test. Nessun rilievo statico
aperto nei due nuovi file; gli esiti runtime sono registrati separatamente.

| Punto della lista C1 | Riscontro |
|---|---|
| 1. Requisiti e ADR | REQ-LIM-002, REQ-AFF-004/008, ADR-0014/0048; confine locale esplicito. |
| 2. Invarianti | Buffer immutabile, larghezze e progresso, parole separate; INV-F1/A8/P6. |
| 3. Errori | Il parser di base precede `:cbor-nonminimal`; offset del lead; guardie interne tipizzate. |
| 4. Limiti | Nessun ciclo nuovo, ricorsione o attesa; lettura massima nove byte. |
| 5. Allocazioni | Operazioni su fixnum e parole u32; misura distinta richiesta, senza deduzione dal solo codice. |
| 6. Dati verificati | Sei valori restituiti soltanto dopo sintassi e larghezza minima; nessun payload attestato. |
| 7. Decisioni | Inventario con confronto alle forme sorgenti; copertura e mutazioni conservate separatamente. |
| 8. Proprietario | Solo variabili locali e buffer in sola lettura, nessuna factory o scratch. |
| 9. Tracciabilità | ASDF e scope dedicato predisposti; `make check` è il controllo di integrazione. |
| 10. Standard | FTYPE, docstring, guardie, safety 3, funzioni brevi; nessuna deviazione introdotta. |
| 11. Parallelismo | Nessun lock, scrittura condivisa o rendezvous nel prodotto. |
| 12. Durabilità | Modulo puro: nessun cambiamento durevole o eliminazione. |

I campi IEEE sono confrontati senza costruire float. Per binary32, il campo
esponente normale di binary16 corrisponde a 113–142; quello subnormale a
103–112, con divisibilità del significando per `2^(126-exp)`. Per binary64,
binary32 normale corrisponde a 897–1150 e subnormale a 874–896, con
divisibilità per `2^(926-exp)`, verificata su parole separate. Il padding
richiede 13 bit nulli per 32→16 e 29 per 64→32 nei casi normali e speciali.
Lo zero richiede significando nullo; un subnormale sorgente non nullo è
troppo piccolo per la destinazione. I test usano un oracolo razionale
generale, distinto da queste soglie del kernel.

Segno e payload non vengono modificati; la presenza di una rappresentazione
più corta non dipende dal segno. Le guardie sugli allineamenti controllano
le postcondizioni dei predicati, senza effetti sul buffer. Non si attesta
irraggiungibilità dei rami interni dal solo risultato della copertura.
