<#
.SYNOPSIS
    Tool: Win Update Reset
    Full Windows Update reset matching windows-update.bat
#>

$menuName = "Win Update Reset"
$toolName = "WinUpdateReset"
$toolCategory = "Maintenance"

$fields = @(
    @{ Name = "Restart"; Type = "Combo"; Default = "No"; Label = "Restart After"; Options = @("No", "Yes") }
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

function Stop-ServiceRetry {
    param([string]$Name, [int]$Attempts = 3)
    for ($i = 1; $i -le $Attempts; $i++) {
        net stop $Name 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq 'Stopped') { return $true }
    }
    return $false
}

function Rename-Component {
    param([string]$Path)
    if (Test-Path "$Path.bak") {
        Remove-Item "$Path.bak" -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $Path) {
        Invoke-Cmd "attrib -r -s -h /s /d `"$Path`""
        Invoke-Cmd "ren `"$Path`" $([System.IO.Path]::GetFileName($Path)).bak"
        Write-Output "Component di-rename: $Path -> $([System.IO.Path]::GetFileName($Path)).bak"
    }
}

function Invoke-ToolAction {
    param($params)

    $restart = $params['Restart']
    $sysRoot = $env:SYSTEMROOT

    Write-Output "Reset Windows Update dimulai..."

    # 1) Stop services (with retry like the .bat)
    foreach ($svc in @('bits', 'wuauserv', 'cryptsvc')) {
        Write-Output "Menghentikan service $svc ..."
        if (-not (Stop-ServiceRetry $svc)) {
            Write-Output "Gagal menghentikan service $svc setelah 3 percobaan. Restart komputer lalu coba lagi."
            return
        }
    }

    # 2) Flush DNS + delete update cache files
    Invoke-Cmd "ipconfig /flushdns"
    Invoke-Cmd "del /s /q /f `"$env:ALLUSERSPROFILE\Application Data\Microsoft\Network\Downloader\qmgr*.dat`""
    Invoke-Cmd "del /s /q /f `"$env:ALLUSERSPROFILE\Microsoft\Network\Downloader\qmgr*.dat`""
    Invoke-Cmd "del /s /q /f `"$sysRoot\Logs\WindowsUpdate\*`""

    # 3) pending.xml
    $pendingXml = "$sysRoot\winsxs\pending.xml"
    if (Test-Path "$pendingXml.bak") { Remove-Item "$pendingXml.bak" -Force -ErrorAction SilentlyContinue }
    if (Test-Path $pendingXml) {
        Invoke-Cmd "takeown /f `"$pendingXml`""
        Invoke-Cmd "attrib -r -s -h /s /d `"$pendingXml`""
        Invoke-Cmd "ren `"$pendingXml`" pending.xml.bak"
    }

    # 4) Rename update store components to .bak
    Rename-Component "$sysRoot\SoftwareDistribution\DataStore"
    Rename-Component "$sysRoot\SoftwareDistribution\Download"
    Rename-Component "$sysRoot\system32\Catroot2"

    # 5) Reset Windows Update policies
    Write-Output "Menghapus kebijakan (policy) Windows Update..."
    Invoke-Cmd 'reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f'
    Invoke-Cmd 'reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\WindowsUpdate" /f'
    Invoke-Cmd 'reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f'
    Invoke-Cmd 'reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\WindowsUpdate" /f'
    Invoke-Cmd "gpupdate /force"

    # 6) Reset service security descriptors
    Write-Output "Merestore security descriptor service..."
    Invoke-Cmd 'sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)'
    Invoke-Cmd 'sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)'

    # 7) Re-register Windows Update DLLs (single cmd, matching windows-update.bat)
    Write-Output "Mendaftarkan ulang komponen Windows Update (regsvr32)..."
    $dlls = @(
        'atl.dll','urlmon.dll','mshtml.dll','shdocvw.dll','browseui.dll','jscript.dll',
        'vbscript.dll','scrrun.dll','msxml.dll','msxml3.dll','msxml6.dll','actxprxy.dll',
        'softpub.dll','wintrust.dll','dssenh.dll','rsaenh.dll','gpkcsp.dll','sccbase.dll',
        'slbcsp.dll','cryptdlg.dll','oleaut32.dll','ole32.dll','shell32.dll','initpki.dll',
        'wuapi.dll','wuaueng.dll','wuaueng1.dll','wucltui.dll','wups.dll','wups2.dll',
        'wuweb.dll','qmgr.dll','qmgrprxy.dll','wucltux.dll','muweb.dll','wuwebv.dll'
    )
    Invoke-Cmd (($dlls | ForEach-Object { "regsvr32.exe /s $_" }) -join ' & ')

    # 8) Reset network stack
    Invoke-Cmd "netsh winsock reset"
    Invoke-Cmd "netsh winsock reset proxy"

    # 9) Set services to auto-start
    Invoke-Cmd "sc config wuauserv start= auto"
    Invoke-Cmd "sc config bits start= auto"
    Invoke-Cmd "sc config DcomLaunch start= auto"

    # 10) Restart services
    Invoke-Cmd "net start bits"
    Invoke-Cmd "net start wuauserv"
    Invoke-Cmd "net start cryptsvc"

    Write-Output "--------------------------------------------"
    Write-Output "Reset Windows Update selesai."
    if ($restart -eq 'Yes') {
        Write-Output "Restart komputer dalam 10 detik..."
        shutdown /r /f /t 10
    } else {
        Write-Output "Restart komputer diperlukan untuk menyelesaikan reset Windows Update."
    }
}

Export-ModuleMember -Function Get-ToolConfig, Invoke-ToolAction
