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

  await ThemeController.loadThemeMode();
  
  runApp(const TripNexusApp());
}

class TripNexusApp extends StatelessWidget {
  const TripNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'TripNexus',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
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
    
    final startTime = DateTime.now();
    
    try {
      print('🔄 Initializing services...');
      // Start initialization immediately
      final authServiceFuture = AuthService.getInstance();
      
      // Load user session
      final authService = await authServiceFuture;
      final isLoggedIn = await authService.loadUserSession();
      
      // Ensure splash shows for at least 1500ms for branding, but no more if ready
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsed < 1500) {
        await Future.delayed(Duration(milliseconds: 1500 - elapsed));
      }
      
      if (!mounted) return;
      
      if (isLoggedIn && authService.currentUser != null) {
        print('✅ User session loaded: ${authService.currentUser!.email}');
        final user = authService.currentUser!;
        
        _navigateTo(user.isTourist ? const TouristDashboard() : const AdvisorDashboard());
        return;
      }
      
      print('ℹ️ No active session, showing welcome screen');
    } catch (e) {
      print('❌ Service initialization error: $e');
    }
    
    if (!mounted) return;
    _navigateTo(const WelcomeScreen());
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2196F3),
                  Color(0xFF1976D2),
                  Color(0xFF1565C0),
                ],
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.travel_explore_rounded,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      const Text(
                        'TripNexus',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Your Journey Begins Here',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.5,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}