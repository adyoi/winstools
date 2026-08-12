<#
.SYNOPSIS
    Buat private CA (OpenSSL) + sertifikat code signing (dengan email) untuk winstools, lalu export PFX.
    Root dibuat sekali; sertifikat code signing dibuat ulang setiap dijalankan.
    Output di folder CA di samping skrip ini.
#>

[CmdletBinding()]
param(
    [string]$CaDir       = "..\CA",
    [string]$Org         = "WINSTOOLS",
    [string]$RootCN      = "WINSTOOLS Root CA",
    [string]$SignCN      = "WINSTOOLS CodeSigning",
    [string]$SignEmail   = "adyoix@gmail.com",
    [int]$RootDays       = 3650,
    [int]$SignDays       = 1095,
    [string]$PfxPassword = "WINSTOOLS-CA-2026"
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$caPath = Join-Path $scriptDir $CaDir
New-Item -ItemType Directory -Path $caPath -Force | Out-Null

$openssl = (Get-Command openssl.exe).Source
if (-not $openssl) { throw "OpenSSL tidak ditemukan. Install dari https://slproweb.com/products/Win32OpenSSL.html" }

Push-Location $caPath
try {
    # 1) Root CA - buat hanya jika belum ada
    if (-not (Test-Path .\rootCA.crt)) {
        Write-Host "[ca] Membuat Root CA ($RootCN, $RootDays hari)..."
        & $openssl req -x509 -newkey rsa:4096 -sha256 -days $RootDays -nodes `
            -keyout rootCA.key -out rootCA.crt `
            -subj "/CN=$RootCN/O=$Org" `
            -addext "basicConstraints=critical,CA:TRUE" `
            -addext "keyUsage=critical,keyCertSign,cRLSign" `
            -addext "subjectKeyIdentifier=hash"
        if ($LASTEXITCODE -ne 0) { throw "Gagal membuat Root CA" }
        & $openssl x509 -in rootCA.crt -outform DER -out rootCA.cer
    } else {
        Write-Host "[ca] Root CA sudah ada - dipakai ulang."
    }

    # 2) Kunci + CSR code signing (dengan email di subject)
    Write-Host "[ca] Membuat kunci & CSR code signing (E=$SignEmail)..."
    & $openssl req -new -newkey rsa:3072 -sha256 -nodes `
        -keyout winstools.key -out winstools.csr `
        -subj "/CN=$SignCN/O=$Org/emailAddress=$SignEmail"
    if ($LASTEXITCODE -ne 0) { throw "Gagal membuat CSR" }

    # 3) Tandatangani sertifikat code signing
    Write-Host "[ca] Menandatangani sertifikat code signing ($SignDays hari)..."
    $ext = @"
[ext]
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=codeSigning
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
"@
    Set-Content -LiteralPath .\ext.cnf -Value $ext -Encoding ASCII
    & $openssl x509 -req -in winstools.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial `
        -out winstools.crt -days $SignDays -sha256 -extfile ext.cnf -extensions "ext"
    if ($LASTEXITCODE -ne 0) { throw "Gagal menandatangani sertifikat" }

    # 4) Export PFX (cert + key + root, key exportable)
    Write-Host "[ca] Export PFX..."
    & $openssl pkcs12 -export -out winstools.pfx `
        -inkey winstools.key -in winstools.crt -certfile rootCA.crt `
        -passout "pass:$PfxPassword" -name "WINSTOOLS CodeSigning"
    if ($LASTEXITCODE -ne 0) { throw "Gagal export PFX" }

    Write-Host ""
    Write-Host "[ca] SELESAI - file di $caPath"
    Write-Host "      rootCA.cer      : install di Trusted Root mesin target"
    Write-Host "      rootCA.crt/key  : simpan aman (private key root)"
    Write-Host "      winstools.pfx   : pakai untuk sign (password: $PfxPassword)"
    Write-Host "      Signer          : $SignCN <$SignEmail>"
} finally {
    Pop-Location
}
