# Stime di ordine di grandezza

> **Non sono misure.** Sono calcoli a tavolino per verificare se i
> [target preliminari](../13-benchmark.md#target-preliminari) sono compatibili con i limiti
> fisici dell'[hardware di riferimento](../13-benchmark.md#hardware-di-riferimento). Le cifre
> sull'hardware sono valori tipici indicativi, da sostituire con quelli misurati sulla macchina
> reale (SPK-03, SPK-05). Servono a capire *dove* sta il limite, non a prevedere un risultato.

## Banda di scrittura

Banda = operazioni/s × dimensione del documento (senza intestazioni né compressione).

| Target INSERT | Documento 1 KB | Documento 4 KB |
|---|---|---|
| 300k ops/s (group commit, minimo) | 0,3 GB/s | 1,2 GB/s |
| 1 M ops/s (group commit, massimo) | 1 GB/s | 4 GB/s |
| 2 M ops/s (async, massimo) | 2 GB/s | 8 GB/s |

Termine di paragone: un NVMe PCIe 4 ha un tetto di interfaccia intorno a 7–8 GB/s in scrittura
sequenziale, e la banda *sostenuta* è di norma sensibilmente più bassa; PCIe 5 circa il doppio.

Conseguenze:

1. Con documenti da 4 KB la fascia alta dei target di INSERT è **al limite o oltre** un singolo
   dispositivo PCIe 4, anche scrivendo ogni record una sola volta.
2. Se ogni record è scritto due volte (WAL + segmento, opzioni a/b di QA-02) la banda
   necessaria raddoppia: il limite si incontra già a metà della fascia.
3. La stessa banda è contesa da CLEAN e MERGE, che scrivono segmenti nuovi.

→ La fascia alta è raggiungibile solo con documenti piccoli, una sola scrittura per record,
compressione o più dispositivi. È l'argomento principale per decidere QA-02. Vale anche come
conferma del principio di priorità INV-P4: sul dispositivo il WAL deve prevalere sulla
compaction.

## Rotazione dei segmenti

Una Serie che scrive 1 GB/s riempie un segmento da 256 MB in circa 0,25 s: ~4 segmenti al
secondo, ~4.000 segmenti per TB.

- La rotazione deve essere un'operazione economica e non bloccante per il writer.
- La regola dei 50 s non pesa su questi segmenti: nascono a dimensione piena e non sono
  candidati al MERGE. Riguarda i segmenti piccoli prodotti dal CLEAN.
- Il numero di segmenti per Serie è nell'ordine delle migliaia: metadata, Bloom filter e file
  aperti vanno dimensionati di conseguenza.

## Memoria del primary index

Ipotesi: entry compatta con impronta della chiave, segment-id, offset, length, version —
nell'ordine di 24–32 byte — più lo spazio libero della tabella. Stima: **30–40 byte per
documento**, escluso lo spazio per `_id` di lunghezza variabile.

| Documenti | Indice | Dati live a 2 KB/doc |
|---|---|---|
| 100 milioni | 3–4 GB | 200 GB |
| 1 miliardo | 30–40 GB | 2 TB |

→ Su una macchina da 64–128 GB il primary index limita la capacità a qualche miliardo di
documenti per server, e a 1 miliardo occupa già una quota importante della RAM, in concorrenza
con la cache. Questa memoria non deve essere lavoro per il GC (QA-18).

## Tempo di riavvio

| Strategia (QA-03) | Lavoro al riavvio per 1 miliardo di documenti / 2 TB | Ordine di grandezza |
|---|---|---|
| Ricostruzione dai segmenti | leggere 2 TB a 1–5 GB/s | da ~7 a ~35 minuti |
| File di hint per segmento | leggere ~30–40 GB e reinserire 1 miliardo di entry | decine di secondi – pochi minuti |
| Checkpoint della tabella | caricare 30–40 GB + replay del WAL recente | decine di secondi |

→ La ricostruzione completa è accettabile come rete di sicurezza (l'indice è un dato
derivato), non come percorso normale di riavvio. Il recovery parallelo per Serie riduce i
tempi solo se i dati sono distribuiti su più Serie.

## Budget del writer logico

Un writer per Serie significa che la parte seriale di ogni scrittura è eseguita da un solo
core alla volta.

| Throughput su una Serie | Tempo disponibile per operazione nella parte seriale |
|---|---|
| 300k ops/s | ~3,3 µs |
| 1 M ops/s | 1 µs |
| 2 M ops/s | 0,5 µs |

Costi tipici della parte seriale: aggiornamento dell'indice con probabile cache miss (~0,1 µs),
copia di un record da 2 KB nel buffer (~0,1–0,2 µs), controllo di versione, contabilità.
L'ordine di grandezza è compatibile con ~1 M ops/s per Serie **solo se** nella parte seriale
non c'è altro: niente parsing, validazione, allocazione, aggiornamento sincrono di indici
secondari. A 2 M ops/s su una singola Serie non resta margine.

→ I target di scrittura sono verosimili come *aggregato su più Serie*; come valore *per
singola Serie* la fascia alta è al limite. Per questo QA-26 va chiarita subito, e gli indici
secondari (QA-25) vanno valutati rispetto a questo budget.

## Letture puntuali

**Da cache/indice.** 1–4 M ops/s aggregati su 16–32 core equivalgono a 4–16 µs per operazione
per core: ampio per una ricerca in memoria. Il costo dominante sarà protocollo e rete, più
l'eventuale allocazione per richiesta.

**Da NVMe.** Una lettura casuale costa nell'ordine di 0,1 ms. Con I/O bloccante un thread
esegue quindi ~10.000 letture al secondo: per 150k–600k ops/s servono da 15 a 60 letture in
volo contemporaneamente.

→ La fascia alta richiede più thread bloccati in I/O di quanti siano i core, oppure I/O
asincrono. Il thread pool dinamico deve distinguere i worker che usano CPU da quelli in attesa
di I/O (QA-19), e la scelta va fatta con il vincolo «solo Common Lisp».

## Group commit

Sia *f* la durata di un flush. Una Serie può fare al più 1/*f* flush al secondo; ogni
transazione attende in media circa un flush.

| Durata del flush | Flush/s per Serie | Dimensione del gruppo a 300k ops/s | Latenza aggiunta |
|---|---|---|---|
| 0,1 ms | 10.000 | 30 | ~0,1 ms |
| 1 ms | 1.000 | 300 | ~1 ms |
| 5 ms | 200 | 1.500 | ~5 ms |

- La latenza delle scritture durevoli non può scendere sotto la durata del flush: l'obiettivo
  numerico di P99 (QA-26) deve tenerne conto, distinto per livello di durability.
- Un WAL per Serie significa **N flussi di flush concorrenti** sullo stesso dispositivo. Se il
  dispositivo serializza i flush, il vantaggio dell'indipendenza tra Serie si riduce proprio
  sul percorso durevole. È un'ipotesi da misurare (SPK-03), con impatto diretto su ADR-0003.

## Transazioni multiserie

Latenza minima di un commit multiserie: flush dei PREPARE (in parallelo sui partecipanti) +
flush della decisione = **due flush in sequenza**. Throughput: limitato dai gruppi di
`multiserie.log` (flush/s × transazioni per gruppo); con 1.000 flush/s servono gruppi da
decine a centinaia di transazioni per arrivare a decine–centinaia di migliaia di tx/s.

→ Il target è plausibile se i gruppi si formano bene. Ogni transazione multiserie consuma
inoltre il budget del writer di ciascun partecipante almeno due volte (PREPARE ed esito).

## Garbage collector

Ipotesi di carico: 1 M richieste/s. Se ogni richiesta alloca 1 KB nello heap gestito, il tasso
di allocazione è 1 GB/s: una collezione della generazione giovane più volte al secondo, e a
ogni collezione **tutti** i thread si fermano.

→ «Nessuna allocazione sul hot path» è un requisito architetturale, non una rifinitura: va
considerato nel disegno delle interfacce tra moduli (buffer riutilizzati, risultati scritti in
memoria fornita dal chiamante). La durata delle pause con heap di decine di GB è la misura che
SPK-02 deve produrre.

## Riepilogo

| Target | Giudizio a tavolino | Dipende da |
|---|---|---|
| GET da cache/indice | plausibile | protocollo, allocazioni, GC |
| GET da NVMe | plausibile nella fascia bassa; fascia alta richiede I/O molto concorrente | QA-19 |
| INSERT / UPDATE / DELETE | plausibile come aggregato; fascia alta al limite del dispositivo con documenti grandi | QA-02, QA-26 |
| Query indicizzata | non valutabile: dipende da QA-25 e dal Query Engine | QA-25 |
| Scan sequenziale, CLEAN | plausibili: lavoro sequenziale limitato dal dispositivo | priorità di I/O |
| Transazioni multiserie | plausibile se il group commit forma gruppi ampi | QA-06, QA-07 |
| Bassa latenza P95/P99 | **non valutabile senza un obiettivo numerico** | QA-26, SPK-02 |
