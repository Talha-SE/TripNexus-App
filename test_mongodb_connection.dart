import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║   TripNexus - MongoDB Connection Diagnostic Tool         ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');

  final connectionString = 'mongodb+srv://rtalhaonline_db_user:VFQm6yonboNbUmNB@cluster0.weglya2.mongodb.net/?appName=Cluster0';
  final dbName = 'tripnexus_db';

  // Test 1: Basic Internet Connectivity
  await testInternetConnection();

  // Test 2: DNS Resolution with Multiple Methods
  await testDNSResolution();

  // Test 3: MongoDB Connection with Different Approaches
  await testMongoDBConnection(connectionString, dbName);

  // Test 4: Alternative Connection Strings
  await testAlternativeConnections(dbName);

  print('\n╔═══════════════════════════════════════════════════════════╗');
  print('║                    DIAGNOSTIC COMPLETE                    ║');
  print('╚═══════════════════════════════════════════════════════════╝');
}

Future<void> testInternetConnection() async {
  print('🌐 Test 1: Internet Connectivity Check');
  print('   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print('   ✅ Internet: WORKING');
      print('   📍 Google DNS resolved to: ${result[0].address}');
    }
  } catch (e) {
    print('   ❌ Internet: FAILED - $e');
  }
  print('');
}

Future<void> testDNSResolution() async {
  print('🔍 Test 2: DNS Resolution Tests');
  print('   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  final hostsToTest = [
    'cluster0.weglya2.mongodb.net',
    'mongodb.net',
    'atlas.mongodb.com',
  ];

  for (var host in hostsToTest) {
    try {
      print('   🔎 Resolving: $host');
      final result = await InternetAddress.lookup(host)
          .timeout(Duration(seconds: 10));
      
      if (result.isNotEmpty) {
        print('   ✅ $host resolved successfully!');
        for (var addr in result.take(3)) {
          print('      → IP: ${addr.address}');
        }
      }
    } catch (e) {
      print('   ❌ $host: FAILED');
      print('      Error: ${e.toString().split('\n')[0]}');
    }
  }
  print('');
}

