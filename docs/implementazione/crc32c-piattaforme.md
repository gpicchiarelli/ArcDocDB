# Integrazione CRC32C sulle piattaforme

[ADR-0060](../adr/0060-crc32c-caricamento-portabile.md) precisa il
[backend misurato](crc32c-arm64.md). Nessun cambiamento al formato del DB.

| Ambiente | Backend automatico | Qualifica prestazionale |
|---|---|---|
| macOS ARM64, SBCL 2.6.9, CRC OS e NEON presenti | ARM64 CRC32C | M4 locale: GET cache hit 4 KiB 1,684 µs, software 6,758 µs |
| Stesso ambiente con CRC/NEON assente o probing fallito | Lisp slicing-by-8 | Fallback di correttezza |
| Linux x86-64, piattaforma di riferimento | Lisp slicing-by-8 | Nessuna misura hardware trasferita dall'M4 |
| Linux ARM64, macOS x86-64, altri SBCL | Lisp slicing-by-8 | Nessuna accelerazione attivata senza qualifica |

La portabilità del checksum non estende il supporto del motore POSIX a
Windows o ad altri sistemi. La CI esistente copre Linux x86-64 e macOS ARM64.
I risultati prestazionali sono mediane di finestre sui dati caldi; non P99.

## Bootstrap e rollback

ASDF e il loader delle misure CI condividono `src/io/cpu-build.lisp`.
Soltanto la combinazione qualificata richiede SB-SIMD e legge le definizioni
dei VOP o i riferimenti NEON. La successiva scelta del kernel richiede la
conferma OS/CPU. La funzione pubblica `backend-crc32c` riporta l'esito.
I due componenti ASDF nativi hanno anche `:if-feature`: il fallback non
carica vecchi FASL ARM presenti nella cache. Un confronto di tre processi
freschi senza `:force` controlla nativo → software → nativo sulla stessa
cache di compilazione.

Per forzare il software, prima di caricare ASDF/prodotto in un processo fresco:

```lisp
(pushnew :arcdocdb-crc32c-software *features*)
```

La feature non modifica il formato, i dati o l'API. Evitare reload durante
il servizio: selezione e feature di compilazione appartengono all'avvio.

## Metodo di verifica, prima delle prove

Tre test nuovi (fondazioni: 34) esercitano ogni condizione del compilatore,
versioni ignote, Linux x86/ARM, macOS Intel, Windows, disabilitazione esplicita,
feature native obsolete, risposte OS e tutte le otto selezioni del backend.
La tabella MC/DC del compilatore è il caso positivo con ognuna delle cinque
feature rimossa singolarmente, versione diversa e disabilitazione aggiunta.
Per il report OS: `(0 4 1)` contro `(-1 4 1)`, `(0 8 1)`, `(0 4 0)`;
per la selezione: tutte le combinazioni dei tre booleani. Sono test delle
decisioni pure; non simulano l'ABI o l'esecuzione su un altro kernel OS.

Due processi freschi eseguono build rigoroso e suite complete, uno normale
e uno software forzato. Nel secondo il kernel ARM e l'emettitore non devono
essere definiti, né SB-SIMD richiesto da ArcDocDB. Un test separato del reader
carica le fondazioni senza package SIMD su combinazioni di feature sintetiche:
verifica isolamento delle dipendenze, non equivale a eseguire Linux/x86.
L'intero `make check` rimane obbligatorio. I benchmark precedenti conservano
i loro sorgenti; si controlla la regressione col driver A/B invariato.

Due letture dell'autore: dipendenze/feature e fallback, poi ABI/decisioni,
contratti seed/range/incrementalità e immutabilità del kernel nel servizio.
Nessuna revisione indipendente o qualifica C1 complessiva implicita.

## Risultati dell'integrazione

Il controllo globale equivalente a `make check` (`check-core` registrato)
è passato con exit 0 e sorgenti stabili: build e suite, lint, tracciabilità
(137 requisiti, 71 invarianti, 60 ADR), link, full text, strumenti di prova,
audit di 316 cataloghi, undici spike e autotest CI. Anche la build rigorosa
con software forzato è passata con tutte le suite e nessun warning.
I tre processi ASDF senza `:force` e l'isolamento del reader sono passati.

La campagna A/B invariata conferma il risultato su Apple M4/SBCL 2.6.9:
GET cache hit da 4 KiB, CSN 7, **1,664 µs hardware contro 6,752 µs software**;
segmento caldo: 2,377 contro 7,484 µs. Sono mediane di cinque finestre;
360 finestre prestazionali, 14,4 milioni di GET, tutte complete e con
delta heap zero. Le 72 finestre bounded precedono la misura. Il driver,
le fixture e il perimetro sono quelli del metodo precedente; nessun P99.

Il [run CI precedente](https://github.com/gpicchiarelli/ArcDocDB/actions/runs/39998228176)
ha fallito su Linux durante il caricamento dei test figli per il warning
`reading an ignored variable: STREAM`. La correzione `ignore` → `ignorable`
è inclusa e verificata dal build rigoroso locale. Questa osservazione sul
run precedente non costituisce un esito CI della nuova revisione.

[Sorgenti, prove e risultati grezzi dell'integrazione](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-23-crc32c-platforms/catalogo.lisp).
Le appendici e i collegamenti conclusivi sono metadati successivi alla
verifica globale; il codice eseguibile non cambia dopo quel controllo.
