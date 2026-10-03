# Eccezioni alla copertura

Elenco delle righe di codice C1/C2 che la suite **non** può raggiungere, con motivazione e
verifica sostitutiva ([piano di verifica](piano-di-verifica.md#copertura)). Una riga non
raggiungibile senza motivo è un difetto di test o codice morto: va coperta o rimossa.

| Campo | Contenuto |
|---|---|
| ID | `COV-nnn`, stabile |
| Dove | modulo, funzione, riga |
| Perché non raggiungibile | ad esempio ramo difensivo su un invariante già garantito dal tipo |
| Verifica sostitutiva | ispezione, asserzione, test del modello |
| Approvazione | data |

## Eccezioni approvate

Nessuna (non c'è ancora codice di prodotto).
