# M0 — Metodo preregistrato per il lifetime dei frame

Data: 2026-10-22. Questo metodo precede la prima esecuzione del nuovo modello.
Classe C4; nessun codice di cache del prodotto viene introdotto o qualificato.

## Ipotesi e oracolo

Si esplorano tutti gli interleaving sequentially consistent di un frame fisso,
uno o due reader con un hazard slot privato ciascuno e uno o due riusi.
Metadati READY/RETIRING/BUILDING, annuncio, conferma e singole letture/scritture
sono passi atomici distinti. Una scansione del reclaimer legge un hazard per
passo; non e' una fotografia atomica dell'intero registro. Il contenuto ha due
campi scritti e copiati separatamente; l'incarnazione logica non viene riciclata.

Il reader legge l'identita', annuncia il token, riconferma READY e token,
copia entrambi i campi, poi cancella l'annuncio. Un mancato confronto completa
un tentativo con MISS, senza rileggere il contenuto. Il reclaimer chiude READY,
scansiona gli slot e riscrive solo senza protezioni corrispondenti. Un annuncio
tardivo dopo la scansione e' innocuo perche' la riconferma fallisce.

L'oracolo, distinto dal token, e' l'incarnazione logica osservata dal primo
passo del reader. Qualunque campo copiato diverso da essa e' una violazione.
La copia privata resta verificabile anche dopo rilascio e riuso del frame.

## Criteri prima dell'esecuzione

- Nessuna violazione per 1 reader/1 riuso, 1/2, 2/1 e 2/2.
- Limite duro 200.000 stati per configurazione: esaurirlo e' errore.
- Testimoni di successo, copia durante RETIRING, reclaimer fermato da un
  hazard e annuncio tardivo dopo la chiusura devono essere raggiunti.
- Ogni controllo negativo deve produrre un controesempio: assenza di
  riconferma, rilascio fra le due copie, scansione ignorata, ABA con token
  riciclato dopo due riusi. Conservare il percorso e lo stato del guasto.
- Compilazione con safety 3 e avvisi fatali; esecuzione anche nella suite SPK-07.

## Progresso e limiti

Il reader ha al massimo sette passi propri, senza ciclo o attesa del writer;
la funzione di rango e' 6-fase, con completamento anticipato sul miss.
Questo argomento riguarda un singolo tentativo sotto SC e primitive astratte
terminanti. Un MISS non dimostra il completamento di un lookup o di un GET.
Un reader sospeso con hazard puo' impedire il riuso del frame, non i passi
degli altri reader. Una cache finita tutta protetta puo' impedire il caricamento.

Il modello non dimostra il modello di memoria ARM64/x86-64, la realizzazione
SBCL delle primitive, l'assenza di pause GC, la linearizzabilita' del database,
il lookup della directory, il budget del processo, snapshot, commit o I/O.
Non qualifica lock-free il prodotto. La generazione deve esaurirsi senza wrap
e il confronto reale deve includere PageRef, frame e generazione, senza ABA.

Il pattern deriva dagli hazard pointers di Michael, 2004:
[pubblicazione IBM](https://research.ibm.com/publications/hazard-pointers-safe-memory-reclamation-for-lock-free-objects).
L'eventuale traduzione in prodotto richiedera' un ADR e verifica delle primitive
[SBCL](https://www.sbcl.org/manual/#Atomic-Operations) e delle barriere documentate.

## Conservazione

Registrare con `tools/record-command.lisp` ogni esecuzione, anche fallita.
Nessuna modifica alle sorgenti durante un run. Conservare metodo, modello,
driver e record originali in un nuovo archivio; risultati in un documento
distinto, senza trasformare il gate aperto in una qualifica del motore.
