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
}
