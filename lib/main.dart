import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/tourist/tourist_dashboard.dart';
import 'screens/advisor/advisor_dashboard.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/weather_notification_service.dart';
import 'services/news_notification_service.dart';
import 'services/mongodb_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Performance optimizations
  // Enable hardware rendering
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Lock orientation for better performance
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

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _introController;
  late AnimationController _ambientController;
  late Animation<double> _logoAnim;
  late Animation<double> _textAnim;
  late Animation<double> _statusAnim;
  late Animation<double> _ambientPulse;

  String _statusText = 'Initializing...';

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _logoAnim = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    );
    _textAnim = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.3, 0.78, curve: Curves.easeOutCubic),
    );
    _statusAnim = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.58, 1.0, curve: Curves.easeInOut),
    );
    _ambientPulse = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOut),
    );

    _introController.forward();
    _checkAuthentication();
  }

  @override
  void dispose() {
    _introController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _setStatus(String text) {
    if (mounted) setState(() => _statusText = text);
  }

  Future<void> _checkAuthentication() async {
    final startTime = DateTime.now();

    try {
      _setStatus('Starting up...');
      await Future.wait<dynamic>([
        NotificationService.getInstance().initialize(),
        WeatherNotificationService.getInstance().initialize(),
        NewsNotificationService.getInstance().initialize(),
        AuthService.getInstance(),
      ]);

      _setStatus('Loading session...');
      final authService = await AuthService.getInstance();
      final isLoggedIn = await authService.loadUserSession();

      _setStatus('Ready!');
      MongoDBService.getInstance().then(
        (s) => s.ensureConnected(timeout: const Duration(seconds: 12)),
      );

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsed < 900) {
        await Future.delayed(Duration(milliseconds: 900 - elapsed));
      }

      if (!mounted) return;

      if (isLoggedIn && authService.currentUser != null) {
        final user = authService.currentUser!;
        _navigateTo(
          user.isTourist ? const TouristDashboard() : const AdvisorDashboard(),
        );
        return;
      }
    } catch (e) {
      debugPrint('Startup error: $e');
      _setStatus('Starting offline...');
      await Future.delayed(const Duration(milliseconds: 600));
    }

    if (!mounted) return;
    _navigateTo(const WelcomeScreen());
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
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
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF041D4D),
                  Color(0xFF0A3F88),
                  Color(0xFF1667C9),
                ],
              ),
            ),
          ),
          Positioned(
            top: -180,
            right: -70,
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _ambientPulse.value,
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.22),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -120,
            left: -90,
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.08 - (_ambientPulse.value - 1.0),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF7FD6FF).withValues(alpha: 0.2),
                          const Color(0xFF7FD6FF).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.18),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _logoAnim,
                  child: FadeTransition(
                    opacity: _logoAnim,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _ambientController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _ambientController.value * 0.5,
                              child: Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(48),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Container(
                          width: 172,
                          height: 172,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.36),
                                Colors.white.withValues(alpha: 0.1),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1.3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/tripnexus.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _textAnim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.24),
                      end: Offset.zero,
                    ).animate(_textAnim),
                    child: Column(
                      children: [
                        const Text(
                          'TripNexus',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 2.2,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.white.withValues(alpha: 0.12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            'Your Journey Begins Here',
                            style: TextStyle(
                              fontSize: 13.8,
                              color: Colors.white.withValues(alpha: 0.9),
                              letterSpacing: 0.45,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 64),
                FadeTransition(
                  opacity: _statusAnim,
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: Text(
                            _statusText,
                            key: ValueKey(_statusText),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
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
