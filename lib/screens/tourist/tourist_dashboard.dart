import 'dart:ui';
import 'package:flutter/services.dart';
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
import '../common/notification_panel_screen.dart';
import '../../services/notification_service.dart';
import '../../widgets/in_app_notification.dart';
import '../../models/notification_model.dart';

class TouristDashboard extends StatefulWidget {
  const TouristDashboard({Key? key}) : super(key: key);

  @override
  State<TouristDashboard> createState() => _TouristDashboardState();
}

class _TouristDashboardState extends State<TouristDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _notificationService = NotificationService.getInstance();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
    _updateUnreadCount();

    // Check for pending notification trigger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_notificationService.pendingNotification != null) {
        _navigateToNotifications();
        _notificationService.clearPendingNotification();
      }
    });
  }

  void _setupNotificationListener() {
    _notificationService.addListener(_onNotificationReceived);
  }

  void _onNotificationReceived(AppNotification notification) {
    if (mounted) {
      setState(() {
        _unreadCount = _notificationService.unreadCount;
      });
      // Show in-app notification
      NotificationOverlayHelper.show(
        context,
        notification,
        onTap: () {
          _navigateToNotifications();
        },
      );
    }
  }

  void _updateUnreadCount() {
    setState(() {
      _unreadCount = _notificationService.unreadCount;
    });
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationPanelScreen(),
      ),
    ).then((_) => _updateUnreadCount());
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationReceived);
    super.dispose();
  }

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
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutQuart,
      switchOutCurve: Curves.easeInQuart,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
            )),
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

  Future<void> _refreshDashboardData() async {
    // Show some haptic feedback for a "smart" feel if possible, or just refresh
    try {
      final authService = await AuthService.getInstance();
      await authService.loadUserSession(); // Refresh user data
      _updateUnreadCount(); // Refresh notifications
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error refreshing dashboard: $e');
    }
  }

  Widget _buildHomeTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Container(
      color: bgColor,
      child: RefreshIndicator(
        onRefresh: _refreshDashboardData,
        displacement: 100, // Show below the header icons
        color: Color(AppConfig.primaryColor),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Container(
                color: bgColor,
                child: Column(
                  children: [
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
                          _buildSectionHeader('AI-Powered Features', null),
                          const SizedBox(height: 16),
                          _buildAIFeatures(),
                          const SizedBox(height: 32),
                          _buildRecentTrips(),
                          const SizedBox(height: 100), // Extra space for bottom nav
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = Color(AppConfig.primaryColor);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [Color(AppConfig.primaryColor), const Color(0xFF1565C0)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : primaryColor).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative background elements
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
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
                      Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _buildHeaderIconButton(
                                icon: Icons.notifications_none_rounded,
                                onTap: _navigateToNotifications,
                              ),
                              if (_unreadCount > 0)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isDark ? const Color(0xFF1E293B) : Color(AppConfig.primaryColor), width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Welcome Text
                  Text(
                    'Hello, Explorer!',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discover Your\nDream Journey',
                    style: GoogleFonts.outfit(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Search Bar Placeholder (Modern Look)
                  GestureDetector(
                    onTap: () => _navigateToScreen(const AdvisorsSearchScreen()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.8), size: 22),
                          const SizedBox(width: 12),
                          Text(
                            'Where do you want to go?',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 15,
                            ),
                          ),
                        ],
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 20,
      crossAxisSpacing: 12,
      padding: EdgeInsets.zero,
      childAspectRatio: 0.8,
      children: [
        _buildQuickActionItem(Icons.auto_awesome_rounded, 'AI Planner', () => _navigateToScreen(const AITripPlannerScreen()), const Color(0xFFE3F2FD), const Color(0xFF2196F3)),
        _buildQuickActionItem(Icons.camera_enhance_rounded, 'Scanner', () => _navigateToScreen(const LandmarkScannerScreen()), const Color(0xFFFFF3E0), const Color(0xFFFF9800)),
        _buildQuickActionItem(Icons.cloud_outlined, 'Weather', () => _navigateToScreen(const WeatherScreen()), const Color(0xFFE8F5E9), const Color(0xFF4CAF50)),
        _buildQuickActionItem(Icons.person_search_rounded, 'Advisors', () => _navigateToScreen(const AdvisorsSearchScreen()), const Color(0xFFF3E5F5), const Color(0xFF9C27B0)),
        _buildQuickActionItem(Icons.bookmark_border_rounded, 'Saved', () => _navigateToScreen(const SavedLandmarksScreen()), const Color(0xFFFFEBEE), const Color(0xFFF44336)),
        _buildQuickActionItem(Icons.timeline_rounded, 'Plans', () => _navigateToScreen(const SavedTripPlansScreen()), const Color(0xFFE0F2F1), const Color(0xFF009688)),
        _buildQuickActionItem(Icons.newspaper_rounded, 'News', () => _navigateToScreen(const NewsScreen()), const Color(0xFFF1F5F9), const Color(0xFF64748B)),
        _buildQuickActionItem(Icons.settings_rounded, 'Settings', () => setState(() => _selectedIndex = 5), const Color(0xFFF1F5F9), const Color(0xFF475569)),
      ],
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, VoidCallback onTap, Color bgColor, Color iconColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withOpacity(0.15) : iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? iconColor.withOpacity(0.2) : iconColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade300 : theme.colorScheme.onSurface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
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
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          _buildFeatureCard(
            0,
            Icons.smart_toy_rounded,
            'AI Travel Assistant',
            'Get personalized recommendations',
            Color(AppConfig.primaryColor),
            const Color(0xFFE3F2FD),
            () => _navigateToScreen(const AITripPlannerScreen()),
          ),
          const SizedBox(width: 16),
          _buildFeatureCard(
            1,
            Icons.eco_rounded,
            'Eco-Friendly',
            'Sustainable travel choices for you',
            const Color(0xFF10B981),
            const Color(0xFFECFDF5),
            () {},
          ),
          const SizedBox(width: 16),
          _buildFeatureCard(
            2,
            Icons.event_available_rounded,
            'Local Events',
            'Find exciting events nearby',
            const Color(0xFFF59E0B),
            const Color(0xFFFFFBEB),
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(int index, IconData icon, String title, String subtitle, Color color, Color bgColor, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.2) : color.withOpacity(0.06),
              blurRadius: 24,
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
                    color: isDark ? color.withOpacity(0.1) : color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Icon(Icons.arrow_forward_rounded, size: 20, color: isDark ? Colors.white38 : color.withOpacity(0.3)),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: isDark ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? Colors.white60 : theme.colorScheme.onSurface.withOpacity(0.6),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTrips() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Trips',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(AppConfig.primaryColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Color(AppConfig.primaryColor).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.map_rounded,
                  color: Color(AppConfig.primaryColor),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No trips yet',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start planning your next adventure with our AI assistant!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : theme.colorScheme.onSurface.withOpacity(0.4),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToScreen(const CreateTripScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(AppConfig.primaryColor),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Plan a Trip'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripsTab() {
    return const TripsListScreen();
  }

  Widget _buildExploreTab() {
    return const LandmarkScannerScreen();
  }

  Widget _buildProfileTab() {
    return const ProfileScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      appBar: null,
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
                      Theme.of(context).scaffoldBackgroundColor.withOpacity(0),
                      Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 64,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF1E293B) : Colors.white).withOpacity(isDark ? 0.85 : 0.9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.grid_view_rounded, Icons.grid_view_outlined, 'Home'),
                _buildNavItem(1, Icons.explore_rounded, Icons.explore_outlined, 'Explore'),
                _buildNavItem(2, Icons.camera_enhance_rounded, Icons.camera_enhance_outlined, 'Scan'),
                _buildNavItem(4, Icons.article_rounded, Icons.article_outlined, 'News'),
                _buildNavItem(5, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = Color(AppConfig.primaryColor);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedIndex = index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuart,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? primaryColor.withOpacity(isDark ? 0.2 : 0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? selectedIcon : unselectedIcon,
                  key: ValueKey<bool>(isSelected),
                  color: isSelected 
                      ? primaryColor 
                      : (isDark ? Colors.white38 : const Color(0xFF64748B)), // Slate 500 for modern look in light mode
                  size: 22,
                ),
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
