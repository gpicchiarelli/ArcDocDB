# Hash delle chiavi e seme dell'indice

## Contratto

ADR-0014 richiede un hash non crittografico a 64 bit con seme per Serie.
Il kernel implementa XXH64 della
[specifica ufficiale in xxHash v0.8.3](https://github.com/Cyan4973/xxHash/blob/v0.8.3/doc/xxhash_spec.md).
Non introduce dipendenze di prodotto oltre SBCL/ASDF. Riferimenti:
REQ-IDX-001, REQ-IDX-003, REQ-IDX-005, REQ-LIM-003, REQ-AFF-004 e REQ-AFF-008;
invarianti INV-I3 e INV-P6.

```lisp
(arcdocdb.hash64:xxh64 octets start end seed-high seed-low)
;; => high, low: esattamente due u32
```

Span half-open, da zero a 65.535 byte, vettore simple u8. Un hash di span
vuoto e ammesso; il writer mantiene separatamente il vincolo di almeno un
byte della chiave. I due u32 sono fixnum su SBCL a 64 bit. Nessun u64
attraversa il confine pubblico: operazioni modulari e helper inline conservano
le parole native. Safety 3 e controlli di tipo/range restano attivi.
Il chiamante mantiene buffer e seme immutati per tutta la chiamata.

La validazione rifiuta tipi/semi non conformi con INVALID-ARGUMENT
`:hash-arguments`, span fuori buffer con `:buffer-range`, lunghezza oltre
limite con `:hash-span-limit`. Input immutato anche sul rifiuto.
Il kernel non possiede stato, lock, scratch, I/O o fonti casuali.

## Seme posseduto dalla Serie

`crea-indice-primario` accetta `:hash-seed-high` e `:hash-seed-low`:
entrambi u32 espliciti oppure entrambi NIL. La coppia incompleta/non conforme
e rifiutata con `:primary-hash-seed-configuration` prima degli array.
Il seme configurato e read-only per tutta la vita dell'indice.
`digest-chiave-indice` verifica salute/configurazione e usa questa coppia.
L'indice senza seme conserva la API di basso livello a digest fidati;
le nuove API hash lo rifiutano con `:primary-hash-unconfigured`.
Una coppia interna incoerente rende terminale l'indice con
`:primary-hash-seed-corrupt`.

Generazione, entropia iniettabile, ricostruzione al riavvio e scelta del seme
appartengono al controller. Non e introdotto un valore casuale implicito,
ne e consentito cambiare il seme di una root gia popolata. Le API a digest
precalcolati rimangono interfacce fidate del sottosistema; il confine esterno
deve calcolare lo stesso digest posseduto dall'indice.

## Digest per la ricostruzione

```lisp
(arcdocdb.index.primary:calcola-digests-frammento
 index source highs lows seed-high seed-low)
;; => C, slot-vivi, byte-chiavi-hashati
```

Solo writer con gettone esclusivo. Il sorgente deve essere canonico,
corrente, pubblicato e scrivibile. Due array simple u32 distinti di C elementi,
privati e gia prenotati. Preflight dei tipi, lunghezze, alias e seme
completo uguale alla coppia dell'indice, prima di allocazioni e scritture.
Il controllo di entrambi i u32 non dipende dai pochi bit osservabili
nel fingerprint o nel prefisso del frammento.

Una scansione di C slot campiona il payload, calcola XXH64 sui byte vivi
e verifica fingerprint, prefisso e lookup allo slot fisico originale.
Scrive solo le celle vive; EMPTY/DELETED conservano le sentinelle.
Il risultato alimenta il [costruttore verificato](indice-ricostruzione.md).
Root, banco, arena, salute sana e revisione non vengono modificati.
Un errore di dominio/corruzione segue il fail-stop esistente; mappe private
parziali su errore durante la scansione si scartano, senza rollback dell'indice.
Root assente: `:primary-index-missing-root`. Discordanza del digest
ricalcolato internamente: `:primary-hash-source-digest`, sempre FAULTED.
I digest esterni fidati del rebuild conservano il contratto dei rifiuti.

Budget separato: mappe 8*C byte e due scratch fissi da cinque u64,
80 byte di payload oltre header/runtime. Non sono parte del budget di
copia del rebuild. Costo: O(C + byte-chiavi-vive) per scansione/hash,
oltre ai probe originali limitati da C per chiave; caso ostile O(C²*K).
Nessuna pretesa di pausa costante o P99. La manutenzione alloca fuori
dal percorso caldo.

## Verifica

[Campagna e metodo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-key-hash/README.md).
[Revisioni e correzioni](hash-chiavi-revisione.md).
[Prove e misure conservate](hash-chiavi-risultati.md).
Oracolo freddo indipendente, vettori upstream, ogni residuo e allineamento,
semi oltre fixnum, immutabilita e worker reali. Prove della mappa con
lookup/rebuild/split, predicati e mutanti nominati; misure seriali e
parallele separate dopo i controlli.

Hash e fingerprint sono acceleratori: la ricerca decide sempre con
confronto bytewise della chiave. Non si usa il digest per autenticare
input o dati persistenti. Restano controller/seed lifecycle, GET completo,
misure del motore, P99 e qualifica della piattaforma di riferimento.
