import 'dart:io';
import 'dart:convert';

void main() async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║      Alternative: MongoDB Atlas Data API Test            ║');
  print('║      (Bypasses Direct MongoDB Connection)                 ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');

  // This tests if we can reach MongoDB Atlas via HTTPS instead of mongodb:// protocol
  print('🔍 Testing MongoDB Atlas Reachability via HTTPS...');
  print('');

  await testAtlasHTTPSConnectivity();
  await testMongoDBDirectConnection();
  await suggestSolutions();
}

Future<void> testAtlasHTTPSConnectivity() async {
  print('📡 Test 1: MongoDB Atlas HTTPS Connectivity');
  print('   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  
  final testUrls = [
    'https://cloud.mongodb.com',
    'https://www.mongodb.com/cloud/atlas',
    'https://account.mongodb.com',
  ];

  for (var url in testUrls) {
    try {
      print('   🔗 Testing: $url');
      final client = HttpClient();
      client.connectionTimeout = Duration(seconds: 10);
      
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      
      print('   ✅ Status: ${response.statusCode} - Reachable!');
      await response.drain();
      client.close();
    } catch (e) {
      print('   ❌ Failed: ${e.toString().split('\n')[0]}');
    }
  }
  print('');
}

Future<void> testMongoDBDirectConnection() async {
  print('🔌 Test 2: Direct Socket Connection to MongoDB');
  print('   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  
  // Try to get the actual IP of MongoDB servers
  print('   🔍 Attempting DNS resolution for MongoDB Atlas...');
  
  final hosts = [
    'cluster0.weglya2.mongodb.net',
    'cluster0-shard-00-00.weglya2.mongodb.net',
    'cluster0-shard-00-01.weglya2.mongodb.net',
    'cluster0-shard-00-02.weglya2.mongodb.net',
  ];

  print('');
  bool anyResolved = false;

  for (var host in hosts) {
    try {
      print('   📍 Resolving: $host');
      final addresses = await InternetAddress.lookup(host)
          .timeout(Duration(seconds: 5));
      
      if (addresses.isNotEmpty) {
        anyResolved = true;
        print('   ✅ Resolved to: ${addresses.first.address}');
        
        // Try to connect to resolved IP
        await testSocketConnection(addresses.first.address, 27017);
      }
    } catch (e) {
      print('   ❌ DNS Failed: ${e.toString().split('\n').first}');
    }
  }

  if (!anyResolved) {
    print('');
    print('   ⚠️  DNS Resolution completely blocked!');
    print('   💡 This is definitely a local network/firewall issue');
  }
  print('');
}

Future<void> testSocketConnection(String ip, int port) async {
  try {
    print('      🔌 Testing socket connection to $ip:$port...');
    final socket = await Socket.connect(ip, port, timeout: Duration(seconds: 5));
    print('      ✅ Socket connection successful!');
    await socket.close();
  } catch (e) {
    if (e.toString().contains('timed out')) {
      print('      ⏱️  Timeout - Firewall likely blocking port 27017');
    } else if (e.toString().contains('refused')) {
      print('      🚫 Connection refused');
    } else {
      print('      ❌ ${e.toString().split('\n').first}');
    }
  }
}

Future<void> suggestSolutions() async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║                    SOLUTION OPTIONS                       ║');
  print('╠═══════════════════════════════════════════════════════════╣');
  print('║                                                           ║');
  print('║  🎯 IMMEDIATE SOLUTIONS:                                  ║');
  print('║                                                           ║');
  print('║  Option 1: Fix Windows DNS/Firewall (RECOMMENDED)        ║');
  print('║  ──────────────────────────────────────────────────────   ║');
  print('║  Run as Administrator:                                    ║');
  print('║  → powershell -File fix_mongodb_windows.ps1               ║');
  print('║                                                           ║');
  print('║  Option 2: Manual Firewall Fix                           ║');
  print('║  ──────────────────────────────────────────────────────   ║');
  print('║  1. Open Windows Defender Firewall                        ║');
  print('║  2. Advanced Settings → Outbound Rules → New Rule         ║');
  print('║  3. Port → TCP → Specific: 27017                          ║');
  print('║  4. Allow Connection → Apply to all profiles              ║');
  print('║                                                           ║');
  print('║  Option 3: Change Network                                ║');
  print('║  ──────────────────────────────────────────────────────   ║');
  print('║  • Try mobile hotspot (bypasses corporate firewall)       ║');
  print('║  • Disable VPN if using one                               ║');
  print('║  • Use different WiFi network                             ║');
  print('║                                                           ║');
  print('║  Option 4: MongoDB Atlas Configuration                   ║');
  print('║  ──────────────────────────────────────────────────────   ║');
  print('║  1. Go to: https://cloud.mongodb.com                      ║');
  print('║  2. Network Access → Add IP Address                       ║');
  print('║  3. Add: 0.0.0.0/0 (Allow from anywhere)                  ║');
  print('║  4. Wait 2-3 minutes for changes to apply                 ║');
  print('║                                                           ║');
  print('║  Option 5: Test in Flutter App                           ║');
  print('║  ──────────────────────────────────────────────────────   ║');
  print('║  Mobile apps use different network stack:                 ║');
  print('║  → flutter run                                            ║');
  print('║  → Try login/signup (may work despite desktop test fail)  ║');
  print('║                                                           ║');
  print('║  ⚡ QUICK TEST:                                           ║');
  print('║  Try running the app on your phone/emulator - it often    ║');
  print('║  works even when desktop tests fail!                      ║');
  print('║                                                           ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');
  print('📱 Next Command to Try:');
  print('   → Run: flutter run');
  print('   → Or: powershell -ExecutionPolicy Bypass -File fix_mongodb_windows.ps1');
  print('');
}
