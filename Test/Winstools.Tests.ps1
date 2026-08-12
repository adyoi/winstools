# WINSTOOLS - Uji otomatis (kompatibel Pester 3.4 & 5.x)
# Jalankan:  powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Pester -Script .\Test"
# Catatan: assertion memakai `throw` (bukan sintaks 'Should') agar lintas-versi Pester.

$here = Split-Path $MyInvocation.MyCommand.Path -Parent
$projRoot = Split-Path $here -Parent

Describe 'Sintaks skrip' {
    $files = @()
    $files += Get-ChildItem (Join-Path $projRoot 'Scripts') -Filter '*.ps1' -File
    $files += Get-ChildItem (Join-Path $projRoot 'Scripts') -Filter '*.psm1' -Recurse -File
    $files += Get-ChildItem (Join-Path $projRoot 'Build') -Filter '*.ps1' -File

    foreach ($f in $files) {
        $rel = $f.FullName.Substring($projRoot.Length)
        It "Sintaks valid: $rel" -TestCases @{ f = $f } {
            param($f)
            $tokens = $null
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errors) | Out-Null
            if ($null -ne $errors -and $errors.Count -gt 0) {
                throw "Parse error: $($errors[0].Message)"
            }
        }
    }
}

Describe 'Modul tool' {
    $toolsDir = Join-Path $projRoot 'Scripts\Tools'
    $tools = Get-ChildItem $toolsDir -Filter '*.psm1' -File

    foreach ($t in $tools) {
        It "Tool $($t.Name) dapat di-import dan mengekspor fungsi inti" -TestCases @{ t = $t } {
            param($t)
            $m = Import-Module $t.FullName -PassThru -Force -ErrorAction Stop
            if (-not $m) { throw "Modul tidak ter-import: $($t.Name)" }
            foreach ($fn in @('Get-ToolConfig', 'Invoke-ToolAction')) {
                if (-not $m.ExportedCommands.ContainsKey($fn)) { throw "Tool $($t.Name) tidak mengekspor $fn" }
            }
        }

        It "Tool $($t.Name) memiliki konfigurasi yang valid" -TestCases @{ t = $t } {
            param($t)
            $m = Import-Module $t.FullName -PassThru -Force -ErrorAction SilentlyContinue
            $cfg = & $m.ExportedCommands['Get-ToolConfig']
            foreach ($prop in @('MenuName', 'ToolName', 'Category')) {
                if ([string]::IsNullOrEmpty($cfg.$prop)) { throw "Tool $($t.Name): field $prop kosong" }
            }
            $expected = [System.IO.Path]::GetFileNameWithoutExtension($t.Name)
            if ($cfg.ToolName -ne $expected) { throw "Tool $($t.Name): ToolName '$($cfg.ToolName)' tidak sama dengan '$expected'" }
        }
    }

    It 'Tidak ada tool tanpa fungsi inti' -TestCases @{ count = $tools.Count } {
        param($count)
        if ($count -le 0) { throw 'Tidak ada tool ditemukan di Scripts\Tools' }
    }
}

Describe 'Konsistensi runtime' {
    It 'CustomCommands.json disimpan di %LOCALAPPDATA%\Winstools (bukan folder exe)' -TestCases @{ modPath = (Join-Path $projRoot 'Scripts\Tools\CustomCommand.psm1') } {
        param($modPath)
        Import-Module $modPath -Force -ErrorAction SilentlyContinue
        $path = Get-CustomCommandsPath
        if (-not $path) { throw 'Get-CustomCommandsPath tidak mengembalikan path' }
        if ($path -notmatch '^C:\\Users\\.*Winstools') { throw "Path tidak berada di %LOCALAPPDATA%\Winstools: $path" }
    }
}

Describe 'Metadata build (build.ps1)' {
    It 'build.ps1 memiliki parameter -Version' -TestCases @{ buildPath = (Join-Path $projRoot 'Build\build.ps1') } {
        param($buildPath)
        $build = Get-Content $buildPath -Raw
        if ($build -notmatch '\[string\]\$Version') { throw 'build.ps1 tidak memiliki parameter -Version' }
    }

    It 'build.ps1 membaca versi dari file VERSION di root project' -TestCases @{ buildPath = (Join-Path $projRoot 'Build\build.ps1') } {
        param($buildPath)
        $build = Get-Content $buildPath -Raw
        if ($build -notmatch 'VERSION') { throw 'build.ps1 tidak membaca file VERSION' }
    }

    It 'build.ps1 memakai timestamp server DigiCert' -TestCases @{ buildPath = (Join-Path $projRoot 'Build\build.ps1') } {
        param($buildPath)
        $build = Get-Content $buildPath -Raw
        if ($build -notmatch 'timestamp\.digicert\.com') { throw 'build.ps1 tidak memakai timestamp server DigiCert' }
    }

    It 'build.ps1 memakai env WINSTOOLS_PFX_PASSWORD untuk password PFX' -TestCases @{ buildPath = (Join-Path $projRoot 'Build\build.ps1') } {
        param($buildPath)
        $build = Get-Content $buildPath -Raw
        if ($build -notmatch 'WINSTOOLS_PFX_PASSWORD') { throw 'build.ps1 tidak memakai env password PFX' }
    }

    It 'File VERSION ada di root project dan berisi versi valid' -TestCases @{ vf = (Join-Path $projRoot 'VERSION') } {
        param($vf)
        if (-not (Test-Path $vf)) { throw 'File VERSION tidak ditemukan' }
        $v = (Get-Content $vf -Raw).Trim()
        if ($v -notmatch '^\d+\.\d+(\.\d+)*$') { throw "Format versi tidak valid: '$v'" }
    }
}

