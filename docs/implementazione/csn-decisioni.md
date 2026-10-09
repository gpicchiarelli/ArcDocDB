# Decisioni C1 — registro CSN

Lettura del realizzatore prima dell'esecuzione. Invarianti INV-M4, INV-M6, INV-A8;
REQ-MVC-005, REQ-MVC-008, REQ-AFF-008. I test successivi devono esercitare ogni
condizione modificabile singolarmente, con rifiuto e conservazione dello stato.
Questa tabella non dichiara copertura strumentale né qualifica del motore.

| Decisione | Condizioni | Casi richiesti |
|---|---|---|
| Configurazione | capacità nel dominio; high u32; low u32 | capacità 0/65537/tipo errato; high/low negativi, 2^32, non interi; confini validi |
| Guardia | owner corrente; tentativo riuscito | chiamata ricorsiva, altro thread proprietario, acquisizione libera |
| Forma del registro | lunghezza high=K; low=K; used≤K; cursor<K | FI per ogni campo incoerente; registro valido |
| Frontiere | ultimo<H; used=0 con H≠ultimo | FI ordine high, ordine low a high uguale, differenza di ciascuna parola |
| Credito | used=K | capacità piena, rifiuto senza avanzare ultimo, risoluzione e nuovo credito |
| Esaurimento | high=2^32−1 e low=2^32−1 | entrambe vere; high massimo/low inferiore; low massimo/high inferiore |
| Slot libero | high=0 e low=0 | libero, CSN basso con solo low, carry con solo high, entrambi non zero |
| Incremento | low massimo | incremento normale, carry, passaggio oltre fixnum, massimo u64 |
| Forma del token | slot index e slot<K; high/low u32; almeno una parola positiva | singoli tipi/range errati; zero/zero; ciascuna parola sola positiva |
| Identità del token | high e low coincidono con slot | ciascuna parola differente, stale dopo risoluzione e dopo riuso |
| Token e frontiere | used>0; H<token; token≤ultimo | FI ciascuna incoerenza, token corrente valido |
| Minimo residuo | slot≠risolto; coppia non zero; H<slot≤ultimo | risolto escluso, libero, pendente più vecchio/più nuovo, FI frontiere |
| Conteggio residuo | count=used−1 | vuoto, uno/molti pendenti, conteggio incoerente |
| Decremento del minimo | count>0; low=0 | nessun pendente, borrow high→low massimo, minimo con low positivo |
| Ordine u64 | high minore; high uguale e low minore | high minore con low maggiore; high maggiore; high uguale/low minore/uguale/maggiore |

I valori iniziali derivano dal massimo recuperato; nessun setter pubblico modifica
la base in esercizio. Il controller è proprietario degli obblighi di risoluzione
e del fail-stop: il registro non sa se gli effetti sono stati pubblicati.

Ogni scansione è limitata a K≤65536; nessun callback o I/O dentro il mutex.
Le parole u32 rimangono fixnum su SBCL a 64 bit. Le condizioni d'errore possono
allocare, i successi sono oggetto di misura. L'API accetta token numerici legati
dal chiamante al registro: non rileva lo scambio fra Archivi con token identici.
