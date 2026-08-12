<#
.SYNOPSIS
    Tool: Disable Services
    Disables selected Windows services matching services.bat
#>

$menuName = "Disable Services"
$toolName = "DisableServices"
$toolCategory = "Maintenance"

$fields = @()

$services = @(
    'DPS','lfsvc','WerSvc','shpamsvc','ssh-agent','DiagTrack','AppVClient','RetailDemo',
    'MapsBroker','XblGameSave','RemoteAccess','tzautoupdate','XboxNetApiSvc','WdiServiceHost',
    'RemoteRegistry','XblAuthManager','UevAgentService','MsKeyboardFilter','dmwappushservice',
    'NetTcpPortSharing','DialogBlockingService'
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

    $disabled = 0
    foreach ($svc in $services) {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if (-not $s) { continue }

        if ($s.StartType -ne 'Disabled') {
            Invoke-Cmd "sc config $svc start= disabled"
        }
        if ($s.Status -ne 'Stopped') {
            Invoke-Cmd "net stop $svc"
        }
        Write-Output "Service dinonaktifkan: $svc"
        $disabled++
    }

    Write-Output "--------------------------------------------"
    if ($disabled -gt 0) {
        Write-Output "$disabled service berhasil dinonaktifkan."
    } else {
        Write-Output "Tidak ada service yang ditemukan/diubah."
    }
}

Export-ModuleMember -Function Get-ToolConfig, Invoke-ToolAction
