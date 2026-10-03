# Contribuire

ArcDocDB è in **Fase 0** (definizione architetturale e valutazione): oggi si contribuisce a
specifica, ADR, valutazione e spike. Il codice di produzione inizia con la Fase 1
([roadmap](docs/roadmap.md)).

## Principi

- Si scrive **una volta sola, con la soluzione migliore nota**: vedi
  [principi di ingegneria](docs/principi-di-ingegneria.md). Niente codice provvisorio.
- **Solo Common Lisp** ([ADR-0001](docs/adr/0001-common-lisp-sbcl.md)), nessuna dipendenza
  esterna ([ADR-0027](docs/adr/0027-dipendenze-e-test.md)).
- La [specifica](docs/specifica/prompt-originale.md) è la fonte di verità; la cambia solo un
  ADR che dichiara l'emendamento.

## Flusso

1. Una modifica di requisito o di formato parte da un [ADR](docs/adr/README.md)
   (modello: [0000](docs/adr/0000-modello.md)); un ADR accettato non si riscrive, si
   sostituisce.
2. Si propaga nello **stesso commit** a invarianti e documenti tematici.
3. Gli identificativi (`INV-`, `QA-`, `FI-`, `RSK-`, `SPK-`, `ADR-`) sono stabili.
4. Gli spike vivono in [`spikes/`](spikes/README.md) e sono usa-e-getta.

## Prima di aprire una pull request

```bash
make check
```

Esegue gli smoke test (SBCL) e la verifica di link e ancore della documentazione.

## Convenzioni

- Documentazione in italiano; termini di dominio in italiano anche nel codice
  ([glossario](docs/glossario.md)).
- Ciò che non viene dalla specifica è marcato `Proposta` o `Aperto (QA-nn)`.
- Numeri di prestazione solo se misurati in modo riproducibile
  ([benchmark](docs/13-benchmark.md#riproducibilità)).
