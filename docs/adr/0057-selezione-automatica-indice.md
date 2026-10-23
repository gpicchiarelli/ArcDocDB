# ADR-0057 — Selezione automatica del modo dell'indice per Serie

- **Stato:** Accettata dall'autore il 2026-10-22; attuazione incrementale
- **Data:** 2026-10-22
- **Rapporto con la specifica:** estende il modo residente con selezione automatica
  per Serie, concretizzando ADR-0049; non cambia formati persistenti o commit
- **Riferimenti:** [ADR-0049](0049-capacita-oltre-la-ram.md),
  [ADR-0050](0050-pubblicazione-e-costi-della-directory.md),
  [contratto implementativo](../implementazione/indice-automatico.md),
  REQ-IDX-008, INV-I7, INV-A8, INV-P6

## Contesto

L'autore richiede un indice oltre RAM, preservando il percorso residente quando
la memoria basta e scegliendo automaticamente durante avvio ed esercizio. Un
indice paginato completamente in cache non equivale al percorso flat residente:
pin, copie e gestione delle pagine hanno costi ulteriori.

## Decisione

1. Il comportamento predefinito e automatico e' locale alla Serie. All'avvio,
   se il picco residente sta nel budget assegnato, si sceglie il modo residente.
2. In esercizio il residente resta tale finche' il picco previsto rientra nel
   budget. Il superamento richiede il modo paginato prima di ammettere il
   lavoro che eccederebbe il limite; non autorizza uso della swap.
3. Il rientro dal paginato al residente e' automatico con isteresi: picco
   residente entro una percentuale del budget, configurabile 1..99, default 75.
   Il default e' una politica, non un risultato di benchmark. La banda
   distinta evita cambi ripetuti quando la stima oscilla vicino al limite.
4. Ogni cambio richiede una prenotazione del picco di migrazione: sorgente
   ancora utilizzabile, destinazione, staging, delta e riferimenti trattenuti.
   Se manca memoria il selettore restituisce budget insufficiente: non avvia
   allocazioni e non cambia la root. Il chiamante sospende o rifiuta il nuovo
   lavoro che non puo' riservare, mantenendo le letture gia' ammesse.
5. Le stime comprendono slot, chiavi, directory, history, metadati, garbage
   trattenuto e transitori pertinenti. Budget e stime sono byte interi
   conservativi, non la sola RAM libera istantanea dell'OS.
   I picchi dei due modi descrivono il prossimo lavoro da ammettere; quello
   di migrazione descrive il cambio sul dataset corrente, prima di quel
   lavoro. Puo' essere minore del futuro picco residente che il cambio evita,
   ma non del picco di destinazione. Questo rende possibile anticipare la
   crescita anziche' attendere un indice gia' troppo grande da migrare.
6. Il selettore e' puro, non effettua I/O, non alloca dopo la configurazione e
   non tocca uno stato globale. Lo usa il controllore fuori dal lookup GET;
   non aggiunge contatori o serializzazione tra Serie.
7. La scelta e' una proposta, non una pubblicazione. L'attuatore futuro deve
   costruire e verificare la destinazione, ricontrollare le frontiere e
   pubblicare una sola vista coerente; commit, snapshot, outcome ed epoche
   restano quelli del motore. Nessun nuovo punto di atomicita' durevole.

Il primo incremento implementa soltanto il selettore e il modello astratto
del lifetime dei frame. Non dispone di backend primario paginato, migrazione,
misuratore della memoria fisica o attuatore nel motore; non annuncia tali
funzioni come disponibili. L'indice corrente continua a usare il modo residente.

## Conseguenze

L'API distingue destinazione desiderata e azione ammissibile. Nessun flag
permette di fingere il completamento di una migrazione. Due Serie con budget
diversi possono scegliere modi diversi senza sincronizzazione per richiesta.
Le quote globali restano responsabilita' del controllore: la somma comprende
anche migrazioni contemporanee e gli altri componenti del motore.

Il modo paginato richiede ancora un ADR di formato e una decisione verificata
su cache, directory e history. La proprieta' lock-free viene valutata
separatamente per lookup residente, acquisizione/rilascio e miss con I/O.

## Alternative considerate

- Paginazione sempre attiva: impone overhead anche se l'indice entra in RAM.
- Selezione soltanto manuale o all'avvio: non soddisfa crescita e rientro automatici.
- Stessa soglia in entrambe le direzioni: puo' causare oscillazioni continue.
- Cambio immediato di un flag: non dimostra copertura dei commit o degli snapshot.
- Decisione dalla sola RAM libera: trascura prenotazioni e memoria transitoria.

Il pattern di deadband e scelta dalla capacita' segue il principio del
[controllore gia' previsto da ADR-0011](0011-thread-pool-dinamico.md).
L'isteresi decide quando preparare un cambio, non la correttezza della pubblicazione.

## Valutazione

Test sulle soglie esatte, scelta iniziale, crescita, riduzione, variazione
del budget, transitorio insufficiente, saturazione e Serie indipendenti.
Decisioni composte elencate nel contratto. Prima dell'attuatore servono
oracoli differenziali, crash prima/dopo lo swap, snapshot e writer concorrenti,
memoria oltre RAM senza swap e confronti misurati fra le due modalita'.
