$ErrorActionPreference = 'Stop'
$serverRoot = Split-Path -Parent $PSScriptRoot
$cefVersion = '1.4.0'
$cefCache = Join-Path $serverRoot '.deps-download/cef-1.4.0'
$cefArchive = Join-Path $cefCache 'server.zip'
$cefExpectedHash = '42a165a5ceae06329215afbda2a83a148bb26a61ddaa1d5a3d07bed6744e7da5'
New-Item -ItemType Directory -Force -Path $cefCache | Out-Null
if (-not (Test-Path -LiteralPath $cefArchive)) {
    Invoke-WebRequest -Uri "https://github.com/aurora-mp/omp-cef/releases/download/v$cefVersion/cef-omp-v$cefVersion-x86.zip" -OutFile $cefArchive
}
if ((Get-FileHash -LiteralPath $cefArchive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $cefExpectedHash) {
    throw 'CEF archive SHA-256 does not match the official v1.4.0 release. Installation stopped.'
}
$cefExtract = Join-Path $cefCache 'server'
Expand-Archive -LiteralPath $cefArchive -DestinationPath $cefExtract -Force
Copy-Item -LiteralPath (Join-Path $cefExtract 'components/Cef.dll') -Destination (Join-Path $serverRoot 'components/Cef.dll') -Force
Copy-Item -LiteralPath (Join-Path $cefExtract 'cef.inc') -Destination (Join-Path $serverRoot 'qawno/include/cef.inc') -Force
Write-Host 'Installed omp-cef v1.4.0 Windows x86. Restart the server and allow UDP game-port + 2 (7779).'
