<#
.SYNOPSIS
    Tool: God Mode
    Windows Settings shortcuts + God Mode matching settings.bat
#>

$menuName = "God Mode"
$toolName = "GodMode"
$toolCategory = "Customization"

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

$fields = @(
    @{ Name = "Location"; Type = "Text"; Default = $scriptDir; Label = "Folder Location" }
)

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

    $basePath = if ($params['Location']) { $params['Location'] } else { $scriptDir }
    if (-not $basePath) { $basePath = (Get-Location).Path }
    if (-not [System.IO.Directory]::Exists($basePath)) { [System.IO.Directory]::CreateDirectory($basePath) | Out-Null }

    # Windows Settings shortcuts (.msc + .cpl) matching settings.bat
    $winX = Join-Path $basePath "Windowx"
    if (-not [System.IO.Directory]::Exists($winX)) { [System.IO.Directory]::CreateDirectory($winX) | Out-Null }

    $sys32 = Join-Path $env:WINDIR "System32"
    foreach ($ext in @('msc', 'cpl')) {
        $files = @(Get-ChildItem $sys32 -Filter "*.$ext" -ErrorAction SilentlyContinue)
        foreach ($f in $files) {
            $link = Join-Path $winX $f.Name
            if (-not (Test-Path $link)) {
                Invoke-Cmd "mklink `"$link`" `"$($f.FullName)`""
            }
        }
    }

    # God Mode folder
    $path = [System.IO.Path]::Combine($basePath, "GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}")
    [System.IO.Directory]::CreateDirectory($path) | Out-Null

    Start-Process explorer.exe -ArgumentList $winX
    Write-Output "Shortcut Windows Settings ($($winX)) dibuat:"
    Write-Output "  - $(@(Get-ChildItem $winX -Filter '*.msc' -ErrorAction SilentlyContinue).Count) shortcut .msc"
    Write-Output "  - $(@(Get-ChildItem $winX -Filter '*.cpl' -ErrorAction SilentlyContinue).Count) shortcut .cpl"
    Write-Output "God Mode dibuat di: $path"
}

Export-ModuleMember -Function Get-ToolConfig, Invoke-ToolAction
