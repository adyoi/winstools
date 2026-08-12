<#
.SYNOPSIS
    Session Module - Session management, switching, logging
#>

function Write-SessionLog {
    param(
        $OutputBox,
        [string]$Message,
        [string]$Type = "INFO"
    )
    if (-not $OutputBox) { return }

    if ($OutputBox.InvokeRequired) {
        $OutputBox.Invoke([Action[System.Windows.Forms.RichTextBox, string, string]] { Write-SessionLog $args[0] $args[1] $args[2] }, $OutputBox, $Message, $Type)
        return
    }

    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = "[$timestamp] [$Type]"

    $OutputBox.SelectionStart = $OutputBox.TextLength
    $OutputBox.SelectionLength = 0

    switch ($Type) {
        "SUCCESS" { $OutputBox.SelectionColor = [System.Drawing.Color]::FromArgb(78, 201, 176) }
        "ERROR"   { $OutputBox.SelectionColor = [System.Drawing.Color]::FromArgb(244, 71, 71) }
        "WARNING" { $OutputBox.SelectionColor = [System.Drawing.Color]::FromArgb(220, 220, 170) }
        default   { $OutputBox.SelectionColor = [System.Drawing.Color]::FromArgb(200, 200, 200) }
    }

    $OutputBox.AppendText("$prefix $Message`n")
    $OutputBox.SelectionColor = $OutputBox.ForeColor
    $OutputBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Switch-Session {
    param([string]$FeatureName)

    Write-DebugLog "Switching session to: $FeatureName" -Category 'SESSION'

    $appState = Get-AppState
    $appState.ActiveSession = $FeatureName
    if ($appState.WelcomeView) { $appState.WelcomeView.Visible = $false }

    foreach ($key in $appState.Sessions.Keys) {
        $sess = $appState.Sessions[$key]
        $isActive = ($key -eq $FeatureName)
        $sess.MainPanel.Visible = $isActive
        Set-TabActive -Tab $sess.Tab -Active $isActive
    }
}

function New-Session {
    param(
        [string]$FeatureName,
        $Fields,
        [scriptblock]$RunAction,
        $Feature = $null
    )

    Write-DebugLog "Creating session: $FeatureName" -Category 'SESSION'

    $appState = Get-AppState
    if ($appState.Sessions.ContainsKey($FeatureName)) {
        Write-DebugLog "Session exists, switching to: $FeatureName" -Category 'SESSION'
        Switch-Session -FeatureName $FeatureName
        return
    }

    # Create session UI
    $sessionUI = New-SessionPanel -FeatureName $FeatureName -Fields $Fields

    # Create tab
    $sessionData = @{
        FeatureName = $FeatureName
        Job         = $null
        IsRunning   = $false
        BtnRun      = $sessionUI.BtnRun
        OutputBox   = $sessionUI.OutputBox
        Inputs      = $sessionUI.InputControls
        MainPanel   = $sessionUI.MainPanel
        Tab         = $null
        RunAction   = $RunAction
        Module      = if ($Feature) { $Feature.Module } else { $null }
        ModulePath  = if ($Feature) { $Feature.ModulePath } else { $null }
        HasCustomUI = if ($Feature) { $Feature.HasCustomUI } else { $false }
        RequiresConfirm = if ($Feature) { $Feature.RequiresConfirm } else { $false }
    }

    $tab = New-SessionTab -Title $FeatureName -SessionData $sessionData
    $sessionData.Tab = $tab
    $sessionData.BtnRun.Tag = $sessionData

    # Wire events
    $tab.Panel.Add_Click({ param($s, $e) Switch-Session $s.Tag.FeatureName })
    $tab.Label.Add_Click({ param($s, $e) Switch-Session $s.Tag.FeatureName })

    $tab.CloseButton.Add_Click({
        param($sender, $e)
        $sess = $sender.Tag
        $appState = Get-AppState
        if ($sess.IsRunning) {
            [System.Windows.Forms.MessageBox]::Show("Sesi sedang berjalan. Batalkan (CANCEL) terlebih dahulu sebelum menutup tab.", "Perhatian", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        if ($sess.Job) {
            Stop-SessionJob -Job $sess.Job
        }
        $appState.SessionBar.Tabs.Controls.Remove($sess.Tab.Panel)
        $appState.ContentPanel.Controls.Remove($sess.MainPanel)
        $appState.Sessions.Remove($sess.FeatureName)
        Update-SessionBarArrows

        $remaining = @($appState.Sessions.Keys)
        if ($remaining.Count -gt 0) {
            Switch-Session $remaining[0]
        } else {
            $appState.ActiveSession = $null
            $appState.SessionBar.Visible = $false
            if ($appState.WelcomeView) { $appState.WelcomeView.Visible = $true }
        }
    })

    $sessionUI.BtnRun.Add_Click({
        param($sender, $e)
        $sess = $sender.Tag
        if ($sess.IsRunning) {
            if ($sess.Job) {
                Stop-SessionJob -Job $sess.Job
                $sess.Job = $null
            }
            $sess.IsRunning = $false
            $sender.Text = "RUN"
            $sender.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
            $sess.MainPanel.Cursor = [System.Windows.Forms.Cursors]::Default
            Write-SessionLog -OutputBox $sess.OutputBox -Message "Proses dibatalkan oleh pengguna." -Type "WARNING"
            Write-DebugLog "Session cancelled by user: $($sess.FeatureName)" -Category 'SESSION'
            return
        }

        $params = @{}
        foreach ($k in $sess.Inputs.Keys) {
            $params[$k] = $sess.Inputs[$k].Text
        }

        if ($sess.RequiresConfirm) {
            $answer = [System.Windows.Forms.MessageBox]::Show(
                "Tool ini melakukan tindakan sistem yang berisiko.`n`nLanjutkan eksekusi '$($sess.FeatureName)'?",
                "Konfirmasi",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning)
            if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
                Write-SessionLog -OutputBox $sess.OutputBox -Message "Eksekusi dibatalkan oleh pengguna (konfirmasi)." -Type "WARNING"
                Write-DebugLog "Session cancelled by user (confirm): $($sess.FeatureName)" -Category 'SESSION'
                return
            }
        }

        $sess.IsRunning = $true
        $sender.Text = "CANCEL"
        $sender.BackColor = [System.Drawing.Color]::FromArgb(209, 52, 56)
        $sess.MainPanel.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

        Write-SessionLog -OutputBox $sess.OutputBox -Message "--------------------------------------------------" -Type "INFO"
        Write-SessionLog -OutputBox $sess.OutputBox -Message "Memulai eksekusi: $($sess.FeatureName)" -Type "INFO"
        Write-SessionLog -OutputBox $sess.OutputBox -Message "--------------------------------------------------" -Type "INFO"
        Write-DebugLog "Starting job for: $($sess.FeatureName)" -Category 'SESSION'

        $sess.Job = Start-Job -ScriptBlock $sess.RunAction -ArgumentList $sess.ModulePath, $params
        Start-GlobalTimer
    })

    # --- Custom UI: tool modules return ready-built controls via Get-CustomUI ---
    if ($sessionData.HasCustomUI -and $sessionData.Module) {
        try {
            $getCustomUiCmd = $sessionData.Module.ExportedCommands['Get-CustomUI']
            if ($getCustomUiCmd) {
                $customUI = & $getCustomUiCmd $sessionData
                Write-DebugLog "Custom UI loaded for: $FeatureName" -Category 'SESSION'
                foreach ($ctrl in $customUI.Controls) {
                    $sessionData.BtnRun.Parent.Controls.Add($ctrl)
                }
            }
        } catch {
            Write-ErrorLog "Custom UI error for ${FeatureName}: $_" -Category 'SESSION'
        }
    }

    $appState.Sessions[$FeatureName] = $sessionData
    $appState.SessionBar.Tabs.Controls.Add($tab.Panel)
    $appState.ContentPanel.Controls.Add($sessionUI.MainPanel)
    $appState.SessionBar.Visible = $true
    Update-SessionBarArrows
    $appState.SessionBar.TabsHost.ScrollControlIntoView($tab.Panel)
    Switch-Session -FeatureName $FeatureName
}

function Stop-SessionJob {
    param($Job)

    if (-not $Job) { return }

    Write-DebugLog "Stopping job: $($Job.Id)" -Category 'SESSION'

    # Stop-Job cukup untuk menghentikan proses job (termasuk native command).
    # JANGAN gunakan taskkill /T /F di sini: membunuh child secara paksa membuat
    # console host (conhost.exe) menggantung sehingga powershell tidak mau keluar.
    Stop-Job -Job $Job -ErrorAction SilentlyContinue
    Remove-Job -Job $Job -Force -ErrorAction SilentlyContinue
}

Export-ModuleMember -Function Write-SessionLog, Switch-Session, New-Session, Stop-SessionJob