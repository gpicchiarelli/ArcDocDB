# ADR-0049 — Percorso di capacità oltre la RAM

- **Stato:** Proposta; direzione di ricerca autorizzata, formato e algoritmo da valutare.
- **Data:** 2026-10-08
- **Rapporto con la specifica:** propone un'estensione all'indice residente; non sostituisce ancora ADR-0043 né lo scope v1.

## Obiettivo

La capacità di una Serie deve poter superare la memoria disponibile per l'indice primario. La stima di documenti per RAM del modo residente non è un limite universale del prodotto.

## Proposta

Un modo opzionale per Serie con indice primario persistente derivato e cache limitata. Valutare pagine ordinate copy-on-write e una directory persistente a hashing; nessuno dei due è ancora scelto. Le chiavi complete e le location devono poter risiedere su disco; non basta spostare solo le chiavi. Il writer resta locale, le viste dei reader coerenti, il recovery ricostruibile da segmenti e manifest. Nessuna scrittura condivisa tra Serie; nessuna risorsa senza budget.

## Evidenze necessarie prima dell'adozione

Esperimento con indice più grande della cache, confronti di lookup caldo/freddo, P95/P99, memoria limitata, costo degli split, write amplification, rebuild, crash e snapshot durante manutenzione. Misurare con chiavi corte e lunghe. Dichiarare il punto di atomicità in un ADR successivo e aggiornare la tracciabilità prima di implementare il motore.

Il modo residente conserva il percorso ottimizzato; il modo persistente aggiunge possibili letture NVMe e non eredita i suoi target di latenza. Replica e sharding restano estensioni separate. Nessuna capacità oltre RAM è oggi dimostrata.
