# Riferimenti fisici full text — metodo preregistrato

17 ottobre 2026. REQ-SEC-004/006/010, REQ-WAL-005 e REQ-CON-002;
ADR-0037/0039/0047/0054, INV-I5/I6 e INV-P6. Il prossimo elemento della mappa
del delta e un riferimento preallocato per la riserva, catturato dal lotto
sigillato con token CSN autorevole prima della consegna all'I/O.

La cattura non pubblica, non prova durability e non risolve un prepared. Conserva
row, segmento, offset assoluto, lunghezza, versione e stamp in due parole;
lo stamp e CSN per un ordinario, TXID per un prepared. Il getter resta valido
dopo il riuso del buffer; nessun riuso delle riserve trasferite e introdotto.

| Decisione | Verifiche previste |
|---|---|
| Ownership | lease e token canonici; solo riserva trasferita dal ponte PUT |
| Lifetime | stessa incarnazione/intervallo; lotto SEALED e non consegnato al gruppo I/O |
| Autorita | registro e log esatti del token WAL pendente; log segmento sano |
| Header | CRC su soli 20 byte, span/tipo/flag e stamp coerenti; nessuna scansione del body |
| Ordinario | stamp uguale al CSN catturato alla chiusura, mai uno stamp manuale non associato |
| Prepared | TXID uguale al valore catturato all'append; mai sostituito dal CSN del lotto |
| Cattura | campi gia preallocati, somma offset verificata prima degli effetti; nessun budget normale dopo SEAL |
| Guasto | header incoerente o cattura interrotta => pool/lotto FAULTED, dati e costi conservati |
| Getter | solo riferimento interamente catturato; nessuna dipendenza dal buffer riusato |

Oracoli: record indipendente bitwise v1/v2, posizione calcolata dal prefisso del
file e dai record precedenti, stamp a bordi u32/u64; riuso reale dei lotti dopo
write/flush e risoluzione del token nella fixture. Rifiuti conservativi prima degli
effetti; header corrotti anche con CRC ricalcolato. Prova nativa su file completo,
riaperto in sola lettura, confronto dei byte raggiunti dal riferimento.

Heap: estendere la misura PUT gia esclusa dalla copertura strumentata con chiusura
WAL, mille catture/getter su slot preallocati e ID 1/UINT64_MAX. Probe CRC dimostra
che la cattura legge solo l'header; controllo negativo sul vecchio scanner completo.
Conservare tutti i tentativi e i sorgenti effettivi. Due letture dello stesso autore;
qualifica C1, MC/DC e verifica indipendente complessiva rimangono aperte.

## Due letture dello stesso autore

Prima lettura: seguiti lease, generation della riserva e incarnazione del lotto;
autorita del token richiesta prima di leggere lo stamp. Flag e TXID originali
catturati all'append del frame privato; CSN ordinari verificati solo dopo chiusura.
Offset e forma prima degli effetti, nessun rilascio o fallimento normale di capienza
dopo SEAL. Getter senza riferimenti al buffer, senza claim di visibilita o durability.

Seconda lettura: seguiti errori di header, cattura incompleta e riuso reale del lotto.
Effetto protetto fin dal suo avvio, stato SEALED fissato per ultimo, invarianti
prima/dopo il setter interno; fault conserva costi e CSN. La quota metadata del
pool rimane conservativa e le sei esclusioni di allocazione del catalogo CI sono
invariate. Le due letture dello stesso autore non sono una revisione indipendente
e non chiudono C1 o MC/DC.
