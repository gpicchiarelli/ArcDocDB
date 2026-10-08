# Valutazione architetturale

[Documentazione](../README.md) · [Esperimenti](../../spikes/README.md) · [Roadmap](../roadmap.md)

Questa sezione valuta l'architettura descritta dalla
[specifica](../specifica/specifica-originale.md) **prima** dell'implementazione: che cosa regge,
che cosa è ancora indefinito, che cosa è rischioso e come lo si verifica.

> **Natura di questi documenti.** È una valutazione *preliminare*, fatta a tavolino. Le stime
> sono ordini di grandezza con ipotesi dichiarate, non misure. Ogni conclusione è da
> confermare o smentire con gli spike; i documenti vanno aggiornati con i risultati.

## Documenti

| Documento | Contenuto |
|---|---|
| [SPK-08, bitmap](risultati-SPK-08-bitmap-2026-10-08.md) | Conteggio su array byte/u64, codice generato e confronto locale senza packing |
| [Analisi critica](analisi-critica.md) | Punti di forza, tensioni interne alla specifica, lacune di progetto |
| [Stime di ordine di grandezza](stime-ordine-di-grandezza.md) | Plausibilità dei target rispetto ai limiti dell'hardware |
| [Registro dei rischi](registro-rischi.md) | Rischi `RSK-…` con esposizione, mitigazione e verifica |
| [Piano degli spike](piano-spike.md) | Esperimenti `SPK-…` che misurano le ipotesi critiche |
| [Risultati locali 2026-10-08](risultati-2026-10-08.md) | Campagna seriale, output grezzi, ottimizzazioni, limiti e lavoro restante |
| [Registro delle prove](registro-delle-prove.md) | Schema, metadata, conservazione di prove, diagnostiche, fallimenti e benchmark |
| [SPK-04, prima campagna](risultati-SPK-04-2026-10-08.md) | Writer su pool, attese limitate, modelli di lettura e benchmark diagnostici |
| [SPK-05, prima campagna](risultati-SPK-05-2026-10-08.md) | Letture reali pread/mmap, verifica dei record, allocazioni e confronto locale |
| [SPK-06, prima campagna](risultati-SPK-06-2026-10-08.md) | Modello finito del carico, quote e interferenza locale di copie con letture |
| [SPK-07 e SPK-08, avanzamento](risultati-SPK-07-08-2026-10-08.md) | Crash sui byte, due lettori SC, maschere esatte e benchmark NEON/SWAR |
| [SPK-01, lettura in buffer](risultati-SPK-01-lettura-2026-10-08.md) | Oracolo indipendente, validazione statica, u64 alti e 80 campioni a coppie |

## Criteri di valutazione

L'architettura e ogni alternativa nelle [questioni aperte](../questioni-aperte.md) si giudicano
su questi criteri, in ordine di importanza:

| # | Criterio | Domanda |
|---|---|---|
| 1 | **Correttezza** | Gli [invarianti](../invarianti.md) sono garantiti per costruzione o dipendono da disciplina? Il protocollo è verificabile su modello? |
| 2 | **Prevedibilità** | Che cosa succede a P99 sotto burst, compaction e GC? Esistono punti di stallo globale? |
| 3 | **Isolamento tra Serie** | Quali risorse restano condivise e come sono governate? |
| 4 | **Prestazioni** | Il hot path è compatibile con i target? Dove sta il limite fisico? |
| 5 | **Recuperabilità** | Quanto dura un riavvio? Ogni stato intermedio è riconoscibile? |
| 6 | **Costi di spazio e scrittura** | Amplificazione di scrittura, spazio trattenuto da versioni e snapshot |
| 7 | **Realizzabilità in Common Lisp/SBCL** | Si può fare senza codice foreign, senza allocare sul hot path, con il GC disponibile? |
| 8 | **Complessità** | Quanti meccanismi distinti di durability e concorrenza vanno verificati? |

## Sintesi preliminare

**Impianto.** L'architettura è coerente e conservativa nelle scelte che contano per la
correttezza. Storage append-only, segmenti immutabili e compaction copy-on-write rendono la
crash-safety in larga parte *strutturale*: un file immutabile non si può corrompere a metà, e
un'operazione che scrive solo file nuovi si può sempre ripetere. L'indipendenza fisica delle
Serie dà un modello di isolamento semplice da ragionare. Il parente più vicino è il modello
«log append-only + indice delle chiavi in memoria» (reso noto da Bitcask), qui esteso con
partizionamento per Serie, MVCC, transazioni multi-partizione e una compaction a due
operazioni distinte.

