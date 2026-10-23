# Provenienza dei sorgenti delle PR

Metodo C4 preregistrato il 2026-10-22, prima della correzione.
REQ-VAL-001, REQ-AFF-012. Nessuna modifica al prodotto o ai formati del database.

GitHub espone l'head della PR nei metadata del run e del check suite, mentre
il checkout predefinito prova il merge sintetico. Nel run 39818673128 sono
rispettivamente `258ffd35…` e `53bf6ef4…`; il publisher 39821678927 rifiuta
quindi un rapporto valido. Dopo il merge, il riferimento temporaneo scompare
e l'associazione del run alla PR può risultare vuota.

Il percorso diretto mantiene il confronto con head/check suite. Il percorso
PR aggiuntivo richiede che le API GitHub riconoscano il commit come merge
firmato validamente da web-flow, con due parent e secondo parent uguale
all'head del run. Le PR associate a quell'head devono appartenere allo
stesso repository e conservare esattamente quell'head. Un merge indicato
da GitHub per una di queste PR fornisce l'ancora dei contenuti.

Il confronto usa l'inventario immutabile di path, modi e blob Git, con la
sola esclusione già prevista di `spikes/results/ci/`. Anche documentazione,
test, strumenti e workflow devono coincidere. Nessun checkout o LOAD del
producer; limiti e rifiuto di symlink/submodule restano attivi. Il confronto
dell'ancora non rilegge i byte dei blob o ricalcola le statistiche fisiche.

La prova conserva SHA dichiarata del checkout, head del run, numero PR,
SHA dell'ancora GitHub, SOURCE-ID e POLICY-ID. Il metodo dichiara
**equivalenza dei sorgenti**, non uguaglianza degli SHA né attestazione
crittografica dell'esecuzione. Il livello del producer resta UNTRUSTED-PR;
i risultati non diventano qualifiche C1/MC/DC. Se l'head è cambiato o manca
un'ancora con sorgenti identici, la pubblicazione resta rifiutata.
Il publisher aggiunge soltanto il permesso di lettura delle PR; i permessi
dei producer e il checkout del main fidato restano invariati.

Regressioni prima/dopo: merge equivalente, esclusione dei soli dati CI,
firma/signer/parent invalidi, documentazione e policy diverse, metadata PR
duplicati/mancanti/di altro repository, inventario API limitato, identità
dichiarata falsa e contesto run divergente. Le API simulate operano su
oggetti Git privati; un replay separato usa le API e gli artifact originali
del run 39818673128. Il caso positivo deve fallire prima del fix.

Una seconda regressione esercita la prima ricevuta del riconciliatore con
un vero push verso un bare locale: devono essere creati gli antenati di
`reconciliation/runs/`, conservando stato e ricevuta. Nessun push GitHub
nelle fixture e nessun allentamento dei controlli di CI-SAVE.

## Risultati del 2026-10-22

Su `1edd2085`, le 22 nuove prove di pubblicazione producono i due errori
attesi: merge sintetico rifiutato e parent della prima ricevuta assente.
Le altre 20 prove e i 333 controlli CI precedenti passano. Su `3dfadeb3`,
tutte le 355 prove passano. Su `59c38ae3`, con i due controlli aggiuntivi
sul permesso di sola lettura delle PR, il controllo completo `make check`
passa, comprese **357 prove CI** e gli undici spike. I record attestano
sorgenti stabili durante ogni esecuzione.

Il replay in sola preparazione del run originale `39818673128`, attempt 1,
riesce con le API e i pacchetti reali. Conserva lo SHA sintetico
`53bf6ef451bf7751b8b774adf8001226f8185372`, l'head
`258ffd35563847e5f7da86d995b97afad473a1bc` e l'ancora del merge della PR #21
`c46bc4c1dda191a31cf806c6f519f08aaa186df6`, con SOURCE-ID e POLICY-ID
identici. Il replay non effettua push; il producer resta UNTRUSTED-PR.

Un primo controllo completo, avviato in parallelo al replay, fallisce
nel controllo dei collegamenti: enumera il checkout temporaneo del
publisher mentre questo viene rimosso al termine del replay. Il record
fallito resta conservato; il controllo completo riuscito è un'esecuzione
successiva, avviata dopo la chiusura del replay. Questi due comandi non
devono essere sovrapposti quando condividono la stessa directory di lavoro.

L'[archivio chiuso](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-ci-publisher-provenance/catalogo.lisp)
conserva i sei processi registrati, i risultati prima/dopo, i pacchetti
originali scaricati, le risposte API selezionate e i sorgenti utilizzati.
Due bundle mantengono gli oggetti Git delle fixture private; un pack
incrementale mantiene il merge sintetico originale, con i due parent
esplicitati come prerequisiti. Log e dati Lisp si leggono come dati,
mai tramite LOAD. La riuscita locale non attesta ancora l'esecuzione del
publisher nel workflow integrato su main.

Fonti: [evento pull_request](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request),
[PR associate a un commit](https://docs.github.com/en/rest/commits/commits#list-pull-requests-associated-with-a-commit),
[semantica di merge_commit_sha](https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request),
[verifica delle firme](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification).
