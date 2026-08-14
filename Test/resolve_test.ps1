$ErrorActionPreference = 'Continue'
Import-Module 'D:\Documents\winstools\Scripts\Modules\Config.psm1' -Force
Initialize-Config -Environment 'Production' | Out-Null
Import-Module 'D:\Documents\winstools\Scripts\Modules\Options.psm1' -Force

Write-Host "=== Dari scope global ==="
Write-Host ("Get-Command Initialize-Config: " + [bool](Get-Command Initialize-Config -ErrorAction SilentlyContinue))

Write-Host "=== Dari dalam scope modul Options (simulasi handler) ==="
& (Get-Module Options) {
    $init = Get-Command Initialize-Config -ErrorAction Stop
    Write-Host ("resolved: " + $init.Name)
    & $init -Environment 'Development' -Debug:$true -LogLevel 'DEBUG'
}
Write-Host ("Config now: Env=" + (Get-Config -Key Environment) + " Debug=" + (Get-Config -Key Debug) + " Log=" + (Get-Config -Key LogLevel))
