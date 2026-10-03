# Valutazione architetturale

Questa sezione valuta l'architettura descritta dalla
[specifica](../specifica/prompt-originale.md) **prima** dell'implementazione: che cosa regge,
che cosa è ancora indefinito, che cosa è rischioso e come lo si verifica.

> **Natura di questi documenti.** È una valutazione *preliminare*, fatta a tavolino. Le stime
> sono ordini di grandezza con ipotesi dichiarate, non misure. Ogni conclusione è da
> confermare o smentire con gli spike; i documenti vanno aggiornati con i risultati.

## Documenti

| Documento | Contenuto |
|---|---|
| [Analisi critica](analisi-critica.md) | Punti di forza, tensioni interne alla specifica, lacune di progetto |
| [Stime di ordine di grandezza](stime-ordine-di-grandezza.md) | Plausibilità dei target rispetto ai limiti dell'hardware |
| [Registro dei rischi](registro-rischi.md) | Rischi `RSK-…` con esposizione, mitigazione e verifica |
| [Piano degli spike](piano-spike.md) | Esperimenti `SPK-…` che misurano le ipotesi critiche |

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

**Decisioni che spettano all'autore.** [ADR-0028](../adr/0028-target-e-obiettivi-di-latenza.md)
(target e latenze) e [ADR-0030](../adr/0030-scope-v1.md) (scope) sono in stato *Proposta*.

**Verdetto.** Il progetto è completo sul piano dei meccanismi: ogni modulo ha un pattern
assegnato, un formato persistente e un criterio di verifica. La Fase 0 si chiude con
l'esecuzione di SPK-01, SPK-02, SPK-03 e del modello SPK-07, che confermano o sostituiscono
(con nuovi ADR, non con ritocchi) le ipotesi quantitative.
