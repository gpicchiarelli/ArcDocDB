# Toolchain CI

La [CI producer](../../workflows/ci.yml) e il
[publisher](../../workflows/ci-results.yml) installano SBCL 2.6.9 con questa
[azione locale](action.yml). Il [lock](../../ci-toolchain.lock.lisp) registra
archivi, SHA-256, ricette, bootstrap e pin delle action. Una modifica richiede
aggiornare insieme lock, azione e controlli statici. Classe C4;
REQ-VAL-001 e REQ-AFF-012.

## Distribuzioni e bootstrap

| Runner | Distribuzione verificata | SHA-256 |
|---|---|---|
| `ubuntu-24.04`, x86-64 | Binario ufficiale SBCL 2.6.9 | `39fac28407405841003e4c2abfbe0d96abd93b7701e8b61cdd35e713943b46d6` |
| `macos-15`, arm64 | Sorgenti ufficiali SBCL 2.6.9 | `c6fd1d735570eb4ff34caf9609988ca77ed0bd12b55d09a4fed075be890da513` |
| Bootstrap macOS arm64 | Binario ufficiale SBCL 2.4.0 | `1d01fac2d9748f769c9246a0a11a2c011d7843337f8f06ca144f5a500e10c117` |

I tre digest sono stati ottenuti il 2026-10-17 dai byte scaricati da
SourceForge, senza eseguire gli archivi. La
[tabella ufficiale](https://www.sbcl.org/platform-table.html) indica 2.4.0
come binario macOS arm64 disponibile. La ricetta segue le
[istruzioni della versione 2.6.9](https://github.com/sbcl/sbcl/blob/68a6b27d7ec8a8be45024d5e62db4f316e5ac7ea/INSTALL).
Il tag annotato `sbcl-2.6.9` è stato risolto via API fino al commit
`68a6b27d7ec8a8be45024d5e62db4f316e5ac7ea`; la distribuzione sorgente è
identificata dal digest dei suoi byte, distinto dall'object ID Git.

Le [label standard GitHub](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
verificate il 2026-10-17 assegnano `macos-15` ad arm64 sia per repository
pubblici sia privati. Intel usa `macos-15-intel`; `macos-15-arm64` è il nome
dell'immagine nel repository runner-images, non una label standard elencata.
La matrice mantiene `macos-15` e il setup rifiuta un'architettura diversa.
Il passo setup verify ha timeout di 30 minuti; il job macOS ha 65 minuti
complessivi per installazione, prove e upload (Linux conserva 30 minuti).

Su macOS si installa il bootstrap in un prefisso temporaneo privato e si
controlla `SBCL 2.4.0`, poi si costruisce il sorgente verificato con:

- architettura `arm64`, `CC=clang`, deployment target `15.0`;
- heap predefinito e del bootstrap di 2048 MiB, due processi make;
- `--with-sb-thread --without-sb-core-compression`, contrib standard;
- bootstrap con `--no-sysinit --no-userinit --disable-debugger`.

La compressione del core è esclusa dalla ricetta macOS per evitare la
dipendenza nativa da zstd. Compilatore C, SDK e immagine provengono dal
runner: il sorgente e il bootstrap sono fissati, i byte della build ottenuta
sono misurati sul runner. Non si dichiara una build bit per bit riproducibile.
Ogni download è verificato prima dell'estrazione, con timeout, retry e limite
di byte; OS o architetture differenti sono rifiutati. Nessuna cache di FASL
o della toolchain è condivisa fra job.

## Record e integrazione

L'azione espone gli output `prefix` e `record`, aggiunge il binario a
`GITHUB_PATH` e imposta `SBCL_HOME`. `ARCDOCDB_CI_TOOLCHAIN_RECORD` indica
`installation.lisp`, un record wire in `RUNNER_TEMP` con versione, OS,
architettura, ricetta, digest distribuzione/bootstrap e digest effettivi
del binario e del core installati. Su macOS contiene anche il digest di
`compiler.txt`, stdout originale di `clang --version` nella stessa directory.
Il lock è indicato da `ARCDOCDB_CI_TOOLCHAIN_LOCK` nei workflow.
Il modulo workflow espone `CI-WORKFLOW-INSTALLATION-SCHEMA(record)` per
validare la forma del record letto con `ci-read`; caricarlo prima della lettura
registra le keyword wire previste, senza interpretare codice del producer.

Il coordinator acquisisce `ARCDOCDB_CI_TOOLCHAIN_RECORD` e lo copia in
`out/work/installation.lisp`, poi seleziona la provenienza da includere nel
proprio `out/packet/`. `out/work/` e i file temporanei non vengono caricati. CPU,
RAM, kernel, image release, versione ASDF, flag e heap effettivi dei processi
di prova restano responsabilità del recorder/coordinator. Un setup fallito
non produce un record di installazione riuscita e mantiene rosso il job.

## Workflow e controlli statici

I pin completi di checkout/upload/download sono stati verificati con le API
ufficiali dei tag
[checkout v4.2.2](https://api.github.com/repos/actions/checkout/git/ref/tags/v4.2.2),
[upload v4.6.2](https://api.github.com/repos/actions/upload-artifact/git/ref/tags/v4.6.2) e
[download v4.3.0](https://api.github.com/repos/actions/download-artifact/git/ref/tags/v4.3.0).
Tutti e tre puntavano direttamente a oggetti commit; non occorreva un
ulteriore peel. Il producer usa solo lettura, artefatti distinti per
run/attempt/job, retention richiesta di 30 giorni e upload del solo
`packet/` del job anche al fallimento. Il warning per file assenti non
converte un setup fallito in successo. `seal` scarica soltanto il proprio
attempt in una directory temporanea distinta.

Il publisher parte da un checkout fresco di `refs/heads/main`, senza
credenziali persistenti. Solo i comandi publish/reconcile ricevono
`GH_TOKEN`; la CLI verifica ID, metadata GitHub, payload e tentativi e
gestisce i retry. L'ingresso manuale è ammesso solo da main e propone
`dry_run=true`; workflow_run considera ogni conclusione, e il recupero è
schedulato ogni sei ore con limite 100. Il benchmark producer parte per ogni
push main e ogni richiesta manuale. I push automatici dipendono dai
permessi effettivi del repository; la retention effettiva va verificata
dal coordinator rispetto alla finestra di recupero.

`ARCDOCDB.CI::CI-WORKFLOW-SELF-TEST(out)` legge i sorgenti e il lock, controlla
il contratto testuale YAML adottato e usa fixture in memoria per verificare
alcuni rifiuti. Restituisce una plist con conteggi e scrive esclusivamente
`workflow-self-test.lisp` nella directory `out`. Non interpreta YAML generale,
non invoca programmi e non dimostra l'esecuzione dei runner. Il caricamento
del modulo non avvia il self-test. La compilazione e la campagna GitHub
restano da eseguire dal coordinator dopo la chiusura del writer.
