# MongoDB Atlas Connection Fix for Windows
# Run this script as Administrator

Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     MongoDB Atlas Windows Connection Fixer               ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ Error: This script must be run as Administrator" -ForegroundColor Red
    Write-Host ""
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green
Write-Host ""

# Step 1: Flush DNS Cache
Write-Host "🔄 Step 1: Flushing DNS Cache..." -ForegroundColor Yellow
try {
    ipconfig /flushdns | Out-Null
    Write-Host "   ✅ DNS Cache flushed successfully" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed to flush DNS cache: $_" -ForegroundColor Red
}
Write-Host ""

# Step 2: Add Windows Firewall Rules for MongoDB
Write-Host "🔧 Step 2: Adding Windows Firewall Rules..." -ForegroundColor Yellow
try {
    # Remove existing rules if any
    Remove-NetFirewallRule -DisplayName "MongoDB Atlas Outbound" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "MongoDB Atlas Outbound SSL" -ErrorAction SilentlyContinue
    
    # Add new rules
    New-NetFirewallRule -DisplayName "MongoDB Atlas Outbound" `
        -Direction Outbound `
        -Action Allow `
        -Protocol TCP `
        -RemotePort 27017 `
        -Program "C:\Program Files\Dart\dart.exe" `
        -ErrorAction SilentlyContinue | Out-Null
    
    New-NetFirewallRule -DisplayName "MongoDB Atlas Outbound SSL" `
        -Direction Outbound `
        -Action Allow `
        -Protocol TCP `
        -RemotePort 27017,443 `
        -ErrorAction SilentlyContinue | Out-Null
    
    Write-Host "   ✅ Firewall rules added successfully" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Firewall rules partially added: $_" -ForegroundColor Yellow
}
Write-Host ""

# Step 3: Reset Network Settings
Write-Host "🌐 Step 3: Resetting Network Settings..." -ForegroundColor Yellow
try {
    netsh winsock reset | Out-Null
    Write-Host "   ✅ Winsock reset successful" -ForegroundColor Green
    Write-Host "   ⚠️  Note: May require system restart" -ForegroundColor Yellow
} catch {
    Write-Host "   ❌ Failed to reset winsock: $_" -ForegroundColor Red
}
Write-Host ""

# Step 4: Configure DNS Settings
Write-Host "🔍 Step 4: DNS Configuration Check..." -ForegroundColor Yellow
$adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
foreach ($adapter in $adapters) {
    Write-Host "   📡 Adapter: $($adapter.Name)" -ForegroundColor Cyan
    $dns = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4
    Write-Host "      Current DNS: $($dns.ServerAddresses -join ', ')" -ForegroundColor Gray
}
Write-Host ""
Write-Host "   💡 If DNS issues persist, add Google DNS (8.8.8.8, 8.8.4.4)" -ForegroundColor Yellow
Write-Host ""

# Step 5: Test MongoDB Connectivity
Write-Host "🧪 Step 5: Testing MongoDB Connectivity..." -ForegroundColor Yellow
Write-Host "   Running diagnostic..." -ForegroundColor Gray
Write-Host ""

# Change to script directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# Run the test
dart test_mongodb_connection.dart

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                   FIX COMPLETE                            ║" -ForegroundColor Cyan
Write-Host "╠═══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "║  If connection still fails, try:                          ║" -ForegroundColor White
Write-Host "║  1. Restart your computer                                 ║" -ForegroundColor White
Write-Host "║  2. Disable antivirus temporarily                         ║" -ForegroundColor White
Write-Host "║  3. Check MongoDB Atlas IP whitelist                      ║" -ForegroundColor White
Write-Host "║  4. Try using mobile hotspot (bypass network firewall)    ║" -ForegroundColor White
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
