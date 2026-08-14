<#
.SYNOPSIS
    Tool: Disk Repair
    Full disk repair suite matching disk.bat
#>

$menuName = "Disk Repair"
$toolName = "DiskManagement"
$toolCategory = "Maintenance"

$fields = @()

function Get-ToolConfig {
    return @{
        MenuName        = $menuName
        ToolName        = $toolName
        Category        = $toolCategory
        Fields          = $fields
        RequiresConfirm = $true
    }
}

function Invoke-ToolAction {
    param($params)

    Write-Output "Memulai System File Checker (SFC)..."
    Invoke-Cmd "sfc /scannow"

    Write-Output "Memulai Check Disk (CHKDSK)..."
    Invoke-Cmd "chkdsk /V"

    Write-Output "Memulai Defragmentasi Disk..."
    Invoke-Cmd "defrag /C /U"

    Write-Output "DISM - CheckHealth..."
    Invoke-Cmd "DISM /Online /Cleanup-Image /CheckHealth"
    Write-Output "DISM - ScanHealth..."
    Invoke-Cmd "DISM /Online /Cleanup-Image /ScanHealth"
    Write-Output "DISM - RestoreHealth..."
    Invoke-Cmd "DISM /Online /Cleanup-Image /RestoreHealth"

    Write-Output "Reset Winsock..."
    Invoke-Cmd "netsh winsock reset"

    Write-Output "Release & Renew IP..."
    Invoke-Cmd "ipconfig /release"
    Invoke-Cmd "ipconfig /renew"

    Write-Output "Perbaikan disk selesai. Restart komputer disarankan."
}

Export-ModuleMember -Function Get-ToolConfig, Invoke-ToolAction
