<#
.SYNOPSIS
    Tool: Clear DNS
    Full DNS/network reset matching cleardns.bat + custom static DNS
#>

$menuName = "Clear DNS"
$toolName = "ClearDNS"
$toolCategory = "Network"

$fields = @(
    @{ Name = "Primary";      Type = "Text";    Default = "1.1.1.1";     Label = "Primary DNS" }
    @{ Name = "Secondary";    Type = "Text";    Default = "1.0.0.1";     Label = "Secondary DNS" }
    @{ Name = "Interface";    Type = "Combo";   Default = "";            Label = "Interface"; Options = @() }
)

function Get-ToolConfig {
    return @{
        MenuName    = $menuName
        ToolName    = $toolName
        Category    = $toolCategory
        Fields          = $fields
        RequiresConfirm = $true
        CustomUI        = $true
        HasCustomPanel = $true
    }
}

function Get-NetworkAdapters {
    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' -or $_.Status -eq 'Disconnected' } | Select-Object -ExpandProperty Name
    if (-not $adapters) {
        $adapters = @("Wi-Fi", "Ethernet")
    }
    return $adapters
}

function Get-CustomUI {
    param($sessionData)

    # Populate Interface ComboBox with detected network adapters
    $combo = $sessionData.Inputs['Interface']
    if ($combo) {
        $adapters = Get-NetworkAdapters
        $combo.Items.Clear()
        if ($adapters) { $combo.Items.AddRange([string[]]$adapters) }
        $preferred = $adapters | Where-Object { $_ -like "*Wi-Fi*" -or $_ -like "*Wireless*" } | Select-Object -First 1
        if (-not $preferred) { $preferred = $adapters | Select-Object -First 1 }
        if ($preferred) { $combo.Text = [string]$preferred }
    }

    # Refresh button (beside the Interface ComboBox)
    $btnRefresh = [System.Windows.Forms.Button]::new()
    $btnRefresh.Text = "Refresh"
    $btnRefresh.Size = [System.Drawing.Size]::new(80, 27)
    $btnRefresh.Location = [System.Drawing.Point]::new(368, 161)
    $btnRefresh.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
    $btnRefresh.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 65)
    $btnRefresh.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnRefresh.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(170, 170, 175)
    $btnRefresh.Font = [System.Drawing.Font]::new("Segoe UI", 9)
    $btnRefresh.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnRefresh.Tag = $sessionData
    $btnRefresh.Add_Click({
        param($s, $e)
        $sess = $s.Tag
        $cbo = $sess.Inputs['Interface']
        if (-not $cbo) { return }
        $adps = Get-NetworkAdapters
        $cbo.Items.Clear()
        if ($adps) { $cbo.Items.AddRange([string[]]$adps) }
        $pref = $adps | Where-Object { $_ -like "*Wi-Fi*" -or $_ -like "*Wireless*" } | Select-Object -First 1
        if (-not $pref) { $pref = $adps | Select-Object -First 1 }
        if ($pref) { $cbo.Text = [string]$pref }
    })

    return @{
        Type = "ClearDNS"
        SessionData = $sessionData
        Controls = @($btnRefresh)
    }
}

function Invoke-ToolAction {
    param($params)

    $dns1 = $params['Primary']
    $dns2 = $params['Secondary']
    $iface = $params['Interface']

    Write-Output "Memeriksa interface jaringan..."
    Invoke-Cmd "netsh interface show interface"

    # Release / Renew (matching cleardns.bat)
    Write-Output "Melepas koneksi jaringan (release)..."
    Invoke-Cmd "ipconfig /release"
    Start-Sleep -Seconds 2
    Write-Output "Memperbarui koneksi jaringan (renew)..."
    Invoke-Cmd "ipconfig /renew"
    Start-Sleep -Seconds 2

    # Flush DNS
    Invoke-Cmd "ipconfig /flushdns"

    # Set DNS
    if (-not [string]::IsNullOrWhiteSpace($iface) -and -not [string]::IsNullOrWhiteSpace($dns1)) {
        Write-Output "Mengatur DNS statis pada interface $iface ..."
        Invoke-Cmd "netsh interface IPv4 set dnsserver `"$iface`" static $dns1 primary"
        if ($dns2 -and $dns2 -ne "None") {
            Invoke-Cmd "netsh interface IPv4 add dnsserver `"$iface`" address=$dns2 index=2"
        }
    } else {
        Write-Output "Mengembalikan DNS ke DHCP (reset)..."
        if (-not [string]::IsNullOrWhiteSpace($iface)) {
            Invoke-Cmd "netsh interface IPv4 set dnsserver `"$iface`" dhcp"
            Invoke-Cmd "netsh interface IPv6 set dnsserver `"$iface`" dhcp"
        }
    }
    Invoke-Cmd "ipconfig /flushdns"

    # Reset Winsock + TCP/IP stack (matching cleardns.bat)
    Write-Output "Merestart Winsock dan TCP/IP..."
    Invoke-Cmd "netsh winsock reset"
    Invoke-Cmd "netsh winsock reset catalog"
    Invoke-Cmd "netsh int ip reset all"
    Invoke-Cmd "netsh int ip reset resetlog.txt"
    Invoke-Cmd "netsh winhttp reset proxy"
    Invoke-Cmd "ipconfig /flushdns"

    Write-Output "DNS dan jaringan berhasil direset. Restart komputer disarankan agar perubahan diterapkan."
}

Export-ModuleMember -Function Get-ToolConfig, Invoke-ToolAction, Get-CustomUI, Get-NetworkAdapters
