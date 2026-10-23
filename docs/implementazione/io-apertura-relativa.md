# Apertura readonly dalla directory posseduta

> **Proposta di API** — contratto applicativo che realizza l'apertura
> readonly di COD-37 sulle piattaforme di ADR-0017, senza cambiare
> formati e decisioni di ADR-0040.

`io:apri-lettura-nella-directory` riceve una capacità directory aperta
e un nome foglia ASCII, e restituisce due valori: una nuova capacità
readonly e la dimensione osservata tramite il suo stesso FD. Il nome
viene copiato prima dell'I/O. Il parent e le capacità preesistenti restano
del chiamante; soltanto il child acquisito viene chiuso se la chiamata
fallisce prima di pubblicarlo.

L'apertura è relativa al FD del parent, con `NOFOLLOW`, `CLOEXEC` e
`NONBLOCK`. Sono ammessi soltanto file regolari. Il confronto esatto di
device/inode con l'entry relativa precede il ritorno. Il controller
possiede il namespace e ne impedisce mutazioni concorrenti: il controllo
non sostituisce tale precondizione e non è uno snapshot atomico.

| Opzione | Contratto |
|---|---|
| `max-transfer` | 1…256 MiB, predefinito 256 MiB |
| `max-file-bytes` | 0…`most-positive-fixnum`, predefinito 4 GiB−1; zero per il solo file vuoto |

Il backend del parent viene ereditato. Sono richieste le callback
opzionali `open-relative`, `file-metadata` ed `entry-identity` descritte
nel [metodo preregistrato](io-apertura-relativa-metodo.md); la loro
assenza produce un rifiuto prima dell'apertura, senza fallback nativo.
Le API preesistenti e il callback `identity` mantengono il contratto.

La dimensione è una fotografia di `fstat` e non modifica le frontiere
written/durable, che restano zero. Non attesta header, CRC, prefisso
valido, commit o durability. L'uso nei reader della
[prova verticale](prova-verticale.md) passa loro capacità e dimensione
della stessa apertura; il resto del bootstrap e del coordinamento
rimane C4.

Il [metodo](io-apertura-relativa-metodo.md) specifica budget, errori,
ownership e decisioni; le [due letture C1](io-apertura-relativa-revisione.md)
precedono le esecuzioni. Nessuna rinomina, eliminazione, creazione o
riapertura in scrittura avviene in questa API. La [raccolta posseduta delle fonti](fonti-recovery.md)
acquisisce ora l’insieme ACTIVE/CLOSED con budget e cleanup; il coordinamento
del recovery resta un incremento successivo.

Le [prove locali conservate](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-io-apertura-relativa/README.md)
distinguono il controllo completo sul commit congelato dall'integrazione
successiva. Il [rapporto di raccolta](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-io-apertura-relativa-collection/collection.lisp)
e il checker indipendente attestano la conservazione dell'archivio chiuso.
Il [supplemento di integrazione](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-io-apertura-relativa-integrazione/README.md)
conserva separatamente la prima CI e la verifica locale della composizione
con scelta ID dalla directory e nomi canonici; il codice I/O resta invariato.
