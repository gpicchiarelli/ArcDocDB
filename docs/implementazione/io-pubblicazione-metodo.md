# Pubblicazione esclusiva di un temporaneo — metodo

> **Proposta di API** — Completamento di ADR-0040 e INV-A9/A10/A11,
> preregistrato il 2026-10-17 prima dell'implementazione e delle esecuzioni.
> Nessun nuovo formato o punto di commit del database.

## Incremento e responsabilità

`io:pubblica-temporaneo(directory, source, source-name, target-name)`
riceve una capacità readonly del file già verificato. Il coordinatore
garantisce la decisione autorevole durevole che nomina quel segmento,
l'integrità dei contenuti e il namespace esclusivo e stabile. Il suffisso
`.tmp` da solo non prova questi fatti. I nomi sono componenti ASCII e
`source-name` è esattamente `target-name` seguito da `.tmp`.

La primitiva verifica identità del FD e del nome sorgente, esegue una
rinomina esclusiva relativa allo stesso parent e verifica il nome finale
contro il FD ancora aperto. Un target già presente, anche un symlink o
un alias, deve impedire la sostituzione nella syscall. Non basta una
verifica di assenza seguita dalla normale `renameat`.

Linux usa `renameat2` con `RENAME_NOREPLACE` (1); Darwin usa `renameatx_np`
con `RENAME_EXCL` (4). Nessun ripiego su rename ordinaria, link/unlink o
cancellazione preventiva. Simbolo nativo assente, ABI/piattaforma non
ammessa e callback mancante sono rifiuti espliciti. Un filesystem che
rifiuta la primitiva produce il guasto POSIX originale, senza retry.

Il backend aggiunge soltanto la keyword opzionale `:rename-exclusive`,
con argomenti parent-fd/source/target e risultato zero. Richiede anche
`identity` e `entry-identity`. I backend esistenti conservano il layout
di chiamata del costruttore; le istanze vanno ricompilate dopo il nuovo slot.

## Effetti e guasti

La rinomina è il punto atomico del namespace e completa una decisione
già presa. Non è una nuova decisione EDIT. Il caller esegue separatamente
`durable-flush(directory)` prima di ammettere traffico. Nessuna apertura,
scrittura dei segmenti, troncamento, close o flush implicito.

Preflight e prima verifica di identità non cambiano la capacità. Entrati
nel confine dell'effetto, syscall fallita, callback con risultato diverso
da zero, postcondizione fallita o uscita incompleta guastano una directory
ancora aperta, preservando la causa. Si riusa il cleanup della rinomina
esistente, senza duplicarlo. Non si ritenta o annulla un esito incerto.
Se il ritorno viene perso dopo il successo, il coordinatore ricostruisce
l'inventario dal manifest: la stessa chiamata non è un protocollo di retry.

Le capacità sono prestate; restano aperte sul successo. Il compito I/O
impedisce close/riuso del FD e sostituzioni del sorgente per tutta la
chiamata. L'esclusività del target non rende atomico il controllo
d'identità del sorgente e non autorizza un namespace concorrente.
La fonte posseduta del recovery mantiene i fatti del nome osservato:
il coordinatore non riusa tali nomi iniziali dopo il completamento.

## Decisioni C1 e verifica prevista

| ID | Decisione / obbligo | Casi da qualificare |
|---|---|---|
| PIO-D01 | Directory aperta e source readonly aperto | Modi diversi, chiuso, faulted, FD invalido |
| PIO-D02 | Due foglie valide e relazione `.tmp` esatta | Limiti, separatori, case, suffisso/target diversi |
| PIO-D03 | Backend identico e callback complete | Backend misti; ogni callback assente separatamente |
| PIO-D04 | Nativo 64 bit, piattaforma e simbolo presenti | ABI/piattaforma/simbolo non supportati |
| PIO-D05 | Device e inode del nome sorgente uguali al FD | Ciascuna disuguaglianza, file non regolare e symlink |
| PIO-D06 | Selettore ordinario/esclusivo nel helper comune | Rinomina precedente invariata; nuovo callback/nativo |
| PIO-D07 | Effetto esclusivo zero | Target assente, presente, symlink, hardlink; errno, ritorno impossibile |
| PIO-D08 | Postcondizione nome finale/FD e capacità aperte | Identità cambiata, guasto post-effetto, invalidazione FI |
| PIO-D09 | Uscita incompleta e directory ancora aperta | Errore, uscita non locale, directory già chiusa/faulted |

In questo incremento si eseguono compilazione del solo prodotto senza
avvisi, lint, tracciabilità, link e lettura del disassemblato. Le diagnostiche
e i loro eventuali fallimenti passano dal recorder comune e sono conservati
con revisione, hash, ambiente e output originali. Prima dei run gli autori
sono chiusi e il codice è committed. Due letture statiche C1 distinguono
contratto e guasti; una revisione indipendente resta esplicitamente statica.

Non sono previsti nuovi test funzionali, FI, mutazioni, copertura o
benchmark in questo incremento. PIO-D01…D09, MC/DC, esecuzione Linux/macOS,
crash/power loss, integrazione del Recovery Manager e ammissione rimangono
da qualificare. Nessun numero di throughput o promessa di zero allocazioni:
copie dei nomi e FFI appartengono al percorso freddo dei metadati.

## Fonti delle primitive

- [Linux man-pages: renameat2 e RENAME_NOREPLACE](https://man7.org/linux/man-pages/man2/rename.2.html).
- [Apple XNU: ABI renameatx_np e RENAME_EXCL](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/sys/stdio.h).
- [Apple: supporto del volume alla rinomina esclusiva](https://developer.apple.com/documentation/foundation/urlresourcevalues/volumesupportsexclusiverenaming).
- [SBCL: verifica senza effetti della disponibilità dei simboli esterni](https://sbcl.org/sbcl-internals/Linkage_002dtable.html).
