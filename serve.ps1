# Minimal static server for local preview (no Node or Python needed): powershell -File serve.ps1
param([int]$Port = 8080)
$root = $PSScriptRoot
$l = [Net.HttpListener]::new(); $l.Prefixes.Add("http://localhost:$Port/"); $l.Start()
Write-Host "Serving $root at http://localhost:$Port/"
$types = @{ '.html'='text/html; charset=utf-8'; '.js'='text/javascript'; '.css'='text/css'; '.json'='application/json'; '.png'='image/png'; '.jpg'='image/jpeg'; '.svg'='image/svg+xml'; '.ico'='image/x-icon'; '.bin'='application/octet-stream' }
while ($l.IsListening) {
  $c = $l.GetContext(); $p = [Uri]::UnescapeDataString($c.Request.Url.AbsolutePath.TrimStart('/')); if (!$p) { $p = 'index.html' }
  $f = Join-Path $root $p
  if ((Test-Path $f -PathType Leaf) -and ([IO.Path]::GetFullPath($f)).StartsWith($root)) {
    $b = [IO.File]::ReadAllBytes($f); $t = $types[[IO.Path]::GetExtension($f)]; if ($t) { $c.Response.ContentType = $t }
    $c.Response.Headers.Add('Cache-Control', 'no-store'); $c.Response.OutputStream.Write($b, 0, $b.Length)
  } else { $c.Response.StatusCode = 404 }
  $c.Response.Close()
}
