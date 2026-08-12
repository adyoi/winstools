<#
.SYNOPSIS
    UI Module - Form, panels, controls creation
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$text_menu       = "WINSTOOLS v1.0"
$text_form       = "Windows Super Tools - $text_menu"
$text_btnLeft    = "<"
$text_btnRight   = ">"
$text_lblNoParam = ""
$text_btnRun     = "RUN"
$text_btnClear   = "CLEAR"

function New-MainForm {
    $form = [System.Windows.Forms.Form]::new()
    $form.Text = $text_form
    $form.Size = [System.Drawing.Size]::new(1024, 680)
    $form.MinimumSize = [System.Drawing.Size]::new(1000, 700)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    return $form
}

function New-MenuPanel {
    $panel = [System.Windows.Forms.Panel]::new()
    $panel.Dock = [System.Windows.Forms.DockStyle]::Left
    $panel.Width = 240
    $panel.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    return $panel
}

function New-MenuHeader {
    $header = [System.Windows.Forms.Panel]::new()
    $header.Height = 70
    $header.Dock = [System.Windows.Forms.DockStyle]::Top
    $header.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)

    $lbl = [System.Windows.Forms.Label]::new()
    $lbl.Text = $text_menu
    $lbl.Font = [System.Drawing.Font]::new("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $lbl.ForeColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $lbl.Location = [System.Drawing.Point]::new(20, 22)
    $lbl.AutoSize = $true
    $header.Controls.Add($lbl)
    return $header
}

function New-MenuScrollPanel {
    $panel = [System.Windows.Forms.Panel]::new()
    $panel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $panel.AutoScroll = $true
    return $panel
}

function New-RightPanel {
    $panel = [System.Windows.Forms.Panel]::new()
    $panel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $panel.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 247)
    return $panel
}

function New-SessionBar {
    $bar = [System.Windows.Forms.Panel]::new()
    $bar.Height = 40
    $bar.Dock = [System.Windows.Forms.DockStyle]::Top
    $bar.BackColor = [System.Drawing.Color]::FromArgb(230, 230, 235)

    $tabsHost = [System.Windows.Forms.Panel]::new()
    $tabsHost.Dock = [System.Windows.Forms.DockStyle]::Fill
    $tabsHost.AutoScroll = $true
    $tabsHost.BackColor = [System.Drawing.Color]::FromArgb(230, 230, 235)
    $tabsHost.HorizontalScroll.Visible = $false
    $tabsHost.HorizontalScroll.Enabled = $true
    $tabsHost.VerticalScroll.Visible = $false
    $tabsHost.VerticalScroll.Enabled = $false

    $tabs = [System.Windows.Forms.FlowLayoutPanel]::new()
    $tabs.Anchor = 'Left, Top'
    $tabs.Location = [System.Drawing.Point]::new(0, 0)
    $tabs.Height = 35
    $tabs.Width = $tabsHost.ClientSize.Width
    $tabs.WrapContents = $false
    $tabs.BackColor = [System.Drawing.Color]::FromArgb(230, 230, 235)
    $tabs.Padding = [System.Windows.Forms.Padding]::new(6, 3, 0, 0)
    $tabsHost.Controls.Add($tabs)

    $btnLeft = [System.Windows.Forms.Button]::new()
    $btnLeft.Text = $text_btnLeft
    $btnLeft.Dock = [System.Windows.Forms.DockStyle]::Right
    $btnLeft.Width = 22
    $btnLeft.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnLeft.FlatAppearance.BorderSize = 0
    $btnLeft.BackColor = [System.Drawing.Color]::FromArgb(200, 200, 208)
    $btnLeft.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 85)
    $btnLeft.Font = [System.Drawing.Font]::new("Segoe UI", 11)
    $btnLeft.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $btnLeft.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnLeft.Visible = $false

    $btnRight = [System.Windows.Forms.Button]::new()
    $btnRight.Text = $text_btnRight
    $btnRight.Dock = [System.Windows.Forms.DockStyle]::Right
    $btnRight.Width = 22
    $btnRight.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnRight.FlatAppearance.BorderSize = 0
    $btnRight.BackColor = [System.Drawing.Color]::FromArgb(200, 200, 208)
    $btnRight.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 85)
    $btnRight.Font = [System.Drawing.Font]::new("Segoe UI", 11)
    $btnRight.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $btnRight.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnRight.Visible = $false

    $btnLeft.Add_Click({
        param($s, $e)
        $host = $s.Tag
        $x = [Math]::Abs($host.AutoScrollPosition.X) - 140
        if ($x -lt 0) { $x = 0 }
        $host.AutoScrollPosition = [System.Drawing.Point]::new($x, 0)
        $host.Refresh()
    })
    $btnRight.Add_Click({
        param($s, $e)
        $host = $s.Tag
        $x = [Math]::Abs($host.AutoScrollPosition.X) + 140
        $host.AutoScrollPosition = [System.Drawing.Point]::new($x, 0)
        $host.Refresh()
    })
    $btnLeft.Tag = $tabsHost
    $btnRight.Tag = $tabsHost

    $tabsHost.Add_Resize({ Update-SessionBarArrows })

    $bar.Controls.Add($tabsHost)
    $bar.Controls.Add($btnLeft)
    $bar.Controls.Add($btnRight)

    $bar | Add-Member -NotePropertyName Tabs -NotePropertyValue $tabs -Force
    $bar | Add-Member -NotePropertyName TabsHost -NotePropertyValue $tabsHost -Force
    $bar | Add-Member -NotePropertyName BtnLeft -NotePropertyValue $btnLeft -Force
    $bar | Add-Member -NotePropertyName BtnRight -NotePropertyValue $btnRight -Force
    return $bar
}

