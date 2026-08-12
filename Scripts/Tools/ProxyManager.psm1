<#
.SYNOPSIS
    Tool: Proxy Manager
#>

$menuName = "Proxy Manager"
$toolName = "ProxyManager"
$toolCategory = "Network"

$fields = @(
    @{ Name = "Action";  Type = "Combo";   Default = "Enable";  Label = "Action";     Options = @("Enable", "Disable") }
    @{ Name = "Server";  Type = "Text";    Default = "http://118.99.96.173:8080"; Label = "Proxy Server" }
    @{ Name = "Override"; Type = "Text";   Default = "<local>"; Label = "Proxy Override" }
)

function Get-ToolConfig {
    return @{
        MenuName    = $menuName
        ToolName    = $toolName
        Category    = $toolCategory
        Fields      = $fields
        RequiresConfirm = $true
    }
}

function Invoke-ToolAction {
    param($params)

    $action = if ($null -ne $params) { $params['Action'] } else { $null }
    $server = if ($null -ne $params) { $params['Server'] } else { $null }
    $override = if ($null -ne $params) { $params['Override'] } else { $null }

    if ([string]::IsNullOrWhiteSpace([string]$action)) {
        $action = 'Enable'
    }

    $actionName = ([string]$action).Trim()
    $serverValue = if ([string]::IsNullOrWhiteSpace([string]$server)) { 'http://118.99.96.173:8080' } else { $server.Trim() }
    $overrideValue = if ($null -eq $override) { '<local>' } else { [string]$override }

    $proxyKey = $null
    try {
        $proxyKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey("Software\Microsoft\Windows\CurrentVersion\Internet Settings")

        if ($actionName -ieq 'Disable') {
            $proxyKey.SetValue('ProxyEnable', 0, [Microsoft.Win32.RegistryValueKind]::DWord)
            $proxyKey.DeleteValue('ProxyServer', $false)
            $proxyKey.DeleteValue('ProxyOverride', $false)
            $proxyKey.DeleteValue('AutoConfigURL', $false)
            $proxyKey.DeleteValue('AutoDetect', $false)
            Write-Output 'Proxy berhasil dinonaktifkan.'
        }
        else {
            if ([string]::IsNullOrWhiteSpace($serverValue)) {
                throw 'Server proxy tidak boleh kosong saat action adalah Enable.'
            }

            $proxyKey.SetValue('ProxyEnable', 1, [Microsoft.Win32.RegistryValueKind]::DWord)
            $proxyKey.SetValue('ProxyServer', $serverValue, [Microsoft.Win32.RegistryValueKind]::String)
            $proxyKey.SetValue('ProxyOverride', $overrideValue, [Microsoft.Win32.RegistryValueKind]::String)
            $proxyKey.DeleteValue('AutoConfigURL', $false)
            $proxyKey.SetValue('AutoDetect', 0, [Microsoft.Win32.RegistryValueKind]::DWord)
            Write-Output "Proxy diaktifkan ke server: $serverValue"
        }
    }
    finally {
        if ($null -ne $proxyKey) {
            $proxyKey.Close()
        }
    }
}

Export-ModuleMember -Function Get-ToolConfig, Invoke-ToolAction