import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/tourist/tourist_dashboard.dart';
import 'screens/advisor/advisor_dashboard.dart';
import 'services/auth_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const TripNexusApp());
}

class TripNexusApp extends StatelessWidget {
  const TripNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TripNexus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    print('🚀 App starting...');
    
    // Show splash for minimum time while initializing
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    try {
      print('🔄 Initializing services...');
      final authService = await AuthService.getInstance();
      final isLoggedIn = await authService.loadUserSession();
      
      if (isLoggedIn && authService.currentUser != null) {
        print('✅ User session loaded: ${authService.currentUser!.email}');
        final user = authService.currentUser!;
        
        if (!mounted) return;
        
        // Navigate to appropriate dashboard based on role
        if (user.isTourist) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TouristDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdvisorDashboard()),
          );
        }
        return; // Exit early, don't navigate to welcome screen
      }
      
      print('ℹ️ No active session, showing welcome screen');
    } catch (e) {
      print('❌ Service initialization error: $e');
      // Continue to welcome screen even if initialization fails
    }
    
    if (!mounted) return;
    
    // Only navigate to welcome screen if no active session
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3),
              Color(0xFFFF9800),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.travel_explore,
                size: 120,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'TripNexus',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
