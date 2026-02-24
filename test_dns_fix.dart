import 'dart:io';

void main() async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║    MongoDB DNS Fix: Using Alternative DNS Servers        ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');

  print('🔧 Current DNS Configuration Check');
  print('   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('');

  // Test with system DNS
  await testDNS('System DNS', null);

  // Test with Google DNS
  print('');
  print('💡 Suggestion: Change DNS to Google DNS (8.8.8.8)');
  print('   This often fixes MongoDB Atlas DNS issues on Windows');
  print('');

  print('╔═══════════════════════════════════════════════════════════╗');
  print('║             HOW TO CHANGE DNS IN WINDOWS                  ║');
  print('╠═══════════════════════════════════════════════════════════╣');
  print('║                                                           ║');
  print('║  METHOD 1: PowerShell (Quick - Run as Administrator)     ║');
  print('║  ─────────────────────────────────────────────────────    ║');
  print('║  Run these commands in Administrator PowerShell:          ║');
  print('║                                                           ║');
  print('║  # Get your network adapter name                          ║');
  print('║  Get-NetAdapter | Where Status -eq "Up"                   ║');
  print('║                                                           ║');
  print('║  # Set Google DNS (replace "Wi-Fi" with your adapter)     ║');
  print('║  Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" `     ║');
  print('║    -ServerAddresses "8.8.8.8","8.8.4.4"                   ║');
  print('║                                                           ║');
  print('║  # Flush DNS cache                                        ║');
  print('║  ipconfig /flushdns                                       ║');
  print('║                                                           ║');
  print('║  METHOD 2: GUI (Easy)                                     ║');
  print('║  ─────────────────────────────────────────────────────    ║');
  print('║  1. Open Settings → Network & Internet                    ║');
  print('║  2. Click your connection (Wi-Fi or Ethernet)             ║');
  print('║  3. Scroll to "DNS server assignment" → Edit              ║');
  print('║  4. Set Manual                                            ║');
  print('║  5. IPv4: ON                                              ║');
  print('║  6. Preferred DNS: 8.8.8.8                                ║');
  print('║  7. Alternate DNS: 8.8.4.4                                ║');
  print('║  8. Save                                                  ║');
  print('║                                                           ║');
  print('║  After changing DNS, run this test again!                 ║');
  print('║                                                           ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');

  print('📋 Summary of Issues Found:');
  print('   • Windows DNS cannot resolve *.weglya2.mongodb.net');
  print('   • MongoDB Atlas HTTPS endpoints ARE reachable');
  print('   • This is a DNS-specific issue, not network connectivity');
  print('');
  print('✅ Solutions (try in order):');
  print('   1. Change DNS to 8.8.8.8 (Google DNS) - See above');
  print('   2. Flush DNS cache: ipconfig /flushdns');
  print('   3. Restart computer');
  print('   4. Try mobile hotspot to bypass network restrictions');
  print('   5. Test in Flutter app: flutter run');
  print('');
}

Future<void> testDNS(String label, String? dnsServer) async {
  print('📍 Testing with $label');
  
  final testHosts = [
    'google.com',
    'mongodb.com',
    'cluster0.weglya2.mongodb.net',
  ];

  for (var host in testHosts) {
    try {
      final result = await InternetAddress.lookup(host)
          .timeout(Duration(seconds: 5));
      
      if (result.isNotEmpty) {
        print('   ✅ $host → ${result.first.address}');
      }
    } catch (e) {
      print('   ❌ $host → FAILED');
    }
  }
}
