# ALGEBRA

**ALGEBRA: Alzheimer's disease and genomic breakdown in ageing.** A single-page interactive 3D website (Three.js / WebGL). It zooms from the Laniakea supercluster and the Milky Way down to Earth, which shrinks into the nucleus of a single neuron (with its oligodendrocytes); out to the human brain and its seven resting-state networks; the amygdalae, whose nuclei are sorted by laser; the sorted neurons' nuclei gathering into one nucleus and its DNA; PacBio SMRT Cell sequencing, a 3D Manhattan plot of Alzheimer's disease GWAS, an all-atom DNA double helix with ageing-related lesions, and DNA repair genes.

## Layout

The page and its code are in `index.html` (~580 KB). Large assets live beside it. There is no build step.

- `assets/earth/{day,night,clouds}-{px,nx,py,ny,pz,nz}.jpg`: the Earth's cube maps (NASA Blue Marble, Black Marble and clouds, reprojected from equirectangular so the globe has no seam), sampled by direction in `EARTH_PHOTO`.
- `assets/*.jpg`: the planets (Mercury to Neptune, no Earth) and the Moon; `assets/saturn-rings.png`; `assets/moons/*.jpg`, the moons' maps (credits in `assets/moons/CREDITS.md`).
- `data/*.bin`: gzipped datasets `brain`, `dna`, `genes`, `gwas` (EADB et al. 2026), `gwas2` (Uffelmann et al. 2026, GRCh37, built by `tools/build-gwas2.ps1`) (fetched in parallel at start via `BIN`) and `tle`, an old satellite snapshot, no longer used. Load them with `loadBin(name)` or `loadJSON(name)`, which also accept files a host has already decompressed.
- `i18n/{nl,fa}.json`: the Dutch and Persian dictionaries. Each maps English text, with whitespace collapsed, to its translation. Text with inline markup is keyed by its HTML. English is the source and has no file.

- `<style>` at the top holds the design tokens on `:root`. The palette includes `--void`, `--bone`, network colours `--net1..7`, base colours `--base-a/c/g/t`, and element colours `--el-*`. The site is dark-only.
- `window.NOOS_DATA` (one long line near the import map) keeps only the small inline data: the `net` and `land` datasets, their metadata, and the time-zone table.
- The import map, which pins `three@0.170.0` from jsDelivr.
- After it comes the main `<script type="module">` with all scene code.
- Long lines still hold `NOOS_DATA` and the amygdala voxel data `AMY_VOX` (~22 KB).

## Working on it

- **Never read the file whole, and never print the long data lines.** Some lines are tens of KB. Use `grep -n` to find code, and read with `offset`/`limit`. Pipe output through `cut -c1-200` when a match could land on a data line.
- Edit with small, exact replacements. Leave the base64/gzip blobs untouched unless you are replacing an asset on purpose.
- **External dependencies:**
  - three.js 0.170.0 (jsDelivr)
  - pako 2.1.0 (cdnjs)
  - Exo 2 (Google Fonts)
  - IP geolocation (geojs / ipapi / ipwho.is) as a best-effort lookup
- Font: Univia Pro (licensed, Adobe Fonts) when installed, otherwise Exo 2 as fallback.

## Running

Serve the folder over HTTP rather than opening the file directly, because ES modules and fetches need it:

    powershell -NoProfile -ExecutionPolicy Bypass -File serve.ps1

Then open http://localhost:8080. `serve.ps1` is a dependency-free static server, because Node and Python are not installed here.

## Conventions

- Languages: English, Nederlands and پارسی, picked on the opening chapter (`#langs`). The choice is stored in localStorage under `algebra-lang` (a `?lang=` query string overrides it) and the page reloads. `LANG` and `I18` load before anything else. `translateDom()` translates the page, and a MutationObserver translates text the scene writes later. In code, wrap strings with `t_('…')`; for strings that contain values, use `tf('Reading {0}', name)`. Every new piece of user-facing English needs entries in both JSON files. Gene names, papers, p-values, numbers and units stay in English. Persian sets `body.rtl`: Vazirmatn font, no letter-spacing, right-to-left text blocks, and `splitChars` splits titles by word.
- The splash says only "Loading…"; `ld()` is a no-op.
- IP geolocation runs only after consent from the privacy notice (`#consent`, localStorage key `algebra-geo`); without it, `locate()` falls back to the time zone.
- Developer credit: Sourena Soheili-Nezhad, in `<meta name="author">` only (not in the chapter titles).
- The Manhattan chapter holds two studies: `GA` (EADB) and `GB` (Uffelmann, `mir = 1`). `G` is the one on show. The flat ring shows only `G`; the button filling its inner circle (`#gSwap`, `switchStudy`) spins it 20 turns in 3 s and swaps the studies mid-turn. The standing ring and the line show both, `GB` mirrored below. Particles `[0, NS)` carry `G` and `[NS, 2NS)` the other study (`NP >= 2*NS`); `showStudy` trades the two sets. Both studies share the GRCh38 genome axis so their positions match.
- Middle- or right-drag pans the scene; left-drag turns it; the wheel zooms.
- Chapters (`ST`, in story order): Universe -1, Earth 0, Neuron 1, Brain 2, Amygdala 3, Sorting 4, Nucleus 5, One well 6, SMRT Cell 7, Genome 8, DNA 9, Repair 10. Each transition has its own progress variable, and the particle shader runs them as one chain in the same order: `mCell` Earth → neuron (the Earth photograph shrinks into its nucleus), `m1`/`uMorph` neuron → brain, `mAmy`, `mSort`, `mNucl` sorter → nucleus (the neurons' tube pours out into it), then `mZm`, `mSm`, `mGw`, `mDna`, `mNet`.
