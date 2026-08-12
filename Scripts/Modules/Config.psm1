<#
.SYNOPSIS
    Configuration module - Environment settings
#>

$script:Config = @{
    Environment = 'Development'  # 'Development' or 'Production'
    Debug       = $true
    LogLevel    = 'DEBUG'        # 'DEBUG', 'INFO', 'WARN', 'ERROR'
}

function Get-Config {
    param([string]$Key)
    return $script:Config[$Key]
}

function Set-Config {
    param([string]$Key, $Value)
    $script:Config[$Key] = $Value
}

function Initialize-Config {
    param(
        [string]$Environment = 'Production'
    )
    $script:Config.Environment = $Environment
    $script:Config.Debug = ($Environment -eq 'Development')
    $script:Config.LogLevel = if ($Environment -eq 'Development') { 'DEBUG' } else { 'ERROR' }
    if ($script:Config.Debug) {
        Write-Host "[CONFIG] Environment: $Environment, Debug: $($script:Config.Debug)"
    }
}

function Write-DebugLog {
    param([string]$Message, [string]$Category = 'GENERAL')
    if ($script:Config.Debug) {
        $timestamp = Get-Date -Format "HH:mm:ss.fff"
        Write-Host "[$timestamp] [DEBUG] [$Category] $Message" -ForegroundColor Gray
    }
}

function Write-InfoLog {
    param([string]$Message, [string]$Category = 'GENERAL')
    if ($script:Config.LogLevel -in @('DEBUG', 'INFO')) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestamp] [INFO] [$Category] $Message" -ForegroundColor Cyan
    }
}

function Write-WarnLog {
    param([string]$Message, [string]$Category = 'GENERAL')
    if ($script:Config.LogLevel -in @('DEBUG', 'INFO', 'WARN')) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestamp] [WARN] [$Category] $Message" -ForegroundColor Yellow
    }
}

function Write-ErrorLog {
    param([string]$Message, [string]$Category = 'GENERAL')
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] [ERROR] [$Category] $Message" -ForegroundColor Red
}

Export-ModuleMember -Function Get-Config, Set-Config, Initialize-Config, Write-DebugLog, Write-InfoLog, Write-WarnLog, Write-ErrorLog