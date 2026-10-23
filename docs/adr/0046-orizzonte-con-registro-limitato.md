# ADR-0046 — Orizzonte con registro limitato dei CSN in volo

- **Stato:** Accettata
- **Data:** 2026-10-08
- **Rapporto con la specifica:** nessuna emenda; corregge il punto 2 di
  [ADR-0038](0038-orizzonte-di-visibilita.md). Snapshot, ordine delle versioni e CSN restano.
- **Riferimenti:** [SPK-07](../../spikes/SPK-07-protocols/README.md), INV-M4, INV-M6,
  REQ-MVC-008, RSK-05

## Controesempio eseguibile

Il credito sui soli commit pendenti non limita la distanza tra ultimo CSN e orizzonte.
Con anello di quattro parole e al massimo due pendenti:

```text
prendi 1, prendi 2, pubblica 2,
prendi 3, pubblica 3, prendi 4, pubblica 4,
prendi 5, pubblica 5, pubblica 1
```

La pubblicazione di 5 usa la posizione che poi contiene 1. Alla fine non esistono pendenti,
ma `H=4` e `ultimo-CSN=5`: gli snapshot non possono nascere. L'esploratore trova il percorso
in dieci transizioni; il limite dei pendenti è rispettato in ogni stato.

## Decisione

1. **Registro preallocato dei soli CSN in volo**, capacità configurata `K`, default proposto
   256. Zero indica slot libero. Ogni lotto o decisione conserva il proprio indice di slot.
   Non si indicizza più un array tramite `csn mod N`.
2. **Assegnazione e registrazione indivisibili**, sotto il mutex dell'orizzonte: si riserva
   uno slot libero, si incrementa l'ultimo CSN e lo si registra prima di rilasciare il mutex.
   Nessuna pubblicazione può far avanzare `H` oltre un CSN assegnato ma non registrato.
3. **Pubblicazione o annullamento**: sotto lo stesso mutex, si verifica l'identità del CSN,
   si libera il suo slot e si pone `H=min(CSN in volo)-1`; se il registro è vuoto,
   `H=ultimo-CSN`. La ricerca del minimo visita al massimo `K` parole. `H` non diminuisce.
4. **Capacità esaurita**: il lotto resta aperto o la richiesta è parcheggiata secondo
   [ADR-0045](0045-modello-di-esecuzione.md), con byte e tempo limitati. Il credito ritorna
   quando quel commit è pubblicato o annullato; la distanza da `H` non consuma crediti.
5. **Esaurimento dei 64 bit**: rifiuto esplicito prima dell'incremento, mai wrap. Il valore
   di `K` e il costo delle due sezioni critiche per lotto sono da misurare in SPK-04.

Il coordinamento resta per lotto, decisione o snapshot. I reader senza snapshot leggono
senza prendere il mutex. Il registro è una voce dell'elenco già condiviso nell'Archivio;
la frequenza passa da una a due sezioni critiche per lotto.

## Alternative

- Anello con credito basato su `ultimo-CSN-H`: corretto nel piccolo modello, ma un commit
  lento consuma la finestra anche dopo che gli altri hanno finito. Il registro conserva il
  limite sui veri pendenti.
- Heap dei CSN in volo: ricerca del minimo più economica, con più strutture da mantenere.
  Si introduce solo se SPK-04 misura il registro come limite di scalabilità.

## Verifica e limiti

SPK-07 esplora fino a sei CSN con capacità due: il registro non salta commit pendenti e,
quando tutti sono conclusi, raggiunge l'ultimo CSN. La variante originale deve fallire.
Questa è verifica di un modello finito con memoria sequenzialmente consistente; le barriere
e la sincronizzazione dell'implementazione restano da provare sui thread reali.
