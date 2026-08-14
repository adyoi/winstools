<#
.SYNOPSIS
    Tool: Proxy Manager
    Dropdown proxy dari free-proxy-list (https://github.com/iplocate/free-proxy-list)
    Daftar proxy TIDAK diunduh otomatis saat sesi dibuka (hindari UI freeze & gagal karena file besar).
    Klik tombol Load -> unduh async (runspace) dengan progress bar.
    Jika unduhan terpotong di tengah (Truncated), data parsial yang sudah turun tetap dipakai, bukan gagal total.
#>

$menuName = "Proxy Manager"
$toolName = "ProxyManagement"
$toolCategory = "Network"

$proxyListUrl    = 'https://raw.githubusercontent.com/iplocate/free-proxy-list/refs/heads/main/all-proxies.txt'
$proxyListSource = 'https://github.com/iplocate/free-proxy-list'
$defaultProxy    = '111.111.111.111:8080'

$fields = @(
    @{ Name = "Action";   Type = "Combo";   Default = "Enable";  Label = "Action";     Options = @("Enable", "Disable") }
    @{ Name = "Server";   Type = "Combo";   Default = "";        Label = "Proxy Server"; Options = @() }
    @{ Name = "Override"; Type = "Text";    Default = "<local>"; Label = "Proxy Override" }
)

function Get-ToolConfig {
    return @{
        MenuName        = $menuName
        ToolName        = $toolName
        Category        = $toolCategory
        Fields          = $fields
        RequiresConfirm = $true
        CustomUI        = $true
        HasCustomPanel  = $true
    }
}

function Test-ProxyFormat {
    param([string]$Proxy)
    if ([string]::IsNullOrWhiteSpace($Proxy)) { return $false }
    $bare = $Proxy -replace '^https?://', ''
    return ($bare -match '^(\d{1,3}\.){3}\d{1,3}:\d{2,5}$')
}

function ConvertTo-ProxyList {
    param([string]$Content)
    return @($Content -split '\r?\n' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -match '^(https?://)?(\d{1,3}\.){3}\d{1,3}:\d{2,5}$' })
}

<#
.SYNOPSIS
    Unduh daftar proxy secara streaming. Mengembalikan hashtable:
    @{ Content; Truncated; Total; Received }
    Jika koneksi putus di tengah unduhan (Truncated = $true), data yang sudah ter-download tetap dikembalikan
    sehingga caller dapat memakai daftar parsial, bukan gagal total.
.PARAMETER ProgressCallback
    scriptblock opsional dengan parameter ($Bytes, $Total, $Percent). Percent -1 = ukuran total tidak diketahui.
#>
function Get-ProxyListStream {
    param(
        [string]$Url = $proxyListUrl,
        [scriptblock]$ProgressCallback = $null
    )
    $result = @{ Content = ''; Truncated = $false; Total = 0; Received = 0 }
    try {
        $req = [System.Net.HttpWebRequest]::Create($Url)
        $req.Method = 'GET'
        $req.UserAgent = 'Mozilla/5.0 (compatible; Winstools/1.0)'
        $req.Timeout = 30000
        $req.ReadWriteTimeout = 30000
        $resp = $req.GetResponse()
        try {
            $total = $resp.ContentLength
            $result.Total = $total
            $stream = $resp.GetResponseStream()
            try {
                $buffer = New-Object byte[] 16384
                $ms = New-Object System.IO.MemoryStream
                try {
                    while ($true) {
                        $read = $stream.Read($buffer, 0, $buffer.Length)
                        if ($read -le 0) { break }
                        $ms.Write($buffer, 0, $read)
                        $result.Received += $read
                        if ($ProgressCallback) {
                            $pct = if ($total -gt 0) { [Math]::Min(100, [int](($result.Received * 100) / $total)) } else { -1 }
                            & $ProgressCallback -Bytes $result.Received -Total $total -Percent $pct
                        }
                    }
                } catch {
                    $result.Truncated = $true
                }
                $result.Content = [System.Text.Encoding]::UTF8.GetString($ms.ToArray())
                $ms.Dispose()
            } finally {
                $stream.Dispose()
            }
        } finally {
            $resp.Dispose()
        }
    } catch {
        $result.Truncated = $true
    }
    return $result
}

