<#
.SYNOPSIS
    Build installer winstools dengan Inno Setup (ISCC.exe).
    Menghasilkan Build\<shortVersion>\winstools-installer.exe.

.PARAMETER Version
    Versi aplikasi. Default ambil dari file VERSION di root project (fallback 1.0.0).
#>

[CmdletBinding()]
param(
    [string]$Version = ""
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location -LiteralPath $root

$projRoot = Split-Path $root -Parent

if (-not $Version) {
    $versionFile = Join-Path $projRoot "VERSION"
    if (Test-Path $versionFile) {
        $Version = (Get-Content $versionFile -Raw).Trim()
    } else {
        $Version = "1.0.0"
    }
}

$shortVersion = ($Version -split '\.')[0..1] -join '.'

$exe = Join-Path $root "$shortVersion\winstools.exe"
if (-not (Test-Path $exe)) {
    throw "winstools.exe belum dibuild: $exe. Jalankan build-exe.ps1 dulu."
}

$iscc = Get-Command ISCC.exe -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $iscc) {
    $candidates = @(
        'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
        'C:\Program Files\Inno Setup 6\ISCC.exe'
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $iscc = Get-Item $c; break }
    }
}
if (-not $iscc) {
    throw "ISCC.exe tidak ditemukan. Install Inno Setup 6 (choco install innosetup -y)."
}

Write-Host "[installer] Versi: $Version (folder Build\$shortVersion)"
Write-Host "[installer] ISCC : $($iscc.Source)"

& $iscc.Source (Join-Path $root 'config-installer.iss') "/DAppVersion=$Version" "/DAppShortVersion=$shortVersion"
if ($LASTEXITCODE -ne 0) { throw "ISCC gagal (exit code $LASTEXITCODE)." }

$out = Join-Path $root "$shortVersion\winstools-installer.exe"
if (Test-Path $out) {
    Write-Host "[installer] Selesai: $out"
} else {
    throw "Installer tidak dihasilkan."
}
