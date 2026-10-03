# ADR-0022 — Registri è una Serie; il catalogo è fatto di documenti

- **Stato:** Accettata
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-10; realizza «Serie speciale Registri», «Catalogo»
- **Riferimenti:** [architettura](../architettura.md#archivio-e-registri), RSK-15

## Decisione

1. **Registri è una Serie a tutti gli effetti**, con storage in `Registri/catalog/`
   (`wal/`, `segments/`, `index/` al suo interno) e configurazione **incorporata nel codice**
   (durability `:strong`, segmento target 16 MB, indice secondario sul nome). Non è
   modificabile né eliminabile dall'utente.
2. **Ogni Serie è un documento** di Registri, con `_id` = identificatore interno stabile
   (16 byte generato) e corpo CBOR: nome, stato, configurazione, contratto, indici,
   configurazione dei segmenti, metadata di recovery. La directory della Serie è
   `<Archivio>/<id-esadecimale>/`; il nome logico vive solo nel catalogo (rinomina = una
   scrittura).
3. **Creazione di una Serie** (transazione single-Series su Registri): si crea la directory
   con i file iniziali e la si sincronizza; poi si scrive il documento con stato `creating`;
   si apre la Serie; si aggiorna il documento a `active`. Al riavvio, una directory senza
   documento o con stato `creating` viene rimossa; `dropping` viene completata.
4. **Bootstrap:** il recovery apre Registri per prima (configurazione nota a priori), legge
   il catalogo, poi apre le altre Serie in parallelo.
5. `multiserie.log` vive in `Registri/` accanto a `catalog/` ed è gestito dal coordinatore
   dell'Archivio, non dal writer di Registri.
6. Il nome `Registri` è riservato.

Pattern: catalogo di sistema memorizzato nel motore stesso (PostgreSQL `pg_catalog`).

## Conseguenze

- Un solo meccanismo di durability per dati e catalogo; il catalogo eredita transazioni,
  recovery e fault injection.
- La circolarità si scioglie con la configurazione costante di Registri.
- Le operazioni DDL seguono una macchina a stati esplicita (`creating`, `active`,
  `dropping`) ripetibile dopo un crash.

## Alternative considerate

- *File di catalogo riscritto atomicamente:* un secondo meccanismo da verificare, nessun
  vantaggio.

## Valutazione

- Verifica: fault injection su creazione/eliminazione di Serie (scenario da aggiungere al
  catalogo FI come FI-13).
