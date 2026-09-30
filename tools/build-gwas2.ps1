# Builds data/gwas2.bin (Uffelmann et al. 2026) from the summary statistics file named in $src below.
# Run: powershell -NoProfile -ExecutionPolicy Bypass -File tools/build-gwas2.ps1
$ErrorActionPreference = 'Stop'
$src = 'C:\Users\soure\Desktop\twent_combined_all_neff0.6_nsumstats1_filt.txt.gz'
$out = 'C:\Users\soure\ALGEBRA\data\gwas2.bin'
$inv = [Globalization.CultureInfo]::InvariantCulture

# read (p as text: the top hits underflow a double, so -log10 p is taken from mantissa and exponent)
$fs = [IO.File]::OpenRead($src); $gz = New-Object IO.Compression.GZipStream($fs, [IO.Compression.CompressionMode]::Decompress); $sr = New-Object IO.StreamReader($gz)
$null = $sr.ReadLine()
$V = New-Object System.Collections.Generic.List[object]
$nMax = 0
while (($line = $sr.ReadLine()) -ne $null) {
  $x = $line.Split("`t")
  $ps = $x[8].ToLowerInvariant(); $ei = $ps.IndexOf('e')
  if ($ei -ge 0) { $m = [double]::Parse($ps.Substring(0, $ei), $inv); $e = [int]$ps.Substring($ei + 1) } else { $m = [double]::Parse($ps, $inv); $e = 0 }
  if ($m -le 0) { continue }
  $L = -([Math]::Log10($m) + $e)
  $rs = if ($x[15] -like 'rs*') { $x[15] } else { $x[0] }
  $n = [int]$x[13] + [int]$x[14]; if ($n -gt $nMax) { $nMax = $n }
  $V.Add([pscustomobject]@{ c = [int]$x[1]; p = [int]$x[2]; a2 = $x[3]; a1 = $x[4]; f = [double]::Parse($x[5], $inv); b = [double]::Parse($x[6], $inv); se = [double]::Parse($x[7], $inv); L = $L; rs = $rs; k = -1; keep = $false })
}
$sr.Close()
"read $($V.Count) variants, max n $nMax"

# loci: clump genome-wide significant variants within 1 Mb of a stronger lead
$SIG = -[Math]::Log10(5e-8)
$loci = New-Object System.Collections.Generic.List[object]
foreach ($w in ($V | Sort-Object -Property L -Descending)) {
  $hit = -1
  for ($j = 0; $j -lt $loci.Count; $j++) { $lc = $loci[$j]; if ($lc.c -eq $w.c -and [Math]::Abs($lc.p - $w.p) -le 1e6) { $hit = $j; break } }
  if ($hit -lt 0 -and $w.L -ge $SIG) { $hit = $loci.Count; $loci.Add([pscustomobject]@{ c = $w.c; p = $w.p; rs = $w.rs; L = $w.L; n = 0 }) }
  $w.k = $hit
}
"loci: $($loci.Count)"

# thinning to about the size of the EADB set: each locus keeps its 40 strongest; the rest are sampled evenly
$rank = @{}
foreach ($w in ($V | Sort-Object -Property L -Descending)) { if ($w.k -ge 0) { $r = [int]$rank[$w.k]; if ($r -lt 40) { $w.keep = $true }; $rank[$w.k] = $r + 1 } }
$sigV = @($V | Where-Object { $_.L -ge $SIG -and -not $_.keep }); $subV = @($V | Where-Object { $_.L -lt $SIG -and -not $_.keep })
$kept0 = @($V | Where-Object { $_.keep }).Count
$wantSig = [Math]::Max(0, 8600 - $kept0); $wantSub = 6900
$i = 0; foreach ($w in $sigV) { if ([Math]::Floor(($i + 1) * $wantSig / $sigV.Count) -gt [Math]::Floor($i * $wantSig / $sigV.Count)) { $w.keep = $true }; $i++ }
$i = 0; foreach ($w in $subV) { if ([Math]::Floor(($i + 1) * $wantSub / $subV.Count) -gt [Math]::Floor($i * $wantSub / $subV.Count)) { $w.keep = $true }; $i++ }
$K = @($V | Where-Object { $_.keep } | Sort-Object -Property c, p)
"kept $($K.Count): sig $(@($K | Where-Object { $_.L -ge $SIG }).Count)"

# loci in genome order, and each kept variant's locus index
$ord = @(0..($loci.Count - 1) | Sort-Object -Property { $loci[$_].c }, { $loci[$_].p })
$remap = @{}; for ($r = 0; $r -lt $ord.Count; $r++) { $remap[$ord[$r]] = $r }

$sb = New-Object Text.StringBuilder
$f = { param($d, $fmt) $d.ToString($fmt, $inv) }
$arr = { param($name, $sel) [void]$sb.Append(",`"$name`":[" + (($K | ForEach-Object $sel) -join ',') + ']') }
[void]$sb.Append('{"study":"Uffelmann et al., 2026","build":"GRCh37","n":' + $nMax)
& $arr 'rs' { '"' + $_.rs + '"' }
& $arr 'c' { $_.c }
& $arr 'p' { $_.p }
& $arr 'L' { $_.L.ToString('0.###', $inv) }
& $arr 'b' { $_.b.ToString('0.#####', $inv) }
& $arr 'se' { $_.se.ToString('0.#####', $inv) }
& $arr 'a1' { '"' + $_.a1 + '"' }
& $arr 'a2' { '"' + $_.a2 + '"' }
& $arr 'f' { $_.f.ToString('0.####', $inv) }
& $arr 'k' { if ($_.k -ge 0) { $remap[$_.k] } else { -1 } }
$ls = foreach ($j in $ord) { $l = $loci[$j]; '{"c":' + $l.c + ',"p":' + $l.p + ',"rs":"' + $l.rs + '","L":' + $l.L.ToString('0.###', $inv) + ',"t2":0,"name":""}' }
[void]$sb.Append(',"loci":[' + ($ls -join ',') + ']}')

$bytes = [Text.Encoding]::UTF8.GetBytes($sb.ToString())
$ofs = [IO.File]::Create($out); $ogz = New-Object IO.Compression.GZipStream($ofs, [IO.Compression.CompressionLevel]::Optimal); $ogz.Write($bytes, 0, $bytes.Length); $ogz.Close()
"wrote $out ($((Get-Item $out).Length) bytes, json $($bytes.Length))"
