# Metodo di verifica del confine I/O

Registrato prima dell'implementazione e dell'esecuzione delle campagne. Ambito:
apertura in sola lettura, creazione esclusiva di `.tmp`, pread esatta, append
esatta, flush di file/directory, chiusura singola. Nessuna rinomina, cancellazione,
troncamento, pubblicazione dell'indice o conferma di una transazione.

## Contratti da verificare

- Le letture non cambiano il cursore del file né scrivono stato condiviso; il
  chiamante mantiene vivo il descrittore e possiede il buffer di destinazione.
- Un compito possiede il file scrivibile fino al completamento dell'append/flush.
  I file diversi non condividono stato mutabile, lock o contatori per operazione.
- Ogni progresso positivo avanza di quanto restituito; ogni ciclo ha al massimo
  tanti passi quanti sono i byte richiesti. Zero progresso e ritorni impossibili
  sono errori. Un errore write/flush, incluso EINTR, non viene ritentato.
- Budget, capacità e offset sono verificati prima della prima syscall. Un rifiuto
  lascia il file utilizzabile; un guasto di scrittura/flush lo rende faulted.
- La posizione durevole avanza solo dopo un flush riuscito. Un errore successivo
  non annulla le posizioni storiche ma impedisce ogni futura operazione mutante.
- Close invalida il descrittore prima di chiamare il backend: niente retry né
  seconda close, anche con EINTR, perché il numero potrebbe essere riutilizzato.
- Native: fdatasync Linux, F_FULLFSYNC macOS; fsync per directory. Buffer pinning
  soltanto nel modulo io; nessun puntatore esportato dalle API pubbliche.

## Prove

Backend iniettato con ritorni brevi, progresso di un byte, EOF iniziale/parziale,
ritorni negativi/eccessivi/non interi, EIO, ENOSPC ed EINTR prima/dopo progresso.
Si controllano argv/offset, contenuto dei buffer, numero di chiamate, stato del
file, posizione scritta/durevole e assenza di chiamate dopo il guasto.

Fixture reali in una directory temporanea esclusiva: creazione, append di un
header e lotti SEAL, flush, riapertura readonly, confronto dei byte e verifica dei
codec. Si sincronizza anche la directory. Si controllano file già esistenti,
symlink, file/directory di tipo errato e letture posizionali ripetute/concorrenti.
Queste prove non simulano perdita di alimentazione o malfunzionamenti del supporto.

`make test lint` e `make check`. Il wrapper `tools/record-command.lisp` conserva
comando, ambiente, revisione, blob prima/dopo, esito, stdout/stderr e fallimenti.
Copertura e mutazioni mirate in processi separati dalle misure.

## Misure

Cinque campioni, warmup, fixture e buffer preallocati, GC completo prima del
campione, safety 3. Misurare tempo e heap SBCL: pread reale da cache del filesystem
(2 KiB), append reale senza flush per operazione e backend simulato per isolare il
costo dei controlli. Un self-test rileva anche allocazioni deliberate. Controllare
zero byte heap nei percorsi riusciti scelti, senza generalizzarlo agli errori.

Eventuali misure di flush sono latenza della syscall locale, non commit del motore
né throughput NVMe sostenuto; i campioni sono conservati integralmente. Non si
deduce P99 da cinque campioni. Carico esterno e cache OS non sono controllati.
Qualifica C1, Linux x86-64, eventi della Serie/Archivio, pool I/O e guasti del
motore integrato restano criteri separati.
