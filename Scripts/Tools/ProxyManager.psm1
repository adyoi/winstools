<#
.SYNOPSIS
    Tool: Proxy Manager
    Dropdown proxy dari free-proxy-list (https://github.com/iplocate/free-proxy-list)
#>

$menuName = "Proxy Manager"
$toolName = "ProxyManager"
$toolCategory = "Network"

$proxyListUrl    = 'https://raw.githubusercontent.com/iplocate/free-proxy-list/refs/heads/main/all-proxies.txt'
$proxyListSource = 'https://github.com/iplocate/free-proxy-list'
$defaultProxy    = 'http://111.111.111.111:8080'

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

function Get-ProxyList {
    $list = @()
    try {
        $resp = Invoke-WebRequest -Uri $proxyListUrl -UseBasicParsing -TimeoutSec 20
        $list = @($resp.Content -split '\r?\n' |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -match '^(\d{1,3}\.){3}\d{1,3}:\d{2,5}$' })
    } catch {
        Write-Output "Gagal mengambil daftar proxy: $_"
    }
    return $list
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
        return @{ Type = "ProxyManager"; SessionData = $sessionData; Controls = $controls }
    }

    $loaded = Update-ProxyCombo $combo
    if ($loaded -gt 0) {
        Write-SessionLog -OutputBox $sessionData.OutputBox -Message "Daftar proxy dimuat ($loaded item) dari $proxyListSource" -Type "INFO"
    } else {
        Write-SessionLog -OutputBox $sessionData.OutputBox -Message "Gagal memuat daftar proxy - memakai default. Coba tombol Refresh." -Type "WARNING"
    }

    $btnRefresh = [System.Windows.Forms.Button]::new()
    $btnRefresh.Text = "Refresh"
    $btnRefresh.Size = [System.Drawing.Size]::new(80, 27)
    $btnRefresh.Location = [System.Drawing.Point]::new($combo.Left + $combo.Width + 8, $combo.Top)
    $btnRefresh.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
    $btnRefresh.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 65)
    $btnRefresh.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnRefresh.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(170, 170, 175)
    $btnRefresh.Font = [System.Drawing.Font]::new("Segoe UI", 9)
    $btnRefresh.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnRefresh.Tag = @{ Combo = $combo; OutputBox = $sessionData.OutputBox }
    $btnRefresh.Add_Click({
        param($s, $e)
        $d = $s.Tag
        $n = Update-ProxyCombo $d.Combo
        if ($n -gt 0) {
            Write-SessionLog -OutputBox $d.OutputBox -Message "Daftar proxy dimuat ulang ($n item) dari $proxyListSource" -Type "SUCCESS"
        } else {
            Write-SessionLog -OutputBox $d.OutputBox -Message "Gagal memuat ulang daftar proxy." -Type "WARNING"
        }
    })
    $controls += $btnRefresh

    $lblSource = [System.Windows.Forms.Label]::new()
    $lblSource.Text = "Sumber daftar proxy: $proxyListSource"
    $lblSource.Location = [System.Drawing.Point]::new($combo.Left, $combo.Top + $combo.Height + 6)
    $lblSource.Size = [System.Drawing.Size]::new(380, 18)
    $lblSource.ForeColor = [System.Drawing.Color]::FromArgb(130, 130, 135)
    $lblSource.Font = [System.Drawing.Font]::new("Segoe UI", 8)
    $controls += $lblSource

    return @{ Type = "ProxyManager"; SessionData = $sessionData; Controls = $controls }
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
        $proxyKey.SetValue("ProxyEnable", 1, [Microsoft.Win32.RegistryValueKind]::DWord)
        $proxyKey.SetValue("ProxyServer", $server, [Microsoft.Win32.RegistryValueKind]::String)
        if (-not [string]::IsNullOrWhiteSpace($override)) {
            $proxyKey.SetValue("ProxyOverride", $override, [Microsoft.Win32.RegistryValueKind]::String)
        }
        Write-Output "Proxy diaktifkan ke server: $server"
    }
    $proxyKey.Close()
}

Export-ModuleMember -Function Get-ToolConfig, Invoke-ToolAction, Get-CustomUI, Get-ProxyList, Update-ProxyCombo