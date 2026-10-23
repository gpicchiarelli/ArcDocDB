# Verifica del recovery ACTIVE

Le prove dedicate sono in `tests/recovery-active/`, caricate dopo le fixture
CONTROL e recovery. Usano il percorso pubblico di lettura, risoluzione,
serializzazione e pubblicazione, con backend iniettato e file reali.

Il [metodo preregistrato](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-active-verifica/README.md)
distingue test, fault injection, letture C1, copertura e misure parallele.
Il [report](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-active-verifica/report.md)
conserva esiti e limiti effettivi: un successo della suite non chiude
da solo la qualifica C1 o l'integrazione del Recovery Manager.

La tabella ARV-D01..14 in [active-recuperato.md](active-recuperato.md)
resta il riferimento delle decisioni. Le fixture controllano byte e valori
con oracoli indipendenti, distinguono CSN zero da assenza e impongono
la conservazione della coda fisica. La suite non attesta che la tabella
DECISION provenga dall'Archivio: tale associazione resta una precondizione
del chiamante, fino all'integrazione del lettore autorevole.

Comandi ripetibili, ciascuno tramite il registratore delle prove:

```sh
make check
sbcl --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script tools/get-series-capture.lisp --raw-root spikes/out/active-verifica-coverage-R1/ -- sbcl --noinform --no-userinit --no-sysinit --script tools/foundation-coverage.lisp --report spikes/out/active-verifica-coverage-R1/ recovery-active
```

Il secondo comando richiede una directory nuova; conserva HTML e stato
SB-COVER. I suoi conteggi riguardano forme e rami e non dimostrano MC/DC.

La [verifica finale dell'integrazione](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-active-integrazione/report.md)
conserva separatamente il controllo del grafo che include anche il passo
pool/Serie arrivato su `main` dopo la campagna iniziale.
