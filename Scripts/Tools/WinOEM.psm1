<#
.SYNOPSIS
    Tool: Set OEM
#>

$menuName = "Win OEM"
$toolName = "WinOEM"
$toolCategory = "Customization"

# Root aplikasi: source = winstools\; EXE terinstal = folder exe (Icons di samping Tools)
$oemRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not (Test-Path (Join-Path $oemRoot "Icons"))) { $oemRoot = Split-Path $PSScriptRoot -Parent }
$oemLogo = Join-Path $oemRoot "Icons\winstools.bmp"

$fields = @(
    @{ Name = "Manufacturer";   Type = "Text";    Default = "Winstools";             Label = "Manufacturer" }
    @{ Name = "Model";          Type = "Text";    Default = "Winstools";             Label = "Model" }
    @{ Name = "SupportHours";   Type = "Text";    Default = "24/7";                  Label = "Support Hours" }
    @{ Name = "SupportPhone";   Type = "Text";    Default = "021-021-021";           Label = "Support Phone" }
    @{ Name = "SupportURL";     Type = "Text";    Default = "https://support.local"; Label = "Support URL" }
    @{ Name = "Owner";          Type = "Text";    Default = "Winstools";             Label = "Registered Owner" }
    @{ Name = "Org";            Type = "Text";    Default = "Winstools";             Label = "Organization" }
    @{ Name = "Logo";           Type = "Text";    Default = $oemLogo;                Label = "OEM Logo Path" }
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

    $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"
    if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
    if ($params['Manufacturer']) { Set-ItemProperty $path "Manufacturer" $params['Manufacturer'] }
    if ($params['Model']) { Set-ItemProperty $path "Model" $params['Model'] }
    if ($params['SupportHours']) { Set-ItemProperty $path "SupportHours" $params['SupportHours'] }
    if ($params['SupportPhone']) { Set-ItemProperty $path "SupportPhone" $params['SupportPhone'] }
    if ($params['SupportURL']) { Set-ItemProperty $path "SupportURL" $params['SupportURL'] }
    if ($params['Logo']) { Set-ItemProperty $path "Logo" $params['Logo'] }
    $regPathNT = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    if ($params['Owner']) { Set-ItemProperty $regPathNT "RegisteredOwner" $params['Owner'] }
    if ($params['Org']) { Set-ItemProperty $regPathNT "RegisteredOrganization" $params['Org'] }
    Write-Output "Informasi OEM berhasil diperbarui di Registry."
}

Export-ModuleMember -Function Get-ToolConfig, Invoke-ToolAction