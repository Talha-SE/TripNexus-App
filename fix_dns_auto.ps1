# Auto-Fix MongoDB DNS Issues on Windows
# Run as Administrator

Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         MongoDB DNS Auto-Fix for Windows                 ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ Must run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell → Run as Administrator" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green
Write-Host ""

# Step 1: Get active network adapters
Write-Host "🔍 Step 1: Detecting Network Adapters..." -ForegroundColor Yellow
$adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}

if ($adapters.Count -eq 0) {
    Write-Host "❌ No active network adapters found!" -ForegroundColor Red
    pause
    exit 1
}

Write-Host "   Found $($adapters.Count) active adapter(s):" -ForegroundColor Green
foreach ($adapter in $adapters) {
    Write-Host "   • $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Cyan
}
Write-Host ""

# Step 2: Backup current DNS settings
Write-Host "💾 Step 2: Backing up current DNS settings..." -ForegroundColor Yellow
$backupFile = "dns_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
foreach ($adapter in $adapters) {
    $dns = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4
    "$($adapter.Name): $($dns.ServerAddresses -join ',')" | Out-File -Append $backupFile
}
Write-Host "   ✅ Backup saved to: $backupFile" -ForegroundColor Green
Write-Host ""

# Step 3: Set Google DNS
Write-Host "🌐 Step 3: Setting Google DNS (8.8.8.8, 8.8.4.4)..." -ForegroundColor Yellow
foreach ($adapter in $adapters) {
    try {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex `
            -ServerAddresses "8.8.8.8","8.8.4.4" -ErrorAction Stop
        Write-Host "   ✅ DNS updated for: $($adapter.Name)" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  Failed for $($adapter.Name): $_" -ForegroundColor Yellow
    }
}
Write-Host ""

# Step 4: Flush DNS cache
Write-Host "🔄 Step 4: Flushing DNS Cache..." -ForegroundColor Yellow
try {
    ipconfig /flushdns | Out-Null
    Write-Host "   ✅ DNS Cache flushed" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed to flush DNS" -ForegroundColor Red
}
Write-Host ""

# Step 5: Register DNS
Write-Host "📝 Step 5: Registering DNS..." -ForegroundColor Yellow
try {
    ipconfig /registerdns | Out-Null
    Write-Host "   ✅ DNS Registered" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  DNS registration warning (non-critical)" -ForegroundColor Yellow
}
Write-Host ""

# Step 6: Wait and test
Write-Host "⏳ Waiting 5 seconds for DNS changes to propagate..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
Write-Host ""

# Step 7: Test DNS resolution
Write-Host "🧪 Step 6: Testing MongoDB DNS Resolution..." -ForegroundColor Yellow
Write-Host "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

$testHosts = @(
    "google.com",
    "mongodb.com", 
    "cluster0.weglya2.mongodb.net"
)

$allSuccess = $true
foreach ($host in $testHosts) {
    try {
        $result = [System.Net.Dns]::GetHostAddresses($host)
        if ($result.Count -gt 0) {
            Write-Host "   ✅ $host → $($result[0].IPAddressToString)" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ❌ $host → FAILED" -ForegroundColor Red
        $allSuccess = $false
    }
}
Write-Host ""

if ($allSuccess) {
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                  ✅ DNS FIX SUCCESSFUL!                   ║" -ForegroundColor Green
    Write-Host "╠═══════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "║                                                           ║" -ForegroundColor White
    Write-Host "║  MongoDB Atlas DNS is now resolving correctly!            ║" -ForegroundColor White
    Write-Host "║                                                           ║" -ForegroundColor White
    Write-Host "║  Next step:                                               ║" -ForegroundColor White
    Write-Host "║  → dart test_mongodb_connection.dart                      ║" -ForegroundColor Cyan
    Write-Host "║                                                           ║" -ForegroundColor White
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
} else {
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║              ⚠️  PARTIAL SUCCESS                          ║" -ForegroundColor Yellow
    Write-Host "╠═══════════════════════════════════════════════════════════╣" -ForegroundColor Yellow
    Write-Host "║                                                           ║" -ForegroundColor White
    Write-Host "║  DNS changed to Google DNS, but some hosts still fail.    ║" -ForegroundColor White
    Write-Host "║                                                           ║" -ForegroundColor White
    Write-Host "║  Additional steps to try:                                 ║" -ForegroundColor White
    Write-Host "║  1. Restart your computer                                 ║" -ForegroundColor White
    Write-Host "║  2. Disable Windows Firewall temporarily                  ║" -ForegroundColor White
    Write-Host "║  3. Check antivirus/security software                     ║" -ForegroundColor White
    Write-Host "║  4. Try mobile hotspot                                    ║" -ForegroundColor White
    Write-Host "║  5. Test in Flutter app anyway: flutter run               ║" -ForegroundColor Cyan
    Write-Host "║                                                           ║" -ForegroundColor White
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "💡 To restore original DNS settings, run:" -ForegroundColor Cyan
Write-Host "   Set-DnsClientServerAddress -InterfaceAlias `"Your-Adapter`" -ResetServerAddresses" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to run MongoDB connection test..." -ForegroundColor Yellow
pause

# Run the connection test
Write-Host ""
Write-Host "🧪 Running MongoDB Connection Test..." -ForegroundColor Cyan
Write-Host ""
dart test_mongodb_connection.dart

Write-Host ""
Write-Host "Script complete! Check results above." -ForegroundColor Cyan
pause