function Update-SessionBarArrows {
    $bar = Get-AppState -Key 'SessionBar'
    if (-not $bar) { return }
    $bar.Tabs.PerformLayout()
    $pref = $bar.Tabs.PreferredSize.Width
    $client = $bar.TabsHost.ClientSize.Width
    $bar.Tabs.Width = [Math]::Max($client, $pref)
    $overflow = $pref -gt $client
    $bar.BtnLeft.Visible = $overflow
    $bar.BtnRight.Visible = $overflow
    if (-not $overflow) {
        $bar.TabsHost.AutoScrollPosition = [System.Drawing.Point]::new(0, 0)
    }
}

function Set-TabActive {
    param($Tab, [bool]$Active)
    $blue = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $inactiveBack = [System.Drawing.Color]::FromArgb(200, 202, 210)
    if ($Active) {
        $Tab.Panel.BackColor = $blue
        $Tab.Label.BackColor = $blue
        $Tab.Label.ForeColor = [System.Drawing.Color]::White
        $Tab.CloseButton.BackColor = [System.Drawing.Color]::FromArgb(70, 165, 235)
        $Tab.CloseButton.ForeColor = [System.Drawing.Color]::White
        $Tab.Indicator.Visible = $true
    } else {
        $Tab.Panel.BackColor = $inactiveBack
        $Tab.Label.BackColor = $inactiveBack
        $Tab.Label.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 85)
        $Tab.CloseButton.BackColor = [System.Drawing.Color]::FromArgb(185, 188, 196)
        $Tab.CloseButton.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 105)
        $Tab.Indicator.Visible = $false
    }
}

function New-ContentPanel {
    $panel = [System.Windows.Forms.Panel]::new()
    $panel.Dock = [System.Windows.Forms.DockStyle]::Fill
    return $panel
}

