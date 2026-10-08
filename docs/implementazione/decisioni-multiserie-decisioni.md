# Decisioni della tabella multiserie

Inventario COD-54 da verificare in due letture C1. I casi sono in
[`tests/recovery/`](../../tests/recovery/). La tabella non certifica da sola
copertura MC/DC, durability o applicazione atomica del motore.

| Controllo | Condizioni e casi |
|---|---|
| Configurazione | budget in intervallo; zero valido; valori negativi o oltre il tipo; controllo anche a log vuoto |
| Scansione prima del risultato | prefisso completo; coda finale; corruzione testimoniata successiva; ricerca incompleta; nessuna tabella su errore |
| Conteggio dei record | count zero; esattamente al limite; un record oltre; i duplicati consumano budget |
| Payload DECISION | almeno due partecipanti; consumo esatto; troncamento e byte residui dentro un lotto integro |
| Conteggio dei partecipanti | limite per record; totale esatto; totale superato fra record, anche duplicati |
| Ordinamento dei partecipanti | ID distinti, incluso zero; primo/ultimo byte diverso; bit alto; uguaglianza completa |
| Coalescenza del TXID | nuovo TXID; duplicato con CSN/set uguali; set permutato; CSN o solo set discordante |
| Ricerca del TXID | primo, intermedio e ultimo; assente sotto/fra/sopra; TXID/CSN zero e massimi; CSN condiviso |
| Query di appartenenza | partecipante presente/assente; TXID assente; ID da slice non allineata; range invalido o lunghezza diversa da 16 anche a TXID assente |
| Ownership | sorgente invariato durante costruzione; sorgente sovrascritto dopo costruzione; query stabili; nessun vettore interno esposto |
| Progressione interna | cornici e conteggi coerenti con il prefisso verificato; ordinamento/range/capienza rispettati; guardie difensive sempre attive |

I loop di ordinamento sono limitati dai conteggi effettivi; le query usano
ricerca binaria su dati ordinati. Le definizioni e le guardie interne restano
nel denominatore grezzo della copertura. Eventuali forme non raggiungibili
vengono motivate dopo la misura, senza sottrarle dai totali pubblicati.

Il [metodo](decisioni-multiserie-metodo.md) distingue prove di cornice,
semantica e recovery completo. Una decisione semanticamente invalida dentro
il prefisso sigillato non può trasformarsi in assenza e quindi presumed abort.
