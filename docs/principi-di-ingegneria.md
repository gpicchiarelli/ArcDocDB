# Principi di ingegneria

> Decisione dell'autore (2026-10-03): si scrive una volta sola, con la soluzione migliore
> nota. Non si scrive codice «da migliorare dopo».

## Che cosa significa «la soluzione migliore»

«10/10» non è un voto oggettivo; è un criterio di ammissione. Un pattern è ammesso in
ArcDocDB solo se soddisfa **tutte** le condizioni:

1. **Track record.** È usato in produzione da almeno un sistema di storage o database noto per
   lo stesso problema, oppure deriva da un risultato pubblicato e verificato. L'ADR cita dove.
2. **Aderenza agli invarianti.** Garantisce gli [invarianti](invarianti.md) *per costruzione*
   dove possibile, non per disciplina del programmatore.
3. **Nessun modo di guasto noto per il nostro caso.** Se il pattern ha una debolezza
   conosciuta (es. il blocco dei partecipanti nel 2PC), l'ADR dice come viene neutralizzata.
4. **Il più semplice che soddisfa completamente il requisito.** A parità di 1–3 vince la
   soluzione con meno meccanismi; un meccanismo in più va giustificato da un requisito, non
   da un'eventualità.
5. **Realizzabile in solo Common Lisp** ([ADR-0001](adr/0001-common-lisp-sbcl.md)) senza
   allocazioni sul hot path.
6. **Verificabile.** Esiste un modo per dimostrare che funziona: modello esplorabile, test di
   fault injection, benchmark riproducibile.

Se nessuna opzione soddisfa tutte le condizioni, **non si scrive codice**: si registra la
questione, si esegue lo spike che manca e si decide dopo.

## Regole di lavoro

- **Decidere prima, scrivere dopo.** Ogni meccanismo ha un ADR accettato *prima* della prima
  riga di codice. L'ADR fissa pattern, formati, invarianti garantiti e verifica.
- **Forma definitiva.** Il codice si scrive nella forma finale: niente `TODO`, segnaposto,
  «versione 1 da rifattorizzare», parametri hardcoded «per ora», gestione degli errori
  rimandata.
- **Niente alternative «buone abbastanza».** Se due soluzioni sono ammesse, l'ADR sceglie e
  motiva; non si tiene la seconda come riserva nel codice.
- **Le misure cambiano i numeri, non l'architettura.** I benchmark tarano soglie e parametri
  dichiarati configurabili dall'ADR. Se una misura invalida un meccanismo, si scrive un nuovo
  ADR che sostituisce il precedente: non si «aggiusta» il codice.
- **Gli spike non sono codice.** Sono esperimenti usa-e-getta in [`spikes/`](../spikes/README.md):
  non vengono promossi, e non contano come codice provvisorio.
- **Un formato persistente non cambia.** Ogni formato su disco ha versione e numero magico;
  un cambio di formato è un nuovo formato con migrazione, mai una modifica in-place.
- **Una fonte di verità per ogni fatto.** Ogni dato derivato (metadata, indici, cache) è
  ricostruibile e dichiara da che cosa.

## Che cosa resta fuori

Questo principio non elimina l'incertezza sulle *prestazioni*: alcune domande (durata delle
pause del GC, scalabilità dei flush concorrenti) hanno risposta solo con una misura. In quei
casi l'ADR dichiara l'ipotesi, lo spike che la verifica e quale risultato lo farebbe
sostituire. Il codice che dipende da quell'ipotesi si scrive comunque nella forma definitiva
prevista dall'ADR.
