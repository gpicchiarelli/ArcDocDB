# ADR-0050 — Pubblicazione e costi della directory dell'indice

- **Stato:** Accettata; modello di memoria e scala da verificare.
- **Data:** 2026-10-08
- **Rapporto con la specifica:** nessuna emenda; precisa i punti 2 e 3 e le
  conseguenze di [ADR-0043](0043-primary-index-a-frammenti.md). Vale anche per
  il layout v2 di [ADR-0048](0048-limiti-documentali-e-formato-v2.md).
- **Riferimenti:** INV-I3, INV-A8, REQ-IDX-007,
  [SPK-01](../../spikes/SPK-01-primary-index/README.md).

## Contesto

L'esperimento usa una root immutabile, pubblicata con CAS. Ogni split o rebuild
produce una directory nuova. Copiare al massimo C slot del frammento non limita
il costo di questa directory: si copiano **2^G riferimenti**, anche se non si
raddoppia. La dichiarazione precedente di costo massimo C e assenza di pausa
proporzionale alla Serie ometteva questo lavoro e la copia delle chiavi.

La lettura di un frammento ritirato può ancora essere linearizzabile durante
l'operazione. Il suo stato congelato non fissa però il punto di linearizzazione
alla lettura iniziale del riferimento: il writer può aggiornare uno slot tra
quella lettura e il ritiro. Il reader osserverebbe lo stato successivo. Questa
osservazione corregge un istante proposto, **non dimostra** una risposta errata
del vecchio protocollo in ogni caso di sostituzione.

## Decisione

1. Il writer costruisce frammenti e directory fuori dalla root pubblicata e
   pubblica una nuova root indivisibile con generazione crescente. Non modifica
   più i frammenti sostituiti. Generazioni e seqlock non possono fare wrap.
2. Il reader acquisisce la root, legge il frammento col seqlock, esegue la
   barriera di lettura e ricontrolla root e generazione **anche su miss**. Se
   sono cambiate, scarta il risultato. I tentativi condividono il limite del
   seqlock; al limite il compito passa al writer della stessa Serie, senza spin
   illimitato. Il mutex del solo harness non è il meccanismo di produzione.
3. Ogni manutenzione dichiara separatamente slot visitati/copiati, byte delle
   chiavi, riferimenti della directory, memoria transitoria e durata. Il limite
   C riguarda gli slot di un frammento sorgente. La directory costa O(2^G), con
   profondità massima configurata e budget controllato prima della pubblicazione.
4. Il budget transitorio comprende vecchi e nuovi array della manutenzione e
   la directory nuova. Il payload vivo non è RSS: root trattenute dai reader,
   garbage non raccolto, header e runtime hanno costi aggiuntivi. Il numero di
   worker e le operazioni in volo restano limitati secondo ADR-0045.
5. Non si dichiara una pausa indipendente dalla dimensione della Serie per
   questa rappresentazione. SPK-01 misura il costo della directory e delle
   chiavi; SPK-02 misura il collector. Una directory paginata o persistente
   richiederà un ADR e un confronto se le misure non rispettano i budget.

Non compare alcun coordinamento fra Serie. Sono seriali costruzione e
pubblicazione nel writer proprietario; i reader non modificano contatori comuni
per operazione. Nessun formato persistente cambia.

## Verifica e limiti

SPK-01 inietta una sostituzione tra acquisizione del frammento e sondaggio:
controlla il retry sia per un hit vecchio sia per un miss diventato hit. La
suite differenziale e lo stress restano evidenze limitate agli scenari eseguiti.
SPK-07 deve ancora modellare la pubblicazione reale; il disassemblato e il
modello di memoria vanno verificati su ARM64 e x86-64. Il GC mantiene gli
oggetti referenziati, ma non garantisce un tempo massimo di rilascio.
