# Hash delle chiavi — prove e misure

[Risultati e registri strutturati](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-key-hash/risultati.md):
706 test integrati piu due smoke, 46 nuove regressioni, sette mutanti,
240 finestre seriali senza heap e 360 gruppi paralleli.

Su SBCL/macOS ARM64: circa 38,6 milioni di hash/s per chiavi di 16 byte
in seriale; 75,7–113,1 milioni aggregati con quattro worker, secondo
la fixture/seme. Mediane di cinque repliche; tutte le lunghezze e i semi
sono conservati. Il percorso parallelo misura heap globale positivo.

Questi numeri riguardano la primitiva con validazione e sink del harness.
Copertura incompleta degli helper inline/guardie, MC/DC, motore completo,
P99, lifecycle del seme e x86-64 rimangono limiti dichiarati.
