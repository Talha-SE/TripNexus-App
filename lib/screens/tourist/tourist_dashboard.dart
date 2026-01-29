import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_drawer.dart';
import '../auth/welcome_screen.dart';
import 'create_trip_screen.dart';
import 'trips_list_screen.dart';
import 'landmark_scanner_screen.dart';
import 'advisors_search_screen.dart';
import 'weather_screen.dart';
import 'profile_screen.dart';
import 'ai_trip_planner_screen.dart';
import 'saved_landmarks_screen.dart';
import 'saved_trip_plans_screen.dart';
import 'news_screen.dart';

class TouristDashboard extends StatefulWidget {
  const TouristDashboard({Key? key}) : super(key: key);

  @override
  State<TouristDashboard> createState() => _TouristDashboardState();
}

class _TouristDashboardState extends State<TouristDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _handleLogout() async {
    final authService = await AuthService.getInstance();
    await authService.logout();
    
    if (!mounted) return;
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Widget _buildDashboardContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey<int>(_selectedIndex),
        child: _getContentForIndex(_selectedIndex),
      ),
    );
  }

  Widget _getContentForIndex(int index) {
    switch (index) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildTripsTab();
      case 2:
        return _buildExploreTab();
      case 3:
        return const WeatherScreen();
      case 4:
        return const NewsScreen();
      case 5:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Quick Actions', null),
                const SizedBox(height: 16),
                _buildQuickActions(),
                const SizedBox(height: 32),
                _buildSectionHeader('AI-Powered Features', () {}),
                const SizedBox(height: 16),
                _buildAIFeatures(),
                const SizedBox(height: 32),
                _buildSectionHeader('Recent Trips', () {}),
                const SizedBox(height: 16),
                _buildRecentTrips(),
                const SizedBox(height: 100), // Extra space for bottom nav
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: 0.5,
          ),
        ),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'See All',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(AppConfig.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Color(AppConfig.primaryColor),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color(AppConfig.primaryColor);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : primaryColor).withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ambient Background Graphics
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderIconButton(
                        icon: Icons.sort_rounded,
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      _buildHeaderIconButton(
                        icon: Icons.notifications_none_rounded, // Improved icon
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  // Welcome Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, Explorer!',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Discover Your\nDream Journey',
                              style: GoogleFonts.outfit( // Changed to Outfit as per "modern" suggestion if available, otherwise fallback to Poppins
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Colors.grey, size: 32),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Glassmorphic Search Bar
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                       boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(isDark ? 0.1 : 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: isDark ? Colors.white70 : primaryColor,
                                size: 26,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Search destinations...',
                                  style: GoogleFonts.poppins(
                                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.tune_rounded,
                                  color: isDark ? Colors.white : primaryColor,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildQuickActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionItem(Icons.auto_awesome_rounded, 'AI Planner', () => _navigateToScreen(const AITripPlannerScreen()), const Color(0xFFE3F2FD), const Color(0xFF2196F3)),
              _buildQuickActionItem(Icons.qr_code_scanner_rounded, 'Scan', () => _navigateToScreen(const LandmarkScannerScreen()), const Color(0xFFFFF3E0), const Color(0xFFFF9800)),
              _buildQuickActionItem(Icons.cloud_outlined, 'Weather', () => _navigateToScreen(const WeatherScreen()), const Color(0xFFE8F5E9), const Color(0xFF4CAF50)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionItem(Icons.person_search_rounded, 'Advisors', () => _navigateToScreen(const AdvisorsSearchScreen()), const Color(0xFFF3E5F5), const Color(0xFF9C27B0)),
              _buildQuickActionItem(Icons.bookmark_border_rounded, 'Saved', () => _navigateToScreen(const SavedLandmarksScreen()), const Color(0xFFFFEBEE), const Color(0xFFF44336)),
              _buildQuickActionItem(Icons.timeline_rounded, 'Plans', () => _navigateToScreen(const SavedTripPlansScreen()), const Color(0xFFE0F2F1), const Color(0xFF009688)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, VoidCallback onTap, Color bgColor, Color iconColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withOpacity(0.2) : bgColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildAIFeatures() {
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          _buildFeatureCard(
            0,
            Icons.smart_toy_rounded,
            'AI Travel Assistant',
            'Get personalized\nrecommendations',
            Color(AppConfig.primaryColor),
            const Color(0xFFE3F2FD),
          ),
          const SizedBox(width: 16),
          _buildFeatureCard(
            1,
            Icons.eco_rounded,
            'Eco-Friendly',
            'Sustainable travel\nchoices for you',
            const Color(0xFF4CAF50),
            const Color(0xFFE8F5E9),
          ),
          const SizedBox(width: 16),
          _buildFeatureCard(
            2,
            Icons.event_available_rounded,
            'Local Events',
            'Find exciting events\nat your destination',
            const Color(0xFFFF9800),
            const Color(0xFFFFF3E0),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(int index, IconData icon, String title, String subtitle, Color color, Color bgColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? color.withOpacity(0.2) : bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              CircleAvatar(
                radius: 12,
                backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                child: Icon(Icons.arrow_forward, size: 14, color: isDark ? Colors.white : Colors.grey.shade600),
              )
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.grey.shade500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTrips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  width: 8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: isDark ? Colors.white54 : Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No trips planned yet',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your next adventure is waiting.\nStart planning your dream trip today!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: isDark ? Colors.white60 : Colors.grey.shade500,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _navigateToScreen(const CreateTripScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConfig.primaryColor),
                  foregroundColor: Colors.white,
                  elevation: 10,
                  shadowColor: Color(AppConfig.primaryColor).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_location_alt_outlined),
                    const SizedBox(width: 12),
                    Text(
                      'Create New Trip',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsTab() {
    return const TripsListScreen();
  }

  Widget _buildExploreTab() {
    return const LandmarkScannerScreen();
  }

  Widget _buildAdvisorsTab() {
    return const AdvisorsSearchScreen();
  }

  Widget _buildProfileTab() {
    return const ProfileScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      appBar: (_selectedIndex == 1 || _selectedIndex == 2)
          ? AppBar(
              title: const Text('TripNexus'),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
              ],
            )
          : null,
      drawer: CustomDrawer(
        userRole: 'Tourist',
        onLogout: _handleLogout,
      ),
      body: Stack(
        children: [
          _buildDashboardContent(),
          // Gradient fade at the bottom for better content visibility behind nav bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 100,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0),
                      Colors.white.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF0F172A).withOpacity(0.8) 
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home_rounded),
                _buildNavItem(1, Icons.explore_rounded),
                _buildNavItem(2, Icons.camera_enhance_rounded),
                _buildNavItem(3, Icons.cloud_outlined),
                _buildNavItem(4, Icons.article_outlined),
                _buildNavItem(5, Icons.person_outline_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_selectedIndex != index) {
            setState(() => _selectedIndex = index);
          }
        },
        child: SizedBox(
          height: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Active Background Glow (Fluid Animation)
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic, // Changed from overshooting Cubic to safe easeOutCubic
                width: isSelected ? 48 : 0,
                height: isSelected ? 48 : 0,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: (isDark ? Colors.white : const Color(0xFF0F172A)).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    )
                  ] : [
                    const BoxShadow(
                      color: Colors.transparent,
                      blurRadius: 0,
                      offset: Offset.zero,
                    )
                  ],
                ),
              ),
              // Icon with Scale and Color Transition
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 1.0 + (value * 0.1),
                    child: Icon(
                      icon,
                      size: 24,
                      color: Color.lerp(
                        isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                        isDark ? const Color(0xFF0F172A) : Colors.white,
                        value,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
