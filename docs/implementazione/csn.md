# CSN di Archivio e orizzonte di visibilità

`arcdocdb.csn` realizza il registro limitato di
[ADR-0046](../adr/0046-orizzonte-con-registro-limitato.md). Ogni Archivio possiede
un registro; le Serie lo toccano alla chiusura e alla risoluzione di un lotto
o di una decisione multiserie. Nessun accesso condiviso per documento.

| API | Contratto |
|---|---|
| `crea-registro-csn :capacity :initial-high :initial-low` | Capacità 1..65536, default 256. Base validata dal recovery; nessun pendente, ultimo=H=base. |
| `prendi-csn registro` | Ritorna `slot, high, low`: CSN nuovo positivo e già registrato. Conservare i tre valori insieme al registro. |
| `risolvi-csn registro slot high low` | Dopo pubblicazione o annullamento validi, libera il credito. Ritorna `H-high, H-low`. |
| `leggi-frontiere-csn registro` | Ritorna `ultimo-high, ultimo-low, H-high, H-low` da una sezione coerente. |

Un CSN è `high × 2^32 + low`; il prodotto conserva le parole separate e non
costruisce bignum sul percorso caldo. Zero identifica uno slot libero. Il
CSN massimo è assegnabile una sola volta; la richiesta successiva è rifiutata
prima di qualsiasi modifica. I token sono numerici e appartengono al registro
conservato dal chiamante: non sono capability per input esterno. Due Archivi
possono assegnare la stessa coppia numerica; non scambiare i loro token.

## Sincronizzazione e progresso

Tutti i campi sono privati e richiedono il mutex di Archivio. Ogni API tenta
l'acquisizione una sola volta, senza attesa; `:csn-busy` richiede che il controller
conservi e riprogrammi il compito. Non ritentare l'assegnazione già riuscita quando
un passo successivo fallisce. Per `risolvi-csn` busy conserva il token e l'obbligo
di risoluzione. Il modulo non crea worker, callback, timer o liste di parcheggio.

Una ricerca circolare visita al più K slot per assegnare; la risoluzione visita
al più K slot per verificare il conteggio e calcolare `H=min(pendenti)-1`. Se non
restano pendenti, `H=ultimo`. Le conclusioni fuori ordine restituiscono subito
il credito e non aumentano H oltre il più vecchio pendente. La distanza numerica
fra ultimo e H non consuma crediti.

La lettura delle frontiere usa lo stesso tentativo di mutex: è coerente anche
attraverso il carry fra le parole. I GET senza snapshot non la chiamano.
Lettura atomica di H senza lock, registrazione e risveglio degli snapshot non
sono esposti da questo blocco. Un snapshot futuro dovrà coordinare sotto lo
stesso protocollo la propria soglia e il CSN di nascita.

## Condizioni e responsabilità

| Condizione/reason | Azione |
|---|---|
| `invalid-argument / :csn-config` | Configurazione o parole iniziali fuori dominio. |
| `resource-exhausted / :csn-busy` | Nessuna modifica; conservare il compito per riprogrammarlo. |
| `resource-exhausted / :csn-full` | Lotto ancora aperto; capacità dei veri pendenti esaurita. |
| `resource-exhausted / :csn-exhausted` | Esaurimento permanente u64; mai wrap o azzeramento. |
| `invalid-argument / :csn-token` | Tipo/range/zero, token vecchio o identità non corrente; nessun credito liberato. |
| `invariant-violation` | Il controller deve applicare fail-stop all'Archivio. |

Un guasto di Serie con CSN in corso non permette di rimuoverlo automaticamente:
la risoluzione richiede pubblicazione o annullamento corretti. H non è la frontiera
dei byte durevoli. Il controller non deve confermare un commit dalla sola risoluzione.

## Avvio e confini

Il recovery deve raccogliere il massimo CSN validato dell'intero Archivio prima
di costruire il registro e ammettere scritture. La base non si può cambiare dopo
la costruzione. Apertura tardiva di Serie, WAL e lifecycle richiedono integrazione;
questa API non autorizza importazioni concorrenti con CSN superiori alla base.

Il [metodo preregistrato](csn-metodo.md) descrive oracoli, mutanti e misure.
Il componente conserva solo stato volatile e non introduce atomicità durevole.
