# Verifica della catena pool, dispatcher e Serie

Metodo C4 preregistrato il 2026-10-15 sulla base
`a34cede6fbc9215908d50aa85311d5d703660040`, prima di eseguire le nuove prove.
REQ-THR-001, REQ-CON-001/002/004/005 e REQ-AFF-008; ADR-0031/0034/0045.
I sorgenti di prodotto restano invariati. Si verificano insieme il
[passo dispatcher](pool-step.md), l'[avvio](pool-begin.md) e il
[bridge Serie](worker-serie.md), usando API pubbliche e thread reali.

## Scenari e oracoli

1. Due worker con contesti, porte, tabelle e link creati sui rispettivi thread,
   registro di routing immutabile e ready condivisa. Il primo mantiene la lease
   della Serie A; il secondo completa **32 quantum** della Serie B prima che il
   coordinatore liberi A. Ripetere con A in ACTIVE/RUNNING e con debito BATCH.
   L'oracolo verifica payload FIFO, token, count, stato e tutti i cinque valori
   del dispatcher. B termina ed è joined prima della release di A.
2. Ritiro del secondo worker mentre deve ricircolare A dopo il primo quantum.
   Il coordinatore accoda B e richiede il ritiro tramite il registro pubblico.
   Ready a tre partizioni, home 0 e 2, capacità 1 e 2: quattro scenari.
   Full scambia A con B, completa B e applica il ritiro soltanto al successivo
   ingresso IDLE. Room pubblica A, termina il passo e ritira senza nuova presa.
   Il primo worker prende e completa il lavoro rimasto; ogni payload atteso
   compare una volta sola, in ordine. Il registro converge a un worker attivo.

Le barriere C4 fissano l'ordine degli eventi, non sostituiscono i trasferimenti
del prodotto. Nessuna FI sui valori, sulle funzioni o sulle parole lifecycle.
Le semafore e i join hanno timeout di 15 secondi; i cicli hanno cardinalità
nota (2 modalità, 32 quantum, 4 scenari). Gli errori dei thread vengono
propagati al test. Nel cleanup si liberano le barriere, si terminano e si
uniscono i thread della fixture prima di chiudere i backend in memoria.

## Verifica e limiti

Compilazione stretta senza warning/style-warning, suite scheduler e suite
completa tramite `make check`; registri originali conservati, anche in caso
di fallimento. Rilettura C4 della fixture e dei suoi oracoli prima della
qualifica finale. Nessun nuovo codice caldo: le misure di allocazione e
copertura precedenti non vengono reinterpretate come misure di queste prove.

Le pause artificiali con lease/debito appartengono solo alla fixture di test:
non sono un compito di prodotto che attende. Il risultato prova la possibilità
di avanzare su due Serie distinte in questi ordini sincronizzati, non lo speedup
su due core, fairness generale, assenza universale di race o memoria debole.
Payload simbolici/interi verificati e confermati dal caller: nessuna applicazione
di PUT, commit durevole, I/O reale, park/wake o loop server viene qualificata.
