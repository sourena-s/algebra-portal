# ALGEBRA

**ALGEBRA: Alzheimer's disease and genomic breakdown in ageing.** A single-page interactive 3D website (Three.js / WebGL). It zooms from the Laniakea supercluster and the Milky Way down to Earth, then into the human brain and its seven resting-state networks, the amygdalae and their nuclei, a single neuron's nucleus and DNA, PacBio SMRT Cell sequencing, a 3D Manhattan plot of Alzheimer's disease GWAS, an all-atom DNA double helix with ageing-related lesions, and DNA repair genes.

## Layout

Everything lives in one self-contained file, `index.html` (~7 MB, ~5,700 lines). There is no build step.

- `<style>` at the top holds the design tokens on `:root`. The palette includes `--void`, `--bone`, network colours `--net1..7`, base colours `--base-a/c/g/t`, and element colours `--el-*`. The site is dark-only.
- **Line ~776**: `window.NOOS_DATA`, a ~3.5 MB line of gzipped + base64 data (GWAS and more). It is decoded in the browser with pako.
- **Line ~778**: the import map, which pins `three@0.170.0` from jsDelivr.
- **Line ~784 onward**: the main `<script type="module">` with all scene code.
- **Very long lines** hold embedded base64 JPEG textures (Earth day map ~L1104, planets `PL_TEX` ~L4538, `MOON_TEX` ~L4559) and voxel data (`AMY_VOX` ~L4926).

## Working on it

- **Never read the file whole, and never print the long data lines.** A single line can be MBs. Use `grep -n` to find code, and read with `offset`/`limit`. Pipe output through `cut -c1-200` when a match could land on a data line.
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
