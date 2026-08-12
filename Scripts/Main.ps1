<#
.SYNOPSIS
    WINSTOOLS - Windows Super Tools
#>

$WarningPreference = 'SilentlyContinue'
# Resolve module root: normal script -> $PSScriptRoot; ps2exe EXE -> $ScriptRoot (dir of exe)
$script:ModuleRoot = $PSScriptRoot
if (-not $script:ModuleRoot -and $ScriptRoot) { $script:ModuleRoot = $ScriptRoot }
if (-not $script:ModuleRoot -and $MyInvocation.MyCommand.Path) { $script:ModuleRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
if (-not $script:ModuleRoot) { $script:ModuleRoot = (Get-Location).Path }

# Fallback: jika exe/skrip berada di Build\<versi> yang tidak self-contained, cari Modules di Scripts source project
if (-not (Test-Path (Join-Path $script:ModuleRoot "Modules\Config.psm1"))) {
    $cand = Join-Path (Split-Path (Split-Path $script:ModuleRoot -Parent) -Parent) "Scripts"
    if (Test-Path (Join-Path $cand "Modules\Config.psm1")) { $script:ModuleRoot = $cand }
}

# Load Config first
Import-Module (Join-Path $script:ModuleRoot "Modules\Config.psm1") -Force
# Set environment: 'Development' for debug logs, 'Production' for clean output
Initialize-Config -Environment 'Production'

# Initialize elevation BEFORE loading Modules (must be in main script scope)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $scriptPath = $MyInvocation.MyCommand.Path
    if (-not $scriptPath) { $scriptPath = $PSCommandPath }
    if (-not $scriptPath) {
        # Compiled EXE: $ScriptRoot = dir of exe; resolve the exe itself via current process
        try {
            if ($ScriptRoot -and (Test-Path (Join-Path $ScriptRoot "winstools.exe"))) {
                $scriptPath = Join-Path $ScriptRoot "winstools.exe"
            } else {
                $scriptPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
            }
        } catch {}
    }
    if (-not $scriptPath -and $PSScriptRoot) { $scriptPath = Join-Path $PSScriptRoot "Main.ps1" }
    
    try {
        if ($scriptPath -and (Test-Path $scriptPath)) {
            if ($scriptPath -match '\.exe$' -and $scriptPath -notmatch '(powershell|pwsh)\.exe$') {
                # Compiled EXE: relaunch itself elevated (no powershell wrapper)
                Start-Process -FilePath $scriptPath -Verb RunAs
            } else {
                Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
            }
        } else {
            Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -Command `"& '$($MyInvocation.InvocationName)'`"" -Verb RunAs
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Aplikasi membutuhkan hak akses Administrator untuk berjalan.", "Elevation Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
    exit
}

Import-Module (Join-Path $script:ModuleRoot "Modules\App.psm1") -Force
Import-Module (Join-Path $script:ModuleRoot "Modules\UI.psm1") -Force
Import-Module (Join-Path $script:ModuleRoot "Modules\Session.psm1") -Force
Import-Module (Join-Path $script:ModuleRoot "Modules\Features.psm1") -Force

Write-InfoLog "Application starting" -Category 'APP'

# Create main form
$form = New-MainForm
$appState = Get-AppState
$appState.Form = $form

# App icon
$iconPath = Join-Path (Split-Path $script:ModuleRoot -Parent) "Icons\window.ico"
if (-not (Test-Path $iconPath)) { $iconPath = Join-Path $script:ModuleRoot "Icons\window.ico" }
if (Test-Path $iconPath) {
    $form.Icon = [System.Drawing.Icon]::new($iconPath)
}

# Create menu panel (scroll panel added first so header docks on top of it correctly)
$panelMenu = New-MenuPanel
$panelHeader = New-MenuHeader
$menuScrollPanel = New-MenuScrollPanel
$panelMenu.Controls.Add($menuScrollPanel)
$panelMenu.Controls.Add($panelHeader)

# Create right panel
$panelRight = New-RightPanel
$sessionBar = New-SessionBar
$contentPanel = New-ContentPanel
$panelRight.Controls.Add($sessionBar)
$panelRight.Controls.Add($contentPanel)
$panelRight.Controls.SetChildIndex($contentPanel, 0)

$appState.SessionBar = $sessionBar
$appState.ContentPanel = $contentPanel

# Welcome view (tab pane hidden while Welcome is shown)
$sessionBar.Visible = $false
$welcomeView = New-WelcomeView
$contentPanel.Controls.Add($welcomeView)
$appState.WelcomeView = $welcomeView

# Load system info dashboard asynchronously once the form is shown
$form.Add_Shown({ Start-WelcomeLoad })

# Initialize global timer
$null = Initialize-GlobalTimer
Start-GlobalTimer

# Load features and create menu buttons
$features = Get-Features
$yPos = 15

foreach ($feat in $features) {
    $btn = New-MenuButton -Text $feat.Name
    $btn.Location = [System.Drawing.Point]::new(12, $yPos)
    $btn.Tag = $feat

    $btn.Add_Click({
        $featCopy = $this.Tag
        $featureName = $featCopy.Name
        $fields = $featCopy.Fields
        $action = $featCopy.Action
        New-Session -FeatureName $featureName -Fields $fields -RunAction $action -Feature $featCopy
    })

    $menuScrollPanel.Controls.Add($btn)
    $yPos += 42
}

# Assemble form
$form.Controls.Add($panelRight)
$form.Controls.Add($panelMenu)

# Cleanup on close
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
    if ($wjob) {
        Stop-SessionJob -Job $wjob
    }
    [System.Windows.Forms.Application]::Exit()
})

$form.Add_FormClosed({
    Write-InfoLog "Application exiting" -Category 'APP'
})

[void]$form.ShowDialog()