<#
.SYNOPSIS
    Features Module - Dynamic tool loading from tools directory
#>

function Get-Features {
    $toolsPath = Join-Path (Split-Path $PSScriptRoot -Parent) "tools"
    $features = @()

    if (-not (Test-Path $toolsPath)) {
        Write-WarnLog "tools directory not found: $toolsPath" -Category 'FEATURES'
        return $features
    }

    $toolFiles = Get-ChildItem -Path $toolsPath -Filter "*.psm1" | Sort-Object Name

    foreach ($file in $toolFiles) {
        try {
            $toolModule = Import-Module $file.FullName -PassThru -Force -ErrorAction Stop
            if ($toolModule -and $toolModule.ExportedCommands.ContainsKey('Get-ToolConfig')) {
                $getConfig = $toolModule.ExportedCommands['Get-ToolConfig']
                $config = & $getConfig
                if ($config) {
                    $features += @{
                        Name        = $config.MenuName
                        ToolName    = $config.ToolName
                        Category    = $config.Category
                        Fields      = $config.Fields
                        HasCustomUI = $config.CustomUI
                        Module      = $toolModule
                        ModulePath  = $toolModule.Path
                        Action      = {
                            param($modulePath, $p)
                            $scriptsDir = Split-Path (Split-Path $modulePath -Parent) -Parent
                            Import-Module (Join-Path $scriptsDir "Modules\Features.psm1") -Force
                            $m = Import-Module $modulePath -PassThru -Force
                            $invoke = $m.ExportedCommands['Invoke-ToolAction']
                            & $invoke $p
                        }
                    }
                    Write-DebugLog "Loaded tool: $($config.MenuName) ($($config.ToolName))" -Category 'FEATURES'
                }
            }
        } catch {
            Write-ErrorLog "Failed to load tool $($file.Name): $_" -Category 'FEATURES'
        }
    }

    return $features
}

function Get-ToolModule {
    param([string]$ToolName)
    $toolsPath = Join-Path (Split-Path $PSScriptRoot -Parent) "tools"
    $file = Get-ChildItem -Path $toolsPath -Filter "$ToolName.psm1" | Select-Object -First 1
    if ($file) {
        return Import-Module $file.FullName -PassThru -Force
    }
    return $null
}

function Invoke-Cmd {
    param([string]$cmd)
    Write-Output "C:\> $cmd"
    & cmd.exe /c $cmd 2>&1
}

Export-ModuleMember -Function Get-Features, Get-ToolModule, Invoke-Cmd