Describe 'Skema konfigurasi tool' {
    $toolsDir = Join-Path $projRoot 'Scripts\Tools'
    $tools = Get-ChildItem $toolsDir -Filter '*.psm1' -File

    foreach ($t in $tools) {
        It "Tool $($t.Name): Fields memenuhi skema" -TestCases @{ t = $t } {
            param($t)
            $m = Import-Module $t.FullName -PassThru -Force -ErrorAction SilentlyContinue
            $cfg = & $m.ExportedCommands['Get-ToolConfig']
            $flds = $cfg.Fields
            if ($null -eq $flds) { throw "Tool $($t.Name) tidak mendefinisikan Fields" }
            $knownTypes = @('Text', 'TextArea', 'Combo', 'Password')
            foreach ($f in @($flds)) {
                if ([string]::IsNullOrEmpty($f.Name))  { throw "Tool $($t.Name): field tanpa Name" }
                if ([string]::IsNullOrEmpty($f.Label)) { throw "Tool $($t.Name): field '$($f.Name)' tanpa Label" }
                if ($knownTypes -notcontains $f.Type)  { throw "Tool $($t.Name): field '$($f.Name)' tipe '$($f.Type)' tidak dikenal" }
            }
        }
    }

    It 'Tool destruktif menetapkan RequiresConfirm = true' {
        $expected = @('ClearDNS', 'DiskRepair', 'DisableServices', 'WinUpdateReset', 'SetOEM', 'ProxyManager')
        foreach ($toolName in $expected) {
            $file = Join-Path $toolsDir "$toolName.psm1"
            if (-not (Test-Path $file)) { throw "Tool destruktif tidak ditemukan: $toolName" }
            $m = Import-Module $file -PassThru -Force -ErrorAction SilentlyContinue
            $cfg = & $m.ExportedCommands['Get-ToolConfig']
            if ($cfg.RequiresConfirm -ne $true) { throw "Tool $toolName tidak menetapkan RequiresConfirm = true" }
        }
    }
}

Describe 'CustomCommands roundtrip (tanpa merusak data user)' {
    It 'Save -> Read -> Remove berfungsi dan memulihkan file asli' -TestCases @{ modPath = (Join-Path $projRoot 'Scripts\Tools\CustomCommand.psm1') } {
        param($modPath)
        Import-Module $modPath -Force -ErrorAction Stop
        $path = Get-CustomCommandsPath
        $hadFile = Test-Path $path
        $backup = $null
        if ($hadFile) { $backup = [System.IO.File]::ReadAllText($path) }
        try {
            Save-CustomCommand 'winstools_test_rt' 'Write-Output roundtrip-ok' | Out-Null
            $cmds = Read-CustomCommands
            if (-not $cmds.ContainsKey('winstools_test_rt')) { throw 'Perintah tidak tersimpan ke file' }
            if ($cmds['winstools_test_rt'] -ne 'Write-Output roundtrip-ok') { throw 'Nilai command tidak sesuai setelah roundtrip' }
            Remove-CustomCommand 'winstools_test_rt' | Out-Null
            $cmds2 = Read-CustomCommands
            if ($cmds2.ContainsKey('winstools_test_rt')) { throw 'Perintah tidak terhapus' }
        } finally {
            if ($hadFile) { [System.IO.File]::WriteAllText($path, $backup) }
            else { Remove-Item $path -Force -ErrorAction SilentlyContinue }
        }
    }
}

Describe 'Integritas build (hanya bila exe ada)' {
    $buildRoot = Join-Path $projRoot 'Build'
    $buildDirs = @(Get-ChildItem $buildRoot -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName 'winstools.exe') })
    $versionFile = Join-Path $projRoot 'VERSION'

    if ($buildDirs.Count -gt 0) {
        foreach ($d in $buildDirs) {
            It "Build $($d.Name): winstools.exe self-contained dan versi sesuai VERSION" -TestCases @{ exe = (Join-Path $d.FullName 'winstools.exe'); d = $d; vf = $versionFile } {
                param($exe, $d, $vf)
                if (-not (Test-Path $exe)) { throw 'winstools.exe tidak ada' }
                foreach ($sub in @('Modules', 'Tools', 'Icons')) {
                    if (-not (Test-Path (Join-Path $d.FullName $sub))) { throw "Folder $sub tidak ada di build" }
                }
                $vi = (Get-Item $exe).VersionInfo
                if ([string]::IsNullOrEmpty($vi.FileVersion)) { throw 'FileVersion kosong pada exe' }
                $expected = ((Get-Content $vf -Raw).Trim() -split '\.')
                while ($expected.Count -lt 4) { $expected += '0' }
                if ($vi.FileVersion -ne ($expected -join '.')) { throw "FileVersion '$($vi.FileVersion)' != '$($expected -join '.')'" }
            }
        }
    }
}
