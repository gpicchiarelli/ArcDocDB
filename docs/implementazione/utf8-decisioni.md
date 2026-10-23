# Decisioni della validazione UTF-8

Inventario delle decisioni composte in `src/codec/utf8.lisp`. Gli oracoli
dei dati pubblici sono dichiarati prima della lettura del prodotto nel
[metodo](utf8-metodo.md). Le guardie interne difendono il contratto tra helper;
il chiamante pubblico non può falsificarle dopo il preflight corretto.

| Funzione e decisione | Condizioni e casi indipendenti |
|---|---|
| `check-utf8-arguments`: `and` del range | Buffer `octets`; start `index`; end `index`; `start <= end <= length`. Buffer generico/adjustable/displaced, start o end negativo/non intero/oltre fixnum, start > end, end > length. La catena numerica ha entrambi i confini esercitati separatamente. |
| `check-utf8-arguments`: `and` del budget | Budget `index`; budget <= 16 MiB. Negativo/non intero/oltre fixnum e 16 MiB+1, con range valido; budget 0 e 16 MiB validi. Il controllo avviene prima dei byte. |
| `verifica-carattere-utf8`: `and` del progresso | cursor < next; next <= end. Sono invarianti interni dopo il controllo della larghezza e delle continuazioni. Il percorso pubblico esercita le larghezze 1/2/3/4, lo span esatto e quello troncato; nessun input pubblico rende false queste condizioni. |

Le catene `<=` richiedono entrambi i limiti: lead C2..DF, E0..EF e F0..F4;
continuazioni 80..BF; scalar second fra minimo e massimo del prefisso. Le
fixture manuali controllano ciascun bordo, i byte immediatamente esterni,
E0 A0/ED 9F/F0 90/F4 8F e i quattro prefissi esclusi. Dopo un lead valido
la troncatura precede il contenuto; dopo la larghezza verificata una
continuazione invalida precede la restrizione scalare.

Nessuna decisione `or` è presente nel prodotto. Il ramo finale del `cond`
classifica un byte iniziale malformato previsto; segnala `corruption-detected`,
non un'incoerenza interna. Le altre guardie interne segnalano
`invariant-violation`; il futuro confine del worker dovrà applicare il fail-stop.

Questa tabella registra l'ambito e i limiti delle prove. Non dichiara MC/DC
completa, non esclude guardie dal denominatore di copertura e non costituisce
una deroga approvata ai criteri C1 del motore.