function Get-ProxyList {
    $streamResult = Get-ProxyListStream
    return ConvertTo-ProxyList $streamResult.Content
}

function Update-ProxyCombo {
    param($Combo)
    $list = Get-ProxyList
    $Combo.Items.Clear()
    if ($list.Count -gt 0) {
        $Combo.Items.AddRange([string[]]$list)
    } else {
        $Combo.Items.AddRange([string[]]@($defaultProxy))
    }
    if ([string]::IsNullOrEmpty($Combo.Text) -and $Combo.Items.Count -gt 0) {
        $Combo.Text = [string]$Combo.Items[0]
    }
    return $list.Count
}

function Get-CustomUI {
    param($sessionData)

    $controls = @()
    $combo = $sessionData.Inputs['Server']
    if (-not $combo) {
        return @{ Type = "ProxyManagement"; SessionData = $sessionData; Controls = $controls }
    }

    # Tidak ada unduhan otomatis di sini (file bisa besar -> gagal/UI freeze).
    $combo.Text = $defaultProxy

    $btnLoad = [System.Windows.Forms.Button]::new()
    $btnLoad.Text = "Load"
    $btnLoad.Size = [System.Drawing.Size]::new(80, 27)
    $btnLoad.Location = [System.Drawing.Point]::new($combo.Left + $combo.Width + 8, $combo.Top)
    $btnLoad.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
    $btnLoad.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 65)
    $btnLoad.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnLoad.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(170, 170, 175)
    $btnLoad.Font = [System.Drawing.Font]::new("Segoe UI", 9)
    $btnLoad.Cursor = [System.Windows.Forms.Cursors]::Hand

    $progressBar = [System.Windows.Forms.ProgressBar]::new()
    $progressBar.Size = [System.Drawing.Size]::new($combo.Width, 15)
    $progressBar.Location = [System.Drawing.Point]::new($combo.Left, $combo.Top + $combo.Height + 6)
    $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
    $progressBar.Visible = $false

    $uiFile = Join-Path $PSScriptRoot "ProxyManagement.psm1"
    $d = @{
        Combo       = $combo
        OutputBox   = $sessionData.OutputBox
        BtnLoad     = $btnLoad
        ProgressBar = $progressBar
        UiFile      = $uiFile
        Ps          = $null
        Async       = $null
        State       = $null
        Timer       = $null
    }
    $btnLoad.Tag = $d

    $btnLoad.Add_Click({
        param($s, $e)
        $d = $s.Tag
        if ($d.Async -and -not $d.Async.IsCompleted) {
            Write-SessionLog -OutputBox $d.OutputBox -Message "Unduhan masih berjalan. Tunggu hingga selesai." -Type "WARNING"
            return
        }

        $d.BtnLoad.Enabled = $false
        $d.BtnLoad.Text = "Loading..."
        $d.ProgressBar.Visible = $true
        $d.ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
        $d.ProgressBar.Value = 0
        Write-SessionLog -OutputBox $d.OutputBox -Message "Mengunduh daftar proxy dari $proxyListSource ..." -Type "INFO"

        $state = [hashtable]::Synchronized(@{
            Progress = -1; Received = 0; Total = 0; Truncated = $false; Items = @(); Done = $false
        })
        $d.State = $state

        $ps = [System.Management.Automation.PowerShell]::Create()
        $d.Ps = $ps
        $script = "param(`$Url, `$Mod, `$State)
Import-Module -Name `$Mod -Force
`$r = Get-ProxyListStream -Url `$Url -ProgressCallback { param(`$Bytes, `$Total, `$Percent)
    `$State.Progress = `$Percent; `$State.Received = `$Bytes; `$State.Total = `$Total
}
`$State.Truncated = `$r.Truncated
`$State.Items = @(ConvertTo-ProxyList `$r.Content)
`$State.Done = `$true"
        $null = $ps.AddScript($script).AddArgument($proxyListUrl).AddArgument($d.UiFile).AddArgument($state)
        $d.Async = $ps.BeginInvoke()

        $timer = [System.Windows.Forms.Timer]::new()
        $timer.Interval = 100
        $d.Timer = $timer
        $timer.Add_Tick({
            $st = $d.State
            if (-not $st) { return }
            if ($st.Progress -ge 0) {
                $d.ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
                $d.ProgressBar.Value = $st.Progress
            } else {
                $d.ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
            }
            if (-not $st.Done) { return }

            $timer.Stop()
            $d.ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
            $d.ProgressBar.Value = 100
            $d.BtnLoad.Enabled = $true
            $d.BtnLoad.Text = "Load"

            $combo = $d.Combo
            $combo.Items.Clear()
            if ($st.Items.Count -gt 0) {
                $combo.Items.AddRange([string[]]$st.Items)
                $combo.Text = [string]$st.Items[0]
                $msg = "Daftar proxy dimuat ($($st.Items.Count) item)"
                if ($st.Truncated) { $msg += " (unduhan terpotong - data parsial)" }
                Write-SessionLog -OutputBox $d.OutputBox -Message "$msg dari $proxyListSource" -Type $(if ($st.Truncated) { 'WARNING' } else { 'SUCCESS' })
            } else {
                $combo.Items.AddRange([string[]]@($defaultProxy))
                $combo.Text = $defaultProxy
                Write-SessionLog -OutputBox $d.OutputBox -Message "Tidak ada proxy valid yang diperoleh (unduhan gagal/terpotong). Memakai default." -Type "WARNING"
            }

            if ($d.Async) {
                try { $d.Async.AsyncWaitHandle.WaitOne(500) | Out-Null } catch {}
                $d.Ps.Dispose()
            }
            $d.Async = $null
            $d.Ps = $null
            $d.State = $null
            $d.Timer = $null
            $timer.Dispose()
        })
        $timer.Start()
    })
    $controls += $btnLoad
    $controls += $progressBar

    $lblSource = [System.Windows.Forms.Label]::new()
    $lblSource.Text = "Sumber daftar proxy: $proxyListSource"
    $lblSource.Location = [System.Drawing.Point]::new($combo.Left, $combo.Top + $combo.Height + 25)
    $lblSource.Size = [System.Drawing.Size]::new(500, 18)
    $lblSource.ForeColor = [System.Drawing.Color]::FromArgb(130, 130, 135)
    $lblSource.Font = [System.Drawing.Font]::new("Segoe UI", 8)
    $controls += $lblSource

    return @{ Type = "ProxyManagement"; SessionData = $sessionData; Controls = $controls }
}