function Get-PhysicalCoreCount {
    $coreCount = 0
    try {
        if (-not ('Winstools.Native.CpuInfo' -as [type])) {
            Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace Winstools.Native {
    public static class CpuInfo {
        [StructLayout(LayoutKind.Sequential)]
        public struct SLPI {
            public UIntPtr ProcessorMask;
            public uint Relationship;
            public uint ExtraInfoSize;
            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 16)]
            public byte[] ExtraInfo;
        }
        const uint REL_PROCESSOR_CORE = 0;
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool GetLogicalProcessorInformation(IntPtr buffer, ref uint returnedLength);
        public static int PhysicalCores() {
            uint len = 0;
            GetLogicalProcessorInformation(IntPtr.Zero, ref len);
            int size = (int)len;
            if (size <= 0) return -1;
            IntPtr buf = Marshal.AllocHGlobal(size);
            try {
                if (!GetLogicalProcessorInformation(buf, ref len)) return -1;
                int stride = Marshal.SizeOf(typeof(SLPI));
                int count = 0;
                long baseAddr = buf.ToInt64();
                for (long off = 0; off + stride <= size; off += stride) {
                    SLPI info = (SLPI)Marshal.PtrToStructure((IntPtr)(baseAddr + off), typeof(SLPI));
                    if (info.Relationship == REL_PROCESSOR_CORE) count++;
                }
                return count;
            } finally {
                Marshal.FreeHGlobal(buf);
            }
        }
    }
}
'@
        }
        $coreCount = [Winstools.Native.CpuInfo]::PhysicalCores()
    } catch {
        $coreCount = 0
    }
    if ($coreCount -le 0) { $coreCount = [Environment]::ProcessorCount }
    return $coreCount
}

function Get-AppIconHtml {
    $pngPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Icons\window.png"
    if (-not (Test-Path $pngPath)) { $pngPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Icons\window.png" }
    if (-not (Test-Path $pngPath)) { return "" }
    $iconData = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pngPath))
    return "<img src=`"data:image/png;base64,$iconData`" style=`"width:40px;height:40px;vertical-align:middle;margin-right:12px;`" alt=`"`">"
}

