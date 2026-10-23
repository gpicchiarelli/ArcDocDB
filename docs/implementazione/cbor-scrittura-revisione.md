# Prima lettura C1 delle testate CBOR in scrittura

Lettura indipendente del blob `61f0d6e2783e4790ed7e19a45bba6407d6e5b3de`
prima delle campagne. Il precedente `02c5313d…` superava COD-13 nel wrapper
pubblico: 11 percorsi. Il preflight è stato estratto prima della compilazione,
conservando il contratto. Nessun rilievo funzionale statico aperto.

| Checklist C1 | Riscontro statico e verifica dinamica richiesta |
|---|---|
| 1. Requisito e ADR | REQ-CBR-001 deriva da ADR-0014, AFF-004/008 per errori e confini; dominio MT0..6. |
| 2. Invarianti | INV-F1/P6, destinazione esclusiva e testata standard; preflight e sentinelle nel corpus indipendente. |
| 3. Errori | Range/major/high/low/capacità prima di scrivere, offset NIL; invariant-violation interno senza rollback. Nessun handler. |
| 4. Limiti | Un dotimes di massimo quattro passi, due parole al massimo, nove byte; nessuna ricorsione o attesa. |
| 5. Memoria | Nessun costruttore, closure o u64 ricomposto; heap e sensore positivo ancora da misurare. |
| 6. Dati in uscita | NEXT dopo range/progresso, capacità prima della somma, lead entro u8. |
| 7. Decisioni | Quattro forme nell'[inventario](cbor-scrittura-decisioni.md), senza esclusioni o attestazione MC/DC. |
| 8. Proprietà | OWNER/SHARED espliciti, buffer esclusivo fino al ritorno, nessun riferimento trattenuto o stato globale. |
| 9. Integrazione | Export/ASDF/runner/requisito/matrice predisposti; build/lint/trace/check da acquisire. |
| 10. Standard | safety3, FTYPE/docstring/REQ; funzioni sotto60 righe. Percorsi: selezione9, parola8, preflight8, pubblico7, contando compound e ciclo. |
| 11. Parallelismo | Nessun lock/attesa/scrittura condivisa tra Serie; worker privati verificano concorrenza, senza scaling. |
| 12. Durevolezza | Nessuna pubblicazione durevole o eliminazione. Scrittura nel buffer esclusivo senza promessa atomica. |

La mutazione della capacità fisica è prevista rilevabile come condizione
errata: la guardia interna impedisce comunque lo sconfinamento. Non è una
prova di scrittura fuori span. MT1 riceve l'argomento wire `-1-n`; lo span
vuoto valido arriva alla capacità. Nessun limite documentale implicito.

La [seconda lettura](cbor-scrittura-lettura.md) valuta anche il corpus cieco.
I [risultati](cbor-scrittura-risultati.md) completano le voci dinamiche;
la lettura statica da sola non qualifica il prodotto o chiude un gate.
