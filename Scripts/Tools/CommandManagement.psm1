<#
.SYNOPSIS
    Tool: Custom Command
    Custom commands with save/load/execute functionality
#>

$menuName = "Custom Command"
$toolName = "CommandManagement"
$toolCategory = "Advanced"

$fields = @(
    @{ Name = "Name";     Type = "Text";     Default = ""; Label = "Command Name" }
    @{ Name = "Command";  Type = "TextArea"; Default = ""; Label = "Command" }
)

$dataDir = Join-Path $env:LOCALAPPDATA "Winstools"
if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }
$customCommandsPath = Join-Path $dataDir "CustomCommands.json"

function Get-ToolConfig {
    return @{
        MenuName        = $menuName
        ToolName        = $toolName
        Category        = $toolCategory
        Fields          = $fields
        CustomUI        = $true
        HasCustomPanel  = $true
    }
}

function Get-CustomCommandsPath {
    return $customCommandsPath
}

function Read-CustomCommands {
    $commands = @{}
    if (Test-Path $customCommandsPath) {
        try {
            $data = Get-Content $customCommandsPath -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
            if ($data) {
                foreach ($p in $data.PSObject.Properties) {
                    $commands[$p.Name] = [string]$p.Value
                }
            }
        } catch {
            # ignore corrupt/missing file
        }
    }
    return $commands
}

function Save-CustomCommand {
    param($name, $command)
    $commands = Read-CustomCommands
    $commands[$name] = $command
    $commands | ConvertTo-Json -Depth 3 | Set-Content -Path $customCommandsPath -Encoding UTF8
    Write-Output "Command '$name' saved."
}

function Remove-CustomCommand {
    param($name)
    $commands = Read-CustomCommands
    if ($commands.ContainsKey($name)) {
        $commands.Remove($name)
        $commands | ConvertTo-Json -Depth 3 | Set-Content -Path $customCommandsPath -Encoding UTF8
        Write-Output "Command '$name' deleted."
    }
}

function Invoke-ToolAction {
    param($params)

    $command = $params['Command']
    if ([string]::IsNullOrWhiteSpace($command)) {
        Write-Output "No command specified."
        return
    }

    Invoke-Cmd $command
}

function Get-CustomUI {
    param($sessionData)

    $btnSave = [System.Windows.Forms.Button]::new()
    $btnSave.Text = "Save Command"
    $btnSave.Size = [System.Drawing.Size]::new(120, 28)
    $btnSave.Location = [System.Drawing.Point]::new(220, 47)
    $btnSave.BackColor = [System.Drawing.Color]::FromArgb(68, 68, 70)
    $btnSave.ForeColor = [System.Drawing.Color]::White
    $btnSave.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnSave.FlatAppearance.BorderSize = 0
    $btnSave.Font = [System.Drawing.Font]::new("Segoe UI", 9)
    $btnSave.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnSave.Tag = $sessionData
    $btnSave.Add_Click({
        param($s, $e)
        $sess = $s.Tag
        $name = $sess.Inputs['Name'].Text
        $cmd  = $sess.Inputs['Command'].Text
        if (-not $name) { Write-SessionLog -OutputBox $sess.OutputBox -Message "Nama command kosong." -Type "WARNING"; return }
        if (-not $cmd)  { Write-SessionLog -OutputBox $sess.OutputBox -Message "Command kosong." -Type "WARNING"; return }
        Save-CustomCommand $name $cmd | ForEach-Object { Write-SessionLog -OutputBox $sess.OutputBox -Message $_ -Type "INFO" }
    })

    $btnLoad = [System.Windows.Forms.Button]::new()
    $btnLoad.Text = "Load Command"
    $btnLoad.Size = [System.Drawing.Size]::new(110, 28)
    $btnLoad.Location = [System.Drawing.Point]::new(350, 47)
    $btnLoad.BackColor = [System.Drawing.Color]::FromArgb(68, 68, 70)
    $btnLoad.ForeColor = [System.Drawing.Color]::White
    $btnLoad.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnLoad.FlatAppearance.BorderSize = 0
    $btnLoad.Font = [System.Drawing.Font]::new("Segoe UI", 9)
    $btnLoad.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnLoad.Tag = $sessionData
    $btnLoad.Add_Click({
        param($s, $e)
        $sess = $s.Tag
        $name = $sess.Inputs['Name'].Text
        if (-not $name) { Write-SessionLog -OutputBox $sess.OutputBox -Message "Nama command kosong." -Type "WARNING"; return }
        $cmds = Read-CustomCommands
        if ($cmds.ContainsKey($name)) {
            $sess.Inputs['Command'].Text = $cmds[$name]
            Write-SessionLog -OutputBox $sess.OutputBox -Message "Command '$name' dimuat dari CustomCommands.json." -Type "SUCCESS"
        } else {
            Write-SessionLog -OutputBox $sess.OutputBox -Message "Command '$name' tidak ditemukan di CustomCommands.json." -Type "WARNING"
        }
    })

    return @{
        Type = "CommandManagement"
        SessionData = $sessionData
        Controls = @($btnSave, $btnLoad)
    }
}

Export-ModuleMember -Function Get-ToolConfig, Invoke-ToolAction, Get-CustomUI, Read-CustomCommands, Save-CustomCommand, Remove-CustomCommand, Get-CustomCommandsPath