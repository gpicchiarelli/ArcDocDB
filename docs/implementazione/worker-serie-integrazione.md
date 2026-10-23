# Integrazione delle verifiche reader dopo il primo controllo generale

Dopo il PASS sul congelamento `96c0f4f`, `main` ha incorporato la PR 8 fino
a `65972a4e6e84bd4c31d1d654c9a9a29bf6c44eb0`. Il confronto degli alberi
non rileva cambiamenti in alcun file `src/` o nei test già presenti.
Si aggiungono 64 prove EBR/lettura, il loro self-test di mutazione nel
Makefile, lo strumento reader-mutation, documenti ed evidenze.
Le aggiunte ASDF delle nuove suite vengono conservate insieme al bridge.

I quattro sorgenti del bridge, i suoi 26 test e il C4 sono byte-identici
ai congelamenti qualificati. La modifica a foundation-coverage aggiunge
soltanto selezione CLI, dispatch e self-test degli scope epochs/read;
selezione ed esecuzione dello scope Series restano invariate.
Non si ripetono le misure seriali e la copertura nativa: i loro esiti restano
attribuiti al v3 su `8101eb8`, con denominatori e limiti originali.

Il nuovo `make check` verifica l'integrazione su `65972a4`, incluse le
64 prove e il self-test aggiunti. Il primo PASS generale su `96c0f4f` e
il suo gate documenti/evidenze rimangono conservati come esiti precedenti;
non vengono rinominati o sostituiti dal controllo successivo.
Il controllo aggiornato passa nel
[record](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/full-check-reader-integration.lisp)
`4000710249-command-34111-0`, `:OK/:STABLE`, exit 0: 641 sorgenti e
documenti invariati, 796 test nominati e due smoke. Le due nuove suite
comprendono 34 prove epoche e 30 lettura. Passano anche i self-test di
mutazione snapshot e reader, con i relativi errori intenzionali conservati
nel [bundle](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/reader-integration-selftests.lisp).

Il [master Fase 0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series-reader-spikes-check/report.lisp)
`4000710392-check-37003-0` è `:COMPLETE`: tutti i dieci processi sono
`:STABLE`, exit 0, stderr vuoto; SPK-07 `:PASS`, gli altri `:OK`.
Conservazioni del comando e degli spike `:OK`, exit 0; nessun warning o
style-warning nello stderr originale del comando. Sorgenti e documenti
del congelamento sono nel
[bundle](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/source-reader-integration.lisp).
La lettura ausiliaria corretta e gli output estratti sono conservati;
nessun nuovo probe di sintassi e nessuna nuova misura C4.

L'inserimento di questi risultati e dei nuovi cataloghi è seguito da un
controllo dei documenti, della tracciabilità e della conservazione. I suoi
raw vengono aggiunti al catalogo senza ripetere prove o benchmark invariati.

Il [risultato della campagna](worker-serie-risultati.md) e le
[due letture](worker-serie-revisione.md) mantengono separati questi scope.
