# 02 — Modello logico

> **Fonte:** «Architettura logica», «Serie speciale Registri», «Catalogo», «Layout fisico» della
> [specifica](specifica/prompt-originale.md).

## Gerarchia

```
Server
└── Archivio
    └── Serie
        └── Documento
```

### Server

Il processo principale. È responsabile di:

- gestione delle connessioni;
- scheduler globale;
- thread pool dinamico;
- gestione degli Archivi.

### Archivio

Contenitore logico (domain) che raggruppa più Serie. È il **livello al quale si richiedono
transazioni e snapshot multiserie**. Ogni Archivio DEVE contenere la Serie speciale
[Registri](#registri).

### Serie

Il namespace dei documenti e, soprattutto, **l'unità primaria di storage e di parallelismo**.
Una Serie:

- definisce il paradigma/contratto dei propri documenti: struttura/schema, validazione, indici,
  configurazione dello storage;
- possiede il proprio WAL, i propri segmenti, i propri indici;
- DEVE poter operare in parallelo e indipendentemente dalle altre Serie.

Tutto ciò che è fisicamente condiviso tra Serie è un potenziale punto di contesa: la specifica
lo riduce al solo `multiserie.log` (e alle risorse di calcolo governate dallo scheduler).

> **Deciso (QA-21 → [ADR-0029](adr/0029-interfacce-protocollo-query-contratto.md))** — La specifica non definisce il linguaggio dello schema/contratto né le
> regole di evoluzione dello schema.

### Documento

L'unità logica di dati. Ha un `_id` univoco **all'interno della Serie** e può avere versioni
storiche, conservate dallo storage append-only e governate da MVCC.

> **Deciso (QA-01 → [ADR-0014](adr/0014-formato-record-documento-id.md))** — Formato del documento, tipo di `_id` e codifica dei record su disco non
> sono specificati.

## Registri

Registri è una Serie speciale, obbligatoria in ogni Archivio. **Non è il WAL dei dati.**
Contiene:

- il catalogo (metadatabase) delle Serie;
- i metadati di configurazione delle Serie;
- le informazioni necessarie al recovery del catalogo;
- un singolo file persistente `multiserie.log`.

`multiserie.log` è il *transaction decision log* delle transazioni che coinvolgono più Serie
(vedi [05 Transazioni](05-transazioni.md)). Ne esiste **uno solo per Archivio**: NON DEVE
esistere un file separato per ogni transazione.

> **Deciso (QA-10 → [ADR-0022](adr/0022-registri-come-serie-catalogo.md))** — Registri è definita «Serie speciale», ma il layout indicativo mostra solo
> `catalog/` e `multiserie.log`. Resta da decidere se il catalogo è memorizzato con il normale
> meccanismo di una Serie (WAL + segmenti propri) o con un formato dedicato, e come avviene il
> bootstrap (per aprire le Serie serve il catalogo, che a sua volta va recuperato per primo).

## Catalogo

`Registri/catalog/` contiene il catalogo delle Serie. Per ogni Serie memorizza almeno:

| Campo | Note |
|---|---|
| nome | identifica la Serie nell'Archivio |
| configurazione | parametri generali |
| schema/contratto | struttura e validazione dei documenti |
| configurazione degli indici | quali indici secondari e di che tipo ([08](08-indici.md)) |
| segment configuration | es. dimensione target del segmento (default ~256 MB) |
| stato | stato della Serie |
| metadata per il recovery | quanto serve al [Recovery Manager](11-recovery.md) |

Il catalogo DEVE essere modificabile in modo **transazionale e crash-safe**: creare, modificare
o eliminare una Serie non può lasciare il catalogo in uno stato intermedio dopo un crash.

## Layout fisico

Struttura indicativa su disco:

```
Archivio/
├── Registri/
│   ├── catalog/
│   └── multiserie.log
│
├── Serie-A/
│   ├── wal/
│   ├── segments/
│   └── index/
│
├── Serie-B/
│   ├── wal/
│   ├── segments/
│   └── index/
│
└── ...
```

Regole:

- ogni Serie rimane **fisicamente indipendente** (INV-W1);
- NON DEVE esistere un global data WAL (INV-W1);
- l'unico log condiviso a livello di Archivio è `Registri/multiserie.log` (INV-W2).

> **Deciso ([ADR-0022](adr/0022-registri-come-serie-catalogo.md))** — Poiché le directory delle Serie sono sorelle di `Registri/`, il nome
> `Registri` va riservato: nessuna Serie utente può chiamarsi così. Conviene inoltre che il nome
> della directory sia un identificatore interno stabile e non il nome logico della Serie, così
> una rinomina è una modifica del solo catalogo.

## Parallelismo gerarchico

```
Server → Archivio → Serie → writer/readers → WAL → compaction → query/index operations
```

La Serie è l'unità principale di **isolamento del carico**: una Serie molto trafficata non deve
bloccare le altre (INV-P3). Dettagli in [10 Concorrenza e scheduling](10-concorrenza-e-scheduling.md).
