<#
.SYNOPSIS
    Tool: Virus Scan (ClamAV)
#>

$menuName = "Virus Scanner [ClamAV]"
$toolName = "VirusScanner"
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

    $btnUpdate = [System.Windows.Forms.Button]::new()
    $btnUpdate.Text = "Update Databases"
    $btnUpdate.Size = [System.Drawing.Size]::new(130, 28)
    $btnUpdate.Location = [System.Drawing.Point]::new(340, 47)
    $btnUpdate.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnUpdate.ForeColor = [System.Drawing.Color]::White
    $btnUpdate.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnUpdate.FlatAppearance.BorderSize = 0
    $btnUpdate.Font = [System.Drawing.Font]::new("Segoe UI", 9)
    $btnUpdate.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnUpdate.Tag = $sessionData
    $btnUpdate.Add_Click({
        param($s, $e)
        $sess = $s.Tag
        $s.Text = "Updating..."
        $s.Enabled = $false
        try {
            $base = Split-Path $sess.Inputs['ClamAVPath'].Text -Parent
            $fresh = Join-Path $base 'freshclam.exe'
            if (-not [System.IO.File]::Exists($fresh)) {
                Write-SessionLog -OutputBox $sess.OutputBox -Message "freshclam.exe tidak ditemukan di: $fresh" -Type "ERROR"
                return
            }
            Write-SessionLog -OutputBox $sess.OutputBox -Message "Memperbarui database ClamAV: $fresh" -Type "INFO"
            $out = & $fresh 2>&1
            $out | ForEach-Object { Write-SessionLog -OutputBox $sess.OutputBox -Message $_ -Type "INFO" }
            Write-SessionLog -OutputBox $sess.OutputBox -Message "Pembaruan database selesai." -Type "SUCCESS"
        } catch {
            Write-SessionLog -OutputBox $sess.OutputBox -Message "Gagal memperbarui database: $_" -Type "ERROR"
        } finally {
            $s.Text = "Update Databases"
            $s.Enabled = $true
        }
    })

    return @{
        Type = "VirusScanner"
        SessionData = $sessionData
        Controls = @($btnCheck, $btnUpdate)
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