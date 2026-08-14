<#
.SYNOPSIS
    Menulis ulang resource versi (VERSIONINFO) pada exe dengan bahasa tertentu (default Indonesia 0x0421).
    Dipanggil build.ps1 SETELAH compile dan SEBELUM signing.
#>

[CmdletBinding()]
param(
    [string]$FilePath        = ".\winstools.exe",
    [string]$FileDescription = "Windows Super Tools",
    [string]$FileVersion     = "1.0.0.0",
    [string]$ProductName     = "Winstools",
    [string]$ProductVersion  = "1.0.0.0",
    [string]$CompanyName     = "PT (Perorangan) Adidaya Karya Utama",
    [string]$LegalCopyright  = "MIT",
    [string]$Comments        = "Windows Super Tools",
    [int]$Language           = 0x0421
)

$ErrorActionPreference = 'Stop'
$exe = (Resolve-Path $FilePath).Path
if (-not (Test-Path $exe)) { throw "File tidak ditemukan: $exe" }

# --- Win32 P/Invoke ---
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class VerRes {
    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern IntPtr BeginUpdateResource(string pFileName, bool bDeleteExistingResources);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool UpdateResource(IntPtr hUpdate, IntPtr lpType, IntPtr lpName, ushort wLanguage, byte[] lpData, uint cbData);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool EndUpdateResource(IntPtr hUpdate, bool fDiscard);
}
'@ -ErrorAction Stop

function Add-U16 { param($List, [uint16]$v) $List.AddRange([System.BitConverter]::GetBytes($v)) }
function Add-U32 { param($List, [uint32]$v) $List.AddRange([System.BitConverter]::GetBytes($v)) }

# Blok string: "Key" -> "Value" (VS_STRING)
function New-StringBlock {
    param([string]$Key, [string]$Value)
    $list = New-Object 'System.Collections.Generic.List[byte]'
    $keyB = [System.Text.Encoding]::Unicode.GetBytes($Key + [char]0)
    $valB = [System.Text.Encoding]::Unicode.GetBytes($Value + [char]0)   # nilai selalu di-terminate null
    $list.AddRange([byte[]](0, 0))                 # wLength (diisi di akhir)
    Add-U16 $list ([uint16]$valB.Length)           # wValueLength (bytes, termasuk null)
    $list.AddRange([byte[]](1, 0))                 # wType = text
    $list.AddRange($keyB)
    while (($list.Count % 4) -ne 0) { $list.Add([byte]0) }
    $list.AddRange($valB)
    while (($list.Count % 4) -ne 0) { $list.Add([byte]0) }  # pad akhir agar blok berikutnya sejajar
    $len = [System.BitConverter]::GetBytes([uint16]$list.Count)
    $list[0] = $len[0]; $list[1] = $len[1]
    return $list.ToArray()
}

# Blok pembungkus (StringTable/StringFileInfo/VarFileInfo/Var/VS_VERSION_INFO)
function New-WrapBlock {
    param([string]$Key, $ValueBytes, [int]$ValueLength, [int]$Type, $Children)
    $list = New-Object 'System.Collections.Generic.List[byte]'
    $keyB = [System.Text.Encoding]::Unicode.GetBytes($Key + [char]0)
    $list.AddRange([byte[]](0, 0))                 # wLength (diisi di akhir)
    Add-U16 $list ([uint16]$ValueLength)
    Add-U16 $list ([uint16]$Type)
    $list.AddRange($keyB)
    while (($list.Count % 4) -ne 0) { $list.Add([byte]0) }
    if ($ValueBytes) { $list.AddRange([byte[]]$ValueBytes) }
    foreach ($c in $Children) { $list.AddRange([byte[]]$c) }
    while (($list.Count % 4) -ne 0) { $list.Add([byte]0) }  # pad akhir agar blok berikutnya sejajar
    $len = [System.BitConverter]::GetBytes([uint16]$list.Count)
    $list[0] = $len[0]; $list[1] = $len[1]
    return $list.ToArray()
}

