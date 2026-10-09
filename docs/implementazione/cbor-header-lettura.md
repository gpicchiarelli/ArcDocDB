# Prima lettura degli header CBOR

Lettura del coordinatore dopo il congelamento dei tre file di test indipendenti
(17 nominali) e dei due sorgenti di prodotto. Il coordinatore ha stabilito il
contratto e collegato ASDF; non ha scritto i due sorgenti. La seconda lettura
è attribuita all'autore degli oracoli nel [referto separato](cbor-header-revisione.md).
Queste sono letture automatizzate locali, senza approvazione umana di rilascio.

Nessun difetto del kernel riscontrato nella lettura statica. Il range pubblico
verifica tipi prima della lunghezza e numeri prima dei byte. Span vuoto e AI
riservati hanno motivi e offset distinti. AI31 ritorna prima del calcolo della
larghezza; il caso major7 resta un marker senza attestazione strutturale.
La guardia width<=end-start precede tutti i byte dell'argomento e garantisce
che next=start+width sia un index. Si accumulano al massimo quattro byte per
parola: le rotazioni BE non costruiscono un intero a 64 bit. F8 controlla il
valore semplice dopo la disponibilità del secondo byte; F9/FA/FB conservano
anche NaN e infinity. I sei valori sono coerenti con il contratto congelato.

Il modulo ha quattro funzioni brevi, FTYPE completi, safety3, condizioni
tipizzate, input di proprietà del chiamante e nessuno stato mutabile globale.
Le guardie interne di range/progresso difendono le dipendenze fra helper;
nessun input pubblico corretto le rende false. Il [registro delle decisioni](cbor-header-decisioni.md)
le mantiene esplicite. Non vengono escluse dalla copertura.

Gli oracoli freddi possono costruire liste e bignum; il kernel e la misura
non li usano come risultati caldi. Il test thread verifica i sei valori prima
del sink, contenuto integrale e sovrapposizione dei soli intervalli di lavoro.
Semafori, join e cleanup hanno timeout e controllano la cessazione. Queste
prove attestano compatibilità con letture concorrenti su buffer privati;
il runtime del pool e il parser completo restano successivi.

Build, campagne di copertura/mutazione e allocazioni sono previste nel
[metodo](cbor-header-metodo.md), ancora da eseguire al momento di questa lettura.
Il referto statico non anticipa gli esiti. L'integrazione non promuove gate
C1 completi, MC/DC, requisiti del decoder o qualificazione del motore.
