<#
.SYNOPSIS
    Tool: Event Log
#>

$menuName = "Event Log"
$toolName = "EventLog"
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

    Write-Output "Membersihkan Event Logs Windows..."
    Invoke-Cmd "@echo off & net stop EventLog /yes"
    Remove-Item -Path "$env:SystemRoot\System32\Winevt\Logs\*.evt" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:SystemRoot\System32\Winevt\Logs\*.evtl" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:SystemRoot\System32\Winevt\Logs\*.evtx" -Force -ErrorAction SilentlyContinue
    Invoke-Cmd "cd `"%SystemRoot%\System32\Winevt\Logs`""
    Invoke-Cmd "for /f %x in ('where *.evt') do @echo. > `"%x`""
    Invoke-Cmd "for /f %x in ('where *.evtl') do @echo. > `"%x`""
    Invoke-Cmd "for /f %x in ('where *.evtx') do @echo. > `"%x`""
    Invoke-Cmd "net start EventLog"
    Invoke-Cmd "@echo off & for /f %x in ('wevtutil el') do (wevtutil cl `"%x`" >nul 2>&1 & echo Clear %x)"
    Write-Output "Event Log dibersihkan."
}

Export-ModuleMember -Function Get-ToolConfig, Invoke-ToolAction