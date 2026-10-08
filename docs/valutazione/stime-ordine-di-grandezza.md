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

Misura locale v1: 64,22656 B/documento di payload degli array a 100.000
documenti, prima e dopo 50.000 sostituzioni di chiave
([campagna 2026-10-08](risultati-2026-10-08.md)). Esclusi header, runtime,
garbage e frammenti trattenuti: non sostituisce le stime di capacità v2.
Il costo della directory e della memoria transitoria è separato da C slot
([ADR-0050](../adr/0050-pubblicazione-e-costi-della-directory.md)).

A 10 milioni di documenti il payload v1 misurato è 82,2099968 B/doc,
822.099.968 byte. Il dato supera il valore a 100.000 documenti perché cambia
il riempimento dei frammenti; non è una capacità garantita o un dato v2.

Layout deciso in [ADR-0043](../adr/0043-primary-index-a-frammenti.md): frammenti a capacità
fissa, 1 byte di controllo + 4 parole da 64 bit per slot (CSN, location, chiave e lunghezza,
contatore seqlock) = **33 byte per slot**, più le chiavi nell'area locale del frammento (16
byte per gli id generati).

Il costo per documento dipende dal riempimento, che in una tabella a hashing estendibile
oscilla per ogni frammento tra 7/16 (subito dopo una divisione) e 7/8 (subito prima):

| Riempimento | Slot | Chiave (id 16 B, area al 75 %) | Totale per documento |
|---|---|---|---|
| massimo (7/8) | ~38 B | ~18 B | ~56 B |
| medio atteso (~0,61) | ~54 B | ~21 B | **~75–80 B** |
| minimo (7/16) | ~75 B | ~37 B | ~112 B |

| Documenti | Memoria dell'indice (media) | Dati live a 2 KB/doc |
|---|---|---|
| 100 milioni | ~8 GB | 200 GB |
| 1 miliardo | ~80 GB | 2 TB |

→ Con ~15 % della RAM riservato a cache e runtime, un server da 64 GB ospita circa **650
milioni** di documenti e uno da 128 GB circa **1,3 miliardi**. Questa memoria non è lavoro per
il GC ([ADR-0024](../adr/0024-memoria-e-gc.md)). I documenti eliminati non occupano memoria.

Nota sulla stima precedente («56 byte per entry», 750 milioni per 64 GB): era il valore al
riempimento massimo di una tabella unica, vero solo nell'istante prima di un raddoppio; la
stessa tabella, in media, costava più di 90 byte per documento e durante il raddoppio
richiedeva il triplo della memoria ([analisi progettuale](../analisi-progettuale.md#ap-12)).
Il riempimento medio effettivo è una delle misure di SPK-01.

## Tempo di riavvio

| Strategia (QA-03) | Lavoro al riavvio per 1 miliardo di documenti / 2 TB | Ordine di grandezza |
|---|---|---|
| Ricostruzione dai segmenti | leggere 2 TB a 1–5 GB/s | da ~7 a ~35 minuti |
| File di hint per segmento | leggere ~24 GB di entry più le chiavi e reinserire 1 miliardo di entry, in parallelo e in qualsiasi ordine | decine di secondi – pochi minuti |
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

Il **CRC** merita una riga a sé. Un CRC32C tabellare in Common Lisp costa nell'ordine di
1–2 µs per un record da 2 KB (stima, SPK-09): se lo calcolasse il writer, da solo consumerebbe
gran parte del budget a 300k ops/s. Per questo il record ha due CRC
([ADR-0039](../adr/0039-cornice-unica-dei-record.md)): quello del corpo è calcolato dal worker
della richiesta, in parallelo; il writer calcola solo quello dell'intestazione, 20 byte.

→ I target di scrittura sono verosimili come *aggregato su più Serie*; come valore *per
singola Serie* la fascia alta è al limite. Per questo QA-26 va chiarita subito, e gli indici
secondari (QA-25) vanno valutati rispetto a questo budget.

## Letture puntuali

> **Proposta** — La [prima campagna SPK-04](risultati-SPK-04-2026-10-08.md)
> misura soltanto il drain di code sintetiche con start/join e strumentazione.
> I dati conservati non confermano il budget seriale del writer: sono esclusi
> record, CRC, indice, commit durevole e produttori concorrenti durante il drain.


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
  numerico di P99 (QA-26) deve tenerne conto, distinto per livello di durability. Con un
  compito di I/O alla volta per log ([ADR-0037](../adr/0037-lotto-sigillato.md)) una scrittura
  attende tra uno e due flush: quello in corso al suo arrivo e il proprio.
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

## Revisione v2 (ADR-0048)

Le tabelle precedenti stimano il layout v1. V2 costa 41 B/slot invece di 33: +8/occupazione B per documento (circa +9,1 a carico 7/8, +18,3 a 7/16), oltre alle chiavi. Con 16 B di chiave e le precedenti ipotesi medie, circa 88 B/documento; 64 GB decimali con 15 % riservato darebbero circa 618 milioni, **stima illustrativa**. Chiavi grandi riducono molto la capacità. Rimisurare in SPK-01; nessuna capacità del modo oltre RAM è dimostrata.
