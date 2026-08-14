<#
.SYNOPSIS
    Configuration module - Environment settings (persisted ke config.json)

    Nilai konfigurasi disimpan di:
        %LOCALAPPDATA%\Winstools\config.json
    sehingga aplikasi memuat nilai yang sama setiap kali dijalankan (bukan default).
#>

$script:Config = @{
    Environment = 'Production'  # 'Development' or 'Production'
    Debug       = $false
    LogLevel    = 'ERROR'       # 'DEBUG', 'INFO', 'WARN', 'ERROR'
}

$script:ConfigFile = Join-Path $env:LOCALAPPDATA "Winstools\config.json"

function Save-ConfigFile {
    $dir = Split-Path $script:ConfigFile -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [ordered]@{
        Environment = $script:Config.Environment
        Debug       = [bool]$script:Config.Debug
        LogLevel    = $script:Config.LogLevel
    } | ConvertTo-Json | Set-Content -LiteralPath $script:ConfigFile -Encoding UTF8
}

function Get-ConfigPath {
    return $script:ConfigFile
}

function Get-Config {
    param([string]$Key)
    return $script:Config[$Key]
}

function Set-Config {
    param([string]$Key, $Value)
    $script:Config[$Key] = $Value
    Save-ConfigFile
}

function Initialize-Config {
    param(
        [string]$Environment = 'Production',
        [switch]$Debug,
        [ValidateSet('DEBUG','INFO','WARN','ERROR')][string]$LogLevel,
        [string]$ConfigPath
    )
    if ($ConfigPath) { $script:ConfigFile = $ConfigPath }

    # 1) Muat nilai dari file (jika sudah ada) sebagai nilai awal.
    $fileEnv   = $null
    $fileDebug = $null
    $fileLog   = $null
    if (Test-Path $script:ConfigFile) {
        try {
            $data = Get-Content -LiteralPath $script:ConfigFile -Raw | ConvertFrom-Json
            if ($data.Environment) { $fileEnv = [string]$data.Environment }
            if ($null -ne $data.Debug) { $fileDebug = [bool]$data.Debug }
            if ($data.LogLevel) { $fileLog = [string]$data.LogLevel }
        } catch {
            # file rusak -> abaikan, pakai default
        }
    }

    # 2) Parameter eksplisit menimpa file; sisanya memakai nilai file (atau default).
    $envVal = if ($PSBoundParameters.ContainsKey('Environment')) { $Environment }
              elseif ($fileEnv) { $fileEnv } else { 'Production' }
    $dev = ($envVal -eq 'Development')
    $dbgVal = if ($PSBoundParameters.ContainsKey('Debug')) { [bool]$Debug }
              elseif ($null -ne $fileDebug) { $fileDebug } else { $dev }
    $logVal = if ($PSBoundParameters.ContainsKey('LogLevel')) { $LogLevel }
              elseif ($fileLog) { $fileLog } else { if ($dev) { 'DEBUG' } else { 'ERROR' } }
    if ($logVal -notin @('DEBUG','INFO','WARN','ERROR')) { $logVal = if ($dev) { 'DEBUG' } else { 'ERROR' } }

    $script:Config.Environment = $envVal
    $script:Config.Debug = $dbgVal
    $script:Config.LogLevel = $logVal

    # 3) Simpan (buat file pada run pertama / perbarui setelah perubahan).
    Save-ConfigFile

    if ($script:Config.Debug) {
        Write-Host "[CONFIG] Environment: $envVal, Debug: $($script:Config.Debug), LogLevel: $($script:Config.LogLevel)"
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

Export-ModuleMember -Function Get-Config, Set-Config, Initialize-Config, Get-ConfigPath, Write-DebugLog, Write-InfoLog, Write-WarnLog, Write-ErrorLog
