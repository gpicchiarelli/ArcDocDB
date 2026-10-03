# Tracciabilità

La tracciabilità è **bidirezionale e controllata da uno strumento**
([ADR-0035](../adr/0035-strategia-di-verifica-e-tracciabilita.md), INV-A5).

```
specifica / ADR  →  REQ-…  →  invarianti, ADR, classe  →  codice (;;; REQ:) → test → esito
                      ▲                                                          │
                      └──────────────  matrice generata, `make trace`  ◀─────────┘
```

## File

| File | Contenuto |
|---|---|
| [requisiti.lisp](requisiti.lisp) | i requisiti, come dati: fonte, enunciato, classe, invarianti, ADR, metodi di verifica, scenari FI, stato |
| [matrice.md](matrice.md) | la matrice **generata**: requisiti, copertura degli invarianti e degli scenari FI, ADR → requisiti |
| [`tools/check-trace.lisp`](../../tools/check-trace.lisp) | validazione e generazione |

## Comandi

```bash
make trace          # verifica; fallisce se qualcosa è incoerente
make trace-write    # rigenera matrice.md dopo aver modificato requisiti.lisp
```

## Che cosa viene controllato

1. Ogni requisito ha identificativo `REQ-<AREA>-<nnn>`, fonte, enunciato, classe di integrità
   (C1…C4), stato e almeno un metodo di verifica; gli identificativi sono unici.
2. Ogni `INV-`, `ADR-` e `FI-` citato **esiste** nella documentazione.
3. **Ogni invariante** di [invarianti.md](../invarianti.md) è coperto da almeno un requisito.
4. **Ogni scenario** di [fault injection](../14-fault-injection.md) è coperto da almeno un
   requisito; un requisito verificato con `:fi` indica gli scenari.
5. Ogni riferimento `REQ-…` in `src/`, `tests/`, `tools/` indica un requisito esistente.
6. Un requisito `:implementato` o `:verificato` è citato nel codice (`src/` o `tools/`) e,
   se non è di classe C4, nei test.
7. La matrice committata è esattamente quella generata.

## Stati di un requisito

| Stato | Significato |
|---|---|
| `:specificato` | enunciato definito, senza progetto |
| `:progettato` | realizzato da ADR e documenti; nessun codice |
| `:implementato` | codice presente e tracciato (`;;; REQ: REQ-…`) |
| `:verificato` | tutte le verifiche dell'elenco `:ver` eseguite e verdi |

## Come si aggiunge o si cambia un requisito

1. Modificare [requisiti.lisp](requisiti.lisp): un requisito si **ritira** (stato e nota), non si
   rinumera né si riusa l'identificativo.
2. `make trace-write`, poi `make trace`.
3. Citare gli ID nei commit (`Refs: REQ-…`) e, quando c'è codice, in `;;; REQ:` e nel nome del
   test.

## Limiti dichiarati

- Lo strumento controlla l'**esistenza** e la **completezza** dei collegamenti, non la loro
  **correttezza semantica**: che un requisito sia davvero realizzato da quell'ADR lo stabilisce
  la revisione ([lista di controllo](../affidabilita/standard-di-codifica.md#lista-di-controllo-di-revisione-c1)).
- Fino alla Fase 1 non c'è codice di prodotto: i controlli 5 e 6 sono attivi ma si applicano
  solo agli strumenti.