function Get-WelcomeHtml {
    function To-Gb([double]$bytes) {
        if ($bytes -le 0) { return "0 GB" }
        return ("{0:N1} GB" -f ($bytes / 1GB))
    }

    $iconImg = Get-AppIconHtml
    
    # --- Native info collection (registry + .NET, no WMI/wmic) ---
    $regWin  = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
    $regBIOS = Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS' -ErrorAction SilentlyContinue
    $regCPU  = Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0' -ErrorAction SilentlyContinue

    $winName  = if ($regWin.ProductName) { [string]$regWin.ProductName } else { 'Windows' }
    $winVer   = if ($regWin.DisplayVersion) { [string]$regWin.DisplayVersion } else { '' }
    $winBuild = if ($regWin.CurrentBuild) { [string]$regWin.CurrentBuild } else { '' }
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ($arch -in @('AMD64', 'ARM64')) { $arch = '64-bit' } elseif ($arch -eq 'x86') { $arch = '32-bit' }

    $instDate = ''
    if ($regWin.InstallDate) {
        try { $instDate = ([DateTimeOffset]::FromUnixTimeSeconds([int64]$regWin.InstallDate)).DateTime.ToString('yyyy-MM-dd') } catch {}
    }

    $bootTime = $null
    try { $bootTime = (Get-Process -Id 4 -ErrorAction Stop).StartTime } catch {}
    $bootStr = if ($bootTime) { $bootTime.ToString('dd-MM HH:mm') } else { 'N/A' }
    $uptime = if ($bootTime) { (Get-Date) - $bootTime } else { [TimeSpan]::Zero }
    $upDays = [Math]::Floor($uptime.TotalDays); $upHours = $uptime.Hours; $upMins = $uptime.Minutes

    $ramTotal = 0; $ramFree = 0; $ramUsed = 0; $ramPct = 0
    try {
        Add-Type -AssemblyName Microsoft.VisualBasic -ErrorAction Stop
        $ci = New-Object Microsoft.VisualBasic.Devices.ComputerInfo
        $ramTotal = [double]$ci.TotalPhysicalMemory
        $ramFree  = [double]$ci.AvailablePhysicalMemory
        $ramUsed  = $ramTotal - $ramFree
        $ramPct   = if ($ramTotal -gt 0) { [Math]::Round(($ramUsed / $ramTotal) * 100) } else { 0 }
    } catch {}

    $cpuName   = if ($regCPU.ProcessorNameString) { [string]$regCPU.ProcessorNameString } else { $env:PROCESSOR_IDENTIFIER }
    $maxMhz    = if ($regCPU.'~MHz') { [int64]$regCPU.'~MHz' } else { 0 }
    $cpuGHz    = if ($maxMhz -gt 0) { ("{0:N2} GHz" -f ($maxMhz / 1000)) } else { 'N/A' }
    $cpuCores   = Get-PhysicalCoreCount
    $cpuThreads = [Environment]::ProcessorCount

    $sysManu  = if ($regBIOS.SystemManufacturer) { [string]$regBIOS.SystemManufacturer } else { '' }
    $sysModel = if ($regBIOS.SystemProductName) { [string]$regBIOS.SystemProductName } else { '' }
    $mbManu   = if ($regBIOS.BaseBoardManufacturer) { [string]$regBIOS.BaseBoardManufacturer } else { '' }
    $mbProd   = if ($regBIOS.BaseBoardProduct) { [string]$regBIOS.BaseBoardProduct } else { '' }

    $biosManu = if ($regBIOS.BIOSVendor) { [string]$regBIOS.BIOSVendor } else { '' }
    $biosVer  = ''
    if ($regBIOS.BIOSVersion) { $biosVer = @($regBIOS.BIOSVersion) | Where-Object { $_ } | Select-Object -First 1 }
    $biosDate = if ($regBIOS.BIOSReleaseDate) { [string]$regBIOS.BIOSReleaseDate } else { '' }

    $gpus = @()
    try {
        $gpuRoot = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
        foreach ($node in @(Get-ChildItem $gpuRoot -ErrorAction SilentlyContinue)) {
            $np = Get-ItemProperty $node.PSPath -ErrorAction SilentlyContinue
            if (-not $np.DriverDesc) { continue }
            $vram = 0
            if ($np.'HardwareInformation.qwMemorySize') {
                $v = $np.'HardwareInformation.qwMemorySize'
                if ($v -is [byte[]]) {
                    try { $vram = [BitConverter]::ToUInt64($v, 0) } catch {}
                } elseif ($v -is [long] -or $v -is [int]) { $vram = [int64]$v }
            }
            $gpus += [pscustomobject]@{ Name = [string]$np.DriverDesc; Vram = $vram }
        }
    } catch {}

    $disks = @()
    try {
        $disks = @([IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq [IO.DriveType]::Fixed -and $_.IsReady } |
            ForEach-Object { [pscustomobject]@{ DeviceID = $_.Name.TrimEnd('\'); Total = [double]$_.TotalSize; Free = [double]$_.TotalFreeSpace } })
    } catch {}

    $ips = @()
    try {
        $ips = @([System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
            ForEach-Object { $_.GetIPProperties().UnicastAddresses } |
            Where-Object { $_.Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork -and $_.Address.ToString() -notlike '127.*' -and $_.Address.ToString() -notlike '169.254.*' } |
            ForEach-Object { $_.Address.ToString() })
    } catch {}

    $netHtml = ""
    if ($ips.Count -gt 0) { foreach ($ip in $ips) { $netHtml += "<div>$ip</div>" } } else { $netHtml = "<div class=`"dim`">N/A</div>" }

    $gpuHtml = ""
    if ($gpus.Count -eq 0) {
        $gpuHtml = '<tr><td class="v">No GPU detected</td></tr>'
    } else {
        foreach ($g in $gpus) {
            $vram = if ($g.Vram -gt 0) { To-Gb $g.Vram } else { "N/A" }
            $gpuHtml += "<tr><td class=`"v`">$($g.Name) <span class=`"dim`">($vram)</span></td></tr>"
        }
    }

    $diskHtml = ""
    foreach ($d in $disks) {
        $total = $d.Total
        $free  = $d.Free
        $used  = $total - $free
        $pct   = if ($total -gt 0) { [Math]::Round(($used / $total) * 100) } else { 0 }
        $barW  = [Math]::Min(100, $pct)
        $diskHtml += @"
<tr>
    <td class="k">$($d.DeviceID)</td>
    <td class="v">$(To-Gb $total) total &middot; $(To-Gb $free) bebas</td>
    <td class="v"><div class="bar"><div class="fill" style="width:$barW%"></div></div></td>
    <td class="v">$pct% terpakai</td>
</tr>
"@
    }

    $cardStart = '<td style="padding:5px;vertical-align:top;"><div class="card">'
    $cardEnd   = '</div></td>'

    $html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
    body { margin:0; padding:16px 22px; background:#e6e6eb; font-family:'Segoe UI',Arial,sans-serif; color:#2b2b2b; }
    h1 { font-size:22px; margin:0 0 2px 0; }
    .sub { color:#6a6a75; font-size:12px; margin:0 0 12px 0; }
    table.grid { border-collapse:collapse; width:100%; }
    td.holder { padding:5px; vertical-align:top; }
    .card { background:#ffffff; border:1px solid #d5d5de; border-radius:8px; padding:10px 14px; }
    .card .title { font-size:11px; color:#7a7a85; margin-bottom:4px; text-transform:uppercase; letter-spacing:0.5px; }
    .card .big { font-size:16px; font-weight:bold; color:#1f1f24; }
    .card .small { font-size:12px; color:#5f5f6a; margin-top:2px; }
    table.spec { border-collapse:collapse; width:100%; }
    table.spec td { padding:2px 0; font-size:12px; vertical-align:top; }
    td.k { color:#7a7a85; width:96px; white-space:nowrap; }
    td.v { color:#33333a; }
    .dim { color:#9a9aa5; }
    .bar { background:#e2e2e8; border-radius:4px; height:8px; width:110px; overflow:hidden; }
    .fill { background:#0a7ccb; height:100%; }
    .foot { color:#8a8a95; font-size:11px; margin-top:12px; }
</style>
</head>
<body>
    <h1>$iconImg$text_menu</h1>
    <p class="sub">Sistem Maintenance Tool &mdash; Multi-Session &middot; $($env:COMPUTERNAME) &middot; $($env:USERNAME)</p>

    <table class="grid"><tr>
        $cardStart
            <div class="title">&#128421; Sistem Operasi</div>
            <div class="big">$winName</div>
            <div class="small">Build $winBuild &middot; $arch</div>
            <div class="small">Edisi $winVer &middot; Instal: $instDate</div>
        $cardEnd
        $cardStart
            <div class="title">&#128187; Perangkat</div>
            <div class="small" style="font-size:13px;color:#1f1f24;">$sysManu $sysModel</div>
            <div class="small">$mbManu $mbProd</div>
        $cardEnd
        $cardStart
            <div class="title">&#11088; Uptime</div>
            <div class="big">$upDays hari</div>
            <div class="small">$upHours jam $upMins menit</div>
            <div class="small">Boot: $bootStr</div>
        $cardEnd
    </tr></table>

    <table class="grid"><tr>
        $cardStart
            <div class="title">&#129504; Prosesor</div>
            <div class="small" style="font-size:13px;color:#1f1f24;">$cpuName</div>
            <div class="small">$cpuCores core / $cpuThreads thread</div>
            <div class="small">$cpuGHz</div>
        $cardEnd
        $cardStart
            <div class="title">&#128267; RAM</div>
            <div class="big">$(To-Gb $ramUsed) / $(To-Gb $ramTotal)</div>
            <div class="small">$ramPct% terpakai &middot; $(To-Gb $ramFree) bebas</div>
        $cardEnd
        $cardStart
            <div class="title">&#127918; GPU</div>
            <table class="spec">$gpuHtml</table>
        $cardEnd
    </tr></table>

    <table class="grid"><tr>
        $cardStart
            <div class="title">&#128190; Penyimpanan</div>
            <table class="spec">
                $diskHtml
            </table>
        $cardEnd
        $cardStart
            <div class="title">&#127760; Jaringan</div>
            <table class="spec">
                <tr><td class="v">$netHtml</td></tr>
            </table>
        $cardEnd
        $cardStart
            <div class="title">&#128241; BIOS</div>
            <div class="small">$biosManu $biosVer</div>
            <div class="small">$biosDate</div>
        $cardEnd
    </tr></table>

    <p class="foot">Klik salah satu menu di sidebar kiri untuk membuka sesi baru.</p>
</body>
</html>
"@
    return $html
}

function New-WelcomeView {
    $wb = [System.Windows.Forms.WebBrowser]::new()
    $wb.Dock = [System.Windows.Forms.DockStyle]::Fill
    $wb.AllowNavigation = $false
    $wb.IsWebBrowserContextMenuEnabled = $false
    $wb.WebBrowserShortcutsEnabled = $false
    $wb.ScriptErrorsSuppressed = $true
    $wb.ScrollBarsEnabled = $false
    $wb.BackColor = [System.Drawing.Color]::FromArgb(230, 230, 235)

    $iconImg = Get-AppIconHtml

    $wb.DocumentText = "<html><body style=`"background:#e6e6eb;font-family:'Segoe UI',Arial,sans-serif;padding:26px;color:#2b2b2b;`"><h1 style=`"font-size:22px;margin:0 0 4px 0;`">$iconImg$text_menu</h1><p style=`"color:#6a6a75;font-size:13px;`">Memuat informasi sistem...</p></body></html>"
    return $wb
}

function Start-WelcomeLoad {
    $uiFile = Join-Path $PSScriptRoot "UI.psm1"
    $job = Start-Job -ArgumentList $uiFile -ScriptBlock {
        param($f)
        try {
            Import-Module $f -Force
            Get-WelcomeHtml
        } catch {
            Write-Output ""
        }
    }
    Set-AppState -Key 'WelcomeJob' -Value $job
}

function New-MenuButton {
    param([string]$Text)
    $btn = [System.Windows.Forms.Button]::new()
    $btn.Text = "  $Text"
    $btn.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $btn.Size = [System.Drawing.Size]::new(205, 34)
    $btn.BackColor = [System.Drawing.Color]::FromArgb(51, 51, 55)
    $btn.ForeColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderSize = 0
    $btn.Font = [System.Drawing.Font]::new("Segoe UI", 9.5)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $btn
}

function New-SessionTab {
    param([string]$Title, [hashtable]$SessionData)
    $panel = [System.Windows.Forms.Panel]::new()
    $panel.Size = [System.Drawing.Size]::new(180, 35)
    $panel.BackColor = [System.Drawing.Color]::FromArgb(200, 202, 210)
    $panel.Cursor = [System.Windows.Forms.Cursors]::Hand
    $panel.Margin = [System.Windows.Forms.Padding]::new(0, 0, 3, 0)
    $panel.Tag = $SessionData

    $indicator = [System.Windows.Forms.Panel]::new()
    $indicator.Height = 3
    $indicator.Dock = [System.Windows.Forms.DockStyle]::Top
    $indicator.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $indicator.Visible = $false
    $indicator.Tag = $SessionData
    $panel.Controls.Add($indicator)

    $lbl = [System.Windows.Forms.Label]::new()
    $lbl.Text = $Title
    $lbl.Font = [System.Drawing.Font]::new("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $lbl.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 85)
    $lbl.Location = [System.Drawing.Point]::new(12, 9)
    $lbl.Size = [System.Drawing.Size]::new(132, 20)
    $lbl.Tag = $SessionData
    $panel.Controls.Add($lbl)

    $btnClose = [System.Windows.Forms.Button]::new()
    $btnClose.Text = "x"
    $btnClose.Font = [System.Drawing.Font]::new("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnClose.Size = [System.Drawing.Size]::new(24, 24)
    $btnClose.Location = [System.Drawing.Point]::new(150, 6)
    $btnClose.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnClose.FlatAppearance.BorderSize = 0
    $btnClose.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(232, 87, 87)
    $btnClose.BackColor = [System.Drawing.Color]::FromArgb(185, 188, 196)
    $btnClose.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 105)
    $btnClose.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(232, 87, 87); $this.ForeColor = [System.Drawing.Color]::White })
    $btnClose.Add_MouseLeave({
        $activeBack = [System.Drawing.Color]::FromArgb(0, 122, 204)
        if ($this.Parent.BackColor -eq $activeBack) {
            $this.BackColor = [System.Drawing.Color]::FromArgb(70, 165, 235)
            $this.ForeColor = [System.Drawing.Color]::White
        } else {
            $this.BackColor = [System.Drawing.Color]::FromArgb(185, 188, 196)
            $this.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 105)
        }
    })
    $btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnClose.Tag = $SessionData
    $panel.Controls.Add($btnClose)

    return @{ Panel = $panel; Label = $lbl; CloseButton = $btnClose; Indicator = $indicator }
}

function New-SessionPanel {
    param([string]$FeatureName, $Fields)

    # Normalize fields: support both legacy string[] and new hashtable[] format
    $normalizedFields = @()
    foreach ($f in $Fields) {
        if ($f -is [string]) {
            $normalizedFields += @{ Name = $f; Type = "Text"; Default = ""; Label = $f; Options = @() }
        } else {
            $normalizedFields += @{
                Name    = $f.Name
                Type    = if ($null -ne $f.Type) { $f.Type } else { "Text" }
                Default = if ($null -ne $f.Default) { $f.Default } else { "" }
                Label   = if ($null -ne $f.Label) { $f.Label } else { $f.Name }
                Options = if ($null -ne $f.Options) { $f.Options } else { @() }
            }
        }
    }

    $mainPanel = [System.Windows.Forms.Panel]::new()
    $mainPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $mainPanel.Visible = $false

    # Output Console
    $outputBox = [System.Windows.Forms.RichTextBox]::new()
    $outputBox.ReadOnly = $true
    $outputBox.Font = [System.Drawing.Font]::new("Consolas", 10)
    $outputBox.BackColor = [System.Drawing.Color]::FromArgb(12, 12, 12)
    $outputBox.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
    $outputBox.Dock = [System.Windows.Forms.DockStyle]::Fill
    $outputBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $outputBox.WordWrap = $false
    $outputBox.Padding = [System.Windows.Forms.Padding]::new(50)
    $outputBox.Text = "[READY] $FeatureName`n"

    # Panel Height: adjust for TextArea fields
    $textAreaCount = @($normalizedFields | Where-Object { $_.Type -eq 'TextArea' }).Count
    $panelHeight = if ($normalizedFields.Count -eq 0) { 110 } else { 90 + ([Math]::Ceiling(($normalizedFields.Count + $textAreaCount * 3) / 2) * 55) }
    $panelInput = [System.Windows.Forms.Panel]::new()
    $panelInput.Height = $panelHeight
    $panelInput.Dock = [System.Windows.Forms.DockStyle]::Top
    $panelInput.BackColor = [System.Drawing.Color]::White
    $panelInput.AutoScroll = $true

    $lblTitle = [System.Windows.Forms.Label]::new()
    $lblTitle.Text = "SESSION: $FeatureName"
    $lblTitle.Font = [System.Drawing.Font]::new("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $lblTitle.Location = [System.Drawing.Point]::new(20, 12)
    $lblTitle.AutoSize = $true
    $panelInput.Controls.Add($lblTitle)

    $btnRun = [System.Windows.Forms.Button]::new()
    $btnRun.Text = $text_btnRun 
    $btnRun.Size = [System.Drawing.Size]::new(100, 32)
    $btnRun.Location = [System.Drawing.Point]::new(20, 44)
    $btnRun.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnRun.ForeColor = [System.Drawing.Color]::White
    $btnRun.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnRun.FlatAppearance.BorderSize = 0
    $btnRun.Font = [System.Drawing.Font]::new("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $btnRun.Cursor = [System.Windows.Forms.Cursors]::Hand
    $panelInput.Controls.Add($btnRun)

    $btnClear = [System.Windows.Forms.Button]::new()
    $btnClear.Text = $text_btnClear
    $btnClear.Size = [System.Drawing.Size]::new(80, 32)
    $btnClear.Location = [System.Drawing.Point]::new(130, 44)
    $btnClear.BackColor = [System.Drawing.Color]::FromArgb(68, 68, 70)
    $btnClear.ForeColor = [System.Drawing.Color]::White
    $btnClear.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnClear.FlatAppearance.BorderSize = 0
    $btnClear.Font = [System.Drawing.Font]::new("Segoe UI", 9)
    $btnClear.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnClear.Tag = @{ Box = $outputBox; Name = $FeatureName }
    $btnClear.Add_Click({
        $data = $this.Tag
        $data.Box.Clear()
        $data.Box.AppendText("[READY] $($data.Name)`n")
    })
    $panelInput.Controls.Add($btnClear)

    $inputControls = @{}
    $colWidth = 340; $colGap = 30; $startX = 20; $startY = 88; $rowHeight = 55
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

    for ($i = 0; $i -lt $normalizedFields.Count; $i++) {
        $field = $normalizedFields[$i]
        $col = $i % 2
        $row = [Math]::Floor($i / 2)
        $x = $startX + ($col * ($colWidth + $colGap))
        $y = $startY + ($row * $rowHeight)

        $lbl = [System.Windows.Forms.Label]::new()
        $lbl.Text = $field.Label
        $lbl.Font = [System.Drawing.Font]::new("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $lbl.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
        $lbl.Location = [System.Drawing.Point]::new($x, $y)
        $lbl.AutoSize = $true
        $panelInput.Controls.Add($lbl)

        $ctrl = $null
        switch ($field.Type) {
            'Combo' {
                $c = [System.Windows.Forms.ComboBox]::new()
                if ($field.Options -and $field.Options.Count -gt 0) {
                    $c.Items.AddRange($field.Options)
                    $c.Text = if ($field.Default) { $field.Default } else { $field.Options[0] }
                } else {
                    $c.Text = if ($field.Default) { $field.Default } else { "" }
                }
                $c.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
                $ctrl = $c
            }
            'TextArea' {
                $tb = [System.Windows.Forms.TextBox]::new()
                $tb.Multiline = $true
                $tb.Height = 50
                $tb.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
                $tb.AcceptsReturn = $true
                $tb.Text = if ($field.Default) { $field.Default } else { "" }
                $ctrl = $tb
            }
            default {
                $tb = [System.Windows.Forms.TextBox]::new()
                $tb.Text = if ($field.Default) { $field.Default } else { "" }
                $ctrl = $tb
            }
        }
        $ctrl.Size = [System.Drawing.Size]::new($colWidth, 26)
        $ctrl.Location = [System.Drawing.Point]::new($x, $y + 18)
        if ($field.Type -eq 'TextArea') { $ctrl.Width = $colWidth * 2 + $colGap; $ctrl.Height = 80 }
        $panelInput.Controls.Add($ctrl)
        $inputControls[$field.Name] = $ctrl
    }

    if ($normalizedFields.Count -eq 0) {
        $lblNoParam = [System.Windows.Forms.Label]::new()
        $lblNoParam.Text = $text_lblNoParam
        $lblNoParam.Font = [System.Drawing.Font]::new("Segoe UI", 9.5, [System.Drawing.FontStyle]::Italic)
        $lblNoParam.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
        $lblNoParam.Location = [System.Drawing.Point]::new(135, 50)
        $lblNoParam.AutoSize = $true
        $panelInput.Controls.Add($lblNoParam)
    }
    
    $separator = [System.Windows.Forms.Panel]::new()
    $separator.Height = 6
    $separator.Dock = [System.Windows.Forms.DockStyle]::Top
    $separator.BackColor = [System.Drawing.Color]::FromArgb(12, 12, 12)

    $mainPanel.Controls.Add($outputBox)
    $mainPanel.Controls.Add($separator)
    $mainPanel.Controls.Add($panelInput)
    
    #$panelInput.BringToFront()

    return @{ MainPanel = $mainPanel; OutputBox = $outputBox; InputControls = $inputControls; BtnRun = $btnRun; BtnClear = $btnClear }
}

Export-ModuleMember -Function New-MainForm, New-MenuPanel, New-MenuHeader, New-MenuScrollPanel, New-RightPanel, New-SessionBar, Update-SessionBarArrows, Set-TabActive, New-ContentPanel, Get-WelcomeHtml, New-WelcomeView, Start-WelcomeLoad, New-MenuButton, New-SessionTab, New-SessionPanel