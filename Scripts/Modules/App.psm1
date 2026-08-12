<#
.SYNOPSIS
    Core application module - State management and initialization
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:AppState = @{
    Sessions        = @{}
    ActiveSession   = $null
    Form            = $null
    SessionBar      = $null
    ContentPanel    = $null
    WelcomeView     = $null
    GlobalTimer     = $null
}

function Get-AppState {
    param([string]$Key)
    if ($Key) { return $script:AppState[$Key] }
    return $script:AppState
}

function Set-AppState {
    param($Key, $Value)
    $script:AppState[$Key] = $Value
}

function Initialize-GlobalTimer {
    Write-DebugLog "Initializing global timer" -Category 'APP'
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 150
    $timer.Add_Tick({ Invoke-SessionMonitor })
    Set-AppState -Key 'GlobalTimer' -Value $timer
    return $timer
}

function Start-GlobalTimer {
    Write-DebugLog "Starting global timer" -Category 'APP'
    $timer = Get-AppState -Key 'GlobalTimer'
    if ($timer) { $timer.Start() }
}

function Invoke-SessionMonitor {
    $sessions = (Get-AppState -Key 'Sessions')
    $anyRunning = $false

    foreach ($key in $sessions.Keys) {
        $sess = $sessions[$key]
        if (-not $sess -or -not $sess.IsRunning -or -not $sess.Job) { continue }
        $anyRunning = $true

        $newData = Receive-Job -Job $sess.Job 2>&1
        if ($newData) {
            foreach ($line in $newData) {
                Write-SessionLog -OutputBox $sess.OutputBox -Message $line -Type "INFO"
            }
        }

        if ($sess.Job.State -in @('Completed', 'Failed', 'Stopped')) {
            $tail = Receive-Job -Job $sess.Job 2>&1
            if ($tail) {
                foreach ($line in $tail) {
                    Write-SessionLog -OutputBox $sess.OutputBox -Message $line -Type "INFO"
                }
            }
            Remove-Job -Job $sess.Job -Force -ErrorAction SilentlyContinue
            $sess.Job = $null
            $sess.IsRunning = $false
            $anyRunning = $false
            $sess.BtnRun.Text = "RUN"
            $sess.BtnRun.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
            $sess.MainPanel.Cursor = [System.Windows.Forms.Cursors]::Default
            Write-SessionLog -OutputBox $sess.OutputBox -Message "--------------------------------------------------" -Type "INFO"
            Write-SessionLog -OutputBox $sess.OutputBox -Message "Sesi selesai." -Type "SUCCESS"
            Write-DebugLog "Session completed: $key" -Category 'SESSION'
        }
    }

    # Welcome dashboard: apply result from background load job when ready
    $wjob = Get-AppState -Key 'WelcomeJob'
    if ($wjob -and $wjob.State -ne 'Running') {
        $html = Receive-Job -Job $wjob 2>&1
        Remove-Job -Job $wjob -Force -ErrorAction SilentlyContinue
        Set-AppState -Key 'WelcomeJob' -Value $null
        if ($html) {
            $wb = Get-AppState -Key 'WelcomeView'
            if ($wb) {
                try {
                    if ($wb.Document) {
                        $wb.Document.Write([string]$html)
                    } else {
                        $wb.DocumentText = [string]$html
                    }
                } catch {
                    try { $wb.DocumentText = [string]$html } catch {}
                }
            }
        }
    }

    # Stop the global timer when nothing is pending (idle)
    if (-not $anyRunning -and -not (Get-AppState -Key 'WelcomeJob')) {
        $timer = Get-AppState -Key 'GlobalTimer'
        if ($timer -and $timer.Enabled) { $timer.Stop() }
    }
}

Export-ModuleMember -Function Get-AppState, Set-AppState, Initialize-GlobalTimer, Start-GlobalTimer, Invoke-SessionMonitor