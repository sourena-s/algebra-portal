// Builds data/borders.bin from Natural Earth 1:50m countries (world-atlas@2.0.2, world-countries@5.1.0 for the alpha-2 codes,
// topojson-client@3.1.0, all from npm, unpacked beside this script): node build-borders.js 50m ../data/borders.bin
const fs = require('fs'), zlib = require('zlib'), tc = require('./topojson-client-3.1.0/package/dist/topojson-client.js');
const res = process.argv[2] || '50m';
const topo = JSON.parse(fs.readFileSync(`world-atlas-2.0.2/package/countries-${res}.json`));
const wc = JSON.parse(fs.readFileSync('world-countries-5.1.0/package/countries.json'));
const byN = {}; for (const c of wc) if (c.ccn3) byN[c.ccn3] = c.cca2;
const fc = tc.feature(topo, topo.objects.countries); const out = {}; let pts = 0, miss = [];
for (const f of fc.features){
  const cc = byN[f.id] || (f.properties.name === 'Kosovo' ? 'XK' : null); if (!cc){ miss.push(f.id + ' ' + f.properties.name); continue; }
  const polys = f.geometry ? (f.geometry.type === 'Polygon' ? [f.geometry.coordinates] : f.geometry.coordinates) : [];
  const rings = out[cc] || (out[cc] = []);
  for (const p of polys) for (const r of p){ const a = []; let lx = 1e9, ly = 1e9;
    for (const [x, y] of r){ const X = Math.round(x*100), Y = Math.round(y*100); if (X === lx && Y === ly) continue; a.push(lx === 1e9 ? X : X - lx, ly === 1e9 ? Y : Y - ly); lx = X; ly = Y; }
    if (a.length >= 6){ rings.push(a); pts += a.length/2; } }
}
const js = JSON.stringify(out), gz = zlib.gzipSync(js, { level: 9 });
console.log(res, Object.keys(out).length, 'countries', pts, 'pts', js.length, 'json', gz.length, 'gz'); console.log('missing', miss.join('; '));
if (process.argv[3]) fs.writeFileSync(process.argv[3], gz);
