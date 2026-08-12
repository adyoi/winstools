<#
.SYNOPSIS
    Build winstools: compile (ps2exe) + patch version resource + sign (Authenticode) + verify.
    Output per versi: Build\<shortVersion>\winstools.exe
    Folder hasil dibuat self-contained (Modules, Tools, Icons + skrip build ikut disalin).

.PARAMETER PfxPath
    Path PFX sertifikat code signing. Kosongkan untuk memakai default CA\winstools.pfx di root project.

.PARAMETER PfxPassword
    Password PFX.

.PARAMETER SignThumbprint
    Alternatif: pakai sertifikat dari Cert:\CurrentUser\My berdasarkan thumbprint.

.PARAMETER Version
    Versi build (default 1.2.0.0). Bisa "1.3" / "1.3.0.0"; otomatis dilengkapi jadi 4 bagian.
    Nama folder output = major.minor (Build\1.3).
#>

[CmdletBinding()]
param(
    [string]$PfxPath        = "",
    [string]$PfxPassword    = "WINSTOOLS-CA-2026",
    [string]$SignThumbprint = "",
    [string]$Version        = "1.2.0.0"
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location -LiteralPath $root

# Lokasi project: Build\ -> winstools
$buildRoot = $root                  # Build\ : folder semua hasil per versi
$projRoot  = Split-Path $root -Parent   # winstools\ : root project

# ---------------------------------------------------------------------------
# Metadata aplikasi (muncul di Properties -> Details)
# ---------------------------------------------------------------------------
$metaTitle       = "Windows Super Tools"   # File Description
$metaDescription = "Windows Super Tools"   # Comments
$metaProduct     = "Winstools"             # Product Name
$metaCompany     = "PT (Perorangan) Adidaya Karya Utama"              # Company Name
$metaCopyright   = "Copyright © 2026 PT (Perorangan) Adidaya Karya Utama. All rights reserved."  # LegalCopyright
$metaVersion     = $Version            # File Version & Product Version (dari parameter)

# Normalisasi versi ke 4 bagian (contoh: "1.3" -> "1.3.0.0")
$parts = @($metaVersion -split '\.')
while ($parts.Count -lt 4) { $parts += '0' }
$metaVersion = $parts -join '.'

# Versi pendek (major.minor) -> nama folder build: Build\1.0
$shortVersion = ($metaVersion -split '\.')[0..1] -join '.'

# ---------------------------------------------------------------------------
# Path input/output
# ---------------------------------------------------------------------------
$inputScript = Join-Path $projRoot "Scripts\Main.ps1"
$iconFile    = Join-Path $projRoot "Icons\window.ico"
$timestamp   = "http://timestamp.digicert.com"

$outDir    = Join-Path $buildRoot $shortVersion
$outputExe = Join-Path $outDir "winstools.exe"

# Setiap build membuat folder sesuai versi
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
Write-Host "[build] Versi: $metaVersion ($shortVersion)"
Write-Host "[build] Output: $outputExe"

if (-not $PfxPath) { $PfxPath = Join-Path $projRoot "CA\winstools.pfx" }

# ---------------------------------------------------------------------------
# 1) Compile (ps2exe)
# ---------------------------------------------------------------------------
Import-Module ps2exe -Force -ErrorAction Stop
Write-Host "[build] Compiling $inputScript -> $outputExe"
Invoke-PS2EXE -InputFile $inputScript -OutputFile $outputExe -IconFile $iconFile -noConsole `
    -title $metaTitle -description $metaDescription -product $metaProduct -company $metaCompany `
    -copyright $metaCopyright -version $metaVersion

# ---------------------------------------------------------------------------
# 2) Patch resource versi (bahasa Indonesia 0x0421, dsb.) -- SEBELUM signing
# ---------------------------------------------------------------------------
$verResScript = Join-Path $root 'set-versioninfo.ps1'
if (Test-Path $verResScript) {
    & $verResScript -FilePath $outputExe -FileDescription $metaTitle -FileVersion $metaVersion `
        -ProductName $metaProduct -ProductVersion $metaVersion -CompanyName $metaCompany `
        -LegalCopyright $metaCopyright -Comments $metaDescription -Language 0x0421
} else {
    Write-Warning "[build] set-versioninfo.ps1 tidak ditemukan - resource versi dilewati."
}

# ---------------------------------------------------------------------------
# 3) Resolve certificate: PFX dulu, thumbprint sebagai fallback
# ---------------------------------------------------------------------------
$cert = $null
if ($PfxPath -and (Test-Path $PfxPath)) {
    if (-not $PfxPassword) { throw "PfxPassword wajib diisi saat memakai PFX." }
    $pwd  = ConvertTo-SecureString -String $PfxPassword -AsPlainText -Force
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2((Resolve-Path $PfxPath), $pwd)
} elseif ($SignThumbprint) {
    $cert = Get-ChildItem Cert:\CurrentUser\My -ErrorAction SilentlyContinue | Where-Object { $_.Thumbprint -eq $SignThumbprint } | Select-Object -First 1
    if (-not $cert) { throw "Thumbprint tidak ditemukan di Cert:\CurrentUser\My : $SignThumbprint" }
} else {
    Write-Warning "[build] Tidak ada sertifikat dikonfigurasi - tanda tangan dilewati."
}

# ---------------------------------------------------------------------------
# 4) Sign
# ---------------------------------------------------------------------------
if ($cert) {
    Write-Host "[build] Signing dengan $($cert.Subject)"
    $sig = Set-AuthenticodeSignature -FilePath $outputExe -Certificate $cert -HashAlgorithm SHA256 -TimestampServer $timestamp
    if ($sig.Status -in @('Valid', 'UnknownError')) {
        Write-Host "[build] Ditandatangani OK (status: $($sig.Status))"
    } else {
        Write-Host "[build] Status tanda tangan: $($sig.Status) - $($sig.StatusMessage)"
    }
}

# ---------------------------------------------------------------------------
# 5) Salin runtime agar folder Build\<versi> self-contained
#    (exe memuat Modules/Tools/Icons relatif terhadap lokasinya sendiri)
# ---------------------------------------------------------------------------
$srcModules = Join-Path $projRoot "Scripts\Modules"
$srcTools   = Join-Path $projRoot "Scripts\Tools"
$dstIcons   = Join-Path $outDir "Icons"

Copy-Item -Path $srcModules -Destination $outDir -Recurse -Force
Copy-Item -Path $srcTools   -Destination $outDir -Recurse -Force
New-Item -ItemType Directory -Path $dstIcons -Force | Out-Null
Copy-Item -Path (Join-Path $projRoot "Icons\window.ico") -Destination $dstIcons -Force
Copy-Item -Path (Join-Path $projRoot "Icons\window.png") -Destination $dstIcons -Force
Write-Host "[build] Runtime disalin ke $outDir (Modules, Tools, Icons)"

# ---------------------------------------------------------------------------
# 6) Verify
# ---------------------------------------------------------------------------
$sig = Get-AuthenticodeSignature $outputExe
Write-Host ""
Write-Host "[verify] File     : $outputExe"
Write-Host "[verify] Signed   : $($sig.Status -ne 'NotSigned')"
Write-Host "[verify] Status   : $($sig.Status)"
if ($sig.SignerCertificate) { Write-Host "[verify] Signer   : $($sig.SignerCertificate.Subject)" }
if ($sig.TimeStamperCertificate) { Write-Host "[verify] Timestamp: $($sig.TimeStamperCertificate.Subject)" }
Write-Host ""
if ($sig.Status -ne 'Valid') {
    Write-Host "[build] Selesai. Catatan: status != Valid biasanya karena root sertifikat belum di-trust (self-signed)."
    Write-Host "[build] Jalankan setup-ca.ps1 lalu install rootCA.cer ke 'Trusted Root Certification Authorities'."
} else {
    Write-Host "[build] Selesai - tanda tangan Valid."
}
