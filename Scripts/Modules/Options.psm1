<#
.SYNOPSIS
    Options Module - tombol Options (merah) + separator di menu, dan panel tabs:
    Gui Config, Gui Builder, Gui Tester, Check Update / Self Update, Changelog, About.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$script:GitRepo       = 'adyoi/winstools'
$script:OptBuildState = $null
$script:OptTestState  = $null
$script:OptUpdState   = $null

function Get-ProjectRoot {
    $dir = Split-Path $PSScriptRoot -Parent
    $root = Split-Path $dir -Parent
    $prev = $null
    while ($root -and $root -ne $prev) {
        if (Test-Path (Join-Path $root 'Scripts\Modules\Config.psm1')) { return $root }
        $prev = $root
        $root = Split-Path $root -Parent
    }
    return $null
}

function Get-AppVersion {
    $root = Get-ProjectRoot
    if ($root) {
        $vf = Join-Path $root 'VERSION'
        if (Test-Path $vf) { return (Get-Content $vf -Raw).Trim() }
    }
    try {
        $vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
        if ($vi.FileVersion) { return $vi.FileVersion }
    } catch {}
    return '1.0.0'
}

function New-OptionsSeparator {
    $sep = [System.Windows.Forms.Panel]::new()
    $sep.Width = 205
    $sep.Height = 1
    $sep.BackColor = [System.Drawing.Color]::FromArgb(90, 90, 98)
    return $sep
}

