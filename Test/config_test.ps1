<#
.SYNOPSIS
    Config GUI test: verifikasi tab Gui Config (tombol Options) memuat nilai aktif
    dan menerapkan perubahan dengan benar.
#>
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$root = Split-Path $PSScriptRoot -Parent   # winstools\
Import-Module (Join-Path $root 'Scripts\Modules\Config.psm1') -Force
Initialize-Config -Environment 'Development' -Debug:$false -LogLevel 'WARN' | Out-Null
Import-Module (Join-Path $root 'Scripts\Modules\Options.psm1') -Force

Write-Output "== [1] Tab Config harus menampilkan nilai aktif (Development / Debug=false / WARN) =="
$tab = & (Get-Module Options) { New-ConfigTab }
$envCombo = $null; $dbgChk = $null; $logCombo = $null; $status = $null
foreach ($ctrl in $tab.Controls) {
    if ($ctrl -is [System.Windows.Forms.ComboBox]) {
        if ($ctrl.Items.Count -eq 2) { $envCombo = $ctrl }
        elseif ($ctrl.Items.Count -eq 4) { $logCombo = $ctrl }
    }
    if ($ctrl -is [System.Windows.Forms.CheckBox]) { $dbgChk = $ctrl }
    if ($ctrl -is [System.Windows.Forms.Label] -and $ctrl.Text -like 'Nilai aktif*') { $status = $ctrl }
}
Write-Output ("UI  : Env=" + $envCombo.SelectedIndex + " (" + $envCombo.Text + ") Debug=" + $dbgChk.Checked + " Log=" + $logCombo.Text)
Write-Output ("Sesi: Env=" + (Get-Config -Key Environment) + " Debug=" + (Get-Config -Key Debug) + " Log=" + (Get-Config -Key LogLevel))

Write-Output "== [2] Klik Terapkan tanpa mengubah (nilai harus tetap) =="
$btnApply = $tab.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] -and $_.Text -eq 'Terapkan' } | Select-Object -First 1
$btnApply.PerformClick()
Write-Output ("Sesi: Env=" + (Get-Config -Key Environment) + " Debug=" + (Get-Config -Key Debug) + " Log=" + (Get-Config -Key LogLevel))

Write-Output "== [3] Ganti Environment -> Production, Terapkan =="
$envCombo.SelectedIndex = 0
$btnApply.PerformClick()
Write-Output ("Sesi: Env=" + (Get-Config -Key Environment) + " Debug=" + (Get-Config -Key Debug) + " Log=" + (Get-Config -Key LogLevel))
Write-Output ("Status: " + $status.Text)
