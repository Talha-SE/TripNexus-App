import 'package:mongo_dart/mongo_dart.dart';
import '../config/app_config.dart';

class MongoDBService {
  static MongoDBService? _instance;
  static Db? _db;
  static bool _isConnecting = false;

  MongoDBService._();

  static Future<MongoDBService> getInstance() async {
    _instance ??= MongoDBService._();
    return _instance!;
  }

  Future<bool> ensureConnected({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    // If already connected, return immediately
    if (_db != null && _db!.isConnected) {
      print('✅ MongoDB Already Connected');
      return true;
    }

    // If another connection attempt is in progress, wait for it
    if (_isConnecting) {
      print('⏳ Waiting for ongoing connection...');
      int waitCount = 0;
      while (_isConnecting && waitCount < 30) {
        await Future.delayed(const Duration(milliseconds: 500));
        waitCount++;
        if (_db != null && _db!.isConnected) {
          return true;
        }
      }
    }

    // Try to connect with retries
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        await _connect().timeout(timeout);
        if (_db != null && _db!.isConnected) {
          return true;
        }
      } catch (e) {
        print('❌ MongoDB ensureConnected failed (attempt $attempt): $e');
        if (attempt < 3) {
          await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }

    return false;
  }

  Future<void> _connect() async {
    if (_isConnecting) {
      return;
    }

    _isConnecting = true;

    try {
      // Double-check connection status
      if (_db != null && _db!.isConnected) {
        print('✅ MongoDB Already Connected');
        _isConnecting = false;
        return;
      }

      // Close existing connection if any
      if (_db != null) {
        try {
          await _db!.close();
        } catch (e) {
          print('⚠️ Error closing old connection: $e');
        }
        _db = null;
      }

      print('🔄 Connecting to MongoDB...');

      _db = await Db.create(AppConfig.mongoDbConnectionString);

      await _db!.open(secure: true);

      // Verify connection with a simple command
      await _db!.serverStatus();

      print('✅ MongoDB Connected Successfully');
    } catch (e) {
      print('❌ MongoDB Connection Error: $e');
      _db = null;
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> disconnect() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      print('MongoDB Disconnected');
    }
  }

  DbCollection getUsersCollection() {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Database not connected');
    }
    return _db!.collection(AppConfig.usersCollection);
  }

  DbCollection getTripsCollection() {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Database not connected');
    }
    return _db!.collection(AppConfig.tripsCollection);
  }

  DbCollection getAdvisorsCollection() {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Database not connected');
    }
    return _db!.collection(AppConfig.advisorsCollection);
  }

  DbCollection getBookingsCollection() {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Database not connected');
    }
    return _db!.collection(AppConfig.bookingsCollection);
  }

  DbCollection getPackagesCollection() {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Database not connected');
    }
    return _db!.collection(AppConfig.packagesCollection);
  }

  DbCollection getSavedLandmarksCollection() {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Database not connected');
    }
    return _db!.collection('saved_landmarks');
  }

  DbCollection getSavedTripPlansCollection() {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Database not connected');
    }
    return _db!.collection('saved_trip_plans');
  }

  DbCollection getPackageMessagesCollection() {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Database not connected');
    }
    return _db!.collection('package_messages');
  }

  DbCollection getPackageBookingsCollection() {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Database not connected');
    }
    return _db!.collection('package_bookings');
  }

  DbCollection getBlockchainReviewsCollection() {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Database not connected');
    }
    return _db!.collection(AppConfig.blockchainReviewsCollection);
  }

  bool get isConnected => _db != null && _db!.isConnected;
}
