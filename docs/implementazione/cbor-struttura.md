# Scansione della struttura CBOR

Il codec attraversa un item completo con stack preallocato e verifica
struttura, UTF-8 e budget, senza creare un documento decodificato.
L'API prepara una base per la validazione sui worker prevista da ADR-0029;
il collegamento all'ammissione delle operazioni resta successivo.

```lisp
(let ((spazio (arcdocdb.cbor:crea-spazio-cbor))) ; prima del percorso caldo
  (arcdocdb.cbor:verifica-struttura-cbor
   buffer start end spazio
   :max-bytes 16777216 :max-nodes 16777216 :max-depth 100))
;; => nodi, profondità massima di array/map, end
```

Lo span `[start,end)` appartiene al chiamante e rimane immutabile.
Ogni worker possiede uno spazio distinto, usato da una sola chiamata alla
volta e riusabile dopo errore. La factory crea una struttura e due array
fissi di 102 celle; lo spazio non trattiene il buffer. Sono disponibili
budget inferiori ai default, compresa profondità zero per scalari/stringhe.

Ogni header item, compresi tag e chunk vuoti, conta un nodo; il break non
conta. Solo array/map aumentano la profondità, inclusi contenitori vuoti,
chiavi e valori. Un tag non consuma un figlio del padre prima dell'item
seguente. I chunk di stringhe indefinite sono definiti e dello stesso tipo;
ciascun chunk di testo deve contenere sequenze UTF-8 complete. Il successo
richiede la fine esatta dello span, senza un secondo item o byte residui.

Range, spazio, alias con l'array privato dei kind e configurazioni invalidi
sono `invalid-argument`. Lo span oltre budget, i nodi o la profondità sono
`resource-exhausted`. Sintassi, troncatura, break/chunk e UTF-8 errati sono
`corruption-detected`; motivi e offset assoluti distinguono il punto di
rifiuto. Le precedenze complete sono registrate nel
[metodo](cbor-struttura-metodo.md). Un preflight rifiutato lascia lo spazio
invariato; gli errori runtime consentono il reset alla chiamata successiva.

Il controllo del profilo documentale di ADR-0014 resta da implementare:
semantica dei tag, duplicati e ordinamento delle chiavi, rappresentazioni
minime e regole dei float. Lo scanner accetta questi casi come struttura
generica. Il risultato non attesta validità semantica completa o codifica
deterministica.

Le verifiche comprendono oracoli indipendenti, corpus generato, fuzz finito,
confini di 16MiB e 100 livelli e due thread con buffer/spazi privati.
[Prima lettura](cbor-struttura-lettura.md),
[seconda lettura](cbor-struttura-revisione.md),
[inventario delle decisioni](cbor-struttura-decisioni.md) e
[lettura dei driver](cbor-struttura-driver-review.md) distinguono riscontri
statici e campagne runtime. [Risultati e dati grezzi](cbor-struttura-risultati.md).
Le prove del modulo non qualificano il motore,
la durabilità o lo scaling del pool.
