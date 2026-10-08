# Linguaggio visivo

Tutto ciò che nel repository si vede — marchio, immagini, badge, pagina iniziale — segue
queste regole. Sono poche perché devono essere rispettate sempre.

## Principi

1. **Un solo colore, un solo significato.** L'identità è monocroma. L'unico colore è l'ambra,
   e indica sempre e solo *ciò che può cambiare*: il segmento `ACTIVE` nei disegni, la fase del
   progetto tra i badge. Tutto ciò che è immutabile è inchiostro.
2. **Niente che non serva.** Ogni elemento deve dire qualcosa del sistema. Nessuna decorazione,
   nessuna ombra, nessun gradiente, nessuna cornice.
3. **Il materiale è la pagina.** Le immagini hanno sfondo trasparente e si posano sulla pagina
   di GitHub, chiara o scura. Ogni immagine esiste nelle due varianti.
4. **Una sola forma.** La capsula: una linea con le estremità tonde. È un segmento. Marchio,
   illustrazione e diagramma sono fatti solo di capsule, archi e linee sottili.
5. **I numeri sono testo.** Un numero si scrive nel testo, dove può essere letto e corretto.
   Non diventa un badge.

## Colori

| Nome | Chiaro | Scuro | Uso |
|---|---|---|---|
| Inchiostro | `#1d1d1f` | `#f5f5f7` | marchio, segmenti immutabili, testo dei nodi |
| Grafite | `#6e6e73` | `#a1a1a6` | descrizioni, etichette, fili del diagramma |
| Nebbia | `#d2d2d7` | `#48484a` | contorni, parentesi, tratteggi |
| **Ambra** | `#c9892f` | `#e9a84c` | ciò che cambia: `ACTIVE`, fase corrente |

Nient'altro. Verde e rosso compaiono solo dove li impone GitHub (l'esito della CI).

## Tipografia

Carattere di sistema, in quest'ordine: `-apple-system`, `BlinkMacSystemFont`, `SF Pro Text`,
`Helvetica Neue`, `Helvetica`, `Arial`, `sans-serif`.

| Ruolo | Corpo | Peso | Spaziatura |
|---|---|---|---|
| Nodo del diagramma | 14 | 500 | normale |
| Descrizione | 13 | 400 | normale |
| Etichetta (maiuscolo) | 9,5–10 | 600 | +1,2 – +1,5 |

Il nome del progetto è testo vero nel README, non un'immagine. Le etichette in maiuscolo
spaziato sono riservate ai nomi di stato e alle proprietà (`ACTIVE`, `IMMUTABLE`).

## Marchio

Un arco sopra tre segmenti: l'Archivio e ciò che custodisce. Il primo segmento è ambra.

| Costruzione | Valore |
|---|---|
| Griglia | 64 × 64 |
| Tratto | 5, estremità tonde, per arco e segmenti |
| Arco | semicerchio di raggio 21, centro (32, 30) |
| Segmenti | da x = 11 a x = 53, a y = 39, 48, 57 (passo 9) |
| Spazio di rispetto | un tratto e mezzo su ogni lato |
| Dimensione minima | 16 px |

Non si ruota, non si deforma, non si ricolora, non si affianca al nome in un'unica immagine.

## File

| File | Contenuto |
|---|---|
| [`img/mark-light.svg`](img/mark-light.svg) · [`img/mark-dark.svg`](img/mark-dark.svg) | il marchio |
| [`img/hero-light.svg`](img/hero-light.svg) · [`img/hero-dark.svg`](img/hero-dark.svg) | i segmenti di una Serie |
| [`img/flow-light.svg`](img/flow-light.svg) · [`img/flow-dark.svg`](img/flow-dark.svg) | il percorso di una scrittura e di una lettura |
| [`img/social.svg`](img/social.svg) · [`img/social.png`](img/social.png) | anteprima per i social, 1280 × 640 |

La variante scura di un'immagine è la variante chiara con i quattro colori sostituiti secondo
la tabella sopra; la geometria è identica. Ogni immagine ha `title` e `desc` per chi non la
vede.

L'anteprima per i social non si imposta da riga di comando: si carica `img/social.png` in
*Settings → General → Social preview*.

## Badge

Una sola riga, cinque al massimo, tutti dello stesso stile:
`style=flat-square`, etichetta `#3a3a3c`, valore `#8e8e93`. Solo il badge della fase usa l'ambra
`#c9892f`. Dicono che cosa è il progetto (licenza, linguaggio, runtime, dipendenze, fase); non
contano cose. Il badge della CI, che ha i colori di GitHub, sta nella sezione *Status*.

## La pagina iniziale

Nell'ordine: marchio, nome, una frase, i badge, la navigazione, l'illustrazione. Poi le
sezioni, ciascuna con un'idea sola. Frasi brevi. Tabelle senza intestazione quando le colonne
si spiegano da sole. Nessuna emoji.

## Che cosa non si fa

- Aggiungere un colore.
- Usare l'ambra per qualcosa che non cambia.
- Mettere testo dentro un'immagine quando può stare nella pagina.
- Aggiungere un badge per un numero.
- Usare un'immagine con lo sfondo.

## Alternativa fotografica

I progetti [GPForum](https://github.com/gpicchiarelli/GPForum) e
[AutomaGP](https://github.com/gpicchiarelli/AutomaGP) aprono il README con un render
fotorealistico di una stanza. Per ArcDocDB l'illustrazione è vettoriale, per i principi 2 e 3.
Se si volesse comunque un'immagine di quella serie, va generata con un generatore di immagini
(quella di AutomaGP è stata prodotta con l'agente di Cursor) a partire da questa descrizione.

<details>
<summary>Descrizione per il generatore</summary>

```
Photorealistic cinematic interior photograph, 16:9, moody low-key lighting, warm golden light.
A quiet study in a country villa. On the left, dark vertical slatted wood panelling with a
server rack half hidden in shadow behind it, small green status LEDs glowing softly.

The central wall is textured warm grey plaster. Mounted on it, a large backlit brass wall
relief: a wide semicircular brass arch, and beneath it a tidy stack of long horizontal brass
bars, like storage segments laid one above the other. All the bars are matte and softly
rim-lit from behind; one single bar, the top one, glows with warm amber light.

Below it, a long low sideboard in dark walnut with a brass desk lamp, two closed
leather-bound ledgers and a small potted plant. On the right, a tall black-framed window
onto lush green trees. Foreground: a dark walnut desk with an open laptop showing green
monospaced code, a ceramic cup, a notebook with a fountain pen.

Calm, serious, durable mood. Deep brown and olive shadows, warm amber highlights, shallow
depth of field, subtle film grain. No people, no readable text, no logos, no watermark.
```

</details>

## Il repository come prodotto

Il README presenta scopo, funzionamento e maturità. L'indice della documentazione orienta
per domanda; gli indici di sezione offrono collegamenti ai percorsi vicini. La guida ai
contributi descrive il lavoro possibile oggi e i controlli effettivamente disponibili.

- Conservare marchio, palette, geometrie e varianti chiara e scura.
- Usare titoli descrittivi e intestazioni esplicite nelle tabelle di confronto.
- Distinguere una garanzia progettata da un risultato verificato; lo stato deve essere leggibile.
- Collegare i documenti con etichette comprensibili, senza ripetere il marchio in ogni pagina.
- Tenere i dettagli tecnici nei documenti dedicati; il README deve fornire accesso a quei dettagli.
