<#
.SYNOPSIS
    Tool: Network Diagnostics
    Ping, tracert, nslookup, port check and other network diagnostics
#>

$menuName = "Network Management"
$toolName = "NetworkManagement"
$toolCategory = "Network"

$fields = @(
    @{ Name = "Action"; Type = "Combo"; Default = "Ping"; Label = "Action"; Options = @(
        'Ping', 'Tracert', 'PathPing', 'Nslookup', 'DNS Lookup All', 'Port Check',
        'IP Config', 'Netstat', 'ARP Table', 'Flush DNS', 'Full Diagnostics'
    ) }
    @{ Name = "Host"; Type = "Text"; Default = "8.8.8.8"; Label = "Host / IP" }
    @{ Name = "Port"; Type = "Text"; Default = "80";      Label = "Port" }
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

    $action = $params['Action']
    $host = $params['Host']
    $port = $params['Port']

    if ([string]::IsNullOrWhiteSpace($host)) { $host = '8.8.8.8' }

    switch ($action) {
        'Ping' {
            Write-Output "Ping $host ..."
            Invoke-Cmd "ping $host"
        }
        'Tracert' {
            Write-Output "Tracert -d $host ..."
            Invoke-Cmd "tracert -d $host"
        }
        'PathPing' {
            Write-Output "PathPing -n -h 10 $host ..."
            Invoke-Cmd "pathping -n -h 10 $host"
        }
        'Nslookup' {
            Write-Output "Nslookup $host ..."
            Invoke-Cmd "nslookup $host"
        }
        'DNS Lookup All' {
            Write-Output "DNS lookup semua record untuk $host ..."
            foreach ($t in @('A', 'AAAA', 'MX', 'NS', 'TXT', 'CNAME')) {
                Write-Output "--- $t ---"
                Invoke-Cmd "nslookup -type=$t $host"
            }
        }
        'Port Check' {
            if (-not $port) { $port = '80' }
            Write-Output "Memeriksa port $port pada $host ..."
            try {
                $r = Test-NetConnection -ComputerName $host -Port ([int]$port) -WarningAction SilentlyContinue
                if ($r.TcpTestSucceeded) {
                    Write-Output "RESULT: Port $port pada $host TERBUKA (open)."
                } else {
                    Write-Output "RESULT: Port $port pada $host TERTUTUP / tidak dapat diakses."
                }
                if ($r.RemoteAddress) { Write-Output "Remote address: $($r.RemoteAddress)" }
                if ($r.PingSucceeded) { Write-Output "Ping: sukses" } else { Write-Output "Ping: gagal/diblokir" }
            } catch {
                Write-Output "ERROR: $_"
            }
        }
        'IP Config' {
            Invoke-Cmd "ipconfig /all"
        }
        'Netstat' {
            Write-Output "Netstat -ano (koneksi aktif)..."
            Invoke-Cmd "netstat -ano"
        }
        'ARP Table' {
            Invoke-Cmd "arp -a"
        }
        'Flush DNS' {
            Invoke-Cmd "ipconfig /flushdns"
            Write-Output "DNS cache berhasil di-flush."
        }
        'Full Diagnostics' {
            Write-Output "========== NETWORK DIAGNOSTICS: $host =========="
            Write-Output "--- IP Configuration ---"
            Invoke-Cmd "ipconfig /all"
            Write-Output "--- Ping $host ---"
            Invoke-Cmd "ping $host"
            Write-Output "--- Nslookup $host ---"
            Invoke-Cmd "nslookup $host"
            if ($port) {
                Write-Output "--- Port Check ${host}:${port} ---"
                try {
                    $r = Test-NetConnection -ComputerName $host -Port ([int]$port) -WarningAction SilentlyContinue
                    Write-Output "Port ${port}: $(if ($r.TcpTestSucceeded) { 'TERBUKA' } else { 'TERTUTUP' })"
                } catch { Write-Output "Port check gagal: $_" }
            }
            Write-Output "--- Netstat (active connections) ---"
            Invoke-Cmd "netstat -ano"
            Write-Output "--- ARP Table ---"
            Invoke-Cmd "arp -a"
            Write-Output "========== SELESAI =========="
        }
        default {
            Write-Output "Aksi tidak dikenal: $action"
        }
    }
}

Export-ModuleMember -Function Get-ToolConfig, Invoke-ToolAction
