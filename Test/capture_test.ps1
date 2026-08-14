[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$root = Split-Path $PSScriptRoot -Parent   # winstools\
Import-Module (Join-Path $root 'Scripts\Modules\Config.psm1') -Force
Initialize-Config -Environment 'Development' -ConfigPath (Join-Path $env:TEMP 'winstools_test_config.json')
Import-Module (Join-Path $root 'Scripts\Modules\App.psm1') -Force
Import-Module (Join-Path $root 'Scripts\Modules\UI.psm1') -Force
Import-Module (Join-Path $root 'Scripts\Modules\Session.psm1') -Force
Import-Module (Join-Path $root 'Scripts\Modules\Features.psm1') -Force

Add-Type @"
using System;
using System.Runtime.InteropServices;
public struct CR { public int Left, Top, Right, Bottom; }
public class CWin {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out CR r);
    [DllImport("user32.dll")] public static extern bool DwmGetWindowAttribute(IntPtr h, int attr, out CR r, int size);
    public const int DWMWA_EXTENDED_FRAME_BOUNDS = 9;
}
"@
[CWin]::SetProcessDPIAware() | Out-Null

$appState = Get-AppState
$form = New-MainForm
$appState.Form = $form

$panelMenu = New-MenuPanel
$panelHeader = New-MenuHeader
$menuScrollPanel = New-MenuScrollPanel
$panelMenu.Controls.Add($menuScrollPanel)
$panelMenu.Controls.Add($panelHeader)
$panelRight = New-RightPanel
$sessionBar = New-SessionBar
$contentPanel = New-ContentPanel
$panelRight.Controls.Add($sessionBar)
$panelRight.Controls.Add($contentPanel)
$panelRight.Controls.SetChildIndex($contentPanel, 0)
$appState.SessionBar = $sessionBar
$appState.ContentPanel = $contentPanel
$sessionBar.Visible = $false
$welcomeView = New-WelcomeView
$contentPanel.Controls.Add($welcomeView)
$appState.WelcomeView = $welcomeView

$script:shownAt = 0
$form.Add_Shown({ Start-WelcomeLoad; $script:shownAt = [Environment]::TickCount })
$null = Initialize-GlobalTimer
Start-GlobalTimer

$features = Get-Features
$yPos = 15
foreach ($feat in $features) {
    $btn = New-MenuButton -Text $feat.Name
    $btn.Location = [System.Drawing.Point]::new(12, $yPos)
    $btn.Tag = $feat
    $btn.Add_Click({
        $featCopy = $this.Tag
        New-Session -FeatureName $featCopy.Name -Fields $featCopy.Fields -RunAction $featCopy.Action -Feature $featCopy
    })
    $menuScrollPanel.Controls.Add($btn)
    $yPos += 42
}
$form.Controls.Add($panelRight)
$form.Controls.Add($panelMenu)

$script:savePath = Join-Path $env:TEMP 'winstools_capture.png'
$script:captured = $false

$form.Add_Shown({
    $form.Activate()
    $t = New-Object System.Windows.Forms.Timer
    $t.Interval = 250
    $t.Add_Tick({
        param($s, $e)
        $st = Get-AppState
        $wjob = $st.WelcomeJob
        $wb = $st.WelcomeView
        $ready = $false
        if ($wb -and $wb.Document) {
            $txt = $wb.DocumentText
            if ($txt -and -not $txt.Contains('Memuat informasi sistem')) { $ready = $true }
        }
        if (-not $wjob -and $ready) {
            $s.Stop()
            Write-Output ("WELCOME_MS=" + ([Environment]::TickCount - $script:shownAt))
            Start-Sleep -Milliseconds 1200
            $form.TopMost = $true
            $form.BringToFront()
            $form.Activate()
            Start-Sleep -Milliseconds 600
            $v = New-Object CR
            try {
                [CWin]::DwmGetWindowAttribute($form.Handle, [CWin]::DWMWA_EXTENDED_FRAME_BOUNDS, [ref]$v, [System.Runtime.InteropServices.Marshal]::SizeOf([CWin+CR])) | Out-Null
            } catch {
                $v = New-Object CR
                [CWin]::GetWindowRect($form.Handle, [ref]$v) | Out-Null
            }
            $w = $v.Right - $v.Left; $hgt = $v.Bottom - $v.Top
            $bmp = New-Object System.Drawing.Bitmap($w, $hgt)
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            try {
                $g.CopyFromScreen($v.Left, $v.Top, 0, 0, $bmp.Size)
                $bmp.Save($script:savePath, [System.Drawing.Imaging.ImageFormat]::Png)
                $script:captured = $true
            } catch { Write-Output ("CAPTURE_ERR: " + $_) }
            $g.Dispose(); $bmp.Dispose()
            $form.TopMost = $false
            $form.Close()
        }
    })
    $t.Start()
})

$form.ShowDialog()
if ($script:captured) {
    $f = Get-Item $script:savePath
    Write-Output ("SAVED " + $f.FullName + " (" + $f.Length + " bytes)")
} else { Write-Output 'NOT_CAPTURED' }