# VS_FIXEDFILEINFO (52 byte)
function New-FixedFileInfo {
    param([string]$FileVer, [string]$ProdVer)
    $fv = @($FileVer.Split('.')); $pv = @($ProdVer.Split('.'))
    while ($fv.Count -lt 4) { $fv += '0' }; while ($pv.Count -lt 4) { $pv += '0' }
    $list = New-Object 'System.Collections.Generic.List[byte]'
    Add-U32 $list ([uint32]4277077181)                     # dwSignature = 0xFEEF04BD
    Add-U32 $list ([uint32]0x00010000)                       # dwStrucVersion
    Add-U32 $list ([uint32](([uint32]$fv[0] -shl 16) -bor ([uint32]$fv[1])))  # dwFileVersionMS
    Add-U32 $list ([uint32](([uint32]$fv[2] -shl 16) -bor ([uint32]$fv[3])))  # dwFileVersionLS
    Add-U32 $list ([uint32](([uint32]$pv[0] -shl 16) -bor ([uint32]$pv[1])))  # dwProductVersionMS
    Add-U32 $list ([uint32](([uint32]$pv[2] -shl 16) -bor ([uint32]$pv[3])))  # dwProductVersionLS
    Add-U32 $list ([uint32]0x3F)                             # dwFileFlagsMask
    Add-U32 $list ([uint32]0)                                # dwFileFlags
    Add-U32 $list ([uint32]0x00040004)                       # dwFileOS = VOS_NT_WINDOWS32
    Add-U32 $list ([uint32]1)                                # dwFileType = VFT_APP
    Add-U32 $list ([uint32]0)                                # dwFileSubtype
    Add-U32 $list ([uint32]0)                                # dwFileDateMS
    Add-U32 $list ([uint32]0)                                # dwFileDateLS
    return $list.ToArray()
}

# --- Susun tree ---
$charset = 0x04B0 # 1200 (Unicode)
$transKey = ('{0:X4}{1:X4}' -f $Language, $charset)          # contoh: 042104B0

$stringBlocks = New-Object System.Collections.ArrayList
[void]$stringBlocks.Add((New-StringBlock 'CompanyName'       $CompanyName))
[void]$stringBlocks.Add((New-StringBlock 'FileDescription'   $FileDescription))
[void]$stringBlocks.Add((New-StringBlock 'FileVersion'       $FileVersion))
[void]$stringBlocks.Add((New-StringBlock 'InternalName'      $FileDescription))
[void]$stringBlocks.Add((New-StringBlock 'LegalCopyright'    $LegalCopyright))
[void]$stringBlocks.Add((New-StringBlock 'OriginalFilename'  (Split-Path $exe -Leaf)))
[void]$stringBlocks.Add((New-StringBlock 'ProductName'       $ProductName))
[void]$stringBlocks.Add((New-StringBlock 'ProductVersion'    $ProductVersion))
[void]$stringBlocks.Add((New-StringBlock 'Comments'          $Comments))

$stringTable    = New-WrapBlock -Key $transKey -ValueLength 0 -Type 1 -Children $stringBlocks.ToArray()
$stringFileInfo = New-WrapBlock -Key 'StringFileInfo' -ValueLength 0 -Type 1 -Children @($stringTable)

$transBytes = [byte[]]@(
    ($Language -band 0xFF), (($Language -shr 8) -band 0xFF),
    ($charset -band 0xFF), (($charset -shr 8) -band 0xFF)
)
$var = New-WrapBlock -Key 'Translation' -ValueLength 4 -Type 0 -ValueBytes $transBytes -Children @()
$varFileInfo = New-WrapBlock -Key 'VarFileInfo' -ValueLength 0 -Type 1 -Children @($var)

$fixed = New-FixedFileInfo -FileVer $FileVersion -ProdVer $ProductVersion
$versionInfo = New-WrapBlock -Key 'VS_VERSION_INFO' -ValueLength $fixed.Length -Type 0 -ValueBytes $fixed -Children @($stringFileInfo, $varFileInfo)

# --- Update resource RT_VERSION (id=1) pada file ---
$h = [VerRes]::BeginUpdateResource($exe, $false)
if ($h -eq [IntPtr]::Zero) { throw "BeginUpdateResource gagal (error $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))" }
$ok = [VerRes]::UpdateResource($h, [IntPtr]0x10, [IntPtr]1, 0, $versionInfo, [uint32]$versionInfo.Length)
if (-not $ok) { [VerRes]::EndUpdateResource($h, $true) | Out-Null; throw "UpdateResource gagal (error $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))" }
$ok2 = [VerRes]::EndUpdateResource($h, $false)
if (-not $ok2) { throw "EndUpdateResource gagal (error $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))" }

Write-Host "[verres] Version resource diperbarui: lang=0x$('{0:X4}' -f $Language), file=$exe"