Future<void> testMongoDBConnection(String connectionString, String dbName) async {
  print('🔌 Test 3: MongoDB Connection Attempts');
  print('   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  // Attempt 1: Standard SRV Connection
  print('   📡 Attempt 1: Standard SRV Connection');
  await _attemptConnection(connectionString, dbName, '1');

  print('');
  
  // Attempt 2: Direct MongoDB URI (without SRV)
  print('   📡 Attempt 2: Direct Connection (without SRV)');
  final directUri = 'mongodb://rtalhaonline_db_user:VFQm6yonboNbUmNB@cluster0-shard-00-00.weglya2.mongodb.net:27017,cluster0-shard-00-01.weglya2.mongodb.net:27017,cluster0-shard-00-02.weglya2.mongodb.net:27017/$dbName?ssl=true&replicaSet=atlas-xxxx-shard-0&authSource=admin&retryWrites=true&w=majority';
  await _attemptConnection(directUri, dbName, '2');

  print('');

  // Attempt 3: With Increased Timeout
  print('   📡 Attempt 3: Extended Timeout (30 seconds)');
  await _attemptConnectionWithTimeout(connectionString, dbName, Duration(seconds: 30));

  print('');
}

Future<void> _attemptConnection(String uri, String dbName, String attemptNumber) async {
  Db? db;
  try {
    print('   ⏳ Connecting...');
    db = await Db.create(uri);
    
    await db.open(secure: true);
    
    print('   ✅ Connection SUCCESSFUL!');
    
    // Test database operations
    print('   📊 Testing database operations...');
    await db.serverStatus();
    print('   ✅ Server status check: PASSED');
    
    // List collections
    final collections = await db.getCollectionNames();
    print('   📁 Collections found: ${collections.length}');
    for (var col in collections.take(5)) {
      print('      • $col');
    }
    
    // Test users collection
    final usersCollection = db.collection('users');
    final userCount = await usersCollection.count();
    print('   👥 Users in database: $userCount');
    
    await db.close();
    print('   ✅ Database connection is FULLY FUNCTIONAL!');
    
  } catch (e) {
    print('   ❌ Connection FAILED');
    if (e.toString().contains('Failed host lookup')) {
      print('   ⚠️  DNS Resolution Error');
      print('   💡 This is likely a Windows DNS/Firewall issue');
    } else if (e.toString().contains('HandshakeException')) {
      print('   ⚠️  SSL/TLS Handshake Error');
      print('   💡 Certificate or firewall blocking SSL');
    } else if (e.toString().contains('SocketException')) {
      print('   ⚠️  Network Socket Error');
      print('   💡 Firewall or network blocking connection');
    } else if (e.toString().contains('TimeoutException')) {
      print('   ⚠️  Connection Timeout');
      print('   💡 MongoDB Atlas might be unreachable');
    }
    print('   📝 Full error: ${e.toString().split('\n')[0]}');
  } finally {
    if (db != null && db.isConnected) {
      await db.close();
    }
  }
}

Future<void> _attemptConnectionWithTimeout(String uri, String dbName, Duration timeout) async {
  Db? db;
  try {
    print('   ⏳ Connecting with ${timeout.inSeconds}s timeout...');
    
    db = await Db.create(uri);
    await db.open(secure: true).timeout(timeout);
    
    print('   ✅ Connection SUCCESSFUL!');
    
    await db.serverStatus().timeout(Duration(seconds: 10));
    print('   ✅ Server responsive');
    
    await db.close();
    
  } catch (e) {
    print('   ❌ Connection FAILED: ${e.toString().split('\n')[0]}');
  } finally {
    if (db != null && db.isConnected) {
      try {
        await db.close();
      } catch (_) {}
    }
  }
}

Future<void> testAlternativeConnections(String dbName) async {
  print('🔧 Test 4: Alternative Connection Methods');
  print('   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  // Try with explicit MongoDB nodes
  final alternativeUris = [
    // Standard MongoDB protocol with all replica set members
    'mongodb://rtalhaonline_db_user:VFQm6yonboNbUmNB@cluster0-shard-00-00.weglya2.mongodb.net:27017,cluster0-shard-00-01.weglya2.mongodb.net:27017,cluster0-shard-00-02.weglya2.mongodb.net:27017/$dbName?ssl=true&authSource=admin',
    
    // With different SSL options
    'mongodb+srv://rtalhaonline_db_user:VFQm6yonboNbUmNB@cluster0.weglya2.mongodb.net/$dbName?retryWrites=true&w=majority',
  ];

  for (var i = 0; i < alternativeUris.length; i++) {
    print('\n   🔄 Alternative ${i + 1}:');
    await _attemptConnection(alternativeUris[i], dbName, 'Alt-${i + 1}');
  }

  print('\n');
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║                  TROUBLESHOOTING TIPS                     ║');
  print('╠═══════════════════════════════════════════════════════════╣');
  print('║                                                           ║');
  print('║  If DNS resolution is failing:                            ║');
  print('║  1. Check Windows Firewall settings                       ║');
  print('║  2. Try disabling VPN temporarily                         ║');
  print('║  3. Check if antivirus is blocking connections            ║');
  print('║  4. Try: ipconfig /flushdns in PowerShell                 ║');
  print('║  5. Add MongoDB Atlas IPs to firewall whitelist           ║');
  print('║                                                           ║');
  print('║  Windows Firewall Quick Fix:                              ║');
  print('║  • Run PowerShell as Administrator                        ║');
  print('║  • Execute: New-NetFirewallRule -DisplayName "MongoDB"    ║');
  print('║    -Direction Outbound -Action Allow -Protocol TCP        ║');
  print('║    -RemotePort 27017                                      ║');
  print('║                                                           ║');
  print('║  Check MongoDB Atlas:                                     ║');
  print('║  • Verify IP whitelist includes 0.0.0.0/0                 ║');
  print('║  • Check cluster is running (not paused)                  ║');
  print('║  • Verify credentials are correct                         ║');
  print('║                                                           ║');
  print('╚═══════════════════════════════════════════════════════════╝');
}
