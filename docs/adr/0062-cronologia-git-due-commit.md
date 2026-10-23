# ADR-0062 — Cronologia Git ridotta a due commit

- **Stato:** Accettata su richiesta dell'autore del 2026-10-23
- **Data:** 2026-10-23
- **Riferimenti:** REQ-AFF-012, INV-X2;
  [conservazione delle prove](0061-conservazione-esterna-delle-prove.md).
- **Rapporto con ADR-0061:** sostituisce, per questa operazione autorizzata,
  la scelta di non riscrivere la cronologia. Gli asset e gli originali delle prove restano invariati.
- **Rapporto con la specifica:** nessun cambio al prodotto o ai formati persistenti.

## Decisione

Si mantengono i due ultimi stati: verifica CRC32C e successiva pulizia delle
prove. Il primo diventa un commit radice con **lo stesso albero Git originale**;
il secondo ne è l'unico figlio. Nel secondo cambiano solo collegamenti e
metadati di manutenzione necessari alla riscrittura. Il codice eseguibile
rimane identico. I nuovi hash non vengono attribuiti alle esecuzioni storiche:
i risultati conservano gli identificativi originali.

Prima della sostituzione si crea un bundle Git completo delle tre ref pubbliche
precedenti, lo si verifica, lo si pubblica nell'asset esterno e lo si rilegge
con SHA-256. Il checkpoint locale Codex coincide con un albero già presente
nella cronologia salvata; nessun contenuto ulteriore da integrare.

`main` e il tag della release vengono aggiornati insieme con lease sugli hash
osservati. Il branch remoto obsoleto viene eliminato nella stessa operazione.
Il tag punta al nuovo commit radice; gli asset conservano nome e hash originali.
Il pubblicatore CI viene sospeso durante la manutenzione e poi riattivato.

## Verifica e conseguenze

- Uguaglianza dell'albero del primo commit prima e dopo la riscrittura.
- Nessuna modifica al codice eseguibile del secondo commit.
- Destinazioni dei collegamenti storici verificate nell'albero conservato.
- Due commit raggiungibili da `main`, un solo padre per il secondo, nessuno per il primo.
- Ref locali e remote allineate, cataloghi e collegamenti locali verificati.
- Dopo il push, scadenza dei reflog locali e garbage collection degli oggetti orfani.

Il primo stato conservato include ancora i raw storici: quei blob restano
raggiungibili e continuano a occupare spazio Git. La richiesta riguarda la
cronologia, non la modifica dei due stati conservati. La rimozione di oggetti
irraggiungibili sui server GitHub dipende dal servizio. I commit futuri,
compresi quelli del pubblicatore CI, possono nuovamente aumentare la cronologia.
Il rollback completo è possibile importando il bundle verificato.
