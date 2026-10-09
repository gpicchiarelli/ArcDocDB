# Contribuire

ArcDocDB è in **Fase 0** (definizione architetturale e valutazione): oggi si contribuisce a
specifica, ADR, valutazione e spike. L'autore ha inoltre autorizzato le
[fondazioni implementative](docs/implementazione/README.md) dal 2026-10-08;
restano aperti i criteri di uscita della Fase 0
([roadmap](docs/roadmap.md)).

La [guida al repository](docs/guida-al-repository.md) raccoglie le regole di lavoro,
le fonti di verità e i criteri di affidabilità.

## Principi

- Si scrive **una volta sola, con la soluzione migliore nota**: vedi
  [principi di ingegneria](docs/principi-di-ingegneria.md). Niente codice provvisorio.
- **Solo Common Lisp** ([ADR-0001](docs/adr/0001-common-lisp-sbcl.md)), nessuna dipendenza
  esterna ([ADR-0027](docs/adr/0027-dipendenze-e-test.md)).
- La [specifica](docs/specifica/specifica-originale.md) è la fonte di verità; la cambia solo un
  ADR che dichiara l'emendamento.

## Flusso

1. Una modifica di requisito o di formato parte da un [ADR](docs/adr/README.md)
   (modello: [0000](docs/adr/0000-modello.md)); un ADR accettato non si riscrive, si
   sostituisce.
2. Si propaga nello **stesso commit** a invarianti e documenti tematici.
3. Gli identificativi (`INV-`, `QA-`, `FI-`, `RSK-`, `SPK-`, `ADR-`, `REQ-`, `AP-`) sono stabili.
4. Gli spike vivono in [`spikes/`](spikes/README.md) e sono usa-e-getta.

## Prima di aprire una pull request

```bash
make check
```

Compila senza avvisi, esegue test e linter, controlla tracciabilità e collegamenti,
e verifica la correttezza dei nove esperimenti disponibili. Le misure di prestazione
si eseguono separatamente con `make spikes-bench`.

## Convenzioni

- Documentazione in italiano; termini di dominio in italiano anche nel codice
  ([glossario](docs/glossario.md)).
- Ciò che non viene dalla specifica è marcato `Proposta`, `Deciso (… → ADR-nnnn)` o `Aperto (QA-nn)`.
- Numeri di prestazione solo se misurati in modo riproducibile
  ([benchmark](docs/13-benchmark.md#riproducibilità)).

## Orientarsi

[Documentazione](docs/README.md) · [Decisioni](docs/adr/README.md) ·
[Esperimenti](spikes/README.md) · [Sicurezza](SECURITY.md)
