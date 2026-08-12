<#
.SYNOPSIS
    Tool: Virus Scan
#>

$menuName = "Virus Scan"
$toolName = "VirusScan"
$toolCategory = "Security"

$fields = @(
    @{ Name = "Target";         Type = "Text";     Default = "$env:USERPROFILE";     Label = "Scan Target" }
    @{ Name = "ClamAVPath";     Type = "Text";     Default = "C:\Program Files\ClamAV\clamscan.exe"; Label = "ClamAV Path" }
    @{ Name = "MaxFileSize";    Type = "Text";     Default = "7M";                    Label = "Max File Size" }
)

function Get-ToolConfig {
    return @{
        MenuName    = $menuName
        ToolName    = $toolName
        Category    = $toolCategory
        Fields      = $fields
        CustomUI    = $true
        HasCustomPanel = $true
    }
}

function Get-CustomUI {
    param($sessionData)

    $btnCheck = [System.Windows.Forms.Button]::new()
    $btnCheck.Text = "Cek ClamAV"
    $btnCheck.Size = [System.Drawing.Size]::new(110, 28)
    $btnCheck.Location = [System.Drawing.Point]::new(220, 47)
    $btnCheck.BackColor = [System.Drawing.Color]::FromArgb(68, 68, 70)
    $btnCheck.ForeColor = [System.Drawing.Color]::White
    $btnCheck.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnCheck.FlatAppearance.BorderSize = 0
    $btnCheck.Font = [System.Drawing.Font]::new("Segoe UI", 9)
    $btnCheck.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnCheck.Tag = $sessionData
    $btnCheck.Add_Click({
        param($s, $e)
        $sess = $s.Tag
        $path = $sess.Inputs['ClamAVPath'].Text
        if ([System.IO.File]::Exists($path)) {
            Write-SessionLog -OutputBox $sess.OutputBox -Message "ClamAV ditemukan: $path" -Type "SUCCESS"
        } else {
            Write-SessionLog -OutputBox $sess.OutputBox -Message "ClamAV TIDAK ditemukan: $path" -Type "ERROR"
        }
    })

    return @{
        Type = "VirusScan"
        SessionData = $sessionData
        Controls = @($btnCheck)
    }
}

function Invoke-ToolAction {
    param($params)

    $target = $params['Target']
    $clamPath = $params['ClamAVPath']
    $maxFileSize = $params['MaxFileSize']

    if (-not [System.IO.Directory]::Exists($target)) { throw "ERROR: Folder target tidak ditemukan: $target" }
    if (-not [System.IO.File]::Exists($clamPath)) { throw "ERROR: clamscan.exe tidak ditemukan di: $clamPath`nDownload ClamAV di https://www.clamav.net/download" }

    $logDir = Join-Path $env:LOCALAPPDATA "Winstools\logs"
    [System.IO.Directory]::CreateDirectory($logDir) | Out-Null
    $logFile = Join-Path $logDir ("scan_{0:dd}_{0:MM}_{0:yyyy}.log" -f (Get-Date))

    Write-Output "Memeriksa target: $target ..."
    Write-Output "Batas ukuran file: $maxFileSize"
    Write-Output "ClamAV: $clamPath"
    Write-Output "Log: $logFile"
    Write-Output "Memulai scan pada $(Get-Date -Format 'HH:mm:ss') ..."
    Invoke-Cmd "`"$clamPath`" --max-filesize=$maxFileSize -r --log=`"$logFile`" `"$target`""
    Write-Output "Scan selesai pada $(Get-Date -Format 'HH:mm:ss'). Cek log untuk ringkasan."
    if (Test-Path $logFile) { Start-Process notepad.exe -ArgumentList $logFile }
}

Export-ModuleMember -Function Get-ToolConfig, Invoke-ToolAction, Get-CustomUI