**Che cosa manca.** La specifica fissa bene i *comportamenti* e lascia aperti alcuni
*meccanismi*. Sei sono strutturali e vanno decisi prima di qualsiasi formato su disco:

1. come il primary index concilia scritture continue, snapshot e rilocazione (QA-24);
2. come un record passa da WAL a segmento e quante volte viene scritto (QA-02);
3. dove vive l'insieme autorevole dei segmenti e come si rende atomico lo swap (QA-04);
4. come si ordina il commit a livello di Archivio per gli snapshot multiserie (QA-06);
5. che cosa accade a un documento tra PREPARE e decisione (QA-07);
6. quali strutture vivono nello heap di SBCL e quali fuori (QA-18).

**Rischi principali.**

- *GC di SBCL contro P99* (RSK-01): è il rischio che più dipende dalla piattaforma scelta e
  meno dall'architettura. Va misurato per primo.
- *Primary index* (RSK-02): tre requisiti sulla stessa struttura; un errore qui si paga in
  ogni operazione.
- *Banda di scrittura* (RSK-03): la fascia alta dei target di INSERT, con documenti da 4 KB,
  è al limite fisico di un singolo dispositivo NVMe anche con una sola scrittura per record.
- *Transazioni multiserie* (RSK-05): correttezza della visibilità atomica e gestione dello
  stato PREPARED senza bloccare il writer della Serie.

