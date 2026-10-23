# Creazione del temporaneo dalla directory posseduta

> **Proposta di API** — completa il confine I/O relativo di ADR-0017,
> senza cambiare formati, record decisivi o riconciliazione di ADR-0040.

`io:crea-temporaneo-nella-directory(directory, nome, …)` crea un nuovo
file regolare vuoto `.tmp` e restituisce una capacità append posseduta.
Il parent resta prestato e riutilizzabile. La creazione usa il suo FD,
anche se il percorso originario della directory viene rinominato.

Il nome foglia ASCII stampabile viene copiato prima dell'I/O. Sono
esclusi separatori, NUL e dot path; il limite è 255 byte e il suffisso
deve essere `.tmp`. Il nome `.tmp` stesso è ammesso, come nell'API
preesistente. Un nome già occupato viene rifiutato senza modificarlo.

| Opzione | Contratto |
|---|---|
| `max-transfer` | 1…256 MiB, predefinito 256 MiB |
| `max-file-bytes` | 1…`most-positive-fixnum`, predefinito 4 GiB−1 |

Il percorso nativo usa `openat` con creazione esclusiva, append,
`NOFOLLOW`, `CLOEXEC` e modo 0600 filtrato dalla umask del processo.
Il quarto argomento variadico riceve il modo promosso a `int`, secondo
l'ABI anche su Darwin ARM64. Prima della pubblicazione, `fstat` deve
attestare un regolare vuoto e device/inode devono coincidere con l'entry
nofollow nello stesso parent. Il controller possiede il namespace e
impedisce modifiche o chiusure concorrenti durante la chiamata.

Il backend viene ereditato dal parent. Sono richieste `create-relative`,
`file-metadata` ed `entry-identity`; l'assenza di una callback rifiuta
l'operazione prima dell'I/O, senza fallback. La callback di creazione
riceve `(fd-parent, foglia-privata, :append)` e deve realizzare la stessa
creazione esclusiva. L'API readonly e il suo callback restano distinti.

Le frontiere written/durable del nuovo file sono zero. Non avviene
alcun flush o rename. Un guasto successivo alla creazione chiude una sola
volta il child non pubblicato, conservando causa primaria e guasto di
cleanup. Il nome creato può restare presente: non viene eliminato
implicitamente. Il controller dovrà riconciliarlo secondo la fonte di
verità; questa API non prenota un ID di segmento e non decide un EDIT.

La [prova verticale](prova-verticale.md) usa la primitiva per i propri
output. Scelta dei nomi, bootstrap e orchestrazione della fixture
restano C4. Il [metodo preregistrato](io-creazione-relativa-metodo.md)
definisce decisioni, errori e limiti delle prove.
Le [letture C1](io-creazione-relativa-revisione.md) registrano i sorgenti
e i controlli statici che precedono le esecuzioni.

Le [prove conservate](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-io-creazione-relativa/README.md)
distinguono il full R1 sul freeze S1 dal controllo d'integrazione R2.
Il [rapporto di raccolta](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-io-creazione-relativa-collection/collection.lisp)
e il [checker indipendente](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-io-creazione-relativa-collection/closed-check.log)
attestano la conservazione dell'inventario chiuso.
Il [supplemento di raccordo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-io-creazione-relativa-raccordo/README.md)
conserva R4, il primo run CI fallito nel consumer dei report, la
regressione prima/dopo la correzione e i controlli C4 sulle integrazioni.
