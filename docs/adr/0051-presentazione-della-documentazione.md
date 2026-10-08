# ADR-0051 — Presentazione della specifica e delle guide del repository

- **Stato:** Accettata (riordino documentale richiesto dall'autore)
- **Data:** 2026-10-08
- **Rapporto con la specifica:** emenda soltanto nome e nota introduttiva della
  specifica originale; il corpo e i requisiti restano invariati.
- **Riferimenti:** [specifica originale](../specifica/specifica-originale.md),
  [guida al repository](../guida-al-repository.md),
  [contributi](../../CONTRIBUTING.md), [registro delle prove](../valutazione/registro-delle-prove.md)

## Contesto

Le guide di lavoro sono duplicate e alcune note degli esperimenti descrivono
l'organizzazione del lavoro anziché il metodo riproducibile. La documentazione
pubblica deve descrivere il progetto, le verifiche e i loro limiti.

## Decisione

1. La specifica originale ha un nome coerente con il suo ruolo di documento
   tecnico. La nota introduttiva conserva i chiarimenti sulla trascrizione e
   sul MERGE; il corpo successivo al separatore iniziale è identico.
2. Le regole comuni sono raccolte nella guida al repository, collegata da
   `CONTRIBUTING.md`. Le configurazioni locali degli strumenti restano locali.
3. Le note degli spike descrivono moduli, runner, dipendenze e campagne.
   Dati, comandi, hash dei sorgenti e output originali delle prove sono conservati.

Il riordino non introduce serialità nel motore, scritture condivise o operazioni
durevoli; non richiede un nuovo punto di atomicità.

## Conseguenze

Una sola guida raccoglie le regole comuni. I collegamenti alla specifica sono
aggiornati insieme al documento. Le evidenze storiche mantengono la loro
provenienza e non sono riscritte per uniformarne il lessico.

## Alternative considerate

- Conservare guide duplicate: richiede di mantenerle sincronizzate.
- Riscrivere anche i report originali: compromette la verifica della provenienza.

## Valutazione

Confronto del corpo della specifica con la revisione precedente, controllo dei
collegamenti e della tracciabilità e suite `make check`. Nessun requisito del
motore cambia stato per effetto del riordino.