**Indicazione.** Nessun elemento emerso finora invalida l'architettura. La fattibilità delle
prestazioni dichiarate dipende però da due verifiche che non si possono fare a tavolino — GC e
primary index in SBCL — e da un chiarimento sui target (QA-26). L'ordine di lavoro proposto è
nella [roadmap](../roadmap.md#ordine-consigliato-parte-restante).

## Rivalutazione 2026-10-03

Le 26 questioni aperte sono state chiuse con gli ADR 0013–0030, scegliendo per ciascuna il
pattern con il miglior track record noto ([principi](../principi-di-ingegneria.md)). Il
progetto consolidato è in [architettura.md](../architettura.md) e
[formati-su-disco.md](../formati-su-disco.md). Giudizio sui criteri:

| Criterio | Prima | Dopo | Perché |
|---|---|---|---|
| Correttezza | meccanismi non definiti | definiti e modellabili | swap = un record (ADR-0018); CSN con attesa delle multiserie in applicazione (ADR-0020); presumed abort e intenti (ADR-0021); invarianti INV-F1, INV-V1…V4 |
| Prevedibilità | dipende dal GC | dipende dal GC, con criterio numerico | zero allocazione e array senza puntatori (ADR-0024); pausa ≤ 5 ms come criterio di SPK-02 (ADR-0028); writer mai bloccato su I/O (ADR-0019) |
| Isolamento tra Serie | buono | buono, quantificato | un incremento atomico per lotto è l'unico costo condiviso ([architettura](../architettura.md#archivio-coordinamento-minimo)) |
| Prestazioni | banda al limite con doppia scrittura | 1× scrittura | log-structured (ADR-0013); indici per segmento senza lavoro extra nel writer (ADR-0026) |
| Recuperabilità | riavvio proporzionale ai dati | proporzionale ai documenti | hint per segmento (ADR-0015); ogni stato intermedio riconoscibile dal control log |
| Costi di spazio | non quantificati | quantificati | ~56 B/entry di indice; record morti delle transazioni abortite recuperati dal CLEAN |
| Realizzabilità in Common Lisp | da verificare | progettata senza codice foreign | chiamate di sistema via contrib (ADR-0017); CBOR/CRC/hash propri (ADR-0027) |
| Complessità | 18 moduli, meccanismi aperti | un meccanismo per problema | un solo log dati, un solo log strutturale, un solo codec, una sola politica di memoria |

**Rischi dopo le decisioni.** Vedi lo [stato aggiornato](registro-rischi.md#stato-dopo-gli-adr-2026-10-03).
Restano aperti sul piano quantitativo: RSK-01 (GC: SPK-02), RSK-02 nella sola parte
prestazionale (SPK-01), RSK-03 residuo sui flush concorrenti (SPK-03). Tutti gli altri sono
mitigati dal progetto o accettati esplicitamente.

**Analisi progettuale.** Dopo questa rivalutazione l'insieme delle decisioni è stato riletto
come un tutto ([analisi progettuale](../analisi-progettuale.md)). Tre righe della tabella
sopra erano ottimistiche: la **correttezza** aveva cinque difetti (uno snapshot poteva
cambiare vista; un crash ordinario poteva diventare un guasto; la regola dei tombstone poteva
far riapparire documenti eliminati; un esito poteva essere scartato prima dei record che
risolve; il CSN poteva invertire un ordine causale); i **costi di spazio** dell'indice
valevano solo al riempimento massimo; la **complessità** contava più meccanismi del
necessario. Gli ADR 0036–0045 chiudono i rilievi e riducono i meccanismi: un punto di
atomicità per operazione, una cornice di record, un tipo di record per log di controllo, una
tabella concorrente. Il giudizio sull'impianto non cambia; cambia la fiducia nei dettagli,
che ora poggia su controesempi cercati e non trovati più, e che il modello SPK-07 deve
confermare.

**Decisioni dell'autore (2026-10-08).** [ADR-0028](../adr/0028-target-e-obiettivi-di-latenza.md)
(target e latenze) e [ADR-0030](../adr/0030-scope-v1.md) (scope) sono confermati, incluse le
revisioni su minimi, backup e verificatore.

**Prime evidenze eseguibili (2026-10-08).** SPK-07 trova un blocco dell'orizzonte con anello
di quattro parole e due commit pendenti: la distanza dei CSN può crescere senza violare i
crediti. [ADR-0046](../adr/0046-orizzonte-con-registro-limitato.md) lo sostituisce con il
registro limitato dei soli pendenti. Il modello corretto supera la configurazione finita;
il controllo negativo conserva il controesempio. I risultati degli spike restano distinti
dalla verifica dei requisiti del motore, che conservano lo stato `progettato`.

**Verdetto.** Il progetto è completo sul piano dei meccanismi: ogni modulo ha un pattern
assegnato, un formato persistente e un criterio di verifica. La Fase 0 si chiude con
l'esecuzione di SPK-01, SPK-02, SPK-03 e del modello SPK-07, che confermano o sostituiscono
(con nuovi ADR, non con ritocchi) le ipotesi quantitative.

## Evidenze locali 2026-10-08

La [prima campagna](risultati-2026-10-08.md) completa i cinque runner: indice v1
a 100.000 documenti, GC a 128 MiB con 48 profili, 12 casi append/flush, modelli
finiti e CRC/OUTCOME. L'inlining del verificatore conserva `safety 3` ed elimina
le allocazioni osservate nel benchmark anche per CSN massimo. Il throughput
dell'indice iniziale non nasconde 152 byte allocati per lookup: è il primo
percorso da ottimizzare. La directory ha costo separato dagli slot
([ADR-0050](../adr/0050-pubblicazione-e-costi-della-directory.md)).

GC con molti worker attivi e flush durevoli concorrenti restano vincoli da
misurare nel pool reale. I risultati sono locali e v1: non chiudono i minimi,
il gate v2, le scale superiori, la piattaforma Linux o il modello completo.

La replica dell'indice v1 a **10 milioni di documenti** completa gli INSERT,
misura 2,098 M GET/s e 82,21 B/doc di payload. L'inlining riduce le allocazioni
GET a circa 48 B/op nel campione da 100.000; il massimo split alla scala maggiore
è 98,827 ms. Restano profiling, scala superiore e v2: non si chiude il rischio.

SPK-10 aggiunge controlli e misure **v2** separati: codec, indice a cinque parole,
CBOR iterativo e migrazione su modello. L'integrazione attraversa fileheader,
record, documento, hint e indice con chiavi fino a 65.535 byte, profondità 100
e record massimo di 16.842.775 byte. Le parti escluse sono dichiarate nel
[risultato](risultati-2026-10-08.md#spk-10--limiti-v2-e-integrazione).
Il [registro strutturato](registro-delle-prove.md) conserva anche fallimenti e
varianti smentite; `make check` e la CI raccolgono output e metadata della verifica.

> **Proposta** — [SPK-06](risultati-SPK-06-2026-10-08.md) verifica la policy
> del carico su tracce finite e misura separatamente copie buffered concorrenti
> a letture pread. Il modello usa segnali iniettati e non governa le copie della
> campagna I/O. Restano calibrazione sul dispositivo, feedback reale e verifica
> del P99 durante CLEAN/MERGE del motore sulla piattaforma di riferimento.
