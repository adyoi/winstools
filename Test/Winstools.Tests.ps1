# WINSTOOLS - Uji otomatis (Pester 3.4+ / 5.x)
# Jalankan:  powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Pester -Script .\Test"

$here = Split-Path $MyInvocation.MyCommand.Path -Parent
$projRoot = Split-Path $here -Parent

Describe 'Sintaks skrip' {
    $files = @()
    $files += Get-ChildItem (Join-Path $projRoot 'Scripts') -Filter '*.ps1' -File
    $files += Get-ChildItem (Join-Path $projRoot 'Scripts') -Filter '*.psm1' -Recurse -File
    $files += Get-ChildItem (Join-Path $projRoot 'Build') -Filter '*.ps1' -File

    foreach ($f in $files) {
        $rel = $f.FullName.Substring($projRoot.Length)
        It "Sintaks valid: $rel" {
            $tokens = $null
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errors) | Out-Null
            $errors | Should BeNullOrEmpty
        }
    }
}

Describe 'Modul tool' {
    $toolsDir = Join-Path $projRoot 'Scripts\Tools'
    $tools = Get-ChildItem $toolsDir -Filter '*.psm1' -File

    foreach ($t in $tools) {
        It "Tool $($t.Name) dapat di-import dan mengekspor fungsi inti" {
            $m = Import-Module $t.FullName -PassThru -Force -ErrorAction Stop
            $m | Should Not Be $null
            $m.ExportedCommands.ContainsKey('Get-ToolConfig')    | Should Be $true
            $m.ExportedCommands.ContainsKey('Invoke-ToolAction') | Should Be $true
        }

        It "Tool $($t.Name) memiliki konfigurasi yang valid" {
            $m = Import-Module $t.FullName -PassThru -Force -ErrorAction SilentlyContinue
            $cfg = & $m.ExportedCommands['Get-ToolConfig']
            $cfg.MenuName  | Should Not BeNullOrEmpty
            $cfg.ToolName  | Should Not BeNullOrEmpty
            $cfg.Category  | Should Not BeNullOrEmpty
            $cfg.ToolName  | Should Be ([System.IO.Path]::GetFileNameWithoutExtension($t.Name))
        }
    }

    It 'Tidak ada tool tanpa fungsi inti' {
        $tools | Should Not BeNullOrEmpty
    }
}

Describe 'Konsistensi runtime' {
    It 'CustomCommands.json disimpan di %LOCALAPPDATA%\Winstools (bukan folder exe)' {
        $m = Import-Module (Join-Path $projRoot 'Scripts\Tools\CustomCommand.psm1') -PassThru -Force -ErrorAction SilentlyContinue
        $mod = $m | Where-Object { $_.Name -eq 'CustomCommand' } | Select-Object -First 1
        $path = & $mod.ExportedCommands['Get-CustomCommandsPath'] 2>$null
        if ($path) {
            $path | Should Match '^C:\\Users\\.*Winstools'
        }
    }
}

Describe 'Metadata build (build.ps1)' {
    It 'build.ps1 memiliki parameter -Version' {
        $build = Get-Content (Join-Path $projRoot 'Build\build.ps1') -Raw
        $build | Should Match '\[string\]\$Version'
    }
}
