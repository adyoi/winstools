<#
.SYNOPSIS
    Button test: verifikasi tombol Options (merah + separator) dibangun benar dan
    dialog Options terbuka + tertutup bersih.

.PARAMETER AutoClose
    Detik sebelum dialog Options ditutup otomatis (default: 3).
#>
param([int]$AutoClose = 3)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$root = Split-Path $PSScriptRoot -Parent   # winstools\
Import-Module (Join-Path $root 'Scripts\Modules\Config.psm1') -Force
Initialize-Config -Environment 'Production' -ConfigPath (Join-Path $env:TEMP 'winstools_test_config.json') | Out-Null
Import-Module (Join-Path $root 'Scripts\Modules\Options.psm1') -Force

Write-Output "== [1] Tombol Options =="
$btn = New-OptionsButton
Write-Output ("Text: '" + $btn.Text + "'  Size: " + $btn.Width + "x" + $btn.Height)
Write-Output ("BackColor: " + $btn.BackColor.R + "," + $btn.BackColor.G + "," + $btn.BackColor.B)
$sep = New-OptionsSeparator
Write-Output ("Separator: " + $sep.Width + "x" + $sep.Height)

Write-Output "== [2] Dialog Options terbuka + auto-close =="
$form = & (Get-Module Options) { New-OptionsForm }
$tabs = [System.Windows.Forms.TabControl]::new()
$tabs.Dock = [System.Windows.Forms.DockStyle]::Fill
$tabs.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$tabs.Padding = [System.Drawing.Point]::new(12, 6)
$tabs.TabPages.Add((& (Get-Module Options) { New-ConfigTab }))
$tabs.TabPages.Add((& (Get-Module Options) { New-BuilderTab }))
$tabs.TabPages.Add((& (Get-Module Options) { New-TesterTab }))
$tabs.TabPages.Add((& (Get-Module Options) { New-UpdateTab }))
$tabs.TabPages.Add((& (Get-Module Options) { New-ChangelogTab }))
$tabs.TabPages.Add((& (Get-Module Options) { New-AboutTab }))
$form.Controls.Add($tabs)
Write-Output ("TabCount: " + $tabs.TabPages.Count + "  (" + (($tabs.TabPages | ForEach-Object { $_.Text }) -join ', ') + ")")

$script:dlgForm = $form
$script:dlgOk = $false
if ($AutoClose -gt 0) {
    $form.Add_Shown({
        $t = New-Object System.Windows.Forms.Timer
        $t.Interval = $AutoClose * 1000
        $t.Add_Tick({
            param($s, $e)
            $s.Stop()
            $script:dlgForm.Close()
        })
        $t.Start()
    })
}
$form.Add_FormClosed({
    $script:dlgOk = $true
})
[void]$form.ShowDialog()
Write-Output ("Closed=" + $script:dlgOk)
Write-Output "BUTTON_TEST_DONE"
