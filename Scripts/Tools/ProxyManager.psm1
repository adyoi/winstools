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

Export-ModuleMember -Function Get-ToolConfig, Invoke-ToolAction