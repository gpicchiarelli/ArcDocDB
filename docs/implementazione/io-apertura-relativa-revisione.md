# Apertura relativa: letture C1

Due letture statiche precedono compilazione ed esecuzione: root e revisore
distinto sul prodotto; root e autore dei test sul collegamento e sulle
asserzioni C4. Il [metodo preregistrato](io-apertura-relativa-metodo.md)
definisce OR-D01…D10 prima delle prove. Nessun rilievo di flusso rimane
aperto; la rilettura ha completato le condizioni dichiarate nelle docstring.

Fonti finali del prodotto, SHA-256:

| File in `src/io/` | SHA-256 |
|---|---|
| `native-open-relative.lisp` | `3ec8ca51841d3d07ce1e69153dbf069eecaa9de484d9c976642fc03527c3af32` |
| `open-relative.lisp` | `f1d37c3ca3d5d186cc02ecbf6479216d9b7c2d731ca06707004469077d795ecd` |
| `types.lisp` | `a934f29924bd798ebb0aeb3ba7e75c23abc188820c8e78b3a35a6ed8796423d5` |
| `package.lisp` | `758e9ea9d232d5d3f56d9b1e4aa9ea3d6044dbaa5b6af06c8f4506542ad83bca` |

| Punto della checklist C1 | Lettura statica |
|---|---|
| 1. Requisiti e ADR | REQ-STO-003, REQ-REC-001, REQ-AFF-001/004/008/018, REQ-FOR-001; ADR-0017/0033/0035/0040 e COD-37 coerenti |
| 2. Invarianti | INV-A7/A9/A10, INV-P6/X3; casi su parent, byte, identità, frontiere e cleanup |
| 3. Errori | Tipi e provenienza espliciti; test di condizione originaria, syscall e doppio guasto; close nonzero anche con errno NIL |
| 4. Cicli e attese | Nessun ciclo di prodotto nuovo; nome limitato a 255 byte; syscall nel pool I/O senza deadline wall |
| 5. Heap | Apertura con allocazioni ammesse e foglia limitata; nessuna misura del percorso caldo o RSS dichiarata |
| 6. Confini | FD e tuple validati prima della pubblicazione; FD 0 ammesso, alias parent rifiutato; EOF non ristretto prima del budget |
| 7. Decisioni | OR-D01…D10; copertura dinamica e MC/DC restano distinte dalla lettura |
| 8. Ownership | Parent borrowed; copia e child privati prima di openat; handoff protetto; un solo cleanup del child anche con parent invalidato |
| 9. Tracciabilità e check | Riferimenti presenti; rigenerazione matrice e `make check` richiesti sul commit congelato, esiti registrati separatamente |
| 10. Regole | ftype, safety 3, docstring e funzioni sotto 60 righe; nessun handler generico di prodotto o dipendenza nuova |
| 11. Parallelismo | Nessun lock, attesa o scrittura condivisa fra Serie; controller proprietario del namespace e delle capacità |
| 12. Durability | Nessuna modifica durevole o eliminazione; EOF osservato distinto dalle frontiere valide/committed/durable |

Il confronto di device/inode conserva componenti signed e unsigned a 64 bit.
L'EOF può essere zero o un intero grande: valori negativi/non interi sono
rifiutati, quelli eccessivi producono un errore di risorsa prima di ogni
restringimento. Callback mancanti non attivano un fallback nativo.

Le callback sono fidate. Il controller impedisce mutazioni del namespace,
modifiche del file e chiusure concorrenti. Le finestre senza interrupt
proteggono handoff e cleanup; non definiscono cancellazione asincrona.
Uscite non locali estranee tentano cleanup una volta, senza allegare alla
causa l'errno secondario; errori estranei nella callback di close restano
fuori protocollo. Le deadline C4 sono cooperative.

La fixture verticale passa EOF e capacità della stessa apertura ai reader
CONTROL, decision log e ACTIVE; bootstrap, output e coordinamento restano
C4. Questa lettura non attesta qualifica C1 completa, MC/DC, mutation
testing dei nuovi percorsi, prestazioni o un Recovery Manager completo.
