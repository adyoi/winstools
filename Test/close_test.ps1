<#
.SYNOPSIS
    Regression test penutupan aplikasi: menutup form harus menghentikan semua session job
    dan tidak meninggalkan proses anak (ping/cmd/powershell) yang menggantung.

.PARAMETER Scenario
    'none'  - form normal, tutup otomatis, cek tidak ada proses anak tersisa.
    'stuck' - buat session job yang berjalan lama, tutup, cek job ikut dihentikan.
#>
param([string]$Scenario = 'none')

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$root = Split-Path $PSScriptRoot -Parent   # winstools\
Import-Module (Join-Path $root 'Scripts\Modules\Config.psm1') -Force
Initialize-Config -Environment 'Development'
Import-Module (Join-Path $root 'Scripts\Modules\App.psm1') -Force
Import-Module (Join-Path $root 'Scripts\Modules\UI.psm1') -Force
Import-Module (Join-Path $root 'Scripts\Modules\Session.psm1') -Force
Import-Module (Join-Path $root 'Scripts\Modules\Features.psm1') -Force

$appState = Get-AppState
$form = New-MainForm
$appState.Form = $form

if ($Scenario -eq 'stuck') {
    $job = Start-Job -ScriptBlock { & cmd.exe /c ping -n 999 127.0.0.1 }
    Start-Sleep -Seconds 1
    $appState.Sessions['StuckTest'] = @{ Job = $job; IsRunning = $true }
}

# ---- EXACT close handler from Main.ps1 (regression) ----
$form.Add_FormClosing({
    if ($script:AppClosing) { return }
    $script:AppClosing = $true
    Write-InfoLog "Application closing" -Category 'APP'
    $appState = Get-AppState
    $timer = $appState.GlobalTimer
    if ($timer) { $timer.Stop(); $timer.Dispose() }
    foreach ($sess in $appState.Sessions.Values) {
        if ($sess.Job) {
            Stop-SessionJob -Job $sess.Job
        }
    }
    $wjob = $appState.WelcomeJob
    if ($wjob -and $wjob.PowerShell) {
        try { $wjob.PowerShell.Stop() } catch {}
        try { $wjob.PowerShell.Dispose() } catch {}
    }
    [System.Windows.Forms.Application]::Exit()
})
$form.Add_FormClosed({
    Write-InfoLog "Application exiting" -Category 'APP'
})

$script:testForm = $form
$form.Add_Shown({
    $t = New-Object System.Windows.Forms.Timer
    $t.Interval = 3000
    $t.Add_Tick({
        param($s, $e)
        $s.Stop()
        $script:testForm.Close()
    })
    $t.Start()
})

$sw = [Diagnostics.Stopwatch]::StartNew()
$form.ShowDialog()
$sw.Stop()
Write-Output "FORMELLAPSED_MS=$($sw.ElapsedMilliseconds)"
Start-Sleep -Milliseconds 800
$left = @(Get-CimInstance Win32_Process -Filter "ParentProcessId = $PID" | Where-Object { $_.Name -match 'ping|cmd|powershell|pwsh' })
Write-Output ("LEFTOVER_CHILDREN=" + ($left.Name -join ','))
