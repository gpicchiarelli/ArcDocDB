# Orizzonte dei commit: integrazione del registro unico

L'implementazione attiva del registro CSN è
[`arcdocdb.csn`](../../src/csn/registry.lisp), descritta nel
[contratto canonico](csn.md). Il [collegamento snapshot](snapshot-csn.md)
usa quell'unico registro dell'Archivio. Gli snapshot e i writer non possono
assegnare versioni attraverso due sequenze indipendenti.

La prima implementazione di questo ramo in `arcdocdb.mvcc` è stata rimossa
prima del rilascio. Il modulo MVCC contiene ora solo snapshot, i loro budget
ed il collegamento all'API pubblica CSN. Nessun formato o ADR cambia.

## Adeguamento delle chiamate

| Prima implementazione del ramo | Interfaccia attiva |
|---|---|
| `mvcc:crea-registro-csn` con capacità/base | `csn:crea-registro-csn :capacity :initial-high :initial-low`; base validata dal recovery. |
| Prenotazione e `mvcc:riserva-csn` | `csn:prendi-csn` restituisce slot/high/low; il contesto di commit conserva questi valori insieme al registro. |
| `mvcc:concludi-csn` | `csn:risolvi-csn` riceve il token originale dopo pubblicazione o annullamento corretti. |
| `mvcc:leggi-orizzonte` | `csn:leggi-frontiere-csn`: ultimo-high/low e H-high/low nello stesso campione. |
| `mvcc:orizzonte-raggiunto-p` | Gli snapshot usano il collegamento al campione canonico, senza accedere ai campi privati CSN. |
| Salute del vecchio registro | Il confine dell'Archivio gestisce il guasto CSN, invalida gli snapshot e isola il dominio. |

Non esistono alias che permettano di costruire il vecchio registro.
Le API numeriche high/low non sono capability per input esterno; il token
resta legato al registro dell'Archivio. Un GET corrente non consulta CSN.

## Conservazione delle evidenze

La campagna iniziale di sola compilazione e controlli statici resta integra
nel [catalogo storico](../../spikes/results/2026-10-09-csn-origine/catalogo.lisp).
I report sono stati spostati senza cambiarne i byte, distinguendoli dalla
[campagna del registro canonico](../../spikes/results/2026-10-09-csn/catalogo.lisp).
Le implementazioni precedenti restano nella cronologia Git. La conservazione
non promuove i vecchi controlli statici a qualifica concorrente.
