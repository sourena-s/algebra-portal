# ALGEBRA

**ALGEBRA: Alzheimer's disease and genomic breakdown in ageing.** A single-page interactive 3D website (Three.js / WebGL). It zooms from the Laniakea supercluster and the Milky Way down to Earth, then into the human brain and its seven resting-state networks, the amygdalae and their nuclei, a single neuron's nucleus and DNA, PacBio SMRT Cell sequencing, a 3D Manhattan plot of Alzheimer's disease GWAS, an all-atom DNA double helix with ageing-related lesions, and DNA repair genes.

## Layout

The page and its code are in `index.html` (~580 KB). Large assets live beside it. There is no build step.

- `assets/*.jpg`: Earth day, night and clouds, the planets (Mercury to Neptune, no Earth) and the Moon; `assets/saturn-rings.png`; `assets/moons/*.jpg`, the moons' maps (credits in `assets/moons/CREDITS.md`).
- `data/*.bin`: gzipped datasets `brain`, `dna`, `genes`, `gwas` (fetched in parallel at start via `BIN`) and `tle`, the satellite snapshot (fetched only if the live feeds fail). Load them with `loadBin(name)` or `loadJSON(name)`, which also accept files a host has already decompressed.

- `<style>` at the top holds the design tokens on `:root`. The palette includes `--void`, `--bone`, network colours `--net1..7`, base colours `--base-a/c/g/t`, and element colours `--el-*`. The site is dark-only.
- `window.NOOS_DATA` (one long line near the import map) keeps only the small inline data: the `net` and `land` datasets, their metadata, and the time-zone table.
- The import map, which pins `three@0.170.0` from jsDelivr.
- After it comes the main `<script type="module">` with all scene code.
- Long lines still hold `NOOS_DATA` and the amygdala voxel data `AMY_VOX` (~22 KB).

## Working on it

- **Never read the file whole, and never print the long data lines.** Some lines are tens of KB. Use `grep -n` to find code, and read with `offset`/`limit`. Pipe output through `cut -c1-200` when a match could land on a data line.
- Edit with small, exact replacements. Leave the base64/gzip blobs untouched unless you are replacing an asset on purpose.
- **External dependencies:**
  - three.js 0.170.0 and satellite.js 5.0.0 (jsDelivr)
  - pako 2.1.0 (cdnjs)
  - Exo 2 (Google Fonts)
  - Live satellite TLEs from CelesTrak, with a GitHub mirror as fallback
  - IP geolocation (geojs / ipapi / ipwho.is) as a best-effort lookup
- Font: Univia Pro (licensed, Adobe Fonts) when installed, otherwise Exo 2 as fallback.

## Running

Serve the folder over HTTP rather than opening the file directly, because ES modules and fetches need it:

    powershell -NoProfile -ExecutionPolicy Bypass -File serve.ps1

Then open http://localhost:8080. `serve.ps1` is a dependency-free static server, because Node and Python are not installed here.

## Conventions

- The splash says only "Loading…"; `ld()` is a no-op.
- IP geolocation runs only after consent from the privacy notice (`#consent`, localStorage key `algebra-geo`); without it, `locate()` falls back to the time zone.
- Developer credit: Sourena Soheili-Nezhad (`<meta name="author">` and `.credit` under the tagline).
