# Identità visiva

## File

| File | Uso |
|---|---|
| [`img/arcdocdb-logo.svg`](img/arcdocdb-logo.svg) | logo per sfondo chiaro |
| [`img/arcdocdb-logo-dark.svg`](img/arcdocdb-logo-dark.svg) | logo per sfondo scuro |
| `img/arcdocdb-hero.png` | immagine hero del README — **da generare** (vedi sotto) |

## Palette

| Colore | Esadecimale | Uso |
|---|---|---|
| Petrolio scuro | `#1f3f43` | testo del logo, badge di piattaforma |
| Petrolio | `#3f7a80` | colore principale: badge, accenti |
| Petrolio chiaro | `#5a9aa0` | badge di conteggio, secondo livello |
| Verde esito | `#2e7d32` | badge di esito positivo |
| Ambra | `#d4a017` | badge di fase |
| Rosso critico | `#b71c1c` | badge «safety-critical» |

Il marchio: tre segmenti impilati (i segmenti immutabili) sotto un arco (l'Archivio).

## Immagine hero

Riferimento di stile: l'hero di [GPForum](https://github.com/gpicchiarelli/GPForum), un render
fotorealistico cinematografico in 16:9 (1672 × 941): stanza in penombra, luce dorata radente,
materiali veri, un elemento a parete che racconta il software e un angolo tecnologico sullo
sfondo. Per ArcDocDB: **villa di campagna, legno e ottone, tecnologia discreta**.

Un'immagine di questo tipo richiede un generatore di immagini; non è producibile con il codice
del repository. Una volta generata va salvata come `img/arcdocdb-hero.png` e inserita in cima
al `README.md` con il testo alternativo riportato sotto.

### Prompt

```
Photorealistic cinematic architectural interior photograph at golden hour, 35mm lens.
A quiet, dimly lit study inside a country villa, warm oak and walnut timber everywhere:
vertical slatted wood panelling on the left, exposed dark ceiling beams with small brass
track spotlights, a wide-plank oak floor with soft reflections and long amber light shafts
from tall black steel-framed windows on the right that open onto a green Tuscan hillside
with cypress trees in soft focus.

The main wall is a monumental archive of identical leather-bound ledgers on dark oak
shelves, hundreds of volumes in tidy rows, each spine with a small brass label, and a slim
warm strip light along the base of the shelves. One single open ledger rests on a lit oak
lectern in front of it.

In the left background, through a glass and black steel door, a small technical room: two
server racks with softly glowing green and amber status LEDs and a wall monitor showing a
calm graph. The technology is discreet, integrated into the wood, never dominant.

Foreground right: a long walnut table with a brass reading lamp, a ceramic cup, a closed
laptop and a small brass hourglass. Large potted green plants near the panelling and by
the window.

Calm, serious, durable mood. Warm amber highlights against deep green-brown shadows,
shallow depth of field, subtle film grain, volumetric dust in the light, high dynamic
range, ultra detailed realistic materials. No people, no text, no logos, no watermark.
```

### Prompt negativo (dove supportato)

```
cartoon, illustration, flat vector, 3d render look, plastic, oversaturated, neon colors,
cyberpunk, futuristic, sci-fi, people, faces, text, letters, logos, watermark, clutter
```

### Variante «stanze tematiche»

Aggiungere: *a long hallway of the villa with three open arched doorways in the background,
each showing a different room in the same timber-and-brass style: a registry room with a wall
of small oak catalogue drawers and an unrolled paper scroll on a desk; a workshop where a
large worn ledger stands next to a small crisp new one and a brass hourglass; a quiet room
with a single writing desk and a lamp.*

### Testo alternativo

> A quiet country-villa archive in warm timber and brass: a wall of identical ledgers, a
> single open ledger under a lamp, and a discreet server room glowing in the background.
