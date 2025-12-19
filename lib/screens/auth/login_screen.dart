import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../tourist/tourist_dashboard.dart';
import '../advisor/advisor_dashboard.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  DateTime? _lastTapTime;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Prevent multiple rapid taps (debouncing)
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) < const Duration(seconds: 2)) {
      print('⏱️ Login already in progress, ignoring tap');
      return;
    }
    _lastTapTime = now;

    if (!_formKey.currentState!.validate()) {
      _lastTapTime = null;
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      print('🔐 Attempting login for: ${_emailController.text.trim()}');
      final authService = await AuthService.getInstance();
      final result = await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        print('✅ Login successful, navigating to dashboard...');
        final user = result['user'] as UserModel;
        
        // Navigate based on user role
        if (user.isTourist) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const TouristDashboard(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdvisorDashboard(),
            ),
          );
        }
      } else {
        print('❌ Login failed: ${result['message']}');
        _showError(result['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('❌ Login exception: $e');
      String errorMessage = 'Connection error. Please check your internet and try again.';
      
      if (e.toString().contains('LateInitializationError')) {
        errorMessage = 'App initialization error. Please restart the app.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error. Please check your connection.';
      }
      
      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _lastTapTime = null;
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(AppConfig.errorColor),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Color(AppConfig.primaryColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Icon(
                  Icons.login_rounded,
                  size: 80,
                  color: Color(AppConfig.primaryColor),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome Back!',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConfig.textPrimaryColor),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue your journey',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Color(AppConfig.textSecondaryColor),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                    },
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.poppins(
                        color: Color(AppConfig.primaryColor),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(AppConfig.primaryColor),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Login',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(
                        color: Color(AppConfig.textSecondaryColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.poppins(
                          color: Color(AppConfig.primaryColor),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