function Invoke-ToolAction {
    param($params)

    $action = $params['Action']
    $server = $params['Server']
    $override = $params['Override']
    $proxyKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey("Software\Microsoft\Windows\CurrentVersion\Internet Settings")
    if ($action -eq "Disable") {
        $proxyKey.SetValue("ProxyEnable", 0, [Microsoft.Win32.RegistryValueKind]::DWord)
        $proxyKey.DeleteValue("ProxyServer", $false)
        $proxyKey.DeleteValue("ProxyOverride", $false)
        Write-Output "Proxy berhasil dinonaktifkan."
    } else {
        if (-not (Test-ProxyFormat $server)) {
            Write-Output "Format proxy tidak valid: '$server'. Gunakan host:port (mis. 111.111.111.111:8080) atau http://host:port."
            $proxyKey.Close()
            return
        }
        $serverBare = $server -replace '^https?://', ''
        $proxyKey.SetValue("ProxyEnable", 1, [Microsoft.Win32.RegistryValueKind]::DWord)
        $proxyKey.SetValue("ProxyServer", $serverBare, [Microsoft.Win32.RegistryValueKind]::String)
        if (-not [string]::IsNullOrWhiteSpace($override)) {
            $proxyKey.SetValue("ProxyOverride", $override, [Microsoft.Win32.RegistryValueKind]::String)
        }
        Write-Output "Proxy diaktifkan ke server: $serverBare"
    }
    $proxyKey.Close()
}

Export-ModuleMember -Function Get-ToolConfig, Invoke-ToolAction, Get-CustomUI, Get-ProxyList, Get-ProxyListStream, ConvertTo-ProxyList, Test-ProxyFormat, Update-ProxyCombo
