<#
.SYNOPSIS
    GUI smoke test: memuat semua modul (seperti Main.ps1) lalu menampilkan form utama.

.PARAMETER AutoClose
    Jumlah detik sebelum form ditutup otomatis (default: 5). Gunakan 0 untuk manual.
.PARAMETER Environment
    'Production' (default) atau 'Development' (log debug).

.CONTOH
    powershell -ExecutionPolicy Bypass -File .\Test\form_test.ps1 -AutoClose 5
#>
param(
    [int]$AutoClose = 5,
    [string]$Environment = 'Production'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent   # winstools\

Import-Module (Join-Path $root 'Scripts\Modules\Config.psm1') -Force
Initialize-Config -Environment $Environment
Import-Module (Join-Path $root 'Scripts\Modules\App.psm1') -Force
Import-Module (Join-Path $root 'Scripts\Modules\UI.psm1') -Force
Import-Module (Join-Path $root 'Scripts\Modules\Session.psm1') -Force
Import-Module (Join-Path $root 'Scripts\Modules\Features.psm1') -Force

$form = New-MainForm
$appState = Get-AppState
$appState.Form = $form

$script:testForm = $form
if ($AutoClose -gt 0) {
    $form.Add_Shown({
        $t = New-Object System.Windows.Forms.Timer
        $t.Interval = $AutoClose * 1000
        $t.Add_Tick({
            param($s, $e)
            $s.Stop()
            $script:testForm.Close()
        })
        $t.Start()
    })
}

[void]$form.ShowDialog()
Write-Host "[test] form ditutup, OK"