function New-OptionsButton {
    $btn = [System.Windows.Forms.Button]::new()
    $btn.Text = "  Options"
    $btn.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $btn.Size = [System.Drawing.Size]::new(205, 34)
    $btn.BackColor = [System.Drawing.Color]::FromArgb(196, 43, 43)
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderSize = 0
    $btn.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(226, 58, 58)
    $btn.Font = [System.Drawing.Font]::new("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.Add_Click({ Show-OptionsDialog })
    return $btn
}

function New-OptionsForm {
    $form = [System.Windows.Forms.Form]::new()
    $form.Text = "Options - Winstools"
    $form.Size = [System.Drawing.Size]::new(820, 600)
    $form.MinimumSize = [System.Drawing.Size]::new(700, 500)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 247)
    $iconPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Icons\window.ico"
    if (-not (Test-Path $iconPath)) { $iconPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Icons\window.ico" }
    if (-not (Test-Path $iconPath)) { $iconPath = Join-Path $PSScriptRoot "Icons\window.ico" }
    if (Test-Path $iconPath) {
        $form.Icon = [System.Drawing.Icon]::new($iconPath)
    }
    return $form
}

# ---------------------------------------------------------------------------
# Tab: Gui Config
# ---------------------------------------------------------------------------
function New-ConfigTab {
    $tab = [System.Windows.Forms.TabPage]::new()
    $tab.Text = "Gui Config"
    $tab.Padding = [System.Windows.Forms.Padding]::new(5)
    $tab.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 247)

    $lblTitle = [System.Windows.Forms.Label]::new()
    $lblTitle.Text = "Konfigurasi Aplikasi"
    $lblTitle.Font = [System.Drawing.Font]::new("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 45)
    $lblTitle.Location = [System.Drawing.Point]::new(14, 12)
    $lblTitle.AutoSize = $true
    $tab.Controls.Add($lblTitle)

    $lblSub = [System.Windows.Forms.Label]::new()
    $lblSub.Text = "Terapkan langsung ke sesi berjalan. Perubahan berlaku seketika."
    $lblSub.Font = [System.Drawing.Font]::new("Segoe UI", 9)
    $lblSub.ForeColor = [System.Drawing.Color]::FromArgb(110, 110, 118)
    $lblSub.Location = [System.Drawing.Point]::new(14, 40)
    $lblSub.AutoSize = $true
    $tab.Controls.Add($lblSub)

    $lblEnv = [System.Windows.Forms.Label]::new()
    $lblEnv.Text = "Environment"
    $lblEnv.Font = [System.Drawing.Font]::new("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblEnv.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 86)
    $lblEnv.Location = [System.Drawing.Point]::new(14, 80)
    $lblEnv.AutoSize = $true
    $tab.Controls.Add($lblEnv)

    $cboEnv = [System.Windows.Forms.ComboBox]::new()
    $cboEnv.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cboEnv.Items.AddRange(@('Production', 'Development'))
    $cboEnv.Size = [System.Drawing.Size]::new(220, 26)
    $cboEnv.Location = [System.Drawing.Point]::new(14, 102)
    $tab.Controls.Add($cboEnv)

    $lblDbg = [System.Windows.Forms.Label]::new()
    $lblDbg.Text = "Debug Log"
    $lblDbg.Font = [System.Drawing.Font]::new("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblDbg.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 86)
    $lblDbg.Location = [System.Drawing.Point]::new(260, 80)
    $lblDbg.AutoSize = $true
    $tab.Controls.Add($lblDbg)

    $chkDebug = [System.Windows.Forms.CheckBox]::new()
    $chkDebug.Text = "Tampilkan log DEBUG"
    $chkDebug.Size = [System.Drawing.Size]::new(180, 26)
    $chkDebug.Location = [System.Drawing.Point]::new(260, 102)
    $tab.Controls.Add($chkDebug)

    $lblLog = [System.Windows.Forms.Label]::new()
    $lblLog.Text = "Log Level"
    $lblLog.Font = [System.Drawing.Font]::new("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblLog.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 86)
    $lblLog.Location = [System.Drawing.Point]::new(14, 140)
    $lblLog.AutoSize = $true
    $tab.Controls.Add($lblLog)

    $cboLog = [System.Windows.Forms.ComboBox]::new()
    $cboLog.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cboLog.Items.AddRange(@('DEBUG', 'INFO', 'WARN', 'ERROR'))
    $cboLog.SelectedIndex = 3
    $cboLog.Size = [System.Drawing.Size]::new(220, 26)
    $cboLog.Location = [System.Drawing.Point]::new(14, 162)
    $tab.Controls.Add($cboLog)

    $lblInfo = [System.Windows.Forms.Label]::new()
    $lblInfo.Text = "Development -> Debug ON, LogLevel DEBUG.`nProduction -> Debug OFF, LogLevel ERROR.`nAnda bisa meng-override Debug / Log Level secara manual."
    $lblInfo.Font = [System.Drawing.Font]::new("Segoe UI", 8.5)
    $lblInfo.ForeColor = [System.Drawing.Color]::FromArgb(130, 130, 138)
    $lblInfo.Location = [System.Drawing.Point]::new(14, 200)
    $lblInfo.AutoSize = $true
    $tab.Controls.Add($lblInfo)

    $lblStatus = [System.Windows.Forms.Label]::new()
    $lblStatus.Text = ""
    $lblStatus.Font = [System.Drawing.Font]::new("Segoe UI", 9)
    $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $lblStatus.Location = [System.Drawing.Point]::new(14, 250)
    $lblStatus.AutoSize = $true
    $tab.Controls.Add($lblStatus)

    $btnApply = [System.Windows.Forms.Button]::new()
    $btnApply.Text = "Terapkan"
    $btnApply.Size = [System.Drawing.Size]::new(120, 32)
    $btnApply.Location = [System.Drawing.Point]::new(14, 280)
    $btnApply.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnApply.ForeColor = [System.Drawing.Color]::White
    $btnApply.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnApply.FlatAppearance.BorderSize = 0
    $btnApply.Font = [System.Drawing.Font]::new("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $btnApply.Cursor = [System.Windows.Forms.Cursors]::Hand
    $tab.Controls.Add($btnApply)

    $btnRefresh = [System.Windows.Forms.Button]::new()
    $btnRefresh.Text = "Muat Nilai Aktif"
    $btnRefresh.Size = [System.Drawing.Size]::new(140, 32)
    $btnRefresh.Location = [System.Drawing.Point]::new(146, 280)
    $btnRefresh.BackColor = [System.Drawing.Color]::FromArgb(68, 68, 72)
    $btnRefresh.ForeColor = [System.Drawing.Color]::White
    $btnRefresh.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnRefresh.FlatAppearance.BorderSize = 0
    $btnRefresh.Font = [System.Drawing.Font]::new("Segoe UI", 9)
    $btnRefresh.Cursor = [System.Windows.Forms.Cursors]::Hand
    $tab.Controls.Add($btnRefresh)

    $tag = @{ Env = $cboEnv; Debug = $chkDebug; Log = $cboLog; Status = $lblStatus; Suppress = $false }
    $btnApply.Tag = $tag
    $btnRefresh.Tag = $tag
    $cboEnv.Tag = $tag

    $cboEnv.Add_SelectedIndexChanged({
        param($s, $e)
        $d = $s.Tag
        if ($d.Suppress) { return }
        if ($d.Env.SelectedIndex -eq 1) { $d.Debug.Checked = $true; $d.Log.SelectedIndex = 0 }
        else { $d.Debug.Checked = $false; $d.Log.SelectedIndex = 3 }
    })

    $btnApply.Add_Click({
        param($s, $e)
        $d = $s.Tag
        $envVal = if ($d.Env.SelectedIndex -eq 1) { 'Development' } else { 'Production' }
        $dbgVal = $d.Debug.Checked
        $logVal = @('DEBUG', 'INFO', 'WARN', 'ERROR')[$d.Log.SelectedIndex]
        try {
            $init = Get-Command Initialize-Config -ErrorAction Stop
            & $init -Environment $envVal -Debug:$dbgVal -LogLevel $logVal
            $d.Status.Text = "Diterapkan: Environment=$envVal, Debug=$dbgVal, LogLevel=$logVal"
        } catch {
            $d.Status.Text = "Gagal menerapkan: $_"
        }
    })

    $btnRefresh.Add_Click({
        param($s, $e)
        $d = $s.Tag
        $envVal = (Get-Config -Key 'Environment')
        $dbgVal = (Get-Config -Key 'Debug')
        $logVal = (Get-Config -Key 'LogLevel')
        $d.Suppress = $true
        $d.Env.SelectedIndex = if ($envVal -eq 'Development') { 1 } else { 0 }
        $d.Debug.Checked = [bool]$dbgVal
        $idx = @('DEBUG', 'INFO', 'WARN', 'ERROR').IndexOf($logVal)
        $d.Log.SelectedIndex = if ($idx -ge 0) { $idx } else { 3 }
        $d.Suppress = $false
        $d.Status.Text = "Nilai aktif: Environment=$envVal, Debug=$([bool]$dbgVal), LogLevel=$logVal"
    })

    # Muat nilai aktif saat dialog dibuka (agar selalu menampilkan state terkini,
    # termasuk setelah Apply lalu tutup-buka dialog lagi).
    try {
        $envVal = (Get-Config -Key 'Environment')
        $dbgVal = (Get-Config -Key 'Debug')
        $logVal = (Get-Config -Key 'LogLevel')
        $tag.Suppress = $true
        $tag.Env.SelectedIndex = if ($envVal -eq 'Development') { 1 } else { 0 }
        $tag.Debug.Checked = [bool]$dbgVal
        $idx = @('DEBUG', 'INFO', 'WARN', 'ERROR').IndexOf($logVal)
        $tag.Log.SelectedIndex = if ($idx -ge 0) { $idx } else { 3 }
        $tag.Suppress = $false
        $tag.Status.Text = "Nilai aktif: Environment=$envVal, Debug=$([bool]$dbgVal), LogLevel=$logVal"
    } catch {
        $tag.Suppress = $false
    }

    return $tab
}

# ---------------------------------------------------------------------------
# Helper: proses redirect + timer polling log
# ---------------------------------------------------------------------------
function Start-RedirectProcess {
    param([string]$FilePath, [string[]]$Arguments)
    $outFile = Join-Path $env:TEMP ("winstools_out_" + [guid]::NewGuid().ToString('N') + ".txt")
    $errFile = Join-Path $env:TEMP ("winstools_err_" + [guid]::NewGuid().ToString('N') + ".txt")
    $quoted = @($Arguments | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } })
    $psi = @{
        FilePath = $FilePath
        ArgumentList = ($quoted -join ' ')
        RedirectStandardOutput = $outFile
        RedirectStandardError = $errFile
        NoNewWindow = $true
        PassThru = $true
    }
    $proc = Start-Process @psi
    return @{ Proc = $proc; Out = $outFile; Err = $errFile }
}

function Read-ProcLog {
    param($State)
    $text = ""
    foreach ($k in @('Out', 'Err')) {
        $f = $State[$k]
        if (-not $f -or -not (Test-Path $f)) { continue }
        $len = (Get-Item $f).Length
        $posKey = "$($k)Pos"
        $pos = [int64]$State[$posKey]
        if ($len -gt $pos) {
            try {
                $fs = [System.IO.File]::OpenRead($f)
                try {
                    $fs.Seek($pos, [System.IO.SeekOrigin]::Begin) | Out-Null
                    $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::UTF8)
                    $text += $sr.ReadToEnd()
                    $State[$posKey] = $fs.Position
                } finally { $fs.Dispose() }
            } catch {}
        }
    }
    return $text
}

# ---------------------------------------------------------------------------
# Tab: Gui Builder
# ---------------------------------------------------------------------------
function New-BuilderTab {
    $tab = [System.Windows.Forms.TabPage]::new()
    $tab.Text = "Gui Builder"
    $tab.Padding = [System.Windows.Forms.Padding]::new(14)
    $tab.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 247)

    $top = [System.Windows.Forms.Panel]::new()
    $top.Dock = [System.Windows.Forms.DockStyle]::Top
    $top.Height = 148
    $top.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 247)

    $lblTitle = [System.Windows.Forms.Label]::new()
    $lblTitle.Text = "Gui Builder - Kompilasi EXE"
    $lblTitle.Font = [System.Drawing.Font]::new("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 45)
    $lblTitle.Location = [System.Drawing.Point]::new(14, 12)
    $lblTitle.AutoSize = $true
    $top.Controls.Add($lblTitle)

    $lblVer = [System.Windows.Forms.Label]::new()
    $lblVer.Text = "Versi"
    $lblVer.Font = [System.Drawing.Font]::new("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblVer.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 86)
    $lblVer.Location = [System.Drawing.Point]::new(14, 48)
    $lblVer.AutoSize = $true
    $top.Controls.Add($lblVer)

    $txtVer = [System.Windows.Forms.TextBox]::new()
    $txtVer.Text = Get-AppVersion
    $txtVer.Size = [System.Drawing.Size]::new(140, 26)
    $txtVer.Location = [System.Drawing.Point]::new(14, 70)
    $top.Controls.Add($txtVer)

    $lblPath = [System.Windows.Forms.Label]::new()
    $lblPath.Text = "Skrip: Build\build-exe.ps1"
    $lblPath.Font = [System.Drawing.Font]::new("Segoe UI", 8.5)
    $lblPath.ForeColor = [System.Drawing.Color]::FromArgb(130, 130, 138)
    $lblPath.Location = [System.Drawing.Point]::new(170, 74)
    $lblPath.AutoSize = $true
    $top.Controls.Add($lblPath)

    $btnBuild = [System.Windows.Forms.Button]::new()
    $btnBuild.Text = "Build"
    $btnBuild.Size = [System.Drawing.Size]::new(110, 32)
    $btnBuild.Location = [System.Drawing.Point]::new(14, 104)
    $btnBuild.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnBuild.ForeColor = [System.Drawing.Color]::White
    $btnBuild.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnBuild.FlatAppearance.BorderSize = 0
    $btnBuild.Font = [System.Drawing.Font]::new("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $btnBuild.Cursor = [System.Windows.Forms.Cursors]::Hand
    $top.Controls.Add($btnBuild)

    $btnOpenFolder = [System.Windows.Forms.Button]::new()
    $btnOpenFolder.Text = "Buka Folder"
    $btnOpenFolder.Size = [System.Drawing.Size]::new(110, 32)
    $btnOpenFolder.Location = [System.Drawing.Point]::new(134, 104)
    $btnOpenFolder.BackColor = [System.Drawing.Color]::FromArgb(68, 68, 72)
    $btnOpenFolder.ForeColor = [System.Drawing.Color]::White
    $btnOpenFolder.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnOpenFolder.FlatAppearance.BorderSize = 0
    $btnOpenFolder.Font = [System.Drawing.Font]::new("Segoe UI", 9)
    $btnOpenFolder.Cursor = [System.Windows.Forms.Cursors]::Hand
    $top.Controls.Add($btnOpenFolder)

    $box = [System.Windows.Forms.RichTextBox]::new()
    $box.ReadOnly = $true
    $box.Font = [System.Drawing.Font]::new("Consolas", 9.5)
    $box.BackColor = [System.Drawing.Color]::FromArgb(18, 18, 20)
    $box.ForeColor = [System.Drawing.Color]::FromArgb(210, 210, 215)
    $box.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $box.Dock = [System.Windows.Forms.DockStyle]::Fill
    $box.Text = "[READY] Masukkan versi lalu klik Build.`n"
    $tab.Controls.Add($top)
    $tab.Controls.Add($box)

    $btnBuild.Tag = @{ Ver = $txtVer; Box = $box; Btn = $btnBuild }
    $btnOpenFolder.Tag = @{ Ver = $txtVer }

    $btnBuild.Add_Click({
        param($s, $e)
        $d = $s.Tag
        $ver = $d.Ver.Text.Trim()
        if (-not $ver) { $d.Box.AppendText("[ERROR] Versi kosong.`n"); return }
        $root = Get-ProjectRoot
        if (-not $root) { $d.Box.AppendText("[ERROR] Project root tidak ditemukan. Jalankan dari source (dev).`n"); return }
        $buildScript = Join-Path $root 'Build\build-exe.ps1'
        if (-not (Test-Path $buildScript)) {
            $d.Box.AppendText("[ERROR] build-exe.ps1 tidak ditemukan: $buildScript`n")
            return
        }
        if ($script:OptBuildState -and $script:OptBuildState.Proc -and -not $script:OptBuildState.Proc.HasExited) {
            $d.Box.AppendText("[WARN] Build masih berjalan.`n")
            return
        }
        $d.Btn.Enabled = $false
        $d.Btn.Text = "Membangun..."
        $d.Box.Clear()
        $d.Box.AppendText("[BUILD] Versi: $ver`n")
        $d.Box.AppendText("[BUILD] Skrip : $buildScript`n`n")

        $runner = Join-Path $env:TEMP ("winstools_runner_" + [guid]::NewGuid().ToString('N') + ".ps1")
        $body = "`$ErrorActionPreference='Continue'; & '$buildScript' -Version '$ver' 2>&1 | ForEach-Object { `$_.ToString() }"
        Set-Content -LiteralPath $runner -Value $body -Encoding UTF8
        $runArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $runner)
        $state = Start-RedirectProcess -FilePath 'powershell.exe' -Arguments $runArgs
        $state.Box = $d.Box
        $state.Btn = $d.Btn
        $state.Runner = $runner
        $state.OutPos = [int64]0
        $state.ErrPos = [int64]0
        $script:OptBuildState = $state
    })

    $btnOpenFolder.Add_Click({
        param($s, $e)
        $d = $s.Tag
        $ver = $d.Ver.Text.Trim()
        $root = Get-ProjectRoot
        if (-not $root) { return }
        $shortVer = ($ver -split '\.')[0..1] -join '.'
        $dir = Join-Path $root "Build\$shortVer"
        if (Test-Path $dir) { Start-Process explorer.exe $dir }
        else {
            $dir2 = Join-Path $root 'Build'
            if (Test-Path $dir2) { Start-Process explorer.exe $dir2 }
        }
    })

    return $tab
}

# ---------------------------------------------------------------------------
# Tab: Gui Tester
# ---------------------------------------------------------------------------
function New-TesterTab {
    $tab = [System.Windows.Forms.TabPage]::new()
    $tab.Text = "Gui Tester"
    $tab.Padding = [System.Windows.Forms.Padding]::new(14)
    $tab.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 247)

    $top = [System.Windows.Forms.Panel]::new()
    $top.Dock = [System.Windows.Forms.DockStyle]::Top
    $top.Height = 148
    $top.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 247)

    $lblTitle = [System.Windows.Forms.Label]::new()
    $lblTitle.Text = "Gui Tester - Jalankan Test"
    $lblTitle.Font = [System.Drawing.Font]::new("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 45)
    $lblTitle.Location = [System.Drawing.Point]::new(14, 12)
    $lblTitle.AutoSize = $true
    $top.Controls.Add($lblTitle)

    $lblSel = [System.Windows.Forms.Label]::new()
    $lblSel.Text = "Jenis Test"
    $lblSel.Font = [System.Drawing.Font]::new("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblSel.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 86)
    $lblSel.Location = [System.Drawing.Point]::new(14, 48)
    $lblSel.AutoSize = $true
    $top.Controls.Add($lblSel)

    $cboTest = [System.Windows.Forms.ComboBox]::new()
    $cboTest.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cboTest.Items.AddRange(@('Pester (semua unit test)', 'Form smoke test (auto-close)', 'Capture screenshot test'))
    $cboTest.SelectedIndex = 0
    $cboTest.Size = [System.Drawing.Size]::new(320, 26)
    $cboTest.Location = [System.Drawing.Point]::new(14, 70)
    $top.Controls.Add($cboTest)

    $btnRun = [System.Windows.Forms.Button]::new()
    $btnRun.Text = "Jalankan Test"
    $btnRun.Size = [System.Drawing.Size]::new(130, 32)
    $btnRun.Location = [System.Drawing.Point]::new(14, 106)
    $btnRun.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnRun.ForeColor = [System.Drawing.Color]::White
    $btnRun.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnRun.FlatAppearance.BorderSize = 0
    $btnRun.Font = [System.Drawing.Font]::new("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $btnRun.Cursor = [System.Windows.Forms.Cursors]::Hand
    $top.Controls.Add($btnRun)

    $box = [System.Windows.Forms.RichTextBox]::new()
    $box.ReadOnly = $true
    $box.Font = [System.Drawing.Font]::new("Consolas", 9.5)
    $box.BackColor = [System.Drawing.Color]::FromArgb(18, 18, 20)
    $box.ForeColor = [System.Drawing.Color]::FromArgb(210, 210, 215)
    $box.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $box.Dock = [System.Windows.Forms.DockStyle]::Fill
    $box.Text = "[READY] Pilih jenis test lalu klik Jalankan.`n"
    $tab.Controls.Add($top)
    $tab.Controls.Add($box)

    $btnRun.Tag = @{ Cbo = $cboTest; Box = $box; Btn = $btnRun }

    $btnRun.Add_Click({
        param($s, $e)
        $d = $s.Tag
        $root = Get-ProjectRoot
        if (-not $root) {
            $d.Box.AppendText("[ERROR] Project root tidak ditemukan. Jalankan dari source (dev).`n")
            return
        }
        $testDir = Join-Path $root 'Test'
        $kind = $d.Cbo.SelectedIndex
        if ($script:OptTestState -and $script:OptTestState.Proc -and -not $script:OptTestState.Proc.HasExited) {
            $d.Box.AppendText("[WARN] Test masih berjalan.`n")
            return
        }
        $d.Btn.Enabled = $false
        $d.Btn.Text = "Menjalankan..."
        $d.Box.Clear()
        $d.Box.AppendText("[TEST] Mulai: $($d.Cbo.Text)`n`n")

        $runner = Join-Path $env:TEMP ("winstools_runner_" + [guid]::NewGuid().ToString('N') + ".ps1")
        switch ($kind) {
            0 {
                $body = "`$ErrorActionPreference='Continue'; Import-Module Pester -ErrorAction SilentlyContinue; `$p = Get-Module Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1; if (`$p.Version -ge [version]'5.0') { `$r = Invoke-Pester -Path '$testDir\Pester.Tests.ps1' -PassThru } else { `$r = Invoke-Pester -Script '$testDir\Pester.Tests.ps1' -PassThru }; Write-Output ('PESTER: Passed=' + `$r.PassedCount + ' Failed=' + `$r.FailedCount)"
            }
            1 {
                $body = "& '$testDir\form_test.ps1' -AutoClose 3"
            }
            default {
                $body = "& '$testDir\capture_test.ps1'"
            }
        }
        Set-Content -LiteralPath $runner -Value $body -Encoding UTF8
        $runArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $runner)
        $state = Start-RedirectProcess -FilePath 'powershell.exe' -Arguments $runArgs
        $state.Box = $d.Box
        $state.Btn = $d.Btn
        $state.Runner = $runner
        $state.OutPos = [int64]0
        $state.ErrPos = [int64]0
        $script:OptTestState = $state
    })

    return $tab
}

# ---------------------------------------------------------------------------
# Tab: Check Update / Self Update
# ---------------------------------------------------------------------------
function New-UpdateTab {
    $tab = [System.Windows.Forms.TabPage]::new()
    $tab.Text = "Check Update - Self Update"
    $tab.Padding = [System.Windows.Forms.Padding]::new(14)
    $tab.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 247)

    $top = [System.Windows.Forms.Panel]::new()
    $top.Dock = [System.Windows.Forms.DockStyle]::Top
    $top.Height = 130
    $top.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 247)

    $lblTitle = [System.Windows.Forms.Label]::new()
    $lblTitle.Text = "Check Update / Self Update"
    $lblTitle.Font = [System.Drawing.Font]::new("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 45)
    $lblTitle.Location = [System.Drawing.Point]::new(14, 12)
    $lblTitle.AutoSize = $true
    $top.Controls.Add($lblTitle)

    $lblVer = [System.Windows.Forms.Label]::new()
    $lblVer.Text = "Versi lokal: $(Get-AppVersion)"
    $lblVer.Font = [System.Drawing.Font]::new("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $lblVer.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 86)
    $lblVer.Location = [System.Drawing.Point]::new(14, 48)
    $lblVer.AutoSize = $true
    $top.Controls.Add($lblVer)

    $btnCheck = [System.Windows.Forms.Button]::new()
    $btnCheck.Text = "Cek Update"
    $btnCheck.Size = [System.Drawing.Size]::new(120, 32)
    $btnCheck.Location = [System.Drawing.Point]::new(14, 82)
    $btnCheck.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnCheck.ForeColor = [System.Drawing.Color]::White
    $btnCheck.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnCheck.FlatAppearance.BorderSize = 0
    $btnCheck.Font = [System.Drawing.Font]::new("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $btnCheck.Cursor = [System.Windows.Forms.Cursors]::Hand
    $top.Controls.Add($btnCheck)

    $btnDownload = [System.Windows.Forms.Button]::new()
    $btnDownload.Text = "Unduh Update"
    $btnDownload.Size = [System.Drawing.Size]::new(130, 32)
    $btnDownload.Location = [System.Drawing.Point]::new(146, 82)
    $btnDownload.BackColor = [System.Drawing.Color]::FromArgb(196, 43, 43)
    $btnDownload.ForeColor = [System.Drawing.Color]::White
    $btnDownload.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnDownload.FlatAppearance.BorderSize = 0
    $btnDownload.Font = [System.Drawing.Font]::new("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $btnDownload.Cursor = [System.Windows.Forms.Cursors]::Hand
    $top.Controls.Add($btnDownload)

    $box = [System.Windows.Forms.RichTextBox]::new()
    $box.ReadOnly = $true
    $box.Font = [System.Drawing.Font]::new("Consolas", 9.5)
    $box.BackColor = [System.Drawing.Color]::FromArgb(18, 18, 20)
    $box.ForeColor = [System.Drawing.Color]::FromArgb(210, 210, 215)
    $box.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $box.Dock = [System.Windows.Forms.DockStyle]::Fill
    $box.Text = "[READY] Sumber rilis: $script:GitRepo`n"
    $tab.Controls.Add($box)
    $tab.Controls.Add($top)
    

    $btnCheck.Tag = @{ Box = $box; Btn = $btnCheck; BtnDownload = $btnDownload }
    $btnDownload.Tag = @{ Box = $box; Btn = $btnCheck; BtnDownload = $btnDownload }

    $btnCheck.Add_Click({
        param($s, $e)
        $d = $s.Tag
        $d.Btn.Enabled = $false
        $d.Btn.Text = "Memeriksa..."
        $d.BtnDownload.Enabled = $false
        $boxRef = $d.Box
        $repo = $script:GitRepo
        $script:OptUpdState = $null

        $ps = [System.Management.Automation.PowerShell]::Create()
        $script = "param(`$Repo)`$ProgressPreference='SilentlyContinue'; try { `$r = Invoke-RestMethod -Uri ('https://api.github.com/repos/' + `$Repo + '/releases/latest') -Headers @{ 'User-Agent' = 'Winstools' } -TimeoutSec 20; Write-Output `$r | ConvertTo-Json -Depth 4 } catch { Write-Output ('ERROR: ' + `$_) }"
        $null = $ps.AddScript($script).AddArgument($repo)
        $async = $ps.BeginInvoke()
        $script:OptUpdState = @{ Ps = $ps; Async = $async; Box = $boxRef; Btn = $d.Btn; BtnDownload = $d.BtnDownload; Phase = 'check' }
    })

    $btnDownload.Add_Click({
        param($s, $e)
        $d = $s.Tag
        if (-not $script:OptUpdState -or -not $script:OptUpdState.Release) {
            $d.Box.AppendText("[WARN] Lakukan 'Cek Update' dulu.`n")
            return
        }
        $rel = $script:OptUpdState.Release
        $asset = @($rel.assets | Where-Object { $_.name -eq 'winstools.exe' })[0]
        if (-not $asset) {
            $d.Box.AppendText("[WARN] Asset winstools.exe tidak ditemukan di rilis.`n")
            return
        }
        $d.BtnDownload.Enabled = $false
        $d.BtnDownload.Text = "Mengunduh..."
        $destDir = Join-Path $env:TEMP 'winstools_update'
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        $dest = Join-Path $destDir 'winstools.exe'
        $boxRef = $d.Box

        $ps = [System.Management.Automation.PowerShell]::Create()
        $script = "param(`$Url, `$Dest)`$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri `$Url -OutFile `$Dest -UseBasicParsing -TimeoutSec 120; Write-Output ('OK: ' + `$Dest) } catch { Write-Output ('ERROR: ' + `$_) }"
        $null = $ps.AddScript($script).AddArgument($asset.browser_download_url).AddArgument($dest)
        $async = $ps.BeginInvoke()
        $script:OptUpdState.Ps = $ps
        $script:OptUpdState.Async = $async
        $script:OptUpdState.Box = $boxRef
        $script:OptUpdState.BtnDownload = $d.BtnDownload
        $script:OptUpdState.Phase = 'download'
    })

    return $tab
}

# ---------------------------------------------------------------------------
# Tab: Changelog
# ---------------------------------------------------------------------------
function New-ChangelogTab {
    $tab = [System.Windows.Forms.TabPage]::new()
    $tab.Text = "Changelog"
    $tab.Padding = [System.Windows.Forms.Padding]::new(8)
    $tab.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 247)

    $box = [System.Windows.Forms.RichTextBox]::new()
    $box.ReadOnly = $true
    $box.Dock = [System.Windows.Forms.DockStyle]::Fill
    $box.Font = [System.Drawing.Font]::new("Consolas", 9.5)
    $box.BackColor = [System.Drawing.Color]::White
    $box.ForeColor = [System.Drawing.Color]::FromArgb(45, 45, 50)
    $root = Get-ProjectRoot
    $chg = if ($root) { Join-Path $root 'CHANGELOG.md' } else { $null }
    if ($chg -and (Test-Path $chg)) {
        $box.Text = Get-Content $chg -Raw
    } else {
        $box.Text = "CHANGELOG.md tidak ditemukan (jalankan dari source / dev)."
    }
    $tab.Controls.Add($box)
    return $tab
}

# ---------------------------------------------------------------------------
# Tab: About
# ---------------------------------------------------------------------------
function New-AboutTab {
    $tab = [System.Windows.Forms.TabPage]::new()
    $tab.Text = "About"
    $tab.Padding = [System.Windows.Forms.Padding]::new(14)
    $tab.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 247)

    $lbl = [System.Windows.Forms.Label]::new()
    $lbl.Font = [System.Drawing.Font]::new("Segoe UI", 10)
    $lbl.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 66)
    $lbl.Location = [System.Drawing.Point]::new(14, 16)
    $lbl.AutoSize = $true
    $lbl.Text = "Windows Super Tools - Winstools`nVersi: $(Get-AppVersion)`n`nWindows Super Tools - Limitless Windows Optimization`ndengan multi-session, welcome dashboard, auto-elevasi, dan CI build + test.`n`nPerusahaan: PT (Perorangan) Adidaya Karya Utama`nRepositori: https://github.com/$script:GitRepo`n`nCopyright (c) 2026. Hak cipta dilindungi."
    $tab.Controls.Add($lbl)

    $btnRepo = [System.Windows.Forms.Button]::new()
    $btnRepo.Text = "Buka Repositori"
    $btnRepo.Size = [System.Drawing.Size]::new(140, 32)
    $btnRepo.Location = [System.Drawing.Point]::new(14, 220)
    $btnRepo.BackColor = [System.Drawing.Color]::FromArgb(68, 68, 72)
    $btnRepo.ForeColor = [System.Drawing.Color]::White
    $btnRepo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnRepo.FlatAppearance.BorderSize = 0
    $btnRepo.Font = [System.Drawing.Font]::new("Segoe UI", 9)
    $btnRepo.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnRepo.Add_Click({ Start-Process "https://github.com/$script:GitRepo" })
    $tab.Controls.Add($btnRepo)

    return $tab
}

# ---------------------------------------------------------------------------
# Dialog utama
# ---------------------------------------------------------------------------
function Show-OptionsDialog {
    $form = New-OptionsForm
    $tabs = [System.Windows.Forms.TabControl]::new()
    $tabs.Dock = [System.Windows.Forms.DockStyle]::Fill
    $tabs.Font = [System.Drawing.Font]::new("Segoe UI", 9)
    $tabs.Padding = [System.Drawing.Point]::new(12, 6)

    $tabs.TabPages.Add((New-ConfigTab))
    $tabs.TabPages.Add((New-BuilderTab))
    $tabs.TabPages.Add((New-TesterTab))
    $tabs.TabPages.Add((New-UpdateTab))
    $tabs.TabPages.Add((New-ChangelogTab))
    $tabs.TabPages.Add((New-AboutTab))

    $form.Controls.Add($tabs)

    # Timer global Options: polling proses build/test/update
    $timer = [System.Windows.Forms.Timer]::new()
    $timer.Interval = 300
    $timer.Add_Tick({
        # Build
        $b = $script:OptBuildState
        if ($b -and $b.Proc) {
            $text = Read-ProcLog $b
            if ($text) { $b.Box.AppendText($text); $b.Box.SelectionStart = $b.Box.TextLength; $b.Box.ScrollToCaret() }
            if ($b.Proc.HasExited) {
                $b.Box.AppendText("`n[SELESAI] Build exit code: $($b.Proc.ExitCode)`n")
                $b.Btn.Enabled = $true
                $b.Btn.Text = "Build"
                if ($b.Runner -and (Test-Path $b.Runner)) { Remove-Item $b.Runner -Force -ErrorAction SilentlyContinue }
                $script:OptBuildState = $null
            }
        }
        # Test
        $t = $script:OptTestState
        if ($t -and $t.Proc) {
            $text = Read-ProcLog $t
            if ($text) { $t.Box.AppendText($text); $t.Box.SelectionStart = $t.Box.TextLength; $t.Box.ScrollToCaret() }
            if ($t.Proc.HasExited) {
                $t.Box.AppendText("`n[SELESAI] Test exit code: $($t.Proc.ExitCode)`n")
                $t.Btn.Enabled = $true
                $t.Btn.Text = "Jalankan Test"
                if ($t.Runner -and (Test-Path $t.Runner)) { Remove-Item $t.Runner -Force -ErrorAction SilentlyContinue }
                $script:OptTestState = $null
            }
        }
        # Update check / download
        $u = $script:OptUpdState
        if ($u -and $u.Ps -and $u.Async -and $u.Async.IsCompleted) {
            $out = $null
            try { $out = $u.Ps.EndInvoke($u.Async) 2>&1 } catch { $out = $_.Exception.Message }
            try { $u.Ps.Dispose() } catch {}
            $text = ($out | Out-String).Trim()
            if ($u.Phase -eq 'check') {
                if ($text -and $text -notlike 'ERROR:*') {
                    try {
                        $rel = $text | ConvertFrom-Json
                        $script:OptUpdState.Release = $rel
                        $local = Get-AppVersion
                        $latest = ($rel.tag_name -replace '^v', '').Trim()
                        $u.Box.AppendText("[OK] Rilis terbaru: $($rel.tag_name)`n")
                        $u.Box.AppendText("[OK] Tanggal: $($rel.published_at)`n")
                        $u.Box.AppendText("[OK] Versi lokal: $local`n")
                        if ($latest -and $latest -ne $local) {
                            $u.Box.AppendText("[INFO] Update tersedia. Klik 'Unduh Update'.`n")
                        } else {
                            $u.Box.AppendText("[INFO] Aplikasi sudah versi terbaru.`n")
                        }
                    } catch {
                        $u.Box.AppendText("[ERR] Gagal membaca data rilis: $_`n")
                    }
                } else {
                    $u.Box.AppendText("[ERR] $text`n")
                }
                $u.Btn.Enabled = $true
                $u.Btn.Text = "Cek Update"
                $u.BtnDownload.Enabled = $true
            } else {
                if ($text -like 'OK:*') {
                    $u.Box.AppendText("$text`n")
                    $u.Box.AppendText("[INFO] Unduhan selesai. Tutup aplikasi lalu jalankan file yang diunduh untuk memakai versi baru.`n")
                } else {
                    $u.Box.AppendText("[ERR] $text`n")
                }
                $u.BtnDownload.Enabled = $true
                $u.BtnDownload.Text = "Unduh Update"
            }
            $script:OptUpdState.Ps = $null
            $script:OptUpdState.Async = $null
        }
    })
    $timer.Start()

    $form.Add_FormClosed({
        if ($script:OptBuildState -and $script:OptBuildState.Proc) {
            try { $script:OptBuildState.Proc.Kill() } catch {}
            if ($script:OptBuildState.Runner -and (Test-Path $script:OptBuildState.Runner)) { Remove-Item $script:OptBuildState.Runner -Force -ErrorAction SilentlyContinue }
        }
        if ($script:OptTestState -and $script:OptTestState.Proc) {
            try { $script:OptTestState.Proc.Kill() } catch {}
            if ($script:OptTestState.Runner -and (Test-Path $script:OptTestState.Runner)) { Remove-Item $script:OptTestState.Runner -Force -ErrorAction SilentlyContinue }
        }
        if ($script:OptUpdState -and $script:OptUpdState.Ps) {
            try { $script:OptUpdState.Ps.Stop() } catch {}
            try { $script:OptUpdState.Ps.Dispose() } catch {}
        }
        $timer.Dispose()
        $script:OptBuildState = $null
        $script:OptTestState = $null
        $script:OptUpdState = $null
    })

    [void]$form.ShowDialog()
}

Export-ModuleMember -Function New-OptionsButton, New-OptionsSeparator, Show-OptionsDialog, Get-AppVersion
