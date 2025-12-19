import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'mongodb_service.dart';

class AuthService {
  static AuthService? _instance;
  late MongoDBService _mongoService;
  UserModel? _currentUser;

  AuthService._();

  static Future<AuthService> getInstance() async {
    if (_instance == null) {
      _instance = AuthService._();
      try {
        _instance!._mongoService = await MongoDBService.getInstance();
        print('✅ AuthService initialized successfully');
      } catch (e) {
        print('❌ AuthService initialization failed: $e');
        _instance = null;
        rethrow;
      }
    }
    return _instance!;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
    String? businessName,
    String? description,
    String? expertise,
    String? address,
    String? country,
    List<String>? languages,
  }) async {
    try {
      final connected = await _mongoService.ensureConnected(
        timeout: const Duration(seconds: 15),
      );
      if (!connected) {
        return {
          'success': false,
          'message': 'Unable to connect to database. Please check your internet and try again.',
        };
      }

      final usersCollection = _mongoService.getUsersCollection();

      // Check if user already exists
      final existingUser = await usersCollection.findOne({'email': email});
      if (existingUser != null) {
        return {
          'success': false,
          'message': 'Email already registered',
        };
      }

      // Create user object
      final user = UserModel(
        email: email,
        password: _hashPassword(password),
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
        isVerified: false,
        businessName: businessName,
        description: description,
        expertise: expertise,
        address: address,
        country: country,
        languages: languages,
        rating: role != UserRole.tourist ? 0.0 : null,
        totalBookings: role != UserRole.tourist ? 0 : null,
      );

      // Insert to MongoDB
      final result = await usersCollection.insertOne(user.toJson());

      if (result.isSuccess) {
        // Remove password before storing
        final userWithoutPassword = user.copyWith(password: null);
        _currentUser = userWithoutPassword;
        await _saveUserSession(userWithoutPassword);

        return {
          'success': true,
          'message': 'Registration successful',
          'user': userWithoutPassword,
        };
      } else {
        return {
          'success': false,
          'message': 'Registration failed',
        };
      }
    } catch (e) {
      print('Registration Error: $e');
      return {
        'success': false,
        'message': 'An error occurred during registration',
      };
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔐 Attempting login for: $email');
      final connected = await _mongoService.ensureConnected(
        timeout: const Duration(seconds: 15),
      );
      if (!connected) {
        print('❌ Login failed: Unable to connect to database');
        return {
          'success': false,
          'message': 'Unable to connect to database. Please check your internet and try again.',
        };
      }

      final usersCollection = _mongoService.getUsersCollection();

      print('🔍 Searching for user: $email');
      final user = await usersCollection.findOne({
        'email': email,
        'password': _hashPassword(password),
      });

      if (user == null) {
        print('❌ Login failed: Invalid credentials for email: $email');
        return {
          'success': false,
          'message': 'Invalid email or password. Please check your credentials.',
        };
      }

      final userModel = UserModel.fromJson(user);
      final userWithoutPassword = userModel.copyWith(password: null);
      _currentUser = userWithoutPassword;
      await _saveUserSession(userWithoutPassword);

      print('✅ Login successful for: ${userModel.email} (${userModel.role})');
      return {
        'success': true,
        'message': 'Login successful',
        'user': userWithoutPassword,
      };
    } catch (e) {
      print('❌ Login Error: $e');
      return {
        'success': false,
        'message': 'Connection error. Please check your internet and try again.',
      };
    }
  }

  Future<void> _saveUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    await prefs.setBool('is_logged_in', true);
  }

  Future<bool> loadUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (isLoggedIn) {
        final userData = prefs.getString('user_data');
        if (userData != null) {
          _currentUser = UserModel.fromJson(jsonDecode(userData));
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Load Session Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _currentUser = null;
  }

  void updateCurrentUser(UserModel user) {
    _currentUser = user;
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
}
