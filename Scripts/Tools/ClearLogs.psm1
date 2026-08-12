<#
.SYNOPSIS
    Tool: Clear Logs
#>

$menuName = "Clear Logs"
$toolName = "ClearLogs"
$toolCategory = "Maintenance"

$fields = @()

function Get-ToolConfig {
    return @{
        MenuName    = $menuName
        ToolName    = $toolName
        Category    = $toolCategory
        Fields      = $fields
    }
}

function Invoke-ToolAction {
    param($params)

    Write-Output "Membersihkan Temp, Prefetch, dan Logs sistem..."
    Invoke-Cmd "auditpol /clear /y"
    $paths = @(
        "$env:Temp\*.*",
        "$env:LocalAppData\Temp\*.*",
        "$env:WinDir\Prefetch\*.*",
        "$env:WinDir\Temp\*.*",
        "$env:WinDir\Logs\*.*",
        "$env:AppData\Temp\*.*",
        "$env:SystemDrive\*.bak",
        "$env:SystemDrive\*.log"
    )
    foreach ($path in $paths) {
        # Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        Invoke-Cmd "del /f /q /s $path"
    }
    Write-Output "File sampah dan log berhasil dibersihkan."
}

Export-ModuleMember -Function Get-ToolConfig, Invoke-ToolAction