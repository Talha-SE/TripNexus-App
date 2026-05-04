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
import 'advisor_packages_browse_screen.dart';
import 'weather_screen.dart';
import 'profile_screen.dart';
import 'ai_trip_planner_screen.dart';
import 'saved_landmarks_screen.dart';
import 'my_bookings_screen.dart';
import 'news_screen.dart';
import '../common/notification_panel_screen.dart';
import '../../services/notification_service.dart';
import '../../widgets/in_app_notification.dart';
import '../../models/notification_model.dart';
import '../../services/mongodb_service.dart';
import '../../models/saved_trip_plan_model.dart';
import '../../widgets/trip_plan_view.dart';

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
  List<SavedTripPlanModel> _savedPlans = [];
  bool _isLoadingSavedPlans = false;

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
    _updateUnreadCount();
    _loadSavedPlans();

    // Check for pending notification trigger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_notificationService.pendingNotification != null) {
        _navigateToNotifications();
        _notificationService.clearPendingNotification();
      }
    });
  }

  Future<void> _loadSavedPlans() async {
    if (!mounted) return;
    setState(() => _isLoadingSavedPlans = true);

    try {
      final authService = await AuthService.getInstance();
      final user = authService.currentUser;

      if (user == null) {
        setState(() => _isLoadingSavedPlans = false);
        return;
      }

      final mongoService = await MongoDBService.getInstance();
      await mongoService.ensureConnected();
      final collection = mongoService.getSavedTripPlansCollection();

      final plans = await collection.find({'userId': user.id}).toList();

      if (mounted) {
        setState(() {
          _savedPlans = plans
              .map((p) => SavedTripPlanModel.fromJson(p))
              .toList()
            ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
          _isLoadingSavedPlans = false;
        });
      }
    } catch (e) {
      print('Error loading saved plans: $e');
      if (mounted) {
        setState(() => _isLoadingSavedPlans = false);
      }
    }
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
      MaterialPageRoute(builder: (context) => const NotificationPanelScreen()),
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
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutQuart),
            ),
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
                          _buildRecentTrips(),
                          const SizedBox(
                            height: 100,
                          ), // Extra space for bottom nav
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
                                showBorder: false,
                                showBackground: false,
                              ),
                              if (_unreadCount > 0)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _selectedIndex = 5),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
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
                    onTap: () =>
                        _navigateToScreen(const AdvisorPackagesBrowseScreen()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: Colors.white.withOpacity(0.8),
                            size: 22,
                          ),
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

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showBorder = true,
    bool showBackground = true,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: showBackground
            ? Colors.white.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: showBorder
            ? Border.all(color: Colors.white.withOpacity(0.15), width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(child: Icon(icon, color: Colors.white, size: 22)),
        ),
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
        _buildQuickActionItem(
          Icons.auto_awesome_rounded,
          'AI Planner',
          () => _navigateToScreen(const AITripPlannerScreen()),
          const Color(0xFFE3F2FD),
          const Color(0xFF2196F3),
        ),
        _buildQuickActionItem(
          Icons.camera_enhance_rounded,
          'Scanner',
          () => _navigateToScreen(const LandmarkScannerScreen()),
          const Color(0xFFFFF3E0),
          const Color(0xFFFF9800),
        ),
        _buildQuickActionItem(
          Icons.cloud_outlined,
          'Weather',
          () => _navigateToScreen(const WeatherScreen()),
          const Color(0xFFE8F5E9),
          const Color(0xFF4CAF50),
        ),
        _buildQuickActionItem(
          Icons.person_search_rounded,
          'Advisors',
          () => _navigateToScreen(const AdvisorPackagesBrowseScreen()),
          const Color(0xFFF3E5F5),
          const Color(0xFF9C27B0),
        ),
        _buildQuickActionItem(
          Icons.receipt_long_rounded,
          'Bookings',
          () => _navigateToScreen(const MyBookingsScreen()),
          const Color(0xFFFFEBEE),
          const Color(0xFFF44336),
        ),
        _buildQuickActionItem(
          Icons.bookmark_border_rounded,
          'Saved Plans',
          () => _navigateToScreen(const TripsListScreen(title: 'Saved Plans')),
          const Color(0xFFE0F2F1),
          const Color(0xFF009688),
        ),
        _buildQuickActionItem(
          Icons.newspaper_rounded,
          'News',
          () => _navigateToScreen(const NewsScreen()),
          const Color(0xFFF1F5F9),
          const Color(0xFF64748B),
        ),
        _buildQuickActionItem(
          Icons.settings_rounded,
          'Settings',
          () => setState(() => _selectedIndex = 5),
          const Color(0xFFF1F5F9),
          const Color(0xFF475569),
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color bgColor,
    Color iconColor,
  ) {
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
              color: isDark
                  ? iconColor.withOpacity(0.15)
                  : iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? iconColor.withOpacity(0.2)
                    : iconColor.withOpacity(0.1),
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
              color: isDark
                  ? Colors.grey.shade300
                  : theme.colorScheme.onSurface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Widget _buildRecentTrips() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Recent Trips', () => setState(() => _selectedIndex = 1)),
        const SizedBox(height: 16),
        if (_isLoadingSavedPlans)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100,
              ),
            ),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_savedPlans.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100,
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
                    color: isDark
                        ? Colors.white38
                        : theme.colorScheme.onSurface.withOpacity(0.4),
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
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _savedPlans.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final plan = _savedPlans[index];
              return _buildRecentTripCard(plan);
            },
          ),
      ],
    );
  }

  Widget _buildRecentTripCard(SavedTripPlanModel plan) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _openSavedPlan(plan),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Color(AppConfig.primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: Color(AppConfig.primaryColor),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.destination,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plan.duration} days • ${plan.interests}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white60
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _openSavedPlan(SavedTripPlanModel plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _SavedPlanDetailScreen(plan: plan, onRefresh: _loadSavedPlans),
      ),
    ).then((_) => _loadSavedPlans());
  }

  Widget _buildAIFeatures() {
    // Removed - AI-Powered Features section
    return const SizedBox.shrink();
  }

  Widget _buildTripsTab() {
    return const TripsListScreen();
  }

  Widget _buildExploreTab() {
    return const LandmarkScannerScreen();
  }

  Widget _buildProfileTab() {
    return ProfileScreen(
      onBack: () {
        setState(() => _selectedIndex = 0);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (_selectedIndex != 0) {
          // If not on home tab, go home first
          setState(() => _selectedIndex = 0);
        } else {
          // On home tab: show exit confirmation
          showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Exit App',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Are you sure you want to exit?',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Color(AppConfig.textSecondaryColor),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    SystemNavigator.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(AppConfig.primaryColor),
                  ),
                  child: Text(
                    'Exit',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: true,
        appBar: null,
        drawer: CustomDrawer(userRole: 'Tourist', onLogout: _handleLogout),
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
                        Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withOpacity(0),
                        Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withOpacity(0.95),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildFloatingNavBar(),
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = Color(AppConfig.primaryColor);

    return Container(
      height: 68,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 20),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                  .withOpacity(isDark ? 0.85 : 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : primaryColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  0,
                  Icons.grid_view_rounded,
                  Icons.grid_view_outlined,
                  'Home',
                ),
                _buildNavItem(
                  1,
                  Icons.map_rounded,
                  Icons.map_outlined,
                  'Trips',
                ),
                _buildNavItem(
                  2,
                  Icons.camera_rounded,
                  Icons.camera_outlined,
                  'Scan',
                ),
                _buildNavItem(
                  4,
                  Icons.article_rounded,
                  Icons.article_outlined,
                  'News',
                ),
                _buildNavItem(
                  5,
                  Icons.person_rounded,
                  Icons.person_outline_rounded,
                  'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
  ) {
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
                      : (isDark ? Colors.white38 : const Color(0xFF64748B)),
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

class _SavedPlanDetailScreen extends StatelessWidget {
  final SavedTripPlanModel plan;
  final VoidCallback onRefresh;

  const _SavedPlanDetailScreen({
    required this.plan,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = Color(AppConfig.primaryColor);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Trip Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [primaryColor, const Color(0xFF1565C0)],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 90, 0, 20),
            child: TripPlanView(
              destination: plan.destination,
              duration: plan.duration,
              startDate: plan.startDate,
              endDate: plan.endDate,
              interests: plan.interests,
              budget: plan.budget,
              planText: plan.plan,
            ),
          ),
        ),
      ),
    );
  }
}
